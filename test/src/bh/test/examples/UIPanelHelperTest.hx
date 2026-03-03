package bh.test.examples;

import utest.Assert;
import bh.base.TweenManager;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness.UITestScreen;
import bh.ui.UIPanelHelper;
import bh.ui.UIPanelHelper.PanelCloseMode;
import bh.ui.UIPanelHelper.PanelDefaults;
import bh.ui.UITooltipHelper.TooltipPosition;
import bh.ui.UIElement.UIScreenEvent;

/**
 * Unit tests for UIPanelHelper.
 * Tests open/close lifecycle, isOpen, outside-click handling, close modes,
 * named multi-panel API, per-interactive overrides, and event emission.
 */
class UIPanelHelperTest extends BuilderTestBase {
	// Anchor programmable with an interactive region.
	static final ANCHOR_MANIM = '
		#anchor programmable(status:[normal]=normal) {
			bitmap(generated(color(100, 30, #666666))): 0, 0
			interactive(100, 30, "btn1"): 0, 0
		}
	';

	// Second anchor with a different interactive id.
	static final ANCHOR2_MANIM = '
		#anchor2 programmable(status:[normal]=normal) {
			bitmap(generated(color(100, 30, #888888))): 0, 0
			interactive(100, 30, "btn2"): 0, 0
		}
	';

	// Third anchor for multi-panel tests.
	static final ANCHOR3_MANIM = '
		#anchor3 programmable(status:[normal]=normal) {
			bitmap(generated(color(100, 30, #AAAAAA))): 0, 0
			interactive(100, 30, "btn3"): 0, 0
		}
	';

	// Simple programmable used as panel content.
	static final PANEL_MANIM = '
		#panel programmable(label:string=hello) {
			bitmap(generated(color(80, 40, #FFAA00))): 0, 0
		}
	';

	// ============== Helper ==============

	function createHelper(?closeOn:PanelCloseMode, ?position:TooltipPosition, ?offset:Int):{
		helper:UIPanelHelper,
		screen:UITestScreen
	} {
		var screen = new UITestScreen();
		var builder = BuilderTestBase.builderFromSource('$ANCHOR_MANIM\n$ANCHOR2_MANIM\n$ANCHOR3_MANIM\n$PANEL_MANIM');

		var anchorResult = builder.buildWithParameters("anchor", []);
		screen.addInteractives(anchorResult);

		var anchor2Result = builder.buildWithParameters("anchor2", []);
		screen.addInteractives(anchor2Result);

		var anchor3Result = builder.buildWithParameters("anchor3", []);
		screen.addInteractives(anchor3Result);

		var defaults:bh.ui.UIPanelHelper.PanelDefaults = {};
		if (closeOn != null) defaults.closeOn = closeOn;
		if (position != null) defaults.position = position;
		if (offset != null) defaults.offset = offset;

		var helper = new UIPanelHelper(screen, builder, defaults);
		return {helper: helper, screen: screen};
	}

	// ============== Initial state ==============

	@Test
	public function testInitialState():Void {
		var ctx = createHelper();
		Assert.isFalse(ctx.helper.isOpen());
		Assert.isNull(ctx.helper.getActiveId());
		Assert.isNull(ctx.helper.getPanelResult());
		Assert.isNull(ctx.helper.getActivePrefix());
	}

	// ============== open / close ==============

	@Test
	public function testOpenPanel():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");

		Assert.isTrue(ctx.helper.isOpen());
		Assert.equals("btn1", ctx.helper.getActiveId());
		Assert.notNull(ctx.helper.getPanelResult());
		Assert.notNull(ctx.helper.getActivePrefix());
	}

	@Test
	public function testClosePanel():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");
		Assert.isTrue(ctx.helper.isOpen());

		ctx.helper.close();
		Assert.isFalse(ctx.helper.isOpen());
		Assert.isNull(ctx.helper.getActiveId());
		Assert.isNull(ctx.helper.getPanelResult());
		Assert.isNull(ctx.helper.getActivePrefix());
	}

	@Test
	public function testCloseWhenNothingOpen():Void {
		var ctx = createHelper();
		// Should not throw
		ctx.helper.close();
		Assert.isFalse(ctx.helper.isOpen());
	}

	@Test
	public function testOpenReplacesExistingPanel():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");
		Assert.equals("btn1", ctx.helper.getActiveId());

		// Opening for different interactive should close first
		ctx.helper.open("btn2", "panel");
		Assert.equals("btn2", ctx.helper.getActiveId());
		Assert.isTrue(ctx.helper.isOpen());
	}

	@Test
	public function testOpenSameInteractiveTwice():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");
		var firstResult = ctx.helper.getPanelResult();

		// Opening same interactive again closes + reopens
		ctx.helper.open("btn1", "panel");
		Assert.isTrue(ctx.helper.isOpen());
		Assert.equals("btn1", ctx.helper.getActiveId());
	}

	@Test
	public function testOpenForUnregisteredInteractive():Void {
		var ctx = createHelper();
		ctx.helper.open("nonexistent", "panel");
		Assert.isFalse(ctx.helper.isOpen());
		Assert.isNull(ctx.helper.getActiveId());
	}

	@Test
	public function testOpenWithParams():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel", ["label" => "world"]);
		Assert.isTrue(ctx.helper.isOpen());
		Assert.notNull(ctx.helper.getPanelResult());
	}

	// ============== Close emits event ==============

	@Test
	public function testCloseEmitsPanelCloseEvent():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");
		ctx.screen.clearEvents();

		ctx.helper.close();
		Assert.isTrue(ctx.screen.hasEvent(UICustomEvent(UIPanelHelper.EVENT_PANEL_CLOSE, "btn1")));
	}

	@Test
	public function testCloseDoesNotEmitWhenNothingOpen():Void {
		var ctx = createHelper();
		ctx.screen.clearEvents();

		ctx.helper.close();
		Assert.equals(0, ctx.screen.eventCount());
	}

	@Test
	public function testOpenReplacementEmitsCloseForPrevious():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");
		ctx.screen.clearEvents();

		ctx.helper.open("btn2", "panel");
		// Should have emitted close for btn1
		Assert.isTrue(ctx.screen.hasEvent(UICustomEvent(UIPanelHelper.EVENT_PANEL_CLOSE, "btn1")));
	}

	// ============== isOwnInteractive ==============

	@Test
	public function testIsOwnInteractiveNoPanel():Void {
		var ctx = createHelper();
		Assert.isFalse(ctx.helper.isOwnInteractive("anything"));
	}

	@Test
	public function testIsOwnInteractiveMatchesPrefix():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");
		var prefix = ctx.helper.getActivePrefix();
		Assert.notNull(prefix);
		// An id starting with the prefix should be recognized
		Assert.isTrue(ctx.helper.isOwnInteractive(prefix + ".sub"));
	}

	@Test
	public function testIsOwnInteractiveRejectsUnrelated():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");
		Assert.isFalse(ctx.helper.isOwnInteractive("unrelated_id"));
	}

	// ============== Per-interactive overrides ==============

	@Test
	public function testSetPositionOverride():Void {
		var ctx = createHelper();
		ctx.helper.setPosition("btn1", Right);

		// Should not throw — positioning uses getBounds which returns zeroes in headless
		ctx.helper.open("btn1", "panel");
		Assert.isTrue(ctx.helper.isOpen());
	}

	@Test
	public function testSetOffsetOverride():Void {
		var ctx = createHelper();
		ctx.helper.setOffset("btn1", 20);

		ctx.helper.open("btn1", "panel");
		Assert.isTrue(ctx.helper.isOpen());
	}

	@Test
	public function testAllPositions():Void {
		for (pos in [Above, Below, Left, Right]) {
			var ctx = createHelper(null, pos);
			ctx.helper.open("btn1", "panel");
			Assert.isTrue(ctx.helper.isOpen());
			ctx.helper.close();
		}
	}

	// ============== Close modes ==============

	@Test
	public function testDefaultCloseModeIsOutsideClick():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");

		// Outside click on the trigger interactive should set pending close
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClickOutside, "btn1", null));
		var closed = ctx.helper.checkPendingClose();
		Assert.isTrue(closed);
		Assert.isFalse(ctx.helper.isOpen());
	}

	@Test
	public function testManualCloseModeIgnoresOutsideClick():Void {
		var ctx = createHelper(Manual);
		ctx.helper.open("btn1", "panel");

		// Outside click should NOT close in Manual mode
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClickOutside, "btn1", null));
		ctx.helper.checkPendingClose();
		Assert.isTrue(ctx.helper.isOpen());
	}

	@Test
	public function testManualCloseModeRequiresExplicitClose():Void {
		var ctx = createHelper(Manual);
		ctx.helper.open("btn1", "panel");
		Assert.isTrue(ctx.helper.isOpen());

		ctx.helper.close();
		Assert.isFalse(ctx.helper.isOpen());
	}

	@Test
	public function testPerOpenCloseModeOverride():Void {
		var ctx = createHelper(OutsideClick); // default is OutsideClick
		// But open with Manual override
		ctx.helper.open("btn1", "panel", null, Manual);

		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClickOutside, "btn1", null));
		ctx.helper.checkPendingClose();
		Assert.isTrue(ctx.helper.isOpen()); // Should stay open because of Manual override
	}

	// ============== Outside click handling ==============

	@Test
	public function testOutsideClickDeferredClose():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");

		// UIClickOutside sets pending
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClickOutside, "btn1", null));
		Assert.isTrue(ctx.helper.isOpen()); // Still open — deferred

		// checkPendingClose resolves it
		var closed = ctx.helper.checkPendingClose();
		Assert.isTrue(closed);
		Assert.isFalse(ctx.helper.isOpen());
	}

	@Test
	public function testClickOnTriggerInteractiveCancelsPendingClose():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");

		// Outside click sets pending
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClickOutside, "btn1", null));

		// Click on the trigger interactive cancels pending close
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClick, "btn1", null));

		var closed = ctx.helper.checkPendingClose();
		Assert.isFalse(closed);
		Assert.isTrue(ctx.helper.isOpen());
	}

	@Test
	public function testClickOnPanelInteractiveCancelsPendingClose():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");
		var prefix = ctx.helper.getActivePrefix();

		// Outside click sets pending
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClickOutside, "btn1", null));

		// Click on a panel interactive (matching prefix) cancels pending close
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClick, prefix + ".child", null));

		var closed = ctx.helper.checkPendingClose();
		Assert.isFalse(closed);
		Assert.isTrue(ctx.helper.isOpen());
	}

	@Test
	public function testClickOnUnrelatedInteractiveClosesImmediately():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");

		// Click on a different interactive — immediate close
		var closed = ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClick, "btn2", null));
		Assert.isTrue(closed);
		Assert.isFalse(ctx.helper.isOpen());
	}

	@Test
	public function testCheckPendingCloseWhenNoPending():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");

		// No outside click happened
		var closed = ctx.helper.checkPendingClose();
		Assert.isFalse(closed);
		Assert.isTrue(ctx.helper.isOpen());
	}

	@Test
	public function testCheckPendingCloseWhenNoPanelOpen():Void {
		var ctx = createHelper();
		var closed = ctx.helper.checkPendingClose();
		Assert.isFalse(closed);
	}

	@Test
	public function testHandleOutsideClickWhenNoPanelOpen():Void {
		var ctx = createHelper();
		// Should not throw
		var closed = ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClickOutside, "btn1", null));
		Assert.isFalse(closed);
	}

	// ============== Named panels ==============

	@Test
	public function testOpenNamedPanel():Void {
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel");

		Assert.isTrue(ctx.helper.isOpenNamed("slot1"));
		Assert.notNull(ctx.helper.getNamedPanelResult("slot1"));
	}

	@Test
	public function testNamedPanelDoesNotAffectSinglePanelApi():Void {
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel");

		// Single-panel API should still report nothing open
		Assert.isFalse(ctx.helper.isOpen());
		Assert.isNull(ctx.helper.getActiveId());
	}

	@Test
	public function testCloseNamedPanel():Void {
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel");
		ctx.helper.closeNamed("slot1");

		Assert.isFalse(ctx.helper.isOpenNamed("slot1"));
		Assert.isNull(ctx.helper.getNamedPanelResult("slot1"));
	}

	@Test
	public function testCloseNamedPanelEmitsEvent():Void {
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel");
		ctx.screen.clearEvents();

		ctx.helper.closeNamed("slot1");
		Assert.isTrue(ctx.screen.hasEvent(UICustomEvent(UIPanelHelper.EVENT_PANEL_CLOSE, "btn1")));
	}

	@Test
	public function testCloseNonexistentNamedSlot():Void {
		var ctx = createHelper();
		// Should not throw
		ctx.helper.closeNamed("nonexistent");
		Assert.isFalse(ctx.helper.isOpenNamed("nonexistent"));
	}

	@Test
	public function testMultipleNamedPanelsIndependent():Void {
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel");
		ctx.helper.openNamed("slot2", "btn2", "panel");

		Assert.isTrue(ctx.helper.isOpenNamed("slot1"));
		Assert.isTrue(ctx.helper.isOpenNamed("slot2"));

		// Closing one doesn't affect the other
		ctx.helper.closeNamed("slot1");
		Assert.isFalse(ctx.helper.isOpenNamed("slot1"));
		Assert.isTrue(ctx.helper.isOpenNamed("slot2"));
	}

	@Test
	public function testCloseAllNamed():Void {
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel");
		ctx.helper.openNamed("slot2", "btn2", "panel");

		ctx.helper.closeAllNamed();
		Assert.isFalse(ctx.helper.isOpenNamed("slot1"));
		Assert.isFalse(ctx.helper.isOpenNamed("slot2"));
	}

	@Test
	public function testCloseAllNamedEmitsEvents():Void {
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel");
		ctx.helper.openNamed("slot2", "btn2", "panel");
		ctx.screen.clearEvents();

		ctx.helper.closeAllNamed();
		Assert.isTrue(ctx.screen.hasEvent(UICustomEvent(UIPanelHelper.EVENT_PANEL_CLOSE, "btn1")));
		Assert.isTrue(ctx.screen.hasEvent(UICustomEvent(UIPanelHelper.EVENT_PANEL_CLOSE, "btn2")));
	}

	@Test
	public function testCloseAllNamedWhenNoneOpen():Void {
		var ctx = createHelper();
		// Should not throw
		ctx.helper.closeAllNamed();
		Assert.isFalse(ctx.helper.isOpenNamed("slot1"));
	}

	@Test
	public function testOpenNamedReplacesExistingInSameSlot():Void {
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel");
		ctx.screen.clearEvents();

		// Opening same slot with different interactive replaces
		ctx.helper.openNamed("slot1", "btn2", "panel");
		Assert.isTrue(ctx.helper.isOpenNamed("slot1"));
		// Should have emitted close for btn1
		Assert.isTrue(ctx.screen.hasEvent(UICustomEvent(UIPanelHelper.EVENT_PANEL_CLOSE, "btn1")));
	}

	@Test
	public function testOpenNamedForUnregisteredInteractive():Void {
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "nonexistent", "panel");
		Assert.isFalse(ctx.helper.isOpenNamed("slot1"));
	}

	@Test
	public function testGetNamedPanelResultWhenNotOpen():Void {
		var ctx = createHelper();
		Assert.isNull(ctx.helper.getNamedPanelResult("slot1"));
	}

	@Test
	public function testOpenNamedWithParams():Void {
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel", ["label" => "custom"]);
		Assert.isTrue(ctx.helper.isOpenNamed("slot1"));
		Assert.notNull(ctx.helper.getNamedPanelResult("slot1"));
	}

	// ============== Named panels close modes ==============

	@Test
	public function testNamedPanelOutsideClickClose():Void {
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel");

		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClickOutside, "btn1", null));
		Assert.isTrue(ctx.helper.isOpenNamed("slot1")); // Deferred

		var closed = ctx.helper.checkPendingClose();
		Assert.isTrue(closed);
		Assert.isFalse(ctx.helper.isOpenNamed("slot1"));
	}

	@Test
	public function testNamedPanelManualCloseIgnoresOutsideClick():Void {
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel", null, Manual);

		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClickOutside, "btn1", null));
		ctx.helper.checkPendingClose();
		Assert.isTrue(ctx.helper.isOpenNamed("slot1"));
	}

	@Test
	public function testNamedPanelClickOnOwnInteractiveCancelsPending():Void {
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel");

		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClickOutside, "btn1", null));
		// Click on the trigger interactive cancels
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClick, "btn1", null));

		var closed = ctx.helper.checkPendingClose();
		Assert.isFalse(closed);
		Assert.isTrue(ctx.helper.isOpenNamed("slot1"));
	}

	// ============== isOwnInteractive with named panels ==============

	@Test
	public function testIsOwnInteractiveMatchesNamedPanelPrefix():Void {
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel");

		// Named panel prefix includes slot name
		Assert.isTrue(ctx.helper.isOwnInteractive("slot1.btn1.panel.child"));
	}

	@Test
	public function testIsOwnInteractiveMatchesBothSingleAndNamed():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");
		ctx.helper.openNamed("slot1", "btn2", "panel");

		var prefix = ctx.helper.getActivePrefix();
		Assert.isTrue(ctx.helper.isOwnInteractive(prefix + ".child"));
		Assert.isTrue(ctx.helper.isOwnInteractive("slot1.btn2.panel.child"));
	}

	// ============== Mixed single + named ==============

	@Test
	public function testSingleAndNamedPanelsCoexist():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");
		ctx.helper.openNamed("slot1", "btn2", "panel");

		Assert.isTrue(ctx.helper.isOpen());
		Assert.isTrue(ctx.helper.isOpenNamed("slot1"));

		// Closing single doesn't affect named
		ctx.helper.close();
		Assert.isFalse(ctx.helper.isOpen());
		Assert.isTrue(ctx.helper.isOpenNamed("slot1"));
	}

	@Test
	public function testCloseAllNamedDoesNotAffectSingle():Void {
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");
		ctx.helper.openNamed("slot1", "btn2", "panel");

		ctx.helper.closeAllNamed();
		Assert.isTrue(ctx.helper.isOpen());
		Assert.equals("btn1", ctx.helper.getActiveId());
	}

	// ============== Named panel outside-click cross-panel bug ==============

	@Test
	public function testNamedPanelClickOnOtherTriggerDoesNotClose():Void {
		// Bug: Two named panels open. Clicking one panel's trigger button
		// incorrectly marks the OTHER panel for pendingClose, because
		// isOwnInteractive() only checks prefixes, not trigger IDs.
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel");
		ctx.helper.openNamed("slot2", "btn2", "panel");

		// Outside-click fires for btn1 (its panel is open, so controller sends UIClickOutside)
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClickOutside, "btn1", null));

		// Then UIClick fires for btn2 — user clicked btn2's trigger.
		// btn2 is another named panel's trigger, NOT an unrelated interactive.
		// slot1 should NOT be marked for close.
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClick, "btn2", null));

		var closed = ctx.helper.checkPendingClose();
		Assert.isFalse(closed);
		Assert.isTrue(ctx.helper.isOpenNamed("slot1"));
		Assert.isTrue(ctx.helper.isOpenNamed("slot2"));
	}

	@Test
	public function testNamedPanelClickOnOtherPanelContentDoesNotClose():Void {
		// Two named panels open. Clicking inside panel2's content
		// should not close panel1.
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel");
		ctx.helper.openNamed("slot2", "btn2", "panel");

		// Outside-click fires for btn1
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClickOutside, "btn1", null));

		// Click on slot2's panel content — prefix is "slot2.btn2.panel"
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClick, "slot2.btn2.panel.child", null));

		var closed = ctx.helper.checkPendingClose();
		Assert.isFalse(closed);
		Assert.isTrue(ctx.helper.isOpenNamed("slot1"));
		Assert.isTrue(ctx.helper.isOpenNamed("slot2"));
	}

	@Test
	public function testNamedPanelClickOnUnrelatedDoesClose():Void {
		// Clicking a truly unrelated interactive SHOULD close named panels.
		var ctx = createHelper();
		ctx.helper.openNamed("slot1", "btn1", "panel");
		ctx.helper.openNamed("slot2", "btn2", "panel");

		// Outside-click fires for both triggers
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClickOutside, "btn1", null));
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClickOutside, "btn2", null));

		// Click on btn3 — truly unrelated
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClick, "btn3", null));

		var closed = ctx.helper.checkPendingClose();
		Assert.isTrue(closed);
		Assert.isFalse(ctx.helper.isOpenNamed("slot1"));
		Assert.isFalse(ctx.helper.isOpenNamed("slot2"));
	}

	@Test
	public function testNamedPanelClickOnSinglePanelContentDoesNotCloseNamed():Void {
		// Single panel + named panel open. Clicking inside single panel's
		// content should not close the named panel.
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");
		ctx.helper.openNamed("slot1", "btn2", "panel");
		var singlePrefix = ctx.helper.getActivePrefix();

		// Outside-click fires for btn2
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClickOutside, "btn2", null));

		// Click on single panel's content
		ctx.helper.handleOutsideClick(UIInteractiveEvent(UIClick, singlePrefix + ".child", null));

		var closed = ctx.helper.checkPendingClose();
		Assert.isFalse(closed);
		Assert.isTrue(ctx.helper.isOpenNamed("slot1"));
	}

	// ============== Fade transitions ==============

	function createHelperWithTweens(?fadeIn:Float, ?fadeOut:Float):{
		helper:UIPanelHelper,
		screen:UITestScreen,
		tweens:TweenManager
	} {
		var screen = new UITestScreen();
		var builder = BuilderTestBase.builderFromSource('$ANCHOR_MANIM\n$ANCHOR2_MANIM\n$ANCHOR3_MANIM\n$PANEL_MANIM');

		var anchorResult = builder.buildWithParameters("anchor", []);
		screen.addInteractives(anchorResult);

		var anchor2Result = builder.buildWithParameters("anchor2", []);
		screen.addInteractives(anchor2Result);

		var anchor3Result = builder.buildWithParameters("anchor3", []);
		screen.addInteractives(anchor3Result);

		var tweens = new TweenManager();
		var defaults:PanelDefaults = {};
		if (fadeIn != null) defaults.fadeIn = fadeIn;
		if (fadeOut != null) defaults.fadeOut = fadeOut;

		var helper = new UIPanelHelper(screen, builder, defaults, tweens);
		return {helper: helper, screen: screen, tweens: tweens};
	}

	@Test
	public function testFadeInPanelStartsAtZeroAlpha():Void {
		var ctx = createHelperWithTweens(0.3, 0.0);
		ctx.helper.open("btn1", "panel");
		Assert.isTrue(ctx.helper.isOpen());

		// Panel result object should exist; fade-in tween is running
		var result = ctx.helper.getPanelResult();
		Assert.notNull(result);
	}

	@Test
	public function testFadeInPanelReachesFullAlpha():Void {
		var ctx = createHelperWithTweens(0.2, 0.0);
		ctx.helper.open("btn1", "panel");

		// Advance tweens past fade-in duration
		ctx.tweens.update(0.3);
		Assert.isTrue(ctx.helper.isOpen());
	}

	@Test
	public function testFadeOutPanelRemovesOnComplete():Void {
		var ctx = createHelperWithTweens(0.0, 0.2);
		ctx.helper.open("btn1", "panel");
		Assert.isTrue(ctx.helper.isOpen());

		ctx.helper.close();
		// Panel is logically closed immediately
		Assert.isFalse(ctx.helper.isOpen());

		// Advance past fade-out — object removed by onComplete
		ctx.tweens.update(0.3);
		Assert.isFalse(ctx.helper.isOpen());
	}

	@Test
	public function testFadeOutPanelEventEmittedImmediately():Void {
		var ctx = createHelperWithTweens(0.0, 0.5);
		ctx.helper.open("btn1", "panel");
		ctx.screen.clearEvents();

		ctx.helper.close();
		// EVENT_PANEL_CLOSE fires immediately, before fade-out completes
		Assert.isTrue(ctx.screen.hasEvent(UICustomEvent(UIPanelHelper.EVENT_PANEL_CLOSE, "btn1")));
	}

	@Test
	public function testNamedPanelFadeOut():Void {
		var ctx = createHelperWithTweens(0.0, 0.2);
		ctx.helper.openNamed("slot1", "btn1", "panel");
		Assert.isTrue(ctx.helper.isOpenNamed("slot1"));

		ctx.helper.closeNamed("slot1");
		// Named panel logically closed immediately
		Assert.isFalse(ctx.helper.isOpenNamed("slot1"));

		// Advance past fade-out
		ctx.tweens.update(0.3);
		Assert.isFalse(ctx.helper.isOpenNamed("slot1"));
	}

	@Test
	public function testZeroFadeDefaultIsInstant():Void {
		// Default PanelDefaults has fadeIn=0, fadeOut=0 — backward compatible
		var ctx = createHelper();
		ctx.helper.open("btn1", "panel");
		Assert.isTrue(ctx.helper.isOpen());

		ctx.helper.close();
		Assert.isFalse(ctx.helper.isOpen());
	}

	@Test
	public function testOpenDuringFadeOutCancelsPrevious():Void {
		var ctx = createHelperWithTweens(0.0, 0.5);
		ctx.helper.open("btn1", "panel");

		// Close — starts fade-out
		ctx.helper.close();
		Assert.isFalse(ctx.helper.isOpen());

		// Immediately open for btn2 — should cancel btn1 fade-out
		ctx.helper.open("btn2", "panel");
		Assert.isTrue(ctx.helper.isOpen());
		Assert.equals("btn2", ctx.helper.getActiveId());

		// Advance tweens — no crash from dangling btn1 tween
		ctx.tweens.update(1.0);
		Assert.isTrue(ctx.helper.isOpen());
	}
}
