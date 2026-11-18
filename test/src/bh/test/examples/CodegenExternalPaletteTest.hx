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
	/** The colour drawn at (x, y) of an object, drawn alone into a picture (filters too). **/
	static function pixelAt(o:h2d.Object, x:Int, y:Int):Int {
		final scene = new h2d.Scene();
		scene.addChild(o);
		scene.syncOnly(0);
		final texture = new h3d.mat.Texture(32, 16, [Target]);
		texture.clear(0, 0);
		o.drawTo(texture);
		final pixels = texture.capturePixels();
		texture.dispose();
		o.remove();
		scene.dispose();
		pixels.convert(BGRA);
		return pixels.getPixel(x, y);
	}

	// Request 26: replacePalette(external(ext), teams, 0, 1) and a shader's `palette: external(ext), tones`
	// find the palette in the imported file: the red square recoloured to the other team's blue, the
	// reddish one held to the import's tones (magenta), from the builder and from codegen alike
	@Test
	public function testAPaletteOfAnImportRecoloursAndHolds():Void {
		final built = buildFromFile(MANIM_PATH, "externalSwap");
		Assert.equals(0xFF0000FF, pixelAt(built.object, 4, 4), "replacePalette: row 0's red to row 1's blue");
		Assert.equals(0xFFFF00FF, pixelAt(built.object, 14, 4), "paletteLock: the nearest of the import's tones");
		final made:h2d.Object = createMp().externalSwap.create();
		Assert.equals(0xFF0000FF, pixelAt(made, 4, 4), "codegen: the same");
		Assert.equals(0xFFFF00FF, pixelAt(made, 14, 4));
	}

	@Test
	public function testAPaletteOfAFileNotImportedIsAParseError():Void {
		for (filter in ["replacePalette(external(nope), teams, 0, 1)", "paletteLock(palette: external(nope), tones)"]) {
			final message = bh.test.BuilderTestBase.parseExpectingError('
				#p programmable() { bitmap(generated(color(8, 8, #FF0000))) { filter: $filter pos: 0, 0 } }
			');
			Assert.notNull(message, filter);
			if (message != null)
				Assert.stringContains('the file imports no "nope"', message, filter);
		}
	}
}
