# ProgrammableCodeGen Macro — TODO

What the `@:build(ProgrammableCodeGen.buildAll())` macro supports vs what's missing.

## Architecture

- Single factory class with `@:manim("path", "name")` field annotations
- `buildAll()` generates companion classes (`ParentName_FieldName`) via `Context.defineType()`
- Factory takes `ResourceLoader`, generated `createXxx()` methods handle loading internally
- Companion `create()` receives `MultiAnimBuilder`, constructor passes `resourceLoader` to `ProgrammableBuilder` base
- Parsing via `MacroManimParser` (inline macro parser, no subprocess)

## Fully Working

- **BITMAP** — tile loading (file, sheet, sheet+index), H/V alignment
- **TEXT** — font, alignment, maxWidth, color, letterSpacing, lineSpacing, lineBreak, dropShadow, param refs in text/color
- **NINEPATCH** — sheet/tile, width/height with param expressions
- **FLOW** — all properties (maxWidth/Height, minWidth/Height, lineHeight, colWidth, layout, padding, spacing, debug, multiline)
- **LAYERS** — container with layer index assignment
- **MASK** — width/height creation, container
- **POINT** — empty container (same as builder)
- **INTERACTIVE** — MAObject with width/height/id
- **Conditionals** — `@(p=>v)`, `@(p=>[v1,v2])`, `@(p!=v)`, ranges `@(p=>10..30)`, `@else`, `@default`, `CoAny`, `CoFlag`, `CoNot`
- **Expressions** — `$param`, `+`, `-`, `*`, `/`, `div`, `%`, ternary, comparisons, parentheses
- **Properties** — scale, alpha, blendMode
- **Static create()** — factory with typed params (Bool for bool, inline constants for enums), reordered (required first)
- **Setters** — `setXxx(v)` per param, updates visibility + expressions in-place
- **REPEAT / REPEAT2D** — all iterator types (see below)
- **Self-loading factory** — `createXxx()` calls `resourceLoader.loadMultiAnim(path)` internally

### REPEAT / REPEAT2D — All Iterators Working

| Iterator | Approach | Details |
|----------|----------|---------|
| **GridIterator** | Compile-time unroll (static) or pool (param-dependent) | Offset per iteration (dx, dy) |
| **RangeIterator** | Compile-time unroll (static) or pool (param-dependent) | Numeric range (start..end, step) |
| **LayoutIterator** | Compile-time unroll | Resolves layout points from parsed AST at compile time |
| **TilesIterator** | Runtime loop | Fetches tiles from sheet at construction, creates h2d.Bitmap children |
| **StateAnimIterator** | Runtime loop | Fetches animation frames at construction, creates h2d.Bitmap children |
| **ArrayIterator** | Runtime loop | Iterates array parameter values at construction |

Static count: unrolled at compile time — N copies with loop variable substituted. Zero runtime overhead.
Param-dependent count: pre-allocated pool up to max. `_applyVisibility()` shows/hides pool items.
REPEAT2D: same approach for both axes. Static x Static → fully unrolled. Mixed → pool for param axis.

## Not Implemented — Stub Only (empty h2d.Object placeholder)

### REFERENCE
Delegates to another programmable with parameters. Builder calls `buildWithParameters(name, params)`.

For codegen: call `this.buildReference(name, params)` at construction time and store the result. The method already exists on `ProgrammableBuilder`. Updates would require rebuilding the subtree (or delegating to the referenced programmable's own generated class).

### PLACEHOLDER
Resolved via callbacks at build time. Builder calls the callback function to get a tile/object.

For codegen: generate a `setPlaceholder(name, obj)` method that lets the user provide the object. Or store the callback and invoke it at construction.

### GRAPHICS
Vector drawing primitives on h2d.Graphics. Builder supports:
- Rectangles (filled/unfilled), polygons, circles, ellipses, arcs, rounded rects, lines
- Style: filled vs line-width stroke
- Color per element

For codegen: generate the draw calls directly as macro expressions. Each graphics element becomes a `g.beginFill()` / `g.drawRect()` / etc. call. Expressions referencing params would need redraw on update.

### PIXELS
Pixel-level drawing (PixelLines). Builder supports:
- Lines, rectangles (filled/unfilled), individual pixels
- Color per element

For codegen: similar to GRAPHICS — generate draw calls. Needs `h2d.Graphics` with pixel-level operations.

### PARTICLES
Full particle system. Builder creates emitters with:
- Emitter modes (point, cone, box, circle)
- Tile loading, life/size/speed/gravity
- Color interpolation (start/mid/end)
- Fade in/out, rotation
- Force fields (attractor, repulsor, vortex, wind, turbulence)
- Bounds modes (kill, bounce, wrap)

For codegen: complex. Best approach is to delegate to a runtime helper that creates the particle system from the parsed AST. No need to inline all particle logic into generated code.

## Missing Properties

### Filters
Not applied at all. Builder supports 10 filter types:
- **outline** — `h2d.filter.Outline` or custom `PixelOutline`
- **glow** — `h2d.filter.Glow`
- **blur** — `h2d.filter.Blur`
- **dropShadow** — `h2d.filter.DropShadow`
- **saturate** — `h2d.filter.ColorMatrix`
- **brightness** — `h2d.filter.ColorMatrix`
- **replacePalette** — custom palette replacement
- **replaceColor** — custom color list replacement
- **pixelOutline** — custom `PixelOutline` filter
- **group** — `h2d.filter.Group` combining multiple filters

Node has `filters: Array<FilterDef>`. Codegen ignores it entirely. Need to generate filter creation code in constructor and optionally update if filter params reference programmable params.

### Tint
Node has `tintColor: Null<Int>`. Builder applies it to `h2d.Drawable` via cast. Codegen ignores it. Simple to add — `cast(obj, h2d.Drawable).color.setColor(tintColor)` in constructor.

### Grid/Hex/Layout Positioning
`generatePositionExpr()` only handles `OFFSET(x,y)` and `ZERO`. Returns null for:
- **SELECTED_GRID_POSITION(gridX, gridY)** — needs grid spacing from parent context
- **SELECTED_GRID_POSITION_WITH_OFFSET(gridX, gridY, offsetX, offsetY)** — same + offset
- **SELECTED_HEX_POSITION(hex)** — needs hex layout calculations (q,r,s -> x,y)
- **SELECTED_HEX_EDGE(direction, factor)** — hex edge midpoint
- **SELECTED_HEX_CORNER(count, factor)** — hex corner point
- **LAYOUT(layoutName, index)** — needs layout point lookup from LayoutTypes

Grid: resolve spacing at compile time from parent node, inline `x = gridX * spacingX, y = gridY * spacingY`.
Hex: use the `Hex.hx` math functions (already macro-compatible with the `#if macro` Point typedef).
Layout: resolve layout points at compile time from the parsed layout data.

### Position Expression Updates
When positions use `$param` references (e.g., `$w - 70, $h - 30`), the codegen sets position in the constructor but does NOT update it in `_updateExpressions()`. Need to collect position param refs and add position updates alongside other expression updates.

## Suggested Implementation Order

### Phase 1: Correctness — make codegen output match builder output

| # | Feature | Effort | Impact | Notes |
|---|---------|--------|--------|-------|
| 1 | **Tint** | Trivial | Low | One-liner: `cast(obj, h2d.Drawable).color.setColor(tintColor)` |
| 2 | **Filters** | Medium | High | Most commonly used missing feature. Static filters (no param refs) are straightforward. Param-dependent filters need update logic. |
| 3 | **Position expression updates** | Medium | High | Critical correctness bug — positions with `$param` refs don't update on setter calls. Need to add position updates to `expressionUpdates`. |
| 4 | **REFERENCE** | Medium | High | Call `this.buildReference(name, params)` at construction. Already have the method on ProgrammableBuilder. Main question: how to handle updates. |
| 5 | **GRAPHICS** | Medium | Medium | Generate `beginFill()`/`drawRect()`/etc. calls. Param-dependent graphics need clear+redraw. |
| 6 | **PIXELS** | Medium | Low | Similar to GRAPHICS. Rare in practice. |
| 7 | **Grid/Hex positioning** | Medium | Medium | Grid: inline math. Hex: call Hex.hx functions. Need parent context for grid spacing. |
| 8 | **Layout positioning** | Low | Low | Resolve layout points from parsed AST (same approach as LayoutIterator). |
| 9 | **PLACEHOLDER** | Low | Low | Generate setter method for user-provided objects. |
| 10 | **PARTICLES** | High | Medium | Delegate to runtime helper. Complex but well-isolated. |

### Phase 2: Performance — optimize generated code

| # | Feature | Effort | Impact | Notes |
|---|---------|--------|--------|-------|
| 1 | **Per-param visibility** | Medium | High | Generate `_applyVisibility_paramName()` that only touches elements conditioned on that param. Currently every setter calls the full `_applyVisibility()`. |
| 2 | **Per-param expressions** | Medium | High | Generate `_updateExpressions_paramName()` that only recalculates expressions referencing that param. Data already available in `paramRefs`. Currently setter skips call entirely if param unused, but when called, updates ALL expressions. |
| 3 | **Lazy filter updates** | Low | Low | Only update filters when their param refs change. |

## Suggested Tests

### Correctness tests (new .manim examples + visual tests)

| Test | .manim content | Validates |
|------|---------------|-----------|
| **45-codegenTint** | Bitmap with `tintColor` applied | Tint renders same as builder |
| **46-codegenFilter** | Elements with outline, glow, blur filters | Filters applied correctly |
| **47-codegenFilterParam** | Filter with param-dependent value (e.g., blur radius = `$blurAmount`) | Filter updates on setter |
| **48-codegenPosExpr** | Elements with param-dependent positions (`$w - 70, $h - 30`) | Position updates when params change |
| **49-codegenReference** | Programmable containing `reference($ref)` to another | Reference builds and renders |
| **50-codegenGraphics** | Graphics elements (rect, circle, line) | Draw calls generate correctly |
| **51-codegenGridPos** | Elements using `grid(x, y)` positioning | Grid positions calculated correctly |

### Performance tests (unit tests, not visual)

| Test | What to measure | Validates |
|------|----------------|-----------|
| **Setter call time** | Time N calls to `setHealth(i)` on a healthbar with many elements | Per-param optimization reduces work |
| **Visibility overhead** | Compare `_applyVisibility()` full vs per-param on multi-param component | Per-param visibility skips unrelated elements |
| **Codegen vs builder** | Time creation + 100 setter calls, codegen vs `MultiAnimBuilder.build()` | Codegen is faster (that's the whole point) |
| **Memory** | Compare object count: codegen companion vs builder result | Codegen doesn't create excess objects |

### How to add a correctness test

1. Create `test/examples/<N>-codegen<Name>/codegen<Name>.manim`
2. Add `@:manim("test/examples/<N>-codegen<Name>/codegen<Name>.manim", "codegen<Name>")` to `MultiProgrammable`
3. Add unit test method in `ProgrammableCodeGenTest.hx` using companion class
4. Add visual test comparing codegen output to builder output (use `macroRenderScreenshotAndCompare`)
5. Generate reference image with `test.bat gen-refs`
