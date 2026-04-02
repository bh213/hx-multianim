package bh.multianim;

import bh.multianim.MultiAnimParser;

/**
 * Keyword metadata derived from parser enums for LSP/tooling use.
 * Uses exhaustive switch matching where practical — adding a new enum
 * variant forces updating the metadata here (compile error otherwise).
 *
 * For enums with many params (like NodeType.FLOW), uses Type.enumConstructor()
 * to avoid fragile wildcard patterns that break when params are added.
 */
class ManimKeywordInfo {
	// ---- Elements (from NodeType) ----

	/** Map enum constructor name to display name. */
	static final elementNames:Map<String, String> = [
		"FLOW" => "flow", "SPACER" => "spacer", "BITMAP" => "bitmap", "POINT" => "point",
		"STATEANIM" => "stateanim", "STATEANIM_CONSTRUCT" => "stateanim",
		"PIXELS" => "pixels", "TEXT" => "text", "RICHTEXT" => "richText",
		"PROGRAMMABLE" => "programmable", "TILEGROUP" => "tilegroup",
		"RELATIVE_LAYOUTS" => "layout", "PATHS" => "paths",
		"ANIMATED_PATH" => "animatedPath", "CURVES" => "curves",
		"PARTICLES" => "particles", "APPLY" => "apply", "LAYERS" => "layers",
		"MASK" => "mask", "REPEAT" => "repeatable", "REPEAT2D" => "repeatable2d",
		"STATIC_REF" => "staticRef", "PLACEHOLDER" => "placeholder",
		"DYNAMIC_REF" => "dynamicRef", "SLOT" => "slot", "SLOT_CONTENT" => "slotContent",
		"INTERACTIVE" => "interactive", "GRAPHICS" => "graphics",
		"DATA" => "data", "AUTOTILE" => "autotile", "ATLAS2" => "atlas2",
		"PALETTE" => "palette", "FINAL_VAR" => "@final", "NINEPATCH" => "ninepatch",
	];

	static final elementDescriptions:Map<String, String> = [
		"FLOW" => "Layout flow container with overflow, alignment, spacing",
		"SPACER" => "Empty space: spacer(w, h)",
		"BITMAP" => "Display image: bitmap(source, [center])",
		"POINT" => "Positioning point for coordinate reference",
		"STATEANIM" => "State animation from .anim file",
		"STATEANIM_CONSTRUCT" => "Inline state animation construct",
		"PIXELS" => "Pixel-level drawing primitives",
		"TEXT" => "Simple text element (h2d.Text)",
		"RICHTEXT" => "Rich text with [markup] (h2d.HtmlText)",
		"PROGRAMMABLE" => "Parameterized UI component",
		"TILEGROUP" => "Optimized tile grouping container",
		"RELATIVE_LAYOUTS" => "Relative layout definitions",
		"PATHS" => "Path shape definitions",
		"ANIMATED_PATH" => "Animated path with curves and events",
		"CURVES" => "Curve function definitions",
		"PARTICLES" => "Particle effect system",
		"APPLY" => "Apply properties to parent element",
		"LAYERS" => "Z-ordering container",
		"MASK" => "Clipping mask rectangle: mask(w, h)",
		"REPEAT" => "Loop elements: repeatable($var, iterator)",
		"REPEAT2D" => "2D loop: repeatable2d($x, $y, iterX, iterY)",
		"STATIC_REF" => "Static embed of another programmable",
		"PLACEHOLDER" => "Dynamic placeholder for runtime content",
		"DYNAMIC_REF" => "Dynamic embed with runtime parameter updates",
		"SLOT" => "Swappable container (plain or parameterized)",
		"SLOT_CONTENT" => "Content inside a parameterized slot",
		"INTERACTIVE" => "Hit-test region: interactive(w, h, id)",
		"GRAPHICS" => "Vector graphics drawing",
		"DATA" => "Static typed data block",
		"AUTOTILE" => "Autotile terrain pattern",
		"ATLAS2" => "Inline sprite atlas definition",
		"PALETTE" => "Color palette definition",
		"FINAL_VAR" => "Immutable named constant",
		"NINEPATCH" => "9-patch scalable image: ninepatch(sheet, tile, w, h)",
	];

	static final elementSnippets:Map<String, String> = [
		"FLOW" => "flow($1) {\n\t$0\n}",
		"PROGRAMMABLE" => "#${1:name} programmable($2) {\n\t$0\n}",
		"PARTICLES" => "#${1:name} particles {\n\t$0\n}",
		"CURVES" => "curves {\n\t$0\n}",
		"PATHS" => "paths {\n\t$0\n}",
		"ANIMATED_PATH" => "#${1:name} animatedPath {\n\tpath: ${2:pathName}\n\t$0\n}",
		"DATA" => "#${1:name} data {\n\t$0\n}",
		"MASK" => "mask($1, $2) {\n\t$0\n}",
		"LAYERS" => "layers {\n\t$0\n}",
		"SLOT" => "#${1:name} slot",
		"ATLAS2" => "#${1:name} atlas2(\"$2\") {\n\t$0\n}",
		"PALETTE" => "#${1:name} palette {\n\t$0\n}",
		"FINAL_VAR" => "@final ${1:NAME} = $0",
		"REPEAT" => "repeatable(\\$$1, ${2:iterator}) {\n\t$0\n}",
		"REPEAT2D" => "repeatable2d(\\$$1, \\$$2, ${3:iterX}, ${4:iterY}) {\n\t$0\n}",
	];

	static final topLevelElements:Array<String> = [
		"PROGRAMMABLE", "DATA", "CURVES", "PATHS", "ANIMATED_PATH",
		"ATLAS2", "PALETTE", "FINAL_VAR", "RELATIVE_LAYOUTS",
	];

	static final childElements:Array<String> = [
		"BITMAP", "TEXT", "RICHTEXT", "NINEPATCH", "FLOW",
		"LAYERS", "MASK", "TILEGROUP", "INTERACTIVE", "SLOT", "SLOT_CONTENT", "SPACER",
		"POINT", "APPLY", "GRAPHICS", "PIXELS", "PARTICLES", "REPEAT", "REPEAT2D",
		"STATIC_REF", "DYNAMIC_REF", "PLACEHOLDER", "STATEANIM", "STATEANIM_CONSTRUCT",
		"AUTOTILE", "FINAL_VAR",
	];

	public static function elementName(ctor:String):Null<String> {
		return elementNames.get(ctor);
	}

	public static function elementDescription(ctor:String):Null<String> {
		return elementDescriptions.get(ctor);
	}

	public static function elementSnippet(ctor:String):Null<String> {
		return elementSnippets.get(ctor);
	}

	public static function isTopLevel(ctor:String):Bool {
		return topLevelElements.contains(ctor);
	}

	public static function isChildElement(ctor:String):Bool {
		return childElements.contains(ctor);
	}

	/** All known NodeType constructor names. Kept in sync manually — sync-check validates. */
	public static final allElementCtors:Array<String> = [
		"FLOW", "SPACER", "BITMAP", "POINT", "STATEANIM", "STATEANIM_CONSTRUCT",
		"PIXELS", "TEXT", "RICHTEXT", "PROGRAMMABLE", "TILEGROUP", "RELATIVE_LAYOUTS",
		"PATHS", "ANIMATED_PATH", "CURVES", "PARTICLES", "APPLY", "LAYERS", "MASK",
		"REPEAT", "REPEAT2D", "STATIC_REF", "PLACEHOLDER", "DYNAMIC_REF",
		"SLOT", "SLOT_CONTENT", "INTERACTIVE", "GRAPHICS", "DATA", "AUTOTILE",
		"ATLAS2", "PALETTE", "FINAL_VAR", "NINEPATCH",
	];

	// ---- Parameter types (from DefinitionType — exhaustive switch) ----

	public static function paramTypeName(type:DefinitionType):String {
		return switch (type) {
			case PPTInt: "int";
			case PPTUnsignedInt: "uint";
			case PPTFloat: "float";
			case PPTBool: "bool";
			case PPTString: "string";
			case PPTColor: "color";
			case PPTTile: "tile";
			case PPTArray: "array";
			case PPTHexDirection: "hexDirection";
			case PPTGridDirection: "gridDirection";
			case PPTEnum(values): '[${values.join(",")}]';
			case PPTRange(from, to): '$from..$to';
			case PPTFlags(bits): 'flags($bits)';
		};
	}

	public static function paramTypeDescription(type:DefinitionType):String {
		return switch (type) {
			case PPTInt: "Integer parameter";
			case PPTUnsignedInt: "Unsigned integer parameter (>= 0)";
			case PPTFloat: "Floating point parameter";
			case PPTBool: "Boolean parameter (true/false)";
			case PPTString: "String parameter";
			case PPTColor: "Color parameter (#RRGGBB)";
			case PPTTile: "Tile parameter (h2d.Tile, no default allowed)";
			case PPTArray: "Array parameter";
			case PPTHexDirection: "Hex direction enum";
			case PPTGridDirection: "Grid direction enum";
			case PPTEnum(_): "Enum parameter with specific values";
			case PPTRange(_, _): "Integer range parameter";
			case PPTFlags(_): "Bit flags parameter";
		};
	}

	public static final simpleParamTypes:Array<DefinitionType> = [
		PPTInt, PPTUnsignedInt, PPTFloat, PPTBool, PPTString, PPTColor, PPTTile,
		PPTArray, PPTHexDirection, PPTGridDirection,
	];

	// ---- Filters (from FilterType — exhaustive switch) ----

	public static function filterName(type:FilterType):String {
		return switch (type) {
			case FilterNone: "none";
			case FilterGroup(_): "group";
			case FilterOutline(_, _): "outline";
			case FilterSaturate(_): "saturate";
			case FilterBrightness(_): "brightness";
			case FilterGrayscale(_): "grayscale";
			case FilterHue(_): "hue";
			case FilterGlow(_, _, _, _, _, _, _): "glow";
			case FilterBlur(_, _, _, _): "blur";
			case FilterDropShadow(_, _, _, _, _, _, _, _): "dropShadow";
			case FilterPixelOutline(_, _): "pixelOutline";
			case FilterPaletteReplace(_, _, _): "replacePalette";
			case FilterColorListReplace(_, _): "replaceColor";
			case FilterCustom(_, _): "custom";
		};
	}

	public static function filterDescription(type:FilterType):String {
		return switch (type) {
			case FilterNone: "Remove all filters";
			case FilterGroup(_): "Group multiple filters: group(filter1, filter2)";
			case FilterOutline(_, _): "Outline: outline(size, color)";
			case FilterSaturate(_): "Saturation: saturate(value) — 1.0 = normal";
			case FilterBrightness(_): "Brightness: brightness(value) — 1.0 = normal";
			case FilterGrayscale(_): "Grayscale: grayscale(value) — 0.0-1.0";
			case FilterHue(_): "Hue shift: hue(degrees)";
			case FilterGlow(_, _, _, _, _, _, _): "Glow: glow(color, alpha, radius, [gain, quality, smoothColor, knockout])";
			case FilterBlur(_, _, _, _): "Blur: blur(radius, [gain, quality, linear])";
			case FilterDropShadow(_, _, _, _, _, _, _, _): "Drop shadow: dropShadow(distance, angle, color, alpha, radius)";
			case FilterPixelOutline(_, _): "Pixel-perfect outline";
			case FilterPaletteReplace(_, _, _): "Palette replacement";
			case FilterColorListReplace(_, _): "Color replacement: replaceColor: [#src] => [#dst]";
			case FilterCustom(_, _): "Custom registered filter";
		};
	}

	public static final completableFilters:Array<FilterType> = [
		FilterOutline(null, null), FilterGlow(null, null, null, null, null, false, false),
		FilterBlur(null, null, null, null), FilterSaturate(null), FilterBrightness(null),
		FilterGrayscale(null), FilterHue(null), FilterDropShadow(null, null, null, null, null, null, null, false),
		FilterPixelOutline(null, false), FilterPaletteReplace("", null, null),
		FilterColorListReplace(null, null), FilterGroup(null), FilterNone,
	];

	// ---- Transitions (from TransitionType — exhaustive switch) ----

	public static function transitionName(type:TransitionType):String {
		return switch (type) {
			case TransNone: "none";
			case TransFade(_, _): "fade";
			case TransCrossfade(_, _): "crossfade";
			case TransFlipX(_, _): "flipX";
			case TransFlipY(_, _): "flipY";
			case TransSlide(_, _, _, _): "slide";
		};
	}

	public static function transitionDescription(type:TransitionType):String {
		return switch (type) {
			case TransNone: "No transition (instant)";
			case TransFade(_, _): "Fade transition: fade(duration, easing)";
			case TransCrossfade(_, _): "Crossfade: crossfade(duration, easing)";
			case TransFlipX(_, _): "Horizontal flip: flipX(duration, easing)";
			case TransFlipY(_, _): "Vertical flip: flipY(duration, easing)";
			case TransSlide(_, _, _, _): "Slide: slide(direction, duration, [distance, easing])";
		};
	}

	public static function transitionSnippet(type:TransitionType):Null<String> {
		return switch (type) {
			case TransNone: null;
			case TransFade(_, _): "fade($1, $2)";
			case TransCrossfade(_, _): "crossfade($1, $2)";
			case TransFlipX(_, _): "flipX($1, $2)";
			case TransFlipY(_, _): "flipY($1, $2)";
			case TransSlide(_, _, _, _): "slide($1, $2)";
		};
	}

	public static final allTransitions:Array<TransitionType> = [
		TransNone, TransFade(0, null), TransCrossfade(0, null),
		TransFlipX(0, null), TransFlipY(0, null), TransSlide(TDLeft, 0, null, null),
	];

	// ---- Easings (from EasingType — exhaustive switch) ----

	public static function easingName(type:EasingType):String {
		return switch (type) {
			case Linear: "linear";
			case EaseInQuad: "easeInQuad";
			case EaseOutQuad: "easeOutQuad";
			case EaseInOutQuad: "easeInOutQuad";
			case EaseInCubic: "easeInCubic";
			case EaseOutCubic: "easeOutCubic";
			case EaseInOutCubic: "easeInOutCubic";
			case EaseInBack: "easeInBack";
			case EaseOutBack: "easeOutBack";
			case EaseInOutBack: "easeInOutBack";
			case EaseOutBounce: "easeOutBounce";
			case EaseOutElastic: "easeOutElastic";
			case CubicBezier(_, _, _, _): "cubicBezier";
		};
	}

	public static final allEasings:Array<EasingType> = [
		Linear, EaseInQuad, EaseOutQuad, EaseInOutQuad,
		EaseInCubic, EaseOutCubic, EaseInOutCubic,
		EaseInBack, EaseOutBack, EaseInOutBack,
		EaseOutBounce, EaseOutElastic,
	];

	// ---- Path commands (from ParsedPaths — exhaustive switch) ----

	public static function pathName(type:ParsedPaths):String {
		return switch (type) {
			case MoveTo(_, _): "moveTo";
			case LineTo(_, _): "lineTo";
			case Forward(_): "forward";
			case TurnDegrees(_): "turn";
			case Checkpoint(_): "checkpoint";
			case Bezier2To(_, _, _, _): "quadratic";
			case Bezier3To(_, _, _, _, _): "bezier";
			case Arc(_, _): "arc";
			case Close: "close";
			case Spiral(_, _, _): "spiral";
			case Wave(_, _, _): "wave";
		};
	}

	public static function pathDescription(type:ParsedPaths):String {
		return switch (type) {
			case MoveTo(_, _): "Move to point: moveTo(x, y)";
			case LineTo(_, _): "Line to point: lineTo(x, y)";
			case Forward(_): "Move forward: forward(distance)";
			case TurnDegrees(_): "Turn angle: turn(degrees)";
			case Checkpoint(_): "Named checkpoint: checkpoint(\"name\")";
			case Bezier2To(_, _, _, _): "Quadratic curve: quadratic(cpx, cpy, endx, endy)";
			case Bezier3To(_, _, _, _, _): "Cubic bezier: bezier(cp1x, cp1y, cp2x, cp2y[, ex, ey])";
			case Arc(_, _): "Arc segment: arc(radius, angleDelta)";
			case Close: "Close path back to start";
			case Spiral(_, _, _): "Spiral: spiral(radiusStart, radiusEnd, angleDelta)";
			case Wave(_, _, _): "Wave: wave(amplitude, wavelength, count)";
		};
	}

	public static final allPathCommands:Array<ParsedPaths> = [
		MoveTo(null, null), LineTo(null, null), Forward(null), TurnDegrees(null),
		Checkpoint(""), Bezier2To(null, null, null, null), Bezier3To(null, null, null, null, null),
		Arc(null, null), Close, Spiral(null, null, null), Wave(null, null, null),
	];

	// ---- Curve operations (from CurveOperation — exhaustive switch) ----

	public static function curveName(type:CurveOperation):String {
		return switch (type) {
			case Multiply(_): "multiply";
			case Compose(_, _): "apply";
			case Invert(_): "invert";
			case Scale(_, _): "scale";
		};
	}

	public static function curveDescription(type:CurveOperation):String {
		return switch (type) {
			case Multiply(_): "Multiply curves: multiply: [curve1, curve2]";
			case Compose(_, _): "Apply composition: apply: inner, outer";
			case Invert(_): "Invert curve: invert: curveName";
			case Scale(_, _): "Scale curve: scale: curveName, factor";
		};
	}

	public static final allCurveOps:Array<CurveOperation> = [
		Multiply(null), Compose("", ""), Invert(""), Scale("", null),
	];
}
