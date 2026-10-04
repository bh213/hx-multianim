# Proposal B: tilesets and tile maps in `.manim` — built

Written 2026-09-30 and built the same day in the working tree, not committed. The docs describe it
as built: `docs/manim.md` "Tilesets and Tile Maps", `docs/manim-reference.md`, `docs/devbridge.md`
(`map_list`, `map_get`), `TECHNICAL-DOCS.md` "Tile maps", `CHANGELOG.md`.

Changed from the proposal, with the user: nothing particular to an art pack is built in. Heights are
the tileset's `edge` and `rise n { side left right single span toward }` (not cliff/rim/face/tall, and a side may face any
way); what a cell means to the game is generic `metadata { }` on a terrain, a rise or a `cell name { }`,
written and read as settings are (`key:type => value`; `metadataAt` is a `BuilderResolvedSettings`)
(no `walk`, `joins` or `over` lists); a layer names its own `sheet:` and `draw: under | over | top`
(no special `shadows` layer). A layer has one cell a square, so shadows never overlap and are drawn as
they are, not flattened into a texture.

Tests: `TilemapTest`, visual test 155, DevBridge built-in ops list.

Added 2026-10-01: `transition a, b { autotile }` for a pair's own edge tiles; several tiles per
autotile index (`mapping: [15: 7 | 8 | 9]`, drawn by position); `levels { legend { "A": 10 } rows }`
beyond nine.

Added 2026-10-02: flips and quarter turns in `mapping:` (`1 flipX rot90`); `margin:` and `spacing:`
on a `file:` source; objects of several cells (`cell tree { size: 2, 3 anchor: 1, 2 }`, among the
actors on their feet, their name and metadata on every cell they cover, `objectAt`, inside the map
and over no other); the map drawn in chunks, each as it is first in view (`cull(x, y, w, h)` or the
scene), a change redrawing its chunk. Playground demos "Tile Map" and "Layers in .anim".

Added 2026-10-04: a chunk costs its own size wherever it is (chunk-local masks, `buildAutotile`'s
origin), per-cell level and platform arrays, lookups once a name, sides numbered along a run in one
pass, metadata shared a combination; `sideAt` / `metadataAt` work a chunk out without drawing it.

Not done, by how many tilesets each blocks: Wang 2-edge and 3-corner formats; a shared `shape:`
vocabulary for collision (full, slopes, half, one-way); inner-corner side pieces where two cliffs
meet; layer `offset:` and `parallax:`; hex and isometric cells (the map is square-cell only); a
run-length or other compact form for very big maps; an importer from Tiled and LDtk in
hx-multianim-utils; marks and regions as data-block tables; where each row is written, for a tool
(the parse keeps it only for its own errors); objects culled with their chunk (they are among the
actors, so every one is drawn).
