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
}
