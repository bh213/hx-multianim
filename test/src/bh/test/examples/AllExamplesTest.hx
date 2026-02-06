package bh.test.examples;

import bh.test.VisualTestBase;
import bh.test.examples.AutotileTestHelper;
import utest.Assert;
import h2d.Scene;

class AllExamplesTest extends VisualTestBase {
	var autotileHelper:AutotileTestHelper;

	public function new(s2d:Scene) {
		super("examples", s2d);
		autotileHelper = new AutotileTestHelper(this, s2d);
	}

	// Example 1: hex grid + pixels
	@Test
	public function test01_HexGridPixels(async:utest.Async) {
		this.testName = "hexGridPixels";
		this.testTitle = "#1: hex grid + pixels";
		this.referenceDir = "test/examples/1-hexGridPixels";
		buildRenderScreenshotAndCompare("test/examples/1-hexGridPixels/hexGridPixels.manim", "hexGridPixels", async, 1280, 720, 1.0);
	}

	// Example 2: text
	@Test
	public function test02_TextDemo(async:utest.Async) {
		this.testName = "textDemo";
		this.testTitle = "#2: text";
		this.referenceDir = "test/examples/2-textDemo";
		buildRenderScreenshotAndCompare("test/examples/2-textDemo/textDemo.manim", "textDemo", async, 1280, 720, 1.0);
	}

	// Example 3: bitmap
	@Test
	public function test03_BitmapDemo(async:utest.Async) {
		this.testName = "bitmapDemo";
		this.testTitle = "#3: bitmap";
		this.referenceDir = "test/examples/3-bitmapDemo";
		buildRenderScreenshotAndCompare("test/examples/3-bitmapDemo/bitmapDemo.manim", "bitmapDemo", async, 1280, 720, 1.0);
	}

	// Example 4: repeatable
	@Test
	public function test04_RepeatableDemo(async:utest.Async) {
		this.testName = "repeatableDemo";
		this.testTitle = "#4: repeatable";
		this.referenceDir = "test/examples/4-repeatableDemo";
		buildRenderScreenshotAndCompare("test/examples/4-repeatableDemo/repeatableDemo.manim", "repeatableDemo", async, 1280, 720, 1.0);
	}

	// Example 5: stateanim
	@Test
	public function test05_StateAnimDemo(async:utest.Async) {
		this.testName = "stateAnimDemo";
		this.testTitle = "#5: stateanim";
		this.referenceDir = "test/examples/5-stateAnimDemo";
		buildRenderScreenshotAndCompare("test/examples/5-stateAnimDemo/stateAnimDemo.manim", "stateAnimDemo", async, 1280, 720, 1.0);
	}

	// Example 6: flow
	@Test
	public function test06_FlowDemo(async:utest.Async) {
		this.testName = "flowDemo";
		this.testTitle = "#6: flow";
		this.referenceDir = "test/examples/6-flowDemo";
		buildRenderScreenshotAndCompare("test/examples/6-flowDemo/flowDemo.manim", "flowDemo", async, 1280, 720, 1.0);
	}

	// Example 7: palette
	@Test
	public function test07_PaletteDemo(async:utest.Async) {
		this.testName = "paletteDemo";
		this.testTitle = "#7: palette";
		this.referenceDir = "test/examples/7-paletteDemo";
		buildRenderScreenshotAndCompare("test/examples/7-paletteDemo/paletteDemo.manim", "paletteDemo", async, 1280, 720, 1.0);
	}

	// Example 8: layers
	@Test
	public function test08_LayersDemo(async:utest.Async) {
		this.testName = "layersDemo";
		this.testTitle = "#8: layers";
		this.referenceDir = "test/examples/8-layersDemo";
		buildRenderScreenshotAndCompare("test/examples/8-layersDemo/layersDemo.manim", "layersDemo", async, 1280, 720, 1.0);
	}

	// Example 9: 9-patch
	@Test
	public function test09_NinePatchDemo(async:utest.Async) {
		this.testName = "ninePatchDemo";
		this.testTitle = "#9: 9-patch";
		this.referenceDir = "test/examples/9-ninePatchDemo";
		buildRenderScreenshotAndCompare("test/examples/9-ninePatchDemo/ninePatchDemo.manim", "ninePatchDemo", async, 1280, 720, 1.0);
	}

	// Example 10: reference
	@Test
	public function test10_ReferenceDemo(async:utest.Async) {
		this.testName = "referenceDemo";
		this.testTitle = "#10: reference";
		this.referenceDir = "test/examples/10-referenceDemo";
		buildRenderScreenshotAndCompare("test/examples/10-referenceDemo/referenceDemo.manim", "referenceDemo", async, 1280, 720, 1.0);
	}

	// Example 11: bitmap align
	@Test
	public function test11_BitmapAlignDemo(async:utest.Async) {
		this.testName = "bitmapAlignDemo";
		this.testTitle = "#11: bitmap align";
		this.referenceDir = "test/examples/11-bitmapAlignDemo";
		buildRenderScreenshotAndCompare("test/examples/11-bitmapAlignDemo/bitmapAlignDemo.manim", "bitmapAlignDemo", async, 1280, 720, 1.0);
	}

	// Example 12: updatable from code
	@Test
	public function test12_UpdatableDemo(async:utest.Async) {
		this.testName = "updatableDemo";
		this.testTitle = "#12: updatable from code";
		this.referenceDir = "test/examples/12-updatableDemo";
		buildRenderScreenshotAndCompare("test/examples/12-updatableDemo/updatableDemo.manim", "updatableDemo", async, 1280, 720, 1.0);
	}

	// Example 13: layout repeatable
	@Test
	public function test13_LayoutRepeatableDemo(async:utest.Async) {
		this.testName = "layoutRepeatableDemo";
		this.testTitle = "#13: layout repeatable";
		this.referenceDir = "test/examples/13-layoutRepeatableDemo";
		buildRenderScreenshotAndCompare("test/examples/13-layoutRepeatableDemo/layoutRepeatableDemo.manim", "layoutRepeatableDemo", async, 1280, 720, 1.0);
	}

	// Example 14: tileGroup
	@Test
	public function test14_TileGroupDemo(async:utest.Async) {
		this.testName = "tileGroupDemo";
		this.testTitle = "#14: tileGroup";
		this.referenceDir = "test/examples/14-tileGroupDemo";
		buildRenderScreenshotAndCompare("test/examples/14-tileGroupDemo/tileGroupDemo.manim", "tileGroupDemo", async, 1280, 720, 1.0);
	}

	// Example 15: stateAnim construct
	@Test
	public function test15_StateAnimConstructDemo(async:utest.Async) {
		this.testName = "stateAnimConstructDemo";
		this.testTitle = "#15: stateAnim construct";
		this.referenceDir = "test/examples/15-stateAnimConstructDemo";
		buildRenderScreenshotAndCompare("test/examples/15-stateAnimConstructDemo/stateAnimConstructDemo.manim", "stateAnimConstructDemo", async, 1280, 720, 1.0);
	}

	// Example 16: div/mod
	@Test
	public function test16_DivModDemo(async:utest.Async) {
		this.testName = "divModDemo";
		this.testTitle = "#16: div/mod";
		this.referenceDir = "test/examples/16-divModDemo";
		buildRenderScreenshotAndCompare("test/examples/16-divModDemo/divModDemo.manim", "divModDemo", async, 1280, 720, 1.0);
	}

	// Example 17: apply
	@Test
	public function test17_ApplyDemo(async:utest.Async) {
		this.testName = "applyDemo";
		this.testTitle = "#17: apply";
		this.referenceDir = "test/examples/17-applyDemo";
		buildRenderScreenshotAndCompare("test/examples/17-applyDemo/applyDemo.manim", "applyDemo", async, 1280, 720, 1.0);
	}

	// Example 18: conditionals
	@Test
	public function test18_ConditionalsDemo(async:utest.Async) {
		this.testName = "conditionalsDemo";
		this.testTitle = "#18: conditionals";
		this.referenceDir = "test/examples/18-conditionalsDemo";
		buildRenderScreenshotAndCompare("test/examples/18-conditionalsDemo/conditionalsDemo.manim", "main", async, 1280, 720, 1.0);
	}

	// Example 19: ternary op
	@Test
	public function test19_TernaryOpDemo(async:utest.Async) {
		this.testName = "ternaryOpDemo";
		this.testTitle = "#19: ternary op";
		this.referenceDir = "test/examples/19-ternaryOpDemo";
		buildRenderScreenshotAndCompare("test/examples/19-ternaryOpDemo/ternaryOpDemo.manim", "ternaryOpDemo", async, 1280, 720, 1.0);
	}

	// Example 20: graphics
	@Test
	public function test20_GraphicsDemo(async:utest.Async) {
		this.testName = "graphicsDemo";
		this.testTitle = "#20: graphics";
		this.referenceDir = "test/examples/20-graphicsDemo";
		buildRenderScreenshotAndCompare("test/examples/20-graphicsDemo/graphicsDemo.manim", "graphicsDemo", async, 1280, 720, 1.0);
	}

	// Example 21: repeatable2d
	@Test
	public function test21_Repeatable2dDemo(async:utest.Async) {
		this.testName = "repeatable2dDemo";
		this.testTitle = "#21: repeatable2d";
		this.referenceDir = "test/examples/21-repeatable2dDemo";
		buildRenderScreenshotAndCompare("test/examples/21-repeatable2dDemo/repeatable2dDemo.manim", "repeatable2dDemo", async, 1280, 720, 1.0);
	}

	// Example 23: tiles/stateanim iteration
	@Test
	public function test23_TilesIteration(async:utest.Async) {
		this.testName = "tilesIteration";
		this.testTitle = "#23: tiles/stateanim iteration";
		this.referenceDir = "test/examples/23-tilesIteration";
		buildRenderScreenshotAndCompare("test/examples/23-tilesIteration/tilesIteration.manim", "tilesIteration", async, 1280, 720, 1.0);
	}

	// Example 24: atlas demo - tiles with bounding rects
	@Test
	public function test24_AtlasDemo(async:utest.Async) {
		this.testName = "atlasDemo";
		this.testTitle = "#24: atlas demo";
		this.referenceDir = "test/examples/24-atlasDemo";
		buildRenderScreenshotAndCompare("test/examples/24-atlasDemo/atlasDemo.manim", "atlasDemo", async, 1280, 720, 1.0);
	}

	// Example 26: autotile cross format - tests buildAutotile() with cross format
	@Test
	public function test26_AutotileCross(async:utest.Async) {
		this.testName = "autotileCross";
		this.testTitle = "#26: autotile cross";
		this.referenceDir = "test/examples/26-autotileCross";

		autotileHelper.buildCombinedAutotileTestMultiple(
			"test/examples/26-autotileCross/autotileCross.manim",
			"autotileCross",
			[
				// Positions match manim file (multiply by scale 4.0)
				{name: "crossColored", grid: AutotileTestHelper.SIMPLE_RECT_GRID, x: 80.0, y: 376.0, background: false},
				{name: "crossWater", grid: AutotileTestHelper.SIMPLE_RECT_GRID, x: 520.0, y: 376.0, background: true}
			],
			async,
			1280, 720,
			0.98,
			4.0
		);
	}

	// Example 27: autotile blob47 format - tests buildAutotile() with blob47 format
	@Test
	public function test27_AutotileBlob47(async:utest.Async) {
		this.testName = "autotileBlob47";
		this.testTitle = "#27: autotile blob47";
		this.referenceDir = "test/examples/27-autotileBlob47";

		autotileHelper.buildCombinedAutotileTestMultiple(
			"test/examples/27-autotileBlob47/autotileBlob47.manim",
			"autotileBlob47",
			[
				// Positions match updatables in manim file (multiply by scale 2.0)
				{name: "blob47Colored", grid: AutotileTestHelper.LARGE_SEA_GRID, x: 40.0, y: 326.0, background: false},
				{name: "blob47Water", grid: AutotileTestHelper.LARGE_SEA_GRID, x: 684.0, y: 326.0, background: true}
			],
			async,
			1280, 720,
			0.98,
			2.0
		);
	}

	// Example 28: font showcase - displays all registered fonts with representative characters
	@Test
	public function test28_FontShowcase(async:utest.Async) {
		this.testName = "fontShowcase";
		this.testTitle = "#28: font showcase";
		this.referenceDir = "test/examples/28-fontShowcase";
		buildRenderScreenshotAndCompare("test/examples/28-fontShowcase/fontShowcase.manim", "fontShowcase", async, 1280, 720, 1.0);
	}

	// Example 29: scale position demo - verifies scale does NOT affect position
	@Test
	public function test29_ScalePositionDemo(async:utest.Async) {
		this.testName = "scalePositionDemo";
		this.testTitle = "#29: scale position demo";
		this.referenceDir = "test/examples/29-scalePositionDemo";
		buildRenderScreenshotAndCompare("test/examples/29-scalePositionDemo/scalePositionDemo.manim", "scalePositionDemo", async, 1280, 720, 1.0);
	}

	// Example 30: autotile demo syntax - tests the new demo: source syntax
	@Test
	public function test30_AutotileDemoSyntax(async:utest.Async) {
		this.testName = "autotileDemoSyntax";
		this.testTitle = "#30: autotile demo syntax";
		this.referenceDir = "test/examples/30-autotileDemoSyntax";

		// Test cross format with demo syntax - also tests blob47 via the same manim file
		autotileHelper.buildCombinedAutotileTest(
			"test/examples/30-autotileDemoSyntax/autotileDemoSyntax.manim",
			"autotileDemoSyntax",
			"simple13Demo",  // kept as "simple13Demo" for backwards compatibility
			AutotileTestHelper.SIMPLE_RECT_GRID,
			400.0, 100.0,
			async,
			1280, 720,
			0.98,
			1.0
		);
	}

	// Example 31: forgotten plains terrain - real tileset autotile
	@Test
	public function test31_ForgottenPlainsTerrain(async:utest.Async) {
		this.testName = "forgottenPlainsTerrain";
		this.testTitle = "#31: forgotten plains terrain";
		this.referenceDir = "test/examples/31-forgottenPlainsTerrain";

		// Test combined: programmable element showing all 13 tiles + autotile terrain
		autotileHelper.buildCombinedAutotileTestMultiple(
			"test/examples/31-forgottenPlainsTerrain/forgottenPlainsTerrain.manim",
			"forgottenPlainsTerrain",
			[
				// Autotile terrain positioned at bottom (7x7 grid with cross hole)
				{name: "grassTerrain", grid: AutotileTestHelper.CROSS_HOLE_GRID, x: 40.0, y: 360.0, background: false},
				{name: "grassDemo", grid: AutotileTestHelper.CROSS_HOLE_GRID, x: 320.0, y: 360.0, background: false}
			],
			async,
			1280, 720,
			0.98,
			4.0
		);
	}

	// Example 32: blob47 fallback - blob47 with partial tileset
	@Test
	public function test32_Blob47Fallback(async:utest.Async) {
		this.testName = "blob47Fallback";
		this.testTitle = "#32: blob47 fallback";
		this.referenceDir = "test/examples/32-blob47Fallback";

		// Test blob47 with partial tileset - missing tiles use fallback
		// Positions: manim has backgrounds at (10,152) and (160,152), scale 2.0
		autotileHelper.buildCombinedAutotileTestMultiple(
			"test/examples/32-blob47Fallback/blob47Fallback.manim",
			"blob47Fallback",
			[
				// Demo tiles (left map)
				{name: "blob47Demo", grid: AutotileTestHelper.LARGE_SEA_GRID, x: 20.0, y: 304.0, background: false},
				// Forgotten Plains tiles with fallback (right map)
				{name: "blob47Grass", grid: AutotileTestHelper.LARGE_SEA_GRID, x: 320.0, y: 304.0, background: false}
			],
			async,
			1280, 720,
			0.98,
			2.0
		);
	}

	// Example 33: @else and @default conditionals
	@Test
	public function test33_ElseDefaultDemo(async:utest.Async) {
		this.testName = "elseDefaultDemo";
		this.testTitle = "#33: @else and @default";
		this.referenceDir = "test/examples/33-elseDefaultDemo";
		buildRenderScreenshotAndCompare("test/examples/33-elseDefaultDemo/elseDefaultDemo.manim", "elseDefaultDemo", async, 1280, 720, 1.0);
	}

	// Example 34: named filter params + block comments
	@Test
	public function test34_NamedFilterParams(async:utest.Async) {
		this.testName = "namedFilterParams";
		this.testTitle = "#34: named filter params";
		this.referenceDir = "test/examples/34-namedFilterParams";
		buildRenderScreenshotAndCompare("test/examples/34-namedFilterParams/namedFilterParams.manim", "namedFilterParams", async, 1280, 720, 1.0);
	}
}
