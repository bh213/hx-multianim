# Whole-code review — 2026-09-26

Scope: all of `src/` at `228f959` (dev), reviewed in the worktree `.claude/worktrees/review-whole-code`.
Twenty finder passes: line-by-line scans per area (base runtime, screens/controllers, grid + draggable,
card hand + widgets, builder ×2, codegen ×2, parser ×2, stateanim + paths, DevBridge + hot reload) and
cross-cutting passes (recent-commit regressions, cross-file contracts, wrapper/proxy correctness,
Haxe/Heaps pitfalls, efficiency, reuse, simplification, root cause). Every item below was re-checked by a
separate adversarial verifier against the source. Parser items were reproduced with `haxe --interp`
parse probes; the codegen compile errors were reproduced by compiling the shapes through a scratch copy
of the `test/examples/152-codegenCompileErrors` harness. Refuted claims are left out; items the verifier
could only partly trace are marked *(plausible)*.

Not run: the cloud `/code-review ultra` pass (user-triggered only) and the conventions pass.

**Status 2026-09-27:** 12 items fixed in `7d43afd` and ticked below (ERR-10, UI-60, UI-36, UI-43, CG-40,
PRS-10, PRS-16, PRS-18, PRS-19, PRS-20, PRS-23, DOC-26); PRS-9 partly. Also fixed 2026-09-27: the
interactive-wrapper cluster (UI-28, UI-52, UI-54, UI-55, UI-57, UI-58, UI-53) and the reload clusters
(HR-6, HR-3, HR-2, DEV-2, DEV-3, HR-5, HR-4). Fixed 2026-09-28 in three commits: dialog results and
transitions `c388b14` (UI-29, UI-51, UI-30, UI-31, UI-47); `a128c22` (UI-37, CG-27, CG-32, BLD-25, BLD-28,
VFX-20); grid teardown and zero-length paths `8b734f0` (UI-16, UI-17, UI-59, VFX-33, UI-27, UI-26). Found
while fixing those and filed below: UI-65..UI-71, BLD-33. A pre-push review of those three commits
(2026-09-29) confirmed every claimed fix and filed UI-72..UI-74 and VFX-37 (UI-71 widened). Fixed
2026-10-05 on `bugfix/tilemap-chunk-borders-and-runtime-fixes`: VFX-23, VFX-24 (with tween order,
`clearHand` drag state and the cursor while targeting, from a separate report). The summaries below
list open items only.

**Legend:** same as `release-1.0-audit.md` — `[ ]` open, **P1** fix before 1.0, **P2** should fix,
**P3** acceptable post-1.0. 🤖 marks agent-facing defects: they break DevBridge/MCP, hot reload, the LSP
or diagnostics, or they fail silently, so an agent that drives the library from the docs and from error
messages cannot notice or self-correct. File:line references are for `228f959`.

**IDs** continue the sequences of `release-1.0-audit.md` (next free number per prefix as of 2026-09-26).
New prefix `DEV` = DevBridge / MCP transport. Before assigning a new ID, check both files. To review one
item: `/bug-review todo/review-2026-09-26-whole-code.md UI-16`.

---

## Agent-user impact — start here

An agent drives this library three ways: it edits `.manim`/`.anim` from the docs and reads the parse and
build errors, it hot-reloads, and it inspects and pokes the running game through DevBridge/MCP. Each
loop has defects that either lie (report success while nothing happened) or point at the wrong cause.

**The tools report success when nothing happened**
- `DEV-7`, `DEV-9` — click coordinates and inspection coordinates are in different spaces under zoom;
  clicks computed from inspection miss while returning success.
- `DEV-1` — a request answered 408 may still execute; a retry runs it twice.
- `DEV-4`, `DEV-10` — skipped events, empty parameter lists.

**The edit-fix-retry loop is misdirected**
- `ERR-9`, `LSP-6` — errors are positioned at the next token, or at line 0.
- `CG-33` — codegen type errors point at the library source, not the `.manim`.
- `BLD-13`, `BLD-14`, `BLD-20`, `BLD-21`, `CG-26`, `PRS-24`, `VFX-27` — messages that name the wrong
  cause ("reference i does not exist" for a loop variable, "unknown animation 0", "Could not parse
  Press <A> to jump", "Null access").

**Invalid input is silently accepted with a different meaning** — the agent never learns it was wrong:
`PRS-9` (colour typos), `PRS-14` (`$param` taken as a literal name), `BLD-16`/`BLD-17` (`==`
comparisons), `VFX-28` (metadata typos).

**Documented syntax is rejected** — agents copy the docs verbatim: `PRS-21` (named
paths/curves/layouts), `PRS-13` (method calls in X), `DEC-9` (contradictory strict-D docs).

**Previews an agent looks at are wrong** — `VFX-32` (DevBridge bounds of flipped sprites).

---

## Existing audit items confirmed or extended

- `UI-3` — two new consequences filed as `UI-30` and `UI-31`.
- `UI-4` — confirmed still open (lines moved: instant branch ScreenManager.hx:626-631, animated
  :829-834); the animated path never widens the controllers back to `[dialog, oldMaster]`.
- `UI-14` — confirmed, plus the missing half: while disabled, the controller's `OnLeave` is swallowed
  (UIInteractiveWrapper.hx:97, :120), so no `UILeaving` is pushed and a tooltip opened on `UIEntering`
  stays open.
- `UI-10` — confirmed (the absolute `content.getBounds()` inside a scrolled mask). Correction to one
  finder: the helper can hold a scroll up to half the range at scene y 0, not "no scroll at all"; with a
  large scene y, content that fits still scrolls.
- `UI-15` — cell-drag start's phantom `CellDataChanged` pair is confirmed (a third fires on cancel);
  `cancelDrag()` sends no `ZoneLeave`/`ZoneRejectLeave` and no `"dragCancel"` custom event, `clear()` fires
  nothing, and a `cancelDrag()` from inside an `OnRelease` callback passes a null wrapper and tears
  down twice. The "no DragCancel" wording is stale for `cancelDrag` (it fires at :490-492).
- `DOC-21` / `DOC-22` — confirmed: every build with `reloadable == true` is registered, incremental or
  not; the `list_active_programmables` note string (DevBridge.hx:2078) is false.
- `UI-7` — confirmed by three passes. Extra consequence: a skipped `UIMultiAnimDraggable.clear()` leaves
  event capture running and a mid-drag `animOnComplete` able to fire against the torn-down screen.
- `UI-11` — confirmed by three passes. Extra: the stale wrappers keep matching a *re-registered* grid
  (prefix match), and `CellTargetEnter/Leave` is emitted N+1 times per hover.
- `UI-15` — the "cancel a `TweenSequence` from a member's onComplete" sub-bullet is confirmed; the
  `clear()` variant is new and filed as `VFX-25`.
- `ERR-2` / `ERR-3` — confirmed; the LSP consequence (diagnostic at line 0) is filed as `LSP-6`.
- `ERR-5` — confirmed; it also applies to `parseSubEmitters` (MacroManimParser.hx:4904), which ERR-5
  does not mention.
- `VFX-14` / `DEC-7` — confirmed still open. Extra: the same `@else(cond)` chain has three meanings — a
  parse error ("ambiguous") in extrapoints/playlists/headers, first-arm-wins in `filters {}` and in
  `metadata {}` — and plain cross-state chains (`@(dir=>l) … @else(weapon=>rifle) …`) are rejected too.
- `DOC-19` — the metadata-validation gap returns wrong values, not only undocumented behaviour; filed as
  `VFX-28`.
- `VFX-16` — duplicate `@final K` in one scope is another silent overwrite (`PRS-15`).
- `VFX-17` — the "parseXY asymmetry" remainder is still live for method calls; filed as `PRS-13`.
- `DOC-11` — the curve default-values half is confirmed (fix the doc, the code is sensible); the comma
  half is new (`PRS-23`).
- `VSX-3` / `DOC-12` / `LSP-5` — confirmed; the remaining keyword-table drift is `LSP-7`.
- `DEC-1` — `$hex.edge(d)` on `hex: flat` returns the edge toward direction d+1 (`BLD-30`); decide with
  DEC-1 because the fix changes pinned reference images.
- `PERF-4`, `PERF-6`, `PERF-10`, `PERF-12` — all confirmed. PERF-6 additionally: the rearrange path is
  re-resolved once per card on every hover change (`UICardHandHelper.hx:1504`, ≈250–350 allocations for
  a 7-card hand). PERF-12 count is higher than stated: `incrX`/`incrY` default to true, so ≈3.4
  `Math.pow` per particle per frame with defaults.
- `CG-13` — confirmed and wider: runtime-built repeat bodies drop far more than text styles (`CG-35`).
- `CG-23` — the TAWGrid/maxWidth fix left the autoFit half unfixed (`CG-28`).
- `CG-21` family — enum params forwarded as their Int index also break every stateanim sink (`CG-26`).

---

## UI — screen stack, interactives, helpers

- [x] `UI-28` **P1** 🤖 **`syncInteractivesFrom` deletes the interactives of every other source that
  shares its prefix** — the rebuild listener diffs by prefix only (UIScreen.hx:1097-1121): with two
  incremental results registered under the same prefix (`null` included — the cookbook's two-builder
  screen, manim-cookbook.md:1440), any value-changing `setParameter` on one (an autoStatus hover is
  enough) unregisters and `remove()`s every interactive of the other, and they never come back because
  `getInteractives()` filters detached nodes (MultiAnimBuilder.hx:2275-2277). Silent: the second
  result's buttons just stop responding. *Test: two incremental results, `addInteractives` both,
  `setParameter` on the first → `getInteractive(secondId)` still non-null and attached.*
  **FIXED 2026-09-27** with the wrapper-lifecycle cluster below. `UIScreenInteractiveSyncTest.testRebuildLeavesInteractivesOfOtherSourceUnderSamePrefix`.
- [x] `UI-29` **P1** **A reused dialog auto-closes with its previous result** —
  `closeDialogWithTransition` (both branches) and the dialog-over-dialog branch read
  `controller.exitResponse` without clearing it (ScreenManager.hx:711, :885); the only reset is inside
  `UIDefaultController.update()` (:276-285), which never runs once the dialog left `activeScreens`.
  Reopening the same dialog instance (e.g. an `OkCancelDialog` with `closeTransition`) delivers the old
  `OnDialogResult` on the first `update()` and closes it before it renders — a "confirm purchase" dialog
  confirms itself. `switchScreen`'s forced close (:779-783) delivers the stale value too. *Test:
  ScreenManagerDialogTransitionTest — setExitCode, closeDialogWithTransition(Fade), reopen, update →
  still open, no result.*
  **FIXED 2026-09-28** (`c388b14`): the exit response is taken (read and cleared) when delivered and cleared when a dialog opens. `ScreenManagerDialogTransitionTest.testReopenedDialogAfter*DoesNotReplayItsResult`, `testCoveredDialogRevivedAfterTopCloseDoesNotReplayItsResult`.
- [x] `UI-30` **P2** **Closing a dialog during its own open transition leaves it dim/off-screen**
  *(extends UI-3)* — the controller-exit close in `update()` (:288-302) and the instant
  `closeDialogWithTransition` branch (:886-890) never call `finalizeTransition()`; `removeScreen`
  cancels the enter tween (onComplete skipped), the root keeps its partial alpha/x/y (only the cleanup
  at :837-848 resets transforms, and only for removed screens), `isTransitioning` stays true, and the
  next instant `modalDialog` shows the stale transform. *Test: modalDialogWithTransition(Fade(1.0)),
  update(0.1), setExitCode, update → isTransitioning false; reopen → root.alpha == 1.*
  **FIXED 2026-09-28** (`c388b14`): the controller-exit and instant closes call `finalizeTransition()` first, which now finishes the transition tweens. `testDialogExitDuringOpenTransitionFinishesTheTransition`, `testInstantCloseDuringOpenTransitionFinishesTheTransition`.
- [x] `UI-31` **P2** **An interrupted transition's enter tween later runs the NEXT transition's cleanup**
  *(extends UI-3)* — `executeTransition` hangs `onComplete` on the last tween, which is the entering
  root's tween whenever nothing is removed (first screen, any dialog open) (:1063-1076); the closure
  reads `transitionCleanup` at fire time (:1046-1052) and `finalizeTransition` does not cancel entering
  roots. So `switchTo(A, Fade)` then `switchTo(B, SlideLeft)` mid-fade removes A early and clears
  `isTransitioning` while B still slides; a `closeDialogWithTransition` during the open fade delivers
  `OnDialogResult` early. *Test: ScreenTransitionIntegrationTest per verifier sketch.*
  **FIXED 2026-09-28** (`c388b14`): a `transitionSerial` guard makes the onComplete of an ended transition a no-op; `finalizeTransition` finishes entering roots too. `testInterruptedSwitchDoesNotEndTheNextTransitionEarly`, `testClosingDialogDuringOpenFadeDeliversResultWhenCloseEnds`.
- [ ] `UI-32` **P2** **Tooltips and panels are misplaced inside any offset layer** — `UIPositionHelper`
  assigns `anchor.getBounds()` (absolute scene coordinates) to the target's local x/y
  (UIPositionHelper.hx:9-24); `UITooltipHelper`/`UIPanelHelper` then add the target to a layer, which in
  `UIScrollableScreen` lives under `scrollContent` (y = -scroll). Scroll 300px → tooltip appears 300px
  too high; same during a slide transition or shake. Sibling of UI-10. *Fix: `anchor.getBounds(target.parent)`
  after adding.*
- [ ] `UI-33` **P2** **ScreenManager can never be torn down; old managers keep receiving input** —
  `ControllerEventHandler` registers on the `hxd.Window` singleton (ControllerEventHandler.hx:12-17) and
  neither it nor `ScreenManager` has a `dispose()`/`removeEventTarget`. Every manager ever built keeps
  dispatching clicks and keys to its stale screens and pins their scene graphs and tweens; the test
  suite builds nine per process, so earlier tests' screens receive later tests' synthetic input.
- [x] `UI-60` **P1** **`MasterAndSingle(m, s) → Single(s)` crashes** — when the single screen stays and only
  the master goes, `removedScreens` is still null at `removedScreens.push(oldMaster)`
  (ScreenManager.hx:600-612; it is assigned only inside `if (oldSingle != single)`). Null safety does not
  flag it and no test switches this way; the animated path handles it. *Test:
  updateScreenMode(MasterAndSingle(M, S)) then updateScreenMode(Single(S)) → no throw, M removed.*
  **FIXED 2026-09-27** (`7d43afd`): `removedScreens = []` before the `if`.
  `ScreenManagerDialogTransitionTest.testMasterAndSingleToSameSingle_RemovesOnlyMaster`.
- [x] `UI-47` **P2** **`switchScreen(MasterAndSingle(A, B), transition)` from `Single(A)` leaves A invisible
  but active** — `computeScreenDiff` puts A in both the add and the remove set (ScreenManager.hx:983-989)
  where the instant path throws (:589, :610-611, :622); A gets a second UIEntering, its root is detached
  by the cleanup, yet it stays in `activeScreens` and is updated and hit-tested. Same gap for
  `MasterAndSingle(A,B) → Single(A)` and `→ MasterAndSingle(B,A)`: the animated path has none of the
  instant path's guards. UI-5 family.
  **FIXED 2026-09-28** (`c388b14`): `computeScreenDiff` has the instant path guards, so the animated switch throws the same errors before any state changes. `testPromotingTheSingleToMasterWithTransitionIsRejectedLikeTheInstantSwitch`.
- [ ] `UI-49` **P3** **Dialog-close and overlay fade-out tweens skip `skipFirstDt`** — contrary to the
  documented rule (runtime-systems.md "All transition tweens use skipFirstDt") at :1148-1161 and
  :1294-1295. No visible jump in ordinary use; after an expensive closing frame the fade starts part-way.
  Related: `isTransitioning` mirrors `transitionCleanup != null` except inside `closeDialogWithTransition`
  (:895-934), where a revived dialog's `UIEntering` code runs with the flag set and no cleanup; a
  `finalizeTransition()` there desyncs the two.
- [ ] `UI-45` **P2** **`onEnterTransition`/`onExitTransition` overrides are silently ignored** — the hooks
  are documented as ScreenManager-integrated (UIScreen.hx:214-226) but nothing calls them anywhere in
  this repo or the sibling repos. Also dead: `UIScreen.validateSettings` (:431), `mergeExtraParams`
  (:541), `AnimParser.hexToSelector` (:2190).
- [ ] `UI-61` **P2** **The two settings readers disagree on coercion** — `UIScreen.get{Int,Float,Bool}Settings`
  (81 call sites) coerce colour, float and string values and throw plain strings (UIScreen.hx:373-429);
  `BuilderResolvedSettings.get*OrDefault` (22 call sites) throw `BuilderError` for the same values
  (MultiAnimBuilder.hx:199-296). The same key is read by both: dropdown `transitionTimer => $t` with a
  float param works in a placeholder's `settings {}` (UIScreen.hx:969) and throws in `#dropdown`'s root
  settings (UIMultiAnimDropdown.hx:67); same split for `scrollSpeed`. `AnimMetadata` is a third
  near-copy. Make UIScreen wrap `BuilderResolvedSettings`.
- [x] `UI-51` **P1** **Opening the next dialog from `OnDialogResult` delivers the result twice and loses the
  new dialog** — the result is delivered while `mode` is still `Dialog(A)` (ScreenManager.hx:297-300,
  :885-889), so `modalDialog(B)` inside the handler takes the dialog-over-dialog branch, which delivers
  A's result again (null on the update path, :693-712), and the pending `updateScreenMode(previousMode)`
  then removes B in the same frame. A handler that opens B without checking the result recurses forever.
  *Test: probe screen opening B from OnDialogResult("A") → one result, B shown.*
  **FIXED 2026-09-28** (`c388b14`): the controller-exit and instant close paths close first and deliver afterwards, like the animated close. `testOpeningNextDialogFromResultShowsItAndDeliversOnce`, `testOpeningNextDialogFromResultOfInstantCloseShowsIt`.

**Interactive wrapper lifecycle.** `UI-28`, `UI-52`, `UI-54`, `UI-57` and `UI-58` share one cause:
`syncInteractivesFrom` (UIScreen.hx:1097-1133) diffs by prefix and id only, and removal calls
`remove()` on the builder-owned object. Keying wrappers by source and object identity, and never
detaching builder-owned objects, fixes all five.
**FIXED 2026-09-27** (with `UI-53`, `UI-55`): wrappers record their source and the sync touches only
its own `(source, prefix)`; a wrapper whose object a rebuild recreated under the same id follows it
(`UIInteractiveWrapper.rebind`, so hover/`disabled`/priority carry over — a fresh wrapper would make the
controller send leave/enter on every hover rebuild); objects are never detached; `addInteractives` takes
an `eventPriority` applied to later wrappers too; the auto helper is created on first need;
`removeInteractives` unbinds only its own wrappers. Tests in `UIScreenInteractiveSyncTest`.

- [x] `UI-52` **P1** 🤖 **A rebuild that recreates an interactive with the same id leaves a dead wrapper** —
  the diff keeps any wrapper whose id still exists (:1113-1115, :1128-1129), so after a `@switch` arm
  rebuild or a repeat count change the wrapper points at the old, detached object and the live one is
  never wrapped. Wider than it sounds: an arm rebuilds when any conditional inside it changes, so the
  repo's own `SWITCH_AUTO_STATUS_MANIM` pattern (autoStatus interactive with `@(status=>hover)` visuals
  in an arm) goes dead after the first hover. Existing tests check only that `getInteractive(id)` is
  non-null. `UIRichInteractiveHelper.resync` is not affected.
- [x] `UI-54` **P1** 🤖 **An interactive inside a hidden conditional container is dead after it is shown
  again** — hiding a block conditional / `layers()` / `flow()` that holds an interactive makes the sync
  drop its wrapper through `removeElement`, which `remove()`s the object from its still-live container
  (UIScreen.hx:1117-1121, :1322); showing re-attaches only the container (MultiAnimBuilder.hx:957-975),
  so the interactive is out of the tree for good. Same cause: `removeInteractives(p)` followed by
  `addInteractives(sameResult, p)` — the usual way to toggle a HUD's input — wraps nothing. The flat
  `@(c) interactive(...)` form survives.
- [x] `UI-57` **P2** **Panel buttons rebuilt after open lose overlay priority** — `UIPanelHelper` raises
  only the wrappers returned at open time to `UIEventPriority.Overlay` (UIPanelHelper.hx:134-135,
  :165-166, :275-276); wrappers the sync creates later have priority 0, so clicks go to the content
  underneath.
- [x] `UI-58` **P2** **An `autoStatus` interactive that appears after registration never gets hover
  states** — the auto-status helper is created only if one exists at `addInteractives` time
  (UIScreen.hx:1058-1076) and the sync resyncs only when it exists (:1132-1133).
- [x] `UI-55` **P2** **A panel whose interactives are all behind an unmatched conditional is never wired** —
  `open`/`openAt`/`openNamed` call `addInteractives` (and install the rebuild listener) only when the
  panel has interactives at open time (UIPanelHelper.hx:133-135, :164-166, :274-276); interactives
  materialised later by `setParameter` never get wrappers.
- [ ] `UI-56` **P2** **`UIScrollableScreen` throws for a postponed dropdown or draggable** — content sits in
  `scrollContent` at root layer 0, which no `LayersEnum` maps to, so `findLayerFromObject` throws
  `layer not found for object` in the first `update()` (UIScrollableScreen.hx:17, :32-45; UIScreen.hx:
  1404-1417). The same element works on a plain screen.
- [x] `UI-53` **P3** **`removeInteractives(prefix)` strips auto-status bindings of child prefixes** —
  wrappers and subscriptions are removed by exact prefix (UIScreen.hx:1170-1172, :1190) but bindings by
  `startsWith(prefix + ".")` (UIRichInteractiveHelper.hx:128-132), so an open panel prefixed
  `hud.settings.menu` loses its hover states when the HUD refreshes.

Found 2026-09-28 while fixing the dialog items (`c388b14`):

- [ ] `UI-65` **P2** **An instant switch out of a dialog drops its result** — `switchScreen(mode)` without a
  transition, or a direct `updateScreenMode`, from `Dialog` mode closes the dialog without delivering
  `OnDialogResult`; the animated switch delivers it (through `closeDialogWithTransition`). Since
  `c388b14` the stale value no longer replays on the next opening, but the result is lost.
- [ ] `UI-66` **P2** **Any finished controller closes the open dialog with its own value** —
  `ScreenManager.update()` handles `UIControllerFinished(result)` from every active screen by switching
  on `mode`, so under `Dialog(...)` it closes the dialog and delivers `result` as the dialog's
  `OnDialogResult` even when the finished controller is the master's (the master stays active under a
  dialog opened over `MasterAndSingle`, see UI-4).
- [ ] `UI-67` **P2** **A rejected switch from a dialog still closes the dialog** — `switchScreen(…,
  transition)` from `Dialog` mode closes the dialog before `computeScreenDiff` validates the target mode
  (the role-change guards added for UI-47), so a rejected switch throws with the dialog already gone.
  And the instant `Dialog → MasterAndSingle` branch of `updateScreenMode` has no role-change guard: over
  `Single(A)` it accepts `MasterAndSingle(A, B)` and leaves A on the content layer.
- [ ] `UI-68` **P3** **The covered dialog's result is delivered mid-switch** — opening a dialog over
  another delivers the covered dialog's `OnDialogResult` inside `updateScreenMode`, before the switch
  commits: a handler that opens a dialog from it nests, and one that opens a dialog on any result (null
  included) recurses forever. The close paths deliver after the switch since `c388b14` (UI-51).
- [ ] `UI-69` **P3** **`finalizeTransition` cannot finish a `Custom` transition** — its tweens come from
  the game's function and are not in `transitionTweens`, so an interrupted `Custom` transition keeps
  animating; the `transitionSerial` guard (`c388b14`) does stop it running the next transition's
  cleanup. The remaining half of UI-3 for custom transitions.
- [ ] `UI-72` **P3** **A pending animated close can deliver a result that changes the mode under the next
  close** — since `c388b14`, `update()`'s controller-exit path and `closeDialogWithTransition` call
  `finalizeTransition()` before reading `mode` (ScreenManager.hx:318, :1028). If that finalizes an
  animated dialog close, its `OnDialogResult` handler runs first and may open or switch screens; the
  code then acts on the new mode: it closes the wrong dialog and delivers the result under the wrong
  name, or `update()` throws `unhandled exit`. Sequence: dialog over dialog, animated close of the top
  (the covered one revives), covered one exits within the fade, handler opens another dialog. Capture the
  `Dialog` fields before finalizing and re-check afterwards. Related nit: the result is now taken before
  `updateScreenMode`, so a throw there (a `UILeaving` handler, a failed hot reload) loses it.
  *Found 2026-09-29.*

## UI — panels and tooltips

- [ ] `UI-34` **P2** **`closeNamed()` loses a fade-out that was cancelled elsewhere; the panel stays as a
  ghost** — when the previous fade-out tween was cancelled outside the helper (a screen switch runs
  `cancelAllChildren(root)`, or `TweenManager.clear()`), `closeNamed()` drops the tracking record
  without `obj.remove()` (UIPanelHelper.hx:310-315); the fade's onComplete — the only removal — never
  ran. The panel stays parented at mid-fade alpha, and `dispose()` can no longer reach it. The
  single-panel path handles the same case (`cancelActiveFadeOut`, :441-447). *Test in verifier notes.*
- [ ] `UI-35` **P2** **Leaving a screen mid fade-out re-shows the half-faded panel on return** — the
  root cause of UI-34, independent of `closeNamed`: `ScreenManager` cancels (not finishes) every tween
  under a leaving root (:554-558, :838-847) and only detaches the root; `UIPanelHelper` has no
  UILeaving hook and never checks `tween.cancelled`, so the panel is visible again at mid-fade alpha as
  soon as the screen comes back. *Fix: detach tracked fade objects on UILeaving / in
  `checkPendingClose` when cancelled, or finish instead of cancel on leaving roots.*
- [ ] `UI-48` **P3** **A manually built `UIPanelHelper` is never disposed by `clear()`** — only
  `createPanelHelper` registers it, and `registerPanelHelper` is not public (UIScreen.hx:833-849), so
  `new UIPanelHelper(screen, …)` — the constructor example in runtime-systems.md:300 — keeps its fade
  running on a detached object and reports `isOpen()` after `clear()`. `UITooltipHelper`'s comment
  "symmetric with UIPanelHelper auto-wiring" (:77-78) is not true.
- [ ] `UI-64` **P3** **Single and named panels exempt each other's triggers asymmetrically** — clicking a
  named panel's trigger closes the open single panel, and clicking the single trigger closes open named
  panels (UIPanelHelper.hx:384-385 vs :402-403). Doc nits in the same file: the `handleOutsideClick`
  docblock sits above `var _pendingClose` (:364-372), and the dispose comment (:490) names a field
  `namedFadeOutTweens` that is `namedFadeOuts`.

## UI — grid and drag-drop

- [x] `UI-16` **P1** **Disposing two linked grids during a cross-grid swap throws** — the displaced
  item's animation sits in the target grid's `activeSwapAnims` with a callback that rebuilds the SOURCE
  grid, and vice versa (UIMultiAnimGrid.hx:1300-1301, :1316); `dispose()` fires pending callbacks
  (:1618-1623) then clears `cells` (:1644), so the grid disposed second (screen teardown order) throws
  `Cell (c, r) does not exist` from `rebuildCell` (:603) and aborts `UIScreen.clear()`. Same throw from
  `update()` if only one grid is disposed. *Test: two linked grids, drag onto an occupied cell,
  dispose A then B (and mirror) → no throw.*
  **FIXED 2026-09-28** (`8b734f0`): late swap work uses `rebuildCellIfPresent`; `dispose()` takes its swaps off the list before firing them. `testDisposingLinkedGridsMidCrossGridSwapDoesNotThrow`, `testUpdateAfterLinkedGridDisposedMidSwapDoesNotThrow`.
- [x] `UI-17` **P1** **Removing the source cell of an active cell drag throws and wedges every later
  drag** — every settle path ends in `set(src)` → `getEntry` throw (:1385-1388, :1289, :1660) after
  `cellDragObj` was nulled; `cellDragFinish` never runs, `cellDragSettling` stays true, and the next
  press detaches a visual that can never move or be released (:1043 vs :1007/:1062). *Test:
  createCellDragGrid; click (0,0); removeCell(0,0); release → no throw; second drag releasable.*
  **FIXED 2026-09-28** (`8b734f0`): `removeCell`/`removeCellAnimated` end a drag whose source they remove (`cellDragAbortIfSource`); a return landing on a removed cell finishes. `testRemovingDragSourceCell*` (three tests).
- [x] `UI-27` **P2** **A swap callback that disposes the grid crashes `update()`** — `update()` fires
  each completed swap's callback inside a descending loop (:1559-1576); a callback that disposes the
  grid (screen switch → `clear()` → `dispose()` → `activeSwapAnims.resize(0)`) leaves the loop reading
  a null entry when two swaps were in flight. `UICardHandHelper` uses collect-then-fire for exactly
  this (:741, :1590). *Test: two swapCells in one frame, dispose from ctx.onComplete, update → no throw.*
  **FIXED 2026-09-28** (`8b734f0`): `update()` collects finished swaps and fires them after the loop. `testSwapCompletionThatDisposesGridDoesNotCrashUpdate`.
- [ ] `UI-21` **P2** **`makeDraggableFromCell` hands the live cell visual to the draggable** — the entry
  keeps pointing at the object now inside the draggable (:1491-1509), unlike every internal path which
  swaps in a `DummyCellVisual` (:884-899). Any `rebuildCell`/`removeCell`/`swapCells`/swap-drop on that
  cell `remove()`s the flying visual (destroying `h2d.Graphics` content), and `clear(src)` rewrites its
  params. Consequence: with `swapEnabled` and no swap/return path, `handleSwapDrop`'s synchronous
  `rebuildCell(src)` (:1957-1962) makes the dragged item vanish at drop time and an empty root snaps.
  *Test: set; makeDraggableFromCell; rebuildCell → draggable target still parented.*
- [ ] `UI-22` **P2** **Dropping a cell's draggable back onto its own cell is not a no-op** — drop zones
  include the source cell (:1760-1790). With `swapEnabled` the default predicate (`isOccupied`, true for
  the source) routes it to `handleSwapDrop`: a bogus `CellSwap(src, src)`, a double rebuild, and an
  empty draggable (:1840-1842, :1931-1962). Without `swapEnabled` it emits `CellDrop(cell == source)`,
  and the documented handler (`set(cell, payload); sourceGrid.clear(sourceCell)`) wipes the item.
  `swapCells` (:444) and the built-in drag (:1173) already exclude same-cell.
- [ ] `UI-19` **P2** **Built-in cell drag ignores `swapAccepts`** — the release decides swap-vs-drop with
  `swapEnabled && isOccupied` only (:1219-1223); the external-draggable path honours the delegate
  (:1840-1841) as the `GridConfig` contract promises. *Test: swapAccepts → false; drag onto occupied →
  CellDrop, not CellSwap.*
- [ ] `UI-20` **P2** **Card targets on `rectOrigin: Centered` grids are offset by half a cell** — the
  synthetic interactive is placed top-left at the cell position for every Rect grid (:2033-2037) while
  hover/drop hit-tests treat that point as the centre (:1720-1721, :2007-2010), so the card arrow snaps
  to and plays on the neighbouring cell.
- [ ] `UI-25` **P2** **Hex drop zones and card targets overlap their neighbours** — both use a 2sx × 2sy
  box around the centre (:2012-2013, :2129) although neighbouring hexes are √3·sx apart; in the overlap
  band the draggable picks the last zone in map order and the card hand the first, neither matching
  `cellAtPoint`.
- [ ] `UI-24` **P2** **`removeDrops`/`dispose` leave the grid's highlight wrappers on the draggable** —
  only the zones are removed (:1475-1483, :1626-1628); the `onDragStartHighlightZones` /
  `onDragEndHighlightZones` / `onDragDrop` wrappers (:1804-1822) stay chained, so a grid that no longer
  accepts drops still highlights its cells on every drag start and is kept alive. Each
  `acceptDrops → removeDrops → acceptDrops` cycle nests another wrapper whose stale inner copy runs
  first with the old `accepts`. Draggable-side analogue of UI-11.
- [ ] `UI-18` **P2** **`detachCellVisual`/`reattachCellVisual` duplicate the cell visual** — detach
  immediately rebuilds a fresh visual with the same data (docstring says the cell shows empty,
  :854, :872-875); reattach adds the returned object at its stale position, positions the fresh entry
  instead, and never re-registers it (:903-914), leaving an orphan `removeCell` never removes.
- [ ] `UI-23` **P3** **One-off `DropContext` custom paths stick to the draggable forever** —
  `rejectWithPath`/`acceptWithPath`/`SwapContext` snap paths permanently replace the draggable's path
  factories (:1850-1852, :1869-1870, :1917-1918); the "save current factory" comment has no save. The
  built-in cell-drag path resolves the path per drop (:1246).
- [x] `UI-26` **P3** **An accepted external drop settling after `dispose()` runs the game's callback
  against the disposed grid** — `dispose()` completes swap and cell-drag animations at once
  (:1616-1621) but for `acceptDrops` draggables only removes zones (:1624-1627); the draggable's own
  snap (an AnimatedPath, not a tween) later fires `DragSnapComplete` → `ctx.onComplete`.
  **FIXED 2026-09-28** (`8b734f0`): a run-once `DropSettle` per accepted drop; `dispose()` completes the pending ones. `testAcceptedExternal*SettlingAfterDisposeDoesNotCallBackLater`.
- [ ] `UI-46` **P3** **`ctx.reject()` + `ctx.onComplete(cb)` runs `cb` before the return animation** — for
  `acceptDrops` draggables the draggable calls `onDragCancel` synchronously at release, before starting
  the return (UIMultiAnimDraggable.hx:668-677); the docs (ui-components.md:242, the `DropContext`
  docstring) and the built-in cell drag (:1368-1373) wait for the animation.
- [x] `UI-59` **P1** **Clicking an animated draggable without moving it throws** — the zero-distance
  guard is skipped on purpose when `animApplyScale`/`Alpha`/`Rotation` is set (UIMultiAnimDraggable.hx:
  359-364), and the built-in `setReturnAnimPath`/`setSnapAnimPath` factories then build
  `Stretch(from, from)`, which cannot become an AnimatedPath (`pathLength must be > 0`, a plain string
  thrown inside the event handler). `UIDraggableTest` works around it (:355-358). Root cause VFX-33.
  **FIXED 2026-09-28** (`8b734f0`): through VFX-33, no draggable change; the `UIDraggableTest` workaround is gone. `testClickWithoutMovingAnimatedDraggable*`.
- [ ] `UI-71` **P3** **A `CellSwap` handler that removes the source or target cell makes the swap throw** —
  `cellDragHandleSwap` calls `set()` on both cells right after emitting `CellSwap`; if the game's handler
  removed either, `getEntry` throws `Cell (c, r) does not exist`. The late rebuilds are guarded since
  `8b734f0` (UI-16); these synchronous sets are not. *Found 2026-09-28.* The external-draggable swap has
  the same hole: `handleSwapDrop` calls `sourceGrid.set`/`rebuildCell` synchronously (UIMultiAnimGrid.hx:
  2007-2035) and throws when the draggable's source cell was removed, or its grid disposed, before the
  drop. *(Widened 2026-09-29.)*
- [ ] `UI-74` **P3** **Work a completion starts during `dispose()` never runs** — `dispose()` drains a copy of
  `activeSwapAnims` (UIMultiAnimGrid.hx:1680), so a swap the game starts from a `ctx.onComplete` fired by
  that drain stays in the list and never completes; `pendingCellRemovals` has the same gap (older).
  Completions finishing in the same `update()` as the one that disposes still fire after `dispose()`.
  Drain until empty, or ignore new work once disposed. (The docs' "nothing calls back after `dispose()`"
  was reworded 2026-09-29.) *Found 2026-09-29.*

## UI — card hand and widgets

- [x] `UI-36` **P1** 🤖 **Card `status` visuals never change: the card hand drives its bindings with the
  wrong key** — cards are registered as `'<prefix>_<n>.card'` (UICardHandHelper.hx:842-849 →
  UIRichInteractiveHelper.hx:53/60) but all eight state calls pass the bare `'<prefix>_<n>'` (:491,
  :868, :882, :1048, :1060, :1088, :1362, :1570), and every lookup returns early on a miss (:169-187).
  So hover/pressed/disabled visuals of `bind => "status"` cards never apply, a disabled card's
  interactive stays enabled (its UIClick still reaches game code), and each discarded card leaks one
  binding holding its BuilderResult. The playground card-hand demo is affected (card-hand.manim:674,
  :722-730). Present since 2026-03-03. *Test: setHoveredEntry → status "hover"; setCardEnabled(false)
  → "disabled" and wrapper disabled; discard → binding gone.*
  **FIXED 2026-09-27** (`7d43afd`): each card keeps its binding ids (new
  `UIRichInteractiveHelper.getBindingIds(prefix, out)`) and every state call goes through them; discard
  uses `unregisterByPrefix`. The rebuild listener only marks the ids stale (a status change rebuilds the
  card from inside the loop). Five tests in `CardHandIntegrationTest`.
- [x] `UI-37` **P1** **A card drawn with `enabled: false` becomes playable** — `drawCard` overwrites the
  `Disabled` state `buildCardEntry` set with `Animating` (:364-365), and the animation end promotes it to
  `InHand` (:1565-1566). `setHand` keeps it disabled.
  **FIXED 2026-09-28** (`a128c22`): `CardEntry.disableAfterAnimation`; the card flies as `Animating` and lands `Disabled`. `CardHandIntegrationTest.testCardDrawnWithEnabledFalseStaysDisabledAfter*` and two guards.
- [x] `UI-43` **P1** **ScrollableList: a press on empty space arms a double-click on item 0 (HashLink)** —
  `lastClickIndex = newIndex` stores a `Null<Int>` into an `Int` field (:65, :317, :332); on HL null
  unboxes to 0 (verified with Haxe 4.3.6; JS keeps null). A press on the scrollbar or the empty tail
  followed by a press on item 0 fires `UIDoubleClickItem(0)`. *Fix: `newIndex ?? -1`.*
  **FIXED 2026-09-27** (`7d43afd`) as proposed.
  `UIComponentTest.testScrollableListEmptySpacePressDoesNotArmDoubleClick`.
- [ ] `UI-38` **P2** **Outside-click subscriptions made on `OnEnter` never register** — the controller
  sets its element context only for push/release events (UIDefaultController.hx:167-171) and
  `trackOutsideClick` returns without it (:53-55). The dropdown's only subscription is on `OnEnter`
  (UIMultiAnimDropdown.hx:200-205) and click-to-open never subscribes, so documented
  `closeOnOutsideClick` never fires (masked by the `autoCloseOnLeave` default);
  `testDropdownCloseOnOutsideClick` injects the event directly. The scrollable list has the same dead
  subscription (:351-352), so a row pressed and released outside stays "pressed".
- [ ] `UI-39` **P2** **`setCardEnabled(id, true)` on a hovered or dragged card corrupts its state** — the
  fallback branch forces `InHand` (:474-489), so `CardHoverEnd` is never emitted and z-order is never
  restored (:1045-1051); for a dragged card the layout stops skipping it and animates the card the
  player holds. `UISelectFromHandController.onDeactivate` (:97-102) triggers it.
- [ ] `UI-40` **P2** **Disabling a focused text input renders it enabled** — `blur()` synchronously
  fires `onFocusLost`, which writes `status = "normal"` after the `"disabled"` write
  (UIMultiAnimTextInput.hx:123-130, :223-236).
- [ ] `UI-41` **P2** **Tabs: a bar-wide disable/enable cycle re-enables per-item disabled tabs** —
  `set_disabled` writes `btn.disabled = value` (UIMultiAnimTabs.hx:200-207) instead of the
  `disabled || items[i].disabled` rule in `refreshDisabledState` (:416-420).
- [ ] `UI-42` **P2** **ScrollableList: disabled rows highlight on hover and are born "normal"** —
  `OnMouseMove` lacks the disabled gate `OnPush` has (:356-359 vs :320-321), and `buildItem` sets
  `status` from `baseStatus`/"normal" ignoring `disabled` (UIElementBuilder.hx:45).
- [ ] `UI-44` **P2** **Interactive events carry no mouse button: `UIClick` and `UIPush` fire for right and
  middle clicks** — `UIInteractiveWrapper` matches `OnPush(_)`/`OnRelease(_)` and drops the button
  (UIInteractiveWrapper.hx:121-129), so a game handling `UIClick` acts on a right-click, and
  `UIRichInteractiveHelper` shows "pressed" for any button (:234-238). The card hand works around it
  with a latch filled from the raw `onMouseClick`; a screen that forwards the release but not the push
  (a setup CHANGELOG rc.6 names as supported) turns a right press into a left drag that the right
  release cannot end. The runtime-systems.md card-hand API list omits `onMouseClick`, and the cookbook
  hex-grid snippet (:910-916) forwards only `onMouseMove`. Carrying the button in the event removes the
  latch.
- [ ] `UI-50` **P3** **Card hand: a stale target id reaches `canPlayCard` after card-to-card hover** — the
  card-to-card branch exits targeting without clearing `currentTargetId` (UICardHandHelper.hx:
  1193-1200), so leaving the card for a spot outside every zone calls `canPlayCard(id,
  TargetZone(staleId))` each frame with no arrow drawn.
- [ ] `UI-62` **P2** **Checkbox, tab, slider and dropdown lose their hover state after a click** — each widget
  hand-rolls the normal/hover/pressed machine and sets "normal" on release (UIMultiAnimCheckbox.hx:81-82,
  UIMultiAnimTabs.hx:101-103, UIMultiAnimSlider.hx:170-171, UIMultiAnimDropdown.hx:187-188) while the
  pointer is still over it; the controller re-sends `OnEnter` only when the hovered element changes, so
  the stock std.manim hover sprites disappear until the pointer leaves and returns. Button returns to
  "hover", `UIRichInteractiveHelper` to hover-if-entered-via-hover. One shared transition function would
  remove six copies.
- [ ] `UI-63` **P3** **The card hand's draw animation drops the path shape on a closed path** — the
  tracking draw lerps straight when the raw endpoint is at the origin (UICardHandHelper.hx:760-767),
  where `Path.applyStretch` (used by discard/return/rearrange) falls back to fit-centre
  (MultiAnimPaths.hx:503-533).
- [ ] `UI-70` **P2** **A card disabled mid-animation is laid out like a resting card** —
  `setCardEnabled(id, false)` during a draw, discard or rearrange sets `Disabled`, which
  `rearrangeCards`/`applyLayout` do not skip (they skip `Animating`): another draw or discard cuts its
  animation short and fires `DrawAnimComplete` early, and `applyLayout` snaps disabled cards instead of
  animating them. Drawn-disabled cards no longer take this path since `a128c22` (UI-37). *Found
  2026-09-28.*
- [ ] `UI-73` **P3** **A redundant `setCardEnabled(id, false)` during a disabled card's draw brings UI-70 back**
  — the `Animating` branch clears `disableAfterAnimation` and sets `Disabled` mid-flight
  (UICardHandHelper.hx:508), so the next `drawCard`'s rearrange replaces its draw animation and
  `DrawAnimComplete` fires early. Keep it `Animating` when it is already due to land disabled. *Found
  2026-09-29.*

## Builder (runtime `MultiAnimBuilder`)

- [ ] `BLD-13` **P1** 🤖 **`apply {}` inside a constant-count `repeatable` breaks incremental builds** —
  APPLY tracking ignores `suppressConditionalTracking` (MultiAnimBuilder.hx:6645-6663 vs :6726), so the
  post-build and every later conditional pass re-evaluate it with the loop variable unbound:
  `apply { alpha: 1 - $i * 0.3 }` throws `reference i does not exist` at build (the loop variable is
  reported as a missing parameter), and `@($i => 1) apply { scale: 2 }` is silently reverted.
- [ ] `BLD-14` **P1** 🤖 **Re-showing a conditional that contains a constant-count `repeatable` throws** —
  `addToGraph` replays every tracked expression under the re-shown subtree (:972-996), including
  per-iteration position closures that reference `$i` (:4664-4688); `setParameter("show", true)`
  throws `missing_ref` and the element can never be shown again.
- [ ] `BLD-15` **P1** **`center()`/`pivot()` and `align` are lost on `setParameter` and inside
  tilegroups** — the tracked BITMAP closure recomputes the offset from hAlign/vAlign only (:4477-4489),
  and its SolidColor fast path drops the align offset (:4468-4472); the tilegroup BITMAP case has the
  same omission (:5275-5291). The initial build honours `TSPivot` (:5659-5669). A centred bitmap jumps
  to its top-left anchor on the first update.
- [ ] `BLD-16` **P1** 🤖 **`==`/`!=` compare arithmetic operands as strings; builder and codegen disagree** —
  `resolveAsBool` compares `resolveAsString` of both sides (:3240-3243), which concatenates `+` and
  truncates `*`/`/` (:3535-3538); the ternary condition has no parentheses and `==` binds below `+`.
  `?($a == $b + 1)` with a=3, b=2 compares "3" with "21" → false; codegen compares numerically → true.
  The codegen comment claiming "same boolean result either way" (ProgrammableCodeGen.hx:7547-7553) is
  wrong for compound operands.
- [ ] `BLD-20` **P1** 🤖 **String parameters crash `${a + " " + b}` interpolation and `<`/`>` comparisons** —
  `resolveAsNumber` throws an un-coded error for a string/enum reference (:3363-3370) while string
  literals throw code `not_a_number` (:3355), and both fallbacks filter on that code (:3229-3235,
  :3518-3524). The message ("reference first is not a value but StringValue") sends an agent to fix a
  valid `.manim`.
- [ ] `BLD-22` **P1** **Incremental `pixels` jumps on the first `setParameter`** — the initial build adds
  the node position on top of the canvas offset (:6670-6675, :6808-6811); the redraw closure resets to
  the canvas offset only (:4532) and the position closure overwrites without it (:4681-4683).
  `pixels {...}: 100, 50` snaps to (0,0). The existing test uses position 0.
- [x] `BLD-25` **P1** **Inline 2D palettes are unusable** — `buildPalettes` drops the width of
  `palette(2d: N) {...}` (:7220-7221), so `palette(name, x, y)`, `replacePalette` and codegen's
  `getPaletteColor2D` all throw `palette is not 2d` (a plain string, no position) for a palette declared
  2D. Only a parse test covers the feature.
  **FIXED 2026-09-28** (`a128c22`): the width is passed; colours that do not fill whole rows are a positioned BuilderError. `BuilderUnitTest.testInline2dPalette*`.
- [ ] `BLD-26` **P1** **Tilegroups bake losing `@else`/`@default` arms in incremental builds** — inside
  `buildTileGroup` all children are returned unfiltered (:4047-4048) and every else/default arm counts
  as visible (:3985), so loop-variable chains that `validateTileGroupSubtree` explicitly allows bake the
  winning arm AND the losers. Every widget is built incrementally (UIElementBuilder.hx:83), and codegen
  delegates tilegroups to the builder, so both backends are affected.
- [x] `BLD-28` **P1** 🤖 **`range` with step 0 hangs the web playground; descending `to:` drops values** —
  the parser adds 1 to `to:` regardless of step sign and never rejects step 0 (MacroManimParser.hx:4175,
  :4178-4200); all count sites use `Math.ceil((end - start) / step)` unguarded (builder :5188, :6160,
  :6336, :6482; codegen :2338, :2529, :4009). Verified: `range(from: 5, to: 1, step: -1)` yields 5,4,3
  (docs: inclusive); step 0 is an infinite loop on JS and zero iterations on HL.
  **FIXED 2026-09-28** (`a128c22`): a literal step 0 is a parse error; a `$param` step 0 throws a BuilderError on both backends (`MultiAnimBuilder.rangeIterationCount`, shared with generated rebuilds); `to:` adds ±1 (one unit in the step's direction). Tests in `BuilderUnitTest` and `CodegenRepeatParamParityTest`.
- [ ] `BLD-17` **P2** **`?($flag == true)` is always false on both backends** — bool params are stored as
  1/0 and a bare `true` lowers to the string "true" (:1093-1094, MacroManimParser.hx:988-990). Only
  `?($flag)` works.
- [ ] `BLD-18` **P2** **A `$param` autotile index is never tracked** — `collectTileSourceParamRefs` skips
  `AutotileRef`/`AutotileRegionSheet` (:4330-4343), so `setParameter` is a silent no-op (not even an
  `untracked_param` error).
- [ ] `BLD-19` **P2** **Hide/show moves an unlayered element to the top layer** — `addToGraph` re-inserts
  with `Layers.addChildAt` (:962-970), which Heaps defines as "add to the topmost layer", so after one
  toggle the element renders above its `@layer(N)` siblings. Related: an element without `@layer` goes
  to "whatever layer is topmost so far" at build time, so declaration order decides; pin or document
  that rule with the fix.
- [ ] `BLD-21` **P2** **Indexing a `@final` array throws** — `resolveAsArrayElement` has no
  `ExpressionAlias` arm (:2943-2961) though `resolveAsArray` has one, so `$NAMES[$i]` fails while
  `array($NAMES)` works; the message prints the array name as "not an array".
- [ ] `BLD-23` **P2** **Tilegroup `pixels` lose their offset; fixture 14's reference image is wrong** —
  the tilegroup PIXELS case ignores `minX/minY` (:5384-5414). `test/examples/14-tileGroupDemo` (a 4px
  frame at -4,-4) renders 4px off and its reference image was generated from that output.
- [ ] `BLD-24` **P2** **Children of a top-level non-programmable root are built twice** — `startBuild`
  builds the root (which already builds its children) and then builds the children again (:7160,
  :7171-7176): doubled objects, interactives and names; with `#x[$i]` it throws a misleading
  `indexed_name_collision`. The documented `#hud point: …` form is affected.
- [ ] `BLD-27` **P2** **richText: `$param` style colours on reserved names and `$param` images never
  update** — the tracked closure defines tags under the raw name (:4426) while the converter emits
  escaped tags for b/i/u/s/bold/italic/font, and it installs the new image loader after the rebuild with
  a no-op `ht.text = ht.text` (:4435-4436; `Text.set_text` returns early on equal text).
- [ ] `BLD-30` **P2** **`$hex.edge(d)` on flat layouts returns the edge toward d+1** — `polygonEdge` and
  `outline()` pair corners d and d+1, correct only for pointy (Hex.hx:596-618). Decide with `DEC-1`: the
  fix changes the reference images of tests 1, 47 and 87.
- [ ] `BLD-29` **P3** **`rotate:` and `tint:` on tilegroup children are silently ignored** while `filter:`
  and `blendMode:` throw (:5405-5414).
- [ ] `BLD-31` **P3** **Builder and codegen transition code have drifted** — `CodegenTransitionHelper`
  duplicates the tracker and the five-kind executor of `IncrementalUpdateContext` (MultiAnimBuilder.hx:
  1221-1560). Differences: codegen's restore returns early for a reparented element and leaves it at
  alpha 0, the builder's removes it from any parent (CodegenTransitionHelper.hx:354-395 vs
  MultiAnimBuilder.hx:1469-1476); `cancelAllTransitions` is iterate-then-clear in one and drain in the
  other (unreachable re-entrancy today). Have the context own one shared runner.
- [ ] `BLD-33` **P2** 🤖 **`key:bool => $K` with `@final K = true` fails on both backends** — the builder's
  `resolveAsBool` sends the `@final` alias (`RVString("true")`) through `resolveAsInteger` (`expected
  integer, got "true"`); codegen inlines it as `"true" != 0`, a compile error. The parser's
  `validateTypedMetadataRef` accepts the form. The untyped literal `key => true` works since `a128c22`
  (CG-27). *Found 2026-09-28.*
- [ ] `DEC-9` **P2** 🤖 **Strict-D alpha is honoured inconsistently, and the docs contradict each other** —
  (a) `generated(color(…))` goes through `solidTile`, which treats a zero top byte as opaque
  (HeapsUtils.hx:20-24; MultiAnimBuilder.hx:3569, :4470; ProgrammableCodeGen.hx:7987), so `transparent`
  renders opaque black and a `$param` alpha animation snaps to opaque at 0. manim-reference.md:700
  documents that exception, but manim-language.md:18, manim-reference.md:732 and CHANGELOG rc.5 say
  `transparent` is reachable everywhere. (b) `graphics()` shapes ignore alpha entirely — Heaps
  `beginFill`/`lineStyle` read RGB only and the builder passes no alpha (:5046-5145) — so `#FF000080`
  draws opaque and codegen's ~20 `c |= 0xFF000000` bakes are dead code. (c) `text()`/`richText()` colour
  alpha is dropped because `h2d.Text.set_textColor` keeps the previous alpha (:5706, :5784). Decide the
  contract, then fix the leaves and the docs together.
- [x] `ERR-10` **P1** 🤖 **One failed load poisons the loader: every retry reports a bogus cyclic
  dependency** — `CachingResourceLoader.loadMultiAnim` pops its cycle-detection key only on success
  (ResourceLoader.hx:154-164). After a parse or build error, every later load of that file — codegen
  `create()`, `buildFromResource`, a `.manim` `import`, the next hot reload of an importing file —
  throws `cyclic dependency in multiAnim X` instead of the real error, until `rebuildAll` or a restart.
  This is the agent edit-fix-retry loop. *Fix: pop in a catch and rethrow.*
  **FIXED 2026-09-27** (`7d43afd`) as proposed. `BuilderUnitTest.testFailedMultiAnimLoadDoesNotPoisonRetry`.

## Codegen (`@:manim`)

Items CG-25, CG-27, CG-30, CG-31 were compiled; the scratch harness (six red hosts) is ready to drop into
`test/examples/152-codegenCompileErrors/hosts/`. One sweep of `rvToExpr(` calls that feed Int or String
sinks (use `rvToExprInt`, or `rvToExpr(x, true)` for strings) closes CG-25, CG-26, CG-30, CG-31 and CG-34.

- [ ] `CG-25` **P1** **Enum/number tile names and fractional tile indices do not compile** —
  `tileSourceToExpr` lowers sheet, name, file and index with plain `rvToExpr` (ProgrammableCodeGen.hx:
  7965-7978): `bitmap(icons, $kind)` with an enum → "Int should be String"; `bitmap(icons, frame, $i / 2)`
  → "Float should be Int". The builder resolves both.
- [ ] `CG-26` **P1** 🤖 **Enum parameters play animation "0"** — every stateanim string sink stringifies
  the enum's Int index (`Std.string(this._anim)`, :6124-6191, :5773, :8364) instead of its name; create()
  throws `unknown animation 0`, naming the index, so the agent searches the `.anim` file.
- [x] `CG-27` **P1** **Untyped `key => true` in settings or interactive metadata does not compile** —
  parsed as the string "true" with bool type, lowered as `RSVBool("true" != 0)` (:4284, :7951). The
  documented auto-inferred form breaks; typed `key:bool => true` compiles.
  **FIXED 2026-09-28** (`a128c22`): `ProgrammableCodeGen.settingBoolExpr` bakes the literal at both sites. Compile-check host `Cg27Host`; `CodegenIncrementalInteractiveStateanimTest.testUntypedBoolMetadataAndSettings_CodegenMatchesBuilder`.
- [ ] `CG-30` **P1** **`pixels` rect sizes from expressions do not compile; literal fractions round** —
  `var w:Int = <Float expr>` (:5972-5983); the static path uses `Math.round` where the builder truncates
  (:5889-5890 vs MultiAnimBuilder.hx:5011-5012).
- [ ] `CG-31` **P1** **Fractional palette and array indices do not compile** — `palette(pal, $n / 2)` and
  `$items[$n / 2]` lower with `rvToExpr` into Int sinks (:7614-7633); an out-of-range array index
  renders "null" where the builder throws.
- [x] `CG-32` **P1** **`getPath_x()` / `createAnimatedPath_x()` crash before the first `create()`** — the
  builder-fallback bodies call `getBuilder()` (ProgrammableBuilder.hx:538-552) but `_builder` is only
  set inside `create()`/`createFrom()` (CG :9170, :9218). Fallback is emitted for `close`, unresolvable
  coordinates, animatedPath without duration/speed and curve fallbacks. The docs show the standalone
  call. Raw null access, no BuilderError.
  **FIXED 2026-09-28** (`a128c22`): the generated fallback bodies call `ProgrammableBuilder.ensureBuilder(manimPath)` first. `AnimatedPathBuilderTest.testCodegenBuilderFallbackPathsWorkBeforeCreate`.
- [ ] `CG-28` **P2** **autoFit diverges from the builder** — codegen fits once at create (:6888-6890)
  and never on text updates (builder refits, MultiAnimBuilder.hx:4386-4391); with `maxWidth: grid` it
  passes `fitWidth = null` so the first fallback font always wins (:6844-6860; ProgrammableBuilder.hx:
  619-646); `scale: $param` is baked as 1.0. Residue of CG-23.
- [ ] `CG-29` **P2** **Wave segments with fractional counts end in the wrong place** — codegen omits the
  residual lateral offset the builder fix added (:10088-10095 vs MultiAnimPaths.hx:228-245), so the next
  segment's start and the Stretch endpoint differ.
- [ ] `CG-33` **P3** 🤖 **Codegen type errors point at library source, not at the `.manim`** — generated
  expressions carry the macro's own position, so every error above is reported at
  ProgrammableCodeGen.hx:7540/4284/5982 or `std/haxe/macro/MacroStringTools.hx:70`, never at the
  element or the `@:manim` field. *Fix: attach the node's parser position at the lowering entry points.*

**Runtime-built repeat bodies** (a `repeatable` whose count depends on a param, and `tiles()`/
`stateanim()`/array iterators) are the weakest part of codegen: CG-35, CG-37, CG-38 and CG-40 all live in
`processRuntimeRepeat` / `generateRuntimeChildExprs` (ProgrammableCodeGen.hx:3038-3680). Verified with
small HashLink programs that build the same programmable through both backends.

- [x] `CG-40` **P1** **A `point` inside a runtime-built repeat crashes `create()`** — the POINT arm declares
  `final _rt_obj` (:3224) and passes it as the container; any builder-forwarded child (interactive,
  staticRef, particles, slot, named element) declares its own `_rt_obj` and runs
  `_rt_obj.addChild(_rt_obj)` (:3678-3679) → "Recursive addChild". Fixture 65 only puts inline
  children in points.
  **FIXED 2026-09-27** (`7d43afd`): the forwarded local is `_rt_fwd`. Fixture 137 gains
  `pointForwardedChild`; `CodegenRepeatParamParityTest.testPointForwardedChild_*`.
- [ ] `CG-38` **P1** 🤖 **Forwarded children of runtime-built repeats are silently not built** — they are looked
  up by the macro parse's `uniqueNodeName` (:3668), which embeds `Std.string(node.type)`, and the eval
  and HashLink parses format structs and maps differently (verified side by side), so the lookup misses
  and `if (_rt_obj != null)` skips (:3679). Affected: interactives with metadata, particles, named
  text, stateanim with 2+ selectors, static/dynamicRef with 2+ params, parameterized slots. Fixture
  `67-interactiveMetadata` already loses its interactives in codegen; the visual test cannot see
  invisible interactives. *Fix: key by a parse-stable DFS ordinal, as `particlesNodeOrdinal` does.*
- [ ] `CG-37` **P1** **`tiles()`/`stateanim()` loop variables are not bound in runtime-built repeats** — only
  the index is mapped (:3038-3046); the documented `$tilename` variable fails to compile ("has no field
  _nm"), `bitmap(center($t))` silently loads `placeholder.png` (:8026-8033), and a named
  `#c[$i] bitmap($t)` throws "TileSource reference t not found" at runtime (MultiAnimBuilder.hx:3779).
- [ ] `CG-35` **P2** **Runtime-built repeat children lose non-offset positions and extended properties**
  *(extends CG-13)* — the inline arms honour only `x, y` offsets plus scale/rotation/alpha (:3148-3664):
  `$grid.pos`, hex, layout and `.offset()` positions land at 0,0, and `filter`, `tint`, `blendMode` and
  `@layer` are dropped (verified: builder 0/16/32 with outline, codegen 0/0/0 without). The PIXELS arm
  emits nothing at all when any coordinate uses the loop variable or a param (:3428-3505).
- [ ] `CG-34` **P2** **Fractional `interactive` sizes and `:int` metadata do not compile** — width, height
  and `key:int =>` go through `rvToExpr` (:4266-4284); even a plain float param fails.
- [ ] `CG-39` **P2** **Parameters named `scale`, `position`, `pb`, `parameter`, `root` … break the generated
  class** — setters `set<Param>` and fields `_<param>` collide with `h2d.Object` members or generated
  internals (:514-545, :971). `inc_game/res/manim/shipclass.manim:17` already declares `scale` and would
  break under `@:manim`. Reserve or mangle these names.
- [ ] `CG-36` **P3** **Dashed element names produce invalid Haxe field names** — `#health-bar`, `#my-slot`,
  `#cell-x[$i]` and a dashed `dynamicRef` target become `get_health-bar` etc. (:663, :1219, :1315, :2035);
  `sanitizeIdentifier` is used only for path/curve names. No shipped file uses a dashed element name
  (dashed programmable names are fine).
- [ ] `BLD-32` **P2** **`repeatable` inside a `flow` lays out differently in the three build modes** — the full
  builder gives the flow one child per iteration; the incremental builder wraps the whole repeat when a
  child conditional references a param (MultiAnimBuilder.hx:6209-6215) and codegen wraps a
  param-dependent count repeat (ProgrammableCodeGen.hx:2398, :2604-2608), so iterations stack at 0,0
  (verified: 3 / 1 / 1 visible children). Per-iteration children is the documented flow intent. The
  visual harness builds non-incrementally, so `test.bat` cannot see it.

## Parser and LSP

- [ ] `PRS-9` **P1** 🤖 **Mistyped colour literals silently become another colour** — `tryStringToColor`
  uses `Std.parseInt`, which stops at the first non-hex character, and only the length is checked
  (MacroManimParser.hx:1140-1147, :1198-1222). Verified: `#FFFFOO` → opaque cyan, `#FF00G0` → green,
  `0xFF_00FF00` → `0x000000FF`, `#FF0000ZZ` → transparent green.
  *Partly fixed 2026-09-27 (`7d43afd`, with PRS-18): hex colour literals strip `_`, so `0xFF_00FF00` is
  `0xFF00FF00`. The typo cases (`#FFFFOO`, `#FF00G0`, `#FF0000ZZ`) are still open.*
- [x] `PRS-10` **P1** 🤖 **`@(cond) @else` silently drops the condition** — `@else`/`@default` in the
  modifier chain lack the "stacked conditionals" guard the others have (:2997-3007 vs :2951-2963);
  `@(a=>2) @else bitmap(...)` becomes an unconditional else arm.
  **FIXED 2026-09-27** (`7d43afd`): both get the guard.
  `ParserErrorTest.testConditionalFollowedByElseOrDefaultRejected`.
- [ ] `PRS-14` **P1** 🤖 **A `$param` where a literal name is required is taken as that literal** —
  `expectIdentifierOrString` accepts a reference token (an interpolation concession) at every call site
  (:1559-1572): `layout($n)` looks up a layout named "n"; also `ninepatch($sheet, $tile, …)`,
  `palette($pal, 0)`, `@final $X = 1`. No error.
- [x] `PRS-16` **P1** 🤖 **`@any()` hides its element forever; `@()` is always true** — an empty condition
  list is accepted (parseConditionalParameters returns on `)`); builder and codegen evaluate empty
  any-mode as false (MultiAnimBuilder.hx:3941-3948, ProgrammableCodeGen.hx:7248).
  **FIXED 2026-09-27** (`7d43afd`): an empty list is a parse error (`@()`, `@if()`, `@all()`, `@any()`,
  and `@else()` too). `ParserErrorTest.testEmptyConditionalRejected`.
- [x] `PRS-18` **P1** 🤖 **Parameter defaults with `_` separators are truncated** — defaults skip the
  underscore strip that expressions get (:1884-1918 vs :606-609): `n:int=1_000` → 1, `f:float=1_000.5` →
  1.0, `c:color=0xFF_00FF00` → 255.
  **FIXED 2026-09-27** (`7d43afd`): the numeric default branches and `tryParseColor`'s hex branch strip
  `_`. `ParserErrorTest.testParameterDefaultsStripDigitSeparators`.
- [x] `PRS-19` **P1** 🤖 **The documented `subEmitters` syntax is rejected** — the object loop only eats
  `;` (:4881-4907), so the comma form in docs/manim.md:2325-2333 and manim-language.md:207 fails at the
  first comma. No `.manim` test uses sub-emitters.
  **FIXED 2026-09-27** (`7d43afd`): fields separate by `,` or `;`.
  `ParserErrorTest.testSubEmittersCommaSeparatedFieldsParse`.
- [x] `PRS-20` **P1** 🤖 **A malformed `bezier(` is silently dropped from its path** — `bezier`/`bezierAbs`
  handle only `)` and `,` after the first control point (:6008-6057); a missing `)` pushes nothing and
  parsing continues.
  **FIXED 2026-09-27** (`7d43afd`): `expect(TComma)` in place of the silent branch.
  `ParserErrorTest.testMalformedBezierRejected`.
- [ ] `PRS-24` **P1** 🤖 **`richText` with `[word]` and no `[/]` crashes the build** — the converter opens a
  tag for any `[identifier]` and never closes leftovers (TextMarkupConverter.hx:89-108); `hasMarkup()`
  has no consumer and style validation runs only when `styles:` exists. `"Press [A] to jump"` fails
  with Heaps' `Could not parse Press <A> to jump`, naming HTML the author never wrote. Codegen bakes the
  broken tag at macro time.
- [ ] `PRS-13` **P1** 🤖 **Method calls are rejected in the X coordinate but accepted in Y** *(extends
  VFX-17)* — `$ctx.random(0, 10), 0` → "$ctx.random is not a coordinate system"; `$grid.pos(1, 2).x, 0`
  → "Unknown coordinate suffix: .x"; the same expressions parse as Y (:1244-1314). Documented in
  manim-language.md:127-129.
- [ ] `PRS-21` **P2** 🤖 **`#name paths/curves/layouts {}` (documented) is invisible** — named blocks are
  registered under the user's name instead of the default node name (:5409-5413), so `animatedPath`
  fails with "requires a paths block to be defined before it" and `getPaths()` throws. Either support
  the name or reject it and fix manim-reference.md:15-18.
- [ ] `PRS-22` **P2** **`@flow.*` is silently dropped on shorthand shapes, `particles` and conditional
  blocks** — those cases `return` before the single `flowProperties` assignment (:3646-3651,
  :3942-3964, :4043-4048 vs :4055-4056). *(Conditional-block case: plausible.)*
- [x] `PRS-23` **P2** 🤖 **Comma-separated curve segments are rejected** — the documented form
  (manim-language.md:162) fails; only newline/`;` works (:6425-6475). One-line fix.
  **FIXED 2026-09-27** (`7d43afd`): `eatComma()` after each segment.
  `ParserErrorTest.testCommaSeparatedCurveSegmentsParse`.
- [ ] `PRS-11` **P2** **`uint` and range defaults are not bounds-checked** — `u:uint=-1`, `r:1..5=9`
  accepted (:1912-1915).
- [ ] `PRS-12` **P2** 🤖 **`$ctx.width-10` lexes as one identifier** — `-` is allowed inside identifiers
  (:425) because real asset names use it (`peaberry-white-outline`), so unspaced minus after a property
  fails at build with "not a known context property". Scope the fix (e.g. `-` before a digit), do not
  drop `-`.
- [ ] `ERR-9` **P2** 🤖 **Semantic errors are reported at the next token** — `error()` uses `peekToken()`
  after the offending token was consumed (:574-577 with :693-694, :1754, :1911): an unknown `$missing`
  at the end of a line is reported on the next line, in the next element. LSP squiggles and hot-reload
  error positions land on the wrong element.
- [ ] `LSP-6` **P2** 🤖 **Lexer errors appear at line 0 in the LSP** *(extends ERR-2/ERR-3)* — plain-string
  throws reach `ManimAnalyzer`'s catch-all, which pins them to 0:0 (lsp/src/manim/lsp/ManimAnalyzer.hx:
  44-50). A stray character on line 4 is reported on line 1.
- [ ] `PRS-15` **P3** **Duplicate `@final K` in one scope is accepted** — last one wins (:3075-3081).
- [ ] `PRS-17` **P3** **`#n[$K]` with a `@final` index outside a repeatable is accepted** — scope check
  treats finals as loop variables (:3155-3158, :3078).
- [ ] `PRS-25` **P3** **`.manim` and `.anim` string escapes differ** — `.manim` handles `\"`, `\\`, `\n`;
  `.anim` handles only `\"` and `\uXXXX`, so `\n` and `\\` stay literal there and `\\` before a closing
  quote swallows the quote (MacroManimParser.hx:240-247, :273-280; AnimParser.hx:328-336). A lone `\r`
  is a newline in `.anim` but not in `.manim`'s line counter. (A UTF-8 BOM parses in both; add a test.)
- [ ] `LSP-7` **P3** 🤖 **Keyword table drift** — `AUTOTILE` and `PARTICLES` are offered as child elements
  only (parser: autotile root-only, particles root allowed), path commands lack the `*Abs` variants, and
  the LSP completion hard-codes `rotation:` (parser: `rotate:`) (ManimKeywordInfo.hx:90-101, :293-332;
  CompletionProvider.hx:62).
- [x] `DOC-26` **P2** 🤖 **The card-hand `paths {}` snippet in the auto-loaded rules file does not parse** —
  `.claude/rules/runtime-systems.md:23-26` uses `#cardArc lineTo(…), bezier(…)` without `path { }`;
  agents copy it verbatim. Correct form: docs/manim.md:1594.
  **FIXED 2026-09-27** (`7d43afd`). The snippet had four more defects: comma-separated `animatedPath`
  properties on one line (only one per line parses), a `graphics(color, width) { line(…) }` form that
  does not exist, an `interactive` without a position, and a conditional bare `filter:` (needs
  `apply { filter: … }`). Rewritten; `#handShape` also no longer ends at its start point. The same
  broken snippet in the `UICardHandHelper` class doc and the FloatingTextHelper example (same
  one-line `animatedPath`) were fixed too. `ParserErrorTest.testCardHandSetupSnippetParses` /
  `testFloatingTextSnippetParses` hold copies of the two rules-file examples.

## Base runtime — tweens, particles, paths

- [x] `VFX-20` **P1** **A burst-driven (`count: 0`) particle emitter disappears after its first burst** —
  `onEnd()` (default `remove()`) fires as soon as every batch is empty after any emission
  (Particles.hx:1602-1620), so the documented per-shot trail emitter renders nothing from the second
  shot on. Looping groups are unaffected (burst particles recycle). `onEnd` also has no one-shot latch:
  a no-op override is called every frame while idle.
  **FIXED 2026-09-28** (`a128c22`): a container ends only when some group has `nparts > 0` or was shut down, and `onEnd` fires once per live-to-empty transition. `ParticleRuntimeTest` (four tests).
- [ ] `VFX-19` **P2** **`fadeOut(..., removeOnComplete)` + `clear()` in its callback removes the wrong
  object** — `runCompletionHooks` reads `target`/`removeTargetOnComplete` after the callback
  (TweenManager.hx:235-241); `clear()` returns this tween to the pool and a tween started in the same
  callback reuses it, so the new target is removed and the old one leaks.
- [ ] `VFX-25` **P2** **`clear()` in a sequence member's callback still fires the sequence's onComplete** —
  `releaseTweens` empties the sequence, `step()` then reports done (:386-394) and `update()` fires the
  callback before its clear check (:508-529). Fix: `seq.step(dt) && !seq.cancelled` (also fixes the
  UI-15 cancel variant).
- [x] `VFX-23` **P2** **A zero-duration tween inside a `group()` is never applied** — `TweenGroup.step`
  only steps `elapsed < duration` (:452-468), so the member never snaps and `removeOnComplete` never
  runs, yet the group completes.
  **FIXED 2026-10-05**: `Tween.completed` (set by a finishing step or `finish()`, reset as the pool reuses it); the group steps every member not completed. `TweenManagerTest.testAZeroDurationTweenInAGroupReachesItsEnd`.
- [ ] `VFX-21` **P2** **Externally driven particles fast-forward while hidden** — the accumulated dt is
  consumed every sync but reset only in `draw()` (:169-172, :1664-1665); Heaps syncs invisible objects,
  so 60 hidden frames simulate ~30 s.
- [ ] `VFX-22` **P2** **`colorStops` with back/elastic easings produce garbage colours** — `lerpColor`
  packs unclamped channels (:1135-1146): black→white with `easeInBack` renders white for 63% of the
  segment.
- [x] `VFX-24` **P2** **A burst before the first frame suppresses a looping group's continuous particles** —
  `emitBurstAt` sets `started` without calling `start()` (:843-849), and `start()` is the only place
  `count` particles are created.
  **FIXED 2026-10-05**: a burst into a `count > 0` group not started yet starts it first (a switched-off one is left for `sync()` to start once on); burst-only groups as before. `ParticleRuntimeTest.testABurstBeforeTheFirstSyncLeavesTheEmitterItsOwnCount`, `testADisabledGroupHitByABurstStartsWhenEnabled`.
- [ ] `VFX-18` **P2** **FloatingTextHelper paints the text white until the first colour stop** —
  regression from 963a2a5: with a color curve starting after rate 0.0 the spawn colour is overwritten by
  the path's default white (FloatingTextHelper.hx:124-127, AnimatedPath.hx:447-454). Particles hold the
  first stop's colour instead; making AnimatedPath do the same fixes both.
- [ ] `VFX-26` **P3** **`emit: point(dist: D)` spawns at 0..√2·D with diagonal-biased density** —
  un-normalised square vector used for offset (Particles.hx:948-956; inherited from Heaps).
- [ ] `API-10` **P3** **Small base-type math bugs with no in-tree callers** — `Palette.getColorByIndexWraparound(-n)`
  reads past the end (Palette.hx:20-23); `GridDirection.turnRight(-1)` yields -1 (:169-171);
  `getRelativeDirection` collapses ±k (:150-160); `HexLayout.directionToAngle` returns the corner
  bearing (Hex.hx:555-562); `PositionLinkObject.linkVisibility` latches the link's own `visible` false
  and never touches the destination (dead flag, :31-36).
- [ ] `API-11` **P3** **`TweenManager.cancel`, `finish` and `setOnComplete` on a kept `Tween` act on whatever
  reuses it** — `cancel(t)` is a plain pass-through (TweenManager.hx:569-571) and pooled tweens are
  handed out again; the docs warn for `cancel()` (runtime-systems.md:187) but the Core API example
  (:172) lists `mgr.cancel(tween)` without the caveat, and nothing warns that `setOnComplete` on a stale
  reference silently replaces the new owner's callback. API-8 fixed this only for internal users; a
  generation-checked handle returned by `tween()` would close it for game code.
- [ ] `VFX-27` **P2** 🤖 **An `.anim` animation with no frames crashes on `play()` when it loops** — the
  parser accepts `playlist { }`, `frames: a..b` beyond the sheet and a reversed `frames: 3..1`
  (AnimParser.hx:1549-1552, :1622-1633, :2117-2121; only an empty playlist *list* is rejected, :1459);
  `play()` then switches on `states[0] == null` (AnimationSM.hx:224-243) and throws "Null access", which
  names nothing. With `loop: no` it silently draws nothing.
- [ ] `VFX-28` **P2** 🤖 **`.anim` metadata conditionals are never validated, so typos match everything** —
  `parseMetadata` skips the state-name/value/comparison checks every other block gets (AnimParser.hx:
  1349-1378; post-parse loop :1033-1045), so `@(lvl => 3) damage: 50` under `states: level(...)` scores
  0 like the `@else` arm and wins every tie (:487-525). DOC-19 lists this as doc-only; it returns wrong
  values.
- [ ] `VFX-31` **P2** **`AnimatedPath.reset()` from a `pathEnd`/`cycleEnd` handler is overwritten** —
  `update()` writes `isDone = true`, `cycleCount++`, `time -= duration` and the pingPong flip after
  calling the handlers (AnimatedPath.hx:323-333, :361-363), so restart-on-end leaves the path dead and
  a cycleEnd reset starts the next cycle at negative time. `AnimationSM` guards this with `playCount`.
- [ ] `VFX-32` **P2** 🤖 **Flipped stateanim frames report shifted bounds** — `getBoundsRec` reconstructs the
  footprint assuming unflipped offsets (AnimationClip.hx:186-187), so with asymmetric atlas trim a
  `flipX`/`flipY` frame's bounds are off by up to a frame width (verified: footprint -16..16 reported as
  2..34). Flow layout and DevBridge `inspect_element`/`find_element_at`/`check_overlaps` see the wrong
  box.
- [ ] `VFX-36` **P2** **A `speedCurve` that starts at 0 freezes a distance-mode path forever** — the speed
  multiplier is evaluated at the current rate before advancing (AnimatedPath.hx:268-275), so any
  `easeIn*` speed curve gives speed 0 at rate 0 and the object never leaves the start (verified).
- [ ] `VFX-29` **P3** **pingPong fires an endpoint event twice per turnaround** *(needs a semantics
  decision)* — an event at rate 1.0 (or 0.0) fires at the end of one leg and again at the start of the
  reversed leg (:304-333). The CHANGELOG says "once per pass", the existing test says "once per cycle".
- [ ] `VFX-30` **P3** **`.anim` colours read as strings come back as `#AARRGGBB`** — regression from the
  rc.6 alpha baking: `'#' + StringTools.hex(c, 6)` no longer strips alpha (AnimParser.hx:585, :597,
  :2136), so `#FF0000` metadata or event meta reads `#FFFF0000`, which re-parses as transparent yellow.
- [x] `VFX-33` **P3** **Zero-length paths produce NaN or "rate out of range"** — ranges are divided by
  `totalLength` with no zero guard (MultiAnimPaths.hx:302-306): `Stretch(p, p)` makes every `getPoint`
  throw `rate out of range: 0.5`, and a leading zero-length segment (`lineTo(0, 0)` first) gives a NaN
  start position. `UICardHandTargeting` has no distance guard (:275).
  **FIXED 2026-09-28** (`8b734f0`): a zero-length path spans 0..1 on every segment, lookups skip zero-width segments (`covers`/`localRate`), distance mode finishes at once; a path with no segments still throws. Tests in `AnimatedPathTest`, `AnimatedPathBuilderTest`.
  Remaining (pre-push review 2026-09-29, P3): a looping or pingPong distance-mode path over a zero-length
  path runs a full cycle and all its events every update, checkpoint events all fire on the first update,
  a NaN `totalLength` takes the zero-length branch silently, and nothing tests the targeting arrow with
  the cursor on its origin.
- [ ] `VFX-37` **P2** 🤖 **Normalized paths lose their checkpoints** — `Path.applyTransform` builds the new
  path from `singlePaths`, which the constructor already stripped of checkpoints, and the new path gets an
  empty `checkpoints` map (MultiAnimPaths.hx:597). Any checkpoint-keyed curve or event on an
  `animatedPath` created with a normalization — `Stretch`, `createProjectilePath`, which the draggable,
  grid and card hand always use — throws `checkpoint not found` on both backends (MultiAnimBuilder.hx:
  7760, ProgrammableCodeGen ~10295). Pre-existing; untested. Copy `checkpoints` into the transformed path
  (uniform transforms keep rates). *Found 2026-09-29.*
- [ ] `VFX-34` **P3** **Unsorted curve `points:` are used as written** — `Curve.getValue` assumes time
  order (Curve.hx:36-37) and nothing sorts or validates; points can be `$refs`, so sort at build time.
- [ ] `VFX-35` **P3** **`AnimatedPath.update(0)` before the first real step returns the constructor
  default state** — position (0,0) (:250-251), which `FloatingTextHelper` applies, so an
  `absolutePosition` spawn flashes at world (0,0) on a paused or first frame.

## DevBridge, hot reload, MCP transport

- [x] `HR-2` **P1** 🤖 **Hot reload skips screens that share a `.manim`, and reports success** —
  `hotReloadFile` iterates the live `screenSourceMap` list while `clearScreenFromSourceMap` removes from
  it and `load()` appends to it (ScreenManager.hx:1457-1487, :1710-1716): with two screens on one file
  the first reloads twice and the second never does; the report says success.
  **FIXED 2026-09-27**: the list is copied before reloading. Fixing HR-3 exposed a second cause: a
  screen was recorded in `screenSourceMap` only on a builder cache miss, so the second screen sharing a
  file was never recorded; every loading screen is recorded now, cached or not.
  `HotReloadTest.testHotReloadReloadsEveryScreenThatSharesTheFile`.
- [x] `HR-3` **P2** **`buildFromResourceName` never hits the builder cache** — `builders` is keyed by
  resource identity but `hxd.Res.load` returns a fresh object per call (:87, :227-229, :308-317): every
  call re-parses, adds a map entry and another file watch, and reload rebuilds every duplicate. Root
  cause of HR-2's guaranteed cache miss.
  **FIXED 2026-09-27**: `builders` keeps resource keys (DevBridge and tests read them) but holds one
  entry per file path and is matched by path (`loadedResource`); `hotReload(resource)` and
  `reload(resource)` compare paths. `HotReloadTest.testBuildFromResourceNameKeepsOneEntryPerFile`.
- [ ] `DEV-1` **P2** 🤖 **A request that times out (408) can still execute** — the timeout path answers 408
  but leaves the connection's data handler armed until the delayed close (HttpServerTransport.hx:
  301-316, :353-359); bytes that complete the request in that window are dispatched and answered with a
  second response. The MCP client sees an error while `set_parameter`/`send_event`/`quit` ran; a retry
  runs it twice. Gap left by 963a2a5's "one request per connection" rule.
- [x] `HR-6` **P1** 🤖 **Every screen switch drops that screen's programmables from hot reload and DevBridge** —
  `ReloadSentinel` unregisters in `onRemove` (HotReload.hx:141-144), which Heaps fires on any removal
  from the scene, and nothing re-registers when the object comes back. Screens are loaded once and their
  roots are removed and re-added on every switch (ScreenManager.hx:554-558), so after A → B → A every
  programmable on A is missing from `list_active_programmables`, and `set_parameter`/`inspect_programmable`
  answer 404 — or hit another instance with the same name and report ok. Also hit: dialog-over-dialog
  revival and slot contents during a parent's reload. Tests miss it because their roots are never
  added to a scene (HotReloadTest:1112).
  **FIXED 2026-09-27**: the sentinel detaches the handle on `onRemove` and attaches it again on `onAdd`;
  `unregister` marks the handle disposed so a discarded result never comes back. Note for tests: the
  test app's s2d is allocated only after its first render, later than the unit tests run, so adding a
  root to s2d does not fire onAdd/onRemove there — `HotReloadTest.allocatedStage()` stands in.
  `testResultBackInSceneIsReloadableAgain`, `testExplicitlyUnregisteredHandleStaysGoneWhenItsObjectIsAddedAgain`.
- [x] `HR-5` **P1** 🤖 **An in-place hot reload tears down the live result before it has a replacement** —
  for a file not loaded by a screen, `hotReloadFile` swaps the builder and hash, empties the slots,
  removes the sentinel and unregisters the handle (ScreenManager.hx:1446-1450, :1546-1550), then builds
  and calls `StateRestorer.restore` outside any try (:1576). `restoreParams` calls `setParameter` for
  every param (HotReload.hx:327-331), which throws `untracked_param` for any param used in an interactive
  id, a stateanim selector or a param-dependent repeat body. Result: a 500 with no terminal SSE event, a
  stale on-screen result with its slot contents gone, a registered ghost, and a later reload of the same
  text answering success with nothing rebuilt. A build error leaves the same half-torn state.
  **FIXED 2026-09-27** (with HR-4): build + `restoreState` first (params the rebuild already holds are
  skipped, so `untracked_param` is never raised for them), the live result untouched until that
  succeeded; on failure borrowed placeholders go back and the file hash is invalidated so the same text
  retries; slot contents move last. `testFailedInPlaceReloadLeavesTheLiveResultIntact`,
  `testInPlaceReloadKeepsParamUsedInInteractiveId`.
- [x] `HR-4` **P2** 🤖 **After an in-place hot reload, updates go to the discarded root** — the adopted
  incremental context still records the discarded root as the parent of top-level conditional and
  deferred entries (MultiAnimBuilder.hx:6826, :5561, :2250; ScreenManager.hx:1587-1593), so hiding works
  but showing re-adds the element under the dead root. Root-level `alpha:`/`scale:`/`rotate:`/`filter:`
  `$param` tracking writes to the dead root too (`set_parameter` reports success, nothing changes), and
  editing a literal root alpha/scale has no effect. `adoptFrom` also drops the rebuild listeners
  (autoStatus resync, card resync) (:2236-2257), and `SceneSwapper` copies the root filter only when the
  new build has one, so removing a root `filter:` keeps the old filter (HotReload.hx:496-499).
  **FIXED 2026-09-27**: instead of re-pointing the adopted context at the stable root (closures capture
  the build's root), the rebuilt root is nested inside the stable `result.object` whole
  (`SceneSwapper.nest`), so everything the new context references is live; on the first reload the root
  properties the original build set on the stable object (`devBuilderRootProps`) are reset there.
  `adoptFrom` moves the rebuild listeners and the reload fires them once. `@layer` order, lost by the
  old child move, is kept too. `testReshownElementAfterInPlaceReloadIsOnScreen`,
  `testRootParamAfterInPlaceReloadReachesTheScreen`, `testLiteralRootEditsApplyOnInPlaceReload`,
  `testRebuildListenersSurviveInPlaceReload`.
- [x] `DEV-2` **P1** 🤖 **`reload {file}` on HashLink reloads nothing and reports success** — the handler builds a
  fresh resource with `hxd.Res.load(file)` (DevBridge.hx:828) and `hotReload` compares it by reference
  with the `builders` keys (ScreenManager.hx:1307), so nothing matches and the reply is
  `{success: true, file: "", rebuiltCount: 0}`. This is the usage the MCP tool advertises for HashLink.
  Same root cause as HR-3. *Test: reload {file:"grid-demo.manim"} → `r.file` names the file.*
  **FIXED 2026-09-27** with HR-3 (matched by path); a `file` nothing loaded now answers `not_found`
  listing the loaded paths. `HotReloadTest.testDevBridgeReloadByFileReloadsThatFile`.
- [x] `DEV-3` **P1** 🤖 **Every `eval_manim` leaves a permanent ghost registration** — the eval build
  registers a reload handle (MultiAnimBuilder.hx:8399-8403, not gated on incremental) and
  `result.object.remove()` is a no-op for a root with no parent, so the sentinel never fires
  (DevBridge.hx:903-919). `list_active_programmables` grows by one per eval, and when the eval'd name
  matches a live programmable, `set_parameter` can hit the ghost (500 "requires incremental mode") and
  `inspect_programmable`/`list_slots` return the ghost's empty data with ok:true.
  **FIXED 2026-09-27**: each eval build's handle is unregistered. `HotReloadTest.testEvalManimLeavesNoRegisteredResult`.
- [ ] `DEV-7` **P2** 🤖 **`send_event` clicks land somewhere else under any zoom** — x,y are fed to the window
  as physical pixels (DevBridge.hx:958-982), which the scene maps through offset and viewport scale,
  while the MCP schema calls them "scene coordinates" and `find_element_at`/`coordinate_transform`/
  `check_overlaps` work in scene space. Under `AutoZoom` with zoom ≥ 2 — the game-template and
  proto-game setting — a click computed from inspection output misses, and the op still returns
  success. Screenshot pixels do match.
- [ ] `DEV-9` **P2** 🤖 **`list_interactives` and `find_element_at` report parent-local positions** — an
  interactive's `x,y` is its local position with no size (DevBridge.hx:1348-1349, :2174-2175), mixed in
  the same array with scene-space button bounds (:1375-1381). Clicking at the listed position misses
  unless every ancestor sits at the origin.
- [ ] `DEV-4` **P2** 🤖 **Event cursors skip the oldest unread entries** — with `since_id`, `get_game_events`
  and `get_debugger_hits` keep the newest `limit` entries but return the buffer's newest id as `lastId`
  (DevBridge.hx:1174-1180, :1245-1251), so a client following the documented cursor never sees the rest
  and nothing says entries were skipped.
- [ ] `DEV-10` **P2** 🤖 **`get_parameters` is empty for `.manim` files in subdirectories** —
  `findBuilderForHandle` compares the resource basename with the full source path (DevBridge.hx:
  2147-2152), so `ui/menu.manim` never matches and parameter definitions come back `[]` with ok:true.
- [ ] `DEV-5` **P2** 🤖 **Large responses can be truncated** *(plausible)* — `sendResponse` queues asynchronous
  writes and closes the socket 50 ms later without waiting for them (HttpServerTransport.hx:354-359;
  Heaps writes are async, and libuv/Winsock cancel pending writes on close). A multi-MB screenshot over
  LAN, VPN or WSL arrives shorter than its Content-Length. Settle with a loopback test that delays
  reading.
- [ ] `DEV-6` **P3** **Non-ASCII or NUL header bytes break request framing** — header bytes are decoded to a
  string and string indices are used as byte offsets (HttpServerTransport.hx:422-454): a non-ASCII
  header shifts the body start (400 Invalid JSON), a NUL truncates the decoded headers (408 after 30 s).
  Reachable with a non-ASCII token or Origin.
- [ ] `DEV-8` **P3** **Unauthenticated connections are uncapped** — each pending connection allocates 64 KB
  and may buffer 16 MB before the token is checked, and a slow-drip client keeps its slot forever
  (HttpServerTransport.hx:200-233, :394, :411). SSE clients are authenticated but also uncapped, and a
  client that stops reading makes every event copy queue without bound.

## Performance (new; existing PERF items above)

- [ ] `PERF-15` ⚡ **Scroll screens re-measure all content every frame** — `getBounds` + full subtree walk
  per frame while auto-measure is on, idle included (UIScrollableScreen.hx:61-75, UIScrollHelper.hx:
  58-60, :113-115). Reuse a Bounds and measure on a dirty flag.
- [ ] `PERF-16` ⚡ **`UIPanelHelper` iterates its named-panel map every frame and every event** — 3 heap
  allocations per frame per helper on HL even with no named panels (UIPanelHelper.hx:394, :425-431).
  The next block in `UIScreen.update` already got the flag gate.
- [ ] `PERF-17` ⚡ **Cell drag allocates per mouse move** — `cellDragFindTarget` allocates a `CellCoord`
  per hit grid plus a struct per tick (UIMultiAnimGrid.hx:1169-1188) though `cellAtPointInto` exists
  and the hover path uses it.
- [ ] `PERF-18` ⚡ **`PositionLinkObject` allocates a Point per position update** (PositionLinkObject.hx:22);
  only on frames the dropdown or an ancestor moves.
- [ ] `TST-9` **`AllocationSmokeTest` exercises none of the hot paths above** — no controller dispatch, no
  `setParameter`, no scroll screen, no panel helper, no drag, no arrow/rearrange path; it calls
  `cellAtPoint` per tick without asserting `CellCoord`. Extend it once PERF-15..18 are fixed.

---

## Fix clusters — one change closes several items

- ~~**Interactive wrapper identity**, **Reload registration**, **In-place reload as a transaction**~~ —
  done 2026-09-27 (see the items).
- **`rvToExpr` into typed sinks** — use `rvToExprInt` / `rvToExpr(x, true)` wherever the callee takes an
  Int or String: `CG-25`, `CG-26`, `CG-30`, `CG-31`, `CG-34`; attach node positions for `CG-33`.
- **Parser early returns** — one `flowProperties` attachment point reached by every `return`, and
  unknown-property rejection: `ERR-5`, `PRS-22` (the separator half, `PRS-19`/`PRS-23`, is done).
- **`Tween` handles** — return a generation-checked handle from `tween()` and snapshot fields before
  callbacks: `API-11`, `VFX-19`, `VFX-25`, `UI-15` (sequence part).
- ~~**Callbacks during iteration**, **Zero-length paths**~~ — done 2026-09-28 (`8b734f0`, see the items).
- **Strict-D alpha** — decide the contract once (`DEC-9`), then fix `solidTile`, graphics and text leaves
  and the docs together.

## Test-coverage gaps these items expose

- The visual harness builds only non-incremental builder output (VisualTestBase.hx:135), and codegen
  delegates tilegroups to the builder, so incremental-only divergences (`BLD-26`, `BLD-23`) and
  incremental-vs-codegen differences are invisible to `test.bat`.
- Hot-reload tests never added their roots to a scene, which is why `HR-6` went unnoticed
  (HotReloadTest:1112). The test app's s2d is allocated only after its first render, so even adding a
  root to s2d fires no onAdd/onRemove in unit tests; `HotReloadTest.allocatedStage()` is the stand-in
  (used by the 2026-09-27 reload tests; older tests still do not attach).
- ~~No test drives interactives through a real screen after a rebuild while checking object identity~~ —
  `UIScreenInteractiveSyncTest` (2026-09-27).
- No `.manim` test parses a named `paths {}` block or reaches a sub-directory `.manim` through DevBridge
  (`subEmitters` and comma-separated curve segments are covered since `7d43afd`).
