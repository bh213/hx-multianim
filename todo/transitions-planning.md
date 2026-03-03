# Transitions & Animation System — Status

All 6 phases implemented. See `.claude/rules/runtime-systems.md` for API reference.

## Open Items

### ~~Codegen does not support transitions~~ — DONE
Implemented in v1.0.0-rc.1. `CodegenTransitionHelper` runtime class mirrors `IncrementalUpdateContext` transition logic. Generated instances get `setTweenManager(tm)` and `cancelAllTransitions()`.

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

- ~~**No codegen comparison test**~~ — DONE. test95 now has builder+macro comparison.
- **No builder test for mid-transition interruption** — changing a parameter while a transition is still animating (cancellation + restart).
- **No builder test for slide inside flow** — would document the known conflict.
- **No parser test for invalid easing name in transition** — e.g. `fade(0.2, unknownEasing)`.

### Floating text pooling

No object pool in `FloatingTextHelper`; left to application code. Not a transitions issue per se.
