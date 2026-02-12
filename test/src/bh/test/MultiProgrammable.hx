package bh.test;

@:build(bh.multianim.ProgrammableCodeGen.buildAll())
class MultiProgrammable extends bh.multianim.ProgrammableBuilder {
	@:manim("test/examples/35-tintDemo/tintDemo.manim", "tintDemo")
	public var tint;

	@:manim("test/examples/36-codegenButton/codegenButton.manim", "codegenButton")
	public var button;

	@:manim("test/examples/37-codegenHealthbar/codegenHealthbar.manim", "codegenHealthbar")
	public var healthbar;

	@:manim("test/examples/38-codegenDialog/codegenDialog.manim", "codegenDialog")
	public var dialog;

	@:manim("test/examples/39-codegenRepeat/codegenRepeat.manim", "codegenRepeat")
	public var repeat;

	@:manim("test/examples/40-codegenRepeat2d/codegenRepeat2d.manim", "codegenRepeat2d")
	public var repeat2d;

	@:manim("test/examples/41-codegenLayout/codegenLayout.manim", "codegenLayout")
	public var layout;

	@:manim("test/examples/42-codegenTilesIter/codegenTilesIter.manim", "codegenTilesIter")
	public var tilesIter;

	@:manim("test/examples/43-codegenGraphics/codegenGraphics.manim", "codegenGraphics")
	public var graphics;

	@:manim("test/examples/44-codegenReference/codegenReference.manim", "codegenReference")
	public var reference;

	@:manim("test/examples/45-codegenFilterParam/codegenFilterParam.manim", "codegenFilterParam")
	public var filterParam;

	@:manim("test/examples/46-codegenGridPos/codegenGridPos.manim", "codegenGridPos")
	public var gridPos;

	@:manim("test/examples/47-codegenHexPos/codegenHexPos.manim", "codegenHexPos")
	public var hexPos;

	@:manim("test/examples/48-codegenTextOpts/codegenTextOpts.manim", "codegenTextOpts")
	public var textOpts;

	@:manim("test/examples/49-codegenBoolFloat/codegenBoolFloat.manim", "codegenBoolFloat")
	public var boolFloat;

	@:manim("test/examples/50-codegenRangeFlags/codegenRangeFlags.manim", "codegenRangeFlags")
	public var rangeFlags;
}
