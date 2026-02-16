package bh.stateanim;

import bh.base.ParseError;
import bh.base.ParseError.ParseUnexpected;
import bh.base.ParsePosition;
import bh.base.Atlas2;
import bh.base.ResourceLoader;
import haxe.io.Bytes;
import bh.stateanim.AnimationSM;
import bh.base.Point;

using StringTools;
using bh.base.MapTools;

enum APIdentifierType {
	AITString;
	AITParameter;
	AITQuotedString;
}

enum APToken {
	APEof;
	APOpen;
	APClosed;
	APComma;
	APColon;
	APSemiColon;
	APNumber(s:String);
	APIdentifier(s:String, keyword:Null<APKeywords>, identType:APIdentifierType);
	APCurlyClosed;
	APCurlyOpen;
	APBracketClosed;
	APBracketOpen;
	APNewLine;
	APDoubleDot;
	APAt;
	APArrow;
	APNotEquals;
}

enum AnimConditionalValue {
	ACVSingle(value:String);
	ACVMulti(values:Array<String>);
	ACVNot(inner:AnimConditionalValue);
}

typedef AnimConditionalSelector = Map<String, AnimConditionalValue>;

enum APKeywords {
	APSheet;
	APFile;
	APStates;
	APAllowedExtraPoints;
	APExtrapoints;
	APPlaylist;
	APCenter;
	APLoop;
	APAnimation;
	APName;
	APFps;
	APEvent;
	APDuration;
	APRandom;
	APFrames;
	APMetadata;
}

// ===================== Hand-coded Lexer =====================

private class AnimToken {
	public var type:APToken;
	public var line:Int;
	public var col:Int;
	public function new(type:APToken, line:Int, col:Int) {
		this.type = type;
		this.line = line;
		this.col = col;
	}
}

private class AnimLexerHC {
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

	static final keywordMap:Map<String, APKeywords> = [
		"sheet" => APSheet, "file" => APFile, "states" => APStates,
		"allowedextrapoints" => APAllowedExtraPoints, "extrapoints" => APExtrapoints,
		"playlist" => APPlaylist, "center" => APCenter, "loop" => APLoop,
		"animation" => APAnimation, "name" => APName, "fps" => APFps,
		"event" => APEvent, "duration" => APDuration, "random" => APRandom,
		"frames" => APFrames, "metadata" => APMetadata,
	];

	inline function ch():Int {
		return pos < len ? src.charCodeAt(pos) : -1;
	}

	public function nextToken():AnimToken {
		// Skip spaces and tabs (NOT newlines)
		while (pos < len) {
			final c = ch();
			if (c == ' '.code || c == '\t'.code) { pos++; col++; }
			else break;
		}

		final startLine = line;
		final startCol = col;

		if (pos >= len) return new AnimToken(APEof, startLine, startCol);

		final c = ch();

		// Line comment
		if (c == '/'.code && pos + 1 < len && src.charCodeAt(pos + 1) == '/'.code) {
			while (pos < len && ch() != '\n'.code && ch() != '\r'.code) { pos++; col++; }
			return nextToken();
		}

		// Block comment
		if (c == '/'.code && pos + 1 < len && src.charCodeAt(pos + 1) == '*'.code) {
			pos += 2; col += 2;
			while (pos < len) {
				if (ch() == '*'.code && pos + 1 < len && src.charCodeAt(pos + 1) == '/'.code) {
					pos += 2; col += 2;
					break;
				}
				if (ch() == '\n'.code) { line++; col = 1; lineStart = pos + 1; }
				else { col++; }
				pos++;
			}
			return nextToken();
		}

		// Newline
		if (c == '\n'.code) { pos++; line++; col = 1; lineStart = pos; return new AnimToken(APNewLine, startLine, startCol); }
		if (c == '\r'.code) {
			pos++;
			if (pos < len && ch() == '\n'.code) pos++;
			line++; col = 1; lineStart = pos;
			return new AnimToken(APNewLine, startLine, startCol);
		}

		// Two-char tokens
		if (c == '!'.code && pos + 1 < len && src.charCodeAt(pos + 1) == '='.code) { pos += 2; col += 2; return new AnimToken(APNotEquals, startLine, startCol); }
		if (c == '='.code && pos + 1 < len && src.charCodeAt(pos + 1) == '>'.code) { pos += 2; col += 2; return new AnimToken(APArrow, startLine, startCol); }
		if (c == '.'.code && pos + 1 < len && src.charCodeAt(pos + 1) == '.'.code) { pos += 2; col += 2; return new AnimToken(APDoubleDot, startLine, startCol); }

		// Single-char tokens
		switch (c) {
			case '('.code: pos++; col++; return new AnimToken(APOpen, startLine, startCol);
			case ')'.code: pos++; col++; return new AnimToken(APClosed, startLine, startCol);
			case '{'.code: pos++; col++; return new AnimToken(APCurlyOpen, startLine, startCol);
			case '}'.code: pos++; col++; return new AnimToken(APCurlyClosed, startLine, startCol);
			case '['.code: pos++; col++; return new AnimToken(APBracketOpen, startLine, startCol);
			case ']'.code: pos++; col++; return new AnimToken(APBracketClosed, startLine, startCol);
			case ','.code: pos++; col++; return new AnimToken(APComma, startLine, startCol);
			case ':'.code: pos++; col++; return new AnimToken(APColon, startLine, startCol);
			case ';'.code: pos++; col++; return new AnimToken(APSemiColon, startLine, startCol);
			case '@'.code: pos++; col++; return new AnimToken(APAt, startLine, startCol);
			default:
		}

		// Quoted string
		if (c == '"'.code) {
			pos++; col++;
			var buf = new StringBuf();
			while (pos < len) {
				final sc = ch();
				if (sc == '\\'.code && pos + 1 < len) {
					final nc = src.charCodeAt(pos + 1);
					if (nc == '"'.code) { buf.addChar('"'.code); pos += 2; col += 2; continue; }
					if (nc == 'u'.code && pos + 5 < len) {
						buf.add(String.fromCharCode(Std.parseInt("0x" + src.substr(pos + 2, 4))));
						pos += 6; col += 6; continue;
					}
				}
				if (sc == '"'.code) { pos++; col++; break; }
				buf.addChar(sc);
				pos++; col++;
			}
			return new AnimToken(APIdentifier(buf.toString(), null, AITQuotedString), startLine, startCol);
		}

		// Number (including negative)
		if ((c >= '0'.code && c <= '9'.code) || (c == '-'.code && pos + 1 < len && src.charCodeAt(pos + 1) >= '0'.code && src.charCodeAt(pos + 1) <= '9'.code)) {
			var start = pos;
			if (c == '-'.code) { pos++; col++; }
			while (pos < len && ch() >= '0'.code && ch() <= '9'.code) { pos++; col++; }
			// Skip underscore digit separators
			return new AnimToken(APNumber(src.substring(start, pos).replace("_", "")), startLine, startCol);
		}

		// Identifier (includes @, #, !, $)
		if (isIdentStart(c)) {
			var start = pos;
			pos++; col++;
			while (pos < len && isIdentContinue(ch())) { pos++; col++; }
			final s = src.substring(start, pos);
			final kw = keywordMap.get(s.toLowerCase());
			return new AnimToken(APIdentifier(s, kw, AITString), startLine, startCol);
		}

		// Unknown character - skip it
		pos++; col++;
		return nextToken();
	}

	static inline function isIdentStart(c:Int):Bool {
		return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || c == '_'.code
			|| c == '@'.code || c == '#'.code || c == '!'.code || c == '$'.code;
	}

	static inline function isIdentContinue(c:Int):Bool {
		return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || (c >= '0'.code && c <= '9'.code)
			|| c == '_'.code || c == '-'.code || c == '$'.code;
	}
}

// ===================== Types =====================

enum MetadataValue {
	MVInt(i:Int);
	MVString(s:String);
}

typedef MetadataEntry = {
	var states:AnimConditionalSelector;
	var value:MetadataValue;
}

typedef LoadedAnimation = {
	var sheet:String;
	var states:Map<String, Array<String>>;
	var allowedExtraPoints:Array<String>;
	var ?center:Point;
	var ?metadata:AnimMetadata;
	var animations:Array<AnimationState>;
}

class AnimMetadata {
	final metadata:Map<String, Array<MetadataEntry>>;

	public function new(metadata:Map<String, Array<MetadataEntry>>) {
		this.metadata = metadata;
	}

	function findBestMatch(key:String, stateSelector:Null<AnimationStateSelector>):Null<MetadataValue> {
		if (metadata == null)
			return null;
		final entries = metadata[key];
		if (entries == null)
			return null;

		var bestScore = -1;
		var best:Null<MetadataEntry> = null;
		for (entry in entries) {
			final score = stateSelector != null ? AnimParser.countStateMatch(entry.states, stateSelector) : 0;
			if (score > bestScore) {
				best = entry;
				bestScore = score;
			}
		}
		return best != null ? best.value : null;
	}

	public function getIntOrDefault(key:String, defaultValue:Int, ?stateSelector:AnimationStateSelector):Int {
		final value = findBestMatch(key, stateSelector);
		if (value == null)
			return defaultValue;
		return switch value {
			case MVInt(i): i;
			case MVString(s): throw 'expected int for metadata key ${key} but was string $s';
		};
	}

	public function getIntOrException(key:String, ?stateSelector:AnimationStateSelector):Int {
		final value = findBestMatch(key, stateSelector);
		if (value == null)
			throw 'metadata key ${key} not found';
		return switch value {
			case MVInt(i): i;
			case MVString(s): throw 'expected int for metadata key ${key} but was string $s';
		};
	}

	public function getStringOrDefault(key:String, defaultValue:String, ?stateSelector:AnimationStateSelector):String {
		final value = findBestMatch(key, stateSelector);
		if (value == null)
			return defaultValue;
		return switch value {
			case MVString(s): s;
			case MVInt(i): '$i';
		};
	}

	public function getStringOrException(key:String, ?stateSelector:AnimationStateSelector):String {
		final value = findBestMatch(key, stateSelector);
		if (value == null)
			throw 'metadata key ${key} not found';
		return switch value {
			case MVString(s): s;
			case MVInt(i): '$i';
		};
	}
}

@:using(AnimParser.ExtraPointsHelper)
typedef ExtraPoints = {
	var states:AnimConditionalSelector;
	var point:Point;
	var ?visited:Bool;
}

enum AnimPlaylistFrames {
	SheetFrameAnim(name:String, durationMilliseconds:Null<Int>);
	SheetFrameAnimWithIndex(name:String, from:Null<Int>, to:Null<Int>, durationMilliseconds:Null<Int>);
	FileSingleFrame(filename:String, durationMilliseconds:Null<Int>);
	PlaylistEvent(playlistEvent:AnimationPlaylistEvent);
}

typedef Playlist = {
	var states:AnimConditionalSelector;
	var anims:Array<AnimPlaylistFrames>;
	var ?visited:Bool;
}

typedef AnimationState = {
	var name:String;
	var states:AnimConditionalSelector;
	var fps:Null<Int>;
	var loop:Null<Int>; // -1 = forever, null = no loop, N = loop N times
	var extraPoint:Map<String, Array<ExtraPoints>>;
	var playlist:Array<Playlist>;
	var ?visited:Bool;
}

class ExtraPointsHelper {
	public static function toPoint(pt:ExtraPoints) {
		return new h2d.col.IPoint(pt.point.x, pt.point.y);
	}
}

class AnimUnexpected<Token> extends ParseUnexpected<Token> {
	final message:String;

	public function new(token:Token, pos:ParsePosition, message) {
		super(token, pos);
		this.token = token;
		this.message = message;
	}

	override public function toString() {
		return '${message}: unexpected $token at ${this.pos.format()}';
	}
}

class InvalidSyntax extends ParseError {
	public var error:String;

	public function new(error, pos:ParsePosition) {
		super(pos);
		this.error = 'Error ${error}, ${pos.format()}';
	}

	public override function toString() {
		return error;
	}
}

typedef AnimationStateSelector = Map<String, String>;

interface AnimParserResult {
	var definedStates(default, never):Map<String, Array<String>>;
	var metadata(default, never):Null<AnimMetadata>;
	function createAnimSM(stateSelector:AnimationStateSelector):AnimationSM;
}

// ===================== Parser =====================

class AnimParser implements AnimParserResult {
	var tokens:Array<AnimToken>;
	var tpos:Int;
	var sourceName:String;

	var animations:Array<AnimationState> = [];
	var animationNames:Array<String> = [];
	var allowedExtraPoints:Array<String> = [];
	public var definedStates(default, null):Map<String, Array<String>> = [];
	var definedStatesIndexes:Array<String> = [];
	var sheetName:String;
	var center:Null<Point> = null;
	var metadataMap:Map<String, Array<MetadataEntry>> = [];
	public var metadata(default, null):Null<AnimMetadata> = null;
	var cache:Map<String, Array<{name:String, states:Array<AnimationFrameState>, loopCount:Int, extraPoints:Map<String, h2d.col.IPoint>}>> = [];
	final resourceLoader:bh.base.ResourceLoader;

	// ===================== Token Access =====================

	inline function peek():APToken {
		return tokens[tpos].type;
	}

	function advance():AnimToken {
		final t = tokens[tpos];
		if (tpos < tokens.length - 1) tpos++;
		return t;
	}

	function expect(type:APToken):Void {
		if (!Type.enumEq(peek(), type))
			syntaxError('expected $type, got ${peek()}');
		advance();
	}

	function match(type:APToken):Bool {
		if (Type.enumEq(peek(), type)) {
			advance();
			return true;
		}
		return false;
	}

	function skipNewlines():Void {
		while (Type.enumEq(peek(), APNewLine)) advance();
	}

	function curPos():ParsePosition {
		final t = tokens[tpos];
		return new ParsePosition(sourceName, t.line, t.col);
	}

	function syntaxError(error:String, ?pos:ParsePosition):Dynamic {
		final p = pos != null ? pos : curPos();
		final err = new InvalidSyntax(error, p);
		trace(err);
		throw err;
	}

	function unexpectedError(?message:String):Dynamic {
		final err = new AnimUnexpected(peek(), curPos(), message);
		trace(err);
		throw err;
	}

	// ===================== Entry Points =====================

	public static function parseFile(input:byte.ByteData, sourceName:String, resourceLoader):AnimParserResult {
		return parseString(input.readString(0, input.length), sourceName, resourceLoader);
	}

	public static function parseString(content:String, sourceName:String, resourceLoader):AnimParserResult {
		try {
			final lexer = new AnimLexerHC(content, sourceName);
			var tokens:Array<AnimToken> = [];
			while (true) {
				final t = lexer.nextToken();
				tokens.push(t);
				if (Type.enumEq(t.type, APEof)) break;
			}
			var p = new AnimParser(tokens, sourceName, resourceLoader);
			p.parse();
			return p;
		} catch (e) {
			trace(e);
			throw e;
		}
	}

	function new(tokens:Array<AnimToken>, sourceName:String, resourceLoader) {
		this.tokens = tokens;
		this.tpos = 0;
		this.sourceName = sourceName;
		this.resourceLoader = resourceLoader;
	}

	// ===================== Main Parse =====================

	function parse():Void {
		var animationParsingStarted = false;
		while (true) {
			switch (peek()) {
				case APNewLine:
					advance();
				case APEof:
					break;
				case APIdentifier(_, APSheet, AITString):
					advance();
					expect(APColon);
					final value = expectIdentifier();
					expectNewline();
					if (animationParsingStarted) syntaxError("sheet must be defined before animations");
					if (sheetName != null) syntaxError("sheet already defined");
					sheetName = value;
				case APIdentifier(_, APStates, AITString):
					advance();
					expect(APColon);
					if (animationParsingStarted) syntaxError("states must be defined before animations");
					if (definedStates.count() > 0) syntaxError("states already defined");
					definedStates = parseAllStates();
				case APIdentifier(_, APAllowedExtraPoints, AITString):
					advance();
					expect(APColon);
					expect(APBracketOpen);
					if (animationParsingStarted) syntaxError("allowedExtraPoints must be defined before animations");
					if (allowedExtraPoints.length > 0) syntaxError("allowedExtraPoints already defined");
					allowedExtraPoints = parseListUntilBracket();
				case APIdentifier(_, APCenter, AITString):
					advance();
					expect(APColon);
					if (center != null) syntaxError("center already defined");
					center = parseCoordinates();
				case APIdentifier(_, APMetadata, AITString):
					advance();
					expect(APCurlyOpen);
					if (animationParsingStarted) syntaxError("metadata must be defined before animations");
					if (metadataMap.count() > 0) syntaxError("metadata already defined");
					parseMetadata();
				case APIdentifier(_, APAnimation, AITString):
					advance();
					animationParsingStarted = true;
					final animationStates = parseStates();
					for (key => value in animationStates) {
						parserValidateConditionalState(definedStates, key, value);
					}
					expect(APCurlyOpen);
					final startOfAnim = curPos();
					var parsedAnim = parseAnimation(definedStates, animationStates, allowedExtraPoints);
					if (parsedAnim.fps == null) syntaxError("fps expected", startOfAnim);
					var anim:AnimationState = {
						states: animationStates,
						name: parsedAnim.name,
						loop: parsedAnim.loop,
						fps: parsedAnim.fps,
						extraPoint: parsedAnim.extraPoints,
						playlist: parsedAnim.playlist
					};
					animations.push(anim);
				default:
					unexpectedError();
			}
		}

		// Post-parse validation
		for (key => value in definedStates) {
			definedStatesIndexes.push(key);
		}
		final allStates = createAllStates(definedStates);
		if (allStates.length > 50) {
			trace('Warning: large number of states in AnimParser: ${allStates.length}}');
		}

		for (state in allStates) {
			for (name in animationNames) {
				var anim = findAnimationInternal(name, state, animations);
				if (anim == null) syntaxError('no animation ${name} defined for states ${state}');
				else anim.visited = true;

				for (ePoint in allowedExtraPoints) {
					var p = findExtraPoint(ePoint, state, anim, definedStates);
					if (p != null) p.visited = true;
				}

				var playlist = findPlaylist(state, anim, definedStates);
				if (playlist == null) throw 'no playlist for ${state}, id ${anim.name}';
			}
		}

		for (anim in animations) {
			if (anim.visited == false) throw 'animation ${anim.name} not reachable';
			for (ek => ev in anim.extraPoint) {
				for (ePoint in ev) {
					if (ePoint.visited == false)
						throw 'Extra point ${ek} in anim ${anim.name} not reachable ${ePoint.states}';
				}
				for (pl in anim.playlist) {
					if (pl.visited == false)
						throw 'Playlist in anim ${anim.name} not reachable ${pl.states}';
				}
			}
		}
		this.metadata = metadataMap.count() > 0 ? new AnimMetadata(metadataMap) : null;
	}

	// ===================== Parse Helpers =====================

	function expectIdentifier():String {
		switch (peek()) {
			case APIdentifier(s, _, AITString | AITQuotedString):
				advance();
				return s;
			case APNumber(s):
				advance();
				return s;
			default:
				return syntaxError('expected identifier, got ${peek()}');
		}
	}

	function expectNewline():Void {
		switch (peek()) {
			case APNewLine:
				advance();
			case APEof:
			default:
				syntaxError('expected newline, got ${peek()}');
		}
	}

	function parseCoordinates():Point {
		switch (peek()) {
			case APNumber(x):
				advance();
				expect(APComma);
				switch (peek()) {
					case APNumber(y):
						advance();
						return {x: Std.parseInt(x), y: Std.parseInt(y)};
					default:
						return unexpectedError("expected y coordinate");
				}
			default:
				return unexpectedError("expected coordinates");
		}
	}

	function parseAllStates():Map<String, Array<String>> {
		var states:Map<String, Array<String>> = [];
		switch (peek()) {
			case APIdentifier(stateName, _, _):
				advance();
				expect(APOpen);
				var list = parseList();
				if (states.exists(stateName)) syntaxError('State ${stateName} already defined');
				states.set(stateName, list);
				while (match(APComma)) {
					switch (peek()) {
						case APIdentifier(sn, _, _):
							advance();
							expect(APOpen);
							var l = parseList();
							if (states.exists(sn)) syntaxError('State ${sn} already defined');
							states.set(sn, l);
						default:
							break;
					}
				}
			default:
				unexpectedError("expected state definition");
		}
		return states;
	}

	function parseStates():AnimConditionalSelector {
		var states:AnimConditionalSelector = [];
		while (true) {
			skipNewlines();
			switch (peek()) {
				case APAt:
					advance();
					expect(APOpen);
					parseConditionalState(states);
				default:
					return states;
			}
		}
	}

	function parseConditionalState(states:AnimConditionalSelector):Void {
		final stateName = expectIdentifier();

		var negated = false;
		switch (peek()) {
			case APArrow:
				advance();
			case APNotEquals:
				advance();
				negated = true;
			default:
				unexpectedError("Expected => or !=");
		}

		var condValue:AnimConditionalValue;
		switch (peek()) {
			case APBracketOpen:
				advance();
				condValue = ACVMulti(parseConditionalValueList());
			case APIdentifier(value, _, AITString | AITQuotedString):
				advance();
				condValue = ACVSingle(value);
			case APNumber(value):
				advance();
				condValue = ACVSingle(value);
			default:
				condValue = syntaxError("Expected value or [values]");
		}

		if (negated) condValue = ACVNot(condValue);

		expect(APClosed);
		states.set(stateName, condValue);
	}

	function parseConditionalValueList():Array<String> {
		var values:Array<String> = [];
		while (true) {
			values.push(expectIdentifier());
			if (match(APComma)) continue;
			expect(APBracketClosed);
			return values;
		}
	}

	function parseList():Array<String> {
		var list:Array<String> = [];
		while (true) {
			list.push(expectIdentifier());
			if (match(APComma)) continue;
			expect(APClosed);
			return list;
		}
	}

	function parseListUntilBracket():Array<String> {
		var list:Array<String> = [];
		while (true) {
			final ident = expectIdentifier();
			if (list.contains(ident)) syntaxError('extra point ${ident} already defined');
			list.push(ident);
			if (match(APComma)) continue;
			expect(APBracketClosed);
			return list;
		}
	}

	function parseMetadata():Void {
		while (true) {
			skipNewlines();
			if (match(APCurlyClosed)) break;
			final states = parseStates();
			final key = expectIdentifier();
			expect(APColon);
			switch (peek()) {
				case APNumber(numStr):
					advance();
					var entry:MetadataEntry = {states: states, value: MVInt(Std.parseInt(numStr))};
					if (metadataMap.exists(key)) metadataMap[key].push(entry);
					else metadataMap[key] = [entry];
				case APIdentifier(strVal, _, AITQuotedString):
					advance();
					var entry:MetadataEntry = {states: states, value: MVString(strVal)};
					if (metadataMap.exists(key)) metadataMap[key].push(entry);
					else metadataMap[key] = [entry];
				default:
					unexpectedError("Expected number or string value in metadata");
			}
		}
	}

	function parseAnimation(statesDefinitions, animationStates, allowedExtraPointsList) {
		var extraPoints:Map<String, Array<ExtraPoints>> = [];
		var ret = {loop: (null : Null<Int>), name: (null : Null<String>), fps: (null : Null<Int>), extraPoints: extraPoints, playlist: ([] : Array<Playlist>)};

		while (true) {
			skipNewlines();
			switch (peek()) {
				case APCurlyClosed:
					advance();
					break;
				case APIdentifier(_, APName, AITString):
					advance();
					expect(APColon);
					ret.name = expectIdentifier();
					if (!animationNames.contains(ret.name)) animationNames.push(ret.name);
				case APIdentifier(_, APLoop, AITString):
					advance();
					switch (peek()) {
						case APNewLine:
							ret.loop = -1;
						case APColon:
							advance();
							switch (peek()) {
								case APIdentifier("true" | "yes", _, _):
									advance();
									ret.loop = -1;
								case APIdentifier("false" | "no", _, _):
									advance();
									ret.loop = null;
								case APNumber(number):
									advance();
									var cnt = Std.parseInt(number);
									if (cnt <= 0) syntaxError("loop counter must be greater than 0");
									ret.loop = cnt;
								default:
									syntaxError('unknown loop value ${peek()}');
							}
						default:
							unexpectedError();
					}
				case APIdentifier(_, APFps, AITString):
					advance();
					expect(APColon);
					switch (peek()) {
						case APNumber(number):
							advance();
							if (ret.fps != null) syntaxError("fps already set");
							ret.fps = Std.parseInt(number);
							if (ret.fps <= 0) syntaxError("fps must be greater than 0");
						default:
							unexpectedError("expected fps number");
					}
				case APIdentifier(_, APExtrapoints, AITString):
					advance();
					expect(APCurlyOpen);
					if (extraPoints.count() > 0) syntaxError("extraPoints already defined");
					parseExtraPoints(statesDefinitions, animationStates, extraPoints, allowedExtraPointsList);
					if (extraPoints.count() == 0) syntaxError("extraPoints must not be empty");
				case APIdentifier(_, APPlaylist, AITString):
					advance();
					final playlistStates = parseStates();
					for (key => value in playlistStates)
						parserValidateConditionalState(statesDefinitions, key, value);
					checkForUnreachableState(animationStates, playlistStates);
					expect(APCurlyOpen);
					var playlist:Playlist = {anims: [], states: playlistStates};
					parseFrames(playlist.anims);
					ret.playlist.push(playlist);
				default:
					unexpectedError();
			}
		}

		if (ret.name == null) syntaxError("name not defined");
		if (ret.playlist.length == 0) syntaxError("animation requires playlist");
		return ret;
	}

	function parseExtraPoints(statesDefinitions, animationStates, extraPoints:Map<String, Array<ExtraPoints>>, allowedExtraPointsList:Array<String>):Void {
		while (true) {
			skipNewlines();
			if (match(APCurlyClosed)) break;
			final states = parseStates();
			final pointName = expectIdentifier();
			expect(APColon);
			final c = parseCoordinates();

			if (allowedExtraPointsList.contains(pointName) == false)
				syntaxError('extraPoint ${pointName} not declared in allowedExtraPoints');
			for (key => value in states)
				parserValidateConditionalState(statesDefinitions, key, value);
			checkForUnreachableState(animationStates, states);

			var p = {states: states, point: c};
			if (extraPoints.exists(pointName)) extraPoints[pointName].push(p);
			else extraPoints.set(pointName, [p]);
		}
	}

	function parseFrames(anims:Array<AnimPlaylistFrames>):Void {
		while (true) {
			skipNewlines();
			switch (peek()) {
				case APCurlyClosed:
					advance();
					return;
				case APIdentifier(_, APFile, AITString):
					advance();
					expect(APColon);
					switch (peek()) {
						case APIdentifier(frameFilename, _, AITQuotedString):
							advance();
							var duration:Null<Int> = tryParseDuration();
							anims.push(FileSingleFrame(frameFilename, duration));
						default:
							unexpectedError("expected filename");
					}
				case APIdentifier(_, APEvent, AITString):
					advance();
					final eventName = expectIdentifier();
					switch (peek()) {
						case APIdentifier(_, APRandom, AITString):
							advance();
							final p = parseCoordinates();
							expect(APComma);
							switch (peek()) {
								case APNumber(randomRadius):
									advance();
									final r = Std.parseInt(randomRadius);
									anims.push(PlaylistEvent(RandomPointEvent(eventName, new h2d.col.IPoint(p.x, p.y), r)));
								default:
									unexpectedError("expected radius");
							}
						case APNewLine | APSemiColon:
							advance();
							anims.push(PlaylistEvent(Trigger(eventName)));
						case APNumber(_):
							final p = parseCoordinates();
							anims.push(PlaylistEvent(PointEvent(eventName, new h2d.col.IPoint(p.x, p.y))));
						default:
							anims.push(PlaylistEvent(Trigger(eventName)));
					}
				case APIdentifier(_, APSheet, AITString):
					advance();
					expect(APColon);
					final frameName = expectIdentifier();
					match(APComma); // optional comma
					var start:Null<Int> = null;
					var end:Null<Int> = null;
					var duration:Null<Int> = null;
					switch (peek()) {
						case APIdentifier(_, APFrames, AITString):
							advance();
							expect(APColon);
							switch (peek()) {
								case APNumber(startIndex):
									advance();
									start = Std.parseInt(startIndex);
									expect(APDoubleDot);
									switch (peek()) {
										case APNumber(endIndex):
											advance();
											end = Std.parseInt(endIndex);
											if (start < 0) syntaxError('frame index must be non-negative, was $start');
											if (end < 0) syntaxError('frame index must be non-negative, was $end');
										default:
											unexpectedError("expected end index");
									}
								default:
									unexpectedError("expected start index");
							}
							match(APComma);
							duration = tryParseDuration();
						case APNewLine:
							advance();
						case APCurlyClosed:
						// don't advance - let the outer loop handle it
						default:
							unexpectedError("expected frames, newline or }");
					}
					if (start == null && end == null)
						anims.push(SheetFrameAnim(frameName, duration));
					else
						anims.push(SheetFrameAnimWithIndex(frameName, start, end, duration));
				default:
					unexpectedError();
			}
		}
	}

	function tryParseDuration():Null<Int> {
		switch (peek()) {
			case APIdentifier(_, APDuration, AITString):
				advance();
				expect(APColon);
				return parseDurationValue();
			default:
				return null;
		}
	}

	function parseDurationValue():Null<Int> {
		switch (peek()) {
			case APNumber(duration):
				advance();
				switch (peek()) {
					case APIdentifier("ms", _, AITString):
						advance();
						final d = Std.parseInt(duration);
						if (d <= 0) return syntaxError("duration must be greater than 0");
						return d;
					default:
						// Number without ms suffix - assume ms
						final d = Std.parseInt(duration);
						if (d <= 0) return syntaxError("duration must be greater than 0");
						return d;
				}
			case APIdentifier(durationStr, _, AITString):
				advance();
				if (durationStr.endsWith("ms")) {
					final d = Std.parseInt(durationStr.substring(0, durationStr.length - 2));
					if (d <= 0) syntaxError("duration must be greater than 0");
					return d;
				} else
					return syntaxError('expected <int>ms got ${durationStr}');
			default:
				return null;
		}
	}

	// ===================== State Validation =====================

	static function validateState(definedStates:Map<String, Array<String>>, name:String, value:String) {
		if (!definedStates.exists(name))
			throw 'state ${name} not defined';
		if (definedStates[name].contains(value) == false)
			throw 'state ${name} does not allow value:${value}';
	}

	static function validateStateSelector(definedStates:Map<String, Array<String>>, selector:AnimationStateSelector) {
		if (definedStates.count() != selector.count())
			throw 'invalid selector ${selector} for defined states ${definedStates}';
		for (key => value in definedStates) {
			if (selector.exists(key) == false)
				throw 'key not defined: ${key}';
			if (value.contains(selector[key]) == false)
				throw 'unknown state value ${value} not defined for key: ${key}: ${definedStates}';
		}
		for (key => value in selector) {
			if (definedStates.exists(key) == false)
				throw 'unknown state key: ${key}';
			if (definedStates[key].contains(value) == false)
				throw 'unknown state value ${value} not defined for key: ${key}: ${definedStates}';
		}
	}

	function parserValidateState(animStates:Map<String, Array<String>>, name:String, value:String) {
		try {
			validateState(animStates, name, value);
		} catch (e) {
			syntaxError(e.message);
		}
	}

	function parserValidateConditionalState(animStates:Map<String, Array<String>>, name:String, value:AnimConditionalValue) {
		switch value {
			case ACVSingle(v):
				parserValidateState(animStates, name, v);
			case ACVMulti(values):
				for (v in values) parserValidateState(animStates, name, v);
			case ACVNot(inner):
				parserValidateConditionalState(animStates, name, inner);
		}
	}

	function checkForUnreachableState(parentState:AnimConditionalSelector, childState:AnimConditionalSelector) {
		for (key => childValue in childState) {
			if (!parentState.exists(key)) continue;
			final parentValue = parentState[key];
			switch [parentValue, childValue] {
				case [ACVSingle(pv), ACVSingle(cv)]:
					if (pv != cv)
						syntaxError('unreachable state ${childState}, limited by ${parentState}');
					else
						syntaxError('useless state limit ${childState}, limited by ${parentState}');
				case _:
			}
		}
		return true;
	}

	// ===================== Static Utility Methods =====================

	public static function matchConditionalValue(condValue:AnimConditionalValue, runtimeValue:String):Bool {
		return switch condValue {
			case ACVSingle(v): v == runtimeValue;
			case ACVMulti(vs): vs.contains(runtimeValue);
			case ACVNot(inner): !matchConditionalValue(inner, runtimeValue);
		};
	}

	public static function countStateMatch(match:AnimConditionalSelector, selector:AnimationStateSelector) {
		var retVal = 0;
		for (key => value in selector) {
			if (match.exists(key)) {
				if (matchConditionalValue(match[key], value))
					retVal++;
				else
					retVal -= 10000;
			}
		}
		return retVal;
	}

	public static function findPlaylist(stateSelector:AnimationStateSelector, animation:AnimationState, definedStates:Map<String, Array<String>>) {
		validateStateSelector(definedStates, stateSelector);
		var bestScore = -1;
		var best2Score = -1;
		var best:Null<Playlist> = null;
		var best2:Null<Playlist> = null;
		for (p in animation.playlist) {
			final count = countStateMatch(p.states, stateSelector);
			if (count > bestScore) {
				best2Score = bestScore;
				best2 = best;
				best = p;
				bestScore = count;
			} else if (bestScore == count) {
				best2 = best;
				best = p;
				best2Score = bestScore;
			}
		}
		if (best != null && best2Score == bestScore)
			throw 'ambiguous playlist: ${animation.name} ${best.states} ${best2.states} selector: ${stateSelector}';
		return best;
	}

	public static function findExtraPoint(extraPointName:String, stateSelector:AnimationStateSelector, animation:AnimationState,
			definedStates:Map<String, Array<String>>) {
		validateStateSelector(definedStates, stateSelector);
		var bestScore = -1;
		var best2Score = -1;
		var best:Null<ExtraPoints> = null;
		var best2:Null<ExtraPoints> = null;
		final allExtraPoints = animation.extraPoint.get(extraPointName);
		if (allExtraPoints == null) return null;

		for (p in allExtraPoints) {
			final count = countStateMatch(p.states, stateSelector);
			if (count > bestScore) {
				best2Score = bestScore;
				best2 = best;
				best = p;
				bestScore = count;
			} else if (bestScore == count) {
				best2 = best;
				best = p;
				best2Score = bestScore;
			}
		}
		if (best != null && best2Score == bestScore)
			throw 'ambiguous extraPoint: ${extraPointName} ${best.states} ${best2.states} selector: ${stateSelector}';
		return best;
	}

	public static function findAnimation(name:String, stateSelector:AnimationStateSelector, definedStates, animations) {
		validateStateSelector(definedStates, stateSelector);
		return findAnimationInternal(name, stateSelector, animations);
	}

	public static function findAnimationInternal(name:String, stateSelector:AnimationStateSelector, animations:Array<AnimationState>) {
		var bestScore = -1;
		var best:Null<AnimationState> = null;
		for (a in animations) {
			if (name != a.name) continue;
			var count = countStateMatch(a.states, stateSelector);
			if (count > bestScore) {
				best = a;
				bestScore = count;
			} else if (bestScore == count) {
				throw 'ambiguous animation: ${a.name}:${a.states}, ${best.name}:${best.states}';
			}
		}
		return best;
	}

	// ===================== Runtime Methods =====================

	function createAllStates(statesDefinitions:Map<String, Array<String>>) {
		var totalStates = 1;
		var stateValuesCount = [];
		var stateKeys = [];
		var retVal = [];
		for (key => value in statesDefinitions) {
			totalStates *= value.length;
			stateValuesCount.push(value.length);
			stateKeys.push(key);
		}
		for (i in 0...totalStates) {
			final x:AnimationStateSelector = [];
			var ci = i;
			for (ki in 0...stateKeys.length) {
				final vi = ci % stateValuesCount[ki];
				ci = Std.int(ci / stateValuesCount[ki]);
				var key = stateKeys[ki];
				x.set(key, statesDefinitions[key][vi]);
			}
			retVal.push(x);
		}
		return retVal;
	}

	function createStates(anims:Array<AnimPlaylistFrames>, anim:AnimationState, stateSelector:AnimationStateSelector):Array<AnimationFrameState> {
		function replaceState(inputStr:String, stateSelector:AnimationStateSelector) {
			var result = inputStr;
			for (key => value in stateSelector) {
				result = result.replace('$$$$${key}$$$$', value);
			}
			return result;
		}

		function tileToFrame(tile:h2d.Tile, duration:Float):AnimationFrameState {
			if (center != null) {
				tile.dx = -center.x;
				tile.dy = -center.y;
			}
			return Frame(new AnimationFrame(tile, duration, 0, 0, tile.iwidth, tile.iheight));
		}

		function AFtoFrame(f:AnimationFrame, duration:Float):AnimationFrameState {
			if (center != null) {
				f.tile.dx = f.offsetx - center.x;
				f.tile.dy = (f.height - f.tile.height) - f.offsety - center.y;
			}
			return Frame(f.cloneWithDuration(duration));
		}

		var retVal = [];
		final duration = 1.0 / anim.fps;
		for (frames in anims) {
			switch frames {
				case SheetFrameAnim(name, overrideDuration):
					final expandedName = replaceState(name, stateSelector);
					final sheet = resourceLoader.loadSheet2(sheetName);
					if (sheet == null) throw 'sheet ${sheetName} not found';
					final loadedTiles = sheet.getAnim(expandedName);
					if (loadedTiles == null) throw 'tiles ${name}->${expandedName} not found';
					var tiles = sheet.getAnim(expandedName);
					var d = overrideDuration == null ? duration : overrideDuration / 1000.0;
					retVal = retVal.concat(Lambda.map(tiles, t -> AFtoFrame(t, d)));
				case SheetFrameAnimWithIndex(name, from, to, overrideDuration):
					final sheet = resourceLoader.loadSheet2(sheetName);
					if (sheet == null) throw 'sheet ${sheetName} not found';
					final expandedName = replaceState(name, stateSelector);
					final animTiles = sheet.getAnim(expandedName);
					if (animTiles == null) throw 'tiles ${name}->${expandedName} not found';
					var d = overrideDuration == null ? duration : overrideDuration / 1000.0;
					for (i in 0...animTiles.length) {
						if ((from == null || i >= from) && (to == null || i <= to)) {
							retVal.push(AFtoFrame(animTiles[i], d));
						}
					}
				case FileSingleFrame(filename, overrideDuration):
					var d = overrideDuration == null ? duration : overrideDuration / 1000.0;
					retVal.push(tileToFrame(resourceLoader.loadTile(filename), d));
				case PlaylistEvent(playlistEvent):
					retVal.push(Event(playlistEvent));
			}
		}
		return retVal;
	}

	function selectorToHex(selector:AnimationStateSelector) {
		if (selector.count() == 0) return "";
		var indexes = Bytes.alloc(definedStatesIndexes.length);
		indexes.fill(0, indexes.length, 255);
		for (key => value in selector) {
			final idx = definedStatesIndexes.indexOf(key);
			if (idx == -1) throw 'invalid selector key ${key}';
			final value = definedStates[key].indexOf(value);
			indexes.set(idx, value);
		}
		return indexes.toHex();
	}

	function hexToSelector(hex:String) {
		var selector:AnimationStateSelector = [];
		if (hex.length == 0) return selector;
		var indexes = Bytes.ofHex(hex);
		for (i in 0...indexes.length) {
			final key = definedStatesIndexes[i];
			final byteValue = indexes.get(i);
			selector.set(key, definedStates[key][byteValue]);
		}
		return selector;
	}

	public function load(stateSelector:AnimationStateSelector, animSM:AnimationSM) {
		var hex = selectorToHex(stateSelector);
		if (!cache.exists(hex)) {
			var cacheArray = [];
			for (name in animationNames) {
				final anim = findAnimation(name, stateSelector, definedStates, animations);
				if (anim == null) throw 'null anim ${name}';
				final playlist = findPlaylist(stateSelector, anim, definedStates);
				if (playlist == null) throw 'null playlist for anim ${name}';
				var states = createStates(playlist.anims, anim, stateSelector);
				final extraPoints = new Map<String, h2d.col.IPoint>();
				for (pointName in allowedExtraPoints) {
					var pt = findExtraPoint(pointName, stateSelector, anim, definedStates);
					if (pt != null) extraPoints.set(pointName, pt.toPoint());
				}
				final loopCount = anim.loop == null ? 0 : anim.loop;
				cacheArray.push({name: name, states: states, loopCount: loopCount, extraPoints: extraPoints});
			}
			cache.set(hex, cacheArray);
		}

		final cacheEntries = cache.get(hex);
		for (e in cacheEntries) {
			animSM.addAnimationState(e.name, e.states, e.loopCount, e.extraPoints);
		}
	}

	public function createAnimSM(stateSelector:AnimationStateSelector):AnimationSM {
		var animSM = new AnimationSM(stateSelector);
		load(stateSelector, animSM);
		return animSM;
	}
}
