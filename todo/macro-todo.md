# ProgrammableCodeGen Macro — TODO

## Feature Comparison: Builder vs CodeGen

### Node Types — Full Parity (both builder and codegen support)

| Node Type | Incremental Update Support |
|-----------|---------------------------|
| BITMAP | Color only (solid color tiles) |
| TEXT | Text content + color |
| NINEPATCH | Width + height |
| POINT | — |
| LAYERS | — |
| MASK | — |
| FLOW | — |
| SPACER | — |
| SLOT (plain) | — |
| SLOT (parameterized) | Codegen delegates to runtime builder |
| INTERACTIVE | — |
| PLACEHOLDER | — |
| STATIC_REF | — |
| DYNAMIC_REF | Parameter propagation |
| GRAPHICS | — |
| PIXELS | — |
| PARTICLES | — |
| STATEANIM | — |
| STATEANIM_CONSTRUCT | — |
| TILEGROUP | — |
| APPLY | — |
| APPLY (conditional) | Visibility toggle |
| FINAL_VAR | — |
| REPEAT (Step/Range, static) | Compile-time unroll |
| REPEAT (Step/Range, param-dependent) | Runtime rebuild via pool |
| REPEAT (Layout/Tiles/StateAnim/Array) | Runtime delegation to builder |
| REPEAT2D (static Step/Range) | Compile-time unroll |
| REPEAT2D (param-dependent) | Runtime fallback to builder |
| RELATIVE_LAYOUTS | Used for LayoutIterator resolution |

All position updates tracked for elements with `$param` references.

### Root-Level Definitions — Codegen Support

| Definition | Builder | CodeGen | Notes |
|------------|---------|---------|-------|
| PATHS | Root-level | `createPath_name()` factory method | Full parity |
| ANIMATED_PATH | Root-level | `createAnimatedPath_name()` factory method | Full parity |
| CURVES | Root-level | `createCurve_name()` factory method | Full parity |
| DATA | Root-level | Generates typed data class | Full parity |
| PALETTE | Root-level | Not generated | Definition-only; accessed via builder `getPalette()`. Codegen doesn't need it since palettes are consumed by filters at build time. |
| AUTOTILE | Root-level | Not generated | Definition-only; works inside `bitmap()` via `AutotileRef`. Not a renderable node. |
| ATLAS2 | Root-level | Not generated | Definition-only; tiles accessed via sheet references. Builder also throws if used as non-root. |
| IMPORT | Root-level | Not handled | Imports resolved at parse time, before codegen runs. |

## Remaining Gaps

| Gap | Severity | Notes |
|-----|----------|-------|
| **AUTOTILE as tile source only** | Low | Works inside `bitmap()` via `AutotileRef`/`AutotileRegionSheet`. Not handled as top-level node type (falls through to `default: null` in `generateCreateExpr`). Fine since autotiles are definition nodes, not renderables. |
| **ATLAS2** | N/A | Definition node, not renderable. Builder throws `'atlas2 is a definition node'`. No codegen accessor for atlas2-defined tiles — tiles are accessed via sheet references instead. |
| **PALETTE in codegen** | N/A | Palettes are consumed at build time by filters (`replacePalette`). Codegen applies filters statically. No gap for typical usage. Only an issue if someone needs runtime palette access, which the generated class doesn't expose. |
| **Parameterized slot setParameter** | Low | Codegen emits a warning — parameterized slots delegate to runtime builder. `setParameter()` on slot works via `ProgrammableBuilder` at runtime, not via generated typed methods. |
| **Param-dependent coordinates in PIXELS** | Low | Codegen warns and uses `(0,0)` for param-dependent coordinate types in pixel elements. |

## Performance — Optimize Generated Code

| # | Feature | Effort | Impact | Notes |
|---|---------|--------|--------|-------|
| 1 | **Per-param visibility** | Medium | High | Generate `_applyVisibility_paramName()` that only touches elements conditioned on that param. Currently every setter calls the full `_applyVisibility()`. |
| 2 | **Per-param expressions** | Low | Medium | `_updateExpressions()` is already skipped when param has no expression refs. Next step: generate per-param `_updateExpressions_paramName()` that only recalculates expressions referencing that param, instead of all expressions. |

## Incremental Update Gaps (Builder vs Codegen)

The builder's `IncrementalUpdateContext` tracks incremental updates for specific node properties. The codegen generates `_applyVisibility()` and `_updateExpressions()` instead, which serve a similar purpose but with a different architecture.

| Feature | Builder Incremental | Codegen |
|---------|-------------------|---------|
| TEXT content/color | Tracked | Via `_updateExpressions()` |
| NINEPATCH w/h | Tracked | Via `_updateExpressions()` |
| BITMAP solid color | Tracked | Via `_updateExpressions()` |
| Position updates | Tracked | Via `_updateExpressions()` |
| Conditional visibility | Tracked | Via `_applyVisibility()` |
| DynamicRef params | Propagated | Via setter + runtime builder |
| Filter changes | Not tracked | Static only |
| Scale/alpha changes | Not tracked | Static only |
| REPEAT rebuild | Full rebuild | Pool-based rebuild |

No significant gaps — codegen and builder use different mechanisms but achieve equivalent results for supported features.
