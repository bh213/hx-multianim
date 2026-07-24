# 1.0 Release Audit — 2026-07-11

Full-project audit ahead of 1.0: 13 parallel deep-review passes over parsers, builder, codegen,
UI layer, VFX runtime, docs, tests/CI, and dev tooling. Every finding below was verified against
source (file:line) — many parser findings were empirically reproduced with probe scripts.

**Baseline:** test suite fully green — 101/101 visual, 7,581 unit assertions (8,009 in DEV build).
Caveat: `haxe hx-multianim.hxml` type-checks **zero** modules (no `-main`/module list — the hxml only
registers the atlas2 macro), so "the library compiles" is only proven via the test builds.

Legend: `[ ]` open, `[x]` done. Severity: **P0** release blocker · **P1** fix before 1.0 ·
**P2** should fix before 1.0 · **P3** post-1.0 acceptable.

**Item IDs:** every checklist item carries a stable ID (`BLD-2`, `CG-16`, …); the prefix names the
section it lives in: `P0` blockers · `BLD` builder · `CG` codegen parity · `UI` UI/screen stack ·
`VFX` VFX/anim/paths · `FLT` filter semantics · `PRS` parsers · `HR` hot reload · `LSP` LSP ·
`DEC` decisions · `DOC` docs · `TST` test & CI · `VSX` VS Code extension · `ERR` error quality ·
`PERF` performance · `API` API gaps. To review one bug:
`/bug-review todo/release-1.0-audit.md CG-16`. IDs are permanent — never renumber or reuse; new
items take the next free number in their prefix. (1.1 roadmap bullets are features, not bugs — no IDs.)

**Pruned 2026-07-15:** completed items are removed from this file — their resolution notes live in
`CHANGELOG.md` and git history (`git log -S <ID> -- todo/release-1.0-audit.md`). Removed IDs stay
retired. Done to date: all `P0-*`, all `BLD-*`, `CG-1..12`/`14..20`/`22` (+ most of `CG-23`;
`CG-9` was not-a-bug), `UI-1..2`, `VFX-1..13`/`15`, all `FLT-*`, `PRS-1..8`, `DEC-2..3`, `DOC-1`,
`TST-1..2`, `PERF-9`, `HR-1`, `LSP-1..4` (PRS-8 resolved as "allow enclosing finals in slot
bodies"; LSP-2 resolved with a build.js rebuild step + CI drift gate + LSP tests in CI).

---

## P1 — High-severity code bugs

### Hot reload / LSP

- [ ] `LSP-5` **Path-command completions never fire inside `#name path { … }` bodies** — `path` is
  missing from `ContextAnalyzer.isContextKeyword` (ContextAnalyzer.hx:332), so the inner block pushes
  an empty context → Unknown → element completions. Path commands are only offered one level up,
  directly inside `paths {}`, where `#name path {}` declarations (not commands) belong. Add `path`
  as a context keyword + a PathBody context mapping to `pathCompletions()`, and give `PathsBody` a
  `#name path {}` snippet instead (mirroring `curves`/`curve`). *(Found 2026-07-15 during the
  PRS-8 + hot-reload/LSP bug review.)*

---

## P2 — Medium bugs (fix before 1.0 where cheap)

### Codegen parity
- [ ] `CG-13` Inline text/richText in runtime-iterated repeats loses `styles:`/`images:`/`autoFit`/hyperlinks
  (fast path CG:3049-3134; named elements are forwarded and fine). *(2026-07-13 verify: VALID, fix
  deferred — route styled/imaged inline text through emitRuntimeChildViaBuilder or port the feature
  layers; also drops grid/hex positions of inline text in runtime repeats.)*
- [ ] `CG-21` `setParameter` value-contract divergences — enum Int (codegen: unvalidated index; builder:
  throws), tile String (builder accepts filename; codegen throws), string non-String (builder
  stringifies; codegen throws). **Pick one contract** (decision tracked as `DEC-4`).
  *(2026-07-13 verify: all three confirmed on HEAD + a fourth: bool-from-Int (codegen `!=0` accepts,
  builder throws). Also same family: codegen full-build handoffs (buildTileGroupByNode/buildParticles)
  forward enum params as raw Int index → builder `enum "x" does not contain value "0"` throw.)*
- [ ] `CG-23` Misc: ~~maxWidth-with-param-scale bake~~, ~~`TAWGrid` skipped~~, ~~`$ctx.random` no truncation~~,
  hyperlink exception propagation asymmetry, SWITCH-node tint/filter/blendMode never applied,
  ~~LayoutIterator `$param` points → 0,0~~, ~~generated tile w/h single-truncation~~, ~~dynamicRef forwarded
  string params use numeric add vs builder's string concat~~, ~~REPEAT2D count key collision
  (`countX*10000+countY`, CG:3725-3733)~~.
  *(2026-07-13: all struck-through sub-items fixed — maxWidth/TAWGrid runtime scale divisor
  (`CodegenTextMaxWidthParityTest`), $ctx.random via rvToExprInt (Cg23cHost), layout $param points
  emit runtime positions in codegen AND the builder-side MultiAnimLayouts scope now layers the
  index var over current params instead of replacing them (`CodegenLayoutParamPointsTest`),
  generated dims via rvToExprInt (`CodegenTileSourceParityTest`), dynamicRef forwards resolve by
  TARGET param type — string targets concatenate (`CodegenForwardStringConcatTest`; dynamic-name and
  staticRef sites keep source-shape fallback), REPEAT2D rebuild reworked to per-axis tracking fields
  + runtime dx/dy + range values start+i*step (`CodegenRepeat2DParityTest`). REMAINING: hyperlink
  try/catch asymmetry (d) and SWITCH-node tint/filter/blendMode (e) — verified VALID, untested
  syntax risk, fix with CG-13.)*
- [ ] `CG-24` **Codegen ignores `isTileGroup`** — `case PROGRAMMABLE(isTileGroup, ...)` captures the
  flag but never uses it (CG:275), so a `@:manim` root-form `programmable tilegroup` is generated
  as an ordinary per-element programmable: no TileGroup batching AND no macro-time
  `validateTileGroupSubtreeMacro` (only `generateTileGroupCreate` calls it, nested form only).
  Parity direction needs a decision — if codegen intentionally stays unbatched, macro-time
  rejection would be wrong. *(Found 2026-07-13 during the BLD-6 bug review.)* *(2026-07-13 verify:
  flag still unused at CG:275; codegen output is strictly more capable (conditionals work reactively)
  but unbatched — the root form's entire point is draw-call reduction. Decision still open.)*

### UI layer
- [ ] `UI-3` Interrupted screen transitions: `finalizeTransition()` doesn't finish the **entering** screen's
  tween (ScreenManager.hx:730-746, :825) — back-to-back transitions fight over the same root.
- [ ] `UI-4` Dialog over `MasterAndSingle`: **instant** open keeps `[dialog, oldMaster]` controllers, but
  **animated** open leaves `[dialog]` only, never restored (:643 vs :810-814) — same API, different
  routing by transition arg.
- [ ] `UI-5` `switchScreen` with transition from a dialog-over-dialog stack duplicates the surviving screen
  in `activeScreens`/controllers (:762-766, :793-800) → double update + double input.
- [ ] `UI-6` `ScreenManager.update()` mutates `activeScreens` while iterating (:292-305).
- [ ] `UI-7` `UIScreenBase.clear()` remove-during-iteration skips ~half the elements' `clear()`
  (UIScreen.hx:171-173 + :1329).
- [ ] `UI-8` Outside-click subscribers survive `clear()` → ghost `OnReleaseOutside`/`UIClickOutside` to
  disposed wrappers after clear/load (UIDefaultController.hx:44, :288-292).
- [ ] `UI-9` **Interactives in hidden conditional arms are still clickable** — `containsPoint` never checks
  the `visible` chain (UIInteractiveWrapper.hx:96-107); the 569bba4 ghost fix filters only *detached*
  arms; incremental hides via `visible=false`. (Related: `getInteractives()` semantics differ
  between paths — see `DEC-5`.)
- [ ] `UI-10` `UIScrollHelper.measureContentHeight` uses absolute-space `getBounds()` — `h2d.Mask` subtracts
  scrollY in absPos so the range shrinks as you scroll + is inflated by scene position
  (UIScrollHelper.hx:113-120). Fix: `content.getBounds(content)`. (UIScrollableScreen is correct.)
- [ ] `UI-11` Grid card-target refresh re-chains highlight/accepts closures without unchaining on every
  addCell/removeCell → N-deep chain, duplicate feedback, leak (UIMultiAnimGrid.hx:2010-2029 vs :2055-2076).
- [ ] `UI-12` Removing a dropdown leaks its floating panel (different layer; `clear()` never removes
  `panelObject`, UIMultiAnimDropdown.hx:322-336, :81-85).
- [ ] `UI-13` `UISelectFromHandController.onDeactivate` re-enables **all** cards, incl. game-disabled ones (:97-102).
- [ ] `UI-14` Stuck `hovered` flag when an interactive is disabled while hovered → wrong "hover" visual on
  re-enable (UIInteractiveWrapper.hx:120; UIRichInteractiveHelper.hx:197-199).
- [ ] `UI-15` Lows: dropdown panel updated 2×/frame (2× wheel speed); disabled checkbox/slider/textinput
  swallow events instead of bubbling; UIPanelHelper single-panel `close()` mid-dispatch (named path
  defers via `pendingClose`); `closeNamed` assumes `Tween.finish()` is synchronous → deferred hook
  clobbers next fade's tracking; cell-drag start emits 2 phantom `CellDataChanged`; cancelling a
  TweenSequence from a member's `onComplete` doesn't suppress the sequence `onComplete`;
  `cancelDrag()`/`clear()` outside event dispatch don't release mouse capture + no `DragCancel`.

### VFX / paths (lower severity)
- [ ] `VFX-14` `.anim` `@else(cond)` doesn't encode chain negation (best-score approximation); ambiguity throws
  a raw unpositioned string from `parse()` (:1916); `@(x=>a) @else(y=>b)` in one header silently
  discards the first condition. *(2026-07-12: PARTIAL — ambiguity now throws positioned
  InvalidSyntax; `@()` + `@else`/`@default` stacking in one header is a parse error. Chain-negation
  SEMANTICS deliberately deferred — matcher redesign, couples with DEC-7.)*
- [ ] `VFX-16` Silent duplicate-name overwrites: paths (:5974), curves (:6404), layouts (:2759), data fields,
  stateanim constructs; `.anim` duplicate `loop:`. *(2026-07-12: PARTIAL — paths/curves/layouts/
  stateanim constructs now duplicate-error (`ParserErrorTest`). Data record fields already had a
  guard. `.anim` duplicate `loop:` unverified — left open.)*
- [ ] `VFX-17` Parser lexer warts: both lexers silently skip unknown characters; number lexer eats trailing `.`
  before identifiers (`10.offset(...)` pitfall root cause, MacroManimParser.hx:225); coordinate X
  can't start with `$ref[idx]` or `$grid.width` (parseXY asymmetry); AnimLexer recursion on long
  comment runs (stack overflow risk on generated files); `flags`-param conditionals with non-numeric
  values recreate the builder/codegen divergence class (:2133-2135). *(2026-07-12: PARTIAL —
  unknown chars now error in both lexers (BOM tolerated); AnimLexer comments skip iteratively;
  `$grid.width`/`$ctx.height` accepted as coordinate X; flags guard added. DEFERRED: trailing-dot
  number lexing (its real fix is the 1.1 ".offset() after bare x,y" feature); `$ref[idx]` as X.)*

---

## Decisions needed before 1.0 (breaking-change window closes at release)

- [ ] `DEC-1` **Hex `offset`/`doubled` orientation mapping is inverted vs redblobgames convention**
  (CoordinateSystems.hx:97-108 + builder + 6 codegen sites: POINTY→qoffsetToCube; standard is
  q-offset=flat, r-offset=pointy). Consistent across builder/codegen so tests can't catch it, and
  existing content encodes the inverted behavior. Fix + migrate, or document as library convention.
- [ ] `DEC-4` **`setParameter` value contract** (enum-by-int, tile-by-filename, stringify non-strings):
  builder and codegen disagree in both directions. Define once, generate/validate both paths
  (see `CG-21`).
- [ ] `DEC-5` **`getInteractives()` after conditional flips**: builder returns build-time registry
  (hidden-but-built listed); codegen walks the live scene (detached excluded). Affects
  `UIRichInteractiveHelper.resync`. Pick one semantic. (Related: `UI-9`.)
- [ ] `DEC-6` **Version-header forward-compat**: parser accepts exactly `1.0`/`1` (MacroManimParser.hx:5522-5539).
  Decide the 1.x policy (accept `1.x`? warn?) before files with `version: 1.1` exist.
- [ ] `DEC-7` **`.manim` vs `.anim` conditional syntax divergence** (comma-form vs stacking; different `@else`
  semantics): align or document explicitly.
- [ ] `DEC-8` **Autotile edge-flag selectors**: `ByEdges` enum + builder/codegen support exist but no parser
  path produces it; docs show `autotile("x", N|E|S|W)` (two doc sites disagree `|` vs `+`). Wire the
  parser or cut the docs.

---

## Documentation fixes for 1.0

### docs/manim-cookbook.md (worst offender — recipes that throw or don't compile)
- [ ] `DOC-2` **Data Blocks Haxe API is fictional** — `getDataBlock`/`getInt`/`getRecordArray`/`getString`
  don't exist; actual `builder.getData(name):Dynamic` + field access (MB:7512).
- [ ] `DOC-3` Grid samples: `cellBuildName` is not a `GridConfig` field — needs
  `cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: ...})`; `CellDrop`
  pattern has 4 args vs 5; `CellHoverEnter`→`CellTargetEnter(cell, source)`;
  `getCellResult`→`getCellVisual().getResult()`; cell `highlight:bool` violates the string
  highlight contract (`none/accept/reject`); card-target id format is `grid0ch0_col_row`.
- [ ] `DOC-4` Card hand recipe: `graphics(color, width){...}` block form doesn't exist (invalid `.manim`);
  undefined curve refs; missing `returnPath`/`rearrangePath` → ctor throws; `layoutMode: PathLayout`
  never set (path config inert); `drawCard` missing required `buildName`; auto-wiring claim false
  for `new UICardHandHelper(...)` (only `addCardHand()` registers).
- [ ] `DOC-5` Dropdown recipes: panel contract is `width/height/topClearance` + placeholder key `"mask"`;
  item contract is `itemWidth/index/title/status/selected/disabled` + required `settings{height}`.
- [ ] `DOC-6` Slider recipe: `grid: $ref/100` unparseable (integer literals only); missing `#start`/`#end`
  points + `size` param; `scrollSpeed` is a list setting, not slider.
- [ ] `DOC-7` Button recipe passes `font`/`fontColor` its own `#button` doesn't declare; tab param is
  `buttonText` not `tabText`; dropdown/tabs items must be `[{name: ...}]` not plain strings;
  `autoConfirm` needs `minCount == maxCount`; `shakeWithCurve` takes `Float->Float` not `ICurve`
  (use `curve.getValue`); one TOC anchor broken; `.manim` block in a haxe fence.

### docs/manim.md
- [ ] `DOC-8` Particles `relative` default is **true** (doc says false); sub-emitter table missing `burstCount`;
  `emit`/`tiles` not actually required.
- [ ] `DOC-9` Stale runtime APIs: `getPath("name", start, end)` → `getPath(name, Stretch(a,b))`;
  `createAnimatedPath_name(start, end)` → `(?normalization)` (animpaths.md is current — fix manim.md).
- [ ] `DOC-10` richText sizing options listed are flow params; placeholder signature wrong; layouts keyword is
  `hexgrid:` not `hex:`; array iterator needs 2 args; broken examples `grid(10*$i,10)` and
  `palette(2d, 4)`; UI helper samples missing `settings` arg (same class as README).
- [ ] `DOC-11` Curve segments: omitted values auto-chain to `(i/n, (i+1)/n)` not `(0,1)`; overlap blending is
  triangular-weighted; `pingPong` does NOT require `loop`; `$ctx.width` is scene width, not element;
  arc/turn "counter-clockwise" is y-up convention (visually clockwise in Heaps); `cycleStart` not
  fired on first cycle; tilegroup child list incomplete; font list is app-registered, not a library fact.
- [ ] `DOC-12` `step(repeatCount, dx, dy)` positional form doesn't parse — dx/dy must be named
  (`step(count, dx: N, dy: N)`, MacroManimParser.hx:4041-4060); transitions example uses one-arg
  `sheet("ui")` 4× (needs `sheet("ui", "tileName")`, :1613-1625); `apply` documents `rotation:` but
  the keyword is `rotate:` (:5193-5202); repeatable example `'Index: $i'` needs `'Index: ${$i}'`
  (contradicts the doc's own interpolation rules); cookbook particles comment claims one-shot bursts
  need manual removal — false, non-looping groups auto-remove via default `onEnd` (Particles.hx:1604-1609).

### docs/manim-reference.md
- [ ] `DOC-13` Filter semantics rows (brightness/saturate/hue — `DEC-2` resolved as fix-code 2026-07-12:
  verify the rows now match the multiplier/degrees semantics); layout `align:`
  `left`/`top` are not accepted tokens and the doc's own example fails to parse; `palette(2d, width)`
  → `palette(2d: width)`; `palette(external)` misplaced; autotile `source` row totally wrong shape;
  `cubicBezier` is not a bare curve style and not usable as a curve-slot easing name; bezier
  smoothing is `smoothing: auto|none|<float>`; `$index`/`$indexX`/`$bitmap` are author-chosen loop
  var names, not implicit refs; glow/dropShadow `smoothColor`/`knockout` reachable only via
  (undocumented) named-param form; bare `flags` invalid — requires `flags(N)`;
  `interactivePrefix` default is `'card${helperInstanceId}'`; ScreenManager ctor is
  `(app:hxd.App, ?loader, ?config)`; `CellHoverEnter` → `CellTargetEnter`.

### docs/anim-reference.md + docs/anim.md
- [ ] `DOC-14` **`event <name> trigger` does not parse** — no `trigger` keyword; anim.md's complete example
  (L554) won't parse. Also documented in hx-multianim CLAUDE.md. Fix docs (bare form is canonical)
  or add a no-op keyword + test.
- [ ] `DOC-15` Per-animation `center:` override doesn't exist (parse error).
- [ ] `DOC-16` Playlist per-frame filters **replace**, don't accumulate (pinned by AnimFilterRuntimeTest).
- [ ] `DOC-17` `$$state$$` "migration hint error" doesn't exist; `LoadedAnimation` in example is dead code;
  color metadata alpha semantics (`VFX-2` fixed 2026-07-12: short forms bake 0xFF — update the text
  to the new semantics); flipX/flipY size check is load-time not parse-time.
- [ ] `DOC-18` Structural: anim.md and anim-reference.md share the same H1 title; anim.md + animpaths.md are
  README-linked but missing from the CLAUDE.md doc index (the drift source). Adopt into the index
  (or fold) + retitle.
- [ ] `DOC-19` Worth documenting: keywords case-insensitive but filter names case-sensitive; `frames: 1..5`
  are 0-based inclusive; fps is mandatory (no default); metadata conditionals not validated against
  `states:`; event-meta bools delivered as `"1"`/`"0"` strings; second `filters{}` silently replaces first.

### TECHNICAL-DOCS.md
- [ ] `DOC-20` `InvalidSyntax extends ParseError` (no `ParserError` class); incremental-mode description stale
  (deferred materialization, not build-all-invisible); `getResult()` → `getSource()` (also in
  CLAUDE.md + rules files); ProgressBar doesn't implement `UIElementFloatValue`;
  `createWithParameters` doesn't exist; `Path.normalize` → `applyTransform(PathNormalization)`;
  ReloadSentinel is not "weak references".

### docs/devbridge.md + docs/hot-reload.md + docs/vscode-extension.md
- [ ] `DOC-21` devbridge.md: screenshot `width`/`height` params are ignored by the handler; the
  "only incremental:true tracked" note is stale **including the runtime `note` string returned by
  `list_active_programmables`** (DevBridge.hx:1998) — fix the in-code string too; `x`/`y` not
  actually required on find_element_at/coordinate_transform; `wait_for_idle` also requires !paused;
  `list_interactives` button-by-text entries undocumented; `click_interactive` alias undocumented.
- [ ] `DOC-22` hot-reload.md: ~~`reloadable=false` claim~~ (resolved with `HR-1` 2026-07-15 — behavior
  implemented + doc expanded); registration no longer gated on
  `incremental` (commit 5491588); dynamicRef snapshot is one level deep, not recursive; `adoptFrom`
  field list incomplete; missing-test premise at :540 contradicts actual (correct) behavior.
- [ ] `DOC-23` vscode-extension.md: materially stale pre-implementation spec — in-repo location, language ids
  (`multianim`/`anim`), second `anim` language undocumented, scope names, activationEvents, deps,
  extension.ts listing. Rewrite against `vscode/` as shipped.
- [ ] `DOC-24` CLAUDE.md: HotReload does **not** do `.anim` reload; "hxparse-based" stale (root CLAUDE.md);
  `getResult()`→`getSource()`; `.claude/rules/runtime-systems.md` has the invalid card-hand
  `graphics(color,width){}` snippet and the `ICurve`-callable shake snippet;
  `.claude/rules/ui-components.md` + CHANGELOG:473 reference `CellHoverEnter`.
- [ ] `DOC-25` "TestApp frame count: 50 frames" note stale (now WALL_CLOCK_TIMEOUT 60s).

---

## Test & CI for 1.0

- [ ] `TST-3` **VisualTestBase swallow-path**: an exception in a `waitForUpdate` callback makes the test
  silently vanish from stats — run reports OK with a test missing (VisualTestBase.hx:52-64). Fail loudly.
- [ ] `TST-4` **Add an LSP CI job** (`haxe lsp/test-lsp.hxml && node lsp/bin/test.js` + `haxe lsp/lsp-server.hxml`)
  — also the only JS-target *execution* gate (JS is compile-only today) and the server.js drift gate.
- [ ] `TST-5` Tests for `sceneToHex` (advertised rc.5 feature, zero tests) and the grid cell-animation/detach
  family (`tweenCell`/`addCellAnimated`/`removeCellAnimated`/`detachCellVisual`/`reattachCellVisual`).
- [ ] `TST-6` A `.anim` replaceColor **visual** test (currently parse-only). *(The other two original
  sub-items are done/obsolete: DEC-2/DEC-3 semantics are pinned by matrix-level tests in
  `BuilderUnitTest`/`AnimFilterStateConditionalTest`/`ParticleRuntimeTest`, and `event x,y {meta}`
  became a parse error under VFX-13 — pinned by its rejection test.)*
- [ ] `TST-7` Confirm branch protection requires Compile + Test (Standard) + Test (Dev).
- [ ] `TST-8` Hygiene: `test.bat run` overwrites standard results with DEV results in `build/test_result.txt`
  (test.ps1:163,167); PR-comment step is template-injection fragile (tests.yml:196); lix cache path
  inconsistency between workflows; duplicate example dir numbers (122, 130); dead `TestMain.hx`;
  no CI on pushes to `dev`; reference-image DX-vs-Mesa drift has no CI-side gen-refs recovery path (document it).

## VS Code extension packaging

- [ ] `VSX-1` No README.md in `vscode/` (empty marketplace page); package.json missing `license`/`icon`/`keywords`;
  version skew (ext 2.0.28 vs hardcoded serverInfo "0.1.0"); `.vscodeignore` ships build scripts.
- [ ] `VSX-2` Grammar staleness: case-sensitive grammar vs case-insensitive parser (`flipX`, `colorCurve`,
  `autoFit`, `fillWidth/fillHeight`, `extraPoint`, `repeatable2d` unhighlighted in documented casing);
  missing `@flow.*`, `as`, particle aliases; `#RGB` never matches; `#FF0000` mis-scoped by the tags
  rule (pattern order). anim grammar: stale `goto/command/untilCommand/hit`, missing all 9 filter
  names, `$$name$$` interpolation rule (actual `${state}`), no color pattern.
  `sync-check.js` lowercases both sides — structurally can't catch any of this. Fix: generate the
  keyword alternations from ManimKeywordInfo (or use `(?i)` groups) + make sync-check case-sensitive.
- [ ] `VSX-3` ManimKeywordInfo: `RELATIVE_LAYOUTS => "layout"` but the keyword is `layouts` (LSP surfaces a
  non-parsing name); the "sync-check validates" comment is false (sync-check never reads this file).

---

## Error-quality cleanup (P3 unless noted)

- [ ] `ERR-1` Remaining plain string throws (builder convention is BuilderError): MB:8277
  (`buildWithParameters` missing element — most user-visible, do for 1.0), :8227/:8231/:8244/:8247
  (`dynamicValueToIndex` raw rethrow), :3169, :6991→ParseUtils.hx:7, :7674; **all of
  MultiAnimPaths.hx** (:65 — which also corrupts state, :298, :332, :369, :388, :413);
  MultiAnimParser.hx:123.
- [ ] `ERR-2` MacroLexer raw string throws bypass ParseError machinery (unterminated string/comment/
  interpolation) — strict mode / DevBridge / hot-reload catch sites get nothing structured.
- [ ] `ERR-3` `ParseUtils.toInt` unpositioned throws from ordinary typos (`programmable(n:int=abc)`,
  `@(c=>banana)` on color params, `0x` empty hex).
- [ ] `ERR-4` `programmable(count=5)` misleading error (silently becomes `string=""` then fails elsewhere).
- [ ] `ERR-5` `parseParticles` silently skips unknown properties (`speeed: 50` no-ops) — shutdown block
  errors on unknown keys; align.
- [ ] `ERR-6` Codegen: generated `getSlot`/dispatchers throw bare Strings (breaks `catch (e:BuilderError)`);
  TSReference fallback silently loads `"placeholder.png"` (error points at a file the user never
  wrote); `getUpdatable` generated only-when-sinks-exist returns null for static names while
  `get_name()` works.
- [ ] `ERR-7` Error text duplicates source name + uses two position formats (`error()` + `InvalidSyntax`).
- [ ] `ERR-8` Dead code: AnimParser reachability checks (`PRS-5` above), `_`-strip in number lexer, duplicate
  `isKeyword` alternatives, DEV slide-in-flow warning that can never fire,
  `checkForUnreachableState` unused return, `LoadedAnimation` typedef, `TestMain.hx`,
  `parseViaSubprocess` misleading name, `AnimationSM.speed` unreachable field,
  `PixelLine.centerX/centerY` dead fields.

---

## Performance backlog (mostly post-1.0; items marked ⚡ are cheap)

**Parser (compile-time cost for every `@:manim`):**
- [ ] `PERF-1` `isKeyword` allocates 2 lowercase strings/call × ~45-57 sequential guards per token — resolve
  keywords once at lex time (AnimParser already has the pattern).
- [ ] `PERF-2` `createNode` serializes the entire NodeType via `Std.string(type)` into `uniqueNodeName` —
  kilobytes per TEXT/FLOW/PARTICLES node, retained as string lookup keys.
- [ ] `PERF-3` ⚡ `Type.enumEq` per `match`/`expect` → constructor-index check.

**Builder:**
- [ ] `PERF-4` `applyConditionalChains` walks the entire tree per `setParameter` + Map-iterator alloc per node —
  needs a `param → conditional-chain` reverse index (mirroring `trackedByParam`).
- [ ] `PERF-5` Unconditional `apply{}` reconcile re-allocates `h2d.filter.*` on every setParameter of any param.
- [ ] `PERF-6` `getCurves()` re-resolves the whole curves map per call (per colorStop segment during particle
  builds); `getLayouts()/getPaths()` allocate fresh facades inside tracked closures — memoize.
  *(2026-07-13: also hit per mouse move — `UICardHandTargeting` calls `builder.getPaths().getPath(...)`
  during drag targeting, allocating a fresh `MultiAnimPaths` + scratch Map each move.)*
- [ ] `PERF-7` `BuilderResult.getSlot/hasSlot` linear scans — map-backed lookup.

**Codegen (todo-performance.md items confirmed + new):**
- [ ] `PERF-8` Per-param `_applyVisibility_X` / `_updateExpressions_X` (fixes the behavioral `CG-16` too).
  *(2026-07-13: the `_updateExpressions` half is DONE — per-entry paramRefs gating via
  `_updateExpressions(?changed)`, CG-16 resolved. Remaining: per-param `_applyVisibility` gating
  (visibility conditions still all re-evaluate per setter — cheap, but O(entries)).)*

**UI:**
- [ ] `PERF-10` `getBounds()`-allocating `containsPoint` for every widget on every mouse move (only
  UIInteractiveWrapper is alloc-free); `ControllerEventHandler` allocates per input event
  (Lambda.map + Point + wrapper); drop-zone scan ~200 allocs/drag-move on a 10×10 grid; targeting
  arrow re-normalizes its path per mouse move; `addCell/removeCell` O(cells) refresh → grid
  `beginBatch()/endBatch()`.

**VFX:**
- [ ] `PERF-11` PathGuide force field: ~93 curve evals/particle/frame (golden-section to 1e-6 evaluating both
  probes + 51 coarse samples). ⚡ Reuse one probe + loosen tolerance; properly: **arc-length LUT on
  Path** (also fixes distance-mode constant speed and `getClosestRate`).
- [ ] `PERF-12` ⚡ Per-particle `Math.pow` with group-constant args — cache per group per frame.
- [ ] `PERF-13` `PixelLines.updateBitmap` leaks a GPU texture per call, no `dispose()` — called from codegen
  param updates (texture churn per parameter change).
- [ ] `PERF-14` AnimatedPathState `custom` map boxing per frame; no `hexToPixelInto` (API asymmetry forces allocs).

---

## API gaps (1.0-nice-to-have)

- [ ] `API-1` `BuilderResult.dispose()` (cancel transitions, clear rebuild listeners, mark slots) — currently
  transition tweens + listeners leak on discard.
- [ ] `API-2` `has*` companions: `hasLayouts/hasPaths/hasCurves/hasCurve/hasData/hasParticles` (today: try/catch).
- [ ] `API-3` `SlotHandle.getScreenBounds()` missing the `disposed` guard every other method has.
- [ ] `API-4` Unify throw-vs-null lookup contracts (BuilderResult throws; SwitchArmResults/SlotHandle null;
  codegen getDynamicRef null).
- [ ] `API-5` `getParameterNames()` introspection on results; `#name[$i]` outside a loop silently registers
  `"name 0"` — diagnose.
- [ ] `API-6` `modalDialog` calls `load()` without `clear()` — document the contract or add clear-if-loaded.
- [ ] `API-7` `clear()` doesn't reset `tabGroup`/`modalOverlayConfig`; TextInput never leaves its tab group;
  duplicate interactive ids silently shadow; `GridConfig.tweenManager:Dynamic` → type it;
  tooltip helper auto-registers for dispose but **not** update (manual `update(dt)` still needed);
  `removeGroupElements` leaves group membership; `getLowerLayer` throws copy-paste 'no higher layer
  found'; `enableLinkEvents` not idempotent.
- [ ] `API-8` TweenManager: generation tokens so stale `cancel(t)` can't hit a recycled tween.
- [ ] `API-9` Particles: public `liveCount`, restart/reset; `ParticleGroup.enabled` setter (docstring
  describes a setter that no longer exists); `AnimationSM` speed accessor; fix
  `AnimatedPath.reset()` stale `currentState`; `currentSelector` mutable no-op.

---

## 1.1 feature roadmap

**Performance:** per-param codegen visibility/expressions; builder param→conditional reverse index;
arc-length LUT on Path; widget bounds caching; grid batching.

**Framework:**
- Declarative tooltip/panel system (todo-suggestions #9) + Auto positioning with overflow (#1) —
  the two High-impact items already triaged.
- `blockUnderlying:Bool` per dialog (resolves the documented routing asymmetry + `UI-4`).
- Lazy building of inactive conditional arms (the tactical fixes landed 2026-07-13 — losing chain
  arms now defer, deferred dynamicRef forwards — but full lazy-arm building remains the structural
  simplification that would delete that machinery).
- `.anim` hot reload (top item in hot-reload.md TODO; ReloadFileType.Anim plumbing already exists —
  only the ScreenManager loop is missing).
- `.anim` strict-D alpha migration + `#RRGGBBAA` round-trip consistency.
- AnimationSM playback control: speed, pause-at-frame, `seek(frame)`, finished-once callback.
- Runtime particle tuning API (most ParticleGroup fields are builder-only); per-group `worldAnchor`;
  sub-emitter coordinate-space contract.
- `PlayAnimComplete` card-hand event (can't currently sequence effects after a played card leaves).
- Parser: float literals in int coordinate contexts; `.offset()` after bare `x, y`; scientific
  notation; conditionals inside `settings{}`; `@switch` on loop variables; root-level `@final`
  visible inside programmables; strict particle keys; `.anim` duplicate `loop:` diagnostic
  (the rest of the duplicate-name family landed with VFX-16); `.anim` `@final` expressions.
- Text input codegen (`createTextInput()` factory — already triaged post-1.0).
- Exception-safe param-scope swaps as a systematic pattern (BLD-8 fixed the known sites with inline
  try/catch unwind; a zero-alloc `withParams` helper would make new sites safe by construction).

**Tooling:**
- Generate tmLanguage keyword alternations from ManimKeywordInfo + case-sensitive sync-check.
- LSP: per-request try/catch; `@switch`-arm completions using captured paramTypes; enum-value
  completion after `=>`; real symbol ranges via parser positions; cross-file go-to-definition
  through `import`; incremental sync.
- DevBridge: localhost-default bind (if not done for 1.0) + auth token; CI server.js drift gate.

**Pre-existing backlog (todo-suggestions.md):** panel toggle, anchor tracking, closeAll,
EVENT_PANEL_OPEN, open/openNamed dedup, batch setDisabled, isDisabled query, text-input password
mode, auto-grow multiline, modal tab groups — all still valid; none were invalidated by this audit.
