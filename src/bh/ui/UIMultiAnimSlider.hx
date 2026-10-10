package bh.ui;

import bh.base.CursorManager;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.MultiAnimBuilder;
import h2d.Object;
import h2d.col.Point;
import bh.ui.UIElement;
import bh.multianim.MultiAnimParser.NamedBuildResult;

/** Which way a slider runs. `Auto` reads it from the design's `#start` and `#end` points: when
 *  they differ in y and not in x, it is vertical. */
enum SliderDirection {
	Auto;
	Horizontal;
	Vertical;
}

class UIStandardMultiAnimSlider implements UIElement implements UIElementDisablable implements StandardUIElementEvents implements UIElementNumberValue
		implements UIElementFloatValue implements UIElementSyncRedraw implements UIElementCursor {
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
	/** `settings { direction => vertical }`; `Auto` (the default) reads the `#start`/`#end` points. */
	public var direction:SliderDirection = Auto;

	var extraParams:Null<Map<String, Dynamic>>;
	// Scratch reused inside calculatePos() — globalToLocal mutates its argument,
	// so we copy eventPos into this Point to keep the caller's eventPos intact
	// without allocating per event.
	final tmpPoint:Point = new Point();

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

	public function getCursor():hxd.Cursor {
		if (disabled)
			return CursorManager.getDefaultCursor();
		return CursorManager.getDefaultInteractiveCursor();
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
			if (currentResult.hasParameter("disabled"))
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

	// The slider .manim has multiple conditional branches (one per size variant), each with its
	// own #start/#end points; names["start"] holds every variant, and an arm that does not match
	// is out of the scene graph. getNamedDrawn gives the one drawn under the result's root.
	function findVisible(name:String):Null<h2d.Object> {
		return currentResult.getNamedDrawn(name);
	}

	/** Whether the slider runs along y: `direction`, or for `Auto` the `#start`/`#end` points of the
	 *  design (vertical when they differ in y and not in x). */
	public function isVertical():Bool {
		return switch direction {
			case Vertical: true;
			case Horizontal: false;
			case Auto:
				if (currentResult == null) return false;
				final start = findVisible("start");
				final end = findVisible("end");
				start != null && end != null && start.x == end.x && start.y != end.y;
		};
	}

	function calculatePos(eventPos:Point):Float {
		final start = findVisible("start");
		final end = findVisible("end");
		if (start == null || end == null) return currentValue;
		// globalToLocal on start.parent (the ninepatch) converts scene mouse coords
		// into the same coordinate space as start.x/end.x, handling any parent scaling.
		// globalToLocal mutates its argument — copy into scratch so eventPos stays intact.
		tmpPoint.set(eventPos.x, eventPos.y);
		final localPos = start.parent.globalToLocal(tmpPoint);
		final vertical = switch direction {
			case Vertical: true;
			case Horizontal: false;
			case Auto: start.x == end.x && start.y != end.y;
		};
		final ratio = vertical
			? hxd.Math.clamp((localPos.y - start.y) / (end.y - start.y), 0, 1)
			: hxd.Math.clamp((localPos.x - start.x) / (end.x - start.x), 0, 1);
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
