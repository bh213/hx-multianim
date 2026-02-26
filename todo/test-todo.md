# Test TODO

| # | Item | Summary | Priority |
|---|------|---------|----------|
| 5 | `UIRichInteractiveHelper` tests | register() bind scanning, handleEvent() state machine, setDisabled | Medium |
| 6 | `UITooltipHelper` tests | startHover/cancelHover, delay, show/hide, positioning | Medium |
| 7 | `UIPanelHelper` tests | open/close, isOpen, outsideClick, close modes, named panels | Medium |
| 8 | Parser error coverage | Malformed expressions, invalid types, duplicates, circular refs | Medium |
| 9 | Builder error paths | Missing programmable, wrong types, undefined $ref, slot mismatches | Medium |
| 10 | Interactive event tests | Event filtering, bind metadata, UIClickOutside, disabled gating | Medium |
| 11 | `UIClickOutside` event | Documented but not tested | Low |
| 12 | AnimMetadata API | State-selector getInt/getString methods untested | Low |
| 13 | Hex offset/doubled coordinates | $hex.offset and $hex.doubled not specifically tested | Low |
| 14 | Animated path events | pathStart/End, cycleStart/End not asserted programmatically | Low |
| 15 | Particle runtime API | addForceField, removeForceFieldAt, sub-emitters untested | Low |
| 16 | `autoSyncInitialState` | No test verifying initial sync behavior | Low |
| 17 | Test numbering audit | Tests 62, 77 are unit-only in visual test dirs, consider moving | Low |

## Visual Tests Fixes

General visual test issues that need attention.

## Missing UI Component Tests

### Tabs (`UIMultiAnimTabs`) — HIGH
No visual or unit tests. Needs: creation, tab switching (`beginTab`/`endTab`), `ContentTarget` routing, `tabPanel.contentRoot` relative mode, `UIChangeItem` event.

## Missing Helper Tests

### `UIRichInteractiveHelper` — MEDIUM
No dedicated test for state binding auto-wiring. Needs: `register()` scanning bind metadata, `handleEvent()` driving Normal->Hover->Pressed->Normal, `setDisabled()`.

### `UITooltipHelper` — MEDIUM
No tests. Needs: `startHover`/`cancelHover`, delay behavior, `show`/`hide`, position/offset configuration.

### `UIPanelHelper` — MEDIUM
No tests. Needs: `open`/`close`, `isOpen`, `handleOutsideClick`, `OutsideClick`/`Manual` close modes.

## Missing Parser / Builder Error Tests

### Parser Error Coverage — MEDIUM
Current `ParserErrorTest` only covers conditional validation (`@else`/`@default` ordering). Missing error cases: malformed expressions, invalid parameter types, unknown element types, duplicate programmable names, circular references, invalid coordinate system syntax.

### Builder Error Paths — MEDIUM
No negative tests for builder. Missing: reference to non-existent programmable, wrong parameter types, undefined `$ref`, invalid filter parameters, slot name mismatches (indexed vs non-indexed).

## Missing Interactive Tests

- **UIRichInteractiveHelper** — no tests for `register()`, `handleEvent()`, `setDisabled()`
- **UITooltipHelper** — no tests for delay, show/hide, positioning
- **UIPanelHelper** — no tests for open/close, outside-click, deferred close, named panels
- **Event filtering** (`events: [hover, click, push]`) — no unit test
- **`bind` metadata** — no unit test
- **`UIClickOutside`** — no unit or visual test
- **Disabled interactive** gating events — no test

## Test Numbering Audit

Tests 1-91 exist as directories. Numbering is **continuous with no gaps**.

Two directories have no visual test method (unit-only, by design):
- **62** — `dataBlock` — used via `builder.getData()` in unit tests only
- **77** — `pvFactorySettings` — used in PVFactory unit tests, builds manually (no `@:manim` registration)

These are non-visual tests living inside the visual test numbering scheme (`test/examples/`). Consider refactoring: either move their unit tests out of `ProgrammableCodeGenTest.hx` into `BuilderUnitTest.hx` where other non-visual builder tests live, or relocate their data files out of `test/examples/` to avoid confusion with the visual test sequence.

All other 89 directories (1-91 minus 62, 77) have both a `testNN_` method in `ProgrammableCodeGenTest.hx` and a `@:manim` registration in `MultiProgrammable.hx`.

## Missing Feature Coverage

### `UIClickOutside` Event — LOW
Documented in CLAUDE.md but not tested. Add a `UIComponentTest` case verifying `UIInteractiveEvent(UIClickOutside, ...)` fires correctly.

### AnimMetadata API (`.anim`) — LOW
`getIntOrDefault`, `getStringOrDefault`, `getIntOrException`, `getStringOrException` with state selectors — no unit tests in `AnimParserTest`.

### Hex Offset/Doubled Coordinates — LOW
`$hex.offset(col, row, even|odd)` and `$hex.doubled(col, row)` not specifically tested. Tests 47/87 cover hex cube/corner/edge only.

### Animated Path Events — LOW
`pathStart`, `pathEnd`, `cycleStart`, `cycleEnd` events not asserted programmatically. Test 61 only does visual sampling.

### Particle Runtime API — LOW
`addForceField`, `removeForceFieldAt`, `clearForceFields`, sub-emitters — no unit tests. Only visual particle test (51) with seeded comparison.

### `autoSyncInitialState` — LOW
Referenced in commit history but no test verifying the behavior.
