package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.BuildMode;
import bh.test.BuilderTestBase.buildFromFile;

/**
 * `RVColorXY(externalReference, name, x, y)` and `RVColor(externalReference, name, index)`
 * are produced by the parser when a `.manim` file references an imported palette via
 * `palette(external(extRef), name, x, y)`. The runtime builder honors `externalReference`
 * — `MultiAnimBuilder.resolveAsColorInteger` switches to the imported builder via
 * `getBuilderWithExternal(externalReference)` before resolving.
 *
 * Codegen ignores `externalReference` and emits `_pb.getPaletteColor2D(name, ...)`,
 * which always resolves against the LOCAL builder. When the local builder has no palette
 * by that name (the only definition is in the imported file), the call throws
 * "could not get palette node".
 *
 * Companion fixtures:
 * - test/examples/115-codegenExternalPalette/codegenExternalPalette.manim
 * - test/examples/115-codegenExternalPalette/extPalette.manim
 */
class CodegenExternalPaletteTest extends BuilderTestBase {
	static inline var MANIM_PATH = "test/examples/115-codegenExternalPalette/codegenExternalPalette.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	// Sanity: runtime path resolves the imported palette correctly.
	@Test
	public function testRuntimeBuildExternalPalette():Void {
		final result = buildFromFile(MANIM_PATH, "codegenExternalPalette");
		Assert.notNull(result);
		Assert.notNull(result.object);
		Assert.isTrue(result.object.numChildren > 0,
			"runtime build with `palette(external(ext), tones, 0)` should succeed");
	}

	// Bug repro: codegen drops `externalReference` from `RVColorXY` / `RVColor` and resolves
	// the palette name against the local builder, which has no `#tones` palette declared.
	@Test
	public function testCodegenBuildExternalPalette():Void {
		final mp = createMp();
		var thrown:Null<String> = null;
		try {
			final inst:Dynamic = mp.codegenExternalPalette.create();
			Assert.notNull(inst);
			Assert.isTrue((inst : h2d.Object).numChildren > 0,
				"codegen build should produce a non-empty subtree");
		} catch (e:Dynamic) {
			thrown = Std.string(e);
		}
		Assert.isNull(thrown,
			'codegen must thread externalReference through palette() refs (matches runtime); threw: $thrown');
	}
}
