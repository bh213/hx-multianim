# ProgrammableCodeGen Macro — TODO

## Remaining Gaps

| Gap | Severity | Notes |
|-----|----------|-------|
| **Param-dependent grid/layout in PIXELS** | Low | Codegen warns and uses `(0,0)` for `SELECTED_GRID_POSITION` and `LAYOUT` coordinate types in pixel elements when param-dependent. Hex types now supported. |

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
