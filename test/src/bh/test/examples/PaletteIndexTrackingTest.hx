package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.buildFromSource;

/**
 * Incremental tracking of param refs nested inside palette color lookups.
 *
 * Bug shape: collectParamRefs (MultiAnimBuilder) recurses into references, binops,
 * parenthesis, ternaries, unary ops, and array-element indices — but not into
 * RVColor / RVColorXY index refs (nor RVMethodCall / RVChainedMethodCall args,
 * RVCallbacks(WithIndex), RVArray elements). trackExtendedFormExpressions only
 * registers a tracked expression when the collected ref list is non-empty, so
 * `tint: palette(pal, $idx)` collects nothing and setParameter("idx", ...) never
 * re-applies the tint — the color is frozen at its build-time value.
 */
class PaletteIndexTrackingTest extends BuilderTestBase {
	static inline var OPAQUE_RED = 0xFFFF0000;
	static inline var OPAQUE_GREEN = 0xFF00FF00;

	static inline var PAL_SOURCE = "
		#pal palette { #FF0000 #00FF00 #0000FF }
		#tintPal programmable(idx:int=0) {
			bitmap(generated(color(8, 8, #FFFFFF))) {
				tint: palette(pal, $idx)
				pos: 0, 0
			}
		}
	";

	static function tintedBitmapColor(root:h2d.Object):Int {
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(root);
		Assert.equals(1, bitmaps.length, "expected exactly one tinted bitmap");
		return bitmaps[0].color.toColor();
	}

	/** Full-build baseline: the palette index resolves per build. */
	@Test
	public function testPaletteIndexTint_FullBuild_ResolvesIndex():Void {
		final defResult = buildFromSource(PAL_SOURCE, "tintPal");
		Assert.equals(OPAQUE_RED, tintedBitmapColor(defResult.object),
			"full build: idx=0 (default) must tint palette color 0 (red)");

		final params = new Map<String, Dynamic>();
		params.set("idx", 1);
		final result = buildFromSource(PAL_SOURCE, "tintPal", params);
		Assert.equals(OPAQUE_GREEN, tintedBitmapColor(result.object),
			"full build: idx=1 must tint palette color 1 (green)");
	}

	/** Incremental: setParameter on the palette index must re-apply the tint.
	 *  Currently collectParamRefs skips the RVColor index ref, so no tracked
	 *  expression is registered and the tint stays frozen. */
	@Test
	public function testPaletteIndexTint_Incremental_RefiresOnIndexChange():Void {
		final result = buildFromSource(PAL_SOURCE, "tintPal", null, Incremental);
		Assert.equals(OPAQUE_RED, tintedBitmapColor(result.object),
			"incremental build: idx=0 (default) must tint palette color 0 (red)");

		result.setParameter("idx", 1);
		Assert.equals(OPAQUE_GREEN, tintedBitmapColor(result.object),
			"incremental: setParameter(idx, 1) must re-tint to palette color 1 (green) — index ref is currently untracked");
	}

}
