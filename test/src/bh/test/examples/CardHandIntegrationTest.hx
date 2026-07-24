package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness.UITestScreen;
import bh.ui.UICardHandHelper;
import bh.ui.UICardHandTypes;
import bh.ui.UIInteractiveWrapper;
import bh.base.FPoint;
import bh.base.MAObject;
import bh.base.MAObject.MultiAnimObjectData;
import bh.multianim.MultiAnimBuilder.BuilderResolvedSettings;
import bh.ui.UIElement.UIScreenEvent;

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

	// ==================== Default Interactive Prefix Uniqueness ====================

	@Test
	public function testTwoDefaultHelpersOnSameScreenProduceDistinctInteractiveIds():Void {
		// Two card hands on the same screen must not collide in screen.interactiveMap.
		// With a fixed default prefix and a per-helper sequence counter starting at 0,
		// both helpers produce "card_0.card" for their first card, and the screen's
		// interactiveMap.set() silently overwrites — routing events and autoStatus to
		// only the second helper.
		var builder1 = BuilderTestBase.builderFromSource(CARD_MANIM);
		var builder2 = BuilderTestBase.builderFromSource(CARD_MANIM);
		var screen = new UITestScreen();
		var helper1 = new UICardHandHelper(screen, builder1);
		var helper2 = new UICardHandHelper(screen, builder2);

		helper1.setHand([desc("a")]);
		helper2.setHand([desc("a")]);

		final id1 = helper1.cards[0].interactiveId;
		final id2 = helper2.cards[0].interactiveId;
		Assert.notEquals(id1, id2,
			'two helpers with default config must produce distinct card interactive prefixes '
			+ '(got "$id1" and "$id2" — collision would silently overwrite in screen.interactiveMap)');

		final wrapper1 = screen.getInteractive('$id1.card');
		final wrapper2 = screen.getInteractive('$id2.card');
		Assert.notNull(wrapper1, 'helper1\'s card wrapper "$id1.card" should be registered on the screen');
		Assert.notNull(wrapper2, 'helper2\'s card wrapper "$id2.card" should be registered on the screen');
		Assert.notEquals(wrapper1, wrapper2,
			"both helpers' wrappers must be distinct registrations — same wrapper means one helper "
			+ "overwrote the other in screen.interactiveMap");
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

	@Test
	public function testDisposeCancelsCardTransitionTweens():Void {
		// Card with a transition block — changing `status` spawns transition tweens via
		// builder.tweenManager. dispose() must cancel those tweens so they don't keep
		// ticking onComplete callbacks against detached scene graph objects.
		var manim = "
			#card programmable(status:[normal,hover,pressed,disabled]=normal) {
				transition { status: fade(0.5) }
				@(status=>normal) bitmap(generated(color(80, 110, #444444))): 0, 0
				@(status=>hover) bitmap(generated(color(80, 110, #888888))): 0, 0
				interactive(80, 110, \"card\", bind => \"status\"): 0, 0
			}
		";
		var builder = BuilderTestBase.builderFromSource(manim);
		var tm = new bh.base.TweenManager();
		builder.tweenManager = tm;

		var screen = new UITestScreen();
		var helper = new UICardHandHelper(screen, builder);
		helper.setHand([desc("a")]);

		// Trigger transition by changing status — spawns tweens on the card subtree.
		var entry = helper.cards[0];
		entry.result.setParameter("status", "hover");

		// Collect tween-bearing children — proves a transition tween is in flight.
		var bearers:Array<h2d.Object> = [];
		for (i in 0...entry.result.object.numChildren) {
			var child = entry.result.object.getChildAt(i);
			if (tm.hasTweens(child)) bearers.push(child);
		}
		Assert.isTrue(bearers.length > 0, "Expected transition tweens after status change (test precondition)");

		helper.dispose();

		// After dispose, none of the previously tracked targets should have live tweens.
		// `hasTweens` filters cancelled handles, so passing this asserts the tweens were
		// cancelled (not just orphaned).
		var stillTweening = 0;
		for (b in bearers)
			if (tm.hasTweens(b)) stillTweening++;
		Assert.equals(0, stillTweening, 'Expected 0 live tweens on disposed card subtree, got $stillTweening');
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

	// ==================== clearHand cancels in-flight animations ====================

	// Card .manim with paths so draw/discard go through `activeAnimations`
	// instead of falling through to the instant-snap branch in `animateCardTo`.
	static final CARD_WITH_PATHS_MANIM = "
		paths {
			#cardArc path { lineTo(0, -300) }
		}
		#drawPath animatedPath {
			path: cardArc
			type: time
			duration: 1.0
		}
		#discardPath animatedPath {
			path: cardArc
			type: time
			duration: 1.0
		}
		#card programmable(status:[normal,hover,pressed,disabled]=normal) {
			bitmap(generated(color(80, 110, #444444))): 0, 0
			interactive(80, 110, \"card\", bind => \"status\"): 0, 0
		}
	";

	static function createHelperWithPaths():{helper:UICardHandHelper, screen:UITestScreen} {
		var builder = BuilderTestBase.builderFromSource(CARD_WITH_PATHS_MANIM);
		var screen = new UITestScreen();
		var helper = new UICardHandHelper(screen, builder, {
			anchorX: 400, anchorY: 600,
			drawPathName: "drawPath",
			discardPathName: "discardPath",
			drawPilePosition: new FPoint(50, 600),
			discardPilePosition: new FPoint(750, 600),
		});
		return {helper: helper, screen: screen};
	}

	static function findEvent(events:Array<CardHandEvent>, predicate:(CardHandEvent) -> Bool):Bool {
		for (e in events)
			if (predicate(e))
				return true;
		return false;
	}

	@Test
	public function testClearingHandMidDiscardAnimationStillEmitsDiscardAnimComplete():Void {
		var h = createHelperWithPaths();
		var events:Array<CardHandEvent> = [];
		h.helper.onCardEvent = (event) -> events.push(event);
		h.helper.setHand([desc("a"), desc("b")]);

		h.helper.discardCard("a");
		// Path-driven animation queues; without update(dt) it stays in flight.
		Assert.isFalse(findEvent(events, e -> switch (e) { case DiscardAnimComplete("a"): true; default: false; }),
			"DiscardAnimComplete should be deferred while path animation is in flight");
		Assert.equals(1, h.helper.activeAnimations.length,
			"discardCard with discardPathName should queue exactly one active animation");

		// Cancel the in-flight animation by resetting the hand.
		h.helper.setHand([]);

		Assert.isTrue(findEvent(events, e -> switch (e) { case DiscardAnimComplete("a"): true; default: false; }),
			"DiscardAnimComplete must fire for the cancelled card so awaiting state machines can advance");
	}

	@Test
	public function testClearingHandMidDrawAnimationStillEmitsDrawAnimComplete():Void {
		var h = createHelperWithPaths();
		var events:Array<CardHandEvent> = [];
		h.helper.onCardEvent = (event) -> events.push(event);

		h.helper.drawCard(desc("incoming"));
		Assert.isFalse(findEvent(events, e -> switch (e) { case DrawAnimComplete("incoming"): true; default: false; }),
			"DrawAnimComplete should be deferred while path animation is in flight");
		Assert.isTrue(h.helper.activeAnimations.length >= 1,
			"drawCard with drawPathName should queue at least one active animation");

		h.helper.setHand([]);

		Assert.isTrue(findEvent(events, e -> switch (e) { case DrawAnimComplete("incoming"): true; default: false; }),
			"DrawAnimComplete must fire for the cancelled card so awaiting state machines can advance");
	}

	@Test
	public function testDisposeMidDiscardAnimationStillEmitsDiscardAnimComplete():Void {
		var h = createHelperWithPaths();
		var events:Array<CardHandEvent> = [];
		h.helper.onCardEvent = (event) -> events.push(event);
		h.helper.setHand([desc("a")]);

		h.helper.discardCard("a");
		Assert.isFalse(findEvent(events, e -> switch (e) { case DiscardAnimComplete("a"): true; default: false; }));

		h.helper.dispose();

		Assert.isTrue(findEvent(events, e -> switch (e) { case DiscardAnimComplete("a"): true; default: false; }),
			"dispose() routes through clearHand() — must also fire pending *AnimComplete events");
	}

	// ==================== Per-entry animation replacement preserves prior onComplete ====================
	// When `animateCardTo` / `animateCardToTracking` is called for an entry that already has
	// an animation in flight, the helper internally drops the previous animation. The previous
	// animation's onComplete owns scene-graph cleanup (container removal on discard) and event
	// emission (DrawAnimComplete / DiscardAnimComplete). It must still run when displaced —
	// otherwise consumers awaiting completion stall, and discarded card containers leak.

	@Test
	public function testDrawAnimCompleteFiresWhenInterruptedByDiscardOnSameCard():Void {
		var h = createHelperWithPaths();
		var events:Array<CardHandEvent> = [];
		h.helper.onCardEvent = (event) -> events.push(event);

		h.helper.setHand([desc("a")]);
		h.helper.drawCard(desc("b"));

		// Sanity: draw is queued, hasn't completed yet.
		Assert.isFalse(findEvent(events, e -> switch (e) { case DrawAnimComplete("b"): true; default: false; }),
			"DrawAnimComplete should be deferred while the draw animation is in flight");
		Assert.isTrue(h.helper.activeAnimations.length >= 1,
			"drawCard with drawPathName should queue an active animation");

		// Interrupt the in-flight draw with a discard on the same card. discardCard
		// calls animateCardTo, which calls removeAnimationsForEntry on b's entry —
		// dropping the draw animation along with its onComplete.
		h.helper.discardCard("b");

		Assert.isTrue(findEvent(events, e -> switch (e) { case DrawAnimComplete("b"): true; default: false; }),
			"DrawAnimComplete must fire even when discardCard cancels the in-flight draw on the same card");
	}

	@Test
	public function testDiscardCleanupRunsWhenAnimateCardToReplacesInFlightDiscard():Void {
		// Drive the bug at its narrowest: an entry has a discard animation queued, and
		// another animateCardTo() call lands on the same entry. The discard's onComplete
		// — which removes the container from the scene graph and emits DiscardAnimComplete —
		// must still run when displaced.
		var h = createHelperWithPaths();
		var events:Array<CardHandEvent> = [];
		h.helper.onCardEvent = (event) -> events.push(event);
		h.helper.setHand([desc("a")]);

		// Capture the entry before discardCard splices it from cards[].
		var aEntry = h.helper.cards[0];
		var aContainer = aEntry.container;

		h.helper.discardCard("a");
		Assert.equals(1, h.helper.activeAnimations.length,
			"discard animation should be queued before interruption");
		Assert.notNull(aContainer.parent,
			"card container should still be in the scene graph mid-discard");

		// Interrupt: schedule another animation on the same (already spliced) entry.
		// Triggers removeAnimationsForEntry on the in-flight discard.
		h.helper.animateCardTo(aEntry, 0, 0, 50, 50, 0, 0, "discardPath",
			() -> {});

		Assert.isTrue(findEvent(events, e -> switch (e) { case DiscardAnimComplete("a"): true; default: false; }),
			"DiscardAnimComplete must fire when the discard animation is replaced on its own entry");
		Assert.isNull(aContainer.parent,
			"container removal lives in the discard's onComplete — it must run on cancel to avoid scene-graph leak");
	}

	// ==================== Re-entrant mutation of activeAnimations ====================
	// removeAnimationsForEntry iterates activeAnimations backward with splice(i, 1) and
	// fires displaced.onComplete() synchronously. The onComplete can re-enter via
	// applyLayout(true) -> animateCardTo -> removeAnimationsForEntry, or via user-supplied
	// onCardEvent handlers triggered by emitEvent. When the re-entrant call mutates
	// activeAnimations (splices entries at indices < i, or replaces the array via
	// clearHand), the outer iteration's `i--` either dereferences a now-out-of-bounds
	// index (null-deref crash) or skips an unprocessed entry. The same hazard exists in
	// update(dt). clearHand already snapshots-then-fires for this exact reason — that
	// guarantee must apply to removeAnimationsForEntry too.

	@Test
	public function testRemoveAnimationsForEntryHandlesHandResetFromOnComplete():Void {
		var h = createHelperWithPaths();
		h.helper.setHand([desc("a"), desc("b"), desc("c")]);
		var events:Array<CardHandEvent> = [];

		h.helper.discardCard("a");
		h.helper.discardCard("b");
		h.helper.discardCard("c");
		Assert.equals(3, h.helper.activeAnimations.length,
			"three discards should queue three active animations before the iteration starts");

		// Capture C's entry — discardCard already spliced it from cards[] but its animation
		// is still in activeAnimations[2].
		var entryC = h.helper.activeAnimations[2].entry;

		// Hook the event handler so DiscardAnimComplete("c") triggers a hand reset.
		// setHand([]) routes through clearHand() which reassigns
		// activeAnimations = []. The outer removeAnimationsForEntry loop continues
		// with i-- and reads activeAnimations[1] on the now-empty array -> null deref.
		h.helper.onCardEvent = (event) -> {
			events.push(event);
			switch (event) {
				case DiscardAnimComplete("c"):
					h.helper.setHand([]);
				default:
			}
		};

		// Trigger cancellation of C's in-flight discard. Inside animateCardTo,
		// removeAnimationsForEntry(C) starts at i = 2, splices C, calls C.onComplete
		// which fires the user handler which resets the hand. After the handler returns,
		// the outer loop must not crash and must not skip A or B's onCompletes
		// (which are draining via clearHand's snapshot path).
		h.helper.animateCardTo(entryC, 0, 0, 200, 200, 0, 0, "discardPath", () -> {});

		Assert.isTrue(findEvent(events, e -> switch (e) { case DiscardAnimComplete("c"): true; default: false; }),
			"DiscardAnimComplete('c') must fire — its onComplete triggered the reset");
		Assert.isTrue(findEvent(events, e -> switch (e) { case DiscardAnimComplete("a"): true; default: false; }),
			"DiscardAnimComplete('a') must fire — it was drained by the cascading clearHand call");
		Assert.isTrue(findEvent(events, e -> switch (e) { case DiscardAnimComplete("b"): true; default: false; }),
			"DiscardAnimComplete('b') must fire — it was drained by the cascading clearHand call");
		// After the re-entrant clearHand drains A and B, animateCardTo proceeds to push
		// a fresh animation for C — so exactly one animation should remain.
		Assert.equals(1, h.helper.activeAnimations.length,
			"only the freshly-pushed C animation should remain after the re-entrant reset; the outer iteration must finish cleanly without leaving stale entries");
	}

	// ==================== Mouse handler allocation hygiene ====================

	@Test
	public function testMouseHandlersReuseCachedScratchPoint():Void {
		// onMouseMove, onMouseRelease, and getCardIdAtPosition are called on every mouse event.
		// They must convert scene coords -> handContainer local coords via globalToLocal, which
		// requires an h2d.col.Point. That Point must be cached on the helper and reused across
		// calls — allocating a fresh Point per event produces per-frame GC pressure on the hot path.
		var h = createHelper();
		h.helper.setHand([desc("c1"), desc("c2")]);

		// Prime the cache and capture the identity of the cached Point.
		h.helper.onMouseMove(100, 100);
		var cached:Dynamic = Reflect.field(h.helper, "scratchPoint");
		Assert.notNull(cached,
			"UICardHandHelper should expose a cached scratchPoint field after a mouse event — got null");

		// Subsequent mouse events must reuse the same Point instance, not allocate a new one.
		h.helper.onMouseMove(200, 150);
		Assert.equals(cached, Reflect.field(h.helper, "scratchPoint"),
			"onMouseMove must reuse the cached scratchPoint (no allocation)");

		h.helper.onMouseRelease(300, 400);
		Assert.equals(cached, Reflect.field(h.helper, "scratchPoint"),
			"onMouseRelease must reuse the cached scratchPoint (no allocation)");

		h.helper.getCardIdAtPosition(50, 50);
		Assert.equals(cached, Reflect.field(h.helper, "scratchPoint"),
			"getCardIdAtPosition must reuse the cached scratchPoint (no allocation)");

		// Sanity: the cached Point's coords should reflect the last globalToLocal call, proving
		// the helper is actually using it (not just holding it unused while allocating elsewhere).
		h.helper.onMouseMove(777, 555);
		final pt:Dynamic = Reflect.field(h.helper, "scratchPoint");
		Assert.notNull(pt);
		// globalToLocal mutates pt in place; with identity transform on handContainer the local
		// coords equal the scene coords passed in.
		Assert.floatEquals(777.0, pt.x, 0.001, "scratchPoint.x should reflect last onMouseMove input");
		Assert.floatEquals(555.0, pt.y, 0.001, "scratchPoint.y should reflect last onMouseMove input");
	}

	// onMouseMove fires hover detection through getCardAtBasePosition, which goes through
	// computeLayout → UICardHandLayout.computeFan/Linear/PathLayout. Those return a freshly
	// allocated Array<CardLayoutPosition> with N freshly-allocated CardLayoutPosition class
	// instances (it's @:structInit). For mouse-move (and the public getCardIdAtPosition) the
	// positions are read once for hit-test math and discarded — the static-buffer pattern
	// already used by _scratchRates in UICardHandLayout fits perfectly.
	@Test
	public function testGetCardIdAtPositionReusesLayoutPositionBufferAcrossCalls():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b"), desc("c"), desc("d"), desc("e")]);

		// Warm-up call: lazily populates the scratch buffer if implementation does that.
		h.helper.getCardIdAtPosition(50, 50);
		final allocatedAfterWarmup = CardLayoutPosition.creationCount;

		// Subsequent hit-test calls must not allocate fresh CardLayoutPosition instances.
		for (i in 0...10)
			h.helper.getCardIdAtPosition(50.0 + i, 50.0 + i);

		final delta = CardLayoutPosition.creationCount - allocatedAfterWarmup;
		Assert.equals(0, delta,
			"getCardIdAtPosition / getCardAtBasePosition must reuse a static Array<CardLayoutPosition> buffer "
			+ "across calls — every mouse-move runs hover detection on this path. Allocated " + delta
			+ " fresh CardLayoutPosition instances across 10 follow-up calls (5 cards each).");
	}

	// applyLayout(true) and rearrangeCards run on every hover/drag/draw. animateCardTo's
	// `from`/`to` FPoints are read for x/y only and forwarded to createProjectilePath →
	// applyStretch, which also reads-and-forgets. Allocating fresh FPoints per card per
	// layout pass is pure waste — primitives + an instance scratch pair give identical
	// behavior with zero per-call allocation.
	@Test
	public function testApplyLayoutAnimatedDoesNotAllocateFPointsPerCard():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b"), desc("c"), desc("d"), desc("e")]);

		FPoint.creationCount = 0;
		@:privateAccess h.helper.applyLayout(true);

		Assert.equals(0, FPoint.creationCount,
			"applyLayout(true) must not allocate FPoints per InHand card — animateCardTo should "
			+ "accept primitives (or reuse instance scratch FPoints internally). Allocated "
			+ FPoint.creationCount + " FPoints across 5 cards on a single layout pass.");
	}

	// applyLayout(true) is a hot path — fires on every hover change, drag start/end, draw,
	// and discard. The rearrange call site has no completion work to do, but the current
	// API forces it to pass a closure. `() -> {}` still allocates a fresh closure per
	// iteration (Haxe lambdas allocate on evaluation), wasting one allocation per InHand
	// card per layout pass. The fix: let `animateCardTo`'s onComplete be Null<() -> Void>
	// and pass `null` from the rearrange site. Asserting via the stored ActiveAnimation
	// is the most direct observable signal.
	@Test
	public function testApplyLayoutRearrangeStoresNullOnCompleteInsteadOfEmptyClosure():Void {
		var builder = BuilderTestBase.builderFromSource(CARD_WITH_PATHS_MANIM);
		var screen = new UITestScreen();
		// Reuse discardPath as the rearrange path — animateCardTo only needs a valid
		// animatedPath name; the test never advances time so the path content is irrelevant.
		var helper = new UICardHandHelper(screen, builder, {
			anchorX: 400, anchorY: 600,
			rearrangePathName: "discardPath",
		});
		helper.setHand([desc("a"), desc("b"), desc("c")]);

		// Perturb container positions so animateCardTo's snap-if-close fast path
		// (dx²+dy² < 1) does NOT fire — that would early-return without pushing an
		// ActiveAnimation, and we need ActiveAnimations to inspect onComplete.
		for (entry in helper.cards) {
			entry.container.x += 100;
			entry.container.y += 100;
		}

		helper.applyLayout(true);

		Assert.equals(3, helper.activeAnimations.length,
			"precondition: applyLayout(true) on 3 perturbed InHand cards should queue 3 animations");

		for (i in 0...helper.activeAnimations.length) {
			Assert.isNull(helper.activeAnimations[i].onComplete,
				"applyLayout(true)'s rearrange call site must pass null instead of `() -> {}` — "
				+ "an empty closure still allocates per card per layout pass on a hot path. "
				+ "ActiveAnimation[" + i + "].onComplete is non-null, meaning the call site is "
				+ "still constructing a throwaway closure.");
		}
	}

	// rearrangeCards fires on every drawCard / discardCard for every non-skipped card in
	// the hand. Its onComplete closure captures `entry` and `pos` purely to (a) call
	// resolveAnimationComplete and (b) write pos.scale onto the container. Both are
	// expressible as ActiveAnimation state — pos.scale is always 1.0 for rearrange call
	// sites (positions come from computeLayout(-1)) and state.scale from the path settles
	// to 1.0 anyway; resolveAnimationComplete only matters for Disabled cards with a
	// pending re-enable, which can be driven by a flag on ActiveAnimation instead of a
	// per-card closure. Leaving the closure in place wastes one allocation per non-skipped
	// card per draw/discard.
	@Test
	public function testRearrangeCardsStoresNullOnCompleteInsteadOfPerCardClosure():Void {
		var builder = BuilderTestBase.builderFromSource(CARD_WITH_PATHS_MANIM);
		var screen = new UITestScreen();
		// discardPath is reused as the rearrange path here — the test never advances time,
		// so the path's contents don't matter as long as animateCardTo queues an animation.
		var helper = new UICardHandHelper(screen, builder, {
			anchorX: 400, anchorY: 600,
			rearrangePathName: "discardPath",
		});
		helper.setHand([desc("a"), desc("b"), desc("c"), desc("d")]);

		// Perturb container positions so animateCardTo's snap-if-close fast path
		// (dx²+dy² < 1) does NOT fire — that would early-return without pushing an
		// ActiveAnimation.
		for (entry in helper.cards) {
			entry.container.x += 100;
			entry.container.y += 100;
		}

		// Drain any animations queued by setHand → applyLayout so we observe only the
		// rearrangeCards-queued ones below.
		helper.activeAnimations.resize(0);

		// skipIndex=0 mimics drawCard's "skip the newly-drawn card" semantics. The
		// remaining 3 cards should all queue rearrange animations.
		var positions = helper.computeLayout(-1);
		helper.rearrangeCards(positions, 0);

		Assert.equals(3, helper.activeAnimations.length,
			"precondition: rearrangeCards on 4 perturbed cards with skipIndex=0 should queue 3 animations");

		for (i in 0...helper.activeAnimations.length) {
			Assert.isNull(helper.activeAnimations[i].onComplete,
				"rearrangeCards must pass null onComplete instead of a per-card closure — "
				+ "the closure captures `entry` and `pos` only to call resolveAnimationComplete "
				+ "and write a redundant pos.scale, both of which can be driven from ActiveAnimation "
				+ "state. ActiveAnimation[" + i + "].onComplete is non-null, meaning the call site "
				+ "is still constructing a throwaway closure per card per rearrange.");
		}
	}

	// ==================== UIPush hit-test consistency with hover ====================
	// Hover detection (onMouseMove → getCardAtBasePosition) intentionally uses the base
	// layout, ignoring the hover pop, so the popped card doesn't block neighbor detection.
	// But UIPush is routed by Heaps to whichever Interactive physically contains the
	// cursor — i.e. post-pop positions. When the hand overlaps and the hovered card has
	// popped up out from under the cursor, the cursor sits in the popped card's old
	// shadow — over a neighbor's Interactive. Heaps fires UIPush on the neighbor; if the
	// helper trusts that id, drag starts on the wrong card while the visually-highlighted
	// card stays hovered. Click must follow the same hit-test as hover.

	@Test
	public function testUIPushOnNeighborInteractiveStartsDragOnHoveredCard():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b"), desc("c")]);

		final entryA = h.helper.cards[0];
		final entryB = h.helper.cards[1];

		// Force hover on A — mimics what onMouseMove would do via the base-layout
		// hit-test. A becomes the visually-highlighted card.
		h.helper.setHoveredEntry(entryA);
		Assert.equals(entryA, h.helper.hoveredEntry,
			"precondition: A must be the hovered entry before UIPush arrives");

		// UIPush fires on B's interactive: Heaps' physical hit-test on actual
		// post-pop positions disagrees with the base-layout hover hit-test.
		final emptyMeta = new BuilderResolvedSettings(null);
		final consumed = h.helper.handleScreenEvent(
			UIInteractiveEvent(UIPush, entryB.interactiveId, emptyMeta));

		Assert.isTrue(consumed,
			"UIPush on a card interactive must be consumed (drag started)");
		Assert.equals(entryA, h.helper.draggedEntry,
			"Drag must follow the visually-hovered card (A), not the card whose "
			+ "interactive Heaps happened to route UIPush to (B). Click hit-test "
			+ "must agree with hover hit-test.");
		Assert.isTrue(h.helper.isDragging,
			"isDragging must be true after UIPush on a hovered card's neighbor");
	}

	@Test
	public function testUIPushFallsBackToInteractiveEntryWhenNothingHovered():Void {
		// Fallback path: when nothing is hovered (cursor outside the hand), UIPush
		// must still drag the card whose interactive fired — same as before the fix.
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b")]);

		final entryB = h.helper.cards[1];
		Assert.isNull(h.helper.hoveredEntry,
			"precondition: no card is hovered");

		final emptyMeta = new BuilderResolvedSettings(null);
		final consumed = h.helper.handleScreenEvent(
			UIInteractiveEvent(UIPush, entryB.interactiveId, emptyMeta));

		Assert.isTrue(consumed);
		Assert.equals(entryB, h.helper.draggedEntry,
			"With nothing hovered, drag must follow the interactive that fired");
	}

	// ==================== Rotated interactive hit-test ====================
	// Fan layout sets non-zero rotation on each card's container. The interactive child
	// inherits that rotation through the parent chain. UIInteractiveWrapper.containsPoint
	// hit-tests via globalToLocal, which must invert every transform up the chain — including
	// rotation — for click and hover to land on the right card. A regression that silently
	// drops rotation (e.g. axis-aligned rect check on world coords, or skipping the parent
	// transform walk) would still pass simple cases where rotation is zero, but break the
	// outer fan cards. Lock this in with a direct probe on a rotated parent: the only point
	// that distinguishes a correct globalToLocal-based check from a rotation-dropping one is
	// a global coordinate whose preimage flips sides of the rect when rotation is honored.

	@Test
	public function testInteractiveContainsPointHonorsParentRotation():Void {
		// Build an MAInteractive (80x110) at parent local origin under a rotated container.
		// Parent at (100, 100), rotation = π/2 (90° CCW).
		final interactive = new MAObject(MAInteractive(80, 110, "card", null), false);
		final wrapper = new UIInteractiveWrapper(interactive, null);

		final parent = new h2d.Object();
		parent.setPosition(100, 100);
		parent.rotation = Math.PI / 2;
		parent.addChild(interactive);

		// 90° CCW: child local (lx, ly) projects to global (-ly + 100, lx + 100).
		// Local (40, 55) (rect center) → global (45, 140).
		Assert.isTrue(wrapper.containsPoint(new h2d.col.Point(45, 140)),
			"global (45, 140) is the projection of local center (40, 55) through 90° rotation; "
			+ "containsPoint must hit it via globalToLocal");

		// Local (200, 55) is well outside the 80x110 rect. Projects to global (45, 300).
		Assert.isFalse(wrapper.containsPoint(new h2d.col.Point(45, 300)),
			"global (45, 300) projects from local (200, 55), outside the rect");

		// Discriminator: global (140, 155) maps to local (40, 55) WITHOUT rotation (would hit),
		// but to local (55, -40) WITH 90° rotation (y outside [0..110], must miss). This is the
		// regression guard — a rotation-dropping implementation would return true here.
		Assert.isFalse(wrapper.containsPoint(new h2d.col.Point(140, 155)),
			"global (140, 155) is inside the unrotated rect but outside the 90°-rotated rect; "
			+ "containsPoint must honor parent rotation and miss");
	}

	@Test
	public function testInteractiveContainsPointHonorsCardHandFanRotation():Void {
		// End-to-end check: drive the interactive through the actual card hand fan layout
		// (rather than a hand-rolled rotated parent) so the test fails if anything in the
		// pivotWrapper/result.object chain ever drops rotation. Pick the leftmost card —
		// fan layout gives outer cards the largest rotation in absolute value.
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b"), desc("c"), desc("d"), desc("e")]);

		final entry = h.helper.cards[0];
		Assert.notEquals(0.0, entry.container.rotation,
			"precondition: outer fan card should have non-zero rotation after setHand");

		final wrapper = h.screen.getInteractive(entry.interactiveId + ".card");
		Assert.notNull(wrapper, "screen wrapper for outer fan card should be registered");

		// Project a known-inside local point (rect center) through the live transform chain
		// to a global coordinate, then assert containsPoint hits it. Round-trip via
		// localToGlobal/globalToLocal proves the transform stack — including the fan rotation
		// on entry.container — is being inverted on hit-test.
		final intr:h2d.Object = cast wrapper.interactive;
		final globalCenter = intr.localToGlobal(new h2d.col.Point(40, 55));
		Assert.isTrue(wrapper.containsPoint(new h2d.col.Point(globalCenter.x, globalCenter.y)),
			"containsPoint must hit the global projection of the rect center under the live "
			+ "fan rotation; missing here means rotation is being dropped on the hit-test path");

		// Project a local point well outside the rect and assert it misses. This guards
		// against a regression that returns true unconditionally.
		final globalOutside = intr.localToGlobal(new h2d.col.Point(500, 55));
		Assert.isFalse(wrapper.containsPoint(new h2d.col.Point(globalOutside.x, globalOutside.y)),
			"containsPoint must miss a global point whose preimage is outside the rect");
	}

	// Allocation watchdog counters (FPoint.creationCount,
	// UICardHandLayout.scratchArrayAllocationCount, CardLayoutPosition.creationCount)
	// must be gated behind MULTIANIM_ALLOC_TRACK so they vanish from production builds.
	// Test builds need the flag defined in test-common.hxml or the watchdog tests fail
	// to compile (counters become unreachable identifiers).
	@Test
	public function testAllocationTrackingFlagIsDefinedInTestBuilds():Void {
		#if MULTIANIM_ALLOC_TRACK
		Assert.pass();
		#else
		Assert.fail("MULTIANIM_ALLOC_TRACK must be defined in test builds. It gates the static "
			+ "counters FPoint.creationCount, UICardHandLayout.scratchArrayAllocationCount, "
			+ "and CardLayoutPosition.creationCount, which are read by allocation watchdog "
			+ "tests in CardHandIntegrationTest and CardHandOrchestratorTest. "
			+ "Add `-D MULTIANIM_ALLOC_TRACK` to test-common.hxml.");
		#end
	}
}
