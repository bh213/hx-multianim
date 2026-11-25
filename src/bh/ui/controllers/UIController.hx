package bh.ui.controllers;

import bh.ui.UIElement;
import h2d.col.Point;

enum UIControllerLifecycleEvent {
	LifecycleControllerStarted;
	LifecycleControllerFinished;
	
}

enum UIControllerResult {
	UIControllerRunning;
	UIControllerFinished(result:Dynamic);
}

interface UIControllerScreenIntegration {
	/** Dispatch event with auto-wiring (autoStatus) handled before screen's onScreenEvent. */
	function dispatchScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void;
	function forEachElement(type:SubElementsType, fn:UIElement->Void):Void;
	function onKey(keyCode:Int, release:Bool):Bool;
	/** Dispatch mouse move to higher-order components and screen override.
	 *  Always returns true — components are notified but never block interactive processing. */
	function dispatchMouseMove(pos:Point):Bool;
	function onMouseWheel(pos:Point, delta:Float):Bool;
	/** Dispatch mouse click/release to higher-order components.
	 *  Returns false only when a release is consumed (e.g. card hand drag end). */
	function dispatchMouseClick(pos:Point, button:Int, release:Bool):Bool;
}

@:allow(bh.ui.screens.UIScreenBase)
@:allow(bh.ui.screens.ScreenManager)
interface UIController {
	var exitResponse(default, null):Null<Dynamic>;
	function handleClick(mousePos:Point, button:Int, release:Bool, eventWrapper:EventWrapper):Void;
	function handleKey(keyCode:Int, release:Bool, mousePoint:Point, eventWrapper:EventWrapper):Void;
	function handleMouseWheel(mousePoint:Point, wheelDelta:Float, eventWrapper:EventWrapper):Void;
	function handleMove(mousePos:Point, sourceEvent:EventWrapper):Void;
	function otherEvent(sourceEvent:EventWrapper):Void;
	function getDebugName():String;
	function update(dt:Float):UIControllerResult;
	function lifecycleEvent(event:UIControllerLifecycleEvent):Void;
	function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void;
	function clearState():Void;
}

class PointerEvent {
	/**
		Whether a finger made this event. Heaps sets `touchId` on a touch alone, but a mouse event's
		is undefined on JS and 0 on HashLink, where the first finger may be 0 too: there every pointer
		event of a touch platform is a finger's (Heaps sends no mouse events on one).
	**/
	public static function isTouch(event:hxd.Event):Bool {
		#if js
		final id:Null<Int> = event.touchId;
		return id != null;
		#else
		return event.touchId != 0 || hxd.System.getValue(IsTouch);
		#end
	}
}

typedef EventWrapper = {
	var sourceEvent:hxd.Event;
	var mousePoint:h2d.col.Point;
	var scene:h2d.Scene;
}


