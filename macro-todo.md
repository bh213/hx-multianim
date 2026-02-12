# ProgrammableCodeGen Macro — TODO

## Remaining Gaps

| Gap | Severity | Notes |
|-----|----------|-------|
| **RVFunction** (`function(gridWidth)`) | Low | Evaluates to `0`. Rarely used. |
| **Multi-element named getters** | Low | Only single-element `get_name()` generated. Multi-element `Updatable` wrappers not created. |
| **Definition node types** | N/A | AUTOTILE (`buildAutotile()` API), ATLAS2 (inline), ANIMATED_PATH — accessed by reference, not rendered as children. |

## Implemented

| Feature | Notes |
|---------|-------|
| **Array parameters** (`param:array=[v1,v2]`) | `PPTArray` → `Array<String>` typed field. Default as null with constructor fallback (Haxe constant-default limitation). |
| **RVElementOfArray** (`$arr[$i]`) | Resolves to runtime loop var or `this._arr[index]`. |
| **ArrayIterator in REPEAT** | `repeatable($i, array($val, $arr))` — runtime pool with `_rt_val` value variable. |
| **TEXT in runtime repeat** | `generateRuntimeChildExprs` handles TEXT nodes inside param-dependent iterators. |

## Phase 2: Performance — optimize generated code

| # | Feature | Effort | Impact | Notes |
|---|---------|--------|--------|-------|
| 1 | **Per-param visibility** | Medium | High | Generate `_applyVisibility_paramName()` that only touches elements conditioned on that param. Currently every setter calls the full `_applyVisibility()`. |
| 2 | **Per-param expressions** | Medium | High | Generate `_updateExpressions_paramName()` that only recalculates expressions referencing that param. Data already available in `paramRefs`. Currently setter skips call entirely if param unused, but when called, updates ALL expressions. |
| 3 | **Lazy filter updates** | Low | Low | Only update filters when their param refs change. |
