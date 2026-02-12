package bh.test;

@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class MultiProgrammable extends bh.multianim.ProgrammableBuilder {
	@:manim("test/examples/38-codegenButton/codegenButton.manim", "codegenButton")
	public var button;

	@:manim("test/examples/39-codegenHealthbar/codegenHealthbar.manim", "codegenHealthbar")
	public var healthbar;

	@:manim("test/examples/40-codegenDialog/codegenDialog.manim", "codegenDialog")
	public var dialog;

	@:manim("test/examples/41-codegenRepeat/codegenRepeat.manim", "codegenRepeat")
	public var repeat;

	@:manim("test/examples/42-codegenRepeat2d/codegenRepeat2d.manim", "codegenRepeat2d")
	public var repeat2d;

	@:manim("test/examples/43-codegenLayout/codegenLayout.manim", "codegenLayout")
	public var layout;

	@:manim("test/examples/44-codegenTilesIter/codegenTilesIter.manim", "codegenTilesIter")
	public var tilesIter;

	@:manim("test/examples/37-tintDemo/tintDemo.manim", "tintDemo")
	public var tint;

	@:manim("test/examples/46-codegenGraphics/codegenGraphics.manim", "codegenGraphics")
	public var graphics;

	@:manim("test/examples/47-codegenReference/codegenReference.manim", "codegenReference")
	public var reference;

	@:manim("test/examples/48-codegenFilterParam/codegenFilterParam.manim", "codegenFilterParam")
	public var filterParam;

	@:manim("test/examples/49-codegenGridPos/codegenGridPos.manim", "codegenGridPos")
	public var gridPos;

	@:manim("test/examples/50-codegenHexPos/codegenHexPos.manim", "codegenHexPos")
	public var hexPos;

	@:manim("test/examples/51-codegenTextOpts/codegenTextOpts.manim", "codegenTextOpts")
	public var textOpts;

	@:manim("test/examples/52-codegenBoolFloat/codegenBoolFloat.manim", "codegenBoolFloat")
	public var boolFloat;

	@:manim("test/examples/53-codegenRangeFlags/codegenRangeFlags.manim", "codegenRangeFlags")
	public var rangeFlags;
}
