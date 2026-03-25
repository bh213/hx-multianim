package bh.ui;

import bh.base.FPoint;
import bh.base.GridDirection;
import bh.base.Hex;
import bh.base.Hex.HexLayout;
import bh.base.Hex.HexOrientation;
import bh.base.MAObject;
import bh.base.MAObject.MultiAnimObjectData;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.base.TweenManager;
import bh.base.TweenManager.Tween;
import bh.base.TweenManager.TweenProperty;
import bh.multianim.MultiAnimParser.EasingType;
import bh.paths.AnimatedPath;
import bh.paths.MultiAnimPaths.PathNormalization;
import bh.ui.UICardHandTypes;
import bh.ui.UIElement.UIScreenEvent;
import bh.ui.UIHigherOrderComponent;
import bh.ui.UIMultiAnimDraggable;
import bh.ui.UIMultiAnimDraggable.DropZoneId;
import bh.ui.UIMultiAnimGridTypes;
import h2d.col.Bounds;
import h2d.col.Point;

using bh.base.HeapsUtils;

// Alias to avoid name shadowing with GridType.Hex enum constructor
private typedef HexUtil = bh.base.Hex.Hex;

/** Internal cell entry storing the visual and game data. */
private class CellEntry<T> {
	public var coord:CellCoord;
	public var visual:CellVisual<T>;
	public var data:Null<T>;

	public function new(coord:CellCoord, visual:CellVisual<T>, data:Null<T>) {
		this.coord = coord;
		this.visual = visual;
		this.data = data;
	}
}

/** No-op CellVisual used as a placeholder during swap detach operations. */
private class DummyCellVisual<T> implements CellVisual<T> {
	public var object(get, never):h2d.Object;

	final _object:h2d.Object;

	inline function get_object():h2d.Object
		return _object;

	public function new() {
		_object = new h2d.Object();
	}

	public function setHighlight(value:String):Void {}

	public function setStatus(value:String):Void {}

	public function beginUpdate(?data:T):Void {}

	public function endUpdate():Void {}

	public function getResult():Null<BuilderResult> {
		return null;
	}
}

/** Internal entry for an in-flight swap animation (displaced item moving to new cell). */
private class SwapAnimEntry {
	public var animPath:AnimatedPath;
	public var object:h2d.Object;
	public var targetCoord:CellCoord;
	public var onComplete:Null<Void -> Void>;

	public function new(animPath:AnimatedPath, object:h2d.Object, targetCoord:CellCoord, ?onComplete:Void -> Void) {
		this.animPath = animPath;
		this.object = object;
		this.targetCoord = targetCoord;
		this.onComplete = onComplete;
	}
}

/** Internal binding for a registered draggable. */
private typedef DraggableBinding = {
	var draggable:UIMultiAnimDraggable;
	var accepts:Null<GridDropAccepts>;
}

/** Internal binding for a registered card hand. */
private typedef CardHandBinding = {
	var cardHand:UICardHandHelper;
	var accepts:Null<GridCardAccepts>;
	var targetPrefix:String;
	var eventListener:Null<(event:UICardHandTypes.CardHandEvent) -> Void>;
}

/**
 * A 2D grid component (rectangular or hexagonal) that manages cell state,
 * rendering via `.manim` programmables, drag-drop integration, and card hand targeting.
 *
 * Follows the helper/manager pattern (like `UICardHandHelper`): the grid owns its
 * scene graph root, communicates via callbacks, and the game routes mouse events.
 *
 * ## Usage
 * ```haxe
 * var grid = new UIMultiAnimGrid(builder, {
 *     gridType: Rect(50, 50, 4),
 *     cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "gridCell"}),
 *     originX: 100, originY: 100,
 * });
 * grid.addRectRegion(5, 4);
 * grid.onGridEvent = (event) -> switch event {
 *     case CellClick(cell, _): trace('clicked ${cell.col}, ${cell.row}');
 *     default:
 * };
 * ```
 */
class UIMultiAnimGrid<T> implements UIHigherOrderComponent {
	// --- Config ---
	final builder:MultiAnimBuilder;
	final gridType:GridType;
	final cellFactory:CellVisualFactory<T>;
	final snapPathName:Null<String>;
	final returnPathName:Null<String>;
	final swapPathName:Null<String>;
	final swapEnabled:Bool;
	final swapAccepts:Null<GridSwapAccepts>;
	final swapAnimContainer:Null<h2d.Object>;
	final swapVisualProvider:Null<SwapVisualProvider<T>>;
	final tweenManager:Null<TweenManager>;

	// --- Geometry ---
	final hexLayout:Null<HexLayout>;
	final rectCellW:Float;
	final rectCellH:Float;
	final rectGap:Float;

	// --- Scene graph ---
	final root:h2d.Layers;

	// --- Cell storage: Map<"col_row", CellEntry<T>> ---
	final cells:Map<String, CellEntry<T>> = new Map();
	var _cellCount:Int = 0;

	// --- Grid layers: named overlays rendered per-cell ---
	final layerConfigs:Map<String, GridLayerConfig> = new Map();
	// layerEntries: Map<"layerName", Map<"col_row", CellVisual<T>>>
	final layerEntries:Map<String, Map<String, CellVisual<T>>> = new Map();

	// --- Hover state ---
	var hoveredCell:Null<CellCoord> = null;

	// --- Drag-drop ---
	final registeredDraggables:Array<DraggableBinding> = [];
	var activeDragHighlightedCells:Array<CellCoord> = [];

	function isCellDragHighlighted(col:Int, row:Int):Bool {
		for (c in activeDragHighlightedCells)
			if (c.col == col && c.row == row)
				return true;
		return false;
	}

	function resolveHighlightValue(cell:CellCoord, accepts:Bool):String {
		return cellFactory.resolveHighlightValue(cell, accepts);
	}

	/** Apply highlight values to all cells based on an accept predicate (drag start / card drag start). */
	function applyDragHighlights(acceptsFn:(coord:CellCoord) -> Bool):Void {
		for (_ => entry in cells) {
			final accepts = acceptsFn(entry.coord);
			final value = resolveHighlightValue(entry.coord, accepts);
			if (value != cellFactory.highlightDefault) {
				entry.visual.setHighlight(value);
				activeDragHighlightedCells.push({col: entry.coord.col, row: entry.coord.row});
			}
		}
	}

	/** Clear all drag/card highlight values on cells. */
	function clearDragHighlights():Void {
		for (cell in activeDragHighlightedCells) {
			final e = cells.get(cellKey(cell.col, cell.row));
			if (e != null)
				e.visual.setHighlight(cellFactory.highlightDefault);
		}
		activeDragHighlightedCells = [];
	}

	/** Apply hover/unhover visual feedback on a cell (shared by drag zone hover and card targeting). */
	function applyCellTargetFeedback(coord:CellCoord, highlight:Bool, source:CellTargetSource):Void {
		final e = cells.get(cellKey(coord.col, coord.row));
		if (e != null) {
			e.visual.beginUpdate();
			e.visual.setStatus(if (highlight) "hover" else "normal");
			if (!highlight && !isCellDragHighlighted(coord.col, coord.row))
				e.visual.setHighlight(cellFactory.highlightDefault);
			e.visual.endUpdate();
		}
		if (highlight)
			emitEvent(CellTargetEnter(coord, source));
		else
			emitEvent(CellTargetLeave(coord, source));
	}

	// --- Card hand ---
	final registeredCardHands:Array<CardHandBinding> = [];
	final cardTargetInteractives:Map<String, MAObject> = new Map();
	final cardTargetWrappers:Map<String, UIInteractiveWrapper> = new Map();
	var activeCardDragId:Null<String> = null;

	// --- Active swap animations ---
	final activeSwapAnims:Array<SwapAnimEntry> = [];

	// --- Instance counter for unique card hand target IDs ---
	static var cardTargetCounter:Int = 0;
	final cardTargetId:Int;
	var cardHandBindingCounter:Int = 0;

	// --- Callbacks ---

	/** Called when a grid event occurs (click, hover, drop, card play). */
	public var onGridEvent:Null<(event:GridEvent<T>) -> Void> = null;

	/** Called after a cell is built. Use to customize the cell visual (add overlays, etc.). */
	public var onCellBuilt:Null<(coord:CellCoord, visual:CellVisual<T>) -> Void> = null;

	// ============================================================
	// Construction
	// ============================================================

	public function new(builder:MultiAnimBuilder, config:GridConfig<T>) {
		this.builder = builder;
		this.gridType = config.gridType;
		this.cellFactory = config.cellVisualFactory;
		this.snapPathName = config.snapPathName;
		this.returnPathName = config.returnPathName;
		this.swapPathName = config.swapPathName;
		this.swapEnabled = config.swapEnabled != null ? config.swapEnabled : false;
		this.swapAccepts = config.swapAccepts;
		this.swapAnimContainer = config.swapAnimContainer;
		this.swapVisualProvider = config.swapVisualProvider;
		this.tweenManager = config.tweenManager;

		this.root = new h2d.Layers();
		this.root.setPosition(config.originX != null ? config.originX : 0, config.originY != null ? config.originY : 0);

		this.cardTargetId = cardTargetCounter++;

		switch gridType {
			case Rect(w, h, gap):
				rectCellW = w;
				rectCellH = h;
				rectGap = gap != null ? gap : 0;
				hexLayout = null;
			case Hex(orientation, sx, sy):
				hexLayout = HexLayout.createFromFloats(orientation, sx, sy);
				rectCellW = 0;
				rectCellH = 0;
				rectGap = 0;
		}
	}

	// ============================================================
	// Cell structure (add/remove cells)
	// ============================================================

	/** Add a cell at (col, row) with optional initial data and parameters. */
	public function addCell(col:Int, row:Int, ?data:T, ?params:Map<String, Dynamic>):Void {
		final key = cellKey(col, row);
		if (cells.exists(key))
			return;

		final coord:CellCoord = {col: col, row: row};
		final entry = buildCell(coord, data, params);
		cells.set(key, entry);
		_cellCount++;
		root.add(entry.visual.object, 0);
		positionCell(entry);

		if (onCellBuilt != null)
			onCellBuilt(coord, entry.visual);

		refreshAllDraggableZones();
		refreshAllCardTargets();
	}

	/** Remove a cell at (col, row). Also clears all layers on this cell. */
	public function removeCell(col:Int, row:Int):Void {
		final key = cellKey(col, row);
		final entry = cells.get(key);
		if (entry == null)
			return;

		entry.visual.object.remove();
		cells.remove(key);
		_cellCount--;
		clearAllLayersOnCell(col, row);

		// Clear hover if this was the hovered cell
		if (hoveredCell != null && hoveredCell.col == col && hoveredCell.row == row)
			hoveredCell = null;

		refreshAllDraggableZones();
		refreshAllCardTargets();
	}

	/** Check if a cell exists at (col, row). */
	public inline function hasCell(col:Int, row:Int):Bool {
		return cells.exists(cellKey(col, row));
	}

	/** Batch-add a rectangular region of cells (0..cols-1, 0..rows-1). */
	public function addRectRegion(cols:Int, rows:Int):Void {
		for (row in 0...rows)
			for (col in 0...cols)
				if (!hasCell(col, row))
					addCellInternal(col, row, null, null);

		refreshAllDraggableZones();
		refreshAllCardTargets();
	}

	/** Batch-add a hexagonal region centered at (centerCol, centerRow) with given radius. */
	public function addHexRegion(centerCol:Int, centerRow:Int, radius:Int):Void {
		final centerHex = new HexUtil(centerCol, centerRow, -centerCol - centerRow);
		final range = HexUtil.createRange(radius);
		for (relHex in range) {
			final absHex = relHex.toHex(centerHex);
			if (!hasCell(absHex.q, absHex.r))
				addCellInternal(absHex.q, absHex.r, null, null);
		}

		refreshAllDraggableZones();
		refreshAllCardTargets();
	}

	// ============================================================
	// Cell data
	// ============================================================

	/** Set cell data and optionally update visual parameters. */
	public function set(col:Int, row:Int, data:T, ?params:Map<String, Dynamic>):Void {
		final entry = getEntry(col, row);
		final oldData = entry.data;
		entry.data = data;

		entry.visual.beginUpdate(data);
		final result = entry.visual.getResult();
		if (result != null && params != null)
			for (key => value in params)
				result.setParameter(key, value);
		entry.visual.endUpdate();

		emitEvent(CellDataChanged(entry.coord, oldData, data));
	}

	/** Get cell data at (col, row). Returns null if cell is empty. */
	public function get(col:Int, row:Int):Null<T> {
		final entry = cells.get(cellKey(col, row));
		return entry != null ? entry.data : null;
	}

	/** Clear cell data and reset visual to default. */
	public function clear(col:Int, row:Int):Void {
		final entry = getEntry(col, row);
		final oldData = entry.data;
		entry.data = null;

		// Reset to defaults
		entry.visual.beginUpdate(null);
		entry.visual.setHighlight(cellFactory.highlightDefault);
		entry.visual.setStatus("normal");
		entry.visual.endUpdate();

		emitEvent(CellDataChanged(entry.coord, oldData, null));
	}

	/** Swap two cells' data and visuals, optionally animated.
	 *  Emits CellSwap with ctx.programmatic=true. Both cells must exist.
	 *  @param animated If true (default), uses swapPathName (or returnPathName fallback) for both items.
	 *                  If false, swaps instantly. */
	public function swapCells(col1:Int, row1:Int, col2:Int, row2:Int, animated:Bool = true):Void {
		if (col1 == col2 && row1 == row2)
			return;

		final coord1:CellCoord = {col: col1, row: row1};
		final coord2:CellCoord = {col: col2, row: row2};
		final ctx = new SwapContext(true);
		emitEvent(CellSwap(coord1, coord2, null, ctx));

		if (ctx.handled && !ctx.accepted)
			return;

		// Resolve swap path
		final resolvedSwapPath = if (ctx.swapPath != null) ctx.swapPath
			else if (swapPathName != null) swapPathName
			else returnPathName;

		// Snapshot data before swap
		final entry1 = getEntry(col1, row1);
		final entry2 = getEntry(col2, row2);
		final data1 = entry1.data;
		final data2 = entry2.data;

		if (animated && resolvedSwapPath != null) {
			// Detach both visuals WITHOUT rebuilding — we control rebuild timing
			final det1 = detachCellVisualRaw(col1, row1);
			final det2 = detachCellVisualRaw(col2, row2);

			// Swap data and rebuild both cells so they show correct data immediately
			entry1.data = data2;
			entry2.data = data1;
			rebuildCell(col1, row1);
			rebuildCell(col2, row2);

			var pendingAnims = 2;
			final onBothDone = () -> {
				pendingAnims--;
				if (pendingAnims <= 0) {
					if (ctx.completeCb != null)
						ctx.completeCb();
				}
			};

			// Animate cell1 visual → cell2 position
			if (det1 != null) {
				animateSwapVisual(det1, {col: col1, row: row1}, cellPosition(col2, row2), resolvedSwapPath, onBothDone);
			} else {
				onBothDone();
			}

			// Animate cell2 visual → cell1 position
			if (det2 != null) {
				animateSwapVisual(det2, {col: col2, row: row2}, cellPosition(col1, row1), resolvedSwapPath, onBothDone);
			} else {
				onBothDone();
			}
		} else {
			// Instant swap — just swap data and rebuild both
			entry1.data = data2;
			entry2.data = data1;
			rebuildCell(col1, row1);
			rebuildCell(col2, row2);
			if (ctx.completeCb != null)
				ctx.completeCb();
		}

		emitEvent(CellDataChanged(coord1, data1, data2));
		emitEvent(CellDataChanged(coord2, data2, data1));
	}

	/** Internal: animate a detached visual from its scene position to a target scene position.
	 *  Handles swapVisualProvider, zero-distance skip, reparenting, and AnimatedPath creation.
	 *  Callers must rebuild cells BEFORE calling this — onDone does NOT rebuild. */
	function animateSwapVisual(detached:{object:h2d.Object, data:Null<T>, sceneX:Float, sceneY:Float},
			sourceCoord:CellCoord, toScenePos:FPoint, pathName:String, onDone:Void -> Void):Void {
		// Use custom swap visual if provider is set, otherwise use detached cell visual
		final animObj = if (swapVisualProvider != null) {
			final custom = swapVisualProvider(sourceCoord, detached.data);
			if (custom != null) {
				detached.object.remove();
				custom;
			} else {
				detached.object;
			}
		} else {
			detached.object;
		}

		final dx = toScenePos.x - detached.sceneX;
		final dy = toScenePos.y - detached.sceneY;
		if (dx * dx + dy * dy < 0.25) {
			animObj.remove();
			onDone();
			return;
		}

		// Reparent first so we can convert scene-space endpoints to parent-local space
		final animParent = reparentForSwapAnim(animObj);
		final localFrom = sceneToLocal(animParent, detached.sceneX, detached.sceneY);
		final localTo = sceneToLocal(animParent, toScenePos.x, toScenePos.y);

		// Position object at start immediately (prevents one-frame flash at wrong position)
		animObj.setPosition(localFrom.x, localFrom.y);

		// AnimatedPath outputs in parent-local space — no conversion needed in update()
		final animPath = builder.createAnimatedPath(pathName, Stretch(localFrom, localTo));

		activeSwapAnims.push(new SwapAnimEntry(animPath, animObj, sourceCoord, () -> {
			animObj.remove();
			onDone();
		}));
	}

	/** Check if cell has non-null data. */
	public function isOccupied(col:Int, row:Int):Bool {
		final entry = cells.get(cellKey(col, row));
		return entry != null && entry.data != null;
	}

	/** Iterate all cells. Callback receives (col, row, data) — data may be null. */
	public function forEach(fn:(col:Int, row:Int, data:Null<T>) -> Void):Void {
		for (_ => entry in cells)
			fn(entry.coord.col, entry.coord.row, entry.data);
	}

	// ============================================================
	// Cell visual params
	// ============================================================

	/** Set a single game-specific parameter on the cell's underlying BuilderResult.
	 *  No-op if the cell visual does not use BuilderResult. */
	public function setCellParameter(col:Int, row:Int, param:String, value:Dynamic):Void {
		final result = getEntry(col, row).visual.getResult();
		if (result != null)
			result.setParameter(param, value);
	}

	/** Set multiple game-specific parameters on the cell's BuilderResult (batched).
	 *  No-op if the cell visual does not use BuilderResult. */
	public function setCellParameters(col:Int, row:Int, params:Map<String, Dynamic>):Void {
		final result = getEntry(col, row).visual.getResult();
		if (result != null) {
			result.beginUpdate();
			for (key => value in params)
				result.setParameter(key, value);
			result.endUpdate();
		}
	}

	/** Get the cell's visual abstraction. */
	public function getCellVisual(col:Int, row:Int):Null<CellVisual<T>> {
		final entry = cells.get(cellKey(col, row));
		return entry != null ? entry.visual : null;
	}

	/** Fully rebuild a cell (e.g., when the delegate returns a different programmable). */
	public function rebuildCell(col:Int, row:Int):Void {
		final key = cellKey(col, row);
		final oldEntry = cells.get(key);
		if (oldEntry == null)
			throw 'Cell ($col, $row) does not exist';

		oldEntry.visual.object.remove();

		final newEntry = buildCell(oldEntry.coord, oldEntry.data, null);
		cells.set(key, newEntry);
		root.add(newEntry.visual.object, 0);
		positionCell(newEntry);

		if (onCellBuilt != null)
			onCellBuilt(newEntry.coord, newEntry.visual);
	}

	// ============================================================
	// Cell animations
	// ============================================================

	/** Tween a cell's visual properties (position, alpha, scale, rotation).
	 *  Requires TweenManager in GridConfig. Returns the Tween for chaining/cancellation, or null if no TweenManager. */
	public function tweenCell(col:Int, row:Int, duration:Float, properties:Array<TweenProperty>, ?easing:EasingType):Null<Tween> {
		if (tweenManager == null)
			return null;
		final entry = getEntry(col, row);
		return tweenManager.tween(entry.visual.object, duration, properties, easing);
	}

	/** Remove a cell with an exit animation (fade out, scale down, etc.).
	 *  Cell is removed from the grid data immediately but visual lingers until animation completes.
	 *  Requires TweenManager. Falls back to instant removal without one. */
	public function removeCellAnimated(col:Int, row:Int, duration:Float, properties:Array<TweenProperty>,
			?easing:EasingType, ?onComplete:Void -> Void):Void {
		final key = cellKey(col, row);
		final entry = cells.get(key);
		if (entry == null)
			return;

		// Remove from grid data immediately (no longer hittable or interactive)
		cells.remove(key);
		_cellCount--;
		clearAllLayersOnCell(col, row);
		if (hoveredCell != null && hoveredCell.col == col && hoveredCell.row == row)
			hoveredCell = null;
		refreshAllDraggableZones();
		refreshAllCardTargets();

		if (tweenManager != null && duration > 0) {
			// Animate, then remove scene object
			final obj = entry.visual.object;
			final tween = tweenManager.tween(obj, duration, properties, easing);
			tween.onComplete = () -> {
				obj.remove();
				if (onComplete != null)
					onComplete();
			};
		} else {
			entry.visual.object.remove();
			if (onComplete != null)
				onComplete();
		}
	}

	/** Add a cell with an entrance animation.
	 *  The cell is added to the grid immediately (hittable), then animated from the given initial properties
	 *  to their natural values. `initProperties` sets the starting state (e.g. alpha=0, scale=0).
	 *  Requires TweenManager. Falls back to instant addition without one.
	 *  @param initProperties Starting property values — the tween targets are the "natural" values (alpha=1, scale=1, etc.) */
	public function addCellAnimated(col:Int, row:Int, ?data:T, ?params:Map<String, Dynamic>, duration:Float = 0.3,
			?initProperties:Array<TweenProperty>, ?easing:EasingType):Void {
		addCell(col, row, data, params);

		if (tweenManager != null && initProperties != null && duration > 0) {
			final entry = cells.get(cellKey(col, row));
			if (entry == null)
				return;
			final obj = entry.visual.object;

			// Set to initial state, tween to natural values
			// The properties passed are the TARGET (natural) state.
			// We need to swap: set object to "from" values, tween to "to" values.
			// Convention: initProperties contains the STARTING values.
			// E.g. addCellAnimated(..., [Alpha(0), Scale(0)]) means start at alpha=0/scale=0, tween to current (1.0/1.0).
			var tweenProps:Array<TweenProperty> = [];
			for (prop in initProperties) {
				switch prop {
					case Alpha(from):
						tweenProps.push(Alpha(obj.alpha));
						obj.alpha = from;
					case Scale(from):
						tweenProps.push(Scale(obj.scaleX));
						obj.scaleX = from;
						obj.scaleY = from;
					case ScaleX(from):
						tweenProps.push(ScaleX(obj.scaleX));
						obj.scaleX = from;
					case ScaleY(from):
						tweenProps.push(ScaleY(obj.scaleY));
						obj.scaleY = from;
					case X(from):
						tweenProps.push(X(obj.x));
						obj.x = from;
					case Y(from):
						tweenProps.push(Y(obj.y));
						obj.y = from;
					case Rotation(from):
						tweenProps.push(Rotation(obj.rotation));
						obj.rotation = from;
					case Custom(getter, setter, from):
						tweenProps.push(Custom(getter, setter, getter()));
						setter(from);
				}
			}
			tweenManager.tween(obj, duration, tweenProps, easing);
		}
	}

	// ============================================================
	// Grid layers — per-cell stacked programmables
	// ============================================================

	/** Register a named layer. Layers are rendered per-cell at the given z-order using a separate programmable.
	 *  Base cells render at z-order 0. Call setLayer() to build layer instances on individual cells. */
	public function addLayer(name:String, config:GridLayerConfig):Void {
		if (layerConfigs.exists(name))
			throw 'Grid layer "$name" already registered';
		layerConfigs.set(name, config);
		layerEntries.set(name, new Map());
	}

	/** Build (or rebuild) a layer instance on a cell. Creates the programmable at the cell's position.
	 *  If the layer already exists on this cell, it's cleared first. */
	public function setLayer(col:Int, row:Int, layerName:String, ?params:Map<String, Dynamic>):Void {
		final config = layerConfigs.get(layerName);
		if (config == null)
			throw 'Grid layer "$layerName" not registered';
		if (!cells.exists(cellKey(col, row)))
			throw 'Cell ($col, $row) does not exist';

		final entries = layerEntries.get(layerName);
		final key = cellKey(col, row);

		// Clear existing if present
		final existing = entries.get(key);
		if (existing != null) {
			existing.object.remove();
			entries.remove(key);
		}

		// Build the layer programmable (only user-supplied params — no auto col/row injection)
		final buildParams:Map<String, Dynamic> = if (params != null) params else new Map();

		final result = builder.buildWithParameters(config.buildName, buildParams, null, null, true);
		final visual = new DefaultCellVisual<T>(result, "", "");

		// Position at cell coordinates
		final localPos = getCellLocalPosition({col: col, row: row});
		visual.object.setPosition(localPos.x, localPos.y);
		root.add(visual.object, config.zOrder);

		entries.set(key, visual);
	}

	/** Clear a layer instance from a cell. */
	public function clearLayer(col:Int, row:Int, layerName:String):Void {
		final entries = layerEntries.get(layerName);
		if (entries == null)
			return;

		final key = cellKey(col, row);
		final visual = entries.get(key);
		if (visual != null) {
			visual.object.remove();
			entries.remove(key);
		}
	}

	/** Clear a layer from all cells. */
	public function clearLayerAll(layerName:String):Void {
		final entries = layerEntries.get(layerName);
		if (entries == null)
			return;

		for (_ => visual in entries)
			visual.object.remove();
		entries.clear();
	}

	/** Clear all layers from all cells. */
	public function clearAllLayers():Void {
		for (_ => entries in layerEntries) {
			for (_ => visual in entries)
				visual.object.remove();
			entries.clear();
		}
	}

	/** Get the CellVisual for a layer instance on a cell (for incremental updates).
	 *  Returns null if the layer doesn't exist on this cell. */
	public function getLayerVisual(col:Int, row:Int, layerName:String):Null<CellVisual<T>> {
		final entries = layerEntries.get(layerName);
		if (entries == null)
			return null;
		return entries.get(cellKey(col, row));
	}

	/** Check if a layer instance exists on a cell. */
	public function hasLayer(col:Int, row:Int, layerName:String):Bool {
		final entries = layerEntries.get(layerName);
		if (entries == null)
			return false;
		return entries.exists(cellKey(col, row));
	}

	/** Clear all layers on a specific cell. */
	function clearAllLayersOnCell(col:Int, row:Int):Void {
		final key = cellKey(col, row);
		for (_ => entries in layerEntries) {
			final entry = entries.get(key);
			if (entry != null) {
				entry.object.remove();
				entries.remove(key);
			}
		}
	}

	// ============================================================
	// External objects at layer z-order
	// ============================================================

	/** Add an external object to the grid's layer hierarchy at the given z-order.
	 *  Use this to insert objects (e.g. targeting arrows) between grid layers.
	 *  The object's position is in grid-local coordinates. */
	public function addExternalObject(obj:h2d.Object, zOrder:Int):Void {
		root.add(obj, zOrder);
	}

	/** Remove a previously added external object from the grid. */
	public function removeExternalObject(obj:h2d.Object):Void {
		obj.remove();
	}

	// ============================================================
	// Detach / reattach cell visual
	// ============================================================

	/** Detach a cell's visual for free animation (e.g. fly to another location).
	 *  The cell stays in the grid (data preserved) but shows as empty.
	 *  Returns the detached object and its scene position, or null if cell doesn't exist.
	 *  Call `reattachCellVisual()` to put it back, or `rebuildCell()` to create a fresh visual. */
	public function detachCellVisual(col:Int, row:Int):Null<{object:h2d.Object, data:Null<T>, sceneX:Float, sceneY:Float}> {
		final key = cellKey(col, row);
		final entry = cells.get(key);
		if (entry == null)
			return null;

		final obj = entry.visual.object;
		final pos = cellPosition(col, row);
		final data = entry.data;

		// Safe detach: prevent h2d.Graphics.onRemove() from clearing draw commands
		obj.safeDetach();

		// Rebuild the cell entry immediately so the detached object is fully severed
		// from the grid. This ensures later `rebuildCell()` won't remove our detached object.
		final freshEntry = buildCell(entry.coord, entry.data, null);
		cells.set(key, freshEntry);
		root.add(freshEntry.visual.object, 0);
		positionCell(freshEntry);

		return {object: obj, data: data, sceneX: pos.x, sceneY: pos.y};
	}

	/** Internal: detach cell visual without rebuilding. Used by swap to control rebuild timing.
	 *  Replaces entry.visual.object with a dummy so subsequent rebuildCell() won't destroy the detached object. */
	function detachCellVisualRaw(col:Int, row:Int):Null<{object:h2d.Object, data:Null<T>, sceneX:Float, sceneY:Float}> {
		final key = cellKey(col, row);
		final entry = cells.get(key);
		if (entry == null)
			return null;

		final obj = entry.visual.object;
		final pos = cellPosition(col, row);
		final data = entry.data;

		obj.safeDetach();

		// Replace with a dummy so rebuildCell's oldEntry.visual.object.remove() is harmless
		entry.visual = new DummyCellVisual<T>();

		return {object: obj, data: data, sceneX: pos.x, sceneY: pos.y};
	}

	/** Reattach a previously detached cell visual (or rebuild if the object was disposed).
	 *  If `obj` is provided, it's placed back at the cell position.
	 *  If `obj` is null, the cell is fully rebuilt from scratch. */
	public function reattachCellVisual(col:Int, row:Int, ?obj:h2d.Object):Void {
		final entry = cells.get(cellKey(col, row));
		if (entry == null)
			throw 'Cell ($col, $row) does not exist';

		if (obj != null) {
			root.add(obj, 0);
			positionCell(entry);
		} else {
			// Full rebuild
			rebuildCell(col, row);
		}
	}

	// ============================================================
	// Coordinate queries
	// ============================================================

	/** Find which cell is at the given scene coordinates. Returns null if no cell. */
	public function cellAtPoint(sceneX:Float, sceneY:Float):Null<CellCoord> {
		final local = root.globalToLocal(new Point(sceneX, sceneY));
		return switch gridType {
			case Rect(_, _, _): hitTestRect(local.x, local.y);
			case Hex(_, _, _): hitTestHex(local.x, local.y);
		};
	}

	/** Get the world (scene) position of a cell's origin.
	 *  Converts from root-local coordinates to absolute scene coordinates. */
	public function cellPosition(col:Int, row:Int):FPoint {
		final local = getCellLocalPosition({col: col, row: row});
		final global = root.localToGlobal(new h2d.col.Point(local.x, local.y));
		return {x: global.x, y: global.y};
	}

	/** Get all existing neighbor cells. Rect: 4-directional, Hex: 6-directional. */
	public function neighbors(col:Int, row:Int):Array<CellCoord> {
		final result:Array<CellCoord> = [];
		switch gridType {
			case Rect(_, _, _):
				for (d in [{dc: 1, dr: 0}, {dc: -1, dr: 0}, {dc: 0, dr: 1}, {dc: 0, dr: -1}]) {
					final nc = col + d.dc;
					final nr = row + d.dr;
					if (cells.exists(cellKey(nc, nr)))
						result.push({col: nc, row: nr});
				}
			case Hex(_, _, _):
				final hex = toHex(col, row);
				for (dir in GridDirection.allDirections()) {
					final neighbor = HexUtil.neighbor(hex, dir);
					final nc:CellCoord = fromHex(neighbor);
					if (cells.exists(cellKey(nc.col, nc.row)))
						result.push(nc);
				}
		}
		return result;
	}

	/** Grid distance between two cells. Rect: Manhattan. Hex: hex distance. */
	public function distance(c1:Int, r1:Int, c2:Int, r2:Int):Int {
		return switch gridType {
			case Rect(_, _, _):
				iabs(c2 - c1) + iabs(r2 - r1);
			case Hex(_, _, _):
				HexUtil.distance(toHex(c1, r1), toHex(c2, r2));
		};
	}

	/** Number of cells in the grid. */
	public inline function cellCount():Int {
		return _cellCount;
	}

	// ============================================================
	// Mouse event routing
	// ============================================================

	/** Route mouse move events. Call from game screen's onMouseMove. Returns true if over a cell. */
	public function onMouseMove(sceneX:Float, sceneY:Float):Bool {
		final hit = cellAtPoint(sceneX, sceneY);

		if (!cellCoordsEqual(hit, hoveredCell)) {
			if (hoveredCell != null) {
				final entry = cells.get(cellKey(hoveredCell.col, hoveredCell.row));
				if (entry != null)
					entry.visual.setStatus("normal");
				emitEvent(CellTargetLeave(hoveredCell, Mouse));
			}
			hoveredCell = hit;
			if (hoveredCell != null) {
				final entry = cells.get(cellKey(hoveredCell.col, hoveredCell.row));
				if (entry != null)
					entry.visual.setStatus("hover");
				emitEvent(CellTargetEnter(hoveredCell, Mouse));
			}
		}

		return hoveredCell != null;
	}

	/** Route mouse click events. Call from game screen's onMouseClick. Returns true if a cell was clicked. */
	public function onMouseClick(sceneX:Float, sceneY:Float, button:Int):Bool {
		final hit = cellAtPoint(sceneX, sceneY);
		if (hit != null) {
			emitEvent(CellClick(hit, button));
			return true;
		}
		return false;
	}

	/** Route mouse release events. Grid does not consume release events. */
	public function onMouseRelease(sceneX:Float, sceneY:Float):Bool {
		return false;
	}

	/** Route screen events. Grid does not consume screen events. */
	public function handleScreenEvent(event:UIScreenEvent):Bool {
		return false;
	}

	// ============================================================
	// Drag-drop: receiving drops
	// ============================================================

	/** Register a draggable to drop onto this grid's cells.
	 *  The grid auto-creates DropZone per cell and manages highlight state.
	 *  Duplicate registrations for the same draggable are ignored. */
	public function acceptDrops(draggable:UIMultiAnimDraggable, ?accepts:GridDropAccepts):Void {
		// Guard against duplicate registration
		for (existing in registeredDraggables)
			if (existing.draggable == draggable)
				return;

		final binding:DraggableBinding = {
			draggable: draggable,
			accepts: accepts,
		};
		registeredDraggables.push(binding);
		createDropZonesForDraggable(binding);
		wireHighlightCallbacks(binding);
	}

	/** Unregister a draggable from this grid. */
	public function removeDrops(draggable:UIMultiAnimDraggable):Void {
		var i = registeredDraggables.length;
		while (i-- > 0) {
			if (registeredDraggables[i].draggable == draggable) {
				clearZonesForBinding(registeredDraggables[i]);
				registeredDraggables.splice(i, 1);
			}
		}
	}

	// ============================================================
	// Drag-drop: creating draggables FROM cells
	// ============================================================

	/** Create a UIMultiAnimDraggable from a cell's content.
	 *  Populates draggable's `sourceGrid`, `sourceCellCoord`, and `payload` fields. */
	public function makeDraggableFromCell(col:Int, row:Int, ?visualOverride:h2d.Object):UIMultiAnimDraggable {
		final entry = getEntry(col, row);
		final target = visualOverride != null ? visualOverride : entry.visual.object;

		final drag = UIMultiAnimDraggable.create(target);
		drag.returnToOrigin = true;

		if (snapPathName != null)
			drag.setSnapAnimPath(builder, snapPathName);
		if (returnPathName != null)
			drag.setReturnAnimPath(builder, returnPathName);

		// Populate source tracking and payload
		drag.sourceGrid = this;
		drag.sourceCellCoord = ({col: col, row: row} : CellCoord);
		drag.payload = entry.data;

		return drag;
	}

	// ============================================================
	// Card hand targeting
	// ============================================================

	/** Get all registered card target wrappers for sharing with other targeting systems. */
	public function getCardTargetWrappers():Array<UIInteractiveWrapper> {
		return [for (_ => w in cardTargetWrappers) w];
	}

	/** Register this grid's cells as card play targets.
	 *  Creates UIInteractiveWrapper per cell for the card hand's targeting system. */
	public function registerAsCardTarget(cardHand:UICardHandHelper, ?accepts:GridCardAccepts):Void {
		final binding:CardHandBinding = {
			cardHand: cardHand,
			accepts: accepts,
			targetPrefix: 'grid${cardTargetId}ch${cardHandBindingCounter++}',
			eventListener: null,
		};
		registeredCardHands.push(binding);
		createCardTargetsForBinding(binding);
	}

	/** Unregister from a card hand's targeting system. */
	public function unregisterAsCardTarget(cardHand:UICardHandHelper):Void {
		var i = registeredCardHands.length;
		while (i-- > 0) {
			if (registeredCardHands[i].cardHand == cardHand) {
				clearCardTargetsForBinding(registeredCardHands[i]);
				registeredCardHands.splice(i, 1);
			}
		}
	}

	// ============================================================
	// Lifecycle
	// ============================================================

	/** Reposition the grid origin. All cells and layers move automatically (they are children of root). */
	public function setOrigin(x:Float, y:Float):Void {
		root.setPosition(x, y);
	}

	/** Get the root scene graph object. Add to scene via addObjectToLayer(grid.getObject(), layer). */
	public function getObject():h2d.Object {
		return root;
	}

	/** Update — call from game loop for swap animations. */
	public function update(dt:Float):Void {
		if (activeSwapAnims.length == 0)
			return;

		var i = activeSwapAnims.length;
		while (i-- > 0) {
			final entry = activeSwapAnims[i];
			final s = entry.animPath.update(dt);
			// AnimatedPath outputs parent-local positions (Stretch endpoints converted at creation)
			entry.object.setPosition(s.position.x, s.position.y);
			if (s.done) {
				final cb = entry.onComplete;
				activeSwapAnims.splice(i, 1);
				if (cb != null)
					cb();
			}
		}
	}

	/** Clean up all resources. */
	public function dispose():Void {
		// Cancel active swap animations
		for (entry in activeSwapAnims)
			entry.object.remove();
		activeSwapAnims.resize(0);

		// Clear all drag bindings
		for (binding in registeredDraggables)
			clearZonesForBinding(binding);
		registeredDraggables.resize(0);

		// Clear all card hand bindings
		for (binding in registeredCardHands)
			clearCardTargetsForBinding(binding);
		registeredCardHands.resize(0);

		// Clear all layers
		clearAllLayers();
		layerConfigs.clear();

		// Remove scene graph
		root.remove();
		cells.clear();
		_cellCount = 0;
		hoveredCell = null;
	}

	// ============================================================
	// Internal: cell key
	// ============================================================

	inline function cellKey(col:Int, row:Int):String {
		return '${col}_${row}';
	}

	function getEntry(col:Int, row:Int):CellEntry<T> {
		final entry = cells.get(cellKey(col, row));
		if (entry == null)
			throw 'Cell ($col, $row) does not exist';
		return entry;
	}

	// ============================================================
	// Internal: cell building
	// ============================================================

	function buildCell(coord:CellCoord, data:Null<T>, ?extraParams:Map<String, Dynamic>):CellEntry<T> {
		final visual = cellFactory.buildCell(coord, data, extraParams);
		return new CellEntry(coord, visual, data);
	}

	function positionCell(entry:CellEntry<T>):Void {
		final p = getCellLocalPosition(entry.coord);
		entry.visual.object.setPosition(p.x, p.y);
	}

	/** Get cell position in local coordinates (relative to grid root). */
	function getCellLocalPosition(coord:CellCoord):FPoint {
		return switch gridType {
			case Rect(w, h, gap):
				final g = gap != null ? gap : 0.0;
				{x: coord.col * (w + g), y: coord.row * (h + g)};
			case Hex(_, _, _):
				final hex = toHex(coord.col, coord.row);
				final p = hexLayout.hexToPixel(hex);
				{x: p.x, y: p.y};
		};
	}

	/** Internal addCell that doesn't refresh zones (for batch operations). */
	function addCellInternal(col:Int, row:Int, data:Null<T>, params:Null<Map<String, Dynamic>>):Void {
		final key = cellKey(col, row);
		if (cells.exists(key))
			return;

		final coord:CellCoord = {col: col, row: row};
		final entry = buildCell(coord, data, params);
		cells.set(key, entry);
		_cellCount++;
		root.add(entry.visual.object, 0);
		positionCell(entry);

		if (onCellBuilt != null)
			onCellBuilt(coord, entry.visual);
	}

	// ============================================================
	// Internal: hit testing
	// ============================================================

	function hitTestRect(localX:Float, localY:Float):Null<CellCoord> {
		final stride = rectCellW + rectGap;
		final strideY = rectCellH + rectGap;

		final col = Math.floor(localX / stride);
		final row = Math.floor(localY / strideY);

		// Check if in the gap area
		final cellLocalX = localX - col * stride;
		final cellLocalY = localY - row * strideY;
		if (cellLocalX > rectCellW || cellLocalY > rectCellH)
			return null;

		final key = cellKey(col, row);
		return cells.exists(key) ? ({col: col, row: row} : CellCoord) : null;
	}

	function hitTestHex(localX:Float, localY:Float):Null<CellCoord> {
		final fractional = hexLayout.pixelToHex(new Point(localX, localY));
		final hex = fractional.round();
		final coord = fromHex(hex);
		final key = cellKey(coord.col, coord.row);
		return cells.exists(key) ? coord : null;
	}

	// ============================================================
	// Internal: hex coordinate helpers
	// ============================================================

	inline function toHex(col:Int, row:Int):HexUtil {
		return new HexUtil(col, row, -col - row);
	}

	inline function fromHex(hex:HexUtil):CellCoord {
		return {col: hex.q, row: hex.r};
	}

	// ============================================================
	// Internal: drag-drop zone management
	// ============================================================

	function createDropZonesForDraggable(binding:DraggableBinding):Void {
		for (_ => entry in cells) {
			final coord = entry.coord;
			final zoneId = GridCell(this, coord.col, coord.row);

			final cellBounds = computeCellBounds(coord);
			final snapPos = cellPosition(coord.col, coord.row);

			// Capture coord for closures
			final capturedCoord:CellCoord = {col: coord.col, row: coord.row};

			binding.draggable.addDropZone({
				id: zoneId,
				bounds: cellBounds,
				snapX: snapPos.x,
				snapY: snapPos.y,
				accepts: if (binding.accepts != null) (drag, zone) -> binding.accepts(capturedCoord, drag) else null,
				boundsProvider: () -> computeCellBounds(capturedCoord),
				snapProvider: () -> {
					final p = cellPosition(capturedCoord.col, capturedCoord.row);
					return new Point(p.x, p.y);
				},
				onZoneHighlight: (zone, highlight) -> {
					applyCellTargetFeedback(capturedCoord, highlight, Drag(binding.draggable));
				},
				onZoneReject: (zone, reject) -> {
					final e = cells.get(cellKey(capturedCoord.col, capturedCoord.row));
					if (e != null) {
						e.visual.setStatus(if (reject) "hover" else "normal");
					}
				},
			});
		}
	}

	function wireHighlightCallbacks(binding:DraggableBinding):Void {
		final prevStart = binding.draggable.onDragStartHighlightZones;
		binding.draggable.onDragStartHighlightZones = (zones) -> {
			if (prevStart != null)
				prevStart(zones);
			applyDragHighlights((coord) -> binding.accepts == null || binding.accepts(coord, binding.draggable));
		};

		final prevEnd = binding.draggable.onDragEndHighlightZones;
		binding.draggable.onDragEndHighlightZones = (zones) -> {
			if (prevEnd != null)
				prevEnd(zones);
			clearDragHighlights();
		};

		// Wire drop event to emit GridEvent with DropContext for animation control.
		// Chaining: if prevDrop handled it (returned true), skip this grid.
		// If prevDrop returned false (zone not for that grid), try this grid.
		final prevDrop = binding.draggable.onDragDrop;
		binding.draggable.onDragDrop = (result, wrapper) -> {
			if (prevDrop != null && prevDrop(result, wrapper))
				return true;

			if (result.zone != null) {
				final coord:Null<CellCoord> = switch result.zone.id {
					case GridCell(g, col, row) if (g == this): ({col: col, row: row} : CellCoord);
					default: null;
				};
				if (coord != null) {
					// Read source info from draggable fields (set by makeDraggableFromCell)
					final srcGrid:Null<UIMultiAnimGrid<T>> = Std.isOfType(binding.draggable.sourceGrid, UIMultiAnimGrid)
						? cast binding.draggable.sourceGrid
						: null;
					final srcCell:Null<CellCoord> = binding.draggable.sourceCellCoord;

					// Check for swap: swapEnabled + has source cell + swapAccepts (or default isOccupied)
					if (swapEnabled  && (swapAccepts != null ? swapAccepts(coord, binding.draggable) : isOccupied(coord.col, coord.row))) {
						return handleSwapDrop(binding, coord, srcGrid, srcCell);
					}

					final ctx = new DropContext();
					emitEvent(CellDrop(coord, binding.draggable, srcGrid, srcCell, ctx));

					// Handle rejection: if game called ctx.reject(), cancel the snap
					if (ctx.handled && !ctx.accepted) {
						// Save current return path factory, override if custom reject path provided
						if (ctx.pathName != null)
							binding.draggable.setReturnAnimPath(builder, ctx.pathName);
						// Wire onComplete into the cancel callback
						if (ctx.completeCb != null) {
							final onComplete = ctx.completeCb;
							final prevCancel = binding.draggable.onDragCancel;
							binding.draggable.onDragCancel = (pos, w) -> {
								// Restore original cancel handler
								binding.draggable.onDragCancel = prevCancel;
								if (prevCancel != null)
									prevCancel(pos, w);
								onComplete();
							};
						}
						return false; // Returning false causes draggable to treat as failed drop → return animation
					}

					// Accept path: override snap path if custom accept path provided
					if (ctx.handled && ctx.pathName != null)
						binding.draggable.setSnapAnimPath(builder, ctx.pathName);

					// Wire onComplete for accepted drops via DragSnapComplete event
					if (ctx.completeCb != null) {
						final onComplete = ctx.completeCb;
						final prevEvent = binding.draggable.onDragEvent;
						binding.draggable.onDragEvent = (event, pos, w) -> {
							if (prevEvent != null)
								prevEvent(event, pos, w);
							switch event {
								case DragSnapComplete | DragCancel:
									// Restore original event handler and fire completion
									binding.draggable.onDragEvent = prevEvent;
									onComplete();
								default:
							}
						};
					}

					return true;
				}
			}
			return false;
		};
	}

	/** Handle a drop-on-occupied-cell as a swap. Returns true if accepted (snap), false if rejected (return). */
	function handleSwapDrop(binding:DraggableBinding, targetCoord:CellCoord, srcGrid:Null<UIMultiAnimGrid<T>>,
			srcCell:CellCoord):Bool {
		final draggable = binding.draggable;
		final ctx = new SwapContext(false);
		emitEvent(CellSwap(srcCell, targetCoord, draggable, ctx));

		// Rejected — return draggable to origin
		if (ctx.handled && !ctx.accepted) {
			return false;
		}

		// Resolve which grid owns the source cell (could be cross-grid)
		final sourceGrid:UIMultiAnimGrid<T> = srcGrid != null ? srcGrid : this;

		// Resolve swap path: ctx override > config swapPathName > config returnPathName > null (instant)
		final resolvedSwapPath = if (ctx.swapPath != null) ctx.swapPath
			else if (swapPathName != null) swapPathName
			else returnPathName;

		// Override snap path if ctx provided one
		if (ctx.snapPath != null)
			draggable.setSnapAnimPath(builder, ctx.snapPath);

		// Snapshot current state before swapping data
		final targetEntry = cells.get(cellKey(targetCoord.col, targetCoord.row));
		if (targetEntry == null)
			return false;

		final displacedData = targetEntry.data;
		final dragPayload = draggable.payload;

		// Detach displaced item visual WITHOUT rebuilding — we control rebuild timing
		final detached = detachCellVisualRaw(targetCoord.col, targetCoord.row);

		// Swap data atomically: dragged data → target, displaced data → source
		set(targetCoord.col, targetCoord.row, dragPayload);
		sourceGrid.set(srcCell.col, srcCell.row, displacedData);

		// Rebuild target cell — it's behind the snapping draggable, so the user won't see it
		// until snap completes. Do NOT rebuild source cell — its visual should stay as-is
		// (the displaced animation covers it). Source is rebuilt when displaced anim completes
		// or via onSnapComplete/onComplete from the game.
		rebuildCell(targetCoord.col, targetCoord.row);

		// Track whether displaced animation is done (for coordinating onComplete with snap)
		var displacedDone = false;
		var snapDone = false;
		final onBothDone = () -> {
			if (displacedDone && snapDone && ctx.completeCb != null)
				ctx.completeCb();
		};

		// Animate displaced item to source cell
		if (detached != null && resolvedSwapPath != null) {
			final sourceScenePos = sourceGrid.cellPosition(srcCell.col, srcCell.row);
			animateSwapVisual(detached, targetCoord, sourceScenePos, resolvedSwapPath, () -> {
				sourceGrid.rebuildCell(srcCell.col, srcCell.row);
				displacedDone = true;
				onBothDone();
			});
		} else {
			// No animation — rebuild source cell immediately
			if (detached != null)
				detached.object.remove();
			sourceGrid.rebuildCell(srcCell.col, srcCell.row);
			displacedDone = true;
		}

		// Wire DragSnapComplete to clean up draggable visual.
		// Target cell is already rebuilt with correct data above.
		final prevEvent = draggable.onDragEvent;
		draggable.onDragEvent = (event, pos, w) -> {
			if (prevEvent != null)
				prevEvent(event, pos, w);
			switch event {
				case DragSnapComplete:
					draggable.onDragEvent = prevEvent;
					draggable.getObject().remove();
					if (ctx.snapCompleteCb != null)
						ctx.snapCompleteCb();
					snapDone = true;
					onBothDone();
				case DragCancel:
					draggable.onDragEvent = prevEvent;
					snapDone = true;
					onBothDone();
				default:
			}
		};

		return true; // Accept — draggable snaps to target
	}

	function clearZonesForBinding(binding:DraggableBinding):Void {
		for (_ => entry in cells) {
			binding.draggable.removeDropZone(GridCell(this, entry.coord.col, entry.coord.row));
		}
	}

	function refreshAllDraggableZones():Void {
		for (binding in registeredDraggables) {
			clearZonesForBinding(binding);
			createDropZonesForDraggable(binding);
		}
	}

	function computeCellBounds(coord:CellCoord):Bounds {
		final local = getCellLocalPosition(coord);
		final global = root.localToGlobal(new h2d.col.Point(local.x, local.y));
		return switch gridType {
			case Rect(w, h, _):
				Bounds.fromValues(global.x, global.y, w, h);
			case Hex(_, sx, sy):
				Bounds.fromValues(global.x - sx, global.y - sy, sx * 2, sy * 2);
		};
	}

	// ============================================================
	// Internal: card hand targeting
	// ============================================================

	function createCardTargetsForBinding(binding:CardHandBinding):Void {
		final prefix = binding.targetPrefix;
		for (_ => entry in cells) {
			final coord = entry.coord;
			final targetId = '${prefix}_${coord.col}_${coord.row}';
			final cellSize = getCellBoundingSize();

			// Create a synthetic MAObject with MAInteractive for the card hand system
			final interactive = new MAObject(MAInteractive(Math.ceil(cellSize.x), Math.ceil(cellSize.y), targetId, null), false);

			// Position interactive at cell top-left in local coordinates.
			// Rect: getCellLocalPosition already returns top-left, no offset needed.
			// Hex: getCellLocalPosition returns center, offset by half-size to get top-left.
			final localPos = getCellLocalPosition(coord);
			switch gridType {
				case Rect(_, _, _):
					interactive.setPosition(localPos.x, localPos.y);
				case Hex(_, _, _):
					interactive.setPosition(localPos.x - cellSize.x / 2, localPos.y - cellSize.y / 2);
			}
			root.add(interactive, 1000);

			final wrapper = new UIInteractiveWrapper(interactive, null);
			cardTargetInteractives.set(targetId, interactive);
			cardTargetWrappers.set(targetId, wrapper);

			binding.cardHand.registerTargetInteractive(wrapper);
		}

		// Wire accepts filter — chain with previous so multiple grids can coexist
		if (binding.accepts != null) {
			final accepts = binding.accepts;
			final prevAccepts = binding.cardHand.getTargeting().acceptsFilter;
			binding.cardHand.setTargetAcceptsFilter((cardId, targetId, meta) -> {
				final coord = parseCardTargetId(targetId);
				if (coord != null)
					return accepts(coord, cardId);
				return if (prevAccepts != null) prevAccepts(cardId, targetId, meta) else true;
			});
		}

		// Wire highlight callback — chain with previous and use shared feedback helper
		final prevHighlight = binding.cardHand.getTargeting().onTargetHighlight;
		binding.cardHand.setTargetHighlightCallback((targetId, highlight, meta) -> {
			if (prevHighlight != null)
				prevHighlight(targetId, highlight, meta);
			final coord = parseCardTargetId(targetId);
			if (coord != null)
				applyCellTargetFeedback(coord, highlight, Card(if (activeCardDragId != null) activeCardDragId else ""));
		});

		// Wire card drag events → highlight all valid targets on drag start
		final listener = (event:UICardHandTypes.CardHandEvent) -> {
			switch event {
				case CardPlayed(cardId, target):
					switch target {
						case TargetZone(targetId):
							final coord = parseCardTargetId(targetId);
							if (coord != null)
								emitEvent(CellCardPlayed(coord, cardId));
						default:
					}
				case CardDragStart(cardId):
					activeCardDragId = cardId;
					applyDragHighlights((coord) -> binding.accepts == null || binding.accepts(coord, cardId));
				case CardDragEnd(_):
					clearDragHighlights();
					activeCardDragId = null;
				default:
			}
		};
		binding.cardHand.chainedListeners.push(listener);
		binding.eventListener = listener;
	}

	function clearCardTargetsForBinding(binding:CardHandBinding):Void {
		final prefix = binding.targetPrefix + "_";
		final toRemove:Array<String> = [];
		for (targetId => _ in cardTargetInteractives) {
			if (StringTools.startsWith(targetId, prefix))
				toRemove.push(targetId);
		}
		for (targetId in toRemove) {
			final interactive = cardTargetInteractives.get(targetId);
			if (interactive != null)
				interactive.remove();
			binding.cardHand.unregisterTargetInteractive(targetId);
			cardTargetInteractives.remove(targetId);
			cardTargetWrappers.remove(targetId);
		}

		// Remove chained event listener
		if (binding.eventListener != null) {
			binding.cardHand.chainedListeners.remove(binding.eventListener);
			binding.eventListener = null;
		}
	}

	function refreshAllCardTargets():Void {
		for (binding in registeredCardHands) {
			clearCardTargetsForBinding(binding);
			createCardTargetsForBinding(binding);
		}
	}

	function getCellBoundingSize():FPoint {
		return switch gridType {
			case Rect(w, h, _): {x: w, y: h};
			case Hex(_, sx, sy): {x: sx * 2, y: sy * 2};
		};
	}

	function parseCardTargetId(targetId:String):Null<CellCoord> {
		// Target IDs have format: grid{cardTargetId}ch{N}_{col}_{row}
		// Match any binding's prefix by checking grid instance prefix
		final gridPrefix = 'grid${cardTargetId}ch';
		if (!StringTools.startsWith(targetId, gridPrefix))
			return null;
		// Find the col_row suffix: last two underscore-separated parts
		final parts = targetId.split("_");
		if (parts.length < 2)
			return null;
		final row = Std.parseInt(parts[parts.length - 1]);
		final col = Std.parseInt(parts[parts.length - 2]);
		if (col == null || row == null)
			return null;
		return {col: col, row: row};
	}

	// ============================================================
	// Internal: utility
	// ============================================================

	/** Place an object into the swap animation container for in-flight rendering.
	 *  Uses the configured swapAnimContainer if set, otherwise falls back to the grid's own root.
	 *  Returns the parent object (for coordinate conversion). */
	function reparentForSwapAnim(obj:h2d.Object):h2d.Object {
		if (swapAnimContainer != null) {
			swapAnimContainer.addChild(obj);
			return swapAnimContainer;
		} else {
			// Fallback: add to grid root at high z-order (above cells and layers)
			root.add(obj, 1000);
			return root;
		}
	}

	/** Convert a scene-space point into a parent object's local coordinate space. */
	function sceneToLocal(parent:h2d.Object, sceneX:Float, sceneY:Float):FPoint {
		final local = parent.globalToLocal(new h2d.col.Point(sceneX, sceneY));
		return new FPoint(local.x, local.y);
	}


	function emitEvent(event:GridEvent<T>):Void {
		if (onGridEvent != null)
			onGridEvent(event);
	}

	static function cellCoordsEqual(a:Null<CellCoord>, b:Null<CellCoord>):Bool {
		if (a == null && b == null)
			return true;
		if (a == null || b == null)
			return false;
		return a.col == b.col && a.row == b.row;
	}

	static inline function iabs(v:Int):Int {
		return v < 0 ? -v : v;
	}
}
