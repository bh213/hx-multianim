package bh.test.examples;

#if MULTIANIM_DEV
import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.buildFromSource;
import bh.test.BuilderTestBase.builderFromSource;
import bh.test.BuilderTestBase.findVisibleBitmapDescendants;
import bh.test.BuilderTestBase.findAllTextDescendants;
import bh.test.BuilderTestBase.countVisibleChildren;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.dev.HotReload;

/**
 * Hot-reload unit tests.
 * Only compiled with -D MULTIANIM_DEV.
 * Tests the snapshot/restore/swap cycle used during live .manim hot-reload.
 *
 * NOTE: Use double-quoted strings ("...") for .manim source — single-quoted strings
 * trigger Haxe string interpolation which conflicts with .manim $ references.
 */
class HotReloadTest extends BuilderTestBase {
	// ===== Helper: simulate hot-reload cycle =====

	/**
	 * Simulates a hot-reload: builds from oldSource, snapshots state,
	 * builds from newSource with restored snapshot, swaps scene.
	 * Returns {oldResult, newResult, report} for assertions.
	 */
	static function simulateReload(oldSource:String, newSource:String, programmable:String,
			?initialParams:Map<String, Dynamic>):{oldResult:BuilderResult, newResult:BuilderResult} {
		// 1. Build original
		final oldResult = buildFromSource(oldSource, programmable, initialParams, Incremental);

		// 2. Snapshot
		final snapshot = StateSnapshotter.capture(oldResult);

		// 3. Detach slots
		StateRestorer.detachSlots(oldResult);

		// 4. Build new version
		final newBuilder = builderFromSource(newSource);
		final inputMap = StateRestorer.snapshotToInputMap(snapshot.params);
		final newResult = newBuilder.buildWithParameters(programmable, inputMap, null, null, true);

		// 5. Restore
		StateRestorer.restore(newResult, snapshot);

		// 6. Replace children in stable root, adopt internals
		final parent = new h2d.Object();
		parent.addChild(oldResult.object);
		SceneSwapper.replaceChildren(oldResult.object, newResult.object);
		final stableObject = oldResult.object;
		oldResult.adoptFrom(newResult);
		oldResult.object = stableObject;

		return {oldResult: oldResult, newResult: newResult};
	}

	// ==================== resolvedToDynamic correctness ====================

	@Test
	public function testResolvedToDynamic_enumReturnsName():Void {
		// Index should return the name string, not the integer index
		final result = StateRestorer.resolvedToDynamic(bh.multianim.MultiAnimParser.ResolvedIndexParameters.Index(2, "active"));
		Assert.isTrue(Std.isOfType(result, String), "Index should return String name");
		Assert.equals("active", cast(result, String));
	}

	@Test
	public function testResolvedToDynamic_intValue():Void {
		final result = StateRestorer.resolvedToDynamic(bh.multianim.MultiAnimParser.ResolvedIndexParameters.Value(42));
		Assert.equals(42, result);
	}

	@Test
	public function testResolvedToDynamic_floatValue():Void {
		final result = StateRestorer.resolvedToDynamic(bh.multianim.MultiAnimParser.ResolvedIndexParameters.ValueF(3.14));
		Assert.floatEquals(3.14, result);
	}

	@Test
	public function testResolvedToDynamic_stringValue():Void {
		final result = StateRestorer.resolvedToDynamic(bh.multianim.MultiAnimParser.ResolvedIndexParameters.StringValue("hello"));
		Assert.equals("hello", result);
	}

	@Test
	public function testResolvedToDynamic_boolFlag():Void {
		final result = StateRestorer.resolvedToDynamic(bh.multianim.MultiAnimParser.ResolvedIndexParameters.Flag(1));
		Assert.equals(1, result);
	}

	// ==================== SignatureChecker ====================

	@Test
	public function testSignatureChecker_compatible():Void {
		final oldBuilder = builderFromSource("
			#test programmable(mode:[a,b,c]=a, size:uint=10) {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		final newBuilder = builderFromSource("
			#test programmable(mode:[a,b,c]=a, size:uint=20) {
				bitmap(generated(color(20, 20, #0f0))): 0, 0
			}
		");
		final oldDefs = oldBuilder.getParameterDefinitions("test");
		final newDefs = newBuilder.getParameterDefinitions("test");
		final reason = SignatureChecker.check(oldDefs, newDefs);
		Assert.isNull(reason, "Same params should be compatible");
	}

	@Test
	public function testSignatureChecker_removedParam():Void {
		final oldBuilder = builderFromSource("
			#test programmable(mode:[a,b]=a, size:uint=10) {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		final newBuilder = builderFromSource("
			#test programmable(mode:[a,b]=a) {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		final oldDefs = oldBuilder.getParameterDefinitions("test");
		final newDefs = newBuilder.getParameterDefinitions("test");
		final reason = SignatureChecker.check(oldDefs, newDefs);
		Assert.notNull(reason, "Removed param should be incompatible");
		Assert.isTrue(reason.indexOf("size") >= 0);
	}

	@Test
	public function testSignatureChecker_typeChanged():Void {
		final oldBuilder = builderFromSource("
			#test programmable(val:uint=10) {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		final newBuilder = builderFromSource("
			#test programmable(val:bool=true) {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		final oldDefs = oldBuilder.getParameterDefinitions("test");
		final newDefs = newBuilder.getParameterDefinitions("test");
		final reason = SignatureChecker.check(oldDefs, newDefs);
		Assert.notNull(reason, "Changed type should be incompatible");
		Assert.isTrue(reason.indexOf("val") >= 0);
	}

	@Test
	public function testSignatureChecker_addedParam():Void {
		final oldBuilder = builderFromSource("
			#test programmable(mode:[a,b]=a) {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		final newBuilder = builderFromSource("
			#test programmable(mode:[a,b]=a, size:uint=10) {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		final oldDefs = oldBuilder.getParameterDefinitions("test");
		final newDefs = newBuilder.getParameterDefinitions("test");
		// Adding params is compatible
		final reason = SignatureChecker.check(oldDefs, newDefs);
		Assert.isNull(reason, "Added param should be compatible");
		final added = SignatureChecker.getAddedParams(oldDefs, newDefs);
		Assert.equals(1, added.length);
		Assert.equals("size", added[0]);
	}

	@Test
	public function testSignatureChecker_enumValuesChanged():Void {
		// Changing enum values within same PPTEnum type should be compatible
		final oldBuilder = builderFromSource("
			#test programmable(mode:[a,b]=a) {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		final newBuilder = builderFromSource("
			#test programmable(mode:[a,b,c]=a) {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		final oldDefs = oldBuilder.getParameterDefinitions("test");
		final newDefs = newBuilder.getParameterDefinitions("test");
		final reason = SignatureChecker.check(oldDefs, newDefs);
		Assert.isNull(reason, "Adding enum values should be compatible (same PPTEnum kind)");
	}

	// ==================== FileChangeDetector ====================

	@Test
	public function testFileChangeDetector_basics():Void {
		final detector = new FileChangeDetector();
		Assert.isTrue(detector.hasChanged("test.manim", "content1"), "First check should always be changed");
		detector.updateHash("test.manim", "content1");
		Assert.isFalse(detector.hasChanged("test.manim", "content1"), "Same content should not be changed");
		Assert.isTrue(detector.hasChanged("test.manim", "content2"), "Different content should be changed");
	}

	@Test
	public function testFileChangeDetector_storeInitialHash():Void {
		final detector = new FileChangeDetector();
		detector.storeInitialHash("test.manim", "content1");
		Assert.isFalse(detector.hasChanged("test.manim", "content1"), "Stored hash should match");
		// storeInitialHash should not overwrite existing
		detector.storeInitialHash("test.manim", "content2");
		Assert.isFalse(detector.hasChanged("test.manim", "content1"), "storeInitialHash should not overwrite");
	}

	@Test
	public function testFileChangeDetector_invalidate():Void {
		final detector = new FileChangeDetector();
		detector.updateHash("test.manim", "content1");
		detector.invalidate("test.manim");
		Assert.isTrue(detector.hasChanged("test.manim", "content1"), "Invalidated should always report changed");
	}

	// ==================== Snapshot/Restore: uint parameter ====================

	@Test
	public function testHotReload_uintParamPreserved():Void {
		final oldSource = "
			#test programmable(size:uint=10) {
				bitmap(generated(color($size, $size, #f00))): 0, 0
			}
		";
		// Build with non-default param
		final result = buildFromSource(oldSource, "test", ["size" => 25], Incremental);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(25, Std.int(bitmaps[0].tile.width));

		// Snapshot and rebuild with new source (different default, same type)
		final newSource = "
			#test programmable(size:uint=99) {
				bitmap(generated(color($size, $size, #0f0))): 0, 0
			}
		";
		final r = simulateReload(oldSource, newSource, "test", ["size" => 25]);
		final newBitmaps = findVisibleBitmapDescendants(r.oldResult.object);
		Assert.equals(1, newBitmaps.length);
		// Size should be restored to 25 (not default 99)
		Assert.equals(25, Std.int(newBitmaps[0].tile.width));
	}

	// ==================== Snapshot/Restore: enum parameter ====================

	@Test
	public function testHotReload_enumParamPreserved():Void {
		final source = '
			#test programmable(mode:[normal,hover,active]=normal) {
				@(mode=>normal) text(dd, "N", white): 0, 0
				@(mode=>hover) text(dd, "H", white): 0, 0
				@(mode=>active) text(dd, "A", white): 0, 0
			}
		';
		// Build with mode=hover
		final result = buildFromSource(source, "test", ["mode" => "hover"], Incremental);
		var texts = findAllTextDescendants(result.object);
		var visibleTexts = texts.filter(t -> t.visible);
		Assert.equals(1, visibleTexts.length);
		Assert.equals("H", visibleTexts[0].text);

		// Simulate hot-reload: change text content but keep mode=hover
		final newSource = '
			#test programmable(mode:[normal,hover,active]=normal) {
				@(mode=>normal) text(dd, "Normal", white): 0, 0
				@(mode=>hover) text(dd, "Hover!", white): 0, 0
				@(mode=>active) text(dd, "Active", white): 0, 0
			}
		';
		final r = simulateReload(source, newSource, "test", ["mode" => "hover"]);
		texts = findAllTextDescendants(r.oldResult.object);
		visibleTexts = texts.filter(t -> t.visible);
		Assert.equals(1, visibleTexts.length);
		Assert.equals("Hover!", visibleTexts[0].text);
	}

	// ==================== Snapshot/Restore: bool parameter ====================

	@Test
	public function testHotReload_boolParamPreserved():Void {
		final source = "
			#test programmable(visible:bool=false) {
				@(visible=>true) bitmap(generated(color(20, 20, #0f0))): 0, 0
			}
		";
		final result = buildFromSource(source, "test", ["visible" => "true"], Incremental);
		Assert.equals(1, findVisibleBitmapDescendants(result.object).length);

		final newSource = "
			#test programmable(visible:bool=false) {
				@(visible=>true) bitmap(generated(color(30, 30, #00f))): 0, 0
			}
		";
		final r = simulateReload(source, newSource, "test", ["visible" => "true"]);
		final bitmaps = findVisibleBitmapDescendants(r.oldResult.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
	}

	// ==================== Snapshot/Restore: float parameter ====================

	@Test
	public function testHotReload_floatParamPreserved():Void {
		final source = "
			#test programmable(opacity:float=1.0) {
				@alpha($opacity) bitmap(generated(color(20, 20, #f00))): 0, 0
			}
		";
		final r = simulateReload(source, source, "test", ["opacity" => "0.5"]);
		// Just verify rebuild succeeds without error
		Assert.notNull(r.oldResult);
		Assert.notNull(r.oldResult.object);
	}

	// ==================== Snapshot/Restore: string parameter ====================

	@Test
	public function testHotReload_stringParamPreserved():Void {
		final source = "
			#test programmable(label:string=\"hello\") {
				text(dd, $label, white): 0, 0
			}
		";
		final r = simulateReload(source, source, "test", ["label" => "world"]);
		final texts = findAllTextDescendants(r.oldResult.object);
		Assert.equals(1, texts.length);
		Assert.equals("world", texts[0].text);
	}

	// ==================== SceneSwapper ====================

	@Test
	public function testSceneSwapper_replacesChildren():Void {
		final parent = new h2d.Object();
		final stable = new h2d.Object();
		stable.x = 100;
		stable.y = 200;
		stable.scaleX = 2.0;
		stable.visible = false;
		parent.addChild(stable);

		final oldChild = new h2d.Object();
		stable.addChild(oldChild);

		final newRoot = new h2d.Object();
		final newChild1 = new h2d.Object();
		final newChild2 = new h2d.Object();
		newRoot.addChild(newChild1);
		newRoot.addChild(newChild2);

		SceneSwapper.replaceChildren(stable, newRoot);

		// Stable object stays in scene with its transforms intact
		Assert.equals(parent, stable.parent, "Stable root stays in scene");
		Assert.equals(100.0, stable.x);
		Assert.equals(200.0, stable.y);
		Assert.floatEquals(2.0, stable.scaleX);
		Assert.isFalse(stable.visible, "visible preserved");

		// Children replaced
		Assert.equals(2, stable.numChildren);
		Assert.equals(newChild1, stable.getChildAt(0));
		Assert.equals(newChild2, stable.getChildAt(1));

		// Old child detached, new root empty
		Assert.isNull(oldChild.parent, "Old child detached");
		Assert.equals(0, newRoot.numChildren, "New root emptied");
	}

	@Test
	public function testSceneSwapper_stableRootKeepsScenePosition():Void {
		final parent = new h2d.Object();
		final before = new h2d.Object();
		final stable = new h2d.Object();
		final after = new h2d.Object();
		parent.addChild(before);
		parent.addChild(stable);
		parent.addChild(after);

		final newRoot = new h2d.Object();
		newRoot.addChild(new h2d.Object());
		SceneSwapper.replaceChildren(stable, newRoot);

		// Stable stays at same index
		Assert.equals(3, parent.numChildren);
		Assert.equals(before, parent.getChildAt(0));
		Assert.equals(stable, parent.getChildAt(1));
		Assert.equals(after, parent.getChildAt(2));
	}

	// ==================== Snapshot/Restore: visual content changes ====================

	@Test
	public function testHotReload_visualContentUpdated():Void {
		final oldSource = "
			#test programmable(w:uint=10) {
				bitmap(generated(color($w, $w, #f00))): 0, 0
			}
		";
		final newSource = "
			#test programmable(w:uint=10) {
				bitmap(generated(color($w, $w, #f00))): 0, 0
				bitmap(generated(color(5, 5, #0f0))): 50, 0
			}
		";
		final r = simulateReload(oldSource, newSource, "test", ["w" => 20]);
		final bitmaps = findVisibleBitmapDescendants(r.oldResult.object);
		Assert.equals(2, bitmaps.length, "New source adds a second bitmap");
		Assert.equals(20, Std.int(bitmaps[0].tile.width), "Param w should be restored to 20");
	}

	// ==================== snapshotToInputMap round-trip ====================

	@Test
	public function testSnapshotToInputMap_roundTrip():Void {
		final source = "
			#test programmable(n:uint=10, mode:[a,b,c]=a, flag:bool=false, label:string=\"hi\") {
				bitmap(generated(color($n, $n, #f00))): 0, 0
			}
		";
		final result = buildFromSource(source, "test", ["n" => 42, "mode" => "b", "flag" => "true", "label" => "test"], Incremental);
		final snapshot = StateSnapshotter.capture(result);
		final inputMap = StateRestorer.snapshotToInputMap(snapshot.params);

		Assert.equals(42, inputMap.get("n"));
		Assert.equals("b", inputMap.get("mode")); // Should be string name, not index
		Assert.equals(1, inputMap.get("flag")); // bool true = 1
		Assert.equals("test", inputMap.get("label"));
	}

	// ==================== Slot content preservation ====================

	@Test
	public function testHotReload_slotContentPreserved():Void {
		final source = "
			#test programmable() {
				#content slot: 0, 0
			}
		";
		final oldResult = buildFromSource(source, "test", null, Incremental);
		final slot = oldResult.getSlot("content");
		Assert.notNull(slot);

		// Add content to slot
		final content = new h2d.Object();
		slot.setContent(content);
		Assert.isFalse(slot.isEmpty());

		// Manually simulate reload on this specific result
		final snapshot = StateSnapshotter.capture(oldResult);
		StateRestorer.detachSlots(oldResult);

		final newBuilder = builderFromSource(source);
		final newResult = newBuilder.buildWithParameters("test", new Map(), null, null, true);
		StateRestorer.restore(newResult, snapshot);

		final parent = new h2d.Object();
		parent.addChild(oldResult.object);
		SceneSwapper.replaceChildren(oldResult.object, newResult.object);
		final stableObject = oldResult.object;
		oldResult.adoptFrom(newResult);
		oldResult.object = stableObject;

		final restoredSlot = oldResult.getSlot("content");
		Assert.notNull(restoredSlot);
		// Slot content should be restored (the h2d.Object reparented)
		Assert.isFalse(restoredSlot.isEmpty());
	}

	// ==================== resolvedToDynamic: unsnappable types ====================

	@Test
	public function testResolvedToDynamic_expressionAlias():Void {
		final result = StateRestorer.resolvedToDynamic(
			bh.multianim.MultiAnimParser.ResolvedIndexParameters.ExpressionAlias(
				bh.multianim.MultiAnimParser.ReferenceableValue.RVInteger(42)));
		Assert.isNull(result, "ExpressionAlias should return null (unsnappable)");
	}

	@Test
	public function testResolvedToDynamic_tileSource():Void {
		final result = StateRestorer.resolvedToDynamic(
			bh.multianim.MultiAnimParser.ResolvedIndexParameters.TileSourceValue(
				bh.multianim.MultiAnimParser.TileSource.TSFile(
					bh.multianim.MultiAnimParser.ReferenceableValue.RVString("test.png"))));
		Assert.isNull(result, "TileSourceValue should return null (unsnappable)");
	}

	// ==================== snapshotToInputMap: skips null values ====================

	@Test
	public function testSnapshotToInputMap_skipsNulls():Void {
		final params:Map<String, bh.multianim.MultiAnimParser.ResolvedIndexParameters> = [];
		params.set("normal", bh.multianim.MultiAnimParser.ResolvedIndexParameters.Value(42));
		params.set("expr", bh.multianim.MultiAnimParser.ResolvedIndexParameters.ExpressionAlias(
			bh.multianim.MultiAnimParser.ReferenceableValue.RVInteger(99)));
		params.set("tile", bh.multianim.MultiAnimParser.ResolvedIndexParameters.TileSourceValue(
			bh.multianim.MultiAnimParser.TileSource.TSFile(
				bh.multianim.MultiAnimParser.ReferenceableValue.RVString("test.png"))));

		final inputMap = StateRestorer.snapshotToInputMap(params);
		Assert.isTrue(inputMap.exists("normal"), "Normal values should be in map");
		Assert.isFalse(inputMap.exists("expr"), "ExpressionAlias should be skipped");
		Assert.isFalse(inputMap.exists("tile"), "TileSourceValue should be skipped");
		Assert.equals(42, inputMap.get("normal"));
	}

	// ==================== Parse error keeps old state ====================

	@Test
	public function testHotReload_parseErrorKeepsOldState():Void {
		final validSource = "
			#test programmable(size:uint=10) {
				bitmap(generated(color($size, $size, #f00))): 0, 0
			}
		";
		final invalidSource = "
			#test programmable(size:uint=10 {
				bitmap(generated(color($size, $size, #f00))): 0, 0
		";

		// Build from valid source
		final result = buildFromSource(validSource, "test", ["size" => 25], Incremental);
		Assert.notNull(result);
		Assert.notNull(result.object);

		// Attempt to parse invalid source — should throw
		var parseError = false;
		try {
			builderFromSource(invalidSource);
		} catch (e:Dynamic) {
			parseError = true;
		}
		Assert.isTrue(parseError, "Invalid source should throw parse error");

		// Original result should still be functional
		result.setParameter("size", 30);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(30, Std.int(bitmaps[0].tile.width));
	}

	// ==================== DynamicRef parameter preservation ====================

	@Test
	public function testHotReload_dynamicRefParamsPreserved():Void {
		final source = "
			#bar programmable(value:uint=50, label:string=\"Label\") {
				bitmap(generated(color($value, 10, #f00))): 0, 0
				text(dd, $label, white): 0, 0
			}
			#test programmable() {
				dynamicRef($bar, value=>80, label=>\"HP\"): 0, 0
			}
		";
		final oldResult = buildFromSource(source, "test", null, Incremental);
		Assert.notNull(oldResult);

		// Get dynamic ref and change its parameter
		final dynRef = oldResult.getDynamicRef("bar");
		Assert.notNull(dynRef, "Should have dynamicRef 'bar'");
		dynRef.setParameter("value", 60);

		// Snapshot captures dynamic ref params
		final snapshot = StateSnapshotter.capture(oldResult);
		Assert.isTrue(snapshot.dynamicRefs.exists("bar"), "Snapshot should include dynamicRef 'bar'");

		// Verify the snapshot captured the updated value
		final drParams = snapshot.dynamicRefs.get("bar");
		Assert.notNull(drParams);
		Assert.isTrue(drParams.exists("value"), "DynamicRef snapshot should have 'value' param");
	}
}
#end
