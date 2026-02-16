package bh.base;

class FontManager {
	private static var fontRegistry:Map<String, h2d.Font> = new Map();

	/**
	 * Register a font with an optional offset to normalize positioning.
	 * Use offsetX/offsetY to adjust glyph positions so text at (0,0) starts at the top-left.
	 * This is useful for fonts with built-in padding or baseline offsets that get multiplied by scale.
	 */
	public static function registerFont(name:String, font:h2d.Font, offsetX:Float = 0, offsetY:Float = 0) {
		var lowerName = name.toLowerCase();
		if (fontRegistry.exists(lowerName)) {
			throw 'Font "${name}" is already registered. Use a different name or unregister the existing font first.';
		}
		if (offsetX != 0 || offsetY != 0) {
			font.setOffset(offsetX, offsetY);
		}
		fontRegistry.set(lowerName, font);
	}

	
	
	public static function getFontByName(name:String):h2d.Font {
		var font = fontRegistry.get(name.toLowerCase());
		if (font == null) {
			throw 'Font not found: ${name}. Make sure to register the font first using registerFont().';
		}
		return font;
	}
	
	public static function getRegisteredFontNames():Array<String> {
		final keys = [for (k in fontRegistry.keys()) k];
		keys.sort((a, b) -> a < b ? -1 : 1);
		return keys;
	}

}
