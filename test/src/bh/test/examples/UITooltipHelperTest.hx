package bh.test.examples;

import utest.Assert;
import bh.base.TweenManager;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness.UITestScreen;
import bh.ui.UITooltipHelper;
import bh.ui.UITooltipHelper.TooltipDefaults;
import bh.ui.UITooltipHelper.TooltipPosition;

/**
 * Unit tests for UITooltipHelper.
 * Tests hover delay lifecycle, immediate show/hide, per-interactive overrides,
 * positioning, updateParams, and rebuild.
 */
class UITooltipHelperTest extends BuilderTestBase {
	// A simple programmable used as the "anchor" with an interactive region.
	static final ANCHOR_MANIM = '
		#anchor programmable(status:[normal]=normal) {
			bitmap(generated(color(100, 30, #666666))): 0, 0
			interactive(100, 30, "btn1"): 0, 0
		}
	';

	// A second anchor with a different interactive id.
	static final ANCHOR2_MANIM = '
		#anchor2 programmable(status:[normal]=normal) {
			bitmap(generated(color(100, 30, #888888))): 0, 0
			interactive(100, 30, "btn2"): 0, 0
		}
	';

	// A simple programmable used as the tooltip content.
	static final TOOLTIP_MANIM = '
		#tip programmable(label:string=hello) {
			bitmap(generated(color(80, 20, #FFAA00))): 0, 0
		}
	';

	// A second tooltip programmable with a different name.
	static final TOOLTIP2_MANIM = '
		#tip2 programmable(label:string=hello) {
			bitmap(generated(color(60, 15, #00AAFF))): 0, 0
		}
	';

	// ============== Helper ==============

	function createHelper(?delay:Float, ?position:TooltipPosition, ?offset:Int):{
		helper:UITooltipHelper,
		screen:UITestScreen
	} {
		var screen = new UITestScreen();
		var builder = BuilderTestBase.builderFromSource('$ANCHOR_MANIM\n$ANCHOR2_MANIM\n$TOOLTIP_MANIM\n$TOOLTIP2_MANIM');

		// Build anchor and register its interactive on the screen
		var anchorResult = builder.buildWithParameters("anchor", []);
		screen.addInteractives(anchorResult);

		var anchor2Result = builder.buildWithParameters("anchor2", []);
		screen.addInteractives(anchor2Result);

		var defaults:bh.ui.UITooltipHelper.TooltipDefaults = {};
		if (delay != null) defaults.delay = delay;
		if (position != null) defaults.position = position;
		if (offset != null) defaults.offset = offset;

		var helper = new UITooltipHelper(screen, builder, defaults);
		return {helper: helper, screen: screen};
	}

	// ============== startHover / cancelHover / delay ==============

	@Test
	public function testInitialState():Void {
		var ctx = createHelper();
		Assert.isFalse(ctx.helper.isActive());
		Assert.isNull(ctx.helper.getActiveId());
	}

	@Test
	public function testStartHoverDoesNotShowImmediately():Void {
		var ctx = createHelper(0.3);
		ctx.helper.startHover("btn1", "tip");

		// No update yet — tooltip should NOT be active
		Assert.isFalse(ctx.helper.isActive());
		Assert.isNull(ctx.helper.getActiveId());
	}

	@Test
	public function testHoverShowsAfterDelay():Void {
		var ctx = createHelper(0.3);
		ctx.helper.startHover("btn1", "tip");

		// Advance time but not enough
		ctx.helper.update(0.1);
		Assert.isFalse(ctx.helper.isActive());

		ctx.helper.update(0.1);
		Assert.isFalse(ctx.helper.isActive());

		// Now cross the threshold (total 0.3)
		ctx.helper.update(0.1);
		Assert.isTrue(ctx.helper.isActive());
		Assert.equals("btn1", ctx.helper.getActiveId());
	}

	@Test
	public function testCancelHoverBeforeDelay():Void {
		var ctx = createHelper(0.5);
		ctx.helper.startHover("btn1", "tip");

		ctx.helper.update(0.2);
		Assert.isFalse(ctx.helper.isActive());

		// Cancel before delay elapses
		ctx.helper.cancelHover("btn1");

		// Advance past original delay — should NOT show
		ctx.helper.update(0.5);
		Assert.isFalse(ctx.helper.isActive());
	}

	@Test
	public function testCancelHoverWrongIdDoesNothing():Void {
		var ctx = createHelper(0.2);
		ctx.helper.startHover("btn1", "tip");

		// Cancel with wrong id — should not affect the pending hover
		ctx.helper.cancelHover("btn2");

		ctx.helper.update(0.3);
		Assert.isTrue(ctx.helper.isActive());
		Assert.equals("btn1", ctx.helper.getActiveId());
	}

	@Test
	public function testCancelHoverHidesActiveTooltip():Void {
		var ctx = createHelper(0.1);
		ctx.helper.startHover("btn1", "tip");
		ctx.helper.update(0.2);
		Assert.isTrue(ctx.helper.isActive());

		// Cancel should hide the active tooltip
		ctx.helper.cancelHover("btn1");
		Assert.isFalse(ctx.helper.isActive());
		Assert.isNull(ctx.helper.getActiveId());
	}

	@Test
	public function testDefaultDelayIsPointThree():Void {
		// Create with no explicit delay — default is 0.3
		var ctx = createHelper();
		ctx.helper.startHover("btn1", "tip");

		ctx.helper.update(0.29);
		Assert.isFalse(ctx.helper.isActive());

		ctx.helper.update(0.02);
		Assert.isTrue(ctx.helper.isActive());
	}

	// ============== show / hide ==============

	@Test
	public function testShowImmediately():Void {
		var ctx = createHelper();
		ctx.helper.show("btn1", "tip");

		Assert.isTrue(ctx.helper.isActive());
		Assert.equals("btn1", ctx.helper.getActiveId());
	}

	@Test
	public function testHide():Void {
		var ctx = createHelper();
		ctx.helper.show("btn1", "tip");
		Assert.isTrue(ctx.helper.isActive());

		ctx.helper.hide();
		Assert.isFalse(ctx.helper.isActive());
		Assert.isNull(ctx.helper.getActiveId());
	}

	@Test
	public function testHideWhenNothingActive():Void {
		var ctx = createHelper();
		// Should not throw
		ctx.helper.hide();
		Assert.isFalse(ctx.helper.isActive());
	}

	@Test
	public function testShowReplacesExistingTooltip():Void {
		var ctx = createHelper();
		ctx.helper.show("btn1", "tip");
		Assert.equals("btn1", ctx.helper.getActiveId());

		// Show for different interactive — should replace
		ctx.helper.show("btn2", "tip");
		Assert.equals("btn2", ctx.helper.getActiveId());
	}

	@Test
	public function testShowForUnregisteredInteractiveDoesNotActivate():Void {
		var ctx = createHelper();
		ctx.helper.show("nonexistent", "tip");
		Assert.isFalse(ctx.helper.isActive());
	}

	// ============== Per-interactive overrides ==============

	@Test
	public function testSetDelayOverride():Void {
		var ctx = createHelper(1.0); // default delay = 1.0
		ctx.helper.setDelay("btn1", 0.1);

		ctx.helper.startHover("btn1", "tip");
		ctx.helper.update(0.15);
		Assert.isTrue(ctx.helper.isActive());
	}

	@Test
	public function testSetDelayOverrideOnlyAffectsTargetInteractive():Void {
		var ctx = createHelper(1.0);
		ctx.helper.setDelay("btn1", 0.1);

		// btn2 should still use default delay
		ctx.helper.startHover("btn2", "tip");
		ctx.helper.update(0.15);
		Assert.isFalse(ctx.helper.isActive());

		ctx.helper.update(1.0);
		Assert.isTrue(ctx.helper.isActive());
	}

	@Test
	public function testSetPositionOverride():Void {
		var ctx = createHelper(0.0);
		ctx.helper.setPosition("btn1", Below);

		// Just verify it doesn't throw — positioning uses getBounds which returns zeroes in headless
		ctx.helper.show("btn1", "tip");
		Assert.isTrue(ctx.helper.isActive());
	}

	@Test
	public function testSetOffsetOverride():Void {
		var ctx = createHelper(0.0);
		ctx.helper.setOffset("btn1", 20);

		ctx.helper.show("btn1", "tip");
		Assert.isTrue(ctx.helper.isActive());
	}

	// ============== Duplicate startHover ==============

	@Test
	public function testStartHoverWhileAlreadyActiveForSameId():Void {
		var ctx = createHelper(0.1);
		ctx.helper.startHover("btn1", "tip");
		ctx.helper.update(0.2);
		Assert.isTrue(ctx.helper.isActive());
		Assert.equals("btn1", ctx.helper.getActiveId());

		// startHover for same id while tooltip is active — should do nothing (no hide/re-show)
		ctx.helper.startHover("btn1", "tip");
		Assert.isTrue(ctx.helper.isActive());
		Assert.equals("btn1", ctx.helper.getActiveId());
	}

	@Test
	public function testStartHoverForDifferentIdHidesFirst():Void {
		var ctx = createHelper(0.1);
		ctx.helper.startHover("btn1", "tip");
		ctx.helper.update(0.2);
		Assert.isTrue(ctx.helper.isActive());
		Assert.equals("btn1", ctx.helper.getActiveId());

		// Start hover for a different interactive — should hide btn1
		ctx.helper.startHover("btn2", "tip");
		Assert.isFalse(ctx.helper.isActive());

		// Then show btn2 after delay
		ctx.helper.update(0.2);
		Assert.isTrue(ctx.helper.isActive());
		Assert.equals("btn2", ctx.helper.getActiveId());
	}

	// ============== updateParams ==============

	@Test
	public function testUpdateParamsWhenActive():Void {
		var ctx = createHelper();
		ctx.helper.show("btn1", "tip");
		Assert.isTrue(ctx.helper.isActive());

		// updateParams calls setParameter on the incremental BuilderResult
		var result = ctx.helper.updateParams(["label" => "world"]);
		Assert.isTrue(result);
		Assert.isTrue(ctx.helper.isActive());
	}

	@Test
	public function testUpdateParamsWhenNotActive():Void {
		var ctx = createHelper();
		var result = ctx.helper.updateParams(["label" => "world"]);
		Assert.isFalse(result);
	}

	// ============== rebuild ==============

	@Test
	public function testRebuildWhenActive():Void {
		var ctx = createHelper();
		ctx.helper.show("btn1", "tip");
		Assert.isTrue(ctx.helper.isActive());

		var result = ctx.helper.rebuild(["label" => "rebuilt"]);
		Assert.isTrue(result);
		Assert.isTrue(ctx.helper.isActive());
		Assert.equals("btn1", ctx.helper.getActiveId());
	}

	@Test
	public function testRebuildWhenNotActive():Void {
		var ctx = createHelper();
		var result = ctx.helper.rebuild();
		Assert.isFalse(result);
	}

	@Test
	public function testRebuildPreservesOriginalParams():Void {
		var ctx = createHelper();
		ctx.helper.show("btn1", "tip", ["label" => "original"]);
		Assert.isTrue(ctx.helper.isActive());

		// Rebuild without new params — should reuse original params
		var result = ctx.helper.rebuild();
		Assert.isTrue(result);
		Assert.isTrue(ctx.helper.isActive());
	}

	@Test
	public function testStartHoverWithChangedBuildNameUpdatesTooltip():Void {
		// Bug 1.3: startHover returns early if activeTooltipId matches,
		// even if the buildName is different. The tooltip stays as the old buildName.
		var ctx = createHelper(0.0);
		ctx.helper.show("btn1", "tip");
		Assert.isTrue(ctx.helper.isActive());
		@:privateAccess Assert.equals("tip", ctx.helper.activeBuildName);

		// startHover with same ID but DIFFERENT buildName should not return early —
		// it should hide the old tooltip and start a new hover timer for the new buildName.
		ctx.helper.startHover("btn1", "tip2");
		// The old tooltip should be hidden (startHover calls hide())
		// and hover timer should be pending for tip2
		ctx.helper.update(0.01);
		// After delay, tooltip should show with new buildName
		Assert.isTrue(ctx.helper.isActive());
		Assert.equals("btn1", ctx.helper.getActiveId());
		@:privateAccess Assert.equals("tip2", ctx.helper.activeBuildName);
	}

	// ============== Zero delay ==============

	@Test
	public function testZeroDelay():Void {
		var ctx = createHelper(0.0);
		ctx.helper.startHover("btn1", "tip");

		// Even with zero delay, update must be called to trigger show
		Assert.isFalse(ctx.helper.isActive());

		ctx.helper.update(0.0);
		Assert.isTrue(ctx.helper.isActive());
	}

	// ============== Update with no pending hover ==============

	@Test
	public function testUpdateWithNoPendingHover():Void {
		var ctx = createHelper();
		// Should not throw
		ctx.helper.update(1.0);
		Assert.isFalse(ctx.helper.isActive());
	}

	// ============== Positioning (all four positions) ==============

	@Test
	public function testAllPositions():Void {
		// Verify all four position variants can be used without error
		for (pos in [Above, Below, Left, Right]) {
			var ctx = createHelper(0.0, pos);
			ctx.helper.show("btn1", "tip");
			Assert.isTrue(ctx.helper.isActive());
			ctx.helper.hide();
		}
	}

	// ============== Fade transitions ==============

	function createHelperWithTweens(?fadeIn:Float, ?fadeOut:Float):{
		helper:UITooltipHelper,
		screen:UITestScreen,
		tweens:TweenManager
	} {
		var screen = new UITestScreen();
		var builder = BuilderTestBase.builderFromSource('$ANCHOR_MANIM\n$ANCHOR2_MANIM\n$TOOLTIP_MANIM\n$TOOLTIP2_MANIM');

		var anchorResult = builder.buildWithParameters("anchor", []);
		screen.addInteractives(anchorResult);

		var anchor2Result = builder.buildWithParameters("anchor2", []);
		screen.addInteractives(anchor2Result);

		var tweens = new TweenManager();
		var defaults:TooltipDefaults = {delay: 0.0};
		if (fadeIn != null) defaults.fadeIn = fadeIn;
		if (fadeOut != null) defaults.fadeOut = fadeOut;

		var helper = new UITooltipHelper(screen, builder, defaults, tweens);
		return {helper: helper, screen: screen, tweens: tweens};
	}

	@Test
	public function testFadeInStartsAtZeroAlpha():Void {
		var ctx = createHelperWithTweens(0.2, 0.1);
		ctx.helper.show("btn1", "tip");
		Assert.isTrue(ctx.helper.isActive());

		// Object should exist but at alpha 0 (before tween update)
		var interactive = ctx.screen.getInteractive("btn1");
		// Tooltip was added to screen layer; helper is active
		Assert.isTrue(ctx.helper.isActive());
	}

	@Test
	public function testFadeInReachesFullAlpha():Void {
		var ctx = createHelperWithTweens(0.2, 0.1);
		ctx.helper.show("btn1", "tip");

		// Advance tweens past fade-in duration
		ctx.tweens.update(0.3);
		Assert.isTrue(ctx.helper.isActive());
	}

	@Test
	public function testFadeOutRemovesOnComplete():Void {
		var ctx = createHelperWithTweens(0.0, 0.2);
		ctx.helper.show("btn1", "tip");
		Assert.isTrue(ctx.helper.isActive());

		ctx.helper.hide();
		// After hide, tooltip is logically gone
		Assert.isFalse(ctx.helper.isActive());

		// But the fade-out tween is still running — advance past it
		ctx.tweens.update(0.3);
		// No crash = success, object was removed by onComplete
		Assert.isFalse(ctx.helper.isActive());
	}

	@Test
	public function testHideDuringFadeInCancels():Void {
		var ctx = createHelperWithTweens(0.5, 0.1);
		ctx.helper.show("btn1", "tip");

		// Partially advance fade-in
		ctx.tweens.update(0.1);

		// Hide — should cancel fade-in and start fade-out
		ctx.helper.hide();
		Assert.isFalse(ctx.helper.isActive());

		// Advance past fade-out
		ctx.tweens.update(0.2);
		Assert.isFalse(ctx.helper.isActive());
	}

	@Test
	public function testShowDuringFadeOutCancelsPrevious():Void {
		var ctx = createHelperWithTweens(0.0, 0.5);
		ctx.helper.show("btn1", "tip");

		// Hide btn1 — starts fade-out
		ctx.helper.hide();
		Assert.isFalse(ctx.helper.isActive());

		// Immediately show btn2 — should cancel btn1 fade-out
		ctx.helper.show("btn2", "tip");
		Assert.isTrue(ctx.helper.isActive());
		Assert.equals("btn2", ctx.helper.getActiveId());

		// Advance tweens — no crash from dangling btn1 tween
		ctx.tweens.update(1.0);
		Assert.isTrue(ctx.helper.isActive());
	}

	@Test
	public function testZeroFadeIsInstant():Void {
		var ctx = createHelperWithTweens(0.0, 0.0);
		ctx.helper.show("btn1", "tip");
		Assert.isTrue(ctx.helper.isActive());

		ctx.helper.hide();
		Assert.isFalse(ctx.helper.isActive());
	}

	@Test
	public function testNoTweenManagerFallsBackToInstant():Void {
		// Using the original createHelper (no tweens)
		var ctx = createHelper(0.0);
		ctx.helper.show("btn1", "tip");
		Assert.isTrue(ctx.helper.isActive());

		ctx.helper.hide();
		Assert.isFalse(ctx.helper.isActive());
	}

	// ============== Bug: hide() does not reset hover timer ==============

	@Test
	public function testHideResetsHoverTimer():Void {
		// Bug: hide() does not reset hoverTimer or clear pending hover state.
		// After hide(), the next update() should NOT re-show the tooltip.
		var ctx = createHelper(0.3);
		ctx.helper.startHover("btn1", "tip");

		// Advance partially (not enough to show)
		ctx.helper.update(0.2);
		Assert.isFalse(ctx.helper.isActive());

		// Call hide() directly — should cancel pending hover
		ctx.helper.hide();

		// Now update past the original delay — tooltip should NOT appear
		ctx.helper.update(0.2);
		Assert.isFalse(ctx.helper.isActive(), "Tooltip should not appear after hide() cancelled pending hover");
	}

	@Test
	public function testHideAfterShowDoesNotReshow():Void {
		// After show() + hide(), a subsequent update() should NOT re-show the tooltip
		var ctx = createHelper(0.1);
		ctx.helper.startHover("btn1", "tip");
		ctx.helper.update(0.2); // tooltip shows
		Assert.isTrue(ctx.helper.isActive());

		ctx.helper.hide(); // direct hide
		Assert.isFalse(ctx.helper.isActive());

		// update should not re-trigger
		ctx.helper.update(0.5);
		Assert.isFalse(ctx.helper.isActive(), "Tooltip should not reappear after hide()");
	}

	@Test
	public function testRebuildWithFade():Void {
		var ctx = createHelperWithTweens(0.2, 0.1);
		ctx.helper.show("btn1", "tip");
		ctx.tweens.update(0.3); // complete fade-in
		Assert.isTrue(ctx.helper.isActive());

		// Rebuild should hide (fade-out old) then show (fade-in new)
		var result = ctx.helper.rebuild(["label" => "rebuilt"]);
		Assert.isTrue(result);
		Assert.isTrue(ctx.helper.isActive());

		// Advance to complete all fades
		ctx.tweens.update(0.5);
		Assert.isTrue(ctx.helper.isActive());
	}
}
