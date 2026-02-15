package bh.test.examples;

import utest.Assert;
import h2d.Scene;
import bh.test.VisualTestBase;
import bh.test.HtmlReportGenerator;
import bh.test.examples.AutotileTestHelper;

/**
 * Tests for the @:build(ProgrammableCodeGen.buildAll()) generated classes.
 * Visual tests use simpleMacroTest() / multiInstanceMacroTest() to produce 3-image comparisons:
 *   - Reference image
 *   - Builder (runtime) rendering
 *   - Macro (compile-time) rendering
 */
@:access(bh.base.Particles)
@:access(bh.base.ParticleGroup)
@:access(h2d.SpriteBatch)
@:access(h2d.BatchElement)
class ProgrammableCodeGenTest extends VisualTestBase {
	var autotileHelper:AutotileTestHelper;

	public function new(s2d:Scene) {
		super("programmableCodeGen", s2d);
		autotileHelper = new AutotileTestHelper(this, s2d);
	}

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	// ==================== Button: unit tests ====================

	@Test
	public function testButtonCreate():Void {
		final mp = createMp();
		final btn = mp.button.create();
		Assert.notNull(btn, "Button should be created");
		Assert.isTrue(btn.numChildren > 0, "Root should have children");
	}

	@Test
	public function testButtonSetStatus():Void {
		final mp = createMp();
		final btn = mp.button.create();
		Assert.isTrue(countVisibleChildren(btn) > 0, "Visible in normal state");

		btn.setStatus(bh.test.MultiProgrammable_Button.Hover);
		Assert.isTrue(countVisibleChildren(btn) > 0, "Visible in hover state");

		btn.setStatus(bh.test.MultiProgrammable_Button.Pressed);
		Assert.isTrue(countVisibleChildren(btn) > 0, "Visible in pressed state");
	}

	@Test
	public function testButtonSetText():Void {
		final mp = createMp();
		final btn = mp.button.create();
		final textEl = findTextChild(btn);
		Assert.notNull(textEl, "Should have a Text element");
		if (textEl != null)
			Assert.equals("Button", textEl.text);

		btn.setButtonText("Changed");
		final textEl2 = findTextChild(btn);
		if (textEl2 != null)
			Assert.equals("Changed", textEl2.text);
	}

	// ==================== Button: visual (3-image) ====================

	@Test
	public function test36_CodegenButton(async:utest.Async):Void {
		simpleMacroTest(36, "codegenButton", () -> createMp().button.create(), async, null, null, 4.0);
	}

	// ==================== Healthbar: unit tests ====================

	@Test
	public function testHealthbarCreate():Void {
		final mp = createMp();
		final hb = mp.healthbar.create();
		Assert.notNull(hb, "Healthbar should be created");
		Assert.isTrue(hb.numChildren > 0, "Root should have children");
	}

	@Test
	public function testHealthbarSetHealth():Void {
		final mp = createMp();
		final hb = mp.healthbar.create();

		final textEl = findTextChild(hb);
		Assert.notNull(textEl, "Should have health text");
		if (textEl != null)
			Assert.equals("75", textEl.text);

		hb.setHealth(50);
		final textEl2 = findTextChild(hb);
		if (textEl2 != null)
			Assert.equals("50", textEl2.text);
	}

	@Test
	public function testHealthbarLowHealth():Void {
		final mp = createMp();
		final hb = mp.healthbar.create();

		hb.setHealth(20);
		var visibleCount = countVisibleChildren(hb);
		Assert.isTrue(visibleCount > 0, "Should have visible children at low health");
	}

	// ==================== Healthbar: visual (3-image) ====================

	@Test
	public function test37_CodegenHealthbar(async:utest.Async):Void {
		simpleMacroTest(37, "codegenHealthbar", () -> createMp().healthbar.create(), async, null, null, 4.0);
	}

	// ==================== Dialog: unit tests ====================

	@Test
	public function testDialogCreate():Void {
		final mp = createMp();
		final dlg = mp.dialog.create();
		Assert.notNull(dlg, "Dialog should be created");
		Assert.isTrue(dlg.numChildren > 0, "Root should have children");
	}

	@Test
	public function testDialogSetTitle():Void {
		final mp = createMp();
		final dlg = mp.dialog.create();

		final textEl = findTextChild(dlg);
		Assert.notNull(textEl, "Should have title text");
		if (textEl != null)
			Assert.equals("Dialog", textEl.text);

		dlg.setTitle("New Title");
		final textEl2 = findTextChild(dlg);
		if (textEl2 != null)
			Assert.equals("New Title", textEl2.text);
	}

	@Test
	public function testDialogSetStyle():Void {
		final mp = createMp();
		final dlg = mp.dialog.create(400, "Dialog macro");

		dlg.setStyle(bh.test.MultiProgrammable_Dialog.Hover);
		Assert.isTrue(countVisibleChildren(dlg) > 0, "Visible in hover style");

		dlg.setStyle(bh.test.MultiProgrammable_Dialog.Disabled);
		Assert.isTrue(countVisibleChildren(dlg) > 0, "Visible in disabled style");
	}

	// ==================== Dialog: visual (3-image) ====================

	@Test
	public function test38_CodegenDialog(async:utest.Async):Void {
		simpleMacroTest(38, "codegenDialog", () -> createMp().dialog.create(), async, null, null, 4.0);
	}

	// ==================== createFrom: unit tests ====================

	@Test
	public function testDialogCreateFrom():Void {
		final mp = createMp();
		final dlg = mp.dialog.createFrom({
			w: 400,
			h: 300,
			title: "Test",
			body: "Body text",
			style: bh.test.MultiProgrammable_Dialog.Hover
		});
		Assert.notNull(dlg, "Dialog should be created with createFrom");
		Assert.isTrue(dlg.numChildren > 0, "Root should have children");
	}

	@Test
	public function testDialogCreateFromPartial():Void {
		final mp = createMp();
		final dlg = mp.dialog.createFrom({title: "Only Title"});
		Assert.notNull(dlg, "Dialog should be created with partial params");
		final textEl = findTextChild(dlg);
		Assert.notNull(textEl, "Should have title text");
		if (textEl != null)
			Assert.equals("Only Title", textEl.text);
	}

	@Test
	public function testDialogCreateFromEmpty():Void {
		final mp = createMp();
		final dlg = mp.dialog.createFrom({});
		Assert.notNull(dlg, "Dialog should be created with all defaults");
		Assert.isTrue(dlg.numChildren > 0, "Root should have children");
	}

	@Test
	public function testBoolFloatCreateFrom():Void {
		final mp = createMp();
		final bf = mp.boolFloat.createFrom({showBorder: true, opacity: 0.5});
		Assert.notNull(bf, "BoolFloat should be created from struct");
		Assert.isTrue(bf.numChildren > 0, "Root should have children");
	}

	@Test
	public function testCreateFromMatchesCreate():Void {
		final mp1 = createMp();
		final mp2 = createMp();
		final pos = mp1.dialog.create(400, 200, "Test", "Body", bh.test.MultiProgrammable_Dialog.Hover);
		final map = mp2.dialog.createFrom({w: 400, h: 200, title: "Test", body: "Body", style: bh.test.MultiProgrammable_Dialog.Hover});
		Assert.equals(pos.numChildren, map.numChildren, "create and createFrom should produce same structure");
	}

	// ==================== Repeat: unit tests ====================

	@Test
	public function testRepeatCreate():Void {
		final mp = createMp();
		final rpt = mp.repeat.create();
		Assert.notNull(rpt, "Repeat should be created");
		Assert.isTrue(rpt.numChildren > 0, "Root should have children");
	}

	@Test
	public function testRepeatChildCount():Void {
		final mp = createMp();
		final rpt = mp.repeat.create();
		var totalChildren = countAllDescendants(rpt);
		Assert.isTrue(totalChildren > 10, "Should have many descendant objects from unrolled repeats");
	}

	@Test
	public function testRepeatSetCount():Void {
		final mp = createMp();
		final rpt = mp.repeat.create();

		rpt.setCount(2);
		var visCount = countVisibleDescendants(rpt);
		final count2 = visCount;

		rpt.setCount(4);
		visCount = countVisibleDescendants(rpt);
		Assert.isTrue(visCount > count2, "More visible descendants with higher count");
	}

	// ==================== Repeat: visual (3-image) ====================

	@Test
	public function test39_CodegenRepeat(async:utest.Async):Void {
		simpleMacroTest(39, "codegenRepeat", () -> createMp().repeat.create(), async, null, null, 4.0);
	}

	// ==================== Repeat2D: unit tests ====================

	@Test
	public function testRepeat2dCreate():Void {
		final mp = createMp();
		final rpt2d = mp.repeat2d.create();
		Assert.notNull(rpt2d, "Repeat2d should be created");
		Assert.isTrue(rpt2d.numChildren > 0, "Root should have children");
	}

	@Test
	public function testRepeat2dSetCols():Void {
		final mp = createMp();
		final rpt2d = mp.repeat2d.create();

		rpt2d.setCols(1);
		final count1 = countVisibleDescendants(rpt2d);

		rpt2d.setCols(3);
		final count3 = countVisibleDescendants(rpt2d);
		Assert.isTrue(count3 > count1, "More visible descendants with more cols");
	}

	// ==================== Repeat2D: visual (3-image) ====================

	@Test
	public function test40_CodegenRepeat2d(async:utest.Async):Void {
		simpleMacroTest(40, "codegenRepeat2d", () -> createMp().repeat2d.create(), async, null, null, 4.0);
	}

	// ==================== Layout: unit tests ====================

	@Test
	public function testLayoutCreate():Void {
		final mp = createMp();
		final lay = mp.layout.create();
		Assert.notNull(lay, "Layout should be created");
		Assert.isTrue(lay.numChildren > 0, "Root should have children");
	}

	@Test
	public function testLayoutChildCount():Void {
		final mp = createMp();
		final lay = mp.layout.create();
		var totalChildren = countAllDescendants(lay);
		Assert.isTrue(totalChildren >= 9, "Should have at least 9 descendant objects from layout repeats");
	}

	// ==================== Layout: visual (3-image) ====================

	@Test
	public function test41_CodegenLayout(async:utest.Async):Void {
		simpleMacroTest(41, "codegenLayout", () -> createMp().layout.create(), async, null, null, 4.0);
	}

	// ==================== TilesIter: unit tests ====================

	@Test
	public function testTilesIterCreate():Void {
		final mp = createMp();
		final ti = mp.tilesIter.create();
		Assert.notNull(ti, "TilesIter should be created");
		Assert.isTrue(ti.numChildren > 0, "Root should have children");
	}

	@Test
	public function testTilesIterHasBitmaps():Void {
		final mp = createMp();
		final ti = mp.tilesIter.create();
		var totalChildren = countAllDescendants(ti);
		Assert.isTrue(totalChildren >= 2, "Should have descendant objects from runtime iterators");
	}

	// ==================== TilesIter: visual (3-image) ====================

	@Test
	public function test42_CodegenTilesIter(async:utest.Async):Void {
		simpleMacroTest(42, "codegenTilesIter", () -> createMp().tilesIter.create(), async, null, null, 4.0);
	}

	// ==================== Tint: visual (3-image) ====================

	@Test
	public function test35_TintDemo(async:utest.Async):Void {
		simpleMacroTest(35, "tintDemo", () -> createMp().tint.create(), async);
	}

	// ==================== Graphics: visual (3-image) ====================

	@Test
	public function test43_CodegenGraphics(async:utest.Async):Void {
		simpleMacroTest(43, "codegenGraphics", () -> createMp().graphics.create(), async, null, null, 4.0);
	}

	// ==================== Reference: visual (3-image) ====================

	@Test
	public function test44_CodegenReference(async:utest.Async):Void {
		simpleMacroTest(44, "codegenReference", () -> createMp().reference.create(), async, null, null, 4.0);
	}

	// ==================== FilterParam: unit tests ====================

	@Test
	public function testFilterParamCreate():Void {
		final mp = createMp();
		final fp = mp.filterParam.create();
		Assert.notNull(fp, "FilterParam should be created");
		Assert.isTrue(fp.numChildren > 0, "Root should have children");
	}

	@Test
	public function testFilterParamSetOutlineColor():Void {
		final mp = createMp();
		final fp = mp.filterParam.create();

		final firstChild = fp.getChildAt(0);
		Assert.notNull(firstChild.filter, "First child should have an outline filter");

		fp.setOutlineColor(0x00FF00);
		Assert.notNull(firstChild.filter, "Filter should still exist after color change");
	}

	@Test
	public function testFilterParamSetTintColor():Void {
		final mp = createMp();
		final fp = mp.filterParam.create();

		fp.setTintColor(0xFF0000);
		Assert.isTrue(fp.numChildren > 0, "Should still have children after tint change");
	}

	// ==================== FilterParam: visual (3-image) ====================

	@Test
	public function test45_CodegenFilterParam(async:utest.Async):Void {
		simpleMacroTest(45, "codegenFilterParam", () -> createMp().filterParam.create(), async, null, null, 4.0);
	}

	// ==================== GridPos: unit tests ====================

	@Test
	public function testGridPosCreate():Void {
		final mp = createMp();
		final gp = mp.gridPos.create();
		Assert.notNull(gp, "GridPos should be created");
		Assert.isTrue(gp.numChildren > 0, "Root should have children");
	}

	@Test
	public function testGridPosChildCount():Void {
		final mp = createMp();
		final gp = mp.gridPos.create();
		var totalChildren = countAllDescendants(gp);
		Assert.isTrue(totalChildren >= 7, "Should have at least 7 descendant objects from layout repeats");
	}

	// ==================== GridPos: visual (3-image) ====================

	@Test
	public function test46_CodegenGridPos(async:utest.Async):Void {
		simpleMacroTest(46, "codegenGridPos", () -> createMp().gridPos.create(), async, null, null, 4.0);
	}

	// ==================== HexPos: unit tests ====================

	@Test
	public function testHexPosCreate():Void {
		final mp = createMp();
		final hp = mp.hexPos.create();
		Assert.notNull(hp, "HexPos should be created");
		Assert.isTrue(hp.numChildren > 0, "Root should have children");
	}

	@Test
	public function testHexPosChildCount():Void {
		final mp = createMp();
		final hp = mp.hexPos.create();
		var totalChildren = countAllDescendants(hp);
		Assert.isTrue(totalChildren >= 24, "Should have at least 24 descendant objects from hex positioning");
	}

	// ==================== HexPos: visual (3-image) ====================

	@Test
	public function test47_CodegenHexPos(async:utest.Async):Void {
		simpleMacroTest(47, "codegenHexPos", () -> createMp().hexPos.create(), async);
	}

	@Test
	public function testHexPosSetCornerIdx():Void {
		final mp = createMp();
		final hp = mp.hexPos.create();
		hp.setCornerIdx(3);
		Assert.isTrue(hp.numChildren > 0);
	}

	// ==================== TextOpts: unit tests ====================

	@Test
	public function testTextOptsCreate():Void {
		final mp = createMp();
		final to = mp.textOpts.create();
		Assert.notNull(to, "TextOpts should be created");
		Assert.isTrue(to.numChildren > 0, "Root should have children");
	}

	// ==================== TextOpts: visual (3-image) ====================

	@Test
	public function test48_CodegenTextOpts(async:utest.Async):Void {
		simpleMacroTest(48, "codegenTextOpts", () -> createMp().textOpts.create(), async);
	}

	// ==================== BoolFloat: unit tests ====================

	@Test
	public function testBoolFloatCreate():Void {
		final mp = createMp();
		final bf = mp.boolFloat.create();
		Assert.notNull(bf, "BoolFloat should be created");
		Assert.isTrue(bf.numChildren > 0, "Root should have children");
	}

	@Test
	public function testBoolFloatToggle():Void {
		final mp = createMp();
		final bf = mp.boolFloat.create();
		final vis1 = countVisibleChildren(bf);

		bf.setShowLabel(true);
		final vis2 = countVisibleChildren(bf);
		Assert.isTrue(vis2 > vis1, "Toggling showLabel on should increase visible children");

		bf.setShowBorder(false);
		Assert.isTrue(countVisibleChildren(bf) > 0, "Should still have visible children after border toggle");
	}

	@Test
	public function testBoolFloatAlpha():Void {
		final mp = createMp();
		final bf = mp.boolFloat.create();
		var foundAlpha = false;
		for (i in 0...bf.numChildren) {
			final child = bf.getChildAt(i);
			if (child.alpha < 1.0 && child.alpha > 0.0) {
				foundAlpha = true;
				break;
			}
		}
		Assert.isTrue(foundAlpha, "Should have a child with alpha < 1.0 from float param");
	}

	// ==================== BoolFloat: visual — multi-instance ====================

	@Test
	public function test49_CodegenBoolFloat(async:utest.Async):Void {
		var params:Array<Map<String, Dynamic>> = [];
		for (i in 0...4) {
			var p = new Map<String, Dynamic>();
			switch (i) {
				case 0: p.set("showBorder", "true"); p.set("showLabel", "false"); p.set("opacity", 0.8); p.set("barWidth", 1.5);
				case 1: p.set("showBorder", "false"); p.set("showLabel", "true"); p.set("opacity", 0.4); p.set("barWidth", 2.0);
				case 2: p.set("showBorder", "true"); p.set("showLabel", "true"); p.set("opacity", 1.0); p.set("barWidth", 0.5);
				case 3: p.set("showBorder", "false"); p.set("showLabel", "false"); p.set("opacity", 0.6); p.set("barWidth", 1.0);
			}
			params.push(p);
		}

		multiInstanceMacroTest(49, "codegenBoolFloat", 2.0, 80.0, params, function(i:Int):h2d.Object {
			var mp = createMp();
			return switch (i) {
				case 0: mp.boolFloat.create(true, false, 0.8, 1.5);
				case 1: mp.boolFloat.create(false, true, 0.4, 2.0);
				case 2: mp.boolFloat.create(true, true, 1.0, 0.5);
				default: mp.boolFloat.create(false, false, 0.6, 1.0);
			};
		}, async);
	}

	// ==================== RangeFlags: unit tests ====================

	@Test
	public function testRangeFlagsCreate():Void {
		final mp = createMp();
		final rf = mp.rangeFlags.create();
		Assert.notNull(rf, "RangeFlags should be created");
		Assert.isTrue(rf.numChildren > 0, "Root should have children");
	}

	@Test
	public function testRangeFlagsLevelConditional():Void {
		final mp = createMp();
		final rf = mp.rangeFlags.create();
		final vis1 = countVisibleChildren(rf);
		Assert.isTrue(vis1 > 0, "Should have visible children at level 60");

		rf.setLevel(20);
		final vis2 = countVisibleChildren(rf);
		Assert.isTrue(vis2 > 0, "Should have visible children at level 20");

		final textEl = findTextChild(rf);
		Assert.notNull(textEl, "Should have a text element");
		if (textEl != null)
			Assert.equals("20", textEl.text);
	}

	// ==================== RangeFlags: visual — multi-instance ====================

	@Test
	public function test50_CodegenRangeFlags(async:utest.Async):Void {
		var params:Array<Map<String, Dynamic>> = [];
		for (i in 0...4) {
			var p = new Map<String, Dynamic>();
			switch (i) {
				case 0: p.set("level", 60); p.set("power", 30); p.set("bits", 5);
				case 1: p.set("level", 20); p.set("power", 45); p.set("bits", 3);
				case 2: p.set("level", 80); p.set("power", 10); p.set("bits", 7);
				case 3: p.set("level", 50); p.set("power", 50); p.set("bits", 0);
			}
			params.push(p);
		}

		multiInstanceMacroTest(50, "codegenRangeFlags", 2.0, 75.0, params, function(i:Int):h2d.Object {
			var mp = createMp();
			return switch (i) {
				case 0: mp.rangeFlags.create(60, 30, 5);
				case 1: mp.rangeFlags.createFrom({bits: 3, power:45 , level:20});
				case 2: mp.rangeFlags.create(80, 10, 7);
				default: mp.rangeFlags.create(50, 50, 0);
			};
		}, async);
	}

	// ==================== Particles: visual + unit tests ====================

	@Test
	public function test51_CodegenParticles(async:utest.Async):Void {
		setupTest(51, "codegenParticles");
		VisualTestBase.pendingVisualTests++;
		async.setTimeout(15000);

		final animFilePath = 'test/examples/51-codegenParticles/codegenParticles.manim';
		final sizeX = 1280;
		final sizeY = 720;

		// Phase 1: builder — build, advance particles, screenshot
		clearScene();
		var builderResult = buildAndAddToScene(animFilePath, "codegenParticles");
		if (builderResult == null) {
			Assert.fail("Failed to build codegenParticles from builder");
			VisualTestBase.pendingVisualTests--;
			async.done();
			return;
		}

		var builderParticles = findParticles(builderResult.object);
		if (builderParticles != null) advanceParticles(builderParticles, 1.5);

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderSuccess = screenshot(builderPath, sizeX, sizeY);
			Assert.isTrue(builderSuccess, "Builder should produce non-empty screenshot");

			// Phase 2: macro — create, advance particles, screenshot
			clearScene();
			var macroRoot = createMp().particles.create();
			s2d.addChild(macroRoot);

			var macroParticles = findParticles(macroRoot);
			if (macroParticles != null) advanceParticles(macroParticles, 1.5);

			waitForUpdate(function(dt2:Float) {
				var macroPath = 'test/screenshots/codegenParticles_macro.png';
				var macroSuccess = screenshot(macroPath, sizeX, sizeY);
				Assert.isTrue(macroSuccess, "Macro should produce non-empty screenshot");

				// Both should produce visible particles — compare loosely to reference
				var referencePath = getReferenceImagePath();
				var builderSim = builderSuccess ? computeSimilarity(builderPath, referencePath) : 0.0;
				var macroSim = macroSuccess ? computeSimilarity(macroPath, referencePath) : 0.0;

				// Use low threshold since particles are randomly positioned
				var threshold = 0.70;
				var builderOk = builderSim > threshold;
				var macroOk = macroSim > threshold;

				HtmlReportGenerator.addResultWithMacro(getDisplayName(), referencePath, builderPath, builderOk && macroOk,
					builderSim, null, macroPath, macroSim, macroOk, threshold, threshold);
				HtmlReportGenerator.generateReport();

				Assert.isTrue(builderOk, 'Builder should roughly match reference (similarity: ${Math.round(builderSim * 10000) / 100}%)');
				Assert.isTrue(macroOk, 'Macro should roughly match reference (similarity: ${Math.round(macroSim * 10000) / 100}%)');

				VisualTestBase.pendingVisualTests--;
				async.done();
			});
		});
	}

	static function findParticles(obj:h2d.Object):Null<bh.base.Particles> {
		if (Std.isOfType(obj, bh.base.Particles)) return cast obj;
		for (i in 0...obj.numChildren) {
			var result = findParticles(obj.getChildAt(i));
			if (result != null) return result;
		}
		return null;
	}

	/**
	 * Advance particle simulation by totalTime seconds using fixed timesteps.
	 * Uses @:access to directly update particle groups and batch elements.
	 */
	static function advanceParticles(particles:bh.base.Particles, totalTime:Float):Void {
		final step:Float = 0.016;
		var remaining = totalTime;
		while (remaining > 0) {
			final dt = remaining < step ? remaining : step;
			for (g in particles.groups) {
				if (!g.started && g.enabled) g.start();
				g.updateTime(dt);
				// Advance each particle in the batch (mirrors SpriteBatch.sync behavior)
				var e = g.batch.first;
				while (e != null) {
					var next = e.next;
					if (!e.update(dt))
						e.remove();
					e = next;
				}
			}
			remaining -= step;
		}
	}

	// ==================== BlendMode: visual (3-image) ====================

	@Test
	public function test52_CodegenBlendMode(async:utest.Async):Void {
		simpleMacroTest(52, "codegenBlendMode", () -> createMp().blendMode.create(), async);
	}

	// ==================== Apply: visual — multi-instance ====================

	@Test
	public function test53_CodegenApply(async:utest.Async):Void {
		var params:Array<Map<String, Dynamic>> = [];
		for (i in 0...3) {
			var p = new Map<String, Dynamic>();
			switch (i) {
				case 0: p.set("state", "alpha");
				case 1: p.set("state", "filter");
				case 2: p.set("state", "scale");
			}
			params.push(p);
		}

		multiInstanceMacroTest(53, "codegenApply", 1.0, 250.0, params, function(i:Int):h2d.Object {
			var mp = createMp();
			return switch (i) {
				case 0: mp.apply.create(bh.test.MultiProgrammable_Apply.Alpha);
				case 1: mp.apply.create(bh.test.MultiProgrammable_Apply.Filter);
				default: mp.apply.create(bh.test.MultiProgrammable_Apply.Scale);
			};
		}, async);
	}

	// ==================== PaletteReplace: visual (3-image) ====================

	@Test
	public function test54_CodegenPaletteReplace(async:utest.Async):Void {
		simpleMacroTest(54, "codegenPaletteReplace", () -> createMp().paletteReplace.create(), async);
	}

	// ==================== Array: visual (3-image) ====================

	@Test
	public function test55_CodegenArray(async:utest.Async):Void {
		var params:Array<Map<String, Dynamic>> = [];
		for (i in 0...3) {
			var p = new Map<String, Dynamic>();
			switch (i) {
				case 0: p.set("items", (["one", "two", "three"] : Array<Dynamic>));
				case 1: p.set("items", (["alpha", "beta"] : Array<Dynamic>));
				case 2: p.set("items", (["x", "y", "z", "w"] : Array<Dynamic>));
			}
			params.push(p);
		}
		multiInstanceMacroTest(55, "codegenArray", 4.0, 80.0, params, function(i:Int):h2d.Object {
			var mp = createMp();
			return switch (i) {
				case 0: mp.array.create(["one", "two", "three"]);
				case 1: mp.array.create(["alpha", "beta"]);
				default: mp.array.create(["x", "y", "z", "w"]);
			};
		}, async);
	}

	// ==================== GridFunc: function(gridWidth/gridHeight) ====================

	@Test
	public function test56_CodegenGridFunc(async:utest.Async):Void {
		simpleMacroTest(56, "codegenGridFunc", () -> createMp().gridFunc.create(), async, null, null, 4.0);
	}

	// ==================== MultiNamed: unit tests ====================

	@Test
	public function testMultiNamedCreate():Void {
		final mp = createMp();
		final mn = mp.multiNamed.create();
		Assert.notNull(mn, "MultiNamed should be created");
		Assert.isTrue(mn.numChildren > 0, "Root should have children");
	}

	@Test
	public function testMultiNamedGetIndicator():Void {
		final mp = createMp();
		final mn = mp.multiNamed.create();
		final indicator = mn.get_indicator();
		Assert.notNull(indicator, "get_indicator() should return IUpdatable");
		Assert.isTrue(Std.isOfType(indicator, bh.multianim.ProgrammableUpdatable), "Should be ProgrammableUpdatable instance");
		final pu:bh.multianim.ProgrammableUpdatable = cast indicator;
		Assert.equals(4, pu.objects.length, "Should have 4 indicator objects");
	}

	@Test
	public function testMultiNamedGetLabel():Void {
		final mp = createMp();
		final mn = mp.multiNamed.create();
		final label = mn.get_label();
		Assert.notNull(label, "get_label() should return h2d.Object (single-element getter)");
	}

	@Test
	public function testMultiNamedSetVisibility():Void {
		final mp = createMp();
		final mn = mp.multiNamed.create();
		final indicator = mn.get_indicator();
		final pu:bh.multianim.ProgrammableUpdatable = cast indicator;
		indicator.setVisibility(false);
		for (obj in pu.objects) {
			Assert.isFalse(obj.visible, "All indicator objects should be hidden");
		}
		indicator.setVisibility(true);
		for (obj in pu.objects) {
			Assert.isTrue(obj.visible, "All indicator objects should be visible");
		}
	}

	// ==================== MultiNamed: visual — multi-instance ====================

	@Test
	public function test57_CodegenMultiNamed(async:utest.Async):Void {
		var params:Array<Map<String, Dynamic>> = [];
		for (i in 0...4) {
			var p = new Map<String, Dynamic>();
			switch (i) {
				case 0: p.set("status", "idle");
				case 1: p.set("status", "hover");
				case 2: p.set("status", "pressed");
				case 3: p.set("status", "disabled");
			}
			params.push(p);
		}

		multiInstanceMacroTest(57, "codegenMultiNamed", 2.0, 80.0, params, function(i:Int):h2d.Object {
			var mp = createMp();
			return switch (i) {
				case 0: mp.multiNamed.create();
				case 1: mp.multiNamed.createFrom({status: bh.test.MultiProgrammable_MultiNamed.Hover});
				case 2: mp.multiNamed.createFrom({status: bh.test.MultiProgrammable_MultiNamed.Pressed});
				default: mp.multiNamed.createFrom({status: bh.test.MultiProgrammable_MultiNamed.Disabled});
			};
		}, async);
	}

	// ==================== RepeatableDemo: macro comparison ====================

	@Test
	public function test04_RepeatableDemo(async:utest.Async):Void {
		var params:Array<Map<String, Dynamic>> = [];
		for (i in 0...4) {
			var p = new Map<String, Dynamic>();
			switch (i) {
				case 0: p.set("count", 1);
				case 1: p.set("count", 3);
				case 2: p.set("count", 5);
				case 3: p.set("count", 20);
			}
			params.push(p);
		}
		multiInstanceMacroTest(4, "repeatableDemo", 1.0, 90.0, params, function(i:Int):h2d.Object {
			var mp = createMp();
			return switch (i) {
				case 0: mp.repeatableDemo.create(1);
				case 1: mp.repeatableDemo.create(3);
				case 2: mp.repeatableDemo.create(5);
				default: mp.repeatableDemo.create(20);
			};
		}, async);
	}

	// ==================== FlowDemo: macro comparison ====================

	@Test
	public function test06_FlowDemo(async:utest.Async):Void {
		setupTest(6, "flowDemo");
		builderAndMacroScreenshotAndCompare("test/examples/6-flowDemo/flowDemo.manim", "flowDemo",
			() -> createMp().flowDemo.create(), async);
	}

	// ==================== HexGridPixels: macro comparison ====================

	@Test
	public function test01_HexGridPixels(async:utest.Async):Void {
		setupTest(1, "hexGridPixels");
		builderAndMacroScreenshotAndCompare("test/examples/1-hexGridPixels/hexGridPixels.manim", "hexGridPixels",
			() -> createMp().hexGridPixels.create(), async, null, null, null, 0.999);
	}

	// ==================== TextDemo: macro comparison ====================

	@Test
	public function test02_TextDemo(async:utest.Async):Void {
		setupTest(2, "textDemo");
		builderAndMacroScreenshotAndCompare("test/examples/2-textDemo/textDemo.manim", "textDemo",
			() -> createMp().textDemo.create(), async);
	}

	// ==================== BitmapDemo: macro comparison ====================

	@Test
	public function test03_BitmapDemo(async:utest.Async):Void {
		setupTest(3, "bitmapDemo");
		builderAndMacroScreenshotAndCompare("test/examples/3-bitmapDemo/bitmapDemo.manim", "bitmapDemo",
			() -> createMp().bitmapDemo.create(), async);
	}

	// ==================== LayersDemo: macro comparison ====================

	@Test
	public function test08_LayersDemo(async:utest.Async):Void {
		setupTest(8, "layersDemo");
		builderAndMacroScreenshotAndCompare("test/examples/8-layersDemo/layersDemo.manim", "layersDemo",
			() -> createMp().layersDemo.create(), async);
	}

	// ==================== NinePatchDemo: macro comparison ====================

	@Test
	public function test09_NinePatchDemo(async:utest.Async):Void {
		setupTest(9, "ninePatchDemo");
		builderAndMacroScreenshotAndCompare("test/examples/9-ninePatchDemo/ninePatchDemo.manim", "ninePatchDemo",
			() -> createMp().ninePatchDemo.create(), async);
	}

	// ==================== ReferenceDemo: macro comparison ====================

	@Test
	public function test10_ReferenceDemo(async:utest.Async):Void {
		setupTest(10, "referenceDemo");
		builderAndMacroScreenshotAndCompare("test/examples/10-referenceDemo/referenceDemo.manim", "referenceDemo",
			() -> createMp().referenceDemo.create(), async);
	}

	// ==================== BitmapAlignDemo: macro comparison ====================

	@Test
	public function test11_BitmapAlignDemo(async:utest.Async):Void {
		setupTest(11, "bitmapAlignDemo");
		builderAndMacroScreenshotAndCompare("test/examples/11-bitmapAlignDemo/bitmapAlignDemo.manim", "bitmapAlignDemo",
			() -> createMp().bitmapAlignDemo.create(), async);
	}

	// ==================== LayoutRepeatableDemo: macro comparison ====================

	@Test
	public function test13_LayoutRepeatableDemo(async:utest.Async):Void {
		setupTest(13, "layoutRepeatableDemo");
		builderAndMacroScreenshotAndCompare("test/examples/13-layoutRepeatableDemo/layoutRepeatableDemo.manim", "layoutRepeatableDemo",
			() -> createMp().layoutRepeatableDemo.create(), async);
	}

	// ==================== TileGroupDemo: macro comparison ====================

	@Test
	public function test14_TileGroupDemo(async:utest.Async):Void {
		setupTest(14, "tileGroupDemo");
		builderAndMacroScreenshotAndCompare("test/examples/14-tileGroupDemo/tileGroupDemo.manim", "tileGroupDemo",
			() -> createMp().tileGroupDemo.create(), async);
	}

	// ==================== ConditionalsDemo: macro comparison ====================

	@Test
	public function test18_ConditionalsDemo(async:utest.Async):Void {
		setupTest(18, "conditionalsDemo");
		builderAndMacroScreenshotAndCompare("test/examples/18-conditionalsDemo/conditionalsDemo.manim", "main",
			() -> createMp().conditionalsDemo.create(), async);
	}

	// ==================== TernaryOpDemo: macro comparison ====================

	@Test
	public function test19_TernaryOpDemo(async:utest.Async):Void {
		setupTest(19, "ternaryOpDemo");
		builderAndMacroScreenshotAndCompare("test/examples/19-ternaryOpDemo/ternaryOpDemo.manim", "ternaryOpDemo",
			() -> createMp().ternaryOpDemo.create(), async);
	}

	// ==================== GraphicsDemo: macro comparison ====================

	@Test
	public function test20_GraphicsDemo(async:utest.Async):Void {
		setupTest(20, "graphicsDemo");
		builderAndMacroScreenshotAndCompare("test/examples/20-graphicsDemo/graphicsDemo.manim", "graphicsDemo",
			() -> createMp().graphicsDemo.create(), async);
	}

	// ==================== Repeatable2dDemo: macro comparison ====================

	@Test
	public function test21_Repeatable2dDemo(async:utest.Async):Void {
		setupTest(21, "repeatable2dDemo");
		builderAndMacroScreenshotAndCompare("test/examples/21-repeatable2dDemo/repeatable2dDemo.manim", "repeatable2dDemo",
			() -> createMp().repeatable2dDemo.create(), async);
	}

	// ==================== AtlasDemo: macro comparison ====================

	@Test
	public function test23_AtlasDemo(async:utest.Async):Void {
		setupTest(23, "atlasDemo");
		builderAndMacroScreenshotAndCompare("test/examples/23-atlasDemo/atlasDemo.manim", "atlasDemo",
			() -> createMp().atlasDemo.create(), async);
	}

	// ==================== FontShowcase: macro comparison ====================

	@Test
	public function test26_FontShowcase(async:utest.Async):Void {
		setupTest(26, "fontShowcase");
		builderAndMacroScreenshotAndCompare("test/examples/26-fontShowcase/fontShowcase.manim", "fontShowcase",
			() -> createMp().fontShowcase.create(), async);
	}

	// ==================== ScalePositionDemo: macro comparison ====================

	@Test
	public function test27_ScalePositionDemo(async:utest.Async):Void {
		setupTest(27, "scalePositionDemo");
		builderAndMacroScreenshotAndCompare("test/examples/27-scalePositionDemo/scalePositionDemo.manim", "scalePositionDemo",
			() -> createMp().scalePositionDemo.create(), async);
	}

	// ==================== ElseDefaultDemo: macro comparison ====================

	@Test
	public function test31_ElseDefaultDemo(async:utest.Async):Void {
		setupTest(31, "elseDefaultDemo");
		builderAndMacroScreenshotAndCompare("test/examples/31-elseDefaultDemo/elseDefaultDemo.manim", "elseDefaultDemo",
			() -> createMp().elseDefaultDemo.create(), async);
	}

	// ==================== StateAnimDemo: macro comparison ====================

	@Test
	public function test05_StateAnimDemo(async:utest.Async):Void {
		setupTest(5, "stateAnimDemo");
		builderAndMacroScreenshotAndCompare("test/examples/5-stateAnimDemo/stateAnimDemo.manim", "stateAnimDemo",
			() -> createMp().stateAnimDemo.create(), async, null, null, null, 0.97);
	}

	// ==================== PaletteDemo: macro comparison ====================

	@Test
	public function test07_PaletteDemo(async:utest.Async):Void {
		setupTest(7, "paletteDemo");
		builderAndMacroScreenshotAndCompare("test/examples/7-paletteDemo/paletteDemo.manim", "paletteDemo",
			() -> createMp().paletteDemo.create(), async);
	}

	// ==================== UpdatableDemo: macro comparison ====================

	@Test
	public function test12_UpdatableDemo(async:utest.Async):Void {
		setupTest(12, "updatableDemo");
		builderAndMacroScreenshotAndCompare("test/examples/12-updatableDemo/updatableDemo.manim", "updatableDemo",
			() -> createMp().updatableDemo.create(), async);
	}

	// ==================== StateAnimConstructDemo: macro comparison ====================

	@Test
	public function test15_StateAnimConstructDemo(async:utest.Async):Void {
		setupTest(15, "stateAnimConstructDemo");
		builderAndMacroScreenshotAndCompare("test/examples/15-stateAnimConstructDemo/stateAnimConstructDemo.manim", "stateAnimConstructDemo",
			() -> createMp().stateAnimConstructDemo.create(), async);
	}

	// ==================== DivModDemo: macro comparison ====================

	@Test
	public function test16_DivModDemo(async:utest.Async):Void {
		setupTest(16, "divModDemo");
		builderAndMacroScreenshotAndCompare("test/examples/16-divModDemo/divModDemo.manim", "divModDemo",
			() -> createMp().divModDemo.create(), async);
	}

	// ==================== TilesIteration: macro comparison ====================

	@Test
	public function test22_TilesIteration(async:utest.Async):Void {
		setupTest(22, "tilesIteration");
		builderAndMacroScreenshotAndCompare("test/examples/22-tilesIteration/tilesIteration.manim", "tilesIteration",
			() -> createMp().tilesIteration.create(), async);
	}

	// ==================== NamedFilterParams: macro comparison ====================

	@Test
	public function test32_NamedFilterParams(async:utest.Async):Void {
		setupTest(32, "namedFilterParams");
		builderAndMacroScreenshotAndCompare("test/examples/32-namedFilterParams/namedFilterParams.manim", "namedFilterParams",
			() -> createMp().namedFilterParams.create(), async);
	}

	// ==================== InlineAtlas2Demo: macro comparison ====================

	@Test
	public function test33_InlineAtlas2Demo(async:utest.Async):Void {
		setupTest(33, "inlineAtlas2Demo");
		builderAndMacroScreenshotAndCompare("test/examples/33-inlineAtlas2Demo/inlineAtlas2Demo.manim", "inlineAtlas2Demo",
			() -> createMp().inlineAtlas2Demo.create(), async);
	}

	// ==================== MaskDemo: macro comparison ====================

	@Test
	public function test34_MaskDemo(async:utest.Async):Void {
		setupTest(34, "maskDemo");
		builderAndMacroScreenshotAndCompare("test/examples/34-maskDemo/maskDemo.manim", "maskDemo",
			() -> createMp().maskDemo.create(), async);
	}

	// ==================== ApplyDemo: macro comparison ====================

	@Test
	public function test17_ApplyDemo(async:utest.Async):Void {
		setupTest(17, "applyDemo");
		builderAndMacroScreenshotAndCompare("test/examples/17-applyDemo/applyDemo.manim", "applyDemo",
			() -> createMp().applyDemo.create(), async);
	}

	// ==================== AutotileCross: macro comparison ====================

	@Test
	public function test24_AutotileCross(async:utest.Async):Void {
		setupTest(24, "autotileCross");
		VisualTestBase.pendingVisualTests++;
		async.setTimeout(15000);
		final animFilePath = "test/examples/24-autotileCross/autotileCross.manim";
		final scale = 4.0;
		final threshold = 0.98;
		final autotileConfigs:Array<{name:String, grid:Array<Array<Int>>, x:Float, y:Float, background:Bool}> = [
			{name: "crossColored", grid: AutotileTestHelper.SIMPLE_RECT_GRID, x: 80.0, y: 376.0, background: false},
			{name: "crossWater", grid: AutotileTestHelper.SIMPLE_RECT_GRID, x: 520.0, y: 376.0, background: true}
		];

		// Phase 1: builder + autotile grids
		clearScene();
		var result = buildAndAddToScene(animFilePath, "autotileCross", scale);
		if (result == null) {
			Assert.fail('Failed to build "autotileCross"');
			VisualTestBase.pendingVisualTests--;
			async.done();
			return;
		}
		addAutotileOverlays(animFilePath, autotileConfigs, scale);

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderSuccess = screenshot(builderPath, 1280, 720);

			// Phase 2: macro + autotile grids
			clearScene();
			var macroRoot = createMp().autotileCross.create();
			macroRoot.setScale(scale);
			s2d.addChild(macroRoot);
			addAutotileOverlays(animFilePath, autotileConfigs, scale);
			if (testTitle != null && testTitle.length > 0) addTitleOverlay();

			waitForUpdate(function(dt2:Float) {
				var macroPath = 'test/screenshots/autotileCross_macro.png';
				var referencePath = getReferenceImagePath();
				var macroSuccess = screenshot(macroPath, 1280, 720);

				var builderSim = builderSuccess ? computeSimilarity(builderPath, referencePath) : 0.0;
				var macroSim = macroSuccess ? computeSimilarity(macroPath, referencePath) : 0.0;
				var builderOk = builderSim > threshold;
				var macroOk = macroSim > threshold;

				HtmlReportGenerator.addResultWithMacro(getDisplayName(), referencePath, builderPath, builderOk && macroOk,
					builderSim, null, macroPath, macroSim, macroOk, threshold, threshold);
				HtmlReportGenerator.generateReport();

				Assert.isTrue(builderOk, 'Builder should match reference (similarity: ${Math.round(builderSim * 10000) / 100}%)');
				Assert.isTrue(macroOk, 'Macro should match reference (similarity: ${Math.round(macroSim * 10000) / 100}%)');

				VisualTestBase.pendingVisualTests--;
				async.done();
			});
		});
	}

	// ==================== AutotileBlob47: macro comparison ====================

	@Test
	public function test25_AutotileBlob47(async:utest.Async):Void {
		setupTest(25, "autotileBlob47");
		VisualTestBase.pendingVisualTests++;
		async.setTimeout(15000);
		final animFilePath = "test/examples/25-autotileBlob47/autotileBlob47.manim";
		final scale = 2.0;
		final threshold = 0.98;
		final autotileConfigs:Array<{name:String, grid:Array<Array<Int>>, x:Float, y:Float, background:Bool}> = [
			{name: "blob47Colored", grid: AutotileTestHelper.LARGE_SEA_GRID, x: 40.0, y: 326.0, background: false},
			{name: "blob47Water", grid: AutotileTestHelper.LARGE_SEA_GRID, x: 684.0, y: 326.0, background: true}
		];

		// Phase 1: builder + autotile grids
		clearScene();
		var result = buildAndAddToScene(animFilePath, "autotileBlob47", scale);
		if (result == null) {
			Assert.fail('Failed to build "autotileBlob47"');
			VisualTestBase.pendingVisualTests--;
			async.done();
			return;
		}
		addAutotileOverlays(animFilePath, autotileConfigs, scale);

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderSuccess = screenshot(builderPath, 1280, 720);

			// Phase 2: macro + autotile grids
			clearScene();
			var macroRoot = createMp().autotileBlob47.create();
			macroRoot.setScale(scale);
			s2d.addChild(macroRoot);
			addAutotileOverlays(animFilePath, autotileConfigs, scale);
			if (testTitle != null && testTitle.length > 0) addTitleOverlay();

			waitForUpdate(function(dt2:Float) {
				var macroPath = 'test/screenshots/autotileBlob47_macro.png';
				var referencePath = getReferenceImagePath();
				var macroSuccess = screenshot(macroPath, 1280, 720);

				var builderSim = builderSuccess ? computeSimilarity(builderPath, referencePath) : 0.0;
				var macroSim = macroSuccess ? computeSimilarity(macroPath, referencePath) : 0.0;
				var builderOk = builderSim > threshold;
				var macroOk = macroSim > threshold;

				HtmlReportGenerator.addResultWithMacro(getDisplayName(), referencePath, builderPath, builderOk && macroOk,
					builderSim, null, macroPath, macroSim, macroOk, threshold, threshold);
				HtmlReportGenerator.generateReport();

				Assert.isTrue(builderOk, 'Builder should match reference (similarity: ${Math.round(builderSim * 10000) / 100}%)');
				Assert.isTrue(macroOk, 'Macro should match reference (similarity: ${Math.round(macroSim * 10000) / 100}%)');

				VisualTestBase.pendingVisualTests--;
				async.done();
			});
		});
	}

	// ==================== AutotileDemoSyntax: macro comparison ====================

	@Test
	public function test28_AutotileDemoSyntax(async:utest.Async):Void {
		setupTest(28, "autotileDemoSyntax");
		VisualTestBase.pendingVisualTests++;
		async.setTimeout(15000);
		final animFilePath = "test/examples/28-autotileDemoSyntax/autotileDemoSyntax.manim";
		final scale = 1.0;
		final threshold = 0.98;
		final autotileConfigs:Array<{name:String, grid:Array<Array<Int>>, x:Float, y:Float, background:Bool}> = [
			{name: "simple13Demo", grid: AutotileTestHelper.SIMPLE_RECT_GRID, x: 400.0, y: 100.0, background: false}
		];

		// Phase 1: builder + autotile grids
		clearScene();
		var result = buildAndAddToScene(animFilePath, "autotileDemoSyntax", scale);
		if (result == null) {
			Assert.fail('Failed to build "autotileDemoSyntax"');
			VisualTestBase.pendingVisualTests--;
			async.done();
			return;
		}
		addAutotileOverlays(animFilePath, autotileConfigs, scale);

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderSuccess = screenshot(builderPath, 1280, 720);

			// Phase 2: macro + autotile grids
			clearScene();
			var macroRoot = createMp().autotileDemoSyntax.create();
			macroRoot.setScale(scale);
			s2d.addChild(macroRoot);
			addAutotileOverlays(animFilePath, autotileConfigs, scale);
			if (testTitle != null && testTitle.length > 0) addTitleOverlay();

			waitForUpdate(function(dt2:Float) {
				var macroPath = 'test/screenshots/autotileDemoSyntax_macro.png';
				var referencePath = getReferenceImagePath();
				var macroSuccess = screenshot(macroPath, 1280, 720);

				var builderSim = builderSuccess ? computeSimilarity(builderPath, referencePath) : 0.0;
				var macroSim = macroSuccess ? computeSimilarity(macroPath, referencePath) : 0.0;
				var builderOk = builderSim > threshold;
				var macroOk = macroSim > threshold;

				HtmlReportGenerator.addResultWithMacro(getDisplayName(), referencePath, builderPath, builderOk && macroOk,
					builderSim, null, macroPath, macroSim, macroOk, threshold, threshold);
				HtmlReportGenerator.generateReport();

				Assert.isTrue(builderOk, 'Builder should match reference (similarity: ${Math.round(builderSim * 10000) / 100}%)');
				Assert.isTrue(macroOk, 'Macro should match reference (similarity: ${Math.round(macroSim * 10000) / 100}%)');

				VisualTestBase.pendingVisualTests--;
				async.done();
			});
		});
	}

	// ==================== ForgottenPlainsTerrain: macro comparison ====================

	@Test
	public function test29_ForgottenPlainsTerrain(async:utest.Async):Void {
		setupTest(29, "forgottenPlainsTerrain");
		VisualTestBase.pendingVisualTests++;
		async.setTimeout(15000);
		final animFilePath = "test/examples/29-forgottenPlainsTerrain/forgottenPlainsTerrain.manim";
		final scale = 4.0;
		final threshold = 0.98;
		final autotileConfigs:Array<{name:String, grid:Array<Array<Int>>, x:Float, y:Float, background:Bool}> = [
			{name: "grassTerrain", grid: AutotileTestHelper.CROSS_HOLE_GRID, x: 40.0, y: 360.0, background: false},
			{name: "grassDemo", grid: AutotileTestHelper.CROSS_HOLE_GRID, x: 320.0, y: 360.0, background: false}
		];

		// Phase 1: builder + autotile grids
		clearScene();
		var result = buildAndAddToScene(animFilePath, "forgottenPlainsTerrain", scale);
		if (result == null) {
			Assert.fail('Failed to build "forgottenPlainsTerrain"');
			VisualTestBase.pendingVisualTests--;
			async.done();
			return;
		}
		addAutotileOverlays(animFilePath, autotileConfigs, scale);

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderSuccess = screenshot(builderPath, 1280, 720);

			// Phase 2: macro + autotile grids
			clearScene();
			var macroRoot = createMp().forgottenPlainsTerrain.create();
			macroRoot.setScale(scale);
			s2d.addChild(macroRoot);
			addAutotileOverlays(animFilePath, autotileConfigs, scale);
			if (testTitle != null && testTitle.length > 0) addTitleOverlay();

			waitForUpdate(function(dt2:Float) {
				var macroPath = 'test/screenshots/forgottenPlainsTerrain_macro.png';
				var referencePath = getReferenceImagePath();
				var macroSuccess = screenshot(macroPath, 1280, 720);

				var builderSim = builderSuccess ? computeSimilarity(builderPath, referencePath) : 0.0;
				var macroSim = macroSuccess ? computeSimilarity(macroPath, referencePath) : 0.0;
				var builderOk = builderSim > threshold;
				var macroOk = macroSim > threshold;

				HtmlReportGenerator.addResultWithMacro(getDisplayName(), referencePath, builderPath, builderOk && macroOk,
					builderSim, null, macroPath, macroSim, macroOk, threshold, threshold);
				HtmlReportGenerator.generateReport();

				Assert.isTrue(builderOk, 'Builder should match reference (similarity: ${Math.round(builderSim * 10000) / 100}%)');
				Assert.isTrue(macroOk, 'Macro should match reference (similarity: ${Math.round(macroSim * 10000) / 100}%)');

				VisualTestBase.pendingVisualTests--;
				async.done();
			});
		});
	}

	// ==================== Blob47Fallback: macro comparison ====================

	@Test
	public function test30_Blob47Fallback(async:utest.Async):Void {
		setupTest(30, "blob47Fallback");
		VisualTestBase.pendingVisualTests++;
		async.setTimeout(15000);
		final animFilePath = "test/examples/30-blob47Fallback/blob47Fallback.manim";
		final scale = 2.0;
		final threshold = 0.98;
		final autotileConfigs:Array<{name:String, grid:Array<Array<Int>>, x:Float, y:Float, background:Bool}> = [
			{name: "blob47Demo", grid: AutotileTestHelper.LARGE_SEA_GRID, x: 20.0, y: 304.0, background: false},
			{name: "blob47Grass", grid: AutotileTestHelper.LARGE_SEA_GRID, x: 320.0, y: 304.0, background: false}
		];

		// Phase 1: builder + autotile grids
		clearScene();
		var result = buildAndAddToScene(animFilePath, "blob47Fallback", scale);
		if (result == null) {
			Assert.fail('Failed to build "blob47Fallback"');
			VisualTestBase.pendingVisualTests--;
			async.done();
			return;
		}
		addAutotileOverlays(animFilePath, autotileConfigs, scale);

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderSuccess = screenshot(builderPath, 1280, 720);

			// Phase 2: macro + autotile grids
			clearScene();
			var macroRoot = createMp().blob47Fallback.create();
			macroRoot.setScale(scale);
			s2d.addChild(macroRoot);
			addAutotileOverlays(animFilePath, autotileConfigs, scale);
			if (testTitle != null && testTitle.length > 0) addTitleOverlay();

			waitForUpdate(function(dt2:Float) {
				var macroPath = 'test/screenshots/blob47Fallback_macro.png';
				var referencePath = getReferenceImagePath();
				var macroSuccess = screenshot(macroPath, 1280, 720);

				var builderSim = builderSuccess ? computeSimilarity(builderPath, referencePath) : 0.0;
				var macroSim = macroSuccess ? computeSimilarity(macroPath, referencePath) : 0.0;
				var builderOk = builderSim > threshold;
				var macroOk = macroSim > threshold;

				HtmlReportGenerator.addResultWithMacro(getDisplayName(), referencePath, builderPath, builderOk && macroOk,
					builderSim, null, macroPath, macroSim, macroOk, threshold, threshold);
				HtmlReportGenerator.generateReport();

				Assert.isTrue(builderOk, 'Builder should match reference (similarity: ${Math.round(builderSim * 10000) / 100}%)');
				Assert.isTrue(macroOk, 'Macro should match reference (similarity: ${Math.round(macroSim * 10000) / 100}%)');

				VisualTestBase.pendingVisualTests--;
				async.done();
			});
		});
	}

	// ==================== Autotile helper ====================

	/** Add autotile grids to the current scene with optional black backgrounds. */
	private function addAutotileOverlays(animFilePath:String,
			autotiles:Array<{name:String, grid:Array<Array<Int>>, x:Float, y:Float, background:Bool}>,
			scale:Float):Void {
		for (autotile in autotiles) {
			if (autotile.background) {
				var gridWidth = autotile.grid[0].length;
				var gridHeight = autotile.grid.length;
				var bgWidth = Std.int(gridWidth * 16 * scale);
				var bgHeight = Std.int(gridHeight * 16 * scale);
				var bg = new h2d.Bitmap(h2d.Tile.fromColor(0x000000, bgWidth, bgHeight), s2d);
				bg.x = autotile.x;
				bg.y = autotile.y;
			}
			autotileHelper.buildAutotileAndAddToScene(animFilePath, autotile.name, autotile.grid, autotile.x, autotile.y, scale);
		}
	}

	// ==================== MultiProgrammable factory: unit tests ====================

	@Test
	public function testMultiProgrammableButton():Void {
		final multi = createMp();
		final btn = multi.button.create();
		Assert.notNull(btn, "button.create() should return instance");
		Assert.isTrue(btn.numChildren > 0, "Button should have children");
	}

	@Test
	public function testMultiProgrammableHealthbar():Void {
		final multi = createMp();
		final hb = multi.healthbar.create();
		Assert.notNull(hb, "healthbar.create() should return instance");
		Assert.isTrue(hb.numChildren > 0, "Healthbar should have children");

		hb.setHealth(50);
		final textEl = findTextChild(hb);
		if (textEl != null)
			Assert.equals("50", textEl.text);
	}

	// ==================== Easing & Curves: macro codegen (3-image) ====================

	@Test
	public function test58_EasingCurvesDemo(async:utest.Async):Void {
		setupTest(58, "easingCurvesDemo");
		VisualTestBase.pendingVisualTests++;
		async.setTimeout(15000);

		final animFilePath = "test/examples/58-easingCurvesDemo/easingCurvesDemo.manim";
		final sizeX = 1280;
		final sizeY = 720;
		final curveNames = [
			"linear", "easeInQuad", "easeOutQuad", "easeInOutCubic",
			"easeOutBounce", "easeOutElastic", "easeInBack", "easeOutBack", "customPoints"
		];
		final pathNames = ["arc", "bezierS", "zigzag"];

		// Phase 1: builder — load .manim, draw curves/paths with dots
		clearScene();
		try {
			final fileContent = byte.ByteData.ofString(sys.io.File.getContent(animFilePath));
			final loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
			final builder = bh.multianim.MultiAnimBuilder.load(fileContent, loader, animFilePath);

			final curves = builder.getCurves();
			final paths = builder.getPaths();
			final pathMap = new Map<String, bh.paths.MultiAnimPaths.Path>();
			for (name in pathNames) pathMap.set(name, paths.getPath(name));

			final g = new h2d.Graphics(s2d);
			final font = loader.loadFont("m3x6");

			drawEasingCurvesVisualization(g, font, curves, curveNames, s2d);
			drawPathVisualization(g, font, pathMap, pathNames, s2d);
			drawNormalizationVisualization(g, font, paths, s2d);

			if (testTitle != null && testTitle.length > 0) addTitleOverlay();
		} catch (e:Dynamic) {
			var msg = 'Builder threw: $e';
			reportBuildFailure(msg);
			Assert.fail(msg);
			VisualTestBase.pendingVisualTests--;
			async.done();
			return;
		}

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderSuccess = false;
			try {
				builderSuccess = screenshot(builderPath, sizeX, sizeY);
			} catch (e:Dynamic) {
				Assert.fail('Builder screenshot threw: $e');
				VisualTestBase.pendingVisualTests--;
				async.done();
				return;
			}

			// Phase 2: macro — use generated factory methods
			clearScene();
			try {
				final mp = createMp();
				final g = new h2d.Graphics(s2d);
				final loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
				final font = loader.loadFont("m3x6");

				// Initialize the builder (needed for path/curve methods that delegate to it)
				mp.easingCurves.create();

				// Get curves via macro-generated methods
				final macroCurves = new Map<String, bh.paths.Curve.ICurve>();
				macroCurves.set("linear", mp.easingCurves.getCurve_linear());
				macroCurves.set("easeInQuad", mp.easingCurves.getCurve_easeInQuad());
				macroCurves.set("easeOutQuad", mp.easingCurves.getCurve_easeOutQuad());
				macroCurves.set("easeInOutCubic", mp.easingCurves.getCurve_easeInOutCubic());
				macroCurves.set("easeOutBounce", mp.easingCurves.getCurve_easeOutBounce());
				macroCurves.set("easeOutElastic", mp.easingCurves.getCurve_easeOutElastic());
				macroCurves.set("easeInBack", mp.easingCurves.getCurve_easeInBack());
				macroCurves.set("easeOutBack", mp.easingCurves.getCurve_easeOutBack());
				macroCurves.set("customPoints", mp.easingCurves.getCurve_customPoints());
				drawEasingCurvesVisualization(g, font, macroCurves, curveNames, s2d);

				// Get paths via macro-generated methods
				final macroPathMap = new Map<String, bh.paths.MultiAnimPaths.Path>();
				macroPathMap.set("arc", mp.easingCurves.getPath_arc());
				macroPathMap.set("bezierS", mp.easingCurves.getPath_bezierS());
				macroPathMap.set("zigzag", mp.easingCurves.getPath_zigzag());
				drawPathVisualization(g, font, macroPathMap, pathNames, s2d);

				// Normalization via macro: get arc path, then normalize it
				final macroArc = mp.easingCurves.getPath_arc();
				drawNormalizationVisualizationFromPath(g, font, macroArc, s2d);

				if (testTitle != null && testTitle.length > 0) addTitleOverlay();
			} catch (e:Dynamic) {
				Assert.fail('Macro threw: $e');
				VisualTestBase.pendingVisualTests--;
				async.done();
				return;
			}

			waitForUpdate(function(dt2:Float) {
				try {
					var macroPath = 'test/screenshots/easingCurvesDemo_macro.png';
					var referencePath = getReferenceImagePath();
					var macroSuccess = screenshot(macroPath, sizeX, sizeY);

					var builderSim = builderSuccess ? computeSimilarity(builderPath, referencePath) : 0.0;
					var macroSim = macroSuccess ? computeSimilarity(macroPath, referencePath) : 0.0;
					var builderOk = builderSim > 0.99;
					var macroOk = macroSim > 0.99;

					HtmlReportGenerator.addResultWithMacro(getDisplayName(), referencePath, builderPath, builderOk && macroOk,
						builderSim, null, macroPath, macroSim, macroOk, 0.99, 0.99);
					HtmlReportGenerator.generateReport();

					Assert.isTrue(builderOk, 'Builder should match reference (${Math.round(builderSim * 10000) / 100}%)');
					Assert.isTrue(macroOk, 'Macro should match reference (${Math.round(macroSim * 10000) / 100}%)');
				} catch (e:Dynamic) {
					Assert.fail('Screenshot/compare threw: $e');
				}
				VisualTestBase.pendingVisualTests--;
				async.done();
			});
		});
	}

	@Test
	public function test59_SegmentedCurvesDemo(async:utest.Async):Void {
		setupTest(59, "segmentedCurvesDemo");
		VisualTestBase.pendingVisualTests++;
		async.setTimeout(15000);

		final animFilePath = "test/examples/59-segmentedCurvesDemo/segmentedCurvesDemo.manim";
		final sizeX = 1280;
		final sizeY = 720;
		final curveNames = [
			"simpleEasing", "pointsCurve", "segDefaultValues",
			"segExplicitValues", "segOverlapping", "segGapped"
		];

		// Phase 1: builder
		clearScene();
		try {
			final fileContent = byte.ByteData.ofString(sys.io.File.getContent(animFilePath));
			final loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
			final builder = bh.multianim.MultiAnimBuilder.load(fileContent, loader, animFilePath);

			final curves = builder.getCurves();

			final g = new h2d.Graphics(s2d);
			final font = loader.loadFont("m3x6");

			drawEasingCurvesVisualization(g, font, curves, curveNames, s2d);

			if (testTitle != null && testTitle.length > 0) addTitleOverlay();
		} catch (e:Dynamic) {
			var msg = 'Builder threw: $e';
			reportBuildFailure(msg);
			Assert.fail(msg);
			VisualTestBase.pendingVisualTests--;
			async.done();
			return;
		}

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderSuccess = false;
			try {
				builderSuccess = screenshot(builderPath, sizeX, sizeY);
			} catch (e:Dynamic) {
				Assert.fail('Builder screenshot threw: $e');
				VisualTestBase.pendingVisualTests--;
				async.done();
				return;
			}

			// Phase 2: macro
			clearScene();
			try {
				final mp = createMp();
				final g = new h2d.Graphics(s2d);
				final loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
				final font = loader.loadFont("m3x6");

				mp.segmentedCurves.create();

				final macroCurves = new Map<String, bh.paths.Curve.ICurve>();
				macroCurves.set("simpleEasing", mp.segmentedCurves.getCurve_simpleEasing());
				macroCurves.set("pointsCurve", mp.segmentedCurves.getCurve_pointsCurve());
				macroCurves.set("segDefaultValues", mp.segmentedCurves.getCurve_segDefaultValues());
				macroCurves.set("segExplicitValues", mp.segmentedCurves.getCurve_segExplicitValues());
				macroCurves.set("segOverlapping", mp.segmentedCurves.getCurve_segOverlapping());
				macroCurves.set("segGapped", mp.segmentedCurves.getCurve_segGapped());
				drawEasingCurvesVisualization(g, font, macroCurves, curveNames, s2d);

				if (testTitle != null && testTitle.length > 0) addTitleOverlay();
			} catch (e:Dynamic) {
				Assert.fail('Macro threw: $e');
				VisualTestBase.pendingVisualTests--;
				async.done();
				return;
			}

			waitForUpdate(function(dt2:Float) {
				try {
					var macroPath = 'test/screenshots/segmentedCurvesDemo_macro.png';
					var referencePath = getReferenceImagePath();
					var macroSuccess = screenshot(macroPath, sizeX, sizeY);

					var builderSim = builderSuccess ? computeSimilarity(builderPath, referencePath) : 0.0;
					var macroSim = macroSuccess ? computeSimilarity(macroPath, referencePath) : 0.0;
					var builderOk = builderSim > 0.99;
					var macroOk = macroSim > 0.99;

					HtmlReportGenerator.addResultWithMacro(getDisplayName(), referencePath, builderPath, builderOk && macroOk,
						builderSim, null, macroPath, macroSim, macroOk, 0.99, 0.99);
					HtmlReportGenerator.generateReport();

					Assert.isTrue(builderOk, 'Builder should match reference (${Math.round(builderSim * 10000) / 100}%)');
					Assert.isTrue(macroOk, 'Macro should match reference (${Math.round(macroSim * 10000) / 100}%)');
				} catch (e:Dynamic) {
					Assert.fail('Screenshot/compare threw: $e');
				}
				VisualTestBase.pendingVisualTests--;
				async.done();
			});
		});
	}

	@Test
	public function test60_NewPathCommands(async:utest.Async):Void {
		setupTest(60, "newPathCommands");
		VisualTestBase.pendingVisualTests++;
		async.setTimeout(15000);

		final animFilePath = "test/examples/60-newPathCommands/newPathCommands.manim";
		final sizeX = 1280;
		final sizeY = 720;
		final pathNames = [
			"triangle", "pentagon", "moveToRel", "moveToAbs", "spiralExpand", "spiralShrink", "waveBasic",
			"waveAngled", "lineRel", "lineAbs", "arcTurn", "bezierSmooth", "combined", "checkpointClose"
		];

		// Phase 1: builder
		clearScene();
		try {
			final fileContent = byte.ByteData.ofString(sys.io.File.getContent(animFilePath));
			final loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
			final builder = bh.multianim.MultiAnimBuilder.load(fileContent, loader, animFilePath);

			final paths = builder.getPaths();
			final pathMap = new Map<String, bh.paths.MultiAnimPaths.Path>();
			for (name in pathNames) pathMap.set(name, paths.getPath(name));

			final g = new h2d.Graphics(s2d);
			final font = loader.loadFont("m3x6");

			drawPathGrid(g, font, pathMap, pathNames, s2d);

			if (testTitle != null && testTitle.length > 0) addTitleOverlay();
		} catch (e:Dynamic) {
			var msg = 'Builder threw: $e';
			reportBuildFailure(msg);
			Assert.fail(msg);
			VisualTestBase.pendingVisualTests--;
			async.done();
			return;
		}

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderSuccess = false;
			try {
				builderSuccess = screenshot(builderPath, sizeX, sizeY);
			} catch (e:Dynamic) {
				Assert.fail('Builder screenshot threw: $e');
				VisualTestBase.pendingVisualTests--;
				async.done();
				return;
			}

			// Phase 2: macro
			clearScene();
			try {
				final mp = createMp();
				final g = new h2d.Graphics(s2d);
				final loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
				final font = loader.loadFont("m3x6");

				mp.newPathCommands.create();

				final macroPathMap = new Map<String, bh.paths.MultiAnimPaths.Path>();
				macroPathMap.set("triangle", mp.newPathCommands.getPath_triangle());
				macroPathMap.set("pentagon", mp.newPathCommands.getPath_pentagon());
				macroPathMap.set("moveToRel", mp.newPathCommands.getPath_moveToRel());
				macroPathMap.set("moveToAbs", mp.newPathCommands.getPath_moveToAbs());
				macroPathMap.set("spiralExpand", mp.newPathCommands.getPath_spiralExpand());
				macroPathMap.set("spiralShrink", mp.newPathCommands.getPath_spiralShrink());
				macroPathMap.set("waveBasic", mp.newPathCommands.getPath_waveBasic());
				macroPathMap.set("waveAngled", mp.newPathCommands.getPath_waveAngled());
				macroPathMap.set("lineRel", mp.newPathCommands.getPath_lineRel());
				macroPathMap.set("lineAbs", mp.newPathCommands.getPath_lineAbs());
				macroPathMap.set("arcTurn", mp.newPathCommands.getPath_arcTurn());
				macroPathMap.set("bezierSmooth", mp.newPathCommands.getPath_bezierSmooth());
				macroPathMap.set("combined", mp.newPathCommands.getPath_combined());
				macroPathMap.set("checkpointClose", mp.newPathCommands.getPath_checkpointClose());
				drawPathGrid(g, font, macroPathMap, pathNames, s2d);

				if (testTitle != null && testTitle.length > 0) addTitleOverlay();
			} catch (e:Dynamic) {
				Assert.fail('Macro threw: $e');
				VisualTestBase.pendingVisualTests--;
				async.done();
				return;
			}

			waitForUpdate(function(dt2:Float) {
				try {
					var macroPath = 'test/screenshots/newPathCommands_macro.png';
					var referencePath = getReferenceImagePath();
					var macroSuccess = screenshot(macroPath, sizeX, sizeY);

					var builderSim = builderSuccess ? computeSimilarity(builderPath, referencePath) : 0.0;
					var macroSim = macroSuccess ? computeSimilarity(macroPath, referencePath) : 0.0;
					var builderOk = builderSim > 0.98;
					var macroOk = macroSim > 0.98;

					HtmlReportGenerator.addResultWithMacro(getDisplayName(), referencePath, builderPath, builderOk && macroOk,
						builderSim, null, macroPath, macroSim, macroOk, 0.98, 0.98);
					HtmlReportGenerator.generateReport();

					Assert.isTrue(builderOk, 'Builder should match reference (${Math.round(builderSim * 10000) / 100}%)');
					Assert.isTrue(macroOk, 'Macro should match reference (${Math.round(macroSim * 10000) / 100}%)');
				} catch (e:Dynamic) {
					Assert.fail('Screenshot/compare threw: $e');
				}
				VisualTestBase.pendingVisualTests--;
				async.done();
			});
		});
	}

	// ==================== AnimatedPath Curves: macro codegen (3-image) ====================

	@Test
	public function test61_AnimatedPathCurves(async:utest.Async):Void {
		setupTest(61, "animatedPathCurves");
		VisualTestBase.pendingVisualTests++;
		async.setTimeout(15000);

		final animFilePath = "test/examples/61-animatedPathCurves/animatedPathCurves.manim";
		final sizeX = 1280;
		final sizeY = 720;

		// Phase 1: builder
		clearScene();
		try {
			final fileContent = byte.ByteData.ofString(sys.io.File.getContent(animFilePath));
			final loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
			final builder = bh.multianim.MultiAnimBuilder.load(fileContent, loader, animFilePath);

			final g = new h2d.Graphics(s2d);
			final font = loader.loadFont("m3x6");

			// Background
			g.lineStyle(0);
			g.beginFill(0xC8B896);
			g.drawRect(0, 0, sizeX, sizeY);
			g.endFill();

			// Create animated paths and simulate them
			final animNames = ["distAnim", "timeAnim", "customAnim", "checkpointAnim"];

			drawAnimatedPathGrid(g, font, s2d, builder, animNames);
			drawAnimatedPathLegend(g, font, s2d);

			if (testTitle != null && testTitle.length > 0) addTitleOverlay();
		} catch (e:Dynamic) {
			var msg = 'Builder threw: $e';
			reportBuildFailure(msg);
			Assert.fail(msg);
			VisualTestBase.pendingVisualTests--;
			async.done();
			return;
		}

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderSuccess = false;
			try {
				builderSuccess = screenshot(builderPath, sizeX, sizeY);
			} catch (e:Dynamic) {
				Assert.fail('Builder screenshot threw: $e');
				VisualTestBase.pendingVisualTests--;
				async.done();
				return;
			}

			// Phase 2: macro
			clearScene();
			try {
				final mp = createMp();
				final g = new h2d.Graphics(s2d);
				final loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
				final font = loader.loadFont("m3x6");

				mp.animatedPathCurves.create();

				g.lineStyle(0);
				g.beginFill(0xC8B896);
				g.drawRect(0, 0, sizeX, sizeY);
				g.endFill();

				final animNames = ["distAnim", "timeAnim", "customAnim", "checkpointAnim"];

				drawAnimatedPathGridMacro(g, font, s2d, mp, animNames);
				drawAnimatedPathLegend(g, font, s2d);

				if (testTitle != null && testTitle.length > 0) addTitleOverlay();
			} catch (e:Dynamic) {
				Assert.fail('Macro threw: $e');
				VisualTestBase.pendingVisualTests--;
				async.done();
				return;
			}

			waitForUpdate(function(dt2:Float) {
				try {
					var macroPath = 'test/screenshots/animatedPathCurves_macro.png';
					var referencePath = getReferenceImagePath();
					var macroSuccess = screenshot(macroPath, sizeX, sizeY);

					var builderSim = builderSuccess ? computeSimilarity(builderPath, referencePath) : 0.0;
					var macroSim = macroSuccess ? computeSimilarity(macroPath, referencePath) : 0.0;
					var builderOk = builderSim > 0.99;
					var macroOk = macroSim > 0.99;

					HtmlReportGenerator.addResultWithMacro(getDisplayName(), referencePath, builderPath, builderOk && macroOk,
						builderSim, null, macroPath, macroSim, macroOk, 0.99, 0.99);
					HtmlReportGenerator.generateReport();

					Assert.isTrue(builderOk, 'Builder should match reference (${Math.round(builderSim * 10000) / 100}%)');
					Assert.isTrue(macroOk, 'Macro should match reference (${Math.round(macroSim * 10000) / 100}%)');
				} catch (e:Dynamic) {
					Assert.fail('Screenshot/compare threw: $e');
				}
				VisualTestBase.pendingVisualTests--;
				async.done();
			});
		});
	}

	// ==================== AnimatedPath visualization helpers ====================

	static function simulateAnimatedPath(ap:bh.paths.AnimatedPath):Array<bh.paths.AnimatedPath.AnimatedPathState> {
		var states:Array<bh.paths.AnimatedPath.AnimatedPathState> = [];
		var totalTime:Float = 0;
		final dt:Float = 0.05;
		while (totalTime < 5.0) {
			var state = ap.update(dt);
			states.push({
				position: state.position,
				angle: state.angle,
				rate: state.rate,
				speed: state.speed,
				scale: state.scale,
				alpha: state.alpha,
				rotation: state.rotation,
				done: state.done,
				custom: state.custom
			});
			totalTime += dt;
			if (state.done) break;
		}
		return states;
	}

	static function drawAnimatedPathCell(g:h2d.Graphics, states:Array<bh.paths.AnimatedPath.AnimatedPathState>,
			path:bh.paths.MultiAnimPaths.Path, baseX:Float, offsetY:Float):Void {
		// Draw path line
		g.lineStyle(1, 0x336633);
		for (i in 0...201) {
			final rate:Float = i / 200.0;
			final pt = path.getPoint(rate);
			if (i == 0)
				g.moveTo(baseX + pt.x, offsetY + pt.y);
			else
				g.lineTo(baseX + pt.x, offsetY + pt.y);
		}

		// Draw sampled positions: dot color = rate (white→black), dot alpha = alpha, dot size = scale
		for (state in states) {
			final dotX = baseX + state.position.x;
			final dotY = offsetY + state.position.y;
			final rateBrightness = Std.int((1.0 - bh.base.TweenUtils.FloatTools.clamp(state.rate, 0, 1)) * 255);
			final rateColor = (rateBrightness << 16) | (rateBrightness << 8) | rateBrightness;
			final scaleSize = state.scale * 3;
			g.lineStyle(0);
			g.beginFill(rateColor, bh.base.TweenUtils.FloatTools.clamp(state.alpha, 0, 1));
			g.drawCircle(dotX, dotY, scaleSize);
			g.endFill();
		}

		// Draw scale curve graph below path
		final curveY = offsetY + 120;
		if (states.length > 1) {
			g.lineStyle(1, 0x884444);
			for (i in 0...states.length) {
				final px = baseX + (i / states.length) * 200;
				final py = curveY - states[i].scale * 30;
				if (i == 0) g.moveTo(px, py); else g.lineTo(px, py);
			}
			// Draw alpha curve graph
			g.lineStyle(1, 0x448844);
			for (i in 0...states.length) {
				final px = baseX + (i / states.length) * 200;
				final py = curveY - states[i].alpha * 30;
				if (i == 0) g.moveTo(px, py); else g.lineTo(px, py);
			}
		}
	}

	function drawAnimatedPathGrid(g:h2d.Graphics, font:h2d.Font, parent:h2d.Object,
			builder:bh.multianim.MultiAnimBuilder, animNames:Array<String>):Void {
		for (col in 0...animNames.length) {
			final animName = animNames[col];
			final baseX:Float = 40 + col * 320;
			final baseY:Float = 40;

			var label = new h2d.Text(font, parent);
			label.text = animName;
			label.textColor = 0x222222;
			label.setPosition(baseX, 10);

			final ap = builder.createAnimatedPath(animName);
			final states = simulateAnimatedPath(ap);
			drawAnimatedPathCell(g, states, ap.path, baseX, baseY);
		}
	}

	function drawAnimatedPathGridMacro(g:h2d.Graphics, font:h2d.Font, parent:h2d.Object,
			mp:bh.test.MultiProgrammable, animNames:Array<String>):Void {
		for (col in 0...animNames.length) {
			final animName = animNames[col];
			final baseX:Float = 40 + col * 320;
			final baseY:Float = 40;

			var label = new h2d.Text(font, parent);
			label.text = animName;
			label.textColor = 0x222222;
			label.setPosition(baseX, 10);

			final ap = switch animName {
				case "distAnim": mp.animatedPathCurves.createAnimatedPath_distAnim();
				case "timeAnim": mp.animatedPathCurves.createAnimatedPath_timeAnim();
				case "customAnim": mp.animatedPathCurves.createAnimatedPath_customAnim();
				case "checkpointAnim": mp.animatedPathCurves.createAnimatedPath_checkpointAnim();
				default: throw 'unknown anim: $animName';
			};

			final states = simulateAnimatedPath(ap);
			drawAnimatedPathCell(g, states, ap.path, baseX, baseY);
		}
	}

	static function drawAnimatedPathLegend(g:h2d.Graphics, font:h2d.Font, parent:h2d.Object):Void {
		final legendX:Float = 20;
		final legendY:Float = 690;
		final spacing:Float = 160;

		// Path geometry
		g.lineStyle(2, 0x336633);
		g.moveTo(legendX, legendY + 4);
		g.lineTo(legendX + 20, legendY + 4);
		var t1 = new h2d.Text(font, parent);
		t1.text = "path";
		t1.textColor = 0x336633;
		t1.setPosition(legendX + 24, legendY - 3);

		// Dots: size = scale, color = rate (white→black), opacity = alpha
		final dotLegendX = legendX + spacing;
		g.lineStyle(0);
		g.beginFill(0xFFFFFF, 0.4);
		g.drawCircle(dotLegendX + 4, legendY + 4, 2);
		g.endFill();
		g.beginFill(0x888888);
		g.drawCircle(dotLegendX + 12, legendY + 4, 4);
		g.endFill();
		g.beginFill(0x000000);
		g.drawCircle(dotLegendX + 22, legendY + 4, 6);
		g.endFill();
		var t2 = new h2d.Text(font, parent);
		t2.text = "dots: size=scale, white..black=rate, opacity=alpha";
		t2.textColor = 0x555555;
		t2.setPosition(dotLegendX + 32, legendY - 3);

		// Scale curve
		final scaleLegendX = legendX + spacing * 2 + 120;
		g.lineStyle(2, 0x884444);
		g.moveTo(scaleLegendX, legendY + 4);
		g.lineTo(scaleLegendX + 20, legendY + 4);
		var t3 = new h2d.Text(font, parent);
		t3.text = "scale curve";
		t3.textColor = 0x884444;
		t3.setPosition(scaleLegendX + 24, legendY - 3);

		// Alpha curve
		final alphaLegendX = scaleLegendX + spacing;
		g.lineStyle(2, 0x448844);
		g.moveTo(alphaLegendX, legendY + 4);
		g.lineTo(alphaLegendX + 20, legendY + 4);
		var t4 = new h2d.Text(font, parent);
		t4.text = "alpha curve";
		t4.textColor = 0x448844;
		t4.setPosition(alphaLegendX + 24, legendY - 3);
	}

	// ==================== Easing/Curves visualization helpers ====================

	/** Draw easing curve dot plots: each curve as a row of dots showing eased position. */
	static function drawEasingCurvesVisualization(g:h2d.Graphics, font:h2d.Font, curves:Map<String, bh.paths.Curve.ICurve>,
			curveNames:Array<String>, parent:h2d.Object):Void {
		final startX:Float = 140;
		final width:Float = 200;
		final height:Float = 50;
		final baseY:Float = 30;
		final rowSpacing:Float = 65;
		final dotCount = 21;

		// Background
		g.lineStyle(0);
		g.beginFill(0xC8B896);
		g.drawRect(0, 0, 1280, 720);
		g.endFill();

		for (idx in 0...curveNames.length) {
			final name = curveNames[idx];
			final curve = curves.get(name);
			if (curve == null) continue;

			final rowY = baseY + idx * rowSpacing;

			// Label
			if (font != null) {
				var label = new h2d.Text(font, parent);
				label.text = name;
				label.textColor = 0x222222;
				label.setPosition(5, rowY + 10);
			}

			// Gray baseline
			g.lineStyle(1, 0x999988);
			g.moveTo(startX, rowY + height);
			g.lineTo(startX + width, rowY + height);

			// Gray top line
			g.moveTo(startX, rowY);
			g.lineTo(startX + width, rowY);

			// Dots along the easing curve: X = t * width, Y = value * height (inverted)
			// Colored white (t=0) to black (t=1)
			for (i in 0...dotCount) {
				final t:Float = i / (dotCount - 1);
				final value = curve.getValue(t);
				final dotX = startX + t * width;
				final dotY = rowY + height - value * height;

				final brightness = Std.int((1.0 - t) * 255);
				final color = (brightness << 16) | (brightness << 8) | brightness;
				g.lineStyle(0);
				g.beginFill(color);
				g.drawCircle(dotX, dotY, 3);
				g.endFill();
			}

			// Also draw a continuous thin line showing the curve shape
			g.lineStyle(1, 0x888877);
			for (i in 0...101) {
				final t:Float = i / 100.0;
				final value = curve.getValue(t);
				final px = startX + t * width;
				final py = rowY + height - value * height;
				if (i == 0)
					g.moveTo(px, py);
				else
					g.lineTo(px, py);
			}

			// Horizontal dots at fixed time intervals showing X spacing (easing effect)
			// Colored white (t=0) to black (t=1)
			final dotRowY = rowY + height + 12;
			for (i in 0...dotCount) {
				final t:Float = i / (dotCount - 1);
				final easedT = curve.getValue(t);
				final dotX = startX + easedT * width;

				final brightness = Std.int((1.0 - t) * 255);
				final color = (brightness << 16) | (brightness << 8) | brightness;
				g.lineStyle(0);
				g.beginFill(color);
				g.drawCircle(dotX, dotRowY, 2);
				g.endFill();
			}
		}
	}

	/** Draw paths with dots at uniform and eased rate intervals. */
	static function drawPathVisualization(g:h2d.Graphics, font:h2d.Font, pathMap:Map<String, bh.paths.MultiAnimPaths.Path>,
			pathNames:Array<String>, parent:h2d.Object):Void {
		final baseX:Float = 400;
		final baseY:Float = 30;
		final pathSpacing:Float = 200;
		final dotCount = 31;

		for (idx in 0...pathNames.length) {
			final name = pathNames[idx];
			final path = pathMap.get(name);
			if (path == null) continue;

			final offsetX = baseX + idx * (pathSpacing + 80);
			final offsetY = baseY + 60;

			// Label
			if (font != null) {
				var label = new h2d.Text(font, parent);
				label.text = "path: " + name;
				label.textColor = 0xAAFFAA;
				label.setPosition(offsetX, baseY);
			}

			// Draw continuous path line
			g.lineStyle(1, 0x336633);
			for (i in 0...201) {
				final rate:Float = i / 200.0;
				final pt = path.getPoint(rate);
				final px = offsetX + pt.x;
				final py = offsetY + pt.y;
				if (i == 0)
					g.moveTo(px, py);
				else
					g.lineTo(px, py);
			}

			// Draw dots at uniform rate intervals
			for (i in 0...dotCount) {
				final rate:Float = i / (dotCount - 1);
				final pt = path.getPoint(rate);
				final dotX = offsetX + pt.x;
				final dotY = offsetY + pt.y;

				g.lineStyle(0);
				g.beginFill(0x44FF44);
				g.drawCircle(dotX, dotY, 3);
				g.endFill();
			}

			// Draw eased dots (easeInOutCubic) in different color
			g.lineStyle(0);
			for (i in 0...dotCount) {
				final t:Float = i / (dotCount - 1);
				final easedRate = bh.base.TweenUtils.FloatTools.applyEasing(bh.multianim.MultiAnimParser.EasingType.EaseInOutCubic, t);
				final pt = path.getPoint(easedRate);
				final dotX = offsetX + pt.x;
				final dotY = offsetY + pt.y;

				g.beginFill(0xFF4444);
				g.drawCircle(dotX, dotY, 2);
				g.endFill();
			}

			// Legend
			if (font != null && idx == 0) {
				var legend1 = new h2d.Text(font, parent);
				legend1.text = "green=uniform  red=easeInOutCubic";
				legend1.textColor = 0x888888;
				legend1.setPosition(baseX, baseY + 15);
			}
		}
	}

	/** Draw path normalization example (builder version using MultiAnimPaths). */
	static function drawNormalizationVisualization(g:h2d.Graphics, font:h2d.Font, paths:bh.paths.MultiAnimPaths,
			parent:h2d.Object):Void {
		final arcPath = paths.getPath("arc");
		final normArc = paths.getPath("arc", new bh.base.FPoint(350, 100), new bh.base.FPoint(550, 20));
		drawNormalizationPaths(g, font, arcPath, normArc, parent);
	}

	/** Draw path normalization example (macro version using pre-built Path). */
	static function drawNormalizationVisualizationFromPath(g:h2d.Graphics, font:h2d.Font, arcPath:bh.paths.MultiAnimPaths.Path,
			parent:h2d.Object):Void {
		final normArc = arcPath.normalize(new bh.base.FPoint(350, 100), new bh.base.FPoint(550, 20));
		drawNormalizationPaths(g, font, arcPath, normArc, parent);
	}

	/** Shared normalization drawing logic. */
	static function drawNormalizationPaths(g:h2d.Graphics, font:h2d.Font, arcPath:bh.paths.MultiAnimPaths.Path,
			normArc:bh.paths.MultiAnimPaths.Path, parent:h2d.Object):Void {
		final normX:Float = 400;
		final normY:Float = 390;
		if (font != null) {
			var label = new h2d.Text(font, parent);
			label.text = "path normalization: arc (0,0)->(200,0) vs (50,100)->(250,20)";
			label.textColor = 0xFFAAAA;
			label.setPosition(normX, normY - 20);
		}

		// Original arc with no normalization
		g.lineStyle(1, 0x553333);
		for (i in 0...201) {
			final rate:Float = i / 200.0;
			final pt = arcPath.getPoint(rate);
			if (i == 0) g.moveTo(normX + pt.x, normY + pt.y);
			else g.lineTo(normX + pt.x, normY + pt.y);
		}
		for (i in 0...21) {
			final rate:Float = i / 20.0;
			final pt = arcPath.getPoint(rate);
			g.lineStyle(0);
			g.beginFill(0xFF6666);
			g.drawCircle(normX + pt.x, normY + pt.y, 3);
			g.endFill();
		}

		// Normalized arc
		final normStart = new bh.base.FPoint(350, 100);
		final normEnd = new bh.base.FPoint(550, 20);
		g.lineStyle(1, 0x335555);
		for (i in 0...201) {
			final rate:Float = i / 200.0;
			final pt = normArc.getPoint(rate);
			if (i == 0) g.moveTo(pt.x, normY - 100 + pt.y);
			else g.lineTo(pt.x, normY - 100 + pt.y);
		}
		for (i in 0...21) {
			final rate:Float = i / 20.0;
			final pt = normArc.getPoint(rate);
			g.lineStyle(0);
			g.beginFill(0x44FFFF);
			g.drawCircle(pt.x, normY - 100 + pt.y, 3);
			g.endFill();
		}

		// Mark start/end points
		g.lineStyle(0);
		g.beginFill(0xFFFFFF);
		g.drawCircle(normStart.x, normY - 100 + normStart.y, 4);
		g.endFill();
		g.beginFill(0xFFFF00);
		g.drawCircle(normEnd.x, normY - 100 + normEnd.y, 4);
		g.endFill();
	}

	/** Draw paths in a grid layout starting at (20,20). 7 columns, wrapping to next row.
	 *  Dots are colored white (rate=0) to black (rate=1) on a tan background. */
	static function drawPathGrid(g:h2d.Graphics, font:h2d.Font, pathMap:Map<String, bh.paths.MultiAnimPaths.Path>,
			pathNames:Array<String>, parent:h2d.Object):Void {
		final cols = 7;
		final cellW:Float = 175;
		final cellH:Float = 170;
		final baseX:Float = 20;
		final baseY:Float = 20;
		final labelH:Float = 12;
		final padding:Float = 5;
		final dotCount = 31;

		// Background
		g.lineStyle(0);
		g.beginFill(0xC8B896);
		g.drawRect(0, 0, 1280, 720);
		g.endFill();

		for (idx in 0...pathNames.length) {
			final name = pathNames[idx];
			final path = pathMap.get(name);
			if (path == null) continue;

			final col = idx % cols;
			final row = Std.int(idx / cols);
			final cellX = baseX + col * cellW;
			final cellY = baseY + row * cellH;

			// Sample points and compute bounding box
			var minX:Float = 1e9;
			var minY:Float = 1e9;
			var maxX:Float = -1e9;
			var maxY:Float = -1e9;
			var points = new Array<{x:Float, y:Float, rate:Float}>();
			for (i in 0...dotCount) {
				final rate:Float = i / (dotCount - 1);
				final pt = path.getPoint(rate);
				if (pt.x < minX) minX = pt.x;
				if (pt.y < minY) minY = pt.y;
				if (pt.x > maxX) maxX = pt.x;
				if (pt.y > maxY) maxY = pt.y;
				points.push({x: pt.x, y: pt.y, rate: rate});
			}

			// Available area below label
			final availW = cellW - padding * 2;
			final availH = cellH - labelH - padding * 3;
			final pathW = maxX - minX;
			final pathH = maxY - minY;

			// Scale to fit, preserving aspect ratio
			var scale:Float = 1.0;
			if (pathW > 0 && pathH > 0) {
				scale = Math.min(availW / pathW, availH / pathH);
			} else if (pathW > 0) {
				scale = availW / pathW;
			} else if (pathH > 0) {
				scale = availH / pathH;
			}
			if (scale > 1.0) scale = 1.0; // don't upscale

			final scaledW = pathW * scale;
			final scaledH = pathH * scale;

			// Center path in available area
			final drawAreaX = cellX + padding;
			final drawAreaY = cellY + labelH + padding * 2;
			final originX = drawAreaX + (availW - scaledW) / 2;
			final originY = drawAreaY + (availH - scaledH) / 2;

			// Label just above the path area
			if (font != null) {
				var label = new h2d.Text(font, parent);
				label.text = name;
				label.textColor = 0x222222;
				label.setPosition(cellX + padding, cellY + padding);
			}

			// Draw dots colored white (rate=0) to black (rate=1)
			for (p in points) {
				final brightness = Std.int((1.0 - p.rate) * 255);
				final color = (brightness << 16) | (brightness << 8) | brightness;
				g.lineStyle(0);
				g.beginFill(color);
				g.drawCircle(originX + (p.x - minX) * scale, originY + (p.y - minY) * scale, 2.5);
				g.endFill();
			}
		}
	}

	// ==================== Helpers ====================

	static function countVisibleChildren(obj:h2d.Object):Int {
		var count = 0;
		for (i in 0...obj.numChildren) {
			if (obj.getChildAt(i).visible)
				count++;
		}
		return count;
	}

	static function findTextChild(obj:h2d.Object):Null<h2d.Text> {
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, h2d.Text)) {
				final t:h2d.Text = cast child;
				if (t.visible)
					return t;
			}
		}
		return null;
	}

	static function countAllDescendants(obj:h2d.Object):Int {
		var count = obj.numChildren;
		for (i in 0...obj.numChildren) {
			count += countAllDescendants(obj.getChildAt(i));
		}
		return count;
	}

	static function countVisibleDescendants(obj:h2d.Object):Int {
		var count = 0;
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (child.visible) {
				count++;
				count += countVisibleDescendants(child);
			}
		}
		return count;
	}

	// ==================== Performance test: macro vs builder ====================

	@Test
	public function testMacroVsBuilderPerformance():Void {
		final iterations = 10000;
		final animFilePath = "test/examples/61-animatedPathCurves/animatedPathCurves.manim";

		// Pre-load builder (file I/O not included in benchmark)
		final fileContent = byte.ByteData.ofString(sys.io.File.getContent(animFilePath));
		final loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
		final builder = bh.multianim.MultiAnimBuilder.load(fileContent, loader, animFilePath);

		// Pre-create macro instance
		final mp = createMp();

		// Warm up both paths
		builder.createAnimatedPath("distAnim");
		builder.createAnimatedPath("timeAnim");
		builder.createAnimatedPath("customAnim");
		builder.createAnimatedPath("checkpointAnim");
		mp.animatedPathCurves.createAnimatedPath_distAnim();
		mp.animatedPathCurves.createAnimatedPath_timeAnim();
		mp.animatedPathCurves.createAnimatedPath_customAnim();
		mp.animatedPathCurves.createAnimatedPath_checkpointAnim();

		// Benchmark builder
		final builderStart = haxe.Timer.stamp();
		for (_ in 0...iterations) {
			builder.createAnimatedPath("distAnim");
			builder.createAnimatedPath("timeAnim");
			builder.createAnimatedPath("customAnim");
			builder.createAnimatedPath("checkpointAnim");
		}
		final builderTime = haxe.Timer.stamp() - builderStart;

		// Benchmark macro
		final macroStart = haxe.Timer.stamp();
		for (_ in 0...iterations) {
			mp.animatedPathCurves.createAnimatedPath_distAnim();
			mp.animatedPathCurves.createAnimatedPath_timeAnim();
			mp.animatedPathCurves.createAnimatedPath_customAnim();
			mp.animatedPathCurves.createAnimatedPath_checkpointAnim();
		}
		final macroTime = haxe.Timer.stamp() - macroStart;

		final speedup = builderTime / macroTime;
		trace('Performance: builder=${Std.int(builderTime * 1000)}ms, macro=${Std.int(macroTime * 1000)}ms, speedup=${Std.string(speedup).substr(0, 5)}x (${iterations} iterations)');
		Assert.isTrue(macroTime < builderTime, 'Macro should be faster than builder: macro=${macroTime}s, builder=${builderTime}s');
	}

	// ==================== Data block: unit tests ====================

	@Test
	public function testDataScalarFields():Void {
		final mp = createMp();
		final data = mp.gameData;
		Assert.notNull(data, "Data should be created");
		Assert.equals(5, data.maxLevel);
		Assert.equals("Warrior", data.name);
		Assert.equals(true, data.enabled);
		Assert.floatEquals(3.5, data.speed);
	}

	@Test
	public function testDataArrayFields():Void {
		final mp = createMp();
		final costs = mp.gameData.costs;
		Assert.notNull(costs, "costs array should not be null");
		Assert.equals(4, costs.length);
		Assert.equals(10, costs[0]);
		Assert.equals(20, costs[1]);
		Assert.equals(40, costs[2]);
		Assert.equals(80, costs[3]);
	}

	@Test
	public function testDataRecordFields():Void {
		final mp = createMp();
		final tiers = mp.gameData.tiers;
		Assert.notNull(tiers, "tiers array should not be null");
		Assert.equals(2, tiers.length);
		Assert.equals("Bronze", tiers[0].name);
		Assert.equals(10, tiers[0].cost);
		Assert.floatEquals(1.0, tiers[0].dmg);
		Assert.equals("Silver", tiers[1].name);
		Assert.equals(20, tiers[1].cost);
		Assert.floatEquals(1.5, tiers[1].dmg);
	}

	@Test
	public function testDataSingleRecord():Void {
		final mp = createMp();
		final dt = mp.gameData.defaultTier;
		Assert.notNull(dt, "defaultTier should not be null");
		Assert.equals("None", dt.name);
		Assert.equals(0, dt.cost);
		Assert.floatEquals(0.0, dt.dmg);
	}

	@Test
	public function testDataBuilderDynamic():Void {
		final animFilePath = "test/examples/62-dataBlock/dataBlock.manim";
		final fileContent = byte.ByteData.ofString(sys.io.File.getContent(animFilePath));
		final loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
		final builder = bh.multianim.MultiAnimBuilder.load(fileContent, loader, animFilePath);

		final data:Dynamic = builder.getData("gameData");
		Assert.notNull(data, "Builder getData should return non-null");
		Assert.equals(5, data.maxLevel);
		Assert.equals("Warrior", data.name);
		Assert.equals(true, data.enabled);

		final costs:Array<Dynamic> = data.costs;
		Assert.notNull(costs, "costs should not be null");
		Assert.equals(4, costs.length);
		Assert.equals(10, costs[0]);
		Assert.equals(80, costs[3]);

		final tiers:Array<Dynamic> = data.tiers;
		Assert.notNull(tiers, "tiers should not be null");
		Assert.equals(2, tiers.length);
		Assert.equals("Bronze", tiers[0].name);
		Assert.equals(10, tiers[0].cost);
	}

	@Test
	public function testDataOptionalFieldOmitted():Void {
		final mp = createMp();
		final bt = mp.gameData.basicTier;
		Assert.notNull(bt, "basicTier should not be null");
		Assert.equals("Basic", bt.name);
		Assert.equals(5, bt.cost);
		Assert.isNull(bt.dmg, "dmg should be null when omitted");
	}

	@Test
	public function testDataOptionalFieldProvided():Void {
		final mp = createMp();
		final dt = mp.gameData.defaultTier;
		Assert.notNull(dt, "defaultTier should not be null");
		Assert.notNull(dt.dmg, "dmg should not be null when provided");
		Assert.floatEquals(0.0, dt.dmg);
	}

	@Test
	public function testDataExposedType():Void {
		// The record type should be exposed as GameDataTier (PascalCase of dataName + recordName)
		final mp = createMp();
		final tier:bh.test.GameDataTier = mp.gameData.defaultTier;
		Assert.notNull(tier, "Should be assignable to exposed type");
		Assert.equals("None", tier.name);
	}

	@Test
	public function testDataTypePackage():Void {
		// typepackage puts the exposed type in a custom package
		final mp = createMp();
		final tier:bh.test.data.GameDataTier = mp.gameDataTypePkg.defaultTier;
		Assert.notNull(tier, "Should be assignable to type in custom package");
		Assert.equals("None", tier.name);
		Assert.equals(0, tier.cost);
	}

	@Test
	public function testDataMergeTypes():Void {
		// mergeTypes should reuse the same type for identical record signatures
		final mp = createMp();
		final tier1:bh.test.merged.GameDataTier = mp.gameDataMerged1.defaultTier;
		final tier2:bh.test.merged.GameDataTier = mp.gameDataMerged2.defaultTier;
		Assert.notNull(tier1, "merged1 tier should not be null");
		Assert.notNull(tier2, "merged2 tier should not be null");
		Assert.equals("None", tier1.name);
		Assert.equals("None", tier2.name);
	}

	// ==================== @final variable declaration ====================

	@Test
	public function test63_FinalVarDemo(async:utest.Async):Void {
		simpleTest(63, "finalVarDemo", async);
	}

	// ==================== Repeat rebuild: dynamic count changes ====================

	@Test
	public function test64_RepeatRebuild(async:utest.Async):Void {
		// Each variant: [initialCount, finalCount, initialCols, finalCols, initialRows, finalRows]
		final variants:Array<Array<Int>> = [
			[3, 5, 3, 5, 2, 5], // grow
			[10, 3, 10, 3, 10, 3], // shrink
			[0, 10, 0, 10, 0, 10], // from zero
			[10, 10, 10, 10, 10, 10], // no change
		];

		// Builder params: use the final values directly
		var params:Array<Map<String, Dynamic>> = [];
		for (v in variants) {
			var p = new Map<String, Dynamic>();
			p.set("count", v[1]);
			p.set("cols", v[3]);
			p.set("rows", v[5]);
			params.push(p);
		}

		multiInstanceMacroTest(64, "repeatRebuild", 1.0, 180.0, params, function(i:Int):h2d.Object {
			var mp = createMp();
			var v = variants[i];
			// Create with initial values, then set to final values
			var inst = mp.repeatRebuild.create(v[0], v[2], v[4]);
			inst.setCount(v[1]);
			inst.setCols(v[3]);
			inst.setRows(v[5]);
			return inst;
		}, async);
	}

	// ==================== Repeat all node types: bitmap/text/ninepatch/point with scale/alpha/align ====================

	@Test
	public function test65_RepeatAllNodes(async:utest.Async):Void {
		final variants:Array<Array<Int>> = [
			[2, 4], // grow
			[5, 2], // shrink
			[0, 3], // from zero
			[3, 3], // no change
		];

		var params:Array<Map<String, Dynamic>> = [];
		for (v in variants) {
			var p = new Map<String, Dynamic>();
			p.set("count", v[1]);
			params.push(p);
		}

		multiInstanceMacroTest(65, "repeatAllNodes", 1.0, 180.0, params, function(i:Int):h2d.Object {
			var mp = createMp();
			var v = variants[i];
			var inst = mp.repeatAllNodes.create(v[0]);
			inst.setCount(v[1]);
			return inst;
		}, async, 0.999);
	}

	// ==================== Flow background ninepatch: auto-sizing ====================

	@Test
	public function test66_FlowBgDemo(async:utest.Async):Void {
		setupTest(66, "flowBgDemo");
		builderAndMacroScreenshotAndCompare("test/examples/66-flowBgDemo/flowBgDemo.manim", "flowBgDemo",
			() -> createMp().flowBgDemo2.create(), async);
	}
}
