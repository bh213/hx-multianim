package screens;

import bh.ui.UIElementBuilder;
import bh.ui.UIMultiAnimButton.UIStandardMultiAnimButton;
import bh.base.MacroUtils;
import bh.ui.UIElement;
import bh.multianim.MultiAnimBuilder;

using bh.base.BitUtils;
using bh.ui.screens.UIScreen.UIScreenBase;

@:nullSafety
class OkCancelDialog extends UIScreenBase {
	var initialDialogText:String;
	final okText:String;
	final cancelText:String;
	var okButton:Null<UIStandardMultiAnimButton>;
	var cancelButton:Null<UIStandardMultiAnimButton>;
	var dialogBuilder:UIElementBuilder;
	var okButtonBuilder:UIElementBuilder;
	var cancelButtonBuilder:UIElementBuilder;
	var dialogText:Null<Updatable>;

	public function new(screenManager, dialogBuilder:UIElementBuilder, okButtonBuilder:UIElementBuilder, cancelButtonBuilder:UIElementBuilder, okText:String,
			cancelText:String, dialogText:String) {
		super(screenManager);
		this.initialDialogText = dialogText;
		this.dialogBuilder = dialogBuilder;
		this.okButtonBuilder = okButtonBuilder;
		this.cancelButtonBuilder = cancelButtonBuilder;
		this.okText = okText;
		this.cancelText = cancelText;
	}

	public function load() {
		var dialog = MacroUtils.macroBuildWithParameters(dialogBuilder.builder, dialogBuilder.name, ["dialogText" => initialDialogText], [
			ok => addButton(okButtonBuilder, okText),
			cancel => addButton(cancelButtonBuilder, cancelText)
		]);
		
		addBuilderResult(dialog.builderResults);

		this.okButton = dialog.ok;
		this.cancelButton = dialog.cancel;
		this.dialogText = dialog.builderResults.getUpdatable("dialogText");
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		switch event {
			case UIKeyPress(keyCode, release):
				if (keyCode == hxd.Key.ENTER) {
					this.getController().exitResponse = true;
				} else if (keyCode == hxd.Key.ESCAPE) {
					this.getController().exitResponse = false;
				}
			case UIClick:
				if (source == this.okButton) {
					this.getController().exitResponse = true;
				} else if (source == this.cancelButton) {
					this.getController().exitResponse = false;
				}
			default:
		}
	}
}
