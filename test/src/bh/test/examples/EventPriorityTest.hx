package bh.test.examples;

import utest.Assert;
import h2d.col.Point;
import bh.ui.UIElement;
import bh.ui.controllers.UIController;
import bh.ui.controllers.UIDefaultController;
import bh.ui.screens.UIScreen.LayersEnum;
import bh.ui.screens.ScreenManager;
import bh.ui.ControllerEventHandler;
import bh.test.UITestHarness.UITestScreen;
import hxd.Event.EventKind;

/**
 * Mock element with configurable hit area, priority, and consumed behavior.
 */
private class MockInteractive implements UIElement implements StandardUIElementEvents implements UIElementPriority {
	public final name:String;
	public var eventPriority(default, null):Int;
	public var consumeEvents:Bool;
	public var receivedEvents:Array<UIElementEvents> = [];

	final x:Float;
	final y:Float;
	final w:Float;
	final h:Float;

	public function new(name:String, x:Float, y:Float, w:Float, h:Float, priority:Int = 0, consume:Bool = true) {
		this.name = name;
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
		this.eventPriority = priority;
		this.consumeEvents = consume;
	}

	public function getObject():h2d.Object return new h2d.Object();

	public function containsPoint(pos:Point):Bool {
		return pos.x >= x && pos.x <= x + w && pos.y >= y && pos.y <= y + h;
	}

	public function clear():Void {}

	public function onEvent(wrapper:UIElementEventWrapper):Void {
		receivedEvents.push(wrapper.event);
		wrapper.consumed = consumeEvents;
	}

	public function clearReceived():Void {
		receivedEvents = [];
	}
}

/**
 * Mock element standing in a real scene graph, so what is drawn over what can be told.
 */
private class MockDrawnInteractive extends MockInteractive {
	final object:h2d.Object;

	public function new(name:String, parent:h2d.Object) {
		super(name, 0, 0, 100, 100);
		this.object = new h2d.Object(parent);
	}

	override public function getObject():h2d.Object return object;
}

/**
 * Controller that only records where the screens' event handler says a pointer event happened.
 */
private class PointRecordingController extends UIDefaultController {
	public final points:Array<Point> = [];
	public var onClick:Null<Void->Void> = null;

	override public function handleClick(mousePoint:Point, button:Int, release:Bool, eventWrapper:EventWrapper):Void {
		points.push(mousePoint.clone());
		if (onClick != null)
			onClick();
	}

	override public function handleMove(mousePoint:Point, eventWrapper:EventWrapper):Void {
		points.push(mousePoint.clone());
	}
}

private class PointRecordingScreen extends UITestScreen {
	public final recording:PointRecordingController;

	public function new() {
		super();
		recording = new PointRecordingController(new MockIntegration());
	}

	override public function getController():UIController {
		return recording;
	}
}

/**
 * Mock element WITHOUT UIElementPriority — tests that non-priority elements default to 0.
 */
private class MockInteractiveNoPriority implements UIElement implements StandardUIElementEvents {
	public final name:String;
	public var consumeEvents:Bool;
	public var receivedEvents:Array<UIElementEvents> = [];

	final x:Float;
	final y:Float;
	final w:Float;
	final h:Float;

	public function new(name:String, x:Float, y:Float, w:Float, h:Float, consume:Bool = true) {
		this.name = name;
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
		this.consumeEvents = consume;
	}

	public function getObject():h2d.Object return new h2d.Object();

	public function containsPoint(pos:Point):Bool {
		return pos.x >= x && pos.x <= x + w && pos.y >= y && pos.y <= y + h;
	}

	public function clear():Void {}

	public function onEvent(wrapper:UIElementEventWrapper):Void {
		receivedEvents.push(wrapper.event);
		wrapper.consumed = consumeEvents;
	}

	public function clearReceived():Void {
		receivedEvents = [];
	}
}

/**
 * Mock widget that holds the mouse from a push to its release (as a slider, scrollbar or list
 * does while dragged) and, disabled, ignores every event, as those widgets do.
 */
private class MockCapturingWidget implements UIElement implements StandardUIElementEvents implements UIElementDisablable {
	public var disabled(default, set):Bool = false;
	public var receivedEvents:Array<UIElementEvents> = [];

	final x:Float;
	final y:Float;
	final w:Float;
	final h:Float;

	public function new(x:Float, y:Float, w:Float, h:Float) {
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
	}

	function set_disabled(value:Bool):Bool {
		return disabled = value;
	}

	public function getObject():h2d.Object return new h2d.Object();

	public function containsPoint(pos:Point):Bool {
		return pos.x >= x && pos.x <= x + w && pos.y >= y && pos.y <= y + h;
	}

	public function clear():Void {}

	public function onEvent(wrapper:UIElementEventWrapper):Void {
		if (disabled)
			return;
		receivedEvents.push(wrapper.event);
		switch wrapper.event {
			case OnPush(_): wrapper.control.captureEvents.startCapture();
			case OnRelease(_): wrapper.control.captureEvents.stopCapture();
			default:
		}
	}
}

/**
 * Mock UIControllerScreenIntegration for testing UIDefaultController in isolation.
 */
private class MockIntegration implements UIControllerScreenIntegration {
	public var elements:Array<UIElement> = [];
	public var dispatchedEvents:Array<UIScreenEvent> = [];
	/** A component takes the release, as a card hand does at the end of a drag. */
	public var consumeRelease:Bool = false;

	public function new() {}

	public function dispatchScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {
		dispatchedEvents.push(event);
	}

	public function forEachElement(type:SubElementsType, fn:UIElement->Void):Void {
		for (e in elements) fn(e);
	}

	public function onKey(keyCode:Int, release:Bool):Bool return true;
	public function dispatchMouseMove(pos:Point):Bool return true;
	public function onMouseWheel(pos:Point, delta:Float):Bool return true;
	public function dispatchMouseClick(pos:Point, button:Int, release:Bool):Bool return !(release && consumeRelease);
}

/**
 * Mock integration that throws when its allocating getElements() is called.
 * UIDefaultController must drive its hot path entirely through forEachElement —
 * any caller that reaches for getElements re-introduces the Array + concat
 * allocation shape this contract removes.
 */
private class ThrowingGetElementsIntegration implements UIControllerScreenIntegration {
	public var elements:Array<UIElement> = [];
	public var getElementsCallCount:Int = 0;

	public function new() {}

	public function dispatchScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {}

	public function getElements(type:SubElementsType):Array<UIElement> {
		getElementsCallCount++;
		throw "Production code must not call getElements() — use forEachElement";
	}

	public function forEachElement(type:SubElementsType, fn:UIElement->Void):Void {
		for (e in elements) fn(e);
	}

	public function onKey(keyCode:Int, release:Bool):Bool return true;
	public function dispatchMouseMove(pos:Point):Bool return true;
	public function onMouseWheel(pos:Point, delta:Float):Bool return true;
	public function dispatchMouseClick(pos:Point, button:Int, release:Bool):Bool return true;
}

/**
 * Mock integration that records every callback handed to forEachElement, so tests
 * can assert UIDefaultController reuses a single cached callback instance across
 * input events instead of allocating a fresh closure per call.
 */
private class CallbackTrackingIntegration implements UIControllerScreenIntegration {
	public var elements:Array<UIElement> = [];
	public var receiveEventsCallbacks:Array<UIElement->Void> = [];

	public function new() {}

	public function dispatchScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {}

	public function forEachElement(type:SubElementsType, fn:UIElement->Void):Void {
		if (type == SETReceiveEvents) receiveEventsCallbacks.push(fn);
		for (e in elements) fn(e);
	}

	public function onKey(keyCode:Int, release:Bool):Bool return true;
	public function dispatchMouseMove(pos:Point):Bool return true;
	public function onMouseWheel(pos:Point, delta:Float):Bool return true;
	public function dispatchMouseClick(pos:Point, button:Int, release:Bool):Bool return true;
}

/**
 * Unit tests for event priority ordering and consumed bubbling in UIDefaultController.
 */
class EventPriorityTest extends utest.Test {
	var integration:MockIntegration;
	var controller:UIDefaultController;

	function setup() {
		integration = new MockIntegration();
		controller = new UIDefaultController(integration);
	}

	final disposals:Array<Void->Void> = [];

	function teardown():Void {
		for (dispose in disposals)
			dispose();
		disposals.resize(0);
	}

	static function eventWrapper():EventWrapper {
		return {
			sourceEvent: new hxd.Event(hxd.Event.EventKind.EPush),
			mousePoint: new Point(0, 0),
			scene: null
		};
	}

	static function touchWrapper(kind:EventKind):EventWrapper {
		final event = new hxd.Event(kind);
		event.touchId = 1;
		return {sourceEvent: event, mousePoint: new Point(0, 0), scene: null};
	}

	static function eventNames(element:MockInteractive):Array<String> {
		return [for (e in element.receivedEvents) Type.enumConstructor(e)];
	}

	/** The screens' event handler over a scene zoomed by 2, and where it says each event happened. */
	function handlerOverZoomedScene():{scene:h2d.Scene, handler:ControllerEventHandler, manager:ScreenManager, points:Array<Point>} {
		final sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		final scene = new h2d.Scene();
		scene.scaleMode = h2d.Scene.ScaleMode.Zoom(2);
		scene.syncOnly(0);
		final handler = new ControllerEventHandler(scene, hxd.Window.getInstance(), sm);
		disposals.push(() -> {
			handler.dispose();
			sm.dispose();
		});
		final screen = new PointRecordingScreen();
		@:privateAccess sm.activeScreenControllers = [screen];
		return {scene: scene, handler: handler, manager: sm, points: screen.recording.points};
	}

	static function recordingScreens(manager:ScreenManager, count:Int):Array<PointRecordingScreen> {
		final screens = [for (_ in 0...count) new PointRecordingScreen()];
		@:privateAccess manager.activeScreenControllers = [for (s in screens) (s : bh.ui.screens.UIScreen)];
		return screens;
	}

	// ==================== Priority Ordering ====================

	@Test
	public function testHighPriorityReceivesEventFirst():Void {
		var low = new MockInteractive("low", 0, 0, 100, 100, 0);
		var high = new MockInteractive("high", 0, 0, 100, 100, 10);
		// Register low first, high second — priority should override registration order
		integration.elements = [low, high];

		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());

		Assert.equals(1, high.receivedEvents.length);
		Assert.equals(0, low.receivedEvents.length);
	}

	@Test
	public function testHighPriorityRegisteredSecondStillWins():Void {
		var high = new MockInteractive("high", 0, 0, 100, 100, 5);
		var low = new MockInteractive("low", 0, 0, 100, 100, 1);
		integration.elements = [high, low];

		controller.handleClick(new Point(50, 50), 0, true, eventWrapper());

		Assert.equals(1, high.receivedEvents.length);
		Assert.equals(0, low.receivedEvents.length);
	}

	@Test
	public function testEqualPriorityPreservesRegistrationOrder():Void {
		var first = new MockInteractive("first", 0, 0, 100, 100, 0);
		var second = new MockInteractive("second", 0, 0, 100, 100, 0);
		integration.elements = [first, second];

		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());

		// Both at priority 0, first registered wins (consumed by default)
		Assert.equals(1, first.receivedEvents.length);
		Assert.equals(0, second.receivedEvents.length);
	}

	// ==================== Draw Order Among Equal Priorities ====================

	@Test
	public function testEqualPriorityTheOneDrawnOnTopTakesTheClick():Void {
		final root = new h2d.Object();
		// Made first, so registered first, and drawn under what is made after it
		final blocker = new MockDrawnInteractive("blocker", root);
		final button = new MockDrawnInteractive("button", root);
		integration.elements = [blocker, button];

		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());

		Assert.equals(1, button.receivedEvents.length, "the button is drawn over the blocker: the click is the button's");
		Assert.equals(0, blocker.receivedEvents.length, "the blocker drawn under the button takes nothing");
	}

	@Test
	public function testEqualPriorityDrawOrderFollowsLayersAndNesting():Void {
		final root = new h2d.Layers();
		final upper = new h2d.Object();
		final lower = new h2d.Object();
		// Added first, on the higher layer: drawn last
		root.add(upper, 5);
		root.add(lower, 1);
		final under = new MockDrawnInteractive("under", lower);
		final over = new MockDrawnInteractive("over", new h2d.Object(upper));
		integration.elements = [under, over];

		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());

		Assert.equals(1, over.receivedEvents.length, "what stands in the higher layer is drawn on top, however deep");
		Assert.equals(0, under.receivedEvents.length, "what stands in the lower layer takes nothing");
	}

	@Test
	public function testEqualPriorityAnOverlaysButtonAnswersWithABlockerDeclaredBeforeIt():Void {
		final result = bh.test.BuilderTestBase.buildFromSource('
			#test programmable() {
				interactive(100, 100, "confirm-block"): 0, 0
				interactive(40, 20, "begin"): 10, 10
			}
		', "test");
		for (obj in result.interactives)
			integration.elements.push(new bh.ui.UIInteractiveWrapper(obj, null));

		controller.handleClick(new Point(20, 15), 0, false, eventWrapper());

		final pushed:Array<String> = [];
		for (e in integration.dispatchedEvents)
			switch e {
				case UIInteractiveEvent(UIPush, id, _): pushed.push(id);
				default:
			}
		Assert.same(["begin"], pushed, "the button declared after the full-screen blocker is drawn on it and takes the press");
	}

	@Test
	public function testEqualPriorityAChildIsDrawnOverItsParent():Void {
		final parent = new MockDrawnInteractive("parent", new h2d.Object());
		final child = new MockDrawnInteractive("child", parent.getObject());
		integration.elements = [parent, child];

		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());

		Assert.equals(1, child.receivedEvents.length, "a child is drawn after its parent, so it is on top");
		Assert.equals(0, parent.receivedEvents.length, "the parent under its child takes nothing");
	}

	// ==================== Consumed Bubbling ====================

	@Test
	public function testConsumedTrueStopsAtFirstElement():Void {
		var top = new MockInteractive("top", 0, 0, 100, 100, 10, true);
		var bottom = new MockInteractive("bottom", 0, 0, 100, 100, 0, true);
		integration.elements = [top, bottom];

		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());

		Assert.equals(1, top.receivedEvents.length);
		Assert.equals(0, bottom.receivedEvents.length);
	}

	@Test
	public function testConsumedFalseBubblesToNext():Void {
		var top = new MockInteractive("top", 0, 0, 100, 100, 10, false);
		var bottom = new MockInteractive("bottom", 0, 0, 100, 100, 0, true);
		integration.elements = [top, bottom];

		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());

		Assert.equals(1, top.receivedEvents.length);
		Assert.equals(1, bottom.receivedEvents.length);
	}

	@Test
	public function testBubbleThroughMultipleLayers():Void {
		var a = new MockInteractive("a", 0, 0, 100, 100, 20, false);
		var b = new MockInteractive("b", 0, 0, 100, 100, 10, false);
		var c = new MockInteractive("c", 0, 0, 100, 100, 0, true);
		integration.elements = [a, b, c];

		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());

		// All three receive the event: a and b pass through, c consumes
		Assert.equals(1, a.receivedEvents.length);
		Assert.equals(1, b.receivedEvents.length);
		Assert.equals(1, c.receivedEvents.length);
	}

	@Test
	public function testBubbleStopsMidChain():Void {
		var a = new MockInteractive("a", 0, 0, 100, 100, 20, false);
		var b = new MockInteractive("b", 0, 0, 100, 100, 10, true); // consumes
		var c = new MockInteractive("c", 0, 0, 100, 100, 0, true);
		integration.elements = [a, b, c];

		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());

		Assert.equals(1, a.receivedEvents.length);
		Assert.equals(1, b.receivedEvents.length);
		Assert.equals(0, c.receivedEvents.length); // never reached
	}

	@Test
	public function testAllPassThroughNoneConsume():Void {
		var a = new MockInteractive("a", 0, 0, 100, 100, 10, false);
		var b = new MockInteractive("b", 0, 0, 100, 100, 0, false);
		integration.elements = [a, b];

		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());

		// Both receive the event, neither consumes
		Assert.equals(1, a.receivedEvents.length);
		Assert.equals(1, b.receivedEvents.length);
	}

	// ==================== Non-overlapping ====================

	@Test
	public function testNonOverlappingOnlyHitsTarget():Void {
		var left = new MockInteractive("left", 0, 0, 50, 100, 10, true);
		var right = new MockInteractive("right", 60, 0, 50, 100, 0, true);
		integration.elements = [left, right];

		controller.handleClick(new Point(70, 50), 0, false, eventWrapper());

		Assert.equals(0, left.receivedEvents.length);
		Assert.equals(1, right.receivedEvents.length);
	}

	@Test
	public function testClickMissesAll():Void {
		var elem = new MockInteractive("elem", 0, 0, 50, 50, 0, true);
		integration.elements = [elem];

		controller.handleClick(new Point(200, 200), 0, false, eventWrapper());

		Assert.equals(0, elem.receivedEvents.length);
	}

	// ==================== Mixed Priority/NoPriority ====================

	@Test
	public function testNoPriorityElementDefaultsToZero():Void {
		var high = new MockInteractive("high", 0, 0, 100, 100, 5, true);
		var noPrio = new MockInteractiveNoPriority("noPrio", 0, 0, 100, 100, true);
		// noPrio registered first, but high has priority 5
		integration.elements = [noPrio, high];

		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());

		Assert.equals(1, high.receivedEvents.length);
		Assert.equals(0, noPrio.receivedEvents.length);
	}

	@Test
	public function testNoPriorityBubblePassThrough():Void {
		var noPrio = new MockInteractiveNoPriority("noPrio", 0, 0, 100, 100, false);
		var fallback = new MockInteractive("fallback", 0, 0, 100, 100, 0, true);
		integration.elements = [noPrio, fallback];

		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());

		Assert.equals(1, noPrio.receivedEvents.length);
		Assert.equals(1, fallback.receivedEvents.length);
	}

	// ==================== Release Events ====================

	@Test
	public function testReleaseEventBubbles():Void {
		var top = new MockInteractive("top", 0, 0, 100, 100, 10, false);
		var bottom = new MockInteractive("bottom", 0, 0, 100, 100, 0, true);
		integration.elements = [top, bottom];

		controller.handleClick(new Point(50, 50), 0, true, eventWrapper());

		Assert.equals(1, top.receivedEvents.length);
		Assert.equals(1, bottom.receivedEvents.length);
		// Both should receive OnRelease
		switch top.receivedEvents[0] { case OnRelease(_): Assert.pass(); default: Assert.fail("Expected OnRelease"); }
		switch bottom.receivedEvents[0] { case OnRelease(_): Assert.pass(); default: Assert.fail("Expected OnRelease"); }
	}

	// ==================== Capture ====================

	@Test
	public function testAWidgetDisabledWhileItHoldsTheMouseLetsItGo():Void {
		final slider = new MockCapturingWidget(0, 0, 50, 50);
		final other = new MockInteractive("other", 60, 0, 50, 50);
		integration.elements = [slider, other];

		controller.handleClick(new Point(10, 10), 0, false, eventWrapper());
		Assert.equals(1, slider.receivedEvents.length, "the push starts the drag");
		slider.disabled = true;
		controller.handleClick(new Point(70, 10), 0, false, eventWrapper());

		Assert.equals(1, other.receivedEvents.length,
			"a widget disabled mid-drag never hears its release, so the controller must not keep the mouse for it");
	}

	// ==================== Wheel Events ====================

	@Test
	public function testWheelEventRespectsConsumed():Void {
		var top = new MockInteractive("top", 0, 0, 100, 100, 10, false);
		var bottom = new MockInteractive("bottom", 0, 0, 100, 100, 0, true);
		integration.elements = [top, bottom];

		controller.handleMouseWheel(new Point(50, 50), 1.0, eventWrapper());

		Assert.equals(1, top.receivedEvents.length);
		Assert.equals(1, bottom.receivedEvents.length);
	}

	@Test
	public function testWheelEventStopsWhenConsumed():Void {
		var top = new MockInteractive("top", 0, 0, 100, 100, 10, true);
		var bottom = new MockInteractive("bottom", 0, 0, 100, 100, 0, true);
		integration.elements = [top, bottom];

		controller.handleMouseWheel(new Point(50, 50), 1.0, eventWrapper());

		Assert.equals(1, top.receivedEvents.length);
		Assert.equals(0, bottom.receivedEvents.length);
	}

	// ==================== Key Events ====================

	@Test
	public function testKeyEventBubbles():Void {
		var top = new MockInteractive("top", 0, 0, 100, 100, 10, false);
		var bottom = new MockInteractive("bottom", 0, 0, 100, 100, 0, true);
		integration.elements = [top, bottom];

		controller.handleKey(32, false, new Point(50, 50), eventWrapper());

		Assert.equals(1, top.receivedEvents.length);
		Assert.equals(1, bottom.receivedEvents.length);
	}

	@Test
	public function testKeyEventStopsWhenConsumed():Void {
		var top = new MockInteractive("top", 0, 0, 100, 100, 10, true);
		var bottom = new MockInteractive("bottom", 0, 0, 100, 100, 0, true);
		integration.elements = [top, bottom];

		controller.handleKey(32, false, new Point(50, 50), eventWrapper());

		Assert.equals(1, top.receivedEvents.length);
		Assert.equals(0, bottom.receivedEvents.length);
	}

	// ==================== Hover (Top Element Only) ====================

	@Test
	public function testHoverOnlyTopElement():Void {
		var top = new MockInteractive("top", 0, 0, 100, 100, 10, false);
		var bottom = new MockInteractive("bottom", 0, 0, 100, 100, 0, true);
		integration.elements = [top, bottom];

		// Move into the overlap area
		controller.handleMove(new Point(50, 50), eventWrapper());

		// Only top gets OnEnter (hover is single-element)
		var topHasEnter = false;
		for (e in top.receivedEvents) switch e { case OnEnter: topHasEnter = true; default: }
		Assert.isTrue(topHasEnter);

		var bottomHasEnter = false;
		for (e in bottom.receivedEvents) switch e { case OnEnter: bottomHasEnter = true; default: }
		Assert.isFalse(bottomHasEnter);
	}

	// ==================== Touch ====================

	@Test
	public function testATouchArrivesWithItsPressAndLeavesNoHoverWhenItLifts():Void {
		final button = new MockInteractive("button", 0, 0, 100, 100);
		integration.elements = [button];
		final finger = new Point(50, 50);

		controller.handleClick(finger, 0, false, touchWrapper(EPush));
		controller.handleClick(finger, 0, true, touchWrapper(ERelease));

		Assert.same(["OnMouseMove", "OnEnter", "OnPush", "OnRelease", "OnLeave"], eventNames(button),
			"a tap is a pointer that arrives, presses, releases and goes: nothing stays lit after the finger lifts");
	}

	@Test
	public function testALiftAComponentConsumesStillLeavesNoHover():Void {
		final button = new MockInteractive("button", 0, 0, 100, 100);
		integration.elements = [button];
		integration.consumeRelease = true;
		final finger = new Point(50, 50);

		controller.handleClick(finger, 0, false, touchWrapper(EPush));
		controller.handleClick(finger, 0, true, touchWrapper(ERelease));

		Assert.equals("OnLeave", eventNames(button).pop(), "a release taken by a component (a card hand's drag) still ends the hover");
	}

	@Test
	public function testAMouseReleaseKeepsTheHover():Void {
		final button = new MockInteractive("button", 0, 0, 100, 100);
		integration.elements = [button];
		final at = new Point(50, 50);

		controller.handleMove(at, eventWrapper());
		controller.handleClick(at, 0, false, eventWrapper());
		controller.handleClick(at, 0, true, eventWrapper());

		Assert.same(["OnMouseMove", "OnEnter", "OnPush", "OnRelease"], eventNames(button),
			"a mouse is still there after its click, and so is its hover");
	}

	@Test
	public function testATouchTakesItsOwnPlaceThroughTheScene():Void {
		final zoomed = handlerOverZoomedScene();

		for (kind in [EPush, EMove, ERelease]) {
			final touch = new hxd.Event(kind, 100, 60);
			touch.touchId = 1;
			zoomed.handler.handleEvents(touch);
			Assert.floatEquals(100, touch.relX, "the event goes on to Heaps' own scene events as it came");
		}

		Assert.equals(3, zoomed.points.length);
		for (point in zoomed.points) {
			Assert.floatEquals(50, point.x, "the finger at 100 in the window is at 50 in a scene zoomed by 2");
			Assert.floatEquals(30, point.y, "the finger at 60 in the window is at 30 in a scene zoomed by 2");
		}
	}

	@Test
	public function testAMouseEventKeepsTheMousesPlace():Void {
		final zoomed = handlerOverZoomedScene();

		zoomed.handler.handleEvents(new hxd.Event(EPush, 100, 60));

		Assert.equals(1, zoomed.points.length);
		Assert.floatEquals(zoomed.scene.mouseX, zoomed.points[0].x, "a mouse event is placed where the mouse is");
		Assert.floatEquals(zoomed.scene.mouseY, zoomed.points[0].y, "a mouse event is placed where the mouse is");
	}

	// ==================== The Event Handler's Controllers ====================

	@Test
	public function testAScreenLeavingDuringAnEventStillLetsTheRestHearIt():Void {
		final zoomed = handlerOverZoomedScene();
		final screens = recordingScreens(zoomed.manager, 3);
		// What a screen switch does from a click handler
		screens[0].recording.onClick = () -> {
			@:privateAccess zoomed.manager.activeScreenControllers.remove(screens[0]);
		};

		zoomed.handler.handleEvents(new hxd.Event(EPush, 10, 10));

		for (i in 0...3)
			Assert.equals(1, screens[i].recording.points.length, 'screen $i hears the event as the event found the screens');
	}

	@Test
	public function testAnEventRaisedDuringAnEventLeavesTheOuterOneWhole():Void {
		final zoomed = handlerOverZoomedScene();
		final screens = recordingScreens(zoomed.manager, 2);
		var raised = false;
		screens[0].recording.onClick = () -> {
			if (!raised) {
				raised = true;
				zoomed.handler.handleEvents(new hxd.Event(EPush, 20, 20));
			}
		};

		zoomed.handler.handleEvents(new hxd.Event(EPush, 10, 10));

		Assert.equals(2, screens[0].recording.points.length, "the first screen hears the outer event and the one it raised");
		Assert.equals(2, screens[1].recording.points.length, "the second screen hears the raised event and still the outer one");
	}

	#if MULTIANIM_ALLOC_TRACK
	@Test
	public function testTheEventHandlerMakesNoControllerListPerEvent():Void {
		final zoomed = handlerOverZoomedScene();
		zoomed.handler.handleEvents(new hxd.Event(EMove, 10, 10)); // warm-up

		final baseline = ControllerEventHandler.controllerListCount;
		for (_ in 0...50)
			zoomed.handler.handleEvents(new hxd.Event(EMove, 10, 10));

		final made = ControllerEventHandler.controllerListCount - baseline;
		Assert.equals(0, made, "every mouse move comes through handleEvents, which must reuse its list of controllers. Got " + made + " across 50 events.");
	}
	#end

	// ==================== eventPriority from .manim metadata ====================

	@Test
	public function testEventPriorityFromManimMetadata():Void {
		var result = bh.test.BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 100, #666666))): 0, 0
				interactive(100, 100, "btn1", eventPriority:int => 42): 0, 0
			}
		', "test");
		var wrapper = new bh.ui.UIInteractiveWrapper(result.interactives[0], null);
		Assert.equals(42, wrapper.eventPriority);
	}

	// UIDefaultController.update / getEventElements call integration.getElements()
	// every frame / every event, which allocates a defensive copy + concat. The fix
	// adds a callback variant `forEachElement(type, fn)` that streams elements
	// (and provider sub-elements) without building an array. This test pins the
	// contract: the new method visits the same elements in the same order.
	@Test
	public function testIntegrationForEachElementVisitsAllElementsInOrder():Void {
		var a = new MockInteractive("a", 0, 0, 10, 10);
		var b = new MockInteractive("b", 0, 0, 10, 10);
		var c = new MockInteractive("c", 0, 0, 10, 10);
		integration.elements = [a, b, c];

		var visited:Array<UIElement> = [];
		integration.forEachElement(SETReceiveUpdates, function(e:UIElement):Void {
			visited.push(e);
		});

		Assert.equals(3, visited.length,
			"forEachElement must visit every element registered on the integration. "
			+ "If this fires, the callback variant is dropping elements that getElements() returns.");
		Assert.equals(cast a, visited[0], "forEachElement must preserve registration order.");
		Assert.equals(cast b, visited[1], "forEachElement must preserve registration order.");
		Assert.equals(cast c, visited[2], "forEachElement must preserve registration order.");
	}

	@Test
	public function testEventPriorityDefaultZero():Void {
		var result = bh.test.BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 100, #666666))): 0, 0
				interactive(100, 100, "btn1"): 0, 0
			}
		', "test");
		var wrapper = new bh.ui.UIInteractiveWrapper(result.interactives[0], null);
		Assert.equals(0, wrapper.eventPriority);
	}

	// ==================== Allocation Watchdog ====================

	// getEventElements is called from handleMove / handleClick / handleMouseWheel /
	// handleKey — i.e. once per input event. Each call must reuse the same scratch
	// buffer instead of allocating a new Array<UIElement>. The capture-target
	// short-circuit must also reuse scratch rather than returning a fresh single-
	// element array.
	#if MULTIANIM_ALLOC_TRACK
	@Test
	public function testGetEventElementsReusesScratchAcrossMouseMoves():Void {
		var a = new MockInteractive("a", 0, 0, 100, 100, 0);
		var b = new MockInteractive("b", 0, 0, 100, 100, 5);
		integration.elements = [a, b];

		// Warm-up — settles any first-call allocation that's not on the hot path.
		controller.handleMove(new Point(50, 50), eventWrapper());

		final baseline = UIDefaultController.hitsCreationCount;
		for (i in 0...50) {
			controller.handleMove(new Point(50 + (i % 10), 50), eventWrapper());
		}
		final delta = UIDefaultController.hitsCreationCount - baseline;
		Assert.equals(0, delta,
			"getEventElements must reuse instance scratch instead of allocating a new "
			+ "Array<UIElement> per call (and per sort comparator). Got " + delta
			+ " extra allocations across 50 handleMove calls.");
	}

	@Test
	public function testGetEventElementsCaptureTargetShortCircuitReusesScratch():Void {
		var a = new MockInteractive("a", 0, 0, 100, 100, 0);
		integration.elements = [a];

		// Force the capture-target short-circuit path inside getEventElements.
		// Simulate a drag-like sequence: push, then move with target captured.
		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());
		// Manually set capture target so the short-circuit branch is exercised.
		@:privateAccess controller.controllable.captureEvents.target = a;

		controller.handleMove(new Point(60, 50), eventWrapper());

		final baseline = UIDefaultController.hitsCreationCount;
		for (i in 0...50) {
			controller.handleMove(new Point(60 + (i % 10), 50), eventWrapper());
		}
		final delta = UIDefaultController.hitsCreationCount - baseline;
		Assert.equals(0, delta,
			"getEventElements capture-target short-circuit must reuse scratch instead of "
			+ "returning a fresh [target] array per call. Got " + delta
			+ " extra allocations across 50 handleMove calls with capture target set.");
	}
	#end

	// getEventElements is called from handleMove / handleClick / handleMouseWheel /
	// handleKey. It used to inline an anonymous `function(element) { ... }` literal
	// that captured the per-call `pos` local, forcing a fresh closure allocation on
	// every input event. The fix mirrors the _updateCallback pattern: thread `pos`
	// through an instance field and hoist the callback to a final field assigned
	// once in the constructor. This pins the contract — the SAME callback instance
	// must reach forEachElement across every input event.
	@Test
	public function testGetEventElementsReusesCachedCallbackInstanceAcrossInputEvents():Void {
		var tracking = new CallbackTrackingIntegration();
		tracking.elements = [new MockInteractive("a", 0, 0, 100, 100, 0)];
		var ctrl = new UIDefaultController(tracking);

		ctrl.handleMove(new Point(50, 50), eventWrapper());
		ctrl.handleMove(new Point(60, 50), eventWrapper());
		ctrl.handleClick(new Point(70, 50), 0, false, eventWrapper());
		ctrl.handleClick(new Point(80, 50), 0, true, eventWrapper());
		ctrl.handleMouseWheel(new Point(90, 50), 1.0, eventWrapper());
		ctrl.handleKey(32, false, new Point(50, 50), eventWrapper());

		Assert.isTrue(tracking.receiveEventsCallbacks.length >= 6,
			"Expected at least 6 SETReceiveEvents callback captures across the input "
			+ "hot path; got " + tracking.receiveEventsCallbacks.length + ". If this fires, "
			+ "the input handlers stopped routing through getEventElements / forEachElement.");

		final first = tracking.receiveEventsCallbacks[0];
		for (i in 1...tracking.receiveEventsCallbacks.length) {
			final same = Reflect.compareMethods(first, tracking.receiveEventsCallbacks[i]);
			Assert.isTrue(same,
				"getEventElements must pass the SAME cached callback instance to "
				+ "forEachElement across every input event. A fresh closure surfaced at "
				+ "call " + i + " — fix by hoisting the callback to a final field assigned "
				+ "in the constructor and threading pos through an instance field "
				+ "(mirror the _updateCallback / _updateDt pattern at lines 110-134).");
		}
	}

	// UIDefaultController's full input hot path — handleMove, handleClick (push +
	// release), handleMouseWheel, handleKey — must drive element discovery through
	// the streaming forEachElement API only. Reaching for the allocating
	// getElements() Array + concat shape is the regression this pins against.
	@Test
	public function testUIDefaultControllerHotPathNeverCallsGetElements():Void {
		var integ = new ThrowingGetElementsIntegration();
		integ.elements = [new MockInteractive("a", 0, 0, 100, 100, 0)];
		var ctrl = new UIDefaultController(integ);

		ctrl.handleMove(new Point(50, 50), eventWrapper());
		ctrl.handleClick(new Point(50, 50), 0, false, eventWrapper());
		ctrl.handleClick(new Point(50, 50), 0, true, eventWrapper());
		ctrl.handleMouseWheel(new Point(50, 50), 1.0, eventWrapper());
		ctrl.handleKey(32, false, new Point(50, 50), eventWrapper());
		ctrl.handleKey(32, true, new Point(50, 50), eventWrapper());

		Assert.equals(0, integ.getElementsCallCount,
			"UIDefaultController must not call integration.getElements() on any input "
			+ "handler — production code path must stream via forEachElement to avoid "
			+ "per-event Array allocation. Got " + integ.getElementsCallCount + " calls.");
	}

	// ==================== Cursor ====================

	@Test
	public function testAHoveredElementsCursorFollowsItsState():Void {
		// An element's cursor may change while the mouse stays on it (disabled by a click, a state
		// set from code): the cursor follows on the next move, or the next frame without one.
		var element = new MockCursorInteractive(hxd.Cursor.Button);
		integration.elements = [element];
		final applied:Array<hxd.Cursor> = [];
		final was = hxd.System.setCursor;
		hxd.System.setCursor = c -> applied.push(c);
		inline function last():String
			return applied.length == 0 ? "none" : Std.string(applied[applied.length - 1]);
		try {
			controller.handleMove(new Point(50, 50), eventWrapper());
			Assert.equals("Button", last(), "the element's cursor as the mouse enters it");
			element.cursor = hxd.Cursor.Default;
			controller.handleMove(new Point(51, 50), eventWrapper());
			Assert.equals("Default", last(), "its new cursor on the next move, still over it");
			element.cursor = hxd.Cursor.Move;
			controller.update(0.016);
			Assert.equals("Move", last(), "or on the next frame, the mouse still");
			final count = applied.length;
			controller.handleMove(new Point(52, 50), eventWrapper());
			controller.update(0.016);
			Assert.equals(count, applied.length, "an unchanged cursor is not set again");
		} catch (e:Dynamic) {
			hxd.System.setCursor = was;
			throw e;
		}
		hxd.System.setCursor = was;
	}

	// ==================== A hidden element takes no clicks (hx-multianim request 36) ====================

	@Test
	public function testAHiddenElementPassesTheClickToTheOneUnderIt():Void {
		final hidden = new MockObjectInteractive("hidden");
		final shown = new MockObjectInteractive("shown");
		// the hidden one first, so it would be first under the pointer
		integration.elements = [hidden, shown];
		hidden.object.visible = false;
		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());
		Assert.equals(0, hidden.receivedEvents.length, "a hidden element hears no click");
		Assert.equals(1, shown.receivedEvents.length, "the click is the shown one's");

		// hidden by a parent (an @() arm that is not shown)
		shown.clearReceived();
		hidden.object.visible = true;
		final arm = new h2d.Object();
		arm.addChild(hidden.object);
		arm.visible = false;
		controller.handleMove(new Point(50, 50), eventWrapper());
		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());
		Assert.equals(0, hidden.receivedEvents.length, "under a hidden parent: no move, no click");
		Assert.isTrue(shown.receivedEvents.length >= 2, "the shown one hears both");

		// shown again, it is first again
		shown.clearReceived();
		arm.visible = true;
		controller.handleClick(new Point(50, 50), 0, false, eventWrapper());
		Assert.equals(1, hidden.receivedEvents.length, "shown again, it takes the click");
		Assert.equals(0, shown.receivedEvents.length);
	}

	@Test
	public function testTwoButtonsInOnePlaceTheHiddenOneIsNotTheSource():Void {
		// Deal and Hit at one place, Deal hidden: a click is Hit's (Playing Cards' blackjack screen)
		final screen = new TwoButtonsScreen();
		Assert.isFalse(screen.deal.getObject().visible);
		final ctrl = screen.getController();
		ctrl.handleClick(new Point(260, 110), 0, false, eventWrapper());
		ctrl.handleClick(new Point(260, 110), 0, true, eventWrapper());
		Assert.equals(1, screen.clicks.length, "one click");
		Assert.isTrue(screen.clicks[0] == screen.hit, "from the shown button, Hit");
		screen.deal.getObject().visible = true;
		screen.hit.getObject().visible = false;
		ctrl.handleClick(new Point(260, 110), 0, false, eventWrapper());
		ctrl.handleClick(new Point(260, 110), 0, true, eventWrapper());
		Assert.equals(2, screen.clicks.length);
		Assert.isTrue(screen.clicks[1] == screen.deal, "swapped: from Deal");
	}

	@Test
	public function testIsShownWalksEveryParent():Void {
		final top = new h2d.Object();
		final mid = new h2d.Object(top);
		final leaf = new h2d.Object(mid);
		Assert.isTrue(UIDefaultController.isShown(leaf));
		mid.visible = false;
		Assert.isFalse(UIDefaultController.isShown(leaf), "a hidden parent hides it");
		mid.visible = true;
		top.visible = false;
		Assert.isFalse(UIDefaultController.isShown(leaf), "so does a hidden grandparent");
		Assert.isTrue(UIDefaultController.isShown(null), "no object: as before, shown");
	}
}

/** An element over (0, 0) to (100, 100) with an object of its own, to hide. **/
private class MockObjectInteractive implements UIElement implements StandardUIElementEvents {
	public final name:String;
	public final object = new h2d.Object();
	public var receivedEvents:Array<UIElementEvents> = [];

	public function new(name:String) {
		this.name = name;
	}

	public function getObject():h2d.Object return object;

	public function containsPoint(pos:Point):Bool {
		return pos.x >= 0 && pos.x <= 100 && pos.y >= 0 && pos.y <= 100;
	}

	public function clear():Void {}

	public function onEvent(wrapper:UIElementEventWrapper):Void {
		receivedEvents.push(wrapper.event);
	}

	public function clearReceived():Void {
		receivedEvents = [];
	}
}

/** Deal and Hit, two buttons at one place made by `addButtonWithSingleBuilder`, Deal hidden. **/
private class TwoButtonsScreen extends bh.ui.screens.UIScreen.UIScreenBase {
	public var deal:bh.ui.UIMultiAnimButton.UIStandardMultiAnimButton;
	public var hit:bh.ui.UIMultiAnimButton.UIStandardMultiAnimButton;
	public final clicks:Array<UIElement> = [];

	public function new() {
		super(cast null);
		final builder = bh.test.BuilderTestBase.builderFromSource('
			#button programmable(buttonText:string=Click, status:[normal,hover,pressed]=normal, disabled:bool=false) {
				bitmap(generated(color(60, 24, #444444))): 0, 0
			}
		');
		deal = addButtonWithSingleBuilder(builder, "button", null, "Deal");
		hit = addButtonWithSingleBuilder(builder, "button", null, "Hit");
		for (b in [deal, hit]) {
			addElement(b, DefaultLayer);
			b.getObject().setPosition(248, 100);
		}
		deal.getObject().visible = false;
	}

	public function load():Void {}

	public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {
		if (event.match(UIClick))
			clicks.push(source);
	}
}

/** An element over (0, 0) to (100, 100) with the cursor it is given. **/
private class MockCursorInteractive implements UIElement implements StandardUIElementEvents implements UIElementCursor {
	public var cursor:hxd.Cursor;

	public function new(cursor:hxd.Cursor) {
		this.cursor = cursor;
	}

	public function getObject():h2d.Object return new h2d.Object();

	public function containsPoint(pos:Point):Bool {
		return pos.x >= 0 && pos.x <= 100 && pos.y >= 0 && pos.y <= 100;
	}

	public function clear():Void {}

	public function onEvent(wrapper:UIElementEventWrapper):Void {}

	public function getCursor():hxd.Cursor return cursor;
}
