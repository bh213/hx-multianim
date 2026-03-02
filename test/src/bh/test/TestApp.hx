package bh.test;

import hxd.App;
import h2d.Scene;
import utest.Runner;
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
	private var startTime:Float = 0;
	private var unitTestEndTime:Float = 0;
	private var visualTestEndTime:Float = 0;
	private static inline var WALL_CLOCK_TIMEOUT_SEC = 60.0;
	// Frames to wait after all visual tests complete (for async callbacks to flush)
	private static inline var POST_COMPLETION_FRAMES = 3;
	private var postCompletionCounter:Int = 0;
	private var poolDrained:Bool = false;
	private var statusText:h2d.Text = null;
	private var poolTotal:Int = 0;
	private var lastTracedDone:Int = -1;

	override function init() {
		hxd.Res.initLocal();
		
		FontManager.registerFont("dd", hxd.Res.fonts.digitaldisco.toFont(), 0, -3);
		FontManager.registerFont("pixeled6", hxd.Res.fonts.pixeled_6.toFont(), 0, -4);
		FontManager.registerFont("m3x6", hxd.Res.fonts.m3x6.toFont(), 0, -5);
		FontManager.registerFont("pixellari", hxd.Res.fonts.pixellari.toFont(), -1, -1);
		FontManager.registerFont("f3x5", hxd.Res.fonts.f3x5.toFont());
		FontManager.registerFont("peaberry-white", hxd.Res.fonts.WhitePeaberry.toFont(), -2, -9);
		FontManager.registerFont("peaberry-white-outline", hxd.Res.fonts.WhitePeaberryOutline.toFont(), -2, -10);
		FontManager.registerFont("m6x11", hxd.Res.fonts.m6x11.toFont());

		VisualTestBase.appInstance = this;
		VisualTestBase.imagePool = new ImageProcessingPool();

		HtmlReportGenerator.clear();

		startTime = Sys.time();

		testRunner = new Runner();

		// Single test filtering: -D SINGLE_TEST=N runs only testNN_ methods
		applySingleTestFilter(testRunner);

		testRunner.addCase(new bh.test.examples.ParserErrorTest());
		testRunner.addCase(new bh.test.examples.AnimParserTest());
		testRunner.addCase(new bh.test.examples.BuilderUnitTest());
		testRunner.addCase(new bh.test.examples.UIComponentTest());
		testRunner.addCase(new bh.test.examples.UITooltipHelperTest());
		testRunner.addCase(new bh.test.examples.UIPanelHelperTest());
		testRunner.addCase(new bh.test.examples.UIRichInteractiveHelperTest());
		testRunner.addCase(new bh.test.examples.ParticleRuntimeTest());
		testRunner.addCase(new bh.test.examples.TweenManagerTest());
		testRunner.addCase(new bh.test.examples.ProgrammableCodeGenTest(s2d));
		testRunner.addCase(new bh.test.examples.ScreenTransitionTest());
		testRunner.addCase(new bh.test.examples.AnimatedPathTest());
		testRunner.addCase(new bh.test.examples.CardHandOrchestratorTest());
		testRunner.addCase(new bh.test.examples.AnimFilterRuntimeTest());
		testRunner.addCase(new bh.test.examples.RichTextTest());
		testRunner.addCase(new bh.test.examples.ParameterizedSlotTest());
		testRunner.addCase(new bh.test.examples.InteractiveEventTest());
		testRunner.addCase(new bh.test.examples.FlowOverflowTest());
		testRunner.addCase(new bh.test.examples.DynamicRefTest());
		testRunner.addCase(new bh.test.examples.BitFlagTest());
		#if MULTIANIM_DEV
		testRunner.addCase(new bh.test.examples.HotReloadTest());
		#end

		// Capture unit test results in memory for HTML report
		// (not using Report.create which calls Sys.exit on completion)
		HtmlReportGenerator.setUnitTestAggregator(new utest.ui.common.ResultAggregator(testRunner, true));
		hxd.Window.getInstance().vsync = false;
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
			unitTestEndTime = Sys.time();
			testsStarted = true;
		}

		// After tests started, wait for all visual tests to complete
		if (testsStarted && !testsCompleted) {
			if (VisualTestBase.pendingVisualTests <= 0 && frameCount > 2) {
				testsCompleted = true;
				if (VisualTestBase.imagePool != null) {
					poolTotal = VisualTestBase.imagePool.getTotalEnqueued();
					showStatus('Processing $poolTotal images...');
					VisualTestBase.imagePool.startProcessing();
				}
			}
		}

		// After all visual tests complete, poll pool and update status each frame
		if (testsCompleted && !poolDrained) {
			var pool = VisualTestBase.imagePool;
			if (pool != null) {
				var done = pool.getCompletedCount();
				var pct = if (poolTotal > 0) Math.round(done * 100 / poolTotal) else 0;
				#if (VERBOSE || PROGRESS)
				if (done != lastTracedDone) {
					lastTracedDone = done;
					Sys.stderr().writeString('Processing images... $done/$poolTotal ($pct%)\r\n');
					Sys.stderr().flush();
				}
				#end
				if (pool.isComplete()) {
					pool.shutdown();
					HtmlReportGenerator.addCompletedResults(pool.getResults());
					poolDrained = true;
					visualTestEndTime = Sys.time();
					showStatus('Processing complete ($poolTotal images). Generating report...');
					Sys.stderr().writeString('Image processing complete ($poolTotal images).\r\n');
					Sys.stderr().flush();
					postCompletionCounter = 0;
				} else {
					showStatus('Processing images... $done/$poolTotal ($pct%)');
				}
			} else {
				poolDrained = true;
				visualTestEndTime = Sys.time();
			}
		}

		if (poolDrained) {
			postCompletionCounter++;
			if (postCompletionCounter >= POST_COMPLETION_FRAMES) {
				finishAndExit(null);
			}
		}

		// Safety timeout: exit after 60 seconds wall-clock
		var elapsed = Sys.time() - startTime;
		if (elapsed >= WALL_CLOCK_TIMEOUT_SEC) {
			trace('Warning: Safety timeout reached (elapsed: ${Math.round(elapsed)}s, frames: $frameCount), '
				+ 'pending visual tests: ${VisualTestBase.pendingVisualTests}');
			if (!poolDrained && VisualTestBase.imagePool != null) {
				if (!testsCompleted) {
					// Timeout before captures finished — start processing what we have
					VisualTestBase.imagePool.startProcessing();
				}
				VisualTestBase.imagePool.shutdownAndWait();
				HtmlReportGenerator.addCompletedResults(VisualTestBase.imagePool.getResults());
				poolDrained = true;
				visualTestEndTime = Sys.time();
			}
			finishAndExit("TIMEOUT");
		}
	}

	private function showStatus(msg:String):Void {
		if (statusText == null) {
			s2d.removeChildren();
			statusText = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
			statusText.textColor = 0xFFFFFF;
			statusText.setScale(2);
			statusText.setPosition(20, 20);
		}
		statusText.text = msg;
	}

	private function finishAndExit(?statusOverride:String):Void {
		var elapsedSec = Math.round(Sys.time() - startTime);
		// unit_seconds = start to first visual capture (pure unit tests)
		// visual_seconds = first visual capture to pool drain complete (captures + processing)
		var visualStart = VisualTestBase.firstVisualCaptureTime;
		var unitSec = if (visualStart > 0) Math.round((visualStart - startTime) * 10) / 10 else Math.round((unitTestEndTime - startTime) * 10) / 10;
		var visualSec = if (visualStart > 0 && visualTestEndTime > 0) Math.round((visualTestEndTime - visualStart) * 10) / 10 else 0.0;
		HtmlReportGenerator.enableUnitTestReport();
		HtmlReportGenerator.setTiming(unitSec, visualSec);
		HtmlReportGenerator.generateReport();
		var structured = HtmlReportGenerator.getStructuredSummary(elapsedSec, statusOverride, unitSec, visualSec);
		sys.io.File.saveContent("build/test_result.txt", structured);
		Sys.exit(structured.indexOf("status: FAILED") >= 0 ? 1 : 0);
	}

	override function render(e:h3d.Engine) {
		e.clear(0, 1);
		try {
			s2d.render(e);
		} catch (err:Dynamic) {
			trace('Error during render: $err');
			s2d.removeChildren();
		}
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
