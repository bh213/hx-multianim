# ProgrammableCodeGen Macro — TODO

## Remaining Gaps

None — full coordinate parity in all element types including `pixels()`.

### Fixed
- **Param-dependent coords in PIXELS** — `SELECTED_GRID_POSITION`, `NAMED_COORD`, `WITH_OFFSET`, `SELECTED_HEX_CELL_CORNER/EDGE`, `LAYOUT`, `ZERO` now all supported. Missing coord types produce compile-time errors instead of silent `(0,0)` fallback.
- **Pixel shape variable scoping bug** — `boundsExprs` used nested `macro { }` blocks which scoped variables, making them invisible to `shapeVarExprs`. Fixed by pushing individual statements.

## Performance — Optimize Generated Code

| # | Feature | Effort | Impact | Notes |
|---|---------|--------|--------|-------|
| 1 | **Per-param visibility** | Medium | High | Generate `_applyVisibility_paramName()` that only touches elements conditioned on that param. Currently every setter calls the full `_applyVisibility()`. |
| 2 | **Per-param expressions** | Low | Medium | `_updateExpressions()` is already skipped when param has no expression refs. Next step: generate per-param `_updateExpressions_paramName()` that only recalculates expressions referencing that param, instead of all expressions. |

## Incremental Update — Tracking Status

| Feature | Builder Incremental | Codegen |
|---------|-------------------|---------|
| Scale changes | Tracked via `trackIncrementalExpressions()` | Tracked via `_updateExpressions()` |
| Alpha changes | Tracked via `trackIncrementalExpressions()` | Tracked via `_updateExpressions()` |
| Filter changes | Tracked via `trackIncrementalExpressions()` | Tracked via `_updateExpressions()` |
| Tint changes | Tracked via `trackIncrementalExpressions()` | Tracked via `_updateExpressions()` |

## Parity Audit (2026-02-24)

All 86 visual tests compare builder vs codegen output — full element parity confirmed.

### Element Support — Full Parity

All renderable element types are supported in both builder and codegen:
bitmap, text, ninepatch, spacer, flow, layers, mask, graphics, pixels, interactive,
placeholder, slot (plain + parameterized + indexed + 2D), slot_content, static_ref,
dynamic_ref, repeat, repeat2d, stateanim, stateanim_construct, particles, apply,
final_var, programmable, tilegroup, relative_layouts, paths, animated_path, curves, point.

### Feature Support — Full Parity

| Feature | Status | Notes |
|---------|--------|-------|
| All coordinate systems | Parity | Grid, hex (all variants), named, layout, offset suffix |
| All expression types | Parity | Binary, ternary, callback, property access, chained methods, unary |
| All 10+ filter types | Parity | outline, glow, blur, saturate, brightness, grayscale, hue, dropShadow, pixelOutline, paletteReplace, colorReplace |
| All conditional types | Parity | @if, @ifstrict, @else, @default, range, bit flags, negation, multi-value |
| Parameterized slots | Parity | `setParameter()` works — built via `buildParameterizedSlot()` at runtime |
| DynamicRef | Parity | `getDynamicRef()` returns `BuilderResult` with full `setParameter()` support (always incremental) |
| Repeat/Repeat2D | Parity | Static unroll for step/range; pool mode for param-dependent counts; layout/tiles/anim/array iterators at runtime |
| Tilegroup | Parity | All sub-elements (bitmap, ninepatch, repeatable, repeat2d, pixels, point) |
| Particles | Parity | Delegated to builder at runtime |
| AnimatedPath | Parity | Inline codegen when static; builder fallback otherwise |
| Curves/Paths | Parity | Factory methods generated |
| Data blocks | Parity | Companion classes via `@:data` macro |
| Import | Parity | Resolved at parser level before codegen — transparent |

### Definition-Only Nodes (Not Renderable — Same in Both)

These are definition nodes, not renderable elements. Neither builder nor codegen renders them inline:
- `PALETTE` — definition only (root context)
- `AUTOTILE` — definition only (root context)
- `ATLAS2` — definition only (root context, parsed for sheet references)
- `DATA` — definition only (codegen generates companion classes)
