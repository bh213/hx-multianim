package bh.ui;

import bh.base.FPoint;
import bh.base.MAObject;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.SlotHandle;
import bh.paths.AnimatedPath;
import bh.paths.AnimatedPath.AnimatedPathMode;
import bh.paths.MultiAnimPaths.Path;
import bh.paths.MultiAnimPaths.PathNormalization;
import bh.ui.screens.UIScreen;
import bh.ui.screens.UIScreen.LayersEnum;
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
 * Called when dragging starts, moves, ends, or when entering/leaving drop zones.
 */
typedef DragEventDelegate = (event:DragEvent, pos:Point, wrapper:UIElementEventWrapper) -> Void;

/**
 * Delegate function type for handling drag cancellation (drop outside any valid zone).
 */
typedef DragCancelDelegate = (pos:Point, wrapper:UIElementEventWrapper) -> Void;

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
	ZoneEnter(zone:DropZone);
	ZoneLeave(zone:DropZone);
}

@:structInit
class DropZone {
	public var id:String;
	public var bounds:Bounds;
	public var slot:Null<SlotHandle> = null;
	public var snapX:Null<Float> = null;
	public var snapY:Null<Float> = null;
	public var accepts:Null<(draggable:UIMultiAnimDraggable, zone:DropZone) -> Bool> = null;
	public var priority:Int = 0;
	public var boundsProvider:Null<() -> Bounds> = null;
	public var snapProvider:Null<() -> Point> = null;
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
 * with drop zones, slot integration, path-based animations for
 * successful snaps and failed-drop returns, zone hover tracking,
 * drag constraints, priority-based zone selection, and UIScreen layer support.
 */
class UIMultiAnimDraggable implements UIElement implements StandardUIElementEvents implements UIElementUpdatable implements UIElementCustomAddToLayer {
	var root:h2d.Object;
	var target:h2d.Object;
	var dragOffset:Point;

	public var draggableButtons:Array<Int> = [0];

	var draggingButton:Int = -1;

	var state:DraggableState = Idle;
	var originX:Float = 0.;
	var originY:Float = 0.;
	var activeAnim:Null<AnimatedPath> = null;
	var animOnComplete:Null<() -> Void> = null;
	var activeWrapper:Null<UIElementEventWrapper> = null;
	var currentHoverZone:Null<DropZone> = null;

	// Layer support
	var screen:Null<UIScreen> = null;
	var currentLayer:Null<LayersEnum> = null;

	// Delegate callbacks
	public var onDragStart:Null<DragStartDelegate> = null;
	public var onDragDrop:Null<DragDropDelegate> = null;
	public var onDragEvent:Null<DragEventDelegate> = null;
	public var onDragCancel:Null<DragCancelDelegate> = null;

	// Path factories for animations (null = instant teleport)
	public var returnPathFactory:Null<AnimatedPathFactory> = null;
	public var snapPathFactory:Null<AnimatedPathFactory> = null;

	// Drop zones
	public var dropZones:Array<DropZone> = [];

	// Configuration
	public var enabled:Bool = true;
	public var dragConstraint:Null<(pos:Point) -> Point> = null;

	/** Optional layer to reparent to while dragging (null = stay on current layer). */
	public var dragLayer:Null<LayersEnum> = null;

	/** Alpha applied to the target while dragging (null = no change). */
	public var dragAlpha:Null<Float> = null;

	/** Alpha applied to the target when hovering over a valid drop zone (null = no change). */
	public var zoneHighlightAlpha:Null<Float> = null;

	/** Whether to return to origin on failed drop (true) or stay at current position (false). Default: true. */
	public var returnToOrigin:Bool = true;

	/** Whether to apply scale from AnimatedPathState during animation. Default: false. */
	public var animApplyScale:Bool = false;

	/** Whether to apply alpha from AnimatedPathState during animation. Default: false. */
	public var animApplyAlpha:Bool = false;

	/** Whether to apply rotation from AnimatedPathState during animation. Default: false. */
	public var animApplyRotation:Bool = false;

	var savedAlpha:Float = 1.0;

	public function new(target:h2d.Object) {
		this.target = target;
		this.root = new MAObject(MADraggable(0, 0), false);
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

	public function addDropZoneFromSlot(id:String, slot:SlotHandle,
			?accepts:(draggable:UIMultiAnimDraggable, zone:DropZone) -> Bool):UIMultiAnimDraggable {
		dropZones.push({
			id: id,
			bounds: slot.container.getBounds(),
			slot: slot,
			accepts: accepts,
			boundsProvider: () -> slot.container.getBounds(),
			snapProvider: () -> slot.container.localToGlobal(new Point(0, 0))
		});
		return this;
	}

	public function removeDropZone(id:String):Void {
		dropZones = dropZones.filter(z -> z.id != id);
	}

	public function clearDropZones():Void {
		dropZones = [];
	}

	// --- AnimatedPath from builder ---

	public function setReturnAnimPath(builder:MultiAnimBuilder, name:String):UIMultiAnimDraggable {
		returnPathFactory = (from, to) -> builder.createAnimatedPath(name, Stretch(from, to));
		return this;
	}

	public function setSnapAnimPath(builder:MultiAnimBuilder, name:String):UIMultiAnimDraggable {
		snapPathFactory = (from, to) -> builder.createAnimatedPath(name, Stretch(from, to));
		return this;
	}

	function findDropZone(pos:Point):Null<DropZone> {
		var best:Null<DropZone> = null;
		var bestPriority = -2147483648;
		var bestIndex = -1;
		for (i in 0...dropZones.length) {
			var zone = dropZones[i];
			var b = zone.boundsProvider != null ? zone.boundsProvider() : zone.bounds;
			if (b.contains(pos)) {
				if (zone.accepts == null || zone.accepts(this, zone)) {
					if (zone.priority > bestPriority || (zone.priority == bestPriority && i > bestIndex)) {
						best = zone;
						bestPriority = zone.priority;
						bestIndex = i;
					}
				}
			}
		}
		return best;
	}

	function getSnapPosition(zone:DropZone, fallback:Point):{x:Float, y:Float} {
		if (zone.snapProvider != null) {
			var sp = zone.snapProvider();
			return {x: sp.x, y: sp.y};
		}
		return {
			x: zone.snapX != null ? zone.snapX : fallback.x,
			y: zone.snapY != null ? zone.snapY : fallback.y
		};
	}

	// --- AnimatedPath helpers ---

	function startAnimation(fromX:Float, fromY:Float, toX:Float, toY:Float, factory:Null<AnimatedPathFactory>, onComplete:() -> Void):Void {
		if (factory == null) {
			onComplete();
			return;
		}

		// Don't animate zero-distance
		if (Math.abs(toX - fromX) < 0.5 && Math.abs(toY - fromY) < 0.5) {
			onComplete();
			return;
		}

		var from = new FPoint(fromX, fromY);
		var to = new FPoint(toX, toY);
		activeAnim = factory(from, to);
		animOnComplete = onComplete;
		state = Animating;
	}

	// --- Layer helpers ---

	function moveToLayer(layer:Null<LayersEnum>):Void {
		if (screen == null || layer == null)
			return;
		root.remove();
		screen.addObjectToLayer(root, layer);
	}

	function restoreLayer():Void {
		if (dragLayer != null && screen != null && currentLayer != null) {
			root.remove();
			screen.addObjectToLayer(root, currentLayer);
		}
	}

	// --- UIElementUpdatable ---

	public function update(dt:Float):Void {
		if (state != Animating || activeAnim == null)
			return;

		var s = activeAnim.update(dt);
		root.setPosition(s.position.x, s.position.y);
		if (animApplyScale) {
			target.scaleX = s.scale;
			target.scaleY = s.scale;
		}
		if (animApplyAlpha) target.alpha = s.alpha;
		if (animApplyRotation) target.rotation = s.rotation;

		if (s.done) {
			// Restore target properties modified by animation
			if (animApplyScale) {
				target.scaleX = 1.;
				target.scaleY = 1.;
			}
			if (animApplyAlpha) target.alpha = savedAlpha;
			if (animApplyRotation) target.rotation = 0.;

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
		if (activeWrapper != null) {
			activeWrapper.control.captureEvents.stopCapture();
			activeWrapper = null;
		}
		activeAnim = null;
		animOnComplete = null;
		currentHoverZone = null;
		draggingButton = -1;
		if (state == Dragging) {
			restoreLayer();
			if (target != null)
				target.alpha = savedAlpha;
		}
		state = Idle;
		if (target != null) {
			target.remove();
			target = null;
		}
	}

	// --- UIElementCustomAddToLayer ---

	public function customAddToLayer(requestedLayer:Null<LayersEnum>, screen:UIScreen, updateMode:Bool):UIElementCustomAddToLayerResult {
		if (requestedLayer == null) {
			if (updateMode)
				throw 'customAddToLayer update mode had no layer';
			else
				return Postponed;
		}
		if (!updateMode && this.root.parent == null)
			screen.addObjectToLayer(this.root, requestedLayer);
		this.screen = screen;
		this.currentLayer = requestedLayer;
		return Added;
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
					activeWrapper = wrapper;

					// Remember origin for return animation
					originX = root.x;
					originY = root.y;

					dragOffset = new Point(root.x - wrapper.eventPos.x, root.y - wrapper.eventPos.y);
					wrapper.control.captureEvents.startCapture();

					// Apply drag alpha
					savedAlpha = target.alpha;
					if (dragAlpha != null)
						target.alpha = dragAlpha;

					// Reparent to drag layer if configured
					moveToLayer(dragLayer);

					wrapper.control.pushEvent(UICustomEvent("dragStart", null), this);
					if (onDragEvent != null) {
						onDragEvent(DragStart, wrapper.eventPos, wrapper);
					}
				}

			case OnRelease(button):
				if (button == draggingButton && state == Dragging) {
					draggingButton = -1;
					activeWrapper = null;
					wrapper.control.captureEvents.stopCapture();

					// Clear zone hover
					if (currentHoverZone != null) {
						if (onDragEvent != null)
							onDragEvent(ZoneLeave(currentHoverZone), wrapper.eventPos, wrapper);
						currentHoverZone = null;
					}

					// Restore alpha
					target.alpha = savedAlpha;

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
						var snap = getSnapPosition(zone, dropPos);

						wrapper.control.pushEvent(UICustomEvent("dragDrop", {zone: zone.id}), this);
						if (onDragEvent != null) {
							onDragEvent(DragEnd, wrapper.eventPos, wrapper);
						}

						startAnimation(root.x, root.y, snap.x, snap.y, snapPathFactory, () -> {
							root.setPosition(snap.x, snap.y);
							restoreLayer();
							if (zone.slot != null) {
								zone.slot.setContent(target);
							}
						});
					} else {
						// Failed drop
						wrapper.control.pushEvent(UICustomEvent("dragCancel", null), this);
						if (onDragEvent != null) {
							onDragEvent(DragCancel, wrapper.eventPos, wrapper);
						}
						if (onDragCancel != null) {
							onDragCancel(wrapper.eventPos, wrapper);
						}

						if (returnToOrigin) {
							startAnimation(root.x, root.y, originX, originY, returnPathFactory, () -> {
								root.setPosition(originX, originY);
								restoreLayer();
							});
						} else {
							// Stay at current position
							state = Idle;
							restoreLayer();
						}
					}
				}

			case OnMouseMove:
				if (state == Dragging) {
					var newPos = new Point(wrapper.eventPos.x + dragOffset.x, wrapper.eventPos.y + dragOffset.y);
					if (dragConstraint != null) {
						newPos = dragConstraint(newPos);
					}
					root.setPosition(newPos.x, newPos.y);

					// Zone hover tracking
					var hoverZone = findDropZone(wrapper.eventPos);
					if (hoverZone != currentHoverZone) {
						if (currentHoverZone != null && onDragEvent != null) {
							onDragEvent(ZoneLeave(currentHoverZone), wrapper.eventPos, wrapper);
						}
						currentHoverZone = hoverZone;
						if (currentHoverZone != null && onDragEvent != null) {
							onDragEvent(ZoneEnter(currentHoverZone), wrapper.eventPos, wrapper);
						}
						// Update alpha for zone highlight
						if (zoneHighlightAlpha != null) {
							target.alpha = if (currentHoverZone != null) zoneHighlightAlpha else if (dragAlpha != null) dragAlpha else savedAlpha;
						}
					}

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
