package manim.lsp;

import manim.lsp.LspTypes;
import manim.lsp.ContextAnalyzer;

using StringTools;

/**
 * Provides context-aware completion items for .manim files.
 */
class CompletionProvider {
	public static function getCompletions(ctx:CursorContextResult):Array<LspCompletionItem> {
		return switch (ctx.context) {
			case TopLevel: topLevelCompletions();
			case ProgrammableBody | RepeatableBody: elementCompletions();
			case FlowBody: flowCompletions();
			case ParticlesBody: particleCompletions();
			case CurvesBody: curvesBodyCompletions();
			case CurveBody: curveCompletions();
			case PathsBody: pathCompletions();
			case AnimatedPathBody: animatedPathCompletions();
			case SettingsBody: settingsCompletions();
			case TransitionBody: transitionCompletions();
			case FilterPosition: filterCompletions();
			case ProgrammableParams: paramTypeCompletions();
			case DataBody: [];
			case InteractiveParams: [];
			case AfterDollar(prefix): referenceCompletions(ctx.paramNames, prefix);
			case AfterAt: conditionalCompletions();
			case AfterConditionalOpen: paramNameCompletions(ctx.paramNames);
			case EasingPosition: easingCompletions();
			case Unknown: elementCompletions(); // Best guess
		};
	}

	static function topLevelCompletions():Array<LspCompletionItem> {
		return [
			snippet("programmable", "#name programmable($1) {\n\t$0\n}", "Define a programmable UI component"),
			snippet("data", "#name data {\n\t$0\n}", "Define a typed data block"),
			snippet("curves", "curves {\n\t$0\n}", "Define curve functions"),
			snippet("paths", "paths {\n\t$0\n}", "Define path shapes"),
			snippet("animatedPath", "#name animatedPath {\n\t$0\n}", "Define an animated path"),
			snippet("import", "import \"$1\" as \"$2\"", "Import external .manim file"),
			snippet("@final", "@final $1 = $0", "Define an immutable constant"),
			kw("version:", "File version header"),
			snippet("atlas2", "#name atlas2(\"$1\") {\n\t$0\n}", "Inline sprite atlas"),
			snippet("palette", "#name palette {\n\t$0\n}", "Color palette"),
		];
	}

	static function elementCompletions():Array<LspCompletionItem> {
		return [
			kw("bitmap", "Display image: bitmap(source, [center])"),
			kw("text", "Text element: text(font, text, color, [align, maxWidth])"),
			kw("richText", "Rich text with markup: richText(font, text, color, [align, maxWidth])"),
			kw("ninepatch", "9-patch scalable: ninepatch(sheet, tile, w, h)"),
			kw("flow", "Layout flow container"),
			kw("layers", "Z-ordering container"),
			kw("mask", "Clipping mask: mask(w, h)"),
			kw("tilegroup", "Optimized tile grouping"),
			kw("interactive", "Hit-test region: interactive(w, h, id)"),
			snippet("slot", "#name slot", "Swappable container"),
			kw("spacer", "Empty space: spacer(w, h)"),
			kw("point", "Positioning point"),
			kw("apply", "Apply properties to parent"),
			kw("graphics", "Vector graphics"),
			kw("pixels", "Pixel primitives"),
			snippet("particles", "particles {\n\t$0\n}", "Particle effect"),
			kw("repeatable", "Loop elements: repeatable($var, iterator)"),
			kw("repeatable2d", "2D loop: repeatable2d($x, $y, iterX, iterY)"),
			kw("staticRef", "Static embed: staticRef($ref)"),
			kw("dynamicRef", "Dynamic embed: dynamicRef($ref, params)"),
			kw("placeholder", "Dynamic placeholder"),
			kw("stateanim", "State animation"),
			snippet("settings", "settings {\n\t$0\n}", "Component settings block"),
			snippet("transition", "transition {\n\t$0\n}", "Animated parameter transitions"),
			kw("filter:", "Apply visual filter"),
			kw("blendMode:", "Set blend mode"),
			kw("scale:", "Set scale"),
			kw("alpha:", "Set alpha/opacity"),
			kw("rotation:", "Set rotation"),
			kw("tint:", "Set color tint"),
			kw("layer:", "Set render layer"),
			snippet("@final", "@final $1 = $0", "Define a constant"),
		];
	}

	static function flowCompletions():Array<LspCompletionItem> {
		final items = elementCompletions();
		items.push(kw("overflow:", "Flow overflow: expand|limit|scroll|hidden"));
		items.push(kw("fillWidth:", "Fill width: true|false"));
		items.push(kw("fillHeight:", "Fill height: true|false"));
		items.push(kw("reverse:", "Reverse order: true|false"));
		items.push(kw("horizontalAlign:", "Default horizontal align: left|right|middle"));
		items.push(kw("verticalAlign:", "Default vertical align: top|bottom|middle"));
		return items;
	}

	static function particleCompletions():Array<LspCompletionItem> {
		return [
			kw("count", "Number of particles"),
			kw("emit", "Emission shape: point|cone|box|circle|path"),
			kw("tiles", "Particle tile: file(\"img.png\") or sheet(\"atlas\", \"tile\")"),
			kw("loop", "Loop emission: true|false"),
			kw("maxLife", "Maximum particle lifetime (seconds)"),
			kw("speed", "Initial particle speed"),
			kw("speedRandom", "Speed randomization (0-1)"),
			kw("gravity", "Gravity strength"),
			kw("gravityAngle", "Gravity direction (degrees)"),
			kw("size", "Particle size multiplier"),
			kw("sizeRandom", "Size randomization (0-1)"),
			kw("blendMode", "Blend mode: add|alpha"),
			kw("fadeIn", "Fade-in duration (0-1 of life)"),
			kw("fadeOut", "Fade-out start (0-1 of life)"),
			kw("colorStops", "Color gradient: 0.0 #FF0000, 1.0 #0000FF"),
			kw("sizeCurve", "Size animation curve"),
			kw("velocityCurve", "Velocity animation curve"),
			kw("forceFields", "Force fields: [turbulence, wind, vortex, ...]"),
			kw("bounds", "Particle bounds: kill, box(...)"),
			kw("rotationSpeed", "Rotation speed (degrees/sec)"),
			kw("rotateAuto", "Auto-rotate to velocity: true|false"),
			kw("relative", "Relative to emitter: true|false"),
			kw("spawnCurve", "Spawn rate curve"),
			kw("forwardAngle", "Forward direction: down|up|right|left"),
			kw("animFile", "Animation file for particles"),
			kw("subEmitters", "Sub-emitter definitions"),
		];
	}

	static function curvesBodyCompletions():Array<LspCompletionItem> {
		return [
			snippet("curve", "#name curve {\n\t$0\n}", "Define a named curve"),
		];
	}

	static function curveCompletions():Array<LspCompletionItem> {
		return [
			kw("easing", "Built-in easing function"),
			kw("points", "Control points: [(0, 0), (0.5, 1.0), (1.0, 0)]"),
			kw("multiply", "Multiply curves: [curve1, curve2]"),
			kw("apply", "Apply composition: inner, outer"),
			kw("invert", "Invert curve: 1.0 - curve(t)"),
			kw("scale", "Scale curve: curve, factor"),
		];
	}

	static function pathCompletions():Array<LspCompletionItem> {
		return [
			kw("moveTo", "Move to point: moveTo(x, y)"),
			kw("lineTo", "Line to point: lineTo(x, y)"),
			kw("bezier", "Cubic bezier: bezier(cp1x, cp1y, cp2x, cp2y[, endx, endy])"),
			kw("quadratic", "Quadratic curve: quadratic(cpx, cpy, endx, endy)"),
			kw("arc", "Arc segment"),
			kw("close", "Close path"),
		];
	}

	static function animatedPathCompletions():Array<LspCompletionItem> {
		return [
			kw("path", "Path reference (required)"),
			kw("type", "Animation type: time|distance"),
			kw("duration", "Duration in seconds"),
			kw("speed", "Speed (pixels/sec, for distance type)"),
			kw("loop", "Loop animation: true|false"),
			kw("pingPong", "Ping-pong: true|false"),
			kw("easing", "Easing function"),
			kw("scaleCurve", "Scale animation curve"),
			kw("alphaCurve", "Alpha animation curve"),
			kw("rotationCurve", "Rotation animation curve"),
			kw("speedCurve", "Speed animation curve"),
			kw("progressCurve", "Progress animation curve"),
			kw("colorCurve", "Color curve: curve, startColor, endColor"),
			snippet("event", "event(\"$1\")", "Path event at rate"),
			snippet("custom", "custom(\"$1\"): $0", "Custom value curve"),
		];
	}

	static function settingsCompletions():Array<LspCompletionItem> {
		return [
			kw("buildName", "Programmable build name override"),
			kw("font", "Font name"),
			kw("fontColor", "Font color"),
			kw("width", "Width"),
			kw("height", "Height"),
			kw("text", "Text content"),
			kw("disabled", "Disabled state"),
		];
	}

	static function transitionCompletions():Array<LspCompletionItem> {
		return [
			kw("none", "No transition (instant)"),
			snippet("fade", "fade($1, $2)", "Fade transition: fade(duration, easing)"),
			snippet("crossfade", "crossfade($1, $2)", "Crossfade: crossfade(duration, easing)"),
			snippet("flipX", "flipX($1, $2)", "Horizontal flip: flipX(duration, easing)"),
			snippet("flipY", "flipY($1, $2)", "Vertical flip: flipY(duration, easing)"),
			snippet("slide", "slide($1, $2)", "Slide: slide(direction, duration)"),
		];
	}

	static function filterCompletions():Array<LspCompletionItem> {
		return [
			kw("outline", "Outline filter: outline(size, color)"),
			kw("glow", "Glow filter: glow(color, alpha, radius)"),
			kw("blur", "Blur filter: blur(radius)"),
			kw("saturate", "Saturation: saturate(value)"),
			kw("brightness", "Brightness: brightness(value)"),
			kw("grayscale", "Grayscale: grayscale(value)"),
			kw("hue", "Hue shift: hue(value)"),
			kw("dropShadow", "Drop shadow filter"),
			kw("pixelOutline", "Pixel-perfect outline"),
			kw("replacePalette", "Palette replacement"),
			kw("replaceColor", "Color replacement"),
			kw("group", "Group multiple filters"),
			kw("none", "Remove all filters"),
		];
	}

	static function paramTypeCompletions():Array<LspCompletionItem> {
		return [
			kw("int", "Integer parameter"),
			kw("uint", "Unsigned integer parameter"),
			kw("float", "Float parameter"),
			kw("bool", "Boolean parameter"),
			kw("string", "String parameter"),
			kw("color", "Color parameter (#RRGGBB)"),
			kw("tile", "Tile parameter (h2d.Tile)"),
		];
	}

	static function referenceCompletions(paramNames:Array<String>, prefix:String):Array<LspCompletionItem> {
		final items:Array<LspCompletionItem> = [];

		// Parameter references
		for (name in paramNames) {
			items.push({label: '$$name', kind: CompletionKind.Variable, detail: "Parameter reference"});
		}

		// Built-in references
		items.push({label: "$grid", kind: CompletionKind.Module, detail: "Grid coordinate system"});
		items.push({label: "$hex", kind: CompletionKind.Module, detail: "Hex coordinate system"});
		items.push({label: "$ctx", kind: CompletionKind.Module, detail: "Context (width, height, random, font)"});

		return items;
	}

	static function conditionalCompletions():Array<LspCompletionItem> {
		return [
			snippet("@(", "@($1=>$2)", "Conditional: match when param equals value"),
			snippet("@if(", "@if($1=>$2)", "Explicit conditional"),
			snippet("@ifstrict(", "@ifstrict($1=>$2)", "Strict conditional (must match ALL)"),
			kw("@else", "Matches when preceding @() didn't match"),
			kw("@default", "Final fallback"),
			snippet("@final", "@final $1 = $0", "Define a constant"),
		];
	}

	static function paramNameCompletions(paramNames:Array<String>):Array<LspCompletionItem> {
		return [for (name in paramNames) {label: name, kind: CompletionKind.Variable, detail: "Parameter"}];
	}

	static function easingCompletions():Array<LspCompletionItem> {
		final easings = [
			"linear", "easeIn", "easeOut", "easeInOut",
			"easeInQuad", "easeOutQuad", "easeInOutQuad",
			"easeInCubic", "easeOutCubic", "easeInOutCubic",
			"easeInQuart", "easeOutQuart", "easeInOutQuart",
			"easeInQuint", "easeOutQuint", "easeInOutQuint",
			"easeInSine", "easeOutSine", "easeInOutSine",
			"easeInExpo", "easeOutExpo", "easeInOutExpo",
			"easeInCirc", "easeOutCirc", "easeInOutCirc",
			"easeInBack", "easeOutBack", "easeInOutBack",
			"easeInElastic", "easeOutElastic", "easeInOutElastic",
			"easeInBounce", "easeOutBounce", "easeInOutBounce",
		];
		return [for (e in easings) {label: e, kind: CompletionKind.EnumMember, detail: "Easing function"}];
	}

	// ---- Helpers ----

	static function kw(label:String, detail:String):LspCompletionItem {
		return {label: label, kind: CompletionKind.Keyword, detail: detail};
	}

	static function snippet(label:String, insertText:String, detail:String):LspCompletionItem {
		return {
			label: label,
			kind: CompletionKind.Snippet,
			detail: detail,
			insertText: insertText,
			insertTextFormat: 2 // Snippet format
		};
	}
}
