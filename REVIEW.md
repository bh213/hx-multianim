# hx-multianim — Comprehensive Code Review

Deep review of the codebase, documentation, and design of **hx-multianim**: a Haxe library for declarative animations and pixel-art UI using the Heaps framework.

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Bugs](#bugs)
3. [Documentation Inaccuracies](#documentation-inaccuracies)
4. [Missing Features & Incomplete Implementations](#missing-features--incomplete-implementations)
5. [Code Quality & Consistency](#code-quality--consistency)
6. [Test Coverage Gaps](#test-coverage-gaps)
7. [Design Suggestions](#design-suggestions)

---

## Executive Summary

The project is well-designed with a coherent architecture: a custom `.manim` DSL parsed at both compile-time and runtime, a builder that produces Heaps scene graphs, and a macro codegen system that generates typed Haxe APIs. The `.anim` state animation system is clean and focused. The library serves its gamedev/prototyping niche effectively.

That said, the review identified **6 likely bugs**, **5 documentation inaccuracies**, **8 incomplete features**, significant code duplication in the parser, UI component inconsistencies, and substantial test coverage gaps — particularly around runtime behavior, edge cases, and the UI layer.

---

## Bugs

### BUG-1: Parser — `parseCoordinateMethodChain()` return value discarded

**File:** `src/bh/multianim/MacroManimParser.hx` ~line 1103

When parsing a coordinate expression like `$ref.someMethod(...)`, the result of `parseCoordinateMethodChain(s)` is not returned/assigned in the `if (match(TDot))` branch. The expression result is silently dropped and execution falls through, likely producing incorrect coordinate values or a parse error.

**Severity:** High — silent wrong behavior for coordinate method chains.

---

### BUG-2: Particles — Empty tiles array crash

**File:** `src/bh/base/Particles.hx` ~line 733

```haxe
p.t = tiles[0]; // CRASH if tiles.length == 0
```

No bounds check before accessing `tiles[0]`. If a particle group is configured without tile sources, this crashes at runtime.

**Severity:** High — runtime crash.

---

### BUG-3: Builder — Unreachable `case null` after `default`

**File:** `src/bh/multianim/MultiAnimBuilder.hx` ~line 3004

```haxe
case CBRObject(val): val;
case CBRNoResult: null;
default: throw '...';
case null: null;  // unreachable
```

The `case null` appears after `default` and can never match. If null was intended to be handled, it needs to come before `default`.

**Severity:** Medium — dead code, possible unhandled null.

---

### BUG-4: Builder — `getIntOrDefault`/`getStringOrDefault` throw instead of returning default

**File:** `src/bh/multianim/MultiAnimBuilder.hx` ~lines 175-217

Functions named `*OrDefault` throw an exception when `settings` is null, rather than returning the default value. The name is misleading and the behavior is wrong if callers expect graceful fallback.

**Severity:** Medium — API contract violation.

---

### BUG-5: Parser — Color/name ambiguity for `#xxx` tokens

**File:** `src/bh/multianim/MacroManimParser.hx` ~lines 873-877

When the parser encounters a `TName` token like `#ff0`, it tries to interpret it as a hex color first. If the user defines a named element `#ff0` (unlikely but valid), it would be silently parsed as the color value `0xFFFF00` instead. No warning is issued.

**Severity:** Low — edge case, but a silent semantic error.

---

### BUG-6: Codegen — Integer bounds use `-0x7FFFFFFF` instead of `Int.MIN_VALUE`

**File:** `src/bh/multianim/ProgrammableCodeGen.hx` ~line 3389

```haxe
var maxX:Int = -0x7FFFFFFF;
```

This is `-2147483647`, which is off by 1 from `Int.MIN_VALUE` (`-2147483648`). Could cause incorrect bounding box calculations for pixel elements that happen to land at the extreme boundary.

**Severity:** Low — extremely unlikely to hit in practice.

---

## Documentation Inaccuracies

### DOC-1: CLAUDE.md — Particle sub-emitters listed as "not yet implemented"

**File:** `CLAUDE.md` line ~325

States: *"Particle sub-emitters (parsing and building complete, runtime spawning in `Particles.hx` not yet implemented)"*

**Reality:** Sub-emitters are **fully implemented** in `Particles.hx`:
- `triggerSubEmitters()` at line ~984 handles OnBirth, OnDeath, OnCollision
- `checkIntervalSubEmitters()` at line ~1036 handles OnInterval
- All four trigger types work, including probability and burst count

The TODO should be removed or updated to reflect the actual status.

---

### DOC-2: docs/anim.md — `createAnimSM()` parameter mismatch

**File:** `docs/anim.md` ~line 477

Documentation shows: `parsed.createAnimSM(stateSelector, true)` with an `externallyDriven` parameter. But `AnimParser.createAnimSM()` does not accept or forward this parameter. The `externallyDriven` flag exists on the `AnimationSM` constructor but isn't exposed through the parser API.

---

### DOC-3: docs/anim.md — Wrong API method name

**File:** `docs/anim.md` ~lines 399, 453

References `resourceLoader.loadAnimParser()` but the actual API is the static method `AnimParser.parseFile()` or `AnimParser.parseString()`.

---

### DOC-4: CLAUDE.md — Missing AnimMetadata documentation

The `AnimMetadata` class (AnimParser.hx lines ~255-320) with methods like `getIntOrDefault()`, `getStringOrException()` etc. is fully implemented but not mentioned in CLAUDE.md. Only documented in docs/anim.md.

---

### DOC-5: CLAUDE.md — `bit` conditional syntax undocumented

The parser supports `@(param => bit[index])` syntax (MacroManimParser.hx ~lines 1831-1836) for bitwise flag testing, but this is not mentioned in the CLAUDE.md quick reference or the conditional syntax documentation.

---

## Missing Features & Incomplete Implementations

### FEAT-1: Hex coordinate offset support

**Status:** Listed in CLAUDE.md TODOs, confirmed not implemented. `$hex.offset(col, row, even|odd)` parsing exists but full coordinate offset support is incomplete.

### FEAT-2: Conditional not working with repeatable variables

**Status:** Listed in CLAUDE.md TODOs. Conditions like `@(index >= 3)` inside `repeatable` blocks don't evaluate correctly against loop iteration variables.

### FEAT-3: Repeatable step scale for dx/dy

**Status:** Listed in CLAUDE.md TODOs, no fix found. Step scaling for repeatable elements using `dx`/`dy` offsets doesn't work correctly.

### FEAT-4: Generic components support

**Status:** Listed as "next feature" in CLAUDE.md. No implementation found.

### FEAT-5: Bit expressions (anyBit/allBits)

**Status:** Listed as "next feature" in CLAUDE.md. No implementation found.

### FEAT-6: ByEdges autotile selector

**File:** `MacroManimParser.hx` ~line 1517

TODO comment: `// TODO: ByEdges parsing if needed`. Only `ByIndex` is implemented for autotile tile selection.

### FEAT-7: Codegen — Runtime hex pixel-to-coordinate conversion

**File:** `ProgrammableCodeGen.hx` ~line 4615

```haxe
// TODO: generate runtime code for pixel coord resolution
null;
```

`SELECTED_HEX_PIXEL` returns null, preventing runtime hex pixel coordinate resolution in generated code.

### FEAT-8: UIScreenBase — `addCheckboxWithText()` incomplete

**File:** `src/bh/ui/screens/UIScreen.hx` ~line 355

Marked with `// TODO: needs work` but is part of the public API.

---

## Code Quality & Consistency

### QUAL-1: Massive expression parsing duplication in MacroManimParser

**File:** `MacroManimParser.hx`

Four near-identical function families:
- `parseIntegerOrReference()` / `parseNextIntExpression()`
- `parseFloatOrReference()` / `parseNextFloatExpression()`
- `parseStringOrReference()` / `parseNextStringExpression()`
- `parseAnything()` / `parseNextAnythingExpression()`

Each follows the same operator-precedence pattern with minor type differences. This is ~600 lines of duplicated logic that could be consolidated with a generic parsing function and type-specific callbacks.

### QUAL-2: Inconsistent token consumption patterns

**File:** `MacroManimParser.hx`

Three patterns used interchangeably without clear rationale:
- `eatComma()` — silently consumes comma if present
- `match(TComma)` — consumes if present, returns bool
- `expect(TComma)` — throws if not present

`eatComma()` allows leading commas (e.g., before color lists), which may be unintended. Some parsing functions use `eatSemicolon()` inconsistently.

### QUAL-3: Inconsistent property/node disambiguation

**File:** `MacroManimParser.hx`

Keywords like `hex`, `scale`, `alpha`, `tint`, `filter`, `layer` use `isPropertyColon()` peek-ahead to distinguish property assignments from child element names. But `blendmode` always consumes and expects a colon, meaning a child element named `blendmode` would fail to parse.

### QUAL-4: UI component API inconsistencies

**Files:** `src/bh/ui/UIMultiAnim*.hx`

- **Redraw pattern:** Button/Checkbox use `multiResult.findResultByCombo()`, Slider/ProgressBar use `builder.buildWithParameters()`, Dropdown uses `mainPartImages.findResultByCombo()`. Three different patterns for the same operation.
- **`clear()` method:** Button sets 1 field to null, ScrollableList sets 6+ fields, Dropdown sets 2 but doesn't clean panel callbacks.
- **Callback cleanup:** `onClick`, `onToggle`, `onInternalToggle` dynamic functions are never cleared in `clear()`, risking dangling references.

### QUAL-5: Variable shadowing in MultiAnimBuilder

**File:** `MultiAnimBuilder.hx` ~lines 5227, 5249

```haxe
function loadTileImpl(sheet, tilename, ...) {
    final sheet = getOrLoadSheet(sheet); // shadows parameter
```

The parameter `sheet` (String) is immediately shadowed by a local `sheet` (IAtlas2). Same pattern in `load9Patch`. Confusing and error-prone.

### QUAL-6: `@:nullSafety` disabled on main builder

**File:** `MultiAnimBuilder.hx` ~line 775

The `@:nullSafety` directive is commented out on the 5300-line `MultiAnimBuilder` class, while the smaller `Updatable` class at line 50 has it enabled. The largest and most complex class in the project lacks null safety checking.

### QUAL-7: AnimParser — Duplicate state-matching functions

**File:** `AnimParser.hx` ~lines 1075-1159

Four functions (`countStateMatch`, `findPlaylist`, `findExtraPoint`, `findAnimationInternal`) implement the same "find best matching score" pattern with duplicated logic. Should be refactored into a generic utility.

### QUAL-8: Codegen — Overly broad exception catching

**File:** `ProgrammableCodeGen.hx` ~line 5465

```haxe
try {
    Context.getType(...);
    Context.fatalError('Type already exists...', pos);
} catch (_:Dynamic) {
    // Expected — type doesn't exist yet
}
```

Uses `catch (_:Dynamic)` which swallows all exceptions. If `getType()` fails for reasons other than "type not found" (e.g., macro state corruption), the real error is hidden.

### QUAL-9: Codegen — Silent fallback to `macro null` or `macro 0`

**File:** `ProgrammableCodeGen.hx`

Multiple switch statements use `default: macro 0` or `default: macro null` as fallbacks without emitting any warning. If new enum variants are added, the generated code silently produces wrong values instead of failing at compile time. Affected locations: lines ~4267, ~4337, ~5413, ~2444.

---

## Test Coverage Gaps

### TEST-1: No tests for runtime behavior

The test suite is entirely visual (screenshot comparison). There are no tests that verify:
- Scene graph properties (positions, colors, text content) programmatically
- Event handling / interactive behavior
- State machine transitions
- Dynamic parameter updates at runtime
- Memory cleanup after `clear()`

### TEST-2: No UI component tests

Zero tests for any of:
- `UIMultiAnimDraggable` (18KB of drag-and-drop code, untested)
- `UIMultiAnimSlider`, `UIMultiAnimProgressBar`
- `UIMultiAnimDropdown`, `UIMultiAnimScrollableList`
- `UIInteractiveWrapper`, `UIScreen` event flows
- `SlotHandle` API (`setContent`, `clear`, `getContent`)

### TEST-3: No particle sub-emitter tests

Despite being fully implemented, there are zero tests for sub-emitter spawning, trigger types, probability, or burst counts.

### TEST-4: No edge case tests

Missing tests for:
- Unicode/emoji in text elements
- Very large repeatable counts (1000+)
- Deeply nested flows/layers (10+ levels)
- Conditional interactions with repeatable variables (known broken)
- Named indexed elements (`#name[$i]`) inside repeatables
- Dynamic ref `beginUpdate()`/`endUpdate()` batching

### TEST-5: Inconsistent test thresholds

- Default visual similarity threshold: 0.9999 (near pixel-perfect)
- Particle tests: relaxed to 0.75 (25% dissimilarity allowed)
- Color distance threshold: hardcoded 5

No documentation of why different thresholds are used or what constitutes acceptable variation.

### TEST-6: Only one `.anim` test file

The entire `.anim` format is tested with a single file (`test/res/marine.anim`). No tests for:
- Frame range validation (e.g., `frames: 5..2` — start > end)
- Empty state arrays
- Animation-level conditionals
- Metadata types and queries

---

## Design Suggestions

### SUGGEST-1: Error recovery in parser

The parser currently throws on the first error and stops. For a DSL used for rapid prototyping, a resilient parser that collects errors and continues parsing would significantly improve the edit-compile-test loop. Even collecting the first 5 errors before stopping would help.

### SUGGEST-2: Source maps / better error positions for generated code

When codegen-produced code throws at runtime, the error traces back to the generated Haxe code, not the `.manim` source. Adding `.manim` line/column information to generated `throw` messages would make debugging easier.

### SUGGEST-3: Unified expression parser

The four parallel expression-parsing families (`Int`, `Float`, `String`, `Anything`) could be unified into a single generic parser with type-specific resolution callbacks. This would eliminate ~600 lines of duplication and reduce the chance of fixing a bug in one variant but not the others.

### SUGGEST-4: UI component base class or trait

Button, Checkbox, Slider, ProgressBar, Dropdown, and ScrollableList each implement their own `clear()`, redraw, and event handling. A shared base class or trait with lifecycle hooks (`onBuild`, `onClear`, `onRedraw`) would enforce consistency and prevent the memory leak pattern where callbacks aren't cleaned up.

### SUGGEST-5: Builder state machine validation

The builder uses a manual stack (`stateStack`) with `push`/`pop` for tracking nested build state. A formal state machine or scope guard (RAII-style `try`/`finally`) would prevent stack corruption and make the nesting invariants explicit.

### SUGGEST-6: Typed settings system

UI component settings are string-keyed maps with dynamic values, requiring manual type casting and string-matching. A typed settings builder (generated from `.manim` parameter declarations) would catch misconfiguration at compile time rather than runtime.

### SUGGEST-7: Programmatic test assertions alongside visual tests

Screenshot comparison catches visual regressions but can't verify semantic correctness (e.g., "is this text actually at position 100,50?"). Adding property assertions alongside visual tests would catch issues that aren't pixel-visible, like off-by-one positions or wrong z-ordering that happens to look correct.

### SUGGEST-8: Consider LSP / editor integration for `.manim`

Given the complexity of the `.manim` language (conditionals, expressions, coordinates, 20+ element types, filters, particles), editor support with syntax highlighting, error squiggles, and autocompletion would significantly improve the authoring experience. Even a basic TextMate grammar for syntax highlighting would help.
