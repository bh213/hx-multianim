# TODO

| # | Item | Summary | Priority |
|---|------|---------|----------|
| 10 | `closeAllNamed()` iterator | Mutating map during iteration, fragile | Low |
| 15 | Text input codegen | `@:manim` factory with `createTextInput()` | Low |

## Main Goals

- Code generation: programmable elements should always work via `builder.buildWithParameters` or via macro system (`@:manim(...)`)

## V1
- ~~Haxelib release~~ — DONE (1.0.0-rc.1, see [release.md](release.md))
- More hot reload integration tests — see [docs/hot-reload.md "Missing Tests"](../docs/hot-reload.md#missing-tests-needed)
- Add blob47 utils for easier testing/dev/selection
- change.manim version to 1.0


**CI remaining:**
- [ ] Add `HAXELIB_PASSWORD` secret to GitHub repo settings (required before first tag push)
- [ ] Dev mode tests (`-D MULTIANIM_DEV`) need matrix build or sequential run in CI (currently `test.ps1` runs both)

## Bugs

### `closeAllNamed()` iterator safety
`closeAllNamed()` iterates `namedPanels` while `closeNamed()` removes from it. Currently works because Haxe `StringMap` iteration copies keys, but fragile.
**Fix:** Collect keys first (like `checkPendingClose` already does).

## Deprecation Cleanup
- Remove legacy particle syntax from parser (keep only new forms):
  - `boundsMode`/`boundsMinX`/`boundsMaxX`/`boundsMinY`/`boundsMaxY`/`boundsLine` → `bounds:` combined syntax only
  - `rate: colorCurve: easing, #start, #end` → `colorStops:` only
  - Positional emit args `cone(dist, distRand, angle, angleRand)` → named params only

## After 1.0
- Text input codegen support (`@:manim` factory with `createTextInput()`)
- Bit expression: support for any-bit and all-bits (e.g. grid direction)
- Radio: paired UIElement (click on label to change radio)
- Subelements: handle nested subelements, keep state, don't query each time (cache `Std.isOfType`)
- Layouts: absoluteScreens / layers support
- UIElements: move to separate list, don't check interfaces all the time
- Hex/grid XY: enable scale & translate
- Custom `h2d.Object` subclasses with repeats-to-index or grid-to-index functionality
- Optimize grid/hex coordinate system so it doesn't walk the tree each time
- Text width for align revisit
- Setting editor
- apply animPath tweening to element?
