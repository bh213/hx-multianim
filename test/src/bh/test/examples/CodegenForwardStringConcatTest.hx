package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * dynamicRef forwarded params must be resolved by the TARGET param's declared
 * type: forwarding `label => $a + $b` (a=1, b=2) into a string param
 * concatenates in the builder ("12"), while the codegen lowers the value by
 * source expression shape — a numeric add (3) that then stringifies to "3".
 *
 * Companion fixture: test/examples/151-codegenForwardConcat/forwardConcat.manim
 */
class CodegenForwardStringConcatTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/151-codegenForwardConcat/forwardConcat.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function firstTextContent(root:h2d.Object, backend:String):Null<String> {
		final t = findFirstText(root);
		Assert.notNull(t, '$backend: expected the forwarded-label text element');
		return t != null ? t.text : null;
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

	/** Builder baseline: string target param -> string concatenation. */
	@Test
	public function testForwardConcat_Builder_ConcatenatesForStringTarget():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "concatHost", null);
		Assert.equals("12", firstTextContent(result.object, "builder"),
			"builder: label => $a + $b with a=1, b=2 into a string param concatenates to \"12\"");
	}

	/** Codegen: same contract — resolve by target param type. */
	@Test
	public function testForwardConcat_Codegen_ConcatenatesForStringTarget():Void {
		final inst:Dynamic = createMp().concatHost.create();
		Assert.equals("12", firstTextContent(cast inst, "codegen"),
			"codegen: label => $a + $b into a string param must concatenate to \"12\", not numerically add to \"3\"");
	}
}
