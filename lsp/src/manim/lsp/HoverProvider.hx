package manim.lsp;

import manim.lsp.LspTypes;

using StringTools;

/**
 * Provides hover documentation for .manim keywords and constructs.
 */
class HoverProvider {
	public static function getHover(word:String, text:String, uri:String):Null<LspHover> {
		// Strip prefix characters for lookup
		final cleanWord = if (word.startsWith("$") || word.startsWith("#") || word.startsWith("@"))
			word.substr(1)
		else
			word;

		final doc = lookupKeyword(word) ?? lookupKeyword(cleanWord);
		if (doc != null) {
			return {contents: {kind: "markdown", value: doc}};
		}

		// Check if it's a color literal
		if (word.startsWith("#") && (word.length == 4 || word.length == 7 || word.length == 9)) {
			final isHex = ~/^#[0-9a-fA-F]+$/.match(word);
			if (isHex) {
				return {contents: {kind: "markdown", value: 'Color: `$word`'}};
			}
		}

		// Check if it's a $parameter reference — look up type from file
		if (word.startsWith("$")) {
			final paramInfo = findParamInfo(cleanWord, text);
			if (paramInfo != null) return {contents: {kind: "markdown", value: paramInfo}};
		}

		return null;
	}

	static function findParamInfo(paramName:String, text:String):Null<String> {
		// Search for "paramName:type=default" pattern in programmable declarations
		final pattern = new EReg('\\b$paramName\\s*:\\s*(\\w+|\\[[^\\]]*\\]|\\d+\\.\\.\\d+)', '');
		if (pattern.match(text)) {
			final matched = pattern.matched(0);
			return '**Parameter** `$$$paramName`\n\n`$matched`';
		}
		return null;
	}

	static function lookupKeyword(word:String):Null<String> {
		return switch (word) {
			// Elements
			case "programmable":
				"**programmable** — Define a parameterized UI component\n\n```manim\n#name programmable(param:type=default) {\n  // elements...\n}\n```";
			case "bitmap":
				"**bitmap** — Display an image\n\n```manim\nbitmap(source, [center])\nbitmap(\"sheet\", \"tile\")\nbitmap(file(\"image.png\"))\nbitmap(generated(color(w, h, #color)))\n```";
			case "text":
				"**text** — Simple text element (h2d.Text)\n\n```manim\ntext(font, \"content\", #color, [align, maxWidth])\n```\n\nOptions: `letterSpacing`, `lineSpacing`, `lineBreak`, `dropShadow*`, `autoFit`";
			case "richText":
				"**richText** — Rich text with [markup] (h2d.HtmlText)\n\n```manim\nrichText(font, \"content\", #color, [align, maxWidth])\n```\n\nAdditional options: `styles:`, `images:`, `condenseWhite`";
			case "ninepatch":
				"**ninepatch** — 9-patch scalable image\n\n```manim\nninepatch(sheet, tile, width, height)\n```";
			case "flow":
				"**flow** — Layout flow container\n\n```manim\nflow(maxWidth, maxHeight, [layout]) {\n  // children...\n}\n```\n\nOptions: `overflow`, `fillWidth`, `fillHeight`, `reverse`, `horizontalAlign`, `verticalAlign`";
			case "layers":
				"**layers** — Z-ordering container\n\nChildren use `layer: N` for ordering.";
			case "mask":
				"**mask** — Clipping mask rectangle\n\n```manim\nmask(width, height) { ... }\n```";
			case "interactive":
				"**interactive** — Hit-test region\n\n```manim\ninteractive(width, height, id)\ninteractive(w, h, id, debug)\ninteractive(w, h, id, key => value, ...)\n```\n\nMetadata: `key => val`, `key:int => N`, `key:float => N`";
			case "slot":
				"**slot** — Swappable container\n\n```manim\n#name slot\n#name[$i] slot              // indexed\n#name slot(param:type=default) // parameterized\n```";
			case "spacer":
				"**spacer** — Empty space inside flow containers\n\n```manim\nspacer(width, height)\n```";
			case "point":
				"**point** — Positioning point for coordinate reference";
			case "apply":
				"**apply** — Apply properties to parent element";
			case "graphics":
				"**graphics** — Vector graphics drawing\n\n```manim\ngraphics(color, lineWidth) { line(x1,y1,x2,y2) }\n```";
			case "pixels":
				"**pixels** — Pixel-level drawing primitives";
			case "particles":
				"**particles** — Particle effect system\n\n```manim\n#name particles {\n  count: 100\n  emit: point()\n  tiles: file(\"particle.png\")\n  maxLife: 2.0\n  speed: 50\n}\n```";
			case "repeatable":
				"**repeatable** — Loop elements over an iterator\n\n```manim\nrepeatable($var, step(count, start, end)) { ... }\nrepeatable($var, layout(name)) { ... }\nrepeatable($var, array(a, b, c)) { ... }\n```";
			case "repeatable2d":
				"**repeatable2d** — 2D loop\n\n```manim\nrepeatable2d($x, $y, iterX, iterY) { ... }\n```";
			case "staticRef":
				"**staticRef** — Embed another programmable (static, no runtime updates)\n\n```manim\nstaticRef($ref)\nstaticRef($ref, param1, param2)\n```";
			case "dynamicRef":
				"**dynamicRef** — Embed with runtime parameter updates\n\n```manim\ndynamicRef($ref, param1, param2)\n```";
			case "placeholder":
				"**placeholder** — Dynamic placeholder for runtime content\n\n```manim\nplaceholder(size, source)\n```";
			case "stateanim":
				"**stateanim** — Inline state animation\n\n```manim\nstateanim construct(...)\n```";
			case "tilegroup":
				"**tilegroup** — Optimized tile grouping container\n\nSupports: `bitmap`, `ninepatch`, `repeatable`, `pixels`, `point`";

			// Blocks
			case "settings":
				"**settings** — Component settings block\n\n```manim\nsettings {\n  key:type => value\n}\n```";
			case "transition":
				"**transition** — Animated transitions for parameter changes\n\n```manim\ntransition {\n  param: crossfade(0.1, easeOutQuad)\n}\n```\n\nTypes: `none`, `fade`, `crossfade`, `flipX`, `flipY`, `slide`";
			case "curves":
				"**curves** — Define curve functions\n\n```manim\ncurves {\n  #name curve { easing: easeInQuad }\n  #name curve { points: [(0,0), (1,1)] }\n  #name curve { multiply: [a, b] }\n}\n```";
			case "paths":
				"**paths** — Define path shapes\n\n```manim\npaths {\n  #name lineTo(x,y), bezier(cpx,cpy,ex,ey)\n}\n```";
			case "animatedPath":
				"**animatedPath** — Animated path with curves and events\n\n```manim\n#name animatedPath {\n  path: myPath\n  type: time\n  duration: 1.0\n  easing: easeOutCubic\n}\n```";
			case "data":
				"**data** — Static typed data block\n\n```manim\n#name data {\n  field:type = value\n}\n```";
			case "import":
				"**import** — Import external .manim file\n\n```manim\nimport \"file.manim\" as \"name\"\n```";
			case "version":
				"**version** — File version header\n\n```manim\nversion: 1.0\n```";

			// Directives
			case "@final" | "final":
				"**@final** — Immutable named constant\n\n```manim\n@final NAME = 42\n// Use as $NAME\n```";
			case "@else" | "else":
				"**@else** — Matches when preceding @() condition didn't match\n\n```manim\n@(param=>value) element1\n@else element2\n@else(param=>other) element3\n```";
			case "@default" | "default":
				"**@default** — Final fallback (always matches)";
			case "@if":
				"**@if** — Explicit conditional (same as `@()`)\n\n```manim\n@if(param=>value) element\n```";
			case "@ifstrict":
				"**@ifstrict** — Strict matching (must match ALL specified params)";

			// Filter types
			case "outline":
				"**outline** filter — `outline(size, color)`";
			case "glow":
				"**glow** filter — `glow(color, alpha, radius, [gain, quality, smoothColor, knockout])`";
			case "blur":
				"**blur** filter — `blur(radius, [gain, quality, linear])`";
			case "saturate":
				"**saturate** filter — `saturate(value)` — 1.0 = normal";
			case "brightness":
				"**brightness** filter — `brightness(value)` — 1.0 = normal";
			case "grayscale":
				"**grayscale** filter — `grayscale(value)` — 0.0-1.0";
			case "hue":
				"**hue** filter — `hue(degrees)`";
			case "dropShadow":
				"**dropShadow** filter — `dropShadow(distance, angle, color, alpha, radius)`";
			case "pixelOutline":
				"**pixelOutline** filter — pixel-perfect outline";
			case "replacePalette":
				"**replacePalette** filter — replace palette colors";
			case "replaceColor":
				"**replaceColor** filter — `replaceColor: [#src1, #src2] => [#dst1, #dst2]`";

			// Parameter types
			case "int":
				"**int** — Integer parameter type";
			case "uint":
				"**uint** — Unsigned integer parameter type (>= 0)";
			case "float":
				"**float** — Floating point parameter type";
			case "bool":
				"**bool** — Boolean parameter type (true/false)";
			case "string":
				"**string** — String parameter type";
			case "color":
				"**color** — Color parameter type (#RRGGBB)";
			case "tile":
				"**tile** — Tile parameter type (h2d.Tile, no default allowed)";

			// Coordinate systems
			case "grid":
				"**$grid** — Grid coordinate system\n\n`$grid.pos(x, y)` — grid position\n`$grid.width` / `$grid.height` — cell dimensions";
			case "hex":
				"**$hex** — Hexagonal coordinate system\n\n`$hex.cube(q, r, s)` — cube coords\n`$hex.corner(index, scale)` — corner position\n`$hex.edge(direction, scale)` — edge midpoint";
			case "ctx":
				"**$ctx** — Context properties\n\n`$ctx.width` / `$ctx.height` — scene dimensions\n`$ctx.random(min, max)` — random value\n`$ctx.font(\"name\").lineHeight` — font metrics";

			default: null;
		};
	}
}
