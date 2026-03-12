package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness.UITestScreen;
import bh.ui.UICardHandHelper;
import bh.ui.UICardHandTypes;
import bh.ui.UIElement.UIScreenEvent;
import bh.ui.controllers.UIController;
import bh.ui.controllers.UIInteractionController;
import bh.ui.controllers.UIInteractionTypes;
import bh.ui.controllers.UISelectFromHandController;
import bh.ui.controllers.UIPickTargetController;
import h2d.col.Point;

/**
 * Unit tests for UIInteractionController, UISelectFromHandController, and UIPickTargetController.
 */
class InteractionControllerTest extends BuilderTestBase {
	// ==================== Helpers ====================

	static final CARD_MANIM = "
		#card programmable(status:[normal,hover,pressed,disabled]=normal, selected:bool=false) {
			bitmap(generated(color(80, 110, #444444))): 0, 0
			interactive(80, 110, \"card\", bind => \"status\"): 0, 0
		}
	";

	static function createCardHand(?config:CardHandConfig):{helper:UICardHandHelper, screen:UITestScreen} {
		var builder = BuilderTestBase.builderFromSource(CARD_MANIM);
		var screen = new UITestScreen();
		var helper = new UICardHandHelper(screen, builder, config);
		return {helper: helper, screen: screen};
	}

	static function desc(id:String):CardDescriptor {
		return {id: id, buildName: "card"};
	}

	// ==================== UIInteractionController base ====================

	@Test
	public function testInteractionControllerCreation():Void {
		var screen = new UITestScreen();
		var called = false;
		var ctrl = new UIInteractionController(screen, (_) -> { called = true; });
		Assert.notNull(ctrl);
		Assert.isFalse(called);
	}

	@Test
	public function testInteractionControllerCompleteDefersToUpdate():Void {
		var screen = new UITestScreen();
		var resultReceived:Null<Dynamic> = null;
		var callbackFired = false;
		var ctrl = new UIInteractionController(screen, (result) -> {
			callbackFired = true;
			resultReceived = result;
		});

		ctrl.complete("test_result");
		// Callback should NOT fire immediately
		Assert.isFalse(callbackFired);

		// Should fire on next update
		ctrl.update(0.016);
		Assert.isTrue(callbackFired);
		Assert.equals("test_result", resultReceived);
	}

	@Test
	public function testInteractionControllerCancelDefersToUpdate():Void {
		var screen = new UITestScreen();
		var resultReceived:Dynamic = "not_called";
		var callbackFired = false;
		var ctrl = new UIInteractionController(screen, (result) -> {
			callbackFired = true;
			resultReceived = result;
		});

		ctrl.cancel();
		Assert.isFalse(callbackFired);

		ctrl.update(0.016);
		Assert.isTrue(callbackFired);
		Assert.isNull(resultReceived);
	}

	@Test
	public function testInteractionControllerCancelOverridesComplete():Void {
		var screen = new UITestScreen();
		var resultReceived:Dynamic = "not_called";
		var ctrl = new UIInteractionController(screen, (result) -> {
			resultReceived = result;
		});

		ctrl.complete("some_result");
		ctrl.cancel(); // cancel after complete — cancel wins
		ctrl.update(0.016);
		Assert.isNull(resultReceived);
	}

	@Test
	public function testInteractionControllerCallbackFiresOnce():Void {
		var screen = new UITestScreen();
		var callCount = 0;
		var ctrl = new UIInteractionController(screen, (_) -> { callCount++; });

		ctrl.complete("result");
		ctrl.update(0.016);
		Assert.equals(1, callCount);

		// Second update should not fire again
		ctrl.update(0.016);
		Assert.equals(1, callCount);
	}

	@Test
	public function testInteractionControllerReturnsRunning():Void {
		var screen = new UITestScreen();
		var ctrl = new UIInteractionController(screen, (_) -> {});

		// Before completion
		var result = ctrl.update(0.016);
		Assert.isTrue(Type.enumEq(result, UIControllerRunning));

		// During completion delivery
		ctrl.complete("done");
		result = ctrl.update(0.016);
		Assert.isTrue(Type.enumEq(result, UIControllerRunning));
	}

	@Test
	public function testInteractionControllerLifecycleActivate():Void {
		var screen = new UITestScreen();
		var activated = false;
		var deactivated = false;

		var ctrl = new TestableInteractionController(screen, (_) -> {}, () -> { activated = true; }, () -> { deactivated = true; });

		Assert.isFalse(activated);
		ctrl.lifecycleEvent(LifecycleControllerStarted);
		Assert.isTrue(activated);
		Assert.isFalse(deactivated);

		ctrl.lifecycleEvent(LifecycleControllerFinished);
		Assert.isTrue(deactivated);
	}

	@Test
	public function testInteractionControllerDebugName():Void {
		var screen = new UITestScreen();
		var ctrl = new UIInteractionController(screen, (_) -> {});
		Assert.equals("interaction controller", ctrl.getDebugName());
	}

	// ==================== UISelectFromHandController ====================

	@Test
	public function testSelectFromHandCreation():Void {
		var h = createCardHand();
		h.helper.setHand([desc("a"), desc("b"), desc("c")]);
		var ctrl = new UISelectFromHandController(h.screen, h.helper, {maxCount: 2}, (_) -> {});
		Assert.notNull(ctrl);
		Assert.equals(0, ctrl.getSelectedCards().length);
		Assert.equals(2, ctrl.getRemainingCount());
	}

	@Test
	public function testSelectFromHandDebugName():Void {
		var h = createCardHand();
		h.helper.setHand([desc("a"), desc("b")]);
		var ctrl = new UISelectFromHandController(h.screen, h.helper, {maxCount: 2}, (_) -> {});
		Assert.equals("select-from-hand(0/2)", ctrl.getDebugName());
	}

	@Test
	public function testSelectFromHandSuppressesDrag():Void {
		var h = createCardHand();
		h.helper.setHand([desc("a"), desc("b")]);

		// Set a custom canDragCard
		var originalDragFilter = (id:CardId) -> true;
		h.helper.canDragCard = originalDragFilter;

		var ctrl = new UISelectFromHandController(h.screen, h.helper, {maxCount: 1}, (_) -> {});
		ctrl.lifecycleEvent(LifecycleControllerStarted);

		// Drag should be suppressed
		Assert.isFalse(h.helper.canDragCard("a"));

		// Deactivate should restore
		ctrl.lifecycleEvent(LifecycleControllerFinished);
		Assert.isTrue(h.helper.canDragCard("a"));
	}

	@Test
	public function testSelectFromHandDisablesFilteredCards():Void {
		var h = createCardHand();
		h.helper.setHand([desc("a"), desc("b"), desc("c")]);

		// Only "b" is selectable
		var ctrl = new UISelectFromHandController(h.screen, h.helper, {
			maxCount: 1,
			filter: (id) -> id == "b"
		}, (_) -> {});

		ctrl.lifecycleEvent(LifecycleControllerStarted);
		// "a" and "c" should be disabled
		Assert.isFalse(h.helper.isCardInHand("a")); // disabled
		Assert.isTrue(h.helper.isCardInHand("b")); // still in hand
		Assert.isFalse(h.helper.isCardInHand("c")); // disabled

		// Deactivate restores all
		ctrl.lifecycleEvent(LifecycleControllerFinished);
		Assert.isTrue(h.helper.isCardInHand("a"));
		Assert.isTrue(h.helper.isCardInHand("b"));
		Assert.isTrue(h.helper.isCardInHand("c"));
	}

	@Test
	public function testSelectFromHandConfirmRequiresMinCount():Void {
		var h = createCardHand();
		h.helper.setHand([desc("a"), desc("b")]);

		var result:Null<Dynamic> = null;
		var ctrl = new UISelectFromHandController(h.screen, h.helper, {
			minCount: 2,
			maxCount: 3,
			autoConfirm: false
		}, (r) -> { result = r; });

		// Can't confirm with 0 selected
		ctrl.confirm();
		ctrl.update(0.016);
		Assert.isNull(result); // not enough
	}

	@Test
	public function testSelectFromHandDefaultConfig():Void {
		var h = createCardHand();
		h.helper.setHand([desc("a")]);

		var result:Null<Dynamic> = null;
		// Default: minCount=1, maxCount=1, autoConfirm=true (because min==max)
		var ctrl = new UISelectFromHandController(h.screen, h.helper, {}, (r) -> { result = r; });
		Assert.equals("select-from-hand(0/1)", ctrl.getDebugName());
		Assert.equals(1, ctrl.getRemainingCount());
	}

	@Test
	public function testSelectFromHandStaticStart():Void {
		var h = createCardHand();
		h.helper.setHand([desc("a"), desc("b")]);

		var resultReceived:Null<SelectFromHandResult> = null;
		var ctrl = UISelectFromHandController.start(h.screen, h.helper, {maxCount: 1}, (r) -> {
			resultReceived = r;
		});

		Assert.notNull(ctrl);
		// Controller should be pushed (screen's controller is now the select controller)
		Assert.equals("select-from-hand(0/1)", h.screen.get_controller().getDebugName());
	}

	@Test
	public function testSelectFromHandStaticStartCancel():Void {
		var h = createCardHand();
		h.helper.setHand([desc("a"), desc("b")]);

		var resultReceived:Dynamic = "not_called";
		var ctrl = UISelectFromHandController.start(h.screen, h.helper, {maxCount: 1}, (r) -> {
			resultReceived = r;
		});

		ctrl.cancel();
		ctrl.update(0.016);

		// Should have received null (cancelled)
		Assert.isNull(resultReceived);
		// Controller should be popped (back to default)
		Assert.equals("default UI controller", h.screen.get_controller().getDebugName());
	}

	// ==================== UIPickTargetController ====================

	@Test
	public function testPickTargetCreation():Void {
		var screen = new UITestScreen();
		var ctrl = new UIPickTargetController(screen, {validTargetIds: ["btn1", "btn2"]}, (_) -> {});
		Assert.notNull(ctrl);
		Assert.equals("pick-target", ctrl.getDebugName());
	}

	@Test
	public function testPickTargetStaticStart():Void {
		var screen = new UITestScreen();
		var resultReceived:Null<PickTargetResult> = null;
		var ctrl = UIPickTargetController.start(screen, {validTargetIds: ["btn1"]}, (r) -> {
			resultReceived = r;
		});

		Assert.notNull(ctrl);
		Assert.equals("pick-target", screen.get_controller().getDebugName());
	}

	@Test
	public function testPickTargetStaticStartCancel():Void {
		var screen = new UITestScreen();
		var resultReceived:Dynamic = "not_called";
		var ctrl = UIPickTargetController.start(screen, {validTargetIds: ["btn1"]}, (r) -> {
			resultReceived = r;
		});

		ctrl.cancel();
		ctrl.update(0.016);

		Assert.isNull(resultReceived);
		Assert.equals("default UI controller", screen.get_controller().getDebugName());
	}

	@Test
	public function testPickTargetSuppressesCardDrag():Void {
		var h = createCardHand();
		h.helper.setHand([desc("a"), desc("b")]);
		h.helper.canDragCard = (_) -> true;

		var ctrl = new UIPickTargetController(h.screen, {
			cardHand: h.helper,
			cardFilter: (_) -> true
		}, (_) -> {});

		ctrl.lifecycleEvent(LifecycleControllerStarted);
		Assert.isFalse(h.helper.canDragCard("a"));

		ctrl.lifecycleEvent(LifecycleControllerFinished);
		Assert.isTrue(h.helper.canDragCard("a"));
	}

	// ==================== UIInteractionTypes ====================

	@Test
	public function testPickTargetResultEnum():Void {
		var r1 = PickTargetResult.TargetInteractive("btn_1");
		var r2 = PickTargetResult.TargetCell(3, 5);
		var r3 = PickTargetResult.TargetCard("card_a");

		switch r1 {
			case TargetInteractive(id):
				Assert.equals("btn_1", id);
			default:
				Assert.fail("Expected TargetInteractive");
		}
		switch r2 {
			case TargetCell(col, row):
				Assert.equals(3, col);
				Assert.equals(5, row);
			default:
				Assert.fail("Expected TargetCell");
		}
		switch r3 {
			case TargetCard(cardId):
				Assert.equals("card_a", cardId);
			default:
				Assert.fail("Expected TargetCard");
		}
	}

	// ==================== CardHandHelper new API ====================

	@Test
	public function testFindCardIdByInteractiveId():Void {
		var h = createCardHand();
		h.helper.setHand([desc("a"), desc("b"), desc("c")]);
		// Cards should have interactive IDs — can't know exact prefix+seq,
		// but we can verify unknown ID returns null
		Assert.isNull(h.helper.findCardIdByInteractiveId("nonexistent_99"));
	}

	@Test
	public function testIsCardInHand():Void {
		var h = createCardHand();
		h.helper.setHand([desc("a"), desc("b")]);

		Assert.isTrue(h.helper.isCardInHand("a"));
		Assert.isTrue(h.helper.isCardInHand("b"));
		Assert.isFalse(h.helper.isCardInHand("nonexistent"));
	}

	@Test
	public function testIsCardInHandDisabled():Void {
		var h = createCardHand();
		h.helper.setHand([desc("a"), desc("b")]);
		h.helper.setCardEnabled("a", false);

		Assert.isFalse(h.helper.isCardInHand("a")); // disabled cards are not "in hand"
		Assert.isTrue(h.helper.isCardInHand("b"));
	}

	// ==================== Controller stack integration ====================

	@Test
	public function testPushPopControllerStack():Void {
		var screen = new UITestScreen();
		Assert.equals("default UI controller", screen.get_controller().getDebugName());

		var ctrl = new UIInteractionController(screen, (_) -> {});
		screen.pushController(ctrl);
		Assert.equals("interaction controller", screen.get_controller().getDebugName());

		screen.popController();
		Assert.equals("default UI controller", screen.get_controller().getDebugName());
	}

	@Test
	public function testNestedControllers():Void {
		var screen = new UITestScreen();

		var ctrl1 = new UIInteractionController(screen, (_) -> {});
		screen.pushController(ctrl1);
		Assert.equals("interaction controller", screen.get_controller().getDebugName());

		var ctrl2 = new UIInteractionController(screen, (_) -> {});
		screen.pushController(ctrl2);
		Assert.equals("interaction controller", screen.get_controller().getDebugName());

		screen.popController();
		screen.popController();
		Assert.equals("default UI controller", screen.get_controller().getDebugName());
	}

	@Test
	public function testStartCancelRestoresStack():Void {
		var h = createCardHand();
		h.helper.setHand([desc("a")]);

		Assert.equals("default UI controller", h.screen.get_controller().getDebugName());

		var ctrl = UISelectFromHandController.start(h.screen, h.helper, {maxCount: 1}, (_) -> {});
		Assert.equals("select-from-hand(0/1)", h.screen.get_controller().getDebugName());

		ctrl.cancel();
		ctrl.update(0.016);
		Assert.equals("default UI controller", h.screen.get_controller().getDebugName());
	}

	// ==================== Composable controllers ====================

	@Test
	public function testSequentialControllerComposition():Void {
		var h = createCardHand();
		h.helper.setHand([desc("a"), desc("b")]);

		var phase = 0;
		// Start first controller
		var ctrl1 = UISelectFromHandController.start(h.screen, h.helper, {maxCount: 1, autoConfirm: false}, (r1) -> {
			phase = 1;
			// After first completes, start second
			UIPickTargetController.start(h.screen, {validTargetIds: ["target1"]}, (r2) -> {
				phase = 2;
			});
		});

		Assert.equals(0, phase);

		// Complete first
		ctrl1.confirm(); // won't work with 0 selected, need manual complete
		ctrl1.complete({cards: ["a"]});
		ctrl1.update(0.016);
		Assert.equals(1, phase);

		// Second controller should now be active
		Assert.equals("pick-target", h.screen.get_controller().getDebugName());

		// Cancel second
		var topCtrl:UIPickTargetController = cast h.screen.get_controller();
		topCtrl.cancel();
		topCtrl.update(0.016);
		Assert.equals(2, phase);
		Assert.equals("default UI controller", h.screen.get_controller().getDebugName());
	}
}

/**
 * Testable subclass that exposes onActivate/onDeactivate hooks.
 */
private class TestableInteractionController extends UIInteractionController {
	final activateHook:() -> Void;
	final deactivateHook:() -> Void;

	public function new(integration, resultCallback, activateHook, deactivateHook) {
		super(integration, resultCallback);
		this.activateHook = activateHook;
		this.deactivateHook = deactivateHook;
	}

	override public function onActivate():Void {
		activateHook();
	}

	override public function onDeactivate():Void {
		deactivateHook();
	}
}
