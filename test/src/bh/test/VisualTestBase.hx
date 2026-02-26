package bh.test;

import h3d.mat.Texture;
import hxd.Pixels;
import utest.Assert;
import h2d.col.IBounds;
import h2d.Scene;

class VisualTestBase extends utest.Test {
	private var referenceDir:String;
	private var testName:String;
	private var testTitle:String;
	private var s2d:Scene;
	private var updateWaiter:Null<Float -> Void>;
	public static var appInstance:hxd.App;
	public static var pendingVisualTests:Int = 0;

	private static inline function verbose(msg:String):Void {
		#if VERBOSE
		trace(msg);
		#end
	}

	public function new(testName:String, s2d:Scene) {
		super();
		if (s2d == null) {
			throw "Warning: Scene not provided to VisualTestBase for test '$testName'";
		}
		this.testName = testName;
		this.s2d = s2d;
		this.referenceDir = 'test/examples/$testName';

		var screenshotDir = "test/screenshots";
		if (!sys.FileSystem.exists(screenshotDir)) {
			sys.FileSystem.createDirectory(screenshotDir);
		}

		if (appInstance != null && Std.isOfType(appInstance, TestApp)) {
			cast(appInstance, TestApp).subscribeToUpdate(onAppUpdate);
		}
	}

	private function onAppUpdate(dt:Float):Void {
		if (updateWaiter != null) {
			var callback = updateWaiter;
			updateWaiter = null;
			try {
				callback(dt);
			} catch (e:Dynamic) {
				trace('Error in waitForUpdate callback: $e');
				if (pendingVisualTests > 0)
					pendingVisualTests--;
			}
		}
	}

	public function waitForUpdate(callback:Float -> Void):Void {
		updateWaiter = callback;
	}

	// ==================== Setup helpers ====================

	private function setupTest(num:Int, name:String, ?title:String):Void {
		this.testName = name;
		this.testTitle = title != null ? title : '#$num: $name';
		this.referenceDir = 'test/examples/$num-$name';
	}

	private static function manimPath(num:Int, name:String):String {
		return 'test/examples/$num-$name/$name.manim';
	}

	// ==================== Simple visual test ====================

	public function simpleTest(num:Int, name:String, async:utest.Async, ?programmableName:String,
			?title:String, ?scale:Float):Void {
		setupTest(num, name, title);
		var progName = programmableName != null ? programmableName : name;
		var s = scale != null ? scale : 1.0;
		buildRenderScreenshotAndCompare(manimPath(num, name), progName, async, 1280, 720, s);
	}

	public function simpleMacroTest(num:Int, name:String, createMacroRoot:() -> h2d.Object,
			async:utest.Async, ?programmableName:String, ?title:String, ?scale:Float, ?threshold:Float):Void {
		setupTest(num, name, title);
		var progName = programmableName != null ? programmableName : name;
		var s = scale != null ? scale : 1.0;
		builderAndMacroScreenshotAndCompare(manimPath(num, name), progName, createMacroRoot, async, 1280, 720, s, threshold);
	}

	// ==================== Build and render ====================

	public function buildAndAddToScene(animFilePath:String, name:String, ?scale:Float):Dynamic {
		s2d.removeChildren();

		if (scale == null) scale = 1.0;

		try {
			var fileContent = byte.ByteData.ofString(sys.io.File.getContent(animFilePath));
			var loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
			var builder = bh.multianim.MultiAnimBuilder.load(fileContent, loader, animFilePath);

			var built = builder.buildWithParameters(name, new Map(), {scene: s2d});
			verbose('Built element "$name" from $animFilePath: $built');
			if (built == null) {
				throw 'Error: Failed to build element "$name" from $animFilePath';
			}
			s2d.addChild(built.object);
			built.object.setScale(scale);

			if (testTitle != null && testTitle.length > 0) {
				addTitleOverlay();
			}

			return built;
		} catch (e:Dynamic) {
			trace('Error building animation from $animFilePath: $e');
			return null;
		}
	}

	private function addTitleOverlay():Void {
		var loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
		var font = loader.loadFont("dd");
		if (font != null) {
			var text = new h2d.Text(font, s2d);
			text.text = testTitle;
			text.textColor = 0xFFFFFF;
			text.textAlign = Right;
			text.setPosition(1260, 20);
			text.alpha = 0.9;
		}
	}

	public function clearScene() {
		if (s2d != null) {
			s2d.removeChildren();
		}
	}

	// ==================== Screenshot ====================

	/**
	 * Render scene to off-screen texture, encode PNG on main thread.
	 * Returns PNG bytes or null if image is empty. No Heaps objects leak out.
	 */
	public function captureScreenshotPng(?sizeX:Int, ?sizeY:Int):Null<haxe.io.Bytes> {
		if (appInstance == null) {
			trace("Warning: App instance not available for screenshot");
			return null;
		}

		if (sizeX == null) sizeX = 1280;
		if (sizeY == null) sizeY = 720;

		var e = appInstance.engine;
		var renderTexture = new Texture(sizeX, sizeY, [Target]);

		e.pushTarget(renderTexture);
		e.clear(0x1f1f1fff, 1);
		s2d.render(e);

		var pixels = renderTexture.capturePixels(0, 0, IBounds.fromValues(0, 0, sizeX, sizeY));

		e.popTarget();
		renderTexture.dispose();

		// Quick empty check
		pixels.convert(BGRA);
		var b = pixels.bytes;
		var off = pixels.offset;
		var total = pixels.width * pixels.height;
		var empty = true;
		for (i in 0...total) {
			if (b.getInt32((i << 2) + off) != 0xff1f1f1f) {
				empty = false;
				break;
			}
		}

		if (empty) {
			pixels.dispose();
			return null;
		}

		// Encode PNG on main thread — only raw Bytes leave this method
		var pngBytes = pixels.toPNG();
		pixels.dispose();
		return pngBytes;
	}

	// ==================== Path helpers ====================

	public function getReferenceImagePath():String {
		return '$referenceDir/reference.png';
	}

	public function getActualImagePath():String {
		return 'test/screenshots/${testName}_actual.png';
	}

	public function getDisplayName():String {
		var displayName = testName;
		if (referenceDir != null) {
			var dirName = haxe.io.Path.withoutDirectory(referenceDir);
			var dashIdx = dirName.indexOf("-");
			if (dashIdx > 0) {
				var num = dirName.substring(0, dashIdx);
				displayName = '#$num: $testName';
			}
		}
		return displayName;
	}

	private function reportBuildFailure(errorMessage:String, ?orderIndex:Int):Void {
		HtmlReportGenerator.addResult(getDisplayName(), getReferenceImagePath(), getActualImagePath(), false, 0.0, errorMessage, null, orderIndex);
	}

	// ==================== Async visual test methods ====================

	/**
	 * Build, render, capture, and enqueue comparison with reference.
	 */
	public function buildRenderScreenshotAndCompare(animFilePath:String, elementName:String,
			async:utest.Async, ?sizeX:Int, ?sizeY:Int, ?scale:Float):Void {
		var orderIdx = HtmlReportGenerator.reserveOrderIndex();
		pendingVisualTests++;
		async.setTimeout(10000);
		clearScene();

		var result:Dynamic = null;
		try {
			result = buildAndAddToScene(animFilePath, elementName, scale);
		} catch (e:Dynamic) {
			var msg = 'Build threw exception for "$elementName" from $animFilePath: $e';
			reportBuildFailure(msg, orderIdx);
			Assert.fail(msg);
			pendingVisualTests--;
			async.done();
			return;
		}

		if (result == null) {
			var msg = 'Failed to build element "$elementName" from $animFilePath';
			reportBuildFailure(msg, orderIdx);
			Assert.fail(msg);
			pendingVisualTests--;
			async.done();
			return;
		}

		waitForUpdate(function(dt:Float) {
			var actualPath = getActualImagePath();
			var referencePath = getReferenceImagePath();
			var displayName = getDisplayName();
			var pngBytes = captureScreenshotPng(sizeX, sizeY);

			if (pngBytes == null) {
				Assert.fail('Screenshot was empty at $actualPath');
			} else {
				Assert.pass();
				sys.io.File.saveBytes(actualPath, pngBytes);
				var similarity = computeSimilarityFromPngFiles(actualPath, referencePath);
				var passed = similarity >= 1.0;
				HtmlReportGenerator.addResult(displayName, referencePath, actualPath, passed, similarity, null, 1.0, orderIdx);
			}
			pendingVisualTests--;
			async.done();
		});
	}

	/**
	 * Build builder + macro, capture both, enqueue comparison.
	 */
	public function builderAndMacroScreenshotAndCompare(animFilePath:String, elementName:String, createMacroRoot:() -> h2d.Object,
			async:utest.Async, ?sizeX:Int, ?sizeY:Int, ?scale:Float, ?threshold:Float):Void {
		var orderIdx = HtmlReportGenerator.reserveOrderIndex();
		pendingVisualTests++;
		async.setTimeout(15000);
		if (sizeX == null) sizeX = 1280;
		if (sizeY == null) sizeY = 720;
		if (scale == null) scale = 1.0;
		if (threshold == null) threshold = 1.0;

		// Phase 1: builder
		clearScene();
		var result:Dynamic = null;
		try {
			result = buildAndAddToScene(animFilePath, elementName, scale);
		} catch (e:Dynamic) {
			var msg = 'Builder build threw exception for "$elementName": $e';
			reportBuildFailure(msg, orderIdx);
			Assert.fail(msg);
			pendingVisualTests--;
			async.done();
			return;
		}

		if (result == null) {
			var msg = 'Failed to build element "$elementName" from $animFilePath';
			reportBuildFailure(msg, orderIdx);
			Assert.fail(msg);
			pendingVisualTests--;
			async.done();
			return;
		}

		waitForUpdate(function(dt:Float) {
			var builderPath = 'test/screenshots/${testName}_actual.png';
			var builderPng = captureScreenshotPng(sizeX, sizeY);

			// Phase 2: macro
			clearScene();
			var macroRoot:h2d.Object = null;
			try {
				macroRoot = createMacroRoot();
			} catch (e:Dynamic) {
				Assert.fail('Macro createRoot() threw: $e');
				if (builderPng != null) {
					var referencePath = getReferenceImagePath();
					var displayName = getDisplayName();
					var th = threshold;
					sys.io.File.saveBytes(builderPath, builderPng);
					var sim = computeSimilarityFromPngFiles(builderPath, referencePath);
					HtmlReportGenerator.addResult(displayName, referencePath, builderPath, sim >= th, sim, null, th, orderIdx);
				}
				pendingVisualTests--;
				async.done();
				return;
			}

			s2d.addChild(macroRoot);
			macroRoot.setScale(scale);

			if (testTitle != null && testTitle.length > 0) {
				addTitleOverlay();
			}

			waitForUpdate(function(dt2:Float) {
				var macroPath = 'test/screenshots/${testName}_macro.png';
				var referencePath = getReferenceImagePath();
				var macroPng = captureScreenshotPng(sizeX, sizeY);
				var displayName = getDisplayName();
				var th = threshold;

				Assert.pass();
				if (builderPng != null)
					sys.io.File.saveBytes(builderPath, builderPng);
				if (macroPng != null)
					sys.io.File.saveBytes(macroPath, macroPng);

				var builderSim = builderPng != null ? computeSimilarityFromPngFiles(builderPath, referencePath) : 0.0;
				var macroSim = macroPng != null ? computeSimilarityFromPngFiles(macroPath, referencePath) : 0.0;
				var builderOk = builderSim >= th;
				var macroOk = macroSim >= th;

				HtmlReportGenerator.addResultWithMacro(displayName, referencePath, builderPath, builderOk && macroOk,
					builderSim, null, macroPath, macroSim, macroOk, th, th, orderIdx);

				pendingVisualTests--;
				async.done();
			});
		});
	}

	/**
	 * Multi-instance macro vs builder test.
	 */
	public function multiInstanceMacroTest(num:Int, name:String, scale:Float, spacing:Float,
			builderParams:Array<Map<String, Dynamic>>, createMacroRoots:(index:Int) -> h2d.Object,
			async:utest.Async, ?tolerance:Null<Float>):Void {
		setupTest(num, name);
		var orderIdx = HtmlReportGenerator.reserveOrderIndex();
		pendingVisualTests++;
		async.setTimeout(15000);

		var animFilePath = manimPath(num, name);
		var variantCount = builderParams.length;

		// Phase 1: builder
		clearScene();
		var container = new h2d.Object(s2d);
		container.setScale(scale);

		try {
			var fileContent = byte.ByteData.ofString(sys.io.File.getContent(animFilePath));
			var loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
			var builder = bh.multianim.MultiAnimBuilder.load(fileContent, loader, animFilePath);

			for (i in 0...variantCount) {
				var built = builder.buildWithParameters(name, builderParams[i]);
				if (built != null && built.object != null) {
					built.object.setPosition(0, i * spacing);
					container.addChild(built.object);
				}
			}
		} catch (e:Dynamic) {
			var msg = 'Builder build threw exception for "$name": $e';
			reportBuildFailure(msg, orderIdx);
			Assert.fail(msg);
			pendingVisualTests--;
			async.done();
			return;
		}

		if (testTitle != null && testTitle.length > 0) addTitleOverlay();

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderPng = captureScreenshotPng(1280, 720);

			// Phase 2: macro
			clearScene();
			var mc = new h2d.Object(s2d);
			mc.setScale(scale);

			try {
				for (i in 0...variantCount) {
					var root = createMacroRoots(i);
					root.setPosition(0, i * spacing);
					mc.addChild(root);
				}
			} catch (e:Dynamic) {
				Assert.fail('Macro createRoot() threw: $e');
				pendingVisualTests--;
				async.done();
				return;
			}

			if (testTitle != null && testTitle.length > 0) addTitleOverlay();

			waitForUpdate(function(dt2:Float) {
				var macroPath = 'test/screenshots/${testName}_macro.png';
				var referencePath = getReferenceImagePath();
				var macroPng = captureScreenshotPng(1280, 720);
				var displayName = getDisplayName();
				var th:Float = if (tolerance != null) tolerance else 1.0;

				Assert.pass();
				if (builderPng != null)
					sys.io.File.saveBytes(builderPath, builderPng);
				if (macroPng != null)
					sys.io.File.saveBytes(macroPath, macroPng);

				var builderSim = builderPng != null ? computeSimilarityFromPngFiles(builderPath, referencePath) : 0.0;
				var macroSim = macroPng != null ? computeSimilarityFromPngFiles(macroPath, referencePath) : 0.0;
				var builderOk = builderSim >= th;
				var macroOk = macroSim >= th;

				HtmlReportGenerator.addResultWithMacro(displayName, referencePath, builderPath, builderOk && macroOk,
					builderSim, null, macroPath, macroSim, macroOk, th, th, orderIdx);

				pendingVisualTests--;
				async.done();
			});
		});
	}

	/**
	 * Multi-instance macro vs builder test using .manim layout for positioning.
	 */
	public function layoutMacroTest(num:Int, name:String, layoutName:String, scale:Float,
			builderParams:Array<Map<String, Dynamic>>, createMacroRoots:(index:Int) -> h2d.Object,
			async:utest.Async, ?tolerance:Null<Float>):Void {
		setupTest(num, name);
		var orderIdx = HtmlReportGenerator.reserveOrderIndex();
		pendingVisualTests++;
		async.setTimeout(15000);

		var animFilePath = manimPath(num, name);
		var variantCount = builderParams.length;

		// Phase 1: builder
		clearScene();
		var container = new h2d.Object(s2d);
		container.setScale(scale);

		var layoutPoints:Array<h2d.col.Point> = [];
		try {
			var fileContent = byte.ByteData.ofString(sys.io.File.getContent(animFilePath));
			var loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
			var builder = bh.multianim.MultiAnimBuilder.load(fileContent, loader, animFilePath);
			var layouts = builder.getLayouts();

			for (i in 0...variantCount) {
				var pt = layouts.getPoint(layoutName, i);
				layoutPoints.push(new h2d.col.Point(pt.x, pt.y));
				var built = builder.buildWithParameters(name, builderParams[i]);
				if (built != null && built.object != null) {
					built.object.setPosition(pt.x, pt.y);
					container.addChild(built.object);
				}
			}
		} catch (e:Dynamic) {
			var msg = 'Builder build threw exception for "$name": $e';
			reportBuildFailure(msg, orderIdx);
			Assert.fail(msg);
			pendingVisualTests--;
			async.done();
			return;
		}

		if (testTitle != null && testTitle.length > 0) addTitleOverlay();

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderPng = captureScreenshotPng(1280, 720);

			// Phase 2: macro
			clearScene();
			var mc = new h2d.Object(s2d);
			mc.setScale(scale);

			try {
				for (i in 0...variantCount) {
					var root = createMacroRoots(i);
					root.setPosition(layoutPoints[i].x, layoutPoints[i].y);
					mc.addChild(root);
				}
			} catch (e:Dynamic) {
				Assert.fail('Macro createRoot() threw: $e');
				pendingVisualTests--;
				async.done();
				return;
			}

			if (testTitle != null && testTitle.length > 0) addTitleOverlay();

			waitForUpdate(function(dt2:Float) {
				var macroPath = 'test/screenshots/${testName}_macro.png';
				var referencePath = getReferenceImagePath();
				var macroPng = captureScreenshotPng(1280, 720);
				var displayName = getDisplayName();
				var th:Float = if (tolerance != null) tolerance else 1.0;

				Assert.pass();
				if (builderPng != null)
					sys.io.File.saveBytes(builderPath, builderPng);
				if (macroPng != null)
					sys.io.File.saveBytes(macroPath, macroPng);

				var builderSim = builderPng != null ? computeSimilarityFromPngFiles(builderPath, referencePath) : 0.0;
				var macroSim = macroPng != null ? computeSimilarityFromPngFiles(macroPath, referencePath) : 0.0;
				var builderOk = builderSim >= th;
				var macroOk = macroSim >= th;

				HtmlReportGenerator.addResultWithMacro(displayName, referencePath, builderPath, builderOk && macroOk,
					builderSim, null, macroPath, macroSim, macroOk, th, th, orderIdx);

				pendingVisualTests--;
				async.done();
			});
		});
	}

	// ==================== Synchronous screenshot/compare (for custom test patterns) ====================

	/**
	 * Capture screenshot and save synchronously. Returns true if non-empty.
	 */
	public function screenshot(outputFile:String, ?sizeX:Int, ?sizeY:Int):Bool {
		var pngBytes = captureScreenshotPng(sizeX, sizeY);
		if (pngBytes == null) return false;
		sys.io.File.saveBytes(outputFile, pngBytes);
		return true;
	}

	/**
	 * Compare actual vs reference image synchronously. Returns true if similarity >= threshold.
	 */
	public function compareImages(actual:String, reference:String, ?threshold:Float):Bool {
		if (threshold == null) threshold = 1.0;
		var similarity = computeSimilarityFromPngFiles(actual, reference);
		return similarity >= threshold;
	}

	/**
	 * Compute similarity between two image files synchronously.
	 */
	public function computeSimilarity(actual:String, reference:String):Float {
		return computeSimilarityFromPngFiles(actual, reference);
	}

	// ==================== Pixel comparison ====================

	/** Decode PNG bytes to raw pixel data. */
	private static function decodePng(pngBytes:haxe.io.Bytes):{bytes:haxe.io.Bytes, width:Int, height:Int} {
		var reader = new format.png.Reader(new haxe.io.BytesInput(pngBytes));
		var data = reader.read();
		var header = format.png.Tools.getHeader(data);
		var pixels = format.png.Tools.extract32(data);
		return {bytes: pixels, width: header.width, height: header.height};
	}

	/**
	 * Load two PNGs from disk and compute pixel similarity (0.0 to 1.0).
	 */
	public static function computeSimilarityFromPngFiles(actual:String, reference:String):Float {
		if (!sys.FileSystem.exists(reference)) return 0.0;
		if (!sys.FileSystem.exists(actual)) return 0.0;

		try {
			var p1 = decodePng(sys.io.File.getBytes(actual));
			var p2 = decodePng(sys.io.File.getBytes(reference));
			if (p1.width != p2.width || p1.height != p2.height) return 0.0;

			var b1 = p1.bytes;
			var b2 = p2.bytes;
			var totalPixels = p1.width * p1.height;
			var matchingPixels = 0;
			for (i in 0...totalPixels) {
				var p = i << 2;
				var c1 = b1.getInt32(p);
				var c2 = b2.getInt32(p);
				if (c1 == c2) {
					matchingPixels++;
				} else {
					var dr = ((c1 >> 16) & 0xFF) - ((c2 >> 16) & 0xFF);
					var dg = ((c1 >> 8) & 0xFF) - ((c2 >> 8) & 0xFF);
					var db = (c1 & 0xFF) - (c2 & 0xFF);
					if (dr < 0) dr = -dr;
					if (dg < 0) dg = -dg;
					if (db < 0) db = -db;
					if (Math.sqrt(dr * dr + dg * dg + db * db) < 5)
						matchingPixels++;
				}
			}
			return matchingPixels / totalPixels;
		} catch (e:Dynamic) {
			return 0.0;
		}
	}

	/** Format similarity with diff pixel count when percentage rounds to 100% but isn't exact. */
	public static function fmtSim(similarity:Float, totalPixels:Int = 921600):String {
		var pct = Math.round(similarity * 10000) / 100;
		if (pct >= 100.0 && similarity < 1.0) {
			var diffPixels = totalPixels - Math.round(similarity * totalPixels);
			return '${pct}% (${diffPixels}px differ)';
		}
		return '${pct}%';
	}
}
