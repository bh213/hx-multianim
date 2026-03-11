package bh.ui;

import bh.base.FPoint;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.paths.MultiAnimPaths;
import bh.paths.MultiAnimPaths.PathNormalization;
import bh.ui.UICardHandTypes.CardId;
import bh.ui.UICardHandTypes.TargetHighlightCallback;
import bh.ui.UICardHandTypes.TargetAcceptsCallback;
import bh.ui.UIInteractiveWrapper;

/** Manages targeting arrow visual and target zone hit-testing.
 *
 *  The arrow is rendered as a chain of `.manim` programmable instances placed along a
 *  `.manim` path (Stretch-normalized from origin to cursor). Each segment and the
 *  arrowhead receive a `valid:bool` parameter for color switching.
 *
 *  Target zones are `.manim` interactives (`UIInteractiveWrapper`) — hit testing uses
 *  `containsPoint()` which handles coordinate transforms automatically via `globalToLocal`.
 *
 *  When no segment/head names are provided, no arrow visual is drawn but target
 *  detection still works. */
class UICardHandTargeting {
	final builder:MultiAnimBuilder;
	final arrowPathName:Null<String>;
	final segmentSpacing:Float;

	var arrowContainer:h2d.Object;

	// Pool of pre-built segment instances (valid=false and valid=true pairs)
	var segmentPoolInvalid:Array<BuilderResult> = [];
	var segmentPoolValid:Array<BuilderResult> = [];
	var headInvalid:Null<BuilderResult> = null;
	var headValid:Null<BuilderResult> = null;

	var activeSegmentCount:Int = 0;
	var hasArrowVisual:Bool = false;

	var targets:Array<UIInteractiveWrapper> = [];
	var activeTargetId:Null<String> = null;
	var currentValid:Bool = false;

	static inline final MAX_SEGMENTS = 30;

	/** When false, the targeting visual is suppressed (target detection still works). */
	public var arrowEnabled:Bool = true;

	/** When true, arrow endpoint snaps to a point on the hovered target (default: center).
	 *  When false, arrow follows cursor freely — target detection still works. */
	public var snapToTarget:Bool = true;

	/** Optional callback to compute the arrow snap point for a target in the target's local space.
	 *  When null, arrow snaps to interactive center. Receives the target wrapper, returns local-space point. */
	public var arrowSnapPointProvider:Null<(UIInteractiveWrapper) -> FPoint> = null;

	/** Called when a target becomes highlighted or unhighlighted during targeting. */
	public var onTargetHighlight:Null<TargetHighlightCallback> = null;

	/** Optional filter: return false to reject a card from a target. */
	public var acceptsFilter:Null<TargetAcceptsCallback> = null;

	public function new(builder:MultiAnimBuilder, ?segmentName:String, ?headName:String, ?pathName:String, spacing:Float = 25.0) {
		this.builder = builder;
		this.arrowPathName = pathName;
		this.segmentSpacing = spacing;

		arrowContainer = new h2d.Object();
		arrowContainer.visible = false;

		if (segmentName != null && headName != null && pathName != null) {
			hasArrowVisual = true;

			// Pre-build segment pool
			for (_ in 0...MAX_SEGMENTS) {
				var inv = builder.buildWithParameters(segmentName, ["valid" => false], null, null, false);
				var val = builder.buildWithParameters(segmentName, ["valid" => true], null, null, false);
				inv.object.visible = false;
				val.object.visible = false;
				arrowContainer.addChild(inv.object);
				arrowContainer.addChild(val.object);
				segmentPoolInvalid.push(inv);
				segmentPoolValid.push(val);
			}

			// Build arrowhead
			headInvalid = builder.buildWithParameters(headName, ["valid" => false], null, null, false);
			headValid = builder.buildWithParameters(headName, ["valid" => true], null, null, false);
			headInvalid.object.visible = false;
			headValid.object.visible = false;
			arrowContainer.addChild(headInvalid.object);
			arrowContainer.addChild(headValid.object);
		}
	}

	public function getObject():h2d.Object {
		return arrowContainer;
	}

	// === Target registration (interactive-based) ===

	public function registerTarget(wrapper:UIInteractiveWrapper):Void {
		for (i in 0...targets.length) {
			if (targets[i].id == wrapper.id) {
				targets[i] = wrapper;
				return;
			}
		}
		targets.push(wrapper);
	}

	public function registerTargets(wrappers:Array<UIInteractiveWrapper>):Void {
		for (w in wrappers)
			registerTarget(w);
	}

	public function unregisterTarget(id:String):Void {
		var i = 0;
		while (i < targets.length) {
			if (targets[i].id == id) {
				targets.splice(i, 1);
				return;
			}
			i++;
		}
	}

	public function clearTargets():Void {
		if (activeTargetId != null && onTargetHighlight != null) {
			var wrapper = findTarget(activeTargetId);
			if (wrapper != null)
				onTargetHighlight(activeTargetId, false, wrapper.metadata);
		}
		activeTargetId = null;
		targets = [];
	}

	/** Hit-test targets and update highlight state (no arrow visual).
	 *  Used during normal drag (arrow disabled) for continuous target feedback.
	 *  @return The ID of the target under cursor, or null if none. */
	public function updateHighlight(sceneX:Float, sceneY:Float, cardId:CardId):Null<String> {
		var hoveredWrapper:Null<UIInteractiveWrapper> = null;
		var pt = new h2d.col.Point(sceneX, sceneY);
		for (wrapper in targets) {
			if (wrapper.containsPoint(pt)) {
				if (acceptsFilter == null || acceptsFilter(cardId, wrapper.id, wrapper.metadata)) {
					hoveredWrapper = wrapper;
					break;
				}
			}
		}

		var newTargetId = if (hoveredWrapper != null) hoveredWrapper.id else null;
		if (newTargetId != activeTargetId) {
			if (activeTargetId != null && onTargetHighlight != null) {
				var oldWrapper = findTarget(activeTargetId);
				if (oldWrapper != null)
					onTargetHighlight(activeTargetId, false, oldWrapper.metadata);
			}
			activeTargetId = newTargetId;
			if (activeTargetId != null && onTargetHighlight != null && hoveredWrapper != null)
				onTargetHighlight(activeTargetId, true, hoveredWrapper.metadata);
		}

		return newTargetId;
	}

	/** Hit-test targets at a scene-space position without updating any visuals or highlight state.
	 *  Used for final drop check in direct-drag mode. */
	public function hitTestTargets(sceneX:Float, sceneY:Float, cardId:CardId):Null<String> {
		var pt = new h2d.col.Point(sceneX, sceneY);
		for (wrapper in targets) {
			if (wrapper.containsPoint(pt)) {
				if (acceptsFilter == null || acceptsFilter(cardId, wrapper.id, wrapper.metadata))
					return wrapper.id;
			}
		}
		return null;
	}

	/** Update the targeting visual from origin to cursor.
	 *  Places segment programmables along the Stretch-normalized arrow path.
	 *  @param originX, originY — local-space coords for arrow start position
	 *  @param cursorX, cursorY — local-space coords for arrow end position
	 *  @param sceneX, sceneY — scene-space coords for target hit testing
	 *  @return The ID of the target under cursor, or null if none. */
	public function updateTargetingLine(originX:Float, originY:Float, cursorX:Float, cursorY:Float, sceneX:Float, sceneY:Float,
			cardId:CardId):Null<String> {
		arrowContainer.visible = arrowEnabled;

		// Find target under cursor (scene-space coords for containsPoint)
		var hoveredWrapper:Null<UIInteractiveWrapper> = null;
		var pt = new h2d.col.Point(sceneX, sceneY);
		for (wrapper in targets) {
			if (wrapper.containsPoint(pt)) {
				if (acceptsFilter == null || acceptsFilter(cardId, wrapper.id, wrapper.metadata)) {
					hoveredWrapper = wrapper;
					break;
				}
			}
		}

		// Update highlight state
		var newTargetId = if (hoveredWrapper != null) hoveredWrapper.id else null;
		if (newTargetId != activeTargetId) {
			if (activeTargetId != null && onTargetHighlight != null) {
				var oldWrapper = findTarget(activeTargetId);
				if (oldWrapper != null)
					onTargetHighlight(activeTargetId, false, oldWrapper.metadata);
			}
			activeTargetId = newTargetId;
			if (activeTargetId != null && onTargetHighlight != null && hoveredWrapper != null)
				onTargetHighlight(activeTargetId, true, hoveredWrapper.metadata);
		}

		var valid = hoveredWrapper != null;

		// Snap arrow endpoint to target when hovering a valid target (if snap enabled)
		var endX = cursorX;
		var endY = cursorY;
		if (snapToTarget && valid && hoveredWrapper != null) {
			// Get snap point in target's local space (default: interactive center)
			var localPoint:Null<h2d.col.Point> = null;
			if (arrowSnapPointProvider != null) {
				final fp = arrowSnapPointProvider(hoveredWrapper);
				localPoint = new h2d.col.Point(fp.x, fp.y);
			} else {
				switch hoveredWrapper.interactive.multiAnimType {
					case MAInteractive(width, height, _, _):
						localPoint = new h2d.col.Point(width * 0.5, height * 0.5);
					default:
				}
			}
			if (localPoint != null) {
				// Convert from target local space to arrow local space
				var centerScene = hoveredWrapper.interactive.localToGlobal(localPoint);
				var centerLocal = arrowContainer.globalToLocal(centerScene);
				endX = centerLocal.x;
				endY = centerLocal.y;
			}
		}

		// Update arrow visuals (uses local-space coords for positioning)
		if (hasArrowVisual && arrowEnabled && arrowPathName != null) {
			var paths = builder.getPaths();
			var origin = new FPoint(originX, originY);
			var cursor = new FPoint(endX, endY);
			var path = paths.getPath(arrowPathName, Stretch(origin, cursor));

			// Calculate how many segments fit
			var totalLen = path.totalLength;
			var count = Math.floor(totalLen / segmentSpacing);
			if (count > MAX_SEGMENTS) count = MAX_SEGMENTS;
			if (count < 1) count = 1;

			// Toggle valid state if changed
			if (valid != currentValid) {
				currentValid = valid;
			}

			// Place segments along path
			for (i in 0...count) {
				var rate = (i + 0.5) / (count + 1); // evenly spaced, leaving room for head
				var pt2 = path.getPoint(rate);
				var angle = path.getTangentAngle(rate);

				var inv = segmentPoolInvalid[i];
				var val = segmentPoolValid[i];
				inv.object.visible = !currentValid;
				val.object.visible = currentValid;
				inv.object.setPosition(pt2.x, pt2.y);
				inv.object.rotation = angle;
				val.object.setPosition(pt2.x, pt2.y);
				val.object.rotation = angle;
			}

			// Hide unused segments
			for (i in count...activeSegmentCount) {
				segmentPoolInvalid[i].object.visible = false;
				segmentPoolValid[i].object.visible = false;
			}
			activeSegmentCount = count;

			// Place arrowhead at end
			var endPt = path.getPoint(1.0);
			var endAngle = path.getTangentAngle(1.0);
			if (headInvalid != null) {
				headInvalid.object.visible = !currentValid;
				headInvalid.object.setPosition(endPt.x, endPt.y);
				headInvalid.object.rotation = endAngle;
			}
			if (headValid != null) {
				headValid.object.visible = currentValid;
				headValid.object.setPosition(endPt.x, endPt.y);
				headValid.object.rotation = endAngle;
			}
		}

		return newTargetId;
	}

	/** Clear the targeting visual and reset highlight state. */
	public function clearLine():Void {
		arrowContainer.visible = false;

		// Hide all segments
		for (i in 0...activeSegmentCount) {
			segmentPoolInvalid[i].object.visible = false;
			segmentPoolValid[i].object.visible = false;
		}
		activeSegmentCount = 0;

		// Hide arrowhead
		if (headInvalid != null) headInvalid.object.visible = false;
		if (headValid != null) headValid.object.visible = false;

		if (activeTargetId != null && onTargetHighlight != null) {
			var wrapper = findTarget(activeTargetId);
			if (wrapper != null)
				onTargetHighlight(activeTargetId, false, wrapper.metadata);
		}
		activeTargetId = null;
	}

	function findTarget(id:String):Null<UIInteractiveWrapper> {
		for (w in targets)
			if (w.id == id)
				return w;
		return null;
	}
}
