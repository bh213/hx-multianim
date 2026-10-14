package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Named hex systems with runtime (param-dependent) coordinates: the codegen's
 * generatePositionExpr NAMED_COORD arm returns null when static resolution
 * fails, so the element is silently left at 0,0 (the hex-layout discovery
 * pass also never recurses into the wrapper, which is why nothing is
 * emitted). The builder substitutes the named system and positions correctly.
 *
 * Companion fixture: test/examples/148-codegenHexNamed/hexNamed.manim
 */
class CodegenNamedHexCoordTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/148-codegenHexNamed/hexNamed.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function singleBitmapX(root:h2d.Object):Float {
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(root);
		Assert.equals(1, bitmaps.length, "expected exactly one positioned bitmap");
		if (bitmaps.length != 1)
			return Math.NaN;
		var x = 0.0;
		var o:h2d.Object = bitmaps[0];
		while (o != null && o != root) {
			x += o.x;
			o = o.parent;
		}
		return x;
	}

	/** Codegen must place the element where the builder does (non-zero hex pixel). */
	@Test
	public function testHexNamed_Codegen_PositionsAtNamedHexCoord():Void {
		final builderResult = BuilderTestBase.buildFromFile(FIXTURE, "hexNamed", null);
		final builderX = singleBitmapX(builderResult.object);
		Assert.isTrue(builderX != 0,
			"builder baseline: $h.cube(1, 0, 0) on a flat(20, 20) system lands at a non-zero x");

		final inst:Dynamic = createMp().hexNamed.create();
		final codegenX = singleBitmapX(cast inst);
		Assert.floatEquals(builderX, codegenX,
			'codegen: a runtime named-hex coordinate must position the element like the builder '
			+ '(expected x=$builderX, got x=$codegenX — currently silently left at 0,0)');
	}
}
