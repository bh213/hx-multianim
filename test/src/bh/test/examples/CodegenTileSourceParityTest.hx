package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.ui.UIElement.TileHelper;

/**
 * Tile-source lowering parity between codegen and builder:
 *
 * - bitmap($tileParam) inside a tiles-iterator repeat: the codegen fast path
 *   assumes every TSReference is the iterator's tile variable and emits
 *   _rt_tiles[_rt_i], silently rendering the sheet tile instead of the
 *   passed-in tile parameter.
 * - generated(cross(...)): the codegen approximates the cross as a solid
 *   rectangle (and drops the thickness); the builder draws a real cross via
 *   PixelLines into a dedicated texture.
 * - generated(color(w, h, ...)) dims: the codegen truncates the whole float
 *   expression once (Std.int($n / 2 * 2) with n=7 -> 7) where the builder
 *   truncates per node (Std.int(7/2)*2 -> 6).
 *
 * Companion fixture: test/examples/147-codegenTileSource/tileSource.manim
 */
class CodegenTileSourceParityTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/147-codegenTileSource/tileSource.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function visibleBitmaps(root:h2d.Object):Array<h2d.Bitmap> {
		return BuilderTestBase.findVisibleBitmapDescendants(root);
	}

	// ==================== bitmap($tileParam) in a tiles repeat ====================

	/** Builder baseline: every iteration renders the 13px icon param. */
	@Test
	public function testTileMisbind_Builder_BindsTileParam():Void {
		final params = new Map<String, Dynamic>();
		params.set("icon", TileHelper.generatedRectColor(13, 13, 0xFF00FF));
		final result = BuilderTestBase.buildFromFile(FIXTURE, "tileMisbind", params);
		final bitmaps = visibleBitmaps(result.object);
		Assert.isTrue(bitmaps.length > 0, "builder: the tiles repeat renders at least one bitmap");
		for (b in bitmaps)
			Assert.equals(13, Std.int(b.tile.width),
				"builder: bitmap($icon) renders the 13px tile param, not the iterator tile");
	}

	/** Codegen: bitmap($icon) must bind the tile param, not the iterator tile. */
	@Test
	public function testTileMisbind_Codegen_BindsTileParam():Void {
		final icon = h2d.Tile.fromColor(0xFFFF00FF, 13, 13);
		final inst:Dynamic = createMp().tileMisbind.create(icon);
		final bitmaps = visibleBitmaps(cast inst);
		Assert.isTrue(bitmaps.length > 0, "codegen: the tiles repeat renders at least one bitmap");
		for (b in bitmaps)
			Assert.equals(13, Std.int(b.tile.width),
				"codegen: bitmap($icon) must render the 13px tile param, not mis-bind to the iterator tile");
	}

	// ==================== generated(cross(...)) ====================

	/** Builder baseline: the cross is drawn into a real 32x32 texture. */
	@Test
	public function testCrossGen_Builder_DrawsRealCross():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "crossGen", null);
		final bitmaps = visibleBitmaps(result.object);
		Assert.equals(1, bitmaps.length, "builder: one cross bitmap");
		if (bitmaps.length != 1)
			return;
		Assert.equals(32, Std.int(bitmaps[0].tile.width), "builder: cross tile is 32px wide");
		// A drawn cross needs a real 32x32 pixel surface; the solid-color
		// approximation is a shared 1x1 texture stretched to size.
		Assert.equals(32, bitmaps[0].tile.getTexture().width,
			"builder: the cross is drawn into a dedicated 32px texture");
	}

	/** Codegen: generated(cross(...)) must draw a cross, not a stretched solid. */
	@Test
	public function testCrossGen_Codegen_DrawsRealCross():Void {
		final inst:Dynamic = createMp().crossGen.create();
		final bitmaps = visibleBitmaps(cast inst);
		Assert.equals(1, bitmaps.length, "codegen: one cross bitmap");
		if (bitmaps.length != 1)
			return;
		Assert.equals(32, Std.int(bitmaps[0].tile.width), "codegen: cross tile is 32px wide");
		Assert.equals(32, bitmaps[0].tile.getTexture().width,
			"codegen: generated(cross(...)) must draw the cross into a real texture, not approximate it as a stretched 1x1 solid");
	}

	// ==================== generated dims truncation parity ====================

	/** Builder baseline: $n / 2 * 2 with n=7 truncates per node -> 6. */
	@Test
	public function testGenTrunc_Builder_PerNodeTruncation():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "genTrunc", null);
		final bitmaps = visibleBitmaps(result.object);
		Assert.equals(1, bitmaps.length, "builder: one generated bitmap");
		if (bitmaps.length == 1)
			Assert.equals(6, Std.int(bitmaps[0].tile.width),
				"builder: generated width $n / 2 * 2 with n=7 truncates per node (Std.int(7/2)*2 = 6)");
	}

	/** Codegen: generated tile dims must follow the per-node rvToExprInt rule. */
	@Test
	public function testGenTrunc_Codegen_PerNodeTruncation():Void {
		final inst:Dynamic = createMp().genTrunc.create();
		final bitmaps = visibleBitmaps(cast inst);
		Assert.equals(1, bitmaps.length, "codegen: one generated bitmap");
		if (bitmaps.length == 1)
			Assert.equals(6, Std.int(bitmaps[0].tile.width),
				"codegen: generated width $n / 2 * 2 with n=7 must truncate per node (6), not once at the end (7)");
	}
}
