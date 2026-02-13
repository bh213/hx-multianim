package bh.paths;

import bh.paths.Curve.ICurve;

/** A stateless ICurve implementation backed by a function.
 *  Used by macro-generated code to inline all curve math. */
class InlineCurve implements ICurve {
	var _fn:Float->Float;

	public function new(fn:Float->Float) {
		this._fn = fn;
	}

	public function getValue(t:Float):Float {
		return _fn(t);
	}
}
