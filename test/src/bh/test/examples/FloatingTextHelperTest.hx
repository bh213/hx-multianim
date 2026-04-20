package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.ui.FloatingTextHelper;

/**
 * Unit tests for FloatingTextHelper.
 * Tests spawn, update, completion, clear, and position modes.
 */
class FloatingTextHelperTest extends BuilderTestBase {
	// A simple animatedPath: line upward 50px over 1 second with alpha fade
	static final TEST_MANIM = "
		paths { #testPath path { lineTo(0, -50) } }
		curves { #testAlpha curve { points: [(0, 1.0), (1.0, 0.0)] } }
		#testAnim animatedPath {
			path: testPath
			type: time
			duration: 1.0
			0.0: alphaCurve: testAlpha
		}
	";

	function createAnimPath():bh.paths.AnimatedPath {
		var builder = BuilderTestBase.builderFromSource(TEST_MANIM);
		return builder.createAnimatedPath("testAnim");
	}

	// ============== Initial state ==============

	@Test
	public function testInitialState():Void {
		var helper = new FloatingTextHelper();
		Assert.equals(0, helper.count);
	}

	// ============== spawn ==============

	@Test
	public function testSpawnCreatesInstance():Void {
		var parent = new h2d.Object();
		var helper = new FloatingTextHelper(parent);
		var font = hxd.res.DefaultFont.get();
		helper.spawn("-42", font, 100, 200, createAnimPath());
		Assert.equals(1, helper.count);
		Assert.equals(1, parent.numChildren);
	}

	@Test
	public function testSpawnWithColor():Void {
		var parent = new h2d.Object();
		var helper = new FloatingTextHelper(parent);
		var font = hxd.res.DefaultFont.get();
		var inst = helper.spawn("-42", font, 100, 200, createAnimPath(), 0xFF0000);
		Assert.equals(1, helper.count);
		Assert.notNull(inst.object);
	}

	// ============== spawnObject ==============

	@Test
	public function testSpawnObjectCreatesInstance():Void {
		var parent = new h2d.Object();
		var helper = new FloatingTextHelper(parent);
		var obj = new h2d.Object();
		helper.spawnObject(obj, 100, 200, createAnimPath());
		Assert.equals(1, helper.count);
		Assert.equals(1, parent.numChildren);
	}

	// ============== update ==============

	@Test
	public function testUpdateAdvancesPath():Void {
		var helper = new FloatingTextHelper(new h2d.Object());
		var font = hxd.res.DefaultFont.get();
		var inst = helper.spawn("-42", font, 100, 200, createAnimPath());
		helper.update(0.5);
		Assert.isFalse(inst.done);
		Assert.equals(1, helper.count);
	}

	@Test
	public function testCompletedInstanceRemoved():Void {
		var parent = new h2d.Object();
		var helper = new FloatingTextHelper(parent);
		var font = hxd.res.DefaultFont.get();
		helper.spawn("-42", font, 100, 200, createAnimPath());
		// Advance past duration (1.0s)
		helper.update(1.1);
		Assert.equals(0, helper.count);
	}

	@Test
	public function testOnCompleteCallback():Void {
		var helper = new FloatingTextHelper(new h2d.Object());
		var font = hxd.res.DefaultFont.get();
		var completed = false;
		var inst = helper.spawn("-42", font, 100, 200, createAnimPath());
		inst.onComplete = () -> completed = true;
		helper.update(1.1);
		Assert.isTrue(completed);
	}

	// ============== clear ==============

	@Test
	public function testClearRemovesAll():Void {
		var parent = new h2d.Object();
		var helper = new FloatingTextHelper(parent);
		var font = hxd.res.DefaultFont.get();
		helper.spawn("A", font, 0, 0, createAnimPath());
		helper.spawn("B", font, 0, 0, createAnimPath());
		Assert.equals(2, helper.count);
		helper.clear();
		Assert.equals(0, helper.count);
	}

	// ============== Multiple instances ==============

	@Test
	public function testMultipleInstancesIndependent():Void {
		var helper = new FloatingTextHelper(new h2d.Object());
		var font = hxd.res.DefaultFont.get();
		helper.spawn("A", font, 0, 0, createAnimPath());
		helper.spawn("B", font, 0, 0, createAnimPath());
		Assert.equals(2, helper.count);
		helper.update(0.5);
		Assert.equals(2, helper.count);
		helper.update(0.6); // past 1.0s
		Assert.equals(0, helper.count);
	}

	// ============== Position modes ==============

	@Test
	public function testRelativePositionMode():Void {
		var helper = new FloatingTextHelper(new h2d.Object());
		var font = hxd.res.DefaultFont.get();
		var inst = helper.spawn("-42", font, 100, 200, createAnimPath());
		helper.update(0.5);
		// At t=0.5 on lineTo(0, -50), position should be ~(0, -25)
		// So object should be at (100+0, 200-25) = (100, 175)
		Assert.isTrue(inst.object.y < 200); // moved upward
		Assert.floatEquals(100.0, inst.object.x);
	}

	@Test
	public function testAbsolutePositionMode():Void {
		var helper = new FloatingTextHelper(new h2d.Object());
		var font = hxd.res.DefaultFont.get();
		var inst = helper.spawn("-42", font, 100, 200, createAnimPath(), null, true);
		helper.update(0.5);
		// In absolute mode, object position IS the path position (not offset from start)
		// Path goes from (0,0) to (0,-50), at t=0.5 → ~(0, -25)
		Assert.isTrue(inst.object.y < 0);
	}

	// ============== No parent ==============

	@Test
	public function testNoParentDoesNotCrash():Void {
		var helper = new FloatingTextHelper(); // no parent
		var font = hxd.res.DefaultFont.get();
		var inst = helper.spawn("-42", font, 100, 200, createAnimPath());
		Assert.equals(1, helper.count);
		// Object is not added to any parent
		Assert.isNull(inst.object.parent);
	}

	// ============== Reentrant mutation from onComplete ==============

	@Test
	public function testOnCompleteCanCallClear():Void {
		var helper = new FloatingTextHelper(new h2d.Object());
		var font = hxd.res.DefaultFont.get();
		var a = helper.spawn("A", font, 0, 0, createAnimPath());
		helper.spawn("B", font, 0, 0, createAnimPath());
		helper.spawn("C", font, 0, 0, createAnimPath());
		a.onComplete = () -> helper.clear();
		// Advance past duration — A's onComplete will clear B and C.
		// Must not crash from reentrant array mutation during swap-remove.
		helper.update(1.1);
		Assert.equals(0, helper.count);
	}

	@Test
	public function testOnCompleteCanSpawn():Void {
		var helper = new FloatingTextHelper(new h2d.Object());
		var font = hxd.res.DefaultFont.get();
		var a = helper.spawn("A", font, 0, 0, createAnimPath());
		var respawned = false;
		a.onComplete = () -> {
			helper.spawn("A2", font, 0, 0, createAnimPath());
			respawned = true;
		};
		helper.update(1.1);
		Assert.isTrue(respawned);
		// A is gone; A2 was spawned inside onComplete — should be in the list.
		Assert.equals(1, helper.count);
	}

	// ============== Alpha from path ==============

	@Test
	public function testAlphaFromPath():Void {
		var helper = new FloatingTextHelper(new h2d.Object());
		var font = hxd.res.DefaultFont.get();
		var inst = helper.spawn("-42", font, 0, 0, createAnimPath());
		helper.update(0.5);
		// Alpha curve goes 1.0 → 0.0 linearly; at t=0.5 should be ~0.5
		Assert.isTrue(inst.object.alpha < 0.9);
		Assert.isTrue(inst.object.alpha > 0.1);
	}
}
