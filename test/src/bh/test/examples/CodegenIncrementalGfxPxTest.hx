package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Regression — codegen GRAPHICS and PIXELS with $param references must redraw
 * on setParameter(), matching the builder's behavior (already covered for
 * builder-path by BuilderUnitTest.testIncrementalGraphicsRedrawsOnSetParameter
 * and BuilderUnitTest.testIncrementalPixelsActualDataAfterSetParameter).
 *
 * Companion fixture: test/examples/109-codegenIncrementalGfxPx/codegenIncrementalGfxPx.manim
 */
class CodegenIncrementalGfxPxTest extends BuilderTestBase {
	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function findGraphicsChild(obj:h2d.Object):Null<h2d.Graphics> {
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, h2d.Graphics))
				return cast child;
		}
		return null;
	}

	static function findPixelLinesChild(obj:h2d.Object):Null<bh.base.PixelLine.PixelLines> {
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, bh.base.PixelLine.PixelLines))
				return cast child;
			final found = findPixelLinesChild(child);
			if (found != null)
				return found;
		}
		return null;
	}

	static inline final RED = 0xFFFF0000;
	static inline final PIXEL_H = 5;

	/** Check all pixels: 0..filledWidth should be expectedColor, filledWidth..totalWidth should be 0 (transparent). */
	static function assertPixelRect(pl:bh.base.PixelLine.PixelLines, filledWidth:Int, expectedColor:Int, label:String):Void {
		for (y in 0...pl.data.height) {
			for (x in 0...pl.data.width) {
				final actual = pl.data.getPixel(x, y);
				if (x < filledWidth && y < PIXEL_H) {
					if (actual != expectedColor) {
						Assert.fail('$label: pixel($x,$y) expected filled 0x${StringTools.hex(expectedColor, 8)} but got 0x${StringTools.hex(actual, 8)}');
						return;
					}
				} else {
					if (actual != 0) {
						Assert.fail('$label: pixel($x,$y) expected transparent but got 0x${StringTools.hex(actual, 8)}');
						return;
					}
				}
			}
		}
		Assert.pass();
	}

	@Test
	@:access(h2d.Graphics)
	public function testCodegenGraphics_RedrawsOnSetParameter():Void {
		final mp = createMp();
		final inst:Dynamic = mp.codegenIncGraphics.create();
		final obj:h2d.Object = cast inst;

		final g = findGraphicsChild(obj);
		Assert.notNull(g, "Should find h2d.Graphics child");
		Assert.floatEquals(200.0, g.xMax, "Initial xMax should be 200 (val=100 → width=200)");

		inst.setVal(50);
		final g2 = findGraphicsChild(obj);
		Assert.notNull(g2, "Graphics should still exist after setVal");
		Assert.floatEquals(100.0, g2.xMax, "After setVal(50), xMax should be 100 (val=50 → width=100) — requires codegen redraw");
	}

	@Test
	public function testCodegenPixels_RedrawsOnSetParameter():Void {
		final mp = createMp();
		final inst:Dynamic = mp.codegenIncPixels.create();
		final obj:h2d.Object = cast inst;

		var pl = findPixelLinesChild(obj);
		Assert.notNull(pl, "Should have a PixelLines child");
		assertPixelRect(pl, 100, RED, "initial val=100");

		inst.setVal(50);
		pl = findPixelLinesChild(obj);
		Assert.notNull(pl, "PixelLines should still exist after setVal");
		assertPixelRect(pl, 50, RED, "after setVal(50) — requires codegen redraw");
	}
}
