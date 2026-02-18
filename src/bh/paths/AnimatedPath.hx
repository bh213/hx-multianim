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
	public var color:Int;
	public var done:Bool;
	public var cycle:Int;
	public var custom:Map<String, Float>;
}

enum CurveSlot {
	Speed;
	Scale;
	Alpha;
	Rotation;
	Progress; // time mode only: maps timeRate -> pathRate
	Color; // maps rate -> 0..1 interpolation between startColor and endColor
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

	public var loop:Bool = false;
	public var pingPong:Bool = false;

	var time:Float = 0.;
	var distance:Float = 0.;
	var isDone:Bool = false;
	var started:Bool = false;
	var cycleCount:Int = 0;
	var reversed:Bool = false;

	// Curve segments per slot (sorted by startRate)
	var speedCurveSegments:Array<CurveSegment> = [];
	var scaleCurveSegments:Array<CurveSegment> = [];
	var alphaCurveSegments:Array<CurveSegment> = [];
	var rotationCurveSegments:Array<CurveSegment> = [];
	var progressCurveSegments:Array<CurveSegment> = [];
	var colorCurveSegments:Array<CurveSegment> = [];
	var customCurveSegments:Map<String, Array<CurveSegment>> = [];

	// Color interpolation endpoints (set via setColorRange)
	var colorStart:Int = 0xFFFFFF;
	var colorEnd:Int = 0xFFFFFF;

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
			color: 0xFFFFFF,
			done: false,
			cycle: 0,
			custom: []
		};
	}

	public function addCurveSegment(slot:CurveSlot, startRate:Float, curve:ICurve):Void {
		var segments = getSegmentsForSlot(slot);
		insertSorted(segments, {startRate: startRate, curve: curve});
	}

	public function setColorRange(startColor:Int, endColor:Int):Void {
		this.colorStart = startColor;
		this.colorEnd = endColor;
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

	public function reset():Void {
		time = 0.;
		distance = 0.;
		isDone = false;
		started = false;
		currentEventIndex = 0;
		cycleCount = 0;
		reversed = false;
	}

	public function getState():AnimatedPathState {
		return currentState;
	}

	/** Compute and return the path state at an arbitrary rate (0..1) without
	 *  advancing internal time/distance or firing events. */
	public function seek(rate:Float):AnimatedPathState {
		computeState(rate);
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
		var modeComplete = false;

		switch mode {
			case Distance(baseSpeed):
				var currentRate = getDistanceRate();
				var speedMultiplier = evaluateCurveSlot(speedCurveSegments, currentRate);
				effectiveSpeed = baseSpeed * speedMultiplier;
				distance += dt * effectiveSpeed;
				rate = getDistanceRate();
				modeComplete = rate >= 1.0;

			case Time(duration):
				var timeRate = Math.min(time / duration, 1.0);
				// Progress curve maps time-rate to path-rate
				rate = if (progressCurveSegments.length > 0)
					evaluateCurveSlot(progressCurveSegments, timeRate)
				else
					timeRate;
				effectiveSpeed = if (time > 0) pathLength * rate / time else 0.;
				// In Time mode, done when time elapses — not when rate overshoots
				// (progress curves like EaseOutElastic overshoot past 1.0 to create bounce)
				modeComplete = timeRate >= 1.0;
		}

		// Fire events up to current rate
		while (currentEventIndex < timedEvents.length) {
			final ev = timedEvents[currentEventIndex];
			if (ev.atRate <= rate) {
				computeState(if (reversed) 1.0 - ev.atRate else ev.atRate);
				currentState.speed = effectiveSpeed;
				currentState.cycle = cycleCount;
				fireEvent(ev.eventName);
				currentEventIndex++;
			} else
				break;
		}

		if (modeComplete) {
			if (loop || pingPong) {
				// Complete this cycle
				computeState(if (reversed) 0. else 1.0);
				currentState.speed = effectiveSpeed;
				currentState.cycle = cycleCount;
				fireEvent("cycleEnd");
				onUpdate(currentState);

				// Start new cycle
				cycleCount++;
				currentEventIndex = 0;
				switch mode {
					case Time(duration): time -= duration;
					case Distance(_): distance -= pathLength;
				}
				if (pingPong) reversed = !reversed;
				fireEvent("cycleStart");
				// Re-compute rate for remainder of this frame
				switch mode {
					case Distance(baseSpeed):
						rate = getDistanceRate();
					case Time(duration):
						var timeRate = Math.min(time / duration, 1.0);
						rate = if (progressCurveSegments.length > 0) evaluateCurveSlot(progressCurveSegments, timeRate) else timeRate;
				}
				if (reversed) rate = 1.0 - rate;
				computeState(rate);
				currentState.speed = effectiveSpeed;
				currentState.cycle = cycleCount;
				onUpdate(currentState);
				return currentState;
			}
			computeState(1.0);
			currentState.speed = effectiveSpeed;
			currentState.cycle = cycleCount;
			currentState.done = true;
			fireEvent("pathEnd");
			onUpdate(currentState);
			isDone = true;
			return currentState;
		}

		if (reversed) rate = 1.0 - rate;
		computeState(rate);
		currentState.speed = effectiveSpeed;
		currentState.cycle = cycleCount;
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
		if (colorCurveSegments.length > 0)
			currentState.color = lerpColor(colorStart, colorEnd, evaluateCurveSlotDefault(colorCurveSegments, rate, 0.));
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
			case Color: colorCurveSegments;
		};
	}

	static inline function lerpColor(c1:Int, c2:Int, t:Float):Int {
		var r1 = (c1 >> 16) & 0xFF;
		var g1 = (c1 >> 8) & 0xFF;
		var b1 = c1 & 0xFF;
		var r2 = (c2 >> 16) & 0xFF;
		var g2 = (c2 >> 8) & 0xFF;
		var b2 = c2 & 0xFF;
		var r = Std.int(r1 + (r2 - r1) * t);
		var g = Std.int(g1 + (g2 - g1) * t);
		var b = Std.int(b1 + (b2 - b1) * t);
		return (r << 16) | (g << 8) | b;
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
