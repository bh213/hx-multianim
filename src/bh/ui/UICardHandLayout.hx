package bh.ui;

import bh.base.FPoint;
import bh.paths.MultiAnimPaths.Path;
import bh.ui.UICardHandTypes.CardLayoutPosition;
import bh.ui.UICardHandTypes.PathDistribution;
import bh.ui.UICardHandTypes.PathOrientation;

/** Pure math for card hand layout calculation. No scene graph dependency. */
class UICardHandLayout {
	/** Shared scratch point for path sampling; HL is single-threaded so sharing is safe. */
	static final _scratch:FPoint = new FPoint(0, 0);

	/** Counts internal scratch-array allocations performed by the path-layout hot path.
	 *  Pure instrumentation — does not affect behavior. Should remain unchanged across
	 *  repeated computePathLayout calls (scratch arrays must be reused).
	 *  Gated behind MULTIANIM_ALLOC_TRACK so the field disappears from production builds. */
	#if MULTIANIM_ALLOC_TRACK
	public static var scratchArrayAllocationCount:Int = 0;
	#end

	// Reusable work buffers for computePathLayout / computeEvenArcLengthRates. HL is
	// single-threaded so static sharing is safe — same pattern as `_scratch:FPoint`.
	// Cleared with resize(0) on entry; capacity is retained across calls.
	static final _scratchSampleRates:Array<Float> = [];
	static final _scratchSampleLengths:Array<Float> = [];
	static final _scratchRates:Array<Float> = [];
	static final _scratchAdjustedRates:Array<Float> = [];

	// Grows `out` to length `n`, allocating fresh CardLayoutPosition instances only
	// when the buffer hasn't seen this size before. Existing entries are reused in
	// place; the layout `Into` callers fully overwrite every field of each entry.
	static inline function ensureSize(out:Array<CardLayoutPosition>, n:Int):Void {
		if (out.length < n) {
			while (out.length < n)
				out.push(new CardLayoutPosition());
		} else if (out.length > n) {
			out.resize(n);
		}
	}

	static inline function writePos(p:CardLayoutPosition, x:Float, y:Float, rotation:Float, scale:Float, normalX:Float, normalY:Float):Void {
		p.x = x;
		p.y = y;
		p.rotation = rotation;
		p.scale = scale;
		p.normalX = normalX;
		p.normalY = normalY;
	}

	/** Compute layout positions for N cards in fan arc arrangement.
	 *  Arc center is at (anchorX, anchorY + radius), cards sit on the arc above it.
	 *  @param cardCount Number of cards
	 *  @param anchorX Center X of hand area
	 *  @param anchorY Bottom Y of hand area
	 *  @param radius Arc radius in pixels
	 *  @param maxAngleDeg Maximum total spread angle in degrees
	 *  @param hoverIndex Index of hovered card (-1 for none)
	 *  @param hoverPopDistance Pixels to pop hovered card toward arc center
	 *  @param hoverScale Scale factor for hovered card
	 *  @param neighborSpreadDeg Extra degrees to push neighbors of hovered card
	 *  @return Array of CardLayoutPosition, one per card */
	public static function computeFanLayout(cardCount:Int, anchorX:Float, anchorY:Float, radius:Float, maxAngleDeg:Float,
			hoverIndex:Int, hoverPopDistance:Float, hoverScale:Float, neighborSpreadDeg:Float):Array<CardLayoutPosition> {
		var result:Array<CardLayoutPosition> = [];
		computeFanLayoutInto(result, cardCount, anchorX, anchorY, radius, maxAngleDeg, hoverIndex, hoverPopDistance, hoverScale, neighborSpreadDeg);
		return result;
	}

	/** Buffer-filling variant of computeFanLayout for hot-path callers (hover hit-test).
	 *  Resizes `out` to cardCount and mutates entries in place; existing CardLayoutPosition
	 *  instances are reused, only the tail is allocated when the buffer grows. */
	public static function computeFanLayoutInto(out:Array<CardLayoutPosition>, cardCount:Int, anchorX:Float, anchorY:Float, radius:Float,
			maxAngleDeg:Float, hoverIndex:Int, hoverPopDistance:Float, hoverScale:Float, neighborSpreadDeg:Float):Void {
		if (cardCount <= 0) {
			out.resize(0);
			return;
		}
		ensureSize(out, cardCount);

		if (cardCount == 1) {
			var pop = if (hoverIndex == 0) hoverPopDistance else 0.0;
			var s = if (hoverIndex == 0) hoverScale else 1.0;
			writePos(out[0], anchorX, anchorY - pop, 0.0, s, 0.0, -1.0);
			return;
		}

		var maxAngleRad = maxAngleDeg * Math.PI / 180.0;
		var maxPerCardDeg = 8.0;
		var maxPerCardRad = maxPerCardDeg * Math.PI / 180.0;
		var angleStep = Math.min(maxAngleRad / (cardCount - 1), maxPerCardRad);
		var totalArc = angleStep * (cardCount - 1);
		var halfArc = totalArc / 2.0;

		var neighborSpreadRad = neighborSpreadDeg * Math.PI / 180.0;

		for (i in 0...cardCount) {
			var baseAngle = -halfArc + i * angleStep;

			var angle = baseAngle;
			if (hoverIndex >= 0 && i != hoverIndex) {
				if (i < hoverIndex) {
					var dist = hoverIndex - i;
					var spread = neighborSpreadRad / dist;
					angle -= spread;
				} else {
					var dist = i - hoverIndex;
					var spread = neighborSpreadRad / dist;
					angle += spread;
				}
			}

			var x = anchorX + radius * Math.sin(angle);
			var y = anchorY + radius - radius * Math.cos(angle);

			var scale = 1.0;
			var pop = 0.0;

			if (i == hoverIndex) {
				pop = hoverPopDistance;
				scale = hoverScale;
			}

			var normalAngle = angle;
			x -= pop * Math.sin(normalAngle);
			y -= pop * Math.cos(normalAngle);

			writePos(out[i], x, y, angle, scale, -Math.sin(angle), -Math.cos(angle));
		}
	}

	/** Compute layout positions for N cards in horizontal linear arrangement.
	 *  Cards are centered around anchorX.
	 *  @param cardCount Number of cards
	 *  @param anchorX Center X of hand area
	 *  @param anchorY Bottom Y of hand area
	 *  @param cardWidth Width of a single card
	 *  @param spacing Desired spacing between cards
	 *  @param maxWidth Maximum total width before cards overlap
	 *  @param hoverIndex Index of hovered card (-1 for none)
	 *  @param hoverPopDistance Pixels to pop hovered card upward
	 *  @param hoverScale Scale factor for hovered card
	 *  @param neighborSpread Pixels to push neighbors apart horizontally
	 *  @return Array of CardLayoutPosition, one per card */
	public static function computeLinearLayout(cardCount:Int, anchorX:Float, anchorY:Float, cardWidth:Float, spacing:Float,
			maxWidth:Float, hoverIndex:Int, hoverPopDistance:Float, hoverScale:Float, neighborSpread:Float):Array<CardLayoutPosition> {
		var result:Array<CardLayoutPosition> = [];
		computeLinearLayoutInto(result, cardCount, anchorX, anchorY, cardWidth, spacing, maxWidth, hoverIndex, hoverPopDistance, hoverScale,
			neighborSpread);
		return result;
	}

	/** Buffer-filling variant of computeLinearLayout for hot-path callers. */
	public static function computeLinearLayoutInto(out:Array<CardLayoutPosition>, cardCount:Int, anchorX:Float, anchorY:Float, cardWidth:Float,
			spacing:Float, maxWidth:Float, hoverIndex:Int, hoverPopDistance:Float, hoverScale:Float, neighborSpread:Float):Void {
		if (cardCount <= 0) {
			out.resize(0);
			return;
		}
		ensureSize(out, cardCount);

		var totalWidth = cardCount * cardWidth + (cardCount - 1) * spacing;
		var effectiveStep = cardWidth + spacing;
		if (totalWidth > maxWidth && cardCount > 1) {
			effectiveStep = (maxWidth - cardWidth) / (cardCount - 1);
		}

		var startX = anchorX - (cardCount - 1) * effectiveStep / 2.0;

		for (i in 0...cardCount) {
			var x = startX + i * effectiveStep;
			var y = anchorY;

			if (hoverIndex >= 0 && i != hoverIndex) {
				if (i < hoverIndex) {
					var dist = hoverIndex - i;
					x -= neighborSpread / dist;
				} else {
					var dist = i - hoverIndex;
					x += neighborSpread / dist;
				}
			}

			var scale = 1.0;
			if (i == hoverIndex) {
				y -= hoverPopDistance;
				scale = hoverScale;
			}

			writePos(out[i], x, y, 0.0, scale, 0.0, -1.0);
		}
	}

	/** Compute layout positions for N cards distributed along a path.
	 *  @param cardCount Number of cards
	 *  @param path Path to distribute cards along
	 *  @param distribution How to space cards along the path
	 *  @param orientation How to rotate cards relative to path tangent
	 *  @param hoverIndex Index of hovered card (-1 for none)
	 *  @param hoverPopDistance Pixels to pop hovered card along path normal
	 *  @param hoverScale Scale factor for hovered card
	 *  @param neighborSpreadRate Rate delta to push neighbors away from hovered card
	 *  @return Array of CardLayoutPosition, one per card */
	public static function computePathLayout(cardCount:Int, path:Path, distribution:PathDistribution, orientation:PathOrientation,
			hoverIndex:Int, hoverPopDistance:Float, hoverScale:Float, neighborSpreadRate:Float):Array<CardLayoutPosition> {
		var result:Array<CardLayoutPosition> = [];
		computePathLayoutInto(result, cardCount, path, distribution, orientation, hoverIndex, hoverPopDistance, hoverScale, neighborSpreadRate);
		return result;
	}

	/** Buffer-filling variant of computePathLayout for hot-path callers. */
	public static function computePathLayoutInto(out:Array<CardLayoutPosition>, cardCount:Int, path:Path, distribution:PathDistribution,
			orientation:PathOrientation, hoverIndex:Int, hoverPopDistance:Float, hoverScale:Float, neighborSpreadRate:Float):Void {
		if (cardCount <= 0) {
			out.resize(0);
			return;
		}
		ensureSize(out, cardCount);

		var rates = _scratchRates; rates.resize(0);
		if (cardCount == 1) {
			rates.push(0.5);
		} else {
			switch (distribution) {
				case EvenRate:
					for (i in 0...cardCount)
						rates.push(i / (cardCount - 1));
				case EvenArcLength:
					rates = computeEvenArcLengthRates(path, cardCount);
			}
		}

		if (hoverIndex >= 0 && hoverIndex < cardCount) {
			final adjustedRates = _scratchAdjustedRates; adjustedRates.resize(0);
			for (i in 0...cardCount)
				adjustedRates.push(rates[i]);
			for (i in 0...cardCount) {
				if (i == hoverIndex)
					continue;
				var dist = hoverIndex - i;
				if (dist < 0)
					dist = -dist;
				var shift = neighborSpreadRate / dist;
				if (i < hoverIndex)
					adjustedRates[i] = Math.max(0.0, rates[i] - shift);
				else
					adjustedRates[i] = Math.min(1.0, rates[i] + shift);
			}
			rates = adjustedRates;
		}

		for (i in 0...cardCount) {
			var rate = rates[i];
			path.getPointInto(rate, _scratch);
			var tangent = path.getTangentAngle(rate);

			var nrmX = -Math.sin(tangent);
			var nrmY = Math.cos(tangent);

			var x = _scratch.x;
			var y = _scratch.y;
			var scale = 1.0;

			if (i == hoverIndex) {
				x += nrmX * hoverPopDistance;
				y += nrmY * hoverPopDistance;
				scale = hoverScale;
			}

			var rotation:Float = switch (orientation) {
				case Tangent: tangent;
				case Straight: 0.0;
				case TangentClamped(maxDeg):
					var maxRad = maxDeg * Math.PI / 180.0;
					Math.max(-maxRad, Math.min(maxRad, tangent));
			};

			writePos(out[i], x, y, rotation, scale, nrmX, nrmY);
		}
	}

	/** Compute evenly arc-length spaced rates along a path using lookup table + binary search.
	 *  Returns a reused static scratch array — caller must consume it before the next
	 *  computePathLayout call. */
	static function computeEvenArcLengthRates(path:Path, cardCount:Int):Array<Float> {
		// Build cumulative arc-length lookup table
		final sampleCount = 100;
		final sampleRates = _scratchSampleRates; sampleRates.resize(0);
		final sampleLengths = _scratchSampleLengths; sampleLengths.resize(0);
		var cumLength:Float = 0.0;
		path.getPointInto(0.0, _scratch);
		var prevX:Float = _scratch.x;
		var prevY:Float = _scratch.y;

		sampleRates.push(0.0);
		sampleLengths.push(0.0);

		for (s in 1...sampleCount + 1) {
			var r = s / sampleCount;
			path.getPointInto(r, _scratch);
			var dx = _scratch.x - prevX;
			var dy = _scratch.y - prevY;
			cumLength += Math.sqrt(dx * dx + dy * dy);
			sampleRates.push(r);
			sampleLengths.push(cumLength);
			prevX = _scratch.x;
			prevY = _scratch.y;
		}

		var totalArcLength = cumLength;
		final rates = _scratchRates; rates.resize(0);

		for (i in 0...cardCount) {
			var targetLength = if (cardCount == 1) totalArcLength * 0.5 else i * totalArcLength / (cardCount - 1);

			// Binary search in sampleLengths
			var lo = 0;
			var hi = sampleCount;
			while (lo < hi) {
				var mid = (lo + hi) >> 1;
				if (sampleLengths[mid] < targetLength)
					lo = mid + 1;
				else
					hi = mid;
			}

			// Interpolate between lo-1 and lo
			if (lo == 0) {
				rates.push(0.0);
			} else {
				var segStart = sampleLengths[lo - 1];
				var segEnd = sampleLengths[lo];
				var segLen = segEnd - segStart;
				var t = if (segLen > 0.001) (targetLength - segStart) / segLen else 0.0;
				rates.push(sampleRates[lo - 1] + t * (sampleRates[lo] - sampleRates[lo - 1]));
			}
		}

		return rates;
	}
}
