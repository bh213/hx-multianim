# Test TODO

| # | Item | Summary | Priority |
|---|------|---------|----------|

| 13 | Hex offset/doubled coordinates | $hex.offset and $hex.doubled not specifically tested | Low |
| 15 | Particle runtime API | addForceField, removeForceFieldAt, sub-emitters untested | Low |
| 17 | Test numbering audit | Tests 62, 77 are unit-only in visual test dirs, consider moving | Low |
| 18 | .anim @default conditional | No test for @default fallback behavior in AnimParserTest | Low |
| 19 | .anim filter declarations | `filters { }` block untested in AnimParserTest | Low |
| 20 | .anim typed event metadata | Event metadata payload (`event hit { damage:int => 5 }`) untested | Low |

## Visual Tests Fixes

General visual test issues that need attention.

## Test Numbering Audit

Tests 1-91 exist as directories. Numbering is **continuous with no gaps**.

Two directories have no visual test method (unit-only, by design):
- **62** — `dataBlock` — used via `builder.getData()` in unit tests only
- **77** — `pvFactorySettings` — used in PVFactory unit tests, builds manually (no `@:manim` registration)

These are non-visual tests living inside the visual test numbering scheme (`test/examples/`). Consider refactoring: either move their unit tests out of `ProgrammableCodeGenTest.hx` into `BuilderUnitTest.hx` where other non-visual builder tests live, or relocate their data files out of `test/examples/` to avoid confusion with the visual test sequence.

All other 89 directories (1-91 minus 62, 77) have both a `testNN_` method in `ProgrammableCodeGenTest.hx` and a `@:manim` registration in `MultiProgrammable.hx`.

## Missing Feature Coverage

### Hex Offset/Doubled Coordinates — LOW
`$hex.offset(col, row, even|odd)` and `$hex.doubled(col, row)` not specifically tested. Tests 47/87 cover hex cube/corner/edge only.

### Particle Runtime API — LOW
`addForceField`, `removeForceFieldAt`, `clearForceFields`, sub-emitters — no unit tests. Only visual particle test (51) with seeded comparison.

### .anim @default Conditional — LOW
`@default` fallback in extrapoints/animation blocks. `@else` is tested but `@default` has no dedicated test.

### .anim Filter Declarations — LOW
`filters { replaceColor: ... }` block added to parser but no test coverage.

### .anim Typed Event Metadata — LOW
`event hit { damage:int => 5, element => "fire" }` — events with typed metadata payload. Parser has `parseEventMeta()` but no test exercises it.

