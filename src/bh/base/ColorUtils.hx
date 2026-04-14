package bh.base;


class ColorUtils {

    // Note: tryStringToColor() now bakes 0xFF alpha into all colors except `transparent` (0x00000000).
	// This function is only needed for raw integer values from non-tryStringToColor sources.
	// Warning: will incorrectly override explicit 0 alpha (e.g., transparent, #RRGGBB00).
	public static inline function addAlphaIfNotPresent(color:Int) {
		if (color >>> 24 == 0) color |= 0xFF000000;
		return color;
	}

	public static inline function getAlpha(color:Int) {
		return (color >>> 24) / 255.0;
	}
}

/**
	Public-API type for user-supplied `:color` parameters on codegen programmables.

	Implicitly bakes `0xFF` alpha on `Int → ColorArg` conversion so callers can pass raw
	`0xRRGGBB` ints and still match parser-baked `#RRGGBB` arm values (which are stored as
	`0xFFRRGGBB`). `to Int` lets the codegen keep a plain `Int` storage field without a
	round-trip.

	BOUNDARY ONLY. Do not use as a storage or internal type. `addAlphaIfNotPresent` is not
	idempotent on explicit 0-alpha colors — `transparent` / `#RRGGBB00` values re-entering
	via `fromInt` get clobbered to `0xFF000000`. Already-baked internal values must stay on
	the `Int` side.
**/
abstract ColorArg(Int) to Int {
	inline function new(i:Int) this = i;

	@:from
	public static inline function fromInt(i:Int):ColorArg {
		return new ColorArg(ColorUtils.addAlphaIfNotPresent(i));
	}
}
