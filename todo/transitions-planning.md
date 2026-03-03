# Transitions & Animation System — Status

All 6 phases implemented. See `.claude/rules/runtime-systems.md` for API reference.

## Summary

| System | Status | Tests |
|--------|--------|-------|
| TweenManager | Done | 57 unit tests |
| Screen Transitions + Modal Overlay | Done | 9 unit tests (ScreenTransitionTest) |
| Tooltip/Panel Fade | Done | — |
| FloatingTextHelper | Done | 13 unit tests |
| .manim `transition {}` Declarations | Done | 15 parser + 3 builder + 1 visual |
| UI Control Integration | Done | Auto via incremental mode |

## Open Items

### Codegen does not support transitions

`ProgrammableCodeGen` does not generate transition-aware code. `transition {}` blocks are parsed but ignored by the macro path — only builder mode animates parameter changes.

**Impact:** Any `@:manim` codegen instance with a `transition {}` block will work functionally (conditionals switch instantly) but won't animate. This is documented in `docs/manim.md` and `docs/manim-reference.md`.

**What would be needed:** Codegen-generated classes would need to carry `TransitionType` metadata and use `IncrementalUpdateContext` (or equivalent) at runtime. Non-trivial — transitions depend on TweenManager injection and the builder's visibility tracking.

### `slide()` inside `flow()` is broken

Slide transitions modify `x`/`y` directly on the child object. `h2d.Flow.sync()` recalculates and overwrites child positions every frame, so the slide animation gets immediately overridden.

| Transition | Inside flow | Why |
|------------|-------------|-----|
| `fade()` | Safe | Only modifies alpha |
| `crossfade()` | Safe | Only modifies alpha |
| `flipX()` / `flipY()` | Safe | Only modifies scaleX/scaleY |
| `slide()` | Broken | Flow.sync() overwrites x/y |

**Options:**
- Warn/error at parse time if slide transition is declared inside a flow ancestor
- Use `@flow.absolute` workaround (removes element from layout)
- No fix needed if nobody uses it (no reports so far)

### Missing test coverage

- **No codegen comparison test** — test95 uses `simpleTest()` (builder-only). Should add `simpleMacroTest()` variant to verify codegen renders correctly (instant, no animation) and matches builder's static frame.
- **No builder test for mid-transition interruption** — changing a parameter while a transition is still animating (cancellation + restart).
- **No builder test for slide inside flow** — would document the known conflict.
- **No parser test for invalid easing name in transition** — e.g. `fade(0.2, unknownEasing)`.

### Floating text pooling

No object pool in `FloatingTextHelper`; left to application code. Not a transitions issue per se.
