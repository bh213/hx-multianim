package bh.base;

import bh.base.TileGrid.TileGridKind;
import bh.multianim.BuilderError;
import bh.multianim.MultiAnimBuilder.BuilderResolvedSettings;
import bh.multianim.MultiAnimParser.AutotileFormat;
import bh.multianim.MultiAnimParser.ParsedSettingValue;
import bh.multianim.MultiAnimParser.ResolvedSettings;
import bh.multianim.MultiAnimParser.SettingValue;
import bh.multianim.MultiAnimParser.TilemapDef;
import bh.multianim.MultiAnimParser.TilemapLayerDef;
import bh.multianim.MultiAnimParser.TilemapMarkDef;
import bh.multianim.MultiAnimParser.TilesetCellDef;
import bh.multianim.MultiAnimParser.TilesetDef;
import bh.multianim.MultiAnimParser.TilesetRiseDef;

/**
	What a tile map is drawn from, given by the builder that owns its tileset.
**/
typedef TileMapTiles = {
	/**
		The TileGroup of an autotile over a grid (`grid[y][x]`, non-zero is the terrain) whose `[0][0]`
		is the map's cell (`x0`, `y0`), drawn at every position or only those set in `where` (the
		autotile's own positions: corners for the corner format, cells otherwise; the same origin).
		Both may be sparse: empty rows, rows that stop short, a missing cell being 0; a map gives the
		grid of the cells around the chunks it draws and no more, so a chunk costs its own size
		wherever it is in the map.
	**/
	var autotile:(name:String, grid:Array<Array<Int>>, where:Null<Array<Array<Int>>>, x0:Int, y0:Int) -> h2d.TileGroup;

	/**
		The same over the isometric or hex grid a map's tileset says: each tile put on its cell (or
		corner) as the grid puts a frame (`TileGrid.frameX`). A map off the square grid uses this.
	**/
	var ?autotileOn:(name:String, grid:Array<Array<Int>>, where:Null<Array<Array<Int>>>, x0:Int, y0:Int, on:TileGrid) -> h2d.TileGroup;

	/**
		The tile an autotile draws for an index at map cell (x, y) (the one of several its position
		picks), flipped as its mapping says and unturned, with the size of the frame it was cut from;
		null where it draws nothing. A map off the square grid draws its ground tile by tile with it,
		back to front, and lifted autotiles (a level's edge, a platform's top) on its raised cells.
	**/
	var ?autotileTile:(name:String, index:Int, x:Int, y:Int) -> Null<MapFrame>;

	/** An autotile's format, which says what its positions are; throws for a name the file has not. **/
	var autotileFormat:(name:String) -> AutotileFormat;

	/** The frames of a name in a sheet, each placed in its untrimmed frame (`TileMap.frameOf`), or null when the sheet has no such name. **/
	var frames:(sheet:String, name:String) -> Null<Array<MapFrame>>;

	/**
		The frames of a name in a layer's own sheet (`sheet:` in the layer), found from the file that
		writes the map, where the tileset's atlas is found from the tileset's; `frames` when not given.
	**/
	var ?layerFrames:(sheet:String, name:String) -> Null<Array<MapFrame>>;

	/** A terrain's, a rise's or a cell's metadata, resolved as settings are; null when it has none. **/
	var metadata:(parsed:Map<String, ParsedSettingValue>) -> ResolvedSettings;
}

/**
	A frame a map puts on a cell: its tile, drawn from (`tile.dx`, `tile.dy`) of the frame it was cut
	from, and that frame's size. A packer that trims an atlas's frames to their pixels (`offset:` and
	`orig:`, as TexturePacker writes them) leaves a tile smaller than its frame: placed so, it is drawn
	where the whole frame would be, and stands on its cell by the whole frame's size off the square grid.
	`TileMap.frameOf` makes one of an atlas frame, `TileMap.tileFrame` of a tile drawn whole.
**/
typedef MapFrame = {
	final tile:h2d.Tile;
	final width:Int;
	final height:Int;
}

/** A rectangle of cells, `x1` and `y1` one past the last. **/
private typedef CellRect = {x0:Int, y0:Int, x1:Int, y1:Int};

/** A rectangle of the map's pixels, as `cull` is given one. **/
private typedef PixelRect = {x:Float, y:Float, w:Float, h:Float};

/**
	What a layer has at a cell, as `objectAt` says it: the cell's name, the anchor cell the layer's
	character is at, and the cells it covers (`x`, `y` its top-left, `width` by `height`; one by
	one for a cell of one).
**/
typedef TilemapObject = {
	final name:String;
	final anchorX:Int;
	final anchorY:Int;
	final x:Int;
	final y:Int;
	final width:Int;
	final height:Int;
}

/**
	A character of a layer's legend, resolved once as the rows are read, so a cell drawn costs no
	lookup: what it draws, where about its cell (`draw`, the anchor of an object of several cells),
	its tileset cell and that cell's metadata.
**/
private typedef LayerEntry = {
	final name:String;
	final frames:Array<MapFrame>;
	final draw:String;
	final anchorX:Int;
	final anchorY:Int;
	final cell:Null<TilesetCellDef>;
	final metadata:ResolvedSettings;
}

/**
	A terrain as the ground off the square grid draws it, in a chunk: its frames, or its autotiles (one,
	or one an animation frame) with its mask, where it draws and its transitions (an autotile a frame
	each too).
**/
private typedef GroundPlan = {
	final terrain:Int;
	final frames:Null<Array<MapFrame>>;
	final autotiles:Array<String>;
	final format:AutotileFormat;
	final mask:Null<Array<Array<Int>>>;
	final where:Null<Array<Array<Int>>>;
	final transitions:Array<GroundTransition>;
}

/**
	A transition as the ground off the square grid draws it: its autotiles (one a frame), where it
	draws, and the mask they are indexed over (the terrain's own, its ignored terrains' cells added).
**/
private typedef GroundTransition = {
	final autotiles:Array<String>;
	final format:AutotileFormat;
	final where:Array<Array<Int>>;
	final mask:Array<Array<Int>>;
}

/** The step from a cell to its neighbour toward a side, as `TileMap.towardStep` says it. **/
typedef TowardStep = {
	final dx:Int;
	final dy:Int;
}

/**
	A square of the map drawn on its own, so a change is drawn again where it is and only that, and
	what is off screen is not drawn at all. What it draws is in its parts of the map's passes.
**/
private class Chunk {
	public final rect:CellRect;
	/** Its part of each of the map's passes, by the pass's index: null until it draws there. **/
	public final parts:Array<Null<h2d.Object>>;
	/** Objects of several cells anchored in this chunk, among the actors. **/
	public var objects:Array<h2d.Object> = [];
	/** An animated terrain's frames in this chunk, by the terrain's index. **/
	public var animated:Array<{terrain:Int, frames:Array<h2d.Object>}> = [];
	/** Its tiles are to be drawn again. **/
	public var dirty = true;
	/** Its cells' sides and metadata are as the rows are now; worked out without drawing when asked. **/
	public var resolved = false;
	/** In view, after culling: its parts and objects are shown. **/
	public var shown = true;

	/** Its place in the map's chunks, row by row: the order its parts keep in a pass off the square grid. **/
	public var index = 0;

	public function new(rect:CellRect, passes:Int) {
		this.rect = rect;
		parts = [for (_ in 0...passes) null];
	}
}

/**
	A tile map (`#name tilemap { … }` in a .manim), drawn from its tileset:

	- the terrains, bottom first, each drawn under every terrain after it (an autotile over the
	  cells of that terrain and of the terrains after it, or the variants of an atlas name), and where
	  two meet, the pair's `transition` autotile over the upper one's own (the terrains it says
	  `ignore:` of counting as the upper one);
	- the levels: each outlined with the tileset's `edge` (the one of the terrain on top, where the
	  tileset has one for it), along its rim only, and beyond a higher cell, toward the lower
	  neighbour its rise faces (`toward:`, down by default), the rise's `side` over `span` cells. On the square grid nothing is lifted (off it, see the grid docs: a raised cell is): what
	  stands on a higher level stands on its cells, where they are drawn;
	- the platforms (a tree top, a roof: a kind of higher level that is not the ground raised, where the
	  map's levels legend says one): each drawn with its own `edge` over all of it, and its own sides;
	- the cell layers, each from its own sheet (the tileset's atlas by default), drawn `under` the
	  actors, `over` them, or at the `top`, above everything; a `cell` of the tileset may say otherwise,
	  and a cell with a `size` is an object of several cells, drawn among the actors by default, whose
	  name and metadata every cell it covers has (`cellAt`, `objectAt`, `metadataAt`). A cell drawn
	  `side` is in place of a rise's side: where it covers one, the side's pieces are not drawn and it
	  is drawn in their place and order (a doorway, an arch or a drain in a wall face), the run of the
	  side going on past it as if whole; on the square grid in the sides' pass, after them, as any
	  layer cell is placed; on a lifted map a piece a level, as the raised cell's side is (`emitSideCells`);
	- the decor and the actors in one layer, `actors`, sorted by their feet (`y`) every frame.

	The map is drawn in chunks of `chunkSize` cells a side (`TileMap.defaultChunkSize`, 32), each as
	it is first in view and again when a cell of it (or, at its border, of a neighbour) changes, so a
	change costs its chunk and a big map costs what is seen of it. The view is `cull(x, y, w, h)` (the
	part of the map in view, in its own pixels), or by itself the scene's size when the map is in a
	scene and `cullToScene` is on (the default; a game with a camera calls `cull`, since a camera is
	not in an object's place); a map in no scene and given no view is drawn whole.

	It steps itself as it is drawn: the animated terrains and the sorting run in `sync`, with the frame's
	time, so nothing is to be called from the game loop. `sortActors = false` turns the sorting off.

	What a cell means to the game is its metadata, from the tileset: its terrain's, a rise's side over
	it, then each layer's cell there (an object's, over every cell it covers), a later one winning,
	read as settings are (`metadataAt(x, y).getBoolOrDefault("wall", false)`). The map says what is
	where (`terrainAt`, `levelAt`, `cellAt`, `objectAt`, `sideAt`, `mark`) and may be changed while
	the game runs (`setTerrain`, `setLevel`, `setCell`): however many cells change, the chunks they
	are in are drawn again once, as they are next in view; `redraw()` draws it all now. Reading a
	cell draws nothing: `terrainAt`, `levelAt` and `cellAt` read the rows, and `sideAt` and
	`metadataAt` work out a changed chunk's sides and metadata by themselves, so a game that reads
	the whole map (pathfinding) does not draw the whole map.
**/
class TileMap extends h2d.Object {
	/** Every tile map in a scene: what the DevBridge's `map_list` and `map_get` read, and hot reload redraws. **/
	public static final showing:Array<TileMap> = [];

	/** Cells a side of a chunk, for maps made from now on; `chunkSize` is a map's own. **/
	public static var defaultChunkSize = 32;

	/** The map's name in its file. **/
	public final mapName:String;

	/** The .manim file it was read from. **/
	public var sourceName(default, null):String;

	/** A cell's width in pixels: the grid's `tileWidth` (the square's side on a square grid). **/
	public var tileSize(default, null):Int = 0;

	/** The grid the tileset lays its tiles on (`grid:`): where every cell is on screen, and its neighbours. **/
	public var grid(default, null):TileGrid;

	/**
		Pixels a level raises a cell, drawn lifted: on the isometric and hex grids the tileset's
		`lift:`, half a cell's height when unsaid; 0 on the square grid, where nothing is lifted.
	**/
	public var lift(default, null):Float = 0;

	public var width(default, null):Int = 0;
	public var height(default, null):Int = 0;

	/** Cells a side of a chunk: what is drawn again when a cell changes, and what culling keeps or drops. `setChunkSize` changes it. **/
	public var chunkSize(default, null):Int;

	public var chunkCols(default, null):Int = 0;
	public var chunkRows(default, null):Int = 0;

	/** The map as it is now: the parsed definition's rows, changed by `setTerrain`, `setLevel` and `setCell`. Read it; change it through them. **/
	public var def(default, null):TilemapDef;

	/** The parse's definition the map was last read from, as the builder's `refreshTilemap` tells a map it has read already. **/
	public var sourceDef(default, null):TilemapDef;

	public var tileset(default, null):TilesetDef;

	/** A `tilemap(fill(…))`'s: the builder that last made it, from whose tileset it is made again
		(a hot reload makes it again from the reloaded file's; a refill asked of the old builder,
		which a result or codegen factory still holds, goes to this one). **/
	@:allow(bh.multianim.MultiAnimBuilder)
	var filledBy:Null<bh.multianim.MultiAnimBuilder> = null;

	/** Decor and actors, sorted by their feet (`y`) every frame unless `sortActors` is off. Add an actor with `addActor`. **/
	public final actors:h2d.Layers;

	/**
		Whether `actors` are sorted by their feet every frame (the default). Off, they keep the order
		they were added in, or the one the game gives them: a map with no actors that move, or a game
		that sorts its own.
	**/
	public var sortActors:Bool = true;

	/**
		Whether chunks out of the scene's view are left undrawn, the view being the scene's size seen
		through the map's own place and scale (the default). A game with a camera, which is not in an
		object's place, says the view itself with `cull`; a map not in a scene is drawn whole.
	**/
	public var cullToScene:Bool = true;

	var tiles:TileMapTiles;
	final ground:h2d.Object;
	final overLayer:h2d.Object;
	final topLayer:h2d.Object;
	// The map's draw order, one object a pass: each terrain bottom first, the levels' edges and the
	// platforms' tops, the sides, then each layer's cells under the actors (in `ground`); each
	// layer's cells over them (in `overLayer`) and at the top (in `topLayer`). A chunk draws into
	// its own part of each pass, so what it draws past its cells (a corner autotile's tile half a
	// cell up and left of its corner, an object reaching into the next chunk) is under every later
	// pass of every chunk and over every earlier one, as the map drawn in one piece is.
	var passes:Array<h2d.Object> = [];
	var edgePass = 0;
	var sidePass = 0;
	var underPass = 0;
	var overPass = 0;
	var topPass = 0;
	var chunks:Array<Chunk> = [];
	var decor:Array<h2d.Object> = [];
	// The chunk being drawn, off the square grid: its terrains' plans, and its raised cells' columns
	// by cell index (what `drawLayers` puts a raised cell's layer cells into)
	var chunkPlans:Array<GroundPlan> = [];
	var columnOf:Map<Int, ColumnTiles> = [];
	// Per terrain: the clock of its animation, shared by every chunk
	var animClocks:Array<{time:Float, index:Int}> = [];
	// Per cell, kept as the rows are and read without a draw: its terrain's index in the tileset
	// (-1 for none), its level (0 without levels), and its platform's index in `platformNames` (-1
	// for the ground); the rows are strings, and a character read from one is a string made
	var terrainIndex:Array<Int> = [];
	var levelIndex:Array<Int> = [];
	var platformIndex:Array<Int> = [];
	// The platforms the map's levels legend names, each once
	var platformNames:Array<String> = [];
	// Per layer (as `def.layers`): its legend resolved, each character an entry, and per cell the
	// entry whose character is there (-1 elsewhere) and the index (`cy * width + cx`) of the cell
	// whose character covers it - its own for a cell of one, the anchor's for an object - or -1
	var layerEntries:Array<Array<LayerEntry>> = [];
	var layerEntryOf:Array<Map<String, Int>> = [];
	var layerCell:Array<Array<Int>> = [];
	var covers:Array<Array<Int>> = [];
	// Some layer's legend has a cell drawn in place of a rise's side (`draw: side`): only then does a
	// side drawn look at the layers over it, so a map without one draws its sides as it always did
	var hasSideCells = false;
	// Per cell: the rise of a side drawn over it, 0 for none; and which of the tileset's rises drew it, -1 for none
	var sides:Array<Int> = [];
	var sideRises:Array<Int> = [];
	// The tileset's metadata, resolved once a source: per terrain and per rise (as tileset.rises);
	// a cell's is in its layer entries
	var terrainMetadata:Array<ResolvedSettings> = [];
	var riseMetadata:Array<ResolvedSettings> = [];
	// Per cell: its metadata, merged; one object a combination of sources, shared by every cell of
	// it: a terrain's own where nothing else is on the cell, else in `mergedSettings` by the combination
	var metadata:Array<BuilderResolvedSettings> = [];
	var terrainSettings:Array<BuilderResolvedSettings> = [];
	// A combination's key: its sources' indices in a mixed radix (terrain, rise, each layer's
	// entry, each one more than its count, none 0), an Int while the combinations fit in one;
	// a string otherwise, in `mergedSettings`
	var mergedByKey:Map<Int, BuilderResolvedSettings> = [];
	var mergedSettings:Map<String, BuilderResolvedSettings> = [];
	var intMetadataKeys = true;
	// The frames of a terrain's `cells:`, and of a rise's side pieces as they are first drawn, once a source
	var terrainFrames:Array<Null<Array<MapFrame>>> = [];
	var pieceFrames:Map<String, Array<MapFrame>> = [];
	// The edge autotiles a level is outlined with: the tileset's own, then each terrain's
	var edgeNames:Array<String> = [];
	// Per transition (as `tileset.transitions`), once a source: the index of the terrain it is drawn
	// toward (-1 for none), and by terrain index whether it counts as the transition's own (`ignore:`),
	// null for a transition that ignores none
	var transitionFrom:Array<Int> = [];
	var transitionIgnored:Array<Null<Array<Bool>>> = [];
	// How many cells past its anchor's an object of a layer draws (its footprint and its image),
	// the most of any; the view reaches that far past a chunk too, so an object is drawn and
	// shown as soon as any of it is in view, though only its anchor's chunk draws it
	var objectReach = 0;
	var cullMargin = 0;
	// The tileset's rises, worked out once a source: the sides they face (`toward:`, each once),
	// and which rise a cell takes, by side, terrain, platform and levels (`riseFor`'s answer)
	var towardNames:Array<String> = [];
	var riseTable:Array<Int> = [];
	var riseLevels = 0;
	// Where a side's run starts, per side faced and line of cells along it (`runStride` lines a
	// side): the run's rise, its first and the last cell seen, along the line. A chunk starting
	// in a run reads its start here, found by the chunk before it, instead of walking back; good
	// while `rowsVersion` (bumped by every change) is the one it was written at
	var runStride = 0;
	var runVersion:Array<Int> = [];
	var runIndex:Array<Int> = [];
	var runStart:Array<Int> = [];
	var runEnd:Array<Int> = [];
	var rowsVersion = 0;
	// Some chunk is dirty: drawn when next in view
	var changed = false;
	// The view `cull` was given, in the map's pixels, or null for the scene's; one rectangle, written over
	var cullRect:Null<PixelRect> = null;
	// The chunks shown last: every one, or the columns and rows (ends included) the view reached,
	// so culling touches the chunks that come into or go out of view and no other
	var shownAll = true;
	var shownCol0 = 0;
	var shownCol1 = -1;
	var shownRow0 = 0;
	var shownRow1 = -1;
	// Masks of a draw pass, shared by the chunks it draws and made over `passRect` alone (the chunks
	// and a cell around them, as far as an autotile's index looks), the rectangle's corner their
	// `[0][0]`: per terrain, per level, per platform and level
	var passRect:CellRect = {x0: 0, y0: 0, x1: 0, y1: 0};
	var passTerrainMasks:Array<Null<Array<Array<Int>>>> = [];
	/** A line terrain's (`connect16`) own cells alone, within the pass (`autotileMask`). */
	var passOwnTerrainMasks:Array<Null<Array<Array<Int>>>> = [];
	/** Per transition with `ignore:` (as `tileset.transitions`): its terrain's mask with the ignored terrains' cells, within the pass (`transitionMask`). */
	var passTransitionMasks:Array<Null<Array<Array<Int>>>> = [];
	var passLevelMasks:Map<Int, Array<Array<Int>>> = [];
	var passPlatformMasks:Map<Int, Null<Array<Array<Int>>>> = [];
	var passHighest = -1;

	static final NO_METADATA = new BuilderResolvedSettings(null);
	static final EMPTY_ROW:Array<Int> = [];
	static final STEP_UP:TowardStep = {dx: 0, dy: -1};
	static final STEP_DOWN:TowardStep = {dx: 0, dy: 1};
	static final STEP_LEFT:TowardStep = {dx: -1, dy: 0};
	static final STEP_RIGHT:TowardStep = {dx: 1, dy: 0};
	// What a terrain's transitions are found once of: one a format, however many formats there are
	static final FORMAT_COUNT = Type.getEnumConstructs(AutotileFormat).length;
	static final scratchPoint = new h2d.col.Point();
	// Each written and read within one call that runs no callbacks, as `sceneRect` is (culling off
	// the square grid, a lifted piece's run, a layer cell's box): single-threaded, never re-entered
	static final scratchCell = new h2d.col.IPoint();
	static final scratchBounds = new h2d.col.Bounds();
	// The width of the columns a standing frame is cut in along its cell's lower outline (`addCut`):
	// an isometric or hex outline's 2:1 slope moves a row every two pixels
	static inline final CUT = 2;
	// One rectangle for the scene's view, written by `localRectOf` and read by `applyCulling` in the
	// same call, which runs no callbacks: `sync` is single-threaded and never re-enters it. Never
	// kept past that call (`cullRect` is the map's own).
	static final sceneRect:PixelRect = {x: 0, y: 0, w: 0, h: 0};

	// Watchdog for tests: how often a chunk being drawn asks which rise a cell takes. Gated behind
	// MULTIANIM_ALLOC_TRACK so the increment vanishes from production builds; a side's run is numbered
	// from its start, so a long cliff must not cost a walk back from every one of its cells.
	#if MULTIANIM_ALLOC_TRACK
	public static var riseLookups:Int = 0;
	#end

	// Watchdogs for tests, gated the same way: strings built as the keys of merged metadata (a
	// cell's key is looked up for every cell drawn or worked out), and the chunks a frame looks
	// at to find the dirty ones in view (every frame while one is dirty).
	#if MULTIANIM_ALLOC_TRACK
	public static var metadataKeyStrings:Int = 0;
	public static var chunkChecks:Int = 0;
	#end

	public function new(mapName:String, sourceName:String, def:TilemapDef, tileset:TilesetDef, tiles:TileMapTiles, ?parent:h2d.Object) {
		super(parent);
		this.mapName = mapName;
		this.sourceName = sourceName;
		this.def = def;
		this.tileset = tileset;
		this.tiles = tiles;
		chunkSize = defaultChunkSize;
		ground = new h2d.Object(this);
		actors = new h2d.Layers(this);
		overLayer = new h2d.Object(this);
		topLayer = new h2d.Object(this);
		setSource(def, tileset, tiles);
	}

	/**
		New definitions, from a hot reload: the map is drawn again, as its chunks are next in view,
		and the actors stay. A `BuilderError` for an object of several cells outside the map
		(`tilemap_object_outside`) or over another cell of its layer (`tilemap_object_overlap`).
	**/
	public function setSource(def:TilemapDef, tileset:TilesetDef, tiles:TileMapTiles):Void {
		sourceDef = def;
		this.def = copyOf(def);
		this.tileset = tileset;
		this.tiles = tiles;
		grid = TileGrid.of(tileset.grid, tileset.tileSize, tileset.tileOffsetX, tileset.tileOffsetY);
		tileSize = grid.tileWidth;
		lift = grid.kind == Orthogonal ? 0 : (tileset.lift != null ? tileset.lift : grid.tileHeight / 2);
		width = def.width;
		height = def.height;
		terrainMetadata = [for (t in tileset.terrains) tiles.metadata(t.metadata)];
		riseMetadata = [for (r in tileset.rises) tiles.metadata(r.metadata)];
		terrainSettings = [for (m in terrainMetadata) m != null ? new BuilderResolvedSettings(m) : NO_METADATA];
		mergedSettings = [];
		mergedByKey = [];
		terrainFrames = [for (t in tileset.terrains) t.cells != null ? framesOf(tileset.atlas, t.cells) : null];
		pieceFrames = [];
		edgeNames = [];
		if (tileset.edge != null)
			edgeNames.push(tileset.edge);
		for (name in tileset.edges)
			if (!edgeNames.contains(name)) edgeNames.push(name);
		transitionFrom = [for (t in tileset.transitions) terrainIndexOf(t.from)];
		transitionIgnored = [
			for (t in tileset.transitions)
				t.ignore == null || t.ignore.length == 0 ? null : [for (terrain in tileset.terrains) t.ignore.contains(terrain.name)]
		];
		animClocks = [for (_ in tileset.terrains) {time: 0.0, index: 0}];
		final cells = width * height;
		terrainIndex = [for (cy in 0...height) for (cx in 0...width) terrainIndexOf(this.def.legend.get(this.def.terrain[cy].charAt(cx)))];
		platformNames = [];
		for (_ => platform in this.def.levelPlatforms)
			if (!platformNames.contains(platform)) platformNames.push(platform);
		final levels = this.def.levels;
		levelIndex = [for (cy in 0...height) for (cx in 0...width) levels.length > 0 ? levelOf(this.def.levelLegend, levels[cy].charAt(cx)) : 0];
		platformIndex = [
			for (cy in 0...height)
				for (cx in 0...width)
					levels.length > 0 ? platformNames.indexOf(this.def.levelPlatforms.get(levels[cy].charAt(cx))) : -1
		];
		final cellMetadata:Map<String, ResolvedSettings> = [for (c in tileset.cells) c.name => tiles.metadata(c.metadata)];
		layerEntries = [];
		layerEntryOf = [];
		for (l in this.def.layers) {
			final ownSheet = l.sheet;
			final entries:Array<LayerEntry> = [];
			final of:Map<String, Int> = [];
			for (ch => name in l.legend) {
				final cell = cellDef(name);
				of.set(ch, entries.length);
				entries.push({
					name: name,
					frames: ownSheet != null ? framesOf(ownSheet, name, true) : framesOf(tileset.atlas, name),
					draw: cell != null && cell.draw != null ? cell.draw : (l.draw != null ? l.draw : "under"),
					anchorX: cell != null && cell.anchorX != null ? cell.anchorX : 0,
					anchorY: cell != null && cell.anchorY != null ? cell.anchorY : 0,
					cell: cell,
					metadata: cellMetadata.get(name),
				});
			}
			layerEntries.push(entries);
			layerEntryOf.push(of);
		}
		hasSideCells = false;
		for (entries in layerEntries)
			for (e in entries)
				if (e.draw == "side") hasSideCells = true;
		layerCell = [];
		covers = [];
		for (li in 0...this.def.layers.length)
			readLayer(li);
		sides = [for (_ in 0...cells) 0];
		sideRises = [for (_ in 0...cells) -1];
		metadata = [for (_ in 0...cells) NO_METADATA];
		// the metadata keys fit an Int while the combinations of sources do
		var combinations = (tileset.terrains.length + 1.0) * (tileset.rises.length + 1.0);
		for (entries in layerEntries)
			combinations *= entries.length + 1.0;
		intMetadataKeys = combinations <= 2147483647.0;
		objectReach = 0;
		for (entries in layerEntries)
			for (e in entries) {
				final reach = reachOf(e);
				if (reach > objectReach) objectReach = reach;
			}
		cullMargin = grid.kind == Orthogonal ? (1 + objectReach) * tileSize : marginOffGrid();
		readRises();
		makePasses();
		makeChunks();
	}

	/**
		How many cells past its anchor's a layer's entry draws, the furthest of any side: its
		footprint about its anchor, and its image, drawn from the footprint's top-left.
	**/
	function reachOf(e:LayerEntry):Int {
		final w = e.cell != null && e.cell.width != null ? e.cell.width : 1;
		final h = e.cell != null && e.cell.height != null ? e.cell.height : 1;
		var reach = e.anchorX;
		inline function atLeast(cells:Int)
			if (cells > reach) reach = cells;
		atLeast(w - 1 - e.anchorX);
		atLeast(e.anchorY);
		atLeast(h - 1 - e.anchorY);
		// off the square grid a frame's reach is in pixels, in `marginOffGrid`
		if (grid.kind != Orthogonal)
			return reach;
		// what the tile draws, placed in its frame
		for (frame in e.frames) {
			final f = frame.tile;
			atLeast(e.anchorX - Math.floor(f.dx / tileSize));
			atLeast(Math.ceil((f.dx + f.width) / tileSize) - 1 - e.anchorX);
			atLeast(e.anchorY - Math.floor(f.dy / tileSize));
			atLeast(Math.ceil((f.dy + f.height) / tileSize) - 1 - e.anchorY);
		}
		return reach;
	}

	/**
		How far past a chunk's cells what it draws may reach, in pixels, on the isometric and hex
		grids: a frame stands on its cell and may be taller and wider than it, an object of several
		cells reaches past its anchor, a raised cell is drawn higher, and the tileset's `tileOffset`
		moves them all. Generous: a chunk shown a little early costs nothing drawn.
	**/
	function marginOffGrid():Int {
		var frame = 0.0;
		inline function atLeast(f:MapFrame) {
			if (f.width > frame) frame = f.width;
			if (f.height > frame) frame = f.height;
		}
		for (entries in layerEntries)
			for (e in entries)
				for (f in e.frames)
					atLeast(f);
		for (frames in terrainFrames)
			if (frames != null)
				for (f in frames)
					atLeast(f);
		final cell = grid.tileWidth > grid.tileHeight ? grid.tileWidth : grid.tileHeight;
		final offset = Math.abs(grid.offsetX) + Math.abs(grid.offsetY);
		return Math.ceil((2 + objectReach) * cell + frame + offset + liftMargin());
	}

	/** How high the highest level a map may have lifts a cell (none on the square grid). **/
	function liftMargin():Float {
		if (lift == 0 || def.levels.length == 0)
			return 0;
		// levels are 0 to 9 or the legend's: the highest one a map may be given
		var highest = 9;
		for (_ => level in def.levelLegend)
			if (level > highest) highest = level;
		return highest * lift;
	}

	/** How far up a cell is drawn: its level times `lift` off the square grid, 0 on it. **/
	public function liftAt(cx:Int, cy:Int):Float {
		return lift == 0 || !inside(cx, cy) ? 0 : levelIndex[cy * width + cx] * lift;
	}

	/**
		The rises worked out once a source: the sides they face, which rise a cell takes for every
		side, terrain, platform and number of levels (as `riseFor` says; a number of levels above
		every rise's takes `rise any`, as the next one past them does), and room for the runs.
	**/
	function readRises():Void {
		towardNames = [];
		var highest = 0;
		for (r in tileset.rises) {
			if (!towardNames.contains(r.toward)) towardNames.push(r.toward);
			if (r.rise > highest) highest = r.rise;
		}
		riseLevels = highest + 2;
		riseTable = [];
		for (toward in towardNames)
			for (t in -1...tileset.terrains.length)
				for (p in -1...platformNames.length)
					for (levels in 0...riseLevels)
						riseTable.push(levels == 0 ? -1 : riseFor(tileset, levels, toward, t >= 0 ? tileset.terrains[t].name : null,
							p >= 0 ? platformNames[p] : null));
		runStride = width > height ? width : height;
		final runs = towardNames.length * runStride;
		runVersion = [for (_ in 0...runs) -1];
		runIndex = [for (_ in 0...runs) -1];
		runStart = [for (_ in 0...runs) 0];
		runEnd = [for (_ in 0...runs) 0];
		rowsVersion++;
	}

	/** The map's passes made again for the source's terrains and layers, in the order they are drawn. **/
	function makePasses():Void {
		for (p in passes)
			p.remove();
		final layers = def.layers.length;
		edgePass = tileset.terrains.length;
		sidePass = edgePass + 1;
		underPass = sidePass + 1;
		overPass = underPass + layers;
		topPass = overPass + layers;
		passes = [];
		for (i in 0...topPass + layers)
			passes.push(new h2d.Object(i < overPass ? ground : (i < topPass ? overLayer : topLayer)));
	}

	/** A chunk's part of a pass, made as it first draws there, shown as the chunk is. **/
	function partOf(c:Chunk, pass:Int):h2d.Object {
		var part = c.parts[pass];
		if (part == null) {
			if (grid.kind == Orthogonal) {
				part = new h2d.Object(passes[pass]);
			} else {
				// a frame taller or wider than its cell reaches into the chunks around it, so a
				// pass's parts are kept in the chunks' order, back to front, whichever is drawn first
				part = new h2d.Object();
				final into = passes[pass];
				var at = 0;
				for (other in chunks)
					if (other.index < c.index && other.parts[pass] != null) at++;
				into.addChildAt(part, at);
			}
			part.visible = c.shown;
			c.parts[pass] = part;
		}
		return part;
	}

	/** Changes the size of a chunk, in cells; the map is drawn again in the new ones as they are in view. **/
	public function setChunkSize(cells:Int):Void {
		if (cells <= 0)
			throw BuilderError.of('tilemap $mapName: a chunk is 1 cell or more a side, got $cells', "tilemap_chunk");
		chunkSize = cells;
		makeChunks();
	}

	/** New chunks, every one dirty: drawn as it is next in view, its cells worked out as they are asked. **/
	function makeChunks():Void {
		for (c in chunks)
			clearChunk(c);
		chunkCols = Std.int((width + chunkSize - 1) / chunkSize);
		chunkRows = Std.int((height + chunkSize - 1) / chunkSize);
		chunks = [];
		for (row in 0...chunkRows)
			for (col in 0...chunkCols) {
				final x0 = col * chunkSize;
				final y0 = row * chunkSize;
				chunks.push(new Chunk({
					x0: x0,
					y0: y0,
					x1: x0 + chunkSize < width ? x0 + chunkSize : width,
					y1: y0 + chunkSize < height ? y0 + chunkSize : height,
				}, passes.length));
				chunks[chunks.length - 1].index = chunks.length - 1;
			}
		shownAll = true;
		changed = true;
	}

	/** Everything a chunk drew taken off the map: its parts of the passes and its objects. **/
	static function clearChunk(c:Chunk):Void {
		for (i in 0...c.parts.length) {
			final part = c.parts[i];
			if (part != null) {
				part.remove();
				c.parts[i] = null;
			}
		}
		for (o in c.objects)
			o.remove();
		c.objects = [];
		c.animated = [];
	}

	/** The decor of the map's file, built by the builder: replaces the decor there was, not the actors. **/
	public function setDecor(objects:Array<h2d.Object>):Void {
		for (o in decor)
			o.remove();
		decor = objects.copy();
		for (o in decor)
			actors.add(o, 0);
	}

	// ===================== The game's side =====================

	public function addActor(actor:h2d.Object):Void {
		actors.add(actor, 0);
	}

	public function removeActor(actor:h2d.Object):Void {
		if (actor.parent == actors)
			actor.remove();
	}

	/**
		The part of the map in view, in its own pixels: chunks outside it are not drawn until the
		view reaches them. For a game with a camera, every frame the camera moves. `cullNone()`
		forgets the view; the scene's is used again with `cullToScene = true` after it.
	**/
	public function cull(x:Float, y:Float, w:Float, h:Float):Void {
		var r = cullRect;
		if (r == null) {
			r = {x: x, y: y, w: w, h: h};
			cullRect = r;
		} else {
			r.x = x;
			r.y = y;
			r.w = w;
			r.h = h;
		}
		applyCulling();
	}

	/** Every chunk in view, whatever the scene shows, until `cull` says a view or `cullToScene` is set again. **/
	public function cullNone():Void {
		cullRect = null;
		cullToScene = false;
		applyCulling();
	}

	/** Whether a chunk (by its column and row of chunks) is drawn, after culling. **/
	public function isChunkVisible(col:Int, row:Int):Bool {
		return chunks[row * chunkCols + col].shown;
	}

	/** The cell a point of the map is in (pixels, in the map's own coordinates), as its grid lays the cells. **/
	public function toCell(x:Float, y:Float):h2d.col.IPoint {
		if (lift == 0 || def.levels.length == 0)
			return grid.toCell(x, y);
		// A cell drawn lifted is under the point where its top or its side is: of the cells whose
		// column reaches the point, the one in front (the lowest middle on screen), the higher top
		// on a tie. Looked for at every level a cell of the map may stand on.
		final highest = Math.ceil(liftMargin() / lift);
		var best:Null<h2d.col.IPoint> = null;
		var bestY = Math.NEGATIVE_INFINITY;
		for (level in 0...highest + 1) {
			final c = grid.toCell(x, y + level * lift);
			if (!inside(c.x, c.y) || levelIndex[c.y * width + c.x] < level)
				continue;
			final y0 = grid.pixelY(c.x, c.y);
			if (y0 > bestY || (y0 == bestY && best != null && levelIndex[c.y * width + c.x] > levelIndex[best.y * width + best.x])) {
				best = c;
				bestY = y0;
			}
		}
		return best != null ? best : grid.toCell(x, y);
	}

	/** A cell's top-left corner, in pixels: its box's, a diamond's or a hex's on those grids (`TileGrid.toPixel`). **/
	public function toPixel(cx:Int, cy:Int):h2d.col.Point {
		return grid.toPixel(cx, cy);
	}

	/** The middle of a cell, in pixels: where an actor standing on it has its feet (`TileGrid.center`). **/
	public function centerOf(cx:Int, cy:Int):h2d.col.Point {
		return grid.center(cx, cy);
	}

	public function inside(cx:Int, cy:Int):Bool {
		return cx >= 0 && cy >= 0 && cx < width && cy < height;
	}

	/** The terrain's name, or null for `none` and outside the map. **/
	public function terrainAt(cx:Int, cy:Int):Null<String> {
		if (!inside(cx, cy))
			return null;
		final i = terrainIndex[cy * width + cx];
		return i < 0 ? null : tileset.terrains[i].name;
	}

	/** 0 where the map has no levels. **/
	public function levelAt(cx:Int, cy:Int):Int {
		return inside(cx, cy) ? levelIndex[cy * width + cx] : 0;
	}

	/** The platform a cell is of (the tileset's `platform name { … }`, where the map's levels legend says one), or null: the ground, at its level. **/
	public function platformAt(cx:Int, cy:Int):Null<String> {
		if (!inside(cx, cy))
			return null;
		final p = platformIndex[cy * width + cx];
		return p < 0 ? null : platformNames[p];
	}

	/** The level a character of the levels rows stands for: a digit is itself, any other is in the legend. **/
	public static function levelOf(legend:Map<String, Int>, c:String):Int {
		final named = legend.get(c);
		if (named != null)
			return named;
		final code = c.charCodeAt(0);
		return code == null || code < "0".code || code > "9".code ? 0 : code - "0".code;
	}

	/** The name of the cell a layer has there (an object's, over every cell it covers), or null. **/
	public function cellAt(layer:String, cx:Int, cy:Int):Null<String> {
		final li = layerIndex(layer);
		if (li < 0 || !inside(cx, cy))
			return null;
		final anchor = covers[li][cy * width + cx];
		return anchor < 0 ? null : entryAt(li, anchor).name;
	}

	/**
		What a layer has at a cell, with where it is: its name, the anchor cell the layer's character
		is at (where `setCell` changes it), and the cells it covers. Null where the layer has nothing.
	**/
	public function objectAt(layer:String, cx:Int, cy:Int):Null<TilemapObject> {
		final li = layerIndex(layer);
		if (li < 0 || !inside(cx, cy))
			return null;
		final anchor = covers[li][cy * width + cx];
		if (anchor < 0)
			return null;
		final ax = anchor % width;
		final ay = Std.int(anchor / width);
		final entry = entryAt(li, anchor);
		final r = footprintOf(entry.cell, ax, ay);
		return {name: entry.name, anchorX: ax, anchorY: ay, x: r.x0, y: r.y0, width: r.x1 - r.x0, height: r.y1 - r.y0};
	}

	/**
		The rise of a side drawn over the cell, or 0; on a lifted map (isometric and hex) a raised
		cell's own side, the most levels it drops. A side a layer's cell is drawn in place of (`draw:
		side`) is the cell's all the same: the levels are as they were, only what is drawn changed
		(its metadata is under the cell's, which wins). Worked out for the cell's chunk if it changed;
		nothing is drawn.
	**/
	public function sideAt(cx:Int, cy:Int):Int {
		if (!inside(cx, cy))
			return 0;
		resolveCellsChunk(cx, cy);
		return sides[cy * width + cx];
	}

	/**
		The cell's metadata: its terrain's, a side's over it, then each layer's cell there (an object's
		on every cell it covers), a later one winning; read as settings are (`getBoolOrDefault`,
		`getIntOrDefault`, `getFloatOrDefault`, `getStringOrDefault`, `has`, `keys`). Empty outside the
		map. Worked out for the cell's chunk if it changed; nothing is drawn.
	**/
	public function metadataAt(cx:Int, cy:Int):BuilderResolvedSettings {
		if (!inside(cx, cy))
			return NO_METADATA;
		resolveCellsChunk(cx, cy);
		return metadata[cy * width + cx];
	}

	public function mark(name:String):Null<TilemapMarkDef> {
		for (m in def.marks)
			if (m.name == name) return m;
		return null;
	}

	/** Changes a cell's terrain to the one `char` stands for in the legend; the map is drawn again there (see `redraw`). **/
	public function setTerrain(cx:Int, cy:Int, char:String):Void {
		checkInside(cx, cy);
		if (!def.legend.exists(char))
			throw BuilderError.of('tilemap $mapName: "$char" is not in the legend', "tilemap_legend");
		def.terrain[cy] = replaceAt(def.terrain[cy], cx, char);
		terrainIndex[cy * width + cx] = terrainIndexOf(def.legend.get(char));
		// a rise may be the terrain's own, so a terrain change reaches as far as a level's
		if (def.levels.length > 0)
			touchRises(cx, cy);
		else
			touch(cx, cy, 1);
	}

	/**
		Changes a cell's level: the ground raised to `level` (a digit, or a character of the map's
		levels legend that is not a platform's); the map is drawn again there (see `redraw`).
	**/
	public function setLevel(cx:Int, cy:Int, level:Int):Void {
		checkInside(cx, cy);
		var c:Null<String> = level >= 0 && level <= 9 ? String.fromCharCode("0".code + level) : null;
		if (c == null)
			for (key => value in def.levelLegend)
				if (value == level && !def.levelPlatforms.exists(key)) {
					c = key;
					break;
				}
		if (c == null)
			throw BuilderError.of('tilemap $mapName: no character stands for the ground at level $level (a digit, or one of the levels legend that is not a platform)',
				"tilemap_level");
		if (def.levels.length == 0)
			def.levels = [for (_ in 0...height) StringTools.lpad("", "0", width)];
		def.levels[cy] = replaceAt(def.levels[cy], cx, c);
		levelIndex[cy * width + cx] = level;
		platformIndex[cy * width + cx] = -1;
		touchRises(cx, cy);
	}

	/**
		Changes a layer's cell (`" "` for none) at the cell the layer's character is at: an object of
		several cells is placed and removed at its anchor; the map is drawn again there (see `redraw`).
		`BuilderError`s: a cell another object covers (`tilemap_object_covered`: change that object at
		its anchor, `objectAt` says where), an object that would reach outside the map
		(`tilemap_object_outside`) or over another cell of the layer (`tilemap_object_overlap`); nothing
		is changed then.
	**/
	public function setCell(layer:String, cx:Int, cy:Int, char:String):Void {
		checkInside(cx, cy);
		final li = layerIndex(layer);
		if (li < 0)
			throw BuilderError.of('tilemap $mapName has no layer $layer', "tilemap_layer");
		final l = def.layers[li];
		final entries = layerEntries[li];
		final newEntry:Int = char == " " ? -1 : (layerEntryOf[li].exists(char) ? layerEntryOf[li].get(char) : -2);
		if (newEntry == -2)
			throw BuilderError.of('tilemap $mapName: "$char" is not in the legend of layer $layer', "tilemap_legend");
		final cover = covers[li];
		final at = layerCell[li];
		final i = cy * width + cx;
		if (cover[i] >= 0 && cover[i] != i) {
			final a = cover[i];
			throw BuilderError.of('tilemap $mapName: layer $layer: column $cx, row $cy is covered by ${entries[at[a]].name} at column ${a % width}, row ${Std.int(a / width)}: change it there',
				"tilemap_object_covered");
		}
		// the old object's cells freed; put back if the new one cannot be placed
		var old:Null<CellRect> = null;
		if (cover[i] == i) {
			old = footprintOf(entries[at[i]].cell, cx, cy);
			fillCover(cover, old, -1);
		}
		var placed:Null<CellRect> = null;
		if (newEntry >= 0) {
			final entry = entries[newEntry];
			placed = footprintOf(entry.cell, cx, cy);
			try {
				placeCover(cover, li, entry.name, cx, cy, placed);
			} catch (e:BuilderError) {
				if (old != null)
					fillCover(cover, old, i);
				throw e;
			}
		}
		l.rows[cy] = replaceAt(l.rows[cy], cx, char);
		at[i] = newEntry;
		// drawn again where the old and the new one are: their metadata is on every cell they cover
		if (old != null)
			touchRect(old, 0);
		if (placed != null)
			touchRect(placed, 0);
		if (old == null && placed == null)
			touch(cx, cy, 0);
	}

	function checkInside(cx:Int, cy:Int):Void {
		if (!inside(cx, cy))
			throw BuilderError.of('tilemap $mapName: column $cx, row $cy is outside the map (${width}x$height)', "tilemap_outside");
	}

	function layerIndex(name:String):Int {
		for (i in 0...def.layers.length)
			if (def.layers[i].name == name) return i;
		return -1;
	}

	/** The legend entry of a layer at a cell index, which has a character there. **/
	inline function entryAt(li:Int, index:Int):LayerEntry {
		return layerEntries[li][layerCell[li][index]];
	}

	/** The cells a cell placed at (cx, cy) covers: its own, or for an object of several its `size` about its anchor. **/
	function footprintOf(cell:Null<TilesetCellDef>, cx:Int, cy:Int):CellRect {
		final w = cell != null && cell.width != null ? cell.width : 1;
		final h = cell != null && cell.height != null ? cell.height : 1;
		final ax = cell != null && cell.anchorX != null ? cell.anchorX : 0;
		final ay = cell != null && cell.anchorY != null ? cell.anchorY : 0;
		return {x0: cx - ax, y0: cy - ay, x1: cx - ax + w, y1: cy - ay + h};
	}

	/** A layer's rows read: per cell the entry whose character is there, and every cell's anchor (its cover); the errors `setSource` says. **/
	function readLayer(li:Int):Void {
		final l = def.layers[li];
		final entries = layerEntries[li];
		final of = layerEntryOf[li];
		final cells = width * height;
		final at = [for (_ in 0...cells) -1];
		final cover = [for (_ in 0...cells) -1];
		layerCell.push(at);
		covers.push(cover);
		for (cy in 0...height) {
			final row = l.rows[cy];
			for (cx in 0...width) {
				final ch = row.charAt(cx);
				if (ch == " ")
					continue;
				final e = of.get(ch);
				if (e == null)
					continue; // the builder has checked the legend
				at[cy * width + cx] = e;
				placeCover(cover, li, entries[e].name, cx, cy, footprintOf(entries[e].cell, cx, cy));
			}
		}
	}

	/** Marks the cells a cell at (cx, cy) covers as its, once they are inside the map and free. **/
	function placeCover(cover:Array<Int>, li:Int, name:String, cx:Int, cy:Int, r:CellRect):Void {
		final layer = def.layers[li].name;
		if (r.x0 < 0 || r.y0 < 0 || r.x1 > width || r.y1 > height)
			throw BuilderError.of('tilemap $mapName: layer $layer: $name at column $cx, row $cy covers columns ${r.x0} to ${r.x1 - 1}, rows ${r.y0} to ${r.y1 - 1}, outside the map (${width}x$height)',
				"tilemap_object_outside");
		for (y in r.y0...r.y1)
			for (x in r.x0...r.x1) {
				final other = cover[y * width + x];
				if (other >= 0)
					throw BuilderError.of('tilemap $mapName: layer $layer: $name at column $cx, row $cy covers column $x, row $y, where ${entryAt(li, other).name} at column ${other % width}, row ${Std.int(other / width)} is already',
						"tilemap_object_overlap");
			}
		fillCover(cover, r, cy * width + cx);
	}

	function fillCover(cover:Array<Int>, r:CellRect, value:Int):Void {
		for (y in r.y0...r.y1)
			for (x in r.x0...r.x1)
				cover[y * width + x] = value;
	}

	/** A cell changed: the chunks within `reach` cells of it are drawn again, next time. **/
	function touch(cx:Int, cy:Int, reach:Int):Void {
		touchChunks(chunkOf(cx - reach), chunkOf(cx + reach), chunkOf(cy - reach), chunkOf(cy + reach));
	}

	/** Cells changed: the chunks within `reach` cells of the rectangle are drawn again, next time. **/
	function touchRect(r:CellRect, reach:Int):Void {
		touchChunks(chunkOf(r.x0 - reach), chunkOf(r.x1 - 1 + reach), chunkOf(r.y0 - reach), chunkOf(r.y1 - 1 + reach));
	}

	/** The column (or row) of chunks a cell's column (or row) is in, however far outside the map. **/
	inline function chunkOf(cell:Int):Int {
		return Math.floor(cell / chunkSize);
	}

	/** The chunks of some columns and rows (both ends included, those outside the map left out) are drawn again, their cells worked out again, next time. **/
	function touchChunks(col0:Int, col1:Int, row0:Int, row1:Int):Void {
		if (col0 < 0) col0 = 0;
		if (row0 < 0) row0 = 0;
		if (col1 >= chunkCols) col1 = chunkCols - 1;
		if (row1 >= chunkRows) row1 = chunkRows - 1;
		for (row in row0...row1 + 1)
			for (col in col0...col1 + 1) {
				final c = chunks[row * chunkCols + col];
				c.dirty = true;
				c.resolved = false;
			}
		changed = true;
		// the rows changed: where a side's run starts may have too
		rowsVersion++;
	}

	/**
		A cell's level or terrain changed, which may change what rise a cell near it has: the sides
		drawn from there reach `span` cells, and a side of several pieces taken in turn is numbered
		from its run's start, so every chunk along the run the cell may be in is drawn again too.
	**/
	function touchRises(cx:Int, cy:Int):Void {
		final reach = maxSpan() + 1;
		touch(cx, cy, reach);
		for (rise in tileset.rises) {
			if (rise.sides.length < 2)
				continue;
			final step = towardStep(rise.toward);
			if (step.dy != 0)
				touchChunks(0, chunkCols - 1, chunkOf(cy - reach), chunkOf(cy + reach));
			else
				touchChunks(chunkOf(cx - reach), chunkOf(cx + reach), 0, chunkRows - 1);
		}
	}

	/** How far a side reaches from the cell above it: the longest `span` of the tileset's rises. **/
	function maxSpan():Int {
		var span = 0;
		for (r in tileset.rises)
			if (r.span > span) span = r.span;
		return span;
	}

	/** The map as the DevBridge's `map_get` says it: the rows as written, and where it is. **/
	public function describe():Dynamic {
		return {
			name: mapName,
			source: sourceName,
			line: def.line,
			width: width,
			height: height,
			tileSize: tileSize,
			grid: grid.describe(),
			tileset: def.tileset,
			legend: mapToObject(def.legend),
			terrain: def.terrain.copy(),
			levels: def.levels.copy(),
			levelLegend: mapToObject(def.levelLegend),
			levelPlatforms: mapToObject(def.levelPlatforms),
			layers: [for (l in def.layers) {name: l.name, sheet: l.sheet, draw: l.draw, legend: mapToObject(l.legend), rows: l.rows.copy()}],
			marks: [for (m in def.marks) m.w != null ? {name: m.name, x: m.x, y: m.y, w: m.w, h: m.h} : {name: m.name, x: m.x, y: m.y}],
		};
	}

	/**
		Steps the animated terrains and sorts the actors by their feet. Only `sync` calls it, with the
		frame's time, so a map moves by itself while it is drawn and a game has nothing to call.
	**/
	function step(dt:Float):Void {
		for (i in 0...animClocks.length) {
			final terrain = tileset.terrains[i];
			final frames = terrain.autotiles.length;
			if (frames < 2)
				continue;
			final clock = animClocks[i];
			final duration = (terrain.duration != null ? terrain.duration : 1000) / 1000;
			clock.time += dt;
			var index = clock.index;
			while (clock.time >= duration) {
				clock.time -= duration;
				index = (index + 1) % frames;
			}
			if (index != clock.index) {
				clock.index = index;
				for (c in chunks)
					for (a in c.animated)
						if (a.terrain == i)
							showFrame(a.frames, index);
			}
		}
		if (sortActors)
			actors.ysort(0);
	}

	/** A run of an animated terrain's frames in a chunk (off the square grid, in its place back to front): shown as the terrain's clock says, stepped with the rest. **/
	function animate(c:Chunk, terrain:Int, frames:Array<h2d.Object>):Void {
		showFrame(frames, animClocks[terrain].index);
		c.animated.push({terrain: terrain, frames: frames});
	}

	static function showFrame(frames:Array<h2d.Object>, index:Int):Void {
		for (k in 0...frames.length)
			frames[k].visible = k == index;
	}

	override function sync(ctx:h2d.RenderContext) {
		// what is in view first, so a chunk out of it is not drawn at all
		applyCulling();
		drawDirty(true);
		step(ctx.elapsedTime);
		super.sync(ctx);
	}

	override function onAdd() {
		super.onAdd();
		if (!showing.contains(this))
			showing.push(this);
	}

	override function onRemove() {
		showing.remove(this);
		super.onRemove();
	}

	/** Hot reload: every map in a scene read from `path` is read again from its new builder. **/
	public static function builderReplaced(path:String, refresh:TileMap->Void):Void {
		for (map in showing.copy())
			if (map.sourceName == path)
				refresh(map);
	}

	// ===================== Culling =====================

	/**
		Shows the chunks the view reaches and hides the rest; every chunk when there is no view.
		Only the chunks the view reached last time and those it reaches now are looked at: the rest
		are hidden already.
	**/
	function applyCulling():Void {
		var view = cullRect;
		if (view == null && cullToScene) {
			final scene = getScene();
			if (scene != null)
				view = localRectOf(scene);
		}
		if (view == null) {
			if (!shownAll)
				for (c in chunks)
					showChunk(c, true);
			shownAll = true;
			return;
		}
		// the columns and rows of chunks the view may reach: a corner autotile reaches half a tile
		// past its cells, and an object of several cells as far past its anchor as it covers or
		// its image does, so a chunk within that of the view is shown (`cullMargin`)
		var col0, col1, row0, row1;
		if (grid.kind == Orthogonal) {
			final side = chunkSize * tileSize;
			col0 = Math.floor((view.x - cullMargin) / side);
			col1 = Math.floor((view.x + view.w + cullMargin) / side);
			row0 = Math.floor((view.y - cullMargin) / side);
			row1 = Math.floor((view.y + view.h + cullMargin) / side);
		} else {
			// the cells at the corners of the view and its margin; a diamond or a band of hexes in
			// view lies within the rectangle of cells they span
			var cx0 = 0x7FFFFFFF, cy0 = 0x7FFFFFFF, cx1 = -0x7FFFFFFF, cy1 = -0x7FFFFFFF;
			final p = scratchCell;
			for (corner in 0...4) {
				grid.toCell(corner & 1 == 0 ? view.x - cullMargin : view.x + view.w + cullMargin,
					corner < 2 ? view.y - cullMargin : view.y + view.h + cullMargin, p);
				if (p.x < cx0) cx0 = p.x;
				if (p.x > cx1) cx1 = p.x;
				if (p.y < cy0) cy0 = p.y;
				if (p.y > cy1) cy1 = p.y;
			}
			col0 = chunkOf(cx0 - 1);
			col1 = chunkOf(cx1 + 1);
			row0 = chunkOf(cy0 - 1);
			row1 = chunkOf(cy1 + 1);
		}
		if (col0 < 0) col0 = 0;
		if (row0 < 0) row0 = 0;
		if (col1 >= chunkCols) col1 = chunkCols - 1;
		if (row1 >= chunkRows) row1 = chunkRows - 1;
		if (shownAll) {
			for (c in chunks)
				showChunk(c, inView(c, view));
		} else {
			for (row in shownRow0...shownRow1 + 1)
				for (col in shownCol0...shownCol1 + 1)
					showChunk(chunks[row * chunkCols + col], false);
			for (row in row0...row1 + 1)
				for (col in col0...col1 + 1) {
					final c = chunks[row * chunkCols + col];
					showChunk(c, inView(c, view));
				}
		}
		shownAll = false;
		shownCol0 = col0;
		shownCol1 = col1;
		shownRow0 = row0;
		shownRow1 = row1;
	}

	/** Whether a view reaches a chunk: within `cullMargin` of its cells, as far as what it draws reaches past them. **/
	function inView(c:Chunk, view:PixelRect):Bool {
		if (grid.kind == Orthogonal)
			return c.rect.x1 * tileSize + cullMargin > view.x && c.rect.x0 * tileSize - cullMargin < view.x + view.w
				&& c.rect.y1 * tileSize + cullMargin > view.y && c.rect.y0 * tileSize - cullMargin < view.y + view.h;
		final b = grid.bounds(c.rect.x0, c.rect.y0, c.rect.x1, c.rect.y1, scratchBounds);
		return b.xMax + cullMargin > view.x && b.xMin - cullMargin < view.x + view.w && b.yMax + cullMargin > view.y
			&& b.yMin - cullMargin < view.y + view.h;
	}

	/** Shows or hides a chunk: its parts of the passes and its objects among the actors. **/
	static function showChunk(c:Chunk, visible:Bool):Void {
		if (c.shown == visible)
			return;
		c.shown = visible;
		for (part in c.parts)
			if (part != null) part.visible = visible;
		for (o in c.objects)
			o.visible = visible;
	}

	/** The scene's whole view in the map's own coordinates: a box around its four corners, in `sceneRect`. **/
	function localRectOf(scene:h2d.Scene):PixelRect {
		var minX = Math.POSITIVE_INFINITY, minY = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY, maxY = Math.NEGATIVE_INFINITY;
		final p = scratchPoint;
		for (corner in 0...4) {
			p.set(corner & 1 == 0 ? 0 : scene.width, corner < 2 ? 0 : scene.height);
			globalToLocal(p);
			if (p.x < minX) minX = p.x;
			if (p.x > maxX) maxX = p.x;
			if (p.y < minY) minY = p.y;
			if (p.y > maxY) maxY = p.y;
		}
		final r = sceneRect;
		r.x = minX;
		r.y = minY;
		r.w = maxX - minX;
		r.h = maxY - minY;
		return r;
	}

	// ===================== Drawing =====================

	/**
		Draws everything again from the rows, now: new definitions, or cells changed since. A chunk
		is drawn by itself when it is next in view, so this is for drawing them all sooner, whatever
		the view.
	**/
	public function redraw():Void {
		for (c in chunks)
			c.dirty = true;
		// drawDirty draws nothing while nothing changed: a map drawn whole already is redrawn too
		changed = true;
		drawDirty(false);
	}

	/**
		Draws the dirty chunks, those in view only when `onlyVisible`; nothing when none is. With a
		view, only the chunks culling showed are looked at: a dirty chunk out of view waits for it
		without costing every frame a look at every chunk.
	**/
	function drawDirty(onlyVisible:Bool):Void {
		if (!changed)
			return;
		var todo:Null<Array<Chunk>> = null;
		inline function check(c:Chunk) {
			#if MULTIANIM_ALLOC_TRACK
			chunkChecks++;
			#end
			if (c.dirty && (!onlyVisible || c.shown)) {
				if (todo == null)
					todo = [];
				todo.push(c);
			}
		}
		if (onlyVisible && !shownAll) {
			for (row in shownRow0...shownRow1 + 1)
				for (col in shownCol0...shownCol1 + 1)
					check(chunks[row * chunkCols + col]);
		} else {
			for (c in chunks)
				check(c);
		}
		if (todo != null)
			drawChunks(todo);
	}

	/** Works out the sides and metadata of the chunk a cell is in, if they changed: what `sideAt` and `metadataAt` read, drawing nothing. **/
	function resolveCellsChunk(cx:Int, cy:Int):Void {
		final c = chunks[Std.int(cy / chunkSize) * chunkCols + Std.int(cx / chunkSize)];
		if (!c.resolved)
			resolveChunk(c);
	}

	/** Draws some chunks in one pass, whose masks cover them and a cell around: as far as an autotile's index looks. **/
	function drawChunks(todo:Array<Chunk>):Void {
		var x0 = width, y0 = height, x1 = 0, y1 = 0;
		for (c in todo) {
			if (c.rect.x0 < x0) x0 = c.rect.x0;
			if (c.rect.y0 < y0) y0 = c.rect.y0;
			if (c.rect.x1 > x1) x1 = c.rect.x1;
			if (c.rect.y1 > y1) y1 = c.rect.y1;
		}
		beginPass({
			x0: x0 > 0 ? x0 - 1 : 0,
			y0: y0 > 0 ? y0 - 1 : 0,
			x1: x1 < width ? x1 + 1 : width,
			y1: y1 < height ? y1 + 1 : height,
		});
		for (c in todo)
			drawChunk(c);
		endPass();
		changed = false;
		for (c in chunks)
			if (c.dirty) {
				changed = true;
				break;
			}
	}

	/** The masks a pass needs are made once, over its rectangle, as a chunk first asks for them. **/
	function beginPass(rect:CellRect):Void {
		passRect = rect;
		passTerrainMasks = [for (_ in tileset.terrains) null];
		passOwnTerrainMasks = [for (_ in tileset.terrains) null];
		passTransitionMasks = [for (_ in tileset.transitions) null];
		passLevelMasks = [];
		passPlatformMasks = [];
		passHighest = -1;
	}

	function endPass():Void {
		passTerrainMasks = [];
		passOwnTerrainMasks = [];
		passTransitionMasks = [];
		passLevelMasks = [];
		passPlatformMasks = [];
	}

	/**
		Rows for a grid over a rectangle of positions, the pass rectangle's corner its `[0][0]`: the
		rows above it empty, each row's positions before it 0 (a cell at most, the margin around a
		chunk), the rest 0 to be set. An autotile walks just the rectangle, and what reads it
		(`Autotile.isFilled`) takes a missing position as 0.
	**/
	function gridOver(r:CellRect):Array<Array<Int>> {
		final rows:Array<Array<Int>> = [for (_ in 0...r.y0 - passRect.y0) EMPTY_ROW];
		final cols = r.x1 - passRect.x0;
		for (_ in r.y0...r.y1)
			rows.push([for (_ in 0...cols) 0]);
		return rows;
	}

	/**
		The mask terrain `i`'s autotile is drawn over: a ground's (blob47, corner, …) is its cells and
		those of every terrain above it, so the terrains above stand on it; a line's (`connect16`, a
		road) is its own cells alone, so it joins only its own and runs under nothing else.
	**/
	function autotileMask(i:Int, format:AutotileFormat):Array<Array<Int>> {
		if (format != Connect16)
			return terrainMask(i);
		var mask = passOwnTerrainMasks[i];
		if (mask == null) {
			mask = gridOver(passRect);
			for (cy in passRect.y0...passRect.y1) {
				final row = mask[cy - passRect.y0];
				for (cx in passRect.x0...passRect.x1)
					row[cx - passRect.x0] = terrainIndex[cy * width + cx] == i ? 1 : 0;
			}
			passOwnTerrainMasks[i] = mask;
		}
		return mask;
	}

	/**
		The mask transition `ti`'s autotile is indexed over: its terrain's own (`own`, `autotileMask`),
		and for a transition with `ignore:` the cells of the terrains it ignores too, so its edge faces
		the terrain it is drawn toward and none of them. Made once a pass, as the terrains' masks are.
	**/
	function transitionMask(ti:Int, own:Array<Array<Int>>):Array<Array<Int>> {
		final ignored = transitionIgnored[ti];
		if (ignored == null)
			return own;
		var mask = passTransitionMasks[ti];
		if (mask == null) {
			mask = gridOver(passRect);
			for (cy in passRect.y0...passRect.y1) {
				final row = mask[cy - passRect.y0];
				final ownRow = own[cy - passRect.y0];
				for (cx in passRect.x0...passRect.x1) {
					final t = terrainIndex[cy * width + cx];
					row[cx - passRect.x0] = ownRow[cx - passRect.x0] != 0 || (t >= 0 && ignored[t]) ? 1 : 0;
				}
			}
			passTransitionMasks[ti] = mask;
		}
		return mask;
	}

	/** Terrain `i`'s cells and those of every terrain above it, within the pass. **/
	function terrainMask(i:Int):Array<Array<Int>> {
		var mask = passTerrainMasks[i];
		if (mask == null) {
			mask = gridOver(passRect);
			for (cy in passRect.y0...passRect.y1) {
				final row = mask[cy - passRect.y0];
				for (cx in passRect.x0...passRect.x1)
					row[cx - passRect.x0] = terrainIndex[cy * width + cx] >= i ? 1 : 0;
			}
			passTerrainMasks[i] = mask;
		}
		return mask;
	}

	/** The ground's cells at `level` or above, platforms left out, within the pass. **/
	function levelMask(level:Int):Array<Array<Int>> {
		var mask = passLevelMasks.get(level);
		if (mask == null) {
			mask = gridOver(passRect);
			for (cy in passRect.y0...passRect.y1) {
				final row = mask[cy - passRect.y0];
				for (cx in passRect.x0...passRect.x1) {
					final i = cy * width + cx;
					row[cx - passRect.x0] = levelIndex[i] >= level && platformIndex[i] < 0 ? 1 : 0;
				}
			}
			passLevelMasks.set(level, mask);
		}
		return mask;
	}

	/** A platform's cells (by its index in `platformNames`) at `level` or above, within the pass; null when it has none there. **/
	function platformMask(platform:Int, level:Int):Null<Array<Array<Int>>> {
		final key = level * platformNames.length + platform;
		if (passPlatformMasks.exists(key))
			return passPlatformMasks.get(key);
		final mask = gridOver(passRect);
		var any = false;
		for (cy in passRect.y0...passRect.y1) {
			final row = mask[cy - passRect.y0];
			for (cx in passRect.x0...passRect.x1) {
				final i = cy * width + cx;
				if (levelIndex[i] >= level && platformIndex[i] == platform) {
					row[cx - passRect.x0] = 1;
					any = true;
				}
			}
		}
		passPlatformMasks.set(key, any ? mask : null);
		return any ? mask : null;
	}

	/** The highest level within the pass: a level nowhere near the chunks drawn has nothing to draw in them. **/
	function highestLevel():Int {
		if (passHighest < 0) {
			var highest = 0;
			for (cy in passRect.y0...passRect.y1)
				for (cx in passRect.x0...passRect.x1) {
					final level = levelIndex[cy * width + cx];
					if (level > highest) highest = level;
				}
			passHighest = highest;
		}
		return passHighest;
	}

	/** A chunk's tiles drawn again, and its cells worked out with them. **/
	function drawChunk(c:Chunk):Void {
		c.dirty = false;
		clearChunk(c);
		columnOf = [];
		clearSides(c);
		drawTerrains(c);
		drawRises(c);
		drawLayers(c);
		mergeMetadata(c);
		c.resolved = true;
	}

	/** A chunk's cells worked out again, nothing drawn: the sides over them, then their metadata. **/
	function resolveChunk(c:Chunk):Void {
		clearSides(c);
		scanRises(c, null);
		mergeMetadata(c);
		c.resolved = true;
	}

	function clearSides(c:Chunk):Void {
		for (cy in c.rect.y0...c.rect.y1)
			for (cx in c.rect.x0...c.rect.x1) {
				sides[cy * width + cx] = 0;
				sideRises[cy * width + cx] = -1;
			}
	}

	/**
		The autotile positions a chunk owns, for a format: its cells, or for the corner format its
		corners from its top-left one up to, not including, the next chunk's, the map's last column
		and row of corners going to the last chunks.
	**/
	function positionsOf(c:Chunk, format:AutotileFormat):CellRect {
		return switch format {
			case Corner: {
					x0: c.rect.x0,
					y0: c.rect.y0,
					x1: c.rect.x1 == width ? width + 1 : c.rect.x1,
					y1: c.rect.y1 == height ? height + 1 : c.rect.y1,
				};
			case Cross | Blob47 | Hex64 | Connect16: c.rect;
		};
	}

	/**
		The positions of a rectangle an autotile over `mask` draws anything at: corners with a filled
		cell around them, or filled cells. Null when none, so a terrain absent from a chunk is not
		asked for at all.
	**/
	function drawnPositions(mask:Array<Array<Int>>, format:AutotileFormat, r:CellRect):Null<Array<Array<Int>>> {
		final ox = passRect.x0;
		final oy = passRect.y0;
		final where = gridOver(r);
		var any = false;
		for (cy in r.y0...r.y1) {
			final row = where[cy - oy];
			for (cx in r.x0...r.x1) {
				final drawn = switch format {
					case Corner: Autotile.getCornerIndex(mask, cx - ox, cy - oy) != 0;
					case Cross | Blob47 | Hex64 | Connect16: Autotile.isFilled(mask, cx - ox, cy - oy);
				};
				if (drawn) {
					row[cx - ox] = 1;
					any = true;
				}
			}
		}
		return any ? where : null;
	}

	function drawTerrains(c:Chunk):Void {
		// off the square grid every terrain is drawn in one pass, back to front, animated ones too
		if (grid.kind != Orthogonal) {
			drawGroundInOrder(c);
			return;
		}
		for (i in 0...tileset.terrains.length) {
			final terrain = tileset.terrains[i];
			final frames = terrainFrames[i];
			if (frames != null) {
				final groups = new TileGroups(this, c, i);
				for (cy in c.rect.y0...c.rect.y1)
					for (cx in c.rect.x0...c.rect.x1)
						if (terrainIndex[cy * width + cx] >= i) {
							final f = frames[Autotile.variantAt(cx, cy, frames.length)];
							groups.add(grid.frameX(cx, cy, f.width), grid.frameY(cx, cy, f.height), f.tile);
						}
				continue;
			}
			if (terrain.autotiles.length == 0)
				continue;
			final format = tiles.autotileFormat(terrain.autotiles[0]);
			final mask = autotileMask(i, format);
			final ownWhere = drawnPositions(mask, format, positionsOf(c, format));
			if (ownWhere == null)
				continue; // none of the terrain near this chunk
			// The terrain's own autotile over its cells and those of the terrains above it; then,
			// where it meets a terrain it has a transition from, that pair's autotile over the
			// meeting positions. An animated terrain has one of each a frame; the meeting positions
			// depend on the autotile's format alone, so they are found once a format, not once a frame.
			// A transition with `ignore:` is indexed over a mask its ignored terrains' cells are in too.
			final transitionIndices = [for (ti in 0...tileset.transitions.length) if (tileset.transitions[ti].to == terrain.name) ti];
			final transitions = [for (ti in transitionIndices) tileset.transitions[ti]];
			final meeting:Array<Array<Null<Array<Array<Int>>>>> = [for (_ in transitions) [for (_ in 0...FORMAT_COUNT) null]];
			final meetingFound:Array<Array<Bool>> = [for (_ in transitions) [for (_ in 0...FORMAT_COUNT) false]];
			final frameGroups:Array<h2d.Object> = [];
			for (k in 0...terrain.autotiles.length) {
				final ownGroup = autotileGroup(terrain.autotiles[k], mask, ownWhere, passRect.x0, passRect.y0);
				if (transitions.length == 0) {
					frameGroups.push(ownGroup);
					continue;
				}
				final frame = new h2d.Object();
				frame.addChild(ownGroup);
				for (ti in 0...transitions.length) {
					final tIndex = transitionIndices[ti];
					final autotile = transitions[ti].autotiles[k];
					final format = tiles.autotileFormat(autotile);
					final fi = Type.enumIndex(format);
					if (!meetingFound[ti][fi]) {
						meeting[ti][fi] = meetingPositions(i, transitionFrom[tIndex], format, positionsOf(c, format), transitionIgnored[tIndex]);
						meetingFound[ti][fi] = true;
					}
					final where = meeting[ti][fi];
					if (where != null)
						frame.addChild(autotileGroup(autotile, transitionMask(tIndex, mask), where, passRect.x0, passRect.y0));
				}
				frameGroups.push(frame);
			}
			final part = partOf(c, i);
			for (g in frameGroups)
				part.addChild(g);
			if (frameGroups.length > 1) {
				showFrame(frameGroups, animClocks[i].index);
				c.animated.push({terrain: i, frames: frameGroups});
			}
		}
	}

	/**
		The terrains off the square grid, in one pass and back to front: row by row (on flat hexes the
		row's columns not pushed, then the pushed ones, which are lower), each position's terrains
		bottom first, a transition's tile right after its terrain's. A frame taller than its cell (a
		block with its side, a hex with its edge) then covers the cells behind it and is covered by
		those in front, whichever terrain each is; drawn a terrain a pass, as on the square grid, a
		terrain above would cover the cells in front of it. Under a cell of a `cells:` terrain no
		terrain below is drawn: its frame is the whole cell, as the one below would be. An animated
		terrain is drawn in its place in the order too: from its first tile on, a run of an object a
		frame shown in turn, the still tiles after it in every frame of it (`OrderedTiles`).
	**/
	function drawGroundInOrder(c:Chunk):Void {
		final plans = groundPlans(c);
		chunkPlans = plans;
		if (plans.length == 0)
			return;
		final groups = new TileGroups(this, c, plans[plans.length - 1].terrain);
		final flatHex = grid.kind == Hex && !grid.pointy;
		final lifting = lift > 0 && def.levels.length > 0;
		final lastRow = c.rect.y1 == height ? height + 1 : c.rect.y1;
		// a corner format's positions reach a column past the map's last
		final lastColumn = c.rect.x1 == width ? width + 1 : c.rect.x1;
		final cells = c.rect;
		final corners = positionsOf(c, Corner);
		// position by position, each one's terrains bottom first: a cell's neighbour along its row
		// is in front of it on the isometric grid, so a row's terrains a pass would draw a terrain
		// over the cells in front of it
		for (cy in c.rect.y0...lastRow)
			for (half in 0...(flatHex ? 2 : 1))
				for (cx in c.rect.x0...lastColumn) {
					if (flatHex && grid.pushed(cx) != (half == 1))
						continue;
					for (plan in plans) {
						final corner = plan.format == Corner;
						final r = corner ? corners : cells;
						if (cy >= r.y1 || cx >= r.x1)
							continue;
						if (!corner && liftedAt(cx, cy))
							continue; // a raised cell is drawn with its column, among the actors
						emitGround(plan, cx, cy, groups, 0);
					}
					if (cx < cells.x1 && cy < cells.y1) {
						// a raised cell's lowest level of side, in its place: the cells in front cover
						// what of it reaches past the cell
						if (lifting && liftedAt(cx, cy))
							emitSides(cx, cy, 0, 1, groups);
						emitStandingBelow(cx, cy, groups);
					}
				}
		if (lifting)
			drawColumns(c, plans);
	}

	/**
		The raised cells of a chunk, drawn lifted. Each cell's side, from the level of the neighbour
		in front of it up to its own, a rise's piece a level (`span` frames from the top down, the
		last again below them), and on it the cell's terrains lifted by its level. The lowest level of
		its side is drawn with the ground, back to front, where what stands in front covers what of it
		reaches past its cell; the rest, its top and the layers' cells on it (`drawLayers`) are a
		column among the actors, sorted by the middle of the cell on the ground less half a pixel, so
		it is in front of what stands behind the cell, behind what stands in front of it, and under
		what stands on it, an actor on it giving its feet on the ground (`centerOf`) and drawing
		itself `liftAt` higher.
	**/
	function drawColumns(c:Chunk, plans:Array<GroundPlan>):Void {
		columnOf = [];
		for (cy in c.rect.y0...c.rect.y1)
			for (cx in c.rect.x0...c.rect.x1) {
				if (!liftedAt(cx, cy))
					continue;
				final level = levelIndex[cy * width + cx];
				final column = columnAt(c, cx, cy);
				emitSides(cx, cy, 1, level, column);
				for (plan in plans)
					if (plan.format != Corner)
						emitGround(plan, cx, cy, column, level * lift);
			}
	}

	/** Where a raised cell's column sorts among the actors: the cell's middle on the ground, less half a pixel. **/
	inline function columnSortY(cx:Int, cy:Int):Float {
		return grid.pixelY(cx, cy) + grid.tileHeight / 2 - 0.5;
	}

	/**
		The column a raised cell's tiles are drawn on, among the actors: the cell's own, made as it is
		first asked for. A chunk asking for the column of a cell of another chunk (a lifted corner
		tile whose front cell is there) gets one of its own, sorted right after that cell's.
	**/
	function columnAt(c:Chunk, cx:Int, cy:Int):ColumnTiles {
		final i = cy * width + cx;
		var column = columnOf.get(i);
		if (column == null) {
			final own = cx >= c.rect.x0 && cx < c.rect.x1 && cy >= c.rect.y0 && cy < c.rect.y1;
			column = new ColumnTiles(this, c, columnSortY(cx, cy) + (own ? 0 : 0.125));
			column.object.visible = c.shown;
			actors.add(column.object, 0);
			c.objects.push(column.object);
			columnOf.set(i, column);
		}
		return column;
	}

	/**
		How many levels a raised cell's side drops toward a direction (`TileGrid.towardDirection`; -1,
		`down`: to the lowest of the neighbours `below()` gives), the map's edge counting as level 0;
		0 where it stands no higher.
	**/
	function dropToward(cx:Int, cy:Int, direction:Int):Int {
		final level = levelIndex[cy * width + cx];
		var lowest = level;
		inline function look(d:Int) {
			final nx = grid.neighbourX(cx, cy, d);
			final ny = grid.neighbourY(cx, cy, d);
			final n = inside(nx, ny) ? levelIndex[ny * width + nx] : 0;
			if (n < lowest) lowest = n;
		}
		if (direction < 0)
			for (b in grid.below())
				look(b);
		else
			look(direction);
		return level - lowest;
	}

	/**
		Which of the tileset's rises draws a raised cell's side toward the side faced `toward` (by its
		index in `towardNames`), lifted, at the level of side `band` (the piece from `band` up to `band +
		1`); -1 for none there.
	**/
	function liftedRiseAt(cx:Int, cy:Int, toward:Int, band:Int):Int {
		if (!inside(cx, cy))
			return -1;
		final level = levelIndex[cy * width + cx];
		final drop = dropToward(cx, cy, grid.towardDirection(towardNames[toward]));
		return drop > 0 && band < level && band >= level - drop ? riseOf(cy * width + cx, toward, drop) : -1;
	}

	/**
		A raised cell's side pieces for the levels `from` up to, not including, `to` (bottom first),
		toward each face the tileset draws a side toward: `down` every face below at once, from the
		lowest neighbour there (the map's edge counting as level 0), or one face (`se`, `sw`, `s`),
		its piece against that face's side of the cell (`TileGrid.faceX`). The piece is the run's
		`left` or `right` end, or `single`, where the rise names them (`liftedPiece`). Where a layer's
		cell drawn in the side's place (`draw: side`) covers the cell, no face's piece is drawn: the
		cells anchored here are drawn in their place instead (`emitSideCells`).
	**/
	function emitSides(cx:Int, cy:Int, from:Int, to:Int, sink:TileSink):Void {
		final i = cy * width + cx;
		final level = levelIndex[i];
		if (to > level) to = level;
		if (from >= to)
			return;
		if (hasSideCells && sideCellOver(i)) {
			emitSideCells(cx, cy, from, to, sink);
			return;
		}
		for (k in from...to)
			for (ti in 0...towardNames.length) {
				final d = grid.towardDirection(towardNames[ti]);
				final drop = dropToward(cx, cy, d);
				if (drop <= 0 || k < level - drop)
					continue;
				final r = riseOf(i, ti, drop);
				if (r < 0)
					continue;
				final frames = pieceFramesOf(liftedPiece(cx, cy, ti, d, r, k));
				final j = level - 1 - k;
				final f = frames[j < frames.length ? j : frames.length - 1];
				final x = d < 0 ? grid.frameX(cx, cy, f.width) : grid.faceX(cx, cy, d, f.width);
				sink.add(x, grid.frameY(cx, cy, f.height) - k * lift, f.tile);
			}
	}

	/** Whether a layer's cell drawn in place of a rise's side (`draw: side`) covers a cell (by its index): its own, or an object's of several cells. **/
	function sideCellOver(i:Int):Bool {
		for (li in 0...covers.length) {
			final anchor = covers[li][i];
			if (anchor >= 0 && entryAt(li, anchor).draw == "side")
				return true;
		}
		return false;
	}

	/**
		How many levels a raised cell's side drops on a lifted map, where the tileset draws one: the most
		toward any side it faces (`noteLiftedSides`' answer); 0 where it shows no side.
	**/
	function liftedDrop(cx:Int, cy:Int):Int {
		final i = cy * width + cx;
		if (levelIndex[i] <= 0)
			return 0;
		var most = 0;
		for (ti in 0...towardNames.length) {
			final drop = dropToward(cx, cy, grid.towardDirection(towardNames[ti]));
			if (drop > most && riseOf(i, ti, drop) >= 0)
				most = drop;
		}
		return most;
	}

	/**
		The layers' cells drawn in place of a raised cell's side (`draw: side`) anchored at it, for the
		levels of side `from` up to, not including, `to`: a piece a level, as a rise's side is (the
		cell's frames from the top down, the last again below them), standing on the cell (an object
		of several cells on its footprint's box), whole, where the side's pieces of every face would be.
		Nothing where the cell shows no side: `drawLayers` draws it then, as an `under` cell.
	**/
	function emitSideCells(cx:Int, cy:Int, from:Int, to:Int, sink:TileSink):Void {
		final i = cy * width + cx;
		final level = levelIndex[i];
		final drop = liftedDrop(cx, cy);
		if (drop <= 0)
			return;
		final lowest = level - drop;
		if (from < lowest) from = lowest;
		for (li in 0...layerCell.length) {
			final e = layerCell[li][i];
			if (e < 0)
				continue;
			final entry = layerEntries[li][e];
			if (entry.draw != "side")
				continue;
			final cell = entry.cell;
			final w = cell != null && cell.width != null ? cell.width : 1;
			final h = cell != null && cell.height != null ? cell.height : 1;
			final x0 = cx - entry.anchorX;
			final y0 = cy - entry.anchorY;
			final box = grid.bounds(x0, y0, x0 + w, y0 + h, scratchBounds);
			final boxX = box.xMin;
			final boxY = box.yMin;
			final boxW = box.width;
			final boxH = box.height;
			final frames = entry.frames;
			for (k in from...to) {
				final j = level - 1 - k;
				final f = frames[j < frames.length ? j : frames.length - 1];
				sink.add(grid.frameLeft(boxX, f.width, boxW), grid.frameTop(boxY, f.height, boxH) - k * lift, f.tile);
			}
		}
	}

	/**
		The piece of a raised cell's side toward a face, as `sidePiece` picks one on the square grid:
		its run's ends, a side one cell long, or its middle (several taken in turn along the run). On
		the isometric grid a run goes along the screen: an `se` face's along its column (cy), an `sw`
		face's along its row (cx), and the front of `down` (both faces in one piece) along the cells'
		fronts, the `sw` faces up to the corner and the `se` faces from it; `left` is its end on the
		left of the screen, `right` on the right. On the hex grid every face's run follows the cells'
		lower outline (`hexRunNeighbour`), whose faces zigzag. A run is a level of side's (`band`, the
		piece from `band` up to `band + 1`; -1, the cell's top one): the outline is that of the cells
		standing higher than the band, and a neighbour goes on with the run where its side has a piece
		at that band drawn by the same rise. So a cell two up beside one up continues its neighbour's
		run in its lower piece and ends its own in its upper one.
	**/
	function liftedPiece(cx:Int, cy:Int, toward:Int, direction:Int, index:Int, band:Int = -1):String {
		final rise = tileset.rises[index];
		if (grid.kind == Orthogonal || (rise.left == null && rise.right == null && rise.single == null && rise.sides.length < 2))
			return rise.sides[0];
		final k = band >= 0 ? band : levelIndex[cy * width + cx] - 1;
		final p = scratchCell;
		inline function goesOn(x:Int, y:Int):Bool
			return liftedRiseAt(x, y, toward, k) == index;
		runNeighbour(cx, cy, direction, -1, k, p);
		final before = goesOn(p.x, p.y);
		runNeighbour(cx, cy, direction, 1, k, p);
		final after = goesOn(p.x, p.y);
		// how far along the run, from its left end: each step left moves left on screen (or, on a flat
		// hex, straight down), so the walk ends; the map's size bounds it all the same
		var along = 0;
		if (before && rise.sides.length > 1) {
			var x = cx, y = cy;
			final most = width * height;
			while (along < most) {
				runNeighbour(x, y, direction, -1, k, p);
				if (!goesOn(p.x, p.y))
					break;
				x = p.x;
				y = p.y;
				along++;
			}
		}
		return sidePiece(rise, before, after, along);
	}

	/**
		The cell beside a raised cell along its side's run, on the isometric grid: to the left on screen
		(`way` -1) or to the right (1). An `se` face's run goes along cy, an `sw` face's along cx; the
		front of `down` goes left along the `sw` faces where its `sw` face shows (else along the `se`
		ones) and right along the `se` faces where its `se` face shows (else along the `sw` ones); a
		face shows at the level of side `band` where the neighbour there stands no higher than it.
	**/
	function runNeighbour(cx:Int, cy:Int, direction:Int, way:Int, band:Int, out:h2d.col.IPoint):Void {
		if (grid.kind == Hex) {
			hexRunNeighbour(cx, cy, way, band, out);
			return;
		}
		var alongX = direction == 4;
		if (direction < 0) {
			// down: whether each front face shows, its neighbour lower
			inline function lower(x:Int, y:Int):Bool
				return !inside(x, y) || levelIndex[y * width + x] <= band;
			alongX = way < 0 ? lower(cx, cy + 1) : !lower(cx + 1, cy);
		}
		if (alongX)
			out.set(cx + way, cy);
		else
			out.set(cx, cy - way);
	}

	/**
		The next cell along a raised cell's lower outline on the hex grid, to the left on screen (`way`
		-1) or to the right (1), whatever face the run is of: the outline walked past the cell's last
		face that shows on that side at the level of side `band` (the neighbour below it no higher than
		`band`, the map's edge counting as lower). Past its outermost face (se going right, sw going
		left) the outline goes on along the next cell's faces: on a pointy hex the cell beside it (e, w)
		when that stands higher, else up its upright side to the one above (ne, nw); on a flat hex the
		one above (ne, nw). Past an inner face (a pointy hex's se hidden, a flat hex's s or se) the
		cell in front of the hidden face goes on.
	**/
	function hexRunNeighbour(cx:Int, cy:Int, way:Int, band:Int, out:h2d.col.IPoint):Void {
		inline function lower(d:Int):Bool {
			final nx = grid.neighbourX(cx, cy, d);
			final ny = grid.neighbourY(cx, cy, d);
			return !inside(nx, ny) || levelIndex[ny * width + nx] <= band;
		}
		// the faces below, right to left: pointy se 2, sw 3; flat se 2, s 3, sw 4
		final first = 2;
		final last = grid.pointy ? 3 : 4;
		var next:Int;
		if (way > 0) {
			var d = first;
			while (d < last && !lower(d))
				d++;
			// the outermost face shows (or none but the last): past its right end
			// (pointy: e 1, else ne 0; flat: ne 1)
			next = d == first && lower(first) ? (grid.pointy ? (!lower(1) ? 1 : 0) : 1) : d - 1;
		} else {
			var d = last;
			while (d > first && !lower(d))
				d--;
			// (pointy: w 4, else nw 5; flat: nw 5)
			next = d == last && lower(last) ? (grid.pointy && !lower(4) ? 4 : 5) : d + 1;
		}
		out.set(grid.neighbourX(cx, cy, next), grid.neighbourY(cx, cy, next));
	}

	/**
		The sides of a chunk's raised cells as `sideAt` reads them, nothing drawn: a lifted map draws a
		raised cell's side on the cell itself, so the cell has it, the most levels it drops toward any
		face and the rise that draws that (the first of the tileset's sides faced, on a tie), whose
		metadata the cell takes.
	**/
	function noteLiftedSides(c:Chunk):Void {
		for (cy in c.rect.y0...c.rect.y1)
			for (cx in c.rect.x0...c.rect.x1) {
				final i = cy * width + cx;
				if (levelIndex[i] <= 0)
					continue;
				for (ti in 0...towardNames.length) {
					final drop = dropToward(cx, cy, grid.towardDirection(towardNames[ti]));
					if (drop <= sides[i])
						continue;
					final r = riseOf(i, ti, drop);
					if (r < 0)
						continue;
					sides[i] = drop;
					sideRises[i] = r;
				}
			}
	}

	/**
		The levels' edges and the platforms' tops of a chunk on a lifted map: each drawn on the raised
		cells' tops at their level, in their columns. A level's edge is drawn along its rim on the cells
		of that level (a cell higher up shows its own level's), a platform's top over its cells of that
		level; a corner tile, which four cells share, at the highest level around it, on the column of
		the front one of that level.
	**/
	function drawLiftedTops(c:Chunk):Void {
		final highest = highestLevel();
		for (level in 1...highest + 1) {
			final mask = levelMask(level);
			for (name in edgeNames) {
				final format = tiles.autotileFormat(name);
				final where = rimPositions(mask, name, format, positionsOf(c, format));
				if (where != null)
					liftedAutotile(c, name, format, mask, where, level, -1);
			}
		}
		for (platform in tileset.platforms) {
			final edge = platform.edge;
			final pi = platformNames.indexOf(platform.name);
			if (edge == null || pi < 0)
				continue;
			final format = tiles.autotileFormat(edge);
			for (level in 1...highest + 1) {
				final mask = platformMask(pi, level);
				if (mask == null)
					continue;
				final where = drawnPositions(mask, format, positionsOf(c, format));
				if (where != null)
					liftedAutotile(c, edge, format, mask, where, level, pi);
			}
		}
	}

	/**
		An autotile over a level's (or a platform's, `platform` its index, -1 the ground's) mask drawn
		lifted at that level, on the columns of the cells of that level, at the positions `where` has.
	**/
	function liftedAutotile(c:Chunk, name:String, format:AutotileFormat, mask:Array<Array<Int>>, where:Array<Array<Int>>, level:Int, platform:Int):Void {
		final r = positionsOf(c, format);
		final ox = passRect.x0;
		final oy = passRect.y0;
		inline function ofLevel(x:Int, y:Int):Bool
			return inside(x, y) && levelIndex[y * width + x] == level && platformIndex[y * width + x] == platform;
		for (cy in r.y0...r.y1)
			for (cx in r.x0...r.x1) {
				if (!Autotile.isFilled(where, cx - ox, cy - oy))
					continue;
				var x = cx, y = cy;
				if (format == Corner) {
					// the four cells about the corner, the front one first: drawn at the highest level there
					var top = 0;
					for (dy in -1...1)
						for (dx in -1...1)
							if (inside(cx + dx, cy + dy) && levelIndex[(cy + dy) * width + cx + dx] > top) top = levelIndex[(cy + dy) * width + cx + dx];
					if (top != level)
						continue;
					var found = false;
					for (n in 0...4)
						if (ofLevel(cx - (n & 1), cy - (n >> 1))) {
							x = cx - (n & 1);
							y = cy - (n >> 1);
							found = true;
							break;
						}
					if (!found)
						continue;
				} else if (!ofLevel(cx, cy))
					continue;
				placeAutotileTile(name, format, mask, cx, cy, columnAt(c, x, y), level * lift, -1, -1);
			}
	}

	/** What `drawGroundInOrder` draws of each terrain, bottom first; those not near the chunk left out. **/
	function groundPlans(c:Chunk):Array<GroundPlan> {
		final plans:Array<GroundPlan> = [];
		for (i in 0...tileset.terrains.length) {
			final terrain = tileset.terrains[i];
			final frames = terrainFrames[i];
			if (frames != null) {
				plans.push({terrain: i, frames: frames, autotiles: [], format: Blob47, mask: null, where: null, transitions: []});
				continue;
			}
			if (terrain.autotiles.length == 0)
				continue;
			final autotile = terrain.autotiles[0];
			final format = tiles.autotileFormat(autotile);
			final mask = autotileMask(i, format);
			if ((format == Corner || format == Connect16) && grid.kind == Hex)
				throw BuilderError.of('tilemap $mapName: terrain ${terrain.name}: autotile $autotile is of the ${format == Corner ? "corner" : "connect16"} format, which has no hex form (blob47, cross or hex64 are)',
					"tilemap_grid");
			final where = drawnPositions(mask, format, positionsOf(c, format));
			if (where == null)
				continue;
			final transitions:Array<GroundTransition> = [];
			for (ti in 0...tileset.transitions.length) {
				final t = tileset.transitions[ti];
				if (t.to == terrain.name) {
					final tf = tiles.autotileFormat(t.autotiles[0]);
					final meeting = meetingPositions(i, transitionFrom[ti], tf, positionsOf(c, tf), transitionIgnored[ti]);
					if (meeting != null)
						transitions.push({autotiles: t.autotiles, format: tf, where: meeting, mask: transitionMask(ti, mask)});
				}
			}
			plans.push({
				terrain: i,
				frames: null,
				autotiles: terrain.autotiles,
				format: format,
				mask: mask,
				where: where,
				transitions: transitions
			});
		}
		return plans;
	}

	/**
		A terrain's tile at a position (a cell, or a corner of the corner format), and its transitions'
		there, moved up by `up` pixels; an animated terrain's a frame each.
	**/
	function emitGround(plan:GroundPlan, cx:Int, cy:Int, groups:TileSink, up:Float):Void {
		final frames = plan.frames;
		if (frames != null) {
			final t = terrainIndex[cy * width + cx];
			// under a cell of another `cells:` terrain nothing is drawn: its frame covers the cell
			if (t < plan.terrain || (t > plan.terrain && terrainFrames[t] != null))
				return;
			final f = frames[Autotile.variantAt(cx, cy, frames.length)];
			groups.add(grid.frameX(cx, cy, f.width), grid.frameY(cx, cy, f.height) - up, f.tile);
			return;
		}
		final where = plan.where;
		final ox = passRect.x0;
		final oy = passRect.y0;
		if (where == null || !Autotile.isFilled(where, cx - ox, cy - oy))
			return;
		final mask:Array<Array<Int>> = cast plan.mask;
		final count = plan.autotiles.length;
		// a still terrain's tiles go with the rest; an animated one's into a frame each (`frame` -1: still)
		for (k in 0...count) {
			final frame = count > 1 ? k : -1;
			placeAutotileTile(plan.autotiles[k], plan.format, mask, cx, cy, groups, up, plan.terrain, frame, count);
			for (t in plan.transitions)
				if (Autotile.isFilled(t.where, cx - ox, cy - oy))
					placeAutotileTile(t.autotiles[k < t.autotiles.length ? k : t.autotiles.length - 1], t.format, t.mask, cx, cy, groups, up, plan.terrain,
						frame, count);
		}
	}

	/**
		The tile an autotile draws at a position over a pass's mask, put on the grid as `buildAutotile`
		puts it; frame `frame` of `frames` of terrain `terrain`'s animation, or a still tile (`frame` -1).
	**/
	function placeAutotileTile(name:String, format:AutotileFormat, mask:Array<Array<Int>>, cx:Int, cy:Int, groups:TileSink, up:Float, terrain:Int, frame:Int,
			frames = 1):Void {
		final lx = cx - passRect.x0;
		final ly = cy - passRect.y0;
		final index = switch format {
			case Corner: Autotile.getCornerIndex(mask, lx, ly);
			case Cross: Autotile.getCrossIndex(Autotile.getNeighborMask8(mask, lx, ly));
			case Blob47: Autotile.getBlob47Index(Autotile.getNeighborMask8(mask, lx, ly));
			case Hex64: Autotile.getHexIndex(mask, lx, ly, grid, passRect.x0, passRect.y0);
			// on the isometric grid too: N, E, S and W are the grid's, the diamond's four edges
			case Connect16: Autotile.getConnect16Index(mask, lx, ly);
		};
		if (format == Corner && index == 0)
			return;
		final tileAt = tiles.autotileTile;
		if (tileAt == null)
			throw BuilderError.of('tilemap $mapName: its tiles give no autotile tile by index, which a map off the square grid needs', "tilemap_grid");
		final f = tileAt(name, index, cx, cy);
		if (f == null)
			return;
		final x = format == Corner ? grid.frameLeft(grid.cornerX(cx, cy), f.width, grid.tileWidth) : grid.frameX(cx, cy, f.width);
		final y = (format == Corner ? grid.frameTop(grid.cornerY(cx, cy), f.height, grid.tileHeight) : grid.frameY(cx, cy, f.height)) - up;
		if (frame < 0)
			groups.add(x, y, f.tile);
		else
			groups.addFrame(terrain, frames, frame, x, y, f.tile);
	}

	/** Whether a cell is drawn lifted, with its column among the actors (a raised cell off the square grid). **/
	function liftedAt(cx:Int, cy:Int):Bool {
		return lift > 0 && inside(cx, cy) && levelIndex[cy * width + cx] > 0;
	}

	/** An autotile over a pass's mask, its tiles put on the map's grid. **/
	function autotileGroup(name:String, mask:Array<Array<Int>>, where:Null<Array<Array<Int>>>, x0:Int, y0:Int):h2d.TileGroup {
		final on = tiles.autotileOn;
		return grid.kind == Orthogonal || on == null ? tiles.autotile(name, mask, where, x0, y0) : on(name, mask, where, x0, y0, grid);
	}

	/** The index of a terrain of the tileset, -1 for `none` (null, or a name it has not). **/
	function terrainIndexOf(name:Null<String>):Int {
		for (i in 0...tileset.terrains.length)
			if (tileset.terrains[i].name == name) return i;
		return -1;
	}

	/**
		Where terrain `i` (with the terrains above it) meets terrain `from` and nothing else, within
		a rectangle of positions: the autotile positions (corners of the corner format, cells
		otherwise) whose surrounding cells are some of each, every outside one being `from` (-1 for
		`none`, which the map's edge counts as). A terrain `ignored` says (by index, a transition's
		`ignore:`) is neither: it neither stops a position nor makes one, so a cell of `i` that touches
		`from` and an ignored terrain still meets `from`, and one with no cell of `i` (or above) about
		it does not. Null when there is no such position.
	**/
	function meetingPositions(i:Int, from:Int, format:AutotileFormat, r:CellRect, ?ignored:Array<Bool>):Null<Array<Array<Int>>> {
		inline function terrainAtCell(cx:Int, cy:Int):Int
			return inside(cx, cy) ? terrainIndex[cy * width + cx] : -1;
		final ox = passRect.x0;
		final oy = passRect.y0;
		final where = gridOver(r);
		var any = false;
		// the cells around a position: the four about a corner, the nine about a cell
		final corner = format == Corner;
		final hexGrid = grid.kind == Hex;
		final d0 = -1;
		final d1 = corner ? 1 : 2;
		for (cy in r.y0...r.y1) {
			final row = where[cy - oy];
			for (cx in r.x0...r.x1) {
				if (!corner && terrainAtCell(cx, cy) < i)
					continue;
				var insideCount = 0;
				var outsideCount = 0;
				var other = false;
				inline function count(t:Int) {
					if (t >= i)
						insideCount++;
					else if (t == from)
						outsideCount++;
					else if (ignored == null || t < 0 || !ignored[t])
						other = true;
				}
				if (hexGrid && !corner) {
					// a hex and its six neighbours
					count(terrainAtCell(cx, cy));
					for (d in 0...6)
						count(terrainAtCell(grid.neighbourX(cx, cy, d), grid.neighbourY(cx, cy, d)));
				} else
					for (dy in d0...d1)
						for (dx in d0...d1)
							count(terrainAtCell(cx + dx, cy + dy));
				if (!other && insideCount > 0 && outsideCount > 0) {
					row[cx - ox] = 1;
					any = true;
				}
			}
		}
		return any ? where : null;
	}

	/** The step from a cell to its neighbour, by `toward:`; one object a side, shared: read it, do not keep changing it. **/
	public static function towardStep(toward:String):TowardStep {
		return switch toward {
			case "up": STEP_UP;
			case "left": STEP_LEFT;
			case "right": STEP_RIGHT;
			default: STEP_DOWN;
		};
	}

	/** The levels' edges, the platforms' tops and the rises' sides of a chunk, the sides noted as they are drawn. **/
	function drawRises(c:Chunk):Void {
		if (def.levels.length == 0)
			return;
		// off the square grid a raised cell is lifted, its sides drawn on it (`drawColumns`), its
		// edge and a platform's top on its top
		if (lift > 0) {
			drawLiftedTops(c);
			noteLiftedSides(c);
			return;
		}
		final highest = highestLevel();
		// Every level's outline: along its rim only, so what is on the level shows; the autotile of
		// the terrain on top where the tileset has one for it, the tileset's own otherwise.
		for (level in 1...highest + 1) {
			final mask = levelMask(level);
			for (name in edgeNames) {
				final format = tiles.autotileFormat(name);
				final where = rimPositions(mask, name, format, positionsOf(c, format));
				if (where != null)
					partOf(c, edgePass).addChild(autotileGroup(name, mask, where, passRect.x0, passRect.y0));
			}
		}
		// Every platform's top: its own autotile over all of it, on whatever terrain is under it
		for (platform in tileset.platforms) {
			final edge = platform.edge;
			final pi = platformNames.indexOf(platform.name);
			if (edge == null || pi < 0)
				continue;
			final format = tiles.autotileFormat(edge);
			for (level in 1...highest + 1) {
				final mask = platformMask(pi, level);
				if (mask == null)
					continue;
				final where = drawnPositions(mask, format, positionsOf(c, format));
				if (where != null)
					partOf(c, edgePass).addChild(autotileGroup(edge, mask, where, passRect.x0, passRect.y0));
			}
		}
		scanRises(c, new TileGroups(this, c, sidePass));
	}

	/**
		Beyond a higher cell, toward the neighbour its rise faces, the side over `span` cells: noted
		in `sides` and `sideRises` for the cells it lands on in the chunk, and drawn there into
		`groups` when given one. The higher cells looked at reach `span` outside the chunk. The cells
		are scanned along a side's run, each cell's rise looked up once, as the cell before looks
		at it to see whether its run goes on. How far along its run a cell is follows from the cell
		before; the first cell of a run the scan meets reads where the run starts from what a scan
		before noted on its line (`runAlong`), so a long cliff is not walked back along once a chunk.
	**/
	function scanRises(c:Chunk, groups:Null<TileGroups>):Void {
		if (def.levels.length == 0)
			return;
		if (lift > 0) {
			noteLiftedSides(c);
			return;
		}
		final span = maxSpan();
		for (ti in 0...towardNames.length) {
			final step = towardStep(towardNames[ti]);
			final dx = step.dx;
			final dy = step.dy;
			// its neighbours along the side's run, in reading order (left or above first)
			final px = dy != 0 ? 1 : 0;
			final py = dx != 0 ? 1 : 0;
			// the run's axis is the inner loop
			final alongX = px == 1;
			final a0 = alongX ? c.rect.y0 - span : c.rect.x0 - span;
			final a1 = alongX ? c.rect.y1 + span : c.rect.x1 + span;
			final b0 = alongX ? c.rect.x0 - span : c.rect.y0 - span;
			final b1 = alongX ? c.rect.x1 + span : c.rect.y1 + span;
			final lines = alongX ? height : width;
			for (a in a0...a1) {
				if (a < 0 || a >= lines)
					continue;
				final slot = ti * runStride + a;
				// the rise of the cell before, when it was scanned (`known`); and this cell's, when
				// the cell before looked it up (-2 when it did not)
				var previous = -1;
				var known = false;
				var next = -2;
				var along = 0;
				for (b in b0...b1) {
					final cx = alongX ? b : a;
					final cy = alongX ? a : b;
					if (!inside(cx, cy)) {
						known = false;
						next = -2;
						continue;
					}
					final index = next != -2 ? next : riseIndexAt(cx, cy, ti, dx, dy);
					next = -2;
					if (index < 0) {
						previous = -1;
						known = true;
						continue;
					}
					final rise = tileset.rises[index];
					if (inside(cx + px, cy + py))
						next = riseIndexAt(cx + px, cy + py, ti, dx, dy);
					final after = next == index;
					final before = known ? previous == index : inside(cx - px, cy - py) && riseIndexAt(cx - px, cy - py, ti, dx, dy) == index;
					// how far along the run the cell is, for a middle of several taken in turn
					if (!before)
						along = 0;
					else if (known)
						along++;
					else
						along = rise.sides.length > 1 ? runAlong(slot, b, index, cx, cy, px, py, ti) : 0;
					if (rise.sides.length > 1) {
						runVersion[slot] = rowsVersion;
						runIndex[slot] = index;
						runStart[slot] = b - along;
						runEnd[slot] = b;
					}
					previous = index;
					known = true;
					final levels = riseToward(cx, cy, dx, dy);
					var frames:Null<Array<MapFrame>> = null;
					for (k in 0...rise.span) {
						final sx = cx + dx * (k + 1);
						final sy = cy + dy * (k + 1);
						if (!inside(sx, sy))
							break;
						if (sx < c.rect.x0 || sx >= c.rect.x1 || sy < c.rect.y0 || sy >= c.rect.y1)
							continue;
						// under a layer's cell drawn in the side's place (`draw: side`) the piece is not
						// drawn; the cell is, by `drawLayers`, and the run goes on past it as if whole
						if (groups != null && !(hasSideCells && sideCellOver(sy * width + sx))) {
							if (frames == null)
								frames = pieceFramesOf(sidePiece(rise, before, after, along));
							final f = frames[k < frames.length ? k : frames.length - 1];
							groups.add(grid.frameX(sx, sy, f.width), grid.frameY(sx, sy, f.height), f.tile);
						}
						sides[sy * width + sx] = levels;
						sideRises[sy * width + sx] = index;
					}
				}
			}
		}
	}

	/** The edge autotile of a cell's terrain: the tileset's for that terrain, else its own; null when it has neither. **/
	function edgeOfCell(cx:Int, cy:Int):Null<String> {
		final t = inside(cx, cy) ? terrainIndex[cy * width + cx] : -1;
		final own = t >= 0 ? tileset.edges.get(tileset.terrains[t].name) : null;
		return own != null ? own : tileset.edge;
	}

	/**
		Where an edge autotile is drawn for a level's mask, within a rectangle of positions: its
		positions (corners of the corner format, cells otherwise) on the level's rim, where the
		terrain on top has this autotile as its edge. The inside of a level is not outlined, so its
		terrains show. Null when nowhere.
	**/
	function rimPositions(mask:Array<Array<Int>>, name:String, format:AutotileFormat, r:CellRect):Null<Array<Array<Int>>> {
		final ox = passRect.x0;
		final oy = passRect.y0;
		inline function filled(cx:Int, cy:Int):Bool
			return Autotile.isFilled(mask, cx - ox, cy - oy);
		final where = gridOver(r);
		var any = false;
		for (cy in r.y0...r.y1) {
			final row = where[cy - oy];
			for (cx in r.x0...r.x1) {
				final rim = switch format {
					case Corner:
						// the cells around the corner, the one below and right of it first: on the
						// rim when some are filled and some not, with the first filled one's edge
						var count = 0;
						var edge:Null<String> = null;
						if (filled(cx, cy)) {
							count++;
							edge = edgeOfCell(cx, cy);
						}
						if (filled(cx - 1, cy)) {
							count++;
							if (edge == null) edge = edgeOfCell(cx - 1, cy);
						}
						if (filled(cx, cy - 1)) {
							count++;
							if (edge == null) edge = edgeOfCell(cx, cy - 1);
						}
						if (filled(cx - 1, cy - 1)) {
							count++;
							if (edge == null) edge = edgeOfCell(cx - 1, cy - 1);
						}
						count > 0 && count < 4 && edge == name;
					case Cross | Blob47 | Hex64 | Connect16:
						var rim = false;
						if (filled(cx, cy) && edgeOfCell(cx, cy) == name) {
							if (grid.kind == Hex) {
								for (d in 0...6)
									if (!filled(grid.neighbourX(cx, cy, d), grid.neighbourY(cx, cy, d))) rim = true;
							} else
								for (dy in -1...2)
									for (dx in -1...2)
										if (!filled(cx + dx, cy + dy)) rim = true;
						}
						rim;
				};
				if (rim) {
					row[cx - ox] = 1;
					any = true;
				}
			}
		}
		return any ? where : null;
	}

	/** How many levels a cell stands above its neighbour one step away; 0 at the map's edge or when it does not. **/
	function riseToward(cx:Int, cy:Int, dx:Int, dy:Int):Int {
		if (!inside(cx, cy) || !inside(cx + dx, cy + dy))
			return 0;
		final d = levelIndex[cy * width + cx] - levelIndex[(cy + dy) * width + cx + dx];
		return d > 0 ? d : 0;
	}

	/** Which of the tileset's rises draws the side of a cell toward a neighbour; -1 when it stands no higher, or the tileset has none for it. **/
	function riseIndexAt(cx:Int, cy:Int, toward:Int, dx:Int, dy:Int):Int {
		#if MULTIANIM_ALLOC_TRACK
		riseLookups++;
		#end
		final levels = riseToward(cx, cy, dx, dy);
		if (levels <= 0)
			return -1;
		return riseOf(cy * width + cx, toward, levels);
	}

	/** Which of the tileset's rises draws a side `levels` high for a cell (by its index) toward a side faced (by its index in `towardNames`): `riseFor`'s answer, worked out once a source (`readRises`). **/
	inline function riseOf(i:Int, toward:Int, levels:Int):Int {
		final key = (toward * (tileset.terrains.length + 1) + terrainIndex[i] + 1) * (platformNames.length + 1) + platformIndex[i] + 1;
		return riseTable[key * riseLevels + (levels < riseLevels ? levels : riseLevels - 1)];
	}

	/**
		How far along its run a cell is, the first one of the run a scan meets (its run goes on
		before it): from the run's start a scan before noted on this line while the rows were as
		they are, else walked back to.
	**/
	function runAlong(slot:Int, b:Int, index:Int, cx:Int, cy:Int, px:Int, py:Int, toward:Int):Int {
		if (runVersion[slot] == rowsVersion && runIndex[slot] == index && runStart[slot] < b && runEnd[slot] >= b - 1)
			return b - runStart[slot];
		final step = towardStep(towardNames[toward]);
		var along = 0;
		while (riseIndexAt(cx - px * (along + 1), cy - py * (along + 1), toward, step.dx, step.dy) == index)
			along++;
		return along;
	}

	/**
		The rise of a tileset for a cell `levels` above its neighbour `toward`: for a cell of a
		platform, that platform's own rises and no other; else the terrain's own in that direction
		when it has any, the ones for every terrain otherwise; among those the one of that many
		levels, else `rise any`. -1 when there is none.
	**/
	public static function riseFor(tileset:TilesetDef, levels:Int, toward:String, terrain:Null<String>, ?platform:Null<String>):Int {
		// a platform's sides are its own: where it has none, nothing is drawn, not the ground's
		var own = false;
		if (terrain != null && platform == null)
			for (r in tileset.rises)
				if (r.toward == toward && r.terrain == terrain && r.platform == null) own = true;
		final wanted = own ? terrain : null;
		final wantedPlatform = platform;
		var any = -1;
		for (i in 0...tileset.rises.length) {
			final r = tileset.rises[i];
			if (r.toward != toward || r.terrain != wanted || r.platform != wantedPlatform)
				continue;
			if (r.rise == levels)
				return i;
			if (r.rise == 0)
				any = i;
		}
		return any;
	}

	/**
		The piece of a side a cell takes: its ends (`left` the run's first, left or top; `right` its
		last), or a side one cell wide, where the rise names them; else its middle, the one whose turn
		it is `along` the run when the rise has several.
	**/
	function sidePiece(rise:TilesetRiseDef, before:Bool, after:Bool, along:Int):String {
		final piece = if (before && after) null else if (!before && !after) rise.single else if (before) rise.right else rise.left;
		if (piece != null)
			return piece;
		// the run's first cell is its left end, so the first middle is the cell after it
		final turn = rise.left != null && along > 0 ? along - 1 : along;
		return rise.sides[turn % rise.sides.length];
	}

	function cellDef(name:String):Null<TilesetCellDef> {
		for (c in tileset.cells)
			if (c.name == name) return c;
		return null;
	}

	/** Whether a layer's entry stands among the actors on one cell (not an object of several cells). **/
	static function standsAlone(entry:LayerEntry):Bool {
		final cell = entry.cell;
		return entry.draw == "actors"
			&& (cell == null || ((cell.width == null || cell.width == 1) && (cell.height == null || cell.height == 1)));
	}

	/** Whether a frame drawn from `y` on cell (cx, cy) reaches below the cell's own top somewhere (`TileGrid.bottomAt`). **/
	function reachesBelow(cx:Int, cy:Int, y:Float, tile:h2d.Tile):Bool {
		return y + tile.dy + tile.height > grid.bottomAt(cx, cy, grid.pixelX(cx, cy));
	}

	/**
		What of the frames standing on a cell (a layer's `draw: actors` cell of one cell) reaches below
		the cell's own top, drawn with the ground in the cell's place: a building drawn on its block
		has the block's sides there, which the cells in front cover as they cover a terrain's. The
		rest of the frame stands among the actors (`drawLayers`).
	**/
	function emitStandingBelow(cx:Int, cy:Int, sink:TileSink):Void {
		for (li in 0...layerCell.length) {
			final e = layerCell[li][cy * width + cx];
			if (e < 0)
				continue;
			final entry = layerEntries[li][e];
			if (!standsAlone(entry))
				continue;
			final frame = entry.frames[Autotile.variantAt(cx, cy, entry.frames.length)];
			final y = grid.frameY(cx, cy, frame.height) - liftAt(cx, cy);
			if (reachesBelow(cx, cy, y, frame.tile))
				addCut(sink, cx, cy, grid.frameX(cx, cy, frame.width), y, frame.tile, false);
		}
	}

	/**
		A frame standing on cell (cx, cy), drawn from (x, y), cut along the cell's lower outline
		(`TileGrid.bottomAt`) in columns `CUT` pixels wide: the part above the outline (`above`), or
		the part below it. What is beside the cell's box is all above.
	**/
	function addCut(sink:TileSink, cx:Int, cy:Int, x:Float, y:Float, tile:h2d.Tile, above:Bool):Void {
		final left = x + tile.dx;
		final top = y + tile.dy;
		final w = Std.int(tile.width);
		final h = Std.int(tile.height);
		final boxLeft = grid.pixelX(cx, cy);
		final boxRight = boxLeft + grid.tileWidth;
		var sx = 0;
		while (sx < w) {
			final cw = sx + CUT > w ? w - sx : CUT;
			final mid = left + sx + cw / 2;
			var r = h;
			if (mid > boxLeft && mid < boxRight) {
				r = Math.floor(grid.bottomAt(cx, cy, mid) - top);
				if (r < 0) r = 0;
				if (r > h) r = h;
			}
			if (above) {
				if (r > 0)
					sink.add(left + sx, top, tile.sub(sx, 0, cw, r));
			} else if (r < h)
				sink.add(left + sx, top + r, tile.sub(sx, r, cw, h - r));
			sx += cw;
		}
	}

	function drawLayers(c:Chunk):Void {
		// a lifted map draws a raised cell's side on the cell, a piece a level: a cell drawn in the
		// side's place goes with those pieces (`emitSideCells`), and as an `under` cell where none is
		final liftsSides = lift > 0 && def.levels.length > 0;
		for (li in 0...def.layers.length) {
			final entries = layerEntries[li];
			final at = layerCell[li];
			final under = new TileGroups(this, c, underPass + li);
			final over = new TileGroups(this, c, overPass + li);
			final top = new TileGroups(this, c, topPass + li);
			// in the sides' pass, after the sides: in place of the pieces it covers, which `scanRises` left out
			final side:Null<TileGroups> = hasSideCells ? new TileGroups(this, c, sidePass) : null;
			for (cy in c.rect.y0...c.rect.y1)
				for (cx in c.rect.x0...c.rect.x1) {
					final e = at[cy * width + cx];
					if (e < 0)
						continue;
					final entry = entries[e];
					var draw = entry.draw;
					if (draw == "side" && liftsSides) {
						if (liftedDrop(cx, cy) > 0)
							continue;
						draw = "under";
					}
					final frames = entry.frames;
					final frame = frames[Autotile.variantAt(cx, cy, frames.length)];
					final tile = frame.tile;
					// an object of several cells is drawn from its top-left, the layer's character at its
					// anchor; off the square grid it stands on its footprint's box
					var x:Float, y:Float;
					var footY = 0.0;
					var footprint:Null<CellRect> = null;
					if (grid.kind == Orthogonal) {
						x = (cx - entry.anchorX) * tileSize;
						y = (cy - entry.anchorY) * tileSize;
					} else {
						final r = footprintOf(entry.cell, cx, cy);
						footprint = r;
						final box = grid.bounds(r.x0, r.y0, r.x1, r.y1, scratchBounds);
						x = grid.frameLeft(box.xMin, frame.width, box.width);
						// on a raised cell, lifted with it (an object by its anchor's level)
						y = grid.frameTop(box.yMin, frame.height, box.height) - liftAt(cx, cy);
						footY = (box.yMin + box.yMax) / 2;
					}
					// a raised cell's own cells under the actors are drawn on its column, among them
					final column = draw != "actors" && draw != "over" && draw != "top" ? columnOf.get(cy * width + cx) : null;
					if (column != null) {
						column.add(x, y, tile);
						continue;
					}
					switch draw {
						case "actors":
							// an object of several cells off the square grid: in strips, each sorted by
							// the front cell of the footprint under it
							if (footprint != null && (footprint.x1 - footprint.x0 > 1 || footprint.y1 - footprint.y0 > 1)) {
								if (grid.kind == Isometric)
									addStrips(c, footprint, x, y, tile);
								else
									addHexStrips(c, footprint, x, y, tile);
								continue;
							}
							// off the square grid, what reaches below the cell's top is the ground's, drawn
							// with it (`emitStandingBelow`); the rest stands among the actors, sorted by
							// the middle of the cell's box
							if (grid.kind != Orthogonal && chunkPlans.length > 0 && reachesBelow(cx, cy, y, tile)) {
								final standing = new ColumnTiles(this, c, footY);
								standing.object.visible = c.shown;
								actors.add(standing.object, 0);
								c.objects.push(standing.object);
								addCut(standing, cx, cy, x, y, tile, true);
								continue;
							}
							// among the actors, standing on its feet: its y is its bottom edge, which sorts
							// it; off the square grid, the middle of its footprint's box
							final t = tile.clone();
							final sprite = new h2d.Bitmap(t);
							sprite.x = x;
							if (grid.kind == Orthogonal) {
								t.dy -= frame.height;
								sprite.y = y + frame.height;
							} else {
								t.dy += y - footY;
								sprite.y = footY;
							}
							sprite.visible = c.shown;
							actors.add(sprite, 0);
							c.objects.push(sprite);
						case "over": over.add(x, y, tile);
						case "top": top.add(x, y, tile);
						case "side" if (side != null): side.add(x, y, tile);
						default: under.add(x, y, tile);
					}
				}
		}
	}

	/**
		An object of several cells on the isometric grid, among the actors in strips half a cell wide:
		each sorted by the front cell of the footprint under it (the one lowest on screen), less a
		quarter of a pixel (after the raised cells it stands on, before an actor on that cell). One key
		for the whole object, its footprint's middle, is wrong beside a long side: an actor in front of
		the side's far end is behind the middle. The cuts are the cells' half columns, moved by
		`tileOffset` as the frame is; what the frame draws past the footprint goes with the end strip.
	**/
	function addStrips(c:Chunk, r:CellRect, x:Float, y:Float, tile:h2d.Tile):Void {
		final half = grid.columnStep;
		// the footprint's half columns on screen: cell (cx, cy) covers cx - cy - 1 and cx - cy
		final k0 = r.x0 - r.y1;
		final k1 = r.x1 - r.y0 - 1;
		final left = x + tile.dx;
		final right = left + tile.width;
		for (k in k0...k1 + 1) {
			var a = k == k0 ? left : k * half + grid.offsetX;
			var b = k == k1 ? right : (k + 1) * half + grid.offsetX;
			if (a < left) a = left;
			if (b > right) b = right;
			if (b <= a)
				continue;
			// of the footprint's cells with cx - cy = k or k + 1, the lowest on screen (the most cx + cy)
			var best = -0x7FFFFFFF;
			var frontX = 0, frontY = 0;
			for (d in k...k + 2) {
				final fy = r.y1 - 1 < r.x1 - 1 - d ? r.y1 - 1 : r.x1 - 1 - d;
				final fx = fy + d;
				if (fx < r.x0 || fy < r.y0 || fx + fy <= best)
					continue;
				best = fx + fy;
				frontX = fx;
				frontY = fy;
			}
			addStrip(c, x, y, tile, left, a, b, grid.pixelY(frontX, frontY) + grid.tileHeight / 2 - 0.25);
		}
	}

	/**
		An object of several cells on the hex grid, among the actors in strips, as `addStrips` does on
		the isometric grid: the footprint's cells' boxes cut the screen at their left and right edges
		(half a cell apart on pointy hexes; a slant's width and a side's in turn on flat ones), each
		piece sorted by the front cell over it (the lowest on screen of the footprint's cells whose box
		covers it) less a quarter of a pixel. Pieces side by side with the same front row are one strip:
		a pointy footprint's front row is one, its pushed rows' jagged ends their own. One key for the
		whole object, its footprint's middle, puts an actor beside a back row in front of the front
		row's corner over it.
	**/
	function addHexStrips(c:Chunk, r:CellRect, x:Float, y:Float, tile:h2d.Tile):Void {
		final w = grid.tileWidth;
		final cuts:Array<Float> = [];
		for (cy in r.y0...r.y1)
			for (cx in r.x0...r.x1) {
				final px = grid.pixelX(cx, cy) + grid.offsetX;
				if (cuts.indexOf(px) < 0)
					cuts.push(px);
				if (cuts.indexOf(px + w) < 0)
					cuts.push(px + w);
			}
		cuts.sort((p, q) -> p < q ? -1 : (p > q ? 1 : 0));
		final left = x + tile.dx;
		final right = left + tile.width;
		final last = cuts.length - 2;
		var start = left;
		var key = Math.NaN;
		for (i in 0...last + 1) {
			// the front cell over the piece: the most pixelY among the cells whose box covers its middle
			final mid = (cuts[i] + cuts[i + 1]) / 2;
			var front = Math.NEGATIVE_INFINITY;
			for (cy in r.y0...r.y1)
				for (cx in r.x0...r.x1) {
					final px = grid.pixelX(cx, cy) + grid.offsetX;
					final py = grid.pixelY(cx, cy);
					if (px <= mid && mid < px + w && py > front)
						front = py;
				}
			final k = front + grid.tileHeight / 2 - 0.25;
			if (i > 0 && k != key) {
				addStrip(c, x, y, tile, left, start, cuts[i], key);
				start = cuts[i];
			}
			key = k;
		}
		addStrip(c, x, y, tile, left, start, right, key);
	}

	/** One strip of an object among the actors: its frame's columns from `a` to `b` (map pixels, kept within the frame), sorted at `sortY`. **/
	function addStrip(c:Chunk, x:Float, y:Float, tile:h2d.Tile, left:Float, a:Float, b:Float, sortY:Float):Void {
		final right = left + tile.width;
		if (a < left)
			a = left;
		if (b > right)
			b = right;
		if (b <= a)
			return;
		final sprite = new h2d.Bitmap(tile.sub(a - left, 0, b - a, tile.height, tile.dx + a - left, tile.dy + y - sortY));
		sprite.x = x;
		sprite.y = sortY;
		sprite.visible = c.shown;
		actors.add(sprite, 0);
		c.objects.push(sprite);
	}

	/**
		A chunk's cells' metadata, merged once a draw: the terrain's, a side's over it, then each
		layer's cell there (an object's on every cell it covers). A cell with its terrain's alone
		shares the terrain's settings; any other combination of sources is merged once and shared
		by every cell of it.
	**/
	function mergeMetadata(c:Chunk):Void {
		final layers = def.layers.length;
		for (cy in c.rect.y0...c.rect.y1)
			for (cx in c.rect.x0...c.rect.x1) {
				final i = cy * width + cx;
				final t = terrainIndex[i];
				final r = sideRises[i];
				var more = r >= 0 && riseMetadata[r] != null;
				for (li in 0...layers) {
					final anchor = covers[li][i];
					if (anchor >= 0 && entryAt(li, anchor).metadata != null)
						more = true;
				}
				if (!more) {
					metadata[i] = t >= 0 ? terrainSettings[t] : NO_METADATA;
					continue;
				}
				if (intMetadataKeys) {
					var key = (t + 1) * (riseMetadata.length + 1) + r + 1;
					for (li in 0...layers) {
						final anchor = covers[li][i];
						key = key * (layerEntries[li].length + 1) + (anchor >= 0 ? layerCell[li][anchor] + 1 : 0);
					}
					var settings = mergedByKey.get(key);
					if (settings == null) {
						settings = mergedOf(t, r, i);
						mergedByKey.set(key, settings);
					}
					metadata[i] = settings;
					continue;
				}
				var key = '$t|$r';
				for (li in 0...layers) {
					final anchor = covers[li][i];
					key += '|' + (anchor >= 0 ? layerCell[li][anchor] : -1);
				}
				#if MULTIANIM_ALLOC_TRACK
				metadataKeyStrings++;
				#end
				var settings = mergedSettings.get(key);
				if (settings == null) {
					settings = mergedOf(t, r, i);
					mergedSettings.set(key, settings);
				}
				metadata[i] = settings;
			}
	}

	/** A cell's metadata sources merged: its terrain's, the rise's of a side over it, then each layer's cell there, a later one winning. **/
	function mergedOf(t:Int, r:Int, i:Int):BuilderResolvedSettings {
		final merged = new Map<String, SettingValue>();
		if (t >= 0)
			takeMetadata(merged, terrainMetadata[t]);
		if (r >= 0)
			takeMetadata(merged, riseMetadata[r]);
		for (li in 0...def.layers.length) {
			final anchor = covers[li][i];
			if (anchor >= 0)
				takeMetadata(merged, entryAt(li, anchor).metadata);
		}
		return new BuilderResolvedSettings(merged);
	}

	static function takeMetadata(into:Map<String, SettingValue>, from:ResolvedSettings):Void {
		if (from == null)
			return;
		for (k => v in from)
			into.set(k, v);
	}

	/** The frames of a rise's side piece, looked up as it is first drawn and kept until the source changes. **/
	function pieceFramesOf(name:String):Array<MapFrame> {
		var frames = pieceFrames.get(name);
		if (frames == null) {
			frames = framesOf(tileset.atlas, name);
			pieceFrames.set(name, frames);
		}
		return frames;
	}

	/** The frames of a name, which the builder checked were there; `layersOwn` for a layer's own sheet. **/
	function framesOf(sheet:String, name:String, layersOwn = false):Array<MapFrame> {
		final frames = layersOwn && tiles.layerFrames != null ? tiles.layerFrames(sheet, name) : tiles.frames(sheet, name);
		if (frames == null || frames.length == 0)
			throw BuilderError.of('tilemap $mapName: sheet $sheet has no cell $name', "tilemap_missing_cell");
		return frames;
	}

	/**
		An atlas frame as a map draws it: its tile placed in its untrimmed frame (`offset:` from the
		frame's left and bottom, as libGDX writes it), and that frame's size (`orig:`). A frame with no
		`orig:` is its tile, whole.
	**/
	public static function frameOf(f:bh.stateanim.AnimationFrame):MapFrame {
		if (f.width <= 0 || f.height <= 0)
			return tileFrame(f.tile);
		return {tile: f.placedAbout(0, 0).tile, width: f.width, height: f.height};
	}

	/** A tile drawn whole: its frame is its own size. **/
	public static function tileFrame(t:h2d.Tile):MapFrame {
		return {tile: t, width: Std.int(t.width), height: Std.int(t.height)};
	}

	static function replaceAt(row:String, i:Int, char:String):String {
		return row.substr(0, i) + char + row.substr(i + 1);
	}

	static function mapToObject<T>(m:Map<String, T>):Dynamic {
		final o = {};
		for (k => v in m)
			Reflect.setField(o, k, v);
		return o;
	}

	/** The rows are the map's own: changing a cell must not change the file's parse, shared by every map built from it. **/
	static function copyOf(def:TilemapDef):TilemapDef {
		return {
			tileset: def.tileset,
			tilesetImport: def.tilesetImport,
			width: def.width,
			height: def.height,
			legend: def.legend,
			terrain: def.terrain.copy(),
			levels: def.levels.copy(),
			levelLegend: def.levelLegend,
			levelPlatforms: def.levelPlatforms,
			layers: [
				for (l in def.layers)
					({name: l.name, legend: l.legend, rows: l.rows.copy(), sheet: l.sheet, draw: l.draw} : TilemapLayerDef)
			],
			marks: def.marks,
			line: def.line,
		};
	}
}

/** Where tiles are put as a chunk is drawn: a chunk's part of a pass, or a raised cell's column. **/
private interface TileSink {
	/** A still tile. **/
	function add(x:Float, y:Float, tile:h2d.Tile):Void;

	/** Frame `frame` of `frames` of an animated terrain's tile (`terrain` its index): shown as its terrain's clock says. **/
	function addFrame(terrain:Int, frames:Int, frame:Int, x:Float, y:Float, tile:h2d.Tile):Void;
}

/**
	Tiles kept in the order they are added, under one parent made as the first is: still tiles in a
	TileGroup a texture (a TileGroup draws from a single texture) until an animated terrain's first
	tile comes; from there a run, an object a frame of the terrain's shown in turn, each frame's
	tiles in the order they come and every still tile after them in each frame too, so what is in
	front of the animated tiles covers them in whichever frame shows. A run is as many objects as the
	terrain has frames, however its tiles and the still ones take turns; another animated terrain's
	tile starts a run of its own.
**/
private class OrderedTiles implements TileSink {
	final map:TileMap;
	final chunk:Chunk;
	// subtracted from every tile's y: the parent's own y
	var shiftY = 0.0;
	var still:Null<Array<h2d.TileGroup>> = null;
	var run:Null<{terrain:Int, frames:Array<h2d.Object>, groups:Array<Array<h2d.TileGroup>>}> = null;

	public function new(map:TileMap, chunk:Chunk) {
		this.map = map;
		this.chunk = chunk;
	}

	/** The object the tiles go into. **/
	function holder():h2d.Object {
		throw "abstract";
	}

	public function add(x:Float, y:Float, tile:h2d.Tile):Void {
		final r = run;
		if (r != null) {
			// in the run, in every frame of it
			for (k in 0...r.frames.length)
				addTo(r.groups[k], r.frames[k], x, y - shiftY, tile);
			return;
		}
		var groups = still;
		if (groups == null) {
			groups = [];
			still = groups;
		}
		addTo(groups, null, x, y - shiftY, tile);
	}

	public function addFrame(terrain:Int, frames:Int, frame:Int, x:Float, y:Float, tile:h2d.Tile):Void {
		var r = run;
		if (r == null || r.terrain != terrain || r.frames.length != frames) {
			final parent = holder();
			final objects = [for (_ in 0...frames) new h2d.Object(parent)];
			r = {terrain: terrain, frames: objects, groups: [for (_ in 0...frames) []]};
			run = r;
			@:privateAccess map.animate(chunk, terrain, objects);
		}
		addTo(r.groups[frame], r.frames[frame], x, y - shiftY, tile);
	}

	/** Into the group of its texture under `parent` (the holder when null), made when there is none. **/
	function addTo(groups:Array<h2d.TileGroup>, parent:Null<h2d.Object>, x:Float, y:Float, tile:h2d.Tile):Void {
		final texture = tile.getTexture();
		for (g in groups)
			if (g.tile.getTexture() == texture) {
				g.add(x, y, tile);
				return;
			}
		final g = new h2d.TileGroup(tile, parent != null ? parent : holder());
		groups.push(g);
		g.add(x, y, tile);
	}
}

/**
	A raised cell drawn lifted, among the actors: an object at the cell's middle on the ground (less
	half a pixel), which is what sorts it, holding its tiles placed where the map puts them.
**/
private class ColumnTiles extends OrderedTiles {
	public final object = new h2d.Object();

	public function new(map:TileMap, chunk:Chunk, sortY:Float) {
		super(map, chunk);
		object.y = sortY;
		shiftY = sortY;
	}

	override function holder():h2d.Object {
		return object;
	}
}

/** Tiles in a chunk's part of a pass, the part made as the first tile is added. **/
private class TileGroups extends OrderedTiles {
	final pass:Int;

	public function new(map:TileMap, chunk:Chunk, pass:Int) {
		super(map, chunk);
		this.pass = pass;
	}

	override function holder():h2d.Object {
		return @:privateAccess map.partOf(chunk, pass);
	}
}
