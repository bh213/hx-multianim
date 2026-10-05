package bh.test.examples;

import utest.Assert;
import bh.base.TileMap;
import bh.base.TileMap.TileMapTiles;
import bh.multianim.BuilderError;
import bh.multianim.MultiAnimBuilder;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.builderFromSource;
import bh.test.BuilderTestBase.parseExpectingError;

/**
 * Tilesets and tile maps (`#name tileset { … }`, `#name tilemap { … }`, `tilemap(name)`): parse
 * errors, terrains drawn bottom first, levels with their rims, faces and joins, cell layers and
 * where they are drawn, the actors sorted by their feet, animated terrains, changes while running,
 * a reload that keeps the actors, and what the DevBridge is told. Cells from the public Forgotten
 * Plains tiles and demo autotiles; nothing here depends on how that sheet is laid out.
 */
class TilemapTest extends BuilderTestBase {
	static inline var TILESET_PNG = "Tileset/Minifantasy_ForgottenPlainsTiles.png";

	/** A tileset and room for the map under test. Its cells are any 8x8 squares of the sheet. **/
	public static function source(map:String, ?extraTileset:String = "", ?extraAtlas:String = ""):String {
		return '
			#fp atlas2("$TILESET_PNG") {
				grass: 32, 24, 8, 8, index: 0
				grass: 32, 40, 8, 8, index: 1
				flower: 16, 8, 8, 8
				face: 296, 112, 8, 8, index: 0
				face: 296, 120, 8, 8, index: 1
				faceEnd: 288, 112, 8, 8, index: 0
				faceEnd: 288, 120, 8, 8, index: 1
				stairs: 88, 160, 8, 8
				roof: 24, 8, 8, 8
				tree: 0, 0, 16, 16
				$extraAtlas
			}
			#dirt autotile { format: corner tileSize: 8 demo: #886644, #664422 }
			#water autotile { format: corner tileSize: 8 demo: #2A4A9A, #4A78D0 }
			#waterB autotile { format: corner tileSize: 8 demo: #2A4A9A, #5A88E0 }
			#rim autotile { format: corner tileSize: 8 demo: #3A2A1A, #00000000 }
			#plains tileset {
				tileSize: 8
				atlas: "fp"
				edge: rim
				terrain grass { cells: "grass" metadata { cost:int => 1 } }
				terrain dirt { autotile: dirt metadata { cost:int => 2, look => "muddy" } }
				terrain water { autotile: water, waterB duration: 300 metadata { swim:bool => yes, cost:float => 3.5 } }
				rise 1 { side: "face" left: "faceEnd" span: 2 metadata { wall:bool => true } }
				cell stairs { metadata { wall:bool => false, climb => true } }
				cell roof { draw: over }
				$extraTileset
			}
			$map
		';
	}

	/** A map built and drawn whole: a map draws a chunk as it is first seen or asked, and these tests look at what is drawn. **/
	static function build(map:String, ?name:String = "m"):TileMap {
		final map = builderFromSource(source(map)).buildTilemap(name);
		map.redraw();
		return map;
	}

	static function builderErrorCode(fn:() -> Void):Null<String> {
		try {
			fn();
			return null;
		} catch (e:BuilderError) {
			return e.code;
		}
	}

	/** The index-th thing drawn on the ground of a map small enough for one chunk. **/
	static function groundGroup(map:TileMap, index:Int):h2d.TileGroup {
		return cast groundOf(map, 0)[index];
	}

	/** What a chunk drew under the actors, in the order it is drawn: its part of each of the ground's passes, in turn. **/
	static function groundOf(map:TileMap, chunk:Int):Array<h2d.Object> {
		final drawn:Array<h2d.Object> = [];
		final parts = @:privateAccess map.chunks[chunk].parts;
		for (pass in 0...@:privateAccess map.overPass) {
			final part = parts[pass];
			if (part != null)
				for (o in part)
					drawn.push(o);
		}
		return drawn;
	}

	/** How many things every chunk drew in the map's over or top layer: its passes' parts' children. **/
	static function drawnIn(layer:h2d.Object):Int {
		var n = 0;
		for (pass in layer)
			for (part in pass)
				n += part.numChildren;
		return n;
	}

	// ===== Parsing =====

	@Test
	public function testParseErrors() {
		function expect(fragment:String, text:String, ?pos:haxe.PosInfos) {
			final error = parseExpectingError(text);
			Assert.notNull(error, 'expected an error with "$fragment"', pos);
			if (error != null) Assert.stringContains(fragment, error, pos);
		}
		final ts = '#t tileset { tileSize: 8 atlas: "fp" terrain g { cells: "grass" } }\n';
		expect("row 2 is 3 characters, the map is 2 wide", ts + '#m tilemap { tileset: t size: 2, 2 legend { ".": g } terrain: ["..", "..."] }');
		expect('row 1: "x" is not in the legend', ts + '#m tilemap { tileset: t size: 2, 1 legend { ".": g } terrain: [".x"] }');
		expect("terrain has 1 rows, the map is 2 high", ts + '#m tilemap { tileset: t size: 2, 2 legend { ".": g } terrain: [".."] }');
		expect("is not a level", ts + '#m tilemap { tileset: t size: 2, 1 legend { ".": g } terrain: [".."] levels: ["0a"] }');
		expect("requires tileset", '#m tilemap { size: 1, 1 legend { ".": g } terrain: ["."] }');
		expect("requires size", ts + '#m tilemap { tileset: t legend { ".": g } terrain: ["."] }');
		expect("a legend key is one character", ts + '#m tilemap { tileset: t size: 1, 1 legend { "..": g } terrain: ["."] }');
		expect("mark exit is outside", ts + '#m tilemap { tileset: t size: 2, 2 legend { ".": g } terrain: ["..", ".."] marks { exit: 1, 1, 2, 1 } }');
		expect("draw: is under", ts + '#m tilemap { tileset: t size: 1, 1 legend { ".": g } terrain: ["."] layer a { draw: sideways legend { "x": grass } rows: ["x"] } }');
		expect("needs autotile: or cells:", '#t tileset { tileSize: 8 atlas: "fp" terrain g { metadata { cost => 1 } } }');
		expect("needs duration:", '#t tileset { tileSize: 8 atlas: "fp" terrain w { autotile: a, b } }');
		expect("needs side: and span:", '#t tileset { tileSize: 8 atlas: "fp" edge: r terrain g { cells: "grass" } rise 1 { side: s } }');
		expect("toward: is down, up, left or right", '#t tileset { tileSize: 8 atlas: "fp" edge: r terrain g { cells: "grass" } rise 1 { side: s span: 1 toward: north } }');
		expect("a tileset with rises needs edge:", '#t tileset { tileSize: 8 atlas: "fp" terrain g { cells: "grass" } rise 1 { side: s span: 1 } }');
		expect("edge: is the tileset's", '#t tileset { tileSize: 8 atlas: "fp" edge: r terrain g { cells: "grass" } rise 1 { edge: r side: s span: 1 } }');
		expect("metadata cost is given twice", '#t tileset { tileSize: 8 atlas: "fp" terrain g { cells: "grass" metadata { cost => 1, cost => 2 } } }');
		expect("a tileset has no parameters", '#t tileset { tileSize: 8 atlas: "fp" terrain g { cells: "grass" metadata { cost:int => $$cost } } }');
		expect("expected a type after \":\"", '#t tileset { tileSize: 8 atlas: "fp" terrain g { cells: "grass" metadata { cost: 1 } } }');
		expect("draw: is under", '#t tileset { tileSize: 8 atlas: "fp" terrain g { cells: "grass" } cell roof { draw: sideways } }');
		expect("tileset requires atlas", '#t tileset { tileSize: 8 terrain g { cells: "grass" } }');
	}

	// ===== Terrains =====

	@Test
	public function testEachTerrainIsDrawnUnderTheOnesAfterIt() {
		// dirt's autotile covers the water cell too, so the water sits on dirt, not on a hole
		final withWater = build('#m tilemap { tileset: plains size: 3, 1 legend { ".": grass, "d": dirt, "~": water } terrain: ["d~."] }');
		final withGrass = build('#m tilemap { tileset: plains size: 3, 1 legend { ".": grass, "d": dirt, "~": water } terrain: ["d.."] }');
		// ground: the grass cells, then dirt, then water's two frames
		Assert.equals(6, groundGroup(withWater, 1).count(), "dirt over d and ~: 6 corners");
		Assert.equals(4, groundGroup(withGrass, 1).count(), "dirt over d alone: 4 corners");
		Assert.equals(3, groundGroup(withWater, 0).count(), "grass under every cell");
		Assert.equals("water", withWater.terrainAt(1, 0));
		Assert.isNull(withWater.terrainAt(5, 0), "outside the map");
	}

	@Test
	public function testNoneIsNoTerrain() {
		final map = build('#m tilemap { tileset: plains size: 2, 1 legend { ".": grass, " ": none } terrain: [". "] }');
		Assert.isNull(map.terrainAt(1, 0));
		Assert.isFalse(map.metadataAt(1, 0).keys().hasNext(), "no terrain, no metadata");
		Assert.equals(1, groundGroup(map, 0).count());
	}

	@Test
	public function testAnimatedTerrainSwapsItsFrames() {
		final map = build('#m tilemap { tileset: plains size: 2, 2 legend { "~": water } terrain: ["~~", "~~"] }');
		// water's two autotiles are its frames, whatever else is drawn under or over them
		final animated:Array<{frames:Array<h2d.Object>}> = @:privateAccess map.chunks[0].animated;
		Assert.equals(1, animated.length, "one animated terrain in the one chunk");
		final first = animated[0].frames[0];
		final second = animated[0].frames[1];
		Assert.isTrue(first.parent.parent.parent == @:privateAccess map.ground && second.parent == first.parent, "both frames are on the chunk's ground");
		Assert.isTrue(first.visible && !second.visible);
		@:privateAccess map.step(0.2);
		Assert.isTrue(first.visible, "not yet: 300 ms a frame");
		@:privateAccess map.step(0.15);
		Assert.isTrue(!first.visible && second.visible, "the second frame after 350 ms");
	}

	// ===== Levels =====

	static final PLATEAU = '#m tilemap {
		tileset: plains
		size: 5, 6
		legend { ".": grass }
		terrain: [".....", ".....", ".....", ".....", ".....", "....."]
		levels:  ["00000", "01110", "01110", "00000", "00000", "00000"]
		layer steps { legend { "s": stairs } rows: ["     ", "     ", "     ", "  s  ", "     ", "     "] }
	}';

	@Test
	public function testAHigherLevelGetsItsEdgeAndASideWithItsMetadata() {
		final map = build(PLATEAU);
		Assert.equals(1, map.levelAt(2, 1));
		Assert.equals(0, map.levelAt(0, 0));
		for (cx in 1...4) {
			Assert.equals(1, map.sideAt(cx, 3), 'column $cx: a side two cells long below the plateau');
			Assert.equals(1, map.sideAt(cx, 4));
			Assert.equals(0, map.sideAt(cx, 5));
		}
		Assert.equals(0, map.sideAt(0, 3), "no side beside the plateau");
		Assert.isTrue(map.metadataAt(1, 3).getBoolOrDefault("wall", false), "the rise's metadata is on the cells its side covers");
		Assert.isFalse(map.metadataAt(2, 3).getBoolOrDefault("wall", true), "the stairs' own metadata wins, laid over the side");
		Assert.isTrue(map.metadataAt(2, 3).getBoolOrDefault("climb", false));
		Assert.isFalse(map.metadataAt(2, 1).getBoolOrDefault("wall", false), "the plateau's top is not the side");
		Assert.equals(1, map.metadataAt(2, 1).getIntOrDefault("cost", 0), "and has its terrain's metadata");
	}

	/** The names a map asks its sheet for while it is drawn again, in order. **/
	static function cellsDrawn(map:TileMap):Array<String> {
		final asked:Array<String> = [];
		final tiles:TileMapTiles = @:privateAccess map.tiles;
		map.setSource(map.def, map.tileset, {
			autotile: tiles.autotile,
			autotileFormat: tiles.autotileFormat,
			frames: (sheet, name) -> {
				asked.push(name);
				return tiles.frames(sheet, name);
			},
			metadata: tiles.metadata,
		});
		map.redraw();
		return asked;
	}

	/**
		The side pieces (of `names`) drawn on the chunks' ground, in the order they were placed, read
		from the TileGroups' vertices: a tile is four of x, y, u, v, r, g, b, a. A piece of several
		frames is counted once, by its first. The map is to be drawn already.
	**/
	static function piecesDrawn(map:TileMap, names:Array<String>):Array<String> {
		final tiles:TileMapTiles = @:privateAccess map.tiles;
		final pieces = [for (n in names) {name: n, tile: tiles.frames("fp", n)[0]}];
		final drawn:Array<String> = [];
		for (ci in 0...@:privateAccess map.chunks.length) {
			for (drawnThing in groundOf(map, ci)) {
				final group = Std.downcast(drawnThing, h2d.TileGroup);
				if (group == null || group.tile == null)
					continue; // an autotile's group has no tile of its own, and no side pieces
				final texture = group.tile.getTexture();
				final buffer:hxd.FloatBuffer = @:privateAccess group.content.tmp;
				var i = 0;
				while (i + 3 < buffer.length) {
					final u = buffer[i + 2];
					final v = buffer[i + 3];
					for (p in pieces)
						if (p.tile.getTexture() == texture && @:privateAccess Math.abs(p.tile.u - u) < 1e-6 && @:privateAccess Math.abs(p.tile.v - v) < 1e-6)
							drawn.push(p.name);
					i += 32;
				}
			}
		}
		return drawn;
	}

	/** How many positions a `where` grid marks. **/
	static function positionsSet(where:Null<Array<Array<Int>>>):Int {
		if (where == null)
			return 0;
		var n = 0;
		for (row in where)
			for (v in row)
				n += v;
		return n;
	}

	/** Every autotile a map asks for while it is drawn again: its name and, when only some positions, those. **/
	static function autotilesDrawn(map:TileMap):Array<{name:String, where:Null<Array<Array<Int>>>}> {
		final asked:Array<{name:String, where:Null<Array<Array<Int>>>}> = [];
		final tiles:TileMapTiles = @:privateAccess map.tiles;
		map.setSource(map.def, map.tileset, {
			autotile: (name, grid, where, x0, y0) -> {
				asked.push({name: name, where: where});
				return tiles.autotile(name, grid, where, x0, y0);
			},
			autotileFormat: tiles.autotileFormat,
			frames: tiles.frames,
			metadata: tiles.metadata,
		});
		map.redraw();
		return asked;
	}

	@Test
	public function testASideIsDrawnWithTheEndPiecesTheRiseNames() {
		// The rise names left: only. The plateau's side is a run of three cells: its first end is the
		// left piece, its middle and its last end (no right:) the side itself.
		final plateau = piecesDrawn(build(PLATEAU), ["faceEnd", "face"]);
		Assert.equals(1, plateau.filter(n -> n == "faceEnd").length, "one left end");
		Assert.equals(2, plateau.filter(n -> n == "face").length, "the middle and the last end");
		// A side one cell wide, with no single: given, is the side itself
		final bump = piecesDrawn(build('#m tilemap { tileset: plains size: 3, 3 legend { ".": grass } terrain: ["...", "...", "..."] levels: ["000", "010", "000"] }'),
			["faceEnd", "face"]);
		Assert.equals(0, bump.filter(n -> n == "faceEnd").length);
		Assert.equals(1, bump.filter(n -> n == "face").length);
	}

	@Test
	public function testASideTowardAnotherDirection() {
		final bump = '#m tilemap {
			tileset: plains
			size: 4, 3
			legend { ".": grass }
			terrain: ["....", "....", "...."]
			levels: ["0000", "0100", "0000"]
		}';
		final downOnly = builderFromSource(source(bump)).buildTilemap("m");
		Assert.equals(1, downOnly.sideAt(1, 2), "down, the default: the side below");
		Assert.equals(0, downOnly.sideAt(2, 1), "the tileset draws no side toward the right");

		final alsoRight = builderFromSource(source(bump, 'rise 1 { side: "face" span: 1 toward: right }')).buildTilemap("m");
		Assert.equals(1, alsoRight.sideAt(1, 2));
		Assert.equals(1, alsoRight.sideAt(2, 1), "and now the side to the right too");

		Assert.equals("tilemap_rise",
			builderErrorCode(() -> builderFromSource(source(bump, 'rise 2 { side: "face" span: 1 toward: right }')).buildTilemap("m")),
			"sides toward the right, and none for a rise of 1 that way");
	}

	@Test
	public function testARiseTheTilesetHasNotIsAnError() {
		final code = builderErrorCode(() -> build('#m tilemap { tileset: plains size: 1, 2 legend { ".": grass } terrain: [".", "."] levels: ["2", "0"] }'));
		Assert.equals("tilemap_rise", code);
	}

	@Test
	public function testAnEdgeIsDrawnAlongTheRimOnly() {
		// The plateau is three cells by two: the corners around it are twelve, and the two that have
		// the plateau on every side are its inside, which the edge leaves to the terrain.
		final rim = autotilesDrawn(build(PLATEAU)).filter(a -> a.name == "rim");
		Assert.equals(1, rim.length);
		final where = rim[0].where;
		Assert.notNull(where, "the edge is drawn at some positions, not all");
		if (where != null) {
			var count = 0;
			for (row in where)
				for (v in row)
					count += v;
			Assert.equals(10, count);
			Assert.equals(1, where[1][1], "the plateau's top left corner");
			Assert.equals(0, where[2][2], "a corner with the plateau all round it");
		}
	}

	@Test
	public function testATerrainsOwnEdge() {
		// Dirt on the left of the plateau, grass on the right: each is outlined with its own edge.
		final map = builderFromSource(source('
			#rimDirt autotile { format: blob47 tileSize: 8 demo: #553311, #00000000 }
			#m tilemap {
				tileset: plains
				size: 6, 4
				legend { ".": grass, "d": dirt }
				terrain: ["......", ".dd...", ".dd...", "......"]
				levels:  ["000000", "011110", "011110", "000000"]
			}', 'edge dirt: rimDirt')).buildTilemap("m");
		final drawn = autotilesDrawn(map);
		final dirtRim = drawn.filter(a -> a.name == "rimDirt");
		Assert.equals(1, dirtRim.length);
		final where = dirtRim[0].where;
		Assert.notNull(where);
		if (where != null) {
			Assert.equals(1, where[1][1], "a dirt cell of the plateau, on its rim");
			Assert.equals(0, where[1][3], "a grass cell of it: the tileset's own edge");
		}
		Assert.equals(1, drawn.filter(a -> a.name == "rim").length, "and the grass's side of it with the tileset's edge");

		final error = parseExpectingError(source('#m tilemap { tileset: plains size: 1, 1 legend { ".": grass } terrain: ["."] }', 'edge lava: rim'));
		Assert.notNull(error);
		if (error != null) Assert.stringContains("tileset has no terrain lava", error);
	}

	@Test
	public function testARiseForAnyLevelAndATerrainsOwn() {
		final bump = '#m tilemap {
			tileset: plains
			size: 4, 6
			legend { ".": grass, "d": dirt }
			terrain: ["....", ".d..", "....", "....", "....", "...."]
			levels:  ["0000", "0320", "0000", "0000", "0000", "0000"]
		}';
		// any: every rise that has none of its own, here toward up and for 2 and 3 levels down;
		// dirt has its own rise 3, one cell long, in place of the any that grass takes.
		final map = builderFromSource(source(bump,
			'rise any { side: "face" span: 3 }  rise any { side: "roof" span: 1 toward: up }  rise 3 dirt { side: "stairs" span: 1 }')).buildTilemap("m");
		Assert.equals(3, map.sideAt(1, 0), "above the dirt cell, three levels up");
		Assert.equals(2, map.sideAt(2, 0));
		Assert.equals(3, map.sideAt(1, 2), "the dirt's own side");
		Assert.equals(0, map.sideAt(1, 3), "one cell long");
		Assert.equals(2, map.sideAt(2, 2));
		Assert.equals(2, map.sideAt(2, 4), "any, three cells long");
		Assert.equals(0, map.sideAt(2, 5));

		final dup = parseExpectingError(source(bump, 'rise any { side: "face" span: 1 }  rise any { side: "face" span: 2 }'));
		Assert.notNull(dup);
		if (dup != null) Assert.stringContains("rise any toward down is defined twice", dup);
	}

	@Test
	public function testSeveralSidesAreTakenInTurn() {
		// A run of five: its first end, then the middles in the order written, round again.
		final map = builderFromSource(source('#m tilemap {
			tileset: plains
			size: 7, 3
			legend { ".": grass }
			terrain: [".......", ".......", "......."]
			levels:  ["0222220", "0000000", "0000000"]
		}', 'rise 2 { side: "stairs", "flower", "roof" left: "faceEnd" span: 1 }')).buildTilemap("m");
		map.redraw();
		Assert.same(["faceEnd", "stairs", "flower", "roof", "stairs"], piecesDrawn(map, ["stairs", "flower", "roof", "faceEnd"]));
	}

	@Test
	public function testAPlatformIsDrawnOverTheGroundWithItsOwnSides() {
		final src = '
			#top autotile { format: blob47 tileSize: 8 demo: #224422, #446644 }
			#m tilemap {
				tileset: plains
				size: 5, 6
				legend { ".": grass }
				terrain: [".....", ".....", ".....", ".....", ".....", "....."]
				levels { legend { "c": 1 canopy } rows: ["00000", "0ccc0", "0ccc0", "00000", "00000", "00000"] }
			}';
		final map = builderFromSource(source(src, 'platform canopy { edge: top  rise 1 { side: "roof" span: 1 } }')).buildTilemap("m");
		Assert.equals("canopy", map.platformAt(2, 1));
		Assert.isNull(map.platformAt(0, 0));
		Assert.equals(1, map.levelAt(2, 1));
		Assert.equals("grass", map.terrainAt(2, 1), "the ground under it is the map's");
		final drawn = autotilesDrawn(map);
		final tops = drawn.filter(a -> a.name == "top");
		Assert.equals(1, tops.length);
		Assert.equals(6, positionsSet(tops[0].where), "its top is drawn over all of it, inside and rim: every one of its 3 by 2 cells (a cell-format autotile)");
		Assert.equals(0, drawn.filter(a -> a.name == "rim").length, "the ground's edge is not its outline");
		Assert.equals(1, map.sideAt(2, 3), "its own side, one cell long");
		Assert.equals(0, map.sideAt(2, 4), "not the ground's, two cells long");
		Assert.same({c: "canopy"}, map.describe().levelPlatforms);

		// A platform with no side that way is drawn without one, not with the ground's
		final bare = builderFromSource(source(src, 'platform canopy { edge: top }')).buildTilemap("m");
		Assert.equals(0, bare.sideAt(2, 3));

		Assert.equals("tilemap_platform", builderErrorCode(() -> builderFromSource(source(src)).buildTilemap("m")),
			"the map names a platform the tileset has not");
		final empty = parseExpectingError(source(src, 'platform canopy { }'));
		Assert.notNull(empty);
		if (empty != null) Assert.stringContains("platform canopy needs edge:", empty);
		final terrained = parseExpectingError(source(src, 'platform canopy { edge: top  rise 1 dirt { side: "roof" span: 1 } }'));
		Assert.notNull(terrained);
		if (terrained != null) Assert.stringContains("a platform\'s rise is its own", terrained);
	}

	@Test
	public function testMetadataTypes() {
		final map = build('#m tilemap { tileset: plains size: 3, 1 legend { ".": grass, "d": dirt, "~": water } terrain: [".d~"] }');
		Assert.equals(3.5, map.metadataAt(2, 0).getFloatOrDefault("cost", 0));
		Assert.isTrue(map.metadataAt(2, 0).getBoolOrDefault("swim", false));
		Assert.equals("muddy", map.metadataAt(1, 0).getStringOrDefault("look", ""));
		Assert.equals("2", map.metadataAt(1, 0).getStringOrDefault("cost", ""), "a number read as a string");
		Assert.equals("nothing", map.metadataAt(0, 0).getStringOrDefault("look", "nothing"));
		Assert.equals(2, map.metadataAt(1, 0).getIntOrDefault("cost", 0));
		Assert.isFalse(map.metadataAt(9, 9).has("cost"), "outside the map");
	}

	// ===== Layers, decor, actors =====

	@Test
	public function testLayersAreDrawnWhereTheySay() {
		final map = build('#m tilemap {
			tileset: plains
			size: 3, 1
			legend { ".": grass }
			terrain: ["..."]
			layer deco { legend { "f": flower, "r": roof } rows: ["fr "] }
			layer glow { draw: top legend { "f": flower } rows: ["  f"] }
		}');
		Assert.equals("flower", map.cellAt("deco", 0, 0));
		Assert.isNull(map.cellAt("deco", 2, 0), "a space is no cell");
		final over:h2d.Object = @:privateAccess map.overLayer;
		final top:h2d.Object = @:privateAccess map.topLayer;
		Assert.equals(1, drawnIn(over), "the roof, whose cell says draw: over, above the actors");
		Assert.equals(1, drawnIn(top), "the glow layer, draw: top");
		Assert.isTrue(map.getChildIndex(top) > map.getChildIndex(map.actors), "top above the actors");
	}

	@Test
	public function testDecorAndActorsAreSortedByTheirFeet() {
		final map = build('#m tilemap {
			tileset: plains
			size: 4, 4
			legend { ".": grass }
			terrain: ["....", "....", "....", "...."]
			decor { bitmap(generated(color(4, 8, #CC3333))): 10, 20 }
		}');
		Assert.equals(1, map.actors.numChildren, "the decor is among the actors");
		final a = new h2d.Object();
		a.y = 30;
		final b = new h2d.Object();
		b.y = 5;
		map.addActor(a);
		map.addActor(b);
		@:privateAccess map.step(0);
		Assert.equals(0, map.actors.getChildIndex(b), "the one further up is drawn first");
		Assert.isTrue(map.actors.getChildIndex(a) > map.actors.getChildIndex(b));
		b.y = 40;
		@:privateAccess map.step(0);
		Assert.isTrue(map.actors.getChildIndex(b) > map.actors.getChildIndex(a), "passing each other swaps them");

		map.sortActors = false;
		b.y = 0;
		@:privateAccess map.step(0);
		Assert.isTrue(map.actors.getChildIndex(b) > map.actors.getChildIndex(a), "not sorted: the order stays as it was");
	}

	@Test
	public function testMarksAndTheShapeTheDevBridgeIsGiven() {
		final map = build('#m tilemap {
			tileset: plains
			size: 4, 3
			legend { ".": grass, "d": dirt }
			terrain: ["....", ".dd.", "...."]
			marks { spawn: 0, 0  exit: 1, 1, 3, 2 }
		}');
		Assert.equals(3, map.mark("exit").w);
		Assert.isNull(map.mark("spawn").w, "a point");
		final d:Dynamic = map.describe();
		Assert.equals("m", d.name);
		Assert.same(["....", ".dd.", "...."], d.terrain);
		Assert.equals(2, (d.marks : Array<Dynamic>).length);
	}

	// ===== Changes while running, and a reload =====

	@Test
	public function testChangesRedrawAndLeaveTheFileAlone() {
		final builder = builderFromSource(source('#m tilemap { tileset: plains size: 3, 3 legend { ".": grass, "d": dirt } terrain: ["...", "...", "..."] }'));
		final map = builder.buildTilemap("m");
		map.setTerrain(1, 1, "d");
		Assert.equals("dirt", map.terrainAt(1, 1));
		map.setLevel(1, 0, 1);
		Assert.equals(1, map.levelAt(1, 0));
		Assert.equals(1, map.sideAt(1, 1), "a level painted higher grows a side");
		Assert.raises(() -> map.setTerrain(0, 0, "x"));
		final fresh = builder.buildTilemap("m");
		Assert.equals("grass", fresh.terrainAt(1, 1), "the parse is untouched: a new map is as written");
	}

	@Test
	public function testAReloadRedrawsAndKeepsTheActors() {
		final map = build('#m tilemap { tileset: plains size: 2, 1 legend { ".": grass, "d": dirt } terrain: [".."] }');
		final actor = new h2d.Object();
		map.addActor(actor);
		final newer = builderFromSource(source('#m tilemap { tileset: plains size: 2, 1 legend { ".": grass, "d": dirt } terrain: ["d."] }'));
		TileMap.showing.push(map);
		TileMap.builderReplaced(map.sourceName, newer.refreshTilemap);
		TileMap.showing.remove(map);
		Assert.equals("dirt", map.terrainAt(0, 0), "the new rows");
		Assert.isTrue(actor.parent == map.actors, "the actor stays");
	}

	@Test
	public function testSetLevelRaisesTheGroundNotAPlatform() {
		final map = builderFromSource(source('
			#top autotile { format: blob47 tileSize: 8 demo: #224422, #446644 }
			#m tilemap {
				tileset: plains
				size: 3, 1
				legend { ".": grass }
				terrain: ["..."]
				levels { legend { "c": 1 canopy, "R": 12 canopy } rows: ["0c0"] }
			}', 'platform canopy { edge: top  rise 1 { side: "roof" span: 1 } }')).buildTilemap("m");
		map.setLevel(0, 0, 1);
		Assert.equals(1, map.levelAt(0, 0));
		Assert.isNull(map.platformAt(0, 0), "the ground raised, not a canopy");
		Assert.equals("1c0", map.def.levels[0], "a digit, though the legend has a platform at that level");
		Assert.equals("canopy", map.platformAt(1, 0), "the canopy there stays");
		Assert.equals("tilemap_level", builderErrorCode(() -> map.setLevel(2, 0, 12)), "a platform's character does not stand for the ground at that level");
	}

	@Test
	public function testAChangeOutsideTheMapIsAnError() {
		final map = build('#m tilemap {
			tileset: plains
			size: 3, 2
			legend { ".": grass, "d": dirt }
			terrain: ["...", "..."]
			layer deco { legend { "s": stairs } rows: ["   ", "   "] }
		}');
		Assert.equals("tilemap_outside", builderErrorCode(() -> map.setTerrain(0, 2, "d")));
		Assert.equals("tilemap_outside", builderErrorCode(() -> map.setTerrain(3, 0, "d")));
		Assert.equals("tilemap_outside", builderErrorCode(() -> map.setTerrain(-1, 0, "d")));
		Assert.equals("tilemap_outside", builderErrorCode(() -> map.setLevel(0, 2, 1)));
		Assert.equals("tilemap_outside", builderErrorCode(() -> map.setCell("deco", 3, 0, "s")));
		Assert.equals("...", map.def.terrain[0], "nothing written");
		Assert.equals("tilemap_legend", builderErrorCode(() -> map.setTerrain(0, 0, "x")));
		Assert.equals("tilemap_legend", builderErrorCode(() -> map.setCell("deco", 0, 0, "x")));
		Assert.equals("tilemap_layer", builderErrorCode(() -> map.setCell("none", 0, 0, "s")));
		Assert.equals("grass", map.terrainAt(0, 0), "the map is as it was");
	}

	@Test
	public function testSeveralChangesAreDrawnOnce() {
		final map = build('#m tilemap { tileset: plains size: 3, 3 legend { ".": grass, "d": dirt } terrain: ["...", "...", "..."] }');
		final drawn = groundGroup(map, 0);
		map.setTerrain(0, 0, "d");
		map.setTerrain(1, 0, "d");
		map.setLevel(2, 0, 1);
		Assert.isTrue(drawn == groundGroup(map, 0), "not drawn again for each change");
		Assert.equals("dirt", map.terrainAt(1, 0), "the rows say what is where at once");
		Assert.isTrue(drawn == groundGroup(map, 0), "and reading them draws nothing");
		Assert.equals(1, map.sideAt(2, 1), "asked what a cell is, the map works it out: the side of the level raised");
		Assert.equals(2, map.metadataAt(1, 0).getIntOrDefault("cost", 0), "the dirt's metadata");
		Assert.isTrue(drawn == groundGroup(map, 0), "without drawing anything");
		map.redraw();
		Assert.isFalse(drawn == groundGroup(map, 0), "drawn again once, for every change");
		final again = groundGroup(map, 0);
		Assert.equals(1, map.sideAt(2, 1), "the same side");
		Assert.isTrue(again == groundGroup(map, 0), "and not drawn again while nothing changes");
	}

	@Test
	public function testARefreshFromTheSameParseLeavesTheMapAlone() {
		final builder = builderFromSource(source('#m tilemap { tileset: plains size: 2, 1 legend { ".": grass, "d": dirt } terrain: [".."] }'));
		final map = builder.buildTilemap("m");
		map.setTerrain(0, 0, "d");
		builder.refreshTilemap(map);
		Assert.equals("dirt", map.terrainAt(0, 0), "the file has not changed: nothing to read again");
	}

	// ===== The builder's checks =====

	@Test
	public function testNamesTheTilesetHasNotAreErrors() {
		Assert.equals("tilemap_terrain",
			builderErrorCode(() -> build('#m tilemap { tileset: plains size: 1, 1 legend { ".": lava } terrain: ["."] }')));
		Assert.equals("tilemap_missing_cell",
			builderErrorCode(() -> build('#m tilemap { tileset: plains size: 1, 1 legend { ".": grass } terrain: ["."] layer x { legend { "a": nope } rows: ["a"] } }')));
		Assert.equals("tilemap_sheet",
			builderErrorCode(() -> build('#m tilemap { tileset: plains size: 1, 1 legend { ".": grass } terrain: ["."] layer x { sheet: "nosheet" legend { "a": grass } rows: ["a"] } }')),
			"a layer's own sheet is loaded, and one that cannot be is said so, not taken for a missing cell");
		try {
			build('#m tilemap { tileset: plains size: 1, 1 legend { ".": grass } terrain: ["."] layer x { sheet: "nosheet" legend { "a": grass } rows: ["a"] } }');
			Assert.fail("a sheet that cannot be loaded");
		} catch (e:BuilderError) {
			Assert.stringContains("sheet nosheet cannot be loaded", e.toString());
		}
		Assert.equals("missing_ref", builderErrorCode(() -> build('#m tilemap { tileset: nowhere size: 1, 1 legend { ".": grass } terrain: ["."] }')));
	}

	// ===== Levels beyond nine =====

	@Test
	public function testLevelsBeyondNineHaveALegend() {
		// a tileset without rises, so any difference between levels is allowed
		final map = builderFromSource(source('
			#flat tileset { tileSize: 8 atlas: "fp" terrain g { cells: "grass" } }
			#m tilemap {
				tileset: flat
				size: 3, 2
				legend { ".": g }
				terrain: ["...", "..."]
				levels { legend { "A": 10, "B": 12 } rows: ["0AB", "900"] }
			}
		')).buildTilemap("m");
		Assert.equals(10, map.levelAt(1, 0));
		Assert.equals(12, map.levelAt(2, 0));
		Assert.equals(9, map.levelAt(0, 1), "a digit is itself");
		map.setLevel(0, 0, 12);
		Assert.equals(12, map.levelAt(0, 0));
		Assert.equals("BAB", map.def.levels[0], "set through the legend's character");
		map.setLevel(0, 0, 3);
		Assert.equals("3AB", map.def.levels[0], "a digit stays a digit");
		Assert.raises(() -> map.setLevel(0, 0, 11)); // no character stands for 11
		final d:Dynamic = map.describe();
		Assert.equals(10, Reflect.field(d.levelLegend, "A"));
	}

	@Test
	public function testLevelsLegendErrors() {
		final ts = '#t tileset { tileSize: 8 atlas: "fp" terrain g { cells: "grass" } }\n';
		final head = ts + '#m tilemap { tileset: t size: 2, 1 legend { ".": g } terrain: [".."] ';
		Assert.stringContains("is not a level", parseExpectingError(head + 'levels: ["0A"] }'));
		Assert.stringContains("a digit is its own level", parseExpectingError(head + 'levels { legend { "5": 1 } rows: ["00"] } }'));
		Assert.stringContains("a level is 0 or more", parseExpectingError(head + 'levels { legend { "A": -1 } rows: ["00"] } }'));
		Assert.stringContains("in the levels legend twice", parseExpectingError(head + 'levels { legend { "A": 1, "A": 2 } rows: ["00"] } }'));
		Assert.stringContains("unexpected levels property", parseExpectingError(head + 'levels { rows: ["00"] draw: top } }'));
		// a rise beyond nine is a rise like any other
		final steep = ts.split("terrain g { cells: \"grass\" }").join('edge: rim terrain g { cells: "grass" } rise 10 { side: "face" span: 1 }');
		final map = builderFromSource(source(steep + '#m tilemap { tileset: t size: 1, 2 legend { ".": g } terrain: [".", "."] levels { legend { "A": 10 } rows: ["A", "0"] } }')).buildTilemap("m");
		Assert.equals(10, map.sideAt(0, 1), "a side of the rise of ten below the cell");
	}

	// ===== Transitions between two terrains =====

	static final SHORES = '
		#shore autotile { format: corner tileSize: 8 demo: #FFFF00, #FFFF00 }
		#shoreB autotile { format: corner tileSize: 8 demo: #FFFF00, #FFFF00 }
	';

	@Test
	public function testATransitionIsDrawnWhereTheTwoTerrainsMeetAndNothingElse() {
		// water (two frames) with a transition from grass: its shore is drawn over its own autotile
		// at the corners whose cells are some water (or a terrain above it) and otherwise grass only
		final map = builderFromSource(source(SHORES
			+ '#m tilemap { tileset: plains size: 4, 3 legend { ".": grass, "d": dirt, "~": water } terrain: ["....", ".~~d", "...."] }',
			'transition grass, water { autotile: shore, shoreB }')).buildTilemap("m");
		final drawn = autotilesDrawn(map);
		Assert.same(["dirt", "water", "shore", "waterB", "shoreB"], [for (a in drawn) a.name], "own first, then the transition, a frame each");
		final where = drawn[2].where;
		Assert.notNull(where, "the shore is drawn at some positions only");
		Assert.equals(6, positionsSet(drawn[1].where), "the terrain's own at every corner around its two cells: 3 by 2");
		// corners are 5 x 4; corner (cx, cy) is the top-left of cell (cx, cy)
		Assert.equals(1, where[1][1], "grass and the first water cell");
		Assert.equals(1, where[1][2], "grass above two water cells");
		Assert.equals(1, where[2][1], "grass below the first water cell");
		Assert.equals(1, where[2][2], "grass below two water cells");
		Assert.equals(0, where[1][3], "dirt is below water in the tileset, so a corner with dirt is not grass alone");
		Assert.equals(0, where[1][4], "dirt against grass and the map's edge: no water at all");
		Assert.equals(0, where[0][0], "all grass");
		var count = 0;
		for (row in where)
			for (v in row)
				count += v;
		Assert.equals(4, count, "the four corners where the water meets grass only");
	}

	@Test
	public function testATransitionFromNoneIsTheMapsEdge() {
		// a cell-format autotile: positions are cells. The water cell is alone on the map, so every
		// neighbour is the edge: the transition from none draws it
		final map = builderFromSource(source('
			#rim13 autotile { format: cross tileSize: 8 demo: #FFFF00, #FFFF00 }
			#rim13B autotile { format: cross tileSize: 8 demo: #FFFF00, #FFFF00 }
			#m tilemap { tileset: plains size: 2, 1 legend { ".": grass, "~": water } terrain: ["~~"] }
		', 'transition none, water { autotile: rim13, rim13B }')).buildTilemap("m");
		final shore = autotilesDrawn(map).filter(a -> a.name == "rim13");
		Assert.equals(1, shore.length);
		Assert.same([[1, 1]], shore[0].where, "both water cells touch only the edge");
		final mixed = builderFromSource(source('
			#rim13 autotile { format: cross tileSize: 8 demo: #FFFF00, #FFFF00 }
			#rim13B autotile { format: cross tileSize: 8 demo: #FFFF00, #FFFF00 }
			#m tilemap { tileset: plains size: 2, 1 legend { ".": grass, "~": water } terrain: ["~."] }
		', 'transition none, water { autotile: rim13, rim13B }')).buildTilemap("m");
		Assert.equals(0, autotilesDrawn(mixed).filter(a -> a.name == "rim13").length, "water against the edge and grass: neither pair alone, no transition drawn");
	}

	@Test
	public function testTransitionErrors() {
		function expect(fragment:String, tilesetExtra:String, ?pos:haxe.PosInfos) {
			final error = parseExpectingError(source(SHORES + '#m tilemap { tileset: plains size: 1, 1 legend { ".": grass } terrain: ["."] }', tilesetExtra));
			Assert.notNull(error, 'expected an error with "$fragment"', pos);
			if (error != null) Assert.stringContains(fragment, error, pos);
		}
		expect("has no terrain lava", 'transition grass, lava { autotile: shore, shoreB }');
		expect("has no terrain mud (or none)", 'transition mud, water { autotile: shore, shoreB }');
		expect("drawn over", 'transition water, dirt { autotile: shore }');
		expect("drawn from cells:", 'transition none, grass { autotile: shore }');
		expect("2 autotile(s) for terrain dirt, which has 1", 'transition grass, dirt { autotile: shore, shoreB }');
		expect("is defined twice", 'transition grass, water { autotile: shore, shoreB } transition grass, water { autotile: shore, shoreB }');
		expect("needs autotile:", 'transition grass, water { }');
		expect("a transition has autotile: only", 'transition grass, water { duration: 3 }');
		Assert.equals("missing_ref",
			builderErrorCode(() -> builderFromSource(source('#m tilemap { tileset: plains size: 1, 1 legend { ".": grass } terrain: ["."] }',
				'transition grass, water { autotile: nope, nope2 }')).buildTilemap("m")),
			"an autotile the file has not is said at build time, before anything is drawn");
	}

	// ===== Objects of several cells =====

	@Test
	public function testAnObjectOfSeveralCellsStandsAmongTheActorsOnItsAnchor() {
		final map = builderFromSource(source('#m tilemap {
			tileset: plains
			size: 5, 3
			legend { ".": grass }
			terrain: [".....", ".....", "....."]
			layer props { legend { "t": tree } rows: ["     ", " t   ", "     "] }
		}', 'cell tree { size: 2, 2 metadata { wall:bool => true } }')).buildTilemap("m");
		map.redraw();
		// the character is at (1, 1), the tree's anchor is its bottom-left cell: its image covers (1, 0) to (2, 1)
		final objects:Array<h2d.Object> = @:privateAccess map.chunks[0].objects;
		Assert.equals(1, objects.length);
		final tree = objects[0];
		Assert.isTrue(tree.parent == map.actors, "among the actors");
		Assert.floatEquals(8, tree.x);
		Assert.floatEquals(16, tree.y, "its y is its feet, the bottom of its image, which sorts it");
		Assert.equals("tree", map.cellAt("props", 1, 1));
		Assert.equals("tree", map.cellAt("props", 2, 0), "every cell it covers is it");
		Assert.isNull(map.cellAt("props", 0, 0));
		Assert.isTrue(map.metadataAt(1, 1).getBoolOrDefault("wall", false), "its metadata is on its anchor cell");
		Assert.isTrue(map.metadataAt(2, 0).getBoolOrDefault("wall", false), "and on every cell it covers");
		Assert.isFalse(map.metadataAt(0, 0).getBoolOrDefault("wall", false));
		map.setCell("props", 3, 2, "t"); // covers (3, 1) to (4, 2)
		map.redraw();
		Assert.equals(2, (@:privateAccess map.chunks[0].objects : Array<h2d.Object>).length, "drawn again: the old sprite gone, two now");
		Assert.isNull(tree.parent, "the first draw's sprite was removed");
	}

	@Test
	public function testAnObjectIsPlacedAndRemovedAtItsAnchorAndCoversNoOther() {
		final was = TileMap.defaultChunkSize;
		TileMap.defaultChunkSize = 2;
		final src = source('#m tilemap {
			tileset: plains
			size: 4, 3
			legend { ".": grass }
			terrain: ["....", "....", "...."]
			layer props { legend { "t": tree, "f": flower } rows: ["    ", " t  ", "f   "] }
		}', 'cell tree { size: 2, 2 metadata { wall:bool => true } }');
		final map = try builderFromSource(src).buildTilemap("m") catch (e:Dynamic) {
			TileMap.defaultChunkSize = was;
			throw e;
		}
		TileMap.defaultChunkSize = was;
		// the tree at (1, 1) covers (1, 0) to (2, 1), across the border of two chunks of 2 cells
		final tree = map.objectAt("props", 2, 0);
		Assert.notNull(tree);
		Assert.same({name: "tree", anchorX: 1, anchorY: 1, x: 1, y: 0, width: 2, height: 2}, tree, "a covered cell says the object and where its anchor is");
		Assert.same({name: "flower", anchorX: 0, anchorY: 2, x: 0, y: 2, width: 1, height: 1}, map.objectAt("props", 0, 2), "a cell of one is itself");
		Assert.isNull(map.objectAt("props", 3, 0));
		Assert.isTrue(map.metadataAt(2, 0).getBoolOrDefault("wall", false), "its metadata in the other chunk too");
		Assert.equals("tilemap_object_covered", builderErrorCode(() -> map.setCell("props", 2, 0, " ")), "a covered cell is changed at the anchor");
		Assert.equals("tree", map.cellAt("props", 2, 0), "nothing changed");
		map.setCell("props", 1, 1, " ");
		Assert.isNull(map.cellAt("props", 2, 0), "removed at its anchor, its cells are free");
		Assert.isFalse(map.metadataAt(2, 0).getBoolOrDefault("wall", false), "and the other chunk is drawn again without it");
		Assert.equals("tilemap_object_outside", builderErrorCode(() -> map.setCell("props", 3, 2, "t")), "a tree at the right edge would cover column 4");
		Assert.isNull(map.cellAt("props", 3, 2), "nothing changed");
		Assert.equals("   ", map.def.layers[0].rows[2].substr(1), "the rows neither");
		map.setCell("props", 2, 2, "t"); // covers (2, 1) to (3, 2)
		Assert.equals("tilemap_object_overlap", builderErrorCode(() -> map.setCell("props", 1, 2, "t")), "a tree at (1, 2) would cover (2, 1), the other tree's");
		Assert.equals("tree", map.cellAt("props", 2, 1), "the one there stays");
		Assert.isNull(map.cellAt("props", 1, 1), "the other was not placed");
		Assert.equals("tilemap_object_covered", builderErrorCode(() -> map.setCell("props", 3, 1, "f")), "nor is a flower placed on a cell it covers");
		map.setCell("props", 1, 2, "f");
		Assert.equals("flower", map.cellAt("props", 1, 2), "beside it, a flower is");
		// the same checks when the rows are read
		Assert.equals("tilemap_object_overlap", builderErrorCode(() -> builderFromSource(source('#m tilemap { tileset: plains size: 4, 3 legend { ".": grass }
			terrain: ["....", "....", "...."] layer props { legend { "t": tree } rows: ["    ", " tt ", "    "] } }', 'cell tree { size: 2, 2 }')).buildTilemap("m")));
		Assert.equals("tilemap_object_outside", builderErrorCode(() -> builderFromSource(source('#m tilemap { tileset: plains size: 4, 3 legend { ".": grass }
			terrain: ["....", "....", "...."] layer props { legend { "t": tree } rows: ["t   ", "    ", "    "] } }', 'cell tree { size: 2, 2 }')).buildTilemap("m")),
			"a tree on the top row would cover row -1");
	}

	@Test
	public function testAnObjectMayBeDrawnWithTheLayerInstead() {
		final map = builderFromSource(source('#m tilemap {
			tileset: plains
			size: 4, 3
			legend { ".": grass }
			terrain: ["....", "....", "...."]
			layer props { legend { "t": tree } rows: ["    ", "  t ", "    "] }
		}', 'cell tree { size: 2, 2 anchor: 1, 0 draw: over }')).buildTilemap("m");
		map.redraw();
		Assert.equals(0, (@:privateAccess map.chunks[0].objects : Array<h2d.Object>).length);
		final over:h2d.Object = @:privateAccess map.overLayer;
		Assert.equals(1, drawnIn(over), "one group over the actors, in the chunk");
		Assert.equals("tree", map.cellAt("props", 2, 1));
	}

	@Test
	public function testObjectErrors() {
		final head = '#m tilemap { tileset: plains size: 2, 2 legend { ".": grass } terrain: ["..", ".."] layer p { legend { "f": flower } rows: ["f ", "  "] } }';
		Assert.equals("tilemap_cell_size", builderErrorCode(() -> builderFromSource(source(head, 'cell flower { size: 2, 2 }')).buildTilemap("m")),
			"a cell of two by two is drawn 16x16, the flower is 8x8");
		Assert.stringContains("anchor 2, 0 is outside", parseExpectingError(source(head, 'cell tree { size: 2, 2 anchor: 2, 0 }')));
		Assert.stringContains("anchor: is for a cell with a size:", parseExpectingError(source(head, 'cell tree { anchor: 0, 0 }')));
		Assert.stringContains("or actors", parseExpectingError(source(head, 'cell tree { draw: sideways }')));
	}

	// ===== Chunks and culling =====

	/** A 10 by 6 map in chunks of 4 cells: 3 by 2 chunks, the last column and row short; drawn whole unless `undrawn`. **/
	static function chunked(?rows:String = "", ?extraTileset:String = "", ?undrawn:Bool = false):TileMap {
		final was = TileMap.defaultChunkSize;
		TileMap.defaultChunkSize = 4;
		try {
			final map = builderFromSource(source('#m tilemap { tileset: plains size: 10, 6 legend { ".": grass, "d": dirt } terrain: ["..........", "..........", "..........", "..........", "..........", ".........."] $rows }',
				extraTileset)).buildTilemap("m");
			TileMap.defaultChunkSize = was;
			if (!undrawn)
				map.redraw();
			return map;
		} catch (e:Dynamic) {
			TileMap.defaultChunkSize = was;
			throw e;
		}
	}

	/** Records which autotiles a map asks for from now on, without drawing it again first. **/
	static function recordAutotiles(map:TileMap):Array<String> {
		final asked:Array<String> = [];
		final tiles:TileMapTiles = @:privateAccess map.tiles;
		@:privateAccess map.tiles = {
			autotile: (name, grid, where, x0, y0) -> {
				asked.push(name);
				return tiles.autotile(name, grid, where, x0, y0);
			},
			autotileFormat: tiles.autotileFormat,
			frames: tiles.frames,
			metadata: tiles.metadata,
		};
		return asked;
	}

	@Test
	public function testAChangeIsDrawnAgainInItsChunkOnly() {
		final map = chunked();
		Assert.equals(3, map.chunkCols);
		Assert.equals(2, map.chunkRows);
		Assert.equals(4, map.chunkSize);
		final asked = recordAutotiles(map);
		map.setTerrain(1, 1, "d");
		Assert.equals(0, asked.length, "nothing drawn until the chunk is seen or asked what it draws");
		Assert.equals("dirt", map.terrainAt(1, 1), "the rows say the terrain");
		Assert.equals(0, asked.length, "without a draw");
		Assert.equals(0, map.sideAt(1, 1), "nor does asking what a cell is");
		Assert.equals(0, asked.length);
		@:privateAccess map.drawDirty(false);
		Assert.same(["dirt"], asked, "drawn: the chunk the cell is in, once, and no other");
		asked.resize(0);
		map.setTerrain(3, 1, "d");
		@:privateAccess map.drawDirty(false);
		Assert.equals(2, asked.length, "a cell at a chunk's border: its chunk and the neighbour the autotile's corners reach into");
		asked.resize(0);
		map.setTerrain(9, 5, "d");
		@:privateAccess map.drawDirty(false);
		Assert.equals(1, asked.length, "the last chunk, short, drawn on its own");
		Assert.equals("dirt", map.terrainAt(9, 5));
	}

	@Test
	public function testATerrainChangeReachesAsFarAsTheSidesItsRiseDraws() {
		// A rise of the dirt's own, two cells long toward the right: a cell two columns before a
		// chunk border turned to dirt changes the side piece in the next chunk
		final map = chunked('levels: ["0000000000", "0010000000", "0000000000", "0000000000", "0000000000", "0000000000"]',
			'rise 1 { side: "face" span: 2 toward: right }  rise 1 dirt { side: "stairs" span: 2 toward: right metadata { stairs:bool => true } }');
		Assert.equals(1, map.sideAt(4, 1), "the side's second cell, in the second chunk");
		Assert.isFalse(map.metadataAt(4, 1).getBoolOrDefault("stairs", false), "the grass's rise");
		map.setTerrain(2, 1, "d");
		Assert.isTrue(map.metadataAt(4, 1).getBoolOrDefault("stairs", false), "the dirt's rise now, drawn again in the next chunk too");
	}

	@Test
	public function testSidesTakenInTurnAreNumberedFromTheRunsStartAcrossChunks() {
		// A plateau's side across every chunk, of two pieces in turn: the run shortened at its start
		// turns every piece after it, in every chunk along the run
		final map = chunked('levels: ["0000000000", "2222222222", "0000000000", "0000000000", "0000000000", "0000000000"]',
			'rise 2 { side: "stairs", "flower" span: 1 }');
		map.setLevel(0, 1, 0);
		@:privateAccess map.drawDirty(false);
		Assert.same(["stairs", "flower", "stairs", "flower", "stairs", "flower", "stairs", "flower", "stairs"], piecesDrawn(map, ["stairs", "flower"]),
			"the run of nine from column 1, chunk by chunk: the pieces in turn from its start");
	}

	@Test
	public function testAChunkOutOfViewIsNotDrawnUntilSeenOrAsked() {
		final map = chunked("", "", true);
		inline function dirty(i:Int):Bool
			return @:privateAccess map.chunks[i].dirty;
		inline function drawn(i:Int):Int
			return groundOf(map, i).length;
		Assert.isTrue(dirty(0) && dirty(5), "nothing drawn as the map is built");
		Assert.equals("grass", map.terrainAt(9, 5), "the rows are read without a draw");
		Assert.isTrue(dirty(5));
		map.cull(0, 0, 10, 10);
		@:privateAccess map.drawDirty(true); // as sync does, with the view
		Assert.isFalse(dirty(0), "the chunk in view is drawn");
		Assert.isTrue(drawn(0) > 0);
		Assert.isTrue(dirty(5), "the chunk out of view is not");
		Assert.equals(0, drawn(5));
		Assert.equals(0, map.sideAt(9, 5));
		Assert.isTrue(dirty(5), "asked what a cell is, the chunk is worked out, not drawn");
		Assert.equals(0, drawn(5));
		map.cullNone();
		@:privateAccess map.drawDirty(true);
		Assert.isFalse(dirty(2) || dirty(5), "in view now, drawn");
		Assert.isTrue(drawn(5) > 0);
	}

	/** How many tiles the index-th group on the ground of a chunk draws. **/
	static function groundGroupCount(map:TileMap, chunk:Int, index:Int):Int {
		final group:h2d.TileGroup = cast groundOf(map, chunk)[index];
		return group.count();
	}

	@Test
	public function testChunksAreDrawnWhereTheyAreAndTheMapReadsTheSame() {
		final map = chunked('levels: ["0000000000", "0001111000", "0001111000", "0000000000", "0000000000", "0000000000"]');
		Assert.equals(16, groundGroupCount(map, 0, 0), "the first chunk's grass, 4 by 4 cells");
		Assert.equals(8, groundGroupCount(map, 2, 0), "the last column of chunks is 2 cells wide: 2 by 4");
		Assert.equals(4, groundGroupCount(map, 5, 0), "the last chunk, 2 by 2");
		for (cx in 3...7) {
			Assert.equals(1, map.sideAt(cx, 3), 'column $cx: the plateau\'s side, across a chunk border');
			Assert.equals(1, map.sideAt(cx, 4));
		}
		Assert.equals(0, map.sideAt(2, 3));
		// a bigger chunk draws the same map
		map.setChunkSize(32);
		Assert.equals(1, map.chunkCols);
		Assert.equals(1, map.sideAt(5, 4));
		map.redraw();
		Assert.equals(60, groundGroupCount(map, 0, 0), "all the grass in one chunk");
	}

	@Test
	public function testRedrawDrawsAMapDrawnAlready() {
		// redraw() draws everything again now, also when every chunk is drawn already and nothing
		// changed since; and leaves no chunk waiting to be drawn, which the next change would draw too.
		final map = chunked('levels: ["0000000000", "0110000000", "0000000000", "0000000000", "0000000000", "0000000000"]');
		final asked = recordAutotiles(map);
		map.redraw();
		Assert.isTrue(asked.length > 0, "the plateau's rim drawn again, now");
		var waiting = 0;
		for (c in @:privateAccess map.chunks)
			if (c.dirty)
				waiting++;
		Assert.equals(0, waiting, "no chunk left dirty");
	}

	@Test
	public function testAnimatedTerrainsKeepOneClockAcrossChunks() {
		final was = TileMap.defaultChunkSize;
		TileMap.defaultChunkSize = 1;
		final map = try build('#m tilemap { tileset: plains size: 2, 1 legend { "~": water } terrain: ["~~"] }') catch (e:Dynamic) {
			TileMap.defaultChunkSize = was;
			throw e;
		}
		TileMap.defaultChunkSize = was;
		@:privateAccess map.step(0.35);
		final frames0:Array<h2d.Object> = @:privateAccess map.chunks[0].animated[0].frames;
		Assert.isTrue(!frames0[0].visible && frames0[1].visible, "after 350 ms the second frame, in every chunk");
		map.setTerrain(1, 0, "~");
		@:privateAccess map.drawDirty(false);
		final frames1:Array<h2d.Object> = @:privateAccess map.chunks[1].animated[0].frames;
		Assert.isTrue(!frames1[0].visible && frames1[1].visible, "a chunk drawn again starts at the clock's frame, not the first");
	}

	@Test
	public function testCullingHidesTheChunksOutOfView() {
		final map = chunked('layer roofs { legend { "r": roof } rows: [${rows("          ", 5)}, "         r"] }');
		map.cull(0, 0, 10, 10); // a chunk is 4 cells of 8px: 32px
		Assert.isTrue(map.isChunkVisible(0, 0));
		Assert.isFalse(map.isChunkVisible(2, 1), "the far chunk is out of view");
		Assert.isFalse(map.isChunkVisible(1, 0));
		map.cull(30, 0, 10, 10);
		Assert.isTrue(map.isChunkVisible(0, 0), "a corner autotile reaches a tile past its chunk, so a chunk within a tile of the view stays");
		Assert.isTrue(map.isChunkVisible(1, 0));
		Assert.isFalse(map.isChunkVisible(2, 0));
		map.cullNone();
		Assert.isTrue(map.isChunkVisible(2, 1), "no view: every chunk");
		final over:Null<h2d.Object> = @:privateAccess map.chunks[5].parts[@:privateAccess map.overPass];
		Assert.notNull(over, "the roof, over the actors, in the last chunk");
		map.cull(0, 0, 1, 1);
		Assert.isFalse(over != null && over.visible, "what a chunk draws over the actors goes with it");
	}

	// ===== What a chunk costs =====

	/** How many ints a grid holds: every row's length added up. **/
	static function intsOf(grid:Null<Array<Array<Int>>>):Int {
		if (grid == null)
			return 0;
		var n = 0;
		for (row in grid)
			n += row.length;
		return n;
	}

	@Test
	public function testAChunkIsDrawnFromGridsOverItselfAndACellAroundOnly() {
		// A 10 by 6 map in chunks of 4, dirt in the last chunk alone (cells 8..9, 4..5). The chunk is
		// drawn by itself, so the grids the autotile is given cover it and a cell around it: 3 by 3
		// cells, 4 by 4 corners at most. Rows padded from the map's first column would make a chunk
		// far to the right cost its column in ints, for every mask and every where-grid.
		final was = TileMap.defaultChunkSize;
		TileMap.defaultChunkSize = 4;
		final map = try builderFromSource(source('#m tilemap { tileset: plains size: 10, 6 legend { ".": grass, "d": dirt }
			terrain: ["..........", "..........", "..........", "..........", "..........", "........dd"] }')).buildTilemap("m") catch (e:Dynamic) {
			TileMap.defaultChunkSize = was;
			throw e;
		}
		TileMap.defaultChunkSize = was;
		final asked:Array<{grid:Array<Array<Int>>, where:Null<Array<Array<Int>>>}> = [];
		final tiles:TileMapTiles = @:privateAccess map.tiles;
		@:privateAccess map.tiles = {
			autotile: (name, grid, where, x0, y0) -> {
				asked.push({grid: grid, where: where});
				return tiles.autotile(name, grid, where, x0, y0);
			},
			autotileFormat: tiles.autotileFormat,
			frames: tiles.frames,
			metadata: tiles.metadata,
		};
		map.cull(72, 40, 8, 8); // the last chunk's own pixels: no neighbour within a tile of the view
		@:privateAccess map.drawDirty(true);
		Assert.isFalse(@:privateAccess map.chunks[5].dirty, "the last chunk is drawn");
		Assert.isTrue(@:privateAccess map.chunks[4].dirty && @:privateAccess map.chunks[2].dirty, "and no other");
		Assert.isTrue(asked.length > 0, "the dirt's autotile is drawn");
		for (a in asked) {
			Assert.isTrue(intsOf(a.grid) <= 16, 'the mask holds the chunk and a cell around it: ${intsOf(a.grid)} ints for 3 by 3 cells');
			Assert.isTrue(intsOf(a.where) <= 16, 'the positions drawn are the chunk\'s own: ${intsOf(a.where)} ints for 4 by 4 corners');
		}
	}

	@Test
	public function testRiseLookupsAlongACliffGrowWithItsLength() {
		#if MULTIANIM_ALLOC_TRACK
		// A cliff 62 cells long of two side pieces taken in turn: every cell's piece is numbered from
		// the run's start, which must be found once a run, not by walking back from every cell.
		final width = 64;
		final map = builderFromSource(source('#m tilemap { tileset: plains size: $width, 2 legend { ".": grass }
			terrain: ["${StringTools.rpad("", ".", width)}", "${StringTools.rpad("", ".", width)}"]
			levels: ["0${StringTools.rpad("", "2", width - 2)}0", "${StringTools.rpad("", "0", width)}"] }',
			'rise 2 { side: "stairs", "flower" span: 1 }')).buildTilemap("m");
		TileMap.riseLookups = 0;
		map.redraw();
		final lookups = TileMap.riseLookups;
		final budget = 8 * width * 2;
		Assert.isTrue(lookups <= budget, 'a few lookups a cell: $lookups for ${width * 2} cells, the budget is $budget');
		Assert.equals(2, map.sideAt(30, 1), "the side is there");
		#else
		Assert.pass("counts need MULTIANIM_ALLOC_TRACK");
		#end
	}

	@Test
	public function testASheetIsAskedForACellOnceNotForEveryCellDrawn() {
		// Six flowers in a layer, and the plateau's side of three cells: the frames of a name are
		// looked up once as the map reads its rows, not for every cell that shows them.
		final flowers = cellsDrawn(build('#m tilemap {
			tileset: plains
			size: 4, 3
			legend { ".": grass }
			terrain: ["....", "....", "...."]
			layer deco { legend { "f": flower } rows: ["ffff", "ff  ", "    "] }
		}'));
		Assert.equals(1, flowers.filter(n -> n == "flower").length, 'flower asked for once, got ${flowers.filter(n -> n == "flower").length} times');
		final plateau = cellsDrawn(build(PLATEAU));
		Assert.equals(1, plateau.filter(n -> n == "face").length, 'the side piece asked for once, got ${plateau.filter(n -> n == "face").length} times');
	}

	@Test
	public function testCellsWithTheSameMetadataShareOneSettings() {
		// Most cells are the same combination of terrain, side and layer cells: one settings
		// object serves them all, made once a combination, not once a cell.
		final map = build('#m tilemap { tileset: plains size: 3, 1 legend { ".": grass, "d": dirt } terrain: [".d."] }');
		Assert.isTrue(map.metadataAt(0, 0) == map.metadataAt(2, 0), "two grass cells read the same settings object");
		Assert.isFalse(map.metadataAt(0, 0) == map.metadataAt(1, 0), "the dirt cell its own");
		Assert.equals(1, map.metadataAt(2, 0).getIntOrDefault("cost", 0));
		Assert.equals(2, map.metadataAt(1, 0).getIntOrDefault("cost", 0));
	}

	@Test
	public function testReadingACellsSideOrMetadataDrawsNoTiles() {
		// A game that reads the whole map (pathfinding) must not draw the whole map: what a cell is
		// (its side, its metadata) is worked out without building its chunk's tiles.
		final map = chunked('levels: ["0000000000", "0000000000", "0000000000", "0000000000", "0000000010", "0000000000"]', "", true);
		final asked = recordAutotiles(map);
		Assert.equals(1, map.sideAt(8, 5), "the side below the raised cell, in the last chunk");
		Assert.isTrue(map.metadataAt(8, 5).getBoolOrDefault("wall", false), "with the rise's metadata");
		Assert.equals(1, map.metadataAt(9, 5).getIntOrDefault("cost", 0), "and the grass's beside it");
		Assert.equals(0, asked.length, "no autotile drawn for a read");
		Assert.equals(0, groundOf(map, 5).length, "nothing on the chunk's ground");
		@:privateAccess map.drawDirty(false);
		Assert.isTrue(asked.length > 0, "drawn when the map is drawn");
		Assert.equals(1, map.sideAt(8, 5), "and the same side then");
	}

	// ===== Chunk borders =====

	/** A map drawn whole into a texture its size: the pixels on screen, whatever its chunks. **/
	static function pixelsOf(map:TileMap):hxd.Pixels {
		final scene = new h2d.Scene();
		scene.addChild(map);
		map.cullNone();
		map.redraw();
		final texture = new h3d.mat.Texture(map.width * map.tileSize, map.height * map.tileSize, [Target]);
		texture.clear(0xFF00FF);
		map.drawTo(texture);
		final pixels = texture.capturePixels();
		texture.dispose();
		map.remove();
		scene.dispose();
		pixels.convert(BGRA);
		return pixels;
	}

	/** Where a map drawn in chunks of `chunkSize` looks different from the same map in one chunk: the pixels that differ and the first of them, or null. **/
	static function chunkBorderDifference(source:String, chunkSize:Int):Null<String> {
		final map = builderFromSource(source).buildTilemap("m");
		map.setChunkSize(chunkSize);
		final chunked = pixelsOf(map);
		map.setChunkSize(map.width > map.height ? map.width : map.height);
		final whole = pixelsOf(map);
		var differ = 0;
		var first = "";
		for (y in 0...whole.height)
			for (x in 0...whole.width)
				if (chunked.getPixel(x, y) != whole.getPixel(x, y)) {
					if (differ == 0)
						first = 'pixel $x, $y (cell ${Std.int(x / map.tileSize)}, ${Std.int(y / map.tileSize)})';
					differ++;
				}
		return differ == 0 ? null : '$differ pixels differ, the first at $first';
	}

	static function rows(row:String, count:Int):String {
		return [for (_ in 0...count) '"$row"'].join(", ");
	}

	@Test
	public function testChunkBordersDrawTheSameAsOneChunk() {
		// Maps of 8 by 8 cells drawn in chunks of 4 and in one chunk must look the same. A corner
		// autotile's tile sits half a cell up and left of its corner, so a chunk's first column and
		// row of corners reach over the last column and row of the chunk before it: whatever that
		// chunk drew on its cells there (layer cells, sides, a terrain of cells above an autotile
		// one, an object reaching across) must still be drawn over the next chunk's terrain.
		final dirt = '#m tilemap { tileset: plains size: 8, 8 legend { "d": dirt } terrain: [${rows("dddddddd", 8)}]';
		Assert.isNull(chunkBorderDifference(source(dirt + ' layer deco { legend { "f": flower } rows: [${rows("   f    ", 3)}, "ffffffff", ${rows("   f    ", 4)}] } }'), 4),
			"a layer's cells on the last column and row of a chunk are drawn over the next chunk's terrain");
		Assert.isNull(chunkBorderDifference(source(dirt + ' levels: [${rows("00000000", 2)}, "11111111", ${rows("00000000", 5)}] }'), 4),
			"a side landing on the last row of a chunk is drawn over the next chunk's terrain");
		Assert.isNull(chunkBorderDifference(source('#m tilemap { tileset: plains size: 8, 8 legend { "s": stone } terrain: [${rows("ssssssss", 8)}] }',
			'terrain stone { cells: "roof" }'), 4),
			"a terrain of cells above autotile terrains is drawn over every chunk's autotiles under it");
		Assert.isNull(chunkBorderDifference(source('#m tilemap { tileset: plains size: 8, 8 legend { ".": grass } terrain: [${rows("........", 8)}]
			layer a { legend { "f": flower } rows: ["        ", "    f   ", ${rows("        ", 6)}] }
			layer b { legend { "t": tree } rows: [${rows("        ", 2)}, "   t    ", ${rows("        ", 5)}] } }',
			'cell tree { size: 2, 2 draw: under }'), 4),
			"a later layer's object reaching into the next chunk is drawn over an earlier layer's cell there");
	}

	// ===== Objects of several cells and culling =====

	@Test
	public function testAnObjectReachingIntoTheViewIsDrawnWithItsChunk() {
		// A pole four cells tall stands on row 8, in the third row of chunks of 4, and reaches up to
		// row 5. A view of rows 0 to 5 sees its top, so the chunk it stands in is shown and drawn.
		final was = TileMap.defaultChunkSize;
		TileMap.defaultChunkSize = 4;
		final map = try builderFromSource(source('#m tilemap { tileset: plains size: 4, 12 legend { ".": grass } terrain: [${rows("....", 12)}]
			layer props { legend { "p": pole } rows: [${rows("    ", 8)}, " p  ", ${rows("    ", 3)}] } }',
			'cell pole { size: 1, 4 }', 'pole: 0, 0, 8, 32')).buildTilemap("m") catch (e:Dynamic) {
			TileMap.defaultChunkSize = was;
			throw e;
		}
		TileMap.defaultChunkSize = was;
		Assert.equals("pole", map.cellAt("props", 1, 5), "the pole covers row 5");
		map.cull(0, 0, 32, 48); // rows 0 to 5
		@:privateAccess map.drawDirty(true); // as sync does, with the view
		Assert.isTrue(map.isChunkVisible(0, 2), "the chunk the pole stands in is shown: the pole's top is in view");
		final objects:Array<h2d.Object> = @:privateAccess map.chunks[2].objects;
		Assert.equals(1, objects.length, "and the pole is drawn");
		Assert.isTrue(objects.length == 1 && objects[0].visible, "and shown");
	}

	@Test
	public function testAnObjectAmongTheActorsGoesWithItsChunk() {
		final map = chunked('layer props { legend { "t": tree } rows: [${rows("          ", 5)}, "        t "] }', 'cell tree { size: 2, 2 }');
		final tree:h2d.Object = (@:privateAccess map.chunks[5].objects : Array<h2d.Object>)[0];
		Assert.isTrue(tree.visible);
		map.cull(0, 0, 1, 1);
		Assert.isFalse(map.isChunkVisible(2, 1));
		Assert.isFalse(tree.visible, "the tree is hidden with its chunk, out of view");
		map.setCell("props", 8, 5, " ");
		map.setCell("props", 8, 5, "t");
		map.redraw();
		final again:h2d.Object = (@:privateAccess map.chunks[5].objects : Array<h2d.Object>)[0];
		Assert.isFalse(again.visible, "drawn while its chunk is out of view, it starts hidden");
		map.cullNone();
		Assert.isTrue(again.visible, "and is shown with its chunk");
	}

	// ===== What a draw costs =====

	@Test
	public function testMergedMetadataIsKeyedWithoutStrings() {
		#if MULTIANIM_ALLOC_TRACK
		// Every cell has the stairs' metadata over its terrain's: a merged combination, looked up
		// for every cell drawn or worked out. The lookup's key is not a string built per cell.
		final map = builderFromSource(source('#m tilemap { tileset: plains size: 8, 2 legend { ".": grass, "d": dirt } terrain: ["d.d.d.d.", ".d.d.d.d"]
			layer s { legend { "s": stairs } rows: ["ssssssss", "ssssssss"] } }')).buildTilemap("m");
		TileMap.metadataKeyStrings = 0;
		map.redraw(); // its first draw
		Assert.equals(0, TileMap.metadataKeyStrings, 'strings built for metadata keys: ${TileMap.metadataKeyStrings} for 16 cells');
		Assert.isTrue(map.metadataAt(1, 0).getBoolOrDefault("climb", false), "the stairs' metadata");
		Assert.equals(1, map.metadataAt(1, 0).getIntOrDefault("cost", 0), "over the grass's");
		Assert.equals(2, map.metadataAt(0, 0).getIntOrDefault("cost", 0), "or the dirt's");
		Assert.isTrue(map.metadataAt(0, 0) == map.metadataAt(2, 0), "one settings object a combination");
		#else
		Assert.pass("counts need MULTIANIM_ALLOC_TRACK");
		#end
	}

	@Test
	public function testACliffsRiseIsLookedUpOnceACellInAnyChunkSize() {
		#if MULTIANIM_ALLOC_TRACK
		// A cliff 62 cells long of two side pieces taken in turn. Each cell's rise is looked up once
		// (a row's first and last cell once more, for its neighbour outside the scan), and a chunk
		// along the run finds where the run starts without walking back to it.
		final width = 64;
		final src = source('#m tilemap { tileset: plains size: $width, 2 legend { ".": grass }
			terrain: ["${StringTools.rpad("", ".", width)}", "${StringTools.rpad("", ".", width)}"]
			levels: ["0${StringTools.rpad("", "2", width - 2)}0", "${StringTools.rpad("", "0", width)}"] }',
			'rise 2 { side: "stairs", "flower" span: 1 }');
		for (size in [32, 4]) {
			final map = builderFromSource(src).buildTilemap("m");
			map.setChunkSize(size);
			// the cells each chunk scans: its own and the longest side's span around, inside the map,
			// and two more a row
			final span:Int = @:privateAccess map.maxSpan();
			var budget = 0;
			for (c in @:privateAccess map.chunks) {
				final r = c.rect;
				final rowsIn = (r.y1 + span < map.height ? r.y1 + span : map.height) - (r.y0 - span > 0 ? r.y0 - span : 0);
				final colsIn = (r.x1 + span < map.width ? r.x1 + span : map.width) - (r.x0 - span > 0 ? r.x0 - span : 0);
				budget += rowsIn * (colsIn + 2);
			}
			TileMap.riseLookups = 0;
			map.redraw();
			Assert.isTrue(TileMap.riseLookups <= budget, 'chunks of $size: ${TileMap.riseLookups} rise lookups, one a cell scanned is $budget');
			Assert.equals(2, map.sideAt(30, 1), "the side is there");
		}
		#else
		Assert.pass("counts need MULTIANIM_ALLOC_TRACK");
		#end
	}

	@Test
	public function testAStepTowardANeighbourIsNotMadeEachTime() {
		Assert.isTrue(TileMap.towardStep("up") == TileMap.towardStep("up"), "the same step every time, not a new object");
		Assert.isTrue(TileMap.towardStep("down") == TileMap.towardStep("sideways"), "down is the default");
		Assert.equals(-1, TileMap.towardStep("left").dx);
		Assert.equals(1, TileMap.towardStep("down").dy);
	}

	@Test
	public function testOnlyTheChunksInViewAreLookedAtForDrawing() {
		#if MULTIANIM_ALLOC_TRACK
		// 256 chunks, all waiting to be drawn, and a view of one: a frame looks at the chunks in
		// view, not at every chunk of the map while some far one is still undrawn.
		final was = TileMap.defaultChunkSize;
		TileMap.defaultChunkSize = 4;
		final row = StringTools.rpad("", ".", 64);
		final map = try builderFromSource(source('#m tilemap { tileset: plains size: 64, 64 legend { ".": grass } terrain: [${rows(row, 64)}] }'))
			.buildTilemap("m") catch (e:Dynamic) {
			TileMap.defaultChunkSize = was;
			throw e;
		}
		TileMap.defaultChunkSize = was;
		map.cull(0, 0, 16, 16);
		@:privateAccess map.drawDirty(true);
		Assert.isFalse(@:privateAccess map.chunks[0].dirty, "the chunk in view is drawn");
		Assert.isTrue(@:privateAccess map.chunks[255].dirty, "the far one waits");
		TileMap.chunkChecks = 0;
		for (_ in 0...10)
			@:privateAccess map.drawDirty(true);
		Assert.isTrue(TileMap.chunkChecks <= 10 * 4, 'chunks looked at in 10 frames: ${TileMap.chunkChecks}, the view reaches 1');
		#else
		Assert.pass("counts need MULTIANIM_ALLOC_TRACK");
		#end
	}

	@Test
	public function testMetadataStillMergesWhenCombinationsOverflowAnInt() {
		// Five layers of fifty characters each: more combinations of metadata sources than an Int
		// holds, so the key is a string there; the cells' metadata merges and is shared as with an
		// Int key.
		final chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWX";
		final legend = [for (i in 0...chars.length) '"${chars.charAt(i)}": stairs'].join(", ");
		final layers = [for (l in 0...5) 'layer l$l { legend { $legend } rows: ["${chars.charAt(l)}${chars.charAt(l)}${chars.charAt(l + 10)}"] }'].join("\n");
		final map = builderFromSource(source('#m tilemap { tileset: plains size: 3, 1 legend { ".": grass, "d": dirt } terrain: ["..d"] $layers }'))
			.buildTilemap("m");
		Assert.isFalse(@:privateAccess map.intMetadataKeys, "precondition: the combinations do not fit an Int");
		#if MULTIANIM_ALLOC_TRACK
		TileMap.metadataKeyStrings = 0;
		#end
		map.redraw();
		#if MULTIANIM_ALLOC_TRACK
		Assert.isTrue(TileMap.metadataKeyStrings > 0, "keyed by strings");
		#end
		Assert.isTrue(map.metadataAt(0, 0).getBoolOrDefault("climb", false), "the stairs' metadata");
		Assert.equals(1, map.metadataAt(0, 0).getIntOrDefault("cost", 0), "over the grass's");
		Assert.equals(2, map.metadataAt(2, 0).getIntOrDefault("cost", 0), "over the dirt's");
		Assert.isTrue(map.metadataAt(0, 0) == map.metadataAt(1, 0), "the same combination shares one settings object");
		Assert.isFalse(map.metadataAt(0, 0) == map.metadataAt(2, 0), "another has its own");
	}

	@Test
	public function testAnImageBiggerThanItsCellWidensTheView() {
		// A layer's name with no tileset cell is a cell of one, drawn from its top-left; this one is
		// 8x40, five cells tall. Placed on row 3, the last of the first chunk of 4, it reaches down to
		// row 7, so a view of rows 6 and 7 shows the first chunk, which draws it.
		final was = TileMap.defaultChunkSize;
		TileMap.defaultChunkSize = 4;
		final map = try builderFromSource(source('#m tilemap { tileset: plains size: 4, 12 legend { ".": grass } terrain: [${rows("....", 12)}]
			layer props { legend { "p": post } rows: [${rows("    ", 3)}, " p  ", ${rows("    ", 8)}] } }', "", 'post: 0, 0, 8, 40'))
			.buildTilemap("m") catch (e:Dynamic) {
			TileMap.defaultChunkSize = was;
			throw e;
		}
		TileMap.defaultChunkSize = was;
		Assert.equals(4, @:privateAccess map.objectReach, "the image reaches 4 cells below its cell");
		map.cull(0, 50, 32, 10); // rows 6 and 7
		Assert.isTrue(map.isChunkVisible(0, 0), "the chunk the post's cell is in is shown: its image is in view");
	}

	/** Where an object comes in a depth-first walk of `root`, the order Heaps draws them in; -1 when it is not under it. **/
	static function drawIndex(root:h2d.Object, target:h2d.Object):Int {
		var index = 0;
		function walk(o:h2d.Object):Bool {
			if (o == target)
				return true;
			index++;
			for (child in o)
				if (walk(child))
					return true;
			return false;
		}
		return walk(root) ? index : -1;
	}

	@Test
	public function testEdgesAreDrawnUnderEveryChunksSides() {
		// A plateau across the map: every chunk draws its rim's edge and the side below it. A corner
		// edge tile reaches half a cell back into the chunk before, so every chunk's edges are
		// under every chunk's sides, as when the map is drawn in one piece.
		final map = chunked('levels: ["0000000000", "1111111111", "0000000000", "0000000000", "0000000000", "0000000000"]');
		final ground:h2d.Object = @:privateAccess map.ground;
		final edgePass:Int = @:privateAccess map.edgePass;
		final sidePass:Int = @:privateAccess map.sidePass;
		final chunks = @:privateAccess map.chunks;
		for (sides in 0...3)
			for (edges in 0...3) {
				final sidePart = chunks[sides].parts[sidePass];
				final edgePart = chunks[edges].parts[edgePass];
				Assert.isTrue(sidePart != null && edgePart != null, 'precondition: chunks $edges and $sides draw edges and sides');
				if (sidePart == null || edgePart == null)
					continue;
				final edgeAt = drawIndex(ground, edgePart);
				final sideAt = drawIndex(ground, sidePart);
				Assert.isTrue(edgeAt >= 0 && sideAt >= 0, 'both drawn on the ground: edges at $edgeAt, sides at $sideAt');
				Assert.isTrue(edgeAt < sideAt, 'chunk $edges\'s edges (at $edgeAt) under chunk $sides\'s sides (at $sideAt)');
			}
	}
}
