package bh.multianim;

import bh.base.TweenManager;
import bh.base.TweenManager.Tween;
import bh.base.TweenManager.TweenProperty;
import bh.multianim.MultiAnimParser.TransitionType;
import bh.multianim.MultiAnimParser.TransitionDirection;
import bh.multianim.MultiAnimParser.EasingType;

/**
 * Runtime helper for animated transitions in codegen-generated instances.
 * Mirrors the transition logic in IncrementalUpdateContext (MultiAnimBuilder.hx).
 * Generated instances delegate to this class when transition{} blocks are present.
 */
@:nullSafety
class CodegenTransitionHelper {
	final transitionSpecs:Map<String, TransitionType>;
	public var tweenManager:Null<TweenManager> = null;
	var activeTransitionTweens:Array<{obj:h2d.Object, tween:Tween, savedAlpha:Float, savedScaleX:Float, savedScaleY:Float, savedX:Float, savedY:Float}> = [];

	public function new(specs:Map<String, TransitionType>) {
		this.transitionSpecs = specs;
	}

	/** Set visibility with optional transition animation.
	 *  changedParam identifies which parameter triggered the change. */
	public function setVisibilityWithTransition(obj:h2d.Object, newVisible:Bool, changedParam:String):Void {
		if (obj.visible == newVisible && !hasActiveTransition(obj)) return;

		final spec = transitionSpecs.get(changedParam);
		if (spec == null || tweenManager == null || spec.match(TransNone)) {
			cancelActiveTransition(obj);
			obj.visible = newVisible;
			return;
		}

		cancelActiveTransition(obj);
		executeTransition(obj, newVisible, spec);
	}

	public function cancelActiveTransition(obj:h2d.Object):Void {
		var i = 0;
		while (i < activeTransitionTweens.length) {
			if (activeTransitionTweens[i].obj == obj) {
				final entry = activeTransitionTweens[i];
				entry.tween.onComplete = null;
				entry.tween.cancel();
				obj.alpha = entry.savedAlpha;
				obj.scaleX = entry.savedScaleX;
				obj.scaleY = entry.savedScaleY;
				obj.x = entry.savedX;
				obj.y = entry.savedY;
				activeTransitionTweens.splice(i, 1);
			} else {
				i++;
			}
		}
	}

	public function cancelAllTransitions():Void {
		while (activeTransitionTweens.length > 0) {
			final entry = activeTransitionTweens[0];
			entry.tween.onComplete = null;
			entry.tween.cancel();
			entry.obj.alpha = entry.savedAlpha;
			entry.obj.scaleX = entry.savedScaleX;
			entry.obj.scaleY = entry.savedScaleY;
			entry.obj.x = entry.savedX;
			entry.obj.y = entry.savedY;
			activeTransitionTweens.splice(0, 1);
		}
	}

	function hasActiveTransition(obj:h2d.Object):Bool {
		for (entry in activeTransitionTweens)
			if (entry.obj == obj) return true;
		return false;
	}

	function trackTransitionTween(obj:h2d.Object, tween:Tween, savedAlpha:Float, savedScaleX:Float, savedScaleY:Float, savedX:Float, savedY:Float):Void {
		activeTransitionTweens.push({obj: obj, tween: tween, savedAlpha: savedAlpha, savedScaleX: savedScaleX, savedScaleY: savedScaleY, savedX: savedX, savedY: savedY});
		final origOnComplete = tween.onComplete;
		tween.onComplete = () -> {
			var i = 0;
			while (i < activeTransitionTweens.length) {
				if (activeTransitionTweens[i].tween == tween) {
					activeTransitionTweens.splice(i, 1);
					break;
				}
				i++;
			}
			if (origOnComplete != null) origOnComplete();
		};
	}

	function executeTransition(obj:h2d.Object, show:Bool, spec:TransitionType):Void {
		final tm = tweenManager;
		if (tm == null) { obj.visible = show; return; }

		final preAlpha = obj.alpha;
		final preScaleX = obj.scaleX;
		final preScaleY = obj.scaleY;
		final preX = obj.x;
		final preY = obj.y;

		switch (spec) {
			case TransFade(duration, easing):
				if (show) {
					obj.visible = true;
					obj.alpha = 0.0;
					final t = tm.tween(obj, duration, [Alpha(preAlpha)], easing);
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				} else {
					final t = tm.tween(obj, duration, [Alpha(0.0)], easing);
					final capturedObj = obj;
					t.onComplete = () -> {
						capturedObj.visible = false;
						capturedObj.alpha = preAlpha;
					};
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				}

			case TransCrossfade(duration, easing):
				if (show) {
					obj.visible = true;
					obj.alpha = 0.0;
					final t = tm.tween(obj, duration, [Alpha(preAlpha)], easing);
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				} else {
					final t = tm.tween(obj, duration, [Alpha(0.0)], easing);
					final capturedObj = obj;
					t.onComplete = () -> {
						capturedObj.visible = false;
						capturedObj.alpha = preAlpha;
					};
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				}

			case TransFlipX(duration, easing):
				final halfDuration = duration / 2.0;
				if (show) {
					obj.visible = true;
					obj.scaleX = 0.0;
					final t = tm.tween(obj, halfDuration, [ScaleX(preScaleX)], easing);
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				} else {
					final t = tm.tween(obj, halfDuration, [ScaleX(0.0)], easing);
					final capturedObj = obj;
					t.onComplete = () -> {
						capturedObj.visible = false;
						capturedObj.scaleX = preScaleX;
					};
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				}

			case TransFlipY(duration, easing):
				final halfDuration = duration / 2.0;
				if (show) {
					obj.visible = true;
					obj.scaleY = 0.0;
					final t = tm.tween(obj, halfDuration, [ScaleY(preScaleY)], easing);
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				} else {
					final t = tm.tween(obj, halfDuration, [ScaleY(0.0)], easing);
					final capturedObj = obj;
					t.onComplete = () -> {
						capturedObj.visible = false;
						capturedObj.scaleY = preScaleY;
					};
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				}

			case TransSlide(dir, duration, distance, easing):
				final slideOffset:Float = distance != null ? distance : 50.0;
				if (show) {
					obj.visible = true;
					obj.alpha = 0.0;
					switch (dir) {
						case TDLeft: obj.x -= slideOffset;
						case TDRight: obj.x += slideOffset;
						case TDUp: obj.y -= slideOffset;
						case TDDown: obj.y += slideOffset;
					}
					final t = tm.tween(obj, duration, [X(preX), Y(preY), Alpha(preAlpha)], easing);
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				} else {
					var targetX = obj.x;
					var targetY = obj.y;
					switch (dir) {
						case TDLeft: targetX -= slideOffset;
						case TDRight: targetX += slideOffset;
						case TDUp: targetY -= slideOffset;
						case TDDown: targetY += slideOffset;
					}
					final t = tm.tween(obj, duration, [X(targetX), Y(targetY), Alpha(0.0)], easing);
					final capturedObj = obj;
					t.onComplete = () -> {
						capturedObj.visible = false;
						capturedObj.alpha = preAlpha;
						capturedObj.x = preX;
						capturedObj.y = preY;
					};
					trackTransitionTween(obj, t, preAlpha, preScaleX, preScaleY, preX, preY);
				}

			case TransNone:
				obj.visible = show;
		}
	}
}
