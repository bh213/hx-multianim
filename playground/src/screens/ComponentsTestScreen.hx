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


class ComponentsTestScreen extends UIScreenBase {

	var builder:Null<MultiAnimBuilder>;
	var reset:UIStandardMultiAnimButton;
	var disable:UIStandardMultiAnimButton;
	var checkbox1:UIStandardMultiCheckbox;
	var checkbox2:UIStandardMultiCheckbox;
	var checkbox3:UIStandardMultiCheckbox;
	var slider:UIStandardMultiAnimSlider;
	// var drop1:UIStandardMultiAnimDropdown;


	public function createCross(color):h2d.Object {
		var x = 0;
		var y = 0;
		var size = 4.;
		
		var pointGraphics = new h2d.Graphics();
		pointGraphics.lineStyle(1, color, 1.0);
		pointGraphics.moveTo(x - size, y);
		pointGraphics.lineTo(x + size, y);
		pointGraphics.moveTo(x, y - size);
		pointGraphics.lineTo(x, y + size);
		return pointGraphics;
	}

	public function load():Void {


		
			final list4 = [{name:"10"}, {name:"50"}, {name:"100"}, {name:"1000"}];
			final list20 = [for (i in 1...20) {name: '${i}'}];
			final list100 = [for (i in 1...100) {name: '${i}'}];
			final list20disabled = [for (i in 1...20) {name: '${i}', disabled: i < 3 || i > 15}];


			

			this.builder = this.screenManager.buildFromResourceName("std.manim", false);
			var componentsBuilder = this.screenManager.buildFromResourceName("components.manim", false);


			var tileGroupTest1 = componentsBuilder.buildWithParameters("testTileGroup1", []);
			addBuilderResult(tileGroupTest1);

			var tileGroupTest2 = componentsBuilder.buildWithParameters("testTileGroup2", []);
			addBuilderResult(tileGroupTest2);

			var tileGroupTest3 = componentsBuilder.buildWithParameters("testTileGroup3", []);
			addBuilderResult(tileGroupTest3);

			var tileGroupTest4 = componentsBuilder.buildWithParameters("testTileGroup4", []);
			addBuilderResult(tileGroupTest4);

			var tileGroupTest5 = componentsBuilder.buildWithParameters("testTileGroup5", []);
			addBuilderResult(tileGroupTest5);
			
			var tileGroupTest6 = componentsBuilder.buildWithParameters("testTileGroup6", []);
			addBuilderResult(tileGroupTest6);


			final mainLayout = componentsBuilder.getLayouts();
			 
			var buttonsIterator = mainLayout.getIterator("buttons");
			
			var dropDownIterator = mainLayout.getIterator("mainDropDown");
			
			var checkboxesIterator = mainLayout.getIterator("checkboxes");
			
			var res = MacroUtils.macroBuildWithParameters(componentsBuilder, "ui", [], [
				checkbox1=>addCheckbox(builder,  true),
				checkbox2=>addCheckbox(builder,  true),
				checkbox3=>addCheckbox(builder,  true),
				checkbox4=>addCheckbox(builder,  true),
				checkbox5=>addCheckbox(builder,  true),
				scroll1=>addScrollableListWithSingleBuilder(builder, "list-panel", "list-item-120", "scrollbar", "scrollbar", list4, 0,100,100),
				scroll2=>addScrollableListWithSingleBuilder(builder, "list-panel", "list-item-120", "scrollbar", "scrollbar", list100, 10,100,100),
				scroll3=>addScrollableListWithSingleBuilder(builder, "list-panel", "list-item-120", "scrollbar", "scrollbar", list20, 3,100,100),
				scroll4=>addScrollableListWithSingleBuilder(builder, "list-panel", "list-item-120", "scrollbar", "scrollbar", list20disabled, 3,100,100),
				checkboxWithLabel=>addCheckboxWithText(builder, "my label", true),
				//function addDropdown(providedBuilder, items, settings:ResolvedSettings, initialIndex = 0) {
				//dropdown1 => addDropdown(builder, list100, 0)
			]);
			var ui = res.builderResults;
			
			//this.drop1 = res.dropdown1;
			
			addBuilderResult(res.builderResults);

			this.reset = addElementWithIterator(UIStandardMultiAnimButton.create(builder, "button", "Reset"), buttonsIterator);
			this.disable = addElementWithIterator(UIStandardMultiAnimButton.create(builder, "button", "disable"), buttonsIterator);
			this.slider = addElementWithPos(UIStandardMultiAnimSlider.create(builder, "slider", 200), 1000, 200);
			
			
			
			// drop1.autoCloseOnLeave = false;
			addElementWithIterator(UIStandardMultiAnimDropdown.create(builder.createElementBuilder("dropdown"), builder.createElementBuilder("list-panel"), builder.createElementBuilder("list-item-120"), builder.createElementBuilder("scrollbar"), "scrollbar", [{name:"item A"}, {name:"item B"}, {name:"item C"}]), dropDownIterator);
			addElementWithIterator(UIStandardMultiAnimDropdown.create(builder.createElementBuilder("dropdown"), builder.createElementBuilder("list-panel"), builder.createElementBuilder("list-item-120"), builder.createElementBuilder("scrollbar"), "scrollbar",[{name:"Krava"}, {name:"Trava"}, {name:"Zelena Jama"}, {name:"XXXXX"}]), dropDownIterator);
			var dd3 = addElementWithIterator(UIStandardMultiAnimDropdown.create(builder.createElementBuilder("dropdown"), builder.createElementBuilder("list-panel"), builder.createElementBuilder("list-item-120"), builder.createElementBuilder("scrollbar"), "scrollbar",[{name:"10"}, {name:"50"}, {name:"100"}, {name:"1000"}]), dropDownIterator);
			dd3.autoOpen = false;
			
			this.checkbox1 = addElementWithIterator(UIStandardMultiCheckbox.create(builder, "checkbox", true), checkboxesIterator);
			this.checkbox2 = addElementWithIterator(UIStandardMultiCheckbox.create(builder, "checkbox", true), checkboxesIterator);
			this.checkbox3 = addElementWithIterator(UIStandardMultiCheckbox.create(builder, "checkbox", true), checkboxesIterator);

			var radioBox = UIMultiAnimRadioButtons.create(builder, "radioButtons", "radio2", list4, 1);
			addElementWithPos(radioBox, 300,300);
			

			var h2dObj = createCross(0xFFFF0000);
			var testCheckbox = UIStandardMultiCheckbox.create(builder, "checkbox", true);
			var macroRes = MacroUtils.macroBuildWithParameters(componentsBuilder, "macroTest", [], [
				factoryElement=>addCheckbox(builder,  true),
				element=>testCheckbox,
				h2dObjectFactory=>createCross(0xFF0000FF),
				h2dObject=>h2dObj,
				]);

			addBuilderResult(macroRes.builderResults);
			
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
			switch event {
				case UIClick:
					if (source == reset) {
						checkbox1.selected = true;					
						checkbox2.selected = true;					
						checkbox3.selected = true;					
						slider.setIntValue( 20);
						// drop1.setSelectedIndex(2);
					}
					if (source == disable) {
						checkbox1.disabled = !checkbox1.disabled;
						checkbox2.selected = !checkbox2.selected;
						checkbox3.selected = !checkbox3.selected;
						// drop1.disabled = !drop1.disabled;
						slider.disabled = !slider.disabled;
						reset.disabled = !reset.disabled;
					}
				case UIToggle(pressed):
				case UIChangeValue(value):
				case UIChangeItem(index, items):
				case UIKeyPress(keyCode, release):
				case UIOnControllerEvent(result):
				case UICustomEvent(eventName, data):
			}
	}
}