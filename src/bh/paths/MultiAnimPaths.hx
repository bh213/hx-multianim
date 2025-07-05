package bh.paths;

import bh.multianim.CoordinateSystems;
import bh.multianim.CoordinateSystems.Coordinates;
import bh.multianim.MultiAnimParser;
import bh.multianim.MultiAnimBuilder;
import bh.base.FPoint;

using tweenxcore.Tools;

enum PathType {
	Checkpoint(name:String);
	Line;
	Arc(center:FPoint, startAngle:Float, radius:Float, angleDelta:Float);
	Bezier2(control:FPoint);
	Bezier3(control1:FPoint, control2:FPoint);
}

@:nullSafety
class MultiAnimPaths {
	final pathDefs:PathsDef;
	final builder:MultiAnimBuilder;

	public function new(pathDefs:PathsDef, builder:MultiAnimBuilder) {
		this.pathDefs = pathDefs;
		this.builder = builder;
	}

	public function getPath(name:String, ?startPoint:FPoint, ?startAngle:Float, ?endPoint:FPoint):Path {
		final oldIndexed = builder.indexedParams;
		
		var newIndexedParams:Map<String, ResolvedIndexParameters> = [];
		if (startPoint != null) {
			newIndexedParams.set("startX", ValueF(startPoint.x));
			newIndexedParams.set("startY", ValueF(startPoint.y));
		}
		if (endPoint != null) {
			newIndexedParams.set("endX", ValueF(endPoint.x));
			newIndexedParams.set("endY", ValueF(endPoint.y));
		}
		if (startAngle != null) {
			newIndexedParams.set("startAngle", ValueF(startAngle));
		}


		builder.indexedParams = newIndexedParams;
		
		var gridCoordinateSystem:Null<GridCoordinateSystem> = null;
		var hexCoordinateSystem:Null<HexCoordinateSystem> = null;

		inline function resolveCoordinate(pos:Coordinates):FPoint {
			return builder.calculatePosition(pos, gridCoordinateSystem, hexCoordinateSystem);
		}

		inline function resolveNumber(value:ReferencableValue):Float {
			return builder.resolveAsNumber(value);
		}

		final def = pathDefs.get(name);
		if (def == null)
			throw 'path not found: $name';

		var singlePaths:Array<SinglePath> = [];
		var point = startPoint ?? new FPoint(0, 0);
		var angle:Float = startAngle != null ? hxd.Math.degToRad(startAngle) : 0.;

		for (path in def) {
			switch path {
				case LineTo(end):
					var end = resolveCoordinate(end);
					singlePaths.push(new SinglePath(point, end, Line));
					angle = hxd.Math.atan2(end.y - point.y, end.x - point.x);
					point = end;

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
					var perpAngle = angle + (angleDeltaF > 0 ? Math.PI / 2 : -Math.PI / 2);
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
					angle += angleDeltaRad;
					point = end;

				case Checkpoint(name):
					singlePaths.push(new SinglePath(point, point, Checkpoint(name)));

				case Bezier2To(end, control):
					var end = resolveCoordinate(end);
					var control = resolveCoordinate(control);
					singlePaths.push(new SinglePath(point, end, Bezier2(control)));
					// For quadratic bezier, the tangent at the end point is from control point to end point
					angle = hxd.Math.atan2(end.y - control.y, end.x - control.x);
					point = end;

				case Bezier3To(end, control1, control2):
					var end = resolveCoordinate(end);
					var control1 = resolveCoordinate(control1);
					var control2 = resolveCoordinate(control2);
					singlePaths.push(new SinglePath(point, end, Bezier3(control1, control2)));
					// For cubic bezier, the tangent at the end point is from control2 to end point
					angle = hxd.Math.atan2(end.y - control2.y, end.x - control2.x);
					point = end;
			}
		}

		builder.indexedParams = oldIndexed;
		return new Path(singlePaths);
	}
}	
	




@:allow(bh.paths.MultiAnimPaths)
class Path {
	final singlePaths:Array<SinglePath>;
	final checkpoints:Map<String, Float> = [];
	public final totalLength:Float;

	public function new(singlePaths:Array<SinglePath>) {
		this.singlePaths = singlePaths;
		var currentLength = 0.;

		for (singlePath in singlePaths) {
			final startOffset = currentLength;
			currentLength += singlePath.length();
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
		throw 'rate out of range: $rate';
	}

}

@:allow(bh.paths.MultiAnimPaths)
private class SinglePath {
	var startRange:Float = Math.NaN;
	var endRange:Float = Math.NaN;

	var path:PathType;
	var start:FPoint;
	var end:FPoint;

	function new(start:FPoint, end:FPoint, path:PathType) {
		this.start = start;
		this.end = end;
		this.path = path;
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
			case Bezier2(control1):
				return new FPoint(rate.bezier2(start.x, control1.x, end.x),
					rate.bezier2(start.y, control1.y, end.y));
			case Bezier3(control1, control2):
				return new FPoint(rate.bezier3(start.x, control1.x, control2.x, end.x),
					rate.bezier3(start.y, control1.y, control2.y, end.y));
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
			case Bezier2(control):
				estimate(4);
			case Bezier3(control1, control2):
				estimate(8);
			case Checkpoint(_): 0;
		}
	}
}
