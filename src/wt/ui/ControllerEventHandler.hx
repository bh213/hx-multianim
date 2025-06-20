package wt.ui;

import wt.ui.screens.ScreenManager;
import wt.ui.controllers.UIController;



@:nullSafety
class ControllerEventHandler {
    
	final screenManager:ScreenManager;
	final scene:h2d.Scene;
	final window:hxd.Window;

	public function new(scene, window, screenManager) {
		this.scene = scene;
		this.window = window;
		this.screenManager = screenManager;
		window.addEventTarget(handleEvents);
	}

	inline function getControllers():Array<UIController> {
		return Lambda.map(screenManager.activeScreenControllers, x->x.getController());
	}



	public function handleEvents(event:hxd.Event):Void {
		

		final mousePoint = new h2d.col.Point(scene.mouseX, scene.mouseY);
		final eventWrapper:EventWrapper = {
			sourceEvent:event,
			mousePoint:mousePoint,
			scene:scene
		}

		for (stage => controller in getControllers()) {
		
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
	}
}
