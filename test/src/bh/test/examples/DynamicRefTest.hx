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
		// Capture visible bitmaps before parameter change
		var bitmapsBefore = findVisibleBitmapDescendants(subResult.object);
		Assert.isTrue(bitmapsBefore.length > 0);
		// setParameter on the sub-result
		subResult.setParameter("color", "green");
		// After changing color from red to green, the visible bitmaps should still exist
		var bitmapsAfter = findVisibleBitmapDescendants(subResult.object);
		Assert.isTrue(bitmapsAfter.length > 0);
		// The object tree should still be intact
		Assert.isTrue(subResult.object.numChildren > 0);
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
		// Capture visible bitmaps before toggling (show=true, so inner bitmap should be visible)
		var bitmapsBefore = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmapsBefore.length > 0);
		// Toggle parent parameter to hide inner content
		result.beginUpdate();
		result.setParameter("show", false);
		result.endUpdate();
		// After setting visible=>false via show=>false, the bitmap should no longer be visible
		var bitmapsAfter = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmapsAfter.length < bitmapsBefore.length);
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

	// ==================== Dynamic Name Refs ====================

	@Test
	public function testDynamicNameRefBuilds():Void {
		// $template is a string param that names a programmable
		final result = buildFromSource("
			#widgetA programmable() {
				bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
			#widgetB programmable() {
				bitmap(generated(color(20, 20, #00ff00))): 0, 0
			}
			#test programmable(template:string=\"widgetA\") {
				dynamicRef($template): 0, 0
			}
		", "test", null, Incremental);
		Assert.notNull(result);
		Assert.isTrue(result.object.numChildren > 0);
		// Should build widgetA initially
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testDynamicNameRefSwitchesOnParamChange():Void {
		final result = buildFromSource("
			#widgetA programmable() {
				bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
			#widgetB programmable() {
				bitmap(generated(color(20, 20, #00ff00))): 0, 0
			}
			#test programmable(template:string=\"widgetA\") {
				dynamicRef($template): 0, 0
			}
		", "test", null, Incremental);
		// Initially widgetA (10x10)
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Switch to widgetB
		result.setParameter("template", "widgetB");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testDynamicNameRefWithForwardedParams():Void {
		final result = buildFromSource("
			#bar programmable(val:uint=10) {
				bitmap(generated(color($val, 5, #ff0000))): 0, 0
			}
			#baz programmable(val:uint=10) {
				bitmap(generated(color($val, 8, #00ff00))): 0, 0
			}
			#test programmable(template:string=\"bar\", size:uint=15) {
				dynamicRef($template, val=>$size): 0, 0
			}
		", "test", null, Incremental);
		// Initially bar with val=15
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(15, Std.int(bitmaps[0].tile.width));

		// Switch template to baz — should rebuild with val=15
		result.setParameter("template", "baz");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(15, Std.int(bitmaps[0].tile.width));
		Assert.equals(8, Std.int(bitmaps[0].tile.height));
	}

	@Test
	public function testDynamicNameRefParamUpdateWithoutTemplateChange():Void {
		final result = buildFromSource("
			#bar programmable(val:uint=10) {
				bitmap(generated(color($val, 5, #ff0000))): 0, 0
			}
			#test programmable(template:string=\"bar\", size:uint=10) {
				dynamicRef($template, val=>$size): 0, 0
			}
		", "test", null, Incremental);
		// Initially bar with val=10
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Change size without changing template — should propagate to child
		result.setParameter("size", 25);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(25, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testDynamicNameRefFallbackToLiteral():Void {
		// When $name is NOT a parameter, it should fall back to literal programmable name
		// (backward compatibility)
		final result = buildFromSource("
			#myWidget programmable() {
				bitmap(generated(color(7, 7, #0000ff))): 0, 0
			}
			#test programmable() {
				dynamicRef($myWidget): 0, 0
			}
		", "test");
		Assert.notNull(result);
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.isTrue(bitmaps.length > 0);
		Assert.equals(7, Std.int(bitmaps[0].tile.width));
	}

	// ==================== Dynamic Name Ref Tear-Down ====================

	@Test
	public function testDynamicNameRefTearDownRemovesOldVisuals():Void {
		// When template changes, old visual's scene graph should be fully removed
		final result = buildFromSource("
			#widgetA programmable() {
				bitmap(generated(color(10, 10, #ff0000))): 0, 0
				bitmap(generated(color(5, 5, #00ff00))): 15, 0
			}
			#widgetB programmable() {
				bitmap(generated(color(20, 20, #0000ff))): 0, 0
			}
			#test programmable(template:string=\"widgetA\") {
				dynamicRef($template): 0, 0
			}
		", "test", null, Incremental);

		// Initially widgetA: 2 bitmaps
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);

		// Switch to widgetB: should have exactly 1 bitmap, old ones gone
		result.setParameter("template", "widgetB");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Switch back to widgetA: should rebuild 2 bitmaps
		result.setParameter("template", "widgetA");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);
	}

	@Test
	public function testDynamicNameRefTearDownUpdatesInteractives():Void {
		// When template changes, old result's interactives should not appear in new result
		final result = buildFromSource("
			#widgetA programmable() {
				bitmap(generated(color(10, 10, #ff0000))): 0, 0
				interactive(50, 50, \"btnA\"): 0, 0
			}
			#widgetB programmable() {
				bitmap(generated(color(20, 20, #0000ff))): 0, 0
				interactive(50, 50, \"btnB\"): 0, 0
			}
			#test programmable(template:string=\"widgetA\") {
				dynamicRef($template): 0, 0
			}
		", "test", null, Incremental);

		// Initially widgetA — getDynamicRef should return its result
		var dynRef = result.getDynamicRef("widgetA");
		Assert.notNull(dynRef);
		Assert.isTrue(dynRef.interactives.length > 0, "widgetA should have interactives");

		// Switch to widgetB
		result.setParameter("template", "widgetB");
		dynRef = result.getDynamicRef("widgetB");
		Assert.notNull(dynRef);
		Assert.isTrue(dynRef.interactives.length > 0, "widgetB should have interactives");

		// Old widgetA result should no longer be accessible via getDynamicRef
		var err:String = null;
		try {
			result.getDynamicRef("widgetA");
		} catch (e:Dynamic) {
			err = Std.string(e);
		}
		Assert.notNull(err, "Old template widgetA should not be accessible after switch");
	}

	@Test
	public function testDynamicNameRefMissingParamOnTargetThrows():Void {
		// Target programmable doesn't have the forwarded param — should throw (strict)
		var err:String = null;
		try {
			buildFromSource("
				#widgetA programmable() {
					bitmap(generated(color(10, 10, #ff0000))): 0, 0
				}
				#test programmable(template:string=\"widgetA\") {
					dynamicRef($template, nonexistent=>42): 0, 0
				}
			", "test", null, Incremental);
		} catch (e:Dynamic) {
			err = Std.string(e);
		}
		Assert.notNull(err);
	}

	// ==================== Sibling Collisions on Same Programmable Name (H2) ====================

	// Bug H2: `internalResults.dynamicRefs` is keyed by the referenced programmable name, so two
	// `dynamicRef($X)` siblings under @(..)/@else collapse onto one map entry (last-writer-wins).
	// `getDynamicRef("X")` then returns whichever was BUILT last, independent of which sibling is
	// currently VISIBLE. This silently hands the caller the wrong handle when visibility flips.

	@Test
	public function testDynamicRefColocatedSiblingsThrowOnGet():Void {
		// Two unnamed dynamicRef($X) siblings under @(..)/@else collapse onto one map entry
		// (the referenced programmable's name "X"). Pre-fix, `getDynamicRef("X")` silently returned
		// whichever was built last — which could be detached after a visibility flip. Post-fix,
		// calling getDynamicRef on an ambiguous key throws with a hint to use #name.
		final result = buildFromSource("
			#X programmable() {
				bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
			#host programmable(a:int=0) {
				@(a=>1) dynamicRef($X): 0, 0
				@else   dynamicRef($X): 0, 0
			}
		", "host", null, Incremental);

		// Only @else built initially (@(a=>1) is deferred) — only one site, so get is fine.
		result.getDynamicRef("X");

		// Flip once to materialise @(a=>1). Now both sites have written to dynamicRefs["X"].
		result.setParameter("a", 1);
		var err:String = null;
		try {
			result.getDynamicRef("X");
		} catch (e:Dynamic) {
			err = Std.string(e);
		}
		Assert.notNull(err, "getDynamicRef must throw on ambiguous unnamed sibling collision");
		Assert.isTrue(err.indexOf("#name") >= 0, 'error must hint at #name disambiguation; got: $err');
	}

	@Test
	public function testDynamicRefNamedSiblingsAreIndependentlyAddressable():Void {
		// With #name-labelled dynamicRef sites, each sibling stores under its explicit name — no
		// collision, and getDynamicRef returns the right one regardless of visibility.
		final result = buildFromSource("
			#X programmable(v:uint=1) {
				bitmap(generated(color(10, $v, #ff0000))): 0, 0
			}
			#host programmable(a:int=0, v:uint=5) {
				@(a=>1) #armOn  dynamicRef($X, v=>$v): 0, 0
				@else   #armOff dynamicRef($X, v=>$v): 0, 0
			}
		", "host", null, Incremental);

		final rootObj = result.object;

		// a=0 → armOff visible, armOn deferred (not yet built).
		Assert.isTrue(isDescendantOfRoot(result.getDynamicRef("armOff").object, rootObj),
			"armOff must be attached when a=0");

		// Flip to a=1. Both arms are now tracked by name; each independently addressable.
		result.setParameter("a", 1);
		Assert.isTrue(isDescendantOfRoot(result.getDynamicRef("armOn").object, rootObj),
			"armOn must be attached after flipping to a=1");
		Assert.isFalse(isDescendantOfRoot(result.getDynamicRef("armOff").object, rootObj),
			"armOff must be detached after flipping to a=1");

		// Flip back to a=0. armOff attached again, armOn detached. No ambiguity, no stale handle.
		result.setParameter("a", 0);
		Assert.isTrue(isDescendantOfRoot(result.getDynamicRef("armOff").object, rootObj),
			"armOff must be attached after flipping back to a=0");
		Assert.isFalse(isDescendantOfRoot(result.getDynamicRef("armOn").object, rootObj),
			"armOn must be detached after flipping back to a=0");
	}

	@Test
	public function testDynamicRefIndexedInRepeatableIsIndependentlyAddressable():Void {
		// Inside a repeatable, each iteration of an unnamed dynamicRef($X) would collide. The
		// `#name[$i] dynamicRef(...)` form makes each iteration a distinct map entry keyed as
		// `"name idx"` — addressable with the underlying `dynamicRefs.get("name 0")` etc.
		final result = buildFromSource("
			#leaf programmable(v:uint=3) {
				bitmap(generated(color($v, 5, #00ff00))): 0, 0
			}
			#host programmable() {
				repeatable($i, step(3, dx: 30)) {
					#item[$i] dynamicRef($leaf, v=>$i + 10): 0, 0
				}
			}
		", "host", null, Incremental);

		// Three iterations, three distinct entries under keys "item 0", "item 1", "item 2".
		Assert.isTrue(result.dynamicRefs.exists("item 0"), "indexed key 'item 0' should exist");
		Assert.isTrue(result.dynamicRefs.exists("item 1"), "indexed key 'item 1' should exist");
		Assert.isTrue(result.dynamicRefs.exists("item 2"), "indexed key 'item 2' should exist");

		// Each iteration got a different forwarded $v (10, 11, 12) via the $i + 10 expression —
		// check that each per-iteration sub-result's bitmap reflects the right width.
		final widths = [0, 0, 0];
		for (i in 0...3) {
			final sub = result.dynamicRefs.get("item " + i);
			Assert.notNull(sub);
			final bitmaps = findVisibleBitmapDescendants(sub.object);
			Assert.equals(1, bitmaps.length);
			widths[i] = Std.int(bitmaps[0].tile.width);
		}
		Assert.equals(10, widths[0]);
		Assert.equals(11, widths[1]);
		Assert.equals(12, widths[2]);
	}

	@Test
	public function testDynamicRefExplicitNameCollisionThrowsAtBuild():Void {
		// Two #name dynamicRef sites with the same explicit name are a hard error — there is no
		// sensible resolution. Fails at build time, not at getDynamicRef.
		var err:String = null;
		try {
			buildFromSource("
				#X programmable() {
					bitmap(generated(color(10, 10, #ff0000))): 0, 0
				}
				#host programmable() {
					#widget dynamicRef($X): 0, 0
					#widget dynamicRef($X): 0, 20
				}
			", "host", null, Incremental);
		} catch (e:Dynamic) {
			err = Std.string(e);
		}
		Assert.notNull(err);
		Assert.isTrue(err.indexOf("widget") >= 0, 'error must mention duplicate name; got: $err');
	}

	static function isDescendantOfRoot(obj:h2d.Object, root:h2d.Object):Bool {
		var cur:h2d.Object = obj;
		while (cur != null) {
			if (cur == root) return true;
			cur = cur.parent;
		}
		return false;
	}

	@Test
	public function testDynamicRefConditionalSiblingsPropagateAcrossVisibilityFlip():Void {
		// Bug H2 secondary symptom: before the fix, parameter updates to the parent were applied
		// only to the VISIBLE sibling (the applyUpdates loop filtered dynamicRefBindings via
		// `isEffectivelyVisible`). When visibility flipped, the previously-hidden sibling surfaced
		// with STALE parameter state. After the fix, the propagation loop fires regardless of
		// visibility, so both siblings stay in sync.
		final result = buildFromSource("
			#X programmable(v:uint=1) {
				bitmap(generated(color(10, $v, #ff0000))): 0, 0
			}
			#host programmable(a:int=0, v:uint=5) {
				@(a=>1) #armOn  dynamicRef($X, v=>$v): 0, 0
				@else   #armOff dynamicRef($X, v=>$v): 0, 0
			}
		", "host", null, Incremental);

		// a=0 → armOff visible, v=5. Bitmap height should be 5.
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(5, Std.int(bitmaps[0].tile.height));

		// Update v while armOff is visible. Must reach armOff (visible).
		result.setParameter("v", 10);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(10, Std.int(bitmaps[0].tile.height),
			"visible armOff must reflect v=10 after setParameter on parent");

		// Flip to armOn. Its dynamicRef was hidden when v changed, but with the fix it received the
		// v=10 update through the propagation loop. After flipping it renders v=10, not the stale
		// default.
		result.setParameter("a", 1);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.height),
			"armOn must reflect v=10 after becoming visible (no stale state)");

		// Update v while armOn is visible. armOff (now hidden) must still receive the update.
		result.setParameter("v", 15);
		result.setParameter("a", 0);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(15, Std.int(bitmaps[0].tile.height),
			"armOff must reflect v=15 after becoming visible again (no stale state)");
	}
}
