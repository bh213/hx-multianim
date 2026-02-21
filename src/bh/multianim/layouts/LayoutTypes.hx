package bh.multianim.layouts;

import bh.base.Point;
import bh.multianim.CoordinateSystems.Coordinates;
import bh.multianim.CoordinateSystems.GridCoordinateSystem;
import bh.multianim.CoordinateSystems.HexCoordinateSystem;

enum LayoutContent {
	LayoutPoint(pos:Coordinates);
}

enum LayoutsType {
	Single(content:LayoutContent);
	List(list:Array<LayoutContent>);
    Sequence(varName:String, from:Int, to:Int, content:LayoutContent);
    Grid(cols:Int, rows:Int, cellW:Int, cellH:Int);
}

enum LayoutAlignX {
	Left;
	Center;
	Right;
}

enum LayoutAlignY {
	Top;
	Center;
	Bottom;
}

@:nullSafety
typedef Layout = {
	name:String,
	type:LayoutsType,
    grid:Null<GridCoordinateSystem>,
	hex:Null<HexCoordinateSystem>,
	offset:Point,
	alignX:LayoutAlignX,
	alignY:LayoutAlignY
};
