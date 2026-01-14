package bh.test.examples;

import bh.test.VisualTestBase;
import utest.Assert;
import h2d.Scene;

class AllExamplesTest extends VisualTestBase {
	public function new(s2d:Scene) {
		super("examples", s2d);
	}

	// Example 1: hex grid + pixels

	@Test
	public function test01_HexGridPixels(async:utest.Async) {
		this.testName = "hexGridPixels";
		this.referenceDir = "test/examples/1-hexGridPixels";
		buildRenderScreenshotAndCompare("test/examples/1-hexGridPixels/hexGridPixels.manim", "hexGridPixels", async, 1280, 720);
	}

	// Example 2: text
	@Test
	public function test02_TextDemo(async:utest.Async) {
		this.testName = "textDemo";
		this.referenceDir = "test/examples/2-textDemo";
		buildRenderScreenshotAndCompare("test/examples/2-textDemo/textDemo.manim", "textDemo", async, 1280, 720);
	}

	// Example 3: bitmap
	// TODO: Requires crew2 sprite sheets (crew2.atlas2, crew2-0.png) - Available in test/res
	@Test
	public function test03_BitmapDemo(async:utest.Async) {
		this.testName = "bitmapDemo";
		this.referenceDir = "test/examples/3-bitmapDemo";
		buildRenderScreenshotAndCompare("test/examples/3-bitmapDemo/bitmapDemo.manim", "bitmapDemo", async, 1280, 720);
	}

	// Example 4: repeatable
	// TODO: Requires crew2 sprite sheets (crew2.atlas2, crew2-0.png) - Available in test/res
	@Test
	public function test04_RepeatableDemo(async:utest.Async) {
		this.testName = "repeatableDemo";
		this.referenceDir = "test/examples/4-repeatableDemo";
		buildRenderScreenshotAndCompare("test/examples/4-repeatableDemo/repeatableDemo.manim", "repeatableDemo", async, 1280, 720);
	}

	// Example 5: stateanim
	// TODO: Requires marine.anim with "idle" animation - Available in test/res
	@Test
	public function test05_StateAnimDemo(async:utest.Async) {
		this.testName = "stateAnimDemo";
		this.referenceDir = "test/examples/5-stateAnimDemo";
		buildRenderScreenshotAndCompare("test/examples/5-stateAnimDemo/stateAnimDemo.manim", "stateAnimDemo", async, 1280, 720);
	}

	// Example 6: flow
	@Test
	public function test06_FlowDemo(async:utest.Async) {
		this.testName = "flowDemo";
		this.referenceDir = "test/examples/6-flowDemo";
		buildRenderScreenshotAndCompare("test/examples/6-flowDemo/flowDemo.manim", "flowDemo", async, 1280, 720);
	}

	// Example 7: palette
	@Test
	public function test07_PaletteDemo(async:utest.Async) {
		this.testName = "paletteDemo";
		this.referenceDir = "test/examples/7-paletteDemo";
		buildRenderScreenshotAndCompare("test/examples/7-paletteDemo/paletteDemo.manim", "paletteDemo", async, 1280, 720);
	}

	// Example 8: layers
	@Test
	public function test08_LayersDemo(async:utest.Async) {
		this.testName = "layersDemo";
		this.referenceDir = "test/examples/8-layersDemo";
		buildRenderScreenshotAndCompare("test/examples/8-layersDemo/layersDemo.manim", "layersDemo", async, 1280, 720);
	}

	// Example 9: 9-patch
	// TODO: Requires UI atlas (ui.atlas2, ui-0.png) - Available in test/res
	@Test
	public function test09_NinePatchDemo(async:utest.Async) {
		this.testName = "ninePatchDemo";
		this.referenceDir = "test/examples/9-ninePatchDemo";
		buildRenderScreenshotAndCompare("test/examples/9-ninePatchDemo/ninePatchDemo.manim", "ninePatchDemo", async, 1280, 720);
	}

	// Example 10: reference
	@Test
	public function test10_ReferenceDemo(async:utest.Async) {
		this.testName = "referenceDemo";
		this.referenceDir = "test/examples/10-referenceDemo";
		buildRenderScreenshotAndCompare("test/examples/10-referenceDemo/referenceDemo.manim", "referenceDemo", async, 1280, 720);
	}

	// Example 11: bitmap align
	@Test
	public function test11_BitmapAlignDemo(async:utest.Async) {
		this.testName = "bitmapAlignDemo";
		this.referenceDir = "test/examples/11-bitmapAlignDemo";
		buildRenderScreenshotAndCompare("test/examples/11-bitmapAlignDemo/bitmapAlignDemo.manim", "bitmapAlignDemo", async, 1280, 720);
	}

	// Example 12: updatable from code
	@Test
	public function test12_UpdatableDemo(async:utest.Async) {
		this.testName = "updatableDemo";
		this.referenceDir = "test/examples/12-updatableDemo";
		buildRenderScreenshotAndCompare("test/examples/12-updatableDemo/updatableDemo.manim", "updatableDemo", async, 1280, 720);
	}

	// Example 13: layout repeatable
	@Test
	public function test13_LayoutRepeatableDemo(async:utest.Async) {
		this.testName = "layoutRepeatableDemo";
		this.referenceDir = "test/examples/13-layoutRepeatableDemo";
		buildRenderScreenshotAndCompare("test/examples/13-layoutRepeatableDemo/layoutRepeatableDemo.manim", "layoutRepeatableDemo", async, 1280, 720);
	}

	// Example 14: tileGroup
	@Test
	public function test14_TileGroupDemo(async:utest.Async) {
		this.testName = "tileGroupDemo";
		this.referenceDir = "test/examples/14-tileGroupDemo";
		buildRenderScreenshotAndCompare("test/examples/14-tileGroupDemo/tileGroupDemo.manim", "tileGroupDemo", async, 1280, 720);
	}

	// Example 15: stateAnim construct
	// TODO: Requires crew2 sprite sheets (crew2.atlas2, crew2-0.png) - Available in test/res
	@Test
	public function test15_StateAnimConstructDemo(async:utest.Async) {
		this.testName = "stateAnimConstructDemo";
		this.referenceDir = "test/examples/15-stateAnimConstructDemo";
		buildRenderScreenshotAndCompare("test/examples/15-stateAnimConstructDemo/stateAnimConstructDemo.manim", "stateAnimConstructDemo", async, 1280, 720);
	}

	// Example 16: div/mod
	@Test
	public function test16_DivModDemo(async:utest.Async) {
		this.testName = "divModDemo";
		this.referenceDir = "test/examples/16-divModDemo";
		buildRenderScreenshotAndCompare("test/examples/16-divModDemo/divModDemo.manim", "divModDemo", async, 1280, 720);
	}

	// Example 17: apply
	@Test
	public function test17_ApplyDemo(async:utest.Async) {
		this.testName = "applyDemo";
		this.referenceDir = "test/examples/17-applyDemo";
		buildRenderScreenshotAndCompare("test/examples/17-applyDemo/applyDemo.manim", "applyDemo", async, 1280, 720);
	}

	// Example 18: conditionals
	@Test
	public function test18_ConditionalsDemo(async:utest.Async) {
		this.testName = "conditionalsDemo";
		this.referenceDir = "test/examples/18-conditionalsDemo";
		buildRenderScreenshotAndCompare("test/examples/18-conditionalsDemo/conditionalsDemo.manim", "main", async, 1280, 720);
	}

	// Example 19: tertiary op
	@Test
	public function test19_TertiaryOpDemo(async:utest.Async) {
		this.testName = "tertiaryOpDemo";
		this.referenceDir = "test/examples/19-tertiaryOpDemo";
		buildRenderScreenshotAndCompare("test/examples/19-tertiaryOpDemo/tertiaryOpDemo.manim", "tertiaryOpDemo", async, 1280, 720);
	}

	// Example 20: graphics
	@Test
	public function test20_GraphicsDemo(async:utest.Async) {
		this.testName = "graphicsDemo";
		this.referenceDir = "test/examples/20-graphicsDemo";
		buildRenderScreenshotAndCompare("test/examples/20-graphicsDemo/graphicsDemo.manim", "graphicsDemo", async, 1280, 720);
	}

	// Example 21: repeatable2d
	@Test
	public function test21_Repeatable2dDemo(async:utest.Async) {
		this.testName = "repeatable2dDemo";
		this.referenceDir = "test/examples/21-repeatable2dDemo";
		buildRenderScreenshotAndCompare("test/examples/21-repeatable2dDemo/repeatable2dDemo.manim", "repeatable2dDemo", async, 1280, 720);
	}
}
