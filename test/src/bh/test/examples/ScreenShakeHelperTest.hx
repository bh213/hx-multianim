package bh.test.examples;

import utest.Assert;
import bh.ui.ScreenShakeHelper;

/**
 * Non-visual unit tests for ScreenShakeHelper — focused on the delta-tracking
 * fix: gameplay motion of the target must be preserved across shake updates,
 * and stop() / natural expiry must remove only the shake's own residual, not
 * whatever the target happened to be at when construction ran.
 */
class ScreenShakeHelperTest extends utest.Test {
	static inline var EPS:Float = 0.0001;

	static function createObject():h2d.Object {
		return new h2d.Object();
	}

	// ==================== Gameplay motion preservation ====================

	@Test
	public function testGameplayMotionDuringShakeIsPreserved():Void {
		// Target starts at origin, shake runs for several frames, during which
		// gameplay moves the target. Without delta tracking the shake would keep
		// pinning it back to (0, 0) + offset.
		var obj = createObject();
		obj.x = 0;
		obj.y = 0;
		var shake = new ScreenShakeHelper(obj);

		shake.shake(5.0, 1.0);
		shake.update(0.016); // frame 1 — shake applies some offset

		// Gameplay moves target 100px right between frames.
		var offsetAfterFrame1X = obj.x;
		var offsetAfterFrame1Y = obj.y;
		obj.x += 100.0;
		obj.y += 50.0;

		shake.update(0.016); // frame 2 — must preserve the +100/+50 from gameplay

		// The gameplay displacement must still be in place. Formally:
		// new position = old position + (newDx - oldDx) + gameplayDelta
		// i.e. difference between frame-2 and frame-1 positions, minus the
		// shake delta, equals the gameplay delta.
		var shakeDeltaX = obj.x - (offsetAfterFrame1X + 100.0);
		var shakeDeltaY = obj.y - (offsetAfterFrame1Y + 50.0);

		// The shake delta should be bounded by 2 * intensity (max swing from
		// one random angle to another). Intensity=5 → max |delta| ≤ 10.
		Assert.isTrue(Math.abs(shakeDeltaX) <= 10.0 + EPS,
			'shakeDeltaX=$shakeDeltaX exceeds 2*intensity bound (10.0)');
		Assert.isTrue(Math.abs(shakeDeltaY) <= 10.0 + EPS,
			'shakeDeltaY=$shakeDeltaY exceeds 2*intensity bound (10.0)');
	}

	@Test
	public function testStopRemovesOnlyShakeOffsetNotGameplayMotion():Void {
		// Target is moved by gameplay after the shake was constructed. When
		// stop() runs, the target must end up at (gameplayX, gameplayY), NOT
		// at (0, 0) (the constructor-captured "original" position from the
		// old implementation).
		var obj = createObject();
		obj.x = 0;
		obj.y = 0;
		var shake = new ScreenShakeHelper(obj);

		shake.shake(8.0, 1.0);
		shake.update(0.016);

		// Simulate a large camera scroll during the shake.
		obj.x += 500.0;
		obj.y += 300.0;

		shake.update(0.016);
		shake.stop();

		// After stop, the residual shake offset must be gone, but the
		// gameplay motion must be preserved → target ends at exactly
		// (500, 300).
		Assert.floatEquals(500.0, obj.x);
		Assert.floatEquals(300.0, obj.y);
		Assert.isFalse(shake.isShaking);
	}

	@Test
	public function testNaturalExpiryRemovesResidualOffset():Void {
		// When the last shake expires naturally (not via stop()), the next
		// update() call should clean up the residual offset.
		var obj = createObject();
		obj.x = 10.0;
		obj.y = 20.0;
		var shake = new ScreenShakeHelper(obj);

		shake.shake(5.0, 0.1);
		shake.update(0.05); // mid-shake, offset applied
		Assert.notEquals(10.0, obj.x); // shake is actively offsetting

		shake.update(0.1); // shake expires this frame
		// After expiry the shake list is empty — but the final delta from the
		// last frame before expiry might still be on the object until the
		// next update() cleans it up.
		shake.update(0.016); // cleanup frame

		Assert.floatEquals(10.0, obj.x);
		Assert.floatEquals(20.0, obj.y);
		Assert.isFalse(shake.isShaking);
	}

	@Test
	public function testStopWithNoActiveShakeIsNoop():Void {
		// stop() when nothing is running must not move the target.
		var obj = createObject();
		obj.x = 42.0;
		obj.y = 99.0;
		var shake = new ScreenShakeHelper(obj);

		shake.stop();

		Assert.floatEquals(42.0, obj.x);
		Assert.floatEquals(99.0, obj.y);
	}

	@Test
	public function testEmptyUpdateIsNoopOnPristineTarget():Void {
		// update() with no active shakes and no prior offset must not touch
		// the target (important — an eager `target.x -= 0` would still
		// trigger Heaps' transform invalidation).
		var obj = createObject();
		obj.x = 123.0;
		obj.y = 456.0;
		var shake = new ScreenShakeHelper(obj);

		shake.update(0.016);
		shake.update(0.016);
		shake.update(0.016);

		Assert.floatEquals(123.0, obj.x);
		Assert.floatEquals(456.0, obj.y);
	}

	// ==================== Shake bounds / intensity ====================

	@Test
	public function testShakeOffsetBoundedByIntensity():Void {
		// Across many frames the per-frame shake delta must never exceed the
		// intensity bound. We verify frame-to-frame deltas stay within
		// 2 * intensity (since angles are random, consecutive frames can
		// swing from +intensity to -intensity).
		var obj = createObject();
		obj.x = 0;
		obj.y = 0;
		var shake = new ScreenShakeHelper(obj);

		shake.shake(10.0, 5.0);

		var prevX = obj.x;
		var prevY = obj.y;
		for (i in 0...20) {
			shake.update(0.1);
			// Each frame the shake adds a delta of ≤ 2 * intensity * factor
			// (factor ≤ 1, so ≤ 20 per axis).
			var dx = obj.x - prevX;
			var dy = obj.y - prevY;
			Assert.isTrue(Math.abs(dx) <= 20.0 + EPS,
				'frame $i dx=$dx exceeds 2*intensity bound');
			Assert.isTrue(Math.abs(dy) <= 20.0 + EPS,
				'frame $i dy=$dy exceeds 2*intensity bound');
			prevX = obj.x;
			prevY = obj.y;
		}
	}

	@Test
	public function testDirectionalShakeOnlyMovesOneAxis():Void {
		// Horizontal-only shake must not move target.y (dirY=0).
		var obj = createObject();
		obj.x = 0;
		obj.y = 0;
		var shake = new ScreenShakeHelper(obj);

		shake.shakeDirectional(10.0, 1.0, 1.0, 0.0);

		for (i in 0...10) {
			shake.update(0.05);
			Assert.floatEquals(0.0, obj.y, 'vertical-locked shake moved y on frame $i');
		}
	}

	// ==================== Additive stacking ====================

	@Test
	public function testConcurrentShakesDoNotLeakOffsetOnExpiry():Void {
		// Two concurrent shakes. When both expire and the cleanup frame
		// runs, the target returns exactly to its baseline position.
		var obj = createObject();
		obj.x = 7.0;
		obj.y = 11.0;
		var shake = new ScreenShakeHelper(obj);

		shake.shake(5.0, 0.1);
		shake.shake(3.0, 0.15);
		Assert.isTrue(shake.isShaking);

		// Run long enough for both to expire, then one cleanup frame.
		shake.update(0.2);
		shake.update(0.016);

		Assert.floatEquals(7.0, obj.x);
		Assert.floatEquals(11.0, obj.y);
		Assert.isFalse(shake.isShaking);
	}

	@Test
	public function testIsShakingFlag():Void {
		var obj = createObject();
		var shake = new ScreenShakeHelper(obj);

		Assert.isFalse(shake.isShaking);

		shake.shake(5.0, 0.1);
		Assert.isTrue(shake.isShaking);

		shake.update(0.2); // expires
		Assert.isFalse(shake.isShaking);
	}
}
