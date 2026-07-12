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

---

## P0 — Release blockers

- [x] `P0-1` **haxelib packaging: missing `extraParams.hxml`.** The library requires
  `--macro bh.base.AtlasMacroInit.init()` (hx-multianim.hxml:3, AtlasMacroInit.hx:5) to register the
  `.atlas2` extension. A haxelib consumer using `-lib hx-multianim` never gets it → every `.manim`
  using atlas resources fails at load. Ship `extraParams.hxml` with the macro line (haxelib applies
  it automatically) and add it to README's hxml snippet. *(2026-07-12: `extraParams.hxml` added;
  README quick-start notes the `-cp` case.)*
- [x] `P0-2` **Release workflow publishes without running tests.** `release-and-publish.yml` builds, tags,
  and `haxelib submit`s with no test step/gate; failing tests still ship. Add the test suite (or a
  gate on the Tests workflow) to the release job. *(2026-07-12: restructured into
  check-version → tests → build-and-publish; tests job reuses `tests.yml` via `workflow_call` with
  `skip-report-deploy: true`.)*
- [x] `P0-3` **Version/tag state will silently skip the next publish.** Tag `v1.0.0-rc.5` already exists on
  origin while `haxelib.json` still says `1.0.0-rc.5` and ~12 newer commits sit under the dated
  `[1.0.0-rc.5] - 2026-05-15` CHANGELOG section (entries committed through 2026-06-22). Merging
  dev→main as-is hits the tag-exists guard and **publishes nothing**. Bump version + new CHANGELOG
  section before merge. Also: rc.4 *was* released (haxelib bump commit 2394795) but has no CHANGELOG
  section — its entries are folded into rc.5; `[0.4]` header is undated. *(2026-07-12: bumped to
  `1.0.0-rc.6`; all post-tag entries moved into a new `[1.0.0-rc.6] - 2026-07-12` section (rc.5
  section restored to its tagged content, verified byte-identical); rc.4 note added under the rc.5
  header. `[0.4]` header left undated.)*
- [x] `P0-4` **DevBridge binds `0.0.0.0` with `Access-Control-Allow-Origin: *`, no auth** (DevBridge.hx:101,
  :483-490, SSE :180-185). Any LAN host — or any website via DNS rebinding — can screenshot, inject
  input, `eval_manim`, `quit`. Default to `127.0.0.1` with opt-in `HX_DEV_BIND`; cheap extra: Host
  header check. (Dev-only flag, but 1.0 users will run it.) *(2026-07-12: `HX_DEV_BIND` env var +
  constructor override implemented. **Decision: default stays `0.0.0.0`** so LAN MCP clients keep
  working out of the box; security note documented in docs/devbridge.md. No Host-header check —
  it would break legitimate by-IP LAN access. Post-1.0 candidate: auth token.)*
- [x] `P0-5` **README code samples are broken** (first-contact surface):
  - `animSM.addCommand(SwitchState("idle"), ExecuteNow)` — API doesn't exist; use `animSM.play("idle")` (AnimationSM.hx:131). README:104.
  - `showScreen` → `switchTo` (ScreenManager.hx:843). README:123.
  - `showDialog` → `modalDialog` (ScreenManager.hx:532). README:238.
  - `public override function load()/onScreenEvent()` — `override` on **abstract** methods = compile error (UIScreen.hx:70,228,231; verified with `haxe --interp`). README:147,161,241.
  - `addCheckbox(builder, true)` / `addSlider(builder, 50)` / `addRadio(builder, items, true, 0)` — missing required `settings:ResolvedSettings` arg (UIScreen.hx:583/563/652). README:193,196,213.

  *(2026-07-12: all five fixed; also added haxelib/lix install commands, the `.atlas2` macro note,
  and an ATTRIBUTION.md link.)*
- [x] `P0-6` **`AllocationSmokeTest` has never run.** Fully written, advertised in CHANGELOG rc.5 and
  `.claude/rules/testing-and-debugging.md`, but never added to the `addCase` list
  (TestApp.hx:83-150). One-line fix — then it must actually pass. *(2026-07-12: registered; passes
  in both Standard and Dev runs — +6 unit assertions.)*

---

## P1 — High-severity code bugs

### Builder (MultiAnimBuilder)

- [x] `BLD-1` **REPEAT2D has no incremental-mode handling at all** (MultiAnimBuilder.hx:6437-6578). REPEAT
  collects `repeatParamRefs`, registers a structural rebuild, and sets `suppressConditionalTracking`
  (:6186-6243, :6300-6428); REPEAT2D does none of it. Consequences in incremental builds:
  `@()` arms AND their `@else` siblings all render simultaneously per iteration; last-writer-wins
  conditional registry corrupts state; param-dependent counts silently freeze. Port the REPEAT machinery.
  *(2026-07-12: ported — full REPEAT machinery (refs from both axes + child conditionals, untracked
  marking, conditional-tracking suppression, structural rebuild closure). Count freeze reproduced and
  fixed; the "both arms render simultaneously" claim did NOT reproduce in loop-var or param+`@else`
  shapes — those rendered correctly even before the port; kept as parity anchors in
  `Repeat2DIncrementalTest`.)*
- [x] `BLD-2` **`collectParamRefs` misses six `ReferenceableValue` classes** (:4174-4185):
  `RVElementOfArray.arrayRef`, `RVMethodCall` args, `RVChainedMethodCall`, `RVCallbacks(WithIndex)`,
  `RVColor`/`RVColorXY` index refs, `RVArray` elements. Result: tracked expressions / rebuild
  triggers / dynamicRef forwarding silently never fire — e.g. `tint: palette(pal, $idx)` frozen forever.
  *(2026-07-12: all six classes added; `PaletteIndexTrackingTest` pins the `tint: palette(pal, $idx)`
  repro. Side-find while testing: 2D palette declarations can't parse at all — filed as `PRS-7`.)*

### Codegen parity (ProgrammableCodeGen vs builder) — each has a mechanical repro

- [x] `CG-1` **`step($dx, $dy, N)` param-dependent offsets become 0** (CG:2291-2311 static-resolve
  fallback → 0; builder resolves at build MB:6140). Elements stack at origin.
  *(2026-07-12: fixed with CG-2 — param-dependent scalars route through the runtime rebuild path;
  rebuild method takes (count, start, step, dx, dy) and guards on all five. `CodegenRepeatParamParityTest`.)*
- [x] `CG-2` **`range($start..$end, $step)` param-dependent start/step → loop values start 0, step 1**
  (count is right, values wrong; CG:2303-2305, 2464-2467 vs MB:6151-6155).
  *(2026-07-12: fixed — `_rt_val = _rt_start + _rt_i * _rt_step` from runtime `rvToExprInt` args; the
  trigger refs now include start/step (previously only `end`), and a start shift with unchanged count
  rebuilds via the extended guard.)*
- [x] `CG-3` **`repeatable` inside `flow` always wrapped in one container** (CG:2338-2354 etc. vs
  builder's `needsWrapper` logic MB:6207-6213) → flow sees one child; iterations overlap.
  *(2026-07-12: fixed — fully static, zero-offset, non-conditional repeats with no own position
  (`ZERO`) unroll directly into the parent field; conditional/positioned/param-dependent repeats keep
  the container for visibility toggling and `removeChildren`.)*
- [x] `CG-4` **`$ctx.width/height` crashes in codegen constructor** — emits `this.getScene().width`,
  null before scene attach (CG:7055-7058). Builder uses `builderParams.scene` (MB:2947).
  *(2026-07-12: fixed — emits `ProgrammableBuilder.ctxSceneWidth/Height(this, this._pb)`: live scene
  when attached, else new injectable `ProgrammableBuilder.scene` field, else structured `BuilderError`
  matching the builder. `CodegenCtxSizeTest`; docs note in manim-reference.md Context Properties.)*

### UI / screen stack

- [x] `UI-1` **Double `OnDialogResult` when closing dialog-over-dialog** — fired at ScreenManager.hx:871 AND
  again in the Dialog→Dialog branch :696-697 (second may carry `null`). A purchase-confirm handler
  runs twice. *(2026-07-12: Dialog→Dialog branch now distinguishes close-return (no re-fire; the
  close path already fired it) from open-over (documented fire kept). `ScreenManagerDialogTransitionTest`.)*
- [x] `UI-2` **`reload()`/hot-reload with a dialog open** → Dialog→Dialog branch destroys the modal overlay
  (never recreated, :647), fires spurious `UILeaving`/`UIEntering`, and delivers a **phantom
  `OnDialogResult`** to the caller (:696-697). *(2026-07-12: same-dialog refresh is now a no-op —
  overlay, scene presence, and controllers preserved; no lifecycle round trip, no result.
  `removeModalOverlay()` moved into the branches that actually leave the dialog.)*

### VFX / animation runtime

- [x] `VFX-1` **`gravityAngle` direction convention is swapped** — gravity applied as
  `vx += g·sin(θ), vy += g·cos(θ)` (Heaps legacy 0°=down; Particles.hx:231-232) while the parser's
  constants use 0°=right/90°=down (MacroManimParser.hx:806-815) and builder passes degrees→radians
  verbatim (MB:7169). `gravityAngle: down` pushes particles **right**. The unset default masks it.
  Independently confirmed by two audits. Fix the sin/cos (or add 90°−θ in builder) and audit content.
  *(2026-07-12: sin/cos swapped to the standard (cos, sin) vector; default moved to π/2 so unset
  gravity still falls down. Resolves DEC-3. `ParticleRuntimeTest`; ref 51-codegenParticles regenerated.
  In-repo content audit: only test example 51 used gravityAngle — sibling repos should grep for it.)*
- [x] `VFX-2` **`.anim` color literals never bake alpha** (AnimParser.hx:374-379 → `0x00RRGGBB`; `.manim`
  lexer bakes `0xFF` per strict-D). `AFTint` is guard-patched but `.anim` `replaceColor` writes
  **fully transparent** pixels (via `ReplacePaletteShader.setColor` → alpha 0), and
  `getColorOrDefault/OrException` return alpha-0 ints. Fix at the lexer; keep the `>>>24==0` guards.
  *(2026-07-12: 3/6-digit forms bake 0xFF at the lexer; 8-digit keeps explicit alpha; guards kept.
  Existing color pins updated. `AnimParserTest` + anim-reference.md note.)*
- [x] `VFX-3` **`AnimationSM.onFinished()` fires every frame after completion** (AnimationSM.hx:213-223 — no
  finished latch). Handlers that spawn/free objects execute once per frame. *(2026-07-12: latched per
  playback, reset in `play()`. `AnimFilterRuntimeTest`.)*
- [x] `VFX-4` **`spawnCurve` + `maxLife: 0` hard-hangs the game** — `emissionAccumulator = +Inf` →
  `while (>= 1.0)` never terminates (Particles.hx:1438-1443; `life=0` is legal + unvalidated).
  *(2026-07-12: builder rejects `maxLife <= 0` with a BuilderError. `BuilderUnitTest`.)*
- [x] `VFX-5` **`emitBurstAt()` before first render → permanent double-draw** — sets `batch.visible = true`
  (Particles.hx:835-839) but batches are drawn explicitly in `Particles.draw()`; child-draw kicks in
  too (double alpha / wrong transform for non-relative). Delete the line. *(2026-07-12: deleted.
  `ParticleRuntimeTest`.)*
- [x] `VFX-6` **Line-only `bounds:` silently enforces a hidden 800×600 box** (defaults at Particles.hx:660-672;
  builder overrides only when `box(...)` present, MB:7281-7294). Default box should be ±infinity.
  *(2026-07-12: defaults are ±infinity. `ParticleRuntimeTest`; manim-reference.md bounds note.)*

### Filter semantics (code contradicts documented intent, all three backends)

- [x] `FLT-1` **`brightness(v)` is additive**, not a multiplier — Heaps `colorLightness` does `_41 += v`
  (MB:6938-6941, AnimParser.hx:2123-2127, codegen ~8350). The documented disabled-button pattern
  `group(brightness(0.5), grayscale(0.8))` actually **brightens**. Parser default `RVFloat(1.)`
  shows multiplier intent. *(2026-07-12: fixed as multiplier (diagonal scale) in all three backends.)*
- [x] `FLT-2` **`saturate(v)` scale off by one** — Heaps adds 1 internally, so `saturate(0)` = normal,
  `saturate(-1)` = gray (MB:6933-6937). Doc says 0=gray/1=normal. (`grayscale` is correct.)
  *(2026-07-12: fixed — `colorSaturate(v - 1)` in all three backends.)*
- [x] `FLT-3` **`hue(v)` takes radians**, documented as degrees; no angle-suffix support (MB:6949-6953 vs
  `dropShadow` which does deg→rad, MB:6961).
  → Decide: fix code (breaking for existing content — better now than post-1.0) or fix docs. Either
  way add tests pinning the chosen semantics. (Decision tracked as `DEC-2`.)
  *(2026-07-12: fixed — degToRad in all three backends; angle-suffix support left for the parser
  roadmap. DEC-2 resolved as "fix code". Matrix-level pins in `BuilderUnitTest` +
  `AnimFilterStateConditionalTest`; refs 32/68 regenerated.)*

### Parsers (empirically reproduced)

- [ ] `PRS-1` **Parameterized slot without `{}` body permanently leaks slot param scope** — restore code only
  in the `TCurlyOpen` branch (MacroManimParser.hx:3403-3426 vs :4019-4027).
- [ ] `PRS-2` **Multi-line `${…}` interpolation desyncs all subsequent line numbers** (:299-308 never bumps
  `line` on `\n`); interpolation column off-by-1/2 (:352).
- [ ] `PRS-3` **`@` modifiers silently dropped** on `@final` / `settings{}` / `transition{}` (conditional
  parsed then discarded — :3032, :3934-3962, :3895-3932); `#name` silently dropped on `@switch`
  (:5452). Should be parse errors.
- [ ] `PRS-4` **Nested `programmable` not rejected** — clobbers outer scope with no restore (:3549-3569).
  Add the root-only guard the other block types have.
- [ ] `PRS-5` **AnimParser "not reachable" validation is dead code** — checks `visited == false` on a
  null-default optional field (`null == false` is false); `Playlist.visited` never set
  (AnimParser.hx:990-1000, :619,:638,:673). Fully-shadowed animations parse silently.
  CHANGELOG:288 claims these errors fire — they cannot.
- [ ] `PRS-6` **`.anim` lexer accepts unterminated strings** — swallows the rest of the file into one token,
  errors far away (AnimParser.hx:323-341); embedded `\n` doesn't bump line numbers.
- [ ] `PRS-7` **2D palette declaration cannot be parsed** — the parser branch expects `TIdentifier("2d")`
  (MacroManimParser.hx:3775) but the lexer tokenizes `2d` as `TInteger(2)` + `d`, so
  `palette(2d:width) { … }` can never parse ("expected 2d or file in palette()"). Docs show a third
  spelling, `palette(2d, 4)` (manim.md:1419, manim-reference.md:752), which also fails. 2D palettes
  are only reachable via `palette(file:...)` today; `PaletteColors2D` is dead. Fix the lexer/parser
  to accept one spelling and align the docs. *(Found 2026-07-12 during the BLD-2 bug review.)*

### Hot reload / LSP

- [ ] `HR-1` **`result.reloadable = false` opt-out is a no-op** — read exactly once inside
  `buildWithParameters` *before* the result is returned (MB:8318 — only read in the codebase);
  reload loop never consults it (ScreenManager.hx:1440). Implement the reload-loop check or delete
  the doc claim (hot-reload.md:294-296 documents fiction; its own missing-tests list shows the intent).
- [ ] `LSP-1` **LSP: every `$param` reference completion is labeled the literal string `"$name"`** —
  `'$$name'` escapes to a literal `$` (CompletionProvider.hx:177). Intended `'$' + name`.
- [ ] `LSP-2` **Packaged `vscode/server/server.js` is 11 parser commits stale** (last built 2026-04-16),
  including the Pratt-precedence **breaking change** — shipped diagnostics disagree with the real
  parser. `npm run build`/`package` never rebuild the Haxe server. Add a prebuild step + CI drift gate.
- [ ] `LSP-3` **LSP suggests invalid syntax**: `quadratic` path-command completion isn't a parser keyword
  (ManimKeywordInfo.hx:300 `pathName(Bezier2To)`).
- [ ] `LSP-4` **LSP request handlers not individually try/caught** (ManimLanguageServer.hx:151-208) — a
  provider throw means the JSON-RPC request never gets a response; client promise hangs forever.

---

## P2 — Medium bugs (fix before 1.0 where cheap)

### Builder
- [ ] `BLD-3` Conditional sentinels not `isAbsolute` → phantom `horizontalSpacing` slot per conditional child
  inside `flow()` (MB:6660-6663; heaps Flow.hx:1452-1456). Incremental layout ≠ full layout.
- [ ] `BLD-4` `@final` inside parameterized slot bodies lost from slot ctx → `slot.setParameter` throws
  `missing_ref` (`syncFinalsFromBuilder` called for roots :8306, neither slot path: :6787-6801, :8413-8423).
- [ ] `BLD-5` Initially-hidden conditional arm `dynamicRef` gets no param forwarding after materialization
  (deferred path builds with `incrementalMode=false`, :1558-1605). Same layout initially-visible works.
- [ ] `BLD-6` `programmable tilegroup` root skips `validateTileGroupSubtree` (:7036-7049) → param conditionals
  silently freeze (full) or double-bake both arms (incremental).
- [ ] `BLD-7` Tracked expressions skipped while invisible never re-fired on `setVisibility(true)`
  (:1781-1793) → stale text/tint on reshow.
- [ ] `BLD-8` `MultiAnimPaths.getPath` / `MultiAnimLayouts.resolve` swap `builder.indexedParams` with **no
  try/finally** (MultiAnimPaths.hx:49-50/:243; MultiAnimLayouts.hx:59-71) — any throw corrupts the
  builder's param map for the rest of the session. Add a `withParams(map, fn)` helper.
- [ ] `BLD-9` `repeatable($i, array($val, arr))` leaks `$val` into enclosing scope after the loop
  (cleanup misses `valueVariableName` at :6291-6298, :6417-6423, :6575-6576, :5267-5270).
- [ ] `BLD-10` Eager pre-build of losing conditional arms evaluates expressions with out-of-guard values →
  incremental build throws where full mode is fine (tile fallback exists :3826-3859; array bounds /
  div-by-zero don't).
- [ ] `BLD-11` REPEAT loop-var shadow guard checks the element `#name` instead of the loop var (:6215-6216,
  :5318-5319; REPEAT2D does it right).
- [ ] `BLD-12` DEV: hot-reload registry handles leak when dynamicRef subtrees rebuild while detached (sentinel
  `onRemove` never fires, HotReload.hx:138-166); old child contexts' transition tweens not cancelled.

### Codegen parity
- [ ] `CG-5` `generated(cross(...))` renders a solid rectangle (CG:7382 — "approximate as solid color").
- [ ] `CG-6` `@switch` non-last `default:` arm swallows later arms in the mixed-arm path (CG:2164-2182,
  reverse-build discards accumulated chain; all-enum path is correct).
- [ ] `CG-7` `beginUpdate()/endUpdate()` batches suppress transitions AND force-rebuild every `@switch` arm
  (`_changedParam == null`; CG:720,746,781-790,967-976). Builder batches animate + gate per-ref.
- [ ] `CG-8` Conditional params inside a param-dependent repeat: codegen throws `untracked`, builder rebuilds
  (CG:3523-3543 vs MB:6199-6204).
- [ ] `CG-9` `graphics { polygon(...) }` with grid/hex coordinate points collapses to 0,0 (CG:4534-4551).
- [ ] `CG-10` `particles {}` inside a static-unrolled `repeatable` throws index-out-of-range at `create()`
  (macro counter per unrolled iteration vs PB:187-207 counting parse nodes).
- [ ] `CG-11` Conditional `tilegroup` siblings: macro doc-order index vs built-tree order mismatch → wrong
  content or out-of-range throw (CG:5787-5807 vs PB:252-267).
- [ ] `CG-12` `$array[$idx]`: index refs untracked (no `RVElementOfArray` case in `collectParamRefsImpl`
  CG:7158-7193) → stale content on `setIdx`.
- [ ] `CG-13` Inline text/richText in runtime-iterated repeats loses `styles:`/`images:`/`autoFit`/hyperlinks
  (fast path CG:3049-3134; named elements are forwarded and fine).
- [ ] `CG-14` `layers()` layer ignored for repeat/`@switch` containers (bare `addChild` CG:2354,2097,2834,2529).
- [ ] `CG-15` Flow scalars / `spacer` / `@flow.offset` use `rvToExpr` (Float) where builder uses
  `resolveAsInteger` → generated-code compile errors + truncation divergence (CG:6512-6544,1884-1896).
  Violates the established `rvToExprInt` invariant.
- [ ] `CG-16` `_updateExpressions()` re-fires ALL updates → behavioral: game callbacks re-invoked, stateanim
  `play()` restarted, filters re-allocated on unrelated `setParameter` (CG:801-808).
- [ ] `CG-17` `CBRFloat` callback result in int context silently replaced by default (PB:406-432; builder
  throws in int contexts, accepts in float contexts).
- [ ] `CG-18` REPEAT2D non-step/range axes silently render **nothing** (CG:3562-3578) — should be
  `Context.error("not supported in codegen")`.
- [ ] `CG-19` `bitmap($tileParam)` in runtime repeats mis-binds to the iterator tile / undefined `_rt_tiles`
  compile error (CG:2971-2976 matches any `TSReference`).
- [ ] `CG-20` `dynamicRef($loopVar)` treated as literal programmable name "i" (CG:3926-3939; STATIC_REF handles it).
- [ ] `CG-21` `setParameter` value-contract divergences — enum Int (codegen: unvalidated index; builder:
  throws), tile String (builder accepts filename; codegen throws), string non-String (builder
  stringifies; codegen throws). **Pick one contract** (decision tracked as `DEC-4`).
- [ ] `CG-22` `.offset()`/named-coord around runtime hex coords → `unknown identifier _hexLayout` compile
  error (CG:7995-8022, no WITH_OFFSET/NAMED_COORD recursion).
- [ ] `CG-23` Misc: maxWidth-with-param-scale bake, `TAWGrid` skipped, `$ctx.random` no truncation,
  hyperlink exception propagation asymmetry, SWITCH-node tint/filter/blendMode never applied,
  LayoutIterator `$param` points → 0,0, generated tile w/h single-truncation, dynamicRef forwarded
  string params use numeric add vs builder's string concat, REPEAT2D count key collision
  (`countX*10000+countY`, CG:3725-3733).

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
- [x] `VFX-7` Wave segment endpoint ignores residual lateral offset for fractional `count` → position jump
  into next segment + wrong Stretch scaling (MultiAnimPaths.hx:227-239 vs :723-731).
  *(2026-07-12: endpoint includes `amp·sin(count·2π)` lateral term. Continuity scan in
  `AnimatedPathBuilderTest`. Note: only counts that aren't multiples of 0.5 exhibited it.)*
- [x] `VFX-8` AnimatedPath pingPong: distance-mode speed curve un-mirrored vs other slots; events fire at
  forward progress (not mirrored position) in reversed cycles; `cycleStart` delivered with previous
  cycle's end state (AnimatedPath.hx:266-269, :289-318, :345). *(2026-07-12: all three fixed —
  speed curve mirrored; events fire by path position (descending atRate) in reversed cycles;
  cycleStart carries the new cycle's index + start position. `AnimatedPathTest` ×3.)*
- [x] `VFX-9` `AnimParser.load()` cache shares one filter instance + one extraPoints IPoint map across all
  AnimationSM instances per selector (AnimParser.hx:2210-2266) — mutation corrupts every SM.
  *(2026-07-12: cache stores filter DEFINITIONS (resolved per SM); extraPoints copied per SM.
  Also fixed `parseString`'s typed rethrow wrapping errors in haxe.ValueException. `AnimParserTest`.)*
- [x] `VFX-10` Force-field/bounds/sub-emitter coordinates are in different spaces for relative vs non-relative
  groups — undocumented (Particles.hx:1154-1225, :1318-1324). *(2026-07-12: documented in
  manim-reference.md Bounds section — emitter-local for relative, scene/worldAnchor space otherwise.)*
- [x] `VFX-11` `Curve` with duplicate time values → NaN (Curve.hx:40-45), unvalidated. *(2026-07-12: NOT
  REPRODUCIBLE — the zero-width division is unreachable: endpoint clamps catch t == firstTime, and
  the first-match scan always hits the earlier non-degenerate segment for duplicates at i>0.
  Duplicate-time points behave as step curves. No fix needed; optional hardening left out.)*
- [x] `VFX-12` `Hex.toOffsetCoordinates()` uses invalid offset=0; `HexLayout.directionToAngle` ignores
  `start_angle` (Hex.hx:252-254, :550-554). (Both unused in-library.) *(2026-07-12:
  toOffsetCoordinates commits to odd-q parity (ODD); directionToAngle became an instance method
  adding 60°·start_angle. New `HexApiTest`.)*
- [x] `VFX-13` `event name x,y { meta }` / `event name random ... { meta }` parse OK but **silently drop the
  point/random spec** (AnimParser.hx:1491-1505). Document or reject. *(2026-07-12: REJECTED at parse
  time (payload can't carry both). Two pre-existing tests pinning the lossy form replaced by the
  rejection test. Carrying both = post-1.0 feature if wanted.)*
- [ ] `VFX-14` `.anim` `@else(cond)` doesn't encode chain negation (best-score approximation); ambiguity throws
  a raw unpositioned string from `parse()` (:1916); `@(x=>a) @else(y=>b)` in one header silently
  discards the first condition. *(2026-07-12: PARTIAL — ambiguity now throws positioned
  InvalidSyntax; `@()` + `@else`/`@default` stacking in one header is a parse error. Chain-negation
  SEMANTICS deliberately deferred — matcher redesign, couples with DEC-7.)*
- [x] `VFX-15` `.anim` comparison/range conditionals accept non-numeric operands → NaN → arm silently dead.
  *(2026-07-12: post-parse validation rejects non-numeric operands and comparisons against states
  with no numeric declared values (animation/playlist/extra-point/filter selectors). Runtime matcher
  keeps silent-false for genuinely mixed states (pinned by existing test). `AnimParserTest`.)*
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
- [x] `DEC-2` **brightness/saturate/hue semantics** (see `FLT-1`–`FLT-3`): fix code to documented intent
  (breaking visuals for content that compensated) or re-document Heaps semantics. Recommend fixing
  code — the docs, the parser default, and user intuition all agree on multiplier/degrees.
  *(2026-07-12: RESOLVED as "fix code" — all three backends now match the docs. See FLT-1..3.)*
- [x] `DEC-3` **`gravityAngle`**: fix convention + audit existing `.manim` content (see `VFX-1`).
  *(2026-07-12: RESOLVED — convention fixed, default preserved as "down". In-repo content audited
  (only test example 51); sibling repos (proto-game, playground) should grep `gravityAngle`.)*
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

### README.md
- [x] `DOC-1` All `P0-5` sample fixes above; add lix install command; consider linking ATTRIBUTION.md.
  *(2026-07-12: all done — see `P0-5` above.)*

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
- [ ] `DOC-13` Filter semantics rows (brightness/saturate/hue — pending `DEC-2`); layout `align:`
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
  color metadata alpha semantics (pending `VFX-2` fix); flipX/flipY size check is load-time not parse-time.
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
- [ ] `DOC-22` hot-reload.md: `reloadable=false` claim (pending `HR-1`); registration no longer gated on
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

- [x] `TST-1` Register `AllocationSmokeTest` (`P0-6` above). *(2026-07-12)*
- [x] `TST-2` Gate release workflow on tests (`P0-2` above). *(2026-07-12)*
- [ ] `TST-3` **VisualTestBase swallow-path**: an exception in a `waitForUpdate` callback makes the test
  silently vanish from stats — run reports OK with a test missing (VisualTestBase.hx:52-64). Fail loudly.
- [ ] `TST-4` **Add an LSP CI job** (`haxe lsp/test-lsp.hxml && node lsp/bin/test.js` + `haxe lsp/lsp-server.hxml`)
  — also the only JS-target *execution* gate (JS is compile-only today) and the server.js drift gate.
- [ ] `TST-5` Tests for `sceneToHex` (advertised rc.5 feature, zero tests) and the grid cell-animation/detach
  family (`tweenCell`/`addCellAnimated`/`removeCellAnimated`/`detachCellVisual`/`reattachCellVisual`).
- [ ] `TST-6` Tests pinning whatever brightness/saturate/hue/gravityAngle semantics are decided
  (`DEC-2`/`DEC-3`); a `.anim` replaceColor **visual** test (currently parse-only); a
  `event x,y {meta}` behavior test.
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
- [ ] `PERF-7` `BuilderResult.getSlot/hasSlot` linear scans — map-backed lookup.

**Codegen (todo-performance.md items confirmed + new):**
- [ ] `PERF-8` Per-param `_applyVisibility_X` / `_updateExpressions_X` (fixes the behavioral `CG-16` too).
- [ ] `PERF-9` `buildTileGroupFromProgrammable` performs K throwaway **full builds** for K tilegroups per `create()`.

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
- Lazy building of inactive conditional arms (kills the out-of-guard evaluation class `BLD-10` + the
  deferred dynamicRef asymmetry `BLD-5` structurally).
- REPEAT2D full incremental parity port (`BLD-1`).
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
