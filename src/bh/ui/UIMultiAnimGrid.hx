package bh.ui;

import bh.base.FPoint;
import bh.base.GridDirection;
import bh.base.Hex;
import bh.base.Hex.FractionalHex;
import bh.base.Hex.HexLayout;
import bh.base.Hex.HexOrientation;
import bh.base.MAObject;
import bh.base.MAObject.MultiAnimObjectData;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.BuilderResolvedSettings;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.paths.MultiAnimPaths.PathNormalization;
import bh.ui.UICardHandTypes;
import bh.ui.UIMultiAnimDraggable;
import bh.ui.UIMultiAnimGridTypes;
import h2d.col.Bounds;
import h2d.col.Point;

// Alias to avoid name shadowing with GridType.Hex enum constructor
private typedef HexUtil = bh.base.Hex.Hex;

/** Internal cell entry storing the built result and game data. */
private class CellEntry {
	public var coord:CellCoord;
	public var result:BuilderResult;
	public var data:Dynamic;
	public var buildName:String;

	public function new(coord:CellCoord, result:BuilderResult, data:Dynamic, buildName:String) {
		this.coord = coord;
		this.result = result;
		this.data = data;
		this.buildName = buildName;
	}
}

/** Internal binding for a registered draggable. */
private typedef DraggableBinding = {
	var draggable:UIMultiAnimDraggable;
	var accepts:Null<GridDropAccepts>;
	var zonePrefix:String;
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
 *     cellBuildName: "gridCell",
 *     originX: 100, originY: 100,
 * });
 * grid.addRectRegion(5, 4);
 * grid.onGridEvent = (event) -> switch event {
 *     case CellClick(cell, _): trace('clicked ${cell.col}, ${cell.row}');
 *     default:
 * };
 * ```
 */
class UIMultiAnimGrid {
	// --- Config ---
	final builder:MultiAnimBuilder;
	final gridType:GridType;
	final defaultBuildName:String;
	final cellBuildDelegate:Null<CellBuildDelegate>;
	final highlightParam:String;
	final statusParam:String;
	final snapPathName:Null<String>;
	final returnPathName:Null<String>;

	// --- Geometry ---
	final hexLayout:Null<HexLayout>;
	final rectCellW:Float;
	final rectCellH:Float;
	final rectGap:Float;

	// --- Scene graph ---
	final root:h2d.Object;

	// --- Cell storage: Map<"col_row", CellEntry> ---
	final cells:Map<String, CellEntry> = new Map();

	// --- Hover state ---
	var hoveredCell:Null<CellCoord> = null;

	// --- Drag-drop ---
	final registeredDraggables:Array<DraggableBinding> = [];
	var activeHighlightedCells:Array<CellCoord> = [];

	// --- Card hand ---
	final registeredCardHands:Array<CardHandBinding> = [];
	final cardTargetInteractives:Map<String, MAObject> = new Map();
	final cardTargetWrappers:Map<String, UIInteractiveWrapper> = new Map();

	// --- Instance counter for unique zone IDs ---
	static var instanceCounter:Int = 0;
	final instanceId:Int;
	var cardHandBindingCounter:Int = 0;

	// --- Callbacks ---

	/** Called when a grid event occurs (click, hover, drop, card play). */
	public var onGridEvent:Null<(event:GridEvent) -> Void> = null;

	/** Called after a cell is built. Use to customize the BuilderResult (add overlays, etc.). */
	public var onCellBuilt:Null<(coord:CellCoord, result:BuilderResult) -> Void> = null;

	// ============================================================
	// Construction
	// ============================================================

	public function new(builder:MultiAnimBuilder, config:GridConfig) {
		this.builder = builder;
		this.gridType = config.gridType;
		this.defaultBuildName = config.cellBuildName;
		this.cellBuildDelegate = config.cellBuildDelegate;
		this.highlightParam = config.highlightParam != null ? config.highlightParam : "highlight";
		this.statusParam = config.statusParam != null ? config.statusParam : "status";
		this.snapPathName = config.snapPathName;
		this.returnPathName = config.returnPathName;

		this.root = new h2d.Object();
		this.root.setPosition(config.originX != null ? config.originX : 0, config.originY != null ? config.originY : 0);

		this.instanceId = instanceCounter++;

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
	public function addCell(col:Int, row:Int, ?data:Dynamic, ?params:Map<String, Dynamic>):Void {
		final key = cellKey(col, row);
		if (cells.exists(key))
			return;

		final coord:CellCoord = {col: col, row: row};
		final entry = buildCell(coord, data, params);
		cells.set(key, entry);
		root.addChild(entry.result.object);
		positionCell(entry);

		if (onCellBuilt != null)
			onCellBuilt(coord, entry.result);

		refreshAllDraggableZones();
		refreshAllCardTargets();
	}

	/** Remove a cell at (col, row). */
	public function removeCell(col:Int, row:Int):Void {
		final key = cellKey(col, row);
		final entry = cells.get(key);
		if (entry == null)
			return;

		entry.result.object.remove();
		cells.remove(key);

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
	public function set(col:Int, row:Int, data:Dynamic, ?params:Map<String, Dynamic>):Void {
		final entry = getEntry(col, row);
		final oldData = entry.data;
		entry.data = data;

		if (params != null) {
			entry.result.beginUpdate();
			for (key => value in params)
				entry.result.setParameter(key, value);
			entry.result.endUpdate();
		}

		emitEvent(CellDataChanged(entry.coord, oldData, data));
	}

	/** Get cell data at (col, row). Returns null if cell is empty. */
	public function get(col:Int, row:Int):Dynamic {
		final entry = cells.get(cellKey(col, row));
		return entry != null ? entry.data : null;
	}

	/** Clear cell data and reset visual to default. */
	public function clear(col:Int, row:Int):Void {
		final entry = getEntry(col, row);
		final oldData = entry.data;
		entry.data = null;

		// Reset to defaults
		entry.result.beginUpdate();
		entry.result.setParameter(highlightParam, false);
		entry.result.setParameter(statusParam, "normal");
		entry.result.endUpdate();

		emitEvent(CellDataChanged(entry.coord, oldData, null));
	}

	/** Check if cell has non-null data. */
	public function isOccupied(col:Int, row:Int):Bool {
		final entry = cells.get(cellKey(col, row));
		return entry != null && entry.data != null;
	}

	/** Iterate all cells. Callback receives (col, row, data) — data may be null. */
	public function forEach(fn:(col:Int, row:Int, data:Dynamic) -> Void):Void {
		for (_ => entry in cells)
			fn(entry.coord.col, entry.coord.row, entry.data);
	}

	// ============================================================
	// Cell visual params
	// ============================================================

	/** Set a single parameter on the cell's BuilderResult. */
	public function setCellParameter(col:Int, row:Int, param:String, value:Dynamic):Void {
		final entry = getEntry(col, row);
		entry.result.setParameter(param, value);
	}

	/** Set multiple parameters on the cell's BuilderResult (batched). */
	public function setCellParameters(col:Int, row:Int, params:Map<String, Dynamic>):Void {
		final entry = getEntry(col, row);
		entry.result.beginUpdate();
		for (key => value in params)
			entry.result.setParameter(key, value);
		entry.result.endUpdate();
	}

	/** Get the raw BuilderResult for a cell (for advanced customization). */
	public function getCellResult(col:Int, row:Int):Null<BuilderResult> {
		final entry = cells.get(cellKey(col, row));
		return entry != null ? entry.result : null;
	}

	/** Fully rebuild a cell (e.g., when the delegate returns a different programmable). */
	public function rebuildCell(col:Int, row:Int):Void {
		final key = cellKey(col, row);
		final oldEntry = cells.get(key);
		if (oldEntry == null)
			throw 'Cell ($col, $row) does not exist';

		oldEntry.result.object.remove();

		final newEntry = buildCell(oldEntry.coord, oldEntry.data, null);
		cells.set(key, newEntry);
		root.addChild(newEntry.result.object);
		positionCell(newEntry);

		if (onCellBuilt != null)
			onCellBuilt(newEntry.coord, newEntry.result);

		refreshAllDraggableZones();
		refreshAllCardTargets();
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
	public function cellCount():Int {
		var count = 0;
		for (_ in cells)
			count++;
		return count;
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
					entry.result.setParameter(statusParam, "normal");
				emitEvent(CellHoverLeave(hoveredCell));
			}
			hoveredCell = hit;
			if (hoveredCell != null) {
				final entry = cells.get(cellKey(hoveredCell.col, hoveredCell.row));
				if (entry != null)
					entry.result.setParameter(statusParam, "hover");
				emitEvent(CellHoverEnter(hoveredCell));
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
			zonePrefix: 'grid${instanceId}',
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
	 *  Tracks source grid+cell. On successful drop elsewhere, source auto-clears.
	 *  On cancel, returns to source cell. */
	public function makeDraggableFromCell(col:Int, row:Int, ?visualOverride:h2d.Object):UIMultiAnimDraggable {
		final entry = getEntry(col, row);
		final target = visualOverride != null ? visualOverride : entry.result.object;

		final drag = UIMultiAnimDraggable.create(target);
		drag.returnToOrigin = true;

		if (snapPathName != null)
			drag.setSnapAnimPath(builder, snapPathName);
		if (returnPathName != null)
			drag.setReturnAnimPath(builder, returnPathName);

		// Store source info for CellDrop event
		final sourceGrid = this;
		final sourceCell:CellCoord = {col: col, row: row};

		// Wire drop callback to emit CellDrop with source info
		final prevDrop = drag.onDragDrop;
		drag.onDragDrop = (result, wrapper) -> {
			if (prevDrop != null && !prevDrop(result, wrapper))
				return false;
			// Source clearing is handled by the receiving grid's CellDrop event handler
			return true;
		};

		return drag;
	}

	// ============================================================
	// Card hand targeting
	// ============================================================

	/** Register this grid's cells as card play targets.
	 *  Creates UIInteractiveWrapper per cell for the card hand's targeting system. */
	public function registerAsCardTarget(cardHand:UICardHandHelper, ?accepts:GridCardAccepts):Void {
		final binding:CardHandBinding = {
			cardHand: cardHand,
			accepts: accepts,
			targetPrefix: 'grid${instanceId}ch${cardHandBindingCounter++}',
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

	/** Get the root scene graph object. Add to scene via addObjectToLayer(grid.getObject(), layer). */
	public function getObject():h2d.Object {
		return root;
	}

	/** Update — call from game loop if using animations. */
	public function update(dt:Float):Void {
		// Reserved for future animation support
	}

	/** Clean up all resources. */
	public function dispose():Void {
		// Clear all drag bindings
		for (binding in registeredDraggables)
			clearZonesForBinding(binding);
		registeredDraggables.resize(0);

		// Clear all card hand bindings
		for (binding in registeredCardHands)
			clearCardTargetsForBinding(binding);
		registeredCardHands.resize(0);

		// Remove scene graph
		root.remove();
		cells.clear();
		hoveredCell = null;
	}

	// ============================================================
	// Internal: cell key
	// ============================================================

	inline function cellKey(col:Int, row:Int):String {
		return '${col}_${row}';
	}

	function getEntry(col:Int, row:Int):CellEntry {
		final entry = cells.get(cellKey(col, row));
		if (entry == null)
			throw 'Cell ($col, $row) does not exist';
		return entry;
	}

	// ============================================================
	// Internal: cell building
	// ============================================================

	function buildCell(coord:CellCoord, data:Dynamic, ?extraParams:Map<String, Dynamic>):CellEntry {
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
		params.set(highlightParam, false);
		params.set(statusParam, "normal");

		// Apply delegate params
		if (delegateParams != null)
			for (key => value in delegateParams)
				params.set(key, value);

		// Apply extra params (from addCell/set)
		if (extraParams != null)
			for (key => value in extraParams)
				params.set(key, value);

		final result = builder.buildWithParameters(buildName, params, null, null, true);
		return new CellEntry(coord, result, data, buildName);
	}

	function positionCell(entry:CellEntry):Void {
		switch gridType {
			case Rect(w, h, gap):
				final g = gap != null ? gap : 0.0;
				entry.result.object.setPosition(entry.coord.col * (w + g), entry.coord.row * (h + g));
			case Hex(_, _, _):
				final hex = toHex(entry.coord.col, entry.coord.row);
				final p = hexLayout.hexToPixel(hex);
				entry.result.object.setPosition(p.x, p.y);
		}
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
	function addCellInternal(col:Int, row:Int, data:Dynamic, params:Null<Map<String, Dynamic>>):Void {
		final key = cellKey(col, row);
		if (cells.exists(key))
			return;

		final coord:CellCoord = {col: col, row: row};
		final entry = buildCell(coord, data, params);
		cells.set(key, entry);
		root.addChild(entry.result.object);
		positionCell(entry);

		if (onCellBuilt != null)
			onCellBuilt(coord, entry.result);
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
			final zoneId = '${binding.zonePrefix}_${coord.col}_${coord.row}';

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
					final e = cells.get(cellKey(capturedCoord.col, capturedCoord.row));
					if (e != null)
						e.result.setParameter(highlightParam, highlight);
				},
			});
		}
	}

	function wireHighlightCallbacks(binding:DraggableBinding):Void {
		final prevStart = binding.draggable.onDragStartHighlightZones;
		binding.draggable.onDragStartHighlightZones = (zones) -> {
			if (prevStart != null)
				prevStart(zones);
			// Highlight all accepting cells
			for (_ => entry in cells) {
				final accepts = binding.accepts == null || binding.accepts(entry.coord, binding.draggable);
				if (accepts) {
					entry.result.setParameter(highlightParam, true);
					activeHighlightedCells.push({col: entry.coord.col, row: entry.coord.row});
				}
			}
		};

		final prevEnd = binding.draggable.onDragEndHighlightZones;
		binding.draggable.onDragEndHighlightZones = (zones) -> {
			if (prevEnd != null)
				prevEnd(zones);
			// Clear all highlights
			for (cell in activeHighlightedCells) {
				final e = cells.get(cellKey(cell.col, cell.row));
				if (e != null)
					e.result.setParameter(highlightParam, false);
			}
			activeHighlightedCells = [];
		};

		// Wire drop event to emit GridEvent
		// Chaining: if prevDrop handled it (returned true), skip this grid.
		// If prevDrop returned false (zone not for that grid), try this grid.
		final prevDrop = binding.draggable.onDragDrop;
		binding.draggable.onDragDrop = (result, wrapper) -> {
			if (prevDrop != null && prevDrop(result, wrapper))
				return true;

			if (result.zone != null) {
				final coord = parseZoneId(result.zone.id, binding.zonePrefix);
				if (coord != null) {
					emitEvent(CellDrop(coord, binding.draggable, null, null));
					return true;
				}
			}
			return false;
		};
	}

	function clearZonesForBinding(binding:DraggableBinding):Void {
		final prefix = binding.zonePrefix;
		// Remove all zones matching our prefix
		for (_ => entry in cells) {
			final zoneId = '${prefix}_${entry.coord.col}_${entry.coord.row}';
			binding.draggable.removeDropZone(zoneId);
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

	function parseZoneId(zoneId:String, prefix:String):Null<CellCoord> {
		if (!StringTools.startsWith(zoneId, prefix + "_"))
			return null;
		final rest = zoneId.substr(prefix.length + 1);
		final parts = rest.split("_");
		if (parts.length != 2)
			return null;
		final col = Std.parseInt(parts[0]);
		final row = Std.parseInt(parts[1]);
		if (col == null || row == null)
			return null;
		return {col: col, row: row};
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
			root.addChild(interactive);

			final wrapper = new UIInteractiveWrapper(interactive, null);
			cardTargetInteractives.set(targetId, interactive);
			cardTargetWrappers.set(targetId, wrapper);

			binding.cardHand.registerTargetInteractive(wrapper);
		}

		// Wire accepts filter
		if (binding.accepts != null) {
			final accepts = binding.accepts;
			binding.cardHand.setTargetAcceptsFilter((cardId, targetId, meta) -> {
				final coord = parseCardTargetId(targetId);
				if (coord == null)
					return true; // Not our target, don't block
				return accepts(coord, cardId);
			});
		}

		// Wire highlight callback
		binding.cardHand.setTargetHighlightCallback((targetId, highlight, meta) -> {
			final coord = parseCardTargetId(targetId);
			if (coord != null) {
				final e = cells.get(cellKey(coord.col, coord.row));
				if (e != null)
					e.result.setParameter(highlightParam, highlight);
			}
		});

		// Wire card played event → CellCardPlayed conversion
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
		// Target IDs have format: grid{instanceId}ch{N}_{col}_{row}
		// Match any binding's prefix by checking grid instance prefix
		final gridPrefix = 'grid${instanceId}ch';
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

	function emitEvent(event:GridEvent):Void {
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
