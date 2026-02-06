package bh.ui;

import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.MultiAnimBuilder;
import h2d.Object;
import h2d.col.Point;
import bh.ui.UIElement;

class UIStandardMultiAnimSlider implements UIElement implements UIElementDisablable implements StandardUIElementEvents implements UIElementNumberValue
		implements UIElementSyncRedraw {
	var status(default, set):StandardUIElementStates = SUINormal;
	var currentResult:Null<BuilderResult> = null;
	var root:h2d.Object;

	public var requestRedraw(default, null):Bool = true;
	public var disabled(default, set):Bool = false;

	var builder:MultiAnimBuilder;
	var currentValue:Int;
	final size:Int;
	final buildName:String;

	function new(builder:MultiAnimBuilder, name:String, size:Int, initialValue:Int) {
		this.root = new h2d.Object();
		this.builder = builder;
		this.buildName = name;
		this.currentValue = initialValue;
		this.size = size;
	}

	public function clear() {
		this.currentResult = null;
		this.builder = null;
	}

	public function set_disabled(value:Bool):Bool {
		if (this.disabled != value) {
			this.disabled = value;
			this.requestRedraw = true;
		}
		return value;
	}

	function set_status(value:StandardUIElementStates):StandardUIElementStates {
		if (this.status != value) {
			this.status = value;
			this.requestRedraw = true;
		}
		return value;
	}

	public static function create(builder:MultiAnimBuilder, name:String, size:Int, initialValue = 0) {
		return new UIStandardMultiAnimSlider(builder, name, size, initialValue);
	}

	function buildNew(name, status, value:Int, disabled:Bool, size:Int) {
		var result = builder.buildWithParameters(name, [
			"status" => standardUIElementStatusToString(status),
			"size" => size,
			"value" => value,
			"disabled" => '$disabled'
		]);
		if (result == null)
			throw 'could not build #${name} with status=>${status}';
		if (result.object == null)
			throw 'build #${name} with status=>${status} size=>${size}, value=>${value}, disabled=>${disabled} returned null object';
		return result;
	}

	public function doRedraw() {
		this.requestRedraw = false;
		if (this.currentResult != null && this.currentResult.object != null)
			this.currentResult.object.remove();
		this.currentResult = buildNew(buildName, status, currentValue, disabled, size);

		root.addChild(this.currentResult.object);
	}

	public function getObject():Object {
		return root;
	}

	public function containsPoint(pos:Point):Bool {
		return getObject().getBounds().contains(pos);
	}

	function calculatePos(eventPos:Point) {
		final start = currentResult.names["start"][0].getBuiltHeapsObject().toh2dObject();
		final localPos = start.globalToLocal(eventPos.clone());
		final end = currentResult.names["end"][0].getBuiltHeapsObject().toh2dObject();
		final i = hxd.Math.clamp(localPos.x, start.x, end.x);
		return Std.int(100.0 * i / (end.x - start.x));
	}

	public function onEvent(wrapper:UIElementEventWrapper) {
		if (this.disabled)
			return;
		// trace('${event}, ${isDragging}');
		final isDragging = wrapper.control.captureEvents.isCapturing();
		switch wrapper.event {
			case OnPush(button):
				currentValue = calculatePos(wrapper.eventPos);
				triggerOnChange(currentValue, wrapper);
				this.status = SUIPressed;
				if (!isDragging)
					wrapper.control.captureEvents.startCapture();

			case OnRelease(button):
				this.status = SUINormal;
				if (isDragging)
					wrapper.control.captureEvents.stopCapture();
			case OnReleaseOutside(_) | OnPushOutside(_):
				this.status = SUINormal;
				if (isDragging)
					wrapper.control.captureEvents.stopCapture();
			case OnEnter:
				this.status = SUIHover;
			case OnLeave:
				this.status = SUINormal;
			case OnKey(up, key):
			case OnWheel(dir):
			case OnMouseMove:
				if (isDragging) {
					currentValue = calculatePos(wrapper.eventPos);
					triggerOnChange(currentValue, wrapper);
					this.requestRedraw = true;
				}
				// this.status = SUIPressed;
		}
	}

	function triggerOnChange(value:Int, wrapper:UIElementEventWrapper) {
		onChange(value, wrapper);
		wrapper.control.pushEvent(UIChangeValue(value), this);
	}

	public dynamic function onChange(value:Int, wrapper:UIElementEventWrapper) {}

	public function setIntValue(v:Int) {
		currentValue = Std.int(hxd.Math.clamp(v, 0, 100));
		this.requestRedraw = true;
	}

	public function getIntValue():Int {
		return currentValue;
	}
}
