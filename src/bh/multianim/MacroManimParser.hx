package bh.multianim;

import bh.multianim.MultiAnimParser;
import bh.multianim.CoordinateSystems;
import bh.multianim.MacroCompatTypes.MacroBlendMode;
import bh.multianim.MacroCompatTypes.MacroFlowLayout;
import bh.multianim.MacroCompatTypes.MacroFlowOverflow;
import bh.multianim.layouts.LayoutTypes;
import bh.base.Hex;

using StringTools;

// ===================== Token types for the hand-coded lexer =====================

private enum MacroTokenType {
	TEof;
	TOpen;          // (
	TClosed;        // )
	TBracketOpen;   // [
	TBracketClosed; // ]
	TCurlyOpen;     // {
	TCurlyClosed;   // }
	TComma;
	TAt;
	TExclamation;
	TQuestion;
	TColon;
	TDoubleDot;     // ..
	TSemiColon;
	TArrow;         // =>
	TStar;
	TPercent;
	TPlus;
	TSlash;
	TMinus;
	TEquals;
	TLessThan;
	TGreaterThan;
	TLessEquals;
	TGreaterEquals;
	TNotEquals;     // !=
	TDoubleEquals;  // ==
	TInteger(s:String);
	TFloat(s:String);
	THexInteger(s:String);
	TIdentifier(s:String);
	TName(s:String);       // #name
	TReference(s:String);  // $ref
	TQuotedString(s:String);
}

private class Token {
	public var type:MacroTokenType;
	public var line:Int;
	public var col:Int;
	public function new(type:MacroTokenType, line:Int, col:Int) {
		this.type = type;
		this.line = line;
		this.col = col;
	}
	public function toString():String {
		return Std.string(type);
	}
}

// ===================== Lexer =====================

private class MacroLexer {
	var src:String;
	var pos:Int;
	var len:Int;
	var line:Int;
	var col:Int;
	var lineStart:Int;
	var sourceName:String;
	var pendingTokens:Array<Token> = [];

	public function new(src:String, sourceName:String) {
		this.src = src;
		this.pos = 0;
		this.len = src.length;
		this.line = 1;
		this.col = 1;
		this.lineStart = 0;
		this.sourceName = sourceName;
	}

	public function nextToken():Token {
		if (pendingTokens.length > 0) return pendingTokens.shift();
		while (pos < len) {
			final startLine = line;
			final startCol = pos - lineStart + 1;
			final c = src.charCodeAt(pos);

			// Whitespace
			if (c == ' '.code || c == '\t'.code || c == '\r'.code) {
				pos++;
				continue;
			}
			// Newline
			if (c == '\n'.code) {
				pos++;
				line++;
				lineStart = pos;
				continue;
			}

			// Comments
			if (c == '/'.code && pos + 1 < len) {
				final c2 = src.charCodeAt(pos + 1);
				if (c2 == '/'.code) {
					// Line comment
					pos += 2;
					while (pos < len && src.charCodeAt(pos) != '\n'.code)
						pos++;
					continue;
				}
				if (c2 == '*'.code) {
					// Block comment
					pos += 2;
					while (pos + 1 < len) {
						if (src.charCodeAt(pos) == '*'.code && src.charCodeAt(pos + 1) == '/'.code) {
							pos += 2;
							break;
						}
						if (src.charCodeAt(pos) == '\n'.code) {
							line++;
							lineStart = pos + 1;
						}
						pos++;
					}
					continue;
				}
			}

			// Two-character operators (must check before single-char)
			if (pos + 1 < len) {
				final c2 = src.charCodeAt(pos + 1);
				if (c == '='.code && c2 == '>'.code) { pos += 2; return new Token(TArrow, startLine, startCol); }
				if (c == '='.code && c2 == '='.code) { pos += 2; return new Token(TDoubleEquals, startLine, startCol); }
				if (c == '!'.code && c2 == '='.code) { pos += 2; return new Token(TNotEquals, startLine, startCol); }
				if (c == '<'.code && c2 == '='.code) { pos += 2; return new Token(TLessEquals, startLine, startCol); }
				if (c == '>'.code && c2 == '='.code) { pos += 2; return new Token(TGreaterEquals, startLine, startCol); }
				if (c == '.'.code && c2 == '.'.code) { pos += 2; return new Token(TDoubleDot, startLine, startCol); }
			}

			// Single-character tokens
			switch (c) {
				case '('.code: pos++; return new Token(TOpen, startLine, startCol);
				case ')'.code: pos++; return new Token(TClosed, startLine, startCol);
				case '['.code: pos++; return new Token(TBracketOpen, startLine, startCol);
				case ']'.code: pos++; return new Token(TBracketClosed, startLine, startCol);
				case '{'.code: pos++; return new Token(TCurlyOpen, startLine, startCol);
				case '}'.code: pos++; return new Token(TCurlyClosed, startLine, startCol);
				case ','.code: pos++; return new Token(TComma, startLine, startCol);
				case '@'.code: pos++; return new Token(TAt, startLine, startCol);
				case '?'.code: pos++; return new Token(TQuestion, startLine, startCol);
				case ':'.code: pos++; return new Token(TColon, startLine, startCol);
				case ';'.code: pos++; return new Token(TSemiColon, startLine, startCol);
				case '*'.code: pos++; return new Token(TStar, startLine, startCol);
				case '%'.code: pos++; return new Token(TPercent, startLine, startCol);
				case '+'.code: pos++; return new Token(TPlus, startLine, startCol);
				case '/'.code: pos++; return new Token(TSlash, startLine, startCol);
				case '-'.code: pos++; return new Token(TMinus, startLine, startCol);
				case '='.code: pos++; return new Token(TEquals, startLine, startCol);
				case '<'.code: pos++; return new Token(TLessThan, startLine, startCol);
				case '>'.code: pos++; return new Token(TGreaterThan, startLine, startCol);
				case '!'.code: pos++; return new Token(TExclamation, startLine, startCol);
				default:
			}

			// Hex number: 0x...
			if (c == '0'.code && pos + 1 < len && (src.charCodeAt(pos + 1) == 'x'.code || src.charCodeAt(pos + 1) == 'X'.code)) {
				pos += 2;
				final hexStart = pos;
				while (pos < len) {
					final hc = src.charCodeAt(pos);
					if ((hc >= '0'.code && hc <= '9'.code) || (hc >= 'a'.code && hc <= 'f'.code) || (hc >= 'A'.code && hc <= 'F'.code) || hc == '_'.code) {
						pos++;
					} else break;
				}
				return new Token(THexInteger(src.substring(hexStart, pos)), startLine, startCol);
			}

			// Number: integer or float
			if ((c >= '0'.code && c <= '9'.code) || (c == '.'.code && pos + 1 < len && src.charCodeAt(pos + 1) >= '0'.code && src.charCodeAt(pos + 1) <= '9'.code)) {
				final numStart = pos;
				var isFloat = c == '.'.code;
				pos++;
				while (pos < len) {
					final nc = src.charCodeAt(pos);
					if (nc >= '0'.code && nc <= '9'.code || nc == '_'.code) {
						pos++;
					} else if (nc == '.'.code && !isFloat && pos + 1 < len && src.charCodeAt(pos + 1) != '.'.code) {
						isFloat = true;
						pos++;
					} else break;
				}
				final numStr = src.substring(numStart, pos);
				return new Token(isFloat ? TFloat(numStr) : TInteger(numStr), startLine, startCol);
			}

			// Quoted string: "..."
			if (c == '"'.code) {
				pos++;
				var buf = new StringBuf();
				while (pos < len) {
					final sc = src.charCodeAt(pos);
					if (sc == '\\'.code && pos + 1 < len) {
						final sc2 = src.charCodeAt(pos + 1);
						if (sc2 == '"'.code) { buf.addChar('"'.code); pos += 2; continue; }
						if (sc2 == '\\'.code) { buf.addChar('\\'.code); pos += 2; continue; }
						if (sc2 == 'n'.code) { buf.addChar('\n'.code); pos += 2; continue; }
						buf.addChar('\\'.code);
						pos++;
						continue;
					}
					if (sc == '"'.code) {
						pos++;
						break;
					}
					if (sc == '\n'.code) { line++; lineStart = pos + 1; }
					buf.addChar(sc);
					pos++;
				}
				return new Token(TQuotedString(buf.toString()), startLine, startCol);
			}

			// Single-quoted string with interpolation: '...${expr}...'
			if (c == "'".code) {
				pos++;
				var buf = new StringBuf();
				var parts:Array<{isCode:Bool, text:String}> = [];
				var hasInterpolation = false;
				var closed = false;
				while (pos < len) {
					final sc = src.charCodeAt(pos);
					if (sc == '\\'.code && pos + 1 < len) {
						final sc2 = src.charCodeAt(pos + 1);
						if (sc2 == "'".code) { buf.addChar("'".code); pos += 2; continue; }
						if (sc2 == '\\'.code) { buf.addChar('\\'.code); pos += 2; continue; }
						if (sc2 == 'n'.code) { buf.addChar('\n'.code); pos += 2; continue; }
						buf.addChar('\\'.code);
						pos++;
						continue;
					}
					if (sc == "'".code) {
						pos++;
						closed = true;
						break;
					}
					// Check for ${...} interpolation
					if (sc == '$'.code && pos + 1 < len && src.charCodeAt(pos + 1) == '{'.code) {
						hasInterpolation = true;
						parts.push({isCode: false, text: buf.toString()});
						buf = new StringBuf();
						final interpLine = line;
						final interpCol = pos - lineStart + 1;
						pos += 2; // skip ${
						// Extract code until matching }
						var depth = 1;
						var codeStart = pos;
						while (pos < len && depth > 0) {
							final bc = src.charCodeAt(pos);
							if (bc == '{'.code) depth++;
							else if (bc == '}'.code) depth--;
							else if (bc == "'".code) {
								// Hit string terminator before closing } — interpolation is unclosed
								throw '$sourceName:$interpLine:$interpCol: Unclosed string interpolation, expected }';
							}
							if (depth > 0) pos++;
						}
						if (depth > 0) {
							throw '$sourceName:$interpLine:$interpCol: Unclosed string interpolation, expected }';
						}
						final codeText = src.substring(codeStart, pos);
						if (StringTools.trim(codeText).length == 0) {
							throw '$sourceName:$interpLine:$interpCol: Empty expression in string interpolation';
						}
						parts.push({isCode: true, text: codeText});
						if (pos < len) pos++; // skip }
						continue;
					}
					if (sc == '\n'.code) { line++; lineStart = pos + 1; }
					buf.addChar(sc);
					pos++;
				}
				if (!closed) {
					throw '$sourceName:$startLine:$startCol: Unterminated string, missing closing single quote';
				}

				if (!hasInterpolation) {
					return new Token(TQuotedString(buf.toString()), startLine, startCol);
				}

				// Has interpolation — emit tokens for: "prefix" + expr + "suffix" + ...
				final remaining = buf.toString();
				if (remaining.length > 0) parts.push({isCode: false, text: remaining});

				// Build token list: parts joined with + operators, code parts re-lexed
				var filtered:Array<Token> = [];
				for (part in parts) {
					if (part.isCode) {
						// Re-lex the code section
						var codeTokens:Array<Token> = [];
						final subLexer = new MacroLexer(part.text, sourceName);
						while (true) {
							final st = subLexer.nextToken();
							if (Type.enumEq(st.type, TEof)) break;
							codeTokens.push(st);
						}
						if (codeTokens.length == 0) continue; // skip empty code
						// Insert + before this part if there are preceding tokens
						if (filtered.length > 0) filtered.push(new Token(TPlus, startLine, startCol));
						// Wrap multi-token expressions in parentheses for correct precedence
						if (codeTokens.length > 1) {
							filtered.push(new Token(TOpen, startLine, startCol));
							for (t in codeTokens) filtered.push(t);
							filtered.push(new Token(TClosed, startLine, startCol));
						} else {
							for (t in codeTokens) filtered.push(t);
						}
					} else if (part.text.length > 0) {
						// Insert + before this part if there are preceding tokens
						if (filtered.length > 0) filtered.push(new Token(TPlus, startLine, startCol));
						filtered.push(new Token(TQuotedString(part.text), startLine, startCol));
					}
					// Skip empty string parts entirely
				}

				if (filtered.length == 0) return new Token(TQuotedString(""), startLine, startCol);
				final first = filtered.shift();
				for (t in filtered) pendingTokens.push(t);
				return first;
			}

			// #name
			if (c == '#'.code) {
				pos++;
				final idStart = pos;
				while (pos < len) {
					final ic = src.charCodeAt(pos);
					if ((ic >= 'a'.code && ic <= 'z'.code) || (ic >= 'A'.code && ic <= 'Z'.code) || (ic >= '0'.code && ic <= '9'.code) || ic == '_'.code || ic == '-'.code) {
						pos++;
					} else break;
				}
				return new Token(TName(src.substring(idStart, pos)), startLine, startCol);
			}

			// $reference
			if (c == '$'.code) {
				pos++;
				final idStart = pos;
				while (pos < len) {
					final ic = src.charCodeAt(pos);
					if ((ic >= 'a'.code && ic <= 'z'.code) || (ic >= 'A'.code && ic <= 'Z'.code) || (ic >= '0'.code && ic <= '9'.code) || ic == '_'.code) {
						pos++;
					} else break;
				}
				return new Token(TReference(src.substring(idStart, pos)), startLine, startCol);
			}

			// Identifier
			if ((c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || c == '_'.code) {
				final idStart = pos;
				pos++;
				while (pos < len) {
					final ic = src.charCodeAt(pos);
					if ((ic >= 'a'.code && ic <= 'z'.code) || (ic >= 'A'.code && ic <= 'Z'.code) || (ic >= '0'.code && ic <= '9'.code) || ic == '_'.code || ic == '-'.code) {
						pos++;
					} else break;
				}
				return new Token(TIdentifier(src.substring(idStart, pos)), startLine, startCol);
			}

			// Unknown character - skip
			pos++;
		}
		return new Token(TEof, line, pos - lineStart + 1);
	}

	public function posString():String {
		return '$sourceName:$line';
	}
}

// ===================== Parser =====================

class MacroManimParser {
	var tokens:Array<Token>;
	var tpos:Int;
	var sourceName:String;
	var nodes:Map<String, Node>;
	var imports:Map<String, Dynamic>;
	var resourceLoader:Dynamic;
	var uniqueCounter:Int;
	var currentName:Null<String>;
	var activeDefs:Null<ParametersDefinitions>; // null = not inside programmable, set to currentDefs when entering programmable scope
	var scopeVars:Null<Array<String>>; // loop vars, iterator output vars, @final vars (not in activeDefs)

	static final defaultLayoutNodeName = "#defaultLayout";
	static final defaultPathNodeName = "#defaultPaths";
	static final defaultCurveNodeName = "#defaultCurves";

	function new(tokens:Array<Token>, sourceName:String, ?resourceLoader:Dynamic) {
		this.tokens = tokens;
		this.tpos = 0;
		this.sourceName = sourceName;
		this.nodes = new Map();
		this.imports = new Map();
		this.resourceLoader = resourceLoader;
		this.uniqueCounter = 654321;
		this.activeDefs = null;
		this.scopeVars = null;
	}

	function validateRef(name:String):Void {
		if (activeDefs == null) return; // not inside programmable, skip validation
		if (activeDefs.exists(name)) return;
		if (scopeVars != null && scopeVars.indexOf(name) >= 0) return;
		final paramNames = [for (k in activeDefs.keys()) k];
		final allVars = scopeVars != null ? paramNames.concat(scopeVars) : paramNames;
		final available = allVars.length > 0 ? allVars.join(", ") : "(none)";
		error('unknown variable $$' + name + '. Available: ' + available);
	}

	// ---- Token access ----

	inline function peek():MacroTokenType {
		return tokens[tpos].type;
	}

	inline function peekToken():Token {
		return tokens[tpos];
	}

	function advance():Token {
		final t = tokens[tpos];
		if (tpos < tokens.length - 1) tpos++;
		return t;
	}

	function expect(type:MacroTokenType):Void {
		final t = peek();
		if (!Type.enumEq(t, type))
			error('expected $type, got $t');
		advance();
	}

	function expectKeyword(keyword:String):Void {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, keyword)):
				advance();
			default:
				error('expected "$keyword", got ${peek()}');
		}
	}

	function match(type:MacroTokenType):Bool {
		if (Type.enumEq(peek(), type)) {
			advance();
			return true;
		}
		return false;
	}

	function error(msg:String):Dynamic {
		final t = peekToken();
		throw '$sourceName:${t.line}:${t.col}: $msg';
	}

	function posString():String {
		final t = peekToken();
		return '$sourceName:${t.line}:${t.col}';
	}

	// ---- Utility ----

	function eatSemicolon():Void {
		match(TSemiColon);
	}

	function eatComma():Void {
		match(TComma);
	}

	function generateUniqueName(id:Int, name:String, typeName:String):String {
		return '${name}_${typeName}_${id}';
	}

	// ---- Keyword lookup ----

	static function isKeyword(s:String, kw:String):Bool {
		return s.toLowerCase() == kw.toLowerCase();
	}

	// ---- Integer/Float parsing helpers ----

	function stringToInt(s:String):Int {
		// Handle underscore separators
		final cleaned = s.split("_").join("");
		final i = Std.parseInt(cleaned);
		if (i == null) error('expected integer, got $s');
		return i;
	}

	function stringToFloat(s:String):Float {
		final cleaned = s.split("_").join("");
		final f = Std.parseFloat(cleaned);
		if (Math.isNaN(f)) error('expected float, got $s');
		return f;
	}

	// ===================== Expression Parsing =====================

	function parseIntegerOrReference():ReferenceableValue {
		switch (peek()) {
			case TQuestion:
				advance();
				expect(TOpen);
				final cond = parseAnything();
				expect(TClosed);
				final ifTrue = parseIntegerOrReference();
				expect(TColon);
				final ifFalse = parseIntegerOrReference();
				return parseNextIntExpression(RVTernary(cond, ifTrue, ifFalse));
			case TIdentifier(s) if (isKeyword(s, "callback")):
				advance();
				return parseCallback();
			case TIdentifier(s) if (isKeyword(s, "function")):
				advance();
				expect(TOpen);
				return RVFunction(parseFunction());
			case TMinus:
				advance();
				switch (peek()) {
					case TInteger(n):
						advance();
						return parseNextIntExpression(RVInteger(-stringToInt(n)));
					case THexInteger(n):
						advance();
						return parseNextIntExpression(RVInteger(-stringToInt("0x" + n)));
					case TReference(s):
						advance();
						validateRef(s);
						if (match(TBracketOpen)) {
							final idx = parseIntegerOrReference();
							expect(TBracketClosed);
							return parseNextIntExpression(EUnaryOp(OpNeg, RVElementOfArray(s, idx)));
						}
						return parseNextIntExpression(EUnaryOp(OpNeg, RVReference(s)));
					case TOpen:
						advance();
						final e = parseIntegerOrReference();
						expect(TClosed);
						return parseNextIntExpression(EUnaryOp(OpNeg, RVParenthesis(e)));
					default:
						return error('expected value after unary minus');
				}
			case TInteger(n):
				advance();
				return parseNextIntExpression(RVInteger(stringToInt(n)));
			case THexInteger(n):
				advance();
				return parseNextIntExpression(RVInteger(stringToInt("0x" + n)));
			case TReference(s):
				advance();
				validateRef(s);
				if (match(TBracketOpen)) {
					final idx = parseIntegerOrReference();
					expect(TBracketClosed);
					return parseNextIntExpression(RVElementOfArray(s, idx));
				}
				return parseNextIntExpression(RVReference(s));
			case TOpen:
				advance();
				final e = parseIntegerOrReference();
				expect(TClosed);
				return parseNextIntExpression(RVParenthesis(e));
			default:
				return error('expected integer or expression, got ${peek()}');
		}
	}

	function parseNextIntExpression(e1:ReferenceableValue):ReferenceableValue {
		switch (peek()) {
			case TPlus: advance(); return binop(e1, OpAdd, parseIntegerOrReference());
			case TMinus: advance(); return binop(e1, OpSub, parseIntegerOrReference());
			case TStar: advance(); return binop(e1, OpMul, parseIntegerOrReference());
			case TSlash: advance(); return binop(e1, OpDiv, parseIntegerOrReference());
			case TPercent: advance(); return binop(e1, OpMod, parseIntegerOrReference());
			case TIdentifier(s) if (isKeyword(s, "div")): advance(); return binop(e1, OpIntegerDiv, parseIntegerOrReference());
			case TDoubleEquals: advance(); return binop(e1, OpEq, parseIntegerOrReference());
			case TNotEquals: advance(); return binop(e1, OpNotEq, parseIntegerOrReference());
			case TLessThan: advance(); return binop(e1, OpLess, parseIntegerOrReference());
			case TGreaterThan: advance(); return binop(e1, OpGreater, parseIntegerOrReference());
			case TLessEquals: advance(); return binop(e1, OpLessEq, parseIntegerOrReference());
			case TGreaterEquals: advance(); return binop(e1, OpGreaterEq, parseIntegerOrReference());
			default: return e1;
		}
	}

	function parseFloatOrReference():ReferenceableValue {
		switch (peek()) {
			case TQuestion:
				advance();
				expect(TOpen);
				final cond = parseAnything();
				expect(TClosed);
				final ifTrue = parseFloatOrReference();
				expect(TColon);
				final ifFalse = parseFloatOrReference();
				return parseNextFloatExpression(RVTernary(cond, ifTrue, ifFalse));
			case TIdentifier(s) if (isKeyword(s, "callback")):
				advance();
				return parseCallback();
			case TIdentifier(s) if (isKeyword(s, "function")):
				advance();
				expect(TOpen);
				return RVFunction(parseFunction());
			case TMinus:
				advance();
				switch (peek()) {
					case TInteger(n) | TFloat(n):
						advance();
						return parseNextFloatExpression(RVFloat(-stringToFloat(n)));
					case TReference(s):
						advance();
						validateRef(s);
						if (match(TBracketOpen)) {
							final idx = parseFloatOrReference();
							expect(TBracketClosed);
							return parseNextFloatExpression(EUnaryOp(OpNeg, RVElementOfArray(s, idx)));
						}
						return parseNextFloatExpression(EUnaryOp(OpNeg, RVReference(s)));
					case TOpen:
						advance();
						final e = parseFloatOrReference();
						expect(TClosed);
						return parseNextFloatExpression(EUnaryOp(OpNeg, RVParenthesis(e)));
					default:
						return error('expected value after unary minus');
				}
			case TInteger(n) | TFloat(n):
				advance();
				return parseNextFloatExpression(RVFloat(stringToFloat(n)));
			case TReference(s):
				advance();
				validateRef(s);
				if (match(TBracketOpen)) {
					final idx = parseIntegerOrReference();
					expect(TBracketClosed);
					return parseNextFloatExpression(RVElementOfArray(s, idx));
				}
				return parseNextFloatExpression(RVReference(s));
			case TOpen:
				advance();
				final e = parseFloatOrReference();
				expect(TClosed);
				return RVParenthesis(e);
			default:
				return error('expected float or expression, got ${peek()}');
		}
	}

	function parseNextFloatExpression(e1:ReferenceableValue):ReferenceableValue {
		switch (peek()) {
			case TPlus: advance(); return binop(e1, OpAdd, parseFloatOrReference());
			case TMinus: advance(); return binop(e1, OpSub, parseFloatOrReference());
			case TStar: advance(); return binop(e1, OpMul, parseFloatOrReference());
			case TSlash: advance(); return binop(e1, OpDiv, parseFloatOrReference());
			case TPercent: advance(); return binop(e1, OpMod, parseFloatOrReference());
			case TIdentifier(s) if (isKeyword(s, "div")): advance(); return binop(e1, OpIntegerDiv, parseIntegerOrReference());
			case TDoubleEquals: advance(); return binop(e1, OpEq, parseFloatOrReference());
			case TNotEquals: advance(); return binop(e1, OpNotEq, parseFloatOrReference());
			case TLessThan: advance(); return binop(e1, OpLess, parseFloatOrReference());
			case TGreaterThan: advance(); return binop(e1, OpGreater, parseFloatOrReference());
			case TLessEquals: advance(); return binop(e1, OpLessEq, parseFloatOrReference());
			case TGreaterEquals: advance(); return binop(e1, OpGreaterEq, parseFloatOrReference());
			default: return e1;
		}
	}

	function parseStringOrReference():ReferenceableValue {
		switch (peek()) {
			case TQuestion:
				advance();
				expect(TOpen);
				final cond = parseAnything();
				expect(TClosed);
				final ifTrue = parseStringOrReference();
				expect(TColon);
				final ifFalse = parseStringOrReference();
				return parseNextStringExpression(RVTernary(cond, ifTrue, ifFalse));
			case TIdentifier(s) if (isKeyword(s, "callback")):
				advance();
				return parseCallback();
			case TMinus:
				advance();
				switch (peek()) {
					case TInteger(n) | TFloat(n):
						advance();
						return parseNextStringExpression(RVString('-' + n));
					default:
						return error('expected number after minus in string context');
				}
			case TInteger(n) | TFloat(n):
				advance();
				// Check for number-prefixed identifiers like "3x5" for font names
				switch (peek()) {
					case TIdentifier(s2):
						advance();
						return parseNextStringExpression(RVString(n + s2));
					default:
						return parseNextStringExpression(RVString(n));
				}
			case THexInteger(n):
				advance();
				return parseNextStringExpression(RVString("0x" + n));
			case TQuotedString(s):
				advance();
				return parseNextStringExpression(RVString(s));
			case TIdentifier(s):
				advance();
				return parseNextStringExpression(RVString(s));
			case TName(s):
				advance();
				return parseNextStringExpression(RVString(s));
			case TReference(s):
				advance();
				validateRef(s);
				if (match(TBracketOpen)) {
					final idx = parseIntegerOrReference();
					expect(TBracketClosed);
					return parseNextStringExpression(RVElementOfArray(s, idx));
				}
				return parseNextStringExpression(RVReference(s));
			case TOpen:
				advance();
				final e = parseStringOrReference();
				expect(TClosed);
				return RVParenthesis(e);
			default:
				return error('expected string or reference, got ${peek()}');
		}
	}

	function parseNextStringExpression(e1:ReferenceableValue):ReferenceableValue {
		switch (peek()) {
			case TPlus: advance(); return binop(e1, OpAdd, parseStringOrReference());
			case TMinus: advance(); return binop(e1, OpSub, parseStringOrReference());
			case TStar: advance(); return binop(e1, OpMul, parseStringOrReference());
			case TSlash: advance(); return binop(e1, OpDiv, parseStringOrReference());
			case TPercent: advance(); return binop(e1, OpMod, parseStringOrReference());
			case TDoubleEquals: advance(); return binop(e1, OpEq, parseStringOrReference());
			case TNotEquals: advance(); return binop(e1, OpNotEq, parseStringOrReference());
			case TLessThan: advance(); return binop(e1, OpLess, parseStringOrReference());
			case TGreaterThan: advance(); return binop(e1, OpGreater, parseStringOrReference());
			case TLessEquals: advance(); return binop(e1, OpLessEq, parseStringOrReference());
			case TGreaterEquals: advance(); return binop(e1, OpGreaterEq, parseStringOrReference());
			default: return e1;
		}
	}

	function parseAnything():ReferenceableValue {
		switch (peek()) {
			case TQuestion:
				advance();
				expect(TOpen);
				final cond = parseAnything();
				expect(TClosed);
				final ifTrue = parseAnything();
				expect(TColon);
				final ifFalse = parseAnything();
				return parseNextAnythingExpression(RVTernary(cond, ifTrue, ifFalse));
			case TIdentifier(s) if (isKeyword(s, "callback")):
				advance();
				return parseCallback();
			case TIdentifier(s) if (isKeyword(s, "function")):
				advance();
				expect(TOpen);
				return RVFunction(parseFunction());
			case TMinus:
				advance();
				switch (peek()) {
					case TInteger(n) | THexInteger(n):
						advance();
						return parseNextAnythingExpression(RVInteger(-stringToInt(n)));
					case TFloat(n):
						advance();
						return parseNextAnythingExpression(RVFloat(-stringToFloat(n)));
					case TReference(s):
						advance();
						validateRef(s);
						if (match(TBracketOpen)) {
							final idx = parseAnything();
							expect(TBracketClosed);
							return parseNextAnythingExpression(EUnaryOp(OpNeg, RVElementOfArray(s, idx)));
						}
						return parseNextAnythingExpression(EUnaryOp(OpNeg, RVReference(s)));
					case TOpen:
						advance();
						final e = parseAnything();
						expect(TClosed);
						return parseNextAnythingExpression(EUnaryOp(OpNeg, RVParenthesis(e)));
					default:
						return error('expected value after unary minus');
				}
			case TInteger(n) | THexInteger(n):
				advance();
				return parseNextAnythingExpression(RVInteger(stringToInt(n)));
			case TFloat(n):
				advance();
				return parseNextAnythingExpression(RVFloat(stringToFloat(n)));
			case TReference(s):
				advance();
				validateRef(s);
				if (match(TBracketOpen)) {
					final idx = parseAnything();
					expect(TBracketClosed);
					return parseNextAnythingExpression(RVElementOfArray(s, idx));
				}
				return parseNextAnythingExpression(RVReference(s));
			case TQuotedString(s):
				advance();
				return parseNextAnythingExpression(RVString(s));
			case TIdentifier(s):
				advance();
				return parseNextAnythingExpression(RVString(s));
			case TName(s):
				// TName is #xxx - try as color first (#f00, #FF0000, etc.)
				final c = tryStringToColor("#" + s);
				advance();
				if (c != null) return parseNextAnythingExpression(RVInteger(c));
				return parseNextAnythingExpression(RVString(s));
			case TOpen:
				advance();
				final e = parseAnything();
				expect(TClosed);
				return parseNextAnythingExpression(RVParenthesis(e));
			case TBracketOpen:
				advance();
				final arr:Array<ReferenceableValue> = [];
				while (!match(TBracketClosed)) {
					if (arr.length > 0) expect(TComma);
					arr.push(parseAnything());
				}
				return RVArray(arr);
			default:
				return error('expected value or expression, got ${peek()}');
		}
	}

	function parseNextAnythingExpression(e1:ReferenceableValue):ReferenceableValue {
		switch (peek()) {
			case TPlus: advance(); return binop(e1, OpAdd, parseAnything());
			case TMinus: advance(); return binop(e1, OpSub, parseAnything());
			case TStar: advance(); return binop(e1, OpMul, parseAnything());
			case TSlash: advance(); return binop(e1, OpDiv, parseAnything());
			case TPercent: advance(); return binop(e1, OpMod, parseAnything());
			case TIdentifier(s) if (isKeyword(s, "div")): advance(); return binop(e1, OpIntegerDiv, parseAnything());
			case TDoubleEquals: advance(); return binop(e1, OpEq, parseAnything());
			case TNotEquals: advance(); return binop(e1, OpNotEq, parseAnything());
			case TLessThan: advance(); return binop(e1, OpLess, parseAnything());
			case TGreaterThan: advance(); return binop(e1, OpGreater, parseAnything());
			case TLessEquals: advance(); return binop(e1, OpLessEq, parseAnything());
			case TGreaterEquals: advance(); return binop(e1, OpGreaterEq, parseAnything());
			default: return e1;
		}
	}

	function binop(e1:ReferenceableValue, op:RvOp, e2:ReferenceableValue):ReferenceableValue {
		// Precedence: mul/div bind tighter than add/sub
		return switch [e2, op] {
			case [EBinop(op2 = OpAdd | OpSub, e3, e4), OpMul | OpDiv | OpMod | OpIntegerDiv]:
				EBinop(op2, EBinop(op, e1, e3), e4);
			default:
				EBinop(op, e1, e2);
		}
	}

	function parseCallback():ReferenceableValue {
		expect(TOpen);
		final name = parseStringOrReference();
		var index:Null<ReferenceableValue> = null;
		if (match(TComma)) {
			index = parseIntegerOrReference();
		}
		expect(TClosed);
		var defaultValue:Null<ReferenceableValue> = null;
		if (match(TEquals)) {
			defaultValue = parseStringOrReference();
		}
		if (index != null) return RVCallbacksWithIndex(name, index, defaultValue);
		return RVCallbacks(name, defaultValue);
	}

	function parseFunction():ReferenceableValueFunction {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "gridwidth")):
				advance();
				expect(TClosed);
				return RVFGridWidth;
			case TIdentifier(s) if (isKeyword(s, "gridheight")):
				advance();
				expect(TClosed);
				return RVFGridHeight;
			default:
				return error("unknown function");
		}
	}

	// ===================== Color Parsing =====================

	function parseColorOrReference():ReferenceableValue {
		switch (peek()) {
			case TQuestion:
				advance();
				expect(TOpen);
				final cond = parseAnything();
				expect(TClosed);
				final ifTrue = parseColorOrReference();
				expect(TColon);
				final ifFalse = parseColorOrReference();
				return RVTernary(cond, ifTrue, ifFalse);
			case TIdentifier(s) if (isKeyword(s, "palette")):
				advance();
				expect(TOpen);
				var externalReference:Null<String> = null;
				switch (peek()) {
					case TIdentifier(s2) if (isKeyword(s2, "external")):
						advance();
						expect(TOpen);
						externalReference = expectIdentifierOrString();
						expect(TClosed);
						expect(TComma);
					default:
				}
				final paletteName = expectIdentifierOrString();
				expect(TComma);
				final index = parseIntegerOrReference();
				if (match(TComma)) {
					final row = parseIntegerOrReference();
					expect(TClosed);
					return RVColorXY(externalReference, paletteName, index, row);
				}
				expect(TClosed);
				return RVColor(externalReference, paletteName, index);
			default:
				final color = tryParseColor();
				if (color != null) return RVInteger(color);
				return parseIntegerOrReference();
		}
	}

	function tryParseColor():Null<Int> {
		switch (peek()) {
			case THexInteger(n):
				final c = tryStringToColor("0x" + n);
				if (c != null) { advance(); return c; }
				return null;
			case TName(s):
				final c = tryStringToColor("#" + s);
				if (c != null) { advance(); return c; }
				return null;
			case TIdentifier(s):
				final c = tryStringToColor(s);
				if (c != null) { advance(); return c; }
				return null;
			default:
				return null;
		}
	}

	public static function tryStringToColor(s:String):Null<Int> {
		if (s == null) return null;
		var color = switch (s.toLowerCase()) {
			case "maroon": 0x800000;
			case "red": 0xFF0000;
			case "orange": 0xFFA500;
			case "yellow": 0xFFFF00;
			case "olive": 0x808000;
			case "green": 0x008000;
			case "lime": 0x00FF00;
			case "purple": 0x800080;
			case "fuchsia": 0xFF00FF;
			case "teal": 0x008080;
			case "cyan" | "aqua": 0x00FFFF;
			case "blue": 0x0000FF;
			case "navy": 0x000080;
			case "black": 0x000000;
			case "gray": 0x808080;
			case "silver": 0xC0C0C0;
			case "white": 0xFFFFFF;
			default: null;
		}
		if (color != null) return color;
		if (s.startsWith("0x")) return Std.parseInt(s);
		if (s.startsWith("#")) {
			final colorStr = s.substring(1);
			final colorVal = Std.parseInt("0x" + colorStr);
			if (colorStr.length == 3 && colorVal != null) {
				var r = colorVal >> 8;
				var g = (colorVal & 0xF0) >> 4;
				var b = colorVal & 0xF;
				r |= r << 4;
				g |= g << 4;
				b |= b << 4;
				return (r << 16) | (g << 8) | b;
			}
			return colorVal;
		}
		return Std.parseInt(s);
	}

	// ===================== Coordinate Parsing =====================

	function parseXY():Coordinates {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "grid")):
				advance();
				expect(TOpen);
				final x = parseIntegerOrReference();
				expect(TComma);
				final y = parseIntegerOrReference();
				if (match(TComma)) {
					final ox = parseIntegerOrReference();
					expect(TComma);
					final oy = parseIntegerOrReference();
					expect(TClosed);
					return SELECTED_GRID_POSITION_WITH_OFFSET(x, y, ox, oy);
				}
				expect(TClosed);
				return SELECTED_GRID_POSITION(x, y);
			case TIdentifier(s) if (isKeyword(s, "hex")):
				advance();
				expect(TOpen);
				final q = parseInteger();
				expect(TComma);
				final r = parseInteger();
				expect(TComma);
				final sv = parseInteger();
				eatComma();
				expect(TClosed);
				if (q + r + sv != 0) error("q + r + s must be 0");
				return SELECTED_HEX_POSITION(new Hex(q, r, sv));
			case TIdentifier(s) if (isKeyword(s, "layout")):
				advance();
				expect(TOpen);
				final layoutName = expectIdentifierOrString();
				if (match(TComma)) {
					final index = parseIntegerOrReference();
					expect(TClosed);
					return LAYOUT(layoutName, index);
				}
				expect(TClosed);
				return LAYOUT(layoutName, null);
			case TIdentifier(s) if (isKeyword(s, "hexedge")):
				advance();
				expect(TOpen);
				final dir = parseIntegerOrReference();
				expect(TComma);
				final factor = parseFloatOrReference();
				expect(TClosed);
				return SELECTED_HEX_EDGE(dir, factor);
			case TIdentifier(s) if (isKeyword(s, "hexcorner")):
				advance();
				expect(TOpen);
				final dir = parseIntegerOrReference();
				expect(TComma);
				final factor = parseFloatOrReference();
				expect(TClosed);
				return SELECTED_HEX_CORNER(dir, factor);
			default:
				final x = parseIntegerOrReference();
				expect(TComma);
				final y = parseIntegerOrReference();
				return OFFSET(x, y);
		}
	}

	// ===================== Helpers =====================

	function parseInteger():Int {
		switch (peek()) {
			case TMinus:
				advance();
				switch (peek()) {
					case TInteger(n):
						advance();
						return -stringToInt(n);
					default:
						return error('expected integer');
				}
			case TInteger(n):
				advance();
				return stringToInt(n);
			case THexInteger(n):
				advance();
				return stringToInt("0x" + n);
			default:
				return error('expected integer, got ${peek()}');
		}
	}

	function parseFloat_():Float {
		var sign = 1.0;
		if (match(TMinus)) sign = -1.0;
		switch (peek()) {
			case TInteger(n) | TFloat(n):
				advance();
				return sign * stringToFloat(n);
			default:
				return error('expected number, got ${peek()}');
		}
	}

	function parseBool():Bool {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "yes") || isKeyword(s, "true")):
				advance();
				return true;
			case TIdentifier(s) if (isKeyword(s, "no") || isKeyword(s, "false")):
				advance();
				return false;
			case TInteger(s) if (s == "1"):
				advance();
				return true;
			case TInteger(s) if (s == "0"):
				advance();
				return false;
			default:
				return error("expected true/false, 0/1 or yes/no");
		}
	}

	function expectIdentifierOrString():String {
		switch (peek()) {
			case TIdentifier(s):
				advance();
				return s;
			case TQuotedString(s):
				advance();
				return s;
			default:
				return error('expected identifier or string, got ${peek()}');
		}
	}

	function expectReference():String {
		switch (peek()) {
			case TReference(s):
				advance();
				return s;
			default:
				return error('expected $$reference, got ${peek()}');
		}
	}

	function expectReferenceOrIdentifier():String {
		switch (peek()) {
			case TReference(s):
				advance();
				return s;
			case TIdentifier(s):
				advance();
				return s;
			default:
				return error('expected reference or identifier, got ${peek()}');
		}
	}

	// ===================== Tile Source =====================

	function parseTileSource():TileSource {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "file")):
				advance();
				expect(TOpen);
				final filename = parseStringOrReference();
				expect(TClosed);
				return TSFile(filename);
			case TIdentifier(s) if (isKeyword(s, "generated")):
				advance();
				expect(TOpen);
				final genType = parseGeneratedTileType();
				expect(TClosed);
				return TSGenerated(genType);
			case TIdentifier(s) if (isKeyword(s, "sheet")):
				advance();
				expect(TOpen);
				final sheet = parseStringOrReference();
				expect(TComma);
				final name = parseStringOrReference();
				if (match(TComma)) {
					final index = parseIntegerOrReference();
					expect(TClosed);
					return TSSheetWithIndex(sheet, name, index);
				}
				expect(TClosed);
				return TSSheet(sheet, name);
			case TReference(s):
				advance();
				validateRef(s);
				return TSReference(s);
			default:
				// bare sheetName, tileName [, index]
				final sheet = parseStringOrReference();
				expect(TComma);
				final name = parseStringOrReference();
				if (match(TComma)) {
					final index = parseIntegerOrReference();
					return TSSheetWithIndex(sheet, name, index);
				}
				return TSSheet(sheet, name);
		}
	}

	function parseGeneratedTileType():GeneratedTileType {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "cross")):
				advance();
				expect(TOpen);
				final w = parseIntegerOrReference();
				expect(TComma);
				final h = parseIntegerOrReference();
				var color:ReferenceableValue = RVInteger(0xFF0000);
				if (match(TComma)) color = parseColorOrReference();
				expect(TClosed);
				return Cross(w, h, color);
			case TIdentifier(s) if (isKeyword(s, "color")):
				advance();
				expect(TOpen);
				final w = parseIntegerOrReference();
				expect(TComma);
				final h = parseIntegerOrReference();
				var color:ReferenceableValue = RVInteger(0xFF0000);
				if (match(TComma)) color = parseColorOrReference();
				expect(TClosed);
				return SolidColor(w, h, color);
			case TIdentifier(s) if (isKeyword(s, "colorwithtext")):
				advance();
				expect(TOpen);
				final w = parseIntegerOrReference();
				expect(TComma);
				final h = parseIntegerOrReference();
				expect(TComma);
				final color = parseColorOrReference();
				expect(TComma);
				final text = parseAnything();
				expect(TComma);
				final textColor = parseColorOrReference();
				expect(TComma);
				final font = parseStringOrReference();
				expect(TClosed);
				return SolidColorWithText(w, h, color, text, textColor, font);
			case TIdentifier(s) if (isKeyword(s, "autotile")):
				advance();
				expect(TOpen);
				final name = parseStringOrReference();
				expect(TComma);
				final selector = parseAutotileTileSelector();
				expect(TClosed);
				return AutotileRef(name, selector);
			case TIdentifier(s) if (isKeyword(s, "autotileregionsheet")):
				advance();
				expect(TOpen);
				final name = parseStringOrReference();
				expect(TComma);
				final atScale = parseAnything();
				expect(TComma);
				final font = parseStringOrReference();
				expect(TComma);
				final fontColor = parseColorOrReference();
				expect(TClosed);
				return AutotileRegionSheet(name, atScale, font, fontColor);
			default:
				return error("unknown generated tile type");
		}
	}

	function parseAutotileTileSelector():AutotileTileSelector {
		// Try integer index first
		switch (peek()) {
			case TInteger(_), TReference(_):
				return ByIndex(parseIntegerOrReference());
			default:
				// TODO: ByEdges parsing if needed
				return ByIndex(parseIntegerOrReference());
		}
	}

	// ===================== Parameter Definitions =====================

	function parseDefines():{defs:ParametersDefinitions, order:Array<String>} {
		var defines:ParametersDefinitions = new Map();
		var order:Array<String> = [];
		if (match(TClosed)) return {defs: defines, order: order};
		while (true) {
			final def = parseDefine();
			if (defines.exists(def.name)) error('parameter ${def.name} already defined');
			defines.set(def.name, def);
			order.push(def.name);
			if (match(TClosed)) return {defs: defines, order: order};
			expect(TComma);
		}
	}

	function parseDefine():Definition {
		final paramName = expectIdentifierOrString();
		// Shorthand: name="default" (string type with default)
		if (match(TEquals)) {
			switch (peek()) {
				case TQuotedString(s):
					advance();
					return {name: paramName, type: PPTString, defaultValue: StringValue(s)};
				default:
			}
		}
		if (!match(TColon)) {
			return {name: paramName, type: PPTString, defaultValue: StringValue("")};
		}
		// Parse type
		final def:Definition = {name: paramName, type: PPTInt, defaultValue: null};
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "hexdirection")):
				advance();
				def.type = PPTHexDirection;
			case TIdentifier(s) if (isKeyword(s, "griddirection")):
				advance();
				def.type = PPTGridDirection;
			case TIdentifier(s) if (isKeyword(s, "int")):
				advance();
				def.type = PPTInt;
			case TIdentifier(s) if (isKeyword(s, "float")):
				advance();
				def.type = PPTFloat;
			case TIdentifier(s) if (isKeyword(s, "uint")):
				advance();
				def.type = PPTUnsignedInt;
			case TIdentifier(s) if (isKeyword(s, "bool")):
				advance();
				def.type = PPTBool;
			case TIdentifier(s) if (isKeyword(s, "string")):
				advance();
				def.type = PPTString;
				def.defaultValue = StringValue("");
			case TIdentifier(s) if (isKeyword(s, "color")):
				advance();
				def.type = PPTColor;
			case TIdentifier(s) if (isKeyword(s, "array")):
				advance();
				def.type = PPTArray;
			case TIdentifier(s) if (isKeyword(s, "flags")):
				advance();
				expect(TOpen);
				final bits = parseInteger();
				expect(TClosed);
				def.type = PPTFlags(bits);
			case TBracketOpen:
				advance();
				var enumNames:Array<String> = [];
				var lastWasComma = true; // start true to allow first value
				while (true) {
					switch (peek()) {
						case TBracketClosed:
							advance();
							break;
						case TComma:
							if (lastWasComma) error("double comma in enum definition");
							advance();
							lastWasComma = true;
						case TIdentifier(s):
							advance();
							if (enumNames.indexOf(s) >= 0) error('enum value "$s" already defined');
							enumNames.push(s);
							lastWasComma = false;
						case TQuotedString(s):
							advance();
							if (enumNames.indexOf(s) >= 0) error('enum value "$s" already defined');
							enumNames.push(s);
							lastWasComma = false;
						case TInteger(s) | TFloat(s):
							advance();
							if (enumNames.indexOf(s) >= 0) error('enum value "$s" already defined');
							enumNames.push(s);
							lastWasComma = false;
						default:
							error('unexpected token in enum definition: ${peek()}');
					}
				}
				def.type = PPTEnum(enumNames);
			case TInteger(_) | TMinus:
				// Range: from..to
				final from = parseInteger();
				expect(TDoubleDot);
				final to = parseInteger();
				def.type = PPTRange(from, to);
			default:
				error('unknown parameter type: ${peek()}');
		}
		// Default value
		parseDefaultParameterValue(def);
		return def;
	}

	function parseDefaultParameterValue(param:Definition):Void {
		if (!match(TEquals)) return;
		switch (param.type) {
			case PPTColor:
				final c = tryParseColor();
				if (c != null) { param.defaultValue = Value(c); return; }
				param.defaultValue = Value(parseInteger());
			case PPTArray:
				param.defaultValue = ArrayString(parseStringArray());
			default:
				var s:String = null;
				switch (peek()) {
					case TIdentifier(str):
						advance();
						s = str;
					case TQuotedString(str):
						advance();
						s = str;
					case THexInteger(str):
						advance();
						s = '0x' + str;
					case TMinus:
						advance();
						switch (peek()) {
							case TInteger(n) | TFloat(n):
								advance();
								s = '-' + n;
							default: error("expected number after minus");
						}
					case TInteger(n) | TFloat(n):
						advance();
						s = n;
					default:
						error('unexpected default value: ${peek()}');
				}
				param.defaultValue = dynamicValueToIndex(param.name, param.type, s);
		}
	}

	function dynamicValueToIndex(name:String, type:DefinitionType, value:String):ResolvedIndexParameters {
		return switch (type) {
			case PPTEnum(values):
				if (!values.contains(value)) error('enum "$name" does not contain value "$value"');
				Index(values.indexOf(value), value);
			case PPTRange(from, to):
				final n = Std.parseInt(value);
				if (n == null) error('expected integer for range default');
				Value(n);
			case PPTInt | PPTUnsignedInt:
				final n = Std.parseInt(value);
				if (n == null) error('expected integer for default');
				Value(n);
			case PPTFloat:
				final f = Std.parseFloat(value);
				if (Math.isNaN(f)) error('expected float for default');
				ValueF(f);
			case PPTBool:
				switch (value.toLowerCase()) {
					case "true" | "yes" | "1": Value(1);
					case "false" | "no" | "0": Value(0);
					default: error('invalid bool default: $value');
				}
			case PPTString: StringValue(value);
			case PPTColor:
				final c = tryStringToColor(value);
				if (c != null) Value(c) else Value(Std.parseInt(value));
			case PPTHexDirection | PPTGridDirection:
				final n = Std.parseInt(value);
				if (n == null) error('expected integer for default');
				Value(n);
			case PPTFlags(bits):
				final n = Std.parseInt(value);
				if (n == null) error('expected integer for default');
				Flag(n);
			case PPTArray:
				error('array default requires bracket syntax: [val1, val2, ...]');
		}
	}

	function parseStringArray():Array<String> {
		expect(TBracketOpen);
		var arr:Array<String> = [];
		while (!match(TBracketClosed)) {
			if (arr.length > 0) expect(TComma);
			switch (peek()) {
				case TInteger(n) | TFloat(n):
					advance();
					arr.push(n);
				default:
					arr.push(expectIdentifierOrString());
			}
		}
		return arr;
	}

	// ===================== Conditional Parsing =====================

	function parseConditionalParameters(defs:ParametersDefinitions):Map<String, ConditionalValues> {
		var result:Map<String, ConditionalValues> = new Map();
		while (true) {
			if (match(TClosed)) return result;
			if (result.keys().hasNext()) expect(TComma);

			final paramName = expectIdentifierOrString();

			// Validate parameter
			if (!defs.exists(paramName)) error('conditional parameter "$paramName" does not have definition');
			if (result.exists(paramName)) error('conditional parameter "$paramName" already defined');

			// Check for comparison operators
			switch (peek()) {
				case TGreaterEquals:
					advance();
					final val = parseAnything();
					result.set(paramName, CoRange(resolveToFloat(val), null, false, false));
				case TLessEquals:
					advance();
					final val = parseAnything();
					result.set(paramName, CoRange(null, resolveToFloat(val), false, false));
				case TGreaterThan:
					advance();
					final val = parseAnything();
					result.set(paramName, CoRange(resolveToFloat(val), null, true, false));
				case TLessThan:
					advance();
					final val = parseAnything();
					result.set(paramName, CoRange(null, resolveToFloat(val), false, true));
				case TNotEquals:
					advance();
					// Negated match
					switch (peek()) {
						case TBracketOpen:
							advance();
							var enums:Array<String> = [];
							while (!match(TBracketClosed)) {
								if (enums.length > 0) eatComma();
								enums.push(expectIdentifierOrString());
							}
							result.set(paramName, CoNot(CoEnums(enums)));
						default:
							final val = expectIdentifierOrString();
							final paramDef = defs.get(paramName);
							if (paramDef != null) {
								final cv = stringToConditional(val, paramDef.type);
								result.set(paramName, CoNot(cv));
							} else {
								result.set(paramName, CoNot(CoStringValue(val)));
							}
					}
				case TArrow:
					advance();
					// Match
					switch (peek()) {
						case TStar:
							advance();
							result.set(paramName, CoAny);
						case TBracketOpen:
							advance();
							var enums:Array<String> = [];
							while (!match(TBracketClosed)) {
								if (enums.length > 0) eatComma();
								enums.push(expectIdentifierOrString());
							}
							result.set(paramName, CoEnums(enums));
						case TExclamation:
							// Backward compat: @(param => !value) negate syntax
							advance();
							final val = expectIdentifierOrString();
							final paramDef = defs.get(paramName);
							if (paramDef != null) {
								final cv = stringToConditional(val, paramDef.type);
								result.set(paramName, CoNot(cv));
							} else {
								result.set(paramName, CoNot(CoStringValue(val)));
							}
						default:
							// Check for backward compat keywords
							switch (peek()) {
								case TIdentifier(s) if (isKeyword(s, "greaterthanorequal")):
									advance();
									final val = parseAnything();
									result.set(paramName, CoRange(resolveToFloat(val), null, false, false));
								case TIdentifier(s) if (isKeyword(s, "lessthanorequal")):
									advance();
									final val = parseAnything();
									result.set(paramName, CoRange(null, resolveToFloat(val), false, false));
								case TIdentifier(s) if (isKeyword(s, "bit")):
									advance();
									expect(TBracketOpen);
									final bitIndex = parseInteger();
									expect(TBracketClosed);
									result.set(paramName, CoFlag(1 << bitIndex));
								case TIdentifier(s) if (isKeyword(s, "between")):
									advance();
									final from = parseConditionalValue();
									expect(TDoubleDot);
									final to = parseConditionalValue();
									final fromF = resolveCondToFloat(from);
									final toF = resolveCondToFloat(to);
									result.set(paramName, CoRange(fromF, toF, false, false));
								default:
									// Could be a range: from..to
									final val = parseConditionalValue();
									// Check for range
									if (match(TDoubleDot)) {
										final to = parseConditionalValue();
										final fromF = resolveCondToFloat(val);
										final toF = resolveCondToFloat(to);
										result.set(paramName, CoRange(fromF, toF, false, false));
									} else {
										final paramDef = defs.get(paramName);
										if (paramDef != null) {
											final cv = stringToConditional(val, paramDef.type);
											result.set(paramName, cv);
										} else {
											result.set(paramName, CoStringValue(val));
										}
									}
							}
					}
				default:
					error('expected =>, !=, >=, <=, > or < after parameter name');
			}
		}
	}

	function parseConditionalValue():String {
		switch (peek()) {
			case TMinus:
				advance();
				switch (peek()) {
					case TInteger(n):
						advance();
						return '-$n';
					case TFloat(n):
						advance();
						return '-$n';
					default:
						return error("expected number after minus");
				}
			case TInteger(n) | TFloat(n):
				advance();
				return n;
			case THexInteger(n):
				advance();
				return '0x$n';
			case TIdentifier(s):
				advance();
				return s;
			case TQuotedString(s):
				advance();
				return s;
			default:
				return error('expected conditional value, got ${peek()}');
		}
	}

	function stringToConditional(val:String, type:DefinitionType):ConditionalValues {
		return switch (type) {
			case PPTEnum(values):
				if (values.contains(val))
					CoIndex(values.indexOf(val), val);
				else
					CoStringValue(val);
			case PPTBool:
				switch (val.toLowerCase()) {
					case "true" | "yes" | "1": CoValue(1);
					case "false" | "no" | "0": CoValue(0);
					default: CoStringValue(val);
				}
			case PPTFlags(bits):
				final n = Std.parseInt(val);
				if (n != null) CoFlag(n) else CoStringValue(val);
			case PPTColor:
				final c = tryStringToColor(val);
				if (c != null) CoValue(c) else CoValue(Std.parseInt(val));
			default:
				final n = Std.parseInt(val);
				if (n != null) CoValue(n) else CoStringValue(val);
		}
	}

	function resolveToFloat(rv:ReferenceableValue):Null<Float> {
		return switch (rv) {
			case RVInteger(i): i;
			case RVFloat(f): f;
			default: 0;
		}
	}

	function resolveCondToFloat(s:String):Null<Float> {
		final f = Std.parseFloat(s);
		if (!Math.isNaN(f)) return f;
		return 0;
	}

	// ===================== Blend Mode =====================

	function tryParseBlendMode():Null<MacroBlendMode> {
		switch (peek()) {
			case TIdentifier(s):
				final bm = switch (s.toLowerCase()) {
					case "none": MBNone;
					case "alpha": MBAlpha;
					case "add": MBAdd;
					case "alphaadd": MBAlphaAdd;
					case "softadd": MBSoftAdd;
					case "multiply": MBMultiply;
					case "alphamultiply": MBAlphaMultiply;
					case "erase": MBErase;
					case "screen": MBScreen;
					case "sub": MBSub;
					case "max": MBMax;
					case "min": MBMin;
					default: null;
				}
				if (bm != null) { advance(); return bm; }
				return null;
			default: return null;
		}
	}

	// ===================== HAlign / VAlign =====================

	function parseHAlign():Null<HorizontalAlign> {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "left")): advance(); return Left;
			case TIdentifier(s) if (isKeyword(s, "right")): advance(); return Right;
			case TIdentifier(s) if (isKeyword(s, "center")): advance(); return Center;
			default: return null;
		}
	}

	function parseVAlign():Null<VerticalAlign> {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "top")): advance(); return Top;
			case TIdentifier(s) if (isKeyword(s, "bottom")): advance(); return Bottom;
			case TIdentifier(s) if (isKeyword(s, "center")): advance(); return Center;
			default: return null;
		}
	}

	// ===================== Filter =====================

	function parseFilter():FilterType {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "none")):
				advance();
				return FilterNone;
			case TIdentifier(s) if (isKeyword(s, "group")):
				advance();
				expect(TOpen);
				var filters:Array<FilterType> = [];
				while (!match(TClosed)) {
					if (filters.length > 0) eatComma();
					filters.push(parseFilter());
				}
				return FilterGroup(filters);
			case TIdentifier(s) if (isKeyword(s, "outline")):
				advance();
				expect(TOpen);
				if (isNamedParamNext()) {
					final results = parseOptionalParams([
						ParseFloatOrReference("size"),
						ParseCustom("color", parseColorOrReference),
					]);
					return FilterOutline(
						cast results.get("size") ?? RVFloat(1.),
						cast results.get("color") ?? RVInteger(0xFF000000)
					);
				}
				final size = parseFloatOrReference();
				expect(TComma);
				final color = parseColorOrReference();
				expect(TClosed);
				return FilterOutline(size, color);
			case TIdentifier(s) if (isKeyword(s, "saturate")):
				advance();
				expect(TOpen);
				if (isNamedParamNext()) {
					final results = parseOptionalParams([
						ParseFloatOrReference("value"),
					]);
					return FilterSaturate(cast results.get("value") ?? RVFloat(1.));
				}
				final value = parseFloatOrReference();
				expect(TClosed);
				return FilterSaturate(value);
			case TIdentifier(s) if (isKeyword(s, "brightness")):
				advance();
				expect(TOpen);
				if (isNamedParamNext()) {
					final results = parseOptionalParams([
						ParseFloatOrReference("value"),
					]);
					return FilterBrightness(cast results.get("value") ?? RVFloat(1.));
				}
				final value = parseFloatOrReference();
				expect(TClosed);
				return FilterBrightness(value);
			case TIdentifier(s) if (isKeyword(s, "blur")):
				advance();
				expect(TOpen);
				if (isNamedParamNext()) {
					final results = parseOptionalParams([
						ParseFloatOrReference("radius"),
						ParseFloatOrReference("gain"),
						ParseFloatOrReference("quality"),
						ParseFloatOrReference("linear"),
					]);
					return FilterBlur(
						cast results.get("radius") ?? RVFloat(1.),
						cast results.get("gain") ?? RVFloat(1.),
						cast results.get("quality") ?? RVFloat(1.),
						cast results.get("linear") ?? RVFloat(0.)
					);
				}
				final radius = parseFloatOrReference();
				expect(TComma);
				final gain = parseFloatOrReference();
				var quality = RVFloat(1.);
				var linear = RVFloat(0.);
				if (match(TComma)) {
					quality = parseFloatOrReference();
					if (match(TComma)) linear = parseFloatOrReference();
				}
				expect(TClosed);
				return FilterBlur(radius, gain, quality, linear);
			case TIdentifier(s) if (isKeyword(s, "glow")):
				advance();
				expect(TOpen);
				if (isNamedParamNext()) {
					final results = parseOptionalParams([
						ParseFloatOrReference("alpha"),
						ParseFloatOrReference("radius"),
						ParseFloatOrReference("gain"),
						ParseFloatOrReference("quality"),
						ParseBool("smoothColor"),
						ParseBool("knockout"),
						ParseCustom("color", parseColorOrReference),
					]);
					return FilterGlow(
						cast results.get("color") ?? RVInteger(0xFFFFFF),
						cast results.get("alpha") ?? RVFloat(1.),
						cast results.get("radius") ?? RVFloat(1.),
						cast results.get("gain") ?? RVFloat(1.),
						cast results.get("quality") ?? RVFloat(1.),
						results.exists("smoothColor") ? cast(results.get("smoothColor"), Bool) : false,
						results.exists("knockout") ? cast(results.get("knockout"), Bool) : false
					);
				}
				final color = parseColorOrReference();
				expect(TComma);
				final alpha = parseFloatOrReference();
				expect(TComma);
				final radius = parseFloatOrReference();
				var gain = RVFloat(1.);
				var quality = RVFloat(1.);
				var smoothColor = false;
				var knockout = false;
				if (match(TComma)) gain = parseFloatOrReference();
				if (match(TComma)) quality = parseFloatOrReference();
				expect(TClosed);
				return FilterGlow(color, alpha, radius, gain, quality, smoothColor, knockout);
			case TIdentifier(s) if (isKeyword(s, "dropshadow")):
				advance();
				expect(TOpen);
				if (isNamedParamNext()) {
					final results = parseOptionalParams([
						ParseFloatOrReference("distance"),
						ParseFloatOrReference("angle"),
						ParseFloatOrReference("alpha"),
						ParseFloatOrReference("radius"),
						ParseCustom("color", parseColorOrReference),
						ParseFloatOrReference("gain"),
						ParseFloatOrReference("quality"),
						ParseBool("smoothColor"),
					]);
					return FilterDropShadow(
						cast results.get("distance") ?? RVFloat(1.),
						cast results.get("angle") ?? RVFloat(0.785),
						cast results.get("color") ?? RVInteger(0),
						cast results.get("alpha") ?? RVFloat(1.),
						cast results.get("radius") ?? RVFloat(1.),
						cast results.get("gain") ?? RVFloat(1.),
						cast results.get("quality") ?? RVFloat(1.),
						results.exists("smoothColor") ? cast(results.get("smoothColor"), Bool) : false
					);
				}
				final distance = parseFloatOrReference();
				expect(TComma);
				final angle = parseFloatOrReference();
				expect(TComma);
				final color = parseColorOrReference();
				expect(TComma);
				final alpha = parseFloatOrReference();
				var radius = RVFloat(1.);
				var gain = RVFloat(1.);
				var quality = RVFloat(1.);
				var smoothColor = false;
				if (match(TComma)) radius = parseFloatOrReference();
				if (match(TComma)) gain = parseFloatOrReference();
				if (match(TComma)) quality = parseFloatOrReference();
				expect(TClosed);
				return FilterDropShadow(distance, angle, color, alpha, radius, gain, quality, smoothColor);
			case TIdentifier(s) if (isKeyword(s, "pixeloutline")):
				advance();
				expect(TOpen);
				var mode:PixelOutlineModeDef;
				switch (peek()) {
					case TIdentifier(s2) if (isKeyword(s2, "knockout")):
						advance();
						expect(TComma);
						final color = parseColorOrReference();
						expect(TComma);
						final knockoutVal = parseFloatOrReference();
						mode = POKnockout(color, knockoutVal);
					case TIdentifier(s2) if (isKeyword(s2, "inlinecolor")):
						advance();
						expect(TComma);
						final color = parseColorOrReference();
						expect(TComma);
						final inlineColor = parseColorOrReference();
						mode = POInlineColor(color, inlineColor);
					default:
						return error("expected knockout or inlineColor in pixelOutline");
				}
				var smoothColor = false;
				if (match(TComma)) {
					switch (peek()) {
						case TIdentifier(s2) if (isKeyword(s2, "smoothcolor")):
							advance();
							smoothColor = true;
						default:
					}
				}
				expect(TClosed);
				return FilterPixelOutline(mode, smoothColor);
			case TIdentifier(s) if (isKeyword(s, "replacepalette")):
				advance();
				expect(TOpen);
				final paletteName = expectIdentifierOrString();
				expect(TComma);
				final sourceRow = parseIntegerOrReference();
				expect(TComma);
				final replacementRow = parseIntegerOrReference();
				expect(TClosed);
				return FilterPaletteReplace(paletteName, sourceRow, replacementRow);
			case TIdentifier(s) if (isKeyword(s, "replacecolor")):
				advance();
				expect(TOpen);
				expect(TBracketOpen);
				final sources = parseColorsList(TBracketClosed);
				eatComma();
				expect(TBracketOpen);
				final replacements = parseColorsList(TBracketClosed);
				expect(TClosed);
				return FilterColorListReplace(sources, replacements);
			default:
				return error('unknown filter type: ${peek()}');
		}
	}

	function parseColorsList(endToken:MacroTokenType):Array<ReferenceableValue> {
		var colors:Array<ReferenceableValue> = [];
		while (true) {
			eatComma();
			if (Type.enumEq(peek(), endToken)) {
				advance();
				break;
			}
			colors.push(parseColorOrReference());
		}
		return colors;
	}

	function isNamedParamNext():Bool {
		switch (peek()) {
			case TIdentifier(_):
				// Save position to peek ahead
				final saved = tpos;
				advance();
				final isColon = Type.enumEq(peek(), TColon);
				tpos = saved; // restore
				return isColon;
			default: return false;
		}
	}

	function parseNamedFloatParam(name:String, defaultVal:ReferenceableValue):ReferenceableValue {
		// Try to parse named params in any order
		return defaultVal; // Simplified - full impl would scan all named params
	}

	function parseNamedColorParam(name:String, defaultVal:ReferenceableValue):ReferenceableValue {
		return defaultVal;
	}

	// ===================== Layout Content =====================

	function parseLayoutContent():Null<LayoutContent> {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "point")):
				advance();
				expect(TColon);
				final xy = parseXY();
				return LayoutPoint(xy);
			default:
				return null;
		}
	}

	// ===================== Layouts Parsing =====================

	function parseLayouts():LayoutsDef {
		var layouts:LayoutsDef = new Map();
		var offsets:Array<bh.base.Point> = [new bh.base.Point(0, 0)];
		var currentGrid:Null<GridCoordinateSystem> = null;
		var currentHex:Null<HexCoordinateSystem> = null;

		while (true) {
			switch (peek()) {
				case TIdentifier(s) if (isKeyword(s, "grid")):
					advance();
					expect(TColon);
					final spacingX = parseInteger();
					expect(TComma);
					final spacingY = parseInteger();
					eatSemicolon();
					expect(TCurlyOpen);
					currentGrid = {spacingX: spacingX, spacingY: spacingY};
					currentHex = null;
					parseLayoutEntries(layouts, offsets, currentGrid, currentHex);
					currentGrid = null;
				case TIdentifier(s) if (isKeyword(s, "hexgrid")):
					advance();
					expect(TColon);
					final orientation = parseHexOrientation();
					expect(TOpen);
					final w = parseFloat_();
					expect(TComma);
					final h = parseFloat_();
					expect(TClosed);
					eatSemicolon();
					expect(TCurlyOpen);
					currentHex = {hexLayout: HexLayout.createFromFloats(orientation, w, h)};
					currentGrid = null;
					parseLayoutEntries(layouts, offsets, currentGrid, currentHex);
					currentHex = null;
				case TIdentifier(s) if (isKeyword(s, "offset")):
					advance();
					expect(TColon);
					final ox = parseInteger();
					expect(TComma);
					final oy = parseInteger();
					eatSemicolon();
					expect(TCurlyOpen);
					offsets.push(new bh.base.Point(ox, oy));
					parseLayoutEntries(layouts, offsets, currentGrid, currentHex);
					offsets.pop();
				case TName(_):
					parseLayoutEntry(layouts, offsets, currentGrid, currentHex);
				case TCurlyClosed:
					advance();
					return layouts;
				default:
					error('unexpected token in layouts: ${peek()}');
			}
		}
	}

	function parseHexOrientation():bh.base.Hex.HexOrientation {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "flat")):
				advance();
				return FLAT;
			case TIdentifier(s) if (isKeyword(s, "pointy")):
				advance();
				return POINTY;
			default:
				error("expected flat or pointy");
				return FLAT; // unreachable
		}
	}

	function parseLayoutEntries(layouts:LayoutsDef, offsets:Array<bh.base.Point>,
			grid:Null<GridCoordinateSystem>, hex:Null<HexCoordinateSystem>):Void {
		while (true) {
			switch (peek()) {
				case TName(_):
					parseLayoutEntry(layouts, offsets, grid, hex);
				case TIdentifier(s) if (isKeyword(s, "grid")):
					advance();
					expect(TColon);
					final spacingX = parseInteger();
					expect(TComma);
					final spacingY = parseInteger();
					eatSemicolon();
					expect(TCurlyOpen);
					final nestedGrid:GridCoordinateSystem = {spacingX: spacingX, spacingY: spacingY};
					parseLayoutEntries(layouts, offsets, nestedGrid, null);
				case TIdentifier(s) if (isKeyword(s, "hexgrid")):
					advance();
					expect(TColon);
					final orientation = parseHexOrientation();
					expect(TOpen);
					final w = parseFloat_();
					expect(TComma);
					final h = parseFloat_();
					expect(TClosed);
					eatSemicolon();
					expect(TCurlyOpen);
					final nestedHex:HexCoordinateSystem = {hexLayout: HexLayout.createFromFloats(orientation, w, h)};
					parseLayoutEntries(layouts, offsets, null, nestedHex);
				case TIdentifier(s) if (isKeyword(s, "offset")):
					advance();
					expect(TColon);
					final ox = parseInteger();
					expect(TComma);
					final oy = parseInteger();
					eatSemicolon();
					expect(TCurlyOpen);
					offsets.push(new bh.base.Point(ox, oy));
					parseLayoutEntries(layouts, offsets, grid, hex);
					offsets.pop();
				case TCurlyClosed:
					advance();
					return;
				default:
					error('unexpected token in layout entries: ${peek()}');
			}
		}
	}

	function parseLayoutEntry(layouts:LayoutsDef, offsets:Array<bh.base.Point>,
			grid:Null<GridCoordinateSystem>, hex:Null<HexCoordinateSystem>):Void {
		switch (peek()) {
			case TName(name):
				advance();
				// Try single point first
				final content = parseLayoutContent();
				if (content != null) {
					eatSemicolon();
					layouts.set(name, {name: name, type: Single(content), grid: grid, hex: hex, offset: foldOffsets(offsets)});
					return;
				}
				// sequence or list
				switch (peek()) {
					case TIdentifier(s) if (isKeyword(s, "sequence")):
						advance();
						expect(TOpen);
						final varName = expectReferenceOrIdentifier();
						expect(TColon);
						final from = parseInteger();
						expect(TDoubleDot);
						final to = parseInteger();
						expect(TClosed);
						final lc = parseLayoutContent();
						if (lc == null) error("layout content expected");
						eatSemicolon();
						layouts.set(name, {name: name, type: Sequence(varName, from, to, lc), grid: grid, hex: hex, offset: foldOffsets(offsets)});
					case TIdentifier(s) if (isKeyword(s, "list")):
						advance();
						expect(TCurlyOpen);
						var contentList:Array<LayoutContent> = [];
						while (true) {
							final lc = parseLayoutContent();
							if (lc != null) {
								eatSemicolon();
								contentList.push(lc);
							} else {
								break;
							}
						}
						expect(TCurlyClosed);
						layouts.set(name, {name: name, type: List(contentList), grid: grid, hex: hex, offset: foldOffsets(offsets)});
					default:
						error("expected sequence, list, or point");
				}
			default:
				error('expected layout name (#name), got ${peek()}');
		}
	}

	function foldOffsets(offsets:Array<bh.base.Point>):bh.base.Point {
		var x = 0;
		var y = 0;
		for (o in offsets) { x += o.x; y += o.y; }
		return new bh.base.Point(x, y);
	}

	// ===================== Node Parsing =====================

	function createNode(type:NodeType, parent:Null<Node>, conditional:NodeConditionalValues,
			scale:Null<ReferenceableValue>, alpha:Null<ReferenceableValue>, tint:Null<ReferenceableValue>,
			layerIndex:Int, updatableName:UpdatableNameType):Node {
		uniqueCounter++;
		final nameStr = switch (updatableName) {
			case UNTObject(n): n;
			case UNTUpdatable(n): n;
			case UNTIndexed(n, _): n;
		}
		return {
			pos: ZERO,
			scale: scale,
			alpha: alpha,
			tint: tint,
			layer: layerIndex,
			gridCoordinateSystem: null,
			hexCoordinateSystem: null,
			blendMode: null,
			filter: null,
			parent: parent,
			updatableName: updatableName,
			type: type,
			children: [],
			conditionals: conditional,
			uniqueNodeName: generateUniqueName(uniqueCounter, nameStr, Std.string(type)),
			settings: null,
			#if MULTIANIM_TRACE
			parserPos: posString()
			#end
		};
	}

	function parseNode(updatableName:UpdatableNameType, parent:Null<Node>, currentDefs:ParametersDefinitions):Node {
		// Reset reference validation scope for each root-level node
		if (parent == null) { activeDefs = null; scopeVars = null; }
		var layerIndex = -1;
		var alpha:Null<ReferenceableValue> = null;
		var scale:Null<ReferenceableValue> = null;
		var tint:Null<ReferenceableValue> = null;
		var conditional:NodeConditionalValues = NoConditional;

		// Parse @ prefix (conditionals, layer, alpha, scale, tint)
		if (match(TAt)) {
			var atCount = 0;
			while (true) {
				switch (peek()) {
					case TIdentifier(s) if (isKeyword(s, "if")):
						advance();
						expect(TOpen);
						conditional = Conditional(parseConditionalParameters(currentDefs), false);
						atCount++;
					case TIdentifier(s) if (isKeyword(s, "ifstrict")):
						advance();
						expect(TOpen);
						conditional = Conditional(parseConditionalParameters(currentDefs), true);
						atCount++;
					case TOpen:
						advance();
						conditional = Conditional(parseConditionalParameters(currentDefs), false);
						atCount++;
					case TIdentifier(s) if (isKeyword(s, "layer")):
						advance();
						expect(TOpen);
						layerIndex = parseInteger();
						expect(TClosed);
						atCount++;
					case TIdentifier(s) if (isKeyword(s, "alpha")):
						advance();
						expect(TOpen);
						alpha = parseFloatOrReference();
						expect(TClosed);
						atCount++;
					case TIdentifier(s) if (isKeyword(s, "tint")):
						advance();
						expect(TOpen);
						tint = parseColorOrReference();
						expect(TClosed);
						atCount++;
					case TIdentifier(s) if (isKeyword(s, "scale")):
						advance();
						expect(TOpen);
						scale = parseFloatOrReference();
						expect(TClosed);
						atCount++;
					case TIdentifier(s) if (isKeyword(s, "else")):
						advance();
						if (match(TOpen)) {
							conditional = ConditionalElse(parseConditionalParameters(currentDefs));
						} else {
							conditional = ConditionalElse(null);
						}
						atCount++;
					case TIdentifier(s) if (isKeyword(s, "default")):
						advance();
						conditional = ConditionalDefault;
						atCount++;
					case TIdentifier(s) if (isKeyword(s, "final")):
						advance();
						final name = expectIdentifierOrString();
						expect(TEquals);
						final expr = parseAnything();
						if (scopeVars != null) scopeVars.push(name);
						return createNode(FINAL_VAR(name, expr), parent, NoConditional, null, null, null, -1, UNTObject(name));
					case TAt:
						advance(); // allow @alpha(0.5) @scale(0.25) chaining
					default:
						break;
				}
			}
			if (atCount == 0) error("expected conditional or inline property after @");
		}

		// Validate @else/@default
		switch (conditional) {
			case ConditionalElse(_) | ConditionalDefault:
				if (parent == null) error("@else/@default cannot be used on root elements");
				if (parent.children.length == 0) error("@else/@default requires a preceding sibling with a @() conditional");
				switch (parent.children[parent.children.length - 1].conditionals) {
					case NoConditional: error("@else/@default: previous sibling has no conditional");
					default:
				}
			default:
		}

		// Parse node type
		final node:Node = switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "bitmap")):
				advance();
				expect(TOpen);
				final ts = parseTileSource();
				var hAlign:HorizontalAlign = Left;
				var vAlign:VerticalAlign = Top;
				if (match(TComma)) {
					final h = parseHAlign();
					if (h != null) {
						hAlign = h;
						if (match(TComma)) {
							final v = parseVAlign();
							if (v != null) vAlign = v;
						} else if (hAlign == Center) vAlign = Center;
					}
				}
				expect(TClosed);
				createNode(BITMAP(ts, hAlign, vAlign), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "ninepatch")):
				advance();
				expect(TOpen);
				final sheet = expectIdentifierOrString();
				expect(TComma);
				final tilename = expectIdentifierOrString();
				expect(TComma);
				final width = parseIntegerOrReference();
				expect(TComma);
				final height = parseIntegerOrReference();
				expect(TClosed);
				createNode(NINEPATCH(sheet, tilename, width, height), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "text")):
				advance();
				expect(TOpen);
				final fontname = parseStringOrReference();
				expect(TComma);
				final text = parseStringOrReference();
				expect(TComma);
				final color = parseColorOrReference();
				var halign:Null<HorizontalAlign> = null;
				var textAlignWidth:TextAlignWidth = TAWAuto;
				var letterSpacing:Float = 0.;
				var lineSpacing:Float = 0.;
				var lineBreak:Bool = true;
				var isHtml:Bool = false;
				var dropShadowXY:Null<bh.base.FPoint> = null;
				var dropShadowColor:Int = 0;
				var dropShadowAlpha:Float = 0.5;
				if (match(TComma)) {
					halign = parseHAlign();
					if (halign != null && match(TComma)) {
						// Check for grid or maxWidth
						switch (peek()) {
							case TIdentifier(gs) if (isKeyword(gs, "grid")):
								advance();
								textAlignWidth = TAWGrid;
							default:
								final mw = tryParseIntValue();
								if (mw != null) textAlignWidth = TAWValue(mw);
						}
					}
				}
				// Parse remaining optional named params until )
				while (true) {
					if (match(TClosed)) break;
					eatComma();
					if (match(TClosed)) break;
					if (isNamedParamNext()) {
						final pname = expectIdentifierOrString();
						expect(TColon);
						switch (pname.toLowerCase()) {
							case "letterspacing": letterSpacing = parseFloat_();
							case "linespacing": lineSpacing = parseFloat_();
							case "linebreak": lineBreak = parseBool();
							case "html": isHtml = parseBool();
							case "dropshadowxy":
								final dx = parseFloat_();
								expect(TComma);
								final dy = parseFloat_();
								dropShadowXY = {x: dx, y: dy};
							case "dropshadowcolor":
								final c = tryParseColor();
								if (c != null) dropShadowColor = c;
								else error("expected color value for dropShadowColor");
							case "dropshadowalpha": dropShadowAlpha = parseFloat_();
							default: error('unknown text param: $pname');
						}
					} else break;
				}
				final textDef:TextDef = {
					fontName: fontname, text: text, color: color, halign: halign,
					textAlignWidth: textAlignWidth, letterSpacing: letterSpacing, lineSpacing: lineSpacing,
					lineBreak: lineBreak, dropShadowXY: dropShadowXY, dropShadowColor: dropShadowColor, dropShadowAlpha: dropShadowAlpha,
					isHtml: isHtml
				};
				createNode(TEXT(textDef), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "apply")):
				advance();
				createNode(APPLY, parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "point")):
				advance();
				if (match(TOpen)) expect(TClosed);
				createNode(POINT, parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "layers")):
				advance();
				if (match(TOpen)) expect(TClosed);
				createNode(LAYERS, parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "mask")):
				advance();
				expect(TOpen);
				final w = parseIntegerOrReference();
				expect(TComma);
				final h = parseIntegerOrReference();
				expect(TClosed);
				createNode(MASK(w, h), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "spacer")):
				advance();
				expect(TOpen);
				final spacerW = parseIntegerOrReference();
				expect(TComma);
				final spacerH = parseIntegerOrReference();
				expect(TClosed);
				createNode(SPACER(spacerW, spacerH), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "slot")):
				advance();
				if (updatableName == null)
					error("slot requires a #name prefix");
				createNode(SLOT, parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "interactive")):
				advance();
				expect(TOpen);
				final w = parseIntegerOrReference();
				expect(TComma);
				final h = parseIntegerOrReference();
				expect(TComma);
				final id = parseStringOrReference();
				var debug = false;
				var metadata:Null<Array<{key:ReferenceableValue, type:SettingValueType, value:ReferenceableValue}>> = null;
				if (match(TComma)) {
					switch (peek()) {
						case TIdentifier(d) if (isKeyword(d, "debug")):
							advance();
							debug = true;
							if (match(TComma)) {
								metadata = parseInteractiveMetadata();
							}
						default:
							metadata = parseInteractiveMetadata();
					}
				}
				expect(TClosed);
				createNode(INTERACTIVE(w, h, id, debug, metadata), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "flow")):
				advance();
				expect(TOpen);
				// Parse named optional params
				var maxWidth:Null<ReferenceableValue> = null;
				var maxHeight:Null<ReferenceableValue> = null;
				var minWidth:Null<ReferenceableValue> = null;
				var minHeight:Null<ReferenceableValue> = null;
				var lineHeight:Null<ReferenceableValue> = null;
				var colWidth:Null<ReferenceableValue> = null;
				var layout:Null<MacroFlowLayout> = null;
				var paddingLeft:Null<ReferenceableValue> = null;
				var paddingRight:Null<ReferenceableValue> = null;
				var paddingTop:Null<ReferenceableValue> = null;
				var paddingBottom:Null<ReferenceableValue> = null;
				var hSpacing:Null<ReferenceableValue> = null;
				var vSpacing:Null<ReferenceableValue> = null;
				var debug = false;
				var multiline = false;
				var bgSheet:Null<ReferenceableValue> = null;
				var bgTile:Null<ReferenceableValue> = null;
				var overflow:Null<MacroFlowOverflow> = null;
				var fillWidth = false;
				var fillHeight = false;
				var reverse = false;
				while (!match(TClosed)) {
					eatComma();
					if (match(TClosed)) break;
					if (!isNamedParamNext()) { eatComma(); continue; }
					final pname = expectIdentifierOrString();
					expect(TColon);
					switch (pname.toLowerCase()) {
						case "maxwidth": maxWidth = parseIntegerOrReference();
						case "maxheight": maxHeight = parseIntegerOrReference();
						case "minwidth": minWidth = parseIntegerOrReference();
						case "minheight": minHeight = parseIntegerOrReference();
						case "lineheight": lineHeight = parseIntegerOrReference();
						case "colwidth": colWidth = parseIntegerOrReference();
						case "layout": layout = parseFlowOrientation();
						case "paddingleft": paddingLeft = parseIntegerOrReference();
						case "paddingright": paddingRight = parseIntegerOrReference();
						case "paddingtop": paddingTop = parseIntegerOrReference();
						case "paddingbottom": paddingBottom = parseIntegerOrReference();
						case "horizontalspacing": hSpacing = parseIntegerOrReference();
						case "verticalspacing": vSpacing = parseIntegerOrReference();
						case "padding":
							final p = parseIntegerOrReference();
							paddingLeft = p; paddingRight = p; paddingTop = p; paddingBottom = p;
						case "debug": debug = parseBool();
						case "multiline": multiline = parseBool();
						case "background":
							expectKeyword("ninepatch");
							expect(TOpen);
							bgSheet = parseStringOrReference();
							expect(TComma);
							bgTile = parseStringOrReference();
							expect(TClosed);
						case "overflow": overflow = parseFlowOverflow();
						case "fillwidth": fillWidth = parseBool();
						case "fillheight": fillHeight = parseBool();
						case "reverse": reverse = parseBool();
						default: error('unknown flow param: $pname');
					}
				}
				createNode(FLOW(maxWidth, maxHeight, minWidth, minHeight, lineHeight, colWidth, layout, paddingTop, paddingBottom, paddingLeft, paddingRight, hSpacing, vSpacing, debug, multiline, bgSheet, bgTile, overflow, fillWidth, fillHeight, reverse), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "programmable")):
				advance();
				// Check for tilegroup
				var isTileGroup = false;
				switch (peek()) {
					case TIdentifier(s2) if (isKeyword(s2, "tilegroup")):
						advance();
						isTileGroup = true;
					default:
				}
				expect(TOpen);
				final parsed = parseDefines();
				currentDefs = parsed.defs;
				activeDefs = parsed.defs;
				scopeVars = [];
				createNode(PROGRAMMABLE(isTileGroup, parsed.defs, parsed.order), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "relativelayouts")):
				advance();
				expect(TCurlyOpen);
				final layoutsDef = parseLayouts();
				final n = createNode(RELATIVE_LAYOUTS(layoutsDef), parent, conditional, scale, alpha, tint, layerIndex, switch (updatableName) {
					case UNTObject(_): UNTObject(defaultLayoutNodeName);
					case UNTUpdatable(_): UNTUpdatable(defaultLayoutNodeName);
					case UNTIndexed(_, _): UNTObject(defaultLayoutNodeName);
				});
				return n; // skip position/children parsing

			case TIdentifier(s) if (isKeyword(s, "particles")):
				advance();
				expect(TCurlyOpen);
				final p = parseParticles();
				final n = createNode(PARTICLES(p), parent, conditional, scale, alpha, tint, layerIndex, updatableName);
				return n;

			case TIdentifier(s) if (isKeyword(s, "staticRef") || isKeyword(s, "reference")):
				advance();
				expect(TOpen);
				var extRef:Null<String> = null;
				switch (peek()) {
					case TIdentifier(s2) if (isKeyword(s2, "external")):
						advance();
						expect(TOpen);
						extRef = expectIdentifierOrString();
						expect(TClosed);
						expect(TComma);
					default:
				}
				final progRef = expectReferenceOrIdentifier();
				var params:Map<String, ReferenceableValue> = new Map();
				if (match(TComma)) {
					params = parseReferenceParams();
				}
				expect(TClosed);
				createNode(STATIC_REF(extRef, progRef, params), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "dynamicRef") || isKeyword(s, "component")):
				advance();
				expect(TOpen);
				var extRef:Null<String> = null;
				switch (peek()) {
					case TIdentifier(s2) if (isKeyword(s2, "external")):
						advance();
						expect(TOpen);
						extRef = expectIdentifierOrString();
						expect(TClosed);
						expect(TComma);
					default:
				}
				final progRef = expectReferenceOrIdentifier();
				var params:Map<String, ReferenceableValue> = new Map();
				if (match(TComma)) {
					params = parseReferenceParams();
				}
				expect(TClosed);
				createNode(DYNAMIC_REF(extRef, progRef, params), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "placeholder")):
				advance();
				expect(TOpen);
				final type = switch (peek()) {
					case TIdentifier(s2) if (isKeyword(s2, "error")): advance(); PHError;
					case TIdentifier(s2) if (isKeyword(s2, "nothing")): advance(); PHNothing;
					default: PHTileSource(parseTileSource());
				}
				expect(TComma);
				var source:PlaceholderReplacementSource = null;
				switch (peek()) {
					case TIdentifier(s2) if (isKeyword(s2, "callback")):
						advance();
						expect(TOpen);
						final name = parseStringOrReference();
						if (match(TComma)) {
							final idx = parseIntegerOrReference();
							expect(TClosed);
							source = PRSCallbackWithIndex(name, idx);
						} else {
							expect(TClosed);
							source = PRSCallback(name);
						}
					case TIdentifier(s2) if (isKeyword(s2, "builderparameter")):
						advance();
						expect(TOpen);
						final name = parseStringOrReference();
						expect(TClosed);
						source = PRSBuilderParameterSource(name);
					default:
						error("expected callback or builderParameter");
				}
				expect(TClosed);
				createNode(PLACEHOLDER(type, source), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "repeatable2d")):
				advance();
				expect(TOpen);
				final varNameX = expectReferenceOrIdentifier();
				expect(TComma);
				final varNameY = expectReferenceOrIdentifier();
				expect(TComma);
				final repeatTypeX = parseRepeatIterator(currentDefs);
				expect(TComma);
				final repeatTypeY = parseRepeatIterator(currentDefs);
				expect(TClosed);
				createNode(REPEAT2D(varNameX, varNameY, repeatTypeX, repeatTypeY), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "repeatable")):
				advance();
				expect(TOpen);
				final varName = expectReferenceOrIdentifier();
				expect(TComma);
				final repeatType = parseRepeatIterator(currentDefs);
				expect(TClosed);
				createNode(REPEAT(varName, repeatType), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "stateanim")):
				advance();
				// Check if construct variant (stateAnim construct(...))
				switch (peek()) {
					case TIdentifier(s2) if (isKeyword(s2, "construct")):
						advance();
						expect(TOpen);
						final initialState = parseStringOrReference();
						eatComma();
						final constructs = parseStateAnimConstruct();
						createNode(STATEANIM_CONSTRUCT(initialState, constructs), parent, conditional, scale, alpha, tint, layerIndex, updatableName);
					default:
						expect(TOpen);
						final filename = expectIdentifierOrString();
						expect(TComma);
						final initialState = parseStringOrReference();
						var selector:Map<String, ReferenceableValue> = new Map();
						while (match(TComma)) {
							final key = expectIdentifierOrString();
							expect(TArrow);
							final val = parseStringOrReference();
							selector.set(key, val);
						}
						expect(TClosed);
						createNode(STATEANIM(filename, initialState, selector), parent, conditional, scale, alpha, tint, layerIndex, updatableName);
				}

			case TIdentifier(s) if (isKeyword(s, "tilegroup")):
				advance();
				createNode(TILEGROUP, parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "graphics")):
				advance();
				expect(TOpen);
				final elements = parseGraphicsElements();
				createNode(GRAPHICS(elements), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "palette")):
				advance();
				if (currentName == null) error("palette requires a #name");
				if (parent != null) error("palette must be a root node");
				// Three forms: palette { colors }, palette(2d:width) { colors }, palette(file:filename)
				final paletteNode:Node = switch (peek()) {
					case TOpen:
						advance();
						switch (peek()) {
							case TIdentifier(s2) if (isKeyword(s2, "2d")):
								advance();
								expect(TColon);
								final width = parseInteger();
								expect(TClosed);
								expect(TCurlyOpen);
								final colors = parseColorsList(TCurlyClosed);
								createNode(PALETTE(PaletteColors2D(colors, width)), parent, conditional, scale, alpha, tint, layerIndex, updatableName);
							case TIdentifier(s2) if (isKeyword(s2, "file")):
								advance();
								expect(TColon);
								final filename = parseStringOrReference();
								expect(TClosed);
								createNode(PALETTE(PaletteImageFile(filename)), parent, conditional, scale, alpha, tint, layerIndex, updatableName);
							default:
								error("expected 2d or file in palette()");
						}
					case TCurlyOpen:
						advance();
						final colors = parseColorsList(TCurlyClosed);
						createNode(PALETTE(PaletteColors(colors)), parent, conditional, scale, alpha, tint, layerIndex, updatableName);
					default:
						error("expected { or ( after palette");
				};
				return paletteNode;

			case TIdentifier(s) if (isKeyword(s, "pixels")):
				advance();
				expect(TOpen);
				final shapes = parsePixelShapes();
				createNode(PIXELS(shapes), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "paths")):
				advance();
				if (currentName == null) currentName = "paths";
				if (parent != null) error("paths must be a root node");
				expect(TCurlyOpen);
				final pathsDef = parsePaths();
				final n = createNode(PATHS(pathsDef), parent, conditional, scale, alpha, tint, layerIndex, switch (updatableName) {
					case UNTObject(_): UNTObject(defaultPathNodeName);
					case UNTUpdatable(_): UNTUpdatable(defaultPathNodeName);
					case UNTIndexed(_, _): UNTObject(defaultPathNodeName);
				});
				return n;

			case TIdentifier(s) if (isKeyword(s, "animated_path") || isKeyword(s, "animatedPath") || isKeyword(s, "animatedpath")):
				advance();
				if (currentName == null) error("animated_path requires a #name");
				if (parent != null) error("animated_path must be a root node");
				expect(TCurlyOpen);
				final apDef = parseAnimatedPath();
				final n = createNode(ANIMATED_PATH(apDef), parent, conditional, scale, alpha, tint, layerIndex, updatableName);
				return n;

			case TIdentifier(s) if (isKeyword(s, "curves")):
				advance();
				if (currentName == null) currentName = "curves";
				if (parent != null) error("curves must be a root node");
				expect(TCurlyOpen);
				final curvesDef = parseCurves();
				final n = createNode(CURVES(curvesDef), parent, conditional, scale, alpha, tint, layerIndex, switch (updatableName) {
					case UNTObject(_): UNTObject(defaultCurveNodeName);
					case UNTUpdatable(_): UNTUpdatable(defaultCurveNodeName);
					case UNTIndexed(_, _): UNTObject(defaultCurveNodeName);
				});
				return n;

			case TIdentifier(s) if (isKeyword(s, "autotile")):
				advance();
				if (currentName == null) error("autotile requires a #name");
				if (parent != null) error("autotile must be a root node");
				expect(TCurlyOpen);
				final atDef = parseAutotile();
				final n = createNode(AUTOTILE(atDef), parent, conditional, scale, alpha, tint, layerIndex, updatableName);
				return n;

			case TIdentifier(s) if (isKeyword(s, "atlas2")):
				advance();
				if (currentName == null) error("atlas2 requires a #name");
				if (parent != null) error("atlas2 must be a root node");
				final a2Def = parseAtlas2();
				final n = createNode(ATLAS2(a2Def), parent, conditional, scale, alpha, tint, layerIndex, updatableName);
				return n;

			case TIdentifier(s) if (isKeyword(s, "data")):
				advance();
				if (currentName == null) error("data requires a #name");
				if (parent != null) error("data must be a root node");
				expect(TCurlyOpen);
				final dataDef = parseData();
				final n = createNode(DATA(dataDef), parent, conditional, scale, alpha, tint, layerIndex, updatableName);
				return n;

			// Standalone graphics shortcuts: rect(), line(), circle(), polygon(), ellipse(), roundrect()
			case TIdentifier(s) if (isKeyword(s, "rect") || isKeyword(s, "circle") || isKeyword(s, "line")
				|| isKeyword(s, "polygon") || isKeyword(s, "ellipse") || isKeyword(s, "roundrect") || isKeyword(s, "arc")):
				advance();
				// These are shorthand for graphics(shape(...))
				// parseGraphics* functions call parseOptionalElementPos() which would consume the node position.
				// We use element.pos as the node position instead.
				final element = switch (s.toLowerCase()) {
					case "rect": parseGraphicsRect();
					case "circle": parseGraphicsCircle();
					case "line": parseGraphicsLine();
					case "polygon": parseGraphicsPolygon();
					case "ellipse": parseGraphicsEllipse();
					case "roundrect": parseGraphicsRoundRect();
					case "arc": parseGraphicsArc();
					default: error('unexpected graphics shorthand: $s'); null;
				};
				// Extract the element position as node position, reset element pos to ZERO
				final nodePos = element.pos;
				element.pos = ZERO;
				final n = createNode(GRAPHICS([element]), parent, conditional, scale, alpha, tint, layerIndex, updatableName);
				n.pos = nodePos;
				eatSemicolon();
				return n;

			case TIdentifier(s) if (isKeyword(s, "settings")):
				advance();
				expect(TCurlyOpen);
				if (parent == null) error("settings must have a parent");
				if (parent.settings == null) parent.settings = new Map();
				while (!match(TCurlyClosed)) {
					final key = expectIdentifierOrString();
					switch (peek()) {
						case TColon:
							advance();
							// Typed: key:type=>value
							final typeName = expectIdentifierOrString();
							expect(TArrow);
							switch (typeName.toLowerCase()) {
								case "int":
									final value = parseIntegerOrReference();
									if (parent.settings.exists(key)) error('setting $key already defined');
									parent.settings.set(key, {type: SVTInt, value: value});
								case "float":
									final value = parseFloatOrReference();
									if (parent.settings.exists(key)) error('setting $key already defined');
									parent.settings.set(key, {type: SVTFloat, value: value});
								case "string":
									final value = parseStringOrReference();
									if (parent.settings.exists(key)) error('setting $key already defined');
									parent.settings.set(key, {type: SVTString, value: value});
								default:
									error('expected int, float, or string after : in settings');
							}
						case TArrow:
							advance();
							// Untyped: key=>value (defaults to string)
							final value = parseStringOrReference();
							if (parent.settings.exists(key)) error('setting $key already defined');
							parent.settings.set(key, {type: SVTString, value: value});
						default:
							error('expected :type=> or => after setting key');
					}
					eatComma();
				}
				return null;

			default:
				error('expected valid node type, got ${peek()}');
		}

		// Position or children
		switch (peek()) {
			case TColon:
				advance();
				node.pos = parseXY();
				eatSemicolon();
			case TSemiColon:
				advance();
				node.pos = ZERO;
			case TCurlyOpen:
				advance();
				// Track loop variables in scope for repeatable/repeatable2d bodies
				var loopVarsToPop = 0;
				if (scopeVars != null) {
					switch (node.type) {
						case REPEAT(varName, repeatType):
							scopeVars.push(varName);
							loopVarsToPop = 1;
							// Also track iterator output variables
							switch (repeatType) {
								case TilesIterator(bitmapVar, tilenameVar, _, _):
									scopeVars.push(bitmapVar); loopVarsToPop++;
									if (tilenameVar != null) { scopeVars.push(tilenameVar); loopVarsToPop++; }
								case StateAnimIterator(bitmapVar, _, _, _):
									scopeVars.push(bitmapVar); loopVarsToPop++;
								case ArrayIterator(valueVar, _):
									scopeVars.push(valueVar); loopVarsToPop++;
								default:
							}
						case REPEAT2D(varNameX, varNameY, _, _):
							scopeVars.push(varNameX);
							scopeVars.push(varNameY);
							loopVarsToPop = 2;
						default:
					}
				}
				parseNodes(node, currentDefs);
				for (_ in 0...loopVarsToPop) scopeVars.pop();
			case TEof:
				error("unexpected end of file");
			default:
				error('expected : or { or ;, got ${peek()}');
		}

		return node;
	}

	// ===================== Repeat Iterator =====================

	function parseRepeatIterator(defs:ParametersDefinitions):RepeatType {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "step")):
				advance();
				expect(TOpen);
				final count = parseIntegerOrReference();
				expect(TComma);
				// Parse named params dx:, dy:
				var dx:Null<ReferenceableValue> = null;
				var dy:Null<ReferenceableValue> = null;
				while (!match(TClosed)) {
					eatComma();
					if (match(TClosed)) break;
					final pname = expectIdentifierOrString();
					expect(TColon);
					switch (pname.toLowerCase()) {
						case "dx": dx = parseIntegerOrReference();
						case "dy": dy = parseIntegerOrReference();
						default: error('unknown step param: $pname');
					}
				}
				return StepIterator(dx, dy, count);
			case TIdentifier(s) if (isKeyword(s, "layout")):
				advance();
				expect(TOpen);
				final layoutGroup = expectIdentifierOrString();
				expect(TComma);
				final layoutName = expectIdentifierOrString();
				expect(TClosed);
				return LayoutIterator(layoutName);
			case TIdentifier(s) if (isKeyword(s, "array")):
				advance();
				expect(TOpen);
				final valueVar = expectReferenceOrIdentifier();
				expect(TComma);
				final arrayName = expectReferenceOrIdentifier();
				expect(TClosed);
				return ArrayIterator(valueVar, arrayName);
			case TIdentifier(s) if (isKeyword(s, "range")):
				advance();
				expect(TOpen);
				final start = parseIntegerOrReference();
				expect(TComma);
				final end = parseIntegerOrReference();
				if (match(TComma)) {
					final step = parseIntegerOrReference();
					expect(TClosed);
					return RangeIterator(start, end, step);
				}
				expect(TClosed);
				return RangeIterator(start, end, RVInteger(1));
			case TIdentifier(s) if (isKeyword(s, "stateanim")):
				advance();
				expect(TOpen);
				final bitmapVar = expectReferenceOrIdentifier();
				expect(TComma);
				final animFile = expectIdentifierOrString();
				expect(TComma);
				final animName = parseStringOrReference();
				var selector:Map<String, ReferenceableValue> = new Map();
				while (match(TComma)) {
					final key = expectIdentifierOrString();
					expect(TArrow);
					final val = parseStringOrReference();
					selector.set(key, val);
				}
				expect(TClosed);
				return StateAnimIterator(bitmapVar, animFile, animName, selector);
			case TIdentifier(s) if (isKeyword(s, "tiles")):
				advance();
				expect(TOpen);
				final bitmapVar = expectReferenceOrIdentifier();
				expect(TComma);
				return parseTilesIteratorArgs(bitmapVar, defs);
			default:
				return error("expected iterator type: grid, layout, array, range, stateanim, tiles");
		}
	}

	function parseTilesIteratorArgs(bitmapVar:String, defs:ParametersDefinitions):RepeatType {
		switch (peek()) {
			case TIdentifier(s):
				// Could be tilename var: tiles($bmp, $tilename, "sheet")
				// or directly a quoted string
				advance();
				expect(TComma);
				final sheetName = expectIdentifierOrString();
				expect(TClosed);
				return TilesIterator(bitmapVar, s, sheetName, null);
			case TQuotedString(sheetName):
				advance();
				if (match(TComma)) {
					final filter = expectIdentifierOrString();
					expect(TClosed);
					return TilesIterator(bitmapVar, null, sheetName, filter);
				}
				expect(TClosed);
				return TilesIterator(bitmapVar, null, sheetName, null);
			case TReference(tilename):
				advance();
				expect(TComma);
				final sheetName = expectIdentifierOrString();
				expect(TClosed);
				return TilesIterator(bitmapVar, tilename, sheetName, null);
			default:
				return error("expected sheet name or tilename variable");
		}
	}

	// ===================== Particles =====================

	function parseParticles():ParticlesDef {
		var p:ParticlesDef = {
			count: null, loop: null, relative: null, emitDelay: null, emitSync: null,
			maxLife: null, lifeRandom: null, size: null, sizeRandom: null, blendMode: null,
			speed: null, speedRandom: null, speedIncrease: null, gravity: null, gravityAngle: null,
			fadeIn: null, fadeOut: null, fadePower: null, tiles: [], emit: Point(RVFloat(0), RVFloat(0)),
			rotationInitial: null, rotationSpeed: null, rotationSpeedRandom: null, rotateAuto: null,
			colorStart: null, colorEnd: null, colorMid: null, colorMidPos: null,
			forceFields: null, velocityCurve: null, sizeCurve: null,
			trailEnabled: null, trailLength: null, trailFadeOut: null,
			boundsMode: null, boundsMinX: null, boundsMaxX: null, boundsMinY: null, boundsMaxY: null,
			subEmitters: null, animationRepeat: null
		};
		while (!match(TCurlyClosed)) {
			if (!isNamedParamNext()) { eatComma(); eatSemicolon(); continue; }
			final name = expectIdentifierOrString();
			expect(TColon);
			switch (name.toLowerCase()) {
				case "count": p.count = parseIntegerOrReference();
				case "loop": p.loop = parseBool();
				case "relative": p.relative = parseBool();
				case "maxlife": p.maxLife = parseFloatOrReference();
				case "liferandom": p.lifeRandom = parseFloatOrReference();
				case "size": p.size = parseFloatOrReference();
				case "sizerandom": p.sizeRandom = parseFloatOrReference();
				case "speed": p.speed = parseFloatOrReference();
				case "speedrandom": p.speedRandom = parseFloatOrReference();
				case "speedincrease": p.speedIncrease = parseFloatOrReference();
				case "gravity": p.gravity = parseFloatOrReference();
				case "gravityangle": p.gravityAngle = parseFloatOrReference();
				case "fadein": p.fadeIn = parseFloatOrReference();
				case "fadeout": p.fadeOut = parseFloatOrReference();
				case "fadepower": p.fadePower = parseFloatOrReference();
				case "rotationspeed": p.rotationSpeed = parseFloatOrReference();
				case "rotationspeedrandom": p.rotationSpeedRandom = parseFloatOrReference();
				case "rotationinitial": p.rotationInitial = parseFloatOrReference();
				case "rotateauto": p.rotateAuto = parseBool();
				case "emitdelay": p.emitDelay = parseFloatOrReference();
				case "emitsync": p.emitSync = parseFloatOrReference();
				case "colorstart": p.colorStart = parseColorOrReference();
				case "colorend": p.colorEnd = parseColorOrReference();
				case "colormid": p.colorMid = parseColorOrReference();
				case "colormidpos": p.colorMidPos = parseFloatOrReference();
				case "animationrepeat": p.animationRepeat = parseFloatOrReference();
				case "blendmode":
					final bm = tryParseBlendMode();
					if (bm == null) error("unknown blend mode");
					p.blendMode = bm;
				case "tiles":
					p.tiles = parseTileSources();
				case "emit":
					p.emit = parseEmitMode();
				case "sizecurve":
					p.sizeCurve = parseCurvePoints();
				case "velocitycurve":
					p.velocityCurve = parseCurvePoints();
				case "forcefields":
					p.forceFields = parseForceFields();
				case "boundsmode":
					p.boundsMode = parseBoundsMode();
				case "boundsminx":
					p.boundsMinX = parseFloatOrReference();
				case "boundsmaxx":
					p.boundsMaxX = parseFloatOrReference();
				case "boundsminy":
					p.boundsMinY = parseFloatOrReference();
				case "boundsmaxy":
					p.boundsMaxY = parseFloatOrReference();
				case "trailenabled":
					p.trailEnabled = parseBool();
				case "traillength":
					p.trailLength = parseFloatOrReference();
				case "trailfadeout":
					p.trailFadeOut = parseBool();
				case "subemitters":
					p.subEmitters = parseSubEmitters();
				default:
					// Skip unknown params
					parseStringOrReference();
			}
			eatSemicolon();
		}
		return p;
	}

	function parseTileSources():Array<TileSource> {
		var tiles:Array<TileSource> = [];
		while (true) {
			switch (peek()) {
				case TIdentifier(s) if (isKeyword(s, "file") || isKeyword(s, "generated") || isKeyword(s, "sheet")):
					tiles.push(parseTileSource());
				case TReference(_):
					tiles.push(parseTileSource());
				default:
					break;
			}
		}
		return tiles;
	}

	function parseEmitMode():ParticlesEmitMode {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "point")):
				advance();
				expect(TOpen);
				final dist = parseFloatOrReference();
				expect(TComma);
				final distRand = parseFloatOrReference();
				expect(TClosed);
				return Point(dist, distRand);
			case TIdentifier(s) if (isKeyword(s, "cone")):
				advance();
				expect(TOpen);
				final dist = parseFloatOrReference();
				expect(TComma);
				final distRand = parseFloatOrReference();
				expect(TComma);
				final angle = parseFloatOrReference();
				expect(TComma);
				final angleRand = parseFloatOrReference();
				expect(TClosed);
				return Cone(dist, distRand, angle, angleRand);
			case TIdentifier(s) if (isKeyword(s, "box")):
				advance();
				expect(TOpen);
				final w = parseFloatOrReference();
				expect(TComma);
				final h = parseFloatOrReference();
				expect(TComma);
				final angle = parseFloatOrReference();
				expect(TComma);
				final angleRand = parseFloatOrReference();
				expect(TClosed);
				return Box(w, h, angle, angleRand);
			case TIdentifier(s) if (isKeyword(s, "circle")):
				advance();
				expect(TOpen);
				final r = parseFloatOrReference();
				expect(TComma);
				final rRand = parseFloatOrReference();
				expect(TComma);
				final angle = parseFloatOrReference();
				expect(TComma);
				final angleRand = parseFloatOrReference();
				expect(TClosed);
				return Circle(r, rRand, angle, angleRand);
			default:
				return error("expected emit mode: point, cone, box, circle");
		}
	}

	// ===================== Particle Curves & Force Fields =====================

	function parseCurvePoints():Array<ParticleCurvePoint> {
		expect(TBracketOpen);
		var points:Array<ParticleCurvePoint> = [];
		while (!match(TBracketClosed)) {
			if (points.length > 0) expect(TComma);
			expect(TOpen);
			final time = parseFloatOrReference();
			expect(TComma);
			final value = parseFloatOrReference();
			expect(TClosed);
			points.push({time: time, value: value});
		}
		return points;
	}

	function parseForceFields():Array<ParticleForceFieldDef> {
		expect(TBracketOpen);
		var fields:Array<ParticleForceFieldDef> = [];
		while (!match(TBracketClosed)) {
			if (fields.length > 0) expect(TComma);
			switch (peek()) {
				case TIdentifier(s) if (isKeyword(s, "turbulence")):
					advance();
					expect(TOpen);
					final strength = parseFloatOrReference();
					expect(TComma);
					final scale = parseFloatOrReference();
					expect(TComma);
					final speed = parseFloatOrReference();
					expect(TClosed);
					fields.push(FFTurbulence(strength, scale, speed));
				case TIdentifier(s) if (isKeyword(s, "wind")):
					advance();
					expect(TOpen);
					final vx = parseFloatOrReference();
					expect(TComma);
					final vy = parseFloatOrReference();
					expect(TClosed);
					fields.push(FFWind(vx, vy));
				case TIdentifier(s) if (isKeyword(s, "vortex")):
					advance();
					expect(TOpen);
					final x = parseFloatOrReference();
					expect(TComma);
					final y = parseFloatOrReference();
					expect(TComma);
					final strength = parseFloatOrReference();
					expect(TComma);
					final radius = parseFloatOrReference();
					expect(TClosed);
					fields.push(FFVortex(x, y, strength, radius));
				case TIdentifier(s) if (isKeyword(s, "attractor")):
					advance();
					expect(TOpen);
					final x = parseFloatOrReference();
					expect(TComma);
					final y = parseFloatOrReference();
					expect(TComma);
					final strength = parseFloatOrReference();
					expect(TComma);
					final radius = parseFloatOrReference();
					expect(TClosed);
					fields.push(FFAttractor(x, y, strength, radius));
				case TIdentifier(s) if (isKeyword(s, "repulsor")):
					advance();
					expect(TOpen);
					final x = parseFloatOrReference();
					expect(TComma);
					final y = parseFloatOrReference();
					expect(TComma);
					final strength = parseFloatOrReference();
					expect(TComma);
					final radius = parseFloatOrReference();
					expect(TClosed);
					fields.push(FFRepulsor(x, y, strength, radius));
				default:
					error('unknown force field type: ${peek()}');
			}
		}
		return fields;
	}

	function parseBoundsMode():ParticleBoundsModeDef {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "kill")):
				advance();
				return BMKill;
			case TIdentifier(s) if (isKeyword(s, "wrap")):
				advance();
				return BMWrap;
			case TIdentifier(s) if (isKeyword(s, "bounce")):
				advance();
				expect(TOpen);
				final damping = parseFloatOrReference();
				expect(TClosed);
				return BMBounce(damping);
			case TIdentifier(s) if (isKeyword(s, "none")):
				advance();
				return BMNone;
			default:
				return error('unknown bounds mode: ${peek()}');
		}
	}

	function parseSubEmitters():Array<ParticleSubEmitterDef> {
		expect(TBracketOpen);
		var emitters:Array<ParticleSubEmitterDef> = [];
		while (!match(TBracketClosed)) {
			if (emitters.length > 0) expect(TComma);
			expect(TCurlyOpen);
			var groupId:String = null;
			var trigger:ParticleSubEmitTriggerDef = null;
			var probability:ReferenceableValue = RVFloat(1.0);
			var inheritVelocity:Null<ReferenceableValue> = null;
			var offsetX:Null<ReferenceableValue> = null;
			var offsetY:Null<ReferenceableValue> = null;
			while (!match(TCurlyClosed)) {
				final name = expectIdentifierOrString();
				expect(TColon);
				switch (name.toLowerCase()) {
					case "groupid": groupId = expectIdentifierOrString();
					case "trigger":
						final t = expectIdentifierOrString();
						trigger = switch (t.toLowerCase()) {
							case "onbirth": SETOnBirth;
							case "ondeath": SETOnDeath;
							case "oncollision": SETOnCollision;
							case "oninterval":
								expect(TOpen);
								final interval = parseFloatOrReference();
								expect(TClosed);
								SETOnInterval(interval);
							default: error('unknown sub-emitter trigger: $t');
						};
					case "probability": probability = parseFloatOrReference();
					case "inheritvelocity": inheritVelocity = parseFloatOrReference();
					case "offsetx": offsetX = parseFloatOrReference();
					case "offsety": offsetY = parseFloatOrReference();
					default: parseStringOrReference(); // skip unknown
				}
				eatSemicolon();
			}
			emitters.push({groupId: groupId, trigger: trigger, probability: probability,
				inheritVelocity: inheritVelocity, offsetX: offsetX, offsetY: offsetY});
		}
		return emitters;
	}

	// ===================== Reference Parameters =====================

	function parseReferenceParams():Map<String, ReferenceableValue> {
		var params:Map<String, ReferenceableValue> = new Map();
		while (true) {
			switch (peek()) {
				case TClosed:
					return params;
				case TIdentifier(name):
					advance();
					expect(TArrow);
					params.set(name, parseAnything());
					eatComma();
				default:
					return params;
			}
		}
	}

	// ===================== Interactive Metadata =====================

	function parseInteractiveMetadata():Null<Array<{key:ReferenceableValue, type:SettingValueType, value:ReferenceableValue}>> {
		var metadata:Array<{key:ReferenceableValue, type:SettingValueType, value:ReferenceableValue}> = [];
		while (true) {
			switch (peek()) {
				case TClosed:
					return metadata.length == 0 ? null : metadata;
				case TIdentifier(name):
					advance();
					metadata.push(parseMetadataValue(RVString(name)));
					eatComma();
				case TReference(name):
					advance();
					metadata.push(parseMetadataValue(RVReference(name)));
					eatComma();
				default:
					return metadata.length == 0 ? null : metadata;
			}
		}
	}

	function parseMetadataValue(key:ReferenceableValue):{key:ReferenceableValue, type:SettingValueType, value:ReferenceableValue} {
		switch (peek()) {
			case TColon:
				advance();
				final typeName = expectIdentifierOrString();
				expect(TArrow);
				return switch (typeName.toLowerCase()) {
					case "int": {key: key, type: SVTInt, value: parseIntegerOrReference()};
					case "float": {key: key, type: SVTFloat, value: parseFloatOrReference()};
					case "string": {key: key, type: SVTString, value: parseStringOrReference()};
					default: error('expected int, float, or string after : in metadata');
				};
			case TArrow:
				advance();
				return {key: key, type: SVTString, value: parseAnything()};
			default:
				return error("expected :type=> or => after metadata key");
		}
	}

	// ===================== Flow Orientation =====================

	function parseFlowOrientation():MacroFlowLayout {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "horizontal")): advance(); return MFLHorizontal;
			case TIdentifier(s) if (isKeyword(s, "vertical")): advance(); return MFLVertical;
			case TIdentifier(s) if (isKeyword(s, "stack")): advance(); return MFLStack;
			default: return error("expected horizontal, vertical, or stack");
		}
	}

	function parseFlowOverflow():MacroFlowOverflow {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "expand")): advance(); return MFOExpand;
			case TIdentifier(s) if (isKeyword(s, "limit")): advance(); return MFOLimit;
			case TIdentifier(s) if (isKeyword(s, "scroll")): advance(); return MFOScroll;
			case TIdentifier(s) if (isKeyword(s, "hidden")): advance(); return MFOHidden;
			default: return error("expected expand, limit, scroll, or hidden");
		}
	}

	// ===================== Parse Nodes (children block) =====================

	function parseNodes(node:Null<Node>, defs:ParametersDefinitions):Void {
		while (true) {
			switch (peek()) {
				case TCurlyClosed:
					advance();
					return;
				case TEof:
					if (node != null) error("unexpected end of file");
					return;
				case TSemiColon:
					advance();
					continue;
				// Properties
				case TIdentifier(s) if (isKeyword(s, "pos") || isKeyword(s, "position")):
					advance();
					expect(TColon);
					if (node == null) error("position not supported on root elements");
					node.pos = parseXY();
					eatSemicolon();
				case TIdentifier(s) if (isKeyword(s, "grid")):
					advance();
					expect(TColon);
					if (node == null) error("grid not supported on root");
					final w = parseInteger();
					expect(TComma);
					final h = parseInteger();
					eatSemicolon();
					node.gridCoordinateSystem = {spacingX: w, spacingY: h};
				case TIdentifier(s) if (isKeyword(s, "hex")):
					if (isPropertyColon()) {
						advance();
						expect(TColon);
						if (node == null) error("hex not supported on root");
						final orientation = parseHexOrientation();
						expect(TOpen);
						final w = parseFloat_();
						expect(TComma);
						final h = parseFloat_();
						expect(TClosed);
						eatSemicolon();
						node.hexCoordinateSystem = {hexLayout: HexLayout.createFromFloats(orientation, w, h)};
					} else {
						parseChildNode(node, defs);
					}
				case TIdentifier(s) if (isKeyword(s, "scale")):
					// Check if this is "scale: value" (property) or used as node
					if (isPropertyColon()) {
						advance();
						expect(TColon);
						if (node == null) error("scale not supported on root");
						node.scale = parseFloatOrReference();
						eatSemicolon();
					} else {
						parseChildNode(node, defs);
					}
				case TIdentifier(s) if (isKeyword(s, "alpha")):
					if (isPropertyColon()) {
						advance();
						expect(TColon);
						if (node == null) error("alpha not supported on root");
						node.alpha = parseFloatOrReference();
						eatSemicolon();
					} else {
						parseChildNode(node, defs);
					}
				case TIdentifier(s) if (isKeyword(s, "tint")):
					if (isPropertyColon()) {
						advance();
						expect(TColon);
						if (node == null) error("tint not supported on root");
						node.tint = parseColorOrReference();
						eatSemicolon();
					} else {
						parseChildNode(node, defs);
					}
				case TIdentifier(s) if (isKeyword(s, "filter")):
					if (isPropertyColon()) {
						advance();
						expect(TColon);
						if (node == null) error("filter not supported on root");
						node.filter = parseFilter();
						eatSemicolon();
					} else {
						parseChildNode(node, defs);
					}
				case TIdentifier(s) if (isKeyword(s, "layer")):
					if (isPropertyColon()) {
						advance();
						expect(TColon);
						if (node == null) error("layer not supported on root");
						node.layer = parseInteger();
						eatSemicolon();
					} else {
						parseChildNode(node, defs);
					}
				case TIdentifier(s) if (isKeyword(s, "blendmode")):
					advance();
					expect(TColon);
					if (node == null) error("blendMode not supported on root");
					final bm = tryParseBlendMode();
					if (bm == null) error("unknown blend mode");
					node.blendMode = bm;
					eatSemicolon();
				case TIdentifier(s) if (isKeyword(s, "import")):
					advance();
					final file = expectIdentifierOrString();
					expectKeyword("as");
					final importName = expectIdentifierOrString();
					eatSemicolon();
					if (resourceLoader != null) {
						final loadedFile:Dynamic = resourceLoader.loadMultiAnim(file);
						if (loadedFile == null) error('could not load multiAnim file $file');
						imports.set(importName, loadedFile);
					}
				case TName(name):
					advance();
					currentName = name;
					// Check for (updatable) or [$var] modifier
					var nameType:UpdatableNameType = UNTObject(name);
					if (match(TOpen)) {
						switch (peek()) {
							case TIdentifier(s) if (isKeyword(s, "updatable")):
								advance();
								nameType = UNTUpdatable(name);
							default:
						}
						expect(TClosed);
					} else if (match(TBracketOpen)) {
						// #name[$var] — indexed named element
						switch (peek()) {
							case TReference(indexVar):
								advance();
								if (scopeVars == null || !scopeVars.contains(indexVar))
									error('#name[$$$indexVar]: index variable $$$indexVar is not a known loop variable in this scope');
								expect(TBracketClosed);
								nameType = UNTIndexed(name, indexVar);
							default:
								error('expected $$variable inside #name[...]');
						}
					}
					// Validate: #name (non-indexed) is not allowed inside repeatable
					switch (nameType) {
						case UNTObject(_) | UNTUpdatable(_):
							var checkNode = node;
							while (checkNode != null) {
								switch (checkNode.type) {
									case REPEAT(varName, _):
										error('#$name requires indexed form #$name[$$' + varName + '] inside repeatable');
									case REPEAT2D(varNameX, _, _, _):
										error('#$name requires indexed form #$name[$$' + varNameX + '] inside repeatable');
									default:
								}
								checkNode = checkNode.parent;
							}
						default:
					}
					final newNode = parseNode(nameType, node, defs);
					currentName = null;
					if (newNode != null) {
						if (node == null) addNode(name, newNode);
						else node.children.push(newNode);
					}
				default:
					// Unnamed node
					final newNode = parseNode(UNTObject(null), node, defs);
					if (newNode != null) {
						if (node == null) {
							final n = switch (newNode.updatableName) {
								case UNTObject(n): n;
								case UNTUpdatable(n): n;
								case UNTIndexed(n, _): n;
							}
							addNode(n, newNode);
						} else {
							node.children.push(newNode);
						}
					}
			}
		}
	}

	function parseChildNode(node:Null<Node>, defs:ParametersDefinitions):Void {
		final newNode = parseNode(UNTObject(null), node, defs);
		if (newNode != null) {
			if (node != null) node.children.push(newNode);
		}
	}

	function isPropertyColon():Bool {
		final saved = tpos;
		advance();
		final isColon = Type.enumEq(peek(), TColon);
		tpos = saved;
		return isColon;
	}

	function addNode(name:String, node:Node):Void {
		if (nodes.exists(name)) error('duplicate node #$name');
		nodes.set(name, node);
	}

	function tryParseIntValue():Null<Int> {
		switch (peek()) {
			case TInteger(n):
				advance();
				return stringToInt(n);
			case TMinus:
				final saved = tpos;
				advance();
				switch (peek()) {
					case TInteger(n):
						advance();
						return -stringToInt(n);
					default:
						tpos = saved;
						return null;
				}
			default:
				return null;
		}
	}

	// ===================== Main Entry Points =====================

	function parse():MultiAnimResult {
		// Version header
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "version")):
				advance();
				expect(TColon);
				switch (peek()) {
					case TFloat(v):
						advance();
						if (v != "0.5") error('version 0.5 expected, got $v');
					case TInteger(v):
						advance();
						if (v != "0") error('version 0.5 expected, got $v');
					default:
						error("expected version number");
				}
			default:
				error("Missing version declaration. Files must start with 'version: 0.5'");
		}

		// Parse root nodes
		parseNodes(null, new Map());

		// Check for EOF
		switch (peek()) {
			case TEof:
			default:
				error('unexpected content after main body: ${peek()}');
		}

		return {nodes: nodes, imports: imports};
	}

	// ===================== Graphics =====================

	function parseGraphicsElements():Array<PositionedGraphicsElement> {
		final elements:Array<PositionedGraphicsElement> = [];
		while (true) {
			eatComma();
			switch (peek()) {
				case TClosed:
					advance();
					return elements;
				case TIdentifier(s) if (isKeyword(s, "rect")):
					advance();
					elements.push(parseGraphicsRect());
				case TIdentifier(s) if (isKeyword(s, "circle")):
					advance();
					elements.push(parseGraphicsCircle());
				case TIdentifier(s) if (isKeyword(s, "roundrect")):
					advance();
					elements.push(parseGraphicsRoundRect());
				case TIdentifier(s) if (isKeyword(s, "ellipse")):
					advance();
					elements.push(parseGraphicsEllipse());
				case TIdentifier(s) if (isKeyword(s, "arc")):
					advance();
					elements.push(parseGraphicsArc());
				case TIdentifier(s) if (isKeyword(s, "line")):
					advance();
					elements.push(parseGraphicsLine());
				case TIdentifier(s) if (isKeyword(s, "polygon")):
					advance();
					elements.push(parseGraphicsPolygon());
				case TSemiColon:
					advance();
				default:
					error('expected graphics element or ), got ${peek()}');
					return elements;
			}
		}
		return elements;
	}

	function parseGraphicsStyle():GraphicsStyle {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "filled")):
				advance();
				return GSFilled;
			case TInteger(n):
				advance();
				return GSLineWidth(RVInteger(Std.parseInt(n)));
			case TFloat(n):
				advance();
				return GSLineWidth(RVFloat(Std.parseFloat(n)));
			default:
				final rv = parseIntegerOrReference();
				return GSLineWidth(rv);
		}
	}

	function parseGraphicsRect():PositionedGraphicsElement {
		expect(TOpen);
		final color = parseColorOrReference();
		expect(TComma);
		final style = parseGraphicsStyle();
		expect(TComma);
		final width = parseIntegerOrReference();
		expect(TComma);
		final height = parseIntegerOrReference();
		expect(TClosed);
		final pos = parseOptionalElementPos();
		return {element: GERect(color, style, width, height), pos: pos};
	}

	function parseGraphicsCircle():PositionedGraphicsElement {
		expect(TOpen);
		final color = parseColorOrReference();
		expect(TComma);
		final style = parseGraphicsStyle();
		expect(TComma);
		final radius = parseFloatOrReference();
		expect(TClosed);
		final pos = parseOptionalElementPos();
		return {element: GECircle(color, style, radius), pos: pos};
	}

	function parseGraphicsRoundRect():PositionedGraphicsElement {
		expect(TOpen);
		final color = parseColorOrReference();
		expect(TComma);
		final style = parseGraphicsStyle();
		expect(TComma);
		final width = parseIntegerOrReference();
		expect(TComma);
		final height = parseIntegerOrReference();
		expect(TComma);
		final radius = parseIntegerOrReference();
		expect(TClosed);
		final pos = parseOptionalElementPos();
		return {element: GERoundRect(color, style, width, height, radius), pos: pos};
	}

	function parseGraphicsEllipse():PositionedGraphicsElement {
		expect(TOpen);
		final color = parseColorOrReference();
		expect(TComma);
		final style = parseGraphicsStyle();
		expect(TComma);
		final width = parseIntegerOrReference();
		expect(TComma);
		final height = parseIntegerOrReference();
		expect(TClosed);
		final pos = parseOptionalElementPos();
		return {element: GEEllipse(color, style, width, height), pos: pos};
	}

	function parseGraphicsArc():PositionedGraphicsElement {
		expect(TOpen);
		final color = parseColorOrReference();
		expect(TComma);
		final style = parseGraphicsStyle();
		expect(TComma);
		final radius = parseFloatOrReference();
		expect(TComma);
		final startAngle = parseFloatOrReference();
		expect(TComma);
		final arcAngle = parseFloatOrReference();
		expect(TClosed);
		final pos = parseOptionalElementPos();
		return {element: GEArc(color, style, radius, startAngle, arcAngle), pos: pos};
	}

	function parseGraphicsLine():PositionedGraphicsElement {
		expect(TOpen);
		final color = parseColorOrReference();
		expect(TComma);
		final lineWidth = parseFloatOrReference();
		expect(TComma);
		final start = parseXY();
		expect(TComma);
		final end = parseXY();
		expect(TClosed);
		final pos = parseOptionalElementPos();
		return {element: GELine(color, lineWidth, start, end), pos: pos};
	}

	function parseGraphicsPolygon():PositionedGraphicsElement {
		expect(TOpen);
		final color = parseColorOrReference();
		expect(TComma);
		final style = parseGraphicsStyle();
		expect(TComma);
		// Parse comma-separated x,y pairs until )
		final points:Array<Coordinates> = [];
		while (!match(TClosed)) {
			eatComma();
			if (match(TClosed)) break;
			final x = parseFloatOrReference();
			expect(TComma);
			final y = parseFloatOrReference();
			points.push(OFFSET(x, y));
		}
		final pos = parseOptionalElementPos();
		return {element: GEPolygon(color, style, points), pos: pos};
	}

	/** Parse optional `: x, y` position after a graphics element, defaulting to ZERO */
	function parseOptionalElementPos():Coordinates {
		if (match(TColon)) {
			return parseXY();
		}
		return ZERO;
	}

	// ===================== Pixel Shapes =====================

	function parsePixelShapes():Array<PixelShapes> {
		var shapes:Array<PixelShapes> = [];
		while (!match(TClosed)) {
			eatComma();
			eatSemicolon();
			if (match(TClosed)) break;
			switch (peek()) {
				case TIdentifier(s) if (isKeyword(s, "line")):
					advance();
					final start = parseXY();
					expect(TComma);
					final end = parseXY();
					expect(TComma);
					final color = parseColorOrReference();
					shapes.push(LINE({start: start, end: end, color: color}));
				case TIdentifier(s) if (isKeyword(s, "rect")):
					advance();
					final start = parseXY();
					expect(TComma);
					final width = parseIntegerOrReference();
					expect(TComma);
					final height = parseIntegerOrReference();
					expect(TComma);
					final color = parseColorOrReference();
					shapes.push(RECT({start: start, width: width, height: height, color: color}));
				case TIdentifier(s) if (isKeyword(s, "filledrect")):
					advance();
					final start = parseXY();
					expect(TComma);
					final width = parseIntegerOrReference();
					expect(TComma);
					final height = parseIntegerOrReference();
					expect(TComma);
					final color = parseColorOrReference();
					shapes.push(FILLED_RECT({start: start, width: width, height: height, color: color}));
				case TIdentifier(s) if (isKeyword(s, "pixel")):
					advance();
					final pos = parseXY();
					expect(TComma);
					final color = parseColorOrReference();
					shapes.push(PIXEL({pos: pos, color: color}));
				default:
					error('unexpected pixel shape: ${peek()}');
			}
		}
		return shapes;
	}

	// ===================== StateAnim Construct =====================

	function parseStateAnimConstruct():Map<String, StateAnimConstruct> {
		var constructs:Map<String, StateAnimConstruct> = new Map();
		while (!match(TClosed)) {
			eatComma();
			if (match(TClosed)) break;
			final stateName = expectIdentifierOrString();
			expect(TArrow);
			// expect "sheet"
			switch (peek()) {
				case TIdentifier(s) if (isKeyword(s, "sheet")):
					advance();
				default:
					error("expected 'sheet' in construct");
			}
			final sheet = expectIdentifierOrString();
			expect(TComma);
			final name = parseStringOrReference();
			expect(TComma);
			final fps = parseIntegerOrReference();
			eatComma();
			var loop = false;
			var center = false;
			// Parse optional flags
			while (true) {
				switch (peek()) {
					case TIdentifier(s) if (isKeyword(s, "loop")):
						advance();
						loop = true;
						eatComma();
					case TIdentifier(s) if (isKeyword(s, "center")):
						advance();
						center = true;
						eatComma();
					default:
						break;
				}
			}
			constructs.set(stateName, IndexedSheet(sheet, name, fps, loop, center));
		}
		return constructs;
	}

	// ===================== Paths =====================

	function parsePaths():PathsDef {
		var paths:PathsDef = new Map();
		while (!match(TCurlyClosed)) {
			final pathName = switch (peek()) {
				case TName(s): advance(); s;
				default: expectIdentifierOrString();
			};
			// expect "path" keyword
			switch (peek()) {
				case TIdentifier(s) if (isKeyword(s, "path")):
					advance();
				default:
					error("expected 'path' keyword");
			}
			expect(TCurlyOpen);
			var pathElements:Array<ParsedPaths> = [];
			while (!match(TCurlyClosed)) {
				eatSemicolon();
				if (match(TCurlyClosed)) break;
				switch (peek()) {
					case TIdentifier(s) if (isKeyword(s, "forward")):
						advance();
						expect(TOpen);
						final distance = parseIntegerOrReference();
						expect(TClosed);
						pathElements.push(Forward(distance));
					case TIdentifier(s) if (isKeyword(s, "turn")):
						advance();
						expect(TOpen);
						final angle = parseIntegerOrReference();
						expect(TClosed);
						pathElements.push(TurnDegrees(angle));
					case TIdentifier(s) if (isKeyword(s, "arc")):
						advance();
						expect(TOpen);
						final radius = parseIntegerOrReference();
						expect(TComma);
						final angleDelta = parseIntegerOrReference();
						expect(TClosed);
						pathElements.push(Arc(radius, angleDelta));
					case TIdentifier(s) if (isKeyword(s, "lineto")):
						advance();
						expect(TOpen);
						final end = parseXY();
						expect(TClosed);
						pathElements.push(LineTo(end, PCMRelative));
					case TIdentifier(s) if (isKeyword(s, "lineabs")):
						advance();
						expect(TOpen);
						final end = parseXY();
						expect(TClosed);
						pathElements.push(LineTo(end, PCMAbsolute));
					case TIdentifier(s) if (isKeyword(s, "checkpoint")):
						advance();
						expect(TOpen);
						final cpName = expectIdentifierOrString();
						expect(TClosed);
						pathElements.push(Checkpoint(cpName));
					case TIdentifier(s) if (isKeyword(s, "close")):
						advance();
						pathElements.push(Close);
					case TIdentifier(s) if (isKeyword(s, "moveto")):
						advance();
						expect(TOpen);
						final mode = parseCoordinateMode();
						final target = parseXY();
						expect(TClosed);
						pathElements.push(MoveTo(target, mode));
					case TIdentifier(s) if (isKeyword(s, "moveabs")):
						advance();
						expect(TOpen);
						final target = parseXY();
						expect(TClosed);
						pathElements.push(MoveTo(target, PCMAbsolute));
					case TIdentifier(s) if (isKeyword(s, "spiral")):
						advance();
						expect(TOpen);
						final radiusStart = parseIntegerOrReference();
						expect(TComma);
						final radiusEnd = parseIntegerOrReference();
						expect(TComma);
						final angleDelta = parseIntegerOrReference();
						expect(TClosed);
						pathElements.push(Spiral(radiusStart, radiusEnd, angleDelta));
					case TIdentifier(s) if (isKeyword(s, "wave")):
						advance();
						expect(TOpen);
						final amplitude = parseIntegerOrReference();
						expect(TComma);
						final wavelength = parseIntegerOrReference();
						expect(TComma);
						final count = parseIntegerOrReference();
						expect(TClosed);
						pathElements.push(Wave(amplitude, wavelength, count));
					case TIdentifier(s) if (isKeyword(s, "bezierabs")):
						advance();
						expect(TOpen);
						final end = parseXY();
						expect(TComma);
						final control1 = parseXY();
						if (match(TClosed)) {
							pathElements.push(Bezier2To(end, control1, PCMAbsolute, null));
						} else if (match(TComma)) {
							switch (peek()) {
								case TIdentifier(s2) if (isKeyword(s2, "smoothing")):
									final smoothing = parsePathSmoothing();
									expect(TClosed);
									pathElements.push(Bezier2To(end, control1, PCMAbsolute, smoothing));
								default:
									final control2 = parseXY();
									if (match(TClosed)) {
										pathElements.push(Bezier3To(end, control1, control2, PCMAbsolute, null));
									} else {
										expect(TComma);
										final smoothing = parsePathSmoothing();
										expect(TClosed);
										pathElements.push(Bezier3To(end, control1, control2, PCMAbsolute, smoothing));
									}
							}
						}
					case TIdentifier(s) if (isKeyword(s, "bezier")):
						advance();
						expect(TOpen);
						final bezierMode = parseCoordinateMode();
						final end = parseXY();
						expect(TComma);
						final control1 = parseXY();
						if (match(TClosed)) {
							pathElements.push(Bezier2To(end, control1, bezierMode, null));
						} else if (match(TComma)) {
							// Check for smoothing or second control point
							switch (peek()) {
								case TIdentifier(s2) if (isKeyword(s2, "smoothing")):
									final smoothing = parsePathSmoothing();
									expect(TClosed);
									pathElements.push(Bezier2To(end, control1, bezierMode, smoothing));
								default:
									final control2 = parseXY();
									if (match(TClosed)) {
										pathElements.push(Bezier3To(end, control1, control2, bezierMode, null));
									} else {
										expect(TComma);
										final smoothing = parsePathSmoothing();
										expect(TClosed);
										pathElements.push(Bezier3To(end, control1, control2, bezierMode, smoothing));
									}
							}
						}
					default:
						error('unexpected path element: ${peek()}');
				}
			}
			paths.set(pathName, pathElements);
		}
		return paths;
	}

	function parseCoordinateMode():Null<PathCoordinateMode> {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "absolute")):
				advance();
				expect(TComma);
				return PCMAbsolute;
			case TIdentifier(s) if (isKeyword(s, "relative")):
				advance();
				expect(TComma);
				return PCMRelative;
			default:
				return null;
		}
	}

	function parsePathSmoothing():Null<SmoothingType> {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "smoothing")):
				advance();
				expect(TColon);
				switch (peek()) {
					case TIdentifier(s2) if (isKeyword(s2, "auto")):
						advance();
						return STAuto;
					case TIdentifier(s2) if (isKeyword(s2, "none")):
						advance();
						return STNone;
					default:
						return STDistance(parseFloatOrReference());
				}
			default:
				return null;
		}
	}

	// ===================== Animated Path =====================

	function parseAnimatedPath():AnimatedPathDef {
		var curveAssignments:Array<AnimatedPathCurveAssignment> = [];
		var events:Array<AnimatedPathTimedEvent> = [];
		var mode:Null<AnimatedPathModeType> = null;
		var speed:Null<ReferenceableValue> = null;
		var duration:Null<ReferenceableValue> = null;
		var pathName:Null<String> = null;

		while (!match(TCurlyClosed)) {
			switch (peek()) {
				// type: distance | time
				case TIdentifier(s) if (isKeyword(s, "type")):
					advance();
					expect(TColon);
					final modeStr = expectIdentifierOrString();
					mode = switch (modeStr.toLowerCase()) {
						case "distance": APDistance;
						case "time": APTime;
						default: error('expected "distance" or "time", got "$modeStr"');
					};
				// speed: <float>
				case TIdentifier(s) if (isKeyword(s, "speed")):
					advance();
					expect(TColon);
					speed = parseFloatOrReference();
				// duration: <float>
				case TIdentifier(s) if (isKeyword(s, "duration")):
					advance();
					expect(TColon);
					duration = parseFloatOrReference();
				// path: <pathName>
				case TIdentifier(s) if (isKeyword(s, "path")):
					advance();
					expect(TColon);
					pathName = expectIdentifierOrString();
				default:
					// Rate or checkpoint: <float>: ... or <identifier>: ...
					var at:AnimatedPathTime;
					switch (peek()) {
						case TFloat(_) | TInteger(_):
							final rate = parseFloatOrReference();
							at = Rate(rate);
						case TIdentifier(_) | TQuotedString(_):
							final cpName = expectIdentifierOrString();
							at = Checkpoint(cpName);
						default:
							error('expected rate, checkpoint, type, speed, path, or duration, got ${peek()}');
							return {mode: mode, speed: speed, duration: duration, pathName: pathName != null ? pathName : "", curveAssignments: curveAssignments, events: events};
					}
					expect(TColon);
					// Parse comma-separated list of actions at this time point
					parseAnimatedPathActions(at, curveAssignments, events);
			}
		}
		if (pathName == null) error("animatedPath requires a 'path:' field");

		// Validate path exists and checkpoint references are valid
		var pathCheckpoints:Array<String> = [];
		var pathsNode = nodes.get(defaultPathNodeName);
		if (pathsNode != null) {
			switch (pathsNode.type) {
				case PATHS(pathsDef):
					var pathElements = pathsDef.get(pathName);
					if (pathElements == null) error('path "$pathName" not found in paths block');
					for (el in pathElements) {
						switch (el) {
							case Checkpoint(cpName): pathCheckpoints.push(cpName);
							default:
						}
					}
				default:
			}
		} else {
			error("animatedPath requires a paths block to be defined before it");
		}

		// Validate checkpoint references in curve assignments and events
		for (ca in curveAssignments) {
			switch (ca.at) {
				case Checkpoint(cpName):
					if (pathCheckpoints.indexOf(cpName) < 0)
						error('checkpoint "$cpName" not found in path "$pathName" (available: ${pathCheckpoints.join(", ")})');
				default:
			}
		}
		for (ev in events) {
			switch (ev.at) {
				case Checkpoint(cpName):
					if (pathCheckpoints.indexOf(cpName) < 0)
						error('checkpoint "$cpName" not found in path "$pathName" (available: ${pathCheckpoints.join(", ")})');
				default:
			}
		}

		return {mode: mode, speed: speed, duration: duration, pathName: pathName, curveAssignments: curveAssignments, events: events};
	}

	function parseAnimatedPathActions(at:AnimatedPathTime, curveAssignments:Array<AnimatedPathCurveAssignment>, events:Array<AnimatedPathTimedEvent>):Void {
		while (true) {
			switch (peek()) {
				case TIdentifier(s) if (isKeyword(s, "event")):
					advance();
					expect(TOpen);
					final eventName = expectIdentifierOrString();
					expect(TClosed);
					events.push({at: at, eventName: eventName});
				case TIdentifier(s) if (isKeyword(s, "speedcurve")):
					advance();
					expect(TColon);
					final curveName = expectIdentifierOrString();
					curveAssignments.push({at: at, slot: APSpeed, curveName: curveName});
				case TIdentifier(s) if (isKeyword(s, "scalecurve")):
					advance();
					expect(TColon);
					final curveName = expectIdentifierOrString();
					curveAssignments.push({at: at, slot: APScale, curveName: curveName});
				case TIdentifier(s) if (isKeyword(s, "alphacurve")):
					advance();
					expect(TColon);
					final curveName = expectIdentifierOrString();
					curveAssignments.push({at: at, slot: APAlpha, curveName: curveName});
				case TIdentifier(s) if (isKeyword(s, "rotationcurve")):
					advance();
					expect(TColon);
					final curveName = expectIdentifierOrString();
					curveAssignments.push({at: at, slot: APRotation, curveName: curveName});
				case TIdentifier(s) if (isKeyword(s, "progresscurve")):
					advance();
					expect(TColon);
					final curveName = expectIdentifierOrString();
					curveAssignments.push({at: at, slot: APProgress, curveName: curveName});
				case TIdentifier(s) if (isKeyword(s, "custom")):
					advance();
					expect(TOpen);
					final customName = expectIdentifierOrString();
					expect(TClosed);
					expect(TColon);
					final curveName = expectIdentifierOrString();
					curveAssignments.push({at: at, slot: APCustom(customName), curveName: curveName});
				default:
					error('expected curve assignment or event, got ${peek()}');
					return;
			}
			// Check for comma to continue parsing more actions at this time point
			if (!match(TComma)) return;
		}
	}

	// ===================== Easing =====================

	function parseEasingType():EasingType {
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "linear")): advance(); return Linear;
			case TIdentifier(s) if (isKeyword(s, "easeinquad")): advance(); return EaseInQuad;
			case TIdentifier(s) if (isKeyword(s, "easeoutquad")): advance(); return EaseOutQuad;
			case TIdentifier(s) if (isKeyword(s, "easeinoutquad")): advance(); return EaseInOutQuad;
			case TIdentifier(s) if (isKeyword(s, "easeincubic")): advance(); return EaseInCubic;
			case TIdentifier(s) if (isKeyword(s, "easeoutcubic")): advance(); return EaseOutCubic;
			case TIdentifier(s) if (isKeyword(s, "easeinoutcubic")): advance(); return EaseInOutCubic;
			case TIdentifier(s) if (isKeyword(s, "easeinback")): advance(); return EaseInBack;
			case TIdentifier(s) if (isKeyword(s, "easeoutback")): advance(); return EaseOutBack;
			case TIdentifier(s) if (isKeyword(s, "easeinoutback")): advance(); return EaseInOutBack;
			case TIdentifier(s) if (isKeyword(s, "easeoutbounce")): advance(); return EaseOutBounce;
			case TIdentifier(s) if (isKeyword(s, "easeoutelastic")): advance(); return EaseOutElastic;
			case TIdentifier(s) if (isKeyword(s, "cubicbezier")):
				advance();
				expect(TOpen);
				final x1 = parseFloat_();
				expect(TComma);
				final y1 = parseFloat_();
				expect(TComma);
				final x2 = parseFloat_();
				expect(TComma);
				final y2 = parseFloat_();
				expect(TClosed);
				return CubicBezier(x1, y1, x2, y2);
			default:
				return error('expected easing type, got ${peek()}');
		}
	}

	// ===================== Curves =====================

	function parseCurves():CurvesDef {
		var curves:CurvesDef = new Map();
		while (!match(TCurlyClosed)) {
			final curveName = switch (peek()) {
				case TName(s): advance(); s;
				default: expectIdentifierOrString();
			};
			// expect "curve" keyword
			switch (peek()) {
				case TIdentifier(s) if (isKeyword(s, "curve")):
					advance();
				default:
					error("expected 'curve' keyword");
			}
			expect(TCurlyOpen);
			var easing:Null<EasingType> = null;
			var points:Null<Array<ParticleCurvePoint>> = null;
			var segments:Null<Array<CurveSegmentDef>> = null;
			var segExplicit:Array<Bool> = [];
			while (!match(TCurlyClosed)) {
				eatSemicolon();
				if (match(TCurlyClosed)) break;
				switch (peek()) {
					case TIdentifier(s) if (isKeyword(s, "easing")):
						advance();
						expect(TColon);
						easing = parseEasingType();
					case TIdentifier(s) if (isKeyword(s, "points")):
						advance();
						expect(TColon);
						points = parseCurvePoints();
					case TBracketOpen:
						if (segments == null) segments = [];
						var explicit = [false];
						segments.push(parseCurveSegment(explicit));
						segExplicit.push(explicit[0]);
					default:
						error('expected easing, points, or segment [start..end] in curve definition, got ${peek()}');
				}
			}
			if (segments != null && (easing != null || points != null))
				error("cannot mix segments with easing/points in the same curve");
			// Auto-chain segments without explicit values: each gets equal fraction of 0..1 output
			if (segments != null && segments.length > 1) {
				var allImplicit = true;
				for (e in segExplicit) if (e) { allImplicit = false; break; }
				if (allImplicit) {
					var n = segments.length;
					for (i in 0...n) {
						segments[i].valueStart = RVFloat(i / n);
						segments[i].valueEnd = RVFloat((i + 1) / n);
					}
				}
			}
			curves.set(curveName, {easing: easing, points: points, segments: segments});
		}
		return curves;
	}

	function parseCurveSegment(explicitOut:Array<Bool>):CurveSegmentDef {
		expect(TBracketOpen);
		final timeStart = parseFloatOrReference();
		expect(TDoubleDot);
		final timeEnd = parseFloatOrReference();
		expect(TBracketClosed);
		final easing = parseEasingType();
		var valueStart:ReferenceableValue = RVFloat(0.0);
		var valueEnd:ReferenceableValue = RVFloat(1.0);
		if (match(TOpen)) {
			valueStart = parseFloatOrReference();
			expect(TComma);
			valueEnd = parseFloatOrReference();
			expect(TClosed);
			explicitOut[0] = true;
		}
		return {
			timeStart: timeStart,
			timeEnd: timeEnd,
			easing: easing,
			valueStart: valueStart,
			valueEnd: valueEnd
		};
	}

	// ===================== Autotile =====================

	function parseAutotile():AutotileDef {
		var format:Null<AutotileFormat> = null;
		var source:Null<AutotileSource> = null;
		var tileSize:Null<ReferenceableValue> = null;
		var depth:Null<ReferenceableValue> = null;
		var mapping:Null<Map<Int, Int>> = null;
		var region:Null<Array<ReferenceableValue>> = null;
		var allowPartialMapping:Bool = false;

		while (!match(TCurlyClosed)) {
			switch (peek()) {
				case TIdentifier(s) if (isKeyword(s, "format")):
					advance();
					expect(TColon);
					switch (peek()) {
						case TIdentifier(s2) if (isKeyword(s2, "cross")):
							advance();
							format = Cross;
						case TIdentifier(s2) if (isKeyword(s2, "blob47")):
							advance();
							format = Blob47;
						default:
							error("expected cross or blob47");
					}
				case TIdentifier(s) if (isKeyword(s, "sheet")):
					advance();
					expect(TColon);
					final sheet = parseStringOrReference();
					expect(TComma);
					switch (peek()) {
						case TIdentifier(s2) if (isKeyword(s2, "prefix")):
							advance();
							expect(TColon);
							final prefix = parseStringOrReference();
							source = ATSAtlas(sheet, prefix);
						case TIdentifier(s2) if (isKeyword(s2, "region")):
							advance();
							expect(TColon);
							expect(TBracketOpen);
							var regionVals:Array<ReferenceableValue> = [];
							while (!match(TBracketClosed)) {
								eatComma();
								if (match(TBracketClosed)) break;
								regionVals.push(parseIntegerOrReference());
							}
							source = ATSAtlasRegion(sheet, regionVals);
						default:
							error("expected prefix or region after sheet");
					}
				case TIdentifier(s) if (isKeyword(s, "file")):
					advance();
					expect(TColon);
					final filename = parseStringOrReference();
					source = ATSFile(filename);
				case TIdentifier(s) if (isKeyword(s, "tiles")):
					advance();
					expect(TColon);
					final tiles = parseTileSources();
					source = ATSTiles(tiles);
				case TIdentifier(s) if (isKeyword(s, "demo")):
					advance();
					expect(TColon);
					final edgeColor = parseColorOrReference();
					expect(TComma);
					final fillColor = parseColorOrReference();
					source = ATSDemo(edgeColor, fillColor);
				case TIdentifier(s) if (isKeyword(s, "tilesize")):
					advance();
					expect(TColon);
					tileSize = parseIntegerOrReference();
				case TIdentifier(s) if (isKeyword(s, "depth")):
					advance();
					expect(TColon);
					depth = parseIntegerOrReference();
				case TIdentifier(s) if (isKeyword(s, "mapping")):
					advance();
					expect(TColon);
					expect(TBracketOpen);
					mapping = parseAutotileMapping();
				case TIdentifier(s) if (isKeyword(s, "allowpartialmapping")):
					advance();
					expect(TColon);
					allowPartialMapping = parseBool();
				case TIdentifier(s) if (isKeyword(s, "region")):
					advance();
					expect(TColon);
					expect(TBracketOpen);
					region = [];
					while (!match(TBracketClosed)) {
						eatComma();
						if (match(TBracketClosed)) break;
						region.push(parseIntegerOrReference());
					}
				default:
					error('unexpected autotile property: ${peek()}');
			}
		}

		if (format == null) error("autotile requires format");
		if (source == null) error("autotile requires source");
		if (tileSize == null) error("autotile requires tileSize");

		return {
			format: format,
			source: source,
			tileSize: tileSize,
			depth: depth,
			mapping: mapping,
			region: region,
			allowPartialMapping: allowPartialMapping
		};
	}

	function parseAutotileMapping():Map<Int, Int> {
		var map:Map<Int, Int> = new Map();
		var seqIdx = 0;
		while (!match(TBracketClosed)) {
			eatComma();
			if (match(TBracketClosed)) break;
			final idx = parseInteger();
			if (match(TColon)) {
				final target = parseInteger();
				map.set(idx, target);
			} else {
				map.set(seqIdx, idx);
			}
			seqIdx++;
		}
		return map;
	}

	// ===================== Atlas2 =====================

	function parseAtlas2():Atlas2Def {
		expect(TOpen);
		var source:Atlas2Source;
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "sheet")):
				advance();
				expect(TOpen);
				final sheetName = parseStringOrReference();
				expect(TClosed);
				expect(TClosed);
				source = A2SSheet(sheetName);
			default:
				final filename = parseStringOrReference();
				expect(TClosed);
				source = A2SFile(filename);
		}

		expect(TCurlyOpen);
		var entries:Array<Atlas2EntryDef> = [];
		while (!match(TCurlyClosed)) {
			final name = expectIdentifierOrString();
			expect(TColon);
			final x = parseInteger();
			expect(TComma);
			final y = parseInteger();
			expect(TComma);
			final w = parseInteger();
			expect(TComma);
			final h = parseInteger();

			var entry:Atlas2EntryDef = {name: name, x: x, y: y, w: w, h: h};

			// Parse optional properties
			while (match(TComma)) {
				switch (peek()) {
					case TIdentifier(s) if (isKeyword(s, "offset")):
						advance();
						expect(TColon);
						entry.offsetX = parseInteger();
						expect(TComma);
						entry.offsetY = parseInteger();
					case TIdentifier(s) if (isKeyword(s, "orig")):
						advance();
						expect(TColon);
						entry.origW = parseInteger();
						expect(TComma);
						entry.origH = parseInteger();
					case TIdentifier(s) if (isKeyword(s, "split")):
						advance();
						expect(TColon);
						entry.split = [parseInteger()];
						for (_ in 0...3) {
							expect(TComma);
							entry.split.push(parseInteger());
						}
					case TIdentifier(s) if (isKeyword(s, "index")):
						advance();
						expect(TColon);
						entry.index = parseInteger();
					default:
						break;
				}
			}
			entries.push(entry);
		}

		return {source: source, entries: entries};
	}

	// ===================== Data =====================

	function parseData():DataDef {
		var records:Map<String, DataRecordDef> = new Map();
		var fields:Array<DataFieldDef> = [];

		while (!match(TCurlyClosed)) {
			eatSemicolon();
			if (match(TCurlyClosed)) break;

			switch (peek()) {
				case TName(name):
					// #name record(...) — record type definition
					advance();
					expectKeyword("record");
					expect(TOpen);
					final recordFields = parseDataRecordFields();
					if (records.exists(name)) error('record type "$name" already defined');
					records.set(name, {name: name, fields: recordFields});

				default:
					// Regular field: name: [type] value
					final fieldName = expectIdentifierOrString();
					expect(TColon);
					final field = parseDataField(fieldName, records);
					fields.push(field);
			}
			eatSemicolon();
		}

		return {records: records, fields: fields};
	}

	function parseDataRecordFields():Array<{name:String, type:DataValueType, optional:Bool}> {
		var result:Array<{name:String, type:DataValueType, optional:Bool}> = [];
		if (match(TClosed)) return result;
		while (true) {
			final isOptional = match(TQuestion);
			final fieldName = expectIdentifierOrString();
			expect(TColon);
			final fieldType = parseDataType();
			result.push({name: fieldName, type: fieldType, optional: isOptional});
			if (match(TClosed)) return result;
			expect(TComma);
		}
	}

	/** Parse a type keyword: int, float, string, bool, or a record name.
	 *  If followed by [], it becomes an array type. */
	function parseDataType():DataValueType {
		final typeName = expectIdentifierOrString();
		var baseType:DataValueType = switch (typeName.toLowerCase()) {
			case "int": DVTInt;
			case "float": DVTFloat;
			case "string": DVTString;
			case "bool": DVTBool;
			default: DVTRecord(typeName);
		};
		// Check for [] suffix making it an array type
		if (match(TBracketOpen)) {
			expect(TBracketClosed);
			return DVTArray(baseType);
		}
		return baseType;
	}

	/** Parse a data field value, inferring type from value or using explicit type prefix for records. */
	function parseDataField(fieldName:String, records:Map<String, DataRecordDef>):DataFieldDef {
		// Check if next token is an identifier that could be a type prefix (record name)
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "true") || isKeyword(s, "false")):
				// Bool value
				final boolVal = parseBool();
				return {name: fieldName, type: DVTBool, value: DVBool(boolVal)};

			case TIdentifier(s):
				// Could be: recordName { ... } or recordName[] [ ... ]
				final saved = tpos;
				advance();
				switch (peek()) {
					case TCurlyOpen:
						// recordName { ... }
						advance();
						final recordDef = records.get(s);
						if (recordDef == null) error('unknown record type "$s"');
						final recordValue = parseDataRecordValue(s, recordDef, records);
						return {name: fieldName, type: DVTRecord(s), value: recordValue};
					case TBracketOpen:
						// recordName[] [ ... ]
						advance();
						expect(TBracketClosed);
						expect(TBracketOpen);
						final elements = parseDataArrayElements(DVTRecord(s), records);
						return {name: fieldName, type: DVTArray(DVTRecord(s)), value: DVArray(elements)};
					default:
						// Not a type prefix, restore position
						tpos = saved;
				}

			default:
		}

		// Infer type from value
		switch (peek()) {
			case TInteger(n):
				advance();
				return {name: fieldName, type: DVTInt, value: DVInt(stringToInt(n))};
			case TMinus:
				advance();
				switch (peek()) {
					case TInteger(n):
						advance();
						return {name: fieldName, type: DVTInt, value: DVInt(-stringToInt(n))};
					case TFloat(n):
						advance();
						return {name: fieldName, type: DVTFloat, value: DVFloat(-stringToFloat(n))};
					default:
						return error('expected number after minus');
				}
			case TFloat(n):
				advance();
				return {name: fieldName, type: DVTFloat, value: DVFloat(stringToFloat(n))};
			case TQuotedString(s):
				advance();
				return {name: fieldName, type: DVTString, value: DVString(s)};
			case TBracketOpen:
				advance();
				// Array literal — infer element type from first element
				final elements = parseDataArrayInferred(records);
				final elemType = if (elements.length > 0) inferDataValueType(elements[0]) else DVTInt;
				return {name: fieldName, type: DVTArray(elemType), value: DVArray(elements)};
			default:
				return error('expected value in data field "$fieldName"');
		}
	}

	function parseDataRecordValue(recordName:String, recordDef:DataRecordDef, records:Map<String, DataRecordDef>):DataValue {
		var fieldValues:Map<String, DataValue> = new Map();
		while (!match(TCurlyClosed)) {
			eatComma();
			if (match(TCurlyClosed)) break;
			final name = expectIdentifierOrString();
			expect(TColon);
			// Find expected type from record definition
			var expectedType:Null<DataValueType> = null;
			for (rf in recordDef.fields) {
				if (rf.name == name) {
					expectedType = rf.type;
					break;
				}
			}
			if (expectedType == null) error('unknown field "$name" in record "$recordName"');
			final value = parseDataValueOfType(expectedType, records);
			if (fieldValues.exists(name)) error('duplicate field "$name" in record');
			fieldValues.set(name, value);
		}
		// Validate all required fields present (optional fields can be omitted)
		for (rf in recordDef.fields) {
			if (!fieldValues.exists(rf.name) && !rf.optional)
				error('missing required field "${rf.name}" in record "$recordName"');
		}
		return DVRecord(recordName, fieldValues);
	}

	function parseDataValueOfType(type:DataValueType, records:Map<String, DataRecordDef>):DataValue {
		return switch (type) {
			case DVTInt: DVInt(parseInteger());
			case DVTFloat: DVFloat(parseFloat_());
			case DVTString:
				switch (peek()) {
					case TQuotedString(s): advance(); DVString(s);
					default: error('expected string value');
				}
			case DVTBool: DVBool(parseBool());
			case DVTRecord(recordName):
				expect(TCurlyOpen);
				final recordDef = records.get(recordName);
				if (recordDef == null) error('unknown record type "$recordName"');
				parseDataRecordValue(recordName, recordDef, records);
			case DVTArray(elemType):
				expect(TBracketOpen);
				DVArray(parseDataArrayElements(elemType, records));
		};
	}

	function parseDataArrayElements(elemType:DataValueType, records:Map<String, DataRecordDef>):Array<DataValue> {
		var result:Array<DataValue> = [];
		while (!match(TBracketClosed)) {
			eatComma();
			if (match(TBracketClosed)) break;
			result.push(parseDataValueOfType(elemType, records));
		}
		return result;
	}

	function parseDataArrayInferred(records:Map<String, DataRecordDef>):Array<DataValue> {
		var result:Array<DataValue> = [];
		while (!match(TBracketClosed)) {
			eatComma();
			if (match(TBracketClosed)) break;
			switch (peek()) {
				case TInteger(n):
					advance();
					result.push(DVInt(stringToInt(n)));
				case TFloat(n):
					advance();
					result.push(DVFloat(stringToFloat(n)));
				case TQuotedString(s):
					advance();
					result.push(DVString(s));
				case TMinus:
					advance();
					switch (peek()) {
						case TInteger(n):
							advance();
							result.push(DVInt(-stringToInt(n)));
						case TFloat(n):
							advance();
							result.push(DVFloat(-stringToFloat(n)));
						default:
							error('expected number after minus');
					}
				case TIdentifier(s) if (isKeyword(s, "true") || isKeyword(s, "false")):
					result.push(DVBool(parseBool()));
				default:
					error('expected value in array literal');
			}
		}
		return result;
	}

	function inferDataValueType(value:DataValue):DataValueType {
		return switch (value) {
			case DVInt(_): DVTInt;
			case DVFloat(_): DVTFloat;
			case DVString(_): DVTString;
			case DVBool(_): DVTBool;
			case DVRecord(name, _): DVTRecord(name);
			case DVArray(elements): DVTArray(if (elements.length > 0) inferDataValueType(elements[0]) else DVTInt);
		};
	}

	// ===================== Optional Params (for filters) =====================

	function parseOptionalParams(defs:Array<OptionalParametersParsing>, ?once:Bool):Map<String, Dynamic> {
		var results:Map<String, Dynamic> = new Map();
		while (!match(TClosed)) {
			eatComma();
			if (match(TClosed)) break;
			final pname = expectIdentifierOrString();
			expect(TColon);
			var found = false;
			for (d in defs) {
				final defName = switch (d) {
					case ParseInteger(n) | ParseIntegerOrReference(n) | ParseFloat(n) |
						ParseFloatOrReference(n) | ParseBool(n) | ParseCustom(n, _) | ParseColor(n): n;
				};
				if (isKeyword(pname, defName)) {
					if (results.exists(defName)) error('named parameter "$defName" already defined');
					switch (d) {
						case ParseInteger(n):
							results.set(n, parseInteger());
						case ParseIntegerOrReference(n):
							results.set(n, parseIntegerOrReference());
						case ParseFloat(n):
							results.set(n, parseFloat_());
						case ParseFloatOrReference(n):
							results.set(n, parseFloatOrReference());
						case ParseBool(n):
							results.set(n, parseBool());
						case ParseCustom(n, parse):
							results.set(n, parse());
						case ParseColor(n):
							results.set(n, parseColorOrReference());
					}
					found = true;
					break;
				}
			}
			if (!found) error('unknown named parameter: $pname');
		}
		return results;
	}

	// ===================== Public API =====================

	public static function parseFile(content:String, sourceName:String, ?resourceLoader:Dynamic):MultiAnimResult {
		// Tokenize
		final lexer = new MacroLexer(content, sourceName);
		var tokens:Array<Token> = [];
		while (true) {
			final t = lexer.nextToken();
			tokens.push(t);
			if (Type.enumEq(t.type, TEof)) break;
		}

		// Parse
		final parser = new MacroManimParser(tokens, sourceName, resourceLoader);
		return parser.parse();
	}
}
