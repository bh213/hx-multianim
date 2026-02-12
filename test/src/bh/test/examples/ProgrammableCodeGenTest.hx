package bh.test.examples;

import utest.Assert;
import h2d.Scene;
import bh.test.VisualTestBase;
import bh.test.HtmlReportGenerator;

/**
 * Tests for the @:build(ProgrammableCodeGen.buildAll()) generated classes.
 * All programmables are consolidated into MultiProgrammable with @:manim fields.
 * Visual tests use builderAndMacroScreenshotAndCompare() to produce 3-image comparisons:
 *   - Reference image
 *   - Builder (runtime) rendering
 *   - Macro (compile-time) rendering
 * Both builder and macro are compared against reference; test fails if either fails.
 */
class ProgrammableCodeGenTest extends VisualTestBase {
	public function new(s2d:Scene) {
		super("programmableCodeGen", s2d);
	}

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	// ==================== Button: unit tests ====================

	@Test
	public function testButtonCreate():Void {
		final mp = createMp();
		final btn = mp.button.create();
		Assert.notNull(btn.root, "Button should have a root object");
		Assert.isTrue(btn.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testButtonSetStatus():Void {
		final mp = createMp();
		final btn = mp.button.create();
		Assert.isTrue(countVisibleChildren(btn.root) > 0, "Visible in normal state");

		btn.setStatus(bh.test.MultiProgrammable_Button.Hover);
		Assert.isTrue(countVisibleChildren(btn.root) > 0, "Visible in hover state");

		btn.setStatus(bh.test.MultiProgrammable_Button.Pressed);
		Assert.isTrue(countVisibleChildren(btn.root) > 0, "Visible in pressed state");
	}

	@Test
	public function testButtonSetText():Void {
		final mp = createMp();
		final btn = mp.button.create();
		final textEl = findTextChild(btn.root);
		Assert.notNull(textEl, "Should have a Text element");
		if (textEl != null)
			Assert.equals("Button", textEl.text);

		btn.setButtonText("Changed");
		final textEl2 = findTextChild(btn.root);
		if (textEl2 != null)
			Assert.equals("Changed", textEl2.text);
	}

	// ==================== Button: visual (3-image) ====================

	@Test
	public function test38_CodegenButton(async:utest.Async):Void {
		this.testName = "codegenButton";
		this.testTitle = "#38: codegen button";
		this.referenceDir = "test/examples/38-codegenButton";
		builderAndMacroScreenshotAndCompare("test/examples/38-codegenButton/codegenButton.manim", "codegenButton", function() {
			return createMp().button.create().root;
		}, async, 1280, 720);
	}

	// ==================== Healthbar: unit tests ====================

	@Test
	public function testHealthbarCreate():Void {
		final mp = createMp();
		final hb = mp.healthbar.create();
		Assert.notNull(hb.root, "Healthbar should have a root object");
		Assert.isTrue(hb.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testHealthbarSetHealth():Void {
		final mp = createMp();
		final hb = mp.healthbar.create();

		// Check text shows health value
		final textEl = findTextChild(hb.root);
		Assert.notNull(textEl, "Should have health text");
		if (textEl != null)
			Assert.equals("75", textEl.text);

		// Change health
		hb.setHealth(50);
		final textEl2 = findTextChild(hb.root);
		if (textEl2 != null)
			Assert.equals("50", textEl2.text);
	}

	@Test
	public function testHealthbarLowHealth():Void {
		final mp = createMp();
		final hb = mp.healthbar.create();

		// Set health below 30 — should switch to "pressed" (red) bar
		hb.setHealth(20);
		// Verify the conditional worked: low health bar visible, high health bar hidden
		var visibleCount = countVisibleChildren(hb.root);
		Assert.isTrue(visibleCount > 0, "Should have visible children at low health");
	}

	// ==================== Healthbar: visual (3-image) ====================

	@Test
	public function test39_CodegenHealthbar(async:utest.Async):Void {
		this.testName = "codegenHealthbar";
		this.testTitle = "#39: codegen healthbar";
		this.referenceDir = "test/examples/39-codegenHealthbar";
		builderAndMacroScreenshotAndCompare("test/examples/39-codegenHealthbar/codegenHealthbar.manim", "codegenHealthbar", function() {
			return createMp().healthbar.create().root;
		}, async, 1280, 720);
	}

	// ==================== Dialog: unit tests ====================

	@Test
	public function testDialogCreate():Void {
		final mp = createMp();
		final dlg = mp.dialog.create();
		Assert.notNull(dlg.root, "Dialog should have a root object");
		Assert.isTrue(dlg.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testDialogSetTitle():Void {
		final mp = createMp();
		final dlg = mp.dialog.create();

		final textEl = findTextChild(dlg.root);
		Assert.notNull(textEl, "Should have title text");
		if (textEl != null)
			Assert.equals("Dialog", textEl.text);

		dlg.setTitle("New Title");
		final textEl2 = findTextChild(dlg.root);
		if (textEl2 != null)
			Assert.equals("New Title", textEl2.text);
	}

	@Test
	public function testDialogSetStyle():Void {
		final mp = createMp();
		final dlg = mp.dialog.create(400, "Dialog macro");

		// Switch styles
		dlg.setStyle(bh.test.MultiProgrammable_Dialog.Hover);
		Assert.isTrue(countVisibleChildren(dlg.root) > 0, "Visible in hover style");

		dlg.setStyle(bh.test.MultiProgrammable_Dialog.Disabled);
		Assert.isTrue(countVisibleChildren(dlg.root) > 0, "Visible in disabled style");
	}

	// ==================== Dialog: visual (3-image) ====================

	@Test
	public function test40_CodegenDialog(async:utest.Async):Void {
		this.testName = "codegenDialog";
		this.testTitle = "#40: codegen dialog";
		this.referenceDir = "test/examples/40-codegenDialog";
		builderAndMacroScreenshotAndCompare("test/examples/40-codegenDialog/codegenDialog.manim", "codegenDialog", function() {
			return createMp().dialog.create().root;
		}, async, 1280, 720);
	}

	// ==================== Repeat: unit tests ====================

	@Test
	public function testRepeatCreate():Void {
		final mp = createMp();
		final rpt = mp.repeat.create();
		Assert.notNull(rpt.root, "Repeat should have a root object");
		Assert.isTrue(rpt.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testRepeatChildCount():Void {
		final mp = createMp();
		final rpt = mp.repeat.create();
		// With default count=5, the param-dependent repeat should have 5 visible iteration containers
		var totalChildren = countAllDescendants(rpt.root);
		Assert.isTrue(totalChildren > 10, "Should have many descendant objects from unrolled repeats");
	}

	@Test
	public function testRepeatSetCount():Void {
		final mp = createMp();
		final rpt = mp.repeat.create();

		// Reduce count — some pool items should become hidden
		rpt.setCount(2);
		var visCount = countVisibleDescendants(rpt.root);
		final count2 = visCount;

		// Increase count — more pool items should become visible
		rpt.setCount(4);
		visCount = countVisibleDescendants(rpt.root);
		Assert.isTrue(visCount > count2, "More visible descendants with higher count");
	}

	// ==================== Repeat: visual (3-image) ====================

	@Test
	public function test41_CodegenRepeat(async:utest.Async):Void {
		this.testName = "codegenRepeat";
		this.testTitle = "#41: codegen repeat";
		this.referenceDir = "test/examples/41-codegenRepeat";
		builderAndMacroScreenshotAndCompare("test/examples/41-codegenRepeat/codegenRepeat.manim", "codegenRepeat", function() {
			return createMp().repeat.create().root;
		}, async, 1280, 720);
	}

	// ==================== Repeat2D: unit tests ====================

	@Test
	public function testRepeat2dCreate():Void {
		final mp = createMp();
		final rpt2d = mp.repeat2d.create();
		Assert.notNull(rpt2d.root, "Repeat2d should have a root object");
		Assert.isTrue(rpt2d.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testRepeat2dSetCols():Void {
		final mp = createMp();
		final rpt2d = mp.repeat2d.create();

		// Reduce cols — some pool items should become hidden
		rpt2d.setCols(1);
		final count1 = countVisibleDescendants(rpt2d.root);

		rpt2d.setCols(3);
		final count3 = countVisibleDescendants(rpt2d.root);
		Assert.isTrue(count3 > count1, "More visible descendants with more cols");
	}

	// ==================== Repeat2D: visual (3-image) ====================

	@Test
	public function test42_CodegenRepeat2d(async:utest.Async):Void {
		this.testName = "codegenRepeat2d";
		this.testTitle = "#42: codegen repeat2d";
		this.referenceDir = "test/examples/42-codegenRepeat2d";
		builderAndMacroScreenshotAndCompare("test/examples/42-codegenRepeat2d/codegenRepeat2d.manim", "codegenRepeat2d", function() {
			return createMp().repeat2d.create().root;
		}, async, 1280, 720);
	}

	// ==================== Layout: unit tests ====================

	@Test
	public function testLayoutCreate():Void {
		final mp = createMp();
		final lay = mp.layout.create();
		Assert.notNull(lay.root, "Layout should have a root object");
		Assert.isTrue(lay.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testLayoutChildCount():Void {
		final mp = createMp();
		final lay = mp.layout.create();
		// 5 list points + 4 sequence points = 9 ninepatch elements, each in containers
		var totalChildren = countAllDescendants(lay.root);
		Assert.isTrue(totalChildren >= 9, "Should have at least 9 descendant objects from layout repeats");
	}

	// ==================== Layout: visual (3-image) ====================

	@Test
	public function test43_CodegenLayout(async:utest.Async):Void {
		this.testName = "codegenLayout";
		this.testTitle = "#43: codegen layout";
		this.referenceDir = "test/examples/43-codegenLayout";
		builderAndMacroScreenshotAndCompare("test/examples/43-codegenLayout/codegenLayout.manim", "codegenLayout", function() {
			return createMp().layout.create().root;
		}, async, 1280, 720);
	}

	// ==================== TilesIter: unit tests ====================

	@Test
	public function testTilesIterCreate():Void {
		final mp = createMp();
		final ti = mp.tilesIter.create();
		Assert.notNull(ti.root, "TilesIter should have a root object");
		Assert.isTrue(ti.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testTilesIterHasBitmaps():Void {
		final mp = createMp();
		final ti = mp.tilesIter.create();
		// Should have bitmap children from both tiles and stateanim iterators
		var totalChildren = countAllDescendants(ti.root);
		Assert.isTrue(totalChildren >= 2, "Should have descendant objects from runtime iterators");
	}

	// ==================== TilesIter: visual (3-image) ====================

	@Test
	public function test44_CodegenTilesIter(async:utest.Async):Void {
		this.testName = "codegenTilesIter";
		this.testTitle = "#44: codegen tiles iter";
		this.referenceDir = "test/examples/44-codegenTilesIter";
		builderAndMacroScreenshotAndCompare("test/examples/44-codegenTilesIter/codegenTilesIter.manim", "codegenTilesIter", function() {
			return createMp().tilesIter.create().root;
		}, async, 1280, 720);
	}

	// ==================== Tint (reuses #37 tintDemo): visual (3-image) ====================

	@Test
	public function test37_TintDemo(async:utest.Async):Void {
		this.testName = "tintDemo";
		this.testTitle = "#37: tint";
		this.referenceDir = "test/examples/37-tintDemo";
		builderAndMacroScreenshotAndCompare("test/examples/37-tintDemo/tintDemo.manim", "tintDemo", function() {
			return createMp().tint.create().root;
		}, async, 1280, 720, 1.0);
	}

	// ==================== Graphics: visual (3-image) ====================

	@Test
	public function test46_CodegenGraphics(async:utest.Async):Void {
		this.testName = "codegenGraphics";
		this.testTitle = "#46: codegen graphics";
		this.referenceDir = "test/examples/46-codegenGraphics";
		builderAndMacroScreenshotAndCompare("test/examples/46-codegenGraphics/codegenGraphics.manim", "codegenGraphics", function() {
			return createMp().graphics.create().root;
		}, async, 1280, 720);
	}

	// ==================== Reference: visual (3-image) ====================

	@Test
	public function test47_CodegenReference(async:utest.Async):Void {
		this.testName = "codegenReference";
		this.testTitle = "#47: codegen reference";
		this.referenceDir = "test/examples/47-codegenReference";
		builderAndMacroScreenshotAndCompare("test/examples/47-codegenReference/codegenReference.manim", "codegenReference", function() {
			return createMp().reference.create().root;
		}, async, 1280, 720);
	}

	// ==================== FilterParam: unit tests ====================

	@Test
	public function testFilterParamCreate():Void {
		final mp = createMp();
		final fp = mp.filterParam.create();
		Assert.notNull(fp.root, "FilterParam should have a root object");
		Assert.isTrue(fp.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testFilterParamSetOutlineColor():Void {
		final mp = createMp();
		final fp = mp.filterParam.create();

		// Verify filter exists on first child (outline)
		final firstChild = fp.root.getChildAt(0);
		Assert.notNull(firstChild.filter, "First child should have an outline filter");

		// Change outline color — filter should update
		fp.setOutlineColor(0x00FF00);
		Assert.notNull(firstChild.filter, "Filter should still exist after color change");
	}

	@Test
	public function testFilterParamSetTintColor():Void {
		final mp = createMp();
		final fp = mp.filterParam.create();

		// Change tint color — tint should update
		fp.setTintColor(0xFF0000);
		// Just verify it doesn't crash — visual correctness verified by screenshot
		Assert.isTrue(fp.root.numChildren > 0, "Should still have children after tint change");
	}

	// ==================== FilterParam: visual (3-image) ====================

	@Test
	public function test48_CodegenFilterParam(async:utest.Async):Void {
		this.testName = "codegenFilterParam";
		this.testTitle = "#48: codegen filter param";
		this.referenceDir = "test/examples/48-codegenFilterParam";
		builderAndMacroScreenshotAndCompare("test/examples/48-codegenFilterParam/codegenFilterParam.manim", "codegenFilterParam", function() {
			return createMp().filterParam.create().root;
		}, async, 1280, 720);
	}

	// ==================== GridPos: unit tests ====================

	@Test
	public function testGridPosCreate():Void {
		final mp = createMp();
		final gp = mp.gridPos.create();
		Assert.notNull(gp.root, "GridPos should have a root object");
		Assert.isTrue(gp.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testGridPosChildCount():Void {
		final mp = createMp();
		final gp = mp.gridPos.create();
		// 4 posLayout points + 3 colLayout points = 7 bitmaps
		var totalChildren = countAllDescendants(gp.root);
		Assert.isTrue(totalChildren >= 7, "Should have at least 7 descendant objects from layout repeats");
	}

	// ==================== GridPos: visual (3-image) ====================

	@Test
	public function test49_CodegenGridPos(async:utest.Async):Void {
		this.testName = "codegenGridPos";
		this.testTitle = "#49: codegen grid pos";
		this.referenceDir = "test/examples/49-codegenGridPos";
		builderAndMacroScreenshotAndCompare("test/examples/49-codegenGridPos/codegenGridPos.manim", "codegenGridPos", function() {
			return createMp().gridPos.create().root;
		}, async, 1280, 720);
	}

	// ==================== HexPos: unit tests ====================

	@Test
	public function testHexPosCreate():Void {
		final mp = createMp();
		final hp = mp.hexPos.create();
		Assert.notNull(hp.root, "HexPos should have a root object");
		Assert.isTrue(hp.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testHexPosChildCount():Void {
		final mp = createMp();
		final hp = mp.hexPos.create();
		// 2 hex groups x (6 corners + 6 edges) = 24 bitmaps
		var totalChildren = countAllDescendants(hp.root);
		Assert.isTrue(totalChildren >= 24, "Should have at least 24 descendant objects from hex positioning");
	}

	// ==================== HexPos: visual (3-image) ====================

	@Test
	public function test50_CodegenHexPos(async:utest.Async):Void {
		this.testName = "codegenHexPos";
		this.testTitle = "#50: codegen hex pos";
		this.referenceDir = "test/examples/50-codegenHexPos";
		builderAndMacroScreenshotAndCompare("test/examples/50-codegenHexPos/codegenHexPos.manim", "codegenHexPos", function() {
			return createMp().hexPos.create().root;
		}, async, 1280, 720, 1.0);
	}

	// ==================== TextOpts: unit tests ====================

	@Test
	public function testTextOptsCreate():Void {
		final mp = createMp();
		final to = mp.textOpts.create();
		Assert.notNull(to.root, "TextOpts should have a root object");
		Assert.isTrue(to.root.numChildren > 0, "Root should have children");
	}

	// ==================== TextOpts: visual (3-image) ====================

	@Test
	public function test51_CodegenTextOpts(async:utest.Async):Void {
		this.testName = "codegenTextOpts";
		this.testTitle = "#51: codegen text opts";
		this.referenceDir = "test/examples/51-codegenTextOpts";
		builderAndMacroScreenshotAndCompare("test/examples/51-codegenTextOpts/codegenTextOpts.manim", "codegenTextOpts", function() {
			return createMp().textOpts.create().root;
		}, async, 1280, 720, 1.0);
	}

	// ==================== BoolFloat: unit tests ====================

	@Test
	public function testBoolFloatCreate():Void {
		final mp = createMp();
		final bf = mp.boolFloat.create();
		Assert.notNull(bf.root, "BoolFloat should have a root object");
		Assert.isTrue(bf.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testBoolFloatToggle():Void {
		final mp = createMp();
		final bf = mp.boolFloat.create();
		final vis1 = countVisibleChildren(bf.root);

		bf.setShowLabel(true);
		final vis2 = countVisibleChildren(bf.root);
		Assert.isTrue(vis2 > vis1, "Toggling showLabel on should increase visible children");

		bf.setShowBorder(false);
		Assert.isTrue(countVisibleChildren(bf.root) > 0, "Should still have visible children after border toggle");
	}

	@Test
	public function testBoolFloatAlpha():Void {
		final mp = createMp();
		final bf = mp.boolFloat.create();
		var foundAlpha = false;
		for (i in 0...bf.root.numChildren) {
			final child = bf.root.getChildAt(i);
			if (child.alpha < 1.0 && child.alpha > 0.0) {
				foundAlpha = true;
				break;
			}
		}
		Assert.isTrue(foundAlpha, "Should have a child with alpha < 1.0 from float param");
	}

	// ==================== BoolFloat: visual — multi-instance with different params ====================

	@Test
	public function test52_CodegenBoolFloat(async:utest.Async):Void {
		this.testName = "codegenBoolFloat";
		this.testTitle = "#52: codegen bool+float";
		this.referenceDir = "test/examples/52-codegenBoolFloat";
		async.setTimeout(15000);

		final SCALE = 2.0;
		final SPACING = 80.0;
		final MANIM = "test/examples/52-codegenBoolFloat/codegenBoolFloat.manim";

		// Phase 1: builder — 4 variants with different params
		clearScene();
		var container = new h2d.Object(s2d);
		container.setScale(SCALE);

		var fileContent = byte.ByteData.ofString(sys.io.File.getContent(MANIM));
		var loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
		var builder = bh.multianim.MultiAnimBuilder.load(fileContent, loader, MANIM);

		for (i in 0...4) {
			var p = new Map<String, Dynamic>();
			switch (i) {
				case 0: p.set("showBorder", "true"); p.set("showLabel", "false"); p.set("opacity", 0.8); p.set("barWidth", 1.5);
				case 1: p.set("showBorder", "false"); p.set("showLabel", "true"); p.set("opacity", 0.4); p.set("barWidth", 2.0);
				case 2: p.set("showBorder", "true"); p.set("showLabel", "true"); p.set("opacity", 1.0); p.set("barWidth", 0.5);
				case 3: p.set("showBorder", "false"); p.set("showLabel", "false"); p.set("opacity", 0.6); p.set("barWidth", 1.0);
			}
			var built = builder.buildWithParameters("codegenBoolFloat", p);
			if (built != null && built.object != null) {
				built.object.setPosition(0, i * SPACING);
				container.addChild(built.object);
			}
		}

		if (testTitle != null && testTitle.length > 0) addTitleOverlay();

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderSuccess = screenshot(builderPath, 1280, 720);

			// Phase 2: macro — same 4 variants
			clearScene();
			var mc = new h2d.Object(s2d);
			mc.setScale(SCALE);

			for (i in 0...4) {
				var mp = createMp();
				var root = switch (i) {
					case 0: mp.boolFloat.create(true, false, 0.8, 1.5).root;
					case 1: mp.boolFloat.create(false, true, 0.4, 2.0).root;
					case 2: mp.boolFloat.create(true, true, 1.0, 0.5).root;
					default: mp.boolFloat.create(false, false, 0.6, 1.0).root;
				};
				root.setPosition(0, i * SPACING);
				mc.addChild(root);
			}

			if (testTitle != null && testTitle.length > 0) addTitleOverlay();

			waitForUpdate(function(dt2:Float) {
				var macroPath = 'test/screenshots/${testName}_macro.png';
				var macroSuccess = screenshot(macroPath, 1280, 720);
				var referencePath = getReferenceImagePath();

				var builderSim = builderSuccess ? computeSimilarity(builderPath, referencePath) : 0.0;
				var macroSim = macroSuccess ? computeSimilarity(macroPath, referencePath) : 0.0;
				var builderOk = builderSim > 0.99;
				var macroOk = macroSim > 0.99;

				var displayName = '#52: codegenBoolFloat';
				HtmlReportGenerator.addResultWithMacro(displayName, referencePath, builderPath, builderOk && macroOk,
					builderSim, null, macroPath, macroSim, macroOk);
				HtmlReportGenerator.generateReport();

				Assert.isTrue(builderOk, 'Builder should match reference (${Math.round(builderSim * 10000) / 100}%)');
				Assert.isTrue(macroOk, 'Macro should match reference (${Math.round(macroSim * 10000) / 100}%)');
				async.done();
			});
		});
	}

	// ==================== RangeFlags: unit tests ====================

	@Test
	public function testRangeFlagsCreate():Void {
		final mp = createMp();
		final rf = mp.rangeFlags.create();
		Assert.notNull(rf.root, "RangeFlags should have a root object");
		Assert.isTrue(rf.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testRangeFlagsLevelConditional():Void {
		final mp = createMp();
		final rf = mp.rangeFlags.create();
		final vis1 = countVisibleChildren(rf.root);
		Assert.isTrue(vis1 > 0, "Should have visible children at level 60");

		rf.setLevel(20);
		final vis2 = countVisibleChildren(rf.root);
		Assert.isTrue(vis2 > 0, "Should have visible children at level 20");

		final textEl = findTextChild(rf.root);
		Assert.notNull(textEl, "Should have a text element");
		if (textEl != null)
			Assert.equals("20", textEl.text);
	}

	// ==================== RangeFlags: visual — multi-instance with different params ====================

	@Test
	public function test53_CodegenRangeFlags(async:utest.Async):Void {
		this.testName = "codegenRangeFlags";
		this.testTitle = "#53: codegen range+flags";
		this.referenceDir = "test/examples/53-codegenRangeFlags";
		async.setTimeout(15000);

		final SCALE = 2.0;
		final SPACING = 75.0;
		final MANIM = "test/examples/53-codegenRangeFlags/codegenRangeFlags.manim";

		// Phase 1: builder — 4 variants with different params
		clearScene();
		var container = new h2d.Object(s2d);
		container.setScale(SCALE);

		var fileContent = byte.ByteData.ofString(sys.io.File.getContent(MANIM));
		var loader:bh.base.ResourceLoader = TestResourceLoader.createLoader(false);
		var builder = bh.multianim.MultiAnimBuilder.load(fileContent, loader, MANIM);

		for (i in 0...4) {
			var p = new Map<String, Dynamic>();
			switch (i) {
				case 0: p.set("level", 60); p.set("power", 30); p.set("bits", 5);
				case 1: p.set("level", 20); p.set("power", 45); p.set("bits", 3);
				case 2: p.set("level", 80); p.set("power", 10); p.set("bits", 7);
				case 3: p.set("level", 50); p.set("power", 50); p.set("bits", 0);
			}
			var built = builder.buildWithParameters("codegenRangeFlags", p);
			if (built != null && built.object != null) {
				built.object.setPosition(0, i * SPACING);
				container.addChild(built.object);
			}
		}

		if (testTitle != null && testTitle.length > 0) addTitleOverlay();

		waitForUpdate(function(dt:Float) {
			var builderPath = getActualImagePath();
			var builderSuccess = screenshot(builderPath, 1280, 720);

			// Phase 2: macro — same 4 variants
			clearScene();
			var mc = new h2d.Object(s2d);
			mc.setScale(SCALE);

			for (i in 0...4) {
				var mp = createMp();
				var root = switch (i) {
					case 0: mp.rangeFlags.create(60, 30, 5).root;
					case 1: mp.rangeFlags.create(20, 45, 3).root;
					case 2: mp.rangeFlags.create(80, 10, 7).root;
					default: mp.rangeFlags.create(50, 50, 0).root;
				};
				root.setPosition(0, i * SPACING);
				mc.addChild(root);
			}

			if (testTitle != null && testTitle.length > 0) addTitleOverlay();

			waitForUpdate(function(dt2:Float) {
				var macroPath = 'test/screenshots/${testName}_macro.png';
				var macroSuccess = screenshot(macroPath, 1280, 720);
				var referencePath = getReferenceImagePath();

				var builderSim = builderSuccess ? computeSimilarity(builderPath, referencePath) : 0.0;
				var macroSim = macroSuccess ? computeSimilarity(macroPath, referencePath) : 0.0;
				var builderOk = builderSim > 0.99;
				var macroOk = macroSim > 0.99;

				var displayName = '#53: codegenRangeFlags';
				HtmlReportGenerator.addResultWithMacro(displayName, referencePath, builderPath, builderOk && macroOk,
					builderSim, null, macroPath, macroSim, macroOk);
				HtmlReportGenerator.generateReport();

				Assert.isTrue(builderOk, 'Builder should match reference (${Math.round(builderSim * 10000) / 100}%)');
				Assert.isTrue(macroOk, 'Macro should match reference (${Math.round(macroSim * 10000) / 100}%)');
				async.done();
			});
		});
	}

	// ==================== MultiProgrammable factory: unit tests ====================

	@Test
	public function testMultiProgrammableButton():Void {
		final multi = createMp();
		final btn = multi.button.create();
		Assert.notNull(btn, "button.create() should return companion instance");
		Assert.notNull(btn.root, "Button companion should have a root");
		Assert.isTrue(btn.root.numChildren > 0, "Button root should have children");
	}

	@Test
	public function testMultiProgrammableHealthbar():Void {
		final multi = createMp();
		final hb = multi.healthbar.create();
		Assert.notNull(hb, "healthbar.create() should return companion instance");
		Assert.notNull(hb.root, "Healthbar companion should have a root");
		Assert.isTrue(hb.root.numChildren > 0, "Healthbar root should have children");

		// Verify typed setter works
		hb.setHealth(50);
		final textEl = findTextChild(hb.root);
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
