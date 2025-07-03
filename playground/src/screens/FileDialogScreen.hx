package screens;

import bh.base.MacroUtils;
import bh.ui.UIElement;
import bh.ui.UIMultiAnimDropdown;
import bh.multianim.MultiAnimBuilder;
import bh.ui.UIMultiAnimSlider;
import bh.ui.UIMultiAnimCheckbox;
import bh.ui.UIMultiAnimButton;
import bh.ui.*;
import bh.ui.screens.UIScreen;
using bh.base.BitUtils;
@:nullSafety
class FileDialogScreen extends UIScreenBase {
	var files:Array<String>;
	var selected:Null<String> = null;
	var button1:Null<UIStandardMultiAnimButton>;
	var button2:Null<UIStandardMultiAnimButton>;
	var scrollableList:Null<UIMultiAnimScrollableList>;

	public function new(screenManager, files:Array<String>) {
		super(screenManager);
		this.files = files;
	}
	
	public function load() {
		var dialogBuilder = this.screenManager.buildFromResourceName("dialog-base.manim", false);
		var stdBuilder = this.screenManager.buildFromResourceName("std.manim", false);

		var okButton = UIStandardMultiAnimButton.create(stdBuilder, "button", "OK");
		var cancelButton = UIStandardMultiAnimButton.create(stdBuilder, "button", "Cancel");

		var list:Array<UIElementListItem> = cast files.map(x-> {name:x});
		
		var res = MacroUtils.macroBuildWithParameters(dialogBuilder, "fileDialog", [], [
			button1 => okButton,
			button2 => cancelButton,
			filelist => addScrollableListWithSingleBuilder(stdBuilder, "list-panel", "list-item-120", "scrollbar", "scrollbar", list, 0, 300, 200)
		]);

		this.button1 = okButton;
		this.button2 = cancelButton;
		this.scrollableList = res.filelist;
		addBuilderResult(res.builderResults);

		scrollableList.onItemChanged = (newIndex, items, wrapper) -> {
			selected = items[newIndex].name;
			if (button1 != null) button1.disabled = false;
		}
		scrollableList.onItemDoubleClicked = (newIndex, items, wrapper) -> {
			selected = items[newIndex].name;
			this.getController().exitResponse = selected;	
		}

		okButton.onClick = () -> {
			if (selected == null) throw 'filename should have been selected';
			this.getController().exitResponse = selected;
		}
		cancelButton.onClick = () -> this.getController().exitResponse = false;

		okButton.disabled = true;
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		switch event {
			case UIOnControllerEvent(event):
				trace(event);
			default:
		}
	}
}