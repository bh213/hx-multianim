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

	// ==================== Grid coordinate system tests ====================

	@Test
	public function testGridPosBasic():Void {
		// grid(20, 15) with pos(2, 3) => x=40, y=45
		final result = buildFromSource("
			#test programmable(n:uint=2) {
				grid: 20, 15
				bitmap(generated(color(5, 5, #f00))): $grid.pos($n, 3)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(40, Std.int(bitmaps[0].x));
		Assert.equals(45, Std.int(bitmaps[0].y));
	}

	@Test
	public function testGridPosWithOffset():Void {
		// grid(20, 15) with pos(1, 2, 5, 3) => x=20+5=25, y=30+3=33
		final result = buildFromSource("
			#test programmable() {
				grid: 20, 15
				bitmap(generated(color(5, 5, #f00))): $grid.pos(1, 2, 5, 3)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(25, Std.int(bitmaps[0].x));
		Assert.equals(33, Std.int(bitmaps[0].y));
	}

	@Test
	public function testGridWidthHeightValues():Void {
		// grid(25, 30) => width=25, height=30, used as bitmap dimensions
		final result = buildFromSource("
			#test programmable() {
				grid: 25, 30
				bitmap(generated(color($grid.width, $grid.height, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(25, Std.int(bitmaps[0].tile.width));
		Assert.equals(30, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testGridPosXYExtraction():Void {
		// grid(20, 15), pos(3, 2).x = 60, pos(3, 2).y = 30
		// Use as bitmap dimensions to verify values
		final result = buildFromSource("
			#test programmable() {
				grid: 20, 15
				bitmap(generated(color($grid.pos(3, 2).x, $grid.pos(3, 2).y, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(60, Std.int(bitmaps[0].tile.width));
		Assert.equals(30, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testGridPosXYExtractionWithOffset():Void {
		// grid(20, 15), pos(1, 2, 7, 3).x = 20+7=27, pos(1, 2, 7, 3).y = 30+3=33
		final result = buildFromSource("
			#test programmable() {
				grid: 20, 15
				bitmap(generated(color($grid.pos(1, 2, 7, 3).x, $grid.pos(1, 2, 7, 3).y, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(27, Std.int(bitmaps[0].tile.width));
		Assert.equals(33, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testGridPosZero():Void {
		// grid(20, 15) with pos(0, 0) => x=0, y=0
		final result = buildFromSource("
			#test programmable() {
				grid: 20, 15
				bitmap(generated(color(5, 5, #f00))): $grid.pos(0, 0)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(0, Std.int(bitmaps[0].x));
		Assert.equals(0, Std.int(bitmaps[0].y));
	}

	@Test
	public function testGridWidthInExpression():Void {
		// grid(20, 15) => $grid.width * 3 = 60
		final result = buildFromSource("
			#test programmable() {
				grid: 20, 15
				bitmap(generated(color($grid.width * 3, 10, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(60, Std.int(bitmaps[0].tile.width));
	}

	// ==================== Named grid system tests ====================

	@Test
	public function testNamedGridPos():Void {
		// small: grid(10, 10), big: grid(40, 40)
		// $small.pos(1, 0) => x=10, $big.pos(1, 0) => x=40
		final result = buildFromSource("
			#test programmable() {
				grid: #small 10, 10
				grid: #big 40, 40
				bitmap(generated(color(5, 5, #f00))): $small.pos(1, 0)
				bitmap(generated(color(5, 5, #00f))): $big.pos(1, 0)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].x));
		Assert.equals(0, Std.int(bitmaps[0].y));
		Assert.equals(40, Std.int(bitmaps[1].x));
		Assert.equals(0, Std.int(bitmaps[1].y));
	}

	@Test
	public function testNamedGridWidthHeight():Void {
		// small: grid(10, 15) => width=10, height=15
		final result = buildFromSource("
			#test programmable() {
				grid: #small 10, 15
				bitmap(generated(color($small.width, $small.height, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
		Assert.equals(15, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testNamedGridPosXYExtraction():Void {
		// myGrid: grid(30, 20), pos(2, 1).x = 60, pos(2, 1).y = 20
		final result = buildFromSource("
			#test programmable() {
				grid: #myGrid 30, 20
				bitmap(generated(color($myGrid.pos(2, 1).x, $myGrid.pos(2, 1).y, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(60, Std.int(bitmaps[0].tile.width));
		Assert.equals(20, Std.int(bitmaps[0].tile.height));
	}

	// ==================== Hex coordinate system tests ====================

	@Test
	public function testHexCubeOrigin():Void {
		// hex(pointy, 16), cube(0,0,0) => should be at hex center (origin)
		final result = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $hex.cube(0, 0, 0)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		// origin hex => position 0,0
		Assert.equals(0, Std.int(bitmaps[0].x));
		Assert.equals(0, Std.int(bitmaps[0].y));
	}

	@Test
	public function testHexCubeNonOrigin():Void {
		// hex(pointy, 16), cube(1, -1, 0) should produce non-zero position
		final result = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $hex.cube(1, -1, 0)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		// Position should not be at origin
		final x = bitmaps[0].x;
		final y = bitmaps[0].y;
		Assert.isTrue(x != 0 || y != 0, "cube(1,-1,0) should not be at origin");
	}

	@Test
	public function testHexCornerXYExtraction():Void {
		// hex(pointy, 16), corner(0, 1.0) should produce non-zero values
		final result = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color($hex.corner(0, 1.0).x + 50, $hex.corner(0, 1.0).y + 50, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		// corner(0, 1.0) at pointy size 16 produces specific values
		// The +50 offset ensures positive bitmap dimensions
		final w = Std.int(bitmaps[0].tile.width);
		final h = Std.int(bitmaps[0].tile.height);
		Assert.isTrue(w > 0, "corner .x + 50 should produce positive width, got: " + w);
		Assert.isTrue(h > 0, "corner .y + 50 should produce positive height, got: " + h);
	}

	@Test
	public function testHexEdgeXYExtraction():Void {
		// hex(pointy, 16), edge(0, 0.5)
		final result = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color($hex.edge(0, 0.5).x + 50, $hex.edge(0, 0.5).y + 50, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		final w = Std.int(bitmaps[0].tile.width);
		final h = Std.int(bitmaps[0].tile.height);
		Assert.isTrue(w > 0, "edge .x + 50 should produce positive width, got: " + w);
		Assert.isTrue(h > 0, "edge .y + 50 should produce positive height, got: " + h);
	}

	@Test
	public function testHexCornerSymmetry():Void {
		// Corners 0 and 3 of a pointy hex are vertically symmetric
		// corner(0).y and corner(3).y should be negatives of each other
		final result = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color($hex.corner(0, 1.0).y + 50, $hex.corner(3, 1.0).y + 50, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		final w = Std.int(bitmaps[0].tile.width);
		final h = Std.int(bitmaps[0].tile.height);
		// corner(0).y + 50 and corner(3).y + 50 should sum to 100 (since they are negatives)
		Assert.equals(100, w + h);
	}

	@Test
	public function testHexCubeXYExtraction():Void {
		// hex(pointy, 16), cube(1, 0, -1).x and .y
		final result = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color($hex.cube(1, 0, -1).x + 50, $hex.cube(1, 0, -1).y + 50, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		final w = Std.int(bitmaps[0].tile.width);
		final h = Std.int(bitmaps[0].tile.height);
		Assert.isTrue(w > 0, "cube(1,0,-1).x + 50 should be positive, got: " + w);
		Assert.isTrue(h > 0, "cube(1,0,-1).y + 50 should be positive, got: " + h);
		// cube(1,0,-1) moves right in pointy hex, so x should be > 50
		Assert.isTrue(w > 50, "cube(1,0,-1).x should be positive, got value+50: " + w);
	}

	@Test
	public function testHexOffsetEven():Void {
		// hex(pointy, 16), offset(1, 0, even) should produce a non-origin position
		final result = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $hex.offset(1, 0, even)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		final x = bitmaps[0].x;
		Assert.isTrue(x != 0, "offset(1,0,even) should not be at x=0");
	}

	@Test
	public function testHexOffsetOdd():Void {
		// hex(pointy, 16), offset(1, 0, odd) should produce a different position than even
		final resultEven = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $hex.offset(1, 1, even)
			}
		", "test");
		final resultOdd = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $hex.offset(1, 1, odd)
			}
		", "test");
		final bitmapsEven = findVisibleBitmapDescendants(resultEven.object);
		final bitmapsOdd = findVisibleBitmapDescendants(resultOdd.object);
		// Even and odd parity for row 1 should produce different y positions
		Assert.isTrue(bitmapsEven[0].y != bitmapsOdd[0].y || bitmapsEven[0].x != bitmapsOdd[0].x,
			"Even and odd parity should produce different positions");
	}

	@Test
	public function testHexDoubled():Void {
		// hex(pointy, 16), doubled(2, 0) should produce a non-origin position
		final result = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $hex.doubled(2, 0)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.isTrue(bitmaps[0].x != 0, "doubled(2,0) should not be at x=0");
	}

	@Test
	public function testHexWidthHeightValues():Void {
		// hex(pointy, 16) => width and height should be positive non-zero
		final result = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color($hex.width, $hex.height, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		final w = Std.int(bitmaps[0].tile.width);
		final h = Std.int(bitmaps[0].tile.height);
		Assert.isTrue(w > 0, "hex.width should be positive, got: " + w);
		Assert.isTrue(h > 0, "hex.height should be positive, got: " + h);
	}

	@Test
	public function testHexFlatVsPointyOrientation():Void {
		// flat and pointy hex with same size should produce different width/height ratios
		final resultPointy = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color($hex.width, $hex.height, #f00))): 0, 0
			}
		", "test");
		final resultFlat = buildFromSource("
			#test programmable() {
				hex: flat(16, 16)
				bitmap(generated(color($hex.width, $hex.height, #f00))): 0, 0
			}
		", "test");
		final pointyBitmaps = findVisibleBitmapDescendants(resultPointy.object);
		final flatBitmaps = findVisibleBitmapDescendants(resultFlat.object);
		// Pointy: width < height. Flat: width > height (for same size)
		// Actually for pointy: w = sqrt(3)*size, h = 2*size
		// For flat: w = 2*size, h = sqrt(3)*size
		// So pointy.width should equal flat.height and vice versa
		final pw = Std.int(pointyBitmaps[0].tile.width);
		final ph = Std.int(pointyBitmaps[0].tile.height);
		final fw = Std.int(flatBitmaps[0].tile.width);
		final fh = Std.int(flatBitmaps[0].tile.height);
		Assert.equals(pw, fh);
		Assert.equals(ph, fw);
	}

	// ==================== Named hex system tests ====================

	@Test
	public function testNamedHexCube():Void {
		final result = buildFromSource("
			#test programmable() {
				hex: #myHex pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $myHex.cube(1, -1, 0)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.isTrue(bitmaps[0].x != 0 || bitmaps[0].y != 0, "named hex cube should resolve");
	}

	@Test
	public function testNamedHexCornerXY():Void {
		// Compare named system to default system — should produce same results
		final resultDefault = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color($hex.corner(0, 1.0).x + 50, $hex.corner(0, 1.0).y + 50, #f00))): 0, 0
			}
		", "test");
		final resultNamed = buildFromSource("
			#test programmable() {
				hex: #h pointy(16, 16)
				bitmap(generated(color($h.corner(0, 1.0).x + 50, $h.corner(0, 1.0).y + 50, #f00))): 0, 0
			}
		", "test");
		final defaultBitmaps = findVisibleBitmapDescendants(resultDefault.object);
		final namedBitmaps = findVisibleBitmapDescendants(resultNamed.object);
		Assert.equals(Std.int(defaultBitmaps[0].tile.width), Std.int(namedBitmaps[0].tile.width));
		Assert.equals(Std.int(defaultBitmaps[0].tile.height), Std.int(namedBitmaps[0].tile.height));
	}

	// ==================== Coordinate .x/.y in expressions ====================

	@Test
	public function testGridPosXInArithmetic():Void {
		// grid(20, 15), pos(2, 0).x = 40, 40 + 10 = 50
		final result = buildFromSource("
			#test programmable() {
				grid: 20, 15
				bitmap(generated(color($grid.pos(2, 0).x + 10, 5, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(50, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testGridPosYInArithmetic():Void {
		// grid(20, 15), pos(0, 3).y = 45, 45 - 5 = 40
		final result = buildFromSource("
			#test programmable() {
				grid: 20, 15
				bitmap(generated(color($grid.pos(0, 3).y - 5, 5, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(40, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testGridPosXYAsDimensions():Void {
		// Using .x and .y extraction as bitmap dimensions
		// grid(20, 15), pos(1, 2).x = 20, pos(1, 2).y = 30
		final result = buildFromSource("
			#test programmable() {
				grid: 20, 15
				bitmap(generated(color($grid.pos(1, 2).x, $grid.pos(1, 2).y, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
		Assert.equals(30, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testGridPosXYWithParamDep():Void {
		// grid(20, 15), pos($n, 1) with n=3 => x=60, y=15
		final params = new Map<String, Dynamic>();
		params.set("n", 3);
		final result = buildFromSource("
			#test programmable(n:uint=0) {
				grid: 20, 15
				bitmap(generated(color($grid.pos($n, 1).x, $grid.pos($n, 1).y, #f00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(60, Std.int(bitmaps[0].tile.width));
		Assert.equals(15, Std.int(bitmaps[0].tile.height));
	}

	// ==================== Multiple coordinate systems in one programmable ====================

	@Test
	public function testTwoGridSystems():Void {
		// Two different grid spacings, verifying each resolves independently
		final result = buildFromSource("
			#test programmable() {
				grid: #a 10, 10
				grid: #b 30, 30
				bitmap(generated(color(5, 5, #f00))): $a.pos(1, 1)
				bitmap(generated(color(5, 5, #00f))): $b.pos(1, 1)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].x));
		Assert.equals(10, Std.int(bitmaps[0].y));
		Assert.equals(30, Std.int(bitmaps[1].x));
		Assert.equals(30, Std.int(bitmaps[1].y));
	}

	@Test
	public function testGridAndHexMixed():Void {
		// One grid and one hex system
		final result = buildFromSource("
			#test programmable() {
				grid: #g 20, 20
				hex: #h pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $g.pos(2, 0)
				bitmap(generated(color(5, 5, #00f))): $h.cube(0, 0, 0)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);
		Assert.equals(40, Std.int(bitmaps[0].x));
		Assert.equals(0, Std.int(bitmaps[0].y));
		Assert.equals(0, Std.int(bitmaps[1].x));
		Assert.equals(0, Std.int(bitmaps[1].y));
	}

	// ==================== Hex coordinate consistency ====================

	@Test
	public function testHexCubeConsistentXY():Void {
		// .x/.y extraction from cube should match position from cube as coordinate
		final result = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $hex.cube(1, 0, -1)
				bitmap(generated(color($hex.cube(1, 0, -1).x + 50, $hex.cube(1, 0, -1).y + 50, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		// First bitmap positioned at hex(1,0,-1)
		// Second bitmap dimensions = hex(1,0,-1).x + 50, hex(1,0,-1).y + 50
		final posX = Std.int(bitmaps[0].x);
		final posY = Std.int(bitmaps[0].y);
		final dimW = Std.int(bitmaps[1].tile.width);
		final dimH = Std.int(bitmaps[1].tile.height);
		Assert.equals(posX + 50, dimW);
		Assert.equals(posY + 50, dimH);
	}

	@Test
	public function testHexOffsetXYExtraction():Void {
		// hex(pointy, 16), offset(1, 0, even) — extract and verify
		final result = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $hex.offset(1, 0, even)
				bitmap(generated(color($hex.offset(1, 0, even).x + 50, $hex.offset(1, 0, even).y + 50, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		final posX = Std.int(bitmaps[0].x);
		final posY = Std.int(bitmaps[0].y);
		final dimW = Std.int(bitmaps[1].tile.width);
		final dimH = Std.int(bitmaps[1].tile.height);
		Assert.equals(posX + 50, dimW);
		Assert.equals(posY + 50, dimH);
	}

	@Test
	public function testHexDoubledXYExtraction():Void {
		// hex(pointy, 16), doubled(2, 0) — extract and verify consistency
		final result = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $hex.doubled(2, 0)
				bitmap(generated(color($hex.doubled(2, 0).x + 50, $hex.doubled(2, 0).y + 50, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		final posX = Std.int(bitmaps[0].x);
		final posY = Std.int(bitmaps[0].y);
		final dimW = Std.int(bitmaps[1].tile.width);
		final dimH = Std.int(bitmaps[1].tile.height);
		Assert.equals(posX + 50, dimW);
		Assert.equals(posY + 50, dimH);
	}

	// ==================== Coordinate system scoping / nesting ====================

	@Test
	public function testGridInheritedThroughFlow():Void {
		// grid defined on programmable, used inside nested flow — should walk up parent chain
		final result = buildFromSource("
			#test programmable() {
				grid: 20, 15
				flow(layout:vertical) {
					bitmap(generated(color(5, 5, #f00))): $grid.pos(2, 3)
				}
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(40, Std.int(bitmaps[0].x));
		Assert.equals(45, Std.int(bitmaps[0].y));
	}

	@Test
	public function testGridShadowingInNestedFlow():Void {
		// Inner grid: on flow should shadow outer grid: on programmable
		final result = buildFromSource("
			#test programmable() {
				grid: 20, 15
				flow(layout:vertical) {
					grid: 10, 10
					bitmap(generated(color(5, 5, #f00))): $grid.pos(1, 1)
				}
				bitmap(generated(color(5, 5, #00f))): $grid.pos(1, 1)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);
		// First bitmap inside flow — uses inner grid (10,10)
		Assert.equals(10, Std.int(bitmaps[0].x));
		Assert.equals(10, Std.int(bitmaps[0].y));
		// Second bitmap outside flow — uses outer grid (20,15)
		Assert.equals(20, Std.int(bitmaps[1].x));
		Assert.equals(15, Std.int(bitmaps[1].y));
	}

	@Test
	public function testHexInheritedThroughFlow():Void {
		// hex defined on programmable, used inside nested flow
		final result = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				flow(layout:vertical) {
					bitmap(generated(color(5, 5, #f00))): $hex.cube(0, 0, 0)
				}
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(0, Std.int(bitmaps[0].x));
		Assert.equals(0, Std.int(bitmaps[0].y));
	}

	@Test
	public function testNamedGridInheritedThroughFlow():Void {
		// named grid on programmable, accessed inside nested flow
		final result = buildFromSource("
			#test programmable() {
				grid: #myGrid 25, 30
				flow(layout:vertical) {
					bitmap(generated(color(5, 5, #f00))): $myGrid.pos(2, 1)
				}
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(50, Std.int(bitmaps[0].x));
		Assert.equals(30, Std.int(bitmaps[0].y));
	}

	@Test
	public function testNamedGridWidthInheritedThroughFlow():Void {
		// named grid width/height accessible through nesting
		final result = buildFromSource("
			#test programmable() {
				grid: #myGrid 25, 30
				flow(layout:vertical) {
					bitmap(generated(color($myGrid.width, $myGrid.height, #f00))): 0, 0
				}
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(25, Std.int(bitmaps[0].tile.width));
		Assert.equals(30, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testGridInheritedThroughLayers():Void {
		// grid defined on programmable, used inside nested layers
		final result = buildFromSource("
			#test programmable() {
				grid: 20, 15
				layers() {
					bitmap(generated(color(5, 5, #f00))): $grid.pos(3, 2)
				}
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(60, Std.int(bitmaps[0].x));
		Assert.equals(30, Std.int(bitmaps[0].y));
	}

	@Test
	public function testGridDoubleNesting():Void {
		// grid inherited through two levels of nesting: programmable > flow > layers
		final result = buildFromSource("
			#test programmable() {
				grid: 20, 15
				flow(layout:vertical) {
					layers() {
						bitmap(generated(color(5, 5, #f00))): $grid.pos(1, 2)
					}
				}
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].x));
		Assert.equals(30, Std.int(bitmaps[0].y));
	}

	// ==================== AnimatedPath tests ====================

	@Test
	public function testAnimatedPathTimeMode():Void {
		final builder = builderFromSource("
			paths {
				#straight path {
					lineTo(100, 0)
				}
			}
			#test animatedPath {
				path: straight
				type: time
				duration: 2.0
			}
		");
		final ap = builder.createAnimatedPath("test");
		Assert.notNull(ap);

		// Update by half duration — rate should be ~0.5
		final state1 = ap.update(1.0);
		Assert.floatEquals(0.5, state1.rate);
		Assert.isFalse(state1.done);

		// Complete the path
		final state2 = ap.update(1.0);
		Assert.floatEquals(1.0, state2.rate);
		Assert.isTrue(state2.done);
	}

	@Test
	public function testAnimatedPathDistanceMode():Void {
		final builder = builderFromSource("
			paths {
				#straight path {
					lineTo(100, 0)
				}
			}
			#test animatedPath {
				path: straight
				type: distance
				speed: 50.0
			}
		");
		final ap = builder.createAnimatedPath("test");

		// At speed=50, 1s covers 50px → rate = 50/100 = 0.5
		final state = ap.update(1.0);
		Assert.floatEquals(0.5, state.rate);
		Assert.isFalse(state.done);
	}

	@Test
	public function testAnimatedPathDtZero():Void {
		final builder = builderFromSource("
			paths {
				#straight path {
					lineTo(100, 0)
				}
			}
			#test animatedPath {
				path: straight
				type: time
				duration: 1.0
			}
		");
		final ap = builder.createAnimatedPath("test");

		// First call with dt > 0 starts the path
		ap.update(0.5);
		final state = ap.update(0.0);
		// dt=0 should not advance rate
		Assert.floatEquals(0.5, state.rate);
		Assert.isFalse(state.done);
	}

	@Test
	public function testAnimatedPathScaleCurve():Void {
		final builder = builderFromSource("
			paths {
				#straight path { lineTo(100, 0) }
			}
			curves {
				#grow curve {
					points: [(0, 0.5), (1, 2.0)]
				}
			}
			#test animatedPath {
				path: straight
				type: time
				duration: 1.0
				0.0: scaleCurve: grow
			}
		");
		final ap = builder.createAnimatedPath("test");

		final state = ap.update(0.5);
		// At rate=0.5, curve localT=0.5, lerp(0.5, 0.5, 2.0) = 1.25
		Assert.floatEquals(1.25, state.scale);
	}

	@Test
	public function testAnimatedPathInlineEasing():Void {
		// Test inline easing without a curves{} block
		final builder = builderFromSource("
			paths {
				#straight path { lineTo(100, 0) }
			}
			#test animatedPath {
				path: straight
				type: time
				duration: 1.0
				0.0: alphaCurve: easeInQuad
			}
		");
		final ap = builder.createAnimatedPath("test");

		final state = ap.update(0.5);
		// easeInQuad(0.5) = 0.25
		Assert.floatEquals(0.25, state.alpha);
	}

	@Test
	public function testAnimatedPathEasingShorthand():Void {
		// Test easing: keyword as shorthand for progressCurve
		final builder = builderFromSource("
			paths {
				#straight path { lineTo(100, 0) }
			}
			#test animatedPath {
				path: straight
				type: time
				duration: 1.0
				easing: easeInQuad
			}
		");
		final ap = builder.createAnimatedPath("test");

		final state = ap.update(0.5);
		// timeRate=0.5, progressCurve = easeInQuad(0.5) = 0.25 = pathRate
		Assert.floatEquals(0.25, state.rate);
	}

	@Test
	public function testAnimatedPathEvents():Void {
		final builder = builderFromSource("
			paths {
				#straight path { lineTo(100, 0) }
			}
			#test animatedPath {
				path: straight
				type: time
				duration: 1.0
				0.0: event(\"start\")
				0.5: event(\"mid\")
				1.0: event(\"end\")
			}
		");
		final ap = builder.createAnimatedPath("test");

		var events:Array<String> = [];
		ap.onEvent = function(name:String, state:bh.paths.AnimatedPath.AnimatedPathState) {
			events.push(name);
		};

		ap.update(0.6);
		// Should fire: pathStart, start, mid
		Assert.isTrue(events.indexOf("pathStart") >= 0);
		Assert.isTrue(events.indexOf("start") >= 0);
		Assert.isTrue(events.indexOf("mid") >= 0);
		Assert.isTrue(events.indexOf("end") < 0);
	}

	@Test
	public function testAnimatedPathLoop():Void {
		final builder = builderFromSource("
			paths {
				#straight path { lineTo(100, 0) }
			}
			#test animatedPath {
				path: straight
				type: time
				duration: 1.0
				loop: true
			}
		");
		final ap = builder.createAnimatedPath("test");

		ap.update(1.5);
		final state = ap.getState();
		Assert.equals(1, state.cycle);
		Assert.floatEquals(0.5, state.rate);
		Assert.isFalse(state.done);
	}

	@Test
	public function testAnimatedPathPingPong():Void {
		final builder = builderFromSource("
			paths {
				#straight path { lineTo(100, 0) }
			}
			#test animatedPath {
				path: straight
				type: time
				duration: 1.0
				loop: true
				pingPong: true
			}
		");
		final ap = builder.createAnimatedPath("test");

		ap.update(1.5);
		final state = ap.getState();
		// After first cycle (0→1), reversed, now 0.5s into reversed cycle → rate = 1.0 - 0.5 = 0.5
		Assert.floatEquals(0.5, state.rate);
		Assert.equals(1, state.cycle);
	}

	@Test
	public function testAnimatedPathSeek():Void {
		final builder = builderFromSource("
			paths {
				#straight path { lineTo(100, 0) }
			}
			#test animatedPath {
				path: straight
				type: time
				duration: 1.0
				0.5: event(\"mid\")
			}
		");
		final ap = builder.createAnimatedPath("test");

		var eventFired = false;
		ap.onEvent = function(name:String, state:bh.paths.AnimatedPath.AnimatedPathState) {
			eventFired = true;
		};

		// Seek should not fire events or advance internal time
		final state = ap.seek(0.7);
		Assert.floatEquals(0.7, state.rate);
		Assert.isFalse(eventFired);
	}

	@Test
	public function testAnimatedPathCheckpoints():Void {
		final builder = builderFromSource("
			paths {
				#path1 path {
					lineTo(50, 0)
					checkpoint(mid)
					lineTo(100, 0)
				}
			}
			#test animatedPath {
				path: path1
				type: time
				duration: 1.0
				mid: event(\"atCheckpoint\")
			}
		");
		final ap = builder.createAnimatedPath("test");

		var events:Array<String> = [];
		ap.onEvent = function(name:String, state:bh.paths.AnimatedPath.AnimatedPathState) {
			events.push(name);
		};

		ap.update(1.0);
		Assert.isTrue(events.indexOf("atCheckpoint") >= 0);
	}

	@Test
	public function testAnimatedPathCustomCurve():Void {
		final builder = builderFromSource("
			paths {
				#straight path { lineTo(100, 0) }
			}
			curves {
				#intensity curve {
					points: [(0, 0), (1, 10)]
				}
			}
			#test animatedPath {
				path: straight
				type: time
				duration: 1.0
				0.0: custom(\"intensity\"): intensity
			}
		");
		final ap = builder.createAnimatedPath("test");

		final state = ap.update(0.3);
		// At rate=0.3, curve localT=0.3, lerp(0.3, 0, 10) = 3.0
		Assert.floatEquals(3.0, state.custom.get("intensity"));
	}

	@Test
	public function testAnimatedPathMultiColorStops():Void {
		final builder = builderFromSource("
			paths {
				#straight path { lineTo(100, 0) }
			}
			curves {
				#fade curve { easing: linear }
			}
			#test animatedPath {
				path: straight
				type: time
				duration: 1.0
				0.0: colorCurve: fade, #FF0000, #00FF00
				0.5: colorCurve: fade, #00FF00, #0000FF
			}
		");
		final ap = builder.createAnimatedPath("test");

		// At t=0.0: start of first segment → color should be #FF0000
		final state0 = ap.seek(0.0);
		Assert.equals(0xFF0000, state0.color);

		// At t=0.5: start of second segment → color should be #00FF00
		final state1 = ap.seek(0.5);
		Assert.equals(0x00FF00, state1.color);

		// At t=1.0: end of second segment → color should be #0000FF
		final state2 = ap.seek(1.0);
		Assert.equals(0x0000FF, state2.color);
	}

	@Test
	public function testProjectilePathHelper():Void {
		final builder = builderFromSource("
			paths {
				#straight path { lineTo(100, 0) }
			}
			#test animatedPath {
				path: straight
				type: time
				duration: 1.0
			}
		");
		final from = new bh.base.FPoint(10, 20);
		final to = new bh.base.FPoint(210, 20);
		final ap = builder.createProjectilePath("test", from, to);

		Assert.notNull(ap);
		// Seek to start — position should be near 'from'
		final state0 = ap.seek(0.0);
		Assert.floatEquals(10, state0.position.x);
		Assert.floatEquals(20, state0.position.y);

		// Seek to end — position should be near 'to'
		final state1 = ap.seek(1.0);
		Assert.floatEquals(210, state1.position.x);
		Assert.floatEquals(20, state1.position.y);
	}

	@Test
	public function testPathGetClosestRate():Void {
		final builder = builderFromSource("
			paths {
				#straight path { lineTo(100, 0) }
			}
			#test animatedPath {
				path: straight
				type: time
				duration: 1.0
			}
		");
		final paths = builder.getPaths();
		final path = paths.getPath("straight");

		// Point near midpoint of line (0,0)→(100,0)
		final rate = path.getClosestRate(new bh.base.FPoint(50, 5));
		Assert.floatEquals(0.5, rate);

		// Point near start
		final rate2 = path.getClosestRate(new bh.base.FPoint(10, 10));
		Assert.floatEquals(0.1, rate2);

		// Point near end
		final rate3 = path.getClosestRate(new bh.base.FPoint(95, 0));
		Assert.floatEquals(0.95, rate3);
	}
}
