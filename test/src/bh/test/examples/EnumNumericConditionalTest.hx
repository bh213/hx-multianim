package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.multianim.BuilderError;

/**
 * `setParameter` on an enum parameter takes a value of the enum, by name or by its index, and
 * nothing else, in the runtime builder and in codegen alike (as the build does): an unknown name
 * or an index past the values is refused with `invalid_param_value`, and what is drawn stays as it
 * was. The template mixes the enum in an enum match (`@(status=>v)`) and in numeric arms
 * (`@(status >= 0)`, `@(status => 0..2)`), which the value must keep answering.
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

	/** The code of what `fn` threw: a BuilderError's, "(none)" for another throw, null for none. */
	static function codeOf(fn:Void -> Void):Null<String> {
		try {
			fn();
			return null;
		} catch (e:BuilderError) {
			return e.code ?? "(none)";
		} catch (e:Dynamic) {
			return "(not a BuilderError: " + Std.string(e) + ")";
		}
	}

	function checkRefusesValuesOutsideTheEnum(setParameter:(String, Dynamic) -> Void, root:h2d.Object, label:String):Void {
		var counts = countByWidth(root);
		Assert.equals(1, counts.enumArms, '$label: status=normal lights one enum arm');
		Assert.equals(2, counts.numericArms, '$label: status=normal lights @(>= 0) and @(=> 0..2)');

		Assert.equals("invalid_param_value", codeOf(() -> setParameter("status", "disabled")), '$label: a name the enum has not is refused');
		Assert.equals("invalid_param_value", codeOf(() -> setParameter("status", 7)), '$label: an index past the values is refused');
		Assert.equals("invalid_param_value", codeOf(() -> setParameter("status", -1)), '$label: a negative index is refused');
		counts = countByWidth(root);
		Assert.equals(1, counts.enumArms, '$label: a refused value leaves the enum arm as it was');
		Assert.equals(2, counts.numericArms, '$label: and the numeric arms');

		setParameter("status", "hover");
		counts = countByWidth(root);
		Assert.equals(1, counts.enumArms, '$label: a value of the enum is taken after a refused one');
		Assert.equals(2, counts.numericArms, '$label: hover (index 1) lights @(>= 0) and @(=> 0..2)');
		setParameter("status", 2);
		Assert.equals(1, countByWidth(root).enumArms, '$label: an index of the enum is taken');
	}

	@Test
	public function testRuntime_RefusesValuesOutsideTheEnum():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, PROG, null, Incremental);
		checkRefusesValuesOutsideTheEnum(result.setParameter, result.object, "builder");
	}

	@Test
	public function testCodegen_RefusesValuesOutsideTheEnum():Void {
		final inst:Dynamic = createMp().enumNumericConditional.create();
		checkRefusesValuesOutsideTheEnum((k, v) -> inst.setParameter(k, v), cast inst, "codegen");
	}
}
