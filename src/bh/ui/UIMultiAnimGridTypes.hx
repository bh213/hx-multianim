package bh.ui;

import bh.base.Hex.HexOrientation;
import bh.ui.UIMultiAnimDraggable;

/** Identifies a cell in the grid. For rect grids, col/row map directly.
 *  For hex grids, col/row are axial coordinates (q/r), s = -q - r derived internally. */
@:structInit
class CellCoord {
	public var col:Int;
	public var row:Int;

	public inline function toString():String {
		return '${col}_${row}';
	}

	public inline function equals(other:CellCoord):Bool {
		return col == other.col && row == other.row;
	}
}

/** Grid geometry type. */
enum GridType {
	/** Rectangular grid with fixed cell size and optional gap between cells. */
	Rect(cellWidth:Float, cellHeight:Float, ?gap:Float);

	/** Hexagonal grid with orientation and hex cell size. */
	Hex(orientation:HexOrientation, sizeX:Float, sizeY:Float);
}

/** Events emitted by UIMultiAnimGrid via the onGridEvent callback. */
enum GridEvent {
	/** Cell was clicked. */
	CellClick(cell:CellCoord, button:Int);

	/** Mouse entered a cell. */
	CellHoverEnter(cell:CellCoord);

	/** Mouse left a cell. */
	CellHoverLeave(cell:CellCoord);

	/** A draggable was dropped onto a cell. sourceGrid/sourceCell are set when the drop originated from makeDraggableFromCell. */
	CellDrop(cell:CellCoord, draggable:UIMultiAnimDraggable, sourceGrid:Null<UIMultiAnimGrid>, sourceCell:Null<CellCoord>);

	/** A card was played on a cell (from UICardHandHelper targeting). */
	CellCardPlayed(cell:CellCoord, cardId:String);

	/** Cell data changed via set() or clear(). */
	CellDataChanged(cell:CellCoord, oldData:Dynamic, newData:Dynamic);
}

/** Delegate to customize per-cell programmable and parameters.
 *  Return null to use grid defaults. */
typedef CellBuildDelegate = (col:Int, row:Int, data:Dynamic) -> Null<CellBuildInfo>;

/** Override info returned by CellBuildDelegate. */
@:structInit
@:nullSafety
typedef CellBuildInfo = {
	/** Override the programmable name for this cell (null = use grid default). */
	var ?buildName:String;

	/** Extra or override parameters for this cell. */
	var ?params:Map<String, Dynamic>;
}

/** Delegate to determine whether a cell accepts a draggable drop. */
typedef GridDropAccepts = (cell:CellCoord, draggable:UIMultiAnimDraggable) -> Bool;

/** Delegate to determine whether a cell accepts a card play. */
typedef GridCardAccepts = (cell:CellCoord, cardId:String) -> Bool;

/** Configuration for UIMultiAnimGrid construction. */
@:structInit
@:nullSafety
typedef GridConfig = {
	/** Grid geometry (Rect or Hex). */
	var gridType:GridType;

	/** Default programmable name used to build each cell. */
	var cellBuildName:String;

	/** Optional delegate to override programmable name or params per cell. */
	var ?cellBuildDelegate:CellBuildDelegate;

	/** X origin offset where cell (0,0) renders in scene coordinates. */
	var ?originX:Float;

	/** Y origin offset where cell (0,0) renders in scene coordinates. */
	var ?originY:Float;

	/** .manim animated path name for snap animation on successful drop (null = instant). */
	var ?snapPathName:String;

	/** .manim animated path name for return animation on failed drop (null = instant). */
	var ?returnPathName:String;

	/** Cell parameter name used for drag-drop highlight state (default: "highlight"). */
	var ?highlightParam:String;

	/** Cell parameter name used for rejected drop highlight (default: null = no reject visual).
	 *  When set, cells where `accepts` returns false get this param set to `true` during drag,
	 *  enabling "wrong item type" red highlight distinct from "not a target." */
	var ?rejectHighlightParam:String;

	/** Cell parameter name used for hover/click status (default: "status"). */
	var ?statusParam:String;

	/** Optional TweenManager for cell lifecycle animations (entrance, exit, effects).
	 *  If null, all cell additions/removals are instant. */
	var ?tweenManager:Dynamic;
}
