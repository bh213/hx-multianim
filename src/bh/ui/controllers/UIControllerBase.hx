package bh.ui.controllers;

import bh.ui.UIElement;
// import bh.ui.controllers.UIController.EventWrapper;
import bh.ui.controllers.UIController;
import h2d.col.Point;

private class CaptureEventsImpl implements CaptureEventsControl {
	public var start = false;
	public var stop = false;
	public var target:Null<UIElement>;

	public function new() {}

	public function startCapture() {
		start = true;
	}

	public function stopCapture() {
		stop = true;
	}

	public function reset() {
		start = false;
		stop = false;
	}

	public function toString() {
		return 'start:${start}, stop:${stop}, target:${target}';
	}

	public function isCapturing() {
		return target != null;
	}
}

private class OutsideClickImpl implements OutsideClickControl {
	var trackOutsideClickSubscribers:Array<UIElement> = [];

	public var enabledChanged:Null<Bool> = null;

	public function trackOutsideClick(enabled:Bool) {
		enabledChanged = enabled;
	}

	public function handle(element:UIElement) {
		if (enabledChanged == null)
			return;
		else if (enabledChanged && !trackOutsideClickSubscribers.contains(element))
			trackOutsideClickSubscribers.push(element);
		else if (enabledChanged == false)
			trackOutsideClickSubscribers.remove(element);
		enabledChanged = null;
	}

	public function triggerOutsideEvents(notThisElement:Null<UIElement>) {
		if (notThisElement == null) {
			final ret = trackOutsideClickSubscribers;
			trackOutsideClickSubscribers = [];
			return ret;
		} else if (trackOutsideClickSubscribers.remove(notThisElement)) {
			final ret = trackOutsideClickSubscribers;
			trackOutsideClickSubscribers = [notThisElement];
			return ret;
		} else {
			final ret = trackOutsideClickSubscribers;
			trackOutsideClickSubscribers = [];
			return ret;
		}
	}

	public function new() {}
}

@:nullSafety
private class ControllableImpl implements Controllable {
	public var captureEvents(default, null):CaptureEventsImpl;
	public var outsideClick(default, null):OutsideClickImpl;

	final controller:UIController;

	public function new(controller:UIController) {
		this.controller = controller;
		this.captureEvents = new CaptureEventsImpl();
		this.outsideClick = new OutsideClickImpl();
	}

	public function pushEvent(event:UIScreenEvent, source:UIElement) {
		controller.onScreenEvent(event, source);
	}
}

@:nullSafety
abstract class UIControllerBase implements UIController {
	var currentOver:Null<UIElement> = null;
	final controllable:ControllableImpl;
	final integration:bh.ui.controllers.UIController.UIControllerScreenIntegration;

	public var exitResponse:Null<Dynamic> = null;

	public function new(integration) {
		this.integration = integration;
		this.controllable = new ControllableImpl(this);
	}

	function handleEvent(element:UIElement, event, eventPos:Point) {
		if (element == null)
			return;
		if (Std.isOfType(element, StandardUIElementEvents)) {
			final wrapper:UIElementEventWrapper = {
				event: event,
				eventPos: eventPos,
				control: controllable
			};

			final captureEvents = controllable.captureEvents;
			cast(element, StandardUIElementEvents).onEvent(wrapper);
			// TODO: only call this on mouse click? or have some interface decide if element needs notification or not
			controllable.outsideClick.handle(element);
			if (captureEvents.start == false && captureEvents.stop == false)
				return;
			if (captureEvents.start && captureEvents.target == null)
				captureEvents.target = element;
			if (captureEvents.stop && captureEvents.target != null)
				captureEvents.target = null;
			// else throw 'invalid drag state ${captureEvents}';
			captureEvents.reset();
		} else
			throw 'unsupported onEvent ${element}';
	}

	public function handleClick(mousePoint:Point, button:Int, release:Bool, eventWrapper:EventWrapper) {
		final element = getEventElement(mousePoint);
		if (integration.onMouseClick(mousePoint, button, release) == false) return;
		final triggeredElements = controllable.outsideClick.triggerOutsideEvents(element);
		for (value in triggeredElements) {
			handleEvent(value, release ? OnReleaseOutside(button) : OnPushOutside(button), mousePoint);
		}
		if (element == null)
			return;
		handleEvent(element, release ? OnRelease(button) : OnPush(button), mousePoint);
	}

	public function handleMouseWheel(mousePoint:Point, wheelDelta:Float, eventWrapper:EventWrapper) {
		if (integration.onMouseWheel(mousePoint, wheelDelta) == false) return;
		final element = getEventElement(mousePoint);
		if (element == null)
			return;
		handleEvent(element, OnWheel(wheelDelta), mousePoint);
	}

	abstract function getEventElement(pos:Point):Null<UIElement>;

	public function handleMove(mousePoint:Point, eventWrapper:EventWrapper) {
		if (integration.onMouseMove(mousePoint) == false) return;
		final element = getEventElement(mousePoint);

		if (element != null)
			handleEvent(element, OnMouseMove, mousePoint);
		if (element == currentOver)
			return;
		else if (element == null && currentOver != null) {
			handleEvent(currentOver, OnLeave, mousePoint);
			currentOver = null;
		} else if (element != null) {
			if (currentOver != null) {
				handleEvent(currentOver, OnLeave, mousePoint);
			}
			handleEvent(element, OnEnter, mousePoint);
			currentOver = element;
		}
	}

	function redrawAndUpdate(element:UIElement, dt:Float) {
		if (Std.isOfType(element, UIElementUpdatable)) {
			(cast(element, UIElementUpdatable)).update(dt);
		}
		if (Std.isOfType(element, UIElementSyncRedraw)) {
			final redrawable = (cast(element, UIElementSyncRedraw));
			if (redrawable.requestRedraw)
				redrawable.doRedraw();
		}
	}

	public function update(dt:Float) {
		for (element in integration.getElements(SETReceiveUpdates)) {
			redrawAndUpdate(element, dt);
		}

		if (exitResponse != null) {
			final retVal = exitResponse;
			exitResponse = null;
			return UIControllerFinished(retVal);
		}
		return UIControllerRunning;
	}

	public function lifecycleEvent(event:UIControllerLifecycleEvent) {
		switch event {
			case LifecycleControllerStarted:
			case LifecycleControllerFinished:
		}
	}

	public function handleKey(keyCode:Int, release:Bool, mousePoint:Point, eventWrapper:EventWrapper) {
		if (integration.onKey(keyCode, release) == false) return;
		final element = getEventElement(mousePoint);
		onScreenEvent(UIKeyPress(keyCode, release), null);
		if (element == null)
			return;
		handleEvent(element, OnKey(keyCode, release), mousePoint);
	}

	public function otherEvent(sourceEvent:EventWrapper) {}

	public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {
		// trace('user event ${event} from ${source}');
		integration.onScreenEvent(event, source);
	}
}
