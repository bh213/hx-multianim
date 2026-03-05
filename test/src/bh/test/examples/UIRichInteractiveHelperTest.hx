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
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null)));
	}

	@Test
	public function testRegisterIgnoresInteractiveWithoutBind():Void {
		var ctx = createHelper(UNBOUND_MANIM, "unbound");
		// handleEvent should return false for unbound interactive
		Assert.isFalse(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btnNoBind", null)));
	}

	@Test
	public function testRegisterWithPrefix():Void {
		var ctx = createHelper(BOUND_MANIM, "bound", "pfx");
		// With prefix, full id is "pfx.btn1"
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "pfx.btn1", null)));
		// Without prefix should not match
		Assert.isFalse(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null)));
	}

	@Test
	public function testRegisterMultipleInteractives():Void {
		var ctx = createHelper(MULTI_BOUND_MANIM, "multi");
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btnA", null)));
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btnB", null)));
	}

	@Test
	public function testRegisterCustomBindParam():Void {
		var ctx = createHelper(CUSTOM_BIND_MANIM, "custom");
		// Should bind to "myState" parameter — handleEvent returns true
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btnCustom", null)));
	}

	// ============== handleEvent() state machine ==============

	@Test
	public function testEnterSetsHover():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		assertState(ctx.helper, "btn1", Normal);
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		Assert.isTrue(handled);
		assertState(ctx.helper, "btn1", Hover);
	}

	@Test
	public function testPushAfterEnterSetPressed():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		assertState(ctx.helper, "btn1", Hover);
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		Assert.isTrue(handled);
		assertState(ctx.helper, "btn1", Pressed);
	}

	@Test
	public function testClickAfterPushReturnsToHover():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		assertState(ctx.helper, "btn1", Pressed);
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIClick, "btn1", null));
		Assert.isTrue(handled);
		assertState(ctx.helper, "btn1", Hover);
	}

	@Test
	public function testLeaveFromHoverReturnsToNormal():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		assertState(ctx.helper, "btn1", Hover);
		ctx.helper.handleEvent(UIInteractiveEvent(UILeaving, "btn1", null));
		assertState(ctx.helper, "btn1", Normal);
	}

	@Test
	public function testLeaveFromPressedReturnsToNormal():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		assertState(ctx.helper, "btn1", Pressed);
		ctx.helper.handleEvent(UIInteractiveEvent(UILeaving, "btn1", null));
		assertState(ctx.helper, "btn1", Normal);
	}

	@Test
	public function testPushWithoutEnterIsIgnored():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		// Push without prior Enter — state is Normal, push requires Hover
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		// State should remain Normal (push ignored from Normal)
		assertState(ctx.helper, "btn1", Normal);
	}

	@Test
	public function testClickWithoutPushIsIgnored():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
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
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
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
		Assert.isFalse(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "unknown", null)));
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
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btnA", null));
		// B can still enter independently
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btnB", null)));
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
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		Assert.isTrue(handled); // Still returns true because it IS bound
		assertState(ctx.helper, "btn1", Disabled); // State unchanged
	}

	@Test
	public function testSetDisabledThenEnabled():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.setDisabled("btn1", true);
		ctx.helper.setDisabled("btn1", false);
		// Should work normally after re-enabling
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
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
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
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
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
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
		Assert.isTrue(helper.handleEvent(UIInteractiveEvent(UIEntering, "btnNoBind", null)));
	}

	@Test
	public function testUnbind():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.unbind("btn1");
		Assert.isFalse(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null)));
	}

	@Test
	public function testUnbindAll():Void {
		var ctx = createHelper(MULTI_BOUND_MANIM, "multi");
		ctx.helper.unbindAll();
		Assert.isFalse(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btnA", null)));
		Assert.isFalse(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btnB", null)));
	}

	@Test
	public function testUnregister():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.unregister(ctx.result);
		Assert.isFalse(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null)));
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
		Assert.isFalse(helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null)));
		Assert.isTrue(helper.handleEvent(UIInteractiveEvent(UIEntering, "btnCustom", null)));
	}

	// ============== getResult ==============

	@Test
	public function testGetResultReturnsBoundResult():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		Assert.equals(ctx.result, ctx.helper.getResult("btn1"));
	}

	@Test
	public function testGetResultReturnsNullForUnknown():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		Assert.isNull(ctx.helper.getResult("nonexistent"));
	}

	@Test
	public function testGetResultReturnsNullAfterUnbind():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.unbind("btn1");
		Assert.isNull(ctx.helper.getResult("btn1"));
	}

	// ============== setParameter forwarding ==============

	@Test
	public function testSetParameterOnBoundInteractive():Void {
		var ctx = createHelper(PARAM_FORWARD_MANIM, "paramFwd");
		// Forwards "label" parameter to the BuilderResult — verify state unaffected
		ctx.helper.setParameter("btnFwd", "label", "world");
		assertState(ctx.helper, "btnFwd", Normal);
		// Verify the result is still accessible (parameter forwarded to it)
		Assert.notNull(ctx.helper.getResult("btnFwd"));
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
			ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
			ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
			ctx.helper.handleEvent(UIInteractiveEvent(UIClick, "btn1", null));
			ctx.helper.handleEvent(UIInteractiveEvent(UILeaving, "btn1", null));
		}
		// Should still work after multiple cycles
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null)));
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
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btnVis", null));
		assertState(ctx.helper, "btnVis", Hover);
		bitmaps = findVisibleBitmapDescendants(ctx.result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testBindAutoWiringFullCycleVisual():Void {
		var ctx = createHelper(VISUAL_BIND_MANIM, "visual");
		// Enter → 20px
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btnVis", null));
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
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
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
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
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
}
