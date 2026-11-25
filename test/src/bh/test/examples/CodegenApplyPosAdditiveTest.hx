package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.buildFromFile;

/**
 * `apply { pos: dx, dy }` must compose additively with the parent's existing
 * placement — when the apply matches, the offset is ADDED to the parent's base
 * position, not used as an absolute position. The builder uses addPosition; the
 * codegen path emitted an absolute setPosition, dropping the base placement of
 * any non-root container (root pos is unaffected — it lives in a separate holder).
 *
 * Companion fixture: test/examples/126-codegenApplyPosAdditive/codegenApplyPosAdditive.manim
 * Parent #box is positioned at (100, 50); @(hover) apply { pos: 5, 5 } must yield (105, 55).
 * The programmable root has no pos:, so its only child is the #box container.
 */
class CodegenApplyPosAdditiveTest extends BuilderTestBase {
	static inline var MANIM_PATH = "test/examples/126-codegenApplyPosAdditive/codegenApplyPosAdditive.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	@Test
	public function testApplyPos_AdditiveOnPositionedContainer_Builder():Void {
		final result = buildFromFile(MANIM_PATH, "codegenApplyPosAdditive", null, Incremental);
		final box = result.object.getChildAt(0);
		Assert.notNull(box, "container child must exist");
		Assert.floatEquals(100.0, box.x, "ctor: base x");
		Assert.floatEquals(50.0, box.y, "ctor: base y");

		result.setParameter("hover", true);
		Assert.floatEquals(105.0, box.x, "hover: apply pos adds to base x (100 + 5)");
		Assert.floatEquals(55.0, box.y, "hover: apply pos adds to base y (50 + 5)");

		result.setParameter("hover", false);
		Assert.floatEquals(100.0, box.x, "hover off: base x restored");
		Assert.floatEquals(50.0, box.y, "hover off: base y restored");
	}

	@Test
	public function testApplyPos_AdditiveOnPositionedContainer_Codegen():Void {
		final mp = createMp();
		final inst:Dynamic = mp.codegenApplyPosAdditive.create();
		final root:h2d.Object = cast inst;
		final box = root.getChildAt(0);
		Assert.notNull(box, "container child must exist");
		Assert.floatEquals(100.0, box.x, "ctor: base x");
		Assert.floatEquals(50.0, box.y, "ctor: base y");

		inst.setHover(true);
		Assert.floatEquals(105.0, box.x, "hover: apply pos adds to base x (100 + 5)");
		Assert.floatEquals(55.0, box.y, "hover: apply pos adds to base y (50 + 5)");

		inst.setHover(false);
		Assert.floatEquals(100.0, box.x, "hover off: base x restored");
		Assert.floatEquals(50.0, box.y, "hover off: base y restored");
	}
}
