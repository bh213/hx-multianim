package screens;

import bh.ui.UIElement;
import bh.ui.UIMultiAnimDropdown;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder;
import bh.ui.UIMultiAnimSlider;
import bh.ui.UIMultiAnimCheckbox;
import bh.ui.UIMultiAnimButton;
import bh.ui.*;
import bh.ui.screens.UIScreen;
using bh.base.BitUtils;
@:nullSafety
class Room1Screen extends UIScreenBase {

	var builder:Null<MultiAnimBuilder>;
	var roomFlags:Int = 0;
	var cornerFlags:Int = 0;
	var panelFlags:Int = 0;
	var room:Null<BuilderResult>;
	var updatableText:Null<Updatable>;
	public function load() {

			this.builder = this.screenManager.buildFromResourceName("room1.manim", false);
			var stdBuilder = this.screenManager.buildFromResourceName("std.manim", false);

			final layouts = builder.getLayouts();
			var itRoom = layouts.getIterator("roomCheckboxes");
			var itCorner = layouts.getIterator("cornerCheckboxes");
			var itPanel = layouts.getIterator("panelCheckboxes");
			var itButtons = layouts.getIterator("panelButtons");

			
			var checkboxes = [];
			var roomCheckboxes = [];
			for (i in 0...6) {
				var c = addElementWithIterator(UIStandardMultiCheckbox.create(stdBuilder, "checkbox", false), itRoom);
				checkboxes.push(c);
				roomCheckboxes.push(c);

				c.onToggle = checked -> 	{
					roomFlags = roomFlags.setBitToValue(i, checked);
					redraw();
					};
			}


			var cornerCheckboxes = [];
			for (i in 0...6) {
				var c = addElementWithIterator(UIStandardMultiCheckbox.create(stdBuilder, "checkbox", false), itCorner);
				checkboxes.push(c);
				cornerCheckboxes.push(c);
				c.onToggle = checked -> 	{
					cornerFlags = cornerFlags.setBitToValue(i, checked);
					redraw();
				};
			}
			var panelCheckboxes = [];
			for (i in 0...6) {
				var c = addElementWithIterator(UIStandardMultiCheckbox.create(stdBuilder, "checkbox", false), itPanel);
				checkboxes.push(c);
				panelCheckboxes.push(c);
				c.onToggle = checked -> 	{
					panelFlags = panelFlags.setBitToValue(i, checked);
					redraw();
				};
			}
			

			var clearAllButton = addElementWithIterator(UIStandardMultiAnimButton.create(stdBuilder, "button", 'clearAll'), itButtons);
			clearAllButton.onClick = () -> {
				this.roomFlags = 0;
				this.cornerFlags = 0;
				this.panelFlags = 0;
				for (value in checkboxes)  value.selected = false;
				redraw();
			
			}

			// }
			var s1 = addElementWithIterator(UIStandardMultiAnimButton.create(stdBuilder, "button", 'set all panels'), itButtons);
			s1.onClick =() -> {
				this.panelFlags = 127;
				for (value in panelCheckboxes)  value.selected = true;
				redraw();
			}
			var s2 = addElementWithIterator(UIStandardMultiAnimButton.create(stdBuilder, "button", 'set all rooms'), itButtons);
			s2.onClick =() -> {
				this.roomFlags = 127;
				for (value in roomCheckboxes)  value.selected = true;
				redraw();
			}

			var s3 = addElementWithIterator(UIStandardMultiAnimButton.create(stdBuilder, "button", 'set all corners'), itButtons);
			s3.onClick =() -> {
				this.cornerFlags = 127;
				for (value in cornerCheckboxes)  value.selected = true;
				redraw();
			}


			
			var ui = addBuilderResult(builder.buildWithParameters("ui", []));
			this.updatableText = ui.getUpdatable("testNumber");
			redraw();
			

			
	}

	function redraw() {
		if (room != null) room.object.remove();

		final params = [
			"wallDirections" => roomFlags,
			"cornerDirections" => cornerFlags,
			"panelDirections" => panelFlags,
		];
		if (updatableText != null) updatableText.updateText('$params');
		@:nullSafety(Off) this.room = addBuilderResult(this.builder.buildWithParameters("room", params));
	}

	// public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
	// 	trace(event, source);
	// 		switch event {
	// 			case UIClick:
	// 				if (source == multiAnim) {
	// 					screenManager.gotoScreen(NormalStage, "main");
	// 				}
	// 				if (source == stateAnim) {
	// 					screenManager.gotoScreen(NormalStage, "stateAnim");
	// 				}
	// 			case UIToggle(pressed):
	// 			case UIChangeValue(value):
	// 			case UIChangeItem(index, items):
	// 			case UIKeyPress(keyCode, release):
	// 		}
	// }

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {}
}