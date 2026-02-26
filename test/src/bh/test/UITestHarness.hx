package bh.test;

import bh.ui.UIElement;
import bh.ui.UIElement.UIElementEvents;
import bh.ui.UIElement.UIElementFloatValue;
import bh.ui.UIElement.UIElementNumberValue;
import bh.ui.UIElement.UIElementListValue;
import bh.ui.UIElement.UIElementListItem;
import bh.ui.UIElement.UIElementSelectable;
import bh.ui.screens.UIScreen;
import h2d.col.Point;
import bh.multianim.MultiAnimParser.ResolvedSettings;
import bh.multianim.MultiAnimParser.SettingValue;

/**
 * Mock CaptureEventsControl for testing UI components.
 */
class MockCaptureEvents implements CaptureEventsControl {
	public var capturing:Bool = false;

	public function new() {}

	public function startCapture():Void {
		capturing = true;
	}

	public function stopCapture():Void {
		capturing = false;
	}

	public function isCapturing():Bool {
		return capturing;
	}
}

/**
 * Mock OutsideClickControl for testing UI components.
 */
class MockOutsideClick implements OutsideClickControl {
	public var tracking:Bool = false;

	public function new() {}

	public function trackOutsideClick(enabled:Bool):Void {
		tracking = enabled;
	}
}

/**
 * Mock Controllable that records pushed events for assertion.
 */
class MockControllable implements Controllable {
	public var captureEvents(default, null):CaptureEventsControl;
	public var outsideClick(default, null):OutsideClickControl;
	public var recordedEvents:Array<{event:UIScreenEvent, source:UIElement}> = [];

	public function new() {
		captureEvents = new MockCaptureEvents();
		outsideClick = new MockOutsideClick();
	}

	public function pushEvent(event:UIScreenEvent, source:UIElement):Void {
		recordedEvents.push({event: event, source: source});
	}

	public function clearEvents():Void {
		recordedEvents = [];
	}

	public function hasEvent(expected:UIScreenEvent):Bool {
		for (e in recordedEvents)
			if (Type.enumEq(e.event, expected))
				return true;
		return false;
	}

	public function eventCount():Int {
		return recordedEvents.length;
	}

	/** Check if any recorded event is a UIInteractiveEvent wrapping the given inner event type. */
	public function hasInteractiveEvent(innerEvent:UIScreenEvent):Bool {
		for (e in recordedEvents) {
			switch e.event {
				case UIInteractiveEvent(evt, _, _):
					if (Type.enumEq(evt, innerEvent))
						return true;
				default:
			}
		}
		return false;
	}
}

/**
 * Minimal UIScreenBase subclass for testing UI components.
 * Records all events received via onScreenEvent.
 * Exposes protected addElement/removeElement for testing the screen's element lifecycle.
 */
class UITestScreen extends UIScreenBase {
	public var recordedEvents:Array<{event:UIScreenEvent, source:Null<UIElement>}> = [];

	public function new() {
		super(cast null);
	}

	public function load():Void {}

	public function onScreenEvent(event:UIScreenEvent, source:UIElement):Void {
		recordedEvents.push({event: event, source: source});
	}

	public function clearEvents():Void {
		recordedEvents = [];
	}

	public function hasEvent(expected:UIScreenEvent):Bool {
		for (e in recordedEvents)
			if (Type.enumEq(e.event, expected))
				return true;
		return false;
	}

	public function eventCount():Int {
		return recordedEvents.length;
	}

	/** Expose autoSyncInitialState for testing. */
	public function testSetAutoSyncInitialState(value:Bool):Void {
		autoSyncInitialState = value;
	}

	/** Expose addElement for testing. */
	public function testAddElement(element:UIElement, ?layer:LayersEnum):UIElement {
		return addElement(element, layer);
	}

	/** Expose removeElement for testing. */
	public function testRemoveElement(element:UIElement):UIElement {
		return removeElement(element);
	}

	/** Expose getSettings for testing. */
	public function testGetSettings(settings:ResolvedSettings, settingName:String, defaultValue:String):String {
		return getSettings(settings, settingName, defaultValue);
	}

	/** Expose getIntSettings for testing. */
	public function testGetIntSettings(settings:ResolvedSettings, settingName:String, defaultValue:Int):Int {
		return getIntSettings(settings, settingName, defaultValue);
	}

	/** Expose getFloatSettings for testing. */
	public function testGetFloatSettings(settings:ResolvedSettings, settingName:String, defaultValue:Float):Float {
		return getFloatSettings(settings, settingName, defaultValue);
	}

	/** Expose getBoolSettings for testing. */
	public function testGetBoolSettings(settings:ResolvedSettings, settingName:String, defaultValue:Bool):Bool {
		return getBoolSettings(settings, settingName, defaultValue);
	}

	/** Expose splitSettings for testing. */
	public function testSplitSettings(settings:ResolvedSettings, controlSettings:Array<String>, behavioralSettings:Array<String>,
			registeredPrefixes:Array<String>, multiForwardSettings:Array<String>,
			elementName:String):{main:Null<Map<String, Dynamic>>, prefixed:Map<String, Map<String, Dynamic>>} {
		return splitSettings(settings, controlSettings, behavioralSettings, registeredPrefixes, multiForwardSettings, elementName);
	}
}

/**
 * Mock UIElement that implements UIElementNumberValue for testing syncInitialState.
 */
class MockNumberElement implements UIElement implements UIElementNumberValue {
	var obj:h2d.Object;
	var value:Int;

	public function new(initialValue:Int) {
		obj = new h2d.Object();
		value = initialValue;
	}

	public function getObject():h2d.Object return obj;
	public function containsPoint(pos:Point):Bool return false;
	public function clear():Void {}
	public function setIntValue(v:Int):Void { value = v; }
	public function getIntValue():Int return value;
}

/**
 * Mock UIElement that implements UIElementFloatValue and UIElementNumberValue for testing syncInitialState.
 */
class MockFloatElement implements UIElement implements UIElementFloatValue implements UIElementNumberValue {
	var obj:h2d.Object;
	var floatVal:Float;
	var intVal:Int;

	public function new(initialFloat:Float, initialInt:Int) {
		obj = new h2d.Object();
		floatVal = initialFloat;
		intVal = initialInt;
	}

	public function getObject():h2d.Object return obj;
	public function containsPoint(pos:Point):Bool return false;
	public function clear():Void {}
	public function setFloatValue(v:Float):Void { floatVal = v; }
	public function getFloatValue():Float return floatVal;
	public function setIntValue(v:Int):Void { intVal = v; }
	public function getIntValue():Int return intVal;
}

/**
 * Mock UIElement that implements UIElementListValue for testing syncInitialState.
 */
class MockListElement implements UIElement implements UIElementListValue {
	var obj:h2d.Object;
	var selectedIndex:Int;
	var items:Array<UIElementListItem>;

	public function new(index:Int, items:Array<UIElementListItem>) {
		obj = new h2d.Object();
		this.selectedIndex = index;
		this.items = items;
	}

	public function getObject():h2d.Object return obj;
	public function containsPoint(pos:Point):Bool return false;
	public function clear():Void {}
	public function setSelectedIndex(idx:Int):Void { selectedIndex = idx; }
	public function getSelectedIndex():Int return selectedIndex;
	public function getList():Array<UIElementListItem> return items;
}

/**
 * Mock UIElement that implements UIElementSelectable for testing syncInitialState.
 */
class MockSelectableElement implements UIElement implements UIElementSelectable {
	var obj:h2d.Object;
	public var selected(default, set):Bool;

	public function new(initialSelected:Bool) {
		obj = new h2d.Object();
		selected = initialSelected;
	}

	function set_selected(v:Bool):Bool return selected = v;
	public function getObject():h2d.Object return obj;
	public function containsPoint(pos:Point):Bool return false;
	public function clear():Void {}
}

/**
 * Utility class for simulating UI events in tests.
 * Provides helpers to construct event wrappers and simulate common interactions.
 */
class UITestHarness {
	/**
	 * Creates a UIElementEventWrapper for simulating UI events on components.
	 */
	public static function createEventWrapper(event:UIElementEvents, control:Controllable, ?pos:Point):UIElementEventWrapper {
		return {
			event: event,
			eventPos: pos != null ? pos : new Point(0, 0),
			control: control
		};
	}

	/** Simulates a full click (push + release) on an element. */
	public static function simulateClick(element:StandardUIElementEvents, control:Controllable, ?pos:Point):Void {
		element.onEvent(createEventWrapper(OnPush(0), control, pos));
		element.onEvent(createEventWrapper(OnRelease(0), control, pos));
	}

	/** Simulates a push (mouse down) on an element. */
	public static function simulatePush(element:StandardUIElementEvents, control:Controllable, ?pos:Point):Void {
		element.onEvent(createEventWrapper(OnPush(0), control, pos));
	}

	/** Simulates mouse enter on an element. */
	public static function simulateEnter(element:StandardUIElementEvents, control:Controllable, ?pos:Point):Void {
		element.onEvent(createEventWrapper(OnEnter, control, pos));
	}

	/** Simulates mouse leave on an element. */
	public static function simulateLeave(element:StandardUIElementEvents, control:Controllable, ?pos:Point):Void {
		element.onEvent(createEventWrapper(OnLeave, control, pos));
	}
}
