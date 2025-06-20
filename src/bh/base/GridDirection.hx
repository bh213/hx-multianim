package bh.base;
import bh.base.Hex;
import hxd.Math;


abstract Degree(Float) {

	public static inline function fromValue(value:Float) {
		return new Degree(value);
	}
    
    public inline function new (value:Float) {
        this = value;
    }
	
	@:to inline public function toRadians():Radian {
		return new Radian(this / 180 * Math.PI);
	  }

    @:from static inline function fromRadian(radians:Radian):Degree {
        return new Degree(radians.radiansValue() * 180.0 / Math.PI);
    }
    public inline function degreesValue ():Float return this;
}

abstract Radian(Float) {

	
	public static function fromDegreeValue(value:Float) {
		return new Radian(value / 180.0 * Math.PI);
	}

	public static function fromValue(value:Float) {
		return new Radian(value);
	}
    public inline function new (value:Float) {
        this = value;
    }

	@:to inline public  function toDegrees():Degree {
		return new Degree(this * 180 / Math.PI);
	  }

    @:from static inline function fromDegree (d:Degree):Radian {
        return new Radian(d.degreesValue() / 180.0 * Math.PI);
    }

    public inline function radiansValue ():Float return this;
}


enum abstract RelativeDirection(Int) {
	var FRONT = 0;
	var RIGHT = 1;
	var BACK = 2;
	var LEFT = 3;
	
}

abstract GridDirectionSet(Int) from Int to Int{
	
	public inline function new(val:Int) {
		this = val;
	}

	public static function createEmpty() {
		return new GridDirectionSet(0);
	}

	public inline function setDirection(direction:GridDirection) {
		this |= 1 << direction.toInt();
		
	}

	public inline function clearDirection(direction:GridDirection) {
		this &= ~(1 << direction.toInt());  
	}

	public inline function hasDirection(direction:GridDirection):Bool {
		return this &(1 << direction.toInt()) != 0;
	}

	public inline function getDirections():Array<GridDirection> {
		var retVal = [];
		for (direction in GridDirection.allDirections()) {
			if (hasDirection(direction)) retVal.push(direction);
		}
		return retVal;
	}

}

@:allow(bh.base.Hex)
enum abstract GridDirection(Int) {

  	var DIRECTION_RIGHT = 0;
  	var DIRECTION_TOP_RIGHT = 1;
	var DIRECTION_TOP_LEFT = 2;
	var DIRECTION_LEFT = 3;
	var DIRECTION_DOWN_LEFT = 4;
	var DIRECTION_DOWN_RIGHT = 5;
	public static final totalDirections = 6;

	

    static final directions:Array<Hex> = [new Hex(1, 0, -1), new Hex(1, -1, 0), new Hex(0, -1, 1), new Hex(-1, 0, 1), new Hex(-1, 1, 0), new Hex(0, 1, -1)];
	static final  allEnumDirections = [DIRECTION_RIGHT, DIRECTION_TOP_RIGHT, DIRECTION_TOP_LEFT, DIRECTION_LEFT, DIRECTION_DOWN_LEFT, DIRECTION_DOWN_RIGHT];
    
	private inline function new(direction) {
		this = direction;
	}
	public function hexDirection(direction:GridDirection):Hex
    {
        return directions[direction.toInt()];
    }

	public inline function toHex():Hex
    {
        return directions[this];
	}
	
	public function getString() {
		return switch cast(this, GridDirection) {
			case DIRECTION_RIGHT:  "right";
			case DIRECTION_TOP_RIGHT: "top-right";
		  	case DIRECTION_TOP_LEFT:  "top-left";
		  	case DIRECTION_LEFT: "left";
		  	case DIRECTION_DOWN_LEFT: "down-left";
			case DIRECTION_DOWN_RIGHT: "down-right";
			default: '???(${this})';
			  
		}
	}

  	
  	public function toInt():Int {
    	return this;
  	}

	public static function allDirections() {
		return allEnumDirections;
	};



	public inline function turn(turn){
		if (turn < 0) return turnLeft(-turn);
		else return turnRight(turn);
	}

	public static function getRelativeDirection(attackDirection:GridDirection, objectDirection:GridDirection):RelativeDirection {
		var relativeDirection = Math.iabs(attackDirection.toInt() - objectDirection.toInt());		
		switch relativeDirection {
			case 0 : return BACK;
			case 3 : return FRONT;
			case 1|2 : return RIGHT;
			case 4|5 : return LEFT;
			case _: throw 'invalid relative direction ${relativeDirection}';
		}

	}


	public function turnLeft(?turn = 1):GridDirection{
		return new GridDirection ((((this % totalDirections) - (turn % totalDirections) + totalDirections)) % totalDirections);
		
	}

	public function turnRight(?turn = 1):GridDirection{
		return new GridDirection((this + turn)  % totalDirections);
	}

	public static function calculateDirection(from:Hex, to:Hex):GridDirection {
		
		if (from.equals(to)) throw 'from == to';
		var firstHex = FractionalHex.hexSingleStep(from, to);
		var direction = Hex.subtract(firstHex, from);
		for (i in 0...directions.length) {
			if (directions[i].equals(direction)) return allEnumDirections[i];
		}
		throw 'direction not found ${direction.toString()}';
	}

	public function calculateStepsFromTiles(from:Hex, to:Hex):Int{

		var finalDirection = calculateDirection(from, to);
		return calculateSteps(finalDirection);
	}

	public inline function calculateSteps(to:GridDirection):Int{
		
		var left = (totalDirections + this - to.toInt()) % totalDirections;
		var right =  totalDirections - left;
		return right < left ? right : -left;
	}

	public function opposite():GridDirection{
		return new GridDirection((this + 3) % totalDirections);
	}


	

}
