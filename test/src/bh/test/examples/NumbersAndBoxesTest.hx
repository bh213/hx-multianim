package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
	Numbers as a game writes them, and a text's box that follows its parameters:

	- a float literal with an exponent (`1.0e56`, `2.5e-4`) is read wherever a number is;
	- a float in an expression where a whole number is wanted (`$r * 0.8` as a line's end, an ellipse's
	  radius) is worked out as a float and truncated once, in the builder and codegen alike (a position
	  keeps its fraction, as a position given by a float parameter does),
	  and a float alone there is still refused, saying it can be part of an expression;
	- a text's width given by a parameter follows setParameter, in the builder and codegen alike.

	Companion fixture: test/examples/180-numbersAndBoxes/numbersAndBoxes.manim
**/
class NumbersAndBoxesTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/180-numbersAndBoxes/numbersAndBoxes.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function parseError(source:String):Null<String> {
		try {
			BuilderTestBase.builderFromSource(source);
			return null;
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	static function graphicsOf(o:h2d.Object, into:Array<h2d.Graphics>):Array<h2d.Graphics> {
		if (Std.isOfType(o, h2d.Graphics))
			into.push(cast o);
		for (i in 0...o.numChildren)
			graphicsOf(o.getChildAt(i), into);
		return into;
	}

	static function firstText(o:h2d.Object):Null<h2d.Text> {
		if (Std.isOfType(o, h2d.Text))
			return cast o;
		for (i in 0...o.numChildren) {
			final t = firstText(o.getChildAt(i));
			if (t != null)
				return t;
		}
		return null;
	}

	// ==================== exponents ====================

	@Test
	public function testAnExponentIsRead():Void {
		final builder = BuilderTestBase.builderFromSource("
			#nums data {
				ignite: 1.0e56
				iron: 3e55
				small: 2.5e-4
				up: 1.5E+2
			}
		");
		final nums:Dynamic = builder.getData("nums");
		Assert.floatEquals(1.0e56, nums.ignite);
		Assert.floatEquals(3e55, nums.iron);
		Assert.floatEquals(2.5e-4, nums.small);
		Assert.floatEquals(150, nums.up);
		// a shader's argument, and a word after a number is still a word
		final result = BuilderTestBase.buildFromSource("
			#test programmable() {
				#a bitmap(generated(color(8, 8, #f00))) { filter: flash(amount: 2.5e-1) pos: 0, 0 }
			}
		", "test", null, Incremental);
		final flash:bh.base.filters.EngineShaderFilter = cast result.getNamedDrawn("a").filter;
		Assert.floatEquals(0.25, flash.values["amount"]);
	}

	// ==================== a float where a whole number is wanted ====================

	static function checkFloatInInt(root:h2d.Object, backend:String):Void {
		final g = graphicsOf(root, []);
		Assert.equals(2, g.length, '$backend: a line and an ellipse');
		if (g.length < 2) return;
		// the line placed at $r * 0.55 = 5.5 (a position keeps its fraction); the ellipse at $r * 1.5 = 15
		Assert.floatEquals(5.5, g[0].x, '$backend: a position of $$r * 0.55, at ' + g[0].x);
		Assert.floatEquals(15, g[1].y, '$backend: a position of $$r * 1.5');
		// the ellipse's radii 10 and $r * 0.8 = 8: 20 by 16
		final b = g[1].getBounds(g[1]);
		Assert.floatEquals(20, b.width, 1, '$backend: an ellipse 2 * 10 wide');
		Assert.floatEquals(16, b.height, 1, '$backend: an ellipse 2 * ($$r * 0.8) high, not 0');
		// the line from 0, 0 to $r * 0.8 = 8, -$r * 1.35 = -13.5 -> -13
		final l = g[0].getBounds(g[0]);
		Assert.floatEquals(8, l.xMax, 1, '$backend: the line ends at 8 across');
		Assert.floatEquals(-13, l.yMin, 1, '$backend: the line ends at -13 up');
	}

	@Test
	public function testAFloatInAnExpression_Builder():Void {
		checkFloatInInt(BuilderTestBase.buildFromFile(FIXTURE, "floatInInt", null).object, "builder");
	}

	@Test
	public function testAFloatInAnExpression_Codegen():Void {
		final inst:Dynamic = createMp().floatInInt.create();
		checkFloatInInt(cast inst, "codegen");
	}

	@Test
	public function testAFloatInAnExpression_FollowsTheParameter():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "floatInInt", null, Incremental);
		result.setParameter("r", 20);
		final g = graphicsOf(result.object, []);
		Assert.floatEquals(11, g[0].x, "builder: 20 * 0.55, at " + g[0].x);
		final inst:Dynamic = createMp().floatInInt.create();
		inst.setR(20);
		final cg = graphicsOf(cast inst, []);
		Assert.floatEquals(11, cg[0].x, "codegen: 20 * 0.55, at " + cg[0].x);
	}

	@Test
	public function testAFloatAloneIsStillRefused():Void {
		final error = parseError("#t programmable() { graphics(line(#fff, 1, 0, 0, 2.5, 0)): 0, 0 }");
		Assert.notNull(error, "a float alone where a whole number is wanted");
		if (error != null)
			Assert.stringContains("part of an expression", error);
		final negative = parseError("#t programmable() { graphics(line(#fff, 1, 0, 0, -2.5, 0)): 0, 0 }");
		Assert.notNull(negative, "a negative float alone where a whole number is wanted");
		if (negative != null)
			Assert.stringContains("part of an expression", negative);
		Assert.isNull(parseError("#t programmable(r:int=4) { graphics(line(#fff, 1, 0, 0, 0.5 * $r, -1.5 * $r)): 0, 0 }"),
			"a float before an operator, after a unary minus too");
	}

	// ==================== a text's width by a parameter ====================

	@Test
	public function testATextWidthFollowsSetParameter_Builder():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "textWidthParam", null, Incremental);
		final t = firstText(result.object);
		Assert.floatEquals(40, t.maxWidth);
		result.setParameter("w", 100);
		Assert.floatEquals(100, t.maxWidth, "builder: the width follows $w");
	}

	@Test
	public function testATextWidthFollowsSetParameter_Codegen():Void {
		final inst:Dynamic = createMp().textWidthParam.create();
		final t = firstText(cast inst);
		Assert.floatEquals(40, t.maxWidth);
		inst.setW(100);
		Assert.floatEquals(100, t.maxWidth, "codegen: the width follows $w");
	}

	@Test
	public function testARichTextWidthFollowsSetParameter_Builder():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "richWidthParam", null, Incremental);
		final t = firstText(result.object);
		Assert.isTrue(Std.isOfType(t, h2d.HtmlText), "builder: a rich text is an HtmlText");
		Assert.floatEquals(40, t.maxWidth);
		result.setParameter("w", 100);
		Assert.floatEquals(100, t.maxWidth, "builder: the rich text's width follows $w");
	}

	@Test
	public function testARichTextWidthFollowsSetParameter_Codegen():Void {
		final inst:Dynamic = createMp().richWidthParam.create();
		final t = firstText(cast inst);
		Assert.floatEquals(40, t.maxWidth);
		inst.setW(100);
		Assert.floatEquals(100, t.maxWidth, "codegen: the rich text's width follows $w");
	}

	// ==================== an autoFit box by parameters ====================

	/** Shrinks the box to a fallback font, then grows it back to the declared one. **/
	static function checkFitFollows(t:h2d.Text, set:(String, Int) -> Void, backend:String):Void {
		final declared = t.font.name;
		Assert.isTrue(t.textWidth <= 300, '$backend: the label fits the first box in its own font');
		set("w", 30);
		Assert.notEquals(declared, t.font.name, '$backend: a narrower box takes a smaller font');
		set("w", 300);
		Assert.equals(declared, t.font.name, '$backend: a wide box again takes the declared font back');
	}

	@Test
	public function testAnAutoFitBoxFollowsSetParameter_Builder():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "textFitParam", null, Incremental);
		checkFitFollows(firstText(result.object), (n, v) -> result.setParameter(n, v), "builder");
	}

	@Test
	public function testAnAutoFitBoxFollowsSetParameter_Codegen():Void {
		final inst:Dynamic = createMp().textFitParam.create();
		checkFitFollows(firstText(cast inst), (n, v) -> if (n == "w") inst.setW(v) else inst.setH(v), "codegen");
	}
}
