package bh.test;

import hxd.App;
import h2d.Scene;
import utest.Runner;
import utest.ui.Report;
import bh.test.VisualTestBase;
import bh.base.FontManager;

class TestApp extends hxd.App {
	// Force compilation of @:build macro generated class
	static var _forceBuild:Any = (null : bh.test.MultiProgrammable);

	private var testRunner:Runner;
	private var frameCount:Int = 0;
	private var updateSubscribers:Array<Float -> Void> = [];
	private var testsStarted:Bool = false;
	private var testsCompleted:Bool = false;
	// Frames to wait after all visual tests complete (for async callbacks to flush)
	private static inline var POST_COMPLETION_FRAMES = 3;
	private var postCompletionCounter:Int = 0;

	override function init() {
		hxd.Res.initLocal();

		FontManager.registerFont("dd", hxd.Res.fonts.digitaldisco.toFont(), 0, -1);
		FontManager.registerFont("pixeled6", hxd.Res.fonts.pixeled_6.toFont(), 0, -4);
		FontManager.registerFont("m3x6", hxd.Res.fonts.m3x6.toFont(), 0, -5);
		FontManager.registerFont("pixellari", hxd.Res.fonts.pixellari.toFont());
		FontManager.registerFont("f3x5", hxd.Res.fonts.f3x5.toFont());
		FontManager.registerFont("peaberry-white", hxd.Res.fonts.WhitePeaberry.toFont());
		FontManager.registerFont("peaberry-white-outline", hxd.Res.fonts.WhitePeaberryOutline.toFont(), 0, -5);

		VisualTestBase.appInstance = this;

		HtmlReportGenerator.clear();

		testRunner = new Runner();

		// Single test filtering: -D SINGLE_TEST=N runs only testNN_ methods
		applySingleTestFilter(testRunner);

		testRunner.addCase(new bh.test.examples.AllExamplesTest(s2d));
		testRunner.addCase(new bh.test.examples.ParserErrorTest());
		testRunner.addCase(new bh.test.examples.AnimParserTest());
		testRunner.addCase(new bh.test.examples.ProgrammableCodeGenTest(s2d));

		Report.create(testRunner);
	}

	public function subscribeToUpdate(callback:Float -> Void):Void {
		updateSubscribers.push(callback);
	}

	override function update(dt:Float) {
		frameCount++;

		for (callback in updateSubscribers) {
			callback(dt);
		}

		// Start tests on first frame
		if (frameCount == 1) {
			testRunner.run();
			testsStarted = true;
		}

		// After tests started, wait for all visual tests to complete
		if (testsStarted && !testsCompleted) {
			if (VisualTestBase.pendingVisualTests <= 0 && frameCount > 2) {
				testsCompleted = true;
				postCompletionCounter = 0;
			}
		}

		// After all visual tests complete, wait a few more frames then exit
		if (testsCompleted) {
			postCompletionCounter++;
			if (postCompletionCounter >= POST_COMPLETION_FRAMES) {
				HtmlReportGenerator.generateReport();
				var summary = HtmlReportGenerator.getSummary();
				sys.io.File.saveContent("build/test_result.txt", summary);
				Sys.exit(summary.indexOf("FAILED") >= 0 ? 1 : 0);
			}
		}

		// Safety timeout: exit after 200 frames regardless
		if (frameCount >= 200) {
			trace("Warning: Safety timeout reached (200 frames), exiting with pending visual tests: " + VisualTestBase.pendingVisualTests);
			HtmlReportGenerator.generateReport();
			sys.io.File.saveContent("build/test_result.txt", "FAILED: Safety timeout (200 frames), pending: " + VisualTestBase.pendingVisualTests);
			Sys.exit(1);
		}
	}

	override function render(e:h3d.Engine) {
		e.clear(0, 1);
		s2d.render(e);
	}

	static function applySingleTestFilter(runner:Runner):Void {
		var testNumStr = SingleTestMacro.getDefineValue();
		if (testNumStr != null) {
			var testNum = Std.parseInt(testNumStr);
			if (testNum != null) {
				var padded = testNum < 10 ? '0$testNum' : '$testNum';
				runner.globalPattern = new EReg('test${padded}_', '');
				#if VERBOSE
				trace('Single test mode: running test #$testNum (pattern: test${padded}_)');
				#end
			}
		}
	}

	static function main() {
		#if VERBOSE
		trace("Starting test app...");
		#end
		new TestApp();
	}
}
