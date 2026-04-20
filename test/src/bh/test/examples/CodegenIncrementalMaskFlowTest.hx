package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Regression — MASK(w, h) and FLOW(maxWidth/padding/spacing/...) scalar properties
 * referencing $params must re-apply when the param changes.
 *
 * Builder path: validated via `trackIncrementalExpressions` dispatch.
 * Codegen path: validated via `_updateExpressions()` wiring.
 *
 * Companion fixture: test/examples/110-codegenIncrementalMaskFlow/codegenIncrementalMaskFlow.manim
 */
class CodegenIncrementalMaskFlowTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/110-codegenIncrementalMaskFlow/codegenIncrementalMaskFlow.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function findMaskChild(obj:h2d.Object):Null<h2d.Mask> {
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, h2d.Mask))
				return cast child;
			final found = findMaskChild(child);
			if (found != null)
				return found;
		}
		return null;
	}

	static function findFlowChild(obj:h2d.Object):Null<h2d.Flow> {
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, h2d.Flow))
				return cast child;
			final found = findFlowChild(child);
			if (found != null)
				return found;
		}
		return null;
	}

	// ==================== MASK ====================

	@Test
	public function testMask_Builder_ParamUpdate():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "codegenIncMask", null, Incremental);
		final m = findMaskChild(result.object);
		Assert.notNull(m, "Should find h2d.Mask child");
		Assert.equals(200, m.width, "Initial mask width from w=200");
		Assert.equals(100, m.height, "Initial mask height from h=100");

		result.setParameter("w", 80);
		Assert.equals(80, m.width, "mask.width after setParameter(w, 80)");

		result.setParameter("h", 40);
		Assert.equals(40, m.height, "mask.height after setParameter(h, 40)");
	}

	@Test
	public function testMask_Codegen_ParamUpdate():Void {
		final mp = createMp();
		final inst:Dynamic = mp.codegenIncMask.create();
		final obj:h2d.Object = cast inst;

		final m = findMaskChild(obj);
		Assert.notNull(m, "Should find h2d.Mask child");
		Assert.equals(200, m.width, "Initial mask width");
		Assert.equals(100, m.height, "Initial mask height");

		inst.setW(80);
		Assert.equals(80, m.width, "mask.width after setW(80)");

		inst.setH(40);
		Assert.equals(40, m.height, "mask.height after setH(40)");
	}

	// ==================== FLOW ====================

	@Test
	public function testFlow_Builder_ParamUpdate():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "codegenIncFlow", null, Incremental);
		final f = findFlowChild(result.object);
		Assert.notNull(f, "Should find h2d.Flow child");
		Assert.equals(200, f.maxWidth, "Initial maxWidth from maxW=200");
		Assert.equals(10, f.paddingLeft, "Initial paddingLeft from pad=10");
		Assert.equals(10, f.paddingRight, "Initial paddingRight from pad=10");
		Assert.equals(5, f.horizontalSpacing, "Initial horizontalSpacing from hsp=5");

		result.setParameter("maxW", 400);
		Assert.equals(400, f.maxWidth, "maxWidth after setParameter(maxW, 400)");

		result.setParameter("pad", 25);
		Assert.equals(25, f.paddingLeft, "paddingLeft after setParameter(pad, 25)");
		Assert.equals(25, f.paddingRight, "paddingRight after setParameter(pad, 25)");

		result.setParameter("hsp", 12);
		Assert.equals(12, f.horizontalSpacing, "horizontalSpacing after setParameter(hsp, 12)");
	}

	@Test
	public function testFlow_Codegen_ParamUpdate():Void {
		final mp = createMp();
		final inst:Dynamic = mp.codegenIncFlow.create();
		final obj:h2d.Object = cast inst;

		final f = findFlowChild(obj);
		Assert.notNull(f, "Should find h2d.Flow child");
		Assert.equals(200, f.maxWidth, "Initial maxWidth");
		Assert.equals(10, f.paddingLeft, "Initial paddingLeft");
		Assert.equals(10, f.paddingRight, "Initial paddingRight");
		Assert.equals(5, f.horizontalSpacing, "Initial horizontalSpacing");

		inst.setMaxW(400);
		Assert.equals(400, f.maxWidth, "maxWidth after setMaxW(400)");

		inst.setPad(25);
		Assert.equals(25, f.paddingLeft, "paddingLeft after setPad(25)");
		Assert.equals(25, f.paddingRight, "paddingRight after setPad(25)");

		inst.setHsp(12);
		Assert.equals(12, f.horizontalSpacing, "horizontalSpacing after setHsp(12)");
	}
}
