package bh.ui;

import bh.ui.screens.ScreenManager;
import bh.ui.controllers.UIController;

@:nullSafety
class ControllerEventHandler {
	final screenManager:ScreenManager;
	final scene:h2d.Scene;
	final window:hxd.Window;

	#if MULTIANIM_ALLOC_TRACK
	// Allocation watchdog for tests. Gated behind MULTIANIM_ALLOC_TRACK so the increment vanishes
	// from production builds; every input event, each mouse move included, comes through here.
	public static var controllerListCount:Int = 0;
	#end

	// The controllers as the event found them (a handler may switch screens), the one list reused
	// from event to event. Null while in use, so an event raised during another makes its own.
	var controllerList:Null<Array<UIController>> = [];

	public function new(scene, window, screenManager) {
		this.scene = scene;
		this.window = window;
		this.screenManager = screenManager;
		window.addEventTarget(handleEvents);
	}

	/** Stops hearing the window's input (the window matches the method by `Reflect.compareMethods`). */
	public function dispose():Void {
		window.removeEventTarget(handleEvents);
	}

	static function newControllerList():Array<UIController> {
		#if MULTIANIM_ALLOC_TRACK
		controllerListCount++;
		#end
		return [];
	}

	/** A press, move or release by a finger: the mouse did not move for it, so only the event says where it is. */
	static function isFingerOnScreen(event:hxd.Event):Bool {
		return switch event.kind {
			case EPush | ERelease | EMove: PointerEvent.isTouch(event);
			default: false;
		}
	}

	/**
		The event's own place in the scene, worked out as `Scene.mouseX`/`mouseY` work out the mouse's.
		Not by `Camera.eventToCamera`, which writes it into the event: Heaps' own scene events read
		this same event later and do that themselves.
	**/
	function scenePointOf(event:hxd.Event):h2d.col.Point {
		return @:privateAccess {
			scene.syncPos();
			final camera = scene.interactiveCamera;
			final dx = camera.screenXToCamera(event.relX, event.relY) - scene.absX;
			final dy = camera.screenYToCamera(event.relX, event.relY) - scene.absY;
			final det = scene.matA * scene.matD - scene.matB * scene.matC;
			new h2d.col.Point((dx * scene.matD - dy * scene.matC) / det, (dy * scene.matA - dx * scene.matB) / det);
		}
	}

	public function handleEvents(event:hxd.Event):Void {
		final mousePoint = isFingerOnScreen(event) ? scenePointOf(event) : new h2d.col.Point(scene.mouseX, scene.mouseY);
		final eventWrapper:EventWrapper = {
			sourceEvent: event,
			mousePoint: mousePoint,
			scene: scene
		}

		final controllers:Array<UIController> = controllerList ?? newControllerList();
		controllerList = null;
		for (screen in screenManager.activeScreenControllers)
			controllers.push(screen.getController());

		for (controller in controllers) {
			switch event.kind {
				case EPush:
					controller.handleClick(mousePoint, event.button, false, eventWrapper);
				case ERelease:
					controller.handleClick(mousePoint, event.button, true, eventWrapper);
				case EMove:
					controller.handleMove(mousePoint, eventWrapper);
				case EKeyDown:
					controller.handleKey(event.keyCode, false, mousePoint, eventWrapper);
				case EKeyUp:
					controller.handleKey(event.keyCode, true, mousePoint, eventWrapper);
				case EWheel:
					controller.handleMouseWheel(mousePoint, event.wheelDelta, eventWrapper);
				default:
					controller.otherEvent(eventWrapper);
			}
		}

		controllers.resize(0);
		controllerList = controllers;
	}
}
