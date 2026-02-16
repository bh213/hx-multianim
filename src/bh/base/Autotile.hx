package bh.base;

/**
 * Utility class for autotile terrain generation.
 *
 * Supports two formats:
 * - Cross: Cross layout + corners for elevation with depth (13 tiles)
 * - Blob47: Full 47-tile autotile with all edge/corner combinations
 *
 * Neighbor bit flags (8-direction):
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

	/**
	 * Calculate 8-direction neighbor bitmask from a binary grid at position (x, y).
	 * @param grid 2D array where 1 = terrain present, 0 = empty
	 * @param x X position in grid
	 * @param y Y position in grid
	 * @return 8-bit neighbor mask
	 */
	public static function getNeighborMask8(grid:Array<Array<Int>>, x:Int, y:Int):Int {
		final height = grid.length;
		if (height == 0)
			return 0;
		final width = grid[0].length;

		var mask = 0;

		// N (y-1)
		if (y > 0 && grid[y - 1][x] == 1)
			mask |= N;
		// NE (y-1, x+1)
		if (y > 0 && x < width - 1 && grid[y - 1][x + 1] == 1)
			mask |= NE;
		// E (x+1)
		if (x < width - 1 && grid[y][x + 1] == 1)
			mask |= E;
		// SE (y+1, x+1)
		if (y < height - 1 && x < width - 1 && grid[y + 1][x + 1] == 1)
			mask |= SE;
		// S (y+1)
		if (y < height - 1 && grid[y + 1][x] == 1)
			mask |= S;
		// SW (y+1, x-1)
		if (y < height - 1 && x > 0 && grid[y + 1][x - 1] == 1)
			mask |= SW;
		// W (x-1)
		if (x > 0 && grid[y][x - 1] == 1)
			mask |= W;
		// NW (y-1, x-1)
		if (y > 0 && x > 0 && grid[y - 1][x - 1] == 1)
			mask |= NW;

		return mask;
	}

	/**
	 * Calculate 4-direction neighbor bitmask from a binary grid at position (x, y).
	 * @param grid 2D array where 1 = terrain present, 0 = empty
	 * @param x X position in grid
	 * @param y Y position in grid
	 * @return 4-bit neighbor mask (N=1, E=2, S=4, W=8)
	 */
	public static function getNeighborMask4(grid:Array<Array<Int>>, x:Int, y:Int):Int {
		final height = grid.length;
		if (height == 0)
			return 0;
		final width = grid[0].length;

		var mask = 0;

		if (y > 0 && grid[y - 1][x] == 1)
			mask |= N4; // N
		if (x < width - 1 && grid[y][x + 1] == 1)
			mask |= E4; // E
		if (y < height - 1 && grid[y + 1][x] == 1)
			mask |= S4; // S
		if (x > 0 && grid[y][x - 1] == 1)
			mask |= W4; // W

		return mask;
	}

	/**
	 * Get Cross format tile index from 4-direction neighbor mask.
	 *
	 * Layout:
	 * ```
	 *       0=N
	 * 1=W   2=C   3=E
	 *       4=S
	 * 5=NW  6=NE  7=SW  8=SE (outer corners)
	 * 9=inner-NE  10=inner-NW  11=inner-SE  12=inner-SW
	 * ```
	 *
	 * @param mask8 8-direction neighbor bitmask
	 * @return Tile index
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

	/** Reverse lookup: tile index (0-46) -> reduced 8-bit mask */
	private static var blob47ReverseLUT:Array<Int> = null;

	/**
	 * Blob47 fallback lookup table. For each tile index, gives the next simpler tile
	 * (same cardinal directions but with one fewer corner).
	 * Used when a tileset doesn't have all 47 tiles.
	 */
	private static var blob47FallbackLUT:Array<Int> = null;

	/**
	 * Get Blob47 tile index from 8-direction neighbor mask.
	 * Uses a lookup table to map 256 possible combinations to 47 unique tiles.
	 *
	 * @param mask8 8-direction neighbor bitmask
	 * @return Tile index 0-46
	 */
	public static function getBlob47Index(mask8:Int):Int {
		if (blob47LUT == null) {
			initBlob47LUT();
		}
		return blob47LUT[mask8];
	}

	/**
	 * Get Blob47 tile index with fallback for missing tiles.
	 * If the ideal tile index >= maxTiles, falls back to a simpler tile
	 * by progressively removing corner requirements.
	 *
	 * @param mask8 8-direction neighbor bitmask
	 * @param maxTiles Number of available tiles (e.g., 16 for a minimal set)
	 * @return Tile index that is guaranteed to be < maxTiles
	 */
	public static function getBlob47IndexWithFallback(mask8:Int, maxTiles:Int):Int {
		if (blob47LUT == null) {
			initBlob47LUT();
		}
		return applyBlob47Fallback(blob47LUT[mask8], maxTiles);
	}

	/**
	 * Apply fallback to a blob47 tile index.
	 * If tileIndex >= maxTiles, falls back to simpler tiles until one exists.
	 *
	 * @param tileIndex The original tile index (0-46)
	 * @param maxTiles Number of available tiles
	 * @return Tile index that is guaranteed to be < maxTiles
	 */
	public static function applyBlob47Fallback(tileIndex:Int, maxTiles:Int):Int {
		if (blob47FallbackLUT == null) {
			initBlob47FallbackLUT();
		}

		// Keep falling back until we find a tile that exists
		while (tileIndex >= maxTiles && tileIndex > 0) {
			tileIndex = blob47FallbackLUT[tileIndex];
		}

		// Final safety: if still out of range, use tile 0 (isolated)
		if (tileIndex >= maxTiles) {
			return 0;
		}

		return tileIndex;
	}

	/**
	 * Apply fallback to a blob47 tile index using a Map for defined tiles.
	 * If tileIndex is not in the map, falls back to simpler tiles until one exists.
	 *
	 * @param tileIndex The original tile index (0-46)
	 * @param mapping Map of defined tile indices
	 * @return Tile index that exists in the mapping
	 */
	public static function applyBlob47FallbackWithMap(tileIndex:Int, mapping:Map<Int, Int>):Int {
		if (blob47LUT == null) initBlob47LUT();

		final mask = blob47ReverseLUT[tileIndex];
		final allCardinals = mask & (N | E | S | W);
		final cardinalBits:Array<Int> = [];
		if ((allCardinals & N) != 0) cardinalBits.push(N);
		if ((allCardinals & E) != 0) cardinalBits.push(E);
		if ((allCardinals & S) != 0) cardinalBits.push(S);
		if ((allCardinals & W) != 0) cardinalBits.push(W);

		// Phase 1: Same cardinals, try all corner subsets (prefer most corners)
		final result = findBestCornerMatch(allCardinals, tileIndex, mapping);
		if (result >= 0) return result;

		// Phase 2: Remove cardinals progressively (1, then 2, etc.)
		for (removeCount in 1...cardinalBits.length) {
			final best = tryReducedCardinals(cardinalBits, removeCount, tileIndex, mapping);
			if (best >= 0) return best;
		}

		// Phase 3: Full tile or empty tile
		if (tileIndex != 46 && mapping.exists(46)) return 46;
		if (tileIndex != 0 && mapping.exists(0)) return 0;

		return tileIndex;
	}

	/**
	 * Get the full fallback chain for a blob47 tile.
	 * Returns {result: actual fallback tile, skipped: tiles tried but not mapped (in order of priority)}.
	 * If the tile is directly mapped, result == tileIndex and skipped is empty.
	 */
	public static function getBlob47FallbackChain(tileIndex:Int, mapping:Map<Int, Int>):{result:Int, skipped:Array<Int>} {
		if (blob47LUT == null) initBlob47LUT();
		if (mapping.exists(tileIndex)) return {result: tileIndex, skipped: []};

		final skipped:Array<Int> = [];
		final mask = blob47ReverseLUT[tileIndex];
		final allCardinals = mask & (N | E | S | W);
		final cardinalBits:Array<Int> = [];
		if ((allCardinals & N) != 0) cardinalBits.push(N);
		if ((allCardinals & E) != 0) cardinalBits.push(E);
		if ((allCardinals & S) != 0) cardinalBits.push(S);
		if ((allCardinals & W) != 0) cardinalBits.push(W);

		// Phase 1: Same cardinals, all corner subsets sorted by corner count desc
		final phase1 = getSortedCornerSubsets(allCardinals, tileIndex);
		for (candidate in phase1) {
			if (mapping.exists(candidate)) return {result: candidate, skipped: skipped};
			skipped.push(candidate);
		}

		// Phase 2: Remove cardinals progressively
		for (removeCount in 1...cardinalBits.length) {
			final phase2 = getSortedReducedCardinalCandidates(cardinalBits, removeCount, tileIndex);
			for (candidate in phase2) {
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

	/** Get all unique candidate tiles for given cardinals + corner subsets, sorted by descending corner count */
	private static function getSortedCornerSubsets(cardinals:Int, skipTile:Int):Array<Int> {
		final cornerBits:Array<Int> = [];
		if ((cardinals & N) != 0 && (cardinals & E) != 0) cornerBits.push(NE);
		if ((cardinals & S) != 0 && (cardinals & E) != 0) cornerBits.push(SE);
		if ((cardinals & S) != 0 && (cardinals & W) != 0) cornerBits.push(SW);
		if ((cardinals & N) != 0 && (cardinals & W) != 0) cornerBits.push(NW);

		final numCorners = cornerBits.length;
		final candidates:Array<{tile:Int, corners:Int}> = [];
		final seen = new Map<Int, Bool>();

		for (subset in 0...(1 << numCorners)) {
			var tryMask = cardinals;
			var count = 0;
			for (ci in 0...numCorners) {
				if ((subset & (1 << ci)) != 0) { tryMask |= cornerBits[ci]; count++; }
			}
			final tryTile = blob47LUT[tryMask];
			if (tryTile != skipTile && !seen.exists(tryTile)) {
				seen.set(tryTile, true);
				candidates.push({tile: tryTile, corners: count});
			}
		}
		// Sort by descending corner count (most corners first = best match)
		candidates.sort((a, b) -> b.corners - a.corners);
		return [for (c in candidates) c.tile];
	}

	/** Get candidate tiles for reduced cardinal sets, sorted by score (cardinals*10 + corners) desc */
	private static function getSortedReducedCardinalCandidates(cardinalBits:Array<Int>, removeCount:Int, skipTile:Int):Array<Int> {
		final candidates:Array<{tile:Int, score:Int}> = [];
		final seen = new Map<Int, Bool>();

		combineRemovals(cardinalBits, cardinalBits.length, removeCount, 0, 0, removeMask -> {
			var keepCardinals = 0;
			for (b in cardinalBits) {
				if ((b & removeMask) == 0) keepCardinals |= b;
			}
			final subCandidates = getSortedCornerSubsets(keepCardinals, skipTile);
			for (candidate in subCandidates) {
				if (!seen.exists(candidate)) {
					seen.set(candidate, true);
					final rmask = blob47ReverseLUT[candidate];
					var corners = 0;
					if ((rmask & NE) != 0) corners++;
					if ((rmask & SE) != 0) corners++;
					if ((rmask & SW) != 0) corners++;
					if ((rmask & NW) != 0) corners++;
					final score = (cardinalBits.length - removeCount) * 10 + corners;
					candidates.push({tile: candidate, score: score});
				}
			}
		});
		candidates.sort((a, b) -> b.score - a.score);
		return [for (c in candidates) c.tile];
	}

	/** Try all corner subsets for given cardinals, return mapped tile with most corners, or -1 */
	private static function findBestCornerMatch(cardinals:Int, skipTile:Int, mapping:Map<Int, Int>):Int {
		final cornerBits:Array<Int> = [];
		if ((cardinals & N) != 0 && (cardinals & E) != 0) cornerBits.push(NE);
		if ((cardinals & S) != 0 && (cardinals & E) != 0) cornerBits.push(SE);
		if ((cardinals & S) != 0 && (cardinals & W) != 0) cornerBits.push(SW);
		if ((cardinals & N) != 0 && (cardinals & W) != 0) cornerBits.push(NW);

		final numCorners = cornerBits.length;
		var bestTile = -1;
		var bestCount = -1;

		for (subset in 0...(1 << numCorners)) {
			var tryMask = cardinals;
			var count = 0;
			for (ci in 0...numCorners) {
				if ((subset & (1 << ci)) != 0) {
					tryMask |= cornerBits[ci];
					count++;
				}
			}
			final tryTile = blob47LUT[tryMask];
			if (tryTile != skipTile && mapping.exists(tryTile) && count > bestCount) {
				bestCount = count;
				bestTile = tryTile;
			}
		}
		return bestTile;
	}

	/** Try removing removeCount cardinals, for each try all corner subsets */
	private static function tryReducedCardinals(cardinalBits:Array<Int>, removeCount:Int, skipTile:Int, mapping:Map<Int, Int>):Int {
		var bestTile = -1;
		var bestScore = -1; // cardinals remaining * 10 + corners

		combineRemovals(cardinalBits, cardinalBits.length, removeCount, 0, 0, removeMask -> {
			final reduced = (N | E | S | W) & ~removeMask;
			// Only keep cardinals that were in the original
			var keepCardinals = 0;
			for (b in cardinalBits) {
				if ((b & removeMask) == 0) keepCardinals |= b;
			}
			final result = findBestCornerMatch(keepCardinals, skipTile, mapping);
			if (result >= 0) {
				final rmask = blob47ReverseLUT[result];
				var corners = 0;
				if ((rmask & NE) != 0) corners++;
				if ((rmask & SE) != 0) corners++;
				if ((rmask & SW) != 0) corners++;
				if ((rmask & NW) != 0) corners++;
				final score = (cardinalBits.length - removeCount) * 10 + corners;
				if (score > bestScore) {
					bestScore = score;
					bestTile = result;
				}
			}
		});

		return bestTile;
	}

	private static function combineRemovals(bits:Array<Int>, n:Int, k:Int, start:Int, mask:Int, cb:(Int) -> Void):Void {
		if (k == 0) { cb(mask); return; }
		for (i in start...n) {
			combineRemovals(bits, n, k - 1, i + 1, mask | bits[i], cb);
		}
	}

	/**
	 * Initialize the Blob47 lookup table.
	 * Maps all 256 possible 8-neighbor combinations to 47 unique tile indices.
	 */
	private static function initBlob47LUT():Void {
		blob47LUT = new Array<Int>();
		blob47LUT.resize(256);

		for (i in 0...256) {
			blob47LUT[i] = calculateBlob47Tile(i);
		}

		// Build reverse LUT: tile index (0-46) -> reduced mask
		// Use the switch table from calculateBlob47Tile directly
		blob47ReverseLUT = [
			0, 1, 4, 5, 7, 16, 17, 20, 21, 23, 28, 29, 31,        // 0-12
			64, 65, 68, 69, 71, 80, 81, 84, 85, 87, 92, 93, 95,    // 13-25
			112, 113, 116, 117, 119, 124, 125, 127,                  // 26-33
			193, 197, 199, 209, 213, 215, 221, 223, 241, 245, 247, 253, 255 // 34-46
		];
	}

	/**
	 * Initialize the Blob47 fallback lookup table.
	 * Each entry maps a tile index to its fallback (same cardinals, fewer corners).
	 * Fallback chain removes corners in order: NW -> SW -> SE -> NE.
	 */
	private static function initBlob47FallbackLUT():Void {
		blob47FallbackLUT = new Array<Int>();
		blob47FallbackLUT.resize(47);

		// Tile 0: isolated - no fallback (base case)
		blob47FallbackLUT[0] = 0;

		// Tiles 1-5: single cardinal, no corners possible - fall back to 0
		blob47FallbackLUT[1] = 0; // N only -> isolated
		blob47FallbackLUT[2] = 0; // E only -> isolated
		blob47FallbackLUT[3] = 0; // N+E (no corner) -> E only? Actually better to go to simpler
		blob47FallbackLUT[4] = 3; // N+NE+E -> N+E
		blob47FallbackLUT[5] = 0; // S only -> isolated
		blob47FallbackLUT[6] = 1; // N+S -> N only
		blob47FallbackLUT[7] = 2; // E+S -> E only
		blob47FallbackLUT[8] = 3; // N+E+S -> N+E
		blob47FallbackLUT[9] = 8; // N+NE+E+S -> N+E+S
		blob47FallbackLUT[10] = 7; // E+SE+S -> E+S
		blob47FallbackLUT[11] = 8; // N+E+SE+S -> N+E+S
		blob47FallbackLUT[12] = 9; // N+NE+E+SE+S -> N+NE+E+S (remove SE)

		blob47FallbackLUT[13] = 0; // W only -> isolated
		blob47FallbackLUT[14] = 1; // N+W -> N only
		blob47FallbackLUT[15] = 2; // E+W -> E only
		blob47FallbackLUT[16] = 3; // N+E+W -> N+E
		blob47FallbackLUT[17] = 16; // N+NE+E+W -> N+E+W
		blob47FallbackLUT[18] = 5; // S+W -> S only
		blob47FallbackLUT[19] = 6; // N+S+W -> N+S
		blob47FallbackLUT[20] = 7; // E+S+W -> E+S
		blob47FallbackLUT[21] = 8; // N+E+S+W (center, no corners) -> N+E+S
		blob47FallbackLUT[22] = 21; // N+NE+E+S+W -> center
		blob47FallbackLUT[23] = 20; // E+SE+S+W -> E+S+W
		blob47FallbackLUT[24] = 21; // N+E+SE+S+W -> center
		blob47FallbackLUT[25] = 22; // N+NE+E+SE+S+W -> N+NE+E+S+W (remove SE)

		blob47FallbackLUT[26] = 18; // S+SW+W -> S+W
		blob47FallbackLUT[27] = 19; // N+S+SW+W -> N+S+W
		blob47FallbackLUT[28] = 20; // E+S+SW+W -> E+S+W
		blob47FallbackLUT[29] = 21; // N+E+S+SW+W -> center
		blob47FallbackLUT[30] = 22; // N+NE+E+S+SW+W -> N+NE+E+S+W (remove SW)
		blob47FallbackLUT[31] = 23; // E+SE+S+SW+W -> E+SE+S+W (remove SW)
		blob47FallbackLUT[32] = 24; // N+E+SE+S+SW+W -> N+E+SE+S+W (remove SW)
		blob47FallbackLUT[33] = 25; // N+NE+E+SE+S+SW+W -> N+NE+E+SE+S+W (remove SW)

		blob47FallbackLUT[34] = 14; // N+W+NW -> N+W
		blob47FallbackLUT[35] = 16; // N+E+W+NW -> N+E+W
		blob47FallbackLUT[36] = 17; // N+NE+E+W+NW -> N+NE+E+W (remove NW)
		blob47FallbackLUT[37] = 19; // N+S+W+NW -> N+S+W
		blob47FallbackLUT[38] = 21; // N+E+S+W+NW -> center
		blob47FallbackLUT[39] = 22; // N+NE+E+S+W+NW -> N+NE+E+S+W (remove NW)
		blob47FallbackLUT[40] = 24; // N+E+SE+S+W+NW -> N+E+SE+S+W (remove NW)
		blob47FallbackLUT[41] = 25; // N+NE+E+SE+S+W+NW -> N+NE+E+SE+S+W (remove NW)
		blob47FallbackLUT[42] = 27; // N+S+SW+W+NW -> N+S+SW+W (remove NW)
		blob47FallbackLUT[43] = 29; // N+E+S+SW+W+NW -> N+E+S+SW+W (remove NW)
		blob47FallbackLUT[44] = 30; // N+NE+E+S+SW+W+NW -> N+NE+E+S+SW+W (remove NW)
		blob47FallbackLUT[45] = 32; // N+E+SE+S+SW+W+NW -> N+E+SE+S+SW+W (remove NW)
		blob47FallbackLUT[46] = 41; // all neighbors -> remove NW
	}

	/**
	 * Calculate which of the 47 blob tiles to use for a given neighbor mask.
	 * Corners are only relevant if both adjacent edges are present.
	 */
	private static function calculateBlob47Tile(mask:Int):Int {
		final hasN = (mask & N) != 0;
		final hasNE = (mask & NE) != 0;
		final hasE = (mask & E) != 0;
		final hasSE = (mask & SE) != 0;
		final hasS = (mask & S) != 0;
		final hasSW = (mask & SW) != 0;
		final hasW = (mask & W) != 0;
		final hasNW = (mask & NW) != 0;

		// Corners only matter if both adjacent edges are present
		final effectiveNE = hasNE && hasN && hasE;
		final effectiveSE = hasSE && hasS && hasE;
		final effectiveSW = hasSW && hasS && hasW;
		final effectiveNW = hasNW && hasN && hasW;

		// Build reduced mask with effective corners
		var reduced = 0;
		if (hasN)
			reduced |= 1;
		if (effectiveNE)
			reduced |= 2;
		if (hasE)
			reduced |= 4;
		if (effectiveSE)
			reduced |= 8;
		if (hasS)
			reduced |= 16;
		if (effectiveSW)
			reduced |= 32;
		if (hasW)
			reduced |= 64;
		if (effectiveNW)
			reduced |= 128;

		// Map reduced mask to tile index (0-46)
		// This mapping follows the standard blob tileset layout
		return switch reduced {
			case 0: 0; // isolated
			case 1: 1; // N only
			case 4: 2; // E only
			case 5: 3; // N+E
			case 7: 4; // N+NE+E
			case 16: 5; // S only
			case 17: 6; // N+S
			case 20: 7; // E+S
			case 21: 8; // N+E+S
			case 23: 9; // N+NE+E+S
			case 28: 10; // E+SE+S
			case 29: 11; // N+E+SE+S
			case 31: 12; // N+NE+E+SE+S
			case 64: 13; // W only
			case 65: 14; // N+W
			case 68: 15; // E+W
			case 69: 16; // N+E+W
			case 71: 17; // N+NE+E+W
			case 80: 18; // S+W
			case 81: 19; // N+S+W
			case 84: 20; // E+S+W
			case 85: 21; // N+E+S+W (center, no corners)
			case 87: 22; // N+NE+E+S+W
			case 92: 23; // E+SE+S+W
			case 93: 24; // N+E+SE+S+W
			case 95: 25; // N+NE+E+SE+S+W
			case 112: 26; // S+SW+W
			case 113: 27; // N+S+SW+W
			case 116: 28; // E+S+SW+W
			case 117: 29; // N+E+S+SW+W
			case 119: 30; // N+NE+E+S+SW+W
			case 124: 31; // E+SE+S+SW+W
			case 125: 32; // N+E+SE+S+SW+W
			case 127: 33; // N+NE+E+SE+S+SW+W
			case 193: 34; // N+W+NW
			case 197: 35; // N+E+W+NW
			case 199: 36; // N+NE+E+W+NW
			case 209: 37; // N+S+W+NW
			case 213: 38; // N+E+S+W+NW
			case 215: 39; // N+NE+E+S+W+NW
			case 221: 40; // N+E+SE+S+W+NW
			case 223: 41; // N+NE+E+SE+S+W+NW
			case 241: 42; // N+S+SW+W+NW
			case 245: 43; // N+E+S+SW+W+NW
			case 247: 44; // N+NE+E+S+SW+W+NW
			case 253: 45; // N+E+SE+S+SW+W+NW
			case 255: 46; // all neighbors
			default: 21; // default to center
		};
	}

	/**
	 * Helper to check if a specific direction is present in a mask.
	 */
	public static inline function hasDirection(mask:Int, dir:Int):Bool {
		return (mask & dir) != 0;
	}
}
