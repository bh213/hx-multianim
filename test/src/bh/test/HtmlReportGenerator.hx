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
}

class HtmlReportGenerator {
	private static var results:Array<TestResult> = [];
	private static var reportPath:String = "test/screenshots/index.html";

	public static function addResult(testName:String, referencePath:String, actualPath:String, passed:Bool, similarity:Float):Void {
		results.push({
			testName: testName,
			referencePath: referencePath,
			actualPath: actualPath,
			passed: passed,
			similarity: similarity
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
		html.add('        .image-comparison {\n');
		html.add('            display: grid;\n');
		html.add('            grid-template-columns: 1fr 1fr;\n');
		html.add('            gap: 20px;\n');
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
		html.add('        }\n');
		html.add('        .no-image {\n');
		html.add('            padding: 40px;\n');
		html.add('            background: #f9f9f9;\n');
		html.add('            border: 1px dashed #ccc;\n');
		html.add('            border-radius: 3px;\n');
		html.add('            color: #999;\n');
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

		// Individual test results
		for (result in results) {
			var statusClass = result.passed ? "passed" : "failed";
			var statusText = result.passed ? "PASSED" : "FAILED";
			var similarityPercent = Math.round(result.similarity * 10000) / 100;

			html.add('    <div class="test-result ${statusClass}">\n');
			html.add('        <div class="test-header">\n');
			html.add('            <div class="test-name">${result.testName}</div>\n');
			html.add('            <div class="test-status ${statusClass}">${statusText}</div>\n');
			html.add('        </div>\n');
			html.add('        <div class="similarity">Similarity: ${similarityPercent}%</div>\n');
			html.add('        <div class="image-comparison">\n');

			// Reference image
			html.add('            <div class="image-container">\n');
			html.add('                <div class="image-label">Reference</div>\n');
			if (FileSystem.exists(result.referencePath)) {
				var relPath = makeRelativePath(result.referencePath);
				html.add('                <img src="${relPath}" alt="Reference">\n');
			} else {
				html.add('                <div class="no-image">No reference image</div>\n');
			}
			html.add('            </div>\n');

			// Actual image
			html.add('            <div class="image-container">\n');
			html.add('                <div class="image-label">Actual</div>\n');
			if (FileSystem.exists(result.actualPath)) {
				var relPath = makeRelativePath(result.actualPath);
				html.add('                <img src="${relPath}" alt="Actual">\n');
			} else {
				html.add('                <div class="no-image">No actual image</div>\n');
			}
			html.add('            </div>\n');

			html.add('        </div>\n');
			html.add('    </div>\n');
		}

		html.add('</body>\n');
		html.add('</html>\n');

		File.saveContent(reportPath, html.toString());
		trace('HTML report generated: ${reportPath}');
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

	public static function clear():Void {
		results = [];
	}
}
