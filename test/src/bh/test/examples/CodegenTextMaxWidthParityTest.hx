package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * text() maxWidth parity gaps:
 *
 * - maxWidth with a param-dependent scale: the builder divides maxWidth by
 *   the live resolved scale; the codegen resolves the divisor with the
 *   static-only resolver and bakes 1.0 for $param scales.
 * - TAWGrid ("grid" in the maxWidth slot): the builder takes maxWidth from
 *   the enclosing grid spacing; the codegen never implemented the arm and
 *   silently drops it.
 *
 * Companion fixture: test/examples/149-codegenTextWidth/textWidth.manim
 */
class CodegenTextMaxWidthParityTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/149-codegenTextWidth/textWidth.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function findFirstText(o:h2d.Object):Null<h2d.Text> {
		if (Std.isOfType(o, h2d.Text))
			return cast o;
		for (i in 0...o.numChildren) {
			final t = findFirstText(o.getChildAt(i));
			if (t != null)
				return t;
		}
		return null;
	}

	static function textMaxWidth(root:h2d.Object, backend:String):Null<Float> {
		final t = findFirstText(root);
		Assert.notNull(t, '$backend: expected a text element');
		return t != null ? t.maxWidth : null;
	}

	// ==================== maxWidth / param scale ====================

	/** Builder baseline: maxWidth 100 at scale $s=2 -> 50. */
	@Test
	public function testScaledMaxWidth_Builder_DividesByLiveScale():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "tScale", null);
		final mw = textMaxWidth(result.object, "builder");
		Assert.notNull(mw, "builder: maxWidth set");
		if (mw != null)
			Assert.floatEquals(50, mw, "builder: maxWidth 100 with scale $s=2.0 resolves to 50");
	}

	/** Codegen: the divisor must be the live scale, not a baked 1.0. */
	@Test
	public function testScaledMaxWidth_Codegen_DividesByLiveScale():Void {
		final inst:Dynamic = createMp().tScale.create();
		final mw = textMaxWidth(cast inst, "codegen");
		Assert.notNull(mw, "codegen: maxWidth set");
		if (mw != null)
			Assert.floatEquals(50, mw,
				"codegen: maxWidth 100 with scale $s=2.0 must resolve to 50 (param scale currently bakes divisor 1.0)");
	}

	// ==================== TAWGrid ====================

	/** Builder baseline: grid-aligned text takes maxWidth from grid spacing. */
	@Test
	public function testGridMaxWidth_Builder_UsesGridSpacing():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "tGrid", null);
		final mw = textMaxWidth(result.object, "builder");
		Assert.notNull(mw, "builder: TAWGrid sets maxWidth");
		if (mw != null)
			Assert.floatEquals(64, mw, "builder: TAWGrid takes maxWidth from the 64px grid spacing");
	}

	/** Codegen: TAWGrid must not be silently dropped. */
	@Test
	public function testGridMaxWidth_Codegen_UsesGridSpacing():Void {
		final inst:Dynamic = createMp().tGrid.create();
		final mw = textMaxWidth(cast inst, "codegen");
		Assert.notNull(mw, "codegen: TAWGrid must set maxWidth (currently dropped entirely)");
		if (mw != null)
			Assert.floatEquals(64, mw, "codegen: TAWGrid must take maxWidth from the 64px grid spacing");
	}
}
