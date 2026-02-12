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

	@:manim("test/examples/51-codegenParticles/codegenParticles.manim", "codegenParticles")
	public var particles;

	@:manim("test/examples/52-codegenBlendMode/codegenBlendMode.manim", "codegenBlendMode")
	public var blendMode;

	@:manim("test/examples/53-codegenApply/codegenApply.manim", "codegenApply")
	public var apply;

	@:manim("test/examples/17-applyDemo/applyDemo.manim", "applyDemo")
	public var applyDemo;

	@:manim("test/examples/1-hexGridPixels/hexGridPixels.manim", "hexGridPixels")
	public var hexGridPixels;

	@:manim("test/examples/2-textDemo/textDemo.manim", "textDemo")
	public var textDemo;

	@:manim("test/examples/3-bitmapDemo/bitmapDemo.manim", "bitmapDemo")
	public var bitmapDemo;

	@:manim("test/examples/4-repeatableDemo/repeatableDemo.manim", "repeatableDemo")
	public var repeatableDemo;

	@:manim("test/examples/6-flowDemo/flowDemo.manim", "flowDemo")
	public var flowDemo;

	@:manim("test/examples/8-layersDemo/layersDemo.manim", "layersDemo")
	public var layersDemo;

	@:manim("test/examples/9-ninePatchDemo/ninePatchDemo.manim", "ninePatchDemo")
	public var ninePatchDemo;

	@:manim("test/examples/10-referenceDemo/referenceDemo.manim", "referenceDemo")
	public var referenceDemo;

	@:manim("test/examples/11-bitmapAlignDemo/bitmapAlignDemo.manim", "bitmapAlignDemo")
	public var bitmapAlignDemo;

	@:manim("test/examples/13-layoutRepeatableDemo/layoutRepeatableDemo.manim", "layoutRepeatableDemo")
	public var layoutRepeatableDemo;

	@:manim("test/examples/14-tileGroupDemo/tileGroupDemo.manim", "tileGroupDemo")
	public var tileGroupDemo;

	@:manim("test/examples/18-conditionalsDemo/conditionalsDemo.manim", "main")
	public var conditionalsDemo;

	@:manim("test/examples/19-ternaryOpDemo/ternaryOpDemo.manim", "ternaryOpDemo")
	public var ternaryOpDemo;

	@:manim("test/examples/20-graphicsDemo/graphicsDemo.manim", "graphicsDemo")
	public var graphicsDemo;

	@:manim("test/examples/21-repeatable2dDemo/repeatable2dDemo.manim", "repeatable2dDemo")
	public var repeatable2dDemo;

	@:manim("test/examples/23-atlasDemo/atlasDemo.manim", "atlasDemo")
	public var atlasDemo;

	@:manim("test/examples/26-fontShowcase/fontShowcase.manim", "fontShowcase")
	public var fontShowcase;

	@:manim("test/examples/27-scalePositionDemo/scalePositionDemo.manim", "scalePositionDemo")
	public var scalePositionDemo;

	@:manim("test/examples/31-elseDefaultDemo/elseDefaultDemo.manim", "elseDefaultDemo")
	public var elseDefaultDemo;

	@:manim("test/examples/32-namedFilterParams/namedFilterParams.manim", "namedFilterParams")
	public var namedFilterParams;

	@:manim("test/examples/33-inlineAtlas2Demo/inlineAtlas2Demo.manim", "inlineAtlas2Demo")
	public var inlineAtlas2Demo;

	@:manim("test/examples/34-maskDemo/maskDemo.manim", "maskDemo")
	public var maskDemo;
}
