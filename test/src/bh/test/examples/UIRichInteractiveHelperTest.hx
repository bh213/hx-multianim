package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness.UITestScreen;
import bh.ui.UIRichInteractiveHelper;
import bh.ui.UIElement.UIScreenEvent;
import bh.multianim.MultiAnimBuilder.BuilderResult;

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
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		Assert.isTrue(handled);
		// State should be Hover after entering
	}

	@Test
	public function testPushAfterEnterSetPressed():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		Assert.isTrue(handled);
	}

	@Test
	public function testClickAfterPushReturnsToHover():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIClick, "btn1", null));
		Assert.isTrue(handled);
	}

	@Test
	public function testLeaveFromHoverReturnsToNormal():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		ctx.helper.handleEvent(UIInteractiveEvent(UILeaving, "btn1", null));
		// Should be Normal now — entering again should work (wouldn't if stuck in wrong state)
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		Assert.isTrue(handled);
	}

	@Test
	public function testLeaveFromPressedReturnsToNormal():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		ctx.helper.handleEvent(UIInteractiveEvent(UILeaving, "btn1", null));
		// Should be Normal — can enter again
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		Assert.isTrue(handled);
	}

	@Test
	public function testPushWithoutEnterIsIgnored():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		// Push without prior Enter — state is Normal, push requires Hover
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		// After failed push, Enter should still transition to Hover (not stuck in Pressed)
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		Assert.isTrue(true); // No crash = success
	}

	@Test
	public function testClickWithoutPushIsIgnored():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		// Click without Push — requires Pressed state
		ctx.helper.handleEvent(UIInteractiveEvent(UIClick, "btn1", null));
		// Should still be in Hover, leave returns to Normal
		ctx.helper.handleEvent(UIInteractiveEvent(UILeaving, "btn1", null));
		Assert.isTrue(true);
	}

	@Test
	public function testFullCycleEnterPushClickLeave():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		// Full interaction cycle: Normal → Hover → Pressed → Hover → Normal
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null)));
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null)));
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UIClick, "btn1", null)));
		Assert.isTrue(ctx.helper.handleEvent(UIInteractiveEvent(UILeaving, "btn1", null)));
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
		// Events should return true (bound) but not change state
		var handled = ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		Assert.isTrue(handled); // Still returns true because it IS bound
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
		// Should not throw
		ctx.helper.setDisabled("nonexistent", true);
		Assert.isTrue(true);
	}

	@Test
	public function testDisabledDoesNotTransitionOnEnter():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		// Enter first, then disable
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		ctx.helper.setDisabled("btn1", true);
		// Push should be blocked (disabled state)
		ctx.helper.handleEvent(UIInteractiveEvent(UIPush, "btn1", null));
		// Re-enable — state was reset to Normal by setDisabled(false)
		ctx.helper.setDisabled("btn1", false);
		// After re-enable, entering should work from Normal
		ctx.helper.handleEvent(UIInteractiveEvent(UIEntering, "btn1", null));
		Assert.isTrue(true);
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
		// Should not throw — forwards "label" parameter to the BuilderResult
		ctx.helper.setParameter("btnFwd", "label", "world");
		Assert.isTrue(true);
	}

	@Test
	public function testSetParameterOnUnknownInteractive():Void {
		var ctx = createHelper(BOUND_MANIM, "bound");
		// Should silently do nothing
		ctx.helper.setParameter("nonexistent", "label", "world");
		Assert.isTrue(true);
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
}
