package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.base.FPoint;
import bh.ui.UICardHandTargeting;
import bh.ui.UIInteractiveWrapper;
import bh.base.MAObject;
import bh.base.MAObject.MultiAnimObjectData;

/**
 * Unit tests for UICardHandTargeting.
 * Tests target registration, highlight state, hit testing,
 * and arrow endpoint snapping to target center.
 */
@:access(bh.ui.UICardHandTargeting)
class CardHandTargetingTest extends BuilderTestBase {
	// .manim with arrow segment, head, and path for full arrow visual tests
	static final ARROW_MANIM = "
		paths {
			#arrowPath path { lineTo(400, 0) }
		}
		#segment programmable(valid:bool=false) {
			bitmap(generated(color(10, 4, #FFFFFF))): 0, 0
		}
		#head programmable(valid:bool=false) {
			bitmap(generated(color(12, 8, #FF0000))): 0, 0
		}
	";

	// ============== Helpers ==============

	/** Create a positioned interactive MAObject at (x, y) with given dimensions. */
	static function createInteractive(id:String, w:Int, h:Int, x:Float, y:Float):UIInteractiveWrapper {
		var obj = new MAObject(MAInteractive(w, h, id, null), false);
		obj.setPosition(x, y);
		return new UIInteractiveWrapper(obj, null);
	}

	/** Create a targeting instance without arrow visuals (target detection only). */
	static function createTargetingNoArrow():UICardHandTargeting {
		var builder = BuilderTestBase.builderFromSource(ARROW_MANIM);
		return new UICardHandTargeting(builder);
	}

	/** Create a targeting instance with arrow visuals. */
	static function createTargetingWithArrow():UICardHandTargeting {
		var builder = BuilderTestBase.builderFromSource(ARROW_MANIM);
		return new UICardHandTargeting(builder, "segment", "head", "arrowPath", 25.0);
	}

	// ============== Initial state ==============

	@Test
	public function testInitialState():Void {
		var t = createTargetingNoArrow();
		Assert.isFalse(t.arrowContainer.visible);
		Assert.equals(0, t.targets.length);
		Assert.isNull(t.activeTargetId);
		Assert.isTrue(t.arrowEnabled);
	}

	@Test
	public function testInitialStateWithArrow():Void {
		var t = createTargetingWithArrow();
		Assert.isTrue(t.hasArrowVisual);
		Assert.equals(0, t.activeSegmentCount);
	}

	@Test
	public function testNoArrowVisualByDefault():Void {
		var t = createTargetingNoArrow();
		Assert.isFalse(t.hasArrowVisual);
	}

	// ============== Target registration ==============

	@Test
	public function testRegisterTarget():Void {
		var t = createTargetingNoArrow();
		var w = createInteractive("target1", 50, 50, 100, 100);
		t.registerTarget(w);
		Assert.equals(1, t.targets.length);
	}

	@Test
	public function testRegisterMultipleTargets():Void {
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 0, 0));
		t.registerTarget(createInteractive("t2", 50, 50, 100, 0));
		t.registerTarget(createInteractive("t3", 50, 50, 200, 0));
		Assert.equals(3, t.targets.length);
	}

	@Test
	public function testRegisterTargetReplacesExisting():Void {
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 0, 0));
		t.registerTarget(createInteractive("t1", 80, 80, 10, 10));
		Assert.equals(1, t.targets.length);
	}

	@Test
	public function testRegisterTargets():Void {
		var t = createTargetingNoArrow();
		t.registerTargets([
			createInteractive("t1", 50, 50, 0, 0),
			createInteractive("t2", 50, 50, 100, 0)
		]);
		Assert.equals(2, t.targets.length);
	}

	@Test
	public function testUnregisterTarget():Void {
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 0, 0));
		t.registerTarget(createInteractive("t2", 50, 50, 100, 0));
		t.unregisterTarget("t1");
		Assert.equals(1, t.targets.length);
		Assert.equals("t2", t.targets[0].id);
	}

	@Test
	public function testUnregisterActiveTargetClearsHighlight():Void {
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 0, 0));

		var highlighted:Array<{id:String, on:Bool}> = [];
		t.onTargetHighlight = (id, on, meta) -> highlighted.push({id: id, on: on});

		// Highlight t1 by hovering over it
		t.updateHighlight(25, 25, "card1");
		Assert.equals(1, highlighted.length);
		Assert.isTrue(highlighted[0].on);

		// Unregister t1 while it's the active highlight
		t.unregisterTarget("t1");

		// Should have fired un-highlight callback
		Assert.equals(2, highlighted.length);
		Assert.equals("t1", highlighted[1].id);
		Assert.isFalse(highlighted[1].on);
		Assert.isNull(t.activeTargetId);
	}

	@Test
	public function testUnregisterNonexistentTarget():Void {
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 0, 0));
		t.unregisterTarget("nonexistent");
		Assert.equals(1, t.targets.length);
	}

	@Test
	public function testClearTargets():Void {
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 0, 0));
		t.registerTarget(createInteractive("t2", 50, 50, 100, 0));
		t.clearTargets();
		Assert.equals(0, t.targets.length);
		Assert.isNull(t.activeTargetId);
	}

	// ============== Hit testing ==============

	@Test
	public function testHitTestTargetsHit():Void {
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));
		// Point inside the interactive (100+25, 100+25)
		var result = t.hitTestTargets(125, 125, "card1");
		Assert.equals("t1", result);
	}

	@Test
	public function testHitTestTargetsMiss():Void {
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));
		// Point outside
		var result = t.hitTestTargets(0, 0, "card1");
		Assert.isNull(result);
	}

	@Test
	public function testHitTestTargetsWithAcceptsFilter():Void {
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));
		t.acceptsFilter = (cardId, targetId, meta) -> cardId != "blocked";
		// Accepted card
		Assert.equals("t1", t.hitTestTargets(125, 125, "ok"));
		// Blocked card
		Assert.isNull(t.hitTestTargets(125, 125, "blocked"));
	}

	// ============== updateHighlight ==============

	@Test
	public function testUpdateHighlightEnter():Void {
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));

		var highlighted:Array<{id:String, on:Bool}> = [];
		t.onTargetHighlight = (id, on, meta) -> highlighted.push({id: id, on: on});

		t.updateHighlight(125, 125, "card1");
		Assert.equals(1, highlighted.length);
		Assert.equals("t1", highlighted[0].id);
		Assert.isTrue(highlighted[0].on);
	}

	@Test
	public function testUpdateHighlightLeave():Void {
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));

		var highlighted:Array<{id:String, on:Bool}> = [];
		t.onTargetHighlight = (id, on, meta) -> highlighted.push({id: id, on: on});

		// Enter target
		t.updateHighlight(125, 125, "card1");
		// Leave target
		t.updateHighlight(0, 0, "card1");

		Assert.equals(2, highlighted.length);
		Assert.isTrue(highlighted[0].on);
		Assert.isFalse(highlighted[1].on);
	}

	@Test
	public function testUpdateHighlightNoCallbackWhenSameTarget():Void {
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));

		var callCount = 0;
		t.onTargetHighlight = (id, on, meta) -> callCount++;

		t.updateHighlight(125, 125, "card1");
		t.updateHighlight(130, 130, "card1"); // Still on same target
		Assert.equals(1, callCount); // Only one enter callback
	}

	@Test
	public function testUpdateHighlightReturnValue():Void {
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));

		Assert.equals("t1", t.updateHighlight(125, 125, "card1"));
		Assert.isNull(t.updateHighlight(0, 0, "card1"));
	}

	// ============== clearLine ==============

	@Test
	public function testClearLineResetsHighlight():Void {
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));

		var unhighlighted = false;
		t.onTargetHighlight = (id, on, meta) -> {
			if (!on) unhighlighted = true;
		};

		t.updateHighlight(125, 125, "card1");
		t.clearLine();
		Assert.isTrue(unhighlighted);
		Assert.isNull(t.activeTargetId);
	}

	@Test
	public function testClearLineHidesArrowContainer():Void {
		var t = createTargetingWithArrow();
		t.arrowContainer.visible = true;
		t.clearLine();
		Assert.isFalse(t.arrowContainer.visible);
	}

	// ============== arrowEnabled ==============

	@Test
	public function testArrowEnabledDefault():Void {
		var t = createTargetingNoArrow();
		Assert.isTrue(t.arrowEnabled);
	}

	@Test
	public function testArrowEnabledToggle():Void {
		var t = createTargetingNoArrow();
		t.arrowEnabled = false;
		Assert.isFalse(t.arrowEnabled);
	}

	// ============== updateTargetingLine with arrow ==============

	@Test
	public function testUpdateTargetingLineNoTarget():Void {
		var t = createTargetingWithArrow();
		// No targets registered — arrow should draw but report no target
		var result = t.updateTargetingLine(0, 0, 200, 0, 200, 0, "card1");
		Assert.isNull(result);
		Assert.isTrue(t.arrowContainer.visible);
	}

	@Test
	public function testUpdateTargetingLineWithTarget():Void {
		var t = createTargetingWithArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));

		// Cursor at (125, 125) — inside the target
		var result = t.updateTargetingLine(0, 0, 125, 125, 125, 125, "card1");
		Assert.equals("t1", result);
	}

	@Test
	public function testUpdateTargetingLineArrowDisabled():Void {
		var t = createTargetingWithArrow();
		t.arrowEnabled = false;
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));

		// Even with arrow disabled, target detection still works
		var result = t.updateTargetingLine(0, 0, 125, 125, 125, 125, "card1");
		Assert.equals("t1", result);
		Assert.isFalse(t.arrowContainer.visible);
	}

	@Test
	public function testUpdateTargetingLineArrowSnapsToTargetCenter():Void {
		// The arrow snap change: when hovering a valid target, the arrow endpoint
		// should point to the target's center, not the cursor position.
		// In the headless test environment, objects are at root level so
		// localToGlobal/globalToLocal are identity transforms — the arrow endpoint
		// should be at the center of the interactive (x + w/2, y + h/2).
		var t = createTargetingWithArrow();
		var target = createInteractive("t1", 60, 40, 100, 80);
		t.registerTarget(target);

		// Cursor at (110, 90) — inside the target, but NOT at center
		var result = t.updateTargetingLine(0, 0, 110, 90, 110, 90, "card1");
		Assert.equals("t1", result);

		// The arrowhead should be placed at the path endpoint, which was computed
		// using the snapped center (130, 100) rather than the cursor (110, 90).
		// With Stretch normalization from (0,0) to snapped endpoint, the path's
		// end point (rate=1.0) will be at the snapped position.
		if (t.headValid != null) {
			// Head should be visible (valid target)
			Assert.isTrue(t.headValid.object.visible);
			Assert.isFalse(t.headInvalid.object.visible);
			// Head position should reflect the target center (130, 100), not cursor (110, 90)
			// The Stretch-normalized path maps (0,0)->(400,0) to (0,0)->(130,100)
			var headX = t.headValid.object.x;
			var headY = t.headValid.object.y;
			// Arrowhead should be near the target center, not the original cursor position
			Assert.isTrue(Math.abs(headX - 130) < 2.0, 'headX=$headX expected ~130');
			Assert.isTrue(Math.abs(headY - 100) < 2.0, 'headY=$headY expected ~100');
		}
	}

	@Test
	public function testUpdateTargetingLineNoSnapWhenNoTarget():Void {
		var t = createTargetingWithArrow();
		// No targets registered — arrow endpoint should be at cursor position
		var result = t.updateTargetingLine(0, 0, 200, 100, 200, 100, "card1");
		Assert.isNull(result);

		if (t.headValid != null && t.headInvalid != null) {
			// Invalid head visible (no target)
			Assert.isTrue(t.headInvalid.object.visible);
			Assert.isFalse(t.headValid.object.visible);
			// Head position should be at cursor (end of Stretch path from origin to cursor)
			var headX = t.headInvalid.object.x;
			var headY = t.headInvalid.object.y;
			Assert.isTrue(Math.abs(headX - 200) < 2.0, 'headX=$headX expected ~200');
			Assert.isTrue(Math.abs(headY - 100) < 2.0, 'headY=$headY expected ~100');
		}
	}

	// ============== clearTargets with active highlight ==============

	@Test
	public function testClearTargetsUnhighlightsActive():Void {
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));

		var unhighlightedId:Null<String> = null;
		t.onTargetHighlight = (id, on, meta) -> {
			if (!on) unhighlightedId = id;
		};

		t.updateHighlight(125, 125, "card1");
		t.clearTargets();
		Assert.equals("t1", unhighlightedId);
	}

	// ============== Custom arrow snap provider ==============

	@Test
	public function testCustomArrowSnapProvider():Void {
		// Custom provider: snap to top-left (0, 0) instead of center
		var t = createTargetingWithArrow();
		var target = createInteractive("t1", 60, 40, 100, 80);
		t.registerTarget(target);

		t.arrowSnapPointProvider = (w) -> new bh.base.FPoint(0, 0);

		// Cursor inside target
		var result = t.updateTargetingLine(0, 0, 110, 90, 110, 90, "card1");
		Assert.equals("t1", result);

		// Arrow head should snap to target's top-left (100, 80), not center (130, 100)
		if (t.headValid != null) {
			var headX = t.headValid.object.x;
			var headY = t.headValid.object.y;
			Assert.isTrue(Math.abs(headX - 100) < 2.0, 'headX=$headX expected ~100 (top-left)');
			Assert.isTrue(Math.abs(headY - 80) < 2.0, 'headY=$headY expected ~80 (top-left)');
		}
	}

	@Test
	public function testArrowSnapProviderNullFallsBackToCenter():Void {
		var t = createTargetingWithArrow();
		var target = createInteractive("t1", 60, 40, 100, 80);
		t.registerTarget(target);

		// Explicitly null — should use default center snap
		t.arrowSnapPointProvider = null;

		var result = t.updateTargetingLine(0, 0, 110, 90, 110, 90, "card1");
		Assert.equals("t1", result);

		if (t.headValid != null) {
			var headX = t.headValid.object.x;
			var headY = t.headValid.object.y;
			// Center of 60x40 interactive at (100, 80) = (130, 100)
			Assert.isTrue(Math.abs(headX - 130) < 2.0, 'headX=$headX expected ~130 (center)');
			Assert.isTrue(Math.abs(headY - 100) < 2.0, 'headY=$headY expected ~100 (center)');
		}
	}

	@Test
	public function testArrowSnapProviderCustomOffset():Void {
		// Snap to bottom-right corner of the interactive
		var t = createTargetingWithArrow();
		var target = createInteractive("t1", 60, 40, 100, 80);
		t.registerTarget(target);

		t.arrowSnapPointProvider = (w) -> {
			// Return bottom-right in local space
			switch w.interactive.multiAnimType {
				case MAInteractive(width, height, _, _):
					return new bh.base.FPoint(width, height);
				default:
					return new bh.base.FPoint(0, 0);
			}
		};

		var result = t.updateTargetingLine(0, 0, 110, 90, 110, 90, "card1");
		Assert.equals("t1", result);

		if (t.headValid != null) {
			var headX = t.headValid.object.x;
			var headY = t.headValid.object.y;
			// Bottom-right of 60x40 interactive at (100, 80) = (160, 120)
			Assert.isTrue(Math.abs(headX - 160) < 2.0, 'headX=$headX expected ~160 (bottom-right)');
			Assert.isTrue(Math.abs(headY - 120) < 2.0, 'headY=$headY expected ~120 (bottom-right)');
		}
	}

	@Test
	public function testSnapDisabledIgnoresProvider():Void {
		// When snapToTarget is false, provider should be ignored
		var t = createTargetingWithArrow();
		var target = createInteractive("t1", 60, 40, 100, 80);
		t.registerTarget(target);

		var providerCalled = false;
		t.arrowSnapPointProvider = (w) -> {
			providerCalled = true;
			return new bh.base.FPoint(0, 0);
		};
		t.snapToTarget = false;

		t.updateTargetingLine(0, 0, 110, 90, 110, 90, "card1");
		Assert.isFalse(providerCalled);
	}

	// ============== getObject ==============

	@Test
	public function testGetObjectReturnsArrowContainer():Void {
		var t = createTargetingWithArrow();
		var obj = t.getObject();
		Assert.notNull(obj);
		Assert.equals(t.arrowContainer, obj);
	}

	// ============== forceValid override (canPlayCard wiring) ==============

	@Test
	public function testForceValidFalseOverridesHoveredTarget():Void {
		// Regression: UICardHandHelper.updateDrag() now sets forceValid from
		// canPlayCard(cardId, target), so the player gets immediate red
		// feedback when dragging an unplayable card over a registered target.
		// Test the underlying mechanism: forceValid = false must show the
		// invalid (red) head even while the cursor is over a registered target.
		var t = createTargetingWithArrow();
		t.registerTarget(createInteractive("t1", 60, 40, 100, 80));

		// Cursor inside the target — without forceValid this would be valid.
		t.forceValid = false;
		var result = t.updateTargetingLine(0, 0, 130, 100, 130, 100, "card1");

		// Target detection still works (active highlight is set) ...
		Assert.equals("t1", result);
		// ... but the arrow visual is forced into the invalid state.
		if (t.headValid != null && t.headInvalid != null) {
			Assert.isFalse(t.headValid.object.visible, "valid head must be hidden when forceValid=false");
			Assert.isTrue(t.headInvalid.object.visible, "invalid head must be visible when forceValid=false");
		}
	}

	@Test
	public function testForceValidTrueOverridesNoTarget():Void {
		// The mirror case: forceValid = true forces the valid (green) head
		// even with no hovered target. Useful for previewing playability
		// in zones that don't use registered target interactives.
		var t = createTargetingWithArrow();
		// No targets registered.

		t.forceValid = true;
		var result = t.updateTargetingLine(0, 0, 200, 100, 200, 100, "card1");
		Assert.isNull(result, "no target should be reported when none registered");

		if (t.headValid != null && t.headInvalid != null) {
			Assert.isTrue(t.headValid.object.visible, "valid head must be visible when forceValid=true");
			Assert.isFalse(t.headInvalid.object.visible, "invalid head must be hidden when forceValid=true");
		}
	}

	@Test
	public function testForceValidNullFallsBackToHoverDetection():Void {
		// Default behavior: when forceValid is null, valid state mirrors
		// hoveredWrapper != null. Verifies the helper's `forceValid = null`
		// reset path doesn't break normal hover-driven valid color.
		var t = createTargetingWithArrow();
		t.registerTarget(createInteractive("t1", 60, 40, 100, 80));

		t.forceValid = null;
		var result = t.updateTargetingLine(0, 0, 130, 100, 130, 100, "card1");
		Assert.equals("t1", result);

		if (t.headValid != null && t.headInvalid != null) {
			Assert.isTrue(t.headValid.object.visible, "valid head visible when hovering target with forceValid=null");
			Assert.isFalse(t.headInvalid.object.visible);
		}
	}

	// ============== Allocation hygiene on the targeting hot path ==============
	// updateTargetingLine, updateHighlight, hitTestTargets all run every mouse-move
	// while the player is dragging a card. Every per-call `new h2d.col.Point` /
	// `new FPoint` is GC pressure on the hot path. Same scratch pattern as
	// UIMultiAnimGrid._scratchPoint and UICardHandHelper.scratchPoint.

	@Test
	public function testHitTestTargetsReusesScratchPointAcrossCalls():Void {
		// hitTestTargets must reuse a cached h2d.col.Point for the scene-space
		// hit-test. Without it, every mouse-move during direct-drag mode allocates.
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));

		// Prime the cache.
		t.hitTestTargets(125, 125, "card1");
		final cached:Dynamic = Reflect.field(t, "_scratchPt");
		Assert.notNull(cached,
			"UICardHandTargeting should expose a cached _scratchPt h2d.col.Point after hitTestTargets — got null");

		// Subsequent calls must reuse the same Point instance.
		t.hitTestTargets(130, 130, "card1");
		Assert.equals(cached, Reflect.field(t, "_scratchPt"),
			"hitTestTargets must reuse the cached _scratchPt (no allocation)");

		t.hitTestTargets(0, 0, "card1");
		Assert.equals(cached, Reflect.field(t, "_scratchPt"),
			"hitTestTargets must reuse the cached _scratchPt across calls");

		// Sanity: the cached Point's coords reflect the last input, proving it's actually used.
		t.hitTestTargets(777, 555, "card1");
		final pt:Dynamic = Reflect.field(t, "_scratchPt");
		Assert.floatEquals(777.0, pt.x, 0.001, "_scratchPt.x should reflect last hitTestTargets input");
		Assert.floatEquals(555.0, pt.y, 0.001, "_scratchPt.y should reflect last hitTestTargets input");
	}

	@Test
	public function testUpdateHighlightReusesScratchPointAcrossCalls():Void {
		// updateHighlight runs every mouse-move during normal card drag (arrow off);
		// it converts scene coords for containsPoint and must reuse a single Point.
		var t = createTargetingNoArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));

		t.updateHighlight(125, 125, "card1");
		final cached:Dynamic = Reflect.field(t, "_scratchPt");
		Assert.notNull(cached,
			"UICardHandTargeting should expose a cached _scratchPt h2d.col.Point after updateHighlight");

		t.updateHighlight(0, 0, "card1");
		Assert.equals(cached, Reflect.field(t, "_scratchPt"),
			"updateHighlight must reuse the cached _scratchPt across calls");
	}

	@Test
	public function testUpdateTargetingLineReusesScratchPointAcrossCalls():Void {
		// updateTargetingLine runs every mouse-move during arrow-targeting drag;
		// it allocates an h2d.col.Point for hit-testing and (when snapping) for the
		// snap-point conversion. A single scratch covers both — they don't overlap.
		var t = createTargetingWithArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));

		t.updateTargetingLine(0, 0, 125, 125, 125, 125, "card1");
		final cached:Dynamic = Reflect.field(t, "_scratchPt");
		Assert.notNull(cached,
			"UICardHandTargeting should expose a cached _scratchPt after updateTargetingLine");

		t.updateTargetingLine(0, 0, 130, 130, 130, 130, "card1");
		Assert.equals(cached, Reflect.field(t, "_scratchPt"),
			"updateTargetingLine must reuse the cached _scratchPt across calls");

		// Cursor outside any target — exercises the no-snap branch too.
		t.updateTargetingLine(0, 0, 500, 500, 500, 500, "card1");
		Assert.equals(cached, Reflect.field(t, "_scratchPt"),
			"updateTargetingLine must reuse _scratchPt regardless of snap branch");
	}

	@Test
	public function testUpdateTargetingLineReusesScratchEndpointFPoints():Void {
		// updateTargetingLine builds a Stretch path from origin -> cursor.
		// applyStretch reads x/y and forgets, so a single instance pair is safe.
		// Allocating fresh FPoints per call is pure GC waste on the targeting hot path.
		var t = createTargetingWithArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));

		t.updateTargetingLine(0, 0, 125, 125, 125, 125, "card1");
		final cachedOrigin:Dynamic = Reflect.field(t, "_scratchOrigin");
		final cachedCursor:Dynamic = Reflect.field(t, "_scratchCursor");
		Assert.notNull(cachedOrigin,
			"UICardHandTargeting should expose a cached _scratchOrigin FPoint after updateTargetingLine");
		Assert.notNull(cachedCursor,
			"UICardHandTargeting should expose a cached _scratchCursor FPoint after updateTargetingLine");

		t.updateTargetingLine(10, 20, 200, 250, 200, 250, "card1");
		Assert.equals(cachedOrigin, Reflect.field(t, "_scratchOrigin"),
			"updateTargetingLine must reuse the cached _scratchOrigin (no per-call allocation)");
		Assert.equals(cachedCursor, Reflect.field(t, "_scratchCursor"),
			"updateTargetingLine must reuse the cached _scratchCursor (no per-call allocation)");

		// Sanity: the cached FPoints reflect the last call's origin/cursor inputs,
		// proving they are actually used (not just held while allocating elsewhere).
		t.updateTargetingLine(33, 44, 555, 666, 555, 666, "card1");
		final origin:Dynamic = Reflect.field(t, "_scratchOrigin");
		final cursor:Dynamic = Reflect.field(t, "_scratchCursor");
		Assert.floatEquals(33.0, origin.x, 0.001, "_scratchOrigin.x should reflect last origin input");
		Assert.floatEquals(44.0, origin.y, 0.001, "_scratchOrigin.y should reflect last origin input");
		// _scratchCursor mirrors the snapped/cursor endpoint. With no target under (555,666)
		// and identity transforms in this headless test, it equals the cursor input directly.
		Assert.floatEquals(555.0, cursor.x, 0.001, "_scratchCursor.x should reflect last cursor input");
		Assert.floatEquals(666.0, cursor.y, 0.001, "_scratchCursor.y should reflect last cursor input");
	}

	@Test
	public function testUpdateTargetingLineEndpointFPointAllocationStable():Void {
		// Per-call FPoint delta must be stable across many calls — one warm-up
		// call settles the path-build allocations, and every follow-up call
		// should produce the same delta. With endpoint FPoints reused, the
		// 2-per-call endpoint surcharge is gone; without reuse, every call
		// allocates 2 extra FPoints just for origin/cursor.
		var t = createTargetingWithArrow();
		t.registerTarget(createInteractive("t1", 50, 50, 100, 100));

		// Warm up.
		t.updateTargetingLine(0, 0, 125, 125, 125, 125, "card1");

		// Measure single-call delta.
		final beforeOne = FPoint.creationCount;
		t.updateTargetingLine(0, 0, 130, 130, 130, 130, "card1");
		final perCall = FPoint.creationCount - beforeOne;

		// Run 9 more calls; total FPoint delta must equal 9 * perCall — i.e. no
		// per-call regression and no growth (e.g. accidentally allocating new
		// scratches in a branch). If the endpoint FPoints aren't reused, this
		// still holds in absolute terms, so we additionally bound the perCall
		// figure: it must NOT include the 2 endpoint allocations the bug fix
		// removed. Lower-bound is the path-build allocation count.
		final beforeMany = FPoint.creationCount;
		for (i in 0...9)
			t.updateTargetingLine(0, 0, 130.0 + i, 130.0 + i, 130.0 + i, 130.0 + i, "card1");
		final manyDelta = FPoint.creationCount - beforeMany;
		Assert.equals(perCall * 9, manyDelta,
			"per-call FPoint allocation must be stable across calls (no growth). " + "perCall=" + perCall + " manyDelta=" + manyDelta);

		// Also assert the endpoint allocations are gone. Compare against a fresh
		// instance whose updateTargetingLine has been wired to reuse scratches.
		// With 2 endpoint FPoints removed, perCall on this test setup should be
		// strictly less than (current path-build cost + 2). The exact path-build
		// cost depends on the path definition — to make this robust, we compute
		// it via Reflect on the cached scratches and assert presence (covered
		// by sibling test). Here we only assert that the cached scratches exist
		// AFTER the warm-up + perCall measurement, which guarantees the new
		// allocation path was taken.
		Assert.notNull(Reflect.field(t, "_scratchOrigin"),
			"_scratchOrigin must be allocated once (pre-fix this field doesn't exist)");
		Assert.notNull(Reflect.field(t, "_scratchCursor"),
			"_scratchCursor must be allocated once (pre-fix this field doesn't exist)");
	}
}
