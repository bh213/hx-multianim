package bh.multianim;

import bh.base.FPoint;
import bh.base.Point;
import bh.multianim.MultiAnimParser;
import bh.base.Hex;



enum Coordinates {
	ZERO;
	OFFSET(x:ReferenceableValue, y:ReferenceableValue);
    LAYOUT(layoutName:String, index:ReferenceableValue);
	SELECTED_HEX_POSITION(hex:Hex);
	SELECTED_GRID_POSITION(gridX:ReferenceableValue, gridY:ReferenceableValue);
	SELECTED_GRID_POSITION_WITH_OFFSET(gridX:ReferenceableValue, gridY:ReferenceableValue, offsetX:ReferenceableValue, offsetY:ReferenceableValue);
	SELECTED_HEX_EDGE(direction:ReferenceableValue, factor:ReferenceableValue);
	SELECTED_HEX_CORNER(count:ReferenceableValue, factor:ReferenceableValue);
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
    return {x:system.spacingX * gridX + offsetX, y:system.spacingY * gridY + offsetY};
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

