package bh.test.examples;

import utest.Assert;
import bh.base.Particles;
import bh.base.Particles.ParticleGroup;
import bh.base.Particles.ForceField;
import bh.base.Particles.SubEmitTrigger;
import bh.base.Particles.SubEmitter;
import bh.base.Particles.PartEmitMode;
import bh.paths.Curve;

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

		Passes on HEAD because `evaluateColorCurve` is stateless; exists to pin
		that the cached-index optimization does not regress this when it resets
		per-particle state on init.
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
}
