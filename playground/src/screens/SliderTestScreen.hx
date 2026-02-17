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

	var updatableText300:Updatable;
	var updatableText300s:Updatable;
	var updatableText200:Updatable;
	var updatableText100:Updatable;
	var slider300:UIStandardMultiAnimSlider;
	var slider300s:UIStandardMultiAnimSlider;
	var slider200:UIStandardMultiAnimSlider;
	var slider100:UIStandardMultiAnimSlider;

	public function load():Void {
		this.builder = this.screenManager.buildFromResourceName("std.manim", false);
		var sliderBuilder = this.screenManager.buildFromResourceName("slider.manim", false);

		var ui = MacroUtils.macroBuildWithParameters(sliderBuilder, "ui", [], [
			slider300 => addSlider(builder, 0),
			slider300s => addSlider(builder, 0),
			slider200 => addSlider(builder, 0),
			slider100 => addSlider(builder, 0),
		]);

		this.slider300 = ui.slider300;
		this.slider300s = ui.slider300s;
		this.slider200 = ui.slider200;
		this.slider100 = ui.slider100;
		slider200.max = 50;
		slider200.step = 5;
		slider100.min = -10;
		slider100.max = 10;
		slider100.step = 1;
		this.updatableText300 = ui.builderResults.getUpdatable("sliderVal300");
		this.updatableText300s = ui.builderResults.getUpdatable("sliderVal300s");
		this.updatableText200 = ui.builderResults.getUpdatable("sliderVal200");
		this.updatableText100 = ui.builderResults.getUpdatable("sliderVal100");
		addBuilderResult(ui.builderResults);
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		switch event {
			case UIChangeFloatValue(value):
				if (source == slider300)
					updatableText300.updateText(Std.string(Math.round(value * 10) / 10));
				else if (source == slider300s)
					updatableText300s.updateText(Std.string(Math.round(value * 10) / 10));
				else if (source == slider200)
					updatableText200.updateText(Std.string(Math.round(value * 10) / 10));
				else if (source == slider100)
					updatableText100.updateText(Std.string(Math.round(value * 10) / 10));
			default:
		}
	}
}
