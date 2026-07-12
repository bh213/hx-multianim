# 1.0 Release Audit — 2026-07-11

Full-project audit ahead of 1.0: 13 parallel deep-review passes over parsers, builder, codegen,
UI layer, VFX runtime, docs, tests/CI, and dev tooling. Every finding below was verified against
source (file:line) — many parser findings were empirically reproduced with probe scripts.

**Baseline:** test suite fully green — 101/101 visual, 7,581 unit assertions (8,009 in DEV build).
Caveat: `haxe hx-multianim.hxml` type-checks **zero** modules (no `-main`/module list — the hxml only
registers the atlas2 macro), so "the library compiles" is only proven via the test builds.

Legend: `[ ]` open, `[x]` done. Severity: **P0** release blocker · **P1** fix before 1.0 ·
**P2** should fix before 1.0 · **P3** post-1.0 acceptable.

---

## P0 — Release blockers

- [x] **haxelib packaging: missing `extraParams.hxml`.** The library requires
  `--macro bh.base.AtlasMacroInit.init()` (hx-multianim.hxml:3, AtlasMacroInit.hx:5) to register the
  `.atlas2` extension. A haxelib consumer using `-lib hx-multianim` never gets it → every `.manim`
  using atlas resources fails at load. Ship `extraParams.hxml` with the macro line (haxelib applies
  it automatically) and add it to README's hxml snippet. *(2026-07-12: `extraParams.hxml` added;
  README quick-start notes the `-cp` case.)*
- [x] **Release workflow publishes without running tests.** `release-and-publish.yml` builds, tags,
  and `haxelib submit`s with no test step/gate; failing tests still ship. Add the test suite (or a
  gate on the Tests workflow) to the release job. *(2026-07-12: restructured into
  check-version → tests → build-and-publish; tests job reuses `tests.yml` via `workflow_call` with
  `skip-report-deploy: true`.)*
- [x] **Version/tag state will silently skip the next publish.** Tag `v1.0.0-rc.5` already exists on
  origin while `haxelib.json` still says `1.0.0-rc.5` and ~12 newer commits sit under the dated
  `[1.0.0-rc.5] - 2026-05-15` CHANGELOG section (entries committed through 2026-06-22). Merging
  dev→main as-is hits the tag-exists guard and **publishes nothing**. Bump version + new CHANGELOG
  section before merge. Also: rc.4 *was* released (haxelib bump commit 2394795) but has no CHANGELOG
  section — its entries are folded into rc.5; `[0.4]` header is undated. *(2026-07-12: bumped to
  `1.0.0-rc.6`; all post-tag entries moved into a new `[1.0.0-rc.6] - 2026-07-12` section (rc.5
  section restored to its tagged content, verified byte-identical); rc.4 note added under the rc.5
  header. `[0.4]` header left undated.)*
- [x] **DevBridge binds `0.0.0.0` with `Access-Control-Allow-Origin: *`, no auth** (DevBridge.hx:101,
  :483-490, SSE :180-185). Any LAN host — or any website via DNS rebinding — can screenshot, inject
  input, `eval_manim`, `quit`. Default to `127.0.0.1` with opt-in `HX_DEV_BIND`; cheap extra: Host
  header check. (Dev-only flag, but 1.0 users will run it.) *(2026-07-12: `HX_DEV_BIND` env var +
  constructor override implemented. **Decision: default stays `0.0.0.0`** so LAN MCP clients keep
  working out of the box; security note documented in docs/devbridge.md. No Host-header check —
  it would break legitimate by-IP LAN access. Post-1.0 candidate: auth token.)*
- [x] **README code samples are broken** (first-contact surface):
  - `animSM.addCommand(SwitchState("idle"), ExecuteNow)` — API doesn't exist; use `animSM.play("idle")` (AnimationSM.hx:131). README:104.
  - `showScreen` → `switchTo` (ScreenManager.hx:843). README:123.
  - `showDialog` → `modalDialog` (ScreenManager.hx:532). README:238.
  - `public override function load()/onScreenEvent()` — `override` on **abstract** methods = compile error (UIScreen.hx:70,228,231; verified with `haxe --interp`). README:147,161,241.
  - `addCheckbox(builder, true)` / `addSlider(builder, 50)` / `addRadio(builder, items, true, 0)` — missing required `settings:ResolvedSettings` arg (UIScreen.hx:583/563/652). README:193,196,213.

  *(2026-07-12: all five fixed; also added haxelib/lix install commands, the `.atlas2` macro note,
  and an ATTRIBUTION.md link.)*
- [x] **`AllocationSmokeTest` has never run.** Fully written, advertised in CHANGELOG rc.5 and
  `.claude/rules/testing-and-debugging.md`, but never added to the `addCase` list
  (TestApp.hx:83-150). One-line fix — then it must actually pass. *(2026-07-12: registered; passes
  in both Standard and Dev runs — +6 unit assertions.)*

---

## P1 — High-severity code bugs

### Builder (MultiAnimBuilder)

- [ ] **REPEAT2D has no incremental-mode handling at all** (MultiAnimBuilder.hx:6437-6578). REPEAT
  collects `repeatParamRefs`, registers a structural rebuild, and sets `suppressConditionalTracking`
  (:6186-6243, :6300-6428); REPEAT2D does none of it. Consequences in incremental builds:
  `@()` arms AND their `@else` siblings all render simultaneously per iteration; last-writer-wins
  conditional registry corrupts state; param-dependent counts silently freeze. Port the REPEAT machinery.
- [ ] **`collectParamRefs` misses six `ReferenceableValue` classes** (:4174-4185):
  `RVElementOfArray.arrayRef`, `RVMethodCall` args, `RVChainedMethodCall`, `RVCallbacks(WithIndex)`,
  `RVColor`/`RVColorXY` index refs, `RVArray` elements. Result: tracked expressions / rebuild
  triggers / dynamicRef forwarding silently never fire — e.g. `tint: palette(pal, $idx)` frozen forever.

### Codegen parity (ProgrammableCodeGen vs builder) — each has a mechanical repro

- [ ] **P1: `step($dx, $dy, N)` param-dependent offsets become 0** (CG:2291-2311 static-resolve
  fallback → 0; builder resolves at build MB:6140). Elements stack at origin.
- [ ] **P2: `range($start..$end, $step)` param-dependent start/step → loop values start 0, step 1**
  (count is right, values wrong; CG:2303-2305, 2464-2467 vs MB:6151-6155).
- [ ] **P3: `repeatable` inside `flow` always wrapped in one container** (CG:2338-2354 etc. vs
  builder's `needsWrapper` logic MB:6207-6213) → flow sees one child; iterations overlap.
- [ ] **P4: `$ctx.width/height` crashes in codegen constructor** — emits `this.getScene().width`,
  null before scene attach (CG:7055-7058). Builder uses `builderParams.scene` (MB:2947).

### UI / screen stack

- [ ] **Double `OnDialogResult` when closing dialog-over-dialog** — fired at ScreenManager.hx:871 AND
  again in the Dialog→Dialog branch :696-697 (second may carry `null`). A purchase-confirm handler
  runs twice.
- [ ] **`reload()`/hot-reload with a dialog open** → Dialog→Dialog branch destroys the modal overlay
  (never recreated, :647), fires spurious `UILeaving`/`UIEntering`, and delivers a **phantom
  `OnDialogResult`** to the caller (:696-697).

### VFX / animation runtime

- [ ] **`gravityAngle` direction convention is swapped** — gravity applied as
  `vx += g·sin(θ), vy += g·cos(θ)` (Heaps legacy 0°=down; Particles.hx:231-232) while the parser's
  constants use 0°=right/90°=down (MacroManimParser.hx:806-815) and builder passes degrees→radians
  verbatim (MB:7169). `gravityAngle: down` pushes particles **right**. The unset default masks it.
  Independently confirmed by two audits. Fix the sin/cos (or add 90°−θ in builder) and audit content.
- [ ] **`.anim` color literals never bake alpha** (AnimParser.hx:374-379 → `0x00RRGGBB`; `.manim`
  lexer bakes `0xFF` per strict-D). `AFTint` is guard-patched but `.anim` `replaceColor` writes
  **fully transparent** pixels (via `ReplacePaletteShader.setColor` → alpha 0), and
  `getColorOrDefault/OrException` return alpha-0 ints. Fix at the lexer; keep the `>>>24==0` guards.
- [ ] **`AnimationSM.onFinished()` fires every frame after completion** (AnimationSM.hx:213-223 — no
  finished latch). Handlers that spawn/free objects execute once per frame.
- [ ] **`spawnCurve` + `maxLife: 0` hard-hangs the game** — `emissionAccumulator = +Inf` →
  `while (>= 1.0)` never terminates (Particles.hx:1438-1443; `life=0` is legal + unvalidated).
- [ ] **`emitBurstAt()` before first render → permanent double-draw** — sets `batch.visible = true`
  (Particles.hx:835-839) but batches are drawn explicitly in `Particles.draw()`; child-draw kicks in
  too (double alpha / wrong transform for non-relative). Delete the line.
- [ ] **Line-only `bounds:` silently enforces a hidden 800×600 box** (defaults at Particles.hx:660-672;
  builder overrides only when `box(...)` present, MB:7281-7294). Default box should be ±infinity.

### Filter semantics (code contradicts documented intent, all three backends)

- [ ] **`brightness(v)` is additive**, not a multiplier — Heaps `colorLightness` does `_41 += v`
  (MB:6938-6941, AnimParser.hx:2123-2127, codegen ~8350). The documented disabled-button pattern
  `group(brightness(0.5), grayscale(0.8))` actually **brightens**. Parser default `RVFloat(1.)`
  shows multiplier intent.
- [ ] **`saturate(v)` scale off by one** — Heaps adds 1 internally, so `saturate(0)` = normal,
  `saturate(-1)` = gray (MB:6933-6937). Doc says 0=gray/1=normal. (`grayscale` is correct.)
- [ ] **`hue(v)` takes radians**, documented as degrees; no angle-suffix support (MB:6949-6953 vs
  `dropShadow` which does deg→rad, MB:6961).
  → Decide: fix code (breaking for existing content — better now than post-1.0) or fix docs. Either
  way add tests pinning the chosen semantics.

### Parsers (empirically reproduced)

- [ ] **Parameterized slot without `{}` body permanently leaks slot param scope** — restore code only
  in the `TCurlyOpen` branch (MacroManimParser.hx:3403-3426 vs :4019-4027).
- [ ] **Multi-line `${…}` interpolation desyncs all subsequent line numbers** (:299-308 never bumps
  `line` on `\n`); interpolation column off-by-1/2 (:352).
- [ ] **`@` modifiers silently dropped** on `@final` / `settings{}` / `transition{}` (conditional
  parsed then discarded — :3032, :3934-3962, :3895-3932); `#name` silently dropped on `@switch`
  (:5452). Should be parse errors.
- [ ] **Nested `programmable` not rejected** — clobbers outer scope with no restore (:3549-3569).
  Add the root-only guard the other block types have.
- [ ] **AnimParser "not reachable" validation is dead code** — checks `visited == false` on a
  null-default optional field (`null == false` is false); `Playlist.visited` never set
  (AnimParser.hx:990-1000, :619,:638,:673). Fully-shadowed animations parse silently.
  CHANGELOG:288 claims these errors fire — they cannot.
- [ ] **`.anim` lexer accepts unterminated strings** — swallows the rest of the file into one token,
  errors far away (AnimParser.hx:323-341); embedded `\n` doesn't bump line numbers.

### Hot reload / LSP

- [ ] **`result.reloadable = false` opt-out is a no-op** — read exactly once inside
  `buildWithParameters` *before* the result is returned (MB:8318 — only read in the codebase);
  reload loop never consults it (ScreenManager.hx:1440). Implement the reload-loop check or delete
  the doc claim (hot-reload.md:294-296 documents fiction; its own missing-tests list shows the intent).
- [ ] **LSP: every `$param` reference completion is labeled the literal string `"$name"`** —
  `'$$name'` escapes to a literal `$` (CompletionProvider.hx:177). Intended `'$' + name`.
- [ ] **Packaged `vscode/server/server.js` is 11 parser commits stale** (last built 2026-04-16),
  including the Pratt-precedence **breaking change** — shipped diagnostics disagree with the real
  parser. `npm run build`/`package` never rebuild the Haxe server. Add a prebuild step + CI drift gate.
- [ ] **LSP suggests invalid syntax**: `quadratic` path-command completion isn't a parser keyword
  (ManimKeywordInfo.hx:300 `pathName(Bezier2To)`).
- [ ] **LSP request handlers not individually try/caught** (ManimLanguageServer.hx:151-208) — a
  provider throw means the JSON-RPC request never gets a response; client promise hangs forever.

---

## P2 — Medium bugs (fix before 1.0 where cheap)

### Builder
- [ ] Conditional sentinels not `isAbsolute` → phantom `horizontalSpacing` slot per conditional child
  inside `flow()` (MB:6660-6663; heaps Flow.hx:1452-1456). Incremental layout ≠ full layout.
- [ ] `@final` inside parameterized slot bodies lost from slot ctx → `slot.setParameter` throws
  `missing_ref` (`syncFinalsFromBuilder` called for roots :8306, neither slot path: :6787-6801, :8413-8423).
- [ ] Initially-hidden conditional arm `dynamicRef` gets no param forwarding after materialization
  (deferred path builds with `incrementalMode=false`, :1558-1605). Same layout initially-visible works.
- [ ] `programmable tilegroup` root skips `validateTileGroupSubtree` (:7036-7049) → param conditionals
  silently freeze (full) or double-bake both arms (incremental).
- [ ] Tracked expressions skipped while invisible never re-fired on `setVisibility(true)`
  (:1781-1793) → stale text/tint on reshow.
- [ ] `MultiAnimPaths.getPath` / `MultiAnimLayouts.resolve` swap `builder.indexedParams` with **no
  try/finally** (MultiAnimPaths.hx:49-50/:243; MultiAnimLayouts.hx:59-71) — any throw corrupts the
  builder's param map for the rest of the session. Add a `withParams(map, fn)` helper.
- [ ] `repeatable($i, array($val, arr))` leaks `$val` into enclosing scope after the loop
  (cleanup misses `valueVariableName` at :6291-6298, :6417-6423, :6575-6576, :5267-5270).
- [ ] Eager pre-build of losing conditional arms evaluates expressions with out-of-guard values →
  incremental build throws where full mode is fine (tile fallback exists :3826-3859; array bounds /
  div-by-zero don't).
- [ ] REPEAT loop-var shadow guard checks the element `#name` instead of the loop var (:6215-6216,
  :5318-5319; REPEAT2D does it right).
- [ ] DEV: hot-reload registry handles leak when dynamicRef subtrees rebuild while detached (sentinel
  `onRemove` never fires, HotReload.hx:138-166); old child contexts' transition tweens not cancelled.

### Codegen parity
- [ ] `generated(cross(...))` renders a solid rectangle (CG:7382 — "approximate as solid color").
- [ ] `@switch` non-last `default:` arm swallows later arms in the mixed-arm path (CG:2164-2182,
  reverse-build discards accumulated chain; all-enum path is correct).
- [ ] `beginUpdate()/endUpdate()` batches suppress transitions AND force-rebuild every `@switch` arm
  (`_changedParam == null`; CG:720,746,781-790,967-976). Builder batches animate + gate per-ref.
- [ ] Conditional params inside a param-dependent repeat: codegen throws `untracked`, builder rebuilds
  (CG:3523-3543 vs MB:6199-6204).
- [ ] `graphics { polygon(...) }` with grid/hex coordinate points collapses to 0,0 (CG:4534-4551).
- [ ] `particles {}` inside a static-unrolled `repeatable` throws index-out-of-range at `create()`
  (macro counter per unrolled iteration vs PB:187-207 counting parse nodes).
- [ ] Conditional `tilegroup` siblings: macro doc-order index vs built-tree order mismatch → wrong
  content or out-of-range throw (CG:5787-5807 vs PB:252-267).
- [ ] `$array[$idx]`: index refs untracked (no `RVElementOfArray` case in `collectParamRefsImpl`
  CG:7158-7193) → stale content on `setIdx`.
- [ ] Inline text/richText in runtime-iterated repeats loses `styles:`/`images:`/`autoFit`/hyperlinks
  (fast path CG:3049-3134; named elements are forwarded and fine).
- [ ] `layers()` layer ignored for repeat/`@switch` containers (bare `addChild` CG:2354,2097,2834,2529).
- [ ] Flow scalars / `spacer` / `@flow.offset` use `rvToExpr` (Float) where builder uses
  `resolveAsInteger` → generated-code compile errors + truncation divergence (CG:6512-6544,1884-1896).
  Violates the established `rvToExprInt` invariant.
- [ ] `_updateExpressions()` re-fires ALL updates → behavioral: game callbacks re-invoked, stateanim
  `play()` restarted, filters re-allocated on unrelated `setParameter` (CG:801-808).
- [ ] `CBRFloat` callback result in int context silently replaced by default (PB:406-432; builder
  throws in int contexts, accepts in float contexts).
- [ ] REPEAT2D non-step/range axes silently render **nothing** (CG:3562-3578) — should be
  `Context.error("not supported in codegen")`.
- [ ] `bitmap($tileParam)` in runtime repeats mis-binds to the iterator tile / undefined `_rt_tiles`
  compile error (CG:2971-2976 matches any `TSReference`).
- [ ] `dynamicRef($loopVar)` treated as literal programmable name "i" (CG:3926-3939; STATIC_REF handles it).
- [ ] `setParameter` value-contract divergences — enum Int (codegen: unvalidated index; builder:
  throws), tile String (builder accepts filename; codegen throws), string non-String (builder
  stringifies; codegen throws). **Pick one contract** (see Decisions).
- [ ] `.offset()`/named-coord around runtime hex coords → `unknown identifier _hexLayout` compile
  error (CG:7995-8022, no WITH_OFFSET/NAMED_COORD recursion).
- [ ] Misc: maxWidth-with-param-scale bake, `TAWGrid` skipped, `$ctx.random` no truncation,
  hyperlink exception propagation asymmetry, SWITCH-node tint/filter/blendMode never applied,
  LayoutIterator `$param` points → 0,0, generated tile w/h single-truncation, dynamicRef forwarded
  string params use numeric add vs builder's string concat, REPEAT2D count key collision
  (`countX*10000+countY`, CG:3725-3733).

### UI layer
- [ ] Interrupted screen transitions: `finalizeTransition()` doesn't finish the **entering** screen's
  tween (ScreenManager.hx:730-746, :825) — back-to-back transitions fight over the same root.
- [ ] Dialog over `MasterAndSingle`: **instant** open keeps `[dialog, oldMaster]` controllers, but
  **animated** open leaves `[dialog]` only, never restored (:643 vs :810-814) — same API, different
  routing by transition arg.
- [ ] `switchScreen` with transition from a dialog-over-dialog stack duplicates the surviving screen
  in `activeScreens`/controllers (:762-766, :793-800) → double update + double input.
- [ ] `ScreenManager.update()` mutates `activeScreens` while iterating (:292-305).
- [ ] `UIScreenBase.clear()` remove-during-iteration skips ~half the elements' `clear()`
  (UIScreen.hx:171-173 + :1329).
- [ ] Outside-click subscribers survive `clear()` → ghost `OnReleaseOutside`/`UIClickOutside` to
  disposed wrappers after clear/load (UIDefaultController.hx:44, :288-292).
- [ ] **Interactives in hidden conditional arms are still clickable** — `containsPoint` never checks
  the `visible` chain (UIInteractiveWrapper.hx:96-107); the 569bba4 ghost fix filters only *detached*
  arms; incremental hides via `visible=false`. (Related codegen P23: `getInteractives()` semantics
  differ between paths — see Decisions.)
- [ ] `UIScrollHelper.measureContentHeight` uses absolute-space `getBounds()` — `h2d.Mask` subtracts
  scrollY in absPos so the range shrinks as you scroll + is inflated by scene position
  (UIScrollHelper.hx:113-120). Fix: `content.getBounds(content)`. (UIScrollableScreen is correct.)
- [ ] Grid card-target refresh re-chains highlight/accepts closures without unchaining on every
  addCell/removeCell → N-deep chain, duplicate feedback, leak (UIMultiAnimGrid.hx:2010-2029 vs :2055-2076).
- [ ] Removing a dropdown leaks its floating panel (different layer; `clear()` never removes
  `panelObject`, UIMultiAnimDropdown.hx:322-336, :81-85).
- [ ] `UISelectFromHandController.onDeactivate` re-enables **all** cards, incl. game-disabled ones (:97-102).
- [ ] Stuck `hovered` flag when an interactive is disabled while hovered → wrong "hover" visual on
  re-enable (UIInteractiveWrapper.hx:120; UIRichInteractiveHelper.hx:197-199).
- [ ] Lows: dropdown panel updated 2×/frame (2× wheel speed); disabled checkbox/slider/textinput
  swallow events instead of bubbling; UIPanelHelper single-panel `close()` mid-dispatch (named path
  defers via `pendingClose`); `closeNamed` assumes `Tween.finish()` is synchronous → deferred hook
  clobbers next fade's tracking; cell-drag start emits 2 phantom `CellDataChanged`; cancelling a
  TweenSequence from a member's `onComplete` doesn't suppress the sequence `onComplete`;
  `cancelDrag()`/`clear()` outside event dispatch don't release mouse capture + no `DragCancel`.

### VFX / paths (lower severity)
- [ ] Wave segment endpoint ignores residual lateral offset for fractional `count` → position jump
  into next segment + wrong Stretch scaling (MultiAnimPaths.hx:227-239 vs :723-731).
- [ ] AnimatedPath pingPong: distance-mode speed curve un-mirrored vs other slots; events fire at
  forward progress (not mirrored position) in reversed cycles; `cycleStart` delivered with previous
  cycle's end state (AnimatedPath.hx:266-269, :289-318, :345).
- [ ] `AnimParser.load()` cache shares one filter instance + one extraPoints IPoint map across all
  AnimationSM instances per selector (AnimParser.hx:2210-2266) — mutation corrupts every SM.
- [ ] Force-field/bounds/sub-emitter coordinates are in different spaces for relative vs non-relative
  groups — undocumented (Particles.hx:1154-1225, :1318-1324).
- [ ] `Curve` with duplicate time values → NaN (Curve.hx:40-45), unvalidated.
- [ ] `Hex.toOffsetCoordinates()` uses invalid offset=0; `HexLayout.directionToAngle` ignores
  `start_angle` (Hex.hx:252-254, :550-554). (Both unused in-library.)
- [ ] `event name x,y { meta }` / `event name random ... { meta }` parse OK but **silently drop the
  point/random spec** (AnimParser.hx:1491-1505). Document or reject.
- [ ] `.anim` `@else(cond)` doesn't encode chain negation (best-score approximation); ambiguity throws
  a raw unpositioned string from `parse()` (:1916); `@(x=>a) @else(y=>b)` in one header silently
  discards the first condition.
- [ ] `.anim` comparison/range conditionals accept non-numeric operands → NaN → arm silently dead.
- [ ] Silent duplicate-name overwrites: paths (:5974), curves (:6404), layouts (:2759), data fields,
  stateanim constructs; `.anim` duplicate `loop:`.
- [ ] Parser lexer warts: both lexers silently skip unknown characters; number lexer eats trailing `.`
  before identifiers (`10.offset(...)` pitfall root cause, MacroManimParser.hx:225); coordinate X
  can't start with `$ref[idx]` or `$grid.width` (parseXY asymmetry); AnimLexer recursion on long
  comment runs (stack overflow risk on generated files); `flags`-param conditionals with non-numeric
  values recreate the builder/codegen divergence class (:2133-2135).

---

## Decisions needed before 1.0 (breaking-change window closes at release)

- [ ] **Hex `offset`/`doubled` orientation mapping is inverted vs redblobgames convention**
  (CoordinateSystems.hx:97-108 + builder + 6 codegen sites: POINTY→qoffsetToCube; standard is
  q-offset=flat, r-offset=pointy). Consistent across builder/codegen so tests can't catch it, and
  existing content encodes the inverted behavior. Fix + migrate, or document as library convention.
- [ ] **brightness/saturate/hue semantics** (see P1 Filters): fix code to documented intent (breaking
  visuals for content that compensated) or re-document Heaps semantics. Recommend fixing code —
  the docs, the parser default, and user intuition all agree on multiplier/degrees.
- [ ] **`gravityAngle`**: fix convention + audit existing `.manim` content.
- [ ] **`setParameter` value contract** (enum-by-int, tile-by-filename, stringify non-strings):
  builder and codegen disagree in both directions. Define once, generate/validate both paths.
- [ ] **`getInteractives()` after conditional flips**: builder returns build-time registry
  (hidden-but-built listed); codegen walks the live scene (detached excluded). Affects
  `UIRichInteractiveHelper.resync`. Pick one semantic.
- [ ] **Version-header forward-compat**: parser accepts exactly `1.0`/`1` (MacroManimParser.hx:5522-5539).
  Decide the 1.x policy (accept `1.x`? warn?) before files with `version: 1.1` exist.
- [ ] **`.manim` vs `.anim` conditional syntax divergence** (comma-form vs stacking; different `@else`
  semantics): align or document explicitly.
- [ ] **Autotile edge-flag selectors**: `ByEdges` enum + builder/codegen support exist but no parser
  path produces it; docs show `autotile("x", N|E|S|W)` (two doc sites disagree `|` vs `+`). Wire the
  parser or cut the docs.

---

## Documentation fixes for 1.0

### README.md
- [x] All P0 sample fixes above; add lix install command; consider linking ATTRIBUTION.md.
  *(2026-07-12: all done — see the README P0 entry above.)*

### docs/manim-cookbook.md (worst offender — recipes that throw or don't compile)
- [ ] **Data Blocks Haxe API is fictional** — `getDataBlock`/`getInt`/`getRecordArray`/`getString`
  don't exist; actual `builder.getData(name):Dynamic` + field access (MB:7512).
- [ ] Grid samples: `cellBuildName` is not a `GridConfig` field — needs
  `cellVisualFactory: new DefaultCellVisualFactory(builder, {cellBuildName: ...})`; `CellDrop`
  pattern has 4 args vs 5; `CellHoverEnter`→`CellTargetEnter(cell, source)`;
  `getCellResult`→`getCellVisual().getResult()`; cell `highlight:bool` violates the string
  highlight contract (`none/accept/reject`); card-target id format is `grid0ch0_col_row`.
- [ ] Card hand recipe: `graphics(color, width){...}` block form doesn't exist (invalid `.manim`);
  undefined curve refs; missing `returnPath`/`rearrangePath` → ctor throws; `layoutMode: PathLayout`
  never set (path config inert); `drawCard` missing required `buildName`; auto-wiring claim false
  for `new UICardHandHelper(...)` (only `addCardHand()` registers).
- [ ] Dropdown recipes: panel contract is `width/height/topClearance` + placeholder key `"mask"`;
  item contract is `itemWidth/index/title/status/selected/disabled` + required `settings{height}`.
- [ ] Slider recipe: `grid: $ref/100` unparseable (integer literals only); missing `#start`/`#end`
  points + `size` param; `scrollSpeed` is a list setting, not slider.
- [ ] Button recipe passes `font`/`fontColor` its own `#button` doesn't declare; tab param is
  `buttonText` not `tabText`; dropdown/tabs items must be `[{name: ...}]` not plain strings;
  `autoConfirm` needs `minCount == maxCount`; `shakeWithCurve` takes `Float->Float` not `ICurve`
  (use `curve.getValue`); one TOC anchor broken; `.manim` block in a haxe fence.

### docs/manim.md
- [ ] Particles `relative` default is **true** (doc says false); sub-emitter table missing `burstCount`;
  `emit`/`tiles` not actually required.
- [ ] Stale runtime APIs: `getPath("name", start, end)` → `getPath(name, Stretch(a,b))`;
  `createAnimatedPath_name(start, end)` → `(?normalization)` (animpaths.md is current — fix manim.md).
- [ ] richText sizing options listed are flow params; placeholder signature wrong; layouts keyword is
  `hexgrid:` not `hex:`; array iterator needs 2 args; broken examples `grid(10*$i,10)` and
  `palette(2d, 4)`; UI helper samples missing `settings` arg (same class as README).
- [ ] Curve segments: omitted values auto-chain to `(i/n, (i+1)/n)` not `(0,1)`; overlap blending is
  triangular-weighted; `pingPong` does NOT require `loop`; `$ctx.width` is scene width, not element;
  arc/turn "counter-clockwise" is y-up convention (visually clockwise in Heaps); `cycleStart` not
  fired on first cycle; tilegroup child list incomplete; font list is app-registered, not a library fact.
- [ ] `step(repeatCount, dx, dy)` positional form doesn't parse — dx/dy must be named
  (`step(count, dx: N, dy: N)`, MacroManimParser.hx:4041-4060); transitions example uses one-arg
  `sheet("ui")` 4× (needs `sheet("ui", "tileName")`, :1613-1625); `apply` documents `rotation:` but
  the keyword is `rotate:` (:5193-5202); repeatable example `'Index: $i'` needs `'Index: ${$i}'`
  (contradicts the doc's own interpolation rules); cookbook particles comment claims one-shot bursts
  need manual removal — false, non-looping groups auto-remove via default `onEnd` (Particles.hx:1604-1609).

### docs/manim-reference.md
- [ ] Filter semantics rows (brightness/saturate/hue — pending the code decision); layout `align:`
  `left`/`top` are not accepted tokens and the doc's own example fails to parse; `palette(2d, width)`
  → `palette(2d: width)`; `palette(external)` misplaced; autotile `source` row totally wrong shape;
  `cubicBezier` is not a bare curve style and not usable as a curve-slot easing name; bezier
  smoothing is `smoothing: auto|none|<float>`; `$index`/`$indexX`/`$bitmap` are author-chosen loop
  var names, not implicit refs; glow/dropShadow `smoothColor`/`knockout` reachable only via
  (undocumented) named-param form; bare `flags` invalid — requires `flags(N)`;
  `interactivePrefix` default is `'card${helperInstanceId}'`; ScreenManager ctor is
  `(app:hxd.App, ?loader, ?config)`; `CellHoverEnter` → `CellTargetEnter`.

### docs/anim-reference.md + docs/anim.md
- [ ] **`event <name> trigger` does not parse** — no `trigger` keyword; anim.md's complete example
  (L554) won't parse. Also documented in hx-multianim CLAUDE.md. Fix docs (bare form is canonical)
  or add a no-op keyword + test.
- [ ] Per-animation `center:` override doesn't exist (parse error).
- [ ] Playlist per-frame filters **replace**, don't accumulate (pinned by AnimFilterRuntimeTest).
- [ ] `$$state$$` "migration hint error" doesn't exist; `LoadedAnimation` in example is dead code;
  color metadata alpha semantics (pending B2 fix); flipX/flipY size check is load-time not parse-time.
- [ ] Structural: anim.md and anim-reference.md share the same H1 title; anim.md + animpaths.md are
  README-linked but missing from the CLAUDE.md doc index (the drift source). Adopt into the index
  (or fold) + retitle.
- [ ] Worth documenting: keywords case-insensitive but filter names case-sensitive; `frames: 1..5`
  are 0-based inclusive; fps is mandatory (no default); metadata conditionals not validated against
  `states:`; event-meta bools delivered as `"1"`/`"0"` strings; second `filters{}` silently replaces first.

### TECHNICAL-DOCS.md
- [ ] `InvalidSyntax extends ParseError` (no `ParserError` class); incremental-mode description stale
  (deferred materialization, not build-all-invisible); `getResult()` → `getSource()` (also in
  CLAUDE.md + rules files); ProgressBar doesn't implement `UIElementFloatValue`;
  `createWithParameters` doesn't exist; `Path.normalize` → `applyTransform(PathNormalization)`;
  ReloadSentinel is not "weak references".

### docs/devbridge.md + docs/hot-reload.md + docs/vscode-extension.md
- [ ] devbridge.md: screenshot `width`/`height` params are ignored by the handler; the
  "only incremental:true tracked" note is stale **including the runtime `note` string returned by
  `list_active_programmables`** (DevBridge.hx:1998) — fix the in-code string too; `x`/`y` not
  actually required on find_element_at/coordinate_transform; `wait_for_idle` also requires !paused;
  `list_interactives` button-by-text entries undocumented; `click_interactive` alias undocumented.
- [ ] hot-reload.md: `reloadable=false` claim (pending code fix); registration no longer gated on
  `incremental` (commit 5491588); dynamicRef snapshot is one level deep, not recursive; `adoptFrom`
  field list incomplete; missing-test premise at :540 contradicts actual (correct) behavior.
- [ ] vscode-extension.md: materially stale pre-implementation spec — in-repo location, language ids
  (`multianim`/`anim`), second `anim` language undocumented, scope names, activationEvents, deps,
  extension.ts listing. Rewrite against `vscode/` as shipped.
- [ ] CLAUDE.md: HotReload does **not** do `.anim` reload; "hxparse-based" stale (root CLAUDE.md);
  `getResult()`→`getSource()`; `.claude/rules/runtime-systems.md` has the invalid card-hand
  `graphics(color,width){}` snippet and the `ICurve`-callable shake snippet;
  `.claude/rules/ui-components.md` + CHANGELOG:473 reference `CellHoverEnter`.
- [ ] "TestApp frame count: 50 frames" note stale (now WALL_CLOCK_TIMEOUT 60s).

---

## Test & CI for 1.0

- [x] Register `AllocationSmokeTest` (P0 above). *(2026-07-12)*
- [x] Gate release workflow on tests (P0 above). *(2026-07-12)*
- [ ] **VisualTestBase swallow-path**: an exception in a `waitForUpdate` callback makes the test
  silently vanish from stats — run reports OK with a test missing (VisualTestBase.hx:52-64). Fail loudly.
- [ ] **Add an LSP CI job** (`haxe lsp/test-lsp.hxml && node lsp/bin/test.js` + `haxe lsp/lsp-server.hxml`)
  — also the only JS-target *execution* gate (JS is compile-only today) and the server.js drift gate.
- [ ] Tests for `sceneToHex` (advertised rc.5 feature, zero tests) and the grid cell-animation/detach
  family (`tweenCell`/`addCellAnimated`/`removeCellAnimated`/`detachCellVisual`/`reattachCellVisual`).
- [ ] Tests pinning whatever brightness/saturate/hue/gravityAngle semantics are decided; a `.anim`
  replaceColor **visual** test (currently parse-only); a `event x,y {meta}` behavior test.
- [ ] Confirm branch protection requires Compile + Test (Standard) + Test (Dev).
- [ ] Hygiene: `test.bat run` overwrites standard results with DEV results in `build/test_result.txt`
  (test.ps1:163,167); PR-comment step is template-injection fragile (tests.yml:196); lix cache path
  inconsistency between workflows; duplicate example dir numbers (122, 130); dead `TestMain.hx`;
  no CI on pushes to `dev`; reference-image DX-vs-Mesa drift has no CI-side gen-refs recovery path (document it).

## VS Code extension packaging

- [ ] No README.md in `vscode/` (empty marketplace page); package.json missing `license`/`icon`/`keywords`;
  version skew (ext 2.0.28 vs hardcoded serverInfo "0.1.0"); `.vscodeignore` ships build scripts.
- [ ] Grammar staleness: case-sensitive grammar vs case-insensitive parser (`flipX`, `colorCurve`,
  `autoFit`, `fillWidth/fillHeight`, `extraPoint`, `repeatable2d` unhighlighted in documented casing);
  missing `@flow.*`, `as`, particle aliases; `#RGB` never matches; `#FF0000` mis-scoped by the tags
  rule (pattern order). anim grammar: stale `goto/command/untilCommand/hit`, missing all 9 filter
  names, `$$name$$` interpolation rule (actual `${state}`), no color pattern.
  `sync-check.js` lowercases both sides — structurally can't catch any of this. Fix: generate the
  keyword alternations from ManimKeywordInfo (or use `(?i)` groups) + make sync-check case-sensitive.
- [ ] ManimKeywordInfo: `RELATIVE_LAYOUTS => "layout"` but the keyword is `layouts` (LSP surfaces a
  non-parsing name); the "sync-check validates" comment is false (sync-check never reads this file).

---

## Error-quality cleanup (P3 unless noted)

- [ ] Remaining plain string throws (builder convention is BuilderError): MB:8277
  (`buildWithParameters` missing element — most user-visible, do for 1.0), :8227/:8231/:8244/:8247
  (`dynamicValueToIndex` raw rethrow), :3169, :6991→ParseUtils.hx:7, :7674; **all of
  MultiAnimPaths.hx** (:65 — which also corrupts state, :298, :332, :369, :388, :413);
  MultiAnimParser.hx:123.
- [ ] MacroLexer raw string throws bypass ParseError machinery (unterminated string/comment/
  interpolation) — strict mode / DevBridge / hot-reload catch sites get nothing structured.
- [ ] `ParseUtils.toInt` unpositioned throws from ordinary typos (`programmable(n:int=abc)`,
  `@(c=>banana)` on color params, `0x` empty hex).
- [ ] `programmable(count=5)` misleading error (silently becomes `string=""` then fails elsewhere).
- [ ] `parseParticles` silently skips unknown properties (`speeed: 50` no-ops) — shutdown block
  errors on unknown keys; align.
- [ ] Codegen: generated `getSlot`/dispatchers throw bare Strings (breaks `catch (e:BuilderError)`);
  TSReference fallback silently loads `"placeholder.png"` (error points at a file the user never
  wrote); `getUpdatable` generated only-when-sinks-exist returns null for static names while
  `get_name()` works.
- [ ] Error text duplicates source name + uses two position formats (`error()` + `InvalidSyntax`).
- [ ] Dead code: AnimParser reachability checks (P1 above), `_`-strip in number lexer, duplicate
  `isKeyword` alternatives, DEV slide-in-flow warning that can never fire,
  `checkForUnreachableState` unused return, `LoadedAnimation` typedef, `TestMain.hx`,
  `parseViaSubprocess` misleading name, `AnimationSM.speed` unreachable field,
  `PixelLine.centerX/centerY` dead fields.

---

## Performance backlog (mostly post-1.0; items marked ⚡ are cheap)

**Parser (compile-time cost for every `@:manim`):**
- [ ] `isKeyword` allocates 2 lowercase strings/call × ~45-57 sequential guards per token — resolve
  keywords once at lex time (AnimParser already has the pattern).
- [ ] `createNode` serializes the entire NodeType via `Std.string(type)` into `uniqueNodeName` —
  kilobytes per TEXT/FLOW/PARTICLES node, retained as string lookup keys.
- [ ] ⚡ `Type.enumEq` per `match`/`expect` → constructor-index check.

**Builder:**
- [ ] `applyConditionalChains` walks the entire tree per `setParameter` + Map-iterator alloc per node —
  needs a `param → conditional-chain` reverse index (mirroring `trackedByParam`).
- [ ] Unconditional `apply{}` reconcile re-allocates `h2d.filter.*` on every setParameter of any param.
- [ ] `getCurves()` re-resolves the whole curves map per call (per colorStop segment during particle
  builds); `getLayouts()/getPaths()` allocate fresh facades inside tracked closures — memoize.
- [ ] `BuilderResult.getSlot/hasSlot` linear scans — map-backed lookup.

**Codegen (todo-performance.md items confirmed + new):**
- [ ] Per-param `_applyVisibility_X` / `_updateExpressions_X` (fixes the behavioral P16 too).
- [ ] `buildTileGroupFromProgrammable` performs K throwaway **full builds** for K tilegroups per `create()`.

**UI:**
- [ ] `getBounds()`-allocating `containsPoint` for every widget on every mouse move (only
  UIInteractiveWrapper is alloc-free); `ControllerEventHandler` allocates per input event
  (Lambda.map + Point + wrapper); drop-zone scan ~200 allocs/drag-move on a 10×10 grid; targeting
  arrow re-normalizes its path per mouse move; `addCell/removeCell` O(cells) refresh → grid
  `beginBatch()/endBatch()`.

**VFX:**
- [ ] PathGuide force field: ~93 curve evals/particle/frame (golden-section to 1e-6 evaluating both
  probes + 51 coarse samples). ⚡ Reuse one probe + loosen tolerance; properly: **arc-length LUT on
  Path** (also fixes distance-mode constant speed and `getClosestRate`).
- [ ] ⚡ Per-particle `Math.pow` with group-constant args — cache per group per frame.
- [ ] `PixelLines.updateBitmap` leaks a GPU texture per call, no `dispose()` — called from codegen
  param updates (texture churn per parameter change).
- [ ] AnimatedPathState `custom` map boxing per frame; no `hexToPixelInto` (API asymmetry forces allocs).

---

## API gaps (1.0-nice-to-have)

- [ ] `BuilderResult.dispose()` (cancel transitions, clear rebuild listeners, mark slots) — currently
  transition tweens + listeners leak on discard.
- [ ] `has*` companions: `hasLayouts/hasPaths/hasCurves/hasCurve/hasData/hasParticles` (today: try/catch).
- [ ] `SlotHandle.getScreenBounds()` missing the `disposed` guard every other method has.
- [ ] Unify throw-vs-null lookup contracts (BuilderResult throws; SwitchArmResults/SlotHandle null;
  codegen getDynamicRef null).
- [ ] `getParameterNames()` introspection on results; `#name[$i]` outside a loop silently registers
  `"name 0"` — diagnose.
- [ ] `modalDialog` calls `load()` without `clear()` — document the contract or add clear-if-loaded.
- [ ] `clear()` doesn't reset `tabGroup`/`modalOverlayConfig`; TextInput never leaves its tab group;
  duplicate interactive ids silently shadow; `GridConfig.tweenManager:Dynamic` → type it;
  tooltip helper auto-registers for dispose but **not** update (manual `update(dt)` still needed);
  `removeGroupElements` leaves group membership; `getLowerLayer` throws copy-paste 'no higher layer
  found'; `enableLinkEvents` not idempotent.
- [ ] TweenManager: generation tokens so stale `cancel(t)` can't hit a recycled tween.
- [ ] Particles: public `liveCount`, restart/reset; `ParticleGroup.enabled` setter (docstring
  describes a setter that no longer exists); `AnimationSM` speed accessor; fix
  `AnimatedPath.reset()` stale `currentState`; `currentSelector` mutable no-op.

---

## 1.1 feature roadmap

**Performance:** per-param codegen visibility/expressions; builder param→conditional reverse index;
arc-length LUT on Path; widget bounds caching; grid batching.

**Framework:**
- Declarative tooltip/panel system (todo-suggestions #9) + Auto positioning with overflow (#1) —
  the two High-impact items already triaged.
- `blockUnderlying:Bool` per dialog (resolves the documented routing asymmetry + the animated-open bug).
- Lazy building of inactive conditional arms (kills the out-of-guard evaluation class + the deferred
  dynamicRef asymmetry structurally).
- REPEAT2D full incremental parity port.
- `.anim` hot reload (top item in hot-reload.md TODO; ReloadFileType.Anim plumbing already exists —
  only the ScreenManager loop is missing).
- `.anim` strict-D alpha migration + `#RRGGBBAA` round-trip consistency.
- AnimationSM playback control: speed, pause-at-frame, `seek(frame)`, finished-once callback.
- Runtime particle tuning API (most ParticleGroup fields are builder-only); per-group `worldAnchor`;
  sub-emitter coordinate-space contract.
- `PlayAnimComplete` card-hand event (can't currently sequence effects after a played card leaves).
- Parser: float literals in int coordinate contexts; `.offset()` after bare `x, y`; scientific
  notation; conditionals inside `settings{}`; `@switch` on loop variables; root-level `@final`
  visible inside programmables; strict particle keys; duplicate-name diagnostics; `.anim` `@final`
  expressions; unknown-character diagnostics.
- Text input codegen (`createTextInput()` factory — already triaged post-1.0).
- Exception-safe param-scope swaps (`withParams` helper) across MultiAnimPaths/Layouts/particles.

**Tooling:**
- Generate tmLanguage keyword alternations from ManimKeywordInfo + case-sensitive sync-check.
- LSP: per-request try/catch; `@switch`-arm completions using captured paramTypes; enum-value
  completion after `=>`; real symbol ranges via parser positions; cross-file go-to-definition
  through `import`; incremental sync.
- DevBridge: localhost-default bind (if not done for 1.0) + auth token; CI server.js drift gate.

**Pre-existing backlog (todo-suggestions.md):** panel toggle, anchor tracking, closeAll,
EVENT_PANEL_OPEN, open/openNamed dedup, batch setDisabled, isDisabled query, text-input password
mode, auto-grow multiline, modal tab groups — all still valid; none were invalidated by this audit.
