package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.BuildMode;
import bh.test.BuilderTestBase.buildFromSource;
import bh.test.BuilderTestBase.findVisibleBitmapDescendants;

/**
 * Unit tests for bit flag conditionals:
 * @(param => bit[N]) syntax with flags parameter type.
 * Tests individual bits, multi-bit combinations, zero flags, @else after bit conditional.
 */
class BitFlagTest extends BuilderTestBase {
	// ==================== Individual Bits ====================

	@Test
	public function testBit0Set():Void {
		// flags=1 (binary 001) → bit[0] set
		final params = new Map<String, Dynamic>();
		params.set("flags", 1);
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[0]) bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
	}

	@Test
	public function testBit0NotSet():Void {
		// flags=2 (binary 010) → bit[0] not set
		final params = new Map<String, Dynamic>();
		params.set("flags", 2);
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[0]) bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(0, bitmaps.length);
	}

	@Test
	public function testBit1Set():Void {
		// flags=2 (binary 010) → bit[1] set
		final params = new Map<String, Dynamic>();
		params.set("flags", 2);
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[1]) bitmap(generated(color(10, 10, #00ff00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
	}

	@Test
	public function testBit1NotSet():Void {
		// flags=5 (binary 101) → bit[1] not set
		final params = new Map<String, Dynamic>();
		params.set("flags", 5);
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[1]) bitmap(generated(color(10, 10, #00ff00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(0, bitmaps.length);
	}

	@Test
	public function testBit3Set():Void {
		// flags=8 (binary 1000) → bit[3] set
		final params = new Map<String, Dynamic>();
		params.set("flags", 8);
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[3]) bitmap(generated(color(10, 10, #0000ff))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
	}

	@Test
	public function testBit3NotSet():Void {
		// flags=7 (binary 0111) → bit[3] not set
		final params = new Map<String, Dynamic>();
		params.set("flags", 7);
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[3]) bitmap(generated(color(10, 10, #0000ff))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(0, bitmaps.length);
	}

	// ==================== Multiple Bits ====================

	@Test
	public function testMultipleBitsAllSet():Void {
		// flags=7 (binary 111) → bit[0], bit[1], bit[2] all set
		final params = new Map<String, Dynamic>();
		params.set("flags", 7);
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[0]) bitmap(generated(color(10, 10, #ff0000))): 0, 0
				@(flags => bit[1]) bitmap(generated(color(20, 20, #00ff00))): 10, 0
				@(flags => bit[2]) bitmap(generated(color(30, 30, #0000ff))): 20, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(3, bitmaps.length);
	}

	@Test
	public function testMultipleBitsSomeSet():Void {
		// flags=5 (binary 101) → bit[0] set, bit[1] not set, bit[2] set
		final params = new Map<String, Dynamic>();
		params.set("flags", 5);
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[0]) bitmap(generated(color(10, 10, #ff0000))): 0, 0
				@(flags => bit[1]) bitmap(generated(color(20, 20, #00ff00))): 10, 0
				@(flags => bit[2]) bitmap(generated(color(30, 30, #0000ff))): 20, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);
	}

	// ==================== Zero Flags ====================

	@Test
	public function testZeroFlagsNoBitsMatch():Void {
		// flags=0 → no bits set, no bitmaps visible
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[0]) bitmap(generated(color(10, 10, #ff0000))): 0, 0
				@(flags => bit[1]) bitmap(generated(color(20, 20, #00ff00))): 10, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(0, bitmaps.length);
	}

	// ==================== @else After Bit Conditional ====================

	@Test
	public function testElseAfterBitConditional():Void {
		// flags=0 → bit[0] not set → @default fires
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[0]) bitmap(generated(color(20, 20, #00ff00))): 0, 0
				@default bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		// Default bitmap is 10x10
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	@Test
	public function testElseAfterBitConditionalNotFired():Void {
		// flags=1 → bit[0] set → @default does NOT fire
		final params = new Map<String, Dynamic>();
		params.set("flags", 1);
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[0]) bitmap(generated(color(20, 20, #00ff00))): 0, 0
				@default bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		// Bit[0] bitmap is 20x20
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}

	// ==================== Default Flags Value ====================

	@Test
	public function testDefaultFlagsValueZero():Void {
		// No params passed, flags defaults to 0
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[0]) bitmap(generated(color(10, 10, #ff0000))): 0, 0
				@default bitmap(generated(color(5, 5, #888888))): 0, 0
			}
		", "test");
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		// Default bitmap (5x5) because flags=0, bit[0] not set
		Assert.equals(5, Std.int(bitmaps[0].tile.width));
	}

	// ==================== High Bit ====================

	@Test
	public function testBit7Set():Void {
		// flags=128 (binary 10000000) → bit[7] set
		final params = new Map<String, Dynamic>();
		params.set("flags", 128);
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[7]) bitmap(generated(color(15, 15, #ffff00))): 0, 0
			}
		", "test", params);
		final bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
	}

	// ==================== Incremental Bit Flag Tests ====================

	@Test
	public function testIncrementalSetFlagsTogglesVisibility():Void {
		// Build in Incremental mode with flags=0 and 3 bitmaps for bit[0], bit[1], bit[2]
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[0]) bitmap(generated(color(10, 10, #ff0000))): 0, 0
				@(flags => bit[1]) bitmap(generated(color(10, 10, #00ff00))): 10, 0
				@(flags => bit[2]) bitmap(generated(color(10, 10, #0000ff))): 20, 0
			}
		", "test", null, Incremental);

		// Initially flags=0: no bits set, no visible bitmaps
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(0, bitmaps.length);

		// Set flags=1 (bit[0]) → 1 visible bitmap
		result.setParameter("flags", 1);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);

		// Set flags=3 (bit[0]+bit[1]) → 2 visible bitmaps
		result.setParameter("flags", 3);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(2, bitmaps.length);
	}

	@Test
	public function testIncrementalClearFlags():Void {
		// Build in Incremental mode with initial flags=7 (all 3 bits set)
		final params = new Map<String, Dynamic>();
		params.set("flags", 7);
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[0]) bitmap(generated(color(10, 10, #ff0000))): 0, 0
				@(flags => bit[1]) bitmap(generated(color(10, 10, #00ff00))): 10, 0
				@(flags => bit[2]) bitmap(generated(color(10, 10, #0000ff))): 20, 0
			}
		", "test", params, Incremental);

		// Initially flags=7: all 3 bits set → 3 visible bitmaps
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(3, bitmaps.length);

		// Clear all flags → 0 visible
		result.setParameter("flags", 0);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(0, bitmaps.length);
	}

	@Test
	public function testIncrementalBitToggleWithDefault():Void {
		// Build in Incremental mode with @(flags => bit[0]) bitmap 20x20 and @default bitmap 10x10
		final result = buildFromSource("
			#test programmable(flags:flags(8)=0) {
				@(flags => bit[0]) bitmap(generated(color(20, 20, #00ff00))): 0, 0
				@default bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
		", "test", null, Incremental);

		// Initially flags=0: bit[0] not set → @default fires (10x10)
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Set flags=1 (bit[0]) → bit[0] match fires (20x20)
		result.setParameter("flags", 1);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Clear flags back to 0 → @default fires again (10x10)
		result.setParameter("flags", 0);
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
	}

	// ==================== Incremental Multi-Value Match Tests ====================

	@Test
	public function testIncrementalMultiValueMatch():Void {
		// @(color=>[red,green]) matches when color is red OR green
		final result = buildFromSource("
			#test programmable(color:[red,green,blue]=red) {
				@(color=>[red,green]) bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
		", "test", null, Incremental);

		// Initially color="red": matches [red,green] → 1 visible bitmap
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);

		// Switch to "green": still matches [red,green] → 1 visible
		result.setParameter("color", "green");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);

		// Switch to "blue": does NOT match [red,green] → 0 visible
		result.setParameter("color", "blue");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(0, bitmaps.length);
	}

	@Test
	public function testIncrementalMultiValueNegation():Void {
		// @(color != [red,green]) matches when color is NOT red and NOT green
		final result = buildFromSource("
			#test programmable(color:[red,green,blue]=blue) {
				@(color != [red,green]) bitmap(generated(color(10, 10, #0000ff))): 0, 0
			}
		", "test", null, Incremental);

		// Initially color="blue": blue is NOT in [red,green] → 1 visible
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);

		// Switch to "red": red IS in [red,green], so != fails → 0 visible
		result.setParameter("color", "red");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(0, bitmaps.length);
	}

	@Test
	public function testIncrementalMultiValueWithElse():Void {
		// @(mode=>[a,b]) bitmap 20x20 and @else bitmap 10x10
		final result = buildFromSource("
			#test programmable(mode:[a,b,c]=a) {
				@(mode=>[a,b]) bitmap(generated(color(20, 20, #00ff00))): 0, 0
				@else bitmap(generated(color(10, 10, #ff0000))): 0, 0
			}
		", "test", null, Incremental);

		// Initially mode="a": matches [a,b] → 20x20 visible
		var bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));

		// Switch to "c": does NOT match [a,b] → @else fires (10x10)
		result.setParameter("mode", "c");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));

		// Switch to "b": matches [a,b] again → 20x20
		result.setParameter("mode", "b");
		bitmaps = findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.equals(20, Std.int(bitmaps[0].tile.width));
	}
}
