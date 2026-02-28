package bh.test.examples;

import utest.Assert;
import bh.base.Particles;
import bh.base.Particles.ParticleGroup;
import bh.base.Particles.ForceField;
import bh.base.Particles.SubEmitTrigger;
import bh.base.Particles.SubEmitter;

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

	static function createGroup(id:String, p:Particles):ParticleGroup {
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
		dg.emitLoop = false;
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
}
