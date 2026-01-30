package bh.test;

import hxd.App;
import h2d.Scene;
import utest.Runner;
import utest.ui.Report;
import bh.test.VisualTestBase;

class TestApp extends hxd.App {
	private var testRunner:Runner;
	private var frameCount:Int = 0;
	private var updateSubscribers:Array<Float -> Void> = [];
	private var testsCompleted:Bool = false;

	override function init() {
		// Initialize Heaps resource system
		hxd.Res.initLocal();

		// Set app instance for tests to use
		VisualTestBase.appInstance = this;

		// Clear HTML report
		HtmlReportGenerator.clear();

		testRunner = new Runner();

		// Add test cases with scene reference
		testRunner.addCase(new bh.test.examples.AllExamplesTest(s2d));

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
			// With 21 examples + existing tests, we need more frames
			if (frameCount >= 30) {
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
		trace("Starting test app...");
		new TestApp();
	}
}
