package bh.stateanim;

import bh.base.ParseError;
import bh.base.ParseError.ParseUnexpected;
import bh.base.ParsePosition;
import bh.base.Point;
#if (!macro && !noheaps)
import bh.base.Atlas2;
import bh.base.ResourceLoader;
import haxe.io.Bytes;
import bh.stateanim.AnimationSM;
import bh.base.filters.PixelOutline;
import bh.base.filters.PixelOutline.PixelOutlineFilterMode;
import bh.base.filters.ReplacePaletteShader;
#end

using StringTools;
using bh.base.MapTools;
using bh.multianim.ParseUtils;

@:nullSafety
enum APIdentifierType {
	AITString;
	AITParameter;
	AITQuotedString;
}

@:nullSafety
enum APToken {
	APEof;
	APOpen;
	APClosed;
	APComma;
	APColon;
	APSemiColon;
	APNumber(s:String); // integers and floats (#6)
	APIdentifier(s:String, keyword:Null<APKeywords>, identType:APIdentifierType);
	APCurlyClosed;
	APCurlyOpen;
	APBracketClosed;
	APBracketOpen;
	// APNewLine removed (#10) - newlines are now whitespace
	APDoubleDot;
	APAt;
	APArrow;
	APNotEquals;
	APGreater; // (#8)
	APLess; // (#8)
	APGreaterEq; // (#8)
	APLessEq; // (#8)
	APColor(i:Int); // (#11) #RRGGBB color literals
	APMinus; // (#7) unary minus before $ref
	APEquals; // (#7) = for @final assignment
}

@:nullSafety
enum AnimConditionalValue {
	ACVSingle(value:String);
	ACVMulti(values:Array<String>);
	ACVNot(inner:AnimConditionalValue);
	ACVCompare(op:AnimCompareOp, value:String); // (#8) @(level >= 3)
	ACVRange(min:String, max:String); // (#8) @(level => 1..5)
}

@:nullSafety
enum AnimCompareOp { // (#8)
	ACmpGte;
	ACmpLte;
	ACmpGt;
	ACmpLt;
}

@:nullSafety
typedef AnimConditionalSelector = Map<String, AnimConditionalValue>;

@:nullSafety
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
	APAnim; // (#5) compact shorthand
	APFinal; // (#7) @final constants
	APElse; // (#1) @else
	APDefault; // (#1) @default
	APFilters; // (#12) filter declarations
	APFilter; // (#12) per-frame filter in playlist
	APNone; // (#12) filter none
	APFlipX; // (#13) horizontal flip
	APFlipY; // (#13) vertical flip
}

/**
 * Keyword metadata for LSP/tooling use.
 * Single source of truth for .anim keyword names, contexts, and descriptions.
 */
enum AnimKeywordContext {
	AKTopLevel;
	AKAnimationBody;
	AKPlaylistBody;
	AKFilterBody;
	AKConditional;
}

@:nullSafety
class AnimKeywordInfo {
	public final name:String;
	public final context:AnimKeywordContext;
	public final description:String;
	public final snippet:Null<String>;
	public final isBlock:Bool;

	public function new(name:String, context:AnimKeywordContext, description:String, ?snippet:String, isBlock:Bool = false) {
		this.name = name;
		this.context = context;
		this.description = description;
		this.snippet = snippet;
		this.isBlock = isBlock;
	}

	// All .anim keywords with metadata — add new keywords here
	public static final all:Array<AnimKeywordInfo> = [
		// Top-level declarations
		new AnimKeywordInfo("sheet", AKTopLevel, "Sprite sheet name", "sheet: "),
		new AnimKeywordInfo("states", AKTopLevel, "State variable declaration: `states: stateName(value1, value2)`", "states: "),
		new AnimKeywordInfo("center", AKTopLevel, "Default center point: `center: x,y`", "center: "),
		new AnimKeywordInfo("fps", AKTopLevel, "Default frames per second", "fps: "),
		new AnimKeywordInfo("loop", AKTopLevel, "Default loop count. `yes` = forever, number = N times", "loop: "),
		new AnimKeywordInfo("flipX", AKTopLevel, "Default horizontal flip (yes/no)", "flipX: yes"),
		new AnimKeywordInfo("flipY", AKTopLevel, "Default vertical flip (yes/no)", "flipY: yes"),
		new AnimKeywordInfo("allowedExtraPoints", AKTopLevel, "Declare valid extra point names for validation"),
		new AnimKeywordInfo("animation", AKTopLevel, "Named animation definition with playlist, extrapoints, and filters",
			"animation ${1:name} {\n\t$0\n}", true),
		new AnimKeywordInfo("anim", AKTopLevel, "One-liner animation shorthand: `anim name(fps:N, loop:yes): \"sheetName\"`",
			"anim ${1:name}(fps:${2:20}): \"${3:sheetName}\""),
		new AnimKeywordInfo("metadata", AKTopLevel, "Typed key-value pairs (int, float, string, color). Supports state conditionals",
			"metadata {\n\t$0\n}", true),
		// Animation body
		new AnimKeywordInfo("fps", AKAnimationBody, "Frames per second", "fps: "),
		new AnimKeywordInfo("loop", AKAnimationBody, "Loop count (yes = forever)", "loop: "),
		new AnimKeywordInfo("playlist", AKAnimationBody, "Frame playlist", "playlist {\n\tsheet: \"${1:name}\"\n\t$0\n}", true),
		new AnimKeywordInfo("extrapoints", AKAnimationBody, "Named points for effects/interactions. Supports state conditionals",
			"extrapoints {\n\t$0\n}", true),
		new AnimKeywordInfo("filters", AKAnimationBody, "Per-animation filter block with state conditionals",
			"filters {\n\t$0\n}", true),
		new AnimKeywordInfo("flipX", AKAnimationBody, "Horizontal flip (yes/no)", "flipX: yes"),
		new AnimKeywordInfo("flipY", AKAnimationBody, "Vertical flip (yes/no)", "flipY: yes"),
		// Playlist body
		new AnimKeywordInfo("sheet", AKPlaylistBody, "Sheet name. Supports `${stateName}` interpolation", "sheet: \""),
		new AnimKeywordInfo("event", AKPlaylistBody, "Trigger event: `event <name> trigger | random x,y,radius | x,y`"),
		new AnimKeywordInfo("filter", AKPlaylistBody, "Per-frame filter change"),
		// Filter body
		new AnimKeywordInfo("tint", AKFilterBody, "Tint filter: `tint: #RRGGBB`", "tint: "),
		new AnimKeywordInfo("brightness", AKFilterBody, "Brightness filter: `brightness: 0.0-1.0`", "brightness: "),
		new AnimKeywordInfo("saturate", AKFilterBody, "Saturation filter", "saturate: "),
		new AnimKeywordInfo("grayscale", AKFilterBody, "Grayscale filter", "grayscale: "),
		new AnimKeywordInfo("hue", AKFilterBody, "Hue rotation filter", "hue: "),
		new AnimKeywordInfo("outline", AKFilterBody, "Outline filter: `outline: size, #color`", "outline: "),
		new AnimKeywordInfo("pixelOutline", AKFilterBody, "Pixel outline filter: `pixelOutline: #color`", "pixelOutline: "),
		new AnimKeywordInfo("replaceColor", AKFilterBody, "Color replacement: `replaceColor: [#src] => [#dst]`", "replaceColor: "),
		new AnimKeywordInfo("none", AKFilterBody, "Clear filters"),
		// Conditionals (usable in multiple contexts)
		new AnimKeywordInfo("@(", AKConditional, "Conditional: `@(state=>value)`", "@(${1:state}=>${2:value}) "),
		new AnimKeywordInfo("@else", AKConditional, "Else branch"),
		new AnimKeywordInfo("@else(", AKConditional, "Else-if with condition", "@else(${1:state}=>${2:value}) "),
		new AnimKeywordInfo("@default", AKConditional, "Default fallback"),
		new AnimKeywordInfo("@final", AKConditional, "Named constant", "@final ${1:NAME} = ${2:value}"),
	];

	public static function forContext(ctx:AnimKeywordContext):Array<AnimKeywordInfo> {
		return [for (k in all) if (k.context == ctx) k];
	}

	public static function findByName(name:String):Null<AnimKeywordInfo> {
		final lower = name.toLowerCase();
		for (k in all) {
			if (k.name.toLowerCase() == lower) return k;
		}
		return null;
	}
}

// ===================== Hand-coded Lexer =====================

@:nullSafety
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
		"anim" => APAnim, "final" => APFinal,
		"else" => APElse, "default" => APDefault, "filters" => APFilters,
		"filter" => APFilter, "none" => APNone,
		"flipx" => APFlipX, "flipy" => APFlipY,
	];

	inline function ch():Int {
		return pos < len ? src.charCodeAt(pos) : -1;
	}

	static inline function isHexChar(c:Int):Bool {
		return (c >= '0'.code && c <= '9'.code) || (c >= 'a'.code && c <= 'f'.code) || (c >= 'A'.code && c <= 'F'.code);
	}

	public function nextToken():AnimToken {
		// Skip spaces, tabs, AND newlines (#10 - newlines are now whitespace)
		while (pos < len) {
			final c = ch();
			if (c == ' '.code || c == '\t'.code) {
				pos++; col++;
			} else if (c == '\n'.code) {
				pos++; line++; col = 1; lineStart = pos;
			} else if (c == '\r'.code) {
				pos++;
				if (pos < len && ch() == '\n'.code) pos++;
				line++; col = 1; lineStart = pos;
			} else break;
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
			var blockClosed = false;
			while (pos < len) {
				if (ch() == '*'.code && pos + 1 < len && src.charCodeAt(pos + 1) == '/'.code) {
					pos += 2; col += 2;
					blockClosed = true;
					break;
				}
				if (ch() == '\n'.code) { line++; col = 1; lineStart = pos + 1; }
				else { col++; }
				pos++;
			}
			if (!blockClosed)
				throw '$sourceName:$startLine:$startCol: Unterminated block comment, missing closing */';
			return nextToken();
		}

		// Two-char tokens (must check before single-char)
		if (c == '!'.code && pos + 1 < len && src.charCodeAt(pos + 1) == '='.code) { pos += 2; col += 2; return new AnimToken(APNotEquals, startLine, startCol); }
		if (c == '='.code && pos + 1 < len && src.charCodeAt(pos + 1) == '>'.code) { pos += 2; col += 2; return new AnimToken(APArrow, startLine, startCol); }
		if (c == '.'.code && pos + 1 < len && src.charCodeAt(pos + 1) == '.'.code) { pos += 2; col += 2; return new AnimToken(APDoubleDot, startLine, startCol); }
		if (c == '>'.code && pos + 1 < len && src.charCodeAt(pos + 1) == '='.code) { pos += 2; col += 2; return new AnimToken(APGreaterEq, startLine, startCol); } // (#8)
		if (c == '<'.code && pos + 1 < len && src.charCodeAt(pos + 1) == '='.code) { pos += 2; col += 2; return new AnimToken(APLessEq, startLine, startCol); } // (#8)

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
			case '>'.code: pos++; col++; return new AnimToken(APGreater, startLine, startCol); // (#8)
			case '<'.code: pos++; col++; return new AnimToken(APLess, startLine, startCol); // (#8)
			case '='.code: pos++; col++; return new AnimToken(APEquals, startLine, startCol); // (#7)
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
						buf.add(String.fromCharCode(("0x" + src.substr(pos + 2, 4)).toInt()));
						pos += 6; col += 6; continue;
					}
				}
				if (sc == '"'.code) { pos++; col++; break; }
				buf.addChar(sc);
				pos++; col++;
			}
			return new AnimToken(APIdentifier(buf.toString(), null, AITQuotedString), startLine, startCol);
		}

		// Minus sign: produce APMinus if not followed by digit (digit case handled below as negative number) (#7)
		if (c == '-'.code) {
			if (pos + 1 < len && src.charCodeAt(pos + 1) >= '0'.code && src.charCodeAt(pos + 1) <= '9'.code) {
				// fall through to number parsing below
			} else {
				pos++; col++;
				return new AnimToken(APMinus, startLine, startCol);
			}
		}

		// Number (integer or float) (#6 adds float support)
		if ((c >= '0'.code && c <= '9'.code) || (c == '-'.code && pos + 1 < len && src.charCodeAt(pos + 1) >= '0'.code && src.charCodeAt(pos + 1) <= '9'.code)) {
			var start = pos;
			if (c == '-'.code) { pos++; col++; }
			while (pos < len && ch() >= '0'.code && ch() <= '9'.code) { pos++; col++; }
			// Float: decimal part (#6)
			if (pos < len && ch() == '.'.code && pos + 1 < len && src.charCodeAt(pos + 1) >= '0'.code && src.charCodeAt(pos + 1) <= '9'.code) {
				pos++; col++; // consume '.'
				while (pos < len && ch() >= '0'.code && ch() <= '9'.code) { pos++; col++; }
			}
			return new AnimToken(APNumber(src.substring(start, pos).replace("_", "")), startLine, startCol);
		}

		// Color literal: #RRGGBB or #RGB or #RRGGBBAA (#11)
		if (c == '#'.code) {
			pos++; col++;
			var hexStart = pos;
			while (pos < len && isHexChar(ch())) { pos++; col++; }
			final hexStr = src.substring(hexStart, pos);
			if (hexStr.length == 3) {
				// #RGB → #RRGGBB
				final r = ("0x" + hexStr.charAt(0) + hexStr.charAt(0)).toInt();
				final g = ("0x" + hexStr.charAt(1) + hexStr.charAt(1)).toInt();
				final b = ("0x" + hexStr.charAt(2) + hexStr.charAt(2)).toInt();
				return new AnimToken(APColor((r << 16) | (g << 8) | b), startLine, startCol);
			} else if (hexStr.length == 6) {
				return new AnimToken(APColor(("0x" + hexStr).toInt()), startLine, startCol);
			} else if (hexStr.length == 8) {
				// #RRGGBBAA → store as 0xAARRGGBB
				final rr = ("0x" + hexStr.substring(0, 2)).toInt();
				final gg = ("0x" + hexStr.substring(2, 4)).toInt();
				final bb = ("0x" + hexStr.substring(4, 6)).toInt();
				final aa = ("0x" + hexStr.substring(6, 8)).toInt();
				return new AnimToken(APColor((aa << 24) | (rr << 16) | (gg << 8) | bb), startLine, startCol);
			} else {
				// Unknown # sequence - treat as identifier starting with #
				return new AnimToken(APIdentifier("#" + hexStr, null, AITString), startLine, startCol);
			}
		}

		// Identifier (includes $)
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
		return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || c == '_'.code || c == '$'.code;
	}

	static inline function isIdentContinue(c:Int):Bool {
		return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || (c >= '0'.code && c <= '9'.code)
			|| c == '_'.code || c == '-'.code || c == '$'.code;
	}
}

// ===================== Types =====================

@:nullSafety
enum MetadataValue {
	MVInt(i:Int);
	MVFloat(f:Float); // (#6)
	MVString(s:String);
	MVColor(c:Int); // (#11) stored as 0xRRGGBB or 0xAARRGGBB
}

@:nullSafety
typedef MetadataEntry = {
	var states:AnimConditionalSelector;
	var value:MetadataValue;
}

@:nullSafety
typedef LoadedAnimation = {
	var sheet:String;
	var states:Map<String, Array<String>>;
	var allowedExtraPoints:Array<String>;
	var ?center:Point;
	var ?metadata:AnimMetadata;
	var animations:Array<AnimationState>;
}

/**
 * Conditional matching logic, extracted so it's available in both
 * full parser (heaps) and LSP (noheaps) modes.
 */
class AnimConditionalMatcher {
	public static function matchConditionalValue(condValue:AnimConditionalValue, runtimeValue:String):Bool {
		return switch condValue {
			case ACVSingle(v): v == runtimeValue;
			case ACVMulti(vs): vs.contains(runtimeValue);
			case ACVNot(inner): !matchConditionalValue(inner, runtimeValue);
			case ACVCompare(op, cmpVal):
				final numRuntime = Std.parseFloat(runtimeValue);
				final numCmp = Std.parseFloat(cmpVal);
				if (Math.isNaN(numRuntime) || Math.isNaN(numCmp)) false;
				else switch op {
					case ACmpGte: numRuntime >= numCmp;
					case ACmpLte: numRuntime <= numCmp;
					case ACmpGt: numRuntime > numCmp;
					case ACmpLt: numRuntime < numCmp;
				};
			case ACVRange(minVal, maxVal):
				final numRuntime = Std.parseFloat(runtimeValue);
				final numMin = Std.parseFloat(minVal);
				final numMax = Std.parseFloat(maxVal);
				if (Math.isNaN(numRuntime) || Math.isNaN(numMin) || Math.isNaN(numMax)) false;
				else numRuntime >= numMin && numRuntime <= numMax;
		};
	}

	public static function countStateMatch(match:AnimConditionalSelector, selector:AnimationStateSelector):Int {
		var retVal = 0;
		for (key => value in selector) {
			final condVal = match.get(key);
			if (condVal != null) {
				if (matchConditionalValue(condVal, value))
					retVal++;
				else
					retVal -= 10000;
			}
		}
		return retVal;
	}
}

@:nullSafety
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
			final score = stateSelector != null ? AnimConditionalMatcher.countStateMatch(entry.states, stateSelector) : 0;
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
			case MVFloat(f): Std.int(f);
			case MVString(s): throw 'expected int for metadata key ${key} but was string $s';
			case MVColor(c): throw 'expected int for metadata key ${key} but was color $c';
		};
	}

	public function getIntOrException(key:String, ?stateSelector:AnimationStateSelector):Int {
		final value = findBestMatch(key, stateSelector);
		if (value == null)
			throw 'metadata key ${key} not found';
		return switch value {
			case MVInt(i): i;
			case MVFloat(f): Std.int(f);
			case MVString(s): throw 'expected int for metadata key ${key} but was string $s';
			case MVColor(c): throw 'expected int for metadata key ${key} but was color $c';
		};
	}

	public function getFloatOrDefault(key:String, defaultValue:Float, ?stateSelector:AnimationStateSelector):Float { // (#6)
		final value = findBestMatch(key, stateSelector);
		if (value == null)
			return defaultValue;
		return switch value {
			case MVInt(i): i;
			case MVFloat(f): f;
			case MVString(s): throw 'expected float for metadata key ${key} but was string $s';
			case MVColor(c): throw 'expected float for metadata key ${key} but was color $c';
		};
	}

	public function getFloatOrException(key:String, ?stateSelector:AnimationStateSelector):Float { // (#6)
		final value = findBestMatch(key, stateSelector);
		if (value == null)
			throw 'metadata key ${key} not found';
		return switch value {
			case MVInt(i): i;
			case MVFloat(f): f;
			case MVString(s): throw 'expected float for metadata key ${key} but was string $s';
			case MVColor(c): throw 'expected float for metadata key ${key} but was color $c';
		};
	}

	public function getStringOrDefault(key:String, defaultValue:String, ?stateSelector:AnimationStateSelector):String {
		final value = findBestMatch(key, stateSelector);
		if (value == null)
			return defaultValue;
		return switch value {
			case MVString(s): s;
			case MVInt(i): '$i';
			case MVFloat(f): '$f';
			case MVColor(c): '#${StringTools.hex(c, 6)}';
		};
	}

	public function getStringOrException(key:String, ?stateSelector:AnimationStateSelector):String {
		final value = findBestMatch(key, stateSelector);
		if (value == null)
			throw 'metadata key ${key} not found';
		return switch value {
			case MVString(s): s;
			case MVInt(i): '$i';
			case MVFloat(f): '$f';
			case MVColor(c): '#${StringTools.hex(c, 6)}';
		};
	}

	public function getColorOrDefault(key:String, defaultValue:Int, ?stateSelector:AnimationStateSelector):Int { // (#11)
		final value = findBestMatch(key, stateSelector);
		if (value == null)
			return defaultValue;
		return switch value {
			case MVColor(c): c;
			case MVInt(i): i;
			case MVString(s): throw 'expected color for metadata key ${key} but was string $s';
			case MVFloat(f): throw 'expected color for metadata key ${key} but was float $f';
		};
	}

	public function getColorOrException(key:String, ?stateSelector:AnimationStateSelector):Int { // (#11)
		final value = findBestMatch(key, stateSelector);
		if (value == null)
			throw 'metadata key ${key} not found';
		return switch value {
			case MVColor(c): c;
			case MVInt(i): i;
			case MVString(s): throw 'expected color for metadata key ${key} but was string $s';
			case MVFloat(f): throw 'expected color for metadata key ${key} but was float $f';
		};
	}
}

@:nullSafety
#if (!macro && !noheaps)
@:using(AnimParser.ExtraPointsHelper)
#end
typedef ExtraPoints = {
	var states:AnimConditionalSelector;
	var point:Point;
	var ?visited:Bool;
}

@:nullSafety
enum AnimPlaylistFrames {
	SheetFrameAnim(name:String, durationMilliseconds:Null<Int>);
	SheetFrameAnimWithIndex(name:String, from:Null<Int>, to:Null<Int>, durationMilliseconds:Null<Int>);
	FileSingleFrame(filename:String, durationMilliseconds:Null<Int>);
	#if (!macro && !noheaps)
	PlaylistEvent(playlistEvent:AnimationPlaylistEvent);
	#end
	PlaylistEventData(name:String, meta:Map<String, MetadataValue>); // (#9) event with typed metadata
	PlaylistFilter(filter:AnimFilterType); // (#12) per-frame filter change
}

@:nullSafety
typedef Playlist = {
	var states:AnimConditionalSelector;
	var anims:Array<AnimPlaylistFrames>;
	var ?visited:Bool;
}

@:nullSafety
enum AnimFilterType { // (#12)
	AFTint(color:Int);
	AFBrightness(v:Float);
	AFSaturate(v:Float);
	AFGrayscale(v:Float);
	AFHue(v:Float);
	AFOutline(size:Float, color:Int);
	AFPixelOutline(color:Int);
	AFReplaceColor(sourceColors:Array<Int>, replacementColors:Array<Int>);
	AFNone;
}

@:nullSafety
typedef AnimFilterEntry = { // (#12)
	var states:AnimConditionalSelector;
	var filter:AnimFilterType;
}

@:nullSafety
typedef AnimationState = {
	var name:String;
	var states:AnimConditionalSelector;
	var fps:Null<Int>;
	var loop:Null<Int>; // -1 = forever, null = no loop, N = loop N times
	var extraPoint:Map<String, Array<ExtraPoints>>;
	var playlist:Array<Playlist>;
	var ?visited:Bool;
	var ?filters:Array<AnimFilterEntry>; // (#12)
	var ?flipX:Bool; // (#13) horizontal flip
	var ?flipY:Bool; // (#13) vertical flip
}

#if (!macro && !noheaps)
@:nullSafety
class ExtraPointsHelper {
	public static function toPoint(pt:ExtraPoints) {
		return new h2d.col.IPoint(pt.point.x, pt.point.y);
	}
}
#end

@:nullSafety
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

@:nullSafety
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

@:nullSafety
typedef AnimationStateSelector = Map<String, String>;

#if (!macro && !noheaps)
@:nullSafety
interface AnimParserResult {
	var definedStates(default, never):Map<String, Array<String>>;
	var metadata(default, never):Null<AnimMetadata>;

	function createAnimSM(stateSelector:AnimationStateSelector):AnimationSM;
}
#end

// ===================== Parser =====================

#if (!macro && !noheaps)
@:nullSafety
class AnimParser implements AnimParserResult {
	var tokens:Array<AnimToken>;
	var tpos:Int;
	var sourceName:String;

	var animations:Array<AnimationState> = [];
	var animationNames:Array<String> = [];
	var allowedExtraPoints:Array<String> = [];
	public var definedStates(default, null):Map<String, Array<String>> = [];
	var definedStatesIndexes:Array<String> = [];
	var sheetName:Null<String> = null;
	var center:Null<Point> = null;
	var metadataMap:Map<String, Array<MetadataEntry>> = [];
	public var metadata(default, null):Null<AnimMetadata> = null;
	var constants:Map<String, Float> = []; // (#7) @final named constants
	var defaultFps:Null<Int> = null; // (#3) file-level fps default
	var defaultLoop:Null<Int> = null; // (#3) file-level loop default
	var defaultFlipX:Bool = false; // (#13) file-level flipX default
	var defaultFlipY:Bool = false; // (#13) file-level flipY default
	var cache:Map<String, Array<{name:String, states:Array<AnimationFrameState>, loopCount:Int, extraPoints:Map<String, h2d.col.IPoint>, filter:Null<h2d.filter.Filter>, tintColor:Null<Int>}>> = [];
	final resourceLoader:bh.base.ResourceLoader;

	// ===================== Token Access =====================

	inline function peek():APToken {
		return tokens[tpos].type;
	}

	function peekAt(offset:Int):APToken { // lookahead
		final idx = tpos + offset;
		return idx < tokens.length ? tokens[idx].type : APEof;
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

	function curPos():ParsePosition {
		final t = tokens[tpos];
		return new ParsePosition(sourceName, t.line, t.col);
	}

	function syntaxError(error:String, ?pos:ParsePosition):Dynamic {
		final p = pos != null ? pos : curPos();
		final err = new InvalidSyntax(error, p);
		#if MULTIANIM_DEV
		trace('AnimParser syntax error in $sourceName: $err');
		#end
		throw err;
	}

	function unexpectedError(?message:String):Dynamic {
		final err = new AnimUnexpected(peek(), curPos(), message ?? "unexpected");
		#if MULTIANIM_DEV
		trace('AnimParser unexpected token in $sourceName: $err');
		#end
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
			#if MULTIANIM_DEV
			trace('AnimParser.parseString failed for $sourceName: $e');
			#end
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

	@:nullSafety(Off)
	function parse():Void {
		var animationParsingStarted = false;
		while (true) {
			switch (peek()) {
				case APEof:
					break;
				case APIdentifier(_, APSheet, AITString):
					advance();
					expect(APColon);
					final value = expectIdentifier();
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
				case APIdentifier(_, APFps, AITString): // (#3) file-level fps default
					advance();
					expect(APColon);
					if (animationParsingStarted) syntaxError("file-level fps default must be before animations");
					if (defaultFps != null) syntaxError("default fps already set");
					final parsedDefaultFps = parseIntNumber();
					if (parsedDefaultFps <= 0) syntaxError("default fps must be greater than 0");
					defaultFps = parsedDefaultFps;
				case APIdentifier(_, APLoop, AITString): // (#3) file-level loop default
					advance();
					expect(APColon);
					if (animationParsingStarted) syntaxError("file-level loop default must be before animations");
					defaultLoop = parseLoopValue();
				case APIdentifier(_, APFlipX, AITString): // (#13) file-level flipX default
					advance();
					expect(APColon);
					if (animationParsingStarted) syntaxError("file-level flipX default must be before animations");
					defaultFlipX = parseBoolValue();
				case APIdentifier(_, APFlipY, AITString): // (#13) file-level flipY default
					advance();
					expect(APColon);
					if (animationParsingStarted) syntaxError("file-level flipY default must be before animations");
					defaultFlipY = parseBoolValue();
				case APAt: // (#7) @final constants, or other @ at top level
					advance();
					switch peek() {
						case APIdentifier(_, APFinal, _): // @final name = expr
							advance();
							if (animationParsingStarted) syntaxError("@final must be declared before animations");
							final constName = expectIdentifier();
							expect(APEquals);
							final constVal = parseConstantExpr();
							if (constants.exists(constName)) syntaxError('@final "${constName}" already defined');
							constants.set(constName, constVal);
						default:
							unexpectedError("expected 'final' after @");
					}
				case APIdentifier(_, APAnimation, AITString): // full animation block
					advance();
					animationParsingStarted = true;

					// (#2) Optional name in header: animation name { } or animation name @(cond) { }
					var headerName:Null<String> = null;
					switch [peek(), peekAt(1)] {
						case [APIdentifier(s, _, AITString), APCurlyOpen | APAt]:
							advance();
							headerName = s;
						case _:
					}

					final animationStates = parseStates(); // (#1) handles @else, @default
					for (key => value in animationStates) {
						parserValidateConditionalState(definedStates, key, value);
					}
					expect(APCurlyOpen);
					final startOfAnim = curPos();
					var parsedAnim = parseAnimation(definedStates, animationStates, allowedExtraPoints, headerName);
					final animFps = parsedAnim.fps ?? defaultFps;
					if (animFps == null) syntaxError("fps expected (set fps in animation body or as file-level default)", startOfAnim);
					var anim:AnimationState = {
						states: animationStates,
						name: parsedAnim.name,
						loop: parsedAnim.loop ?? defaultLoop,
						fps: animFps,
						extraPoint: parsedAnim.extraPoints,
						playlist: parsedAnim.playlist,
						filters: parsedAnim.filters,
						flipX: parsedAnim.flipX ?? defaultFlipX,
						flipY: parsedAnim.flipY ?? defaultFlipY,
					};
					animations.push(anim);
				case APIdentifier(_, APAnim, AITString): // (#5) compact shorthand: anim name(fps:N, loop:yes): "sheet"
					advance();
					animationParsingStarted = true;
					parseAnimShorthand();
				default:
					unexpectedError();
			}
		}

		// Post-parse validation
		for (key => value in definedStates) {
			definedStatesIndexes.push(key);
		}
		final allStates = createAllStates(definedStates);
		#if MULTIANIM_DEV
		if (allStates.length > 50) {
			trace('Warning: large number of states in AnimParser: ${allStates.length}}');
		}
		#end

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
			}
			for (pl in anim.playlist) {
				if (pl.visited == false)
					throw 'Playlist in anim ${anim.name} not reachable ${pl.states}';
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

	// (#6) Parse a number (integer or float) and return as string
	function parseIntNumber():Int {
		switch peek() {
			case APNumber(s):
				advance();
				return Std.parseInt(s) ?? syntaxError('expected integer, got "$s"');
			default:
				return unexpectedError("expected integer number");
		}
	}

	// (#7) Parse a constant expression: number, -number, $ref, -$ref
	@:nullSafety(Off)
	function parseConstantExpr():Float {
		var isNeg = match(APMinus);
		switch peek() {
			case APNumber(s):
				advance();
				final f = Std.parseFloat(s);
				return isNeg ? -f : f;
			case APIdentifier(s, _, AITString) if (s.charAt(0) == '$'):
				advance();
				final refName = s.substring(1);
				final cv = constants.get(refName);
				if (cv == null) syntaxError('constant "${refName}" not defined. Defined constants: ${[for (k in constants.keys()) k]}');
				return isNeg ? -(cv : Float) : (cv : Float);
			default:
				return unexpectedError("expected number or $constant");
		}
	}

	// (#6) Parse coordinate component: integer, float-rounded-to-int, or $ref
	function parseIntCoord():Int {
		return Std.int(parseConstantExpr());
	}

	function parseCoordinates():Point {
		final x = parseIntCoord();
		expect(APComma);
		final y = parseIntCoord();
		return {x: x, y: y};
	}

	// (#3) Parse a loop value (yes/no/number)
	@:nullSafety(Off)
	function parseLoopValue():Null<Int> {
		switch peek() {
			case APIdentifier("true" | "yes", _, _):
				advance();
				return -1;
			case APIdentifier("false" | "no", _, _):
				advance();
				return null;
			case APNumber(number):
				advance();
				final cnt = Std.parseInt(number);
				if (cnt == null || cnt <= 0) syntaxError("loop counter must be greater than 0");
				return cnt;
			default:
				return unexpectedError("expected loop value (yes/no/true/false/number)");
		}
	}

	function parseBoolValue():Bool { // (#13) yes/no/true/false
		switch peek() {
			case APIdentifier("true" | "yes", _, _):
				advance();
				return true;
			case APIdentifier("false" | "no", _, _):
				advance();
				return false;
			default:
				return unexpectedError("expected yes/no/true/false");
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

	// (#1) parseStates: handles @(cond), @else, @else(cond), @default
	function parseStates():AnimConditionalSelector {
		var states:AnimConditionalSelector = [];
		while (true) {
			switch (peek()) {
				case APAt:
					advance();
					switch peek() {
						case APIdentifier(_, APElse, _): // @else or @else(cond)
							advance();
							if (match(APOpen)) {
								// @else(condition) - parse just that condition
								var elseStates:AnimConditionalSelector = [];
								parseConditionalState(elseStates);
								return elseStates;
							}
							return []; // bare @else = empty selector (fallback, matches everything)
						case APIdentifier(_, APDefault, _): // @default
							advance();
							return []; // empty selector (matches everything, lowest priority)
						case APOpen: // @(cond)
							advance();
							parseConditionalState(states);
						default:
							return unexpectedError("expected (, else, or default after @");
					}
				default:
					return states;
			}
		}
	}

	function parseConditionalState(states:AnimConditionalSelector):Void {
		final stateName = expectIdentifier();

		var condValue:AnimConditionalValue;
		switch (peek()) {
			case APArrow: // =>  — single value, multi-value [a,b], or range a..b
				advance();
				switch peek() {
					case APBracketOpen: // @(state=>[a,b])
						advance();
						condValue = ACVMulti(parseConditionalValueList());
					case APNumber(v):
						advance();
						if (match(APDoubleDot)) { // @(state=>1..5) range
							final val2 = expectIdentifier();
							condValue = ACVRange(v, val2);
						} else {
							condValue = ACVSingle(v);
						}
					case APIdentifier(v, _, AITString | AITQuotedString):
						advance();
						if (match(APDoubleDot)) { // @(state=>a..b) range
							final val2 = expectIdentifier();
							condValue = ACVRange(v, val2);
						} else {
							condValue = ACVSingle(v);
						}
					default:
						condValue = syntaxError("Expected value, [values], or range after =>");
				}
			case APNotEquals: // !=
				advance();
				var innerVal:AnimConditionalValue;
				switch peek() {
					case APBracketOpen:
						advance();
						innerVal = ACVMulti(parseConditionalValueList());
					case APIdentifier(value, _, AITString | AITQuotedString):
						advance();
						innerVal = ACVSingle(value);
					case APNumber(value):
						advance();
						innerVal = ACVSingle(value);
					default:
						innerVal = syntaxError("Expected value or [values] after !=");
				}
				condValue = ACVNot(innerVal);
			case APGreaterEq: // >= (#8)
				advance();
				condValue = ACVCompare(ACmpGte, expectIdentifier());
			case APLessEq: // <= (#8)
				advance();
				condValue = ACVCompare(ACmpLte, expectIdentifier());
			case APGreater: // > (#8)
				advance();
				condValue = ACVCompare(ACmpGt, expectIdentifier());
			case APLess: // < (#8)
				advance();
				condValue = ACVCompare(ACmpLt, expectIdentifier());
			default:
				condValue = syntaxError("Expected =>, !=, >=, <=, >, or < in conditional");
		}

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
			if (match(APCurlyClosed)) break;
			final states = parseStates();
			final key = expectIdentifier();
			expect(APColon);
			var entryValue:MetadataValue;
			switch (peek()) {
				case APNumber(numStr):
					advance();
					// (#6) detect float vs int
					if (numStr.contains(".")) {
						entryValue = MVFloat(Std.parseFloat(numStr));
					} else {
						entryValue = MVInt(numStr.toInt());
					}
				case APIdentifier(strVal, _, AITQuotedString):
					advance();
					entryValue = MVString(strVal);
				case APColor(c): // (#11)
					advance();
					entryValue = MVColor(c);
				default:
					entryValue = unexpectedError("Expected number, string, or color value in metadata");
			}
			var entry:MetadataEntry = {states: states, value: entryValue};
			final existing = metadataMap.get(key);
			if (existing != null) existing.push(entry);
			else metadataMap[key] = [entry];
		}
	}

	@:nullSafety(Off)
	function parseAnimation(statesDefinitions, animationStates, allowedExtraPointsList, ?headerName:String) {
		var extraPoints:Map<String, Array<ExtraPoints>> = [];
		var filters:Array<AnimFilterEntry> = []; // (#12)
		var flipX:Null<Bool> = null; // (#13)
		var flipY:Null<Bool> = null; // (#13)
		var ret = {
			loop: (null : Null<Int>),
			name: headerName, // (#2) name may come from header
			fps: (null : Null<Int>),
			extraPoints: extraPoints,
			playlist: ([] : Array<Playlist>),
			filters: filters,
			flipX: flipX,
			flipY: flipY,
		};

		while (true) {
			switch (peek()) {
				case APCurlyClosed:
					advance();
					break;
				case APIdentifier(_, APName, AITString): // (#2) backward compat: name: inside body
					advance();
					expect(APColon);
					final bodyName = expectIdentifier();
					if (ret.name != null && ret.name != bodyName)
						syntaxError('animation name "${ret.name}" (in header) conflicts with name: "${bodyName}" (in body)');
					ret.name = bodyName;
					if (!animationNames.contains(ret.name)) animationNames.push(ret.name);
				case APIdentifier(_, APLoop, AITString):
					advance();
					expect(APColon);
					ret.loop = parseLoopValue();
				case APIdentifier(_, APFps, AITString):
					advance();
					expect(APColon);
					if (ret.fps != null) syntaxError("fps already set");
					final parsedFps = parseIntNumber();
					if (parsedFps <= 0) syntaxError("fps must be greater than 0");
					ret.fps = parsedFps;
				case APIdentifier(_, APExtrapoints, AITString):
					advance();
					expect(APCurlyOpen);
					if (extraPoints.count() > 0) syntaxError("extraPoints already defined");
					parseExtraPoints(statesDefinitions, animationStates, extraPoints, allowedExtraPointsList);
					if (extraPoints.count() == 0) syntaxError("extraPoints must not be empty");
				case APIdentifier(_, APPlaylist, AITString):
					advance();
					final playlistStates = parseStates(); // (#1) @else/@default in playlist
					for (key => value in playlistStates)
						parserValidateConditionalState(statesDefinitions, key, value);
					checkForUnreachableState(animationStates, playlistStates);
					expect(APCurlyOpen);
					var playlist:Playlist = {anims: [], states: playlistStates};
					parseFrames(playlist.anims);
					ret.playlist.push(playlist);
				case APIdentifier(_, APFilters, AITString): // (#12) filter declarations
					advance();
					expect(APCurlyOpen);
					ret.filters = parseFilterBlock(statesDefinitions, animationStates);
				case APIdentifier(_, APFlipX, AITString): // (#13) horizontal flip
					advance();
					expect(APColon);
					if (ret.flipX != null) syntaxError("flipX already set");
					ret.flipX = parseBoolValue();
				case APIdentifier(_, APFlipY, AITString): // (#13) vertical flip
					advance();
					expect(APColon);
					if (ret.flipY != null) syntaxError("flipY already set");
					ret.flipY = parseBoolValue();
				default:
					unexpectedError();
			}
		}

		if (ret.name == null) syntaxError("animation name not set (use 'animation name { }' or 'name:' inside body)");
		if (!animationNames.contains(ret.name)) animationNames.push(ret.name);
		if (ret.playlist.length == 0) syntaxError("animation requires playlist");
		return ret;
	}

	// (#5) Parse compact animation shorthand: anim name(fps:N, loop:yes, flipX:yes, flipY:yes): "sheet"
	@:nullSafety(Off)
	function parseAnimShorthand():Void {
		final name = expectIdentifier();
		var overrideFps:Null<Int> = null;
		var overrideLoop:Null<Int> = null;
		var overrideFlipX:Null<Bool> = null; // (#13)
		var overrideFlipY:Null<Bool> = null; // (#13)

		if (match(APOpen)) {
			var first = true;
			while (!match(APClosed)) {
				if (!first) expect(APComma);
				first = false;
				switch peek() {
					case APIdentifier(_, APFps, _):
						advance();
						expect(APColon);
						final fps = parseIntNumber();
						if (fps <= 0) syntaxError("fps must be greater than 0");
						overrideFps = fps;
					case APIdentifier(_, APLoop, _):
						advance();
						expect(APColon);
						overrideLoop = parseLoopValue();
					case APIdentifier(_, APFlipX, _): // (#13)
						advance();
						expect(APColon);
						overrideFlipX = parseBoolValue();
					case APIdentifier(_, APFlipY, _): // (#13)
						advance();
						expect(APColon);
						overrideFlipY = parseBoolValue();
					default:
						unexpectedError("expected fps, loop, flipX, or flipY modifier in anim shorthand");
				}
			}
		}

		expect(APColon);
		final sheetStr = expectIdentifier();
		final sheetPos = curPos();
		validateSheetName(sheetStr, sheetPos);

		final animFps = overrideFps ?? defaultFps;
		if (animFps == null) syntaxError('anim shorthand "${name}" requires fps (set in modifiers or file-level default)');
		final animLoop:Null<Int> = overrideLoop ?? defaultLoop;

		final playlist:Playlist = {anims: [SheetFrameAnim(sheetStr, null)], states: []};
		final anim:AnimationState = {
			states: [],
			name: name,
			loop: animLoop,
			fps: animFps,
			extraPoint: [],
			playlist: [playlist],
			flipX: overrideFlipX ?? defaultFlipX,
			flipY: overrideFlipY ?? defaultFlipY,
		};
		if (!animationNames.contains(name)) animationNames.push(name);
		animations.push(anim);
	}

	function parseExtraPoints(statesDefinitions:Map<String, Array<String>>, animationStates:AnimConditionalSelector,
			extraPoints:Map<String, Array<ExtraPoints>>, allowedExtraPointsList:Array<String>):Void {
		while (true) {
			if (match(APCurlyClosed)) break;
			final states = parseStates(); // (#1) @else/@default in extrapoints
			final pointName = expectIdentifier();
			expect(APColon);
			final c = parseCoordinates();

			if (allowedExtraPointsList.contains(pointName) == false)
				syntaxError('extraPoint ${pointName} not declared in allowedExtraPoints');
			for (key => value in states)
				parserValidateConditionalState(statesDefinitions, key, value);
			checkForUnreachableState(animationStates, states);

			var p = {states: states, point: c};
			final existing = extraPoints.get(pointName);
			if (existing != null) existing.push(p);
			else extraPoints.set(pointName, [p]);
		}
	}

	function parseFrames(anims:Array<AnimPlaylistFrames>):Void {
		while (true) {
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
									final r = Std.parseFloat(randomRadius);
									// (#9) optional metadata payload after random event
									if (match(APCurlyOpen)) {
										final meta = parseEventMeta();
										anims.push(PlaylistEventData(eventName, meta));
									} else {
										anims.push(PlaylistEvent(RandomPointEvent(eventName, new h2d.col.IPoint(p.x, p.y), r)));
									}
								default:
									unexpectedError("expected radius");
							}
						case APNumber(_):
							final p = parseCoordinates();
							if (match(APCurlyOpen)) { // (#9) metadata on point event
								final meta = parseEventMeta();
								anims.push(PlaylistEventData(eventName, meta));
							} else {
								anims.push(PlaylistEvent(PointEvent(eventName, new h2d.col.IPoint(p.x, p.y))));
							}
						case APSemiColon: // explicit statement terminator
							advance();
							anims.push(PlaylistEvent(Trigger(eventName)));
						case APCurlyOpen: // (#9) metadata on bare trigger event
							advance();
							final meta = parseEventMeta();
							anims.push(PlaylistEventData(eventName, meta));
						default:
							// Bare trigger: self-terminated by next keyword, } or EOF
							anims.push(PlaylistEvent(Trigger(eventName)));
					}
				case APIdentifier(_, APSheet, AITString):
					advance();
					expect(APColon);
					final frameName = expectIdentifier();
					final sheetPos = curPos();
					validateSheetName(frameName, sheetPos); // (#4) validate ${state} and error on $$
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
									final startN = Std.parseInt(startIndex) ?? 0;
									start = startN;
									expect(APDoubleDot);
									switch (peek()) {
										case APNumber(endIndex):
											advance();
											final endN = Std.parseInt(endIndex) ?? 0;
											end = endN;
											if (startN < 0) syntaxError('frame index must be non-negative, was $startN');
											if (endN < 0) syntaxError('frame index must be non-negative, was $endN');
										default:
											unexpectedError("expected end index");
									}
								default:
									unexpectedError("expected start index");
							}
							match(APComma);
							duration = tryParseDuration();
						case APCurlyClosed | APEof | APIdentifier(_, APSheet | APFile | APEvent | APFilter, _):
							// sheet name is self-terminating in context
						default:
							duration = tryParseDuration();
					}
					if (start == null && end == null)
						anims.push(SheetFrameAnim(frameName, duration));
					else
						anims.push(SheetFrameAnimWithIndex(frameName, start, end, duration));
				case APIdentifier(_, APFilter, AITString): // (#12) per-frame filter
					advance();
					final filter = parseFilterEntry();
					anims.push(PlaylistFilter(filter));
				default:
					unexpectedError();
			}
		}
	}

	// (#9) Parse typed event metadata: key => val, key:type => val, ...
	function parseEventMeta():Map<String, MetadataValue> {
		var meta:Map<String, MetadataValue> = [];
		while (true) {
			if (match(APCurlyClosed)) break;
			final key = expectIdentifier();
			// Optional type annotation: key:type => val
			var typeHint:Null<String> = null;
			if (match(APColon)) {
				typeHint = expectIdentifier();
			}
			expect(APArrow);
			var val:MetadataValue;
			switch peek() {
				case APNumber(s):
					advance();
					if (typeHint == "float" || s.contains(".")) {
						val = MVFloat(Std.parseFloat(s));
					} else {
						val = MVInt(s.toInt());
					}
				case APIdentifier(s, _, AITQuotedString):
					advance();
					val = MVString(s);
				case APIdentifier("true" | "false", _, _):
					final b = expectIdentifier();
					val = MVInt(b == "true" ? 1 : 0);
				case APColor(c): // (#11)
					advance();
					val = MVColor(c);
				default:
					val = unexpectedError("expected metadata value");
			}
			meta.set(key, val);
			match(APComma);
		}
		return meta;
	}

	// (#12) Parse filter declarations block with typed filters and state conditionals
	function parseFilterBlock(statesDefinitions, animationStates):Array<AnimFilterEntry> {
		var filters:Array<AnimFilterEntry> = [];
		while (!match(APCurlyClosed)) {
			final states = parseStates();
			for (key => value in states)
				parserValidateConditionalState(statesDefinitions, key, value);
			checkForUnreachableState(animationStates, states);
			final filter = parseFilterEntry();
			filters.push({states: states, filter: filter});
		}
		return filters;
	}

	// (#12) Parse a single filter entry: type: params
	function parseFilterEntry():AnimFilterType {
		final filterName = expectIdentifier();
		switch filterName {
			case "none":
				return AFNone;
			case "tint":
				expect(APColon);
				return AFTint(expectColor());
			case "brightness":
				expect(APColon);
				return AFBrightness(expectFloat());
			case "saturate":
				expect(APColon);
				return AFSaturate(expectFloat());
			case "grayscale":
				expect(APColon);
				return AFGrayscale(expectFloat());
			case "hue":
				expect(APColon);
				return AFHue(expectFloat());
			case "outline":
				expect(APColon);
				final size = expectFloat();
				expect(APComma);
				final color = expectColor();
				return AFOutline(size, color);
			case "pixelOutline":
				expect(APColon);
				return AFPixelOutline(expectColor());
			case "replaceColor":
				expect(APColon);
				final sourceColors = parseFilterColorList();
				expect(APArrow);
				final replacementColors = parseFilterColorList();
				if (sourceColors.length != replacementColors.length)
					syntaxError('replaceColor: source and replacement color lists must have same length (${sourceColors.length} vs ${replacementColors.length})');
				return AFReplaceColor(sourceColors, replacementColors);
			default:
				return syntaxError('unknown filter type: $filterName');
		}
	}

	function expectColor():Int {
		switch peek() {
			case APColor(c):
				advance();
				return c;
			default:
				return unexpectedError("expected color (#RRGGBB)");
		}
	}

	function expectFloat():Float {
		final negative = match(APMinus);
		switch peek() {
			case APNumber(n):
				advance();
				final v = Std.parseFloat(n);
				return negative ? -v : v;
			default:
				return unexpectedError("expected number");
		}
	}

	// (#12) Parse [#color, #color, ...] list
	function parseFilterColorList():Array<Int> {
		expect(APBracketOpen);
		var colors:Array<Int> = [];
		while (!match(APBracketClosed)) {
			if (colors.length > 0) expect(APComma);
			colors.push(expectColor());
		}
		if (colors.length == 0) syntaxError("color list must not be empty");
		return colors;
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
						final d = Std.parseInt(duration) ?? 0;
						if (d <= 0) return syntaxError("duration must be greater than 0");
						return d;
					default:
						final d = Std.parseInt(duration) ?? 0;
						if (d <= 0) return syntaxError("duration must be greater than 0");
						return d;
				}
			case APIdentifier(durationStr, _, AITString):
				advance();
				if (durationStr.endsWith("ms")) {
					final d = Std.parseInt(durationStr.substring(0, durationStr.length - 2)) ?? 0;
					if (d <= 0) syntaxError("duration must be greater than 0");
					return d;
				} else
					return syntaxError('expected <int>ms got ${durationStr}');
			default:
				return null;
		}
	}

	// (#4) Validate sheet name: validate ${state} references
	function validateSheetName(name:String, pos:ParsePosition):Void {
		// Validate ${stateName} references against defined states
		var j = 0;
		while (j < name.length) {
			if (name.charAt(j) == '$' && j + 1 < name.length && name.charAt(j + 1) == '{') {
				final end = name.indexOf('}', j + 2);
				if (end == -1) syntaxError('Unclosed $${...} in sheet name "${name}"', pos);
				final stateName = name.substring(j + 2, end);
				if (!definedStates.exists(stateName))
					syntaxError('Unknown state "${stateName}" in sheet name "${name}". Defined states: [${[for (k in definedStates.keys()) k].join(", ")}]', pos);
				j = end + 1;
			} else {
				j++;
			}
		}
	}

	// ===================== State Validation =====================

	static function validateState(definedStates:Map<String, Array<String>>, name:String, value:String) {
		final vals = definedStates.get(name);
		if (vals == null)
			throw 'state ${name} not defined';
		if (vals.contains(value) == false)
			throw 'state ${name} does not allow value:${value}';
	}

	static function validateStateSelector(definedStates:Map<String, Array<String>>, selector:AnimationStateSelector) {
		if (definedStates.count() != selector.count())
			throw 'invalid selector ${selector} for defined states ${definedStates}';
		for (key => value in definedStates) {
			final sv = selector.get(key);
			if (sv == null)
				throw 'key not defined: ${key}';
			if (value.contains(sv) == false)
				throw 'unknown state value ${value} not defined for key: ${key}: ${definedStates}';
		}
		for (key => value in selector) {
			final vals = definedStates.get(key);
			if (vals == null)
				throw 'unknown state key: ${key}';
			if (vals.contains(value) == false)
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
			case ACVCompare(_, _) | ACVRange(_, _): // (#8) comparison ops: just check state name exists
				if (!animStates.exists(name))
					syntaxError('state "${name}" not defined');
		}
	}

	function checkForUnreachableState(parentState:AnimConditionalSelector, childState:AnimConditionalSelector) {
		// Empty child state (@else/@default) is always reachable - skip check
		if (childState.count() == 0) return true;
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

	public static inline function matchConditionalValue(condValue:AnimConditionalValue, runtimeValue:String):Bool {
		return AnimConditionalMatcher.matchConditionalValue(condValue, runtimeValue);
	}

	public static inline function countStateMatch(match:AnimConditionalSelector, selector:AnimationStateSelector):Int {
		return AnimConditionalMatcher.countStateMatch(match, selector);
	}

	public static function findPlaylist(stateSelector:AnimationStateSelector, animation:AnimationState, definedStates:Map<String, Array<String>>) {
		validateStateSelector(definedStates, stateSelector);
		return findBestStateMatch(animation.playlist, stateSelector, 'playlist: ${animation.name}');
	}

	public static function findExtraPoint(extraPointName:String, stateSelector:AnimationStateSelector, animation:AnimationState,
			definedStates:Map<String, Array<String>>) {
		validateStateSelector(definedStates, stateSelector);
		final allExtraPoints = animation.extraPoint.get(extraPointName);
		if (allExtraPoints == null) return null;
		return findBestStateMatch(allExtraPoints, stateSelector, 'extraPoint: $extraPointName');
	}

	public static function findAnimation(name:String, stateSelector:AnimationStateSelector, definedStates, animations) {
		validateStateSelector(definedStates, stateSelector);
		return findAnimationInternal(name, stateSelector, animations);
	}

	public static function findAnimationInternal(name:String, stateSelector:AnimationStateSelector, animations:Array<AnimationState>) {
		return findBestStateMatch(animations.filter(a -> a.name == name), stateSelector, 'animation: $name');
	}

	private static function findBestStateMatch<T:{var states:AnimConditionalSelector;}>(items:Array<T>, stateSelector:AnimationStateSelector,
			ambiguityContext:String):Null<T> {
		var bestScore = -1;
		var best2Score = -1;
		var best:Null<T> = null;
		var best2:Null<T> = null;
		for (item in items) {
			final count = countStateMatch(item.states, stateSelector);
			if (count > bestScore) {
				best2Score = bestScore;
				best2 = best;
				best = item;
				bestScore = count;
			} else if (bestScore == count) {
				best2 = best;
				best = item;
				best2Score = bestScore;
			}
		}
		if (best != null && best2 != null && best2Score == bestScore)
			throw 'ambiguous $ambiguityContext: ${best.states} vs ${best2.states} selector: $stateSelector';
		return best;
	}

	// ===================== Runtime Methods =====================

	function createAllStates(statesDefinitions:Map<String, Array<String>>):Array<AnimationStateSelector> {
		var totalStates = 1;
		var stateValuesCount:Array<Int> = [];
		var stateKeys:Array<String> = [];
		var stateValues:Array<Array<String>> = [];
		var retVal:Array<AnimationStateSelector> = [];
		for (key => value in statesDefinitions) {
			totalStates *= value.length;
			stateValuesCount.push(value.length);
			stateKeys.push(key);
			stateValues.push(value);
		}
		for (i in 0...totalStates) {
			final x:AnimationStateSelector = [];
			var ci = i;
			for (ki in 0...stateKeys.length) {
				final vi = ci % stateValuesCount[ki];
				ci = Std.int(ci / stateValuesCount[ki]);
				x.set(stateKeys[ki], stateValues[ki][vi]);
			}
			retVal.push(x);
		}
		return retVal;
	}

	function createStates(anims:Array<AnimPlaylistFrames>, anim:AnimationState, stateSelector:AnimationStateSelector):Array<AnimationFrameState> {
		final _center = center;
		final _sheetName = sheetName;
		if (_sheetName == null) throw 'sheet not set';
		final _fps = anim.fps;
		if (_fps == null) throw 'fps not set for animation ${anim.name}';
		final _flipX = anim.flipX == true; // (#13)
		final _flipY = anim.flipY == true; // (#13)

		// (#4) Replace ${key} with state value
		function replaceState(inputStr:String, stateSelector:AnimationStateSelector):String {
			var result = inputStr;
			for (key => value in stateSelector) {
				final pattern = "${" + key + "}";
				result = result.replace(pattern, value);
			}
			return result;
		}

		// (#13) Clone tile before flipping to avoid mutating shared atlas tiles.
		// Heaps' tile.flipX/Y mirrors around the pivot. We additionally shift by
		// (orig - 2*center) so the sprite stays in the same untrimmed screen footprint
		// regardless of where the pivot sits within the untrimmed area.
		function maybeFlipClone(tile:h2d.Tile, origW:Float, origH:Float):h2d.Tile {
			if (!_flipX && !_flipY) return tile;
			var cloned = tile.clone();
			final cx:Float = _center != null ? _center.x : 0;
			final cy:Float = _center != null ? _center.y : 0;
			if (_flipX) {
				cloned.flipX();
				cloned.dx += origW - 2 * cx;
			}
			if (_flipY) {
				cloned.flipY();
				cloned.dy += origH - 2 * cy;
			}
			return cloned;
		}

		function tileToFrame(tile:h2d.Tile, duration:Float):AnimationFrameState {
			if (_center != null) {
				tile.dx = -_center.x;
				tile.dy = -_center.y;
			}
			// Raw single-frame tiles have no trim — orig dimensions == tile dimensions
			final outTile = maybeFlipClone(tile, tile.width, tile.height);
			return Frame(new AnimationFrame(outTile, duration, 0, 0, outTile.iwidth, outTile.iheight));
		}

		function AFtoFrame(f:AnimationFrame, duration:Float):AnimationFrameState {
			if (_center != null) {
				f.tile.dx = f.offsetx - _center.x;
				f.tile.dy = (f.height - f.tile.height) - f.offsety - _center.y;
			}
			if (_flipX || _flipY) {
				// f.width / f.height = untrimmed (orig) dimensions from atlas
				return Frame(f.cloneWithNewTile(maybeFlipClone(f.tile, f.width, f.height)).cloneWithDuration(duration));
			}
			return Frame(f.cloneWithDuration(duration));
		}

		var retVal = [];
		final duration = 1.0 / _fps;
		for (frames in anims) {
			switch frames {
				case SheetFrameAnim(name, overrideDuration):
					final expandedName = replaceState(name, stateSelector);
					final sheet = resourceLoader.loadSheet2(_sheetName);
					if (sheet == null) throw 'sheet ${_sheetName} not found';
					final loadedTiles = sheet.getAnim(expandedName);
					if (loadedTiles == null) throw 'tiles ${name}->${expandedName} not found';
					var tiles = sheet.getAnim(expandedName);
					final _od = overrideDuration;
					var d = _od == null ? duration : _od / 1000.0;
					retVal = retVal.concat(Lambda.map(tiles, t -> AFtoFrame(t, d)));
				case SheetFrameAnimWithIndex(name, from, to, overrideDuration):
					final sheet = resourceLoader.loadSheet2(_sheetName);
					if (sheet == null) throw 'sheet ${_sheetName} not found';
					final expandedName = replaceState(name, stateSelector);
					final animTiles = sheet.getAnim(expandedName);
					if (animTiles == null) throw 'tiles ${name}->${expandedName} not found';
					final _od = overrideDuration;
					var d = _od == null ? duration : _od / 1000.0;
					for (i in 0...animTiles.length) {
						if ((from == null || i >= from) && (to == null || i <= to)) {
							retVal.push(AFtoFrame(animTiles[i], d));
						}
					}
				case FileSingleFrame(filename, overrideDuration):
					final _od = overrideDuration;
					var d = _od == null ? duration : _od / 1000.0;
					retVal.push(tileToFrame(resourceLoader.loadTile(filename), d));
				case PlaylistEvent(playlistEvent):
					retVal.push(Event(playlistEvent));
				case PlaylistEventData(name, meta): // (#9) convert MetadataValue map to String map for AnimationSM
					var strMeta:Map<String, String> = [];
					for (k => v in meta) {
						strMeta.set(k, switch v {
							case MVInt(i): Std.string(i);
							case MVFloat(f): Std.string(f);
							case MVString(s): s;
							case MVColor(c): '#${StringTools.hex(c, 6)}';
						});
					}
					retVal.push(Event(TriggerData(name, strMeta)));
				case PlaylistFilter(filterType): // (#12) per-frame filter change
					final builtFilter = buildAnimFilter(filterType);
					final tint:Null<Int> = switch filterType {
						case AFTint(c): c;
						default: null;
					};
					retVal.push(SetFilter(builtFilter, tint));
			}
		}
		return retVal;
	}

	function selectorToHex(selector:AnimationStateSelector):String {
		if (selector.count() == 0) return "";
		var indexes = Bytes.alloc(definedStatesIndexes.length);
		indexes.fill(0, indexes.length, 255);
		for (key => value in selector) {
			final idx = definedStatesIndexes.indexOf(key);
			if (idx == -1) throw 'invalid selector key ${key}';
			final vals = definedStates.get(key);
			if (vals == null) throw 'unknown state key: ${key}';
			indexes.set(idx, vals.indexOf(value));
		}
		return indexes.toHex();
	}

	function hexToSelector(hex:String):AnimationStateSelector {
		var selector:AnimationStateSelector = [];
		if (hex.length == 0) return selector;
		var indexes = Bytes.ofHex(hex);
		for (i in 0...indexes.length) {
			final key = definedStatesIndexes[i];
			final byteValue = indexes.get(i);
			final vals = definedStates.get(key);
			if (vals == null) throw 'unknown state key: ${key}';
			selector.set(key, vals[byteValue]);
		}
		return selector;
	}

	// (#12) Build a Heaps filter from an AnimFilterType. Returns null for tint (handled separately) and none.
	public static function buildAnimFilter(filter:AnimFilterType):Null<h2d.filter.Filter> {
		return switch filter {
			case AFTint(_): null;
			case AFNone: null;
			case AFBrightness(v):
				var m = new h3d.Matrix();
				m.identity();
				m.colorLightness(v);
				new h2d.filter.ColorMatrix(m);
			case AFSaturate(v):
				var m = new h3d.Matrix();
				m.identity();
				m.colorSaturate(v);
				new h2d.filter.ColorMatrix(m);
			case AFGrayscale(v):
				var m = new h3d.Matrix();
				m.identity();
				m.colorSaturate(-v);
				new h2d.filter.ColorMatrix(m);
			case AFHue(v):
				var m = new h3d.Matrix();
				m.identity();
				m.colorHue(v);
				new h2d.filter.ColorMatrix(m);
			case AFOutline(size, color):
				new h2d.filter.Outline(size, color);
			case AFPixelOutline(color):
				new PixelOutline(Knockout(color, 1.0), false);
			case AFReplaceColor(src, dst):
				ReplacePaletteShader.createAsColorsFilter(src, dst);
		};
	}

	// (#12) Resolve animation-level filters against state selector.
	// Returns matching filters and optional tint color.
	static function resolveAnimFilters(filters:Null<Array<AnimFilterEntry>>,
			stateSelector:AnimationStateSelector):{filter:Null<h2d.filter.Filter>, tintColor:Null<Int>} {
		if (filters == null || filters.length == 0) return {filter: null, tintColor: null};

		var tintColor:Null<Int> = null;
		var heapsFilters:Array<h2d.filter.Filter> = [];
		for (entry in filters) {
			if (countStateMatch(entry.states, stateSelector) >= 0) {
				switch entry.filter {
					case AFTint(color):
						tintColor = color;
					case AFNone: // skip
					default:
						final f = buildAnimFilter(entry.filter);
						if (f != null) heapsFilters.push(f);
				}
			}
		}
		var filter:Null<h2d.filter.Filter> = null;
		if (heapsFilters.length == 1)
			filter = heapsFilters[0];
		else if (heapsFilters.length > 1) {
			var group = new h2d.filter.Group();
			for (f in heapsFilters) group.add(f);
			filter = group;
		}
		return {filter: filter, tintColor: tintColor};
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
				final _flipX = anim.flipX == true; // (#13)
				final _flipY = anim.flipY == true; // (#13)
				// (#13) For Option B "flip in place", mirror extrapoints around the untrimmed
				// screen center, not the pivot. Need untrimmed dimensions from first frame.
				var origW:Float = 0;
				var origH:Float = 0;
				if (_flipX || _flipY) {
					var found = false;
					for (s in states) {
						if (found) continue;
						switch s {
							case Frame(f):
								origW = f.width;
								origH = f.height;
								found = true;
							default:
						}
					}
				}
				final cx:Float = center != null ? center.x : 0;
				final cy:Float = center != null ? center.y : 0;
				for (pointName in allowedExtraPoints) {
					var pt = findExtraPoint(pointName, stateSelector, anim, definedStates);
					if (pt != null) {
						var p = pt.toPoint();
						// (#13) Mirror around untrimmed screen center, matching Option B tile flip
						if (_flipX) p.x = Std.int(origW - 2 * cx) - p.x;
						if (_flipY) p.y = Std.int(origH - 2 * cy) - p.y;
						extraPoints.set(pointName, p);
					}
				}
				final loopCount:Int = anim.loop ?? 0;
				final resolved = resolveAnimFilters(anim.filters, stateSelector);
				cacheArray.push({name: name, states: states, loopCount: loopCount, extraPoints: extraPoints, filter: resolved.filter, tintColor: resolved.tintColor});
			}
			cache.set(hex, cacheArray);
		}

		final cacheEntries = cache.get(hex);
		if (cacheEntries == null) throw 'cache miss for hex ${hex}';
		for (e in cacheEntries) {
			animSM.addAnimationState(e.name, e.states, e.loopCount, e.extraPoints, e.filter, e.tintColor);
		}
	}

	public function createAnimSM(stateSelector:AnimationStateSelector):AnimationSM {
		var animSM = new AnimationSM(stateSelector);
		load(stateSelector, animSM);
		return animSM;
	}
}
#end

/**
 * Lightweight .anim validator for LSP/noheaps mode.
 * Tokenizes via AnimLexerHC, validates structure (matching braces,
 * known top-level keywords), and extracts symbols.
 * Does NOT build runtime objects — just checks syntax.
 */
class AnimParserLsp {
	var tokens:Array<AnimToken>;
	var tpos:Int;
	var sourceName:String;

	public var animationNames(default, null):Array<String> = [];
	public var stateDeclarations(default, null):Array<{name:String, values:Array<String>}> = [];
	public var hasMetadata(default, null):Bool = false;
	public var constants(default, null):Array<String> = [];

	public function new(src:String, sourceName:String) {
		this.sourceName = sourceName;
		final lexer = new AnimLexerHC(src, sourceName);
		tokens = [];
		while (true) {
			final t = lexer.nextToken();
			tokens.push(t);
			if (t.type == APEof) break;
		}
		tpos = 0;
	}

	inline function peek():APToken {
		return tokens[tpos].type;
	}

	function advance():Void {
		if (tpos < tokens.length - 1) tpos++;
	}

	function currentPos():ParsePosition {
		return new ParsePosition(sourceName, tokens[tpos].line, tokens[tpos].col);
	}

	function match(expected:APToken):Bool {
		if (peek() == expected) {
			advance();
			return true;
		}
		return false;
	}

	function skipBlock():Void {
		var depth = 1;
		while (depth > 0 && peek() != APEof) {
			switch (peek()) {
				case APCurlyOpen: depth++;
				case APCurlyClosed: depth--;
				default:
			}
			if (depth > 0) advance();
		}
		if (peek() == APCurlyClosed) advance();
	}

	function skipToNextTopLevel():Void {
		while (peek() != APEof) {
			switch (peek()) {
				case APIdentifier(_, kw, _) if (kw != null): return;
				case APAt: return;
				default: advance();
			}
		}
	}

	/**
	 * Validate the .anim file structure. Throws InvalidSyntax or AnimUnexpected on errors.
	 */
	public function validate():Void {
		while (peek() != APEof) {
			switch (peek()) {
				case APIdentifier(_, keyword, _):
					switch (keyword) {
						case APAnimation:
							advance();
							switch (peek()) {
								case APIdentifier(name, _, _):
									animationNames.push(name);
									advance();
								default:
									throw new InvalidSyntax("expected animation name", currentPos());
							}
							if (!match(APCurlyOpen)) throw new InvalidSyntax("expected '{' after animation name", currentPos());
							skipBlock();
						case APAnim:
							advance();
							switch (peek()) {
								case APIdentifier(name, _, _):
									animationNames.push(name);
									advance();
								default:
									throw new InvalidSyntax("expected anim name", currentPos());
							}
							skipToNextTopLevel();
						case APMetadata:
							advance();
							hasMetadata = true;
							if (!match(APCurlyOpen)) throw new InvalidSyntax("expected '{' after metadata", currentPos());
							skipBlock();
						case APStates:
							advance();
							if (!match(APColon)) throw new InvalidSyntax("expected ':' after states", currentPos());
							switch (peek()) {
								case APIdentifier(name, _, _):
									advance();
									final values:Array<String> = [];
									if (match(APOpen)) {
										while (peek() != APClosed && peek() != APEof) {
											switch (peek()) {
												case APIdentifier(v, _, _):
													values.push(v);
													advance();
												case APComma:
													advance();
												default:
													advance();
											}
										}
										match(APClosed);
									}
									stateDeclarations.push({name: name, values: values});
								default:
							}
						case APSheet | APCenter | APFps | APLoop | APAllowedExtraPoints | APFlipX | APFlipY:
							advance();
							if (!match(APColon)) throw new InvalidSyntax("expected ':'", currentPos());
							skipToNextTopLevel();
						default:
							advance();
					}
				case APAt:
					advance();
					switch (peek()) {
						case APIdentifier(_, APFinal, _):
							advance();
							switch (peek()) {
								case APIdentifier(name, _, _):
									constants.push(name);
									advance();
								default:
							}
							skipToNextTopLevel();
						default:
							advance();
					}
				default:
					advance();
			}
		}
	}
}
