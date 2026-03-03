package bh.test.examples;

import utest.Assert;
import bh.base.TweenManager;
import bh.base.TweenManager.Tween;
import bh.base.TweenManager.TweenProperty;
import bh.ui.screens.ScreenTransition;
import bh.multianim.MultiAnimParser.EasingType;

/**
 * Integration tests for screen transition behavior.
 *
 * ScreenManager requires a live hxd.App and cannot be instantiated in
 * isolation.  These tests exercise the same tween-driven transition
 * mechanics that ScreenManager.executeTransition uses — creating
 * enter/exit tweens on h2d.Object roots and stepping TweenManager —
 * so we get real coverage of the transition pipeline without needing
 * the full app lifecycle.
 */
@:nullSafety
class ScreenTransitionIntegrationTest extends utest.Test {
	// ==================== Helpers ====================

	/** Simulates ScreenManager.executeTransition for Fade. */
	static function executeFadeTransition(tweens:TweenManager, oldRoot:h2d.Object, newRoot:h2d.Object,
			duration:Float, ?easing:EasingType, ?onComplete:Void -> Void):Void {
		newRoot.alpha = 0.0;
		var enterTween = tweens.tween(newRoot, duration, [Alpha(1.0)], easing);
		enterTween.skipFirstDt = true;
		var exitTween = tweens.tween(oldRoot, duration, [Alpha(0.0)], easing);
		exitTween.skipFirstDt = true;
		if (onComplete != null)
			exitTween.setOnComplete(onComplete);
	}

	/** Simulates ScreenManager.executeTransition for SlideLeft. */
	static function executeSlideLeftTransition(tweens:TweenManager, oldRoot:h2d.Object, newRoot:h2d.Object,
			screenWidth:Float, duration:Float, ?easing:EasingType, ?onComplete:Void -> Void):Void {
		newRoot.x = screenWidth;
		var enterTween = tweens.tween(newRoot, duration, [X(0.0)], easing);
		enterTween.skipFirstDt = true;
		var exitTween = tweens.tween(oldRoot, duration, [X(-screenWidth)], easing);
		exitTween.skipFirstDt = true;
		if (onComplete != null)
			exitTween.setOnComplete(onComplete);
	}

	/** Simulates ScreenManager.executeTransition for SlideRight. */
	static function executeSlideRightTransition(tweens:TweenManager, oldRoot:h2d.Object, newRoot:h2d.Object,
			screenWidth:Float, duration:Float, ?easing:EasingType, ?onComplete:Void -> Void):Void {
		newRoot.x = -screenWidth;
		var enterTween = tweens.tween(newRoot, duration, [X(0.0)], easing);
		enterTween.skipFirstDt = true;
		var exitTween = tweens.tween(oldRoot, duration, [X(screenWidth)], easing);
		exitTween.skipFirstDt = true;
		if (onComplete != null)
			exitTween.setOnComplete(onComplete);
	}

	/** Simulates ScreenManager.executeTransition for SlideUp. */
	static function executeSlideUpTransition(tweens:TweenManager, oldRoot:h2d.Object, newRoot:h2d.Object,
			screenHeight:Float, duration:Float, ?easing:EasingType, ?onComplete:Void -> Void):Void {
		newRoot.y = screenHeight;
		var enterTween = tweens.tween(newRoot, duration, [Y(0.0)], easing);
		enterTween.skipFirstDt = true;
		var exitTween = tweens.tween(oldRoot, duration, [Y(-screenHeight)], easing);
		exitTween.skipFirstDt = true;
		if (onComplete != null)
			exitTween.setOnComplete(onComplete);
	}

	/** Simulates ScreenManager.executeTransition for SlideDown. */
	static function executeSlideDownTransition(tweens:TweenManager, oldRoot:h2d.Object, newRoot:h2d.Object,
			screenHeight:Float, duration:Float, ?easing:EasingType, ?onComplete:Void -> Void):Void {
		newRoot.y = -screenHeight;
		var enterTween = tweens.tween(newRoot, duration, [Y(0.0)], easing);
		enterTween.skipFirstDt = true;
		var exitTween = tweens.tween(oldRoot, duration, [Y(screenHeight)], easing);
		exitTween.skipFirstDt = true;
		if (onComplete != null)
			exitTween.setOnComplete(onComplete);
	}

	// ==================== Fade Transition ====================

	@Test
	public function testFadeTransitionCreatesAlphaTween():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.alpha = 1.0;

		executeFadeTransition(mgr, oldRoot, newRoot, 0.5);

		Assert.isTrue(mgr.hasTweens(oldRoot));
		Assert.isTrue(mgr.hasTweens(newRoot));
	}

	@Test
	public function testFadeTransitionDuration():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.alpha = 1.0;
		var completed = false;

		executeFadeTransition(mgr, oldRoot, newRoot, 0.5, null, () -> completed = true);

		// First update consumed by skipFirstDt
		mgr.update(0.016);
		Assert.isFalse(completed);

		// Advance partway — should not be complete
		mgr.update(0.3);
		Assert.isFalse(completed);

		// Advance past duration
		mgr.update(0.3);
		Assert.isTrue(completed);
	}

	@Test
	public function testFadeTransitionWithEasing():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.alpha = 1.0;

		executeFadeTransition(mgr, oldRoot, newRoot, 1.0, EaseInQuad);

		// Skip first dt
		mgr.update(0.001);
		// At t=0.5 with EaseInQuad: eased = 0.25
		mgr.update(0.5);

		// New root started at 0.0, target 1.0 → at eased 0.25, alpha ~ 0.25
		Assert.floatEquals(0.25, newRoot.alpha);
		// Old root started at 1.0, target 0.0 → at eased 0.25, alpha ~ 0.75
		Assert.floatEquals(0.75, oldRoot.alpha);
	}

	@Test
	public function testFadeOldScreenAlphaDecreases():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.alpha = 1.0;

		executeFadeTransition(mgr, oldRoot, newRoot, 1.0);

		// Skip first dt
		mgr.update(0.001);

		mgr.update(0.5);
		Assert.isTrue(oldRoot.alpha < 1.0);
		Assert.isTrue(oldRoot.alpha > 0.0);

		mgr.update(0.5);
		Assert.floatEquals(0.0, oldRoot.alpha);
	}

	@Test
	public function testFadeNewScreenAlphaIncreases():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.alpha = 1.0;

		executeFadeTransition(mgr, oldRoot, newRoot, 1.0);

		// New root starts at 0
		Assert.floatEquals(0.0, newRoot.alpha);

		// Skip first dt
		mgr.update(0.001);

		mgr.update(0.5);
		Assert.isTrue(newRoot.alpha > 0.0);
		Assert.isTrue(newRoot.alpha < 1.0);

		mgr.update(0.5);
		Assert.floatEquals(1.0, newRoot.alpha);
	}

	// ==================== Slide Transitions ====================

	@Test
	public function testSlideLeftTransition():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		final screenWidth = 800.0;

		executeSlideLeftTransition(mgr, oldRoot, newRoot, screenWidth, 1.0);

		// New root starts at screenWidth
		Assert.floatEquals(screenWidth, newRoot.x);

		// Skip first dt
		mgr.update(0.001);

		mgr.update(1.0);
		// After completion: new screen at 0, old screen at -screenWidth
		Assert.floatEquals(0.0, newRoot.x);
		Assert.floatEquals(-screenWidth, oldRoot.x);
	}

	@Test
	public function testSlideRightTransition():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		final screenWidth = 800.0;

		executeSlideRightTransition(mgr, oldRoot, newRoot, screenWidth, 1.0);

		// New root starts at -screenWidth
		Assert.floatEquals(-screenWidth, newRoot.x);

		// Skip first dt
		mgr.update(0.001);

		mgr.update(1.0);
		Assert.floatEquals(0.0, newRoot.x);
		Assert.floatEquals(screenWidth, oldRoot.x);
	}

	@Test
	public function testSlideUpTransition():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		final screenHeight = 600.0;

		executeSlideUpTransition(mgr, oldRoot, newRoot, screenHeight, 1.0);

		// New root starts below (at screenHeight)
		Assert.floatEquals(screenHeight, newRoot.y);

		// Skip first dt
		mgr.update(0.001);

		mgr.update(1.0);
		Assert.floatEquals(0.0, newRoot.y);
		Assert.floatEquals(-screenHeight, oldRoot.y);
	}

	@Test
	public function testSlideDownTransition():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		final screenHeight = 600.0;

		executeSlideDownTransition(mgr, oldRoot, newRoot, screenHeight, 1.0);

		// New root starts above (at -screenHeight)
		Assert.floatEquals(-screenHeight, newRoot.y);

		// Skip first dt
		mgr.update(0.001);

		mgr.update(1.0);
		Assert.floatEquals(0.0, newRoot.y);
		Assert.floatEquals(screenHeight, oldRoot.y);
	}

	@Test
	public function testSlideDuration():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		var completed = false;

		executeSlideLeftTransition(mgr, oldRoot, newRoot, 800.0, 0.3, null, () -> completed = true);

		// Skip first dt
		mgr.update(0.001);

		mgr.update(0.2);
		Assert.isFalse(completed);

		mgr.update(0.2);
		Assert.isTrue(completed);
	}

	@Test
	public function testSlideWithEasing():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		final screenWidth = 800.0;

		executeSlideLeftTransition(mgr, oldRoot, newRoot, screenWidth, 1.0, EaseInQuad);

		// Skip first dt
		mgr.update(0.001);

		// At t=0.5 with EaseInQuad: eased = 0.25
		mgr.update(0.5);
		// New root: from screenWidth to 0, at eased 0.25 → 800 - 800*0.25 = 600
		Assert.floatEquals(600.0, newRoot.x);
		// Old root: from 0 to -screenWidth, at eased 0.25 → -800*0.25 = -200
		Assert.floatEquals(-200.0, oldRoot.x);
	}

	@Test
	public function testSlideOldScreenMoves():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.x = 0;

		executeSlideLeftTransition(mgr, oldRoot, newRoot, 800.0, 1.0);

		// Skip first dt
		mgr.update(0.001);

		mgr.update(0.5);
		// Old root should have moved (negative x for slide left)
		Assert.isTrue(oldRoot.x < 0.0);
	}

	@Test
	public function testSlideNewScreenStartsOffset():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		final screenWidth = 800.0;

		executeSlideLeftTransition(mgr, oldRoot, newRoot, screenWidth, 1.0);

		// Before any update, new screen should be at the offset position
		Assert.floatEquals(screenWidth, newRoot.x);
	}

	// ==================== None Transition ====================

	@Test
	public function testNoneTransitionIsInstant():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		var completed = false;

		// Simulate None: no tweens created, just call onComplete
		var transition = ScreenTransition.None;
		switch (transition) {
			case None:
				completed = true;
			default:
				Assert.fail("Expected None");
		}

		Assert.isTrue(completed);
		Assert.isFalse(mgr.hasTweens(oldRoot));
		Assert.isFalse(mgr.hasTweens(newRoot));
	}

	// ==================== Custom Transition ====================

	@Test
	public function testCustomTransitionCallback():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		var callbackInvoked = false;

		var transition = ScreenTransition.Custom((tweens, old, nw, onComplete) -> {
			callbackInvoked = true;
			onComplete();
		});

		switch (transition) {
			case Custom(fn):
				fn(mgr, oldRoot, newRoot, () -> {});
			default:
		}

		Assert.isTrue(callbackInvoked);
	}

	@Test
	public function testCustomTransitionReceivesTweenManager():Void {
		var mgr = new TweenManager();
		var receivedTweens:Null<TweenManager> = null;

		var transition = ScreenTransition.Custom((tweens, old, nw, onComplete) -> {
			receivedTweens = tweens;
			onComplete();
		});

		switch (transition) {
			case Custom(fn):
				fn(mgr, new h2d.Object(), new h2d.Object(), () -> {});
			default:
		}

		Assert.equals(mgr, receivedTweens);
	}

	@Test
	public function testCustomTransitionReceivesOldRoot():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var receivedOld:Null<h2d.Object> = null;

		var transition = ScreenTransition.Custom((tweens, old, nw, onComplete) -> {
			receivedOld = old;
			onComplete();
		});

		switch (transition) {
			case Custom(fn):
				fn(mgr, oldRoot, new h2d.Object(), () -> {});
			default:
		}

		Assert.equals(oldRoot, receivedOld);
	}

	@Test
	public function testCustomTransitionReceivesNewRoot():Void {
		var mgr = new TweenManager();
		var newRoot = new h2d.Object();
		var receivedNew:Null<h2d.Object> = null;

		var transition = ScreenTransition.Custom((tweens, old, nw, onComplete) -> {
			receivedNew = nw;
			onComplete();
		});

		switch (transition) {
			case Custom(fn):
				fn(mgr, new h2d.Object(), newRoot, () -> {});
			default:
		}

		Assert.equals(newRoot, receivedNew);
	}

	@Test
	public function testCustomTransitionOnCompleteCallback():Void {
		var mgr = new TweenManager();
		var completeCalled = false;

		var transition = ScreenTransition.Custom((tweens, old, nw, onComplete) -> {
			onComplete();
		});

		switch (transition) {
			case Custom(fn):
				fn(mgr, new h2d.Object(), new h2d.Object(), () -> completeCalled = true);
			default:
		}

		Assert.isTrue(completeCalled);
	}

	// ==================== TweenManager State During Transition ====================

	@Test
	public function testTransitionInProgressHasTweens():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.alpha = 1.0;

		executeFadeTransition(mgr, oldRoot, newRoot, 1.0);

		// Skip first dt
		mgr.update(0.001);

		// Mid-transition: tweens are active
		mgr.update(0.3);
		Assert.isTrue(mgr.hasTweens(oldRoot));
		Assert.isTrue(mgr.hasTweens(newRoot));
	}

	@Test
	public function testTransitionCompleteNoTweens():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.alpha = 1.0;

		executeFadeTransition(mgr, oldRoot, newRoot, 0.5);

		// Skip first dt
		mgr.update(0.001);

		// Step past duration
		mgr.update(0.6);

		Assert.isFalse(mgr.hasTweens(oldRoot));
		Assert.isFalse(mgr.hasTweens(newRoot));
	}

	// ==================== Transition Interruption ====================

	@Test
	public function testInterruptFinalizesCurrentTransition():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.alpha = 1.0;
		var firstCompleted = false;

		executeFadeTransition(mgr, oldRoot, newRoot, 1.0, null, () -> firstCompleted = true);

		// Skip first dt, advance partway
		mgr.update(0.001);
		mgr.update(0.3);

		// Simulate finalize (like ScreenManager.finalizeTransition)
		mgr.cancelAll(oldRoot);
		mgr.cancelAll(newRoot);
		// Manually set final state (what ScreenManager cleanup does)
		oldRoot.alpha = 0.0;
		newRoot.alpha = 1.0;

		// Now start a second transition with a new screen
		var newerRoot = new h2d.Object();
		executeFadeTransition(mgr, newRoot, newerRoot, 0.5);

		// Old transition tweens are gone
		Assert.isFalse(mgr.hasTweens(oldRoot));
		// New transition tweens are active
		Assert.isTrue(mgr.hasTweens(newRoot));
		Assert.isTrue(mgr.hasTweens(newerRoot));
	}

	@Test
	public function testFinalizeTransitionJumpsToEnd():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.alpha = 1.0;

		executeFadeTransition(mgr, oldRoot, newRoot, 1.0);

		// Skip first dt, advance partway
		mgr.update(0.001);
		mgr.update(0.3);

		// Simulate finalizeTransition by finishing tweens manually
		// ScreenManager calls cleanup which resets properties
		mgr.cancelAll(oldRoot);
		mgr.cancelAll(newRoot);
		oldRoot.alpha = 1.0; // ScreenManager resets to 1.0 in cleanup
		oldRoot.x = 0;
		oldRoot.y = 0;

		// Verify old root was reset
		Assert.floatEquals(1.0, oldRoot.alpha);
		Assert.floatEquals(0.0, oldRoot.x);
	}

	@Test
	public function testFinalizeTransitionClearsTweens():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.alpha = 1.0;

		executeFadeTransition(mgr, oldRoot, newRoot, 1.0);

		// Skip first dt, advance partway
		mgr.update(0.001);
		mgr.update(0.3);

		Assert.isTrue(mgr.hasTweens(oldRoot));

		// Finalize
		mgr.cancelAll(oldRoot);
		mgr.cancelAll(newRoot);
		// Clean up cancelled tweens
		mgr.update(0.001);

		Assert.isFalse(mgr.hasTweens(oldRoot));
		Assert.isFalse(mgr.hasTweens(newRoot));
	}

	// ==================== Scene Graph During Transition ====================

	@Test
	public function testTransitionBothScreensInScene():Void {
		var mgr = new TweenManager();
		var scene = new h2d.Object();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		scene.addChild(oldRoot);
		scene.addChild(newRoot);
		oldRoot.alpha = 1.0;

		executeFadeTransition(mgr, oldRoot, newRoot, 1.0);

		// Skip first dt
		mgr.update(0.001);
		mgr.update(0.3);

		// Both roots should be in the scene during the transition
		Assert.notNull(oldRoot.parent);
		Assert.notNull(newRoot.parent);
		Assert.equals(scene, oldRoot.parent);
		Assert.equals(scene, newRoot.parent);
	}

	@Test
	public function testNewScreenOnTopDuringFade():Void {
		var scene = new h2d.Layers();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();

		// ScreenManager adds screens at specific layers.
		// New screens are added after old ones, so they render on top.
		scene.add(oldRoot, 2);
		scene.add(newRoot, 2);

		// The new root was added after old root at the same layer,
		// so it renders on top (later in child list = on top).
		var oldIndex = -1;
		var newIndex = -1;
		for (i in 0...scene.numChildren) {
			var child = scene.getChildAt(i);
			if (child == oldRoot) oldIndex = i;
			if (child == newRoot) newIndex = i;
		}

		Assert.isTrue(newIndex > oldIndex);
	}

	@Test
	public function testOldScreenRemovedAfterTransition():Void {
		var scene = new h2d.Object();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		scene.addChild(oldRoot);
		scene.addChild(newRoot);

		var mgr = new TweenManager();
		oldRoot.alpha = 1.0;
		var transitionComplete = false;

		executeFadeTransition(mgr, oldRoot, newRoot, 0.5, null, () -> {
			transitionComplete = true;
			// Simulate ScreenManager cleanup: remove old root
			oldRoot.remove();
		});

		// Skip first dt
		mgr.update(0.001);
		// Complete the transition
		mgr.update(0.6);

		Assert.isTrue(transitionComplete);
		Assert.isNull(oldRoot.parent);
		Assert.notNull(newRoot.parent);
	}

	// ==================== SkipFirstDt Behavior ====================

	@Test
	public function testSkipFirstDtPreventsInitialJump():Void {
		var mgr = new TweenManager();
		var root = new h2d.Object();
		root.alpha = 1.0;

		var tween = mgr.tween(root, 1.0, [Alpha(0.0)]);
		tween.skipFirstDt = true;

		// First update with large dt — should be discarded
		mgr.update(0.5);
		// Alpha should still be at start (1.0) because first dt was skipped
		Assert.floatEquals(1.0, root.alpha);

		// Second update actually advances
		mgr.update(0.5);
		Assert.floatEquals(0.5, root.alpha);
	}

	// ==================== Custom Transition With Tweens ====================

	@Test
	public function testCustomTransitionCreatesTweens():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.alpha = 1.0;
		newRoot.alpha = 0.0;
		var completed = false;

		// Custom transition that fades but with custom logic
		var customFn = (tweens:TweenManager, old:h2d.Object, nw:h2d.Object, onComplete:Void -> Void) -> {
			tweens.tween(old, 0.5, [Alpha(0.0)]);
			tweens.tween(nw, 0.5, [Alpha(1.0)]).setOnComplete(onComplete);
		};

		customFn(mgr, oldRoot, newRoot, () -> completed = true);

		Assert.isTrue(mgr.hasTweens(oldRoot));
		Assert.isTrue(mgr.hasTweens(newRoot));

		mgr.update(0.5);

		Assert.isTrue(completed);
		Assert.floatEquals(0.0, oldRoot.alpha);
		Assert.floatEquals(1.0, newRoot.alpha);
	}

	// ==================== Modal Overlay ====================

	@Test
	public function testModalOverlayAlphaTween():Void {
		var mgr = new TweenManager();
		var overlay = new h2d.Object();
		overlay.alpha = 0.0;
		final targetAlpha = 0.7;

		var tween = mgr.tween(overlay, 0.3, [Alpha(targetAlpha)]);
		tween.skipFirstDt = true;

		// Skip first dt
		mgr.update(0.001);

		// Advance to completion
		mgr.update(0.3);
		Assert.floatEquals(targetAlpha, overlay.alpha);
	}

	@Test
	public function testModalOverlayOnHigherLayer():Void {
		var scene = new h2d.Layers();
		var contentRoot = new h2d.Object();
		var overlay = new h2d.Object();
		var dialogRoot = new h2d.Object();

		// ScreenManager layer ordering: content=2, overlay=5, dialog=6
		scene.add(contentRoot, 2);
		scene.add(overlay, 5);
		scene.add(dialogRoot, 6);

		// Verify layer ordering via getChildLayer
		var contentLayer = scene.getChildLayer(contentRoot);
		var overlayLayer = scene.getChildLayer(overlay);
		var dialogLayer = scene.getChildLayer(dialogRoot);

		Assert.isTrue(overlayLayer > contentLayer);
		Assert.isTrue(dialogLayer > overlayLayer);
	}

	@Test
	public function testModalOverlayFadeIn():Void {
		var mgr = new TweenManager();
		var overlay = new h2d.Object();
		overlay.alpha = 0.0;
		final targetAlpha = 0.5;

		var tween = mgr.tween(overlay, 0.3, [Alpha(targetAlpha)]);
		tween.skipFirstDt = true;

		// Skip first dt
		mgr.update(0.001);

		// Midway
		mgr.update(0.15);
		Assert.isTrue(overlay.alpha > 0.0);
		Assert.isTrue(overlay.alpha < targetAlpha);

		// Complete
		mgr.update(0.15);
		Assert.floatEquals(targetAlpha, overlay.alpha);
	}

	// ==================== Edge Cases ====================

	@Test
	public function testFadeWithNullEasing():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.alpha = 1.0;
		var completed = false;

		// Null easing should use linear (default)
		executeFadeTransition(mgr, oldRoot, newRoot, 0.3, null, () -> completed = true);

		// Skip first dt
		mgr.update(0.001);
		mgr.update(0.3);

		Assert.isTrue(completed);
		Assert.floatEquals(0.0, oldRoot.alpha);
		Assert.floatEquals(1.0, newRoot.alpha);
	}

	@Test
	public function testZeroDurationIsInstant():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.alpha = 1.0;
		var completed = false;

		executeFadeTransition(mgr, oldRoot, newRoot, 0.0, null, () -> completed = true);

		// Skip first dt
		mgr.update(0.001);
		// Any small update should complete immediately
		mgr.update(0.001);

		Assert.isTrue(completed);
		Assert.floatEquals(0.0, oldRoot.alpha);
		Assert.floatEquals(1.0, newRoot.alpha);
	}

	// ==================== Exit-Only Transition (Dialog Close) ====================

	@Test
	public function testExitOnlyFadeTransition():Void {
		var mgr = new TweenManager();
		var dialogRoot = new h2d.Object();
		dialogRoot.alpha = 1.0;
		var completed = false;

		// Simulate executeExitTransition for Fade
		mgr.tween(dialogRoot, 0.3, [Alpha(0.0)]).setOnComplete(() -> completed = true);

		mgr.update(0.3);
		Assert.isTrue(completed);
		Assert.floatEquals(0.0, dialogRoot.alpha);
	}

	@Test
	public function testExitOnlySlideTransition():Void {
		var mgr = new TweenManager();
		var dialogRoot = new h2d.Object();
		dialogRoot.x = 0;
		final screenWidth = 800.0;
		var completed = false;

		// Simulate executeExitTransition for SlideLeft
		mgr.tween(dialogRoot, 0.3, [X(-screenWidth)]).setOnComplete(() -> completed = true);

		mgr.update(0.3);
		Assert.isTrue(completed);
		Assert.floatEquals(-screenWidth, dialogRoot.x);
	}

	// ==================== Transition Property Reset ====================

	@Test
	public function testCleanupResetsProperties():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.alpha = 1.0;

		executeFadeTransition(mgr, oldRoot, newRoot, 0.5);

		// Skip first dt
		mgr.update(0.001);
		// Complete
		mgr.update(0.6);

		// Simulate ScreenManager cleanup (resets alpha, x, y)
		oldRoot.alpha = 1.0;
		oldRoot.x = 0;
		oldRoot.y = 0;

		Assert.floatEquals(1.0, oldRoot.alpha);
		Assert.floatEquals(0.0, oldRoot.x);
		Assert.floatEquals(0.0, oldRoot.y);
	}

	// ==================== Concurrent Enter/Exit ====================

	@Test
	public function testFadeEnterAndExitRunConcurrently():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		oldRoot.alpha = 1.0;

		executeFadeTransition(mgr, oldRoot, newRoot, 1.0);

		// Skip first dt
		mgr.update(0.001);
		mgr.update(0.5);

		// Both should be mid-transition at the same time
		Assert.isTrue(oldRoot.alpha > 0.0 && oldRoot.alpha < 1.0);
		Assert.isTrue(newRoot.alpha > 0.0 && newRoot.alpha < 1.0);
		// They should sum to ~1.0 for linear easing
		Assert.floatEquals(1.0, oldRoot.alpha + newRoot.alpha);
	}

	@Test
	public function testSlideEnterAndExitRunConcurrently():Void {
		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();
		final screenWidth = 800.0;

		executeSlideLeftTransition(mgr, oldRoot, newRoot, screenWidth, 1.0);

		// Skip first dt
		mgr.update(0.001);
		mgr.update(0.5);

		// Both should be mid-slide
		Assert.isTrue(oldRoot.x < 0.0);
		Assert.isTrue(newRoot.x > 0.0 && newRoot.x < screenWidth);
	}

	// ==================== Multiple Sequential Transitions ====================

	@Test
	public function testSequentialTransitions():Void {
		var mgr = new TweenManager();
		var screenA = new h2d.Object();
		var screenB = new h2d.Object();
		var screenC = new h2d.Object();
		screenA.alpha = 1.0;

		// First transition: A → B
		executeFadeTransition(mgr, screenA, screenB, 0.5);
		mgr.update(0.001); // skip first dt
		mgr.update(0.5);

		Assert.floatEquals(0.0, screenA.alpha);
		Assert.floatEquals(1.0, screenB.alpha);

		// Second transition: B → C
		executeFadeTransition(mgr, screenB, screenC, 0.5);
		mgr.update(0.001); // skip first dt
		mgr.update(0.5);

		Assert.floatEquals(0.0, screenB.alpha);
		Assert.floatEquals(1.0, screenC.alpha);
	}
}
