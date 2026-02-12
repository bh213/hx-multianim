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

	// tests 1, 2, 3, 4, 6, 8, 9, 10, 11, 13 moved to ProgrammableCodeGenTest (macro comparison)
	@Test public function test05_StateAnimDemo(async:utest.Async) { simpleTest(5, "stateAnimDemo", async); }
	@Test public function test07_PaletteDemo(async:utest.Async) { simpleTest(7, "paletteDemo", async); }
	@Test public function test12_UpdatableDemo(async:utest.Async) { simpleTest(12, "updatableDemo", async); }
	@Test public function test14_TileGroupDemo(async:utest.Async) { simpleTest(14, "tileGroupDemo", async); }
	@Test public function test15_StateAnimConstructDemo(async:utest.Async) { simpleTest(15, "stateAnimConstructDemo", async); }
	@Test public function test16_DivModDemo(async:utest.Async) { simpleTest(16, "divModDemo", async); }
	// test17 moved to ProgrammableCodeGenTest (macro comparison)
	@Test public function test18_ConditionalsDemo(async:utest.Async) { simpleTest(18, "conditionalsDemo", async, "main"); }
	@Test public function test19_TernaryOpDemo(async:utest.Async) { simpleTest(19, "ternaryOpDemo", async); }
	@Test public function test20_GraphicsDemo(async:utest.Async) { simpleTest(20, "graphicsDemo", async); }
	@Test public function test21_Repeatable2dDemo(async:utest.Async) { simpleTest(21, "repeatable2dDemo", async); }
	@Test public function test22_TilesIteration(async:utest.Async) { simpleTest(22, "tilesIteration", async); }
	@Test public function test23_AtlasDemo(async:utest.Async) { simpleTest(23, "atlasDemo", async); }

	// Autotile tests (24-30)

	@Test
	public function test24_AutotileCross(async:utest.Async) {
		setupTest(24, "autotileCross");
		autotileHelper.buildCombinedAutotileTestMultiple(
			"test/examples/24-autotileCross/autotileCross.manim", "autotileCross",
			[
				{name: "crossColored", grid: AutotileTestHelper.SIMPLE_RECT_GRID, x: 80.0, y: 376.0, background: false},
				{name: "crossWater", grid: AutotileTestHelper.SIMPLE_RECT_GRID, x: 520.0, y: 376.0, background: true}
			],
			async, 1280, 720, 0.98, 4.0
		);
	}

	@Test
	public function test25_AutotileBlob47(async:utest.Async) {
		setupTest(25, "autotileBlob47");
		autotileHelper.buildCombinedAutotileTestMultiple(
			"test/examples/25-autotileBlob47/autotileBlob47.manim", "autotileBlob47",
			[
				{name: "blob47Colored", grid: AutotileTestHelper.LARGE_SEA_GRID, x: 40.0, y: 326.0, background: false},
				{name: "blob47Water", grid: AutotileTestHelper.LARGE_SEA_GRID, x: 684.0, y: 326.0, background: true}
			],
			async, 1280, 720, 0.98, 2.0
		);
	}

	@Test public function test26_FontShowcase(async:utest.Async) { simpleTest(26, "fontShowcase", async); }
	@Test public function test27_ScalePositionDemo(async:utest.Async) { simpleTest(27, "scalePositionDemo", async); }

	@Test
	public function test28_AutotileDemoSyntax(async:utest.Async) {
		setupTest(28, "autotileDemoSyntax");
		autotileHelper.buildCombinedAutotileTest(
			"test/examples/28-autotileDemoSyntax/autotileDemoSyntax.manim", "autotileDemoSyntax",
			"simple13Demo", AutotileTestHelper.SIMPLE_RECT_GRID, 400.0, 100.0,
			async, 1280, 720, 0.98, 1.0
		);
	}

	@Test
	public function test29_ForgottenPlainsTerrain(async:utest.Async) {
		setupTest(29, "forgottenPlainsTerrain");
		autotileHelper.buildCombinedAutotileTestMultiple(
			"test/examples/29-forgottenPlainsTerrain/forgottenPlainsTerrain.manim", "forgottenPlainsTerrain",
			[
				{name: "grassTerrain", grid: AutotileTestHelper.CROSS_HOLE_GRID, x: 40.0, y: 360.0, background: false},
				{name: "grassDemo", grid: AutotileTestHelper.CROSS_HOLE_GRID, x: 320.0, y: 360.0, background: false}
			],
			async, 1280, 720, 0.98, 4.0
		);
	}

	@Test
	public function test30_Blob47Fallback(async:utest.Async) {
		setupTest(30, "blob47Fallback");
		autotileHelper.buildCombinedAutotileTestMultiple(
			"test/examples/30-blob47Fallback/blob47Fallback.manim", "blob47Fallback",
			[
				{name: "blob47Demo", grid: AutotileTestHelper.LARGE_SEA_GRID, x: 20.0, y: 304.0, background: false},
				{name: "blob47Grass", grid: AutotileTestHelper.LARGE_SEA_GRID, x: 320.0, y: 304.0, background: false}
			],
			async, 1280, 720, 0.98, 2.0
		);
	}

	@Test public function test31_ElseDefaultDemo(async:utest.Async) { simpleTest(31, "elseDefaultDemo", async); }
	@Test public function test32_NamedFilterParams(async:utest.Async) { simpleTest(32, "namedFilterParams", async); }
	@Test public function test33_InlineAtlas2Demo(async:utest.Async) { simpleTest(33, "inlineAtlas2Demo", async); }
	@Test public function test34_MaskDemo(async:utest.Async) { simpleTest(34, "maskDemo", async); }
}
