package bh.test.examples;

import h2d.Scene;
import utest.Assert;
import bh.test.VisualTestBase;
import bh.test.TestResourceLoader;

/**
 * Helper for autotile visual tests: builds buildAutotile() terrains next to a programmable, plus
 * the standard test grids.
 */
class AutotileTestHelper {
	var testBase:VisualTestBase;
	var s2d:Scene;

	public function new(testBase:VisualTestBase, s2d:Scene) {
		this.testBase = testBase;
		this.s2d = s2d;
	}

	/**
	 * Build autotile terrain using buildAutotile() and add it to the scene.
	 * A build error fails the running test with the builder's message (not just "returned null").
	 */
	public function buildAutotileAndAddToScene(animFilePath:String, autotileName:String, grid:Array<Array<Int>>, x:Float, y:Float, scale:Float = 4.0):Null<h2d.TileGroup> {
		try {
			var fileContent = byte.ByteData.ofString(sys.io.File.getContent(animFilePath));
			var loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
			var builder = bh.multianim.MultiAnimBuilder.load(fileContent, loader, animFilePath);

			var tileGroup = builder.buildAutotile(autotileName, grid);
			tileGroup.x = x;
			tileGroup.y = y;
			tileGroup.setScale(scale);
			s2d.addChild(tileGroup);
			return tileGroup;
		} catch (e:Dynamic) {
			Assert.fail('buildAutotile("$autotileName") from $animFilePath failed: $e');
			return null;
		}
	}

	// =========================================================================
	// Standard test grids (grid[y][x], non-zero = terrain)
	// =========================================================================

	/**
	 * Simple rectangular terrain grid - tests all outer edge tiles (0-8)
	 *   0 1 1 1 0
	 *   1 1 1 1 1
	 *   1 1 1 1 1
	 *   1 1 1 1 1
	 *   0 1 1 1 0
	 */
	public static var SIMPLE_RECT_GRID = [
		[0, 1, 1, 1, 0],
		[1, 1, 1, 1, 1],
		[1, 1, 1, 1, 1],
		[1, 1, 1, 1, 1],
		[0, 1, 1, 1, 0]
	];

	/**
	 * 7x7 terrain with cross-shaped hole in middle - tests all inner corners
	 *   0 1 1 1 1 1 0
	 *   1 1 1 1 1 1 1
	 *   1 1 1 0 1 1 1
	 *   1 1 0 0 0 1 1
	 *   1 1 1 0 1 1 1
	 *   1 1 1 1 1 1 1
	 *   0 1 1 1 1 1 0
	 */
	public static var CROSS_HOLE_GRID = [
		[0, 1, 1, 1, 1, 1, 0],
		[1, 1, 1, 1, 1, 1, 1],
		[1, 1, 1, 0, 1, 1, 1],
		[1, 1, 0, 0, 0, 1, 1],
		[1, 1, 1, 0, 1, 1, 1],
		[1, 1, 1, 1, 1, 1, 1],
		[0, 1, 1, 1, 1, 1, 0]
	];

	/**
	 * 16x12 grid that produces every one of the 47 blob47 tiles (found by search;
	 * AutotileTest.testBlob47AllTilesGridCoversEveryTile pins that).
	 */
	public static var BLOB47_ALL_TILES_GRID = [
		[0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1],
		[0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1],
		[1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0],
		[0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1],
		[0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0],
		[0, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0],
		[1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0],
		[1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 1],
		[1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1],
		[1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0],
		[1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
		[0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 1, 1, 1]
	];

	/**
	 * Cases the per-cell formats cannot express but corner handles: a block with a 1-cell hole,
	 * 1-wide vertical and horizontal strips, an isolated cell, diagonal-only touches and an L.
	 */
	public static var EDGE_CASES_GRID = [
		[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0],
		[0, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0],
		[0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0],
		[0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	];
}
