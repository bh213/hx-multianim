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

@:nullSafety
private class ControllableImpl implements Controllable {
	public var captureEvents(default, null):CaptureEventsImpl;

	final controller:UIController;

	// Outside-click subscriber tracking (inlined from former OutsideClickImpl)
	var subscribers:Array<UIElement> = [];
	// Set by controller before dispatching onEvent, cleared after.
	var currentElement:Null<UIElement> = null;

	public function new(controller:UIController) {
		this.controller = controller;
		this.captureEvents = new CaptureEventsImpl();
	}

	public function trackOutsideClick(enabled:Bool) {
		if (currentElement == null)
			return;
		if (enabled && !subscribers.contains(currentElement))
			subscribers.push(currentElement);
		else if (!enabled)
			subscribers.remove(currentElement);
	}

	public function setContext(element:UIElement) {
		currentElement = element;
	}

	public function clearContext() {
		currentElement = null;
	}

	public function triggerOutsideEvents(notThisElement:Null<UIElement>) {
		if (notThisElement == null) {
			final ret = subscribers;
			subscribers = [];
			return ret;
		} else if (subscribers.remove(notThisElement)) {
			final ret = subscribers;
			subscribers = [notThisElement];
			return ret;
		} else {
			final ret = subscribers;
			subscribers = [];
			return ret;
		}
	}

	public function pushEvent(event:UIScreenEvent, source:UIElement) {
		controller.onScreenEvent(event, source);
	}
}

@:nullSafety
class UIDefaultController implements UIController {
	var currentOver:Null<UIElement> = null;
	final controllable:ControllableImpl;
	final integration:bh.ui.controllers.UIController.UIControllerScreenIntegration;

	public var exitResponse:Null<Dynamic> = null;

	public function new(integration) {
		this.integration = integration;
		this.controllable = new ControllableImpl(this);
	}

	public function getDebugName():String {
		return "default UI controller";
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
			// Set context so trackOutsideClick() knows which element is calling
			switch (event) {
				case OnPush(_), OnRelease(_), OnReleaseOutside(_):
					controllable.setContext(element);
				default:
			}
			cast(element, StandardUIElementEvents).onEvent(wrapper);
			controllable.clearContext();
			if (captureEvents.start == false && captureEvents.stop == false)
				return;
			if (captureEvents.start && captureEvents.target == null)
				captureEvents.target = element;
			if (captureEvents.stop && captureEvents.target != null)
				captureEvents.target = null;
			// else throw 'invalid drag state ${captureEvents}';
			captureEvents.reset();
		}
	}

	public function handleClick(mousePoint:Point, button:Int, release:Bool, eventWrapper:EventWrapper) {
		final element = getEventElement(mousePoint);
		if (integration.onMouseClick(mousePoint, button, release) == false) return;
		if (release) {
			final triggeredElements = controllable.triggerOutsideEvents(element);
			for (value in triggeredElements) {
				handleEvent(value, OnReleaseOutside(button), mousePoint);
			}
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

	function getEventElement(pos:Point):Null<UIElement> {
		if (controllable.captureEvents.target != null)
			return controllable.captureEvents.target;
		for (element in integration.getElements(SETReceiveEvents)) {
			if (element.containsPoint(pos))
				return element;
		}
		return null;
	}

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
		updateCursor();
	}

	function updateCursor() {
		if (currentOver != null && Std.isOfType(currentOver, UIElementCursor)) {
			hxd.System.setCursor((cast(currentOver, UIElementCursor)).getCursor());
		} else {
			hxd.System.setCursor(bh.base.CursorManager.getDefaultCursor());
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

	public function clearState() {
		currentOver = null;
		controllable.captureEvents.target = null;
		controllable.captureEvents.reset();
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
		integration.dispatchScreenEvent(event, source);
	}
}
