package bh.test.examples;

import utest.Assert;
import bh.base.HeapsUtils.solidTile;
import bh.base.HeapsUtils.solidBitmap;

/**
 * Unit tests for solidTile / solidBitmap — lock the strict-D alpha
 * unpacking contract: top byte is alpha, top-byte=0 is treated as opaque
 * (legacy bare-0xRRGGBB compat), explicit #RRGGBBAA alpha is honored.
 *
 * Verification uses Heaps' texture cache: fromColor returns the same
 * underlying texture for equal (rgb, alpha*255) keys, so texture identity
 * between calls confirms the alpha was decoded correctly.
 */
class HeapsUtilsTest extends utest.Test {

	@Test
	public function testSolidTileDimensions():Void {
		final t = solidTile(0xFFFF0000, 64, 32);
		Assert.equals(64.0, t.width);
		Assert.equals(32.0, t.height);
	}

	@Test
	public function testTopByteZeroTreatedAsOpaque():Void {
		// Legacy compat: bare 0xRRGGBB (top byte = 0) renders opaque,
		// matching Heaps' Tile.fromColor default and the codegen's old
		// `|= 0xFF000000` bake. Same texture as the explicitly-opaque form.
		final legacy = solidTile(0x00FF0000, 4, 4);
		final opaque = solidTile(0xFFFF0000, 4, 4);
		Assert.equals(opaque.getTexture(), legacy.getTexture());
	}

	@Test
	public function testExplicitAlphaByteHonored():Void {
		// #7fdbda33 (regression from test #78): parser bakes to 0x337fdbda;
		// alpha 0x33/255 must be decoded, producing a different texture
		// than the fully-opaque form.
		final semi = solidTile(0x337fdbda, 4, 4);
		final opaque = solidTile(0xFF7fdbda, 4, 4);
		Assert.notEquals(opaque.getTexture(), semi.getTexture());
	}

	@Test
	public function testAlphaByteMatchesFloatAlpha():Void {
		// Byte 0x80 (= 128) should decode to the same texture as passing
		// alpha = 128/255 to Heaps' Tile.fromColor directly — this pins the
		// unpacking formula used inside solidTile.
		final viaHelper = solidTile(0x80FF8000, 4, 4);
		final viaHeaps = h2d.Tile.fromColor(0xFF8000, 4, 4, 128 / 255.0);
		Assert.equals(viaHeaps.getTexture(), viaHelper.getTexture());
	}

	@Test
	public function testDifferentAlphasProduceDifferentTextures():Void {
		// Distinct alpha bytes must produce distinct cached textures.
		final a25 = solidTile(0x40FF0000, 4, 4);
		final a50 = solidTile(0x80FF0000, 4, 4);
		final a75 = solidTile(0xC0FF0000, 4, 4);
		final aFull = solidTile(0xFFFF0000, 4, 4);
		Assert.notEquals(a25.getTexture(), a50.getTexture());
		Assert.notEquals(a50.getTexture(), a75.getTexture());
		Assert.notEquals(a75.getTexture(), aFull.getTexture());
	}

	@Test
	public function testSolidBitmapParentAndTile():Void {
		final parent = new h2d.Object();
		final bmp = solidBitmap(0xFF00FF00, 16, 8, parent);
		Assert.equals(parent, bmp.parent);
		Assert.equals(16.0, bmp.tile.width);
		Assert.equals(8.0, bmp.tile.height);
	}

	@Test
	public function testSolidBitmapNullParent():Void {
		final bmp = solidBitmap(0xFF0000FF, 10, 10);
		Assert.isNull(bmp.parent);
		Assert.notNull(bmp.tile);
	}
}
