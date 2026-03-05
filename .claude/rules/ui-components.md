# UI Components Reference

## UI Elements Notes

- **Generic settings pass-through**: Any setting not recognized as control or behavioral is automatically forwarded to the underlying programmable as an extra parameter. The programmable must declare a matching parameter; mismatches throw with programmable name + available params.
- **Prefixed settings**: `item.fontColor`, `scrollbar.thickness` — dotted keys route to sub-builders in multi-programmable components (dropdown, scrollableList). Registered prefixes: dropdown has `dropdown`, `item`, `scrollbar` (main=panel); scrollableList has `item`, `scrollbar` (main=panel).
- **Multi-forward settings**: Unprefixed `font`/`fontColor` on dropdown/scrollableList forward to ALL relevant sub-builders for backwards compatibility.
- **Button**: `buildName` and `text` are control settings; everything else (e.g. `width`, `height`, `font`, `fontColor`) passes through to `#button` programmable. Uses incremental `BuilderResult` with `setParameter("status", ...)` for state changes.
- **Checkbox**: Same incremental approach as button; uses `beginUpdate()`/`endUpdate()` when toggling both `status` and `checked` parameters.
- **TabButton**: Same incremental approach; `selected`/`disabled` via `setParameter("checked"/"disabled", ...)`.
- **Scrollable list / Dropdown**: `font`, `fontColor` forwarded to both item builder and dropdown button builder. The `#dropdown` programmable accepts `font`/`fontColor` params for the selected item text.
- **Settings `color` type**: `fontColor:color=>white` — parsed via `parseColorOrReference()`, stored as `SVTColor`/`RSVColor`. Supports named colors (`white`, `red`, `transparent`, etc.), hex (`#RGB`, `#RRGGBB`, `#RRGGBBAA`), and native Heaps format (`0xAARRGGBB`). `SettingValueTools.asColorInt()` helper matches both `RSVColor` and `RSVInt` for backward compatibility.
- **Dropdown**: Uses incremental `BuilderResult` with `setParameter("status", ...)` and `setParameter("panel", "open"/"closed")`. Scrollable panel moves to different layer.
- **UIScreen**: If elements don't show or react to events, check if added to UIScreen's elements
- **Macros**: `MacroUtils.macroBuildWithParameters` maps `.manim` elements to Haxe code — auto-injects `ResolvedSettings` parameter
- **Settings naming**: `buildName` for single builder override, `<element>BuildName` for multiple (e.g. `radioBuildName`, `radioButtonBuildName`)
- **Slider**: Supports custom float range (`min`, `max`, `step` settings). Internally maps to 0-100 grid. Implements both `UIElementNumberValue` (int) and `UIElementFloatValue` (float). Uses incremental mode for efficient redraws. Emits both `UIChangeValue(Int)` and `UIChangeFloatValue(Float)`.
- **Progress bar**: Display-only component (`UIMultiAnimProgressBar`). Uses full rebuild (not incremental) because `bitmap(generated(color(...)))` is not tracked. Screen helper: `addProgressBar(builder, settings, initialValue)`.
- **Scrollable list scrollbar**: Built with incremental mode — scroll events use `setParameter("scrollPosition", ...)` instead of full rebuild.
- **Scrollable list items**: Items built with incremental `BuilderResult` — state changes (`status`, `selected`, `disabled`) use `setParameter()` directly instead of pre-built combos.
- **Scrollable list runtime API**: `setItems(newItems, ?selectedIndex)` replaces content at runtime; `scrollToIndex(idx)` scrolls to make item visible; `clickMode` (`SingleClick`/`DoubleClick`) controls action event; `disabled` dims list (alpha 0.5) and shows selected in disabled variant. Events: `UIClickItem` (single-click mode), `UIDoubleClickItem` (double-click mode). Setting: `clickMode => "single"` or `"double"`.
- **List item tiles**: `UIElementListItem.tileRef` uses `TileRef` enum (`TRFile`, `TRSheet`, `TRSheetIndex`, `TRTile`, `TRGeneratedRect`, `TRGeneratedRectColor`) for structured tile references. Legacy `tileName` (plain string) still works. `TileHelper` class provides static helpers for builder params: `TileHelper.sheet("atlas", "tile")`, `TileHelper.file("img.png")`, `TileHelper.generatedRect(w, h)`, `TileHelper.generatedRectColor(w, h, color)`.
- **`tile` parameter type**: `.manim` `name:tile` declares a tile parameter (no default allowed). Use with `bitmap($name)`. In codegen maps to `Dynamic` (pass `h2d.Tile`). In builder pass via `TileHelper`.
- **Full component reference**: See `docs/manim.md` "UI Components" section for all parameter contracts, settings, and events
- **Tabs**: `UIMultiAnimTabs` — tab bar with per-tab content management via `beginTab()`/`endTab()`. Uses `ContentTarget` interface for screen element routing. Settings: `buildName` (tabBar), `tabButtonBuildName` (tab), `tabButton.*` (prefixed to buttons), `tabPanel.width`/`tabPanel.height` (panel size), `tabPanel.contentRoot` (behavioral — enables relative coordinate mode by naming a `#point` element in the tabBar programmable). In relative mode, each tab gets its own `h2d.Layers` at the named element's position, so screen layers work within the panel. Events: `UIChangeItem(index, items)`.
- **Text input**: `UIMultiAnimTextInput` wraps `h2d.TextInput` inside a `.manim` programmable frame. Requires programmable with `status:[normal,hover,focused,disabled]=normal`, `placeholder:bool=true`, and `#textArea point`. Settings: `buildName`, `font`, `fontColor`, `cursorColor`, `selectionColor`, `text`, `placeholder`, `maxLength`, `multiline`, `readOnly`, `disabled`, `filter` (`numeric`/`alphanumeric`/`none`), `inputWidth`, `tabIndex`. `TextInputFilter` enum: `FNumericOnly`, `FAlphanumeric`, `FCustom(fn)`. Screen helper: `addTextInput(builder, settings, ?initialText)`. Events: `UITextChange(text)`, `UITextSubmit(text)`, `UIFocusChange(focused)`. `textInput.insertTabs = null` so Tab is not consumed. Enter-advance deferred to `update(dt)` to avoid Heaps event conflicts.
- **Tab navigation**: `UITabGroup` — Tab/Shift+Tab cycling between `UIMultiAnimTextInput` elements. `enableTabNavigation(mode:TabWireMode = Autowire)` creates tab group; `Autowire` mode handles Tab key automatically in `onKey()`. `tabIndex` setting for explicit ordering (auto-assigned if omitted). `enterAdvances:Bool` flag advances focus on Enter. `advanceFrom(source)` for deferred enter-advance. Duplicate `tabIndex` values throw. Skips disabled inputs.

## Interactives

`interactive()` elements create hit-test regions with optional typed metadata:

```manim
interactive(200, 30, "myBtn")
interactive(200, 30, "myBtn", debug)
interactive(200, 30, "myBtn", action => "buy", label => "Buy Item")
interactive(200, 30, $idx, price:int => 100, weight:float => 1.5, action => "craft")
```

Metadata supports typed values matching the settings system: `key => val` (string default), `key:int => N`, `key:float => N`, `key:string => "s"`, `key:bool => true`, `key:color => #RGB`. Untyped `key => true`/`key => false` auto-infers bool type. Keys and values can be `$references`. Access: `metadata.has(key)`, `metadata.getStringOrDefault(key, default)`, `metadata.getIntOrDefault(key, default)`, `metadata.getBoolOrDefault(key, default)`, etc.

**UI integration:**
- `UIInteractiveWrapper` — thin wrapper implementing `UIElement`, `StandardUIElementEvents`, `UIElementIdentifiable`
- `UIElementIdentifiable` — opt-in interface with `id`, `prefix`, `metadata:BuilderResolvedSettings`
- Screen methods: `addInteractive()`, `addInteractives(result, prefix)`, `removeInteractives(prefix)`, `getInteractive(id)` (O(1) map lookup), `getInteractivesByPrefix(prefix)`
- Events: emits `UIInteractiveEvent(event, id, metadata)` — pattern match in `onScreenEvent`:
  ```haxe
  case UIInteractiveEvent(UIClick, id, meta): // clicked interactive
  case UIInteractiveEvent(UIEntering, id, meta): // hover enter
  case UIInteractiveEvent(UILeaving, id, meta): // hover leave
  case UIInteractiveEvent(UIPush, id, meta): // mouse down
  case UIInteractiveEvent(UIClickOutside, id, meta): // clicked outside
  ```
- **Event filtering**: `events: [hover, click, push]` metadata controls which events are emitted. `EVENT_HOVER=1`, `EVENT_CLICK=2`, `EVENT_PUSH=4`, `EVENT_ALL=7` (default)
- **Bind metadata**: `bind => "status"` declares which programmable parameter the interactive drives for `UIRichInteractiveHelper` auto-wiring
- **`UIRichInteractiveHelper`** — state binding helper: `register(result, ?prefix)` auto-scans bind metadata; `handleEvent(event)` drives Normal→Hover→Pressed→Normal state machine via `setParameter()`; `setDisabled(id, disabled)` for disabled state; `bind()`/`unbind()`/`setParameter()`/`getResult()` for manual control
- **`UITooltipHelper`** — screen-driven tooltip helper: `startHover(id, buildName, ?params)`, `cancelHover(id)`, `show()`, `hide()`, `update(dt)`; configurable delay, position, offset, layer; per-interactive overrides: `setDelay()`, `setPosition()`, `setOffset()`; `updateParams(params)` for incremental parameter update on active tooltip; `rebuild(?params)` for full rebuild with new or original params
- **`UIPanelHelper`** — screen-driven panel helper: `open(id, buildName, ?params)`, `close()`, `isOpen()`, `getPanelResult()`, `handleOutsideClick(event)`; auto-registers panel interactives with prefix; `OutsideClick` / `Manual` close modes; per-interactive overrides: `setPosition()`, `setOffset()`; pushes `UICustomEvent(EVENT_PANEL_CLOSE, interactiveId)` on close; multi-panel support via named slots: `openNamed(slot, ...)`, `closeNamed(slot)`, `closeAllNamed()`, `isOpenNamed(slot)`, `getNamedPanelResult(slot)`
- **Cursor support** — `UIElementCursor` interface with `getCursor():hxd.Cursor` for state-dependent cursor
  - `CursorManager` — static registry (like `FontManager`); pre-registers Heaps cursors: `default`, `pointer`/`button`, `move`, `text`, `hide`/`none`
  - `registerCursor(name, cursor)` / `unregisterCursor(name)` / `getCursor(name)` for custom cursors
  - `setDefaultInteractiveCursor(cursor)` — global default for UI elements (defaults to `Button`/pointer)
  - `setDefaultCursor(cursor)` — fallback when not hovering any element (defaults to `Default`)
  - All built-in components (Button, Checkbox, Slider, Dropdown, TabButton, ScrollableList) implement `UIElementCursor`
  - Interactive per-state cursors via metadata: `cursor => "pointer"`, `cursor.hover => "move"`, `cursor.disabled => "default"`
  - Unknown `cursor.*` suffixes throw (valid: `cursor.hover`, `cursor.disabled`)
  - Controller plumbing in `UIControllerBase.handleMove()` — calls `hxd.System.setCursor()`

## Indexed Names, Slots, Components

**Indexed named elements** — `#name[$i]` inside `repeatable` creates per-iteration named entries (`name_0`, `name_1`, ...):
- Builder: `result.getUpdatableByIndex("name", index)`
- Codegen: `instance.get_name(index)` returns `h2d.Object`

**Slots** — `#name slot` or `#name[$i] slot` for swappable containers:
- Builder: `result.getSlot("name")` or `result.getSlot("name", index)` returns `SlotHandle`
- Codegen: `instance.getSlot("name")` or `instance.getSlot("name", index)`
- `SlotHandle` API: `setContent(obj)`, `clear()`, `getContent()`, `isEmpty()`, `isOccupied()`, `data` (arbitrary payload)
- Mismatched access (index on non-indexed or vice versa) throws

**Parameterized slots** — `#name slot(param:type=default, ...)` for visual state management:
- Same parameter types as `programmable()`: `uint`, `int`, `float`, `bool`, `string`, `color`, enum, range, flags
- Conditionals (`@()`, `@else`, `@default`) and expressions (`$param`) work inside the slot body
- `SlotHandle.setParameter("name", value)` updates visuals via `IncrementalUpdateContext`
- Content goes into a separate `contentRoot` (decoration always visible, not hidden by `setContent`)
- Codegen: `setParameter()` supported — parameterized slots built via `buildParameterizedSlot()` at runtime with full incremental support

**Drag-and-drop** — `UIMultiAnimDraggable` with slot integration:
- `addDropZonesFromSlots("baseName", builderResult, ?accepts)` — batch drop zone creation
- `createFromSlot(slot)` — creates draggable from slot content, tracks `sourceSlot`
- `swapMode` — swaps contents when dropping onto an occupied slot
- Zone highlight callbacks: `onDragStartHighlightZones`, `onDragEndHighlightZones` on draggable
- Per-zone: `DropZone.onZoneHighlight` callback for hover state

## Grid Component

`UIMultiAnimGrid` — 2D grid component (rectangular or hexagonal) that manages cell state, rendering via `.manim` programmables, drag-drop integration, and card hand targeting. Follows the helper/manager pattern (like `UICardHandHelper`).

**Files:**
- `src/bh/ui/UIMultiAnimGrid.hx` — main component
- `src/bh/ui/UIMultiAnimGridTypes.hx` — types: `GridType`, `GridEvent`, `GridConfig`, `CellCoord`, delegates

**Construction:**
```haxe
var grid = new UIMultiAnimGrid(builder, {
    gridType: Rect(50, 50, 4),      // Rect(cellWidth, cellHeight, ?gap) or Hex(orientation, sizeX, sizeY)
    cellBuildName: "gridCell",       // .manim programmable name for cells
    cellBuildDelegate: null,         // optional per-cell override (buildName + params)
    originX: 0, originY: 0,         // grid root position
    snapPathName: "snapAnim",       // animatedPath for drop snap (null = instant)
    returnPathName: "returnAnim",   // animatedPath for drag cancel return (null = instant)
    highlightParam: "highlight",    // cell param for drag highlight state (default: "highlight")
    statusParam: "status",          // cell param for hover status (default: "status")
});
```

**Cell programmable contract:** Must have parameters matching `highlightParam` (bool) and `statusParam` (enum with "normal"/"hover"). Receives `col:int` and `row:int` automatically.

**GridType enum:**
- `Rect(cellWidth:Float, cellHeight:Float, ?gap:Float)` — rectangular grid
- `Hex(orientation:HexOrientation, sizeX:Float, sizeY:Float)` — hexagonal grid (POINTY or FLAT)

**Cell structure API:**
- `addCell(col, row, ?data, ?params)` — add single cell
- `removeCell(col, row)` — remove cell
- `hasCell(col, row)` — check existence
- `cellCount()` — total cells
- `addRectRegion(cols, rows)` — batch add 0..cols-1, 0..rows-1
- `addHexRegion(centerCol, centerRow, radius)` — batch add hex ring (radius 1 = 7 cells, radius 2 = 19 cells)

**Cell data API:**
- `set(col, row, data, ?params)` — set data + optional visual params
- `get(col, row)` — get data (null if empty)
- `clear(col, row)` — clear data, reset visuals to defaults
- `isOccupied(col, row)` — check if data is non-null
- `forEach((col, row, data) -> Void)` — iterate all cells
- `setCellParameter(col, row, param, value)` — set single visual param
- `setCellParameters(col, row, params)` — batch set visual params
- `getCellResult(col, row)` — get raw `BuilderResult` for advanced customization
- `rebuildCell(col, row)` — full rebuild (e.g. when delegate returns different programmable)

**Coordinate queries:**
- `cellAtPoint(sceneX, sceneY)` — hit-test which cell is at scene coords (uses `globalToLocal`)
- `cellPosition(col, row)` — world (scene) position of cell origin
- `neighbors(col, row)` — existing neighbor cells (rect: 4-dir, hex: 6-dir)
- `distance(c1, r1, c2, r2)` — grid distance (rect: Manhattan, hex: hex distance)

**Mouse event routing** — call from screen overrides:
- `onMouseMove(sceneX, sceneY)` — handles hover enter/leave, returns true if over a cell
- `onMouseClick(sceneX, sceneY, button)` — emits `CellClick`, returns true if cell clicked

**GridEvent enum** (via `onGridEvent` callback):
- `CellClick(cell, button)` — cell was clicked
- `CellHoverEnter(cell)` / `CellHoverLeave(cell)` — hover state changes
- `CellDrop(cell, draggable, sourceGrid, sourceCell)` — draggable dropped on cell
- `CellCardPlayed(cell, cardId)` — card played on cell (from card hand targeting)
- `CellDataChanged(cell, oldData, newData)` — data changed via `set()` or `clear()`

**Drag-drop integration:**
- `acceptDrops(draggable, ?accepts)` — register a `UIMultiAnimDraggable` to drop onto this grid's cells. Auto-creates `DropZone` per cell, manages highlight state. `accepts: (cell, draggable) -> Bool` filters valid targets
- `removeDrops(draggable)` — unregister draggable
- `makeDraggableFromCell(col, row, ?visualOverride)` — create draggable from cell content with source tracking

**Card hand integration:**
- `registerAsCardTarget(cardHand, ?accepts)` — register grid cells as card play targets. Creates synthetic `UIInteractiveWrapper` per cell for the card hand's targeting system. `accepts: (cell, cardId) -> Bool` filters valid targets
- `unregisterAsCardTarget(cardHand)` — unregister

**Lifecycle:**
- `getObject()` — root `h2d.Object`, add to scene via `addObjectToLayer(grid.getObject(), layer)`
- `update(dt)` — reserved for future animation support
- `dispose()` — clean up all resources, zones, and scene graph

**Callbacks:**
- `onGridEvent:(GridEvent) -> Void` — main event callback
- `onCellBuilt:(CellCoord, BuilderResult) -> Void` — called after each cell build (customize overlays etc.)

**Cross-grid drag pattern:**
```haxe
// Both grids accept drops from the same draggable
storageGrid.acceptDrops(drag, (cell, _) -> !storageGrid.isOccupied(cell.col, cell.row));
loadoutGrid.acceptDrops(drag, (cell, _) -> !loadoutGrid.isOccupied(cell.col, cell.row));

// In DragStart callback: clear source, store source info
drag.onDragEvent = (event, _, _) -> switch event {
    case DragStart: srcGrid.clear(srcCol, srcRow);
    case DragCancel: srcGrid.set(srcCol, srcRow, data); // restore on cancel
    default:
};

// In onGridEvent CellDrop: set data on target, rebuild draggables
```

**Card targeting wiring pattern:**
```haxe
hexGrid.registerAsCardTarget(cardHand, (cell, cardId) -> !hexGrid.isOccupied(cell.col, cell.row));

// In screen: route mouse events, check card hand first
override public function onMouseMove(pos) {
    if (cardHand.onMouseMove(pos.x, pos.y)) return false; // card hand consumes during drag
    hexGrid.onMouseMove(pos.x, pos.y);
    return super.onMouseMove(pos);
}
override public function onMouseClick(pos, button, release) {
    if (release && cardHand.onMouseRelease(pos.x, pos.y)) return false;
    if (release) hexGrid.onMouseClick(pos.x, pos.y, button);
    return super.onMouseClick(pos, button, release);
}
```

**Dynamic refs** — `dynamicRef($ref, params)` embeds with incremental mode for runtime parameter updates:
- Builder: `result.getDynamicRef("name").setParameter("param", value)`
- Batch updates: `beginUpdate()` / `endUpdate()` defers re-evaluation
- Codegen: generates runtime builder call, returns `BuilderResult`

**Flow improvements** — new optional params on `flow()`:
- `overflow: expand|limit|scroll|hidden`, `fillWidth: true`, `fillHeight: true`, `reverse: true`
- `horizontalAlign: left|right|middle`, `verticalAlign: top|bottom|middle` — default child alignment
- `spacer(w, h)` element for fixed spacing inside flows
- Per-element flow properties via `@flow.*` prefix on children:
  - `@flow.halign(left|right|middle)`, `@flow.valign(top|bottom|middle)` — per-child alignment override
  - `@flow.offset(x, y)` — pixel offset, `@flow.absolute` — remove from layout (overlays)
  - Parse-time validation: must be inside a flow ancestor (REPEAT/REPEAT2D are transparent)
  - `NodeFlowProperties` typedef on `Node` — single nullable struct, created via `NodeFlowPropertiesTools.create()`
