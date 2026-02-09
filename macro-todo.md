# ProgrammableCodeGen Macro — TODO

What the `@:build(ProgrammableCodeGen.build(...))` macro supports vs what's missing.

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

## Partially Working

### REPEAT / REPEAT2D
Iterates children N times with positioning. **Supported iterators:**
- **GridIterator** — offset per iteration (dx, dy) — static count: compile-time unroll; param-dependent: pool with show/hide
- **RangeIterator** — numeric range (start..end, step) — static: compile-time unroll; param-dependent: pool

**Not yet supported iterators (fallback to empty placeholder):**
- **LayoutIterator** — positions from layout points
- **ArrayIterator** — iterate array parameter values
- **StateAnimIterator** — iterate animation frames
- **TilesIterator** — iterate sprite sheet tiles

Implementation details:
- **Static count**: unrolled at compile time — N copies of children with loop variable substituted to literal. Zero runtime overhead.
- **Param-dependent count**: pre-allocated pool up to max (from param default value). `_applyVisibility()` shows/hides pool items based on current count. Efficient updates — no object creation/deletion, only visibility toggling.
- **REPEAT2D**: same approach for both axes. Static x Static → fully unrolled. Mixed → pool for param-dependent axis.

### REFERENCE
Delegates to another programmable with parameters. Builder calls `buildWithParameters(name, params)`.

For codegen: could call `access.buildReference(name, params)` at construction time and store the result. Updates would require rebuilding the subtree (or delegating to the referenced programmable's own generated class if it also uses codegen).

### PLACEHOLDER
Resolved via callbacks at build time. Builder calls the callback function to get a tile/object.

For codegen: generate a `setPlaceholder(name, obj)` method that lets the user provide the object. Or store the callback and invoke it at construction.

### GRAPHICS
Vector drawing primitives on h2d.Graphics. Builder supports:
- Rectangles (filled/unfilled), polygons, circles, ellipses, arcs, rounded rects, lines
- Style: filled vs line-width stroke
- Color per element

For codegen: generate the draw calls directly as macro expressions. Straightforward — each graphics element becomes a `g.beginFill()` / `g.drawRect()` / etc. call. Expressions referencing params would need redraw on update.

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

For codegen: complex. Best approach is probably to store the ParticlesDef and delegate to a runtime helper that creates the particle system from the def. No need to inline all particle logic into generated code.

## Missing Properties

### Filters
Not applied at all. Builder supports 9 filter types:
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
Node has `tintColor: Null<Int>`. Builder applies it to `h2d.Drawable` via cast. Codegen ignores it. Simple to add — just `cast(obj, h2d.Drawable).color.setColor(tintColor)` in constructor.

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

## Priority Order (suggested)

1. **Filters** — most commonly used missing feature, straightforward to add
2. **Tint** — trivial, one-liner
3. **Position expression updates** — important for correctness when params change positions
4. **GRAPHICS** — direct draw call generation
5. **PIXELS** — similar to graphics
6. **REPEAT LayoutIterator/ArrayIterator** — needs layout data or array resolution at compile time
7. **Grid/Hex positioning** — needs context propagation
8. **Layout positioning** — needs layout data at compile time
9. **REFERENCE** — delegation to builder or other generated class
10. **PLACEHOLDER** — callback-based, needs API design
11. **REPEAT StateAnimIterator/TilesIterator** — needs asset access at compile time
12. **PARTICLES** — delegate to runtime helper

## Efficiency Improvements

Currently `_applyVisibility()` and `_updateExpressions()` update ALL elements on every setter call. Could generate per-param methods:
- `_applyVisibility_status()` — only touches elements whose condition references `status`
- `_updateExpressions_health()` — only recalculates expressions referencing `health`

The data is already available (`visibilityEntries` tracks conditions, `expressionUpdates` has `paramRefs`). Each setter would call only its relevant sub-methods.
