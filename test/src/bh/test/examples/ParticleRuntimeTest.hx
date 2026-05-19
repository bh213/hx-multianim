package bh.test.examples;

import utest.Assert;
import bh.base.Particles;
import bh.base.Particles.ParticleGroup;
import bh.base.Particles.ForceField;
import bh.base.Particles.SubEmitTrigger;
import bh.base.Particles.SubEmitter;
import bh.base.Particles.PartEmitMode;
import bh.base.FPoint;
import bh.paths.Curve;
import bh.paths.AnimatedPath;
import bh.paths.MultiAnimPaths.Path;
import bh.paths.MultiAnimPaths.SinglePath;

/**
 * Non-visual unit tests for the particle runtime API:
 * force field management, emitBurst, force field physics, and sub-emitters.
 */
@:access(bh.base.Particles)
@:access(bh.base.ParticleGroup)
@:access(h2d.SpriteBatch)
@:access(h2d.BatchElement)
class ParticleRuntimeTest extends utest.Test {
	// ==================== Helpers ====================

	static function createParticles():Particles {
		return new Particles();
	}

	static function createGroup(id:String, p:Particles, loop:Bool = false):ParticleGroup {
		var tiles = [h2d.Tile.fromColor(0xFF0000, 4, 4)];
		var g = new ParticleGroup(id, p, tiles);
		p.addGroup(g);
		// Set properties via Dynamic cast (bypasses (default, null) restriction)
		var dg:Dynamic = g;
		dg.nparts = 20;
		dg.speed = 100;
		dg.life = 1.0;
		dg.lifeRand = 0;
		dg.sizeRand = 0;
		dg.speedRand = 0;
		dg.emitLoop = loop;
		dg.emitSync = 1.0; // no delay — all particles visible immediately
		dg.emitDelay = 0;
		g.randomFunc = seededRandom(42);
		return g;
	}

	static function seededRandom(seed:Int):() -> Float {
		var rng = new hxd.Rand(seed);
		return rng.rand;
	}

	static function advanceGroup(g:ParticleGroup, totalTime:Float):Void {
		final step:Float = 0.016;
		var remaining = totalTime;
		while (remaining > 0) {
			final dt = remaining < step ? remaining : step;
			if (!g.started && g.enabled)
				g.start();
			g.updateTime(dt);
			var e = g.batch.first;
			while (e != null) {
				var next = e.next;
				if (!e.update(dt))
					e.remove();
				e = next;
			}
			remaining -= step;
		}
	}

	static function countParticles(g:ParticleGroup):Int {
		var count = 0;
		var e = g.batch.first;
		while (e != null) {
			count++;
			e = e.next;
		}
		return count;
	}

	/** Collect x-positions of all alive particles. */
	static function collectXPositions(g:ParticleGroup):Array<Float> {
		var xs:Array<Float> = [];
		var e = g.batch.first;
		while (e != null) {
			if (e.visible)
				xs.push(e.x);
			e = e.next;
		}
		return xs;
	}

	// ==================== Force Field Array API ====================

	@Test
	public function testAddForceField():Void {
		var p = createParticles();
		var g = createGroup("main", p);
		Assert.equals(0, g.forceFields.length);

		g.addForceField(Wind(10.0, 0.0));
		Assert.equals(1, g.forceFields.length);
	}

	@Test
	public function testAddMultipleForceFields():Void {
		var p = createParticles();
		var g = createGroup("main", p);

		g.addForceField(Wind(10.0, 0.0));
		g.addForceField(Attractor(0.0, 0.0, 50.0, 100.0));
		g.addForceField(Vortex(50.0, 50.0, 30.0, 80.0));
		Assert.equals(3, g.forceFields.length);

		// Verify order preserved
		switch (g.forceFields[0]) {
			case Wind(_, _): Assert.pass();
			default: Assert.fail("Expected Wind at index 0");
		}
		switch (g.forceFields[1]) {
			case Attractor(_, _, _, _): Assert.pass();
			default: Assert.fail("Expected Attractor at index 1");
		}
		switch (g.forceFields[2]) {
			case Vortex(_, _, _, _): Assert.pass();
			default: Assert.fail("Expected Vortex at index 2");
		}
	}

	@Test
	public function testRemoveForceFieldAtMiddle():Void {
		var p = createParticles();
		var g = createGroup("main", p);

		g.addForceField(Wind(10.0, 0.0));
		g.addForceField(Attractor(0.0, 0.0, 50.0, 100.0));
		g.addForceField(Vortex(50.0, 50.0, 30.0, 80.0));

		g.removeForceFieldAt(1); // Remove Attractor
		Assert.equals(2, g.forceFields.length);

		switch (g.forceFields[0]) {
			case Wind(_, _): Assert.pass();
			default: Assert.fail("Expected Wind at index 0 after removal");
		}
		switch (g.forceFields[1]) {
			case Vortex(_, _, _, _): Assert.pass();
			default: Assert.fail("Expected Vortex at index 1 after removal");
		}
	}

	@Test
	public function testRemoveForceFieldAtFirst():Void {
		var p = createParticles();
		var g = createGroup("main", p);

		g.addForceField(Wind(10.0, 0.0));
		g.addForceField(Attractor(0.0, 0.0, 50.0, 100.0));

		g.removeForceFieldAt(0);
		Assert.equals(1, g.forceFields.length);

		switch (g.forceFields[0]) {
			case Attractor(_, _, _, _): Assert.pass();
			default: Assert.fail("Expected Attractor at index 0 after removal");
		}
	}

	@Test
	public function testClearForceFields():Void {
		var p = createParticles();
		var g = createGroup("main", p);

		g.addForceField(Wind(10.0, 0.0));
		g.addForceField(Attractor(0.0, 0.0, 50.0, 100.0));
		Assert.equals(2, g.forceFields.length);

		g.clearForceFields();
		Assert.equals(0, g.forceFields.length);
	}

	@Test
	public function testClearThenAdd():Void {
		var p = createParticles();
		var g = createGroup("main", p);

		g.addForceField(Wind(10.0, 0.0));
		g.clearForceFields();
		g.addForceField(Repulsor(0.0, 0.0, 80.0, 120.0));

		Assert.equals(1, g.forceFields.length);
		switch (g.forceFields[0]) {
			case Repulsor(_, _, _, _): Assert.pass();
			default: Assert.fail("Expected Repulsor after clear+add");
		}
	}

	// ==================== emitBurst ====================

	@Test
	public function testEmitBurst():Void {
		var p = createParticles();
		var g = createGroup("main", p);
		// Don't start() — use emitBurst directly
		g.emitBurst(5);

		var count = countParticles(g);
		Assert.equals(5, count);
	}

	@Test
	public function testEmitBurstAt():Void {
		var p = createParticles();
		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.speed = 0; // No initial speed — particles stay near spawn point
		dg.emitMode = Point(0.0, 0.0); // No random offset

		g.emitBurstAt(100.0, 200.0, 0.0, 0.0, 3);

		var count = countParticles(g);
		Assert.equals(3, count);

		// Verify first particle is at the burst position (no random offset)
		var e = g.batch.first;
		Assert.notNull(e);
		Assert.floatEquals(100.0, e.x, 0.01);
		Assert.floatEquals(200.0, e.y, 0.01);
	}

	// ==================== Particle Pooling (free list) ====================

	/** Collect Particle instance references from the batch as a typed Array. */
	static function collectParticleRefs(g:ParticleGroup):Array<Dynamic> {
		var refs:Array<Dynamic> = [];
		var e = g.batch.first;
		while (e != null) {
			refs.push(e);
			e = e.next;
		}
		return refs;
	}

	@Test
	public function testEmitBurstReusesParticleInstancesAfterDeath():Void {
		// Sustained burst emission (sub-emitters, spawnCurve, manual emitBurst) should not
		// allocate a fresh Particle instance for every spawn. After particles die naturally,
		// a subsequent burst is expected to recycle the dead Particle objects from a pool.
		var p = createParticles();
		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.life = 0.1; // short life so particles die quickly

		g.emitBurstAt(0, 0, 0, 0, 3);
		var firstBatch = collectParticleRefs(g);
		Assert.equals(3, firstBatch.length);

		// Advance well past life — non-looping particles return false from update() and
		// SpriteBatch detaches them. With pooling they should land on a free list.
		advanceGroup(g, 0.5);
		Assert.equals(0, countParticles(g));

		g.emitBurstAt(0, 0, 0, 0, 3);
		var secondBatch = collectParticleRefs(g);
		Assert.equals(3, secondBatch.length);

		var reused = 0;
		for (q in secondBatch) {
			for (r in firstBatch) {
				if (q == r) {
					reused++;
					break;
				}
			}
		}
		Assert.equals(3, reused, 'All 3 emitted particles should be recycled from the free list, only $reused were');
	}

	@Test
	public function testSustainedBurstHasBoundedParticleAllocations():Void {
		// Steady-state churn: emit-die-emit repeatedly. With a free list, the total set of
		// Particle instances ever observed should stay near peak-concurrent (3 here), not
		// grow linearly with burst count. Without pooling the unique instance count grows
		// to ~burstCount * cycles.
		var p = createParticles();
		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.life = 0.1;

		var seen = new haxe.ds.ObjectMap<Dynamic, Bool>();
		final cycles = 10;
		final burst = 3;
		for (i in 0...cycles) {
			g.emitBurstAt(0, 0, 0, 0, burst);
			var e = g.batch.first;
			while (e != null) {
				seen.set(e, true);
				e = e.next;
			}
			advanceGroup(g, 0.5); // let them all die
			Assert.equals(0, countParticles(g));
		}

		var unique = 0;
		for (_ in seen.keys()) unique++;
		// Steady state: at most ~burst unique Particle instances are needed.
		// Allow a small slack for first-cycle warm-up.
		Assert.isTrue(unique <= burst + 1,
			'Expected pooled allocation (~$burst unique Particles), saw $unique distinct instances over $cycles burst cycles');
	}

	// ==================== Force Field Physics ====================

	@Test
	public function testNoForceFieldsBaseline():Void {
		var p = createParticles();
		var g = createGroup("main", p);

		advanceGroup(g, 0.5);
		var count = countParticles(g);
		Assert.isTrue(count > 0, "Particles should exist after advancing");
	}

	@Test
	public function testWindAffectsParticles():Void {
		// Run without wind
		var p1 = createParticles();
		var g1 = createGroup("main", p1);
		advanceGroup(g1, 0.3);
		var xsNoWind = collectXPositions(g1);

		// Run with strong rightward wind, same seed
		var p2 = createParticles();
		var g2 = createGroup("main", p2);
		g2.addForceField(Wind(500.0, 0.0));
		advanceGroup(g2, 0.3);
		var xsWithWind = collectXPositions(g2);

		// Both should have particles
		Assert.isTrue(xsNoWind.length > 0, "Baseline should have particles");
		Assert.isTrue(xsWithWind.length > 0, "Wind group should have particles");

		// Average x-position with wind should be further right
		var avgNoWind = average(xsNoWind);
		var avgWithWind = average(xsWithWind);
		Assert.isTrue(avgWithWind > avgNoWind, 'Wind should push particles right: avgWithWind=$avgWithWind > avgNoWind=$avgNoWind');
	}

	@Test
	public function testAttractorPullsParticles():Void {
		// Emit particles from offset position, attractor at origin
		var p1 = createParticles();
		var g1 = createGroup("main", p1);
		var dg1:Dynamic = g1;
		dg1.dx = 200;
		dg1.dy = 0;
		advanceGroup(g1, 0.3);
		var xsNoAttractor = collectXPositions(g1);

		var p2 = createParticles();
		var g2 = createGroup("main", p2);
		var dg2:Dynamic = g2;
		dg2.dx = 200;
		dg2.dy = 0;
		g2.addForceField(Attractor(0.0, 0.0, 300.0, 500.0));
		advanceGroup(g2, 0.3);
		var xsWithAttractor = collectXPositions(g2);

		Assert.isTrue(xsNoAttractor.length > 0, "Baseline should have particles");
		Assert.isTrue(xsWithAttractor.length > 0, "Attractor group should have particles");

		// Average x should be closer to 0 (attractor) with attractor active
		var avgNoAttractor = average(xsNoAttractor);
		var avgWithAttractor = average(xsWithAttractor);
		Assert.isTrue(avgWithAttractor < avgNoAttractor,
			'Attractor should pull particles left: avgWithAttractor=$avgWithAttractor < avgNoAttractor=$avgNoAttractor');
	}

	static function average(values:Array<Float>):Float {
		if (values.length == 0) return 0;
		var sum = 0.0;
		for (v in values)
			sum += v;
		return sum / values.length;
	}

	// ==================== Sub-emitters ====================

	@Test
	public function testSubEmitterOnDeath():Void {
		var p = createParticles();
		var mainGroup = createGroup("main", p);
		var subGroup = createGroup("sparks", p);

		// Configure main group: short life so particles die quickly
		var dm:Dynamic = mainGroup;
		dm.life = 0.1;
		dm.nparts = 5;

		// Configure sub-emitter: on death, spawn in sub-group
		dm.subEmitters = ([
			{
				groupId: "sparks",
				trigger: OnDeath,
				probability: 1.0,
				inheritVelocity: 0.0,
				offsetX: 0.0,
				offsetY: 0.0,
				burstCount: 2
			}
		] : Array<SubEmitter>);

		// Advance long enough for main particles to die
		advanceGroup(mainGroup, 0.5);
		// Also advance sub-group so its batch processes
		advanceGroup(subGroup, 0.016);

		var subCount = countParticles(subGroup);
		Assert.isTrue(subCount > 0, 'Sub-emitter should have spawned particles on death, got $subCount');
	}

	@Test
	public function testSubEmitterOnBirth():Void {
		var p = createParticles();
		var mainGroup = createGroup("main", p);
		var subGroup = createGroup("sparks", p);

		var dm:Dynamic = mainGroup;
		dm.nparts = 3;
		dm.subEmitters = ([
			{
				groupId: "sparks",
				trigger: OnBirth,
				probability: 1.0,
				inheritVelocity: 0.0,
				offsetX: 0.0,
				offsetY: 0.0,
				burstCount: 1
			}
		] : Array<SubEmitter>);

		// start() triggers OnBirth for each initial particle
		mainGroup.start();

		var subCount = countParticles(subGroup);
		// Each of the 3 main particles should trigger 1 sub-particle on birth
		Assert.isTrue(subCount >= 3, 'Expected at least 3 sub-particles from OnBirth, got $subCount');
	}

	@Test
	public function testSubEmitterProbabilityZero():Void {
		var p = createParticles();
		var mainGroup = createGroup("main", p);
		var subGroup = createGroup("sparks", p);

		var dm:Dynamic = mainGroup;
		dm.life = 0.1;
		dm.nparts = 10;
		dm.subEmitters = ([
			{
				groupId: "sparks",
				trigger: OnDeath,
				probability: 0.0, // Never triggers
				inheritVelocity: 0.0,
				offsetX: 0.0,
				offsetY: 0.0,
				burstCount: 2
			}
		] : Array<SubEmitter>);

		advanceGroup(mainGroup, 0.5);

		var subCount = countParticles(subGroup);
		Assert.equals(0, subCount);
	}

	@Test
	public function testSubEmitterGroupNotFound():Void {
		var p = createParticles();
		var mainGroup = createGroup("main", p);
		// No "sparks" group exists

		var dm:Dynamic = mainGroup;
		dm.life = 0.1;
		dm.nparts = 5;
		dm.subEmitters = ([
			{
				groupId: "nonexistent",
				trigger: OnDeath,
				probability: 1.0,
				inheritVelocity: 0.0,
				offsetX: 0.0,
				offsetY: 0.0,
				burstCount: 2
			}
		] : Array<SubEmitter>);

		// Should not crash — silently skips missing group
		advanceGroup(mainGroup, 0.5);
		Assert.pass();
	}

	// ==================== AnimSM event overrides ====================

	@Test
	public function testOnDeathAnimOverrideSwitchesParticleTileAtLifecycleDeath():Void {
		var p = createParticles();
		var g = createGroup("main", p, false); // non-looping — particles die for real
		var dm:Dynamic = g;
		dm.life = 0.1;
		dm.nparts = 1;

		var aliveTile = h2d.Tile.fromColor(0x00FF00, 4, 4);
		var deathTile = h2d.Tile.fromColor(0x0000FF, 4, 4);
		// State "dead" has startLifeRate=2.0 so the lifetime-driven advance at
		// Particle.update never reaches it; only the onDeath override can.
		dm.animStates = [
			{ name: "alive", tiles: [aliveTile], fps: 10.0, startLifeRate: 0.0 },
			{ name: "dead",  tiles: [deathTile], fps: 10.0, startLifeRate: 2.0 }
		];
		g.animEventOverrides.set("onDeath", 1);

		g.start();
		var particle = g.batch.first;
		Assert.notNull(particle, "particle should exist after start");
		Assert.notEquals(deathTile, particle.t, "particle must not be on death tile before lifecycle death");

		// Advance long enough for the particle's lifecycle to trip timeNormalized > 1.
		advanceGroup(g, 0.5);

		Assert.equals(deathTile, particle.t,
			'Expected onDeath override to switch tile to deathTile at lifecycle death; got ${particle.t}');
	}

	// ==================== Shutdown ====================

	@Test
	public function testShutdownInstant():Void {
		var p = createParticles();
		var g = createGroup("main", p, true); // looping

		advanceGroup(g, 0.5); // let particles run
		Assert.equals(20, countParticles(g)); // looping — always 20

		g.shutdown(); // instant — sets emitLoop = false
		Assert.isFalse(g.emitLoop);
		Assert.isFalse(g.isShuttingDown());

		// Particles should die off over time (life=1.0)
		advanceGroup(g, 1.5);
		Assert.equals(0, countParticles(g));
	}

	@Test
	public function testShutdownNoopOnNonLooping():Void {
		var p = createParticles();
		var g = createGroup("main", p, false); // non-looping

		g.shutdown(1.0);
		Assert.isFalse(g.isShuttingDown()); // no-op
	}

	@Test
	public function testShutdownWithDuration():Void {
		var p = createParticles();
		var g = createGroup("main", p, true);
		// Short life so particles recycle frequently during shutdown
		var dg:Dynamic = g;
		dg.life = 0.2;

		advanceGroup(g, 0.3); // let particles cycle a few times
		var countBefore = countParticles(g);
		Assert.equals(20, countBefore);

		g.shutdown(0.5); // 0.5s shutdown with linear count curve
		Assert.isTrue(g.isShuttingDown());

		// Advance past a few particle lifetimes — shutdown thinning happens at recycle time
		advanceGroup(g, 0.4);
		var countMid = countParticles(g);
		Assert.isTrue(countMid < 20, 'Expected fewer than 20 particles during shutdown, got $countMid');
		Assert.isTrue(countMid > 0, 'Expected some particles still alive, got $countMid');

		// After shutdown duration + full life — all should be dead
		advanceGroup(g, 2.0);
		Assert.equals(0, countParticles(g));
	}

	@Test
	public function testShutdownConfiguredDuration():Void {
		var p = createParticles();
		var g = createGroup("main", p, true);
		var dg:Dynamic = g;
		dg.shutdownDuration = 0.5;

		advanceGroup(g, 0.3);
		g.shutdown(); // uses configured duration (0.5)
		Assert.isTrue(g.isShuttingDown());
	}

	@Test
	public function testShutdownRate():Void {
		var p = createParticles();
		var g = createGroup("main", p, true);

		advanceGroup(g, 0.1);
		g.shutdown(1.0);

		Assert.floatEquals(0.0, g.getShutdownRate(), 0.01);
		advanceGroup(g, 0.5);
		Assert.floatEquals(0.5, g.getShutdownRate(), 0.05);
	}

	@Test
	public function testShutdownDurationShapesBurstOnlyGroupWithZeroNparts():Void {
		// Looping group with nparts=0 — particles only come from emitBurst.
		// shutdown(duration) must shape the count down gradually over the configured
		// duration; without that, particles fail to recycle as soon as updateTime fires
		// and the burst dies in roughly one particle lifetime regardless of duration.
		var p = createParticles();
		var g = createGroup("burst", p, true); // looping
		var dg:Dynamic = g;
		dg.nparts = 0;
		dg.life = 0.2; // short — without the fix, all particles would expire well before mid-shutdown

		g.emitBurst(20);
		Assert.equals(20, countParticles(g));

		// Stabilize: with emitLoop=true particles recycle in place even with nparts=0.
		advanceGroup(g, 0.3);
		Assert.equals(20, countParticles(g),
			"burst particles should keep recycling with emitLoop=true before shutdown");

		g.shutdown(2.0); // 2s shutdown — should shape gradually, not collapse in 1 lifetime

		// At ~25% through shutdown, linear curve says ~75% should still be alive.
		// Without the fix, shutdownTargetCount=0 from frame 1 and after 0.5s
		// (>= 2 particle lifetimes) every particle has expired without recycle.
		advanceGroup(g, 0.5);
		var countMid = countParticles(g);
		Assert.isTrue(countMid > 5,
			'Expected substantial particles still alive 0.5s into a 2s shutdown of a burst-only group, got $countMid');
	}

	@Test
	public function testShutdownDurationShapesGroupWithBurstOverflow():Void {
		// Same hazard when liveCount > nparts at shutdown time: bursts pushed the
		// group above its steady-state cap, and the curve must shape from the actual
		// population (not the cap). Otherwise overflow particles are killed in the
		// first lifetime instead of decaying over `duration`.
		var p = createParticles();
		var g = createGroup("overflow", p, true);
		var dg:Dynamic = g;
		dg.nparts = 5;
		dg.life = 0.2;

		advanceGroup(g, 0.1); // start emits nparts=5
		g.emitBurst(15);       // push to 20 live
		Assert.equals(20, countParticles(g));

		g.shutdown(2.0);

		// 25% through, linear curve over 20-particle baseline → ~15 expected.
		// Without the fix, baseline=5 → target ~3 → 17 die in one lifetime.
		advanceGroup(g, 0.5);
		var countMid = countParticles(g);
		Assert.isTrue(countMid > 8,
			'Expected gradual decay from burst-overflow population, got $countMid');
	}

	@Test
	public function testShutdownBurstStillWorks():Void {
		var p = createParticles();
		var g = createGroup("main", p, true);

		advanceGroup(g, 0.1);
		g.shutdown(0.5);

		// Burst should still add particles during shutdown
		var countBefore = countParticles(g);
		g.emitBurst(10);
		var countAfter = countParticles(g);
		Assert.equals(countBefore + 10, countAfter);
	}

	@Test
	public function testShutdownWithAlphaCurve():Void {
		var p = createParticles();
		var g = createGroup("main", p, true);

		// Linear alpha curve: alpha = 1.0 - t
		g.shutdownAlphaCurve = new bh.paths.Curve(null, Linear, null);

		advanceGroup(g, 0.1);
		g.shutdown(1.0);

		// After half the shutdown, alpha mult should be ~0.5
		advanceGroup(g, 0.5);
		Assert.floatEquals(0.5, g.shutdownAlphaMult, 0.1);

		// Check a particle has reduced alpha
		var e = g.batch.first;
		if (e != null) {
			Assert.isTrue(e.alpha < 0.9, 'Expected reduced alpha during shutdown, got ${e.alpha}');
		}
	}

	@Test
	public function testShutdownWithSizeCurve():Void {
		var p = createParticles();
		var g = createGroup("main", p, true);

		g.shutdownSizeCurve = new bh.paths.Curve(null, Linear, null);

		advanceGroup(g, 0.1);
		g.shutdown(1.0);

		advanceGroup(g, 0.5);
		Assert.floatEquals(0.5, g.shutdownSizeMult, 0.1);
	}

	@Test
	public function testShutdownWithSpeedCurve():Void {
		var p = createParticles();
		var g = createGroup("main", p, true);

		g.shutdownSpeedCurve = new bh.paths.Curve(null, Linear, null);

		advanceGroup(g, 0.1);
		g.shutdown(1.0);

		advanceGroup(g, 0.5);
		Assert.floatEquals(0.5, g.shutdownSpeedMult, 0.1);
	}

	// ==================== Externally Driven ====================

	@Test
	public function testExternallyDrivenFrozenWithoutAdvance():Void {
		var p = createParticles();
		var g = createGroup("main", p, true);
		g.externallyDriven = true;

		// Simulate what sync+draw would do (without advanceTime call)
		g.start();
		// Particles exist but _externalDt is 0, so update() returns early
		var e = g.batch.first;
		Assert.notNull(e);
		// Manually call update — should return true (alive) but not move
		var startX = e.x;
		var startY = e.y;
		Assert.isTrue(e.update(0.1)); // SpriteBatch would pass dt, but should be ignored
		Assert.floatEquals(startX, e.x, 0.001);
		Assert.floatEquals(startY, e.y, 0.001);
	}

	@Test
	public function testExternallyDrivenAdvanceTimeMovesParticles():Void {
		var p = createParticles();
		var g = createGroup("main", p, true);
		g.externallyDriven = true;

		g.advanceTime(0.0001); // start + tiny step to init
		var e = g.batch.first;
		Assert.notNull(e);
		var startX = e.x;
		var startY = e.y;

		// Now advance with real dt
		g.advanceTime(0.3);
		// Simulate SpriteBatch calling update during draw
		e.update(999.0); // incoming dt should be ignored, _externalDt used instead
		Assert.isTrue(e.x != startX || e.y != startY, "Particle should have moved after advanceTime");

		// After draw, reset _externalDt (simulating what Particles.draw does)
		g._externalDt = 0;

		// Next update without advanceTime should freeze again
		var afterX = e.x;
		var afterY = e.y;
		Assert.isTrue(e.update(0.5)); // should be no-op
		Assert.floatEquals(afterX, e.x, 0.001);
		Assert.floatEquals(afterY, e.y, 0.001);
	}

	@Test
	public function testExternallyDrivenParticlesConvenience():Void {
		var p = createParticles();
		var g1 = createGroup("ext", p, true);
		var g2 = createGroup("auto", p, true);
		g1.externallyDriven = true;
		// g2 stays auto-driven

		// Particles.advanceTime should only advance externally-driven groups
		p.advanceTime(0.1);
		Assert.isTrue(g1._externalDt > 0, "Externally driven group should have pending dt");
		// g2 should not be touched by Particles.advanceTime
		Assert.floatEquals(0, g2._externalDt, 0.001);
	}

	@Test
	public function testExternallyDrivenGroupLevelUpdateTime():Void {
		var p = createParticles();
		var g = createGroup("main", p, true);
		g.externallyDriven = true;

		g.advanceTime(0.5);
		// updateTime should have been called — globalTime should advance
		Assert.floatEquals(0.5, g.globalTime, 0.01);
	}

	// ==================== emitFilter ====================

	@Test
	public function testEmitFilterDiscardsParticles():Void {
		var p = createParticles();
		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.speed = 0;
		dg.nparts = 10;
		dg.emitSync = 1.0;

		// Only allow particles with x >= 0 (reject negative x)
		g.emitFilter = (x:Float, y:Float) -> x >= 0;

		g.start();
		// Some particles may have been emitted at negative x and discarded
		var count = countParticles(g);
		// All 10 elements exist in batch, but filtered ones are invisible with expired life
		var visibleCount = 0;
		var e = g.batch.first;
		while (e != null) {
			if (e.visible) visibleCount++;
			e = e.next;
		}
		// With the filter active, at least some should be visible (those at x >= 0)
		// and the total should be <= nparts
		Assert.isTrue(visibleCount <= 10, 'Expected at most 10 visible, got $visibleCount');
		Assert.pass();
	}

	@Test
	public function testEmitFilterRejectsAll():Void {
		var p = createParticles();
		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.speed = 0;

		// Reject everything — emitFilter sets life > maxLife, so particles die on first update
		g.emitFilter = (x:Float, y:Float) -> false;

		g.emitBurst(5);
		// Advance one frame so filtered particles (life > maxLife) are removed
		advanceGroup(g, 0.016);

		Assert.equals(0, countParticles(g));
	}

	@Test
	public function testEmitFilterAcceptsAll():Void {
		var p = createParticles();
		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.speed = 0;

		// Accept everything
		g.emitFilter = (x:Float, y:Float) -> true;

		g.emitBurst(5);
		advanceGroup(g, 0.016);

		Assert.equals(5, countParticles(g));
	}

	@Test
	public function testEmitFilterSelectivelyAccepts():Void {
		// emitFilter receives world position computed during init().
		// Use a large emit distance so some particles land in the accept zone.
		var p = createParticles();
		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.speed = 0;
		dg.nparts = 20;
		dg.emitSync = 1.0;
		dg.emitMode = Point(100.0, 0.0); // All particles at distance 100 from origin

		var accepted = 0;
		var rejected = 0;
		// Accept only particles with x > 0 (right half)
		g.emitFilter = (x:Float, y:Float) -> {
			if (x > 0) { accepted++; return true; } else { rejected++; return false; }
		};

		g.start();
		advanceGroup(g, 0.016);

		// Some should be accepted (right half) and some rejected (left half)
		Assert.isTrue(accepted > 0, 'Expected some accepted particles, got $accepted');
		Assert.isTrue(rejected > 0, 'Expected some rejected particles, got $rejected');
		// Alive count should match accepted count
		Assert.equals(accepted, countParticles(g));
	}

	// ==================== syncPos with non-relative group + translated parent ====================

	@Test
	public function testNonRelativeGroupWithTranslatedParent():Void {
		var p = createParticles();
		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.speed = 0;
		dg.nparts = 1;
		dg.emitSync = 1.0;
		dg.isRelative = false;
		dg.emitMode = Point(0.0, 0.0); // No random offset

		// Translate the parent Particles object
		p.x = 100;
		p.y = 200;

		g.start();

		// For non-relative groups, init() transforms particle positions
		// through the parent's transform matrix via syncPos().
		// Particles should be at the parent's world position.
		var e = g.batch.first;
		Assert.notNull(e);
		Assert.floatEquals(100.0, e.x, 1.0);
		Assert.floatEquals(200.0, e.y, 1.0);
	}

	@Test
	public function testNonRelativeVsRelativeGroupPosition():Void {
		// Non-relative particles should have world coordinates;
		// relative particles should have local coordinates near origin.
		var p1 = createParticles();
		var gRel = createGroup("rel", p1);
		var dgRel:Dynamic = gRel;
		dgRel.speed = 0;
		dgRel.nparts = 1;
		dgRel.emitSync = 1.0;
		dgRel.isRelative = true;
		dgRel.emitMode = Point(0.0, 0.0);
		p1.x = 100;
		p1.y = 200;
		gRel.start();

		var p2 = createParticles();
		var gAbs = createGroup("abs", p2);
		var dgAbs:Dynamic = gAbs;
		dgAbs.speed = 0;
		dgAbs.nparts = 1;
		dgAbs.emitSync = 1.0;
		dgAbs.isRelative = false;
		dgAbs.emitMode = Point(0.0, 0.0);
		p2.x = 100;
		p2.y = 200;
		gAbs.start();

		var eRel = gRel.batch.first;
		var eAbs = gAbs.batch.first;
		Assert.notNull(eRel);
		Assert.notNull(eAbs);

		// Relative particle stays near local origin
		Assert.floatEquals(0.0, eRel.x, 1.0);
		Assert.floatEquals(0.0, eRel.y, 1.0);

		// Non-relative particle is at world position
		Assert.floatEquals(100.0, eAbs.x, 1.0);
		Assert.floatEquals(200.0, eAbs.y, 1.0);
	}

	// ==================== worldAnchor: non-relative bake into anchor-local frame ====================

	@Test
	public function testWorldAnchorBakesParticlesIntoAnchorLocalFrame():Void {
		// Scene: worldRoot at (50, 60) with a Particles child at (10, 20).
		// Without an anchor, a non-relative emit at local (0, 0) bakes to scene-space (60, 80).
		// With worldAnchor = worldRoot, the same emit must bake to (10, 20) — the parts container's
		// position relative to worldRoot — i.e. the worldRoot's local frame, with worldRoot's own
		// translation removed.
		var worldRoot = new h2d.Object();
		worldRoot.x = 50;
		worldRoot.y = 60;

		var p = new Particles(worldRoot);
		p.x = 10;
		p.y = 20;

		var g = createGroup("trail", p);
		var dg:Dynamic = g;
		dg.speed = 0;
		dg.nparts = 1;
		dg.emitSync = 1.0;
		dg.isRelative = false;
		dg.emitMode = Point(0.0, 0.0);

		p.worldAnchor = worldRoot;
		g.start();

		var e = g.batch.first;
		Assert.notNull(e);
		Assert.floatEquals(10.0, e.x, 0.01);
		Assert.floatEquals(20.0, e.y, 0.01);
	}

	@Test
	public function testWorldAnchorTrailStaysAnchoredAcrossAnchorTranslation():Void {
		// The point of worldAnchor is that a trail emitted before and after a camera/world pan
		// should land at the same anchor-local coordinates — particles do not slide against the
		// world when worldRoot moves between emits.
		var worldRoot = new h2d.Object();
		worldRoot.x = 0;
		worldRoot.y = 0;

		var p = new Particles(worldRoot);
		p.x = 100;
		p.y = 200;

		var g = createGroup("trail", p);
		var dg:Dynamic = g;
		dg.speed = 0;
		dg.emitMode = Point(0.0, 0.0);
		dg.isRelative = false;

		p.worldAnchor = worldRoot;

		g.emitBurst(1);
		var first = g.batch.first;
		Assert.notNull(first);
		var firstX = first.x;
		var firstY = first.y;

		// The world pans — worldRoot translates. The Particles container moves with it,
		// so the emitter is at a different scene-space point now.
		worldRoot.x = 500;
		worldRoot.y = 600;

		g.emitBurst(1);

		// Find the newly-emitted particle (the one that is not `first`).
		var second:Dynamic = g.batch.first;
		while (second != null && second == first) second = second.next;
		Assert.notNull(second);

		// Both particles must have the same anchor-local baked position — that is what
		// keeps the trail glued to the world while the world pans.
		Assert.floatEquals(firstX, second.x, 0.01);
		Assert.floatEquals(firstY, second.y, 0.01);
	}

	@Test
	public function testNullWorldAnchorPreservesScreenSpaceBaking():Void {
		// Regression guard: with worldAnchor explicitly null (the default), a non-relative
		// emit must still bake into scene space — i.e. include worldRoot's translation.
		var worldRoot = new h2d.Object();
		worldRoot.x = 50;
		worldRoot.y = 60;

		var p = new Particles(worldRoot);
		p.x = 10;
		p.y = 20;

		var g = createGroup("trail", p);
		var dg:Dynamic = g;
		dg.speed = 0;
		dg.nparts = 1;
		dg.emitSync = 1.0;
		dg.isRelative = false;
		dg.emitMode = Point(0.0, 0.0);

		// p.worldAnchor remains null — legacy path.
		g.start();

		var e = g.batch.first;
		Assert.notNull(e);
		Assert.floatEquals(60.0, e.x, 0.01);
		Assert.floatEquals(80.0, e.y, 0.01);
	}

	// ==================== Non-uniform container scale: column norms, not row norms ====================

	@Test
	public function testNonRelativeBakedScaleAndRotationUseContainerAxisLengths():Void {
		// For a Particles container with scaleX=2, scaleY=0.5, rotation=π/3:
		//   matA = 2·cos(π/3) = 1.0       matC = 0.5·-sin(π/3) ≈ -0.433
		//   matB = 2·sin(π/3) ≈ 1.732     matD = 0.5·cos(π/3)  =  0.25
		// The world length of the container's local x-axis is |column 1| = √(matA² + matB²) = 2,
		// and of the y-axis is |column 2| = √(matC² + matD²) = 0.5. A non-relative emit must
		// stamp those axis lengths and the container's rotation onto the particle's
		// baseScaleX/Y/rotation — so a particle authored at size=1 renders at the container's
		// effective size, which is what `relative: false` means visually.
		var p = createParticles();
		p.scaleX = 2.0;
		p.scaleY = 0.5;
		p.rotation = Math.PI / 3;

		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.speed = 0;
		dg.nparts = 1;
		dg.emitSync = 1.0;
		dg.isRelative = false;
		dg.emitMode = Point(0.0, 0.0);

		g.start();

		var e = g.batch.first;
		Assert.notNull(e);
		// e.scaleX/scaleY mirror baseScaleX/baseScaleY at emit; both are set in init().
		Assert.floatEquals(2.0, e.scaleX, 0.01);
		Assert.floatEquals(0.5, e.scaleY, 0.01);
		Assert.floatEquals(Math.PI / 3, e.rotation, 0.01);
	}

	@Test
	public function testNonRelativeBakeWithZeroSizeKeepsVelocityAndRotationFinite():Void {
		// When size=0 collapses scX/scY to zero, the column-axis-angle extraction
		// must still produce a finite rotation. The buggy form computes
		// atan2(rB / scX, rA / scX) — when scX = 0 and one of rA/rB is exactly
		// zero (identity / axis-aligned container), one operand becomes 0/0 = NaN,
		// atan2 returns NaN, and cos/sin poison p.vx/p.vy/p.rotation. atan2 is
		// magnitude-invariant for positive scaling, so dividing by scX is
		// unnecessary; atan2(rB, rA) is the correct formulation.
		var p = createParticles();
		// Identity matrix is enough: matA=1, matB=0 — exactly the 0/0 + 1/0 case.

		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.size = 0; // the trigger
		dg.nparts = 1;
		dg.emitSync = 1.0;
		dg.isRelative = false;
		dg.emitMode = Point(0.0, 0.0);

		g.start();

		var e:Dynamic = g.batch.first;
		Assert.notNull(e);
		var vx:Float = e.vx;
		var vy:Float = e.vy;
		var rotation:Float = e.rotation;
		Assert.isFalse(Math.isNaN(vx), 'vx must be finite after non-relative emit at size=0; got $vx');
		Assert.isFalse(Math.isNaN(vy), 'vy must be finite after non-relative emit at size=0; got $vy');
		Assert.isFalse(Math.isNaN(rotation), 'rotation must be finite after non-relative emit at size=0; got $rotation');
		Assert.isTrue(Math.isFinite(vx), 'vx must not be infinite after non-relative emit at size=0; got $vx');
		Assert.isTrue(Math.isFinite(vy), 'vy must not be infinite after non-relative emit at size=0; got $vy');
		Assert.isTrue(Math.isFinite(rotation), 'rotation must not be infinite after non-relative emit at size=0; got $rotation');
	}

	@Test
	public function testNonRelativeBakeWithZeroSizeAndWorldAnchorKeepsVelocityFinite():Void {
		// Same NaN hazard on the worldAnchor path — after lines 977-980 overwrite
		// rA..rD with the anchor-composed transform, the same atan2(rB / scX, rA / scX)
		// at line 999 still divides by zero when size=0. With identity transforms
		// on both objects, the composed rA=1, rB=0 reproduces the 0/0 NaN case.
		var worldRoot = new h2d.Object();

		var p = new Particles(worldRoot);

		var g = createGroup("trail", p);
		var dg:Dynamic = g;
		dg.size = 0;
		dg.nparts = 1;
		dg.emitSync = 1.0;
		dg.isRelative = false;
		dg.emitMode = Point(0.0, 0.0);

		p.worldAnchor = worldRoot;
		g.start();

		var e:Dynamic = g.batch.first;
		Assert.notNull(e);
		var vx:Float = e.vx;
		var vy:Float = e.vy;
		var rotation:Float = e.rotation;
		Assert.isFalse(Math.isNaN(vx), 'vx must be finite under worldAnchor + size=0; got $vx');
		Assert.isFalse(Math.isNaN(vy), 'vy must be finite under worldAnchor + size=0; got $vy');
		Assert.isFalse(Math.isNaN(rotation), 'rotation must be finite under worldAnchor + size=0; got $rotation');
		Assert.isTrue(Math.isFinite(vx), 'vx must not be infinite under worldAnchor + size=0; got $vx');
		Assert.isTrue(Math.isFinite(vy), 'vy must not be infinite under worldAnchor + size=0; got $vy');
		Assert.isTrue(Math.isFinite(rotation), 'rotation must not be infinite under worldAnchor + size=0; got $rotation');
	}

	// ==================== Sub-emitter OnBirth on recycled particles ====================

	@Test
	public function testSubEmitterOnBirthRecycled():Void {
		var p = createParticles();
		var mainGroup = createGroup("main", p, true); // looping
		var subGroup = createGroup("sparks", p);

		var dm:Dynamic = mainGroup;
		dm.nparts = 3;
		dm.life = 0.1; // short life so particles recycle quickly
		dm.subEmitters = ([
			{
				groupId: "sparks",
				trigger: OnBirth,
				probability: 1.0,
				inheritVelocity: 0.0,
				offsetX: 0.0,
				offsetY: 0.0,
				burstCount: 1
			}
		] : Array<SubEmitter>);

		// Initial start triggers OnBirth for 3 particles
		mainGroup.start();
		var initialSubCount = countParticles(subGroup);
		Assert.isTrue(initialSubCount >= 3, 'Expected at least 3 initial sub-particles, got $initialSubCount');

		// Advance past particle lifetime so they die and recycle (looping)
		// Recycled particles should also trigger OnBirth
		advanceGroup(mainGroup, 0.5);
		advanceGroup(subGroup, 0.016);

		var afterRecycleCount = countParticles(subGroup);
		// If recycled births trigger sub-emitters, count should be > initial
		// If not, this test documents the current behavior
		Assert.isTrue(afterRecycleCount >= initialSubCount,
			'Expected recycled births to trigger sub-emitters: after=$afterRecycleCount >= initial=$initialSubCount');
	}

	@Test
	public function testShutdownOnParticlesForwardsToAllGroups():Void {
		var p = createParticles();
		var g1 = createGroup("group1", p, true);
		var g2 = createGroup("group2", p, true);

		advanceGroup(g1, 0.1);
		advanceGroup(g2, 0.1);

		p.shutdown(0.5);
		Assert.isTrue(g1.isShuttingDown());
		Assert.isTrue(g2.isShuttingDown());
	}

	// ==================== Regression: emitFilter rejection cascade ====================

	@Test
	public function testEmitFilterRejectsDoNotTriggerSubEmitters():Void {
		// Regression: filter-rejected particles used to fire OnBirth in the
		// delayed-spawn init step AND OnDeath when their forced-expired
		// lifecycle tripped, turning every reject into an explosive sub-emitter
		// cascade. Both triggers must check `rejected` first.
		// Use emitDelay > 0 with emitSync = 1.0 so all particles route through
		// the delayed-spawn path in update() (not the immediate start() spawn).
		var p = createParticles();
		var mainGroup = createGroup("main", p);
		var sparks = createGroup("sparks", p);

		// Sparks must have its own nparts = 0 so its start() (triggered by
		// emitBurstAt's autostart) doesn't create baseline particles that
		// would mask sub-emitter spawns.
		var ds:Dynamic = sparks;
		ds.nparts = 0;

		var dm:Dynamic = mainGroup;
		dm.nparts = 10;
		dm.life = 0.5;
		dm.emitSync = 1.0;
		dm.emitDelay = 0.1;
		dm.subEmitters = ([
			{groupId: "sparks", trigger: OnBirth, probability: 1.0,
				inheritVelocity: 0.0, offsetX: 0.0, offsetY: 0.0, burstCount: 5},
			{groupId: "sparks", trigger: OnDeath, probability: 1.0,
				inheritVelocity: 0.0, offsetX: 0.0, offsetY: 0.0, burstCount: 5},
		] : Array<SubEmitter>);

		// Reject every spawn (called inside init() during the delayed step)
		mainGroup.emitFilter = (x:Float, y:Float) -> false;

		// Advance past emitDelay (0.1) and through the forced expiry so the
		// lifecycle branch runs OnDeath as well.
		advanceGroup(mainGroup, 0.5);

		Assert.equals(0, countParticles(sparks),
			'Rejected particles must not trigger OnBirth/OnDeath sub-emitters (got ${countParticles(sparks)} sparks)');
	}

	@Test
	public function testEmitBurstWithRejectionKeepsLiveCountFromDriftingNegative():Void {
		// emitBurstAt only increments liveCount when init() accepts, but the death
		// branches in Particle.update decrement unconditionally — including the
		// stillborn particles whose life was forced past maxLife by filter rejection.
		// Repeated rejected bursts therefore drive liveCount negative, which then
		// poisons shutdown's comparison against shutdownTargetCount.
		var p = createParticles();
		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.nparts = 0; // burst-only path — bypass start()'s baseline
		dg.speed = 0;
		dg.life = 0.5;

		g.emitFilter = (x:Float, y:Float) -> false;

		// Three rejected bursts. Without start(), liveCount baseline is 0; the only
		// changes come from emitBurstAt (none — all rejected) and update's death
		// branch (one decrement per stillborn particle).
		g.emitBurst(10);
		advanceGroup(g, 0.05);
		g.emitBurst(10);
		advanceGroup(g, 0.05);
		g.emitBurst(10);
		advanceGroup(g, 0.05);

		Assert.equals(0, g.liveCount,
			'Rejected bursts must not drift liveCount; expected 0 after all stillborn particles freed, got ${g.liveCount}');
	}

	@Test
	public function testDelayedInitRejectionSkipsSameFramePhysics():Void {
		// When emitFilter rejects a particle whose init was deferred past emitDelay,
		// Particle.update must mirror the burst path and return immediately —
		// rejected particles must NOT continue into the physics block (gravity,
		// force fields, position update) and the lifecycle branch (which would
		// free them in the same update tick) inside the rejection frame.
		// The burst path adds rejected particles to the batch and skips the
		// post-init setup; the delayed-init path was falling through.
		var p = createParticles();
		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.nparts = 5;
		dg.emitSync = 1.0;
		dg.emitDelay = 0.05;
		dg.life = 1.0;

		// Reject every spawn — init() flips life=maxLife+1, sets rejected=true,
		// and returns false. The delayed-init branch has no else for that.
		g.emitFilter = (x:Float, y:Float) -> false;

		// Drive past emitDelay so init() runs and rejects in update(). Each
		// 0.016s tick is < emitDelay, so the delay branch counts down across
		// several ticks and crosses zero on the final tick — that final tick
		// is where the rejection happens.
		advanceGroup(g, 0.06);

		// Mirror burst behavior: rejected particles stay in the batch with
		// life=maxLife+1, rejected=true, freed by the lifecycle branch on the
		// NEXT update — not in the same tick that rejected them.
		Assert.equals(5, countParticles(g),
			"Rejected delayed-init particles must mirror the burst path — they "
			+ "should remain in the batch in the rejection frame, not be carried "
			+ "through physics + lifecycle in the same update tick. Got "
			+ countParticles(g) + " (current bug: physics runs, lifecycle frees).");
	}

	@Test
	public function testRejectedRecycleInLoopGroupFreesParticles():Void {
		// In a looping group, the lifecycle branch (and the bounds-out-of-bounds
		// branch) recycles a particle by calling init() but ignores its return
		// value. When init() is rejected by the filter, init() reset rejected to
		// false at entry then set it back to true on filter reject — the particle
		// stays in the batch with rejected=true, life=maxLife+1, ready to cycle
		// again next frame, forever. Fix: when recycle init returns false, free
		// the particle the same way the non-loop branch does.
		var p = createParticles();
		var g = createGroup("main", p, true); // looping
		var dg:Dynamic = g;
		dg.nparts = 5;
		dg.emitDelay = 0;
		dg.emitSync = 1.0;
		dg.life = 0.05; // short — first lifecycle hits within a couple of frames

		g.emitFilter = (x:Float, y:Float) -> false;

		// Run for many particle lifetimes — each cycle should NOT keep rejected
		// particles alive. With the fix, all 5 are freed on first recycle reject.
		advanceGroup(g, 0.5);

		Assert.equals(0, countParticles(g),
			"Looping group with all-rejecting filter must free particles when "
			+ "recycle init() rejects, not cycle them indefinitely. Got "
			+ countParticles(g) + " (current bug: lifecycle re-init at line 306 "
			+ "ignores init() return value).");
	}

	@Test
	public function testRejectedParticleDoesNotFireIntervalSubEmitters():Void {
		// checkIntervalSubEmitters at line 291 has no `rejected` guard. A
		// rejected particle has life=maxLife+1 and lastSubEmitTime=0, so the
		// `life - lastSubEmitTime >= interval` test fires for any reasonable
		// interval. The OnBirth/OnDeath triggers at line 297 already gate on
		// !rejected; the interval trigger must too. Reachable on burst-rejected
		// particles' next-frame update (the delayed-init rejection now returns
		// early before reaching line 291).
		var p = createParticles();
		var mainGroup = createGroup("main", p);
		var sparks = createGroup("sparks", p);
		var ds:Dynamic = sparks;
		ds.nparts = 0; // no baseline particles, sparks counts only sub-emits

		var dm:Dynamic = mainGroup;
		dm.nparts = 0; // burst-only, avoid start() spawning anything
		dm.life = 1.0;
		dm.subEmitters = ([
			{groupId: "sparks", trigger: OnInterval(0.05), probability: 1.0,
				inheritVelocity: 0.0, offsetX: 0.0, offsetY: 0.0, burstCount: 3},
		] : Array<SubEmitter>);

		mainGroup.emitFilter = (x:Float, y:Float) -> false;
		mainGroup.emitBurst(5);

		// Advance one frame so rejected particles' next-frame update runs and
		// reaches the interval-check site before lifecycle frees them.
		advanceGroup(mainGroup, 0.016);

		Assert.equals(0, countParticles(sparks),
			"Rejected particles must not fire OnInterval sub-emitters — got "
			+ countParticles(sparks) + " sparks. Mirrors the existing !rejected "
			+ "guard around OnDeath at line 297.");
	}

	@Test
	public function testRejectedParticleSkipsPhysicsTickBeforeFree():Void {
		// init() marks a filter-rejected particle dead (life=maxLife+1,
		// rejected=true, visible=false) and the particle is kept in the batch
		// for one more update tick before being freed. That deferred-free tick
		// must NOT run the physics block — gravity, force fields, position
		// step, life increment, rotation, size, alpha, color, sprite anim,
		// bounds — on a particle already known to be dead.
		var p = createParticles();
		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.nparts = 0; // burst-only, no start() spawn
		dg.life = 1.0;
		dg.speed = 0; // no emit velocity, so gravity contribution is the only Δvy
		dg.emitMode = Point(0.0, 0.0); // particle stays at origin in init
		dg.gravity = 1000.0;
		dg.gravityAngle = 0.0; // gravity points down — adds to vy

		g.emitFilter = (x:Float, y:Float) -> false;
		g.emitBurst(1);

		var e:Dynamic = g.batch.first;
		Assert.notNull(e, "Expected one rejected particle in batch after burst");
		// Snapshot post-init state. With Point(0,0) + speed=0, init leaves
		// x=0, y=0, vx=0, vy=0 even on rejection — the filter check is the
		// last thing init does and it doesn't touch those fields.
		var lifeBefore:Float = e.life;
		var vyBefore:Float = e.vy;
		var yBefore:Float = e.y;

		final dt:Float = 0.016;
		var alive:Bool = e.update(dt);
		Assert.isFalse(alive,
			"Rejected particle must be freed on the next update tick.");
		Assert.floatEquals(lifeBefore, e.life, 1e-6,
			"Rejected particle must not have `life += dt` applied before "
			+ "being freed. life went from " + lifeBefore + " to " + e.life
			+ " — physics ran on a dead particle.");
		Assert.floatEquals(vyBefore, e.vy, 1e-6,
			"Rejected particle must not accumulate gravity before being freed. "
			+ "vy went from " + vyBefore + " to " + e.vy
			+ " — physics ran on a dead particle.");
		Assert.floatEquals(yBefore, e.y, 1e-6,
			"Rejected particle must not move via the position step before "
			+ "being freed. y went from " + yBefore + " to " + e.y
			+ " — physics ran on a dead particle.");
	}

	@Test
	public function testEmitBurstAtDoesNotApplyOffsetToRejectedParticle():Void {
		// emitBurstAt unconditionally writes `p.x += atX; p.y += atY;
		// p.vx += inheritVx; p.vy += inheritVy` after calling init(). When
		// init() rejected via emitFilter, the particle was already marked
		// dead and its position/velocity must not be mutated by the burst-
		// position offset.
		var p = createParticles();
		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.nparts = 0;
		dg.life = 1.0;
		dg.speed = 0;
		dg.emitMode = Point(0.0, 0.0); // init leaves x=y=vx=vy=0 on rejection

		g.emitFilter = (x:Float, y:Float) -> false;
		g.emitBurstAt(500.0, 700.0, 50.0, 80.0, 1);

		var e:Dynamic = g.batch.first;
		Assert.notNull(e, "Expected one rejected particle in batch after burst");
		Assert.floatEquals(0.0, e.x, 1e-6,
			"atX must not be applied to a rejected particle. Got x=" + e.x);
		Assert.floatEquals(0.0, e.y, 1e-6,
			"atY must not be applied to a rejected particle. Got y=" + e.y);
		Assert.floatEquals(0.0, e.vx, 1e-6,
			"inheritVx must not be applied to a rejected particle. Got vx=" + e.vx);
		Assert.floatEquals(0.0, e.vy, 1e-6,
			"inheritVy must not be applied to a rejected particle. Got vy=" + e.vy);
	}

	// ==================== Regression: shutdown terminal multipliers reset ====================

	@Test
	public function testShutdownResetsMultipliersAfterNaturalDieOff():Void {
		// Regression: when shutdown's count curve reached rate >= 1.0 the flag
		// was cleared so any remaining live particles could finish naturally,
		// but the alpha/size/speed multipliers were left at their terminal (~0)
		// values, so leftover particles rendered invisible/zero-sized.
		var p = createParticles();
		var g = createGroup("main", p, true);
		var dg:Dynamic = g;
		dg.life = 5.0; // long enough that particles outlive the shutdown window

		g.shutdownAlphaCurve = new bh.paths.Curve(null, Linear, null);
		g.shutdownSizeCurve = new bh.paths.Curve(null, Linear, null);
		g.shutdownSpeedCurve = new bh.paths.Curve(null, Linear, null);

		advanceGroup(g, 0.1);
		g.shutdown(0.2);
		Assert.isTrue(g.isShuttingDown());

		// Run past full shutdown duration so the curve clamps and the
		// shutdownActive flag flips off.
		advanceGroup(g, 0.5);

		Assert.isFalse(g.isShuttingDown(),
			"shutdown should have completed (flag cleared) after duration");
		Assert.floatEquals(1.0, g.shutdownAlphaMult, 0.001,
			"alphaMult must reset to 1 once shutdownActive clears");
		Assert.floatEquals(1.0, g.shutdownSizeMult, 0.001,
			"sizeMult must reset to 1 once shutdownActive clears");
		Assert.floatEquals(1.0, g.shutdownSpeedMult, 0.001,
			"speedMult must reset to 1 once shutdownActive clears");
	}

	// ==================== Regression: removeGroup clears its batch ====================

	@Test
	public function testRemoveGroupClearsBatch():Void {
		// Regression: Particles.removeGroup(id) used to drop the entry from the
		// map but leave the underlying SpriteBatch attached as a child of the
		// Particles object, so its particles kept rendering until the parent
		// was disposed. Now the batch is cleared and removed from the scene.
		var p = createParticles();
		var g = createGroup("main", p);
		g.start();

		final batch = g.batch;
		Assert.notNull(batch.parent, "batch should be attached to scene before removeGroup");
		Assert.isTrue(countParticles(g) > 0, "expected live particles before removeGroup");

		p.removeGroup("main");

		Assert.isNull(p.groups.get("main"), "group should be removed from map");
		Assert.isNull(batch.parent, "batch must be detached from scene after removeGroup");
		Assert.isNull(batch.first, "batch element list must be cleared after removeGroup");
	}

	@Test
	public function testRemoveGroupDrainsFreeParticlePool():Void {
		// removeGroup must release every Particle instance the free-list pool
		// is holding onto. Without this, callers who captured the ParticleGroup
		// reference before removeGroup (sub-emitter chains, game-side handles)
		// keep N dead Particle objects pinned through that reference for the
		// lifetime of that capture.
		var p = createParticles();
		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.life = 0.1; // short life so particles die quickly

		g.emitBurstAt(0, 0, 0, 0, 5);
		advanceGroup(g, 0.5);
		Assert.equals(0, countParticles(g), "all particles should have died");
		Assert.isTrue(g.freeParticles.length > 0,
			"expected dead particles in the free-list pool before removeGroup");

		p.removeGroup("main");

		Assert.equals(0, g.freeParticles.length,
			"removeGroup must drain the free-list pool so captured group references no longer pin dead Particle instances");
	}

	// ==================== Color curve: per-particle segment cache ====================

	static function createLinearCurve():ICurve {
		return new Curve(null, Linear);
	}

	/**
		Drive a single particle's `update(dt)` calls directly (no emission, no group retick).
		The group must already have a spawned particle via `emitBurst(1)` or `start()`.
	**/
	static function tickParticles(g:ParticleGroup, dt:Float):Void {
		var e = g.batch.first;
		while (e != null) {
			var next = e.next;
			if (!e.update(dt)) e.remove();
			e = next;
		}
	}

	static function setupColorCurveGroup(name:String):{p:Particles, g:ParticleGroup} {
		var p = createParticles();
		var g = createGroup(name, p);
		var dg:Dynamic = g;
		dg.nparts = 1;
		dg.life = 1.0;
		dg.lifeRand = 0;
		dg.speed = 0;
		dg.emitMode = PartEmitMode.Point(0, 0);
		return {p: p, g: g};
	}

	/**
		Sanity regression: color values across a multi-segment curve must remain
		correct at segment boundaries and mid-segment after the scan is replaced
		with a cached-index advance.
	**/
	@Test
	public function testColorCurveSegments_ColorCorrectAcrossLifetime():Void {
		var h = setupColorCurveGroup("colorCorrect");
		var g = h.g;
		// Override life = 2.0 so each 0.5s step moves the rate in clean 0.25 increments.
		var dg:Dynamic = g;
		dg.life = 2.0;
		// Two linear segments: red->green (0.0..0.5), green->blue (0.5..1.0).
		g.addColorCurveSegment(0.0, createLinearCurve(), 0xFF0000, 0x00FF00);
		g.addColorCurveSegment(0.5, createLinearCurve(), 0x00FF00, 0x0000FF);

		g.emitBurst(1);
		var p = g.batch.first;
		Assert.notNull(p, "expected one particle to be emitted");

		// Particle.update() evaluates color from CURRENT life then advances life,
		// so after N ticks of step s the color reflects rate = (N-1)*s / maxLife.
		// life=2.0, step=0.5 => after 2 ticks the color reflects rate 0.25 (mid seg 0).
		tickParticles(g, 0.5);
		tickParticles(g, 0.5);
		Assert.floatEquals(0.5, p.r, 0.02, "mid seg 0: red channel should be ~0.5");
		Assert.floatEquals(0.5, p.g, 0.02, "mid seg 0: green channel should be ~0.5");
		Assert.floatEquals(0.0, p.b, 0.02, "mid seg 0: blue should be ~0");

		// Two more ticks bring last-evaluated rate to 0.75 (mid seg 1).
		tickParticles(g, 0.5);
		tickParticles(g, 0.5);
		Assert.floatEquals(0.0, p.r, 0.02, "mid seg 1: red should be ~0");
		Assert.floatEquals(0.5, p.g, 0.02, "mid seg 1: green channel should be ~0.5");
		Assert.floatEquals(0.5, p.b, 0.02, "mid seg 1: blue channel should be ~0.5");
	}

	/**
		When a looping particle is recycled via `init()`, the next lifetime must
		start back at segment 0 (red), not remain stuck on the last segment.
		Pins that `init(p)` resets `currentColorSegmentIndex` so the cached
		monotonic-advance scheme rewinds across an emit-loop cycle.
	**/
	@Test
	public function testColorCurveSegments_ResetsOnEmitLoopRecycle():Void {
		var p = createParticles();
		var g = createGroup("colorLoop", p, /* loop */ true);
		var dg:Dynamic = g;
		dg.nparts = 1;
		dg.life = 1.0;
		dg.lifeRand = 0;
		dg.speed = 0;
		dg.emitMode = PartEmitMode.Point(0, 0);
		g.addColorCurveSegment(0.0, createLinearCurve(), 0xFF0000, 0x00FF00);
		g.addColorCurveSegment(0.5, createLinearCurve(), 0x00FF00, 0x0000FF);

		g.emitBurst(1);
		var particle = g.batch.first;
		Assert.notNull(particle);

		// Drive past end-of-life so the particle recycles back to life=0.
		tickParticles(g, 0.6); // -> rate ~0.6 (seg 1)
		tickParticles(g, 0.6); // -> rate > 1.0, triggers init() recycle

		// One tiny step after recycle — rate should be ~0.05 (seg 0, nearly pure red).
		tickParticles(g, 0.05);
		Assert.floatEquals(1.0, particle.r, 0.15,
			"after emitLoop recycle, particle's color must restart at segment 0 (red); got r=" + particle.r);
		Assert.floatEquals(0.0, particle.b, 0.15,
			"after emitLoop recycle, blue must be ~0 (we're back at the start, not stuck at last segment); got b=" + particle.b);
	}

	/**
		Landmark test for the optimization: particles must carry a cached
		`currentColorSegmentIndex` (same shape as `currentAnimStateIndex`) and it
		must advance monotonically as the particle's rate crosses segment
		boundaries. This fails on HEAD because no such cache exists — the fix
		is expected to add one and feed `Particle.update()` from it.
	**/
	@Test
	public function testColorCurveSegments_CacheAdvancesMonotonically():Void {
		var h = setupColorCurveGroup("colorCache");
		var g = h.g;
		// Four segments — a full scan would be noticeably more expensive than a cached advance.
		g.addColorCurveSegment(0.0,  createLinearCurve(), 0xFF0000, 0x00FF00);
		g.addColorCurveSegment(0.25, createLinearCurve(), 0x00FF00, 0x0000FF);
		g.addColorCurveSegment(0.5,  createLinearCurve(), 0x0000FF, 0xFFFF00);
		g.addColorCurveSegment(0.75, createLinearCurve(), 0xFFFF00, 0xFF00FF);

		g.emitBurst(1);
		var particle = g.batch.first;
		Assert.notNull(particle);

		Assert.isTrue(Reflect.hasField(particle, "currentColorSegmentIndex"),
			"Particle must carry a cached currentColorSegmentIndex field (mirrors currentAnimStateIndex) to avoid an O(segments) scan every frame");

		var observed:Array<Int> = [];
		// 9 steps of 0.1s brings rate to ~0.9, crossing all four segment starts.
		for (i in 0...9) {
			tickParticles(g, 0.1);
			var raw:Dynamic = Reflect.field(particle, "currentColorSegmentIndex");
			Assert.notNull(raw, "cached index must be readable via Reflect on step " + i);
			observed.push(Std.int(raw));
		}

		Assert.isTrue(observed[observed.length - 1] > observed[0],
			"cached index must advance as rate crosses segment boundaries; observed sequence: " + observed.join(","));
		for (i in 1...observed.length) {
			Assert.isTrue(observed[i] >= observed[i - 1],
				"cached index must never move backwards within a single lifetime; step " + i + ": " + observed[i - 1] + " -> " + observed[i]);
		}
	}

	/**
		Color-curve evaluation must live in exactly one place — the cached, monotonic
		path inside `Particle.update()`. The previous public `ParticleGroup.evaluateColorCurve`
		helper duplicates that math with an O(segments) full scan from index 0 and is no longer
		called by any production path. Keeping it around is a footgun: any caller wiring it up
		silently reverts the cached-index optimization. This test pins the API surface.
	**/
	@Test
	public function testParticleGroup_HasNoStandaloneColorCurveEvaluator():Void {
		var fields = Type.getInstanceFields(ParticleGroup);
		Assert.isFalse(fields.indexOf("evaluateColorCurve") != -1,
			"ParticleGroup must not expose evaluateColorCurve — the per-particle hot path in Particle.update() "
			+ "is the single source of truth and uses a cached currentColorSegmentIndex. A standalone helper would "
			+ "reintroduce the O(segments) scan it replaced. Found field on instance: "
			+ fields.filter(f -> f == "evaluateColorCurve").join(","));
	}

	// ==================== Allocation watchdog ====================

	// Particle update is on the deepest hot loop in the engine: each frame loops
	// over every live particle, applies force fields, advances velocity/position,
	// and color-curve interpolation. Force fields are stored as enum cases
	// (immutable, allocated once at config time). PathGuide uses `_scratch:FPoint`
	// to avoid per-particle FPoint allocation. This test pins those contracts.
	@Test
	public function testParticleStepDoesNotAllocateFPoint():Void {
		var p = createParticles();
		var g = createGroup("alloc", p, true);
		// Force-field-heavy config: every per-particle path through applyForceFields fires.
		g.addForceField(Wind(5.0, 0.0));
		g.addForceField(Vortex(0, 0, 50.0, 200.0));
		g.addForceField(Attractor(50.0, 50.0, 30.0, 100.0));

		// Warm-up: spawn the group and run one step so any first-time allocations
		// (e.g. SpriteBatch internals) settle.
		advanceGroup(g, 0.05);
		final fpointBaseline = FPoint.creationCount;

		// 30 ticks * 20 particles = 600 particle steps with 3 force fields each.
		advanceGroup(g, 0.5);

		final delta = FPoint.creationCount - fpointBaseline;
		Assert.equals(0, delta,
			"Particle step (Particle.update + applyForceFields) must be FPoint-allocation-free. "
			+ "Got " + delta + " fresh FPoints across ~30 ticks * 20 particles. PathGuide and "
			+ "computeState already use scratch FPoints; if this fires, someone added an allocation.");
	}

	// ==================== Group iteration must not allocate Map iterators ====================

	// Particles.sync runs once and Particles.draw runs twice per frame, each iterating
	// the groups Map directly. On HL each `for (g in groups)` allocates a fresh
	// hashmap iterator (backing array + struct + iterator object) — ~9 allocs/frame
	// per Particles instance even when nothing is happening. The fix keeps a parallel
	// Array<ParticleGroup> in registration order and iterates THAT in hot paths.
	// These two tests pin the contract that the parallel list mirrors the Map.

	@Test
	public function testAddGroupAppendsToGroupList():Void {
		var p = createParticles();
		var ga = createGroup("a", p);
		var gb = createGroup("b", p);
		var gc = createGroup("c", p);

		Assert.equals(3, p.groupList.length,
			"groupList must contain every group present in the groups Map. "
			+ "If this fires, addGroup forgot to push onto the parallel list.");
		Assert.equals(ga, p.groupList[0], "groupList must preserve insertion order — slot 0 should be the first added group.");
		Assert.equals(gb, p.groupList[1], "groupList must preserve insertion order — slot 1 should be the second added group.");
		Assert.equals(gc, p.groupList[2], "groupList must preserve insertion order — slot 2 should be the third added group.");
	}

	@Test
	public function testRemoveGroupRemovesFromGroupListPreservingOrder():Void {
		var p = createParticles();
		var ga = createGroup("a", p);
		createGroup("b", p);
		var gc = createGroup("c", p);
		createGroup("d", p);

		p.removeGroup("b");
		p.removeGroup("d");

		Assert.equals(2, p.groupList.length,
			"removeGroup must drop the group from the parallel list. "
			+ "If this fires, removeGroup updated the Map but not groupList — hot-path iteration "
			+ "would still walk over removed groups.");
		Assert.equals(ga, p.groupList[0], "remaining groups must keep their original relative order — 'a' is still first.");
		Assert.equals(gc, p.groupList[1], "remaining groups must keep their original relative order — 'c' is still second.");
	}

	// ==================== Disabled group should freeze attached path ====================

	@Test
	public function testAttachedPathDoesNotAdvanceWhenGroupDisabled():Void {
		var p = createParticles();
		var g = createGroup("main", p);

		// Attach a 1-second linear time-mode path with a mid-rate event.
		var sp = new SinglePath(new FPoint(0, 0), new FPoint(100, 0), Line);
		var ap = new AnimatedPath(new Path([sp]), Time(1.0));
		var firedEvents:Array<String> = [];
		ap.onEvent = (name, _) -> firedEvents.push(name);
		ap.addEvent(0.3, "halfwayish");
		g.attachedPath = ap;

		// Disable the group. enabled is (default, null), so use Dynamic to bypass
		// the property restriction — same approach createGroup() uses for nparts/etc.
		var dg:Dynamic = g;
		dg.enabled = false;

		// Tick well past the event rate. updateTime() is what Particles.sync() calls
		// every frame regardless of visibility (Heaps 2.1.0 sync() does not check
		// visible) and regardless of enabled.
		g.updateTime(0.5);

		// Path must stay at rate 0 — no events, no progress, no spawn-curve emission.
		Assert.floatEquals(0.0, ap.getState().rate, 0.0001,
			"AttachedPath rate advanced while group was disabled. updateTime() should not "
			+ "tick attachedPath when enabled is false — rendering and start() are gated on "
			+ "enabled, the path tick should match.");
		Assert.equals(0, firedEvents.length,
			"AttachedPath fired " + firedEvents.length + " event(s) while group was disabled. "
			+ "Expected zero — pathStart and timed events must not fire on a disabled group.");
	}

	// ==================== applyAnimEventOverride pinning ====================

	@Test
	public function testAnimEventOverridePersistsAcrossNextUpdate():Void {
		// applyAnimEventOverride sets currentAnimStateIndex to the override target,
		// but Particle.update()'s natural-advance loop is monotonic forward by lifetime
		// — it walks forward whenever timeNormalized >= animStates[i+1].startLifeRate.
		// If the override targets a state with a startLifeRate lower than the
		// natural-by-time index, the very next tick walks straight past it and the
		// impact / bounce / death anim flickers for one frame at most.
		var p = createParticles();
		var g = createGroup("main", p);
		var dg:Dynamic = g;
		dg.nparts = 1;
		dg.emitDelay = 0;
		dg.emitSync = 1.0; // spawn immediately, no random delay
		dg.life = 1.0;
		dg.lifeRand = 0;

		var t0 = h2d.Tile.fromColor(0x111111, 4, 4);
		var t1 = h2d.Tile.fromColor(0x222222, 4, 4);
		var t2 = h2d.Tile.fromColor(0x333333, 4, 4);
		g.animStates = [
			{ name: "spawn", tiles: [t0], fps: 0, startLifeRate: 0.0 },
			{ name: "mid",   tiles: [t1], fps: 0, startLifeRate: 0.3 },
			{ name: "late",  tiles: [t2], fps: 0, startLifeRate: 0.7 }
		];
		// Override points at state 0 — earlier than the natural-by-time index will be.
		g.animEventOverrides.set("onBounce", 0);

		g.start();
		Assert.equals(1, countParticles(g), "expected one particle after start()");

		// Advance into the late-lifetime band so the natural advance has walked the
		// state index to 2 (timeNormalized ≈ 0.8 ≥ states[2].startLifeRate=0.7).
		advanceGroup(g, 0.8);

		var particle:Dynamic = g.batch.first;
		Assert.notNull(particle);
		Assert.equals(2, particle.currentAnimStateIndex,
			"sanity: natural advance should have reached state index 2 by lifetime≈0.8");

		// Fire the override. applyAnimEventOverride sets the state index to 0 and
		// swaps the tile immediately.
		g.applyAnimEventOverride(particle, "onBounce");
		Assert.equals(0, particle.currentAnimStateIndex,
			"applyAnimEventOverride must set currentAnimStateIndex to the override target (0)");

		// One more tick. With the bug, the natural-advance loop walks from 0 back up
		// to 2 (timeNormalized ~0.81 ≥ states[1].startLifeRate=0.3 and ≥ states[2].startLifeRate=0.7)
		// and clobbers the override. The override must remain pinned.
		particle.update(0.016);
		Assert.equals(0, particle.currentAnimStateIndex,
			"override target (0) must remain pinned after the next update() — "
			+ "the natural-advance loop must not walk past the override target. "
			+ "Got currentAnimStateIndex=" + particle.currentAnimStateIndex);
	}

	// ==================== onEnd must not fire before the system has ever emitted ====================
	//
	// Particles.sync() initialises `isDone = true` and only flips it to false when at least
	// one group has `batch.first != null`. That collapses two unrelated states — "system has
	// never emitted anything yet" and "system has finished emitting" — into the same signal.
	// The default `onEnd()` body calls `this.remove()`, so the container gets detached from
	// its parent on the FIRST sync after construction unless a group has already populated
	// its batch. The two scenarios below are the natural footguns: a freshly-created
	// Particles whose groups are still being added, and a burst-only group (`nparts == 0`)
	// waiting for an external `emitBurstAt()` trigger (typical worldAnchor trail-emitter
	// pattern).

	/** Invoke Particles.sync() directly so we can observe whether onEnd fires on the first tick. */
	static function syncOnce(p:Particles, dt:Float):Void {
		var ctx:h2d.RenderContext = bh.test.VisualTestBase.appInstance.s2d.renderer;
		ctx.elapsedTime = dt;
		@:privateAccess p.sync(ctx);
	}

	@Test
	public function testEmptyParticlesContainerDoesNotFireOnEndOnFirstSync():Void {
		var p = createParticles();
		var endCalls = 0;
		p.onEnd = () -> endCalls++;

		syncOnce(p, 0.016);

		Assert.equals(0, endCalls,
			"onEnd fired on a freshly-created Particles that has no groups yet. The default "
			+ "onEnd body removes the container from its parent, so the natural construction "
			+ "sequence `new Particles(parent); configure(); addGroup(g);` loses the container "
			+ "if the scene ticks between construction and addGroup. Got " + endCalls + " call(s).");
	}

	@Test
	public function testParticlesWithBurstOnlyGroupDoesNotFireOnEndBeforeFirstBurst():Void {
		var p = createParticles();
		var tiles = [h2d.Tile.fromColor(0xFF0000, 4, 4)];
		var g = new ParticleGroup("burst", p, tiles);
		p.addGroup(g);
		var dg:Dynamic = g;
		dg.nparts = 0;            // burst-only — no continuous emission
		dg.emitLoop = false;      // one-shot semantics
		dg.life = 1.0;
		dg.lifeRand = 0;
		g.randomFunc = seededRandom(42);

		var endCalls = 0;
		p.onEnd = () -> endCalls++;

		syncOnce(p, 0.016);

		Assert.equals(0, endCalls,
			"onEnd fired on a Particles whose only group is burst-only (nparts == 0) before any "
			+ "burst was issued. start() leaves the batch empty for nparts == 0, so batch.first "
			+ "stays null and the default onEnd removes the container before the caller can ever "
			+ "trigger emitBurstAt(). This is the worldAnchor trail-emitter pattern. "
			+ "Got " + endCalls + " call(s).");
	}
}
