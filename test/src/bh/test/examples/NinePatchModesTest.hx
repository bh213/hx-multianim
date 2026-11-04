package bh.test.examples;

import utest.Assert;
import bh.base.AnimatedScaleGrid;
import bh.multianim.BuilderError;
import bh.test.BuilderTestBase;

/**
 * Nine-patch modes, parameters and frames (UI art adopted from a pack):
 *
 * - `ninepatch(sheet, tile, w, h [, stretch | tile])`: tiled by default, as before; `settings {
 *   ninepatch => stretch }` on the programmable is the default for every one in it; the element's
 *   own word wins; a `flow(background: ninepatch(…))` stretches unless told `tile`.
 * - the sheet and the cell as string expressions, followed by `setParameter`.
 * - `index: n` (a frame of an indexed name) and `fps: n` (the frames played in a loop).
 *
 * Builder and codegen alike. Fixture: test/examples/157-ninePatchModes/ninePatchModes.manim.
 */
class NinePatchModesTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/157-ninePatchModes/ninePatchModes.manim";
	static inline var WARNING = "Animated button test - Altcolor/Button_Warning_3x3_idle";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function scaleGrids(root:h2d.Object):Array<h2d.ScaleGrid> {
		final out:Array<h2d.ScaleGrid> = [];
		function walk(o:h2d.Object) {
			if (Std.isOfType(o, h2d.ScaleGrid))
				out.push(cast o);
			for (child in o)
				walk(child);
		}
		walk(root);
		return out;
	}

	static function firstGrid(root:h2d.Object):h2d.ScaleGrid {
		final grids = scaleGrids(root);
		Assert.isTrue(grids.length > 0, "a ScaleGrid is drawn");
		return grids[0];
	}

	static function flows(root:h2d.Object):Array<h2d.Flow> {
		final out:Array<h2d.Flow> = [];
		function walk(o:h2d.Object) {
			if (Std.isOfType(o, h2d.Flow))
				out.push(cast o);
			for (child in o)
				walk(child);
		}
		walk(root);
		return out;
	}

	static function background(f:h2d.Flow):h2d.ScaleGrid {
		return @:privateAccess f.background;
	}

	// ==================== Parsing ====================

	@Test
	public function testParsesEverySpelling():Void {
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#p programmable() { ninepatch("ui", "a", 10, 10): 0, 0 }'));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#p programmable() { ninepatch("ui", "a", 10, 10, stretch): 0, 0 }'));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#p programmable() { ninepatch("ui", "a", 10, 10, tile): 0, 0 }'));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#p programmable() { ninepatch("ui", "a", 10, 10, index: 2): 0, 0 }'));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#p programmable() { ninepatch("ui", "a", 10, 10, fps: 8): 0, 0 }'));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#p programmable(f:int=0) { ninepatch("ui", "a", 10, 10, fps: 8.5, index: $$f, stretch): 0, 0 }'));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#p programmable(s:string="ui", c:string="a") { ninepatch($$s, $$c, 10, 10): 0, 0 }'));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#p programmable(c:string="a") { ninepatch("ui", "button_" + $$c + "_hover", 10, 10): 0, 0 }'));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#p programmable() { ninepatch(ui, panel, 10, 10): 0, 0 }'));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#p programmable() { flow(background: ninepatch("ui", "a", tile)) { } }'));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#p programmable() { flow(background: ninepatch("ui", "a", stretch)) { } }'));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#p programmable() { settings { ninepatch => stretch } ninepatch("ui", "a", 10, 10): 0, 0 }'));
	}

	@Test
	public function testRejectsAWrongWord():Void {
		final error = BuilderTestBase.parseExpectingError('#p programmable() { ninepatch("ui", "a", 10, 10, repeat): 0, 0 }');
		Assert.notNull(error, "an unknown word after the size is a parse error");
		Assert.isTrue(error.indexOf("stretch") >= 0 && error.indexOf("tile") >= 0, 'the error names the words: $error');
		final twice = BuilderTestBase.parseExpectingError('#p programmable() { ninepatch("ui", "a", 10, 10, tile, stretch): 0, 0 }');
		Assert.notNull(twice, "stretch or tile given twice is a parse error");
		final flowError = BuilderTestBase.parseExpectingError('#p programmable() { flow(background: ninepatch("ui", "a", repeat)) { } }');
		Assert.notNull(flowError, "a wrong word on a flow background is a parse error");
		Assert.isTrue(flowError.indexOf("stretch") >= 0, 'the error names the words: $flowError');
	}

	// ==================== Modes: builder ====================

	@Test
	public function testBuilder_TilesByDefaultStretchesByWord():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "ninePatchModes", null);
		final grids = scaleGrids(result.object);
		Assert.isTrue(grids.length >= 7, 'the fixture draws seven grids, got ${grids.length}');
		Assert.isTrue(grids[0].tileCenter && grids[0].tileBorders, "a ninepatch with no word tiles, as before");
		Assert.isFalse(grids[1].tileCenter || grids[1].tileBorders, "`stretch` stretches the middle and the edges");
		Assert.isTrue(grids[2].tileCenter && grids[2].tileBorders, "`tile` tiles");
		for (g in grids)
			Assert.isFalse(g.ignoreScale);
	}

	@Test
	public function testBuilder_SettingsDefaultAndTheElementsWordWins():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "npSettings", null);
		final plain:h2d.ScaleGrid = cast result.names.get("plain")[0].getBuiltHeapsObject().toh2dObject();
		final tiled:h2d.ScaleGrid = cast result.names.get("tiled")[0].getBuiltHeapsObject().toh2dObject();
		Assert.isFalse(plain.tileCenter, "settings { ninepatch => stretch } is the default for a ninepatch that does not say");
		Assert.isTrue(tiled.tileCenter, "the element's own `tile` wins over the setting");
		final bg = background(flows(result.object)[0]);
		Assert.notNull(bg);
		Assert.isFalse(bg.tileCenter, "a flow background follows the setting too (stretch)");
	}

	@Test
	public function testBuilder_SettingsRejectsAWrongWord():Void {
		var threw:Null<BuilderError> = null;
		try {
			BuilderTestBase.buildFromSource('#p programmable() { settings { ninepatch => repeat } ninepatch("ui", "button-idle", 20, 20): 0, 0 }', "p");
		} catch (e:BuilderError) {
			threw = e;
		}
		Assert.notNull(threw, "settings { ninepatch => repeat } is a build error");
		if (threw != null)
			Assert.equals("ninepatch_mode", threw.code);
	}

	@Test
	public function testBuilder_FlowBackgroundStretchesUnlessToldTile():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "npFlowBg", null);
		final fl = flows(result.object);
		Assert.equals(2, fl.length);
		final stretched = background(fl[0]);
		final tiled = background(fl[1]);
		Assert.notNull(stretched);
		Assert.notNull(tiled);
		Assert.isFalse(stretched.tileCenter || stretched.tileBorders, "a flow background stretches by default");
		Assert.isTrue(tiled.tileCenter && tiled.tileBorders, "`tile` on a flow background tiles it");
	}

	@Test
	public function testBuilder_TileGroupTakesTheMode():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "npTileGroup", null);
		Assert.notNull(result.object, "a tile group bakes a tiled nine-patch as it bakes a stretched one");
		var threw = false;
		try {
			BuilderTestBase.buildFromSource('#p programmable tileGroup() { ninepatch("ui", "$WARNING", 20, 20, fps: 4): 0, 0 }', "p");
		} catch (e:Dynamic) {
			threw = true;
			Assert.isTrue(Std.string(e).indexOf("fps") >= 0, 'the error names fps: $e');
		}
		Assert.isTrue(threw, "an animated nine-patch cannot be baked into a tile group");
	}

	// ==================== Modes: codegen ====================

	@Test
	public function testCodegen_ModesMatchTheBuilder():Void {
		final inst:Dynamic = createMp().ninePatchModes.create();
		final grids = scaleGrids(cast inst);
		Assert.isTrue(grids.length >= 7, 'codegen draws seven grids, got ${grids.length}');
		Assert.isTrue(grids[0].tileCenter && grids[0].tileBorders, "codegen: no word tiles");
		Assert.isFalse(grids[1].tileCenter || grids[1].tileBorders, "codegen: `stretch` stretches");
		Assert.isTrue(grids[2].tileCenter && grids[2].tileBorders, "codegen: `tile` tiles");
		final fl = flows(cast inst);
		Assert.equals(2, fl.length, "codegen: two flows with backgrounds");
		Assert.isFalse(background(fl[0]).tileCenter, "codegen: a flow background stretches by default");
		Assert.isTrue(background(fl[1]).tileCenter, "codegen: `tile` on a flow background tiles it");
	}

	@Test
	public function testCodegen_SettingsDefault():Void {
		final inst:Dynamic = createMp().npSettings.create();
		final plain:h2d.ScaleGrid = cast inst.get_plain();
		final tiled:h2d.ScaleGrid = cast inst.get_tiled();
		Assert.isFalse(plain.tileCenter, "codegen: settings { ninepatch => stretch } is the default");
		Assert.isTrue(tiled.tileCenter, "codegen: the element's `tile` wins");
	}

	// ==================== The sheet and the cell as parameters ====================

	@Test
	public function testBuilder_CellFromAParameter():Void {
		final idle = firstGrid(BuilderTestBase.buildFromFile(FIXTURE, "npStyled", ["style" => "idle"]).object);
		final hover = firstGrid(BuilderTestBase.buildFromFile(FIXTURE, "npStyled", ["style" => "hover"]).object);
		Assert.isTrue(idle.tile.ix != hover.tile.ix || idle.tile.iy != hover.tile.iy, "two styles are two cells of the sheet");
		Assert.equals(100., idle.width);
		Assert.equals(40., idle.height);

		final bySheet = firstGrid(BuilderTestBase.buildFromFile(FIXTURE, "npParamSheet", ["sheet" => "ui", "cell" => "button-hover"]).object);
		Assert.equals(hover.tile.ix, bySheet.tile.ix, "ninepatch($sheet, $cell, …) resolves both references");
		Assert.equals(hover.tile.iy, bySheet.tile.iy);
		Assert.isFalse(bySheet.tileCenter, "the mode word still follows the parameters");
	}

	@Test
	public function testBuilder_SetParameterChangesTheDrawnCell():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "npStyled", ["style" => "idle"], Incremental);
		final sg = firstGrid(result.object);
		final idleX = sg.tile.ix, idleY = sg.tile.iy;
		result.setParameter("style", "hover");
		Assert.isTrue(sg.tile.ix != idleX || sg.tile.iy != idleY, "setParameter(style) reloads the cell into the same grid");
		final hover = firstGrid(BuilderTestBase.buildFromFile(FIXTURE, "npStyled", ["style" => "hover"]).object);
		Assert.equals(hover.tile.ix, sg.tile.ix);
		Assert.equals(hover.tile.iy, sg.tile.iy);
		Assert.equals(hover.borderLeft, sg.borderLeft, "the borders follow the cell");
		Assert.equals(1, scaleGrids(result.object).length, "no second grid is made");
	}

	@Test
	public function testCodegen_CellFromAParameterFollowsSetParameter():Void {
		final inst:Dynamic = createMp().npStyled.create("idle");
		final sg = firstGrid(cast inst);
		final idleX = sg.tile.ix, idleY = sg.tile.iy;
		inst.setParameter("style", "hover");
		Assert.isTrue(sg.tile.ix != idleX || sg.tile.iy != idleY, "codegen: setParameter(style) reloads the cell");
		final hover = firstGrid(BuilderTestBase.buildFromFile(FIXTURE, "npStyled", ["style" => "hover"]).object);
		Assert.equals(hover.tile.ix, sg.tile.ix, "codegen draws the cell the builder draws");
		Assert.equals(hover.tile.iy, sg.tile.iy);
		Assert.equals(1, scaleGrids(cast inst).length, "codegen: no second grid is made");
	}

	@Test
	public function testAMissingCellNamesTheSheetAndTheCell():Void {
		var message:Null<String> = null;
		try {
			BuilderTestBase.buildFromFile(FIXTURE, "npStyled", ["style" => "nope"]);
		} catch (e:BuilderError) {
			message = e.message;
		}
		Assert.notNull(message, "a cell the sheet has not is a build error");
		if (message != null) {
			Assert.isTrue(message.indexOf("button-nope") >= 0, 'the error names the cell: $message');
			Assert.isTrue(message.indexOf("ui") >= 0, 'the error names the sheet: $message');
		}
	}

	// ==================== Frames ====================

	@Test
	public function testBuilder_IndexIsAFrameOfTheName():Void {
		final frame0 = firstGrid(BuilderTestBase.buildFromFile(FIXTURE, "npFrame", ["frame" => 0]).object);
		final frame3 = firstGrid(BuilderTestBase.buildFromFile(FIXTURE, "npFrame", ["frame" => 3]).object);
		// test/res/ui.atlas2: the warning button's frames sit at (0,0), (0,30), (30,0), (30,30).
		Assert.equals(0, frame0.tile.ix);
		Assert.equals(0, frame0.tile.iy);
		Assert.equals(30, frame3.tile.ix, "index: 3 is the fourth frame's tile");
		Assert.equals(30, frame3.tile.iy);
		Assert.equals(10, frame3.borderLeft);

		var message:Null<String> = null;
		try {
			BuilderTestBase.buildFromFile(FIXTURE, "npFrame", ["frame" => 7]);
		} catch (e:BuilderError) {
			message = e.message;
		}
		Assert.notNull(message, "a frame the name has not is a build error");
		if (message != null)
			Assert.isTrue(message.indexOf("frame 7") >= 0, 'the error names the frame: $message');
	}

	@Test
	public function testBuilder_IndexFollowsSetParameter():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "npFrame", ["frame" => 0], Incremental);
		final sg = firstGrid(result.object);
		result.setParameter("frame", 2);
		Assert.equals(30, sg.tile.ix, "setParameter(frame) shows the third frame");
		Assert.equals(0, sg.tile.iy);
	}

	@Test
	public function testCodegen_IndexMatchesTheBuilder():Void {
		final inst:Dynamic = createMp().npFrame.create(3);
		final sg = firstGrid(cast inst);
		Assert.equals(30, sg.tile.ix, "codegen: index: 3 is the fourth frame");
		Assert.equals(30, sg.tile.iy);
		inst.setParameter("frame", 1);
		Assert.equals(0, sg.tile.ix, "codegen: setParameter(frame) follows");
		Assert.equals(30, sg.tile.iy);
	}

	@Test
	public function testBuilder_FpsPlaysTheFramesFromSync():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "npAnim", ["speed" => 10.0]);
		final sg = firstGrid(result.object);
		Assert.isTrue(Std.isOfType(sg, AnimatedScaleGrid), "fps: makes an AnimatedScaleGrid");
		final anim:AnimatedScaleGrid = cast sg;
		Assert.equals(4, anim.frames.length, "every frame of the name");
		Assert.equals(10., anim.fps);
		Assert.equals(0, anim.frameIndex);
		anim.advance(0.15);
		Assert.equals(1, anim.frameIndex, "0.15 s at 10 fps is frame 1");
		Assert.equals(0, anim.tile.ix);
		Assert.equals(30, anim.tile.iy, "the drawn tile is frame 1's");
		anim.advance(0.3);
		Assert.equals(0, anim.frameIndex, "0.45 s is frame 4, which wraps to 0");
		anim.seek(3);
		Assert.equals(3, anim.frameIndex);
		Assert.equals(30, anim.tile.ix);
		Assert.equals(30, anim.tile.iy);
	}

	@Test
	public function testCodegen_FpsPlaysTheFrames():Void {
		final inst:Dynamic = createMp().npAnim.create(10.0);
		final sg = firstGrid(cast inst);
		Assert.isTrue(Std.isOfType(sg, AnimatedScaleGrid), "codegen: fps: makes an AnimatedScaleGrid");
		final anim:AnimatedScaleGrid = cast sg;
		Assert.equals(4, anim.frames.length);
		anim.advance(0.25);
		Assert.equals(2, anim.frameIndex);
		inst.setParameter("speed", 20.0);
		Assert.equals(20., anim.fps, "codegen: setParameter(speed) changes the rate");
	}

	@Test
	public function testAnimatedGridSyncAdvancesWithTheScene():Void {
		final scene = new h2d.Scene();
		final result = BuilderTestBase.buildFromFile(FIXTURE, "npAnim", ["speed" => 4.0]);
		scene.addChild(result.object);
		final anim:AnimatedScaleGrid = cast firstGrid(result.object);
		scene.syncOnly(0.3);
		Assert.equals(1, anim.frameIndex, "sync steps the animation by the frame's elapsed time");
		scene.dispose();
	}
}
