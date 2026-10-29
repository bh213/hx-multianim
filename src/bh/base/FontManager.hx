package bh.base;

class FontManager {
	private static var fontRegistry:Map<String, h2d.Font> = new Map();
	/** The offset each font was registered with, and the glyph offset it had before, for unregisterFont. */
	private static var fontOffsets:Map<String, {wasX:Float, wasY:Float, offsetY:Float}> = new Map();

	/**
	 * Register a font with an optional offset to normalize positioning.
	 * Use offsetX/offsetY to adjust glyph positions so text at (0,0) starts at the top-left.
	 * This is useful for fonts with built-in padding or baseline offsets that get multiplied by scale.
	 * The offset changes the `h2d.Font` itself; `unregisterFont` takes it off again.
	 */
	public static function registerFont(name:String, font:h2d.Font, offsetX:Float = 0, offsetY:Float = 0) {
		var lowerName = name.toLowerCase();
		if (fontRegistry.exists(lowerName)) {
			throw 'Font "${name}" is already registered. Use a different name or unregister the existing font first.';
		}
		if (offsetX != 0 || offsetY != 0) {
			fontOffsets.set(lowerName, {wasX: @:privateAccess font.offsetX, wasY: @:privateAccess font.offsetY, offsetY: offsetY});
			font.setOffset(offsetX, offsetY);
			@:privateAccess font.baseLine +=offsetY;
			@:privateAccess font.lineHeight +=offsetY;
		}
		fontRegistry.set(lowerName, font);
	}



	/** Removes a font, so its name can be registered again (a second font of a taken name is an
	 *  error), and takes off the offset it was registered with; returns whether it was there. */
	public static function unregisterFont(name:String):Bool {
		final lowerName = name.toLowerCase();
		final font = fontRegistry.get(lowerName);
		final offset = fontOffsets.get(lowerName);
		if (font != null && offset != null) {
			font.setOffset(offset.wasX, offset.wasY);
			@:privateAccess font.baseLine -= offset.offsetY;
			@:privateAccess font.lineHeight -= offset.offsetY;
		}
		fontOffsets.remove(lowerName);
		return fontRegistry.remove(lowerName);
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
