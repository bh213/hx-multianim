package bh.base;

@:structInit
class FPoint {
	public var x:Float;
	public var y:Float;
	
	inline public static function zero() {
		return new FPoint(0, 0);
	}

	inline public function clone() {
		return new FPoint(x, y);
	}

	public inline function new(x, y) {
		this.x = x;
		this.y = y;
		
	}

	#if !macro
	public static inline function fromh2dPoint(p:h2d.col.Point) {
		return new FPoint(p.x, p.y);
	}

	public inline function toh2dPoint() {
		return new h2d.col.Point(x, y);
	}
	#end

	public function toPoint() {
		return new Point(Math.round(x), Math.round(y));
	}
	public function toString() {
		return '$x, $y';
	}
}
