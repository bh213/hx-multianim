# TODO

| # | Item | Summary | Section | Priority |
|---|------|---------|---------|----------|
| 2 | Transitions & animations | Phase 1 (TweenManager) ✓ Phase 2 (Screen Transitions + Modal Overlay) ✓ — remaining: .manim transition declarations, tooltip/panel transitions, floating text, UI control transitions | V1 | Medium |
| 4 | Haxelib release | Publish to haxelib + CI automation | V1 | High |
| 9 | Dropdown z-ordering | Panel renders behind other UI elements | Bugs | Medium |
| 10 | `closeAllNamed()` iterator | Mutating map during iteration, fragile | Bugs | Low |
| 11 | Named panel outside-click | Wrong panel's close cancelled on click | Bugs | Medium |
| 15 | Text input codegen | `@:manim` factory with `createTextInput()` | After 1.0 | Low |

## Main Goals

- Code generation: programmable elements should always work via `builder.buildWithParameters` or via macro system (`@:manim(...)`)

## V1
- more hot reload integration tests needed — see [docs/hot-reload.md "Missing Tests"](../docs/hot-reload.md#missing-tests-needed) for full list
- transitions & animations — Phase 1+2 done (see [transitions-planning.md](transitions-planning.md)); remaining phases: .manim transition declarations, tooltip/panel/floating text transitions, UI control transitions
- haxelib release (see details below)
- add some blob47 utils for easier testing/dev/selection

### Haxelib Release

**haxelib.json gaps** (current: [haxelib.json](../haxelib.json), version `0.12.0`):
- [ ] Fill `releasenote` for each release

**CI/test matrix:**
- [ ] Dev mode tests (`-D MULTIANIM_DEV`) need matrix build or sequential run in CI (currently `test.ps1` runs both)
- [ ] Consider if dev-mode tests should run in release builds or only in dev CI stage

**Pre-release checklist:**
- [ ] Register haxelib account if not done (`haxelib register`)
- [ ] Test locally: `haxelib dev hx-multianim .` to simulate installation
- [ ] Bump version in haxelib.json
- [ ] Manual submit: `haxelib submit .` (auto-zips, excludes dotfiles)

**Automation (GitHub Actions):**
- [ ] Add `HAXELIB_PASSWORD` secret to GitHub repo settings
- [ ] Create `.github/workflows/release-and-publish.yml`:
  - Triggers on push to `main`
  - `EndBug/version-check@v2` detects version bump in haxelib.json
  - `softprops/action-gh-release@v1` creates GitHub Release `vX.Y.Z`
  - `haxelib submit . ${{ secrets.HAXELIB_PASSWORD }}` publishes
  - Reuse build/test steps from existing [build.yml](../.github/workflows/build.yml)

**Versioning notes:**
- Haxelib uses restricted SemVer: `major.minor.patch[-alpha|beta|rc[.N]]`
- Current `0.x.y` signals unstable API — use `1.0.0` when stable
- Submitted versions **cannot be overwritten** — must bump for any change

## Bugs

### Dropdown panel not on modal layer
**File:** `UIMultiAnimDropdown.hx:246`
The dropdown's floating panel uses `PositionLinkObject` but doesn't get placed on the modal layer. This can cause z-ordering issues where other UI elements render on top of the dropdown.
**Fix:** Route through `UIElementCustomAddToLayer` or `screen.addObjectToLayer(obj, ModalLayer)`.

### `closeAllNamed()` iterator safety
`closeAllNamed()` iterates `namedPanels` while `closeNamed()` removes from it. Currently works because Haxe `StringMap` iteration copies keys, but fragile.
**Fix:** Collect keys first (like `checkPendingClose` already does).

### Named panel outside-click scope is too broad
In `handleOutsideClick`, clicking inside *any* panel cancels the pending close for a *specific* named panel (line 254 uses `isOwnInteractive` which checks all panels). Should only cancel if the click is on this panel's own interactives or the trigger interactive.
**Fix:** Check `panel.prefix` and `panel.interactiveId` directly instead of `isOwnInteractive(id)`.

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
