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
- **REFERENCE** — delegates to `ProgrammableBuilder.buildReference()` at construction, builds parameter map at runtime
- **GRAPHICS** — generates `h2d.Graphics` draw calls (beginFill/drawRect/drawCircle/etc.), supports filled vs stroked
- **PLACEHOLDER** — delegates to `ProgrammableBuilder.buildPlaceholderVia*()` methods, supports PRSCallback/PRSCallbackWithIndex/PRSBuilderParameterSource with PHTileSource/PHNothing fallback
- **Conditionals** — `@(p=>v)`, `@(p=>[v1,v2])`, `@(p!=v)`, ranges `@(p=>10..30)`, `@else`, `@default`, `CoAny`, `CoFlag`, `CoNot`
- **Expressions** — `$param`, `+`, `-`, `*`, `/`, `div`, `%`, ternary, comparisons, parentheses
- **Properties** — scale, alpha, blendMode, tint (with param-dependent updates), filters (all 10 types, with param-dependent updates)
- **Instance create()** — `mp.button.create(params)` with typed params (Bool for bool, inline constants for enums), reordered (required first)
- **Setters** — `setXxx(v)` per param, updates visibility + expressions in-place
- **REPEAT / REPEAT2D** — all iterator types (see below)
- **Instance-based factory** — `@:manim` fields are companion objects, `create()` calls `resourceLoader.loadMultiAnim(path)` internally, returns `this` for chaining

### Positioning — All Coordinate Types

| Coordinate | Support | Notes |
|-----------|---------|-------|
| **ZERO** | Full | No-op |
| **OFFSET(x, y)** | Full | With param-dependent expression updates |
| **SELECTED_GRID_POSITION** | Full | Resolves grid spacing from `#defaultLayout` at compile time |
| **SELECTED_GRID_POSITION_WITH_OFFSET** | Full | Same + offset expressions |
| **SELECTED_HEX_POSITION** | Full | Resolves hex→pixel at compile time via `HexLayout.hexToPixel()` |
| **SELECTED_HEX_CORNER** | Static only | Resolves at compile time; warns on param-dependent |
| **SELECTED_HEX_EDGE** | Static only | Resolves at compile time; warns on param-dependent |
| **LAYOUT(name, index)** | Static only | Resolves layout point at compile time from parsed AST |

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

### Param-Dependent Hex Corner/Edge
`SELECTED_HEX_CORNER` and `SELECTED_HEX_EDGE` only work with static (compile-time resolvable) values. Param-dependent values would require storing a `HexLayout` on the generated class for runtime calculation.

### FilterPaletteReplace
`FilterPaletteReplace` falls back to null in codegen because it needs palette data from the builder at runtime.

## Phase 2: Performance — optimize generated code

| # | Feature | Effort | Impact | Notes |
|---|---------|--------|--------|-------|
| 1 | **Per-param visibility** | Medium | High | Generate `_applyVisibility_paramName()` that only touches elements conditioned on that param. Currently every setter calls the full `_applyVisibility()`. |
| 2 | **Per-param expressions** | Medium | High | Generate `_updateExpressions_paramName()` that only recalculates expressions referencing that param. Data already available in `paramRefs`. Currently setter skips call entirely if param unused, but when called, updates ALL expressions. |
| 3 | **Lazy filter updates** | Low | Low | Only update filters when their param refs change. |

## How to add a correctness test

1. Create `test/examples/<N>-codegen<Name>/codegen<Name>.manim`
2. Add `@:manim("test/examples/<N>-codegen<Name>/codegen<Name>.manim", "codegen<Name>")` to `MultiProgrammable`
3. Add unit test method in `ProgrammableCodeGenTest.hx` using companion class
4. Add visual test comparing codegen output to builder output (use `builderAndMacroScreenshotAndCompare`)
5. Generate reference image with `test.bat gen-refs`

### Current codegen tests

| # | Test | Covers |
|---|------|--------|
| 38 | codegenButton | Bitmap, text, ninepatch, conditionals, expressions |
| 39 | codegenHealthbar | Ninepatch, expressions, param-dependent width |
| 40 | codegenDialog | Flow, layers, mask, text, ninepatch |
| 41 | codegenRepeat | Grid/range/layout/tiles/stateanim/array iterators |
| 42 | codegenRepeat2d | 2D grid × grid, range × range |
| 43 | codegenLayout | Layout positioning |
| 44 | codegenTilesIter | TilesIterator with bitmap |
| 46 | codegenGraphics | Graphics draw calls (filled/stroked) |
| 47 | codegenReference | Reference to other programmables |
| 48 | codegenFilterParam | Param-dependent filters (outline, blur, tint) |
| 49 | codegenGridPos | Grid coordinate positioning from #defaultLayout |
| 50 | codegenHexPos | Hex corner/edge positioning (pointy + flat) |
| 51 | codegenTextOpts | letterSpacing, lineSpacing, lineBreak, dropShadow |
| 52 | codegenBoolFloat | PPTBool conditionals, PPTFloat in @alpha() and expressions |
| 53 | codegenRangeFlags | PPTRange conditionals + expressions, PPTFlags declaration |
