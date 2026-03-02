# Test TODO

## Priority Table

| # | Item | Summary | Priority |
|---|------|---------|----------|
| 1 | Card hand orchestration | Full state machine, drag, targeting, card-to-card, animations (layout math covered) | High |
| 2 | .anim typed filter runtime | Runtime filter application via AnimationSM, state conditionals, playlist filters | High |
| 3 | Screen transition integration | ScreenManager integration (enum + pattern matching covered, runtime behavior not) | Medium |
| 4 | Animated path integration | Builder/codegen + createProjectilePath, getClosestRate (runtime API covered) | Medium |
| 5 | Interactive cursor metadata | cursor => "pointer", cursor.hover => "move", invalid suffix throws | Medium |
| 6 | Rich text codegen | @:manim codegen for richText styles/images, runtime parameter updates on HtmlText | Medium |
| 7 | Dynamic ref codegen | Macro-generated dynamicRef, nested refs via codegen path | Low |
| 8 | Test numbering audit | Tests 62, 77 are unit-only in visual test dirs, consider moving | Low |

## Current Test Coverage Summary

**22 test files, ~1187 test methods, 92 visual test examples**

### Well Covered
- Parser & language (BuilderUnitTest: 248, ParserErrorTest: 254)
- Macro codegen (ProgrammableCodeGenTest: 176 methods, 92 visual tests)
- UI components (UIComponentTest: 192 — buttons, checkboxes, sliders, dropdowns, text inputs, scrollable lists, tabs, drag-drop, card hand layout, modals, overlays)
- .anim parser (AnimParserTest: 115 — format, metadata, filters, conditions)
- TweenManager (TweenManagerTest: 36 — tweens, sequences, groups, easing, cancellation)
- Interactive helpers (UIRichInteractiveHelper: 40, UIPanelHelper: 48, UITooltipHelper: 26)
- Particle runtime (ParticleRuntimeTest: 15 — force fields, burst, sub-emitters)
- Hot reload (HotReloadTest: 28)
- Rich text markup (RichTextTest: 46 — convert, hasMarkup, extractStyleReferences, resolveColorToHex, escapeStyleName)
- Animated path runtime (AnimatedPathTest: 40 — time/distance modes, seek, reset, events, curves, loops, pingPong, color, custom curves)
- AnimationSM runtime (AnimFilterRuntimeTest: 26 — registration, play, loops, filters, tint, events, extra points, pause)
- Card hand layout math (CardHandOrchestratorTest: 26 — fan/linear/path layout, hover, enums)
- Screen transitions enum (ScreenTransitionTest: 11 — all variants, pattern matching, custom callback, duration extraction)
- Flow overflow & alignment (FlowOverflowTest: 17 — overflow modes, fill, reverse, alignment, spacer, @flow.* properties)
- Interactive events (InteractiveEventTest: 14 — event flag parsing, id/prefix, metadata, disabled/hovered state)
- Parameterized slots (ParameterizedSlotTest: 14 — basic/parameterized/indexed slots, setParameter, setContent, clear, data, errors)
- Dynamic refs (DynamicRefTest: 10 — basic build, getDynamicRef, setParameter, multiple/nested refs, static values, errors)
- Bit flags (BitFlagTest: 13 — individual bits, multiple bits, zero flags, @else after bit, high bit)

### Recently Added (staged)
- ScreenTransitionTest (11 methods) — enum variants, pattern matching, custom callbacks
- AnimatedPathTest (40 methods) — time/distance modes, seek, reset, events, all curve types
- CardHandOrchestratorTest (26 methods) — fan/linear/path layout math, type enums
- AnimFilterRuntimeTest (26 methods) — AnimationSM playback, loops, filters, tint, events
- RichTextTest (46 methods) — TextMarkupConverter unit tests
- ParameterizedSlotTest (14 methods) — slot lifecycle, parameterized slots, indexed slots
- InteractiveEventTest (14 methods) — event bitmask, metadata, wrapper construction
- FlowOverflowTest (17 methods) — all overflow modes, fill, reverse, alignment, @flow.*
- DynamicRefTest (10 methods) — dynamicRef build, parameter passing, sub-result access
- BitFlagTest (13 methods) — bit[N] conditionals, multi-bit, @else/@default

## Detailed Gap Analysis

### 1. Card Hand Orchestration (HIGH)
**Status:** Layout math fully tested (fan, linear, path). Full state machine and orchestration untested.

Missing tests:
- `setHand(descriptors)` — initial hand setup
- `drawCard(descriptor)` — draw animation, CardState changes
- `discardCard(id)` — discard animation
- `updateCardParams(id, params)` — runtime parameter updates
- `setCardEnabled(id, bool)` — disabled state
- Card state machine (InHand -> Hovering -> Dragging -> Animating)
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

### 2. .anim Typed Filter Runtime (HIGH)
**Status:** Parser tests cover syntax. AnimFilterRuntimeTest covers basic playback/events. No typed filter runtime tests.

Missing tests:
- State-conditional filters (`@(state=>value)`, `@else`, `@default`) applied at runtime
- Playlist per-frame filters (`filter tint:`, `filter none`)
- Multiple filter combination in filters{} block
- Filter types: tint, brightness, saturate, grayscale, hue, outline, pixelOutline, replaceColor
- Filter parameter changes when state selector changes

### 3. Screen Transition Integration (MEDIUM)
**Status:** Enum construction + pattern matching tested. No ScreenManager integration.

Missing tests:
- `isTransitioning` flag during animation
- Input routing to new screen during transition
- Transition interruption (new transition while in progress -> finalize current)
- `finalizeTransition()` jump-to-end behavior
- Modal dialog with transition (open + close)
- Layer ordering during transitions

### 4. Animated Path Integration (MEDIUM)
**Status:** Runtime API thoroughly tested (40 methods). Builder/codegen path untested.

Missing tests:
- Builder: `builder.createAnimatedPath("name", ?startPoint, ?endPoint)`
- Builder: `builder.createProjectilePath("name", startPoint, endPoint)` with Stretch normalization
- Codegen: `factory.createAnimatedPath_name()` macro-generated path access
- `path.getClosestRate(worldPoint)` reverse lookup
- Easing shorthand resolution (`easing: easeOutCubic` in .manim)

### 5. Interactive Cursor Metadata (MEDIUM)
**Status:** Event flags and metadata basics tested. Cursor integration not tested.

Missing tests:
- `cursor => "pointer"` metadata on interactive
- `cursor.hover => "move"`, `cursor.disabled => "default"` per-state cursors
- Unknown `cursor.*` suffix throws
- CursorManager registry integration

### 6. Rich Text Codegen (MEDIUM)
**Status:** TextMarkupConverter thoroughly tested (46 methods). No codegen tests.

Missing tests:
- `@:manim` codegen for `richText()` with styles/images
- Generated `setStyleColor_<name>()`, `setStyleFont_<name>()`, `setImageTile_<name>()` setters
- Runtime parameter updates propagating to HtmlText
- Dynamic style colors with `$param` references in codegen path

### 7. Dynamic Ref Codegen (LOW)
**Status:** Builder path tested (10 methods). No codegen path tests.

Missing tests:
- Macro-generated dynamicRef access
- Nested refs via codegen path
- Conditional branches containing dynamicRef

## Test Numbering Audit

Tests 1-92 exist as directories. Numbering is **continuous with no gaps**.

Two directories have no visual test method (unit-only, by design):
- **62** — `dataBlock` — used via `builder.getData()` in unit tests only
- **77** — `pvFactorySettings` — used in PVFactory unit tests, builds manually (no `@:manim` registration)

These are non-visual tests living inside the visual test numbering scheme (`test/examples/`). Consider refactoring: either move their unit tests out of `ProgrammableCodeGenTest.hx` into `BuilderUnitTest.hx` where other non-visual builder tests live, or relocate their data files out of `test/examples/` to avoid confusion with the visual test sequence.

All other 90 directories (1-92 minus 62, 77) have both a `testNN_` method in `ProgrammableCodeGenTest.hx` and a `@:manim` registration in `MultiProgrammable.hx`.
