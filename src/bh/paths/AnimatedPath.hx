package bh.paths;

import bh.base.FPoint;
import bh.paths.Curve.ICurve;
import bh.paths.MultiAnimPaths.Path;

enum AnimatedPathMode {
	Distance(baseSpeed:Float);
	Time(duration:Float);
}

@:structInit
class AnimatedPathState {
	public var position:FPoint;
	public var angle:Float;
	public var rate:Float;
	public var speed:Float;
	public var scale:Float;
	public var alpha:Float;
	public var rotation:Float;
	public var done:Bool;
	public var custom:Map<String, Float>;
}

enum CurveSlot {
	Speed;
	Scale;
	Alpha;
	Rotation;
	Progress; // time mode only: maps timeRate -> pathRate
}

@:structInit
private class CurveSegment {
	public var startRate:Float;
	public var curve:ICurve;
}

@:structInit
private class TimedEvent {
	public var atRate:Float;
	public var eventName:String;
}

@:nullSafety
class AnimatedPath {
	public final path:Path;
	final mode:AnimatedPathMode;
	final pathLength:Float;

	var time:Float = 0.;
	var distance:Float = 0.;
	var isDone:Bool = false;
	var started:Bool = false;

	// Curve segments per slot (sorted by startRate)
	var speedCurveSegments:Array<CurveSegment> = [];
	var scaleCurveSegments:Array<CurveSegment> = [];
	var alphaCurveSegments:Array<CurveSegment> = [];
	var rotationCurveSegments:Array<CurveSegment> = [];
	var progressCurveSegments:Array<CurveSegment> = [];
	var customCurveSegments:Map<String, Array<CurveSegment>> = [];

	// Timed events (sorted by atRate)
	var timedEvents:Array<TimedEvent> = [];
	var currentEventIndex:Int = 0;

	// Cached state
	var currentState:AnimatedPathState;

	public dynamic function onUpdate(state:AnimatedPathState):Void {}

	public dynamic function onEvent(eventName:String, state:AnimatedPathState):Void {}

	public function new(path:Path, mode:AnimatedPathMode) {
		this.path = path;
		this.mode = mode;
		this.pathLength = path.totalLength;
		if (pathLength <= 0) throw 'pathLength must be > 0';
		this.currentState = {
			position: new FPoint(0, 0),
			angle: 0.,
			rate: 0.,
			speed: 0.,
			scale: 1.,
			alpha: 1.,
			rotation: 0.,
			done: false,
			custom: []
		};
	}

	public function addCurveSegment(slot:CurveSlot, startRate:Float, curve:ICurve):Void {
		var segments = getSegmentsForSlot(slot);
		insertSorted(segments, {startRate: startRate, curve: curve});
	}

	public function addCustomCurveSegment(name:String, startRate:Float, curve:ICurve):Void {
		if (!customCurveSegments.exists(name)) {
			customCurveSegments.set(name, []);
		}
		var segments = customCurveSegments.get(name);
		if (segments != null)
			insertSorted(segments, {startRate: startRate, curve: curve});
	}

	public function addEvent(atRate:Float, eventName:String):Void {
		var left = 0;
		var right = timedEvents.length;
		while (left < right) {
			var mid = Std.int((left + right) / 2);
			if (timedEvents[mid].atRate < atRate)
				left = mid + 1;
			else
				right = mid;
		}
		timedEvents.insert(left, {atRate: atRate, eventName: eventName});
	}

	public function getState():AnimatedPathState {
		return currentState;
	}

	public function update(dt:Float):AnimatedPathState {
		if (isDone) return currentState;
		if (dt <= 0) return currentState;

		if (!started) {
			started = true;
			computeState(0.);
			fireEvent("pathStart");
			onUpdate(currentState);
		}

		time += dt;

		var rate:Float;
		var effectiveSpeed:Float;

		switch mode {
			case Distance(baseSpeed):
				var currentRate = getDistanceRate();
				var speedMultiplier = evaluateCurveSlot(speedCurveSegments, currentRate);
				effectiveSpeed = baseSpeed * speedMultiplier;
				distance += dt * effectiveSpeed;
				rate = getDistanceRate();

			case Time(duration):
				var timeRate = Math.min(time / duration, 1.0);
				// Progress curve maps time-rate to path-rate
				rate = if (progressCurveSegments.length > 0)
					evaluateCurveSlot(progressCurveSegments, timeRate)
				else
					timeRate;
				effectiveSpeed = if (time > 0) pathLength * rate / time else 0.;
		}

		if (rate >= 1.0) rate = 1.0;

		// Fire events up to current rate
		while (currentEventIndex < timedEvents.length) {
			final ev = timedEvents[currentEventIndex];
			if (ev.atRate <= rate) {
				computeState(ev.atRate);
				currentState.speed = effectiveSpeed;
				fireEvent(ev.eventName);
				currentEventIndex++;
			} else
				break;
		}

		if (rate >= 1.0) {
			computeState(1.0);
			currentState.speed = effectiveSpeed;
			currentState.done = true;
			fireEvent("pathEnd");
			onUpdate(currentState);
			isDone = true;
			return currentState;
		}

		computeState(rate);
		currentState.speed = effectiveSpeed;
		onUpdate(currentState);
		return currentState;
	}

	function computeState(rate:Float):Void {
		currentState.rate = rate;
		currentState.position = path.getPoint(rate);
		currentState.angle = path.getTangentAngle(rate);
		currentState.scale = evaluateCurveSlot(scaleCurveSegments, rate);
		currentState.alpha = evaluateCurveSlot(alphaCurveSegments, rate);
		currentState.rotation = evaluateCurveSlotDefault(rotationCurveSegments, rate, 0.);
		currentState.done = false;

		// Custom curves
		for (name => segments in customCurveSegments) {
			currentState.custom.set(name, evaluateCurveSlot(segments, rate));
		}
	}

	function fireEvent(eventName:String):Void {
		onEvent(eventName, currentState);
	}

	inline function getDistanceRate():Float {
		return if (pathLength <= 0) 0. else Math.min(distance / pathLength, 1.0);
	}

	/** Evaluate curve segments at given rate. Returns 1.0 if no segments. */
	function evaluateCurveSlot(segments:Array<CurveSegment>, rate:Float):Float {
		return evaluateCurveSlotDefault(segments, rate, 1.0);
	}

	/** Evaluate curve segments at given rate with custom default. */
	function evaluateCurveSlotDefault(segments:Array<CurveSegment>, rate:Float, defaultValue:Float):Float {
		if (segments.length == 0) return defaultValue;

		// Find active segment: largest startRate <= rate
		var activeIndex = -1;
		for (i in 0...segments.length) {
			if (segments[i].startRate <= rate)
				activeIndex = i;
			else
				break;
		}

		if (activeIndex < 0) return defaultValue;

		var segment = segments[activeIndex];
		var segStart = segment.startRate;
		var segEnd = if (activeIndex + 1 < segments.length) segments[activeIndex + 1].startRate else 1.0;

		var localT = if (segEnd <= segStart) 0. else (rate - segStart) / (segEnd - segStart);
		localT = Math.min(Math.max(localT, 0.), 1.);

		return segment.curve.getValue(localT);
	}

	function getSegmentsForSlot(slot:CurveSlot):Array<CurveSegment> {
		return switch slot {
			case Speed: speedCurveSegments;
			case Scale: scaleCurveSegments;
			case Alpha: alphaCurveSegments;
			case Rotation: rotationCurveSegments;
			case Progress: progressCurveSegments;
		};
	}

	function insertSorted(segments:Array<CurveSegment>, segment:CurveSegment):Void {
		var left = 0;
		var right = segments.length;
		while (left < right) {
			var mid = Std.int((left + right) / 2);
			if (segments[mid].startRate < segment.startRate)
				left = mid + 1;
			else
				right = mid;
		}
		segments.insert(left, segment);
	}
}
