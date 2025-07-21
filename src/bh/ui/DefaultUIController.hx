package bh.ui;

import bh.ui.UIElement;
import h2d.col.Point;

@:nullSafety
class DefaultUIController extends bh.ui.controllers.UIControllerBase {
	public function new(integration) {
		super(integration);
	}

	public function getDebugName():String {
		return "default UI controller";
	}

	function getEventElement(pos):Null<UIElement> {
		if (controllable.captureEvents.target != null)
			return controllable.captureEvents.target;
		for (element in integration.getElements(SETReceiveEvents)) {
			if (element.containsPoint(pos))
				return element;
		}
		return null;
	}
}
