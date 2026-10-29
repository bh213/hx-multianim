package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness.UITestScreen;
import bh.base.TweenManager;
import bh.ui.UICardHandHelper;
import bh.ui.UICardHandTypes.CardDescriptor;
import bh.ui.UICardHandTypes.CardHandConfig;
import bh.ui.UIInteractiveWrapper;
import bh.multianim.MultiAnimBuilder.BuilderResolvedSettings;
import bh.ui.UIElement.UIScreenEvent;

/**
 * Lifecycle edges of the runtime helpers: a wrapper rebound to an object it refuses, a tween asked
 * about from its own completion, and card hand animations that run while the hand changes or that
 * follow their path's length and shape.
 */
@:access(bh.ui.UICardHandHelper)
@:access(bh.ui.UICardHandTargeting)
class LifecycleReviewTest extends BuilderTestBase {
	// ==================== UIInteractiveWrapper.rebind ====================

	@Test
	public function testRebindThatRefusesAnUnknownCursorLeavesTheWrapperAsItWas():Void {
		final first = BuilderTestBase.buildFromSource("
			#p programmable() {
				interactive(10, 10, \"btn\", label => \"first\"): 0, 0
			}
		", "p");
		final second = BuilderTestBase.buildFromSource("
			#p programmable() {
				interactive(10, 10, \"btn\", label => \"second\", cursor => \"nosuchcursor\"): 0, 0
			}
		", "p");
		final wrapper = new UIInteractiveWrapper(first.interactives[0], null);

		var threw = false;
		try {
			@:privateAccess wrapper.rebind(second.interactives[0]);
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "precondition: an unknown cursor name is refused");
		Assert.equals(first.interactives[0], wrapper.interactive, "the refused rebind leaves the wrapper on the object it had");
		Assert.equals("first", wrapper.metadata.getStringOrDefault("label", ""), "and with the metadata it had");
	}

	// ==================== TweenManager.hasTweens from a completion ====================

	@Test
	public function testHasTweensIsFalseInsideABareTweensOwnOnComplete():Void {
		final mgr = new TweenManager();

		// A tween in a sequence: once it has finished, it animates nothing any more
		final inSequence = new h2d.Object();
		var askedInSequence:Null<Bool> = null;
		final member = mgr.createTween(inSequence, 0.01, [X(10.0)]);
		member.setOnComplete(() -> askedInSequence = mgr.hasTweens(inSequence));
		mgr.sequence([member, mgr.createTween(new h2d.Object(), 1.0, [X(5.0)])]);

		// A bare tween asking about its own target from its own onComplete
		final bare = new h2d.Object();
		var askedBare:Null<Bool> = null;
		mgr.tween(bare, 0.01, [X(10.0)]).setOnComplete(() -> askedBare = mgr.hasTweens(bare));

		mgr.update(0.0);
		mgr.update(0.1);

		Assert.isFalse(askedInSequence == null, "precondition: the sequence member's callback ran");
		Assert.isFalse(askedInSequence == true, "precondition: a finished sequence member does not count");
		Assert.isFalse(askedBare == null, "precondition: the bare tween's callback ran");
		Assert.isFalse(askedBare == true, "a bare tween that just finished does not count either, inside its own onComplete");
	}

	// ==================== Card hand helpers ====================

	static final CARD = "
		#card programmable(status:[normal,hover,pressed,disabled]=normal) {
			bitmap(generated(color(80, 110, #444444))): 0, 0
			interactive(80, 110, \"card\", bind => \"status\"): 0, 0
		}
	";

	static function helperFrom(source:String, config:CardHandConfig):{helper:UICardHandHelper, screen:UITestScreen} {
		final builder = BuilderTestBase.builderFromSource(source);
		final screen = new UITestScreen();
		return {helper: new UICardHandHelper(screen, builder, config), screen: screen};
	}

	static function desc(id:String):CardDescriptor {
		return {id: id, buildName: "card"};
	}

	static function pushOn(h:{helper:UICardHandHelper, screen:UITestScreen}, entry:Dynamic):Bool {
		return h.helper.handleScreenEvent(UIInteractiveEvent(UIPush, entry.interactiveId, new BuilderResolvedSettings(null)));
	}

	/** Drags the card `dx`, `dy` away from where it rests and lets go below the hand, out of every
	 *  zone: it flies back to its slot. The cursor starts far from the hand, so nothing is hovered. */
	static function dropAway(h:{helper:UICardHandHelper, screen:UITestScreen}, entry:Dynamic, dx:Float, dy:Float):Void {
		h.helper.onMouseMove(1000, 1000);
		pushOn(h, entry);
		h.helper.onMouseMove(1000 + dx, 1000 + dy);
		h.helper.onMouseRelease(1000 + dx, 1000 + dy);
	}

	/** Distance of (px, py) from the line through (ax, ay) and (bx, by). */
	static function distanceFromLine(px:Float, py:Float, ax:Float, ay:Float, bx:Float, by:Float):Float {
		final dx = bx - ax;
		final dy = by - ay;
		final len = Math.sqrt(dx * dx + dy * dy);
		if (len < 1e-9)
			return Math.sqrt((px - ax) * (px - ax) + (py - ay) * (py - ay));
		return Math.abs((px - ax) * dy - (py - ay) * dx) / len;
	}

	// ---- A card targeting while the hand changes ----

	static final ARROW_CARD = "
		paths {
			#arrowPath path { lineTo(100, 0) }
		}
		#arrowSegment programmable(valid:bool=false) {
			bitmap(generated(color(4, 2, #ffffff))): 0, 0
		}
		#arrowHead programmable(valid:bool=false) {
			bitmap(generated(color(6, 6, #ffffff))): 0, 0
		}
	" + CARD;

	@Test
	public function testACardTargetingWhileAnotherIsDiscardedKeepsItsArrowStartingAtIt():Void {
		final h = helperFrom(ARROW_CARD, {arrowSegmentName: "arrowSegment", arrowHeadName: "arrowHead", arrowPathName: "arrowPath"});
		h.helper.setHand([desc("a"), desc("b"), desc("c")]);
		final entryC = h.helper.cards[2];
		Assert.isTrue(h.helper.startDragFromInteractive(entryC), "precondition: c is dragged");
		h.helper.onMouseMove(640, 200); // up into the play zone
		Assert.isTrue(h.helper.isTargeting, "precondition: c targets");
		final origin = h.helper.targeting._scratchOrigin;
		Assert.floatEquals(entryC.container.x, origin.x, "precondition: the arrow starts at the card");

		h.helper.discardCard("a"); // the hand closes up: c's slot moves
		h.helper.onMouseMove(640, 210);

		Assert.isTrue(h.helper.isTargeting, "precondition: c still targets");
		Assert.floatEquals(entryC.container.x, origin.x, "the arrow still starts at the card (x)");
		Assert.floatEquals(entryC.container.y, origin.y, "the arrow still starts at the card (y)");
	}

	// ---- A return that follows its path ----

	static final DISTANCE_RETURN = "
		paths {
			#cardArc path { lineTo(0, -100) }
		}
		#returnPath animatedPath {
			path: cardArc
			type: distance
			speed: 400.0
		}
	" + CARD;

	/** Update steps of 0.02 s a card dropped `dy` below its slot takes to fly back. */
	static function stepsToFlyBack(dy:Float):Int {
		final h = helperFrom(DISTANCE_RETURN, {anchorX: 400, anchorY: 600, returnPathName: "returnPath"});
		h.helper.setHand([desc("a")]);
		dropAway(h, h.helper.cards[0], 0, dy);
		Assert.equals(1, h.helper.activeAnimations.length, 'precondition: the card dropped $dy px away flies back');
		var steps = 0;
		while (h.helper.activeAnimations.length > 0 && steps < 1000) {
			h.helper.update(0.02);
			steps++;
		}
		h.helper.dispose();
		return steps;
	}

	@Test
	public function testADistanceReturnPathTakesLongerTheFartherTheCardIsDropped():Void {
		final near = stepsToFlyBack(30);
		final far = stepsToFlyBack(600);
		Assert.isTrue(far > near,
			'at the same speed, flying back 600 px takes longer than flying back 30 px: near $near steps, far $far steps');
	}

	static final CLOSED_RETURN = "
		paths {
			#closedArc path {
				lineTo(50, -60)
				lineTo(50, 60)
				lineTo(-100, 0)
			}
		}
		#returnPath animatedPath {
			path: closedArc
			type: time
			duration: 1.0
		}
	" + CARD;

	@Test
	public function testACardReturningOnAClosedPathFollowsItsShapeAndLandsInItsSlot():Void {
		final h = helperFrom(CLOSED_RETURN, {anchorX: 400, anchorY: 600, returnPathName: "returnPath"});
		h.helper.setHand([desc("a")]);
		final entry = h.helper.cards[0];
		dropAway(h, entry, 300, 0); // 300 px to the right of its slot
		Assert.equals(1, h.helper.activeAnimations.length, "precondition: the card flies back");

		final fromX = entry.container.x;
		final fromY = entry.container.y;
		final slotX = entry.layoutPos.x;
		final slotY = entry.layoutPos.y;
		var farthest = 0.0;
		var steps = 0;
		while (h.helper.activeAnimations.length > 0 && steps < 200) {
			h.helper.update(0.05);
			steps++;
			farthest = Math.max(farthest, distanceFromLine(entry.container.x, entry.container.y, fromX, fromY, slotX, slotY));
		}

		Assert.equals(0, h.helper.activeAnimations.length, "precondition: the card has landed");
		Assert.isTrue(farthest > 5.0,
			'the card follows the closed path, not a straight line to its slot (farthest from that line: $farthest px)');
		Assert.floatEquals(slotX, entry.container.x, "and lands in its slot (x)");
		Assert.floatEquals(slotY, entry.container.y, "and lands in its slot (y)");
		h.helper.dispose();
	}
}
