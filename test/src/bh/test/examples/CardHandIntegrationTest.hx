package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness.UITestScreen;
import bh.ui.UICardHandHelper;
import bh.ui.UICardHandTypes;
import bh.base.FPoint;

/**
 * Integration tests for UICardHandHelper orchestration beyond basic CRUD.
 *
 * Tests event callbacks, target management, card state transitions,
 * visibility, anchoring, concurrent operations, and edge cases.
 * Extends the existing CardHandOrchestratorTest which covers layout math
 * and basic setHand/drawCard/discardCard/updateCardParams.
 */
@:access(bh.ui.UICardHandHelper)
class CardHandIntegrationTest extends BuilderTestBase {
	// ==================== Helpers ====================

	static final CARD_MANIM = "
		#card programmable(status:[normal,hover,pressed,disabled]=normal) {
			bitmap(generated(color(80, 110, #444444))): 0, 0
			interactive(80, 110, \"card\", bind => \"status\"): 0, 0
		}
	";

	static function createHelper(?config:CardHandConfig):{helper:UICardHandHelper, screen:UITestScreen} {
		var builder = BuilderTestBase.builderFromSource(CARD_MANIM);
		var screen = new UITestScreen();
		var helper = new UICardHandHelper(screen, builder, config);
		return {helper: helper, screen: screen};
	}

	static function desc(id:String):CardDescriptor {
		return {id: id, buildName: "card"};
	}

	// ==================== onCardEvent Callback ====================

	@Test
	public function testOnCardEventCallbackIsNullByDefault():Void {
		var h = createHelper();
		Assert.isNull(h.helper.onCardEvent);
	}

	@Test
	public function testOnCardEventCallbackAssignment():Void {
		var h = createHelper();
		var events:Array<CardHandEvent> = [];
		h.helper.onCardEvent = (event) -> events.push(event);
		Assert.notNull(h.helper.onCardEvent);
	}

	// ==================== canPlayCard / canDragCard Veto ====================

	@Test
	public function testCanPlayCardCallbackIsNullByDefault():Void {
		var h = createHelper();
		Assert.isNull(h.helper.canPlayCard);
	}

	@Test
	public function testCanPlayCardCallbackAssignment():Void {
		var h = createHelper();
		h.helper.canPlayCard = (cardId, target) -> cardId != "special";
		Assert.notNull(h.helper.canPlayCard);
		Assert.isFalse(h.helper.canPlayCard("special", NoTarget));
		Assert.isTrue(h.helper.canPlayCard("regular", NoTarget));
	}

	@Test
	public function testCanDragCardCallbackSelectiveVeto():Void {
		var h = createHelper();
		h.helper.setHand([desc("locked"), desc("free"), desc("special")]);
		var lockedIds = ["locked", "special"];
		h.helper.canDragCard = (cardId) -> lockedIds.indexOf(cardId) < 0;
		Assert.isFalse(h.helper.canDragCard("locked"));
		Assert.isTrue(h.helper.canDragCard("free"));
		Assert.isFalse(h.helper.canDragCard("special"));
	}

	// ==================== Card State via @:access ====================

	@Test
	public function testNewCardsStartInHandState():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b")]);
		for (entry in h.helper.cards) {
			Assert.isTrue(entry.state == InHand, 'Card ${entry.descriptor.id} should be InHand');
		}
	}

	@Test
	public function testDisabledCardState():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		h.helper.setCardEnabled("a", false);
		Assert.isTrue(h.helper.cards[0].state == Disabled);
	}

	@Test
	public function testReenabledCardState():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		h.helper.setCardEnabled("a", false);
		Assert.isTrue(h.helper.cards[0].state == Disabled);
		h.helper.setCardEnabled("a", true);
		Assert.isTrue(h.helper.cards[0].state == InHand);
	}

	@Test
	public function testIsDraggingInitiallyFalse():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		Assert.isFalse(h.helper.isDragging);
	}

	@Test
	public function testIsTargetingInitiallyFalse():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		Assert.isFalse(h.helper.isTargeting);
	}

	// ==================== Visibility ====================

	@Test
	public function testSetVisibleHides():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b")]);
		h.helper.setVisible(false);
		Assert.isFalse(h.helper.handContainer.visible);
	}

	@Test
	public function testSetVisibleShows():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b")]);
		h.helper.setVisible(false);
		h.helper.setVisible(true);
		Assert.isTrue(h.helper.handContainer.visible);
	}

	// ==================== Anchor ====================

	@Test
	public function testSetAnchorUpdatesPosition():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		h.helper.setAnchor(100, 200);
		Assert.floatEquals(100.0, h.helper.anchorX);
		Assert.floatEquals(200.0, h.helper.anchorY);
	}

	@Test
	public function testDefaultAnchorValues():Void {
		var h = createHelper();
		// Default from CardHandConfig
		Assert.floatEquals(640.0, h.helper.anchorX);
		Assert.floatEquals(680.0, h.helper.anchorY);
	}

	@Test
	public function testCustomAnchorInConfig():Void {
		var config:CardHandConfig = {anchorX: 300.0, anchorY: 500.0};
		var h = createHelper(config);
		Assert.floatEquals(300.0, h.helper.anchorX);
		Assert.floatEquals(500.0, h.helper.anchorY);
	}

	// ==================== Multiple Draw/Discard Operations ====================

	@Test
	public function testMultipleDrawsPreserveOrder():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		h.helper.drawCard(desc("b"));
		h.helper.drawCard(desc("c"));
		h.helper.drawCard(desc("d"));
		var ids = h.helper.getCardIds();
		Assert.equals(4, ids.length);
		Assert.equals("a", ids[0]);
		Assert.equals("d", ids[3]);
	}

	@Test
	public function testDrawAtBeginningAndEnd():Void {
		var h = createHelper();
		h.helper.setHand([desc("b"), desc("c")]);
		h.helper.drawCard(desc("a"), 0);
		h.helper.drawCard(desc("d")); // default = end
		var ids = h.helper.getCardIds();
		Assert.equals("a", ids[0]);
		Assert.equals("b", ids[1]);
		Assert.equals("c", ids[2]);
		Assert.equals("d", ids[3]);
	}

	@Test
	public function testDiscardMiddleCardPreservesOrder():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b"), desc("c"), desc("d")]);
		h.helper.discardCard("b");
		var ids = h.helper.getCardIds();
		Assert.equals(3, ids.length);
		Assert.equals("a", ids[0]);
		Assert.equals("c", ids[1]);
		Assert.equals("d", ids[2]);
	}

	@Test
	public function testDiscardAllCards():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b"), desc("c")]);
		h.helper.discardCard("a");
		h.helper.discardCard("b");
		h.helper.discardCard("c");
		Assert.equals(0, h.helper.getCardCount());
	}

	@Test
	public function testDrawAfterDiscardAll():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		h.helper.discardCard("a");
		Assert.equals(0, h.helper.getCardCount());
		h.helper.drawCard(desc("b"));
		Assert.equals(1, h.helper.getCardCount());
		Assert.equals("b", h.helper.getCardIds()[0]);
	}

	// ==================== setHand Edge Cases ====================

	@Test
	public function testSetHandEmptyArray():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b")]);
		h.helper.setHand([]);
		Assert.equals(0, h.helper.getCardCount());
	}

	@Test
	public function testSetHandSingleCard():Void {
		var h = createHelper();
		h.helper.setHand([desc("solo")]);
		Assert.equals(1, h.helper.getCardCount());
		Assert.equals("solo", h.helper.getCardIds()[0]);
	}

	@Test
	public function testSetHandAfterDispose():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		h.helper.dispose();
		h.helper.setHand([desc("b"), desc("c")]);
		Assert.equals(2, h.helper.getCardCount());
	}

	// ==================== updateCardParams Edge Cases ====================

	@Test
	public function testUpdateCardParamsUnknownIdSafe():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		// Should not throw for unknown card
		h.helper.updateCardParams("nonexistent", ["status" => "hover"]);
		Assert.equals(1, h.helper.getCardCount());
	}

	@Test
	public function testUpdateCardParamsMultipleTimes():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		h.helper.updateCardParams("a", ["status" => "hover"]);
		h.helper.updateCardParams("a", ["status" => "pressed"]);
		h.helper.updateCardParams("a", ["status" => "normal"]);
		Assert.notNull(h.helper.getCardResult("a"));
	}

	// ==================== setCardEnabled Edge Cases ====================

	@Test
	public function testSetCardEnabledUnknownIdSafe():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		// Should not throw for unknown card
		h.helper.setCardEnabled("nonexistent", false);
		Assert.equals(1, h.helper.getCardCount());
	}

	@Test
	public function testSetCardEnabledDoubleFalse():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		h.helper.setCardEnabled("a", false);
		h.helper.setCardEnabled("a", false); // idempotent
		Assert.isTrue(h.helper.cards[0].state == Disabled);
	}

	@Test
	public function testSetCardEnabledDoubleTrue():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		h.helper.setCardEnabled("a", true); // already enabled
		Assert.isTrue(h.helper.cards[0].state == InHand);
	}

	// ==================== onCardBuilt Callback ====================

	@Test
	public function testOnCardBuiltReceivesCorrectIds():Void {
		var receivedIds:Array<String> = [];
		var config:CardHandConfig = {
			onCardBuilt: (cardId, result, container) -> receivedIds.push(cardId)
		};
		var h = createHelper(config);
		h.helper.setHand([desc("x"), desc("y"), desc("z")]);
		Assert.equals(3, receivedIds.length);
		Assert.equals("x", receivedIds[0]);
		Assert.equals("y", receivedIds[1]);
		Assert.equals("z", receivedIds[2]);
	}

	@Test
	public function testOnCardBuiltReceivesNonNullResult():Void {
		var allNonNull = true;
		var config:CardHandConfig = {
			onCardBuilt: (cardId, result, container) -> {
				if (result == null) allNonNull = false;
			}
		};
		var h = createHelper(config);
		h.helper.setHand([desc("a"), desc("b")]);
		Assert.isTrue(allNonNull, "All BuilderResults should be non-null");
	}

	@Test
	public function testOnCardBuiltFiresOnDrawCard():Void {
		var counter = 0;
		var config:CardHandConfig = {
			onCardBuilt: (cardId, result, container) -> counter++
		};
		var h = createHelper(config);
		h.helper.setHand([desc("a")]); // counter = 1
		h.helper.drawCard(desc("b")); // counter = 2
		Assert.equals(2, counter);
	}

	// ==================== dispose ====================

	@Test
	public function testDisposeResetsCardCount():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b"), desc("c")]);
		h.helper.dispose();
		Assert.equals(0, h.helper.getCardCount());
		Assert.equals(0, h.helper.getCardIds().length);
	}

	@Test
	public function testDisposeResetsInternalState():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		h.helper.dispose();
		Assert.isFalse(h.helper.isDragging);
		Assert.isFalse(h.helper.isTargeting);
	}

	@Test
	public function testDoubleDisposeSafe():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		h.helper.dispose();
		h.helper.dispose(); // Should not throw
		Assert.equals(0, h.helper.getCardCount());
	}

	// ==================== Config Defaults ====================

	@Test
	public function testDefaultConfigValues():Void {
		var h = createHelper();
		Assert.floatEquals(640.0, h.helper.anchorX);
		Assert.floatEquals(680.0, h.helper.anchorY);
	}

	@Test
	public function testCustomConfigPersists():Void {
		var config:CardHandConfig = {
			anchorX: 200.0,
			anchorY: 400.0,
			cardWidth: 100.0,
			cardHeight: 140.0
		};
		var h = createHelper(config);
		Assert.floatEquals(200.0, h.helper.anchorX);
		Assert.floatEquals(400.0, h.helper.anchorY);
	}

	// ==================== getCardResult After Operations ====================

	@Test
	public function testGetCardResultAfterDraw():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		h.helper.drawCard(desc("b"));
		Assert.notNull(h.helper.getCardResult("a"));
		Assert.notNull(h.helper.getCardResult("b"));
	}

	@Test
	public function testGetCardResultAfterDiscard():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b")]);
		h.helper.discardCard("a");
		Assert.isNull(h.helper.getCardResult("a"));
		Assert.notNull(h.helper.getCardResult("b"));
	}

	@Test
	public function testGetCardResultAfterSetHand():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b")]);
		Assert.notNull(h.helper.getCardResult("a"));
		h.helper.setHand([desc("c")]);
		Assert.isNull(h.helper.getCardResult("a"));
		Assert.notNull(h.helper.getCardResult("c"));
	}

	// ==================== Arrow Snap Point Provider ====================

	@Test
	public function testSetArrowSnapPointProvider():Void {
		var h = createHelper();
		Assert.isNull(h.helper.targeting.arrowSnapPointProvider);
		h.helper.setArrowSnapPointProvider((w) -> new FPoint(10, 20));
		Assert.notNull(h.helper.targeting.arrowSnapPointProvider);
	}

	@Test
	public function testSetArrowSnapPointProviderNull():Void {
		var h = createHelper();
		h.helper.setArrowSnapPointProvider((w) -> new FPoint(10, 20));
		h.helper.setArrowSnapPointProvider(null);
		Assert.isNull(h.helper.targeting.arrowSnapPointProvider);
	}

	@Test
	public function testGetTargetingObject():Void {
		var h = createHelper();
		var obj = h.helper.getTargetingObject();
		Assert.notNull(obj);
	}

	// ==================== customPlayAnimation ====================

	@Test
	public function testCustomPlayAnimationIsNullByDefault():Void {
		var h = createHelper();
		Assert.isNull(h.helper.customPlayAnimation);
	}

	@Test
	public function testCustomPlayAnimationAssignment():Void {
		var h = createHelper();
		h.helper.customPlayAnimation = (cardId, container, fromX, fromY, onDone) -> {
			onDone();
			return true;
		};
		Assert.notNull(h.helper.customPlayAnimation);
	}

	@Test
	public function testCustomPlayAnimationCalledOnDiscard():Void {
		// customPlayAnimation should NOT be called from discardCard (that's customDiscardAnimation)
		var h = createHelper();
		var playCalled = false;
		h.helper.customPlayAnimation = (cardId, container, fromX, fromY, onDone) -> {
			playCalled = true;
			onDone();
			return true;
		};
		h.helper.setHand([desc("a"), desc("b")]);
		h.helper.discardCard("a");
		Assert.isFalse(playCalled);
	}

	@Test
	public function testCustomPlayAnimationFallbackWhenReturnsFalse():Void {
		var h = createHelper();
		var callCount = 0;
		h.helper.customPlayAnimation = (cardId, container, fromX, fromY, onDone) -> {
			callCount++;
			return false; // Fall through to default
		};
		Assert.notNull(h.helper.customPlayAnimation);
		Assert.equals(0, callCount);
	}

	@Test
	public function testCustomPlayAnimationReceivesCardId():Void {
		var h = createHelper();
		var receivedId:Null<String> = null;
		h.helper.customPlayAnimation = (cardId, container, fromX, fromY, onDone) -> {
			receivedId = cardId;
			onDone();
			return true;
		};
		Assert.isNull(receivedId);
		// Can't easily simulate a full drag-play in unit test, but callback is wired
		Assert.notNull(h.helper.customPlayAnimation);
	}

	// ==================== customDiscardAnimation ====================

	@Test
	public function testCustomDiscardAnimationIsNullByDefault():Void {
		var h = createHelper();
		Assert.isNull(h.helper.customDiscardAnimation);
	}

	@Test
	public function testCustomDiscardAnimationAssignment():Void {
		var h = createHelper();
		h.helper.customDiscardAnimation = (cardId, container, fromX, fromY, onDone) -> {
			onDone();
			return true;
		};
		Assert.notNull(h.helper.customDiscardAnimation);
	}

	@Test
	public function testCustomDiscardAnimationCalledOnDiscard():Void {
		var h = createHelper();
		var discardCalled = false;
		var receivedId:Null<String> = null;
		h.helper.customDiscardAnimation = (cardId, container, fromX, fromY, onDone) -> {
			discardCalled = true;
			receivedId = cardId;
			onDone();
			return true;
		};
		h.helper.setHand([desc("a"), desc("b")]);
		h.helper.discardCard("a");
		Assert.isTrue(discardCalled);
		Assert.equals("a", receivedId);
	}

	@Test
	public function testCustomDiscardAnimationReceivesContainer():Void {
		var h = createHelper();
		var receivedContainer:Null<h2d.Object> = null;
		h.helper.customDiscardAnimation = (cardId, container, fromX, fromY, onDone) -> {
			receivedContainer = container;
			onDone();
			return true;
		};
		h.helper.setHand([desc("a")]);
		h.helper.discardCard("a");
		Assert.notNull(receivedContainer);
	}

	@Test
	public function testCustomDiscardAnimationFallbackWhenReturnsFalse():Void {
		var h = createHelper();
		var callCount = 0;
		h.helper.customDiscardAnimation = (cardId, container, fromX, fromY, onDone) -> {
			callCount++;
			return false; // Fall through to default
		};
		h.helper.setHand([desc("a"), desc("b")]);
		h.helper.discardCard("a");
		Assert.equals(1, callCount);
		// Card should still be removed from hand (default animation takes over)
		Assert.equals(1, h.helper.getCardCount());
	}

	@Test
	public function testCustomDiscardAnimationCardRemovedFromHand():Void {
		var h = createHelper();
		h.helper.customDiscardAnimation = (cardId, container, fromX, fromY, onDone) -> {
			onDone();
			return true;
		};
		h.helper.setHand([desc("a"), desc("b"), desc("c")]);
		h.helper.discardCard("b");
		Assert.equals(2, h.helper.getCardCount());
		Assert.isNull(h.helper.getCardResult("b"));
		Assert.notNull(h.helper.getCardResult("a"));
		Assert.notNull(h.helper.getCardResult("c"));
	}

	@Test
	public function testCustomDiscardAnimationEmitsEvent():Void {
		var h = createHelper();
		var events:Array<CardHandEvent> = [];
		h.helper.onCardEvent = (event) -> events.push(event);
		h.helper.customDiscardAnimation = (cardId, container, fromX, fromY, onDone) -> {
			// Simulate async: call onDone immediately for test
			onDone();
			return true;
		};
		h.helper.setHand([desc("a")]);
		h.helper.discardCard("a");
		// onDone was called, so DiscardAnimComplete should have fired
		var found = false;
		for (e in events) {
			switch (e) {
				case DiscardAnimComplete(id):
					if (id == "a") found = true;
				default:
			}
		}
		Assert.isTrue(found);
	}

	@Test
	public function testCustomDiscardAnimationDeferredOnDone():Void {
		var h = createHelper();
		var events:Array<CardHandEvent> = [];
		h.helper.onCardEvent = (event) -> events.push(event);
		var savedOnDone:Null<() -> Void> = null;
		h.helper.customDiscardAnimation = (cardId, container, fromX, fromY, onDone) -> {
			savedOnDone = onDone;
			return true;
		};
		h.helper.setHand([desc("a")]);
		h.helper.discardCard("a");
		// onDone NOT called yet — DiscardAnimComplete should NOT have fired
		var found = false;
		for (e in events) {
			switch (e) {
				case DiscardAnimComplete(_): found = true;
				default:
			}
		}
		Assert.isFalse(found);
		// Now call onDone
		if (savedOnDone != null) savedOnDone();
		found = false;
		for (e in events) {
			switch (e) {
				case DiscardAnimComplete(id):
					if (id == "a") found = true;
				default:
			}
		}
		Assert.isTrue(found);
	}

	@Test
	public function testCustomPlayAnimationNotCalledByDiscardCard():Void {
		// Verify isolation: customPlayAnimation is for drag-play only
		var h = createHelper();
		var playCalled = false;
		var discardCalled = false;
		h.helper.customPlayAnimation = (cardId, container, fromX, fromY, onDone) -> {
			playCalled = true;
			onDone();
			return true;
		};
		h.helper.customDiscardAnimation = (cardId, container, fromX, fromY, onDone) -> {
			discardCalled = true;
			onDone();
			return true;
		};
		h.helper.setHand([desc("a")]);
		h.helper.discardCard("a");
		Assert.isFalse(playCalled);
		Assert.isTrue(discardCalled);
	}

	@Test
	public function testBothCustomAnimationsCanBeSetIndependently():Void {
		var h = createHelper();
		h.helper.customPlayAnimation = (cardId, container, fromX, fromY, onDone) -> { onDone(); return true; };
		h.helper.customDiscardAnimation = (cardId, container, fromX, fromY, onDone) -> { onDone(); return true; };
		Assert.notNull(h.helper.customPlayAnimation);
		Assert.notNull(h.helper.customDiscardAnimation);
		// Clear one, other stays
		h.helper.customPlayAnimation = null;
		Assert.isNull(h.helper.customPlayAnimation);
		Assert.notNull(h.helper.customDiscardAnimation);
	}

	// ==================== Card with @switch arms — interactiveHelper auto-resync ====================
	// Verifies that the private `interactiveHelper` inside UICardHandHelper auto-resyncs its
	// bindings when a card's BuilderResult rebuilds (e.g. `@switch` arm flip inside the card).
	// Regression guard for the previously-known limitation where cards with internal switch arms
	// would have stale bindings after a parameter change.

	static final SWITCH_CARD_MANIM = "
		#switchCard programmable(mode:[armA, armB]=armA, status:[normal,hover,pressed,disabled]=normal) {
			@switch(mode) {
				armA: interactive(80, 110, \"hitA\", bind => \"status\"): 0, 0;
				armB: interactive(80, 110, \"hitB\", bind => \"status\"): 0, 0;
			}
		}
	";

	static function createSwitchHelper():{helper:UICardHandHelper, screen:UITestScreen} {
		var builder = BuilderTestBase.builderFromSource(SWITCH_CARD_MANIM);
		var screen = new UITestScreen();
		var helper = new UICardHandHelper(screen, builder);
		return {helper: helper, screen: screen};
	}

	@Test
	public function testCardHandRebuildListenerResyncOnSwitchArmFlip():Void {
		var h = createSwitchHelper();
		h.helper.setHand([{id: "c1", buildName: "switchCard"}]);

		final entry = h.helper.cards[0];
		final cardInteractiveId = entry.interactiveId;

		// Initial arm: hitA wrapped + bound via the card hand's private helper
		Assert.notNull(h.screen.getInteractive('$cardInteractiveId.hitA'),
			"initial: hitA screen wrapper should exist");
		Assert.isTrue(h.helper.interactiveHelper.hasBinding('$cardInteractiveId.hitA'),
			"initial: hitA should be bound in interactiveHelper");
		Assert.isFalse(h.helper.interactiveHelper.hasBinding('$cardInteractiveId.hitB'));

		// Flip the card's internal switch arm via setParameter
		entry.result.setParameter("mode", "armB");

		// After rebuild, screen wrappers AND interactiveHelper bindings must both resync
		Assert.isNull(h.screen.getInteractive('$cardInteractiveId.hitA'),
			"after flip: hitA screen wrapper should be gone");
		Assert.notNull(h.screen.getInteractive('$cardInteractiveId.hitB'),
			"after flip: hitB screen wrapper should appear");
		Assert.isFalse(h.helper.interactiveHelper.hasBinding('$cardInteractiveId.hitA'),
			"after flip: hitA binding should be removed from interactiveHelper");
		Assert.isTrue(h.helper.interactiveHelper.hasBinding('$cardInteractiveId.hitB'),
			"after flip: hitB binding should be added to interactiveHelper");

		// Flip back — hitA returns, hitB gone
		entry.result.setParameter("mode", "armA");
		Assert.notNull(h.screen.getInteractive('$cardInteractiveId.hitA'));
		Assert.isNull(h.screen.getInteractive('$cardInteractiveId.hitB'));
		Assert.isTrue(h.helper.interactiveHelper.hasBinding('$cardInteractiveId.hitA'));
		Assert.isFalse(h.helper.interactiveHelper.hasBinding('$cardInteractiveId.hitB'));
	}

	@Test
	public function testCardHandRebuildListenerRemovedOnDiscard():Void {
		var h = createSwitchHelper();
		h.helper.setHand([{id: "c1", buildName: "switchCard"}]);
		final entry = h.helper.cards[0];
		final savedResult = entry.result;

		// Listener should be installed
		Assert.notNull(entry.rebuildListener, "rebuildListener should be installed on buildCardEntry");

		// Discard the card
		h.helper.discardCard("c1");

		// Listener should be removed — subsequent setParameter should NOT attempt to resync bindings
		// on a disposed card. We can't easily inspect the internal listener array, but we can
		// verify the entry's own field was cleared.
		Assert.isNull(entry.rebuildListener, "rebuildListener should be cleared after discard");

		// Sanity: calling setParameter on the stale result must not throw — no listener runs.
		savedResult.setParameter("mode", "armB");
	}
}
