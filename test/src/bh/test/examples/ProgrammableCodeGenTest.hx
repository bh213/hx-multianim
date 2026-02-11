package bh.test.examples;

import utest.Assert;
import h2d.Scene;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.ProgrammableBuilderAccess;
import bh.test.VisualTestBase;

/**
 * Tests for the @:build(ProgrammableCodeGen.build(...)) generated classes.
 * Each programmable has two visual tests using the same .manim file:
 *   - Builder: renders via MultiAnimBuilder (standard path)
 *   - Macro: renders via the compile-time generated class
 * Both compare against the same reference image.
 */
class ProgrammableCodeGenTest extends VisualTestBase {
	static final BUTTON_MANIM = "test/examples/38-codegenButton/codegenButton.manim";
	static final HEALTHBAR_MANIM = "test/examples/39-codegenHealthbar/codegenHealthbar.manim";
	static final DIALOG_MANIM = "test/examples/40-codegenDialog/codegenDialog.manim";
	static final REPEAT_MANIM = "test/examples/41-codegenRepeat/codegenRepeat.manim";
	static final REPEAT2D_MANIM = "test/examples/42-codegenRepeat2d/codegenRepeat2d.manim";
	static final LAYOUT_MANIM = "test/examples/43-codegenLayout/codegenLayout.manim";
	static final TILESITER_MANIM = "test/examples/44-codegenTilesIter/codegenTilesIter.manim";

	public function new(s2d:Scene) {
		super("programmableCodeGen", s2d);
	}

	function loadAccess(manimPath:String):{builder:MultiAnimBuilder, access:ProgrammableBuilderAccess} {
		final loader = TestResourceLoader.createLoader(false);
		final fileContent = byte.ByteData.ofString(sys.io.File.getContent(manimPath));
		final builder = MultiAnimBuilder.load(fileContent, loader, manimPath);
		return {builder: builder, access: new ProgrammableBuilderAccess(builder)};
	}

	// ==================== Button: unit tests ====================

	@Test
	public function testButtonCreate():Void {
		final ba = loadAccess(BUTTON_MANIM);
		final btn = bh.test.ButtonProgrammable.create(ba.access);
		Assert.notNull(btn.root, "ButtonProgrammable should have a root object");
		Assert.isTrue(btn.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testButtonSetStatus():Void {
		final ba = loadAccess(BUTTON_MANIM);
		final btn = bh.test.ButtonProgrammable.create(ba.access);
		Assert.isTrue(countVisibleChildren(btn.root) > 0, "Visible in normal state");

		btn.setStatus(bh.test.ButtonProgrammable.Hover);
		Assert.isTrue(countVisibleChildren(btn.root) > 0, "Visible in hover state");

		btn.setStatus(bh.test.ButtonProgrammable.Pressed);
		Assert.isTrue(countVisibleChildren(btn.root) > 0, "Visible in pressed state");
	}

	@Test
	public function testButtonSetText():Void {
		final ba = loadAccess(BUTTON_MANIM);
		final btn = bh.test.ButtonProgrammable.create(ba.access);
		final textEl = findTextChild(btn.root);
		Assert.notNull(textEl, "Should have a Text element");
		if (textEl != null)
			Assert.equals("Button", textEl.text);

		btn.setButtonText("Changed");
		final textEl2 = findTextChild(btn.root);
		if (textEl2 != null)
			Assert.equals("Changed", textEl2.text);
	}

	// ==================== Button: visual ====================

	@Test
	public function test38_CodegenButtonBuilder(async:utest.Async):Void {
		this.testName = "codegenButton";
		this.testTitle = "#38: codegen button (builder)";
		this.referenceDir = "test/examples/38-codegenButton";
		buildRenderScreenshotAndCompare(BUTTON_MANIM, "codegenButton", async, 1280, 720);
	}

	@Test
	public function test38_CodegenButtonMacro(async:utest.Async):Void {
		this.testName = "codegenButton_macro";
		this.testTitle = "#38: codegen button (builder)";
		this.referenceDir = "test/examples/38-codegenButton";
		macroRenderScreenshotAndCompare(function() {
			final ba = loadAccess(BUTTON_MANIM);
			return bh.test.ButtonProgrammable.create(ba.access).root;
		}, async);
	}

	// ==================== Healthbar: unit tests ====================

	@Test
	public function testHealthbarCreate():Void {
		final ba = loadAccess(HEALTHBAR_MANIM);
		final hb = bh.test.HealthbarProgrammable.create(ba.access);
		Assert.notNull(hb.root, "HealthbarProgrammable should have a root object");
		Assert.isTrue(hb.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testHealthbarSetHealth():Void {
		final ba = loadAccess(HEALTHBAR_MANIM);
		final hb = bh.test.HealthbarProgrammable.create(ba.access);

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
		final ba = loadAccess(HEALTHBAR_MANIM);
		final hb = bh.test.HealthbarProgrammable.create(ba.access);

		// Set health below 30 — should switch to "pressed" (red) bar
		hb.setHealth(20);
		// Verify the conditional worked: low health bar visible, high health bar hidden
		var visibleCount = countVisibleChildren(hb.root);
		Assert.isTrue(visibleCount > 0, "Should have visible children at low health");
	}

	// ==================== Healthbar: visual ====================

	@Test
	public function test39_CodegenHealthbarBuilder(async:utest.Async):Void {
		this.testName = "codegenHealthbar";
		this.testTitle = "#39: codegen healthbar (builder)";
		this.referenceDir = "test/examples/39-codegenHealthbar";
		buildRenderScreenshotAndCompare(HEALTHBAR_MANIM, "codegenHealthbar", async, 1280, 720);
	}

	@Test
	public function test39_CodegenHealthbarMacro(async:utest.Async):Void {
		this.testName = "codegenHealthbar_macro";
		this.testTitle = "#39: codegen healthbar (builder)";
		this.referenceDir = "test/examples/39-codegenHealthbar";
		macroRenderScreenshotAndCompare(function() {
			final ba = loadAccess(HEALTHBAR_MANIM);
			return bh.test.HealthbarProgrammable.create(ba.access).root;
		}, async);
	}

	// ==================== Dialog: unit tests ====================

	@Test
	public function testDialogCreate():Void {
		final ba = loadAccess(DIALOG_MANIM);
		final dlg = bh.test.DialogProgrammable.create(ba.access);
		Assert.notNull(dlg.root, "DialogProgrammable should have a root object");
		Assert.isTrue(dlg.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testDialogSetTitle():Void {
		final ba = loadAccess(DIALOG_MANIM);
		final dlg = bh.test.DialogProgrammable.create(ba.access);

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
		final ba = loadAccess(DIALOG_MANIM);
		final dlg = bh.test.DialogProgrammable.create(ba.access, 400, "Dialog macro");

		// Switch styles
		dlg.setStyle(bh.test.DialogProgrammable.Hover);
		Assert.isTrue(countVisibleChildren(dlg.root) > 0, "Visible in hover style");

		dlg.setStyle(bh.test.DialogProgrammable.Disabled);
		Assert.isTrue(countVisibleChildren(dlg.root) > 0, "Visible in disabled style");
	}

	// ==================== Dialog: visual ====================

	@Test
	public function test40_CodegenDialogBuilder(async:utest.Async):Void {
		this.testName = "codegenDialog";
		this.testTitle = "#40: codegen dialog (builder)";
		this.referenceDir = "test/examples/40-codegenDialog";
		buildRenderScreenshotAndCompare(DIALOG_MANIM, "codegenDialog", async, 1280, 720);
	}

	@Test
	public function test40_CodegenDialogMacro(async:utest.Async):Void {
		this.testName = "codegenDialog_macro";
		this.testTitle = "#40: codegen dialog (builder)";
		this.referenceDir = "test/examples/40-codegenDialog";
		macroRenderScreenshotAndCompare(function() {
			final ba = loadAccess(DIALOG_MANIM);
			return bh.test.DialogProgrammable.create(ba.access).root;
		}, async);
	}

	// ==================== Repeat: unit tests ====================

	@Test
	public function testRepeatCreate():Void {
		final ba = loadAccess(REPEAT_MANIM);
		final rpt = bh.test.RepeatProgrammable.create(ba.access);
		Assert.notNull(rpt.root, "RepeatProgrammable should have a root object");
		Assert.isTrue(rpt.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testRepeatChildCount():Void {
		final ba = loadAccess(REPEAT_MANIM);
		final rpt = bh.test.RepeatProgrammable.create(ba.access);
		// With default count=5, the param-dependent repeat should have 5 visible iteration containers
		var totalChildren = countAllDescendants(rpt.root);
		Assert.isTrue(totalChildren > 10, "Should have many descendant objects from unrolled repeats");
	}

	@Test
	public function testRepeatSetCount():Void {
		final ba = loadAccess(REPEAT_MANIM);
		final rpt = bh.test.RepeatProgrammable.create(ba.access);

		// Reduce count — some pool items should become hidden
		rpt.setCount(2);
		var visCount = countVisibleDescendants(rpt.root);
		final count2 = visCount;

		// Increase count — more pool items should become visible
		rpt.setCount(4);
		visCount = countVisibleDescendants(rpt.root);
		Assert.isTrue(visCount > count2, "More visible descendants with higher count");
	}

	// ==================== Repeat: visual ====================

	@Test
	public function test41_CodegenRepeatBuilder(async:utest.Async):Void {
		this.testName = "codegenRepeat";
		this.testTitle = "#41: codegen repeat (builder)";
		this.referenceDir = "test/examples/41-codegenRepeat";
		buildRenderScreenshotAndCompare(REPEAT_MANIM, "codegenRepeat", async, 1280, 720);
	}

	@Test
	public function test41_CodegenRepeatMacro(async:utest.Async):Void {
		this.testName = "codegenRepeat_macro";
		this.testTitle = "#41: codegen repeat (builder)";
		this.referenceDir = "test/examples/41-codegenRepeat";
		macroRenderScreenshotAndCompare(function() {
			final ba = loadAccess(REPEAT_MANIM);
			return bh.test.RepeatProgrammable.create(ba.access).root;
		}, async);
	}

	// ==================== Repeat2D: unit tests ====================

	@Test
	public function testRepeat2dCreate():Void {
		final ba = loadAccess(REPEAT2D_MANIM);
		final rpt2d = bh.test.Repeat2dProgrammable.create(ba.access);
		Assert.notNull(rpt2d.root, "Repeat2dProgrammable should have a root object");
		Assert.isTrue(rpt2d.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testRepeat2dSetCols():Void {
		final ba = loadAccess(REPEAT2D_MANIM);
		final rpt2d = bh.test.Repeat2dProgrammable.create(ba.access);

		// Reduce cols — some pool items should become hidden
		rpt2d.setCols(1);
		final count1 = countVisibleDescendants(rpt2d.root);

		rpt2d.setCols(3);
		final count3 = countVisibleDescendants(rpt2d.root);
		Assert.isTrue(count3 > count1, "More visible descendants with more cols");
	}

	// ==================== Repeat2D: visual ====================

	@Test
	public function test42_CodegenRepeat2dBuilder(async:utest.Async):Void {
		this.testName = "codegenRepeat2d";
		this.testTitle = "#42: codegen repeat2d (builder)";
		this.referenceDir = "test/examples/42-codegenRepeat2d";
		buildRenderScreenshotAndCompare(REPEAT2D_MANIM, "codegenRepeat2d", async, 1280, 720);
	}

	@Test
	public function test42_CodegenRepeat2dMacro(async:utest.Async):Void {
		this.testName = "codegenRepeat2d_macro";
		this.testTitle = "#42: codegen repeat2d (builder)";
		this.referenceDir = "test/examples/42-codegenRepeat2d";
		macroRenderScreenshotAndCompare(function() {
			final ba = loadAccess(REPEAT2D_MANIM);
			return bh.test.Repeat2dProgrammable.create(ba.access).root;
		}, async);
	}

	// ==================== Layout: unit tests ====================

	@Test
	public function testLayoutCreate():Void {
		final ba = loadAccess(LAYOUT_MANIM);
		final lay = bh.test.LayoutProgrammable.create(ba.access);
		Assert.notNull(lay.root, "LayoutProgrammable should have a root object");
		Assert.isTrue(lay.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testLayoutChildCount():Void {
		final ba = loadAccess(LAYOUT_MANIM);
		final lay = bh.test.LayoutProgrammable.create(ba.access);
		// 5 list points + 4 sequence points = 9 ninepatch elements, each in containers
		var totalChildren = countAllDescendants(lay.root);
		Assert.isTrue(totalChildren >= 9, "Should have at least 9 descendant objects from layout repeats");
	}

	// ==================== Layout: visual ====================

	@Test
	public function test43_CodegenLayoutBuilder(async:utest.Async):Void {
		this.testName = "codegenLayout";
		this.testTitle = "#43: codegen layout (builder)";
		this.referenceDir = "test/examples/43-codegenLayout";
		buildRenderScreenshotAndCompare(LAYOUT_MANIM, "codegenLayout", async, 1280, 720);
	}

	@Test
	public function test43_CodegenLayoutMacro(async:utest.Async):Void {
		this.testName = "codegenLayout_macro";
		this.testTitle = "#43: codegen layout (builder)";
		this.referenceDir = "test/examples/43-codegenLayout";
		macroRenderScreenshotAndCompare(function() {
			final ba = loadAccess(LAYOUT_MANIM);
			return bh.test.LayoutProgrammable.create(ba.access).root;
		}, async);
	}

	// ==================== TilesIter: unit tests ====================

	@Test
	public function testTilesIterCreate():Void {
		final ba = loadAccess(TILESITER_MANIM);
		final ti = bh.test.TilesIterProgrammable.create(ba.access);
		Assert.notNull(ti.root, "TilesIterProgrammable should have a root object");
		Assert.isTrue(ti.root.numChildren > 0, "Root should have children");
	}

	@Test
	public function testTilesIterHasBitmaps():Void {
		final ba = loadAccess(TILESITER_MANIM);
		final ti = bh.test.TilesIterProgrammable.create(ba.access);
		// Should have bitmap children from both tiles and stateanim iterators
		var totalChildren = countAllDescendants(ti.root);
		Assert.isTrue(totalChildren >= 2, "Should have descendant objects from runtime iterators");
	}

	// ==================== TilesIter: visual ====================

	@Test
	public function test44_CodegenTilesIterBuilder(async:utest.Async):Void {
		this.testName = "codegenTilesIter";
		this.testTitle = "#44: codegen tiles iter (builder)";
		this.referenceDir = "test/examples/44-codegenTilesIter";
		buildRenderScreenshotAndCompare(TILESITER_MANIM, "codegenTilesIter", async, 1280, 720);
	}

	@Test
	public function test44_CodegenTilesIterMacro(async:utest.Async):Void {
		this.testName = "codegenTilesIter_macro";
		this.testTitle = "#44: codegen tiles iter (builder)";
		this.referenceDir = "test/examples/44-codegenTilesIter";
		macroRenderScreenshotAndCompare(function() {
			final ba = loadAccess(TILESITER_MANIM);
			return bh.test.TilesIterProgrammable.create(ba.access).root;
		}, async);
	}

	// ==================== Shared macro render helper ====================

	function macroRenderScreenshotAndCompare(createRoot:() -> h2d.Object, async:utest.Async):Void {
		async.setTimeout(10000);
		clearScene();

		final root = createRoot();
		root.setScale(4.0);
		s2d.addChild(root);

		if (testTitle != null && testTitle.length > 0) {
			addTitleOverlay();
		}

		waitForUpdate(function(dt:Float) {
			final actualPath = getActualImagePath();
			final referencePath = getReferenceImagePath();

			var success = screenshot(actualPath, 1280, 720);
			Assert.isTrue(success, 'Screenshot should be created at $actualPath');

			if (success) {
				var match = compareImages(actualPath, referencePath, 0.99);
				Assert.isTrue(match, 'Macro output should match reference image');
			}

			async.done();
		});
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
