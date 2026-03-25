package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.ui.UIMultiAnimDraggable;
import bh.ui.UIMultiAnimDraggable.DragEvent;
import bh.ui.UIMultiAnimDraggable.DraggableState;
import bh.ui.UIMultiAnimDraggable.AnimatedPathFactory;
import bh.multianim.MultiAnimBuilder.SlotHandle;
import bh.paths.AnimatedPath.AnimatedPathMode;
import bh.paths.MultiAnimPaths.PathType;
import h2d.col.Bounds;

/**
 * Unit tests for UIMultiAnimDraggable.
 * Tests swap mode sourceSlot validation, clear() cleanup, and TargetCard dead code.
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
}
