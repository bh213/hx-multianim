package manim.lsp;

using StringTools;

/**
 * Lightweight cursor context analyzer for .manim files.
 * Scans text up to cursor position tracking brace depth and keywords
 * to determine what kind of completions are appropriate.
 *
 * This is intentionally NOT a full parser — it needs to handle
 * incomplete/broken files gracefully.
 */
enum CursorContext {
	TopLevel;
	ProgrammableBody;
	ProgrammableParams; // Inside programmable(...) parameter declaration
	ParticlesBody;
	CurvesBody;
	CurveBody;
	PathsBody;
	AnimatedPathBody;
	FlowBody;
	SettingsBody;
	TransitionBody;
	FilterPosition;
	DataBody;
	RepeatableBody;
	InteractiveParams;
	AfterDollar(prefix:String); // Typing a $reference
	AfterAt; // After @
	AfterConditionalOpen; // Inside @(
	EasingPosition;
	Unknown;
}

typedef CursorContextResult = {
	var context:CursorContext;
	var paramNames:Array<String>; // Parameters in scope from enclosing programmable
	var paramTypes:Map<String, String>; // Parameter types
	var prefix:String; // Partial word before cursor
}

class ContextAnalyzer {
	/**
	 * Analyze the text up to a cursor position and determine the editing context.
	 * Returns context type, parameters in scope, and the partial word being typed.
	 */
	public static function analyze(text:String, line:Int, character:Int):CursorContextResult {
		final lines = text.split("\n");
		final paramNames:Array<String> = [];
		final paramTypes = new Map<String, String>();

		// Build text up to cursor
		var textToCursor = "";
		for (i in 0...lines.length) {
			if (i == line) {
				textToCursor += lines[i].substr(0, character);
				break;
			}
			textToCursor += lines[i] + "\n";
		}

		// Get the partial word being typed
		final prefix = getPrefix(textToCursor);

		// Track nesting via brace stack
		final contextStack:Array<String> = []; // Stack of context keywords
		var inString = false;
		var inComment = false;
		var inLineComment = false;
		var i = 0;
		var lastKeyword = "";

		while (i < textToCursor.length) {
			final c = textToCursor.charCodeAt(i);

			// Line comment
			if (!inString && !inComment && c == "/".code && i + 1 < textToCursor.length && textToCursor.charCodeAt(i + 1) == "/".code) {
				inLineComment = true;
				i += 2;
				continue;
			}
			if (inLineComment) {
				if (c == "\n".code) inLineComment = false;
				i++;
				continue;
			}

			// Block comment
			if (!inString && !inComment && c == "/".code && i + 1 < textToCursor.length && textToCursor.charCodeAt(i + 1) == "*".code) {
				inComment = true;
				i += 2;
				continue;
			}
			if (inComment) {
				if (c == "*".code && i + 1 < textToCursor.length && textToCursor.charCodeAt(i + 1) == "/".code) {
					inComment = false;
					i += 2;
				} else {
					i++;
				}
				continue;
			}

			// String
			if (c == "\"".code && !inString) {
				inString = true;
				i++;
				continue;
			}
			if (inString) {
				if (c == "\\".code) {
					i += 2;
				} else if (c == "\"".code) {
					inString = false;
					i++;
				} else {
					i++;
				}
				continue;
			}

			// Track keywords before braces
			if (c == "{".code) {
				contextStack.push(lastKeyword);
				lastKeyword = "";
				i++;
				continue;
			}

			if (c == "}".code) {
				if (contextStack.length > 0) contextStack.pop();
				i++;
				continue;
			}

			// Extract identifiers for keyword tracking
			if (isIdentStart(c)) {
				var word = "";
				var j = i;
				while (j < textToCursor.length && isIdentChar(textToCursor.charCodeAt(j))) {
					word += String.fromCharCode(textToCursor.charCodeAt(j));
					j++;
				}

				// Track programmable parameters
				if (word == "programmable" || word == "slot") {
					// Try to extract params from the (...) that follows
					extractParams(textToCursor, j, paramNames, paramTypes);
				}

				// Remember meaningful keywords
				if (isContextKeyword(word)) {
					lastKeyword = word;
				}

				i = j;
				continue;
			}

			// Check for $ reference
			if (c == "$".code) {
				// Peek ahead to see if we're at cursor end
				if (i >= textToCursor.length - prefix.length - 1) {
					return {
						context: AfterDollar(prefix),
						paramNames: paramNames,
						paramTypes: paramTypes,
						prefix: prefix
					};
				}
			}

			// Check for @
			if (c == "@".code) {
				if (i == textToCursor.length - 1) {
					return {context: AfterAt, paramNames: paramNames, paramTypes: paramTypes, prefix: prefix};
				}
				if (i + 1 < textToCursor.length && textToCursor.charCodeAt(i + 1) == "(".code) {
					// Check if we're still inside the @( ... ) — find matching )
					var depth = 0;
					var j = i + 1;
					var closed = false;
					while (j < textToCursor.length) {
						if (textToCursor.charCodeAt(j) == "(".code)
							depth++;
						else if (textToCursor.charCodeAt(j) == ")".code) {
							depth--;
							if (depth == 0) {
								closed = true;
								break;
							}
						}
						j++;
					}
					if (!closed) {
						return {context: AfterConditionalOpen, paramNames: paramNames, paramTypes: paramTypes, prefix: prefix};
					}
				}
			}

			i++;
		}

		// Determine context from stack
		final context = determineContext(contextStack, lastKeyword, prefix);

		// Check for filter position
		if (prefix.length == 0 || !prefix.startsWith("$")) {
			final trimmed = textToCursor.rtrim();
			if (trimmed.endsWith("filter:") || trimmed.endsWith("filter :")) {
				return {context: FilterPosition, paramNames: paramNames, paramTypes: paramTypes, prefix: prefix};
			}
		}

		return {context: context, paramNames: paramNames, paramTypes: paramTypes, prefix: prefix};
	}

	static function determineContext(stack:Array<String>, lastKeyword:String, prefix:String):CursorContext {
		if (stack.length == 0) return TopLevel;

		// Walk the stack from outermost to innermost
		var innermost = stack[stack.length - 1];

		return switch (innermost) {
			case "programmable": ProgrammableBody;
			case "particles": ParticlesBody;
			case "curves": CurvesBody;
			case "curve": CurveBody;
			case "paths": PathsBody;
			case "animatedPath": AnimatedPathBody;
			case "flow": FlowBody;
			case "settings": SettingsBody;
			case "transition": TransitionBody;
			case "data": DataBody;
			case "repeatable" | "repeatable2d": RepeatableBody;
			default:
				// Check parent contexts
				if (stack.length >= 2) {
					final parent = stack[stack.length - 2];
					if (parent == "curves") return CurveBody;
					if (parent == "programmable" || parent == "flow" || parent == "layers" || parent == "mask" || parent == "repeatable" || parent == "repeatable2d") return ProgrammableBody;
				}
				if (stack.length >= 1 && (stack[0] == "programmable" || stack[0] == "")) {
					return ProgrammableBody;
				}
				Unknown;
		};
	}

	static function extractParams(text:String, startIdx:Int, paramNames:Array<String>, paramTypes:Map<String, String>):Void {
		// Find the opening ( after 'programmable' keyword
		var i = startIdx;
		while (i < text.length && text.charCodeAt(i) == " ".code)
			i++;
		if (i >= text.length || text.charCodeAt(i) != "(".code) return;
		i++; // skip (

		var depth = 1;
		var current = "";

		while (i < text.length && depth > 0) {
			final c = text.charCodeAt(i);
			if (c == "(".code) depth++;
			else if (c == ")".code) {
				depth--;
				if (depth == 0) break;
			}

			if (c == ",".code && depth == 1) {
				parseParam(current.trim(), paramNames, paramTypes);
				current = "";
			} else {
				current += String.fromCharCode(c);
			}
			i++;
		}
		if (current.trim().length > 0) {
			parseParam(current.trim(), paramNames, paramTypes);
		}
	}

	static function parseParam(param:String, paramNames:Array<String>, paramTypes:Map<String, String>):Void {
		// Format: name:type=default or name:type or name=[...]=default
		final colonIdx = param.indexOf(":");
		final eqIdx = param.indexOf("=");
		final bracketIdx = param.indexOf("[");

		var name = "";
		var type = "";

		if (colonIdx >= 0) {
			name = param.substr(0, colonIdx).trim();
			if (eqIdx >= 0 && eqIdx > colonIdx) {
				type = param.substr(colonIdx + 1, eqIdx - colonIdx - 1).trim();
			} else {
				type = param.substr(colonIdx + 1).trim();
			}
		} else if (bracketIdx >= 0) {
			// name=[val1,val2,...]=default — enum shorthand
			name = param.substr(0, bracketIdx).trim();
			// Find closing bracket
			final closeBracket = param.indexOf("]");
			if (closeBracket >= 0) {
				type = param.substr(bracketIdx, closeBracket - bracketIdx + 1);
			}
		} else if (eqIdx >= 0) {
			name = param.substr(0, eqIdx).trim();
		}

		if (name.length > 0) {
			paramNames.push(name);
			if (type.length > 0) paramTypes.set(name, type);
		}
	}

	static function getPrefix(textToCursor:String):String {
		var i = textToCursor.length - 1;
		while (i >= 0) {
			final c = textToCursor.charCodeAt(i);
			if (isIdentChar(c) || c == "$".code || c == "#".code || c == "@".code) {
				i--;
			} else {
				break;
			}
		}
		return textToCursor.substr(i + 1);
	}

	static function isContextKeyword(word:String):Bool {
		return switch (word) {
			case "programmable" | "particles" | "curves" | "paths" | "animatedPath" | "flow" | "layers" | "mask" | "settings" | "transition" | "data" | "repeatable"
				| "repeatable2d" | "curve" | "tilegroup" | "slot":
				true;
			default:
				false;
		};
	}

	static function isIdentStart(c:Int):Bool {
		return (c >= "a".code && c <= "z".code) || (c >= "A".code && c <= "Z".code) || c == "_".code;
	}

	static function isIdentChar(c:Int):Bool {
		return isIdentStart(c) || (c >= "0".code && c <= "9".code);
	}
}
