package bh.test.examples;

import utest.Assert;
import bh.base.TweenManager;

/**
 * Non-visual unit tests for TweenManager:
 * basic tweens, sequences, groups, cancellation, and edge cases.
 */
class TweenManagerTest extends utest.Test {
	// ==================== Helpers ====================

	static function createObject():h2d.Object {
		return new h2d.Object();
	}

	// ==================== Basic Tween ====================

	@Test
	public function testBasicAlphaTween():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.alpha = 1.0;

		mgr.tween(obj, 1.0, [Alpha(0.0)]);

		// At t=0.5, alpha should be ~0.5 (linear)
		mgr.update(0.5);
		Assert.floatEquals(0.5, obj.alpha);

		// At t=1.0, alpha should be 0.0
		mgr.update(0.5);
		Assert.floatEquals(0.0, obj.alpha);
	}

	@Test
	public function testBasicPositionTween():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.x = 0;
		obj.y = 0;

		mgr.tween(obj, 1.0, [X(100.0), Y(200.0)]);

		mgr.update(0.5);
		Assert.floatEquals(50.0, obj.x);
		Assert.floatEquals(100.0, obj.y);

		mgr.update(0.5);
		Assert.floatEquals(100.0, obj.x);
		Assert.floatEquals(200.0, obj.y);
	}

	@Test
	public function testScaleProperty():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.scaleX = 1.0;
		obj.scaleY = 1.0;

		mgr.tween(obj, 1.0, [Scale(2.0)]);

		mgr.update(1.0);
		Assert.floatEquals(2.0, obj.scaleX);
		Assert.floatEquals(2.0, obj.scaleY);
	}

	@Test
	public function testScaleXYSeparate():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.scaleX = 1.0;
		obj.scaleY = 1.0;

		mgr.tween(obj, 1.0, [ScaleX(3.0), ScaleY(0.5)]);

		mgr.update(1.0);
		Assert.floatEquals(3.0, obj.scaleX);
		Assert.floatEquals(0.5, obj.scaleY);
	}

	@Test
	public function testRotationProperty():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.rotation = 0.0;

		mgr.tween(obj, 1.0, [Rotation(3.14)]);

		mgr.update(1.0);
		Assert.floatEquals(3.14, obj.rotation);
	}

	@Test
	public function testCustomProperty():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		var customValue:Float = 10.0;

		mgr.tween(obj, 1.0, [Custom(() -> customValue, (v) -> customValue = v, 50.0)]);

		mgr.update(0.5);
		Assert.floatEquals(30.0, customValue);

		mgr.update(0.5);
		Assert.floatEquals(50.0, customValue);
	}

	// ==================== Easing ====================

	@Test
	public function testEasing():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.alpha = 0.0;

		mgr.tween(obj, 1.0, [Alpha(1.0)], EaseInQuad);

		// EaseInQuad: t^2. At t=0.5, eased = 0.25
		mgr.update(0.5);
		Assert.floatEquals(0.25, obj.alpha);

		// At t=1.0, eased = 1.0
		mgr.update(0.5);
		Assert.floatEquals(1.0, obj.alpha);
	}

	// ==================== Completion Callback ====================

	@Test
	public function testOnComplete():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		var completed = false;

		mgr.tween(obj, 0.5, [Alpha(0.0)]).setOnComplete(() -> completed = true);

		mgr.update(0.3);
		Assert.isFalse(completed);

		mgr.update(0.3); // past duration
		Assert.isTrue(completed);
	}

	@Test
	public function testOnCompleteExactDuration():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		var completed = false;

		mgr.tween(obj, 1.0, [Alpha(0.0)]).setOnComplete(() -> completed = true);

		mgr.update(1.0);
		Assert.isTrue(completed);
	}

	// ==================== Cancellation ====================

	@Test
	public function testCancel():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.alpha = 1.0;

		var t = mgr.tween(obj, 1.0, [Alpha(0.0)]);

		mgr.update(0.5);
		Assert.floatEquals(0.5, obj.alpha);

		mgr.cancel(t);

		mgr.update(0.5);
		// Should stay at 0.5 (cancelled, no further updates)
		Assert.floatEquals(0.5, obj.alpha);
		Assert.isFalse(mgr.hasTweens(obj));
	}

	@Test
	public function testCancelAll():Void {
		var mgr = new TweenManager();
		var obj = createObject();

		mgr.tween(obj, 1.0, [Alpha(0.0)]);
		mgr.tween(obj, 1.0, [X(100.0)]);

		Assert.isTrue(mgr.hasTweens(obj));

		mgr.cancelAll(obj);
		mgr.update(0.1); // clean up cancelled

		Assert.isFalse(mgr.hasTweens(obj));
	}

	@Test
	public function testCancelAllChildren():Void {
		var mgr = new TweenManager();
		var parent = createObject();
		var child = createObject();
		parent.addChild(child);

		var other = createObject();

		mgr.tween(child, 1.0, [Alpha(0.0)]);
		mgr.tween(other, 1.0, [Alpha(0.0)]);

		mgr.cancelAllChildren(parent);
		mgr.update(0.1); // clean up cancelled

		Assert.isFalse(mgr.hasTweens(child));
		Assert.isTrue(mgr.hasTweens(other));
	}

	@Test
	public function testCancelAllChildrenIncludesRoot():Void {
		var mgr = new TweenManager();
		var root = createObject();

		mgr.tween(root, 1.0, [Alpha(0.0)]);

		mgr.cancelAllChildren(root);
		mgr.update(0.1);

		Assert.isFalse(mgr.hasTweens(root));
	}

	@Test
	public function testClear():Void {
		var mgr = new TweenManager();
		var obj1 = createObject();
		var obj2 = createObject();

		mgr.tween(obj1, 1.0, [Alpha(0.0)]);
		mgr.tween(obj2, 1.0, [X(100.0)]);

		mgr.clear();

		Assert.isFalse(mgr.hasTweens(obj1));
		Assert.isFalse(mgr.hasTweens(obj2));
	}

	// ==================== Interrupted Tweens ====================

	@Test
	public function testInterruptedTweenPicksUpCurrentValue():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.alpha = 1.0;

		var t1 = mgr.tween(obj, 1.0, [Alpha(0.0)]);

		mgr.update(0.5);
		Assert.floatEquals(0.5, obj.alpha);

		// Cancel first tween and start a new one back to 1.0
		mgr.cancel(t1);
		mgr.tween(obj, 1.0, [Alpha(1.0)]);

		// New tween should start from current value (0.5)
		mgr.update(0.5);
		Assert.floatEquals(0.75, obj.alpha);

		mgr.update(0.5);
		Assert.floatEquals(1.0, obj.alpha);
	}

	// ==================== Sequence ====================

	@Test
	public function testSequence():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.x = 0;

		var t1 = mgr.createTween(obj, 0.5, [X(100.0)]);
		var t2 = mgr.createTween(obj, 0.5, [X(200.0)]);
		mgr.sequence([t1, t2]);

		// First tween: 0 -> 100 over 0.5s
		mgr.update(0.5);
		Assert.floatEquals(100.0, obj.x);

		// Second tween: 100 -> 200 over 0.5s (from captured at start)
		mgr.update(0.25);
		Assert.floatEquals(150.0, obj.x);

		mgr.update(0.25);
		Assert.floatEquals(200.0, obj.x);
	}

	@Test
	public function testSequenceOnComplete():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		var completed = false;

		var t1 = mgr.createTween(obj, 0.5, [Alpha(0.5)]);
		var t2 = mgr.createTween(obj, 0.5, [Alpha(0.0)]);
		mgr.sequence([t1, t2]).setOnComplete(() -> completed = true);

		mgr.update(0.5);
		Assert.isFalse(completed);

		mgr.update(0.5);
		Assert.isTrue(completed);
	}

	@Test
	public function testSequenceIndividualCallbacks():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		var firstDone = false;
		var secondDone = false;

		var t1 = mgr.createTween(obj, 0.5, [X(50.0)]);
		t1.setOnComplete(() -> firstDone = true);
		var t2 = mgr.createTween(obj, 0.5, [X(100.0)]);
		t2.setOnComplete(() -> secondDone = true);
		mgr.sequence([t1, t2]);

		mgr.update(0.5);
		Assert.isTrue(firstDone);
		Assert.isFalse(secondDone);

		mgr.update(0.5);
		Assert.isTrue(secondDone);
	}

	@Test
	public function testSequencePassesOverflowDt():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.x = 0;

		var t1 = mgr.createTween(obj, 0.3, [X(100.0)]);
		var t2 = mgr.createTween(obj, 0.3, [X(200.0)]);
		mgr.sequence([t1, t2]);

		// Update by 0.5 — first tween (0.3s) finishes, overflow 0.2s goes to second
		mgr.update(0.5);
		// Second tween: from=100, to=200. t = 0.2/0.3 = 0.667 → value ≈ 166.7
		Assert.isTrue(obj.x > 160.0 && obj.x < 170.0);
	}

	// ==================== Group ====================

	@Test
	public function testGroup():Void {
		var mgr = new TweenManager();
		var obj1 = createObject();
		var obj2 = createObject();
		obj1.alpha = 1.0;
		obj2.x = 0;

		var t1 = mgr.createTween(obj1, 1.0, [Alpha(0.0)]);
		var t2 = mgr.createTween(obj2, 1.0, [X(100.0)]);
		mgr.group([t1, t2]);

		mgr.update(0.5);
		Assert.floatEquals(0.5, obj1.alpha);
		Assert.floatEquals(50.0, obj2.x);

		mgr.update(0.5);
		Assert.floatEquals(0.0, obj1.alpha);
		Assert.floatEquals(100.0, obj2.x);
	}

	@Test
	public function testGroupOnComplete():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		var completed = false;

		var t1 = mgr.createTween(obj, 0.5, [Alpha(0.0)]);
		var t2 = mgr.createTween(obj, 1.0, [X(100.0)]);
		mgr.group([t1, t2]).setOnComplete(() -> completed = true);

		mgr.update(0.5);
		Assert.isFalse(completed); // t2 still running

		mgr.update(0.5);
		Assert.isTrue(completed); // both done
	}

	@Test
	public function testGroupDifferentDurations():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.alpha = 1.0;
		obj.x = 0;

		var t1 = mgr.createTween(obj, 0.5, [Alpha(0.0)]); // finishes first
		var t2 = mgr.createTween(obj, 1.0, [X(100.0)]); // finishes second
		mgr.group([t1, t2]);

		mgr.update(0.5);
		Assert.floatEquals(0.0, obj.alpha); // t1 done
		Assert.floatEquals(50.0, obj.x); // t2 halfway

		mgr.update(0.5);
		// Alpha should stay at 0 (t1 is done, no further updates)
		Assert.floatEquals(0.0, obj.alpha);
		Assert.floatEquals(100.0, obj.x); // t2 done
	}

	// ==================== Convenience Methods ====================

	@Test
	public function testFadeIn():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.alpha = 0.0;

		mgr.fadeIn(obj, 1.0);

		mgr.update(1.0);
		Assert.floatEquals(1.0, obj.alpha);
	}

	@Test
	public function testFadeOut():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.alpha = 1.0;

		mgr.fadeOut(obj, 1.0);

		mgr.update(1.0);
		Assert.floatEquals(0.0, obj.alpha);
	}

	@Test
	public function testFadeOutRemoveOnComplete():Void {
		var mgr = new TweenManager();
		var parent = createObject();
		var obj = createObject();
		parent.addChild(obj);

		Assert.notNull(obj.parent);

		mgr.fadeOut(obj, 0.5, null, true);

		mgr.update(0.5);
		Assert.isNull(obj.parent);
	}

	@Test
	public function testMoveTo():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.x = 10;
		obj.y = 20;

		mgr.moveTo(obj, 100.0, 200.0, 1.0);

		mgr.update(1.0);
		Assert.floatEquals(100.0, obj.x);
		Assert.floatEquals(200.0, obj.y);
	}

	@Test
	public function testScaleTo():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.scaleX = 1.0;
		obj.scaleY = 1.0;

		mgr.scaleTo(obj, 3.0, 1.0);

		mgr.update(1.0);
		Assert.floatEquals(3.0, obj.scaleX);
		Assert.floatEquals(3.0, obj.scaleY);
	}

	// ==================== Edge Cases ====================

	@Test
	public function testZeroDuration():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.alpha = 1.0;
		var completed = false;

		mgr.tween(obj, 0.0, [Alpha(0.0)]).setOnComplete(() -> completed = true);

		mgr.update(0.016); // any dt should finish immediately
		Assert.floatEquals(0.0, obj.alpha);
		Assert.isTrue(completed);
	}

	@Test
	public function testAlreadyAtTarget():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.alpha = 0.5;

		mgr.tween(obj, 1.0, [Alpha(0.5)]); // already at target

		mgr.update(0.5);
		Assert.floatEquals(0.5, obj.alpha); // stays at same value

		mgr.update(0.5);
		Assert.floatEquals(0.5, obj.alpha);
	}

	@Test
	public function testMultiplePropertiesSameObject():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.x = 0;
		obj.y = 0;
		obj.alpha = 1.0;

		mgr.tween(obj, 1.0, [X(100.0), Y(200.0), Alpha(0.0)]);

		mgr.update(1.0);
		Assert.floatEquals(100.0, obj.x);
		Assert.floatEquals(200.0, obj.y);
		Assert.floatEquals(0.0, obj.alpha);
	}

	@Test
	public function testTweenRemovedAfterCompletion():Void {
		var mgr = new TweenManager();
		var obj = createObject();

		mgr.tween(obj, 0.5, [Alpha(0.0)]);
		Assert.isTrue(mgr.hasTweens(obj));

		mgr.update(0.6);
		Assert.isFalse(mgr.hasTweens(obj));
	}

	@Test
	public function testMultipleTweensOnSameObject():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.x = 0;
		obj.alpha = 1.0;

		mgr.tween(obj, 1.0, [X(100.0)]);
		mgr.tween(obj, 1.0, [Alpha(0.0)]);

		mgr.update(0.5);
		Assert.floatEquals(50.0, obj.x);
		Assert.floatEquals(0.5, obj.alpha);
	}

	@Test
	public function testLargeDtOvershoot():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.x = 0;

		mgr.tween(obj, 1.0, [X(100.0)]);

		mgr.update(5.0); // way past duration
		Assert.floatEquals(100.0, obj.x); // clamped to target, not overshooting
	}

	@Test
	public function testCancelDoesNotFireCallback():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		var completed = false;

		var t = mgr.tween(obj, 1.0, [Alpha(0.0)]).setOnComplete(() -> completed = true);

		mgr.cancel(t);
		mgr.update(2.0);

		Assert.isFalse(completed);
	}

	@Test
	public function testHasTweensReturnsFalseForUnknownObject():Void {
		var mgr = new TweenManager();
		var obj = createObject();

		Assert.isFalse(mgr.hasTweens(obj));
	}

	// ==================== createTween vs tween ====================

	@Test
	public function testCreateTweenDoesNotAutoStart():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.alpha = 1.0;

		// createTween does NOT add to manager — it's for manual sequence/group use
		var t = mgr.createTween(obj, 1.0, [Alpha(0.0)]);

		mgr.update(1.0);
		// Object should be unchanged since tween was not added to manager
		Assert.floatEquals(1.0, obj.alpha);
		Assert.isFalse(mgr.hasTweens(obj));

		// Verify the tween was created properly
		Assert.notNull(t);
		Assert.equals(obj, t.target);
	}
}
