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

	// ==================== RepeatableDemo: macro comparison ====================

	@Test
	public function test04_RepeatableDemo(async:utest.Async):Void {
		setupTest(4, "repeatableDemo");
		builderAndMacroScreenshotAndCompare("test/examples/4-repeatableDemo/repeatableDemo.manim", "repeatableDemo",
			() -> createMp().repeatableDemo.create(), async, null, null, null, 0.999);
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
}
