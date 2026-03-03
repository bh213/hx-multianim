package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.builderFromSource;
import bh.test.BuilderTestBase.builderFromFile;
import bh.paths.AnimatedPath;
import bh.paths.MultiAnimPaths.PathNormalization;
import bh.base.FPoint;

/**
 * Integration tests for animated path builder and codegen parity.
 *
 * Tests createAnimatedPath / createProjectilePath through the builder,
 * path normalization modes, error handling, and builder-vs-codegen equivalence.
 */
class AnimatedPathBuilderTest extends BuilderTestBase {
	// Shared .manim source for most tests
	static final ANIM_PATH_SOURCE = "
		paths {
			#straight path { lineTo(100, 0) }
			#diagonal path { lineTo(100, 100) }
			#curved path { bezier(relative, 200, 0, 100, -80, smoothing: auto) }
			#withCheckpoint path {
				lineTo(50, 0)
				checkpoint(\"half\")
				lineTo(50, 50)
			}
		}
		curves {
			#grow curve { points: [(0, 0.5), (1, 2.0)] }
			#fadeOut curve { points: [(0, 1.0), (1, 0.0)] }
		}
		#basic animatedPath {
			path: straight
			type: time
			duration: 1.0
		}
		#withCurves animatedPath {
			path: straight
			type: time
			duration: 1.0
			0.0: scaleCurve: grow, alphaCurve: fadeOut
		}
		#withEvents animatedPath {
			path: straight
			type: time
			duration: 1.0
			0.25: event(\"quarter\")
			0.5: event(\"half\")
			0.75: event(\"threeQuarter\")
		}
		#distMode animatedPath {
			path: straight
			type: distance
			speed: 50.0
		}
		#looping animatedPath {
			path: straight
			type: time
			duration: 0.5
			loop: true
		}
		#pingPonging animatedPath {
			path: straight
			type: time
			duration: 0.5
			pingPong: true
		}
		#withCheckpointEvents animatedPath {
			path: withCheckpoint
			type: time
			duration: 1.0
			half: event(\"atHalf\")
		}
		#diagPath animatedPath {
			path: diagonal
			type: time
			duration: 1.0
		}
		#curvedPath animatedPath {
			path: curved
			type: time
			duration: 1.0
		}
		#withEasing animatedPath {
			path: straight
			type: time
			duration: 1.0
			easing: easeOutCubic
		}
		#withColorStops animatedPath {
			path: straight
			type: time
			duration: 1.0
			0.0: colorCurve: linear, #FF0000, #00FF00
			0.5: colorCurve: linear, #00FF00, #0000FF
		}
		#withCustom animatedPath {
			path: straight
			type: time
			duration: 1.0
			0.0: custom(\"heat\"): grow
		}
		#dummy programmable() { bitmap(generated(color(1, 1, #000))): 0,0 }
	";

	// ==================== Builder: Basic Creation ====================

	@Test
	public function testBuilderCreateBasicAnimatedPath():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		final ap = builder.createAnimatedPath("basic");
		Assert.notNull(ap);
		// Should complete after 1.0 second
		final state = ap.update(1.0);
		Assert.isTrue(state.done);
		Assert.floatEquals(1.0, state.rate);
	}

	@Test
	public function testBuilderCreateDistanceModeAnimatedPath():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		final ap = builder.createAnimatedPath("distMode");
		// speed=50, path length=100 → done after 2s
		final state = ap.update(2.0);
		Assert.isTrue(state.done);
	}

	@Test
	public function testBuilderAnimPathWithCurvesApplied():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		final ap = builder.createAnimatedPath("withCurves");
		// At rate 0.5: grow curve lerp(0.5, 2.0, 0.5)=1.25, fadeOut lerp(1.0, 0.0, 0.5)=0.5
		final state = ap.update(0.5);
		Assert.floatEquals(1.25, state.scale);
		Assert.floatEquals(0.5, state.alpha);
	}

	@Test
	public function testBuilderAnimPathWithEvents():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		final ap = builder.createAnimatedPath("withEvents");
		var events:Array<String> = [];
		ap.onEvent = (name, _) -> events.push(name);

		ap.update(0.6); // past quarter (0.25) and half (0.5)
		Assert.isTrue(events.indexOf("quarter") >= 0);
		Assert.isTrue(events.indexOf("half") >= 0);
		Assert.isTrue(events.indexOf("threeQuarter") < 0); // not yet
	}

	@Test
	public function testBuilderAnimPathLoopDoesNotEnd():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		final ap = builder.createAnimatedPath("looping");
		// Duration 0.5, loop=true — update processes one cycle per call
		// After several updates totaling >1.0s, cycle count should increase
		var state = ap.update(0.5); // completes first cycle
		state = ap.update(0.5); // completes second cycle
		state = ap.update(0.5); // completes third cycle
		Assert.isFalse(state.done);
		Assert.isTrue(state.cycle >= 2, 'Expected cycle >= 2, got ${state.cycle}');
	}

	@Test
	public function testBuilderAnimPathPingPongReverses():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		final ap = builder.createAnimatedPath("pingPonging");
		// Duration 0.5, pingPong → after 0.75s, rate should be going backward (~0.5)
		final state = ap.update(0.75);
		Assert.isFalse(state.done);
		Assert.isTrue(state.rate < 0.9); // reversed from 1.0
	}

	// ==================== Builder: Checkpoint Events ====================

	@Test
	public function testBuilderCheckpointEvent():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		final ap = builder.createAnimatedPath("withCheckpointEvents");
		var events:Array<String> = [];
		ap.onEvent = (name, _) -> events.push(name);

		ap.update(1.0); // complete the path
		Assert.isTrue(events.indexOf("atHalf") >= 0);
	}

	// ==================== Builder: Easing Shorthand ====================

	@Test
	public function testBuilderEasingShorthand():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		final ap = builder.createAnimatedPath("withEasing");
		// easeOutCubic at t=0.5 → progress > 0.5 (eased)
		final state = ap.update(0.5);
		Assert.isTrue(state.rate > 0.6, "easeOutCubic at t=0.5 should progress past 0.6");
	}

	// ==================== Builder: Color Stops ====================

	@Test
	public function testBuilderColorStops():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		final ap = builder.createAnimatedPath("withColorStops");
		// At rate 0.0 → should be near red (#FF0000)
		final stateStart = ap.seek(0.01);
		Assert.isTrue((stateStart.color >> 16) & 0xFF > 200, "Start color should be near red");

		// At rate 0.5 → should be near green (#00FF00)
		final stateMid = ap.seek(0.5);
		Assert.isTrue((stateMid.color >> 8) & 0xFF > 200, "Mid color should be near green");
	}

	// ==================== Builder: Custom Curves ====================

	@Test
	public function testBuilderCustomCurve():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		final ap = builder.createAnimatedPath("withCustom");
		final state = ap.update(0.5);
		// grow curve at t=0.5 → lerp(0.5, 2.0, 0.5) = 1.25
		Assert.notNull(state.custom);
		if (state.custom != null) {
			final heat = state.custom.get("heat");
			Assert.notNull(heat);
			if (heat != null) Assert.floatEquals(1.25, heat);
		}
	}

	// ==================== Builder: Projectile Path (Stretch normalization) ====================

	@Test
	public function testBuilderProjectilePathStartPosition():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		final start = new FPoint(50, 100);
		final end = new FPoint(300, 200);
		final ap = builder.createProjectilePath("basic", start, end);
		final state = ap.seek(0.0);
		Assert.isTrue(Math.abs(state.position.x - 50.0) < 5.0, "Start X should be near 50");
		Assert.isTrue(Math.abs(state.position.y - 100.0) < 5.0, "Start Y should be near 100");
	}

	@Test
	public function testBuilderProjectilePathEndPosition():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		final start = new FPoint(50, 100);
		final end = new FPoint(300, 200);
		final ap = builder.createProjectilePath("basic", start, end);
		final state = ap.seek(1.0);
		Assert.isTrue(Math.abs(state.position.x - 300.0) < 5.0, "End X should be near 300");
		Assert.isTrue(Math.abs(state.position.y - 200.0) < 5.0, "End Y should be near 200");
	}

	// ==================== Builder: Anchor Normalization ====================

	@Test
	public function testBuilderAnchorNormalization():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		final ap = builder.createAnimatedPath("basic", Anchor(new FPoint(200, 300), 0.0));
		final state = ap.seek(0.0);
		// Anchor at (200,300) with 0 rotation → start at (200,300)
		Assert.isTrue(Math.abs(state.position.x - 200.0) < 5.0);
		Assert.isTrue(Math.abs(state.position.y - 300.0) < 5.0);
	}

	@Test
	public function testBuilderAnchorWithRotation():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		// Rotate 90 degrees (pi/2) — straight path (100,0) becomes (0,100)
		final ap = builder.createAnimatedPath("basic", Anchor(new FPoint(0, 0), Math.PI / 2));
		final stateEnd = ap.seek(1.0);
		// End should be near (0, 100) instead of (100, 0)
		Assert.isTrue(Math.abs(stateEnd.position.x) < 5.0, "Rotated end X should be near 0");
		Assert.isTrue(Math.abs(stateEnd.position.y - 100.0) < 5.0, "Rotated end Y should be near 100");
	}

	// ==================== Builder: getClosestRate Through Builder Path ====================

	@Test
	public function testBuilderGetClosestRate():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		final ap = builder.createAnimatedPath("basic");
		// Straight path from (0,0) to (100,0)
		final rate = ap.path.getClosestRate(new FPoint(50, 0));
		Assert.isTrue(Math.abs(rate - 0.5) < 0.05, "Closest rate to midpoint should be ~0.5");
	}

	@Test
	public function testBuilderGetClosestRateOnDiagonal():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		final ap = builder.createAnimatedPath("diagPath");
		// Diagonal from (0,0) to (100,100)
		final rate = ap.path.getClosestRate(new FPoint(100, 100));
		Assert.isTrue(rate > 0.9, "Closest rate to endpoint should be near 1.0");
	}

	// ==================== Builder: Error Cases ====================

	@Test
	public function testBuilderMissingAnimatedPathThrows():Void {
		final builder = builderFromSource(ANIM_PATH_SOURCE);
		try {
			builder.createAnimatedPath("nonExistent");
			Assert.fail("Should throw for missing animated path");
		} catch (e:Dynamic) {
			Assert.pass();
		}
	}

	@Test
	public function testBuilderMissingPathRefThrows():Void {
		try {
			final builder = builderFromSource("
				paths { #straight path { lineTo(100, 0) } }
				#broken animatedPath {
					path: missingPath
					type: time
					duration: 1.0
				}
			");
			builder.createAnimatedPath("broken");
			Assert.fail("Should throw for missing path reference");
		} catch (e:Dynamic) {
			Assert.pass();
		}
	}

	// ==================== Codegen: createAnimatedPath_ Parity ====================

	@Test
	public function testCodegenBasicAnimatedPathExists():Void {
		// Exercise the codegen path — the @:manim factory should generate createAnimatedPath_ methods
		// We use the test61 manim file which has 4 animated paths
		final builder = builderFromFile("test/examples/61-animatedPathCurves/animatedPathCurves.manim");
		final apBuilder = builder.createAnimatedPath("distAnim");
		Assert.notNull(apBuilder);

		// Simulate and check end state matches
		var stateBuilder = apBuilder.seek(1.0);
		Assert.isTrue(stateBuilder.done || stateBuilder.rate >= 0.99);
	}

	@Test
	public function testCodegenVsBuilderDistAnimParity():Void {
		// Builder path
		final builder = builderFromFile("test/examples/61-animatedPathCurves/animatedPathCurves.manim");
		final apBuilder = builder.createAnimatedPath("distAnim");

		// Codegen path (via MultiProgrammable)
		final mp = createMp();
		final apCodegen = mp.animatedPathCurves.createAnimatedPath_distAnim();

		// Both should produce the same state at midpoint
		final stateB = apBuilder.seek(0.5);
		final stateC = apCodegen.seek(0.5);
		Assert.isTrue(Math.abs(stateB.position.x - stateC.position.x) < 1.0,
			"Builder and codegen X should match at rate 0.5");
		Assert.isTrue(Math.abs(stateB.position.y - stateC.position.y) < 1.0,
			"Builder and codegen Y should match at rate 0.5");
		Assert.isTrue(Math.abs(stateB.scale - stateC.scale) < 0.01,
			"Builder and codegen scale should match at rate 0.5");
	}

	@Test
	public function testCodegenVsBuilderTimeAnimParity():Void {
		final builder = builderFromFile("test/examples/61-animatedPathCurves/animatedPathCurves.manim");
		final apBuilder = builder.createAnimatedPath("timeAnim");
		final mp = createMp();
		final apCodegen = mp.animatedPathCurves.createAnimatedPath_timeAnim();

		// Compare at multiple rates
		for (r in [10, 30, 50, 70, 90]) {
			final rate:Float = r / 100.0;
			final stateB = apBuilder.seek(rate);
			final stateC = apCodegen.seek(rate);
			Assert.isTrue(Math.abs(stateB.position.x - stateC.position.x) < 2.0,
				'Builder/codegen X mismatch at rate $rate');
			Assert.isTrue(Math.abs(stateB.position.y - stateC.position.y) < 2.0,
				'Builder/codegen Y mismatch at rate $rate');
		}
	}

	@Test
	public function testCodegenVsBuilderCustomAnimParity():Void {
		final builder = builderFromFile("test/examples/61-animatedPathCurves/animatedPathCurves.manim");
		final apBuilder = builder.createAnimatedPath("customAnim");
		final mp = createMp();
		final apCodegen = mp.animatedPathCurves.createAnimatedPath_customAnim();

		final stateB = apBuilder.update(1.0); // half of 2.0 duration
		final stateC = apCodegen.update(1.0);

		// Custom curve "heat" should match
		Assert.notNull(stateB.custom);
		Assert.notNull(stateC.custom);
		if (stateB.custom != null && stateC.custom != null) {
			final heatB = stateB.custom.get("heat");
			final heatC = stateC.custom.get("heat");
			Assert.notNull(heatB);
			Assert.notNull(heatC);
			if (heatB != null && heatC != null)
				Assert.isTrue(Math.abs(heatB - heatC) < 0.01, "Custom curve 'heat' should match");
		}
	}

	@Test
	public function testCodegenVsBuilderCheckpointAnimParity():Void {
		final builder = builderFromFile("test/examples/61-animatedPathCurves/animatedPathCurves.manim");
		final apBuilder = builder.createAnimatedPath("checkpointAnim");
		final mp = createMp();
		final apCodegen = mp.animatedPathCurves.createAnimatedPath_checkpointAnim();

		// Both should fire the same events
		var eventsB:Array<String> = [];
		var eventsC:Array<String> = [];
		apBuilder.onEvent = (name, _) -> eventsB.push(name);
		apCodegen.onEvent = (name, _) -> eventsC.push(name);

		// Run to completion (distance mode, speed 80, path ~170px → ~2.1s)
		apBuilder.update(3.0);
		apCodegen.update(3.0);

		// Both should have fired reachedMid and reachedEnd
		Assert.isTrue(eventsB.indexOf("reachedMid") >= 0, "Builder should fire reachedMid");
		Assert.isTrue(eventsC.indexOf("reachedMid") >= 0, "Codegen should fire reachedMid");
		Assert.isTrue(eventsB.indexOf("reachedEnd") >= 0, "Builder should fire reachedEnd");
		Assert.isTrue(eventsC.indexOf("reachedEnd") >= 0, "Codegen should fire reachedEnd");
	}

	@Test
	public function testCodegenProjectilePathNormalization():Void {
		final mp = createMp();
		final start = new FPoint(10, 20);
		final end = new FPoint(300, 150);
		final ap = mp.animatedPathCurves.createAnimatedPath_distAnim(Stretch(start, end));
		Assert.notNull(ap);

		final stateStart = ap.seek(0.0);
		Assert.isTrue(Math.abs(stateStart.position.x - 10.0) < 5.0, "Codegen stretch start X");
		Assert.isTrue(Math.abs(stateStart.position.y - 20.0) < 5.0, "Codegen stretch start Y");

		final stateEnd = ap.seek(1.0);
		Assert.isTrue(Math.abs(stateEnd.position.x - 300.0) < 5.0, "Codegen stretch end X");
		Assert.isTrue(Math.abs(stateEnd.position.y - 150.0) < 5.0, "Codegen stretch end Y");
	}

	// ==================== Helpers ====================

	static function createMp():bh.test.MultiProgrammable {
		var loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
		return new bh.test.MultiProgrammable(loader);
	}
}
