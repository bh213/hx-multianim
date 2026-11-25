package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.multianim.BuilderError;

/**
 * $ctx.width / $ctx.height resolution parity between builder and codegen.
 *
 * The builder resolves $ctx.width from BuilderParameters.scene and throws a
 * structured BuilderError when no scene is provided (resolveRVPropertyAccess).
 * Codegen emits `this.getScene().width`, which is null while the generated
 * constructor runs (the instance has not been attached to a scene yet), so
 * create() dies with a raw null-access crash instead of failing structurally
 * (or resolving through an injectable scene).
 *
 * Companion fixture:
 * test/examples/138-codegenCtxSize/ctxSize.manim
 */
class CodegenCtxSizeTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/138-codegenCtxSize/ctxSize.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	/** Builder baseline: without a scene in BuilderParameters, $ctx.width fails with
	 *  a structured BuilderError, not a crash. */
	@Test
	public function testCtxWidth_Builder_NoScene_ThrowsBuilderError():Void {
		var caught:Null<String> = null;
		try {
			BuilderTestBase.buildFromFile(FIXTURE, "ctxSize", null);
		} catch (e:BuilderError) {
			caught = "builderError";
		} catch (e:Dynamic) {
			caught = "other: " + Std.string(e);
		}
		Assert.equals("builderError", caught,
			'builder: $$ctx.width without a scene must throw BuilderError, got: $caught');
	}

	/** Codegen: create() without a scene must fail the same structured way as the
	 *  builder. Currently the generated constructor evaluates
	 *  this.getScene().width while detached and crashes with a null access. */
	@Test
	public function testCtxWidth_Codegen_NoScene_ThrowsBuilderErrorNotNullAccess():Void {
		var caught:Null<String> = null;
		try {
			final inst:Dynamic = createMp().ctxSize.create();
			caught = "no error (built, " + BuilderTestBase.findVisibleBitmapDescendants(cast inst).length + " bitmaps)";
		} catch (e:BuilderError) {
			caught = "builderError";
		} catch (e:Dynamic) {
			caught = "other: " + Std.string(e);
		}
		Assert.equals("builderError", caught,
			'codegen: $$ctx.width without a scene must throw a structured BuilderError like the builder, got: $caught');
	}
}
