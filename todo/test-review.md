# Non-Visual Test Review

Reviewed: 2026-02-27 | Updated: 2026-02-28

This is a detailed review of all non-visual (unit/logic) tests, covering correctness of test intent,
assertion quality, and coverage gaps. Tests are organized by file.

---

## Summary Statistics

| File | Tests | Strong | Weak/No-crash | Remaining Issues |
|------|-------|--------|---------------|-----------------|
| ParserErrorTest.hx | 227 | ~170 | ~57 parse-success-only | Some success tests still don't verify AST |
| AnimParserTest.hx | 89 | ~85 | ~4 | ~~Integration parse tests are all no-crash~~ Fixed: returns result, AST verified. Gaps: @default, filters, typed event metadata |
| BuilderUnitTest.hx | 207 | ~203 | ~4 | ~~Assert.pass() on graphics~~ Reduced to 4 remaining Assert.pass() |
| UIComponentTest.hx | 68 | ~67 | ~1 | ~~ScrollableList scroll Assert.pass()~~ Fixed. 1 remaining Assert.pass() |
| UITooltipHelperTest.hx | 20 | 14 | 6 | Position tests can't verify positioning (headless limitation) |
| UIPanelHelperTest.hx | 48 | 43 | 5 | Unused variable in testOpenSameInteractiveTwice |
| UIRichInteractiveHelperTest.hx | 40 | 40 | 0 | ~~State machine not tested~~ Fixed: assertState() helper, all no-ops replaced |

---

## File: ParserErrorTest.hx (227 tests)

### Overall Assessment: Mixed (improved — critical issues fixed)

### Error Tests - GOOD
Error tests via `parseExpectingError()` are well-done. ~~9 tests didn't validate error message content~~ — fixed: 14 tests upgraded to `Assert.stringContains()`.

### Success Tests - STILL WEAK
Most `parseExpectingSuccess()` tests still only verify parsing doesn't throw — no AST verification. 6 key tests were upgraded to use `parseExpectingResult` with node type/count checks, but the majority (~50+) remain no-crash-only.

### ~~CRITICAL: 3 Tests Missing @Test Annotations~~ — FIXED
`testOffsetOnLayout`, `testOffsetOnGridPos`, `testOffsetInvalidSuffix` now have `@Test`.

### Infrastructure Issue: Duplicated Helpers
Still present — class extends `utest.Test` directly, duplicating helpers from `BuilderTestBase`.

### ~~Missing Negative Tests~~ — Partially Fixed
- ~~Coordinate systems~~ — DONE: 6 tests added
- ~~`@ifstrict` error cases~~ — DONE: 4 tests added
- ~~`import` statement errors~~ — DONE: 3 tests added
- **`@else` after `@default`** — still untested
- **Duplicate `@default`** — still untested
- **`staticRef`/`dynamicRef` errors** — still untested
- **`slot` parsing errors** — still untested

### Remaining Recommendations

1. **Add AST verification to more success tests** — most still only check no-crash
2. **Add negative tests** for `@else` after `@default`, duplicate `@default`, ref/slot errors
3. **Consider extending `BuilderTestBase`** instead of duplicating helpers

---

## File: AnimParserTest.hx (89 tests)

### Overall Assessment: STRONG (was: weak — significantly expanded in commit `217ff7c`)

Grew from 19 to 89 tests. `parseAnimExpectingSuccess` now returns `AnimParserResult`. Tests verify AST structure, metadata types, conditional matching, and new `.anim` format features.

### Unit Tests - GOOD
`countStateMatch`, `matchConditionalValue`, and comparison operator tests are well-structured with exact value assertions. Metadata accessor tests cover int, float, string, color types with state selectors.

### Integration Parse Tests - GOOD (was: WEAK)
Tests now capture and verify the `AnimParserResult`: `definedStates`, metadata values, animation counts.

### New .anim Feature Coverage

| Feature | Tested | Notes |
|---------|--------|-------|
| `@else` conditional | Yes | `testParseElseConditionalInExtrapoints` |
| `@default` conditional | **No** | Gap — no test |
| `@final` constants | Yes | Declaration + duplicate error |
| `${state}` interpolation | Yes | `testParseStateInterpolation` |
| Compact shorthand (`anim name:`) | Yes | `testParseAnimShorthand` |
| Comparison operators | Yes | 6+ tests for `>=`, `<=`, `>`, `<` |
| Range conditionals | Yes | `testParseRangeConditional` |
| Float metadata | Yes | 3 tests (default, exception, state selector) |
| Color metadata | Yes | 3 tests (default, exception, state selector) |
| Typed event metadata | **No** | Events parse but no metadata payload tests |
| Filter declarations | **No** | No tests |

### Remaining Gaps

1. **`@default` conditional** — no test for fallback behavior
2. **Filter declarations** — `filters { }` block untested
3. **Typed event metadata** — `event hit { damage:int => 5 }` payload untested
4. **`findBestStateMatch` ambiguity** — two selectors with equal scores

---

## File: BuilderUnitTest.hx (207 tests)

### Overall Assessment: STRONG (improved)

This is the strongest test file. Tests build actual `.manim` sources and verify concrete output properties.

### Issues Found — Status

1. ~~**Assert.pass() in graphics/pixels tests**~~ — Mostly fixed. 4 `Assert.pass()` calls remain (graphics-related where visual state is hard to verify in headless mode).

2. ~~**Hex coordinate tests use `isTrue(x != 0)`**~~ — FIXED: all 7 tests now assert exact computed values using `floatEquals`.

3. ~~**8 incremental mode tests don't test incremental behavior**~~ — FIXED: all 8 now call `setParameter()` and verify updated output.

4. **Duplicate test**: `testExprMultiVarDivPercent` is identical to `testInterpolMultiVarExpression` — still present.

5. ~~**`testAnimatedPathPingPong` ambiguous time**~~ — FIXED: tests at t=1.75 where forward vs backward rates differ.

6. ~~**No boundary-value testing for range conditionals**~~ — FIXED: 6 boundary tests added.

7. **Misplaced test**: `testInterpolMultiVarExpression` tests expressions, not interpolation — still in wrong section.

8. **`testBoolParamFalse`**: Passes string `"false"` not boolean `false` — naming still misleading.

### Missing Coverage — Status

1. **Named hex `$hex.offset()` / `$hex.doubled()`** with named systems — still untested
2. **Error cases for grid/hex** — still no builder-level error tests (parser tests added)
3. **Incremental `@else` / `@default`** conditionals — still untested
4. **`@flow.*` properties** — still no unit tests, only visual
5. **`tilegroup` element** — still no unit tests
6. **`dynamicRef` parameter propagation** — still weak
7. **Multi-branch conditional re-evaluation** (A→B→C) — still untested
8. **Incremental repeatable count changes** — still untested
9. **`beginUpdate()`/`endUpdate()` batching** — still untested
10. ~~**Multi-value match `@(param=>[v1,v2])`**~~ — DONE: 4 tests
11. ~~**Bit flag conditionals `@(param => bit[N])`**~~ — DONE: 5 tests
12. ~~**Coordinate `.offset()` suffix**~~ — DONE: 3 tests

### Remaining Recommendations

1. **Remove or rename duplicate** `testExprMultiVarDivPercent`
2. **Replace 4 remaining `Assert.pass()`** in graphics tests if possible
3. **Add incremental `@else`/`@default` tests**

---

## File: UIComponentTest.hx (68 tests)

### Overall Assessment: STRONG (improved)

### Issues Found — Status

1. ~~**ScrollableList scroll tests use `Assert.pass()`**~~ — FIXED: verify `mask.scrollY` via `@:privateAccess`.
2. ~~**Dropdown/ScrollableList only test negative callback case**~~ — FIXED: positive tests added.
3. **`testScrollableListAutoSizeMode`** — still only checks creation succeeds.
4. ~~**`testDraggableDragMove` no position check**~~ — FIXED: asserts root moved to (40,40).
5. ~~**`testButtonStateTransitions` no state check**~~ — FIXED: verifies status param transitions.
6. ~~**`testTextInputDisabledBlocksEvents` no verification**~~ — FIXED: verifies status stays "disabled".
7. ~~**`testTextInputHoverState` no state check**~~ — FIXED: verifies status param transitions.
8. ~~**`testTextInputContainsPoint` never calls containsPoint()**~~ — FIXED: now calls it.
9. **`testTextInputOnChangeCallback`** — still only tests negative case (setText doesn't fire). Positive case (user typing) untested.
10. **All slider tests use `BUTTON_MANIM`** — still no slider-specific `.manim`.
11. 1 remaining `Assert.pass()` call.

### Missing Coverage (unchanged)

1. Dropdown panel opening via keyboard Enter (positive test)
2. ScrollableList mouse wheel scrolling
3. ScrollableList disabled item click
4. Slider-specific unit tests
5. Progress bar unit tests
6. Tab content routing with contentRoot mode

---

## File: UITooltipHelperTest.hx (24 tests)

### Overall Assessment: GOOD

Well-structured lifecycle tests covering delay, cancel, show/hide, and per-interactive overrides.

### Issues Found

1. **Position tests can't verify positioning** — `testSetPositionOverride`, `testSetOffsetOverride`, `testAllPositions` only verify the tooltip opens without crashing. Headless mode returns zero bounds, so positioning math can't be validated.

2. **`testUpdateParamsWhenActive`** — verifies `updateParams()` returns `true` but doesn't verify the parameter was actually applied to the `BuilderResult`

3. **`testRebuildPreservesOriginalParams`** — cannot verify original params were actually reused (the tooltip programmable has a default for `label`, so building with or without params looks the same)

### Missing Coverage

1. **Tooltip object scene graph** — no test verifies the h2d.Object was actually added/removed from the scene
2. **`show()` with params directly** — only tested indirectly via rebuild
3. **`startHover` while different hover pending** — what happens when hovering btn2 while btn1's timer is running
4. **Tooltip layer** — the `layer` parameter is never verified

---

## File: UIPanelHelperTest.hx (38 tests)

### Overall Assessment: STRONG

The most thorough of the UI helper test files, with good coverage of single panels, named panels, close modes, deferred close, and event emission.

### Issues Found

1. **`testOpenSameInteractiveTwice`** (line 133) — has an unused variable `firstResult` that was likely intended for a `firstResult != ctx.helper.getPanelResult()` assertion. The variable is captured but never used.

2. **`testOpenWithParams`** — only checks `isOpen()` and `notNull(getPanelResult())`, doesn't verify the "label=world" parameter was applied

3. **Fragile prefix format test** — `testIsOwnInteractiveMatchesNamedPanelPrefix` (line 552) hardcodes `"slot1.btn1.panel.child"` which depends on internal prefix construction format

### Missing Coverage

1. **Close event for same-interactive replacement** — `testOpenSameInteractiveTwice` doesn't check close event emission
2. **Multiple `handleOutsideClick` without `checkPendingClose`** — what happens with two consecutive UIClickOutside events
3. **`handleOutsideClick` with non-UIInteractiveEvent** — the default branch is untested

### Minor Redundancy
`testDefaultCloseModeIsOutsideClick` and `testOutsideClickDeferredClose` test nearly identical scenarios.

---

## File: UIRichInteractiveHelperTest.hx (40 tests)

### Overall Assessment: STRONG (was: CRITICAL — all issues fixed)

Grew from 30 to 40 tests. All critical issues resolved.

- ~~**State machine not tested**~~ — FIXED: `assertState()` helper using `@:privateAccess` verifies `InteractiveState` after each event
- ~~**6 `Assert.isTrue(true)` no-ops**~~ — FIXED: all 6 replaced with actual state/binding assertions
- ~~**UIClickOutside untested**~~ — FIXED: 2 tests verify behavior
- ~~**Bind metadata untested**~~ — FIXED: 2 tests verify full chain through state machine to visual output

### No remaining critical issues.

---

## Cross-Cutting Issues

### 1. ~~The `parseExpectingSuccess` / `parseAnimExpectingSuccess` Pattern~~ — Partially Fixed
~~Both discard the return value.~~ `parseAnimExpectingSuccess` now returns `AnimParserResult`. `parseExpectingSuccess` in ParserErrorTest still discards the result (a `parseExpectingResult` variant was added for 6 key tests but most still use the old pattern).

### 2. Headless Positioning Limitation
Multiple tests across tooltip, panel, and some UI component files cannot verify positioning because `getBounds()` returns zeros in headless mode. These tests are currently smoke tests disguised as functionality tests.

**Recommendation:** Accept these as smoke tests and add comments indicating the limitation. For actual position verification, use the visual test pipeline.

### 3. No Integration Tests Between UI Helpers
There are no tests combining multiple helpers (e.g., UIRichInteractiveHelper driving state that affects UITooltipHelper content, or UIPanelHelper + UITooltipHelper on the same screen).

---

## Coverage Gaps (from test-todo.md + this review)

### URGENT (tests that are broken / dead code)
- [x] Fix 3 missing `@Test` annotations in ParserErrorTest.hx (lines 2026, 2038, 2048) — DONE: added @Test to testOffsetOnLayout, testOffsetOnGridPos, testOffsetInvalidSuffix
- [x] Fix `testButtonStateTransitions` — DONE: verifies status param transitions normal→hover→normal via @:privateAccess
- [x] Fix `testTextInputDisabledBlocksEvents` — DONE: verifies status stays "disabled" after simulateEnter
- [x] Fix `testTextInputHoverState` — DONE: verifies status param transitions normal→hover→normal via @:privateAccess
- [x] Fix `testTextInputContainsPoint` — DONE: now calls containsPoint() and verifies far point is not contained
- NOTE: `testMissingElementName` exposed a parser bug — `programmable()` without `#name` produced NPE instead of proper error — FIXED: changed `updatableName == null` to `.match(UNTObject(null))` in both programmable and slot guards

### High Priority (existing features, broken/useless tests)
- [x] UIRichInteractiveHelper state machine actual transitions (14 tests don't verify state) — DONE: added assertState() helper using @:privateAccess to verify InteractiveState after each event
- [x] Replace 6 `Assert.isTrue(true)` no-ops in UIRichInteractiveHelperTest — DONE: all 6 replaced with actual state/binding assertions
- [x] Replace `Assert.pass()` in ScrollableList scroll tests with actual assertions — DONE: verify mask.scrollY before/after via @:privateAccess
- [x] Replace `Assert.pass()` in BuilderUnitTest graphics/pixels tests with actual assertions — DONE: verify graphics child exists and is visible after setParameter
- [x] Add positive onItemChanged callback tests for Dropdown and ScrollableList — DONE: ScrollableList positive test verifies callback fires on simulated click; Dropdown positive test added with panel click
- [x] AnimParser integration test AST verification (5 parse tests are no-crash only) — DONE: parseAnimExpectingSuccess now returns AnimParserResult; all 17 success tests upgraded to Assert.notNull + key AST checks (definedStates, metadata values)
- [x] Upgrade ~13 error-only `Assert.notNull(error)` tests in ParserErrorTest to check message — DONE: 14 tests upgraded to use Assert.stringContains() for error message verification
- [x] Add `setParameter()` to 8 incremental-mode tests in BuilderUnitTest (or remove dupes) — DONE: all 8 tests now call setParameter() and verify updated output (text, bitmaps, conditionals, repeatables). Note: @final constants are immutable — test verifies values don't change.

### Medium Priority (features with weak tests)
- [x] Hex coordinate exact value assertions (7 tests use `!= 0` / `> 0`) — DONE: all 7 tests now assert exact computed values using floatEquals for positions and equals for Std.int dimensions (computed from hex math formulas for pointy(16,16))
- [x] Range conditional boundary-value tests (test exact endpoints) — DONE: added 6 boundary tests for values 0, 25, 26, 50, 51, 75 covering all range transitions
- [x] ParserErrorTest success tests AST verification (at least key syntax forms) — DONE: upgraded 6 key tests (testValidElseAfterConditional, testValidElseIfChain, testValidDefaultAfterConditionals, testGridPosParseSuccess, testHexCubeParseSuccess, testDataParseSuccess) to use parseExpectingResult and verify node types, children count, and conditional types
- [x] Interactive event filtering (`events: [hover, click, push]`) — DONE: 3 tests verify eventFlags on UIInteractiveWrapper (click-only=2, hover-only=1, default=EVENT_ALL=7)
- [x] Bind metadata auto-wiring — DONE: 2 tests verify full chain: register() auto-wires bind metadata → handleEvent() drives state machine → setParameter() updates visual (bitmap width changes from 10→20→30px based on status)
- [x] UIClickOutside event — DONE: 2 tests verify UIClickOutside doesn't change state machine (falls through to default) and returns false for unknown IDs
- [x] Coordinate systems negative tests in ParserErrorTest (zero error tests) — DONE: 6 tests for unknown grid/hex methods, unknown coordinate system, grid/hex on root level, unknown hex chain method
- [x] Verify drag move positions with exact coordinates — DONE: testDraggableDragMove now asserts root moved to (40,40) after push at (10,10) and move to (50,50)
- [x] Test AnimatedPath pingPong at non-ambiguous time points — DONE: changed from t=1.5 (rate=0.5 ambiguous) to t=1.75 (rate=0.25 which differs from non-pingPong rate=0.75)

### Low Priority (missing feature tests)
- [x] AnimMetadata state-selector API — DONE: 3 tests (float+state, color+state, exception message content)
- [x] Animated path event emissions — DONE: 4 tests (pathEnd, cycleStart/cycleEnd, custom+builtin order, event state rate)
- [ ] Particle runtime API (addForceField, sub-emitters)
- [ ] Slider-specific .manim tests (currently using BUTTON_MANIM)
- [ ] Progress bar unit tests
- [ ] Text input unit tests (post-1.0)
- [ ] Hot reload integration tests
- [x] Multi-value match `@(param=>[v1,v2])` builder tests — DONE: 4 tests (match first/second value, no-match fallback, single value)
- [x] Bit flag conditionals `@(param => bit[N])` builder tests — DONE: 5 tests (bit0 set, bit1 not set, bit2 set, zero flags, multiple bits)
- [x] `.offset()` coordinate suffix builder tests — DONE: 3 tests (layout+offset, grid+offset, param reference offset)
- [x] `@ifstrict` error cases — DONE: 4 tests (parse success, with @else, missing paren, unknown param)
- [x] `import` statement error cases — DONE: 3 tests (missing as, missing filename, file not found)
