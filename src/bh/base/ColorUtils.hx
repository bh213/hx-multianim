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
