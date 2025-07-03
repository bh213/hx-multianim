package screens;

import bh.base.MacroUtils;
import bh.ui.UIElement;
import bh.ui.UIMultiAnimDropdown;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder;
import bh.ui.UIMultiAnimSlider;
import bh.ui.UIMultiAnimCheckbox;
import bh.ui.UIMultiAnimButton;
import bh.ui.UIMultiAnimRadioButtons;
import bh.ui.*;
import bh.ui.screens.UIScreen;

class SliderTestScreen extends UIScreenBase {
	var builder:Null<MultiAnimBuilder>;
	
	var updatableText:Updatable;

	public function load():Void {
		this.builder = this.screenManager.buildFromResourceName("std.manim", false);
		var sliderBuilder = this.screenManager.buildFromResourceName("slider.manim", false);
		
		var ui = MacroUtils.macroBuildWithParameters(sliderBuilder, "ui", [], [
			slider=>addSlider(builder,  0),
		]);

		this.updatableText = ui.builderResults.getUpdatable("sliderVal");
		addBuilderResult(ui.builderResults);
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		
			switch event {
				case UIChangeValue(value):
					this.updatableText.updateText(Std.string(value));
				default:
			}
	}
}
