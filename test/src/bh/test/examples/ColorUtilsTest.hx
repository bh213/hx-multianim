package bh.test.examples;

import utest.Assert;
import bh.base.ColorUtils;

class ColorUtilsTest extends utest.Test {

	@Test
	public function testRgbBakesOpaque():Void {
		Assert.equals(0xFF55AA88, ColorUtils.rgb(0x55AA88));
		Assert.equals(0xFFFF0000, ColorUtils.rgb(0xFF0000));
		Assert.equals(0xFF000000, ColorUtils.rgb(0x000000));
	}

	@Test
	public function testRgbDiscardsInputAlpha():Void {
		Assert.equals(0xFF55AA88, ColorUtils.rgb(0x3355AA88));
		Assert.equals(0xFF000000, ColorUtils.rgb(0xAA000000));
	}

	@Test
	public function testRgbaFullAlpha():Void {
		Assert.equals(0xFF55AA88, ColorUtils.rgba(0x55AA88, 1.0));
	}

	@Test
	public function testRgbaZeroAlpha():Void {
		Assert.equals(0x0055AA88, ColorUtils.rgba(0x55AA88, 0.0));
	}

	@Test
	public function testRgbaHalfAlpha():Void {
		Assert.equals(0x8055AA88, ColorUtils.rgba(0x55AA88, 0.5));
	}

	@Test
	public function testRgbaClampsBelowZero():Void {
		Assert.equals(0x0055AA88, ColorUtils.rgba(0x55AA88, -0.5));
	}

	@Test
	public function testRgbaClampsAboveOne():Void {
		Assert.equals(0xFF55AA88, ColorUtils.rgba(0x55AA88, 1.5));
	}

	@Test
	public function testWithAlphaReplaces():Void {
		Assert.equals(0x8055AA88, ColorUtils.withAlpha(0xFF55AA88, 0.5));
		Assert.equals(0x0055AA88, ColorUtils.withAlpha(0xFF55AA88, 0.0));
		Assert.equals(0xFF55AA88, ColorUtils.withAlpha(0x0055AA88, 1.0));
	}

	@Test
	public function testGetAlpha():Void {
		Assert.equals(1.0, ColorUtils.getAlpha(0xFF55AA88));
		Assert.equals(0.0, ColorUtils.getAlpha(0x0055AA88));
		Assert.isTrue(Math.abs(ColorUtils.getAlpha(0x8055AA88) - 128 / 255) < 0.001);
	}

	@Test
	public function testGetRgb():Void {
		Assert.equals(0x55AA88, ColorUtils.getRgb(0xFF55AA88));
		Assert.equals(0x55AA88, ColorUtils.getRgb(0x0055AA88));
		Assert.equals(0x000000, ColorUtils.getRgb(0xFF000000));
	}
}
