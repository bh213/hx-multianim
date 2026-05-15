package bh.base;

@:structInit
class FPoint {
	public var x:Float;
	public var y:Float;

	// Allocation watchdog for tests. Gated behind MULTIANIM_ALLOC_TRACK so the
	// per-construction increment vanishes from production builds; FPoint is on
	// every particle/path/hex/layout hot path.
	#if MULTIANIM_ALLOC_TRACK
	public static var creationCount:Int = 0;
	#end

	inline public static function zero() {
		return new FPoint(0, 0);
	}

	inline public function clone() {
		return new FPoint(x, y);
	}

	public inline function new(x, y) {
		this.x = x;
		this.y = y;
		#if MULTIANIM_ALLOC_TRACK
		creationCount++;
		#end
	}


	public function toPoint() {
		return new Point(Math.round(x), Math.round(y));
	}
	public function toString() {
		return '$x, $y';
	}
}
