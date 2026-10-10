package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Layout points referencing a programmable param ($gap).
 *
 * Both backends currently get this wrong, in different ways:
 * - builder: MultiAnimLayouts resolves layout points against an indexedParams
 *   map that holds only the loop var, so `$gap` throws "reference gap does
 *   not exist" (the builder-side layout param-scope bug — audit BLD-8).
 * - codegen: the layout repeat is a compile-time-only unroll whose static
 *   point resolution returns null for $param refs — the iteration containers
 *   get NO position and every iteration silently lands at 0,0.
 *
 * Both tests describe the correct behavior ($gap resolves against the
 * programmable's params) and stay red until their respective fixes.
 *
 * Companion fixture: test/examples/150-codegenLayoutParamPts/layoutParamPts.manim
 */
class CodegenLayoutParamPointsTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/150-codegenLayoutParamPts/layoutParamPts.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function xToRoot(obj:h2d.Object, root:h2d.Object):Float {
		var x = 0.0;
		var o:h2d.Object = obj;
		while (o != null && o != root) {
			x += o.x;
			o = o.parent;
		}
		return x;
	}

	static function bitmapXs(root:h2d.Object):Array<Float> {
		final xs = [for (b in BuilderTestBase.findVisibleBitmapDescendants(root)) xToRoot(b, root)];
		xs.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
		return xs;
	}

	static function assertXs(expected:Array<Float>, actual:Array<Float>, msg:String):Void {
		Assert.equals(expected.length, actual.length,
			'$msg — expected ${expected.length} bitmaps, got ${actual.length} at $actual');
		if (expected.length == actual.length)
			for (i in 0...expected.length)
				Assert.floatEquals(expected[i], actual[i],
					'$msg — position $i: expected ${expected[i]}, got ${actual[i]} (all: $actual)');
	}

	/** Builder baseline: $gap=30 spaces the three layout points 0/30/60. */
	@Test
	public function testLayoutParamPoints_Builder_ResolvesParamPoints():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "layoutParam", null);
		assertXs([0, 30, 60], bitmapXs(result.object), "builder: layout points 0, $gap, $gap*2 with gap=30");
	}

	/** Codegen: $param layout points must position iterations, not drop to 0,0. */
	@Test
	public function testLayoutParamPoints_Codegen_ResolvesParamPoints():Void {
		final inst:Dynamic = createMp().layoutParam.create();
		assertXs([0, 30, 60], bitmapXs(cast inst),
			"codegen: layout points 0, $gap, $gap*2 with gap=30 must spread iterations, not stack them at 0,0");
	}
}
