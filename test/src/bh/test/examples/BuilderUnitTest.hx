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
import bh.test.BuilderTestBase.parseExpectingSuccess;
import bh.test.BuilderTestBase.parseExpectingError;
import bh.multianim.MultiAnimParser.SettingValue;
import bh.multianim.MultiAnimParser.CustomFilterArgType;
import bh.base.FilterManager;
import bh.base.MAObject;
import bh.base.MAObject.MultiAnimObjectData;
import bh.ui.UIElement.TileHelper;
import bh.base.ColorUtils;

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

	// ==================== Data block enum tests ====================

	@Test
	public function testDataEnumScalar():Void {
		final data:Dynamic = getDataFromSource("
			#config data {
				#rarity enum(common, uncommon, rare)
				defaultRarity: rarity common
			}
		", "config");
		Assert.equals("common", data.defaultRarity);
	}

	@Test
	public function testDataEnumArray():Void {
		final data:Dynamic = getDataFromSource("
			#config data {
				#element enum(fire, water, earth, air)
				elements: element[] [fire, water, earth]
			}
		", "config");
		final arr:Array<Dynamic> = data.elements;
		Assert.equals(3, arr.length);
		Assert.equals("fire", arr[0]);
		Assert.equals("water", arr[1]);
		Assert.equals("earth", arr[2]);
	}

	@Test
	public function testDataEnumInRecord():Void {
		final data:Dynamic = getDataFromSource("
			#config data {
				#rarity enum(common, uncommon, rare, epic)
				#item record(name: string, rarity: rarity)
				sword: item { name: \"Sword\", rarity: rare }
			}
		", "config");
		Assert.equals("Sword", data.sword.name);
		Assert.equals("rare", data.sword.rarity);
	}

	@Test
	public function testDataEnumOptionalInRecord():Void {
		final data:Dynamic = getDataFromSource("
			#config data {
				#element enum(fire, water, earth, air)
				#item record(name: string, ?element: element)
				shield: item { name: \"Shield\" }
				staff: item { name: \"Staff\", element: air }
			}
		", "config");
		Assert.equals("Shield", data.shield.name);
		Assert.isNull(data.shield.element);
		Assert.equals("Staff", data.staff.name);
		Assert.equals("air", data.staff.element);
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
	public function testIncrementalRepeatableChildConditions():Void {
		// Reproduction case from issue: conditions inside repeatable compare $i against a parameter.
		// Changing the parameter via setParameter should re-evaluate those conditions.
		final params = new Map<String, Dynamic>();
		params.set("level", 0);
		params.set("max", 6);
		final result = buildFromSource("
			#test programmable(level:int=0, max:int=6) {
				repeatable($i, step($max, dx: 14)) {
					@($i < $level) bitmap(generated(color(12, 3, #55CC88))): 0, 0
					@($i >= $level) bitmap(generated(color(12, 3, #556677))): 0, 0
				}
			}
		", "test", params, Incremental);

		// level=0: all 6 should be dim (12x3 #556677)
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(6, bitmaps.length);
		// All should be dim — $i >= 0 is always true
		for (b in bitmaps)
			Assert.equals(3, Std.int(b.tile.height));

		// Set level=3: first 3 should be green, last 3 dim
		result.setParameter("level", 3);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(6, bitmaps.length);

		// Set level=6: all 6 should be green
		result.setParameter("level", 6);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(6, bitmaps.length);
	}

	@Test
	public function testIncrementalRepeatableConstantCountChildConditions():Void {
		// Variant: repeat count is constant (no param ref), but children have param conditions.
		final result = buildFromSource("
			#test programmable(level:int=0) {
				repeatable($i, step(4, dx: 14)) {
					@($i < $level) bitmap(generated(color(10, 10, #00ff00))): 0, 0
					@($i >= $level) bitmap(generated(color(20, 10, #ff0000))): 0, 0
				}
			}
		", "test", null, Incremental);

		// level=0: all 4 should be red (20px wide)
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(4, bitmaps.length);
		for (b in bitmaps)
			Assert.equals(20, Std.int(b.tile.width));

		// level=2: first 2 green (10px), last 2 red (20px)
		result.setParameter("level", 2);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(4, bitmaps.length);
		var greenCount = 0;
		var redCount = 0;
		for (b in bitmaps) {
			if (Std.int(b.tile.width) == 10) greenCount++;
			else if (Std.int(b.tile.width) == 20) redCount++;
		}
		Assert.equals(2, greenCount);
		Assert.equals(2, redCount);

		// level=4: all green (10px)
		result.setParameter("level", 4);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(4, bitmaps.length);
		for (b in bitmaps)
			Assert.equals(10, Std.int(b.tile.width));
	}

	@Test
	public function testIncrementalRepeatableRangeParamRef():Void {
		// Range syntax with $param references: @($i => $from..$to)
		final result = buildFromSource("
			#test programmable(from:int=1, to:int=3) {
				repeatable($i, step(5, dx: 14)) {
					@($i => $from..$to) bitmap(generated(color(10, 10, #00ff00))): 0, 0
					@else bitmap(generated(color(20, 10, #ff0000))): 0, 0
				}
			}
		", "test", null, Incremental);

		// from=1, to=3: indices 1,2,3 green (10px), indices 0,4 red (20px)
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(5, bitmaps.length);
		var greenCount = 0;
		for (b in bitmaps)
			if (Std.int(b.tile.width) == 10) greenCount++;
		Assert.equals(3, greenCount);

		// Change to from=0, to=4: all green
		result.setParameter("from", 0);
		result.setParameter("to", 4);
		bitmaps = findVisibleBitmapDescendants(result.object);
		greenCount = 0;
		for (b in bitmaps)
			if (Std.int(b.tile.width) == 10) greenCount++;
		Assert.equals(5, greenCount);

		// Change to from=2, to=2: only index 2 green
		result.setParameter("from", 2);
		result.setParameter("to", 2);
		bitmaps = findVisibleBitmapDescendants(result.object);
		greenCount = 0;
		for (b in bitmaps)
			if (Std.int(b.tile.width) == 10) greenCount++;
		Assert.equals(1, greenCount);
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

	// ==================== Incremental bitmap tile expression tracking ====================

	@Test
	public function testIncrementalBitmapColorSetParameter():Void {
		final result = buildFromSource("
			#test programmable(bg:color=#FF0000) {
				bitmap(generated(color(10, 10, $bg))): 0, 0
			}
		", "test", null, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);

		// setParameter should update the generated color tile
		result.setParameter("bg", 0x0000FF);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
	}

	@Test
	public function testIncrementalBitmapSizeSetParameter():Void {
		final result = buildFromSource("
			#test programmable(w:uint=10) {
				bitmap(generated(color($w, 10, #FF0000))): 0, 0
			}
		", "test", null, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// setParameter should update tile dimensions
		result.setParameter("w", 20);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalBitmapGeneratedCrossSetParameter():Void {
		final result = buildFromSource("
			#test programmable(w:uint=15) {
				bitmap(generated(cross($w, 10, #FF0000, 1))): 0, 0
			}
		", "test", null, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);

		// setParameter should re-resolve through loadTileSource
		result.setParameter("w", 25);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
	}

	@Test
	public function testIncrementalBitmapTileParamSetParameter():Void {
		final params = new Map<String, Dynamic>();
		params.set("icon", TileHelper.generatedRectColor(10, 10, 0xFF0000));
		final result = buildFromSource("
			#test programmable(icon:tile) {
				bitmap($icon): 0, 0
			}
		", "test", params, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// setParameter with a different tile — should update the bitmap
		result.setParameter("icon", TileHelper.generatedRectColor(20, 15, 0x0000FF));
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
		Assert.equals(15, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testIncrementalBitmapTileParamWithRawTile():Void {
		final params = new Map<String, Dynamic>();
		params.set("icon", TileHelper.generatedRectColor(10, 10, 0xFF0000));
		final result = buildFromSource("
			#test programmable(icon:tile) {
				bitmap($icon): 0, 0
			}
		", "test", params, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// setParameter with a raw h2d.Tile — should also work
		result.setParameter("icon", h2d.Tile.fromColor(0x00FF00, 30, 25));
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
		Assert.equals(25, Std.int(bitmaps[0].tile.height));
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
				repeatable($i, layout(\"testLayout\")) {
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
				repeatable($i, layout(\"testLayout\")) {
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

	// Two @(cond) apply blocks touch the same property on the same parent.
	// Per-entry save/restore can't handle overlapping mutations — each entry's
	// saved value depends on when it was applied, not on what the current
	// baseline is. Expected behavior: unapplying an outer while an inner is
	// still matched should leave the inner's value on the parent.
	@Test
	public function testIncrementalApplyAlphaInterleavedSameProperty():Void {
		final result = buildFromSource("
			#test programmable(a:uint=0, b:uint=0) {
				bitmap(generated(color(50, 50, #ff0000))): 0, 0
				@(a => 1) apply {
					alpha: 0.5
				}
				@(b => 1) apply {
					alpha: 0.3
				}
			}
		", "test", null, Incremental);
		Assert.floatEquals(1.0, result.object.alpha, "baseline");

		result.setParameter("a", 1);
		Assert.floatEquals(0.5, result.object.alpha, "after a=1");

		result.setParameter("b", 1);
		Assert.floatEquals(0.3, result.object.alpha, "after b=1 (later apply wins)");

		// Unapply outer while inner is still matched — should reapply b=0.3.
		result.setParameter("a", 0);
		Assert.floatEquals(0.3, result.object.alpha, "after a=0 with b=1 still matched");

		result.setParameter("b", 0);
		Assert.floatEquals(1.0, result.object.alpha, "back to baseline");
	}

	@Test
	public function testIncrementalApplyScaleInterleavedSameProperty():Void {
		final result = buildFromSource("
			#test programmable(a:uint=0, b:uint=0) {
				bitmap(generated(color(50, 50, #ff0000))): 0, 0
				@(a => 1) apply {
					scale: 0.5
				}
				@(b => 1) apply {
					scale: 0.25
				}
			}
		", "test", null, Incremental);
		Assert.floatEquals(1.0, result.object.scaleX, "baseline scaleX");
		Assert.floatEquals(1.0, result.object.scaleY, "baseline scaleY");

		result.setParameter("a", 1);
		result.setParameter("b", 1);
		Assert.floatEquals(0.25, result.object.scaleX, "both matched → later wins");

		result.setParameter("a", 0);
		Assert.floatEquals(0.25, result.object.scaleX, "a=0, b=1 → b's scale");

		result.setParameter("b", 0);
		Assert.floatEquals(1.0, result.object.scaleX, "back to baseline");
	}

	@Test
	public function testIncrementalApplyAlphaInterleavedStartHidden():Void {
		// Start with both conditions false — entries are tracked with null saved values.
		// Cycle through a=true, b=true, a=false, b=false and verify parent returns to baseline.
		final result = buildFromSource("
			#test programmable(a:uint=0, b:uint=0) {
				bitmap(generated(color(50, 50, #ff0000))): 0, 0
				@(a => 1) apply {
					alpha: 0.5
				}
				@(b => 1) apply {
					alpha: 0.3
				}
			}
		", "test", null, Incremental);
		Assert.floatEquals(1.0, result.object.alpha);

		// Full cycle
		result.setParameter("a", 1); Assert.floatEquals(0.5, result.object.alpha);
		result.setParameter("b", 1); Assert.floatEquals(0.3, result.object.alpha);
		result.setParameter("b", 0); Assert.floatEquals(0.5, result.object.alpha);
		result.setParameter("a", 0); Assert.floatEquals(1.0, result.object.alpha);

		// Second cycle — saved state must not have been corrupted.
		result.setParameter("a", 1); Assert.floatEquals(0.5, result.object.alpha);
		result.setParameter("a", 0); Assert.floatEquals(1.0, result.object.alpha);
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
		// hp=80 → green bar in graph, red bar not in graph
		// children: bg + sentinel_red + sentinel_green + green_bar = 4
		Assert.equals(4, result.object.numChildren);
		// green bar is the last child (after its sentinel)
		final greenBar = result.object.getChildAt(3);
		Assert.isTrue(greenBar.parent != null);

		// Change to hp=30 → red in graph, green removed
		result.setParameter("hp", 30);
		Assert.equals(4, result.object.numChildren); // bg + sentinel_red + red_bar + sentinel_green
		final redBar = result.object.getChildAt(2); // red_bar is after sentinel_red
		Assert.isTrue(redBar.parent != null);
		Assert.isNull(greenBar.parent);

		// Change to hp=70 → green in graph, red removed
		result.setParameter("hp", 70);
		Assert.equals(4, result.object.numChildren); // bg + sentinel_red + sentinel_green + green_bar
		Assert.isNull(redBar.parent);
		Assert.isTrue(greenBar.parent != null);
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
		// hp=80 → green pixels in graph, red not in graph
		// children: bg + sentinel_red + sentinel_green + green_pixels = 4
		Assert.equals(4, result.object.numChildren);
		final greenPixels = result.object.getChildAt(3);
		Assert.isTrue(greenPixels.parent != null);

		// Change to hp=30 → red in graph, green removed
		result.setParameter("hp", 30);
		Assert.equals(4, result.object.numChildren);
		final redPixels = result.object.getChildAt(2);
		Assert.isTrue(redPixels.parent != null);
		Assert.isNull(greenPixels.parent);
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
		// Non-visible conditional nodes are deferred (built on demand when condition matches).
		// This prevents expression evaluation errors (e.g. division by zero) for hidden nodes.
		final result = buildFromSource("
			#test programmable(status:[normal,hover]=normal) {
				@(status=>normal) graphics(rect(#0000ff, filled, 100, 50): 0, 0): 0, 0
				@(status=>hover) graphics(rect(#00ff00, filled, 100, 50): 0, 0): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		// children: sentinel_normal + normal_graphics + sentinel_hover = 3
		Assert.equals(3, result.object.numChildren);

		// Normal graphics should be in graph; hover is deferred (not in graph)
		final normalChild = result.object.getChildAt(1); // after sentinel_normal
		Assert.isTrue(normalChild.parent != null, "Normal graphics should be in graph");

		final normalGfx = findGraphicsInTree(normalChild);
		Assert.notNull(normalGfx, "Normal should be a Graphics");
		Assert.isTrue(hasGraphicsContent(normalGfx), "Normal graphics should have drawn content");

		// Toggle to hover — deferred node materializes and is added to graph
		result.setParameter("status", "hover");
		Assert.isNull(normalChild.parent, "Normal should be removed from graph");
		// children: sentinel_normal + sentinel_hover + hover_graphics = 3
		Assert.equals(3, result.object.numChildren);
		final hoverChild = result.object.getChildAt(2); // after sentinel_hover
		Assert.isTrue(hoverChild.parent != null, "Hover should be in graph");

		// Hover content should be present after materialization
		final hoverGfx = findGraphicsInTree(hoverChild);
		Assert.notNull(hoverGfx, "Hover should have Graphics after materialization");
		Assert.isTrue(hasGraphicsContent(hoverGfx), "Hover graphics should have content after materialization");
	}

	@Test
	public function testIncrementalConditionalGraphicsReShowPreservesContent():Void {
		// h2d.Graphics clears draw commands in onRemove(). When a conditional element is
		// removed from the scene graph (condition false) and re-added (condition true again),
		// the Graphics content must be restored via refreshTrackedExpressionsFor().
		final result = buildFromSource("
			#test programmable(status:[normal,hover]=normal) {
				@(status=>normal) graphics(rect(#0000ff, filled, 100, 50): 0, 0): 0, 0
				@(status=>hover) graphics(rect(#00ff00, filled, 100, 50): 0, 0): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);

		// Initial: normal is in graph with content
		final normalChild = result.object.getChildAt(1);
		final normalGfx = findGraphicsInTree(normalChild);
		Assert.notNull(normalGfx, "Normal should have Graphics");
		Assert.isTrue(hasGraphicsContent(normalGfx), "Normal graphics should have content initially");

		// Toggle to hover — normal removed from graph (Graphics cleared by onRemove)
		result.setParameter("status", "hover");
		Assert.isNull(normalChild.parent, "Normal should be removed from graph");

		// Toggle back to normal — normal re-added, content must be restored
		result.setParameter("status", "normal");
		Assert.isTrue(normalChild.parent != null, "Normal should be back in graph");
		Assert.isTrue(hasGraphicsContent(normalGfx), "Normal graphics should have content after re-show");
	}

	@Test
	public function testIncrementalDefaultGraphicsHasContent():Void {
		// @default catch-all: only fires when NO conditional sibling matched.
		// Non-visible conditional nodes are deferred; content appears after materialization.
		final result = buildFromSource("
			#test programmable(status:[normal,hover,pressed]=normal) {
				@(status=>normal) graphics(rect(#ff0000, filled, 80, 40): 0, 0): 0, 0
				@(status=>hover) graphics(rect(#00ff00, filled, 80, 40): 0, 0): 0, 0
				@default graphics(rect(#0000ff, filled, 80, 40): 0, 0): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		// children: sentinel_normal + normal + sentinel_hover + sentinel_default = 4
		Assert.equals(4, result.object.numChildren);

		// Normal is in graph (after its sentinel); others are not in graph
		final normalChild = result.object.getChildAt(1); // after sentinel_normal
		Assert.isTrue(normalChild.parent != null, "Normal should be in graph");

		// Only visible node has content
		final normalGfx = findGraphicsInTree(normalChild);
		Assert.notNull(normalGfx, "Normal should have Graphics");
		Assert.isTrue(hasGraphicsContent(normalGfx), "Normal graphics should have content");

		// Switch to pressed (triggers @default — materializes it)
		result.setParameter("status", "pressed");
		Assert.isNull(normalChild.parent, "Normal should be removed from graph");
		// children: sentinel_normal + sentinel_hover + sentinel_default + default = 4
		Assert.equals(4, result.object.numChildren);
		final defaultChild = result.object.getChildAt(3); // after sentinel_default
		Assert.isTrue(defaultChild.parent != null, "@default should be in graph");
		final defaultGfx = findGraphicsInTree(defaultChild);
		Assert.notNull(defaultGfx, "@default should have Graphics after materialization");
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
		// children: sentinel_normal + normal + sentinel_else = 3
		Assert.equals(3, result.object.numChildren);

		final normalChild = result.object.getChildAt(1); // after sentinel_normal
		Assert.isTrue(normalChild.parent != null, "Normal should be in graph");

		// Normal should have graphics content
		final normalGfx = findGraphicsInTree(normalChild);
		Assert.notNull(normalGfx, "Normal should have Graphics");
		Assert.isTrue(hasGraphicsContent(normalGfx), "Normal graphics should have content");

		// Switch to hover (normal no longer matches, @else fires and materializes)
		result.setParameter("status", "hover");
		Assert.isNull(normalChild.parent, "Normal should be removed from graph");
		// children: sentinel_normal + sentinel_else + else_graphics = 3
		Assert.equals(3, result.object.numChildren);
		final elseChild = result.object.getChildAt(2); // after sentinel_else
		Assert.isTrue(elseChild.parent != null, "@else should be in graph");
		final elseGfx = findGraphicsInTree(elseChild);
		Assert.notNull(elseGfx, "@else should have Graphics after materialization");
		Assert.isTrue(hasGraphicsContent(elseGfx), "@else graphics should have content when visible");
	}

	@Test
	public function testIncrementalConditionalGraphicsWithDynamicContent():Void {
		// Conditional graphics where the content itself references a parameter.
		// Non-visible nodes are deferred; content built on materialization with current param values.
		final result = buildFromSource("
			#test programmable(status:[normal,hover]=normal, w:uint=100) {
				@(status=>normal) graphics(rect(#ff0000, filled, $w, 30): 0, 0): 0, 0
				@(status=>hover) graphics(rect(#00ff00, filled, $w, 30): 0, 0): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);

		// children: sentinel_normal + normal + sentinel_hover = 3
		final normalChild = result.object.getChildAt(1); // after sentinel_normal

		// Normal should have content; hover is deferred (not in graph)
		final normalGfx = findGraphicsInTree(normalChild);
		Assert.notNull(normalGfx, "Normal should have Graphics");
		Assert.isTrue(hasGraphicsContent(normalGfx), "Normal dynamic graphics should have content");

		// Change the width parameter — visible node updates, deferred node stays deferred
		result.setParameter("w", 50);
		Assert.isTrue(hasGraphicsContent(normalGfx), "Normal graphics should have content after param change");

		// Now toggle visibility — deferred node materializes with w=50
		result.setParameter("status", "hover");
		Assert.isNull(normalChild.parent, "Normal should be removed from graph");
		// children: sentinel_normal + sentinel_hover + hover = 3
		final hoverChild = result.object.getChildAt(2); // after sentinel_hover
		Assert.isTrue(hoverChild.parent != null, "Hover should be in graph");
		final hoverGfx = findGraphicsInTree(hoverChild);
		Assert.notNull(hoverGfx, "Hover should have Graphics after materialization");
		Assert.isTrue(hasGraphicsContent(hoverGfx), "Hover graphics should have content when made visible");
	}

	@Test
	public function testIncrementalConditionalDivisionByZeroDeferred():Void {
		// Division by zero in a conditional expression must not crash when the condition doesn't match.
		// In incremental mode, the node is deferred (not evaluated) when maxShield=0.
		final result = buildFromSource("
			#test programmable(maxShield:uint=0) {
				@(maxShield=>1..99) graphics(rect(#4477CC, filled, 36 * 20 / $maxShield, 8): 0, 0): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);

		// With maxShield=0, the conditional doesn't match — node is not in graph
		// children: sentinel only = 1
		Assert.equals(1, result.object.numChildren);

		// Set maxShield to a valid value — node materializes and is added to graph
		result.setParameter("maxShield", 50);
		Assert.equals(2, result.object.numChildren); // sentinel + graphics
		final child = result.object.getChildAt(1); // after sentinel
		Assert.isTrue(child.parent != null, "Should be in graph when maxShield=50");
		final gfx = findGraphicsInTree(child);
		Assert.notNull(gfx, "Should have Graphics after materialization");
		Assert.isTrue(hasGraphicsContent(gfx), "Graphics should have content");

		// Set back to 0 — node removed from graph, no crash
		result.setParameter("maxShield", 0);
		Assert.isNull(child.parent, "Should be removed from graph when maxShield=0");
		Assert.equals(1, result.object.numChildren); // sentinel only
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

	/** Recursively find an h2d.Graphics in the tree rooted at obj (depth-first). */
	static function findGraphicsInTree(obj:h2d.Object):Null<h2d.Graphics> {
		if (Std.isOfType(obj, h2d.Graphics))
			return cast obj;
		for (i in 0...obj.numChildren) {
			final found = findGraphicsInTree(obj.getChildAt(i));
			if (found != null) return found;
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
	public function testFlowConditionalPreservesPropsBuilder():Void {
		// Builder path: conditional element inside flow with @flow.halign should preserve
		// properties when removed and re-added to the scene graph.
		// Uses @if/@else so both elements are initially built (no deferred path).
		final result = buildFromSource("
			#test programmable(mode:[a,b]=a) {
				flow(layout: vertical, minWidth: 100, verticalSpacing: 2) {
					bitmap(generated(color(80, 10, #ff0000))): 0, 0
					@if(mode=>a) @flow.halign(right) bitmap(generated(color(40, 10, #00ff00))): 0, 0
					@else @flow.halign(middle) bitmap(generated(color(40, 10, #0000ff))): 0, 0
				}
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		final flow = Std.downcast(result.object.getChildAt(0), h2d.Flow);
		Assert.notNull(flow, "Root child should be a Flow");

		// Flow children: bg + sentinel_A + elementA + sentinel_else + [elseElement removed] = 4
		// elementA is at index 2 (after bg=0, sentinel_A=1)
		final elementA = flow.getChildAt(2);
		Assert.isTrue(elementA.parent != null, "Element A should be in graph initially");
		final propsA = flow.getProperties(elementA);
		Assert.equals(h2d.Flow.FlowAlign.Right, propsA.horizontalAlign);

		// Switch to mode=b — A removed, @else element re-added
		result.setParameter("mode", "b");
		Assert.isNull(elementA.parent, "Element A should be removed from graph");

		// @else element is after sentinel_else (index 3)
		final elementElse = flow.getChildAt(3);
		Assert.isTrue(elementElse.parent != null, "Else element should be in graph");
		final propsElse = flow.getProperties(elementElse);
		Assert.equals(h2d.Flow.FlowAlign.Middle, propsElse.horizontalAlign);

		// Switch back to mode=a — A re-added. Its halign=right should be preserved.
		result.setParameter("mode", "a");
		Assert.isTrue(elementA.parent != null, "Element A should be back in graph");
		Assert.isNull(elementElse.parent, "Else element should be removed");
		final propsARestored = flow.getProperties(elementA);
		Assert.equals(h2d.Flow.FlowAlign.Right, propsARestored.horizontalAlign);
	}

	@Test
	public function testFlowConditionalPreservesPropsCodegen():Void {
		// Codegen path: conditional elements inside flow with @flow.halign should preserve
		// properties when removed and re-added via _applyVisibility().
		final mp = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false));
		final instance = mp.flowConditional.create(bh.test.MultiProgrammable_FlowConditional.A);
		Assert.notNull(instance, "Codegen create should succeed");
		// Instance IS the h2d.Object root. First child is the Flow.
		final flow = Std.downcast(instance.getChildAt(0), h2d.Flow);
		Assert.notNull(flow, "Root child should be a Flow");

		// Flow children: bg + sentinel_if + elementA + sentinel_else + [elseElement removed] = 4
		final elementA = flow.getChildAt(2);
		Assert.isTrue(elementA.parent != null, "Element A should be in graph initially");
		final propsA = flow.getProperties(elementA);
		Assert.equals(h2d.Flow.FlowAlign.Right, propsA.horizontalAlign);

		// Switch to mode=b — A removed, @else element re-added
		instance.setMode(bh.test.MultiProgrammable_FlowConditional.B);
		Assert.isNull(elementA.parent, "Element A should be removed from graph");
		final elementElse = flow.getChildAt(3);
		Assert.isTrue(elementElse.parent != null, "Else element should be in graph");
		final propsElse = flow.getProperties(elementElse);
		Assert.equals(h2d.Flow.FlowAlign.Middle, propsElse.horizontalAlign);
		Assert.equals(5, propsElse.offsetX);

		// Switch back to mode=a — A re-added. Its halign=right should be preserved.
		instance.setMode(bh.test.MultiProgrammable_FlowConditional.A);
		Assert.isTrue(elementA.parent != null, "Element A should be back in graph");
		Assert.isNull(elementElse.parent, "Else element should be removed");
		final propsARestored = flow.getProperties(elementA);
		Assert.equals(h2d.Flow.FlowAlign.Right, propsARestored.horizontalAlign);
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
		params.set("hlColor", ColorUtils.rgb(0xFF0000)); // red
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
		result.setParameter("hlColor", ColorUtils.rgb(0x00FF00)); // green
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

	// ==================== Transition support ====================

	@Test
	public function testTransitionNoTweenManagerFallsBackToInstant():Void {
		final result = buildFromSource("
			#test programmable(status:[a,b]=a) {
				transition {
					status: crossfade(0.2)
				}
				@(status=>a) bitmap(generated(color(10, 10, #f00))): 0,0
				@(status=>b) bitmap(generated(color(10, 10, #0f0))): 0,0
			}
		", "test", ["status" => "a"], Incremental);
		Assert.notNull(result);
		// First child visible (status=a), second hidden
		final children = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, children.length);
		// Change parameter without TweenManager — should be instant
		result.setParameter("status", "b");
		final children2 = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, children2.length);
	}

	@Test
	public function testTransitionWithTweenManagerCreatesTween():Void {
		final tm = new bh.base.TweenManager();
		final builder = builderFromSource("
			#test programmable(status:[a,b]=a) {
				transition {
					status: fade(0.5)
				}
				@(status=>a) bitmap(generated(color(10, 10, #f00))): 0,0
				@(status=>b) bitmap(generated(color(10, 10, #0f0))): 0,0
			}
		");
		builder.tweenManager = tm;
		final result = builder.buildWithParameters("test", ["status" => "a"], null, null, true);
		Assert.notNull(result);
		// Initial: sentinel_a + bitmap_a + sentinel_b = 3 children
		final bitmapA = result.object.getChildAt(1); // bitmap_a after sentinel_a
		Assert.isTrue(bitmapA.parent != null, "A should be in graph initially");
		// Change parameter — should create tween instead of instant
		result.setParameter("status", "b");
		// During transition: both elements in graph (A fading out, B fading in)
		Assert.isTrue(tm.hasTweens(bitmapA),
			"TweenManager should have active tweens during transition");
	}

	@Test
	public function testTransitionInterruptionCancelsOldAndStartsNew():Void {
		final tm = new bh.base.TweenManager();
		final builder = builderFromSource("
			#test programmable(status:[a,b,c]=a) {
				transition {
					status: fade(0.5)
				}
				@(status=>a) bitmap(generated(color(10, 10, #ff0000))): 0,0
				@(status=>b) bitmap(generated(color(10, 10, #00ff00))): 10,0
				@(status=>c) bitmap(generated(color(10, 10, #0000ff))): 20,0
			}
		");
		builder.tweenManager = tm;
		final result = builder.buildWithParameters("test", ["status" => "a"], null, null, true);
		Assert.notNull(result);

		// Initial state: A in graph, B and C not in graph
		// children: sentinel_a + bitmap_a + sentinel_b + sentinel_c = 4
		final childA = result.object.getChildAt(1); // bitmap_a after sentinel_a
		Assert.isTrue(childA.parent != null, "A should be in graph initially");

		// Start transition to B
		result.setParameter("status", "b");
		// Transition should be active (A fading out, B fading in — both in graph)
		Assert.isTrue(tm.hasTweens(childA),
			"Should have active tweens after first parameter change");

		// Advance a bit (skip first dt + partial advance)
		tm.update(0.0); // consumed by skipFirstDt
		tm.update(0.1); // advance 0.1s into 0.5s fade

		// Interrupt: change to C before fade completes
		result.setParameter("status", "c");

		// Old tweens for A→B should be cancelled, new tweens for C should start
		// Advance past full duration to complete new transition
		tm.update(0.0); // consumed by skipFirstDt of new tweens
		tm.update(1.0); // advance well past 0.5s duration

		// Final state: only C should be in graph, A and B removed
		Assert.isNull(childA.parent, "A should not be in graph after interruption completes");
		// Find C — it should be the only bitmap in the graph now
		final visibleBitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, visibleBitmaps.length, "Only C should be visible after interruption");
	}

	@Test
	public function testTransitionCrossfadeSequentialTiming():Void {
		// Regression: crossfade(D) used to run a single one-sided alpha tween
		// over D so old + new states overlapped at ~0.5 alpha at the midpoint.
		// New behavior is sequential blend-through-zero — old fades fully to 0
		// over D, new waits at alpha 0 then fades from 0 to its target alpha
		// over another D, total wall-clock = 2 * D.
		final D = 0.4;
		final tm = new bh.base.TweenManager();
		final builder = builderFromSource('
			#test programmable(status:[a,b]=a) {
				transition {
					status: crossfade($D)
				}
				@(status=>a) bitmap(generated(color(10, 10, #ff0000))): 0,0
				@(status=>b) bitmap(generated(color(10, 10, #00ff00))): 0,0
			}
		');
		builder.tweenManager = tm;
		final result = builder.buildWithParameters("test", ["status" => "a"], null, null, true);
		Assert.notNull(result);

		// Initial: sentinel_a + wrapperA + sentinel_b = 3 children. wrapperA is
		// the immediate child whose alpha is tweened (NOT the inner h2d.Bitmap).
		final wrapperA = result.object.getChildAt(1);
		Assert.notNull(wrapperA.parent, "A wrapper should be in graph at start");
		Assert.floatEquals(1.0, wrapperA.alpha, 0.001);

		// Trigger crossfade — wrapperB gets inserted right after sentinel_b.
		result.setParameter("status", "b");
		final wrapperB = result.object.getChildAt(3);
		Assert.notNull(wrapperB, "B wrapper should be in graph during crossfade");

		Assert.isTrue(tm.hasTweens(wrapperA), "A must have an outgoing tween");
		Assert.isTrue(tm.hasTweens(wrapperB), "B must have an incoming tween");

		// First update consumed by skipFirstDt.
		tm.update(0.0);

		// Sample inside the FIRST half (t < D) — this is the diagnostic
		// difference between old and new behavior. With the old simultaneous
		// crossfade, B would already be fading in at t=0.7*D. With the new
		// sequential behavior B must still be completely invisible while A is
		// most of the way through its hide tween.
		tm.update(D * 0.7);
		Assert.isTrue(wrapperA.alpha < 0.5,
			'A should be well past half-faded at t=0.7*D, got ${wrapperA.alpha}');
		Assert.floatEquals(0.0, wrapperB.alpha, 0.001,
			'B must still be fully invisible during the first half, got ${wrapperB.alpha}');

		// Advance past 2*D so both tweens complete: A removed from graph,
		// B at its target alpha 1.0.
		tm.update(D * 1.4);
		Assert.floatEquals(1.0, wrapperB.alpha, 0.05, 'B alpha after 2*D expected ~1, got ${wrapperB.alpha}');
		Assert.isNull(wrapperA.parent, "A should be removed from graph after crossfade completes");
	}

	@Test
	public function testTransitionWithoutTransitionBlockIsInstant():Void {
		final tm = new bh.base.TweenManager();
		final builder = builderFromSource("
			#test programmable(status:[a,b]=a) {
				@(status=>a) bitmap(generated(color(10, 10, #f00))): 0,0
				@(status=>b) bitmap(generated(color(10, 10, #0f0))): 0,0
			}
		");
		builder.tweenManager = tm;
		final result = builder.buildWithParameters("test", ["status" => "a"], null, null, true);
		result.setParameter("status", "b");
		// No transition block means instant — no tweens on any child
		for (i in 0...result.object.numChildren) {
			Assert.isFalse(tm.hasTweens(result.object.getChildAt(i)), "No tweens expected without transition block");
		}
		// B should be in graph, A should not
		final visibleBitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, visibleBitmaps.length, "Only B bitmap should be in graph");
	}

	@Test
	public function testTransitionBatchedUpdatesScopedToParamRefs():Void {
		// Bug guard: findTransitionSpec() must pick the transition declared for the
		// param(s) that actually drive the visibility change of THIS element. With
		// the old implementation it scanned changedParams in StringMap iteration
		// order and returned the first param with any spec — so a batched update
		// could animate an element whose own controlling param has no transition.
		//
		// Setup:
		//   - paramA has fade(0.5) transition
		//   - paramB has NO transition declared (instant)
		//   - elementA is conditioned on paramA (should fade)
		//   - elementB is conditioned on paramB (should toggle instantly)
		//
		// In a batched setParameter for both params, elementB must NOT inherit
		// paramA's fade — its controlling param has no spec.
		final tm = new bh.base.TweenManager();
		final builder = builderFromSource("
			#test programmable(paramA:[a1,a2]=a1, paramB:[b1,b2]=b1) {
				transition {
					paramA: fade(0.5)
				}
				@(paramA=>a1) bitmap(generated(color(10, 10, #ff0000))): 0,0
				@(paramA=>a2) bitmap(generated(color(10, 10, #00ff00))): 0,0
				@(paramB=>b1) bitmap(generated(color(10, 10, #0000ff))): 20,0
				@(paramB=>b2) bitmap(generated(color(10, 10, #ffff00))): 20,0
			}
		");
		builder.tweenManager = tm;
		final result = builder.buildWithParameters("test",
			["paramA" => "a1", "paramB" => "b1"], null, null, true);
		Assert.notNull(result);

		// Batch: change both. Only paramA has a transition.
		result.beginUpdate();
		result.setParameter("paramA", "a2");
		result.setParameter("paramB", "b2");
		result.endUpdate();

		// Each direct child's x position identifies which param controls it (paramA at x=0,
		// paramB at x=20). The paramB-controlled wrappers must be free of tweens — paramB
		// has no transition spec, so toggling it must be instant even when batched with a
		// paramA change. The buggy implementation leaks paramA's fade onto paramB elements.
		var paramAFading = 0;
		var paramBFading = 0;
		for (i in 0...result.object.numChildren) {
			final child = result.object.getChildAt(i);
			if (!tm.hasTweens(child)) continue;
			if (Math.abs(child.x - 0.0) < 0.5) paramAFading++;
			else if (Math.abs(child.x - 20.0) < 0.5) paramBFading++;
		}
		Assert.isTrue(paramAFading > 0, "paramA-controlled elements should be fading (transition spec exists)");
		Assert.equals(0, paramBFading,
			'paramB-controlled elements must toggle instantly (no transition spec); got $paramBFading tween-bearing wrappers at x=20');

		// Sanity: after enough wall-clock to finish the fade, exactly the two new
		// elements (paramA=a2, paramB=b2) are in graph.
		tm.update(0.0); // skipFirstDt
		tm.update(1.0);
		final visible = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, visible.length, "Two elements visible after batched param swap");
	}

	@Test
	public function testTransitionDoesNotFlashInactiveElseBranch():Void {
		// Regression guard for double-pass visibility evaluation in applyUpdates:
		// pass 1 uses shouldBuildInFullMode() which returns `true` unconditionally for
		// ConditionalElse/ConditionalDefault; pass 2 (applyConditionalChains)
		// correctly accounts for sibling-matched state. With a transition active
		// for the changed param, pass 1 adds the @else branch to the graph and
		// starts a fade-in, then pass 2 cancels and starts a fade-out — leaving
		// the element in graph at alpha=savedAlpha (1.0), visibly flashing through
		// a full fade-out when it should have stayed hidden.
		//
		// Setup: cond1 drives the @(cond1) / @else chain; cond2 carries the
		// transition. Changing cond2 must NOT alter chain visibility.
		final tm = new bh.base.TweenManager();
		final builder = builderFromSource("
			#test programmable(cond1:bool=true, cond2:bool=true) {
				transition {
					cond2: fade(0.5)
				}
				@(cond1=>true) bitmap(generated(color(10, 10, #ff0000))): 0,0
				@else bitmap(generated(color(10, 10, #00ff00))): 0,0
			}
		");
		builder.tweenManager = tm;
		final result = builder.buildWithParameters("test",
			["cond1" => true, "cond2" => true], null, null, true);
		Assert.notNull(result);

		// Initial: @(cond1=>true) matches → A visible. @else hidden (not in graph).
		// Children layout: sentinel_A, wrapperA, sentinel_B (B's wrapper built but
		// not attached because the initial chain decided @else inactive).
		final initialChildCount = result.object.numChildren;
		final initialVisible = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, initialVisible.length, "Only A should be visible initially");

		// Trigger the bug: change cond2 (the transition-carrying param). Chain
		// semantics are unchanged — cond1 still matches, @else still inactive.
		result.setParameter("cond2", false);

		// Assertion 1: the number of children in graph must not grow. Pass 1
		// incorrectly calls addToGraph on B's wrapper (shouldBuildInFullMode returns true for
		// ConditionalElse unconditionally); pass 2 leaves it attached mid-fade.
		Assert.equals(initialChildCount, result.object.numChildren,
			'Child count in graph must not change when chain visibility is unchanged');

		// Assertion 2: B's bitmap must not appear as visible. If the bug fires,
		// B's wrapper is in graph with alpha=1.0 (restored by pass 2's cancel)
		// and its fade-out tween hasn't stepped yet — so findVisibleBitmapDescendants
		// would return 2 bitmaps.
		final postChangeVisible = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, postChangeVisible.length,
			'Only A bitmap should be visible; @else must stay hidden when its chain decision is unchanged');

		// Assertion 3: No child should have a tween. The @else branch's visibility
		// decision did not change, so the transition machinery must not fire.
		var tweenBearingCount = 0;
		for (i in 0...result.object.numChildren) {
			final child = result.object.getChildAt(i);
			if (tm.hasTweens(child)) tweenBearingCount++;
		}
		Assert.equals(0, tweenBearingCount,
			'No element should have tweens when chain visibility is unchanged; got $tweenBearingCount');
	}

	@Test
	public function testDynamicRefPropagationSkipsHiddenSubtree():Void {
		// When a dynamicRef sits inside a hidden conditional branch, parent
		// setParameter() changes to forwarded params must NOT cascade into the
		// child's applyUpdates cycle — the child subtree is detached from the
		// scene graph, so re-evaluating its expressions and firing its rebuild
		// listeners is wasted work (and, for listeners that touch external state,
		// a spurious notification).
		//
		// Compare with the trackedExpressions loop in applyUpdates, which already
		// gates on isEffectivelyVisible(obj). The dynamicRefBindings loop
		// immediately below it does not — this test asserts parity.
		final result = buildFromSource("
			#child programmable(v:uint=0) {
				bitmap(generated(color($v + 1, 10, #ff0000))): 0, 0
			}
			#parent programmable(show:bool=true, val:uint=5) {
				@(show=>true) dynamicRef($child, v=>$val): 0, 0
			}
		", "parent", null, Incremental);
		Assert.notNull(result);

		final childRef = result.getDynamicRef("child");
		Assert.notNull(childRef);

		var childRebuildCount = 0;
		childRef.addRebuildListener(() -> childRebuildCount++);

		// Hide the subtree. The forwarded-param refs for this binding are ["val"],
		// so toggling `show` alone is not "relevant" and the propagation loop
		// skips it regardless of the fix — baseline for the next assertion.
		result.setParameter("show", false);
		final hideRebuildCount = childRebuildCount;

		// Change the forwarded param while the dynamicRef is hidden. Today, the
		// propagation loop has no visibility gate — childContext.setParameter
		// fires, the child's applyUpdates runs, and the rebuild listener ticks.
		// After the fix, the hidden subtree must be skipped.
		result.setParameter("val", 7);
		Assert.equals(hideRebuildCount, childRebuildCount,
			'Hidden dynamicRef must not receive propagated param updates; child rebuilt ${childRebuildCount - hideRebuildCount} extra times while detached from scene graph');
	}

	// ==================== extraPoint coordinates ====================

	@Test
	public function testExtraPointRef():Void {
		// marine.anim idle animation with direction=>l has targeting: -1, -12
		// The stateanim is at 100, 200, and the bitmap should be at the extra point coords
		final result = buildFromSource("
			#test programmable() {
				#player stateanim(\"marine.anim\", \"idle\", direction=>\"l\"): 100, 200
				bitmap(generated(color(5, 5, #FF0000))): $player.extraPoint(\"targeting\")
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		// Extra point targeting for direction=l is (-1, -12)
		Assert.equals(-1, Std.int(bitmaps[0].x));
		Assert.equals(-12, Std.int(bitmaps[0].y));
	}

	@Test
	public function testExtraPointRefWithFallback():Void {
		// Reference a point that doesn't exist in idle animation, should use fallback
		final result = buildFromSource("
			#test programmable() {
				#player stateanim(\"marine.anim\", \"idle\", direction=>\"l\"): 100, 200
				bitmap(generated(color(5, 5, #00FF00))): $player.extraPoint(\"fire\", fallback: 99, 88)
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		// "fire" not in idle animation, fallback to 99, 88
		Assert.equals(99, Std.int(bitmaps[0].x));
		Assert.equals(88, Std.int(bitmaps[0].y));
	}

	@Test
	public function testExtraPointRefThrowsOnMissing():Void {
		// Reference a point that doesn't exist without fallback — should throw
		var threw = false;
		try {
			buildFromSource("
				#test programmable() {
					#player stateanim(\"marine.anim\", \"idle\", direction=>\"l\"): 100, 200
					bitmap(generated(color(5, 5, #0000FF))): $player.extraPoint(\"fire\")
				}
			", "test");
		} catch (e:Dynamic) {
			threw = true;
			Assert.stringContains("fire", Std.string(e));
		}
		Assert.isTrue(threw, "Should throw when extra point not found without fallback");
	}

	@Test
	public function testExtraPointAnim():Void {
		// Direct reference to anim file: fire-up animation has fire: 5, -19
		final result = buildFromSource("
			#test programmable() {
				bitmap(generated(color(5, 5, #FF0000))): extraPoint(\"marine.anim\", \"fire-up\", \"fire\", direction=>\"r\")
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(5, Std.int(bitmaps[0].x));
		Assert.equals(-19, Std.int(bitmaps[0].y));
	}

	@Test
	public function testExtraPointAnimWithFallback():Void {
		// Direct reference to anim with missing point — should use fallback
		final result = buildFromSource("
			#test programmable() {
				bitmap(generated(color(5, 5, #FF0000))): extraPoint(\"marine.anim\", \"idle\", \"fire\", direction=>\"l\", fallback: 77, 66)
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(77, Std.int(bitmaps[0].x));
		Assert.equals(66, Std.int(bitmaps[0].y));
	}

	@Test
	public function testExtraPointRefWithOffset():Void {
		// Extra point with .offset() suffix
		final result = buildFromSource("
			#test programmable() {
				#player stateanim(\"marine.anim\", \"idle\", direction=>\"l\"): 100, 200
				bitmap(generated(color(5, 5, #FF0000))): $player.extraPoint(\"targeting\").offset(10, 5)
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		// targeting: -1, -12 + offset(10, 5) = 9, -7
		Assert.equals(9, Std.int(bitmaps[0].x));
		Assert.equals(-7, Std.int(bitmaps[0].y));
	}

	@Test
	public function testExtraPointRefDirectionR():Void {
		// Test with direction=r: @else targeting: 5, -12
		final result = buildFromSource("
			#test programmable() {
				#player stateanim(\"marine.anim\", \"idle\", direction=>\"r\"): 0, 0
				bitmap(generated(color(5, 5, #FF0000))): $player.extraPoint(\"targeting\")
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(5, Std.int(bitmaps[0].x));
		Assert.equals(-12, Std.int(bitmaps[0].y));
	}

	// ==================== extraPoint .x/.y extraction in expressions ====================

	@Test
	public function testExtraPointXYExtractionInText():Void {
		// $ref.extraPoint("name").x / .y should resolve to the point's coordinates
		// marine.anim idle direction=l targeting: -1, -12
		final result = buildFromSource("
			#test programmable() {
				#player stateanim(\"marine.anim\", \"idle\", direction=>\"l\"): 100, 200
				text(dd, '${$player.extraPoint(\"targeting\").x},${$player.extraPoint(\"targeting\").y}', #FF0000): 0, 0
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		Assert.equals("-1,-12", texts[0].text);
	}

	@Test
	public function testExtraPointXYWithArithmeticInText():Void {
		// .x + offset should compute correctly
		final result = buildFromSource("
			#test programmable() {
				@final OX = 150
				@final OY = 200
				#player stateanim(\"marine.anim\", \"idle\", direction=>\"l\"): $OX, $OY
				text(dd, '${$player.extraPoint(\"targeting\").x + $OX},${$player.extraPoint(\"targeting\").y + $OY}', #FF0000): 0, 0
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		// targeting: -1, -12 + offset 150, 200 = 149, 188
		Assert.equals("149,188", texts[0].text);
	}

	@Test
	public function testExtraPointXYFallbackInExpression():Void {
		// $ref.extraPoint("nonexistent", fbX, fbY).x should use fallback
		final result = buildFromSource("
			#test programmable() {
				#player stateanim(\"marine.anim\", \"idle\", direction=>\"l\"): 100, 200
				text(dd, '${$player.extraPoint(\"nonexistent\", 99, 88).x},${$player.extraPoint(\"nonexistent\", 99, 88).y}', #FF0000): 0, 0
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		Assert.equals("99,88", texts[0].text);
	}

	@Test
	public function testExtraPointXYThrowsOnMissingNoFallback():Void {
		// $ref.extraPoint("nonexistent").x without fallback should throw
		var threw = false;
		try {
			buildFromSource("
				#test programmable() {
					#player stateanim(\"marine.anim\", \"idle\", direction=>\"l\"): 100, 200
					text(dd, '${$player.extraPoint(\"nonexistent\").x}', #FF0000): 0, 0
				}
			", "test");
		} catch (e:Dynamic) {
			threw = true;
			Assert.stringContains("nonexistent", Std.string(e));
		}
		Assert.isTrue(threw, "Should throw when extra point not found without fallback in expression context");
	}

	// ==================== Division by zero error paths ====================

	@Test
	public function testErrorDivisionByZeroInt():Void {
		final err = expectError(() -> buildFromSource("
			#test programmable(x:uint=10, y:uint=0) {
				bitmap(generated(color($x / $y, 10, #f00))): 0, 0
			}
		", "test"));
		Assert.notNull(err, "Should throw for integer division by zero");
		Assert.stringContains("Division by zero", err);
	}

	@Test
	public function testErrorDivisionByZeroIntDiv():Void {
		final err = expectError(() -> buildFromSource("
			#test programmable(x:uint=10, y:uint=0) {
				bitmap(generated(color($x div $y, 10, #f00))): 0, 0
			}
		", "test"));
		Assert.notNull(err, "Should throw for integer div by zero");
		Assert.stringContains("Division by zero", err);
	}

	@Test
	public function testErrorModuloByZeroInt():Void {
		final err = expectError(() -> buildFromSource("
			#test programmable(x:uint=17, y:uint=0) {
				bitmap(generated(color($x % $y, 10, #f00))): 0, 0
			}
		", "test"));
		Assert.notNull(err, "Should throw for integer modulo by zero");
		Assert.stringContains("Modulo by zero", err);
	}

	@Test
	public function testErrorDivisionByZeroFloat():Void {
		final err = expectError(() -> buildFromSource("
			#test programmable(x:float=10.0, y:float=0.0) {
				bitmap(generated(color(10, 10, #f00))): $x / $y, 0
			}
		", "test"));
		Assert.notNull(err, "Should throw for float division by zero");
		Assert.stringContains("Division by zero", err);
	}

	@Test
	public function testErrorModuloByZeroFloat():Void {
		final err = expectError(() -> buildFromSource("
			#test programmable(x:float=17.0, y:float=0.0) {
				bitmap(generated(color(10, 10, #f00))): $x % $y, 0
			}
		", "test"));
		Assert.notNull(err, "Should throw for float modulo by zero");
		Assert.stringContains("Modulo by zero", err);
	}

	// ==================== Custom filters ====================

	@Test
	public function testCustomFilterBasic():Void {
		FilterManager.registerFilter("testfilter", [
			{name: "intensity", type: CFFloat},
		], (params) -> {
			// Return a simple blur as the custom filter
			return new h2d.filter.Blur(params["intensity"], 1.0, 1.0, 0.0);
		});
		final result = buildFromSource("
			#test programmable() {
				filter: testfilter(2.0)
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		Assert.notNull(result.object.filter, "Custom filter should be applied");
		FilterManager.unregisterFilter("testfilter");
	}

	@Test
	public function testCustomFilterWithColorParam():Void {
		FilterManager.registerFilter("tintfilter", [
			{name: "amount", type: CFFloat},
			{name: "color", type: CFColor},
		], (params) -> {
			return new h2d.filter.Outline(params["amount"], params["color"]);
		});
		final result = buildFromSource("
			#test programmable() {
				filter: tintfilter(3.0, #FF0000)
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		Assert.notNull(result.object.filter, "Custom filter with color should be applied");
		FilterManager.unregisterFilter("tintfilter");
	}

	@Test
	public function testCustomFilterWithBoolParam():Void {
		var capturedEnabled:Null<Bool> = null;
		FilterManager.registerFilter("togglefilter", [
			{name: "radius", type: CFFloat},
			{name: "enabled", type: CFBool},
		], (params) -> {
			capturedEnabled = params["enabled"];
			return new h2d.filter.Blur(params["radius"], 1.0, 1.0, 0.0);
		});
		final result = buildFromSource("
			#test programmable() {
				filter: togglefilter(1.0, true)
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		Assert.isTrue(capturedEnabled, "Bool param should be true");
		FilterManager.unregisterFilter("togglefilter");
	}

	@Test
	public function testCustomFilterWithDefaults():Void {
		var capturedIntensity:Null<Float> = null;
		FilterManager.registerFilter("defaultfilter", [
			{name: "intensity", type: CFFloat, defaultValue: 5.0},
		], (params) -> {
			capturedIntensity = params["intensity"];
			return new h2d.filter.Blur(params["intensity"], 1.0, 1.0, 0.0);
		});
		// Call with zero args — should use default
		final result = buildFromSource("
			#test programmable() {
				filter: defaultfilter()
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		Assert.floatEquals(5.0, capturedIntensity, "Default value should be used");
		FilterManager.unregisterFilter("defaultfilter");
	}

	@Test
	public function testCustomFilterWithParamRef():Void {
		var capturedIntensity:Null<Float> = null;
		FilterManager.registerFilter("reffilter", [
			{name: "intensity", type: CFFloat},
		], (params) -> {
			capturedIntensity = params["intensity"];
			return new h2d.filter.Blur(params["intensity"], 1.0, 1.0, 0.0);
		});
		final params = new Map<String, Dynamic>();
		params.set("val", 7);
		final result = buildFromSource("
			#test programmable(val:uint=3) {
				filter: reffilter($val)
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test", params);
		Assert.notNull(result, "Build should succeed");
		Assert.floatEquals(7.0, capturedIntensity, "Param ref should resolve to 7");
		FilterManager.unregisterFilter("reffilter");
	}

	@Test
	public function testCustomFilterInsideGroup():Void {
		FilterManager.registerFilter("groupable", [
			{name: "size", type: CFFloat},
		], (params) -> {
			return new h2d.filter.Blur(params["size"], 1.0, 1.0, 0.0);
		});
		final result = buildFromSource("
			#test programmable() {
				filter: group(outline(2, #FF0000), groupable(1.5))
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		Assert.notNull(result.object.filter, "Group filter with custom filter should be applied");
		FilterManager.unregisterFilter("groupable");
	}

	@Test
	public function testCustomFilterUnregisteredThrows():Void {
		final err = expectError(() -> buildFromSource("
			#test programmable() {
				filter: unknownfilter(1.0)
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test"));
		Assert.notNull(err, "Should throw for unregistered custom filter");
		Assert.stringContains("Unknown custom filter", err);
	}

	@Test
	public function testCustomFilterValidation():Void {
		FilterManager.registerFilter("valfilter", [
			{name: "a", type: CFFloat},
			{name: "b", type: CFFloat},
		], (params) -> new h2d.filter.Blur(1.0, 1.0, 1.0, 0.0));

		// Should pass validation
		final builder = builderFromSource("
			#test programmable() {
				filter: valfilter(1.0, 2.0)
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		final valErr = expectError(() -> builder.validateCustomFilters());
		Assert.isNull(valErr, "Validation should pass for registered filter with correct args");

		// Wrong arg count
		final builder2 = builderFromSource("
			#test programmable() {
				filter: valfilter(1.0)
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		final valErr2 = expectError(() -> builder2.validateCustomFilters());
		Assert.notNull(valErr2, "Validation should fail for too few args");
		Assert.stringContains("requires at least", valErr2);
		FilterManager.unregisterFilter("valfilter");
	}

	@Test
	public function testCustomFilterParamRefSkipsTypeValidation():Void {
		FilterManager.registerFilter("reffilter", [
			{name: "c", type: CFColor},
			{name: "v", type: CFFloat},
		], (params) -> new h2d.filter.Blur(1.0, 1.0, 1.0, 0.0));

		// $param refs should skip type check — color param passed as $ref is valid
		final builder = builderFromSource("
			#test programmable(tint:color=#FF0000, size:float=1.0) {
				filter: reffilter($tint, $size)
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		final valErr = expectError(() -> builder.validateCustomFilters());
		Assert.isNull(valErr, "Validation should pass for $param ref args regardless of declared type");

		// Literal with wrong type should still fail
		final builder2 = builderFromSource("
			#test programmable() {
				filter: reffilter(1.0, 2.0)
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		final valErr2 = expectError(() -> builder2.validateCustomFilters());
		Assert.notNull(valErr2, "Validation should still fail for literal type mismatch");
		Assert.stringContains("expects CFColor", valErr2);
		FilterManager.unregisterFilter("reffilter");
	}

	@Test
	public function testCustomFilterRegistrationBlocksBuiltins():Void {
		final err = expectError(() -> {
			FilterManager.registerFilter("outline", [], (params) -> new h2d.filter.Blur(1.0, 1.0, 1.0, 0.0));
		});
		Assert.notNull(err, "Should throw when registering built-in filter name");
		Assert.stringContains("built-in", err);
	}

	@Test
	public function testCustomFilterCaseInsensitive():Void {
		FilterManager.registerFilter("MyFilter", [
			{name: "v", type: CFFloat},
		], (params) -> new h2d.filter.Blur(params["v"], 1.0, 1.0, 0.0));

		// .manim uses lowercase — should still match
		final result = buildFromSource("
			#test programmable() {
				filter: myfilter(2.0)
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test");
		Assert.notNull(result, "Build should succeed with case-insensitive match");
		Assert.notNull(result.object.filter, "Custom filter should be applied");
		FilterManager.unregisterFilter("MyFilter");
	}

	// ==================== Particles shutdown block parsing ====================

	@Test
	public function testParticleShutdownParsesBasic():Void {
		Assert.isTrue(parseExpectingSuccess("
			#fx particles {
				count: 10
				loop: true
				tiles: generated(color(4, 4, #ff0000))
				shutdown: {
					duration: 1.0
				}
			}
		"));
	}

	@Test
	public function testParticleShutdownParsesAllCurves():Void {
		Assert.isTrue(parseExpectingSuccess("
			#fx particles {
				count: 10
				loop: true
				tiles: generated(color(4, 4, #ff0000))
				shutdown: {
					duration: 0.5
					curve: easeOutQuad
					alphaCurve: easeInQuad
					sizeCurve: linear
					speedCurve: easeInOutCubic
				}
			}
		"));
	}

	@Test
	public function testParticleShutdownParsesNamedCurves():Void {
		Assert.isTrue(parseExpectingSuccess("
			curves {
				#fadeDown curve { easing: easeOutQuad }
			}
			#fx particles {
				count: 10
				loop: true
				tiles: generated(color(4, 4, #ff0000))
				shutdown: {
					duration: 1.0
					curve: fadeDown
				}
			}
		"));
	}

	@Test
	public function testParticleShutdownRejectsUnknownProperty():Void {
		final err = parseExpectingError("
			#fx particles {
				count: 10
				tiles: generated(color(4, 4, #ff0000))
				shutdown: {
					duration: 1.0
					bogus: easeOutQuad
				}
			}
		");
		Assert.notNull(err, "Should reject unknown shutdown property");
		Assert.isTrue(err.indexOf("unknown shutdown property") >= 0, 'Expected "unknown shutdown property" in error, got: $err');
	}

	// ==================== Particles externallyDriven ====================

	@Test
	public function testParticleExternallyDrivenParses():Void {
		Assert.isTrue(parseExpectingSuccess("
			#fx particles {
				count: 10
				externallyDriven: true
				tiles: generated(color(4, 4, #ff0000))
			}
		"));
	}

	@Test
	public function testParticleExternallyDrivenFalseParses():Void {
		Assert.isTrue(parseExpectingSuccess("
			#fx particles {
				count: 10
				externallyDriven: false
				tiles: generated(color(4, 4, #ff0000))
			}
		"));
	}

	// ==================== Pivot / Center tile source ====================

	@Test
	public function testCenterTileSource():Void {
		final result = buildFromSource("
			#test programmable() {
				bitmap(center(generated(color(40, 20, #ff0000)))): 100, 100
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(-20, Std.int(bitmaps[0].tile.dx));
		Assert.equals(-10, Std.int(bitmaps[0].tile.dy));
	}

	@Test
	public function testPivotTileSource():Void {
		final result = buildFromSource("
			#test programmable() {
				bitmap(pivot(0.0, 1.0, generated(color(40, 20, #ff0000)))): 100, 100
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(0, Std.int(bitmaps[0].tile.dx));
		Assert.equals(-20, Std.int(bitmaps[0].tile.dy));
	}

	@Test
	public function testPivotHalfBottomCenter():Void {
		final result = buildFromSource("
			#test programmable() {
				bitmap(pivot(0.5, 1.0, generated(color(40, 20, #ff0000)))): 100, 100
			}
		", "test");
		Assert.notNull(result, "Build should succeed");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(-20, Std.int(bitmaps[0].tile.dx));
		Assert.equals(-20, Std.int(bitmaps[0].tile.dy));
	}

	// ==================== @any/@all with setParameter ====================

	@Test
	public function testAnyConditionWithSetParameter():Void {
		// @any = OR semantics: match if either condition is true
		final result = buildFromSource("
			#test programmable(mode:[a,b,c]=a, style:[light,dark]=light) {
				@any(mode=>b, style=>dark) bitmap(generated(color(10, 10, #00ff00))): 0, 0
				@default bitmap(generated(color(20, 10, #ff0000))): 0, 0
			}
		", "test", null, Incremental);

		// Initially mode=a, style=light → neither matches → default (20px)
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Set mode=b → first condition matches → @any triggers (10px)
		result.setParameter("mode", "b");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Set mode=a, style=dark → second condition matches → @any triggers
		result.beginUpdate();
		result.setParameter("mode", "a");
		result.setParameter("style", "dark");
		result.endUpdate();
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Set style=light → neither matches → default
		result.setParameter("style", "light");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testAllConditionWithSetParameter():Void {
		// @all = AND semantics: match only if ALL conditions are true
		final result = buildFromSource("
			#test programmable(mode:[a,b,c]=a, style:[light,dark]=light) {
				@all(mode=>b, style=>dark) bitmap(generated(color(10, 10, #00ff00))): 0, 0
				@default bitmap(generated(color(20, 10, #ff0000))): 0, 0
			}
		", "test", null, Incremental);

		// Initially mode=a, style=light → default (20px)
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Set mode=b only → only one condition matches → still default
		result.setParameter("mode", "b");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Set style=dark → both match → @all triggers (10px)
		result.setParameter("style", "dark");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Set mode=a → only style=dark matches → back to default
		result.setParameter("mode", "a");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testAnyConditionWithComparison():Void {
		// @any with comparison operators mixed: one enum, one comparison
		final result = buildFromSource("
			#test programmable(mode:[a,b,c]=a, level:int=0) {
				@any(mode=>b, level >= 5) bitmap(generated(color(10, 10, #00ff00))): 0, 0
				@default bitmap(generated(color(20, 10, #ff0000))): 0, 0
			}
		", "test", null, Incremental);

		// Initially mode=a, level=0 → neither matches → default (20px)
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Set level=5 → comparison matches → @any triggers (10px)
		result.setParameter("level", 5);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Set level=0, mode=b → enum matches → @any triggers
		result.beginUpdate();
		result.setParameter("level", 0);
		result.setParameter("mode", "b");
		result.endUpdate();
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Set mode=a → neither matches → default
		result.setParameter("mode", "a");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	// ==================== @switch incremental mode tests ====================

	@Test
	public function testIncrementalSwitchEnumBasic():Void {
		// Basic @switch on enum param — setParameter should switch visible arm
		final result = buildFromSource("
			#test programmable(state:[idle, active, error]=idle) {
				@switch(state) {
					idle: bitmap(generated(color(10, 10, #f00)));
					active: bitmap(generated(color(20, 10, #0f0)));
					error: bitmap(generated(color(30, 10, #00f)));
				}
			}
		", "test", null, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Switch to active — should show 20px wide bitmap
		result.setParameter("state", "active");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Switch to error — should show 30px wide bitmap
		result.setParameter("state", "error");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));

		// Switch back to idle — should show 10px wide bitmap again
		result.setParameter("state", "idle");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalSwitchDefault():Void {
		// @switch with default arm — non-listed values should hit default
		final result = buildFromSource("
			#test programmable(state:[idle, hover, pressed, disabled]=idle) {
				@switch(state) {
					idle: bitmap(generated(color(10, 10, #f00)));
					hover: bitmap(generated(color(20, 10, #0f0)));
					default: bitmap(generated(color(30, 10, #00f)));
				}
			}
		", "test", null, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Switch to pressed — should hit default (30px)
		result.setParameter("state", "pressed");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));

		// Switch to hover — should hit explicit arm (20px)
		result.setParameter("state", "hover");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalSwitchMultiValue():Void {
		// @switch with pipe-separated multi-value arms
		final result = buildFromSource("
			#test programmable(level:[low, medium, high, critical]=low) {
				@switch(level) {
					low | medium: bitmap(generated(color(10, 10, #0f0)));
					high | critical: bitmap(generated(color(20, 10, #f00)));
				}
			}
		", "test", null, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// medium — same arm as low (10px)
		result.setParameter("level", "medium");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// high — second arm (20px)
		result.setParameter("level", "high");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalSwitchPipeColor():Void {
		// Regression: @switch pipe-separated arms on a color param.
		// Pipe arms were stored as CoEnums(["#FF0000", ...]) (raw lexeme strings),
		// while runtime values come through as Value(int). matchSingleCondition
		// compared via a.contains(Std.string(val)) — Std.string(0xFF0000) == "16711680"
		// which never matches "#FF0000", so no pipe arm ever fires for color params.
		final result = buildFromSource("
			#test programmable(tint:color=#FF0000) {
				@switch(tint) {
					#FF0000 | #00FF00: bitmap(generated(color(10, 10, #fff)));
					#0000FF | #FFFF00: bitmap(generated(color(20, 10, #fff)));
					default: bitmap(generated(color(99, 10, #fff)));
				}
			}
		", "test", null, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width)); // #FF0000 → first arm

		// Second value of first pipe arm (pass the already-baked AARRGGBB form)
		result.setParameter("tint", 0xFF00FF00);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// First value of second pipe arm
		result.setParameter("tint", 0xFF0000FF);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Second value of second pipe arm
		result.setParameter("tint", 0xFFFFFF00);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Value not in any pipe arm — fall through to default (99px)
		result.setParameter("tint", 0xFF123456);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(99, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalSetParameterColorSemiTransparent():Void {
		// Semi-transparent alpha (top byte != 0) must be preserved unchanged by
		// `IncrementalUpdateContext.setParameter` — addAlphaIfNotPresent is a no-op
		// when alpha is already set. Arms use #RRGGBBAA 8-digit literals so the parser
		// round-trips them to AARRGGBB (Heaps) and the runtime int compares directly.
		final result = buildFromSource("
			#test programmable(tint:color=#FFFFFFFF) {
				@switch(tint) {
					#FF000080: bitmap(generated(color(55, 10, #fff)));
					#00FF00A0: bitmap(generated(color(66, 10, #fff)));
					#000000:   bitmap(generated(color(88, 10, #fff)));
					default:   bitmap(generated(color(99, 10, #fff)));
				}
			}
		", "test", null, Incremental);

		// Default #FFFFFFFF → default arm.
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(99, Std.int(bitmaps[0].tile.width));

		// Already-baked 0x80FF0000 (CSS #FF000080) → semi-transparent red arm (55px).
		result.setParameter("tint", 0x80FF0000);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(55, Std.int(bitmaps[0].tile.width));

		// Already-baked 0xA000FF00 (CSS #00FF00A0) → semi-transparent green arm (66px).
		result.setParameter("tint", 0xA000FF00);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(66, Std.int(bitmaps[0].tile.width));

		// Strict-D: `setParameter("tint", 0)` is preserved verbatim. There's no
		// transparent arm in this programmable, so it falls through to default (99px).
		result.setParameter("tint", 0);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(99, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testParser0xColorLiteralPreserved():Void {
		// Strict-D: `0x...` literals in .manim are Heaps AARRGGBB and preserved
		// verbatim — no alpha baking. `0xFF0000` means transparent red (top byte
		// = 0), so the default tint below does NOT match `#FF0000` (which bakes
		// to `0xFFFF0000`). Use `0xFFFF0000` or `#FF0000` for opaque red.
		final result = buildFromSource("
			#test programmable(tint:color=0xFFFF0000) {
				@switch(tint) {
					#FF0000:   bitmap(generated(color(11, 10, #fff)));
					#FF000080: bitmap(generated(color(22, 10, #fff))); // Heaps 0x80FF0000
					default:   bitmap(generated(color(99, 10, #fff)));
				}
			}
		", "test", null, Incremental);

		// Default `0xFFFF0000` is identical to the baked `#FF0000` arm → 11px.
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(11, Std.int(bitmaps[0].tile.width));

		// Explicit-alpha value: `0x80FF0000` (semi-transparent red) → `#FF000080` arm.
		result.setParameter("tint", 0x80FF0000);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(22, Std.int(bitmaps[0].tile.width));

		// Un-baked 0xFF0000 (transparent red) does NOT match #FF0000 → default (99px).
		result.setParameter("tint", 0xFF0000);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(99, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testParser0xColorLiteralExplicitAlphaPreserved():Void {
		// Regression: `0xAARRGGBB` literals with explicit non-zero alpha must NOT be
		// clobbered by the alpha-baking path. Guards against reverting to an
		// unconditional `0xFF000000 | v`, which would silently convert every
		// semi-transparent 0x literal into an opaque color.
		//
		// Default is `0x80FF0000` (Heaps: alpha 0x80, red 0xFF). Arm literals use CSS
		// #RRGGBBAA: `#FF000080` → Heaps 0x80FF0000 (matches), `#FF0000` → 0xFFFF0000
		// (the opaque-red arm — must NOT match).
		final result = buildFromSource("
			#test programmable(tint:color=0x80FF0000) {
				@switch(tint) {
					#FF000080: bitmap(generated(color(11, 10, #fff))); // semi-transparent red (target)
					#FF0000:   bitmap(generated(color(22, 10, #fff))); // opaque red — must NOT match
					default:   bitmap(generated(color(99, 10, #fff)));
				}
			}
		", "test", null, Incremental);

		// If the 0x path used `0xFF000000 | v`, the stored default would be 0xFFFF0000
		// and the opaque-red arm (22px) would fire. The correct path preserves 0x80FF0000
		// and hits the semi-transparent arm (11px).
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(11, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testParser0xColorLiteralExplicit8DigitZeroAlpha():Void {
		// Regression: `0x` color literals preserve their value verbatim, including
		// 0-alpha cases. `0x00FF0000` is fully transparent red and must NOT be
		// collapsed to opaque red (`0xFFFF0000`). Strict-D: the top byte IS alpha
		// in Heaps convention, regardless of literal length.
		//
		// Arm literals use CSS #RRGGBBAA: `#FF000000` → Heaps 0x00FF0000 (matches),
		// `#FF0000` → 0xFFFF0000 (opaque red — must NOT match).
		final result = buildFromSource("
			#test programmable(tint:color=0x00FF0000) {
				@switch(tint) {
					#FF000000: bitmap(generated(color(11, 10, #fff))); // Heaps 0x00FF0000 — transparent red
					#FF0000:   bitmap(generated(color(22, 10, #fff))); // Heaps 0xFFFF0000 — opaque red
					default:   bitmap(generated(color(99, 10, #fff)));
				}
			}
		", "test", null, Incremental);

		// Default `0x00FF0000` is 8 digits → stored verbatim (alpha 0) → transparent-red
		// arm fires (11px). If the parser collapsed 0-alpha to opaque, the opaque-red
		// arm would fire (22px) instead.
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(11, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalSwitchPipeHexInt():Void {
		// Regression: @switch pipe-separated arms on int param using hex literals.
		// parseSwitchArmValue normalizes 0xFF -> "0xff" but matchSingleCondition
		// compares to Std.string(255) == "255". Decimal arms happen to round-trip,
		// hex arms never match.
		final result = buildFromSource("
			#test programmable(level:int=255) {
				@switch(level) {
					0xFF | 0x10: bitmap(generated(color(10, 10, #fff)));
					0x20 | 0x30: bitmap(generated(color(20, 10, #fff)));
					default: bitmap(generated(color(99, 10, #fff)));
				}
			}
		", "test", null, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width)); // 255 → first arm

		// Second value of first pipe arm
		result.setParameter("level", 0x10);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// First value of second pipe arm
		result.setParameter("level", 0x20);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Out of range — default arm
		result.setParameter("level", 0x99);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(99, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalSwitchBlockArms():Void {
		// @switch with block arms containing multiple elements
		final result = buildFromSource("
			#test programmable(mode:[a, b]=a) {
				@switch(mode) {
					a {
						bitmap(generated(color(10, 10, #f00)));
						bitmap(generated(color(15, 10, #0f0)));
					}
					b {
						bitmap(generated(color(20, 10, #00f)));
					}
				}
			}
		", "test", null, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
		Assert.equals(15, Std.int(bitmaps[1].tile.width));

		// Switch to b — should show single 20px bitmap, not the two from arm a
		result.setParameter("mode", "b");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Switch back to a — should restore both bitmaps
		result.setParameter("mode", "a");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
		Assert.equals(15, Std.int(bitmaps[1].tile.width));
	}

	@Test
	public function testIncrementalSwitchRange():Void {
		// @switch with range and comparison arms
		final params = new Map<String, Dynamic>();
		params.set("temp", -20);
		final result = buildFromSource("
			#test programmable(temp:-50..150=0) {
				@switch(temp) {
					<= -1: bitmap(generated(color(10, 10, #00f)));
					0..100: bitmap(generated(color(20, 10, #0f0)));
					>= 101: bitmap(generated(color(30, 10, #f00)));
				}
			}
		", "test", params, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// temp=50 → 0..100 arm (20px)
		result.setParameter("temp", 50);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// temp=120 → >= 101 arm (30px)
		result.setParameter("temp", 120);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalSwitchBool():Void {
		// @switch on bool param
		final result = buildFromSource("
			#test programmable(enabled:bool=true) {
				@switch(enabled) {
					true: bitmap(generated(color(10, 10, #0f0)));
					false: bitmap(generated(color(20, 10, #f00)));
				}
			}
		", "test", null, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Switch to false
		result.setParameter("enabled", false);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Switch back to true
		result.setParameter("enabled", true);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalSwitchMultipleSwitchBlocks():Void {
		// Two separate @switch blocks on same param — both should update
		final result = buildFromSource("
			#test programmable(state:[a, b]=a) {
				@switch(state) {
					a: bitmap(generated(color(10, 10, #f00)));
					b: bitmap(generated(color(20, 10, #0f0)));
				}
				@switch(state) {
					a: bitmap(generated(color(30, 10, #00f)));
					b: bitmap(generated(color(40, 10, #ff0)));
				}
			}
		", "test", null, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
		Assert.equals(30, Std.int(bitmaps[1].tile.width));

		// Switch to b — both blocks should update
		result.setParameter("state", "b");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
		Assert.equals(40, Std.int(bitmaps[1].tile.width));
	}

	@Test
	public function testIncrementalSwitchWithRepeatable():Void {
		// @switch arms contain repeatables — switching arm should change element count and size
		final result = buildFromSource("
			#test programmable(mode:[items, grid]=items, count:uint=3) {
				@switch(mode) {
					items {
						repeatable($i, step($count, dx: 12)) {
							bitmap(generated(color(10, 10, #0f0))): 0, 0
						}
					}
					grid {
						repeatable($i, step($count, dx: 12)) {
							bitmap(generated(color(20, 10, #f00))): 0, 0
						}
					}
				}
			}
		", "test", null, Incremental);

		// Initial: mode=items, count=3 → 3 green bitmaps (10px wide)
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(3, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Switch to grid — should show 3 red bitmaps (20px wide)
		result.setParameter("mode", "grid");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(3, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Switch back to items — 3 green bitmaps again
		result.setParameter("mode", "items");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(3, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalSwitchRepeatableCountChange():Void {
		// Change the repeatable count param while inside a @switch arm
		final result = buildFromSource("
			#test programmable(mode:[items, grid]=items, count:uint=3) {
				@switch(mode) {
					items {
						repeatable($i, step($count, dx: 12)) {
							bitmap(generated(color(10, 10, #0f0))): 0, 0
						}
					}
					grid {
						repeatable($i, step($count, dx: 12)) {
							bitmap(generated(color(20, 10, #f00))): 0, 0
						}
					}
				}
			}
		", "test", null, Incremental);

		// Initial: mode=items, count=3
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(3, bitmaps.length);

		// Increase count to 5 while staying in items arm
		result.setParameter("count", 5);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(5, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Decrease count to 2
		result.setParameter("count", 2);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);
	}

	@Test
	public function testIncrementalSwitchAndRepeatableBatchUpdate():Void {
		// Change both switch param and repeatable count in one batch
		final result = buildFromSource("
			#test programmable(mode:[items, grid]=items, count:uint=3) {
				@switch(mode) {
					items {
						repeatable($i, step($count, dx: 12)) {
							bitmap(generated(color(10, 10, #0f0))): 0, 0
						}
					}
					grid {
						repeatable($i, step($count, dx: 12)) {
							bitmap(generated(color(20, 10, #f00))): 0, 0
						}
					}
				}
			}
		", "test", null, Incremental);

		// Initial: mode=items, count=3 → 3 green (10px)
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(3, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Batch: switch to grid AND change count to 5 → 5 red (20px)
		result.beginUpdate();
		result.setParameter("mode", "grid");
		result.setParameter("count", 5);
		result.endUpdate();
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(5, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Batch: switch back to items AND count=1 → 1 green (10px)
		result.beginUpdate();
		result.setParameter("mode", "items");
		result.setParameter("count", 1);
		result.endUpdate();
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	// ==================== Switch/Repeat rebuild registration retention ====================
	// Regression coverage for a bug where SWITCH arm rebuilds and param-dependent REPEAT
	// rebuilds passed a throwaway InternalBuilderResults to the recursive build(), so any
	// interactives / slots / dynamicRefs / named elements registered inside the new arm or
	// new iterations were orphaned and never visible via the parent BuilderResult.
	// See MultiAnimBuilder.hx:4452 (SWITCH) and :4675 (REPEAT) rebuild closures.

	static function findInteractiveById(result:bh.multianim.MultiAnimBuilder.BuilderResult, id:String):Null<MAObject> {
		for (obj in result.interactives) {
			switch obj.multiAnimType {
				case MAInteractive(_, _, identifier, _) if (identifier == id): return obj;
				case _:
			}
		}
		return null;
	}

	static function countInteractives(result:bh.multianim.MultiAnimBuilder.BuilderResult):Int {
		var n = 0;
		for (obj in result.interactives) {
			switch obj.multiAnimType {
				case MAInteractive(_, _, _, _): n++;
				case _:
			}
		}
		return n;
	}

	@Test
	public function testIncrementalSwitchInteractiveVisibleAfterArmSwitch():Void {
		// Each arm registers its own interactive id. After flipping arms the new arm's
		// interactive must be findable in result.interactives.
		final result = buildFromSource("
			#test programmable(mode:[a, b]=a) {
				@switch(mode) {
					a: interactive(40, 40, \"hitA\"): 0, 0;
					b: interactive(60, 60, \"hitB\"): 0, 0;
				}
			}
		", "test", null, Incremental);

		Assert.notNull(findInteractiveById(result, "hitA"), "hitA should be present in initial arm a");

		result.setParameter("mode", "b");
		Assert.notNull(findInteractiveById(result, "hitB"),
			"hitB should be present after switching to arm b — currently orphaned by throwaway InternalBuilderResults");

		result.setParameter("mode", "a");
		Assert.notNull(findInteractiveById(result, "hitA"),
			"hitA should be present after switching back to arm a");
	}

	@Test
	public function testIncrementalSwitchSlotVisibleAfterArmSwitch():Void {
		// A named slot inside a switch arm must be retrievable via getSlot() after rebuild.
		final result = buildFromSource("
			#test programmable(mode:[a, b]=a) {
				@switch(mode) {
					a {
						#slotA slot {
							bitmap(generated(color(10, 10, #f00))): 0, 0
						}
					}
					b {
						#slotB slot {
							bitmap(generated(color(20, 20, #0f0))): 0, 0
						}
					}
				}
			}
		", "test", null, Incremental);

		Assert.notNull(result.getSlot("slotA"), "slotA should exist in initial arm a");

		result.setParameter("mode", "b");
		// getSlot throws when missing — capture as Null via try/catch for a clearer assert message.
		var slotB:Dynamic = null;
		try { slotB = result.getSlot("slotB"); } catch (_:Dynamic) {}
		Assert.notNull(slotB,
			"slotB should be retrievable after switching to arm b — currently orphaned by throwaway InternalBuilderResults");
	}

	@Test
	public function testIncrementalSwitchDynamicRefVisibleAfterArmSwitch():Void {
		// dynamicRef registered inside a switch arm must be retrievable after rebuild.
		final result = buildFromSource("
			#leafA programmable() {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
			#leafB programmable() {
				bitmap(generated(color(20, 20, #0f0))): 0, 0
			}
			#test programmable(mode:[a, b]=a) {
				@switch(mode) {
					a: dynamicRef($leafA): 0, 0;
					b: dynamicRef($leafB): 0, 0;
				}
			}
		", "test", null, Incremental);

		Assert.notNull(result.getDynamicRef("leafA"), "leafA dynamicRef should exist in initial arm a");

		result.setParameter("mode", "b");
		var refB:Dynamic = null;
		try { refB = result.getDynamicRef("leafB"); } catch (_:Dynamic) {}
		Assert.notNull(refB,
			"leafB dynamicRef should be retrievable after switching to arm b — currently orphaned by throwaway InternalBuilderResults");
	}

	@Test
	public function testIncrementalSwitchNamedElementVisibleAfterArmSwitch():Void {
		// A named element registered inside a switch arm must be retrievable via hasName/getUpdatable after rebuild.
		final result = buildFromSource("
			#test programmable(mode:[a, b]=a) {
				@switch(mode) {
					a {
						#namedA bitmap(generated(color(10, 10, #f00))): 0, 0
					}
					b {
						#namedB bitmap(generated(color(20, 20, #0f0))): 0, 0
					}
				}
			}
		", "test", null, Incremental);

		Assert.isTrue(result.hasName("namedA"), "namedA should be in result.names for initial arm a");

		result.setParameter("mode", "b");
		Assert.isTrue(result.hasName("namedB"),
			"namedB should be in result.names after switching to arm b — currently orphaned by throwaway InternalBuilderResults");
	}

	@Test
	public function testIncrementalSwitchNoStaleAccumulation():Void {
		// Stale-entry regression: switching arms back-and-forth must not accumulate dead entries
		// in the parent internalResults. After N flips, counts must match what only the active arm registers.
		final result = buildFromSource("
			#test programmable(mode:[a, b]=a) {
				@switch(mode) {
					a {
						interactive(40, 40, \"hitA\"): 0, 0
						#slotA slot {
							bitmap(generated(color(10, 10, #f00))): 0, 0
						}
					}
					b {
						interactive(60, 60, \"hitB\"): 0, 0
						#slotB slot {
							bitmap(generated(color(20, 20, #0f0))): 0, 0
						}
					}
				}
			}
		", "test", null, Incremental);

		// Initial: arm a → 1 interactive (hitA), 1 slot (slotA)
		Assert.equals(1, countInteractives(result), "initial: 1 interactive in arm a");
		Assert.equals(1, result.slots.length, "initial: 1 slot in arm a");

		// Flip back and forth several times — collections must not grow.
		for (i in 0...3) {
			result.setParameter("mode", "b");
			Assert.equals(1, countInteractives(result), 'after switch to b (iter $i): exactly 1 interactive, no stale');
			Assert.equals(1, result.slots.length, 'after switch to b (iter $i): exactly 1 slot, no stale');
			Assert.notNull(findInteractiveById(result, "hitB"));
			Assert.isNull(findInteractiveById(result, "hitA"), 'hitA must not survive switch to b (iter $i)');

			result.setParameter("mode", "a");
			Assert.equals(1, countInteractives(result), 'after switch to a (iter $i): exactly 1 interactive, no stale');
			Assert.equals(1, result.slots.length, 'after switch to a (iter $i): exactly 1 slot, no stale');
			Assert.notNull(findInteractiveById(result, "hitA"));
			Assert.isNull(findInteractiveById(result, "hitB"), 'hitB must not survive switch to a (iter $i)');
		}
	}

	@Test
	public function testIncrementalRepeatableInteractiveShrinkNoStale():Void {
		// When the repeat count shrinks, removed iterations' interactives must be dropped from
		// internalResults (not just from the scene graph).
		final result = buildFromSource("
			#test programmable(count:uint=4) {
				repeatable($i, step($count, dx: 30)) {
					interactive(20, 20, $i): 0, 0
				}
			}
		", "test", null, Incremental);

		Assert.equals(4, countInteractives(result));

		result.setParameter("count", 2);
		Assert.equals(2, countInteractives(result), "shrinking count must remove old entries, not just hide them");
		Assert.notNull(findInteractiveById(result, "0"));
		Assert.notNull(findInteractiveById(result, "1"));
		Assert.isNull(findInteractiveById(result, "2"), "iteration 2 must be removed when count shrinks to 2");
		Assert.isNull(findInteractiveById(result, "3"), "iteration 3 must be removed when count shrinks to 2");
	}

	@Test
	public function testIncrementalRepeatableInteractiveCountChange():Void {
		// Param-dependent repeat count: increasing $count must register interactives for the new iterations.
		final result = buildFromSource("
			#test programmable(count:uint=2) {
				repeatable($i, step($count, dx: 30)) {
					interactive(20, 20, $i): 0, 0
				}
			}
		", "test", null, Incremental);

		Assert.equals(2, countInteractives(result), "should have 2 interactives initially");
		Assert.notNull(findInteractiveById(result, "0"));
		Assert.notNull(findInteractiveById(result, "1"));

		// Increase count — new iterations rebuild via param-dependent repeat closure.
		result.setParameter("count", 4);
		Assert.equals(4, countInteractives(result),
			"should have 4 interactives after count increase — new iterations currently orphan their registrations");
		Assert.notNull(findInteractiveById(result, "2"));
		Assert.notNull(findInteractiveById(result, "3"));
	}

	#if MULTIANIM_DEV
	// ==================== Per-element bookkeeping cleanup on rebuild (dev-only) ====================
	// Verifies that SWITCH/REPEAT rebuild closures clean up nested per-element bookkeeping (tracked
	// expressions, conditional entries, dynamicRefBindings, dynamicNameBindings, transition tweens)
	// when an arm/iteration is destroyed. Without cleanup, repeated arm flips would leak memory.

	@Test
	public function testIncrementalSwitchTrackedExpressionsCleanedUp():Void {
		// Arm B contains an inner repeatable with text interpolation, which registers a tracked
		// expression per iteration. Flipping arms should reclaim those tracked expressions.
		final result = buildFromSource("
			#test programmable(mode:[a, b]=a, label:string=\"hi\") {
				@switch(mode) {
					a {
						bitmap(generated(color(10, 10, #f00))): 0, 0
					}
					b {
						repeatable($i, step(3, dx: 20)) {
							text(dd, '${label}', #fff): 0, 0
						}
					}
				}
			}
		", "test", null, Incremental);

		final ctx = result.incrementalContext;
		Assert.notNull(ctx);
		final initialCount = ctx.getTrackedExpressionsCount();

		// Flip back and forth — count must not grow unboundedly.
		for (i in 0...5) {
			result.setParameter("mode", "b");
			result.setParameter("mode", "a");
		}

		final finalCount = ctx.getTrackedExpressionsCount();
		Assert.equals(initialCount, finalCount,
			'tracked expressions leaked: $initialCount initial vs $finalCount after 10 flips');
	}

	@Test
	public function testIncrementalSwitchConditionalEntriesCleanedUp():Void {
		// Each arm contains @() conditional elements that register conditionalEntries. Flipping
		// arms should reclaim conditional entries from the destroyed arm.
		final result = buildFromSource("
			#test programmable(mode:[a, b]=a, flag:bool=true) {
				@switch(mode) {
					a {
						@(flag=>true) bitmap(generated(color(10, 10, #f00))): 0, 0
						@(flag=>false) bitmap(generated(color(20, 20, #00f))): 0, 0
					}
					b {
						@(flag=>true) bitmap(generated(color(30, 30, #0f0))): 0, 0
						@(flag=>false) bitmap(generated(color(40, 40, #ff0))): 0, 0
					}
				}
			}
		", "test", null, Incremental);

		final ctx = result.incrementalContext;
		Assert.notNull(ctx);
		final initialCount = ctx.getConditionalEntriesCount();

		for (i in 0...5) {
			result.setParameter("mode", "b");
			result.setParameter("mode", "a");
		}

		final finalCount = ctx.getConditionalEntriesCount();
		Assert.equals(initialCount, finalCount,
			'conditional entries leaked: $initialCount initial vs $finalCount after 10 flips');
	}

	@Test
	public function testIncrementalSwitchDynamicRefBindingsCleanedUp():Void {
		// Each arm contains a dynamicRef with parameter forwarding, which registers a
		// dynamicRefBinding. Flipping arms must drop bindings for the orphaned child contexts.
		final result = buildFromSource("
			#leaf programmable(val:uint=0) {
				bitmap(generated(color($val + 1, 10, #f00))): 0, 0
			}
			#test programmable(mode:[a, b]=a, value:uint=10) {
				@switch(mode) {
					a: dynamicRef($leaf, val=>$value): 0, 0;
					b: dynamicRef($leaf, val=>$value): 0, 0;
				}
			}
		", "test", null, Incremental);

		final ctx = result.incrementalContext;
		Assert.notNull(ctx);
		final initialCount = ctx.getDynamicRefBindingsCount();

		for (i in 0...5) {
			result.setParameter("mode", "b");
			result.setParameter("mode", "a");
		}

		final finalCount = ctx.getDynamicRefBindingsCount();
		Assert.equals(initialCount, finalCount,
			'dynamic ref bindings leaked: $initialCount initial vs $finalCount after 10 flips');

		// Sanity: parameter forwarding still works after flips
		result.setParameter("value", 25);
		Assert.equals(1, findVisibleBitmapDescendants(result.object).length);
	}

	@Test
	public function testIncrementalRepeatTrackedExpressionsCleanedUp():Void {
		// Param-dependent repeat with text interpolation: each iteration's text(...) registers a
		// tracked expression. Flipping the iteration count must reclaim tracked expressions from
		// destroyed iterations and not leak bookkeeping into the parent ctx (incrementalMode must
		// be reset to false during the rebuild closure, mirroring the initial build).
		final result = buildFromSource("
			#test programmable(count:uint=2, label:string=\"hi\") {
				repeatable($i, step($count, dx: 20)) {
					text(dd, '${label}', #fff): 0, 0
				}
			}
		", "test", null, Incremental);

		final ctx = result.incrementalContext;
		Assert.notNull(ctx);
		final initialCount = ctx.getTrackedExpressionsCount();

		for (i in 0...5) {
			result.setParameter("count", 4);
			result.setParameter("count", 2);
		}

		final finalCount = ctx.getTrackedExpressionsCount();
		Assert.equals(initialCount, finalCount,
			'tracked expressions leaked: $initialCount initial vs $finalCount after 10 flips');
	}

	@Test
	public function testIncrementalRepeatDynamicRefBindingsCleanedUp():Void {
		// Param-dependent repeat with dynamicRef in each iteration: every iteration registers a
		// dynamicRefBinding. Shrinking/growing the count must reclaim bindings for destroyed
		// iterations.
		final result = buildFromSource("
			#leaf programmable(val:uint=0) {
				bitmap(generated(color($val + 1, 10, #f00))): 0, 0
			}
			#test programmable(count:uint=2, value:uint=10) {
				repeatable($i, step($count, dx: 20)) {
					dynamicRef($leaf, val=>$value): 0, 0
				}
			}
		", "test", null, Incremental);

		final ctx = result.incrementalContext;
		Assert.notNull(ctx);
		final initialCount = ctx.getDynamicRefBindingsCount();

		for (i in 0...5) {
			result.setParameter("count", 4);
			result.setParameter("count", 2);
		}

		final finalCount = ctx.getDynamicRefBindingsCount();
		Assert.equals(initialCount, finalCount,
			'dynamic ref bindings leaked: $initialCount initial vs $finalCount after 10 flips');

		// Sanity: parameter forwarding still propagates to iteration children after flips
		result.setParameter("value", 25);
		Assert.equals(2, findVisibleBitmapDescendants(result.object).length);
	}

	@Test
	public function testIncrementalRepeatRebuildSurvivesManyFlips():Void {
		// Rebuild closure is tied to the wrapper object (3rd arg to trackExpression). Even after
		// many flips that repeatedly cleanupDestroyedSubtree the wrapper's descendants, the
		// rebuild closure itself must not be reaped — subsequent flips must still update the
		// iteration count correctly. Guards against future cleanup tightening.
		final result = buildFromSource("
			#test programmable(count:uint=2) {
				repeatable($i, step($count, dx: 20)) {
					interactive(10, 10, $i): 0, 0
				}
			}
		", "test", null, Incremental);

		Assert.equals(2, countInteractives(result), "initial count mismatch");

		for (i in 0...10) {
			result.setParameter("count", 5);
			Assert.equals(5, countInteractives(result), 'flip $i to 5: rebuild closure lost?');
			result.setParameter("count", 3);
			Assert.equals(3, countInteractives(result), 'flip $i to 3: rebuild closure lost?');
		}
	}
	#end

	// ==================== Rebuild listener API ====================
	// addRebuildListener fires once per applyUpdates cycle when any parameter changed. Used by
	// screen-side helpers to resync interactive wrappers after a @switch arm flip.

	@Test
	public function testRebuildListenerFiresOnSetParameter():Void {
		final result = buildFromSource("
			#test programmable(x:uint=10) {
				bitmap(generated(color($x, 10, #f00))): 0, 0
			}
		", "test", null, Incremental);

		var fireCount = 0;
		result.addRebuildListener(() -> fireCount++);

		Assert.equals(0, fireCount, "listener should not fire on initial build");

		result.setParameter("x", 20);
		Assert.equals(1, fireCount, "listener should fire once per setParameter");

		result.setParameter("x", 30);
		Assert.equals(2, fireCount, "listener should fire on subsequent setParameter calls");
	}

	@Test
	public function testRebuildListenerFiresOncePerBatch():Void {
		final result = buildFromSource("
			#test programmable(x:uint=10, y:uint=10) {
				bitmap(generated(color($x, $y, #f00))): 0, 0
			}
		", "test", null, Incremental);

		var fireCount = 0;
		result.addRebuildListener(() -> fireCount++);

		// Single batched update should fire listener exactly once
		result.beginUpdate();
		result.setParameter("x", 20);
		result.setParameter("y", 30);
		result.endUpdate();

		Assert.equals(1, fireCount, "batched setParameter calls should fire listener once");
	}

	@Test
	public function testRebuildListenerSeesPostRebuildState():Void {
		// Listener fires AFTER rebuild closures complete, so result.interactives reflects the new arm.
		final result = buildFromSource("
			#test programmable(mode:[a, b]=a) {
				@switch(mode) {
					a: interactive(40, 40, \"hitA\"): 0, 0;
					b: interactive(60, 60, \"hitB\"): 0, 0;
				}
			}
		", "test", null, Incremental);

		var observedIds:Array<String> = [];
		result.addRebuildListener(() -> {
			observedIds = [];
			for (obj in result.interactives) {
				switch obj.multiAnimType {
					case MAInteractive(_, _, id, _): observedIds.push(id);
					case _:
				}
			}
		});

		result.setParameter("mode", "b");
		Assert.equals(1, observedIds.length, "listener should observe exactly 1 interactive after switch");
		Assert.equals("hitB", observedIds[0], "listener should observe new arm's interactive id");

		result.setParameter("mode", "a");
		Assert.equals(1, observedIds.length);
		Assert.equals("hitA", observedIds[0]);
	}

	@Test
	public function testRebuildListenerRemove():Void {
		final result = buildFromSource("
			#test programmable(x:uint=10) {
				bitmap(generated(color($x, 10, #f00))): 0, 0
			}
		", "test", null, Incremental);

		var fireCount = 0;
		final listener = () -> fireCount++;
		result.addRebuildListener(listener);

		result.setParameter("x", 20);
		Assert.equals(1, fireCount);

		result.removeRebuildListener(listener);
		result.setParameter("x", 30);
		Assert.equals(1, fireCount, "removed listener should not fire");
	}

	@Test
	public function testRebuildListenerThrowsInNonIncrementalMode():Void {
		// Non-incremental BuilderResult is a static snapshot — addRebuildListener/removeRebuildListener
		// throw so the mismatch surfaces at wiring time rather than letting dependent setParameter
		// calls blow up later. Callers (e.g. UIScreen.addInteractives, UICardHandHelper) must gate
		// on `isIncremental` before subscribing.
		final result = buildFromSource("
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "test"); // no Incremental flag

		Assert.isFalse(result.isIncremental, "static snapshot should report isIncremental=false");

		var threw = false;
		try {
			result.addRebuildListener(() -> {});
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "addRebuildListener should throw on non-incremental result");

		threw = false;
		try {
			result.removeRebuildListener(() -> {});
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "removeRebuildListener should throw on non-incremental result");
	}

	@Test
	public function testReentrantSetParameterInRebuildListener():Void {
		// Re-entrancy contract (MultiAnimBuilder.hx:1302-1312): rebuild listeners fire
		// AFTER popBuilderState/changedParams.clear/hasChanges=false, so a listener that
		// calls setParameter() on the same context enters a fresh applyUpdates cycle.
		// Verify: the re-entrant setParameter propagates to the bitmap size, no crash,
		// no infinite recursion, and both params end up applied.
		final result = buildFromSource("
			#test programmable(x:uint=10, y:uint=10) {
				bitmap(generated(color($x, $y, #f00))): 0, 0
			}
		", "test", null, Incremental);

		var fireCount = 0;
		var reentrantSetDone = false;
		result.addRebuildListener(() -> {
			fireCount++;
			// On the first rebuild (triggered by setParameter("x", 20) below),
			// call setParameter("y", 50) re-entrantly. This enters a fresh applyUpdates
			// cycle that must complete cleanly — producing a second listener tick.
			if (!reentrantSetDone) {
				reentrantSetDone = true;
				result.setParameter("y", 50);
			}
		});

		result.setParameter("x", 20);

		// Expect exactly two fires: outer (x=20) + re-entrant (y=50). An infinite
		// recursion would blow the stack; a swallowed re-entry would leave fireCount=1.
		Assert.equals(2, fireCount, "listener should fire twice: outer + re-entrant");

		// Final render must reflect BOTH params — the re-entrant setParameter must
		// have propagated through the bitmap expression.
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width), "x=20 applied");
		Assert.equals(50, Std.int(bitmaps[0].tile.height), "y=50 applied via re-entrant setParameter");
	}

	@Test
	public function testReentrantSetParameterDuringSwitchRebuild():Void {
		// Card-hand-style reproducer: listener fires when a @switch arm flips, and the
		// listener reacts by pushing a param change on the same context. Must not crash,
		// must apply the re-entrant change, and bindings on the new arm must be coherent.
		final result = buildFromSource("
			#test programmable(mode:[a, b]=a, label:uint=1) {
				@switch(mode) {
					a: bitmap(generated(color($label * 5, 10, #f00))): 0, 0;
					b: bitmap(generated(color($label * 7, 10, #0f0))): 0, 0;
				}
			}
		", "test", null, Incremental);

		var fireCount = 0;
		var reentrantDone = false;
		result.addRebuildListener(() -> {
			fireCount++;
			// When switching to arm b, re-entrantly push a new label value. The fresh
			// applyUpdates cycle must re-evaluate the new arm's bitmap expression.
			if (!reentrantDone) {
				reentrantDone = true;
				result.setParameter("label", 4);
			}
		});

		result.setParameter("mode", "b");

		Assert.equals(2, fireCount, "listener should fire twice: switch flip + re-entrant label change");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length, "only the new arm's bitmap should be visible");
		Assert.equals(28, Std.int(bitmaps[0].tile.width), "arm b with label=4 => width=4*7=28");
	}

	@Test
	public function testIncrementalSwitchFixedRepeatableDifferentCounts():Void {
		// Arms have different fixed repeatable counts — switching should change count
		final result = buildFromSource("
			#test programmable(style:[circles, squares]=circles) {
				@switch(style) {
					circles {
						repeatable($i, step(4, dx: 15)) {
							bitmap(generated(color(10, 10, #00f))): 0, 0
						}
					}
					squares {
						repeatable($i, step(2, dx: 15)) {
							bitmap(generated(color(30, 10, #ff0))): 0, 0
						}
					}
				}
			}
		", "test", null, Incremental);

		// Initial: circles → 4 blue bitmaps (10px)
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(4, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Switch to squares → 2 yellow bitmaps (30px)
		result.setParameter("style", "squares");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));

		// Switch back to circles → 4 blue bitmaps again
		result.setParameter("style", "circles");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(4, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalSwitchTextInterpolation():Void {
		// $param interpolation inside @switch arm — rebuild must re-evaluate text
		final params = new Map<String, Dynamic>();
		params.set("mode", "hp");
		params.set("value", 42);
		final result = buildFromSource("
			#test programmable(mode:[hp, mp]=hp, value:uint=0) {
				@switch(mode) {
					hp: text(dd, 'HP: ${value}', #f00): 0, 0;
					mp: text(dd, 'MP: ${value}', #00f): 0, 0;
				}
			}
		", "test", params, Incremental);
		var texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		Assert.equals("HP: 42", texts[0].text);

		// Change value only (stay in same arm) — text should update
		result.setParameter("value", 99);
		texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		Assert.equals("HP: 99", texts[0].text);

		// Switch arm AND change value in batch
		result.beginUpdate();
		result.setParameter("mode", "mp");
		result.setParameter("value", 7);
		result.endUpdate();
		texts = findAllTextDescendants(result.object);
		Assert.equals(1, texts.length);
		Assert.equals("MP: 7", texts[0].text);
	}

	@Test
	public function testIncrementalSwitchNestedConditional():Void {
		// @() conditionals inside @switch arms — switching arm AND toggling inner conditional
		final result = buildFromSource("
			#test programmable(mode:[a, b]=a, flag:bool=true) {
				@switch(mode) {
					a {
						@(flag=>true) bitmap(generated(color(10, 10, #0f0))): 0, 0;
						@(flag=>false) bitmap(generated(color(20, 10, #f00))): 0, 0;
					}
					b {
						bitmap(generated(color(30, 10, #00f))): 0, 0;
					}
				}
			}
		", "test", null, Incremental);
		// Initial: mode=a, flag=true → 10px green
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Toggle flag → 20px red (still in arm a)
		result.setParameter("flag", false);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Switch to b → 30px blue (flag irrelevant)
		result.setParameter("mode", "b");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));

		// Switch back to a with flag=false → 20px red
		result.setParameter("mode", "a");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalSwitchParamInPosition():Void {
		// $param used in position coordinates inside @switch arm
		final result = buildFromSource("
			#test programmable(mode:[left, right]=left, offset:uint=10) {
				@switch(mode) {
					left: bitmap(generated(color(10, 10, #f00))): $offset, 0;
					right: bitmap(generated(color(10, 10, #0f0))): $offset + 100, 0;
				}
			}
		", "test", null, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].x));

		// Change offset (stay in same arm) — position should update
		result.setParameter("offset", 50);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(50, Std.int(bitmaps[0].x));

		// Switch arm — right arm uses offset+100
		result.setParameter("mode", "right");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(150, Std.int(bitmaps[0].x));
	}

	@Test
	public function testIncrementalSwitchInsideConditional():Void {
		// @switch nested inside @() conditional — outer conditional hides the switch
		final result = buildFromSource("
			#test programmable(enabled:bool=true, mode:[a, b]=a) {
				@(enabled=>true) {
					@switch(mode) {
						a: bitmap(generated(color(10, 10, #0f0))): 0, 0;
						b: bitmap(generated(color(20, 10, #f00))): 0, 0;
					}
				}
				@(enabled=>false) bitmap(generated(color(5, 5, #888))): 0, 0;
			}
		", "test", null, Incremental);
		// Initial: enabled=true, mode=a → 10px green
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Disable → switch hidden, 5px gray shown
		result.setParameter("enabled", false);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(5, Std.int(bitmaps[0].tile.width));

		// Switch mode while disabled — should not affect visible output
		result.setParameter("mode", "b");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(5, Std.int(bitmaps[0].tile.width));

		// Re-enable → should show mode=b arm (20px red)
		result.setParameter("enabled", true);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalSwitchNestedSwitch():Void {
		// Nested @switch: outer on one param, inner on another
		final result = buildFromSource("
			#test programmable(shape:[circle, square]=circle, size:[small, big]=small) {
				@switch(shape) {
					circle {
						@switch(size) {
							small: bitmap(generated(color(10, 10, #0f0))): 0, 0;
							big: bitmap(generated(color(20, 20, #0f0))): 0, 0;
						}
					}
					square {
						@switch(size) {
							small: bitmap(generated(color(10, 10, #f00))): 0, 0;
							big: bitmap(generated(color(20, 20, #f00))): 0, 0;
						}
					}
				}
			}
		", "test", null, Incremental);
		// Initial: circle+small → 10x10 green
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
		Assert.equals(10, Std.int(bitmaps[0].tile.height));

		// Change inner param (size) only
		result.setParameter("size", "big");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
		Assert.equals(20, Std.int(bitmaps[0].tile.height));

		// Change outer param (shape) — inner should reflect current size=big
		result.setParameter("shape", "square");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Change both at once
		result.beginUpdate();
		result.setParameter("shape", "circle");
		result.setParameter("size", "small");
		result.endUpdate();
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalSwitchNoArmMatches():Void {
		// When no arm matches and there's no default — container should be empty
		final params = new Map<String, Dynamic>();
		params.set("value", 50);
		final result = buildFromSource("
			#test programmable(value:0..100=0) {
				bitmap(generated(color(5, 5, #888))): 0, 0;
				@switch(value) {
					<= 10: bitmap(generated(color(10, 10, #0f0))): 0, 20;
					>= 90: bitmap(generated(color(10, 10, #f00))): 0, 20;
				}
			}
		", "test", params, Incremental);
		// value=50 → no arm matches, only the unconditional bitmap shows
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(5, Std.int(bitmaps[0].tile.width));

		// value=5 → <= 10 arm matches, two bitmaps visible
		result.setParameter("value", 5);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);

		// value=50 → back to no match, only unconditional bitmap
		result.setParameter("value", 50);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(5, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testIncrementalSwitchParamExprInBitmapSize():Void {
		// $param expression used in bitmap generated size inside @switch
		final result = buildFromSource("
			#test programmable(mode:[a, b]=a, size:uint=10) {
				@switch(mode) {
					a: bitmap(generated(color($size, $size, #0f0))): 0, 0;
					b: bitmap(generated(color($size * 2, $size * 2, #f00))): 0, 0;
				}
			}
		", "test", null, Incremental);
		// Initial: mode=a, size=10 → 10x10
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Change size to 20 (stay in arm a) → 20x20
		result.setParameter("size", 20);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Switch to b with size=20 → 40x40
		result.setParameter("mode", "b");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(40, Std.int(bitmaps[0].tile.width));

		// Change size to 5 in arm b → 10x10
		result.setParameter("size", 5);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	// ==================== BuilderError sibling-file migration ====================

	/** Regression: errors raised from `MultiAnimLayouts` — one of the sibling builder
	 *  files previously throwing plain strings — now throw `BuilderError` so they
	 *  reach the same structured-diagnostic surface as `MultiAnimBuilder.hx` errors.
	 *  Guards against someone regressing a `BuilderError.of(...)` back to a plain
	 *  `throw '...'` in that file. Also asserts `catch (e:Dynamic)` still matches
	 *  for backward compat with consumers that don't know about BuilderError. */
	@Test
	public function testSiblingBuilderErrorIsTyped():Void {
		final source = "
			layouts {
				#realLayout list {
					point: 0, 0
					point: 10, 0
				}
			}
			#test programmable() {
				repeatable($i, layout(\"nonexistentLayout\")) {
					bitmap(generated(color(8, 8, red))): 0, 0
				}
			}
		";
		var caughtTyped = false;
		var caughtDynamic = false;
		var message:String = null;
		try {
			buildFromSource(source, "test");
		} catch (e:bh.multianim.BuilderError) {
			caughtTyped = true;
			message = e.message;
		} catch (e:Dynamic) {
			caughtDynamic = true;
		}
		Assert.isTrue(caughtTyped, "MultiAnimLayouts error should be a BuilderError");
		Assert.isFalse(caughtDynamic, "Typed catch should run before fallback");
		Assert.notNull(message);
		Assert.isTrue(message.indexOf("nonexistentLayout") >= 0,
			'Message should mention the missing layout name, got: $message');
		Assert.isTrue(message.indexOf("not found") >= 0,
			'Message should preserve original "not found" text, got: $message');
	}

	// ==================== TileGroup + mutable-conditional rejection ====================

	// tileGroup bakes children into a single drawable at build time and is never re-entered
	// by the incremental-update path (buildTileGroup has no trackConditional hook). A
	// conditional whose predicate references a programmable parameter therefore silently
	// freezes on first build, and in incremental mode @else/@default arms bake alongside
	// the matching @() arm because resolveConditionalChildren returns all children when
	// incrementalMode=true (expecting the main build() path to re-filter later).
	//
	// Fix: reject these configurations at build time with a structured BuilderError
	// (code="tilegroup_conditional"). Loop vars introduced by repeatable/repeatable2d
	// INSIDE the tileGroup are still fine — those iterate at build time.

	static function buildExpectingTileGroupConditional(source:String):String {
		try {
			buildFromSource(source, "test");
			return null;
		} catch (e:bh.multianim.BuilderError) {
			Assert.equals("tilegroup_conditional", e.code,
				'Expected BuilderError code="tilegroup_conditional", got "${e.code}" with message: ${e.message}');
			return e.message;
		} catch (e:Dynamic) {
			Assert.fail('Expected BuilderError, got: ${Std.string(e)}');
			return null;
		}
	}

	@Test
	public function testTileGroupConditionalOnParam_Builder_Throws():Void {
		final msg = buildExpectingTileGroupConditional("
			#test programmable(mode:[a,b]=a) {
				tileGroup {
					@(mode=>a) bitmap(generated(color(20, 20, red))): 0, 0
					@(mode=>b) bitmap(generated(color(20, 20, blue))): 0, 0
				}
			}
		");
		Assert.notNull(msg);
		Assert.isTrue(msg.indexOf("tileGroup") >= 0 || msg.indexOf("tilegroup") >= 0,
			'Message should mention tileGroup, got: $msg');
		Assert.isTrue(msg.indexOf("mode") >= 0,
			'Message should name the offending parameter "mode", got: $msg');
	}

	@Test
	public function testTileGroupConditionalOnParam_Incremental_Throws():Void {
		// Incremental mode is where the @else double-bake also manifests — same rejection path
		var msg:String = null;
		try {
			buildFromSource("
				#test programmable(mode:[a,b]=a) {
					tileGroup {
						@(mode=>a) bitmap(generated(color(20, 20, red))): 0, 0
						@else bitmap(generated(color(20, 20, blue))): 0, 0
					}
				}
			", "test", null, Incremental);
		} catch (e:bh.multianim.BuilderError) {
			Assert.equals("tilegroup_conditional", e.code, 'code should be tilegroup_conditional, got "${e.code}"');
			msg = e.message;
		} catch (e:Dynamic) {
			Assert.fail('Expected BuilderError, got: ${Std.string(e)}');
		}
		Assert.notNull(msg, "Incremental build of tileGroup + @()/@else on a param must throw");
	}

	@Test
	public function testTileGroupElseOnParam_Throws():Void {
		// Bare @else following a mutable-param @() is equally broken — the @() site throws first.
		final msg = buildExpectingTileGroupConditional("
			#test programmable(mode:[a,b]=a) {
				tileGroup {
					@(mode=>a) bitmap(generated(color(20, 20, red))): 0, 0
					@default bitmap(generated(color(20, 20, blue))): 0, 0
				}
			}
		");
		Assert.notNull(msg);
	}

	@Test
	public function testTileGroupSwitchOnParam_Throws():Void {
		// @switch(param) on a mutable param inside tileGroup — same problem, the arm is
		// resolved once at build time via resolveMatchedSwitchArm and never re-evaluated.
		final msg = buildExpectingTileGroupConditional("
			#test programmable(kind:[a,b,c]=a) {
				tileGroup {
					@switch(kind) {
						a: bitmap(generated(color(20, 20, red))): 0, 0;
						b: bitmap(generated(color(20, 20, green))): 0, 0;
						default: bitmap(generated(color(20, 20, blue))): 0, 0;
					}
				}
			}
		");
		Assert.notNull(msg);
		Assert.isTrue(msg.indexOf("kind") >= 0, 'Should name the offending parameter "kind", got: $msg');
	}

	@Test
	public function testTileGroupConditionalOnRepeatableLoopVar_Allowed():Void {
		// Loop vars introduced by a repeatable INSIDE the tileGroup iterate at build time —
		// conditionals referencing them are safe and must still be accepted.
		final result = buildFromSource("
			#test programmable() {
				tileGroup {
					repeatable($i, step(3, dx: 20, dy: 0)) {
						@($i => 0) bitmap(generated(color(20, 20, red))): 0, 0
						@($i => 1) bitmap(generated(color(20, 20, green))): 0, 0
						@($i => 2) bitmap(generated(color(20, 20, blue))): 0, 0
					}
				}
			}
		", "test");
		Assert.notNull(result, "Loop-var conditionals inside tileGroup must still build");
	}

	@Test
	public function testTileGroupConditionalOnFinal_Throws():Void {
		// @final as conditional key is broken system-wide (matchSingleCondition has no
		// ExpressionAlias case), but the tileGroup validator catches it early and labels
		// the name as "@final" rather than the generic "parameter" — better diagnostic.
		final msg = buildExpectingTileGroupConditional("
			#test programmable() {
				@final MODE = 1
				tileGroup {
					@(MODE => 1) bitmap(generated(color(20, 20, red))): 0, 0
				}
			}
		");
		Assert.notNull(msg);
		Assert.isTrue(msg.indexOf("@final") >= 0,
			'Message should label "MODE" as @final (not parameter), got: $msg');
		Assert.isTrue(msg.indexOf("MODE") >= 0,
			'Message should name the offending @final "MODE", got: $msg');
		Assert.isTrue(msg.indexOf("parameter") < 0,
			'Message should NOT misclassify an @final as parameter, got: $msg');
	}

	@Test
	public function testTileGroupOuterConditionalOnParam_NotFlagged():Void {
		// Conditionals on the tileGroup NODE ITSELF (outside the baked subtree) are re-entered
		// by the main build() path on incremental rebuild and handled the normal way. Only
		// conditionals on tileGroup's DESCENDANTS are the silent-no-op trap.
		final result = buildFromSource("
			#test programmable(show:bool=true) {
				@(show=>true) tileGroup {
					bitmap(generated(color(20, 20, red))): 0, 0
				}
			}
		", "test");
		Assert.notNull(result, "A conditional on the tileGroup itself is fine — only its descendants are baked");
	}

	// ==================== Batch update contract ====================

	// Batching is designed as single-level: one outer beginUpdate, one matching endUpdate.
	// Nested begin or dangling end used to silently corrupt state (inner begin cleared the
	// outer's pending diffs; inner end flipped batchMode off mid-scope). Both now throw a
	// structured BuilderError so the misuse surfaces immediately.

	@Test
	public function testBatchNestedBeginUpdateThrows():Void {
		final result = buildFromSource("
			#test programmable(x:uint=1) {
				bitmap(generated(color($x * 10, 10, #f00))): 0, 0
			}
		", "test", null, Incremental);
		result.beginUpdate();
		var caught:Null<bh.multianim.BuilderError> = null;
		try {
			result.beginUpdate();
		} catch (e:bh.multianim.BuilderError) {
			caught = e;
		}
		Assert.notNull(caught, "Nested beginUpdate must throw");
		Assert.equals("nested_begin_update", caught.code);
		// Restore state so the outer batch can still end cleanly.
		result.endUpdate();
	}

	@Test
	public function testBatchEndUpdateWithoutBeginThrows():Void {
		final result = buildFromSource("
			#test programmable(x:uint=1) {
				bitmap(generated(color($x * 10, 10, #f00))): 0, 0
			}
		", "test", null, Incremental);
		var caught:Null<bh.multianim.BuilderError> = null;
		try {
			result.endUpdate();
		} catch (e:bh.multianim.BuilderError) {
			caught = e;
		}
		Assert.notNull(caught, "endUpdate without matching beginUpdate must throw");
		Assert.equals("unbalanced_end_update", caught.code);
	}

	@Test
	public function testBatchFlatPairStillWorks():Void {
		// Regression guard: the non-reentrancy assertions must not break the single-level
		// happy path — a flat begin/setParameter*/end cycle still batches and applies once.
		final result = buildFromSource("
			#test programmable(w:uint=10, h:uint=10) {
				bitmap(generated(color($w, $h, #f00))): 0, 0
			}
		", "test", null, Incremental);
		result.beginUpdate();
		result.setParameter("w", 30);
		result.setParameter("h", 20);
		result.endUpdate();
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
		Assert.equals(20, Std.int(bitmaps[0].tile.height));

		// And a second cycle on the same result — end cleared state, begin works again.
		result.beginUpdate();
		result.setParameter("w", 5);
		result.endUpdate();
		final bitmaps2 = findVisibleBitmapDescendants(result.object);
		Assert.equals(5, Std.int(bitmaps2[0].tile.width));
	}

	// ==================== setParameter value-type validation ====================

	// Pre-fix, setParameter walked an isOfType cascade and silently fell through when
	// no branch matched — but still flipped changedParams/hasChanges, so dependent
	// listeners re-ran against a stale indexedParams entry. Now: known param + no
	// matching conversion branch = structured BuilderError with "invalid_param_value".
	// Unknown param names stay silent (UI widgets rely on optional `disabled` param).

	@Test
	public function testSetParameterInvalidValueTypeThrows():Void {
		final result = buildFromSource("
			#test programmable(x:uint=1) {
				bitmap(generated(color($x * 10, 10, #f00))): 0, 0
			}
		", "test", null, Incremental);
		// Pass an array — doesn't match Int/Float/String/Bool/ResolvedIndexParameters/h2d.Tile.
		var caught:Null<bh.multianim.BuilderError> = null;
		try {
			result.setParameter("x", [1, 2, 3]);
		} catch (e:bh.multianim.BuilderError) {
			caught = e;
		}
		Assert.notNull(caught, "Array value on declared param must throw");
		Assert.equals("invalid_param_value", caught.code);
		Assert.isTrue(caught.message.indexOf("\"x\"") >= 0, 'Message should name the param, got: ${caught.message}');
	}

	@Test
	public function testSetParameterNullValueThrows():Void {
		// null is the classic silent-skip trigger: isOfType(null, T) is false for every T.
		// Pre-fix this corrupted `changedParams` without touching `indexedParams`.
		final result = buildFromSource("
			#test programmable(x:uint=1) {
				bitmap(generated(color($x * 10, 10, #f00))): 0, 0
			}
		", "test", null, Incremental);
		var caught:Null<bh.multianim.BuilderError> = null;
		try {
			result.setParameter("x", null);
		} catch (e:bh.multianim.BuilderError) {
			caught = e;
		}
		Assert.notNull(caught, "null value on declared param must throw");
		Assert.equals("invalid_param_value", caught.code);
	}

	@Test
	public function testSetParameterInvalidValueDoesNotFireRebuildListeners():Void {
		// The exact bug H1 described: even when no branch matched, the old code
		// set changedParams/hasChanges, which meant listeners re-fired on the
		// unchanged indexedParams. Now: the throw happens before that flag flip,
		// so listeners stay silent.
		final result = buildFromSource("
			#test programmable(x:uint=1) {
				bitmap(generated(color($x * 10, 10, #f00))): 0, 0
			}
		", "test", null, Incremental);
		var listenerFireCount = 0;
		result.addRebuildListener(() -> listenerFireCount++);
		try { result.setParameter("x", [1, 2, 3]); } catch (_) {}
		Assert.equals(0, listenerFireCount,
			"Rebuild listeners must not fire when setParameter rejected the value type");
	}

	@Test
	public function testSetParameterUnknownParamIsSilentNoOp():Void {
		// UI widgets (Button, Checkbox, Slider, Tabs, TextInput) call
		// setParameter("disabled", ...) on every instance — templates that don't
		// opt into a `disabled` param rely on a no-op. Assert that contract.
		final result = buildFromSource("
			#test programmable(x:uint=10) {
				bitmap(generated(color($x, 10, #f00))): 0, 0
			}
		", "test", null, Incremental);
		var listenerFireCount = 0;
		result.addRebuildListener(() -> listenerFireCount++);
		// No throw, no listener fire — param just isn't there.
		result.setParameter("notDeclared", "whatever");
		Assert.equals(0, listenerFireCount,
			"Unknown param must not fire rebuild listeners (no dependent expressions)");
		// Declared param still works afterward — the silent skip didn't corrupt state.
		result.setParameter("x", 20);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	// setParameter must coerce primitive values to the ResolvedIndexParameters shape
	// that paramDef.type expects — not pick a shape from the Haxe runtime type of
	// value alone. Pre-fix, only PPTFlags routed through dynamicValueToIndex; every
	// other typed param silently stored the wrong shape (StringValue on PPTBool,
	// ValueF on PPTInt, StringValue on PPTColor, ...), and the mismatch only
	// surfaced on the next matchSingleCondition call with a confusing
	// "invalid param types" throw nowhere near the offending setParameter.

	@Test
	public function testSetParameterStringBoolOnBoolParamMatchesConditional():Void {
		// Internal callers (UIMultiAnimTextInput.syncPlaceholder,
		// UIMultiAnimScrollableList) pass "true"/"false" strings to PPTBool params.
		// Parser bakes @(flag=>true) to CoValue(1) and @(flag=>false) to CoValue(0).
		// Pre-fix, StringValue("false") hit the default throw in the CoValue arm
		// of matchSingleCondition.
		final result = buildFromSource("
			#test programmable(flag:bool=true) {
				@(flag=>true)  bitmap(generated(color(11, 10, #fff)))
				@(flag=>false) bitmap(generated(color(22, 10, #fff)))
			}
		", "test", null, Incremental);
		// Default: flag=true → 11px arm visible
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(11, Std.int(bitmaps[0].tile.width));

		// Switch to "false" via string — must coerce to Value(0) so CoValue(0) matches.
		result.setParameter("flag", "false");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(22, Std.int(bitmaps[0].tile.width));

		// And back to "true".
		result.setParameter("flag", "true");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(11, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testSetParameterFloatOnIntParamMatchesConditional():Void {
		// setParameter("n", 5.0) on a PPTInt param stored ValueF(5.0); CoValue(5)
		// only matches Value(_) and threw "invalid param types ValueF(5), CoValue(5)".
		final result = buildFromSource("
			#test programmable(n:int=0) {
				@(n=>0) bitmap(generated(color(11, 10, #fff)))
				@(n=>5) bitmap(generated(color(22, 10, #fff)))
			}
		", "test", null, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(11, Std.int(bitmaps[0].tile.width));

		// Float input for an int param must coerce to Value(5).
		result.setParameter("n", 5.0);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(22, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testSetParameterStringIntOnIntParamMatchesConditional():Void {
		// String digits on PPTInt must coerce to Value(int), not StringValue.
		final result = buildFromSource("
			#test programmable(n:int=0) {
				@(n=>0) bitmap(generated(color(11, 10, #fff)))
				@(n=>7) bitmap(generated(color(22, 10, #fff)))
			}
		", "test", null, Incremental);
		result.setParameter("n", "7");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(22, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testSetParameterCssHexStringOnColorParamBakesAlpha():Void {
		// CSS-form color strings passed via setParameter must alpha-bake the same
		// way the parser does for `#RRGGBB` literals in conditionals, otherwise
		// @(tint=>#FF0000) (baked to CoValue(0xFFFF0000)) can never match a
		// setParameter("tint", "#FF0000") that stores StringValue("#FF0000").
		// NOTE: Int inputs to PPTColor keep strict-D semantics (top byte = alpha).
		final result = buildFromSource("
			#test programmable(tint:color=#00FF00) {
				@(tint=>#FF0000) bitmap(generated(color(22, 10, #fff)))
				@(tint=>#00FF00) bitmap(generated(color(11, 10, #fff)))
			}
		", "test", null, Incremental);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(11, Std.int(bitmaps[0].tile.width));

		// CSS shorthand input → alpha-baked Value(0xFFFF0000).
		result.setParameter("tint", "#FF0000");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(22, Std.int(bitmaps[0].tile.width));
	}

}
