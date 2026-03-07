package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness.UITestScreen;
import bh.ui.UICardHandHelper;
import bh.ui.UICardHandLayout;
import bh.ui.UICardHandTypes;
import bh.paths.MultiAnimPaths.Path;
import bh.paths.MultiAnimPaths.SinglePath;
import bh.base.FPoint;

/**
 * Unit tests for UICardHandLayout math, UICardHandTypes enums,
 * and UICardHandHelper orchestration (setHand, drawCard, discardCard, etc.).
 */
class CardHandOrchestratorTest extends BuilderTestBase {
	// ==================== Helpers ====================

	/** Create a horizontal line path from (0,0) to (400,0). */
	static function createHorizontalPath():Path {
		var sp = new SinglePath(new FPoint(0, 0), new FPoint(400, 0), Line);
		return new Path([sp]);
	}

	/** Create an arc-like path (bezier) for more interesting layout. */
	static function createArcPath():Path {
		var sp = new SinglePath(new FPoint(0, 0), new FPoint(200, 0), Line);
		return new Path([sp]);
	}

	// ==================== Fan Layout ====================

	@Test
	public function testFanLayoutZeroCards():Void {
		var result = UICardHandLayout.computeFanLayout(0, 400.0, 500.0, 300.0, 30.0, -1, 20.0, 1.2, 3.0);
		Assert.equals(0, result.length);
	}

	@Test
	public function testFanLayoutSingleCard():Void {
		var result = UICardHandLayout.computeFanLayout(1, 400.0, 500.0, 300.0, 30.0, -1, 20.0, 1.2, 3.0);
		Assert.equals(1, result.length);
		// Single card centered, no rotation
		Assert.floatEquals(400.0, result[0].x);
		Assert.floatEquals(500.0, result[0].y);
		Assert.floatEquals(0.0, result[0].rotation);
		Assert.floatEquals(1.0, result[0].scale);
	}

	@Test
	public function testFanLayoutMultipleCards():Void {
		var result = UICardHandLayout.computeFanLayout(5, 400.0, 500.0, 300.0, 30.0, -1, 20.0, 1.2, 3.0);
		Assert.equals(5, result.length);

		// Cards should be roughly symmetric around anchorX
		// First card should be to the left, last to the right
		Assert.isTrue(result[0].x < result[4].x);

		// Middle card should be roughly centered
		var midX = result[2].x;
		Assert.isTrue(Math.abs(midX - 400.0) < 5.0);
	}

	@Test
	public function testFanLayoutHoverScale():Void {
		var result = UICardHandLayout.computeFanLayout(5, 400.0, 500.0, 300.0, 30.0, 2, 20.0, 1.5, 3.0);
		// Hovered card (index 2) should have scale 1.5
		Assert.floatEquals(1.5, result[2].scale);
		// Non-hovered should have scale 1.0
		Assert.floatEquals(1.0, result[0].scale);
		Assert.floatEquals(1.0, result[4].scale);
	}

	@Test
	public function testFanLayoutSingleCardHover():Void {
		var result = UICardHandLayout.computeFanLayout(1, 400.0, 500.0, 300.0, 30.0, 0, 20.0, 1.3, 3.0);
		Assert.equals(1, result.length);
		Assert.floatEquals(1.3, result[0].scale);
		// Hovered single card should pop up
		Assert.isTrue(result[0].y < 500.0);
	}

	@Test
	public function testFanLayoutNeighborSpread():Void {
		// With neighbor spread, cards adjacent to hover should be pushed apart
		var noHover = UICardHandLayout.computeFanLayout(5, 400.0, 500.0, 300.0, 30.0, -1, 20.0, 1.2, 3.0);
		var withHover = UICardHandLayout.computeFanLayout(5, 400.0, 500.0, 300.0, 30.0, 2, 20.0, 1.2, 5.0);

		// Card 1 (left neighbor of hover) should be pushed further left
		Assert.isTrue(withHover[1].x < noHover[1].x || withHover[1].rotation < noHover[1].rotation);
		// Card 3 (right neighbor of hover) should be pushed further right
		Assert.isTrue(withHover[3].x > noHover[3].x || withHover[3].rotation > noHover[3].rotation);
	}

	@Test
	public function testFanLayoutNormals():Void {
		var result = UICardHandLayout.computeFanLayout(3, 400.0, 500.0, 300.0, 30.0, -1, 20.0, 1.2, 3.0);
		// Normals should point roughly upward (negative Y)
		for (pos in result) {
			Assert.isTrue(pos.normalY < 0.0);
		}
	}

	// ==================== Linear Layout ====================

	@Test
	public function testLinearLayoutZeroCards():Void {
		var result = UICardHandLayout.computeLinearLayout(0, 400.0, 500.0, 80.0, 10.0, 800.0, -1, 20.0, 1.2, 10.0);
		Assert.equals(0, result.length);
	}

	@Test
	public function testLinearLayoutSingleCard():Void {
		var result = UICardHandLayout.computeLinearLayout(1, 400.0, 500.0, 80.0, 10.0, 800.0, -1, 20.0, 1.2, 10.0);
		Assert.equals(1, result.length);
		Assert.floatEquals(400.0, result[0].x);
		Assert.floatEquals(500.0, result[0].y);
		Assert.floatEquals(0.0, result[0].rotation); // Linear: no rotation
	}

	@Test
	public function testLinearLayoutSpacing():Void {
		var result = UICardHandLayout.computeLinearLayout(3, 400.0, 500.0, 80.0, 10.0, 800.0, -1, 20.0, 1.2, 10.0);
		Assert.equals(3, result.length);
		// Cards should be evenly spaced
		var step = result[1].x - result[0].x;
		var step2 = result[2].x - result[1].x;
		Assert.floatEquals(step, step2);
		// All at same Y (no hover)
		Assert.floatEquals(500.0, result[0].y);
		Assert.floatEquals(500.0, result[1].y);
		Assert.floatEquals(500.0, result[2].y);
		// No rotation in linear mode
		Assert.floatEquals(0.0, result[0].rotation);
	}

	@Test
	public function testLinearLayoutCompression():Void {
		// 10 cards * 80 width + 9 * 10 spacing = 890 > maxWidth 400
		var result = UICardHandLayout.computeLinearLayout(10, 400.0, 500.0, 80.0, 10.0, 400.0, -1, 20.0, 1.2, 10.0);
		Assert.equals(10, result.length);
		// Total span should be within maxWidth
		var totalSpan = result[9].x - result[0].x;
		Assert.isTrue(totalSpan <= 400.0);
	}

	@Test
	public function testLinearLayoutHoverPop():Void {
		var result = UICardHandLayout.computeLinearLayout(5, 400.0, 500.0, 80.0, 10.0, 800.0, 2, 30.0, 1.5, 10.0);
		// Hovered card should pop up (lower Y)
		Assert.isTrue(result[2].y < 500.0);
		Assert.floatEquals(1.5, result[2].scale);
		// Non-hovered at normal Y
		Assert.floatEquals(500.0, result[0].y);
	}

	// ==================== Path Layout ====================

	@Test
	public function testPathLayoutZeroCards():Void {
		var path = createHorizontalPath();
		var result = UICardHandLayout.computePathLayout(0, path, EvenRate, Straight, -1, 20.0, 1.2, 0.05);
		Assert.equals(0, result.length);
	}

	@Test
	public function testPathLayoutSingleCard():Void {
		var path = createHorizontalPath();
		var result = UICardHandLayout.computePathLayout(1, path, EvenRate, Straight, -1, 20.0, 1.2, 0.05);
		Assert.equals(1, result.length);
		// Single card at midpoint (rate=0.5) of path
		Assert.floatEquals(200.0, result[0].x);
		Assert.floatEquals(0.0, result[0].y);
	}

	@Test
	public function testPathLayoutEvenRate():Void {
		var path = createHorizontalPath(); // (0,0) to (400,0)
		var result = UICardHandLayout.computePathLayout(3, path, EvenRate, Straight, -1, 20.0, 1.2, 0.05);
		Assert.equals(3, result.length);
		// Rate 0, 0.5, 1.0 → X = 0, 200, 400
		Assert.floatEquals(0.0, result[0].x);
		Assert.floatEquals(200.0, result[1].x);
		Assert.floatEquals(400.0, result[2].x);
	}

	@Test
	public function testPathLayoutEvenArcLength():Void {
		var path = createHorizontalPath();
		var result = UICardHandLayout.computePathLayout(3, path, EvenArcLength, Straight, -1, 20.0, 1.2, 0.05);
		Assert.equals(3, result.length);
		// On a straight line, arc-length spacing = rate spacing
		Assert.floatEquals(0.0, result[0].x);
		Assert.floatEquals(400.0, result[2].x);
	}

	@Test
	public function testPathLayoutStraightOrientation():Void {
		var path = createHorizontalPath();
		var result = UICardHandLayout.computePathLayout(3, path, EvenRate, Straight, -1, 20.0, 1.2, 0.05);
		// Straight orientation: all rotations = 0
		for (pos in result) {
			Assert.floatEquals(0.0, pos.rotation);
		}
	}

	@Test
	public function testPathLayoutTangentOrientation():Void {
		var path = createHorizontalPath(); // horizontal line, tangent = 0
		var result = UICardHandLayout.computePathLayout(3, path, EvenRate, Tangent, -1, 20.0, 1.2, 0.05);
		// Tangent of horizontal line is 0 radians
		for (pos in result) {
			Assert.floatEquals(0.0, pos.rotation);
		}
	}

	@Test
	public function testPathLayoutTangentClamped():Void {
		var path = createHorizontalPath();
		var result = UICardHandLayout.computePathLayout(3, path, EvenRate, TangentClamped(10.0), -1, 20.0, 1.2, 0.05);
		// On horizontal line, tangent is 0, so clamping doesn't change anything
		for (pos in result) {
			Assert.isTrue(Math.abs(pos.rotation) <= 10.0 * Math.PI / 180.0 + 0.001);
		}
	}

	@Test
	public function testPathLayoutHoverPop():Void {
		var path = createHorizontalPath();
		var result = UICardHandLayout.computePathLayout(3, path, EvenRate, Straight, 1, 30.0, 1.5, 0.05);
		// Hovered card at index 1 should have scale 1.5
		Assert.floatEquals(1.5, result[1].scale);
		Assert.floatEquals(1.0, result[0].scale);
	}

	// ==================== CardHandTypes Enums ====================

	@Test
	public function testCardStateEnum():Void {
		var states:Array<CardState> = [InHand, Hovered, Dragging, Targeting, Animating, Disabled];
		Assert.equals(6, states.length);
		// Verify pattern matching
		for (s in states) {
			var name = switch (s) {
				case InHand: "inhand";
				case Hovered: "hovered";
				case Dragging: "dragging";
				case Targeting: "targeting";
				case Animating: "animating";
				case Disabled: "disabled";
			};
			Assert.notNull(name);
		}
	}

	@Test
	public function testTargetingResultEnum():Void {
		var t1 = TargetZone("zone1");
		var t2 = NoTarget;

		switch (t1) {
			case TargetZone(id): Assert.equals("zone1", id);
			default: Assert.fail("Expected TargetZone");
		}
		switch (t2) {
			case NoTarget: Assert.isTrue(true);
			default: Assert.fail("Expected NoTarget");
		}
	}

	@Test
	public function testCardHandEventEnum():Void {
		var events:Array<CardHandEvent> = [
			CardPlayed("c1", TargetZone("z1")),
			CardPlayed("c2", NoTarget),
			CardCombined("c1", "c2"),
			CardHoverStart("c1"),
			CardHoverEnd("c1"),
			CardDragStart("c1"),
			CardDragEnd("c1"),
			DrawAnimComplete("c1"),
			DiscardAnimComplete("c1"),
		];
		Assert.equals(9, events.length);

		// Verify first event
		switch (events[0]) {
			case CardPlayed(cardId, target):
				Assert.equals("c1", cardId);
				switch (target) {
					case TargetZone(id): Assert.equals("z1", id);
					default: Assert.fail("Expected TargetZone");
				}
			default:
				Assert.fail("Expected CardPlayed");
		}
	}

	@Test
	public function testHandLayoutModeEnum():Void {
		var modes:Array<HandLayoutMode> = [Fan, Linear, PathLayout];
		Assert.equals(3, modes.length);
	}

	@Test
	public function testPathDistributionEnum():Void {
		var dists:Array<PathDistribution> = [EvenArcLength, EvenRate];
		Assert.equals(2, dists.length);
	}

	@Test
	public function testPathOrientationEnum():Void {
		var straight = PathOrientation.Straight;
		var tangent = PathOrientation.Tangent;
		var clamped = PathOrientation.TangentClamped(15.0);

		switch (clamped) {
			case TangentClamped(maxDeg):
				Assert.floatEquals(15.0, maxDeg);
			default:
				Assert.fail("Expected TangentClamped");
		}
		Assert.notNull(straight);
		Assert.notNull(tangent);
	}

	// ==================== Helpers for Orchestration Tests ====================

	static final CARD_MANIM = "
		#card programmable(status:[normal,hover,pressed,disabled]=normal) {
			bitmap(generated(color(80, 110, #444444))): 0, 0
			interactive(80, 110, \"card\", bind => \"status\"): 0, 0
		}
	";

	/** Create a UICardHandHelper with minimal config for testing. */
	static function createHelper(?config:CardHandConfig):{helper:UICardHandHelper, screen:UITestScreen} {
		var builder = BuilderTestBase.builderFromSource(CARD_MANIM);
		var screen = new UITestScreen();
		var helper = new UICardHandHelper(screen, builder, config);
		return {helper: helper, screen: screen};
	}

	/** Create a simple card descriptor. */
	static function desc(id:String):CardDescriptor {
		return {id: id, buildName: "card"};
	}

	// ==================== setHand ====================

	@Test
	public function testSetHandAddsCards():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b"), desc("c")]);
		Assert.equals(3, h.helper.getCardCount());
		Assert.equals(3, h.helper.getCardIds().length);
	}

	@Test
	public function testSetHandReplacesExisting():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b"), desc("c")]);
		Assert.equals(3, h.helper.getCardCount());
		h.helper.setHand([desc("x"), desc("y")]);
		Assert.equals(2, h.helper.getCardCount());
	}

	// ==================== drawCard / discardCard ====================

	@Test
	public function testDrawCardIncrementsCount():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b")]);
		h.helper.drawCard(desc("c"));
		Assert.equals(3, h.helper.getCardCount());
	}

	@Test
	public function testDiscardCardDecrementsCount():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b"), desc("c")]);
		h.helper.discardCard("b");
		Assert.equals(2, h.helper.getCardCount());
	}

	@Test
	public function testDiscardUnknownIdSafe():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b")]);
		h.helper.discardCard("nonexistent");
		Assert.equals(2, h.helper.getCardCount());
	}

	// ==================== updateCardParams / setCardEnabled ====================

	@Test
	public function testUpdateCardParams():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		// Card should exist before update
		Assert.notNull(h.helper.getCardResult("a"));
		// Update the card's status parameter
		h.helper.updateCardParams("a", ["status" => "hover"]);
		// Card should still exist and be retrievable after param update
		Assert.notNull(h.helper.getCardResult("a"));
		Assert.equals(1, h.helper.getCardCount());
	}

	@Test
	public function testSetCardEnabledFalse():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		h.helper.setCardEnabled("a", false);
		// Card should still exist
		Assert.equals(1, h.helper.getCardCount());
		Assert.notNull(h.helper.getCardResult("a"));
	}

	@Test
	public function testSetCardEnabledTrue():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		h.helper.setCardEnabled("a", false);
		h.helper.setCardEnabled("a", true);
		Assert.notNull(h.helper.getCardResult("a"));
	}

	// ==================== getCardResult ====================

	@Test
	public function testGetCardResultReturnsResult():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		Assert.notNull(h.helper.getCardResult("a"));
	}

	@Test
	public function testGetCardResultUnknownNull():Void {
		var h = createHelper();
		h.helper.setHand([desc("a")]);
		Assert.isNull(h.helper.getCardResult("missing"));
	}

	// ==================== onCardBuilt callback ====================

	@Test
	public function testOnCardBuiltCallback():Void {
		var counter = 0;
		var config:CardHandConfig = {
			onCardBuilt: function(cardId, result, container) {
				counter++;
			}
		};
		var h = createHelper(config);
		h.helper.setHand([desc("a"), desc("b"), desc("c")]);
		Assert.equals(3, counter);
	}

	// ==================== canDragCard callback ====================

	@Test
	public function testCanDragCardVeto():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b")]);
		h.helper.canDragCard = function(cardId) { return cardId != "a"; };
		Assert.notNull(h.helper.canDragCard);
		// Verify the veto callback returns expected values
		Assert.isFalse(h.helper.canDragCard("a"));
		Assert.isTrue(h.helper.canDragCard("b"));
	}

	// ==================== drawCard at index ====================

	@Test
	public function testDrawCardAtIndex():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b")]);
		h.helper.drawCard(desc("c"), 0);
		var ids = h.helper.getCardIds();
		Assert.equals(3, ids.length);
		Assert.equals("c", ids[0]);
	}

	// ==================== dispose ====================

	@Test
	public function testDispose():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b"), desc("c")]);
		h.helper.dispose();
		Assert.equals(0, h.helper.getCardCount());
	}

	// ==================== getCardIds order ====================

	@Test
	public function testGetCardIdsOrder():Void {
		var h = createHelper();
		h.helper.setHand([desc("a"), desc("b"), desc("c")]);
		var ids = h.helper.getCardIds();
		Assert.equals("a", ids[0]);
		Assert.equals("b", ids[1]);
		Assert.equals("c", ids[2]);
	}
}
