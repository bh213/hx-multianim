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
- **Scrollable list custom item params**: `UIElementListItem.params:Map<String, Dynamic>` passes arbitrary parameters to the item `.manim` template. Merged after built-in params (`title`, `status`, etc.) in `buildItem()`. The item programmable must declare matching parameters.
- **Scrollable list per-item base status**: `UIElementListItem.baseStatus:String` defines the resting visual status (e.g. `"active"`, `"completed"`). Used as initial `status` in `buildItem()` and as reset target after hover/press ends. Falls back to `"disabled"` if `item.disabled`, then `"normal"`.
- **Scrollable list runtime API**: `setItems(newItems, ?selectedIndex, ?preserveScroll)` replaces content at runtime (force-applies selection visual even if index unchanged); `scrollToIndex(idx)` scrolls to make item visible; `scrollToAndSelect(idx)` combines scroll + select; `clickMode` (`SingleClick`/`DoubleClick`) controls action event; `disabled` dims list (alpha 0.5) and shows selected in disabled variant. Events: `UIClickItem` (single-click mode), `UIDoubleClickItem` (double-click mode). Setting: `clickMode => "single"` or `"double"`.
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
  case UIInteractiveEvent(UIEntering(_), id, meta): // hover enter
  case UIInteractiveEvent(UILeaving, id, meta): // hover leave
  case UIInteractiveEvent(UIPush, id, meta): // mouse down
  case UIInteractiveEvent(UIClickOutside, id, meta): // clicked outside
  ```
- **Event filtering**: `events: [hover, click, push]` metadata controls which events are emitted. `EVENT_HOVER=1`, `EVENT_CLICK=2`, `EVENT_PUSH=4`, `EVENT_ALL=7` (default)
- **autoStatus metadata**: `autoStatus => "status"` auto-wires Normal→Hover→Pressed state machine at screen level. `addInteractives()` detects it, creates internal `UIRichInteractiveHelper`, and handles events automatically via `dispatchScreenEvent()`. Advanced: `screen.getAutoInteractiveHelper()` for `setDisabled()`, `setParameter()`, etc.
- **Bind metadata**: `bind => "status"` for manual wiring with a custom `UIRichInteractiveHelper` (e.g., `UICardHandHelper`). Cannot coexist with `autoStatus` on the same interactive.
- **`UIRichInteractiveHelper`** — state binding helper: `register(result, ?prefix, metadataKey)` scans for given metadata key (default: `"bind"`); `handleEvent(event)` drives Normal→Hover→Pressed→Normal state machine via `setParameter()`; `setDisabled(id, disabled)` for disabled state; `hasBinding(id)`, `unregisterByPrefix(prefix)`, `bind()`/`unbind()`/`setParameter()`/`getResult()` for manual control. Key `"autoStatus"` is reserved for screen auto-wiring.
- **`UITooltipHelper`** — screen-driven tooltip helper: `startHover(id, buildName, ?params)`, `cancelHover(id)`, `show()`, `hide()`, `update(dt)`; configurable delay, position, offset, layer; per-interactive overrides: `setDelay()`, `setPosition()`, `setOffset()`; `updateParams(params)` for incremental parameter update on active tooltip; `rebuild(?params)` for full rebuild with new or original params
- **`UIPanelHelper`** — screen-driven panel helper: `open(id, buildName, ?params)`, `openAt(x, y, buildName, ?params, ?closeMode)`, `close()`, `isOpen()`, `getPanelResult()`, `handleOutsideClick(event)`; auto-registers panel interactives with prefix; `OutsideClick` / `Manual` close modes; per-interactive overrides: `setPosition()`, `setOffset()`; pushes `UICustomEvent(EVENT_PANEL_CLOSE, interactiveId)` on close (not emitted for `openAt` since there is no interactiveId); multi-panel support via named slots: `openNamed(slot, ...)`, `closeNamed(slot)`, `closeAllNamed()`, `isOpenNamed(slot)`, `getNamedPanelResult(slot)`. **Auto-wiring** (recommended): `createPanelHelper(builder, ?defaults, ?tweens)` creates and registers the helper — `handleOutsideClick()` runs automatically in `dispatchScreenEvent()`, `checkPendingClose()` runs in `update()`. Manual: `registerPanelHelper(helper)` / `unregisterPanelHelper(helper)`. `clear()` unregisters all.
- **Cursor support** — `UIElementCursor` interface with `getCursor():hxd.Cursor` for state-dependent cursor
  - `CursorManager` — static registry (like `FontManager`); pre-registers Heaps cursors: `default`, `pointer`/`button`, `move`, `text`, `hide`/`none`
  - `registerCursor(name, cursor)` / `unregisterCursor(name)` / `getCursor(name)` for custom cursors
  - `setDefaultInteractiveCursor(cursor)` — global default for UI elements (defaults to `Button`/pointer)
  - `setDefaultCursor(cursor)` — fallback when not hovering any element (defaults to `Default`)
  - All built-in components (Button, Checkbox, Slider, Dropdown, TabButton, ScrollableList) implement `UIElementCursor`
  - Interactive per-state cursors via metadata: `cursor => "pointer"`, `cursor.hover => "move"`, `cursor.disabled => "default"`
  - Unknown `cursor.*` suffixes throw (valid: `cursor.hover`, `cursor.disabled`)
  - Controller plumbing in `UIDefaultController.handleMove()` — calls `hxd.System.setCursor()`

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
- **`DropZoneId` enum** — structured zone identifiers: `GridCell(grid, col, row)` for grid cells, `SlotZone(baseName, ?index)` for slot-based zones, `SlotZone2D(baseName, indexX, indexY)` for 2D-indexed slots, `Named(name)` for custom zones. `DropZoneIdTools.format(id)` for debug display
- `addDropZonesFromSlots("baseName", builderResult, ?accepts)` — batch drop zone creation (auto-generates `SlotZone`/`SlotZone2D` IDs)
- `removeDropZone(id:DropZoneId)` — uses `Type.enumEq` for comparison
- `createFromSlot(slot)` — creates draggable from slot content, tracks `sourceSlot`
- `cancelDrag()` — programmatically cancel an in-progress drag. Restores origin, alpha, layer, source slot, clears zone highlights, fires `DragCancel`. No-op when not dragging. Also triggered automatically when `enabled` is set to `false` during drag
- `swapMode` — swaps contents when dropping onto an occupied slot. Requires `sourceSlot` (use `createFromSlot`); setting `true` without `sourceSlot` throws
- `payload:Dynamic` — general-purpose data field for `accepts` callbacks (auto-set by `makeDraggableFromCell`)
- `sourceGrid:Null<UIMultiAnimGrid>` / `sourceCellCoord:Null<CellCoord>` — source tracking for cross-grid transfers (auto-set by `makeDraggableFromCell`)
- Zone highlight callbacks: `onDragStartHighlightZones`, `onDragEndHighlightZones` on draggable
- Zone reject callbacks: `onDragStartRejectZones` on draggable, `DropZone.onZoneReject` per-zone
- Per-zone: `DropZone.onZoneHighlight` callback for hover state
- `DragEvent` enum includes `ZoneRejectEnter(zone)` / `ZoneRejectLeave(zone)` for three-state feedback

## Higher-Order Components (UIHigherOrderComponent)

`UIHigherOrderComponent` interface (`src/bh/ui/UIHigherOrderComponent.hx`) — lifecycle auto-wiring for complex UI components (Grid, CardHand) that manage their own scene graph and span multiple layers.

**Interface methods:** `update(dt)`, `onMouseMove(x, y):Bool`, `onMouseClick(x, y, button):Bool`, `onMouseRelease(x, y):Bool`, `handleScreenEvent(event):Bool`, `getObject():h2d.Object`, `dispose()`.

**Implementors:** `UIMultiAnimGrid`, `UICardHandHelper`

**Screen auto-wiring:** `registerComponent(comp)` / `unregisterComponent(comp)` on `UIScreenBase`. Registered components auto-receive:
- `update(dt)` — called in `super.update(dt)` after panel helpers
- Mouse events — `dispatchMouseMove()` / `dispatchMouseClick()` try components first (registration order), fall through to screen overrides
- Screen events — `dispatchScreenEvent()` forwards to components before `onScreenEvent()`
- Disposal — `clear()` calls `dispose()` on all registered components

**Factory methods on UIScreenBase:**
- `createGrid(builder, config, ?settings)` — creates + registers, no scene graph add (for macro use)
- `addGrid(builder, config, ?layer, ?settings)` — creates + adds to layer
- `addCardHand(builder, ?config, ?settings)` — creates + registers + returns helper

**Settings integration:** `applyGridSettings(config, settings)` and `applyCardHandSettings(config, settings)` apply `.manim` `settings {}` values to config fields. Grid: `originX/Y`, `swapPathName`, `swapEnabled`. CardHand: `anchorX/Y`, card dimensions, fan/linear layout, hover/targeting, pile positions, path/arrow names.

**Macro support (`macroBuildWithParameters`):** `PVComponent` placeholder value for component-returning factories. Macro detects `UIHigherOrderComponent` return type and generates `PVComponent(factory, null)` wrapper. Builder calls `getObject()` for scene graph placement. Grid works in macro; CardHand uses `addCardHand()` only (multi-layer architecture prevents single-placeholder representation).

**Dispatch pattern:** `UIControllerScreenIntegration` uses `dispatchMouseMove()` / `dispatchMouseClick()` instead of direct `onMouseMove()` / `onMouseClick()` — enables component event interception before screen handlers. Key coexistence semantics:
- `dispatchMouseMove()` — notifies components but always returns true (never blocks interactive processing)
- `dispatchMouseClick()` — push (non-release) notifies components but never blocks; only release can block (returns false when consumed, e.g. card hand drag end). Controller preserves outside-click tracking even when consumed.
- `dispatchScreenEvent()` — runs autoStatus + panelHelpers first, then tries components. Skips `onScreenEvent()` when a component consumed the event.

**UIComponentHost interface** (`src/bh/ui/UIComponentHost.hx`): Decouples CardHand and UIRichInteractiveHelper from concrete UIScreenBase. Methods: `addObjectToLayer`, `addInteractives`, `removeInteractives`, `getInteractive`, `getAutoInteractiveHelper`. UIScreenBase implements it.

**Hot reload** (`#if MULTIANIM_DEV`):
- `wireGridReload(parentResult, grid, ?prefix)` — hooks `onReload` to re-apply `originX`/`originY` from settings
- `wireCardHandReload(parentResult, cardHand, ?prefix)` — hooks `onReload` to re-apply `anchorX`/`anchorY`
- Grid layers: `setLayer()` uses incremental mode for hot-reload of layer programmables
- Grid: `setOrigin(x, y)` repositions root (all children move automatically)

## Grid Component

`UIMultiAnimGrid` — 2D grid component (rectangular or hexagonal) that manages cell state, rendering via `.manim` programmables, drag-drop integration, and card hand targeting. Follows the helper/manager pattern (like `UICardHandHelper`). Implements `UIHigherOrderComponent`.

**Files:**
- `src/bh/ui/UIMultiAnimGrid.hx` — main component
- `src/bh/ui/UIMultiAnimGridTypes.hx` — types: `GridType`, `GridEvent`, `GridConfig`, `CellCoord`, `CellVisual<T>`, `CellVisualFactory<T>`, delegates

**Construction:**
```haxe
var factory = new DefaultCellVisualFactory(builder, {
    cellBuildName: "gridCell",       // .manim programmable name for cells
    cellBuildDelegate: null,         // optional per-cell override (buildName + params)
    highlightParam: "highlight",     // cell param for drag highlight state (default: "highlight")
    statusParam: "status",           // cell param for hover status (default: "status")
    highlightDelegate: null,         // optional per-cell highlight value delegate
});
var grid = new UIMultiAnimGrid(builder, {
    gridType: Rect(50, 50, 4),      // Rect(cellWidth, cellHeight, ?gap) or Hex(orientation, sizeX, sizeY)
    cellVisualFactory: factory,      // factory that builds cell visuals
    originX: 0, originY: 0,         // grid root position
    snapPathName: "snapAnim",       // animatedPath for drop snap (null = instant)
    returnPathName: "returnAnim",   // animatedPath for drag cancel return (null = instant)
    swapPathName: "swapAnim",       // animatedPath for displaced item during swap (null = falls back to returnPathName, then instant)
    swapEnabled: true,              // enable swap semantics on occupied cell drops (default: false)
    swapAccepts: null,              // (cell, draggable) -> Bool; null = isOccupied() default
    swapAnimContainer: swapLayer,   // h2d.Object parent for in-flight swap visuals (null = grid root fallback)
    tweenManager: screenManager.tweens, // optional TweenManager for cell lifecycle animations (null = instant)
    cellDragEnabled: true,          // cells with data become draggable on press (default: false)
    cellDragFilter: null,           // (col, row, data) -> Bool; null = all with data
    cellDragContainer: dragLayer,   // h2d.Object parent for drag visual (null = grid root at high z-order)
});
```

**CellVisual<T> interface:** Wraps the visual representation of a grid cell. The grid manages highlight/status state through typed methods. Game-specific parameters accessible via `getResult()`.
- `object:h2d.Object` — scene graph object
- `setHighlight(value)` / `setStatus(value)` — typed state updates
- `beginUpdate(?data:T)` / `endUpdate()` — batch multiple state changes + data awareness
- `getResult():Null<BuilderResult>` — escape hatch for game-specific params

**CellVisualFactory<T> interface:** Factory for creating cell visuals. `DefaultCellVisualFactory<T>` wraps `MultiAnimBuilder`.
- `highlightDefault:String` — default highlight value (e.g. "none")
- `buildCell(coord, data, extraParams)` — create a cell visual
- `resolveHighlightValue(coord, accepts)` — determine highlight during drag/card targeting

**Cell programmable contract:** Must have parameters matching `highlightParam` (enum, default values "none"/"accept"/"reject") and `statusParam` (enum with "normal"/"hover"). Custom highlight values supported via `highlightDelegate` on factory config. Receives `col:int` and `row:int` automatically.

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
- `getCellVisual(col, row)` — get `CellVisual<T>` for the cell (use `getResult()` for raw `BuilderResult`)
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
- `CellDrop(cell, draggable, sourceGrid, sourceCell, ctx)` — draggable dropped on cell. `ctx:DropContext` controls post-drop animation
- `CellSwap(source, target, draggable, ctx)` — draggable dropped on occupied cell with `swapEnabled=true`, or programmatic `swapCells()`. `ctx:SwapContext` controls swap animation. `draggable` is null for programmatic swaps. `ctx.programmatic` distinguishes drag vs API
- `CellDragStart(cell, draggable)` — cell drag started (`cellDragEnabled`). Draggable is a data carrier (payload, sourceGrid, sourceCellCoord)
- `CellDragEnd(cell)` — cell drag ended (drop, cancel, or swap complete)
- `CellCardPlayed(cell, cardId)` — card played on cell (from card hand targeting)
- `CellDataChanged(cell, oldData, newData)` — data changed via `set()` or `clear()`

**DropContext** (passed in `CellDrop` event):
- `ctx.accept()` — play snap animation (default)
- `ctx.reject()` — play return animation (draggable returns to origin)
- `ctx.acceptWithPath(pathName)` / `ctx.rejectWithPath(pathName)` — custom animation paths
- `ctx.onComplete(cb)` — fires after snap/return animation completes (accept: `DragSnapComplete`, reject: `DragCancel`)

**SwapContext** (passed in `CellSwap` event):
- `ctx.accept()` — swap both items (default). Dropped item snaps to target, displaced item animates to source via `swapPathName`
- `ctx.acceptWithSwapPath(pathName)` — custom animation path for displaced item
- `ctx.acceptWithPaths(snapPathName, swapPathName)` — custom paths for both dropped and displaced items
- `ctx.reject()` — cancel swap, draggable returns to origin
- `ctx.onComplete(cb)` — fires after both animations complete
- `ctx.programmatic` — `true` if triggered by `swapCells()`, `false` if triggered by drag-drop

**Cell swap API:**
- `swapCells(col1, row1, col2, row2, ?animated:Bool=true)` — swap two cells' data and visuals. Emits `CellSwap` with `ctx.programmatic=true`. If animated, uses `swapPathName` (fallback: `returnPathName`) for both items moving simultaneously. Both cells must exist
- Swap on drop: when `swapEnabled=true` and a draggable has a source cell, the `swapAccepts` delegate (or `isOccupied()` by default) decides whether to emit `CellSwap` or fall through to `CellDrop`. The dragged item snaps to target, the displaced item animates to the source cell. Cross-grid swaps work when `sourceGrid` is set (via `makeDraggableFromCell`)
- Swap path fallback chain: `SwapContext._swapPathName` > `GridConfig.swapPathName` > `GridConfig.returnPathName` > instant

**Built-in cell drag** (`cellDragEnabled: true` in config):
- Cells with data become draggable on left-click press — no external `UIMultiAnimDraggable` wiring needed
- Grid internally detaches cell visual, tracks mouse, finds drop targets via `cellAtPoint()`, handles snap/return/swap animations
- `cellDragFilter: (col, row, data) -> Bool` — optional filter for which cells can be dragged (null = all with data)
- `cellDragContainer: h2d.Object` — parent for drag visual (null = grid root at high z-order)
- Emits `CellDragStart(cell, carrier)` on drag begin, `CellDrop`/`CellSwap` on drop, `CellDragEnd(cell)` on completion
- The `draggable` in `CellDrop` is a lightweight data carrier (access `.payload`, `.sourceGrid`, `.sourceCellCoord`)
- The `draggable` in `CellSwap` is null for cell-drag-initiated swaps (same as programmatic swaps)
- Self-drop: grid auto-registers its own cells as drop targets (source cell excluded)
- Cross-grid drop: use `linkDropTarget()` to register other grids as drop targets

**Cross-grid linking** (for `cellDragEnabled`):
- `linkDropTarget(target, ?accepts)` — register another grid as a drop target for this grid's cell drags. `accepts: (targetCell, sourceCell, data) -> Bool`
- `unlinkDropTarget(target)` — unregister
- `UIMultiAnimGrid.linkGrids(a, b, ?accepts)` — static convenience for bidirectional linking

**External drag-drop integration** (manual `UIMultiAnimDraggable` wiring):
- `acceptDrops(draggable, ?accepts)` — register a `UIMultiAnimDraggable` to drop onto this grid's cells. Auto-creates `DropZone` per cell, manages highlight state. `accepts: (cell, draggable) -> Bool` filters valid targets. Highlight values determined by factory's `resolveHighlightValue()`
- `removeDrops(draggable)` — unregister draggable
- `makeDraggableFromCell(col, row, ?visualOverride)` — create draggable from cell content. Sets `sourceGrid`, `sourceCellCoord`, and `payload` on the draggable

**Card hand integration:**
- `registerAsCardTarget(cardHand, ?accepts)` — register grid cells as card play targets. Creates synthetic `UIInteractiveWrapper` per cell for the card hand's targeting system. `accepts: (cell, cardId) -> Bool` filters valid targets
- `unregisterAsCardTarget(cardHand)` — unregister

**Grid layers** — named per-cell overlays with z-ordering:
- `addLayer(name, {buildName, zOrder})` — register a named layer (base cells at z-order 0)
- `setLayer(col, row, layerName, ?params)` — build/rebuild layer programmable on a cell
- `clearLayer(col, row, layerName)` — remove layer from a cell
- `clearLayerAll(layerName)` — remove layer from all cells
- `clearAllLayers()` — remove all layers
- `getLayerVisual(col, row, layerName)` — `CellVisual<T>` for incremental updates (use `getResult()` for `BuilderResult`)
- `hasLayer(col, row, layerName)` — check existence
- `removeCell()` / `removeCellAnimated()` auto-clear layers on the cell

**External objects in layer hierarchy:**
- `addExternalObject(obj, zOrder)` — insert arbitrary object into grid's `h2d.Layers` at a z-order
- `removeExternalObject(obj)` — remove it

**Cell animations** (require `tweenManager` in config):
- `tweenCell(col, row, duration, properties, ?easing)` — animate cell object properties (e.g. shake, pulse). Non-destructive — cell stays in grid
- `addCellAnimated(col, row, duration, properties, ?easing, ?data, ?params)` — add cell with entrance animation. Properties are FROM values (e.g. `[Scale(0.0), Alpha(0.0)]` → cell scales/fades in from 0)
- `removeCellAnimated(col, row, duration, properties, ?easing)` — animate cell then remove. Properties are TO values (e.g. `[Scale(0.0), Alpha(0.0)]` → cell shrinks/fades out)

**Detach/reattach cell visual:**
- `detachCellVisual(col, row) -> h2d.Object` — remove visual from cell for free animation (e.g. fly to another location). Cell data preserved but shows empty
- `reattachCellVisual(col, row)` — rebuild cell visual from existing data

**Lifecycle:**
- `getObject()` — root `h2d.Object`, add to scene via `addObjectToLayer(grid.getObject(), layer)`
- `update(dt)` — call from screen update for animation support
- `dispose()` — clean up all resources, zones, and scene graph

**Callbacks:**
- `onGridEvent:(GridEvent) -> Void` — main event callback
- `onCellBuilt:(CellCoord, CellVisual<T>) -> Void` — called after each cell build (customize overlays etc.)

**Built-in cell drag pattern** (recommended for grid-to-grid):
```haxe
// Setup: two grids with built-in cell dragging
shipGrid = addGrid(builder, {
    gridType: Rect(64, 64), cellVisualFactory: factory,
    cellDragEnabled: true, cellDragContainer: dragLayer,
    snapPathName: "snapPath", returnPathName: "returnPath",
    swapEnabled: true, swapPathName: "swapPath",
});
inventoryGrid = addGrid(builder, {
    gridType: Rect(64, 64), cellVisualFactory: factory,
    cellDragEnabled: true, cellDragContainer: dragLayer,
    snapPathName: "snapPath", returnPathName: "returnPath",
    swapEnabled: true, swapPathName: "swapPath",
});

// Link grids bidirectionally — cells can be dragged between them
UIMultiAnimGrid.linkGrids(shipGrid, inventoryGrid);

// Handle events — game state updates
shipGrid.onGridEvent = (event) -> switch event {
    case CellDrop(cell, carrier, sourceGrid, sourceCell, ctx):
        ctx.accept();
        shipGrid.set(cell.col, cell.row, carrier.payload);
        if (sourceGrid != null && sourceCell != null) sourceGrid.clear(sourceCell.col, sourceCell.row);
    case CellSwap(source, target, _, ctx):
        ctx.accept();
    default:
};
```

**Cross-grid drag pattern (manual):**
```haxe
// Both grids accept drops — use payload for typed filtering
storageGrid.acceptDrops(drag, (cell, d) -> {
    if (storageGrid.isOccupied(cell.col, cell.row)) return false;
    return d.payload != null ? d.payload.type == "weapon" : true;
});
loadoutGrid.acceptDrops(drag, (cell, d) -> !loadoutGrid.isOccupied(cell.col, cell.row));

// makeDraggableFromCell auto-sets payload, sourceGrid, sourceCellCoord
var drag = srcGrid.makeDraggableFromCell(col, row);

// In onGridEvent CellDrop: source tracking + animation control
case CellDrop(cell, draggable, sourceGrid, sourceCell, ctx):
    ctx.accept();
    targetGrid.set(cell.col, cell.row, draggable.payload);
    ctx.onComplete(() -> rebuildDraggables());
    // sourceGrid/sourceCell identify where the drag started
```

**Cross-grid swap pattern:**
```haxe
// Enable swap on inventory grid — dropping on occupied cell swaps items
// swapAnimContainer: provide an h2d.Object at a layer above the grid so displaced items render on top
var swapLayer = new h2d.Layers();
addObjectToLayer(swapLayer, NamedLayer("swapAnim")); // register layer if needed
var grid = addGrid(builder, {
    gridType: Rect(64, 64), cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: "cell"}),
    snapPathName: "snapPath", swapPathName: "swapPath", swapEnabled: true,
    swapAnimContainer: swapLayer,
});
grid.onGridEvent = (event) -> switch event {
    case CellSwap(source, target, draggable, ctx):
        ctx.accept(); // default — both items animate
        ctx.onComplete(() -> trace("swap done"));
    case CellDrop(cell, draggable, _, _, ctx):
        // Only fires for drops on EMPTY cells (swapEnabled redirects occupied)
        grid.set(cell.col, cell.row, draggable.payload);
    default:
};
// Programmatic swap (e.g. sort inventory)
grid.swapCells(0, 0, 1, 0); // animated
grid.swapCells(0, 0, 1, 0, false); // instant
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
