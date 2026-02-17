package bh.ui;

import bh.base.FPoint;
import bh.base.MAObject;
import bh.multianim.MultiAnimBuilder.SlotHandle;
import bh.paths.AnimatedPath;
import bh.paths.AnimatedPath.AnimatedPathMode;
import bh.paths.MultiAnimPaths.Path;
import h2d.Object;
import h2d.col.Bounds;
import h2d.col.Point;
import bh.ui.UIElement;

/**
 * Delegate function type for checking if drag start is allowed.
 * Returns true if dragging should be allowed to start.
 */
typedef DragStartDelegate = (pos:Point, wrapper:UIElementEventWrapper) -> Bool;

/**
 * Delegate function type for validating a drop.
 * Receives the drop result (which zone, if any) and the position.
 * Returns true if the drop should be accepted.
 */
typedef DragDropDelegate = (result:DragDropResult, wrapper:UIElementEventWrapper) -> Bool;

/**
 * Delegate function type for handling drag events.
 * Called when dragging starts, moves, or ends.
 */
typedef DragEventDelegate = (event:DragEvent, pos:Point, wrapper:UIElementEventWrapper) -> Void;

/**
 * Factory function type for creating an AnimatedPath between two points.
 * Used to create return (failed drop) and snap (successful drop) animations.
 */
typedef AnimatedPathFactory = (from:FPoint, to:FPoint) -> AnimatedPath;

enum DragEvent {
	DragStart;
	DragMove;
	DragEnd;
	DragCancel;
}

@:structInit
class DropZone {
	public var id:String;
	public var bounds:Bounds;
	public var slot:Null<SlotHandle> = null;
	public var snapX:Null<Float> = null;
	public var snapY:Null<Float> = null;
	public var accepts:Null<(draggable:UIMultiAnimDraggable) -> Bool> = null;
}

@:structInit
class DragDropResult {
	public var zone:Null<DropZone>;
	public var pos:Point;
}

enum DraggableState {
	Idle;
	Dragging;
	Animating;
}

/**
 * A draggable wrapper for h2d objects that provides drag-and-drop functionality
 * with drop zones, slot integration, and path-based animations for
 * successful snaps and failed-drop returns.
 */
class UIMultiAnimDraggable implements UIElement implements StandardUIElementEvents implements UIElementUpdatable {
	var root:h2d.Object;
	var target:h2d.Object;
	var dragOffset:Point;

	var draggableButtons:Array<Int> = [0];
	var draggingButton:Int = -1;

	var state:DraggableState = Idle;
	var originX:Float = 0.;
	var originY:Float = 0.;
	var activeAnim:Null<AnimatedPath> = null;
	var animOnComplete:Null<() -> Void> = null;

	// Delegate callbacks
	public var onDragStart:Null<DragStartDelegate> = null;
	public var onDragDrop:Null<DragDropDelegate> = null;
	public var onDragEvent:Null<DragEventDelegate> = null;

	// Path factories for animations (null = instant teleport)
	public var returnPathFactory:Null<AnimatedPathFactory> = null;
	public var snapPathFactory:Null<AnimatedPathFactory> = null;

	// Drop zones
	public var dropZones:Array<DropZone> = [];

	// Configuration
	public var enabled:Bool = true;

	public function new(target:h2d.Object) {
		this.target = target;
		var bounds = target.getBounds();
		this.root = new MAObject(MADraggable(Math.ceil(bounds.width), Math.ceil(bounds.height)), false);
		this.root.addChild(target);
	}

	public static function create(target:h2d.Object):UIMultiAnimDraggable {
		return new UIMultiAnimDraggable(target);
	}

	// --- Drop zone management ---

	public function addDropZone(zone:DropZone):UIMultiAnimDraggable {
		dropZones.push(zone);
		return this;
	}

	public function addDropZoneFromSlot(id:String, slot:SlotHandle, ?accepts:(draggable:UIMultiAnimDraggable) -> Bool):UIMultiAnimDraggable {
		var b = slot.container.getBounds();
		var absPos = slot.container.localToGlobal(new Point(0, 0));
		dropZones.push({
			id: id,
			bounds: b,
			slot: slot,
			snapX: absPos.x,
			snapY: absPos.y,
			accepts: accepts
		});
		return this;
	}

	public function removeDropZone(id:String):Void {
		dropZones = dropZones.filter(z -> z.id != id);
	}

	public function clearDropZones():Void {
		dropZones = [];
	}

	function findDropZone(pos:Point):Null<DropZone> {
		for (zone in dropZones) {
			if (zone.bounds.contains(pos)) {
				if (zone.accepts == null || zone.accepts(this))
					return zone;
			}
		}
		return null;
	}

	// --- AnimatedPath helpers ---

	function startAnimation(fromX:Float, fromY:Float, toX:Float, toY:Float, factory:Null<AnimatedPathFactory>, onComplete:() -> Void):Void {
		if (factory == null) {
			onComplete();
			return;
		}

		var from = new FPoint(fromX, fromY);
		var to = new FPoint(toX, toY);

		// Don't animate zero-distance
		if (Math.abs(toX - fromX) < 0.5 && Math.abs(toY - fromY) < 0.5) {
			onComplete();
			return;
		}

		activeAnim = factory(from, to);
		animOnComplete = onComplete;
		state = Animating;
	}

	// --- UIElementUpdatable ---

	public function update(dt:Float):Void {
		if (state != Animating || activeAnim == null)
			return;

		var s = activeAnim.update(dt);
		target.setPosition(s.position.x, s.position.y);

		if (s.done) {
			var cb = animOnComplete;
			activeAnim = null;
			animOnComplete = null;
			state = Idle;
			if (cb != null)
				cb();
		}
	}

	// --- UIElement ---

	public function getObject():Object {
		return root;
	}

	public function containsPoint(pos:Point):Bool {
		return root.getBounds().contains(pos);
	}

	public function clear() {
		activeAnim = null;
		animOnComplete = null;
		state = Idle;
		if (target != null) {
			target.remove();
			target = null;
		}
	}

	// --- StandardUIElementEvents ---

	public function onEvent(wrapper:UIElementEventWrapper) {
		if (!enabled)
			return;
		if (state == Animating)
			return;

		switch wrapper.event {
			case OnPush(button):
				if (draggableButtons.contains(button)) {
					if (onDragStart != null && !onDragStart(wrapper.eventPos, wrapper)) {
						return;
					}

					draggingButton = button;
					state = Dragging;

					// Remember origin for return animation
					originX = target.x;
					originY = target.y;

					dragOffset = new Point(target.x - wrapper.eventPos.x, target.y - wrapper.eventPos.y);
					wrapper.control.captureEvents.startCapture();

					wrapper.control.pushEvent(UICustomEvent("dragStart", null), this);
					if (onDragEvent != null) {
						onDragEvent(DragStart, wrapper.eventPos, wrapper);
					}
				}

			case OnRelease(button):
				if (button == draggingButton && state == Dragging) {
					draggingButton = -1;
					wrapper.control.captureEvents.stopCapture();

					var dropPos = new Point(wrapper.eventPos.x + dragOffset.x, wrapper.eventPos.y + dragOffset.y);
					var zone = findDropZone(wrapper.eventPos);
					var dropResult:DragDropResult = {zone: zone, pos: dropPos};

					// Check if drop is accepted
					var accepted = zone != null;
					if (accepted && onDragDrop != null) {
						accepted = onDragDrop(dropResult, wrapper);
					}

					if (accepted && zone != null) {
						// Successful drop
						var snapX = zone.snapX != null ? zone.snapX : dropPos.x;
						var snapY = zone.snapY != null ? zone.snapY : dropPos.y;

						wrapper.control.pushEvent(UICustomEvent("dragDrop", {zone: zone.id}), this);
						if (onDragEvent != null) {
							onDragEvent(DragEnd, wrapper.eventPos, wrapper);
						}

						startAnimation(target.x, target.y, snapX, snapY, snapPathFactory, () -> {
							target.setPosition(snapX, snapY);
							if (zone.slot != null) {
								zone.slot.setContent(target);
							}
						});

						// If no animation was started (factory null or zero distance),
						// state is already Idle from startAnimation->onComplete
						if (state != Animating) {
							state = Idle;
						}
					} else {
						// Failed drop - return to origin
						wrapper.control.pushEvent(UICustomEvent("dragCancel", null), this);
						if (onDragEvent != null) {
							onDragEvent(DragCancel, wrapper.eventPos, wrapper);
						}

						startAnimation(target.x, target.y, originX, originY, returnPathFactory, () -> {
							target.setPosition(originX, originY);
						});

						if (state != Animating) {
							target.setPosition(originX, originY);
							state = Idle;
						}
					}
				}

			case OnMouseMove:
				if (state == Dragging) {
					var newPos = new Point(wrapper.eventPos.x + dragOffset.x, wrapper.eventPos.y + dragOffset.y);
					target.setPosition(newPos.x, newPos.y);
					if (onDragEvent != null) {
						onDragEvent(DragMove, wrapper.eventPos, wrapper);
					}
				}
			default:
		}
	}

	// --- Query ---

	public function isCurrentlyDragging():Bool {
		return state == Dragging;
	}

	public function isAnimating():Bool {
		return state == Animating;
	}

	public function getState():DraggableState {
		return state;
	}

	public function getTarget():Object {
		return target;
	}

	public function getOrigin():Point {
		return new Point(originX, originY);
	}
}
