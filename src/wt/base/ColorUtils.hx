package wt.base;


class ColorUtils {

    public static inline function addAlphaIfNotPresent(color:Int) {
		if (color >>> 24 == 0) color |= 0xFF000000; // Add alpha if not present
		return color;
	}

}