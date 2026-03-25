package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.ui.UIMultiAnimDraggable;
import bh.ui.UIMultiAnimDraggable.DragEvent;
import bh.ui.UIMultiAnimDraggable.DraggableState;
import bh.ui.UIMultiAnimDraggable.DropZone;
import bh.ui.UIMultiAnimDraggable.DropZoneId;
import bh.ui.UIMultiAnimDraggable.DropZoneIdTools;
import bh.ui.UIMultiAnimDraggable.AnimatedPathFactory;
import bh.multianim.MultiAnimBuilder.SlotHandle;
import bh.paths.AnimatedPath.AnimatedPathMode;
import bh.paths.MultiAnimPaths.PathType;
import h2d.col.Bounds;
import h2d.col.Point;

/**
 * Unit tests for UIMultiAnimDraggable.
 * Tests drag lifecycle, drop zone integration, swap mode, zone tracking, and edge cases.
 */
class UIDraggableTest extends BuilderTestBase {
	// ============== Helpers ==============

	static function createSlot():SlotHandle {
		var container = new h2d.Object();
		return new SlotHandle(container);
	}

	static function createContentObject(name:String):h2d.Object {
		var obj = new h2d.Object();
		obj.name = name;
		return obj;
	}

	static function createDraggable(?name:String):UIMultiAnimDraggable {
		return new UIMultiAnimDraggable(createContentObject(name != null ? name : "content"));
	}

	static function createBoundsAt(x:Float, y:Float, w:Float, h:Float):Bounds {
		var b = new Bounds();
		b.set(x, y, w, h);
		return b;
	}

	/** Start a drag on the given draggable, return the control for further simulation. */
	static function startDrag(drag:UIMultiAnimDraggable, ?pos:Point):{control:bh.test.UITestHarness.MockControllable} {
		var control = new bh.test.UITestHarness.MockControllable();
		var p = pos != null ? pos : new Point(10, 10);
		bh.test.UITestHarness.simulatePush(drag, control, p);
		return {control: control};
	}

	/** Simulate mouse move during drag. */
	static function simulateMove(drag:UIMultiAnimDraggable, control:bh.test.UITestHarness.MockControllable, pos:Point):Void {
		drag.onEvent(bh.test.UITestHarness.createEventWrapper(OnMouseMove, control, pos));
	}

	/** Simulate mouse release during drag. */
	static function simulateRelease(drag:UIMultiAnimDraggable, control:bh.test.UITestHarness.MockControllable, pos:Point,
			?button:Int):Void {
		drag.onEvent(bh.test.UITestHarness.createEventWrapper(OnRelease(button != null ? button : 0), control, pos));
	}

	// ============== Bug 1.15: swap mode sourceSlot validation ==============

	@Test
	public function testSwapModeSnapshotsCapturedBeforeAnimation():Void {
		// Setup: source slot with content "A", target zone slot with content "B"
		var sourceSlot = createSlot();
		var targetSlot = createSlot();

		var contentA = createContentObject("A");
		var contentB = createContentObject("B");

		sourceSlot.setContent(contentA);
		sourceSlot.data = "dataA";
		targetSlot.setContent(contentB);
		targetSlot.data = "dataB";

		// Create draggable from source slot — this removes content from source
		var drag = UIMultiAnimDraggable.createFromSlot(sourceSlot);
		Assert.notNull(drag);
		drag.swapMode = true;

		// Simulate external code modifying the source slot while drag is in progress
		var externalContent = createContentObject("External");
		sourceSlot.setContent(externalContent);
		sourceSlot.data = "externalData";

		// Now the swap onComplete callback would run — it reads sourceSlot.data
		// which is now "externalData" instead of "dataA".
		// The bug: swap operates on stale data because sourceSlot was externally modified.

		// After fix: draggable should snapshot sourceSlot state at drag start,
		// so external modifications don't affect the swap.

		// Verify the draggable captured the source slot reference
		Assert.notNull(drag.sourceSlot);
		Assert.equals(sourceSlot, drag.sourceSlot);

		// Verify draggable has sourceData snapshot
		Assert.equals("dataA", drag.sourceData);
	}

	@Test
	public function testSwapModePreservesSnapshotAfterExternalModification():Void {
		var sourceSlot = createSlot();
		var contentA = createContentObject("A");
		sourceSlot.setContent(contentA);
		sourceSlot.data = "originalData";

		var drag = UIMultiAnimDraggable.createFromSlot(sourceSlot);
		Assert.notNull(drag);
		drag.swapMode = true;

		// Verify snapshot captured at creation
		Assert.equals("originalData", drag.sourceData);

		// Modify source slot externally
		sourceSlot.data = "modifiedData";

		// Snapshot should remain unchanged
		Assert.equals("originalData", drag.sourceData);
	}

	// ============== Bug 1.7: clear() partial cleanup ==============

	@Test
	public function testClearRemovesRootFromScene():Void {
		var content = createContentObject("content");
		var drag = new UIMultiAnimDraggable(content);

		var parent = new h2d.Object();
		parent.addChild(drag.getObject());
		Assert.notNull(drag.getObject().parent);

		drag.clear();

		// After clear(), root should be removed from scene
		Assert.isNull(drag.getObject().parent);
	}

	@Test
	public function testClearDisablesElement():Void {
		var content = createContentObject("content");
		var drag = new UIMultiAnimDraggable(content);
		Assert.isTrue(drag.enabled);

		drag.clear();

		// After clear(), draggable should be disabled to prevent stale event processing
		Assert.isFalse(drag.enabled);
	}

	@Test
	public function testClearSetsTargetNull():Void {
		var content = createContentObject("content");
		var drag = new UIMultiAnimDraggable(content);
		Assert.notNull(drag.getTarget());

		drag.clear();

		Assert.isNull(drag.getTarget());
	}

	// ============== cancelDrag: programmatic drag cancellation ==============

	@Test
	public function testCancelDragFromDraggingState():Void {
		var content = createContentObject("content");
		var drag = new UIMultiAnimDraggable(content);
		var control = new bh.test.UITestHarness.MockControllable();

		// Start drag
		bh.test.UITestHarness.simulatePush(drag, control, new h2d.col.Point(10, 10));

		// Verify we're dragging
		@:privateAccess Assert.isTrue(drag.state == Dragging);
		var mockCapture:bh.test.UITestHarness.MockCaptureEvents = cast control.captureEvents;
		Assert.isTrue(mockCapture.capturing);

		// Cancel drag
		drag.cancelDrag();

		// Verify state restored
		@:privateAccess Assert.isTrue(drag.state == Idle);
		Assert.isFalse(mockCapture.capturing);
	}

	@Test
	public function testCancelDragRestoresAlpha():Void {
		var content = createContentObject("content");
		content.alpha = 0.9;
		var drag = new UIMultiAnimDraggable(content);
		drag.dragAlpha = 0.5;
		var control = new bh.test.UITestHarness.MockControllable();

		bh.test.UITestHarness.simulatePush(drag, control, new h2d.col.Point(10, 10));
		Assert.floatEquals(0.5, content.alpha);

		drag.cancelDrag();
		Assert.floatEquals(0.9, content.alpha);
	}

	@Test
	public function testCancelDragFiresDragCancelEvent():Void {
		var content = createContentObject("content");
		var drag = new UIMultiAnimDraggable(content);
		var control = new bh.test.UITestHarness.MockControllable();
		var events:Array<DragEvent> = [];
		drag.onDragEvent = (e, _, _) -> events.push(e);

		bh.test.UITestHarness.simulatePush(drag, control, new h2d.col.Point(10, 10));
		events.resize(0); // clear DragStart

		drag.cancelDrag();

		var hasCancelEvent = false;
		for (e in events) {
			switch e {
				case DragCancel: hasCancelEvent = true;
				default:
			}
		}
		Assert.isTrue(hasCancelEvent);
	}

	@Test
	public function testCancelDragNoopWhenIdle():Void {
		var content = createContentObject("content");
		var drag = new UIMultiAnimDraggable(content);

		// Should not throw when not dragging
		drag.cancelDrag();
		@:privateAccess Assert.isTrue(drag.state == Idle);
	}

	@Test
	public function testCancelDragRestoresOrigin():Void {
		var content = createContentObject("content");
		var drag = new UIMultiAnimDraggable(content);
		var control = new bh.test.UITestHarness.MockControllable();

		drag.getObject().setPosition(100, 200);
		bh.test.UITestHarness.simulatePush(drag, control, new h2d.col.Point(100, 200));

		// Move the root to simulate drag motion
		drag.getObject().setPosition(300, 400);

		drag.cancelDrag();

		// Should return to origin
		Assert.floatEquals(100.0, drag.getObject().x);
		Assert.floatEquals(200.0, drag.getObject().y);
	}

	// ============== enabled setter: cancel drag on disable ==============

	@Test
	public function testSetEnabledFalseCancelsDrag():Void {
		var content = createContentObject("content");
		var drag = new UIMultiAnimDraggable(content);
		var control = new bh.test.UITestHarness.MockControllable();

		bh.test.UITestHarness.simulatePush(drag, control, new h2d.col.Point(10, 10));
		@:privateAccess Assert.isTrue(drag.state == Dragging);

		drag.enabled = false;

		@:privateAccess Assert.isTrue(drag.state == Idle);
		var mockCapture:bh.test.UITestHarness.MockCaptureEvents = cast control.captureEvents;
		Assert.isFalse(mockCapture.capturing);
	}

	@Test
	public function testSetEnabledFalseWhenIdleDoesNotThrow():Void {
		var content = createContentObject("content");
		var drag = new UIMultiAnimDraggable(content);

		drag.enabled = false;
		Assert.isFalse(drag.enabled);
		drag.enabled = true;
		Assert.isTrue(drag.enabled);
	}

	// ============== Zero-distance animation with visual flags ==============

	@Test
	public function testZeroDistanceSkipsWithoutVisualFlags():Void {
		var content = createContentObject("content");
		var drag = new UIMultiAnimDraggable(content);
		var completed = false;
		var factory:AnimatedPathFactory = (from, to) -> {
			var sp = new bh.paths.MultiAnimPaths.SinglePath(from, to, Line);
			var path = new bh.paths.MultiAnimPaths.Path([sp]);
			return new bh.paths.AnimatedPath(path, Time(1.0));
		};

		// Zero distance, no visual flags → should skip animation and complete immediately
		@:privateAccess drag.startAnimation(100, 100, 100, 100, factory, () -> completed = true);
		Assert.isTrue(completed);
		@:privateAccess Assert.isTrue(drag.state == Idle);
	}

	@Test
	public function testZeroDistanceAnimatesWithScaleFlag():Void {
		var content = createContentObject("content");
		var drag = new UIMultiAnimDraggable(content);
		drag.animApplyScale = true;
		var completed = false;

		// Need a real path with non-zero length for AnimatedPath
		var from = new bh.base.FPoint(100, 100);
		var to = new bh.base.FPoint(100, 100);
		var factory:AnimatedPathFactory = (f, t) -> {
			// Create a short path so AnimatedPath doesn't throw for zero length
			var sp = new bh.paths.MultiAnimPaths.SinglePath(new bh.base.FPoint(0, 0), new bh.base.FPoint(10, 0), Line);
			var path = new bh.paths.MultiAnimPaths.Path([sp]);
			return new bh.paths.AnimatedPath(path, Time(1.0));
		};

		// Zero distance but animApplyScale=true → should NOT skip, should start animating
		@:privateAccess drag.startAnimation(100, 100, 100, 100, factory, () -> completed = true);
		Assert.isFalse(completed);
		@:privateAccess Assert.isTrue(drag.state == Animating);
	}

	@Test
	public function testZeroDistanceAnimatesWithAlphaFlag():Void {
		var content = createContentObject("content");
		var drag = new UIMultiAnimDraggable(content);
		drag.animApplyAlpha = true;
		var completed = false;
		var factory:AnimatedPathFactory = (f, t) -> {
			var sp = new bh.paths.MultiAnimPaths.SinglePath(new bh.base.FPoint(0, 0), new bh.base.FPoint(10, 0), Line);
			var path = new bh.paths.MultiAnimPaths.Path([sp]);
			return new bh.paths.AnimatedPath(path, Time(1.0));
		};

		@:privateAccess drag.startAnimation(100, 100, 100, 100, factory, () -> completed = true);
		Assert.isFalse(completed);
		@:privateAccess Assert.isTrue(drag.state == Animating);
	}

	@Test
	public function testZeroDistanceAnimatesWithRotationFlag():Void {
		var content = createContentObject("content");
		var drag = new UIMultiAnimDraggable(content);
		drag.animApplyRotation = true;
		var completed = false;
		var factory:AnimatedPathFactory = (f, t) -> {
			var sp = new bh.paths.MultiAnimPaths.SinglePath(new bh.base.FPoint(0, 0), new bh.base.FPoint(10, 0), Line);
			var path = new bh.paths.MultiAnimPaths.Path([sp]);
			return new bh.paths.AnimatedPath(path, Time(1.0));
		};

		@:privateAccess drag.startAnimation(100, 100, 100, 100, factory, () -> completed = true);
		Assert.isFalse(completed);
		@:privateAccess Assert.isTrue(drag.state == Animating);
	}

	// ============== swapMode validation ==============

	@Test
	public function testSwapModeThrowsWithoutSourceSlot():Void {
		var content = createContentObject("content");
		var drag = new UIMultiAnimDraggable(content);

		// swapMode=true without sourceSlot should throw
		Assert.exception(() -> {
			drag.swapMode = true;
		}, String, e -> e == "swapMode requires sourceSlot (use createFromSlot)");
	}

	@Test
	public function testSwapModeAllowedWithSourceSlot():Void {
		var sourceSlot = createSlot();
		var contentA = createContentObject("A");
		sourceSlot.setContent(contentA);
		sourceSlot.data = "dataA";

		var drag = UIMultiAnimDraggable.createFromSlot(sourceSlot);
		Assert.notNull(drag);

		// swapMode=true with sourceSlot should succeed
		drag.swapMode = true;
		Assert.isTrue(drag.swapMode);
	}

	@Test
	public function testSwapModeFalseAlwaysAllowed():Void {
		var content = createContentObject("content");
		var drag = new UIMultiAnimDraggable(content);

		// swapMode=false should always work, even without sourceSlot
		drag.swapMode = false;
		Assert.isFalse(drag.swapMode);
	}

	// ============== Bug 1.5: TargetCard dead code (verified via grep, tested in types) ==============

	@Test
	public function testTargetingResultOnlyHasTargetZoneAndNoTarget():Void {
		// After removing TargetCard, only TargetZone and NoTarget should exist.
		// This test verifies the enum variants match expectations.
		var tz = bh.ui.UICardHandTypes.TargetingResult.TargetZone("z1");
		var nt = bh.ui.UICardHandTypes.TargetingResult.NoTarget;

		switch (tz) {
			case TargetZone(id): Assert.equals("z1", id);
			default: Assert.fail("Expected TargetZone");
		}
		switch (nt) {
			case NoTarget: Assert.isTrue(true);
			default: Assert.fail("Expected NoTarget");
		}
	}

	// ============== Drag lifecycle: push → move → release ==============

	@Test
	public function testDragStartSetsStateToDragging():Void {
		var drag = createDraggable();
		var ctx = startDrag(drag);
		@:privateAccess Assert.isTrue(drag.state == Dragging);
		Assert.isTrue(drag.isCurrentlyDragging());
		Assert.isFalse(drag.isAnimating());
	}

	@Test
	public function testDragStartFiresDragStartEvent():Void {
		var drag = createDraggable();
		var events:Array<DragEvent> = [];
		drag.onDragEvent = (e, _, _) -> events.push(e);

		startDrag(drag);

		var hasDragStart = false;
		for (e in events) {
			switch e {
				case DragStart: hasDragStart = true;
				default:
			}
		}
		Assert.isTrue(hasDragStart);
	}

	@Test
	public function testDragStartCapturesEvents():Void {
		var drag = createDraggable();
		var ctx = startDrag(drag);
		var mockCapture:bh.test.UITestHarness.MockCaptureEvents = cast ctx.control.captureEvents;
		Assert.isTrue(mockCapture.capturing);
	}

	@Test
	public function testDragMoveUpdatesPosition():Void {
		var drag = createDraggable();
		drag.getObject().setPosition(50, 50);
		var ctx = startDrag(drag, new Point(50, 50));

		// Move mouse to (150, 150) — offset is (50-50, 50-50) = (0,0), so root goes to (150,150)
		simulateMove(drag, ctx.control, new Point(150, 150));

		Assert.floatEquals(150.0, drag.getObject().x);
		Assert.floatEquals(150.0, drag.getObject().y);
	}

	@Test
	public function testDragMoveFiresDragMoveEvent():Void {
		var drag = createDraggable();
		var events:Array<DragEvent> = [];
		drag.onDragEvent = (e, _, _) -> events.push(e);
		var ctx = startDrag(drag);
		events.resize(0); // clear DragStart

		simulateMove(drag, ctx.control, new Point(100, 100));

		var hasDragMove = false;
		for (e in events) {
			switch e {
				case DragMove: hasDragMove = true;
				default:
			}
		}
		Assert.isTrue(hasDragMove);
	}

	@Test
	public function testReleaseOutsideZoneFiresDragCancel():Void {
		var drag = createDraggable();
		var events:Array<DragEvent> = [];
		drag.onDragEvent = (e, _, _) -> events.push(e);
		var ctx = startDrag(drag);
		events.resize(0);

		simulateRelease(drag, ctx.control, new Point(100, 100));

		var hasDragCancel = false;
		for (e in events) {
			switch e {
				case DragCancel: hasDragCancel = true;
				default:
			}
		}
		Assert.isTrue(hasDragCancel);
	}

	@Test
	public function testReleaseOutsideZoneReturnsToOrigin():Void {
		var drag = createDraggable();
		drag.getObject().setPosition(50, 60);
		var ctx = startDrag(drag, new Point(50, 60));

		// Move away
		simulateMove(drag, ctx.control, new Point(200, 200));

		// Release outside any zone — no return path factory, so instant return
		simulateRelease(drag, ctx.control, new Point(200, 200));

		Assert.floatEquals(50.0, drag.getObject().x);
		Assert.floatEquals(60.0, drag.getObject().y);
		@:privateAccess Assert.isTrue(drag.state == Idle);
	}

	@Test
	public function testReleaseOnValidZoneFiresDragEnd():Void {
		var drag = createDraggable();
		drag.addDropZone({
			id: Named("zone1"),
			bounds: createBoundsAt(80, 80, 50, 50),
			snapX: 100.0,
			snapY: 100.0,
		});
		var events:Array<DragEvent> = [];
		drag.onDragEvent = (e, _, _) -> events.push(e);
		var ctx = startDrag(drag);
		events.resize(0);

		// Release inside zone (80..130, 80..130)
		simulateRelease(drag, ctx.control, new Point(100, 100));

		var hasDragEnd = false;
		for (e in events) {
			switch e {
				case DragEnd: hasDragEnd = true;
				default:
			}
		}
		Assert.isTrue(hasDragEnd);
	}

	@Test
	public function testReleaseStopsCapture():Void {
		var drag = createDraggable();
		var ctx = startDrag(drag);
		var mockCapture:bh.test.UITestHarness.MockCaptureEvents = cast ctx.control.captureEvents;
		Assert.isTrue(mockCapture.capturing);

		simulateRelease(drag, ctx.control, new Point(10, 10));
		Assert.isFalse(mockCapture.capturing);
	}

	// ============== Drop zone management ==============

	@Test
	public function testAddDropZoneIncreasesCount():Void {
		var drag = createDraggable();
		Assert.equals(0, drag.dropZones.length);

		drag.addDropZone({id: Named("z1"), bounds: createBoundsAt(0, 0, 50, 50)});
		Assert.equals(1, drag.dropZones.length);

		drag.addDropZone({id: Named("z2"), bounds: createBoundsAt(100, 0, 50, 50)});
		Assert.equals(2, drag.dropZones.length);
	}

	@Test
	public function testRemoveDropZoneByIdRemovesCorrectZone():Void {
		var drag = createDraggable();
		drag.addDropZone({id: Named("z1"), bounds: createBoundsAt(0, 0, 50, 50)});
		drag.addDropZone({id: Named("z2"), bounds: createBoundsAt(100, 0, 50, 50)});
		Assert.equals(2, drag.dropZones.length);

		drag.removeDropZone(Named("z1"));
		Assert.equals(1, drag.dropZones.length);

		// Remaining zone should be z2
		switch drag.dropZones[0].id {
			case Named(name): Assert.equals("z2", name);
			default: Assert.fail("Expected Named zone");
		}
	}

	@Test
	public function testClearDropZonesRemovesAll():Void {
		var drag = createDraggable();
		drag.addDropZone({id: Named("z1"), bounds: createBoundsAt(0, 0, 50, 50)});
		drag.addDropZone({id: Named("z2"), bounds: createBoundsAt(100, 0, 50, 50)});
		Assert.equals(2, drag.dropZones.length);

		drag.clearDropZones();
		Assert.equals(0, drag.dropZones.length);
	}

	@Test
	public function testDropZonePriorityHigherWins():Void {
		var drag = createDraggable();
		// Two overlapping zones at same position, different priorities
		drag.addDropZone({id: Named("low"), bounds: createBoundsAt(0, 0, 100, 100), priority: 1});
		drag.addDropZone({id: Named("high"), bounds: createBoundsAt(0, 0, 100, 100), priority: 10});

		var ctx = startDrag(drag, new Point(5, 5));
		var droppedZoneName:String = null;
		drag.onDragEvent = (e, _, _) -> {
			switch e {
				case DragEnd: // dropped
				default:
			}
		};

		// Use findDropZone via release
		var dropResult:String = null;
		drag.onDragDrop = (result, _) -> {
			switch result.zone.id {
				case Named(name): dropResult = name;
				default:
			}
			return true;
		};

		simulateRelease(drag, ctx.control, new Point(50, 50));
		Assert.equals("high", dropResult);
	}

	@Test
	public function testDropZoneSamePriorityLaterIndexWins():Void {
		var drag = createDraggable();
		// Two overlapping zones, same priority — later index wins
		drag.addDropZone({id: Named("first"), bounds: createBoundsAt(0, 0, 100, 100), priority: 0});
		drag.addDropZone({id: Named("second"), bounds: createBoundsAt(0, 0, 100, 100), priority: 0});

		var ctx = startDrag(drag, new Point(5, 5));
		var dropResult:String = null;
		drag.onDragDrop = (result, _) -> {
			switch result.zone.id {
				case Named(name): dropResult = name;
				default:
			}
			return true;
		};

		simulateRelease(drag, ctx.control, new Point(50, 50));
		Assert.equals("second", dropResult);
	}

	@Test
	public function testDropZoneAcceptsFilterRejects():Void {
		var drag = createDraggable();
		drag.addDropZone({
			id: Named("rejected"),
			bounds: createBoundsAt(0, 0, 100, 100),
			accepts: (_, _) -> false,
		});

		var ctx = startDrag(drag, new Point(5, 5));
		var events:Array<DragEvent> = [];
		drag.onDragEvent = (e, _, _) -> events.push(e);

		// Release inside zone that rejects — should be DragCancel, not DragEnd
		simulateRelease(drag, ctx.control, new Point(50, 50));

		var hasDragEnd = false;
		var hasDragCancel = false;
		for (e in events) {
			switch e {
				case DragEnd: hasDragEnd = true;
				case DragCancel: hasDragCancel = true;
				default:
			}
		}
		Assert.isFalse(hasDragEnd);
		Assert.isTrue(hasDragCancel);
	}

	@Test
	public function testDropZoneSnapPosition():Void {
		var drag = createDraggable();
		drag.addDropZone({
			id: Named("snap"),
			bounds: createBoundsAt(80, 80, 50, 50),
			snapX: 100.0,
			snapY: 110.0,
		});

		var ctx = startDrag(drag, new Point(5, 5));

		// Release inside zone — should snap to (100, 110) instantly (no snap factory)
		simulateRelease(drag, ctx.control, new Point(100, 100));

		Assert.floatEquals(100.0, drag.getObject().x);
		Assert.floatEquals(110.0, drag.getObject().y);
	}

	// ============== Zone hover tracking ==============

	@Test
	public function testZoneEnterAndLeaveEventsDuringDrag():Void {
		var drag = createDraggable();
		drag.addDropZone({id: Named("z1"), bounds: createBoundsAt(80, 80, 50, 50)});
		var events:Array<DragEvent> = [];
		drag.onDragEvent = (e, _, _) -> events.push(e);
		var ctx = startDrag(drag, new Point(5, 5));
		events.resize(0);

		// Move into zone
		simulateMove(drag, ctx.control, new Point(100, 100));

		var hasZoneEnter = false;
		for (e in events) {
			switch e {
				case ZoneEnter(_): hasZoneEnter = true;
				default:
			}
		}
		Assert.isTrue(hasZoneEnter);
		events.resize(0);

		// Move out of zone
		simulateMove(drag, ctx.control, new Point(0, 0));

		var hasZoneLeave = false;
		for (e in events) {
			switch e {
				case ZoneLeave(_): hasZoneLeave = true;
				default:
			}
		}
		Assert.isTrue(hasZoneLeave);
	}

	@Test
	public function testOnZoneHighlightCallbackFired():Void {
		var drag = createDraggable();
		var highlightCalls:Array<Bool> = [];
		drag.addDropZone({
			id: Named("z1"),
			bounds: createBoundsAt(80, 80, 50, 50),
			onZoneHighlight: (_, highlight) -> highlightCalls.push(highlight),
		});
		var ctx = startDrag(drag, new Point(5, 5));

		// Move into zone → highlight true
		simulateMove(drag, ctx.control, new Point(100, 100));
		Assert.equals(1, highlightCalls.length);
		Assert.isTrue(highlightCalls[0]);

		// Move out → highlight false
		simulateMove(drag, ctx.control, new Point(0, 0));
		Assert.equals(2, highlightCalls.length);
		Assert.isFalse(highlightCalls[1]);
	}

	@Test
	public function testZoneRejectEnterAndLeaveEvents():Void {
		var drag = createDraggable();
		drag.addDropZone({
			id: Named("rejected"),
			bounds: createBoundsAt(80, 80, 50, 50),
			accepts: (_, _) -> false,
		});
		var events:Array<DragEvent> = [];
		drag.onDragEvent = (e, _, _) -> events.push(e);
		var ctx = startDrag(drag, new Point(5, 5));
		events.resize(0);

		// Move into rejected zone
		simulateMove(drag, ctx.control, new Point(100, 100));

		var hasRejectEnter = false;
		for (e in events) {
			switch e {
				case ZoneRejectEnter(_): hasRejectEnter = true;
				default:
			}
		}
		Assert.isTrue(hasRejectEnter);
		events.resize(0);

		// Move out
		simulateMove(drag, ctx.control, new Point(0, 0));

		var hasRejectLeave = false;
		for (e in events) {
			switch e {
				case ZoneRejectLeave(_): hasRejectLeave = true;
				default:
			}
		}
		Assert.isTrue(hasRejectLeave);
	}

	@Test
	public function testOnZoneRejectCallbackFired():Void {
		var drag = createDraggable();
		var rejectCalls:Array<Bool> = [];
		drag.addDropZone({
			id: Named("rejected"),
			bounds: createBoundsAt(80, 80, 50, 50),
			accepts: (_, _) -> false,
			onZoneReject: (_, reject) -> rejectCalls.push(reject),
		});
		var ctx = startDrag(drag, new Point(5, 5));

		// Move into rejected zone
		simulateMove(drag, ctx.control, new Point(100, 100));
		Assert.equals(1, rejectCalls.length);
		Assert.isTrue(rejectCalls[0]);

		// Move out
		simulateMove(drag, ctx.control, new Point(0, 0));
		Assert.equals(2, rejectCalls.length);
		Assert.isFalse(rejectCalls[1]);
	}

	@Test
	public function testAcceptedZoneTakesPrecedenceOverRejected():Void {
		var drag = createDraggable();
		// Overlapping zones: one accepts, one rejects
		drag.addDropZone({id: Named("rejected"), bounds: createBoundsAt(80, 80, 50, 50), accepts: (_, _) -> false});
		drag.addDropZone({id: Named("accepted"), bounds: createBoundsAt(80, 80, 50, 50), accepts: (_, _) -> true});
		var events:Array<DragEvent> = [];
		drag.onDragEvent = (e, _, _) -> events.push(e);
		var ctx = startDrag(drag, new Point(5, 5));
		events.resize(0);

		// Move into overlapping area — accepted should win, no reject events
		simulateMove(drag, ctx.control, new Point(100, 100));

		var hasZoneEnter = false;
		var hasRejectEnter = false;
		for (e in events) {
			switch e {
				case ZoneEnter(_): hasZoneEnter = true;
				case ZoneRejectEnter(_): hasRejectEnter = true;
				default:
			}
		}
		Assert.isTrue(hasZoneEnter);
		Assert.isFalse(hasRejectEnter);
	}

	// ============== Swap on drop ==============

	@Test
	public function testSwapOnDropExchangesSlotContents():Void {
		var sourceSlot = createSlot();
		var targetSlot = createSlot();

		var contentA = createContentObject("A");
		var contentB = createContentObject("B");
		sourceSlot.setContent(contentA);
		sourceSlot.data = "dataA";
		targetSlot.setContent(contentB);
		targetSlot.data = "dataB";

		var drag = UIMultiAnimDraggable.createFromSlot(sourceSlot);
		Assert.notNull(drag);
		drag.swapMode = true;

		// Add target slot as drop zone
		drag.addDropZone({
			id: Named("target"),
			bounds: createBoundsAt(80, 80, 50, 50),
			slot: targetSlot,
			snapX: 100.0,
			snapY: 100.0,
		});

		var ctx = startDrag(drag, new Point(5, 5));
		simulateRelease(drag, ctx.control, new Point(100, 100));

		// After swap: target slot has A (with dataA), source slot has B (with dataB)
		Assert.equals("B", sourceSlot.getContent().name);
		Assert.equals("dataB", sourceSlot.data);
		Assert.equals("A", targetSlot.getContent().name);
		Assert.equals("dataA", targetSlot.data);
	}

	@Test
	public function testCancelDragRestoresSourceSlot():Void {
		var sourceSlot = createSlot();
		var contentA = createContentObject("A");
		sourceSlot.setContent(contentA);
		sourceSlot.data = "dataA";

		var drag = UIMultiAnimDraggable.createFromSlot(sourceSlot);
		Assert.notNull(drag);

		// Source slot should be cleared after createFromSlot
		Assert.isTrue(sourceSlot.isEmpty());

		var ctx = startDrag(drag, new Point(5, 5));
		drag.cancelDrag();

		// Source slot should be restored with original content and data
		Assert.isTrue(sourceSlot.isOccupied());
		Assert.equals("A", sourceSlot.getContent().name);
		Assert.equals("dataA", sourceSlot.data);
	}

	@Test
	public function testFailedDropRestoresSourceSlot():Void {
		var sourceSlot = createSlot();
		var contentA = createContentObject("A");
		sourceSlot.setContent(contentA);
		sourceSlot.data = "dataA";

		var drag = UIMultiAnimDraggable.createFromSlot(sourceSlot);
		Assert.notNull(drag);

		// No drop zones — release will fail
		var ctx = startDrag(drag, new Point(5, 5));
		simulateRelease(drag, ctx.control, new Point(100, 100));

		// Should return to source slot (no return path factory = instant)
		Assert.isTrue(sourceSlot.isOccupied());
		Assert.equals("A", sourceSlot.getContent().name);
		Assert.equals("dataA", sourceSlot.data);
	}

	// ============== Delegate veto tests ==============

	@Test
	public function testOnDragStartVetoPrevents():Void {
		var drag = createDraggable();
		drag.onDragStart = (_, _) -> false; // always veto

		var ctx = startDrag(drag);

		// Should NOT be dragging — veto prevented it
		@:privateAccess Assert.isTrue(drag.state == Idle);
		Assert.isFalse(drag.isCurrentlyDragging());
	}

	@Test
	public function testOnDragStartAllowsWhenTrue():Void {
		var drag = createDraggable();
		drag.onDragStart = (_, _) -> true;

		var ctx = startDrag(drag);
		@:privateAccess Assert.isTrue(drag.state == Dragging);
	}

	@Test
	public function testOnDragDropVetoCausesDragCancel():Void {
		var drag = createDraggable();
		drag.addDropZone({id: Named("z1"), bounds: createBoundsAt(80, 80, 50, 50)});
		drag.onDragDrop = (_, _) -> false; // veto the drop

		var events:Array<DragEvent> = [];
		drag.onDragEvent = (e, _, _) -> events.push(e);
		var ctx = startDrag(drag, new Point(5, 5));
		events.resize(0);

		// Release inside valid zone but onDragDrop vetoes
		simulateRelease(drag, ctx.control, new Point(100, 100));

		var hasDragEnd = false;
		var hasDragCancel = false;
		for (e in events) {
			switch e {
				case DragEnd: hasDragEnd = true;
				case DragCancel: hasDragCancel = true;
				default:
			}
		}
		Assert.isFalse(hasDragEnd);
		Assert.isTrue(hasDragCancel);
	}

	@Test
	public function testOnDragCancelCallbackFired():Void {
		var drag = createDraggable();
		var cancelFired = false;
		drag.onDragCancel = (_, _) -> cancelFired = true;

		var ctx = startDrag(drag, new Point(5, 5));
		// Release outside any zone
		simulateRelease(drag, ctx.control, new Point(500, 500));

		Assert.isTrue(cancelFired);
	}

	// ============== Configuration: dragAlpha, constraint, returnToOrigin, multi-button ==============

	@Test
	public function testDragAlphaAppliedOnDragStart():Void {
		var content = createContentObject("content");
		content.alpha = 1.0;
		var drag = new UIMultiAnimDraggable(content);
		drag.dragAlpha = 0.4;

		startDrag(drag);
		Assert.floatEquals(0.4, content.alpha);
	}

	@Test
	public function testDragAlphaRestoredOnRelease():Void {
		var content = createContentObject("content");
		content.alpha = 0.8;
		var drag = new UIMultiAnimDraggable(content);
		drag.dragAlpha = 0.3;

		var ctx = startDrag(drag);
		simulateRelease(drag, ctx.control, new Point(10, 10));

		Assert.floatEquals(0.8, content.alpha);
	}

	@Test
	public function testZoneHighlightAlphaAppliedOnZoneEnter():Void {
		var content = createContentObject("content");
		content.alpha = 1.0;
		var drag = new UIMultiAnimDraggable(content);
		drag.dragAlpha = 0.5;
		drag.zoneHighlightAlpha = 0.9;
		drag.addDropZone({id: Named("z1"), bounds: createBoundsAt(80, 80, 50, 50)});

		var ctx = startDrag(drag, new Point(5, 5));
		Assert.floatEquals(0.5, content.alpha); // dragAlpha

		// Move into zone
		simulateMove(drag, ctx.control, new Point(100, 100));
		Assert.floatEquals(0.9, content.alpha); // zoneHighlightAlpha

		// Move out of zone
		simulateMove(drag, ctx.control, new Point(0, 0));
		Assert.floatEquals(0.5, content.alpha); // back to dragAlpha
	}

	@Test
	public function testDragConstraintApplied():Void {
		var drag = createDraggable();
		drag.getObject().setPosition(50, 50);
		// Constrain to horizontal movement only
		drag.dragConstraint = (pos) -> new Point(pos.x, 50);

		var ctx = startDrag(drag, new Point(50, 50));
		simulateMove(drag, ctx.control, new Point(200, 300));

		Assert.floatEquals(200.0, drag.getObject().x);
		Assert.floatEquals(50.0, drag.getObject().y); // constrained
	}

	@Test
	public function testReturnToOriginFalseStaysAtDropPosition():Void {
		var drag = createDraggable();
		drag.returnToOrigin = false;
		drag.getObject().setPosition(50, 50);

		var ctx = startDrag(drag, new Point(50, 50));
		simulateMove(drag, ctx.control, new Point(200, 200));
		simulateRelease(drag, ctx.control, new Point(200, 200));

		// Should stay near drop position (not return to 50,50)
		@:privateAccess Assert.isTrue(drag.state == Idle);
		// Position is updated by move, release doesn't change it (returnToOrigin=false)
		Assert.floatEquals(200.0, drag.getObject().x);
		Assert.floatEquals(200.0, drag.getObject().y);
	}

	@Test
	public function testNonConfiguredButtonIgnored():Void {
		var drag = createDraggable();
		drag.draggableButtons = [0]; // only left button

		var control = new bh.test.UITestHarness.MockControllable();
		// Push with right button (1)
		drag.onEvent(bh.test.UITestHarness.createEventWrapper(OnPush(1), control, new Point(10, 10)));

		@:privateAccess Assert.isTrue(drag.state == Idle);
		Assert.isFalse(drag.isCurrentlyDragging());
	}

	@Test
	public function testCustomButtonConfigured():Void {
		var drag = createDraggable();
		drag.draggableButtons = [2]; // middle button only

		var control = new bh.test.UITestHarness.MockControllable();
		// Push with middle button
		drag.onEvent(bh.test.UITestHarness.createEventWrapper(OnPush(2), control, new Point(10, 10)));

		@:privateAccess Assert.isTrue(drag.state == Dragging);
	}

	@Test
	public function testWrongButtonReleaseIgnored():Void {
		var drag = createDraggable();
		var ctx = startDrag(drag); // left button (0)
		@:privateAccess Assert.isTrue(drag.state == Dragging);

		// Release with right button (1) — should NOT end drag
		simulateRelease(drag, ctx.control, new Point(10, 10), 1);
		@:privateAccess Assert.isTrue(drag.state == Dragging); // still dragging
	}

	// ============== State queries and edge cases ==============

	@Test
	public function testGetStateReturnsCurrentState():Void {
		var drag = createDraggable();
		Assert.isTrue(drag.getState() == Idle);

		var ctx = startDrag(drag);
		Assert.isTrue(drag.getState() == Dragging);

		drag.cancelDrag();
		Assert.isTrue(drag.getState() == Idle);
	}

	@Test
	public function testGetOriginReturnsStartPosition():Void {
		var drag = createDraggable();
		drag.getObject().setPosition(42, 73);

		var ctx = startDrag(drag, new Point(42, 73));
		var origin = drag.getOrigin();

		Assert.floatEquals(42.0, origin.x);
		Assert.floatEquals(73.0, origin.y);
	}

	@Test
	public function testOnEventIgnoredWhenDisabled():Void {
		var drag = createDraggable();
		drag.enabled = false;

		var control = new bh.test.UITestHarness.MockControllable();
		bh.test.UITestHarness.simulatePush(drag, control, new Point(10, 10));

		@:privateAccess Assert.isTrue(drag.state == Idle);
	}

	@Test
	public function testOnEventIgnoredWhenAnimating():Void {
		var drag = createDraggable();
		// Force into Animating state via startAnimation
		var factory:AnimatedPathFactory = (f, t) -> {
			var sp = new bh.paths.MultiAnimPaths.SinglePath(new bh.base.FPoint(0, 0), new bh.base.FPoint(10, 0), Line);
			var path = new bh.paths.MultiAnimPaths.Path([sp]);
			return new bh.paths.AnimatedPath(path, Time(1.0));
		};
		@:privateAccess drag.startAnimation(0, 0, 100, 100, factory, () -> {});
		@:privateAccess Assert.isTrue(drag.state == Animating);

		// Try to start a drag — should be ignored
		var control = new bh.test.UITestHarness.MockControllable();
		bh.test.UITestHarness.simulatePush(drag, control, new Point(10, 10));

		@:privateAccess Assert.isTrue(drag.state == Animating); // still animating
	}

	@Test
	public function testCreateFromSlotReturnsNullForEmptySlot():Void {
		var slot = createSlot();
		var drag = UIMultiAnimDraggable.createFromSlot(slot);
		Assert.isNull(drag);
	}

	@Test
	public function testCreateFromSlotClearsSourceSlot():Void {
		var slot = createSlot();
		slot.setContent(createContentObject("A"));
		slot.data = "test";

		var drag = UIMultiAnimDraggable.createFromSlot(slot);
		Assert.notNull(drag);
		Assert.isTrue(slot.isEmpty());
	}

	@Test
	public function testCreateStaticFactoryMethod():Void {
		var content = createContentObject("content");
		var drag = UIMultiAnimDraggable.create(content);
		Assert.notNull(drag);
		Assert.equals(content, drag.getTarget());
	}

	@Test
	public function testUpdateNoopWhenNotAnimating():Void {
		var drag = createDraggable();
		// Should not throw or change state
		drag.update(0.016);
		@:privateAccess Assert.isTrue(drag.state == Idle);
	}

	@Test
	public function testAnimationNullFactoryCompletesInstantly():Void {
		var drag = createDraggable();
		var completed = false;
		@:privateAccess drag.startAnimation(0, 0, 100, 100, null, () -> completed = true);
		Assert.isTrue(completed);
		@:privateAccess Assert.isTrue(drag.state == Idle);
	}

	@Test
	public function testPayloadField():Void {
		var drag = createDraggable();
		Assert.isNull(drag.payload);
		drag.payload = {type: "weapon", damage: 10};
		Assert.notNull(drag.payload);
		Assert.equals("weapon", drag.payload.type);
	}

	// ============== Highlight zone callbacks ==============

	@Test
	public function testOnDragStartHighlightZonesCalled():Void {
		var drag = createDraggable();
		drag.addDropZone({id: Named("valid"), bounds: createBoundsAt(0, 0, 50, 50)});
		drag.addDropZone({id: Named("rejected"), bounds: createBoundsAt(100, 0, 50, 50), accepts: (_, _) -> false});

		var validZones:Array<DropZone> = null;
		var rejectedZones:Array<DropZone> = null;
		drag.onDragStartHighlightZones = (zones) -> validZones = zones;
		drag.onDragStartRejectZones = (zones) -> rejectedZones = zones;

		startDrag(drag, new Point(5, 5));

		Assert.notNull(validZones);
		Assert.equals(1, validZones.length);
		Assert.notNull(rejectedZones);
		Assert.equals(1, rejectedZones.length);
	}

	@Test
	public function testOnDragEndHighlightZonesCalledOnRelease():Void {
		var drag = createDraggable();
		drag.addDropZone({id: Named("z1"), bounds: createBoundsAt(0, 0, 50, 50)});

		var endCalled = false;
		drag.onDragEndHighlightZones = (_) -> endCalled = true;

		var ctx = startDrag(drag, new Point(5, 5));
		simulateRelease(drag, ctx.control, new Point(200, 200));
		Assert.isTrue(endCalled);
	}

	@Test
	public function testOnDragEndHighlightZonesCalledOnCancel():Void {
		var drag = createDraggable();
		drag.addDropZone({id: Named("z1"), bounds: createBoundsAt(0, 0, 50, 50)});

		var endCalled = false;
		drag.onDragEndHighlightZones = (_) -> endCalled = true;

		var ctx = startDrag(drag, new Point(5, 5));
		drag.cancelDrag();
		Assert.isTrue(endCalled);
	}

	// ============== DropZoneIdTools.format ==============

	@Test
	public function testDropZoneIdFormatNamed():Void {
		Assert.equals("myZone", DropZoneIdTools.format(Named("myZone")));
	}

	@Test
	public function testDropZoneIdFormatSlotZone():Void {
		Assert.equals("items_3", DropZoneIdTools.format(SlotZone("items", 3)));
	}

	@Test
	public function testDropZoneIdFormatSlotZoneNoIndex():Void {
		Assert.equals("items", DropZoneIdTools.format(SlotZone("items")));
	}

	@Test
	public function testDropZoneIdFormatSlotZone2D():Void {
		Assert.equals("grid_2_5", DropZoneIdTools.format(SlotZone2D("grid", 2, 5)));
	}

	@Test
	public function testDropZoneIdFormatGridCell():Void {
		Assert.equals("grid(1,2)", DropZoneIdTools.format(GridCell(null, 1, 2)));
	}

	// ============== Animation update lifecycle ==============

	@Test
	public function testAnimationUpdateAdvancesAndCompletes():Void {
		var drag = createDraggable();
		var completed = false;
		var factory:AnimatedPathFactory = (f, t) -> {
			var sp = new bh.paths.MultiAnimPaths.SinglePath(f, t, Line);
			var path = new bh.paths.MultiAnimPaths.Path([sp]);
			return new bh.paths.AnimatedPath(path, Time(0.1)); // 0.1s duration
		};

		@:privateAccess drag.startAnimation(0, 0, 100, 0, factory, () -> completed = true);
		@:privateAccess Assert.isTrue(drag.state == Animating);
		Assert.isFalse(completed);

		// Advance past duration
		drag.update(0.2);
		Assert.isTrue(completed);
		@:privateAccess Assert.isTrue(drag.state == Idle);
	}

	@Test
	public function testClearDuringDragRestoresAlpha():Void {
		var content = createContentObject("content");
		content.alpha = 0.7;
		var drag = new UIMultiAnimDraggable(content);
		drag.dragAlpha = 0.3;

		var ctx = startDrag(drag);
		Assert.floatEquals(0.3, content.alpha);

		// clear() during drag should restore alpha
		drag.clear();
		Assert.floatEquals(0.7, content.alpha);
	}

	@Test
	public function testClearDuringDragStopsCapture():Void {
		var drag = createDraggable();
		var ctx = startDrag(drag);
		var mockCapture:bh.test.UITestHarness.MockCaptureEvents = cast ctx.control.captureEvents;
		Assert.isTrue(mockCapture.capturing);

		drag.clear();
		Assert.isFalse(mockCapture.capturing);
	}

	@Test
	public function testDragStartPushesCustomEvent():Void {
		var drag = createDraggable();
		var control = new bh.test.UITestHarness.MockControllable();
		bh.test.UITestHarness.simulatePush(drag, control, new Point(10, 10));

		Assert.isTrue(control.hasEvent(UICustomEvent("dragStart", null)));
	}

	@Test
	public function testChainedDropZoneAddition():Void {
		var drag = createDraggable();
		// addDropZone returns this for chaining
		var result = drag.addDropZone({id: Named("z1"), bounds: createBoundsAt(0, 0, 50, 50)});
		Assert.equals(drag, result);
	}

	@Test
	public function testRemoveDropZoneUsesEnumEq():Void {
		var drag = createDraggable();
		drag.addDropZone({id: SlotZone("items", 3), bounds: createBoundsAt(0, 0, 50, 50)});
		Assert.equals(1, drag.dropZones.length);

		// Remove by constructing a new enum value with same params — should match via enumEq
		drag.removeDropZone(SlotZone("items", 3));
		Assert.equals(0, drag.dropZones.length);
	}
}
