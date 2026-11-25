package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Regression — `staticRef($param)` where $param is a string parameter naming the
 * target programmable must resolve the name dynamically in codegen, matching the
 * runtime builder.
 *
 * Bug shape: ProgrammableCodeGen STATIC_REF dispatch collapses RVReference to a
 * literal string, so generateStaticRefCreate emits buildStaticRef("which", ...)
 * — a programmable literally named after the parameter, which does not exist —
 * producing an empty object. The builder resolves $which through indexedParams
 * (resolveRefName) and builds the correct target. The sibling dynamicRef path
 * already routes param-named refs to generateDynamicNameRefCreate.
 *
 * Companion fixture:
 * test/examples/128-codegenStaticRefDynamicName/staticRefDynamicName.manim
 */
class CodegenStaticRefDynamicNameTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/128-codegenStaticRefDynamicName/staticRefDynamicName.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	/** Runtime builder baseline: staticRef($which) resolves the parent string param
	 *  to the target programmable for both the default and an overridden value. */
	@Test
	public function testDynamicName_Builder_ResolvesParamToTarget():Void {
		final defResult = BuilderTestBase.buildFromFile(FIXTURE, "codegenStaticRefDynamicName", null);
		var bitmaps = BuilderTestBase.findVisibleBitmapDescendants(defResult.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(11, Std.int(bitmaps[0].tile.width), "default which=srChildRed -> red bitmap (width 11)");

		final params = new Map<String, Dynamic>();
		params.set("which", "srChildBlue");
		final bResult = BuilderTestBase.buildFromFile(FIXTURE, "codegenStaticRefDynamicName", params);
		bitmaps = BuilderTestBase.findVisibleBitmapDescendants(bResult.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(22, Std.int(bitmaps[0].tile.width),
			"runtime builder: which=srChildBlue -> blue bitmap (width 22)");
	}

	/** Codegen: staticRef($which) must build the programmable named by the parent
	 *  string param at construction. Before the fix the literal "which" name builds
	 *  a nonexistent programmable, yielding an empty object with no bitmap. */
	@Test
	public function testDynamicName_Codegen_ResolvesParamToTarget():Void {
		final mp = createMp();
		final defInst:Dynamic = mp.codegenStaticRefDynamicName.create();
		var bitmaps = BuilderTestBase.findVisibleBitmapDescendants(cast defInst);
		Assert.equals(1, bitmaps.length, "default which=srChildRed must build the red child");
		Assert.equals(11, Std.int(bitmaps[0].tile.width), "default codegen: which=srChildRed -> red bitmap (width 11)");

		final bInst:Dynamic = createMp().codegenStaticRefDynamicName.create("srChildBlue");
		bitmaps = BuilderTestBase.findVisibleBitmapDescendants(cast bInst);
		Assert.equals(1, bitmaps.length, "which=srChildBlue must build the blue child");
		Assert.equals(22, Std.int(bitmaps[0].tile.width),
			"codegen create(\"srChildBlue\"): must resolve param to blue bitmap (width 22)");
	}
}
