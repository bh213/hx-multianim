package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Builder vs codegen parity for conditionals on STRING and FLOAT parameters.
 *
 * String params, integer-parseable value:
 *   `@(version => 2)` on a string param must mean string equality (version == "2").
 *   The parser's stringToConditional has no PPTString arm, so it falls into the
 *   default Std.parseInt branch and produces CoValue(2). The builder's CoValue match
 *   then sees a StringValue and throws 'invalid param types'; codegen emits
 *   `_version == 2` (String == Int) which fails to compile. (The codegen equality
 *   case cannot be exercised as a test until the parser produces CoStringValue —
 *   before the fix it does not compile — so it is added as a green-only fixture.)
 *
 * String params, @switch pipe arm:
 *   `@switch(label) { "alpha" | "beta": ... }` routes the pipe arm to CoEnums.
 *   Codegen's all-enum switch maps each value via findEnumIndex whose default
 *   Std.parseInt returns null for non-numeric strings, so the arm is dropped and
 *   label="beta" silently falls to the default arm. The builder matches correctly.
 *
 * Float params, equality:
 *   `@(weight => 1)` equality on a float param is rejected at parse time (see
 *   ParserErrorTest) — consistent with @switch already rejecting float params.
 *   Float comparisons and ranges (>=, <=, a..b) remain supported.
 *
 * Companion fixture: test/examples/134-stringFloatConditional/stringFloatConditional.manim
 */
class StringFloatConditionalParityTest extends BuilderTestBase {
	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	// ==================== String param: integer-parseable equality value ====================

	@Test
	public function testBuilder_StringParamNumericValueEquality_Matches():Void {
		final src = '#x programmable(version:string="v2") { @(version => 2) bitmap(generated(color(10, 6, #00ff00))): 0, 0 }';
		var thrown:Null<String> = null;
		var result = null;
		try {
			result = BuilderTestBase.buildFromSource(src, "x", ["version" => "2"]);
		} catch (e:Dynamic) {
			thrown = Std.string(e);
		}
		Assert.isNull(thrown,
			'building @(version => 2) on a string param with version="2" must not throw (string equality); threw: $thrown');
		if (result != null) {
			Assert.equals(1, BuilderTestBase.findVisibleBitmapDescendants(result.object).length,
				'@(version => 2) must match when version == "2" (string equality)');
		}
	}

	// Codegen equality on a string param — only compilable once the parser produces
	// CoStringValue (see fixture note). version default "v2" must not match; "2" must.
	@Test
	public function testCodegen_StringParamNumericValueEquality_Matches():Void {
		final inst:Dynamic = createMp().stringEqNumeric.create();
		final obj:h2d.Object = cast inst;
		Assert.equals(0, BuilderTestBase.findVisibleBitmapDescendants(obj).length,
			'codegen: version="v2" must not match @(version => 2)');
		inst.setParameter("version", "2");
		Assert.equals(1, BuilderTestBase.findVisibleBitmapDescendants(obj).length,
			'codegen: version="2" must match @(version => 2) via string equality');
	}

	@Test
	public function testBuilder_StringParamNumericValueEquality_NoMatchWhenDifferent():Void {
		final src = '#x programmable(version:string="v2") { @(version => 2) bitmap(generated(color(10, 6, #00ff00))): 0, 0 }';
		var thrown:Null<String> = null;
		var result = null;
		try {
			result = BuilderTestBase.buildFromSource(src, "x", ["version" => "3"]);
		} catch (e:Dynamic) {
			thrown = Std.string(e);
		}
		Assert.isNull(thrown, 'building @(version => 2) with version="3" must not throw; threw: $thrown');
		if (result != null) {
			Assert.equals(0, BuilderTestBase.findVisibleBitmapDescendants(result.object).length,
				'@(version => 2) must NOT match when version == "3"');
		}
	}

	// ==================== String param: @switch pipe arm ====================

	// Builder already matches CoEnums against the string correctly — this documents
	// the reference behavior the codegen path must match.
	@Test
	public function testBuilder_StringPipeSwitchArm_Matches():Void {
		final src = '#stringPipeSwitch programmable(label:string="hello") { @switch(label) { "alpha" | "beta": bitmap(generated(color(10, 6, #00ff00))): 0, 0   default: bitmap(generated(color(20, 6, #ff0000))): 0, 0 } }';
		final result = BuilderTestBase.buildFromSource(src, "stringPipeSwitch", ["label" => "beta"]);
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width),
			'builder: @switch pipe arm "alpha"|"beta" matches label="beta" (width 10)');
	}

	@Test
	public function testCodegen_StringPipeSwitchArm_MatchesNonDefault():Void {
		final inst:Dynamic = createMp().stringPipeSwitch.create();
		final obj:h2d.Object = cast inst;
		inst.setParameter("label", "beta");
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(obj);
		Assert.equals(1, bitmaps.length, "exactly one arm visible");
		Assert.equals(10, Std.int(bitmaps[0].tile.width),
			'codegen: @switch pipe arm "alpha"|"beta" must match label="beta" (width 10), not fall through to default (width 20)');
	}
}
