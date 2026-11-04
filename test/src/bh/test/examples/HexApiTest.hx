package bh.test.examples;

import utest.Assert;
import bh.base.Hex;
import bh.base.Hex.OffsetCoord;
import bh.base.Hex.HexLayout;
import bh.base.GridDirection;

/**
 * Unit tests for the public Hex coordinate-conversion API.
 */
class HexApiTest extends utest.Test {
	@Test
	public function testToOffsetCoordinatesRoundTripsThroughOddQConversion():Void {
		// OffsetCoord conversions require the parity constant EVEN (+1) or
		// ODD (-1). toOffsetCoordinates() must commit to one parity so the
		// result round-trips through the matching qoffsetToCube call. Passing
		// the invalid offset 0 happens to mimic ODD for positive columns but
		// diverges on negative odd columns — silently corrupting coordinates.
		final samples = [
			new Hex(0, 0, 0),
			new Hex(1, 0, -1),
			new Hex(2, -1, -1),
			new Hex(5, -2, -3),
			new Hex(-1, 0, 1),
			new Hex(-3, 1, 2),
		];
		for (hex in samples) {
			final oc = hex.toOffsetCoordinates();
			final back = OffsetCoord.qoffsetToCube(OffsetCoord.ODD, oc);
			Assert.equals(hex.q, back.q, 'q must round-trip for hex ${hex.toString()}, got ${back.toString()}');
			Assert.equals(hex.r, back.r, 'r must round-trip for hex ${hex.toString()} through odd-q offset coordinates, got ${back.toString()}');
		}
	}

	@Test
	public function testDirectionToAngleReflectsLayoutOrientation():Void {
		// POINTY layouts start half a hex-side rotated from FLAT layouts
		// (start_angle 0.5 in 1/6-turn units = 30°). directionToAngle must
		// reflect the layout's orientation, not report the same angle for both.
		final flat = HexLayout.createFromFloats(FLAT, 20, 20);
		final pointy = HexLayout.createFromFloats(POINTY, 20, 20);

		final flatDeg:Float = flat.directionToAngle(DIRECTION_RIGHT).degreesValue();
		final pointyDeg:Float = pointy.directionToAngle(DIRECTION_RIGHT).degreesValue();

		Assert.floatEquals(30.0, (pointyDeg - flatDeg + 360) % 360, 0.001,
			'POINTY direction angle must be offset 30° from FLAT (start_angle), got flat=$flatDeg pointy=$pointyDeg');
	}
}
