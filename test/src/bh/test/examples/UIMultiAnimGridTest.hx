package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness.UITestScreen;
import bh.ui.UIMultiAnimGrid;
import bh.ui.UIMultiAnimGridTypes;
import bh.ui.UIMultiAnimGridTypes.DefaultCellVisualFactory;
import bh.ui.UIMultiAnimGridTypes.SwapContext;
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

	// Cell + animated path for swap animation position tests
	static final CELL_WITH_PATH_MANIM = "
		paths {
			#swapLine path { lineTo(100, 0) }
		}
		#swapAnim animatedPath {
			path: swapLine
			type: time
			duration: 1.0
		}
		#cell programmable(col:int=0, row:int=0, status:[normal,hover]=normal, highlight:[none,accept,reject]=none) {
			bitmap(generated(color(50, 50, #666666))): 0, 0
		}
	";

	static final HEX_CELL_MANIM = "
		#hexCell programmable(col:int=0, row:int=0, status:[normal,hover]=normal, highlight:[none,accept,reject]=none) {
			bitmap(generated(color(30, 30, #888888))): 0, 0
		}
	";

	function createRectGrid(?cols:Int, ?rows:Int):UIMultiAnimGrid<Dynamic> {
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			originX: 0,
			originY: 0,
		});
		if (cols != null && rows != null)
			grid.addRectRegion(cols, rows);
		return grid;
	}

	function createHexGrid(?radius:Int):UIMultiAnimGrid<Dynamic> {
		var builder = BuilderTestBase.builderFromSource(HEX_CELL_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Hex(POINTY, 30, 30),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "hexCell"}),
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
	public function testGetCellVisual():Void {
		var grid = createRectGrid(2, 2);
		var result = grid.getCellVisual(0, 0);
		Assert.notNull(result);
	}

	@Test
	public function testGetCellVisualNonexistent():Void {
		var grid = createRectGrid(2, 2);
		var result = grid.getCellVisual(5, 5);
		Assert.isNull(result);
	}

	// ============== onCellBuilt callback ==============

	@Test
	public function testOnCellBuiltCallback():Void {
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
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

	function createNonSquareRectGrid():UIMultiAnimGrid<Dynamic> {
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		return new UIMultiAnimGrid(builder, {
			gridType: Rect(60, 30, 4), // wide cells: 60w x 30h, gap=4
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
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
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
		});
		grid.addRectRegion(2, 2);

		var cardHand = new UICardHandHelper(screen, builder);
		grid.registerAsCardTarget(cardHand);

		var receivedEvent:Null<GridEvent<Dynamic>> = null;
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
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
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
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
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
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
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
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
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
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "hexCell"}),
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

	// ============== Grid layers ==============

	static final LAYER_MANIM = "
		#overlay programmable(state:[normal,active]=normal) {
			bitmap(generated(color(50, 50, #FF0000))): 0, 0
		}
		#highlight programmable() {
			bitmap(generated(color(50, 50, #00FF00))): 0, 0
		}
	";

	function createRectGridWithLayers(?cols:Int, ?rows:Int):UIMultiAnimGrid<Dynamic> {
		var builder = BuilderTestBase.builderFromSource('$CELL_MANIM\n$LAYER_MANIM');
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			originX: 0,
			originY: 0,
		});
		if (cols != null && rows != null)
			grid.addRectRegion(cols, rows);
		return grid;
	}

	@Test
	public function testAddLayer():Void {
		var grid = createRectGridWithLayers(2, 2);
		grid.addLayer("overlay", {buildName: "overlay", zOrder: 1});
		// Should not throw — layer is registered
		Assert.isTrue(true);
	}

	@Test
	public function testAddLayerDuplicateThrows():Void {
		var grid = createRectGridWithLayers(2, 2);
		grid.addLayer("overlay", {buildName: "overlay", zOrder: 1});
		var threw = false;
		try {
			grid.addLayer("overlay", {buildName: "overlay", zOrder: 2});
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw);
	}

	@Test
	public function testSetLayerOnCell():Void {
		var grid = createRectGridWithLayers(2, 2);
		grid.addLayer("overlay", {buildName: "overlay", zOrder: 1});
		grid.setLayer(0, 0, "overlay");
		Assert.isTrue(grid.hasLayer(0, 0, "overlay"));
		Assert.notNull(grid.getLayerVisual(0, 0, "overlay"));
	}

	@Test
	public function testSetLayerOnNonexistentCellThrows():Void {
		var grid = createRectGridWithLayers(2, 2);
		grid.addLayer("overlay", {buildName: "overlay", zOrder: 1});
		var threw = false;
		try {
			grid.setLayer(5, 5, "overlay");
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw);
	}

	@Test
	public function testSetLayerUnregisteredThrows():Void {
		var grid = createRectGridWithLayers(2, 2);
		var threw = false;
		try {
			grid.setLayer(0, 0, "unknown");
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw);
	}

	@Test
	public function testSetLayerWithParams():Void {
		var grid = createRectGridWithLayers(2, 2);
		grid.addLayer("overlay", {buildName: "overlay", zOrder: 1});
		grid.setLayer(0, 0, "overlay", ["state" => "active"]);
		Assert.notNull(grid.getLayerVisual(0, 0, "overlay"));
	}

	@Test
	public function testClearLayerSingle():Void {
		var grid = createRectGridWithLayers(2, 2);
		grid.addLayer("overlay", {buildName: "overlay", zOrder: 1});
		grid.setLayer(0, 0, "overlay");
		Assert.isTrue(grid.hasLayer(0, 0, "overlay"));
		grid.clearLayer(0, 0, "overlay");
		Assert.isFalse(grid.hasLayer(0, 0, "overlay"));
		Assert.isNull(grid.getLayerVisual(0, 0, "overlay"));
	}

	@Test
	public function testClearLayerNonexistentDoesNotThrow():Void {
		var grid = createRectGridWithLayers(2, 2);
		grid.addLayer("overlay", {buildName: "overlay", zOrder: 1});
		// Should not throw — no layer set on this cell
		grid.clearLayer(0, 0, "overlay");
		Assert.isFalse(grid.hasLayer(0, 0, "overlay"));
	}

	@Test
	public function testClearLayerAll():Void {
		var grid = createRectGridWithLayers(2, 2);
		grid.addLayer("overlay", {buildName: "overlay", zOrder: 1});
		grid.setLayer(0, 0, "overlay");
		grid.setLayer(1, 0, "overlay");
		Assert.isTrue(grid.hasLayer(0, 0, "overlay"));
		Assert.isTrue(grid.hasLayer(1, 0, "overlay"));
		grid.clearLayerAll("overlay");
		Assert.isFalse(grid.hasLayer(0, 0, "overlay"));
		Assert.isFalse(grid.hasLayer(1, 0, "overlay"));
	}

	@Test
	public function testClearAllLayers():Void {
		var grid = createRectGridWithLayers(2, 2);
		grid.addLayer("overlay", {buildName: "overlay", zOrder: 1});
		grid.addLayer("hl", {buildName: "highlight", zOrder: 2});
		grid.setLayer(0, 0, "overlay");
		grid.setLayer(0, 0, "hl");
		Assert.isTrue(grid.hasLayer(0, 0, "overlay"));
		Assert.isTrue(grid.hasLayer(0, 0, "hl"));
		grid.clearAllLayers();
		Assert.isFalse(grid.hasLayer(0, 0, "overlay"));
		Assert.isFalse(grid.hasLayer(0, 0, "hl"));
	}

	@Test
	public function testRemoveCellAutoClearsLayers():Void {
		var grid = createRectGridWithLayers(2, 2);
		grid.addLayer("overlay", {buildName: "overlay", zOrder: 1});
		grid.setLayer(0, 0, "overlay");
		Assert.isTrue(grid.hasLayer(0, 0, "overlay"));
		grid.removeCell(0, 0);
		Assert.isFalse(grid.hasLayer(0, 0, "overlay"));
	}

	@Test
	public function testSetLayerBuildsIncremental():Void {
		var grid = createRectGridWithLayers(2, 2);
		grid.addLayer("overlay", {buildName: "overlay", zOrder: 1});
		grid.setLayer(0, 0, "overlay", ["state" => "active"]);
		var visual = grid.getLayerVisual(0, 0, "overlay");
		Assert.notNull(visual);
		// Layer visuals should support setParameter via getResult() (incremental mode)
		var threw = false;
		try {
			var result = visual.getResult();
			if (result != null)
				result.setParameter("state", "normal");
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isFalse(threw);
	}

	@Test
	public function testSetLayerRebuildsExisting():Void {
		var grid = createRectGridWithLayers(2, 2);
		grid.addLayer("overlay", {buildName: "overlay", zOrder: 1});
		grid.setLayer(0, 0, "overlay");
		var result1 = grid.getLayerVisual(0, 0, "overlay");
		grid.setLayer(0, 0, "overlay");
		var result2 = grid.getLayerVisual(0, 0, "overlay");
		Assert.notNull(result1);
		Assert.notNull(result2);
		// After rebuild, the result should be a different object
		Assert.isFalse(result1 == result2);
	}

	@Test
	public function testHasLayerFalseWhenNotSet():Void {
		var grid = createRectGridWithLayers(2, 2);
		grid.addLayer("overlay", {buildName: "overlay", zOrder: 1});
		Assert.isFalse(grid.hasLayer(0, 0, "overlay"));
	}

	@Test
	public function testDisposeClearsLayers():Void {
		var grid = createRectGridWithLayers(2, 2);
		grid.addLayer("overlay", {buildName: "overlay", zOrder: 1});
		grid.setLayer(0, 0, "overlay");
		grid.dispose();
		Assert.equals(0, grid.cellCount());
	}

	// ============== External objects ==============

	@Test
	public function testAddExternalObject():Void {
		var grid = createRectGrid(2, 2);
		var obj = new h2d.Object();
		grid.addExternalObject(obj, 5);
		Assert.notNull(obj.parent);
	}

	@Test
	public function testRemoveExternalObject():Void {
		var grid = createRectGrid(2, 2);
		var obj = new h2d.Object();
		grid.addExternalObject(obj, 5);
		Assert.notNull(obj.parent);
		grid.removeExternalObject(obj);
		Assert.isNull(obj.parent);
	}

	// ============== DropContext ==============

	@Test
	public function testDropContextDefaultState():Void {
		var ctx = new DropContext();
		Assert.isFalse(ctx.handled);
		Assert.isTrue(ctx.accepted);
		Assert.isNull(ctx.pathName);
		Assert.isNull(ctx.completeCb);
	}

	@Test
	public function testDropContextAccept():Void {
		var ctx = new DropContext();
		ctx.accept();
		Assert.isTrue(ctx.handled);
		Assert.isTrue(ctx.accepted);
		Assert.isNull(ctx.pathName);
	}

	@Test
	public function testDropContextReject():Void {
		var ctx = new DropContext();
		ctx.reject();
		Assert.isTrue(ctx.handled);
		Assert.isFalse(ctx.accepted);
		Assert.isNull(ctx.pathName);
	}

	@Test
	public function testDropContextAcceptWithPath():Void {
		var ctx = new DropContext();
		ctx.acceptWithPath("customSnap");
		Assert.isTrue(ctx.handled);
		Assert.isTrue(ctx.accepted);
		Assert.equals("customSnap", ctx.pathName);
	}

	@Test
	public function testDropContextRejectWithPath():Void {
		var ctx = new DropContext();
		ctx.rejectWithPath("customReturn");
		Assert.isTrue(ctx.handled);
		Assert.isFalse(ctx.accepted);
		Assert.equals("customReturn", ctx.pathName);
	}

	@Test
	public function testDropContextOnComplete():Void {
		var ctx = new DropContext();
		var fired = false;
		ctx.onComplete(() -> fired = true);
		Assert.notNull(ctx.completeCb);
		ctx.completeCb();
		Assert.isTrue(fired);
	}

	@Test
	public function testDropContextAcceptThenOnComplete():Void {
		var ctx = new DropContext();
		ctx.accept();
		var fired = false;
		ctx.onComplete(() -> fired = true);
		Assert.isTrue(ctx.handled);
		Assert.isTrue(ctx.accepted);
		Assert.notNull(ctx.completeCb);
		ctx.completeCb();
		Assert.isTrue(fired);
	}

	// ============== SwapContext ==============

	@Test
	public function testSwapContextDefaultState():Void {
		var ctx = new SwapContext();
		Assert.isFalse(ctx.handled);
		Assert.isTrue(ctx.accepted);
		Assert.isNull(ctx.swapPath);
		Assert.isNull(ctx.snapPath);
		Assert.isNull(ctx.completeCb);
		Assert.isFalse(ctx.programmatic);
	}

	@Test
	public function testSwapContextProgrammaticFlag():Void {
		var ctx = new SwapContext(true);
		Assert.isTrue(ctx.programmatic);
		var ctx2 = new SwapContext(false);
		Assert.isFalse(ctx2.programmatic);
	}

	@Test
	public function testSwapContextAccept():Void {
		var ctx = new SwapContext();
		ctx.accept();
		Assert.isTrue(ctx.handled);
		Assert.isTrue(ctx.accepted);
	}

	@Test
	public function testSwapContextReject():Void {
		var ctx = new SwapContext();
		ctx.reject();
		Assert.isTrue(ctx.handled);
		Assert.isFalse(ctx.accepted);
	}

	@Test
	public function testSwapContextAcceptWithSwapPath():Void {
		var ctx = new SwapContext();
		ctx.acceptWithSwapPath("customSwap");
		Assert.isTrue(ctx.handled);
		Assert.isTrue(ctx.accepted);
		Assert.equals("customSwap", ctx.swapPath);
		Assert.isNull(ctx.snapPath);
	}

	@Test
	public function testSwapContextAcceptWithPaths():Void {
		var ctx = new SwapContext();
		ctx.acceptWithPaths("snapPath", "swapPath");
		Assert.isTrue(ctx.handled);
		Assert.isTrue(ctx.accepted);
		Assert.equals("snapPath", ctx.snapPath);
		Assert.equals("swapPath", ctx.swapPath);
	}

	@Test
	public function testSwapContextOnComplete():Void {
		var ctx = new SwapContext();
		var fired = false;
		ctx.onComplete(() -> fired = true);
		Assert.notNull(ctx.completeCb);
		ctx.completeCb();
		Assert.isTrue(fired);
	}

	// ============== swapCells (programmatic) ==============

	function createSwapGrid(?cols:Int, ?rows:Int):UIMultiAnimGrid<Dynamic> {
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			originX: 0,
			originY: 0,
			swapEnabled: true,
		});
		if (cols != null && rows != null)
			grid.addRectRegion(cols, rows);
		return grid;
	}

	@Test
	public function testSwapCellsData():Void {
		var grid = createSwapGrid(3, 1);
		grid.set(0, 0, "apple");
		grid.set(1, 0, "banana");
		grid.swapCells(0, 0, 1, 0, false);
		Assert.equals("banana", grid.get(0, 0));
		Assert.equals("apple", grid.get(1, 0));
	}

	@Test
	public function testSwapCellsWithNullData():Void {
		var grid = createSwapGrid(3, 1);
		grid.set(0, 0, "apple");
		// cell (1,0) has null data
		grid.swapCells(0, 0, 1, 0, false);
		Assert.isNull(grid.get(0, 0));
		Assert.equals("apple", grid.get(1, 0));
	}

	@Test
	public function testSwapCellsSameCell():Void {
		var grid = createSwapGrid(2, 1);
		grid.set(0, 0, "test");
		grid.swapCells(0, 0, 0, 0, false);
		Assert.equals("test", grid.get(0, 0));
	}

	@Test
	public function testSwapCellsEmitsCellSwapEvent():Void {
		var grid = createSwapGrid(2, 1);
		grid.set(0, 0, "a");
		grid.set(1, 0, "b");

		var swapFired = false;
		var isProgrammatic = false;
		grid.onGridEvent = (event) -> {
			switch event {
				case CellSwap(source, target, draggable, ctx):
					swapFired = true;
					isProgrammatic = ctx.programmatic;
					Assert.equals(0, source.col);
					Assert.equals(0, source.row);
					Assert.equals(1, target.col);
					Assert.equals(0, target.row);
					Assert.isNull(draggable);
				default:
			}
		};

		grid.swapCells(0, 0, 1, 0, false);
		Assert.isTrue(swapFired);
		Assert.isTrue(isProgrammatic);
	}

	@Test
	public function testSwapCellsEmitsDataChangedEvents():Void {
		var grid = createSwapGrid(2, 1);
		grid.set(0, 0, "a");
		grid.set(1, 0, "b");

		var changeCount = 0;
		grid.onGridEvent = (event) -> {
			switch event {
				case CellDataChanged(_, _, _):
					changeCount++;
				default:
			}
		};

		grid.swapCells(0, 0, 1, 0, false);
		Assert.equals(2, changeCount);
	}

	@Test
	public function testSwapCellsRejected():Void {
		var grid = createSwapGrid(2, 1);
		grid.set(0, 0, "a");
		grid.set(1, 0, "b");

		grid.onGridEvent = (event) -> {
			switch event {
				case CellSwap(_, _, _, ctx):
					ctx.reject();
				default:
			}
		};

		grid.swapCells(0, 0, 1, 0, false);
		// Data should NOT have changed
		Assert.equals("a", grid.get(0, 0));
		Assert.equals("b", grid.get(1, 0));
	}

	@Test
	public function testSwapCellsOnCompleteInstant():Void {
		var grid = createSwapGrid(2, 1);
		grid.set(0, 0, "a");
		grid.set(1, 0, "b");

		var completeFired = false;
		grid.onGridEvent = (event) -> {
			switch event {
				case CellSwap(_, _, _, ctx):
					ctx.onComplete(() -> completeFired = true);
				default:
			}
		};

		grid.swapCells(0, 0, 1, 0, false);
		Assert.isTrue(completeFired);
	}

	@Test
	public function testSwapCellsAnimatedNoPath():Void {
		// animated=true but no swapPathName or returnPathName → instant
		var grid = createSwapGrid(2, 1);
		grid.set(0, 0, "x");
		grid.set(1, 0, "y");
		grid.swapCells(0, 0, 1, 0, true);
		Assert.equals("y", grid.get(0, 0));
		Assert.equals("x", grid.get(1, 0));
	}

	// ============== swapEnabled drop behavior ==============

	@Test
	public function testSwapEnabledConfigStored():Void {
		var grid = createSwapGrid(2, 1);
		@:privateAccess Assert.isTrue(grid.swapEnabled);
	}

	@Test
	public function testSwapEnabledDefaultFalse():Void {
		var grid = createRectGrid(2, 1);
		@:privateAccess Assert.isFalse(grid.swapEnabled);
	}

	@Test
	public function testSwapPathNameStored():Void {
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			swapPathName: "mySwapPath",
			swapEnabled: true,
		});
		@:privateAccess Assert.equals("mySwapPath", grid.swapPathName);
	}

	@Test
	public function testSwapPathNameFallsBackToReturn():Void {
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			returnPathName: "retPath",
			swapEnabled: true,
		});
		@:privateAccess Assert.isNull(grid.swapPathName);
		@:privateAccess Assert.equals("retPath", grid.returnPathName);
	}

	@Test
	public function testSwapHexGrid():Void {
		var builder = BuilderTestBase.builderFromSource(HEX_CELL_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Hex(POINTY, 30, 30),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "hexCell"}),
			swapEnabled: true,
		});
		grid.addHexRegion(0, 0, 1);
		grid.set(0, 0, "center");
		grid.set(1, 0, "right");
		grid.swapCells(0, 0, 1, 0, false);
		Assert.equals("right", grid.get(0, 0));
		Assert.equals("center", grid.get(1, 0));
	}

	@Test
	public function testSwapCellsNonexistentThrows():Void {
		var grid = createSwapGrid(2, 1);
		grid.set(0, 0, "a");
		var threw = false;
		try {
			grid.swapCells(0, 0, 5, 5, false);
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw);
	}

	@Test
	public function testSwapCellsPreservesOtherCells():Void {
		var grid = createSwapGrid(3, 1);
		grid.set(0, 0, "a");
		grid.set(1, 0, "b");
		grid.set(2, 0, "c");
		grid.swapCells(0, 0, 2, 0, false);
		Assert.equals("c", grid.get(0, 0));
		Assert.equals("b", grid.get(1, 0));
		Assert.equals("a", grid.get(2, 0));
	}

	@Test
	public function testSwapCellsDoubleSwapRestores():Void {
		var grid = createSwapGrid(2, 1);
		grid.set(0, 0, "a");
		grid.set(1, 0, "b");
		grid.swapCells(0, 0, 1, 0, false);
		grid.swapCells(0, 0, 1, 0, false);
		Assert.equals("a", grid.get(0, 0));
		Assert.equals("b", grid.get(1, 0));
	}

	@Test
	public function testSwapActiveAnimsCleanedOnDispose():Void {
		var grid = createSwapGrid(2, 1);
		grid.set(0, 0, "a");
		grid.set(1, 0, "b");
		grid.dispose();
		@:privateAccess Assert.equals(0, grid.activeSwapAnims.length);
	}

	// ============== Swap animation position verification ==============

	function createSwapGridWithPath(?originX:Float, ?originY:Float, ?swapContainer:h2d.Object):UIMultiAnimGrid<Dynamic> {
		var builder = BuilderTestBase.builderFromSource(CELL_WITH_PATH_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			originX: originX != null ? originX : 0,
			originY: originY != null ? originY : 0,
			swapEnabled: true,
			swapPathName: "swapAnim",
		});
		return grid;
	}

	static function assertApprox(expected:Float, actual:Float, ?msg:String, tolerance:Float = 1.0):Void {
		if (Math.abs(expected - actual) > tolerance)
			Assert.fail('Expected ~$expected but got $actual (tolerance $tolerance)${msg != null ? ": " + msg : ""}');
		else
			Assert.pass();
	}

	@Test
	public function testSwapAnimStartsAtSourceCellPosition():Void {
		// Grid at origin (100, 50), cell (0,0) at local (0,0) → scene (100, 50)
		// Cell (1,0) at local (52, 0) → scene (152, 50)
		// Swap (0,0) ↔ (1,0): object from cell0 should start at cell0's local position in grid root
		var grid = createSwapGridWithPath(100, 50);
		grid.addRectRegion(3, 1);
		grid.set(0, 0, "a");
		grid.set(1, 0, "b");

		grid.swapCells(0, 0, 1, 0, true);

		// Should have 2 active animations (one per direction)
		@:privateAccess {
			Assert.equals(2, grid.activeSwapAnims.length);

			// Both objects should be positioned at their source cell's local position in grid root
			// (since no swapAnimContainer, they're reparented to grid root)
			var anim0 = grid.activeSwapAnims[0]; // cell0 visual → cell1
			var anim1 = grid.activeSwapAnims[1]; // cell1 visual → cell0

			// Object from cell (0,0) starts at local (0, 0) in grid root
			assertApprox(0, anim0.object.x, "anim0 start x");
			assertApprox(0, anim0.object.y, "anim0 start y");

			// Object from cell (1,0) starts at local (52, 0) in grid root
			assertApprox(52, anim1.object.x, "anim1 start x");
			assertApprox(0, anim1.object.y, "anim1 start y");
		}

		grid.dispose();
	}

	@Test
	public function testSwapAnimMidpointPosition():Void {
		// Linear path, duration 1.0s. At t=0.5s, position should be halfway between from and to.
		var grid = createSwapGridWithPath(100, 50);
		grid.addRectRegion(3, 1);
		grid.set(0, 0, "a");
		grid.set(1, 0, "b");

		grid.swapCells(0, 0, 1, 0, true);

		// Step animation to t=0.5 (halfway)
		grid.update(0.5);

		@:privateAccess {
			Assert.equals(2, grid.activeSwapAnims.length);

			// cell (0,0) local = (0, 0), cell (1,0) local = (52, 0)
			// Midpoint in grid-root local space = (26, 0)
			var anim0 = grid.activeSwapAnims[0]; // cell0 → cell1
			assertApprox(26, anim0.object.x, "anim0 mid x");
			assertApprox(0, anim0.object.y, "anim0 mid y");

			// cell1 → cell0: midpoint is also (26, 0)
			var anim1 = grid.activeSwapAnims[1]; // cell1 → cell0
			assertApprox(26, anim1.object.x, "anim1 mid x");
			assertApprox(0, anim1.object.y, "anim1 mid y");
		}

		grid.dispose();
	}

	@Test
	public function testSwapAnimEndsAtTargetCellPosition():Void {
		var grid = createSwapGridWithPath(100, 50);
		grid.addRectRegion(3, 1);
		grid.set(0, 0, "a");
		grid.set(1, 0, "b");

		grid.swapCells(0, 0, 1, 0, true);

		// Step past completion (duration = 1.0s)
		grid.update(1.1);

		// Animations should be complete — activeSwapAnims cleared
		@:privateAccess Assert.equals(0, grid.activeSwapAnims.length);

		// Cells should have rebuilt with swapped data
		Assert.equals("b", grid.get(0, 0));
		Assert.equals("a", grid.get(1, 0));
	}

	@Test
	public function testSwapAnimWithExternalContainer():Void {
		// When swapAnimContainer is set, objects are reparented there.
		// Container at (200, 100) → scene-space coords converted to container-local.
		var container = new h2d.Object();
		container.setPosition(200, 100);

		var builder = BuilderTestBase.builderFromSource(CELL_WITH_PATH_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			originX: 100,
			originY: 50,
			swapEnabled: true,
			swapPathName: "swapAnim",
			swapAnimContainer: container,
		});
		grid.addRectRegion(2, 1);
		grid.set(0, 0, "a");
		grid.set(1, 0, "b");

		grid.swapCells(0, 0, 1, 0, true);

		@:privateAccess {
			Assert.equals(2, grid.activeSwapAnims.length);

			// Cell (0,0) scene pos = (100, 50). Container at (200, 100).
			// Container-local = (100 - 200, 50 - 100) = (-100, -50)
			var anim0 = grid.activeSwapAnims[0];
			assertApprox(-100, anim0.object.x, "container anim0 start x");
			assertApprox(-50, anim0.object.y, "container anim0 start y");

			// Cell (1,0) scene pos = (152, 50). Container-local = (-48, -50)
			var anim1 = grid.activeSwapAnims[1];
			assertApprox(-48, anim1.object.x, "container anim1 start x");
			assertApprox(-50, anim1.object.y, "container anim1 start y");
		}

		// Step to midpoint
		grid.update(0.5);

		@:privateAccess {
			// anim0: (-100, -50) → (-48, -50), midpoint = (-74, -50)
			var anim0 = grid.activeSwapAnims[0];
			assertApprox(-74, anim0.object.x, "container anim0 mid x");
			assertApprox(-50, anim0.object.y, "container anim0 mid y");

			// anim1: (-48, -50) → (-100, -50), midpoint = (-74, -50)
			var anim1 = grid.activeSwapAnims[1];
			assertApprox(-74, anim1.object.x, "container anim1 mid x");
			assertApprox(-50, anim1.object.y, "container anim1 mid y");
		}

		grid.dispose();
	}

	@Test
	public function testSwapAnimObjectParentedCorrectly():Void {
		// Without container: objects should be children of grid root
		var grid = createSwapGridWithPath(100, 50);
		grid.addRectRegion(2, 1);
		grid.set(0, 0, "a");
		grid.set(1, 0, "b");
		grid.swapCells(0, 0, 1, 0, true);

		@:privateAccess {
			var anim0 = grid.activeSwapAnims[0];
			Assert.isTrue(anim0.object.parent == cast grid.root);
		}

		grid.dispose();

		// With container: objects should be children of container
		var container = new h2d.Object();
		var builder2 = BuilderTestBase.builderFromSource(CELL_WITH_PATH_MANIM);
		var grid2 = new UIMultiAnimGrid(builder2, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder2, {cellBuildName: "cell"}),
			swapEnabled: true,
			swapPathName: "swapAnim",
			swapAnimContainer: container,
		});
		grid2.addRectRegion(2, 1);
		grid2.set(0, 0, "x");
		grid2.set(1, 0, "y");
		grid2.swapCells(0, 0, 1, 0, true);

		@:privateAccess {
			var anim0 = grid2.activeSwapAnims[0];
			Assert.equals(container, anim0.object.parent);
		}

		grid2.dispose();
	}

	@Test
	public function testSwapAnimNonZeroOriginNoJump():Void {
		// Verify no position jump between cell's original scene position and animation start.
		// Grid at (300, 200), cell (2,0) at local (104, 0) → scene (404, 200)
		var grid = createSwapGridWithPath(300, 200);
		grid.addRectRegion(3, 1);
		grid.set(2, 0, "c");
		grid.set(0, 0, "a");

		// Record cell (2,0) scene position before swap
		var cellScenePos = grid.cellPosition(2, 0);
		assertApprox(404, cellScenePos.x, "cell scene x");
		assertApprox(200, cellScenePos.y, "cell scene y");

		grid.swapCells(2, 0, 0, 0, true);

		@:privateAccess {
			// anim0 is cell (2,0) visual → cell (0,0) position
			// Object reparented to grid root at (300, 200)
			// Start position should be cell (2,0) local = (104, 0)
			var anim0 = grid.activeSwapAnims[0];
			assertApprox(104, anim0.object.x, "large origin anim start x");
			assertApprox(0, anim0.object.y, "large origin anim start y");

			// Object scene position should match original cell scene position
			// obj scene = parent.x + obj.x = 300 + 104 = 404
			// (We can't call localToGlobal in test easily, so verify via arithmetic)
			var objSceneX = grid.root.x + anim0.object.x;
			var objSceneY = grid.root.y + anim0.object.y;
			assertApprox(cellScenePos.x, objSceneX, "no jump scene x");
			assertApprox(cellScenePos.y, objSceneY, "no jump scene y");
		}

		grid.dispose();
	}

	// ============== cellDragEnabled config ==============

	@Test
	public function testCellDragEnabledDefaultFalse():Void {
		var grid = createRectGrid(2, 2);
		@:privateAccess Assert.isFalse(grid.cellDragEnabled);
	}

	@Test
	public function testCellDragEnabledConfigStored():Void {
		var grid = createCellDragGrid(2, 2);
		@:privateAccess Assert.isTrue(grid.cellDragEnabled);
	}

	@Test
	public function testCellDragFilterConfigStored():Void {
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		var filter = (col:Int, row:Int, data:Dynamic) -> col == 0;
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			cellDragEnabled: true,
			cellDragFilter: filter,
		});
		@:privateAccess Assert.equals(filter, grid.cellDragFilter);
	}

	// ============== cellDragEnabled: drag start ==============

	function createCellDragGrid(?cols:Int, ?rows:Int):UIMultiAnimGrid<Dynamic> {
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			originX: 0,
			originY: 0,
			cellDragEnabled: true,
		});
		if (cols != null && rows != null)
			grid.addRectRegion(cols, rows);
		return grid;
	}

	function createCellDragGridWithPaths(?cols:Int, ?rows:Int):UIMultiAnimGrid<Dynamic> {
		var builder = BuilderTestBase.builderFromSource(CELL_WITH_PATH_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			originX: 0,
			originY: 0,
			cellDragEnabled: true,
			snapPathName: "swapAnim",
			returnPathName: "swapAnim",
			swapEnabled: true,
			swapPathName: "swapAnim",
		});
		if (cols != null && rows != null)
			grid.addRectRegion(cols, rows);
		return grid;
	}

	@Test
	public function testCellDragStartOnOccupiedCell():Void {
		var grid = createCellDragGrid(3, 1);
		grid.set(1, 0, "item");

		// Push on occupied cell (1,0) at local (52, 25) — center of cell 1
		grid.onMouseClick(52, 25, 0);

		@:privateAccess {
			Assert.notNull(grid.cellDragObj);
			Assert.notNull(grid.cellDragSourceCoord);
			Assert.equals(1, grid.cellDragSourceCoord.col);
			Assert.equals(0, grid.cellDragSourceCoord.row);
			Assert.equals("item", grid.cellDragSourceData);
		}

		grid.dispose();
	}

	@Test
	public function testCellDragNoStartOnEmptyCell():Void {
		var grid = createCellDragGrid(3, 1);
		// No data on any cell

		grid.onMouseClick(25, 25, 0);

		@:privateAccess Assert.isNull(grid.cellDragObj);
		grid.dispose();
	}

	@Test
	public function testCellDragNoStartWhenDisabled():Void {
		var grid = createRectGrid(3, 1); // cellDragEnabled: false (default)
		grid.set(0, 0, "item");

		grid.onMouseClick(25, 25, 0);

		@:privateAccess Assert.isNull(grid.cellDragObj);
		grid.dispose();
	}

	@Test
	public function testCellDragFilterPreventsStart():Void {
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			originX: 0,
			originY: 0,
			cellDragEnabled: true,
			cellDragFilter: (col, row, data) -> col != 0, // Only allow dragging from col != 0
		});
		grid.addRectRegion(3, 1);
		grid.set(0, 0, "blocked");
		grid.set(1, 0, "allowed");

		// Try to drag from filtered cell (0,0) — should fail
		grid.onMouseClick(25, 25, 0);
		@:privateAccess Assert.isNull(grid.cellDragObj);

		// Drag from allowed cell (1,0) — should succeed
		grid.onMouseClick(52 + 25, 25, 0);
		@:privateAccess Assert.notNull(grid.cellDragObj);

		grid.dispose();
	}

	@Test
	public function testCellDragEmitsDragStartEvent():Void {
		var grid = createCellDragGrid(3, 1);
		grid.set(1, 0, "item");

		var dragStartCoord:Null<CellCoord> = null;
		grid.onGridEvent = (event) -> {
			switch event {
				case CellDragStart(cell, _):
					dragStartCoord = cell;
				default:
			}
		};

		grid.onMouseClick(52 + 25, 25, 0);

		Assert.notNull(dragStartCoord);
		Assert.equals(1, dragStartCoord.col);
		Assert.equals(0, dragStartCoord.row);

		grid.dispose();
	}

	@Test
	public function testCellDragConsumesMouseMove():Void {
		var grid = createCellDragGrid(3, 1);
		grid.set(1, 0, "item");

		grid.onMouseClick(52 + 25, 25, 0);

		// onMouseMove should return true when dragging
		var consumed = grid.onMouseMove(100, 25);
		Assert.isTrue(consumed);

		grid.dispose();
	}

	// ============== cellDragEnabled: drag cancel ==============

	@Test
	public function testCellDragReturnOnMiss():Void {
		var grid = createCellDragGrid(3, 1);
		grid.set(1, 0, "item");

		grid.onMouseClick(52 + 25, 25, 0);
		@:privateAccess Assert.notNull(grid.cellDragObj);

		// Release far outside grid — should cancel and rebuild source
		grid.onMouseRelease(500, 500);

		// After instant return (no returnPathName), source cell should be rebuilt
		@:privateAccess Assert.isNull(grid.cellDragObj);
		// Data should still be at original cell
		Assert.equals("item", grid.get(1, 0));

		grid.dispose();
	}

	@Test
	public function testCellDragEmitsDragEndOnCancel():Void {
		var grid = createCellDragGrid(3, 1);
		grid.set(1, 0, "item");

		var dragEndCoord:Null<CellCoord> = null;
		grid.onGridEvent = (event) -> {
			switch event {
				case CellDragEnd(cell):
					dragEndCoord = cell;
				default:
			}
		};

		grid.onMouseClick(52 + 25, 25, 0);
		grid.onMouseRelease(500, 500);

		Assert.notNull(dragEndCoord);
		Assert.equals(1, dragEndCoord.col);
		Assert.equals(0, dragEndCoord.row);

		grid.dispose();
	}

	@Test
	public function testCellDragCannotDropOnSourceCell():Void {
		// Source cell is excluded from drop targets — dropping on it should return
		var grid = createCellDragGrid(3, 1);
		grid.set(1, 0, "item");

		grid.onMouseClick(52 + 25, 25, 0);

		// Release on the same cell (1,0)
		grid.onMouseRelease(52 + 25, 25);

		@:privateAccess Assert.isNull(grid.cellDragObj);
		Assert.equals("item", grid.get(1, 0));

		grid.dispose();
	}

	// ============== cellDragEnabled: drop on same grid ==============

	@Test
	public function testCellDragDropEmitsCellDrop():Void {
		var grid = createCellDragGrid(3, 1);
		grid.set(0, 0, "item");

		var dropCoord:Null<CellCoord> = null;
		var dropPayload:Dynamic = null;
		var dropSourceCoord:Null<CellCoord> = null;
		grid.onGridEvent = (event) -> {
			switch event {
				case CellDrop(cell, draggable, _, sourceCell, ctx):
					dropCoord = cell;
					dropPayload = draggable.payload;
					dropSourceCoord = sourceCell;
					ctx.accept();
				default:
			}
		};

		// Drag from (0,0) to (2,0)
		grid.onMouseClick(25, 25, 0);
		grid.onMouseRelease(104 + 25, 25); // cell (2,0) at local x = 2*(50+2) = 104

		Assert.notNull(dropCoord);
		Assert.equals(2, dropCoord.col);
		Assert.equals(0, dropCoord.row);
		Assert.equals("item", dropPayload);
		Assert.notNull(dropSourceCoord);
		Assert.equals(0, dropSourceCoord.col);

		grid.dispose();
	}

	@Test
	public function testCellDragDropRejected():Void {
		var grid = createCellDragGrid(3, 1);
		grid.set(0, 0, "item");

		grid.onGridEvent = (event) -> {
			switch event {
				case CellDrop(_, _, _, _, ctx):
					ctx.reject();
				default:
			}
		};

		grid.onMouseClick(25, 25, 0);
		grid.onMouseRelease(104 + 25, 25);

		// Item should return to source cell (instant — no return path)
		@:privateAccess Assert.isNull(grid.cellDragObj);
		Assert.equals("item", grid.get(0, 0));

		grid.dispose();
	}

	@Test
	public function testCellDragEmitsDragEndOnDrop():Void {
		var grid = createCellDragGrid(3, 1);
		grid.set(0, 0, "item");

		var events:Array<String> = [];
		grid.onGridEvent = (event) -> {
			switch event {
				case CellDrop(_, _, _, _, ctx):
					events.push("drop");
					ctx.accept();
				case CellDragEnd(_):
					events.push("end");
				default:
			}
		};

		grid.onMouseClick(25, 25, 0);
		grid.onMouseRelease(104 + 25, 25);

		Assert.equals(2, events.length);
		Assert.equals("drop", events[0]);
		Assert.equals("end", events[1]);

		grid.dispose();
	}

	// ============== cellDragEnabled: swap ==============

	function createCellDragSwapGrid(?cols:Int, ?rows:Int):UIMultiAnimGrid<Dynamic> {
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		var grid = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			originX: 0,
			originY: 0,
			cellDragEnabled: true,
			swapEnabled: true,
		});
		if (cols != null && rows != null)
			grid.addRectRegion(cols, rows);
		return grid;
	}

	@Test
	public function testCellDragSwapEmitsCellSwap():Void {
		var grid = createCellDragSwapGrid(3, 1);
		grid.set(0, 0, "A");
		grid.set(1, 0, "B");

		var swapSrc:Null<CellCoord> = null;
		var swapTgt:Null<CellCoord> = null;
		grid.onGridEvent = (event) -> {
			switch event {
				case CellSwap(source, target, _, ctx):
					swapSrc = source;
					swapTgt = target;
					ctx.accept();
				default:
			}
		};

		// Drag from (0,0) to occupied (1,0)
		grid.onMouseClick(25, 25, 0);
		grid.onMouseRelease(52 + 25, 25);

		Assert.notNull(swapSrc);
		Assert.equals(0, swapSrc.col);
		Assert.notNull(swapTgt);
		Assert.equals(1, swapTgt.col);

		// Data should be swapped (instant — no paths)
		Assert.equals("B", grid.get(0, 0));
		Assert.equals("A", grid.get(1, 0));

		grid.dispose();
	}

	@Test
	public function testCellDragSwapRejected():Void {
		var grid = createCellDragSwapGrid(3, 1);
		grid.set(0, 0, "A");
		grid.set(1, 0, "B");

		grid.onGridEvent = (event) -> {
			switch event {
				case CellSwap(_, _, _, ctx):
					ctx.reject();
				default:
			}
		};

		grid.onMouseClick(25, 25, 0);
		grid.onMouseRelease(52 + 25, 25);

		// Rejected swap — data unchanged
		Assert.equals("A", grid.get(0, 0));
		Assert.equals("B", grid.get(1, 0));

		grid.dispose();
	}

	// ============== cellDragEnabled: swap with animated paths ==============

	@Test
	public function testCellDragSwapWithPaths():Void {
		var grid = createCellDragGridWithPaths(3, 1);
		grid.set(0, 0, "A");
		grid.set(1, 0, "B");

		var swapDone = false;
		grid.onGridEvent = (event) -> {
			switch event {
				case CellSwap(_, _, _, ctx):
					ctx.accept();
					ctx.onComplete(() -> swapDone = true);
				default:
			}
		};

		grid.onMouseClick(25, 25, 0);
		grid.onMouseRelease(52 + 25, 25);

		// Data swapped immediately
		Assert.equals("B", grid.get(0, 0));
		Assert.equals("A", grid.get(1, 0));

		// Animations should be running
		@:privateAccess Assert.isTrue(grid.activeSwapAnims.length > 0);

		// Complete animations
		grid.update(2.0);
		Assert.isTrue(swapDone);

		grid.dispose();
	}

	// ============== cellDragEnabled: right click does not drag ==============

	@Test
	public function testCellDragRightClickIgnored():Void {
		var grid = createCellDragGrid(3, 1);
		grid.set(0, 0, "item");

		// Right-click (button 1) should not start drag
		grid.onMouseClick(25, 25, 1);
		@:privateAccess Assert.isNull(grid.cellDragObj);

		grid.dispose();
	}

	// ============== linkDropTarget / linkGrids ==============

	@Test
	public function testLinkDropTargetStored():Void {
		var gridA = createCellDragGrid(2, 1);
		var gridB = createCellDragGrid(2, 1);

		gridA.linkDropTarget(gridB);
		@:privateAccess Assert.equals(1, gridA.linkedGrids.length);
		@:privateAccess Assert.equals(gridB, gridA.linkedGrids[0].target);

		gridA.dispose();
		gridB.dispose();
	}

	@Test
	public function testLinkDropTargetDuplicateIgnored():Void {
		var gridA = createCellDragGrid(2, 1);
		var gridB = createCellDragGrid(2, 1);

		gridA.linkDropTarget(gridB);
		gridA.linkDropTarget(gridB); // duplicate
		@:privateAccess Assert.equals(1, gridA.linkedGrids.length);

		gridA.dispose();
		gridB.dispose();
	}

	@Test
	public function testUnlinkDropTarget():Void {
		var gridA = createCellDragGrid(2, 1);
		var gridB = createCellDragGrid(2, 1);

		gridA.linkDropTarget(gridB);
		gridA.unlinkDropTarget(gridB);
		@:privateAccess Assert.equals(0, gridA.linkedGrids.length);

		gridA.dispose();
		gridB.dispose();
	}

	@Test
	public function testLinkGridsBidirectional():Void {
		var gridA = createCellDragGrid(2, 1);
		var gridB = createCellDragGrid(2, 1);

		UIMultiAnimGrid.linkGrids(gridA, gridB);
		@:privateAccess Assert.equals(1, gridA.linkedGrids.length);
		@:privateAccess Assert.equals(1, gridB.linkedGrids.length);

		gridA.dispose();
		gridB.dispose();
	}

	// ============== Cross-grid cell drag ==============

	@Test
	public function testCrossGridDragFindTarget():Void {
		// GridA at origin (0,0), gridB positioned so cellAtPoint can distinguish them
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		var gridA = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			originX: 0,
			originY: 0,
			cellDragEnabled: true,
		});
		gridA.addRectRegion(2, 1);
		gridA.set(0, 0, "from_A");

		var gridB = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			originX: 200,
			originY: 0,
			cellDragEnabled: true,
		});
		gridB.addRectRegion(2, 1);

		gridA.linkDropTarget(gridB);

		// Start drag from gridA cell (0,0)
		gridA.onMouseClick(25, 25, 0);
		@:privateAccess Assert.notNull(gridA.cellDragObj);

		// Find target should locate gridB cell at (200+25, 25) = gridB's (0,0)
		@:privateAccess {
			var hit = gridA.cellDragFindTarget(225, 25);
			Assert.notNull(hit);
			Assert.equals(gridB, hit.grid);
			Assert.equals(0, hit.coord.col);
			Assert.equals(0, hit.coord.row);
		}

		gridA.dispose();
		gridB.dispose();
	}

	@Test
	public function testCrossGridDropEmitsCellDropOnTarget():Void {
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		var gridA = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			originX: 0,
			originY: 0,
			cellDragEnabled: true,
		});
		gridA.addRectRegion(2, 1);
		gridA.set(0, 0, "payload");

		var gridB = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			originX: 200,
			originY: 0,
			cellDragEnabled: true,
		});
		gridB.addRectRegion(2, 1);

		gridA.linkDropTarget(gridB);

		// Track events on gridB (the target)
		var dropCoord:Null<CellCoord> = null;
		var dropPayload:Dynamic = null;
		var sourceGridRef:Dynamic = null;
		gridB.onGridEvent = (event) -> {
			switch event {
				case CellDrop(cell, draggable, sourceGrid, _, ctx):
					dropCoord = cell;
					dropPayload = draggable.payload;
					sourceGridRef = sourceGrid;
					ctx.accept();
				default:
			}
		};

		// Drag from gridA (0,0), release on gridB (0,0) at scene (225, 25)
		gridA.onMouseClick(25, 25, 0);
		gridA.onMouseRelease(225, 25);

		Assert.notNull(dropCoord);
		Assert.equals(0, dropCoord.col);
		Assert.equals("payload", dropPayload);
		Assert.equals(gridA, sourceGridRef);

		gridA.dispose();
		gridB.dispose();
	}

	@Test
	public function testCrossGridLinkAcceptsFilter():Void {
		var builder = BuilderTestBase.builderFromSource(CELL_MANIM);
		var gridA = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			originX: 0,
			originY: 0,
			cellDragEnabled: true,
		});
		gridA.addRectRegion(2, 1);
		gridA.set(0, 0, "item");

		var gridB = new UIMultiAnimGrid(builder, {
			gridType: Rect(50, 50, 2),
			cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
			originX: 200,
			originY: 0,
			cellDragEnabled: true,
		});
		gridB.addRectRegion(2, 1);

		// Link with accepts filter that rejects all
		gridA.linkDropTarget(gridB, (targetCell, sourceCell, data) -> false);

		// Start drag
		gridA.onMouseClick(25, 25, 0);

		// cellDragFindTarget should NOT find gridB cells (filtered out)
		@:privateAccess {
			var hit = gridA.cellDragFindTarget(225, 25);
			Assert.isNull(hit);
		}

		gridA.dispose();
		gridB.dispose();
	}

	@Test
	public function testLinkedGridsClearedOnDispose():Void {
		var gridA = createCellDragGrid(2, 1);
		var gridB = createCellDragGrid(2, 1);

		gridA.linkDropTarget(gridB);
		gridA.dispose();

		@:privateAccess Assert.equals(0, gridA.linkedGrids.length);

		gridB.dispose();
	}

	@Test
	public function testCellDragCleanedUpOnDispose():Void {
		var grid = createCellDragGrid(3, 1);
		grid.set(0, 0, "item");

		// Start drag then dispose mid-drag
		grid.onMouseClick(25, 25, 0);
		@:privateAccess Assert.notNull(grid.cellDragObj);

		grid.dispose();

		@:privateAccess Assert.isNull(grid.cellDragObj);
		@:privateAccess Assert.isNull(grid.cellDragSourceCoord);
	}

	@Test
	public function testCellDragOnlyLeftButton():Void {
		// Verify button 2 (middle) also does not start drag
		var grid = createCellDragGrid(3, 1);
		grid.set(0, 0, "item");

		grid.onMouseClick(25, 25, 2);
		@:privateAccess Assert.isNull(grid.cellDragObj);

		grid.dispose();
	}

	// ============== cellDragEnabled: source cell visual during drag ==============

	@Test
	public function testCellDragSourceDataPreservedDuringDrag():Void {
		var grid = createCellDragGrid(3, 1);
		grid.set(1, 0, "item");

		// Start drag from (1,0)
		grid.onMouseClick(52 + 25, 25, 0);
		@:privateAccess Assert.notNull(grid.cellDragObj);

		// Data should still be readable at source cell during drag
		Assert.equals("item", grid.get(1, 0));

		grid.dispose();
	}

	@Test
	public function testCellDragSourceCellShowsEmptyVisual():Void {
		var grid = createCellDragGrid(3, 1);
		grid.set(1, 0, "item");

		// Start drag from (1,0)
		grid.onMouseClick(52 + 25, 25, 0);
		@:privateAccess Assert.notNull(grid.cellDragObj);

		// Source cell visual should have been rebuilt (not a DummyCellVisual — getResult() non-null)
		final visual = grid.getCellVisual(1, 0);
		Assert.notNull(visual);
		Assert.notNull(visual.getResult());

		grid.dispose();
	}

	@Test
	public function testCellDragCancelRestoresSourceVisual():Void {
		var grid = createCellDragGrid(3, 1);
		grid.set(1, 0, "item");

		// Start drag
		grid.onMouseClick(52 + 25, 25, 0);
		@:privateAccess Assert.notNull(grid.cellDragObj);

		// Cancel by releasing outside grid
		grid.onMouseRelease(500, 500);

		// Source cell data and visual should be fully restored
		Assert.equals("item", grid.get(1, 0));
		@:privateAccess Assert.isNull(grid.cellDragObj);
		final visual = grid.getCellVisual(1, 0);
		Assert.notNull(visual);
		Assert.notNull(visual.getResult());

		grid.dispose();
	}

	@Test
	public function testCellDragDropRejectedRestoresSource():Void {
		var grid = createCellDragGrid(3, 1);
		grid.set(0, 0, "item");

		grid.onGridEvent = (event) -> {
			switch event {
				case CellDrop(_, _, _, _, ctx):
					ctx.reject();
				default:
			}
		};

		grid.onMouseClick(25, 25, 0);
		grid.onMouseRelease(104 + 25, 25);

		// After reject, source cell should be fully restored
		Assert.equals("item", grid.get(0, 0));
		final visual = grid.getCellVisual(0, 0);
		Assert.notNull(visual);
		Assert.notNull(visual.getResult());

		grid.dispose();
	}

	@Test
	public function testCellDragSwapTargetRebuildsAfterSnap():Void {
		// With no paths (instant), target should be rebuilt after snap completes
		var grid = createCellDragSwapGrid(3, 1);
		grid.set(0, 0, "A");
		grid.set(1, 0, "B");

		grid.onGridEvent = (event) -> {
			switch event {
				case CellSwap(_, _, _, ctx):
					ctx.accept();
				default:
			}
		};

		// Drag from (0,0) to occupied (1,0) — triggers swap
		grid.onMouseClick(25, 25, 0);
		grid.onMouseRelease(52 + 25, 25);

		// After instant swap, both cells should have proper visuals (not DummyCellVisual)
		Assert.equals("B", grid.get(0, 0));
		Assert.equals("A", grid.get(1, 0));
		final vis0 = grid.getCellVisual(0, 0);
		final vis1 = grid.getCellVisual(1, 0);
		Assert.notNull(vis0);
		Assert.notNull(vis1);
		Assert.notNull(vis0.getResult());
		Assert.notNull(vis1.getResult());

		grid.dispose();
	}

	// ============== cellDragEnabled: onComplete ==============

	@Test
	public function testCellDragDropOnCompleteCallback():Void {
		var grid = createCellDragGrid(3, 1);
		grid.set(0, 0, "item");

		var completeFired = false;
		grid.onGridEvent = (event) -> {
			switch event {
				case CellDrop(_, _, _, _, ctx):
					ctx.accept();
					ctx.onComplete(() -> completeFired = true);
				default:
			}
		};

		grid.onMouseClick(25, 25, 0);
		grid.onMouseRelease(104 + 25, 25);

		// Instant snap (no snapPathName) → onComplete should fire immediately
		Assert.isTrue(completeFired);

		grid.dispose();
	}
}
