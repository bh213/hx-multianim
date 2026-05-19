package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.BuildMode;
import bh.test.BuilderTestBase.buildFromSource;
import bh.test.BuilderTestBase.countVisibleDescendants;

/**
 * Regression — playground reports that hovering over a grid cell then leaving
 * "deletes" the previously-hovered empty cell. The cell visual factory drives
 * hover via `setParameter("status", "hover"|"normal")` which fires an
 * incremental @() / apply-filter re-evaluation on the playground grid-demo
 * `#hexCell` / `#rectCell` programmables (which contain both an
 * `@(highlight=>none)` conditional body and a `@(status=>hover) apply { filter }`).
 *
 * After two cycles of hover-in / hover-out the cell should be visually
 * identical to its initial state: same visible-descendant count, same filter
 * (null when not hovered).
 */
class GridCellHoverRegressionTest extends BuilderTestBase {
	// Minimal repro of the playground hex cell, with the two suspect elements:
	//   - @(highlight=>none) body — should always render in the default state
	//   - @(status=>hover) apply { filter: ... } — should add/remove a filter
	static final HEX_CELL_LIKE = "
		#hexCell programmable(col:int=0, row:int=0,
		                     status:[normal,hover]=normal,
		                     highlight:[none,accept,reject,expensive,locked]=none,
		                     occupied:bool=false, cellColor:color=#222244) {
		    @(highlight=>accept)    graphics(polygon(#2a3a2a, filled, 24, 0, 45, 12, 45, 36, 24, 48, 3, 36, 3, 12)): -24, -24
		    @(highlight=>none)      graphics(polygon(#1a1a2e, filled, 24, 0, 45, 12, 45, 36, 24, 48, 3, 36, 3, 12)): -24, -24
		    @(highlight=>reject)    graphics(polygon(#3a2020, filled, 24, 0, 45, 12, 45, 36, 24, 48, 3, 36, 3, 12)): -24, -24
		    @(highlight=>expensive) graphics(polygon(#3a3a1a, filled, 24, 0, 45, 12, 45, 36, 24, 48, 3, 36, 3, 12)): -24, -24
		    @(highlight=>locked)    graphics(polygon(#1a1a1a, filled, 24, 0, 45, 12, 45, 36, 24, 48, 3, 36, 3, 12)): -24, -24
		    @(occupied=>true)       graphics(polygon($cellColor, filled, 24, 6, 39, 15, 39, 33, 24, 42, 9, 33, 9, 15)): -24, -24
		    @(status=>hover)        apply { filter: glow(#44FFFF, 0.3, 4) }
		    graphics(polygon(#334466, 1.0, 24, 0, 45, 12, 45, 36, 24, 48, 3, 36, 3, 12)): -24, -24
		}
	";

	// Minimal repro of the playground rect cell with the same structural pieces.
	static final RECT_CELL_LIKE = "
		#rectCell programmable(col:int=0, row:int=0,
		                       status:[normal,hover]=normal,
		                       highlight:[none,accept,reject,expensive,locked,swap]=none,
		                       itemType:[none,weapon,potion]=none) {
		    bitmap(generated(color(52, 52, #1a1a2e))): 0, 0
		    @(highlight=>accept)     bitmap(generated(color(52, 52, #2a3a2a))): 0, 0
		    @(highlight=>reject)     bitmap(generated(color(52, 52, #3a2020))): 0, 0
		    @(status=>hover)         apply { filter: glow(#FFFF00, 0.3, 4) }
		    graphics(rect(#333355, 1.0, 52, 52)): 0, 0
		}
	";

	@Test
	public function testHexCellHoverThenLeaveRestoresVisuals():Void {
		final result = buildFromSource(HEX_CELL_LIKE, "hexCell", null, Incremental);
		final initialDescendants = countVisibleDescendants(result.object);
		Assert.isNull(result.object.filter, "Initial cell should have no filter");
		Assert.isTrue(initialDescendants > 0, 'Initial cell should have visible content, got $initialDescendants');

		// Cycle 1: hover then leave
		result.setParameter("status", "hover");
		result.setParameter("status", "normal");

		Assert.equals(initialDescendants, countVisibleDescendants(result.object),
			"After hover→leave the visible descendant count must match the initial state " +
			"(visibility flip should not lose @(highlight=>none) or any unconditional element)");
		Assert.isNull(result.object.filter,
			"After hover→leave the glow filter from @(status=>hover) apply { filter: ... } must be removed");

		// Cycle 2: a second pass — incremental caches/IR-cleanup regressions often
		// only manifest on the SECOND transition, not the first.
		result.setParameter("status", "hover");
		result.setParameter("status", "normal");

		Assert.equals(initialDescendants, countVisibleDescendants(result.object),
			"After second hover→leave the visible descendant count must STILL match initial");
		Assert.isNull(result.object.filter,
			"After second hover→leave the filter must STILL be null");
	}

	@Test
	public function testRectCellHoverThenLeaveRestoresVisuals():Void {
		final result = buildFromSource(RECT_CELL_LIKE, "rectCell", null, Incremental);
		final initialDescendants = countVisibleDescendants(result.object);
		Assert.isNull(result.object.filter, "Initial cell should have no filter");
		Assert.isTrue(initialDescendants > 0, 'Initial cell should have visible content, got $initialDescendants');

		// Cycle 1
		result.setParameter("status", "hover");
		result.setParameter("status", "normal");
		Assert.equals(initialDescendants, countVisibleDescendants(result.object),
			"Cycle 1: visible descendants must match initial");
		Assert.isNull(result.object.filter, "Cycle 1: filter must be null");

		// Cycle 2
		result.setParameter("status", "hover");
		result.setParameter("status", "normal");
		Assert.equals(initialDescendants, countVisibleDescendants(result.object),
			"Cycle 2: visible descendants must match initial");
		Assert.isNull(result.object.filter, "Cycle 2: filter must be null");
	}

	// The smoking gun: external code positions the parent AFTER build, then an
	// `@(...) apply { filter: ... }` activates/deactivates. The cell's x,y must
	// be preserved across the apply state flip.
	//
	// Regression introduced by commit 2b26e5f (apr 2026): per-parent baseline-
	// replay reset parent.x / parent.y to a stale baseline captured at build
	// time, snapping the cell back to (0,0) — visually "deleted" because all
	// hovered cells stacked at the grid origin.
	@Test
	public function testApplyFilterToggleDoesNotResetExternallySetPosition():Void {
		final result = buildFromSource(HEX_CELL_LIKE, "hexCell", null, Incremental);
		final obj = result.object;
		// Simulate the grid widget positioning the cell AFTER it was built.
		// (This is what UIMultiAnimGrid.cellPosition / placement code does in
		// the real playground — sets cell.object.setPosition(hexX, hexY).)
		obj.setPosition(123.0, 456.0);

		// Now trigger an apply { filter } toggle, as setStatus("hover")/setStatus("normal") would.
		result.setParameter("status", "hover");
		Assert.floatEquals(123.0, obj.x, "After hover-in, externally-set x must be preserved");
		Assert.floatEquals(456.0, obj.y, "After hover-in, externally-set y must be preserved");
		Assert.notNull(obj.filter, "Hover filter applied");

		result.setParameter("status", "normal");
		Assert.floatEquals(123.0, obj.x, "After hover-out, externally-set x must still be preserved");
		Assert.floatEquals(456.0, obj.y, "After hover-out, externally-set y must still be preserved");
		Assert.isNull(obj.filter, "Hover filter cleared");

		// Second cycle — incremental caches/replay paths often only break on the second flip.
		result.setParameter("status", "hover");
		Assert.floatEquals(123.0, obj.x, "Second cycle: x preserved");
		Assert.floatEquals(456.0, obj.y, "Second cycle: y preserved");
		result.setParameter("status", "normal");
		Assert.floatEquals(123.0, obj.x, "Second cycle end: x preserved");
		Assert.floatEquals(456.0, obj.y, "Second cycle end: y preserved");
	}

	@Test
	public function testHexCellFilterAppliedWhileHovering():Void {
		// Sanity: while status=hover the filter SHOULD be applied.
		final result = buildFromSource(HEX_CELL_LIKE, "hexCell", null, Incremental);
		Assert.isNull(result.object.filter, "Initial — no filter");

		result.setParameter("status", "hover");
		Assert.notNull(result.object.filter,
			"While status=hover the @(status=>hover) apply { filter: glow(...) } must apply a filter");
	}

	// ===== Multi-cell tests (mimicking the real grid: one builder, many cells) =====
	//
	// The real `DefaultCellVisualFactory.buildCell` calls
	// `builder.buildWithParameters(buildName, params, null, null, true)` for EVERY
	// cell on the grid — all sharing the same `MultiAnimBuilder`. The on-screen
	// `GridDemoScreen` has FOUR grids (rect, hex, storage, loadout), each holding
	// many cells, all from the same `demoBuilder`. If incremental-state caching
	// across BuilderResult siblings is wrong, a setParameter on cell A could
	// corrupt cell B's visual.

	@Test
	public function testTwoHexCellsHoverTransitionDoesNotCorruptPrevious():Void {
		// Mimic onMouseMove(A) → onMouseMove(B): leave A (status=normal), enter B (status=hover).
		final builder = bh.test.BuilderTestBase.builderFromSource(HEX_CELL_LIKE);
		final cellA = builder.buildWithParameters("hexCell", new Map(), null, null, true);
		final cellB = builder.buildWithParameters("hexCell", new Map(), null, null, true);

		final aInitial = countVisibleDescendants(cellA.object);
		final bInitial = countVisibleDescendants(cellB.object);

		// Simulate the mouse moving INTO A
		cellA.setParameter("status", "hover");
		Assert.notNull(cellA.object.filter, "A should have hover glow filter");
		Assert.isNull(cellB.object.filter, "B should still be unfiltered");
		Assert.equals(aInitial, countVisibleDescendants(cellA.object), "A visible descendants unchanged");
		Assert.equals(bInitial, countVisibleDescendants(cellB.object), "B visible descendants unchanged");

		// Simulate the mouse moving from A → B
		cellA.setParameter("status", "normal");
		cellB.setParameter("status", "hover");

		Assert.isNull(cellA.object.filter,
			"A's filter must be cleared after status→normal (mouse left A)");
		Assert.notNull(cellB.object.filter,
			"B should now have the hover glow filter");
		Assert.equals(aInitial, countVisibleDescendants(cellA.object),
			"After mouse moved away, A must retain its original visible content — " +
			"this is the playground-reported regression (previous empty cell appears deleted)");
		Assert.equals(bInitial, countVisibleDescendants(cellB.object),
			"B visible content unchanged (only the hover filter differs)");

		// Mouse exits the grid: B → none
		cellB.setParameter("status", "normal");
		Assert.isNull(cellB.object.filter, "B filter cleared after exit");
		Assert.equals(aInitial, countVisibleDescendants(cellA.object), "A still intact");
		Assert.equals(bInitial, countVisibleDescendants(cellB.object), "B still intact");
	}

	@Test
	public function testManyHexCellsSweepHoverAcrossDoesNotCorruptAny():Void {
		// A stress repro: build many cells and sweep hover across them like
		// the user drags the mouse across the grid.
		final builder = bh.test.BuilderTestBase.builderFromSource(HEX_CELL_LIKE);
		final cells:Array<bh.multianim.MultiAnimBuilder.BuilderResult> = [];
		for (_ in 0...10)
			cells.push(builder.buildWithParameters("hexCell", new Map(), null, null, true));

		final initialCounts = [for (c in cells) countVisibleDescendants(c.object)];

		// Sweep forward: hover A, then transition A→B→C…→J. Each step:
		// previous cell goes to "normal", next goes to "hover".
		var prev = -1;
		for (i in 0...cells.length) {
			if (prev >= 0)
				cells[prev].setParameter("status", "normal");
			cells[i].setParameter("status", "hover");
			prev = i;
		}
		// Finally leave the last
		cells[prev].setParameter("status", "normal");

		// Every cell should be back to its initial state.
		for (i in 0...cells.length) {
			Assert.isNull(cells[i].object.filter,
				'After sweep, cell $i must have no filter (status=normal)');
			Assert.equals(initialCounts[i], countVisibleDescendants(cells[i].object),
				'After sweep, cell $i must retain its initial visible descendant count ' +
				'(playground reports previous empty cells disappear during this sweep)');
		}
	}

	// ===== Real playground .manim file =====
	// The grid-demo.manim used by the playground has dozens of programmables,
	// paths, curves, animatedPaths, layer programmables, card programmables,
	// etc. If incremental-state caching across BuilderResult siblings within
	// a single, larger builder is wrong, the bug may only appear here.

	// Mirror exactly what `applyCellTargetFeedback` does on a real hover-out:
	// beginUpdate → setStatus("normal") → setHighlight("none") → endUpdate.
	// (Plus event-source bookkeeping which is irrelevant to cell visuals.)
	static function unhover(cell:bh.multianim.MultiAnimBuilder.BuilderResult):Void {
		cell.beginUpdate();
		cell.setParameter("status", "normal");
		cell.setParameter("highlight", "none");
		cell.endUpdate();
	}

	static function hover(cell:bh.multianim.MultiAnimBuilder.BuilderResult):Void {
		cell.beginUpdate();
		cell.setParameter("status", "hover");
		cell.endUpdate();
	}

	@Test
	public function testRealHexCellSweepWithHighlightReset():Void {
		// Exercise the exact path used by `applyCellTargetFeedback`:
		// hover sets only `status`; unhover sets BOTH `status` AND `highlight`.
		// This is what fires in the playground when the card hand's target-highlight
		// callback chain runs (which happens on every mouse-over of a registered cell target).
		final builder = bh.test.BuilderTestBase.builderFromFile("test/res/grid-demo.manim");
		final cells:Array<bh.multianim.MultiAnimBuilder.BuilderResult> = [];
		for (_ in 0...10)
			cells.push(builder.buildWithParameters("hexCell", new Map(), null, null, true));

		final initial = [for (c in cells) countVisibleDescendants(c.object)];

		var prev = -1;
		for (i in 0...cells.length) {
			if (prev >= 0)
				unhover(cells[prev]);
			hover(cells[i]);
			prev = i;
		}
		unhover(cells[prev]);

		for (i in 0...cells.length) {
			Assert.isNull(cells[i].object.filter,
				'After sweep, hexCell $i must have no filter');
			Assert.equals(initial[i], countVisibleDescendants(cells[i].object),
				'After sweep with highlight reset, hexCell $i must retain its initial visible ' +
				'descendant count (playground regression: previous empty cells disappear)');
		}
	}

	@Test
	public function testRealRectCellSweepWithHighlightReset():Void {
		final builder = bh.test.BuilderTestBase.builderFromFile("test/res/grid-demo.manim");
		final cells:Array<bh.multianim.MultiAnimBuilder.BuilderResult> = [];
		for (_ in 0...10)
			cells.push(builder.buildWithParameters("rectCell", new Map(), null, null, true));

		final initial = [for (c in cells) countVisibleDescendants(c.object)];

		var prev = -1;
		for (i in 0...cells.length) {
			if (prev >= 0)
				unhover(cells[prev]);
			hover(cells[i]);
			prev = i;
		}
		unhover(cells[prev]);

		for (i in 0...cells.length) {
			Assert.isNull(cells[i].object.filter,
				'After sweep, rectCell $i must have no filter');
			Assert.equals(initial[i], countVisibleDescendants(cells[i].object),
				'After sweep with highlight reset, rectCell $i must retain its initial visible ' +
				'descendant count (playground regression: previous empty cells disappear)');
		}
	}

	@Test
	public function testRealHexCellSweepFromFullGridDemoManim():Void {
		final builder = bh.test.BuilderTestBase.builderFromFile("test/res/grid-demo.manim");
		final cells:Array<bh.multianim.MultiAnimBuilder.BuilderResult> = [];
		for (_ in 0...10)
			cells.push(builder.buildWithParameters("hexCell", new Map(), null, null, true));

		final initial = [for (c in cells) countVisibleDescendants(c.object)];

		var prev = -1;
		for (i in 0...cells.length) {
			if (prev >= 0)
				cells[prev].setParameter("status", "normal");
			cells[i].setParameter("status", "hover");
			prev = i;
		}
		cells[prev].setParameter("status", "normal");

		for (i in 0...cells.length) {
			Assert.isNull(cells[i].object.filter,
				'After sweep, hexCell $i must have no filter');
			Assert.equals(initial[i], countVisibleDescendants(cells[i].object),
				'After sweep, hexCell $i must retain its initial visible descendant count ' +
				'(from full grid-demo.manim — playground report)');
		}
	}

	@Test
	public function testRealRectCellSweepFromFullGridDemoManim():Void {
		final builder = bh.test.BuilderTestBase.builderFromFile("test/res/grid-demo.manim");
		final cells:Array<bh.multianim.MultiAnimBuilder.BuilderResult> = [];
		for (_ in 0...10)
			cells.push(builder.buildWithParameters("rectCell", new Map(), null, null, true));

		final initial = [for (c in cells) countVisibleDescendants(c.object)];

		var prev = -1;
		for (i in 0...cells.length) {
			if (prev >= 0)
				cells[prev].setParameter("status", "normal");
			cells[i].setParameter("status", "hover");
			prev = i;
		}
		cells[prev].setParameter("status", "normal");

		for (i in 0...cells.length) {
			Assert.isNull(cells[i].object.filter,
				'After sweep, rectCell $i must have no filter');
			Assert.equals(initial[i], countVisibleDescendants(cells[i].object),
				'After sweep, rectCell $i must retain its initial visible descendant count ' +
				'(from full grid-demo.manim — playground report)');
		}
	}

	// ===== Full-widget tests using the real UIMultiAnimGrid.onMouseMove =====
	// These exercise the same code path as the playground: cellFactory builds each
	// cell, then the widget's mouse-move routing transitions hover state. If any
	// step in that chain corrupts a cell, this test should catch it.

	@Test
	public function testFullGridWidgetMouseSweepLeavesCellsIntact_Rect():Void {
		final builder = bh.test.BuilderTestBase.builderFromFile("test/res/grid-demo.manim");
		final factory = new bh.ui.UIMultiAnimGridTypes.DefaultCellVisualFactory(builder, {cellBuildName: "rectCell"});
		final grid = new bh.ui.UIMultiAnimGrid<Dynamic>(builder, {
			gridType: Rect(52, 52, 4),
			cellVisualFactory: factory,
			originX: 0,
			originY: 0,
		});
		grid.addRectRegion(5, 4);

		// Snapshot initial cell visuals
		final initialCounts:Array<Int> = [];
		for (col in 0...5)
			for (row in 0...4) {
				final vis = grid.getCellVisual(col, row);
				initialCounts.push(countVisibleDescendants(vis.object));
			}

		// Sweep mouse across the grid horizontally row-by-row.
		// Cell size is 52, gap 4 → step 56. Center of each cell ~ (col*56+26, row*56+26).
		for (row in 0...4)
			for (col in 0...5)
				grid.onMouseMove(col * 56 + 26, row * 56 + 26);
		// Move off-grid to clear hover state
		grid.onMouseMove(1000, 1000);

		// Verify every cell still has its initial visible-descendant count and no filter.
		var idx = 0;
		for (col in 0...5)
			for (row in 0...4) {
				final vis = grid.getCellVisual(col, row);
				Assert.isNull(vis.object.filter,
					'After full-grid sweep, rectCell ($col,$row) must have no filter');
				Assert.equals(initialCounts[idx], countVisibleDescendants(vis.object),
					'After full-grid sweep, rectCell ($col,$row) visible descendants must match initial ' +
					'(playground regression — empty cells disappear after hovering)');
				idx++;
			}
	}

	// Returns the bounding box area of all h2d.Graphics descendants.
	// If any Graphics had its draw commands cleared (via onRemove()), its bounds
	// shrink to empty and the area drops — even though the Graphics object is
	// still "visible" in the scene tree.
	static function totalGraphicsArea(obj:h2d.Object):Float {
		var area:Float = 0;
		final all:Array<h2d.Object> = [];
		collectAll(obj, all);
		for (child in all) {
			if (Std.isOfType(child, h2d.Graphics)) {
				final g:h2d.Graphics = cast child;
				final b = g.getBounds();
				if (!b.isEmpty()) {
					area += b.width * b.height;
				}
			}
		}
		return area;
	}

	static function collectAll(obj:h2d.Object, out:Array<h2d.Object>):Void {
		for (i in 0...obj.numChildren) {
			final c = obj.getChildAt(i);
			out.push(c);
			collectAll(c, out);
		}
	}

	@Test
	public function testFullGridWidgetMouseSweepKeepsHexGraphicsDrawn():Void {
		// REAL regression test: cells use graphics(polygon(...)) which becomes h2d.Graphics.
		// h2d.Graphics.onRemove() clears its draw commands. If the cell's Graphics is
		// detached during hover and the @() re-add path fails to call back into draw,
		// the cell renders blank — exactly the playground symptom.
		final builder = bh.test.BuilderTestBase.builderFromFile("test/res/grid-demo.manim");
		final factory = new bh.ui.UIMultiAnimGridTypes.DefaultCellVisualFactory(builder, {cellBuildName: "hexCell"});
		final grid = new bh.ui.UIMultiAnimGrid<Dynamic>(builder, {
			gridType: Hex(POINTY, 30, 30),
			cellVisualFactory: factory,
			originX: 0,
			originY: 0,
		});
		grid.addHexRegion(0, 0, 2);

		// Snapshot initial Graphics-area for each cell
		final cellCoords:Array<bh.ui.UIMultiAnimGridTypes.CellCoord> = [];
		final initialAreas:Array<Float> = [];
		grid.forEach((col, row, _) -> {
			cellCoords.push({col: col, row: row});
			final vis = grid.getCellVisual(col, row);
			initialAreas.push(totalGraphicsArea(vis.object));
		});

		// Sweep mouse across each cell center
		for (coord in cellCoords) {
			final p = grid.cellPosition(coord.col, coord.row);
			grid.onMouseMove(p.x, p.y);
		}
		grid.onMouseMove(2000, 2000);

		for (i in 0...cellCoords.length) {
			final coord = cellCoords[i];
			final vis = grid.getCellVisual(coord.col, coord.row);
			final afterArea = totalGraphicsArea(vis.object);
			Assert.floatEquals(initialAreas[i], afterArea,
				'After hex sweep, cell (${coord.col},${coord.row}) total Graphics bounds area ' +
				'changed: initial=${initialAreas[i]}, after=${afterArea}. This is the playground ' +
				'regression — h2d.Graphics draw commands cleared and not re-fired.');
		}
	}

	@Test
	public function testFullGridWidgetMouseSweepKeepsRectGraphicsDrawn():Void {
		final builder = bh.test.BuilderTestBase.builderFromFile("test/res/grid-demo.manim");
		final factory = new bh.ui.UIMultiAnimGridTypes.DefaultCellVisualFactory(builder, {cellBuildName: "rectCell"});
		final grid = new bh.ui.UIMultiAnimGrid<Dynamic>(builder, {
			gridType: Rect(52, 52, 4),
			cellVisualFactory: factory,
			originX: 0,
			originY: 0,
		});
		grid.addRectRegion(5, 4);

		final initial:Array<Float> = [];
		for (col in 0...5)
			for (row in 0...4) {
				final vis = grid.getCellVisual(col, row);
				initial.push(totalGraphicsArea(vis.object));
			}

		for (row in 0...4)
			for (col in 0...5)
				grid.onMouseMove(col * 56 + 26, row * 56 + 26);
		grid.onMouseMove(1000, 1000);

		var idx = 0;
		for (col in 0...5)
			for (row in 0...4) {
				final vis = grid.getCellVisual(col, row);
				final after = totalGraphicsArea(vis.object);
				Assert.floatEquals(initial[idx], after,
					'After rect sweep, cell ($col,$row) Graphics area: initial=${initial[idx]} after=${after}');
				idx++;
			}
	}

	@Test
	public function testFullGridWidgetMouseSweepLeavesCellsIntact_Hex():Void {
		final builder = bh.test.BuilderTestBase.builderFromFile("test/res/grid-demo.manim");
		final factory = new bh.ui.UIMultiAnimGridTypes.DefaultCellVisualFactory(builder, {cellBuildName: "hexCell"});
		final grid = new bh.ui.UIMultiAnimGrid<Dynamic>(builder, {
			gridType: Hex(POINTY, 30, 30),
			cellVisualFactory: factory,
			originX: 0,
			originY: 0,
		});
		grid.addHexRegion(0, 0, 2);

		// Snapshot initial visuals
		final cellCoords:Array<bh.ui.UIMultiAnimGridTypes.CellCoord> = [];
		final initialCounts:Array<Int> = [];
		grid.forEach((col, row, _) -> {
			cellCoords.push({col: col, row: row});
			final vis = grid.getCellVisual(col, row);
			initialCounts.push(countVisibleDescendants(vis.object));
		});

		// Sweep mouse across each cell's center position. Use cellPosition to be precise.
		for (coord in cellCoords) {
			final p = grid.cellPosition(coord.col, coord.row);
			grid.onMouseMove(p.x, p.y);
		}
		grid.onMouseMove(2000, 2000); // off-grid

		// Verify
		for (i in 0...cellCoords.length) {
			final coord = cellCoords[i];
			final vis = grid.getCellVisual(coord.col, coord.row);
			Assert.isNull(vis.object.filter,
				'After hex sweep, hexCell (${coord.col},${coord.row}) must have no filter');
			Assert.equals(initialCounts[i], countVisibleDescendants(vis.object),
				'After hex sweep, hexCell (${coord.col},${coord.row}) visible descendants ' +
				'must match initial (playground regression)');
		}
	}

	@Test
	public function testMultiGridMouseSweepKeepsCellsIntact():Void {
		// The playground GridDemoScreen has FOUR grids (rect, hex, storage, loadout),
		// all sharing a single MultiAnimBuilder AND the static _scratchPoint /
		// _scratchFPoint in UIMultiAnimGrid. Every mouse-move from the screen
		// dispatches to all four grids' onMouseMove sequentially.
		final builder = bh.test.BuilderTestBase.builderFromFile("test/res/grid-demo.manim");

		final rectFactory = new bh.ui.UIMultiAnimGridTypes.DefaultCellVisualFactory(builder, {cellBuildName: "rectCell"});
		final rectGrid = new bh.ui.UIMultiAnimGrid<Dynamic>(builder, {
			gridType: Rect(52, 52, 4),
			cellVisualFactory: rectFactory,
			originX: 10, originY: 130,
		});
		rectGrid.addRectRegion(5, 4);

		final hexFactory = new bh.ui.UIMultiAnimGridTypes.DefaultCellVisualFactory(builder, {cellBuildName: "hexCell"});
		final hexGrid = new bh.ui.UIMultiAnimGrid<Dynamic>(builder, {
			gridType: Hex(POINTY, 30, 30),
			cellVisualFactory: hexFactory,
			originX: 510, originY: 280,
		});
		hexGrid.addHexRegion(0, 0, 2);

		final storageFactory = new bh.ui.UIMultiAnimGridTypes.DefaultCellVisualFactory(builder, {cellBuildName: "rectCell"});
		final storageGrid = new bh.ui.UIMultiAnimGrid<Dynamic>(builder, {
			gridType: Rect(52, 52, 4),
			cellVisualFactory: storageFactory,
			originX: 780, originY: 152,
		});
		storageGrid.addRectRegion(4, 2);

		final loadoutFactory = new bh.ui.UIMultiAnimGridTypes.DefaultCellVisualFactory(builder, {cellBuildName: "rectCell"});
		final loadoutGrid = new bh.ui.UIMultiAnimGrid<Dynamic>(builder, {
			gridType: Rect(52, 52, 4),
			cellVisualFactory: loadoutFactory,
			originX: 780, originY: 264,
		});
		loadoutGrid.addRectRegion(3, 2);

		final grids = [rectGrid, hexGrid, storageGrid, loadoutGrid];

		// Snapshot ALL cells' initial graphics areas
		final allInitial:Map<String, Float> = new Map();
		for (gi in 0...grids.length) {
			final g = grids[gi];
			g.forEach((col, row, _) -> {
				final v = g.getCellVisual(col, row);
				allInitial.set('$gi:$col:$row', totalGraphicsArea(v.object));
			});
		}

		// Sweep mouse over hex cells; dispatch each move to ALL four grids
		// (this is exactly what UIScreen.dispatchMouseMove does in the playground).
		hexGrid.forEach((col, row, _) -> {
			final p = hexGrid.cellPosition(col, row);
			final sx = hexGrid.getObject().x + p.x;
			final sy = hexGrid.getObject().y + p.y;
			for (g in grids)
				g.onMouseMove(sx, sy);
		});
		// Move way off
		for (g in grids)
			g.onMouseMove(5000, 5000);

		// Verify every cell's Graphics area is unchanged
		for (gi in 0...grids.length) {
			final g = grids[gi];
			g.forEach((col, row, _) -> {
				final v = g.getCellVisual(col, row);
				final after = totalGraphicsArea(v.object);
				final initial = allInitial.get('$gi:$col:$row');
				Assert.floatEquals(initial, after,
					'After multi-grid mouse sweep, grid#$gi cell ($col,$row) Graphics area ' +
					'changed: initial=$initial, after=$after — playground regression');
			});
		}
	}

	@Test
	public function testTwoRectCellsHoverTransitionDoesNotCorruptPrevious():Void {
		final builder = bh.test.BuilderTestBase.builderFromSource(RECT_CELL_LIKE);
		final cellA = builder.buildWithParameters("rectCell", new Map(), null, null, true);
		final cellB = builder.buildWithParameters("rectCell", new Map(), null, null, true);

		final aInitial = countVisibleDescendants(cellA.object);
		final bInitial = countVisibleDescendants(cellB.object);

		cellA.setParameter("status", "hover");
		cellA.setParameter("status", "normal");
		cellB.setParameter("status", "hover");
		cellB.setParameter("status", "normal");

		Assert.isNull(cellA.object.filter, "A filter cleared");
		Assert.isNull(cellB.object.filter, "B filter cleared");
		Assert.equals(aInitial, countVisibleDescendants(cellA.object),
			"A visible content must be intact after sweep");
		Assert.equals(bInitial, countVisibleDescendants(cellB.object),
			"B visible content must be intact after sweep");
	}
}
