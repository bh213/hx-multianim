package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.findVisibleBitmapDescendants;
import bh.test.UITestHarness.UITestScreen;
import bh.ui.UIRichInteractiveHelper;
import bh.ui.UIRichInteractiveHelper.InteractiveState;
import bh.ui.UIElement.UIScreenEvent;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.ui.UIInteractiveWrapper;
import bh.base.ColorUtils;

/**
 * Unit tests for UIRichInteractiveHelper.
 * Tests register() bind scanning, handleEvent() state machine,
 * setDisabled, manual bind/unbind, setParameter forwarding, and getResult.
 */
class UIRichInteractiveHelperTest extends BuilderTestBase {
	// Programmable with a single interactive that has bind metadata.
	static final BOUND_MANIM = '
		#bound programmable(status:[normal,hover,pressed,disabled]=normal) {
			bitmap(generated(color(100, 30, #666666))): 0, 0
			interactive(100, 30, "btn1", bind => "status"): 0, 0
		}
	';

	// Programmable with autoStatus metadata for screen auto-wiring.
	static final AUTO_STATUS_MANIM = '
		#autoBtn programmable(status:[normal,hover,pressed,disabled]=normal) {
			@(status=>normal) bitmap(generated(color(10, 10, #f00))): 0, 0
			@(status=>hover) bitmap(generated(color(20, 10, #0f0))): 0, 0
			@(status=>pressed) bitmap(generated(color(30, 10, #00f))): 0, 0
			interactive(100, 30, "btn1", autoStatus => "status"): 0, 0
		}
	';

	// Programmable with both autoStatus and bind — should throw on register.
	static final DUAL_METADATA_MANIM = '
		#dual programmable(status:[normal,hover,pressed,disabled]=normal) {
			bitmap(generated(color(100, 30, #666666))): 0, 0
			interactive(100, 30, "btn1", autoStatus => "status", bind => "status"): 0, 0
		}
	';

	// Programmable with mixed interactives: one autoStatus, one plain (no metadata).
	static final MIXED_MANIM = '
		#mixed programmable(status:[normal,hover,pressed,disabled]=normal) {
			bitmap(generated(color(200, 60, #666666))): 0, 0
			interactive(100, 30, "autoBtn", autoStatus => "status"): 0, 0
			interactive(100, 30, "plainBtn"): 0, 30
		}
	';

	// Second autoStatus programmable for multi-result tests.
	static final AUTO_STATUS_MANIM_B = '
		#autoBtnB programmable(status:[normal,hover,pressed,disabled]=normal) {
			bitmap(generated(color(10, 10, #666666))): 0, 0
			interactive(100, 30, "btn2", autoStatus => "status"): 0, 0
		}
	';

	// Programmable with two bound interactives.
	static final MULTI_BOUND_MANIM = '
		#multi programmable(status:[normal,hover,pressed,disabled]=normal) {
			bitmap(generated(color(200, 60, #666666))): 0, 0
			interactive(100, 30, "btnA", bind => "status"): 0, 0
			interactive(100, 30, "btnB", bind => "status"): 0, 30
		}
	';

	// Programmable with interactive that has NO bind metadata.
	static final UNBOUND_MANIM = '
		#unbound programmable(status:[normal,hover,pressed,disabled]=normal) {
			bitmap(generated(color(100, 30, #888888))): 0, 0
			interactive(100, 30, "btnNoBind"): 0, 0
		}
	';

	// Programmable with a custom bind parameter name.
	static final CUSTOM_BIND_MANIM = '
		#custom programmable(myState:[normal,hover,pressed,disabled]=normal) {
			bitmap(generated(color(100, 30, #AAAAAA))): 0, 0
			interactive(100, 30, "btnCustom", bind => "myState"): 0, 0
		}
	';

	// Programmable with extra non-state parameter for setParameter forwarding.
	static final PARAM_FORWARD_MANIM = '
		#paramFwd programmable(status:[normal,hover,pressed,disabled]=normal, label:string=hello) {
			bitmap(generated(color(100, 30, #CCCCCC))): 0, 0
			interactive(100, 30, "btnFwd", bind => "status"): 0, 0
		}
	';

	// Programmable with event filtering — only click events emitted.
	static final FILTERED_CLICK_MANIM = '
		#filtered programmable(status:[normal,hover,pressed,disabled]=normal) {
			bitmap(generated(color(100, 30, #666666))): 0, 0
			interactive(100, 30, "btnFiltered", bind => "status", events: [click]): 0, 0
		}
	';

	// Programmable with event filtering — only hover events emitted.
	static final FILTERED_HOVER_MANIM = '
		#filtered programmable(status:[normal,hover,pressed,disabled]=normal) {
			bitmap(generated(color(100, 30, #666666))): 0, 0
			interactive(100, 30, "btnHover", bind => "status", events: [hover]): 0, 0
		}
	';

	// Programmable with visual changes based on status, for verifying bind auto-wiring end-to-end.
	static final VISUAL_BIND_MANIM = '
		#visual programmable(status:[normal,hover,pressed,disabled]=normal) {
			@(status=>normal) bitmap(generated(color(10, 10, #f00))): 0, 0
			@(status=>hover) bitmap(generated(color(20, 10, #0f0))): 0, 0
			@(status=>pressed) bitmap(generated(color(30, 10, #00f))): 0, 0
			interactive(100, 30, "btnVis", bind => "status"): 0, 0
		}
	';

	// ============== Helpers ==============

	function createHelper(manim:String, programmableName:String, ?prefix:String):{
		helper:UIRichInteractiveHelper,
		screen:UITestScreen,
		result:BuilderResult
	} {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(manim, programmableName, null, Incremental);
		screen.addInteractives(result, prefix);
		var helper = new UIRichInteractiveHelper(screen);
		helper.register(result, prefix);
		return {helper: helper, screen: screen, result: result};
	}

	/** Read the internal state machine state for a bound interactive via @:privateAccess. */
	function getState(helper:UIRichInteractiveHelper, id:String):Null<InteractiveState> {
		@:privateAccess var bindings = helper.bindings;
		var binding = bindings.get(id);
		return binding != null ? binding.currentState : null;
	}

	function assertState(helper:UIRichInteractiveHelper, id:String, expected:InteractiveState, ?msg:String):Void {
		var actual = getState(helper, id);
		Assert.notNull(actual, 'Binding for "$id" should exist');
		Assert.isTrue(Type.enumEq(actual, expected),
			msg != null ? msg : 'Expected state $expected for "$id", got $actual');
	}

	// ============== register() bind scanning ==============

	@Test
	public function testRegisterFindsBindMetadata():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		// handleEvent should return true for bound interactive
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null)));
	}

	@Test
	public function testRegisterIgnoresInteractiveWithoutBind():Void {
		var ctx = createHelper(UNBOUND_MANIM, "unbound");
		// handleEvent should return false for unbound interactive
		Assert.isFalse(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btnNoBind", null)));
	}

	@Test
	public function testRegisterWithPrefix():Void {
		var ctx = createHelper(BOUND_MANIM, "bound", "pfx");
		// With prefix, full id is "pfx.btn1"
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "pfx.btn1", null)));
		// Without prefix should not match
		Assert.isFalse(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null)));
	}

	@Test
	public function testRegisterMultipleInteractives():Void {
		var ctx = createHelper(MULTI_BOUND_MANIM, "multi");
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btnA", null)));
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btnB", null)));
	}

	@Test
	public function testRegisterCustomBindParam():Void {
		var ctx = createHelper(CUSTOM_BIND_MANIM, "custom");
		// Should bind to "myState" parameter — handleEvent returns true
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btnCustom", null)));
	}

	// ============== handleEvent() state machine ==============

	@Test
	public function testEnterSetsHover():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		assertState(ctx.helper, "btn1", Normal);
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null));
		Assert.isTrue(handled);
		assertState(ctx.helper, "btn1", Hover);
	}

	@Test
	public function testPushAfterEnterSetPressed():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null));
		assertState(ctx.helper, "btn1", Hover);
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		Assert.isTrue(handled);
		assertState(ctx.helper, "btn1", Pressed);
	}

	@Test
	public function testClickAfterPushReturnsToHover():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null));
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		assertState(ctx.helper, "btn1", Pressed);
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIClick, "btn1", null));
		Assert.isTrue(handled);
		assertState(ctx.helper, "btn1", Hover);
	}

	@Test
	public function testLeaveFromHoverReturnsToNormal():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null));
		assertState(ctx.helper, "btn1", Hover);
		ctx.helper.handleEvent(UIInteractiveEvent(UILeaving, "btn1", null));
		assertState(ctx.helper, "btn1", Normal);
	}

	@Test
	public function testLeaveFromPressedReturnsToNormal():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null));
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		assertState(ctx.helper, "btn1", Pressed);
		ctx.helper.handleEvent(UIInteractiveEvent(UILeaving, "btn1", null));
		assertState(ctx.helper, "btn1", Normal);
	}

	@Test
	public function testPushFromNormalGoesToPressed():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		// Push without prior Enter (touch input path) — should go to Pressed
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		assertState(ctx.helper, "btn1", Pressed);
	}

	@Test
	public function testTouchCycleClickReturnsToNormal():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		// Touch tap: no prior hover. Push from Normal → Pressed, Click → Normal.
		// (Mouse path returns to Hover; touch path must not leave element stuck "hovered".)
		assertState(ctx.helper, "btn1", Normal);
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		assertState(ctx.helper, "btn1", Pressed);
		ctx.helper.handleEvent(UIInteractiveEvent(UIClick, "btn1", null));
		assertState(ctx.helper, "btn1", Normal,
			"Click from touch-initiated Pressed (no prior Hover) should return to Normal, not Hover");
	}

	@Test
	public function testClickWithoutPushIsIgnored():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null));
		assertState(ctx.helper, "btn1", Hover);
		// Click without Push — requires Pressed state
		ctx.helper.handleEvent(UIInteractiveEvent(UIClick, "btn1", null));
		// Should still be in Hover (click ignored from Hover)
		assertState(ctx.helper, "btn1", Hover);
	}

	@Test
	public function testFullCycleEnterPushClickLeave():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		// Full interaction cycle: Normal → Hover → Pressed → Hover → Normal
		assertState(ctx.helper, "btn1", Normal);
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null));
		assertState(ctx.helper, "btn1", Hover);
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		assertState(ctx.helper, "btn1", Pressed);
		ctx.helper.handleEvent(UIInteractiveEvent(UIClick, "btn1", null));
		assertState(ctx.helper, "btn1", Hover);
		ctx.helper.handleEvent(UIInteractiveEvent(UILeaving, "btn1", null));
		assertState(ctx.helper, "btn1", Normal);
	}

	@Test
	public function testUnknownInteractiveReturnsFalse():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		Assert.isFalse(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "unknown", null)));
	}

	@Test
	public function testNonInteractiveEventReturnsFalse():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		Assert.isFalse(ctx.helper.handleEvent(UIClick));
	}

	@Test
	public function testMultipleInteractivesIndependent():Void {
		var ctx = createHelper(MULTI_BOUND_MANIM, "multi");
		// Enter A — should not affect B
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btnA", null));
		// B can still enter independently
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btnB", null)));
		// Leave A
		ctx.helper.handleEvent(UIInteractiveEvent(UILeaving, "btnA", null));
		// B should still respond (still in Hover)
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btnB", null)));
	}

	// ============== setDisabled ==============

	@Test
	public function testSetDisabledBlocksEvents():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.setDisabled("btn1", true);
		assertState(ctx.helper, "btn1", Disabled);
		// Events should return true (bound) but not change state
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null));
		Assert.isTrue(handled); // Still returns true because it IS bound
		assertState(ctx.helper, "btn1", Disabled); // State unchanged
	}

	@Test
	public function testSetDisabledThenEnabled():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.setDisabled("btn1", true);
		ctx.helper.setDisabled("btn1", false);
		// Should work normally after re-enabling
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null));
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIClick, "btn1", null)));
	}

	@Test
	public function testSetDisabledOnUnknownInteractive():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		// Should not throw, and should not affect existing bindings
		ctx.helper.setDisabled("nonexistent", true);
		assertState(ctx.helper, "btn1", Normal);
	}

	@Test
	public function testDisabledDoesNotTransitionOnEnter():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		// Enter first, then disable
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null));
		assertState(ctx.helper, "btn1", Hover);
		ctx.helper.setDisabled("btn1", true);
		assertState(ctx.helper, "btn1", Disabled);
		// Push should be blocked (disabled state)
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		assertState(ctx.helper, "btn1", Disabled);
		// Re-enable — state was reset to Normal by setDisabled(false)
		ctx.helper.setDisabled("btn1", false);
		assertState(ctx.helper, "btn1", Normal);
		// After re-enable, entering should work from Normal
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null));
		assertState(ctx.helper, "btn1", Hover);
	}

	@Test
	public function testSetDisabledDisablesWrapper():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.setDisabled("btn1", true);
		var wrapper = ctx.screen.getInteractive("btn1");
		Assert.notNull(wrapper);
		Assert.isTrue(wrapper.disabled);
	}

	@Test
	public function testSetEnabledEnablesWrapper():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.setDisabled("btn1", true);
		ctx.helper.setDisabled("btn1", false);
		var wrapper = ctx.screen.getInteractive("btn1");
		Assert.notNull(wrapper);
		Assert.isFalse(wrapper.disabled);
	}

	// ============== Manual bind / unbind ==============

	@Test
	public function testManualBind():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(UNBOUND_MANIM, "unbound", null, Incremental);
		screen.addInteractives(result);
		var helper = new UIRichInteractiveHelper(screen);
		// Manually bind the unbound interactive
		helper.bind("btnNoBind", result, "status");
		Assert.isTrue(helper.handleEvent(UIInteractiveEvent(UIEntering(), "btnNoBind", null)));
	}

	@Test
	public function testUnbind():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.unbind("btn1");
		Assert.isFalse(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null)));
	}

	@Test
	public function testUnbindAll():Void {
		var ctx = createHelper(MULTI_BOUND_MANIM, "multi");
		ctx.helper.unbindAll();
		Assert.isFalse(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btnA", null)));
		Assert.isFalse(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btnB", null)));
	}

	@Test
	public function testUnregister():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.unregister(ctx.result);
		Assert.isFalse(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null)));
	}

	@Test
	public function testUnregisterOnlyRemovesMatchingResult():Void {
		var screen = new UITestScreen();
		var result1 = BuilderTestBase.buildFromSource(BOUND_MANIM, "bound", null, Incremental);
		screen.addInteractives(result1);

		var result2 = BuilderTestBase.buildFromSource(CUSTOM_BIND_MANIM, "custom", null, Incremental);
		screen.addInteractives(result2);

		var helper = new UIRichInteractiveHelper(screen);
		helper.register(result1);
		helper.register(result2);

		// Unregister only result1
		helper.unregister(result1);
		Assert.isFalse(helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null)));
		Assert.isTrue(helper.handleEvent(UIInteractiveEvent(UIEntering(), "btnCustom", null)));
	}

	// ============== getResult ==============

	@Test
	public function testGetResultReturnsBoundResult():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		Assert.equals((ctx.result : bh.ui.UIInteractiveSource), ctx.helper.getSource("btn1"));
	}

	@Test
	public function testGetResultReturnsNullForUnknown():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		Assert.isNull(ctx.helper.getSource("nonexistent"));
	}

	@Test
	public function testGetResultReturnsNullAfterUnbind():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.unbind("btn1");
		Assert.isNull(ctx.helper.getSource("btn1"));
	}

	// ============== setParameter forwarding ==============

	@Test
	public function testSetParameterOnBoundInteractive():Void {
		var ctx = createHelper(PARAM_FORWARD_MANIM, "paramFwd");
		// Forwards "label" parameter to the BuilderResult — verify state unaffected
		ctx.helper.setParameter("btnFwd", "label", "world");
		assertState(ctx.helper, "btnFwd", Normal);
		// Verify the result is still accessible (parameter forwarded to it)
		Assert.notNull(ctx.helper.getSource("btnFwd"));
	}

	@Test
	public function testSetParameterOnUnknownInteractive():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		// Should silently do nothing — existing binding unaffected
		ctx.helper.setParameter("nonexistent", "label", "world");
		assertState(ctx.helper, "btn1", Normal);
	}

	// ============== Repeated full cycles ==============

	@Test
	public function testRepeatedCycles():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		// Run multiple interaction cycles
		for (_ in 0...3) {
			ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null));
			ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
			ctx.helper.handleEvent(UIInteractiveEvent(UIClick, "btn1", null));
			ctx.helper.handleEvent(UIInteractiveEvent(UILeaving, "btn1", null));
		}
		// Should still work after multiple cycles
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null)));
	}

	// ============== Event filtering ==============

	@Test
	public function testEventFilteringClickOnly():Void {
		var ctx = createHelper(FILTERED_CLICK_MANIM, "filtered");
		var wrapper = ctx.screen.getInteractive("btnFiltered");
		Assert.notNull(wrapper);
		// EVENT_CLICK = 2, so only click bit should be set
		Assert.equals(UIInteractiveWrapper.EVENT_CLICK, wrapper.eventFlags);
	}

	@Test
	public function testEventFilteringHoverOnly():Void {
		var ctx = createHelper(FILTERED_HOVER_MANIM, "filtered");
		var wrapper = ctx.screen.getInteractive("btnHover");
		Assert.notNull(wrapper);
		// EVENT_HOVER = 1, so only hover bit should be set
		Assert.equals(UIInteractiveWrapper.EVENT_HOVER, wrapper.eventFlags);
	}

	@Test
	public function testDefaultEventFlagsAreAll():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		var wrapper = ctx.screen.getInteractive("btn1");
		Assert.notNull(wrapper);
		// Default: all events enabled (EVENT_ALL = 7)
		Assert.equals(UIInteractiveWrapper.EVENT_ALL, wrapper.eventFlags);
	}

	// ============== Bind auto-wiring end-to-end ==============

	@Test
	public function testBindAutoWiringUpdatesVisual():Void {
		// Verify the full chain: register() auto-wires bind metadata,
		// handleEvent() drives state, setParameter() updates the visual.
		var ctx = createHelper(VISUAL_BIND_MANIM, "visual");
		// Initial state: normal → 10px wide bitmap
		var bitmaps = findVisibleBitmapDescendants(ctx.result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Enter → hover → should now show 20px wide bitmap
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btnVis", null));
		assertState(ctx.helper, "btnVis", Hover);
		bitmaps = findVisibleBitmapDescendants(ctx.result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testBindAutoWiringFullCycleVisual():Void {
		var ctx = createHelper(VISUAL_BIND_MANIM, "visual");
		// Enter → 20px
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btnVis", null));
		var bitmaps = findVisibleBitmapDescendants(ctx.result.object);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Push → pressed → 30px
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btnVis", null));
		bitmaps = findVisibleBitmapDescendants(ctx.result.object);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));

		// Leave → normal → 10px
		ctx.helper.handleEvent(UIInteractiveEvent(UILeaving, "btnVis", null));
		bitmaps = findVisibleBitmapDescendants(ctx.result.object);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	// ============== setDisabled hover awareness (Bug 1.1) ==============

	@Test
	public function testSetDisabledFalseRestoresHoverWhenMouseOver():Void {
		// Bug 1.1: setDisabled(false) always resets to Normal, even if mouse is over the interactive.
		// When UIInteractiveWrapper.hovered is true, re-enabling should set Hover, not Normal.
		var ctx = createHelper(BOUND_MANIM, "bound");
		var wrapper = ctx.screen.getInteractive("btn1");
		Assert.notNull(wrapper);

		// Simulate hover enter — set wrapper.hovered directly since handleEvent
		// processes screen-level events (wrapper.hovered is set by UIInteractiveWrapper.onEvent)
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null));
		assertState(ctx.helper, "btn1", Hover);
		@:privateAccess wrapper.hovered = true;
		Assert.isTrue(wrapper.hovered);

		// Disable while hovered
		ctx.helper.setDisabled("btn1", true);
		assertState(ctx.helper, "btn1", Disabled);

		// Re-enable — mouse is still over (wrapper.hovered is still true because no UILeaving fired)
		ctx.helper.setDisabled("btn1", false);
		// Should be Hover since mouse is still over, not Normal
		assertState(ctx.helper, "btn1", Hover, "Bug 1.1: setDisabled(false) should restore Hover when mouse is over");
	}

	// ============== UIClickOutside ==============

	@Test
	public function testClickOutsideDoesNotChangeState():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		// Enter to set Hover, then push to set Pressed
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering(), "btn1", null));
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		assertState(ctx.helper, "btn1", Pressed);

		// UIClickOutside should not change state (falls through to default in inner switch)
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIClickOutside, "btn1", null));
		Assert.isTrue(handled, "Should return true (interactive is registered)");
		assertState(ctx.helper, "btn1", Pressed, "UIClickOutside should not change state");
	}

	@Test
	public function testClickOutsideOnUnregisteredReturnsFalse():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIClickOutside, "unknown", null));
		Assert.isFalse(handled, "UIClickOutside for unknown ID should return false");
	}

	// ============== autoStatus auto-wiring ==============

	@Test
	public function testAutoStatusRegistersViaAddInteractives():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(result);
		// autoStatus should have created the auto helper
		var autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper, "autoStatus metadata should create auto helper");
		Assert.isTrue(autoHelper.hasBinding("btn1"), "btn1 should be auto-bound");
	}

	@Test
	public function testAutoStatusHandlesEventsAutomatically():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(result);
		var autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper);
		// Simulate event via dispatchScreenEvent (as controller would)
		screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "btn1", null), null);
		assertState(autoHelper, "btn1", Hover);
	}

	@Test
	public function testAutoStatusFullCycle():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(result);
		var autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper);
		// Full cycle via dispatchScreenEvent
		screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "btn1", null), null);
		assertState(autoHelper, "btn1", Hover);
		screen.dispatchScreenEvent(UIInteractiveEvent(UIPush, "btn1", null), null);
		assertState(autoHelper, "btn1", Pressed);
		screen.dispatchScreenEvent(UIInteractiveEvent(UIClick, "btn1", null), null);
		assertState(autoHelper, "btn1", Hover);
		screen.dispatchScreenEvent(UIInteractiveEvent(UILeaving, "btn1", null), null);
		assertState(autoHelper, "btn1", Normal);
	}

	@Test
	public function testAutoStatusEventsStillReachScreen():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(result);
		// dispatchScreenEvent should call onScreenEvent too
		screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "btn1", null), null);
		Assert.isTrue(screen.hasEvent(UIInteractiveEvent(UIEntering(), "btn1", null)),
			"Event should still reach screen's onScreenEvent");
	}

	@Test
	public function testAutoStatusUpdatesVisual():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(result);
		// Initial: normal → 10px wide
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
		// Hover → 20px wide
		screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "btn1", null), null);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testAutoStatusNoHelperWithoutMetadata():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(UNBOUND_MANIM, "unbound", null, Incremental);
		screen.addInteractives(result);
		Assert.isNull(screen.getAutoInteractiveHelper(), "No autoStatus metadata → no auto helper");
	}

	@Test
	public function testAutoStatusIgnoresBindMetadata():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(BOUND_MANIM, "bound", null, Incremental);
		screen.addInteractives(result);
		// bind metadata should NOT trigger auto-wiring
		Assert.isNull(screen.getAutoInteractiveHelper(), "bind metadata should not trigger auto helper");
	}

	@Test
	public function testAutoStatusWithPrefix():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(result, "pfx");
		var autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper);
		Assert.isTrue(autoHelper.hasBinding("pfx.btn1"), "Should bind with prefix");
		Assert.isFalse(autoHelper.hasBinding("btn1"), "Should not bind without prefix");
	}

	@Test
	public function testAutoStatusClearResetsHelper():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(result);
		Assert.notNull(screen.getAutoInteractiveHelper());
		screen.clear();
		Assert.isNull(screen.getAutoInteractiveHelper(), "clear() should reset auto helper");
	}

	@Test
	public function testAutoStatusRemoveInteractivesUnregisters():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(result, "pfx");
		var autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper);
		Assert.isTrue(autoHelper.hasBinding("pfx.btn1"));
		screen.removeInteractives("pfx");
		Assert.isFalse(autoHelper.hasBinding("pfx.btn1"), "removeInteractives should unregister from auto helper");
	}

	// ============== autoStatus reservation ==============

	@Test
	public function testReservedKeyThrowsOnManualRegister():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		var helper = new UIRichInteractiveHelper(screen);
		// Manually registering with reserved key should throw
		var threw = false;
		try {
			helper.register(result, null, "autoStatus");
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "Using reserved 'autoStatus' key in manual register() should throw");
	}

	// ============== collision detection ==============

	@Test
	public function testCollisionThrowsWhenAutoStatusAlreadyRegistered():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(DUAL_METADATA_MANIM, "dual", null, Incremental);
		// addInteractives registers autoStatus first
		screen.addInteractives(result);
		Assert.notNull(screen.getAutoInteractiveHelper());
		// Now manual register with "bind" should throw because auto-helper already owns btn1
		var helper = new UIRichInteractiveHelper(screen);
		var threw = false;
		try {
			helper.register(result);
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "register() should throw when interactive already managed by autoStatus");
	}

	// ============== hasBinding ==============

	@Test
	public function testHasBinding():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		Assert.isTrue(ctx.helper.hasBinding("btn1"));
		Assert.isFalse(ctx.helper.hasBinding("unknown"));
	}

	// ============== unregisterByPrefix ==============

	@Test
	public function testUnregisterByPrefix():Void {
		var screen = new UITestScreen();
		var result1 = BuilderTestBase.buildFromSource(BOUND_MANIM, "bound", null, Incremental);
		screen.addInteractives(result1, "a");
		var result2 = BuilderTestBase.buildFromSource(CUSTOM_BIND_MANIM, "custom", null, Incremental);
		screen.addInteractives(result2, "b");
		var helper = new UIRichInteractiveHelper(screen);
		helper.register(result1, "a");
		helper.register(result2, "b");
		Assert.isTrue(helper.hasBinding("a.btn1"));
		Assert.isTrue(helper.hasBinding("b.btnCustom"));
		helper.unregisterByPrefix("a");
		Assert.isFalse(helper.hasBinding("a.btn1"), "a.btn1 should be removed");
		Assert.isTrue(helper.hasBinding("b.btnCustom"), "b.btnCustom should remain");
	}

	// ============== autoStatus: multiple results ==============

	@Test
	public function testAutoStatusMultipleResultsShareHelper():Void {
		var screen = new UITestScreen();
		var resultA = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(resultA, "a");
		var resultB = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM_B, "autoBtnB", null, Incremental);
		screen.addInteractives(resultB, "b");
		var autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper);
		Assert.isTrue(autoHelper.hasBinding("a.btn1"), "First result's interactive should be bound");
		Assert.isTrue(autoHelper.hasBinding("b.btn2"), "Second result's interactive should be bound");
	}

	@Test
	public function testAutoStatusMultipleResultsIndependentState():Void {
		var screen = new UITestScreen();
		var resultA = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(resultA, "a");
		var resultB = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM_B, "autoBtnB", null, Incremental);
		screen.addInteractives(resultB, "b");
		var autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper);
		// Hover on first should not affect second
		screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "a.btn1", null), null);
		assertState(autoHelper, "a.btn1", Hover);
		assertState(autoHelper, "b.btn2", Normal, "Second interactive should remain Normal");
	}

	// ============== autoStatus: mixed metadata in same result ==============

	@Test
	public function testAutoStatusMixedOnlyAutoWiresAutoStatus():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(MIXED_MANIM, "mixed", null, Incremental);
		screen.addInteractives(result);
		var autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper, "autoStatus on autoBtn should create helper");
		Assert.isTrue(autoHelper.hasBinding("autoBtn"), "autoBtn should be auto-bound");
		Assert.isFalse(autoHelper.hasBinding("plainBtn"), "plainBtn (no metadata) should NOT be auto-bound");
	}

	@Test
	public function testAutoStatusMixedPlainInteractiveEventsPassThrough():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(MIXED_MANIM, "mixed", null, Incremental);
		screen.addInteractives(result);
		// plainBtn events should still reach screen even though autoHelper exists
		screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "plainBtn", null), null);
		Assert.isTrue(screen.hasEvent(UIInteractiveEvent(UIEntering(), "plainBtn", null)),
			"plainBtn event should reach screen's onScreenEvent");
	}

	// ============== autoStatus: setDisabled via auto helper ==============

	@Test
	public function testAutoStatusSetDisabled():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(result);
		var autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper);
		autoHelper.setDisabled("btn1", true);
		assertState(autoHelper, "btn1", Disabled);
		// Events should not change state while disabled
		screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "btn1", null), null);
		assertState(autoHelper, "btn1", Disabled, "Disabled should block hover via auto-wiring");
	}

	@Test
	public function testAutoStatusSetDisabledThenReEnabled():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(result);
		var autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper);
		autoHelper.setDisabled("btn1", true);
		autoHelper.setDisabled("btn1", false);
		assertState(autoHelper, "btn1", Normal);
		// Should respond to events again
		screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "btn1", null), null);
		assertState(autoHelper, "btn1", Hover, "Re-enabled interactive should respond to hover");
	}

	// ============== autoStatus: re-add after clear ==============

	@Test
	public function testAutoStatusReAddAfterClear():Void {
		var screen = new UITestScreen();
		var result1 = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(result1);
		Assert.notNull(screen.getAutoInteractiveHelper());
		screen.clear();
		Assert.isNull(screen.getAutoInteractiveHelper(), "clear() should null auto helper");
		// Re-add — should recreate helper
		var result2 = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(result2);
		var autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper, "Re-adding autoStatus interactives should recreate helper");
		Assert.isTrue(autoHelper.hasBinding("btn1"));
		// Should work normally
		screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "btn1", null), null);
		assertState(autoHelper, "btn1", Hover);
	}

	// ============== collision detection: bind first, then autoStatus ==============

	@Test
	public function testCollisionBindFirstThenAutoStatus():Void {
		// Manually register with "bind" key, then addInteractives with autoStatus on same id
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(DUAL_METADATA_MANIM, "dual", null, Incremental);
		// Manually register first with bind key
		var manualHelper = new UIRichInteractiveHelper(screen);
		manualHelper.register(result);
		Assert.isTrue(manualHelper.hasBinding("btn1"));
		// Now addInteractives — autoStatus scan should succeed (it doesn't check manual helpers)
		// The collision is only checked in the other direction (manual register checks auto helper)
		screen.addInteractives(result);
		Assert.notNull(screen.getAutoInteractiveHelper());
	}

	@Test
	public function testCollisionCustomKeyWhenAutoStatusExists():Void {
		// Register autoStatus via addInteractives, then try manual register with custom key
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(DUAL_METADATA_MANIM, "dual", null, Incremental);
		screen.addInteractives(result);
		Assert.notNull(screen.getAutoInteractiveHelper());
		// Manual register with custom key "myKey" should throw (same interactive managed by autoStatus)
		var helper = new UIRichInteractiveHelper(screen);
		var threw = false;
		try {
			helper.register(result, null, "bind");
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "register() with any custom key should throw when autoStatus manages same interactive");
	}

	// ============== collision detection: prefix-scoped ==============

	@Test
	public function testCollisionWithPrefixedAutoStatus():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(DUAL_METADATA_MANIM, "dual", null, Incremental);
		screen.addInteractives(result, "pfx");
		Assert.notNull(screen.getAutoInteractiveHelper());
		Assert.isTrue(screen.getAutoInteractiveHelper().hasBinding("pfx.btn1"));
		// Manual register with same prefix should throw
		var helper = new UIRichInteractiveHelper(screen);
		var threw = false;
		try {
			helper.register(result, "pfx");
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "Collision should be detected with prefixed autoStatus");
	}

	// ============== no collision for different interactive ids ==============

	@Test
	public function testNoCollisionDifferentIds():Void {
		// autoStatus on "autoBtn", manual bind on "plainBtn" — no collision
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(MIXED_MANIM, "mixed", null, Incremental);
		screen.addInteractives(result);
		Assert.notNull(screen.getAutoInteractiveHelper());
		Assert.isTrue(screen.getAutoInteractiveHelper().hasBinding("autoBtn"));
		// Manual helper binding plainBtn should NOT throw (different interactive)
		var helper = new UIRichInteractiveHelper(screen);
		helper.bind("plainBtn", result, "status");
		Assert.isTrue(helper.hasBinding("plainBtn"), "Manual bind on different id should succeed");
	}

	@Test
	public function testNoCollisionDifferentPrefixes():Void {
		// autoStatus with prefix "a", manual bind with prefix "b" — no collision
		var screen = new UITestScreen();
		var resultA = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(resultA, "a");
		var resultB = BuilderTestBase.buildFromSource(BOUND_MANIM, "bound", null, Incremental);
		screen.addInteractives(resultB, "b");
		Assert.notNull(screen.getAutoInteractiveHelper());
		Assert.isTrue(screen.getAutoInteractiveHelper().hasBinding("a.btn1"));
		// Manual register on "b" prefix should NOT throw (different id: b.btn1 vs a.btn1)
		var helper = new UIRichInteractiveHelper(screen);
		helper.register(resultB, "b");
		Assert.isTrue(helper.hasBinding("b.btn1"), "Manual bind on different prefix should succeed");
	}

	// ============== autoStatus: resetState via auto helper ==============

	@Test
	public function testAutoStatusResetState():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(result);
		var autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper);
		// Drive to Pressed state
		screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "btn1", null), null);
		screen.dispatchScreenEvent(UIInteractiveEvent(UIPush, "btn1", null), null);
		assertState(autoHelper, "btn1", Pressed);
		// Reset
		autoHelper.resetState("btn1");
		assertState(autoHelper, "btn1", Normal, "resetState should return to Normal");
	}

	// ============== autoStatus: visual updates through dispatchScreenEvent ==============

	@Test
	public function testAutoStatusPressedVisual():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(AUTO_STATUS_MANIM, "autoBtn", null, Incremental);
		screen.addInteractives(result);
		// Drive to Pressed → should show 30px wide bitmap
		screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "btn1", null), null);
		screen.dispatchScreenEvent(UIInteractiveEvent(UIPush, "btn1", null), null);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width), "Pressed should show 30px bitmap");
	}

	// ============== reserved key: string variations ==============

	@Test
	public function testReservedKeyConstantValue():Void {
		// Verify the constant is what we expect
		Assert.equals("autoStatus", UIRichInteractiveHelper.RESERVED_KEY);
	}

	@Test
	public function testReservedKeyBlocksEvenWithoutAutoStatusInteractives():Void {
		// Using reserved key on a result with NO autoStatus metadata should still throw
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(BOUND_MANIM, "bound", null, Incremental);
		var helper = new UIRichInteractiveHelper(screen);
		var threw = false;
		try {
			helper.register(result, null, "autoStatus");
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "Reserved key should throw regardless of interactive metadata");
	}

	// ============== resync after switch arm flip ==============
	// Verifies that when result.interactives changes due to a SWITCH arm flip, calling helper.resync()
	// updates bindings: removes ids no longer present, adds new ids, preserves existing ids' state.

	static final SWITCH_BIND_MANIM = '
		#switchBound programmable(mode:[a, b]=a, status:[normal,hover,pressed,disabled]=normal) {
			@switch(mode) {
				a: interactive(40, 40, "hitA", bind => "status"): 0, 0;
				b: interactive(60, 60, "hitB", bind => "status"): 0, 0;
			}
		}
	';

	@Test
	public function testResyncAfterSwitchArmFlipUpdatesBindings():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(SWITCH_BIND_MANIM, "switchBound", null, Incremental);
		screen.addInteractives(result);
		var helper = new UIRichInteractiveHelper(screen);
		helper.register(result);

		Assert.isTrue(helper.hasBinding("hitA"), "initial: hitA bound");
		Assert.isFalse(helper.hasBinding("hitB"), "initial: hitB not bound");

		// Switch arm — manual register helper requires manual resync
		result.setParameter("mode", "b");
		helper.resync(result);

		Assert.isFalse(helper.hasBinding("hitA"), "after switch: hitA unbound");
		Assert.isTrue(helper.hasBinding("hitB"), "after switch: hitB bound");
	}

	@Test
	public function testResyncPreservesExistingBindingState():Void {
		// Programmable with two bind interactives; switching one arm doesn't reset the other's state.
		final manim = '
			#twoArmsShared programmable(mode:[a, b]=a, status:[normal,hover,pressed,disabled]=normal) {
				interactive(50, 50, "stable", bind => "status"): 0, 0
				@switch(mode) {
					a: interactive(40, 40, "armA", bind => "status"): 100, 0;
					b: interactive(60, 60, "armB", bind => "status"): 100, 0;
				}
			}
		';
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(manim, "twoArmsShared", null, Incremental);
		screen.addInteractives(result);
		var helper = new UIRichInteractiveHelper(screen);
		helper.register(result);

		// Drive "stable" into Hover state
		helper.handleEvent(UIInteractiveEvent(UIEntering(), "stable", null));
		assertState(helper, "stable", Hover);

		// Switch arm — stable's state must be preserved across resync
		result.setParameter("mode", "b");
		helper.resync(result);

		assertState(helper, "stable", Hover, "stable's Hover state preserved across resync");
		Assert.isFalse(helper.hasBinding("armA"));
		Assert.isTrue(helper.hasBinding("armB"));
	}

	// ============== Auto-resync via screen rebuild listener ==============
	// Verifies that screen.addInteractives auto-installs a rebuild listener that resyncs the
	// interactive map and autoStatus bindings on switch arm flip.

	static final SWITCH_AUTO_STATUS_MANIM = '
		#switchAuto programmable(mode:[a, b]=a, status:[normal,hover,pressed,disabled]=normal) {
			@switch(mode) {
				a {
					@(status=>normal) bitmap(generated(color(10, 10, #f00))): 0, 0
					@(status=>hover) bitmap(generated(color(20, 10, #0f0))): 0, 0
					interactive(40, 40, "hitA", autoStatus => "status"): 0, 0
				}
				b {
					@(status=>normal) bitmap(generated(color(30, 10, #00f))): 0, 0
					@(status=>hover) bitmap(generated(color(40, 10, #ff0))): 0, 0
					interactive(60, 60, "hitB", autoStatus => "status"): 0, 0
				}
			}
		}
	';

	@Test
	public function testScreenAutoResyncOnSwitchArmFlip():Void {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(SWITCH_AUTO_STATUS_MANIM, "switchAuto", null, Incremental);
		screen.addInteractives(result);

		// Initial: hitA wrapped + bound, hitB absent
		Assert.notNull(screen.getInteractive("hitA"), "initial: hitA wrapper exists");
		Assert.isNull(screen.getInteractive("hitB"), "initial: hitB wrapper absent");
		var autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper);
		Assert.isTrue(autoHelper.hasBinding("hitA"), "initial: hitA auto-bound");
		Assert.isFalse(autoHelper.hasBinding("hitB"));

		// Flip to arm b — listener should auto-resync
		result.setParameter("mode", "b");

		Assert.isNull(screen.getInteractive("hitA"), "after flip: hitA wrapper removed");
		Assert.notNull(screen.getInteractive("hitB"), "after flip: hitB wrapper added");
		Assert.isFalse(autoHelper.hasBinding("hitA"), "after flip: hitA auto-binding removed");
		Assert.isTrue(autoHelper.hasBinding("hitB"), "after flip: hitB auto-bound");

		// Drive hitB through hover via the screen — should reach the new binding
		screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "hitB", null), null);
		assertState(autoHelper, "hitB", Hover, "hitB should respond to hover after resync");

		// Flip back to arm a
		result.setParameter("mode", "a");
		Assert.notNull(screen.getInteractive("hitA"));
		Assert.isNull(screen.getInteractive("hitB"));
		Assert.isTrue(autoHelper.hasBinding("hitA"));
		Assert.isFalse(autoHelper.hasBinding("hitB"));
	}

	@Test
	public function testScreenAutoResyncBackAndForthNoAccumulation():Void {
		// Repeated flips must not accumulate stale wrappers or bindings.
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(SWITCH_AUTO_STATUS_MANIM, "switchAuto", null, Incremental);
		screen.addInteractives(result);

		final autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper);

		for (i in 0...5) {
			result.setParameter("mode", "b");
			Assert.isNull(screen.getInteractive("hitA"), 'iter $i: hitA absent in arm b');
			Assert.notNull(screen.getInteractive("hitB"), 'iter $i: hitB present in arm b');
			Assert.equals(1, screen.getInteractivesByPrefix(null).length, 'iter $i: only one wrapper in arm b');

			result.setParameter("mode", "a");
			Assert.notNull(screen.getInteractive("hitA"), 'iter $i: hitA present in arm a');
			Assert.isNull(screen.getInteractive("hitB"), 'iter $i: hitB absent in arm a');
			Assert.equals(1, screen.getInteractivesByPrefix(null).length, 'iter $i: only one wrapper in arm a');
		}
	}

	@Test
	public function testScreenAutoResyncRemovedOnRemoveInteractives():Void {
		// removeInteractives(prefix) must also drop the rebuild listener so subsequent
		// parameter changes do not re-add wrappers.
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(SWITCH_AUTO_STATUS_MANIM, "switchAuto", null, Incremental);
		screen.addInteractives(result, "pfx");

		Assert.notNull(screen.getInteractive("pfx.hitA"));

		// Remove with the prefix → drops listener
		screen.removeInteractives("pfx");
		Assert.isNull(screen.getInteractive("pfx.hitA"));

		// Subsequent parameter change should NOT re-register anything
		result.setParameter("mode", "b");
		Assert.isNull(screen.getInteractive("pfx.hitB"), "removed subscription should not auto-re-register on rebuild");
	}

	// ============== Codegen instance as UIInteractiveSource ==============
	// Verifies that @:manim codegen instances implement UIInteractiveSource and can be wired
	// to screens/helpers the same way as runtime BuilderResult. Covers getInteractives()
	// (scene graph walk), generic setParameter dispatcher, rebuild listener firing from typed
	// setters, and @switch arm resync.

	static function createMp():bh.test.MultiProgrammable {
		final loader:bh.base.ResourceLoader = bh.test.TestResourceLoader.createLoader(false);
		return new bh.test.MultiProgrammable(loader);
	}

	@Test
	public function testCodegenGetInteractivesReturnsSceneGraphMAObjects():Void {
		// Codegen instance's getInteractives() walks its h2d.Object tree and collects MAObjects.
		final mp = createMp();
		final btn = mp.codegenBoundBtn.create();

		final interactives = btn.getInteractives();
		Assert.equals(1, interactives.length, "codegen instance should expose 1 interactive");

		switch interactives[0].multiAnimType {
			case MAInteractive(_, _, id, _):
				Assert.equals("btnBound", id);
			default:
				Assert.fail("expected MAInteractive");
		}
	}

	@Test
	public function testCodegenLoopVarInteractiveIdIsString():Void {
		// Regression: `interactive(w, h, $loopVar, ...)` inside a statically-unrolled
		// repeatable must codegen the id as a String, not an Int. Also exercises
		// the parameterized-slot scope push/pop: without it, the parser rejects
		// `$loopVar` after the slot body closes ("unknown variable $n. Available: state").
		final mp = createMp();
		final inst = mp.codegenLoopSlot.create();

		final interactives = inst.getInteractives();
		Assert.equals(3, interactives.length, "3 repeat iterations should expose 3 interactives");

		final ids:Array<String> = [];
		for (i in interactives) switch i.multiAnimType {
			case MAInteractive(_, _, id, _): ids.push(id);
			default: Assert.fail("expected MAInteractive");
		}
		ids.sort((a, b) -> Reflect.compare(a, b));
		Assert.equals("0", ids[0]);
		Assert.equals("1", ids[1]);
		Assert.equals("2", ids[2]);
	}

	@Test
	public function testCodegenInteractiveIdExpressions():Void {
		// Regression for rvToExpr(rv, forString=true) in ProgrammableCodeGen:
		//   1) RVInteger / RVFloat leaves must stringify when forString=true
		//      (triggered via @final FIXED_ID = 42 -> finalVarExprs -> RVInteger).
		//   2) RVReference to a non-enum typed param must stringify when forString=true
		//      (enumToStringExpr returns bare Int field for PPTInt).
		//   3) EBinop/EUnaryOp must compute arithmetic with forString=false and then
		//      stringify the result — otherwise "0" + 100 becomes "0100" via string
		//      concat (silent bug) or Int+Int yields Int at a String slot (compile fail).
		final mp = createMp();
		final inst = mp.codegenIdExpr.create();

		final ids:Array<String> = [];
		for (i in inst.getInteractives()) switch i.multiAnimType {
			case MAInteractive(_, _, id, _): ids.push(id);
			default: Assert.fail("expected MAInteractive");
		}
		ids.sort((a, b) -> Reflect.compare(a, b));

		// Expected ids (sorted lexicographically):
		//   "0100","1100","2100"  — $n + $base (static loop n=0/1/2, base=100) bare OpAdd = concat
		//   "42"                  — @final FIXED_ID leaf RVInteger stringified
		//   "7"                   — $offset PPTInt ref wrapped with Std.string
		//   "8"                   — ($offset + 1) parenthesized arithmetic then stringify
		Assert.equals(6, ids.length, "6 interactive ids expected");
		Assert.equals("0100", ids[0], "bare OpAdd $n+$base concatenates n=0");
		Assert.equals("1100", ids[1], "bare OpAdd $n+$base concatenates n=1");
		Assert.equals("2100", ids[2], "bare OpAdd $n+$base concatenates n=2");
		Assert.equals("42", ids[3], "@final FIXED_ID RVInteger leaf stringified");
		Assert.equals("7", ids[4], "int param $offset non-enum RVReference stringified");
		Assert.equals("8", ids[5], "($offset + 1) parenthesized arithmetic");
	}

	@Test
	public function testCodegenAddInteractivesWiresToScreen():Void {
		// screen.addInteractives(codegenInstance) should work symmetrically to the runtime path.
		final mp = createMp();
		final btn = mp.codegenBoundBtn.create();
		final screen = new UITestScreen();

		screen.addInteractives(btn);

		Assert.notNull(screen.getInteractive("btnBound"),
			"codegen instance interactive should be wrapped by screen");
	}

	@Test
	public function testCodegenSetParameterStringDispatchesToTypedSetter():Void {
		// UIRichInteractiveHelper calls source.setParameter("status", "hover") with a String.
		// The codegen dispatcher must convert "hover" to the enum index and call setStatus(index).
		final mp = createMp();
		final btn = mp.codegenBoundBtn.create();

		btn.setParameter("status", "hover");
		Assert.equals(1, @:privateAccess btn._status, "setParameter('status', 'hover') should set status=1 (Hover index)");

		btn.setParameter("status", "pressed");
		Assert.equals(2, @:privateAccess btn._status);

		btn.setParameter("status", "normal");
		Assert.equals(0, @:privateAccess btn._status);
	}

	@Test
	public function testCodegenSetParameterUnknownNameThrows():Void {
		final mp = createMp();
		final btn = mp.codegenBoundBtn.create();

		var threw = false;
		try {
			btn.setParameter("nonexistent", 42);
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "setParameter with unknown param name should throw");
	}

	@Test
	public function testCodegenRichInteractiveHelperEndToEnd():Void {
		// Full state machine via UIRichInteractiveHelper wrapping a codegen instance.
		final mp = createMp();
		final btn = mp.codegenBoundBtn.create();
		final screen = new UITestScreen();
		screen.addInteractives(btn);

		final helper = new UIRichInteractiveHelper(screen);
		helper.register(btn);
		assertState(helper, "btnBound", Normal, "initial state");

		helper.handleEvent(UIInteractiveEvent(UIEntering(), "btnBound", null));
		assertState(helper, "btnBound", Hover, "after hover");
		Assert.equals(1, @:privateAccess btn._status, "helper should have called setParameter('status', 'hover') → setStatus(1)");

		helper.handleEvent(UIInteractiveEvent(UIPush, "btnBound", null));
		assertState(helper, "btnBound", Pressed);
		Assert.equals(2, @:privateAccess btn._status);

		helper.handleEvent(UIInteractiveEvent(UIClick, "btnBound", null));
		assertState(helper, "btnBound", Hover);
		Assert.equals(1, @:privateAccess btn._status);

		helper.handleEvent(UIInteractiveEvent(UILeaving, "btnBound", null));
		assertState(helper, "btnBound", Normal);
		Assert.equals(0, @:privateAccess btn._status);
	}

	@Test
	public function testCodegenAutoStatusEndToEnd():Void {
		// autoStatus codegen instance + screen.addInteractives → full auto-wiring.
		final mp = createMp();
		final btn = mp.codegenAutoBtn.create();
		final screen = new UITestScreen();
		screen.addInteractives(btn);

		final autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper, "autoStatus metadata should create auto helper");
		Assert.isTrue(autoHelper.hasBinding("btnAuto"));

		// Drive via dispatchScreenEvent (controller path)
		screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "btnAuto", null), null);
		assertState(autoHelper, "btnAuto", Hover);
		Assert.equals(1, @:privateAccess btn._status);
	}

	@Test
	public function testCodegenSwitchArmResyncOnSetMode():Void {
		// Codegen instance with @switch arms containing different interactive ids per arm.
		// setMode should trigger rebuild listener → screen resync → new arm's wrapper appears.
		final mp = createMp();
		final btn = mp.codegenSwitchBtn.create();
		final screen = new UITestScreen();
		screen.addInteractives(btn);

		// Initial arm a: armHitA wrapped + auto-bound
		Assert.notNull(screen.getInteractive("armHitA"), "initial: armHitA wrapped");
		Assert.isNull(screen.getInteractive("armHitB"), "initial: armHitB absent");
		final autoHelper = screen.getAutoInteractiveHelper();
		Assert.notNull(autoHelper);
		Assert.isTrue(autoHelper.hasBinding("armHitA"));
		Assert.isFalse(autoHelper.hasBinding("armHitB"));

		// Flip arm via the typed setter — fires _fireRebuildListeners → screen resync
		btn.setMode(1); // 1 = arm "b" index
		Assert.isNull(screen.getInteractive("armHitA"), "after flip: armHitA gone");
		Assert.notNull(screen.getInteractive("armHitB"), "after flip: armHitB present");
		Assert.isFalse(autoHelper.hasBinding("armHitA"));
		Assert.isTrue(autoHelper.hasBinding("armHitB"));

		// Drive arm b's autoStatus end-to-end to confirm the new binding is live
		screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "armHitB", null), null);
		assertState(autoHelper, "armHitB", Hover);
		Assert.equals(1, @:privateAccess btn._status);

		// Flip back — armHitB gone, armHitA back
		btn.setMode(0);
		Assert.notNull(screen.getInteractive("armHitA"));
		Assert.isNull(screen.getInteractive("armHitB"));
		Assert.isTrue(autoHelper.hasBinding("armHitA"));
		Assert.isFalse(autoHelper.hasBinding("armHitB"));
	}

	// ==================== setParameter dispatcher coercion (Issue 1) ====================

	@Test
	public function testCodegenSetParameterIntFamilyCoercesFloatAndString():Void {
		// Int-family params (int, color, range, flags, hexDir, gridDir) must coerce Dynamic
		// Float/String inputs into Int. Without the coercion HL crashes on the downstream
		// Int field write; JS silently passes the Float through and drifts from HL.
		final mp = createMp();
		final inst = mp.codegenTypedParams.create();

		inst.setParameter("count", 5); // Int passthrough
		Assert.equals(5, @:privateAccess inst._count);

		inst.setParameter("count", 7.9); // Float → Int truncation
		Assert.equals(7, @:privateAccess inst._count);

		inst.setParameter("count", "42"); // String → Int parse
		Assert.equals(42, @:privateAccess inst._count);

		inst.setParameter("tint", ColorUtils.rgb(0x00FF00)); // Color via ColorUtils.rgb → 0xFF00FF00
		Assert.equals(0xFF00FF00, @:privateAccess inst._tint);
	}

	@Test
	public function testCodegenSetParameterIntFamilyRejectsUnparseableString():Void {
		final mp = createMp();
		final inst = mp.codegenTypedParams.create();

		var threw = false;
		try {
			inst.setParameter("count", "not-a-number");
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "unparseable String should throw");
	}

	@Test
	public function testCodegenSetParameterIntFamilyRejectsBool():Void {
		// Dynamic Bool into an Int param is nonsense — reject explicitly instead of silently
		// coercing (Haxe's implicit Bool→Int is target-dependent).
		final mp = createMp();
		final inst = mp.codegenTypedParams.create();

		var threw = false;
		try {
			inst.setParameter("count", true);
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "Bool into Int param should throw");
	}

	@Test
	public function testCodegenSetParameterStringRejectsNonString():Void {
		// PPTString previously did `cast _value` — a Dynamic Int/Float would silently pass.
		// Now it type-checks.
		final mp = createMp();
		final inst = mp.codegenTypedParams.create();

		inst.setParameter("label", "world"); // happy path
		Assert.equals("world", @:privateAccess inst._label);

		var threw = false;
		try {
			inst.setParameter("label", 42);
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "Int into String param should throw");
	}

	@Test
	public function testCodegenSetParameterFloatCoercion():Void {
		// Regression guard on pre-existing Float branch — unchanged by this fix.
		final mp = createMp();
		final inst = mp.codegenTypedParams.create();

		inst.setParameter("offset", 2.5);
		Assert.floatEquals(2.5, @:privateAccess inst._offset);

		inst.setParameter("offset", 7); // Int → Float
		Assert.floatEquals(7.0, @:privateAccess inst._offset);
	}

	// ==================== Bool String parsing alignment (Issue 3) ====================

	@Test
	public function testCodegenSetParameterBoolStringVariants():Void {
		// Align with findEnumIndex at ProgrammableCodeGen.hx:~1762 which accepts
		// true|yes|1 and false|no|0 (case-insensitive). Previously only "true" was
		// recognized — "yes", "1", "YES" silently became false.
		final mp = createMp();
		final inst = mp.codegenTypedParams.create();

		for (truthy in ["true", "TRUE", "True", "yes", "YES", "Yes", "1"]) {
			inst.setParameter("enabled", false); // reset
			Assert.equals(0, @:privateAccess inst._enabled);
			inst.setParameter("enabled", truthy);
			Assert.equals(1, @:privateAccess inst._enabled, 'string "' + truthy + '" should map to true');
		}

		for (falsy in ["false", "FALSE", "False", "no", "NO", "0"]) {
			inst.setParameter("enabled", true); // reset
			Assert.equals(1, @:privateAccess inst._enabled);
			inst.setParameter("enabled", falsy);
			Assert.equals(0, @:privateAccess inst._enabled, 'string "' + falsy + '" should map to false');
		}
	}

	@Test
	public function testCodegenSetParameterBoolUnknownStringThrows():Void {
		// Previously fell through silently to `== "true"` → false. Now explicit throw so
		// callers notice typos.
		final mp = createMp();
		final inst = mp.codegenTypedParams.create();

		var threw = false;
		try {
			inst.setParameter("enabled", "maybe");
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "unknown Bool string should throw (not silently become false)");
	}

	@Test
	public function testCodegenSetParameterBoolIntAndBoolPassthrough():Void {
		final mp = createMp();
		final inst = mp.codegenTypedParams.create();

		inst.setParameter("enabled", false);
		Assert.equals(0, @:privateAccess inst._enabled);
		inst.setParameter("enabled", true);
		Assert.equals(1, @:privateAccess inst._enabled);

		inst.setParameter("enabled", 0);
		Assert.equals(0, @:privateAccess inst._enabled);
		inst.setParameter("enabled", 5); // non-zero Int → true
		Assert.equals(1, @:privateAccess inst._enabled);
	}

	// ==================== No-op rebuild-listener guard (Issue 2) ====================

	@Test
	public function testCodegenNoOpSetSkipsRebuildListener():Void {
		// Repeated setParameter with the same value must NOT fire rebuild listeners.
		// With N cards in a hand this gating prevents quadratic UIScreen.addInteractives
		// rescans from no-op hover-status resets.
		final mp = createMp();
		final inst = mp.codegenTypedParams.create();

		var fires = 0;
		inst.addRebuildListener(() -> fires++);

		// Default count is 3. Setting to 3 (same) should NOT fire.
		inst.setParameter("count", 3);
		Assert.equals(0, fires, "no-op Int set should not fire");

		// Change to 5 → should fire once.
		inst.setParameter("count", 5);
		Assert.equals(1, fires, "changing Int value should fire once");

		// Setting to 5 again → no fire.
		inst.setParameter("count", 5);
		Assert.equals(1, fires, "repeated same-value Int set should not re-fire");

		// Coerced same value (Float 5.0 truncates to 5) → no fire.
		inst.setParameter("count", 5.0);
		Assert.equals(1, fires, "coerced-same-value set should not re-fire");

		// Coerced String "5" → same → no fire.
		inst.setParameter("count", "5");
		Assert.equals(1, fires, "string-parsed same-value set should not re-fire");

		// Change via a different path: String "9".
		inst.setParameter("count", "9");
		Assert.equals(2, fires, "changed-via-string set should fire");
	}

	@Test
	public function testCodegenNoOpGuardCoversAllTypes():Void {
		// Guard applies to every typed setter, not just Int.
		final mp = createMp();
		final inst = mp.codegenTypedParams.create();

		var fires = 0;
		inst.addRebuildListener(() -> fires++);

		// Float no-op
		inst.setParameter("offset", 1.5); // default
		Assert.equals(0, fires);
		inst.setParameter("offset", 2.5);
		Assert.equals(1, fires);
		inst.setParameter("offset", 2.5);
		Assert.equals(1, fires, "repeated Float set is no-op");

		// Bool no-op (stored as Int 0/1)
		inst.setParameter("enabled", true); // default true
		Assert.equals(1, fires, "Bool no-op should not fire");
		inst.setParameter("enabled", false);
		Assert.equals(2, fires);
		inst.setParameter("enabled", "no"); // same falsy
		Assert.equals(2, fires, "coerced-same-Bool should not re-fire");

		// String no-op
		inst.setParameter("label", "hello"); // default
		Assert.equals(2, fires, "String no-op should not fire");
		inst.setParameter("label", "world");
		Assert.equals(3, fires);
		inst.setParameter("label", "world");
		Assert.equals(3, fires, "repeated String set is no-op");
	}

	@Test
	public function testCodegenNoOpEnumStatusGuard():Void {
		// The hottest path in practice — UIRichInteractiveHelper resetting status to "normal"
		// on every hover-leave, for every card, every frame the mouse drifts around.
		final mp = createMp();
		final btn = mp.codegenBoundBtn.create();

		var fires = 0;
		btn.addRebuildListener(() -> fires++);

		// Default status is "normal" (index 0). Setting to "normal" must not fire.
		btn.setParameter("status", "normal");
		Assert.equals(0, fires, "setting status to its current value should be a pure no-op");

		btn.setParameter("status", "hover");
		Assert.equals(1, fires);

		btn.setParameter("status", "hover");
		Assert.equals(1, fires, "repeated same-enum set should not re-fire");
	}
}
