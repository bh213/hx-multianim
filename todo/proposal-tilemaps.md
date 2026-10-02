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

Not done, by how many tilesets each blocks: flip and rotate in `mapping:` (packs that ship 4 or 5
tiles and expect mirroring); multi-cell objects in a layer (`cell tree { size: 2, 3 anchor: 1, 2 }`,
sorted by their feet); `spacing:` and `margin:` on `file:` sources and grid atlases; Wang 2-edge
and 3-corner formats; a shared `shape:` vocabulary for collision (full, slopes, half, one-way);
inner-corner side pieces where two cliffs meet; layer `offset:` and `parallax:`; hex and isometric
cells (the map is square-cell only); chunked drawing with culling and a redraw of the chunk a change
touches; a run-length or other compact form for very big maps; an importer from Tiled and LDtk in
hx-multianim-utils; marks and regions as data-block tables; where each row is written, for a tool
(the parse keeps it only for its own errors).
