# TODO

## Main Goals

- Code generation: programmable elements should always work via `builder.buildWithParameters` or via macro system (`@:manim(...)`)

## V1
- hot reload
- transitions & animations (see [transitions-planning.md](transitions-planning.md))
- visual tests fixes
- haxelib release (see details below)
- blob47 utils?
- review in-text colors & html text support for manim
- investigate missing h2d.flow features

### Haxelib Release

**haxelib.json gaps** (current: [haxelib.json](../haxelib.json), version `0.12.0`):
- [ ] Fill `releasenote` for each release

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

## After 1.0

- Type parsing unification: merge interactive + settings type dispatch (see [type-parsing-unification.md](type-parsing-unification.md))
- Generic components support
- Bit expression: support for any-bit and all-bits (e.g. grid direction)
- StateAnim: color replace (replaceColor filter exists in MultiAnimParser, not fully exposed for stateanim)
- Radio: paired UIElement (click on label to change radio)
- Subelements: handle nested subelements, keep state, don't query each time (cache `Std.isOfType`)
- Layouts: absoluteScreens / layers support
- ~~UIElements: send initial change event so control value can be synced to logic~~ (done — `autoSyncInitialState` on UIScreenBase)
- UIElements: move to separate list, don't check interfaces all the time
- Hex/grid XY: enable scale & translate
- Custom `h2d.Object` subclasses with repeats-to-index or grid-to-index functionality
- Optimize grid/hex coordinate system so it doesn't walk the tree each time
- Text width for align revisit
- Setting editor
