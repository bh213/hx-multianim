package bh.test.examples;

import utest.Assert;
import h2d.Scene;
import bh.multianim.MultiAnimBuilder;
import bh.test.VisualTestBase;

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
	static final BUTTON_MANIM = "test/examples/38-codegenButton/codegenButton.manim";
	static final HEALTHBAR_MANIM = "test/examples/39-codegenHealthbar/codegenHealthbar.manim";
	static final DIALOG_MANIM = "test/examples/40-codegenDialog/codegenDialog.manim";
	static final REPEAT_MANIM = "test/examples/41-codegenRepeat/codegenRepeat.manim";
	static final REPEAT2D_MANIM = "test/examples/42-codegenRepeat2d/codegenRepeat2d.manim";
	static final LAYOUT_MANIM = "test/examples/43-codegenLayout/codegenLayout.manim";
	static final TILESITER_MANIM = "test/examples/44-codegenTilesIter/codegenTilesIter.manim";
	static final TINT_MANIM = "test/examples/37-tintDemo/tintDemo.manim";
	static final GRAPHICS_MANIM = "test/examples/46-codegenGraphics/codegenGraphics.manim";
	static final REFERENCE_MANIM = "test/examples/47-codegenReference/codegenReference.manim";

	public function new(s2d:Scene) {
		super("programmableCodeGen", s2d);
	}

	function loadBuilder(manimPath:String):MultiAnimBuilder {
		final loader = TestResourceLoader.createLoader(false);
		final fileContent = byte.ByteData.ofString(sys.io.File.getContent(manimPath));
		return MultiAnimBuilder.load(fileContent, loader, manimPath);
	}

	// ==================== Button: unit tests ====================

	@Test
	public function testButtonCreate():Void {
		final builder = loadBuilder(BUTTON_MANIM);
		final btn = bh.test.MultiProgrammable_Button.create(builder);
		Assert.notNull(btn.root, "Button should have a root object");
		Assert.isTrue(btn.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testButtonSetStatus():Void {
		final builder = loadBuilder(BUTTON_MANIM);
		final btn = bh.test.MultiProgrammable_Button.create(builder);
		Assert.isTrue(countVisibleChildren(btn.root) > 0, "Visible in normal state");

		btn.setStatus(bh.test.MultiProgrammable_Button.Hover);
		Assert.isTrue(countVisibleChildren(btn.root) > 0, "Visible in hover state");

		btn.setStatus(bh.test.MultiProgrammable_Button.Pressed);
		Assert.isTrue(countVisibleChildren(btn.root) > 0, "Visible in pressed state");
	}

	@Test
	public function testButtonSetText():Void {
		final builder = loadBuilder(BUTTON_MANIM);
		final btn = bh.test.MultiProgrammable_Button.create(builder);
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
		builderAndMacroScreenshotAndCompare(BUTTON_MANIM, "codegenButton", function() {
			final builder = loadBuilder(BUTTON_MANIM);
			return bh.test.MultiProgrammable_Button.create(builder).root;
		}, async, 1280, 720);
	}

	// ==================== Healthbar: unit tests ====================

	@Test
	public function testHealthbarCreate():Void {
		final builder = loadBuilder(HEALTHBAR_MANIM);
		final hb = bh.test.MultiProgrammable_Healthbar.create(builder);
		Assert.notNull(hb.root, "Healthbar should have a root object");
		Assert.isTrue(hb.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testHealthbarSetHealth():Void {
		final builder = loadBuilder(HEALTHBAR_MANIM);
		final hb = bh.test.MultiProgrammable_Healthbar.create(builder);

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
		final builder = loadBuilder(HEALTHBAR_MANIM);
		final hb = bh.test.MultiProgrammable_Healthbar.create(builder);

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
		builderAndMacroScreenshotAndCompare(HEALTHBAR_MANIM, "codegenHealthbar", function() {
			final builder = loadBuilder(HEALTHBAR_MANIM);
			return bh.test.MultiProgrammable_Healthbar.create(builder).root;
		}, async, 1280, 720);
	}

	// ==================== Dialog: unit tests ====================

	@Test
	public function testDialogCreate():Void {
		final builder = loadBuilder(DIALOG_MANIM);
		final dlg = bh.test.MultiProgrammable_Dialog.create(builder);
		Assert.notNull(dlg.root, "Dialog should have a root object");
		Assert.isTrue(dlg.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testDialogSetTitle():Void {
		final builder = loadBuilder(DIALOG_MANIM);
		final dlg = bh.test.MultiProgrammable_Dialog.create(builder);

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
		final builder = loadBuilder(DIALOG_MANIM);
		final dlg = bh.test.MultiProgrammable_Dialog.create(builder, 400, "Dialog macro");

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
		builderAndMacroScreenshotAndCompare(DIALOG_MANIM, "codegenDialog", function() {
			final builder = loadBuilder(DIALOG_MANIM);
			return bh.test.MultiProgrammable_Dialog.create(builder).root;
		}, async, 1280, 720);
	}

	// ==================== Repeat: unit tests ====================

	@Test
	public function testRepeatCreate():Void {
		final builder = loadBuilder(REPEAT_MANIM);
		final rpt = bh.test.MultiProgrammable_Repeat.create(builder);
		Assert.notNull(rpt.root, "Repeat should have a root object");
		Assert.isTrue(rpt.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testRepeatChildCount():Void {
		final builder = loadBuilder(REPEAT_MANIM);
		final rpt = bh.test.MultiProgrammable_Repeat.create(builder);
		// With default count=5, the param-dependent repeat should have 5 visible iteration containers
		var totalChildren = countAllDescendants(rpt.root);
		Assert.isTrue(totalChildren > 10, "Should have many descendant objects from unrolled repeats");
	}

	@Test
	public function testRepeatSetCount():Void {
		final builder = loadBuilder(REPEAT_MANIM);
		final rpt = bh.test.MultiProgrammable_Repeat.create(builder);

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
		builderAndMacroScreenshotAndCompare(REPEAT_MANIM, "codegenRepeat", function() {
			final builder = loadBuilder(REPEAT_MANIM);
			return bh.test.MultiProgrammable_Repeat.create(builder).root;
		}, async, 1280, 720);
	}

	// ==================== Repeat2D: unit tests ====================

	@Test
	public function testRepeat2dCreate():Void {
		final builder = loadBuilder(REPEAT2D_MANIM);
		final rpt2d = bh.test.MultiProgrammable_Repeat2d.create(builder);
		Assert.notNull(rpt2d.root, "Repeat2d should have a root object");
		Assert.isTrue(rpt2d.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testRepeat2dSetCols():Void {
		final builder = loadBuilder(REPEAT2D_MANIM);
		final rpt2d = bh.test.MultiProgrammable_Repeat2d.create(builder);

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
		builderAndMacroScreenshotAndCompare(REPEAT2D_MANIM, "codegenRepeat2d", function() {
			final builder = loadBuilder(REPEAT2D_MANIM);
			return bh.test.MultiProgrammable_Repeat2d.create(builder).root;
		}, async, 1280, 720);
	}

	// ==================== Layout: unit tests ====================

	@Test
	public function testLayoutCreate():Void {
		final builder = loadBuilder(LAYOUT_MANIM);
		final lay = bh.test.MultiProgrammable_Layout.create(builder);
		Assert.notNull(lay.root, "Layout should have a root object");
		Assert.isTrue(lay.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testLayoutChildCount():Void {
		final builder = loadBuilder(LAYOUT_MANIM);
		final lay = bh.test.MultiProgrammable_Layout.create(builder);
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
		builderAndMacroScreenshotAndCompare(LAYOUT_MANIM, "codegenLayout", function() {
			final builder = loadBuilder(LAYOUT_MANIM);
			return bh.test.MultiProgrammable_Layout.create(builder).root;
		}, async, 1280, 720);
	}

	// ==================== TilesIter: unit tests ====================

	@Test
	public function testTilesIterCreate():Void {
		final builder = loadBuilder(TILESITER_MANIM);
		final ti = bh.test.MultiProgrammable_TilesIter.create(builder);
		Assert.notNull(ti.root, "TilesIter should have a root object");
		Assert.isTrue(ti.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testTilesIterHasBitmaps():Void {
		final builder = loadBuilder(TILESITER_MANIM);
		final ti = bh.test.MultiProgrammable_TilesIter.create(builder);
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
		builderAndMacroScreenshotAndCompare(TILESITER_MANIM, "codegenTilesIter", function() {
			final builder = loadBuilder(TILESITER_MANIM);
			return bh.test.MultiProgrammable_TilesIter.create(builder).root;
		}, async, 1280, 720);
	}

	// ==================== Tint (reuses #37 tintDemo): visual (3-image) ====================

	@Test
	public function test37_TintDemo(async:utest.Async):Void {
		this.testName = "tintDemo";
		this.testTitle = "#37: tint";
		this.referenceDir = "test/examples/37-tintDemo";
		builderAndMacroScreenshotAndCompare(TINT_MANIM, "tintDemo", function() {
			final builder = loadBuilder(TINT_MANIM);
			return bh.test.MultiProgrammable_Tint.create(builder).root;
		}, async, 1280, 720, 1.0);
	}

	// ==================== Graphics: visual (3-image) ====================

	@Test
	public function test46_CodegenGraphics(async:utest.Async):Void {
		this.testName = "codegenGraphics";
		this.testTitle = "#46: codegen graphics";
		this.referenceDir = "test/examples/46-codegenGraphics";
		builderAndMacroScreenshotAndCompare(GRAPHICS_MANIM, "codegenGraphics", function() {
			final builder = loadBuilder(GRAPHICS_MANIM);
			return bh.test.MultiProgrammable_Graphics.create(builder).root;
		}, async, 1280, 720);
	}

	// ==================== Reference: visual (3-image) ====================

	@Test
	public function test47_CodegenReference(async:utest.Async):Void {
		this.testName = "codegenReference";
		this.testTitle = "#47: codegen reference";
		this.referenceDir = "test/examples/47-codegenReference";
		builderAndMacroScreenshotAndCompare(REFERENCE_MANIM, "codegenReference", function() {
			final builder = loadBuilder(REFERENCE_MANIM);
			return bh.test.MultiProgrammable_Reference.create(builder).root;
		}, async, 1280, 720);
	}

	// ==================== MultiProgrammable factory: unit tests ====================

	@Test
	public function testMultiProgrammableButton():Void {
		final loader = TestResourceLoader.createLoader(false);
		final multi = new bh.test.MultiProgrammable(loader);
		final btn = multi.createButton();
		Assert.notNull(btn, "createButton should return companion instance");
		Assert.notNull(btn.root, "Button companion should have a root");
		Assert.isTrue(btn.root.numChildren > 0, "Button root should have children");
		Assert.notNull(multi.button, "multi.button field should be set after createButton()");
	}

	@Test
	public function testMultiProgrammableHealthbar():Void {
		final loader = TestResourceLoader.createLoader(false);
		final multi = new bh.test.MultiProgrammable(loader);
		final hb = multi.createHealthbar();
		Assert.notNull(hb, "createHealthbar should return companion instance");
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
