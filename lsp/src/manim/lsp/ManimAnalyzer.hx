package manim.lsp;

import bh.multianim.MacroManimParser;
import bh.multianim.MultiAnimParser.Node;
import bh.multianim.MultiAnimParser.NodeType;
import bh.multianim.MultiAnimParser.DefinitionType;
import bh.multianim.MultiAnimParser.UpdatableNameType;
import bh.multianim.MultiAnimParser.InvalidSyntax;
import bh.multianim.MultiAnimParser.MultiAnimUnexpected;
import bh.base.ParsePosition;
import manim.lsp.LspTypes;

using StringTools;

/**
 * Core analysis engine for .manim files.
 * Uses MacroManimParser for parsing and provides LSP features:
 * diagnostics, completions, hover, symbols, go-to-definition.
 */
class ManimAnalyzer {
	/**
	 * Parse a .manim document and return diagnostics.
	 */
	public static function getDiagnostics(text:String, uri:String):Array<LspDiagnostic> {
		final diagnostics:Array<LspDiagnostic> = [];

		try {
			MacroManimParser.parseFile(text, uriToName(uri), null);
		} catch (e:InvalidSyntax) {
			diagnostics.push({
				range: posToRange(e.pos, text),
				severity: DiagnosticSeverity.Error,
				message: e.error,
				source: "manim"
			});
		} catch (e:MultiAnimUnexpected<Dynamic>) {
			diagnostics.push({
				range: posToRange(e.pos, text),
				severity: DiagnosticSeverity.Error,
				message: e.toString(),
				source: "manim"
			});
		} catch (e:Dynamic) {
			// Catch-all for unexpected parser errors
			diagnostics.push({
				range: {start: {line: 0, character: 0}, end: {line: 0, character: 1}},
				severity: DiagnosticSeverity.Error,
				message: 'Parser error: $e',
				source: "manim"
			});
		}

		return diagnostics;
	}

	/**
	 * Get document symbols (outline) from a parsed .manim file.
	 */
	public static function getSymbols(text:String, uri:String):Array<LspSymbolInformation> {
		final symbols:Array<LspSymbolInformation> = [];

		try {
			final result = MacroManimParser.parseFile(text, uriToName(uri), null);

			for (name => node in result.nodes) {
				final range = findNameInText(text, name);
				final symbol:LspSymbolInformation = switch (node.type) {
					case PROGRAMMABLE(_, parameters, _):
						final paramList = [for (pname => def in parameters) '$pname:${defTypeName(def.type)}'];
						{
							name: name,
							kind: SymbolKind.Class,
							range: range,
							selectionRange: range,
							detail: paramList.length > 0 ? '(${paramList.join(", ")})' : null,
							children: getChildSymbols(node, text)
						};
					case DATA(_):
						{name: name, kind: SymbolKind.Struct, range: range, selectionRange: range};
					case CURVES(_):
						{name: name, kind: SymbolKind.Namespace, range: range, selectionRange: range, detail: "curves"};
					case PATHS(_):
						{name: name, kind: SymbolKind.Namespace, range: range, selectionRange: range, detail: "paths"};
					case ANIMATED_PATH(_):
						{name: name, kind: SymbolKind.Function, range: range, selectionRange: range, detail: "animatedPath"};
					case FINAL_VAR(n, _):
						{name: n, kind: SymbolKind.Constant, range: range, selectionRange: range, detail: "@final"};
					case RELATIVE_LAYOUTS(_):
						{name: name, kind: SymbolKind.Namespace, range: range, selectionRange: range, detail: "layout"};
					default:
						{name: name, kind: SymbolKind.Variable, range: range, selectionRange: range};
				};
				symbols.push(symbol);
			}
		} catch (_:Dynamic) {
			// Parse failed — return empty symbols
		}

		return symbols;
	}

	/**
	 * Get completions based on cursor position context.
	 */
	public static function getCompletions(text:String, line:Int, character:Int):Array<LspCompletionItem> {
		final ctx = ContextAnalyzer.analyze(text, line, character);
		return CompletionProvider.getCompletions(ctx);
	}

	/**
	 * Get hover information for a position.
	 */
	public static function getHover(text:String, uri:String, line:Int, character:Int):Null<LspHover> {
		final word = getWordAtPosition(text, line, character);
		if (word == null || word.length == 0) return null;
		return HoverProvider.getHover(word, text, uri);
	}

	/**
	 * Get go-to-definition locations.
	 */
	public static function getDefinition(text:String, uri:String, line:Int, character:Int):Null<LspLocation> {
		final word = getWordAtPosition(text, line, character);
		if (word == null || word.length == 0) return null;

		// $reference — find parameter declaration
		if (word.startsWith("$")) {
			final paramName = word.substr(1);
			return findParameterDefinition(text, uri, paramName);
		}

		// #name — find named element
		if (word.startsWith("#")) {
			return findNamedElement(text, uri, word);
		}

		return null;
	}

	// ---- Helpers ----

	static function getChildSymbols(node:Node, text:String):Null<Array<LspSymbolInformation>> {
		final children:Array<LspSymbolInformation> = [];
		for (child in node.children) {
			switch (child.updatableName) {
				case UNTObject(name) | UNTUpdatable(name) | UNTIndexed(name, _) | UNTIndexed2D(name, _, _):
					final range = findNameInText(text, '#$name');
					final kind = switch (child.type) {
						case SLOT(_, _): SymbolKind.Field;
						case INTERACTIVE(_, _, _, _, _): SymbolKind.Field;
						default: SymbolKind.Property;
					};
					children.push({
						name: '#$name',
						kind: kind,
						range: range,
						selectionRange: range,
						detail: nodeTypeName(child.type)
					});
				default:
			}
			// Recurse
			final grandchildren = getChildSymbols(child, text);
			if (grandchildren != null) {
				for (gc in grandchildren) children.push(gc);
			}
		}
		return children.length > 0 ? children : null;
	}

	static function nodeTypeName(type:NodeType):String {
		return switch (type) {
			case BITMAP(_, _, _): "bitmap";
			case TEXT(_): "text";
			case RICHTEXT(_): "richText";
			case NINEPATCH(_, _, _, _): "ninepatch";
			case FLOW(_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _): "flow";
			case LAYERS: "layers";
			case MASK(_, _): "mask";
			case TILEGROUP: "tilegroup";
			case INTERACTIVE(_, _, _, _, _): "interactive";
			case SLOT(_, _): "slot";
			case SPACER(_, _): "spacer";
			case POINT: "point";
			case REPEAT(_, _): "repeatable";
			case REPEAT2D(_, _, _, _): "repeatable2d";
			case STATIC_REF(_, _, _): "staticRef";
			case DYNAMIC_REF(_, _, _): "dynamicRef";
			case PLACEHOLDER(_, _): "placeholder";
			case GRAPHICS(_): "graphics";
			case PIXELS(_): "pixels";
			case PARTICLES(_): "particles";
			case APPLY: "apply";
			case PROGRAMMABLE(_, _, _): "programmable";
			case STATEANIM(_, _, _): "stateanim";
			case STATEANIM_CONSTRUCT(_, _, _): "stateanim";
			case DATA(_): "data";
			case ANIMATED_PATH(_): "animatedPath";
			case CURVES(_): "curves";
			case PATHS(_): "paths";
			case FINAL_VAR(_, _): "@final";
			default: "";
		}
	}

	static function defTypeName(type:DefinitionType):String {
		return switch (type) {
			case PPTInt: "int";
			case PPTUnsignedInt: "uint";
			case PPTFloat: "float";
			case PPTBool: "bool";
			case PPTString: "string";
			case PPTColor: "color";
			case PPTTile: "tile";
			case PPTEnum(values): '[${values.join(",")}]';
			case PPTRange(from, to): '$from..$to';
			case PPTFlags(_): "flags";
			case PPTArray: "array";
			case PPTHexDirection: "hexDirection";
			case PPTGridDirection: "gridDirection";
		};
	}

	static function posToRange(pos:ParsePosition, text:String):LspRange {
		// ParsePosition is 1-based; LSP is 0-based
		final line = pos.line - 1;
		final col = pos.col - 1;
		return {
			start: {line: line, character: col},
			end: {line: line, character: col + 1}
		};
	}

	static function findNameInText(text:String, name:String):LspRange {
		// Simple text search for a name to get its range
		final lines = text.split("\n");
		for (i in 0...lines.length) {
			final col = lines[i].indexOf(name);
			if (col >= 0) {
				return {
					start: {line: i, character: col},
					end: {line: i, character: col + name.length}
				};
			}
		}
		return {start: {line: 0, character: 0}, end: {line: 0, character: 0}};
	}

	@:allow(manim.lsp.AnimAnalyzer)
	static function getWordAtPosition(text:String, line:Int, character:Int):Null<String> {
		final lines = text.split("\n");
		if (line >= lines.length) return null;
		final lineText = lines[line];
		if (character >= lineText.length) return null;

		// Expand word boundaries (include $, #, @ as word starters)
		var start = character;
		var end = character;

		while (start > 0 && isWordChar(lineText.charCodeAt(start - 1)))
			start--;
		while (end < lineText.length && isWordChar(lineText.charCodeAt(end)))
			end++;

		// Include $ or # or @ prefix
		if (start > 0) {
			final c = lineText.charCodeAt(start - 1);
			if (c == "$".code || c == "#".code || c == "@".code)
				start--;
		}

		if (start == end) return null;
		return lineText.substr(start, end - start);
	}

	static function isWordChar(c:Int):Bool {
		return (c >= "a".code && c <= "z".code) || (c >= "A".code && c <= "Z".code) || (c >= "0".code && c <= "9".code) || c == "_".code;
	}

	static function findParameterDefinition(text:String, uri:String, paramName:String):Null<LspLocation> {
		// Search for parameter declaration in programmable() headers
		final lines = text.split("\n");
		for (i in 0...lines.length) {
			final line = lines[i];
			// Look for "paramName:" or "paramName=" pattern inside programmable()
			final idx = line.indexOf(paramName);
			if (idx >= 0 && line.indexOf("programmable") >= 0) {
				return {
					uri: uri,
					range: {
						start: {line: i, character: idx},
						end: {line: i, character: idx + paramName.length}
					}
				};
			}
		}
		return null;
	}

	static function findNamedElement(text:String, uri:String, name:String):Null<LspLocation> {
		final range = findNameInText(text, name);
		if (range.start.line == 0 && range.start.character == 0 && range.end.character == 0) return null;
		return {uri: uri, range: range};
	}

	static function uriToName(uri:String):String {
		// Convert file:///path/to/file.manim to a short name
		final lastSlash = uri.lastIndexOf("/");
		return lastSlash >= 0 ? uri.substr(lastSlash + 1) : uri;
	}
}
