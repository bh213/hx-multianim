		package bh.paths;

import bh.multianim.CoordinateSystems;
import bh.multianim.CoordinateSystems.Coordinates;
import bh.multianim.MultiAnimParser;
import bh.multianim.MultiAnimBuilder;
import bh.base.FPoint;
using bh.base.TweenUtils;

enum PathType {
	Checkpoint(name:String);
	Line;
	Arc(center:FPoint, startAngle:Float, radius:Float, angleDelta:Float);
	Bezier3(control1:FPoint, control2:FPoint, control3:FPoint);
	Bezier4(control1:FPoint, control2:FPoint, control3:FPoint, control4:FPoint);
	Spiral(center:FPoint, startAngle:Float, radiusStart:Float, radiusEnd:Float, angleDelta:Float);
	Wave(amplitude:Float, wavelength:Float, count:Float, dirAngle:Float);
}

/** How to transform a path relative to start/end points. */
enum PathNormalization {
	/** Maps path's (0,0)→endpoint onto startPoint→endPoint via scale+rotation+translation.
	 *  Best for open paths with a clear start→end direction. */
	Stretch(startPoint:FPoint, endPoint:FPoint);

	/** Scales path so its extent fits targetDist, centers geometric midpoint between start and end.
	 *  Best for closed paths (circuit, star, circle). */
	FitCenter(startPoint:FPoint, endPoint:FPoint);

	/** No scaling. Translates path origin to position, rotates by angle (radians). */
	Anchor(position:FPoint, angle:Float);

	/** Scales path to fit inside the axis-aligned bounding box defined by topLeft→bottomRight.
	 *  No rotation — the two points define a rectangle. */
	FitBounds(topLeft:FPoint, bottomRight:FPoint);
}

@:nullSafety
class MultiAnimPaths {
	final pathDefs:PathsDef;
	final builder:MultiAnimBuilder;

	public function new(pathDefs:PathsDef, builder:MultiAnimBuilder) {
		this.pathDefs = pathDefs;
		this.builder = builder;
	}

	public function getPath(name:String, ?normalization:PathNormalization):Path {
		final oldIndexed = builder.indexedParams;
		builder.indexedParams = [];

		var gridCoordinateSystem:Null<GridCoordinateSystem> = null;
		var hexCoordinateSystem:Null<HexCoordinateSystem> = null;

		inline function resolveCoordinate(pos:Coordinates):FPoint {
			return builder.calculatePosition(pos, gridCoordinateSystem, hexCoordinateSystem);
		}

		inline function resolveNumber(value:ReferenceableValue):Float {
			return builder.resolveAsNumber(value);
		}

		final def = pathDefs.get(name);
		if (def == null)
			throw 'path not found: $name';

		var singlePaths:Array<SinglePath> = [];
		var point = new FPoint(0, 0);
		var angle:Float = 0.;

		for (path in def) {
			switch path {
				case LineTo(end, mode):
					var end = resolveCoordinate(end);
					var finalEnd = switch(mode) {
						case PCMAbsolute: end;
						case PCMRelative|null: new FPoint(point.x + end.x, point.y + end.y);
					};
					singlePaths.push(new SinglePath(point, finalEnd, Line));
					angle = hxd.Math.atan2(finalEnd.y - point.y, finalEnd.x - point.x);
					point = finalEnd;

				case Forward(distance):
					var distance = resolveNumber(distance);
					var end = new FPoint(point.x + distance * Math.cos(angle), point.y + distance * Math.sin(angle));
					singlePaths.push(new SinglePath(point, end, Line));
					point = end;
				case TurnDegrees(angleDelta):
					var angleDelta = resolveNumber(angleDelta);
					angle = hxd.Math.angle(angle + hxd.Math.degToRad(angleDelta));

				case Arc(radius, angleDelta):
					var radius = resolveNumber(radius);
					var angleDeltaF = resolveNumber(angleDelta);
					var angleDeltaRad = hxd.Math.degToRad(angleDeltaF);

					// Perpendicular direction: +90° for CCW, -90° for CW
					var perpAngle = hxd.Math.angle(angle + (angleDeltaF > 0 ? Math.PI / 2 : -Math.PI / 2));
					var centerX = point.x + radius * Math.cos(perpAngle);
					var centerY = point.y + radius * Math.sin(perpAngle);
					var center = new FPoint(centerX, centerY);

					// Start angle for the arc (from center to start point)
					var startAngle = Math.atan2(point.y - centerY, point.x - centerX);
					var endAngle = startAngle + angleDeltaRad;

					var end = new FPoint(
						centerX + radius * Math.cos(endAngle),
						centerY + radius * Math.sin(endAngle)
					);
					singlePaths.push(new SinglePath(point, end, Arc(center, startAngle, radius, angleDeltaF)));

					// Update direction for next segment
					angle = hxd.Math.angle(angle + angleDeltaRad);
					point = end;

				case Checkpoint(name):
					singlePaths.push(new SinglePath(point, point, Checkpoint(name)));

				case Bezier2To(end, control, mode, smoothing):
					var end = resolveCoordinate(end);
					var control = resolveCoordinate(control);
					var finalEnd = switch(mode) {
						case PCMAbsolute: end;
						case PCMRelative|null: new FPoint(point.x + end.x, point.y + end.y);
					};
					var finalControl = switch(mode) {
						case PCMAbsolute: control;
						case PCMRelative|null: new FPoint(point.x + control.x, point.y + control.y);
					};
					
					var pxDistance = getSmoothingDistance(smoothing, point, finalControl);
					if (pxDistance > 0) {
						// Calculate PX (additional control point) to ensure smooth angle transition
						// PX should be positioned so that the tangent at the start point matches the current angle
						var px = new FPoint(
							point.x + pxDistance * Math.cos(angle),
							point.y + pxDistance * Math.sin(angle)
						);
						
						singlePaths.push(new SinglePath(point, finalEnd, Bezier3(px, finalControl, finalEnd)));
					} else {
						// No smoothing - use original bezier2 as bezier3 with control point at start
						singlePaths.push(new SinglePath(point, finalEnd, Bezier3(point, finalControl, finalEnd)));
					}
					// For cubic bezier, the tangent at the end point is from control to end point
					angle = hxd.Math.atan2(finalEnd.y - finalControl.y, finalEnd.x - finalControl.x);
					point = finalEnd;

				case Bezier3To(end, control1, control2, mode, smoothing):
					var end = resolveCoordinate(end);
					var control1 = resolveCoordinate(control1);
					var control2 = resolveCoordinate(control2);
					var finalEnd = switch(mode) {
						case PCMAbsolute: end;
						case PCMRelative|null: new FPoint(point.x + end.x, point.y + end.y);
					};
					var finalControl1 = switch(mode) {
						case PCMAbsolute: control1;
						case PCMRelative|null: new FPoint(point.x + control1.x, point.y + control1.y);
					};
					var finalControl2 = switch(mode) {
						case PCMAbsolute: control2;
						case PCMRelative|null: new FPoint(point.x + control2.x, point.y + control2.y);
					};
					
					var pxDistance = getSmoothingDistance(smoothing, point, finalControl1);
					if (pxDistance > 0) {
						// Calculate PX (additional control point) to ensure smooth angle transition
						// PX should be positioned so that the tangent at the start point matches the current angle
						var px = new FPoint(
							point.x + pxDistance * Math.cos(angle),
							point.y + pxDistance * Math.sin(angle)
						);
						
						singlePaths.push(new SinglePath(point, finalEnd, Bezier4(px, finalControl1, finalControl2, finalEnd)));
					} else {
						// No smoothing - use original bezier3 as bezier4 with control point at start
						singlePaths.push(new SinglePath(point, finalEnd, Bezier4(point, finalControl1, finalControl2, finalEnd)));
					}
					// For quartic bezier, the tangent at the end point is from control2 to end point
					angle = hxd.Math.atan2(finalEnd.y - finalControl2.y, finalEnd.x - finalControl2.x);
					point = finalEnd;

				case Close:
					// Close back to start of first segment in this path
					var closeTarget = if (singlePaths.length > 0) singlePaths[0].start else new FPoint(0, 0);
					singlePaths.push(new SinglePath(point, closeTarget, Line));
					angle = hxd.Math.atan2(closeTarget.y - point.y, closeTarget.x - point.x);
					point = closeTarget;

				case MoveTo(target, mode):
					var target = resolveCoordinate(target);
					var finalTarget = switch(mode) {
						case PCMAbsolute: target;
						case PCMRelative|null: new FPoint(point.x + target.x, point.y + target.y);
					};
					angle = hxd.Math.atan2(finalTarget.y - point.y, finalTarget.x - point.x);
					point = finalTarget;

				case Spiral(radiusStart, radiusEnd, angleDelta):
					var rStart = resolveNumber(radiusStart);
					var rEnd = resolveNumber(radiusEnd);
					var angleDeltaF = resolveNumber(angleDelta);
					var angleDeltaRad = hxd.Math.degToRad(angleDeltaF);

					// Center is perpendicular to current direction, at distance radiusStart
					var perpAngle = hxd.Math.angle(angle + (angleDeltaF > 0 ? Math.PI / 2 : -Math.PI / 2));
					var centerX = point.x + rStart * Math.cos(perpAngle);
					var centerY = point.y + rStart * Math.sin(perpAngle);
					var center = new FPoint(centerX, centerY);

					// Start angle (from center to start point)
					var startAngle = Math.atan2(point.y - centerY, point.x - centerX);
					var endAngle = startAngle + angleDeltaRad;

					// End point: center + radiusEnd at endAngle
					var endPt = new FPoint(
						centerX + rEnd * Math.cos(endAngle),
						centerY + rEnd * Math.sin(endAngle)
					);
					singlePaths.push(new SinglePath(point, endPt, Spiral(center, startAngle, rStart, rEnd, angleDeltaF)));

					angle = hxd.Math.angle(angle + angleDeltaRad);
					point = endPt;

				case Wave(amplitude, wavelength, count):
					var amp = resolveNumber(amplitude);
					var wl = resolveNumber(wavelength);
					var cnt = resolveNumber(count);
					var totalLength = wl * cnt;

					var endPt = new FPoint(
						point.x + totalLength * Math.cos(angle),
						point.y + totalLength * Math.sin(angle)
					);
					singlePaths.push(new SinglePath(point, endPt, Wave(amp, wl, cnt, angle)));
					// Wave ends in same direction, angle doesn't change
					point = endPt;
			}
		}

		builder.indexedParams = oldIndexed;
		var path = new Path(singlePaths);
		if (normalization != null) {
			return path.applyTransform(normalization);
		}
		return path;
	}

	private function getSmoothingDistance(smoothing:Null<bh.multianim.MultiAnimParser.SmoothingType>, start:FPoint, control:FPoint):Float {
		if (smoothing == null) {
			// Auto smoothing - use 50% of distance to control point
			return hxd.Math.distance(start.x - control.x, start.y - control.y) * 0.5;
		}
		
		return switch smoothing {
			case STNone: 0.0;
			case STAuto: hxd.Math.distance(start.x - control.x, start.y - control.y) * 0.5;
			case STDistance(value): 
				builder.resolveAsNumber(value);
		}
	}
}	
	




@:allow(bh.paths.MultiAnimPaths)
class Path {
	var singlePaths:Array<SinglePath>;
	var checkpoints:Map<String, Float> = [];
	public var totalLength:Float;
	public var endpoint:FPoint;

	public function new(singlePaths:Array<SinglePath>, ?precomputedLengths:Array<Float>) {
		this.singlePaths = singlePaths;
		var currentLength = 0.;

		for (i in 0...singlePaths.length) {
			final singlePath = singlePaths[i];
			final startOffset = currentLength;
			currentLength += if (precomputedLengths != null) precomputedLengths[i] else singlePath.length();
			singlePath.startRange = startOffset;
			singlePath.endRange = currentLength;
		}

		this.totalLength = currentLength;

		for (singlePath in singlePaths) {
			singlePath.startRange /= totalLength;
			singlePath.endRange /= totalLength;
			switch singlePath.path {
				case Checkpoint(name):
					if (checkpoints.exists(name))
						throw 'duplicate checkpoint: $name';
					checkpoints.set(name, singlePath.startRange);

				case _:
			}
		}
		this.singlePaths = this.singlePaths.filter(x-> !x.path.match(Checkpoint(_)));

		// Set endpoint as the end of the last SinglePath, or (0,0) if none
		if (this.singlePaths.length > 0) {
			this.endpoint = this.singlePaths[this.singlePaths.length - 1].getEndpoint();
		} else {
			this.endpoint = new FPoint(0, 0);
		}
	}

	/** Fast constructor for macro-generated code: singlePaths already have startRange/endRange
	 *  normalized, no checkpoints in array, endpoint and totalLength pre-computed. */
	public static function fromPrecomputed(singlePaths:Array<SinglePath>, totalLength:Float, checkpointNames:Array<String>,
			checkpointRates:Array<Float>, endpoint:FPoint):Path {
		var p = new Path([]);
		p.singlePaths = singlePaths;
		p.totalLength = totalLength;
		p.endpoint = endpoint;
		for (i in 0...checkpointNames.length) {
			p.checkpoints.set(checkpointNames[i], checkpointRates[i]);
		}
		return p;
	}


	public inline function getCheckpoint(name:String):Float {
		var retVal = checkpoints.get(name);
		if (retVal == null)
			throw 'checkpoint not found: $name';
		return retVal;
	}

	public function drawToGraphics(g:h2d.Graphics) {
		var pixels = toPixelsLine();
		for (i in 0...pixels.length-1) {
			final pt = pixels[i];
			final pt1 = pixels[i+1];
			g.moveTo(pt.x, pt.y);
			g.lineTo(pt1.x, pt1.y);
		}
	}

	public function toPixelsLine() {
		var retVal:Array<FPoint> = [];
		for (path in singlePaths) {
			retVal = retVal.concat(path.toPixelArray());
		}
		return retVal;
	}

	public function getPoint(rate:Float) {
		for (singlePath in singlePaths) {
			if (rate >= singlePath.startRange && rate <= singlePath.endRange) {
				return singlePath.getPoint((rate - singlePath.startRange) / (singlePath.endRange - singlePath.startRange));
			}
		}
		// Extrapolate beyond [0, 1] using first/last segment (e.g. for overshooting progress curves)
		if (rate > 1.0 && singlePaths.length > 0) {
			var last = singlePaths[singlePaths.length - 1];
			return last.getPoint((rate - last.startRange) / (last.endRange - last.startRange));
		}
		if (rate < 0.0 && singlePaths.length > 0) {
			var first = singlePaths[0];
			return first.getPoint((rate - first.startRange) / (first.endRange - first.startRange));
		}
		throw 'rate out of range: $rate';
	}

	/** Get analytical tangent angle (radians) at the given rate (0..1). */
	public function getTangentAngle(rate:Float):Float {
		for (singlePath in singlePaths) {
			if (rate >= singlePath.startRange && rate <= singlePath.endRange) {
				return singlePath.getTangentAngle((rate - singlePath.startRange) / (singlePath.endRange - singlePath.startRange));
			}
		}
		// Extrapolate beyond [0, 1] using first/last segment
		if (rate > 1.0 && singlePaths.length > 0) {
			var last = singlePaths[singlePaths.length - 1];
			return last.getTangentAngle((rate - last.startRange) / (last.endRange - last.startRange));
		}
		if (rate < 0.0 && singlePaths.length > 0) {
			var first = singlePaths[0];
			return first.getTangentAngle((rate - first.startRange) / (first.endRange - first.startRange));
		}
		throw 'rate out of range: $rate';
	}

	public function getEndpoint():FPoint {
		return endpoint;
	}

	/** Find the rate (0..1) on this path closest to the given world point.
	 *  Uses coarse sampling followed by golden-section refinement. */
	public function getClosestRate(point:FPoint):Float {
		if (singlePaths.length == 0) return 0.0;

		// Phase 1: Coarse sampling
		final samples = 50;
		var closestRate:Float = 0.0;
		var closestDistSq:Float = Math.POSITIVE_INFINITY;

		for (i in 0...samples + 1) {
			final rate = i / samples;
			final pt = getPoint(rate);
			final dx = pt.x - point.x;
			final dy = pt.y - point.y;
			final distSq = dx * dx + dy * dy;
			if (distSq < closestDistSq) {
				closestDistSq = distSq;
				closestRate = rate;
			}
		}

		// Phase 2: Golden-section refinement around the closest sample
		final searchRadius = 1.0 / samples;
		var left = Math.max(0.0, closestRate - searchRadius);
		var right = Math.min(1.0, closestRate + searchRadius);
		final phi = (Math.sqrt(5.0) - 1.0) / 2.0;
		final tolerance = 1e-6;

		while (right - left > tolerance) {
			final mid1 = right - (right - left) * phi;
			final mid2 = left + (right - left) * phi;

			final pt1 = getPoint(mid1);
			final pt2 = getPoint(mid2);
			final dx1 = pt1.x - point.x;
			final dy1 = pt1.y - point.y;
			final dx2 = pt2.x - point.x;
			final dy2 = pt2.y - point.y;

			if (dx1 * dx1 + dy1 * dy1 < dx2 * dx2 + dy2 * dy2) {
				right = mid2;
			} else {
				left = mid1;
			}
		}

		return (left + right) / 2.0;
	}

	/** Apply a normalization transform to this path, returning a new transformed Path. */
	public function applyTransform(mode:PathNormalization):Path {
		return switch mode {
			case Stretch(startPoint, endPoint):
				applyStretch(startPoint, endPoint);
			case FitCenter(startPoint, endPoint):
				applyFitCenter(startPoint, endPoint);
			case Anchor(position, angle):
				applyAnchor(position, angle);
			case FitBounds(topLeft, bottomRight):
				applyFitBounds(topLeft, bottomRight);
		};
	}

	/** Stretch: maps (0,0)→endpoint onto startPoint→endPoint via scale+rotation+translation. */
	function applyStretch(startPoint:FPoint, endPoint:FPoint):Path {
		final targetDist = hxd.Math.distance(endPoint.x - startPoint.x, endPoint.y - startPoint.y);
		final targetAngle = Math.atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x);
		final rawDist = hxd.Math.distance(endpoint.x, endpoint.y);
		if (rawDist < 1e-10) return applyFitCenter(startPoint, endPoint); // degenerate: fallback

		final scale = targetDist / rawDist;
		final rawAngle = Math.atan2(endpoint.y, endpoint.x);
		final rotation = targetAngle - rawAngle;
		return transformAll(Math.cos(rotation), Math.sin(rotation), scale, startPoint.x, startPoint.y);
	}

	/** FitCenter: scales by max extent, centers geometric midpoint between start and end. */
	function applyFitCenter(startPoint:FPoint, endPoint:FPoint):Path {
		final targetDist = hxd.Math.distance(endPoint.x - startPoint.x, endPoint.y - startPoint.y);
		final targetAngle = Math.atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x);
		final maxExtent = computeMaxExtent();
		final scale = if (maxExtent > 1e-10) targetDist / (maxExtent * 2) else 1.0;

		// Scale + rotate around origin first, then compute center offset
		final cosA = Math.cos(targetAngle);
		final sinA = Math.sin(targetAngle);
		var scaled = transformAll(cosA, sinA, scale, 0, 0);

		// Compute geometric center of scaled path
		final center = scaled.computeCenter();
		final midX = (startPoint.x + endPoint.x) / 2;
		final midY = (startPoint.y + endPoint.y) / 2;

		// Translate so center maps to midpoint
		return scaled.translateAll(midX - center.x, midY - center.y);
	}

	/** Anchor: translate to position, rotate by angle. No scaling. */
	function applyAnchor(position:FPoint, angle:Float):Path {
		return transformAll(Math.cos(angle), Math.sin(angle), 1.0, position.x, position.y);
	}

	/** FitBounds: scale to fit inside axis-aligned bounding box, no rotation. */
	function applyFitBounds(topLeft:FPoint, bottomRight:FPoint):Path {
		final bounds = computeBounds();
		final pathW = bounds.maxX - bounds.minX;
		final pathH = bounds.maxY - bounds.minY;
		final boxW = bottomRight.x - topLeft.x;
		final boxH = bottomRight.y - topLeft.y;

		// Uniform scale to fit
		var scale:Float = 1.0;
		if (pathW > 1e-10 && pathH > 1e-10)
			scale = Math.min(boxW / pathW, boxH / pathH);
		else if (pathW > 1e-10)
			scale = boxW / pathW;
		else if (pathH > 1e-10)
			scale = boxH / pathH;

		// Scale around origin, then translate to center in box
		var scaled = transformAll(1.0, 0.0, scale, 0, 0);
		final scaledBounds = scaled.computeBounds();
		final scaledW = scaledBounds.maxX - scaledBounds.minX;
		final scaledH = scaledBounds.maxY - scaledBounds.minY;
		final tx = topLeft.x + (boxW - scaledW) / 2 - scaledBounds.minX;
		final ty = topLeft.y + (boxH - scaledH) / 2 - scaledBounds.minY;

		return scaled.translateAll(tx, ty);
	}

	/** Apply scale+rotation+translation to all segments. */
	function transformAll(cosA:Float, sinA:Float, scale:Float, tx:Float, ty:Float):Path {
		var transformed:Array<SinglePath> = [];
		for (sp in singlePaths) {
			transformed.push(sp.transform(cosA, sinA, scale, tx, ty));
		}
		return new Path(transformed);
	}

	/** Translate all segments by (dx, dy). */
	function translateAll(dx:Float, dy:Float):Path {
		var transformed:Array<SinglePath> = [];
		for (sp in singlePaths) {
			transformed.push(sp.transform(1.0, 0.0, 1.0, dx, dy));
		}
		return new Path(transformed);
	}

	/** Compute the maximum distance any point on this path is from the origin,
	 *  by sampling at regular intervals. */
	function computeMaxExtent():Float {
		var maxDist:Float = 0;
		final steps = 50;
		for (i in 0...steps + 1) {
			var pt = getPoint(i / steps);
			var d = hxd.Math.distance(pt.x, pt.y);
			if (d > maxDist) maxDist = d;
		}
		return maxDist;
	}

	/** Compute geometric center by sampling points along the path. */
	function computeCenter():FPoint {
		var sumX:Float = 0;
		var sumY:Float = 0;
		final steps = 50;
		for (i in 0...steps + 1) {
			var pt = getPoint(i / steps);
			sumX += pt.x;
			sumY += pt.y;
		}
		final n = steps + 1;
		return new FPoint(sumX / n, sumY / n);
	}

	/** Compute axis-aligned bounding box by sampling points along the path. */
	function computeBounds():{minX:Float, minY:Float, maxX:Float, maxY:Float} {
		var minX = Math.POSITIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY;
		var maxY = Math.NEGATIVE_INFINITY;
		final steps = 50;
		for (i in 0...steps + 1) {
			var pt = getPoint(i / steps);
			if (pt.x < minX) minX = pt.x;
			if (pt.y < minY) minY = pt.y;
			if (pt.x > maxX) maxX = pt.x;
			if (pt.y > maxY) maxY = pt.y;
		}
		return {minX: minX, minY: minY, maxX: maxX, maxY: maxY};
	}
}

@:allow(bh.paths.MultiAnimPaths)
class SinglePath {
	var startRange:Float = Math.NaN;
	var endRange:Float = Math.NaN;

	var path:PathType;
	var start:FPoint;
	var end:FPoint;

	public function new(start:FPoint, end:FPoint, path:PathType) {
		this.start = start;
		this.end = end;
		this.path = path;
	}

	/** Create a SinglePath with pre-computed normalized range values. */
	public static inline function withRange(start:FPoint, end:FPoint, path:PathType, startRange:Float, endRange:Float):SinglePath {
		var sp = new SinglePath(start, end, path);
		sp.startRange = startRange;
		sp.endRange = endRange;
		return sp;
	}

	public function getPoint(rate:Float):FPoint {
		switch (path) {
			case Checkpoint(name):
				return start.clone();
			case Line:
				return new FPoint(rate.lerp(start.x, end.x), rate.lerp(start.y, end.y));
			case Arc(center, startAngle, radius, angleDelta):
				var angleDeltaRad = hxd.Math.degToRad(angleDelta);
				var currentAngle = startAngle + angleDeltaRad * rate;
				return new FPoint(
					center.x + radius * Math.cos(currentAngle),
					center.y + radius * Math.sin(currentAngle)
				);
			case Bezier3(control1, control2, control3):
				var xValues = [start.x, control1.x, control2.x, end.x];
				var yValues = [start.y, control1.y, control2.y, end.y];
				return new FPoint(rate.bezier(xValues), rate.bezier(yValues));
			case Bezier4(control1, control2, control3, control4):
				var xValues = [start.x, control1.x, control2.x, control3.x, end.x];
				var yValues = [start.y, control1.y, control2.y, control3.y, end.y];
				return new FPoint(rate.bezier(xValues), rate.bezier(yValues));
			case Spiral(center, startAngle, radiusStart, radiusEnd, angleDelta):
				var angleDeltaRad = hxd.Math.degToRad(angleDelta);
				var currentAngle = startAngle + angleDeltaRad * rate;
				var r = rate.lerp(radiusStart, radiusEnd);
				return new FPoint(
					center.x + r * Math.cos(currentAngle),
					center.y + r * Math.sin(currentAngle)
				);
			case Wave(amplitude, wavelength, count, dirAngle):
				var totalLength = wavelength * count;
				var forward = rate * totalLength;
				var phase = rate * count * 2 * Math.PI;
				var lateral = amplitude * Math.sin(phase);
				var cosD = Math.cos(dirAngle);
				var sinD = Math.sin(dirAngle);
				return new FPoint(
					start.x + forward * cosD - lateral * sinD,
					start.y + forward * sinD + lateral * cosD
				);
		}
	}
	/** Analytical tangent angle (radians) at the given local rate (0..1). */
	public function getTangentAngle(rate:Float):Float {
		switch (path) {
			case Checkpoint(_):
				return 0.;
			case Line:
				return Math.atan2(end.y - start.y, end.x - start.x);
			case Arc(center, startAngle, radius, angleDelta):
				var angleDeltaRad = hxd.Math.degToRad(angleDelta);
				var currentAngle = startAngle + angleDeltaRad * rate;
				// Tangent is perpendicular to radius; direction depends on CW/CCW
				if (angleDelta > 0)
					return currentAngle + Math.PI / 2;
				else
					return currentAngle - Math.PI / 2;
			case Bezier3(control1, control2, control3):
				// Cubic bezier derivative: 3(1-t)^2(P1-P0) + 6(1-t)t(P2-P1) + 3t^2(P3-P2)
				// Points: P0=start, P1=control1, P2=control2, P3=end
				var t = rate;
				var mt = 1.0 - t;
				var dx = 3 * mt * mt * (control1.x - start.x) + 6 * mt * t * (control2.x - control1.x) + 3 * t * t * (end.x - control2.x);
				var dy = 3 * mt * mt * (control1.y - start.y) + 6 * mt * t * (control2.y - control1.y) + 3 * t * t * (end.y - control2.y);
				return Math.atan2(dy, dx);
			case Bezier4(control1, control2, control3, control4):
				// Quartic bezier derivative: 4 control points -> cubic derivative
				// Points: P0=start, P1=control1, P2=control2, P3=control3, P4=end
				var t = rate;
				var mt = 1.0 - t;
				var mt2 = mt * mt;
				var t2 = t * t;
				var dx = 4 * mt2 * mt * (control1.x - start.x) + 12 * mt2 * t * (control2.x - control1.x)
					+ 12 * mt * t2 * (control3.x - control2.x) + 4 * t2 * t * (end.x - control3.x);
				var dy = 4 * mt2 * mt * (control1.y - start.y) + 12 * mt2 * t * (control2.y - control1.y)
					+ 12 * mt * t2 * (control3.y - control2.y) + 4 * t2 * t * (end.y - control3.y);
				return Math.atan2(dy, dx);
			case Spiral(center, startAngle, radiusStart, radiusEnd, angleDelta):
				var angleDeltaRad = hxd.Math.degToRad(angleDelta);
				var currentAngle = startAngle + angleDeltaRad * rate;
				var r = rate.lerp(radiusStart, radiusEnd);
				var dr = radiusEnd - radiusStart; // dr/dt (normalized)
				// dx/dt = dr*cos(a) - r*angleDeltaRad*sin(a), dy/dt = dr*sin(a) + r*angleDeltaRad*cos(a)
				var cosA = Math.cos(currentAngle);
				var sinA = Math.sin(currentAngle);
				var dx = dr * cosA - r * angleDeltaRad * sinA;
				var dy = dr * sinA + r * angleDeltaRad * cosA;
				return Math.atan2(dy, dx);
			case Wave(amplitude, wavelength, count, dirAngle):
				var totalLength = wavelength * count;
				// forward component: constant = totalLength
				// lateral component: amplitude * sin(rate * count * 2pi)
				// d(lateral)/d(rate) = amplitude * count * 2pi * cos(rate * count * 2pi)
				var phase = rate * count * 2 * Math.PI;
				var dLateral = amplitude * count * 2 * Math.PI * Math.cos(phase);
				var cosD = Math.cos(dirAngle);
				var sinD = Math.sin(dirAngle);
				var dx = totalLength * cosD - dLateral * sinD;
				var dy = totalLength * sinD + dLateral * cosD;
				return Math.atan2(dy, dx);
		}
	}

	public function toPixelArray():Array<FPoint> {
		
		return switch path {
			case Line: 
				[start, end];
			case Arc(center, startAngle, radius, angleDelta):
				var arcLength = length();
				// Calculate steps based on arc length: approximately 1 point per pixel
				// For very small arcs, ensure at least 3 points for smooth rendering
				var steps = hxd.Math.imax(3, cast arcLength);
				[for(i in 0...steps) getPoint(1.0*i/steps)];
			case Bezier3(control1, control2, control3):
				var steps = hxd.Math.imax(8, cast length() / 4);
				[for(i in 0...steps) getPoint(1.0*i/steps)];
			case Bezier4(control1, control2, control3, control4):
				var steps = hxd.Math.imax(12, cast length() / 4);
				[for(i in 0...steps) getPoint(1.0*i/steps)];
			case Spiral(center, startAngle, radiusStart, radiusEnd, angleDelta):
				var steps = hxd.Math.imax(8, cast length() / 4);
				[for(i in 0...steps) getPoint(1.0*i/steps)];
			case Wave(amplitude, wavelength, count, dirAngle):
				var steps = hxd.Math.imax(12, cast length() / 2);
				[for(i in 0...steps) getPoint(1.0*i/steps)];
			default:
				var steps = hxd.Math.imax(2, cast length() / 4);
				[for(i in 0...steps) getPoint(1.0*i/steps)];
		}
		
	}

	public function length():Float {
		function estimate(steps:Int) {
			var length = 0.;
			var lastPoint = start;
			for (i in 1...steps + 1) {
				var point = getPoint(i / steps);
				length += hxd.Math.distance(lastPoint.x - point.x, lastPoint.y - point.y);
				lastPoint = point;
			}
			return length;
		}

		return switch path {
			case Line:
				hxd.Math.distance(start.x - end.x, start.y - end.y);
			case Arc(center, startAngle, radius, angleDelta):
				var angleDeltaRad = hxd.Math.degToRad(angleDelta);
				radius * Math.abs(angleDeltaRad);
			case Bezier3(control1, control2, control3):
				estimate(8);
			case Bezier4(control1, control2, control3, control4):
				estimate(12);
			case Spiral(center, startAngle, radiusStart, radiusEnd, angleDelta):
				estimate(16);
			case Wave(amplitude, wavelength, count, dirAngle):
				estimate(cast hxd.Math.imax(16, Math.ceil(count * 8)));
			case Checkpoint(_): 0;
		}
	}

	public function getEndpoint():FPoint {
		return end;
	}

	/** Create a transformed copy: scale, rotate, then translate all points. */
	public function transform(cosA:Float, sinA:Float, scale:Float, tx:Float, ty:Float):SinglePath {
		inline function tp(p:FPoint):FPoint {
			final sx = p.x * scale;
			final sy = p.y * scale;
			return new FPoint(sx * cosA - sy * sinA + tx, sx * sinA + sy * cosA + ty);
		}

		final newStart = tp(start);
		final newEnd = tp(end);
		final newPath:PathType = switch path {
			case Checkpoint(name): Checkpoint(name);
			case Line: Line;
			case Arc(center, startAngle, radius, angleDelta):
				final rotation = Math.atan2(sinA, cosA);
				Arc(tp(center), startAngle + rotation, radius * scale, angleDelta);
			case Bezier3(c1, c2, c3): Bezier3(tp(c1), tp(c2), tp(c3));
			case Bezier4(c1, c2, c3, c4): Bezier4(tp(c1), tp(c2), tp(c3), tp(c4));
			case Spiral(center, startAngle, radiusStart, radiusEnd, angleDelta):
				final rotation = Math.atan2(sinA, cosA);
				Spiral(tp(center), startAngle + rotation, radiusStart * scale, radiusEnd * scale, angleDelta);
			case Wave(amplitude, wavelength, count, dirAngle):
				final rotation = Math.atan2(sinA, cosA);
				Wave(amplitude * scale, wavelength * scale, count, dirAngle + rotation);
		};
		return new SinglePath(newStart, newEnd, newPath);
	}
}
