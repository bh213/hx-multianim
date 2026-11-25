package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.buildFromSource;

/**
 * What a filter does with what it is put on, drawn into a picture: a glow round filled shapes, a
 * mask inside a filtered layer.
 */
class FilterContentTest extends BuilderTestBase {
	/** An object drawn alone into a `w` by `h` picture cleared to transparent (filters too), as 0xAARRGGBB. **/
	static function drawn(o:h2d.Object, w:Int, h:Int):hxd.Pixels {
		final scene = new h2d.Scene();
		scene.addChild(o);
		scene.syncOnly(0);
		final texture = new h3d.mat.Texture(w, h, [Target]);
		texture.clear(0, 0);
		o.drawTo(texture);
		final pixels = texture.capturePixels();
		texture.dispose();
		o.remove();
		scene.dispose();
		pixels.convert(BGRA);
		return pixels;
	}

	static inline function alphaOf(c:Int):Int
		return (c >>> 24) & 0xFF;

	// glow() on filled vector shapes lights round their outline: far from the shape, still inside
	// the filter's bounds, nothing is drawn
	@Test
	public function testGlowOnFilledShapesFollowsTheirOutline():Void {
		final built = buildFromSource('
			#g programmable() {
				layers() {
					filter: glow(#FFF4D6, 0.6, 4, 1, 1)
					graphics(ellipse(#D9579B, filled, 6, 5)): 0, 0
					graphics(polygon(#6B1E3A, filled, 4, 0, 0, -3, -4, 0, 0, 3)): 0, 0
				}
			}
		', "g");
		built.object.setPosition(20, 20);
		final pixels = drawn(built.object, 40, 40);
		Assert.equals(0xFFD9579B, pixels.getPixel(17, 23), "the body as drawn");
		Assert.isTrue(alphaOf(pixels.getPixel(27, 20)) > 0, "the glow just past the rim");
		// the corners of the filter's bounds: the ellipse is 6 by 5, the glow 4 out, the bounds 8 out
		for (p in [[7, 8], [32, 8], [7, 31], [32, 31]])
			Assert.equals(0, alphaOf(pixels.getPixel(p[0], p[1])), "no glow at " + p[0] + ", " + p[1] + " (" + StringTools.hex(pixels.getPixel(p[0], p[1]), 8) + ")");
	}

	// The same glow inside a layer with shader filters round it (a creature's flash and shimmer), at
	// scale 5, and in a group with a pulse
	@Test
	public function testGlowOnFilledShapesFollowsTheirOutlineNestedAndGrouped():Void {
		for (filter in ["glow(#FFF4D6, 0.6, 4, 1, 1)", "group(glow(#FFF4D6, 0.6, 4, 1, 1), pulse(color: #FFF4D6, amount: 0.35, speed: 0.5))"]) {
			final built = buildFromSource('
				#g programmable() {
					point {
						scale: 5
						layers() {
							filter: group(flash(color: #FFF4D6, amount: 0), shimmer(color: #FFF4D6, strength: 0, width: 0.3, every: 1.2))
							layers() {
								filter: $filter
								graphics(ellipse(#D9579B, filled, 6, 5)): 0, 0
							}
						}
					}
				}
			', "g");
			built.object.setPosition(100, 100);
			final pixels = drawn(built.object, 200, 200);
			Assert.equals(0xFFD9579B, pixels.getPixel(100, 100), filter + ": the body as drawn");
			for (p in [[45, 50], [155, 50], [45, 150], [155, 150]])
				Assert.isTrue(alphaOf(pixels.getPixel(p[0], p[1])) < 0x40, filter + ": no box at " + p[0] + ", " + p[1] + " (" + StringTools.hex(pixels.getPixel(p[0], p[1]), 8) + ")");
		}
	}

	// A mask inside a filtered layer clips where it is drawn, the layer's content reaching left of it
	@Test
	public function testAMaskInsideAFilterClipsWhereItIsDrawn():Void {
		final built = buildFromSource('
			#m programmable() {
				layers() {
					filter: brightness(1)
					bitmap(generated(color(4, 4, #0000FF))): -30, 0
					mask(20, 10) {
						pos: 10, 0
						bitmap(generated(color(40, 40, #FF0000))): 0, 0
					}
				}
			}
		', "m");
		built.object.setPosition(40, 10);
		final pixels = drawn(built.object, 100, 40);
		Assert.equals(0xFF0000FF, pixels.getPixel(11, 11), "the blue square left of the mask");
		Assert.equals(0xFFFF0000, pixels.getPixel(55, 15), "inside the mask: red");
		Assert.equals(0, alphaOf(pixels.getPixel(75, 15)), "right of the mask: clipped");
		Assert.equals(0, alphaOf(pixels.getPixel(55, 25)), "below the mask: clipped");
	}

	// The same through a scene zoomed by 1.5 (a page zoom that is not whole), drawn as the screen is
	@Test
	public function testAMaskInsideAFilterClipsWhereItIsDrawnInAZoomedScene():Void {
		final built = buildFromSource('
			#m programmable() {
				layers() {
					filter: brightness(1)
					mask(20, 10) {
						pos: 10, 0
						bitmap(generated(color(40, 40, #FF0000))): 0, 0
					}
				}
			}
		', "m");
		final engine = h3d.Engine.getCurrent();
		final scene = new h2d.Scene();
		scene.scaleMode = Zoom(1.5);
		built.object.setPosition(20, 20);
		scene.addChild(built.object);
		scene.syncOnly(0);
		final texture = new h3d.mat.Texture(engine.width, engine.height, [Target]);
		engine.pushTarget(texture);
		engine.clear(0, 1);
		scene.render(engine);
		engine.popTarget();
		final pixels = texture.capturePixels();
		texture.dispose();
		scene.dispose();
		pixels.convert(BGRA);
		// at 1.5: the mask from 30 to 50 by 20 to 30 is 45 to 75 by 30 to 45 on screen
		Assert.equals(0xFFFF0000, pixels.getPixel(48, 33), "inside the mask, near its left");
		Assert.equals(0xFFFF0000, pixels.getPixel(72, 42), "inside the mask, near its bottom right");
		Assert.equals(0, alphaOf(pixels.getPixel(80, 33)), "right of the mask: clipped");
		Assert.equals(0, alphaOf(pixels.getPixel(48, 50)), "below the mask: clipped");
	}
}
