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
	public static function source(map:String, ?extraTileset:String = ""):String {
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

	static function build(map:String, ?name:String = "m"):TileMap {
		return builderFromSource(source(map)).buildTilemap(name);
	}

	static function builderErrorCode(fn:() -> Void):Null<String> {
		try {
			fn();
			return null;
		} catch (e:BuilderError) {
			return e.code;
		}
	}

	static function groundGroup(map:TileMap, index:Int):h2d.TileGroup {
		return cast @:privateAccess map.ground.getChildAt(index);
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
		final animated:Array<{frames:Array<h2d.Object>}> = @:privateAccess map.animated;
		Assert.equals(1, animated.length, "one animated terrain");
		final first = animated[0].frames[0];
		final second = animated[0].frames[1];
		Assert.isTrue(first.parent == @:privateAccess map.ground && second.parent == first.parent, "both frames are on the ground");
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
		return asked;
	}

	/** Every autotile a map asks for while it is drawn again: its name and, when only some positions, those. **/
	static function autotilesDrawn(map:TileMap):Array<{name:String, where:Null<Array<Array<Int>>>}> {
		final asked:Array<{name:String, where:Null<Array<Array<Int>>>}> = [];
		final tiles:TileMapTiles = @:privateAccess map.tiles;
		map.setSource(map.def, map.tileset, {
			autotile: (name, grid, where) -> {
				asked.push({name: name, where: where});
				return tiles.autotile(name, grid, where);
			},
			autotileFormat: tiles.autotileFormat,
			frames: tiles.frames,
			metadata: tiles.metadata,
		});
		return asked;
	}

	@Test
	public function testASideIsDrawnWithTheEndPiecesTheRiseNames() {
		// The rise names left: only. The plateau's side is a run of three cells: its first end is the
		// left piece, its middle and its last end (no right:) the side itself.
		final plateau = cellsDrawn(build(PLATEAU));
		Assert.equals(1, plateau.filter(n -> n == "faceEnd").length, "one left end");
		Assert.equals(2, plateau.filter(n -> n == "face").length, "the middle and the last end");
		// A side one cell wide, with no single: given, is the side itself
		final bump = cellsDrawn(build('#m tilemap { tileset: plains size: 3, 3 legend { ".": grass } terrain: ["...", "...", "..."] levels: ["000", "010", "000"] }'));
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
		final asked = cellsDrawn(builderFromSource(source('#m tilemap {
			tileset: plains
			size: 7, 3
			legend { ".": grass }
			terrain: [".......", ".......", "......."]
			levels:  ["0222220", "0000000", "0000000"]
		}', 'rise 2 { side: "stairs", "flower", "roof" left: "faceEnd" span: 1 }')).buildTilemap("m"));
		final sides = asked.filter(n -> n == "stairs" || n == "flower" || n == "roof" || n == "faceEnd");
		Assert.same(["faceEnd", "stairs", "flower", "roof", "stairs"], sides);
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
		Assert.isNull(tops[0].where, "its top is drawn over all of it, inside and rim");
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
		Assert.equals(1, over.numChildren, "the roof, whose cell says draw: over, above the actors");
		Assert.equals(1, top.numChildren, "the glow layer, draw: top");
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
		Assert.equals("dirt", map.terrainAt(1, 0), "asked, the map is drawn first");
		Assert.isFalse(drawn == groundGroup(map, 0), "once");
		final again = groundGroup(map, 0);
		Assert.equals(1, map.sideAt(2, 1), "the side of the level raised");
		Assert.isTrue(again == groundGroup(map, 0), "and not again while nothing changes");
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
		Assert.isNull(drawn[1].where, "the terrain's own at every position");
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
}
