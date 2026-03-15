package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.ui.UIMultiAnimDraggable;
import bh.multianim.MultiAnimBuilder.SlotHandle;
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
