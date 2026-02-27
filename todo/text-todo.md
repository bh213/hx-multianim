# Text Element Enhancements

## Remaining

- [ ] Fix tilegroup codegen path to respect rich text mode (currently always creates plain `h2d.Text`)

## Completed

- [x] **`text()` / `richText()` split** — `text()` reverted to simple plain text, `richText()` is new dedicated element (always `h2d.HtmlText`)
- [x] **Tilegroup codegen path** — `richText()` in tilegroup/repeatable runtime codegen creates `h2d.HtmlText` correctly

All 4 layers of native rich text markup are implemented:

- [x] **Layer 1 — Named styles**: `styles: {name: color(#hex) font("name")}`, `[styleName]...[/]`
- [x] **Layer 2 — Inline images**: `images: {name: tileSource}`, `[img:name]`
- [x] **Layer 3 — Alignment + condenseWhite**: `[align:center]`, `condenseWhite: true`
- [x] **Layer 4 — Hyperlinks**: `[link:id]` with `callback("link:id")`
- [x] `TextMarkupConverter` utility (macro time + runtime)
- [x] Parse-time validation of `[styleName]` against defined styles
- [x] Auto-detection of HtmlText mode (no `html: true` needed)
- [x] `html: true` removed — parser error with migration message
- [x] Builder support with incremental update tracking
- [x] Codegen support with static pre-conversion optimization
- [x] Parser unit tests (17 tests) + builder unit tests (16 tests)
- [x] Visual test 92 (richText) — 9-row coverage (added hyperlink row)
- [x] Test 48 migrated from `html: true` to `styles:` syntax
- [x] Markup syntax changed from `${tag}` to `%{tag}` to `[tag]...[/]` BBCode-style — no conflict with `$param` interpolation
- [x] Dynamic style colors — `color($param)` with incremental update support
- [x] Dynamic style fonts — `font($param)` with incremental update support
- [x] Dynamic image tiles — `TSReference($param)` with incremental tracking
- [x] `[[` escape sequence — produces literal `[` in output without triggering markup
- [x] Formal `color()`/`font()` function syntax for style definitions (v2 redesign)
- [x] `[c:]`/`[f:]` inline markup removed — parser error with migration message
- [x] Image syntax changed from bracket `[name tileSource]` to curly brace `{name: tileSource}` map
- [x] Codegen typed setters: `setStyleColor_<name>()`, `setStyleFont_<name>()`, `setImageTile_<name>()`
- [x] Image map promoted to instance field in codegen for setter access
- [x] Style shadow fields `_sc_<name>`, `_sf_<name>` for cross-referencing in setters
- [x] `onOverHyperlink` / `onOutHyperlink` — pointer cursor on link hover + `enableLinkEvents()` for UIInteractiveEvent emission
