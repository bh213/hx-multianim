package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.buildFromFile;

/**
 * Two `@(cond) apply { alpha: ... }` on the same parent must compose by resetting
 * to baseline and replaying only the matched entries in declaration order — the
 * builder's reset-and-replay semantics. Codegen previously emitted each entry as an
 * independent `if (cond) apply else revert`, so a non-matching later entry's
 * else-revert clobbered an earlier matching entry's effect.
 *
 * Companion fixture: test/examples/122-codegenOverlappingApply/codegenOverlappingApply.manim
 */
class CodegenOverlappingApplyTest extends BuilderTestBase {
	static inline var MANIM_PATH = "test/examples/122-codegenOverlappingApply/codegenOverlappingApply.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	@Test
	public function testOverlappingApply_MatchedEntryNotClobberedByLaterElse_Builder():Void {
		final result = buildFromFile(MANIM_PATH, "codegenOverlappingApply", null, Incremental);
		Assert.floatEquals(1.0, result.object.alpha, "ctor: no apply matched, baseline alpha");

		// a matches, b does not — only the first apply should take effect.
		result.beginUpdate();
		result.setParameter("a", true);
		result.setParameter("b", false);
		result.endUpdate();
		Assert.floatEquals(0.5, result.object.alpha, "a=true,b=false: first apply wins, not clobbered");

		// both match — last in declaration order wins.
		result.setParameter("b", true);
		Assert.floatEquals(0.2, result.object.alpha, "a=true,b=true: last apply in declaration order wins");

		// neither matches — back to baseline.
		result.beginUpdate();
		result.setParameter("a", false);
		result.setParameter("b", false);
		result.endUpdate();
		Assert.floatEquals(1.0, result.object.alpha, "a=false,b=false: baseline restored");
	}

	@Test
	public function testOverlappingApply_MatchedEntryNotClobberedByLaterElse_Codegen():Void {
		final mp = createMp();
		final inst:Dynamic = mp.codegenOverlappingApply.create();
		final obj:h2d.Object = cast inst;
		Assert.floatEquals(1.0, obj.alpha, "ctor: no apply matched, baseline alpha");

		inst.setA(true);
		inst.setB(false);
		Assert.floatEquals(0.5, obj.alpha, "a=true,b=false: first apply wins, not clobbered");

		inst.setB(true);
		Assert.floatEquals(0.2, obj.alpha, "a=true,b=true: last apply in declaration order wins");

		inst.setA(false);
		inst.setB(false);
		Assert.floatEquals(1.0, obj.alpha, "a=false,b=false: baseline restored");
	}
}
