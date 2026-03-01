# Performance

| # | Item | Summary | Impact | Effort |
|---|------|---------|--------|--------|
| 1 | Per-param visibility | Generate per-param `_applyVisibility_X()` instead of full sweep | High | Medium |
| 2 | Per-param expressions | Generate per-param `_updateExpressions_X()` for targeted recalc | Medium | Low |
| 3 | Heaps BitmapData willReadFrequently | Upstream Heaps issue: `BitmapData` creates canvas 2D context without `willReadFrequently: true`, causing browser warnings and slow `getImageData` readback | Low | Low |

## Codegen — Optimize Generated Code

### Per-param visibility
Generate `_applyVisibility_paramName()` that only touches elements conditioned on that param. Currently every setter calls the full `_applyVisibility()`.
**Effort:** Medium | **Impact:** High

### Per-param expressions
`_updateExpressions()` is already skipped when param has no expression refs. Next step: generate per-param `_updateExpressions_paramName()` that only recalculates expressions referencing that param, instead of all expressions.
**Effort:** Low | **Impact:** Medium

### Heaps BitmapData willReadFrequently
Upstream Heaps bug: `hxd/BitmapData.hx` calls `canvas.getContext2d()` without `{ willReadFrequently: true }`. This causes Chrome warnings and potentially slow GPU→CPU readback on every `getImageData()` call. Fix is one line in Heaps — either patch locally or submit upstream PR.
**Effort:** Low | **Impact:** Low
