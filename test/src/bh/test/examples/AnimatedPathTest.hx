package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.paths.AnimatedPath;
import bh.paths.MultiAnimPaths.Path;
import bh.paths.MultiAnimPaths.SinglePath;
import bh.paths.Curve;
import bh.base.FPoint;

/**
 * Unit tests for AnimatedPath:
 * time/distance modes, seek, reset, events, curves, loops, pingPong, color.
 * Also builder integration tests for createAnimatedPath/createProjectilePath.
 */
class AnimatedPathTest extends BuilderTestBase {
	// ==================== Helpers ====================

	/** Create a straight-line path from (0,0) to (100,0), length = 100. */
	static function createLinePath():Path {
		var sp = new SinglePath(new FPoint(0, 0), new FPoint(100, 0), Line);
		return new Path([sp]);
	}

	/** Create a straight-line path from (0,0) to (0,200), length = 200. */
	static function createVerticalPath():Path {
		var sp = new SinglePath(new FPoint(0, 0), new FPoint(0, 200), Line);
		return new Path([sp]);
	}

	/** Create a simple linear curve (identity: getValue(t) = t). */
	static function createLinearCurve():ICurve {
		return new Curve(null, Linear);
	}

	// ==================== Construction ====================

	@Test
	public function testConstructionTimeMode():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		Assert.notNull(ap);
		Assert.floatEquals(100.0, ap.path.totalLength);
	}

	@Test
	public function testConstructionDistanceMode():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Distance(50.0));
		Assert.notNull(ap);
	}

	@Test
	public function testZeroLengthPathThrows():Void {
		// A zero-length path (start == end) should throw
		var sp = new SinglePath(new FPoint(0, 0), new FPoint(0, 0), Line);
		try {
			var zeroPath = new Path([sp]);
			var ap = new AnimatedPath(zeroPath, Time(1.0));
			Assert.fail("Should have thrown for zero-length path");
		} catch (e:Dynamic) {
			Assert.isTrue(true);
		}
	}

	// ==================== Seek ====================

	@Test
	public function testSeekAtStart():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		var state = ap.seek(0.0);
		Assert.floatEquals(0.0, state.position.x);
		Assert.floatEquals(0.0, state.position.y);
		Assert.floatEquals(0.0, state.rate);
		Assert.isFalse(state.done);
	}

	@Test
	public function testSeekAtEnd():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		var state = ap.seek(1.0);
		Assert.floatEquals(100.0, state.position.x);
		Assert.floatEquals(0.0, state.position.y);
		Assert.floatEquals(1.0, state.rate);
	}

	@Test
	public function testSeekAtMidpoint():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		var state = ap.seek(0.5);
		Assert.floatEquals(50.0, state.position.x);
		Assert.floatEquals(0.5, state.rate);
	}

	@Test
	public function testSeekDoesNotFireEvents():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		ap.addEvent(0.5, "halfway");
		var eventFired = false;
		ap.onEvent = function(name, state) {
			if (name == "halfway") eventFired = true;
		};
		ap.seek(0.6); // past the event
		Assert.isFalse(eventFired);
	}

	// ==================== Time Mode Update ====================

	@Test
	public function testTimeModeProgressionLinear():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));

		var state = ap.update(0.5);
		Assert.floatEquals(0.5, state.rate);
		Assert.floatEquals(50.0, state.position.x);
		Assert.isFalse(state.done);
	}

	@Test
	public function testTimeModeCompletion():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));

		ap.update(0.5);
		var state = ap.update(0.5);
		Assert.floatEquals(1.0, state.rate);
		Assert.floatEquals(100.0, state.position.x);
		Assert.isTrue(state.done);
	}

	@Test
	public function testTimeModeOvershoot():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));

		var state = ap.update(2.0); // overshoot
		Assert.isTrue(state.done);
		Assert.floatEquals(100.0, state.position.x);
	}

	@Test
	public function testTimeModeZeroDtIgnored():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));

		var state = ap.update(0.0);
		// Zero dt should not advance
		Assert.isFalse(state.done);
	}

	// ==================== Distance Mode Update ====================

	@Test
	public function testDistanceModeProgression():Void {
		var path = createLinePath(); // length = 100
		var ap = new AnimatedPath(path, Distance(50.0)); // 50 px/sec

		var state = ap.update(1.0); // 50 pixels in 1 sec → rate = 0.5
		Assert.floatEquals(0.5, state.rate);
		Assert.floatEquals(50.0, state.position.x);
		Assert.isFalse(state.done);
	}

	@Test
	public function testDistanceModeCompletion():Void {
		var path = createLinePath(); // length = 100
		var ap = new AnimatedPath(path, Distance(100.0)); // 100 px/sec

		var state = ap.update(1.0); // 100 pixels → done
		Assert.isTrue(state.done);
		Assert.floatEquals(100.0, state.position.x);
	}

	// ==================== Events ====================

	@Test
	public function testPathStartEvent():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		var events:Array<String> = [];
		ap.onEvent = function(name, state) {
			events.push(name);
		};
		ap.update(0.1);
		Assert.isTrue(events.indexOf("pathStart") >= 0);
	}

	@Test
	public function testPathEndEvent():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		var events:Array<String> = [];
		ap.onEvent = function(name, state) {
			events.push(name);
		};
		ap.update(1.0);
		Assert.isTrue(events.indexOf("pathEnd") >= 0);
	}

	@Test
	public function testCustomEventAtRate():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		ap.addEvent(0.5, "halfway");
		var firedEvents:Array<String> = [];
		ap.onEvent = function(name, state) {
			firedEvents.push(name);
		};
		ap.update(0.6); // past 0.5
		Assert.isTrue(firedEvents.indexOf("halfway") >= 0);
	}

	@Test
	public function testMultipleEventsOrdered():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		ap.addEvent(0.2, "first");
		ap.addEvent(0.5, "second");
		ap.addEvent(0.8, "third");
		var firedEvents:Array<String> = [];
		ap.onEvent = function(name, state) {
			if (name != "pathStart" && name != "pathEnd")
				firedEvents.push(name);
		};
		ap.update(1.0);
		Assert.equals(3, firedEvents.length);
		Assert.equals("first", firedEvents[0]);
		Assert.equals("second", firedEvents[1]);
		Assert.equals("third", firedEvents[2]);
	}

	// ==================== Reset ====================

	@Test
	public function testReset():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		ap.update(0.5);
		ap.reset();
		var state = ap.getState();
		// After reset, update should start from beginning
		var newState = ap.update(0.3);
		Assert.floatEquals(0.3, newState.rate);
		Assert.isFalse(newState.done);
	}

	@Test
	public function testResetAfterCompletion():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		ap.update(1.5); // complete
		Assert.isTrue(ap.getState().done);

		ap.reset();
		var state = ap.update(0.5);
		Assert.isFalse(state.done);
		Assert.floatEquals(0.5, state.rate);
	}

	// ==================== Loop ====================

	@Test
	public function testLoopContinues():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		ap.loop = true;

		ap.update(1.5); // complete one cycle + 0.5 into next
		var state = ap.getState();
		Assert.isFalse(state.done);
		Assert.equals(1, state.cycle);
	}

	@Test
	public function testLoopCycleEvents():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		ap.loop = true;
		var events:Array<String> = [];
		ap.onEvent = function(name, state) {
			events.push(name);
		};
		ap.update(1.5);
		Assert.isTrue(events.indexOf("cycleEnd") >= 0);
		Assert.isTrue(events.indexOf("cycleStart") >= 0);
	}

	// ==================== PingPong ====================

	@Test
	public function testPingPongReverses():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		ap.pingPong = true;

		// First cycle forward: 0→100
		ap.update(1.0);
		// After cycleEnd, direction reverses. Second cycle: 100→0
		// At cycle 1, rate 0.5 reversed = position at 50
		var state = ap.update(0.5);
		Assert.isFalse(state.done);
		Assert.equals(1, state.cycle);
		// In reversed direction, position should be going back toward 0
		Assert.isTrue(state.position.x < 100.0);
	}

	// ==================== Scale Curve ====================

	@Test
	public function testScaleCurve():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		// Linear curve from 1.0 to 1.0 (identity - getValue returns t)
		ap.addCurveSegment(Scale, 0.0, createLinearCurve());

		var state = ap.seek(0.5);
		// Linear easing at t=0.5 returns 0.5
		Assert.floatEquals(0.5, state.scale);

		state = ap.seek(1.0);
		Assert.floatEquals(1.0, state.scale);
	}

	@Test
	public function testDefaultScaleWithoutCurve():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		var state = ap.seek(0.5);
		// Default scale is 1.0 when no curve segment
		Assert.floatEquals(1.0, state.scale);
	}

	// ==================== Alpha Curve ====================

	@Test
	public function testAlphaCurve():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		ap.addCurveSegment(Alpha, 0.0, createLinearCurve());

		var state = ap.seek(0.0);
		Assert.floatEquals(0.0, state.alpha);

		state = ap.seek(1.0);
		Assert.floatEquals(1.0, state.alpha);
	}

	@Test
	public function testDefaultAlphaWithoutCurve():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		var state = ap.seek(0.5);
		// Default alpha is 1.0 when no curve
		Assert.floatEquals(1.0, state.alpha);
	}

	// ==================== Rotation Curve ====================

	@Test
	public function testRotationCurve():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		ap.addCurveSegment(Rotation, 0.0, createLinearCurve());

		var state = ap.seek(0.5);
		Assert.floatEquals(0.5, state.rotation);
	}

	@Test
	public function testDefaultRotationWithoutCurve():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		var state = ap.seek(0.5);
		// Default rotation is 0.0 when no curve
		Assert.floatEquals(0.0, state.rotation);
	}

	// ==================== Speed Curve ====================

	@Test
	public function testSpeedCurveInDistanceMode():Void {
		var path = createLinePath(); // length = 100
		var ap = new AnimatedPath(path, Distance(100.0)); // 100 px/sec base
		// Speed curve: at t=0 returns 0.5 (half speed)
		// Using linear curve: at rate 0 returns 0, at rate 0.5 returns 0.5, at rate 1 returns 1
		ap.addCurveSegment(Speed, 0.0, createLinearCurve());

		// With speed curve, effective speed varies. After some update, rate should differ from constant speed.
		var state = ap.update(0.5);
		// At low rates, speed multiplier is small, so distance covered < 50 pixels
		Assert.isTrue(state.rate < 0.5);
	}

	// ==================== Color Curve ====================

	@Test
	public function testColorCurve():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		ap.addColorCurveSegment(0.0, createLinearCurve(), 0xFF0000, 0x0000FF);

		var state = ap.seek(0.0);
		Assert.equals(0xFF0000, state.color);

		state = ap.seek(1.0);
		Assert.equals(0x0000FF, state.color);
	}

	@Test
	public function testColorCurveMidpoint():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		ap.addColorCurveSegment(0.0, createLinearCurve(), 0xFF0000, 0x0000FF);

		var state = ap.seek(0.5);
		// At midpoint with linear curve: R = ~127, G = 0, B = ~127
		var r = (state.color >> 16) & 0xFF;
		var b = state.color & 0xFF;
		Assert.isTrue(r > 100 && r < 160); // ~127
		Assert.isTrue(b > 100 && b < 160); // ~127
	}

	@Test
	public function testDefaultColorWithoutCurve():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		var state = ap.seek(0.5);
		Assert.equals(0xFFFFFF, state.color);
	}

	// ==================== Custom Curves ====================

	@Test
	public function testCustomCurve():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		ap.addCustomCurveSegment("myValue", 0.0, createLinearCurve());

		var state = ap.seek(0.5);
		Assert.notNull(state.custom);
		var val = state.custom.get("myValue");
		Assert.notNull(val);
		Assert.floatEquals(0.5, val);
	}

	@Test
	public function testMultipleCustomCurves():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		ap.addCustomCurveSegment("curveA", 0.0, createLinearCurve());
		ap.addCustomCurveSegment("curveB", 0.0, createLinearCurve());

		var state = ap.seek(0.7);
		Assert.floatEquals(0.7, state.custom.get("curveA"));
		Assert.floatEquals(0.7, state.custom.get("curveB"));
	}

	// ==================== Duration Override ====================

	@Test
	public function testDurationOverride():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(2.0)); // base duration 2s
		ap.durationOverride = 1.0; // override to 1s

		var state = ap.update(1.0);
		Assert.isTrue(state.done);
		Assert.floatEquals(100.0, state.position.x);
	}

	// ==================== State Fields ====================

	@Test
	public function testAngleOnHorizontalPath():Void {
		var path = createLinePath(); // (0,0) to (100,0), angle = 0
		var ap = new AnimatedPath(path, Time(1.0));
		var state = ap.seek(0.5);
		Assert.floatEquals(0.0, state.angle);
	}

	@Test
	public function testAngleOnVerticalPath():Void {
		var path = createVerticalPath(); // (0,0) to (0,200), angle = PI/2
		var ap = new AnimatedPath(path, Time(1.0));
		var state = ap.seek(0.5);
		// atan2(200, 0) = PI/2
		Assert.floatEquals(Math.PI / 2, state.angle);
	}

	@Test
	public function testCycleCountInitiallyZero():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		var state = ap.update(0.5);
		Assert.equals(0, state.cycle);
	}

	// ==================== onUpdate callback ====================

	@Test
	public function testOnUpdateCallback():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		var updateCount = 0;
		ap.onUpdate = function(state) {
			updateCount++;
		};
		ap.update(0.5);
		Assert.isTrue(updateCount > 0);
	}

	// ==================== After done, update is no-op ====================

	@Test
	public function testUpdateAfterDoneIsNoop():Void {
		var path = createLinePath();
		var ap = new AnimatedPath(path, Time(1.0));
		ap.update(1.0); // complete
		var state = ap.getState();
		Assert.isTrue(state.done);

		// Further updates should not change state
		var state2 = ap.update(0.5);
		Assert.isTrue(state2.done);
		Assert.floatEquals(100.0, state2.position.x);
	}

	// ==================== Builder Integration ====================

	static final AP_MANIM = "
		paths { #testLine path { lineTo(100, 0) } }
		#testAP animatedPath {
			path: testLine
			type: time
			duration: 1.0
		}
	";

	static final AP_LOOP_MANIM = "
		paths { #loopLine path { lineTo(100, 0) } }
		#loopAP animatedPath {
			path: loopLine
			type: time
			duration: 1.0
			loop: true
		}
	";

	static final AP_EASED_MANIM = "
		paths { #easedLine path { lineTo(100, 0) } }
		#easedAP animatedPath {
			path: easedLine
			type: time
			duration: 1.0
			easing: easeOutCubic
		}
	";

	static final AP_EVENT_MANIM = "
		paths { #evLine path { lineTo(100, 0) } }
		#evAP animatedPath {
			path: evLine
			type: time
			duration: 1.0
			0.5: event(\"halfway\")
		}
	";

	@Test
	public function testBuilderCreateAnimatedPath():Void {
		var builder = BuilderTestBase.builderFromSource(AP_MANIM);
		var ap = builder.createAnimatedPath("testAP");
		Assert.notNull(ap);
	}

	@Test
	public function testBuilderAnimPathDuration():Void {
		var builder = BuilderTestBase.builderFromSource(AP_MANIM);
		var ap = builder.createAnimatedPath("testAP");
		var state = ap.update(1.0);
		Assert.isTrue(state.done);
	}

	@Test
	public function testBuilderAnimPathLoop():Void {
		var builder = BuilderTestBase.builderFromSource(AP_LOOP_MANIM);
		var ap = builder.createAnimatedPath("loopAP");
		var state = ap.update(1.5);
		Assert.isFalse(state.done);
		Assert.isTrue(state.cycle > 0);
	}

	@Test
	public function testBuilderCreateProjectilePath():Void {
		var builder = BuilderTestBase.builderFromSource(AP_MANIM);
		var start = new FPoint(10, 20);
		var end = new FPoint(200, 50);
		var ap = builder.createProjectilePath("testAP", start, end);
		Assert.notNull(ap);
		if (ap == null) return;
		var state = ap.seek(0.0);
		// Start position should be near the start point
		Assert.isTrue(Math.abs(state.position.x - 10.0) < 5.0);
		Assert.isTrue(Math.abs(state.position.y - 20.0) < 5.0);
	}

	@Test
	public function testBuilderProjectilePathEndpoint():Void {
		var builder = BuilderTestBase.builderFromSource(AP_MANIM);
		var start = new FPoint(0, 0);
		var end = new FPoint(200, 100);
		var ap = builder.createProjectilePath("testAP", start, end);
		var state = ap.seek(1.0);
		Assert.isTrue(Math.abs(state.position.x - 200.0) < 5.0);
		Assert.isTrue(Math.abs(state.position.y - 100.0) < 5.0);
	}

	@Test
	public function testBuilderAnimPathEasing():Void {
		var builder = BuilderTestBase.builderFromSource(AP_EASED_MANIM);
		var ap = builder.createAnimatedPath("easedAP");
		// Easing applies via update(), not seek(). easeOutCubic at t=0.5 > 0.5
		var state = ap.update(0.5);
		Assert.isTrue(state.position.x > 55.0);
	}

	@Test
	public function testBuilderAnimPathEvents():Void {
		var builder = BuilderTestBase.builderFromSource(AP_EVENT_MANIM);
		var ap = builder.createAnimatedPath("evAP");
		var firedEvents:Array<String> = [];
		ap.onEvent = function(name, state) {
			firedEvents.push(name);
		};
		ap.update(0.6); // past 0.5
		Assert.isTrue(firedEvents.indexOf("halfway") >= 0);
	}

	@Test
	public function testGetClosestRateAtStart():Void {
		var path = createLinePath(); // (0,0) to (100,0)
		var rate = path.getClosestRate(new FPoint(0, 0));
		Assert.isTrue(rate < 0.05);
	}

	@Test
	public function testGetClosestRateAtEnd():Void {
		var path = createLinePath(); // (0,0) to (100,0)
		var rate = path.getClosestRate(new FPoint(100, 0));
		Assert.isTrue(rate > 0.95);
	}

	@Test
	public function testGetClosestRateAtMid():Void {
		var path = createLinePath(); // (0,0) to (100,0)
		var rate = path.getClosestRate(new FPoint(50, 0));
		Assert.isTrue(Math.abs(rate - 0.5) < 0.05);
	}
}
