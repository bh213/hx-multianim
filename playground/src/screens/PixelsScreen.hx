package screens;

import bh.ui.UIElement;
import bh.ui.UIMultiAnimDropdown;
import bh.multianim.MultiAnimBuilder;
import bh.paths.*;
import bh.ui.UIMultiAnimSlider;
import bh.ui.UIMultiAnimCheckbox;
import bh.ui.UIMultiAnimButton;
import bh.ui.*;
import bh.ui.screens.UIScreen;

class PixelsScreen extends UIScreenBase {

	var builder:Null<MultiAnimBuilder>;

	public function load() {
			this.builder = this.screenManager.buildFromResourceName("std.manim", false);
			var pixelsBuilder = this.screenManager.buildFromResourceName("pixels.manim", false);

			var res = pixelsBuilder.buildWithParameters("ui", []);

			addBuilderResult(res);
	}
	
	public override function update(dt:Float) {
		super.update(dt);
	}
	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		
	}

} 