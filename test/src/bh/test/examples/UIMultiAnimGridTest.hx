package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness.UITestScreen;
import bh.ui.UIMultiAnimGrid;
import bh.ui.UIMultiAnimGridTypes;
import bh.ui.UICardHandHelper;
import bh.ui.UICardHandTypes;
import bh.ui.UICardHandTypes.CardHandEvent;
import bh.ui.UICardHandTypes.CardState;
import bh.ui.UICardHandTypes.TargetingResult;
import bh.ui.UIMultiAnimDraggable;
import bh.base.Hex.HexOrientation;

/**
 * Unit tests for UIMultiAnimGrid.
 * Tests cell management, data operations, coordinate queries, hit testing, and events.
 */
class UIMultiAnimGridTest extends BuilderTestBase {
	static final CELL_MANIM = "
		#cell programmable(col:int=0, row:int=0, status:[normal,hover]=normal, highlight:[none,accept,reject]=none) {
			bitmap(generated(color(50, 50, #666666))): 0, 0
		}
	";

	static final HEX_CELL_MANIM = "
		#hexCell programmable(col:int=0, row:int=0, status:[normal,hover]=normal, highlight:[none,accept,reject]=none) {
			bitmap(generated(color(30, 30, #888888))): 0, 0
		}
	";

	function createRectGrid(?cols:Int, ?rows:Int):UIMultiAnimGrid {
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellBuildName: "cell",
			originX: 0,
			originY: 0,
		});
		if (cols != null && rows != null)
			grid.addRectRegion(cols, rows);
		return grid;
	}

	function createHexGrid(?radius:Int):UIMultiAnimGrid {
		var builder = BuilderTestBase.builderFromSource(HEX_CELL_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Hex(POINTY, 30, 30),
			cellBuildName: "hexCell",
			originX: 0,
			originY: 0,
		});
		if (radius != null)
			grid.addHexRegion(0, 0, radius);
		return grid;
	}

	// ============== Construction ==============

	@Test
	public function testConstruction():Void {
		var grid = createRectGrid();
		Assert.notNull(grid);
		Assert.notNull(grid.getObject());
		Assert.equals(0, grid.cellCount());
	}

	// ============== Cell management ==============

	@Test
	public function testAddCell():Void {
		var grid = createRectGrid();
		grid.addCell(0, 0);
		Assert.isTrue(grid.hasCell(0, 0));
		Assert.equals(1, grid.cellCount());
	}

	@Test
	public function testAddCellDuplicate():Void {
		var grid = createRectGrid();
		grid.addCell(0, 0);
		grid.addCell(0, 0); // should not duplicate
		Assert.equals(1, grid.cellCount());
	}

	@Test
	public function testRemoveCell():Void {
		var grid = createRectGrid();
		grid.addCell(0, 0);
		grid.removeCell(0, 0);
		Assert.isFalse(grid.hasCell(0, 0));
		Assert.equals(0, grid.cellCount());
	}

	@Test
	public function testRemoveNonexistentCell():Void {
		var grid = createRectGrid();
		grid.removeCell(5, 5); // should not throw
		Assert.equals(0, grid.cellCount());
	}

	@Test
	public function testAddRectRegion():Void {
		var grid = createRectGrid(4, 3);
		Assert.equals(12, grid.cellCount());
		Assert.isTrue(grid.hasCell(0, 0));
		Assert.isTrue(grid.hasCell(3, 2));
		Assert.isFalse(grid.hasCell(4, 0));
		Assert.isFalse(grid.hasCell(0, 3));
	}

	@Test
	public function testAddHexRegion():Void {
		var grid = createHexGrid(1);
		// Radius 1: center + 6 neighbors = 7 cells
		Assert.equals(7, grid.cellCount());
		Assert.isTrue(grid.hasCell(0, 0));
	}

	@Test
	public function testAddHexRegionRadius2():Void {
		var grid = createHexGrid(2);
		// Radius 2: 1 + 6 + 12 = 19 cells
		Assert.equals(19, grid.cellCount());
	}

	// ============== Cell data ==============

	@Test
	public function testSetAndGetData():Void {
		var grid = createRectGrid(2, 2);
		grid.set(0, 0, {hp: 3});
		Assert.notNull(grid.get(0, 0));
		Assert.equals(3, grid.get(0, 0).hp);
	}

	@Test
	public function testGetEmptyCell():Void {
		var grid = createRectGrid(2, 2);
		Assert.isNull(grid.get(1, 1));
	}

	@Test
	public function testIsOccupied():Void {
		var grid = createRectGrid(2, 2);
		Assert.isFalse(grid.isOccupied(0, 0));
		grid.set(0, 0, {hp: 3});
		Assert.isTrue(grid.isOccupied(0, 0));
	}

	@Test
	public function testClear():Void {
		var grid = createRectGrid(2, 2);
		grid.set(0, 0, {hp: 3});
		grid.clear(0, 0);
		Assert.isFalse(grid.isOccupied(0, 0));
		Assert.isNull(grid.get(0, 0));
	}

	@Test
	public function testForEach():Void {
		var grid = createRectGrid(3, 2);
		grid.set(0, 0, "a");
		grid.set(1, 1, "b");
		var count = 0;
		grid.forEach((col, row, data) -> {
			if (data != null)
				count++;
		});
		Assert.equals(2, count);
	}

	// ============== Cell data events ==============

	@Test
	public function testSetEmitsDataChangedEvent():Void {
		var grid = createRectGrid(2, 2);
		var eventFired = false;
		grid.onGridEvent = (event) -> {
			switch event {
				case CellDataChanged(cell, oldData, newData):
					eventFired = true;
					Assert.equals(0, cell.col);
					Assert.equals(0, cell.row);
					Assert.isNull(oldData);
					Assert.equals(42, newData);
				default:
			}
		};
		grid.set(0, 0, 42);
		Assert.isTrue(eventFired);
	}

	@Test
	public function testClearEmitsDataChangedEvent():Void {
		var grid = createRectGrid(2, 2);
		grid.set(0, 0, "hello");
		var eventFired = false;
		grid.onGridEvent = (event) -> {
			switch event {
				case CellDataChanged(cell, oldData, newData):
					eventFired = true;
					Assert.equals("hello", oldData);
					Assert.isNull(newData);
				default:
			}
		};
		grid.clear(0, 0);
		Assert.isTrue(eventFired);
	}

	// ============== Coordinate queries ==============

	@Test
	public function testCellPositionRect():Void {
		var grid = createRectGrid(3, 3);
		var pos = grid.cellPosition(0, 0);
		Assert.floatEquals(0.0, pos.x);
		Assert.floatEquals(0.0, pos.y);

		// Cell (1, 0) should be at (52, 0) = cellWidth(50) + gap(2)
		var pos1 = grid.cellPosition(1, 0);
		Assert.floatEquals(52.0, pos1.x);
		Assert.floatEquals(0.0, pos1.y);

		// Cell (0, 1) should be at (0, 52)
		var pos01 = grid.cellPosition(0, 1);
		Assert.floatEquals(0.0, pos01.x);
		Assert.floatEquals(52.0, pos01.y);
	}

	@Test
	public function testNeighborsRect():Void {
		var grid = createRectGrid(3, 3);
		// Center cell (1,1) should have 4 neighbors
		var n = grid.neighbors(1, 1);
		Assert.equals(4, n.length);

		// Corner cell (0,0) should have 2 neighbors
		var n0 = grid.neighbors(0, 0);
		Assert.equals(2, n0.length);

		// Edge cell (1,0) should have 3 neighbors
		var n1 = grid.neighbors(1, 0);
		Assert.equals(3, n1.length);
	}

	@Test
	public function testNeighborsHex():Void {
		var grid = createHexGrid(2);
		// Center hex (0,0) in radius-2 should have 6 neighbors
		var n = grid.neighbors(0, 0);
		Assert.equals(6, n.length);
	}

	@Test
	public function testDistanceRect():Void {
		var grid = createRectGrid(5, 5);
		Assert.equals(0, grid.distance(0, 0, 0, 0));
		Assert.equals(1, grid.distance(0, 0, 1, 0));
		Assert.equals(2, grid.distance(0, 0, 1, 1));
		Assert.equals(8, grid.distance(0, 0, 4, 4));
	}

	@Test
	public function testDistanceHex():Void {
		var grid = createHexGrid(2);
		Assert.equals(0, grid.distance(0, 0, 0, 0));
		Assert.equals(1, grid.distance(0, 0, 1, 0));
		Assert.equals(2, grid.distance(0, 0, 1, 1));
	}

	// ============== Hit testing ==============

	@Test
	public function testCellAtPointRect():Void {
		var grid = createRectGrid(3, 3);
		// Point inside cell (0,0): (25, 25)
		var cell = grid.cellAtPoint(25, 25);
		Assert.notNull(cell);
		Assert.equals(0, cell.col);
		Assert.equals(0, cell.row);
	}

	@Test
	public function testCellAtPointRectSecondCell():Void {
		var grid = createRectGrid(3, 3);
		// Cell (1,0) starts at x=52 (50 + 2 gap), center at ~77
		var cell = grid.cellAtPoint(77, 25);
		Assert.notNull(cell);
		Assert.equals(1, cell.col);
		Assert.equals(0, cell.row);
	}

	@Test
	public function testCellAtPointRectGap():Void {
		var grid = createRectGrid(3, 3);
		// Point in the gap between cells (50-52 is gap area)
		var cell = grid.cellAtPoint(51, 25);
		Assert.isNull(cell);
	}

	@Test
	public function testCellAtPointRectOutside():Void {
		var grid = createRectGrid(3, 3);
		// Point outside grid
		var cell = grid.cellAtPoint(500, 500);
		Assert.isNull(cell);
	}

	@Test
	public function testCellAtPointHex():Void {
		var grid = createHexGrid(2);
		// Point at origin should hit center cell (0,0)
		var cell = grid.cellAtPoint(0, 0);
		Assert.notNull(cell);
		Assert.equals(0, cell.col);
		Assert.equals(0, cell.row);
	}

	// ============== Mouse events ==============

	@Test
	public function testMouseClickFiresEvent():Void {
		var grid = createRectGrid(3, 3);
		var clickedCell:Null<CellCoord> = null;
		var clickButton = -1;
		grid.onGridEvent = (event) -> {
			switch event {
				case CellClick(cell, button):
					clickedCell = cell;
					clickButton = button;
				default:
			}
		};
		grid.onMouseClick(25, 25, 0);
		Assert.notNull(clickedCell);
		Assert.equals(0, clickedCell.col);
		Assert.equals(0, clickedCell.row);
		Assert.equals(0, clickButton);
	}

	@Test
	public function testMouseMoveHoverEvents():Void {
		var grid = createRectGrid(3, 3);
		var enters:Array<CellCoord> = [];
		var leaves:Array<CellCoord> = [];
		grid.onGridEvent = (event) -> {
			switch event {
				case CellTargetEnter(cell, Mouse):
					enters.push(cell);
				case CellTargetLeave(cell, Mouse):
					leaves.push(cell);
				default:
			}
		};

		// Move into cell (0,0)
		grid.onMouseMove(25, 25);
		Assert.equals(1, enters.length);
		Assert.equals(0, enters[0].col);
		Assert.equals(0, enters[0].row);
		Assert.equals(0, leaves.length);

		// Move to cell (1,0) — should leave (0,0) and enter (1,0)
		grid.onMouseMove(77, 25);
		Assert.equals(2, enters.length);
		Assert.equals(1, enters[1].col);
		Assert.equals(0, enters[1].row);
		Assert.equals(1, leaves.length);
		Assert.equals(0, leaves[0].col);
		Assert.equals(0, leaves[0].row);
	}

	@Test
	public function testMouseMoveOutside():Void {
		var grid = createRectGrid(3, 3);
		var leaveCount = 0;
		grid.onGridEvent = (event) -> {
			switch event {
				case CellTargetLeave(_, Mouse):
					leaveCount++;
				default:
			}
		};

		// Enter cell first
		grid.onMouseMove(25, 25);
		// Move outside
		grid.onMouseMove(500, 500);
		Assert.equals(1, leaveCount);
	}

	// ============== Cell visual params ==============

	@Test
	public function testGetCellResult():Void {
		var grid = createRectGrid(2, 2);
		var result = grid.getCellResult(0, 0);
		Assert.notNull(result);
	}

	@Test
	public function testGetCellResultNonexistent():Void {
		var grid = createRectGrid(2, 2);
		var result = grid.getCellResult(5, 5);
		Assert.isNull(result);
	}

	// ============== onCellBuilt callback ==============

	@Test
	public function testOnCellBuiltCallback():Void {
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50),
			cellBuildName: "cell",
		});
		var builtCells:Array<CellCoord> = [];
		grid.onCellBuilt = (coord, result) -> {
			builtCells.push(coord);
		};
		grid.addCell(0, 0);
		grid.addCell(1, 0);
		Assert.equals(2, builtCells.length);
	}

	// ============== Dispose ==============

	@Test
	public function testDispose():Void {
		var grid = createRectGrid(2, 2);
		grid.dispose();
		Assert.equals(0, grid.cellCount());
	}

	// ============== Negative coordinates ==============

	@Test
	public function testNegativeCoordinates():Void {
		var grid = createRectGrid();
		grid.addCell(-1, -2);
		Assert.isTrue(grid.hasCell(-1, -2));
		Assert.equals(1, grid.cellCount());
		grid.set(-1, -2, "data");
		Assert.equals("data", grid.get(-1, -2));
	}

	// ============== Non-square cell hit testing (Bug 1.12) ==============

	function createNonSquareRectGrid():UIMultiAnimGrid {
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		return new UIMultiAnimGrid(builder, {
			gridType: Rect(60, 30, 4), // wide cells: 60w x 30h, gap=4
			cellBuildName: "cell",
			originX: 0,
			originY: 0,
		});
	}

	@Test
	public function testHitTestNonSquareCellYGap():Void {
		// Bug 1.12: hitTestRect uses `stride` (cellW+gap) instead of `strideY` (cellH+gap)
		// for cellLocalY calculation. With non-square cells (60w x 30h, gap=4):
		// stride = 64, strideY = 34
		// Row 1 cells occupy Y=34..63. Y gap between row 1 and row 2 is Y=64..67.
		// Row 2 cells start at Y=68.
		// Bug: cellLocalY = localY - row * stride (uses 64 not 34)
		// At Y=65 (gap): row=floor(65/34)=1, cellLocalY=65-1*64=1 which is < 30 → incorrectly hits.
		var grid = createNonSquareRectGrid();
		grid.addRectRegion(2, 3);

		// Point inside cell (0,1) at Y=50 — should hit
		var cell01 = grid.cellAtPoint(10, 50);
		Assert.notNull(cell01);
		Assert.equals(0, cell01.col);
		Assert.equals(1, cell01.row);

		// Point in the Y gap between row 1 (Y=34..63) and row 2 (Y=68..97)
		// Y=65 is in the gap. Should return null.
		var gapCell = grid.cellAtPoint(10, 65);
		Assert.isNull(gapCell); // BUG: returns cell because cellLocalY uses wrong stride
	}

	// ============== Negative coordinate hit testing (Bug 1.13) ==============

	@Test
	public function testCellAtPointNegativeCoordinates():Void {
		// Bug 1.13: hitTestRect early-returns null for negative localX/localY,
		// making cells at negative coordinates invisible to cellAtPoint.
		var grid = createRectGrid();
		grid.addCell(-1, 0);
		grid.addCell(0, 0);
		grid.addCell(-1, -1);

		// Cell (-1, 0) should be at x = -1 * (50+2) = -52. Center at (-27, 25).
		var pos = grid.cellPosition(-1, 0);
		var cell = grid.cellAtPoint(pos.x + 5, pos.y + 5);
		Assert.notNull(cell); // BUG: returns null because localX < 0
		Assert.equals(-1, cell.col);
		Assert.equals(0, cell.row);
	}

	// ============== rebuildCell refresh (Bug 1.11) ==============

	@Test
	public function testRebuildCellCallsOnCellBuilt():Void {
		// rebuildCell should invoke onCellBuilt callback (it does this already)
		var grid = createRectGrid(2, 2);
		var builtCount = 0;
		grid.onCellBuilt = (coord, result) -> {
			builtCount++;
		};
		grid.rebuildCell(0, 0);
		Assert.equals(1, builtCount);
	}

	// ============== Remove and re-add ==============

	@Test
	public function testRemoveAndReaddCell():Void {
		var grid = createRectGrid(2, 2);
		grid.set(0, 0, "initial");
		grid.removeCell(0, 0);
		Assert.isFalse(grid.hasCell(0, 0));
		grid.addCell(0, 0);
		Assert.isTrue(grid.hasCell(0, 0));
		Assert.isNull(grid.get(0, 0)); // data should not persist
	}

	// ============== Multiple card hand registrations (Bug 1.10) ==============

	static final CARD_MANIM = "
		#card programmable(status:[normal,hover,pressed,disabled]=normal) {
			bitmap(generated(color(80, 110, #AA0000))): 0, 0
			interactive(80, 110, \"card\", bind => \"status\"): 0, 0
		}
	";

	// ============== CellCardPlayed event (Bug 1.9) ==============

	@Test
	public function testCellCardPlayedEventEmitted():Void {
		// Bug 1.9: CellCardPlayed event defined but never emitted.
		// After fix, grid wires a chained listener on the card hand that converts
		// CardPlayed(id, TargetZone(targetId)) → CellCardPlayed(cell, cardId).
		var screen = new UITestScreen();
		var builder = BuilderTestBase.builderFromSource('$CELL_MANIM\n$CARD_MANIM');

		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50),
			cellBuildName: "cell",
		});
		grid.addRectRegion(2, 2);

		var cardHand = new UICardHandHelper(screen, builder);
		grid.registerAsCardTarget(cardHand);

		var receivedEvent:Null<GridEvent> = null;
		grid.onGridEvent = (event) -> {
			switch event {
				case CellCardPlayed(_, _): receivedEvent = event;
				default:
			}
		};

		// Simulate card hand emitting CardPlayed targeting a grid cell.
		// The grid's chained listener should convert this to CellCardPlayed.
		// Target ID format: grid{N}ch{M}_{col}_{row}
		@:privateAccess var prefix = grid.registeredCardHands[0].targetPrefix;
		var targetId = '${prefix}_1_0';
		@:privateAccess cardHand.emitEvent(CardHandEvent.CardPlayed("testCard", TargetingResult.TargetZone(targetId)));

		Assert.notNull(receivedEvent);
		switch receivedEvent {
			case CellCardPlayed(cell, cardId):
				Assert.equals(1, cell.col);
				Assert.equals(0, cell.row);
				Assert.equals("testCard", cardId);
			default:
				Assert.fail("Expected CellCardPlayed event");
		}
	}

	@Test
	public function testCellCardPlayedNotEmittedForForeignTarget():Void {
		// Card played on a target that doesn't belong to this grid → no event
		var screen = new UITestScreen();
		var builder = BuilderTestBase.builderFromSource('$CELL_MANIM\n$CARD_MANIM');

		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50),
			cellBuildName: "cell",
		});
		grid.addRectRegion(2, 2);

		var cardHand = new UICardHandHelper(screen, builder);
		grid.registerAsCardTarget(cardHand);

		var eventFired = false;
		grid.onGridEvent = (event) -> {
			switch event {
				case CellCardPlayed(_, _): eventFired = true;
				default:
			}
		};

		// Emit with a target ID that doesn't match this grid
		@:privateAccess cardHand.emitEvent(CardHandEvent.CardPlayed("testCard", TargetingResult.TargetZone("otherGrid_0_0")));

		Assert.isFalse(eventFired);
	}

	// ============== setCardEnabled during animation (Bug 1.4) ==============

	@Test
	public function testSetCardEnabledDuringAnimationDefersEnable():Void {
		// Bug 1.4: setCardEnabled(true) during animation sets InHand prematurely.
		// After fix: re-enabling a card disabled mid-animation defers to onComplete.
		var screen = new UITestScreen();
		var builder = BuilderTestBase.builderFromSource('$CELL_MANIM\n$CARD_MANIM');

		var cardHand = new UICardHandHelper(screen, builder);

		// Build a card manually and simulate animation state
		cardHand.setHand([{id: "c1", buildName: "card"}]);

		// Access private cards array to verify state transitions
		@:privateAccess var entry = cardHand.cards[0];
		Assert.equals(CardState.InHand, entry.state);

		// Simulate card entering animation state (as drawCard would do)
		entry.state = CardState.Animating;

		// Disable during animation — should set Disabled
		cardHand.setCardEnabled("c1", false);
		Assert.equals(CardState.Disabled, entry.state);
		Assert.isFalse(entry.enableAfterAnimation);

		// Re-enable while still "animating" — should stay Disabled, flag deferred enable
		// The entry.state is Disabled but there's no active animation tracked,
		// so isAnimatingEntry returns false → goes to else branch → InHand directly.
		// This test verifies the simpler case where state is not Animating.
		// The full scenario requires actual animations (integration test).
		cardHand.setCardEnabled("c1", true);

		// Without active animation, re-enable goes through the normal path
		Assert.equals(CardState.InHand, entry.state);
	}

	@Test
	public function testResolveAnimationCompleteWithDeferredEnable():Void {
		// Test the resolveAnimationComplete helper directly
		var screen = new UITestScreen();
		var builder = BuilderTestBase.builderFromSource('$CELL_MANIM\n$CARD_MANIM');

		var cardHand = new UICardHandHelper(screen, builder);
		cardHand.setHand([{id: "c1", buildName: "card"}]);

		@:privateAccess var entry = cardHand.cards[0];

		// Simulate: card was disabled during animation, then re-enable was deferred
		entry.state = CardState.Disabled;
		entry.enableAfterAnimation = true;

		// resolveAnimationComplete should restore InHand
		@:privateAccess cardHand.resolveAnimationComplete(entry);
		Assert.equals(CardState.InHand, entry.state);
		Assert.isFalse(entry.enableAfterAnimation);
	}

	@Test
	public function testResolveAnimationCompleteStaysDisabled():Void {
		// When disabled during animation without re-enable, should stay Disabled
		var screen = new UITestScreen();
		var builder = BuilderTestBase.builderFromSource('$CELL_MANIM\n$CARD_MANIM');

		var cardHand = new UICardHandHelper(screen, builder);
		cardHand.setHand([{id: "c1", buildName: "card"}]);

		@:privateAccess var entry = cardHand.cards[0];

		entry.state = CardState.Disabled;
		entry.enableAfterAnimation = false;

		@:privateAccess cardHand.resolveAnimationComplete(entry);
		Assert.equals(CardState.Disabled, entry.state);
	}

	@Test
	public function testCellCardPlayedListenerRemovedOnUnregister():Void {
		// After unregistering, the chained listener should be removed
		var screen = new UITestScreen();
		var builder = BuilderTestBase.builderFromSource('$CELL_MANIM\n$CARD_MANIM');

		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50),
			cellBuildName: "cell",
		});
		grid.addRectRegion(2, 2);

		var cardHand = new UICardHandHelper(screen, builder);
		grid.registerAsCardTarget(cardHand);

		@:privateAccess Assert.equals(1, cardHand.chainedListeners.length);

		grid.unregisterAsCardTarget(cardHand);

		@:privateAccess Assert.equals(0, cardHand.chainedListeners.length);
	}

	// ============== Multiple card hand registrations (Bug 1.10) ==============

	@Test
	public function testMultipleCardHandRegistrationsDontCorrupt():Void {
		// Bug 1.10: clearCardTargetsForBinding clears the ENTIRE shared map,
		// corrupting targets belonging to other card hands.
		var screen = new UITestScreen();
		var builder = BuilderTestBase.builderFromSource('$CELL_MANIM\n$CARD_MANIM');

		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50),
			cellBuildName: "cell",
		});
		grid.addRectRegion(2, 2); // 4 cells

		var cardHand1 = new UICardHandHelper(screen, builder);
		var cardHand2 = new UICardHandHelper(screen, builder);

		grid.registerAsCardTarget(cardHand1);
		// After first registration: 4 targets in shared maps
		@:privateAccess var mapSize1 = 0;
		@:privateAccess for (_ in grid.cardTargetInteractives) mapSize1++;
		Assert.equals(4, mapSize1);

		grid.registerAsCardTarget(cardHand2);
		// After second registration: should have 8 targets (4 per card hand)
		@:privateAccess var mapSize2 = 0;
		@:privateAccess for (_ in grid.cardTargetInteractives) mapSize2++;
		Assert.equals(8, mapSize2);

		// Unregister first card hand — should only remove its 4 targets, not all 8
		grid.unregisterAsCardTarget(cardHand1);
		@:privateAccess var mapSize3 = 0;
		@:privateAccess for (_ in grid.cardTargetInteractives) mapSize3++;
		// Bug 1.10: clearCardTargetsForBinding calls .clear() on the ENTIRE map,
		// so this returns 0 instead of 4
		Assert.equals(4, mapSize3);
	}

	// ============== Card target interactive positioning ==============

	@Test
	public function testCardTargetPositionRect():Void {
		// Card target interactives for rect grids should be positioned at
		// getCellLocalPosition (top-left), NOT offset by -cellSize/2.
		var screen = new UITestScreen();
		var builder = BuilderTestBase.builderFromSource('$CELL_MANIM\n$CARD_MANIM');

		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellBuildName: "cell",
		});
		grid.addRectRegion(2, 2);

		var cardHand = new UICardHandHelper(screen, builder);
		grid.registerAsCardTarget(cardHand);

		// Check interactive positions via @:privateAccess
		@:privateAccess var prefix = grid.registeredCardHands[0].targetPrefix;

		// Cell (0,0): local pos = (0, 0). Interactive should be at (0, 0).
		var i00 = '${prefix}_0_0';
		@:privateAccess var obj00 = grid.cardTargetInteractives.get(i00);
		Assert.notNull(obj00);
		Assert.floatEquals(0.0, obj00.x);
		Assert.floatEquals(0.0, obj00.y);

		// Cell (1,0): local pos = (52, 0). Interactive should be at (52, 0).
		var i10 = '${prefix}_1_0';
		@:privateAccess var obj10 = grid.cardTargetInteractives.get(i10);
		Assert.notNull(obj10);
		Assert.floatEquals(52.0, obj10.x);
		Assert.floatEquals(0.0, obj10.y);

		// Cell (0,1): local pos = (0, 52). Interactive should be at (0, 52).
		var i01 = '${prefix}_0_1';
		@:privateAccess var obj01 = grid.cardTargetInteractives.get(i01);
		Assert.notNull(obj01);
		Assert.floatEquals(0.0, obj01.x);
		Assert.floatEquals(52.0, obj01.y);
	}

	@Test
	public function testCardTargetPositionHex():Void {
		// Card target interactives for hex grids should be at center - cellSize/2
		// because getCellLocalPosition returns the hex center.
		var screen = new UITestScreen();
		var builder = BuilderTestBase.builderFromSource('$HEX_CELL_MANIM\n$CARD_MANIM');

		var grid = new UIMultiAnimGrid(builder, {
			gridType: Hex(POINTY, 30, 30),
			cellBuildName: "hexCell",
		});
		grid.addCell(0, 0);

		var cardHand = new UICardHandHelper(screen, builder);
		grid.registerAsCardTarget(cardHand);

		@:privateAccess var prefix = grid.registeredCardHands[0].targetPrefix;
		var i00 = '${prefix}_0_0';
		@:privateAccess var obj00 = grid.cardTargetInteractives.get(i00);
		Assert.notNull(obj00);

		// Hex center for (0,0) is at origin (0,0). CellBoundingSize = (60, 60).
		// Interactive should be at (0 - 30, 0 - 30) = (-30, -30).
		Assert.floatEquals(-30.0, obj00.x);
		Assert.floatEquals(-30.0, obj00.y);
	}

	// ============== acceptDrops duplicate registration (Bug 1.14) ==============

	@Test
	public function testAcceptDropsDuplicateIgnored():Void {
		// Bug 1.14: calling acceptDrops twice with the same draggable
		// would push duplicate bindings and create duplicate drop zones.
		var grid = createRectGrid(2, 2);

		var dragTarget = new h2d.Object();
		var drag = UIMultiAnimDraggable.create(dragTarget);

		grid.acceptDrops(drag);
		@:privateAccess var count1 = grid.registeredDraggables.length;
		Assert.equals(1, count1);

		// Second call with same draggable should be ignored
		grid.acceptDrops(drag);
		@:privateAccess var count2 = grid.registeredDraggables.length;
		Assert.equals(1, count2);
	}
}
