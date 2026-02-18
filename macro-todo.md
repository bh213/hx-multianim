# ProgrammableCodeGen Macro — TODO

## Remaining Gaps

| Gap | Severity | Notes |
|-----|----------|-------|
| **AUTOTILE as tile source only** | Low | Works inside `bitmap()` via `AutotileRef`/`AutotileRegionSheet`. Not handled as top-level node type (falls through to `default: null` in `generateCreateExpr`). Probably fine since autotiles are definition nodes, not renderables. |
| **ATLAS2** | N/A | Definition node, not renderable. Builder throws `'atlas2 is a definition node'`. No codegen accessor for atlas2-defined tiles — tiles are accessed via sheet references instead. |

## Performance — optimize generated code

| # | Feature | Effort | Impact | Notes |
|---|---------|--------|--------|-------|
| 1 | **Per-param visibility** | Medium | High | Generate `_applyVisibility_paramName()` that only touches elements conditioned on that param. Currently every setter calls the full `_applyVisibility()`. |
| 2 | **Per-param expressions** | Low | Medium | `_updateExpressions()` is already skipped when param has no expression refs. Next step: generate per-param `_updateExpressions_paramName()` that only recalculates expressions referencing that param, instead of all expressions. |
