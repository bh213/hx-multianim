package bh.ui;

import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.BuilderResolvedSettings;
import bh.multianim.MultiAnimMultiResult;
import bh.ui.UIMultiAnimDropdown;
import h2d.col.Point;
import h2d.Object;
import h2d.col.Bounds;

/**
 * Represents the standard states for UI elements (pressed, hover, normal).
 * Used for visual state management in UI controls.
 */
enum StandardUIElementStates {
	SUIPressed;
	SUIHover;
	SUINormal;
}

/**
 * Represents an item in a UI element list (e.g., dropdown, listbox).
 * Used by controls that display selectable lists.
 */
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

/**
 * Main interface for all UI elements. All UI controls must implement this.
 * Provides access to the underlying h2d.Object and hit-testing.
 */
interface UIElement {
	function getObject():h2d.Object;
	function containsPoint(pos:h2d.col.Point):Bool;
	function clear():Void;
}



/**
 * Interface for UI elements that display or edit text.
 */
interface UIElementText {
	function setText(text:String):Void;
	function getText():String;
}

/**
 * Interface for UI elements that represent an integer value (e.g., sliders, progress bars).
 */
interface UIElementNumberValue {
	function setIntValue(v:Int):Void;
	function getIntValue():Int;
}

/**
 * Interface for UI elements that represent a float value (e.g., sliders with custom range).
 */
interface UIElementFloatValue {
	function setFloatValue(v:Float):Void;
	function getFloatValue():Float;
}

/**
 * Interface for UI elements that represent a selectable list of items.
 */
interface UIElementListValue {
	function setSelectedIndex(idx:Int):Void;
	function getSelectedIndex():Int;
	function getList():Array<UIElementListItem>;
}

//  ---- Controllable ----

/**
 * Interface for UI elements that can be controlled (dragged, receive outside clicks, etc).
 * Used by UI controllers to manage user interaction.
 */
interface Controllable {
	public var captureEvents(default, null):CaptureEventsControl;
	public var outsideClick(default, null):OutsideClickControl;
	public function pushEvent(event:UIScreenEvent, source:UIElement):Void;
}

/**
 * Interface for event capture support in UI elements.
 */
interface CaptureEventsControl {
	function startCapture():Void;
	function stopCapture():Void;
	function isCapturing():Bool;
}

/**
 * Interface for tracking clicks outside a UI element (e.g., closing popups).
 */
interface OutsideClickControl {
	function trackOutsideClick(enabled:Bool):Void;
}

// ---- events ----

/**
 * Events that can be sent to UI elements (mouse, keyboard, etc).
 * Used for event dispatching in the UI system.
 */
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

/**
 * Wrapper for UI element events, including position and control context.
 * Used for passing event data to event handlers.
 */
@:structInit
@:nullSafety
typedef UIElementEventWrapper = {
	var event:UIElementEvents;
	var eventPos:h2d.col.Point;
	var control:Controllable;
}

/**
 * Interface for UI elements that handle standard UI events (mouse, keyboard, etc).
 */
interface StandardUIElementEvents {
	function onEvent(eventWrapper:UIElementEventWrapper):Void;
}



/**
 * Events for controller-level UI interactions (e.g., dialog results, entering/leaving).
 */
enum ControllerEvents {
	Leaving;
	Entering;
	OnDialogResult(dialogName:String, result:Null<Dynamic>);
}

/**
 * Events that can be sent from UI elements to the screen/controller.
 * Used for communication between UI controls and the screen logic.
 */
enum UIScreenEvent {
	UIClick;
	UICustomEvent(eventName:String, data:Dynamic);
	UIToggle(pressed:Bool);
	UIChangeValue(value:Int);
	UIChangeFloatValue(value:Float);
	UIChangeItem(index:Int, items:Array<UIElementListItem>);
	UIKeyPress(keyCode:Int, release:Bool);
	UIOnControllerEvent(event:ControllerEvents);
	UIEntering;
	UILeaving;
}

/**
 * Interface for UI elements that carry an identifier and optional metadata.
 */
interface UIElementIdentifiable {
	var id(default, null):String;
	var prefix(default, null):Null<String>;
	var metadata(default, null):BuilderResolvedSettings;
}

/**
 * Interface for UI elements that can be disabled (e.g., buttons, checkboxes).
 */
interface UIElementDisablable {
	var disabled(default, set):Bool;
}


/**
 * Interface for UI elements that can be selected (e.g., radio buttons, list items).
 */
interface UIElementSelectable {
	var selected(default, set):Bool;
}

/**
 * Interface for UI elements that require periodic updates (e.g., animations).
 */
interface UIElementUpdatable {
	function update(dt:Float):Void;
}

/**
 * Interface for UI elements that support redraw requests (e.g., for custom rendering or state changes).
 */
interface UIElementSyncRedraw {
	var requestRedraw(default, null):Bool;
	function doRedraw():Void;
}

/**
 * Result type for custom add-to-layer logic in UI elements.
 * Used by UIElementCustomAddToLayer.
 */
enum UIElementCustomAddToLayerResult {
	Added;
	Postponed;
}

/**
 * Interface for UI elements that want to override the default add-to-layer logic.
 * Allows custom placement in the scene graph or UI layers.
 */
interface UIElementCustomAddToLayer {
	// return true if you want to use default add to layer function
	function customAddToLayer(requestedLayer:Null<bh.ui.screens.UIScreen.LayersEnum>, screen:bh.ui.screens.UIScreen,
		updateMode:Bool):UIElementCustomAddToLayerResult;
}

/**
 * Types of sub-elements for UI elements that contain other elements (e.g., composite controls).
 * Used by UIElementSubElements.
 */
enum SubElementsType {
	SETReceiveUpdates;
	SETReceiveEvents;
}

/**
 * Interface for UI elements that contain sub-elements (e.g., panels, dropdowns).
 * Allows recursive traversal of UI element trees.
 */
interface UIElementSubElements {
	function getSubElements(type:SubElementsType):Array<UIElement>;
}

/**
 * Utility container for wrapping a UIElement and its associated h2d.Object.
 * Used for cases where a UIElement needs to be paired with a specific display object.
 */
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
