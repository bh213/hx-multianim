# Test TODO

| # | Item | Summary | Priority |
|---|------|---------|----------|


| 15 | Particle runtime API | addForceField, removeForceFieldAt, sub-emitters untested | Low |
| 17 | Test numbering audit | Tests 62, 77 are unit-only in visual test dirs, consider moving | Low |

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

### ~~Hex Offset/Doubled Coordinates~~ — DONE
6 unit tests added in `BuilderUnitTest.hx`: flat orientation offset/doubled, non-zero row offset, named hex offset/doubled. Existing tests cover pointy orientation, even/odd parity, XY extraction. Note: `.offset()` suffix cannot chain on `$hex.offset()`/`$hex.doubled()` — parser treats trailing `.offset` as hex chain method.

### Particle Runtime API — LOW
`addForceField`, `removeForceFieldAt`, `clearForceFields`, sub-emitters — no unit tests. Only visual particle test (51) with seeded comparison.

### ~~.anim @default Conditional~~ — DONE
4 tests added in `AnimParserTest.hx`: `@default` in extrapoints, metadata (with value assertions), playlist conditionals, and combined `@else`+`@default` chains.

### ~~.anim Filter Declarations~~ — DONE
20 typed filter tests added: all filter types (`tint`, `brightness`, `saturate`, `grayscale`, `hue`, `outline`, `pixelOutline`, `replaceColor`, `none`), conditionals, playlist filters, error cases.

### ~~.anim Typed Event Metadata~~ — DONE
4 tests added in `AnimParserTest.hx`: trigger event with metadata, point event with metadata, all types (int/float/string/color/bool), random point event with metadata.

