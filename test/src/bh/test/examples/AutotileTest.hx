package bh.test.examples;

import utest.Assert;
import bh.base.Autotile;
import bh.multianim.BuilderError;
import bh.multianim.MultiAnimBuilder;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.builderFromSource;
import bh.test.BuilderTestBase.parseExpectingError;
import bh.test.BuilderTestBase.parseExpectingSuccess;

/**
 * Non-visual autotile tests: index math (bh.base.Autotile), parse-time validation of
 * `autotile {}` blocks, and the builder's tile resolution (mapping, fallback, bounds, caching).
 * Visual coverage lives in tests 24, 25, 28, 29, 30 and 153.
 */
class AutotileTest extends BuilderTestBase {
	static inline var TILESET = "Tileset/Minifantasy_ForgottenPlainsTiles.png"; // 552x184, 8px tiles

	// ==================== Index math ====================

	@Test
	public function testBlob47LookupCoversAll47AndRoundTrips():Void {
		final seen = new Map<Int, Bool>();
		var bad = 0;
		for (mask in 0...256) {
			final index = Autotile.getBlob47Index(mask);
			if (index < 0 || index >= Autotile.BLOB47_TILE_COUNT) {
				bad++;
				continue;
			}
			seen.set(index, true);
			final reduced = Autotile.getBlob47Mask(index);
			// The reduced mask only drops bits, and maps back to the same tile
			if ((reduced & mask) != reduced || Autotile.getBlob47Index(reduced) != index)
				bad++;
		}
		Assert.equals(0, bad, "every mask maps to a tile whose reduced mask round-trips");
		Assert.equals(Autotile.BLOB47_TILE_COUNT, [for (k in seen.keys()) k].length, "all 47 tiles reachable");
	}

	@Test
	public function testCornerIndex():Void {
		final grid = [[1, 0], [0, 1]];
		Assert.equals(Autotile.CORNER_SE, Autotile.getCornerIndex(grid, 0, 0), "cell (0,0) is SE of corner (0,0)");
		Assert.equals(Autotile.CORNER_NW | Autotile.CORNER_SE, Autotile.getCornerIndex(grid, 1, 1), "diagonal touch");
		Assert.equals(Autotile.CORNER_NW, Autotile.getCornerIndex(grid, 2, 2), "bottom-right corner of the grid");
		Assert.equals(Autotile.CORNER_SW, Autotile.getCornerIndex(grid, 1, 0), "top edge corner between cells 0 and 1");
		Assert.equals(0, Autotile.getCornerIndex(grid, 2, 0), "no filled cell around it");
	}

	@Test
	public function testNeighborMaskNonZeroIsFilledRaggedRowsAreEmpty():Void {
		final grid = [[2, 5, 1], [7]];
		// (0,0): E = 5, S = 7 (non-1 values count), SE is past the end of the short row
		Assert.equals(Autotile.E | Autotile.S, Autotile.getNeighborMask8(grid, 0, 0));
		// (2,0): W = 5, SW = row 1 has no x=1, S = row 1 has no x=2
		Assert.equals(Autotile.W, Autotile.getNeighborMask8(grid, 2, 0));
	}

	@Test
	public function testBlob47FallbackPrefersMostCornersWithSameCardinals():Void {
		final mapping:Map<Int, Int> = [0 => 0, 21 => 1, 45 => 2];
		Assert.equals(45, Autotile.applyBlob47FallbackWithMap(46, mapping), "all-neighbours falls back to the 3-corner tile");
		Assert.equals(21, Autotile.applyBlob47FallbackWithMap(22, mapping), "one-corner tile falls back to no-corner center");
		// applyBlob47FallbackWithMap and the chain the mapper tool displays are the same algorithm
		var mismatches = 0;
		for (i in 0...Autotile.BLOB47_TILE_COUNT)
			if (Autotile.applyBlob47FallbackWithMap(i, mapping) != Autotile.getBlob47FallbackChain(i, mapping).result)
				mismatches++;
		Assert.equals(0, mismatches);
	}

	@Test
	public function testBlob47AllTilesGridCoversEveryTile():Void {
		final grid = AutotileTestHelper.BLOB47_ALL_TILES_GRID;
		final seen = new Map<Int, Bool>();
		for (y in 0...grid.length)
			for (x in 0...grid[y].length)
				if (grid[y][x] != 0)
					seen.set(Autotile.getBlob47Index(Autotile.getNeighborMask8(grid, x, y)), true);
		Assert.equals(Autotile.BLOB47_TILE_COUNT, [for (k in seen.keys()) k].length,
			"BLOB47_ALL_TILES_GRID (tests 25/30/153) must produce every blob47 tile");
	}

	// ==================== Parser validation ====================

	@Test
	public function testParseCornerFormat():Void {
		Assert.isTrue(parseExpectingSuccess("#t autotile { format: corner tileSize: 8 demo: #fff, #000 }"));
	}

	@Test
	public function testParseRejectsDepth():Void {
		assertParseError("#t autotile { format: cross tileSize: 8 depth: 4 demo: #fff, #000 }", "depth");
	}

	@Test
	public function testParseRejectsSheetRegion():Void {
		assertParseError('#t autotile { format: cross tileSize: 8 sheet: "x", region: [0, 0, 8, 8] }', "file:");
	}

	@Test
	public function testParseRejectsMappingOnDemo():Void {
		assertParseError("#t autotile { format: cross tileSize: 8 demo: #fff, #000 mapping: [1, 0] }", "mapping");
	}

	@Test
	public function testParseRejectsPartialMappingOutsideBlob47():Void {
		assertParseError("#t autotile { format: corner tileSize: 8 demo: #fff, #000 allowPartialMapping: true }", "blob47");
	}

	@Test
	public function testParseRejectsMappingKeyOutsideFormat():Void {
		assertParseError('#t autotile { format: corner tileSize: 8 file: "$TILESET" mapping: [16:1] }', "not a valid index");
	}

	@Test
	public function testParseRejectsDuplicateMappingKey():Void {
		assertParseError('#t autotile { format: cross tileSize: 8 file: "$TILESET" mapping: [0:1, 0:2] }', "more than one entry");
	}

	@Test
	public function testParseRejectsRegionOnNonFileSource():Void {
		assertParseError("#t autotile { format: cross tileSize: 8 demo: #fff, #000 region: [0, 0, 8, 8] }", "file:");
	}

	@Test
	public function testParseRejectsRegionWithWrongArity():Void {
		assertParseError('#t autotile { format: cross tileSize: 8 file: "$TILESET" region: [0, 0, 8] }', "region");
	}

	@Test
	public function testParseRejectsTwoSources():Void {
		assertParseError('#t autotile { format: cross tileSize: 8 demo: #fff, #000 file: "$TILESET" }', "more than one source");
	}

	// ==================== Builder: rendering ====================

	@Test
	public function testCornerDemoIsolatedCellDrawsFourCornerTiles():Void {
		final builder = builderFromSource("#t autotile { format: corner tileSize: 8 demo: #fff, #000 }");
		final group = builder.buildAutotile("t", [[1]]);
		Assert.equals(4, group.count(), "one tile per grid corner around the cell");
		final bounds = group.getBounds();
		// Offset by half a tile: the 2x2 corner tiles span -4..12 around the 0..8 cell
		Assert.equals(-4.0, bounds.xMin);
		Assert.equals(-4.0, bounds.yMin);
		Assert.equals(12.0, bounds.xMax);
		Assert.equals(12.0, bounds.yMax);
	}

	@Test
	public function testCornerDemoStripDrawsEveryCorner():Void {
		final builder = builderFromSource("#t autotile { format: corner tileSize: 8 demo: #fff, #000 }");
		Assert.equals(6, builder.buildAutotile("t", [[1, 1]]).count(), "3x2 corners, all touch the strip");
		Assert.equals(0, builder.buildAutotile("t", [[0, 0], [0, 0]]).count(), "empty grid draws nothing");
	}

	@Test
	public function testCrossAndBlob47DrawOneTilePerFilledCell():Void {
		final builder = builderFromSource("
			#c autotile { format: cross tileSize: 8 demo: #fff, #000 }
			#b autotile { format: blob47 tileSize: 8 demo: #fff, #000 }
		");
		final grid = [[1, 1, 0], [1, 1, 1], [0, 5, 1]];
		Assert.equals(7, builder.buildAutotile("c", grid).count());
		Assert.equals(7, builder.buildAutotile("b", grid).count());
	}

	@Test
	public function testDemoTilesShareOneTextureAndAreCached():Void {
		final builder = builderFromSource("#b autotile { format: blob47 tileSize: 8 demo: #fff, #000 }");
		final first = builder.getAutotileTile("b", 0);
		var otherTexture = 0;
		for (i in 1...Autotile.BLOB47_TILE_COUNT)
			if (builder.getAutotileTile("b", i).getTexture() != first.getTexture())
				otherTexture++;
		Assert.equals(0, otherTexture, "all 47 demo tiles are sub-tiles of one texture");
		builder.buildAutotile("b", [[1, 1], [1, 1]]);
		Assert.isTrue(builder.getAutotileTile("b", 0) == first, "tiles resolved once per builder");
	}

	@Test
	public function testCornerIndexZeroIsOptional():Void {
		// Region tiles 0..14 mapped to corner indices 1..15; nothing for 0
		final builder = builderFromSource('
			#t autotile {
				format: corner
				tileSize: 8
				file: "$TILESET"
				region: [56, 24, 24, 40]
				mapping: [1:8, 2:6, 3:7, 4:2, 5:5, 6:11, 7:13, 8:0, 9:14, 10:3, 11:12, 12:1, 13:10, 14:9, 15:4]
			}
		');
		Assert.equals(4, builder.buildAutotile("t", [[1]]).count());
		final empty = builder.getAutotileTile("t", 0);
		Assert.equals(8.0, empty.width, "corner index 0 without a tile resolves to a transparent tileSize tile");
	}

	@Test
	public function testAtlasPrefixSource():Void {
		// Inline atlas names the tiles by corner index; c0 is left out on purpose (optional)
		final builder = builderFromSource('
			#fp atlas2("$TILESET") {
				c1: 72, 40, 8, 8
				c2: 56, 40, 8, 8
				c3: 64, 40, 8, 8
				c4: 72, 24, 8, 8
				c5: 72, 32, 8, 8
				c6: 72, 48, 8, 8
				c7: 64, 56, 8, 8
				c8: 56, 24, 8, 8
				c9: 72, 56, 8, 8
				c10: 56, 32, 8, 8
				c11: 56, 56, 8, 8
				c12: 64, 24, 8, 8
				c13: 64, 48, 8, 8
				c14: 56, 48, 8, 8
				c15: 64, 32, 8, 8
			}
			#t autotile { format: corner tileSize: 8 sheet: "fp", prefix: "c" }
			#bad autotile { format: cross tileSize: 8 sheet: "fp", prefix: "c" }
		');
		Assert.equals(4, builder.buildAutotile("t", [[1]]).count());
		// cross index 0 -> "c0", which the atlas does not have
		assertBuilderError(() -> builder.buildAutotile("bad", [[1]]), "autotile_missing_tile");
	}

	// ==================== Builder: validation ====================

	@Test
	public function testShortTileListNeedsPartialMapping():Void {
		final tiles = "tiles: generated(color(8, 8, #f00)) generated(color(8, 8, #0f0)) generated(color(8, 8, #00f))";
		final builder = builderFromSource('
			#strict autotile { format: blob47 tileSize: 8 $tiles }
			#partial autotile { format: blob47 tileSize: 8 allowPartialMapping: true $tiles }
		');
		assertBuilderError(() -> builder.buildAutotile("strict", [[1]]), "autotile_missing_tile");
		Assert.equals(4, builder.buildAutotile("partial", [[1, 1], [1, 1]]).count());
	}

	@Test
	public function testTooManyTilesWithoutMapping():Void {
		final extra = [for (i in 0...14) "generated(color(8, 8, #f00))"].join(" ");
		final builder = builderFromSource('#t autotile { format: cross tileSize: 8 tiles: $extra }');
		assertBuilderError(() -> builder.buildAutotile("t", [[1]]), "autotile_index");
	}

	@Test
	public function testMappingTargetOutsideRegion():Void {
		final builder = builderFromSource('
			#t autotile {
				format: cross
				tileSize: 8
				file: "$TILESET"
				region: [56, 24, 24, 40]
				mapping: [1, 3, 4, 5, 7, 0, 2, 6, 8, 10, 9, 13, 20]
			}
		');
		assertBuilderError(() -> builder.buildAutotile("t", [[1]]), "autotile_index");
	}

	@Test
	public function testMissingMappingEntryWithoutPartial():Void {
		final builder = builderFromSource('
			#t autotile { format: cross tileSize: 8 file: "$TILESET" region: [56, 24, 24, 40] mapping: [1, 3, 4] }
		');
		assertBuilderError(() -> builder.buildAutotile("t", [[1]]), "autotile_missing_tile");
	}

	@Test
	public function testRegionOutsideImage():Void {
		final builder = builderFromSource('#t autotile { format: corner tileSize: 8 file: "$TILESET" region: [540, 0, 24, 8] }');
		assertBuilderError(() -> builder.buildAutotile("t", [[1]]), "autotile_region");
	}

	@Test
	public function testRegionNotWholeTiles():Void {
		final builder = builderFromSource('#t autotile { format: corner tileSize: 8 file: "$TILESET" region: [0, 0, 20, 8] }');
		assertBuilderError(() -> builder.buildAutotile("t", [[1]]), "autotile_region");
	}

	@Test
	public function testIndexOutOfRange():Void {
		final builder = builderFromSource("#t autotile { format: corner tileSize: 8 demo: #fff, #000 }");
		assertBuilderError(() -> builder.getAutotileTile("t", 16), "autotile_index");
	}

	@Test
	public function testGeneratedAutotileUsesResolvedTile():Void {
		final builder = builderFromSource("
			#t autotile { format: cross tileSize: 8 demo: #fff, #000 }
			#p programmable() {
				bitmap(generated(autotile(\"t\", 9))): 0, 0
			}
		");
		final result = builder.buildWithParameters("p", new Map());
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		// bitmap() may wrap the tile; it must still be the cached demo sub-tile (same texture + rect)
		final cached = builder.getAutotileTile("t", 9);
		final tile = bitmaps[0].tile;
		Assert.isTrue(tile.getTexture() == cached.getTexture(), "generated(autotile()) uses the cached demo texture");
		Assert.equals(cached.x, tile.x);
		Assert.equals(cached.y, tile.y);
	}

	// ==================== Helpers ====================

	static function assertParseError(source:String, expectedFragment:String, ?pos:haxe.PosInfos):Void {
		final err = parseExpectingError(source);
		Assert.notNull(err, "expected a parse error", pos);
		if (err != null)
			Assert.isTrue(err.indexOf(expectedFragment) >= 0, 'error should mention "$expectedFragment": $err', pos);
	}

	static function assertBuilderError(fn:Void->Void, expectedCode:String, ?pos:haxe.PosInfos):Void {
		try {
			fn();
			Assert.fail('expected BuilderError "$expectedCode"', pos);
		} catch (e:BuilderError) {
			Assert.equals(expectedCode, e.code, 'wrong error: ${e.message}', pos);
		}
	}
}
