package bh.multianim;

/**
 * Converts manim-native %{tag}...%{/} rich text markup to HTML for h2d.HtmlText.
 *
 * Supported markup:
 *   %{styleName}...%{/}        → <styleName>...</styleName>     (requires defineHtmlTag)
 *   %{img:name}                → <img src="name"/>               (self-closing)
 *   %{align:left|center|right}...%{/} → <p align="...">...</p>
 *   %{link:id}...%{/}          → <a href="id">...</a>
 *   %{/}                       → closes most recently opened tag (stack-based)
 *   %%{                         → literal %{ (escape sequence)
 *
 * Colors and fonts are set via named styles (styles: {name: color(...) font(...)}).
 * Inline %{c:} and %{f:} are no longer supported.
 *
 * Works at both macro time and runtime (no runtime-only APIs).
 */
class TextMarkupConverter {
	/**
	 * Convert %{tag}...%{/} markup to HTML.
	 * If no markup found, returns input unchanged.
	 */
	public static function convert(text:String):String {
		if (text == null || text.length == 0) return text;
		if (text.indexOf("%{") < 0) return text;

		var buf = new StringBuf();
		var tagStack:Array<String> = [];
		var i = 0;
		var len = text.length;

		while (i < len) {
			var ch = text.charCodeAt(i);
			if (ch == "%".code && i + 1 < len && text.charCodeAt(i + 1) == "%".code && i + 2 < len && text.charCodeAt(i + 2) == "{".code) {
				// %%{ → literal %{
				buf.add("%{");
				i += 3;
			} else if (ch == "%".code && i + 1 < len && text.charCodeAt(i + 1) == "{".code) {
				var closeIdx = text.indexOf("}", i + 2);
				if (closeIdx < 0) {
					buf.addChar(ch);
					i++;
					continue;
				}

				var tag = text.substring(i + 2, closeIdx);

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
				} else {
					// Named style: %{damage} → <damage>
					buf.add("<");
					buf.add(tag);
					buf.add(">");
					tagStack.push(tag);
					i = closeIdx + 1;
				}
			} else {
				buf.addChar(ch);
				i++;
			}
		}

		return buf.toString();
	}

	/** Check if a text string contains any %{markup} patterns. */
	public static function hasMarkup(text:String):Bool {
		if (text == null) return false;
		var idx = text.indexOf("%{");
		while (idx >= 0 && idx + 2 < text.length) {
			// Skip %%{ escape sequences
			if (idx > 0 && text.charCodeAt(idx - 1) == "%".code) {
				idx = text.indexOf("%{", idx + 1);
				continue;
			}
			var closeIdx = text.indexOf("}", idx + 2);
			if (closeIdx > idx + 2) {
				var tag = text.substring(idx + 2, closeIdx);
				if (tag == "/" || StringTools.startsWith(tag, "img:")
					|| StringTools.startsWith(tag, "align:") || StringTools.startsWith(tag, "link:") || isValidStyleName(tag)) {
					return true;
				}
			}
			idx = text.indexOf("%{", idx + 1);
		}
		return false;
	}

	/**
	 * Extract all %{styleName} references from text (not img:, align:, link:).
	 * Used for parse-time validation against defined styles.
	 */
	public static function extractStyleReferences(text:String):Array<String> {
		var refs:Array<String> = [];
		if (text == null) return refs;
		var idx = text.indexOf("%{");
		while (idx >= 0 && idx + 2 < text.length) {
			// Skip %%{ escape sequences
			if (idx > 0 && text.charCodeAt(idx - 1) == "%".code) {
				idx = text.indexOf("%{", idx + 1);
				continue;
			}
			var closeIdx = text.indexOf("}", idx + 2);
			if (closeIdx > idx + 2) {
				var tag = text.substring(idx + 2, closeIdx);
				if (tag != "/" && !StringTools.startsWith(tag, "img:")
					&& !StringTools.startsWith(tag, "align:") && !StringTools.startsWith(tag, "link:") && isValidStyleName(tag)) {
					refs.push(tag);
				}
			}
			idx = text.indexOf("%{", closeIdx > idx ? closeIdx : idx + 1);
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

	static function isValidStyleName(name:String):Bool {
		if (name.length == 0) return false;
		for (i in 0...name.length) {
			var c = name.charCodeAt(i);
			if (!((c >= "a".code && c <= "z".code) || (c >= "A".code && c <= "Z".code) || (c >= "0".code && c <= "9".code) || c == "_".code)) {
				return false;
			}
		}
		return true;
	}
}
