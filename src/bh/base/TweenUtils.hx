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
}
