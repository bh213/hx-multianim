package bh.multianim;

import bh.base.FPoint;
import bh.base.Point;
import bh.multianim.MultiAnimParser;
import bh.base.Hex;



enum Coordinates {
	ZERO;
	OFFSET(x:ReferencableValue, y:ReferencableValue);
    LAYOUT(layoutName:String, index:ReferencableValue);
	SELECTED_HEX_POSITION(hex:Hex);
	SELECTED_GRID_POSITION(gridX:ReferencableValue, gridY:ReferencableValue);
	SELECTED_HEX_EDGE(direction:ReferencableValue, factor:ReferencableValue);
	SELECTED_HEX_CORNER(count:ReferencableValue, factor:ReferencableValue);
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


function resolveAsGrid(system:GridCoordinateSystem, gridX:Int, gridY:Int):FPoint {
    return {x:system.spacingX * gridX, y:system.spacingY * gridY};
}   

class HexCoordinateSystemHelper {
    inline static function returnPosition(x, y):FPoint {
        return {x:x, y:y};
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
}

