package bh.ui;

import bh.multianim.MultiAnimMultiResult;
import bh.ui.UIMultiAnimDropdown;
import h2d.col.Point;
import h2d.Object;
import h2d.col.Bounds;

enum StandardUIElementStates {
	SUIPressed;
	SUIHover;
	SUINormal;
}

@:structInit
@:nullSafety
typedef UIElementListItem = {
	var name:String;
	var ?disabled:Bool;
	var ?tileName:String;
	var ?data:Dynamic;
}

function getAllStandardUIElementStatuses() {
	return [SUIPressed, SUIHover, SUINormal];
}

@:nullSafety
function standardUIElementStatusToString(status:StandardUIElementStates) {
	return switch status {
		case SUIPressed: "pressed";
		case SUIHover: "hover";
		case SUINormal: "normal";
	}
}

interface UIElement {
	function getObject():h2d.Object;
	function containsPoint(pos:h2d.col.Point):Bool;
	function clear():Void;
}

interface UIElementText {
	function setText(text:String):Void;
	function getText():String;
}

interface UIElementNumberValue {
	function setIntValue(v:Int):Void;
	function getIntValue():Int;
}

interface UIElementListValue {
	function setSelectedIndex(idx:Int):Void;
	function getSelectedIndex():Int;
	function getList():Array<UIElementListItem>;
}

//  ---- Controllable ----

interface Controllable {
	public var draggable(default, null):DraggableControl;
	public var outsideClick(default, null):OutsideClickControl;
	public function pushEvent(event:UIScreenEvent, source:UIElement):Void;
}

interface DraggableControl {
	function startDrag():Void;
	function stopDrag():Void;
	function isDragging():Bool;
}

interface OutsideClickControl {
	function trackOutsideClick(enabled:Bool):Void;
}

// ---- events ----

enum UIElementEvents {
	OnPush(button:Int);
	OnRelease(button:Int);
	OnPushOutside(button:Int);
	OnReleaseOutside(button:Int);
	OnEnter;
	OnLeave;
	OnKey(keyCode:Int, release:Bool);
	OnWheel(wheelDelta:Float);
	OnMouseMove;
}

@:structInit
@:nullSafety
typedef UIElementEventWrapper = {
	var event:UIElementEvents;
	var eventPos:h2d.col.Point;
	var control:Controllable;
}

interface StandardUIElementEvents {
	function onEvent(eventWrapper:UIElementEventWrapper):Void;
}

enum ControllerEvents {
	Leaving;
	Entering;
	OnDialogResult(dialogName:String, result:Null<Dynamic>);
}

enum UIScreenEvent {
	UIClick;
	UICustomEvent(eventName:String, data:Dynamic);
	UIToggle(pressed:Bool);
	UIChangeValue(value:Int);
	UIChangeItem(index:Int, items:Array<UIElementListItem>);
	UIKeyPress(keyCode:Int, release:Bool);
	UIOnControllerEvent(event:ControllerEvents);
}

interface UIElementDisablable {
	var disabled(default, set):Bool;
}

interface UIElementSelectable {
	var selected(default, set):Bool;
}

interface UIElementItemBuilder {
	function buildItem(index:Int, item:UIElementListItem, itemWidth:Int, itemHeight:Int):MultiAnimMultiResult;
}

interface UIElementUpdatable {
	function update(dt:Float):Void;
}

interface UIElementSyncRedraw {
	var requestRedraw(default, null):Bool;
	function doRedraw():Void;
}

enum UIElementCustomAddToLayerResult {
	Added;
	Postponed;
}

interface UIElementCustomAddToLayer {
	// return true if you want to use default add to layer function
	function customAddToLayer(requestedLayer:Null<bh.ui.screens.UIScreen.LayersEnum>, screen:bh.ui.screens.UIScreen,
		updateMode:Bool):UIElementCustomAddToLayerResult;
}

enum SubElementsType {
	SETReceiveUpdates;
	SETReceiveEvents;
}

interface UIElementSubElements {
	function getSubElements(type:SubElementsType):Array<UIElement>;
}

class UIElementContainer<T:UIElement> implements UIElement {
	public final element:T;
	public final object:h2d.Object;

	public function new(element:T, object:h2d.Object) {
		this.element = element;
		this.object = object;
	}

	public function getObject():Object {
		return object;
	}

	public function containsPoint(pos:Point):Bool {
		return false;
	}

	public function clear() {}
}
