package bh.base;

// Taken from https://github.com/shohei909/tweenx due to warning in tweenxcore library.

class FloatTools {
	/* Clamps a `value` between `min` and `max`. */
	public static inline function clamp(value:Float, min:Float = 0.0, max:Float = 1.0):Float {
		return if (value <= min) min else if (max <= value) max else value;
	}

	/** Linear interpolation between `from` and `to` by `rate` */
	public static inline function lerp(rate:Float, from:Float, to:Float):Float {
		return from * (1 - rate) + to * rate;
	}

	/** Normalizes a `value` within the range between `from` and `to` into a value between 0 and 1 */
	public static inline function inverseLerp(value:Float, from:Float, to:Float):Float {
		return (value - from) / (to - from);
	}

	public static inline function bezier2(rate:Float, from:Float, control:Float, to:Float):Float {
		return lerp(rate, lerp(rate, from, control), lerp(rate, control, to));
	}

	/** Cubic Bernstein polynomial  */
	public static inline function bezier3(rate:Float, from:Float, control1:Float, control2:Float, to:Float):Float {
		return bezier2(rate, lerp(rate, from, control1), lerp(rate, control1, control2), lerp(rate, control2, to));
	}

	/** Bernstein polynomial, which is the mathematical basis for Bézier curve */
	public static inline function bezier(rate:Float, values:Array<Float>):Float {
		return if (values.length < 2) {
			throw "points length must be more than 2";
		} else if (values.length == 2) {
			lerp(rate, values[0], values[1]);
		} else if (values.length == 3) {
			bezier2(rate, values[0], values[1], values[2]);
		} else {
			_bezier(rate, values);
		}
	}

	static function _bezier(rate:Float, values:Array<Float>) {
		if (values.length == 4) {
			return bezier3(rate, values[0], values[1], values[2], values[3]);
		}

		return _bezier(rate, [for (i in 0...values.length - 1) lerp(rate, values[i], values[i + 1])]);
	}

	// ==================== Easing Functions ====================
	// All take t in [0,1] and return a value in [0,1] (approximately, some overshoot).

	public static inline function easeInQuad(t:Float):Float {
		return t * t;
	}

	public static inline function easeOutQuad(t:Float):Float {
		return t * (2.0 - t);
	}

	public static inline function easeInOutQuad(t:Float):Float {
		return if (t < 0.5) 2.0 * t * t else -1.0 + (4.0 - 2.0 * t) * t;
	}

	public static inline function easeInCubic(t:Float):Float {
		return t * t * t;
	}

	public static inline function easeOutCubic(t:Float):Float {
		final u = t - 1.0;
		return u * u * u + 1.0;
	}

	public static inline function easeInOutCubic(t:Float):Float {
		return if (t < 0.5) 4.0 * t * t * t else (t - 1.0) * (2.0 * t - 2.0) * (2.0 * t - 2.0) + 1.0;
	}

	public static function easeInBack(t:Float):Float {
		final c1 = 1.70158;
		final c3 = c1 + 1.0;
		return c3 * t * t * t - c1 * t * t;
	}

	public static function easeOutBack(t:Float):Float {
		final c1 = 1.70158;
		final c3 = c1 + 1.0;
		final u = t - 1.0;
		return 1.0 + c3 * u * u * u + c1 * u * u;
	}

	public static function easeInOutBack(t:Float):Float {
		final c1 = 1.70158;
		final c2 = c1 * 1.525;
		return if (t < 0.5)
			(Math.pow(2.0 * t, 2.0) * ((c2 + 1.0) * 2.0 * t - c2)) / 2.0
		else
			(Math.pow(2.0 * t - 2.0, 2.0) * ((c2 + 1.0) * (t * 2.0 - 2.0) + c2) + 2.0) / 2.0;
	}

	public static function easeOutBounce(t:Float):Float {
		final n1 = 7.5625;
		final d1 = 2.75;
		if (t < 1.0 / d1) {
			return n1 * t * t;
		} else if (t < 2.0 / d1) {
			final t2 = t - 1.5 / d1;
			return n1 * t2 * t2 + 0.75;
		} else if (t < 2.5 / d1) {
			final t2 = t - 2.25 / d1;
			return n1 * t2 * t2 + 0.9375;
		} else {
			final t2 = t - 2.625 / d1;
			return n1 * t2 * t2 + 0.984375;
		}
	}

	public static function easeOutElastic(t:Float):Float {
		if (t == 0.0 || t == 1.0) return t;
		final c4 = (2.0 * Math.PI) / 3.0;
		return Math.pow(2.0, -10.0 * t) * Math.sin((t * 10.0 - 0.75) * c4) + 1.0;
	}

	/** Custom cubic bezier easing (CSS-style). Uses Newton-Raphson to solve for t given x. */
	public static function cubicBezierEasing(x1:Float, y1:Float, x2:Float, y2:Float, t:Float):Float {
		if (t <= 0.0) return 0.0;
		if (t >= 1.0) return 1.0;

		// Find the bezier parameter that gives us the desired x value
		// The bezier x(s) = 3*x1*s*(1-s)^2 + 3*x2*s^2*(1-s) + s^3
		// Newton-Raphson iteration to find s where x(s) = t
		var s = t; // initial guess
		for (_ in 0...8) {
			final s2 = s * s;
			final s3 = s2 * s;
			final oneMinusS = 1.0 - s;
			final oneMinusS2 = oneMinusS * oneMinusS;

			final x = 3.0 * x1 * s * oneMinusS2 + 3.0 * x2 * s2 * oneMinusS + s3;
			final dx = 3.0 * x1 * oneMinusS2 + 6.0 * (x2 - x1) * s * oneMinusS + 3.0 * (1.0 - x2) * s2;

			if (Math.abs(dx) < 1e-10) break;
			s = s - (x - t) / dx;
			s = clamp(s, 0.0, 1.0);
		}

		// Evaluate y at the found parameter
		final s2 = s * s;
		final s3 = s2 * s;
		final oneMinusS = 1.0 - s;
		final oneMinusS2 = oneMinusS * oneMinusS;
		return 3.0 * y1 * s * oneMinusS2 + 3.0 * y2 * s2 * oneMinusS + s3;
	}

	/** Apply a named easing function to a 0-1 value */
	public static function applyEasing(easing:bh.multianim.MultiAnimParser.EasingType, t:Float):Float {
		return switch easing {
			case Linear: t;
			case EaseInQuad: easeInQuad(t);
			case EaseOutQuad: easeOutQuad(t);
			case EaseInOutQuad: easeInOutQuad(t);
			case EaseInCubic: easeInCubic(t);
			case EaseOutCubic: easeOutCubic(t);
			case EaseInOutCubic: easeInOutCubic(t);
			case EaseInBack: easeInBack(t);
			case EaseOutBack: easeOutBack(t);
			case EaseInOutBack: easeInOutBack(t);
			case EaseOutBounce: easeOutBounce(t);
			case EaseOutElastic: easeOutElastic(t);
			case CubicBezier(x1, y1, x2, y2): cubicBezierEasing(x1, y1, x2, y2, t);
		};
	}
}
