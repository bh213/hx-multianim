package bh.base;

@:structInit
class Point {
	public var x:Int;
	public var y:Int;

	public function new(x, y) {
		this.x = x;
		this.y = y;
	}

	public function add(x, y) {
		this.x+=x;
		this.y+=y;
		return this;
	}

	#if !macro
	public inline function toh2dPoint() {
		return new h2d.col.IPoint(x, y);
	}
	#end
	
	public function clone() {
		return new Point(x, y);
	}

	public function toString() {
		return '$x, $y';
	}
}
