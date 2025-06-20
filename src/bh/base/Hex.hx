package bh.base;
import bh.base.GridDirection;
import h2d.col.Point;


enum HexKey {
	HEX(q:Int, r:Int, s:Int);
}

class HexLineIterator {

    private var a_nudge:FractionalHex;
    private var b_nudge:FractionalHex;
    private var step:Float;
    public var distance(default, null):Int;


    public function new(a:Hex, b:Hex) {
        this.distance = Hex.distance(a, b);
        this.a_nudge = new FractionalHex(a.q + 0.000001, a.r + 0.000001, a.s - 0.000002);
        this.b_nudge = new FractionalHex(b.q + 0.000001, b.r + 0.000001, b.s - 0.000002);
        this.step = 1.0 / Math.max(this.distance, 1);    
    }
    
      public function get(i:Int) {
        return FractionalHex.hexLerp(a_nudge, b_nudge, step * i).round();
      }
}

abstract RelativeHex(Hex) {
	inline public function new(hex:Hex) {
		this = hex;
	}

	static public function fromHex(hex:Hex, origin:Hex):RelativeHex {
    	return new RelativeHex(Hex.subtract(hex, origin));
    }
      
    public inline static function fromKey(key:HexKey):RelativeHex {
        switch key {
            case HEX(q, r, s): return new RelativeHex(new Hex(q,r,s));
        }
    }


    static public function zero():RelativeHex {
    	return new RelativeHex(Hex.zero());
  	}


	static public function fromRelativeHex(hex:Hex):RelativeHex {
    	return new RelativeHex(hex);
  	}

	static public function fromRelativeCube(q, r, s):RelativeHex {
    	return new RelativeHex(new Hex(q, r, s));
  	}

	public function equals(b:RelativeHex) {
		return this.equals(cast b);
    }

    public function toKey():HexKey {
        return HEX(this.q,this.r,this.s);
    }

  
  	public function toHex(origin:Hex):Hex {
    	return Hex.add(origin, this);
  	}

  	public function toRelativeHex():Hex {
    	return this;
    }
      
    public function copy():RelativeHex {
    	return fromRelativeHex(this);
  	}

	public inline function rotateRight() {
		 this = Hex.rotateRight(this);
	}

	public inline function rotateLeft() {
		 this = Hex.rotateLeft(this);
	}

}


class Hex 
{
    inline public function new(q:Int, r:Int, s:Int)
    {
        this.q = q;
        this.r = r;
        this.s = s;
        if (q + r + s != 0) throw "q + r + s must be 0";
    }
    public var q(default, null):Int;
    public var r(default, null):Int;
    public var s(default, null):Int;

    inline public function toKey():HexKey {
        return HEX(q,r,s);
    }

    inline public static function zero() {
        return new Hex(0,0,0);
    }

    inline public static function fromKey(key:HexKey):Hex {
        switch key {
            case HEX(q, r, s): return new Hex(q,r,s);
        }
    }

    public inline function equals(a:Hex) {
        return this.q == a.q && this.r == a.r && this.s == a.s;
    }

    static inline public function add(a:Hex, b:Hex):Hex
    {
        return new Hex(a.q + b.q, a.r + b.r, a.s + b.s);
    }

    static inline public function subtract(a:Hex, b:Hex):Hex
    {
        return new Hex(a.q - b.q, a.r - b.r, a.s - b.s);
    }


    static inline public function scale(a:Hex, k:Int):Hex
    {
        return new Hex(a.q * k, a.r * k, a.s * k);
    }


    static inline public function rotateLeft(a:Hex):Hex
    {
        return new Hex(-a.s, -a.q, -a.r);
    }


    static inline public function rotateRight(a:Hex):Hex
    {
        return new Hex(-a.r, -a.s, -a.q);
    }

    
    static public function isNeighbor(a:Hex, b:Hex):Bool
    {
        var result = subtract(a, b);
        for (hex in GridDirection.directions) {
            if (result.equals(hex)) return true;
        }
        return false;
    }

    
    static public function neighbor(hex:Hex, direction:GridDirection):Hex
    {
            return Hex.add(hex, direction.hexDirection(direction));
    }

	public static function cubeRing(radius:Int, direction:GridDirection):Array<RelativeHex> {
		var results = [];

		var cube = Hex.scale(direction.toHex(), radius);
		for (i in GridDirection.allDirections()) {
			for (j in 0...radius) {
				results.push(RelativeHex.fromRelativeHex(cube));
				cube = Hex.add(cube, i.toHex());
			}
		}
		return results;
	}

    public static function createRange(range:Int):Array<RelativeHex> {
        var hexes = [RelativeHex.fromRelativeHex(Hex.zero())];
        for (i in 1...range+1) {
            hexes = hexes.concat(Hex.cubeRing(i, DIRECTION_DOWN_LEFT));
        }
		 
		return hexes;
	}


    static public function length(hex:Hex):Int
    {
        return Std.int((Math.abs(hex.q) + Math.abs(hex.r) + Math.abs(hex.s)) / 2);
    }


    static public function distance(a:Hex, b:Hex):Int
    {
        return Hex.length(Hex.subtract(a, b));
    }

    public function toString() {
        return '$q,$r,$s';
    }

    public function toOffsetCoordinates() {
		return OffsetCoord.qoffsetFromCube(0, this);
	}

}

class FractionalHex
{
    public function new(q:Float, r:Float, s:Float)
    {
        this.q = q;
        this.r = r;
        this.s = s;
        if (Math.round(q + r + s) != 0) throw "q + r + s must be 0";
    }
    public var q:Float;
    public var r:Float;
    public var s:Float;

    public function round():Hex
    {
        var qi:Int = Math.round(this.q);
        var ri:Int = Math.round(this.r);
        var si:Int = Math.round(this.s);
        var q_diff:Float = Math.abs(qi - this.q);
        var r_diff:Float = Math.abs(ri - this.r);
        var s_diff:Float = Math.abs(si - this.s);
        if (q_diff > r_diff && q_diff > s_diff)
        {
            qi = -ri - si;
        }
        else
            if (r_diff > s_diff)
            {
                ri = -qi - si;
            }
            else
            {
                si = -qi - ri;
            }
        return new Hex(qi, ri, si);
    }


    static public function hexLerp(a:FractionalHex, b:FractionalHex, t:Float):FractionalHex
    {
        return new FractionalHex(a.q * (1.0 - t) + b.q * t, a.r * (1.0 - t) + b.r * t, a.s * (1.0 - t) + b.s * t);
    }

    static public function hexSingleStep(a:Hex, b:Hex):Hex
    {
        var N:Int = Hex.distance(a, b);
        var a_nudge:FractionalHex = new FractionalHex(a.q + 0.000001, a.r + 0.000001, a.s - 0.000002);
        var b_nudge:FractionalHex = new FractionalHex(b.q + 0.000001, b.r + 0.000001, b.s - 0.000002);
        var step:Float = 1.0 / Math.max(N, 1);
        return FractionalHex.hexLerp(a_nudge, b_nudge, step * 1 ).round();
    }

    static public function hexLinedraw(a:Hex, b:Hex):Array<Hex>
    {
        var N:Int = Hex.distance(a, b);
        var a_nudge:FractionalHex = new FractionalHex(a.q + 0.000001, a.r + 0.000001, a.s - 0.000002);
        var b_nudge:FractionalHex = new FractionalHex(b.q + 0.000001, b.r + 0.000001, b.s - 0.000002);
        var results:Array<Hex> = [];
        var step:Float = 1.0 / Math.max(N, 1);
        for (i in 0...N + 1)
        {
            results.push(FractionalHex.hexLerp(a_nudge, b_nudge, step * i).round());
        }
        return results;
    }

}

class OffsetCoord
{
    public function new(col:Int, row:Int)
    {
        this.col = col;
        this.row = row;
    }
    public var col:Int;
    public var row:Int;
    static public var EVEN:Int = 1;
    static public var ODD:Int = -1;

    static public function qoffsetFromCube(offset:Int, h:Hex):OffsetCoord
    {
        var col:Int = h.q;
        var row:Int = h.r + Std.int((h.q + offset * (h.q & 1)) / 2);
        return new OffsetCoord(col, row);
    }


    static public function qoffsetToCube(offset:Int, h:OffsetCoord):Hex
    {
        var q:Int = h.col;
        var r:Int = h.row - Std.int((h.col + offset * (h.col & 1)) / 2);
        var s:Int = -q - r;
        return new Hex(q, r, s);
    }


    static public function roffsetFromCube(offset:Int, h:Hex):OffsetCoord
    {
        var col:Int = h.q + Std.int((h.r + offset * (h.r & 1)) / 2);
        var row:Int = h.r;
        return new OffsetCoord(col, row);
    }


    static public function roffsetToCube(offset:Int, h:OffsetCoord):Hex
    {
        var q:Int = h.col - Std.int((h.row + offset * (h.row & 1)) / 2);
        var r:Int = h.row;
        var s:Int = -q - r;
        return new Hex(q, r, s);
    }

    public function toString() {
        return '${col},${row}';
    }

}

class DoubledCoord
{
    public function new(col:Int, row:Int)
    {
        this.col = col;
        this.row = row;
    }
    public var col:Int;
    public var row:Int;

    static public function qdoubledFromCube(h:Hex):DoubledCoord
    {
        var col:Int = h.q;
        var row:Int = 2 * h.r + h.q;
        return new DoubledCoord(col, row);
    }


    static public function qdoubledToCube(h:DoubledCoord):Hex
    {
        var q:Int = h.col;
        var r:Int = Std.int((h.row - h.col) / 2);
        var s:Int = -q - r;
        return new Hex(q, r, s);
    }


    static public function rdoubledFromCube(h:Hex):DoubledCoord
    {
        var col:Int = 2 * h.q + h.r;
        var row:Int = h.r;
        return new DoubledCoord(col, row);
    }


    static public function rdoubledToCube(h:DoubledCoord):Hex
    {
        var q:Int = Std.int((h.col - h.row) / 2);
        var r:Int = h.row;
        var s:Int = -q - r;
        return new Hex(q, r, s);
    }

}

enum HexOrientation {
    POINTY;
    FLAT;
}


class HexOrientationData
{
    public function new(f0:Float, f1:Float, f2:Float, f3:Float, b0:Float, b1:Float, b2:Float, b3:Float, start_angle:Float)
    {
        this.f0 = f0;
        this.f1 = f1;
        this.f2 = f2;
        this.f3 = f3;
        this.b0 = b0;
        this.b1 = b1;
        this.b2 = b2;
        this.b3 = b3;
        this.start_angle = start_angle;
    }
    public var f0:Float;
    public var f1:Float;
    public var f2:Float;
    public var f3:Float;
    public var b0:Float;
    public var b1:Float;
    public var b2:Float;
    public var b3:Float;
    public var start_angle:Float;
}

class HexLayout
{

    var orientationData(default, null):HexOrientationData;
    public var orientation(default, null):HexOrientation;
    public var size(default, null):Point;
    public var origin(default, null):Point;
    static public var pointy:HexOrientationData = new HexOrientationData(Math.sqrt(3.0), Math.sqrt(3.0) / 2.0, 0.0, 3.0 / 2.0, Math.sqrt(3.0) / 3.0, -1.0 / 3.0, 0.0, 2.0 / 3.0, 0.5);
    static public var flat:HexOrientationData = new HexOrientationData(3.0 / 2.0, 0.0, Math.sqrt(3.0) / 2.0, Math.sqrt(3.0), 2.0 / 3.0, 0.0, -1.0 / 3.0, Math.sqrt(3.0) / 3.0, 0.0);

    public function new(orientation:HexOrientation, size:Point, origin:Point)
    {

        this.orientation = orientation;
        switch this.orientation {
            case POINTY: this.orientationData = pointy;
            case FLAT: this.orientationData = flat;

        }
        this.size = size;
        this.origin = origin;
    }

    public function createDrawableHexLayout(size:Point, origin:Point) {
        return new HexLayout(this.orientation, size, origin);
    }


    public function hexToPixel(h:Hex):Point
    {
        var x:Float = (orientationData.f0 * h.q + orientationData.f1 * h.r) * size.x;
        var y:Float = (orientationData.f2 * h.q + orientationData.f3 * h.r) * size.y;
        return new Point(x + origin.x, y + origin.y);
    }


    public function pixelToHex(p:Point):FractionalHex
    {
        var pt:Point = new Point((p.x - origin.x) / size.x, (p.y - origin.y) / size.y);
        var q:Float = orientationData.b0 * pt.x + orientationData.b1 * pt.y;
        var r:Float = orientationData.b2 * pt.x + orientationData.b3 * pt.y;
        return new FractionalHex(q, r, -q - r);
    }


    public static function directionToAngle(gridDirection:GridDirection):Degree
    {
        final deg = 60 * (GridDirection.totalDirections - gridDirection.toInt());
        return new Degree(deg % 360);// + orientationData.start_angle; 
    }

    public function getStartAngleRad():Radian
    {
        return new Radian(orientationData.start_angle);
    }



    public function hexCornerOffset(corner:Int, towardsCenter:Float = 1.0):Point
    {
        var angle:Float = 2.0 * Math.PI * (orientationData.start_angle - corner) / 6.0;
        return new Point(size.x * Math.cos(angle) * towardsCenter, size.y * Math.sin(angle) * towardsCenter);
    }


    public function polygonCorner(h:Hex, corner:Int, ?towardCenter:Float = 1.0):Point {

        var center:Point = hexToPixel(h);
        var offset:Point = hexCornerOffset(corner);
        return new Point(center.x + towardCenter * offset.x, center.y + towardCenter * offset.y);

    }

    public function outline(hexes:Array<Hex>):Array<Point> {
        var outline = [];
        var unprocessed = hexes.copy();

        while(unprocessed.length > 0) {
            final currentHex = unprocessed.pop();
            
            final corners = polygonCorners(currentHex);
            for (direction in GridDirection.allDirections()) {
                final hexInDirection = Hex.add(currentHex, direction.toHex());
                if (Lambda.find(hexes, h->h.equals(hexInDirection)) == null) {
                    outline.push(corners[direction.toInt()]);
                    outline.push(corners[(direction.toInt()+1) % GridDirection.totalDirections]);
                }
            
            }

        }

        return outline;

    }


    public function polygonEdge(h:Hex, corner:Int, ?towardCenter:Float = 1.0):Point {
        var center:Point = hexToPixel(h);
        var o1:Point = hexCornerOffset(corner);
        var o2:Point = hexCornerOffset(corner+1);
        var edge:Point = new Point((o1.x + o2.x)/2, (o1.y + o2.y)/2);
        edge.scale(towardCenter);
        return new Point(center.x + edge.x, center.y + edge.y);

    }

    public function polygonCorners(h:Hex, scale:Float = 1.):Array<Point>
    {
        var corners:Array<Point> = [];
        var center:Point = hexToPixel(h);
        for (i in 0...6)
        {
            var offset:Point = hexCornerOffset(i, scale);
            corners.push(new Point(center.x + offset.x, center.y + offset.y));
        }
        return corners;
    }

    public function toString() {
         return '$orientation, size $size, origin $origin' ;
    }
}
