package manim.lsp;

import bh.stateanim.AnimParser.AnimParserLsp;
import bh.stateanim.AnimParser.AnimKeywordInfo;
import bh.stateanim.AnimParser.AnimKeywordContext;
import bh.stateanim.AnimParser.InvalidSyntax;
import bh.stateanim.AnimParser.AnimUnexpected;
import bh.base.ParsePosition;
import manim.lsp.LspTypes;

using StringTools;

/**
 * .anim file analyzer for LSP features.
 *
 * Uses AnimParserLsp for tokenization/validation and AnimKeywordInfo
 * registry for completions/hover (single source of truth in AnimParser.hx).
 */
class AnimAnalyzer {
	public static function getDiagnostics(text:String, uri:String):Array<LspDiagnostic> {
		final diagnostics:Array<LspDiagnostic> = [];

		try {
			final parser = new AnimParserLsp(text, uriToName(uri));
			parser.validate();
		} catch (e:InvalidSyntax) {
			diagnostics.push({
				range: posToRange(e.pos, text),
				severity: DiagnosticSeverity.Error,
				message: e.error,
				source: "anim"
			});
		} catch (e:AnimUnexpected<Dynamic>) {
			diagnostics.push({
				range: posToRange(e.pos, text),
				severity: DiagnosticSeverity.Error,
				message: e.toString(),
				source: "anim"
			});
		} catch (e:Dynamic) {
			diagnostics.push({
				range: {start: {line: 0, character: 0}, end: {line: 0, character: 1}},
				severity: DiagnosticSeverity.Error,
				message: 'Parser error: $e',
				source: "anim"
			});
		}

		return diagnostics;
	}

	public static function getSymbols(text:String, uri:String):Array<LspSymbolInformation> {
		final symbols:Array<LspSymbolInformation> = [];

		try {
			final parser = new AnimParserLsp(text, uriToName(uri));
			parser.validate();

			for (name in parser.animationNames) {
				final range = findNameInText(text, name);
				symbols.push({name: name, kind: SymbolKind.Function, range: range, selectionRange: range, detail: "animation"});
			}

			for (s in parser.stateDeclarations) {
				final range = findNameInText(text, s.name);
				symbols.push({
					name: s.name,
					kind: SymbolKind.Variable,
					range: range,
					selectionRange: range,
					detail: 'state (${s.values.join(", ")})'
				});
			}

			if (parser.hasMetadata) {
				final range = findNameInText(text, "metadata");
				symbols.push({name: "metadata", kind: SymbolKind.Struct, range: range, selectionRange: range});
			}

			for (name in parser.constants) {
				final range = findNameInText(text, name);
				symbols.push({name: name, kind: SymbolKind.Constant, range: range, selectionRange: range, detail: "@final"});
			}
		} catch (_:Dynamic) {}

		return symbols;
	}

	public static function getCompletions(text:String, line:Int, character:Int):Array<LspCompletionItem> {
		final context = getAnimContext(text, line);
		final kwContext = switch (context) {
			case TopLevel: AKTopLevel;
			case InAnimation: AKAnimationBody;
			case InPlaylist: AKPlaylistBody;
			case InFilters: AKFilterBody;
			case InMetadata | InExtrapoints | AfterAt: AKConditional;
		};

		final items:Array<LspCompletionItem> = [];
		for (kw in AnimKeywordInfo.forContext(kwContext)) {
			final item:LspCompletionItem = {label: kw.name, kind: kw.isBlock ? CompletionKind.Keyword : CompletionKind.Property, detail: kw.description};
			if (kw.snippet != null) {
				item.insertText = kw.snippet;
				item.insertTextFormat = InsertTextFormat.Snippet;
			}
			items.push(item);
		}
		// Add conditionals in contexts that support them
		if (kwContext == AKFilterBody || kwContext == AKAnimationBody) {
			for (kw in AnimKeywordInfo.forContext(AKConditional)) {
				final item:LspCompletionItem = {label: kw.name, kind: CompletionKind.Keyword, detail: kw.description};
				if (kw.snippet != null) {
					item.insertText = kw.snippet;
					item.insertTextFormat = InsertTextFormat.Snippet;
				}
				items.push(item);
			}
		}
		return items;
	}

	public static function getHover(text:String, uri:String, line:Int, character:Int):Null<LspHover> {
		@:privateAccess final word = ManimAnalyzer.getWordAtPosition(text, line, character);
		if (word == null || word.length == 0) return null;

		final kw = AnimKeywordInfo.findByName(word);
		if (kw == null) return null;

		return {contents: {kind: "markdown", value: '**${kw.name}** — ${kw.description}'}};
	}

	// ---- Helpers ----

	static function posToRange(pos:ParsePosition, text:String):LspRange {
		final line = pos.line - 1;
		final col = pos.col - 1;
		return {start: {line: line, character: col}, end: {line: line, character: col + 1}};
	}

	static function findNameInText(text:String, name:String):LspRange {
		final lines = text.split("\n");
		for (i in 0...lines.length) {
			final col = lines[i].indexOf(name);
			if (col >= 0)
				return {start: {line: i, character: col}, end: {line: i, character: col + name.length}};
		}
		return {start: {line: 0, character: 0}, end: {line: 0, character: 0}};
	}

	static function uriToName(uri:String):String {
		final lastSlash = uri.lastIndexOf("/");
		return lastSlash >= 0 ? uri.substr(lastSlash + 1) : uri;
	}

	static function getAnimContext(text:String, cursorLine:Int):AnimContext {
		final lines = text.split("\n");
		var depth = 0;
		var context = TopLevel;

		for (i in 0...Std.int(Math.min(cursorLine + 1, lines.length))) {
			final line = lines[i].trim();

			if (line.startsWith("animation ") || line.startsWith("anim ")) {
				if (depth == 0) context = InAnimation;
			} else if (line.startsWith("metadata")) {
				if (depth == 0) context = InMetadata;
			} else if (line.startsWith("playlist")) {
				if (depth == 1) context = InPlaylist;
			} else if (line.startsWith("extrapoints")) {
				if (depth == 1) context = InExtrapoints;
			} else if (line.startsWith("filters")) {
				if (depth == 1) context = InFilters;
			}

			for (k in 0...lines[i].length) {
				final c = lines[i].charCodeAt(k);
				if (c == "{".code) depth++;
				else if (c == "}".code) {
					depth--;
					if (depth <= 0) { context = TopLevel; depth = 0; } else if (depth <= 1) context = InAnimation;
				}
			}

			if (i == cursorLine && lines[i].trim().startsWith("@") && !lines[i].trim().startsWith("@final"))
				return AfterAt;
		}
		return context;
	}
}

enum AnimContext {
	TopLevel;
	InAnimation;
	InPlaylist;
	InMetadata;
	InExtrapoints;
	InFilters;
	AfterAt;
}
