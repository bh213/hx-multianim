# ProgrammableCodeGen Macro — TODO

## Remaining Gaps

| Gap | Severity | Notes |
|-----|----------|-------|
| **Param-dependent hex corner/edge** | Low | `SELECTED_HEX_CORNER` / `SELECTED_HEX_EDGE` static only. Would need runtime `HexLayout` on generated class. |
| **RVFunction** (`function(gridWidth)`) | Low | Evaluates to `0`. Rarely used. |
| **RVElementOfArray** (`$arr[0]`) | Low | Evaluates to `0`. |
| **RVArray / RVArrayReference** | Low | Evaluates to `0`. Mainly used internally by iterators. |
| **Multi-element named getters** | Low | Only single-element `get_name()` generated. Multi-element `Updatable` wrappers not created. |
| **Definition node types** | N/A | AUTOTILE (`buildAutotile()` API), ATLAS2 (inline), ANIMATED_PATH — accessed by reference, not rendered as children. |

## Phase 2: Performance — optimize generated code

| # | Feature | Effort | Impact | Notes |
|---|---------|--------|--------|-------|
| 1 | **Per-param visibility** | Medium | High | Generate `_applyVisibility_paramName()` that only touches elements conditioned on that param. Currently every setter calls the full `_applyVisibility()`. |
| 2 | **Per-param expressions** | Medium | High | Generate `_updateExpressions_paramName()` that only recalculates expressions referencing that param. Data already available in `paramRefs`. Currently setter skips call entirely if param unused, but when called, updates ALL expressions. |
| 3 | **Lazy filter updates** | Low | Low | Only update filters when their param refs change. |
