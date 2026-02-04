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
	 * Initialize the Blob47 lookup table.
	 * Maps all 256 possible 8-neighbor combinations to 47 unique tile indices.
	 */
	private static function initBlob47LUT():Void {
		blob47LUT = new Array<Int>();
		blob47LUT.resize(256);

		for (i in 0...256) {
			blob47LUT[i] = calculateBlob47Tile(i);
		}
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
