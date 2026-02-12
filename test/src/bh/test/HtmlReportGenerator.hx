package bh.test;

import sys.io.File;
import sys.FileSystem;

using StringTools;

typedef TestResult = {
	var testName:String;
	var referencePath:String;
	var actualPath:String;
	var passed:Bool;
	var similarity:Float;
	var ?errorMessage:String;
	var ?manimPath:String;
	var ?manimContent:String;
	var ?macroPath:String;
	var ?macroSimilarity:Float;
	var ?macroPassed:Bool;
}

class HtmlReportGenerator {
	private static var results:Array<TestResult> = [];
	private static var reportPath:String = "test/screenshots/index.html";

	public static function addResult(testName:String, referencePath:String, actualPath:String, passed:Bool, similarity:Float, ?errorMessage:String):Void {
		addResultWithMacro(testName, referencePath, actualPath, passed, similarity, errorMessage, null, null, null);
	}

	public static function addResultWithMacro(testName:String, referencePath:String, actualPath:String, passed:Bool, similarity:Float,
			?errorMessage:String, ?macroPath:String, ?macroSimilarity:Float, ?macroPassed:Bool):Void {
		// Find manim file in the same directory as reference
		var manimPath:String = null;
		var manimContent:String = null;

		if (referencePath != null && referencePath.endsWith("/reference.png")) {
			var dir = referencePath.substring(0, referencePath.length - "/reference.png".length);
			// Find .manim file in directory
			if (FileSystem.exists(dir) && FileSystem.isDirectory(dir)) {
				for (file in FileSystem.readDirectory(dir)) {
					if (file.endsWith(".manim")) {
						manimPath = dir + "/" + file;
						// Read manim content
						try {
							manimContent = File.getContent(manimPath);
						} catch (e:Dynamic) {
							manimContent = null;
						}
						break;
					}
				}
			}
		}

		results.push({
			testName: testName,
			referencePath: referencePath,
			actualPath: actualPath,
			passed: passed,
			similarity: similarity,
			errorMessage: errorMessage,
			manimPath: manimPath,
			manimContent: manimContent,
			macroPath: macroPath,
			macroSimilarity: macroSimilarity,
			macroPassed: macroPassed,
		});
	}

	public static function generateReport():Void {
		// Ensure target directory exists before writing
		var reportDir = haxe.io.Path.directory(reportPath);
		if (reportDir != null && reportDir != "" && !FileSystem.exists(reportDir)) {
			FileSystem.createDirectory(reportDir);
		}

		var timestamp = Date.now().toString();
		var html = new StringBuf();

		html.add('<!DOCTYPE html>\n');
		html.add('<html lang="en">\n');
		html.add('<head>\n');
		html.add('    <meta charset="UTF-8">\n');
		html.add('    <meta name="viewport" content="width=device-width, initial-scale=1.0">\n');
		html.add('    <title>Visual Test Report</title>\n');
		html.add('    <style>\n');
		html.add('        body {\n');
		html.add('            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;\n');
		html.add('            max-width: 1400px;\n');
		html.add('            margin: 0 auto;\n');
		html.add('            padding: 20px;\n');
		html.add('            background: #f5f5f5;\n');
		html.add('        }\n');
		html.add('        h1 {\n');
		html.add('            color: #333;\n');
		html.add('            border-bottom: 2px solid #4CAF50;\n');
		html.add('            padding-bottom: 10px;\n');
		html.add('        }\n');
		html.add('        .timestamp {\n');
		html.add('            color: #666;\n');
		html.add('            font-size: 14px;\n');
		html.add('            margin-bottom: 20px;\n');
		html.add('        }\n');
		html.add('        .summary {\n');
		html.add('            background: white;\n');
		html.add('            padding: 15px;\n');
		html.add('            border-radius: 5px;\n');
		html.add('            margin-bottom: 20px;\n');
		html.add('            box-shadow: 0 2px 4px rgba(0,0,0,0.1);\n');
		html.add('        }\n');
		html.add('        .failed-links {\n');
		html.add('            background: #ffebee;\n');
		html.add('            padding: 15px;\n');
		html.add('            border-radius: 5px;\n');
		html.add('            margin-bottom: 20px;\n');
		html.add('            border-left: 4px solid #f44336;\n');
		html.add('        }\n');
		html.add('        .failed-links h3 {\n');
		html.add('            margin: 0 0 10px 0;\n');
		html.add('            color: #c62828;\n');
		html.add('        }\n');
		html.add('        .failed-links a {\n');
		html.add('            color: #c62828;\n');
		html.add('            text-decoration: none;\n');
		html.add('            margin-right: 15px;\n');
		html.add('            display: inline-block;\n');
		html.add('            margin-bottom: 5px;\n');
		html.add('        }\n');
		html.add('        .failed-links a:hover {\n');
		html.add('            text-decoration: underline;\n');
		html.add('        }\n');
		html.add('        .error-message {\n');
		html.add('            color: #c62828;\n');
		html.add('            font-size: 12px;\n');
		html.add('            margin-left: 10px;\n');
		html.add('        }\n');
		html.add('        .test-result {\n');
		html.add('            background: white;\n');
		html.add('            margin-bottom: 20px;\n');
		html.add('            padding: 15px;\n');
		html.add('            border-radius: 5px;\n');
		html.add('            box-shadow: 0 2px 4px rgba(0,0,0,0.1);\n');
		html.add('        }\n');
		html.add('        .test-result.passed {\n');
		html.add('            border-left: 4px solid #4CAF50;\n');
		html.add('        }\n');
		html.add('        .test-result.failed {\n');
		html.add('            border-left: 4px solid #f44336;\n');
		html.add('        }\n');
		html.add('        .test-header {\n');
		html.add('            display: flex;\n');
		html.add('            justify-content: space-between;\n');
		html.add('            align-items: center;\n');
		html.add('            margin-bottom: 15px;\n');
		html.add('        }\n');
		html.add('        .test-name {\n');
		html.add('            font-size: 18px;\n');
		html.add('            font-weight: bold;\n');
		html.add('            color: #333;\n');
		html.add('        }\n');
		html.add('        .test-status {\n');
		html.add('            padding: 5px 10px;\n');
		html.add('            border-radius: 3px;\n');
		html.add('            font-size: 14px;\n');
		html.add('            font-weight: bold;\n');
		html.add('            display: inline-block;\n');
		html.add('            margin-left: 5px;\n');
		html.add('        }\n');
		html.add('        .test-status.passed {\n');
		html.add('            background: #4CAF50;\n');
		html.add('            color: white;\n');
		html.add('        }\n');
		html.add('        .test-status.failed {\n');
		html.add('            background: #f44336;\n');
		html.add('            color: white;\n');
		html.add('        }\n');
		html.add('        .similarity {\n');
		html.add('            color: #666;\n');
		html.add('            font-size: 14px;\n');
		html.add('            margin-bottom: 10px;\n');
		html.add('        }\n');
		html.add('        .test-error {\n');
		html.add('            background: #ffebee;\n');
		html.add('            padding: 10px;\n');
		html.add('            border-radius: 3px;\n');
		html.add('            margin-bottom: 10px;\n');
		html.add('            color: #c62828;\n');
		html.add('            font-family: monospace;\n');
		html.add('            font-size: 12px;\n');
		html.add('            white-space: pre-wrap;\n');
		html.add('        }\n');
		html.add('        .image-comparison {\n');
		html.add('            display: grid;\n');
		html.add('            gap: 20px;\n');
		html.add('        }\n');
		html.add('        .image-comparison.cols-2 {\n');
		html.add('            grid-template-columns: 1fr 1fr;\n');
		html.add('        }\n');
		html.add('        .image-comparison.cols-3 {\n');
		html.add('            grid-template-columns: 1fr 1fr 1fr;\n');
		html.add('        }\n');
		html.add('        .image-container {\n');
		html.add('            text-align: center;\n');
		html.add('        }\n');
		html.add('        .image-label {\n');
		html.add('            font-weight: bold;\n');
		html.add('            margin-bottom: 10px;\n');
		html.add('            color: #333;\n');
		html.add('        }\n');
		html.add('        .image-container img {\n');
		html.add('            max-width: 100%;\n');
		html.add('            border: 1px solid #ddd;\n');
		html.add('            border-radius: 3px;\n');
		html.add('            background: #f9f9f9;\n');
		html.add('            cursor: pointer;\n');
		html.add('            transition: opacity 0.2s;\n');
		html.add('        }\n');
		html.add('        .image-container img:hover {\n');
		html.add('            opacity: 0.8;\n');
		html.add('        }\n');
		html.add('        .no-image {\n');
		html.add('            padding: 40px;\n');
		html.add('            background: #f9f9f9;\n');
		html.add('            border: 1px dashed #ccc;\n');
		html.add('            border-radius: 3px;\n');
		html.add('            color: #999;\n');
		html.add('        }\n');
		html.add('        /* Image overlay/lightbox styles */\n');
		html.add('        .image-overlay {\n');
		html.add('            display: none;\n');
		html.add('            position: fixed;\n');
		html.add('            top: 0;\n');
		html.add('            left: 0;\n');
		html.add('            width: 100%;\n');
		html.add('            height: 100%;\n');
		html.add('            background: #000;\n');
		html.add('            z-index: 1000;\n');
		html.add('            cursor: pointer;\n');
		html.add('            justify-content: center;\n');
		html.add('            align-items: center;\n');
		html.add('        }\n');
		html.add('        .image-overlay.active {\n');
		html.add('            display: flex;\n');
		html.add('        }\n');
		html.add('        .image-overlay img {\n');
		html.add('            max-width: 100vw;\n');
		html.add('            max-height: 100vh;\n');
		html.add('            object-fit: contain;\n');
		html.add('            border: none;\n');
		html.add('            background: white;\n');
		html.add('        }\n');
		html.add('        .overlay-close-hint {\n');
		html.add('            position: fixed;\n');
		html.add('            top: 20px;\n');
		html.add('            right: 20px;\n');
		html.add('            color: white;\n');
		html.add('            font-size: 14px;\n');
		html.add('            opacity: 0.7;\n');
		html.add('        }\n');
		html.add('        /* Manim link styles */\n');
		html.add('        .manim-link {\n');
		html.add('            color: #1976D2;\n');
		html.add('            text-decoration: none;\n');
		html.add('            margin-left: 15px;\n');
		html.add('            font-size: 14px;\n');
		html.add('            cursor: pointer;\n');
		html.add('        }\n');
		html.add('        .manim-link:hover {\n');
		html.add('            text-decoration: underline;\n');
		html.add('        }\n');
		html.add('        /* Manim overlay styles */\n');
		html.add('        .manim-overlay {\n');
		html.add('            display: none;\n');
		html.add('            position: fixed;\n');
		html.add('            top: 0;\n');
		html.add('            left: 0;\n');
		html.add('            width: 100%;\n');
		html.add('            height: 100%;\n');
		html.add('            background: #1e1e1e;\n');
		html.add('            z-index: 1000;\n');
		html.add('            overflow: auto;\n');
		html.add('        }\n');
		html.add('        .manim-overlay.active {\n');
		html.add('            display: block;\n');
		html.add('        }\n');
		html.add('        .manim-overlay-header {\n');
		html.add('            position: fixed;\n');
		html.add('            top: 0;\n');
		html.add('            left: 0;\n');
		html.add('            right: 0;\n');
		html.add('            background: #333;\n');
		html.add('            padding: 10px 20px;\n');
		html.add('            display: flex;\n');
		html.add('            justify-content: space-between;\n');
		html.add('            align-items: center;\n');
		html.add('            z-index: 1001;\n');
		html.add('        }\n');
		html.add('        .manim-overlay-title {\n');
		html.add('            color: #fff;\n');
		html.add('            font-size: 16px;\n');
		html.add('            font-family: monospace;\n');
		html.add('        }\n');
		html.add('        .manim-overlay-close {\n');
		html.add('            color: #fff;\n');
		html.add('            background: #555;\n');
		html.add('            border: none;\n');
		html.add('            padding: 5px 15px;\n');
		html.add('            border-radius: 3px;\n');
		html.add('            cursor: pointer;\n');
		html.add('            font-size: 14px;\n');
		html.add('        }\n');
		html.add('        .manim-overlay-close:hover {\n');
		html.add('            background: #666;\n');
		html.add('        }\n');
		html.add('        .manim-content {\n');
		html.add('            margin-top: 50px;\n');
		html.add('            padding: 20px;\n');
		html.add('            color: #d4d4d4;\n');
		html.add('            font-family: Consolas, Monaco, monospace;\n');
		html.add('            font-size: 14px;\n');
		html.add('            line-height: 1.5;\n');
		html.add('            white-space: pre;\n');
		html.add('            tab-size: 4;\n');
		html.add('        }\n');
		html.add('    </style>\n');
		html.add('</head>\n');
		html.add('<body>\n');
		html.add('    <h1>Visual Test Report</h1>\n');
		html.add('    <div class="timestamp">Generated: ${timestamp}</div>\n');

		// Summary section
		var passed = results.filter(r -> r.passed).length;
		var failed = results.length - passed;
		html.add('    <div class="summary">\n');
		html.add('        <strong>Summary:</strong> ${results.length} tests, ');
		html.add('        <span style="color: #4CAF50;">${passed} passed</span>, ');
		html.add('        <span style="color: #f44336;">${failed} failed</span>\n');
		html.add('    </div>\n');

		// Failed tests links section
		var failedResults = results.filter(r -> !r.passed);
		if (failedResults.length > 0) {
			html.add('    <div class="failed-links">\n');
			html.add('        <h3>Failed Tests</h3>\n');
			for (result in failedResults) {
				html.add('        <div>\n');
				html.add('            <a href="#test-${result.testName}">${result.testName}</a>\n');
				if (result.errorMessage != null && result.errorMessage.length > 0) {
					var escapedError = result.errorMessage.htmlEscape();
					html.add('            <span class="error-message">${escapedError}</span>\n');
				}
				html.add('        </div>\n');
			}
			html.add('    </div>\n');
		}

		// Individual test results
		for (result in results) {
			var statusClass = result.passed ? "passed" : "failed";
			var statusText = result.passed ? "PASSED" : "FAILED";
			var similarityPercent = Math.round(result.similarity * 10000) / 100;
			var hasMacro = result.macroPath != null;

			html.add('    <div class="test-result ${statusClass}" id="test-${result.testName}">\n');
			html.add('        <div class="test-header">\n');
			html.add('            <div class="test-name">${result.testName}</div>\n');
			html.add('            <div>\n');
			html.add('                <span class="test-status ${statusClass}">Builder: ${statusText}</span>\n');
			if (hasMacro) {
				var macroStatusClass = result.macroPassed == true ? "passed" : "failed";
				var macroStatusText = result.macroPassed == true ? "PASSED" : "FAILED";
				html.add('                <span class="test-status ${macroStatusClass}">Macro: ${macroStatusText}</span>\n');
			}
			// Add manim link if we have manim content
			if (result.manimPath != null && result.manimContent != null) {
				var manimFileName = haxe.io.Path.withoutDirectory(result.manimPath);
				html.add('                <a class="manim-link" onclick="showManim(\'${result.testName}\')">${manimFileName}</a>\n');
			}
			html.add('            </div>\n');
			html.add('        </div>\n');
			html.add('        <div class="similarity">Builder similarity: ${similarityPercent}%');
			if (hasMacro && result.macroSimilarity != null) {
				var macroSimPercent = Math.round(result.macroSimilarity * 10000) / 100;
				html.add(' | Macro similarity: ${macroSimPercent}%');
			}
			html.add('</div>\n');

			// Show error message if present
			if (result.errorMessage != null && result.errorMessage.length > 0) {
				var escapedError = result.errorMessage.htmlEscape();
				html.add('        <div class="test-error">${escapedError}</div>\n');
			}

			var colsClass = hasMacro ? "cols-3" : "cols-2";
			html.add('        <div class="image-comparison ${colsClass}">\n');

			// Reference image
			html.add('            <div class="image-container">\n');
			html.add('                <div class="image-label">Reference</div>\n');
			if (FileSystem.exists(result.referencePath)) {
				var relPath = makeRelativePath(result.referencePath);
				html.add('                <img src="${relPath}" alt="Reference" onclick="showOverlay(this.src)">\n');
			} else {
				html.add('                <div class="no-image">No reference image</div>\n');
			}
			html.add('            </div>\n');

			// Builder (actual) image
			html.add('            <div class="image-container">\n');
			html.add('                <div class="image-label">${hasMacro ? "Builder" : "Actual"}</div>\n');
			if (FileSystem.exists(result.actualPath)) {
				var relPath = makeRelativePath(result.actualPath);
				html.add('                <img src="${relPath}" alt="Builder" onclick="showOverlay(this.src)">\n');
			} else {
				html.add('                <div class="no-image">No builder image</div>\n');
			}
			html.add('            </div>\n');

			// Macro image (only if present)
			if (hasMacro) {
				html.add('            <div class="image-container">\n');
				html.add('                <div class="image-label">Macro</div>\n');
				if (FileSystem.exists(result.macroPath)) {
					var relPath = makeRelativePath(result.macroPath);
					html.add('                <img src="${relPath}" alt="Macro" onclick="showOverlay(this.src)">\n');
				} else {
					html.add('                <div class="no-image">No macro image</div>\n');
				}
				html.add('            </div>\n');
			}

			html.add('        </div>\n');
			html.add('    </div>\n');
		}

		// Image overlay element
		html.add('    <div class="image-overlay" id="imageOverlay" onclick="hideOverlay()">\n');
		html.add('        <span class="overlay-close-hint">Click or press Esc to close</span>\n');
		html.add('        <img id="overlayImage" src="" alt="Full size">\n');
		html.add('    </div>\n');

		// Manim overlay element
		html.add('    <div class="manim-overlay" id="manimOverlay">\n');
		html.add('        <div class="manim-overlay-header">\n');
		html.add('            <span class="manim-overlay-title" id="manimTitle"></span>\n');
		html.add('            <button class="manim-overlay-close" onclick="hideManim()">Close (Esc)</button>\n');
		html.add('        </div>\n');
		html.add('        <pre class="manim-content" id="manimContent"></pre>\n');
		html.add('    </div>\n');

		// Hidden script data for manim contents
		html.add('    <script id="manimData" type="application/json">\n');
		var manimMap = new StringBuf();
		manimMap.add('{');
		var first = true;
		for (result in results) {
			if (result.manimPath != null && result.manimContent != null) {
				if (!first) manimMap.add(',');
				first = false;
				var manimFileName = haxe.io.Path.withoutDirectory(result.manimPath);
				// Escape the content for JSON
				var escapedContent = result.manimContent.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '\\r').replace('\t', '\\t');
				manimMap.add('"${result.testName}":{"file":"${manimFileName}","content":"${escapedContent}"}');
			}
		}
		manimMap.add('}');
		html.add('${manimMap.toString()}\n');
		html.add('    </script>\n');

		// JavaScript for image overlay and manim overlay
		html.add('    <script>\n');
		html.add('        var manimData = JSON.parse(document.getElementById("manimData").textContent);\n');
		html.add('        function showOverlay(src) {\n');
		html.add('            document.getElementById("overlayImage").src = src;\n');
		html.add('            document.getElementById("imageOverlay").classList.add("active");\n');
		html.add('        }\n');
		html.add('        function hideOverlay() {\n');
		html.add('            document.getElementById("imageOverlay").classList.remove("active");\n');
		html.add('        }\n');
		html.add('        function showManim(testName) {\n');
		html.add('            var data = manimData[testName];\n');
		html.add('            if (data) {\n');
		html.add('                document.getElementById("manimTitle").textContent = data.file;\n');
		html.add('                document.getElementById("manimContent").textContent = data.content;\n');
		html.add('                document.getElementById("manimOverlay").classList.add("active");\n');
		html.add('            }\n');
		html.add('        }\n');
		html.add('        function hideManim() {\n');
		html.add('            document.getElementById("manimOverlay").classList.remove("active");\n');
		html.add('        }\n');
		html.add('        document.addEventListener("keydown", function(e) {\n');
		html.add('            if (e.key === "Escape") {\n');
		html.add('                hideOverlay();\n');
		html.add('                hideManim();\n');
		html.add('            }\n');
		html.add('        });\n');
		html.add('    </script>\n');

		html.add('</body>\n');
		html.add('</html>\n');

		File.saveContent(reportPath, html.toString());

		// Write summary to a separate file for test.bat to read
		File.saveContent("build/test_result.txt", getSummary());
	}

	private static function makeRelativePath(path:String):String {
		// Convert test/screenshots/foo.png to ./foo.png
		// Convert test/examples/bar/reference.png to ../examples/bar/reference.png
		if (path.startsWith("test/screenshots/")) {
			return "./" + path.substring("test/screenshots/".length);
		} else if (path.startsWith("test/examples/")) {
			return "../examples/" + path.substring("test/examples/".length);
		}
		return path;
	}

	public static function getSummary():String {
		var passed = results.filter(r -> r.passed).length;
		var failed = results.length - passed;
		if (failed > 0) {
			var failedNames = results.filter(r -> !r.passed).map(r -> r.testName);
			return 'FAILED: ${failed}/${results.length} tests failed [${failedNames.join(", ")}]';
		}
		return 'OK: ${passed}/${results.length} visual tests passed';
	}

	public static function clear():Void {
		results = [];
	}
}
