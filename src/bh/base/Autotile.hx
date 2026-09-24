package bh.base;

private typedef FallbackCandidate = {tile:Int, cardinals:Int, mismatch:Int, corners:Int, order:Int};

/**
 * Index math for autotile terrain generation.
 *
 * Three formats:
 * - Cross (13 tiles): one tile per filled cell; 4 edges + center + 4 outer + 4 inner corners.
 * - Blob47 (47 tiles): one tile per filled cell; every 8-neighbour combination (a diagonal only
 *   counts when both adjacent cardinals are present).
 * - Corner (16 tiles): dual grid. One tile per grid-cell *corner*, offset by half a tile; the index
 *   says which of the 4 cells around that corner are filled (NW=1, NE=2, SW=4, SE=8). Covers every
 *   configuration (isolated cells, 1-wide strips, diagonal touches) with no fallback. Index 0
 *   (no filled cell) is never drawn.
 *
 * Grid convention: `grid[y][x]`, any non-zero value = terrain present. Out-of-range cells
 * (including ragged rows) count as empty.
 *
 * Neighbor bit flags (8-direction, cross/blob47):
 * - N  = 1   (bit 0)
 * - NE = 2   (bit 1)
 * - E  = 4   (bit 2)
 * - SE = 8   (bit 3)
 * - S  = 16  (bit 4)
 * - SW = 32  (bit 5)
 * - W  = 64  (bit 6)
 * - NW = 128 (bit 7)
 */
class Autotile {
	// 8-direction neighbor bit flags
	public static inline var N:Int = 1;
	public static inline var NE:Int = 2;
	public static inline var E:Int = 4;
	public static inline var SE:Int = 8;
	public static inline var S:Int = 16;
	public static inline var SW:Int = 32;
	public static inline var W:Int = 64;
	public static inline var NW:Int = 128;

	// 4-direction neighbor bit flags (for simple checks)
	public static inline var N4:Int = 1;
	public static inline var E4:Int = 2;
	public static inline var S4:Int = 4;
	public static inline var W4:Int = 8;

	// Corner-format bits: which cell around a grid corner is filled
	public static inline var CORNER_NW:Int = 1;
	public static inline var CORNER_NE:Int = 2;
	public static inline var CORNER_SW:Int = 4;
	public static inline var CORNER_SE:Int = 8;

	public static inline var CROSS_TILE_COUNT:Int = 13;
	public static inline var BLOB47_TILE_COUNT:Int = 47;
	public static inline var CORNER_TILE_COUNT:Int = 16;

	/** True when `grid[y][x]` exists and is non-zero. */
	public static inline function isFilled(grid:Array<Array<Int>>, x:Int, y:Int):Bool {
		return y >= 0 && y < grid.length && x >= 0 && x < grid[y].length && grid[y][x] != 0;
	}

	/** Width of the widest row. */
	public static function gridWidth(grid:Array<Array<Int>>):Int {
		var w = 0;
		for (row in grid)
			if (row.length > w)
				w = row.length;
		return w;
	}

	/**
	 * Calculate 8-direction neighbor bitmask from a grid at position (x, y).
	 * @param grid 2D array where non-zero = terrain present
	 * @return 8-bit neighbor mask
	 */
	public static function getNeighborMask8(grid:Array<Array<Int>>, x:Int, y:Int):Int {
		var mask = 0;
		if (isFilled(grid, x, y - 1)) mask |= N;
		if (isFilled(grid, x + 1, y - 1)) mask |= NE;
		if (isFilled(grid, x + 1, y)) mask |= E;
		if (isFilled(grid, x + 1, y + 1)) mask |= SE;
		if (isFilled(grid, x, y + 1)) mask |= S;
		if (isFilled(grid, x - 1, y + 1)) mask |= SW;
		if (isFilled(grid, x - 1, y)) mask |= W;
		if (isFilled(grid, x - 1, y - 1)) mask |= NW;
		return mask;
	}

	/**
	 * Calculate 4-direction neighbor bitmask from a grid at position (x, y).
	 * @return 4-bit neighbor mask (N=1, E=2, S=4, W=8)
	 */
	public static function getNeighborMask4(grid:Array<Array<Int>>, x:Int, y:Int):Int {
		var mask = 0;
		if (isFilled(grid, x, y - 1)) mask |= N4;
		if (isFilled(grid, x + 1, y)) mask |= E4;
		if (isFilled(grid, x, y + 1)) mask |= S4;
		if (isFilled(grid, x - 1, y)) mask |= W4;
		return mask;
	}

	/**
	 * Corner-format index for the grid corner at (cornerX, cornerY), where corner (cx, cy) is the
	 * top-left corner of cell (cx, cy). Valid corners run 0..width x 0..height (one more than cells).
	 * @return 0-15: NW=1 | NE=2 | SW=4 | SE=8 for each filled cell around the corner
	 */
	public static function getCornerIndex(grid:Array<Array<Int>>, cornerX:Int, cornerY:Int):Int {
		var index = 0;
		if (isFilled(grid, cornerX - 1, cornerY - 1)) index |= CORNER_NW;
		if (isFilled(grid, cornerX, cornerY - 1)) index |= CORNER_NE;
		if (isFilled(grid, cornerX - 1, cornerY)) index |= CORNER_SW;
		if (isFilled(grid, cornerX, cornerY)) index |= CORNER_SE;
		return index;
	}

	/**
	 * Get Cross format tile index from an 8-direction neighbor mask.
	 *
	 * Layout:
	 * ```
	 *       0=N
	 * 1=W   2=C   3=E
	 *       4=S
	 * 5=NW  6=NE  7=SW  8=SE (outer corners)
	 * 9=inner-NE  10=inner-NW  11=inner-SE  12=inner-SW
	 * ```
	 * Edge tiles are named after the side that has NO neighbour (the border side); inner-XX means
	 * all four cardinals present but the XX diagonal missing. The 13-tile set cannot express
	 * isolated cells, 1-wide strips or several missing diagonals — those resolve to the center tile
	 * or the first missing diagonal. Use `corner` or `blob47` when that matters.
	 *
	 * @param mask8 8-direction neighbor bitmask
	 * @return Tile index 0-12
	 */
	public static function getCrossIndex(mask8:Int):Int {
		final hasN = (mask8 & N) != 0;
		final hasE = (mask8 & E) != 0;
		final hasS = (mask8 & S) != 0;
		final hasW = (mask8 & W) != 0;
		final hasNE = (mask8 & NE) != 0;
		final hasSE = (mask8 & SE) != 0;
		final hasSW = (mask8 & SW) != 0;
		final hasNW = (mask8 & NW) != 0;

		// Inner corners (all cardinal directions, missing diagonal)
		if (hasN && hasE && hasS && hasW) {
			if (!hasNE)
				return 9;
			if (!hasNW)
				return 10;
			if (!hasSE)
				return 11;
			if (!hasSW)
				return 12;
			return 2; // center
		}

		// Outer corners (two adjacent cardinals missing)
		if (!hasN && !hasW && hasS && hasE)
			return 5; // NW outer
		if (!hasN && !hasE && hasS && hasW)
			return 6; // NE outer
		if (!hasS && !hasW && hasN && hasE)
			return 7; // SW outer
		if (!hasS && !hasE && hasN && hasW)
			return 8; // SE outer

		// Edges (one cardinal missing)
		if (!hasN && hasS)
			return 0; // N edge
		if (!hasW && hasE)
			return 1; // W edge
		if (!hasE && hasW)
			return 3; // E edge
		if (!hasS && hasN)
			return 4; // S edge

		// Default center
		return 2;
	}

	/**
	 * Blob47 lookup table mapping 256 possible neighbor combinations to 47 unique tiles.
	 * Index is the 8-bit neighbor mask, value is the tile index (0-46).
	 */
	private static var blob47LUT:Array<Int> = null;

	/**
	 * Reverse lookup: tile index (0-46) -> reduced 8-bit mask. Tile indices are the 47 reduced masks
	 * in ascending order (NOT a pictorial tileset layout — real tilesets need a `mapping:`).
	 */
	private static final blob47ReverseLUT:Array<Int> = [
		0, 1, 4, 5, 7, 16, 17, 20, 21, 23, 28, 29, 31,        // 0-12
		64, 65, 68, 69, 71, 80, 81, 84, 85, 87, 92, 93, 95,    // 13-25
		112, 113, 116, 117, 119, 124, 125, 127,                  // 26-33
		193, 197, 199, 209, 213, 215, 221, 223, 241, 245, 247, 253, 255 // 34-46
	];

	/**
	 * Get Blob47 tile index from 8-direction neighbor mask.
	 * @param mask8 8-direction neighbor bitmask
	 * @return Tile index 0-46
	 */
	public static function getBlob47Index(mask8:Int):Int {
		if (blob47LUT == null)
			initBlob47LUT();
		return blob47LUT[mask8];
	}

	/**
	 * Reduced neighbor mask a blob47 tile stands for (inverse of `getBlob47Index`).
	 * Only diagonals whose two adjacent cardinals are present can be set.
	 */
	public static function getBlob47Mask(tileIndex:Int):Int {
		return blob47ReverseLUT[tileIndex];
	}

	/**
	 * Fallback for a blob47 tile that has no entry in `mapping`: the closest mapped tile.
	 * Same algorithm as `getBlob47FallbackChain(...).result` (the two used to be separate
	 * implementations that could tie-break differently).
	 * @return a mapped tile index, or `tileIndex` itself when nothing in the mapping fits
	 */
	public static function applyBlob47FallbackWithMap(tileIndex:Int, mapping:Map<Int, Int>):Int {
		return getBlob47FallbackChain(tileIndex, mapping).result;
	}

	/**
	 * Get the full fallback chain for a blob47 tile.
	 *
	 * Search order:
	 * 1. Same cardinals; diagonals closest to the wanted ones first (fewest mismatched diagonals,
	 *    then more diagonals - a missing notch reads better than a stray one).
	 * 2. Drop cardinals one at a time, ranked the same way.
	 * 3. The full tile (46), then the isolated tile (0).
	 *
	 * Returns {result: actual fallback tile, skipped: tiles tried but not mapped (in order of priority)}.
	 * If the tile is directly mapped, result == tileIndex and skipped is empty. If nothing fits,
	 * result == tileIndex (and it is not in the mapping).
	 */
	public static function getBlob47FallbackChain(tileIndex:Int, mapping:Map<Int, Int>):{result:Int, skipped:Array<Int>} {
		if (blob47LUT == null)
			initBlob47LUT();
		if (mapping.exists(tileIndex))
			return {result: tileIndex, skipped: []};

		final skipped:Array<Int> = [];
		final mask = blob47ReverseLUT[tileIndex];
		final allCardinals = mask & (N | E | S | W);
		final cardinalBits:Array<Int> = [];
		if ((allCardinals & N) != 0) cardinalBits.push(N);
		if ((allCardinals & E) != 0) cardinalBits.push(E);
		if ((allCardinals & S) != 0) cardinalBits.push(S);
		if ((allCardinals & W) != 0) cardinalBits.push(W);

		// Phase 1: Same cardinals, every diagonal combination
		final phase1:Array<FallbackCandidate> = [];
		addCornerCandidates(allCardinals, mask, tileIndex, phase1, new Map());
		for (candidate in sortCandidates(phase1)) {
			if (mapping.exists(candidate)) return {result: candidate, skipped: skipped};
			skipped.push(candidate);
		}

		// Phase 2: Remove cardinals progressively
		for (removeCount in 1...cardinalBits.length) {
			final phase2:Array<FallbackCandidate> = [];
			final seen = new Map<Int, Bool>();
			combineRemovals(cardinalBits, cardinalBits.length, removeCount, 0, 0, removeMask -> {
				addCornerCandidates(allCardinals & ~removeMask, mask, tileIndex, phase2, seen);
			});
			for (candidate in sortCandidates(phase2)) {
				if (mapping.exists(candidate)) return {result: candidate, skipped: skipped};
				if (skipped.indexOf(candidate) < 0) skipped.push(candidate);
			}
		}

		// Phase 3: Full tile or empty tile
		if (tileIndex != 46) {
			if (mapping.exists(46)) return {result: 46, skipped: skipped};
			if (skipped.indexOf(46) < 0) skipped.push(46);
		}
		if (tileIndex != 0) {
			if (mapping.exists(0)) return {result: 0, skipped: skipped};
			if (skipped.indexOf(0) < 0) skipped.push(0);
		}

		return {result: tileIndex, skipped: skipped};
	}

	/** Add one candidate per diagonal combination valid for `cardinals` (tiles already seen are skipped). */
	private static function addCornerCandidates(cardinals:Int, wantedMask:Int, skipTile:Int, out:Array<FallbackCandidate>, seen:Map<Int, Bool>):Void {
		final cornerBits:Array<Int> = [];
		if ((cardinals & N) != 0 && (cardinals & E) != 0) cornerBits.push(NE);
		if ((cardinals & S) != 0 && (cardinals & E) != 0) cornerBits.push(SE);
		if ((cardinals & S) != 0 && (cardinals & W) != 0) cornerBits.push(SW);
		if ((cardinals & N) != 0 && (cardinals & W) != 0) cornerBits.push(NW);

		final wantedCorners = wantedMask & (NE | SE | SW | NW);
		for (subset in 0...(1 << cornerBits.length)) {
			var tryMask = cardinals;
			for (ci in 0...cornerBits.length)
				if ((subset & (1 << ci)) != 0)
					tryMask |= cornerBits[ci];
			final tryTile = blob47LUT[tryMask];
			if (tryTile == skipTile || seen.exists(tryTile))
				continue;
			seen.set(tryTile, true);
			final corners = tryMask & (NE | SE | SW | NW);
			out.push({
				tile: tryTile,
				cardinals: bitCount(cardinals),
				mismatch: bitCount(corners ^ wantedCorners),
				corners: bitCount(corners),
				order: out.length
			});
		}
	}

	/** More cardinals, fewer mismatched diagonals, more diagonals, then enumeration order (explicit, so sort stability does not matter). */
	private static function sortCandidates(candidates:Array<FallbackCandidate>):Array<Int> {
		candidates.sort((a, b) -> {
			if (a.cardinals != b.cardinals) return b.cardinals - a.cardinals;
			if (a.mismatch != b.mismatch) return a.mismatch - b.mismatch;
			if (a.corners != b.corners) return b.corners - a.corners;
			return a.order - b.order;
		});
		return [for (c in candidates) c.tile];
	}

	private static inline function bitCount(v:Int):Int {
		var count = 0;
		var x = v;
		while (x != 0) {
			count += x & 1;
			x >>>= 1;
		}
		return count;
	}

	private static function combineRemovals(bits:Array<Int>, n:Int, k:Int, start:Int, mask:Int, cb:(Int) -> Void):Void {
		if (k == 0) {
			cb(mask);
			return;
		}
		for (i in start...n) {
			combineRemovals(bits, n, k - 1, i + 1, mask | bits[i], cb);
		}
	}

	/**
	 * Initialize the Blob47 lookup table.
	 * Maps all 256 possible 8-neighbor combinations to 47 unique tile indices.
	 */
	private static function initBlob47LUT():Void {
		// Every reduced mask is one of the 47 entries, so indexOf never returns -1.
		blob47LUT = [for (mask in 0...256) blob47ReverseLUT.indexOf(reduceBlob47Mask(mask))];
	}

	/** Drop diagonals whose two adjacent cardinals are not both present. */
	private static function reduceBlob47Mask(mask:Int):Int {
		var reduced = mask & (N | E | S | W);
		if ((mask & NE) != 0 && (mask & N) != 0 && (mask & E) != 0) reduced |= NE;
		if ((mask & SE) != 0 && (mask & S) != 0 && (mask & E) != 0) reduced |= SE;
		if ((mask & SW) != 0 && (mask & S) != 0 && (mask & W) != 0) reduced |= SW;
		if ((mask & NW) != 0 && (mask & N) != 0 && (mask & W) != 0) reduced |= NW;
		return reduced;
	}

	/**
	 * Helper to check if a specific direction is present in a mask.
	 */
	public static inline function hasDirection(mask:Int, dir:Int):Bool {
		return (mask & dir) != 0;
	}
}
