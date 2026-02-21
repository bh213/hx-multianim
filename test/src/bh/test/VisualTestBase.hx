package bh.test;

import h3d.mat.Texture;
import hxd.Pixels;
import hxd.File;
import utest.Assert;
import h2d.col.IBounds;
import hxd.res.Image;
import hxd.Res;
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

	/**
	 * Configure test metadata from a test number and name.
	 * Derives testName, testTitle, and referenceDir from the number and name.
	 */
	private function setupTest(num:Int, name:String, ?title:String):Void {
		this.testName = name;
		this.testTitle = title != null ? title : '#$num: $name';
		this.referenceDir = 'test/examples/$num-$name';
	}

	/**
	 * Get the manim file path for a test number and name.
	 */
	private static function manimPath(num:Int, name:String):String {
		return 'test/examples/$num-$name/$name.manim';
	}

	// ==================== Simple visual test ====================

	/**
	 * One-liner for simple builder-only visual tests.
	 * @param num Test number
	 * @param name Test name (used for directory, manim file, and programmable name)
	 * @param async utest async handle
	 * @param programmableName Override programmable name if different from test name
	 * @param title Override title if desired
	 * @param scale Scale factor (default 1.0)
	 */
	public function simpleTest(num:Int, name:String, async:utest.Async, ?programmableName:String,
			?title:String, ?scale:Float):Void {
		setupTest(num, name, title);
		var progName = programmableName != null ? programmableName : name;
		var s = scale != null ? scale : 1.0;
		buildRenderScreenshotAndCompare(manimPath(num, name), progName, async, 1280, 720, s);
	}

	/**
	 * One-liner for macro vs builder visual tests.
	 * @param num Test number
	 * @param name Test name
	 * @param createMacroRoot Function that creates the macro-generated root object
	 * @param async utest async handle
	 * @param programmableName Override programmable name if different from test name
	 * @param title Override title if desired
	 * @param scale Scale factor (default 1.0)
	 */
	public function simpleMacroTest(num:Int, name:String, createMacroRoot:() -> h2d.Object,
			async:utest.Async, ?programmableName:String, ?title:String, ?scale:Float, ?threshold:Float):Void {
		setupTest(num, name, title);
		var progName = programmableName != null ? programmableName : name;
		var s = scale != null ? scale : 1.0;
		builderAndMacroScreenshotAndCompare(manimPath(num, name), progName, createMacroRoot, async, 1280, 720, s, threshold);
	}

	// ==================== Build and render ====================

	/**
	 * Build a manim file and add it to the scene.
	 * @param scale Scale factor (default 1.0)
	 */
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

	/**
	 * Add a title text overlay to the top-right of the scene.
	 */
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

	public function screenshot(outputFile:String, ?sizeX:Int, ?sizeY:Int):Bool {
		if (appInstance == null) {
			trace("Warning: App instance not available for screenshot");
			return false;
		}

		if (sizeX == null) sizeX = 1280;
		if (sizeY == null) sizeY = 720;

		var e = appInstance.engine;
		var renderTexture = new Texture(sizeX, sizeY, [Target]);

		e.pushTarget(renderTexture);
		e.clear(0x1f1f1fff, 1);
		s2d.render(e);

		var pixels = renderTexture.capturePixels(0, 0, IBounds.fromValues(0, 0, sizeX, sizeY));
		var empty = true;
		for (x in 0...pixels.width) {
			for (y in 0...pixels.height) {
				if (pixels.getPixel(x, y) != 0xff1f1f1f) {
					empty = false;
					break;
				}
			}
			if (!empty) break;
		}

		if (!empty) {
			File.saveBytes(outputFile, pixels.toPNG());
			verbose('Screenshot saved: $outputFile');
		}
		e.popTarget();
		renderTexture.dispose();

		return !empty;
	}

	// ==================== Image comparison ====================

	public function compareImages(actual:String, reference:String, ?threshold:Float):Bool {
		if (threshold == null) threshold = 0.9999;
		var similarity = 1.0;
		var passed = true;

		if (!sys.FileSystem.exists(reference)) {
			trace('Reference image not found: $reference — run gen-refs to create it');
			passed = false;
			similarity = 0.0;
		} else if (!sys.FileSystem.exists(actual)) {
			trace('Error: Actual image not found: $actual');
			passed = false;
			similarity = 0.0;
		} else {
			try {
				var actualBytes = sys.io.File.getBytes(actual);
				var referenceBytes = sys.io.File.getBytes(reference);

				var p1 = hxd.res.Any.fromBytes(actual, actualBytes).toImage().getPixels();
				var p2 = hxd.res.Any.fromBytes(reference, referenceBytes).toImage().getPixels();

				if (p1.width != p2.width || p1.height != p2.height) {
					trace('Image dimensions mismatch: actual ${p1.width}x${p1.height} vs reference ${p2.width}x${p2.height}');
					passed = false;
					similarity = 0.0;
				} else {
					var totalPixels = p1.width * p1.height;
					var matchingPixels = 0;

					for (x in 0...p1.width) {
						for (y in 0...p1.height) {
							if (colorDistance(p1.getPixel(x, y), p2.getPixel(x, y)) < 5) {
								matchingPixels++;
							}
						}
					}

					similarity = matchingPixels / totalPixels;
					verbose('Image similarity: ${Math.round(similarity * 10000) / 100}%');
					passed = similarity > threshold;
				}
			} catch (e:Dynamic) {
				trace('Error comparing images: $e');
				passed = false;
				similarity = 0.0;
			}
		}

		HtmlReportGenerator.addResult(getDisplayName(), reference, actual, passed, similarity, null, threshold);
		HtmlReportGenerator.generateReport();

		return passed;
	}

	private function colorDistance(c1:Int, c2:Int):Float {
		var r1 = (c1 >> 16) & 0xFF;
		var g1 = (c1 >> 8) & 0xFF;
		var b1 = c1 & 0xFF;

		var r2 = (c2 >> 16) & 0xFF;
		var g2 = (c2 >> 8) & 0xFF;
		var b2 = c2 & 0xFF;

		var dr = r1 - r2;
		var dg = g1 - g2;
		var db = b1 - b2;

		return Math.sqrt(dr * dr + dg * dg + db * db);
	}

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

	private function reportBuildFailure(errorMessage:String):Void {
		HtmlReportGenerator.addResult(getDisplayName(), getReferenceImagePath(), getActualImagePath(), false, 0.0, errorMessage);
		HtmlReportGenerator.generateReport();
	}

	// ==================== Async visual test methods ====================

	/**
	 * Build, render, screenshot, and compare with reference.
	 * Handles errors gracefully — if build fails, the test fails with an assertion rather than getting stuck.
	 */
	public function buildRenderScreenshotAndCompare(animFilePath:String, elementName:String,
			async:utest.Async, ?sizeX:Int, ?sizeY:Int, ?scale:Float):Void {
		pendingVisualTests++;
		async.setTimeout(10000);
		clearScene();

		var result:Dynamic = null;
		try {
			result = buildAndAddToScene(animFilePath, elementName, scale);
		} catch (e:Dynamic) {
			var msg = 'Build threw exception for "$elementName" from $animFilePath: $e';
			reportBuildFailure(msg);
			Assert.fail(msg);
			pendingVisualTests--;
			async.done();
			return;
		}

		if (result == null) {
			var msg = 'Failed to build element "$elementName" from $animFilePath';
			reportBuildFailure(msg);
			Assert.fail(msg);
			pendingVisualTests--;
			async.done();
			return;
		}

		waitForUpdate(function(dt:Float) {
			try {
				var actualPath = getActualImagePath();
				var referencePath = getReferenceImagePath();

				var success = screenshot(actualPath, sizeX, sizeY);
				Assert.isTrue(success, 'Screenshot should be created at $actualPath');

				if (success) {
					var match = compareImages(actualPath, referencePath);
					Assert.isTrue(match, 'Screenshot should match reference image');
				}
			} catch (e:Dynamic) {
				Assert.fail('Screenshot/compare threw: $e');
			}
			pendingVisualTests--;
			async.done();
		});
	}

	/**
	 * Build builder output, take screenshot, then build macro output, take screenshot,
	 * compare both to reference. Reports as a single result with 3 images.
	 * Handles errors gracefully — if build or macro creation fails, the test fails with an assertion.
	 */
	public function builderAndMacroScreenshotAndCompare(animFilePath:String, elementName:String, createMacroRoot:() -> h2d.Object,
			async:utest.Async, ?sizeX:Int, ?sizeY:Int, ?scale:Float, ?threshold:Float):Void {
		pendingVisualTests++;
		async.setTimeout(15000);
		if (sizeX == null) sizeX = 1280;
		if (sizeY == null) sizeY = 720;
		if (scale == null) scale = 1.0;
		if (threshold == null) threshold = 0.99;

		// Phase 1: builder screenshot
		clearScene();
		var result:Dynamic = null;
		try {
			result = buildAndAddToScene(animFilePath, elementName, scale);
		} catch (e:Dynamic) {
			var msg = 'Builder build threw exception for "$elementName": $e';
			reportBuildFailure(msg);
			Assert.fail(msg);
			pendingVisualTests--;
			async.done();
			return;
		}

		if (result == null) {
			var msg = 'Failed to build element "$elementName" from $animFilePath';
			reportBuildFailure(msg);
			Assert.fail(msg);
			pendingVisualTests--;
			async.done();
			return;
		}

		waitForUpdate(function(dt:Float) {
			var builderPath = 'test/screenshots/${testName}_actual.png';
			var builderSuccess = false;
			try {
				builderSuccess = screenshot(builderPath, sizeX, sizeY);
			} catch (e:Dynamic) {
				Assert.fail('Builder screenshot threw: $e');
				pendingVisualTests--;
				async.done();
				return;
			}

			// Phase 2: macro screenshot
			clearScene();
			var macroRoot:h2d.Object = null;
			try {
				macroRoot = createMacroRoot();
			} catch (e:Dynamic) {
				Assert.fail('Macro createRoot() threw: $e');
				var referencePath = getReferenceImagePath();
				if (builderSuccess) {
					compareImages(builderPath, referencePath);
				}
				pendingVisualTests--;
				async.done();
				return;
			}

			macroRoot.setScale(scale);
			s2d.addChild(macroRoot);

			if (testTitle != null && testTitle.length > 0) {
				addTitleOverlay();
			}

			waitForUpdate(function(dt2:Float) {
				try {
					var macroPath = 'test/screenshots/${testName}_macro.png';
					var referencePath = getReferenceImagePath();

					var macroSuccess = screenshot(macroPath, sizeX, sizeY);

					var builderSimilarity = builderSuccess ? computeSimilarity(builderPath, referencePath) : 0.0;
					var builderPassed = builderSuccess ? builderSimilarity > threshold : false;

					var macroSimilarity = macroSuccess ? computeSimilarity(macroPath, referencePath) : 0.0;
					var macroPassed = macroSuccess ? macroSimilarity > threshold : false;

					var overallPassed = builderPassed && macroPassed;

					HtmlReportGenerator.addResultWithMacro(getDisplayName(), referencePath, builderPath, overallPassed, builderSimilarity, null, macroPath,
						macroSimilarity, macroPassed, threshold, threshold);
					HtmlReportGenerator.generateReport();

					Assert.isTrue(builderPassed, 'Builder should match reference (similarity: ${Math.round(builderSimilarity * 10000) / 100}%)');
					Assert.isTrue(macroPassed, 'Macro should match reference (similarity: ${Math.round(macroSimilarity * 10000) / 100}%)');
				} catch (e:Dynamic) {
					Assert.fail('Screenshot/compare threw: $e');
				}
				pendingVisualTests--;
				async.done();
			});
		});
	}

	/**
	 * Multi-instance macro vs builder test. Renders N variants with different parameters
	 * side-by-side, comparing builder and macro outputs against reference.
	 * @param num Test number
	 * @param name Test name
	 * @param scale Scale factor
	 * @param spacing Vertical spacing between variants
	 * @param builderParams Array of parameter maps for each builder variant
	 * @param createMacroRoots Function that creates macro roots for each variant index
	 * @param async utest async handle
	 */
	public function multiInstanceMacroTest(num:Int, name:String, scale:Float, spacing:Float,
			builderParams:Array<Map<String, Dynamic>>, createMacroRoots:(index:Int) -> h2d.Object,
			async:utest.Async, ?tolerance:Null<Float>):Void {
		setupTest(num, name);
		pendingVisualTests++;
		async.setTimeout(15000);

		var animFilePath = manimPath(num, name);
		var variantCount = builderParams.length;

		// Phase 1: builder — N variants with different params
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
			reportBuildFailure(msg);
			Assert.fail(msg);
			pendingVisualTests--;
			async.done();
			return;
		}

		if (testTitle != null && testTitle.length > 0) addTitleOverlay();

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderSuccess = false;
			try {
				builderSuccess = screenshot(builderPath, 1280, 720);
			} catch (e:Dynamic) {
				Assert.fail('Builder screenshot threw: $e');
				pendingVisualTests--;
				async.done();
				return;
			}

			// Phase 2: macro — same N variants
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
				try {
					var macroPath = 'test/screenshots/${testName}_macro.png';
					var referencePath = getReferenceImagePath();

					var macroSuccess = screenshot(macroPath, 1280, 720);

					var builderSim = builderSuccess ? computeSimilarity(builderPath, referencePath) : 0.0;
					var macroSim = macroSuccess ? computeSimilarity(macroPath, referencePath) : 0.0;
					var threshold = if (tolerance != null) tolerance else 0.99;
					var builderOk = builderSim > threshold;
					var macroOk = macroSim > threshold;

					HtmlReportGenerator.addResultWithMacro(getDisplayName(), referencePath, builderPath, builderOk && macroOk,
						builderSim, null, macroPath, macroSim, macroOk, threshold, threshold);
					HtmlReportGenerator.generateReport();

					Assert.isTrue(builderOk, 'Builder should match reference (${Math.round(builderSim * 10000) / 100}%)');
					Assert.isTrue(macroOk, 'Macro should match reference (${Math.round(macroSim * 10000) / 100}%)');
				} catch (e:Dynamic) {
					Assert.fail('Screenshot/compare threw: $e');
				}
				pendingVisualTests--;
				async.done();
			});
		});
	}

	/**
	 * Multi-instance macro vs builder test using .manim layout for positioning.
	 * Like multiInstanceMacroTest but reads layout points from the .manim file instead of using fixed spacing.
	 */
	public function layoutMacroTest(num:Int, name:String, layoutName:String, scale:Float,
			builderParams:Array<Map<String, Dynamic>>, createMacroRoots:(index:Int) -> h2d.Object,
			async:utest.Async, ?tolerance:Null<Float>):Void {
		setupTest(num, name);
		pendingVisualTests++;
		async.setTimeout(15000);

		var animFilePath = manimPath(num, name);
		var variantCount = builderParams.length;

		// Phase 1: builder — N variants positioned by layout
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
			reportBuildFailure(msg);
			Assert.fail(msg);
			pendingVisualTests--;
			async.done();
			return;
		}

		if (testTitle != null && testTitle.length > 0) addTitleOverlay();

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderSuccess = false;
			try {
				builderSuccess = screenshot(builderPath, 1280, 720);
			} catch (e:Dynamic) {
				Assert.fail('Builder screenshot threw: $e');
				pendingVisualTests--;
				async.done();
				return;
			}

			// Phase 2: macro — same N variants positioned by layout
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
				try {
					var macroPath = 'test/screenshots/${testName}_macro.png';
					var referencePath = getReferenceImagePath();

					var macroSuccess = screenshot(macroPath, 1280, 720);

					var builderSim = builderSuccess ? computeSimilarity(builderPath, referencePath) : 0.0;
					var macroSim = macroSuccess ? computeSimilarity(macroPath, referencePath) : 0.0;
					var threshold = if (tolerance != null) tolerance else 0.99;
					var builderOk = builderSim > threshold;
					var macroOk = macroSim > threshold;

					HtmlReportGenerator.addResultWithMacro(getDisplayName(), referencePath, builderPath, builderOk && macroOk,
						builderSim, null, macroPath, macroSim, macroOk, threshold, threshold);
					HtmlReportGenerator.generateReport();

					Assert.isTrue(builderOk, 'Builder should match reference (${Math.round(builderSim * 10000) / 100}%)');
					Assert.isTrue(macroOk, 'Macro should match reference (${Math.round(macroSim * 10000) / 100}%)');
				} catch (e:Dynamic) {
					Assert.fail('Screenshot/compare threw: $e');
				}
				pendingVisualTests--;
				async.done();
			});
		});
	}

	public function computeSimilarity(actual:String, reference:String):Float {
		if (!sys.FileSystem.exists(reference)) return 0.0;
		if (!sys.FileSystem.exists(actual)) return 0.0;

		try {
			var actualBytes = sys.io.File.getBytes(actual);
			var referenceBytes = sys.io.File.getBytes(reference);
			var p1 = hxd.res.Any.fromBytes(actual, actualBytes).toImage().getPixels();
			var p2 = hxd.res.Any.fromBytes(reference, referenceBytes).toImage().getPixels();

			if (p1.width != p2.width || p1.height != p2.height) return 0.0;

			var totalPixels = p1.width * p1.height;
			var matchingPixels = 0;
			for (x in 0...p1.width) {
				for (y in 0...p1.height) {
					if (colorDistance(p1.getPixel(x, y), p2.getPixel(x, y)) < 5)
						matchingPixels++;
				}
			}
			return matchingPixels / totalPixels;
		} catch (e:Dynamic) {
			return 0.0;
		}
	}
}
