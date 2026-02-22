package bh.test;

import bh.ui.UIElement;
import bh.ui.UIElement.UIElementEvents;
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
