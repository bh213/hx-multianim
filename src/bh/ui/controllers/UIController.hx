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
	function getElements(type:SubElementsType):Array<UIElement>;
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

typedef EventWrapper = {
	var sourceEvent:hxd.Event;
	var mousePoint:h2d.col.Point;
	var scene:h2d.Scene;
}


