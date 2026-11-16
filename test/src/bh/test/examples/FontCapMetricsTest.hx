package bh.test.examples;

import utest.Assert;
import bh.base.FontManager;
import bh.test.BuilderTestBase;

/**
 * $ctx.font("name").capTop / .capHeight: the capitals' glyph box ('H': its BMFont yoffset and
 * height), with capTop 0 and capHeight = baseLine for a font without 'H'. The builder and the
 * codegen both read them through FontManager.capTop / capHeight and must give the same numbers.
 *
 * Companion fixture:
 * test/examples/179-fontCapMetrics/fontCapMetrics.manim
 */
class FontCapMetricsTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/179-fontCapMetrics/fontCapMetrics.manim";
	static inline var NO_CAPS = "nocaps-test";

	/** For each font: capTop, capHeight, and the y that centres the capitals in a 20 px box. */
	static final CASES:Array<{font:String, capTop:Int, capHeight:Int, centred:Int}> = [
		// o4b03: lineHeight 8, base 6, 'H' yoffset 1 height 5
		{font: "o4b03", capTop: 1, capHeight: 5, centred: 6},
		// m6x11: 'H' yoffset -1 height 13
		{font: "m6x11", capTop: -1, capHeight: 13, centred: 4},
		// m3x6 is registered with offsetY -5: 'H' yoffset 5 - 5 = 0, height 6
		{font: "m3x6", capTop: 0, capHeight: 6, centred: 7},
		// o4b03 without its 'H': capTop 0, capHeight = baseLine 6
		{font: NO_CAPS, capTop: 0, capHeight: 6, centred: 7},
	];

	function setup():Void {
		final font = FontManager.getFontByName("o4b03").clone();
		@:privateAccess font.glyphs.remove("H".code);
		FontManager.registerFont(NO_CAPS, font);
	}

	function teardown():Void {
		FontManager.unregisterFont(NO_CAPS);
	}

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	/** Where the generated bitmap `width` px wide sits under `root`, as "x,y". */
	static function posOf(root:h2d.Object, width:Int):String {
		for (b in BuilderTestBase.findVisibleBitmapDescendants(root)) {
			if (Std.int(b.tile.width) != width) continue;
			var x = 0.0, y = 0.0;
			var o:h2d.Object = b;
			while (o != null && o != root) {
				x += o.x;
				y += o.y;
				o = o.parent;
			}
			return x + "," + y;
		}
		return "none";
	}

	static function check(root:h2d.Object, c:{font:String, capTop:Int, capHeight:Int, centred:Int}, label:String):Void {
		Assert.equals(c.capTop + "," + c.capHeight, posOf(root, 2), label + " " + c.font + ": (capTop, capHeight)");
		Assert.equals("0," + c.centred, posOf(root, 3), label + " " + c.font + ": the capitals centred in a 20 px box");
	}

	@Test
	public function testFontManagerValues():Void {
		for (c in CASES) {
			final font = FontManager.getFontByName(c.font);
			Assert.equals(c.capTop, Std.int(FontManager.capTop(font)), c.font + ": capTop");
			Assert.equals(c.capHeight, Std.int(FontManager.capHeight(font)), c.font + ": capHeight");
		}
	}

	@Test
	public function testBuilder():Void {
		for (c in CASES) {
			final result = BuilderTestBase.buildFromFile(FIXTURE, "fontCaps", ["font" => c.font]);
			check(result.object, c, "builder");
		}
	}

	@Test
	public function testCodegen():Void {
		for (c in CASES) {
			final inst:Dynamic = createMp().fontCaps.create(c.font);
			check(cast inst, c, "codegen");
		}
	}

	/** A change of the font param moves both markers, in both backends. */
	@Test
	public function testFontParamChange():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "fontCaps", null, Incremental);
		final inst:Dynamic = createMp().fontCaps.create();
		check(result.object, CASES[0], "builder default");
		check(cast inst, CASES[0], "codegen default");
		for (c in CASES) {
			result.setParameter("font", c.font);
			inst.setParameter("font", c.font);
			check(result.object, c, "builder after setParameter");
			check(cast inst, c, "codegen after setParameter");
		}
	}
}
