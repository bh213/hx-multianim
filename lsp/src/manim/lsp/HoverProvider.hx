package manim.lsp;

import bh.multianim.ManimKeywordInfo;
import manim.lsp.LspTypes;

using StringTools;

/**
 * Provides hover documentation for .manim keywords and constructs.
 * Derives docs from parser enums via ManimKeywordInfo where possible.
 */
class HoverProvider {
	public static function getHover(word:String, text:String, uri:String):Null<LspHover> {
		final cleanWord = if (word.startsWith("$") || word.startsWith("#") || word.startsWith("@"))
			word.substr(1)
		else
			word;

		final doc = lookupKeyword(word) ?? lookupKeyword(cleanWord);
		if (doc != null)
			return {contents: {kind: "markdown", value: doc}};

		// Color literal
		if (word.startsWith("#") && (word.length == 4 || word.length == 7 || word.length == 9)) {
			final isHex = ~/^#[0-9a-fA-F]+$/.match(word);
			if (isHex)
				return {contents: {kind: "markdown", value: 'Color: `$word`'}};
		}

		// $parameter reference — look up type from file
		if (word.startsWith("$")) {
			final paramInfo = findParamInfo(cleanWord, text);
			if (paramInfo != null) return {contents: {kind: "markdown", value: paramInfo}};
		}

		return null;
	}

	static function findParamInfo(paramName:String, text:String):Null<String> {
		final pattern = new EReg('\\b$paramName\\s*:\\s*(\\w+|\\[[^\\]]*\\]|\\d+\\.\\.\\d+)', '');
		if (pattern.match(text)) {
			final matched = pattern.matched(0);
			return '**Parameter** `$$$paramName`\n\n`$matched`';
		}
		return null;
	}

	static function lookupKeyword(word:String):Null<String> {
		// Try element names (from NodeType via ManimKeywordInfo)
		for (ctor in ManimKeywordInfo.allElementCtors) {
			if (ManimKeywordInfo.elementName(ctor) == word) {
				return '**${word}** — ${ManimKeywordInfo.elementDescription(ctor)}';
			}
		}

		// Try filter names (from FilterType — exhaustive switch)
		for (filterType in ManimKeywordInfo.completableFilters) {
			if (ManimKeywordInfo.filterName(filterType) == word) {
				return '**${word}** filter — ${ManimKeywordInfo.filterDescription(filterType)}';
			}
		}

		// Try param types (from DefinitionType — exhaustive switch)
		for (defType in ManimKeywordInfo.simpleParamTypes) {
			if (ManimKeywordInfo.paramTypeName(defType) == word) {
				return '**${word}** — ${ManimKeywordInfo.paramTypeDescription(defType)}';
			}
		}

		// Try easing names (from EasingType — exhaustive switch)
		for (easing in ManimKeywordInfo.allEasings) {
			if (ManimKeywordInfo.easingName(easing) == word) {
				return '**${word}** — Easing function';
			}
		}

		// Try transition types (from TransitionType — exhaustive switch)
		for (trans in ManimKeywordInfo.allTransitions) {
			if (ManimKeywordInfo.transitionName(trans) == word) {
				return '**${word}** — ${ManimKeywordInfo.transitionDescription(trans)}';
			}
		}

		// Remaining keywords not covered by enums
		return switch (word) {
			case "settings": "**settings** — Component settings block\n\n```manim\nsettings {\n  key:type => value\n}\n```";
			case "transition": "**transition** — Animated transitions for parameter changes\n\n```manim\ntransition {\n  param: crossfade(0.1, easeOutQuad)\n}\n```";
			case "import": "**import** — Import external .manim file\n\n```manim\nimport \"file.manim\" as \"name\"\n```";
			case "version": "**version** — File version header: `version: 1.0`";
			case "@final" | "final": "**@final** — Immutable named constant: `@final NAME = 42`";
			case "@else" | "else": "**@else** — Matches when preceding @() didn't match";
			case "@default" | "default": "**@default** — Final fallback (always matches)";
			case "@if": "**@if** — Explicit conditional (same as `@()`)";
			case "@ifstrict": "**@ifstrict** — Strict matching (must match ALL specified params)";
			case "grid": "**$grid** — Grid coordinate system\n\n`$grid.pos(x, y)`, `$grid.width`, `$grid.height`";
			case "hex": "**$hex** — Hexagonal coordinate system\n\n`$hex.cube(q, r, s)`, `$hex.corner(index, scale)`";
			case "ctx": "**$ctx** — Context properties\n\n`$ctx.width`, `$ctx.height`, `$ctx.random(min, max)`";
			default: null;
		};
	}
}
