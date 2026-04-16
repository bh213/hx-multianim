package bh.base;


class ColorUtils {

	public static inline function getAlpha(color:Int) {
		return (color >>> 24) / 255.0;
	}
}
