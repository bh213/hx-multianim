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

class ButtonTestScreen extends UIScreenBase {
	var builder:Null<MultiAnimBuilder>;
	
	var updatableText:Updatable;
	var disableCheckbox:UIStandardMultiCheckbox;
	var button:UIStandardMultiAnimButton;

	public function load():Void {
		this.builder = this.screenManager.buildFromResourceName("std.manim", false);
		var buttonBuilder = this.screenManager.buildFromResourceName("button.manim", false);
		
		var ui = MacroUtils.macroBuildWithParameters(buttonBuilder, "ui", [], [
			button=>addButtonWithSingleBuilder(buttonBuilder, "button_custom", "Click Me!"),
			disableCheckbox=>addCheckbox(builder, false),
		]);

		this.updatableText = ui.builderResults.getUpdatable("buttonVal");
		this.disableCheckbox = ui.disableCheckbox;
		this.button = ui.button;
		addBuilderResult(ui.builderResults);
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		switch event {
			case UIClick:
				this.updatableText.updateText("Button Clicked!");
			case UIToggle(pressed):
				// This shouldn't fire for disabled checkbox, but handle it just in case
				if (source == disableCheckbox) {
					this.updatableText.updateText("Disabled checkbox toggled: " + pressed);
                    this.button.disabled = pressed;

				}
			default:
		}
	}
} 