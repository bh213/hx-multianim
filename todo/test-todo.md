# Test TODO

## Priority Table

| # | Item | Summary | Priority |
|---|------|---------|----------|
| 1 | Screen transitions | ScreenTransition enum staged but no tests — integration with ScreenManager | High |
| 2 | Animated path runtime API | update(dt), seek(), reset(), events, state fields, curves | High |
| 3 | Card hand orchestration | Full state machine, drag, targeting, card-to-card, animations | High |
| 4 | .anim typed filter runtime | Runtime filter application, state conditionals, playlist filters | High |
| 5 | Rich text unit tests | Markup parsing, styles, dynamic colors, escape sequences | Medium |
| 6 | Parameterized slot unit tests | setParameter(), conditionals, content overlay | Medium |
| 7 | Interactive events bitmask | EVENT_HOVER/CLICK/PUSH filtering, cursor metadata per-state | Medium |
| 8 | Flow overflow & alignment | overflow modes, fillWidth/Height, @flow.* props, reverse | Medium |
| 9 | Dynamic ref edge cases | Nested refs, scope isolation, conditional branches | Low |
| 10 | Bit flag operations | @(param => bit[N]) runtime behavior | Low |
| 11 | Test numbering audit | Tests 62, 77 are unit-only in visual test dirs, consider moving | Low |

## Current Test Coverage Summary

**12 test files, ~970 test methods, 92 visual test examples**

### Well Covered
- Parser & language (BuilderUnitTest: 248, ParserErrorTest: 254)
- Macro codegen (ProgrammableCodeGenTest: 176 methods, 92 visual tests)
- UI components (UIComponentTest: 192 — buttons, checkboxes, sliders, dropdowns, text inputs, scrollable lists, tabs, drag-drop, card hand layout, modals, overlays)
- .anim parser (AnimParserTest: 115 — format, metadata, filters, conditions)
- TweenManager (TweenManagerTest: 36 — tweens, sequences, groups, easing, cancellation)
- Interactive helpers (UIRichInteractiveHelper: 40, UIPanelHelper: 48, UITooltipHelper: 26)
- Particle runtime (ParticleRuntimeTest: 15 — force fields, burst, sub-emitters)
- Hot reload (HotReloadTest: 28)

### Recently Added (last 15 commits)
- TweenManager tests (staged, 36 methods)
- Particle runtime API tests (15 methods)
- Modal overlay config parsing tests (6 methods in UIComponentTest)
- Card hand layout math tests (in UIComponentTest)
- AnimParser typed filter parsing tests

## Detailed Gap Analysis

### 1. Screen Transitions (HIGH)
**Status:** ScreenTransition enum and ScreenManager integration staged but untested.

Missing tests:
- Fade transition (alpha tween on old/new roots)
- Slide transitions (Left/Right/Up/Down positioning + tweens)
- Custom transition callback invocation
- Transition with easing types
- `isTransitioning` flag during animation
- Input routing to new screen during transition
- Transition interruption (new transition while one is in progress → finalize current)
- `finalizeTransition()` jump-to-end behavior
- Modal dialog with transition (open + close)
- Layer ordering during transitions (layerContent, layerMaster, layerOverlay, layerDialog)

### 2. Animated Path Runtime API (HIGH)
**Status:** Visual tests exist (58-59, 61). Builder can load. No runtime API tests.

Missing tests:
- `AnimatedPath.update(dt)` returns `AnimatedPathState`
- `seek(rate)` without side effects
- `reset()` for reuse
- State fields: position, angle, rate, speed, scale, alpha, rotation, color, cycle, done, custom
- Events: pathStart, pathEnd, cycleStart, cycleEnd
- Loop and pingPong modes
- Time-based vs distance-based (type: time/distance)
- Speed/scale/rotation/alpha/progress curves during playback
- Color interpolation across segments (multiple colorCurve at different rates)
- Custom curves (`custom("name"): curveName`)
- `getClosestRate(worldPoint)` reverse lookup
- `createProjectilePath()` with Stretch normalization
- Easing shorthand (`easing: easeOutCubic`)
- Duration and speed properties

### 3. Card Hand Orchestration (HIGH)
**Status:** Layout math tested. Full state machine and orchestration untested.

Missing tests:
- `setHand(descriptors)` — initial hand setup
- `drawCard(descriptor)` — draw animation, CardState changes
- `discardCard(id)` — discard animation
- `updateCardParams(id, params)` — runtime parameter updates
- `setCardEnabled(id, bool)` — disabled state
- Card state machine (InHand → Hovering → Dragging → Animating)
- Drag threshold detection (below = return, above = play)
- Targeting mode activation (drag above threshold)
- Card-to-card detection and `CardCombined` event
- `CardPlayed(TargetZone)` and `CardPlayed(NoTarget)` events
- `canPlayCard` / `canDragCard` veto callbacks
- `onCardBuilt` callback invocation
- `registerTargetInteractive()` / `unregisterTargetInteractive()`
- `setTargetHighlightCallback()` / `setTargetAcceptsFilter()`
- Concurrent animations (multiple cards animating simultaneously)
- Z-order management during hover
- Hover detection via `getCardAtBasePosition()` (not UIEntering events)
- Return animation when drag cancelled

### 4. .anim Typed Filter Runtime (HIGH)
**Status:** Parser tests cover syntax. No runtime application tests.

Missing tests:
- Filter application via AnimationSM at runtime
- State-conditional filters (`@(state=>value)`, `@else`, `@default`)
- Playlist per-frame filters (`filter tint:`, `filter none`)
- Multiple filter combination in filters{} block
- Filter types: tint, brightness, saturate, grayscale, hue, outline, pixelOutline, replaceColor
- Filter parameter changes when state changes

### 5. Rich Text Unit Tests (MEDIUM)
**Status:** Visual test 92 exists. No unit tests.

Missing tests:
- `[tag]...[/]` markup parsing
- `[img name]` image insertion
- `[color=#RRGGBB]...[/]` inline color
- `styles:` definitions and inheritance
- Dynamic style colors with `$param` references
- `%%{` escape sequence
- `images:` tile definitions
- richText() vs text() element distinction
- Runtime parameter updates on rich text

### 6. Parameterized Slots (MEDIUM)
**Status:** Visual test 81-slotParams exists. No unit tests.

Missing tests:
- `SlotHandle.setParameter("name", value)` updates
- Conditional rendering inside parameterized slot body
- `setContent()` on parameterized slot (content goes to contentRoot)
- Decoration always visible regardless of content state
- beginUpdate()/endUpdate() batching with incremental mode
- Codegen: `buildParameterizedSlot()` invocation

### 7. Interactive Events Bitmask (MEDIUM)
**Status:** No tests for event filtering feature.

Missing tests:
- `events: [hover]` → only UIEntering/UILeaving emitted
- `events: [click]` → only UIClick emitted
- `events: [push]` → only UIPush emitted
- `events: [hover, click]` combinations
- Default (no events:) → EVENT_ALL behavior
- Cursor metadata: `cursor => "pointer"`, `cursor.hover => "move"`, `cursor.disabled => "default"`
- Invalid cursor suffix throws

### 8. Flow Overflow & Alignment (MEDIUM)
**Status:** Visual tests 6, 72 exist. No unit tests for new features.

Missing tests:
- `overflow: expand` (default), `limit`, `scroll`, `hidden`
- `fillWidth: true` / `fillHeight: true`
- `reverse: true` layout
- `horizontalAlign` / `verticalAlign` container defaults
- `@flow.halign()`, `@flow.valign()` per-child overrides
- `@flow.offset(x, y)` pixel offset
- `@flow.absolute` — remove from layout
- Parse-time validation: @flow.* must be inside flow ancestor

## Test Numbering Audit

Tests 1-92 exist as directories. Numbering is **continuous with no gaps**.

Two directories have no visual test method (unit-only, by design):
- **62** — `dataBlock` — used via `builder.getData()` in unit tests only
- **77** — `pvFactorySettings` — used in PVFactory unit tests, builds manually (no `@:manim` registration)

These are non-visual tests living inside the visual test numbering scheme (`test/examples/`). Consider refactoring: either move their unit tests out of `ProgrammableCodeGenTest.hx` into `BuilderUnitTest.hx` where other non-visual builder tests live, or relocate their data files out of `test/examples/` to avoid confusion with the visual test sequence.

All other 90 directories (1-92 minus 62, 77) have both a `testNN_` method in `ProgrammableCodeGenTest.hx` and a `@:manim` registration in `MultiProgrammable.hx`.
