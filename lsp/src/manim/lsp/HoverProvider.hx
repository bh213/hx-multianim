package manim.lsp;

import bh.multianim.ManimKeywordInfo;
import bh.multianim.MacroManimParser;
import bh.multianim.MultiAnimParser.Definition;
import bh.multianim.MultiAnimParser.MultiAnimResult;
import bh.multianim.MultiAnimParser.Node;
import manim.lsp.LspTypes;

using StringTools;

/**
 * Provides hover documentation for .manim keywords and constructs.
 * Derives docs from parser enums via ManimKeywordInfo where possible, and shows the file's own
 * `///` doc comments for its root blocks, their parameters and enum choices.
 */
class HoverProvider {
	/** `line` (0-based) is the cursor's: with it a parameter or a choice is looked up in the root
	 *  block the cursor is in. */
	public static function getHover(word:String, text:String, uri:String, line:Int = -1):Null<LspHover> {
		final cleanWord = if (word.startsWith("$") || word.startsWith("#") || word.startsWith("@"))
			word.substr(1)
		else
			word;

		// What the file's own `///` docs say of the block, parameter or choice under the cursor
		final documented = documentedHover(word, cleanWord, text, line);
		if (documented != null)
			return {contents: {kind: "markdown", value: documented}};

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

	/** A hover from the file's `///` doc comments: a root block by its name (`#knight`, or a bare
	 *  `knight` as `staticRef(knight)` writes it), shown when it has a doc or is exported; a
	 *  parameter (`$hp`, or `hp` where it is declared) or a choice of an enum parameter of the root
	 *  block the cursor is in, shown when it has a doc. Null when the file does not parse. */
	static function documentedHover(word:String, name:String, text:String, line:Int):Null<String> {
		final result:Null<MultiAnimResult> = try MacroManimParser.parseFile(text, "hover", null) catch (_:Dynamic) null;
		if (result == null) return null;
		final isRef = word.startsWith("$");
		if (!isRef) {
			final node = result.nodes.get(name);
			if (node != null && (node.doc != null || node.exported == true))
				return blockHover(name, node);
		}
		if (line < 0) return null;
		final blockName = enclosingRootBlock(text, line);
		final block = blockName == null ? null : result.nodes.get(blockName);
		if (block == null) return null;
		final defs = switch block.type {
			case PROGRAMMABLE(_, defs, _): defs;
			default: null;
		};
		if (defs == null) return null;
		final def = defs.get(name);
		if (def != null && (def.doc != null || def.choiceDocs != null))
			return paramHover(def);
		if (isRef) return null;
		for (d in defs) {
			final choiceDoc = d.choiceDocs?.get(name);
			if (choiceDoc != null)
				return '**$name** — choice of `$$${d.name}`\n\n$choiceDoc';
		}
		return null;
	}

	static function blockHover(name:String, node:Node):String {
		final kind = ManimKeywordInfo.elementName(Type.enumConstructor(node.type)) ?? "block";
		final parts = ['**#$name** — ' + (node.exported == true ? 'exported $kind' : kind)];
		if (node.doc != null) parts.push(node.doc);
		switch node.type {
			case PROGRAMMABLE(_, defs, order):
				final documented = [
					for (p in order) {
						final d = defs.get(p);
						if (d != null && d.doc != null) '- `$p:${ManimKeywordInfo.paramTypeName(d.type)}` — ${oneLine(d.doc)}';
					}
				];
				if (documented.length > 0) parts.push(documented.join("\n"));
			default:
		}
		return parts.join("\n\n");
	}

	static function paramHover(def:Definition):String {
		final parts = ['**Parameter** `$$${def.name}`: `${ManimKeywordInfo.paramTypeName(def.type)}`'];
		if (def.doc != null) parts.push(def.doc);
		final choiceDocs = def.choiceDocs;
		if (choiceDocs != null)
			switch def.type {
				case PPTEnum(values):
					parts.push([for (v in values) if (choiceDocs.exists(v)) '- `$v` — ${oneLine(choiceDocs.get(v))}'].join("\n"));
				default:
			}
		return parts.join("\n\n");
	}

	static function oneLine(doc:String):String {
		return doc.split("\n").join(" ");
	}

	/** The root block the 0-based `line` is in: the last `#name` written at the top level
	 *  (outside every bracket, string and comment) on or before that line. */
	static function enclosingRootBlock(text:String, line:Int):Null<String> {
		var current:Null<String> = null;
		var depth = 0;
		var lineNo = 0;
		var i = 0;
		final n = text.length;
		while (i < n && lineNo <= line) {
			final c = text.charCodeAt(i);
			if (c == "\n".code) {
				lineNo++;
				i++;
				continue;
			}
			if (c == "/".code && i + 1 < n && text.charCodeAt(i + 1) == "/".code) {
				while (i < n && text.charCodeAt(i) != "\n".code)
					i++;
				continue;
			}
			if (c == "/".code && i + 1 < n && text.charCodeAt(i + 1) == "*".code) {
				i += 2;
				while (i + 1 < n && !(text.charCodeAt(i) == "*".code && text.charCodeAt(i + 1) == "/".code)) {
					if (text.charCodeAt(i) == "\n".code) lineNo++;
					i++;
				}
				i += 2;
				continue;
			}
			if (c == "\"".code || c == "'".code) {
				i++;
				while (i < n && text.charCodeAt(i) != c) {
					if (text.charCodeAt(i) == "\\".code) i++;
					else if (text.charCodeAt(i) == "\n".code) lineNo++;
					i++;
				}
				i++;
				continue;
			}
			if (c == "{".code || c == "(".code || c == "[".code) {
				depth++;
			} else if (c == "}".code || c == ")".code || c == "]".code) {
				if (depth > 0) depth--;
			} else if (c == "#".code && depth == 0) {
				var j = i + 1;
				while (j < n && isNameChar(text.charCodeAt(j)))
					j++;
				if (j > i + 1) current = text.substring(i + 1, j);
				i = j;
				continue;
			}
			i++;
		}
		return current;
	}

	static function isNameChar(c:Int):Bool {
		return (c >= "a".code && c <= "z".code) || (c >= "A".code && c <= "Z".code) || (c >= "0".code && c <= "9".code) || c == "_".code
			|| c == "-".code;
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

		// The engine's shaders, by name in any case
		final shader = bh.multianim.ShaderCatalog.find(word);
		if (shader != null)
			return '**${shader.name}** — ${ManimKeywordInfo.shaderDescription(shader)}';

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
			case "record": "**record** — Named record type in data block\n\n```manim\n#name record(field:type, ...)\n```";
			case "enum": "**enum** — Named enum type in data block\n\n```manim\n#name enum(val1, val2, ...)\n```";
			case "settings": "**settings** — Component settings block\n\n```manim\nsettings {\n  key:type => value\n}\n```";
			case "transition": "**transition** — Animated transitions for parameter changes\n\n```manim\ntransition {\n  param: crossfade(0.1, easeOutQuad)\n}\n```";
			case "import": "**import** — Import external .manim file\n\n```manim\nimport \"file.manim\" as \"name\"\n```";
			case "export": '**export** — ${ManimKeywordInfo.exportDescription}\n\n```manim\n/// The knight, walking or standing\n#knight export programmable(state:[idle, walk]=idle) {\n  ...\n}\n```';
			case "version": "**version** — File version header: `version: 1.0`";
			case "@final" | "final": "**@final** — Immutable named constant: `@final NAME = 42`";
			case "@else" | "else": "**@else** — Matches when preceding @() didn't match\n\nBlock form: `@else { ... }` or `@else(cond) { ... }`";
			case "@default" | "default": "**@default** — Final fallback (always matches)\n\nBlock form: `@default { ... }`";
			case "@if": "**@if** — Explicit conditional (same as `@()`)\n\nBlock form: `@if(cond) { ... }`";
			case "@all": "**@all** — Match when ALL listed conditions match (AND, same as `@()`)\n\nBlock form: `@all(cond) { ... }`";
			case "@any": "**@any** — Match when ANY listed condition matches (OR)\n\nBlock form: `@any(cond) { ... }`";
			case "@switch" | "switch": "**@switch** — Switch block on parameter\n\n```manim\n@switch(param) {\n  value1: element(...);\n  value2 | value3: element(...);\n  <= 10: element(...);\n  0..100: element(...);\n  default: element(...);\n}\n```";
			case "grid": "**$grid** — Grid coordinate system\n\n`$grid.pos(x, y)`, `$grid.width`, `$grid.height`";
			case "hex": "**$hex** — Hexagonal coordinate system\n\n`$hex.cube(q, r, s)`, `$hex.corner(index, scale)`";
			case "ctx": "**$ctx** — Context properties\n\n`$ctx.width`, `$ctx.height`, `$ctx.random(min, max)`";
			default: null;
		};
	}
}
