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
		corner format, cells otherwise).
	**/
	var autotile:(name:String, grid:Array<Array<Int>>, where:Null<Array<Array<Int>>>) -> h2d.TileGroup;

	/** An autotile's format, which says what its positions are; throws for a name the file has not. **/
	var autotileFormat:(name:String) -> AutotileFormat;

	/** The frames of a name in a sheet, or null when the sheet has no such name. **/
	var frames:(sheet:String, name:String) -> Null<Array<h2d.Tile>>;

	/** A terrain's, a rise's or a cell's metadata, resolved as settings are; null when it has none. **/
	var metadata:(parsed:Map<String, ParsedSettingValue>) -> ResolvedSettings;
}

/**
	A tile map (`#name tilemap { … }` in a .manim), drawn from its tileset:

	- the terrains, bottom first, each drawn under every terrain after it (an autotile over the
	  cells of that terrain and of the terrains after it, or the variants of an atlas name);
	- the levels: each outlined with the tileset's `edge` (the one of the terrain on top, where the
	  tileset has one for it), along its rim only, and beyond a higher cell, toward the lower
	  neighbour its rise faces (`toward:`, down by default), the rise's `side` over `span` cells. Nothing is lifted: what
	  stands on a higher level stands on its cells, where they are drawn;
	- the platforms (a tree top, a roof: a kind of higher level that is not the ground raised, where the
	  map's levels legend says one): each drawn with its own `edge` over all of it, and its own sides;
	- the cell layers, each from its own sheet (the tileset's atlas by default), drawn `under` the
	  actors, `over` them, or at the `top`, above everything; a `cell` of the tileset may say otherwise;
	- the decor and the actors in one layer, `actors`, sorted by their feet (`y`) every frame.

	It steps itself as it is drawn: the animated terrains and the sorting run in `sync`, with the frame's
	time, so nothing is to be called from the game loop. `sortActors = false` turns the sorting off.

	What a cell means to the game is its metadata, from the tileset: its terrain's, a rise's side over
	it, then each layer's cell there, a later one winning, read as settings are (`metadataAt(x, y)
	.getBoolOrDefault("wall", false)`). The map says what is where
	(`terrainAt`, `levelAt`, `cellAt`, `sideAt`, `mark`) and may be changed while the game runs
	(`setTerrain`, `setLevel`, `setCell`): however many cells change, the map is drawn again once, as
	it is next drawn or asked what it draws (`terrainAt`, `sideAt`, `metadataAt`); `redraw()` draws
	it now.
**/
class TileMap extends h2d.Object {
	/** Every tile map in a scene: what the DevBridge's `map_list` and `map_get` read, and hot reload redraws. **/
	public static final showing:Array<TileMap> = [];

	/** The map's name in its file. **/
	public final mapName:String;

	/** The .manim file it was read from. **/
	public var sourceName(default, null):String;

	public var tileSize(default, null):Int = 0;
	public var width(default, null):Int = 0;
	public var height(default, null):Int = 0;

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

	var tiles:TileMapTiles;
	final ground:h2d.Object;
	final overLayer:h2d.Object;
	final topLayer:h2d.Object;
	var decor:Array<h2d.Object> = [];
	var animated:Array<{frames:Array<h2d.Object>, duration:Float, time:Float, index:Int}> = [];
	var terrainIndex:Array<Int> = [];
	// Per cell: the rise of a side drawn over it, 0 for none; and which of the tileset's rises drew it, -1 for none
	var sides:Array<Int> = [];
	var sideRises:Array<Int> = [];
	// The tileset's metadata, resolved once a source: per terrain, per rise (as tileset.rises) and per cell name
	var terrainMetadata:Array<ResolvedSettings> = [];
	var riseMetadata:Array<ResolvedSettings> = [];
	var cellMetadata:Map<String, ResolvedSettings> = [];
	// Per cell: its metadata, merged; one shared empty where it has none
	var metadata:Array<BuilderResolvedSettings> = [];
	// Changed since it was drawn: drawn again, once, when next drawn or asked what it draws
	var changed = false;

	static final NO_METADATA = new BuilderResolvedSettings(null);

	public function new(mapName:String, sourceName:String, def:TilemapDef, tileset:TilesetDef, tiles:TileMapTiles, ?parent:h2d.Object) {
		super(parent);
		this.mapName = mapName;
		this.sourceName = sourceName;
		this.def = def;
		this.tileset = tileset;
		this.tiles = tiles;
		ground = new h2d.Object(this);
		actors = new h2d.Layers(this);
		overLayer = new h2d.Object(this);
		topLayer = new h2d.Object(this);
		setSource(def, tileset, tiles);
	}

	/** New definitions, from a hot reload: the map is drawn again and the actors stay. **/
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
		redraw();
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
		drawChanges();
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

	/** The name of the cell a layer has there, or null. **/
	public function cellAt(layer:String, cx:Int, cy:Int):Null<String> {
		if (!inside(cx, cy))
			return null;
		for (l in def.layers)
			if (l.name == layer) {
				final c = l.rows[cy].charAt(cx);
				return c == " " ? null : l.legend.get(c);
			}
		return null;
	}

	/** The rise of a side drawn over the cell, or 0. **/
	public function sideAt(cx:Int, cy:Int):Int {
		if (!inside(cx, cy))
			return 0;
		drawChanges();
		return sides[cy * width + cx];
	}

	/**
		The cell's metadata: its terrain's, a side's over it, then each layer's cell there, a later one
		winning; read as settings are (`getBoolOrDefault`, `getIntOrDefault`, `getFloatOrDefault`,
		`getStringOrDefault`, `has`, `keys`). Empty outside the map.
	**/
	public function metadataAt(cx:Int, cy:Int):BuilderResolvedSettings {
		if (!inside(cx, cy))
			return NO_METADATA;
		drawChanges();
		return metadata[cy * width + cx];
	}

	public function mark(name:String):Null<TilemapMarkDef> {
		for (m in def.marks)
			if (m.name == name) return m;
		return null;
	}

	/** Changes a cell's terrain to the one `char` stands for in the legend; the map is drawn again (see `redraw`). **/
	public function setTerrain(cx:Int, cy:Int, char:String):Void {
		checkInside(cx, cy);
		if (!def.legend.exists(char))
			throw BuilderError.of('tilemap $mapName: "$char" is not in the legend', "tilemap_legend");
		def.terrain[cy] = replaceAt(def.terrain[cy], cx, char);
		changed = true;
	}

	/**
		Changes a cell's level: the ground raised to `level` (a digit, or a character of the map's
		levels legend that is not a platform's); the map is drawn again (see `redraw`).
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
		changed = true;
	}

	/** Changes a layer's cell (`" "` for none); the map is drawn again (see `redraw`). **/
	public function setCell(layer:String, cx:Int, cy:Int, char:String):Void {
		checkInside(cx, cy);
		for (l in def.layers)
			if (l.name == layer) {
				if (char != " " && !l.legend.exists(char))
					throw BuilderError.of('tilemap $mapName: "$char" is not in the legend of layer $layer', "tilemap_legend");
				l.rows[cy] = replaceAt(l.rows[cy], cx, char);
				changed = true;
				return;
			}
		throw BuilderError.of('tilemap $mapName has no layer $layer', "tilemap_layer");
	}

	function checkInside(cx:Int, cy:Int):Void {
		if (!inside(cx, cy))
			throw BuilderError.of('tilemap $mapName: column $cx, row $cy is outside the map (${width}x$height)', "tilemap_outside");
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
		for (a in animated) {
			a.time += dt;
			while (a.time >= a.duration) {
				a.time -= a.duration;
				a.frames[a.index].visible = false;
				a.index = (a.index + 1) % a.frames.length;
				a.frames[a.index].visible = true;
			}
		}
		if (sortActors)
			actors.ysort(0);
	}

	override function sync(ctx:h2d.RenderContext) {
		drawChanges();
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

	// ===================== Drawing =====================

	/** Draws the map again now if a cell changed since it was drawn; otherwise nothing. **/
	inline function drawChanges():Void {
		if (changed)
			redraw();
	}

	/**
		Draws everything again from the rows, now: new definitions, or cells changed since. The
		changes are drawn by themselves when the map is next drawn or asked what it draws, so this is
		for drawing them sooner.
	**/
	public function redraw():Void {
		changed = false;
		ground.removeChildren();
		overLayer.removeChildren();
		topLayer.removeChildren();
		animated = [];
		final cells = width * height;
		terrainIndex = [for (_ in 0...cells) -1];
		sides = [for (_ in 0...cells) 0];
		sideRises = [for (_ in 0...cells) -1];
		for (cy in 0...height)
			for (cx in 0...width)
				terrainIndex[cy * width + cx] = terrainIndexOf(def.legend.get(def.terrain[cy].charAt(cx)));
		drawTerrains();
		drawRises();
		drawLayers();
		mergeMetadata();
	}

	function drawTerrains():Void {
		for (i in 0...tileset.terrains.length) {
			final terrain = tileset.terrains[i];
			final mask = [for (cy in 0...height) [for (cx in 0...width) terrainIndex[cy * width + cx] >= i ? 1 : 0]];
			final cells = terrain.cells;
			if (cells != null) {
				final frames = framesOf(tileset.atlas, cells);
				final groups = new TileGroups(ground);
				for (cy in 0...height)
					for (cx in 0...width)
						if (mask[cy][cx] != 0)
							groups.add(cx * tileSize, cy * tileSize, frames[Autotile.variantAt(cx, cy, frames.length)]);
				continue;
			}
			// The terrain's own autotile over its cells and those of the terrains above it; then,
			// where it meets a terrain it has a transition from, that pair's autotile over the
			// meeting positions. An animated terrain has one of each a frame.
			final transitions = [for (t in tileset.transitions) if (t.to == terrain.name) t];
			final frameGroups:Array<h2d.Object> = [];
			for (k in 0...terrain.autotiles.length) {
				final own = tiles.autotile(terrain.autotiles[k], mask, null);
				if (transitions.length == 0) {
					frameGroups.push(own);
					continue;
				}
				final frame = new h2d.Object();
				frame.addChild(own);
				for (t in transitions) {
					final autotile = t.autotiles[k];
					final where = meetingPositions(i, terrainIndexOf(t.from), tiles.autotileFormat(autotile));
					if (where != null)
						frame.addChild(tiles.autotile(autotile, mask, where));
				}
				frameGroups.push(frame);
			}
			for (g in frameGroups)
				ground.addChild(g);
			if (frameGroups.length > 1) {
				for (k in 1...frameGroups.length)
					frameGroups[k].visible = false;
				final duration = terrain.duration != null ? terrain.duration : 1000;
				animated.push({frames: frameGroups, duration: duration / 1000, time: 0, index: 0});
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
		Where terrain `i` (with the terrains above it) meets terrain `from` and nothing else: the
		autotile positions (corners of the corner format, cells otherwise) whose surrounding cells are
		some of each, every outside one being `from` (-1 for `none`, which the map's edge counts as).
		Null when there is no such position.
	**/
	function meetingPositions(i:Int, from:Int, format:AutotileFormat):Null<Array<Array<Int>>> {
		inline function terrainAtCell(cx:Int, cy:Int):Int
			return inside(cx, cy) ? terrainIndex[cy * width + cx] : -1;
		var any = false;
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
			if (insideCount == 0 || outsideCount == 0)
				return 0;
			any = true;
			return 1;
		}
		final where = switch format {
			case Corner:
				[for (cy in 0...height + 1) [for (cx in 0...width + 1)
					meets([terrainAtCell(cx - 1, cy - 1), terrainAtCell(cx, cy - 1), terrainAtCell(cx - 1, cy), terrainAtCell(cx, cy)])]];
			case Cross | Blob47:
				[for (cy in 0...height) [for (cx in 0...width)
					terrainAtCell(cx, cy) < i ? 0 : meets([
						for (dy in -1...2) for (dx in -1...2) terrainAtCell(cx + dx, cy + dy)
					])]];
		};
		return any ? where : null;
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

	function drawRises():Void {
		if (def.levels.length == 0)
			return;
		var highest = 0;
		for (cy in 0...height)
			for (cx in 0...width)
				if (levelAt(cx, cy) > highest) highest = levelAt(cx, cy);
		// Every level's outline: along its rim only, so what is on the level shows; the autotile of
		// the terrain on top where the tileset has one for it, the tileset's own otherwise.
		final edgeNames:Array<String> = [];
		final defaultEdge = tileset.edge;
		if (defaultEdge != null)
			edgeNames.push(defaultEdge);
		for (name in tileset.edges)
			if (!edgeNames.contains(name)) edgeNames.push(name);
		for (level in 1...highest + 1) {
			final mask = [for (cy in 0...height) [for (cx in 0...width) levelAt(cx, cy) >= level && platformAt(cx, cy) == null ? 1 : 0]];
			for (name in edgeNames) {
				final where = rimPositions(mask, name, tiles.autotileFormat(name));
				if (where != null)
					ground.addChild(tiles.autotile(name, mask, where));
			}
		}
		// Every platform's top: its own autotile over all of it, on whatever terrain is under it
		for (platform in tileset.platforms) {
			final edge = platform.edge;
			if (edge == null)
				continue;
			for (level in 1...highest + 1) {
				var any = false;
				final mask = [for (cy in 0...height) [for (cx in 0...width) if (levelAt(cx, cy) >= level && platformAt(cx, cy) == platform.name) {
					any = true;
					1;
				} else 0]];
				if (any)
					ground.addChild(tiles.autotile(edge, mask, null));
			}
		}
		// Beyond a higher cell, toward the neighbour its rise faces, the side over `span` cells
		final groups = new TileGroups(ground);
		final towards:Array<String> = [];
		for (rise in tileset.rises)
			if (!towards.contains(rise.toward)) towards.push(rise.toward);
		for (toward in towards) {
			final step = towardStep(toward);
			// its neighbours along the side's run, in reading order (left or above first)
			final px = step.dy != 0 ? 1 : 0;
			final py = step.dx != 0 ? 1 : 0;
			for (cy in 0...height)
				for (cx in 0...width) {
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
					final frames = framesOf(tileset.atlas, sidePiece(rise, before, after, along));
					for (k in 0...rise.span) {
						final sx = cx + step.dx * (k + 1);
						final sy = cy + step.dy * (k + 1);
						if (!inside(sx, sy))
							break;
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
		Where an edge autotile is drawn for a level's mask: its positions (corners of the corner
		format, cells otherwise) on the level's rim, where the terrain on top has this autotile as
		its edge. The inside of a level is not outlined, so its terrains show. Null when nowhere.
	**/
	function rimPositions(mask:Array<Array<Int>>, name:String, format:AutotileFormat):Null<Array<Array<Int>>> {
		inline function filled(cx:Int, cy:Int):Bool
			return inside(cx, cy) && mask[cy][cx] != 0;
		var any = false;
		final where = switch format {
			case Corner:
				[for (cy in 0...height + 1) [for (cx in 0...width + 1) {
					// the cells around the corner, the one below and right of it first
					final around = [[cx, cy], [cx - 1, cy], [cx, cy - 1], [cx - 1, cy - 1]];
					var count = 0;
					var edge:Null<String> = null;
					for (c in around)
						if (filled(c[0], c[1])) {
							count++;
							if (edge == null) edge = edgeOfCell(c[0], c[1]);
						}
					if (count > 0 && count < 4 && edge == name) {
						any = true;
						1;
					} else 0;
				}]];
			case Cross | Blob47:
				[for (cy in 0...height) [for (cx in 0...width) {
					var rim = false;
					if (filled(cx, cy) && edgeOfCell(cx, cy) == name)
						for (dy in -1...2)
							for (dx in -1...2)
								if (!filled(cx + dx, cy + dy)) rim = true;
					if (rim) {
						any = true;
						1;
					} else 0;
				}]];
		};
		return any ? where : null;
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

	function drawLayers():Void {
		for (layer in def.layers) {
			final sheet = layer.sheet != null ? layer.sheet : tileset.atlas;
			final under = new TileGroups(ground);
			final over = new TileGroups(overLayer);
			final top = new TileGroups(topLayer);
			for (cy in 0...height) {
				final row = layer.rows[cy];
				for (cx in 0...width) {
					final c = row.charAt(cx);
					if (c == " ")
						continue;
					final name = layer.legend.get(c);
					if (name == null)
						continue;
					final frames = framesOf(sheet, name);
					final tile = frames[Autotile.variantAt(cx, cy, frames.length)];
					final cell = cellDef(name);
					final draw = cell != null && cell.draw != null ? cell.draw : layer.draw;
					(switch draw {
						case "over": over;
						case "top": top;
						default: under;
					}).add(cx * tileSize, cy * tileSize, tile);
				}
			}
		}
	}

	/** Each cell's metadata, merged once a draw: its terrain's, a side's over it, then each layer's cell. **/
	function mergeMetadata():Void {
		metadata = [for (_ in 0...width * height) NO_METADATA];
		for (cy in 0...height)
			for (cx in 0...width) {
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
				for (l in def.layers) {
					final c = l.rows[cy].charAt(cx);
					final name = c == " " ? null : l.legend.get(c);
					if (name != null)
						take(cellMetadata.get(name));
				}
				if (merged != null)
					metadata[i] = new BuilderResolvedSettings(merged);
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
