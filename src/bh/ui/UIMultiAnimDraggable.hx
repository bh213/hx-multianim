package bh.ui;

import bh.base.MAObject;
import h2d.Object;
import h2d.col.Point;
import h2d.col.Bounds;
import bh.ui.UIElement;

/**
 * Delegate function type for checking if drag start is allowed.
 * Returns true if dragging should be allowed to start.
 */
typedef DragStartDelegate = (pos:Point, wrapper:UIElementEventWrapper) -> Bool;

/**
 * Delegate function type for checking if a destination is valid for dropping.
 * Returns true if the object can be dropped at the given position.
 */
typedef DragDestinationDelegate = (pos:Point, wrapper:UIElementEventWrapper) -> Bool;

/**
 * Delegate function type for handling drag events.
 * Called when dragging starts, moves, or ends.
 */
typedef DragEventDelegate = (event:DragEvent, pos:Point, wrapper:UIElementEventWrapper) -> Void;

/**
 * Enum representing different drag events.
 */
enum DragEvent {
	DragStart;
	DragMove;
	DragEnd;
	DragCancel;
}

/**
 * A draggable wrapper for h2d objects that provides drag functionality
 * with delegate callbacks for validation and event handling.
 */
class UIMultiAnimDraggable implements UIElement implements StandardUIElementEvents {
	var root:h2d.Object;
	var target:h2d.Object;
	var isDragging:Bool = false;
	var dragOffset:Point;

	var draggableButtons:Array<Int> = [0];
	var draggingButtton:Int = -1;

	// Delegate callbacks
	public var onDragStart:Null<DragStartDelegate> = null;
	public var onDragDestination:Null<DragDestinationDelegate> = null;
	public var onDragEvent:Null<DragEventDelegate> = null;

	// Configuration
	public var enabled:Bool = true;

	public function new(target:h2d.Object) {
		this.target = target;
		var bounds = target.getBounds();
		this.root = new MAObject(MADraggable(Math.ceil(bounds.width), Math.ceil(bounds.height)), false);
		this.root.addChild(target);
	}

	/**
	 * Creates a new UIMultiAnimDraggable instance.
	 */
	public static function create(target:h2d.Object):UIMultiAnimDraggable {
		return new UIMultiAnimDraggable(target);
	}

	public function getObject():Object {
		return root;
	}

	public function containsPoint(pos:Point):Bool {
		trace('Draggable containsPoint: ${pos.x}, ${pos.y}, ${root.getBounds().width} ${target.getBounds().width}');
		return root.getBounds().contains(pos);
		
	}

	public function clear() {
		if (target != null) {
			target.remove();
			target = null;
		}
	}

	public function onEvent(wrapper:UIElementEventWrapper) {
		if (!enabled)
			return;

		//trace('Draggable received event: ${wrapper.event} at ${wrapper.eventPos.x}, ${wrapper.eventPos.y}');

		switch wrapper.event {
			case OnPush(button):
				if (draggableButtons.contains(button)) { // Left mouse button only
					if (onDragStart != null && !onDragStart(wrapper.eventPos, wrapper)) {
						return;
					}

					draggingButtton = button;

					isDragging = true;
					dragOffset = new Point(target.x - wrapper.eventPos.x, target.y - wrapper.eventPos.y);
					wrapper.control.captureEvents.startCapture();
				}

			case OnRelease(button):
				if (button == draggingButtton && isDragging) {
					if (!isDragging)
						return;

					// Stop dragging
					isDragging = false;
					draggingButtton = -1;

					if (onDragEvent != null) {
						onDragEvent(DragEnd, wrapper.eventPos, wrapper);
					}

					// Notify the controller that we're stopping drag
					wrapper.control.captureEvents.stopCapture();
				}

			case OnKey(keyCode, release):
				// Optional: could handle keyboard shortcuts

			case OnMouseMove:
				if (isDragging) {
					var newPos = new Point(wrapper.eventPos.x + dragOffset.x, wrapper.eventPos.y + dragOffset.y);
					if (onDragDestination != null && !onDragDestination(newPos, wrapper)) {
						return;
					}

					target.setPosition(newPos.x, newPos.y);
				}
			default:
		}
	}

	public function isCurrentlyDragging():Bool {
		return isDragging;
	}

	public function getTarget():Object {
		return target;
	}
}
