# V1.0 Release Plan

Release strategy: **1.0.0-rc.1** first, then 1.0.0 final after validation.

Current state: 93 visual tests + 3543 unit assertions, all passing. Version 1.0.0-rc.1 ready. All checklist items DONE.

## Checklist

| # | Phase | Item | Priority | Effort | Status |
|---|-------|------|----------|--------|--------|
| 1 | Bug fix | Dropdown z-ordering | High | Small | DONE |
| 2 | Feature | Codegen transition support | High | Large | DONE |
| 3a | Tests | Card hand orchestration integration (~35 tests) | High | Medium | DONE (35 tests) |
| 3b | Tests | .anim typed filter runtime state-conditionals (~25 tests) | High | Medium | DONE (33 tests) |
| 3c | Tests | Screen transition integration (~30 tests) | High | Medium | DONE (40 tests) |
| 3d | Tests | Animated path builder/codegen integration (~20 tests) | High | Medium | DONE (22 tests) |
| 4 | Tests | Transition edge cases (slide-in-flow, invalid easing, interruption) | Medium | Small | DONE |
| 5 | Release | Version bump, CHANGELOG, CI workflow, docs review | High | Medium | DONE |

## Phase 1: Dropdown Z-Ordering Bug

Fix dropdown panel rendering behind other UI elements.

**File:** `src/bh/ui/UIMultiAnimDropdown.hx`
**Pattern:** Same as `UITooltipHelper`/`UIPanelHelper` which use `screen.addObjectToLayer(result.object, layer)`

**Changes:**
1. Add fields: `panelScreen:Null<UIScreen>`, `panelLayer:Null<LayersEnum>`
2. In `customAddToLayer()`: store screen and layer references
3. In `doRedraw()` (~line 255): after creating `PositionLinkObject`, call `panelScreen.addObjectToLayer(panelObject, panelScreen.getHigherLayer(panelLayer))`
4. In `clear()`: null out stored refs

## Phase 2: Codegen Transition Support

Make `transition {}` blocks work in `@:manim` codegen path. Currently parsed but ignored — generated setters do instant `obj.visible = bool`.

### Architecture

Extract transition execution into a shared runtime helper. Generated instances delegate to it. Keep generated code minimal.

### New file: `src/bh/multianim/CodegenTransitionHelper.hx`

Runtime class holding:
- `transitionSpecs:Map<String, TransitionType>` — transition declarations
- `tweenManager:Null<TweenManager>` — injected at runtime
- `activeTransitionTweens:Array<{obj, tween, savedAlpha, savedScaleX, savedScaleY, savedX, savedY}>`

Methods:
- `setVisibilityWithTransition(obj, newVisible, changedParam)` — main entry point
- `cancelActiveTransition(obj)` — cancel + restore pre-transition state
- `cancelAllTransitions()` — cleanup
- `executeTransition(obj, show, spec)` — create tweens based on TransitionType

Logic mirrors `IncrementalUpdateContext` lines 482-612 in `MultiAnimBuilder.hx`.

### Changes to `ProgrammableBuilder.hx`

Add `public var tweenManager:Null<TweenManager> = null` field so factories auto-inject into instances.

### Changes to `ProgrammableCodeGen.hx`

1. **Static state:** Add `currentTransitions:Null<Map<String, TransitionType>>`, reset in `resetState()`
2. **Visibility tracking:** Add `paramRefs:Array<String>` to `visibilityEntries` — tracks which params each conditional depends on
3. **Param extraction:** `extractConditionalParamRefs()` — examines `node.conditionals` to get referenced param names (handles `@else`/`@default` by collecting from prior siblings)
4. **Macro serialization:** `transitionTypeToExpr()`/`easingToExpr()`/`transitionDirToExpr()` — serialize enum values as Haxe macro expressions with fully-qualified type paths
5. **Instance fields:** Generate `_transHelper:Null<CodegenTransitionHelper>` field when transitions exist
6. **Constructor:** Generate transition map initialization + `new CodegenTransitionHelper(map)`
7. **`_applyVisibility(?_changedParam:String)`:** When transitions exist, branch:
   - `_transHelper != null && _changedParam != null && tweenManager != null` → call `setVisibilityWithTransition()` per entry
   - Otherwise → instant `obj.visible = condition` (existing behavior)
   - Entries whose `paramRefs` don't intersect transition-declared params always use instant path
8. **Setters:** Pass param name string: `_applyVisibility("status")` for params with transitions
9. **Public methods:** Generate `setTweenManager(tm)` and `cancelAllTransitions()` on instances
10. **Factory `create()`/`createFrom()`:** Auto-inject TweenManager from factory into instance

### Backward compatibility

- No `_transHelper` generated when `transition {}` is absent → zero overhead
- Instant fallback when TweenManager is null
- Constructor calls `_applyVisibility()` with no param → always instant for initial render

### Test

Change test95 from `simpleTest` to `simpleMacroTest` in `ProgrammableCodeGenTest.hx`.

## Phase 3: Integration Tests

### 3a. Card Hand Orchestration (~35 tests)

**New file:** `test/src/bh/test/examples/CardHandOrchestratorIntegrationTest.hx`

Extends existing `CardHandOrchestratorTest.hx` pattern (41 layout math tests already exist).

- `setHand` / `drawCard` / `discardCard` / `updateCardParams` / `setCardEnabled`
- Card state machine: InHand → Hovering → Dragging → Animating → Return
- Drag threshold, targeting mode activation
- Card-to-card hover detection + `CardCombined` events
- `CardPlayed(TargetZone|NoTarget)` event emission
- `canPlayCard` / `canDragCard` veto callbacks
- Target registration, highlight callback, accepts filter
- Concurrent animations, z-order management

### 3b. .anim Typed Filter Runtime (~25 tests)

**New file:** `test/src/bh/test/examples/AnimFilterStateConditionalTest.hx`

Extends existing `AnimFilterRuntimeTest.hx` pattern (36 parser/basic tests already exist).

- State-conditional filters: `@(state=>value)` selection at runtime
- `@else` / `@default` filter fallbacks
- Filter switching on state selector change
- Playlist per-frame filters: `filter tint:` / `filter none`
- Multiple filter combinations with state conditionals
- Full filter type coverage

### 3c. Screen Transition Integration (~30 tests)

**New file:** `test/src/bh/test/examples/ScreenTransitionIntegrationTest.hx`

Extends existing `ScreenTransitionTest.hx` pattern (11 enum tests already exist).

- `ScreenManager.switchTo()` with Fade/Slide transitions
- `isTransitioning` flag during animation
- Input routing to new screen during transition
- `finalizeTransition()` jump-to-end
- Transition interruption (new transition while in progress)
- Modal dialog transitions
- Layer ordering during transitions

### 3d. Animated Path Builder/Codegen (~20 tests)

**New file:** `test/src/bh/test/examples/AnimatedPathBuilderTest.hx`

Extends existing `AnimatedPathTest.hx` (50 tests) + `BuilderUnitTest.hx` (15 tests).

- `builder.createAnimatedPath()` end-to-end
- `builder.createProjectilePath()` with Stretch normalization
- Codegen `factory.createAnimatedPath_name()` generation + execution
- `getClosestRate()` through builder path
- Easing shorthand resolution in builder context
- Per-segment color interpolation through builder

## Phase 4: Transition Edge Cases

- Parse-time warning for `slide()` inside `flow()` ancestor
- Parser test for invalid easing name in `transition {}` block
- Builder test for mid-transition parameter change (cancel + restart)

## Phase 5: Release Preparation

1. Version bump: `haxelib.json` → `1.0.0-rc.1`
2. Fill `releasenote` field in `haxelib.json`
3. Finalize CHANGELOG: rename `[0.13-dev]` → `[1.0.0-rc.1]`, set date
4. Local validation: `haxelib dev hx-multianim .`
5. CI workflow: `.github/workflows/release-and-publish.yml` (auto-publish on version bump)
6. Documentation review: ensure `docs/manim-reference.md` and `docs/manim.md` cover codegen transitions

## Post-RC (for 1.0.0 final)

- Address issues found during RC usage
- `slide()` in `flow()` fix or parse-time error
- Performance: per-param `_applyVisibility_X()` codegen optimization
- Bump to `1.0.0` final

## Verification

After each phase:
- `haxe hx-multianim.hxml` — library compiles
- `test.bat run` — all tests pass
- After Phase 3: test count ~3460+ assertions
- After Phase 5: `haxelib dev hx-multianim .` succeeds
