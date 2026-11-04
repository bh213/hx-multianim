package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Root-level `tint:` on a programmable targets the h2d.Layers root, which is not an
 * h2d.Drawable, so it cannot carry a color tint. The runtime builder
 * (MultiAnimBuilder.applyExtendedFormProperties) throws a BuilderError for this; codegen
 * must behave identically rather than silently dropping the tint.
 *
 * Fixture: test/examples/123-codegenRootTint/codegenRootTint.manim
 */
class CodegenRootTintTest extends BuilderTestBase {
	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	@Test
	public function testCodegenRootTintThrowsLikeBuilder():Void {
		final mp = createMp();
		var err:String = null;
		var builderErr:Null<bh.multianim.BuilderError> = null;
		try {
			mp.codegenRootTint.create();
		} catch (e:Dynamic) {
			err = Std.string(e);
			if (Std.isOfType(e, bh.multianim.BuilderError)) builderErr = cast e;
		}
		Assert.notNull(err, "Codegen root-level tint on a non-Drawable root must throw, matching the builder");
		Assert.notNull(builderErr, "codegen throw must be a BuilderError, matching the builder path");
	}
}
