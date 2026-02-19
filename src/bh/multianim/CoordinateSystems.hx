package bh.multianim;

import bh.base.FPoint;
import bh.base.Point;
import bh.multianim.MultiAnimParser;
import bh.base.Hex;

enum OffsetParity {
	EVEN;
	ODD;
}

enum CoordinateSystemDef {
	NamedGrid(system:GridCoordinateSystem);
	NamedHex(system:HexCoordinateSystem);
}

enum Coordinates {
	ZERO;
	OFFSET(x:ReferenceableValue, y:ReferenceableValue);
	LAYOUT(layoutName:String, index:ReferenceableValue);
	SELECTED_GRID_POSITION(gridX:ReferenceableValue, gridY:ReferenceableValue);
	SELECTED_GRID_POSITION_WITH_OFFSET(gridX:ReferenceableValue, gridY:ReferenceableValue, offsetX:ReferenceableValue, offsetY:ReferenceableValue);
	SELECTED_HEX_CORNER(count:ReferenceableValue, factor:ReferenceableValue);
	SELECTED_HEX_EDGE(direction:ReferenceableValue, factor:ReferenceableValue);
	SELECTED_HEX_CUBE(q:ReferenceableValue, r:ReferenceableValue, s:ReferenceableValue);
	SELECTED_HEX_OFFSET(col:ReferenceableValue, row:ReferenceableValue, parity:OffsetParity);
	SELECTED_HEX_DOUBLED(col:ReferenceableValue, row:ReferenceableValue);
	SELECTED_HEX_PIXEL(x:ReferenceableValue, y:ReferenceableValue);
	SELECTED_HEX_CELL_CORNER(cell:Coordinates, cornerIndex:ReferenceableValue, factor:ReferenceableValue);
	SELECTED_HEX_CELL_EDGE(cell:Coordinates, direction:ReferenceableValue, factor:ReferenceableValue);
	NAMED_COORD(name:String, coord:Coordinates);
}

@:using(bh.multianim.CoordinateSystems.HexCoordinateSystemHelper)
typedef HexCoordinateSystem = {
	var hexLayout:HexLayout;
}

@:using(bh.multianim.CoordinateSystems)
typedef GridCoordinateSystem = {
	var spacingX:Int;
	var spacingY:Int;
}

function resolveAsGrid(system:GridCoordinateSystem, gridX:Int, gridY:Int, offsetX:Int = 0, offsetY:Int = 0):FPoint {
	return {x: system.spacingX * gridX + offsetX, y: system.spacingY * gridY + offsetY};
}

class HexCoordinateSystemHelper {
	inline static function returnPosition(x, y):FPoint {
		return {x: x, y: y};
	}

	public static function resolveAsHexEdge(system:HexCoordinateSystem, direction:Int, factor:Float) {
		final pos = system.hexLayout.polygonEdge(Hex.zero(), direction, factor);
		return returnPosition(pos.x, pos.y);
	}

	public static function resolveAsHexPosition(system:HexCoordinateSystem, hex:Hex) {
		final pos = system.hexLayout.hexToPixel(hex);
		return returnPosition(pos.x, pos.y);
	}

	public static function resolveAsHexCorner(system:HexCoordinateSystem, count, factor) {
		final pos = system.hexLayout.polygonCorner(Hex.zero(), count, factor);
		return returnPosition(pos.x, pos.y);
	}

	public static function resolveAsHexCellCorner(system:HexCoordinateSystem, hex:Hex, count:Int, factor:Float) {
		final pos = system.hexLayout.polygonCorner(hex, count, factor);
		return returnPosition(pos.x, pos.y);
	}

	public static function resolveAsHexCellEdge(system:HexCoordinateSystem, hex:Hex, direction:Int, factor:Float) {
		final pos = system.hexLayout.polygonEdge(hex, direction, factor);
		return returnPosition(pos.x, pos.y);
	}

	public static function resolveHexCube(system:HexCoordinateSystem, q:Float, r:Float, s:Float):FPoint {
		final hex = if (q == Math.ffloor(q) && r == Math.ffloor(r) && s == Math.ffloor(s)) {
			new Hex(Std.int(q), Std.int(r), Std.int(s));
		} else {
			new FractionalHex(q, r, s).round();
		}
		final pos = system.hexLayout.hexToPixel(hex);
		return returnPosition(pos.x, pos.y);
	}

	public static function resolveHexOffset(system:HexCoordinateSystem, col:Int, row:Int, parity:OffsetParity):FPoint {
		final parityVal = switch (parity) {
			case EVEN: OffsetCoord.EVEN;
			case ODD: OffsetCoord.ODD;
		};
		final hex = switch (system.hexLayout.orientation) {
			case POINTY: OffsetCoord.qoffsetToCube(parityVal, new OffsetCoord(col, row));
			case FLAT: OffsetCoord.roffsetToCube(parityVal, new OffsetCoord(col, row));
		};
		final pos = system.hexLayout.hexToPixel(hex);
		return returnPosition(pos.x, pos.y);
	}

	public static function resolveHexDoubled(system:HexCoordinateSystem, col:Int, row:Int):FPoint {
		final hex = switch (system.hexLayout.orientation) {
			case POINTY: DoubledCoord.qdoubledToCube(new DoubledCoord(col, row));
			case FLAT: DoubledCoord.rdoubledToCube(new DoubledCoord(col, row));
		};
		final pos = system.hexLayout.hexToPixel(hex);
		return returnPosition(pos.x, pos.y);
	}

	public static function resolveHexPixel(system:HexCoordinateSystem, x:Float, y:Float):FPoint {
		#if !macro
		final hex = system.hexLayout.pixelToHex(new h2d.col.Point(x, y)).round();
		final pos = system.hexLayout.hexToPixel(hex);
		return returnPosition(pos.x, pos.y);
		#else
		return returnPosition(0, 0);
		#end
	}

	public static function resolveHexToHex(system:HexCoordinateSystem, q:Float, r:Float, s:Float):Hex {
		if (q == Math.ffloor(q) && r == Math.ffloor(r) && s == Math.ffloor(s)) {
			return new Hex(Std.int(q), Std.int(r), Std.int(s));
		}
		return new FractionalHex(q, r, s).round();
	}
}

