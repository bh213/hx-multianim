package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness.UITestScreen;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.ui.UIElement;
import bh.ui.UIInteractiveWrapper;
import bh.ui.UIPanelHelper;

/**
 * The screen's interactive wrappers after a source rebuilds (`@switch` arm flips, conditional
 * containers hidden and shown, param-dependent repeats) and after remove/add cycles.
 *
 * The wrappers of one source must not be touched by another source's rebuild, a wrapper must
 * follow its interactive to the rebuilt object, and the builder-owned objects themselves must
 * never be detached by the screen.
 */
class UIScreenInteractiveSyncTest extends BuilderTestBase {
	/** True when `w` wraps an interactive the source still exposes (attached to its live tree). */
	static function isLive(w:Null<UIInteractiveWrapper>, source:BuilderResult):Bool {
		if (w == null)
			return false;
		return source.getInteractives().indexOf(w.interactive) >= 0;
	}

	// ==================== one source's rebuild leaves other sources alone ====================

	static final TWO_SOURCES_MANIM = "
		#hoverBtn programmable(status:[normal,hover,pressed,disabled]=normal) {
			@(status=>normal) bitmap(generated(color(10, 10, #f00))): 0, 0
			@(status=>hover) bitmap(generated(color(20, 10, #0f0))): 0, 0
			interactive(40, 40, \"first\", autoStatus => \"status\"): 0, 0
		}
		#plain programmable(n:int=0) {
			interactive(40, 40, \"second\"): 0, 50
		}
	";

	@Test
	public function testRebuildLeavesInteractivesOfOtherSourceUnderSamePrefix():Void {
		final screen = new UITestScreen();
		final first = BuilderTestBase.buildFromSource(TWO_SOURCES_MANIM, "hoverBtn", null, Incremental);
		final second = BuilderTestBase.buildFromSource(TWO_SOURCES_MANIM, "plain", null, Incremental);
		screen.addInteractives(first);
		screen.addInteractives(second);

		first.setParameter("status", "hover");

		Assert.notNull(screen.getInteractive("second"), "another source's interactive keeps its wrapper");
		Assert.isTrue(isLive(screen.getInteractive("second"), second), "and its object stays in its own tree");
	}

	// ==================== a rebuilt interactive with the same id ====================

	static final SAME_ID_ARMS_MANIM = "
		#armSameId programmable(mode:[a,b]=a) {
			@switch(mode) {
				a: interactive(40, 40, \"hit\"): 0, 0;
				b: interactive(60, 60, \"hit\"): 10, 0;
			}
		}
	";

	@Test
	public function testWrapperFollowsRebuiltInteractiveWithSameId():Void {
		final screen = new UITestScreen();
		final result = BuilderTestBase.buildFromSource(SAME_ID_ARMS_MANIM, "armSameId", null, Incremental);
		screen.addInteractives(result);
		final before = screen.getInteractive("hit");
		Assert.notNull(before);
		if (before != null)
			before.disabled = true;

		result.setParameter("mode", "b");

		final after = screen.getInteractive("hit");
		Assert.isTrue(isLive(after, result), "the wrapper must point at the rebuilt, live object");
		Assert.equals(before, after, "the same wrapper follows the rebuilt object");
		if (after != null)
			Assert.isTrue(after.disabled, "state set on the wrapper survives the rebuild");
	}

	static final AUTO_STATUS_ARM_MANIM = "
		#autoArm programmable(mode:[a,b]=a, status:[normal,hover,pressed,disabled]=normal) {
			@switch(mode) {
				a {
					@(status=>normal) bitmap(generated(color(10, 10, #f00))): 0, 0
					@(status=>hover) bitmap(generated(color(20, 10, #0f0))): 0, 0
					interactive(40, 40, \"hitA\", autoStatus => \"status\"): 0, 0
				}
				b {
					interactive(60, 60, \"hitB\", autoStatus => \"status\"): 0, 0
				}
			}
		}
	";

	@Test
	public function testAutoStatusInteractiveStaysLiveAfterItsArmRebuildsOnHover():Void {
		final screen = new UITestScreen();
		final result = BuilderTestBase.buildFromSource(AUTO_STATUS_ARM_MANIM, "autoArm", null, Incremental);
		screen.addInteractives(result);

		screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "hitA", null), null);
		screen.dispatchScreenEvent(UIInteractiveEvent(UILeaving, "hitA", null), null);

		Assert.isTrue(isLive(screen.getInteractive("hitA"), result),
			"after hover rebuilds the arm, the wrapper must point at the live object");
	}

	// ==================== hidden containers and remove/add cycles ====================

	static final HIDDEN_CONTAINER_MANIM = "
		#hiddenBox programmable(open:bool=true) {
			@(open=>true) layers() {
				interactive(100, 30, \"nested\"): 0, 0
			}
		}
	";

	@Test
	public function testInteractiveInHiddenContainerIsWrappedAgainWhenShown():Void {
		final screen = new UITestScreen();
		final result = BuilderTestBase.buildFromSource(HIDDEN_CONTAINER_MANIM, "hiddenBox", null, Incremental);
		screen.addInteractives(result);

		result.setParameter("open", false);
		Assert.isNull(screen.getInteractive("nested"), "hidden: no click target");

		result.setParameter("open", true);
		Assert.isTrue(isLive(screen.getInteractive("nested"), result),
			"shown again: the interactive is back in the tree and wrapped");
	}

	static final ONE_BUTTON_MANIM = "
		#oneButton programmable(n:int=0) {
			interactive(100, 30, \"btn\"): 0, 0
		}
	";

	@Test
	public function testRemoveThenAddInteractivesWrapsTheSameResultAgain():Void {
		final screen = new UITestScreen();
		final result = BuilderTestBase.buildFromSource(ONE_BUTTON_MANIM, "oneButton", null, Incremental);
		screen.addInteractives(result, "hud");

		screen.removeInteractives("hud");
		screen.addInteractives(result, "hud");

		Assert.isTrue(isLive(screen.getInteractive("hud.btn"), result),
			"removeInteractives must not take the object out of the result, so adding it again works");
	}

	// ==================== autoStatus helper and bindings ====================

	static final LATE_AUTO_STATUS_MANIM = "
		#lateAuto programmable(mode:[a,b]=a, status:[normal,hover,pressed,disabled]=normal) {
			@switch(mode) {
				a: interactive(40, 40, \"plain\"): 0, 0;
				b: interactive(40, 40, \"auto\", autoStatus => \"status\"): 0, 0;
			}
		}
	";

	@Test
	public function testAutoStatusInteractiveAppearingAfterRegistrationIsWired():Void {
		final screen = new UITestScreen();
		final result = BuilderTestBase.buildFromSource(LATE_AUTO_STATUS_MANIM, "lateAuto", null, Incremental);
		screen.addInteractives(result);

		result.setParameter("mode", "b");

		final helper = screen.getAutoInteractiveHelper();
		Assert.notNull(helper, "an autoStatus interactive that appears later still gets the auto helper");
		if (helper != null)
			Assert.isTrue(helper.hasBinding("auto"), "and its binding");
	}

	static final AUTO_BUTTON_MANIM = "
		#autoButton programmable(status:[normal,hover,pressed,disabled]=normal) {
			interactive(40, 40, \"btn\", autoStatus => \"status\"): 0, 0
		}
	";

	@Test
	public function testRemoveInteractivesKeepsBindingsOfChildPrefix():Void {
		final screen = new UITestScreen();
		final hud = BuilderTestBase.buildFromSource(AUTO_BUTTON_MANIM, "autoButton", null, Incremental);
		final menu = BuilderTestBase.buildFromSource(AUTO_BUTTON_MANIM, "autoButton", null, Incremental);
		screen.addInteractives(hud, "hud");
		screen.addInteractives(menu, "hud.settings.menu");

		screen.removeInteractives("hud");

		final helper = screen.getAutoInteractiveHelper();
		Assert.notNull(helper);
		if (helper != null) {
			Assert.isFalse(helper.hasBinding("hud.btn"), "the removed prefix loses its binding");
			Assert.isTrue(helper.hasBinding("hud.settings.menu.btn"), "a child prefix keeps its binding");
		}
	}

	// ==================== panel interactives created after open ====================

	static final PANEL_MANIM = "
		#anchor programmable() {
			interactive(100, 30, \"opener\"): 0, 0
		}
		#tabbedPanel programmable(tab:[a,b]=a) {
			@switch(tab) {
				a: interactive(40, 20, \"first\"): 0, 0;
				b: interactive(40, 20, \"second\"): 0, 0;
			}
		}
		#latePanel programmable(mode:[none,button]=none) {
			@switch(mode) {
				none: bitmap(generated(color(40, 20, #333333))): 0, 0;
				button: interactive(40, 20, \"late\"): 0, 0;
			}
		}
	";

	static function createPanelHelper():{helper:UIPanelHelper, screen:UITestScreen} {
		final screen = new UITestScreen();
		final builder = BuilderTestBase.builderFromSource(PANEL_MANIM);
		screen.addInteractives(builder.buildWithParameters("anchor", []));
		return {helper: new UIPanelHelper(screen, builder), screen: screen};
	}

	@Test
	public function testPanelInteractiveCreatedAfterOpenGetsOverlayPriority():Void {
		final ctx = createPanelHelper();
		ctx.helper.open("opener", "tabbedPanel");
		final prefix = ctx.helper.getActivePrefix();
		Assert.equals(UIEventPriority.Overlay, ctx.screen.getInteractive('$prefix.first').eventPriority,
			"precondition: the panel's interactives are raised above the content");

		ctx.helper.getPanelResult().setParameter("tab", "b");

		final w = ctx.screen.getInteractive('$prefix.second');
		Assert.notNull(w, "the rebuilt panel interactive is wrapped");
		if (w != null)
			Assert.equals(UIEventPriority.Overlay, w.eventPriority, "and raised like the ones present at open");
	}

	@Test
	public function testPanelWithNoInteractivesAtOpenWiresThemLater():Void {
		final ctx = createPanelHelper();
		ctx.helper.open("opener", "latePanel");
		final prefix = ctx.helper.getActivePrefix();

		ctx.helper.getPanelResult().setParameter("mode", "button");

		final w = ctx.screen.getInteractive('$prefix.late');
		Assert.notNull(w, "an interactive that appears after open is wrapped");
		if (w != null)
			Assert.equals(UIEventPriority.Overlay, w.eventPriority, "with the panel's priority");
	}
}
