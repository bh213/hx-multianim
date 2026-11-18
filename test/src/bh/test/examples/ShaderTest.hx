package bh.test.examples;

import bh.base.FilterManager;
import bh.base.ShaderClock;
import bh.base.filters.EngineShaderFilter;
import bh.base.filters.StageFade;
import bh.multianim.ShaderCatalog;
import bh.test.BuilderTestBase.BuildMode;
import bh.test.BuilderTestBase.buildFromSource;
import bh.test.BuilderTestBase.builderFromSource;
import bh.ui.screens.ScreenManager;
import utest.Assert;

/**
	The engine's shaders (ShaderCatalog, BuiltinShaders): each described and made, written by name or by
	position, held to its parameters, set in place when a `$param` changes (never made again), as a
	ground drawn from nothing, over the whole stage with a crossfade, and moving by the game's clock.
**/
@:access(bh.ui.screens.ScreenManager)
class ShaderTest extends utest.Test {
	final managers:Array<ScreenManager> = [];

	function teardown():Void {
		for (sm in managers)
			sm.dispose();
		managers.resize(0);
		ShaderClock.reset();
	}

	static function expectError(fn:() -> Void):Null<String> {
		try {
			fn();
			return null;
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	static function shaderOf(f:Null<h2d.filter.Filter>):EngineShaderFilter {
		Assert.isTrue(f is EngineShaderFilter, 'a shader filter, not $f');
		return cast f;
	}

	@Test
	public function testEveryShaderIsDescribedAndMade():Void {
		Assert.equals(19, ShaderCatalog.shaders.length);
		for (info in ShaderCatalog.shaders) {
			Assert.isTrue(info.says.length > 0, info.name + ' says what it does');
			Assert.isTrue(info.places.length > 0, info.name + ' says where it goes');
			for (p in info.params) {
				Assert.notNull(p.label, info.name + '.' + p.name + ' has a label');
				switch p.type {
					case CFFloat | CFInt:
						Assert.isTrue(p.min != null && p.max != null && p.step != null, info.name + '.' + p.name + ' has a range');
						final d:Float = p.defaultValue;
						Assert.isTrue(d >= p.min && d <= p.max, info.name + '.' + p.name + ': its default is in its range');
					default:
				}
			}
			// Made with every value at its default, a palette's too
			final made = shaderOf(FilterManager.buildCustomFilter(info.name, []));
			Assert.equals(info.name.toLowerCase(), made.shaderName);
			for (p in info.params)
				Assert.isTrue(made.values.exists(p.name), info.name + ' was given ' + p.name);
		}
	}

	@Test
	public function testWrittenByNameOrPosition():Void {
		final result = buildFromSource("
			#test programmable() {
				#a bitmap(generated(color(8, 8, #f00))) { filter: crt(0.2, lineSize: 4, flicker: 0) pos: 0, 0 }
				#b bitmap(generated(color(8, 8, #f00))) { filter: vignette(strength: 0.8, color: #102030) pos: 0, 0 }
				#c bitmap(generated(color(8, 8, #f00))) { filter: group(outline(1, #000000), flash(#FF0000, 0.5)) pos: 0, 0 }
			}
		", "test", null, Incremental);
		final crt = shaderOf(result.getNamedDrawn("a").filter);
		Assert.floatEquals(0.2, crt.values["curve"]);
		Assert.equals(4, crt.values["lineSize"]);
		Assert.floatEquals(0.35, crt.values["scanlines"], "left out: its default");
		final vignette = shaderOf(result.getNamedDrawn("b").filter);
		Assert.floatEquals(0.8, vignette.values["strength"]);
		Assert.equals(0x102030, (vignette.values["color"] : Int) & 0xFFFFFF, "a colour, its alpha full");
		Assert.isTrue(result.getNamedDrawn("c").filter is h2d.filter.Group);
	}

	@Test
	public function testHeldToItsParameters():Void {
		final validate = (src:String) -> expectError(() -> builderFromSource(src).validateCustomFilters());
		Assert.isNull(validate("#t programmable() { filter: crt(curve: 0.1, scanlines: 0.2)\n bitmap(generated(color(4, 4, #fff))): 0, 0 }"));
		Assert.stringContains("has no parameter \"bend\"", validate("#t programmable() { filter: crt(bend: 0.1)\n bitmap(generated(color(4, 4, #fff))): 0, 0 }"));
		Assert.stringContains("cannot follow one by name", validate("#t programmable() { filter: crt(curve: 0.1, 0.2)\n bitmap(generated(color(4, 4, #fff))): 0, 0 }"));
		Assert.stringContains("given twice", validate("#t programmable() { filter: crt(0.1, curve: 0.2)\n bitmap(generated(color(4, 4, #fff))): 0, 0 }"));
		// paletteLock given no palette holds to its own
		Assert.isNull(validate("#t programmable() { filter: paletteLock(dither: 0.5)\n bitmap(generated(color(4, 4, #fff))): 0, 0 }"));
		Assert.stringContains("expects CFColor", validate("#t programmable() { filter: flash(color: 0.5)\n bitmap(generated(color(4, 4, #fff))): 0, 0 }"));
		// A bare word is a word, but callback(…) is still a number
		Assert.isNull(validate("#t programmable() { filter: flash(amount: callback(\"hit\"))\n bitmap(generated(color(4, 4, #fff))): 0, 0 }"));
		// A game may not take one of the engine's names
		Assert.stringContains("engine's shaders", expectError(() -> FilterManager.registerFilter("CRT", [], _ -> new h2d.filter.Blur())));
	}

	@Test
	public function testAPaletteByItsName():Void {
		final result = buildFromSource("
			#gameboy palette { #0F380F #306230 #8BAC0F #9BBC0F }
			#test programmable() {
				#a bitmap(generated(color(8, 8, #f00))) { filter: paletteLock(palette: gameboy, dither: 0.25) pos: 0, 0 }
			}
		", "test", null, Incremental);
		final lock = shaderOf(result.getNamedDrawn("a").filter);
		Assert.same([0x0F380F, 0x306230, 0x8BAC0F, 0x9BBC0F], [for (c in (lock.values["palette"] : Array<Int>)) c & 0xFFFFFF]);
		Assert.floatEquals(0.25, lock.values["dither"]);
		// None given: Sweetie 16
		final plain = shaderOf(FilterManager.buildCustomFilter("paletteLock", []));
		Assert.same(bh.multianim.ShaderCatalog.SWEETIE_16, plain.values["palette"]);
		// A game's own palette made the default, and the catalogue's put back
		FilterManager.setParamDefault("paletteLock", "palette", [0x0F380F, 0x9BBC0F]);
		Assert.same([0x0F380F, 0x9BBC0F], shaderOf(FilterManager.buildCustomFilter("paletteLock", [])).values["palette"]);
		Assert.same(bh.multianim.ShaderCatalog.SWEETIE_16, bh.multianim.ShaderCatalog.find("paletteLock").params[0].defaultValue);
		FilterManager.setParamDefault("paletteLock", "palette", null);
		Assert.same(bh.multianim.ShaderCatalog.SWEETIE_16, shaderOf(FilterManager.buildCustomFilter("paletteLock", [])).values["palette"]);
		Assert.stringContains("no parameter", expectError(() -> FilterManager.setParamDefault("paletteLock", "colours", [])));
	}

	@Test
	public function testSetInPlaceWhenAParamChanges():Void {
		final result = buildFromSource("
			#test programmable(hit:float=0, edge:color=#FF8A20) {
				#hero bitmap(generated(color(8, 8, #f00))) { filter: flash(amount: $hit) pos: 0, 0 }
				#gone bitmap(generated(color(8, 8, #f00))) { filter: dissolve(amount: $hit, edgeColor: $edge) pos: 0, 0 }
			}
		", "test", null, Incremental);
		final flash = shaderOf(result.getNamedDrawn("hero").filter);
		final dissolve = shaderOf(result.getNamedDrawn("gone").filter);
		Assert.floatEquals(0, flash.values["amount"]);
		result.setParameter("hit", 0.75);
		result.setParameter("edge", 0x00FF00);
		Assert.equals((flash : h2d.filter.Filter), result.getNamedDrawn("hero").filter, "the same filter, set in place");
		Assert.equals((dissolve : h2d.filter.Filter), result.getNamedDrawn("gone").filter, "the same filter, set in place");
		Assert.floatEquals(0.75, flash.values["amount"]);
		Assert.floatEquals(0.75, dissolve.values["amount"]);
		Assert.equals(0x00FF00, (dissolve.values["edgeColor"] : Int) & 0xFFFFFF);
		Assert.floatEquals(0.06, dissolve.values["edge"], "what was not given keeps its default");
	}

	@Test
	public function testSetInPlaceInGeneratedCode():Void {
		final mp = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false));
		final made:Dynamic = mp.shaderInPlace.create();
		final bitmaps = bh.test.BuilderTestBase.findVisibleBitmapDescendants(cast made);
		final hero = bitmaps[0], sea = bitmaps[1];
		final before = shaderOf(hero.filter);
		made.setHit(0.5);
		Assert.equals((before : h2d.filter.Filter), hero.filter, "the generated setter sets it in place");
		Assert.floatEquals(0.5, before.values["amount"]);
		final ground = shaderOf(sea.filter);
		Assert.equals("water", ground.shaderName);
		Assert.isTrue(ground.values["ground"]);
		made.setSpeed(2.0);
		Assert.equals((ground : h2d.filter.Filter), sea.filter, "a ground set in place too");
		Assert.floatEquals(2.0, ground.values["speed"]);
	}

	@Test
	public function testAShaderInASwitchArmIsSetInPlace():Void {
		final result = buildFromSource("
			#test programmable(mode:[calm, hurt]=hurt, hit:float=0, speed:float=0.5) {
				@switch(mode) {
					hurt {
						#hero bitmap(generated(color(8, 8, #f00))) { filter: flash(amount: $hit) pos: 0, 0 }
						#sea bitmap(generated(shader(water, 32, 16, speed: $speed))): 10, 0
					}
					default: bitmap(generated(color(8, 8, #0f0))): 0, 0;
				}
			}
		", "test", null, Incremental);
		final hero = result.getNamedDrawn("hero");
		final sea:h2d.Bitmap = cast result.getNamedDrawn("sea");
		final flash = shaderOf(hero.filter);
		final water = shaderOf(sea.filter);
		result.setParameter("hit", 0.75);
		result.setParameter("speed", 2.0);
		Assert.equals(hero, result.getNamedDrawn("hero"), "the arm is not built again for a shader's value");
		Assert.equals((flash : h2d.filter.Filter), hero.filter, "its shader set in place");
		Assert.floatEquals(0.75, flash.values["amount"]);
		Assert.equals((sea : h2d.Object), result.getNamedDrawn("sea"), "nor for a ground's");
		Assert.equals((water : h2d.filter.Filter), sea.filter, "the ground's shader set in place");
		Assert.floatEquals(2.0, water.values["speed"]);
		// Another arm and back: built again with the values set, and set in place from then on
		result.setParameter("mode", "calm");
		result.setParameter("mode", "hurt");
		final again = result.getNamedDrawn("hero");
		Assert.notEquals(hero, again);
		Assert.floatEquals(0.75, shaderOf(again.filter).values["amount"]);
		result.setParameter("hit", 0.25);
		Assert.equals(again, result.getNamedDrawn("hero"));
		Assert.floatEquals(0.25, shaderOf(again.filter).values["amount"]);
	}

	@Test
	public function testAShaderValueTheArmUsesElsewhereStillUpdatesAll():Void {
		final result = buildFromSource("
			#test programmable(mode:[a, b]=a, hit:float=0.2) {
				@switch(mode) {
					a {
						#hero bitmap(generated(color(8, 8, #f00))) { filter: flash(amount: $hit) alpha: $hit pos: 0, 0 }
					}
					default: bitmap(generated(color(8, 8, #0f0))): 0, 0;
				}
			}
		", "test", null, Incremental);
		result.setParameter("hit", 0.5);
		final hero = result.getNamedDrawn("hero");
		Assert.floatEquals(0.5, hero.alpha, "the alpha that uses it follows");
		Assert.floatEquals(0.5, shaderOf(hero.filter).values["amount"], "and the shader");
	}

	@Test
	public function testAShaderValueAMaskInTheArmUsesStillBuildsTheArm():Void {
		// A mask's size is not among what an arm's change is matched against: an arm with one is built
		// again for any change, its shaders' too, so the mask follows as before
		final result = buildFromSource("
			#test programmable(mode:[a, b]=a, w:float=0.5) {
				@switch(mode) {
					a {
						#m mask($w * 20, 8) {
							#hero bitmap(generated(color(8, 8, #f00))) { filter: flash(amount: $w) pos: 0, 0 }
						}
					}
					default: bitmap(generated(color(8, 8, #0f0))): 0, 0;
				}
			}
		", "test", null, Incremental);
		result.setParameter("w", 1.0);
		final m:h2d.Mask = cast result.getNamedDrawn("m");
		Assert.equals(20, m.width, "the mask follows");
		Assert.floatEquals(1.0, shaderOf(result.getNamedDrawn("hero").filter).values["amount"], "and the shader");
	}

	@Test
	public function testAShaderInASwitchArmIsSetInPlaceInGeneratedCode():Void {
		final mp = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false));
		final made:Dynamic = mp.shaderSwitch.create();
		final bitmaps = bh.test.BuilderTestBase.findVisibleBitmapDescendants(cast made);
		final hero = bitmaps[0], sea = bitmaps[1];
		final flash = shaderOf(hero.filter);
		final water = shaderOf(sea.filter);
		made.setHit(0.5);
		made.setSpeed(2.0);
		final after = bh.test.BuilderTestBase.findVisibleBitmapDescendants(cast made);
		Assert.equals(hero, after[0], "codegen: the arm is not built again for a shader's value");
		Assert.equals((flash : h2d.filter.Filter), hero.filter, "codegen: its shader set in place");
		Assert.floatEquals(0.5, flash.values["amount"]);
		Assert.equals(sea, after[1], "codegen: nor for a ground's");
		Assert.equals((water : h2d.filter.Filter), sea.filter);
		Assert.floatEquals(2.0, water.values["speed"]);
	}

	@Test
	public function testAGroundInARepeatCountedByAParamHasItsShaderInGeneratedCode():Void {
		final mp = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false));
		final made:Dynamic = mp.shaderGroundRepeat.create();
		var bitmaps = bh.test.BuilderTestBase.findVisibleBitmapDescendants(cast made);
		Assert.equals(2, bitmaps.length);
		for (b in bitmaps)
			Assert.isTrue(b.filter is EngineShaderFilter, "codegen: a ground in a repeat built at run time is drawn by its shader, not a white tile");
		made.setN(3);
		bitmaps = bh.test.BuilderTestBase.findVisibleBitmapDescendants(cast made);
		Assert.equals(3, bitmaps.length);
		for (b in bitmaps)
			Assert.isTrue(b.filter is EngineShaderFilter, "codegen: and after the repeat is built again");
	}

	@Test
	public function testAGroundDrawnFromNothing():Void {
		final result = buildFromSource("
			#test programmable(speed:float=0.5) {
				#sea bitmap(generated(shader(water, 64, 32, speed: $speed, deep: #001020))): 0, 0
				#mist bitmap(generated(shader(fog, 16, 16))): 0, 0
			}
		", "test", null, Incremental);
		final sea:h2d.Bitmap = cast result.getNamedDrawn("sea");
		Assert.equals(64, Std.int(sea.tile.width));
		Assert.equals(32, Std.int(sea.tile.height));
		final water = shaderOf(sea.filter);
		Assert.equals("water", water.shaderName);
		Assert.isTrue(water.values["ground"], "told it draws from nothing");
		Assert.equals(0x001020, (water.values["deep"] : Int) & 0xFFFFFF);
		result.setParameter("speed", 1.5);
		Assert.equals((water : h2d.filter.Filter), sea.filter, "set in place");
		Assert.floatEquals(1.5, water.values["speed"]);
		final fog = shaderOf(result.getNamedDrawn("mist").filter);
		Assert.isTrue(fog.values["ground"]);
	}

	@Test
	public function testAGroundKeepsItsAlignmentWhenItsSizeChanges():Void {
		final result = buildFromSource("
			#test programmable(w:uint=32) {
				#sea bitmap(generated(shader(water, $w, 16)), center): 0, 0
			}
		", "test", null, Incremental);
		final sea:h2d.Bitmap = cast result.getNamedDrawn("sea");
		final water = sea.filter;
		Assert.floatEquals(-16, sea.tile.dx);
		result.setParameter("w", 64);
		Assert.equals(64, Std.int(sea.tile.width));
		Assert.floatEquals(-32, sea.tile.dx, "centred still");
		Assert.equals(water, sea.filter, "its shader set in place");
	}

	@Test
	public function testAGroundOnlyAsABitmapsOwnTile():Void {
		final parse = bh.test.BuilderTestBase.parseExpectingError;
		Assert.stringContains("only a bitmap's own tile",
			parse("#t programmable() { bitmap(center(generated(shader(water, 8, 8)))): 0, 0 }"));
		Assert.stringContains("tilegroup",
			parse("#t programmable() { tilegroup { bitmap(generated(shader(water, 8, 8))): 0, 0 } }"));
		Assert.stringContains("tilegroup",
			parse("#t programmable tileGroup() { bitmap(generated(shader(water, 8, 8))): 0, 0 }"));
		// Its shader is the bitmap's filter: no other may take its place
		Assert.stringContains("a ground's shader is its bitmap's filter",
			parse("#t programmable() { bitmap(generated(shader(water, 8, 8))) { filter: outline(1, #000000) pos: 0, 0 } }"));
		Assert.stringContains("a ground's shader is its bitmap's filter",
			parse("#t programmable() { bitmap(generated(shader(water, 8, 8))) { apply { filter: outline(1, #000000) } } }"));
		// A filter over it from outside is fine
		Assert.isNull(parse("#t programmable() { layers() { filter: outline(1, #000000) bitmap(generated(shader(water, 8, 8))): 0, 0 } }"));
	}

	@Test
	public function testAPaletteByAnEnumParameter():Void {
		final gameboy = [0x0F380F, 0x306230, 0x8BAC0F, 0x9BBC0F];
		final mono = [0x000000, 0xFFFFFF];
		final colors = (f:Null<h2d.filter.Filter>) -> [for (c in (shaderOf(f).values["palette"] : Array<Int>)) c & 0xFFFFFF];
		// The builder gives the palette the value's name
		final result = bh.test.BuilderTestBase.buildFromFile("test/examples/166-shaders/shaders.manim", "shaderPalette", null, Incremental);
		final built = result.getNamedDrawn("a");
		final first = built.filter;
		Assert.same(gameboy, colors(first));
		result.setParameter("pal", "mono");
		Assert.equals(first, built.filter, "set in place");
		Assert.same(mono, colors(built.filter));
		// Generated code too: the name, not the index
		final mp = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false));
		final made = mp.shaderPalette.create();
		final bitmap = bh.test.BuilderTestBase.findVisibleBitmapDescendants(made)[0];
		final made0 = bitmap.filter;
		Assert.same(gameboy, colors(made0));
		made.setParameter("pal", "mono");
		Assert.equals(made0, bitmap.filter, "set in place");
		Assert.same(mono, colors(bitmap.filter));
	}

	@Test
	public function testAnApplysShaderIsMadeAgainInBothBackends():Void {
		// An apply's filter is never set in place: the parent's own may be what is there, kept to be put back
		final result = bh.test.BuilderTestBase.buildFromFile("test/examples/166-shaders/shaders.manim", "shaderApply", null, Incremental);
		final builtRoot = result.getRoot();
		final builtFirst = shaderOf(builtRoot.filter);
		result.setParameter("hit", 0.5);
		Assert.notEquals((builtFirst : h2d.filter.Filter), builtRoot.filter, "builder: made again");
		Assert.floatEquals(0.5, shaderOf(builtRoot.filter).values["amount"]);
		Assert.floatEquals(0, builtFirst.values["amount"], "builder: the one before untouched");
		final mp = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false));
		final made = mp.shaderApply.create();
		final madeFirst = shaderOf(made.filter);
		made.setParameter("hit", 0.5);
		Assert.notEquals((madeFirst : h2d.filter.Filter), made.filter, "codegen: made again, as the builder");
		Assert.floatEquals(0.5, shaderOf(made.filter).values["amount"]);
		Assert.floatEquals(0, madeFirst.values["amount"], "codegen: the one before untouched");
	}

	@Test
	public function testAColourByItsName():Void {
		final validate = (src:String) -> expectError(() -> builderFromSource(src).validateCustomFilters());
		Assert.isNull(validate("#t programmable() { filter: vignette(color: black)\n bitmap(generated(color(4, 4, #fff))): 0, 0 }"));
		Assert.stringContains("expects CFColor, got CFWord",
			validate("#t programmable() { filter: vignette(color: dusk)\n bitmap(generated(color(4, 4, #fff))): 0, 0 }"));
		final result = buildFromSource("
			#test programmable() {
				#a bitmap(generated(color(8, 8, #f00))) { filter: vignette(color: red) pos: 0, 0 }
			}
		", "test", null, Incremental);
		Assert.equals(0xFF0000, (shaderOf(result.getNamedDrawn("a").filter).values["color"] : Int) & 0xFFFFFF);
		// As generated code gives it: the name, read by FilterManager
		final made = shaderOf(FilterManager.buildCustomFilter("vignette", [{name: "color", value: "red"}]));
		Assert.equals(0xFF0000, (made.values["color"] : Int) & 0xFFFFFF);
		Assert.stringContains("expects a colour", expectError(() -> FilterManager.buildCustomFilter("vignette", [{name: "color", value: "dusk"}])));
	}

	@Test
	public function testNeedsSayTheShadersApart():Void {
		final n = bh.multianim.ManimNeeds.ManimNeedsTools.needsOf(bh.multianim.MacroManimParser.parseFile("version: 1.0\n
			#p programmable() {
				bitmap(generated(shader(stars, 32, 32))): 0, 0
				bitmap(generated(color(4, 4, #fff))) { filter: group(crt(), perlinNoise(1.0, 10.0)) }
			}
		", "test", null));
		Assert.same(["perlinnoise"], n.filters);
		Assert.same(["crt", "stars"], n.shaders);
	}

	@Test
	public function testTheClockMovesThem():Void {
		ShaderClock.reset();
		final sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		managers.push(sm);
		sm.update(0.5);
		sm.update(0.25);
		Assert.floatEquals(0.75, ShaderClock.now(), "by the dt the game gives");
		sm.update(0);
		Assert.floatEquals(0.75, ShaderClock.now(), "a stopped game stops them");
		ShaderClock.fixed = 2.0;
		sm.update(1);
		Assert.floatEquals(2.0, ShaderClock.now(), "a capture's time holds");
		ShaderClock.fixed = null;
		Assert.floatEquals(1.75, ShaderClock.now());
	}

	// A shader's colour takes palette(…), as every other colour does
	@Test
	public function testAPaletteColourAsAnArgument():Void {
		final result = buildFromSource("
			#look palette { #8A4FB0 #FF8A3D #FFF4D6 }
			#test programmable() {
				#a bitmap(generated(color(8, 8, #f00))) { filter: vignette(strength: 0.5, color: palette(look, 1)) pos: 0, 0 }
				#b bitmap(generated(shader(stars, 16, 16, color: palette(look, 2)))): 0, 0
				#c bitmap(generated(color(8, 8, #f00))) { filter: flash(palette(look, 0), 0.5) pos: 0, 0 }
			}
		", "test", null, Incremental);
		Assert.equals(0xFF8A3D, (shaderOf(result.getNamedDrawn("a").filter).values["color"] : Int) & 0xFFFFFF, "a filter's colour by name");
		Assert.equals(0xFFF4D6, (shaderOf(result.getNamedDrawn("b").filter).values["color"] : Int) & 0xFFFFFF, "a ground's colour");
		Assert.equals(0x8A4FB0, (shaderOf(result.getNamedDrawn("c").filter).values["color"] : Int) & 0xFFFFFF, "by position");
	}

	// loopTime and loops beside time, worked out at full precision
	@Test
	public function testTheLoopedClock():Void {
		final shader = shaderOf(FilterManager.buildCustomFilter("crt", [])).shader;
		shader.setClock(100.5);
		Assert.floatEquals(100.5, shader.time);
		Assert.floatEquals(4.5, shader.loopTime, "seconds into a loop of 32");
		Assert.floatEquals(3, shader.loops, "the loops gone");
		shader.setClock(32 * 1024 * 2 + 33.25);
		Assert.floatEquals(1.25, shader.loopTime);
		Assert.floatEquals(1, shader.loops, "round again after 1024");
		shader.setClock(0);
		Assert.floatEquals(0, shader.loopTime);
		Assert.floatEquals(0, shader.loops);
	}

	// Fragment shaders at highp where the GPU has it: the build macro on hxsl.GlslOut (AtlasMacroInit.init())
	@Test
	public function testFragmentShadersAskForHighPrecision():Void {
		function glslOf(kind:hxsl.Ast.FunctionKind):String {
			final ref:hxsl.Ast.TVar = {id: 1, name: "main", type: TFun([]), kind: Function};
			final body:hxsl.Ast.TExpr = {e: TBlock([]), t: TVoid, p: null};
			return new hxsl.GlslOut().run({name: "probe", vars: [], funs: [{kind: kind, ref: ref, args: [], ret: TVoid, expr: body}]});
		}
		final fragment = glslOf(Fragment);
		Assert.stringContains("#ifdef GL_FRAGMENT_PRECISION_HIGH\nprecision highp float;\n#else\nprecision mediump float;\n#endif", fragment);
		Assert.isTrue(fragment.indexOf("precision mediump float;") > fragment.indexOf("#else"), "mediump only where highp is missing");
		Assert.stringContains("precision highp float;", glslOf(Vertex), "a vertex shader keeps Heaps' highp");
	}

	/** The colour drawn at (x, y) of an object drawn alone into a 32 by 16 picture. **/
	static function pixelAt(o:h2d.Object, x:Int, y:Int):Int {
		final scene = new h2d.Scene();
		scene.addChild(o);
		scene.syncOnly(0);
		final texture = new h3d.mat.Texture(32, 16, [Target]);
		texture.clear(0, 0);
		o.drawTo(texture);
		final pixels = texture.capturePixels();
		texture.dispose();
		o.remove();
		scene.dispose();
		pixels.convert(BGRA);
		return pixels.getPixel(x, y);
	}

	// A ground half off the stage is drawn whole: its calculatedUV and size mean the whole tile, not
	// the part on screen
	@Test
	public function testAGroundHalfOffTheStageIsDrawnWhole():Void {
		FilterManager.registerFilter("uvprobe", [], params -> EngineShaderFilter.of("uvprobe", new UvProbeShader(), (s, p) -> {}, params));
		final source = "#test programmable() { bitmap(generated(shader(uvprobe, 32, 16))): -16, 0 }";
		try {
			// the stage's left edge is the ground's middle: red there is u of 16.5 / 32
			final red = (pixelAt(buildFromSource(source, "test", null, Incremental).object, 0, 8) >> 16) & 0xFF;
			Assert.isTrue(red > 120 && red < 140, 'the left edge of the stage shades the middle of the ground (red $red)');
			final offStage = buildFromSource("#test programmable() { #g bitmap(generated(shader(uvprobe, 32, 16))): -16, 0 }", "test", null, Incremental);
			final offStageFilter = shaderOf(offStage.getNamedDrawn("g").filter);
			final right = (pixelAt(offStage.object, 15, 8) >> 16) & 0xFF;
			Assert.isTrue(right > 240, 'the right edge of the part shown shades the ground\'s right edge (red $right)');
			Assert.notNull(@:privateAccess offStageFilter.place, "drawn off the stage, the filter made its placing pass");
			// on the stage it is drawn as Heaps gives it: no placing pass made
			final onStage = buildFromSource("#test programmable() { #g bitmap(generated(shader(uvprobe, 32, 16))): 0, 0 }", "test", null, Incremental);
			final onStageFilter = shaderOf(onStage.getNamedDrawn("g").filter);
			pixelAt(onStage.object, 0, 8);
			Assert.isNull(@:privateAccess onStageFilter.place, "drawn whole on the stage, no placing pass is made");
			// past the limit it shades only the part on the stage, as Heaps cut it: the whole picture squeezed into it
			EngineShaderFilter.wholeLimit = 0;
			final cut = (pixelAt(buildFromSource(source, "test", null, Incremental).object, 0, 8) >> 16) & 0xFF;
			Assert.isTrue(cut < 20, 'cut to the stage, the part starts at u 0 (red $cut)');
		} catch (e:Dynamic) {
			Assert.fail(Std.string(e));
		}
		EngineShaderFilter.wholeLimit = 4096;
		FilterManager.unregisterFilter("uvprobe");
	}

	@Test
	public function testOverTheStageWithACrossfade():Void {
		final sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		managers.push(sm);
		final scene = bh.test.VisualTestBase.appInstance.s2d;
		final crt = FilterManager.buildCustomFilter("crt", []);
		sm.setStageShader(crt, 0);
		Assert.equals(crt, scene.filter, "at once");
		final vignette = FilterManager.buildCustomFilter("vignette", []);
		sm.setStageShader(vignette, 0.5);
		Assert.isTrue(scene.filter is StageFade, "both drawn while one gives way");
		final fade:StageFade = cast scene.filter;
		Assert.equals(crt, fade.from);
		Assert.equals(vignette, fade.to);
		sm.update(0.25);
		Assert.floatEquals(0.5, fade.t);
		sm.update(0.3);
		Assert.equals(vignette, scene.filter, "the new one alone once it has come");
		Assert.equals(vignette, sm.stageShader);
		sm.setStageShader(null, 0);
		Assert.isNull(scene.filter);
	}

	@Test
	public function testEachScreenItsOwnADialogItsCallers():Void {
		final sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		managers.push(sm);
		final crt = FilterManager.buildCustomFilter("crt", []);
		final grade = FilterManager.buildCustomFilter("grade", [{name: "saturation", value: 0.3}]);
		final title = new ShaderScreen(sm), play = new ShaderScreen(sm), plain = new ShaderScreen(sm), pause = new ShaderScreen(sm);
		title.screenShader = crt;
		pause.screenShader = grade;
		plain.screenShaderOff = true;
		sm.screenShaderFade = 0;
		sm.defaultScreenShader = FilterManager.buildCustomFilter("vignette", []);
		sm.switchTo(title);
		Assert.equals(crt, sm.stageShader, "its own");
		sm.switchTo(play);
		Assert.equals(sm.defaultScreenShader, sm.stageShader, "one that says none: the default, not the screen before's");
		sm.modalDialog(pause, play, "pause");
		Assert.equals(sm.defaultScreenShader, sm.stageShader, "a dialog is drawn under its caller's");
		sm.updateScreenMode(Single(plain));
		Assert.isNull(sm.stageShader, "one that says off");
		// Every shader drawn as if not there: a game seen without them
		final flash = shaderOf(FilterManager.buildCustomFilter("flash", []));
		Assert.isTrue(flash.enable);
		EngineShaderFilter.off = true;
		Assert.isFalse(flash.enable);
		EngineShaderFilter.off = false;
		Assert.isTrue(flash.enable);
		bh.test.VisualTestBase.appInstance.s2d.filter = null;
	}

	@Test
	public function testDisposeTakesItsStageShaderOff():Void {
		final scene = bh.test.VisualTestBase.appInstance.s2d;
		final sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		final crt = FilterManager.buildCustomFilter("crt", []);
		sm.setStageShader(crt, 0);
		sm.dispose();
		Assert.isNull(scene.filter, "a disposed manager's shader is off the stage");
		Assert.isNull(sm.stageShader);
		// Mid-fade too
		final fading = new ScreenManager(bh.test.VisualTestBase.appInstance);
		fading.setStageShader(crt, 0);
		fading.setStageShader(FilterManager.buildCustomFilter("vignette", []), 0.5);
		Assert.isTrue(scene.filter is StageFade);
		fading.dispose();
		Assert.isNull(scene.filter, "the crossfade off too");
		// A filter the game put on the stage since is the game's
		final later = new ScreenManager(bh.test.VisualTestBase.appInstance);
		later.setStageShader(crt, 0);
		final own = new h2d.filter.Blur();
		scene.filter = own;
		later.dispose();
		Assert.equals((own : h2d.filter.Filter), scene.filter, "the game's own is left");
		scene.filter = null;
	}

	@Test
	public function testAGameThatSaysNoneKeepsItsOwnStageShader():Void {
		final sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		managers.push(sm);
		final own = FilterManager.buildCustomFilter("crt", []);
		sm.setStageShader(own, 0);
		sm.switchTo(new ShaderScreen(sm));
		Assert.equals(own, sm.stageShader, "no screen says one: the stage is left to the game");
		sm.setStageShader(null, 0);
	}
}

private class ShaderScreen extends bh.ui.screens.UIScreen.UIScreenBase {
	public function new(sm:ScreenManager) {
		super(sm);
	}

	public function load():Void {}

	public function onScreenEvent(event:bh.ui.UIElement.UIScreenEvent, source:Null<bh.ui.UIElement>):Void {}
}

/** Draws where it is in its tile: u as red, v as green. **/
private class UvProbeShader extends bh.base.filters.EngineScreenShader {
	static var SRC = {
		function fragment() {
			pixelColor = vec4(calculatedUV.x, calculatedUV.y, 0.0, 1.0);
		}
	};
}
