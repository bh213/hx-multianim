package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Regression — literal-name `dynamicRef($X, p => $outer)` codegen must propagate
 * a parent-param change into the child's forwarded param, matching the runtime
 * builder (MultiAnimBuilder.trackDynamicRef wires this unconditionally).
 *
 * Bug shape: ProgrammableCodeGen.generateDynamicRefCreate builds _refParams at
 * construction and returns exprUpdates: [] — nothing is pushed to expressionUpdates
 * for the literal-name dynamicRef. The dynamic-name variant
 * (generateDynamicNameRefCreate) does push a forwarded-param updater. So codegen
 * setParameter on the parent leaves the child silently stale, while the runtime
 * builder updates the child.
 *
 * Companion fixture:
 * test/examples/118-codegenDynamicRefForwarding/codegenDynamicRefForwarding.manim
 */
class CodegenDynamicRefForwardingTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/118-codegenDynamicRefForwarding/codegenDynamicRefForwarding.manim";
	static inline var ENUM_FIXTURE = "test/examples/122-codegenDynamicRefEnumForwarding/codegenDynamicRefEnumForwarding.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	/** Runtime builder baseline: setParameter on the parent must update the child's
	 *  forwarded param. This already works via trackDynamicRef; the test guards
	 *  against regression on the builder side. */
	@Test
	public function testLiteralNameDynamicRef_Builder_ForwardsParentParamToChild():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "codegenDynamicRefForwarding", null, Incremental);

		var bitmaps = BuilderTestBase.findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width), "initial width = parentVal default 10");

		result.setParameter("parentVal", 75);
		bitmaps = BuilderTestBase.findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(75, Std.int(bitmaps[0].tile.width),
			"runtime builder: child's val must reflect parent.setParameter('parentVal', 75)");
	}

	/** Codegen typed setter must forward the parent param change to the child's
	 *  literal-name dynamicRef. Before the fix, generateDynamicRefCreate registers
	 *  no expressionUpdates entry → the setter does not call into the child
	 *  incremental context → the child stays stuck at the construction value. */
	@Test
	public function testLiteralNameDynamicRef_Codegen_TypedSetterForwardsParentParamToChild():Void {
		final mp = createMp();
		final inst:Dynamic = mp.codegenDynamicRefForwarding.create();
		final obj:h2d.Object = cast inst;

		var bitmaps = BuilderTestBase.findVisibleBitmapDescendants(obj);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width), "initial codegen width = parentVal default 10");

		inst.setParentVal(75);
		bitmaps = BuilderTestBase.findVisibleBitmapDescendants(obj);
		Assert.equals(1, bitmaps.length);
		Assert.equals(75, Std.int(bitmaps[0].tile.width),
			"codegen typed setter setParentVal(75) must propagate into child's val");
	}

	/** Same coverage via the setParameter dispatcher path (not the typed setter).
	 *  Both routes share the same generated setter body, but pinning both forms
	 *  protects against an asymmetric fix. */
	@Test
	public function testLiteralNameDynamicRef_Codegen_SetParameterForwardsParentParamToChild():Void {
		final mp = createMp();
		final inst:Dynamic = mp.codegenDynamicRefForwarding.create();
		final obj:h2d.Object = cast inst;

		inst.setParameter("parentVal", 42);
		var bitmaps = BuilderTestBase.findVisibleBitmapDescendants(obj);
		Assert.equals(1, bitmaps.length);
		Assert.equals(42, Std.int(bitmaps[0].tile.width),
			"codegen setParameter('parentVal', 42) dispatcher must propagate into child's val");
	}

	// ==================== Enum forwarding ====================

	/** Runtime builder: forwarding a parent ENUM into a child enum param must update the
	 *  child after setParameter on the parent (forwarded by name). */
	@Test
	public function testEnumForwarding_Builder_ForwardsParentEnumToChild():Void {
		final result = BuilderTestBase.buildFromFile(ENUM_FIXTURE, "codegenDynamicRefEnumForwarding", null, Incremental);

		var bitmaps = BuilderTestBase.findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(11, Std.int(bitmaps[0].tile.width), "initial: parentMode=a forwards to child mode=a (width 11)");

		result.setParameter("parentMode", "b");
		bitmaps = BuilderTestBase.findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(22, Std.int(bitmaps[0].tile.width),
			"runtime builder: forwarded enum must update child to mode=b after setParameter('parentMode','b')");
	}

	/** Codegen: forwarding a parent ENUM into a child enum param. The generated code emits
	 *  the parent enum field's Int index for the forwarded value, which the child's
	 *  setParameter rejects (dynamicValueToIndex stringifies the int). The child must end up
	 *  at the parent's enum value (by name) both at construction and after setParameter. */
	@Test
	public function testEnumForwarding_Codegen_ForwardsParentEnumToChild():Void {
		final mp = createMp();
		final inst:Dynamic = mp.codegenDynamicRefEnumForwarding.create();
		final obj:h2d.Object = cast inst;

		var bitmaps = BuilderTestBase.findVisibleBitmapDescendants(obj);
		Assert.equals(1, bitmaps.length);
		Assert.equals(11, Std.int(bitmaps[0].tile.width), "initial codegen: parentMode=a -> child mode=a (width 11)");

		inst.setParameter("parentMode", "b");
		bitmaps = BuilderTestBase.findVisibleBitmapDescendants(obj);
		Assert.equals(1, bitmaps.length);
		Assert.equals(22, Std.int(bitmaps[0].tile.width),
			"codegen setParameter('parentMode','b') must propagate into child's mode (width 22)");
	}
}
