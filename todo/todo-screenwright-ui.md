# UI art requests from Screenwright (2026-10-10)

Seven things Screenwright's art import needs from the engine so that UI art adopted from a pack
(buttons, panels, dialogs, cursors, scrollbars, sliders) can be used by a game with nothing written
by hand. Asked for in `../screenwright/HX-MULTIANIM-REQUESTS.md`, items 4 to 10; this file is the
working copy for whoever builds them here. Each item says why, where in the code, what to change,
and how to know it is done. They are independent; the order below is by how much each unblocks.

**Where the asker's code is.** Screenwright writes every adopted control as a programmable to the
contracts in `src/bh/ui/` (`../screenwright/packages/animc/src/adoptKit.ts`, whose header lists
the contracts as it read them) and tries them on a bench built with the real widgets
(`../screenwright/packages/runtime/src/sw/Bench.hx`). When a contract here changes, those two are
the consumers to tell (a note in the CHANGELOG entry is enough; nothing here should know about
Screenwright).

**House rules that apply.** Nothing specific to any art pack goes in. A new `.manim` syntax goes
through `MacroManimParser`, `ManimKeywordInfo`, the codegen (`ProgrammableCodeGen`), the LSP
keyword list (the CI drift gate compares them) and `docs/manim-reference.md`. Every item ends
with a test under `test/`, a line in `CHANGELOG.md`, and the matching doc (`docs/manim.md`,
`docs/manim-reference.md`, `.claude/rules/ui-components.md`). The `precommit` skill runs these.

---

## 1. A nine-patch that stretches, beside one that tiles

**Done (2026-10-10).** Parser (`stretch`/`tile`, `settings { ninepatch => … }`, `flow(background: ninepatch(…, tile))`), builder, codegen, tile group, LSP, grammar, docs. `NinePatchModesTest`, visual test 157.

**Why.** `ninepatch()` builds an `h2d.ScaleGrid` with `tileCenter = true` and `tileBorders = true`
(`MultiAnimBuilder.hx`, `case NINEPATCH`; the same in `ProgrammableCodeGen.hx`), so every panel's
edges and middle are repeated. UI packs are drawn to be stretched as often as tiled: a gradient
fill, a bevel along the edge, a glow that fades inward all show a seam at every repeat. The atlas
`split:` comes from TexturePacker, where it means stretch. Today there is no way to say which a
panel wants, and Screenwright writes every adopted panel, button, tab, bar and dialog as a
`ninepatch`, so every one tiles. A `flow` `background: ninepatch(...)` already stretches (Heaps
`Flow` defaults), and a ninepatch inside a `tilegroup` uses `scaleToSize`, so the engine is
inconsistent with itself.

**What.** A per-ninepatch mode, default unchanged (tile):

```
ninepatch("ui", "panel", 200, 100)            // tiles, as today
ninepatch("ui", "panel", 200, 100, stretch)   // ScaleGrid with tileCenter = tileBorders = false
ninepatch("ui", "panel", 200, 100, tile)      // explicit
```

Also accepted as a settings key on the programmable (`settings{ninepatch=>stretch}`) so a kit can
set it once for every ninepatch in it; the element's own word wins. The same word on
`flow(background: ninepatch(..., tile))`, since that one stretches by default.

**Where.** `MacroManimParser.hx` (the `ninepatch(` arguments, around the `NINEPATCH` case and the
flow background parse), `MultiAnimParser.hx` (`NINEPATCH(sheet, tilename, w, h)` gains a mode),
`MultiAnimBuilder.hx` (`case NINEPATCH`, `load9Patch`, the flow background), `ProgrammableCodeGen.hx`.

**Done when.** A visual test draws the same split cell both ways side by side; `ManimParserTest`
covers the three spellings and a wrong word's error; `docs/manim.md` "Nine-patch" says which is
the default and why.

## 2. A nine-patch's sheet and cell as parameters

**Done (2026-10-10).** Both string expressions; the incremental builder and codegen reload the cell on `setParameter`; the missing-cell error names the sheet and the cell. `NinePatchModesTest`.

**Why.** `ninepatch(sheet, tile, w, h)` takes its sheet and cell as literal strings only
(`MacroManimParser.hx`, the `NINEPATCH` case), where `bitmap(sheet($a, $b))` takes references.
A game's UI theme is one `.manim` whose `#button`, `#checkbox`, `#tabBar`, `#textInput` and the
rest the widgets build by their default names. With the names as literals, a kit with three
button styles is three copies of the button programmable; with them as parameters, it is one:

```
#button programmable(style:string="raised", status:[normal, hover, pressed]=normal, ...) {
  @(status=>hover) ninepatch("ui", "button_" + $style + "_hover", $width, $height);
  ...
}
```

**What.** `ninepatch($sheet, $tile, w, h)`, `ninepatch("ui", $tile, w, h)` and string expressions
in either place, resolved as `bitmap(sheet(...))` resolves them. Incremental builds
(`setParameter("style", ...)`) must rebuild the ScaleGrid's tile.

**Where.** `MacroManimParser.hx` (parse the two as `tileSource`-like references rather than
`String`), `MultiAnimParser.hx`, `MultiAnimBuilder.hx` (`load9Patch` from a resolved value; the
incremental path that tracks which parameters an element depends on), `ProgrammableCodeGen.hx`.

**Done when.** A test builds a programmable twice with two styles and gets two different tiles;
`setParameter` on the style changes the drawn cell; the error for a cell that is not in the sheet
still names the sheet and cell.

## 3. A bitmap cursor from an atlas cell

**Done (2026-10-10).** Both: `CursorManager.registerTileCursor(name, tile, hotX, hotY)` and the `#name cursor { }` block, registered by `ScreenManager.buildFromResource`. On JS `hxd.System.setCursor` makes a CSS `url(data:…)` cursor from the `CustomCursor` frames, so the same pixels show in the browser. DevBridge/MCP `list_cursors`. Playground `cursors` demo. `CursorTest`.

**Why.** `CursorManager` (`src/bh/base/CursorManager.hx`) knows the OS cursors by name
(`default`, `pointer`/`button`, `move`, `text`, `hide`/`none`, `resize-*`) and takes a custom one
only as an `hxd.Cursor.Custom(CustomCursor)` built in Haxe. UI packs ship cursors (an arrow, a
hand, a sword), and Screenwright adopts them as named cells with the point that clicks; a game
cannot use them without code of its own per cursor.

**What.** Either or both:

- `CursorManager.registerCursor(name:String, tile:h2d.Tile, hotX:Int, hotY:Int)` building the
  `CustomCursor` from the tile's pixels, so a game does it in one line from an atlas.
- A `.manim` block the screen manager registers when the file loads:

  ```
  #cursors cursor {
    pointer: sheet("ui", "hand"), hot: 3, 1
    sword:   sheet("ui", "sword"), hot: 1, 1
  }
  ```

  A registered name then works wherever an OS cursor name does: an interactive's `cursor.hover`
  and `cursor.disabled` metadata, `setCursor(name)`.

**Where.** `CursorManager.hx`; for the block, the parser (a new root element, `ManimKeywordInfo`,
LSP), `ScreenManager` where files are loaded, `docs/manim.md`.

**Done when.** A playground demo shows an atlas cursor over a button; a test registers a tile
cursor and asks for it by name; on the JS target the cursor is a CSS cursor from the tile's
pixels (check `hxd.System.setCursor` does that for `Custom`; if not, say what the JS target does).

## 4. The progress bar's contract, and a component for it

**Done (2026-10-10).** Contract in `docs/manim.md`; `std.manim` `#progressBar` from the `ui` atlas (used by the playground demo); `setIntValue` changes `value` in place, a rebuild only once the design throws `untracked_param`. `UIScrollbarWidgetTest`.

**Why.** `UIMultiAnimProgressBar` builds a programmable named `progressBar` with `value` and
rebuilds it whole on every change (`.claude/rules/ui-components.md` says so: display-only, full
rebuild because `generated(color(...))` is not tracked). `std.manim` has no `#progressBar`; the
playground's demo draws one from `generated(color)`. Screenwright writes a bar as
`value:0..100, width, height` with a track and a fill stretched to the value, which is a guess at
what the widget wants, and a bar that is rebuilt on every frame it fills is a cost a HUD notices.

**What.** The contract written down with the others in `docs/manim.md` "UI Components" (which
parameters are passed: `value` certainly, `width`/`height` if they are); a `#progressBar` in the
playground's `std.manim` drawn from the `ui` atlas (`ON_1x3_*` or a `Sliderbar_H_3x1` track with
a fill); and `setValue` updating the built programmable's `value` incrementally when the design
has no untracked `generated(...)`, falling back to a rebuild when it has.

**Where.** `src/bh/ui/UIMultiAnimProgressBar.hx`, `hx-multianim-playground/public/assets/std.manim`,
the docs.

**Done when.** The playground's progress demo uses `#progressBar`; a test sets the value 100
times and the builder result is the same object throughout.

## 5. A scrollbar that is dragged, and a vertical slider

**Done (2026-10-10).** `UIMultiAnimScrollbar` (track, `#thumb`, `#up`/`#down`, paging, horizontal); lists and dropdowns use it when the scrollbar design has `status` and `#thumb`, the old contract still works; `slider.direction` / `settings { direction => vertical }` with `Auto` reading `#start`/`#end`. `std.manim` `#scrollbar` is dragged now (`#scrollbarStatic` is the old one), `#sliderVertical`. `UIScrollbarWidgetTest`.

**Why.** A list's scrollbar (`#scrollbar` with `panelHeight`, `scrollableHeight`,
`scrollPosition`) only shows where the list is: it is not dragged, has no track and no arrow
buttons, and is vertical only. `UIMultiAnimSlider` reads `localPos.x`
(`UIMultiAnimSlider.hx`, the drag handler) and is horizontal only. UI packs come with a
scrollbar's track, thumb and arrows, and with vertical sliders (`Sliderbar_V_1x3` is in
`test/res/ui.atlas2` and nothing draws it); Screenwright adopts those cells and can write no
control for them.

**What.**

- A scrollbar widget: a track, a thumb with `status` normal/hover/pressed and `disabled`, optional
  `up`/`down` arrow buttons as placeholders, dragged and clicked on the track, horizontal or
  vertical; `UIMultiAnimScrollableList` and `UIMultiAnimDropdown` take it in place of the
  position-only one through a setting (`scrollbar.buildName` as now), keeping the old contract
  working for files that have it.
- `direction` on the slider (`settings{direction=>vertical}` or read from `#start`/`#end`: when
  they differ in y and not in x, it is vertical), the drag reading `localPos.y`.

**Where.** `UIMultiAnimScrollableList.hx` (the scrollbar's build and `setParameter("scrollPosition")`),
a new `UIMultiAnimScrollbar.hx`, `UIMultiAnimSlider.hx`, `std.manim`, `docs/manim.md`.

**Done when.** The playground's list demo scrolls by dragging the thumb; a vertical slider demo;
tests for both; the old `#scrollbar` contract still passes its tests.

## 6. A window with a title bar and a close button (not done, by decision)

**Why.** `ScreenManager.modalDialog` and `screens/OkCancelDialog.hx` take a dialog programmable
with `dialogText` and `ok`/`cancel` placeholders; nothing takes a title or a close button, though
every UI pack has them (`Window_tabbed_3x3_*`, `WindowIcon_Close_3x3_*` are in the test atlas).
Screenwright writes a `dialog` to the OkCancelDialog contract and its close button as a button of
its own, `<name>_close`, which a game has to place by hand at the dialog's `#closeAt` point.

**What.** `OkCancelDialog` (or a `WindowDialog` beside it, if the two-button one should stay
minimal) filling a `close` placeholder when the programmable declares one, treating it as Cancel;
a `title:String` argument set on a `#dialogTitle(updatable)` text when the programmable has one;
both optional, so existing dialogs are unchanged.

**Where.** `src/screens/OkCancelDialog.hx`, `ScreenManager.modalDialog`, `std.manim`'s
`#okCancelDialog` (whose `#dialogText` colour `#ffffff00` is transparent today and should be
white), `docs/manim.md` "Dialogs".

**Done when.** A playground dialog demo has a title and a close button that cancels; a test
builds a dialog with and without the two and both work.

## 7. Several frames of a nine-patch

**Done (2026-10-10).** `index: n` and `fps: n` (`bh.base.AnimatedScaleGrid`, stepped from `sync`). `NinePatchModesTest`, visual test 157 (the four frames).

**Why.** `load9Patch` takes frame 0 of a region (`Atlas2.hx`); the `Button_Warning_3x3_*` regions
of the test atlas have four frames each and do not animate. A button that pulses or a panel
whose border shimmers is a run of nine-patch frames, and packs draw them.

**What.** `ninepatch("ui", "button", w, h, fps: 8)` playing the region's frames in a loop, or an
index parameter (`ninepatch("ui", "button", w, h, index: $frame)`) a game or a `stateanim` drives.
The second is the smaller change and composes with item 2.

**Where.** `Atlas2.hx` (`load9Patch` by index), `MultiAnimBuilder.hx`, the parser, codegen, docs.

**Done when.** A visual test shows the warning button animating; a test asks for index 3 and
gets the fourth frame's tile.

---

## Order

1 and 2 first: every adopted panel tiles today, and a theme file is a copy per style without 2.
Then 6 and 3 (a dialog and a cursor are what a game's first screen needs), then 4, 5, 7.

## Not asked

A theme or skin mechanism in the engine (swap all UI art at once) is not asked for: with item 2,
a theme is a `.manim` of the default programmable names over one atlas, and that is enough.
Nothing about how art is cut, named or imported belongs here.
