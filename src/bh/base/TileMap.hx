package bh.base;

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
		The TileGroup of an autotile over a grid (`grid[y][x]`, non-zero is the terrain), drawn at
		every position or only those set in `where` (the autotile's own positions: corners for the
		corner format, cells otherwise). Both may be sparse: empty rows, rows that stop short, a
		missing cell being 0; a map gives the grid of the cells around the chunks it draws and no more.
	**/
	var autotile:(name:String, grid:Array<Array<Int>>, where:Null<Array<Array<Int>>>) -> h2d.TileGroup;

	/** An autotile's format, which says what its positions are; throws for a name the file has not. **/
	var autotileFormat:(name:String) -> AutotileFormat;

	/** The frames of a name in a sheet, or null when the sheet has no such name. **/
	var frames:(sheet:String, name:String) -> Null<Array<h2d.Tile>>;

	/** A terrain's, a rise's or a cell's metadata, resolved as settings are; null when it has none. **/
	var metadata:(parsed:Map<String, ParsedSettingValue>) -> ResolvedSettings;
}

/** A rectangle of cells, `x1` and `y1` one past the last. **/
private typedef CellRect = {x0:Int, y0:Int, x1:Int, y1:Int};

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
	A square of the map drawn on its own, so a change is drawn again where it is and only that, and
	what is off screen is not drawn at all. Its ground, over and top are children of the map's.
**/
private class Chunk {
	public final rect:CellRect;
	public final ground:h2d.Object;
	public final over:h2d.Object;
	public final top:h2d.Object;
	/** Objects of several cells anchored in this chunk, among the actors. **/
	public var objects:Array<h2d.Object> = [];
	/** An animated terrain's frames in this chunk, by the terrain's index. **/
	public var animated:Array<{terrain:Int, frames:Array<h2d.Object>}> = [];
	public var dirty = true;

	public function new(rect:CellRect, ground:h2d.Object, over:h2d.Object, top:h2d.Object) {
		this.rect = rect;
		this.ground = new h2d.Object(ground);
		this.over = new h2d.Object(over);
		this.top = new h2d.Object(top);
	}
}

/**
	A tile map (`#name tilemap { … }` in a .manim), drawn from its tileset:

	- the terrains, bottom first, each drawn under every terrain after it (an autotile over the
	  cells of that terrain and of the terrains after it, or the variants of an atlas name), and where
	  two meet, the pair's `transition` autotile over the upper one's own;
	- the levels: each outlined with the tileset's `edge` (the one of the terrain on top, where the
	  tileset has one for it), along its rim only, and beyond a higher cell, toward the lower
	  neighbour its rise faces (`toward:`, down by default), the rise's `side` over `span` cells. Nothing is lifted: what
	  stands on a higher level stands on its cells, where they are drawn;
	- the platforms (a tree top, a roof: a kind of higher level that is not the ground raised, where the
	  map's levels legend says one): each drawn with its own `edge` over all of it, and its own sides;
	- the cell layers, each from its own sheet (the tileset's atlas by default), drawn `under` the
	  actors, `over` them, or at the `top`, above everything; a `cell` of the tileset may say otherwise,
	  and a cell with a `size` is an object of several cells, drawn among the actors by default, whose
	  name and metadata every cell it covers has (`cellAt`, `objectAt`, `metadataAt`);
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
	are in are drawn again once, as they are next in view or asked what they draw (`sideAt`,
	`metadataAt`; `terrainAt`, `levelAt` and `cellAt` read the rows and draw nothing); `redraw()`
	draws it all now.
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

	public var tileSize(default, null):Int = 0;
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
	var chunks:Array<Chunk> = [];
	var decor:Array<h2d.Object> = [];
	// Per terrain: the clock of its animation, shared by every chunk
	var animClocks:Array<{time:Float, index:Int}> = [];
	// Per cell: its terrain's index in the tileset, -1 for none; kept as the rows are, not drawn
	var terrainIndex:Array<Int> = [];
	// Per layer (as `def.layers`), per cell: the index (`cy * width + cx`) of the cell whose character
	// is there - its own for a cell of one, the anchor's for the cells an object covers - or -1
	var covers:Array<Array<Int>> = [];
	// Per cell: the rise of a side drawn over it, 0 for none; and which of the tileset's rises drew it, -1 for none
	var sides:Array<Int> = [];
	var sideRises:Array<Int> = [];
	// The tileset's metadata, resolved once a source: per terrain, per rise (as tileset.rises) and per cell name
	var terrainMetadata:Array<ResolvedSettings> = [];
	var riseMetadata:Array<ResolvedSettings> = [];
	var cellMetadata:Map<String, ResolvedSettings> = [];
	// Per cell: its metadata, merged; one shared empty where it has none
	var metadata:Array<BuilderResolvedSettings> = [];
	// Some chunk is dirty: drawn when next in view or asked what it draws
	var changed = false;
	// The view `cull` was given, in the map's pixels, or null for the scene's
	var cullRect:Null<{x:Float, y:Float, w:Float, h:Float}> = null;
	// Masks of a draw pass, shared by the chunks it draws and made over `passRect` alone (the chunks
	// and a cell around them, as far as an autotile's index looks): per terrain, per level, per
	// platform and level
	var passRect:CellRect = {x0: 0, y0: 0, x1: 0, y1: 0};
	var passTerrainMasks:Array<Null<Array<Array<Int>>>> = [];
	var passLevelMasks:Map<Int, Array<Array<Int>>> = [];
	var passPlatformMasks:Map<String, Array<Array<Int>>> = [];
	var passHighest = -1;

	static final NO_METADATA = new BuilderResolvedSettings(null);
	static final EMPTY_ROW:Array<Int> = [];
	static final scratchPoint = new h2d.col.Point();

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
		tileSize = tileset.tileSize;
		width = def.width;
		height = def.height;
		terrainMetadata = [for (t in tileset.terrains) tiles.metadata(t.metadata)];
		riseMetadata = [for (r in tileset.rises) tiles.metadata(r.metadata)];
		cellMetadata = [for (c in tileset.cells) c.name => tiles.metadata(c.metadata)];
		animClocks = [for (_ in tileset.terrains) {time: 0.0, index: 0}];
		final cells = width * height;
		terrainIndex = [for (cy in 0...height) for (cx in 0...width) terrainIndexOf(this.def.legend.get(this.def.terrain[cy].charAt(cx)))];
		covers = [for (l in this.def.layers) coverOf(l)];
		sides = [for (_ in 0...cells) 0];
		sideRises = [for (_ in 0...cells) -1];
		metadata = [for (_ in 0...cells) NO_METADATA];
		makeChunks();
	}

	/** Changes the size of a chunk, in cells; the map is drawn again in the new ones as they are in view. **/
	public function setChunkSize(cells:Int):Void {
		if (cells <= 0)
			throw BuilderError.of('tilemap $mapName: a chunk is 1 cell or more a side, got $cells', "tilemap_chunk");
		chunkSize = cells;
		makeChunks();
	}

	/** New chunks, every one dirty: drawn as it is next in view or asked. **/
	function makeChunks():Void {
		for (c in chunks) {
			c.ground.remove();
			c.over.remove();
			c.top.remove();
			for (o in c.objects)
				o.remove();
		}
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
				}, ground, overLayer, topLayer));
			}
		changed = true;
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
		cullRect = {x: x, y: y, w: w, h: h};
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
		return chunks[row * chunkCols + col].ground.visible;
	}

	/** The cell a point of the map is in (pixels, in the map's own coordinates). **/
	public function toCell(x:Float, y:Float):h2d.col.IPoint {
		return new h2d.col.IPoint(Math.floor(x / tileSize), Math.floor(y / tileSize));
	}

	/** A cell's top-left corner, in pixels. **/
	public function toPixel(cx:Int, cy:Int):h2d.col.Point {
		return new h2d.col.Point(cx * tileSize, cy * tileSize);
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
		if (!inside(cx, cy) || def.levels.length == 0)
			return 0;
		return levelOf(def.levelLegend, def.levels[cy].charAt(cx));
	}

	/** The platform a cell is of (the tileset's `platform name { … }`, where the map's levels legend says one), or null: the ground, at its level. **/
	public function platformAt(cx:Int, cy:Int):Null<String> {
		if (!inside(cx, cy) || def.levels.length == 0)
			return null;
		return def.levelPlatforms.get(def.levels[cy].charAt(cx));
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
		return anchor < 0 ? null : nameAt(def.layers[li], anchor);
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
		final name = nameAt(def.layers[li], anchor);
		final r = footprintOf(cellDef(name), ax, ay);
		return {name: name, anchorX: ax, anchorY: ay, x: r.x0, y: r.y0, width: r.x1 - r.x0, height: r.y1 - r.y0};
	}

	/** The rise of a side drawn over the cell, or 0. **/
	public function sideAt(cx:Int, cy:Int):Int {
		if (!inside(cx, cy))
			return 0;
		drawCellsChunk(cx, cy);
		return sides[cy * width + cx];
	}

	/**
		The cell's metadata: its terrain's, a side's over it, then each layer's cell there (an object's
		on every cell it covers), a later one winning; read as settings are (`getBoolOrDefault`,
		`getIntOrDefault`, `getFloatOrDefault`, `getStringOrDefault`, `has`, `keys`). Empty outside the map.
	**/
	public function metadataAt(cx:Int, cy:Int):BuilderResolvedSettings {
		if (!inside(cx, cy))
			return NO_METADATA;
		drawCellsChunk(cx, cy);
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
		if (char != " " && !l.legend.exists(char))
			throw BuilderError.of('tilemap $mapName: "$char" is not in the legend of layer $layer', "tilemap_legend");
		final cover = covers[li];
		final i = cy * width + cx;
		if (cover[i] >= 0 && cover[i] != i) {
			final a = cover[i];
			throw BuilderError.of('tilemap $mapName: layer $layer: column $cx, row $cy is covered by ${nameAt(l, a)} at column ${a % width}, row ${Std.int(a / width)}: change it there',
				"tilemap_object_covered");
		}
		// the old object's cells freed; put back if the new one cannot be placed
		var old:Null<CellRect> = null;
		final oldName = cover[i] == i ? nameAt(l, i) : null;
		if (oldName != null) {
			old = footprintOf(cellDef(oldName), cx, cy);
			fillCover(cover, old, -1);
		}
		var placed:Null<CellRect> = null;
		if (char != " ") {
			final name:String = l.legend.get(char);
			placed = footprintOf(cellDef(name), cx, cy);
			try {
				placeCover(cover, l, name, cx, cy, placed);
			} catch (e:BuilderError) {
				if (old != null)
					fillCover(cover, old, i);
				throw e;
			}
		}
		l.rows[cy] = replaceAt(l.rows[cy], cx, char);
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

	/** The name of the cell at a cell index of a layer, which has one there. **/
	function nameAt(l:TilemapLayerDef, index:Int):String {
		return l.legend.get(l.rows[Std.int(index / width)].charAt(index % width));
	}

	/** The cells a cell placed at (cx, cy) covers: its own, or for an object of several its `size` about its anchor. **/
	function footprintOf(cell:Null<TilesetCellDef>, cx:Int, cy:Int):CellRect {
		final w = cell != null && cell.width != null ? cell.width : 1;
		final h = cell != null && cell.height != null ? cell.height : 1;
		final ax = cell != null && cell.anchorX != null ? cell.anchorX : 0;
		final ay = cell != null && cell.anchorY != null ? cell.anchorY : 0;
		return {x0: cx - ax, y0: cy - ay, x1: cx - ax + w, y1: cy - ay + h};
	}

	/** A layer's cover from its rows: every cell's anchor; the errors `setSource` says. **/
	function coverOf(l:TilemapLayerDef):Array<Int> {
		final cover = [for (_ in 0...width * height) -1];
		for (cy in 0...height)
			for (cx in 0...width) {
				final ch = l.rows[cy].charAt(cx);
				if (ch == " ")
					continue;
				final name = l.legend.get(ch);
				if (name == null)
					continue; // the builder has checked the legend
				placeCover(cover, l, name, cx, cy, footprintOf(cellDef(name), cx, cy));
			}
		return cover;
	}

	/** Marks the cells a cell at (cx, cy) covers as its, once they are inside the map and free. **/
	function placeCover(cover:Array<Int>, l:TilemapLayerDef, name:String, cx:Int, cy:Int, r:CellRect):Void {
		if (r.x0 < 0 || r.y0 < 0 || r.x1 > width || r.y1 > height)
			throw BuilderError.of('tilemap $mapName: layer ${l.name}: $name at column $cx, row $cy covers columns ${r.x0} to ${r.x1 - 1}, rows ${r.y0} to ${r.y1 - 1}, outside the map (${width}x$height)',
				"tilemap_object_outside");
		for (y in r.y0...r.y1)
			for (x in r.x0...r.x1) {
				final other = cover[y * width + x];
				if (other >= 0)
					throw BuilderError.of('tilemap $mapName: layer ${l.name}: $name at column $cx, row $cy covers column $x, row $y, where ${nameAt(l, other)} at column ${other % width}, row ${Std.int(other / width)} is already',
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
		touchRect({x0: cx, y0: cy, x1: cx + 1, y1: cy + 1}, reach);
	}

	/** Cells changed: the chunks within `reach` cells of the rectangle are drawn again, next time. **/
	function touchRect(r:CellRect, reach:Int):Void {
		for (c in chunks)
			if (r.x1 + reach > c.rect.x0 && r.x0 - reach < c.rect.x1 && r.y1 + reach > c.rect.y0 && r.y0 - reach < c.rect.y1)
				c.dirty = true;
		changed = true;
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
			for (c in chunks)
				if (step.dy != 0 ? (cy + reach >= c.rect.y0 && cy - reach < c.rect.y1) : (cx + reach >= c.rect.x0 && cx - reach < c.rect.x1))
					c.dirty = true;
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

	/** Shows the chunks the view reaches and hides the rest; every chunk when there is no view. **/
	function applyCulling():Void {
		var view = cullRect;
		if (view == null && cullToScene) {
			final scene = getScene();
			if (scene != null)
				view = localRectOf(scene);
		}
		for (c in chunks) {
			// a corner autotile reaches half a tile past its cells
			final visible = view == null
				|| (c.rect.x1 * tileSize + tileSize > view.x && c.rect.x0 * tileSize - tileSize < view.x + view.w
					&& c.rect.y1 * tileSize + tileSize > view.y && c.rect.y0 * tileSize - tileSize < view.y + view.h);
			if (c.ground.visible != visible) {
				c.ground.visible = visible;
				c.over.visible = visible;
				c.top.visible = visible;
			}
		}
	}

	/** The scene's whole view in the map's own coordinates: a box around its four corners. **/
	function localRectOf(scene:h2d.Scene):{x:Float, y:Float, w:Float, h:Float} {
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
		return {x: minX, y: minY, w: maxX - minX, h: maxY - minY};
	}

	// ===================== Drawing =====================

	/**
		Draws everything again from the rows, now: new definitions, or cells changed since. A chunk
		is drawn by itself when it is next in view or asked what it draws, so this is for drawing
		them all sooner, whatever the view.
	**/
	public function redraw():Void {
		for (c in chunks)
			c.dirty = true;
		drawDirty(false);
	}

	/** Draws the dirty chunks, those in view only when `onlyVisible`; nothing when none is. **/
	function drawDirty(onlyVisible:Bool):Void {
		if (!changed)
			return;
		var todo:Null<Array<Chunk>> = null;
		for (c in chunks)
			if (c.dirty && (!onlyVisible || c.ground.visible)) {
				if (todo == null)
					todo = [];
				todo.push(c);
			}
		if (todo != null)
			drawChunks(todo);
	}

	/** Draws the chunk a cell is in if it is dirty: what `sideAt` and `metadataAt` read is drawn with it. **/
	function drawCellsChunk(cx:Int, cy:Int):Void {
		if (!changed)
			return;
		final c = chunks[Std.int(cy / chunkSize) * chunkCols + Std.int(cx / chunkSize)];
		if (c.dirty)
			drawChunks([c]);
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
		passLevelMasks = [];
		passPlatformMasks = [];
		passHighest = -1;
	}

	function endPass():Void {
		passTerrainMasks = [];
		passLevelMasks = [];
		passPlatformMasks = [];
	}

	/** Terrain `i`'s cells and those of every terrain above it, within the pass. **/
	function terrainMask(i:Int):Array<Array<Int>> {
		var mask = passTerrainMasks[i];
		if (mask == null) {
			mask = rectGrid(passRect, (cx, cy) -> terrainIndex[cy * width + cx] >= i ? 1 : 0);
			passTerrainMasks[i] = mask;
		}
		return mask;
	}

	/** The ground's cells at `level` or above, platforms left out, within the pass. **/
	function levelMask(level:Int):Array<Array<Int>> {
		var mask = passLevelMasks.get(level);
		if (mask == null) {
			mask = rectGrid(passRect, (cx, cy) -> levelAt(cx, cy) >= level && platformAt(cx, cy) == null ? 1 : 0);
			passLevelMasks.set(level, mask);
		}
		return mask;
	}

	/** A platform's cells at `level` or above, within the pass; null when it has none there. **/
	function platformMask(platform:String, level:Int):Null<Array<Array<Int>>> {
		final key = '$platform#$level';
		if (passPlatformMasks.exists(key))
			return passPlatformMasks.get(key);
		final mask = sparse(passRect, (cx, cy) -> levelAt(cx, cy) >= level && platformAt(cx, cy) == platform ? 1 : 0);
		passPlatformMasks.set(key, mask);
		return mask;
	}

	/** The highest level within the pass: a level nowhere near the chunks drawn has nothing to draw in them. **/
	function highestLevel():Int {
		if (passHighest < 0) {
			var highest = 0;
			for (cy in passRect.y0...passRect.y1)
				for (cx in passRect.x0...passRect.x1)
					if (levelAt(cx, cy) > highest) highest = levelAt(cx, cy);
			passHighest = highest;
		}
		return passHighest;
	}

	function drawChunk(c:Chunk):Void {
		c.dirty = false;
		c.ground.removeChildren();
		c.over.removeChildren();
		c.top.removeChildren();
		for (o in c.objects)
			o.remove();
		c.objects = [];
		c.animated = [];
		for (cy in c.rect.y0...c.rect.y1)
			for (cx in c.rect.x0...c.rect.x1) {
				sides[cy * width + cx] = 0;
				sideRises[cy * width + cx] = -1;
			}
		drawTerrains(c);
		drawRises(c);
		drawLayers(c);
		mergeMetadata(c);
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
			case Cross | Blob47: c.rect;
		};
	}

	/**
		A grid over a rectangle of positions only: the rows above it empty, each row's positions
		before it 0, so an autotile walks just the rectangle, and what reads it (`Autotile.isFilled`)
		takes a missing position as 0.
	**/
	function rectGrid(r:CellRect, at:(x:Int, y:Int) -> Int):Array<Array<Int>> {
		final rows:Array<Array<Int>> = [for (_ in 0...r.y0) EMPTY_ROW];
		for (y in r.y0...r.y1) {
			final row:Array<Int> = [for (_ in 0...r.x0) 0];
			for (x in r.x0...r.x1)
				row.push(at(x, y));
			rows.push(row);
		}
		return rows;
	}

	/** A `where` grid over a rectangle of positions, as `rectGrid`; null when nothing in it is set. **/
	function sparse(r:CellRect, at:(x:Int, y:Int) -> Int):Null<Array<Array<Int>>> {
		var any = false;
		final rows = rectGrid(r, (x, y) -> {
			final v = at(x, y);
			if (v != 0)
				any = true;
			v;
		});
		return any ? rows : null;
	}

	/**
		The positions of a rectangle an autotile over `mask` draws anything at: corners with a filled
		cell around them, or filled cells. Null when none, so a terrain absent from a chunk is not
		asked for at all.
	**/
	function drawnPositions(mask:Array<Array<Int>>, format:AutotileFormat, r:CellRect):Null<Array<Array<Int>>> {
		return switch format {
			case Corner: sparse(r, (x, y) -> Autotile.getCornerIndex(mask, x, y) != 0 ? 1 : 0);
			case Cross | Blob47: sparse(r, (x, y) -> Autotile.isFilled(mask, x, y) ? 1 : 0);
		};
	}

	function drawTerrains(c:Chunk):Void {
		for (i in 0...tileset.terrains.length) {
			final terrain = tileset.terrains[i];
			final cells = terrain.cells;
			if (cells != null) {
				final frames = framesOf(tileset.atlas, cells);
				final groups = new TileGroups(c.ground);
				for (cy in c.rect.y0...c.rect.y1)
					for (cx in c.rect.x0...c.rect.x1)
						if (terrainIndex[cy * width + cx] >= i)
							groups.add(cx * tileSize, cy * tileSize, frames[Autotile.variantAt(cx, cy, frames.length)]);
				continue;
			}
			if (terrain.autotiles.length == 0)
				continue;
			final mask = terrainMask(i);
			final format = tiles.autotileFormat(terrain.autotiles[0]);
			final ownWhere = drawnPositions(mask, format, positionsOf(c, format));
			if (ownWhere == null)
				continue; // none of the terrain near this chunk
			// The terrain's own autotile over its cells and those of the terrains above it; then,
			// where it meets a terrain it has a transition from, that pair's autotile over the
			// meeting positions. An animated terrain has one of each a frame.
			final transitions = [for (t in tileset.transitions) if (t.to == terrain.name) t];
			final frameGroups:Array<h2d.Object> = [];
			for (k in 0...terrain.autotiles.length) {
				final ownGroup = tiles.autotile(terrain.autotiles[k], mask, ownWhere);
				if (transitions.length == 0) {
					frameGroups.push(ownGroup);
					continue;
				}
				final frame = new h2d.Object();
				frame.addChild(ownGroup);
				for (t in transitions) {
					final autotile = t.autotiles[k];
					final format = tiles.autotileFormat(autotile);
					final where = meetingPositions(i, terrainIndexOf(t.from), format, positionsOf(c, format));
					if (where != null)
						frame.addChild(tiles.autotile(autotile, mask, where));
				}
				frameGroups.push(frame);
			}
			for (g in frameGroups)
				c.ground.addChild(g);
			if (frameGroups.length > 1) {
				showFrame(frameGroups, animClocks[i].index);
				c.animated.push({terrain: i, frames: frameGroups});
			}
		}
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
		`none`, which the map's edge counts as). Null when there is no such position.
	**/
	function meetingPositions(i:Int, from:Int, format:AutotileFormat, r:CellRect):Null<Array<Array<Int>>> {
		inline function terrainAtCell(cx:Int, cy:Int):Int
			return inside(cx, cy) ? terrainIndex[cy * width + cx] : -1;
		function meets(cells:Array<Int>):Int {
			var insideCount = 0;
			var outsideCount = 0;
			for (t in cells) {
				if (t >= i)
					insideCount++;
				else if (t == from)
					outsideCount++;
				else
					return 0;
			}
			return insideCount == 0 || outsideCount == 0 ? 0 : 1;
		}
		return switch format {
			case Corner:
				sparse(r, (cx, cy) -> meets([terrainAtCell(cx - 1, cy - 1), terrainAtCell(cx, cy - 1), terrainAtCell(cx - 1, cy), terrainAtCell(cx, cy)]));
			case Cross | Blob47:
				sparse(r, (cx, cy) -> terrainAtCell(cx, cy) < i ? 0 : meets([
					for (dy in -1...2) for (dx in -1...2) terrainAtCell(cx + dx, cy + dy)
				]));
		};
	}

	/** The step from a cell to its neighbour, by `toward:`. **/
	public static function towardStep(toward:String):{dx:Int, dy:Int} {
		return switch toward {
			case "up": {dx: 0, dy: -1};
			case "left": {dx: -1, dy: 0};
			case "right": {dx: 1, dy: 0};
			default: {dx: 0, dy: 1};
		};
	}

	function drawRises(c:Chunk):Void {
		if (def.levels.length == 0)
			return;
		final highest = highestLevel();
		// Every level's outline: along its rim only, so what is on the level shows; the autotile of
		// the terrain on top where the tileset has one for it, the tileset's own otherwise.
		final edgeNames:Array<String> = [];
		final defaultEdge = tileset.edge;
		if (defaultEdge != null)
			edgeNames.push(defaultEdge);
		for (name in tileset.edges)
			if (!edgeNames.contains(name)) edgeNames.push(name);
		for (level in 1...highest + 1) {
			final mask = levelMask(level);
			for (name in edgeNames) {
				final format = tiles.autotileFormat(name);
				final where = rimPositions(mask, name, format, positionsOf(c, format));
				if (where != null)
					c.ground.addChild(tiles.autotile(name, mask, where));
			}
		}
		// Every platform's top: its own autotile over all of it, on whatever terrain is under it
		for (platform in tileset.platforms) {
			final edge = platform.edge;
			if (edge == null)
				continue;
			final format = tiles.autotileFormat(edge);
			for (level in 1...highest + 1) {
				final mask = platformMask(platform.name, level);
				if (mask == null)
					continue;
				final where = drawnPositions(mask, format, positionsOf(c, format));
				if (where != null)
					c.ground.addChild(tiles.autotile(edge, mask, where));
			}
		}
		// Beyond a higher cell, toward the neighbour its rise faces, the side over `span` cells;
		// drawn where it lands, so the higher cells looked at reach `span` outside the chunk
		final groups = new TileGroups(c.ground);
		final towards:Array<String> = [];
		for (rise in tileset.rises)
			if (!towards.contains(rise.toward)) towards.push(rise.toward);
		final span = maxSpan();
		for (toward in towards) {
			final step = towardStep(toward);
			// its neighbours along the side's run, in reading order (left or above first)
			final px = step.dy != 0 ? 1 : 0;
			final py = step.dx != 0 ? 1 : 0;
			for (cy in c.rect.y0 - span...c.rect.y1 + span)
				for (cx in c.rect.x0 - span...c.rect.x1 + span) {
					if (!inside(cx, cy))
						continue;
					final index = riseIndexAt(cx, cy, toward, step.dx, step.dy);
					if (index < 0)
						continue;
					final rise = tileset.rises[index];
					final before = riseIndexAt(cx - px, cy - py, toward, step.dx, step.dy) == index;
					final after = riseIndexAt(cx + px, cy + py, toward, step.dx, step.dy) == index;
					// how far along the run the cell is, for a middle of several taken in turn
					var along = 0;
					if (before && rise.sides.length > 1)
						while (riseIndexAt(cx - px * (along + 1), cy - py * (along + 1), toward, step.dx, step.dy) == index)
							along++;
					var frames:Null<Array<h2d.Tile>> = null;
					for (k in 0...rise.span) {
						final sx = cx + step.dx * (k + 1);
						final sy = cy + step.dy * (k + 1);
						if (!inside(sx, sy))
							break;
						if (sx < c.rect.x0 || sx >= c.rect.x1 || sy < c.rect.y0 || sy >= c.rect.y1)
							continue;
						if (frames == null)
							frames = framesOf(tileset.atlas, sidePiece(rise, before, after, along));
						groups.add(sx * tileSize, sy * tileSize, frames[k < frames.length ? k : frames.length - 1]);
						sides[sy * width + sx] = riseToward(cx, cy, step.dx, step.dy);
						sideRises[sy * width + sx] = index;
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
		inline function filled(cx:Int, cy:Int):Bool
			return Autotile.isFilled(mask, cx, cy);
		return switch format {
			case Corner:
				sparse(r, (cx, cy) -> {
					// the cells around the corner, the one below and right of it first
					final around = [[cx, cy], [cx - 1, cy], [cx, cy - 1], [cx - 1, cy - 1]];
					var count = 0;
					var edge:Null<String> = null;
					for (cell in around)
						if (filled(cell[0], cell[1])) {
							count++;
							if (edge == null) edge = edgeOfCell(cell[0], cell[1]);
						}
					count > 0 && count < 4 && edge == name ? 1 : 0;
				});
			case Cross | Blob47:
				sparse(r, (cx, cy) -> {
					var rim = false;
					if (filled(cx, cy) && edgeOfCell(cx, cy) == name)
						for (dy in -1...2)
							for (dx in -1...2)
								if (!filled(cx + dx, cy + dy)) rim = true;
					rim ? 1 : 0;
				});
		};
	}

	/** How many levels a cell stands above its neighbour one step away; 0 at the map's edge or when it does not. **/
	function riseToward(cx:Int, cy:Int, dx:Int, dy:Int):Int {
		if (!inside(cx, cy) || !inside(cx + dx, cy + dy))
			return 0;
		final d = levelAt(cx, cy) - levelAt(cx + dx, cy + dy);
		return d > 0 ? d : 0;
	}

	/** Which of the tileset's rises draws the side of a cell toward a neighbour; -1 when it stands no higher, or the tileset has none for it. **/
	function riseIndexAt(cx:Int, cy:Int, toward:String, dx:Int, dy:Int):Int {
		final levels = riseToward(cx, cy, dx, dy);
		if (levels <= 0)
			return -1;
		final t = terrainIndex[cy * width + cx];
		return riseFor(tileset, levels, toward, t >= 0 ? tileset.terrains[t].name : null, platformAt(cx, cy));
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

	function drawLayers(c:Chunk):Void {
		for (layer in def.layers) {
			final sheet = layer.sheet != null ? layer.sheet : tileset.atlas;
			final under = new TileGroups(c.ground);
			final over = new TileGroups(c.over);
			final top = new TileGroups(c.top);
			for (cy in c.rect.y0...c.rect.y1) {
				final row = layer.rows[cy];
				for (cx in c.rect.x0...c.rect.x1) {
					final ch = row.charAt(cx);
					if (ch == " ")
						continue;
					final name = layer.legend.get(ch);
					if (name == null)
						continue;
					final frames = framesOf(sheet, name);
					final tile = frames[Autotile.variantAt(cx, cy, frames.length)];
					final cell = cellDef(name);
					final draw = cell != null && cell.draw != null ? cell.draw : layer.draw;
					// an object of several cells is drawn from its top-left, the layer's character at its anchor
					final ax = cell != null && cell.anchorX != null ? cell.anchorX : 0;
					final ay = cell != null && cell.anchorY != null ? cell.anchorY : 0;
					final x = (cx - ax) * tileSize;
					final y = (cy - ay) * tileSize;
					switch draw {
						case "actors":
							// among the actors, standing on its feet: its y is its bottom edge, which sorts it
							final t = tile.clone();
							t.dy -= t.height;
							final sprite = new h2d.Bitmap(t);
							sprite.x = x;
							sprite.y = y + t.height;
							actors.add(sprite, 0);
							c.objects.push(sprite);
						case "over": over.add(x, y, tile);
						case "top": top.add(x, y, tile);
						default: under.add(x, y, tile);
					}
				}
			}
		}
	}

	/** A chunk's cells' metadata, merged once a draw: the terrain's, a side's over it, then each layer's cell there (an object's on every cell it covers). **/
	function mergeMetadata(c:Chunk):Void {
		for (cy in c.rect.y0...c.rect.y1)
			for (cx in c.rect.x0...c.rect.x1) {
				final i = cy * width + cx;
				var merged:Null<Map<String, SettingValue>> = null;
				function take(from:ResolvedSettings) {
					if (from == null)
						return;
					if (merged == null)
						merged = new Map();
					for (k => v in from)
						merged.set(k, v);
				}
				if (terrainIndex[i] >= 0)
					take(terrainMetadata[terrainIndex[i]]);
				if (sideRises[i] >= 0)
					take(riseMetadata[sideRises[i]]);
				for (li in 0...def.layers.length) {
					final anchor = covers[li][i];
					if (anchor >= 0)
						take(cellMetadata.get(nameAt(def.layers[li], anchor)));
				}
				metadata[i] = merged != null ? new BuilderResolvedSettings(merged) : NO_METADATA;
			}
	}

	/** The frames of a name, which the builder checked were there. **/
	function framesOf(sheet:String, name:String):Array<h2d.Tile> {
		final frames = tiles.frames(sheet, name);
		if (frames == null || frames.length == 0)
			throw BuilderError.of('tilemap $mapName: sheet $sheet has no cell $name', "tilemap_missing_cell");
		return frames;
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

/** TileGroups under one parent, one a texture: a TileGroup draws from a single texture. **/
private class TileGroups {
	final parent:h2d.Object;
	final groups:Array<h2d.TileGroup> = [];

	public function new(parent:h2d.Object) {
		this.parent = parent;
	}

	public function add(x:Float, y:Float, tile:h2d.Tile):Void {
		final texture = tile.getTexture();
		for (g in groups)
			if (g.tile.getTexture() == texture) {
				g.add(x, y, tile);
				return;
			}
		final g = new h2d.TileGroup(tile, parent);
		groups.push(g);
		g.add(x, y, tile);
	}
}
