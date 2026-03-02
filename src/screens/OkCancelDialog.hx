package screens;

import bh.ui.UIElementBuilder;
import bh.ui.UIMultiAnimButton.UIStandardMultiAnimButton;
import bh.base.MacroUtils;
import bh.ui.UIElement;
import bh.ui.screens.ScreenTransition;
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

	/** When set, closing uses closeDialogWithTransition instead of controller exit. */
	public var closeTransition:Null<ScreenTransition> = null;

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

		// .manim overlay settings override code-set config
		final overlayFromManim = parseOverlaySettings(dialog.builderResults.rootSettings);
		if (overlayFromManim != null)
			modalOverlayConfig = overlayFromManim;
	}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement) {
		switch event {
			case UIKeyPress(keyCode, release):
				if (keyCode == hxd.Key.ENTER) {
					closeWith(true);
				} else if (keyCode == hxd.Key.ESCAPE) {
					closeWith(false);
				}
			case UIClick:
				if (source == this.okButton) {
					closeWith(true);
				} else if (source == this.cancelButton) {
					closeWith(false);
				}
			default:
		}
	}

	function closeWith(result:Dynamic):Void {
		this.getController().exitResponse = result;
		if (closeTransition != null)
			screenManager.closeDialogWithTransition(closeTransition);
	}
}
