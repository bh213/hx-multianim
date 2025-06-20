package bh.base;

@:structInit
@:forward(x, y)
abstract FPoint(h2d.col.Point) from h2d.col.Point to h2d.col.Point{
	
	inline public static function zero() {
		return new FPoint(0, 0);
	}

	inline public function clone() {
		return new FPoint(this.x, this.y);
	}

	public inline function new(x, y) {
		this.x = x;
		this.y = y;
		
	}
	  

	@:from
	public static inline function fromh2dPoint(p:h2d.col.Point) {
		return new FPoint(p.x, p.y);
	}

	@:to
	public function toPoint():h2d.col.Point {
		return new h2d.col.Point(Math.round(this.x), Math.round(this.y));
	}
	public function toString() {
		return '${this.x}, ${this.y}';
	}
}
