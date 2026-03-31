package bh.ui;

import bh.base.Hex.HexOrientation;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.BuilderResult;
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

/** Cell origin point for Rect grids. Controls where the cell visual is anchored
 *  relative to the hit area. Hex grids always use centered origin. */
enum RectOrigin {
	/** Cell visual origin is at the top-left of the hit area (default). */
	TopLeft;

	/** Cell visual origin is at the center of the hit area.
	 *  Use when cell visuals are centered (e.g. hex sprites in a rect layout). */
	Centered;
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
enum GridEvent<T> {
	/** Cell was clicked. */
	CellClick(cell:CellCoord, button:Int);

	/** Something started targeting a cell (mouse hover, drag hover, or card targeting). */
	CellTargetEnter(cell:CellCoord, source:CellTargetSource);

	/** Something stopped targeting a cell. */
	CellTargetLeave(cell:CellCoord, source:CellTargetSource);

	/** A draggable was dropped onto a cell. sourceGrid/sourceCell are set when the drop originated from makeDraggableFromCell.
	 *  Call ctx.accept()/ctx.reject() to control post-drop animation. Default is accept (snap). */
	CellDrop(cell:CellCoord, draggable:UIMultiAnimDraggable, sourceGrid:Null<UIMultiAnimGrid<T>>, sourceCell:Null<CellCoord>,
		ctx:DropContext);

	/** A draggable was dropped onto an occupied cell with swapEnabled=true.
	 *  The dropped item snaps to the target cell; the displaced item animates to the source cell.
	 *  Call ctx.accept()/ctx.reject() to control swap. Default is accept.
	 *  Also emitted by programmatic swapCells() — check ctx.programmatic to distinguish. */
	CellSwap(source:CellCoord, target:CellCoord, draggable:Null<UIMultiAnimDraggable>, ctx:SwapContext);

	/** A card was played on a cell (from UICardHandHelper targeting). */
	CellCardPlayed(cell:CellCoord, cardId:String);

	/** A cell drag started (cellDragEnabled). The draggable is managed internally. */
	CellDragStart(cell:CellCoord, draggable:UIMultiAnimDraggable);

	/** A cell drag ended (drop, cancel, or swap complete). */
	CellDragEnd(cell:CellCoord);

	/** Cell data changed via set() or clear(). */
	CellDataChanged(cell:CellCoord, oldData:Null<T>, newData:Null<T>);
}

/** Delegate to customize per-cell programmable and parameters.
 *  Return null to use grid defaults. */
typedef CellBuildDelegate<T> = (col:Int, row:Int, data:T) -> Null<CellBuildInfo>;

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
typedef SwapVisualProvider<T> = (cell:CellCoord, data:T) -> Null<h2d.Object>;

/** Delegate to determine whether a cell can be dragged (for cellDragEnabled).
 *  Receives the cell coordinate and its data. Return true to allow dragging. */
typedef CellDragFilter<T> = (col:Int, row:Int, data:T) -> Bool;

/** Delegate to determine whether a cell accepts a draggable drop. */
typedef GridDropAccepts = (cell:CellCoord, draggable:UIMultiAnimDraggable) -> Bool;

/** Delegate to determine whether a cell accepts a card play. */
typedef GridCardAccepts = (cell:CellCoord, cardId:String) -> Bool;

/** Delegate to determine whether a swap should occur when dropping on a cell.
 *  Only called when swapEnabled=true AND the draggable has a source cell.
 *  Return true to emit CellSwap, false to fall through to CellDrop.
 *  When null, defaults to isOccupied() check. */
typedef GridSwapAccepts = (cell:CellCoord, draggable:UIMultiAnimDraggable) -> Bool;

/** Delegate to determine the highlight value for a cell during drag/card targeting.
 *  Return a string matching the cell programmable's highlight enum values (e.g. "valid", "reject", "expensive").
 *  Return "none" (or the configured default) to leave the cell unhighlighted.
 *  When null, the grid uses default behavior: accepts → "accept", !accepts → "reject". */
typedef GridHighlightDelegate = (cell:CellCoord, accepts:Bool) -> String;

// ============================================================
// Cell visual abstraction
// ============================================================

/** Wraps the visual representation of a grid cell.
 *  The grid manages highlight/status state through typed methods.
 *  Game-specific parameters (slots, dynamic refs) are accessible via getResult(). */
interface CellVisual<T> {
	/** The scene graph object for this cell. */
	var object(get, never):h2d.Object;

	/** Set the highlight state (e.g. "none", "accept", "reject"). */
	function setHighlight(value:String):Void;

	/** Set the hover/interaction status (e.g. "normal", "hover"). */
	function setStatus(value:String):Void;

	/** Begin a batched update. Multiple setHighlight/setStatus calls between
	 *  begin/end are applied as a single evaluation. Optional data parameter
	 *  notifies the visual of a data change (set or clear). */
	function beginUpdate(?data:T):Void;

	/** End a batched update, flushing all changes. */
	function endUpdate():Void;

	/** Get the underlying BuilderResult for game-specific params (slots, dynamic refs, etc.).
	 *  Returns null for non-manim implementations. */
	function getResult():Null<BuilderResult>;
}

/** Default CellVisual backed by a BuilderResult from MultiAnimBuilder.
 *  Maps setHighlight/setStatus to setParameter calls using the configured param names. */
class DefaultCellVisual<T> implements CellVisual<T> {
	final result:BuilderResult;
	final highlightParam:String;
	final statusParam:String;

	public var object(get, never):h2d.Object;

	inline function get_object():h2d.Object
		return result.object;

	public function new(result:BuilderResult, highlightParam:String, statusParam:String) {
		this.result = result;
		this.highlightParam = highlightParam;
		this.statusParam = statusParam;
	}

	public function setHighlight(value:String):Void {
		result.setParameter(highlightParam, value);
	}

	public function setStatus(value:String):Void {
		result.setParameter(statusParam, value);
	}

	public function beginUpdate(?data:T):Void {
		result.beginUpdate();
	}

	public function endUpdate():Void {
		result.endUpdate();
	}

	public function getResult():Null<BuilderResult> {
		return result;
	}
}

/** Factory that creates CellVisual instances for a grid.
 *  Owns the highlight default value and highlight resolution logic. */
interface CellVisualFactory<T> {
	/** The default (reset) value for the highlight parameter (e.g. "none"). */
	var highlightDefault(get, never):String;

	/** Build a cell visual for the given coordinate and data. */
	function buildCell(coord:CellCoord, data:Null<T>, extraParams:Null<Map<String, Dynamic>>):CellVisual<T>;

	/** Determine the highlight value for a cell during drag/card targeting.
	 *  Return a string matching the cell programmable's highlight enum values. */
	function resolveHighlightValue(coord:CellCoord, accepts:Bool):String;
}

/** Configuration for DefaultCellVisualFactory construction. */
@:structInit
@:nullSafety
typedef CellVisualFactoryConfig<T> = {
	/** Default programmable name used to build each cell. */
	var cellBuildName:String;

	/** Optional delegate to override programmable name or params per cell. */
	var ?cellBuildDelegate:CellBuildDelegate<T>;

	/** Cell parameter name used for highlight state (default: "highlight"). */
	var ?highlightParam:String;

	/** Cell parameter name used for hover status (default: "status"). */
	var ?statusParam:String;

	/** Optional delegate to determine per-cell highlight value during drag/card targeting. */
	var ?highlightDelegate:GridHighlightDelegate;
}

/** Default factory that builds cells via MultiAnimBuilder.buildWithParameters().
 *  Injects col, row, highlight, and status params automatically. */
class DefaultCellVisualFactory<T> implements CellVisualFactory<T> {
	final builder:MultiAnimBuilder;
	final defaultBuildName:String;
	final cellBuildDelegate:Null<CellBuildDelegate<T>>;
	final _highlightParam:String;
	final _statusParam:String;
	final _highlightDefault:String;
	final highlightDelegate:Null<GridHighlightDelegate>;

	public var highlightDefault(get, never):String;

	inline function get_highlightDefault():String
		return _highlightDefault;

	public function new(builder:MultiAnimBuilder, config:CellVisualFactoryConfig<T>) {
		this.builder = builder;
		this.defaultBuildName = config.cellBuildName;
		this.cellBuildDelegate = config.cellBuildDelegate;
		this._highlightParam = config.highlightParam != null ? config.highlightParam : "highlight";
		this._highlightDefault = "none";
		this._statusParam = config.statusParam != null ? config.statusParam : "status";
		this.highlightDelegate = config.highlightDelegate;
	}

	public function buildCell(coord:CellCoord, data:Null<T>, extraParams:Null<Map<String, Dynamic>>):CellVisual<T> {
		var buildName = defaultBuildName;
		var delegateParams:Null<Map<String, Dynamic>> = null;

		if (cellBuildDelegate != null) {
			final info = cellBuildDelegate(coord.col, coord.row, data);
			if (info != null) {
				if (info.buildName != null)
					buildName = info.buildName;
				delegateParams = info.params;
			}
		}

		final params:Map<String, Dynamic> = new Map();
		params.set("col", coord.col);
		params.set("row", coord.row);
		params.set(_highlightParam, _highlightDefault);
		params.set(_statusParam, "normal");

		if (delegateParams != null)
			for (key => value in delegateParams)
				params.set(key, value);

		if (extraParams != null)
			for (key => value in extraParams)
				params.set(key, value);

		final result = builder.buildWithParameters(buildName, params, null, null, true);
		return new DefaultCellVisual<T>(result, _highlightParam, _statusParam);
	}

	public function resolveHighlightValue(coord:CellCoord, accepts:Bool):String {
		if (highlightDelegate != null)
			return highlightDelegate(coord, accepts);
		return if (accepts) "accept" else "reject";
	}

	/** Get the highlight param name (for layer construction). */
	public inline function getHighlightParam():String
		return _highlightParam;

	/** Get the status param name (for layer construction). */
	public inline function getStatusParam():String
		return _statusParam;
}

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
typedef GridConfig<T> = {
	/** Grid geometry (Rect or Hex). */
	var gridType:GridType;

	/** Factory that builds cell visuals and owns highlight/status semantics. */
	var cellVisualFactory:CellVisualFactory<T>;

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

	/** Optional delegate to control when a swap occurs. Called when swapEnabled=true and the
	 *  draggable has a source cell. Return true to emit CellSwap, false to fall through to CellDrop.
	 *  When null, defaults to isOccupied() — swap whenever the target cell has data. */
	var ?swapAccepts:GridSwapAccepts;

	/** Parent container for swap animation visuals. During swap, the displaced item is reparented
	 *  here so it renders above grid content. Typically an h2d.Layers added at a screen layer above
	 *  the grid (e.g. ModalLayer or a NamedLayer). If null, falls back to the grid's own root at
	 *  a high z-order (works for simple cases but may render behind overlays/dialogs). */
	var ?swapAnimContainer:h2d.Object;

	/** Optional TweenManager for cell lifecycle animations (entrance, exit, effects).
	 *  If null, all cell additions/removals are instant. */
	var ?tweenManager:Dynamic;

	/** Optional delegate to provide a custom visual for the displaced item during swap animation.
	 *  When set, the delegate builds the visual to animate instead of using the raw detached cell.
	 *  This is useful when cell programmables include backgrounds that shouldn't animate.
	 *  Return null from the delegate to fall back to the detached cell visual for that cell. */
	var ?swapVisualProvider:SwapVisualProvider<T>;

	// --- Rect layout options ---

	/** Cell origin point for Rect grids. TopLeft (default): hit area starts at cell position.
	 *  Centered: hit area is centered on cell position (for centered visuals like hex sprites). */
	var ?rectOrigin:RectOrigin;

	// --- Built-in cell dragging ---

	/** Enable built-in cell dragging: cells with data become draggable on mouse press.
	 *  The grid internally creates and manages a UIMultiAnimDraggable per drag operation,
	 *  registers its own cells as drop zones, and emits CellDrop/CellSwap/CellDragStart/CellDragEnd events.
	 *  No external draggable wiring needed. Default: false. */
	var ?cellDragEnabled:Bool;

	/** Optional filter for which cells can be dragged. Called on mouse press when cellDragEnabled=true.
	 *  Return true to allow dragging. When null, all cells with non-null data are draggable. */
	var ?cellDragFilter:CellDragFilter<T>;

	/** Parent container for the drag visual during cell drag. The dragged cell is reparented here
	 *  so it renders above other grid content. If null, falls back to the grid's own root at a high z-order. */
	var ?cellDragContainer:h2d.Object;
}
