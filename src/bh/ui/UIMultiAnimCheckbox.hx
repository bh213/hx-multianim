package bh.ui;

import bh.multianim.MultiAnimMultiResult;
import bh.ui.UIElement;
import bh.multianim.MultiAnimBuilder.MultiAnimBuilder;
import h2d.Object;
import h2d.col.Point;
import bh.ui.UIElement.UIElementEvents;

@:nullSafety
class UIStandardMultiCheckbox implements UIElement implements UIElementDisablable implements UIElementSelectable implements StandardUIElementEvents
		implements UIElementNumberValue implements UIElementSyncRedraw {
	final multiResult:MultiAnimMultiResult;
	var checkboxObject:Null<h2d.Object>;

	var status(default, set):StandardUIElementStates = SUINormal;
	var root:h2d.Object;

	public var disabled(default, set):Bool = false;
	public var selected(default, set):Bool = false;
	public var requestRedraw = true;
	public var ignoreSelectEvents = false;

	public function clear() {
		this.checkboxObject = null;
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

	public function set_selected(value:Bool):Bool {
		if (this.selected != value) {
			this.selected = value;
			this.requestRedraw = true;
		}
		return value;
	}

	public static function create(builder:MultiAnimBuilder, name, checked, ?extraParams:Null<Map<String, Dynamic>>) {
		return new UIStandardMultiCheckbox(builder, name, checked, extraParams);
	}

	function new(builder:MultiAnimBuilder, name:String, startsChecked, ?extraParams:Null<Map<String, Dynamic>>) {
		this.root = new h2d.Object();
		var params:Map<String, Dynamic> = [];
		if (extraParams != null)
			for (key => value in extraParams)
				params.set(key, value);
		this.multiResult = builder.buildWithComboParameters(name, params, ["status", "disabled", "checked"]);
		this.selected = startsChecked;
	}

	public function doRedraw() {
		this.requestRedraw = false;
		if (this.checkboxObject != null)
			this.checkboxObject.remove();

		var result = multiResult.findResultByCombo(standardUIElementStatusToString(status), '${disabled}', '${selected}');
		this.checkboxObject = result.object;
		root.addChild(result.object);
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
				if (!ignoreSelectEvents) {
					this.selected = !this.selected;
					this.status = SUIPressed;
					triggerToggle(this.selected, wrapper.control);
				}
			case OnRelease(button):
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

	function triggerToggle(checked, controllable:Controllable) {
		onToggle(checked);
		onInternalToggle(checked, controllable);
		controllable.pushEvent(UIToggle(checked), this);
	}

	public dynamic function onToggle(checked:Bool) {}

	@:allow(bh.ui.UIMultiAnimRadioButtons)
	dynamic function onInternalToggle(checked:Bool, controllable:Controllable) {}

	public function setIntValue(v:Int) {
		selected = v != 0;
	}

	public function getIntValue():Int {
		return selected ? 1 : 0;
	}
}
