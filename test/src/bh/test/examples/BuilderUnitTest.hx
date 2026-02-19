package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.BuildMode;
import bh.test.BuilderTestBase.buildFromSource;
import bh.test.BuilderTestBase.builderFromSource;
import bh.test.BuilderTestBase.getDataFromSource;
import bh.test.BuilderTestBase.findVisibleBitmapDescendants;
import bh.test.BuilderTestBase.findAllTextDescendants;
import bh.test.BuilderTestBase.countVisibleChildren;

/**
 * Non-visual builder tests.
 * Tests expression resolution, data blocks, conditionals, etc. without screenshots.
 * Uses inline .manim source strings for self-contained, fast tests.
 *
 * NOTE: Use double-quoted strings ("...") for .manim source — single-quoted strings
 * trigger Haxe string interpolation which conflicts with .manim $ references.
 */
class BuilderUnitTest extends BuilderTestBase {
	// ==================== Expression resolution: arithmetic ====================

	@Test
	public function testExprMultiply():Void {
		final result = buildFromSource("
			#test programmable(x:uint=10) {
				bitmap(generated(color($x * 3, $x * 2, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
		Assert.equals(20, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testExprAddSubtract():Void {
		final result = buildFromSource("
			#test programmable(x:uint=20) {
				bitmap(generated(color($x + 5, $x - 3, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(25, Std.int(bitmaps[0].tile.width));
		Assert.equals(17, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testExprDiv():Void {
		final result = buildFromSource("
			#test programmable(x:uint=100) {
				bitmap(generated(color($x div 4, $x div 10, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(25, Std.int(bitmaps[0].tile.width));
		Assert.equals(10, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testExprMod():Void {
		final result = buildFromSource("
			#test programmable(x:uint=17) {
				bitmap(generated(color($x % 10, $x % 3, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(7, Std.int(bitmaps[0].tile.width));
		Assert.equals(2, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testExprCombined():Void {
		// ($x * 2 + 5) = 25, ($x * 3 - 10) = 20
		final result = buildFromSource("
			#test programmable(x:uint=10) {
				bitmap(generated(color($x * 2 + 5, $x * 3 - 10, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(25, Std.int(bitmaps[0].tile.width));
		Assert.equals(20, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testExprWithParamOverride():Void {
		final params = new Map<String, Dynamic>();
		params.set("x", 15);
		final result = buildFromSource("
			#test programmable(x:uint=10) {
				bitmap(generated(color($x * 2, $x, #f00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
		Assert.equals(15, Std.int(bitmaps[0].tile.height));
	}

	// ==================== @final variable resolution ====================

	@Test
	public function testFinalSimple():Void {
		final result = buildFromSource("
			#test programmable(x:uint=10) {
				@final doubled = $x * 2
				bitmap(generated(color($doubled, $doubled, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
		Assert.equals(20, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testFinalChaining():Void {
		final result = buildFromSource("
			#test programmable(x:uint=5) {
				@final a = $x * 2
				@final b = $a + 10
				bitmap(generated(color($b, $a, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
		Assert.equals(10, Std.int(bitmaps[0].tile.height));
	}

	// ==================== Conditional evaluation ====================

	@Test
	public function testConditionalMatchOn():Void {
		final result = buildFromSource("
			#test programmable(mode:[on,off]=on) {
				@(mode=>on) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else bitmap(generated(color(20, 20, #00f))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testConditionalMatchOff():Void {
		final params = new Map<String, Dynamic>();
		params.set("mode", "off");
		final result = buildFromSource("
			#test programmable(mode:[on,off]=on) {
				@(mode=>on) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else bitmap(generated(color(20, 20, #00f))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testConditionalDefault():Void {
		final params = new Map<String, Dynamic>();
		params.set("mode", "c");
		final result = buildFromSource("
			#test programmable(mode:[a,b,c]=a) {
				@(mode=>a) bitmap(generated(color(10, 10, #f00))): 0, 0
				@(mode=>b) bitmap(generated(color(20, 20, #0f0))): 0, 0
				@default bitmap(generated(color(30, 30, #00f))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testConditionalNotEquals():Void {
		final params = new Map<String, Dynamic>();
		params.set("mode", "off");
		final result = buildFromSource("
			#test programmable(mode:[on,off]=on) {
				@(mode != off) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else bitmap(generated(color(20, 20, #00f))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testConditionalRange():Void {
		final params = new Map<String, Dynamic>();
		params.set("val", 50);
		final result = buildFromSource("
			#test programmable(val:0..100=0) {
				@(val >= 30) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else bitmap(generated(color(20, 20, #00f))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testConditionalRangeBelowThreshold():Void {
		final params = new Map<String, Dynamic>();
		params.set("val", 10);
		final result = buildFromSource("
			#test programmable(val:0..100=0) {
				@(val >= 30) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else bitmap(generated(color(20, 20, #00f))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	// ==================== Repeatable ====================

	@Test
	public function testRepeatableCount():Void {
		final result = buildFromSource("
			#test programmable(count:uint=5) {
				repeatable($i, step($count, dx: 20)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(5, bitmaps.length);
	}

	@Test
	public function testRepeatableCountOverride():Void {
		final params = new Map<String, Dynamic>();
		params.set("count", 3);
		final result = buildFromSource("
			#test programmable(count:uint=5) {
				repeatable($i, step($count, dx: 20)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(3, bitmaps.length);
	}

	@Test
	public function testRepeatableZeroCount():Void {
		final params = new Map<String, Dynamic>();
		params.set("count", 0);
		final result = buildFromSource("
			#test programmable(count:uint=5) {
				repeatable($i, step($count, dx: 20)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(0, bitmaps.length);
	}

	// ==================== Data blocks (inline source) ====================

	@Test
	public function testDataScalars():Void {
		final data:Dynamic = getDataFromSource("
			#config data {
				maxLevel: 5
				name: \"Warrior\"
				enabled: true
				speed: 3.5
			}
		", "config");
		Assert.notNull(data, "Data should be created");
		Assert.equals(5, data.maxLevel);
		Assert.equals("Warrior", data.name);
		Assert.equals(true, data.enabled);
		Assert.floatEquals(3.5, data.speed);
	}

	@Test
	public function testDataArray():Void {
		final data:Dynamic = getDataFromSource("
			#config data {
				costs: [10, 20, 40, 80]
			}
		", "config");
		final costs:Array<Dynamic> = data.costs;
		Assert.notNull(costs, "costs should not be null");
		Assert.equals(4, costs.length);
		Assert.equals(10, costs[0]);
		Assert.equals(80, costs[3]);
	}

	@Test
	public function testDataRecord():Void {
		final data:Dynamic = getDataFromSource("
			#config data {
				#tier record(name: string, cost: int, dmg: float)
				tiers: tier[] [
					{ name: \"Bronze\", cost: 10, dmg: 1.0 }
					{ name: \"Silver\", cost: 20, dmg: 1.5 }
				]
			}
		", "config");
		final tiers:Array<Dynamic> = data.tiers;
		Assert.notNull(tiers, "tiers should not be null");
		Assert.equals(2, tiers.length);
		Assert.equals("Bronze", tiers[0].name);
		Assert.equals(10, tiers[0].cost);
		Assert.equals("Silver", tiers[1].name);
	}

	@Test
	public function testDataSingleRecord():Void {
		final data:Dynamic = getDataFromSource("
			#config data {
				#tier record(name: string, cost: int)
				defaultTier: tier { name: \"None\", cost: 0 }
			}
		", "config");
		Assert.notNull(data.defaultTier, "defaultTier should not be null");
		Assert.equals("None", data.defaultTier.name);
		Assert.equals(0, data.defaultTier.cost);
	}

	@Test
	public function testDataOptionalFieldOmitted():Void {
		final data:Dynamic = getDataFromSource("
			#config data {
				#tier record(name: string, cost: int, ?dmg: float)
				value: tier { name: \"Basic\", cost: 5 }
			}
		", "config");
		Assert.equals("Basic", data.value.name);
		Assert.equals(5, data.value.cost);
		Assert.isNull(data.value.dmg, "dmg should be null when omitted");
	}

	@Test
	public function testDataOptionalFieldProvided():Void {
		final data:Dynamic = getDataFromSource("
			#config data {
				#tier record(name: string, cost: int, ?dmg: float)
				value: tier { name: \"Strong\", cost: 10, dmg: 2.5 }
			}
		", "config");
		Assert.equals("Strong", data.value.name);
		Assert.notNull(data.value.dmg, "dmg should not be null when provided");
		Assert.floatEquals(2.5, data.value.dmg);
	}

	@Test
	public function testDataBooleanValues():Void {
		final data:Dynamic = getDataFromSource("
			#config data {
				flagTrue: true
				flagFalse: false
			}
		", "config");
		Assert.equals(true, data.flagTrue);
		Assert.equals(false, data.flagFalse);
	}

	@Test
	public function testDataNegativeNumbers():Void {
		final data:Dynamic = getDataFromSource("
			#config data {
				negInt: -10
				negFloat: -3.5
			}
		", "config");
		Assert.equals(-10, data.negInt);
		Assert.floatEquals(-3.5, data.negFloat);
	}

	// ==================== Multiple programmables in one source ====================

	@Test
	public function testMultipleProgrammables():Void {
		final builder = builderFromSource("
			#first programmable() {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
			#second programmable() {
				bitmap(generated(color(20, 20, #00f))): 0, 0
			}
		");
		final r1 = builder.buildWithParameters("first", new Map());
		final r2 = builder.buildWithParameters("second", new Map());
		Assert.notNull(r1, "first should build");
		Assert.notNull(r2, "second should build");
		final b1 = findVisibleBitmapDescendants(r1.object);
		final b2 = findVisibleBitmapDescendants(r2.object);
		Assert.equals(10, Std.int(b1[0].tile.width));
		Assert.equals(20, Std.int(b2[0].tile.width));
	}

	// ==================== Bool parameter ====================

	@Test
	public function testBoolParamTrue():Void {
		final result = buildFromSource("
			#test programmable(show:bool=true) {
				@(show=>true) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else bitmap(generated(color(20, 20, #00f))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testBoolParamFalse():Void {
		final params = new Map<String, Dynamic>();
		params.set("show", "false");
		final result = buildFromSource("
			#test programmable(show:bool=true) {
				@(show=>true) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else bitmap(generated(color(20, 20, #00f))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	// ==================== String interpolation ${...} ====================

	@Test
	public function testInterpolSimpleValue():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 42);
		final result = buildFromSource("
			#test programmable(value:uint=0) {
				text(dd, '${value}', #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		Assert.equals("42", texts[0].text);
	}

	@Test
	public function testInterpolAddition():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 50);
		final result = buildFromSource("
			#test programmable(value:uint=0) {
				text(dd, '${value + 10}', #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("60", texts[0].text);
	}

	@Test
	public function testInterpolMultiplication():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 25);
		final result = buildFromSource("
			#test programmable(value:uint=0) {
				text(dd, '${value * 2}', #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("50", texts[0].text);
	}

	@Test
	public function testInterpolCombinedMultiplyAdd():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 10);
		final result = buildFromSource("
			#test programmable(value:uint=0) {
				text(dd, '${value * 3 + 5}', #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("35", texts[0].text);
	}

	@Test
	public function testInterpolDiv():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 80);
		final result = buildFromSource("
			#test programmable(value:uint=0) {
				text(dd, '${value div 10}', #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("8", texts[0].text);
	}

	@Test
	public function testInterpolMod():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 50);
		final result = buildFromSource("
			#test programmable(value:uint=0) {
				text(dd, '${value % 7}', #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("1", texts[0].text);
	}

	@Test
	public function testInterpolWithPrefix():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 42);
		final result = buildFromSource("
			#test programmable(value:uint=0) {
				text(dd, 'Value is ${value}', #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("Value is 42", texts[0].text);
	}

	@Test
	public function testInterpolArithInString():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 25);
		final result = buildFromSource("
			#test programmable(value:uint=0) {
				text(dd, 'Double: ${value * 2}', #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("Double: 50", texts[0].text);
	}

	@Test
	public function testInterpolMultiple():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 30);
		final result = buildFromSource("
			#test programmable(value:uint=0) {
				text(dd, '${value} and ${value + 10}', #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("30 and 40", texts[0].text);
	}

	@Test
	public function testInterpolComplexMultiplyAddInString():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 20);
		final result = buildFromSource("
			#test programmable(value:uint=0) {
				text(dd, 'Expression: ${value * 2 + 10}', #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("Expression: 50", texts[0].text);
	}

	@Test
	public function testInterpolMultiVariable():Void {
		final params = new Map<String, Dynamic>();
		params.set("hp", 75);
		params.set("maxHp", 100);
		final result = buildFromSource("
			#test programmable(hp:uint=0, maxHp:uint=100) {
				text(dd, '${hp}/${maxHp}', #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("75/100", texts[0].text);
	}

	@Test
	public function testInterpolMultiVarExpression():Void {
		final params = new Map<String, Dynamic>();
		params.set("hp", 75);
		params.set("maxHp", 100);
		final result = buildFromSource("
			#test programmable(hp:uint=0, maxHp:uint=100) {
				bitmap(generated(color($hp * 100 div $maxHp, 10, #f00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(75, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testInterpolWithLevelPrefix():Void {
		final params = new Map<String, Dynamic>();
		params.set("level", 5);
		final result = buildFromSource("
			#test programmable(level:uint=1) {
				text(dd, 'Lv.${level}', #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("Lv.5", texts[0].text);
	}

	// ==================== Ternary expressions ====================

	@Test
	public function testTernaryStringGe():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 60);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				text(dd, ?($value >= 50) \"HIGH\" : \"low\", #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("HIGH", texts[0].text);
	}

	@Test
	public function testTernaryStringGeFalse():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 30);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				text(dd, ?($value >= 50) \"HIGH\" : \"low\", #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("low", texts[0].text);
	}

	@Test
	public function testTernaryStringGt():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 30);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				text(dd, ?($value > 25) \"yes\" : \"no\", #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("yes", texts[0].text);
	}

	@Test
	public function testTernaryStringEq():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 50);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				text(dd, ?($value == 50) \"MATCH!\" : \"--\", #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("MATCH!", texts[0].text);
	}

	@Test
	public function testTernaryStringEqFalse():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 49);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				text(dd, ?($value == 50) \"MATCH!\" : \"--\", #fff): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("--", texts[0].text);
	}

	@Test
	public function testTernaryNumericBitmapWidth():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 60);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				bitmap(generated(color(?($value > 50) 200 : 80, 10, #f00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(200, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testTernaryNumericBitmapWidthFalse():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 40);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				bitmap(generated(color(?($value > 50) 200 : 80, 10, #f00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(80, Std.int(bitmaps[0].tile.width));
	}

	// ==================== Complex arithmetic (from playground demos) ====================

	@Test
	public function testExprSubtraction():Void {
		final params = new Map<String, Dynamic>();
		params.set("barValue", 30);
		final result = buildFromSource("
			#test programmable(barValue:0..100=50) {
				bitmap(generated(color(100 - $barValue, 10, #f00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(70, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testExprDivPlusAdd():Void {
		final params = new Map<String, Dynamic>();
		params.set("barValue", 60);
		final result = buildFromSource("
			#test programmable(barValue:0..100=50) {
				bitmap(generated(color($barValue div 2 + 10, 10, #f00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(40, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testExprMultiVarDivPercent():Void {
		final params = new Map<String, Dynamic>();
		params.set("hp", 60);
		params.set("maxHp", 200);
		final result = buildFromSource("
			#test programmable(hp:uint=0, maxHp:uint=100) {
				bitmap(generated(color($hp * 100 div $maxHp, 10, #f00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		// 60 * 100 / 200 = 30
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testExprMultiplyParam():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 8);
		final result = buildFromSource("
			#test programmable(value:uint=0) {
				bitmap(generated(color($value * 5, 10, #f00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(40, Std.int(bitmaps[0].tile.width));
	}

	// ==================== Range conditionals ====================

	@Test
	public function testConditionalRangeMatch():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 35);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				@(value => 0..25) bitmap(generated(color(10, 10, #f00))): 0, 0
				@(value => 26..50) bitmap(generated(color(20, 10, #0f0))): 0, 0
				@(value => 51..75) bitmap(generated(color(30, 10, #00f))): 0, 0
				@(value > 75) bitmap(generated(color(40, 10, #ff0))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testConditionalRangeMatchHigher():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 60);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				@(value => 0..25) bitmap(generated(color(10, 10, #f00))): 0, 0
				@(value => 26..50) bitmap(generated(color(20, 10, #0f0))): 0, 0
				@(value => 51..75) bitmap(generated(color(30, 10, #00f))): 0, 0
				@(value > 75) bitmap(generated(color(40, 10, #ff0))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testConditionalRangeMatchAbove75():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 90);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				@(value => 0..25) bitmap(generated(color(10, 10, #f00))): 0, 0
				@(value => 26..50) bitmap(generated(color(20, 10, #0f0))): 0, 0
				@(value => 51..75) bitmap(generated(color(30, 10, #00f))): 0, 0
				@(value > 75) bitmap(generated(color(40, 10, #ff0))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(40, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testConditionalRangeMatchLow():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 15);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				@(value => 0..25) bitmap(generated(color(10, 10, #f00))): 0, 0
				@(value => 26..50) bitmap(generated(color(20, 10, #0f0))): 0, 0
				@(value => 51..75) bitmap(generated(color(30, 10, #00f))): 0, 0
				@(value > 75) bitmap(generated(color(40, 10, #ff0))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testConditionalIfElseDefault():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 50);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				@if(value <= 30) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else(value <= 70) bitmap(generated(color(20, 10, #0f0))): 0, 0
				@default bitmap(generated(color(30, 10, #00f))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testConditionalIfElseDefaultFirst():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 20);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				@if(value <= 30) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else(value <= 70) bitmap(generated(color(20, 10, #0f0))): 0, 0
				@default bitmap(generated(color(30, 10, #00f))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testConditionalIfElseDefaultFallthrough():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 90);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				@if(value <= 30) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else(value <= 70) bitmap(generated(color(20, 10, #0f0))): 0, 0
				@default bitmap(generated(color(30, 10, #00f))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testConditionalLessThan():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 30);
		final result = buildFromSource("
			#test programmable(value:0..100=50) {
				@(value < 50) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else bitmap(generated(color(20, 10, #00f))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testConditionalLessEqual():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 50);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				@(value <= 50) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else bitmap(generated(color(20, 10, #00f))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testConditionalGreaterThan():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 80);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				@(value > 75) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else bitmap(generated(color(20, 10, #00f))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	// ==================== Repeatable with expression count ====================

	@Test
	public function testRepeatableExpressionCount():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 50);
		final result = buildFromSource("
			#test programmable(value:uint=30) {
				repeatable($i, step($value div 10, dx: 20)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		// 50 div 10 = 5
		Assert.equals(5, bitmaps.length);
	}

	@Test
	public function testRepeatableExpressionCountSmall():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 20);
		final result = buildFromSource("
			#test programmable(value:uint=30) {
				repeatable($i, step($value div 10, dx: 20)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		// 20 div 10 = 2
		Assert.equals(2, bitmaps.length);
	}

	// ==================== Expressions with bitmap sizing (from playground) ====================

	@Test
	public function testBitmapWidthFromExpr():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 40);
		final result = buildFromSource("
			#test programmable(value:0..100=50) {
				bitmap(generated(color($value * 3, 10, #f00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(120, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testBitmapWidthFromExprMultiplyFive():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 15);
		final result = buildFromSource("
			#test programmable(value:0..100=50) {
				bitmap(generated(color($value * 5, 10, #f00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(75, Std.int(bitmaps[0].tile.width));
	}

	// ==================== Incremental mode tests ====================

	@Test
	public function testIncrementalExprMultiply():Void {
		final result = buildFromSource("
			#test programmable(x:uint=10) {
				bitmap(generated(color($x * 3, $x * 2, #f00))): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result, "Incremental build should succeed");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
		Assert.equals(20, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testIncrementalExprCombined():Void {
		final result = buildFromSource("
			#test programmable(x:uint=10) {
				bitmap(generated(color($x * 2 + 5, $x * 3 - 10, #f00))): 0, 0
			}
		", "test", null, Incremental);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(25, Std.int(bitmaps[0].tile.width));
		Assert.equals(20, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testIncrementalInterpolation():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 42);
		final result = buildFromSource("
			#test programmable(value:uint=0) {
				text(dd, 'Value: ${value}', #fff): 0, 0
			}
		", "test", params, Incremental);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("Value: 42", texts[0].text);
	}

	@Test
	public function testIncrementalConditionalRange():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 35);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				@(value => 0..25) bitmap(generated(color(10, 10, #f00))): 0, 0
				@(value => 26..50) bitmap(generated(color(20, 10, #0f0))): 0, 0
				@(value => 51..75) bitmap(generated(color(30, 10, #00f))): 0, 0
				@(value > 75) bitmap(generated(color(40, 10, #ff0))): 0, 0
			}
		", "test", params, Incremental);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalTernary():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 60);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				text(dd, ?($value >= 50) \"HIGH\" : \"low\", #fff): 0, 0
			}
		", "test", params, Incremental);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("HIGH", texts[0].text);
	}

	@Test
	public function testIncrementalRepeatable():Void {
		final params = new Map<String, Dynamic>();
		params.set("value", 40);
		final result = buildFromSource("
			#test programmable(value:uint=30) {
				repeatable($i, step($value div 10, dx: 20)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		", "test", params, Incremental);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(4, bitmaps.length);
	}

	@Test
	public function testIncrementalMultiVariable():Void {
		final params = new Map<String, Dynamic>();
		params.set("hp", 60);
		params.set("maxHp", 200);
		final result = buildFromSource("
			#test programmable(hp:uint=0, maxHp:uint=100) {
				text(dd, '${hp}/${maxHp}', #fff): 0, 0
			}
		", "test", params, Incremental);
		final texts = findAllTextDescendants(result.object);
		Assert.equals("60/200", texts[0].text);
	}

	@Test
	public function testIncrementalFinal():Void {
		final result = buildFromSource("
			#test programmable(x:uint=5) {
				@final a = $x * 2
				@final b = $a + 10
				bitmap(generated(color($b, $a, #f00))): 0, 0
			}
		", "test", null, Incremental);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
		Assert.equals(10, Std.int(bitmaps[0].tile.height));
	}
}
