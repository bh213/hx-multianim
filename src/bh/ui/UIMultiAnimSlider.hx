package bh.ui;

import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.MultiAnimBuilder;
import h2d.Object;
import h2d.col.Point;
import bh.ui.UIElement;
import bh.multianim.MultiAnimParser.NamedBuildResult;

class UIStandardMultiAnimSlider implements UIElement implements UIElementDisablable implements StandardUIElementEvents implements UIElementNumberValue
		implements UIElementFloatValue implements UIElementSyncRedraw {
	var status(default, set):StandardUIElementStates = SUINormal;
	var currentResult:Null<BuilderResult> = null;
	var root:h2d.Object;

	public var requestRedraw(default, null):Bool = true;
	public var disabled(default, set):Bool = false;

	var builder:MultiAnimBuilder;
	var currentValue:Float;
	final size:Int;
	final buildName:String;

	public var min:Float = 0;
	public var max:Float = 100;
	public var step:Float = 0;

	var extraParams:Null<Map<String, Dynamic>>;

	function new(builder:MultiAnimBuilder, name:String, size:Int, initialValue:Float, ?extraParams:Null<Map<String, Dynamic>>) {
		this.root = new h2d.Object();
		this.builder = builder;
		this.buildName = name;
		this.currentValue = initialValue;
		this.size = size;
		this.extraParams = extraParams;
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

	public static function create(builder:MultiAnimBuilder, name:String, size:Int, initialValue:Float = 0, ?extraParams:Null<Map<String, Dynamic>>) {
		return new UIStandardMultiAnimSlider(builder, name, size, initialValue, extraParams);
	}

	function externalToInternal(value:Float):Int {
		if (max == min) return 0;
		return Std.int(Math.round((value - min) / (max - min) * 100));
	}

	function snapToStep(value:Float):Float {
		if (step <= 0) return value;
		var snapped = Math.round((value - min) / step) * step + min;
		return hxd.Math.clamp(snapped, min, max);
	}

	public function doRedraw() {
		this.requestRedraw = false;
		if (this.currentResult == null) {
			var params:Map<String, Dynamic> = [
				"status" => standardUIElementStatusToString(status),
				"size" => size,
				"value" => externalToInternal(currentValue),
				"disabled" => '$disabled'
			];
			if (extraParams != null)
				for (key => value in extraParams)
					params.set(key, value);
			this.currentResult = builder.buildWithParameters(buildName, params, null, null, true);
			if (currentResult == null)
				throw 'could not build #${buildName}';
			if (currentResult.object == null)
				throw 'build #${buildName} returned null object';
			root.addChild(this.currentResult.object);
		} else {
			currentResult.beginUpdate();
			currentResult.setParameter("status", standardUIElementStatusToString(status));
			currentResult.setParameter("value", externalToInternal(currentValue));
			currentResult.setParameter("disabled", '$disabled');
			currentResult.endUpdate();
		}
	}

	public function getObject():Object {
		return root;
	}

	public function containsPoint(pos:Point):Bool {
		return getObject().getBounds().contains(pos);
	}

	static function isVisibleInScene(obj:h2d.Object):Bool {
		var cur = obj;
		while (cur != null) {
			if (!cur.visible) return false;
			cur = cur.parent;
		}
		return true;
	}

	// The slider .manim has multiple conditional branches (one per size variant),
	// each with its own #start/#end points. In incremental mode, inactive branches
	// are kept in the scene graph with visible=false on the conditional wrapper.
	// names["start"] returns all variants, so we walk the parent chain to find
	// the one in the active (visible) branch.
	static function findVisible(items:Array<NamedBuildResult>):Null<h2d.Object> {
		for (item in items) {
			final obj = item.getBuiltHeapsObject().toh2dObject();
			if (obj != null && isVisibleInScene(obj))
				return obj;
		}
		return null;
	}

	function calculatePos(eventPos:Point):Float {
		final start = findVisible(currentResult.names["start"]);
		final end = findVisible(currentResult.names["end"]);
		if (start == null || end == null) return currentValue;
		// globalToLocal on start.parent (the ninepatch) converts scene mouse coords
		// into the same coordinate space as start.x/end.x, handling any parent scaling.
		final localPos = start.parent.globalToLocal(eventPos.clone());
		final ratio = hxd.Math.clamp((localPos.x - start.x) / (end.x - start.x), 0, 1);
		return snapToStep(min + ratio * (max - min));
	}

	public function onEvent(wrapper:UIElementEventWrapper) {
		if (this.disabled)
			return;
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
		}
	}

	function triggerOnChange(value:Float, wrapper:UIElementEventWrapper) {
		onChange(Std.int(Math.round(value)), wrapper);
		onFloatChange(value, wrapper);
		wrapper.control.pushEvent(UIChangeValue(Std.int(Math.round(value))), this);
		wrapper.control.pushEvent(UIChangeFloatValue(value), this);
	}

	public dynamic function onChange(value:Int, wrapper:UIElementEventWrapper) {}

	public dynamic function onFloatChange(value:Float, wrapper:UIElementEventWrapper) {}

	public function setFloatValue(v:Float) {
		currentValue = hxd.Math.clamp(v, min, max);
		if (step > 0) currentValue = snapToStep(currentValue);
		this.requestRedraw = true;
	}

	public function getFloatValue():Float {
		return currentValue;
	}

	public function setIntValue(v:Int) {
		setFloatValue(v * 1.0);
	}

	public function getIntValue():Int {
		return Std.int(Math.round(currentValue));
	}
}
