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
	#if MULTIANIM_ALLOC_TRACK
	// Allocation watchdog for tests. Gated behind MULTIANIM_ALLOC_TRACK so the
	// per-construction increment vanishes from production builds; getEventElements
	// fires on every mouse move / click / wheel / key, so its scratch must not
	// reallocate per call.
	public static var hitsCreationCount:Int = 0;
	#end

	var currentOver:Null<UIElement> = null;
	final controllable:ControllableImpl;
	final integration:bh.ui.controllers.UIController.UIControllerScreenIntegration;

	public var exitResponse:Null<Dynamic> = null;

	// State threaded into the cached update callback so update() doesn't
	// allocate a fresh closure per frame on HL. The callback below reads
	// _updateDt and forwards to redrawAndUpdate.
	var _updateDt:Float = 0;
	final _updateCallback:UIElement->Void;

	// Scratch buffer reused across getEventElements calls — avoids per-event
	// Array allocation on every mouse move/click/wheel/key.
	final _hits:Array<UIElement> = [];

	// Stable sort comparator: higher eventPriority first, registration order as
	// tiebreaker. Hoisted to a static field so it's allocated once per program
	// rather than per getEventElements call.
	static final _priorityComparator:(UIElement, UIElement) -> Int = (a, b) -> {
		final pa = Std.isOfType(a, UIElementPriority) ? (cast(a, UIElementPriority)).eventPriority : 0;
		final pb = Std.isOfType(b, UIElementPriority) ? (cast(b, UIElementPriority)).eventPriority : 0;
		return pb - pa;
	};

	public function new(integration) {
		this.integration = integration;
		// Initialise _updateCallback before passing `this` to ControllableImpl —
		// null-safety requires all final fields assigned before `this` leaks.
		// The closure body runs later (every frame), so the analyzer's
		// "this not fully initialised" complaint is a false positive here.
		this._updateCallback = function(element:UIElement):Void {
			@:nullSafety(Off) redrawAndUpdate(element, _updateDt);
		};
		this.controllable = new ControllableImpl(this);
		#if MULTIANIM_ALLOC_TRACK
		hitsCreationCount++;
		#end
	}

	public function getDebugName():String {
		return "default UI controller";
	}

	/** Returns true if the event was consumed (default), false if it should bubble. */
	function handleEvent(element:UIElement, event, eventPos:Point):Bool {
		if (element == null)
			return false;
		if (Std.isOfType(element, StandardUIElementEvents)) {
			final wrapper:UIElementEventWrapper = {
				event: event,
				eventPos: eventPos,
				control: controllable,
				consumed: true
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
				return wrapper.consumed;
			if (captureEvents.start && captureEvents.target == null)
				captureEvents.target = element;
			if (captureEvents.stop && captureEvents.target != null)
				captureEvents.target = null;
			// else throw 'invalid drag state ${captureEvents}';
			captureEvents.reset();
			return wrapper.consumed;
		}
		return false;
	}

	public function handleClick(mousePoint:Point, button:Int, release:Bool, eventWrapper:EventWrapper) {
		final elements = getEventElements(mousePoint);
		final topElement = elements.length > 0 ? elements[0] : null;
		if (integration.dispatchMouseClick(mousePoint, button, release) == false) {
			// Consumed by a component (e.g. card hand drag release).
			// Still process outside-click so panels/dropdowns close correctly.
			if (release) {
				final triggeredElements = controllable.triggerOutsideEvents(topElement);
				for (value in triggeredElements)
					handleEvent(value, OnReleaseOutside(button), mousePoint);
			}
			return;
		}
		if (release) {
			final triggeredElements = controllable.triggerOutsideEvents(topElement);
			for (value in triggeredElements) {
				handleEvent(value, OnReleaseOutside(button), mousePoint);
			}
		}
		for (element in elements) {
			if (handleEvent(element, release ? OnRelease(button) : OnPush(button), mousePoint))
				break;
		}
	}

	public function handleMouseWheel(mousePoint:Point, wheelDelta:Float, eventWrapper:EventWrapper) {
		if (integration.onMouseWheel(mousePoint, wheelDelta) == false) return;
		for (element in getEventElements(mousePoint)) {
			if (handleEvent(element, OnWheel(wheelDelta), mousePoint))
				break;
		}
	}

	function getEventElements(pos:Point):Array<UIElement> {
		_hits.resize(0);
		if (controllable.captureEvents.target != null) {
			_hits.push(controllable.captureEvents.target);
			return _hits;
		}
		integration.forEachElement(SETReceiveEvents, function(element:UIElement):Void {
			if (element.containsPoint(pos))
				_hits.push(element);
		});
		if (_hits.length > 1) {
			haxe.ds.ArraySort.sort(_hits, _priorityComparator);
		}
		return _hits;
	}

	public function handleMove(mousePoint:Point, eventWrapper:EventWrapper) {
		if (integration.dispatchMouseMove(mousePoint) == false) return;
		final elements = getEventElements(mousePoint);
		final element = elements.length > 0 ? elements[0] : null;

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
		_updateDt = dt;
		integration.forEachElement(SETReceiveUpdates, _updateCallback);

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
		final elements = getEventElements(mousePoint);
		onScreenEvent(UIKeyPress(keyCode, release), null);
		for (element in elements) {
			if (handleEvent(element, OnKey(keyCode, release), mousePoint))
				break;
		}
	}

	public function otherEvent(sourceEvent:EventWrapper) {}

	public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {
		// trace('user event ${event} from ${source}');
		integration.dispatchScreenEvent(event, source);
	}
}
