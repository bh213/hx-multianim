package bh.multianim;

#if macro
import bh.multianim.MultiAnimParser;
import bh.multianim.CoordinateSystems;
import bh.multianim.MacroCompatTypes.MacroBlendMode;
import bh.multianim.MacroCompatTypes.MacroFlowLayout;
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
	var uniqueCounter:Int;

	static final defaultLayoutNodeName = "#defaultLayout";

	function new(tokens:Array<Token>, sourceName:String) {
		this.tokens = tokens;
		this.tpos = 0;
		this.sourceName = sourceName;
		this.nodes = new Map();
		this.uniqueCounter = 654321;
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
		return s.toLowerCase() == kw;
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
				advance();
				return parseNextAnythingExpression(RVString(s));
			case TOpen:
				advance();
				final e = parseAnything();
				expect(TClosed);
				return parseNextAnythingExpression(RVParenthesis(e));
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

	static function tryStringToColor(s:String):Null<Int> {
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
			case TReference(s):
				advance();
				return TSReference(s);
			default:
				// sheet(sheetName, tileName [, index])
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
			default:
				return error("unknown generated tile type");
		}
	}

	// ===================== Parameter Definitions =====================

	function parseDefines():ParametersDefinitions {
		var defines:ParametersDefinitions = new Map();
		if (match(TClosed)) return defines;
		while (true) {
			final def = parseDefine();
			if (defines.exists(def.name)) error('parameter ${def.name} already defined');
			defines.set(def.name, def);
			if (match(TClosed)) return defines;
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
				while (true) {
					switch (peek()) {
						case TBracketClosed:
							advance();
							break;
						case TComma:
							advance();
						case TIdentifier(s):
							advance();
							enumNames.push(s);
						case TQuotedString(s):
							advance();
							enumNames.push(s);
						case TInteger(s) | TFloat(s):
							advance();
							enumNames.push(s);
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
				error('array default not supported in this context');
		}
	}

	function parseStringArray():Array<String> {
		expect(TBracketOpen);
		var arr:Array<String> = [];
		while (!match(TBracketClosed)) {
			if (arr.length > 0) expect(TComma);
			arr.push(expectIdentifierOrString());
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
					final size = parseNamedFloatParam("size", RVFloat(1.));
					final color = parseNamedColorParam("color", RVInteger(0xFF000000));
					expect(TClosed);
					return FilterOutline(size, color);
				}
				final size = parseFloatOrReference();
				expect(TComma);
				final color = parseColorOrReference();
				expect(TClosed);
				return FilterOutline(size, color);
			case TIdentifier(s) if (isKeyword(s, "saturate")):
				advance();
				expect(TOpen);
				final value = parseFloatOrReference();
				expect(TClosed);
				return FilterSaturate(value);
			case TIdentifier(s) if (isKeyword(s, "brightness")):
				advance();
				expect(TOpen);
				final value = parseFloatOrReference();
				expect(TClosed);
				return FilterBrightness(value);
			case TIdentifier(s) if (isKeyword(s, "blur")):
				advance();
				expect(TOpen);
				final radius = parseFloatOrReference();
				expect(TComma);
				final gain = parseFloatOrReference();
				expect(TClosed);
				return FilterBlur(radius, gain, RVFloat(1.), RVFloat(0.0));
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

		while (true) {
			switch (peek()) {
				case TName(name):
					advance();
					// Try single point first
					final content = parseLayoutContent();
					if (content != null) {
						eatSemicolon();
						layouts.set(name, {name: name, type: Single(content), grid: null, hex: null, offset: foldOffsets(offsets)});
						continue;
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
							layouts.set(name, {name: name, type: Sequence(varName, from, to, lc), grid: null, hex: null, offset: foldOffsets(offsets)});
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
							layouts.set(name, {name: name, type: List(contentList), grid: null, hex: null, offset: foldOffsets(offsets)});
						default:
							error("expected sequence, list, or point");
					}
				case TCurlyClosed:
					advance();
					return layouts;
				default:
					error('unexpected token in layouts: ${peek()}');
			}
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
					case NoConditional: error("@else/@default requires preceding sibling with conditional");
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
							default: error('unknown text param: $pname');
						}
					} else break;
				}
				final textDef:TextDef = {
					fontName: fontname, text: text, color: color, halign: halign,
					textAlignWidth: textAlignWidth, letterSpacing: letterSpacing, lineSpacing: lineSpacing,
					lineBreak: lineBreak, dropShadowXY: null, dropShadowColor: 0, dropShadowAlpha: 0.5,
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

			case TIdentifier(s) if (isKeyword(s, "interactive")):
				advance();
				expect(TOpen);
				final w = parseIntegerOrReference();
				expect(TComma);
				final h = parseIntegerOrReference();
				expect(TComma);
				final id = parseStringOrReference();
				var debug = false;
				if (match(TComma)) {
					switch (peek()) {
						case TIdentifier(d) if (isKeyword(d, "debug")):
							advance();
							debug = true;
						default:
					}
				}
				expect(TClosed);
				createNode(INTERACTIVE(w, h, id, debug), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

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
						default: error('unknown flow param: $pname');
					}
				}
				createNode(FLOW(maxWidth, maxHeight, minWidth, minHeight, lineHeight, colWidth, layout, paddingTop, paddingBottom, paddingLeft, paddingRight, hSpacing, vSpacing, debug, multiline), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

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
				final params = parseDefines();
				currentDefs = params;
				createNode(PROGRAMMABLE(isTileGroup, params), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

			case TIdentifier(s) if (isKeyword(s, "relativelayouts")):
				advance();
				expect(TCurlyOpen);
				final layoutsDef = parseLayouts();
				final n = createNode(RELATIVE_LAYOUTS(layoutsDef), parent, conditional, scale, alpha, tint, layerIndex, switch (updatableName) {
					case UNTObject(_): UNTObject(defaultLayoutNodeName);
					case UNTUpdatable(_): UNTUpdatable(defaultLayoutNodeName);
				});
				return n; // skip position/children parsing

			case TIdentifier(s) if (isKeyword(s, "particles")):
				advance();
				expect(TCurlyOpen);
				final p = parseParticles();
				final n = createNode(PARTICLES(p), parent, conditional, scale, alpha, tint, layerIndex, updatableName);
				return n;

			case TIdentifier(s) if (isKeyword(s, "reference")):
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
				createNode(REFERENCE(extRef, progRef, params), parent, conditional, scale, alpha, tint, layerIndex, updatableName);

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

			case TIdentifier(s) if (isKeyword(s, "tilegroup")):
				advance();
				createNode(TILEGROUP, parent, conditional, scale, alpha, tint, layerIndex, updatableName);

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
				parseNodes(node, currentDefs);
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
			case TIdentifier(s) if (isKeyword(s, "grid")):
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
						default: error('unknown grid param: $pname');
					}
				}
				return GridIterator(dx, dy, count);
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
				case TIdentifier(s) if (isKeyword(s, "file")):
					advance();
					expect(TOpen);
					tiles.push(TSFile(parseStringOrReference()));
					expect(TClosed);
				case TReference(s):
					advance();
					tiles.push(TSReference(s));
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
					params.set(name, parseStringOrReference());
					eatComma();
				default:
					return params;
			}
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
				case TName(name):
					advance();
					final newNode = parseNode(UNTObject(name), node, defs);
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

	function parse():Map<String, Node> {
		// Version header
		switch (peek()) {
			case TIdentifier(s) if (isKeyword(s, "version")):
				advance();
				expect(TColon);
				switch (peek()) {
					case TFloat(v):
						advance();
						if (v != "0.3") error('version 0.3 expected, got $v');
					case TInteger(v):
						advance();
						if (v != "0") error('version 0.3 expected, got $v');
					default:
						error("expected version number");
				}
			default:
				error("Missing version declaration. Files must start with 'version: 0.3'");
		}

		// Parse root nodes
		parseNodes(null, new Map());

		// Check for EOF
		switch (peek()) {
			case TEof:
			default:
				error('unexpected content after main body: ${peek()}');
		}

		return nodes;
	}

	// ===================== Public API =====================

	public static function parseFile(content:String, sourceName:String):Map<String, Node> {
		// Tokenize
		final lexer = new MacroLexer(content, sourceName);
		var tokens:Array<Token> = [];
		while (true) {
			final t = lexer.nextToken();
			tokens.push(t);
			if (Type.enumEq(t.type, TEof)) break;
		}

		// Parse
		final parser = new MacroManimParser(tokens, sourceName);
		return parser.parse();
	}
}
#end
