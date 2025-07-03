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

class ScrollableListTestScreen extends UIScreenBase {
	var builder:Null<MultiAnimBuilder>;
	
	var updatableText:Updatable;
	var scrollableList:UIMultiAnimScrollableList;

	public function load():Void {
		this.builder = this.screenManager.buildFromResourceName("std.manim", false);
		var scrollableListBuilder = this.screenManager.buildFromResourceName("scrollable-list.manim", false);
		
		// Create sample list items
		var listItems = [
			{name: "Item 1"},
			{name: "Item 2"},
			{name: "Item 3"},
			{name: "Item 4"},
			{name: "Item 5"},
			{name: "Item 6"},
			{name: "Item 7"},
			{name: "Item 8"},
			{name: "Item 9"},
			{name: "Item 10"}
		];
		
		var ui = MacroUtils.macroBuildWithParameters(scrollableListBuilder, "ui", [], [
			scrollableList=>addScrollableListWithSingleBuilder(builder, "list-panel", "list-item-120", "scrollbar", "scrollbar", listItems, 0, 100, 100)
		]);

		this.updatableText = ui.builderResults.getUpdatable("listVal");
		this.scrollableList = ui.scrollableList;
		addBuilderResult(ui.builderResults);
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		switch event {
			case UIChangeItem(index, items):
				if (source == scrollableList) {
					this.updatableText.updateText('Selected: ${items[index].name} (index: ${index})');
				}
			default:
		}
	}
} 