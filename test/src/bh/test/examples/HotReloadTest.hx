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
import bh.multianim.MultiAnimBuilder.BuilderParameters;
import bh.multianim.MultiAnimBuilder.CallbackRequest;
import bh.multianim.MultiAnimBuilder.CallbackResult;
import bh.multianim.MultiAnimBuilder.PlaceholderValues;
import bh.multianim.dev.HotReload;

/**
 * Hot-reload unit tests.
 * Only compiled with -D MULTIANIM_DEV.
 * Tests the snapshot/restore/swap cycle used during live .manim hot-reload.
 *
 * NOTE: Use double-quoted strings ("...") for .manim source — single-quoted strings
 * trigger Haxe string interpolation which conflicts with .manim $ references.
 */
@:access(bh.ui.screens.ScreenManager)
@:access(bh.multianim.dev.DevBridge)
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

	// ==================== Placeholder reuse helpers ====================

	/**
	 * Simulates hot-reload with BuilderParameters (callbacks/placeholderObjects).
	 * Uses PlaceholderReuser to wrap params for reuse during rebuild.
	 */
	static function simulateReloadWithParams(oldSource:String, newSource:String, programmable:String,
			builderParams:BuilderParameters,
			?initialParams:Map<String, Dynamic>):{oldResult:BuilderResult, newResult:BuilderResult} {
		// 1. Build original with builderParams
		final oldBuilder = builderFromSource(oldSource);
		if (initialParams == null) initialParams = new Map();
		final oldResult = oldBuilder.buildWithParameters(programmable, initialParams, builderParams, null, true);

		// 2. Snapshot (captures placeholder objects)
		final snapshot = StateSnapshotter.capture(oldResult);

		// 3. Detach slots
		StateRestorer.detachSlots(oldResult);

		// 4. Wrap builderParams for reuse
		final reloadParams = PlaceholderReuser.wrapBuilderParams(builderParams, snapshot.placeholders);

		// 5. Build new version with wrapped params
		final newBuilder = builderFromSource(newSource);
		final inputMap = StateRestorer.snapshotToInputMap(snapshot.params);
		final newResult = newBuilder.buildWithParameters(programmable, inputMap, reloadParams, null, true);

		// 6. Restore
		StateRestorer.restore(newResult, snapshot);

		// 7. Replace children, adopt internals
		final parent = new h2d.Object();
		parent.addChild(oldResult.object);
		SceneSwapper.replaceChildren(oldResult.object, newResult.object);
		final stableObject = oldResult.object;
		oldResult.adoptFrom(newResult);
		oldResult.object = stableObject;

		return {oldResult: oldResult, newResult: newResult};
	}

	// ==================== Placeholder reuse: builderParameter PVObject ====================

	@Test
	public function testHotReload_pvObjectPlaceholderReused():Void {
		final source = "
			#test programmable() {
				placeholder(nothing, builderParameter(\"myObj\")): 10, 20
			}
		";
		final myObj = new h2d.Object();
		final bp:BuilderParameters = {
			placeholderObjects: ["myObj" => PVObject(myObj)],
		};

		final r = simulateReloadWithParams(source, source, "test", bp);

		// The same h2d.Object should be in the rebuilt tree
		Assert.isTrue(containsObject(r.oldResult.object, myObj), "PVObject should be reused in rebuilt tree");
	}

	// ==================== Placeholder reuse: builderParameter PVFactory ====================

	@Test
	public function testHotReload_pvFactoryPlaceholderReused():Void {
		final source = "
			#test programmable() {
				placeholder(nothing, builderParameter(\"widget\")): 0, 0
			}
		";
		var factoryCallCount = 0;
		final factoryObj = new h2d.Object();
		final bp:BuilderParameters = {
			placeholderObjects: ["widget" => PVFactory((_) -> {
				factoryCallCount++;
				return factoryObj;
			})],
		};

		// Build original — factory called once
		final oldBuilder = builderFromSource(source);
		final oldResult = oldBuilder.buildWithParameters("test", new Map(), bp, null, true);
		Assert.equals(1, factoryCallCount, "Factory called once during initial build");

		// Snapshot and reload
		final snapshot = StateSnapshotter.capture(oldResult);
		StateRestorer.detachSlots(oldResult);
		final reloadParams = PlaceholderReuser.wrapBuilderParams(bp, snapshot.placeholders);
		final newBuilder = builderFromSource(source);
		final newResult = newBuilder.buildWithParameters("test", new Map(), reloadParams, null, true);

		// Factory should NOT be called again — reused as PVObject
		Assert.equals(1, factoryCallCount, "Factory should NOT be re-called during hot reload");

		// Verify same object is in new tree
		Assert.isTrue(containsObject(newResult.object, factoryObj), "Factory-created object should be reused");
	}

	// ==================== Placeholder reuse: callback ====================

	@Test
	public function testHotReload_callbackPlaceholderReused():Void {
		final source = "
			#test programmable() {
				placeholder(nothing, callback(\"grid\")): 0, 0
			}
		";
		var callbackCount = 0;
		final gridObj = new h2d.Object();
		final bp:BuilderParameters = {
			callback: (request) -> {
				switch request {
					case Placeholder(name) if (name == "grid"):
						callbackCount++;
						return CBRObject(gridObj);
					default:
						return CBRNoResult;
				}
			},
		};

		final r = simulateReloadWithParams(source, source, "test", bp);

		// Callback called once for initial build, NOT again during reload
		Assert.equals(1, callbackCount, "Callback should be called once (initial build only)");

		// Same object reused
		Assert.isTrue(containsObject(r.oldResult.object, gridObj), "Callback-provided object should be reused");
	}

	// ==================== Placeholder reuse: callback with index ====================

	@Test
	public function testHotReload_callbackWithIndexPlaceholderReused():Void {
		// Use repeatable with range to generate indexed callbacks
		final source = "
			#test programmable() {
				repeatable($i, range(0, 2)) {
					placeholder(nothing, callback(\"item\", $i)): 0, 0
				}
			}
		";
		var callbackCount = 0;
		final items:Array<h2d.Object> = [];
		for (i in 0...2) {
			final obj = new h2d.Object();
			items.push(obj);
		}
		final bp:BuilderParameters = {
			callback: (request) -> {
				switch request {
					case PlaceholderWithIndex(name, index) if (name == "item"):
						callbackCount++;
						return CBRObject(items[index]);
					default:
						return CBRNoResult;
				}
			},
		};

		final r = simulateReloadWithParams(source, source, "test", bp);

		// Called twice for initial build (index 0 and 1), NOT again during reload
		Assert.equals(2, callbackCount, "Callback should be called twice (initial build only)");

		// Both objects reused
		Assert.isTrue(containsObject(r.oldResult.object, items[0]), "Item 0 should be reused");
		Assert.isTrue(containsObject(r.oldResult.object, items[1]), "Item 1 should be reused");
	}

	// ==================== Placeholder reuse: position change preserves object ====================

	@Test
	public function testHotReload_placeholderPositionChangedObjectReused():Void {
		final oldSource = "
			#test programmable() {
				placeholder(nothing, builderParameter(\"panel\")): 10, 20
			}
		";
		final newSource = "
			#test programmable() {
				placeholder(nothing, builderParameter(\"panel\")): 100, 200
			}
		";
		var factoryCallCount = 0;
		final panelObj = new h2d.Object();
		final bp:BuilderParameters = {
			placeholderObjects: ["panel" => PVFactory((_) -> {
				factoryCallCount++;
				return panelObj;
			})],
		};

		final r = simulateReloadWithParams(oldSource, newSource, "test", bp);

		// Factory NOT re-called
		Assert.equals(1, factoryCallCount, "Factory not re-called on position change");

		// Object reused
		Assert.isTrue(containsObject(r.oldResult.object, panelObj), "Panel should be reused after position change");
	}

	// ==================== Placeholder reuse: new placeholder falls through ====================

	@Test
	public function testHotReload_newPlaceholderFallsThrough():Void {
		final oldSource = "
			#test programmable() {
				placeholder(nothing, builderParameter(\"existing\")): 0, 0
			}
		";
		final newSource = "
			#test programmable() {
				placeholder(nothing, builderParameter(\"existing\")): 0, 0
				placeholder(nothing, builderParameter(\"added\")): 50, 0
			}
		";
		var existingCallCount = 0;
		var addedCallCount = 0;
		final existingObj = new h2d.Object();
		final addedObj = new h2d.Object();
		final bp:BuilderParameters = {
			placeholderObjects: [
				"existing" => PVFactory((_) -> { existingCallCount++; return existingObj; }),
				"added" => PVFactory((_) -> { addedCallCount++; return addedObj; }),
			],
		};

		final r = simulateReloadWithParams(oldSource, newSource, "test", bp);

		// "existing" was in old build → reused (factory not called again)
		Assert.equals(1, existingCallCount, "Existing factory called once (initial build)");

		// "added" is new → factory called during reload
		Assert.equals(1, addedCallCount, "Added factory called once (during reload)");

		// Both present in result
		Assert.isTrue(containsObject(r.oldResult.object, existingObj), "Existing object should be present");
		Assert.isTrue(containsObject(r.oldResult.object, addedObj), "Added object should be present");
	}

	// ==================== Placeholder reuse: no placeholders = no wrapping ====================

	@Test
	public function testHotReload_noPlaceholdersNoWrapping():Void {
		// A programmable with no placeholders should still work fine
		final source = "
			#test programmable(size:uint=10) {
				bitmap(generated(color($size, $size, #f00))): 0, 0
			}
		";
		final bp:BuilderParameters = {};

		final r = simulateReloadWithParams(source, source, "test", bp, ["size" => 25]);
		final bitmaps = findVisibleBitmapDescendants(r.oldResult.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(25, Std.int(bitmaps[0].tile.width));
	}

	// ==================== Placeholder capture: snapshot captures placeholders ====================

	@Test
	public function testPlaceholderSnapshot_capturedDuringBuild():Void {
		final source = "
			#test programmable() {
				placeholder(nothing, builderParameter(\"a\")): 0, 0
				placeholder(nothing, builderParameter(\"b\")): 50, 0
			}
		";
		final objA = new h2d.Object();
		final objB = new h2d.Object();
		final bp:BuilderParameters = {
			placeholderObjects: [
				"a" => PVObject(objA),
				"b" => PVObject(objB),
			],
		};

		final builder = builderFromSource(source);
		final result = builder.buildWithParameters("test", new Map(), bp, null, true);
		final snapshot = StateSnapshotter.capture(result);

		Assert.equals(2, snapshot.placeholders.length, "Should capture 2 placeholders");
		// Verify names
		var names = snapshot.placeholders.map(p -> p.name);
		Assert.isTrue(names.indexOf("a") >= 0, "Should capture placeholder 'a'");
		Assert.isTrue(names.indexOf("b") >= 0, "Should capture placeholder 'b'");
	}

	// ==================== PlaceholderReuser: empty snapshot returns original ====================

	@Test
	public function testPlaceholderReuser_emptySnapshotReturnsOriginal():Void {
		final bp:BuilderParameters = {
			callback: (_) -> CBRNoResult,
		};
		final wrapped = PlaceholderReuser.wrapBuilderParams(bp, []);
		// With empty snapshot, should return original params unchanged
		Assert.equals(bp, wrapped);
	}

	// ==================== Placeholder reuse with params: params still restored ====================

	@Test
	public function testHotReload_placeholderReusedAndParamsRestored():Void {
		final source = "
			#test programmable(label:string=\"default\") {
				placeholder(nothing, builderParameter(\"widget\")): 0, 0
				text(dd, $label, white): 0, 20
			}
		";
		var factoryCallCount = 0;
		final widgetObj = new h2d.Object();
		final bp:BuilderParameters = {
			placeholderObjects: ["widget" => PVFactory((_) -> {
				factoryCallCount++;
				return widgetObj;
			})],
		};

		final r = simulateReloadWithParams(source, source, "test", bp, ["label" => "custom"]);

		// Widget reused
		Assert.equals(1, factoryCallCount, "Factory not re-called");
		Assert.isTrue(containsObject(r.oldResult.object, widgetObj), "Widget should be reused");

		// String param restored
		final texts = findAllTextDescendants(r.oldResult.object);
		Assert.equals(1, texts.length);
		Assert.equals("custom", texts[0].text);
	}

	// ==================== Placeholder reuse: PVComponent ====================

	@Test
	public function testHotReload_pvComponentPlaceholderReused():Void {
		final source = "
			#test programmable() {
				placeholder(nothing, builderParameter(\"grid\")): 30, 40
			}
		";
		var factoryCallCount = 0;
		final gridObj = new h2d.Object();
		final bp:BuilderParameters = {
			placeholderObjects: ["grid" => PVComponent((_) -> {
				factoryCallCount++;
				return gridObj;
			}, null)],
		};

		final r = simulateReloadWithParams(source, source, "test", bp);

		// Component factory NOT re-called — reused as PVObject
		Assert.equals(1, factoryCallCount, "PVComponent factory should NOT be re-called during reload");
		Assert.isTrue(containsObject(r.oldResult.object, gridObj), "PVComponent object should be reused");
	}

	// ==================== Placeholder reuse: value callback re-invoked ====================

	@Test
	public function testHotReload_valueCallbackReInvoked():Void {
		// Name callback returns a scalar value used in expressions — should be re-invoked
		final source = "
			#test programmable() {
				bitmap(generated(color(callback(\"width\"), 10, #f00))): 0, 0
			}
		";
		var callbackCount = 0;
		final bp:BuilderParameters = {
			callback: (request) -> {
				switch request {
					case Name(name) if (name == "width"):
						callbackCount++;
						return CBRInteger(42);
					default:
						return CBRNoResult;
				}
			},
		};

		final r = simulateReloadWithParams(source, source, "test", bp);

		// Value callback should be called TWICE — once for initial build, once for reload
		Assert.equals(2, callbackCount, "Value callback should be re-invoked during reload");
		final bitmaps = findVisibleBitmapDescendants(r.oldResult.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(42, Std.int(bitmaps[0].tile.width));
	}

	// ==================== Placeholder reuse: mixed callback + builderParameter ====================

	@Test
	public function testHotReload_mixedCallbackAndBuilderParameter():Void {
		final source = "
			#test programmable() {
				placeholder(nothing, callback(\"fromCb\")): 0, 0
				placeholder(nothing, builderParameter(\"fromBp\")): 50, 0
			}
		";
		var cbCount = 0;
		var bpCount = 0;
		final cbObj = new h2d.Object();
		final bpObj = new h2d.Object();
		final bp:BuilderParameters = {
			callback: (request) -> {
				switch request {
					case Placeholder(name) if (name == "fromCb"):
						cbCount++;
						return CBRObject(cbObj);
					default:
						return CBRNoResult;
				}
			},
			placeholderObjects: ["fromBp" => PVFactory((_) -> {
				bpCount++;
				return bpObj;
			})],
		};

		final r = simulateReloadWithParams(source, source, "test", bp);

		// Both reused, neither re-called
		Assert.equals(1, cbCount, "Callback placeholder not re-called");
		Assert.equals(1, bpCount, "BuilderParameter factory not re-called");
		Assert.isTrue(containsObject(r.oldResult.object, cbObj), "Callback object reused");
		Assert.isTrue(containsObject(r.oldResult.object, bpObj), "BuilderParameter object reused");
	}

	// ==================== Placeholder reuse: position correctness (no doubling) ====================

	@Test
	public function testHotReload_placeholderPositionNotDoubled():Void {
		final source = "
			#test programmable() {
				placeholder(nothing, builderParameter(\"obj\")): 100, 200
			}
		";
		final myObj = new h2d.Object();
		final bp:BuilderParameters = {
			placeholderObjects: ["obj" => PVObject(myObj)],
		};

		final r = simulateReloadWithParams(source, source, "test", bp);

		// The object should be at (100, 200), not (200, 400) from doubling
		Assert.isTrue(containsObject(r.oldResult.object, myObj), "Object should be in tree");
		// Builder applies addPosition directly to the placeholder object
		Assert.floatEquals(100.0, myObj.x, "Object x should be 100 (not doubled to 200)");
		Assert.floatEquals(200.0, myObj.y, "Object y should be 200 (not doubled to 400)");
	}

	// ==================== Placeholder reuse: removed placeholder ====================

	@Test
	public function testHotReload_removedPlaceholderNotInTree():Void {
		final oldSource = "
			#test programmable() {
				placeholder(nothing, builderParameter(\"keep\")): 0, 0
				placeholder(nothing, builderParameter(\"remove\")): 50, 0
			}
		";
		final newSource = "
			#test programmable() {
				placeholder(nothing, builderParameter(\"keep\")): 0, 0
			}
		";
		final keepObj = new h2d.Object();
		final removeObj = new h2d.Object();
		final bp:BuilderParameters = {
			placeholderObjects: [
				"keep" => PVObject(keepObj),
				"remove" => PVObject(removeObj),
			],
		};

		final r = simulateReloadWithParams(oldSource, newSource, "test", bp);

		Assert.isTrue(containsObject(r.oldResult.object, keepObj), "Kept placeholder should be in tree");
		Assert.isFalse(containsObject(r.oldResult.object, removeObj), "Removed placeholder should NOT be in tree");
	}

	// ==================== Placeholder reuse: scene field preserved ====================

	@Test
	public function testPlaceholderReuser_sceneFieldPreserved():Void {
		final scene = new h2d.Scene();
		final bp:BuilderParameters = {
			callback: (_) -> CBRNoResult,
			scene: scene,
		};
		final captured:PlaceholderSnapshot = [{name: "x", index: null, object: new h2d.Object()}];
		final wrapped = PlaceholderReuser.wrapBuilderParams(bp, captured);

		Assert.equals(scene, wrapped.scene, "scene field should be preserved in wrapped params");
	}

	// ==================== Helper: find h2d.Object by identity in tree ====================

	static function containsObject(root:h2d.Object, target:h2d.Object):Bool {
		if (root == target) return true;
		for (i in 0...root.numChildren) {
			if (containsObject(root.getChildAt(i), target)) return true;
		}
		return false;
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

	// ==================== DynamicRef template swap: dev-resource lifetime ====================

	@Test
	public function testDynamicRefTemplateSwapWhileDetachedReleasesReloadHandle():Void {
		// Handle lifetime must not depend on the ReloadSentinel's onRemove(): Heaps only
		// fires onRemove for scene-ALLOCATED objects, and builder results in these tests
		// (like off-screen game UI) are never attached to a scene. When a dynamicRef
		// template swap discards the old child subtree, the discard path itself must
		// release the old child's reload handle — otherwise the registry accumulates one
		// dead handle per swap.
		final source = "
			#progA programmable() {
				bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
			#progB programmable() {
				bitmap(generated(color(20, 20, #00ff00))): 0, 0
			}
			#host programmable(template:string=\"progA\") {
				#child dynamicRef($template): 0, 0
			}
		";
		// Host root is NOT attached to any scene — the sentinel's onRemove never fires.
		final result = buildFromSource(source, "host", null, Incremental);
		Assert.notNull(result);

		final child = result.getDynamicRef("child");
		Assert.notNull(child, "named dynamicRef should be addressable as 'child'");

		// Manually register the CHILD result (no loader registry is wired in tests,
		// so nothing auto-registers — registration stays fully under test control).
		final registry = new ReloadableRegistry();
		final handle = registry.register("virtual.manim", child, "progA");
		child.reloadHandle = handle;
		Assert.equals(1, registry.getHandles("virtual.manim").length, "sanity: one handle after register");

		// Swap the template — the old child subtree is discarded while detached.
		result.setParameter("template", "progB");

		// The discarded child's handle must be released. The new child was never
		// registered by this test, so the registry must be empty.
		Assert.equals(0, registry.getHandles("virtual.manim").length,
			"discarding the old dynamicRef subtree must release its reload handle even when detached from any scene");

		// Swap again — the registry must not grow with stale handles per swap.
		result.setParameter("template", "progA");
		Assert.equals(0, registry.getHandles("virtual.manim").length,
			"repeated template swaps must not accumulate stale reload handles");
	}

	@Test
	public function testDynamicRefTemplateSwapCancelsOldSubtreeTransitionTweens():Void {
		// When a dynamicRef template swap discards the old child subtree, any in-flight
		// transition tweens owned by the old child's incremental context must be cancelled.
		// Otherwise they keep ticking against orphaned scene objects after the swap.
		final tm = new bh.base.TweenManager();
		final builder = builderFromSource("
			#tplA programmable(status:[a,b]=a) {
				transition {
					status: crossfade(0.5)
				}
				@(status=>a) bitmap(generated(color(10, 10, #ff0000))): 0, 0
				@(status=>b) bitmap(generated(color(10, 10, #00ff00))): 0, 0
			}
			#tplB programmable() {
				bitmap(generated(color(20, 20, #0000ff))): 0, 0
			}
			#host programmable(template:string=\"tplA\") {
				#child dynamicRef($template): 0, 0
			}
		");
		builder.tweenManager = tm;
		final result = builder.buildWithParameters("host", new Map(), null, null, true);
		Assert.notNull(result);

		final child = result.getDynamicRef("child");
		Assert.notNull(child, "named dynamicRef should be addressable as 'child'");
		final oldChildObject = child.object;

		// Start a crossfade on the old child and advance it mid-flight.
		child.setParameter("status", "b");
		tm.update(0.0); // consumed by skipFirstDt
		tm.update(0.1); // 0.1s into the 0.5s crossfade
		Assert.isTrue(subtreeHasTweens(tm, oldChildObject),
			"sanity: crossfade tweens must be active on the old child before the swap");

		// Swap the template — old subtree discarded mid-transition.
		result.setParameter("template", "tplB");

		Assert.isFalse(subtreeHasTweens(tm, oldChildObject),
			"discarding the old dynamicRef subtree must cancel its in-flight transition tweens");
	}

	// Recursive tween probe: TweenManager.hasTweens matches the exact target object,
	// but transition tweens target descendants (the conditional bitmaps), not the root.
	static function subtreeHasTweens(tm:bh.base.TweenManager, root:h2d.Object):Bool {
		if (tm.hasTweens(root)) return true;
		for (i in 0...root.numChildren) {
			if (subtreeHasTweens(tm, root.getChildAt(i))) return true;
		}
		return false;
	}

	// ==================== reloadable=false opt-out ====================

	@Test
	public function testReloadableFalseSkipsInPlaceReload():Void {
		// docs/hot-reload.md ("Controlling Reloadability") documents
		// `result.reloadable = false` as an opt-out. The flag is set by callers
		// AFTER buildWithParameters returns, so the reload loop itself must
		// consult it — registration-time reads can never see the opt-out.
		// Drives the real ScreenManager.hotReload() loop against a temp file.
		final fileName = "hotreload-optout-tmp.manim";
		final filePath = "test/res/" + fileName;
		final v1 = "version: 1.0\n"
			+ "#optout programmable() {\n"
			+ "	bitmap(generated(color(10, 10, #ff0000))): 0, 0\n"
			+ "}\n"
			+ "#normal programmable() {\n"
			+ "	bitmap(generated(color(10, 10, #00ff00))): 0, 0\n"
			+ "}\n";
		final v2 = "version: 1.0\n"
			+ "#optout programmable() {\n"
			+ "	bitmap(generated(color(99, 10, #ff0000))): 0, 0\n"
			+ "}\n"
			+ "#normal programmable() {\n"
			+ "	bitmap(generated(color(99, 10, #00ff00))): 0, 0\n"
			+ "}\n";
		sys.io.File.saveContent(filePath, v1);
		var caught:Null<Dynamic> = null;
		try {
			final sm = new bh.ui.screens.ScreenManager(bh.test.VisualTestBase.appInstance);
			final builder = sm.buildFromResourceName(fileName, false);
			final rOpt = builder.buildWithParameters("optout", new Map(), null, null, true);
			final rNorm = builder.buildWithParameters("normal", new Map(), null, null, true);

			Assert.equals(2, sm.hotReloadRegistry.getHandles(fileName).length,
				"sanity: both incremental results register reload handles");
			Assert.equals(10, Std.int(findVisibleBitmapDescendants(rOpt.object)[0].tile.width));

			// The documented opt-out — set after build, as any real caller would.
			rOpt.reloadable = false;

			sys.io.File.saveContent(filePath, v2);
			sm.hotReload();

			final normBitmaps = findVisibleBitmapDescendants(rNorm.object);
			Assert.equals(99, Std.int(normBitmaps[0].tile.width),
				"control: a reloadable result must be rebuilt in place by hotReload()");

			final optBitmaps = findVisibleBitmapDescendants(rOpt.object);
			Assert.equals(10, Std.int(optBitmaps[0].tile.width),
				"a result with reloadable=false must be skipped by the reload loop");
		} catch (e:Dynamic) {
			caught = e;
		}
		if (sys.FileSystem.exists(filePath))
			sys.FileSystem.deleteFile(filePath);
		if (caught != null)
			throw caught;
	}

	// ==================== Reload registration ====================
	// Which results a reload (and DevBridge) can reach: results of a screen that was switched
	// away and back, every screen sharing a file, a file named by DevBridge `reload`, and no
	// leftovers from `eval_manim`.

	static final ITEM_V1 = "version: 1.0\n#item programmable() {\n\tbitmap(generated(color(10, 10, #ff0000))): 0, 0\n}\n";
	static final ITEM_V2 = "version: 1.0\n#item programmable() {\n\tbitmap(generated(color(99, 10, #ff0000))): 0, 0\n}\n";

	/** Runs `body` with `test/res/<fileName>` holding `content`; the file is deleted afterwards. */
	static function withTempManim(fileName:String, content:String, body:String -> Void):Void {
		final filePath = "test/res/" + fileName;
		sys.io.File.saveContent(filePath, content);
		var caught:Null<Dynamic> = null;
		try {
			body(filePath);
		} catch (e:Dynamic) {
			caught = e;
		}
		if (sys.FileSystem.exists(filePath))
			sys.FileSystem.deleteFile(filePath);
		if (caught != null)
			throw caught;
	}

	static function itemWidth(result:BuilderResult):Int {
		return Std.int(findVisibleBitmapDescendants(result.object)[0].tile.width);
	}

	/** A root marked as on stage. Heaps fires onAdd/onRemove only under an allocated scene, and the
	 *  test app's s2d is allocated only after its first render — later than the unit tests run. */
	static function allocatedStage():h2d.Object {
		final stage = new h2d.Object();
		@:privateAccess stage.onAdd();
		return stage;
	}

	@Test
	public function testResultBackInSceneIsReloadableAgain():Void {
		final fileName = "hotreload-scene-tmp.manim";
		withTempManim(fileName, ITEM_V1, filePath -> {
			final sm = new bh.ui.screens.ScreenManager(bh.test.VisualTestBase.appInstance);
			final s2d = allocatedStage();
			final r = sm.buildFromResourceName(fileName, false).buildWithParameters("item", new Map(), null, null, true);
			s2d.addChild(r.object);
			Assert.equals(1, sm.hotReloadRegistry.getHandles(fileName).length, "sanity: registered while shown");

			// A screen switch takes the root out of the scene and later puts it back.
			r.object.remove();
			s2d.addChild(r.object);
			Assert.equals(1, sm.hotReloadRegistry.getHandles(fileName).length,
				"back in the scene, the result must be registered again");

			sys.io.File.saveContent(filePath, ITEM_V2);
			sm.hotReload();
			Assert.equals(99, itemWidth(r), "and a reload must reach it");
			r.object.remove();
		});
	}

	@Test
	public function testExplicitlyUnregisteredHandleStaysGoneWhenItsObjectIsAddedAgain():Void {
		final s2d = allocatedStage();
		final registry = new ReloadableRegistry();
		final r = buildFromSource("
			#p programmable() {
				bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
		", "p", null, Incremental);
		final handle = registry.register("virtual.manim", r, "p");
		registry.unregister(handle);

		s2d.addChild(r.object);
		Assert.equals(0, registry.getHandles("virtual.manim").length,
			"a discarded result must not come back just because its object is added to the scene");
		r.object.remove();
	}

	@Test
	public function testHotReloadReloadsEveryScreenThatSharesTheFile():Void {
		final fileName = "hotreload-shared-tmp.manim";
		withTempManim(fileName, ITEM_V1, filePath -> {
			final sm = new bh.ui.screens.ScreenManager(bh.test.VisualTestBase.appInstance);
			final a = new SharedFileScreen(sm, fileName);
			final b = new SharedFileScreen(sm, fileName);
			sm.addScreen("sharedA", a);
			sm.addScreen("sharedB", b);
			Assert.equals(1, a.loads);
			Assert.equals(1, b.loads);

			sys.io.File.saveContent(filePath, ITEM_V2);
			final report = sm.hotReload();

			Assert.equals(2, a.loads, "the first screen reloads once");
			Assert.equals(2, b.loads, "the second screen sharing the file reloads too");
			Assert.isTrue(report.success);
		});
	}

	@Test
	public function testBuildFromResourceNameKeepsOneEntryPerFile():Void {
		final fileName = "hotreload-cache-tmp.manim";
		withTempManim(fileName, ITEM_V1, _ -> {
			final sm = new bh.ui.screens.ScreenManager(bh.test.VisualTestBase.appInstance);
			final b1 = sm.buildFromResourceName(fileName, false);
			final b2 = sm.buildFromResourceName(fileName, false);
			Assert.equals(b1, b2);
			Assert.equals(1, sm.loadedManimPaths().length, "loading the same file twice keeps one builder entry");
		});
	}

	@Test
	public function testDevBridgeReloadByFileReloadsThatFile():Void {
		final fileName = "hotreload-bridge-tmp.manim";
		withTempManim(fileName, ITEM_V1, filePath -> {
			final sm = new bh.ui.screens.ScreenManager(bh.test.VisualTestBase.appInstance);
			final r = sm.buildFromResourceName(fileName, false).buildWithParameters("item", new Map(), null, null, true);
			sys.io.File.saveContent(filePath, ITEM_V2);

			final bridge = new bh.multianim.dev.DevBridge(sm, 0);
			final report:Dynamic = bridge.dispatch("reload", {file: fileName});

			Assert.equals(fileName, report.file, "the report names the reloaded file");
			Assert.equals(1, report.rebuiltCount, "the file's live result is rebuilt");
			Assert.equals(99, itemWidth(r));
		});
	}

	// ==================== In-place reload as a transaction ====================
	// A result built outside any screen is reloaded in place: the game keeps its `result.object`.
	// A failed rebuild must leave the live result as it was; a successful one must leave a result
	// whose later updates, re-shown elements and root properties reach the screen.

	/** Builds `name` from `v1`, lets `setup` act on it, then writes `v2` and hot-reloads. */
	static function reloadInPlace(fileName:String, v1:String, v2:String, name:String,
			check:(sm:bh.ui.screens.ScreenManager, result:BuilderResult, report:ReloadReport) -> Void,
			?params:Map<String, Dynamic>, ?setup:BuilderResult -> Void):Void {
		withTempManim(fileName, v1, filePath -> {
			final sm = new bh.ui.screens.ScreenManager(bh.test.VisualTestBase.appInstance);
			final result = sm.buildFromResourceName(fileName, false).buildWithParameters(name, params ?? new Map(), null, null, true);
			final stage = allocatedStage();
			stage.addChild(result.object);
			if (setup != null)
				setup(result);
			sys.io.File.saveContent(filePath, v2);
			final report = sm.hotReload();
			check(sm, result, report);
			result.object.remove();
		});
	}

	/** Product of the alphas from `obj` up to and including `root`. */
	static function alphaUpTo(obj:h2d.Object, root:h2d.Object):Float {
		var a = 1.0;
		var o:Null<h2d.Object> = obj;
		while (o != null) {
			a *= o.alpha;
			if (o == root)
				break;
			o = o.parent;
		}
		return a;
	}

	/** Whether any object from `obj` up to and including `root` carries a filter. */
	static function hasFilterUpTo(obj:h2d.Object, root:h2d.Object):Bool {
		var o:Null<h2d.Object> = obj;
		while (o != null) {
			if (o.filter != null)
				return true;
			if (o == root)
				break;
			o = o.parent;
		}
		return false;
	}

	@Test
	public function testFailedInPlaceReloadLeavesTheLiveResultIntact():Void {
		final v1 = "version: 1.0\n#host programmable() {\n\tbitmap(generated(color(10, 10, #ff0000))): 0, 0\n\t#s slot: 0, 20\n}\n";
		// Parses, but a root tint throws at build time (the programmable root is not a Drawable).
		final v2 = "version: 1.0\n#host programmable() {\n\ttint: #00ff00\n\tbitmap(generated(color(99, 10, #ff0000))): 0, 0\n\t#s slot: 0, 20\n}\n";
		final content = new h2d.Object();
		reloadInPlace("hotreload-fail-tmp.manim", v1, v2, "host", (sm, result, report) -> {
			Assert.isFalse(report.success, "sanity: the rebuild fails");
			Assert.equals(10, itemWidth(result), "the old tree stays on screen");
			Assert.equals(content, result.getSlot("s").getContent(), "slot content stays in its slot");
			Assert.notNull(content.parent, "and attached");
			Assert.equals(1, sm.hotReloadRegistry.getHandles("hotreload-fail-tmp.manim").length,
				"the result stays registered for the next reload");

			final retry = sm.hotReload();
			Assert.isFalse(retry.success, "reloading the same failing text fails again instead of reporting unchanged");
		}, null, result -> result.getSlot("s").setContent(content));
	}

	@Test
	public function testInPlaceReloadKeepsParamUsedInInteractiveId():Void {
		final v1 = "version: 1.0\n#host programmable(n:int=1) {\n\tbitmap(generated(color(10, 10, #ff0000))): 0, 0\n\tinteractive(10, 10, $n): 0, 0\n}\n";
		final v2 = "version: 1.0\n#host programmable(n:int=1) {\n\tbitmap(generated(color(99, 10, #ff0000))): 0, 0\n\tinteractive(10, 10, $n): 0, 0\n}\n";
		var thrown:Null<String> = null;
		try {
			reloadInPlace("hotreload-untracked-tmp.manim", v1, v2, "host", (sm, result, report) -> {
				Assert.isTrue(report.success, 'a param used in an interactive id must not break the reload: ${report.errors}');
				Assert.equals(99, itemWidth(result));
			}, ["n" => 2]);
		} catch (e:Dynamic) {
			thrown = Std.string(e);
		}
		Assert.isNull(thrown, 'hotReload must not throw: $thrown');
	}

	@Test
	public function testReshownElementAfterInPlaceReloadIsOnScreen():Void {
		final v1 = "version: 1.0\n#host programmable(show:bool=true) {\n\t@(show=>true) bitmap(generated(color(10, 10, #ff0000))): 0, 0\n}\n";
		final v2 = "version: 1.0\n#host programmable(show:bool=true) {\n\t@(show=>true) bitmap(generated(color(99, 10, #ff0000))): 0, 0\n}\n";
		reloadInPlace("hotreload-reshow-tmp.manim", v1, v2, "host", (sm, result, report) -> {
			Assert.isTrue(report.success);
			result.setParameter("show", false);
			result.setParameter("show", true);
			final bitmaps = findVisibleBitmapDescendants(result.object);
			Assert.equals(1, bitmaps.length, "a hidden-then-shown element must come back under the live result");
		});
	}

	@Test
	public function testRootParamAfterInPlaceReloadReachesTheScreen():Void {
		final v1 = "version: 1.0\n#host programmable(a:float=1.0) {\n\talpha: $a\n\tbitmap(generated(color(10, 10, #ff0000))): 0, 0\n}\n";
		final v2 = "version: 1.0\n#host programmable(a:float=1.0) {\n\talpha: $a\n\tbitmap(generated(color(99, 10, #ff0000))): 0, 0\n}\n";
		reloadInPlace("hotreload-rootparam-tmp.manim", v1, v2, "host", (sm, result, report) -> {
			Assert.isTrue(report.success);
			result.setParameter("a", 0.5);
			final bitmap = findVisibleBitmapDescendants(result.object)[0];
			Assert.floatEquals(0.5, alphaUpTo(bitmap, result.object), "a root-level $param set after reload must show");
		});
	}

	@Test
	public function testLiteralRootEditsApplyOnInPlaceReload():Void {
		final v1 = "version: 1.0\n#host programmable() {\n\talpha: 0.5\n\tfilter: glow(#ffff00, 0.6, 4)\n\tbitmap(generated(color(10, 10, #ff0000))): 0, 0\n}\n";
		final v2 = "version: 1.0\n#host programmable() {\n\talpha: 0.25\n\tbitmap(generated(color(99, 10, #ff0000))): 0, 0\n}\n";
		reloadInPlace("hotreload-rootedit-tmp.manim", v1, v2, "host", (sm, result, report) -> {
			Assert.isTrue(report.success);
			final bitmap = findVisibleBitmapDescendants(result.object)[0];
			Assert.floatEquals(0.25, alphaUpTo(bitmap, result.object),
				"an edited root alpha applies once (not the old value, not both multiplied)");
			Assert.isFalse(hasFilterUpTo(bitmap, result.object), "a root filter removed from the file is gone");
		});
	}

	@Test
	public function testRebuildListenersSurviveInPlaceReload():Void {
		final v1 = "version: 1.0\n#host programmable(n:int=0) {\n\tbitmap(generated(color(10, 10, #ff0000))): $n, 0\n}\n";
		final v2 = "version: 1.0\n#host programmable(n:int=0) {\n\tbitmap(generated(color(99, 10, #ff0000))): $n, 0\n}\n";
		var fired = 0;
		reloadInPlace("hotreload-listener-tmp.manim", v1, v2, "host", (sm, result, report) -> {
			Assert.isTrue(report.success);
			fired = 0;
			result.setParameter("n", 5);
			Assert.isTrue(fired > 0, "a rebuild listener added before the reload (screen sync, card resync) still fires");
		}, null, result -> result.addRebuildListener(() -> fired++));
	}

	@Test
	public function testTilemapThatNoLongerFitsItsTilesetFailsTheReload():Void {
		final fileName = "hotreload-tilemap-tmp.manim";
		final fits = "version: 1.0
" + bh.test.examples.TilemapTest.source('#m tilemap { tileset: plains size: 2, 1 legend { ".": grass } terrain: [".."] }');
		final unfit = "version: 1.0
" + bh.test.examples.TilemapTest.source('#m tilemap { tileset: plains size: 2, 1 legend { ".": lava } terrain: [".."] }');
		withTempManim(fileName, fits, filePath -> {
			final sm = new bh.ui.screens.ScreenManager(bh.test.VisualTestBase.appInstance);
			final map = sm.buildFromResourceName(fileName, false).buildTilemap("m");
			final stage = allocatedStage();
			stage.addChild(map);
			var failed = 0;
			sm.addReloadListener(event -> switch event {
				case ReloadFailed(_): failed++;
				default:
			});
			sys.io.File.saveContent(filePath, unfit);
			final report = sm.hotReload();
			Assert.isFalse(report.success, "the reload does not throw: it fails its report");
			Assert.equals(1, failed, "and says so to the listeners");
			Assert.equals("tilemap:m", report.errors[0].context);
			Assert.stringContains("lava", report.errors[0].message);
			Assert.equals("grass", map.terrainAt(0, 0), "the map stays as it was");
			Assert.isFalse(sm.hotReload().success, "the same text is tried again, not taken as unchanged");
			map.remove();
		});
	}

	@Test
	public function testEvalManimLeavesNoRegisteredResult():Void {
		final sm = new bh.ui.screens.ScreenManager(bh.test.VisualTestBase.appInstance);
		final bridge = new bh.multianim.dev.DevBridge(sm, 0);
		final result:Dynamic = bridge.dispatch("eval_manim", {source: ITEM_V1});
		Assert.isTrue(result.success, "sanity: the source builds");
		Assert.equals(0, sm.hotReloadRegistry.getHandles("<eval>").length,
			"an eval build must not stay registered as a live programmable");
	}
}

/** Builds `item` from a shared file on every load, counting loads. */
private class SharedFileScreen extends bh.ui.screens.UIScreen.UIScreenBase {
	final fileName:String;

	public var loads:Int = 0;

	public function new(sm:bh.ui.screens.ScreenManager, fileName:String) {
		super(sm);
		this.fileName = fileName;
	}

	public function load():Void {
		loads++;
		final builder = screenManager.buildFromResourceName(fileName, false);
		addObjectToLayer(builder.buildWithParameters("item", new Map(), null, null, true).object);
	}

	public function onScreenEvent(event:bh.ui.UIElement.UIScreenEvent, source:Null<bh.ui.UIElement>):Void {}
}
#end
