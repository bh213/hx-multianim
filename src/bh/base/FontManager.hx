package bh.base;

class FontManager {
	private static var fontRegistry:Map<String, h2d.Font> = new Map();
	
	public static function registerFont(name:String, font:h2d.Font) {
		var lowerName = name.toLowerCase();
		if (fontRegistry.exists(lowerName)) {
			throw 'Font "${name}" is already registered. Use a different name or unregister the existing font first.';
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
