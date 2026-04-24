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
		if (cardCount <= 0)
			return [];

		var result:Array<CardLayoutPosition> = [];

		if (cardCount == 1) {
			// Single card centered, no rotation
			var pop = if (hoverIndex == 0) hoverPopDistance else 0.0;
			var s = if (hoverIndex == 0) hoverScale else 1.0;
			result.push({x: anchorX, y: anchorY - pop, rotation: 0.0, scale: s, normalX: 0.0, normalY: -1.0});
			return result;
		}

		var maxAngleRad = maxAngleDeg * Math.PI / 180.0;
		// Limit per-card angle to prevent wide spread with few cards
		var maxPerCardDeg = 8.0;
		var maxPerCardRad = maxPerCardDeg * Math.PI / 180.0;
		var angleStep = Math.min(maxAngleRad / (cardCount - 1), maxPerCardRad);
		var totalArc = angleStep * (cardCount - 1);
		var halfArc = totalArc / 2.0;

		var neighborSpreadRad = neighborSpreadDeg * Math.PI / 180.0;

		for (i in 0...cardCount) {
			var baseAngle = -halfArc + i * angleStep;

			// Push neighbors apart if hovering
			var angle = baseAngle;
			if (hoverIndex >= 0 && i != hoverIndex) {
				if (i < hoverIndex) {
					// Cards to the left get pushed left
					var dist = hoverIndex - i;
					var spread = neighborSpreadRad / dist;
					angle -= spread;
				} else {
					// Cards to the right get pushed right
					var dist = i - hoverIndex;
					var spread = neighborSpreadRad / dist;
					angle += spread;
				}
			}

			// Position on arc: center of arc is at (anchorX, anchorY + radius)
			var x = anchorX + radius * Math.sin(angle);
			var y = anchorY + radius - radius * Math.cos(angle);

			var scale = 1.0;
			var pop = 0.0;

			if (i == hoverIndex) {
				pop = hoverPopDistance;
				scale = hoverScale;
			}

			// Pop direction is along the normal toward arc center (straight up for small angles)
			var normalAngle = angle;
			x -= pop * Math.sin(normalAngle);
			y -= pop * Math.cos(normalAngle);

			result.push({
				x: x,
				y: y,
				rotation: angle,
				scale: scale,
				normalX: -Math.sin(angle),
				normalY: -Math.cos(angle)
			});
		}

		return result;
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
		if (cardCount <= 0)
			return [];

		var result:Array<CardLayoutPosition> = [];

		// Calculate effective spacing: compress if total width exceeds maxWidth
		var totalWidth = cardCount * cardWidth + (cardCount - 1) * spacing;
		var effectiveStep = cardWidth + spacing;
		if (totalWidth > maxWidth && cardCount > 1) {
			effectiveStep = (maxWidth - cardWidth) / (cardCount - 1);
		}

		var startX = anchorX - (cardCount - 1) * effectiveStep / 2.0;

		for (i in 0...cardCount) {
			var x = startX + i * effectiveStep;
			var y = anchorY;

			// Push neighbors apart if hovering
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

			result.push({
				x: x,
				y: y,
				rotation: 0.0,
				scale: scale,
				normalX: 0.0,
				normalY: -1.0
			});
		}

		return result;
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
		if (cardCount <= 0)
			return [];

		var result:Array<CardLayoutPosition> = [];

		// Compute base rates for each card
		var rates:Array<Float> = [];
		if (cardCount == 1) {
			rates.push(0.5); // center single card
		} else {
			switch (distribution) {
				case EvenRate:
					for (i in 0...cardCount)
						rates.push(i / (cardCount - 1));
				case EvenArcLength:
					rates = computeEvenArcLengthRates(path, cardCount);
			}
		}

		// Shift neighbors apart when hovering
		if (hoverIndex >= 0 && hoverIndex < cardCount) {
			var adjustedRates = rates.copy();
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

		// Compute positions
		for (i in 0...cardCount) {
			var rate = rates[i];
			path.getPointInto(rate, _scratch);
			var tangent = path.getTangentAngle(rate);

			// Normal perpendicular to tangent (pointing "outward" — left-hand normal)
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

			result.push({
				x: x,
				y: y,
				rotation: rotation,
				scale: scale,
				normalX: nrmX,
				normalY: nrmY
			});
		}

		return result;
	}

	/** Compute evenly arc-length spaced rates along a path using lookup table + binary search. */
	static function computeEvenArcLengthRates(path:Path, cardCount:Int):Array<Float> {
		// Build cumulative arc-length lookup table
		final sampleCount = 100;
		var sampleRates:Array<Float> = [];
		var sampleLengths:Array<Float> = [];
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
		var rates:Array<Float> = [];

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
