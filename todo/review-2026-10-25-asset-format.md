# Review — 2026-10-25: inconsistencies, bugs and design (asset-format pass)

Scope: `src/`, `lsp/`, `docs/` at `origin/dev` `98105cc`, reviewed in the worktree
`.claude/worktrees/review-asset-format-2026-10-25`, with an eye on the plan to make programmables
the export/import asset format (the design is in
[proposal-programmable-asset-format.md](proposal-programmable-asset-format.md)). Imports, loading
and registries were traced by hand; parser/LSP/docs, builder/codegen/needs, `.anim`, the widget
contracts and the last five commits each had a finder pass that traced every item it reports to the
code (parser items with eval/HashLink/JS parse probes, some codegen items with compile probes), and
every P1 was traced again before it went in. No test suite was run. Items are **CONFIRMED** (traced
end to end or reproduced), "traced" (both sides read, not run) or *plausible* (the path is there,
the trigger was not run).

**Legend** as in `release-1.0-audit.md`: `[ ]` open, **P1** fix before 1.0, **P2** should fix,
**P3** acceptable post-1.0. IDs continue the sequences of `release-1.0-audit.md` and
`review-2026-09-26-whole-code.md`; new prefix `IMP` = imports, loading and registered names.
File:line references are for `98105cc`. To review one item: `/bug-review todo/review-2026-10-25-asset-format.md IMP-1`.

**101 new items: 9 P1, 43 P2, 49 P3**, plus CG-38 found still open and wider.

**Status 2026-10-25:** the nine P1s are fixed (ticked below), each with a test that failed first:
`CgRootApplyHost` (152 harness), `EventPriorityTest.testAWidgetDisabledWhileItHoldsTheMouseLetsItGo`,
`ScreenManagerDialogTransitionTest.testAnOkCancelDialogAnswersAKeyGoingDownNotItsRelease`,
`AnimParserTest.testAFlippedAnimationsPointEventIsMirroredAsItsExtraPoint`,
`AudioScreenTest.testAHeldSoundWaitsForTheSpriteToBeInTheScene` and
`testAnExtraPointOfAnAnimFilePlaysNoneOfItsSounds`, `ParserErrorTest.testAnIntegerLiteralPastThirtyTwoBitsIsAnError`
and the LSP suite's `testIntegerLiteralsAreThirtyTwoBits`,
`CursorTest.testAnImportedFilesCursorsAndSoundsAreTakenAsItsImporterLoads`,
`BuilderUnitTest.testARefsArgumentsResolveInTheBuildThatWritesThem`,
`StaticRefIncrementalTest.testCodegen_ImportedProgrammableOfTheWrappersNameIsNoCycle`. None duplicates an open
or fixed item of the two earlier lists; where one extends a filed item it says so.

## Start here

**The nine P1s.**

| ID | What | Area |
|---|---|---|
| `CG-48` | Codegen does not compile a root `apply` over a `$param` root property (regression in `cdb83e5`) | codegen |
| `UI-75` | Disabling a widget mid-drag freezes the screen's input | widgets |
| `UI-76` | `OkCancelDialog` closes itself on the key release that opened it | widgets |
| `ANM-13` | Point events are not mirrored by `flipX`/`flipY` | `.anim` |
| `ANM-14` | Held and event sounds start on machines that are not in the scene (`extraPoint("x.anim", …)` lookups too) | `.anim` |
| `PRS-26` | Integer literals parse differently on JS (`0xFFFF0000`) | parser |
| `IMP-1` | An imported file's cursors, sound banks and music are never registered | loading |
| `BLD-34` | A ref's arguments are resolved in the target's builder with its state emptied | builder |
| `CG-41` | Codegen's cycle guard mixes files: a wrapper `#knight` placing an import's `knight` is "circular" | codegen |

**What blocks programmables as an exchange format** (the proposal's section 4 orders the fixes):
IMP-1, IMP-2 (`.anim` read from another root), IMP-3/IMP-5 (import aliases unchecked), IMP-6 (`$name`
changes meaning in an importer), IMP-7/IMP-8 (global, colliding names), IMP-9 (hot reload ignores
imports), BLD-34, BLD-35, CG-41, CG-42 (refs across files), IMP-12/IMP-13/IMP-15 and CG-43 (needs per
export are not reliable), PRS-26, PRS-31, PRS-32, CG-38 (a reader's answers depend on the target and
miss positions), ANM-17, ANM-18, ANM-19 (a figure's interface from `.anim`), UI-85, UI-86, UI-91 (widget
contracts cannot be declared as they stand).

**Agent-facing (🤖)**: IMP-3, IMP-5, PRS-27, PRS-31, PRS-32, PRS-38, ANM-21, ANM-22, UI-82, UI-86, BLD-37,
CG-46 — errors that point at the wrong cause or files the tools accept and the build refuses.

---

## Imports, loading and registered names

- [x] `IMP-1` **P1** **An imported file's `cursor`, `sounds` and `music` blocks are never registered**
  — CONFIRMED. `ScreenManager.buildFromResource` calls `built.registerCursors()` and
  `audio.addBanks(built)` on the file it loads (ScreenManager.hx:563-568), and `hotReloadFile` does
  the same on reload (:1824-1825); both read only `multiParserResult.nodes` of that one builder
  (`MultiAnimBuilder.registerCursors` :11042, `soundBlockNames` :11022, `Audio.addBanks`
  Audio.hx:270). A file reached through `import` is loaded by `loader.loadMultiAnim` from the parser
  (MacroManimParser.hx:5632-5635) and never passes there. A screen file that imports `ui.manim` with
  `#ui sounds { … }` and `#cursors cursor { … }` gets no widget sounds and no cursors (`cursor =>
  "pointer"` falls back silently), and an imported `mix` is not taken either. The docs say a cursor
  block is "registered by name when the file loads"; `needsOf` counts the pack's own cursor blocks as
  satisfied (and in a dev build they start working after the imported file's first hot reload).
  *Fix:* walk `multiParserResult.imports` (depth first, once per builder) in both places; test with a
  two-file fixture.
- [ ] `IMP-2` **P2** **The default loader reads `.anim` from the working directory on HashLink,
  everything else from `hxd.Res`** — CONFIRMED. `ScreenManager.createLoader`'s `loadAnimSMImpl` is
  `File.getBytes(filename)` under `#if hl` (ScreenManager.hx:390-402); sheets, tiles, `.manim`,
  fonts and sounds go through `hxd.Res` (:341-427). So `stateanim("marine.anim")` in a `.manim` that
  itself loads from `res/` resolves against another root, and a game shipped with a pak (or any
  `hxd.Res` loader that is not the local file system) cannot load its `.anim` files. The test loader
  reads `.anim` through `hxd.Res` (test/src/bh/test/TestResourceLoader.hx:34-39), so no test sees it.
  *Fix:* read through `loadHXDResourceImpl(filename).entry.getBytes()` as `loadMultiAnimImpl` does;
  keep a file-system fallback only if a game depends on cwd paths (say so in the CHANGELOG).
- [ ] `IMP-3` **P2** 🤖 **A second `import` of an alias silently replaces the first** — CONFIRMED.
  `importPaths.set(importName, file)` and `imports.set(importName, loadedFile)` with no check
  (MacroManimParser.hx:5631-5635). `import "a.manim" as "kit"` then `import "b.manim" as "kit"`
  makes every `external("kit")` reach `b.manim`; a block only `a.manim` has fails at build as
  "no …", far from the cause. *Fix:* `error('duplicate import alias "kit"')`, as `addNode` does for
  `#name`.
- [ ] `IMP-4` **P3** **`import` is accepted inside any body** — CONFIRMED. The `import` case sits in
  `parseNodes` (MacroManimParser.hx:5476, case at :5624) with no `node == null` check, and
  `parseNodes` parses programmable, slot and `@switch` arm bodies too (:4354, :5816). An `import`
  inside `@(state=>a) { … }` is as global as one at the top, which reads as conditional. *Fix:*
  `if (node != null) error("import goes at the top level of a file")`.
- [ ] `IMP-5` **P2** 🤖 **`external(alias)` is not checked against the file's imports at parse** —
  CONFIRMED. The `staticRef`/`dynamicRef` cases take any identifier (MacroManimParser.hx:3790-3796,
  :3812-3818; also the tilemap and palette `external` sites :1133, :4159, :7872, :7928); the check is
  `importedBuilder` at build (MultiAnimBuilder.hx:9685-9694). A typo fails only when that element is
  built, and a non-incremental build of an arm that is not drawn never reports it; a loaderless
  parse (LSP, `ManimNeeds`) never does, and codegen compiles it and fails at run time. *Fix:* collect
  the `external` aliases with their positions and check them against `importPaths` at the end of
  `parse()`.
- [ ] `IMP-6` **P2** **`staticRef(external(kit), $card)` changes meaning when the importer has a
  parameter or loop variable `card`** — CONFIRMED, by design but undocumented as a hazard. A `$name`
  that is not a parameter is a literal programmable name ("backward compat",
  ProgrammableCodeGen.hx:5032-5043; the builder's `resolveRefName`, MultiAnimBuilder.hx:4227-4237,
  takes anything in `indexedParams`, so a `@final card` does it too), and the docs show the `$` form as the
  normal one (docs/manim-reference.md:68,72). Adding `card:string` to an importer, or a loop
  `repeatable($card, …)`, silently places whatever that value names. *Fix:* warn on a `$name` that
  is neither a parameter nor a loop variable, document the bare form (`staticRef(external(kit),
  card)`), switch the LSP snippets; see AF-4.
- [ ] `IMP-7` **P2** **Sound-bank parameters are one global namespace** — CONFIRMED. `Audio.addBank`
  does `paramValues.set(p.name, p.values)` and resets `params` to the new bank's first value when the
  current value is not among them (Audio.hx:248-252). Two `sounds` blocks that both declare
  `param surface: […]` with different labels: the second's list replaces the first's, so
  `audio.set("surface", "grass")` throws "takes sand, snow" though bank one declares `grass`, and
  bank one's `@(surface => grass)` sounds stop matching. *Fix:* merge the label lists per parameter
  (and error on a label two banks give different meanings, if any), or scope parameters by bank.
- [ ] `IMP-8` **P2** **Registered names are global and inconsistent on collision** — CONFIRMED.
  Fonts: `FontManager.registerFont` throws on a second font of a name, case-insensitively
  (FontManager.hx:11-22), and there is no unregister. Cursors: `CursorManager.registerCursor`
  replaces silently (CursorManager.hx:28-32). Sound banks: replaced by block name, cutting the old
  bank's plays (Audio.hx:244-247). Custom filters: one global map. Two files (two packs) that each
  declare `#ui sounds` or a cursor `pointer`, or a game that registers `m5x7` twice, behave three
  different ways. *Fix:* decide one rule; the proposal's is scoping by declaring file (AF-10).
- [ ] `IMP-9` **P2** **A change to an imported file does not reach its importers on hot reload** —
  CONFIRMED (open in `docs/hot-reload.md:470`, not in the review files). `ScreenManager.hotReload`
  walks `builders` (files a screen loaded, ScreenManager.hx:1662-1666); an imported file is in the
  loader's `multiAnimCache` only, and `hotReloadFile` re-parses the importer against that cache
  (:1760), so the importer keeps the old import. When the imported file is itself a screen's file
  and reloads, `loader.replaceMultiAnim` swaps the cache (:1822-1823) but every importer's
  `multiParserResult.imports` still holds the old builder (filled once at parse,
  MacroManimParser.hx:5635), so `importedBuilder("pack")` (MultiAnimBuilder.hx:9685), staticRef
  rebuilds, `$tpl` template swaps and `refreshTilemapFill` (:9539) all build the old pack. *Fix:*
  resolve imports through the loader by path at build time, or rebind importers on reload; track
  importers per path and reload them on a change.
- [ ] `IMP-10` **P3** **`version:` takes only `1.0`, `.anim` has no version** — CONFIRMED.
  MacroManimParser.hx:5892-5910. A file written for newer syntax fails at its first unknown word,
  reading like a broken file, and nothing says which engine it needs. *Fix:* AF-9.
- [ ] `IMP-11` **P3** **`ManimNeeds` does not list host inputs** — CONFIRMED. `callback(…)`,
  `builderParameter(…)` placeholder sources and `$ctx.width`/`height`/`random` are values the host
  supplies, but `needsOf` lists only `$ctx.font` (ManimNeeds.hx:536-545); a tool cannot tell that an
  export draws differently per host or fails without a callback. *Fix:* a `hostInputs` list (AF-12).
- [ ] `IMP-12` **P2** **`needsOf` loses a map's layer cells when its tileset is imported** —
  CONFIRMED. Layers with no `sheet:` are skipped when `tilesetImport != null` (ManimNeeds.hx:865-876),
  and the import's TILESET walk lists terrain and rise cells only (:846-864): `layer props { "s":
  skull }` puts `skull` in neither file's needs, though manim-reference.md:1806 says it is in "the
  import's own needs"; `ManimNeedsTest.hx:521-542` pins the gap. *Fix:* list the layer's cells under
  the tileset's atlas, marked as the import's.
- [ ] `IMP-13` **P2** **`needsOf` is per file and stops at the import boundary** — CONFIRMED. It walks
  every root and every arm (ManimNeeds.hx:107-129) and drops the values a host passes into an import
  (:781-787), so an import's string parameters fall back to their default with `fromParameters`; there
  is no "what this export needs, given these values", and the docs do not say a tool must recurse into
  `imports` (whose paths are loader keys). *Fix:* AF-12.
- [ ] `IMP-14` **P3** **`needsOf` lists a file's own sound banks as needs** — CONFIRMED. Own sheets
  and own cursors are subtracted, own banks are not (ManimNeeds.hx:641-651, :158). It happens to match
  IMP-1 for imports, not for top-level files. *Fix:* one model, documented.
- [ ] `IMP-15` **P3** **`needsOf` treats enum and range parameters as closed; the runtime does not** —
  CONFIRMED. `setParameter` stores any Int for a range (MultiAnimBuilder.hx:1492-1496), keeps an
  unknown enum string as `StringValue` (:1503-1516), and `dynamicValueToIndex` never checks range
  bounds (MultiAnimParser.hx:1568-1571); codegen alike. So `"lvl_" + $lvl` can become `lvl_99` while
  needs list only declared values with `fromParameters` false (ManimNeeds.hx:419-428). *Fix:*
  validate ranges and enums (DEC-4), or mark such parameters open.

## Builder and codegen across files

- [x] `CG-41` **P1** **Codegen reports a false circular reference when a host and its import share a
  programmable name** — CONFIRMED. `buildStaticRef`/`buildDynamicRef` call
  `target.buildingFrom(fromProgrammable, …)` with `target` the imported builder
  (ProgrammableBuilder.hx:213-224), pushing the host's name onto the import's `buildingRefs`
  (MultiAnimBuilder.hx:10274-10283), whose check then throws (:10290-10292). `pack.manim` with
  `#knight programmable() { staticRef(external(k), knight) }` — the plain re-export wrapper — throws
  `circular programmable reference: knight` in codegen and builds in the builder (its stacks are per
  file). Any shared name (`button`, `icon`, `panel`) breaks the same way. *Fix:* push
  `fromProgrammable` only when `externalRef == null`.
- [x] `BLD-34` **P1** **A ref's arguments are resolved in the target's builder, with its state
  emptied** — CONFIRMED. STATIC_REF/DYNAMIC_REF pass the unresolved `parameters` to
  `builder.buildWithParameters` on the target builder (MultiAnimBuilder.hx:7054-7059, :7083-7093),
  which `pushBuilderState`s (`builderParams` empty, `currentNode` null, :10296) and resolves them
  (:10236-10257, via :10325) before setting `builderParams` (:10326). So `staticRef(x, label =>
  callback("t"))` calls a null function (local refs too), `w => $ctx.width` throws "requires scene",
  `$grid.width`/`$grid.pos(…)` throw "currentNode is null", and across an import
  `tint => palette(hostPal, 1)` is looked up in the pack's palettes (missing, or silently the pack's
  own palette of that name). DynamicRef forwarding (:7163-7176) resolves in the host, so the value
  changes meaning after the first `setParameter`. Codegen resolves every argument in the host. *Fix:*
  resolve arguments in the caller and pass `ResolvedIndexParameters`.
- [ ] `BLD-35` **P2** **`tile`/`flags` cannot be passed to a ref, and forwarding breaks for array,
  tile, flags and bool ternaries** — CONFIRMED. PPTTile goes to `resolveAsString`, which has no
  `TileSourceValue` arm (MultiAnimBuilder.hx:10214, :4410-4417); PPTFlags to `resolveAsInteger`, no
  `Flag` arm (:10199, :4081-4088); the forward switches (:7163-7173, :2199-2209) send every other type
  to `resolveAsInteger`. `staticRef(card, icon => $icon)` throws at build; `dynamicRef(list, items =>
  $items)` builds and the host's first `setParameter("items", …)` throws; `on => ?($n > 2) true :
  false` throws `expected integer, got "true"` on the first update. Codegen passes raw values and works.
  *Fix:* route by the target's type as
  `resolveReferenceableValue` does; pass tile, flags and arrays as they are.
- [ ] `CG-42` **P2** **Codegen lowers a ref's arguments by the host file's parameter types** —
  CONFIRMED, extends CG-23. `ProgrammableCodeGen.hx:8365-8381` looks the target up in
  `allParsedNodes`, the host's parse only; static and dynamic-name sites (:5116, :5371) pass no target.
  `dynamicRef(external(pack), knight, label => $i + 1)` with a string `label` gives `"6"` in codegen
  and `"51"` in the builder; a host programmable of the same name lends its types instead; a host
  `@final T = $enumParam` forwards the enum's index and the builder throws `enum … does not contain
  value "1"`. *Fix:* for an external target emit string-shaped values and let the runtime convert by
  the target's type; at least skip the host lookup when `externalReference != null`.
- [ ] `CG-43` **P2** **Codegen builds every `@()` arm at `create()`; the builder only the shown one**
  — CONFIRMED (the CHANGELOG for `cdb83e5` says so). The builder skips or defers hidden arms
  (MultiAnimBuilder.hx:6646, :6693). So codegen loads every arm's sheets, files and imports: a pack
  trimmed to "what these values need" works in the builder and fails in codegen on a hidden arm's
  missing frame. *Fix:* defer hidden arms in codegen, or document that codegen needs the union.
- [ ] `BLD-36` **P3** **A host map's layer `sheet:` is looked up in the imported tileset's builder**
  — CONFIRMED. `frames` → `tsBuilder.atlasTiles` (MultiAnimBuilder.hx:9696-9704, and
  `checkTilemap`): a host-file inline `atlas2` used as a layer sheet is not found, or the import's
  inline atlas of that name is used; `needsOf` counts the sheet as the host's. *Fix:* resolve layer
  sheets in the map's own builder.
- [ ] `BLD-37` **P3** 🤖 **A missing required argument is reported at its first use, not at the ref**
  — CONFIRMED. Only defaults are filled (MultiAnimBuilder.hx:10263-10265): leaving out `n:int` in
  `staticRef(external(p), knight)` surfaces as `reference n does not exist` inside the pack, or not at
  all when `$n` sits in a hidden arm; a wrong key reads `Setting "x" does not match … "#<uniqueNodeName>"`.
  *Fix:* check required parameters at the ref and name the ref and its target.
- [ ] `CG-44` **P3** **Codegen dynamicRef children and parameterized slots get no TweenManager** —
  CONFIRMED. ProgrammableBuilder.hx:221-235 and ProgrammableCodeGen.hx:1401-1402 set only
  `_transHelper`; the builder hands the enclosing manager down (MultiAnimBuilder.hx:7129-7133). A
  child's `transition {}` animates only if its file came through `buildFromResource`: an import's
  children never animate. *Fix:* pass the instance's manager to child results.
- [ ] `CG-45` **P3** **`setPlaceholderObjects` writes into the loader-shared builder** — CONFIRMED.
  ProgrammableBuilder.hx:461-465, :237-242: a staticRef target's placeholders come from whatever the
  last `create()` of that file set; a nested `create()` overwrites the outer one's. *Fix:* placeholders
  per instance, passed explicitly.
- [ ] `CG-46` **P3** 🤖 **Codegen `setParameter` errors are plain strings** — CONFIRMED, CG-21 family.
  ProgrammableCodeGen.hx:1034, :1282-1360 throw strings where the builder throws `BuilderError` with
  `unknown_param`, `invalid_param_value`, `untracked_param`, so code-filtering catches (e.g.
  UIMultiAnimProgressBar.hx:53) cannot tell the cases apart for a codegen instance. *Fix:*
  `BuilderError.of(…, code)` in the generated setters.
- [ ] `CG-47` **P3** **`staticRef($x)` with `x` a `@final`: the builder places what it names, codegen
  a programmable called `x`** — traced, not run. The builder's `resolveRefName` takes anything in
  `indexedParams`, `@final`s included (MultiAnimBuilder.hx:4227-4237, :3724-3733); codegen checks only
  loop variables and parameters and falls back to the literal (ProgrammableCodeGen.hx:5037-5043), though
  it knows `finalVarExprs`. *Fix:* resolve `@final`s the same way in codegen, or reject `$final` as a
  ref target at parse (IMP-6).

## The last five commits (`97caa2a`, `6895917`, `cdb83e5`, `4adf44e`, `98105cc`)

"Compile probe": a small `@:manim` class compiled against the worktree's `src/` (probe files in the
session scratchpad, not the repo).

- [x] `CG-48` **P1** **Codegen fails to compile ("Null Access") a root-level conditional `apply` over a
  `$param` root property** — `cdb83e5`, CONFIRMED (compile probe; the same text on a `point`
  compiles). A root apply has `parentField == null`, so `resaveOn` pushes `{fieldName: null}`
  (ProgrammableCodeGen.hx:7376, :7385, :7393), and the new gate's `elementFieldRe.match(fieldName)`
  throws in eval (:706-711). `alpha: $a` at the root plus `@(dim=>true) apply { alpha: 0.4 }` and any
  conditional element; also root `scale`/`rotation`/`filter` (a root `filter: flash(amount: $hit)`
  with a hover apply) and root `pos`. Compiled before `cdb83e5`. *Fix:* `fieldName != null &&` before
  the regex; a fixture with a root apply over a `$param`.
- [ ] `CG-49` **P2** **Codegen still runs a hidden element's update when the same setter or batch hides
  it** — `cdb83e5`, traced. Setters run `_updateExpressions` before `_applyVisibility`
  (ProgrammableCodeGen.hx:1086-1095), `endUpdate` too (:1179-1181); the builder applies the
  conditional chains first, then sweeps expressions skipping detached objects (MultiAnimBuilder.hx:2289).
  `@($idx < 3) bitmap(...): layout(row, $idx)` then `setIdx(5)` (or a batch `{on: false, idx: 5}`)
  evaluates `layout(row, 5)` and throws — the case the CHANGELOG calls fixed; the new test sets `on`
  and `idx` in two calls. *Fix:* visibility first, then the gated updates.
- [ ] `CG-50` **P2** **Codegen defers a `dynamicRef($tpl)` template swap while the site is hidden; the
  builder swaps at once** — `cdb83e5`, traced. The swap is an `_eN` update (ProgrammableCodeGen.hx:
  5411-5415), so the new gate (:706-711) skips it; the builder swaps regardless (MultiAnimBuilder.hx:
  2418-2425). After `show=false; setTpl("b")`, codegen's `getDynamicRef("panel")` is still template a
  (`unknown_param` for b's parameters). *Fix:* leave the swap ungated, as `_fwd` forwarding is.
- [ ] `CG-51` **P2** **Codegen: a spliced repeat inside another breaks while the outer one is hidden**
  — `cdb83e5`, traced (the configuration compiles). The marker branch of the visibility pass
  (ProgrammableCodeGen.hx:753-767) lacks the `_si >= 0` guard of the element branch: setting the inner
  condition while the outer is hidden inserts the inner items at index 0, out of order for good; an
  inner `step($n)` rebuilt while the outer is hidden finds no items (`items()` is empty with no parent,
  MultiAnimBuilder.hx:372, :432) and `addItem` drops the new ones. The builder rebuilds the outer
  repeat. *Fix:* guard on the sentinel's parent; rebuild into the outer repeat's held list.
- [ ] `UI-96` **P2** **`resync` moves a binding to the new `dynamicRef` child without its state** —
  `97caa2a`, traced. UIRichInteractiveHelper.hx:106-112 changes `existing.target` but sets nothing on
  it: after `setDisabled("sb", true)` and a template swap, the new template draws `status=normal` and
  looks enabled while the helper keeps `Disabled` (hover and pressed lost alike). *Fix:*
  `target.setParameter(stateParam, …)` with the current state after rebinding.
- [ ] `CG-52` **P2** **Codegen: an unnamed ground bitmap in a runtime-built repeat draws a white
  rectangle** — `4adf44e`, traced (compiles), extends CG-35. The BITMAP branch of
  `generateRuntimeChildExprs` (ProgrammableCodeGen.hx:3843-3899) makes the `solidTile(0xFFFFFFFF)`
  and never sets the ground filter, as the builder does (MultiAnimBuilder.hx:6829-6831).
  `repeatable($i, step($n, dx: 20)) { bitmap(generated(shader(water, 16, 16))) }`. *Fix:* the
  `groundFilterIn` call in that branch.
- [ ] `BLD-38` **P2** **A shader `$param` in a `@switch` arm rebuilds the whole arm on every change**
  — `4adf44e`, CONFIRMED in the builder (MultiAnimBuilder.hx:7276-7311), *plausible* in codegen
  (whose arms the builder builds). `flash(amount: $hit)` driven per frame tears down the arm (its
  stateanims, particles) and makes the filter again; manim-reference "Shaders, Set in place" says only
  an apply's filter and a `group(…)` are made again. *Fix:* track a filter-only change in arms, or
  correct the docs.
- [ ] `CG-53` **P2** **Parameters named `stale` or `applying` break codegen** — `cdb83e5`/`97caa2a`,
  CONFIRMED (compile probes): `Duplicate class field declaration … _stale` / `_applying`. Extends CG-39.
  *Fix:* internals named so no parameter can produce them (`__stale`), or reserve the names.
- [ ] `BLD-39` **P3** **A spliced repeat's own properties and `#name` are dropped** — `cdb83e5`,
  regression, traced. MultiAnimBuilder.hx:7773-7778 now returns null for a conditional or count-driven
  repeat in a flow, so its `alpha`, `scale`, `filter` and `#name` (applied later, :8100, :8156) are
  lost; before they went on the wrapper. Codegen never applied them. *Fix:* reject them at parse for a
  spliced repeat, or give them to each item.
- [ ] `CG-54` **P3** **Codegen rejects one `#name` shared by a literal and a dynamic-name `dynamicRef`
  in exclusive arms** — `6895917`, CONFIRMED (compile probe: "duplicate dynamicRef name").
  ProgrammableCodeGen.hx:2520-2522, :2577-2578 check each list alone; the builder accepts it
  (MultiAnimBuilder.hx:7115), and the docs say "in both backends". *Fix:* the exclusive-arm check
  across both lists.
- [ ] `CG-55` **P3** **Codegen drops a repeat's own `pos:` when it is unrolled or spliced into a
  flow** — `cdb83e5`, traced. ProgrammableCodeGen.hx:2945-2956 and `processRuntimeRepeat`'s in-flow
  branch; the builder adds it to each item (MultiAnimBuilder.hx:7579, :7734). Shows only on
  `@flow.absolute` items.
- [ ] `VFX-38` **P3** **Shader time ignores `ScreenManager.clock` and is process-wide** — `4adf44e`,
  CONFIRMED. `ShaderClock.advance(dt)` in `ScreenManager.update` (ScreenManager.hx:488): a game pause
  that keeps calling `update(dt)` keeps water and stars moving, slow motion does not slow them (sound
  follows `paused`/`scale`), and two managers advance the one static clock twice.
- [ ] `VFX-39` **P3** `EngineShaderFilter.off = true` turns every ground into a solid white rectangle:
  the ground tile is `solidTile(0xFFFFFFFF)` (MultiAnimBuilder.hx:4669-4671, codegen alike), drawn as
  soon as its filter is off. *Fix:* a transparent tile, or hide grounds while off. CONFIRMED.
- [ ] `UI-97` **P3** `setStageShader` during a fade: a new fade starts from the previous fade's
  target, so the mix pops; setting the fade's own target again snaps it to the end
  (ScreenManager.hx:441-470). CONFIRMED.
- [ ] `UI-98` **P3** `UIMultiAnimGrid.set(col, row, data, params)` with a refused value keeps the new
  data but skips `CellDataChanged` (UIMultiAnimGrid.hx:446-466). `97caa2a`. CONFIRMED.
- [ ] `VFX-40` **P3** New static state never reset: `FilterManager.clearAll()` leaves `builtinRegistry`,
  so `setParamDefault` leaks between tests (FilterManager.hx:42, :363); `BuiltinShaders.palettes`
  textures are never freed (BuiltinShaders.hx:146-161); `paletteLock`'s `setParams` joins the palette
  into a string per update (an allocation per frame when animated). CONFIRMED.
- [ ] `LSP-10` **P3** Hover shows a shader's description for `$flash`, `$pulse`, `#water` (any case):
  the stripped word is looked up as a shader before the `$param` lookup (HoverProvider.hx:19, :63-66).
  CONFIRMED.
- [ ] `VFX-41` **P3** In-place setting matches on the shader's own name (`FilterManager.sameShader`,
  FilterManager.hx:342-347): a game filter `mySepia` made with `EngineShaderFilter.of("sepia", …)` is
  made again on every `$param` change, and a same-named shader filter the game put on the object
  (perhaps shared) is written in place. CONFIRMED.

## Parser, LSP and docs

Probes ran the parser on eval (as macros do), HashLink and JS/node (as the LSP does); the probe
files are in the session scratchpad, not the repo.

- [ ] `CG-38` (still open, wider) — the forwarded-children lookup by `uniqueNodeName`
  (MacroManimParser.hx:2988-2989, `Std.string(type)`; ProgrammableBuilder.hx:637-646) differs on all
  three targets, not two: eval prints `[c => …, b => …]` and `{type: …, key: …}`, HashLink
  `[b => …, c => …, a => …]` and `{key : …, type : …}` (just `haxe.ds.StringMap` when DCE drops
  `toString`), JS a nested object dump. A browser build loses the same children. The same names are
  the only node identity a tool has; the fix (a parse-stable ordinal or source position) is AF-5's
  node id too.
- [x] `PRS-26` **P1** **Integer literals parse differently per target** — CONFIRMED (eval, HL, JS).
  `Std.parseInt` (MacroManimParser.hx:630-633, ParseUtils.hx:5-7; the `0x` colour path :1222-1226)
  returns 4294901760 for `0xFFFF0000` on JS and -65536 on HL/eval, so in a browser build (the
  playground, the LSP) `@switch(c) { 0xFFFF0000: … }` and `@(c => 0xFFFF0000)` never match the
  documented opaque form (`#FF0000` is -65536 everywhere). `n:int=99999999999` is 2147483647 on HL,
  an unpositioned "expected integer" on eval, 99999999999 on JS. *Fix:* wrap every parsed integer to
  Int32 and reject an overflowing literal with its position.
- [ ] `PRS-27` **P2** 🤖 **An unnamed root element crashes with no position; the LSP takes it** —
  CONFIRMED. `version: 1.0` then `bitmap(generated(color(1,1,#f00))): 0,0` reaches
  `addNode(null, …)` (MacroManimParser.hx:5702-5714, :5885-5887): HL "Null access .bytes", eval "Null
  Access", JS stores it under "null" and the LSP shows nothing. `currentName` leaks after an unnamed
  `paths`/`curves` (:4076, :4099), so a nameless `sounds`/`data`/`cursor` after one passes the
  "requires a #name" check with errors naming "paths". *Fix:* error on a root element with no name;
  reset `currentName` after each root node.
- [ ] `PRS-28` **P2** **Numeric parameter defaults are misread silently** — CONFIRMED. `n:int=1.5` → 1,
  `u:uint=2.9` → 2, `f:float=0x10` → 0.0 (MacroManimParser.hx:1945-1958, :1975-1980). *Fix:* branch on
  the token kind; reject a float for int types; read a hex token as a number for floats.
- [ ] `PRS-29` **P2** **Comparison and bit-test operands are not type-checked at parse** — CONFIRMED
  for the parse and the builder. `@(status >= hover)` on an enum, `@(n >= abc)`, `@(n => a..b)` on an
  int, `@(s => bit[1])` on a string or float all parse (:2066-2081, :2135-2153); the builder throws at
  build ("expected number, got hover", MultiAnimBuilder.hx:4145-4147; "invalid param types",
  :4844-4851); codegen emits `_m >= "hover"` / `_s & 2` (ProgrammableCodeGen.hx:8490, :8316), which
  should not compile (*plausible*). `@switch` rejects `>=` on the same enum (:5744-5770). *Fix:*
  numeric operands only (or enum names by index), `bit[]` on int-backed params only.
- [ ] `PRS-30` **P2** **A data block's array is typed from its first element** — CONFIRMED.
  `xs: [1, "a", true]` → `DVTArray(DVTInt)` holding a string and a bool; `[1, 2.5]` → int[]; `[]` →
  int[] (:8621-8627, :8931-8951). `DataSchema` and `@:data` read the wrong type. *Fix:* int + float →
  float, reject mixed arrays, require a type for an empty one.
- [ ] `PRS-31` **P2** 🤖 **No source positions in the AST outside `MULTIANIM_DEV`** — CONFIRMED.
  `Definition` has no position (MultiAnimParser.hx:267-271) and `parserPos` is DEV-only (:1462). A
  tool with no Heaps (LSP, CLI, an art-pack host) cannot point at or edit a parameter default in
  place; `.anim` has `AnimSpan`, `.manim` nothing. The LSP falls back to the first text occurrence
  (`findNameInText`, ManimAnalyzer.hx:67, :366), so outline entries land on the wrong line or line 0.
  *Fix:* line/column always on nodes and definitions, value spans like `AnimSpan` (AF-16).
- [ ] `PRS-32` **P2** 🤖 **A parse (and so the LSP) accepts files the builder refuses** — CONFIRMED.
  `staticRef(nothere)` (a same-file target that does not exist), `staticRef(q, y=>5)` where `q` has
  no `y`, a `@final width` shadowing parameter `width` (only the builder throws,
  MultiAnimBuilder.hx:3725-3731), a typo in a built-in shader's argument (`ShaderCatalog` has no Heaps
  dependency, but the check is only in `FilterManager`). *Fix:* a post-parse check pass with no Heaps,
  which the LSP and a pack reader run (AF-7).
- [ ] `PRS-33` **P3** Declarations that can never be valid are accepted: `e:[]` (null default),
  `r:5..1`, `flags(0)`, `flags(99)`, `d:hexdirection=9`, `f:flags(4)=255`; `bit[40]` is `1<<40`,
  which wraps to bit 8 (:2138-2140). Extends PRS-11. CONFIRMED.
- [ ] `PRS-34` **P3** Names are not checked as identifiers: `my-param:int=1` declares, but `$my-param`
  lexes as `$my - param` ("unknown variable $my. Available: my-param"); `"a b":int`, `@final "a b" = 1`
  and a data field `"a b": 1` are accepted. *Fix:* `[A-Za-z_][A-Za-z0-9_]*` for parameter, `@final`
  and data names. CONFIRMED.
- [ ] `PRS-35` **P3** A root-level `@final` parses, is registered as a node, offered and outlined by
  the LSP (ManimKeywordInfo.hx:107; an LSP test pins it) and listed in manim-reference's File
  Structure, but `$X` in any programmable is "unknown variable $X". Making it visible is a deferred
  feature in `release-1.0-audit.md`; until then reject it or say so in the docs. CONFIRMED.
- [ ] `PRS-36` **P3** A `string` parameter can never be required: every other type without `=` is
  required (a constructor argument in codegen), but `name:string` and bare `name` always default to
  `""` (:1834-1835, :1858-1861), so a signature cannot say "required" for strings. CONFIRMED.
- [ ] `PRS-37` **P3** Duplicates resolve silently and differently: two imports of an alias (IMP-3),
  `staticRef(q, x=>1, x=>2)` (the last wins, :5199-5213), and data annotations
  `@range(0,10) @range(0,3) hp: 7`, where the parser checks the first range and
  `DataSchema.metaObject` keeps the last (DataSchema.hx:143-149), so a tool sees 7 outside [0,3].
  CONFIRMED.
- [ ] `PRS-38` **P3** 🤖 Structure errors: a stray `}` at the end of a file is accepted (:5479-5481);
  one mid-file is reported as "unexpected content after main body: TName(q)" at the next element; two
  unnamed `paths {}` give "duplicate node ##defaultPaths", an internal name (near PRS-21); inside
  `${}` a bare enum word becomes a reference (`'${?($m == a) "x":"y"}'` → "unknown variable $a").
  CONFIRMED.
- [ ] `LSP-8` **P2** **The LSP's own parameter scan is wrong** — CONFIRMED (node probe).
  `ContextAnalyzer.hx:147`, :270, :330: `mode:[a,b]=a` yields a parameter `b]` (commas inside brackets
  split it); parameters of every earlier programmable and slot leak into later ones; keyword checks are
  case-sensitive while the parser is not (`Programmable(` yields no parameters; `#ap animatedpath {`
  falls into element completions). *Fix:* read parameters from the parse (AF-5), or track bracket
  depth, reset per root block and compare lowercased.
- [ ] `LSP-9` **P3** Outline and hover show wrong data: every unnamed child is `#null`, `@final K` is
  `#K`; `flags(4)` shows as `flags`; the parameter list comes from the Map, not `paramOrder`
  (ManimAnalyzer.hx:70, :157, :282); a parameter's hover regex-matches the first `name:` anywhere in
  the file, with the name unescaped in the regex (HoverProvider.hx:40). CONFIRMED.
- [ ] `DOC-27` **P3** Docs that do not parse or mean something else: `docs/manim.md:1092`
  `status:[hover, pressed]=normal` (default not in the enum); `:1102` `color:#f0f` / `color:red` as a
  parameter form ("unknown parameter type"); `:1407-1409` lists duplicate and shadowing `@final`s as
  parse errors (PRS-15; shadowing is caught only by the builder); `:1454-1462` palette examples
  `0xf12 0x332 0xfff` are fully transparent under strict-D; manim-reference's File Structure lists a
  root `@final` (PRS-35). CONFIRMED.

## `.anim` and `AnimationSM`

`ANM` continues `todo/agentic-workflows.md` (ANM-1..12), where the `.anim` tooling items are.

- [x] `ANM-13` **P1** **Point events are not mirrored by `flipX`/`flipY`** — CONFIRMED. `createStates`
  pushes `Event(playlistEvent)` as parsed (AnimParser.hx:2644-2645), while extra points are mirrored
  about the untrimmed frame (:2855-2863); a `random` event's centre is not mirrored either. With
  `flipX: yes`, `extrapoints { fire: 10,-8 }` reads (-10,-8) but `event muzzle 10,-8` fires at
  (10,-8): the bullet leaves from the wrong side. No test flips an animation with events. *Fix:*
  mirror event points with the same function as extra points, a new point per selector.
- [x] `ANM-14` **P1** **Held and event sounds start on machines that are not in the scene** —
  CONFIRMED. `play()` runs `updateHold()` and `handleCurrent(EPSILON)` (AnimationSM.hx:207-224,
  :705-718, :754-770) whether or not the machine is allocated; only `onRemove` stops a hold. So
  `extraPoint("ship.anim", "thrust", "muzzle")` — a throwaway machine played to read one point
  (MultiAnimBuilder.hx:6018-6029; codegen once per coordinate, ProgrammableCodeGen.hx:6538-6539,
  :9406-9407, and again per selector change) — starts `sounds { hold thrust: … }` for good, and an
  opening `event shot` with a sound plays per lookup. Every `stateanim` element also plays before it
  is attached (MultiAnimBuilder.hx:7318-7319, ProgrammableBuilder.hx:304-307): a programmable built
  and never shown holds its sound forever. *Fix:* `extraPoint("file.anim", …)` reads the point from
  the parse with no machine; holds and event sounds start only while allocated (`onAdd` already
  starts holds).
- [ ] `ANM-15` **P2** **Without `center:`, atlas trim offsets are dropped** — CONFIRMED. `AFtoFrame`
  applies `offsetx`/`offsety` only inside `if (_center != null)` (AnimParser.hx:2593-2599); Atlas2
  tiles are cut with dx = dy = 0 (Atlas2.hx:216). Trimmed frames jitter, and
  `AnimationClip.getBoundsRec` (:186-187) subtracts the offset and reports a box where nothing is
  drawn. `stateanim construct(…, center)` jitters the same way (`tile.center()` on the trimmed tile,
  MultiAnimBuilder.hx:7331, ProgrammableBuilder.hx:321). *Fix:* a missing centre is (0, 0).
- [ ] `ANM-16` **P2** **Layers flip each about its own canvas** — CONFIRMED in code. `layerFramesOf`
  calls `createStates` per layer (AnimParser.hx:2920), so `maybeFlipClone` mirrors each layer by its
  own frame size (:2609), and the same-size check runs per layer only (:2671-2690); points mirror by
  the timeline's size (:2837-2852). A 48-wide glow over a 32-wide body ends 16 px off when flipped.
  *Fix:* one mirror axis per animation (the timeline's footprint), or a load error naming the layer.
- [ ] `ANM-17` **P2** **`animNeedsOf` lists frames the file never loads** — CONFIRMED. It expands
  `${state}` over every value and ignores the block's condition (ManimNeeds.hx:184-205), and
  `ManimNeedsTest.hx:608` pins that: `layer hat @(hat != none) { sheet: "hat_${hat}" }` needs
  `hat_none`. A host checking a pack reports missing frames that are not missing. *Fix:* walk the
  states × the matching animation/playlist/layer, as the parse's reachability pass does.
- [ ] `ANM-18` **P2** **`$ref.extraPoint(…)` is in the sprite's own space** — CONFIRMED.
  MultiAnimBuilder.hx:6009-6011; ProgrammableCodeGen.hx:6221-6228, :6518-6524, :9388-9395. The
  `stateanim` element's position, `@scale` and rotation are not applied, so the doc example
  (docs/manim-reference.md:532-537, element at 100,100) places the marker at the raw point; test 101
  adds `.offset(220,600)` by hand (animFlip.manim:79-85) and `BuilderUnitTest.hx:6735` pins the raw
  value. The lookup takes `names[0]` (builder) / `elementFields[0]` (codegen), so with `#body` in
  exclusive facing arms it reads the first arm, not the drawn one (*plausible*). *Fix:* compose with
  the element's transform (or document it and add a parent-space form); look up the drawn arm.
- [ ] `ANM-19` **P2** **No Heaps-free reading of an `.anim`; state order lost** — CONFIRMED. The
  parser and `AnimParserResult` sit inside `#if (!macro && !noheaps)` (AnimParser.hx:883-956), and
  point events exist only with Heaps (:770-772), so nothing in a `-D noheaps` build can make the
  `LoadedAnimation` that `animNeedsOf` takes (CLAUDE.md says ManimNeeds is "for the LSP").
  `definedStates`/`LoadedAnimation.states` is a `Map` (:912, :533): `states: facing(..), state(..)`
  comes back in either order on HashLink, so a figure programmable generated from it can differ by
  target. Extends ANM-4/ANM-5. *Fix:* a Heaps-free parse phase with a plain point type and an
  ordered state list.
- [ ] `ANM-20` **P3** Point events take no `$constants`: `event hit $X, $Y` becomes a bare trigger
  and the next token is "unexpected" (AnimParser.hx:2055-2092); extra points and `random` accept
  `$X`. CONFIRMED.
- [ ] `ANM-21` **P3** 🤖 `duration:` with no value parses, and its span covers the next token —
  `parseDurationValue` returns null without consuming (:2362-2363), `markSpan` of zero tokens takes
  the next (:1313). `sheet:"a" duration: frames: 0..2` parses; a tool editing `….duration` in place
  overwrites `frames`. A second `duration:` passes the duplicate check. CONFIRMED.
- [ ] `ANM-22` **P3** 🤖 Two spans share one path: a header name and a body `name:` both record
  `animations.<i>.name` (:1158, :1804); file-level `loop:`/`flipX:`/`flipY:` and animation `loop:`
  have no duplicate check (:1109-1123, :1809-1812), the second wins while a tool edits the first.
  VFX-16 covers the diagnostic; the span consequence is new. CONFIRMED.
- [ ] `ANM-23` **P3** Metadata getters with no selector return the first entry written, even a
  conditional one: every score is 0 and the comparison is strict (AnimParser.hx:612-620).
  `@(dir=>l) x:-5 @(dir=>r) x:5 @default x:0` → `getIntOrDefault("x", 9)` is -5, expected 0. Not
  VFX-28. CONFIRMED.
- [ ] `ANM-24` **P3** A tint the game sets on `sm.clip` or a layer is overwritten on every `play`,
  per-frame `filter` and `setState` redisplay (`setLookTint`, AnimationSM.hx:497-515, :537-544),
  though the docs offer `layer(name)` to tint. CONFIRMED.
- [ ] `ANM-25` **P3** `setState` with a different frame count replays a finished one-shot (a death
  animation restarts, fires its events, sounds and `onFinished` again), and a paused machine fires
  its opening events (AnimationSM.hx:287-291). CONFIRMED.
- [ ] `ANM-26` **P3** The parse cache hands the same mutable objects to every machine: a point
  event's point (AnimParser.hx:2070, :2081, given straight to handlers at AnimationSM.hx:630-631)
  and per-frame `filter` instances (:2658-2664, cached :2866), against the cache comment at
  :936-938. CONFIRMED.
- [ ] `ANM-27` **P3** `createAnimSM` keeps the caller's selector map (`currentSelector = selector`,
  AnimationSM.hx:127), and the documented pattern (anim-reference.md:526-531, older than `setState`)
  mutates that map, so a second machine's selector changes the first's next `setState`. CONFIRMED.
- [ ] `ANM-28` **P3** `sounds { }` event keys are never checked against the file's events (holds are,
  :1202-1204; events not, :1723-1726): `fier: "fx.shot"` plays nothing, silently. CONFIRMED.
- [ ] `ANM-29` **P3** `${state}` in a `file:` line is neither validated nor expanded (:2040-2048,
  :2640-2643): `file: "pose_${dir}.png"` loads that name literally. CONFIRMED.
- [ ] `ANM-30` **P3** Span docs and coverage: the table in anim-reference.md:452-472 omits `layers`,
  `sounds`, `.timeline`, `.layer.<name>#<n>`, `.blend`; a layered animation's playlists have no
  `.playlist#p` span; no spans for an event's radius or payload, filter values, `sounds` entries,
  state values or conditions; the docs do not say offsets are UTF-16 code units of the decoded text,
  so a tool editing bytes breaks on non-ASCII. CONFIRMED.
- [ ] `ANM-31` **P3** The 1000-iteration guard throws on legitimate catch-up: each frame advance is
  one iteration, so an externally driven `update(20)` on a looping 60 fps animation throws
  "animation loop detected" (AnimationSM.hx:582, :656-657). *Plausible.*
- [ ] `ANM-32` **P3** A hole in an atlas name's indices crashes with no name: `getAnim` returns nulls
  for missing indices (Atlas2.hx:128) and `AFtoFrame` dereferences them (AnimParser.hx:2626).
  *Plausible.*

## UI — widgets and their contracts

The contract table these were found with is Appendix A of the proposal.

- [x] `UI-75` **P1** **Disabling a slider, scrollbar, list or dropdown mid-drag freezes the screen's
  input** — CONFIRMED. A drag puts the widget in `captureEvents.target`, and only its own
  `stopCapture()` clears it; a disabled widget's `onEvent` returns on its first line
  (UIMultiAnimSlider.hx:177-192; UIMultiAnimScrollbar.hx:138-150, :247-248;
  UIMultiAnimScrollableList.hx:332-333), and the controller routes every move and click to the
  capture target (UIDefaultController.hx:228-231). `clearState()` runs only from `UIScreen.clear()`
  (UIScreen.hx:232). Extends UI-15 (the draggable's case). *Fix:* the controller drops a capture whose
  target is a disabled `UIElementDisablable`, or `set_disabled(true)` stops it.
- [x] `UI-76` **P1** **`OkCancelDialog` acts on key release: a dialog opened by Enter or Escape closes
  itself** — CONFIRMED. `case UIKeyPress(keyCode, release)` ignores `release`
  (src/screens/OkCancelDialog.hx:59-64), and `UIKeyPress` is sent on down and up
  (UIDefaultController.hx:318-320). "Esc → Quit?" closes as Cancel on the Esc key-up. *Fix:* act on
  `release == false` only, and ignore a key that was down when the dialog opened.
- [ ] `UI-77` **P2** **Composite widgets leak their children's events to the screen** — CONFIRMED. A
  dropdown selection pushes `UIChangeItem` twice (the dropdown's, and the inner list's with the list
  as source, UIMultiAnimScrollableList.hx:484-487, UIMultiAnimDropdown.hx:81, :162-170), so `change`
  plays twice and the list's copy ignores the dropdown's `sound.change`; a list's dragged scrollbar
  pushes `UIChangeValue` per drag step (UIMultiAnimScrollbar.hx:231-238 via the list :335-340); a
  radio click sends `UIChangeItem` and the child's `UIToggle` (UIMultiAnimRadioButtons.hx:59-63).
  *Fix:* children of a widget push to their parent, not the screen.
- [ ] `UI-78` **P2** **`setItems` with the list's own array empties the list** — CONFIRMED. The list
  keeps the caller's array (`this.items = items`, UIMultiAnimScrollableList.hx:79) and `setItems`
  does `items.resize(0)` before copying `newItems` (:132-134): `items.push(x); list.setItems(items)`
  ends empty, and the dropdown sharing the array is mutated. *Fix:* copy in the constructor and copy
  `newItems` before clearing.
- [ ] `UI-79` **P2** **Items scrolled out of a list's view can be hovered and clicked** — CONFIRMED.
  `findInteractiveIndex` tests each item's unclipped bounds (UIMultiAnimScrollableList.hx:271-281,
  :361) while the list's `containsPoint` is the whole panel with its header (MAObject.hx:53-58): a
  click on the header selects an item hidden under the mask. *Fix:* reject points outside the mask.
- [ ] `UI-80` **P2** **A text input's events are lost until the mouse has touched it** — CONFIRMED.
  `controllable` is captured only inside `onEvent` (UIMultiAnimTextInput.hx:39, :167-170, :186-188),
  so after focus by Tab (UITabGroup.hx:132) or `focus()`, every `UIFocusChange`, `UITextChange` and
  `UITextSubmit` is dropped. No test covers the events. *Fix:* give the input its `Controllable` when
  it is added.
- [ ] `UI-81` **P2** **Disabling an open dropdown leaves its panel open for good** — CONFIRMED.
  `set_disabled` does not close it; the panel keeps `Overlay` priority and eats clicks while
  `onEvent` returns early (UIMultiAnimDropdown.hx:107-113, :176-182, :253). *Fix:* `startClose()` and
  reset the priority on disable.
- [ ] `UI-82` **P2** 🤖 **A list's and a dropdown's other settings are dropped silently** —
  CONFIRMED. `split.main` is never used and `buildPanel` passes only `width`, `height`,
  `topClearance`, ignoring `panelBuilder.extraParams` (UIScreen.hx:986-1005, :1037-1063;
  UIMultiAnimScrollableList.hx:168-170). The docs say they reach the panel (docs/manim.md:3506,
  :3641, :895); every other widget throws "does not match any parameter". *Fix:* forward them, or
  throw as the others do.
- [ ] `UI-83` **P2** **A prefixed setting beside its bare form: the winner depends on map order** —
  CONFIRMED. The bare multi-forward `font`/`fontColor` overwrites the prefix map unchecked
  (UIScreen.hx:561-594): with `item.font => A` and `font => B` the item gets whichever key the
  `StringMap` yields last, which differs between HashLink and JS. *Fix:* the prefixed key always
  wins.
- [ ] `UI-84` **P2** **Button click semantics are loose** — CONFIRMED. `OnRelease` fires `UIClick`
  with no press on the button first and for any mouse button (UIMultiAnimButton.hx:98-102); checkbox
  and tab act on a push of any button (UIMultiAnimCheckbox.hx:76, UIMultiAnimTabs.hx:96). Same family
  as UI-44. *Fix:* a left-press flag set on `OnPush(0)`.
- [ ] `UI-85` **P2** **`disabled` and `status` differ per widget** — CONFIRMED. Button, checkbox, tab
  and slider pass `disabled` at build (so a design without it throws: UIMultiAnimButton.hx:28,
  Checkbox:56, Tabs:69, Slider:107) yet guard it with `hasParameter` at run time (:70, :36, :46,
  :122); scrollbar and text input treat it as optional. Button, checkbox, tab, dropdown, text input
  and list items write `status => "disabled"` (outside the documented enums); slider and scrollbar
  never do, so `@(status=>disabled)` art works on one and not the other. An enum value the design
  lacks throws at build (MultiAnimParser.hx:1566) but is kept silently by `setParameter`
  (MultiAnimBuilder.hx:1503-1516): a design without `hover` builds and draws nothing on hover.
  Related to DEC-4. *Fix:* pass `disabled` only when declared; fix one runtime value set per widget
  in the contract (AF-13).
- [ ] `UI-86` **P2** 🤖 **Required parts are checked late, or never** — CONFIRMED. The list panel's
  `builderParameter("mask")` is never checked, an unknown placeholder key is ignored
  (MultiAnimBuilder.hx:7010-7014, :7042-7047), so the list is invisible; the `#scrollbar` point is
  checked only once content overflows (UIMultiAnimScrollableList.hx:204, :223-230), so a later
  `setItems` throws mid-game; the dropdown's `#selectedName` only on the first selection change
  (:97-103); a slider without `#start`/`#end` is silently dead (Slider:157-160); slider and progress
  bar build at the first `update()` (Slider:100-117, ProgressBar:43-64), so their errors come from
  the frame loop. *Fix:* check parts in the constructor from the parse (`builder.hasNamedElement`).
- [ ] `UI-87` **P2** **The list item contract has undocumented parts** — CONFIRMED. `images` is always
  passed (UIElementBuilder.hx:41-76) and so required, but undocumented (docs/manim.md:3419-3431);
  `tile` is passed pre-resolved, which skips the unknown-name check (MultiAnimBuilder.hx:10251-10252),
  so an undeclared `tile` is dropped; every interactive in an item must have the item's index as id
  (UIMultiAnimScrollableList.hx:191, :283-289), so a `"del"` icon throws at first hover. *Fix:* document
  both; check pre-resolved values by name too.
- [ ] `UI-88` **P2** **Two statements in `manim-reference.md` are wrong** — CONFIRMED. :1611 says an
  unknown parameter name is a silent no-op widgets rely on; `setParameter` throws `unknown_param`
  (MultiAnimBuilder.hx:1462-1467). :1544 lists `initialValue` for the slider; `addSlider` does not
  read it (UIScreen.hx:646-650), so it passes through and the slider throws at its first redraw. Also
  `docs/manim.md` "UI Components" has no text input or dialog section. *Fix:* correct both; have
  `addSlider` read `initialValue`.
- [ ] `UI-89` **P3** `scrollSpeed` has no effect until `setItems`: the constructor computes it before
  `addScrollableList`/`addDropdown` set the override (UIMultiAnimScrollableList.hx:221, :474-480;
  UIScreen.hx:1005-1007, :1063-1065). CONFIRMED.
- [ ] `UI-90` **P3** Tabs: `addTabs` always passes `tabButtonHeight` (UIScreen.hx:776-800), so std's
  own `#tabBarVertical`, which does not declare it, cannot be built through `addTabs`; every
  `tabPanel.<key>` becomes `panel<Key>` while std and the docs declare `offset`
  (std.manim:365, docs/manim.md:3705-3714); `tabButtonHeight` defaults to 30 whatever the design.
  CONFIRMED.
- [ ] `UI-91` **P3** `ManimNeeds` takes a tab for a button: `buttonText` is tested before `checked`
  (ManimNeeds.hx:695-699), so it lists `hover`/`click` (a tab plays neither) and misses `change`,
  against manim-reference.md:1817. A second hand-kept copy of the widget contracts inside the
  engine, already drifted (AF-13). CONFIRMED.
- [ ] `UI-92` **P3** Initial sync: a checkbox is both `UIElementNumberValue` and `UIElementSelectable`,
  so `syncInitialState` sends `UIChangeValue(0/1)`, never `UIToggle` (UIScreen.hx:1437-1446); elements
  added inside a tab are never synced (:1374-1403 vs :359-363). The test's mock is Selectable only.
  CONFIRMED.
- [ ] `UI-93` **P3** Re-enabling a read-only text input makes it editable: `set_disabled(false)` sets
  `canEdit = true` over `readOnly` (UIMultiAnimTextInput.hx:87 vs :231). CONFIRMED.
- [ ] `UI-94` **P3** The slider breaks its own change rule: `lastSentValue` starts null, so the first
  push reports a change at the current value; the constructor's `initialValue` is neither clamped nor
  snapped; min > max clamps every `setFloatValue` to one end (UIMultiAnimSlider.hx:53, :214-218,
  :230-236; docs/manim.md:3291-3293). CONFIRMED.
- [ ] `UI-95` **P3** Smaller, all CONFIRMED: the radio group's `set_disabled` stores nothing, so
  `radio.disabled` reads false and items' own `disabled` is ignored (UIMultiAnimRadioButtons.hx:36-39);
  in SingleClick mode a click on the selected item fires no `UIClickItem`, in DoubleClick mode it does
  (List:383 vs :367); the wheel over the dragged bar scrolls `arrowStep` (20) a notch, over the items
  `wheelScrollMultiplier` (10); `OkCancelDialog` requires a `#dialogText` it never uses (:49); a
  dropdown with no items cannot be made and has no `setItems` (:98-99, :143); a `buttonText`,
  `status` or `disabled` given as a setting overrides the build value, so `getText()` disagrees with
  what is drawn.

