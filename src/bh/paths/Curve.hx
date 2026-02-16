package bh.paths;

import bh.multianim.MultiAnimParser.EasingType;
import bh.base.TweenUtils.FloatTools;

/** Interface for a 1D curve that maps a 0..1 input to a float output. */
interface ICurve {
	public function getValue(t:Float):Float;
}

/** A 1D curve that maps a 0..1 input to a float output.
 *  Can be defined by a named easing function, explicit control points, or easing segments. */
class Curve implements ICurve {
	var points:Null<Array<CurvePoint>>;
	var easing:Null<EasingType>;
	var segments:Null<Array<CurveSegment>>;

	public function new(?points:Array<CurvePoint>, ?easing:EasingType, ?segments:Array<CurveSegment>) {
		this.points = points;
		this.easing = easing;
		this.segments = segments;
	}

	/** Evaluate the curve at normalized time t (0..1). */
	public function getValue(t:Float):Float {
		t = FloatTools.clamp(t, 0.0, 1.0);

		if (easing != null) {
			return FloatTools.applyEasing(easing, t);
		}

		if (points != null && points.length > 0) {
			if (points.length == 1) return points[0].value;

			// Clamp to endpoints
			if (t <= points[0].time) return points[0].value;
			if (t >= points[points.length - 1].time) return points[points.length - 1].value;

			// Find segment and linearly interpolate
			for (i in 0...points.length - 1) {
				if (t >= points[i].time && t <= points[i + 1].time) {
					final segT = (t - points[i].time) / (points[i + 1].time - points[i].time);
					return FloatTools.lerp(segT, points[i].value, points[i + 1].value);
				}
			}
			return points[points.length - 1].value;
		}

		if (segments != null && segments.length > 0) {
			return evaluateSegments(t);
		}

		return t;
	}

	private function evaluateSegments(t:Float):Float {
		// Weighted blend of all segments containing t (smooth cross-fade for true overlaps).
		// Uses half-open intervals [start, end) so back-to-back segments don't count as overlap.
		var totalWeight:Float = 0.0;
		var weightedSum:Float = 0.0;

		// Track nearest segments for gap/endpoint interpolation
		var leftEnd:Float = Math.NEGATIVE_INFINITY;
		var leftValue:Float = 0.0;
		var rightStart:Float = Math.POSITIVE_INFINITY;
		var rightValue:Float = 0.0;

		for (seg in segments) {
			// Half-open: [timeStart, timeEnd) — back-to-back boundaries belong to the next segment
			if (t >= seg.timeStart && t < seg.timeEnd) {
				final segDuration = seg.timeEnd - seg.timeStart;
				final localT = if (segDuration <= 0.0) 0.0 else (t - seg.timeStart) / segDuration;
				final easedT = FloatTools.applyEasing(seg.easing, localT);
				final value = FloatTools.lerp(easedT, seg.valueStart, seg.valueEnd);
				// Triangular weight: ~0 at edges, 1 at center — gives smooth cross-fade in true overlaps
				final halfDur = segDuration * 0.5;
				final weight = if (halfDur <= 0.0) 1.0 else Math.max(Math.min((t - seg.timeStart) / halfDur, (seg.timeEnd - t) / halfDur), 1e-6);
				totalWeight += weight;
				weightedSum += weight * value;
			} else if (seg.timeEnd <= t && seg.timeEnd > leftEnd) {
				leftEnd = seg.timeEnd;
				leftValue = seg.valueEnd;
			} else if (seg.timeStart > t && seg.timeStart < rightStart) {
				rightStart = seg.timeStart;
				rightValue = seg.valueStart;
			}
		}

		if (totalWeight > 0.0) return weightedSum / totalWeight;

		// t exactly at a segment endpoint (e.g. t=1.0 at last segment's end): use that segment's end value
		if (leftEnd == t) return leftValue;

		// Gap: linearly interpolate between nearest left end and right start
		final hasLeft = leftEnd != Math.NEGATIVE_INFINITY;
		final hasRight = rightStart != Math.POSITIVE_INFINITY;
		if (hasLeft && hasRight) {
			final gapT = (t - leftEnd) / (rightStart - leftEnd);
			return FloatTools.lerp(gapT, leftValue, rightValue);
		}
		if (hasLeft) return leftValue;
		if (hasRight) return rightValue;
		return t;
	}
}

typedef CurvePoint = {
	var time:Float;
	var value:Float;
};

typedef CurveSegment = {
	var timeStart:Float;
	var timeEnd:Float;
	var easing:EasingType;
	var valueStart:Float;
	var valueEnd:Float;
};
