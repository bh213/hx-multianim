package screens;

import bh.ui.UIElement;
import bh.multianim.MultiAnimBuilder;
import bh.ui.UIMultiAnimButton;
import bh.ui.screens.UIScreen;

using bh.base.BitUtils;

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
