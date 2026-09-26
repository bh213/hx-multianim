package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Codegen twin of PaletteIndexTrackingTest: the codegen keeps its own private
 * collectParamRefsImpl, and the builder-side fix (recursing into RVColor /
 * RVColorXY / RVElementOfArray / RVArray) was never ported. A `tint:
 * palette(pal, $idx)` therefore collects no refs in codegen — no expression
 * update is registered and setParameter("idx", ...) leaves the tint frozen.
 *
 * Companion fixture: test/examples/143-codegenPaletteIdx/paletteIdx.manim
 */
class CodegenPaletteIndexTrackingTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/143-codegenPaletteIdx/paletteIdx.manim";
	static inline var OPAQUE_RED = 0xFFFF0000;
	static inline var OPAQUE_GREEN = 0xFF00FF00;

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function tintedBitmapColor(root:h2d.Object):Int {
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(root);
		Assert.equals(1, bitmaps.length, "expected exactly one tinted bitmap");
		return bitmaps.length == 1 ? bitmaps[0].color.toColor() : 0;
	}

	/** Builder baseline (fixed collector): index change re-applies the tint. */
	@Test
	public function testPaletteIndexTint_Builder_RefiresOnIndexChange():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "palIdx", null, Incremental);
		Assert.equals(OPAQUE_RED, tintedBitmapColor(result.object), "builder: idx=0 tints palette color 0 (red)");
		result.setParameter("idx", 1);
		Assert.equals(OPAQUE_GREEN, tintedBitmapColor(result.object),
			"builder: setParameter(idx, 1) re-tints to palette color 1 (green)");
	}

	/** Codegen: same contract — the palette index ref must be tracked. */
	@Test
	public function testPaletteIndexTint_Codegen_RefiresOnIndexChange():Void {
		final inst:Dynamic = createMp().palIdx.create();
		Assert.equals(OPAQUE_RED, tintedBitmapColor(cast inst), "codegen: idx=0 tints palette color 0 (red)");
		inst.setParameter("idx", 1);
		Assert.equals(OPAQUE_GREEN, tintedBitmapColor(cast inst),
			"codegen: setParameter(idx, 1) must re-tint to palette color 1 (green) — the palette index ref is currently untracked");
	}
}
