# ProgrammableCodeGen Macro — TODO

## Remaining Gaps

| Gap | Severity | Notes |
|-----|----------|-------|
| **Definition node types** | N/A | AUTOTILE (`buildAutotile()` API), ATLAS2 (inline), ANIMATED_PATH — accessed by reference, not rendered as children. |

## Implemented

| Feature | Notes |
|---------|-------|
| **Array parameters** (`param:array=[v1,v2]`) | `PPTArray` → `Array<String>` typed field. Default as null with constructor fallback (Haxe constant-default limitation). |
| **RVElementOfArray** (`$arr[$i]`) | Resolves to runtime loop var or `this._arr[index]`. |
| **ArrayIterator in REPEAT** | `repeatable($i, array($val, $arr))` — runtime pool with `_rt_val` value variable. |
| **TEXT in runtime repeat** | `generateRuntimeChildExprs` handles TEXT nodes inside param-dependent iterators. |
| **RVFunction** (`function(gridWidth/gridHeight)`) | Resolves grid spacing from node's parent chain at compile time. Handled in both `rvToExpr` and `resolveRVStatic`. |
| **Multi-element named getters** | When multiple elements share the same `#name`, `get_name()` now returns `ProgrammableUpdatable` wrapping all elements. Single-element names still return `h2d.Object`. |
| **`@:data` metadata** | `@:data("file.manim", "dataName")` generates typed data classes with `public final` fields. Record types generate companion classes (`ClassName_RecordName`). Builder `getData()` returns `Dynamic`. |

## Phase 2: Performance — optimize generated code

| # | Feature | Effort | Impact | Notes |
|---|---------|--------|--------|-------|
| 1 | **Per-param visibility** | Medium | High | Generate `_applyVisibility_paramName()` that only touches elements conditioned on that param. Currently every setter calls the full `_applyVisibility()`. |
| 2 | **Per-param expressions** | Medium | High | Generate `_updateExpressions_paramName()` that only recalculates expressions referencing that param. Data already available in `paramRefs`. Currently setter skips call entirely if param unused, but when called, updates ALL expressions. |
| 3 | **Lazy filter updates** | Low | Low | Only update filters when their param refs change. |
