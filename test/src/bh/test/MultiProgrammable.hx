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

	@:manim("test/examples/5-stateAnimDemo/stateAnimDemo.manim", "stateAnimDemo")
	public var stateAnimDemo;

	@:manim("test/examples/7-paletteDemo/paletteDemo.manim", "paletteDemo")
	public var paletteDemo;

	@:manim("test/examples/12-updatableDemo/updatableDemo.manim", "updatableDemo")
	public var updatableDemo;

	@:manim("test/examples/15-stateAnimConstructDemo/stateAnimConstructDemo.manim", "stateAnimConstructDemo")
	public var stateAnimConstructDemo;

	@:manim("test/examples/16-divModDemo/divModDemo.manim", "divModDemo")
	public var divModDemo;

	@:manim("test/examples/22-tilesIteration/tilesIteration.manim", "tilesIteration")
	public var tilesIteration;

	@:manim("test/examples/24-autotileCross/autotileCross.manim", "autotileCross")
	public var autotileCross;

	@:manim("test/examples/25-autotileBlob47/autotileBlob47.manim", "autotileBlob47")
	public var autotileBlob47;

	@:manim("test/examples/32-namedFilterParams/namedFilterParams.manim", "namedFilterParams")
	public var namedFilterParams;

	@:manim("test/examples/33-inlineAtlas2Demo/inlineAtlas2Demo.manim", "inlineAtlas2Demo")
	public var inlineAtlas2Demo;

	@:manim("test/examples/34-maskDemo/maskDemo.manim", "maskDemo")
	public var maskDemo;

	@:manim("test/examples/28-autotileDemoSyntax/autotileDemoSyntax.manim", "autotileDemoSyntax")
	public var autotileDemoSyntax;

	@:manim("test/examples/29-forgottenPlainsTerrain/forgottenPlainsTerrain.manim", "forgottenPlainsTerrain")
	public var forgottenPlainsTerrain;

	@:manim("test/examples/30-blob47Fallback/blob47Fallback.manim", "blob47Fallback")
	public var blob47Fallback;

	@:manim("test/examples/54-codegenPaletteReplace/codegenPaletteReplace.manim", "codegenPaletteReplace")
	public var paletteReplace;

	@:manim("test/examples/55-codegenArray/codegenArray.manim", "codegenArray")
	public var array;

	@:manim("test/examples/56-codegenGridFunc/codegenGridFunc.manim", "codegenGridFunc")
	public var gridFunc;

	@:manim("test/examples/57-codegenMultiNamed/codegenMultiNamed.manim", "codegenMultiNamed")
	public var multiNamed;

	@:manim("test/examples/58-easingCurvesDemo/easingCurvesDemo.manim", "easingCurvesDemo")
	public var easingCurves;

	@:manim("test/examples/59-segmentedCurvesDemo/segmentedCurvesDemo.manim", "segmentedCurvesDemo")
	public var segmentedCurves;

	@:manim("test/examples/60-newPathCommands/newPathCommands.manim", "newPathCommands")
	public var newPathCommands;

	@:manim("test/examples/61-animatedPathCurves/animatedPathCurves.manim", "animatedPathCurves")
	public var animatedPathCurves;

	@:data("test/examples/62-dataBlock/dataBlock.manim", "gameData")
	public var gameData;

	@:data("test/examples/62-dataBlock/dataBlock.manim", "gameData", "bh.test.data")
	public var gameDataTypePkg;

	@:data("test/examples/62-dataBlock/dataBlock.manim", "gameData", "bh.test.merged", mergeTypes)
	public var gameDataMerged1;

	@:data("test/examples/62-dataBlock/dataBlock.manim", "gameData", "bh.test.merged", mergeTypes)
	public var gameDataMerged2;

	@:manim("test/examples/64-repeatRebuild/repeatRebuild.manim", "repeatRebuild")
	public var repeatRebuild;

	@:manim("test/examples/65-repeatAllNodes/repeatAllNodes.manim", "repeatAllNodes")
	public var repeatAllNodes;

	@:manim("test/examples/66-flowBgDemo/flowBgDemo.manim", "flowBgDemo")
	public var flowBgDemo2;

	@:manim("test/examples/67-interactiveMetadata/interactiveMetadata.manim", "interactiveMetadata")
	public var interactiveMetadata;

	@:manim("test/examples/68-filtersAdvanced/filtersAdvanced.manim", "filtersAdvanced")
	public var filtersAdvanced;

	@:manim("test/examples/70-indexedNamed/indexedNamed.manim", "indexedNamed")
	public var indexedNamed;

	@:manim("test/examples/71-slotDemo/slotDemo.manim", "slotDemo")
	public var slotDemo;

	@:manim("test/examples/72-flowAdvanced/flowAdvanced.manim", "flowAdvanced")
	public var flowAdvanced;

	@:manim("test/examples/73-dynamicRefs/dynamicRefs.manim", "dynamicRefs")
	public var dynamicRefs;

	@:manim("test/examples/74-dynamicRefScope/dynamicRefScope.manim", "dynamicRefScope")
	public var dynamicRefScope;

	@:manim("test/examples/78-characterSheetDemo/characterSheetDemo.manim", "characterSheetDemo")
	public var characterSheetDemo;

	@:manim("test/examples/79-tileParamDemo/tileParamDemo.manim", "tileParamDemo")
	public var tileParamDemo;

	@:manim("test/examples/80-codegenColorDiv/codegenColorDiv.manim", "codegenColorDiv")
	public var colorDiv;

	@:manim("test/examples/81-slotParams/slotParams.manim", "slotParams")
	public var slotParams;

	@:manim("test/examples/82-layoutMultiChild/layoutMultiChild.manim", "layoutMultiChild")
	public var layoutMultiChild;

	@:manim("test/examples/83-slot2dIndex/slot2dIndex.manim", "slot2dIndex")
	public var slot2dIndex;

	@:manim("test/examples/84-slotContent/slotContent.manim", "slotContentDemo")
	public var slotContentDemo;
}
