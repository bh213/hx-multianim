Technical docs
--------------

This document provides a high-level overview of the technical architecture and implementation details of hx-multianim. For the `.manim` language reference, see [docs/manim.md](docs/manim.md).

## Architecture Overview

The library has three main layers:

1. **Parser** (`MultiAnimParser.hx`) — Parses `.manim` files into an AST of `Node` structures using hxparse
2. **Builder** (`MultiAnimBuilder.hx`) — Resolves the AST: evaluates expressions, resolves references, builds the h2d scene graph at runtime
3. **Macro CodeGen** (`ProgrammableCodeGen.hx` + `MacroManimParser.hx`) — Parses `.manim` at compile time and generates typed Haxe classes

```
.manim file
    │
    ├──► MultiAnimParser (hxparse) ──► Node AST ──► MultiAnimBuilder ──► h2d scene graph
    │                                                                     (runtime)
    └──► MacroManimParser (compile-time) ──► ProgrammableCodeGen ──► generated Haxe classes
                                                                      (compile-time)
```

## Parser

`MultiAnimParser.parseFile()` is the main entry point. It uses a **modified fork** of hxparse (`github.com/bh213/hxparse`).

**Key classes:**
- `MultiAnimParser` — hxparse-based stream parser for `.manim` files
- `AnimParser` — hxparse-based parser for `.anim` state animation files
- `MacroManimParser` — Compile-time parser (NOT hxparse-based; uses `peek()`/`match()`/`advance()`)

**Error types:**
- `InvalidSyntax` (extends `ParserError`) — Semantic errors (e.g., unknown variable, duplicate name)
- `MultiAnimUnexpected` — Syntax errors (unexpected token)

**hxparse caveat:** Pattern matching only works on the **first element** of a `case` pattern. See CLAUDE.md for details.

## Builder

`MultiAnimBuilder` resolves parsed nodes into h2d objects. Key concepts:

### BuilderResult

Returned by `buildWithParameters()`. Contains the built h2d object tree and provides access to named elements, slots, dynamic refs, and updatables.

**Key methods:**
- `getUpdatable(name)` / `getUpdatableByIndex(name, index)` — Access named elements for runtime updates
- `getSlot(name, ?index)` — Access slot containers (`SlotHandle`)
- `getDynamicRef(name)` — Access dynamic ref sub-results (`BuilderResult`)
- `setParameter(name, value)` — Update parameters (incremental mode only)
- `beginUpdate()` / `endUpdate()` — Batch parameter changes
- `getSingleItemByName(name)` — Get raw h2d.Object by name

### Incremental Mode

When `buildWithParameters(..., incremental: true)` is used, the builder constructs ALL conditional branches (setting non-matching ones to invisible) and tracks expression-dependent properties. Calling `setParameter()` then re-evaluates conditionals and expressions without rebuilding the tree.

**Tracked properties:** text content, color, size, position, alpha, tint, filters, visibility.

### Slot System

Slots (`#name slot`) create containers whose content can be swapped at runtime via `SlotHandle`:
- `setContent(obj)` — Hides default children, adds replacement
- `clear()` — Removes replacement, restores defaults
- `getContent()` — Returns current replacement or null

Indexed slots (`#name[$i] slot`) inside repeatables create per-iteration containers: `getSlot("name", 0)`, `getSlot("name", 1)`, etc. Mismatched access (index on non-indexed or vice versa) throws.

**Parameterized slots** (`#name slot(param:type=default, ...)`) add visual state management to slots. The slot body supports conditionals (`@(param=>value)`) and expressions (`$param`). Content added via `setContent()` goes into a separate `contentRoot` while slot decorations remain visible. `SlotHandle.setParameter("name", value)` drives incremental visual updates. In codegen, parameterized slots delegate to runtime via `ProgrammableBuilder.buildParameterizedSlot()`.

### Dynamic Ref System

Dynamic refs (`dynamicRef($ref, params)`) embed programmables with incremental mode enabled automatically. The sub-result is stored and accessible via `getDynamicRef("name")`. This enables runtime parameter updates on embedded elements without rebuilding.

### Coordinate Systems

Beyond basic `x, y` pixel offsets, the builder resolves two coordinate systems declared in element bodies:

- **Grid** — `grid: spacingX, spacingY` enables `$grid.pos(col, row)` positioning. Properties: `$grid.width`, `$grid.height`.
- **Hex** — `hex: pointy|flat(w, h)` enables `$hex.cube(q, r, s)`, `$hex.corner(index, scale)`, `$hex.edge(dir, scale)`, `$hex.offset(col, row, even|odd)`, `$hex.doubled(col, row)`. Properties: `$hex.width`, `$hex.height`.

Both support named variants (`grid: #name spacingX, spacingY`), value extraction (`.x`, `.y`), and the `.offset(dx, dy)` suffix to add pixel offsets to any coordinate expression.

**Context properties:** `$ctx.width`, `$ctx.height`, `$ctx.random(min, max)`, `$ctx.font("name").lineHeight`, `$ctx.font("name").baseLine` provide build-context values in expressions.

**Layout system:** `MultiAnimLayouts` resolves `layout(name [, index])` references to positions from Single, List, Sequence, and Grid layout definitions.

### Transition Declarations

```manim
#button programmable(status:[normal,hover]=normal) {
    transition { status: crossfade(0.1, easeOutQuad) }
    ...
}
```

A `transition { }` block inside a programmable declares animated transitions for parameter-triggered visibility changes. When `setParameter()` changes a value, matching/unmatching branches animate via TweenManager instead of instant toggling. Types: `none`, `fade(duration, ?easing)`, `crossfade(duration, ?easing)`, `flipX(duration, ?easing)`, `flipY(duration, ?easing)`, `slide(direction, duration, ?distance, ?easing)`.

Requires TweenManager (auto-injected via `ScreenManager.buildFromResource()`; also injectable via `BuilderResult.setTweenManager()`). Falls back to instant without TweenManager. Implementation: `CodegenTransitionHelper.hx`.

## Language Elements

`.manim` language constructs beyond the core programmable/element system.

### @final Constants

`@final name = expr` declares an immutable named constant, usable as `$name` in expressions and coordinates. Scoped to the enclosing `{ }` block. Supports numeric, string, color, bool, and array values. Avoids repeating magic numbers across a programmable.

### Import System

`import "file.manim" as "name"` allows cross-file references. Imported programmables are referenced via `staticRef(external("name"), $ref)` and `dynamicRef(external("name"), $ref, params)`. Enables modular `.manim` file organization.

### Rich Text & Markup

`richText(font, text, color, ...)` creates `h2d.HtmlText` with BBCode-style `[tag]...[/]` markup converted by `TextMarkupConverter`:
- `[styleName]...[/]` — applies named style (requires `styles: { name: color(#hex) font("name") }`)
- `[img:name]` — inline image (requires `images: { name: tileSource }`)
- `[align:left|center|right]...[/]` — paragraph alignment
- `[link:id]...[/]` — clickable link
- `[[` — literal `[` escape

Codegen generates per-style setters: `setStyleColor_<name>()`, `setStyleFont_<name>()`, `setImageTile_<name>()`.

### Graphics & Pixels

Two primitive drawing elements:
- **`graphics(color, lineWidth) { ... }`** — creates `h2d.Graphics` with shapes: `rect`, `circle`, `ellipse`, `arc`, `line`, `roundrect`, `polygon`. Supports conditional color via ternary expressions.
- **`pixels(...)`** — pixel-perfect primitives: `pixel`, `line`, `rect`, `filledRect`.

### Tilegroup

`tilegroup` is a GPU-batched container that merges `bitmap`, `ninepatch`, `pixels`, `point`, and `repeatable`/`repeatable2d` children into a single `h2d.TileGroup` draw call. Used for performance-critical rendering (HP bars, tile maps, minimap elements).

### Flow Advanced Features

Beyond basic `flow(horizontal|vertical)` layout:
- `overflow: expand|limit|scroll|hidden` — content overflow behavior
- `fillWidth: true`, `fillHeight: true` — stretch to parent
- `reverse: true` — reverse child order
- `horizontalAlign: left|right|middle`, `verticalAlign: top|bottom|middle` — default child alignment

Per-element annotations override layout for individual children:
- `@flow.halign(left|right|middle)`, `@flow.valign(top|bottom|middle)` — per-child alignment
- `@flow.offset(x, y)` — pixel offset within flow
- `@flow.absolute` — remove from layout (overlay positioning)

Parse-time validation ensures `@flow.*` annotations are inside a flow ancestor.

### Particles

Full particle system via `particles { }` element. Key concepts:

- **Emission:** `emit: point(...)`, `cone(...)`, `box(...)`, `circle(...)`, `path(pathName)` with named parameters for distance, angle, spread
- **Lifetime:** `maxLife`, `fadeIn`, `fadeOut`, `count`, `loop`
- **Motion:** `speed`, `gravity`, `gravityAngle`, `forwardAngle`, size/velocity curves
- **Color stops:** `colorStops: 0.0 #FF0000, 0.5 #00FF00 easeInQuad, 1.0 #0000FF` — per-stop easing interpolation
- **Force fields:** `forceFields: [turbulence(...), wind(...), vortex(...), attractor(...), repulsor(...), pathguide(...)]`
- **Sub-emitters:** `subEmitters: [{ groupId: "sparks", trigger: ondeath, probability: 0.8 }]` — particles spawning child particles on lifecycle events
- **Bounds:** `bounds: kill, box(x, y, w, h)` — kill zones and containment
- **Animation:** `animFile`, `animSelector`, lifetime-driven animation state changes
- **Angle units:** `deg`, `rad`, `turn` suffixes; direction constants (`up`, `down`, `left`, `right`)

Runtime API: `group.emitBurst(count)`, `group.addForceField(ff)`, `group.removeForceFieldAt(i)`, `group.clearForceFields()`.

## UIElements

UI elements implement the `UIElement` interface for event handling within the screen system.

**Key interfaces:**
- `UIElement` — Base interface for all interactive UI elements
- `StandardUIElementEvents` — Standard event emission (UIClick, UIEntering, UILeaving, etc.)
- `UIElementIdentifiable` — Opt-in interface exposing `id`, `prefix`, and `metadata`
- `UIElementSubElements` — For composite elements that contain child UIElements
- Capability interfaces: `UIElementText`, `UIElementNumberValue`, `UIElementFloatValue`, `UIElementListValue`, `UIElementDisablable`, `UIElementCursor`, `UIElementSelectable`

**Element types:** Button, Checkbox, Slider, RadioButtons, ScrollableList, Dropdown, Tabs, TextInput, ProgressBar, Draggable, InteractiveWrapper

### Settings Pass-Through

`UIScreenBase` helper methods (`addButton`, `addSlider`, etc.) classify each setting as:
1. **Control** — consumed by UIScreen (e.g. `buildName`, `panelMode`)
2. **Behavioral** — set on the UI object (e.g. `min`, `max`, `autoOpen`)
3. **Pass-through** — forwarded as `extraParams` to the programmable builder
4. **Prefixed pass-through** — dotted keys like `item.fontColor` route to sub-builders in multi-programmable components (dropdown, scrollableList)

Unknown pass-through params are validated by `MultiAnimBuilder.updateIndexedParamsFromDynamicMap()`, which throws with the programmable name and available parameters.

### Elements handling by UIScreen

If elements are not showing or reacting to events, check if they have been added to UIScreen's elements.

### Interactive Wrapper

`UIInteractiveWrapper` wraps `MAInteractive` objects as UIElements. It implements `UIElementIdentifiable` to expose `id`, `prefix`, and typed `metadata` (a `BuilderResolvedSettings` map with `RSVString/RSVInt/RSVFloat/RSVBool/RSVColor` values).

Interactive metadata is declared in `.manim`: `interactive(w, h, id, key => val, key:int => N)`. Event filtering: `events: [hover, click, push]` controls which events are emitted.

Screen methods for managing interactives:
- `addInteractive(obj, prefix)` — Wraps a single MAInteractive
- `addInteractives(result, prefix)` — Wraps all interactives from a BuilderResult
- `removeInteractives(prefix)` — Removes wrappers by prefix
- `getInteractive(id)` — O(1) map lookup by id
- `getInteractivesByPrefix(prefix)` — All wrappers with a given prefix

Events: `UIInteractiveEvent(event, id, metadata)` where event is `UIClick`, `UIEntering`, `UILeaving`, `UIPush`, `UIClickOutside`.

### Dropdown

Dropdown control consists of a closed-like button and scrollable panel. The dropdown moves the panel to a different layer and keeps position in sync with `PositionLinkObject`. Uses incremental `BuilderResult` with `setParameter("status", ...)` and `setParameter("panel", "open"/"closed")`.

### UIRichInteractiveHelper

Auto-wires `interactive()` elements to a Normal→Hover→Pressed→Disabled state machine. Two metadata keys: `autoStatus => "status"` for screen-level auto-wiring (zero boilerplate — `addInteractives()` detects it and handles events via `dispatchScreenEvent()`), and `bind => "status"` for manual wiring (e.g., `UICardHandHelper`). `register(result, ?prefix, metadataKey)` scans interactives for the given key (default: `"bind"`). `handleEvent(event)` drives state transitions via `setParameter()` on the parent `BuilderResult`. `setDisabled(id, bool)` toggles disabled state. `hasBinding(id)`, `unregisterByPrefix(prefix)`, `bind()`/`unbind()`/`setParameter()`/`getResult()` for manual control. Collision detection throws if an interactive is managed by both `autoStatus` and `bind`.

### UITooltipHelper

Screen-driven tooltip system. `startHover(id, buildName, ?params)` starts a delay timer; after the delay, the tooltip is built from a `.manim` programmable and displayed. `cancelHover(id)` / `hide()` remove it.

Configuration: delay, position (`Above`/`Below`/`Left`/`Right`), offset, layer. Per-interactive overrides: `setDelay()`, `setPosition()`, `setOffset()`. `updateParams(params)` for incremental parameter updates on active tooltips; `rebuild(?params)` for full rebuild. Optional TweenManager fade-in/fade-out via `TooltipDefaults { ?fadeIn, ?fadeOut }`.

### UIPanelHelper

Screen-driven panel popups. `open(id, buildName, ?params)` builds and positions a panel; `close()` removes it. Close modes: `OutsideClick` (auto-close on click outside) and `Manual`. Auto-registers panel interactives with prefix for event routing.

Multi-panel support via named slots: `openNamed(slot, ...)`, `closeNamed(slot)`, `closeAllNamed()`, `isOpenNamed(slot)`, `getNamedPanelResult(slot)`. Fires `UICustomEvent(EVENT_PANEL_CLOSE, interactiveId)` on close. Optional TweenManager fade via `PanelDefaults { ?fadeIn, ?fadeOut }`.

### UIMultiAnimTabs

Tab bar with per-tab content management. `beginTab()`/`endTab()` bracket content registration per tab — screen elements added between these calls are routed to the active tab's container via the `ContentTarget` interface.

Settings: `buildName` (tab bar programmable), `tabButtonBuildName` (tab button programmable), `tabButton.*` (prefixed to tab buttons), `tabPanel.width`/`tabPanel.height`, `tabPanel.contentRoot` (names a `#point` element for relative coordinate mode — each tab gets its own `h2d.Layers` at the point's position). Events: `UIChangeItem(index, items)`.

### UIMultiAnimTextInput & UITabGroup

`UIMultiAnimTextInput` wraps `h2d.TextInput` inside a `.manim` programmable frame. Requires a programmable with `status:[normal,hover,focused,disabled]=normal`, `placeholder:bool=true`, and `#textArea point` (insertion position).

Settings: `font`, `fontColor`, `cursorColor`, `selectionColor`, `placeholder`, `maxLength`, `multiline`, `readOnly`, `disabled`, `filter` (`numeric`/`alphanumeric`/`none`), `inputWidth`, `tabIndex`. Events: `UITextChange(text)`, `UITextSubmit(text)`, `UIFocusChange(focused)`.

`UITabGroup` provides Tab/Shift+Tab focus cycling between text inputs. `enableTabNavigation(Autowire)` handles Tab key automatically. `tabIndex` setting controls ordering (auto-assigned if omitted). `enterAdvances` flag advances focus on Enter.

### UIMultiAnimDraggable

Drag-and-drop system with slot integration. `addDropZonesFromSlots("baseName", builderResult, ?accepts)` batch-creates drop zones from slot handles. `createFromSlot(slot)` creates draggables from slot content, tracking `sourceSlot` for return. `swapMode` swaps contents when dropping onto an occupied slot. Zone highlight callbacks: `onDragStartHighlightZones`, `onDragEndHighlightZones` on the draggable; `DropZone.onZoneHighlight` for per-zone hover state.

### Progress Bar

Display-only component (`UIMultiAnimProgressBar`). Uses full rebuild (not incremental) because `bitmap(generated(color(...)))` is not tracked by incremental mode. Screen helper: `addProgressBar(builder, settings, initialValue)`. Implements `UIElementNumberValue` and `UIElementFloatValue`.

### CursorManager

Static cursor registry (like `FontManager`). Pre-registers Heaps cursors: `default`, `pointer`/`button`, `move`, `text`, `hide`/`none`. Custom cursors via `registerCursor(name, cursor)`. `setDefaultInteractiveCursor(cursor)` sets the global default for UI elements (defaults to pointer). `setDefaultCursor(cursor)` for the fallback when not hovering any element.

Per-interactive state cursors via metadata: `cursor => "pointer"`, `cursor.hover => "move"`, `cursor.disabled => "default"`. All built-in UI components (Button, Checkbox, Slider, Dropdown, TabButton, ScrollableList) implement `UIElementCursor`. Controller plumbing in `UIControllerBase.handleMove()` calls `hxd.System.setCursor()`.

## Runtime Systems

Systems that run in the game loop and coordinate multiple subsystems.

### TweenManager

Lightweight tween system (`src/bh/base/TweenManager.hx`) owned by `ScreenManager`, updated in `ScreenManager.update(dt)`. Animates `h2d.Object` properties via `TweenProperty` enum: `Alpha`, `X`, `Y`, `ScaleX`, `ScaleY`, `Scale`, `Rotation`, `Custom(getter, setter, to)`.

**Core API:** `tween(obj, duration, properties, easing)`, `createTween(...)` (deferred start), `sequence([t1, t2])` (sequential), `group([t1, t2])` (parallel). Convenience: `fadeIn()`, `fadeOut()`, `moveTo()`, `scaleTo()`. Cancellation: `cancel(tween)`, `cancelAll(target)`, `cancelAllChildren(root)`, `clear()`.

**Key behaviors:** `skipFirstDt = true` prevents stutter after scene graph changes. Sequence overflow passes leftover dt to the next tween. Cancelled tweens do not fire `onComplete`.

### Screen Transitions & Modal Overlay

**ScreenTransition** (`src/bh/ui/screens/ScreenTransition.hx`) — enum defining transition types: `None`, `Fade`, `SlideLeft/Right/Up/Down`, `Custom`. Used with `switchTo()`, `switchScreen()`, `modalDialogWithTransition()`, `closeDialogWithTransition()`.

**Transition execution flow:**
1. `switchScreen()` computes screen diff (screens to add/remove)
2. New screens added to scene with lifecycle events; old screens removed from input routing
3. `executeTransition()` creates tweens on screen roots (fade alpha, slide position)
4. All tweens use `skipFirstDt = true` to prevent stutter
5. On complete, `transitionCleanup` removes old screens from scene

**Modal overlay:** When a dialog has `modalOverlayConfig` set, `ScreenManager` creates an `h2d.Bitmap` overlay at layer 5 (between master=4 and dialog=6). Overlay alpha animates in/out via TweenManager synchronized with dialog transition. Optional blur filter applied to underlying screen roots. Config: `color`, `alpha`, `fadeIn`, `fadeOut`, `blur`. Can be set in code (`modalOverlayConfig = {...}`) or via `.manim` `settings { overlay.color:color => ..., overlay.alpha:float => ... }`.

**Layer ordering:** `layerContent=2`, `layerMaster=4`, `layerOverlay=5`, `layerDialog=6`

### UICardHandHelper

Slay the Spire-style card hand system with drag-to-play, targeting, and card-to-card combining. Four files: `UICardHandHelper.hx` (state machine orchestrator), `UICardHandLayout.hx` (fan/linear/path positioning math), `UICardHandTargeting.hx` (targeting line visual + target zones), `UICardHandTypes.hx` (enums, typedefs, config).

**`.manim` integration:** Card visuals are programmables with `interactive()` + `bind => "status"` for auto-wired state machine. Animations use `animatedPath` elements (draw, discard, rearrange, return paths). Targeting arrow is a `.manim` programmable receiving `valid:bool`. Layout can follow a `.manim` `paths {}` path with `EvenArcLength` or `EvenRate` distribution.

**Architecture:** Per-card `CardState` (not a global lock) enables concurrent animations — draw, discard, and rearrange all run in parallel. Position-based hover detection via `getCardAtBasePosition()` with OBB hit testing using `globalToLocal()`. Drag state machine: `UIPush` → drag → card-to-card check → targeting threshold → release (play/combine/return).

**API:** `setHand()`, `drawCard()`, `discardCard()`, `updateCardParams()`, `setCardEnabled()`, `registerTargetInteractive()`, `setTargetHighlightCallback()`, `setTargetAcceptsFilter()`. Events: `CardPlayed`, `CardCombined`, `CardHoverStart/End`, `DrawAnimComplete`, `DiscardAnimComplete`.

### FloatingTextHelper

AnimatedPath-driven floating text manager for damage numbers, heal text, status effects. File: `src/bh/ui/FloatingTextHelper.hx`.

`spawn(text, font, x, y, animPath, ?color, absolutePosition)` creates text driven by an `AnimatedPath`. Two position modes: offset (`absolutePosition=false`, path relative to spawn point, use with Anchor normalization) and absolute (`absolutePosition=true`, path IS world position, use with Stretch normalization). `spawnObject(obj, x, y, animPath, absolutePosition)` for arbitrary `h2d.Object`.

Applies AnimatedPath state: position, alpha, scale, rotation. Color applied to `h2d.Text` when `colorCurve` is active. Completed instances auto-removed.

### Hot Reload

Development-only live `.manim`/`.anim` file reloading (`-D MULTIANIM_DEV`). File: `src/bh/multianim/dev/HotReload.hx`.

Components: `FileChangeDetector` (FNV hash-based change detection), `ReloadableRegistry` (tracks live `BuilderResult` instances via `ReloadSentinel` weak references for auto-unregister), `SignatureChecker` (validates parameter compatibility between old/new versions), `StateSnapshotter`/`StateRestorer` (captures and restores parameter values, slot contents, dynamic ref state across reloads).

**API:** `screenManager.addReloadListener(callback)`, `screenManager.hotReload()`, `screenManager.reload(?resource)`. Events: `ReloadStarted`, `ReloadSucceeded`, `ReloadFailed`, `ReloadNeedsRestart` (when parameter signature changes are incompatible).

## Macros

### macroBuildWithParameters

```haxe
var res = MacroUtils.macroBuildWithParameters(componentsBuilder, "ui", [], [
    checkbox1 => addCheckbox(builder, true),
    scroll1 => addScrollableList(builder, 100, 120, list4, -1),
    dropdown1 => addDropdown(builder, list100, 0)
]);
```

`macroBuildWithParameters` macro calls `MultiAnimBuilder.createWithParameters`, allows settings to override control properties, and adds objects and UIElements to the scene graph and UIScreen elements. It returns a typed anonymous struct with all named placeholders plus `builderResults`.

### ProgrammableCodeGen (Compile-Time)

`@:build(ProgrammableCodeGen.buildAll())` scans a class for `@:manim` and `@:data` field annotations:

**`@:manim("path", "name")`** generates:
- **Factory class** (e.g., `MyUI_Button`) — Stateless, holds resource loader and cached builder. Has `create(params...)` and `createFrom({...})` methods, plus static enum constants.
- **Instance class** (e.g., `MyUI_ButtonInstance`) — Extends `h2d.Object`. Has `setXxx()` setters, `get_xxx()` named element accessors, `getSlot_xxx()` slot accessors, and visibility/expression update logic.

**`@:data("path", "name" [, "pkg" [, mergeTypes]])`** generates:
- **Data class** with `public final` fields matching the data block
- **Record classes** for named record types (e.g., `UpgradesTier` for `#tier record(...)` in `#upgrades data`)
- Optional custom type package and `mergeTypes` deduplication

**MacroManimParser** is the compile-time parser used by `ProgrammableCodeGen`. It is NOT an hxparse `Parser` — it uses a simpler `peek()`/`match()`/`advance()` API on a pre-lexed token stream.

## Data Blocks

`#name data { ... }` defines static typed data at the `.manim` root level. Supports:
- Scalar fields: int, float, string, bool (type-inferred)
- Arrays: `costs: [10, 20, 40]`
- Named record types: `#tier record(name: string, cost: int, ?dmg: float)` with schema validation
- Record-typed fields: `tier { name: "None", cost: 0 }` and arrays `tier[] [{ ... }]`
- Optional fields: `?field: type` — omitted values become `null`

**Runtime access:** `builder.getData("name")` returns `Dynamic`.
**Compile-time access:** `@:data` generates typed classes.

## Curves and Paths

### Curves

1D curves map normalized 0→1 input to float output. Three types:
- **Easing-based:** Uses an `EasingType` function
- **Point-based:** Linear interpolation between `(time, value)` control points
- **Segmented:** Multiple time-ranged easing segments (optionally overlapping, with gap interpolation)

**Operations:** `multiply: [a, b]` (N-ary product), `apply: inner, outer` (composition), `invert: a` (1.0 - a(t)), `scale: a, factor`. Operations can reference other named curves or built-in easing names.

**Runtime:** `builder.getCurve("name").getValue(t)`
**Codegen:** `getCurve_<name>()` factory methods; easing-only curves baked inline at compile time.

### Paths

Path definitions support: `lineTo`, `lineAbs`, `bezier`, `bezierAbs`, `forward`, `turn`, `arc`, `checkpoint`, `close`, `moveTo`, `moveAbs`, `spiral`, `wave`.

**Path normalization:** `Path.normalize(startPoint, endPoint)` applies scale + rotation + translation so the path fits between two arbitrary points.

### Animated Paths

Animated paths control traversal timing with optional easing and timed actions (events, speed changes, particle attachment). Two modes:
- **Speed-based:** Constant speed traversal
- **Duration+easing:** `duration: 0.8` + `easing: easeInOutQuad` for time-based mode

Curve slots accept either named curves from `curves{}` or inline easing names (e.g. `alphaCurve: easeInQuad`). The `easing:` shorthand is sugar for `0.0: progressCurve:`. Multi-color curve stops allow per-segment color pairs at different rates. `createProjectilePath()` is a convenience wrapper using `Stretch` normalization.

**State fields:** `position`, `angle`, `rate`, `speed`, `scale`, `alpha`, `rotation`, `color`, `cycle`, `done`, `custom`.

**Path reverse lookup:** `path.getClosestRate(point)` finds the nearest rate (0..1) to a world point using coarse sampling + golden-section refinement.

## Easing System

`EasingType` enum with 12 named functions plus `CubicBezier(x1, y1, x2, y2)`:
- Linear, EaseIn/Out/InOutQuad, EaseIn/Out/InOutCubic, EaseIn/Out/InOutBack, EaseOutBounce, EaseOutElastic
- Cubic bezier uses Newton-Raphson solver in `FloatTools.applyEasing()`

## Inline Atlas2

`#name atlas2("file.png") { ... }` or `#name atlas2(sheet("sheetName")) { ... }` defines inline sprite atlases within `.manim` files.

**Tile entry format:** `name: x, y, w, h [, offset: ox, oy] [, orig: ow, oh] [, split: l, r, t, b] [, index: n]`

`IAtlas2` interface unifies `Atlas2` (file-based) and `InlineAtlas2` (defined in `.manim`). The builder's `getOrLoadSheet()` checks inline atlases first, then falls back to the resource loader. Works with `bitmap(sheet(...))`, `ninepatch(...)`, `stateAnim construct(...)`, and TilesIterator.

## Autotile

Autotile is a root-level manim element for procedural terrain generation. It defines a tileset that can be automatically placed based on neighbor relationships.

### Supported Formats

- **cross**: Cross layout for standard terrain (13 tiles). Tile indices: 0=N, 1=W, 2=C, 3=E, 4=S, 5-8=outer corners, 9-12=inner corners
- **blob47**: Full 47-tile autotile with all edge/corner combinations using 8-direction neighbor detection

### DSL Syntax

```
#myTerrain autotile {
    format: cross             // cross | blob47
    sheet: "terrain"          // atlas name
    prefix: "grass_"          // tile prefix (tiles named grass_0 to grass_12)
    tileSize: 16              // tile size in pixels
}

// Or with image file instead of atlas:
#myTerrain autotile {
    format: cross
    file: "terrain.png"       // image file with tiles in grid layout
    tileSize: 16
    depth: 8                  // optional: isometric depth for elevation
    mapping: [0, 1, 2, ...]   // optional: custom index mapping
}
```

### Usage

```haxe
var builder = MultiAnimBuilder.load(content, resourceLoader, "terrain.manim");

// Binary grid: 1 = terrain present, 0 = empty
var grid = [
    [0, 1, 1, 0],
    [1, 1, 1, 1],
    [0, 1, 1, 0]
];

// Build terrain TileGroup
var terrain = builder.buildAutotile("myTerrain", grid);
scene.addChild(terrain);

// For elevation with depth:
var elevation = builder.buildAutotileElevation("elevation", grid, 0);
```

### Tile Index Calculation

The `bh.base.Autotile` utility class provides:
- `getNeighborMask8(grid, x, y)` - 8-direction neighbor bitmask (N=1, NE=2, E=4, SE=8, S=16, SW=32, W=64, NW=128)
- `getCrossIndex(mask)` - Map neighbor mask to cross format tile index
- `getBlob47Index(mask)` - Map neighbor mask to blob47 tile index
