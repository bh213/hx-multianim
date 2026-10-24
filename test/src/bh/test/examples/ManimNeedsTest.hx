package bh.test.examples;

import bh.multianim.MacroManimParser;
import bh.multianim.ManimNeeds;
import bh.multianim.MultiAnimParser;
import bh.stateanim.AnimParser;
import utest.Assert;

/**
 * What a file needs of its host, listed from the parse alone (`ManimNeedsTools.needsOf`, with no
 * loader): sheets and their cells, a name from a parameter (every value of an enum, bool or range;
 * a default and what a `staticRef` passes), a `@final`, image files, fonts (a widget's `font`
 * setting too), `.anim` files, imports kept without a loader, custom filters, cursors, the sounds
 * and music the file plays and the sound files its own blocks name, the `ui` bank keys its widgets
 * play by default, a mix block that is no need; and an `.anim` file's sheet, frames and sounds
 * (`animNeedsOf`).
 */
class ManimNeedsTest extends utest.Test {
	static function needs(source:String):ManimNeeds {
		return ManimNeedsTools.needsOf(MacroManimParser.parseFile('version: 1.0\n$source', "needs-test", null));
	}

	static function animNeeds(source:String):AnimNeeds {
		return ManimNeedsTools.animNeedsOf(AnimParser.parseString(source, "needs-test.anim", null).loaded());
	}

	static function cells(n:ManimNeeds, sheet:String):Null<Array<String>> {
		Assert.isTrue(n.sheets.exists(sheet), 'sheet $sheet listed');
		return n.sheets.get(sheet);
	}

	static function keys(m:Map<String, Dynamic>):Array<String> {
		final out = [for (k in m.keys()) k];
		out.sort(Reflect.compare);
		return out;
	}

	@Test
	public function testSheetsAndTheirCells() {
		final n = needs('
			#p programmable() {
				bitmap(sheet("ui", "button")): 0, 0
				bitmap(center(sheet("ui", "icon", 2))): 0, 0
				ninepatch("ui", "panel", 40, 30): 0, 0
				bitmap(sheet("fx", "spark")): 0, 0
				bitmap(sheet("ui", "button")): 5, 5
			}
		');
		Assert.same(["fx", "ui"], keys(n.sheets));
		Assert.same(["button", "icon", "panel"], cells(n, "ui"));
		Assert.same(["spark"], cells(n, "fx"));
		Assert.isFalse(n.fromParameters);
		Assert.equals(0, n.tiles.length);
	}

	@Test
	public function testACellBuiltFromAParameterOfAnyValueIsTheWholeSheet() {
		final n = needs('
			#p programmable(style:string="a") {
				bitmap(sheet("ui", "button")): 0, 0
				ninepatch("ui", "btn_" + $$style, 40, 30): 0, 0
				bitmap(sheet("fx", "spark")): 0, 0
			}
		');
		Assert.isTrue(n.fromParameters);
		Assert.isNull(cells(n, "ui"), "a cell from a string parameter makes the sheet whole");
		Assert.same(["spark"], cells(n, "fx"));
	}

	@Test
	public function testACellOverAnEnumBoolOrRangeParameterIsListedByEveryValue() {
		final n = needs('
			#p programmable(style:[a, b]=a, lit:bool=false, lvl:1..3=1) {
				ninepatch("ui", "btn_" + $$style, 40, 30): 0, 0
				bitmap(sheet("ui", "lamp_" + $$lit)): 0, 0
				bitmap(sheet("ui", \'lvl_$${$$lvl + 1}\')): 0, 0
				bitmap(sheet("ui", ?($$lit) "on" : "off")): 0, 0
			}
		');
		Assert.isFalse(n.fromParameters, "every value of an enum, a bool and a range is known");
		Assert.same(["btn_a", "btn_b", "lamp_0", "lamp_1", "lvl_2", "lvl_3", "lvl_4", "off", "on"], cells(n, "ui"));
	}

	@Test
	public function testASheetNamedByAParameterIsListedByItsDefaultAndSaysSo() {
		final n = needs('
			#p programmable(sheet:string="ui") {
				ninepatch($$sheet, "panel", 40, 30): 0, 0
			}
		');
		Assert.isTrue(n.fromParameters, "another sheet can be given");
		Assert.same(["panel"], cells(n, "ui"));

		final none = needs('
			#p programmable(sheet:string) {
				ninepatch($$sheet, "panel", 40, 30): 0, 0
			}
		');
		Assert.isTrue(none.fromParameters);
		Assert.same([], keys(none.sheets), "with no default the sheet cannot be named");
	}

	@Test
	public function testAFinalIsListedByItsValue() {
		final n = needs('
			#p programmable(style:[a, b]=a) {
				@final SHEET = "deco"
				@final ICON = "star_" + $$style
				@final FONT = "m5x7"
				bitmap(sheet($$SHEET, $$ICON)): 0, 0
				text($$FONT, "hi", #FFFFFF): 0, 10
			}
		');
		Assert.isFalse(n.fromParameters);
		Assert.same(["star_a", "star_b"], cells(n, "deco"));
		Assert.same(["m5x7"], n.fonts);
	}

	@Test
	public function testASlotsParametersAreSeenInItsBody() {
		final n = needs('
			#p programmable(icon:string="gem") {
				#box slot(icon:[a, b]=a) {
					bitmap(sheet("ui", "icon_" + $$icon)): 0, 0
				}
				bitmap(sheet("fx", "plain")): 0, 0
			}
		');
		Assert.same(["icon_a", "icon_b"], cells(n, "ui"), "the slot\'s enum, not the programmable\'s string of the same name");
		Assert.isFalse(n.fromParameters);
	}

	@Test
	public function testAFinalInASwitchArmStaysInTheArm() {
		final n = needs('
			#p programmable(mode:[a, b]=a, C:string="outer") {
				@final F = "m5x7"
				@switch(mode) {
					a {
						@final C = "alpha"
						bitmap(sheet("ui", $$C)): 0, 0
					}
					b {
						text($$F, "x", #FFFFFF): 0, 0
					}
				}
				text($$C, "x", #FFFFFF): 0, 0
			}
		');
		Assert.same(["alpha"], cells(n, "ui"), "the arm\'s own @final");
		Assert.same(["m5x7", "outer"], n.fonts, "the body\'s @final is seen in an arm; after the switch C is the parameter again");
	}

	@Test
	public function testACellOverALoopVariableIsTheWholeSheet() {
		final n = needs('
			#p programmable() {
				repeatable($$n, step(2, dx: 10)) {
					bitmap(sheet("ui", "n_" + $$n)): 0, 0
				}
				bitmap(sheet("fx", "plain")): 0, 0
			}
		');
		Assert.isNull(cells(n, "ui"), "a loop variable\'s values are not worked out");
		Assert.same(["plain"], cells(n, "fx"));
		Assert.isTrue(n.fromParameters);
	}

	@Test
	public function testValuesAStaticRefPassesAndADefaultAreListed() {
		final n = needs('import "std.manim" as "std"
			#label programmable(font:string="m5x7", text:string="") {
				text($$font, $$text, #FFFFFF): 0, 0
			}
			#screen programmable() {
				staticRef($$label, font => "big", text => "Title"): 0, 0
				dynamicRef($$label, font => "small"): 0, 20
				staticRef(external(std), label, font => "elsewhere"): 0, 40
			}
		');
		Assert.same(["big", "m5x7", "small"], n.fonts, "an imported programmable\'s fonts are its file\'s");
		Assert.isTrue(n.fromParameters, "a string parameter can be given others from code");
	}

	@Test
	public function testImageFilesTilesIteratorAndAnInlineAtlas() {
		final n = needs('
			#own atlas2("own.png") {
				cell: 0, 0, 8, 8
			}
			#p programmable() {
				bitmap(file("hero.png")): 0, 0
				bitmap(sheet("own", "cell")): 0, 0
				repeatable($$i, tiles($$b, $$t, "deck")) {
					bitmap($$b): 0, 0
				}
			}
		');
		Assert.same(["hero.png", "own.png"], n.tiles);
		Assert.isFalse(n.sheets.exists("own"), "the file\'s own atlas is not a need");
		Assert.isNull(cells(n, "deck"), "a tiles() iterator takes the whole sheet");
	}

	@Test
	public function testFonts() {
		final n = needs('
			#p programmable() {
				@final lh = $$ctx.font("big").lineHeight
				text(pixel, "hi", #FFFFFF): 0, $$lh
				richText(pixel, "[b]hi[/b]", #FFFFFF, styles: {b: font("bold")}): 0, 0
				text(pixel, "fit", #FFFFFF, left, 20, autoFit: width [m3x6, tiny]): 0, 0
				bitmap(generated(colorWithText(20, 10, #FF0000, "x", #000000, tiny))): 0, 0
			}
		');
		Assert.same(["big", "bold", "m3x6", "pixel", "tiny"], n.fonts);
	}

	@Test
	public function testFontsAWidgetIsGivenInItsSettings() {
		final n = needs('
			#p programmable() {
				placeholder(generated(cross(90, 22, #FF0000)), builderParameter("btn")) {
					settings{text=>"A", width:int=>90, height:int=>22, font=>"m6x11"}
				}
				placeholder(generated(cross(90, 22, #FF0000)), builderParameter("list")) {
					settings{item.font=>"tiny", scrollbar.thickness:int=>4}
				}
			}
		');
		Assert.same(["m6x11", "tiny"], n.fonts);
	}

	@Test
	public function testCursorsAnInteractiveNames() {
		final n = needs('
			#cursors cursor {
				Sword: sheet("ui", "sword"), hot: 0, 0
			}
			#p programmable() {
				interactive(10, 10, "a", cursor => "sword", cursor.hover => "Grab"): 0, 0
				interactive(10, 10, "b", cursor => "pointer", cursor.disabled => "default"): 0, 20
				interactive(10, 10, "c", cursor => "aim"): 0, 40
			}
		');
		Assert.same(["aim", "grab"], n.cursors, "the file\'s own and CursorManager\'s are no need; lower case");
	}

	@Test
	public function testTheBuiltInCursorsAreCursorManagers() {
		for (name in ManimNeedsTools.BUILT_IN_CURSORS)
			Assert.notNull(bh.base.CursorManager.getCursor(name), 'CursorManager has "$name"');
	}

	@Test
	public function testAnimFiles() {
		final n = needs('
			#p programmable() {
				stateanim("marine.anim", "idle", "direction" => "l"): 0, 0
				#wolf stateanim("wolf.anim", "run"): 10, 10
				bitmap(sheet("fx", "flash")): extraPoint("turret.anim", "fire", "muzzle")
				particles {
					count: 3
					tiles: sheet("fx", "dot")
					animFile: "spark.anim"
				}
			}
		');
		Assert.same(["marine.anim", "spark.anim", "turret.anim", "wolf.anim"], n.anims);
	}

	@Test
	public function testImportsAreKeptWithNoLoader() {
		final result = MacroManimParser.parseFile('version: 1.0\nimport "std.manim" as "std"\nimport "theme/dark.manim" as "dark"\n#p programmable() { bitmap(sheet("ui", "x")): 0, 0 }', "needs-test", null);
		Assert.same(["dark", "std"], keys(result.importPaths));
		Assert.equals("std.manim", result.importPaths.get("std"));
		Assert.equals("theme/dark.manim", result.importPaths.get("dark"));
		Assert.same([], keys(result.imports), "nothing loaded without a loader");
		final n = ManimNeedsTools.needsOf(result);
		Assert.same(["dark", "std"], keys(n.imports));
		Assert.equals("theme/dark.manim", n.imports.get("dark"));
	}

	@Test
	public function testCustomFilters() {
		final n = needs('
			#p programmable() {
				bitmap(sheet("ui", "x")) {
					filter: perlinNoise(1.0, 10.0)
				}
				bitmap(sheet("ui", "y")) {
					filter: group(scanlines(0.5), outline(1, #000000))
				}
			}
		');
		// scanlines is one of the engine's shaders: it needs nothing of the host, and is said apart
		Assert.same(["perlinnoise"], n.filters);
		Assert.same(["scanlines"], n.shaders);
	}

	@Test
	public function testSoundsAWidgetAndAnInteractiveName() {
		final n = needs('
			#button programmable(buttonText:string=Click, status:[normal,hover,pressed]=normal) {
				settings { sound.click => "fx.confirm", sound.hover => none }
				bitmap(sheet("ui", "button")): 0, 0
				interactive(40, 20, "buy", sound.click => "ui.change"): 0, 0
				interactive(40, 20, "quiet", sound.click => none): 0, 30
				interactive(40, 20, "plain"): 0, 60
			}
		');
		Assert.same(["fx.confirm", "ui.change"], n.sounds);
		Assert.same(["click"], n.uiSounds, "the plain interactive\'s click; the button\'s own hover and click are named");
	}

	@Test
	public function testMusicAScreenNames() {
		final n = needs('
			#screen programmable() {
				settings { music => "music.play" }
				bitmap(sheet("ui", "bg")): 0, 0
			}
			#silent programmable() {
				settings { music => none }
			}
			#hangar programmable() {
				settings { ambience => "amb.hum" }
			}
			#still programmable() {
				settings { ambience => none }
			}
		');
		Assert.same(["music.play"], n.music);
		Assert.same(["amb.hum"], n.sounds, "an ambience is a sound a screen holds");
	}

	@Test
	public function testSoundFilesOfTheFilesOwnBlocksAndAMixThatIsNoNeed() {
		final n = needs('
			#fx sounds {
				coin { file: "sound/coin.wav" }
				hit { files: ["sound/hit_1.wav", "sound/hit_2.wav"], pick: shuffle }
				explosion {
					layer boom { files: ["sound/boom.wav"] }
					layer debris { file: "sound/debris.wav", delay: 40..120ms, chance: 70% }
				}
			}
			#music music {
				track title { file: "music/title.mp3", loop: yes }
			}
			#main mix {
				bus music
				bus sfx { voices: 24 }
				vca Effects: sfx
				snapshot paused { sfx: pause, fade: 200ms }
			}
		');
		Assert.same(["music/title.mp3", "sound/boom.wav", "sound/coin.wav", "sound/debris.wav", "sound/hit_1.wav", "sound/hit_2.wav"], n.soundFiles);
		Assert.same([], n.sounds);
		Assert.same([], n.music);
		Assert.same([], n.uiSounds);
	}

	@Test
	public function testUiBankKeysTheWidgetsPlayByDefault() {
		final button = needs('
			#button programmable(buttonText:string=Click, status:[normal,hover,pressed]=normal) {
				bitmap(sheet("ui", "button")): 0, 0
			}
		');
		Assert.same(["click", "hover"], button.uiSounds);

		final checkbox = needs('
			#checkbox programmable(checked:bool=false, status:[normal,hover,pressed]=normal, disabled:bool=false) {
				bitmap(sheet("ui", "box")): 0, 0
			}
		');
		Assert.same(["change", "toggle"], checkbox.uiSounds, "a checkbox toggles; a tab or radio button drawn the same changes");

		final dropdown = needs('
			#dropdown programmable(status:[normal,hover,pressed]=normal, panel:[open,closed]=closed) {
				settings { sound.open => none }
				bitmap(sheet("ui", "arrow")): 0, 0
			}
		');
		Assert.same(["change", "close"], dropdown.uiSounds);

		final slider = needs('
			#slider programmable(status:[normal,hover,pressed]=normal, size:int=100, value:int=0, disabled:bool=false) {
				bitmap(sheet("ui", "knob")): 0, 0
			}
		');
		Assert.same(["change"], slider.uiSounds);

		final scrollbar = needs('
			#bar programmable(panelHeight:int=100, scrollableHeight:int=200, scrollPosition:int=0) {
				bitmap(sheet("ui", "thumb")): 0, 0
			}
		');
		Assert.same(["change"], scrollbar.uiSounds, "a scrollbar with no status");

		final item = needs('
			#item programmable(itemWidth:int=100, index:int=0, title:string="", status:[normal,hover]=normal, selected:bool=false, disabled:bool=false) {
				bitmap(sheet("ui", "row")): 0, 0
			}
		');
		Assert.same(["change"], item.uiSounds);

		final others = needs('
			#panel programmable(width:int=10) {
				bitmap(sheet("ui", "panel")): 0, 0
			}
			#card programmable(status:[normal,hover,pressed,disabled]=normal, name:string="") {
				bitmap(sheet("ui", "card")): 0, 0
			}
			#input programmable(status:[normal,hover,focused,disabled]=normal, placeholder:bool=true) {
				bitmap(sheet("ui", "field")): 0, 0
			}
		');
		Assert.same([], others.uiSounds, "a panel, a card and a text input play nothing of the bank");
	}

	@Test
	public function testAnInteractiveThatDoesNotClickPlaysNoClick() {
		final n = needs('
			#p programmable() {
				interactive(10, 10, "tip", events: [hover]): 0, 0
			}
		');
		Assert.same([], n.uiSounds);
	}

	@Test
	public function testASoundNamedThroughAParameterSaysSo() {
		final n = needs('
			#button programmable(buttonText:string=Click, status:[normal,hover,pressed]=normal, snd:string="fx.a") {
				settings { sound.click => $$snd }
				bitmap(sheet("ui", "button")): 0, 0
			}
		');
		Assert.isTrue(n.fromParameters);
		Assert.same(["fx.a"], n.sounds, "the default is listed; others can be given");
		Assert.same(["hover"], n.uiSounds);
	}

	@Test
	public function testCursorsATilesetAndATileMap() {
		final n = needs('
			#cursors cursor {
				pointer: sheet("ui", "hand"), hot: 1, 1
				sword: file("sword.png"), hot: 0, 0
			}
			#grass autotile {
				format: blob47
				tileSize: 16
				sheet: "terrain", prefix: "grass_"
			}
			#ts tileset {
				tileSize: 16
				atlas: "terrain"
				edge: grass
				terrain ground { autotile: grass }
				terrain stones { cells: "stone" }
				rise 1 { side: "cliff" left: "cliffEnd" span: 1 }
				cell skull { }
			}
			#map tilemap {
				tileset: ts
				size: 2, 1
				legend { "g": ground }
				terrain: ["gg"]
				layer props {
					legend { "s": skull }
					rows: ["s "]
				}
			}
		');
		Assert.same(["hand"], cells(n, "ui"));
		Assert.same(["sword.png"], n.tiles);
		Assert.isNull(cells(n, "terrain"), "an autotile\'s prefix takes the whole sheet");
	}

	@Test
	public function testATilesetsAtlasWithItsCellsAndATileMapsLayer() {
		final n = needs('
			#rim autotile {
				format: blob47
				tileSize: 16
				demo: #00FF00, #008800
			}
			#ts tileset {
				tileSize: 16
				atlas: "terrain"
				edge: rim
				terrain ground { autotile: rim }
				terrain stones { cells: "stone" }
				rise 1 { side: "cliff" left: "cliffEnd" span: 1 }
				cell skull { }
			}
			#map tilemap {
				tileset: ts
				size: 2, 1
				legend { "g": ground }
				terrain: ["gg"]
				layer props {
					legend { "s": skull }
					rows: ["s "]
				}
				layer marks {
					sheet: "icons"
					legend { "x": cross }
					rows: ["x "]
				}
			}
		');
		Assert.same(["cliff", "cliffEnd", "skull", "stone"], cells(n, "terrain"));
		Assert.same(["cross"], cells(n, "icons"));
		Assert.isFalse(n.fromParameters);
	}

	@Test
	public function testATileMapOfAnImportedTilesetListsOnlyItsOwnSheets() {
		final n = needs('import "world.manim" as "world"
			#map tilemap {
				tileset: external(world), ts
				size: 2, 1
				legend { "g": ground }
				terrain: ["gg"]
				layer props {
					legend { "s": skull }
					rows: ["s "]
				}
				layer marks {
					sheet: "icons"
					legend { "x": cross }
					rows: ["x "]
				}
			}
		');
		Assert.same(["icons"], keys(n.sheets), "the imported tileset\'s atlas is in the import\'s own needs");
		Assert.same(["cross"], cells(n, "icons"));
		Assert.equals("world.manim", n.imports.get("world"));
	}

	@Test
	public function testAFillNeedsItsTilesetsSheetsAsAPlacedMapDoes() {
		// tilemap(fill(…)) of a tileset of this file: the tileset's atlas with its cells and its
		// autotiles' files, as for tilemap(name); of an imported tileset: the import, whose own
		// needs list the rest. A terrain is a name in the tileset, not a sheet's: nothing more.
		final n = needs('import "world.manim" as "world"
			#dirt autotile { format: corner tileSize: 8 file: "dirt.png" }
			#ts tileset {
				tileSize: 8
				atlas: "terrain"
				terrain grass { cells: "grass" }
				terrain dirt { autotile: dirt }
			}
			#patch programmable(terrain:[grass, dirt]=grass, cols:uint=6, rows:uint=4) {
				tilemap(fill(ts, terrain: $$terrain, cols: $$cols, rows: $$rows)): 0, 0
				tilemap(fill(external("world"), ts, terrain: stone, cols: 2, rows: 2)): 0, 60
			}
		');
		Assert.same(["terrain"], keys(n.sheets));
		Assert.same(["grass"], cells(n, "terrain"));
		Assert.same(["dirt.png"], n.tiles);
		Assert.equals("world.manim", n.imports.get("world"));
		Assert.isFalse(n.fromParameters);
	}

	@Test
	public function testAnAnimFilesSheetFramesAndSounds() {
		final n = animNeeds('
sheet: "crew"
states: dir(l, r)
fps: 10
sounds {
	fire: "fx.shot"
	step: "fx.step"
	land: "fx.step"
	hold idle: "amb.hum"
}
animation idle { playlist { sheet: "idle_$${dir}" frames: 0..1 } }
animation jump {
	playlist {
		sheet: "jump"
		file: "extra/pose.png"
		event fire
	}
}
');
		Assert.same(["crew"], keys(n.sheets));
		Assert.same(["idle_l", "idle_r", "jump"], n.sheets.get("crew"));
		Assert.same(["extra/pose.png"], n.files);
		Assert.same(["amb.hum", "fx.shot", "fx.step"], n.sounds, "the events' sounds and the held one");
	}

	@Test
	public function testAnAnimFileWithLayersAndNoSounds() {
		final n = animNeeds('
sheet: "wolf"
states: hat(none, cap)
layers: body, hat
fps: 10
animation walk {
	layer body { sheet: "walk" }
	layer hat @(hat != none) { sheet: "hat_$${hat}" }
}
');
		Assert.same(["hat_cap", "hat_none", "walk"], n.sheets.get("wolf"));
		Assert.same([], n.sounds);
		Assert.same([], n.files);
	}

	@Test
	public function testExpandStates() {
		final states:Map<String, Array<String>> = ["dir" => ["l", "r"], "arm" => ["a", "b"]];
		final out = ManimNeedsTools.expandStates("w_${dir}_${arm}", states);
		out.sort(Reflect.compare);
		Assert.same(["w_l_a", "w_l_b", "w_r_a", "w_r_b"], out);
		Assert.same(["plain"], ManimNeedsTools.expandStates("plain", states));
	}
}
