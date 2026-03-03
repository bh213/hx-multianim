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
import bh.multianim.MultiAnimParser.SettingValue;

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
	public function testConditionalRangeBoundaryLower():Void {
		// Test exact lower boundary: value=0 should match @(value => 0..25)
		final params = new Map<String, Dynamic>();
		params.set("value", 0);
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
	public function testConditionalRangeBoundaryUpper():Void {
		// Test exact upper boundary: value=25 should match @(value => 0..25)
		final params = new Map<String, Dynamic>();
		params.set("value", 25);
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
	public function testConditionalRangeBoundaryTransition():Void {
		// Test boundary transition: value=26 should match @(value => 26..50), not 0..25
		final params = new Map<String, Dynamic>();
		params.set("value", 26);
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
	public function testConditionalRangeBoundaryExact50():Void {
		// Test exact boundary: value=50 should match @(value => 26..50)
		final params = new Map<String, Dynamic>();
		params.set("value", 50);
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
	public function testConditionalRangeBoundaryExact51():Void {
		// Test transition: value=51 should match @(value => 51..75)
		final params = new Map<String, Dynamic>();
		params.set("value", 51);
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
	public function testConditionalRangeBoundaryExact75():Void {
		// Test upper boundary: value=75 should match @(value => 51..75)
		final params = new Map<String, Dynamic>();
		params.set("value", 75);
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
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
		Assert.equals(20, Std.int(bitmaps[0].tile.height));

		// Verify setParameter updates the generated bitmap
		result.setParameter("x", 20);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(60, Std.int(bitmaps[0].tile.width));
		Assert.equals(40, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testIncrementalExprCombined():Void {
		final result = buildFromSource("
			#test programmable(x:uint=10) {
				bitmap(generated(color($x * 2 + 5, $x * 3 - 10, #f00))): 0, 0
			}
		", "test", null, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(25, Std.int(bitmaps[0].tile.width));
		Assert.equals(20, Std.int(bitmaps[0].tile.height));

		// x=20: width=20*2+5=45, height=20*3-10=50
		result.setParameter("x", 20);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(45, Std.int(bitmaps[0].tile.width));
		Assert.equals(50, Std.int(bitmaps[0].tile.height));
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
		var texts = findAllTextDescendants(result.object);
		Assert.equals("Value: 42", texts[0].text);

		// Verify setParameter updates interpolated text
		result.setParameter("value", 99);
		texts = findAllTextDescendants(result.object);
		Assert.equals("Value: 99", texts[0].text);
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
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Switch to different range: value=60 → 51..75 branch (30px wide)
		result.setParameter("value", 60);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
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
		var texts = findAllTextDescendants(result.object);
		Assert.equals("HIGH", texts[0].text);

		// Switch to false branch: value=30 < 50
		result.setParameter("value", 30);
		texts = findAllTextDescendants(result.object);
		Assert.equals("low", texts[0].text);
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
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(4, bitmaps.length);

		// Change to value=20 → 20 div 10 = 2 items
		result.setParameter("value", 20);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);
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
		var texts = findAllTextDescendants(result.object);
		Assert.equals("60/200", texts[0].text);

		// Update one parameter
		result.setParameter("hp", 80);
		texts = findAllTextDescendants(result.object);
		Assert.equals("80/200", texts[0].text);

		// Batch update both
		result.beginUpdate();
		result.setParameter("hp", 150);
		result.setParameter("maxHp", 300);
		result.endUpdate();
		texts = findAllTextDescendants(result.object);
		Assert.equals("150/300", texts[0].text);
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
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
		Assert.equals(10, Std.int(bitmaps[0].tile.height));

		// @final constants are immutable — they are computed once at build time
		// setParameter("x") should not change @final-derived values
		result.setParameter("x", 10);
		bitmaps = findVisibleBitmapDescendants(result.object);
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
		// cube(1,-1,0) pointy(16,16): x = (√3*1 + √3/2*(-1))*16 = √3/2*16 ≈ 13.856, y = (3/2*(-1))*16 = -24
		Assert.floatEquals(13.856, bitmaps[0].x, 0.01);
		Assert.floatEquals(-24.0, bitmaps[0].y, 0.01);
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
		// corner(0, 1.0) pointy(16,16): x = 16*cos(π/6) ≈ 13.856, y = 16*sin(π/6) ≈ 8.0
		// +50 offset: w = Std.int(63.856) = 63, h = Std.int(~57.999) = 57 (IEEE 754 sin(π/6) < 0.5)
		final w = Std.int(bitmaps[0].tile.width);
		final h = Std.int(bitmaps[0].tile.height);
		Assert.equals(63, w);
		Assert.equals(57, h);
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
		// edge(0, 0.5): midpoint of corners 0,1 scaled by 0.5 → x ≈ 6.928, y = 0.0
		// +50: w = Std.int(56.928) = 56, h = Std.int(50.0) = 50
		final w = Std.int(bitmaps[0].tile.width);
		final h = Std.int(bitmaps[0].tile.height);
		Assert.equals(56, w);
		Assert.equals(50, h);
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
		// cube(1,0,-1) pointy(16,16): x = √3*16 ≈ 27.713, y = 0.0
		// +50: w = Std.int(77.713) = 77, h = Std.int(50.0) = 50
		final w = Std.int(bitmaps[0].tile.width);
		final h = Std.int(bitmaps[0].tile.height);
		Assert.equals(77, w);
		Assert.equals(50, h);
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
		// offset(1, 0, even) → cube(1, -1, 0) → x ≈ 13.856, y = -24.0
		Assert.floatEquals(13.856, bitmaps[0].x, 0.01);
		Assert.floatEquals(-24.0, bitmaps[0].y, 0.01);
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
		// doubled(2, 0) → cube(2, -1, -1) → x = (3√3/2)*16 ≈ 41.569, y = -24.0
		Assert.floatEquals(41.569, bitmaps[0].x, 0.01);
		Assert.floatEquals(-24.0, bitmaps[0].y, 0.01);
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
		// hex(pointy, 16, 16): width = size.x = 16, height = size.y = 16
		final w = Std.int(bitmaps[0].tile.width);
		final h = Std.int(bitmaps[0].tile.height);
		Assert.equals(16, w);
		Assert.equals(16, h);
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

	// ==================== Hex offset/doubled extended tests ====================

	@Test
	public function testHexOffsetFlatOrientation():Void {
		// flat orientation: offset(1, 0, even) should produce different position than pointy
		final resultFlat = buildFromSource("
			#test programmable() {
				hex: flat(16, 16)
				bitmap(generated(color(5, 5, #f00))): $hex.offset(1, 0, even)
			}
		", "test");
		final resultPointy = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $hex.offset(1, 0, even)
			}
		", "test");
		final flatBitmaps = findVisibleBitmapDescendants(resultFlat.object);
		final pointyBitmaps = findVisibleBitmapDescendants(resultPointy.object);
		Assert.equals(1, flatBitmaps.length);
		Assert.isTrue(flatBitmaps[0].x != pointyBitmaps[0].x || flatBitmaps[0].y != pointyBitmaps[0].y,
			"flat and pointy offset should produce different positions");
	}

	@Test
	public function testHexDoubledFlatOrientation():Void {
		// flat orientation: doubled(2, 0) should produce different position than pointy
		final resultFlat = buildFromSource("
			#test programmable() {
				hex: flat(16, 16)
				bitmap(generated(color(5, 5, #f00))): $hex.doubled(2, 0)
			}
		", "test");
		final resultPointy = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $hex.doubled(2, 0)
			}
		", "test");
		final flatBitmaps = findVisibleBitmapDescendants(resultFlat.object);
		final pointyBitmaps = findVisibleBitmapDescendants(resultPointy.object);
		Assert.equals(1, flatBitmaps.length);
		Assert.isTrue(flatBitmaps[0].x != pointyBitmaps[0].x || flatBitmaps[0].y != pointyBitmaps[0].y,
			"flat and pointy doubled should produce different positions");
	}

	@Test
	public function testHexOffsetNonZeroRow():Void {
		// offset(0, 2, even) — row 2 should have y offset
		final result = buildFromSource("
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $hex.offset(0, 2, even)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.isTrue(bitmaps[0].y != 0, "offset row 2 should have non-zero y");
	}

	@Test
	public function testNamedHexOffset():Void {
		// Named hex system with offset coordinates
		final result = buildFromSource("
			#test programmable() {
				hex: #myHex pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $myHex.offset(1, 0, even)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		// Should match default hex offset(1, 0, even) position
		Assert.floatEquals(13.856, bitmaps[0].x, 0.01);
		Assert.floatEquals(-24.0, bitmaps[0].y, 0.01);
	}

	@Test
	public function testNamedHexDoubled():Void {
		// Named hex system with doubled coordinates
		final result = buildFromSource("
			#test programmable() {
				hex: #myHex pointy(16, 16)
				bitmap(generated(color(5, 5, #f00))): $myHex.doubled(2, 0)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.floatEquals(41.569, bitmaps[0].x, 0.01);
		Assert.floatEquals(-24.0, bitmaps[0].y, 0.01);
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

		// Test at t=1.75: first cycle 0→1 (1.0s), then reversed, 0.75s into reversed cycle
		// PingPong rate = 1.0 - 0.75 = 0.25 (NOT 0.75 which non-pingPong loop would give)
		ap.update(1.75);
		final state = ap.getState();
		Assert.floatEquals(0.25, state.rate);
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

	// ==================== Layout repeatable: multi-child iterator fix ====================

	@Test
	public function testLayoutRepeatableMultiChild():Void {
		// Regression test: layout iterator should advance once per iteration,
		// not once per child. With 3 layout points and 2 children per iteration,
		// the old code would consume 2 points per iteration and run out at iteration 2.
		final result = buildFromSource("
			layouts {
				#testLayout list {
					point: 10, 10
					point: 110, 10
					point: 210, 10
				}
			}
			#test programmable() {
				repeatable($i, layout(\"main\", \"testLayout\")) {
					pos: 0, 0
					bitmap(generated(color(40, 20, red))): 0, 0
					bitmap(generated(color(30, 15, blue))): 5, 5
				}
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		// 3 layout points x 2 children = 6 bitmaps
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(6, bitmaps.length);

		// Verify positions: both children in each iteration should share the same
		// layout-point offset. The first bitmap is at (layoutX+0, layoutY+0),
		// the second at (layoutX+5, layoutY+5).
		// Layout points: (10,10), (110,10), (210,10)
		// Iteration 0: bitmap[0] at (10,10), bitmap[1] at (15,15)
		// Iteration 1: bitmap[2] at (110,10), bitmap[3] at (115,15)
		// Iteration 2: bitmap[4] at (210,10), bitmap[5] at (215,15)
		Assert.floatEquals(10, bitmaps[0].x);
		Assert.floatEquals(10, bitmaps[0].y);
		Assert.floatEquals(15, bitmaps[1].x);
		Assert.floatEquals(15, bitmaps[1].y);
		Assert.floatEquals(110, bitmaps[2].x);
		Assert.floatEquals(10, bitmaps[2].y);
		Assert.floatEquals(115, bitmaps[3].x);
		Assert.floatEquals(15, bitmaps[3].y);
		Assert.floatEquals(210, bitmaps[4].x);
		Assert.floatEquals(10, bitmaps[4].y);
		Assert.floatEquals(215, bitmaps[5].x);
		Assert.floatEquals(15, bitmaps[5].y);
	}

	@Test
	public function testLayoutRepeatableSingleChild():Void {
		// Sanity check: single-child layout repeatable should still work
		final result = buildFromSource("
			layouts {
				#testLayout list {
					point: 0, 0
					point: 50, 0
					point: 100, 0
					point: 150, 0
				}
			}
			#test programmable() {
				repeatable($i, layout(\"main\", \"testLayout\")) {
					pos: 0, 0
					bitmap(generated(color(40, 20, red))): 0, 0
				}
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(4, bitmaps.length);
	}

	// ==================== Incremental conditional apply tests ====================

	@Test
	public function testIncrementalApplyFilterNotAppliedWhenConditionFalse():Void {
		final result = buildFromSource("
			#test programmable(dead:uint=0) {
				bitmap(generated(color(50, 50, #ff0000))): 0, 0
				@(dead => 1) apply {
					filter: grayscale(1.0)
				}
			}
		", "test", null, Incremental);
		Assert.notNull(result, "Build should succeed");
		Assert.isNull(result.object.filter, "Filter should NOT be applied when dead=0");
	}

	@Test
	public function testIncrementalApplyFilterAppliedWhenConditionTrue():Void {
		final params = new Map<String, Dynamic>();
		params.set("dead", 1);
		final result = buildFromSource("
			#test programmable(dead:uint=0) {
				bitmap(generated(color(50, 50, #ff0000))): 0, 0
				@(dead => 1) apply {
					filter: grayscale(1.0)
				}
			}
		", "test", params, Incremental);
		Assert.notNull(result, "Build should succeed");
		Assert.notNull(result.object.filter, "Filter SHOULD be applied when dead=1");
	}

	@Test
	public function testIncrementalApplyFilterTogglesWithSetParameter():Void {
		final result = buildFromSource("
			#test programmable(dead:uint=0) {
				bitmap(generated(color(50, 50, #ff0000))): 0, 0
				@(dead => 1) apply {
					filter: grayscale(1.0)
				}
			}
		", "test", null, Incremental);
		Assert.isNull(result.object.filter, "Filter should NOT be applied initially (dead=0)");

		// Toggle on
		result.setParameter("dead", 1);
		Assert.notNull(result.object.filter, "Filter SHOULD be applied after dead=1");

		// Toggle off
		result.setParameter("dead", 0);
		Assert.isNull(result.object.filter, "Filter should be removed after dead=0");
	}

	@Test
	public function testIncrementalApplyAlphaTogglesWithSetParameter():Void {
		final result = buildFromSource("
			#test programmable(dim:uint=0) {
				bitmap(generated(color(50, 50, #ff0000))): 0, 0
				@(dim => 1) apply {
					alpha: 0.3
				}
			}
		", "test", null, Incremental);
		Assert.floatEquals(1.0, result.object.alpha);

		// Toggle on
		result.setParameter("dim", 1);
		Assert.floatEquals(0.3, result.object.alpha);

		// Toggle off — should restore original alpha
		result.setParameter("dim", 0);
		Assert.floatEquals(1.0, result.object.alpha);
	}

	// ==================== Incremental graphics expression tracking ====================

	@Test
	public function testIncrementalGraphicsRedrawsOnSetParameter():Void {
		final result = buildFromSource("
			#test programmable(val:uint=100, maxVal:uint=100) {
				graphics(rect(#ff0000, filled, $val * 200 / $maxVal, 20): 0, 0): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		final g = findGraphicsChild(result.object);
		Assert.notNull(g, "Should find h2d.Graphics child");
		Assert.isTrue(hasGraphicsContent(g), "Graphics should have content before setParameter");
		final childCountBefore = result.object.numChildren;

		// setParameter should trigger clear+redraw
		result.setParameter("val", 50);
		final g2 = findGraphicsChild(result.object);
		Assert.notNull(g2, "Graphics child should still exist after setParameter");
		Assert.isTrue(g2.visible, "Graphics should be visible after redraw");
		Assert.isTrue(hasGraphicsContent(g2), "Graphics should have content after setParameter");
		Assert.equals(childCountBefore, result.object.numChildren, "Child count should be stable after redraw");
	}

	@Test
	public function testIncrementalGraphicsWithConditionalAndExpression():Void {
		final result = buildFromSource("
			#test programmable(hp:uint=80, maxHp:uint=100) {
				graphics(rect(#1a1a1a, filled, 200, 20): 0, 0): 0, 0
				@(hp => 1..50) graphics(rect(#cc3322, filled, $hp * 200 / $maxHp, 20): 0, 0): 0, 0
				@(hp => 51..100) graphics(rect(#44cc44, filled, $hp * 200 / $maxHp, 20): 0, 0): 0, 0
			}
		", "test", null, Incremental);
		// hp=80 → green bar visible, red bar hidden
		Assert.equals(3, result.object.numChildren);
		final redBar = result.object.getChildAt(1);
		final greenBar = result.object.getChildAt(2);
		Assert.isFalse(redBar.visible);
		Assert.isTrue(greenBar.visible);

		// Change to hp=30 → red visible, green hidden
		result.setParameter("hp", 30);
		Assert.isTrue(redBar.visible);
		Assert.isFalse(greenBar.visible);

		// Change to hp=70 → green visible, red hidden
		result.setParameter("hp", 70);
		Assert.isFalse(redBar.visible);
		Assert.isTrue(greenBar.visible);
	}

	@Test
	public function testIncrementalGraphicsBatchUpdate():Void {
		final result = buildFromSource("
			#test programmable(val:uint=100, maxVal:uint=100) {
				graphics(rect(#ff0000, filled, $val * 200 / $maxVal, 20): 0, 0): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		final gBefore = findGraphicsChild(result.object);
		Assert.notNull(gBefore, "Graphics child should exist before batch update");
		Assert.isTrue(hasGraphicsContent(gBefore), "Graphics should have content before batch update");

		// Batch update should also work
		result.beginUpdate();
		result.setParameter("val", 25);
		result.setParameter("maxVal", 200);
		result.endUpdate();
		final g = findGraphicsChild(result.object);
		Assert.notNull(g, "Graphics child should still exist after batch update");
		Assert.isTrue(g.visible, "Graphics should be visible after batch update");
		Assert.isTrue(hasGraphicsContent(g), "Graphics should have content after batch update");
	}

	// ==================== Pixels actual pixel data verification ====================

	static inline final PIXEL_H = 5;
	static inline final PIXEL_W = 100;
	static inline final RED = 0xFFFF0000;

	/** Check all pixels: 0..filledWidth should be expectedColor, filledWidth..totalWidth should be 0 (transparent). */
	static function assertPixelRect(pl:bh.base.PixelLine.PixelLines, filledWidth:Int, expectedColor:Int, label:String):Void {
		for (y in 0...pl.data.height) {
			for (x in 0...pl.data.width) {
				final actual = pl.data.getPixel(x, y);
				if (x < filledWidth && y < PIXEL_H) {
					if (actual != expectedColor) {
						Assert.fail('$label: pixel($x,$y) expected filled 0x${StringTools.hex(expectedColor, 8)} but got 0x${StringTools.hex(actual, 8)}');
						return;
					}
				} else {
					if (actual != 0) {
						Assert.fail('$label: pixel($x,$y) expected transparent but got 0x${StringTools.hex(actual, 8)}');
						return;
					}
				}
			}
		}
		Assert.pass();
	}

	@Test
	public function testPixelsFilledRectAt100Percent():Void {
		final result = buildFromSource("
			#test programmable(val:uint=100) {
				pixels (
					filledRect 0, 0, $val, 5, #ff0000
				);
			}
		", "test");
		Assert.notNull(result);
		final pl = findPixelLinesChild(result.object);
		Assert.notNull(pl, "Should have a PixelLines child");
		assertPixelRect(pl, PIXEL_W, RED, "val=100");
	}

	@Test
	public function testPixelsFilledRectAt50Percent():Void {
		final params = new Map<String, Dynamic>();
		params.set("val", 50);
		final result = buildFromSource("
			#test programmable(val:uint=100) {
				pixels (
					filledRect 0, 0, $val, 5, #ff0000
				);
			}
		", "test", params);
		Assert.notNull(result);
		final pl = findPixelLinesChild(result.object);
		Assert.notNull(pl, "Should have a PixelLines child");
		assertPixelRect(pl, 50, RED, "val=50");
	}

	@Test
	public function testPixelsFilledRectAt0Percent():Void {
		final params = new Map<String, Dynamic>();
		params.set("val", 0);
		final result = buildFromSource("
			#test programmable(val:uint=100) {
				pixels (
					filledRect 0, 0, $val, 5, #ff0000
				);
			}
		", "test", params);
		Assert.notNull(result);
		final pl = findPixelLinesChild(result.object);
		if (pl != null) {
			// With val=0, all pixels should be transparent
			assertPixelRect(pl, 0, RED, "val=0");
		} else {
			// No PixelLines child at all is also valid for a zero-width rect
			Assert.isNull(pl, "No PixelLines child expected for val=0");
		}
	}

	@Test
	public function testIncrementalPixelsActualDataAfterSetParameter():Void {
		final result = buildFromSource("
			#test programmable(val:uint=100) {
				pixels (
					filledRect 0, 0, $val, 5, #ff0000
				);
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		var pl = findPixelLinesChild(result.object);
		Assert.notNull(pl, "Should have a PixelLines child");
		assertPixelRect(pl, PIXEL_W, RED, "initial val=100");

		result.setParameter("val", 50);
		pl = findPixelLinesChild(result.object);
		Assert.notNull(pl, "Should still have a PixelLines child after update");
		assertPixelRect(pl, 50, RED, "after val=50");

		result.setParameter("val", 0);
		pl = findPixelLinesChild(result.object);
		if (pl != null)
			assertPixelRect(pl, 0, RED, "after val=0");
		else
			Assert.pass();
	}

	@Test
	public function testIncrementalPixelsSweep100to0():Void {
		final result = buildFromSource("
			#test programmable(val:uint=100) {
				pixels (
					filledRect 0, 0, $val, 5, #ff0000
				);
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		// Sweep from 100 down to 0 in steps of 10
		var val = 100;
		while (val >= 0) {
			result.setParameter("val", val);
			final pl = findPixelLinesChild(result.object);
			if (val == 0) {
				if (pl != null)
					assertPixelRect(pl, 0, RED, 'sweep val=$val');
				else
					Assert.pass();
			} else {
				Assert.notNull(pl, 'Should have PixelLines at val=$val');
				assertPixelRect(pl, val, RED, 'sweep val=$val');
			}
			val -= 10;
		}
	}

	// ==================== Incremental pixels expression tracking ====================

	@Test
	public function testIncrementalPixelsRedrawsOnSetParameter():Void {
		final result = buildFromSource("
			#test programmable(val:uint=100, maxVal:uint=100) {
				pixels (
					filledRect 0, 0, $val * 32 / $maxVal, 5, #ff0000
				);
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		final pl = bitmaps[0];
		final tileBefore = pl.tile;
		Assert.notNull(tileBefore);
		final widthBefore = tileBefore.width;

		// setParameter should trigger redraw — tile dimensions should change
		// val=100 → width=32, val=50 → width=16
		result.setParameter("val", 50);
		Assert.notNull(pl.tile, "Tile should still exist after setParameter");
		Assert.isTrue(pl.tile.width != widthBefore || pl.tile != tileBefore,
			"Tile should change after setParameter (width before: " + widthBefore + ", after: " + pl.tile.width + ")");
	}

	@Test
	public function testIncrementalPixelsWithConditionalAndExpression():Void {
		final result = buildFromSource("
			#test programmable(hp:uint=80, maxHp:uint=100) {
				pixels (
					filledRect 0, 0, 34, 7, #111111
				);
				@(hp => 1..50) pixels (
					filledRect 0, 0, $hp * 32 / $maxHp, 5, #cc3322
				);
				@(hp => 51..100) pixels (
					filledRect 0, 0, $hp * 32 / $maxHp, 5, #44cc44
				);
			}
		", "test", null, Incremental);
		// hp=80 → green pixels visible, red hidden
		Assert.equals(3, result.object.numChildren);
		final redPixels = result.object.getChildAt(1);
		final greenPixels = result.object.getChildAt(2);
		Assert.isFalse(redPixels.visible);
		Assert.isTrue(greenPixels.visible);

		// Change to hp=30 → red visible, green hidden
		result.setParameter("hp", 30);
		Assert.isTrue(redPixels.visible);
		Assert.isFalse(greenPixels.visible);
	}

	@Test
	public function testIncrementalDynamicRefWithGraphics():Void {
		final result = buildFromSource("
			#bar programmable(val:uint=100, maxVal:uint=100) {
				graphics(rect(#1a1a1a, filled, 200, 20): 0, 0): 0, 0
				graphics(rect(#44cc44, filled, $val * 200 / $maxVal, 20): 0, 0): 0, 0
			}
			#parent programmable(hp:uint=100, maxHp:uint=100) {
				dynamicRef($bar, val=>$hp, maxVal=>$maxHp): 0, 0
			}
		", "parent", null, Incremental);
		Assert.notNull(result);
		final childCountBefore = result.object.numChildren;
		Assert.isTrue(childCountBefore > 0, "Parent should have dynamicRef children");

		// setParameter on parent should propagate to dynamicRef child
		result.beginUpdate();
		result.setParameter("hp", 50);
		result.endUpdate();
		Assert.equals(childCountBefore, result.object.numChildren, "Child count should be stable after parameter propagation");
		Assert.isTrue(result.object.numChildren > 0, "Children should survive parameter propagation");
	}

	// ==================== Incremental conditional graphics content ====================

	@Test
	public function testIncrementalConditionalGraphicsHasContent():Void {
		// Bug: incremental mode with conditional graphics produces empty h2d.Graphics objects.
		// The graphics element is created and drawGraphicsElements IS called, but the content
		// may end up empty due to build ordering issues.
		final result = buildFromSource("
			#test programmable(status:[normal,hover]=normal) {
				@(status=>normal) graphics(rect(#0000ff, filled, 100, 50): 0, 0): 0, 0
				@(status=>hover) graphics(rect(#00ff00, filled, 100, 50): 0, 0): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		Assert.equals(2, result.object.numChildren);

		// Normal graphics should be visible, hover graphics hidden
		final normalGfx:h2d.Graphics = cast result.object.getChildAt(0);
		final hoverGfx:h2d.Graphics = cast result.object.getChildAt(1);
		Assert.isTrue(normalGfx.visible, "Normal graphics should be visible");
		Assert.isFalse(hoverGfx.visible, "Hover graphics should be hidden");

		// Both should have drawn content (not empty buffers)
		Assert.isTrue(hasGraphicsContent(normalGfx), "Normal graphics should have drawn content");
		Assert.isTrue(hasGraphicsContent(hoverGfx), "Hover graphics (initially hidden) should still have drawn content");

		// Toggle to hover (enum params need string values)
		result.setParameter("status", "hover");
		Assert.isFalse(normalGfx.visible, "Normal should now be hidden");
		Assert.isTrue(hoverGfx.visible, "Hover should now be visible");

		// Content should still be present in both
		Assert.isTrue(hasGraphicsContent(normalGfx), "Normal graphics content should survive visibility toggle");
		Assert.isTrue(hasGraphicsContent(hoverGfx), "Hover graphics content should survive visibility toggle");
	}

	@Test
	public function testIncrementalDefaultGraphicsHasContent():Void {
		// @default catch-all: only fires when NO conditional sibling matched.
		// With @else (follows immediately preceding sibling), use @default for "none of the above".
		final result = buildFromSource("
			#test programmable(status:[normal,hover,pressed]=normal) {
				@(status=>normal) graphics(rect(#ff0000, filled, 80, 40): 0, 0): 0, 0
				@(status=>hover) graphics(rect(#00ff00, filled, 80, 40): 0, 0): 0, 0
				@default graphics(rect(#0000ff, filled, 80, 40): 0, 0): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		Assert.equals(3, result.object.numChildren);

		final normalGfx:h2d.Graphics = cast result.object.getChildAt(0);
		final hoverGfx:h2d.Graphics = cast result.object.getChildAt(1);
		final defaultGfx:h2d.Graphics = cast result.object.getChildAt(2);

		// Initially: normal visible, others hidden
		Assert.isTrue(normalGfx.visible, "Normal should be visible");
		Assert.isFalse(hoverGfx.visible, "Hover should be hidden");
		Assert.isFalse(defaultGfx.visible, "@default should be hidden");

		// All should have content regardless of visibility
		Assert.isTrue(hasGraphicsContent(normalGfx), "Normal graphics should have content");
		Assert.isTrue(hasGraphicsContent(hoverGfx), "Hover graphics should have content");
		Assert.isTrue(hasGraphicsContent(defaultGfx), "@default graphics should have content");

		// Switch to pressed (triggers @default)
		result.setParameter("status", "pressed");
		Assert.isFalse(normalGfx.visible);
		Assert.isFalse(hoverGfx.visible);
		Assert.isTrue(defaultGfx.visible, "@default should now be visible");
		Assert.isTrue(hasGraphicsContent(defaultGfx), "@default graphics should have content when visible");
	}

	@Test
	public function testIncrementalElseGraphicsHasContent():Void {
		// @else follows immediately preceding sibling: fires when that sibling didn't match.
		final result = buildFromSource("
			#test programmable(status:[normal,hover]=normal) {
				@(status=>normal) graphics(rect(#ff0000, filled, 80, 40): 0, 0): 0, 0
				@else graphics(rect(#0000ff, filled, 80, 40): 0, 0): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		Assert.equals(2, result.object.numChildren);

		final normalGfx:h2d.Graphics = cast result.object.getChildAt(0);
		final elseGfx:h2d.Graphics = cast result.object.getChildAt(1);

		// Initially: normal matches, @else hidden
		Assert.isTrue(normalGfx.visible, "Normal should be visible");
		Assert.isFalse(elseGfx.visible, "@else should be hidden");

		// Both should have content
		Assert.isTrue(hasGraphicsContent(normalGfx), "Normal graphics should have content");
		Assert.isTrue(hasGraphicsContent(elseGfx), "@else graphics should have content");

		// Switch to hover (normal no longer matches, @else fires)
		result.setParameter("status", "hover");
		Assert.isFalse(normalGfx.visible, "Normal should be hidden");
		Assert.isTrue(elseGfx.visible, "@else should now be visible");
		Assert.isTrue(hasGraphicsContent(elseGfx), "@else graphics should have content when visible");
	}

	@Test
	public function testIncrementalConditionalGraphicsWithDynamicContent():Void {
		// Conditional graphics where the content itself references a parameter
		final result = buildFromSource("
			#test programmable(status:[normal,hover]=normal, w:uint=100) {
				@(status=>normal) graphics(rect(#ff0000, filled, $w, 30): 0, 0): 0, 0
				@(status=>hover) graphics(rect(#00ff00, filled, $w, 30): 0, 0): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);

		final normalGfx:h2d.Graphics = cast result.object.getChildAt(0);
		final hoverGfx:h2d.Graphics = cast result.object.getChildAt(1);

		// Both should have content after initial build
		Assert.isTrue(hasGraphicsContent(normalGfx), "Normal dynamic graphics should have content");
		Assert.isTrue(hasGraphicsContent(hoverGfx), "Hover dynamic graphics (hidden) should have content");

		// Change the width parameter — tracked expression should redraw both
		result.setParameter("w", 50);
		Assert.isTrue(hasGraphicsContent(normalGfx), "Normal graphics should have content after param change");
		Assert.isTrue(hasGraphicsContent(hoverGfx), "Hover graphics should have content after param change");

		// Now toggle visibility
		result.setParameter("status", "hover");
		Assert.isFalse(normalGfx.visible);
		Assert.isTrue(hoverGfx.visible);
		Assert.isTrue(hasGraphicsContent(hoverGfx), "Hover graphics should have content when made visible");
	}

	// ==================== Bool settings ====================

	@Test
	public function testBoolSettingTrue():Void {
		final result = buildFromSource("
			#test programmable() {
				settings{visible:bool=>true}
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result);
		Assert.isTrue(result.rootSettings.getBoolOrDefault("visible", false));
	}

	@Test
	public function testBoolSettingFalse():Void {
		final result = buildFromSource("
			#test programmable() {
				settings{enabled:bool=>false}
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result);
		Assert.isFalse(result.rootSettings.getBoolOrDefault("enabled", true));
	}

	@Test
	public function testBoolSettingYesNo():Void {
		final result = buildFromSource("
			#test programmable() {
				settings{a:bool=>yes, b:bool=>no}
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result);
		Assert.isTrue(result.rootSettings.getBoolOrDefault("a", false));
		Assert.isFalse(result.rootSettings.getBoolOrDefault("b", true));
	}

	@Test
	public function testBoolSettingNumeric():Void {
		final result = buildFromSource("
			#test programmable() {
				settings{on:bool=>1, off:bool=>0}
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result);
		Assert.isTrue(result.rootSettings.getBoolOrDefault("on", false));
		Assert.isFalse(result.rootSettings.getBoolOrDefault("off", true));
	}

	@Test
	public function testBoolSettingCoercion():Void {
		final result = buildFromSource("
			#test programmable() {
				settings{flag:bool=>true}
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result);
		// Bool coerces to string
		Assert.equals("true", result.rootSettings.getStringOrDefault("flag", ""));
		// Bool coerces to int
		Assert.equals(1, result.rootSettings.getIntOrDefault("flag", 0));
		// Bool coerces to float
		Assert.equals(1.0, result.rootSettings.getFloatOrDefault("flag", 0.0));
	}

	@Test
	public function testBoolSettingMixed():Void {
		final result = buildFromSource("
			#test programmable() {
				settings{name=>hello, count:int=>5, active:bool=>true}
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result);
		Assert.equals("hello", result.rootSettings.getStringOrDefault("name", ""));
		Assert.equals(5, result.rootSettings.getIntOrDefault("count", 0));
		Assert.isTrue(result.rootSettings.getBoolOrDefault("active", false));
	}

	// ==================== getNodeSettings ====================

	@Test
	public function testGetNodeSettingsUsesElementName():Void {
		final result = buildFromSource("
			#test programmable() {
				#btn placeholder(generated(cross(10, 10, #f00)), builderParameter(\"btn\")) {
					settings{action=>buy, price:int=>50}
					pos: 0, 0
				}
				#lbl placeholder(generated(cross(10, 10, #0f0)), builderParameter(\"lbl\")) {
					settings{action=>sell, price:int=>100}
					pos: 20, 0
				}
			}
		", "test");
		Assert.notNull(result);
		final btnSettings = result.getNodeSettings("btn");
		Assert.notNull(btnSettings);
		Assert.same(RSVString("buy"), btnSettings["action"]);
		Assert.same(RSVInt(50), btnSettings["price"]);
		final lblSettings = result.getNodeSettings("lbl");
		Assert.notNull(lblSettings);
		Assert.same(RSVString("sell"), lblSettings["action"]);
		Assert.same(RSVInt(100), lblSettings["price"]);
	}

	// ===== Helpers =====

	static function findGraphicsChild(obj:h2d.Object):Null<h2d.Graphics> {
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, h2d.Graphics))
				return cast child;
		}
		return null;
	}

	/** Check if an h2d.Graphics has any drawn content by inspecting its internal bounds tracking. */
	@:access(h2d.Graphics)
	static function hasGraphicsContent(g:h2d.Graphics):Bool {
		// After drawing, xMin/yMin are updated from their initial POSITIVE_INFINITY values.
		// If still at POSITIVE_INFINITY, no vertices were ever added.
		return g.xMin != Math.POSITIVE_INFINITY;
	}

	static function findPixelLinesChild(obj:h2d.Object):Null<bh.base.PixelLine.PixelLines> {
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, bh.base.PixelLine.PixelLines))
				return cast child;
			final found = findPixelLinesChild(child);
			if (found != null)
				return found;
		}
		return null;
	}

	// ==================== Generic settings pass-through ====================

	@Test
	public function testSettingsPassThroughParam():Void {
		// A programmable with a custom param; pass it via buildWithParameters (simulating settings pass-through)
		final result = buildFromSource("
			#test programmable(myWidth:uint=10, myHeight:uint=5) {
				bitmap(generated(color($myWidth, $myHeight, #f00))): 0, 0
			}
		", "test", ["myWidth" => 30, "myHeight" => 20]);
		Assert.notNull(result, "Build should succeed with pass-through params");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
		Assert.equals(20, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testSettingsUnknownParamThrowsWithMessage():Void {
		// Passing a param that doesn't exist in the programmable should throw with helpful message
		var errorMsg:String = null;
		try {
			buildFromSource("
				#test programmable(x:uint=10) {
					bitmap(generated(color($x, $x, #f00))): 0, 0
				}
			", "test", ["nonexistent" => 42]);
		} catch (e:Dynamic) {
			errorMsg = Std.string(e);
		}
		Assert.notNull(errorMsg, "Should throw for unknown param");
		Assert.isTrue(errorMsg.indexOf("nonexistent") >= 0, 'Error should mention "nonexistent", got: $errorMsg');
		Assert.isTrue(errorMsg.indexOf("does not match any parameter") >= 0, 'Error should say "does not match any parameter", got: $errorMsg');
		Assert.isTrue(errorMsg.indexOf("#test") >= 0, 'Error should mention programmable name "#test", got: $errorMsg');
		Assert.isTrue(errorMsg.indexOf("x") >= 0, 'Error should list available param "x", got: $errorMsg');
	}

	@Test
	public function testSettingsPassThroughWithDefaultOverride():Void {
		// Pass-through should override the default value
		final resultDefault = buildFromSource("
			#test programmable(w:uint=50) {
				bitmap(generated(color($w, 10, #f00))): 0, 0
			}
		", "test");
		final bitmapsDefault = findVisibleBitmapDescendants(resultDefault.object);
		Assert.equals(50, Std.int(bitmapsDefault[0].tile.width));

		final resultOverride = buildFromSource("
			#test programmable(w:uint=50) {
				bitmap(generated(color($w, 10, #f00))): 0, 0
			}
		", "test", ["w" => 80]);
		final bitmapsOverride = findVisibleBitmapDescendants(resultOverride.object);
		Assert.equals(80, Std.int(bitmapsOverride[0].tile.width));
	}

	// ==================== Repeatable variable in conditional ====================

	@Test
	public function testRepeatableVarConditionalExact():Void {
		// @($i => 0) should show element only on first iteration
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, step(3, dx: 20)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
					@($i => 0) bitmap(generated(color(5, 5, #00f))): 0, 0
				}
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		// 3 red bitmaps (all iterations) + 1 blue bitmap (only iteration 0)
		Assert.equals(4, bitmaps.length);
	}

	@Test
	public function testRepeatableVarConditionalRange():Void {
		// @($i >= 2) should show element only on iterations 2+
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, step(4, dx: 20)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
					@($i >= 2) bitmap(generated(color(5, 5, #0f0))): 0, 0
				}
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		// 4 red bitmaps (all iterations) + 2 green bitmaps (iterations 2, 3)
		Assert.equals(6, bitmaps.length);
	}

	@Test
	public function testRepeatableVarConditionalNot():Void {
		// @($i != 1) should show on all iterations except 1
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, step(3, dx: 20)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
					@($i != 1) bitmap(generated(color(5, 5, #ff0))): 0, 0
				}
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		// 3 red bitmaps (all iterations) + 2 yellow bitmaps (iterations 0, 2)
		Assert.equals(5, bitmaps.length);
	}

	// ==================== Incremental scale/alpha/filter expression tracking ====================

	@Test
	public function testIncrementalScaleTrackedOnSetParameter():Void {
		final result = buildFromSource("
			#test programmable(s:float=1.0) {
				bitmap(generated(color(50, 50, #ff0000))) {
					scale: $s
					pos: 0, 0
				}
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		final bmp = result.object.getChildAt(0);
		Assert.floatEquals(1.0, bmp.scaleX);
		Assert.floatEquals(1.0, bmp.scaleY);

		result.setParameter("s", 0.5);
		Assert.floatEquals(0.5, bmp.scaleX);
		Assert.floatEquals(0.5, bmp.scaleY);

		result.setParameter("s", 2.0);
		Assert.floatEquals(2.0, bmp.scaleX);
		Assert.floatEquals(2.0, bmp.scaleY);
	}

	@Test
	public function testIncrementalAlphaTrackedOnSetParameter():Void {
		final result = buildFromSource("
			#test programmable(a:float=1.0) {
				bitmap(generated(color(50, 50, #ff0000))) {
					alpha: $a
					pos: 0, 0
				}
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		final bmp = result.object.getChildAt(0);
		Assert.floatEquals(1.0, bmp.alpha);

		result.setParameter("a", 0.3);
		Assert.floatEquals(0.3, bmp.alpha);

		result.setParameter("a", 0.8);
		Assert.floatEquals(0.8, bmp.alpha);
	}

	@Test
	public function testIncrementalFilterTrackedOnSetParameter():Void {
		final result = buildFromSource("
			#test programmable(grey:float=0.0) {
				bitmap(generated(color(50, 50, #ff0000))) {
					filter: grayscale($grey)
					pos: 0, 0
				}
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		final bmp = result.object.getChildAt(0);

		result.setParameter("grey", 1.0);
		Assert.notNull(bmp.filter, "Filter should be set after grey=1.0");

		result.setParameter("grey", 0.0);
		Assert.notNull(bmp.filter, "Filter still set (grayscale(0) is still a filter object)");
	}

	@Test
	public function testIncrementalScaleExpressionTrackedOnSetParameter():Void {
		final result = buildFromSource("
			#test programmable(zoom:uint=100) {
				bitmap(generated(color(50, 50, #ff0000))) {
					scale: $zoom / 100
					pos: 0, 0
				}
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		final bmp = result.object.getChildAt(0);
		Assert.floatEquals(1.0, bmp.scaleX);

		result.setParameter("zoom", 200);
		Assert.floatEquals(2.0, bmp.scaleX);

		result.setParameter("zoom", 50);
		Assert.floatEquals(0.5, bmp.scaleX);
	}

	// ==================== Flow alignment ====================

	@Test
	public function testFlowHorizontalAlign():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: vertical, horizontalAlign: middle, minWidth: 100) {
					bitmap(generated(color(20, 10, #f00))): 0, 0
				}
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final flow = Std.downcast(result.object.getChildAt(0), h2d.Flow);
		Assert.notNull(flow);
		Assert.equals(h2d.Flow.FlowAlign.Middle, flow.horizontalAlign);
	}

	@Test
	public function testFlowVerticalAlign():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: horizontal, verticalAlign: bottom, minHeight: 100) {
					bitmap(generated(color(20, 10, #f00))): 0, 0
				}
			}
		", "test");
		final flow = Std.downcast(result.object.getChildAt(0), h2d.Flow);
		Assert.notNull(flow);
		Assert.equals(h2d.Flow.FlowAlign.Bottom, flow.verticalAlign);
	}

	@Test
	public function testPerElementFlowHAlign():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: vertical, minWidth: 200) {
					@flow.halign(right) bitmap(generated(color(20, 10, #f00))): 0, 0
				}
			}
		", "test");
		final flow = Std.downcast(result.object.getChildAt(0), h2d.Flow);
		Assert.notNull(flow);
		final bmp = flow.getChildAt(0);
		final props = flow.getProperties(bmp);
		Assert.equals(h2d.Flow.FlowAlign.Right, props.horizontalAlign);
	}

	@Test
	public function testPerElementFlowOffset():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: vertical) {
					@flow.offset(5, -3) bitmap(generated(color(20, 10, #f00))): 0, 0
				}
			}
		", "test");
		final flow = Std.downcast(result.object.getChildAt(0), h2d.Flow);
		Assert.notNull(flow);
		final bmp = flow.getChildAt(0);
		final props = flow.getProperties(bmp);
		Assert.equals(5, props.offsetX);
		Assert.equals(-3, props.offsetY);
	}

	@Test
	public function testPerElementFlowAbsolute():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: vertical) {
					@flow.absolute bitmap(generated(color(20, 10, #f00))): 0, 0
				}
			}
		", "test");
		final flow = Std.downcast(result.object.getChildAt(0), h2d.Flow);
		Assert.notNull(flow);
		final bmp = flow.getChildAt(0);
		final props = flow.getProperties(bmp);
		Assert.isTrue(props.isAbsolute);
	}

	@Test
	public function testPerElementCombinedFlowProps():Void {
		// Test chaining multiple per-element flow annotations
		final result = buildFromSource("
			#test programmable() {
				flow(layout: vertical, minWidth: 200) {
					@flow.halign(middle) @flow.valign(bottom) @flow.offset(2, 4) bitmap(generated(color(20, 10, #f00))): 0, 0
				}
			}
		", "test");
		final flow = Std.downcast(result.object.getChildAt(0), h2d.Flow);
		Assert.notNull(flow);
		final bmp = flow.getChildAt(0);
		final props = flow.getProperties(bmp);
		Assert.equals(h2d.Flow.FlowAlign.Middle, props.horizontalAlign);
		Assert.equals(h2d.Flow.FlowAlign.Bottom, props.verticalAlign);
		Assert.equals(2, props.offsetX);
		Assert.equals(4, props.offsetY);
	}

	@Test
	public function testFlowPropOutsideFlowThrows():Void {
		// per-element flow properties outside of flow should throw at parse time
		Assert.raises(function() {
			buildFromSource("
				#test programmable() {
					@flow.halign(middle) bitmap(generated(color(20, 10, #f00))): 0, 0
				}
			", "test");
		});
	}

	// ==================== Named range iterators ====================

	@Test
	public function testNamedRangeInclusive():Void {
		// range(from: 0, to: 3) => 0,1,2,3 (4 items)
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, range(from: 0, to: 3)) {
					bitmap(generated(color(10, 10, #f00))): $i * 20, 0
				}
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(4, bitmaps.length);
	}

	@Test
	public function testNamedRangeExclusive():Void {
		// range(from: 0, until: 3) => 0,1,2 (3 items)
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, range(from: 0, until: 3)) {
					bitmap(generated(color(10, 10, #f00))): $i * 20, 0
				}
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(3, bitmaps.length);
	}

	@Test
	public function testNamedRangeInclusiveWithStep():Void {
		// range(from: 0, to: 10, step: 3) => 0,3,6,9 (4 items; 10 not reached)
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, range(from: 0, to: 10, step: 3)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		// to: 10 means end = 11, step = 3, so: ceil((11-0)/3) = 4
		Assert.equals(4, bitmaps.length);
	}

	@Test
	public function testNamedRangeExclusiveWithStep():Void {
		// range(from: 0, until: 10, step: 3) => 0,3,6,9 (4 items)
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, range(from: 0, until: 10, step: 3)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		// until: 10 means end = 10, step = 3, so: ceil((10-0)/3) = 4
		Assert.equals(4, bitmaps.length);
	}

	@Test
	public function testNamedRangeLoopVarValues():Void {
		// range(from: 2, to: 5) => loop var should be 2,3,4,5
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, range(from: 2, to: 5)) {
					text(dd, $i, #fff): $i * 20, 0
				}
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(4, texts.length);
		Assert.equals("2", texts[0].text);
		Assert.equals("3", texts[1].text);
		Assert.equals("4", texts[2].text);
		Assert.equals("5", texts[3].text);
	}

	@Test
	public function testNamedRangeStepLoopVarValues():Void {
		// range(from: 1, to: 9, step: 2) => loop var should be 1,3,5,7,9
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, range(from: 1, to: 9, step: 2)) {
					text(dd, $i, #fff): 0, 0
				}
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(5, texts.length);
		Assert.equals("1", texts[0].text);
		Assert.equals("3", texts[1].text);
		Assert.equals("5", texts[2].text);
		Assert.equals("7", texts[3].text);
		Assert.equals("9", texts[4].text);
	}

	@Test
	public function testNamedRangeNegativeStart():Void {
		// range(from: -2, to: 1) => -2,-1,0,1 (4 items)
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, range(from: -2, to: 1)) {
					text(dd, $i, #fff): 0, 0
				}
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(4, texts.length);
		Assert.equals("-2", texts[0].text);
		Assert.equals("-1", texts[1].text);
		Assert.equals("0", texts[2].text);
		Assert.equals("1", texts[3].text);
	}

	@Test
	public function testNamedRangeWithParamRef():Void {
		// range with $param references for start/end
		final params = new Map<String, Dynamic>();
		params.set("start", 2);
		params.set("count", 6);
		final result = buildFromSource("
			#test programmable(start:uint=0, count:uint=5) {
				repeatable($i, range(from: $start, until: $count)) {
					text(dd, $i, #fff): 0, 0
				}
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		// from: 2, until: 6 => 2,3,4,5 (4 items)
		Assert.equals(4, texts.length);
		Assert.equals("2", texts[0].text);
		Assert.equals("5", texts[3].text);
	}

	@Test
	public function testNamedRangeConditionalOnLoopVar():Void {
		// Conditional comparison on loop var inside named range body
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, range(from: 0, to: 5)) {
					@($i >= 3) bitmap(generated(color(10, 10, #0f0))): 0, 0
				}
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		// Only iterations 3, 4, 5 produce visible bitmaps
		Assert.equals(3, bitmaps.length);
	}

	@Test
	public function testPositionalRangeWithStep():Void {
		// Positional syntax: range(0, 9, 3) => 0,3,6 (3 items, end exclusive)
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, range(0, 9, 3)) {
					text(dd, $i, #fff): 0, 0
				}
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(3, texts.length);
		Assert.equals("0", texts[0].text);
		Assert.equals("3", texts[1].text);
		Assert.equals("6", texts[2].text);
	}

	@Test
	public function testNamedRangeInclusiveVsExclusiveCountDifference():Void {
		// to: N includes N, until: N excludes N
		final resultTo = buildFromSource("
			#test programmable() {
				repeatable($i, range(from: 0, to: 4)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		", "test");
		final resultUntil = buildFromSource("
			#test programmable() {
				repeatable($i, range(from: 0, until: 4)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		", "test");
		final countTo = findVisibleBitmapDescendants(resultTo.object).length;
		final countUntil = findVisibleBitmapDescendants(resultUntil.object).length;
		// to: 4 => 0,1,2,3,4 = 5 items; until: 4 => 0,1,2,3 = 4 items
		Assert.equals(5, countTo);
		Assert.equals(4, countUntil);
		Assert.equals(countTo - 1, countUntil);
	}

	// ==================== Builder error paths ====================

	/** Helper: run a closure and return the error message string, or null if no error. */
	private static function expectError(fn:() -> Void):String {
		try {
			fn();
			return null;
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	@Test
	public function testErrorMissingProgrammable():Void {
		final err = expectError(() -> buildFromSource("
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "nonexistent"));
		Assert.notNull(err, "Should throw for missing programmable");
		Assert.isTrue(err.indexOf("nonexistent") >= 0, 'Error should mention "nonexistent", got: $err');
		Assert.isTrue(err.indexOf("could find element") >= 0, 'Error should say could not find element, got: $err');
	}

	@Test
	public function testErrorMissingProgrammableEmptySource():Void {
		final err = expectError(() -> buildFromSource("
			#other programmable() {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test"));
		Assert.notNull(err, "Should throw when building a name that doesn't exist");
		Assert.isTrue(err.indexOf("test") >= 0, 'Error should mention "test", got: $err');
	}

	@Test
	public function testErrorWrongParamTypeUintGetsString():Void {
		final err = expectError(() -> buildFromSource("
			#test programmable(x:uint=10) {
				bitmap(generated(color($x, $x, #f00))): 0, 0
			}
		", "test", ["x" => "notanumber"]));
		Assert.notNull(err, "Should throw for wrong param type");
		Assert.isTrue(err.indexOf("integer") >= 0 || err.indexOf("uint") >= 0 || err.indexOf("type") >= 0,
			'Error should mention integer or type, got: $err');
	}

	@Test
	public function testErrorWrongParamTypeBoolGetsGarbage():Void {
		final err = expectError(() -> buildFromSource("
			#test programmable(flag:bool=true) {
				@(flag=>true) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else bitmap(generated(color(20, 20, #00f))): 0, 0
			}
		", "test", ["flag" => "notabool"]));
		Assert.notNull(err, "Should throw for unparseable bool value");
		Assert.isTrue(err.indexOf("bool") >= 0 || err.indexOf("Bool") >= 0 || err.indexOf("type") >= 0,
			'Error should mention bool or type, got: $err');
	}

	@Test
	public function testErrorUndefinedReference():Void {
		final err = expectError(() -> buildFromSource("
			#test programmable() {
				bitmap(generated(color($undefined, 10, #f00))): 0, 0
			}
		", "test"));
		Assert.notNull(err, "Should throw for undefined $ref");
		Assert.isTrue(err.indexOf("undefined") >= 0, 'Error should mention "undefined", got: $err');
	}

	@Test
	public function testErrorUndefinedReferenceInExpression():Void {
		final err = expectError(() -> buildFromSource("
			#test programmable(x:uint=10) {
				bitmap(generated(color($x + $missing, 10, #f00))): 0, 0
			}
		", "test"));
		Assert.notNull(err, "Should throw for undefined $missing in expression");
		Assert.isTrue(err.indexOf("missing") >= 0, 'Error should mention "missing", got: $err');
	}

	@Test
	public function testErrorSlotNotFoundInResult():Void {
		final result = buildFromSource("
			#test programmable() {
				#mySlot slot {
					bitmap(generated(color(10, 10, #555))): 0, 0
				}
			}
		", "test");
		Assert.notNull(result);
		final err = expectError(() -> result.getSlot("nonexistent"));
		Assert.notNull(err, "Should throw for nonexistent slot");
		Assert.isTrue(err.indexOf("nonexistent") >= 0, 'Error should mention "nonexistent", got: $err');
	}

	@Test
	public function testErrorSlotIndexedAccessedWithoutIndex():Void {
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, step(3, dx: 20)) {
					#item[$i] slot {
						bitmap(generated(color(10, 10, #555))): 0, 0
					}
				}
			}
		", "test");
		Assert.notNull(result);
		final err = expectError(() -> result.getSlot("item"));
		Assert.notNull(err, "Should throw when accessing indexed slot without index");
		Assert.isTrue(err.indexOf("indexed") >= 0, 'Error should mention "indexed", got: $err');
		Assert.isTrue(err.indexOf("item") >= 0, 'Error should mention slot name "item", got: $err');
	}

	@Test
	public function testErrorSlotNonIndexedAccessedWithIndex():Void {
		final result = buildFromSource("
			#test programmable() {
				#mySlot slot {
					bitmap(generated(color(10, 10, #555))): 0, 0
				}
			}
		", "test");
		Assert.notNull(result);
		final err = expectError(() -> result.getSlot("mySlot", 0));
		Assert.notNull(err, "Should throw when accessing non-indexed slot with index");
		Assert.isTrue(err.indexOf("not indexed") >= 0, 'Error should mention "not indexed", got: $err');
	}

	@Test
	public function testErrorSlotIndexOutOfBounds():Void {
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, step(2, dx: 20)) {
					#item[$i] slot {
						bitmap(generated(color(10, 10, #555))): 0, 0
					}
				}
			}
		", "test");
		Assert.notNull(result);
		// Valid indices are 0 and 1; index 99 should not exist
		final err = expectError(() -> result.getSlot("item", 99));
		Assert.notNull(err, "Should throw for out-of-bounds slot index");
		Assert.isTrue(err.indexOf("item") >= 0, 'Error should mention slot name, got: $err');
	}

	@Test
	public function testErrorSetParameterWithoutIncrementalMode():Void {
		final result = buildFromSource("
			#test programmable(x:uint=10) {
				bitmap(generated(color($x, $x, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result);
		final err = expectError(() -> result.setParameter("x", 20));
		Assert.notNull(err, "Should throw when setParameter called without incremental mode");
		Assert.isTrue(err.indexOf("incremental") >= 0, 'Error should mention "incremental", got: $err');
	}

	@Test
	public function testErrorBeginUpdateWithoutIncrementalMode():Void {
		final result = buildFromSource("
			#test programmable(x:uint=10) {
				bitmap(generated(color($x, $x, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result);
		final err = expectError(() -> result.beginUpdate());
		Assert.notNull(err, "Should throw when beginUpdate called without incremental mode");
		Assert.isTrue(err.indexOf("incremental") >= 0, 'Error should mention "incremental", got: $err');
	}

	@Test
	public function testErrorEndUpdateWithoutIncrementalMode():Void {
		final result = buildFromSource("
			#test programmable(x:uint=10) {
				bitmap(generated(color($x, $x, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result);
		final err = expectError(() -> result.endUpdate());
		Assert.notNull(err, "Should throw when endUpdate called without incremental mode");
		Assert.isTrue(err.indexOf("incremental") >= 0, 'Error should mention "incremental", got: $err');
	}

	@Test
	public function testErrorGetDynamicRefNotFound():Void {
		final result = buildFromSource("
			#inner programmable() {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
			#test programmable() {
				dynamicRef($inner): 0, 0
			}
		", "test");
		Assert.notNull(result);
		final err = expectError(() -> result.getDynamicRef("nonexistent"));
		Assert.notNull(err, "Should throw for nonexistent dynamic ref");
		Assert.isTrue(err.indexOf("nonexistent") >= 0, 'Error should mention "nonexistent", got: $err');
	}

	@Test
	public function testErrorGetUpdatableNotFound():Void {
		final result = buildFromSource("
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result);
		final err = expectError(() -> result.getUpdatable("nonexistent"));
		Assert.notNull(err, "Should throw for nonexistent updatable name");
		Assert.isTrue(err.indexOf("nonexistent") >= 0, 'Error should mention "nonexistent", got: $err');
	}

	@Test
	public function testErrorFinalShadowsParam():Void {
		final err = expectError(() -> buildFromSource("
			#test programmable(x:uint=10) {
				@final x = 20
				bitmap(generated(color($x, $x, #f00))): 0, 0
			}
		", "test"));
		Assert.notNull(err, "Should throw when @final shadows a parameter");
		Assert.isTrue(err.indexOf("shadows") >= 0, 'Error should mention "shadows", got: $err');
	}

	@Test
	public function testErrorUnknownParamListsAvailable():Void {
		var err:String = null;
		try {
			buildFromSource("
				#test programmable(width:uint=10, height:uint=20, color:string=\"red\") {
					bitmap(generated(color($width, $height, #f00))): 0, 0
				}
			", "test", ["typo" => 42]);
		} catch (e:Dynamic) {
			err = Std.string(e);
		}
		Assert.notNull(err, "Should throw for unknown param");
		Assert.isTrue(err.indexOf("typo") >= 0, 'Error should mention "typo", got: $err');
		Assert.isTrue(err.indexOf("width") >= 0, 'Error should list available param "width", got: $err');
		Assert.isTrue(err.indexOf("height") >= 0, 'Error should list available param "height", got: $err');
	}

	@Test
	public function testErrorNoSlotsInResult():Void {
		final result = buildFromSource("
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result);
		final err = expectError(() -> result.getSlot("anything"));
		Assert.notNull(err, "Should throw when no slots exist");
		Assert.isTrue(err.indexOf("No slots") >= 0 || err.indexOf("not found") >= 0,
			'Error should indicate no slots, got: $err');
	}

	@Test
	public function testErrorNoDynamicRefsInResult():Void {
		final result = buildFromSource("
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result);
		final err = expectError(() -> result.getDynamicRef("anything"));
		Assert.notNull(err, "Should throw when no dynamic refs exist");
		Assert.isTrue(err.indexOf("dynamic") >= 0 || err.indexOf("Dynamic") >= 0 || err.indexOf("ref") >= 0 || err.indexOf("not found") >= 0,
			'Error should mention dynamic ref or not found, got: $err');
	}

	@Test
	public function testErrorSpacerOutsideFlow():Void {
		final err = expectError(() -> buildFromSource("
			#test programmable() {
				spacer(10, 10): 0, 0
			}
		", "test"));
		Assert.notNull(err, "Should throw when spacer used outside flow");
		Assert.isTrue(err.indexOf("spacer") >= 0, 'Error should mention "spacer", got: $err');
		Assert.isTrue(err.indexOf("flow") >= 0, 'Error should mention "flow", got: $err');
	}

	// ==================== Rich text: markup conversion and HtmlText ====================

	@Test
	public function testRichTextStylesCreatesHtmlText():Void {
		final result = buildFromSource("
			#test programmable() {
				richText(dd, \"Deal [damage]50[/] damage\", white, left, 200,
					styles: {damage: color(#FF0000)}): 0, 0
			}
		", "test");
		Assert.notNull(result);
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		Assert.isTrue(Std.isOfType(texts[0], h2d.HtmlText), "Should be HtmlText when styles defined");
	}

	@Test
	public function testRichTextMarkupConverted():Void {
		final result = buildFromSource("
			#test programmable() {
				richText(dd, \"Deal [damage]50[/] damage\", white, left, 200,
					styles: {damage: color(#FF0000)}): 0, 0
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		final ht:h2d.HtmlText = cast texts[0];
		Assert.isTrue(ht.text.indexOf("<damage>") >= 0, 'HTML should contain <damage>, got: ${ht.text}');
		Assert.isTrue(ht.text.indexOf("</damage>") >= 0, 'HTML should contain </damage>, got: ${ht.text}');
	}

	@Test
	public function testRichTextColorFunctionStyle():Void {
		final result = buildFromSource("
			#test programmable() {
				richText(dd, \"[warn]red[/] text\", white, left, 200,
					styles: {warn: color(#FF0000)}): 0, 0
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		final ht:h2d.HtmlText = cast texts[0];
		Assert.isTrue(ht.text.indexOf("<warn>") >= 0, 'HTML should contain <warn>, got: ${ht.text}');
		Assert.isTrue(ht.text.indexOf("</warn>") >= 0, 'HTML should contain </warn>, got: ${ht.text}');
	}

	@Test
	public function testRichTextFontFunctionStyle():Void {
		final result = buildFromSource("
			#test programmable() {
				richText(dd, \"normal [bold]switched[/] end\", white, left, 200,
					styles: {bold: font(\"dd\")}): 0, 0
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		final ht:h2d.HtmlText = cast texts[0];
		Assert.isTrue(ht.text.indexOf("<_s_bold>") >= 0, 'HTML should contain <_s_bold> (escaped reserved tag), got: ${ht.text}');
	}

	@Test
	public function testRichTextImageMarkupConverted():Void {
		final result = buildFromSource("
			#test programmable() {
				richText(dd, \"Cost [img:coin] gold\", white, left, 200,
					images: {coin: generated(color(14, 14, #FFD700))}): 0, 0
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		final ht:h2d.HtmlText = cast texts[0];
		Assert.isTrue(ht.text.indexOf("<img src=") >= 0, 'HTML should contain img src, got: ${ht.text}');
	}

	@Test
	public function testRichTextAlignMarkupConverted():Void {
		final result = buildFromSource("
			#test programmable() {
				richText(dd, \"left\\n[align:center]center[/]\", white, left, 200): 0, 0
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		final ht:h2d.HtmlText = cast texts[0];
		Assert.isTrue(ht.text.indexOf("<p align=") >= 0, 'HTML should contain p align, got: ${ht.text}');
		Assert.isTrue(ht.text.indexOf("</p>") >= 0, 'HTML should contain </p>, got: ${ht.text}');
	}

	@Test
	public function testRichTextLinkMarkupConverted():Void {
		final result = buildFromSource("
			#test programmable() {
				richText(dd, \"[link:shop]click[/]\", white, left, 200): 0, 0
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		final ht:h2d.HtmlText = cast texts[0];
		Assert.isTrue(ht.text.indexOf("<a href=") >= 0, 'HTML should contain a href, got: ${ht.text}');
		Assert.isTrue(ht.text.indexOf("</a>") >= 0, 'HTML should contain </a>, got: ${ht.text}');
	}

	@Test
	public function testTextCreatesPlainText():Void {
		final result = buildFromSource("
			#test programmable() {
				text(dd, \"plain text no markup\", white, left, 200): 0, 0
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		Assert.isFalse(Std.isOfType(texts[0], h2d.HtmlText), "text() should always create plain h2d.Text");
	}

	@Test
	public function testRichTextCondenseWhiteCreatesHtmlText():Void {
		final result = buildFromSource("
			#test programmable() {
				richText(dd, \"spaces   here\", white, left, 200, condenseWhite: true): 0, 0
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		Assert.isTrue(Std.isOfType(texts[0], h2d.HtmlText), "condenseWhite should create HtmlText");
	}

	@Test
	public function testRichTextNestingConverted():Void {
		final result = buildFromSource("
			#test programmable() {
				richText(dd, \"[damage]crit [highlight]50[/] dmg[/]\", white, left, 200,
					styles: {damage: color(#FF0000), highlight: color(yellow)}): 0, 0
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		final ht:h2d.HtmlText = cast texts[0];
		Assert.isTrue(ht.text.indexOf("<damage>") >= 0, 'Should have <damage> tag');
		Assert.isTrue(ht.text.indexOf("<highlight>") >= 0, 'Should have nested <highlight> tag');
		Assert.isTrue(ht.text.indexOf("</highlight>") >= 0, 'Should have </highlight> closing');
		Assert.isTrue(ht.text.indexOf("</damage>") >= 0, 'Should have </damage> closing');
	}

	@Test
	public function testRichTextColorOnlyStyle():Void {
		final result = buildFromSource("
			#test programmable() {
				richText(dd, \"[fire]flames[/]\", white, left, 200,
					styles: {fire: color(red)}): 0, 0
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		Assert.isTrue(Std.isOfType(texts[0], h2d.HtmlText), "Named color style should create HtmlText");
	}

	@Test
	public function testRichTextFontOnlyStyle():Void {
		final result = buildFromSource("
			#test programmable() {
				richText(dd, \"[em]emphasis[/]\", white, left, 200,
					styles: {em: font(\"dd\")}): 0, 0
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		Assert.isTrue(Std.isOfType(texts[0], h2d.HtmlText), "Font-only style should create HtmlText");
	}

	@Test
	public function testRichTextMarkupWithInterpolation():Void {
		// Key test: [markup] and ${param} interpolation combined in single-quoted string
		final params = new Map<String, Dynamic>();
		params.set("dmg", 75);
		final result = buildFromSource("
			#test programmable(dmg:int=50) {
				richText(dd, '[damage]${dmg}[/] damage', white, left, 200,
					styles: {damage: color(#FF0000)}): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		final ht:h2d.HtmlText = cast texts[0];
		Assert.isTrue(ht.text.indexOf("<damage>") >= 0, 'HTML should contain <damage>, got: ${ht.text}');
		Assert.isTrue(ht.text.indexOf("75") >= 0, 'HTML should contain interpolated value 75, got: ${ht.text}');
		Assert.isTrue(ht.text.indexOf("</damage>") >= 0, 'HTML should contain </damage>, got: ${ht.text}');
	}

	@Test
	public function testRichTextDynamicStyleColor():Void {
		// Dynamic style color via $param reference with incremental update
		final params = new Map<String, Dynamic>();
		params.set("hlColor", 0xFFFF0000); // red
		final result = buildFromSource("
			#test programmable(hlColor:color=blue) {
				richText(dd, \"[hl]highlighted[/]\", white, left, 200,
					styles: {hl: color($hlColor)}): 0, 0
			}
		", "test", params, Incremental);
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		Assert.isTrue(Std.isOfType(texts[0], h2d.HtmlText), "Dynamic style color should create HtmlText");

		// Verify setParameter updates without error and HtmlText still exists
		result.setParameter("hlColor", 0xFF00FF00); // green
		final textsAfter = findAllTextDescendants(result.object);
		Assert.equals(1, textsAfter.length);
		Assert.isTrue(Std.isOfType(textsAfter[0], h2d.HtmlText), "Should still be HtmlText after color update");
	}

	@Test
	public function testRichTextEscapeBracket():Void {
		// [[ should produce literal [ in output via TextMarkupConverter
		final result = buildFromSource("
			#test programmable() {
				richText(dd, \"use [[tag] for markup\", white, left, 200): 0, 0
			}
		", "test");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		// richText always creates HtmlText; [[ converts to literal [
		Assert.isTrue(Std.isOfType(texts[0], h2d.HtmlText), "richText should always create HtmlText");
		Assert.isTrue(texts[0].text.indexOf("[") >= 0, 'Text should contain literal [, got: ${texts[0].text}');
	}

	@Test
	public function testRichTextMarkupWithIntParamInterpolation():Void {
		// Single-quoted manim string: [markup] + ${param} interpolation combined
		// dmg is int param — ${dmg} should interpolate to "75" inside the markup
		final params = new Map<String, Dynamic>();
		params.set("dmg", 75);
		final result = buildFromSource("
			#test programmable(dmg:int=50) {
				richText(dd, 'Dealt [dmgStyle]${dmg}[/] damage to [dragon]Dragon[/]', white, left, 540,
					styles: {dmgStyle: color(#FF0000), dragon: color(#FF8844)}): 0, 0
			}
		", "test", params);
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		Assert.isTrue(Std.isOfType(texts[0], h2d.HtmlText), "Should create HtmlText for markup");
		final ht:h2d.HtmlText = cast texts[0];
		// After TextMarkupConverter: [dmgStyle]75[/] → <dmgStyle>75</dmgStyle>, [dragon] → <dragon>
		Assert.isTrue(ht.text.indexOf("75") >= 0, 'Should contain interpolated int 75, got: ${ht.text}');
		Assert.isTrue(ht.text.indexOf("<dmgStyle>") >= 0, 'Should contain <dmgStyle> tag, got: ${ht.text}');
		Assert.isTrue(ht.text.indexOf("</dmgStyle>") >= 0, 'Should contain </dmgStyle> tag, got: ${ht.text}');
		Assert.isTrue(ht.text.indexOf("Dragon") >= 0, 'Should contain Dragon, got: ${ht.text}');
	}

	// ==================== Multi-value match @(param=>[v1,v2]) ====================

	@Test
	public function testMultiValueMatchFirst():Void {
		final params = new Map<String, Dynamic>();
		params.set("rarity", "rare");
		final result = buildFromSource("
			#test programmable(rarity:[common,rare,epic,legendary]=common) {
				@(rarity=>[rare, epic]) bitmap(generated(color(20, 20, #ff0))): 0, 0
				@(rarity=>legendary) bitmap(generated(color(30, 30, #f0f))): 0, 0
				@default bitmap(generated(color(10, 10, #fff))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testMultiValueMatchSecond():Void {
		final params = new Map<String, Dynamic>();
		params.set("rarity", "epic");
		final result = buildFromSource("
			#test programmable(rarity:[common,rare,epic,legendary]=common) {
				@(rarity=>[rare, epic]) bitmap(generated(color(20, 20, #ff0))): 0, 0
				@(rarity=>legendary) bitmap(generated(color(30, 30, #f0f))): 0, 0
				@default bitmap(generated(color(10, 10, #fff))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testMultiValueMatchNoMatch():Void {
		final params = new Map<String, Dynamic>();
		params.set("rarity", "common");
		final result = buildFromSource("
			#test programmable(rarity:[common,rare,epic,legendary]=common) {
				@(rarity=>[rare, epic]) bitmap(generated(color(20, 20, #ff0))): 0, 0
				@(rarity=>legendary) bitmap(generated(color(30, 30, #f0f))): 0, 0
				@default bitmap(generated(color(10, 10, #fff))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testMultiValueMatchLegendary():Void {
		final params = new Map<String, Dynamic>();
		params.set("rarity", "legendary");
		final result = buildFromSource("
			#test programmable(rarity:[common,rare,epic,legendary]=common) {
				@(rarity=>[rare, epic]) bitmap(generated(color(20, 20, #ff0))): 0, 0
				@(rarity=>legendary) bitmap(generated(color(30, 30, #f0f))): 0, 0
				@default bitmap(generated(color(10, 10, #fff))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
	}

	// ==================== Bit flag conditionals @(param => bit[N]) ====================

	@Test
	public function testBitFlagBit0Set():Void {
		// flags=5 (binary 101) → bit[0]=1 set, bit[1]=0 not set, bit[2]=1 set
		final params = new Map<String, Dynamic>();
		params.set("flags", 5);
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[0]) bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testBitFlagBit1NotSet():Void {
		// flags=5 (binary 101) → bit[1] not set
		final params = new Map<String, Dynamic>();
		params.set("flags", 5);
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[1]) bitmap(generated(color(20, 20, #0f0))): 0, 0
				@default bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testBitFlagBit2Set():Void {
		// flags=5 (binary 101) → bit[2] set
		final params = new Map<String, Dynamic>();
		params.set("flags", 5);
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[2]) bitmap(generated(color(30, 30, #00f))): 0, 0
				@default bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testBitFlagZero():Void {
		// flags=0 → no bits set
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[0]) bitmap(generated(color(20, 20, #0f0))): 0, 0
				@default bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testBitFlagMultipleBitsShown():Void {
		// flags=7 (binary 111) → bit[0], bit[1], bit[2] all set; all 3 bitmaps should be visible
		final params = new Map<String, Dynamic>();
		params.set("flags", 7);
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[0]) bitmap(generated(color(10, 10, #f00))): 0, 0
				@(flags => bit[1]) bitmap(generated(color(20, 20, #0f0))): 10, 0
				@(flags => bit[2]) bitmap(generated(color(30, 30, #00f))): 20, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(3, bitmaps.length);
	}

	// ==================== .offset() coordinate suffix ====================

	@Test
	public function testOffsetOnLayoutPosition():Void {
		final result = buildFromSource("
			layouts {
				#base point: 100, 200
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): layout(base).offset(5, 10)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.floatEquals(105, bitmaps[0].x);
		Assert.floatEquals(210, bitmaps[0].y);
	}

	@Test
	public function testOffsetOnGridPos():Void {
		final result = buildFromSource("
			#test programmable() {
				grid: 32, 32
				bitmap(generated(color(10, 10, #f00))): " + "$" + "grid.pos(1, 2).offset(3, 4)
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		// grid.pos(1,2) = (32, 64), offset (3,4) = (35, 68)
		Assert.floatEquals(35, bitmaps[0].x);
		Assert.floatEquals(68, bitmaps[0].y);
	}

	@Test
	public function testOffsetWithParamReference():Void {
		final params = new Map<String, Dynamic>();
		params.set("ox", 15);
		params.set("oy", 25);
		final result = buildFromSource("
			layouts {
				#base point: 50, 50
			}
			#test programmable(ox:int=0, oy:int=0) {
				bitmap(generated(color(10, 10, #f00))): layout(base).offset(" + "$" + "ox, " + "$" + "oy)
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.floatEquals(65, bitmaps[0].x);
		Assert.floatEquals(75, bitmaps[0].y);
	}

	// ==================== Animated path event emissions ====================

	@Test
	public function testAnimatedPathPathEndEvent():Void {
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
		final ap = builder.createAnimatedPath("test");

		var events:Array<String> = [];
		ap.onEvent = function(name:String, state:bh.paths.AnimatedPath.AnimatedPathState) {
			events.push(name);
		};

		// Advance past the end
		ap.update(1.1);
		Assert.isTrue(events.indexOf("pathStart") >= 0, "Should fire pathStart");
		Assert.isTrue(events.indexOf("pathEnd") >= 0, "Should fire pathEnd");
	}

	@Test
	public function testAnimatedPathCycleEvents():Void {
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

		var events:Array<String> = [];
		ap.onEvent = function(name:String, state:bh.paths.AnimatedPath.AnimatedPathState) {
			events.push(name);
		};

		// Advance past first cycle into second
		ap.update(1.5);
		Assert.isTrue(events.indexOf("pathStart") >= 0, "Should fire pathStart");
		Assert.isTrue(events.indexOf("cycleEnd") >= 0, "Should fire cycleEnd at end of first cycle");
		Assert.isTrue(events.indexOf("cycleStart") >= 0, "Should fire cycleStart at beginning of second cycle");
		// looping path should NOT fire pathEnd
		Assert.isTrue(events.indexOf("pathEnd") < 0, "Looping path should not fire pathEnd");
	}

	@Test
	public function testAnimatedPathCustomAndBuiltinEventOrder():Void {
		final builder = builderFromSource("
			paths {
				#straight path { lineTo(100, 0) }
			}
			#test animatedPath {
				path: straight
				type: time
				duration: 1.0
				0.0: event(\"launch\")
				0.5: event(\"halfway\")
				1.0: event(\"arrived\")
			}
		");
		final ap = builder.createAnimatedPath("test");

		var events:Array<String> = [];
		ap.onEvent = function(name:String, state:bh.paths.AnimatedPath.AnimatedPathState) {
			events.push(name);
		};

		// Run to completion
		ap.update(1.1);
		// pathStart should come before custom events
		Assert.isTrue(events.indexOf("pathStart") < events.indexOf("launch"),
			'pathStart should fire before launch, order: $events');
		Assert.isTrue(events.indexOf("launch") < events.indexOf("halfway"),
			'launch should fire before halfway, order: $events');
		Assert.isTrue(events.indexOf("halfway") < events.indexOf("arrived"),
			'halfway should fire before arrived, order: $events');
		Assert.isTrue(events.indexOf("pathEnd") >= 0, "Should fire pathEnd");
	}

	@Test
	public function testAnimatedPathEventState():Void {
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

		var midRate:Float = -1;
		ap.onEvent = function(name:String, state:bh.paths.AnimatedPath.AnimatedPathState) {
			if (name == "mid") {
				midRate = state.rate;
			}
		};

		ap.update(0.6);
		Assert.floatEquals(0.5, midRate, "Event state should have rate=0.5 at mid event");
	}
}
