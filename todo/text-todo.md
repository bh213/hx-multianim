# Text Element Enhancements

## Remaining

- [ ] `onOverHyperlink` / `onOutHyperlink` for hover states on links
- [ ] Fix tilegroup codegen path to respect rich text mode (currently always creates plain `h2d.Text`)
- [ ] Color segments (`setColorSegments`) — consider if needed given `${c:...}` markup

## Completed

All 4 layers of native rich text markup are implemented:

- [x] **Layer 1 — Named styles + inline color/font**: `styles: {name: color "font"}`, `${styleName}`, `${c:color}`, `${f:font}`
- [x] **Layer 2 — Inline images**: `images: [name tileSource]`, `${img:name}`
- [x] **Layer 3 — Alignment + condenseWhite**: `${align:center}`, `condenseWhite: true`
- [x] **Layer 4 — Hyperlinks**: `${link:id}` with `callback("link:id")`
- [x] `TextMarkupConverter` utility (macro time + runtime)
- [x] Parse-time validation of `${styleName}` against defined styles
- [x] Auto-detection of HtmlText mode (no `html: true` needed)
- [x] `html: true` removed — parser error with migration message
- [x] Builder support with incremental update tracking
- [x] Codegen support with static pre-conversion optimization
- [x] Parser unit tests (17 tests) + builder unit tests (12 tests)
- [x] Visual test 92 (richText) — 10-row coverage
- [x] Test 48 migrated from `html: true` to `styles:` syntax
