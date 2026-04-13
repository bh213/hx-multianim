package bh.ui;

import bh.base.CursorManager;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.MultiAnimBuilder;
import bh.ui.UIElement;
import h2d.Object;
import h2d.col.Point;

@:nullSafety
class UIStandardMultiCheckbox implements UIElement implements UIElementDisablable implements UIElementSelectable implements StandardUIElementEvents
		implements UIElementNumberValue implements UIElementCursor {
	final result:BuilderResult;

	public var disabled(default, set):Bool = false;
	public var selected(default, set):Bool = false;
	public var ignoreSelectEvents = false;

	public function clear() {}

	public function getCursor():hxd.Cursor {
		if (disabled)
			return CursorManager.getDefaultCursor();
		return CursorManager.getDefaultInteractiveCursor();
	}

	public function set_disabled(value:Bool):Bool {
		if (this.disabled != value) {
			this.disabled = value;
			result.beginUpdate();
			result.setParameter("status", value ? "disabled" : "normal");
			result.setParameter("disabled", '${value}');
			result.endUpdate();
		}
		return value;
	}

	public function set_selected(value:Bool):Bool {
		if (this.selected != value) {
			this.selected = value;
			result.setParameter("checked", '${value}');
		}
		return value;
	}

	public static function create(builder:MultiAnimBuilder, name, checked, ?extraParams:Null<Map<String, Dynamic>>) {
		return new UIStandardMultiCheckbox(builder, name, checked, extraParams);
	}

	function new(builder:MultiAnimBuilder, name:String, startsChecked:Bool, ?extraParams:Null<Map<String, Dynamic>>) {
		var params:Map<String, Dynamic> = ["status" => "normal", "disabled" => "false", "checked" => '${startsChecked}'];
		if (extraParams != null)
			for (key => value in extraParams)
				params.set(key, value);
		this.result = builder.buildWithParameters(name, params, null, null, true);
		this.selected = startsChecked;
	}

	public function getObject():Object {
		return result.object;
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
					result.beginUpdate();
					result.setParameter("status", "pressed");
					result.setParameter("checked", '${this.selected}');
					result.endUpdate();
					triggerToggle(this.selected, wrapper.control);
				}
			case OnRelease(button):
				result.setParameter("status", "normal");
			case OnReleaseOutside(_):
			case OnPushOutside(_):
			case OnEnter:
				result.setParameter("status", "hover");
			case OnLeave:
				result.setParameter("status", "normal");
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
