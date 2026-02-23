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
	var ?threshold:Float;
	var ?macroThreshold:Float;
}

class HtmlReportGenerator {
	private static var results:Array<TestResult> = [];
	private static var reportPath:String = "test/screenshots/index.html";
	private static var unitAggregator:Null<utest.ui.common.ResultAggregator> = null;
	private static var includeUnitTests:Bool = false;

	public static function setUnitTestAggregator(aggregator:utest.ui.common.ResultAggregator):Void {
		unitAggregator = aggregator;
	}

	public static function enableUnitTestReport():Void {
		includeUnitTests = true;
	}

	public static function addResult(testName:String, referencePath:String, actualPath:String, passed:Bool, similarity:Float, ?errorMessage:String,
			?threshold:Float):Void {
		addResultWithMacro(testName, referencePath, actualPath, passed, similarity, errorMessage, null, null, null, threshold, null);
	}

	public static function addResultWithMacro(testName:String, referencePath:String, actualPath:String, passed:Bool, similarity:Float,
			?errorMessage:String, ?macroPath:String, ?macroSimilarity:Float, ?macroPassed:Bool, ?threshold:Float, ?macroThreshold:Float):Void {
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

		// Generate diff images for pairs that differ
		var diffBase = actualPath != null ? actualPath.replace("_actual.png", "") : null;
		if (diffBase != null) {
			if (similarity < 1.0 && actualPath != null && referencePath != null && FileSystem.exists(actualPath) && FileSystem.exists(referencePath))
				generateDiffImage(actualPath, referencePath, diffBase + "_diff_bref.png");
			if (macroPath != null && macroSimilarity != null && macroSimilarity < 1.0 && FileSystem.exists(macroPath) && FileSystem.exists(referencePath))
				generateDiffImage(macroPath, referencePath, diffBase + "_diff_mref.png");
			if (macroPath != null && actualPath != null && FileSystem.exists(actualPath) && FileSystem.exists(macroPath)
				&& !(similarity == 1.0 && macroSimilarity != null && macroSimilarity == 1.0))
				generateDiffImage(actualPath, macroPath, diffBase + "_diff_bm.png");
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
			threshold: threshold,
			macroThreshold: macroThreshold,
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
		html.add('        .unit-tests-section {\n');
		html.add('            margin-top: 40px;\n');
		html.add('            border-top: 2px solid #999;\n');
		html.add('            padding-top: 20px;\n');
		html.add('        }\n');
		html.add('        .unit-tests-summary {\n');
		html.add('            background: white;\n');
		html.add('            padding: 15px;\n');
		html.add('            border-radius: 5px;\n');
		html.add('            box-shadow: 0 2px 4px rgba(0,0,0,0.1);\n');
		html.add('            margin-bottom: 15px;\n');
		html.add('        }\n');
		html.add('        .unit-tests-summary.all-passed {\n');
		html.add('            border-left: 4px solid #4CAF50;\n');
		html.add('        }\n');
		html.add('        .unit-tests-summary.has-failures {\n');
		html.add('            border-left: 4px solid #f44336;\n');
		html.add('        }\n');
		html.add('        .expand-btn {\n');
		html.add('            background: #e0e0e0;\n');
		html.add('            border: none;\n');
		html.add('            padding: 6px 14px;\n');
		html.add('            border-radius: 3px;\n');
		html.add('            cursor: pointer;\n');
		html.add('            font-size: 13px;\n');
		html.add('            margin-left: 15px;\n');
		html.add('        }\n');
		html.add('        .expand-btn:hover { background: #ccc; }\n');
		html.add('        .unit-details { display: none; }\n');
		html.add('        .unit-details.visible { display: block; }\n');
		html.add('        .unit-class {\n');
		html.add('            background: white;\n');
		html.add('            margin-bottom: 10px;\n');
		html.add('            padding: 12px 15px;\n');
		html.add('            border-radius: 5px;\n');
		html.add('            box-shadow: 0 1px 3px rgba(0,0,0,0.08);\n');
		html.add('        }\n');
		html.add('        .unit-class-name {\n');
		html.add('            font-weight: bold;\n');
		html.add('            font-size: 15px;\n');
		html.add('            color: #333;\n');
		html.add('            margin-bottom: 8px;\n');
		html.add('        }\n');
		html.add('        .unit-method {\n');
		html.add('            font-family: Consolas, Monaco, monospace;\n');
		html.add('            font-size: 13px;\n');
		html.add('            padding: 2px 0;\n');
		html.add('        }\n');
		html.add('        .unit-method.pass { color: #388E3C; }\n');
		html.add('        .unit-method.fail { color: #c62828; font-weight: bold; }\n');
		html.add('        .unit-method .dots { color: #999; margin-left: 4px; }\n');
		html.add('        .unit-fail-detail {\n');
		html.add('            background: #ffebee;\n');
		html.add('            padding: 6px 10px;\n');
		html.add('            margin: 2px 0 4px 20px;\n');
		html.add('            border-radius: 3px;\n');
		html.add('            font-size: 12px;\n');
		html.add('            color: #c62828;\n');
		html.add('            font-family: monospace;\n');
		html.add('            white-space: pre-wrap;\n');
		html.add('        }\n');
		html.add('        .diff-links { margin-top:10px; display:flex; gap:10px; }\n');
		html.add('        .diff-link { color:#c62828; cursor:pointer; font-size:13px; font-weight:bold; padding:3px 8px; border:1px solid #c62828; border-radius:3px; user-select:none; }\n');
		html.add('        .diff-link:hover { background:#ffebee; }\n');
		html.add('        .diff-link-error { color:#fff; background:#c62828; cursor:pointer; font-size:13px; font-weight:bold; padding:3px 8px; border:1px solid #c62828; border-radius:3px; user-select:none; }\n');
		html.add('        .diff-link-error:hover { background:#b71c1c; }\n');
		html.add('        .diff-overlay { display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:#222; z-index:1000; flex-direction:column; }\n');
		html.add('        .diff-overlay.active { display:flex; }\n');
		html.add('        .diff-header { background:#333; padding:10px 20px; display:flex; justify-content:space-between; align-items:center; flex-shrink:0; }\n');
		html.add('        .diff-title { color:#fff; font-size:16px; font-weight:bold; }\n');
		html.add('        .diff-tabs { display:flex; gap:5px; }\n');
		html.add('        .diff-tabs button { background:#555; color:#fff; border:none; padding:6px 14px; border-radius:3px; cursor:pointer; font-size:13px; }\n');
		html.add('        .diff-tabs button:hover { background:#666; }\n');
		html.add('        .diff-tabs button.active { background:#1976D2; }\n');
		html.add('        .diff-close { color:#fff; background:#555; border:none; padding:6px 14px; border-radius:3px; cursor:pointer; font-size:13px; }\n');
		html.add('        .diff-close:hover { background:#666; }\n');
		html.add('        .diff-body { flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center; overflow:auto; padding:20px; }\n');
		html.add('        .diff-label { color:#fff; font-size:16px; margin-top:10px; font-weight:bold; }\n');
		html.add('        .diff-controls { margin-top:10px; color:#ccc; font-size:14px; text-align:center; display:flex; align-items:center; gap:10px; }\n');
		html.add('        .diff-controls input[type="range"] { width:300px; }\n');
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

		// Unit test results section (before visual tests, details hidden by default)
		generateUnitTestSection(html);

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

		// Builder vs Macro mismatch errors section
		var macroMismatches = results.filter(function(r) {
			if (r.macroPath == null) return false;
			if (!FileSystem.exists(r.actualPath) || !FileSystem.exists(r.macroPath)) return false;
			return !(r.similarity == 1.0 && r.macroSimilarity != null && r.macroSimilarity == 1.0);
		});
		if (macroMismatches.length > 0) {
			html.add('    <div class="failed-links" style="border-left-color:#b71c1c;background:#ffcdd2;">\n');
			html.add('        <h3 style="color:#b71c1c;">Builder vs Macro Mismatches (${macroMismatches.length})</h3>\n');
			for (result in macroMismatches) {
				html.add('        <div>\n');
				html.add('            <a href="#test-${result.testName}">${result.testName}</a>\n');
				html.add('        </div>\n');
			}
			html.add('    </div>\n');
		}

		// Sort results by test number for consistent ordering
		results.sort(function(a, b) {
			var numA = extractTestNumber(a.testName);
			var numB = extractTestNumber(b.testName);
			return numA - numB;
		});

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
			// Manim link first (leftmost of right-aligned items)
			if (result.manimPath != null && result.manimContent != null) {
				var manimFileName = haxe.io.Path.withoutDirectory(result.manimPath);
				html.add('                <a class="manim-link" onclick="showManim(\'${result.testName}\')">${manimFileName}</a>\n');
			}
			html.add('                <span class="test-status ${statusClass}">Builder: ${statusText}</span>\n');
			if (hasMacro) {
				var macroStatusClass = result.macroPassed == true ? "passed" : "failed";
				var macroStatusText = result.macroPassed == true ? "PASSED" : "FAILED";
				html.add('                <span class="test-status ${macroStatusClass}">Macro: ${macroStatusText}</span>\n');
			}
			html.add('            </div>\n');
			html.add('        </div>\n');
			var thresholdPercent = result.threshold != null ? Math.round(result.threshold * 10000) / 100 : 99.99;
			var builderPassed = similarityPercent >= thresholdPercent;
			var thresholdStyle = builderPassed ? 'color: #999;' : 'color: #c62828; font-weight: bold;';
			html.add('        <div class="similarity">Builder similarity: ${similarityPercent}% <span style="${thresholdStyle}">(acceptance: ${thresholdPercent}%)</span>');
			if (hasMacro && result.macroSimilarity != null) {
				var macroSimPercent = Math.round(result.macroSimilarity * 10000) / 100;
				var macroThresholdPercent = result.macroThreshold != null ? Math.round(result.macroThreshold * 10000) / 100 : 99.0;
				var macroPassed = macroSimPercent >= macroThresholdPercent;
				var macroThresholdStyle = macroPassed ? 'color: #999;' : 'color: #c62828; font-weight: bold;';
				html.add(' | Macro similarity: ${macroSimPercent}% <span style="${macroThresholdStyle}">(acceptance: ${macroThresholdPercent}%)</span>');
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

			// Diff links for pairs that differ
			var diffBase = result.actualPath.replace("_actual.png", "");
			var diffLinks = new Array<String>();
			if (result.similarity < 1.0 && FileSystem.exists(result.referencePath) && FileSystem.exists(result.actualPath)) {
				var actRel = makeRelativePath(result.actualPath);
				var refRel = makeRelativePath(result.referencePath);
				var dp = diffBase + "_diff_bref.png";
				var dpRel = FileSystem.exists(dp) ? makeRelativePath(dp) : "";
				diffLinks.push('<a class="diff-link" onclick="showDiff(\'${actRel}\',\'${refRel}\',\'Builder\',\'Reference\',\'${dpRel}\')">Diff: Builder vs Ref</a>');
			}
			if (hasMacro && result.macroSimilarity != null && result.macroSimilarity < 1.0 && FileSystem.exists(result.macroPath) && FileSystem.exists(result.referencePath)) {
				var macRel = makeRelativePath(result.macroPath);
				var refRel = makeRelativePath(result.referencePath);
				var dp = diffBase + "_diff_mref.png";
				var dpRel = FileSystem.exists(dp) ? makeRelativePath(dp) : "";
				diffLinks.push('<a class="diff-link" onclick="showDiff(\'${macRel}\',\'${refRel}\',\'Macro\',\'Reference\',\'${dpRel}\')">Diff: Macro vs Ref</a>');
			}
			if (hasMacro && FileSystem.exists(result.actualPath) && FileSystem.exists(result.macroPath)
				&& !(result.similarity == 1.0 && result.macroSimilarity != null && result.macroSimilarity == 1.0)) {
				var actRel = makeRelativePath(result.actualPath);
				var macRel = makeRelativePath(result.macroPath);
				var dp = diffBase + "_diff_bm.png";
				var dpRel = FileSystem.exists(dp) ? makeRelativePath(dp) : "";
				diffLinks.push('<a class="diff-link-error" onclick="showDiff(\'${actRel}\',\'${macRel}\',\'Builder\',\'Macro\',\'${dpRel}\')">ERROR: Builder vs Macro differ</a>');
			}
			if (diffLinks.length > 0) {
				html.add('        <div class="diff-links">\n');
				for (link in diffLinks) {
					html.add('            ${link}\n');
				}
				html.add('        </div>\n');
			}

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

		// Diff overlay element
		html.add('    <div class="diff-overlay" id="diffOverlay">\n');
		html.add('        <div class="diff-header">\n');
		html.add('            <span class="diff-title" id="diffTitle"></span>\n');
		html.add('            <div class="diff-tabs">\n');
		html.add('                <button id="tabSlider" class="active" onclick="setDiffMode(\'slider\')">Slider</button>\n');
		html.add('                <button id="tabDiff" onclick="setDiffMode(\'diff\')">Difference</button>\n');
		html.add('            </div>\n');
		html.add('            <button class="diff-close" onclick="hideDiff()">Close (Esc)</button>\n');
		html.add('        </div>\n');
		html.add('        <div class="diff-body">\n');
		html.add('            <canvas id="diffCanvas" style="display:block;background:#fff"></canvas>\n');
		html.add('            <img id="diffImg" style="display:none;max-width:90vw;max-height:75vh;background:#000">\n');
		html.add('            <div class="diff-label" id="diffLabel"></div>\n');
		html.add('            <div class="diff-controls" id="diffControls"></div>\n');
		html.add('        </div>\n');
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

		// Unit test details toggle (separate script so JSON parse errors can't block it)
		html.add('    <script>\n');
		html.add('        function toggleUnitDetails() {\n');
		html.add('            var el = document.getElementById("unitDetails");\n');
		html.add('            var btn = document.getElementById("unitToggleBtn");\n');
		html.add('            if (el.classList.contains("visible")) {\n');
		html.add('                el.classList.remove("visible");\n');
		html.add('                btn.textContent = "Show Details";\n');
		html.add('            } else {\n');
		html.add('                el.classList.add("visible");\n');
		html.add('                btn.textContent = "Hide Details";\n');
		html.add('            }\n');
		html.add('        }\n');
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
		// Diff viewer — canvas slider + pre-generated diff image
		html.add('        var ds={l1:"",l2:"",mode:"slider",img1:null,img2:null,split:50,diffSrc:""};\n');
		html.add('        function showDiff(a,b,la,lb,dp){\n');
		html.add('            ds.l1=la;ds.l2=lb;ds.split=50;ds.diffSrc=dp||"";\n');
		html.add('            document.getElementById("diffTitle").textContent=la+" vs "+lb;\n');
		html.add('            ds.img1=new Image();ds.img2=new Image();\n');
		html.add('            var n=0;\n');
		html.add('            function ck(){n++;if(n===2){document.getElementById("diffOverlay").classList.add("active");setDiffMode("slider");}}\n');
		html.add('            ds.img1.onload=ck;ds.img2.onload=ck;\n');
		html.add('            ds.img1.src=a;ds.img2.src=b;\n');
		html.add('        }\n');
		html.add('        function hideDiff(){document.getElementById("diffOverlay").classList.remove("active");}\n');
		html.add('        function setDiffMode(m){\n');
		html.add('            ds.mode=m;\n');
		html.add('            document.getElementById("tabSlider").className=m==="slider"?"active":"";\n');
		html.add('            document.getElementById("tabDiff").className=m==="diff"?"active":"";\n');
		html.add('            var cv=document.getElementById("diffCanvas");\n');
		html.add('            var im=document.getElementById("diffImg");\n');
		html.add('            var lb=document.getElementById("diffLabel");\n');
		html.add('            var co=document.getElementById("diffControls");\n');
		html.add('            if(m==="slider"){\n');
		html.add('                cv.style.display="block";im.style.display="none";\n');
		html.add('                ds.split=50;lb.textContent="";\n');
		html.add('                co.innerHTML=ds.l1+" <input type=\\\"range\\\" min=\\\"0\\\" max=\\\"100\\\" value=\\\"50\\\" oninput=\\\"wipeSlider(this.value)\\\"> "+ds.l2;\n');
		html.add('                renderSlider();\n');
		html.add('            }else{\n');
		html.add('                cv.style.display="none";\n');
		html.add('                if(ds.diffSrc){im.src=ds.diffSrc;im.style.display="block";}else{im.style.display="none";}\n');
		html.add('                lb.textContent="Bright pixels = differences";co.innerHTML="";\n');
		html.add('            }\n');
		html.add('        }\n');
		html.add('        function wipeSlider(v){ds.split=parseInt(v);renderSlider();}\n');
		html.add('        function renderSlider(){\n');
		html.add('            if(!ds.img1||!ds.img2||!ds.img1.complete||!ds.img2.complete)return;\n');
		html.add('            var c=document.getElementById("diffCanvas");\n');
		html.add('            var w=ds.img1.naturalWidth,h=ds.img1.naturalHeight;\n');
		html.add('            var maxW=window.innerWidth*0.9,maxH=window.innerHeight*0.75;\n');
		html.add('            var sc=Math.min(1,maxW/w,maxH/h);\n');
		html.add('            var dw=Math.round(w*sc),dh=Math.round(h*sc);\n');
		html.add('            c.width=dw;c.height=dh;\n');
		html.add('            var ctx=c.getContext("2d");\n');
		html.add('            ctx.imageSmoothingEnabled=false;\n');
		html.add('            var sx=Math.round(dw*ds.split/100);\n');
		html.add('            ctx.save();ctx.beginPath();ctx.rect(0,0,sx,dh);ctx.clip();\n');
		html.add('            ctx.drawImage(ds.img1,0,0,dw,dh);ctx.restore();\n');
		html.add('            ctx.save();ctx.beginPath();ctx.rect(sx,0,dw-sx,dh);ctx.clip();\n');
		html.add('            ctx.drawImage(ds.img2,0,0,dw,dh);ctx.restore();\n');
		html.add('            ctx.fillStyle="#ff0000";ctx.fillRect(sx-1,0,2,dh);\n');
		html.add('        }\n');
		html.add('        document.addEventListener("keydown", function(e) {\n');
		html.add('            if (e.key === "Escape") {\n');
		html.add('                hideOverlay();\n');
		html.add('                hideManim();\n');
		html.add('                hideDiff();\n');
		html.add('            }\n');
		html.add('        });\n');
		html.add('    </script>\n');

		html.add('</body>\n');
		html.add('</html>\n');

		try {
			File.saveContent(reportPath, html.toString());
		} catch (e:Dynamic) {
			// File may be locked by browser — don't fail tests over report writing
			trace('Warning: Could not write report: $e');
		}
	}

	private static function extractTestNumber(testName:String):Int {
		// Test names follow pattern "#17: applyDemo"
		if (testName.startsWith("#")) {
			var colonIdx = testName.indexOf(":");
			if (colonIdx > 1) {
				var numStr = testName.substring(1, colonIdx);
				var num = Std.parseInt(numStr);
				if (num != null) return num;
			}
		}
		return 9999;
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
		var parts:Array<String> = [];
		if (failed > 0) {
			var failedNames = results.filter(r -> !r.passed).map(r -> r.testName);
			parts.push('FAILED: ${failed}/${results.length} visual tests failed [${failedNames.join(", ")}]');
		}
		var macroMismatchCount = results.filter(function(r) {
			if (r.macroPath == null) return false;
			return !(r.similarity == 1.0 && r.macroSimilarity != null && r.macroSimilarity == 1.0);
		}).length;
		if (macroMismatchCount > 0) {
			parts.push('ERROR: ${macroMismatchCount} builder vs macro mismatches');
		}
		if (includeUnitTests && unitAggregator != null && unitAggregator.root != null && !unitAggregator.root.stats.isOk) {
			var us = unitAggregator.root.stats;
			parts.push('FAILED: unit tests: ${us.failures} failures, ${us.errors} errors out of ${us.assertations} assertions');
		}
		if (parts.length > 0) return parts.join("; ");
		return 'OK: ${passed}/${results.length} visual tests passed';
	}

	public static function getStructuredSummary(elapsedSeconds:Int, ?statusOverride:String):String {
		var buf = new StringBuf();
		buf.add("--- TEST RESULT ---\n");

		var visualPassed = results.filter(r -> r.passed).length;
		var visualFailed = results.length - visualPassed;
		var hasFailures = visualFailed > 0;

		// Unit test stats
		var unitFail = 0;
		var unitErr = 0;
		var unitAssert = 0;
		if (includeUnitTests && unitAggregator != null && unitAggregator.root != null) {
			var us = unitAggregator.root.stats;
			unitFail = us.failures;
			unitErr = us.errors;
			unitAssert = us.assertations;
			if (!us.isOk) hasFailures = true;
		}

		// Builder vs Macro mismatches
		var macroMismatchNames = results.filter(function(r) {
			if (r.macroPath == null) return false;
			return !(r.similarity == 1.0 && r.macroSimilarity != null && r.macroSimilarity == 1.0);
		}).map(r -> r.testName);
		if (macroMismatchNames.length > 0) hasFailures = true;

		var status = statusOverride != null ? statusOverride : (hasFailures ? "FAILED" : "OK");
		buf.add('status: ${status}\n');
		buf.add('visual_total: ${results.length}\n');
		buf.add('visual_passed: ${visualPassed}\n');
		buf.add('visual_failed: ${visualFailed}\n');
		if (visualFailed > 0) {
			var failedNames = results.filter(r -> !r.passed).map(r -> r.testName);
			buf.add('visual_failures: [${failedNames.join(", ")}]\n');
		}
		buf.add('macro_mismatches: ${macroMismatchNames.length}\n');
		if (macroMismatchNames.length > 0) {
			buf.add('macro_mismatch_tests: [${macroMismatchNames.join(", ")}]\n');
		}
		buf.add('unit_assertions: ${unitAssert}\n');
		buf.add('unit_failures: ${unitFail}\n');
		buf.add('unit_errors: ${unitErr}\n');

		// Per-failure details for unit tests
		if ((unitFail > 0 || unitErr > 0) && unitAggregator != null && unitAggregator.root != null) {
			var details:Array<String> = [];
			var allClasses:Array<utest.ui.common.ClassResult> = [];
			collectClasses(unitAggregator.root, allClasses);
			for (cls in allClasses) {
				for (methodName in cls.methodNames()) {
					var fixture = cls.get(methodName);
					if (!fixture.stats.isOk) {
						for (assertation in fixture) {
							switch (assertation) {
								case Failure(msg, pos):
									details.push('${cls.className}.${methodName}: ${pos.fileName}:${pos.lineNumber}: ${msg}');
								case Error(e, stack):
									details.push('${cls.className}.${methodName}: ${Std.string(e)}');
								default:
							}
						}
					}
				}
			}
			if (details.length > 0) {
				buf.add('unit_error_details: [${details.join(", ")}]\n');
			}
		}

		buf.add('elapsed_seconds: ${elapsedSeconds}\n');
		buf.add("--- END TEST RESULT ---");
		return buf.toString();
	}

	public static function clear():Void {
		results = [];
		unitAggregator = null;
		includeUnitTests = false;
	}

	/**
	 * Generate a grayscale diff image: abs(image1 - image2) amplified 5x.
	 * Black = identical, white = maximum difference.
	 */
	public static function generateDiffImage(path1:String, path2:String, outputPath:String):Bool {
		if (!FileSystem.exists(path1) || !FileSystem.exists(path2)) return false;
		try {
			var bytes1 = File.getBytes(path1);
			var bytes2 = File.getBytes(path2);
			var p1 = hxd.res.Any.fromBytes(path1, bytes1).toImage().getPixels();
			var p2 = hxd.res.Any.fromBytes(path2, bytes2).toImage().getPixels();
			if (p1.width != p2.width || p1.height != p2.height) return false;
			for (x in 0...p1.width) {
				for (y in 0...p1.height) {
					var c1 = p1.getPixel(x, y);
					var c2 = p2.getPixel(x, y);
					var dr = Std.int(Math.abs(((c1 >> 16) & 0xFF) - ((c2 >> 16) & 0xFF)));
					var dg = Std.int(Math.abs(((c1 >> 8) & 0xFF) - ((c2 >> 8) & 0xFF)));
					var db = Std.int(Math.abs((c1 & 0xFF) - (c2 & 0xFF)));
					var v = Std.int(Math.min(255, Math.max(dr, Math.max(dg, db)) * 5));
					p1.setPixel(x, y, 0xFF000000 | (v << 16) | (v << 8) | v);
				}
			}
			File.saveBytes(outputPath, p1.toPNG());
			return true;
		} catch (e:Dynamic) {
			return false;
		}
	}

	private static function generateUnitTestSection(html:StringBuf):Void {
		if (!includeUnitTests || unitAggregator == null || unitAggregator.root == null) return;

		var unitTestResult = unitAggregator.root;
		var stats = unitTestResult.stats;
		var allOk = stats.isOk;
		var summaryClass = allOk ? "all-passed" : "has-failures";

		html.add('    <div class="unit-tests-section">\n');
		html.add('        <h2>Unit Tests</h2>\n');
		html.add('        <div class="unit-tests-summary ${summaryClass}">\n');
		html.add('            <strong>${stats.assertations} assertions:</strong> ');
		html.add('            <span style="color: #4CAF50;">${stats.successes} passed</span>');
		if (stats.failures > 0) html.add(', <span style="color: #f44336;">${stats.failures} failures</span>');
		if (stats.errors > 0) html.add(', <span style="color: #f44336;">${stats.errors} errors</span>');
		if (stats.warnings > 0) html.add(', <span style="color: #FF9800;">${stats.warnings} warnings</span>');
		html.add('\n');
		html.add('            <button class="expand-btn" id="unitToggleBtn" onclick="toggleUnitDetails()">Show Details</button>\n');
		html.add('        </div>\n');

		// Collapsible details
		html.add('        <div class="unit-details" id="unitDetails">\n');

		var allClasses:Array<utest.ui.common.ClassResult> = [];
		collectClasses(unitTestResult, allClasses);
		for (cls in allClasses) {
			generateUnitClass(html, cls);
		}

		html.add('        </div>\n');
		html.add('    </div>\n');
	}

	private static function collectClasses(root:utest.ui.common.PackageResult, out:Array<utest.ui.common.ClassResult>):Void {
		// Collect root-level classes
		for (className in root.classNames()) {
			out.push(root.getClass(className));
		}
		// Collect classes from direct packages only (no recursion — flattenPackage=true
		// puts all packages at root level, and PackageResult can have circular refs)
		for (pkgName in root.packageNames()) {
			var pkg = root.getPackage(pkgName);
			for (className in pkg.classNames()) {
				out.push(pkg.getClass(className));
			}
		}
	}

	private static function generateUnitClass(html:StringBuf, cls:utest.ui.common.ClassResult):Void {
		html.add('            <div class="unit-class">\n');
		html.add('                <div class="unit-class-name">${cls.className.htmlEscape()}</div>\n');

		for (methodName in cls.methodNames()) {
			var fixture = cls.get(methodName);
			var ok = fixture.stats.isOk;
			var statusCls = ok ? "pass" : "fail";
			var dots = "";
			for (assertation in fixture) {
				switch (assertation) {
					case Success(_): dots += ".";
					case Failure(_, _): dots += "F";
					case Error(_, _): dots += "E";
					case SetupError(_, _): dots += "S";
					case TeardownError(_, _): dots += "T";
					case TimeoutError(_, _): dots += "O";
					case AsyncError(_, _): dots += "A";
					case Warning(_): dots += "W";
					case Ignore(_): dots += "I";
				}
			}
			var prefix = ok ? "OK" : "FAIL";
			html.add('                <div class="unit-method ${statusCls}">${methodName.htmlEscape()}: ${prefix} <span class="dots">${dots}</span></div>\n');

			// Show failure details
			if (!ok) {
				for (assertation in fixture) {
					switch (assertation) {
						case Failure(msg, pos):
							var detail = '${pos.fileName}:${pos.lineNumber}: ${msg}';
							html.add('                <div class="unit-fail-detail">${detail.htmlEscape()}</div>\n');
						case Error(e, stack):
							var detail = Std.string(e);
							html.add('                <div class="unit-fail-detail">${detail.htmlEscape()}</div>\n');
						default:
					}
				}
			}
		}
		html.add('            </div>\n');
	}
}
