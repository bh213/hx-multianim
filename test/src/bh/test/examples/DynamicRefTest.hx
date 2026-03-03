package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.BuildMode;
import bh.test.BuilderTestBase.buildFromSource;
import bh.test.BuilderTestBase.findVisibleBitmapDescendants;

/**
 * Unit tests for dynamicRef element:
 * basic build, getDynamicRef, setParameter propagation, nested refs,
 * beginUpdate/endUpdate, scope isolation, error cases.
 */
class DynamicRefTest extends BuilderTestBase {
	// ==================== Basic Build ====================

	@Test
	public function testBasicDynamicRefBuilds():Void {
		final result = buildFromSource("
			#inner programmable() {
				bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
			#test programmable() {
				dynamicRef($inner): 0, 0
			}
		", "test");
		Assert.notNull(result);
		Assert.isTrue(result.object.numChildren > 0);
	}

	@Test
	public function testGetDynamicRefReturnsSubResult():Void {
		final result = buildFromSource("
			#inner programmable() {
				bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
			#test programmable() {
				dynamicRef($inner): 0, 0
			}
		", "test");
		var subResult = result.getDynamicRef("inner");
		Assert.notNull(subResult);
		if (subResult == null) return;
		Assert.notNull(subResult.object);
	}

	// ==================== Parameter Passing ====================

	@Test
	public function testDynamicRefWithParams():Void {
		final result = buildFromSource("
			#bar programmable(val:uint=100, maxVal:uint=100) {
				bitmap(generated(color($val, $maxVal, #ff0000))): 0, 0
			}
			#test programmable(hp:uint=80, maxHp:uint=100) {
				dynamicRef($bar, val=>$hp, maxVal=>$maxHp): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		Assert.isTrue(result.object.numChildren > 0);
	}

	@Test
	public function testDynamicRefSetParameter():Void {
		final result = buildFromSource("
			#bar programmable(val:uint=100, maxVal:uint=100) {
				bitmap(generated(color($val, $maxVal, #ff0000))): 0, 0
			}
			#test programmable(hp:uint=100, maxHp:uint=100) {
				dynamicRef($bar, val=>$hp, maxVal=>$maxHp): 0, 0
			}
		", "test", null, Incremental);

		// Change parameter on parent — should propagate
		result.beginUpdate();
		result.setParameter("hp", 50);
		result.endUpdate();
		Assert.isTrue(result.object.numChildren > 0);
	}

	@Test
	public function testDynamicRefSetParameterOnSubResult():Void {
		final result = buildFromSource("
			#inner programmable(color:[red,green]=red) {
				@(color => red) bitmap(generated(color(10, 10, #ff0000))): 0, 0
				@(color => green) bitmap(generated(color(10, 10, #00ff00))): 0, 0
			}
			#test programmable() {
				dynamicRef($inner): 0, 0
			}
		", "test", null, Incremental);
		var subResult = result.getDynamicRef("inner");
		Assert.notNull(subResult);
		if (subResult == null) return;
		// setParameter on the sub-result
		subResult.setParameter("color", "green");
		Assert.isTrue(true); // If we got here, no exception
	}

	// ==================== Multiple Dynamic Refs ====================

	@Test
	public function testMultipleDynamicRefs():Void {
		final result = buildFromSource("
			#widgetA programmable() {
				bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
			#widgetB programmable() {
				bitmap(generated(color(10, 10, #00ff00))): 0, 0
			}
			#test programmable() {
				dynamicRef($widgetA): 0, 0
				dynamicRef($widgetB): 0, 20
			}
		", "test");
		Assert.notNull(result);
		var refA = result.getDynamicRef("widgetA");
		var refB = result.getDynamicRef("widgetB");
		Assert.notNull(refA);
		Assert.notNull(refB);
	}

	// ==================== Nested Dynamic Refs ====================

	@Test
	public function testNestedDynamicRef():Void {
		final result = buildFromSource("
			#leaf programmable() {
				bitmap(generated(color(5, 5, #0000ff))): 0, 0
			}
			#middle programmable() {
				dynamicRef($leaf): 0, 0
			}
			#test programmable() {
				dynamicRef($middle): 0, 0
			}
		", "test");
		Assert.notNull(result);
		Assert.isTrue(result.object.numChildren > 0);
	}

	// ==================== Error Cases ====================

	@Test
	public function testGetDynamicRefNotFoundThrows():Void {
		final result = buildFromSource("
			#inner programmable() {
				bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
			#test programmable() {
				dynamicRef($inner): 0, 0
			}
		", "test");
		var err:String = null;
		try {
			result.getDynamicRef("nonexistent");
		} catch (e:Dynamic) {
			err = Std.string(e);
		}
		Assert.notNull(err);
		Assert.isTrue(err.indexOf("nonexistent") >= 0);
	}

	// ==================== beginUpdate / endUpdate ====================

	@Test
	public function testBeginEndUpdateBatch():Void {
		final result = buildFromSource("
			#bar programmable(val:uint=100, maxVal:uint=100) {
				bitmap(generated(color($val, $maxVal, #ff0000))): 0, 0
			}
			#test programmable(hp:uint=100, maxHp:uint=100) {
				dynamicRef($bar, val=>$hp, maxVal=>$maxHp): 0, 0
			}
		", "test", null, Incremental);

		// Batch update: change multiple params at once
		result.beginUpdate();
		result.setParameter("hp", 30);
		result.setParameter("maxHp", 50);
		result.endUpdate();
		Assert.isTrue(result.object.numChildren > 0);
	}

	// ==================== Static Value Params ====================

	@Test
	public function testDynamicRefWithStaticValues():Void {
		// Dynamic ref can pass static values (not $references)
		final result = buildFromSource("
			#inner programmable(w:uint=10, h:uint=10) {
				bitmap(generated(color($w, $h, #ff0000))): 0, 0
			}
			#test programmable() {
				dynamicRef($inner, w=>20, h=>30): 0, 0
			}
		", "test");
		Assert.notNull(result);
		// The inner programmable should have w=20, h=30
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
		Assert.equals(30, Std.int(bitmaps[0].tile.height));
	}

	// ==================== Edge Cases ====================

	@Test
	public function testDynamicRefConditionalBranch():Void {
		final result = buildFromSource("
			#inner programmable() {
				bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
			#test programmable(show:bool=true) {
				@(show => true) dynamicRef($inner): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		// Inner should be built when show=true
		Assert.isTrue(result.object.numChildren > 0);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
	}

	@Test
	public function testDynamicRefInRepeatable():Void {
		final result = buildFromSource("
			#inner programmable() {
				bitmap(generated(color(5, 5, #00ff00))): 0, 0
			}
			#test programmable() {
				repeatable($i, step(3, dy: 10)) {
					dynamicRef($inner): 0, 0
				}
			}
		", "test");
		Assert.notNull(result);
		// Should build 3 instances
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length >= 3);
	}

	@Test
	public function testDynamicRefWithEnumParam():Void {
		final result = buildFromSource("
			#inner programmable(mode:[a,b,c]=a) {
				@(mode => a) bitmap(generated(color(10, 10, #ff0000))): 0, 0
				@(mode => b) bitmap(generated(color(10, 10, #00ff00))): 0, 0
				@(mode => c) bitmap(generated(color(10, 10, #0000ff))): 0, 0
			}
			#test programmable(m:[a,b,c]=b) {
				dynamicRef($inner, mode=>$m): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		Assert.isTrue(result.object.numChildren > 0);
	}

	@Test
	public function testDynamicRefSetParamUpdatesChild():Void {
		final result = buildFromSource("
			#inner programmable(visible:bool=true) {
				@(visible => true) bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
			#test programmable(show:bool=true) {
				dynamicRef($inner, visible=>$show): 0, 0
			}
		", "test", null, Incremental);
		// Toggle parent parameter
		result.beginUpdate();
		result.setParameter("show", false);
		result.endUpdate();
		// Should not crash
		Assert.isTrue(true);
	}

	@Test
	public function testDynamicRefWithBoolParam():Void {
		final result = buildFromSource("
			#inner programmable(active:bool=false) {
				@(active => true) bitmap(generated(color(10, 10, #00ff00))): 0, 0
				@(active => false) bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
			#test programmable(flag:bool=true) {
				dynamicRef($inner, active=>$flag): 0, 0
			}
		", "test");
		Assert.notNull(result);
		Assert.isTrue(result.object.numChildren > 0);
	}

	@Test
	public function testDeepNestedGetSubResult():Void {
		final result = buildFromSource("
			#leaf programmable() {
				bitmap(generated(color(5, 5, #0000ff))): 0, 0
			}
			#mid programmable() {
				dynamicRef($leaf): 0, 0
			}
			#test programmable() {
				dynamicRef($mid): 0, 0
			}
		", "test");
		var midRef = result.getDynamicRef("mid");
		Assert.notNull(midRef);
		var leafRef = midRef.getDynamicRef("leaf");
		Assert.notNull(leafRef);
		Assert.notNull(leafRef.object);
	}

	@Test
	public function testDynamicRefChainedGetDynamicRef():Void {
		final result = buildFromSource("
			#leaf programmable() {
				bitmap(generated(color(3, 3, #ff00ff))): 0, 0
			}
			#mid programmable() {
				dynamicRef($leaf): 0, 0
			}
			#test programmable() {
				dynamicRef($mid): 0, 0
			}
		", "test");
		// Chain: test -> mid -> leaf
		var leafRef = result.getDynamicRef("mid").getDynamicRef("leaf");
		Assert.notNull(leafRef);
		var bitmaps = findVisibleBitmapDescendants(leafRef.object);
		Assert.isTrue(bitmaps.length > 0);
	}
}
