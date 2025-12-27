package bh.ui.controllers;

import bh.ui.screens.ScreenManager;
import bh.ui.UIElement;
import h2d.col.Point;
import h2d.Object;
import h2d.col.Bounds;

enum UIControllerLifecycleEvent {
	LifecycleControllerStarted;
	LifecycleControllerFinished;
	
}

enum UIControllerResult {
	UIControllerRunning;
	UIControllerFinished(result:Dynamic);
}

interface UIControllerScreenIntegration {
	function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void;
	function getElements(type:SubElementsType):Array<UIElement>;
	function onMouseMove(pos:Point):Void;
	function onMouseWheel(delta:Float):Void;
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
	function onScreenEvent(event:UIScreenEvent, source:UIElement):Void;
	
}

typedef EventWrapper = {
	var sourceEvent:hxd.Event;
	var mousePoint:h2d.col.Point;
	var scene:h2d.Scene;
}


