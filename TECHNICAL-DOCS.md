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

Returned by `buildWithParameters()`. Contains the built h2d object tree and provides access to named elements, slots, components, and updatables.

**Key methods:**
- `getUpdatable(name)` / `getUpdatableByIndex(name, index)` — Access named elements for runtime updates
- `getSlot(name, ?index)` — Access slot containers (`SlotHandle`)
- `getComponent(name)` — Access component sub-results (`BuilderResult`)
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

### Component System

Components (`component($ref, params)`) embed programmables with incremental mode enabled automatically. The sub-result is stored and accessible via `getComponent("name")`. This enables runtime parameter updates on embedded elements without rebuilding.

## UIElements

UI elements implement the `UIElement` interface for event handling within the screen system.

**Key interfaces:**
- `UIElement` — Base interface for all interactive UI elements
- `StandardUIElementEvents` — Standard event emission (UIClick, UIEntering, UILeaving, etc.)
- `UIElementIdentifiable` — Opt-in interface exposing `id`, `prefix`, and `metadata`
- `UIElementSubElements` — For composite elements that contain child UIElements

**Element types:** Button, Checkbox, Slider, RadioButtons, ScrollableList, Dropdown, Draggable, InteractiveWrapper

### Dropdown

Dropdown control consists of a closed-like button and scrollable panel. The dropdown moves the panel to a different layer and keeps position in sync with `PositionLinkObject`.

### Elements handling by UIScreen

If elements are not showing or reacting to events, check if they have been added to UIScreen's elements.

### Interactive Wrapper

`UIInteractiveWrapper` wraps `MAInteractive` objects as UIElements. It implements `UIElementIdentifiable` to expose `id`, `prefix`, and typed `metadata` (a `BuilderResolvedSettings` map with `RSVString/RSVInt/RSVFloat` values).

Screen methods for managing interactives:
- `addInteractive(obj, prefix)` — Wraps a single MAInteractive
- `addInteractives(result, prefix)` — Wraps all interactives from a BuilderResult
- `removeInteractives(prefix)` — Removes wrappers by prefix

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

**Runtime:** `builder.getCurve("name").getValue(t)`
**Codegen:** `getCurve_<name>()` factory methods; easing-only curves baked inline at compile time.

### Paths

Path definitions support: `lineTo`, `lineAbs`, `bezier`, `bezierAbs`, `forward`, `turn`, `arc`, `checkpoint`, `close`, `moveTo`, `moveAbs`, `spiral`, `wave`.

**Path normalization:** `Path.normalize(startPoint, endPoint)` applies scale + rotation + translation so the path fits between two arbitrary points.

### Animated Paths

Animated paths control traversal timing with optional easing and timed actions (events, speed changes, particle attachment). Two modes:
- **Speed-based:** Constant speed traversal
- **Duration+easing:** `duration: 0.8` + `easing: easeInOutQuad` for time-based mode

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
