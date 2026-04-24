package manim.lsp;

import bh.multianim.ManimKeywordInfo;
import manim.lsp.LspTypes;
import manim.lsp.ContextAnalyzer;

using StringTools;

/**
 * Provides context-aware completion items for .manim files.
 * Derives completions from parser enums via ManimKeywordInfo — exhaustive
 * matching ensures new enum variants force updating the metadata.
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
			case DataBody: dataCompletions();
			case InteractiveParams: [];
			case AfterDollar(prefix): referenceCompletions(ctx.paramNames, prefix);
			case AfterAt: conditionalCompletions();
			case AfterConditionalOpen: paramNameCompletions(ctx.paramNames);
			case EasingPosition: easingCompletions();
			case Unknown: elementCompletions();
		};
	}

	static function topLevelCompletions():Array<LspCompletionItem> {
		final items:Array<LspCompletionItem> = [];
		items.push(snippet("import", "import \"$1\" as \"$2\"", "Import external .manim file"));
		items.push(kw("version:", "File version header"));

		for (ctor in ManimKeywordInfo.allElementCtors) {
			if (ManimKeywordInfo.isTopLevel(ctor)) {
				addElementItem(items, ctor);
			}
		}
		return items;
	}

	static function elementCompletions():Array<LspCompletionItem> {
		final items:Array<LspCompletionItem> = [];
		for (ctor in ManimKeywordInfo.allElementCtors) {
			if (ManimKeywordInfo.isChildElement(ctor)) {
				addElementItem(items, ctor);
			}
		}
		// Properties
		items.push(snippet("settings", "settings {\n\t$0\n}", "Component settings block"));
		items.push(snippet("transition", "transition {\n\t$0\n}", "Animated parameter transitions"));
		for (prop in ["filter:", "blendMode:", "scale:", "alpha:", "rotation:", "tint:", "layer:"])
			items.push(kw(prop, 'Set ${prop.substr(0, prop.length - 1)}'));
		return items;
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
		// Particle properties are parsed as string keys, not an enum
		final props = [
			"count" => "Number of particles", "emit" => "Emission shape: point|cone|box|circle|path",
			"tiles" => "Particle tile: file() or sheet()", "loop" => "Loop emission: true|false",
			"maxLife" => "Maximum particle lifetime (seconds)", "speed" => "Initial particle speed",
			"speedRandom" => "Speed randomization (0-1)", "gravity" => "Gravity strength",
			"gravityAngle" => "Gravity direction", "size" => "Particle size multiplier",
			"sizeRandom" => "Size randomization (0-1)", "blendMode" => "Blend mode: add|alpha",
			"fadeIn" => "Fade-in duration (0-1)", "fadeOut" => "Fade-out start (0-1)",
			"colorStops" => "Color gradient stops", "sizeCurve" => "Size animation curve",
			"velocityCurve" => "Velocity curve", "forceFields" => "Force fields: [turbulence, wind, ...]",
			"bounds" => "Particle bounds: kill, box(...)", "rotationSpeed" => "Rotation speed",
			"rotateAuto" => "Auto-rotate to velocity", "relative" => "Relative to emitter",
			"externallyDriven" => "Disable auto-update; use advanceTime(dt)",
			"spawnCurve" => "Spawn rate curve", "forwardAngle" => "Forward direction",
			"animFile" => "Animation file", "subEmitters" => "Sub-emitter definitions",
			"shutdown" => "Graceful shutdown config: { duration, curve, alphaCurve, sizeCurve, speedCurve }",
		];
		return [for (key => desc in props) kw(key, desc)];
	}

	static function curvesBodyCompletions():Array<LspCompletionItem> {
		return [snippet("curve", "#${1:name} curve {\n\t$0\n}", "Define a named curve")];
	}

	static function curveCompletions():Array<LspCompletionItem> {
		final items:Array<LspCompletionItem> = [
			kw("easing", "Built-in easing function"),
			kw("points", "Control points: [(0, 0), (0.5, 1.0), (1.0, 0)]"),
		];
		for (op in ManimKeywordInfo.allCurveOps)
			items.push(kw(ManimKeywordInfo.curveName(op), ManimKeywordInfo.curveDescription(op)));
		return items;
	}

	static function pathCompletions():Array<LspCompletionItem> {
		return [for (cmd in ManimKeywordInfo.allPathCommands) kw(ManimKeywordInfo.pathName(cmd), ManimKeywordInfo.pathDescription(cmd))];
	}

	static function animatedPathCompletions():Array<LspCompletionItem> {
		// Parsed as string keys, not an enum
		final props = [
			"path" => "Path reference (required)", "type" => "Animation type: time|distance",
			"duration" => "Duration in seconds", "speed" => "Speed (pixels/sec)",
			"loop" => "Loop: true|false", "pingPong" => "Ping-pong: true|false",
			"easing" => "Easing function", "scaleCurve" => "Scale animation curve",
			"alphaCurve" => "Alpha animation curve", "rotationCurve" => "Rotation curve",
			"speedCurve" => "Speed curve", "progressCurve" => "Progress curve",
			"colorCurve" => "Color curve: curve, startColor, endColor",
		];
		return [for (key => desc in props) kw(key, desc)];
	}

	static function dataCompletions():Array<LspCompletionItem> {
		return [
			snippet("record", "#${1:name} record(${2:field:type})", "Define a named record type"),
			snippet("enum", "#${1:name} enum(${2:val1, val2})", "Define a named enum type"),
			kw("int", "Integer field type"),
			kw("float", "Float field type"),
			kw("string", "String field type"),
			kw("bool", "Boolean field type"),
		];
	}

	static function settingsCompletions():Array<LspCompletionItem> {
		final props = [
			"buildName" => "Programmable build name override", "font" => "Font name",
			"fontColor" => "Font color", "width" => "Width", "height" => "Height",
			"text" => "Text content", "disabled" => "Disabled state",
		];
		return [for (key => desc in props) kw(key, desc)];
	}

	static function transitionCompletions():Array<LspCompletionItem> {
		final items:Array<LspCompletionItem> = [];
		for (t in ManimKeywordInfo.allTransitions) {
			final name = ManimKeywordInfo.transitionName(t);
			final desc = ManimKeywordInfo.transitionDescription(t);
			final snip = ManimKeywordInfo.transitionSnippet(t);
			if (snip != null)
				items.push(snippet(name, snip, desc));
			else
				items.push(kw(name, desc));
		}
		return items;
	}

	static function filterCompletions():Array<LspCompletionItem> {
		return [for (f in ManimKeywordInfo.completableFilters) kw(ManimKeywordInfo.filterName(f), ManimKeywordInfo.filterDescription(f))];
	}

	static function paramTypeCompletions():Array<LspCompletionItem> {
		return [for (t in ManimKeywordInfo.simpleParamTypes) kw(ManimKeywordInfo.paramTypeName(t), ManimKeywordInfo.paramTypeDescription(t))];
	}

	static function referenceCompletions(paramNames:Array<String>, prefix:String):Array<LspCompletionItem> {
		final items:Array<LspCompletionItem> = [];
		for (name in paramNames)
			items.push({label: '$$name', kind: CompletionKind.Variable, detail: "Parameter reference"});
		items.push({label: "$grid", kind: CompletionKind.Module, detail: "Grid coordinate system"});
		items.push({label: "$hex", kind: CompletionKind.Module, detail: "Hex coordinate system"});
		items.push({label: "$ctx", kind: CompletionKind.Module, detail: "Context (width, height, random, font)"});
		return items;
	}

	static function conditionalCompletions():Array<LspCompletionItem> {
		return [
			snippet("@(", "@($1=>$2)", "Conditional: match when param equals value"),
			snippet("@( {", "@($1=>$2) {\n\t$0\n}", "Conditional block: match with multiple elements"),
			snippet("@if(", "@if($1=>$2)", "Explicit conditional"),
			snippet("@all(", "@all($1=>$2)", "Match ALL listed conditions (AND)"),
			snippet("@all( {", "@all($1=>$2) {\n\t$0\n}", "AND conditional block"),
			snippet("@any(", "@any($1=>$2)", "Match ANY listed condition (OR)"),
			snippet("@any( {", "@any($1=>$2) {\n\t$0\n}", "OR conditional block"),
			kw("@else", "Matches when preceding @() didn't match"),
			snippet("@else {", "@else {\n\t$0\n}", "Else block with multiple elements"),
			snippet("@else(", "@else($1=>$2) {\n\t$0\n}", "Else-if block with condition"),
			kw("@default", "Final fallback"),
			snippet("@default {", "@default {\n\t$0\n}", "Default block with multiple elements"),
			snippet("@switch(", "@switch($1) {\n\t$2: $0\n\tdefault: $0\n}", "Switch block on parameter"),
			snippet("@final", "@final $1 = $0", "Define a constant"),
		];
	}

	static function paramNameCompletions(paramNames:Array<String>):Array<LspCompletionItem> {
		return [for (name in paramNames) {label: name, kind: CompletionKind.Variable, detail: "Parameter"}];
	}

	static function easingCompletions():Array<LspCompletionItem> {
		return [for (e in ManimKeywordInfo.allEasings) {label: ManimKeywordInfo.easingName(e), kind: CompletionKind.EnumMember, detail: "Easing function"}];
	}

	// ---- Helpers ----

	static function addElementItem(items:Array<LspCompletionItem>, ctor:String):Void {
		final name = ManimKeywordInfo.elementName(ctor);
		final desc = ManimKeywordInfo.elementDescription(ctor);
		final snip = ManimKeywordInfo.elementSnippet(ctor);
		if (name == null || desc == null) return;
		if (snip != null)
			items.push(snippet(name, snip, desc));
		else
			items.push(kw(name, desc));
	}

	static function kw(label:String, detail:String):LspCompletionItem {
		return {label: label, kind: CompletionKind.Keyword, detail: detail};
	}

	static function snippet(label:String, insertText:String, detail:String):LspCompletionItem {
		return {label: label, kind: CompletionKind.Snippet, detail: detail, insertText: insertText, insertTextFormat: InsertTextFormat.Snippet};
	}
}
