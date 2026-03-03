# Test Review: Workflow Branches, TODOs, and Builder/Inc/Codegen Parity


## Test Coverage Matrix

### Visual tests by path comparison mode

| Mode | Count | Notes |
|------|-------|-------|
| Builder + Codegen (3-image) | 91 | `simpleMacroTest`, `multiInstanceMacroTest`, `layoutMacroTest`, or custom builder+macro flow |
| Builder-only (no codegen) | 2 | test62 (dataBlock, no visual), test77 (pvFactorySettings, no visual), test89 (textInput, builder-only visual) |
| Unit-only (no visual) | 2 | test62, test77 |

### Tests missing codegen (`@:manim`) in MultiProgrammable.hx

| # | Test | Reason | Action needed? |
|---|------|--------|---------------|
| 77 | pvFactorySettings | PVFactory is builder-only API (no codegen support) | No — by design |
| 89 | textInput | Codegen support planned post-1.0 (see TODO.md #15) | No — tracked |

### Tests with builder-only visual (no macro screenshot comparison)

| # | Test | Reason |
|---|------|--------|
| 89 | textInput | No `@:manim` entry; uses `enqueueBuilder()` not `enqueueBuilderAndMacro()` |

**Assessment:** This is intentional and tracked in TODO.md. No missing tests here.

## Builder vs Incremental Builder Coverage

### Features tested in BOTH builder and incremental mode

| Feature | Builder test | Incremental test |
|---------|-------------|-----------------|
| Expression evaluation (*, +, -, /, %, div) | BuilderUnitTest (26 tests) | BuilderUnitTest (testIncrementalExpr*, 8 tests) |
| Conditional visibility (=, !=, >=, <=, >, <, range) | BuilderUnitTest (19 tests) | BuilderUnitTest + ProgrammableCodeGenTest (7 tests) |
| @else/@default chains | BuilderUnitTest (3 tests) | ProgrammableCodeGenTest (testIncrementalConditionalVisibility) |
| String interpolation | BuilderUnitTest (12 tests) | BuilderUnitTest (testIncrementalInterpolation) |
| Ternary expressions | BuilderUnitTest (6 tests) | BuilderUnitTest (testIncrementalTernary) |
| Repeatable count changes | BuilderUnitTest (4 tests) | BuilderUnitTest (testIncrementalRepeatable) |
| @final immutability | BuilderUnitTest (2 tests) | BuilderUnitTest (testIncrementalFinal) |
| Apply filter/alpha toggle | BuilderUnitTest | BuilderUnitTest (4 tests) |
| Graphics redraw | BuilderUnitTest | BuilderUnitTest (8 tests incl. conditional) |
| Pixels redraw | BuilderUnitTest | BuilderUnitTest (5 tests) |
| Scale/alpha/filter expressions | BuilderUnitTest | BuilderUnitTest (4 tests) |
| Transition declarations | BuilderUnitTest (4 tests) | BuilderUnitTest (same 4 tests) |
| Dynamic refs | DynamicRefTest (17 tests) | DynamicRefTest (uses Incremental mode throughout) |
| Parameterized slots | ParameterizedSlotTest (14 tests) | ParameterizedSlotTest (uses Incremental for param slots) |
| Multi-value match (`[v1,v2]`) | BuilderUnitTest (4 tests) | Not tested |
| Batch update (beginUpdate/endUpdate) | ProgrammableCodeGenTest (1 test) | BuilderUnitTest (1 test) |

### Features tested ONLY in builder mode (NO incremental tests)

| Feature | Builder test file | Risk |
|---------|------------------|------|
| Flow overflow/fill/reverse/align | FlowOverflowTest (17 tests) | **Low** — flow properties are build-time, not runtime-updatable |
| Bit flag conditionals (`bit[N]`) | BitFlagTest (13 tests) | **Medium** — bit flags are conditionals that SHOULD work with `setParameter()` but aren't tested incrementally |
| Interactive events | InteractiveEventTest (10 tests) | **Low** — events are runtime behavior, incremental mode not applicable |
| Rich text styles/images | RichTextTest (30 tests) | **Low** — richText tested in builder; BuilderUnitTest has 1 incremental test for dynamic style color |
| Grid/hex coordinate systems | BuilderUnitTest (37 tests) | **Low** — coordinate expressions are build-time |
| Named ranges | BuilderUnitTest (10 tests) | **Low** — repeatable ranges are build-time |
| Multi-value conditionals | BuilderUnitTest (4 tests) | **Medium** — `@(param=>[v1,v2])` conditionals could be tested with `setParameter()` |

### Missing incremental tests (recommended additions)

1. **Bit flag incremental** (Medium): Test `setParameter("flags", N)` with `@(flags => bit[0])` conditionals — verify visibility toggling.
2. **Multi-value match incremental** (Low): Test `setParameter("rarity", "rare")` with `@(rarity=>[common,rare])` — verify match/unmatch.

## Builder vs Codegen (Macro) Coverage

### Features with visual parity tests (builder screenshot == codegen screenshot)

All 91 visual tests with macro comparison verify that builder and codegen produce identical output. This covers: conditionals, expressions, text, bitmap, ninepatch, layers, flow, repeatable, repeatable2d, tilegroup, graphics, pixels, apply, masks, references, filters, palettes, autotile, grid/hex positions, particles, blend modes, curves, paths, animated paths, data blocks, @final, indexed named, slots, parameterized slots, slot content, dynamic refs, flow advanced, imports, color operations, layout align, rich text, transitions.

### Features tested in codegen with unit tests

| Feature | Codegen unit test |
|---------|------------------|
| Indexed named get_label/get_icon | ProgrammableCodeGenTest (testIndexedNamedCodegenAccessors) |
| Slot params via codegen | ProgrammableCodeGenTest (testSlotParamsCodegen, testSlotParamsCodegen2dIndex) |
| Slot content via codegen | ProgrammableCodeGenTest (testSlotContentCodegenSetAndClear, etc.) |
| Named range loop values | ProgrammableCodeGenTest (testNamedRangeMacroLoopVarValues) |
| Layout multi-child count | ProgrammableCodeGenTest (testLayoutMultiChildCount) |
| Data block types/packages | ProgrammableCodeGenTest (testDataExposedType, testDataTypePackage, testDataMergeTypes) |

### Features NOT tested in codegen path

| Feature | Current coverage | Gap severity |
|---------|-----------------|-------------|
| TextInput | Builder visual only (test89) | **Low** — codegen planned post-1.0, tracked in TODO.md |
| PVFactory settings | Builder unit only (test77) | **None** — PVFactory is builder-only by design |
| Dynamic ref codegen unit tests | Visual comparison only (test73, 74) | **Medium** — builder has 17 unit tests in DynamicRefTest; codegen has visual parity but no unit tests for `getDynamicRef()`, nested refs via generated API |
| Rich text codegen unit tests | Visual comparison only (test92) | **Medium** — no codegen-specific tests for generated style/image setters |
| Interactive cursor metadata | Not tested at all | **Medium** — tracked in test-todo.md #5 |

## test-todo.md Gap Assessment

| # | Item | Status | Still valid? |
|---|------|--------|-------------|
| 1 | Card hand orchestration | DONE (35 tests in CardHandIntegrationTest) | ✅ Addressed |
| 2 | .anim typed filter runtime | DONE (33 tests in AnimFilterStateConditionalTest) | ✅ Addressed |
| 3 | Screen transition integration | DONE (40 tests in ScreenTransitionIntegrationTest) | ✅ Addressed |
| 4 | Animated path builder/codegen | DONE (22 tests in AnimatedPathBuilderTest) | ✅ Addressed |
| 5 | Interactive cursor metadata | NOT DONE | ⚠️ Still a gap |
| 6 | Rich text codegen unit tests | NOT DONE (visual parity exists) | ⚠️ Still a gap |
| 7 | Dynamic ref codegen unit tests | NOT DONE (visual parity exists) | ⚠️ Still a gap (low priority) |

## TODO.md Assessment

| # | Item | Status |
|---|------|--------|
| 10 | `closeAllNamed()` iterator | Open (low priority) — fragile but works |
| 15 | Text input codegen | Open (post-1.0) — intentionally deferred |

Both remaining items are appropriately triaged.

## Issues Found

### 1. No invalid or broken tests detected
All 95 test directories have matching `.manim` files. All visual tests (except 62, 77) have reference images. All test files compile and are registered in `TestApp.hx`.

### 2. test32 (Blob47Fallback) pre-existing mismatch
Documented in `testing-and-debugging.md` as known: "test32_Blob47Fallback has a reference image mismatch (not a regression)." Note: this is actually test30 in the directory listing (`30-blob47Fallback`).

### 3. Incremental bit flag gap
`BitFlagTest` has 13 tests all in builder-only mode. Since bit flags are conditional visibility tests (`@(flags => bit[N])`), they should work identically with `setParameter("flags", newValue)` in incremental mode, but this path is untested.

### 4. Codegen transition test uses different TweenManager instances per row
In `test95_Transition`, the codegen phase creates/nullifies `tweenManager` per-row on the factory (`mp.transFade.tweenManager = tm2` → create → `mp.transFade.tweenManager = null`). This is correct for testing but differs structurally from the builder phase which uses a single builder-level `tweenManager`. The visual output matches, so this is just a structural observation.

## Functionality Diffs Between Builder, Incremental Builder, and Codegen

### Codegen delegation pattern

Complex/opaque elements are NOT inlined by codegen — they delegate to the runtime builder:
- `PARTICLES` → `ProgrammableBuilder.buildParticles()` → full builder call
- `TILEGROUP` → `ProgrammableBuilder.buildTileGroupFromProgrammable()` → full `buildWithParameters()` call
- `STATEANIM` / `STATEANIM_CONSTRUCT` → `ProgrammableBuilder.buildStateAnim()`
- `PLACEHOLDER` → `ProgrammableBuilder.buildPlaceholderViaCallback()`
- `STATIC_REF` / `DYNAMIC_REF` → `ProgrammableBuilder.buildStaticRef()` / `buildDynamicRef()`
- Parameterized `SLOT` → `ProgrammableBuilder.buildParameterizedSlot()`

This means these elements go through builder code even in codegen path — they're **visually tested** through the 91 macro comparison tests but the delegation mechanism itself has no unit test coverage.

### Key behavioral diffs

| Scenario | Builder | Incremental | Codegen |
|----------|---------|------------|---------|
| `BITMAP` (file/sheet) param change | Full rebuild | **No re-tile** (tile pointer static) | Typed field, no setParameter support for tile source |
| `STATEANIM`/`PARTICLES`/`TILEGROUP` | Full support | **Static** (built once, not tracked) | Delegates to builder at runtime |
| Param-dependent repeat count | Full rebuild | **Tracked** — removes + rebuilds children | **Rebuild** — removes + recreates in runtime loop |
| `LayoutIterator` in repeat | Full support | Static (correct — layout positions are non-parameterized) | **Compile error** if layout not found (previously silent fallback to empty placeholder) |
| `RVArray` / `RVArrayReference` | Full support | Full support | **Throws** — not supported in codegen |
| Runtime `.x`/`.y` extraction from grid/hex | Full support | Full support | **Throws** — `Context.error` |
| Hot reload | Yes (MULTIANIM_DEV) | Yes (MULTIANIM_DEV) | **No** |
| `buildWithComboParameters` | Yes | No | No (use `_applyVisibility` instead) |
| Transitions | N/A (full rebuild) | Full (IncrementalUpdateContext) | Full (CodegenTransitionHelper) |

### Untested codegen limitations

These codegen-specific limitations are NOT verified by tests (no negative tests exist):
1. **`RVArray`/`RVArrayReference` in codegen throws** — no test that codegen rejects these gracefully
2. ~~**`LayoutIterator` fallback in codegen**~~ RESOLVED: now a `Context.error` compile-time failure (no silent degradation)
3. **Runtime `.x`/`.y` extraction throws in codegen** — no test verifying the error message

### ~~Pooling vs rebuild for param-dependent repeats~~ RESOLVED

Investigation revealed the codegen path **already uses rebuild** (removeChildren + recreate loop with actual runtime count), not pooling. The function names (`poolRepeatChildren`, `repeatPoolEntries`, `resolveMaxCount`) were vestiges of a prior approach. Dead code removed and functions renamed to `rebuildRepeatChildren`/`rebuildRepeat2DChildren`. Test64 already verifies counts exceeding the default value (variant `[0, 10, 0, 10, 0, 10]` with defaults `count=5, cols=3, rows=2`).

## Recommendations (Priority Order)

1. **Update test-todo.md header counts** — currently says "23 test files, ~1506 test methods, 95 visual test examples." Test file count is now 27. Method count should be re-verified.
2. **Add incremental bit flag tests** (Low effort, Medium value) — 2-3 tests in BitFlagTest verifying `setParameter("flags", N)` toggles visibility correctly.
3. **Add incremental multi-value match tests** (Low effort) — test `setParameter` with `@(param=>[v1,v2])`.
4. **Interactive cursor metadata tests** (Medium effort) — as tracked in test-todo.md #5.
5. **Rich text codegen unit tests** (Medium effort) — test generated style/image setters.
6. **Dynamic ref codegen unit tests** (Low effort) — test `getDynamicRef()` via generated API.
7. ~~**Codegen repeat pool overflow test**~~ — RESOLVED: codegen uses rebuild, not pooling. Test64 already covers this.