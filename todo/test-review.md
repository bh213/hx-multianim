# Non-Visual Test Review

Reviewed: 2026-02-27

This is a detailed review of all non-visual (unit/logic) tests, covering correctness of test intent,
assertion quality, and coverage gaps. Tests are organized by file.

---

## Summary Statistics

| File | Tests | Strong | Weak/No-crash | Critical Issues |
|------|-------|--------|---------------|-----------------|
| ParserErrorTest.hx | 238 | ~158 error tests | ~163 parse-success-only | Parse-success tests don't verify AST |
| AnimParserTest.hx | 19 | 12 | 7 | Integration parse tests are all no-crash |
| BuilderUnitTest.hx | 217 | ~195 | ~22 | Some `Assert.pass()` on graphics/pixels setParameter |
| UIComponentTest.hx | ~90 | ~80 | ~10 | ScrollableList scroll tests use Assert.pass() |
| UITooltipHelperTest.hx | 24 | 18 | 6 | Position tests can't verify positioning |
| UIPanelHelperTest.hx | 38 | 33 | 5 | Unused variable in testOpenSameInteractiveTwice |
| UIRichInteractiveHelperTest.hx | 30 | 16 | 14 | State machine tests don't verify actual transitions |

---

## File: ParserErrorTest.hx (238 tests)

### Overall Assessment: Mixed

The file has two categories of tests with very different quality levels.

### Error Tests (~79 tests) - GOOD

Tests that verify parse errors via `parseExpectingError()` are generally well-done:
- They verify the error is not null
- ~68 of them also verify error message content with `error.indexOf("expectedString")`
- ~9 check only `Assert.notNull(error)` without verifying the message

**Issue: ~9 error tests don't validate error message content.** Any exception (including NPE) would satisfy `Assert.notNull(error)`. These should check that the error message contains a relevant keyword.

### Success Tests (~163 tests) - WEAK

The `parseExpectingSuccess()` pattern only verifies that parsing doesn't throw. These tests:
- Don't verify the parsed AST structure
- Don't verify number of elements, parameter types, conditional structures
- Would silently pass if the parser started ignoring parts of the syntax

**These are "no-crash" tests, not correctness tests.** A parser that silently skips an `@(mode != off)` conditional would still pass all success tests.

### CRITICAL: 3 Tests Missing @Test Annotations (Dead Code)

Lines 2026, 2038, 2048: `testOffsetOnLayout()`, `testOffsetOnGridPos()`, `testOffsetInvalidSuffix()` are **missing the `@Test` annotation** and will never be executed by the test runner. `testOffsetInvalidSuffix` is the only error test for the `.offset()` suffix feature, so this error path has zero coverage.

### Infrastructure Issue: Duplicated Helpers

The class defines its own `parseExpectingError()`, `parseRawExpectingError()`, `doParse()`, and `parseExpectingSuccess()` helpers (lines 15-54), duplicating the same methods in `BuilderTestBase`. The class extends `utest.Test` directly instead of `BuilderTestBase`. Bug fixes to one copy won't propagate to the other.

### Missing Negative Tests by Section

- **Coordinate systems**: Zero negative tests (missing `grid:` declaration, wrong arg count, unknown method)
- **`@else` after `@default`**: Should be invalid, untested
- **Duplicate `@default`**: Untested
- **`@ifstrict` error cases**: Documented in CLAUDE.md, untested
- **`staticRef`/`dynamicRef` errors**: Missing reference, wrong param count
- **`slot` parsing errors**: Invalid parameter type
- **`import` statement errors**: Invalid path, circular import

### Recommendations for ParserErrorTest.hx

1. **Fix the 3 missing `@Test` annotations** — this is the highest-priority fix as these tests are dead code
2. **Upgrade ~13 error tests** that use only `Assert.notNull(error)` to also check `error.indexOf(...)` for relevant keywords (includes `testUnclosedBrace`, `testMissingElementName`, `testAtSignWithoutContent`, `testGarbageInNumericPosition`, `testMalformedTernaryMissingColon`, `testIncompleteArithmeticExpression`, `testUnaryMinusWithoutValueInFloat`, `testInvalidColorFormat`, `testRichTextStyleNoColorNoFont`, `testRichTextStylesBracketSyntaxFails`, `testRichTextOldStyleSyntaxFails`, `testElseOnRootElement`)
3. **Add AST verification to key success tests** — at minimum verify the node count and node types after parsing
4. **Add negative tests for coordinate systems, `@ifstrict`, imports, refs**
5. **Consider extending `BuilderTestBase`** instead of duplicating helper methods

---

## File: AnimParserTest.hx (19 tests)

### Overall Assessment: Unit tests good, integration tests weak

### Unit Tests (tests 1-12) - GOOD
`countStateMatch` and `matchConditionalValue` tests are well-structured with exact value assertions.

**Minor issue:** Mismatch tests use `Assert.isTrue(result < 0)` instead of exact penalty value `-10000`. Acceptable if the contract is "negative = no match," but if the exact penalty matters for priority scoring, the assertion should be exact.

### Integration Parse Tests (tests 13-17) - WEAK
All 5 parse tests only verify `Assert.isTrue(success)` where success = didn't throw.

**The `parseAnimExpectingSuccess` helper discards the return value**, making it impossible for callers to inspect the result. None of these tests verify:
- Correct number of animations parsed
- Correct conditional selectors (`ACVNot`, `ACVMulti`, `ACVSingle`)
- Correct coordinate values, fps, loop settings
- Correct extra point positions

### Error Tests (tests 18-19) - ACCEPTABLE
Check `Assert.notNull(error)` but don't verify error message content.

### Missing Coverage

1. **End-to-end parse + query**: Parse a `.anim` file then use `findAnimation`/`findExtraPoint` with state selectors to verify conditional dispatch works at runtime
2. **`$$stateName$$` interpolation** in sheet names
3. **`countStateMatch` partial match**: Two conditions where one matches and one doesn't
4. **`countStateMatch` asymmetric keys**: condSelector has keys not in runtimeState
5. **`matchConditionalValue` with `ACVNot(ACVMulti(...))`** directly
6. **AnimMetadata API**: `getIntOrDefault`, `getStringOrDefault` with state selectors (noted in test-todo.md)
7. **`findBestStateMatch` ambiguity**: Two selectors with equal scores

### Recommendations for AnimParserTest.hx

1. **Modify `parseAnimExpectingSuccess` to return the parsed result** so callers can inspect it
2. **Add AST verification to integration tests** — check animation count, conditional types, coordinates
3. **Add an end-to-end test** that parses and queries with state selectors

---

## File: BuilderUnitTest.hx (217 tests)

### Overall Assessment: STRONG

This is the strongest test file. Tests build actual `.manim` sources and verify concrete output properties (bitmap dimensions, positions, text content, visibility, children count).

### Strengths
- Tests verify **actual rendered values**: tile widths, positions, text strings, visibility flags
- Incremental update tests verify state before AND after `setParameter()` calls
- Grid and hex coordinate tests verify exact computed positions
- Conditional range tests verify correct branch selection
- Pixel data tests verify actual pixel values at specific coordinates
- Expression tests verify computed dimensions from formulas

### Issues Found

1. **~7 tests use `Assert.pass()`** after graphics/pixels `setParameter()`. These verify "no crash" but not the resulting visual state:
   - `testIncrementalGraphicsRedrawsOnSetParameter` (line 2320) — should verify the graphics were actually redrawn
   - `testIncrementalGraphicsBatchUpdate` (line 2364) — same issue
   - `testIncrementalDynamicRefWithGraphics` (line 2568) — same issue
   - `testRichTextDynamicStyleColor` (line 3687) — uses `Assert.isTrue(true, ...)` after setParameter

2. **Hex coordinate tests use `isTrue(x != 0)` instead of exact values** (7 tests: `testHexCubeNonOrigin`, `testHexCornerXYExtraction`, `testHexEdgeXYExtraction`, `testHexCubeXYExtraction`, `testHexOffsetEven`, `testHexDoubled`, `testHexWidthHeightValues`). For a deterministic hex system, exact values should be asserted. Example: pointy(16,16) width = sqrt(3)*16 ≈ 27, height = 2*16 = 32.

3. **8 incremental mode tests (Section 14, lines 984-1094) don't test incremental behavior**: They only verify the initial build output in incremental mode but never call `setParameter()`. They are functional duplicates of the non-incremental tests.

4. **Duplicate test**: `testExprMultiVarDivPercent` (line 730) is identical to `testInterpolMultiVarExpression` (line 582) — same source, same params, same assertion.

5. **`testAnimatedPathPingPong`** (line 1969): Rate 0.5 at t=1.5 is the same whether pingPong works or not. Should test at a time where forward vs backward rates differ.

6. **No boundary-value testing for range conditionals**: Tests in the range section never test exact boundary values (e.g., value=25 at boundary of `@(val => 0..25)`).

7. **Misplaced test**: `testInterpolMultiVarExpression` (line 582) tests expression resolution, not string interpolation, but lives in the interpolation section.

8. **`testBoolParamFalse`** (line 420): Passes string `"false"` not boolean `false`. Tests coercion but name doesn't indicate this.

### Missing Coverage

1. **Named hex `$hex.offset()` and `$hex.doubled()`** with named systems — only tested with default hex system
2. **Error cases**: No tests for invalid grid/hex usage (e.g., `$grid.pos()` without a `grid:` declaration)
3. **Incremental `@else` / `@default`** conditionals — only `@(condition)` tested
4. **`@flow.*` properties** (halign, valign, offset, absolute) — no unit tests, only visual
5. **`tilegroup` element** — no unit tests
6. **`dynamicRef` with parameter propagation** — only one test, doesn't verify the child received correct values
7. **`setParameter()` with conditional re-evaluation across multiple branches** (switching from branch A to B to C)
8. **Incremental repeatable count changes** (adding/removing elements)
9. **`beginUpdate()`/`endUpdate()` batching semantics** (verify intermediate states not rendered)
10. **Multi-value match** `@(param=>[v1,v2])` — not tested in builder
11. **Bit flag conditionals** `@(param => bit[N])` — not tested in builder
12. **Coordinate `.offset()` suffix** — documented in CLAUDE.md, no builder tests

### Recommendations for BuilderUnitTest.hx

1. **Replace `Assert.pass()` in graphics/pixels tests** with actual verification of the rendered state
2. **Add exact expected values for hex coordinate tests** — these are mathematically deterministic
3. **Add error-path tests** for invalid coordinate system usage
4. **Add `setParameter()` calls to the 8 incremental-mode-only tests** or remove them as duplicates
5. **Add boundary-value tests** for range conditionals (test exact endpoints)

---

## File: UIComponentTest.hx (~90 tests)

### Overall Assessment: STRONG

Comprehensive test coverage for Button, Checkbox, Slider, Dropdown, ScrollableList, Tabs, Drag-and-Drop, and AutoSync.

### Strengths
- Good lifecycle testing (create, interact, verify state)
- Uses `UITestHarness` for event simulation — proper integration testing
- Tests both happy path and error paths (out-of-bounds, disabled, etc.)
- Event emission is verified with `MockControllable.hasEvent()`
- Drag-and-drop tests are thorough: zones, priorities, constraints, swap mode, highlights

### Issues Found

1. **ScrollableList scroll tests use `Assert.pass()`** with no actual verification:
   - `testScrollableListScrollToIndexAlreadyVisible` (line 1348) — "No assertion needed" comment, but should verify scroll position didn't change
   - `testScrollableListScrollToIndexOutOfBounds` (line 1357) — should verify no state change
   - `testScrollableListScrollToIndexScrollsDown` (line 1368) — should verify scroll position actually changed

2. **`testDropdownOnItemChangedCallback`** (line 1079) — only tests that `setSelectedIndex()` does NOT trigger the callback. Missing: test that panel selection DOES trigger it.

3. **`testScrollableListOnItemChangedCallback`** (line 1372) — same issue: only tests the negative case.

4. **`testScrollableListAutoSizeMode`** (line 1437) — only checks creation succeeds, doesn't verify panel was actually auto-sized

5. **`testDraggableDragMove`** (line 2059) — only checks `Assert.notNull(obj)`, doesn't verify the object actually moved to the new position

6. **`testButtonStateTransitions`** (line 104) — only asserts `notNull(getObject())` after enter/leave. Does NOT verify the status parameter changed to "hover" or back to "normal". This is a "no exception" test disguised as a state test.

7. **`testTextInputDisabledBlocksEvents`** (line 713) — only checks `notNull(getObject())`. Does not verify events were actually blocked (compare with `testButtonDisabledNoClick` which correctly checks `mock.eventCount() == 0`).

8. **`testTextInputHoverState`** (line 726) — same problem as `testButtonStateTransitions`: only `notNull` checks, no state verification.

9. **`testTextInputContainsPoint`** (line 768) — named "containsPoint" but never calls `containsPoint()`. Only checks `notNull(getBounds())`.

10. **`testTextInputOnChangeCallback`** (line 752) — misleading name: actually tests that `setText()` does NOT fire onChange. The positive case (user typing fires onChange) is never tested.

11. **All slider tests use `BUTTON_MANIM`** instead of a slider-specific `.manim` definition. Tests logical value management but not slider-specific visual integration.

### Missing Coverage

1. **Dropdown panel opening/closing via keyboard Enter** — `testDropdownDisabledBlocksAllEvents` tests it in disabled mode, but no positive test for Enter opening
2. **ScrollableList mouse wheel scrolling** — `wheelScrollMultiplier` property is tested, but actual wheel event processing is not
3. **ScrollableList disabled item click** — no test verifying that clicking a disabled item doesn't select it
4. **Slider component** — tests exist in the visual suite but no dedicated unit tests for the slider value interface
5. **Text input component** — no unit tests (noted in TODO.md as post-1.0)
6. **Progress bar component** — no unit tests
7. **Tab content routing with contentRoot mode** — `testTabsContentRootRelativeMode` only checks creation, not that content is positioned correctly

### Recommendations for UIComponentTest.hx

1. **Fix scroll tests** to verify actual scroll state changes
2. **Add positive callback tests** for dropdown/scrollable list `onItemChanged`
3. **Add Slider unit tests** for value range, step, and event emission
4. **Verify drag move positions** with exact coordinate checks

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

## File: UIRichInteractiveHelperTest.hx (30 tests)

### Overall Assessment: CRITICAL ISSUE — State machine not properly tested

### Critical Systemic Problem

**The entire state machine section (14 tests) only checks `handleEvent()` return values.** The return value means "this interactive is registered," NOT "a state transition happened." These tests would all pass even if the state machine was completely broken and never transitioned.

Tests that need actual state verification:
- `testEnterSetsHover` — should verify parameter set to "hover"
- `testPushAfterEnterSetPressed` — should verify parameter set to "pressed"
- `testClickAfterPushReturnsToHover` — should verify parameter set to "hover"
- `testLeaveFromHoverReturnsToNormal` — should verify parameter set to "normal"
- `testLeaveFromPressedReturnsToNormal` — should verify parameter set to "normal"
- `testFullCycleEnterPushClickLeave` — should verify all four transitions

### 6 Tests Use `Assert.isTrue(true)` (Literal No-Op)

These tests provide ZERO regression safety:
1. `testPushWithoutEnterIsIgnored` (line 166)
2. `testClickWithoutPushIsIgnored` (line 177)
3. `testSetDisabledOnUnknownInteractive` (line 242)
4. `testDisabledDoesNotTransitionOnEnter` (line 257)
5. `testSetParameterOnBoundInteractive` (line 361)
6. `testSetParameterOnUnknownInteractive` (line 369)

### Recommendations for UIRichInteractiveHelperTest.hx

1. **Add state observation** — either expose the current state or inspect the `BuilderResult` after each event to verify `setParameter("status", expectedValue)` was called. The simplest approach would be reading the parameter back from the incremental result if the API supports it.
2. **Replace all `Assert.isTrue(true)` with actual assertions**
3. **Test disabled blocking for all event types** (Push, Click, Leave), not just Enter
4. **Test `UIClickOutside` event handling**

---

## Cross-Cutting Issues

### 1. The `parseExpectingSuccess` / `parseAnimExpectingSuccess` Pattern
Both discard the return value, preventing callers from inspecting the parsed result. This is the single biggest architectural issue in the test infrastructure — it makes it impossible to write meaningful parse result tests without using the separate `builderFromSource` path.

**Recommendation:** Have these helpers return the parsed result (or at least store it) so tests can optionally inspect the AST.

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
