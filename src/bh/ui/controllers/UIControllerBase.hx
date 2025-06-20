package bh.ui.controllers;

import bh.ui.UIElement;
//import bh.ui.controllers.UIController.EventWrapper;
import bh.ui.controllers.UIController;
import h2d.col.Point;


private class DraggableImpl implements DraggableControl {
    public var start = false;
	public var stop = false;
	public var target:Null<UIElement>;
    public function new() {}
	public function startDrag() {start = true;}
	public function stopDrag() {stop = true; }
	public function reset() {start = false; stop = false;}
    public function toString() {
        return 'start:${start}, stop:${stop}, target:${target}';
    }
	public function isDragging() {return target != null;}
}

private class OutsideClickImpl implements OutsideClickControl {

    var trackOutsideClickSubscribers:Array<UIElement> = [];
    public var enabledChanged:Null<Bool> = null;
    public function trackOutsideClick(enabled:Bool) {
        enabledChanged = enabled;
    }

    public function handle(element:UIElement) {
        if (enabledChanged == null) return;
        else if (enabledChanged && !trackOutsideClickSubscribers.contains(element)) trackOutsideClickSubscribers.push(element);
        else if (enabledChanged == false) trackOutsideClickSubscribers.remove(element);
        enabledChanged = null;
    }

    public function getTriggered(notThisElement:Null<UIElement>) {
        if (notThisElement == null) {
            final ret = trackOutsideClickSubscribers;
            trackOutsideClickSubscribers = [];
            return ret;
        }
        else if (trackOutsideClickSubscribers.remove(notThisElement)) {
            final ret = trackOutsideClickSubscribers;
            trackOutsideClickSubscribers = [notThisElement];
            return ret;
        } else 
        {
            final ret = trackOutsideClickSubscribers;
            trackOutsideClickSubscribers = [];
            return ret;
        }
    }

    public function new() {
    }

}


@:nullSafety
private class ControllableImpl implements Controllable {
    public var draggable(default, null):DraggableImpl;
    public var outsideClick(default, null):OutsideClickImpl;
    final controller:UIController;
    public function new(controller:UIController) {
        this.controller = controller;
        this.draggable = new DraggableImpl();
        this.outsideClick = new OutsideClickImpl();
    }

	public function pushEvent(event:UIScreenEvent, source:UIElement) {
        controller.onScreenEvent(event, source);
    }
}

@:nullSafety
abstract class UIControllerBase implements UIController  {
    
    var currentOver:Null<UIElement> = null;
    final controllable:ControllableImpl;
    final integration:bh.ui.controllers.UIController.UIControllerScreenIntegration;
    public var exitResponse:Null<Dynamic> = null;
    
    public function new(integration) {
        this.integration = integration;
        this.controllable = new ControllableImpl(this);
    }

    function handleEvent(element:UIElement, event, eventPos:Point, eventWrapper:EventWrapper) {
        if (element == null) return;
        if (Std.isOfType(element, StandardUIElementEvents)) {
            final wrapper:UIElementEventWrapper = {
                event: event,
                eventPos: eventPos,
                control:controllable
            };
            final draggable = controllable.draggable;
            cast (element, StandardUIElementEvents).onEvent(wrapper);
            controllable.outsideClick.handle(element);
            if (draggable.start == false && draggable.stop == false) return;
            if (draggable.start && draggable.target == null) draggable.target = element;
            else if (draggable.stop && draggable.target != null) draggable.target = null;
            else throw 'invalid drag state ${draggable}';
            draggable.reset();

        }
        else throw 'unsupported onEvent ${element}';
    }

	public function handleClick(mousePoint:Point, button:Int, release:Bool, eventWrapper:EventWrapper) {
        final element = getEventElement(mousePoint);

        final triggered = controllable.outsideClick.getTriggered(element);
        for (value in triggered) {
            handleEvent(value, release ? OnReleaseOutside(button) : OnPushOutside(button), mousePoint, eventWrapper);    
        }
        if (element == null) return;
        handleEvent(element, release ? OnRelease(button) : OnPush(button), mousePoint, eventWrapper);
    }

    public function handleMouseWheel(mousePoint:Point, wheelDelta:Float, eventWrapper:EventWrapper) {
        final element = getEventElement(mousePoint);
        if (element == null) return;
        handleEvent(element, OnWheel(wheelDelta), mousePoint, eventWrapper);
    }

    abstract function getEventElement(pos:Point):Null<UIElement>;

	public function handleMove(mousePoint:Point, eventWrapper:EventWrapper) {
        integration.onMouseMove(mousePoint);
        final element = getEventElement(mousePoint);
        
        if (element != null) handleEvent(element, OnMouseMove, mousePoint, eventWrapper);
        if (element == currentOver) return;
        else if (element == null && currentOver != null) {
            handleEvent(currentOver, OnLeave, mousePoint, eventWrapper);
            currentOver = null;
        } else if (element != null) {
            if (currentOver != null) {
                handleEvent(currentOver, OnLeave, mousePoint, eventWrapper);
            }
            handleEvent(element, OnEnter, mousePoint, eventWrapper);
            currentOver = element;
		}
    }

    function redrawAndUpdate(element:UIElement, dt:Float) {
        if (Std.isOfType(element, UIElementUpdatable)) {
            (cast (element, UIElementUpdatable)).update(dt);
        }
        if (Std.isOfType(element, UIElementSyncRedraw)) {
            final redrawable = (cast (element, UIElementSyncRedraw));
            if (redrawable.requestRedraw) redrawable.doRedraw();
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
        final element = getEventElement(mousePoint);
        onScreenEvent(UIKeyPress(keyCode, release), null);
        if (element == null) return;
        handleEvent(element, OnKey(keyCode, release), mousePoint, eventWrapper);
    }

	public function otherEvent(sourceEvent:EventWrapper) {}

	public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {
		//trace('user event ${event} from ${source}');
        integration.onScreenEvent(event, source);
	}

}
	
