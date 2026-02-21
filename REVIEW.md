# hx-multianim — Comprehensive Code Review

## Project Summary

hx-multianim is a Haxe library (~38K lines across 69 source files) for creating animations and pixel art UI elements using the Heaps framework. It provides a custom `.manim` DSL for defining state animations and programmable UI components, with both runtime parsing (via hxparse) and compile-time macro codegen.

The project is well-architected for its domain — gamedev prototyping and pixel art UI — with a clear separation between parsing, building, and rendering. The dual runtime/macro approach is a strong design choice for balancing iteration speed (live reload via playground) with production performance (compile-time codegen). Test infrastructure with 73 visual regression tests is solid.

---

## Critical Bugs

### 1. `getNodeSettings()` uses wrong variable — `MultiAnimBuilder.hx:426`

```haxe
public function getNodeSettings(elementName:String):ResolvedSettings {
    final results = names[name];  // BUG: should be names[elementName]
```

The method takes `elementName` as a parameter but accesses `names[name]` — where `name` is the *programmable's* name (a class field), not the element being looked up. This will always return incorrect results or throw.

**Fix**: Change `names[name]` to `names[elementName]` and update the error message.

### 2. Float parameters silently truncated to Int — `MultiAnimBuilder.hx:239-242`

```haxe
public function setParameter(name:String, value:Dynamic):Void {
    if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
        indexedParams.set(name, Value(Std.int(value)));  // loses float precision
    }
```

All numeric values passed through `IncrementalUpdateContext.setParameter()` are converted to `Int` via `Std.int()`. Any float parameter (e.g., opacity, scale) will be silently truncated. This makes incremental updates unreliable for float-typed parameters.

**Fix**: Check `Int` first, then `Float` separately, using `ValueF(...)` for floats.

### 3. Slider division by zero — `UIMultiAnimSlider.hx:87-92`

```haxe
function calculatePos(eventPos:Point) {
    final start = currentResult.names["start"][0].getBuiltHeapsObject().toh2dObject();
    final end = currentResult.names["end"][0].getBuiltHeapsObject().toh2dObject();
    return Std.int(100.0 * i / (end.x - start.x));  // div-by-zero if start.x == end.x
}
```

If the "start" and "end" named elements are at the same X position (degenerate slider, misconfigured `.manim`), this crashes with division by zero. No null checks on the chain either.

### 4. Conditional chain broken by non-conditional siblings — `MultiAnimBuilder.hx:295-352`

The `@else`/`@default` chain logic resets `prevSiblingMatched`/`anyConditionalSiblingMatched` on `NoConditional` nodes. This means:

```manim
@(param=>val1) element1
unconditional_element
@else element2          # broken — chain was reset by the middle element
```

The `@else` won't see that `element1` matched because the unconditional element reset the tracking flags.

### 5. 2D repeat pool key collision — `ProgrammableCodeGen.hx:2116`

```haxe
final _rt_key = _rt_countX * 10000 + _rt_countY;
```

The pool rebuild key for 2D repeatables encodes `countX * 10000 + countY`. If `countY >= 10000`, keys become ambiguous (e.g., `2 * 10000 + 10001 == 3 * 10000 + 1`). Pool rebuilds may be incorrectly skipped.

---

## Incomplete Implementations

### 6. Particle sub-emitters — runtime not implemented — `Particles.hx:879-927`

Parsing and building for sub-emitters are complete. The runtime has the structure (`triggerSubEmitters()`, `checkIntervalSubEmitters()`, `matchesTrigger()`) but the actual particle spawning is stubbed:

```haxe
// Spawn particles from sub-group at this location
// This is simplified - full implementation would create particles directly
```

The interval-based check similarly has `// Sub-emitter logic here`. Users can define sub-emitters in `.manim` without errors, but nothing will happen at runtime. This should at minimum produce a warning.

### 7. ByEdges autotile selector not parsed — `MacroManimParser.hx:1282-1291`

```haxe
function parseAutotileTileSelector():AutotileTileSelector {
    switch (peek()) {
        case TInteger(_), TReference(_):
            return ByIndex(parseIntegerOrReference());
        default:
            // TODO: ByEdges parsing if needed
            return ByIndex(parseIntegerOrReference());  // always falls through to ByIndex
    }
}
```

Edge-based autotile selection (documented as `generated(autotile("name", N+E+S+W))`) is parsed elsewhere in the runtime parser but not in `MacroManimParser`. Macro codegen users cannot use edge-based selection.

### 8. Hex coordinate offset support missing

CLAUDE.md and TODO.md both list this. Grid coordinates support `grid(x, y, offsetX, offsetY)` but hex only supports `hex(q, r, s)`. The `HexCoordinateSystem` lacks offset parameters.

### 9. Conditionals with repeatable vars — `@(index >= 3)` broken

Listed as a known bug. Loop variables are tracked in `scopeVars` during parsing, but runtime conditional evaluation doesn't properly resolve them when the condition uses comparison operators against loop iteration variables.

---

## Memory Leaks & Missing Cleanup

### 10. `RadioButtons.clear()` is empty — `UIMultiAnimRadioButtons.hx:75`

```haxe
public function clear() {}
```

The `checkboxes` array (line 14) holds references to child UI elements that are never cleaned up. Compare with `UIMultiAnimSlider.clear()` which properly nulls its builder and result, or `UIMultiAnimDropdown.clear()` which clears its items.

### 11. `UIInteractiveWrapper.clear()` likely empty

Interactive wrappers added via `addInteractive()` are tracked in `UIScreen.interactiveWrappers` (line 52). When individual wrappers are removed via `removeElement()`, they're removed from the `elements` list but NOT from `interactiveWrappers`, keeping references alive.

### 12. Dropdown panel not disposed — `UIMultiAnimDropdown.hx:69-72`

```haxe
public function clear() {
    this.items = [];
    this.currentMainPart = null;
    // panel never cleared
}
```

The `panel` (scrollable list) object and its children are never disposed.

### 13. Scope variable stack imbalance on parse error — `MacroManimParser.hx:2910-2935`

```haxe
scopeVars.push(varName);
loopVarsToPop = 1;
// ...
parseNodes(node, currentDefs);       // if this throws...
for (_ in 0...loopVarsToPop) scopeVars.pop();  // ...this never runs
```

If parsing fails inside a repeatable body, scope variables are never popped, contaminating the parent scope for any subsequent error recovery.

---

## Error Handling Issues

### 14. Unknown particle/sub-emitter fields silently ignored

Both particle property parsing (`MacroManimParser.hx:3134`) and sub-emitter field parsing (`MacroManimParser.hx:3348`) have `default: parseStringOrReference()` — silently consuming and discarding unknown field names. Typos like `colourStart` instead of `colorStart` will be silently ignored with no warning.

### 15. Sub-emitter required fields not validated — `MacroManimParser.hx:3314-3356`

After parsing a sub-emitter block, `groupId` and `trigger` can still be null (if user wrote an empty `{ }` or only set `probability`). These null values are pushed into the emitters array and will cause null dereferences at runtime.

### 16. Reference validation skipped outside programmable scope — `MacroManimParser.hx:417-418`

```haxe
if (activeDefs == null) return; // not inside programmable, skip validation
```

When `activeDefs` is null (outside a programmable definition), `$variable` references are not validated at all. Invalid references in root-level elements pass parsing silently.

### 17. Color parsing returns null without advancing — `MacroManimParser.hx:956-973`

`tryParseColor()` returns null for unparseable colors without consuming any tokens. Callers that retry in a loop could potentially hang if they don't check for this specifically.

### 18. AnimParser string formatting typo — `AnimParser.hx:564`

```haxe
trace('Warning: large number of states in AnimParser: ${allStates.length}}');
//                                                                       ^ extra }
```

Minor but indicates this warning path is likely untested.

---

## Design Issues & Suggestions

### 19. Inconsistent error semantics across builder

The builder mixes exception-throwing and null-returning patterns:
- `collectStateAnimFrames()` — returns empty array on missing animation
- `resolveAsInteger()` — throws on missing references
- `resolveAsArray()` — throws on missing arrays
- `loadTileSource()` — throws if result is null

Callers cannot predict which pattern to expect. Recommend establishing a convention — at minimum document which methods throw vs. return null.

### 20. Slot name collision risk — `ProgrammableCodeGen.hx:505-507, 589-597`

Non-indexed slots use `_slotHandle_{name}` and indexed slots use `_slotHandle_{baseName}_{index}`. A non-indexed slot named `"foo_0"` collides with indexed slot `"foo"` at index 0.

### 21. Builder state stack not exception-safe — `MultiAnimBuilder.hx:554-604`

The `pushBuilderState()`/`popBuilderState()` pattern has no try-finally protection. If an exception occurs between push and pop, the state stack is left unbalanced.

### 22. `ProgrammableBuilder._builder` initialization order undocumented

`_builder` is initialized to null (line 34) and assumed to be set by companion classes before any method calls. No documentation or runtime check ensures correct initialization order.

### 23. `resolveMaxCount()` hardcoded defaults — `ProgrammableCodeGen.hx:1075-1091`

Returns 10 in three separate fallthrough paths with no validation that the value is non-negative. The magic default of 10 may over-allocate or under-allocate depending on use case.

---

## Documentation Inconsistencies

### 24. CLAUDE.md uses pre-v0.12 terminology

CLAUDE.md still references `component()` and `reference()` which were renamed to `dynamicRef()` and `staticRef()` in v0.12. The parser accepts both for backward compatibility, but project documentation should use current terms.

### 25. Sub-emitters documented as complete

`docs/manim.md` documents sub-emitter syntax with full examples but doesn't mention that runtime spawning is unimplemented. CLAUDE.md notes this in the TODO section but the main docs don't warn users.

### 26. Scattered TODO tracking

Active work items are split across CLAUDE.md, TODO.md, macro-todo.md, and inline code comments. Some items appear in multiple places with slightly different descriptions (e.g., sub-emitters status).

### 27. Version requirement not prominent

The v0.12 breaking change bumped `.manim` version from 0.3 to 0.5. This is documented in CHANGELOG.md but not in CLAUDE.md or README.md quick start.

---

## Test Coverage Gaps

The suite has **193 tests total**: 103 parser error tests, 19 anim parser tests, ~60 codegen unit tests, and 72 visual regression tests. Parser error coverage is strong. The gaps are in runtime behavior:

```
                     Parsing  Building  Rendering  Macro-Gen
Core Features          ++       ++         ++       ++
Conditionals           ++       ++         ++       +
Coordinates            +        ++         ++       +
Animations             +        +          ++       +
Particles              +        +          -        +
Data Blocks            ++       -          -        -
Error Handling         ++       -          -        -
Edge Cases             +        -          -        -
Performance            -        -          -        -
```

### 28. No runtime error or edge case tests

Parser error tests exist (103 in `ParserErrorTest.hx`), but no builder/runtime error tests for: missing resources, invalid parameter types at runtime, circular imports, or expression type mismatches.

### 29. No tests for incremental updates

`IncrementalUpdateContext` (parameter changes without rebuild) has no dedicated test coverage. `beginUpdate()`/`endUpdate()` batching untested.

### 30. No tests for UI component lifecycle

UI components are tested visually but not for event handling, state transitions, `clear()`/dispose, or edge cases (empty lists, zero-size sliders).

### 31. Conditional + repeatable interaction untested

CLAUDE.md documents `@(index >= 3)` as broken with repeatable vars. No test exists for this interaction — tests exist for conditionals and for repeatables, but not for conditions referencing loop variables.

### 31b. Particle rendering and sub-emitters untested

No visual regression tests for particle effects. Sub-emitter runtime spawning (stubbed in code) has no test.

### 31c. Frame-based test timing is fragile

Tests use a 200-frame safety timeout and frame-based async (`waitForUpdate` callback). Not deterministic across machines — potential CI flakiness source.

---

## Performance Suggestions

### 32. Per-parameter visibility/expression updates — `macro-todo.md` Phase 2

Currently every parameter setter in codegen triggers full `_applyVisibility()` and `_updateExpressions()`. The data to generate per-parameter versions already exists in `paramRefs`. This is the highest-impact optimization for complex programmables.

### 33. Grid/hex coordinate system caching

`getGridFromCurrentNode()` walks the tree repeatedly without caching. In layouts with many grid-positioned elements, this is wasteful.

### 34. UIScreen interface checking

`UIScreen` uses `Std.isOfType()` on every element each time it needs to find sub-elements. Caching by interface at add-time would avoid repeated type checks.

### 35. String allocation in numeric resolution — `MultiAnimBuilder.hx:920-993`

`resolveAsString()` creates new strings for numeric values via interpolation on every call. Caching or direct numeric paths would reduce garbage.

---

## Feature Suggestions for Gamedev/Prototyping

### 36. Hot-reload error recovery

The "double reload issue" (TODO.md) and partial reload failure (some builders succeed, one fails → mixed state) are significant for the core prototyping workflow. A reload transaction (all-or-nothing) would be more robust.

### 37. Initial UI state propagation

TODO.md notes: "uielements → send initial change to uievents so control value can be synced to logic." Currently, UI components don't emit their initial value, requiring manual sync. This is a common pain point in game UI.

### 38. Radio button label clicking

TODO.md notes this. Currently only the checkbox itself is clickable, not the label. Standard UX expectation is that clicking the label toggles the radio.

### 39. Scrollable list disabled state

No way to disable all items in a scrollable list at once. Useful for modal states or loading overlays.

### 40. Particle animation state machine integration

TODO.md mentions `animSM support?` for particles. Tying particle effects to state animation transitions would be valuable for game VFX.

---

## Type System Issues

### 41. Excessive `Dynamic` usage erodes type safety

The codebase has 10+ locations using `Dynamic` where stronger types exist:

- **`ProgrammableBuilder._builder`** (`ProgrammableBuilder.hx:34`) — typed `Dynamic` instead of `Null<MultiAnimBuilder>`, requiring `@:privateAccess` casts everywhere. Should be typed properly.
- **`setParameter(name, value:Dynamic)`** (`MultiAnimBuilder.hx:239,408`) — parameter values lose type info at the API boundary
- **`UIElementListItem.data:Dynamic`** (`UIElement.hx:31`) — list item custom data has no type constraint
- **`AnimationPlaylistEvent.Trigger(data:Dynamic)`** (`AnimationSM.hx:12`) — event data untyped

### 42. Dead enum variants — `RVArray` and `RVArrayReference`

`MultiAnimParser.hx:459-460` defines `RVArray` and `RVArrayReference` variants in the `ReferenceableValue` enum. Every use site in `MultiAnimBuilder.hx` (lines 655, 793, 852, 936) throws `"not supported"`. These are dead code — either implement array resolution or remove the variants to avoid confusion.

### 43. Particle type duplication between parser and runtime

Two parallel type hierarchies exist:
- Parser AST: `ParticlesEmitMode`, `ParticleForceFieldDef`, `ParticleSubEmitterDef`, `ParticleBoundsModeDef`
- Runtime: `PartEmitMode`, `ForceField`, `SubEmitter`, `BoundsMode`

Each pair has manual conversion functions between them. This doubles the maintenance surface and risks the two getting out of sync.

### 44. `BuiltHeapsComponent` mixes incompatible base types

`MultiAnimParser.hx:291-302` defines variants like `HeapsObject(h2d.Object)`, `HeapsBitmap(h2d.Bitmap)`, etc. alongside `StateAnim(AnimationSM)` and `Particles(Particles)` which do NOT extend `h2d.Object`. The `toh2dObject()` conversion function must handle these specially, and callers that assume an `h2d.Object` result will crash on StateAnim/Particles.

### 45. Inconsistent `@:nullSafety` coverage

26 files use `@:nullSafety` but many enum/typedef definitions lack it. Some files have both strict and lenient null handling within the same scope. The inconsistency means null-checking is not reliably enforced project-wide.

---

## Summary

| Category | Count | Top Priority |
|----------|-------|-------------|
| Critical bugs | 5 | #1 getNodeSettings, #2 float truncation |
| Incomplete features | 4 | #6 sub-emitter runtime |
| Memory leaks | 4 | #10 RadioButtons.clear() |
| Error handling | 5 | #15 sub-emitter validation |
| Design issues | 5 | #19 error semantics |
| Doc inconsistencies | 4 | #24 terminology update |
| Test gaps | 4 | #28 parser error tests |
| Performance | 4 | #32 per-param updates |
| Feature suggestions | 5 | #36 reload recovery |
| Type system | 5 | #41 Dynamic usage, #42 dead variants |

The codebase is well-structured and the DSL design is thoughtful. The critical bugs (#1 and #2) are straightforward fixes. The biggest architectural concern is the lack of non-visual tests — as the language grows, parser and builder edge cases need systematic unit testing beyond screenshot comparisons.
