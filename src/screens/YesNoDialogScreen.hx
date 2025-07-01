package screens;

import bh.ui.UIElementBuilder;
import bh.ui.UIMultiAnimButton.UIStandardMultiAnimButton;
import bh.base.MacroUtils;
import bh.ui.UIElement;
import bh.multianim.MultiAnimBuilder;
using bh.base.BitUtils;
using bh.ui.screens.UIScreen.UIScreenBase;

@:nullSafety
class YesNoDialogScreen extends UIScreenBase implements IYesNoDialogScreen {
	var dialogText:String;
	final button1Name:String;
	final button2Name:String;
	final builderDialogName:String;
	var button1:Null<UIStandardMultiAnimButton>;
	var button2:Null<UIStandardMultiAnimButton>;
	var dialogBuilder:UIElementBuilder;
	var button1Builder:UIElementBuilder;
	var button2Builder:UIElementBuilder;

	public function new(screenManager, dialogBuilder:UIElementBuilder, button1Builder:UIElementBuilder, button2Builder:UIElementBuilder, button1Name:String, button2Name:String, dialogText:String) {
		super(screenManager);
		this.dialogText = dialogText;
	}

	

	public override function load() {
		

		
			var dialog = MacroUtils.macroBuildWithParameters(dialogBuilder, builderDialogName, ["dialogText"=>dialogText], [
				button1 => addButton(button1Builder, button1Name),
				button2 => addButton(button2Builder, button2Name)
			]);
		
			final dialog = dialog.builderResults;
			addBuilderResult(dialog);
			this.button1 = dialog.button1;
			this.button2 = dialog.button2;
			this.dialogText = dialog.getUpdatable("dialogText");
			dialogText.updateText(dialogText);
	}

	public override function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		super.onScreenEvent(event, source);
		switch event {
			case UIOnClick(element):
				if (element == button1) {
					this.getController().exitResponse = true;
				} else if (element == button2) {
					this.getController().exitResponse = false;
				}
			default:
		}
	}
}
