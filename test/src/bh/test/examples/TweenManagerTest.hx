package bh.test.examples;

import utest.Assert;
import bh.base.TweenManager;
import bh.base.TweenManager.Tween;
import bh.base.TweenManager.TweenPropertyEntry;
import bh.base.TweenManager.TweenSequence;
import bh.base.TweenManager.TweenGroup;

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
	public function testCancelAllPropagatesToSequenceWhenAllTweensShareTarget():Void {
		var mgr = new TweenManager();
		var obj = createObject();

		var t1 = mgr.createTween(obj, 1.0, [X(100.0)]);
		var t2 = mgr.createTween(obj, 1.0, [Y(200.0)]);
		var seq = mgr.sequence([t1, t2]);

		mgr.cancelAll(obj);

		Assert.isTrue(seq.cancelled,
			"sequence whose tweens all target obj must be cancelled by cancelAll(obj)");
		Assert.isTrue(t1.cancelled);
		Assert.isTrue(t2.cancelled);
	}

	@Test
	public function testCancelAllPropagatesToGroupWhenAllTweensShareTarget():Void {
		var mgr = new TweenManager();
		var obj = createObject();

		var t1 = mgr.createTween(obj, 1.0, [X(100.0)]);
		var t2 = mgr.createTween(obj, 1.0, [Y(200.0)]);
		var grp = mgr.group([t1, t2]);

		mgr.cancelAll(obj);

		Assert.isTrue(grp.cancelled,
			"group whose tweens all target obj must be cancelled by cancelAll(obj)");
		Assert.isTrue(t1.cancelled);
		Assert.isTrue(t2.cancelled);
	}

	@Test
	public function testCancelAllLeavesSequenceAliveWhenSomeTweensSurvive():Void {
		var mgr = new TweenManager();
		var objA = createObject();
		var objB = createObject();

		var t1 = mgr.createTween(objA, 1.0, [X(100.0)]);
		var t2 = mgr.createTween(objB, 1.0, [Y(200.0)]);
		var seq = mgr.sequence([t1, t2]);

		mgr.cancelAll(objA);

		Assert.isTrue(t1.cancelled);
		Assert.isFalse(t2.cancelled);
		Assert.isFalse(seq.cancelled,
			"sequence with surviving non-cancelled tween must not be cancelled");
	}

	// `TweenSequence.getTargets()` / `TweenGroup.getTargets()` were the lookup
	// used by the removed `TweenManager.cancelAll` "is the sequence empty" probe.
	// Each call allocates a fresh `Array<h2d.Object>` and does O(n²) `contains`-
	// based dedup. With the probe gone there are zero callers anywhere across
	// the dotabota tree (sibling repos included). Keeping the methods around is
	// an attractive nuisance — anyone wiring up `mgr.handles[i] match HSequence ->
	// seq.getTargets()` reintroduces the same per-event allocation cliff the
	// rc.5 fix removed. This test pins both surfaces as deliberately absent.
	@Test
	public function testTweenSequenceAndGroupHaveNoGetTargetsMethod():Void {
		var seqFields = Type.getInstanceFields(TweenSequence);
		Assert.isFalse(seqFields.indexOf("getTargets") != -1,
			"TweenSequence must not expose getTargets() — it allocates a fresh Array<h2d.Object> "
			+ "with O(n²) dedup and has no callers anywhere. The previous internal caller in "
			+ "TweenManager.cancelAll was removed in rc.5. Found field on instance: "
			+ seqFields.filter(f -> f == "getTargets").join(","));

		var groupFields = Type.getInstanceFields(TweenGroup);
		Assert.isFalse(groupFields.indexOf("getTargets") != -1,
			"TweenGroup must not expose getTargets() — it allocates a fresh Array<h2d.Object> "
			+ "with O(n²) dedup and has no callers anywhere. The previous internal caller in "
			+ "TweenManager.cancelAll was removed in rc.5. Found field on instance: "
			+ groupFields.filter(f -> f == "getTargets").join(","));
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

	// ==================== Finish on cancelled ====================

	@Test
	public function testCancelledSequenceFinishDoesNotFireSequenceOnComplete():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		var seqCompleted = false;

		var t1 = mgr.createTween(obj, 0.5, [X(100.0)]);
		var t2 = mgr.createTween(obj, 0.5, [X(200.0)]);
		var seq = mgr.sequence([t1, t2]).setOnComplete(() -> seqCompleted = true);

		seq.cancel();
		seq.finish();

		Assert.isFalse(seqCompleted,
			"Cancelled sequence's onComplete must not fire on finish(); contract: cancelled tweens do not fire onComplete.");
	}

	@Test
	public function testCancelledSequenceFinishDoesNotFirePerTweenOnComplete():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		var t1Completed = false;
		var t2Completed = false;

		var t1 = mgr.createTween(obj, 0.5, [X(100.0)]).setOnComplete(() -> t1Completed = true);
		var t2 = mgr.createTween(obj, 0.5, [X(200.0)]).setOnComplete(() -> t2Completed = true);
		var seq = mgr.sequence([t1, t2]);

		seq.cancel();
		seq.finish();

		Assert.isFalse(t1Completed,
			"Cancelled sequence must not fire onComplete on its current tween via finish().");
		Assert.isFalse(t2Completed,
			"Cancelled sequence must not fire onComplete on later tweens via finish().");
	}

	@Test
	public function testSequenceFinishSkipsIndividuallyCancelledCurrentTween():Void {
		var mgr = new TweenManager();
		var objA = createObject();
		var objB = createObject();
		var t1Completed = false;
		var t2Completed = false;

		// Sequence stays alive; only the first (current) tween is cancelled.
		// Mirrors cancelAll(target=objA) selectively cancelling just t1.
		var t1 = mgr.createTween(objA, 0.5, [X(100.0)]).setOnComplete(() -> t1Completed = true);
		var t2 = mgr.createTween(objB, 0.5, [X(200.0)]).setOnComplete(() -> t2Completed = true);
		var seq = mgr.sequence([t1, t2]);

		t1.cancel();
		seq.finish();

		Assert.isFalse(t1Completed,
			"Individually cancelled tween in a still-alive sequence must not fire onComplete on sequence.finish().");
		Assert.isTrue(t2Completed,
			"Non-cancelled later tween in a still-alive sequence should fire onComplete on sequence.finish().");
	}

	@Test
	public function testSequenceStepSkipsIndividuallyCancelledCurrentTween():Void {
		var mgr = new TweenManager();
		var objA = createObject();
		var objB = createObject();
		var t1Completed = false;
		var t2Completed = false;

		// Sequence stays alive; only the first (current) tween is cancelled.
		// Mirrors cancelAll(target=objA) selectively cancelling just t1, then
		// the natural TweenManager.update(dt) → TweenSequence.step(dt) tick.
		var t1 = mgr.createTween(objA, 0.5, [X(100.0)]).setOnComplete(() -> t1Completed = true);
		var t2 = mgr.createTween(objB, 0.5, [X(200.0)]).setOnComplete(() -> t2Completed = true);
		mgr.sequence([t1, t2]);

		t1.cancel();
		mgr.update(0.5);

		Assert.isFalse(t1Completed,
			"Individually cancelled current tween must not fire onComplete via sequence.step().");
		mgr.update(0.5);
		Assert.isTrue(t2Completed,
			"Non-cancelled later tween should still complete and fire onComplete after the sequence advances past the cancelled one.");
	}

	@Test
	public function testCancelledGroupFinishDoesNotFireGroupOnComplete():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		var grpCompleted = false;

		var t1 = mgr.createTween(obj, 0.5, [Alpha(0.0)]);
		var t2 = mgr.createTween(obj, 1.0, [X(100.0)]);
		var group = mgr.group([t1, t2]).setOnComplete(() -> grpCompleted = true);

		group.cancel();
		group.finish();

		Assert.isFalse(grpCompleted,
			"Cancelled group's onComplete must not fire on finish(); contract: cancelled tweens do not fire onComplete.");
	}

	@Test
	public function testCancelledGroupFinishDoesNotFirePerTweenOnComplete():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		var t1Completed = false;
		var t2Completed = false;

		var t1 = mgr.createTween(obj, 0.5, [Alpha(0.0)]).setOnComplete(() -> t1Completed = true);
		var t2 = mgr.createTween(obj, 1.0, [X(100.0)]).setOnComplete(() -> t2Completed = true);
		var group = mgr.group([t1, t2]);

		group.cancel();
		group.finish();

		Assert.isFalse(t1Completed,
			"Cancelled group must not fire per-tween onComplete via finish().");
		Assert.isFalse(t2Completed,
			"Cancelled group must not fire per-tween onComplete via finish().");
	}

	@Test
	public function testGroupFinishSkipsIndividuallyCancelledTween():Void {
		var mgr = new TweenManager();
		var objA = createObject();
		var objB = createObject();
		var t1Completed = false;
		var t2Completed = false;

		// Group stays alive; only one child tween is cancelled. Mirrors
		// cancelAll(target=objA) cancelling just t1 — group.cancel() is not
		// invoked because not all child tweens share the cancelled target.
		var t1 = mgr.createTween(objA, 0.5, [Alpha(0.0)]).setOnComplete(() -> t1Completed = true);
		var t2 = mgr.createTween(objB, 1.0, [X(100.0)]).setOnComplete(() -> t2Completed = true);
		var group = mgr.group([t1, t2]);

		t1.cancel();
		group.finish();

		Assert.isFalse(t1Completed,
			"Individually cancelled tween in a still-alive group must not fire onComplete on group.finish().");
		Assert.isTrue(t2Completed,
			"Non-cancelled tween in a still-alive group should fire onComplete on group.finish().");
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

	@Test
	public function testSequenceCancelMarksAllQueuedTweensAsCancelled():Void {
		var mgr = new TweenManager();
		var obj = createObject();

		var t1 = mgr.createTween(obj, 0.5, [X(50.0)]);
		var t2 = mgr.createTween(obj, 0.5, [X(100.0)]);
		var t3 = mgr.createTween(obj, 0.5, [X(150.0)]);
		var seq = mgr.sequence([t1, t2, t3]);

		// Advance partway into t1 so currentIndex stays at 0.
		mgr.update(0.25);

		seq.cancel();

		Assert.isTrue(seq.cancelled);
		Assert.isTrue(t1.cancelled);
		Assert.isTrue(t2.cancelled, "queued t2 must be cancelled when sequence is cancelled");
		Assert.isTrue(t3.cancelled, "queued t3 must be cancelled when sequence is cancelled");
	}

	@Test
	public function testSequenceFinishAfterCancelDoesNotFirePerTweenCallbacks():Void {
		var mgr = new TweenManager();
		var obj = createObject();

		var t1Done = false;
		var t2Done = false;
		var t3Done = false;
		var seqDone = false;

		var t1 = mgr.createTween(obj, 0.5, [X(50.0)]);
		t1.setOnComplete(() -> t1Done = true);
		var t2 = mgr.createTween(obj, 0.5, [X(100.0)]);
		t2.setOnComplete(() -> t2Done = true);
		var t3 = mgr.createTween(obj, 0.5, [X(150.0)]);
		t3.setOnComplete(() -> t3Done = true);
		var seq = mgr.sequence([t1, t2, t3]).setOnComplete(() -> seqDone = true);

		mgr.update(0.25);

		seq.cancel();
		seq.finish();

		// Contract: cancelled tweens do not fire onComplete (matches manager loop semantics).
		Assert.isFalse(t1Done, "current tween onComplete must not fire after cancel");
		Assert.isFalse(t2Done, "queued tween onComplete must not fire after cancel");
		Assert.isFalse(t3Done, "queued tween onComplete must not fire after cancel");
		Assert.isFalse(seqDone, "sequence onComplete must not fire after cancel");
	}

	@Test
	public function testSequenceFinishAfterCancelDoesNotResumeQueuedTweenSideEffects():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.x = 0;

		var t1 = mgr.createTween(obj, 0.5, [X(100.0)]);
		var t2 = mgr.createTween(obj, 0.5, [X(200.0)]);
		var seq = mgr.sequence([t1, t2]);

		// Run t1 partway so it has a captured "from".
		mgr.update(0.25);
		final xAtCancel = obj.x;

		seq.cancel();
		seq.finish();

		// After cancel, neither t1 nor t2 should jump to their final state — the
		// sequence is dead. (Pre-fix: finish() called t2.finish() → obj.x = 200.)
		Assert.floatEquals(xAtCancel, obj.x);
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

	// ==================== Allocation watchdog ====================

	// TweenPropertyEntry is acquired 1-7× per Tween construction (one per
	// TweenProperty in the array, with `Scale(v)` expanding to two entries).
	// With pooling, completed tweens return their entries to a shared free-list
	// so subsequent tweens of the same shape allocate 0. Pre-warm makes the
	// assertion deterministic regardless of test execution order.
	@Test
	public function testTweenPropertyEntryAllocationsScaleWithPropertyCount():Void {
		var mgr = new TweenManager();
		var obj = createObject();

		// Pre-warm: run 5 × 3-property tweens to completion so the pool holds
		// at least 15 reusable entries.
		for (i in 0...5)
			mgr.tween(obj, 0.1, [X(i + 0.0), Y(i + 0.0), Alpha(0.5)]);
		mgr.update(0.2);
		final baseline = TweenPropertyEntry.creationCount;

		// 5 tweens × 3 properties = 15 entries acquired; all should come from pool.
		for (i in 0...5) {
			mgr.tween(obj, 1.0, [X(100.0 + i), Y(100.0 + i), Alpha(0.5)]);
		}

		final delta = TweenPropertyEntry.creationCount - baseline;
		Assert.equals(0, delta,
			"With a warm pool, 5 tweens × 3 properties should produce 0 fresh "
			+ "TweenPropertyEntry allocations. Got " + delta
			+ " — either the pool regressed or someone double-allocates per property.");
	}

	@Test
	public function testTweenScaleExpandsToTwoEntries():Void {
		var mgr = new TweenManager();
		var obj = createObject();

		// Pre-warm: complete a Scale tween so the pool holds at least 2 entries.
		mgr.tween(obj, 0.1, [Scale(1.0)]);
		mgr.update(0.2);
		final baseline = TweenPropertyEntry.creationCount;

		// `Scale(v)` expands to ScaleX + ScaleY internally — both must come
		// from the pool, so creation delta is 0. Behavioral expansion is
		// covered separately by `testScaleProperty`.
		mgr.tween(obj, 1.0, [Scale(2.0)]);

		final delta = TweenPropertyEntry.creationCount - baseline;
		Assert.equals(0, delta,
			"Scale(v) must reuse two pooled entries (ScaleX + ScaleY) rather than "
			+ "allocating fresh. Got " + delta + " — if 1, the pool is shorting one "
			+ "side of the Scale expansion; if 2, the pool is being bypassed entirely.");
	}

	// Real-world UI churn: tweens complete continuously (card fades, draw/discard,
	// screen transitions) and new ones replace them. Without a pool, every new
	// tween allocates fresh TweenPropertyEntry instances even though identical
	// shapes were just discarded. After pooling, completed tweens return their
	// entries to a free-list so subsequent tweens reuse them with zero allocs.
	@Test
	public function testTweenPropertyEntriesAreReusedAfterTweenCompletes():Void {
		var mgr = new TweenManager();
		var obj = createObject();

		// Prime the pool: run a tween to completion so its 3 entries are released.
		mgr.tween(obj, 0.1, [X(50.0), Y(60.0), Alpha(0.5)]);
		mgr.update(0.2); // exceeds duration → tween completes → entries recycled

		final baseline = TweenPropertyEntry.creationCount;

		// A second tween with the same property shape should fully reuse the pool.
		mgr.tween(obj, 0.1, [X(70.0), Y(80.0), Alpha(0.7)]);

		final delta = TweenPropertyEntry.creationCount - baseline;
		Assert.equals(0, delta,
			"After a tween completes, its TweenPropertyEntries must return to a pool so "
			+ "the next tween of the same shape reuses them. Got " + delta + " fresh "
			+ "allocations — this is the per-frame churn vector hit by UI fades and "
			+ "card animations.");
	}

	// Sequences and groups own multiple Tweens; their entries must also recycle
	// when the wrapper completes. Without per-child release in HSequence/HGroup
	// teardown, sequence/group churn would dominate even after HTween is fixed
	// (transitions and modal overlays are sequence- and group-driven).
	@Test
	public function testSequenceTweenEntriesAreReusedAfterCompletion():Void {
		var mgr = new TweenManager();
		var obj = createObject();

		// Prime: a sequence of two tweens, run to completion.
		var t1 = mgr.createTween(obj, 0.1, [X(10.0), Alpha(0.5)]);
		var t2 = mgr.createTween(obj, 0.1, [Y(20.0)]);
		mgr.sequence([t1, t2]);
		mgr.update(0.5); // both tweens finish → 3 entries released

		final baseline = TweenPropertyEntry.creationCount;

		// Fresh sequence with the same shape should pull entries from the pool.
		var t3 = mgr.createTween(obj, 0.1, [X(11.0), Alpha(0.6)]);
		var t4 = mgr.createTween(obj, 0.1, [Y(21.0)]);
		mgr.sequence([t3, t4]);

		final delta = TweenPropertyEntry.creationCount - baseline;
		Assert.equals(0, delta,
			"Sequence child tweens must release their TweenPropertyEntries to the pool "
			+ "when the sequence completes. Got " + delta + " fresh allocations.");
	}

	// After a tween completes, the Tween instance itself should return to a
	// pool so that the next tween() / createTween() / fadeIn() / fadeOut() /
	// moveTo() / scaleTo() call reuses it instead of allocating fresh. This is
	// the next layer of churn after TweenPropertyEntry pooling: every tween
	// constructed today also allocates an `entries` array and an `easingFn`
	// closure. Pooling Tween eliminates all three at steady state.
	@Test
	public function testTweenInstancesAreReusedAfterCompletion():Void {
		var mgr = new TweenManager();
		var obj = createObject();

		// Prime: complete a tween so its instance returns to the free list.
		mgr.tween(obj, 0.1, [Alpha(0.5)]);
		mgr.update(0.2);

		final baseline = Tween.creationCount;

		// Five sequential complete-then-recreate cycles: pool size never needs
		// to exceed 1, every iteration after the prime should reuse the slot.
		for (i in 0...5) {
			mgr.tween(obj, 0.1, [Alpha(0.5)]);
			mgr.update(0.2);
		}

		final delta = Tween.creationCount - baseline;
		Assert.equals(0, delta,
			"After a tween completes, the Tween instance itself must return to a pool so "
			+ "the next tween of the same shape reuses it. Got " + delta + " fresh "
			+ "allocations across 5 complete-then-recreate cycles — this is the per-frame "
			+ "churn vector hit by panel/tooltip fades, screen transitions, codegen "
			+ "transition{} blocks, and grid cell animations.");
	}

	// fadeOut(removeOnComplete=true) currently allocates a `() -> target.remove()`
	// closure per call to wire up the post-fade detach. That closure should be
	// replaced by a flag on Tween (checked by TweenManager.update after the
	// regular onComplete fires) so the pool is fully exercised — closure
	// allocation otherwise pins a fresh object per fadeOut even with Tween
	// pooling in place.
	@Test
	public function testFadeOutRemoveOnCompleteReusesTweenAfterCompletion():Void {
		var mgr = new TweenManager();
		var parent = createObject();

		// Prime: one fadeOut(removeOnComplete=true) cycle to populate pool.
		var primeObj = createObject();
		parent.addChild(primeObj);
		mgr.fadeOut(primeObj, 0.1, null, true);
		mgr.update(0.2);
		Assert.isNull(primeObj.parent,
			"fadeOut(removeOnComplete=true) prime must remove the object from its parent.");

		final baseline = Tween.creationCount;

		// Five sequential fadeOuts. Each completes before the next, so a
		// single pooled Tween should service all of them.
		for (i in 0...5) {
			var obj = createObject();
			parent.addChild(obj);
			mgr.fadeOut(obj, 0.1, null, true);
			mgr.update(0.2);
			Assert.isNull(obj.parent,
				"fadeOut(removeOnComplete=true) must still remove obj from parent on completion.");
		}

		final delta = Tween.creationCount - baseline;
		Assert.equals(0, delta,
			"fadeOut(removeOnComplete=true) must reuse Tween instances from the pool. "
			+ "Got " + delta + " fresh allocations across 5 cycles — likely the "
			+ "`() -> target.remove()` closure path is bypassing the pool by allocating "
			+ "a new Tween per call.");
	}

	// removeTargetOnComplete is a public field on Tween, so callers can set it on
	// a tween obtained via createTween() and feed that tween into sequence([...])
	// or group([...]). The flag must still cause the target to be removed when the
	// tween completes inside the sequence/group — otherwise the contract diverges
	// silently between bare tweens and wrapped tweens.

	@Test
	public function testRemoveTargetOnCompleteFiresForTweenInsideSequence():Void {
		var mgr = new TweenManager();
		var parent = createObject();
		var obj = createObject();
		parent.addChild(obj);

		var t = mgr.createTween(obj, 0.1, [Alpha(0.0)]);
		t.removeTargetOnComplete = true;
		mgr.sequence([t]);
		mgr.update(0.2);

		Assert.isNull(obj.parent,
			"Tween.removeTargetOnComplete must remove the target from its parent when the tween completes inside a sequence; "
			+ "currently the sequence arm of TweenManager.update only fires the sequence's outer onComplete and never honors per-tween removeTargetOnComplete.");
	}

	@Test
	public function testRemoveTargetOnCompleteFiresForTweenInsideGroup():Void {
		var mgr = new TweenManager();
		var parent = createObject();
		var obj = createObject();
		parent.addChild(obj);

		var t = mgr.createTween(obj, 0.1, [Alpha(0.0)]);
		t.removeTargetOnComplete = true;
		mgr.group([t]);
		mgr.update(0.2);

		Assert.isNull(obj.parent,
			"Tween.removeTargetOnComplete must remove the target from its parent when the tween completes inside a group; "
			+ "currently the group arm of TweenManager.update only fires the group's outer onComplete and never honors per-tween removeTargetOnComplete.");
	}

	// A zero-duration tween represents a "skip" intent (e.g. `crossfade(0)` /
	// `slide(left, 0)` in a .manim transition). step() must not divide by zero —
	// 0/0 = NaN, FloatTools.clamp is not NaN-aware (all NaN comparisons are false),
	// and lerp(NaN, from, to) propagates NaN into the target's alpha/x/y/scale/
	// rotation, silently breaking the object.

	@Test
	public function testZeroDurationTweenDoesNotProduceNaN():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.alpha = 0.5;
		obj.x = 10.0;
		obj.y = 20.0;
		obj.scaleX = 1.5;
		obj.scaleY = 1.5;
		obj.rotation = 0.25;

		mgr.tween(obj, 0.0, [Alpha(1.0), X(100.0), Y(200.0), ScaleX(2.0), ScaleY(2.0), Rotation(1.0)]);

		// First step with dt=0 — elapsed stays 0, so elapsed / duration = 0 / 0 = NaN.
		mgr.update(0.0);

		Assert.isFalse(Math.isNaN(obj.alpha),    "zero-duration tween must not write NaN to alpha");
		Assert.isFalse(Math.isNaN(obj.x),        "zero-duration tween must not write NaN to x");
		Assert.isFalse(Math.isNaN(obj.y),        "zero-duration tween must not write NaN to y");
		Assert.isFalse(Math.isNaN(obj.scaleX),   "zero-duration tween must not write NaN to scaleX");
		Assert.isFalse(Math.isNaN(obj.scaleY),   "zero-duration tween must not write NaN to scaleY");
		Assert.isFalse(Math.isNaN(obj.rotation), "zero-duration tween must not write NaN to rotation");
	}

	// Calling clear() from a tween's onComplete must not push the completing tween
	// onto the shared pool twice. TweenManager.update() fires onComplete BEFORE its
	// own cleanup; if that callback runs clear() (a realistic screen-transition
	// teardown), clear() already recycles the completing handle, then update()
	// recycles it again. A non-idempotent release double-pushes the instance, so two
	// later acquire() calls hand the SAME Tween to two logical tweens → cross-talk
	// on target/elapsed/entries.
	@Test
	public function testClearFromOnCompleteDoesNotDoubleReleaseTween():Void {
		var mgr = new TweenManager();
		var triggerObj = createObject();

		// Tween whose completion callback tears everything down via clear().
		mgr.tween(triggerObj, 0.1, [Alpha(0.0)]).setOnComplete(() -> mgr.clear());
		mgr.update(0.2); // completes → onComplete → clear() → (buggy) double release

		// Two fresh tweens on distinct targets. If the completing tween was pushed
		// to the pool twice, these two acquire() calls pop the same instance.
		var objA = createObject();
		var objB = createObject();
		var tA = mgr.tween(objA, 1.0, [X(100.0)]);
		var tB = mgr.tween(objB, 1.0, [Y(200.0)]);

		Assert.isTrue(tA != tB,
			"clear() invoked from a tween's onComplete must not double-release the completing "
			+ "tween into the pool; two subsequent tween() calls received the same Tween instance, "
			+ "which causes cross-talk on target/elapsed/entries.");

		// Direct consequence of the aliasing: configuring tB clobbers tA's target.
		Assert.equals(objA, tA.target,
			"Aliased tween instances share state — creating tB overwrote tA.target.");
	}

	@Test
	public function testZeroDurationTweenSnapsToFinalValue():Void {
		var mgr = new TweenManager();
		var obj = createObject();
		obj.alpha = 0.0;
		obj.x = 0.0;
		obj.y = 0.0;

		var completed = false;
		mgr.tween(obj, 0.0, [Alpha(1.0), X(100.0), Y(200.0)]).setOnComplete(() -> completed = true);

		mgr.update(0.0);

		Assert.floatEquals(1.0,   obj.alpha, "zero-duration tween must snap alpha to target on first step");
		Assert.floatEquals(100.0, obj.x,     "zero-duration tween must snap x to target on first step");
		Assert.floatEquals(200.0, obj.y,     "zero-duration tween must snap y to target on first step");
		Assert.isTrue(completed, "zero-duration tween must complete (fire onComplete) on first step");
	}
}
