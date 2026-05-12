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

// Public so tests can read `TweenPropertyEntry.creationCount`. Otherwise still an
// implementation detail of the Tween class — fields are not consumed externally.
class TweenPropertyEntry {
	// Allocation watchdog for tests. Gated behind MULTIANIM_ALLOC_TRACK so the
	// per-construction increment vanishes from production builds. With pooling,
	// `creationCount` only grows when the free-list is empty (initial fill or
	// burst beyond the high-water mark); steady-state UI churn produces 0.
	#if MULTIANIM_ALLOC_TRACK
	public static var creationCount:Int = 0;
	#end

	static var _pool:Array<TweenPropertyEntry> = [];

	public var kind:TweenPropertyKind;
	public var from:Float;
	public var to:Float;

	function new(kind:TweenPropertyKind, to:Float) {
		this.kind = kind;
		this.to = to;
		this.from = 0.0;
		#if MULTIANIM_ALLOC_TRACK
		creationCount++;
		#end
	}

	public static inline function acquire(kind:TweenPropertyKind, to:Float):TweenPropertyEntry {
		// pop() is Null<T>; narrow via explicit check rather than relying on length.
		var e = _pool.pop();
		if (e != null) {
			e.kind = kind;
			e.to = to;
			e.from = 0.0;
			return e;
		}
		return new TweenPropertyEntry(kind, to);
	}

	public static inline function release(entry:TweenPropertyEntry):Void {
		// KCustom holds two closures that may capture game state — reset to a
		// closure-free variant so released entries don't pin objects in memory.
		entry.kind = KAlpha;
		entry.from = 0.0;
		entry.to = 0.0;
		_pool.push(entry);
	}
}

private enum TweenHandle {
	HTween(tween:Tween);
	HSequence(seq:TweenSequence);
	HGroup(group:TweenGroup);
}

@:nullSafety
class Tween {
	// Allocation watchdog for tests. Gated behind MULTIANIM_ALLOC_TRACK so the
	// per-construction increment vanishes from production builds. With pooling,
	// `creationCount` only grows when the free-list is empty (initial fill or
	// burst beyond the high-water mark); steady-state UI churn produces 0.
	#if MULTIANIM_ALLOC_TRACK
	public static var creationCount:Int = 0;
	#end

	static var _pool:Array<Tween> = [];

	public var target(default, null):h2d.Object;
	public var duration(default, null):Float;
	public var elapsed(default, null):Float = 0.0;
	public var onComplete:Null<Void -> Void> = null;
	public var cancelled(default, null):Bool = false;

	var easing:Null<EasingType>;
	var entries:Array<TweenPropertyEntry>;
	var initialized:Bool = false;
	/** When true, the first step() discards its dt to avoid a large initial
	    jump after expensive frame operations (e.g. adding scene roots). */
	public var skipFirstDt:Bool = false;
	/** When true, TweenManager.update() removes target from its parent after
	    onComplete fires. Set by fadeOut(removeOnComplete=true) in lieu of a
	    per-call `() -> target.remove()` closure. Skipped on cancellation, so
	    behavior matches the prior closure-on-onComplete path exactly. */
	public var removeTargetOnComplete:Bool = false;

	public function new(target:h2d.Object, duration:Float, properties:Array<TweenProperty>, ?easing:EasingType) {
		this.target = target;
		this.duration = duration;
		this.easing = easing;
		this.entries = [];
		#if MULTIANIM_ALLOC_TRACK
		creationCount++;
		#end
		loadProperties(properties);
	}

	public static inline function acquire(target:h2d.Object, duration:Float, properties:Array<TweenProperty>,
			?easing:EasingType):Tween {
		var t = _pool.pop();
		if (t != null) {
			t.target = target;
			t.duration = duration;
			t.easing = easing;
			t.elapsed = 0.0;
			t.onComplete = null;
			t.cancelled = false;
			t.initialized = false;
			t.skipFirstDt = false;
			t.removeTargetOnComplete = false;
			t.loadProperties(properties);
			return t;
		}
		return new Tween(target, duration, properties, easing);
	}

	/** Release a tween to the shared pool. Recycles owned entries internally
	    so callers only need release(). External references are typically nulled
	    by the time release runs (manager calls this after onComplete fires —
	    helpers like UIPanelHelper null their tracked tween in onComplete). */
	public static inline function release(tween:Tween):Void {
		tween.recycleEntries();
		// Drop callback so a pooled instance does not pin closure-captured state.
		tween.onComplete = null;
		// `target` intentionally not nulled — type is non-nullable, pool depth
		// stays small in practice (typically 1-3 instances under steady churn),
		// and each pooled instance pins exactly one h2d.Object reference.
		_pool.push(tween);
	}

	inline function loadProperties(properties:Array<TweenProperty>):Void {
		for (prop in properties) {
			switch prop {
				case Alpha(to):
					entries.push(TweenPropertyEntry.acquire(KAlpha, to));
				case X(to):
					entries.push(TweenPropertyEntry.acquire(KX, to));
				case Y(to):
					entries.push(TweenPropertyEntry.acquire(KY, to));
				case ScaleX(to):
					entries.push(TweenPropertyEntry.acquire(KScaleX, to));
				case ScaleY(to):
					entries.push(TweenPropertyEntry.acquire(KScaleY, to));
				case Scale(to):
					entries.push(TweenPropertyEntry.acquire(KScaleX, to));
					entries.push(TweenPropertyEntry.acquire(KScaleY, to));
				case Rotation(to):
					entries.push(TweenPropertyEntry.acquire(KRotation, to));
				case Custom(getter, setter, to):
					entries.push(TweenPropertyEntry.acquire(KCustom(getter, setter), to));
			}
		}
	}

	/** Return all entries to the shared pool. Idempotent — safe to call twice. */
	public function recycleEntries():Void {
		for (entry in entries) {
			TweenPropertyEntry.release(entry);
		}
		// Empty in place rather than reallocating; subsequent step() calls will
		// see no entries and become no-ops, matching cancelled-tween semantics.
		entries.resize(0);
	}

	public function setOnComplete(cb:Void -> Void):Tween {
		this.onComplete = cb;
		return this;
	}

	public function cancel():Void {
		cancelled = true;
	}

	/** Fire onComplete and apply removeTargetOnComplete in that order. Called at
	    every per-tween completion site (HTween arm, sequence step/finish, group
	    step/finish) so the flag is honored uniformly whether the tween runs bare
	    or wrapped in a sequence/group. Not invoked on cancel — matches the prior
	    closure-on-onComplete behavior. */
	public function runCompletionHooks():Void {
		var cb = onComplete;
		if (cb != null)
			cb();
		if (removeTargetOnComplete)
			target.remove();
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

		// Zero (or negative) duration is a "skip" intent — snap to the final
		// state and complete immediately. Without this, elapsed/duration is
		// 0/0=NaN (or Infinity for dt>0), clamp is not NaN-aware, and lerp
		// propagates NaN into target.alpha/x/y/scale/rotation.
		if (duration <= 0) {
			for (entry in entries) {
				setPropertyValue(entry.kind, entry.to);
			}
			elapsed = duration;
			return true;
		}

		// When skipFirstDt is set, discard the first step's dt to avoid a
		// large initial jump (e.g. the frame that added new scene roots may
		// have caused a render spike).
		if (skipFirstDt) {
			skipFirstDt = false;
			return false;
		}

		elapsed += dt;
		var t = FloatTools.clamp(elapsed / duration, 0.0, 1.0);
		// Inline dispatch in lieu of an `easingFn:Float -> Float` closure that
		// previously had to be allocated per Tween (one of the per-call allocs
		// we're explicitly here to remove). Linear shortcut keeps the no-easing
		// path branch-free.
		final e = easing;
		var easedT = e == null ? t : FloatTools.applyEasing(e, t);

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
		for (tween in tweens)
			tween.cancel();
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
			if (current.cancelled) {
				currentIndex++;
				continue;
			}
			current.init();
			if (!current.step(remainingDt))
				return false;
			current.runCompletionHooks();
			currentIndex++;
			remainingDt = current.elapsed - current.duration;
			if (remainingDt <= 0)
				break;
		}
		return currentIndex >= tweens.length;
	}

	/** Jump all remaining tweens to their final state. */
	public function finish():Void {
		if (cancelled)
			return;
		while (currentIndex < tweens.length) {
			var current = tweens[currentIndex];
			if (current.cancelled) {
				currentIndex++;
				continue;
			}
			current.init();
			current.finish();
			current.runCompletionHooks();
			currentIndex++;
		}
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
				if (tween.step(dt)) {
					// Per-tween onComplete is fired only in finish() for groups
					// (intentional pre-existing asymmetry with TweenSequence);
					// removeTargetOnComplete still has to fire wherever the tween
					// actually completes, otherwise the flag is silently dropped
					// for tweens wrapped in a group.
					if (tween.removeTargetOnComplete)
						tween.target.remove();
				} else {
					allDone = false;
				}
			}
		}
		return allDone;
	}

	/** Jump all tweens to their final state. */
	public function finish():Void {
		if (cancelled)
			return;
		for (tween in tweens) {
			if (tween.cancelled)
				continue;
			tween.init();
			tween.finish();
			tween.runCompletionHooks();
		}
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
						tween.runCompletionHooks();
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
				recycleHandle(handle);
				handles[i] = handles[handles.length - 1];
				handles.pop();
			} else {
				i++;
			}
		}
	}

	static function recycleHandle(handle:TweenHandle):Void {
		// Tween.release recycles owned entries internally, then returns the
		// instance to the shared pool — replaces the prior recycleEntries-only
		// path so the Tween itself is also reused at steady state.
		switch handle {
			case HTween(tween):
				Tween.release(tween);
			case HSequence(seq):
				for (tween in seq.tweens)
					Tween.release(tween);
			case HGroup(group):
				for (tween in group.tweens)
					Tween.release(tween);
		}
	}

	/** Create and start a tween on a target object. */
	public function tween(target:h2d.Object, duration:Float, properties:Array<TweenProperty>, ?easing:EasingType):Tween {
		var t = Tween.acquire(target, duration, properties, easing);
		t.init();
		handles.push(HTween(t));
		return t;
	}

	/** Create a tween without starting it (for use in sequences). */
	public function createTween(target:h2d.Object, duration:Float, properties:Array<TweenProperty>, ?easing:EasingType):Tween {
		return Tween.acquire(target, duration, properties, easing);
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
					if (allCancelled(seq.tweens))
						seq.cancel();
				case HGroup(group):
					for (tween in group.tweens) {
						if (tween.target == target)
							tween.cancel();
					}
					if (allCancelled(group.tweens))
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
			recycleHandle(handle);
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
		// Flag instead of `setOnComplete(() -> target.remove())` — the closure
		// captured `target` and was allocated per call, defeating Tween pooling
		// for fadeOut-heavy paths (panel/tooltip close, screen transitions).
		// TweenManager.update applies this after onComplete fires.
		if (removeOnComplete) {
			t.removeTargetOnComplete = true;
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
