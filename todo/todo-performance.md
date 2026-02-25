# Performance

| # | Item | Summary | Impact | Effort |
|---|------|---------|--------|--------|
| 1 | Per-param visibility | Generate per-param `_applyVisibility_X()` instead of full sweep | High | Medium |
| 2 | Per-param expressions | Generate per-param `_updateExpressions_X()` for targeted recalc | Medium | Low |

## Codegen — Optimize Generated Code

### Per-param visibility
Generate `_applyVisibility_paramName()` that only touches elements conditioned on that param. Currently every setter calls the full `_applyVisibility()`.
**Effort:** Medium | **Impact:** High

### Per-param expressions
`_updateExpressions()` is already skipped when param has no expression refs. Next step: generate per-param `_updateExpressions_paramName()` that only recalculates expressions referencing that param, instead of all expressions.
**Effort:** Low | **Impact:** Medium
