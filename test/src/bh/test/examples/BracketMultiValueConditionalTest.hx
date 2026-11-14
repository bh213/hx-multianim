package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Regression — bracket multi-value conditionals `@(p => [a,b])` / `@(p != [a,b])`
 * must behave the same in runtime (MultiAnimBuilder) and codegen (ProgrammableCodeGen)
 * for every discrete param type, not just enum.
 *
 * The bracket parser cases built raw `CoEnums` unconditionally and read values with
 * expectIdentifierOrString, diverging from the single-value and `@switch` pipe-arm paths:
 *  - bool: runtime `CoEnums(["true","false"]).contains(Std.string(1))` never matches.
 *  - int:  codegen `CoEnums` -> enumValueToIndex -> 0, emitting `_level == 0` (always-0);
 *          integer literals also failed to parse (expectIdentifierOrString).
 *  - string: codegen would emit `String == 0` (compile error) — now exercised here.
 *
 * Fix mirrors @switch: read values via parseConditionalValue, then route enum/string ->
 * CoEnums, other types -> CoAnyOf(stringToConditional).
 *
 * Companion fixture:
 * test/examples/130-bracketMultiValueConditional/bracketMultiValueConditional.manim
 */
class BracketMultiValueConditionalTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/130-bracketMultiValueConditional/bracketMultiValueConditional.manim";
	static inline var PROG = "bracketMultiValueConditional";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	// Arms keyed by tile width: 10 = int affirmative, 20 = int negated,
	// 30 = bool affirmative, 40 = string affirmative.
	static function countByWidth(obj:h2d.Object):{intAffirm:Int, intNeg:Int, boolAffirm:Int, strAffirm:Int} {
		var intAffirm = 0, intNeg = 0, boolAffirm = 0, strAffirm = 0;
		for (b in BuilderTestBase.findVisibleBitmapDescendants(obj)) {
			switch (Std.int(b.tile.width)) {
				case 10: intAffirm++;
				case 20: intNeg++;
				case 30: boolAffirm++;
				case 40: strAffirm++;
				default:
			}
		}
		return {intAffirm: intAffirm, intNeg: intNeg, boolAffirm: boolAffirm, strAffirm: strAffirm};
	}

	// ==================== Runtime (MultiAnimBuilder) ====================

	@Test
	public function testRuntimeBracketMultiValueMatchesAtDefaults():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, PROG, null, Incremental);
		final c = countByWidth(result.object);
		Assert.equals(1, c.intAffirm, "Builder: level=3 in [1,3] should match. Got " + c.intAffirm);
		Assert.equals(1, c.intNeg, "Builder: level=3 not in [2,4] should match. Got " + c.intNeg);
		// The bug: bool stored as Value(1) compared against the strings "true"/"false".
		Assert.equals(1, c.boolAffirm, "Builder: flag=true in [true,false] must match (bool bracket must not be string-keyed). Got " + c.boolAffirm);
		Assert.equals(1, c.strAffirm, "Builder: name=\"a\" in [a,b] should match. Got " + c.strAffirm);
	}

	@Test
	public function testRuntimeNegatedBracketRespectsMembership():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, PROG, null, Incremental);
		result.setParameter("level", 2);
		final c = countByWidth(result.object);
		// level=2 IS in [2,4] -> negated arm must NOT match.
		Assert.equals(0, c.intNeg, "Builder: level=2 in [2,4] must NOT match negated bracket. Got " + c.intNeg);
		Assert.equals(0, c.intAffirm, "Builder: level=2 not in [1,3] must NOT match affirmative bracket. Got " + c.intAffirm);
	}

	// ==================== Codegen (ProgrammableCodeGen) ====================

	@Test
	public function testCodegenBracketMultiValueMatchesAtDefaults():Void {
		final mp = createMp();
		final inst:Dynamic = mp.bracketMultiValueConditional.create();
		final obj:h2d.Object = cast inst;
		final c = countByWidth(obj);
		// The bug: int routes through enumValueToIndex -> 0, emitting `_level == 0` (always-0).
		Assert.equals(1, c.intAffirm, "Codegen: level=3 in [1,3] must match (int bracket must not collapse to ==0). Got " + c.intAffirm);
		Assert.equals(1, c.intNeg, "Codegen: level=3 not in [2,4] should match. Got " + c.intNeg);
		Assert.equals(1, c.boolAffirm, "Codegen: flag=true in [true,false] should match. Got " + c.boolAffirm);
		// String bracket previously emitted `String == 0` (compile error); must now match.
		Assert.equals(1, c.strAffirm, "Codegen: name=\"a\" in [a,b] must match. Got " + c.strAffirm);
	}

	@Test
	public function testCodegenNegatedBracketRespectsMembership():Void {
		final mp = createMp();
		final inst:Dynamic = mp.bracketMultiValueConditional.create();
		final obj:h2d.Object = cast inst;
		inst.setParameter("level", 2);
		final c = countByWidth(obj);
		// The bug: codegen CoNot wraps an always-false CoEnums -> always-true, firing wrongly.
		Assert.equals(0, c.intNeg, "Codegen: level=2 in [2,4] must NOT match negated bracket. Got " + c.intNeg);
		Assert.equals(0, c.intAffirm, "Codegen: level=2 not in [1,3] must NOT match affirmative bracket. Got " + c.intAffirm);
	}
}
