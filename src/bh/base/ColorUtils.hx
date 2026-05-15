package bh.base;

/** Color helpers for strict-D ARGB semantics.

	hx-multianim stores colors as Heaps `0xAARRGGBB` — the top byte IS alpha,
	always. A bare `0xRRGGBB` int has top byte = 0 and renders invisible
	through `h2d.Drawable.color`. Parser literals handle this (`#RRGGBB`
	bakes `0xFF` alpha, `0xRRGGBB` is preserved verbatim), but Haxe-side ints
	passed via `extraParams` / `setParameter` have no such boundary — use
	these helpers to construct ARGB values safely. */
class ColorUtils {

	/** Opaque color from RGB. `rgb(0x55AA88)` → `0xFF55AA88`. Any alpha byte
		in the input is discarded. */
	public static inline function rgb(rgb:Int):Int {
		return 0xFF000000 | (rgb & 0xFFFFFF);
	}

	/** Color from RGB + alpha (0..1, clamped, rounded to nearest byte).
		`rgba(0x55AA88, 0.5)` → `0x8055AA88`. */
	public static inline function rgba(rgb:Int, alpha:Float):Int {
		final a = alpha <= 0 ? 0 : alpha >= 1 ? 255 : Std.int(alpha * 255 + 0.5);
		return (a << 24) | (rgb & 0xFFFFFF);
	}

	/** Replace the alpha byte on an existing ARGB value (0..1). */
	public static inline function withAlpha(argb:Int, alpha:Float):Int {
		final a = alpha <= 0 ? 0 : alpha >= 1 ? 255 : Std.int(alpha * 255 + 0.5);
		return (a << 24) | (argb & 0xFFFFFF);
	}

	/** Alpha byte as a 0..1 float. */
	public static inline function getAlpha(color:Int):Float {
		return (color >>> 24) / 255.0;
	}

	/** Bottom 24 bits (strips alpha). */
	public static inline function getRgb(color:Int):Int {
		return color & 0xFFFFFF;
	}
}
