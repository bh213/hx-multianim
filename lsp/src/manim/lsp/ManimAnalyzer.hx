package manim.lsp;

import bh.multianim.MacroManimParser;
import bh.base.ParsePosition;
import manim.lsp.LspTypes;

using StringTools;

/**
 * Core analysis engine for .manim files.
 * Uses MacroManimParser for parsing and provides LSP features:
 * diagnostics, completions, hover, symbols, go-to-definition.
 *
 * Uses Dynamic for AST types to avoid noheaps module resolution issues.
 */
class ManimAnalyzer {
	/**
	 * Parse a .manim document and return diagnostics.
	 */
	public static function getDiagnostics(text:String, uri:String):Array<LspDiagnostic> {
		final diagnostics:Array<LspDiagnostic> = [];

		try {
			MacroManimParser.parseFile(text, uriToName(uri), null);
		} catch (e:Dynamic) {
			// Parser exceptions — extract position and message.
			// Haxe JS wraps non-Exception throws, so access fields via Dynamic carefully.
			final unwrapped:Dynamic = js.Syntax.code("({0} && {0}.val) ? {0}.val : {0}", e);
			final msg:String = {
				final error:Null<String> = unwrapped.error;
				final message:Null<String> = unwrapped.message;
				if (error != null) error
				else if (message != null) message
				else Std.string(e);
			};

			// Try to get ParsePosition from exception
			final pos:Dynamic = unwrapped.pos;
			final posLine:Dynamic = pos != null ? pos.line : null;

			if (posLine != null) {
				final line:Int = posLine;
				final col:Int = pos.col;
				diagnostics.push({
					range: {
						start: {line: line - 1, character: col - 1},
						end: {line: line - 1, character: col}
					},
					severity: DiagnosticSeverity.Error,
					message: msg,
					source: "manim"
				});
			} else {
				// Fallback: parse "filename:line:col:" pattern from error string
				final parsed = parsePositionFromMessage(msg);
				diagnostics.push({
					range: parsed.range,
					severity: DiagnosticSeverity.Error,
					message: parsed.message,
					source: "manim"
				});
			}
		}

		return diagnostics;
	}

	/**
	 * Get document symbols (outline) from a parsed .manim file.
	 * Uses Dynamic access on AST nodes to avoid typed imports.
	 */
	public static function getSymbols(text:String, uri:String):Array<LspSymbolInformation> {
		final symbols:Array<LspSymbolInformation> = [];

		try {
			final result = MacroManimParser.parseFile(text, uriToName(uri), null);
			final nodes:Dynamic = result.nodes;

			// Iterate the nodes map (Haxe StringMap uses .h object internally)
			final keys:Array<String> = js.Syntax.code("Object.keys({0}.h)", nodes);

			for (name in keys) {
				final node:Dynamic = js.Syntax.code("{0}.h[{1}]", nodes, name);
				final range = findNameInText(text, name);
				final nodeType:Dynamic = node.type;
				final typeName:String = enumName(nodeType);

				final symbol:LspSymbolInformation = switch (typeName) {
					case "PROGRAMMABLE":
						final parameters:Dynamic = nodeType.parameters;
						final paramList = getParamList(parameters);
						{
							name: name,
							kind: SymbolKind.Class,
							range: range,
							selectionRange: range,
							detail: paramList.length > 0 ? '(${paramList.join(", ")})' : null,
							children: getChildSymbols(node, text)
						};
					case "DATA":
						{name: name, kind: SymbolKind.Struct, range: range, selectionRange: range};
					case "CURVES":
						{name: name, kind: SymbolKind.Namespace, range: range, selectionRange: range, detail: "curves"};
					case "PATHS":
						{name: name, kind: SymbolKind.Namespace, range: range, selectionRange: range, detail: "paths"};
					case "ANIMATED_PATH":
						{name: name, kind: SymbolKind.Function, range: range, selectionRange: range, detail: "animatedPath"};
					case "FINAL_VAR":
						final n:String = nodeType.name;
						{name: n, kind: SymbolKind.Constant, range: range, selectionRange: range, detail: "@final"};
					case "RELATIVE_LAYOUTS":
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

	static function getParamList(parameters:Dynamic):Array<String> {
		final result:Array<String> = [];
		final keys:Array<String> = js.Syntax.code("Object.keys({0}.h)", parameters);
		for (k in keys) {
			final v:Dynamic = js.Syntax.code("{0}.h[{1}]", parameters, k);
			result.push('$k:${defTypeName(v.type)}');
		}
		return result;
	}

	static function defTypeName(type:Dynamic):String {
		final name:String = enumName(type);
		return switch (name) {
			case "PPTEnum":
				final values:Array<String> = type.values;
				'[${values.join(",")}]';
			case "PPTRange": '${type.from}..${type.to}';
			case "PPTInt": "int";
			case "PPTFloat": "float";
			case "PPTBool": "bool";
			case "PPTUnsignedInt": "uint";
			case "PPTString": "string";
			case "PPTColor": "color";
			case "PPTTile": "tile";
			case "PPTFlags": "flags";
			case "PPTHexDirection": "hexDirection";
			case "PPTGridDirection": "gridDirection";
			default: "?";
		};
	}

	static function getChildSymbols(node:Dynamic, text:String):Null<Array<LspSymbolInformation>> {
		final children:Array<LspSymbolInformation> = [];
		final nodeChildren:Array<Dynamic> = node.children;
		if (nodeChildren == null) return null;

		for (child in nodeChildren) {
			final uname:Dynamic = child.updatableName;
			final unameName:String = enumName(uname);
			if (unameName == "UNTName" || unameName == "UNTNameIndexed" || unameName == "UNTNameIndexed2D") {
				final name:String = uname.name;
				final range = findNameInText(text, '#$name');
				final childTypeName:String = enumName(child.type);
				final kind = if (childTypeName == "SLOT" || childTypeName == "INTERACTIVE") SymbolKind.Field else SymbolKind.Property;
				children.push({
					name: '#$name',
					kind: kind,
					range: range,
					selectionRange: range,
					detail: nodeTypeLabel(childTypeName)
				});
			}
			// Recurse
			final grandchildren = getChildSymbols(child, text);
			if (grandchildren != null) {
				for (gc in grandchildren) children.push(gc);
			}
		}
		return children.length > 0 ? children : null;
	}

	static function nodeTypeLabel(name:String):String {
		return switch (name) {
			case "BITMAP": "bitmap";
			case "TEXT": "text";
			case "RICHTEXT": "richText";
			case "NINEPATCH": "ninepatch";
			case "FLOW": "flow";
			case "LAYERS": "layers";
			case "MASK": "mask";
			case "TILEGROUP": "tilegroup";
			case "INTERACTIVE": "interactive";
			case "SLOT": "slot";
			case "SPACER": "spacer";
			case "POINT": "point";
			case "REPEAT": "repeatable";
			case "REPEAT2D": "repeatable2d";
			case "STATIC_REF": "staticRef";
			case "DYNAMIC_REF": "dynamicRef";
			case "PLACEHOLDER": "placeholder";
			case "GRAPHICS": "graphics";
			case "PIXELS": "pixels";
			case "PARTICLES": "particles";
			case "APPLY": "apply";
			case "PROGRAMMABLE": "programmable";
			case "STATEANIM" | "STATEANIM_CONSTRUCT": "stateanim";
			case "DATA": "data";
			case "ANIMATED_PATH": "animatedPath";
			case "CURVES": "curves";
			case "PATHS": "paths";
			case "FINAL_VAR": "@final";
			default: "";
		}
	}

	/** Parse "file:line:col:" or "file:line: character col" from error string */
	static function parsePositionFromMessage(msg:String):{range:LspRange, message:String} {
		// Pattern: "Error ..., filename:LINE: character COL"
		// or "filename:LINE:COL: ..."
		final colonPattern = new EReg("(\\d+):\\s*character\\s+(\\d+)", "");
		if (colonPattern.match(msg)) {
			final line = Std.parseInt(colonPattern.matched(1));
			final col = Std.parseInt(colonPattern.matched(2));
			if (line != null && col != null) {
				return {
					range: {
						start: {line: line - 1, character: col - 1},
						end: {line: line - 1, character: col}
					},
					message: msg
				};
			}
		}

		// Pattern: "filename:LINE:COL:"
		final simplePattern = new EReg(":(\\d+):(\\d+)", "");
		if (simplePattern.match(msg)) {
			final line = Std.parseInt(simplePattern.matched(1));
			final col = Std.parseInt(simplePattern.matched(2));
			if (line != null && col != null) {
				return {
					range: {
						start: {line: line - 1, character: col - 1},
						end: {line: line - 1, character: col}
					},
					message: msg
				};
			}
		}

		// No position found
		return {
			range: {start: {line: 0, character: 0}, end: {line: 0, character: 1}},
			message: msg
		};
	}

	/** Get Haxe enum constructor name from a Dynamic enum value (JS target).
	 * Parameterless constructors have _hx_name directly on the object.
	 * Parameterized constructors store _hx_name on the factory function, not the instance.
	 * For those, look up via __constructs__[_hx_index]._hx_name using the __enum__ registry.
	 */
	static inline function enumName(value:Dynamic):String {
		return js.Syntax.code("{0}._hx_name || ($hxEnums[{0}.__enum__].__constructs__[{0}._hx_index]._hx_name)", value);
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
