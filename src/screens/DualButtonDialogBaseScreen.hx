package screens;

import wt.ui.UIElement;
import wt.multianim.MultiAnimBuilder;
import wt.ui.UIMultiAnimButton;
import wt.ui.screens.UIScreen;

using wt.base.BitUtils;

@:nullSafety
class DualButtonDialogBaseScreen extends UIScreenBase {
	final button1Name:String;
	final button2Name:String;
	final builderDialogName:String;
	var button1:Null<UIStandardMultiAnimButton>;
	var button2:Null<UIStandardMultiAnimButton>;

	function new(screenManager, builderDialogName, button1Name:String, button2Name:String) {
		super(screenManager);
		this.button1Name = button1Name;
		this.button2Name = button2Name;
		this.builderDialogName = builderDialogName;
	}

	var builder:Null<MultiAnimBuilder>;
	var stdBuilder:Null<MultiAnimBuilder>;

	@:nullSafety(Off)
	public function load() {
		this.builder = this.screenManager.buildFromResource(hxd.Res.dialog_base, true);
		this.stdBuilder = this.screenManager.buildFromResource(hxd.Res.std, true);
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {}
}
