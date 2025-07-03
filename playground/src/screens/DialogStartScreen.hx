package screens;

import bh.base.MacroUtils;
import bh.ui.UIElement;

import bh.multianim.MultiAnimBuilder;
import bh.ui.UIMultiAnimButton;
import bh.ui.screens.UIScreen;
using bh.base.BitUtils;
@:nullSafety
class DialogStartScreen extends UIScreenBase {

	var builder:Null<MultiAnimBuilder>;
	var selectedFileText:Null<Updatable>;
	var openOkCancelDialog:Null<UIStandardMultiAnimButton>;
	var openFileDialog:Null<UIStandardMultiAnimButton>;

	public function load() {

			this.builder = this.screenManager.buildFromResourceName("dialog-start.manim", false);
			final stdBuilder = this.screenManager.buildFromResourceName("std.manim", false);
			var res = MacroUtils.macroBuildWithParameters(builder, "ui", [], [
				openDialog1button => addButton(stdBuilder.createElementBuilder("button"), "open OK/Cancel Dialog"), 
				openDialog2button => addButton(stdBuilder.createElementBuilder("button"), "open File select Dialog")
			]);
			addBuilderResult(res.builderResults);
			this.openOkCancelDialog = res.openDialog1button;
			this.openFileDialog = res.openDialog2button;
			this.selectedFileText = res.builderResults.getUpdatable("selectedFileText");

			this.openOkCancelDialog.onClick = () -> {
				var dialog = new OkCancelDialog(screenManager, stdBuilder.createElementBuilder("okCancelDialog"), stdBuilder.createElementBuilder("button"), stdBuilder.createElementBuilder("button"), "Yes", "No", "Are you sure you want to reset selected file?");
				dialog.load();
				this.screenManager.modalDialog(dialog, this, "resetDialog");
			}
			this.openFileDialog.onClick = () -> {
				var files = [
					"arrows.anim",
					"dice.anim", 
					"marine.anim",
					"shield.anim",
					"turret.anim"
				];
				var dialog = new screens.FileDialogScreen(screenManager, files);
				dialog.load();
				this.screenManager.modalDialog(dialog, this, "fileDialog");
			}
		
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		switch event {
			case UIClick:
				if (source == this.openOkCancelDialog) {
					trace("OK/Cancel Dialog");
				} else if (source == this.openFileDialog) {
					trace("File select Dialog");
				}
			case UIOnControllerEvent(result):
				switch result {
					case OnDialogResult(dialogName, result):
						if (dialogName == "fileDialog" && result != false && result != null) {
							// Update the text field with the selected file name
							if (selectedFileText != null) {
								selectedFileText.updateText('Selected: ${result}');
							}
						} else if (dialogName == "resetDialog") {
							// Handle Yes/No dialog response
								selectedFileText?.updateText('Dialog response: ${result}');

						}
					default:
						trace(result);
				}
			default:
		}
	}
}