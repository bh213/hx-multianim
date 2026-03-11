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

/** What is targeting a cell. */
enum CellTargetSource {
	/** Plain mouse hover (no drag/card active). */
	Mouse;

	/** A draggable is being dragged over this cell. */
	Drag(draggable:UIMultiAnimDraggable);

	/** A card targeting arrow is hovering over this cell. */
	Card(cardId:String);
}

/** Events emitted by UIMultiAnimGrid via the onGridEvent callback. */
enum GridEvent {
	/** Cell was clicked. */
	CellClick(cell:CellCoord, button:Int);

	/** Something started targeting a cell (mouse hover, drag hover, or card targeting). */
	CellTargetEnter(cell:CellCoord, source:CellTargetSource);

	/** Something stopped targeting a cell. */
	CellTargetLeave(cell:CellCoord, source:CellTargetSource);

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

/** Delegate to determine the highlight value for a cell during drag/card targeting.
 *  Return a string matching the cell programmable's highlight enum values (e.g. "valid", "reject", "expensive").
 *  Return "none" (or the configured default) to leave the cell unhighlighted.
 *  When null, the grid uses default behavior: accepts → "accept", !accepts → "reject". */
typedef GridHighlightDelegate = (cell:CellCoord, accepts:Bool) -> String;

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

	/** Cell parameter name used for drag-drop highlight state (default: "highlight").
	 *  This is a string/enum parameter on the cell programmable. Values are set by the
	 *  highlightDelegate, or default to "none"/"accept"/"reject". */
	var ?highlightParam:String;

	/** Optional delegate to determine per-cell highlight value during drag/card targeting.
	 *  When null, uses default: accepts → "accept", !accepts → "reject". */
	var ?highlightDelegate:GridHighlightDelegate;

	/** Cell parameter name used for hover/click status (default: "status"). */
	var ?statusParam:String;

	/** Optional TweenManager for cell lifecycle animations (entrance, exit, effects).
	 *  If null, all cell additions/removals are instant. */
	var ?tweenManager:Dynamic;
}
