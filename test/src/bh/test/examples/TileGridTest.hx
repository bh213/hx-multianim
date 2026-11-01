package bh.test.examples;

import utest.Assert;
import bh.base.TileGrid;
import bh.test.BuilderTestBase.builderFromSource;
import bh.test.BuilderTestBase.parseExpectingError;

/**
 * The grids a tileset lays its tiles on (`bh.base.TileGrid`, `grid:` in a tileset): each grid's
 * cells to pixels and back, a point anywhere in a cell going to it, the neighbours, the box around
 * a rectangle of cells, where a frame is put, and the tileset's `grid:` read.
 */
class TileGridTest extends utest.Test {
	static function grids():Array<{name:String, grid:TileGrid}> {
		return [
			{name: "square 16", grid: TileGrid.square(16)},
			{name: "orthogonal 16x8", grid: new TileGrid(Orthogonal, 16, 8)},
			{name: "isometric 32x16", grid: new TileGrid(Isometric, 32, 16)},
			{name: "isometric 132x66", grid: new TileGrid(Isometric, 132, 66)},
			{name: "hex pointy odd 32x28", grid: new TileGrid(Hex, 32, 28, true, true)},
			{name: "hex pointy even 32x28", grid: new TileGrid(Hex, 32, 28, true, false)},
			{name: "hex pointy odd 32x28 side 12", grid: new TileGrid(Hex, 32, 28, true, true, 12)},
			{name: "hex flat odd 28x32", grid: new TileGrid(Hex, 28, 32, false, true)},
			{name: "hex flat even 30x26 side 10", grid: new TileGrid(Hex, 30, 26, false, false, 10)},
		];
	}

	/** Whether a point lies inside a cell's drawn shape (square, diamond or hex), its edges left out by `inset`. **/
	static function insideShape(g:TileGrid, cx:Int, cy:Int, x:Float, y:Float, inset:Float):Bool {
		final lx = x - g.pixelX(cx, cy);
		final ly = y - g.pixelY(cx, cy);
		final w = g.tileWidth;
		final h = g.tileHeight;
		if (lx < inset || ly < inset || lx > w - inset || ly > h - inset)
			return false;
		return switch g.kind {
			case Orthogonal: true;
			case Isometric: Math.abs(lx - w / 2) / (w / 2) + Math.abs(ly - h / 2) / (h / 2) < 1 - inset / Math.min(w, h);
			case Hex:
				final slant = g.pointy ? (h - g.side) / 2 : (w - g.side) / 2;
				if (g.pointy) {
					final d = Math.abs(lx - w / 2) / (w / 2);
					ly > slant * d + inset && ly < h - slant * d - inset;
				} else {
					final d = Math.abs(ly - h / 2) / (h / 2);
					lx > slant * d + inset && lx < w - slant * d - inset;
				}
		};
	}

	public function testTheSquareGridIsTheOldArithmetic() {
		final g = TileGrid.square(16);
		for (cy in -3...4)
			for (cx in -3...4) {
				Assert.floatEquals(cx * 16, g.pixelX(cx, cy));
				Assert.floatEquals(cy * 16, g.pixelY(cx, cy));
				final cell = g.toCell(cx * 16 + 5.5, cy * 16 + 15.9);
				Assert.equals(cx, cell.x);
				Assert.equals(cy, cell.y);
				Assert.floatEquals(cx * 16 - 8, g.cornerX(cx, cy), "a corner tile half a tile up and left");
				Assert.floatEquals(cx * 16, g.frameX(cx, cy, 40), "a frame from the cell's top-left, whatever its size");
				Assert.floatEquals(cy * 16, g.frameY(cx, cy, 40));
			}
		final b = g.bounds(1, 2, 4, 6);
		Assert.floatEquals(16, b.xMin);
		Assert.floatEquals(32, b.yMin);
		Assert.floatEquals(64, b.xMax);
		Assert.floatEquals(96, b.yMax);
	}

	public function testIsometricCellsAreDiamondsFromTheOrigin() {
		final g = new TileGrid(Isometric, 32, 16);
		// cell (0, 0)'s top corner at the origin: its box from (-16, 0)
		Assert.floatEquals(-16, g.pixelX(0, 0));
		Assert.floatEquals(0, g.pixelY(0, 0));
		// cx runs down to the right, cy down to the left
		Assert.floatEquals(0, g.pixelX(1, 0));
		Assert.floatEquals(8, g.pixelY(1, 0));
		Assert.floatEquals(-32, g.pixelX(0, 1));
		Assert.floatEquals(8, g.pixelY(0, 1));
		final c = g.center(2, 1);
		Assert.floatEquals(16, c.x);
		Assert.floatEquals(32, c.y);
		// the box of a 2 by 3 rectangle from (1, 1): its left corner is (1, 4)'s, its right (3, 1)'s
		final b = g.bounds(1, 1, 3, 4);
		Assert.floatEquals(-48, b.xMin);
		Assert.floatEquals(16, b.yMin);
		Assert.floatEquals(32, b.xMax);
		Assert.floatEquals(56, b.yMax);
		// a corner autotile's tile is centred on the cell's top corner
		Assert.floatEquals(g.pixelX(2, 1), g.cornerX(2, 1));
		Assert.floatEquals(g.pixelY(2, 1) - 8, g.cornerY(2, 1));
	}

	public function testHexRowsAndColumnsArePushedAndSteppedBySide() {
		// Hexset: pointy hexes 32 wide and 28 high whose upright sides are 12: rows 20 apart
		final hexset = new TileGrid(Hex, 32, 28, true, true, 12);
		Assert.floatEquals(20, hexset.rowStep);
		Assert.floatEquals(32, hexset.columnStep);
		Assert.floatEquals(16, hexset.pixelX(0, 1), "odd rows pushed half a cell right");
		Assert.floatEquals(20, hexset.pixelY(0, 1));
		Assert.floatEquals(64, hexset.pixelX(2, 2));
		// unsaid, the side is half the box: three quarters of it a row, as a regular hex
		final regular = new TileGrid(Hex, 32, 28, true, false);
		Assert.floatEquals(21, regular.rowStep);
		Assert.floatEquals(16, regular.pixelX(0, 0), "even rows pushed");
		Assert.floatEquals(0, regular.pixelX(0, 1));
		final flat = new TileGrid(Hex, 28, 32, false, true);
		Assert.floatEquals(21, flat.columnStep);
		Assert.floatEquals(16, flat.pixelY(1, 0), "odd columns pushed half a cell down");
		Assert.floatEquals(0, flat.pixelY(2, 0));
	}

	public function testEveryPointOfACellGoesToIt() {
		for (entry in grids()) {
			final g = entry.grid;
			var wrong = 0;
			var first = "";
			for (cy in -4...5)
				for (cx in -4...5) {
					final c = g.center(cx, cy);
					final back = g.toCell(c.x, c.y);
					if (back.x != cx || back.y != cy) {
						if (wrong++ == 0) first = 'centre of ($cx, $cy) went to (${back.x}, ${back.y})';
					}
					// a grid of points over the box: those inside the drawn shape go to the cell
					final steps = 12;
					for (j in 0...steps + 1)
						for (i in 0...steps + 1) {
							final x = g.pixelX(cx, cy) + g.tileWidth * i / steps;
							final y = g.pixelY(cx, cy) + g.tileHeight * j / steps;
							if (!insideShape(g, cx, cy, x, y, 0.01))
								continue;
							final p = g.toCell(x, y);
							if (p.x != cx || p.y != cy) {
								if (wrong++ == 0) first = 'point $x, $y of ($cx, $cy) went to (${p.x}, ${p.y})';
							}
						}
				}
			Assert.equals(0, wrong, '${entry.name}: $first');
		}
	}

	public function testNeighboursGoBothWaysAndTouch() {
		for (entry in grids()) {
			final g = entry.grid;
			final n = g.neighbourCount;
			Assert.equals(g.kind == Hex ? 6 : 8, n, entry.name);
			for (cy in -3...4)
				for (cx in -3...4) {
					final around = g.neighbours(cx, cy);
					Assert.equals(n, around.length);
					for (d in 0...n) {
						final nb = around[d];
						// the opposite direction leads back
						final opposite = (d + Std.int(n / 2)) % n;
						Assert.equals(cx, g.neighbourX(nb.x, nb.y, opposite), '${entry.name}: ($cx, $cy) ${g.directionName(d)} and back, x');
						Assert.equals(cy, g.neighbourY(nb.x, nb.y, opposite), '${entry.name}: ($cx, $cy) ${g.directionName(d)} and back, y');
					}
					if (g.kind == Hex) {
						// the six are the six nearest cells: their middles all within reach of a step
						final c = g.center(cx, cy);
						for (nb in around) {
							final o = g.center(nb.x, nb.y);
							final dist = Math.sqrt((o.x - c.x) * (o.x - c.x) + (o.y - c.y) * (o.y - c.y));
							Assert.isTrue(dist < Math.max(g.tileWidth, g.tileHeight) * 1.01, '${entry.name}: ($cx, $cy) to (${nb.x}, ${nb.y}) is $dist');
						}
					}
				}
		}
		// pointy, odd rows pushed: a pushed row's NE is a column to the right, an unpushed row's is not
		final pointy = new TileGrid(Hex, 32, 28, true, true);
		Assert.equals(1, pointy.neighbourX(0, 1, 0));
		Assert.equals(0, pointy.neighbourY(0, 1, 0));
		Assert.equals(0, pointy.neighbourX(0, 2, 0));
		Assert.equals(1, pointy.neighbourY(0, 2, 0));
		Assert.equals("ne", pointy.directionName(0));
		Assert.equals("n", new TileGrid(Hex, 28, 32, false, true).directionName(0));
	}

	public function testBelowAndToward() {
		Assert.same([4], TileGrid.square(8).below());
		final iso = new TileGrid(Isometric, 32, 16);
		Assert.same([2, 4], iso.below(), "se and sw");
		Assert.equals(2, iso.towardDirection("se"));
		Assert.equals(4, iso.towardDirection("sw"));
		Assert.equals(-1, iso.towardDirection("down"), "down: every face below");
		Assert.same([2, 3], new TileGrid(Hex, 32, 28, true, true).below());
		Assert.same([2, 3, 4], new TileGrid(Hex, 28, 32, false, true).below());
		Assert.equals(3, new TileGrid(Hex, 28, 32, false, true).towardDirection("s"));
		Assert.equals(6, TileGrid.square(8).towardDirection("left"));
	}

	public function testAFrameStandsOnItsCellOffTheSquareGrid() {
		final g = new TileGrid(Hex, 32, 28, true, true, 12, 0, 14);
		// Hexset's 32 by 48 frames: the face's top 6 rows down the frame, 14 rows of side under it
		Assert.floatEquals(0, g.frameX(0, 0, 32));
		Assert.floatEquals(28 - 48 + 14, g.frameY(0, 0, 48), "standing on the box's bottom, then moved down 14");
		final iso = new TileGrid(Isometric, 132, 66);
		Assert.floatEquals(iso.pixelX(1, 1) + 2, iso.frameX(1, 1, 128), "centred");
		Assert.floatEquals(iso.pixelY(1, 1) + 66 - 99, iso.frameY(1, 1, 99), "standing on the bottom");
	}

	public function testTheTilesetSaysItsGrid() {
		final tileset = (grid:String) -> '
			#fp atlas2("Tileset/Minifantasy_ForgottenPlainsTiles.png") { grass: 32, 24, 8, 8 }
			#t tileset { $grid atlas: "fp" terrain grass { cells: "grass" } }
			#m tilemap { tileset: t size: 2, 2 legend { ".": grass } terrain: ["..", ".."] }
		';
		final iso = builderFromSource(tileset("grid: isometric, 32, 16")).buildTilemap("m");
		Assert.equals(Isometric, iso.grid.kind);
		Assert.equals(32, iso.tileSize);
		Assert.equals("isometric", iso.describe().grid.kind);
		final hex = builderFromSource(tileset("grid: hex, 32, 28, pointy, odd, 12  tileOffset: 0, 14")).buildTilemap("m");
		Assert.equals(Hex, hex.grid.kind);
		Assert.isTrue(hex.grid.pointy && hex.grid.odd);
		Assert.equals(12, hex.grid.side);
		Assert.equals(14, hex.grid.offsetY);
		final flat = builderFromSource(tileset("grid: hex, 28, 32, flat, even")).buildTilemap("m");
		Assert.isFalse(flat.grid.pointy || flat.grid.odd);
		Assert.equals(14, flat.grid.side, "half the width when unsaid");
		final square = builderFromSource(tileset("tileSize: 8")).buildTilemap("m");
		Assert.equals(Orthogonal, square.grid.kind);
		final cell = hex.toCell(hex.grid.center(1, 1).x, hex.grid.center(1, 1).y);
		Assert.equals(1, cell.x);
		Assert.equals(1, cell.y);

		for (bad in [
			{grid: "grid: hexagon, 32, 28", says: "grid: is orthogonal, isometric or hex"},
			{grid: "grid: hex, 32, 28, up, odd", says: "a hex is pointy or flat"},
			{grid: "grid: hex, 32, 28, pointy, third", says: "pushes the odd or the even rows"},
			{grid: "grid: hex, 32, 28, pointy, odd, 28", says: "has sides of 0 to 27 pixels"},
			{grid: "grid: isometric, 32, 0", says: "a cell is 1 pixel or more a side"},
			{grid: "tileSize: 8 grid: isometric, 32, 16", says: "tileSize: and grid: both say the size"},
			{grid: "tileSize: 8 lift: 4", says: "lift: is for the isometric and hex grids"},
			{grid: "grid: isometric, 32, 16 edge: e rise 1 { side: \"x\" toward: left }", says: "toward: on the isometric grid is down, se or sw"},
		]) {
			final message = parseExpectingError(tileset(bad.grid));
			Assert.notNull(message, bad.grid);
			if (message != null)
				Assert.stringContains(bad.says, message, bad.grid);
		}
	}
}
