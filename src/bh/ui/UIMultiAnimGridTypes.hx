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

	/** A draggable was dropped onto a cell. sourceGrid/sourceCell are set when the drop originated from makeDraggableFromCell.
	 *  Call ctx.accept()/ctx.reject() to control post-drop animation. Default is accept (snap). */
	CellDrop(cell:CellCoord, draggable:UIMultiAnimDraggable, sourceGrid:Null<UIMultiAnimGrid>, sourceCell:Null<CellCoord>,
		ctx:DropContext);

	/** A draggable was dropped onto an occupied cell with swapEnabled=true.
	 *  The dropped item snaps to the target cell; the displaced item animates to the source cell.
	 *  Call ctx.accept()/ctx.reject() to control swap. Default is accept.
	 *  Also emitted by programmatic swapCells() — check ctx.programmatic to distinguish. */
	CellSwap(source:CellCoord, target:CellCoord, draggable:Null<UIMultiAnimDraggable>, ctx:SwapContext);

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

/** Delegate to provide a custom visual for the displaced item during swap animation.
 *  Receives the cell coordinate and its data. Returns an h2d.Object to animate,
 *  or null to fall back to the detached cell visual (default behavior). */
typedef SwapVisualProvider = (cell:CellCoord, data:Dynamic) -> Null<h2d.Object>;

/** Delegate to determine whether a cell accepts a draggable drop. */
typedef GridDropAccepts = (cell:CellCoord, draggable:UIMultiAnimDraggable) -> Bool;

/** Delegate to determine whether a cell accepts a card play. */
typedef GridCardAccepts = (cell:CellCoord, cardId:String) -> Bool;

/** Delegate to determine the highlight value for a cell during drag/card targeting.
 *  Return a string matching the cell programmable's highlight enum values (e.g. "valid", "reject", "expensive").
 *  Return "none" (or the configured default) to leave the cell unhighlighted.
 *  When null, the grid uses default behavior: accepts → "accept", !accepts → "reject". */
typedef GridHighlightDelegate = (cell:CellCoord, accepts:Bool) -> String;

/** Configuration for a named grid layer. */
@:structInit
@:nullSafety
typedef GridLayerConfig = {
	/** Programmable name used to build layer instances. */
	var buildName:String;

	/** Z-order for this layer in the grid's h2d.Layers. Higher = rendered on top.
	 *  Base cells render at z-order 0. */
	var zOrder:Int;
}

/** Context object passed to onGridEvent for CellDrop events.
 *  Allows the game to control post-drop animation (accept/reject). */
@:allow(bh.ui.UIMultiAnimGrid)
@:allow(bh.test.examples.UIMultiAnimGridTest)
class DropContext {
	var handled:Bool = false;
	var accepted:Bool = true;
	var pathName:Null<String> = null;
	var completeCb:Null<Void -> Void> = null;

	public function new() {}

	/** Accept the drop — plays the snap animation (default behavior). */
	public function accept():Void {
		handled = true;
		accepted = true;
	}

	/** Accept with a custom success animation path. */
	public function acceptWithPath(path:String):Void {
		handled = true;
		accepted = true;
		pathName = path;
	}

	/** Reject the drop — plays the return animation (draggable returns to origin). */
	public function reject():Void {
		handled = true;
		accepted = false;
	}

	/** Reject with a custom failure animation path. */
	public function rejectWithPath(path:String):Void {
		handled = true;
		accepted = false;
		pathName = path;
	}

	/** Register a callback that fires after the snap/return animation completes.
	 *  For accept: fires on DragSnapComplete. For reject: fires on DragCancel. */
	public function onComplete(cb:Void -> Void):Void {
		completeCb = cb;
	}
}

/** Context object passed to onGridEvent for CellSwap events.
 *  Allows the game to accept/reject the swap and control animation. */
@:allow(bh.ui.UIMultiAnimGrid)
@:allow(bh.test.examples.UIMultiAnimGridTest)
class SwapContext {
	var handled:Bool = false;
	var accepted:Bool = true;
	var swapPath:Null<String> = null;
	var snapPath:Null<String> = null;
	var completeCb:Null<Void -> Void> = null;
	var snapCompleteCb:Null<Void -> Void> = null;

	/** True when this swap was triggered by programmatic swapCells(), false for drag-drop. */
	public final programmatic:Bool;

	public function new(programmatic:Bool = false) {
		this.programmatic = programmatic;
	}

	/** Accept the swap — dropped item snaps to target, displaced item animates to source (default). */
	public function accept():Void {
		handled = true;
		accepted = true;
	}

	/** Accept with a custom animation path for the displaced item. */
	public function acceptWithSwapPath(swapPathName:String):Void {
		handled = true;
		accepted = true;
		swapPath = swapPathName;
	}

	/** Accept with custom paths for both the dropped item (snap) and displaced item (swap). */
	public function acceptWithPaths(snapPathName:String, swapPathName:String):Void {
		handled = true;
		accepted = true;
		snapPath = snapPathName;
		swapPath = swapPathName;
	}

	/** Reject the swap — draggable returns to origin, nothing changes. */
	public function reject():Void {
		handled = true;
		accepted = false;
	}

	/** Register a callback that fires after the snap animation completes (draggable lands on target).
	 *  The displaced item may still be animating. Useful for rebuilding game overlays (e.g. draggable items)
	 *  that need to appear at the new positions before the displaced animation finishes. */
	public function onSnapComplete(cb:Void -> Void):Void {
		snapCompleteCb = cb;
	}

	/** Register a callback that fires after both animations complete. */
	public function onComplete(cb:Void -> Void):Void {
		completeCb = cb;
	}
}

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

	/** .manim animated path name for displaced item animation during swap (null = falls back to returnPathName, then instant). */
	var ?swapPathName:String;

	/** Enable swap semantics: dropping onto an occupied cell emits CellSwap instead of CellDrop.
	 *  When false (default), occupied cells are handled by CellDrop as usual. */
	var ?swapEnabled:Bool;

	/** Parent container for swap animation visuals. During swap, the displaced item is reparented
	 *  here so it renders above grid content. Typically an h2d.Layers added at a screen layer above
	 *  the grid (e.g. ModalLayer or a NamedLayer). If null, falls back to the grid's own root at
	 *  a high z-order (works for simple cases but may render behind overlays/dialogs). */
	var ?swapAnimContainer:h2d.Object;

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

	/** Cell parameter name used for reject-drop highlight (default: null = no reject visual).
	 *  When set, cells where `accepts` returns false show this param during drag. */
	var ?rejectHighlightParam:String;

	/** Optional delegate to provide a custom visual for the displaced item during swap animation.
	 *  When set, the delegate builds the visual to animate instead of using the raw detached cell.
	 *  This is useful when cell programmables include backgrounds that shouldn't animate.
	 *  Return null from the delegate to fall back to the detached cell visual for that cell. */
	var ?swapVisualProvider:SwapVisualProvider;
}
