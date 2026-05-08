package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Regression — `setParameter("status", "<unknown enum value>")` must behave the
 * same in runtime (MultiAnimBuilder) and codegen (ProgrammableCodeGen) when the
 * template mixes the enum-typed param in both an enum match (`@(status=>v)`)
 * AND a numeric comparison/range chain (`@(status >= 0)`, `@(status => 0..2)`).
 *
 * Today the two backends diverge:
 *  - Runtime stores unknown enum strings as StringValue(s); matchSingleCondition's
 *    CoRange branch hits `default: throw` and aborts the whole rebuild.
 *  - Codegen flattens unknown enum strings to Int(-1); the generated comparison
 *    silently lights up `@(status < 0)` (wrong arm).
 *
 * Both should silently NOT match the numeric arms — symmetric with the existing
 * "no @(status=>v) arm matches" semantics that UI widgets (Button, Checkbox,
 * Tabs) rely on when calling setParameter("status", "disabled") on templates
 * whose status enum doesn't list "disabled".
 *
 * Companion fixture: test/examples/116-enumNumericConditional/enumNumericConditional.manim
 */
class EnumNumericConditionalTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/116-enumNumericConditional/enumNumericConditional.manim";
	static inline var PROG = "enumNumericConditional";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	// Visible bitmaps split by tile width: enum arms emit width 10, numeric arms emit width 20.
	static function countByWidth(obj:h2d.Object):{enumArms:Int, numericArms:Int} {
		var enumArms = 0;
		var numericArms = 0;
		for (b in BuilderTestBase.findVisibleBitmapDescendants(obj)) {
			final w = Std.int(b.tile.width);
			if (w == 10) enumArms++;
			else if (w == 20) numericArms++;
		}
		return {enumArms: enumArms, numericArms: numericArms};
	}

	// ==================== Runtime (MultiAnimBuilder) ====================

	@Test
	public function testRuntime_UnknownEnumValueDoesNotThrowOnNumericConditional():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, PROG, null, Incremental);

		// Sanity: status=normal — one enum arm, two numeric arms (>= 0 and 0..2 both true)
		var counts = countByWidth(result.object);
		Assert.equals(1, counts.enumArms, "Initial: status=normal lights one enum arm");
		Assert.equals(2, counts.numericArms, "Initial: status=normal lights @(>= 0) and @(=> 0..2) (both numerically true for 0)");

		// The bug: setParameter with an unknown enum string makes matchSingleCondition
		// throw on the @(status >= 0) / @(status < 0) / @(status => 0..2) arms because
		// StringValue("disabled") falls into `default: throw` for CoRange.
		var thrown:Null<String> = null;
		try {
			result.setParameter("status", "disabled");
		} catch (e:Dynamic) {
			thrown = Std.string(e);
		}
		Assert.isNull(thrown,
			'setParameter("status", "disabled") on enum+numeric mixed conditional must not throw; threw: $thrown');
	}

	@Test
	public function testRuntime_UnknownEnumValueDoesNotMatchNumericArms():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, PROG, null, Incremental);

		try {
			result.setParameter("status", "disabled");
		} catch (e:Dynamic) {
			// Covered by the throw-test above; bail out cleanly so this test reports
			// only the silent-mismatch contract.
			Assert.isTrue(false, "setParameter threw — see testRuntime_UnknownEnumValueDoesNotThrowOnNumericConditional");
			return;
		}

		final counts = countByWidth(result.object);
		Assert.equals(0, counts.enumArms,
			"Unknown enum value: no @(status=>v) arm should match. Got " + counts.enumArms);
		Assert.equals(0, counts.numericArms,
			"Unknown enum value: numeric/range arms must silently NOT match (unknown enum is not a number). Got " + counts.numericArms);
	}

	@Test
	public function testRuntime_KnownValueAfterUnknownStillWorks():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, PROG, null, Incremental);

		try { result.setParameter("status", "disabled"); } catch (_:Dynamic) {}

		// Restore to a real enum value — must light the right arm again.
		result.setParameter("status", "hover");
		final counts = countByWidth(result.object);
		Assert.equals(1, counts.enumArms, "After restore to hover: one enum arm visible");
		Assert.equals(2, counts.numericArms, "After restore to hover: @(>= 0) and @(=> 0..2) match (status index 1)");
	}

	// ==================== Codegen (ProgrammableCodeGen) ====================

	@Test
	public function testCodegen_UnknownEnumValueDoesNotMatchNumericArms():Void {
		final mp = createMp();
		final inst:Dynamic = mp.enumNumericConditional.create();
		final obj:h2d.Object = cast inst;

		// Sanity: status=normal — same baseline as runtime.
		var counts = countByWidth(obj);
		Assert.equals(1, counts.enumArms, "Initial codegen: one enum arm");
		Assert.equals(2, counts.numericArms, "Initial codegen: two numeric arms");

		var thrown:Null<String> = null;
		try {
			inst.setParameter("status", "disabled");
		} catch (e:Dynamic) {
			thrown = Std.string(e);
		}
		Assert.isNull(thrown,
			'codegen setParameter("status", "disabled") must not throw; threw: $thrown');

		// The bug: codegen sentinel -1 silently matches @(status < 0) -> wrong arm visible.
		counts = countByWidth(obj);
		Assert.equals(0, counts.enumArms,
			"Codegen unknown enum: no @(status=>v) arm should match. Got " + counts.enumArms);
		Assert.equals(0, counts.numericArms,
			"Codegen unknown enum: numeric/range arms must silently NOT match. Got " + counts.numericArms
			+ " (likely @(status < 0) firing because internal sentinel is -1).");
	}

	@Test
	public function testCodegen_KnownValueAfterUnknownStillWorks():Void {
		final mp = createMp();
		final inst:Dynamic = mp.enumNumericConditional.create();
		final obj:h2d.Object = cast inst;

		try { inst.setParameter("status", "disabled"); } catch (_:Dynamic) {}

		inst.setParameter("status", "pressed");
		final counts = countByWidth(obj);
		Assert.equals(1, counts.enumArms, "After codegen restore to pressed: one enum arm visible");
		Assert.equals(2, counts.numericArms, "After codegen restore to pressed: numeric arms match (index 2)");
	}
}
