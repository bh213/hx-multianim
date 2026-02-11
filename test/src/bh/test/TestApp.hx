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
	private var testsCompleted:Bool = false;

	override function init() {
		// Initialize Heaps resource system
		hxd.Res.initLocal();

		// Register fonts used by tests
		// Note: -white suffix indicates fonts with hardcoded white color
		// Y offsets normalize positioning so text at (0,0) starts at top-left
		FontManager.registerFont("dd", hxd.Res.fonts.digitaldisco.toFont(), 0, -1);
		FontManager.registerFont("pixeled6", hxd.Res.fonts.pixeled_6.toFont(), 0, -4);
		FontManager.registerFont("m3x6", hxd.Res.fonts.m3x6.toFont(), 0, -5);
		FontManager.registerFont("pixellari", hxd.Res.fonts.pixellari.toFont());
		FontManager.registerFont("f3x5", hxd.Res.fonts.f3x5.toFont());
		FontManager.registerFont("peaberry-white", hxd.Res.fonts.WhitePeaberry.toFont());
		FontManager.registerFont("peaberry-white-outline", hxd.Res.fonts.WhitePeaberryOutline.toFont(), 0, -5);

		// Set app instance for tests to use
		VisualTestBase.appInstance = this;

		// Clear HTML report
		HtmlReportGenerator.clear();

		testRunner = new Runner();

		// Add test cases with scene reference
		testRunner.addCase(new bh.test.examples.AllExamplesTest(s2d));
		testRunner.addCase(new bh.test.examples.ParserErrorTest());
		testRunner.addCase(new bh.test.examples.AnimParserTest());
		testRunner.addCase(new bh.test.examples.ProgrammableCodeGenTest(s2d));

		Report.create(testRunner);
	}

	/**
	 * Register a callback to be called on each update (frame)
	 */
	public function subscribeToUpdate(callback:Float -> Void):Void {
		updateSubscribers.push(callback);
	}

	override function update(dt:Float) {
		frameCount++;
		
		// Call all subscribers
		for (callback in updateSubscribers) {
			callback(dt);
		}
		
		// Run tests on first frame, then allow callbacks to execute
		if (frameCount == 1) {
			// Run tests on first frame - this will subscribe callbacks
			testRunner.run();
			testsCompleted = true;
		}
		
			// Exit after enough frames to let all update callbacks finish
			// With visual examples + codegen tests + parser error tests, we need enough frames
			if (frameCount >= 58) {
				// Generate visual HTML report before exiting
				HtmlReportGenerator.generateReport();
				Sys.exit(0);
			}
	}

	override function render(e:h3d.Engine) {
		e.clear(0, 1);
		s2d.render(e);
	}

	static function main() {
		#if VERBOSE
		trace("Starting test app...");
		#end
		new TestApp();
	}
}
