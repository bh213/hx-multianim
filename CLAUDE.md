# Claude AI Instructions for hx-multianim

## Project Overview

**hx-multianim** is a Haxe library for creating animations and pixel art UI elements using the [Heaps](https://heaps.io/) framework. It provides a custom `.manim` language for defining state animations and programmable UI components.

## Key Technologies

- **Language**: Haxe
- **Framework**: Heaps (game/graphics framework)
- **Parser**: Custom hand-written lexer/parser in `MacroManimParser.hx` (runs both at compile-time and runtime)
- **Package Manager**: Lix (recommended)

## Project Structure

| Path | Description |
|------|-------------|
| `src/bh/multianim/MultiAnimParser.hx` | Parser facade — delegates to MacroManimParser |
| `src/bh/multianim/MultiAnimBuilder.hx` | Builder for resolving parsed structures |
| `src/bh/multianim/MacroManimParser.hx` | Main parser for `.manim` files (used at both compile-time and runtime) |
| `src/bh/multianim/ProgrammableCodeGen.hx` | Macro code generation for `@:manim`/`@:data` |
| `src/bh/multianim/ProgrammableBuilder.hx` | Base class for macro-generated factories |
| `src/bh/stateanim/AnimParser.hx` | Parser for `.anim` state animation files |
| `test/` | Test suite |

## Build & Run Commands

```bash
# Compile the library
haxe ./hx-multianim.hxml

# Run tests (parsing and rendering verification)
test.bat run        # Run all tests
test.bat gen-refs   # Generate reference images
test.bat report     # Open test report in browser

```

Playground lives in a separate repository: `../hx-multianim-playground`.

## Parser Architecture

The `.manim` parser is a custom hand-written lexer/parser in `MacroManimParser.hx`. It uses a token-based approach with `peek()`, `advance()`, `match()`, and `expect()` for parsing. The same parser runs at both compile-time (for `@:manim` macro codegen) and runtime (via `MultiAnimParser.parseFile()` which delegates to `MacroManimParser.parseFile()`).

The `.anim` state animation parser in `AnimParser.hx` is a separate hand-written parser.

## Workflow

1. **Parsing**: `MacroManimParser` converts `.manim` file text to AST with `Node` structures
2. **Building**: `MultiAnimBuilder` resolves references, expressions, and type conversions (runtime)
3. **Macro codegen**: `MacroManimParser` parses `.manim` at compile time, `ProgrammableCodeGen` generates typed Haxe classes

## File Formats

### `.manim` - Multi Animation / UI Elements
Used for programmable UI components, layouts, palettes, and paths.

### `.anim` - State Animations
Used for sprite state animations with playlists. Structure:

```anim
sheet: sheetName
states: stateName(value1, value2)
center: x,y
allowedExtraPoints: [point1, point2]

animation {
    name: animationName
    fps: 20
    loop: yes | <number>
    playlist {
        sheet: "sprite_$$state$$_name"
        event <name> trigger | random x,y,radius | x,y
    }
    extrapoints {
        @(state=>value) pointName: x,y
        @(state != value) pointName: x,y
        @(state=>[v1,v2]) pointName: x,y
    }
}
```

**Key `.anim` features:**
- `$$stateName$$` - State variable interpolation in sheet names
- `extrapoints` - Named points for effects/interactions (bullets, particles, etc.)
- Conditionals: `@(state=>value)`, `@(state != value)` negation, `@(state=>[v1,v2])` multi-value, `@(state != [v1,v2])` negated multi-value

## .manim Language Quick Reference

### Programmable Elements

```manim
#name programmable(param:type=default) {
  @(condition) element(params): x,y
}
```

**Parameter types**: `uint`, `int`, `float`, `bool`, `string`, `color`, `tile`, enum (`[val1,val2]`), range (`1..5`), flags

### Common Elements

| Element | Description |
|---------|-------------|
| `bitmap(source, [center])` | Display image |
| `text(font, text, color, [align, maxWidth])` | Text element |
| `ninepatch(sheet, tile, w, h)` | 9-patch scalable |
| `placeholder(size, source)` | Dynamic placeholder |
| `staticRef($ref)` | Static embed of another programmable |
| `dynamicRef($ref, params)` | Dynamic embed with runtime `setParameter()` support |
| `#name slot` / `#name[$i] slot` | Swappable container (indexed variant for repeatables) |
| `#name slot(param:type=default, ...)` | Parameterized slot with visual states |
| `spacer(w, h)` | Empty space inside `flow` containers |
| `interactive(w, h, id [, debug] [, key=>val ...])` | Hit-test region with optional metadata |
| `layers()` | Z-ordering container |
| `mask(w, h)` | Clipping mask rectangle |
| `flow(...)` | Layout flow container |
| `repeatable($var, iterator)` | Loop elements |
| `tilegroup` | Optimized tile grouping (supports `bitmap`, `ninepatch`, `repeatable`, `repeatable2d`, `pixels`, `point`) |
| `stateanim construct(...)` | Inline state animation |
| `point` | Positioning point |
| `apply(...)` | Apply properties to parent |
| `graphics(...)` | Vector graphics |
| `pixels(...)` | Pixel primitives |
| `particles {...}` | Particle effects |
| `@final name = expr` | Immutable named constant |
| `#name data {...}` | Static typed data block |
| `#name atlas2("file") {...}` | Inline sprite atlas |
| `curves {...}` | 1D curve definitions |
| `paths {...}` | Path definitions |
| `#name animatedPath {...}` | Animated path with curves/events |
| `import "file" as "name"` | Import external .manim |

### Conditionals

```manim
@(param=>value)           # Match when param equals value
@if(param=>value)         # Explicit @if (same as @())
@ifstrict(param=>value)   # Strict matching (must match ALL params)
@(param != value)         # Match when param NOT equals value
@(param=>[v1,v2])         # Match multiple values
@(param >= 30)            # Greater than or equal
@(param <= 30)            # Less than or equal
@(param > 30)             # Strictly greater than
@(param < 30)             # Strictly less than
@(param => 10..30)        # Range match (10 <= param <= 30)
@else                     # Matches when preceding @() didn't match
@else(param=>value)       # Else-if with conditions
@default                  # Final fallback
```

### Expressions

- Operators: `+`, `-`, `*`, `/`, `%`, `div`
- References: `$paramName`
- Ternary: `?(condition) trueValue : falseValue`
- Callbacks: `callback("name")`, `callback("name", $index)`

### Coordinate Systems

- Offset: `x,y`
- Grid: `$grid.pos(x, y [, offsetX, offsetY])` (requires `grid: spacingX, spacingY` in body)
- Grid properties: `$grid.width`, `$grid.height`
- Hex: `$hex.cube(q, r, s)`, `$hex.corner(index, scale)`, `$hex.edge(direction, scale)` (requires `hex: orientation(w, h)` in body)
- Hex offset/doubled: `$hex.offset(col, row, even|odd)`, `$hex.doubled(col, row)`
- Hex properties: `$hex.width`, `$hex.height`
- Named systems: `grid: #name spacingX, spacingY`, `hex: #name orientation(w, h)`
- Value extraction: `$grid.pos(x, y).x`, `$hex.corner(0, 1.0).y`
- Context: `$ctx.width`, `$ctx.height`, `$ctx.random(min, max)`, `$ctx.font("name").lineHeight`, `$ctx.font("name").baseLine`
- Layout: `layout(layoutName [, index])`

### Filters

`outline`, `glow`, `blur`, `saturate`, `brightness`, `grayscale`, `hue`, `dropShadow`, `replacePalette`, `replaceColor`, `pixelOutline`, `group`

### Particles Quick Reference

```manim
#effectName particles {
    count: 100
    emit: point(0, 0) | cone(dist, distRand, angle, angleRand) | box(w, h, angle, angleRand) | circle(r, rRand, angle, angleRand)
    tiles: file("particle.png")
    loop: true
    maxLife: 2.0
    speed: 50
    speedRandom: 0.3
    gravity: 100
    gravityAngle: 90
    size: 0.5
    sizeRandom: 0.2
    blendMode: add | alpha
    fadeIn: 0.1
    fadeOut: 0.8
    colorStart: #FF4400
    colorMid: #FFAA00
    colorMidPos: 0.4
    colorEnd: #FFFF88
    sizeCurve: [(0, 0.5), (0.5, 1.2), (1.0, 0.2)]
    velocityCurve: [(0, 1.0), (1.0, 0.3)]
    forceFields: [turbulence(30, 0.02, 2.0), wind(10, 0), vortex(0, 0, 100, 150), attractor(0, 0, 50, 100), repulsor(0, 0, 80, 120), pathguide(myPath, 80, 120, 50)]
    boundsMode: none | kill | bounce(0.6) | wrap
    boundsMinX: -100
    boundsMaxX: 300
    rotationSpeed: 90
    rotateAuto: true
    relative: true
    trailEnabled: true
    trailLength: 0.5
    trailFadeOut: true
    subEmitters: [{ groupId: "sparks", trigger: ondeath, probability: 0.8 }]
}
```

See `docs/manim.md` for full particles documentation.

### Animated Paths Quick Reference

```manim
#animName animatedPath {
    path: myPath
    type: time
    duration: 1.0
    loop: false
    pingPong: false
    easing: easeOutCubic
    0.0: scaleCurve: grow, alphaCurve: easeInQuad
    0.5: event("halfway")
    0.0: colorCurve: linear, #FF0000, #00FF00
    0.5: colorCurve: easeInQuad, #00FF00, #0000FF
    0.0: custom("myValue"): customCurve
}
```

**Properties:** `path` (required), `type: time|distance`, `duration`, `speed`, `loop: bool`, `pingPong: bool`, `easing: <easingName>` (shorthand for `0.0: progressCurve: <easingName>`)

**Curve slots** (at rate 0.0–1.0 or checkpoint name): `speedCurve`, `scaleCurve`, `alphaCurve`, `rotationCurve`, `progressCurve`, `colorCurve: curve, startColor, endColor`, `custom("name"): curve`. Curve references can be named curves from `curves{}` or **inline easing names** (e.g. `easeInQuad`). Multiple `colorCurve` assignments at different rates create per-segment color interpolation.

**Events:** `event("name")`. Built-in: `pathStart`, `pathEnd`, `cycleStart`, `cycleEnd`

**State fields:** `position`, `angle`, `rate`, `speed`, `scale`, `alpha`, `rotation`, `color`, `cycle`, `done`, `custom`

**Runtime API:**
- Builder: `builder.createAnimatedPath("name", ?startPoint, ?endPoint)`
- Projectile helper: `builder.createProjectilePath("name", startPoint, endPoint)` (Stretch normalization)
- Codegen: `factory.createAnimatedPath_name(?startPoint, ?endPoint)`
- `ap.update(dt)` → `AnimatedPathState`, `ap.seek(rate)` → state without side effects, `ap.reset()` for reuse
- Reverse lookup: `path.getClosestRate(worldPoint)` → closest rate (0..1)

See `docs/manim.md` for full animated paths documentation.

## UI Elements Notes

- **Generic settings pass-through**: Any setting not recognized as control or behavioral is automatically forwarded to the underlying programmable as an extra parameter. The programmable must declare a matching parameter; mismatches throw with programmable name + available params.
- **Prefixed settings**: `item.fontColor`, `scrollbar.thickness` — dotted keys route to sub-builders in multi-programmable components (dropdown, scrollableList). Registered prefixes: dropdown has `dropdown`, `item`, `scrollbar` (main=panel); scrollableList has `item`, `scrollbar` (main=panel).
- **Multi-forward settings**: Unprefixed `font`/`fontColor` on dropdown/scrollableList forward to ALL relevant sub-builders for backwards compatibility.
- **Button**: `buildName` and `text` are control settings; everything else (e.g. `width`, `height`, `font`, `fontColor`) passes through to `#button` programmable.
- **Scrollable list / Dropdown**: `font`, `fontColor` forwarded to both item builder and dropdown button builder. The `#dropdown` programmable accepts `font`/`fontColor` params for the selected item text.
- **Settings `color` type**: `fontColor:color=>white` — parsed via `parseColorOrReference()`, stored as `SVTInt`. Supports named colors (`white`, `red`, etc.), hex (`#ff7f50`, `0xFF0000`).
- **Dropdown**: Uses closed button + scrollable panel, moves panel to different layer
- **UIScreen**: If elements don't show or react to events, check if added to UIScreen's elements
- **Macros**: `MacroUtils.macroBuildWithParameters` maps `.manim` elements to Haxe code — auto-injects `ResolvedSettings` parameter
- **Settings naming**: `buildName` for single builder override, `<element>BuildName` for multiple (e.g. `radioBuildName`, `radioButtonBuildName`)
- **Slider**: Supports custom float range (`min`, `max`, `step` settings). Internally maps to 0-100 grid. Implements both `UIElementNumberValue` (int) and `UIElementFloatValue` (float). Uses incremental mode for efficient redraws. Emits both `UIChangeValue(Int)` and `UIChangeFloatValue(Float)`.
- **Progress bar**: Display-only component (`UIMultiAnimProgressBar`). Uses full rebuild (not incremental) because `bitmap(generated(color(...)))` is not tracked. Screen helper: `addProgressBar(builder, settings, initialValue)`.
- **Scrollable list scrollbar**: Built with incremental mode — scroll events use `setParameter("scrollPosition", ...)` instead of full rebuild.
- **List item tiles**: `UIElementListItem.tileRef` uses `TileRef` enum (`TRFile`, `TRSheet`, `TRSheetIndex`, `TRTile`, `TRGeneratedRect`, `TRGeneratedRectColor`) for structured tile references. Legacy `tileName` (plain string) still works. `TileHelper` class provides static helpers for builder params: `TileHelper.sheet("atlas", "tile")`, `TileHelper.file("img.png")`, `TileHelper.generatedRect(w, h)`, `TileHelper.generatedRectColor(w, h, color)`.
- **`tile` parameter type**: `.manim` `name:tile` declares a tile parameter (no default allowed). Use with `bitmap($name)`. In codegen maps to `Dynamic` (pass `h2d.Tile`). In builder pass via `TileHelper`.
- **Full component reference**: See `docs/manim.md` "UI Components" section for all parameter contracts, settings, and events

## Guidelines for Modifications

1. **Always compile after changes**: `haxe hx-multianim.hxml`
2. **Run visual tests**: Verify with `test.bat run`
3. **Keep types consistent**: Use established enum/typedef patterns
4. **Document complex parsing**: Add comments explaining stream patterns
5. **Update related files**: Changes to parser may require builder/UI updates
6. **Add tests for new features**: See "Adding a New Test" section below

## Adding a New Test

Tests are visual screenshot comparisons. To add a new test:

1. **Create test directory**: `test/examples/<N>-<testName>/` (N = next number, e.g., `22-myFeatureDemo`)

2. **Create `.manim` file**: `test/examples/<N>-<testName>/<testName>.manim` with a programmable named after the test feature

3. **Add test method** in `test/src/bh/test/examples/AllExamplesTest.hx`:
   ```haxe
   @Test
   public function test<N>_<TestName>(async:utest.Async) {
       this.testName = "<testName>";
       this.referenceDir = "test/examples/<N>-<testName>";
       buildRenderScreenshotAndCompare("test/examples/<N>-<testName>/<testName>.manim", "<programmableName>", async, 1280, 720);
   }
   ```

4. **Generate reference image** (test.bat gen-refs uses dynamic loop — no manual entries needed):
   - Run `test.bat run` to generate screenshot
   - Run `test.bat gen-refs` to copy as reference
   - Verify with `test.bat run` again (should pass)

## Debug Tracing

Enable debug traces by adding to HXML:
```hxml
-D MULTIANIM_TRACE
```

## Current TODO Items

### Fixes Needed
- Repeatable step scale for dx/dy
- HTML text: standalone `HTMLTEXT` element type is deprecated/commented out (the `text(..., html: true)` parameter approach works)
- Double reload issue
- Hex coordinate system offset support
- Conditional not working with repeatable vars (e.g., `@(index >= 3)`)

### Next Features
- Particle sub-emitters (parsing and building complete, runtime spawning in `Particles.hx` not yet implemented)
- Generic components support
- Bit expressions (anyBit/allBits for grid directions)

## UI Notes — Interactives

`interactive()` elements create hit-test regions with optional typed metadata:

```manim
interactive(200, 30, "myBtn")
interactive(200, 30, "myBtn", debug)
interactive(200, 30, "myBtn", action => "buy", label => "Buy Item")
interactive(200, 30, $idx, price:int => 100, weight:float => 1.5, action => "craft")
```

Metadata supports typed values matching the settings system: `key => val` (string default), `key:int => N`, `key:float => N`, `key:string => "s"`. Keys and values can be `$references`.

**UI integration:**
- `UIInteractiveWrapper` — thin wrapper implementing `UIElement`, `StandardUIElementEvents`, `UIElementIdentifiable`
- `UIElementIdentifiable` — opt-in interface with `id`, `prefix`, `metadata:BuilderResolvedSettings`
- Screen methods: `addInteractive()`, `addInteractives(result, prefix)`, `removeInteractives(prefix)`
- Events: emits standard `UIClick`, `UIEntering`, `UILeaving` — check `source` for `UIElementIdentifiable` to get `id`/`metadata`

## Notes — Indexed Names, Slots, Components

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
- Codegen: warning emitted, `setParameter()` not supported (use runtime builder)

**Drag-and-drop** — `UIMultiAnimDraggable` with slot integration:
- `addDropZonesFromSlots("baseName", builderResult, ?accepts)` — batch drop zone creation
- `createFromSlot(slot)` — creates draggable from slot content, tracks `sourceSlot`
- `swapMode` — swaps contents when dropping onto an occupied slot
- Zone highlight callbacks: `onDragStartHighlightZones`, `onDragEndHighlightZones` on draggable
- Per-zone: `DropZone.onZoneHighlight` callback for hover state

**Dynamic refs** — `dynamicRef($ref, params)` embeds with incremental mode for runtime parameter updates:
- Builder: `result.getDynamicRef("name").setParameter("param", value)`
- Batch updates: `beginUpdate()` / `endUpdate()` defers re-evaluation
- Codegen: generates runtime builder call, returns `BuilderResult`

**Flow improvements** — new optional params on `flow()`:
- `overflow: expand|limit|scroll|hidden`, `fillWidth: true`, `fillHeight: true`, `reverse: true`
- `spacer(w, h)` element for fixed spacing inside flows

## Playground

Interactive playground at: https://bh213.github.io/hx-multianim/

Playground source lives in a separate repository: `../hx-multianim-playground`.
