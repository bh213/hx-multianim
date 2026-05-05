package bh.base;

@:structInit
class FPoint {
	public var x:Float;
	public var y:Float;

	// Lightweight allocation counter for hot-path instrumentation in tests
	// (mirrors UICardHandLayout.scratchArrayAllocationCount). One int increment
	// per FPoint construction.
	public static var creationCount:Int = 0;

	inline public static function zero() {
		return new FPoint(0, 0);
	}

	inline public function clone() {
		return new FPoint(x, y);
	}

	public inline function new(x, y) {
		this.x = x;
		this.y = y;
		creationCount++;
	}


	public function toPoint() {
		return new Point(Math.round(x), Math.round(y));
	}
	public function toString() {
		return '$x, $y';
	}
}
