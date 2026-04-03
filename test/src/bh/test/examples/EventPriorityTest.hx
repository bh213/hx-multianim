package bh.test.examples;

import utest.Assert;
import h2d.col.Point;
import bh.ui.UIElement;
import bh.ui.controllers.UIController;
import bh.ui.controllers.UIDefaultController;

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
 * Mock UIControllerScreenIntegration for testing UIDefaultController in isolation.
 */
private class MockIntegration implements UIControllerScreenIntegration {
	public var elements:Array<UIElement> = [];
	public var dispatchedEvents:Array<UIScreenEvent> = [];

	public function new() {}

	public function dispatchScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {
		dispatchedEvents.push(event);
	}

	public function getElements(type:SubElementsType):Array<UIElement> {
		return elements;
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

	static function eventWrapper():EventWrapper {
		return {
			sourceEvent: new hxd.Event(hxd.Event.EventKind.EPush),
			mousePoint: new Point(0, 0),
			scene: null
		};
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
}
