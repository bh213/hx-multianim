package bh.test;

import h3d.mat.Texture;
import hxd.Pixels;
import hxd.File;
import utest.Assert;
import h2d.col.IBounds;
import hxd.res.Image;
import hxd.Res;
import h2d.Scene;
import bh.multianim.MultiAnimBuilder;

class VisualTestBase extends utest.Test {
	private var referenceDir:String;
	private var testName:String;
	private var testTitle:String; // Human-readable title like "#1: hex grid + pixels"
	private var s2d:Scene;
	private var updateWaiter:Null<Float -> Void>;
	public static var appInstance:hxd.App;

	// Verbose output - only trace info/debug messages when enabled
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
		
		// Ensure screenshot directory exists
		var screenshotDir = "test/screenshots";
		if (!sys.FileSystem.exists(screenshotDir)) {
			sys.FileSystem.createDirectory(screenshotDir);
		}
		
		// Subscribe to app updates if available
		if (appInstance != null && Std.isOfType(appInstance, TestApp)) {
			cast(appInstance, TestApp).subscribeToUpdate(onAppUpdate);
		}
	}

	/**
	 * Called when the app updates (each frame)
	 */
	private function onAppUpdate(dt:Float):Void {
		if (updateWaiter != null) {
			var callback = updateWaiter;
			updateWaiter = null;
			callback(dt);
		}
	}

	/**
	 * Wait for the next frame update
	 */
	public function waitForUpdate(callback:Float -> Void):Void {
		updateWaiter = callback;
	}

	/**
	 * Build a manim file and add it to the scene
	 * @param scale Optional scale factor (default 4.0 for higher resolution rendering)
	 */
	public function buildAndAddToScene(animFilePath:String, name:String, ?scale:Float):Dynamic {

		// Clear existing children from scene
		s2d.removeChildren();

		if (scale == null) scale = 4.0;

		try {
			// Load file as ByteData
			var fileContent = byte.ByteData.ofString(sys.io.File.getContent(animFilePath));

			// Create a resource loader using the factory method
			var loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);

			// Build with the file
			var builder = bh.multianim.MultiAnimBuilder.load(fileContent, loader, animFilePath);

			// If no element name specified, try to build the first element that looks reasonable

			// Build with empty parameters
			var built = builder.buildWithParameters(name, new Map());
			verbose('Built element "$name" from $animFilePath: $built');
			if (built == null) {
				throw 'Error: Failed to build element "$name" from $animFilePath';
			}
			s2d.addChild(built.object);
			built.object.setScale(scale);

			// Add title text overlay if testTitle is set
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
	 * Add a title text overlay to the scene
	 */
	private function addTitleOverlay():Void {
		var loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
		var font = loader.loadFont("dd");
		if (font != null) {
			var text = new h2d.Text(font, s2d);
			text.text = testTitle;
			text.textColor = 0xFFFFFF;
			text.setPosition(20, 20);
			text.alpha = 0.9;
		}
	}
	
	/**
	 * Clear the scene between tests
	 */
	public function clearScene() {
		if (s2d != null) {
			s2d.removeChildren();
		}
	}

	/**
	 * Take a screenshot of the rendered content
	 * Requires an active hxd.App instance
	 */
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
		e.clear(0x1f1f1fff, 1); // Light blue background - this ensures non-empty pixel data

		// Actually render the scene to the texture
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

	/**
	 * Compare two PNG images by calculating similarity
	 * Returns true if images are similar enough (> threshold match)
	 * @param actual Path to actual image
	 * @param reference Path to reference image
	 * @param threshold Optional similarity threshold (default 0.9999 = 99.99%)
	 */
	public function compareImages(actual:String, reference:String, ?threshold:Float):Bool {
		if (threshold == null) threshold = 0.9999;
		var similarity = 1.0;
		var passed = true;

		if (!sys.FileSystem.exists(reference)) {
			verbose('Info: Reference image not found: $reference (would generate on first run)');
			passed = true; // Pass if no reference exists (generate it)
			similarity = 1.0;
		} else if (!sys.FileSystem.exists(actual)) {
			trace('Error: Actual image not found: $actual');
			passed = false;
			similarity = 0.0;
		} else {
			try {
				// Load images directly from file system
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
							var actual_color = p1.getPixel(x, y);
							var reference_color = p2.getPixel(x, y);

							// Allow small color difference (due to compression, etc)
							if (colorDistance(actual_color, reference_color) < 5) {
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

		// Add to HTML report
		HtmlReportGenerator.addResult(testName, reference, actual, passed, similarity);

		// Continuously update the HTML report as results come in
		HtmlReportGenerator.generateReport();

		return passed;
	}

	/**
	 * Calculate color distance in RGB space
	 */
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

	/**
	 * Get the reference image path
	 */
	public function getReferenceImagePath():String {
		return '$referenceDir/reference.png';
	}

	/**
	 * Get the actual screenshot path
	 */
	public function getActualImagePath():String {
		return 'test/screenshots/${testName}_actual.png';
	}

	/**
	 * Build animation, wait for next frame, then take screenshot
	 * Returns immediately but screenshot will be taken after next update
	 * @param scale Optional scale factor (default 4.0)
	 */
	public function buildRenderAndScreenshot(animFilePath:String, elementName:String, outputFile:String,
			?sizeX:Int, ?sizeY:Int, ?scale:Float):Void {
		clearScene();
		var result = buildAndAddToScene(animFilePath, elementName, scale);

		// Queue screenshot for next update
		if (result != null) {
			waitForUpdate(function(dt:Float) {
				var success = screenshot(outputFile, sizeX, sizeY);
				if (!success) {
					trace("Warning: Screenshot may not have been created: " + outputFile);
				}
			});
		} else {
			trace("Error: Failed to build element before screenshot");
		}
	}

	/**
	 * Build, render, screenshot, and compare with reference - async version
	 * Uses utest async to properly wait for screenshot to complete
	 * @param scale Optional scale factor (default 4.0)
	 */
	public function buildRenderScreenshotAndCompare(animFilePath:String, elementName:String,
			async:utest.Async, ?sizeX:Int, ?sizeY:Int, ?scale:Float):Void {
		async.setTimeout(10000);
		clearScene();
		var result = buildAndAddToScene(animFilePath, elementName, scale);

		Assert.notNull(result, 'Failed to build element "$elementName" from $animFilePath');

		if (result != null) {
			// Queue screenshot for next update
			waitForUpdate(function(dt:Float) {
				var actualPath = getActualImagePath();
				var referencePath = getReferenceImagePath();

				var success = screenshot(actualPath, sizeX, sizeY);
				Assert.isTrue(success, 'Screenshot should be created at $actualPath');

				if (success) {
					// Compare with reference
					var match = compareImages(actualPath, referencePath);
					Assert.isTrue(match, 'Screenshot should match reference image');
				}

				// Signal async test completion
				async.done();
			});
		} else {
			async.done();
		}
	}

}
