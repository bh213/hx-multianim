package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Regression — `staticRef($X, p => $outerEnum)` codegen must forward a parent enum
 * param by NAME, matching the runtime builder.
 *
 * Bug shape: ProgrammableCodeGen.generateStaticRefCreate builds the forwarded-param
 * map with rvToExpr(val), which emits an enum ref as its raw Int storage index. That
 * index flows into _pb.buildStaticRef -> buildWithParameters -> dynamicValueToIndex,
 * which stringifies the int ("0") and rejects it against the PPTEnum value list — so
 * codegen create() throws while the runtime builder (which resolves the reference in
 * context) succeeds. The sibling dynamicRef sites already forward enums by name via
 * dynamicRefForwardValueExpr.
 *
 * Companion fixture:
 * test/examples/124-codegenStaticRefEnumForwarding/codegenStaticRefEnumForwarding.manim
 */
class CodegenStaticRefForwardingTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/124-codegenStaticRefEnumForwarding/codegenStaticRefEnumForwarding.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	/** Runtime builder baseline: a staticRef forwarding a parent enum into a child enum
	 *  param resolves the reference in context for both the default and an overridden value. */
	@Test
	public function testEnumForwarding_Builder_ForwardsParentEnumToChild():Void {
		final defResult = BuilderTestBase.buildFromFile(FIXTURE, "codegenStaticRefEnumForwarding", null);
		var bitmaps = BuilderTestBase.findVisibleBitmapDescendants(defResult.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(11, Std.int(bitmaps[0].tile.width), "default parentMode=a forwards to child mode=a (width 11)");

		final params = new Map<String, Dynamic>();
		params.set("parentMode", "b");
		final bResult = BuilderTestBase.buildFromFile(FIXTURE, "codegenStaticRefEnumForwarding", params);
		bitmaps = BuilderTestBase.findVisibleBitmapDescendants(bResult.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(22, Std.int(bitmaps[0].tile.width),
			"runtime builder: parentMode=b forwards to child mode=b (width 22)");
	}

	/** Codegen: staticRef forwarding a parent enum must build the child at the parent's enum
	 *  value (by name) at construction. Before the fix, the forwarded raw Int index is rejected
	 *  by the child's dynamicValueToIndex and create() throws — even for the default value. */
	@Test
	public function testEnumForwarding_Codegen_ForwardsParentEnumToChild():Void {
		final mp = createMp();
		final defInst:Dynamic = mp.codegenStaticRefEnumForwarding.create();
		var bitmaps = BuilderTestBase.findVisibleBitmapDescendants(cast defInst);
		Assert.equals(1, bitmaps.length);
		Assert.equals(11, Std.int(bitmaps[0].tile.width), "default codegen: parentMode=a -> child mode=a (width 11)");

		// Codegen enum params take the Int index publicly; 1 == "b".
		final bInst:Dynamic = createMp().codegenStaticRefEnumForwarding.create(1);
		bitmaps = BuilderTestBase.findVisibleBitmapDescendants(cast bInst);
		Assert.equals(1, bitmaps.length);
		Assert.equals(22, Std.int(bitmaps[0].tile.width),
			"codegen create(1 == \"b\"): parentMode=b must forward to child mode=b (width 22)");
	}
}
