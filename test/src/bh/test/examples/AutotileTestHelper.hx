package bh.test.examples;

import h2d.Scene;
import utest.Assert;
import bh.test.VisualTestBase;
import bh.test.TestResourceLoader;

/**
 * Helper class for autotile-specific test methods.
 * Provides utilities for testing buildAutotile() functionality.
 */
class AutotileTestHelper {
	var testBase:VisualTestBase;
	var s2d:Scene;

	public function new(testBase:VisualTestBase, s2d:Scene) {
		this.testBase = testBase;
		this.s2d = s2d;
	}

	/**
	 * Build autotile terrain using buildAutotile() and add to scene.
	 * This tests the actual autotile functionality.
	 */
	public function buildAutotileAndAddToScene(animFilePath:String, autotileName:String, grid:Array<Array<Int>>, x:Float, y:Float, scale:Float = 4.0):h2d.TileGroup {
		try {
			var fileContent = byte.ByteData.ofString(sys.io.File.getContent(animFilePath));
			var loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
			var builder = bh.multianim.MultiAnimBuilder.load(fileContent, loader, animFilePath);

			var tileGroup = builder.buildAutotile(autotileName, grid);
			#if VERBOSE
			trace('Built autotile "$autotileName" from $animFilePath: $tileGroup');
			#end

			if (tileGroup != null) {
				tileGroup.x = x;
				tileGroup.y = y;
				tileGroup.setScale(scale);
				s2d.addChild(tileGroup);
			}
			return tileGroup;
		} catch (e:Dynamic) {
			trace('Error building autotile from $animFilePath: $e');
			return null;
		}
	}

	/**
	 * Build multiple autotile terrains and add them to the scene.
	 * Useful for testing multiple autotile definitions in one test.
	 */
	public function buildMultipleAutotiles(animFilePath:String, autotiles:Array<{name:String, grid:Array<Array<Int>>, x:Float, y:Float, ?scale:Float}>):Array<h2d.TileGroup> {
		var results = [];
		for (autotile in autotiles) {
			var scale = autotile.scale != null ? autotile.scale : 4.0;
			var tileGroup = buildAutotileAndAddToScene(animFilePath, autotile.name, autotile.grid, autotile.x, autotile.y, scale);
			results.push(tileGroup);
		}
		return results;
	}

	/**
	 * Build combined test: programmable element + autotile terrain.
	 * Tests both regular element building and buildAutotile().
	 * @param threshold Optional similarity threshold (default 0.9999 = 99.99%). Use lower values for tests with GPU-rendered text.
	 * @param scale Optional scale factor for both element and autotile (default 4.0)
	 */
	public function buildCombinedAutotileTest(animFilePath:String, elementName:String, autotileName:String,
			grid:Array<Array<Int>>, autotileX:Float, autotileY:Float,
			async:utest.Async, ?sizeX:Int, ?sizeY:Int, ?threshold:Float, ?scale:Float):Void {
		VisualTestBase.pendingVisualTests++;
		testBase.clearScene();

		if (scale == null) scale = 4.0;

		// Build the visual demo element
		var result = testBase.buildAndAddToScene(animFilePath, elementName, scale);
		Assert.notNull(result, 'Failed to build element "$elementName" from $animFilePath');

		// Build the autotile terrain
		var tileGroup = buildAutotileAndAddToScene(animFilePath, autotileName, grid, autotileX, autotileY, scale);
		Assert.notNull(tileGroup, 'Failed to build autotile "$autotileName" from $animFilePath');

		if (result != null && tileGroup != null) {
			testBase.waitForUpdate(function(dt:Float) {
				var actualPath = testBase.getActualImagePath();
				var referencePath = testBase.getReferenceImagePath();

				var success = testBase.screenshot(actualPath, sizeX, sizeY);
				Assert.isTrue(success, 'Screenshot should be created at $actualPath');

				if (success) {
					var match = testBase.compareImages(actualPath, referencePath, threshold);
					Assert.isTrue(match, 'Screenshot should match reference image');
				}

				VisualTestBase.pendingVisualTests--;
				async.done();
			});
		} else {
			VisualTestBase.pendingVisualTests--;
			async.done();
		}
	}

	/**
	 * Build combined test with multiple autotiles: programmable element + multiple autotile terrains.
	 * Useful for comparing labeled tiles with demo mode tiles side by side.
	 */
	public function buildCombinedAutotileTestMultiple(animFilePath:String, elementName:String,
			autotiles:Array<{name:String, grid:Array<Array<Int>>, x:Float, y:Float, ?background:Bool}>,
			async:utest.Async, ?sizeX:Int, ?sizeY:Int, ?threshold:Float, ?scale:Float):Void {
		VisualTestBase.pendingVisualTests++;
		testBase.clearScene();

		if (scale == null) scale = 4.0;

		// Build the visual demo element
		var result = testBase.buildAndAddToScene(animFilePath, elementName, scale);
		Assert.notNull(result, 'Failed to build element "$elementName" from $animFilePath');

		// Build all autotile terrains
		var allBuilt = true;
		for (autotile in autotiles) {
			// Add black background if requested
			if (autotile.background == true) {
				var gridWidth = autotile.grid[0].length;
				var gridHeight = autotile.grid.length;
				var tileSize = 16; // Default tile size
				var bgWidth = Std.int(gridWidth * tileSize * scale);
				var bgHeight = Std.int(gridHeight * tileSize * scale);
				var bg = new h2d.Bitmap(h2d.Tile.fromColor(0x000000, bgWidth, bgHeight), s2d);
				bg.x = autotile.x;
				bg.y = autotile.y;
			}
			var tileGroup = buildAutotileAndAddToScene(animFilePath, autotile.name, autotile.grid, autotile.x, autotile.y, scale);
			if (tileGroup == null) {
				Assert.notNull(tileGroup, 'Failed to build autotile "${autotile.name}" from $animFilePath');
				allBuilt = false;
			}
		}

		if (result != null && allBuilt) {
			testBase.waitForUpdate(function(dt:Float) {
				var actualPath = testBase.getActualImagePath();
				var referencePath = testBase.getReferenceImagePath();

				var success = testBase.screenshot(actualPath, sizeX, sizeY);
				Assert.isTrue(success, 'Screenshot should be created at $actualPath');

				if (success) {
					var match = testBase.compareImages(actualPath, referencePath, threshold);
					Assert.isTrue(match, 'Screenshot should match reference image');
				}

				VisualTestBase.pendingVisualTests--;
				async.done();
			});
		} else {
			VisualTestBase.pendingVisualTests--;
			async.done();
		}
	}

	/**
	 * Build autotile-only test (no programmable element).
	 * Just renders the autotile terrain and compares with reference.
	 */
	public function buildAutotileOnlyTest(animFilePath:String, autotileName:String, grid:Array<Array<Int>>,
			x:Float, y:Float, async:utest.Async, ?sizeX:Int, ?sizeY:Int):Void {
		VisualTestBase.pendingVisualTests++;
		testBase.clearScene();

		var tileGroup = buildAutotileAndAddToScene(animFilePath, autotileName, grid, x, y);
		Assert.notNull(tileGroup, 'Failed to build autotile "$autotileName" from $animFilePath');

		if (tileGroup != null) {
			testBase.waitForUpdate(function(dt:Float) {
				var actualPath = testBase.getActualImagePath();
				var referencePath = testBase.getReferenceImagePath();

				var success = testBase.screenshot(actualPath, sizeX, sizeY);
				Assert.isTrue(success, 'Screenshot should be created at $actualPath');

				if (success) {
					var match = testBase.compareImages(actualPath, referencePath);
					Assert.isTrue(match, 'Screenshot should match reference image');
				}

				VisualTestBase.pendingVisualTests--;
				async.done();
			});
		} else {
			VisualTestBase.pendingVisualTests--;
			async.done();
		}
	}

	// =========================================================================
	// Standard test grids for different autotile formats
	// =========================================================================

	/**
	 * Simple rectangular terrain grid - tests all outer edge tiles (0-8)
	 * Grid pattern (5x5):
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
	 * L-shaped terrain grid - tests inner corners (9-12)
	 * Grid pattern:
	 *   1 1 0
	 *   1 1 1
	 *   0 1 1
	 */
	public static var L_SHAPE_GRID = [
		[1, 1, 0],
		[1, 1, 1],
		[0, 1, 1]
	];

	/**
	 * Full terrain grid - all tiles surrounded (only center tile)
	 * Grid pattern (3x3):
	 *   1 1 1
	 *   1 1 1
	 *   1 1 1
	 */
	public static var FULL_GRID = [
		[1, 1, 1],
		[1, 1, 1],
		[1, 1, 1]
	];

	/**
	 * Single tile - tests isolated tile rendering
	 */
	public static var SINGLE_TILE = [
		[1]
	];

	/**
	 * Complex terrain with inner corners - tests all 13 cross format tiles
	 * Grid pattern (6x5):
	 *   0 1 1 1 1 0
	 *   1 1 1 1 1 1
	 *   1 1 0 0 1 1
	 *   1 1 1 1 1 1
	 *   0 1 1 1 1 0
	 */
	public static var COMPLEX_GRID = [
		[0, 1, 1, 1, 1, 0],
		[1, 1, 1, 1, 1, 1],
		[1, 1, 0, 0, 1, 1],
		[1, 1, 1, 1, 1, 1],
		[0, 1, 1, 1, 1, 0]
	];

	/**
	 * 7x7 terrain with cross-shaped hole in middle - tests all inner corners
	 * Grid pattern (7x7):
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
	 * Island terrain (grass) - small island shape
	 * Grid pattern (7x5):
	 *   0 0 1 1 1 0 0
	 *   0 1 1 1 1 1 0
	 *   1 1 1 1 1 1 1
	 *   0 1 1 1 1 1 0
	 *   0 0 1 1 1 0 0
	 */
	public static var ISLAND_GRID = [
		[0, 0, 1, 1, 1, 0, 0],
		[0, 1, 1, 1, 1, 1, 0],
		[1, 1, 1, 1, 1, 1, 1],
		[0, 1, 1, 1, 1, 1, 0],
		[0, 0, 1, 1, 1, 0, 0]
	];

	/**
	 * Sea terrain (water) - surrounds the island
	 * Grid pattern (7x5) - inverted island with border
	 *   1 1 1 1 1 1 1
	 *   1 1 0 0 0 1 1
	 *   1 0 0 0 0 0 1
	 *   1 1 0 0 0 1 1
	 *   1 1 1 1 1 1 1
	 */
	public static var SEA_GRID = [
		[1, 1, 1, 1, 1, 1, 1],
		[1, 1, 0, 0, 0, 1, 1],
		[1, 0, 0, 0, 0, 0, 1],
		[1, 1, 0, 0, 0, 1, 1],
		[1, 1, 1, 1, 1, 1, 1]
	];

	/**
	 * Large complex terrain for blob47 testing (12x10)
	 * Tests all tile types including inner corners with holes and peninsulas
	 * Grid pattern:
	 *   0 0 1 1 1 1 1 1 1 1 0 0
	 *   0 1 1 1 1 1 1 1 1 1 1 0
	 *   1 1 1 1 0 0 1 1 1 1 1 1
	 *   1 1 1 0 0 0 0 1 1 1 1 1
	 *   1 1 1 0 0 0 0 1 1 0 1 1
	 *   1 1 1 1 0 0 1 1 0 0 0 1
	 *   1 1 1 1 1 1 1 1 0 0 0 1
	 *   0 1 1 1 1 1 1 1 1 0 1 1
	 *   0 0 1 1 1 1 1 1 1 1 1 0
	 *   0 0 0 1 1 1 1 1 1 0 0 0
	 */
	public static var LARGE_BLOB47_GRID = [
		[0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
		[0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
		[1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1],
		[1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1],
		[1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1],
		[1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1],
		[1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1],
		[0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1],
		[0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
		[0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0]
	];

	/**
	 * Comprehensive blob47 test grid (16x12) - designed to produce all 47 unique tiles.
	 * Includes: isolated tiles, all edge combinations, all corner combinations,
	 * diagonal strips, checkerboard patterns, and fully surrounded tiles.
	 */
	public static var LARGE_SEA_GRID = [
		// Row 0: isolated tiles and single edges
		[1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0],
		// Row 1: more edge patterns
		[0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0],
		// Row 2: L-shapes for outer corners
		[1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1],
		// Row 3: complex patterns
		[1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1],
		// Row 4: diagonal for inner corners
		[0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1],
		// Row 5: checkerboard area
		[0, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1],
		// Row 6: more patterns
		[1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0],
		// Row 7: wide area
		[1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0],
		// Row 8: thin strips
		[0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 1],
		// Row 9: corner patterns
		[0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1],
		// Row 10: more edges
		[1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1],
		// Row 11: bottom edge patterns
		[1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1]
	];
}
