package screens;

import bh.ui.UIElement;
import bh.ui.screens.UIScreen;
import bh.multianim.MultiAnimBuilder;

using StringTools;

class AtlasTestScreen extends UIScreenBase {
	var builder:Null<MultiAnimBuilder>;

	public function load() {
		this.builder = this.screenManager.buildFromResourceName("atlas-test.manim", false);
		var stdBuilder = this.screenManager.buildFromResourceName("std.manim", false);
		loadAtlasTiles("crew2", 0);
		loadAtlasTiles("ui", 1);
		loadAtlasTiles("fx", 2);
		loadAtlasTiles("ui-new", 3);
	}

	function loadAtlasTiles(sheetName:String, indexY:Int) {
		var atlas = this.screenManager.loader.loadSheet2(sheetName);
		if (atlas == null)
			return;

		var tileNames = [for (key in atlas.getContents().keys()) key];

		function callback(input:CallbackRequest):CallbackResult {
			switch input {
				case NameWithIndex(name, index):
					return CBRString(tileNames[index]);
				default:
					throw 'Unknown callback request: $input';
			}
		}

		this.addBuilderResult(builder.buildWithParameters("atlasGrid", ["sheetName" => sheetName, "sheetLength" => tileNames.length, "indexY" => indexY],
			{callback: callback}));
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		// Handle any screen events if needed
	}

	public override function update(dt:Float) {
		super.update(dt);
	}
}
