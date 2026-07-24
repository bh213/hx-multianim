package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.BuildMode;
import bh.test.BuilderTestBase.buildFromFile;
import bh.test.BuilderTestBase.buildFromSource;

/**
 * Regression — unconditional `apply { ... }` must re-apply when a referenced
 * parameter changes. Covers both the builder (incremental) and codegen paths.
 *
 * Companion fixture: test/examples/108-applyParamUpdate/applyParamUpdate.manim
 */
class ApplyParamUpdateTest extends BuilderTestBase {
	static inline var MANIM_PATH = "test/examples/108-applyParamUpdate/applyParamUpdate.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	@Test
	public function testApply_UnconditionalParamUpdate_Builder():Void {
		final result = buildFromFile(MANIM_PATH, "applyParamUpdate", null, Incremental);
		Assert.floatEquals(0.5, result.object.scaleX, "ctor scaleX from k=0.5");
		Assert.floatEquals(1.0, result.object.alpha,  "ctor alpha from a=1.0");

		result.setParameter("k", 2.0);
		Assert.floatEquals(2.0, result.object.scaleX, "scaleX after setParameter(k, 2.0)");

		result.setParameter("a", 0.25);
		Assert.floatEquals(0.25, result.object.alpha, "alpha after setParameter(a, 0.25)");
	}

	@Test
	public function testRootLevelExtendedProps_RefireOnSetParameter_Builder():Void {
		final result = buildFromSource("
			#x programmable(s:float=1.0, a:float=1.0) {
				scale: $s
				alpha: $a
				bitmap(generated(color(40, 40, #4488ff))): 0, 0
			}
		", "x", null, Incremental);
		Assert.floatEquals(1.0, result.object.scaleX, "ctor scaleX from s=1.0");
		Assert.floatEquals(1.0, result.object.alpha,  "ctor alpha from a=1.0");

		result.setParameter("s", 2.0);
		Assert.floatEquals(2.0, result.object.scaleX, "root scaleX after setParameter(s, 2.0)");

		result.setParameter("a", 0.25);
		Assert.floatEquals(0.25, result.object.alpha, "root alpha after setParameter(a, 0.25)");
	}

	@Test
	public function testApply_UnconditionalParamUpdate_Codegen():Void {
		final mp = createMp();
		final inst:Dynamic = mp.applyParamUpdate.create();
		final obj:h2d.Object = cast inst;
		Assert.floatEquals(0.5, obj.scaleX, "ctor scaleX");
		Assert.floatEquals(1.0, obj.alpha,  "ctor alpha");

		inst.setK(2.0);
		Assert.floatEquals(2.0, obj.scaleX, "scaleX after setK(2.0)");

		inst.setA(0.25);
		Assert.floatEquals(0.25, obj.alpha, "alpha after setA(0.25)");
	}
}
