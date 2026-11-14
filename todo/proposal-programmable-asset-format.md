# Programmables as an asset format: export and import

Proposal, 2026-10-25, read against `origin/dev` `98105cc` and the `export` / `///` work staged in the
main checkout the same day (since merged into the branch that carries this file). The defects found in the same review are in
[review-2026-10-25-asset-format.md](review-2026-10-25-asset-format.md); this file says how the format
should work and what the engine has to change for it.

**In short.** A pack is a folder of `.manim` and `.anim` files and the atlases, pictures, fonts and
sounds they name. Its public interface is the root blocks its files mark `export`, gathered by one
index file, `pack.manim`. Any host (a game, the playground, an art library, a CLI) reads that
interface from a parse alone, with no Heaps and no loader, and places an export with
`staticRef(external(ninja), knight, state => walk)`. Four things must hold for that: every name a
pack's file writes resolves the same way in every host; a pack's registered names (cursors, sound
banks, fonts) neither collide with another pack's nor get lost when the pack is imported; each export
has a signature, parts, a contract and needs that a tool can read as plain data; and a file says which
version of the format it needs. The engine has the pieces (`import`, `external()`, `ManimNeeds`,
`importPaths`, and now `export` and `///`), but today it resolves every name as a host loader key,
registers only the top-level file's cursors and banks, reads `.anim` files from another root than
everything else on HashLink, resolves a ref's arguments in the wrong file (BLD-34) and trips
codegen's cycle guard across files (CG-41), has no reader that turns a signature into data, and
takes only `version: 1.0`. Section 4 lists the changes in order.

---

## 1. Terms

| Term | Meaning |
|---|---|
| Pack | A folder (or a zip mounted as one) with `pack.manim` at its top. Its boundary is that folder. |
| Index | `pack.manim`: what the pack is (`#pack data`), and which files' exports it offers (`export import`). Draws nothing. |
| Export | A root block marked `#name export <kind>`: what a host may place or play. Everything else is the pack's implementation. |
| Host | Whatever loads the pack: a game's `ScreenManager` and loader, the playground, a tool. |
| Signature | An export's parameters in order: name, type, choices, range, default, required, doc. |
| Parts | What an export has beyond parameters that code reaches by name: `#name` elements, slots, interactive ids, points, settings keys; for a figure, its animations' points, areas and events. |
| Contract | A named shape an export says it meets (`button`, `figure`): parameters, values and parts. |
| Needs | What an export reaches for outside its pack: engine shaders, host fonts, custom filters, the `ui` bank, callbacks; and inside it: the sheets, cells and sounds it uses. |

## 2. What the engine does today

| Area | Today | Where |
|---|---|---|
| `import "f" as "a"` | Kept in `importPaths` with or without a loader; with one, the file is loaded during the parse through `loader.loadMultiAnim(path)`. The path is a host loader key, never relative to the importing file. Accepted inside any body, not only at the root. A second import of the same alias silently replaces the first. | `MacroManimParser.hx:5624-5636` |
| `external(a)` | Looked up at build (`importedBuilder`). An unknown alias is a build error, raised only where and when that element is built (not at all for an arm a non-incremental build does not draw). | `MultiAnimBuilder.hx:9685-9694`, parser `:3787-3829` |
| Naming what is placed | `staticRef(external(a), $knight)` places `knight`, unless the importer has a string/enum parameter or a loop variable named `knight`: then it places whatever that value names. Codegen calls the `$name` literal "backward compat"; the docs show it as the normal form. | `ProgrammableCodeGen.hx:5032-5043`, `MacroManimParser.hx:534-546`, `docs/manim-reference.md:68,72` |
| Imported builders | Loader-cached and shared by every importer, cycles detected. The target's body is built by the imported builder (its palettes, `@final`s, atlases, imports), but the ref's arguments are resolved there too, after its state is emptied: a callback, `$ctx`, `$grid` or palette in an argument fails or means the pack's (BLD-34). `tile`/`flags` cannot be passed (BLD-35). Codegen resolves arguments in the host by the host's types (CG-42), and its cycle guard mixes the two files, so a wrapper `#knight` placing the pack's `knight` throws "circular" (CG-41). | `ResourceLoader.hx:184-200`; `MultiAnimBuilder.hx:7054-7093`, `:10274-10326`; `ProgrammableBuilder.hx:213-224` |
| Registered names | `buildFromResource` registers the loaded file's `cursor` blocks and adds its `sounds`/`music`/`mix` blocks to `audio`, again on hot reload. An imported file's are never registered. Fonts exist only through `FontManager.registerFont` in code, which throws on a second font of a name; a cursor of an existing name replaces it silently; a bank of an existing block name replaces it and cuts its plays. All are global. | `ScreenManager.hx:563-568`, `:1824-1825`; `FontManager.hx:11-22`; `CursorManager.hx:28-47`; `Audio.hx:270-285` |
| Loading `.anim` | The default loader reads `.anim` with `sys.io.File.getBytes(path)` on HashLink (relative to the working directory) and everything else through `hxd.Res` (relative to `res/`, or from a pak). The test loader reads `.anim` through `hxd.Res`, so no test sees the difference. | `ScreenManager.hx:390-402` vs `:341-427`; `test/src/bh/test/TestResourceLoader.hx:34-39` |
| Needs | `ManimNeedsTools.needsOf(result)`: one whole file, from the parse, every arm; imports listed by alias, not followed, and the values a host passes into an import dropped; no "this export only", no "given these values"; callbacks, `builderParameter`, `placeholder` sources and `$ctx.width`/`height`/`random` not listed. A superset of what the builder loads for that file as long as values stay in their declared enums and ranges, which the runtime does not enforce (IMP-15). Codegen builds every `@()` arm at `create()`, so a pack trimmed to the values a game takes works in the builder and fails in codegen (CG-43). | `ManimNeeds.hx:7-160`, `:781-787` |
| Signature | `PROGRAMMABLE(isTileGroup, defs:Map<String, Definition>, paramOrder)`; `Definition = {name, type, defaultValue}`; types uint, int, float, bool, string, color, tile, enum, int range, flags, hexDirection, gridDirection, array. No float range, no step; "required" only as a missing default; nothing that turns it into plain data. Codegen makes enum parameters `enum abstract`s over the choice's index. | `MultiAnimParser.hx:250-271`, `:1296`; `ProgrammableCodeGen.hx:10430` |
| Format version | `version: 1.0` (or `1`) is the only header the parser takes. A file using newer syntax fails at its first unknown word, which reads the same as a broken file. `.anim` has no version header. | `MacroManimParser.hx:5892-5910` |
| Hot reload | Reloads the files a screen loaded; a change to an imported file does not reach its importers (open item). | `ScreenManager.hx:1655-1692`, `docs/hot-reload.md:470` |
| `export` and `///` (new) | `#name export <kind>` on any root block, `MultiAnimResult.exports` in written order, `///` docs on root blocks, parameters and enum choices (`MultiAnimResultTools.exportedNames`/`docOf`, the builder's `exportedNames()`/`docOf()`, LSP hover). "An import still reaches every block." | `MultiAnimParser.hx` (`MultiAnimResultTools`), `ExportDocCommentTest` |

## 3. How it should work

### 3.1 A pack on disk

```
ninja-adventure/              mounted by a host at, say, lib/org.ninja-adventure/
  pack.manim                  the index
  knight.manim                #knight export programmable(...) playing knight.anim
  knight.anim  knight.atlas2  knight.png
  ui.manim  ui.atlas2  ui.png
  fonts/m5x7.fnt  fonts/m5x7.png
  sounds/slash-1.wav ...
  examples/village.manim      examples: not exported, not imported by the index
```

```manim
version: 1.0

/// Top-down 16 px characters, monsters, UI and sounds.
#pack data {
    id: "org.ninja-adventure"
    name: "Ninja Adventure"
    version: "4.1.0"
    licence: "CC0"
}

export import "./knight.manim" as knight
export import "./ui.manim" as ui
import "./shared.manim" as shared        // the pack's own helpers, not offered
```

```manim
// knight.manim
version: 1.0

/// A knight in grey armour with a visored helmet.
@meets(figure)
#knight export programmable(
    state:[
        idle,       /// stands still
        walk,       /// 4 frames at 8 fps, loops
        attack      /// one pose for 300 ms, hit at 150 ms
    ] = idle,
    facing:[s, w, n, e] = s
) {
    #body stateanim("./knight.anim", $state, direction => $facing): 0, 0
}
```

- Every name a pack's file writes for something in the pack is relative (`./`, `../`, 3.3), so the
  pack works wherever it is mounted and nothing in it is rewritten when a game takes it.
- The index has `version`, a `///` doc, `#pack data` (id, name, semver version, licence, credit) and
  `export import` lines. A summary for readers without the engine (a YAML or JSON manifest) is
  generated from the pack reader's output (3.10), never written by hand beside it.
- A minimal valid pack is three files: `pack.manim`, one `.manim` with an exported programmable, and
  what it draws from. A pack made by hand is as valid as one a tool made; provenance records are
  annotations (3.10) a tool may add and the engine keeps and ignores.

### 3.2 Exports

- `#name export <kind>` marks a root block public. The kinds and what exporting means:

  | Kind | A host gets |
  |---|---|
  | `programmable` | placed by `staticRef`/`dynamicRef(external(pack), name, …)` or built by name |
  | `sounds`, `music` | its sounds/tracks, played by qualified name (3.5) |
  | `tileset`, `autotile`, `tilemap` | `tilemap(fill(external(pack), name, …))`, `builder.buildTilemap` through the import |
  | `palette` | `external(pack)` colour references, `replacePalette` |
  | `cursor` | its cursors, by qualified name or from the pack's own interactives |
  | `particles`, `animatedPath`, `curves`, `paths` | built by name through the import |
  | `data` | read by tools and by `@:data` codegen |
  | `font` (new, 3.5) | its fonts, by qualified name or from the pack's own text |

  A `mix` block is never exported: a game has one. A pack may export a `ui` bank, but it becomes the
  game's widget sounds only when the host installs it; importing it must not replace the game's.
- A file's blocks that are not exported are its implementation. The engine keeps letting
  `external()` reach them (existing files, and a pack's files reaching each other's helpers, need
  it). The pack reader reports, as an error of the pack, any reach from outside the pack's folder
  into a block that is not exported; the LSP offers only exports there and warns on such a reach.
- **Re-export.** `export import "./knight.manim" as knight` in an index makes that file's exports the
  index's. `external(ninja), knight` is looked up in the index's own blocks, then through its
  `export import`s in order. A name two re-exported files both export is an error of the index (at
  the reader, and at build when it is reached). A host imports one file per pack.
- `#preview` and `examples/` are never exported. A tool draws a file's `#preview` when it has one.

### 3.3 Resolving names

- **Relative names.** A name that starts with `./` or `../` is relative to the file that writes it;
  any other name is a host key, as today. This holds for every outside name: `import`,
  `sheet(…)` and a nine-patch's sheet, a tileset's `atlas:`, an autotile's `sheet:`/`file:`,
  `file(…)`, `stateanim("….anim")`, `extraPoint("….anim", …)`, a particle group's `animFile`, a sound's
  `file:`/`files:`, a track's `file:`, a font's file, and in `.anim` its `sheet:` and `file:`. The
  parser (or the builder, where the name is an expression) joins it with the writing file's own key,
  folds `.` and `..`, and refuses to leave the mount root. Loaders keep seeing plain keys, caches stay
  keyed by one spelling, and `ManimNeeds` lists the joined keys.
- **One loading path.** Every resource kind, `.anim` included, goes through the loader's
  `loadHXDResourceImpl` (today `.anim` alone reads the file system on HashLink).
- **Mounting** is the host's (H7): `CachingResourceLoader.mount(prefix, source)` with a folder or a
  zip as source; a key under `prefix` is read there. The engine ships the folder and zip sources.
- **Atlas aliases** (H7): a game that repacks a pack's frames into its own atlas gives the loader a
  table from `(sheet key, cell)` to `(sheet key, cell)`; `loadSheet2` then returns a view over the
  game's atlas under the pack's name, so the pack's files stay as they are and an update is a file
  swap.
- **Naming what is placed.** The canonical form is the bare name,
  `staticRef(external(ninja), knight, …)`. `$knight` means the parameter or loop variable `knight`
  and nothing else. A `$name` that is neither is a warning now (with the fix: drop the `$`), and an
  error from the format version that adds relative names (3.9), so an importer's parameter can never
  silently change what is placed. The docs and the LSP's snippets switch to the bare form now.

### 3.4 Signature and parts as data

A reader with no Heaps returns an export as plain data (`MultiAnimResultTools.exportsOf(result)`,
`signatureOf(result, name)`), the same data the LSP hover, the DevBridge and the pack reader show:

```haxe
typedef ExportInfo = {
    name:String, kind:String, doc:Null<String>, file:String, line:Int,
    params:Array<ParamInfo>,          // in declaration order
    parts:Array<PartInfo>,
    meets:Array<String>,
    annotations:Array<{name:String, args:Array<String>}>,
};
typedef ParamInfo = {
    name:String, type:String,         // "enum", "int", "uint", "float", "bool", "string", "color", "tile", "flags", ...
    choices:Null<Array<{value:String, doc:Null<String>}>>,
    min:Null<Float>, max:Null<Float>, step:Null<Float>,
    defaultValue:Null<String>,        // as written in the format: an enum by name, a colour as #rrggbbaa, true/false
    required:Bool,                    // no default (a tile parameter always)
    doc:Null<String>,
};
typedef PartInfo = {
    name:String, kind:String,         // "point", "slot", "interactive", "named", "setting", "anim-point", "area", "event"
    always:Bool,                      // false inside an @() arm, a @switch arm or a parameter-dependent repeat
};
```

- **The same answer on every target.** A reader runs on JS (the LSP, a browser host) and on
  HashLink (the game) and must read one file the same way. Today it does not: integer literals differ
  (PRS-26), an unnamed root element is a crash on one target and a node on another (PRS-27), and node
  names embed a target-specific dump of the payload (CG-38). Every reader output is tested on both.
- **Written form and position.** Defaults are stored resolved, which is right for building but loses
  the written form (a colour becomes an Int, a bool 0/1), and nodes and definitions carry no position
  outside `MULTIANIM_DEV` (PRS-31). The reader renders defaults back in the format's own spelling and
  every `ExportInfo`, `ParamInfo` and `PartInfo` carries a line and column; a node gets a stable id
  (an ordinal or its position) in place of `uniqueNodeName`.
- **What the reader checks without Heaps.** Today a plain parse passes files the builder refuses
  (PRS-32: a missing same-file target, an argument the target lacks, a `@final` shadowing a
  parameter, a shader argument typo), and the LSP keeps its own parameter scan, which disagrees
  with the parser (LSP-8). Those checks move into a post-parse pass the LSP and the pack reader share.
- **Types to add.** A float range (`size:0.0..2.0 = 1.0`, an optional `step`), so a choice that is a
  number says its range as the int range does. One parameter shape for programmables and the
  engine's shaders: `ShaderCatalog` already has type, default, range, step, unit and label, and a
  tool should draw a slider for either from the same data. A `string` parameter without `=` becomes
  required like every other type (today it silently defaults to `""`, PRS-36).
- **Parts** are listed from the parse: `#name` elements with their element kind, `slot`s, interactive
  ids, `point`s, root `settings` keys; for a programmable that plays an `.anim`, that file's
  animations, extra points, areas and events (3.8).
- **Stability.** Within a pack's major version: adding an export, a parameter with a default, a part,
  or an enum choice at the end is compatible. Removing or renaming an export, a parameter or a choice,
  changing a type, reordering choices, or removing a part a contract names is breaking. Choice order
  matters because codegen bakes a choice's index into the game's compiled code. Hot reload's
  `SignatureChecker` already compares two definitions; the reader offers
  `compareExports(old, new)` on top of it, so a pack update says "compatible" or lists what breaks.

### 3.5 Names a pack registers

- **Registered on every load path.** A file's `cursor`, `sounds` and `music` blocks are taken when
  the file is loaded at all, top level or through an import, and again when it is reloaded.
- **Scoped.** Each registered name is keyed by the file that declares it. A lookup from a file
  searches that file, then the files it imports (depth first, in import order), then the global
  registry. So a pack's `cursor => "pointer"`, its `.anim`'s `sounds { hit: "whoosh.slash" }` and
  its `font("m5x7")` find the pack's own first, and two packs' `m5x7` never meet. Code outside the
  pack names them qualified, by import alias or pack id: `audio.play("ninja:whoosh.slash")`,
  `CursorManager.getCursor("ninja:pointer")`.
- **Fonts in a file.** A `font` root block lets a pack carry its fonts:
  `#m5x7 export font("./fonts/m5x7.fnt", offset: 0, -1)`. Fonts are code-only today.
- **Not a pack's to register:** a `mix`, and (unless the host installs it) the `ui` bank. Custom
  filters stay code: a pack lists them as needs, and carries a shader's source as a typed file
  (H10) for the host to compile.

### 3.6 Needs

- **Per export, across imports, given values** (H9):
  `ManimNeedsTools.needsOfExport(read:String -> Null<String>, file, name, ?values:Map<String, String>)`.
  `read` returns a file's text by key, so imports are followed with no loader; only what `name`
  reaches is walked; a parameter given a value narrows conditionals and names to it.
- **More in the result:** `hostInputs` (callbacks, `builderParameter`s, placeholder sources,
  `$ctx.width`/`height`/`random`, custom filters), the keys as joined (3.3), and `formatVersion`, the
  lowest format version the reached syntax needs (3.9).
- **Two levels a reader reports:** *valid* (parses, every export's needs are in the pack or are host
  needs it declares) and *ready* (also meets its contracts and has its docs). Building every export
  with every choice needs Heaps; a headless HashLink checker in `hx-multianim-utils` does that part.

### 3.7 Contracts

1. **The widget contracts as engine data.** `bh.ui.WidgetContracts`, compiled with `-D noheaps`: for
   each widget the parameters it passes at build (the build refuses a design without them), the
   values it sets while running (a value the design's enum lacks is never drawn), the named parts it
   looks up (required, optional) and the settings it reads. A test holds every widget class to its
   row. Tools read this table instead of keeping a copy of their own.
2. **`@meets(button)`** on an export. The reader checks the signature and parts against the contract:
   a missing built parameter is an error, a missing running value or a part only inside an arm a
   warning. Reported, never refused beyond what the build already refuses.
3. **Declared contracts** (`#figure contract(...)` in a standard contracts file beside `std.manim`)
   if packs need shapes beyond the widgets (H4). The widget table of step 1 is written in that form
   then.

Appendix A is the contract each widget has today, read from the code. Four things stand in the way
of declaring it, and step 1 has to settle them first:

- **One widget's contract is spread over several classes**: the list's over `UIElementBuilder`,
  `UIMultiAnimScrollableList`, `UIMultiAnimScrollbar` and `UIScreen.addScrollableList`; the tabs'
  build parameters partly in `UIScreen.addTabs`. `ManimNeeds` keeps a second copy (to guess widget
  sounds) that has already drifted (UI-91).
- **It depends on settings and data**: `placeholderText` is passed only when the `placeholder`
  setting is set, `font`/`fontColor` only when the list is given them, `tabPanel.<key>` becomes
  `panel<Key>`, `contentRoot` names a part through a setting, list items' statuses include game data
  (`baseStatus`), `#scrollbar` is needed only once content overflows. A row has to say, per
  parameter: always, if declared, or if a setting is given.
- **"Has a part" means three things**: the drawn arm's (slider, scrollbar: `getNamedDrawn`), exactly
  one unconditional (text input: `getSingleItemByName`), or the first written (dropdown). A contract
  says "in every arm", "in some arm" or "exactly one".
- **Strictness varies**: values the builder is given pre-resolved skip the unknown-name check (UI-87),
  enum values are strict at build and loose in `setParameter` (UI-85), and slider and progress bar
  build lazily at the first `update()` (UI-86), so there is no construction moment to check at.
  Fix these with the table, so that the table can be the truth.

### 3.8 A figure's points, areas and events

- **Through the programmable** (H6), in both backends: `LiveProgrammable.point(name):Null<{x, y,
  angle}>`, in the programmable's own space after facing, flip, scale and rotation. It looks up the
  programmable's `#name point` elements, then the extra points of the state animations it plays
  (`body.hand` picks one when several have the name). Events of those animations reach a listener on
  the programmable (`addAnimEventListener`), so code never holds the `AnimationSM`.
- **In `.anim`** (H12): a direction on an extra point (`muzzle: 14, -9 dir 0`, degrees from the
  figure's forward, mirrored with `flipX`), a position per frame where it moves, and `areas { }` per
  animation or frame: rectangles, circles and polygons, each of a kind (`body`, `strike`, `use`, …),
  several of a kind.
- **Sound cues** (H13): `cues { hit: 60ms tail: 115ms }` on a sound, and the state machine starting
  an event's sound `hit` early so it lands on the event's frame.
- **What has to change first.** Today an extra point is an integer per animation and selector
  (`AnimationDescriptor.extraPoints: Map<String, IPoint>`); per frame, only a point event says where
  something is. Mirroring lives in four places that disagree: the tile flip (`maybeFlipClone`, per
  layer, ANM-16), the extra-point mirror in `load()`, the bounds (VFX-32), and none for point events
  (ANM-13); a figure facing left through `scaleX: -1` in `.manim` is a fifth. Directions would add a
  sixth unless one function mirrors a point (and an angle: 180° − θ on x, −θ on y) for a descriptor
  and every path calls it. A point is read today by building and playing a whole machine, sounds
  and all (ANM-14), and in the sprite's own space (ANM-18). So: a Heaps-free `.anim` parse with
  ordered states and a plain point type (ANM-19) first, then `pointOf(anim, selector, name, ?frame)`
  on the parse, then `LiveProgrammable.point` composing it with the element's transform.

### 3.9 Versions

- **The format.** `version: 1.N`: each syntax addition raises N. The parser takes any version up to
  its own and says "this file needs format 1.4; this engine reads up to 1.2" for a newer one.
  `ManimKeywordInfo` gives each keyword the version that added it, so a writer stamps the lowest
  version its file needs and the reader reports it (`formatVersion`). `.anim` gets the same header,
  optional, absent meaning 1.0.
- **The pack.** `version` in `#pack data` is semver; `compareExports` (3.4) decides whether an
  update is minor or major.

### 3.10 Tools

- **The pack reader** (H1): `PackReader.read(read:String -> Null<String>, indexKey):PackInfo`, with no
  Heaps: every export with its signature, parts, docs, `meets`, needs, contract results and the
  problems that keep the pack from valid or ready. `hx-multianim-utils` wraps it as a CLI that
  prints JSON; the LSP's hover and completion use it; the DevBridge answers `list_exports` from it.
- **Hot reload follows imports**: a change to a pack file rebuilds what imports it, and its
  registered names are taken again.
- **Annotations in `.manim`**: `@name(args)` before a root block, kept and never acted on, with a
  span per value, as `.anim` has them (`@from(...)`). Tool metadata (where cells were cut, which
  widget and style) then needs no `#asset data`-style side blocks. `@meets(...)` is the one the
  reader checks.

### 3.11 Not in the engine

Readers for Tiled, LDtk or Aseprite (a host's import converts them), the pack's zip and hub rules,
licence checks, provenance records beyond keeping annotations, cover pictures and previews made by a
tool, and searching a library of packs.

---

## 4. Requested changes

P1: needed before packs move between hosts. P2: needed for the format to be complete. P3: when a
genre or a host asks. IDs are this proposal's (`AF-n`); defects filed in the review file carry their
own IDs and are cited.

| ID | Change | Why | Where | P |
|---|---|---|---|---|
| AF-1 | Register an imported file's `cursor`, `sounds` and `music` blocks when its importer loads, and again on reload | a pack's index loads its files by import, so none of their cursors or banks exist today | `ScreenManager.buildFromResource`, `hotReloadFile`; walk `multiParserResult.imports` | P1 |
| AF-2 | Load `.anim` through `loadHXDResourceImpl` in the default loader | a pack's `.anim` and `.manim` resolve against different roots on HashLink, and a pak'd game cannot find its `.anim` files | `ScreenManager.createLoader` | P1 |
| AF-3 | A second `import` of an alias, an `import` outside the root, and `external(a)` with no import `a` are parse errors | a file's references are checkable from the parse; today an unknown alias fails only when its element is built | `MacroManimParser` import case, `STATIC_REF`/`DYNAMIC_REF`/tilemap/palette `external` sites | P1 |
| AF-4 | `$name` that is neither a parameter nor a loop variable: a warning with the fix; the docs and snippets use the bare name | an importer's parameter silently changes which export is placed | parser `validateRefTargetParam`, `docs/manim-reference.md`, `ManimKeywordInfo` snippets | P1 |
| AF-5 | Signature and parts as data (`ExportInfo`, `exportsOf`, `signatureOf`), no Heaps | every tool reads exports the same way; the LSP, DevBridge and pack reader share it | `MultiAnimResultTools` (in flight) | P1 |
| AF-6 | Re-export (`export import`) and lookup of `external(index), name` through it; first the cross-file ref fixes it rests on: arguments resolved by the caller (BLD-34), `tile`/`flags`/arrays passed through (BLD-35), codegen's cycle guard per file (CG-41) and the target's own types (CG-42) | a host imports one file per pack; without the fixes even a hand-written wrapper in an index fails | parser, `importedBuilder`, `buildWithParameters`, `ProgrammableBuilder`, codegen ref lowering | P1 |
| AF-7 | Pack reader: private reaches across a pack boundary, duplicate export names, missing docs | the export marker means something only if something checks it | new `PackReader` (no Heaps), LSP diagnostics | P2 |
| AF-8 | Relative names (`./`, `../`) for every outside name, in `.manim` and `.anim` | a pack works wherever it is mounted; nothing is rewritten on a take | parser/builder name resolution, `AnimParser`, `ManimNeeds` | P2 |
| AF-9 | Format versions `1.N`, per-keyword `since`, a clear error for a newer file; optional `.anim` header | a host can tell "needs a newer engine" from "broken"; a pack says what it needs | parser `parse()`, `ManimKeywordInfo`, `AnimParser` | P2 |
| AF-10 | Scoped registered names (file, its imports, global) and qualified names for code | two packs' `m5x7`, `pointer` or `whoosh` no longer collide | `FontManager`, `CursorManager`, `Audio`, builder lookups | P2 |
| AF-11 | A `font` root block | a pack carries its fonts | parser, builder, `ManimNeeds` | P2 |
| AF-12 | `needsOfExport` across imports, given values, with host inputs and `formatVersion` | a take packs exactly what its choices reach | `ManimNeeds` | P2 |
| AF-13 | `WidgetContracts` table, tested against the widgets; `@meets` checked by the reader | tools stop keeping their own copy of the contracts | `src/bh/ui/`, `PackReader` | P2 |
| AF-14 | Hot reload follows imports | editing a pack file shows in every example and game that imports it | `ScreenManager.hotReload`, `HotReload` | P2 |
| AF-15 | Float range parameter type, and one parameter description shared with `ShaderCatalog` | "a number with a range" is part of a signature; sliders for shaders and programmables alike | parser, builder, codegen, `ShaderCatalog` | P2 |
| AF-16 | Annotations on `.manim` root blocks, with spans | tool metadata and provenance without side blocks | parser, `MultiAnimResult` | P3 |
| AF-17 | `LiveProgrammable.point(name)` and animation events through the programmable | code uses a figure's points without its state machine | `LiveProgrammable`, builder, codegen | P3 |
| AF-18 | Directional and per-frame extra points, `areas` | bullets leave the right way; hitboxes move with the art | `AnimParser`, `AnimationSM` | P3 |
| AF-19 | Sound cues and early start | the hit lands on the frame | `sounds` block, `Audio`, `AnimationSM` | P3 |
| AF-20 | `file(…)` root block (typed file, loaded as bytes) | any 2D asset can be exported | parser, `ManimNeeds`, loader | P3 |
| AF-21 | Loader mounts (folder, zip) and an atlas alias table | a game outside a library host mounts packs the same way | `CachingResourceLoader` | P3 |

**Order.** AF-1 to AF-4 are fixes and can go now, each with a test, together with the cross-file
ref fixes of AF-6 (BLD-34, BLD-35, CG-41, CG-42) and the two target-dependence bugs a reader would
inherit (PRS-26, CG-38). AF-5 and the rest of AF-6 build on the `export` work in flight. AF-8 and
AF-9 go together (relative names are the first syntax under a new format version). AF-10 and AF-11
together. AF-12 after AF-6 and AF-8, with a decision on CG-43 (codegen building every arm), since a
pack trimmed to "what these values need" is only safe if codegen stops loading hidden arms. AF-13
after AF-5. AF-14 includes the importers' stale import maps (IMP-9). The P3 rows follow the hosts
that ask for them.

## 5. On the `export` / `///` work

It is the right first step and landed as written. For what follows:

- Keep "an import still reaches every block" in the engine; put the meaning of `export` in the reader
  and the LSP (AF-7) rather than refusing at build.
- Define what exporting each kind means (the table in 3.2) in `docs/manim-reference.md`, so a
  `#ui export sounds` does not read as "this replaces the game's widget sounds".
- `MultiAnimResultTools` is the right home for `exportsOf`/`signatureOf` (AF-5); `docOf` becomes a
  field of `ParamInfo` and `ExportInfo`.
- Docs where the plan needs them next: a `data` record's fields, a `sounds` block's sounds, a
  tileset's terrains, and in `.anim` its animations, states and extra points.
- The LSP's completion after `external(x),` should list the imported file's exports first, with their
  docs.

## 6. Open questions

1. A reach into a block that is not exported, from outside the pack: an error of the pack check
   only (proposed), or a build error too?
2. Qualified names in code: `ninja:whoosh.slash` (proposed) or `ninja.whoosh.slash`, which reads like
   a bank named `ninja`?
3. `@meets(button)` as an annotation (proposed: the engine does not act on it) or a keyword?
4. Relative names only with `./` (proposed, nothing existing changes meaning), or bare names relative
   inside a pack too?
5. Float range syntax: `0.0..2.0` (proposed, as the int range) or `float(0, 2, step: 0.1)`?

---

## Appendix A. The widget contracts as the code has them (`98105cc`)

"+ pass" means every screen setting the widget does not consume goes to the build, where an
undeclared one throws. Builds are incremental unless marked. **Bold** runtime values are written
though no documented enum lists them.

| Widget | Passed at build | Passed only when | Set while running | Parts, callbacks, placeholders | Root settings read | Screen settings | Events |
|---|---|---|---|---|---|---|---|
| Button | `buttonText`, `status`=normal, `disabled`="false" + pass | — | `status` normal/hover/pressed/**disabled**; `disabled` if declared; `buttonText`; `setStyleParameter` | — | `sound.hover`, `sound.click` | `buildName`, `text` | UIClick, UIHover |
| Checkbox | `status`, `disabled`, `checked` + pass | — | `status` +**disabled**; `checked`; `disabled` if declared | — | `sound.toggle` | `buildName`, `initialValue` | UIToggle (initial sync sends UIChangeValue, UI-92) |
| Radio group (not incremental) | container `count:int` + pass; each radio has the checkbox contract, no settings reach it | — | per radio, as checkbox | `callback("checkbox", $i)` (other names throw); `callback(n, $i)` text is the item's name | — | `radioBuildName`, `radioButtonBuildName` | UIChangeItem (+ the child's UIToggle, UI-77) |
| Tabs (bar not incremental), tab button | bar `count`; button `status`, `disabled`, `checked`, `buttonText` + `tabButton.*` | bar `tabButtonHeight` (always through `addTabs`), `panel<Key>` per `tabPanel.<key>` | tab `status` +**disabled**, `checked`; `disabled` if declared | `callback("tabButton", $i)` (others throw); `#<contentRoot>` when `tabPanel.contentRoot` is set | — | `buildName`, `tabButtonBuildName`, `tabButton.*`, `tabPanel.*` | UIChangeItem |
| Slider (built at first update) | `status`, `size:int`, `value` 0..100 (internal scale), `disabled` + pass | — | `status` normal/hover/pressed (never disabled); `value`; `disabled` if declared | `#start`, `#end` of the drawn arm (missing: silently dead) | `sound.change` | `buildName`, `size` (200), `min`, `max`, `step`, `direction` (auto) | UIChangeValue, UIChangeFloatValue |
| Progress bar (built at first update) | `value` 0..100 + pass | — | `value` (whole rebuild after `untracked_param`) | — | — | `buildName` | (initial sync UIChangeValue) |
| Scrollbar | `panelHeight`, `scrollableHeight`, `scrollPosition` + pass | `status`=normal, `disabled`=false, `direction`, each if declared (the widget needs `status`) | `status` normal/hover/pressed; `scrollPosition`; `panelHeight`/`scrollableHeight`; `disabled` if declared | `#thumb` (throws without); `#track`, `#up`, `#down` optional | `arrowStep`, `scrollSpeed` | `buildName`, `direction` (vertical; no auto), `arrowStep` | UIChangeValue |
| Scrollable list: panel (not incremental) | `width`, `height`, `topClearance` (other settings dropped, UI-82) | — | — | `builderParameter("mask")` (never checked); one `#<scrollbarInPanelName>` (checked on overflow) | — | `panelBuildName`, `itemBuildName`, `scrollbarBuildName`, `scrollbarInPanelName`, `panelMode`, `width`, `height`, `topClearance`, `scrollSpeed`, `doubleClickThreshold`, `wheelScrollMultiplier`, `clickMode`, `item.*`, `scrollbar.*`; bare `font`/`fontColor` to the item | UIChangeItem, UIClickItem, UIDoubleClickItem (+ the scrollbar's UIChangeValue, UI-77) |
| ↳ list item | `itemWidth`, `index`, `title`, `status` (baseStatus ?? normal), `selected`="false", `disabled`, **`images`** + `item.params` + `item.*` + bare `font`/`fontColor` | `tile` (pre-resolved; dropped if undeclared) when the item has one | `status` normal/hover/pressed/**disabled**/baseStatus; `selected` | every interactive's id must be the item's index | `height` (float, required) | — | — |
| ↳ list scrollbar | `panelHeight`, `scrollableHeight`, `scrollPosition` | as Scrollbar | `scrollPosition`; the whole Scrollbar row when the design has `status` and `#thumb` | — | `scrollSpeed` | — | — |
| Dropdown button | `status`=normal, `panel`=closed + `dropdown.*` + bare `font`/`fontColor` | — | `status` +**disabled**; `panel` open/closed | `#panelPoint` (constructor throws); `#selectedName` text (first change throws); callbacks `selectedName`, `itemName` (others throw) | `transitionTimer`, `sound.open`/`close`/`change` | `dropdownBuildName` + the list's; `autoOpen`, `autoCloseOnLeave`, `closeOnOutsideClick`, `transitionTimer`; 120×300 default | UIChangeItem (twice, UI-77), UIOpen, UIClose |
| Text input | `status`=normal, `placeholder`="true" + pass | `placeholderText` when the `placeholder` setting is non-empty | `status` normal/hover/**focused**/disabled; `placeholder`; `disabled` if declared | exactly one `#textArea` | — | `buildName`, `text`, `placeholder`, `font`, `fontColor`, `cursorColor`, `selectionColor`, `maxLength`, `multiline`, `readOnly`, `disabled`, `filter`, `tabIndex`, `inputWidth` | UITextChange, UITextSubmit, UIFocusChange |
| Grid cell (`DefaultCellVisualFactory`) | `col`, `row`, `<highlightParam>`="none", `<statusParam>`="normal" + delegate params + extras | — | highlight none/accept/reject (or the delegate's); status normal/hover | — | — | code config (`cellBuildName`, `highlightParam`, `statusParam`); grid `originX/Y`, `swapPathName`, `swapEnabled` | GridEvent |
| OkCancelDialog | `dialogText` | — | — | `builderParameter("ok")`, `builderParameter("cancel")` (button contract); `#dialogText` required, unused | `overlay.*` | — | exit response; Enter/Esc (UI-76) |
| Interactive (`addInteractives`) | — | — | the `autoStatus`/`bind` parameter: normal/hover/pressed/disabled (undeclared: throws at the first event) | — | metadata `events`, `eventPriority`, `cursor`, `cursor.hover`, `cursor.disabled`, `autoStatus`, `bind`, `sound.click` | — | UIInteractiveEvent |
