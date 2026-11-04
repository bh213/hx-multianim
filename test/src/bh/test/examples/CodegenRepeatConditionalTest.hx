package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Conditionals on inline-kind children (bitmap/text/ninepatch/graphics/...) inside
 * a param-dependent repeatable must be evaluated per iteration in codegen, matching
 * the runtime builder.
 *
 * Bug shape: processParamDependentRepeat emits each body child via
 * generateRuntimeChildExprs (ProgrammableCodeGen.hx). The inline fast-path kinds
 * (BITMAP, POINT, TEXT, RICHTEXT, NINEPATCH, GRAPHICS, MASK, LAYERS, FLOW) never
 * read child.conditionals, so the element is created on every iteration regardless
 * of its @() condition. The builder resolves conditionals per iteration via
 * resolveConditionalChildren (MultiAnimBuilder REPEAT), so the same .manim renders
 * a different set of objects in the two paths. Builder-forwarded kinds are not
 * affected — buildSingleNodeWithParams honors conditionals via shouldBuildInFullMode.
 *
 * Companion fixture:
 * test/examples/131-codegenRepeatConditional/repeatConditional.manim
 */
class CodegenRepeatConditionalTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/131-codegenRepeatConditional/repeatConditional.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	/** Builder baseline: a param conditional gates the child in every iteration. */
	@Test
	public function testParamConditional_Builder_GatesChildren():Void {
		final defResult = BuilderTestBase.buildFromFile(FIXTURE, "repeatCondParam", null);
		Assert.equals(0, BuilderTestBase.findVisibleBitmapDescendants(defResult.object).length,
			"builder: show=false (default) must render no bitmaps");

		final params = new Map<String, Dynamic>();
		params.set("show", true);
		final onResult = BuilderTestBase.buildFromFile(FIXTURE, "repeatCondParam", params);
		Assert.equals(2, BuilderTestBase.findVisibleBitmapDescendants(onResult.object).length,
			"builder: show=true must render one bitmap per iteration (count=2)");
	}

	/** Codegen: the same .manim must produce the same render set. Currently the
	 *  inline bitmap is emitted unconditionally in the runtime loop body, so
	 *  show=false still renders count bitmaps. */
	@Test
	public function testParamConditional_Codegen_GatesChildren():Void {
		final defInst:Dynamic = createMp().repeatCondParam.create();
		Assert.equals(0, BuilderTestBase.findVisibleBitmapDescendants(cast defInst).length,
			"codegen: show=false (default) must render no bitmaps — conditional is dropped in the runtime repeat body");

		final onInst:Dynamic = createMp().repeatCondParam.create(true);
		Assert.equals(2, BuilderTestBase.findVisibleBitmapDescendants(cast onInst).length,
			"codegen: show=true must render one bitmap per iteration (count=2)");
	}

	/** Builder baseline: a loop-variable conditional selects a single iteration. */
	@Test
	public function testLoopVarConditional_Builder_SelectsIteration():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "repeatCondLoopVar", null);
		Assert.equals(1, BuilderTestBase.findVisibleBitmapDescendants(result.object).length,
			"builder: @($i => 0) must render only iteration 0 of count=3");
	}

	/** Codegen: the loop-variable conditional must be evaluated per iteration at
	 *  runtime. Currently all iterations render. */
	@Test
	public function testLoopVarConditional_Codegen_SelectsIteration():Void {
		final inst:Dynamic = createMp().repeatCondLoopVar.create();
		Assert.equals(1, BuilderTestBase.findVisibleBitmapDescendants(cast inst).length,
			"codegen: @($i => 0) must render only iteration 0 of count=3");
	}
}
