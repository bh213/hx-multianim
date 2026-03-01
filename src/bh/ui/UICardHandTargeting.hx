package bh.ui;

import bh.base.FPoint;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.paths.MultiAnimPaths;
import bh.paths.MultiAnimPaths.PathNormalization;
import bh.ui.UICardHandTypes.CardId;
import bh.ui.UICardHandTypes.CardTarget;

/** Manages targeting arrow visual and target zone hit-testing.
 *
 *  The arrow is rendered as a chain of `.manim` programmable instances placed along a
 *  `.manim` path (Stretch-normalized from origin to cursor). Each segment and the
 *  arrowhead receive a `valid:bool` parameter for color switching.
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

	var targets:Array<CardTarget> = [];
	var activeTargetId:Null<String> = null;
	var currentValid:Bool = false;

	static inline final MAX_SEGMENTS = 30;

	/** When false, the targeting visual is suppressed (target detection still works). */
	public var arrowEnabled:Bool = true;

	/** Called when a target becomes highlighted or unhighlighted during targeting. */
	public var onTargetHighlight:Null<(targetId:String, highlight:Bool) -> Void> = null;

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

	public function registerTarget(target:CardTarget):Void {
		for (i in 0...targets.length) {
			if (targets[i].id == target.id) {
				targets[i] = target;
				return;
			}
		}
		targets.push(target);
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
		if (activeTargetId != null && onTargetHighlight != null)
			onTargetHighlight(activeTargetId, false);
		activeTargetId = null;
		targets = [];
	}

	/** Hit-test targets at a position without updating any visuals.
	 *  Used for direct-drag mode (arrow disabled). */
	public function hitTestTargets(x:Float, y:Float, cardId:CardId):Null<String> {
		for (target in targets) {
			var bounds = target.boundsProvider();
			if (bounds.contains(new h2d.col.Point(x, y))) {
				if (target.accepts == null || target.accepts(cardId))
					return target.id;
			}
		}
		return null;
	}

	/** Update the targeting visual from origin to cursor.
	 *  Places segment programmables along the Stretch-normalized arrow path.
	 *  @return The ID of the target under cursor, or null if none. */
	public function updateTargetingLine(originX:Float, originY:Float, cursorX:Float, cursorY:Float, cardId:CardId):Null<String> {
		arrowContainer.visible = arrowEnabled;

		// Find target under cursor
		var hoveredTarget:Null<CardTarget> = null;
		for (target in targets) {
			var bounds = target.boundsProvider();
			if (bounds.contains(new h2d.col.Point(cursorX, cursorY))) {
				if (target.accepts == null || target.accepts(cardId)) {
					hoveredTarget = target;
					break;
				}
			}
		}

		// Update highlight state
		var newTargetId = if (hoveredTarget != null) hoveredTarget.id else null;
		if (newTargetId != activeTargetId) {
			if (activeTargetId != null && onTargetHighlight != null)
				onTargetHighlight(activeTargetId, false);
			activeTargetId = newTargetId;
			if (activeTargetId != null && onTargetHighlight != null)
				onTargetHighlight(activeTargetId, true);
		}

		var valid = hoveredTarget != null;

		// Update arrow visuals
		if (hasArrowVisual && arrowEnabled && arrowPathName != null) {
			var paths = builder.getPaths();
			var origin = new FPoint(originX, originY);
			var cursor = new FPoint(cursorX, cursorY);
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
				var pt = path.getPoint(rate);
				var angle = path.getTangentAngle(rate);

				var inv = segmentPoolInvalid[i];
				var val = segmentPoolValid[i];
				inv.object.visible = !currentValid;
				val.object.visible = currentValid;
				inv.object.setPosition(pt.x, pt.y);
				inv.object.rotation = angle;
				val.object.setPosition(pt.x, pt.y);
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

		if (activeTargetId != null && onTargetHighlight != null)
			onTargetHighlight(activeTargetId, false);
		activeTargetId = null;
	}
}
