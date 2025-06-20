package screens;

import wt.base.MacroUtils;
import wt.ui.UIElement;
import wt.multianim.MultiAnimBuilder;
using wt.base.BitUtils;

@:nullSafety
class YesNoDialogScreen extends DualButtonDialogBaseScreen {
	var text:String;

	public function new(screenManager, text) {
		super(screenManager, "yesNoDialog", "Yes", "No");
		this.text = text;
	}

	var dialogText:Null<Updatable>;

	@:nullSafety(Off) public override function load() {
		super.load();

		if (builder != null) {
			var res = MacroUtils.macroBuildWithParameters(builder, builderDialogName, [], [
				button1 => addButton(stdBuilder, button1Name),
				button2 => addButton(stdBuilder, button2Name)
			]);
			var ui = res.builderResults;
			addBuilderResult(ui);
			this.button1 = res.button1;
			this.button2 = res.button2;
			this.dialogText = ui.getUpdatable("dialogText");
			dialogText.updateText(text);
		}

		button1.onClick = () -> this.getController().exitResponse = true;
		button2.onClick = () -> this.getController().exitResponse = false;
	}

	public override function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		super.onScreenEvent(event, source);
	}
}
