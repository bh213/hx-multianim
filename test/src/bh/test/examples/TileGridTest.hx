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

	public function testTheHex64Index() {
		final g = new TileGrid(Hex, 32, 28, true, true);
		// cell (1, 1), a pushed row: NE (2, 0), E (2, 1), SE (2, 2), SW (1, 2), W (0, 1), NW (1, 0)
		final cells = [[0, 1, 1], [1, 1, 1], [0, 0, 1]];
		Assert.equals(1 | 2 | 4 | 16 | 32, bh.base.Autotile.getHexIndex(cells, 1, 1, g, 0, 0));
		// the same rows as map rows 1 to 3: row 1 of the grid is map row 2, not pushed, whose NE is (1, 1)
		Assert.equals(1 | 2 | 16, bh.base.Autotile.getHexIndex(cells, 1, 1, g, 0, 1));
		final flat = new TileGrid(Hex, 28, 32, false, true);
		Assert.equals(63, bh.base.Autotile.getHexIndex([[1, 1, 1], [1, 1, 1], [1, 1, 1]], 1, 1, flat, 0, 0));
		// the fallback: the fewest sides changed, more of them first, then the full hex, then the lone one
		final mapping = [0 => 0, 63 => 1, 3 => 2, 7 => 3];
		Assert.equals(3, bh.base.Autotile.getHex64FallbackChain(1, mapping).result);
		Assert.equals(7, bh.base.Autotile.getHex64FallbackChain(15, mapping).result);
		Assert.equals(63, bh.base.Autotile.getHex64FallbackChain(48, [63 => 0, 0 => 1]).result);
		Assert.equals(5, bh.base.Autotile.getHex64FallbackChain(5, [5 => 0]).result, "mapped: itself");
	}

	public function testAHexMapDrawsItsHex64TerrainATileACellBackToFront() {
		final map = builderFromSource('
			#ring autotile { format: hex64 tileSize: 16 demo: #224422, #44AA44 }
			#lone autotile { format: hex64 tileSize: 16 demo: #442222, #AA4444 }
			#t tileset { grid: hex, 16, 16, pointy, odd atlas: "none" terrain moss { autotile: ring } terrain mud { autotile: lone } }
			#m tilemap { tileset: t size: 4, 3 legend { ".": moss, "m": mud, " ": none } terrain: [" .. ", ".mm.", " .. "] }
		').buildTilemap("m");
		map.redraw();
		var drawn = 0;
		final parts:Array<Null<h2d.Object>> = @:privateAccess map.chunks[0].parts;
		for (part in parts)
			if (part != null)
				for (o in part)
					if (Std.isOfType(o, h2d.TileGroup)) drawn += (cast o : h2d.TileGroup).count();
		// moss under every cell of moss and mud (8), mud on its own two: one pass, back to front
		Assert.equals(10, drawn);
		Assert.equals("mud", map.terrainAt(1, 1));
		final c = map.grid.center(2, 1);
		final cell = map.toCell(c.x, c.y);
		Assert.equals(2, cell.x);
		Assert.equals(1, cell.y);
		Assert.equals("tilemap_grid", try {
			builderFromSource('
				#c autotile { format: corner tileSize: 16 demo: #224422, #44AA44 }
				#t tileset { grid: hex, 16, 16, pointy, odd atlas: "none" terrain moss { autotile: c } }
				#m tilemap { tileset: t size: 2, 2 legend { ".": moss } terrain: ["..", ".."] }
			').buildTilemap("m").redraw();
			null;
		} catch (e:bh.multianim.BuilderError) e.code, "the corner format has no hex form");
	}

	/** An isometric map of 32x16 diamonds over demo blocks 32 by 24 (8 pixels of side), lifted 8 a level. **/
	static function isoMap(levels:String, rows:String, ?layer:String = ""):bh.base.TileMap {
		final map = builderFromSource('
			#blocks atlas2("Tileset/Minifantasy_ForgottenPlainsTiles.png") {
				ground: 0, 0, 32, 24
				side: 32, 0, 32, 24
				house: 64, 0, 32, 40
				wide: 0, 24, 64, 48
			}
			#t tileset {
				grid: isometric, 32, 16
				tileOffset: 0, 8
				atlas: "blocks"
				terrain ground { cells: "ground" }
				rise any { side: "side" }
				cell house { draw: actors }
				cell wide { size: 2, 2 }
			}
			#m tilemap { tileset: t size: 4, 4 legend { ".": ground } terrain: ["....", "....", "....", "...."] $levels $layer }
		').buildTilemap("m");
		map.redraw();
		return map;
	}

	public function testObjectsAndRaisedCellsSortAmongTheActorsByTheirMiddle() {
		final map = isoMap("", "", 'layer things { legend { "h": house, "w": wide } rows: ["    ", " w  ", "    ", "  h "] }');
		final objects:Array<h2d.Object> = @:privateAccess map.chunks[0].objects;
		// the wide one (anchor (1, 1), its bottom-left: cells (1, 0) to (2, 1)) in four strips half a
		// cell wide, its footprint's half columns -1 to 2; then the house
		Assert.equals(5, objects.length, "the wide object's four strips and the house among the actors");
		// the house at (2, 3) sorts by its cell's middle
		final house = objects[4];
		Assert.floatEquals(map.grid.center(2, 3).y, house.y);
		// each strip by the front cell under it: half column -1 is (1, 1)'s alone, 0 and 1 the
		// footprint's front corner (2, 1), 2 (2, 0)'s alone
		final fronts = [[1, 1], [2, 1], [2, 1], [2, 0]];
		for (i in 0...4)
			Assert.floatEquals(map.grid.center(fronts[i][0], fronts[i][1]).y - 0.25, objects[i].y, 'strip $i');
		// an actor on the cell in front of the house (SE, (3, 3)) is drawn after it, one behind before
		final front = new h2d.Object();
		final behind = new h2d.Object();
		final c = map.grid.center(3, 3);
		front.setPosition(c.x, c.y);
		final b = map.grid.center(1, 3);
		behind.setPosition(b.x, b.y - map.grid.tileHeight / 2);
		map.addActor(front);
		map.addActor(behind);
		map.actors.ysort(0);
		Assert.isTrue(map.actors.getChildIndex(front) > map.actors.getChildIndex(house), "in front");
		Assert.isTrue(map.actors.getChildIndex(behind) < map.actors.getChildIndex(house), "behind");
	}

	public function testALongObjectSortsByTheFrontCellUnderEachStrip() {
		// a hall one cell by four, its anchor its top-left at (1, 0): cells (1, 0) to (1, 3)
		final map = builderFromSource('
			#blocks atlas2("Tileset/Minifantasy_ForgottenPlainsTiles.png") { ground: 0, 0, 32, 24  hall: 0, 0, 80, 60 }
			#t tileset { grid: isometric, 32, 16 tileOffset: 0, 8 atlas: "blocks" terrain ground { cells: "ground" } cell hall { size: 1, 4 anchor: 0, 0 } }
			#m tilemap { tileset: t size: 4, 6 legend { ".": ground } terrain: ["....", "....", "....", "....", "....", "...."]
				layer things { legend { "h": hall } rows: [" h  ", "    ", "    ", "    ", "    ", "    "] } }
		').buildTilemap("m");
		map.redraw();
		final strips:Array<h2d.Object> = @:privateAccess map.chunks[0].objects;
		// half columns x0 - y1 = -3 to x1 - y0 - 1 = 1, a strip each
		Assert.equals(5, strips.length);
		final k0 = -3;
		// actors standing on cells: in front of the long side's far end (E of (1, 0)), at its middle (E
		// of (1, 2)), in front of its front corner (S of (1, 3)); behind it (W of (1, 1), N of (1, 0))
		final cells = [
			{x: 2, y: 0, inFront: true},
			{x: 2, y: 2, inFront: true},
			{x: 1, y: 4, inFront: true},
			{x: 0, y: 1, inFront: false},
			{x: 1, y: -1, inFront: false},
		];
		final actors = [
			for (cell in cells) {
				final a = new h2d.Object();
				final p = map.grid.center(cell.x, cell.y);
				a.setPosition(p.x, p.y);
				map.addActor(a);
				a;
			}
		];
		// the footprint's middle, the one key it was sorted by, puts the first actor behind it
		final middle = (map.grid.bounds(1, 0, 2, 4).yMin + map.grid.bounds(1, 0, 2, 4).yMax) / 2;
		Assert.isTrue(actors[0].y < middle, "the far end's actor is above the footprint's middle");
		map.actors.ysort(0);
		for (i in 0...cells.length) {
			final cell = cells[i];
			// the strips the actor's cell is over: its half columns, cx - cy - 1 and cx - cy
			for (k in cell.x - cell.y - 1...cell.x - cell.y + 1) {
				final s = k - k0;
				if (s < 0 || s >= strips.length)
					continue;
				final after = map.actors.getChildIndex(actors[i]) > map.actors.getChildIndex(strips[s]);
				Assert.equals(cell.inFront, after, 'the actor on (${cell.x}, ${cell.y}) and the strip of half column $k');
			}
		}
	}

	/** The pixels a map draws, placed at (x, y) in a `w` by `h` picture. **/
	static function drawnPixels(map:bh.base.TileMap, x:Float, y:Float, w:Int, h:Int):hxd.Pixels {
		final scene = new h2d.Scene();
		scene.addChild(map);
		map.setPosition(x, y);
		map.cullNone();
		map.redraw();
		scene.syncOnly(0);
		final texture = new h3d.mat.Texture(w, h, [Target]);
		texture.clear(0xFF00FF);
		map.drawTo(texture);
		final pixels = texture.capturePixels();
		texture.dispose();
		map.remove();
		scene.dispose();
		pixels.convert(BGRA);
		return pixels;
	}

	public function testATrimmedSheetDrawsWhereTheWholeOneDoes() {
		// test/res/isohex/padded.png's frames have clear margins: padded.atlas2 lists them whole,
		// paddedTrimmed.atlas2 trimmed to their pixels (offset: from the left and bottom, orig: the whole size)
		final maps = [
			{
				name: "square",
				x: 10.0,
				y: 10.0,
				source: '
					#auto autotile { format: blob47 tileSize: 140 sheet: "$$atlas", prefix: "auto" allowPartialMapping: true mapping: [46: 0] }
					#t tileset { tileSize: 140 atlas: "$$atlas" terrain plaza { cells: "plaza" } terrain park { autotile: auto }
						cell house { draw: actors } }
					#m tilemap { tileset: t size: 4, 3 legend { ".": plaza, "p": park } terrain: [".pp.", ".pp.", "...."]
						layer things { legend { "h": house, "m": man } rows: ["h   ", " m  ", "  h "] } }
				',
			},
			{
				name: "isometric",
				x: 420.0,
				y: 160.0,
				source: '
					#auto autotile { format: blob47 tileSize: 132 sheet: "$$atlas", prefix: "auto" allowPartialMapping: true mapping: [46: 0] }
					#t tileset { grid: isometric, 132, 66 tileOffset: 0, 33 atlas: "$$atlas" terrain plaza { cells: "plaza" } terrain park { autotile: auto }
						rise any { side: "cliff" } cell house { size: 2, 1 } cell man { draw: actors } }
					#m tilemap { tileset: t size: 3, 3 legend { ".": plaza, "p": park } terrain: ["...", ".p.", "..."]
						layer things { legend { "h": house, "m": man } rows: ["h  ", "  m", " m "] }
						levels: ["000", "001", "010"] }
				',
			},
			{
				name: "hex",
				x: 20.0,
				y: 30.0,
				source: '
					#t tileset { grid: hex, 32, 28, pointy, odd, 12 tileOffset: 0, 14 atlas: "$$atlas" terrain temperate { cells: "temperate" }
						terrain desert { cells: "desert" } rise any { side: "desert" } cell man { draw: actors } }
					#m tilemap { tileset: t size: 4, 3 legend { ".": temperate, "d": desert } terrain: ["..d.", ".dd.", "...."]
						layer people { legend { "m": man } rows: ["  m ", "m   ", "    "] }
						levels: ["0000", "0100", "0000"] }
				',
			},
		];
		for (m in maps) {
			final whole = drawnPixels(builderFromSource(StringTools.replace(m.source, "$atlas", "isohex/padded")).buildTilemap("m"), m.x, m.y, 800, 600);
			final trimmed = drawnPixels(builderFromSource(StringTools.replace(m.source, "$atlas", "isohex/paddedTrimmed")).buildTilemap("m"), m.x, m.y, 800, 600);
			var drawn = 0;
			var differ = 0;
			var first = "";
			for (y in 0...whole.height)
				for (x in 0...whole.width) {
					final p = whole.getPixel(x, y);
					if (p != 0xFFFF00FF)
						drawn++;
					if (trimmed.getPixel(x, y) != p) {
						if (differ == 0)
							first = 'first at $x, $y';
						differ++;
					}
				}
			Assert.isTrue(drawn > 5000, '${m.name}: the map draws ($drawn pixels)');
			Assert.equals(0, differ, '${m.name}: the trimmed sheet draws as the whole one ($first)');
		}
	}

	/** An isometric map over blocks whose rise has its ends and metadata (`rise any { … }` as given), its levels as given. **/
	static function liftedMap(rise:String, levels:Array<String>, ?more:String = ""):bh.base.TileMap {
		final rows = [for (r in levels) '"' + StringTools.lpad("", ".", r.length) + '"'].join(", ");
		final map = builderFromSource('
			#blocks atlas2("Tileset/Minifantasy_ForgottenPlainsTiles.png") {
				ground: 0, 0, 32, 24  side: 32, 0, 32, 24  L: 64, 0, 32, 24  R: 96, 0, 32, 24  S: 128, 0, 32, 24  top0: 32, 24, 32, 24
			}
			#lip autotile { format: blob47 tileSize: 32 sheet: "blocks", prefix: "top" allowPartialMapping: true mapping: [46: 0] }
			#t tileset {
				grid: isometric, 32, 16
				tileOffset: 0, 8
				atlas: "blocks"
				terrain ground { cells: "ground" }
				$rise
				$more
			}
			#m tilemap { tileset: t size: ${levels[0].length}, ${levels.length} legend { ".": ground } terrain: [$rows] levels: [${[for (r in levels) '"$r"'].join(", ")}] }
		').buildTilemap("m");
		return map;
	}

	public function testALiftedCellHasItsSideAndItsRisesMetadata() {
		final levels = ["00000", "02100", "00100", "00000"];
		final map = liftedMap('rise any { side: "side" metadata { cliff:bool => true } }', levels);
		// read before anything is drawn, then after
		for (pass in 0...2) {
			if (pass == 1)
				map.redraw();
			// (1, 1), two up: its S neighbour (1, 2) is the ground, its E one (2, 1) one up: down drops two
			Assert.equals(2, map.sideAt(1, 1), "the most levels its side drops");
			Assert.equals(1, map.sideAt(2, 1));
			Assert.equals(1, map.sideAt(2, 2));
			Assert.equals(0, map.sideAt(0, 0), "the ground has none");
			Assert.isTrue(map.metadataAt(1, 1).getBoolOrDefault("cliff", false), "the rise's metadata is on the raised cell");
			Assert.isFalse(map.metadataAt(1, 2).getBoolOrDefault("cliff", false), "not on the cell in front of it");
		}
		map.setLevel(1, 1, 0);
		Assert.equals(0, map.sideAt(1, 1), "a level changed: worked out again");
		Assert.isFalse(map.metadataAt(1, 1).getBoolOrDefault("cliff", false));
		Assert.equals(1, map.sideAt(2, 1));
	}

	public function testARunOfSidesHasItsEndsOnTheIsometricGrid() {
		// a plateau of 3 by 3 one level up and a lone raised cell
		final levels = ["000000", "011100", "011100", "011100", "000000", "000010"];
		final map = liftedMap('rise any { side: "side" left: "L" right: "R" single: "S" }', levels);
		map.redraw();
		function piece(cx:Int, cy:Int):String
			return @:privateAccess map.liftedPiece(cx, cy, 0, -1, 0);
		// down: the front runs from the plateau's left corner along its sw faces to its bottom corner,
		// then along its se faces to its right corner
		Assert.equals("L", piece(1, 3), "the left end: its left corner");
		Assert.equals("side", piece(2, 3));
		Assert.equals("side", piece(3, 3), "the bottom corner, both faces");
		Assert.equals("side", piece(3, 2));
		Assert.equals("R", piece(3, 1), "the right end: its right corner");
		Assert.equals("S", piece(4, 5), "a lone cell");
		// one face: an se face's run goes along cy, its left end the lowest on screen
		final se = liftedMap('rise any { side: "side" left: "L" right: "R" single: "S" toward: se }', levels);
		se.redraw();
		function sePiece(cx:Int, cy:Int):String
			return @:privateAccess se.liftedPiece(cx, cy, 0, 2, 0);
		Assert.equals("L", sePiece(3, 3));
		Assert.equals("side", sePiece(3, 2));
		Assert.equals("R", sePiece(3, 1));
		final sw = liftedMap('rise any { side: "side" left: "L" right: "R" single: "S" toward: sw }', levels);
		sw.redraw();
		function swPiece(cx:Int, cy:Int):String
			return @:privateAccess sw.liftedPiece(cx, cy, 0, 4, 0);
		Assert.equals("L", swPiece(1, 3));
		Assert.equals("side", swPiece(2, 3));
		Assert.equals("R", swPiece(3, 3));
		// a run is a level of side's: a cell two up beside one up goes on with its run below and
		// ends its own above
		final step = liftedMap('rise any { side: "side" left: "L" right: "R" single: "S" }', ["0000", "0120", "0000"]);
		step.redraw();
		Assert.equals("L", @:privateAccess step.liftedPiece(1, 1, 0, -1, 0, 0));
		Assert.equals("R", @:privateAccess step.liftedPiece(2, 1, 0, -1, 0, 0), "the lower piece goes on from the cell one up");
		Assert.equals("S", @:privateAccess step.liftedPiece(2, 1, 0, -1, 0, 1), "the upper piece stands alone");
	}

	/** A map of blocks on hexes (pointy 32x28 or flat 28x32, side 12, 14 rows of side) whose rise is as given, its levels as given. **/
	static function hexLiftedMap(rise:String, levels:Array<String>, pointy:Bool, ?more:String = "", ?layer:String = ""):bh.base.TileMap {
		final rows = [for (r in levels) '"' + StringTools.lpad("", ".", r.length) + '"'].join(", ");
		final grid = pointy ? "grid: hex, 32, 28, pointy, odd, 12" : "grid: hex, 28, 32, flat, odd, 12";
		final map = builderFromSource('
			#blocks atlas2("Tileset/Minifantasy_ForgottenPlainsTiles.png") {
				ground: 0, 0, 32, 42  side: 32, 0, 32, 42  L: 64, 0, 32, 42  R: 96, 0, 32, 42  S: 128, 0, 32, 42  tower: 0, 42, 80, 100
			}
			#t tileset { $grid tileOffset: 0, 14 atlas: "blocks" terrain ground { cells: "ground" } $rise $more }
			#m tilemap { tileset: t size: ${levels[0].length}, ${levels.length} legend { ".": ground } terrain: [$rows]
				levels: [${[for (r in levels) '"$r"'].join(", ")}] $layer }
		').buildTilemap("m");
		map.redraw();
		return map;
	}

	public function testARunOfSidesHasItsEndsOnTheHexGrid() {
		// pointy hexes, odd rows pushed right: a plateau of 3 by 2 one up and a lone raised cell. Row 2
		// shows both faces; of row 1 only (3, 1), pushed past row 2's end, shows its se face
		final levels = ["000000", "011100", "011100", "000000", "000010"];
		final ends = 'left: "L" right: "R" single: "S"';
		final down = hexLiftedMap('rise any { side: "side" $ends }', levels, true);
		function piece(map:bh.base.TileMap, cx:Int, cy:Int, toward:Int):String
			return @:privateAccess map.liftedPiece(cx, cy, 0, toward, 0);
		// the lower outline runs from (1, 2)'s sw face along row 2's faces, up (3, 2)'s upright side to (3, 1)'s se face
		Assert.equals("L", piece(down, 1, 2, -1), "the left end");
		Assert.equals("side", piece(down, 2, 2, -1));
		Assert.equals("side", piece(down, 3, 2, -1), "goes on up its upright side");
		Assert.equals("R", piece(down, 3, 1, -1), "the right end: the pushed row's last face");
		Assert.equals("S", piece(down, 4, 4, -1), "a lone cell");
		Assert.equals(0, down.sideAt(1, 1), "the back row's cells show no face");
		// one face: its run goes along the outline as far as the same face shows
		final se = hexLiftedMap('rise any { side: "side" $ends toward: se }', levels, true);
		Assert.equals("L", piece(se, 1, 2, 2));
		Assert.equals("side", piece(se, 3, 2, 2));
		Assert.equals("R", piece(se, 3, 1, 2));
		final sw = hexLiftedMap('rise any { side: "side" $ends toward: sw }', levels, true);
		Assert.equals("L", piece(sw, 1, 2, 3));
		Assert.equals("side", piece(sw, 2, 2, 3));
		Assert.equals("R", piece(sw, 3, 2, 3), "(3, 1) above it shows no sw face");
		// flat hexes, odd columns pushed down: the pushed columns' faces stand out at the ends, two
		// cells each, the left ones going on toward the middle and the right ones from it
		final flat = hexLiftedMap('rise any { side: "side" $ends }', ["00000", "01110", "01110", "00000", "00000"], false);
		Assert.equals("L", piece(flat, 1, 1, -1), "its sw face, over the one below");
		Assert.equals("L", piece(flat, 1, 2, -1));
		Assert.equals("side", piece(flat, 2, 2, -1), "the middle column's s face");
		Assert.equals("R", piece(flat, 3, 2, -1));
		Assert.equals("R", piece(flat, 3, 1, -1));
		// two up beside one up, a level of side at a time
		final step = hexLiftedMap('rise any { side: "side" $ends }', ["0000", "0120", "0000"], true);
		Assert.equals("L", @:privateAccess step.liftedPiece(1, 1, 0, -1, 0, 0));
		Assert.equals("R", @:privateAccess step.liftedPiece(2, 1, 0, -1, 0, 0));
		Assert.equals("S", @:privateAccess step.liftedPiece(2, 1, 0, -1, 0, 1));
	}

	public function testALongObjectOnTheHexGridSortsByTheFrontCellUnderEachStrip() {
		// a tower 2 cells by 4 on pointy hexes, its anchor its top-left at (1, 2): rows 2 to 5, rows 3
		// and 5 pushed right half a cell, so its front row's last cell juts out past row 4's
		final map = hexLiftedMap("", ["00000", "00000", "00000", "00000", "00000", "00000", "00000"], true, "cell tower { size: 2, 4 anchor: 0, 0 }",
			'layer things { legend { "t": tower } rows: ["     ", "     ", " t   ", "     ", "     ", "     ", "     "] }');
		final strips:Array<h2d.Object> = @:privateAccess map.chunks[0].objects;
		// the half column only rows 2 and 4 cover (32 to 48), then the rest, whose front is row 5
		Assert.equals(2, strips.length, "a strip for each front row");
		Assert.floatEquals(map.grid.center(1, 4).y - 0.25, strips[0].y);
		Assert.floatEquals(map.grid.center(1, 5).y - 0.25, strips[1].y);
		// the pieces put together are the whole frame
		final first = cast(strips[0], h2d.Bitmap).tile;
		final second = cast(strips[1], h2d.Bitmap).tile;
		Assert.floatEquals(16, first.width);
		Assert.floatEquals(64, second.width);
		Assert.floatEquals(first.dx + 16, second.dx);
		// actors on cells: beside row 4 on the right, over the front row's corner (behind it; in front of
		// the left end, row 4's, which it is not over); in front of the tower and of its left end; behind it
		final cells = [
			{x: 3, y: 4, inFront: [true, false]},
			{x: 1, y: 6, inFront: [true, true]},
			{x: 0, y: 5, inFront: [true, true]},
			{x: 1, y: 1, inFront: [false, false]},
		];
		final actors = [
			for (cell in cells) {
				final a = new h2d.Object();
				final p = map.grid.center(cell.x, cell.y);
				a.setPosition(p.x, p.y);
				map.addActor(a);
				a;
			}
		];
		// the footprint's middle, the one key it was sorted by, puts the first actor in front of it all
		final box = map.grid.bounds(1, 2, 3, 6);
		Assert.isTrue(actors[0].y > (box.yMin + box.yMax) / 2, "the actor beside row 4 is below the footprint's middle");
		map.actors.ysort(0);
		for (i in 0...cells.length)
			for (s in 0...2) {
				final after = map.actors.getChildIndex(actors[i]) > map.actors.getChildIndex(strips[s]);
				Assert.equals(cells[i].inFront[s], after, 'the actor on (${cells[i].x}, ${cells[i].y}) and strip $s');
			}
	}

	public function testAFacePieceStandsAgainstItsSideOfTheCell() {
		final iso = new TileGrid(Isometric, 32, 16, true, true, null, 0, 8);
		// se, the right face: a piece half the cell wide against the box's right
		Assert.floatEquals(iso.pixelX(1, 1) + 16, iso.faceX(1, 1, 2, 16));
		Assert.floatEquals(iso.pixelX(1, 1), iso.faceX(1, 1, 4, 16), "sw, against its left");
		Assert.floatEquals(iso.frameX(1, 1, 32), iso.faceX(1, 1, 2, 32), "a whole cell's frame where a frame goes");
		Assert.floatEquals(iso.frameX(1, 1, 32), iso.faceX(1, 1, 4, 32));
		final pointy = new TileGrid(Hex, 32, 28, true, true, 12);
		Assert.equals(1, pointy.faceSide(2));
		Assert.equals(-1, pointy.faceSide(3));
		final flat = new TileGrid(Hex, 28, 32, false, true);
		Assert.equals(0, flat.faceSide(3), "a flat hex's s: the bottom");
		Assert.equals(-1, flat.faceSide(4));
	}

	public function testALiftedMapDrawsItsEdgeAndAPlatformsTopOnTheRaisedCells() {
		final levels = ["00000", "01100", "01100", "00000"];
		final count = (map:bh.base.TileMap, cx:Int, cy:Int) -> {
			final column:Null<Dynamic> = @:privateAccess map.columnOf.get(cy * map.width + cx);
			var n = 0;
			if (column != null)
				for (g in (column.object : h2d.Object))
					if (Std.isOfType(g, h2d.TileGroup)) n += (cast g : h2d.TileGroup).count();
			n;
		};
		final plain = liftedMap('rise any { side: "side" }', levels);
		plain.redraw();
		Assert.equals(1, count(plain, 1, 1), "its terrain lifted, no edge");
		final edged = liftedMap('rise any { side: "side" }', levels, "edge: lip");
		edged.redraw();
		Assert.equals(2, count(edged, 1, 1), "its terrain and the level's edge on it");
		// a platform: its top over every cell of it
		final roofed = builderFromSource('
			#blocks atlas2("Tileset/Minifantasy_ForgottenPlainsTiles.png") { ground: 0, 0, 32, 24  side: 32, 0, 32, 24  top0: 32, 24, 32, 24 }
			#lip autotile { format: blob47 tileSize: 32 sheet: "blocks", prefix: "top" allowPartialMapping: true mapping: [46: 0] }
			#t tileset { grid: isometric, 32, 16 tileOffset: 0, 8 atlas: "blocks" terrain ground { cells: "ground" }
				platform roof { edge: lip rise any { side: "side" } } }
			#m tilemap { tileset: t size: 4, 4 legend { ".": ground } terrain: ["....", "....", "....", "...."]
				levels { legend { "r": 1 roof } rows: ["0000", "0rr0", "0rr0", "0000"] } }
		').buildTilemap("m");
		roofed.redraw();
		for (cell in [[1, 1], [2, 1], [1, 2], [2, 2]])
			Assert.equals(2, count(roofed, cell[0], cell[1]), 'the roof\'s top on (${cell[0]}, ${cell[1]})');
	}

	public function testAnAnimatedTerrainIsDrawnInItsPlaceBackToFront() {
		// the ground, then water over it, animated: a row of water between two rows of ground
		final map = builderFromSource('
			#blocks atlas2("Tileset/Minifantasy_ForgottenPlainsTiles.png") { ground: 0, 0, 32, 24  wetA0: 32, 0, 32, 24  wetB0: 64, 0, 32, 24 }
			#w0 autotile { format: blob47 tileSize: 32 sheet: "blocks", prefix: "wetA" allowPartialMapping: true mapping: [46: 0] }
			#w1 autotile { format: blob47 tileSize: 32 sheet: "blocks", prefix: "wetB" allowPartialMapping: true mapping: [46: 0] }
			#t tileset { grid: isometric, 32, 16 tileOffset: 0, 8 atlas: "blocks" terrain ground { cells: "ground" } terrain water { autotile: w0, w1 duration: 100 } }
			#m tilemap { tileset: t size: 3, 3 legend { ".": ground, "~": water } terrain: ["...", "~~~", "..."] }
		').buildTilemap("m");
		map.redraw();
		final animated:Array<{terrain:Int, frames:Array<h2d.Object>}> = @:privateAccess map.chunks[0].animated;
		Assert.equals(1, animated.length, "one run of the water");
		final run = animated[0].frames;
		Assert.equals(2, run.length, "a frame each");
		final part = run[0].parent;
		function tiles(o:h2d.Object):Int {
			var n = 0;
			for (g in o)
				if (Std.isOfType(g, h2d.TileGroup)) n += (cast g : h2d.TileGroup).count();
			return n;
		}
		// the row behind and the ground under the first water cell, still; then the run, its frames
		// each with the water and the ground after it, in front of it
		Assert.equals(3, part.numChildren);
		Assert.isTrue(Std.isOfType(part.getChildAt(0), h2d.TileGroup));
		Assert.equals(4, (cast part.getChildAt(0) : h2d.TileGroup).count(), "the row behind and the ground under (0, 1)");
		Assert.equals(run[0], part.getChildAt(1));
		Assert.equals(run[1], part.getChildAt(2));
		Assert.equals(3 + 2 + 3, tiles(run[0]), "the water, the ground under the rest of it and the row in front");
		Assert.equals(3 + 2 + 3, tiles(run[1]));
		Assert.isTrue(run[0].visible && !run[1].visible, "its first frame shown");
		@:privateAccess map.step(0.15);
		Assert.isTrue(!run[0].visible && run[1].visible, "its next frame shown as the clock goes");
	}

	public function testARaisedCellIsLiftedAndItsTopIsWhereThePointerIs() {
		final map = isoMap('levels: ["0000", "0120", "0000", "0000"]', "");
		Assert.floatEquals(8, map.lift, "half the diamond's height when unsaid");
		Assert.floatEquals(16, map.liftAt(2, 1));
		Assert.floatEquals(0, map.liftAt(0, 0));
		// each raised cell is a column among the actors, sorted by its middle on the ground
		final columns:Array<h2d.Object> = @:privateAccess map.chunks[0].objects;
		Assert.equals(2, columns.length);
		Assert.floatEquals(map.grid.center(1, 1).y - 0.5, columns[0].y);
		// the top of (2, 1), two levels up: the pointer on it finds it, not the ground it is drawn over
		final top = map.grid.center(2, 1);
		final atTop = map.toCell(top.x, top.y - 16);
		Assert.equals(2, atTop.x);
		Assert.equals(1, atTop.y);
		// the point the top hides of the cell behind it, (1, 0), is (2, 1)'s too
		final hidden = map.grid.center(1, 0);
		final atHidden = map.toCell(hidden.x, hidden.y);
		Assert.equals(2, atHidden.x, "hidden behind the raised cell");
		Assert.equals(1, atHidden.y);
		// on its side, below its top: still (2, 1)
		final side = map.toCell(top.x, top.y);
		Assert.equals(2, side.x);
		Assert.equals(1, side.y);
		// the ground away from it: the cell there
		final ground = map.grid.center(0, 3);
		final atGround = map.toCell(ground.x, ground.y);
		Assert.equals(0, atGround.x);
		Assert.equals(3, atGround.y);
		// the map is drawn again as a level changes, its columns with it
		map.setLevel(2, 1, 0);
		map.redraw();
		Assert.equals(1, (@:privateAccess map.chunks[0].objects : Array<h2d.Object>).length);
		Assert.equals("tilemap_rise", try {
			builderFromSource('
				#blocks atlas2("Tileset/Minifantasy_ForgottenPlainsTiles.png") { ground: 0, 0, 32, 24 side: 32, 0, 32, 24 }
				#t tileset { grid: isometric, 32, 16 atlas: "blocks" terrain ground { cells: "ground" } rise 1 { side: "side" } }
				#m tilemap { tileset: t size: 2, 2 legend { ".": ground } terrain: ["..", ".."] levels: ["20", "00"] }
			').buildTilemap("m");
			null;
		} catch (e:bh.multianim.BuilderError) e.code, "two levels above the map's edge and its neighbours, with a rise of one only");
	}

	public function testACellsBottomIsItsLowerOutline() {
		// isometric 32x16 at (0, 0): box (-16, 0) to (16, 16), the left and right corners 8 down, the bottom one 16
		final iso = new TileGrid(Isometric, 32, 16);
		Assert.floatEquals(8, iso.bottomAt(0, 0, -16));
		Assert.floatEquals(12, iso.bottomAt(0, 0, -8));
		Assert.floatEquals(16, iso.bottomAt(0, 0, 0));
		Assert.floatEquals(8, iso.bottomAt(0, 0, 40), "past the box: held to it");
		// a pointy hex 32x28 with sides of 12: its lower corners 20 down, its bottom one 28
		final pointy = new TileGrid(Hex, 32, 28, true, true, 12);
		Assert.floatEquals(20, pointy.bottomAt(0, 0, 0));
		Assert.floatEquals(28, pointy.bottomAt(0, 0, 16));
		// a flat hex 28x32 with sides of 12: its side corners half down, its bottom edge level from 8 to 20
		final flat = new TileGrid(Hex, 28, 32, false, true, 12);
		Assert.floatEquals(16, flat.bottomAt(0, 0, 0));
		Assert.floatEquals(32, flat.bottomAt(0, 0, 8));
		Assert.floatEquals(32, flat.bottomAt(0, 0, 14));
		Assert.floatEquals(24, flat.bottomAt(0, 0, 24));
		Assert.floatEquals(8, TileGrid.square(8).bottomAt(1, 0, 10));
	}

	/** How many pixels of two pictures of a map drawn at (x, y) differ inside the cells' shapes (their edges, `inset` wide, left out). **/
	static function differInside(a:hxd.Pixels, b:hxd.Pixels, grid:TileGrid, x:Float, y:Float, cells:Array<Array<Int>>, inset = 1.5):Int {
		var differ = 0;
		for (py in 0...a.height)
			for (px in 0...a.width)
				for (c in cells)
					if (insideShape(grid, c[0], c[1], px - x, py - y, inset)) {
						if (a.getPixel(px, py) != b.getPixel(px, py))
							differ++;
						break;
					}
		return differ;
	}

	public function testACellOfAnEarlierTerrainIsNeverDrawnOverTheBlockInFrontOfIt() {
		// hx-multianim request 35 (Kenney's Isometric City, imported on its grid): blocks 132 wide whose
		// side hangs 33 pixels under their top, the terrains declared grass_bed, asphalt, then park.
		// Off the square grid each row's cells are drawn in their column's order, each cell's terrains
		// bottom first, so a cell of any terrain is drawn before the cells in front of it: their tops
		// cover its side. Drawn with or without the cells behind a cell, its top is the same
		final map = (rows:Array<String>) -> builderFromSource('
			#t tileset { grid: isometric, 132, 66 tileOffset: 0, 33 atlas: "isohex/isoCity"
				terrain grass_bed { cells: "plaza" } terrain asphalt { cells: "asphalt" } terrain park { cells: "treeBlock" } }
			#m tilemap { tileset: t size: ${rows[0].length}, ${rows.length} legend { "g": grass_bed, "a": asphalt, "t": park, " ": none }
				terrain: [${[for (r in rows) '"$r"'].join(", ")}] }
		').buildTilemap("m");
		final x = 210.0, y = 20.0;
		final grid = map(["ag", "ga"]).grid;

		// the asphalt at (0, 0) is behind the grass at (1, 0), its side under that block's top
		final asphaltAlone = drawnPixels(map(["a ", "  "]), x, y, 420, 320);
		var under = 0;
		for (py in 0...asphaltAlone.height)
			for (px in 0...asphaltAlone.width)
				if (insideShape(grid, 1, 0, px - x, py - y, 1.5) && asphaltAlone.getPixel(px, py) != 0xFFFF00FF)
					under++;
		Assert.isTrue(under > 500, 'precondition: the asphalt block\'s side reaches under (1, 0)\'s top ($under pixels)');
		final full = drawnPixels(map(["ag", "ga"]), x, y, 420, 320);
		final withoutIt = drawnPixels(map([" g", "ga"]), x, y, 420, 320);
		Assert.equals(0, differInside(full, withoutIt, grid, x, y, [[1, 0]]), "the 2x2 map: (1, 0)'s top whole, the asphalt behind it drawn first");

		// every cell of a map of three terrains, one declared last among the earlier ones
		final rows = ["gat", "tga", "atg"];
		final whole = drawnPixels(map(rows), x, y, 420, 320);
		for (cy in 0...3)
			for (cx in 0...3) {
				// the cells behind (cx, cy), drawn before it, taken away
				final behind = [
					for (ry in 0...3) [for (rx in 0...3) (rx <= cx && ry <= cy && !(rx == cx && ry == cy)) ? " " : rows[ry].charAt(rx)].join("")
				];
				final alone = drawnPixels(map(behind), x, y, 420, 320);
				// 4 pixels in from the diamond's edge: an asphalt top's soft edge shows what is behind it
				Assert.equals(0, differInside(whole, alone, grid, x, y, [[cx, cy]], 4), '($cx, $cy), a ${rows[cy].charAt(cx)}: its top drawn over what is behind it');
			}
	}

	public function testARaisedCellsLowestSideIsUnderTheCellsInFront() {
		// a raised cell is a stack: its terrain's block on top, a rise's piece a level under it. The
		// lowest piece hangs below the ground as any block's side does, over the tops of the cells in
		// front: drawn in its place, back to front, they cover it, so their tops are drawn as with
		// nothing raised (drawn after the ground it showed a level of side too many)
		final iso = (levels:String) -> builderFromSource('
			#t tileset { grid: isometric, 32, 16 tileOffset: 0, 8 atlas: "isohex/lifted" terrain grass { cells: "grass" } rise any { side: "sideMid" } }
			#m tilemap { tileset: t size: 3, 4 legend { ".": grass } terrain: ["...", "...", "...", "..."] levels: [$levels] }
		').buildTilemap("m");
		final hex = (levels:String) -> builderFromSource('
			#t tileset { grid: hex, 32, 28, pointy, odd, 12 tileOffset: 0, 14 atlas: "isohex/hexset" terrain temperate { cells: "temperate" }
				rise any { side: "desert" } }
			#m tilemap { tileset: t size: 3, 3 legend { ".": temperate } terrain: ["...", "...", "..."] levels: [$levels] }
		').buildTilemap("m");
		final cases = [
			{name: "isometric", flat: iso('"000", "000", "000", "000"'), raised: iso('"000", "010", "000", "000"'), x: 70.0, y: 20.0},
			{name: "pointy hex", flat: hex('"000", "000", "000"'), raised: hex('"000", "010", "000"'), x: 8.0, y: 30.0},
		];
		for (k in cases) {
			final grid = k.raised.grid;
			final front = [for (d in grid.below()) [grid.neighbourX(1, 1, d), grid.neighbourY(1, 1, d)]];
			// on the isometric grid the cell straight below too, under the raised cell's bottom corner
			if (grid.kind == Isometric)
				front.push([2, 2]);
			final flat = drawnPixels(k.flat, k.x, k.y, 140, 120);
			final raised = drawnPixels(k.raised, k.x, k.y, 140, 120);
			Assert.equals(0, differInside(flat, raised, grid, k.x, k.y, front), '${k.name}: the tops of the cells in front of the raised one');
			Assert.isTrue(differInside(flat, raised, grid, k.x, k.y, [[1, 1]]) > 0, '${k.name}: the raised cell is drawn lifted');
		}
	}

	public function testWhatACellStandingOnTheGroundDrawsBelowItIsTheGrounds() {
		// a cell standing among the actors whose frame reaches below its cell's top (a building drawn on
		// its own block): that part is drawn with the ground in its place, under the cells in front.
		// Standing there as the ground's own block, it changes no pixel
		final map = (layer:String) -> builderFromSource('
			#t tileset { grid: isometric, 32, 16 tileOffset: 0, 8 atlas: "isohex/lifted" terrain grass { cells: "grass" } }
			#m tilemap { tileset: t size: 3, 4 legend { ".": grass } terrain: ["...", "...", "...", "..."] $layer }
		').buildTilemap("m");
		final ground = drawnPixels(map(""), 70, 20, 140, 120);
		final standing = map('layer things { draw: actors legend { "b": grass } rows: ["   ", " b ", "   ", "   "] }');
		final drawn = drawnPixels(standing, 70, 20, 140, 120);
		var differ = 0;
		for (py in 0...ground.height)
			for (px in 0...ground.width)
				if (ground.getPixel(px, py) != drawn.getPixel(px, py))
					differ++;
		Assert.equals(0, differ, "the block standing on (1, 1) draws as the ground there");
		Assert.equals(1, (@:privateAccess standing.chunks[0].objects : Array<h2d.Object>).length, "what stands is among the actors");
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
