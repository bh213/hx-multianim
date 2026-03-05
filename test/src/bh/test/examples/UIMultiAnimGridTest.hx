package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.ui.UIMultiAnimGrid;
import bh.ui.UIMultiAnimGridTypes;
import bh.base.Hex.HexOrientation;

/**
 * Unit tests for UIMultiAnimGrid.
 * Tests cell management, data operations, coordinate queries, hit testing, and events.
 */
class UIMultiAnimGridTest extends BuilderTestBase {
	static final CELL_MANIM = "
		#cell programmable(col:int=0, row:int=0, status:[normal,hover]=normal, highlight:bool=false) {
			bitmap(generated(color(50, 50, #666666))): 0, 0
		}
	";

	static final HEX_CELL_MANIM = "
		#hexCell programmable(col:int=0, row:int=0, status:[normal,hover]=normal, highlight:bool=false) {
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
				case CellHoverEnter(cell):
					enters.push(cell);
				case CellHoverLeave(cell):
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
				case CellHoverLeave(_):
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
}
