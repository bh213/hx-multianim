package bh.ui;

import bh.multianim.MultiAnimMultiResult;
import bh.ui.UIElement;
import bh.multianim.MultiAnimBuilder.MultiAnimBuilder;
import h2d.Object;
import h2d.col.Point;
import bh.ui.UIElement.UIElementEvents;

class UIStandardMultiAnimButton implements UIElement implements UIElementDisablable implements StandardUIElementEvents implements UIElementSyncRedraw {
	final multiResult:MultiAnimMultiResult;
	var status(default, set):StandardUIElementStates = SUINormal;
	var root:h2d.Object;
	var currentButtonObject:Null<h2d.Object>;

	public var disabled(default, set):Bool = false;

	public var requestRedraw = true;

	public function clear() {
		currentButtonObject = null;
	}

	public static function create(builder:MultiAnimBuilder, name:String, buttonText:String) {
		return new UIStandardMultiAnimButton(builder, name, buttonText);
	}

	function new(builder:MultiAnimBuilder, name:String, buttonText:String) {
		this.multiResult = builder.buildWithComboParameters(name, ["buttonText" => buttonText], ["status", "disabled"]);
		this.root = new h2d.Object();
	}

	function set_status(value:StandardUIElementStates):StandardUIElementStates {
		if (this.status != value) {
			this.status = value;
			this.requestRedraw = true;
		}
		return value;
	}

	public function set_disabled(value:Bool):Bool {
		if (this.disabled != value) {
			this.disabled = value;
			this.requestRedraw = true;
		}
		return value;
	}

	public function getObject():Object {
		return root;
	}

	public function containsPoint(pos:Point):Bool {
		return getObject().getBounds().contains(pos);
	}

	public function onEvent(wrapper:UIElementEventWrapper) {
		if (this.disabled)
			return;
		switch wrapper.event {
			case OnPush(button):
				this.status = SUIPressed;

			case OnRelease(button):
				triggerClicked(wrapper.control);
				this.status = SUINormal;
			case OnReleaseOutside(_):
			case OnPushOutside(_):

			case OnEnter:
				this.status = SUIHover;
			case OnLeave:
				this.status = SUINormal;
			case OnKey(up, key):
			case OnWheel(dir):
			case OnMouseMove:
		}
	}

	function triggerClicked(controllable:Controllable) {
		onClick();
		controllable.pushEvent(UIClick, this);
	}

	public dynamic function onClick() {}

	public function doRedraw() {
		this.requestRedraw = false;
		if (this.currentButtonObject != null)
			this.currentButtonObject.remove();

		var result = multiResult.findResultByCombo(standardUIElementStatusToString(status), '${disabled}');

		this.currentButtonObject = result.object;
		root.addChild(result.object);
	}
}
