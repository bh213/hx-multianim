package bh.multianim;

/**
 * Converts manim-native [tag]...[/] rich text markup to HTML for h2d.HtmlText.
 *
 * Supported markup:
 *   [styleName]...[/]            → <styleName>...</styleName>     (requires defineHtmlTag)
 *   [img:name]                   → <img src="name"/>               (self-closing)
 *   [align:left|center|right]...[/] → <p align="...">...</p>
 *   [link:id]...[/]              → <a href="id">...</a>
 *   [/]                          → closes most recently opened tag (stack-based)
 *   [[                           → literal [ (escape sequence)
 *
 * Colors and fonts are set via named styles (styles: {name: color(...) font(...)}).
 * Inline [c:] and [f:] are no longer supported.
 *
 * Works at both macro time and runtime (no runtime-only APIs).
 */
class TextMarkupConverter {
	/**
	 * Convert [tag]...[/] markup to HTML.
	 * If no markup found, returns input unchanged.
	 */
	public static function convert(text:String):String {
		if (text == null || text.length == 0) return text;

		// Escape XML special characters before markup conversion.
		// Input text uses [markup] not <html>, so any literal <, >, & must be escaped
		// to prevent h2d.HtmlText's XML parser from misinterpreting them.
		text = escapeXmlChars(text);

		if (text.indexOf("[") < 0) return text;

		var buf = new StringBuf();
		var tagStack:Array<String> = [];
		var i = 0;
		var len = text.length;

		while (i < len) {
			var ch = text.charCodeAt(i);
			if (ch == "[".code && i + 1 < len && text.charCodeAt(i + 1) == "[".code) {
				// [[ → literal [
				buf.add("[");
				i += 2;
			} else if (ch == "[".code) {
				var closeIdx = text.indexOf("]", i + 1);
				if (closeIdx < 0) {
					buf.addChar(ch);
					i++;
					continue;
				}

				var tag = text.substring(i + 1, closeIdx);

				if (tag == "/") {
					if (tagStack.length > 0) {
						var openTag = tagStack.pop();
						buf.add("</");
						buf.add(openTag);
						buf.add(">");
					}
					i = closeIdx + 1;
				} else if (StringTools.startsWith(tag, "img:")) {
					var imgName = tag.substring(4);
					buf.add('<img src="');
					buf.add(imgName);
					buf.add('"/>');
					// self-closing — no stack push
					i = closeIdx + 1;
				} else if (StringTools.startsWith(tag, "align:")) {
					var align = tag.substring(6);
					buf.add('<p align="');
					buf.add(align);
					buf.add('">');
					tagStack.push("p");
					i = closeIdx + 1;
				} else if (StringTools.startsWith(tag, "link:")) {
					var linkId = tag.substring(5);
					buf.add('<a href="');
					buf.add(linkId);
					buf.add('">');
					tagStack.push("a");
					i = closeIdx + 1;
				} else if (isValidStyleName(tag)) {
					// Named style: [damage] → <damage>, [b] → <_s_b> (escape HTML built-ins)
					var safeTag = escapeStyleName(tag);
					buf.add("<");
					buf.add(safeTag);
					buf.add(">");
					tagStack.push(safeTag);
					i = closeIdx + 1;
				} else {
					// Not a recognized tag — emit literal [tag]
					buf.addChar(ch);
					i++;
				}
			} else {
				buf.addChar(ch);
				i++;
			}
		}

		return buf.toString();
	}

	/**
	 * Check if a text string contains any [markup] patterns.
	 * To avoid false positives from natural text like "[red]" or "[note]",
	 * standalone [styleName] only counts as markup if there's also a [/] close tag.
	 * Self-closing tags ([img:], [align:], [link:]) are detected independently.
	 */
	public static function hasMarkup(text:String):Bool {
		if (text == null) return false;
		if (text.indexOf("[") < 0) return false;

		// Quick checks for definitive markup indicators
		var hasCloseTag = text.indexOf("[/]") >= 0;
		var hasSpecial = false;
		var idx = text.indexOf("[");
		while (idx >= 0 && idx + 1 < text.length) {
			// Skip [[ escape sequences
			if (text.charCodeAt(idx + 1) == "[".code) {
				idx = text.indexOf("[", idx + 2);
				continue;
			}
			var closeIdx = text.indexOf("]", idx + 1);
			if (closeIdx > idx + 1) {
				var tag = text.substring(idx + 1, closeIdx);
				if (StringTools.startsWith(tag, "img:") || StringTools.startsWith(tag, "align:")
					|| StringTools.startsWith(tag, "link:")) {
					hasSpecial = true;
					break;
				}
			}
			idx = text.indexOf("[", idx + 1);
		}
		return hasCloseTag || hasSpecial;
	}

	/**
	 * Extract all [styleName] references from text (not img:, align:, link:).
	 * Used for parse-time validation against defined styles.
	 */
	public static function extractStyleReferences(text:String):Array<String> {
		var refs:Array<String> = [];
		if (text == null) return refs;
		var idx = text.indexOf("[");
		while (idx >= 0 && idx + 1 < text.length) {
			// Skip [[ escape sequences
			if (idx + 1 < text.length && text.charCodeAt(idx + 1) == "[".code) {
				idx = text.indexOf("[", idx + 2);
				continue;
			}
			var closeIdx = text.indexOf("]", idx + 1);
			if (closeIdx > idx + 1) {
				var tag = text.substring(idx + 1, closeIdx);
				if (tag != "/" && !StringTools.startsWith(tag, "img:")
					&& !StringTools.startsWith(tag, "align:") && !StringTools.startsWith(tag, "link:") && isValidStyleName(tag)) {
					refs.push(tag);
				}
			}
			idx = text.indexOf("[", closeIdx > idx ? closeIdx : idx + 1);
		}
		return refs;
	}

	/**
	 * Resolve a color string to #RRGGBB hex format.
	 * Accepts: #RGB, #RRGGBB, #RRGGBBAA, named colors (red, blue, etc.)
	 */
	public static function resolveColorToHex(colorStr:String):String {
		if (colorStr == null || colorStr.length == 0) return "#000000";

		// Already a hex color
		if (StringTools.startsWith(colorStr, "#")) {
			var hex = colorStr.substring(1);
			if (hex.length == 3) {
				// #RGB → #RRGGBB
				return "#" + hex.charAt(0) + hex.charAt(0) + hex.charAt(1) + hex.charAt(1) + hex.charAt(2) + hex.charAt(2);
			}
			if (hex.length == 6) return colorStr;
			if (hex.length == 8) return "#" + hex.substring(0, 6); // strip alpha
			return colorStr;
		}

		// Try named color via MacroManimParser.tryStringToColor
		var resolved = MacroManimParser.tryStringToColor(colorStr);
		if (resolved != null) {
			// 0xAARRGGBB → #RRGGBB
			return "#" + StringTools.hex(resolved & 0xFFFFFF, 6);
		}

		// Fallback: return as-is (let Heaps try to parse it)
		return colorStr;
	}

	/** Escape a style name that collides with built-in HtmlText tags (b, i, bold, italic, font).
	 *  Returns the safe internal name for use in HTML output and defineHtmlTag. */
	public static function escapeStyleName(name:String):String {
		return if (isReservedHtmlTag(name)) "_s_" + name else name;
	}

	static function isReservedHtmlTag(name:String):Bool {
		return name == "b" || name == "i" || name == "u" || name == "s"
			|| name == "bold" || name == "italic"
			|| name == "font";
	}

	static function escapeXmlChars(text:String):String {
		if (text.indexOf("&") < 0 && text.indexOf("<") < 0 && text.indexOf(">") < 0) return text;
		var buf = new StringBuf();
		for (i in 0...text.length) {
			switch (text.charCodeAt(i)) {
				case "&".code:
					buf.add("&amp;");
				case "<".code:
					buf.add("&lt;");
				case ">".code:
					buf.add("&gt;");
				default:
					buf.addChar(text.charCodeAt(i));
			}
		}
		return buf.toString();
	}

	static function isValidStyleName(name:String):Bool {
		if (name.length == 0) return false;
		// First character must be a letter or underscore (not a digit)
		var first = name.charCodeAt(0);
		if (!((first >= "a".code && first <= "z".code) || (first >= "A".code && first <= "Z".code) || first == "_".code)) return false;
		for (i in 1...name.length) {
			var c = name.charCodeAt(i);
			if (!((c >= "a".code && c <= "z".code) || (c >= "A".code && c <= "Z".code) || (c >= "0".code && c <= "9".code) || c == "_".code)) {
				return false;
			}
		}
		return true;
	}
}
