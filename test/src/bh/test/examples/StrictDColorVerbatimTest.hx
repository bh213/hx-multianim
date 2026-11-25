package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.buildFromSource;
import bh.test.BuilderTestBase.findVisibleBitmapDescendants;

/**
 * Strict-D color semantics: a Heaps 0x color literal with a zero top byte is
 * transparent and must be stored verbatim (alpha = 0) by BOTH the runtime
 * builder and the macro codegen. Codegen used to re-bake 0xFF000000 onto child
 * tint and pixel colors, rendering 0xFF0000 (transparent red) as opaque red —
 * diverging from the builder (and from codegen's own root-tint path).
 *
 * Companion fixture: test/examples/121-strictDColorVerbatim/strictDColorVerbatim.manim
 */
class StrictDColorVerbatimTest extends BuilderTestBase {
	// 0xFF0000 = transparent red under strict-D (top byte / alpha = 0).
	static inline final TRANSPARENT_RED = 0x00FF0000;

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
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

	@Test
	public function testTintWithZeroAlphaIsStoredVerbatimInBuilderAndCodegen():Void {
		final source = "
			#strictDTint programmable() {
				bitmap(generated(color(16, 16, #0000FF))) {
					tint: 0xFF0000
					pos: 0, 0
				}
			}
		";
		final builderResult = buildFromSource(source, "strictDTint");
		Assert.notNull(builderResult, "Builder build should succeed");
		final builderBitmaps = findVisibleBitmapDescendants(builderResult.object);
		Assert.equals(1, builderBitmaps.length, "Expected one tinted bitmap (builder)");
		Assert.equals(TRANSPARENT_RED, builderBitmaps[0].color.toColor(),
			"Builder must store the transparent-red tint verbatim (alpha = 0)");

		final mp = createMp();
		final codegenObj:h2d.Object = cast mp.strictDTint.create();
		final codegenBitmaps = findVisibleBitmapDescendants(codegenObj);
		Assert.equals(1, codegenBitmaps.length, "Expected one tinted bitmap (codegen)");
		Assert.equals(TRANSPARENT_RED, codegenBitmaps[0].color.toColor(),
			"Codegen must store the transparent-red tint verbatim, not bake 0xFF alpha");
	}

	@Test
	public function testPixelWithZeroAlphaIsStoredVerbatimInBuilderAndCodegen():Void {
		final source = "
			#strictDPixels programmable() {
				pixels (
					filledRect 0, 0, 4, 4, 0xFF0000
				);
			}
		";
		final builderResult = buildFromSource(source, "strictDPixels");
		Assert.notNull(builderResult, "Builder build should succeed");
		final builderPl = findPixelLinesChild(builderResult.object);
		Assert.notNull(builderPl, "Builder should produce a PixelLines child");
		Assert.equals(TRANSPARENT_RED, builderPl.data.getPixel(0, 0),
			"Builder must store the transparent-red pixel verbatim (alpha = 0)");

		final mp = createMp();
		final codegenObj:h2d.Object = cast mp.strictDPixels.create();
		final codegenPl = findPixelLinesChild(codegenObj);
		Assert.notNull(codegenPl, "Codegen should produce a PixelLines child");
		Assert.equals(TRANSPARENT_RED, codegenPl.data.getPixel(0, 0),
			"Codegen must store the transparent-red pixel verbatim, not bake 0xFF alpha");
	}
}
