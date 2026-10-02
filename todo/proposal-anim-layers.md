# Proposal A: layers in `.anim` — built

Written 2026-09-30 and built the same day in the working tree, not committed. The docs describe it
as built: `docs/anim-reference.md` "Layers" and the `AnimationSM` API, `docs/anim.md` "Layers",
`CHANGELOG.md`.

As built:

- `layers: a, b, c` (bottom first) and `layer name @(cond) { … }` blocks in place of a playlist; the
  timeline is `timeline: name` or the first of `layers:` with a block; other layers name frames only
  and must match the timeline's count (checked when the state machine is made); `blend:` per block.
- `AnimationSM`: one clip per layer on one clock, `layer(name)`, `layerNames`, `detachLayer(name,
  parent)` / `attachLayer(name)`, `setState(name, value)` / `setStates(map)` (keeps the frame and time
  when the playing animation's length is unchanged, for any file, layered or not).
- A `stateanim` selector naming a parameter is tracked: `setParameter` calls `setState` (builder and
  codegen).
- Tests: `AnimLayersTest`, visual test 154, `CodegenIncrementalInteractiveStateanimTest` selector tests.

Not done: points per frame (`hand: 3,4 | 4,4 | …`), and per-layer `filters { }`.
