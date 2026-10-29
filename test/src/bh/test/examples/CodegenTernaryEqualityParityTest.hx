package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Ternary `?(cond)` equality parity between builder and codegen.
 *
 * The builder's resolveAsBool (MultiAnimBuilder.hx) evaluates == / != as STRING equality —
 * enum params compared by value NAME, string params by content. Codegen's rvToExpr previously
 * emitted numeric `_field == "..."` for the ternary condition, which is an `Int == String`
 * macro compile error when the operand is an enum or string param (those are typed :Int / :String
 * in codegen). So `?($status == "hover") a : b` could not be expressed in a codegen programmable
 * at all. After the fix, rvToExpr emits a string/enum comparison and both backends agree.
 *
 * Companion fixture: test/examples/135-codegenTernaryEquality/ternaryEquality.manim
 */
class CodegenTernaryEqualityParityTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/135-codegenTernaryEquality/ternaryEquality.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	/** Sum of x offsets from `obj` up to (excluding) `root` — robust against wrapper objects
	 *  differing between the builder and codegen scene graphs. */
	static function xToRoot(obj:h2d.Object, root:h2d.Object):Float {
		var x = 0.0;
		var o:h2d.Object = obj;
		while (o != null && o != root) {
			x += o.x;
			o = o.parent;
		}
		return x;
	}

	static function singleBitmapX(root:h2d.Object):Float {
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(root);
		Assert.equals(1, bitmaps.length);
		return xToRoot(bitmaps[0], root);
	}

	// ==================== Enum param == string literal ====================

	@Test
	public function testTernaryEnumEq_Builder():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "ternaryEnumEq", null);
		Assert.floatEquals(40.0, singleBitmapX(result.object),
			"builder: ?($status == \"hover\") 40 : 0 with status=hover -> x=40");
	}

	@Test
	public function testTernaryEnumEq_Codegen():Void {
		final inst:Dynamic = createMp().ternaryEnumEq.create();
		Assert.floatEquals(40.0, singleBitmapX(cast inst),
			"codegen: ?($status == \"hover\") 40 : 0 with status=hover must compile (enum-by-name compare) and land at x=40");
	}

	/** Builder control: the condition genuinely toggles (not constant-true) — status=normal -> x=0. */
	@Test
	public function testTernaryEnumEq_Builder_FalseBranch():Void {
		final params = new Map<String, Dynamic>();
		params.set("status", "normal");
		final result = BuilderTestBase.buildFromFile(FIXTURE, "ternaryEnumEq", params);
		Assert.floatEquals(0.0, singleBitmapX(result.object),
			"builder: ?($status == \"hover\") 40 : 0 with status=normal -> x=0");
	}

	/** Codegen control: setParameter toggles the condition to its false branch (x=0). */
	@Test
	public function testTernaryEnumEq_Codegen_FalseBranch():Void {
		final inst:Dynamic = createMp().ternaryEnumEq.create();
		inst.setParameter("status", "normal");
		Assert.floatEquals(0.0, singleBitmapX(cast inst),
			"codegen: ?($status == \"hover\") 40 : 0 with status=normal must land at x=0");
	}

	// ==================== Enum param != string literal ====================

	@Test
	public function testTernaryEnumNotEq_Builder():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "ternaryEnumNotEq", null);
		Assert.floatEquals(25.0, singleBitmapX(result.object),
			"builder: ?($status != \"hover\") 25 : 5 with status=normal -> x=25");
	}

	@Test
	public function testTernaryEnumNotEq_Codegen():Void {
		final inst:Dynamic = createMp().ternaryEnumNotEq.create();
		Assert.floatEquals(25.0, singleBitmapX(cast inst),
			"codegen: ?($status != \"hover\") 25 : 5 with status=normal must land at x=25");
	}

	// ==================== String param == string literal ====================

	@Test
	public function testTernaryStringEq_Builder():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "ternaryStringEq", null);
		Assert.floatEquals(30.0, singleBitmapX(result.object),
			"builder: ?($mode == \"go\") 30 : 5 with mode=go -> x=30");
	}

	@Test
	public function testTernaryStringEq_Codegen():Void {
		final inst:Dynamic = createMp().ternaryStringEq.create();
		Assert.floatEquals(30.0, singleBitmapX(cast inst),
			"codegen: ?($mode == \"go\") 30 : 5 with mode=go must land at x=30");
	}
}
