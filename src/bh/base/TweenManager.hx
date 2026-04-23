package bh.base;

import bh.multianim.MultiAnimParser.EasingType;

using bh.base.TweenUtils;

enum TweenProperty {
	Alpha(to:Float);
	X(to:Float);
	Y(to:Float);
	ScaleX(to:Float);
	ScaleY(to:Float);
	Scale(to:Float);
	Rotation(to:Float);
	Custom(getter:Void -> Float, setter:Float -> Void, to:Float);
}

enum SlideDirection {
	Left;
	Right;
	Up;
	Down;
}

private enum TweenPropertyKind {
	KAlpha;
	KX;
	KY;
	KScaleX;
	KScaleY;
	KRotation;
	KCustom(getter:Void -> Float, setter:Float -> Void);
}

private class TweenPropertyEntry {
	public var kind:TweenPropertyKind;
	public var from:Float;
	public var to:Float;

	public function new(kind:TweenPropertyKind, to:Float) {
		this.kind = kind;
		this.to = to;
		this.from = 0.0;
	}
}

private enum TweenHandle {
	HTween(tween:Tween);
	HSequence(seq:TweenSequence);
	HGroup(group:TweenGroup);
}

@:nullSafety
class Tween {
	public var target(default, null):h2d.Object;
	public var duration(default, null):Float;
	public var elapsed(default, null):Float = 0.0;
	public var onComplete:Null<Void -> Void> = null;
	public var cancelled(default, null):Bool = false;

	var easingFn:Float -> Float;
	var entries:Array<TweenPropertyEntry>;
	var initialized:Bool = false;
	/** When true, the first step() discards its dt to avoid a large initial
	    jump after expensive frame operations (e.g. adding scene roots). */
	public var skipFirstDt:Bool = false;

	public function new(target:h2d.Object, duration:Float, properties:Array<TweenProperty>, ?easing:EasingType) {
		this.target = target;
		this.duration = duration;
		this.easingFn = easing != null ? (t) -> FloatTools.applyEasing(easing, t) : (t) -> t;
		this.entries = [];
		for (prop in properties) {
			switch prop {
				case Alpha(to):
					entries.push(new TweenPropertyEntry(KAlpha, to));
				case X(to):
					entries.push(new TweenPropertyEntry(KX, to));
				case Y(to):
					entries.push(new TweenPropertyEntry(KY, to));
				case ScaleX(to):
					entries.push(new TweenPropertyEntry(KScaleX, to));
				case ScaleY(to):
					entries.push(new TweenPropertyEntry(KScaleY, to));
				case Scale(to):
					entries.push(new TweenPropertyEntry(KScaleX, to));
					entries.push(new TweenPropertyEntry(KScaleY, to));
				case Rotation(to):
					entries.push(new TweenPropertyEntry(KRotation, to));
				case Custom(getter, setter, to):
					entries.push(new TweenPropertyEntry(KCustom(getter, setter), to));
			}
		}
	}

	public function setOnComplete(cb:Void -> Void):Tween {
		this.onComplete = cb;
		return this;
	}

	public function cancel():Void {
		cancelled = true;
	}

	/** Captures current property values as "from". Called when the tween starts running. */
	public function init():Void {
		if (initialized)
			return;
		initialized = true;
		for (entry in entries) {
			entry.from = getPropertyValue(entry.kind);
		}
	}

	/** Advance the tween by dt. Returns true when the tween is complete. */
	public function step(dt:Float):Bool {
		if (cancelled)
			return true;
		if (!initialized)
			init();

		// When skipFirstDt is set, discard the first step's dt to avoid a
		// large initial jump (e.g. the frame that added new scene roots may
		// have caused a render spike).
		if (skipFirstDt) {
			skipFirstDt = false;
			return false;
		}

		elapsed += dt;
		var t = FloatTools.clamp(elapsed / duration, 0.0, 1.0);
		var easedT = easingFn(t);

		for (entry in entries) {
			var value = FloatTools.lerp(easedT, entry.from, entry.to);
			setPropertyValue(entry.kind, value);
		}

		return elapsed >= duration;
	}

	/** Jump to the final state immediately. */
	public function finish():Void {
		if (!initialized)
			init();
		for (entry in entries) {
			setPropertyValue(entry.kind, entry.to);
		}
		elapsed = duration;
	}

	function getPropertyValue(kind:TweenPropertyKind):Float {
		return switch kind {
			case KAlpha: target.alpha;
			case KX: target.x;
			case KY: target.y;
			case KScaleX: target.scaleX;
			case KScaleY: target.scaleY;
			case KRotation: target.rotation;
			case KCustom(getter, _): getter();
		};
	}

	function setPropertyValue(kind:TweenPropertyKind, value:Float):Void {
		switch kind {
			case KAlpha:
				target.alpha = value;
			case KX:
				target.x = value;
			case KY:
				target.y = value;
			case KScaleX:
				target.scaleX = value;
			case KScaleY:
				target.scaleY = value;
			case KRotation:
				target.rotation = value;
			case KCustom(_, setter):
				setter(value);
		}
	}
}

@:nullSafety
class TweenSequence {
	public var tweens(default, null):Array<Tween>;
	public var onComplete:Null<Void -> Void> = null;
	public var cancelled(default, null):Bool = false;

	var currentIndex:Int = 0;

	public function new(tweens:Array<Tween>) {
		this.tweens = tweens;
	}

	public function setOnComplete(cb:Void -> Void):TweenSequence {
		this.onComplete = cb;
		return this;
	}

	public function cancel():Void {
		cancelled = true;
		if (currentIndex < tweens.length)
			tweens[currentIndex].cancel();
	}

	/** Advance the sequence. Returns true when all tweens are complete. */
	public function step(dt:Float):Bool {
		if (cancelled)
			return true;
		// Loop instead of recursing so that a huge dt spanning many short tweens
		// (debugger pause, paused tab) doesn't grow the native stack per tween.
		var remainingDt = dt;
		while (currentIndex < tweens.length) {
			var current = tweens[currentIndex];
			current.init();
			if (!current.step(remainingDt))
				return false;
			var cb = current.onComplete;
			if (cb != null)
				cb();
			currentIndex++;
			remainingDt = current.elapsed - current.duration;
			if (remainingDt <= 0)
				break;
		}
		return currentIndex >= tweens.length;
	}

	/** Jump all remaining tweens to their final state. */
	public function finish():Void {
		while (currentIndex < tweens.length) {
			var current = tweens[currentIndex];
			current.init();
			current.finish();
			var cb = current.onComplete;
			if (cb != null)
				cb();
			currentIndex++;
		}
	}

	public function getTargets():Array<h2d.Object> {
		var targets:Array<h2d.Object> = [];
		for (tween in tweens) {
			if (!targets.contains(tween.target))
				targets.push(tween.target);
		}
		return targets;
	}
}

@:nullSafety
class TweenGroup {
	public var tweens(default, null):Array<Tween>;
	public var onComplete:Null<Void -> Void> = null;
	public var cancelled(default, null):Bool = false;

	public function new(tweens:Array<Tween>) {
		this.tweens = tweens;
		for (tween in tweens)
			tween.init();
	}

	public function setOnComplete(cb:Void -> Void):TweenGroup {
		this.onComplete = cb;
		return this;
	}

	public function cancel():Void {
		cancelled = true;
		for (tween in tweens)
			tween.cancel();
	}

	/** Advance all tweens. Returns true when all are complete. */
	public function step(dt:Float):Bool {
		if (cancelled)
			return true;

		var allDone = true;
		for (tween in tweens) {
			if (!tween.cancelled && tween.elapsed < tween.duration) {
				if (!tween.step(dt))
					allDone = false;
			}
		}
		return allDone;
	}

	/** Jump all tweens to their final state. */
	public function finish():Void {
		for (tween in tweens) {
			tween.init();
			tween.finish();
			var cb = tween.onComplete;
			if (cb != null)
				cb();
		}
	}

	public function getTargets():Array<h2d.Object> {
		var targets:Array<h2d.Object> = [];
		for (tween in tweens) {
			if (!targets.contains(tween.target))
				targets.push(tween.target);
		}
		return targets;
	}
}

@:nullSafety
class TweenManager {
	var handles:Array<TweenHandle> = [];

	public function new() {}

	/** Step all active tweens. Call from ScreenManager.update(dt). */
	public function update(dt:Float):Void {
		var i = 0;
		while (i < handles.length) {
			var handle = handles[i];
			var done = false;
			switch handle {
				case HTween(tween):
					if (tween.cancelled) {
						done = true;
					} else if (tween.step(dt)) {
						done = true;
						var cb = tween.onComplete;
						if (cb != null)
							cb();
					}
				case HSequence(seq):
					if (seq.cancelled) {
						done = true;
					} else if (seq.step(dt)) {
						done = true;
						var cb = seq.onComplete;
						if (cb != null)
							cb();
					}
				case HGroup(group):
					if (group.cancelled) {
						done = true;
					} else if (group.step(dt)) {
						done = true;
						var cb = group.onComplete;
						if (cb != null)
							cb();
					}
			}
			if (done) {
				handles[i] = handles[handles.length - 1];
				handles.pop();
			} else {
				i++;
			}
		}
	}

	/** Create and start a tween on a target object. */
	public function tween(target:h2d.Object, duration:Float, properties:Array<TweenProperty>, ?easing:EasingType):Tween {
		var t = new Tween(target, duration, properties, easing);
		t.init();
		handles.push(HTween(t));
		return t;
	}

	/** Create a tween without starting it (for use in sequences). */
	public function createTween(target:h2d.Object, duration:Float, properties:Array<TweenProperty>, ?easing:EasingType):Tween {
		return new Tween(target, duration, properties, easing);
	}

	/** Cancel a specific tween. */
	public function cancel(t:Tween):Void {
		t.cancel();
	}

	/** Cancel all tweens targeting a specific object. */
	public function cancelAll(target:h2d.Object):Void {
		for (handle in handles) {
			switch handle {
				case HTween(tween):
					if (tween.target == target)
						tween.cancel();
				case HSequence(seq):
					for (tween in seq.tweens) {
						if (tween.target == target)
							tween.cancel();
					}
					if (seq.getTargets().length == 0 || allCancelled(seq.tweens))
						seq.cancel();
				case HGroup(group):
					for (tween in group.tweens) {
						if (tween.target == target)
							tween.cancel();
					}
					if (group.getTargets().length == 0 || allCancelled(group.tweens))
						group.cancel();
			}
		}
	}

	/** Cancel all tweens targeting the given root or any of its descendants. */
	public function cancelAllChildren(root:h2d.Object):Void {
		for (handle in handles) {
			switch handle {
				case HTween(tween):
					if (isChildOf(tween.target, root))
						tween.cancel();
				case HSequence(seq):
					for (tween in seq.tweens) {
						if (isChildOf(tween.target, root))
							tween.cancel();
					}
					if (allCancelled(seq.tweens))
						seq.cancel();
				case HGroup(group):
					for (tween in group.tweens) {
						if (isChildOf(tween.target, root))
							tween.cancel();
					}
					if (allCancelled(group.tweens))
						group.cancel();
			}
		}
	}

	/** Cancel all active tweens. */
	public function clear():Void {
		for (handle in handles) {
			switch handle {
				case HTween(tween):
					tween.cancel();
				case HSequence(seq):
					seq.cancel();
				case HGroup(group):
					group.cancel();
			}
		}
		handles = [];
	}

	/** Check if any tweens target this object. */
	public function hasTweens(target:h2d.Object):Bool {
		for (handle in handles) {
			switch handle {
				case HTween(tween):
					if (tween.target == target && !tween.cancelled)
						return true;
				case HSequence(seq):
					if (!seq.cancelled) {
						for (tween in seq.tweens) {
							if (tween.target == target && !tween.cancelled)
								return true;
						}
					}
				case HGroup(group):
					if (!group.cancelled) {
						for (tween in group.tweens) {
							if (tween.target == target && !tween.cancelled)
								return true;
						}
					}
			}
		}
		return false;
	}

	/** Start a sequence of tweens (run one after another). */
	public function sequence(tweens:Array<Tween>):TweenSequence {
		var seq = new TweenSequence(tweens);
		handles.push(HSequence(seq));
		return seq;
	}

	/** Start a group of tweens (run in parallel). */
	public function group(tweens:Array<Tween>):TweenGroup {
		var grp = new TweenGroup(tweens);
		handles.push(HGroup(grp));
		return grp;
	}

	// ==================== Convenience methods ====================

	/** Fade alpha from current to 1.0. */
	public function fadeIn(target:h2d.Object, duration:Float, ?easing:EasingType):Tween {
		return tween(target, duration, [Alpha(1.0)], easing);
	}

	/** Fade alpha from current to 0.0. Optionally remove the object when done. */
	public function fadeOut(target:h2d.Object, duration:Float, ?easing:EasingType, removeOnComplete:Bool = false):Tween {
		var t = tween(target, duration, [Alpha(0.0)], easing);
		if (removeOnComplete) {
			t.setOnComplete(() -> target.remove());
		}
		return t;
	}

	/** Move to a target position. */
	public function moveTo(target:h2d.Object, x:Float, y:Float, duration:Float, ?easing:EasingType):Tween {
		return tween(target, duration, [X(x), Y(y)], easing);
	}

	/** Scale uniformly to a target value. */
	public function scaleTo(target:h2d.Object, scale:Float, duration:Float, ?easing:EasingType):Tween {
		return tween(target, duration, [Scale(scale)], easing);
	}

	// ==================== Internal ====================

	static function allCancelled(tweens:Array<Tween>):Bool {
		for (tween in tweens)
			if (!tween.cancelled) return false;
		return true;
	}

	static function isChildOf(obj:h2d.Object, root:h2d.Object):Bool {
		var current:Null<h2d.Object> = obj;
		while (current != null) {
			if (current == root)
				return true;
			current = current.parent;
		}
		return false;
	}
}
