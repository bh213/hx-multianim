package bh.ui;

import bh.base.CursorManager;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.MultiAnimBuilder;
import bh.ui.UIElement;
import h2d.Object;
import h2d.col.Point;

class UIStandardMultiAnimButton implements UIElement implements UIElementDisablable implements StandardUIElementEvents implements UIElementCursor {
	final result:BuilderResult;

	public var disabled(default, set):Bool = false;

	public static function create(builder:MultiAnimBuilder, name:String, buttonText:String, ?extraParams:Map<String, Dynamic>) {
		return new UIStandardMultiAnimButton(builder, name, buttonText, extraParams);
	}

	function new(builder:MultiAnimBuilder, name:String, buttonText:String, ?extraParams:Map<String, Dynamic>) {
		var params:Map<String, Dynamic> = ["buttonText" => buttonText, "status" => "normal", "disabled" => "false"];
		if (extraParams != null) {
			for (key => value in extraParams)
				params.set(key, value);
		}
		this.result = builder.buildWithParameters(name, params, null, null, true);
	}

	public function setText(text:String) {
		result.setParameter("buttonText", text);
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

	public function getObject():Object {
		return result.object;
	}

	public function containsPoint(pos:Point):Bool {
		return getObject().getBounds().contains(pos);
	}

	public function clear() {}

	public function getCursor():hxd.Cursor {
		if (disabled)
			return CursorManager.getDefaultCursor();
		return CursorManager.getDefaultInteractiveCursor();
	}

	public function onEvent(wrapper:UIElementEventWrapper) {
		if (this.disabled)
			return;
		switch wrapper.event {
			case OnPush(button):
				result.setParameter("status", "pressed");
			case OnRelease(button):
				triggerClicked(wrapper.control);
				result.setParameter("status", "hover");
			case OnReleaseOutside(_):
				result.setParameter("status", "normal");
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

	function triggerClicked(controllable:Controllable) {
		onClick();
		controllable.pushEvent(UIClick, this);
	}

	public dynamic function onClick() {}
}
