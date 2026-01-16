package bh.stateanim;
import hxparse.Unexpected;
import bh.base.Atlas2;
import bh.base.ResourceLoader;
import haxe.io.Bytes;
import bh.stateanim.AnimationSM;
import hxparse.ParserError;
import bh.base.Point;
using StringTools;
using bh.base.MapTools;


// HELP: https://github.com/darmie/wrenparse/blob/e5b903afffba852c40b195d8558a3c11f46e79f6/src/wrenparse/WrenParser.hx
// https://github.com/chipshort/PseudoCode/blob/03dd511375b7ee6a5df1062bcdc21ce4e84aab37/src/pseudocode/PseudoParser.hx
// https://github.com/Aidan63/ptrparser/blob/94d07c0b8a20da7f56dad6cd9ee786b6feb7cfc6/src/PtrParser.hx


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
}
  
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
	APGoto;
	APCommand;
	APUntilCommand;
	APEvent;
	APDuration;
	APRandom;
	APFrames;
}

 

class AnimLexer extends hxparse.Lexer implements hxparse.RuleBuilder {
	static var buf:StringBuf = null;
	static var keywords = @:mapping(2,true) APKeywords;
	static var integer = '([1-9](_?[0-9])*)|0';
	static public var tok = @:rule [
		integer => APNumber(lexer.current),
		"-?[0-9]+" => APNumber(lexer.current),
		"[@|#|!]?[a-zA-Z0-9_\\-\\$]+" => {
			var str = lexer.current;
			var type = AITString;
			return APIdentifier(str, keywords.get(str.toLowerCase()), type);
		},
		"\\[" => APBracketOpen,
		"\\]" => APBracketClosed,
		"\\.\\."=>APDoubleDot,
		"\\(" => APOpen,
		"\\)" => APClosed,
		"\\{" => APCurlyOpen,
		"\\}" => APCurlyClosed,
		"," => APComma,
		"\\@" => APAt,
		":" => APColon,
		";" => APSemiColon,
		"=>" => APArrow,
		"[\n\r]" => APNewLine,
		"//[^\n\r]*" => lexer.token(tok),
		"[ \t]" => lexer.token(tok),
		'"' => {
			buf = new StringBuf();
			lexer.token(string);
			APIdentifier(buf.toString(), null, AITQuotedString);
		},
		"" => APEof,
	];

	static var string = @:rule [
		'\\\\"' => {
			buf.addChar('"'.code);
			lexer.token(string);
		},
		"\\\\u[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]" => {
			buf.add(String.fromCharCode(Std.parseInt("0x" + lexer.current.substr(2))));
			lexer.token(string);
		},
		'"' => {
			lexer.curPos().pmax;
		},
		'[^"]' => {
			buf.add(lexer.current);
			lexer.token(string);
		}
	];
}

typedef LoadedAnimation = {
	var sheet:String;
	var states:Map<String, Array<String>>;
	var allowedExtraPoints:Array<String>;
	var ?center:Point;
	var animations:Array<AnimationState>;
}

@:using(AnimParser.ExtraPointsHelper)
typedef ExtraPoints = {
	var states:AnimationStateSelector;
	var point:Point;
	var ?visited:Bool;
}

enum AnimPlaylistFrames {
	SheetFrameAnim(name:String, durationMilliseconds: Null<Int>);
	SheetFrameAnimWithIndex(name:String, from:Null<Int>, to:Null<Int>, durationMilliseconds: Null<Int>);
	FileSingleFrame(filename:String, durationMilliseconds: Null<Int>);
	Loop(frames:Array<AnimPlaylistFrames>, condition:AnimationFrameCondition);
	ChangeState(newState:String);
	AnimExitPoint;
	PlaylistEvent(playlistEvent:AnimationPlaylistEvent);
}


typedef Playlist = {
	var states:AnimationStateSelector;
	var anims:Array<AnimPlaylistFrames>;
	var ?visited:Bool;
}


typedef AnimationState = {
	var name:String;
	var states:AnimationStateSelector;
	var fps:Null<Int>;
	var loop:Null<AnimationFrameCondition>;
	var extraPoint:Map<String, Array<ExtraPoints>>;
	var playlist:Array<Playlist>;
	var ?visited:Bool;
}

class ExtraPointsHelper {
	public static function toPoint(pt:ExtraPoints) {
		return new h2d.col.IPoint(pt.point.x, pt.point.y);
	}
}
class AnimUnexpected<Token> extends Unexpected<Token> {
	final message:String;
	final input:byte.ByteData;

	public function new(token:Token, pos, message, input) {
		super(token, pos);
		this.token = token;
		this.message = message;
		this.input = input;
	}

	override public function toString() {
		return '${message}: unexpected $token at ${this.pos.format(input)}';
	}
}

class InvalidSyntax extends ParserError {
	public var error:String;

	public function new(error, pos, input) {
		super(pos);
		this.error = toStringWithInput(error, pos, input);
	}

	public override function toString() {
		return error;
	}

	static function toStringWithInput(err, pos, input) {
		return 'Error ${err}, ${pos.format(input)}';
	}
}

typedef AnimationStateSelector = Map<String, String>;

interface AnimParserResult {
	var definedStates(default, never):Map<String, Array<String>>;
	function createAnimSM(stateSelector:AnimationStateSelector):AnimationSM;
}


class AnimParser extends hxparse.Parser<hxparse.LexerTokenSource<APToken>, APToken> implements hxparse.ParserBuilder implements AnimParserResult{

	var animations:Array<AnimationState> = [];
	var animationNames = [];
	var allowedExtraPoints:Array<String> = [];
	public var definedStates(default, null):Map<String, Array<String>> = [];
	var definedStatesIndexes:Array<String> = []; // Provides state to index mapping
	var sheetName:String;
	var center:Null<Point> = null;
	var cache:Map<String, Array<{name:String, states:Array<AnimationFrameState>, extraPoints:Map<String, h2d.col.IPoint>}>>=[];
	final resourceLoader:bh.base.ResourceLoader;

	var input:byte.ByteData;

	static function validateState(definedStates:Map<String, Array<String>>, name:String, value:String) {
		if (!definedStates.exists(name)) throw 'state ${name} not defined';
		if (definedStates[name].contains(value) == false) throw 'state ${name} does not allow value:${value}';
	}

	static function validateStateSelector(definedStates:Map<String, Array<String>>, selector:AnimationStateSelector) {
		if (definedStates.count() != selector.count()) throw 'invalid selector ${selector} for defined states ${definedStates}';
		for (key => value in definedStates) {
			if (selector.exists(key) == false)	throw 'key not defined: ${key}';
			if (value.contains(selector[key]) == false)	throw 'unknown state value ${value} not defined for key: ${key}: ${definedStates}';
		}

		for (key => value in selector) {
			if (definedStates.exists(key) == false)	throw 'unknown state key: ${key}';
			if (definedStates[key].contains(value) == false)	throw 'unknown state value ${value} not defined for key: ${key}: ${definedStates}';
		}
	}

	function parserValidateState(animStates:Map<String, Array<String>>, name:String, value:String) {
		try {
			validateState(animStates, name, value);
		} catch(e) {
			syntaxError(e.message);
		}
	}

	static function countStateMatch(match:AnimationStateSelector, selector:AnimationStateSelector) {
		var retVal = 0;
		for (key => value in selector) {
			if (match.exists(key)) {
				if (match[key] == value) retVal++;
				else retVal -= 10000;
			} 
		} 
		return retVal;
	}

	static function matchSelectorExact(selector1:AnimationStateSelector, selector2:AnimationStateSelector) {
		if (selector1.count() != selector2.count()) return false;

		for (key => value in selector1) {
			if (!selector2.exists(key)) return false;
			if (selector2.get(key) != value) return false;
		} 
		return true;
	}

	function createAllStates(statesDefinitions:Map<String, Array<String>>) {
		var totalStates  = 1;
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
			// trace(selectorToHex(x));
			// trace(hexToSelector(selectorToHex(x)));
			retVal.push(x);
		}
		return retVal;
	}

	public static function findPlaylist(stateSelector:AnimationStateSelector, animation:AnimationState, definedStates:Map<String, Array<String>>){
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
		if (best != null && best2Score == bestScore) throw 'ambigious playlist: ${animation.name} ${best.states} ${best2.states} selector: ${stateSelector}';
		return best;
	}

	public static function findExtraPoint(extraPointName:String, stateSelector:AnimationStateSelector, animation:AnimationState, definedStates:Map<String, Array<String>>){
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

		if (best != null && best2Score == bestScore) throw 'ambigious extraPoint: ${extraPointName} ${best.states} ${best2.states} selector: ${stateSelector}';
		return best;
	}

	public static function findAnimation(name:String, stateSelector:AnimationStateSelector, definedStates, animations){
		validateStateSelector(definedStates, stateSelector);
		return findAnimationInternal(name, stateSelector, animations);
	}

	public static function findAnimationInternal(name:String, stateSelector:AnimationStateSelector, animations:Array<AnimationState>){
		var bestScore = -1;
		var best:Null<AnimationState> = null;
		for (a in animations) {
			if (name != a.name) continue;
			var count = countStateMatch(a.states, stateSelector);
			
			if (count > bestScore) {
				best = a;
				bestScore = count;
			} else if (bestScore == count) {
				throw 'ambigious animation: ${a.name}:${a.states}, ${best.name}:${best.states}';
			}
		}
//		trace('${stateSelector}, ${bestScore}');
		return best;
	}

	function checkForUnreachableState(parentState:AnimationStateSelector, childState:AnimationStateSelector) {
		for (key => value in childState) {
			if (!parentState.exists(key)) continue;
			if (parentState[key] != value) syntaxError('unreachable state ${childState}, limited by ${parentState}');
			else syntaxError('useless state limit ${childState}, limited by ${parentState}');
		}
		return true;
	}

	function syntaxError(error, ?pos):Dynamic {
		final error = new InvalidSyntax(error, pos == null ? stream.curPos(): pos, input);
		trace(error);
		throw error;
	}

	function unexpectedError(?message:String):Dynamic {
		final error = new AnimUnexpected(peek(0), stream.curPos(), message, input);
		trace(error);
		throw error;
	}

	public static function parseFile(input:byte.ByteData, sourceName:String, resourceLoader):AnimParserResult {
		try {
			var p = new AnimParser(input, sourceName, resourceLoader);
			p.parse();
			return p;
		} catch (ue:hxparse.Unexpected<Any>) {
			throw new AnimUnexpected(ue.token, ue.pos, ue.toString(), input);
		} catch (e) {
			trace(e);
			throw e;
		}
	}

	function new(input:byte.ByteData, sourceName:String, resourceLoader) {
		this.resourceLoader = resourceLoader;
		this.input = input;
		var lexer = new AnimLexer(input, sourceName);
		var ts = new hxparse.LexerTokenSource(lexer, AnimLexer.tok);
		super(ts);
	}

	function parse():LoadedAnimation {
		var animationParsingStarted = false;
		while (true) {

			switch stream {
				case [APIdentifier(_, APSheet, AITString), APColon, APIdentifier(value, _, AITString|AITQuotedString), APNewLine]:
					if (animationParsingStarted) syntaxError("sheet must be defined before animations");
					if (sheetName != null) syntaxError("sheet already defined");
					sheetName = value;
				case [APIdentifier(_, APStates, AITString), APColon, s = parseAllStates([])]:
					if (animationParsingStarted) syntaxError("states must be defined before animations");
					if (definedStates.count() > 0) syntaxError("states already defined");
					definedStates = s;
				case [APIdentifier(_, APAllowedExtraPoints, AITString), APColon, APBracketOpen, list = parseListUntilBracket()]:
					if (animationParsingStarted) syntaxError("allowedExtraPoints must be defined before animations");
					if (allowedExtraPoints.length > 0) syntaxError("allowedExtraPoints already defined");
						allowedExtraPoints = list;
				case [APIdentifier(_, APCenter, AITString), APColon, c = parseCoordinates()]:
					if (center != null) syntaxError("center already defined");
					center = c;

				case [APIdentifier(_, APAnimation, AITString), animationStates = parseStates([]), APCurlyOpen]:
					animationParsingStarted = true;
					for (key => value in animationStates) {
						parserValidateState(definedStates, key, value);
					}
					final startOfAnim = this.curPos();
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

				case [APEof]:
//					trace('EOF');
					break;
				case [APNewLine]: // skip newlines
				case _: unexpected();
			}
		}

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
			
				for (epoint in allowedExtraPoints) {
					var p = findExtraPoint(epoint, state, anim, definedStates);
					if (p != null) p.visited = true;
				}
			
				var playlist = findPlaylist(state, anim, definedStates);
				if (playlist == null) throw 'no playlist for ${state}, id ${anim.name}';

			}
		}
		

		for (anim in animations) {
			if (anim.visited == false) throw 'animation ${anim.name} not reachable';
			for (ek => ev in anim.extraPoint) {
				for (epoint in ev) {
					if (epoint.visited == false) throw 'Extra point ${ek} in anim ${anim.name} not reachable ${epoint.states}';
				}

				for (pl in anim.playlist) {
					if (pl.visited == false) throw 'Playlist in anim ${anim.name} not reachable ${pl.states}';
				}
			}
		}
		return {
			sheet: sheetName,
			states: definedStates,
			allowedExtraPoints: allowedExtraPoints,
			center: center,
			animations: animations,
		}
	}

	public function parseExtraPoints(statesDefinitions, animationStates, extraPoints:Map<String, Array<ExtraPoints>>, allowedExtraPoints:Array<String>) {
				while (true) {
					switch stream {
						case [APNewLine]: 
						case [APCurlyClosed]: break;
						case [states = parseStates([]), APIdentifier(pointName, _), APColon,  c = parseCoordinates()]:
							
							if (allowedExtraPoints.contains(pointName) == false) syntaxError('extraPoint ${pointName} not declared in allowedExtraPoints');
							for (key => value in states) {
								parserValidateState(statesDefinitions, key, value);
							}
							checkForUnreachableState(animationStates, states);
							
							var p = {states: states, point: c};
							if (extraPoints.exists(pointName)) 
							{
								extraPoints[pointName].push(p);
							} else {
								extraPoints.set(pointName, [p]);
							}
						case _: unexpectedError();
					}
				}
	}

	public function parseAnimation(statesDefinitions, animationStates, allowedExtraPoints) {
		var extraPoints:Map<String, Array<ExtraPoints>> = [];
		var ret = {loop: null, name:null, fps:null, extraPoints:extraPoints, playlist:[]};

		while (true) {
			switch stream {
				case [APIdentifier(_, APName, AITString), APColon, APIdentifier(name, _, AITString|AITQuotedString)|APNumber(name)]:
					if (!animationNames.contains(name)) animationNames.push(name);
					ret.name = name;
				case [APIdentifier(_, APLoop, AITString)]:
					switch stream {
						case [APNewLine]: ret.loop = FOREVER;
						case [APColon ]:
							switch stream {
								case [APIdentifier("true"|"yes", _)]: ret.loop = FOREVER; 
								case [APIdentifier("false"|"no", _)]: ret.loop = null; 
								case [APIdentifier(_, APUntilCommand, AITString)]: ret.loop = AFC_UNTIL_COMMAND;
								case [APNumber(number)]: 
									var cnt = Std.parseInt(number);
									if (cnt <= 0) syntaxError("loop counter must be greater than 0");
									ret.loop = AFC_COUNT(cnt);
								case _: syntaxError('unknown bool value ${peek(0)}');
							}
						case _: unexpectedError();
					}
					
				case [APIdentifier(_, APFps, AITString), APColon, APNumber(number)]:
					if (ret.fps != null) syntaxError("fps already set");
					ret.fps = Std.parseInt(number);
					if (ret.fps <= 0) syntaxError("fps must be greater than 0");
				case [APIdentifier(_, APExtrapoints, AITString), APCurlyOpen]:				
					if (extraPoints.count() > 0) syntaxError("extraPoints already defined");
					parseExtraPoints(statesDefinitions, animationStates, extraPoints, allowedExtraPoints);
					if (extraPoints.count() == 0) syntaxError("extraPoints must not be empty");

				case [APIdentifier(_, APPlaylist, AITString), playlistStates = parseStates([]), APCurlyOpen]:
					var playlist:Playlist = {anims: [], states: playlistStates};
					for (key => value in playlistStates) {
						parserValidateState(statesDefinitions, key, value);
					}
					checkForUnreachableState(animationStates, playlistStates);

					parseFrames(playlist.anims);
					ret.playlist.push(playlist);

				case [APNewLine]: // skip newlines
				
				case [APCurlyClosed]: break;
				case _: unexpectedError();
			}
		}

		if (ret.name == null) syntaxError("name not defined");
		if (ret.playlist.length == 0) syntaxError("animation requires playlist");
		
		return ret;
	}

	function parseFrames(anims:Array<AnimPlaylistFrames>, isLoop = false):Array<AnimPlaylistFrames> {
		var exit = false;
		while (!exit) {
			switch stream {
				case [APNewLine]: 
				case [APIdentifier(_, APLoop, AITString)]:
					var condition:AnimationFrameCondition = FOREVER;
					switch stream {
						case [APCurlyOpen]:
						case [APNumber(loopCountStr), APCurlyOpen]: 
							var loopCount = Std.parseInt(loopCountStr);
							if (loopCount <= 0) throw 'loop count must be greater than 0';
							condition = AFC_COUNT(loopCount);
						case [APIdentifier(_, APUntilCommand, AITString), APCurlyOpen]: 
							condition = AFC_UNTIL_COMMAND;
						case _: syntaxError("invalid loop, count:Int, untilCommand or { expected");
					}
					var loopFrames = parseFrames([], true);
					anims.push(Loop(loopFrames, condition));
					
				case [APIdentifier(_, APFile, AITString), APColon, APIdentifier(frameFilename, _, AITQuotedString)]: 
					var duration:Null<Int> = null;
							switch stream {
								case [APIdentifier(_, APDuration, AITString),  d = parseDuration()]:
									duration = d;
								case _:
							}
							anims.push(FileSingleFrame(frameFilename, duration));
					
				case [APIdentifier(_, APEvent, AITString), APIdentifier(eventName, _)]:
					switch stream {
						case [APIdentifier(_, APRandom, AITString), p = parseCoordinates(), APComma, APNumber(randomRadius)]:
							final r = Std.parseInt(randomRadius);
							anims.push(PlaylistEvent(RANDOM_POINT_EVENT(eventName, new h2d.col.IPoint(p.x, p.y), r)));
						case [APNewLine|APSemiColon]:
							anims.push(PlaylistEvent(TRIGGER(eventName)));
						case [p = parseCoordinates()]:							
						 	anims.push(PlaylistEvent(POINT_EVENT(eventName, new h2d.col.IPoint(p.x, p.y))));
						case _: unexpectedError();
					}
					
				case [APIdentifier(_, APCommand, AITString)]:
					anims.push(AnimExitPoint);
				case [APIdentifier(_, APGoto, AITString), APIdentifier(stateName, _)]:
					anims.push(ChangeState(stateName));
				case [APIdentifier(_, APSheet, AITString),APColon, APIdentifier(frameName, _, AITString|AITQuotedString)]:
					{
					var start = null;
					var end = null;
					var duration:Null<Int> = null;
					switch stream {
					 	case [APComma]:
					 	case _: 
					}

					switch stream {
						case [APIdentifier(_, APFrames, AITString), APColon, APNumber(startIndex), APDoubleDot, APNumber(endIndex)]:
							var start = Std.parseInt(startIndex);
							var end = Std.parseInt(endIndex);

							switch stream {
								case [APIdentifier(_, APDuration, AITString), APColon, d = parseDuration()]:
									duration = d;
								case [APComma, APIdentifier(_, APDuration, AITString), APColon, d = parseDuration()]:
									duration = d;
								case _:
							}

						case [APNewLine]:
						case [APCurlyClosed]:
							exit = true;
						case _: unexpectedError();

					}
					if (start == null && end == null) anims.push(SheetFrameAnim(frameName, duration));
					else anims.push(SheetFrameAnimWithIndex(frameName, start, end, duration));

				}
				case [APCurlyClosed]: 
					exit = true;
				case _: unexpectedError();
			}
		}
		return anims;
	}

	public function parseCoordinates():Point {
		switch stream {
			case [APNumber(x), APComma, APNumber(y)]:
				return {x: Std.parseInt(x), y: Std.parseInt(y)}
			case _: unexpectedError();
		}
		return null;
	}

	function eatComma() {
		switch stream {
			case [APComma]:
			case _:
		}
	}

	public function parseAllStates(animStates:Map<String, Array<String>>) {
		switch stream {
			case [APIdentifier(stateName, _), APOpen, list = parseList([])]:
				if (animStates.exists(stateName)) syntaxError('State ${stateName} already defined');
				animStates.set(stateName, list);
				switch stream {
					case [APComma]: parseAllStates(animStates);
					case [APNewLine]:
				}

			case _: unexpectedError();
		}
		return animStates;
	}

	public function parseStates(states:AnimationStateSelector) {
		while (true) {
				switch stream {
					case [APAt, APOpen, APIdentifier(stateName, _, AITString | AITQuotedString), APArrow, (APIdentifier(stateValue, _, AITString | AITQuotedString) | APNumber(stateValue)), APClosed]:
						states.set(stateName, stateValue);
					case [APNewLine]:
					case _: return states;
				}
				
		}
	}

	public function parseList(list:Array<String>) {
		switch stream {
			case [APIdentifier(ident, _) | APNumber(ident)]:
				list.push(ident);
				switch stream {
					case [APComma]: parseList(list);
					case [APClosed]: return list;
				}

			case _: unexpectedError();
		}
		return list;
	}

	function parseDuration():Null<Int> {
	
		switch stream {
			case [APNumber(duration), APIdentifier("ms", _)]:
				final d = Std.parseInt(duration);
				if (d <= 0) return syntaxError("duration must be greater than 0");
				return d;
			case [APIdentifier(durationStr, _, AITString)]:
				if (durationStr.endsWith("ms")) {
					
					final d = Std.parseInt(durationStr.substring(0, durationStr.length -2));
					if (d <= 0) syntaxError("duration must be greater than 0");
					return d;
	
				} else return syntaxError('expected <int>ms got ${durationStr}');
			case _: return null;
		}
	}
	
	public function parseListUntilBracket() {
		var list = [];
		while (true) {
			switch stream {
				case [APIdentifier(ident, _)]:
					if (list.contains(ident)) syntaxError('extra point ${ident} already defined');
					list.push(ident);
				switch stream {
					case [APComma]: 
					case [APBracketClosed]: return list;
					}
				case _: unexpectedError();
			}
		}
		return list;
	}


	function createStates(anims:Array<AnimPlaylistFrames>, anim:AnimationState, stateSelector:AnimationStateSelector, level:Int):Array<AnimationFrameState> {
		
		function replaceState(input:String, stateSelector:AnimationStateSelector) {
			var result = input;
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
			return AF_FRAME(new AnimationFrame(tile, duration,0,0,tile.iwidth,tile.iheight));
		}

		function AFtoFrame(f:AnimationFrame, duration:Float):AnimationFrameState {
			if (center != null) {
				f.tile.dx = f.offsetx - center.x;
				f.tile.dy = (f.height-f.tile.height) - f.offsety - center.y;

			}
			return AF_FRAME(f.cloneWithDuration(duration));
		}
		function commandsToDebugString(anims:Array<AnimationFrameState>, markIndex:Int) {
			final buf = new StringBuf();
			for (index in 0...anims.length) {
				
				buf.add('${index}: ${anims[index]}');
				if (index == markIndex) buf.add('\t\t\t<----- HERE');
				buf.add('\n');
			}
			return buf.toString();
		}

		function isInfiniteLoop(anims:Array<AnimationFrameState>, from:Int, to:Int):Bool {
			for(index in from...to) {
				switch anims[index] {
					case AF_EXITPOINT: return false;
					default:
				}
			}
			switch anims[to] {
				case AF_LOOP(destIndex, condition):
					return switch condition {
						case FOREVER: true;
						case AFC_COUNT(repeatCount): false;
						case AFC_UNTIL_COMMAND: false;
					}
				default: throw 'expected loop';
			}
			return true;
		}

		var retVal = [];
		final duration = 1.0/anim.fps;
		for (frames in anims) {
			switch frames {
				case SheetFrameAnim(name, overrideDuration):
					final expandedName = replaceState(name, stateSelector);
					final sheet = resourceLoader.loadSheet2(sheetName);
					if (sheet == null) throw 'sheet ${sheetName} not found';
					final loadedTiles = sheet.getAnim(expandedName);
					if (loadedTiles == null) throw 'tiles ${name}->${expandedName} not found';
					var tiles = sheet.getAnim(expandedName);
					var d = overrideDuration == null ? duration : overrideDuration/1000.0;
					retVal = retVal.concat(Lambda.map(tiles, t -> AFtoFrame(t, d)));
				case SheetFrameAnimWithIndex(name, from, to, overrideDuration):
					final sheet = resourceLoader.loadSheet2(sheetName);
					if (sheet == null) throw 'sheet ${sheetName} not found';
					final expandedName = replaceState(name, stateSelector);
					final animTiles = sheet.getAnim(expandedName);
			
					if (animTiles == null) throw 'tiles ${name}->${expandedName} not found';
					var d = overrideDuration == null ? duration : overrideDuration/1000.0;
					for (i in 0...animTiles.length) {
						if ((from == null || i >= from) && (to == null || i <= to )) {
							retVal.push(AFtoFrame(animTiles[i], d));
						}

					}
				case FileSingleFrame(filename, overrideDuration): 
					var d = overrideDuration == null ? duration : overrideDuration / 1000.0;
					retVal.push(tileToFrame(resourceLoader.loadTile(filename), d));
				case AnimExitPoint:
					retVal.push(AF_EXITPOINT);
				case PlaylistEvent(playlistEvent):
					retVal.push(AF_EVENT(playlistEvent));
				case ChangeState(newState): 
					if (!animationNames.contains(newState)) throw 'invalid goto ${newState}';
					retVal.push(AF_CHAGE_STATE(newState));
				case Loop(anims2, condition): 
					var startIndex = retVal.length;
					
					var loopStates = createStates(anims2, anim, stateSelector, level + 1);
					retVal = retVal.concat(loopStates);
					retVal.push(AF_LOOP(startIndex, condition));
					if (isInfiniteLoop(retVal, startIndex, retVal.length-1)) throw('infinite loop detected in ${anim.name}, states:${stateSelector}, \n${commandsToDebugString(retVal, retVal.length-1)}');
			}
		}

		if (anim.loop != null && level == 0) {
			
			// if (retVal.length > 0 && retVal[retVal.length-1].match(AF_LOOP(_,_))) {
			// 	throw 'animation level loop and ending playlist loop detected';
			// }
			retVal.push(AF_LOOP(0, anim.loop));
			if (isInfiniteLoop(retVal, 0, retVal.length-1)) throw('infinite loop detected in ${anim.name}, states:${stateSelector}\n${commandsToDebugString(retVal, retVal.length-1)}');
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

	public function load(stateSelector:AnimationStateSelector, animSM:AnimationSM){
		var hex = selectorToHex(stateSelector);
		if (!cache.exists(hex)) {

			var cacheArray = [];
			for (name in animationNames) {
				final anim = findAnimation(name, stateSelector, definedStates, animations);
				if (anim == null) throw 'null anim ${name}';
				final playlist = findPlaylist(stateSelector, anim, definedStates);
				if (playlist == null) throw 'null playlist for anim ${name}';
				
				var states = createStates(playlist.anims, anim, stateSelector, 0);

				final extraPoints = new Map<String, h2d.col.IPoint>();
				for(pointName in allowedExtraPoints) {
					var pt = findExtraPoint(pointName, stateSelector, anim, definedStates);
					if (pt != null) extraPoints.set(pointName, pt.toPoint());
				}
				cacheArray.push({name:name, states:states, extraPoints:extraPoints});
				
			}
			cache.set(hex, cacheArray);
		}
		
		final cacheEntries = cache.get(hex);
		for (e in cacheEntries) {
			animSM.addAnimationState(e.name, e.states, e.extraPoints);
		}
	}

	public function createAnimSM(stateSelector:AnimationStateSelector):AnimationSM {
		var animSM = new AnimationSM(stateSelector);
		load(stateSelector, animSM);
		return animSM;
	}

}
