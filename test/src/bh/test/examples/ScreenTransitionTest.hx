package bh.test.examples;

import utest.Assert;
import bh.ui.screens.ScreenTransition;
import bh.base.TweenManager;
import bh.base.TweenManager.TweenProperty;
import bh.multianim.MultiAnimParser.EasingType;

/**
 * Unit tests for ScreenTransition enum variants.
 * Tests enum construction, pattern matching, and custom transition callbacks.
 */
class ScreenTransitionTest extends utest.Test {
	// ==================== Enum Construction ====================

	@Test
	public function testNoneVariant():Void {
		var t = ScreenTransition.None;
		switch (t) {
			case None:
				Assert.isTrue(true);
			default:
				Assert.fail("Expected None variant");
		}
	}

	@Test
	public function testFadeVariant():Void {
		var t = Fade(0.3);
		switch (t) {
			case Fade(duration, easing):
				Assert.floatEquals(0.3, duration);
				Assert.isNull(easing);
			default:
				Assert.fail("Expected Fade variant");
		}
	}

	@Test
	public function testFadeWithEasing():Void {
		var t = Fade(0.5, EaseOutCubic);
		switch (t) {
			case Fade(duration, easing):
				Assert.floatEquals(0.5, duration);
				Assert.equals(EaseOutCubic, easing);
			default:
				Assert.fail("Expected Fade variant");
		}
	}

	@Test
	public function testSlideLeftVariant():Void {
		var t = SlideLeft(0.4, EaseInQuad);
		switch (t) {
			case SlideLeft(duration, easing):
				Assert.floatEquals(0.4, duration);
				Assert.equals(EaseInQuad, easing);
			default:
				Assert.fail("Expected SlideLeft variant");
		}
	}

	@Test
	public function testSlideRightVariant():Void {
		var t = SlideRight(0.6);
		switch (t) {
			case SlideRight(duration, easing):
				Assert.floatEquals(0.6, duration);
				Assert.isNull(easing);
			default:
				Assert.fail("Expected SlideRight variant");
		}
	}

	@Test
	public function testSlideUpVariant():Void {
		var t = SlideUp(0.3, EaseOutBack);
		switch (t) {
			case SlideUp(duration, easing):
				Assert.floatEquals(0.3, duration);
				Assert.equals(EaseOutBack, easing);
			default:
				Assert.fail("Expected SlideUp variant");
		}
	}

	@Test
	public function testSlideDownVariant():Void {
		var t = SlideDown(0.2);
		switch (t) {
			case SlideDown(duration, easing):
				Assert.floatEquals(0.2, duration);
			default:
				Assert.fail("Expected SlideDown variant");
		}
	}

	@Test
	public function testCustomVariant():Void {
		var callbackInvoked = false;
		var t = ScreenTransition.Custom(function(tweens:TweenManager, oldRoot:h2d.Object, newRoot:h2d.Object, onComplete:Void -> Void) {
			callbackInvoked = true;
			onComplete();
		});
		switch (t) {
			case Custom(fn):
				Assert.notNull(fn);
				// Invoke the callback to verify it works
				fn(null, null, null, function() {});
				Assert.isTrue(callbackInvoked);
			default:
				Assert.fail("Expected Custom variant");
		}
	}

	// ==================== Pattern Matching ====================

	@Test
	public function testPatternMatchAllVariants():Void {
		var variants:Array<ScreenTransition> = [
			None,
			Fade(0.3),
			SlideLeft(0.3),
			SlideRight(0.3),
			SlideUp(0.3),
			SlideDown(0.3),
			ScreenTransition.Custom(function(t:TweenManager, o:h2d.Object, n:h2d.Object, c:Void -> Void) { c(); })
		];
		Assert.equals(7, variants.length);

		// Verify each variant matches correctly
		for (v in variants) {
			var matched = switch (v) {
				case None: "none";
				case Fade(_, _): "fade";
				case SlideLeft(_, _): "slideLeft";
				case SlideRight(_, _): "slideRight";
				case SlideUp(_, _): "slideUp";
				case SlideDown(_, _): "slideDown";
				case Custom(_): "custom";
			};
			Assert.notNull(matched);
		}
	}

	@Test
	public function testCustomTransitionCallbackSignature():Void {
		// Verify the custom callback receives correct types
		var receivedTweens:TweenManager = null;
		var receivedOld:h2d.Object = null;
		var receivedNew:h2d.Object = null;
		var completeCalled = false;

		var mgr = new TweenManager();
		var oldRoot = new h2d.Object();
		var newRoot = new h2d.Object();

		var t = ScreenTransition.Custom(function(tweens:TweenManager, old:h2d.Object, nw:h2d.Object, onComplete:Void -> Void) {
			receivedTweens = tweens;
			receivedOld = old;
			receivedNew = nw;
			onComplete();
		});

		switch (t) {
			case Custom(fn):
				fn(mgr, oldRoot, newRoot, function() { completeCalled = true; });
			default:
		}

		Assert.equals(mgr, receivedTweens);
		Assert.equals(oldRoot, receivedOld);
		Assert.equals(newRoot, receivedNew);
		Assert.isTrue(completeCalled);
	}

	// ==================== Duration Extraction ====================

	@Test
	public function testExtractDurationFromVariants():Void {
		// Helper to extract duration from a transition
		function getDuration(t:ScreenTransition):Float {
			return switch (t) {
				case None: 0.0;
				case Fade(d, _): d;
				case SlideLeft(d, _): d;
				case SlideRight(d, _): d;
				case SlideUp(d, _): d;
				case SlideDown(d, _): d;
				case Custom(_): -1.0;
			};
		}

		Assert.floatEquals(0.0, getDuration(None));
		Assert.floatEquals(0.3, getDuration(Fade(0.3)));
		Assert.floatEquals(0.5, getDuration(SlideLeft(0.5)));
		Assert.floatEquals(0.7, getDuration(SlideRight(0.7)));
		Assert.floatEquals(0.1, getDuration(SlideUp(0.1)));
		Assert.floatEquals(1.0, getDuration(SlideDown(1.0)));
		Assert.floatEquals(-1.0, getDuration(ScreenTransition.Custom(function(t:TweenManager, o:h2d.Object, n:h2d.Object, c:Void -> Void) { c(); })));
	}

	// ==================== TweenManager Transition Patterns ====================

	@Test
	public function testTweenFadePattern():Void {
		var mgr = new TweenManager();
		var obj = new h2d.Object();
		obj.alpha = 1.0;
		mgr.tween(obj, 0.3, [Alpha(0.0)]);
		mgr.update(0.35);
		Assert.floatEquals(0.0, obj.alpha);
	}

	@Test
	public function testTweenSlidePattern():Void {
		var mgr = new TweenManager();
		var obj = new h2d.Object();
		obj.x = 0.0;
		mgr.tween(obj, 0.3, [X(-800.0)]);
		mgr.update(0.35);
		Assert.floatEquals(-800.0, obj.x);
	}

	@Test
	public function testTweenCompletionCallback():Void {
		var mgr = new TweenManager();
		var obj = new h2d.Object();
		var completed = false;
		mgr.tween(obj, 0.3, [Alpha(0.0)]).setOnComplete(function() { completed = true; });
		mgr.update(0.35);
		Assert.isTrue(completed);
	}

	@Test
	public function testTweenFinishJumpsToEnd():Void {
		var mgr = new TweenManager();
		var obj = new h2d.Object();
		obj.alpha = 1.0;
		obj.x = 0.0;
		var t = mgr.tween(obj, 1.0, [Alpha(0.0), X(200.0)]);
		t.finish();
		Assert.floatEquals(0.0, obj.alpha);
		Assert.floatEquals(200.0, obj.x);
	}

	@Test
	public function testTweenCancelNoCallback():Void {
		var mgr = new TweenManager();
		var obj = new h2d.Object();
		var completed = false;
		var t = mgr.tween(obj, 1.0, [Alpha(0.0)]).setOnComplete(function() { completed = true; });
		mgr.cancel(t);
		mgr.update(2.0);
		Assert.isFalse(completed);
	}

	@Test
	public function testConcurrentTweens():Void {
		var mgr = new TweenManager();
		var obj1 = new h2d.Object();
		var obj2 = new h2d.Object();
		obj1.alpha = 1.0;
		obj2.x = 0.0;
		mgr.tween(obj1, 0.5, [Alpha(0.0)]);
		mgr.tween(obj2, 0.5, [X(100.0)]);
		mgr.update(0.5);
		Assert.floatEquals(0.0, obj1.alpha);
		Assert.floatEquals(100.0, obj2.x);
	}

	@Test
	public function testSequenceTweens():Void {
		var mgr = new TweenManager();
		var obj = new h2d.Object();
		obj.x = 0.0;
		var t1 = mgr.createTween(obj, 0.3, [X(100.0)]);
		var t2 = mgr.createTween(obj, 0.3, [X(200.0)]);
		mgr.sequence([t1, t2]);
		mgr.update(0.3);
		Assert.floatEquals(100.0, obj.x);
		mgr.update(0.3);
		Assert.floatEquals(200.0, obj.x);
	}

	@Test
	public function testGroupTweens():Void {
		var mgr = new TweenManager();
		var obj1 = new h2d.Object();
		var obj2 = new h2d.Object();
		obj1.alpha = 1.0;
		obj2.x = 0.0;
		var t1 = mgr.createTween(obj1, 0.5, [Alpha(0.0)]);
		var t2 = mgr.createTween(obj2, 0.5, [X(100.0)]);
		mgr.group([t1, t2]);
		mgr.update(0.5);
		Assert.floatEquals(0.0, obj1.alpha);
		Assert.floatEquals(100.0, obj2.x);
	}
}
