package bh.multianim;

import bh.base.Particles;
import bh.base.MacroUtils;
import bh.base.filters.PixelOutline.PixelOutlineFilterMode;
import bh.base.Point;
import bh.multianim.layouts.MultiAnimLayouts;
import bh.base.PixelLine;
import bh.stateanim.AnimationSM;
import h2d.ScaleGrid;
import bh.base.Hex;
import bh.base.Hex.HexLayout;
import hxparse.Unexpected;
import hxparse.ParserError;
import bh.multianim.CoordinateSystems;
using StringTools;
using bh.base.ColorUtils;

enum OptionalParametersParsing {
	ParseInteger(name:String);
	ParseIntegerOrReference(name:String);
	ParseFloat(name:String);
	ParseFloatOrReference(name:String);
	ParseBool(name:String);
	ParseCustom(name:String, parse:()->Dynamic);
	ParseColor(name:String);
	
}

enum IdentifierType {
	ITString;
	ITReference;
	ITName;
	ITQuotedString;
}

enum MPInterpolationEnum {
	MPIStart;
	MPIEnd(stringValue:String);
	MPICode(prefix:String);
}

enum NumberType {
	NTInteger;
	NTFloat;
	NTHexInteger;
}

enum ValueType {
	VTInt;
	VTFloat;
	VTString;
}

enum MPToken {
	MPEof;
	MPOpen;
	MPClosed;
	MPBracketOpen;
	MPBracketClosed;
	MPCurlyOpen;
	MPCurlyClosed;
	MPComma;
	MPAt;
	MPExclamation;
	MPColon;
	MPDoubleDot;
	MPSemiColon;
	MPNumber(s:String, numberType:NumberType);
	MPIdentifier(s:String, keyword:Null<MPKeywords>, identType:IdentifierType);
	MPWhitespace;
	MPNewLine;
	MPArrow;
	MPStar;
	MPPercent;
	MPPlus;
	MPSlash;
	MPMinus;
	MPEquals;
	MPInterpolation(type:MPInterpolationEnum);
}

enum MPKeywords {
	MPTile;
	MPBit;
	MPCallback;
	MPFunction;
	MPBuilderParameter;
	MPNinePatch;
	MPApply;
	MPCenter;
	MPLeft;
	MPRight;
	MPTop;
	MPBottom;
	MPBitmap;
	MPHexDirection;
	MPGridDirection;
	MPRepeatable;
	MPHexGrid;
	MPOffset;
	MPGrid;
	MPHex;
	MPPoint;
	MPFlow;
	MPStateanim;
	MPConstruct;
	MPPixels;
	MPTileGroup;
	MPProgrammable;
	MPRelativeLayouts;
	MPLayout;
	MPLayers;
	MPPalette;
	MPLayer;
	MPSettings;
	MPPosition;
	MPImport;
	MPScale;
	MPFilter;
	MPFile;
	MPSheet;
	MPLoop;
	MPGenerated;
	MPAlpha;
	MPPos;
	MPFlat;
	MPPointy;
	MPHexEdge;
	MPHexCorner;
	MPLine;
	MPForward;
	MPTurn;
	MPBezier;
	MPCheckpoint;
	MPList;
	MPSequence;
	MPRect;
	MPFilledRect;
	MPFlags;
	MPError;
	MPNothing;
	MPText;
	MPVersion;
	MPPlaceholder;
	MPDebug;
	MPReference;
	MPIf;
	MPIfStrict;
	MPInteractive;
	MPInt;
	MPFloat;
	MPColor;
	MPUInt;
	MPBool;
	MPBlendMode;
	MPUpdatable;
	MPPaths;
	MPPath;
	MPParticles;
	MPAnimatedPath;
	MPDiv;
	MPExternal;
	MPArray;
}

enum PlaceholderTypes {
	PHTileSource(source:TileSource);
	PHError;
	PHNothing;
}

enum PlaceholderReplacementSource {
	PRSCallback(name:ReferencableValue);
	PRSCallbackWithIndex(name:ReferencableValue, index:ReferencableValue);
	PRSBuilderParameterSource(name:ReferencableValue);
}

@:using(bh.multianim.MultiAnimParser)
enum UpdatableNameType {
	UNTObject(name:String);
	UNTUpdatable(name:String);
}

typedef ResolvedSettings = Null<Map<String, String>>;

@:using(bh.multianim.MultiAnimParser)
typedef NamedBuildResult = {
	var type:UpdatableNameType;
	var object:BuiltHeapsComponent;
	var settings:ResolvedSettings;
	var gridCoordinateSystem:Null<GridCoordinateSystem>;
	var hexCoordinateSystem:Null<HexCoordinateSystem>;

}

function getBuiltHeapsObject(NamedBuildResult:NamedBuildResult) {
	return NamedBuildResult.object;
}

function asStateAnim(NamedBuildResult:NamedBuildResult) {
	return switch NamedBuildResult.object {
		case StateAnim(a): return a;
		default: throw 'expected stateAnim, got ${NamedBuildResult.object.getName()}';
	};
}


function getNameString(updatableNameType:UpdatableNameType) {
	return switch updatableNameType {
		case UNTObject(name): name;
		case UNTUpdatable(name): name;
	}
}

function toh2dObject(builtHeapsComponent:BuiltHeapsComponent):h2d.Object {
	return switch builtHeapsComponent {
		case HeapsObject(obj): obj;
		case Pixels(p): p;
		case StateAnim(a): a;
		case HeapsBitmap(b): b;
		case HeapsText(b): b;
		case NinePatch(s): s;
		case HeapsFlow(f): f;
		case HeapsLayers(layers): layers;
		case Particles(p): p;
	}
}

@:using(bh.multianim.MultiAnimParser)
enum BuiltHeapsComponent {
	HeapsObject(obj:h2d.Object);
	Pixels(t:PixelLines);
	StateAnim(a:AnimationSM);
	HeapsBitmap(b:h2d.Bitmap);
	HeapsText(b:h2d.Text);
	NinePatch(s:h2d.ScaleGrid);
	HeapsFlow(f:h2d.Flow);
	HeapsLayers(f:h2d.Layers);
	Particles(p:bh.base.Particles);
}


class MultiAnimUnexpected<Token> extends Unexpected<Token> {

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

class MultiAnimLexer extends hxparse.Lexer implements hxparse.RuleBuilder {
	static var buf:StringBuf = null;
	static var keywords = @:mapping(2, true) MPKeywords;
	static var integerDigits = '([0-9](_?[0-9])*)+';
	static var integer = '([1-9](_?[0-9])*)|0';
	
	static public var tok = @:rule [

		 "0x([0-9a-fA-F](_?[0-9a-fA-F])*)+" => {
			return MPNumber(lexer.current.substring(2), NTHexInteger);
		 },
		 integer  => MPNumber(lexer.current, NTInteger),
		integer + "\\." + integerDigits  => MPNumber(lexer.current, NTFloat), 
		"\\." + integerDigits => MPNumber(lexer.current, NTFloat),
		"[a-zA-Z_]+[a-zA-Z0-9_\\-]*" => {
			var str = lexer.current;
			return MPIdentifier(str, keywords.get(str.toLowerCase()), ITString);
		},
		"#[a-zA-Z0-9_\\-]+" => {
			var str = lexer.current;
			str = str.substr(1);
			return MPIdentifier(str, keywords.get(str.toLowerCase()), ITName);
		},
		"\\!" => MPExclamation,
		"$[a-zA-Z0-9_]+" => {
			var str = lexer.current;
			str = str.substr(1);
			return MPIdentifier(str, keywords.get(str.toLowerCase()), ITReference);
		},
		"\\*" => MPStar,
		"\\/" => MPSlash,
		"\\@" => MPAt,
		"\\+" => MPPlus,
		"\\%" => MPPercent,
		"\\-" => MPMinus,
		"\\.\\."=>MPDoubleDot,
		"\\(" => MPOpen,
		"\\)" => MPClosed,
		"\\{" => MPCurlyOpen,
		"\\}" => MPCurlyClosed,
		"\\[" => MPBracketOpen,
		"\\]" => MPBracketClosed,
		"," => MPComma,
		"=>" => MPArrow,
		":" => MPColon,
		"=" => MPEquals,
		";" => MPSemiColon,
		"[\n\r]" => lexer.token(tok),
		"//[^\n\r]*" => lexer.token(tok),
		"[ \t]" => lexer.token(tok),
		
		'"' => {
			buf = new StringBuf();
			lexer.token(string);
			MPIdentifier(buf.toString(), null, ITQuotedString);
		},
		"'" => {
			buf = new StringBuf();
			MPInterpolation(MPIStart);
		},
		"" => MPEof,
	];




	public static var string = @:rule [
		"\\\\\\\\" => {
			buf.add("\\\\");
			lexer.token(string);
		},
		"\\\\" => {
			buf.add("\\");
			lexer.token(string);
		},
		"\\\\\"" => {
			buf.add('"');
			lexer.token(string);
		},
		"\\\\n" => {
			buf.add('\n');
			lexer.token(string);

		},
		'"' => lexer.curPos().pmin,
		"[^\\\\\"]+" => {
			buf.add(lexer.current);
			lexer.token(string);
		}
	];

	public static var interpString = @:rule [
		"\\\\\\\\" => {
			buf.add("\\\\");
			lexer.token(interpString);
		},
		"\\\\n" => {
			buf.add('\n');
			lexer.token(interpString);
		},
		"\\\\" => {
			buf.add("\\");
			lexer.token(interpString);
		},
		"\\\\\"" => {
			buf.add('"');
			lexer.token(interpString);
		},
		"'" => {
			final s = buf.toString();
			buf = new StringBuf();
			MPInterpolation(MPIEnd(s));
		},
		"($$)|(\\$)" => {
			buf.add("$");
			lexer.token(interpString);
		},
		"\\${" => {
			final s = buf.toString();
			buf = new StringBuf();

			MPInterpolation(MPICode(s));
		},
		"[^\\$\\']+" => {
			buf.add(lexer.current);
			lexer.token(interpString);
		}
	];



}

@:nullSafety
class InvalidSyntax extends ParserError {

	public var error:String;
	public function new(error, pos, input) {
		super(pos);
		
		this.error = toStringWithInput(error, pos, input) ;
	}

	public override function toString() {
		return error;
	}

	static function toStringWithInput(err,pos, input) {
		return 'Error ${err}, ${pos.format(input)}';
	}
}

enum PixelShapes {
	LINE(line:PixelLine);
	RECT(rect:PixelRect);
	FILLED_RECT(rect:PixelRect);
}

@:NotNull
typedef PixelLine = {
	start:Coordinates,
	end:Coordinates,
	color:ReferencableValue
}

@:NotNull
typedef PixelRect = {
	start:Coordinates,
	width:ReferencableValue,
	height:ReferencableValue,
	color:ReferencableValue

}

enum DefinitionType {
	PPTHexDirecton;
	PPTGridDirection;
	PPTFlags(bits:Int);
	PPTEnum(values:Array<String>);
	PPTRange(from:Int, to:Int);
	PPTInt;
	PPTFloat;
	PPTBool;
	PPTUnsignedInt;
	PPTString;
	PPTColor;
	PPTArray;
}

typedef Definition = {
	name:String,
	type:DefinitionType,
	defaultValue:Null<ResolvedIndexParameters>
}

enum RvOp {
	OpAdd;
	OpMul;
	OpSub;
	OpDiv;
	OpIntegerDiv;
	OpMod;
}


enum ReferencableValueFunction { // Requires access to Node
	RVFGridWidth;
	RVFGridHeight;
}


enum ResolvedIndexParameters {
	Index(idx:Int, value:String);
	Value(val:Int);
	ValueF(val:Float);
	Flag(f:Int);
	StringValue(s:String);
	ArrayString(strArray:Array<String>);
}


enum ConditionalValues {
	CoEnums(a:Array<String>);
	CoRange(fromInclusive:Null<Float>, toInclusive:Null<Float>);
	CoIndex(idx:Int, value:String);
	CoValue(val:Int);
	CoFlag(f:Int);
	CoAny;
	CoStringValue(s:String);
	CoNot(value:ConditionalValues);

}


enum ReferencableValue {
	RVElementOfArray(arrayRef:String, index:ReferencableValue);
	RVString(s:String);
	RVInteger(i:Int);
	RVArray(refArr:Array<ReferencableValue>);
	RVArrayReference(refArr:String);
	RVFloat(f:Float);
	RVReference(ref:String);
	RVFunction(functionType:ReferencableValueFunction);
	RVParenthesis(e:ReferencableValue);
	RVCallbacksWithIndex(name:ReferencableValue, index:ReferencableValue, defaultValue:ReferencableValue);
	RVCallbacks(name:ReferencableValue, defaultValue:ReferencableValue);
	RVColorXY(externalReference:Null<String>, palette:String, x:ReferencableValue, y:ReferencableValue);
	RVColor(externalReference:Null<String>, palette:String, index:ReferencableValue);
	EBinop(op:RvOp, e1:ReferencableValue, e2:ReferencableValue);
}

enum HorizontalAlign {
	Left;
	Right;
	Center;
}

enum VerticalAlign {
	Top;
	Center;
	Bottom;
}

typedef ParametersDefinitions = Map<String, Definition>;

private enum LayoutsParsingState {
	LPSGrid;
	LPSHex;
	LPSOffset;
	LPSEnd;
}
@:nullSafety
typedef LayoutsDef = Map<String, Layout>;

enum AnimatedPathTime {
	Rate(float:ReferencableValue);
	Checkpoint(checkpointName:String);
}

@:structInit
class AnimatedPathTimedAction {
    public var at:AnimatedPathTime;
    public var action:AnimatedPathsAction;
}

@:nullSafety
enum AnimatedPathsAction {
	ChangeSpeed(speed:ReferencableValue);
    Event(eventName:String);
    AttachParticles(particlesName:String, particlesTemplate:String, particlesDef:ParticlesDef);
    RemoveParticles(particlesName:String);
    ChangeAnimSMState(state:String);
}


@:nullSafety
typedef AnimatedPathDef = Array<AnimatedPathTimedAction>;

@:nullSafety
enum ParsedPaths {
	LineTo(end:Coordinates);
	Forward(distance:ReferencableValue);
	TurnDegrees(angleDelta:ReferencableValue);
	Checkpoint(checkpointName:String);
	Bezier2To(end:Coordinates, control:Coordinates);
	Bezier3To(end:Coordinates, control1:Coordinates, control2:Coordinates);
}

@:nullSafety
typedef PathsDef = Map<String, Array<ParsedPaths>>;


enum ParticlesEmitMode {
	Point(emitDistance:ReferencableValue,  emitDistanceRandom:ReferencableValue);
	Cone(emitDistance:ReferencableValue, emitDistanceRandom:ReferencableValue, emitConeAngle:ReferencableValue, emitConeAngleRandom:ReferencableValue);
	Box(width:ReferencableValue, height:ReferencableValue, emitConeAngle:ReferencableValue, emitConeAngleRandom:ReferencableValue);
}

@:nullSafety
typedef ParticlesDef = {
	var count:Null<ReferencableValue>;
	var loop:Null<Bool>;
	var relative:Null<Bool>;
	var emitDelay:Null<ReferencableValue>;
	var emitSync:Null<ReferencableValue>;
	var maxLife:Null<ReferencableValue>;
	var lifeRandom:Null<ReferencableValue>;
	var size:Null<ReferencableValue>;
	var sizeRandom:Null<ReferencableValue>;
	var blendMode:Null<h2d.BlendMode>;
	var speed:Null<ReferencableValue>;
	var speedRandom:Null<ReferencableValue>;
	var speedIncrease:Null<ReferencableValue>;
	var gravity:Null<ReferencableValue>;
	var gravityAngle:Null<ReferencableValue>;
	var fadeIn:Null<ReferencableValue>;
	var fadeOut:Null<ReferencableValue>;
	var fadePower:Null<ReferencableValue>;
	var tiles:Array<TileSource>;
	var emit:ParticlesEmitMode;
	var rotationInitial:Null<ReferencableValue>;
	var rotationSpeed:Null<ReferencableValue>;
	var rotationSpeedRandom:Null<ReferencableValue>;
	var rotateAuto:Null<Bool>;
}

enum RepeatType {
	GridIterator(dx:ReferencableValue, dy:ReferencableValue, repeatCount:ReferencableValue);
	LayoutIterator(layoutName:String);
	ArrayIterator(valueVariableName:String, arrayName:String);
}

enum GeneratedTileType {
	Cross(width:ReferencableValue, height:ReferencableValue, color:ReferencableValue);
	SolidColor(width:ReferencableValue, height:ReferencableValue, color:ReferencableValue);
}

enum TileSource {
	TSFile(filename:ReferencableValue);
	TSSheet(sheet:ReferencableValue, name:ReferencableValue);
	TSSheetWithIndex(sheet:ReferencableValue, name:ReferencableValue, index:ReferencableValue);
	TSGenerated(type:GeneratedTileType);
}

enum PaletteType {
	PaletteColors(colors:Array<ReferencableValue>);
	PaletteColors2D(colors:Array<ReferencableValue>, width:Int);
	PaletteImageFile(filename:ReferencableValue);
}

enum StateAnimConstruct {
	IndexedSheet(sheet:String, name:ReferencableValue, fps:ReferencableValue, loop: Bool, center:Bool);
}

@:nullSafety
typedef TextDef = {
	var fontName:ReferencableValue;
	var text:ReferencableValue;
	var color:ReferencableValue;
	var halign:Null<HorizontalAlign>;
	var textAlignWidth:Null<Int>;
	var letterSpacing:Float;
	var lineSpacing:Float;
	var lineBreak:Bool;
	var dropShadowXY:Null<bh.base.FPoint>;
	var dropShadowColor:Int;
	var dropShadowAlpha:Float;
	var isHtml:Bool;
}

@:nullSafety
enum NodeType {
	FLOW(maxWidth:Null<ReferencableValue>, maxHeight:Null<ReferencableValue>, minWidth:Null<ReferencableValue>, minHeight:Null<ReferencableValue>,
		lineHeight:Null<ReferencableValue>, colWidth:Null<ReferencableValue>, layout:Null<h2d.Flow.FlowLayout>,
		paddingTop:Null<ReferencableValue>,paddingBottom:Null<ReferencableValue>, paddingLeft:Null<ReferencableValue>, paddingRight:Null<ReferencableValue>,
		horizontalSpacing:Null<ReferencableValue>, verticalSpacing:Null<ReferencableValue>, debug:Bool
		);
	BITMAP(tileSource:TileSource, hAlign:HorizontalAlign, vAligh:VerticalAlign);
	POINT;
	STATEANIM(filename:String, initialState:ReferencableValue, selector:Map<String, ReferencableValue>);
	STATEANIM_CONSTRUCT(initialState:ReferencableValue, construct:Map<String, StateAnimConstruct>);
	PIXELS(shapes:Array<PixelShapes>);
	TEXT(textDef:TextDef);
	PROGRAMMABLE(isTileGroup:Bool, parameters:ParametersDefinitions);
	TILEGROUP;
	RELATIVE_LAYOUTS(layoutsDef:LayoutsDef);
	PATHS(paths:PathsDef);
	ANIMATED_PATH(animatedPathDef:AnimatedPathDef);
	PARTICLES(particles:ParticlesDef);
	APPLY;
	LAYERS;
	REPEAT(varName:String, repeatType:RepeatType);
	REFERENCE(externalReference:Null<String>, programmableReference:String, parameters:Map<String, ReferencableValue>);
	PLACEHOLDER(type:PlaceholderTypes, replacementSource:PlaceholderReplacementSource);
	NINEPATCH(sheet:String, tilename:String, width:ReferencableValue, height:ReferencableValue);
	INTERACTIVE(width:ReferencableValue, height:ReferencableValue, id:ReferencableValue, debug:Bool);
	PALETTE(paletteType:PaletteType);

}

enum NodeConditionalValues {
	Conditional(values:Map<String, ConditionalValues>, strict:Bool);
	NoConditional;
}

enum FilterType {
	FilterNone;
	FilterGroup(filters:Array<FilterType>);
	FilterOutline(s:Float, color:Int);
	FilterSaturate(v:Float);
	FilterBrightness(v:Float);
	FilterGlow(color:Int, alpha:Float, radius:Float, gain:Float, quality:Float, smoothColor:Bool, knockout:Bool);
	FilterBlur(radius:Float, gain:Float, quality:Float, linear:Float);
	FilterDropShadow(distance:Float, angle:Float, color:Int, alpha:Float, radius:Float, gain:Float, quality:Float, smoothColor:Bool);
	FilterPixelOutline(mode:PixelOutlineFilterMode, smoothColor:Bool);
	FilterPaletteReplace(paletteName:String, sourceRow:ReferencableValue, replacementRow:ReferencableValue);
	FilterColorListReplace(sourceColors:Array<ReferencableValue>, replacementColors:Array<ReferencableValue>);

}

@:nullSafety
typedef Node = {
	parent:Null<Node>,
	pos:Coordinates,
	gridCoordinateSystem:Null<GridCoordinateSystem>,
	hexCoordinateSystem:Null<HexCoordinateSystem>,
	scale: Null<ReferencableValue>,
	alpha: Null<ReferencableValue>,
	layer:Null<Int>,
	filter: Null<FilterType>,
	blendMode: Null<h2d.BlendMode>,
	updatableName:UpdatableNameType,
	type:NodeType,
	children:Array<Node>,
	conditionals: NodeConditionalValues,
	uniqueNodeName:String,
	settings:Null<Map<String, ReferencableValue>>,
	#if MULTIANIM_TRACE	
	parserPos:String
	#end
}

typedef MultiAnimResult = {
	var nodes: Map<String, Node>;
	var imports:Map<String, MultiAnimBuilder>;
}

private enum PostParsedActions {
	PPAVerifyRelativeLayout(layoutName:String, pos:hxparse.Position);
	PPAUpdateAndVerifyParticlesTemplate(particleTemplate:String, particlesDef:ParticlesDef, pos:hxparse.Position);
}

class MultiAnimParser extends hxparse.Parser<hxparse.LexerTokenSource<MPToken>, MPToken> implements hxparse.ParserBuilder {
	final version = "0.1";
	public static final defaultLayoutNodeName = "#defaultLayout";
	public static final defaultPathNodeName = "#defaultPaths";
	final resourceLoader:bh.base.ResourceLoader;

	var imports:Map<String, MultiAnimBuilder> = [];
	var nodes:Map<String, Node> = [];
	var input:byte.ByteData;
	var postParsedActions:Array<PostParsedActions> = [];


	function new(input:byte.ByteData, sourceName, resourceLoader) {
		this.input = input;
		this.resourceLoader = resourceLoader;
		var lexer = new MultiAnimLexer(input, sourceName);
		var ts = new hxparse.LexerTokenSource(lexer, MultiAnimLexer.tok);
		super(ts);
	}

	public static function parseFile(input:byte.ByteData, sourceName:String, resourceLoader:bh.base.ResourceLoader) {
		try {
			var p =  new MultiAnimParser(input, sourceName, resourceLoader);
			return p.parse();
		} catch(ue:hxparse.Unexpected<Any>) {
			throw new MultiAnimUnexpected(ue.token, ue.pos, ue.toString(), input);
		} catch (e) {
			trace(e);
			throw e;
		}
		
	}

	function unexpectedError(?message:String):Dynamic {
		//throw '${peek(0)}, ${peek(1)}, ${peek(2)}';

		final error = new MultiAnimUnexpected(peek(0), stream.curPos(), message, input);
		trace(error);
		throw error;
		
	}

	function syntaxError(error, ?pos):Dynamic {
		final error = new InvalidSyntax(error, pos == null ? stream.curPos(): pos, input);
		trace(error);
		throw error;

	}

	inline function debugTrace(ahead:Int, ?name:String) {
			trace('debug trace $name: ${[for (i in 0...ahead) peek(i)]}');
	}


	
	function stringToInt(n) {
		var i = Std.parseInt(n);
		if (i != null) return i;
		return syntaxError('expected integer, got ${n}');
	}

	function stringToFloat(n) {
		var f = Std.parseFloat(n);
		if (f != Math.NaN) return f;
		return syntaxError('expected float, got ${n}');
	}


	function parseNextIntExpression(e1:ReferencableValue):ReferencableValue {
		return switch stream {
			case [MPPlus, e2 = parseIntegerOrReference()]:
				binop(e1, OpAdd, e2);
			case [MPMinus, e2 = parseIntegerOrReference()]:
				binop(e1, OpSub, e2);
			case [MPStar, e2 = parseIntegerOrReference()]:
				binop(e1, OpMul, e2);
			case [MPSlash, e2 = parseIntegerOrReference()]:
				binop(e1, OpDiv, e2);
			case [MPPercent, e2 = parseIntegerOrReference()]:
				binop(e1, OpMod, e2);
			case [MPIdentifier(_, MPDiv, ITString), e2 = parseIntegerOrReference()]:
				binop(e1, OpIntegerDiv, e2);
			case _:
				e1;
		}
	}

	function parseNextFloatExpression(e1:ReferencableValue):ReferencableValue {
		return switch stream {
			case [MPPlus, e2 = parseFloatOrReference()]:
				binop(e1, OpAdd, e2);
			case [MPMinus, e2 = parseFloatOrReference()]:
				binop(e1, OpSub, e2);
			case [MPStar, e2 = parseFloatOrReference()]:
				binop(e1, OpMul, e2);
			case [MPSlash, e2 = parseFloatOrReference()]:
				binop(e1, OpDiv, e2);
			case [MPPercent, e2 = parseFloatOrReference()]:
				binop(e1, OpMod, e2);
			case [MPIdentifier(_, MPDiv, ITString), e2 = parseIntegerOrReference()]:
				binop(e1, OpIntegerDiv, e2);
	
			case _:
				e1;
		}
	}

	function parseNextStringExpression(e1:ReferencableValue):ReferencableValue {
		return switch stream {
			case [MPPlus, e2 = parseStringOrReference()]:
				binop(e1, OpAdd, e2);
			case _:
				e1;
		}
	}


	function parseStringInterpolated():ReferencableValue {
		
		return switch stream {
				case [MPInterpolation(MPICode(prefix))]:
					stream.ruleset = MultiAnimLexer.tok;
					final retVal = binop(RVString(prefix), OpAdd, parseStringOrReference());

					switch stream {
						case [MPCurlyClosed]:
							stream.ruleset = MultiAnimLexer.interpString;
						case _: return unexpectedError();
					}
					
					binop(retVal, OpAdd, parseStringInterpolated());

				case [MPInterpolation(MPIEnd(strValue))]:
					RVString(strValue);
				case _:
					return unexpectedError("Unexpected interpolated string content");
			}
		
	}

	function binop(e1:ReferencableValue, op:RvOp, e2:ReferencableValue) {
		return switch [e2, op] {
			case [EBinop(op2 = OpAdd | OpSub, e3, e4), OpMul ]:
				// precedence
				EBinop(op2, EBinop(op, e1, e3), e4);
			case _:
				EBinop(op, e1, e2);
		}
	}



	function parseCallback(valueType:ValueType) {
	
		var index = null;
		switch stream {
			case [MPOpen, name = parseStringOrReference()]:
				switch stream {
					case [MPComma,  i = parseIntegerOrReference(), MPClosed]:
						index = i;
					case [MPClosed]:
						
				}
				final defaultValue = switch stream {
					case [MPEquals]:
						 switch valueType {
							case VTInt: parseIntegerOrReference();
							case VTFloat: throw 'no VTFloat parsing'; //parseNumberOrReference();
							case VTString: parseStringOrReference();
						}
					case _: null;
				}
				if (index != null) return RVCallbacksWithIndex(name, index, defaultValue);
				else return RVCallbacks(name, defaultValue);
			case _: return unexpectedError("expected callback");
			}
			
	}
	function parseUpdatable(name) {
		// trace('parseUpdatable: ${peek(0)}');
		return switch stream {
			case [MPIdentifier(_, MPUpdatable, ITString)]: UNTUpdatable(name);
			case _: return unexpectedError("expected updatable");
		}

	}
	
	function parseArrayOrReference():Array<ReferencableValue> {
		switch stream {
			case [MPBracketOpen]:
				var array = this.parseSeparated(x-> x.match(MPComma), parseStringOrReference.bind(false));
				switch stream {
					case [MPBracketClosed]:
						return array;
					case _: return unexpectedError("expected ]");
				}
		}
	}

	function parseStringArray():Array<String> {
		switch stream {
			case [MPBracketOpen]:
				var array = this.parseSeparated(x-> x.match(MPComma), parseStringValue);
				switch stream {
					case [MPBracketClosed]:
						return array;
					case _: return unexpectedError("expected ]");
				}
		}
	}

	function parseStringValue() {
		return switch stream {
			case [MPNumber(n, numberType)]:
				switch numberType {
					case NTInteger:n;
					case NTFloat:n;
					case NTHexInteger: '0x$n';
				}
			case [MPIdentifier(str, _, stringType)]:
				switch stringType {
					case ITString: str;
					case ITReference: '!$str';
					case ITName:'#$str';
					case ITQuotedString: str;
				}
			case [MPMinus]: '-${parseStringValue()}';
				
		}
	}

	function parseColorOrReference() {
		return switch stream {
			case [MPIdentifier(_, MPPalette, ITString), MPOpen]:
				
			var externalReference = switch stream {
				case  [MPIdentifier(_, MPExternal , ITString), MPOpen, MPIdentifier(er, _ , ITString | ITQuotedString), MPClosed, MPComma]: 
					var importedBuilder = imports.get(er);
					if (importedBuilder == null) syntaxError('external reference "$er" could not be found. It has to be imported BEFORE referencing it.');
					er;
				case _:  null;
			}

			switch stream {
				case [MPIdentifier(paletteName, _, ITString|ITQuotedString), MPComma, index = parseIntegerOrReference()]:
					return switch stream {
						case [MPComma, row = parseIntegerOrReference(), MPClosed]:
							RVColorXY(externalReference, paletteName, index, row);
						case [MPClosed]: RVColor(externalReference, paletteName, index);
						default: null;

					}
				case _: return unexpectedError("expected paletteName[, index]");
			}
			
			case _:
				final color = tryParseColor();
				if (color == null) return parseIntegerOrReference();
				else return RVInteger(color);
		}
		
	}

	
	function parseColor():Int {
		final color = tryParseColor();
		if (color == null) unexpectedError("unknown color");
		return color;
	}

	function parseColorsList(endSymbol) {
		var colors:Array<ReferencableValue> = [];
		while (true) {
			eatComma();
			if (peek(0) == endSymbol) {
				junk(); 
				break;
			}
			colors.push(parseColorOrReference());
		}
		return colors;
	}

	static function tryStringToColor(s:String):Null<Int> {
		var color = switch (s?.toLowerCase()) {
			case null: return null;
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
			case "cyan": 0x00FFFF;
			case "aqua": 0x00FFFF;
			case "blue": 0x0000FF;
			case "navy": 0x000080;
			case "black": 0x000000;
			case "gray": 0x808080;
			case "silver": 0xC0C0C0;
			case "white": 0xFFFFFF;
			default: null;
		}
		if (color != null) return color;
		else if (s.startsWith("0x")) {
			return Std.parseInt(s);
		}
		else if (s.startsWith("#")) {
			final colorStr = s.substring(1);
			final colorVal = Std.parseInt("0x" + colorStr);
			if (colorStr.length == 3) {
				
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
		
		return null;

	}

	function tryParseColor():Null<Int> {
		var color = switch (peek(0)) {
			case MPNumber(n, NTHexInteger):
				tryStringToColor("0x"+n);
			case MPIdentifier(color, _, ITString):
				tryStringToColor(color);
			case MPIdentifier(colorStr, _, ITName):
				tryStringToColor("#"+colorStr);
			case _: return null;

		}
		if (color != null) {
			junk();
			return color;
		} else return null;

	}

	function parseFunction():ReferencableValueFunction {
		return switch stream {
			case [MPIdentifier("gridWidth", _, ITString), MPClosed]: RVFGridWidth;
			case [MPIdentifier("gridHeight", _, ITString), MPClosed]:RVFGridHeight;
			case _: syntaxError("unknown function");
		}
	}

	function parseIntegerOrReference() {
		return switch stream {

			case [MPIdentifier(_, MPCallback, ITString)]: parseCallback(VTInt);
			case [MPIdentifier(_, MPFunction, ITString), MPOpen]: RVFunction(parseFunction());
			case [MPMinus, MPNumber(n, NTInteger|NTHexInteger)]:
				parseNextIntExpression(RVInteger(-stringToInt(n)));
			case [MPNumber(n, NTInteger|NTHexInteger)]:
				parseNextIntExpression(RVInteger(stringToInt(n)));
			case [MPIdentifier(s, _ , ITReference)]:
				switch stream {
					case [MPBracketOpen, index = parseIntegerOrReference(), MPBracketClosed]:
						parseNextIntExpression(RVElementOfArray(s, index));
					case _:
						parseNextIntExpression(RVReference(s));
				}
				
			case [MPOpen, e = parseIntegerOrReference(), MPClosed]:
				parseNextIntExpression(RVParenthesis(e));
				
			case _: syntaxError('expected integer or expression, got ${peek(0)}');
		}
		
	}

	function parseFloatOrReference() {
		return switch stream {

			case [MPIdentifier(_, MPCallback, ITString)]: parseCallback(VTFloat);
			case [MPIdentifier(_, MPFunction, ITString), MPOpen]: RVFunction(parseFunction());
			case [MPMinus, MPNumber(n, NTInteger|NTFloat)]:
				parseNextFloatExpression(RVFloat(-stringToFloat(n)));
			case [MPNumber(n, NTInteger|NTFloat)]:
				parseNextFloatExpression(RVFloat(stringToFloat(n)));
			case [MPIdentifier(s, _ , ITReference)]:
				switch stream {
					case [MPBracketOpen, index = parseIntegerOrReference(), MPBracketClosed]:
						parseNextFloatExpression(RVElementOfArray(s, index));
					case _:
						parseNextFloatExpression(RVReference(s));
				}
			case [MPOpen, e = parseFloatOrReference(), MPClosed]:
				RVParenthesis(e);				
			case _: syntaxError('expected float|integer or expression, got ${peek(0)}');
		}
		
	}

	function parseStringOrReference(?interpolated) {
//		 trace('PARSE NODES: ${peek(0)}');
		return switch stream {
			case [MPIdentifier(_, MPCallback, ITString)]: parseCallback(VTString);
			case [MPMinus, MPNumber(s, _)]:
				parseNextStringExpression(RVString('-' + s));
			case [MPNumber(s, _)|MPIdentifier(s, _, ITQuotedString|ITString)]:
				parseNextStringExpression(RVString(s));
			case [MPIdentifier(s, _ , ITReference)]:
				switch stream {
					case [MPBracketOpen, index = parseIntegerOrReference(), MPBracketClosed]:
						parseNextStringExpression(RVElementOfArray(s, index));
					case _:
						parseNextStringExpression(RVReference(s));
				}
			case [MPOpen, e = parseStringOrReference(), MPClosed]:
				RVParenthesis(e);				
			case [MPInterpolation(type)]:
				switch type {
					case MPIStart:
						final current = stream.ruleset;
						stream.ruleset = MultiAnimLexer.interpString;
						var r = parseStringInterpolated();
						stream.ruleset = current;
						r;
					case MPIEnd(x):
						RVString(x);
					case MPICode(prefix):
						stream.ruleset = MultiAnimLexer.tok;
						RVString(prefix);
						
				}
				
			//  case [MPBacktick]:
					
			case _: syntaxError('expected string or reference, got ${peek(0)}');
		}
	}

	public function parseInteger():Int {
		var val = tryParseInteger();
		if (val == null) syntaxError('expected number, got ${peek(0)}');
		return val;
	}
	public function tryParseInteger():Null<Int> {
		return switch stream {
			case [MPMinus, MPNumber(n, NTInteger|NTHexInteger)]:
				-stringToInt(n);
			case [MPNumber(n, NTInteger|NTHexInteger)]:
				 stringToInt(n);
			case _: null;
		}
	}

	public function parseFloat():Float {
		final sign = switch stream {
			case [MPMinus]: -1;
			case _: 1;
		}
		switch stream {
			case [MPNumber(n, _)]:
				return sign * stringToFloat(n);
			case _: return syntaxError('expected number, got ${peek(0)}');
		}
		
	}

	function parseXY():Coordinates {
		try {
			switch stream {
				case [MPIdentifier(_, MPGrid, ITString), MPOpen, x = parseIntegerOrReference(), MPComma, y = parseIntegerOrReference(), MPClosed]:
					return SELECTED_GRID_POSITION(x,y);
				case [MPIdentifier(_, MPHex, ITString), MPOpen, q = parseInteger(), MPComma, r = parseInteger(), MPComma, s = parseInteger(), MPComma, MPClosed]:
					
					if (q + r + s != 0) syntaxError("q + r + s must be 0");
					return SELECTED_HEX_POSITION(new Hex(q,r,s));
				
				
				case [MPIdentifier(_, MPLayout, ITString), MPOpen, MPIdentifier(layoutName, _, ITQuotedString|ITString)]:

					return switch stream {
						case [MPClosed]: 
							postParsedActions.push(PPAVerifyRelativeLayout(layoutName, stream.curPos()));
							LAYOUT(layoutName, null);
						case [MPComma, index = parseIntegerOrReference(), MPClosed]:
							
							postParsedActions.push(PPAVerifyRelativeLayout(layoutName, stream.curPos()));
							return LAYOUT(layoutName, index);
						case _: throw unexpectedError("Expected ) or , index)");
					}
					

				case [MPIdentifier(_, MPHexEdge, ITString)]:

					switch stream {
						case [MPOpen, dir = parseIntegerOrReference(), MPComma, factor = parseFloatOrReference(), MPClosed]:
							return SELECTED_HEX_EDGE(dir, factor);

						case _: throw unexpectedError("Expected (dir, scaleFactor)");
					}
					case [MPIdentifier(_, MPHexCorner, ITString)]:
						switch stream {
							case [MPOpen, dir = parseIntegerOrReference(), MPComma, factor = parseFloatOrReference(), MPClosed]:
								return SELECTED_HEX_CORNER(dir, factor);
		
							case _: throw unexpectedError("expected (direction, scaleFactor)");
						}
				
				case [x = parseIntegerOrReference(), MPComma, y = parseIntegerOrReference()]:
					return OFFSET(x, y);
			
				case _: return unexpectedError("Unexpected pos content");
			}
		}
		catch (e) {
			return syntaxError('Error parsing position: ${e} -  should be x,y | hexCorner | hexEdge | grid | hex | layout(name, layout[, index])');
		}

		
	}
	function parseSize():{width:Int, height:Int} {
		switch stream {
			case [ w = parseInteger(), MPComma, h = parseInteger()]:
				return {
					width: w,
					height: h
				};
			case _: return unexpectedError("expected int,int");
		}
	}

	function parsePoint():bh.base.Point {
		switch stream {
			case [ x = parseInteger(), MPComma, y = parseInteger()]:
				return {
					x: x,
					y:y
				};
			case _: return syntaxError("expected int,int");
		}
	}

	function parseFPoint():bh.base.FPoint {
		switch stream {
			case [ x = parseFloat(), MPComma, y = parseFloat()]:
				return {
					x: x,
					y: y
				};
			case _: return syntaxError("expected float,float");
		}
	}


	function parseOrientation():HexOrientation	 {
		switch stream {
			case [MPIdentifier(_, MPPointy, ITString)]: return POINTY;
			case [MPIdentifier(_, MPFlat, ITString)]: return FLAT;
			case _: syntaxError("pointy or edge expected");
		}
		return null;

	}

	static function tryStringToBool(val:String) {
		if (val == null) return null;
		return switch val.toLowerCase() {
			case "true"|"yes"|"1": true;
			case "false"|"no"|"0": false;
			default: null;
		}
	}

	function parseBool():Bool	 {
		return switch stream {
			case [MPIdentifier("yes"|"true", _, ITString)|MPNumber("1",_)]: true;
			case [MPIdentifier("no"|"false", _, ITString)|MPNumber("0",_)]: false;
			case _: syntaxError("expected true/false, 0/1 or yes/no");
		}

	}


	function parseDefines() {
		var defines:ParametersDefinitions = [];
		switch stream { // empty programmable defines
			case [MPClosed]: return defines;
			case _:
		}
		while (true) {
			final ppType = parseDefine();
			if (defines.exists(ppType.name)) syntaxError('parameter type ${ppType.name} already defined');
			defines.set(ppType.name, ppType);
			switch stream {
				case [MPClosed]: return defines;
				case [MPComma]:
					switch stream {
						case [MPComma]: syntaxError('double comma');
						case _:
					}
				case _: unexpectedError();
			}
		}
	}

	static function dynamicToInt(dynValue:Dynamic, err:String->Dynamic):Int {


		if (Std.isOfType(dynValue, Int)) {
			return dynValue;
		}
		else if (Std.isOfType(dynValue, String)) {
			
			switch (tryStringToBool(dynValue)) {
				case true: return 1;
				case false: return 0;
				case null:
			}
			final i = Std.parseInt(dynValue);
			if (i != null) return i;
			err('expected integer-ish in dynamicToInt, got parseInt error for ${dynValue}');
		}
		else if (Std.isOfType(dynValue, Bool)) {
			if (dynValue == true) return 1;
			else return 0;
		}
		else if (Std.isOfType(dynValue, ResolvedIndexParameters)) {
			final v:ResolvedIndexParameters =  cast dynValue;
			return switch v {
				case Value(i): i;
				default: err('expected integer-ish in dynamicToInt as ParameterValue, got ${dynValue}');
			}
		}
		
		return err('expected integer-ish in dynamicToInt, got ${dynValue}');
	}

	static function dynamicToFloat(dynValue:Dynamic, err:String->Dynamic):Float {


		if (Std.isOfType(dynValue, Int)) {
			return dynValue;
		}
		if (Std.isOfType(dynValue, Float)) {
			return dynValue;
		}
		else if (Std.isOfType(dynValue, String)) {
			
			final f = Std.parseFloat(dynValue);
			if (f != Math.NaN) return f;
			err('expected float-ish in dynamicToFloat, got parseInt error for ${dynValue}');
		}
		else if (Std.isOfType(dynValue, ResolvedIndexParameters)) {
			final v:ResolvedIndexParameters =  cast dynValue;
			return switch v {
				case Value(i): i;
				case ValueF(f): f;
				default: err('expected float-ish in dynamicToInt as ParameterValue, got ${dynValue}');
			}
		}
		
		return err('expected float-ish in dynamicToInt, got ${dynValue}');
	}

	static function dynamicToString(dynValue:Dynamic, err:String->Dynamic):String {

		if (dynValue == null) return "";
		if (Std.isOfType(dynValue, String)) {
			return dynValue;
		}
		else if (Std.isOfType(dynValue, Int)) {
			return '${dynValue}';
		}
		else if (Std.isOfType(dynValue, Bool)) {
			if (dynValue == true) return "true";
			else return "false";
		}
		else if (Std.isOfType(dynValue, ResolvedIndexParameters)) {
			final v:ResolvedIndexParameters =  cast dynValue;
			return switch v {
				case StringValue(s): s;
				case Value(i): '${i})';
				case ValueF(f): '${f})';
				default: return err('expected string-ish in dynamicToString, got ${dynValue}');
			}
		}
		return err('expected string-ish in dynamicToString, got ${dynValue}');

	}


	@:allow(bh.multianim.MultiAnimBuilder)
	static function dynamicToConditionalParam(inputValue:Dynamic, type:DefinitionType):ConditionalValues {
		
		function err(s):Dynamic {
			throw s;
		} 

		return switch type {
			case PPTHexDirecton:
				CoValue(dynamicToInt(inputValue, err));
			case PPTBool:
				CoValue(dynamicToInt(inputValue, err));
			case PPTGridDirection:
				CoValue(dynamicToInt(inputValue, err));
			case PPTFlags(bits):
				CoFlag(dynamicToInt(inputValue, err));
			case PPTEnum(values):
				final valStr = dynamicToString(inputValue, err);
				if (!values.contains(valStr)) err('define "${values}" does not contain value "${valStr}"');
				var index = values.indexOf(valStr);
				CoIndex(index, valStr);
			case PPTRange(from, to):
				CoValue(dynamicToInt(inputValue, err));
			case PPTInt:
				CoValue(dynamicToInt(inputValue, err));
			case PPTFloat:
				CoValue(dynamicToInt(inputValue, err));
			case PPTUnsignedInt:
				CoValue(dynamicToInt(inputValue, err)); // TODO:
			case PPTString: CoStringValue(dynamicToString(inputValue, err));
			case PPTArray: err('cannot use array as conditional parameter');
			case PPTColor: 
				if (Std.isOfType(inputValue, String)) {
					var color = tryStringToColor(inputValue);
					if (color == null) err('expected color, got ${inputValue}');
					CoValue(color);
				} else CoValue(dynamicToInt(inputValue, err)); 

		}

	}




	@:allow(bh.multianim.MultiAnimBuilder)
	static function dynamicValueToIndex(name:String, type:DefinitionType, value:Dynamic, error:String->Dynamic) {

		switch type {
			case PPTHexDirecton:
				var dir = dynamicToInt(value, error);
				if (dir < 0 || dir >= 6) error('hexdirection must be 0...5');
				return Value(dir);
			case PPTGridDirection:
				var dir = dynamicToInt(value, error);
				if (dir < 0 || dir >= 8) error('griddirection must be 0...7');
				return Value(dir);
			case PPTFlags(bits):
				var f = dynamicToInt(value, error);
				final maxVal = 2 << bits;
				if (f < 0 || f > maxVal) error('flag have ${bits} and max value is ${maxVal}, yours was ${f}');
				return Flag(f);
			case PPTBool:
				return switch value {
					case StringValue(s):
						var b = tryStringToBool(s);
						if (b != null) return Value(b ? 1 : 0);
						error('invalid bool from string ${s}');
						
					case Value(i):

						if (i > 0) return Value(0);
						else if (i == 0) return Value(1);
						error('invalid bool from int ${value}');
					default: return Value(dynamicToInt(value, error-> throw('invalid bool from ${value} ' + error)));
				}

			case PPTEnum(values):
				final valStr = dynamicToString(value, error);
				if (!values.contains(valStr)) error('define "${name}" does not contain value "${valStr}"');
				var index = values.indexOf(valStr);
				return Index(index, valStr);
			case PPTRange(from, to):
				var num = dynamicToInt(value, error);
				if (num < from || num > to) error('define "${name}" must be ${from}..${to} but was ${num}');
				return Value(num);
			case PPTInt: 
				var num = dynamicToInt(value, error);
				return Value(num);
			case PPTFloat:
				var num = dynamicToFloat(value, error);
				return ValueF(num);
			case PPTArray: 
				if (value is Array) {
					var arrVal:Array<Dynamic> = cast value;
					return ArrayString([for (v in arrVal) dynamicToString(v, error)]);
				} 
				else return error('invalid array value ${value}');

			case PPTColor: 
				if (Std.isOfType(value, String)) {
					var color = tryStringToColor(value);
					if (color == null) error('expected color, got ${value}');
					return Value(color);
				} else return Value(dynamicToInt(value, error)); 
				// var num = paramValueToInt(value, error);
				// return Value(num);
			case PPTUnsignedInt:
				var num = dynamicToInt(value, error);
				if (num < 0) error('define ${name}" must be unsigned integer but was ${num}');
					return Value(num);
			case PPTString:
				return StringValue(dynamicToString(value, error));
		}
	}

	function parseDefaultParameterValue(param:Definition) {
		switch stream {
			case [MPEquals]:
				switch param.type {
					case PPTColor: 
						param.defaultValue = Value(parseColor());

					case PPTArray:
						param.defaultValue = ArrayString(parseStringArray());
					default:
						final s = switch stream {
							case [MPIdentifier(str, _, _)| MPNumber(str, _)]: str;
							case [MPMinus, MPNumber(str, _)]: '-' + str;
						}
						param.defaultValue = dynamicValueToIndex(param.name, param.type, s, s->syntaxError(s));

				}
			case _:
		}

	}
	function parseDefine() {


		var parameter:Definition = {
			name: null,
			type: PPTHexDirecton,
			defaultValue: null
		};
		switch stream {
			case [MPIdentifier(paramName, _, ITString)]:
				switch stream {
					case [MPColon]:
					case [MPEquals, MPIdentifier(defaultString, _, ITQuotedString)]:
						parameter.name = paramName;
						parameter.type = PPTString;
						parameter.defaultValue = StringValue(defaultString);
						return parameter;

				}
				parameter.name = paramName;
			case [MPColon]:
				switch stream {
					case [MPIdentifier(hexDirection, MPHexDirection, _)]:
						parameter.name = hexDirection;
						parameter.type = PPTHexDirecton;
						parseDefaultParameterValue(parameter);
						return parameter;
					case [MPIdentifier(gridDirection, MPGridDirection, _)]:
						parameter.name = gridDirection;
						parameter.type = PPTGridDirection;
						parseDefaultParameterValue(parameter);
						return parameter;
				
					
				}
			case _: unexpectedError("Unknown parameter define - expected = \"string\" or :hexDirection or :gridDirection");
		}
		switch stream {

			case [MPIdentifier(_, MPHexDirection, ITString)]: 
				parameter.type = PPTHexDirecton;
			case [MPNumber(from, NTInteger), MPDoubleDot, MPNumber(to, NTInteger)]: 
				parameter.type = PPTRange(stringToInt(from), stringToInt(to));
			case [MPIdentifier(_, MPFlags, ITString), MPOpen, bits = parseInteger(), MPClosed]: 
					parameter.type = PPTFlags(bits);
			case [MPIdentifier(_, MPInt, ITString)]: 
				parameter.type = PPTInt;
			case [MPIdentifier(_, MPFloat, ITString)]: 
				parameter.type = PPTFloat;
			case [MPIdentifier(_, MPUInt, ITString)]: 
				parameter.type = PPTUnsignedInt;
			case [MPIdentifier(_, MPColor, ITString)]: 
				parameter.type = PPTColor;
			case [MPIdentifier(_, MPBool, ITString)]: 
				parameter.type = PPTBool;
			case [MPIdentifier(_, MPArray, ITString)]: 
				parameter.type = PPTArray;
			
			case [MPBracketOpen]: 
				var enumNames = [];
				while(true) {
					switch stream {
						// TODO: handle -int (e.g. -3)?
						case [MPIdentifier(e, _, ITString|ITQuotedString)| MPNumber(e, _)]: 
							if (enumNames.contains(e)) syntaxError('{e} already defined in enum');
							enumNames.push(e);
						case [MPBracketClosed]: 
							parameter.type = PPTEnum(enumNames);
							break;
						case [MPComma]:
							switch stream {
								case [MPComma]: syntaxError('double comma');
								case _:
							}
					}
				}

		}

		parseDefaultParameterValue(parameter);
		return parameter;
	}

	function parseReferenceParameters(defined:ParametersDefinitions):Map<String, ReferencableValue> {

		function error(s:String):Dynamic {
			return syntaxError(s);
		}
		final parameterValues:Map<String, ReferencableValue> = [];
		while (true) {
			
			switch stream {
				case [MPIdentifier(name, _, ITString|ITQuotedString), MPArrow]:
					final paramDefinitions = defined.get(name);
					
					if (paramDefinitions == null) syntaxError('param $name does not have definition in $defined');
					if (parameterValues.exists(name)) syntaxError('param ${name} already defined');
					switch stream {
						case [MPIdentifier(_, MPBit, ITString), ]:
							var bitValue = 0;
							while (true) {
								switch stream {
									case [MPNumber(value, NTInteger)]:
										final bitNumber = stringToInt(value);
										bitValue |= 1 << bitNumber;
								}
								switch stream {
									case [MPComma]:
									case _: break;
								}
							}
							parameterValues.set(name, RVInteger(bitValue));
						case _:
							var type = paramDefinitions.type;
							var value = switch type {
								case PPTHexDirecton:  parseIntegerOrReference();
								case PPTGridDirection: parseIntegerOrReference();
								case PPTFlags(bits): parseIntegerOrReference();
								case PPTEnum(values): parseStringOrReference();
								case PPTRange(from, to): parseIntegerOrReference();
								case PPTInt:	parseIntegerOrReference();
								case PPTFloat: parseFloatOrReference();
								case PPTBool: parseStringOrReference();
								case PPTUnsignedInt: parseIntegerOrReference();
								case PPTString: parseStringOrReference();
								case PPTColor: parseColorOrReference();
								case PPTArray: RVArray(parseArrayOrReference());
							}
							parameterValues.set(name, value);
					}
					
				case _: unexpectedError("expected parameters");
			}

			switch stream {
				case [MPClosed]: return parameterValues;
				case [MPComma]: 
				case _: unexpectedError("Expected ) or ,");
			
			}

		}
	}

	
	function parseConditionalParameters(defined:ParametersDefinitions, strict:Bool):Map<String, ConditionalValues> {
		final parameterValues:Map<String, ConditionalValues> = [];

		function validateIntTypes(name:String, type:DefinitionType, value:Dynamic) {
			switch type {
				case PPTHexDirecton:
					var i = dynamicToInt(value, s->syntaxError(s));
					if (i < 0 || i > 5) syntaxError('conditional $name: hexdirection must be 0...5, was $value');
				case PPTGridDirection:
						var i = dynamicToInt(value, s->syntaxError(s));
						if (i < 0 ||  i > 3) syntaxError('conditional $name: gridDrection must be 0...3, was $value');
				case PPTFlags(bits):


				case PPTRange(from, to):
					var i = dynamicToInt(value, s->syntaxError(s));										
					if (i < from || i > to) syntaxError('conditional $name: range must be $from..$to, was $value');

				case PPTInt:
				case PPTFloat:
				case PPTBool: 
				case PPTColor: syntaxError('conditional $name: type $type does not support enum conditional');
				case PPTUnsignedInt:
				case PPTString:
				case PPTArray: syntaxError('conditional $name: type $type does not support array conditional');
				case PPTEnum(values):
				
			}
		}


		while (true) {
			
			switch stream {
				case [MPIdentifier(name, _, ITString|ITQuotedString), MPArrow]:

				var negate = switch stream {
					case [MPExclamation]: true;
					case _: false;
				}
	
					final paramDefinitions = defined.get(name);
					if (paramDefinitions == null) syntaxError('conditional parameter $name does not have definition in $defined');
					if (parameterValues.exists(name)) syntaxError('conditional parameter ${name} already defined');
					
					final type = paramDefinitions.type;
					
					var value = switch stream {
						case [MPIdentifier(_, MPBit, ITString), MPBracketOpen]:
							var bitValue = 0;
							while (true) {
								switch stream {
									case [MPNumber(value, NTInteger)]:
										final bitNumber = stringToInt(value);
										bitValue |= 1 << bitNumber;
								}
								eatComma();
								switch stream {
									case [MPBracketClosed]: break;
									case _: 
								}
							}
							dynamicToConditionalParam(bitValue, type);
						case [MPIdentifier("greaterThan", _, ITString), val = parseInteger()]:
							validateIntTypes(name, type, val);
							CoRange(val, null);
						case [MPIdentifier("lessThan", _, ITString), val = parseInteger()]:
							
							validateIntTypes(name, type, val);
							CoRange(null, val);
						case [MPIdentifier("between", _, ITString), val1 = parseInteger(), MPDoubleDot, val2 = parseInteger()]:
							
							validateIntTypes(name, type, val1);
							validateIntTypes(name, type, val2);
							CoRange(val1, val2);
						case [MPIdentifier(value, _, ITString|ITQuotedString)]:
							dynamicToConditionalParam(value, type);
						case [MPIdentifier(value, _, ITName)]:
							dynamicToConditionalParam("#"+value, type);
						case [MPNumber(value, NTInteger|NTFloat)]:
							dynamicToConditionalParam(value, type);
						case [MPNumber(value, NTHexInteger)]:
							dynamicToConditionalParam("0x"+value, type);
						case [MPMinus, MPNumber(value,_)]:
							dynamicToConditionalParam('-'+value, type);
						case [MPStar]:
							CoAny;
						case [MPBracketOpen]:
							final values:Array<String> = [];
							while (true) {
								switch stream {
									case [MPBracketClosed]: break;
									case [MPIdentifier(value, _, ITString|ITQuotedString)|MPNumber(value, NTInteger)]:
										values.push(value);
									 case [MPMinus, MPNumber(value, NTInteger)]:
										values.push("-"+value);
								}
								eatComma();
							}


							for (s in values) {
								validateIntTypes(name, type, s);
							}

							switch type {
								case PPTEnum(defValues):
									for (s in values) {
										if (!defValues.contains(s)) syntaxError('conditional $name: enum value $s not in $defValues');
									}
								default:
							}
							CoEnums(values);

					}
					if (negate) value = CoNot(value);
					parameterValues.set(name, value);
					
					
				case _: unexpectedError("expected parameters");
			}

			switch stream {
				case [MPClosed]: break; 
				case [MPComma]: 
				case _: unexpectedError("Expected ) or ,");
			
			}

		}
		if (strict) {
			for (name => value in defined) {
				if (!parameterValues.exists(name) && value.defaultValue == null)  syntaxError('conditional parameter ${name} without default value has not been specified in strict @conditional');
			}
		}
		return parameterValues;
	}


	function parseStateAnimConstruct() {
		final stateAnimConstruct:Map<String, StateAnimConstruct> = [];

		while (true) {
			switch stream {
				case [MPClosed]: return stateAnimConstruct;
				case [MPSemiColon]:
				case [MPIdentifier(stateName, _, ITString|ITQuotedString), MPArrow, MPIdentifier(_, MPSheet, ITString), MPIdentifier(sheet, _, ITString|ITQuotedString), MPComma, name = parseStringOrReference(), MPComma, fps = parseIntegerOrReference()]:
						eatComma();
						var loop = false;
						var center = false;
						while (true) {
							switch stream {
								case [MPIdentifier(_, MPLoop, ITString)]: loop = true;
								case [MPIdentifier(_, MPCenter, ITString)]: center = true;
								case _:  break;
							}
							eatComma();	
						}

						if (stateAnimConstruct.exists(stateName)) syntaxError('duplicate state name ${stateName}');
						stateAnimConstruct.set(stateName, IndexedSheet(sheet, name, fps, loop, center));
				case _: syntaxError('expected stateName => sheet "sheetName", "anim", fpsInt');
		

			}
		}
	}


	function parseShapes() {
		var shapes:Array<PixelShapes> = [];
		while (true) {
			switch stream {
				case [MPClosed]: return shapes;
				case [MPSemiColon]:
				case [MPIdentifier(_, MPLine, ITString), 
							start = parseXY(), MPComma, 
							end = parseXY(), MPComma, 
							color = parseColorOrReference()]:
						shapes.push(LINE({
							start:start, 
							end:end,
							color: color
						}));
				case [MPIdentifier(_, MPRect, ITString), 
							start = parseXY(), MPComma, 
							width = parseIntegerOrReference(), MPComma, 
							height = parseIntegerOrReference(), MPComma, 
							color = parseColorOrReference()]:
					shapes.push(RECT({
						start: start,
						width: width,
						height: height,
						color: color
					}));
				case [MPIdentifier(_, MPFilledRect, ITString), 
							start = parseXY(), MPComma, 
							width = parseIntegerOrReference(), MPComma, 
							height = parseIntegerOrReference(), MPComma, 
							color = parseColorOrReference()]:
					
					shapes.push(FILLED_RECT({
						start: start, 
						width: width,
						height: height,
						color: color
					}));

			}
		}
	}

	function parseFlowOrientation():h2d.Flow.FlowLayout {
		return switch stream {
			case [MPIdentifier("horizontal", _, ITString|ITQuotedString)]: Horizontal;
			case [MPIdentifier("vertical", _, ITString|ITQuotedString)]: Vertical;
			case [MPIdentifier("stack", _, ITString|ITQuotedString)]: Stack;
		}
	}
	function parseHAlign():Null<HorizontalAlign> {
		return switch stream {
			case [MPIdentifier(_, MPCenter, ITString|ITQuotedString)]: Center;
			case [MPIdentifier(_, MPLeft, ITString|ITQuotedString)]: Left;
			case [MPIdentifier(_, MPRight, ITString|ITQuotedString)]: Right;
			case _: null;
		}
	}

	function parseVAlign():Null<VerticalAlign> {
		return switch stream {
			case [MPIdentifier(_, MPTop, ITString|ITQuotedString)]: Top;
			case [MPIdentifier(_, MPBottom, ITString|ITQuotedString)]: Bottom;
			case [MPIdentifier(_, MPCenter, ITString|ITQuotedString)]: Center;
			case _: null;
		}
	}

	function generateUniqueName(uniqueId:Int, name:String, type:String) {
		return '$type/${name != null? name : ""}/$uniqueId';
	}

	function parseTileSources():Array<TileSource> {
		var retVal = [];
		while (true) {
			var tile = tryParseTileSource();
			if (tile == null) {
				if (retVal.length == 0) syntaxError('expected at least one tile source');
				return retVal;
			}
			else retVal.push(tile);
		}
	}	

	
	function tryParseTileSource() {
		return switch stream {
			case [MPIdentifier(_, MPSheet, ITString), MPOpen, sheet = parseStringOrReference(), MPComma, name = parseStringOrReference()]:
				switch stream {
					case [MPClosed]:TSSheet(sheet, name);
					case [MPComma, index = parseIntegerOrReference(), MPClosed]:TSSheetWithIndex(sheet, name, index);
				}
				
			case [MPIdentifier(_, MPFile, ITString), MPOpen, filename = parseStringOrReference(), MPClosed]: 
				TSFile(filename);
			case [MPIdentifier(_, MPGenerated, ITString), MPOpen ]: 
				switch stream {
					case [MPIdentifier("cross", _ , ITString), MPOpen, width = parseIntegerOrReference(), MPComma, height = parseIntegerOrReference()]: 
						final color = switch stream {
							case [MPComma, color = parseColorOrReference(), MPClosed, MPClosed]:
							case [MPClosed, MPClosed]:RVInteger(0xFFFFFFFF);

						}
						TSGenerated(Cross(width, height, color));
					case [MPIdentifier("color", _ , ITString), MPOpen, width = parseIntegerOrReference(), MPComma, height = parseIntegerOrReference()]: 
						final color = switch stream {
							case [MPComma, color = parseColorOrReference(), MPClosed, MPClosed]: color;
							case [MPClosed, MPClosed]:RVInteger(0xFFFFFFFF);

						}
						TSGenerated(SolidColor(width, height, color));
					case _: unexpectedError('expected cross(width, height[, color] or color(width, height[, color]');
				}

				
			case _: null;
		}
	}
	function parseTileSource() {
		var ts = tryParseTileSource();
		if (ts == null) unexpectedError("expected sheet(sheet, name), file(filename) or generated(cross(width, height[, color]) | color(width, height[, color])");
		return ts;

	}


	function parseNode(updatableNameType:UpdatableNameType, parent:Null<Node>,  inheritedDefinitions:ParametersDefinitions, uniqueId:Int):Node {
		
		var currentDefinitions = inheritedDefinitions;
		

		var allowChildren = true;
		final onceInline = createOnceParser();
		var layerIndex = -1;
		var alpha:Null<ReferencableValue> = null;
		var scale:Null<ReferencableValue> = null;
		var conditional = NoConditional;
		
		#if MULTIANIM_TRACE
		final parserPos = stream.curPos();
		#end
		switch stream {
			case [MPAt]:
				var atLestOneInline = 0;
				while (true) {
					switch stream {
						case [MPIdentifier(_, MPIf, ITString), MPOpen]: 
							final strict = false;
							onceInline.parsed("conditional");
							conditional = Conditional(parseConditionalParameters(currentDefinitions, strict), strict);
						case [MPIdentifier(_, MPIfStrict, ITString), MPOpen]: 
							final strict = true;
							onceInline.parsed("conditional");
							conditional = Conditional(parseConditionalParameters(currentDefinitions, strict), strict);
						case [MPOpen]: 
							final strict = false;
							onceInline.parsed("conditional");
							conditional = Conditional(parseConditionalParameters(currentDefinitions, strict), strict);
						case [MPIdentifier(s, MPLayer, ITString), MPOpen, i = parseInteger(), MPClosed]:
							onceInline.parsed(s);
							layerIndex = i;
							
							var layersAllowed = parent != null && switch parent.type {
								case PROGRAMMABLE(_,_)|LAYERS: true;
								default: false;
							}
							if (!layersAllowed) syntaxError('layer requires parent node to be either programmable or layers but was ${parent.type}');
						case [MPIdentifier(s, MPAlpha, ITString), MPOpen, a = parseFloatOrReference(), MPClosed]:
							onceInline.parsed(s);
							alpha = a;
						case [MPIdentifier(s, MPScale, ITString), MPOpen, sc = parseFloatOrReference(), MPClosed]:
							onceInline.parsed(s);
							scale = sc;
						case _: break;
					}
					atLestOneInline++;
					
			
				}
				if (atLestOneInline == 0) syntaxError('at least one conditional or inline property is required when using @');
			case _: 
		}
		 

		final gridCoordinateSystem = getGridCoordinateSystem(parent);	// TODO: remove or check if this is supposed to be used
		final hexCoordinateSystem = getHexCoordinateSystem(parent);
		var nameString = updatableNameType.getNameString();


		function createNodeResponse(type) {
			return {
				pos:ZERO,
				scale: scale,
				alpha: alpha,
				layer:layerIndex,
				gridCoordinateSystem:null,
				hexCoordinateSystem:null,
				blendMode: null, //h2d.BlendMode.Alpha,
				filter: null, //FilterNone,
				parent:parent,
				updatableName:updatableNameType,
				type:type,
				children:[],
				conditionals:conditional,
				uniqueNodeName: generateUniqueName(uniqueId, nameString, Std.string(type)),
				settings: null,
				#if MULTIANIM_TRACE
				parserPos:parserPos.format(this.input)
				#end
			};
		}


	
		final node:Node = switch stream {

			case [MPIdentifier(_, MPBitmap, ITString), MPOpen]:
				var tileSource = parseTileSource();

				var vAlign:VerticalAlign = Top;
				var hAlign:HorizontalAlign = Left;
				switch stream {
					case [MPClosed]: 
					case [MPComma, a = parseHAlign()]: 
						hAlign = a;
						if (a == null) syntaxError("invalid Horizontal align");
						switch stream {
							case [MPClosed]: 
								if (hAlign == Center) vAlign = Center;
							case [MPComma, v = parseVAlign(), MPClosed]:  vAlign = v;
							if (v == null) syntaxError("invalid vertical align");
							case _: unexpectedError("Expected ) or , vertical align");		
						}


					case _: unexpectedError("Expected ) or , horizontal align");
				}

				createNodeResponse(BITMAP(tileSource, hAlign, vAlign));
				
			case [MPIdentifier(_, MPNinePatch, _), MPOpen, MPIdentifier(sheet,_, ITString|ITQuotedString), MPComma, MPIdentifier(tilename,_, ITString|ITQuotedString), MPComma, width = parseIntegerOrReference(), MPComma, height = parseIntegerOrReference(), MPClosed]:
				createNodeResponse(NINEPATCH(sheet, tilename, width, height));
			
			case [MPIdentifier(_, MPApply, ITString)]:
				if (parent == null) syntaxError('apply cannot be root node');
				allowChildren = false;
				createNodeResponse(APPLY);

			case [MPIdentifier(_, MPStateanim, ITString)]:

				switch stream {
					case [MPOpen, MPIdentifier(filename,_, ITString|ITQuotedString), MPComma, initialState = parseStringOrReference()]:
						var selector:Map<String, ReferencableValue> = [];
						while (true) {
							switch stream {
								case [MPClosed]: break;
								case [MPComma, MPIdentifier(key,_, ITString|ITQuotedString)| MPNumber(key, _), MPArrow, value = parseStringOrReference()]:
									if (selector.exists(key)) syntaxError('${key} already set');
									selector.set(key, value);
								}
		
						}
						createNodeResponse(STATEANIM(filename, initialState, selector));
					case [MPIdentifier(_, MPConstruct, ITString), MPOpen, initialState = parseStringOrReference()]:
						eatComma();
						final constructs = parseStateAnimConstruct();	
		
						createNodeResponse(STATEANIM_CONSTRUCT(initialState, constructs));
				}
				
			case [MPIdentifier(_, MPFlow, ITString), MPOpen]:
				var once = createOnceParser();

				

				var maxWidth:Null<ReferencableValue> = null;
				var maxHeight:Null<ReferencableValue> = null;
				var minWidth:Null<ReferencableValue> = null;
				var minHeight:Null<ReferencableValue> = null;
				
				var lineHeight:Null<ReferencableValue> = null;
				var colWidth:Null<ReferencableValue> = null;
				var layout:Null<h2d.Flow.FlowLayout> = null;
				
				var paddingLeft:Null<ReferencableValue> = null;
				var paddingRight:Null<ReferencableValue> = null;
				var paddingTop:Null<ReferencableValue> = null;
				var paddingBottom:Null<ReferencableValue> = null;
				var horizontalSpacing:Null<ReferencableValue> = null;
				var verticalSpacing:Null<ReferencableValue> = null;
				var debug:Bool = false;


				var results = parseOptionalParams([ParseIntegerOrReference(MacroUtils.identToString(maxWidth)), 
												   ParseIntegerOrReference(MacroUtils.identToString(maxHeight)),
												   ParseIntegerOrReference(MacroUtils.identToString(minWidth)), 
												   ParseIntegerOrReference(MacroUtils.identToString(minHeight)),
												   ParseIntegerOrReference(MacroUtils.identToString(lineHeight)),
												   ParseIntegerOrReference(MacroUtils.identToString(colWidth)),
												   ParseCustom(MacroUtils.identToString(layout), parseFlowOrientation),
												   ParseIntegerOrReference(MacroUtils.identToString(paddingLeft)),
												   ParseIntegerOrReference(MacroUtils.identToString(paddingRight)),
												   ParseIntegerOrReference(MacroUtils.identToString(paddingTop)),
												   ParseIntegerOrReference(MacroUtils.identToString(paddingBottom)),
												   ParseIntegerOrReference(MacroUtils.identToString(horizontalSpacing)),
												   ParseIntegerOrReference(MacroUtils.identToString(verticalSpacing)),
												   ParseIntegerOrReference("padding"),
												   ParseCustom(MacroUtils.identToString(debug), parseBool),
												], once);

				switch stream {
					case [MPClosed]:
					case _: syntaxError(") expected");
				}
		

				MacroUtils.optionsSetIfNotNull(maxWidth, results);
				MacroUtils.optionsSetIfNotNull(maxHeight, results);
				MacroUtils.optionsSetIfNotNull(minHeight, results);
				MacroUtils.optionsSetIfNotNull(minWidth, results);
				MacroUtils.optionsSetIfNotNull(lineHeight, results);
				MacroUtils.optionsSetIfNotNull(colWidth, results);
				MacroUtils.optionsSetIfNotNull(debug, results);
				
				layout = results[MacroUtils.identToString(layout)];
				if (results.exists("padding")) {
					final val = results["padding"];
					paddingLeft = val;
					paddingRight = val;
					paddingTop = val;
					paddingBottom = val;
				}

				MacroUtils.optionsSetIfNotNull(paddingLeft, results);
				MacroUtils.optionsSetIfNotNull(paddingRight, results);
				MacroUtils.optionsSetIfNotNull(paddingTop, results);
				MacroUtils.optionsSetIfNotNull(paddingBottom, results);
				MacroUtils.optionsSetIfNotNull(horizontalSpacing, results);
				MacroUtils.optionsSetIfNotNull(verticalSpacing, results);
				

				createNodeResponse(FLOW(maxWidth, maxHeight, minWidth, minHeight, lineHeight, colWidth, layout, paddingTop, paddingBottom, paddingLeft, paddingRight, horizontalSpacing, verticalSpacing, debug));
				
			case [MPIdentifier(_, MPPoint, ITString)]:
				switch stream {
					case [MPOpen, MPClosed]:
					case _:
				}	
				createNodeResponse(POINT);
			
			case [MPIdentifier(_, MPText, ITString), MPOpen, fontname = parseStringOrReference(), MPComma, text = parseStringOrReference(), MPComma, color = parseColorOrReference()]:

				
				var maxWidth:Null<Int> = null;
				var isParsingDone = false;
				var results:Map<String, Dynamic> = [];
				var halign = null;
				var hasComma = false;
				switch stream {
					case [MPComma]: 
						halign = parseHAlign();
						if (halign != null) {
							switch stream {
								case [MPComma]:
									maxWidth = tryParseInteger();
									if (maxWidth == null) hasComma = true;
								case [MPClosed]: isParsingDone = true;
							}
	
						} else hasComma = true;
					case [MPClosed]: isParsingDone = true;
				}

				
				if (!isParsingDone) {
					switch stream {
						case [MPComma]: 
						case [MPClosed]: isParsingDone = true;
						case _: if (!hasComma) syntaxError(") or , expected");
					}
				}
				var letterSpacing:Null<Float> = null;
				var lineSpacing:Null<Float> = null;
				var lineBreak:Null<Bool> = null;
				var dropShadowXY:Null<bh.base.Point> = null;
				var dropShadowColor:Null<Int> = null;
				var dropShadowAlpha:Null<Float> = null;
				var html:Null<Bool> = null;
				
				if (!isParsingDone) {
					var once = createOnceParser();
					results = parseOptionalParams([
						ParseFloat(MacroUtils.identToString(letterSpacing)), 
						ParseFloat(MacroUtils.identToString(lineSpacing)),
						ParseBool(MacroUtils.identToString(lineBreak)), 
						ParseCustom(MacroUtils.identToString(dropShadowXY), parseFPoint),
						ParseColor(MacroUtils.identToString(dropShadowColor)),
						ParseFloat(MacroUtils.identToString(dropShadowAlpha)),
						ParseBool(MacroUtils.identToString(html)),
				 ], once);
				

				
					switch stream {
						case [MPClosed]:
						case _: syntaxError("expected )");
				 	}
				}




				 var textDef:TextDef = {
					 fontName: fontname,
					 text: text,
					 color: color,
					 halign: halign,
					 textAlignWidth: maxWidth,
					 letterSpacing: MacroUtils.optionsGetPresentOrDefault(letterSpacing, results, 0.),
					 lineSpacing: MacroUtils.optionsGetPresentOrDefault(lineSpacing, results, 0.),
					 lineBreak: MacroUtils.optionsGetPresentOrDefault(lineBreak, results, true),
					 dropShadowXY: MacroUtils.optionsGetPresentOrDefault(dropShadowXY, results, null),
					 dropShadowColor: MacroUtils.optionsGetPresentOrDefault(dropShadowColor, results, 0),
					 dropShadowAlpha: MacroUtils.optionsGetPresentOrDefault(dropShadowAlpha, results, 0.5),
					 isHtml:MacroUtils.optionsGetPresentOrDefault(html, results, false)
				 };

				createNodeResponse(TEXT(textDef));
				
			case [MPIdentifier(_, MPTileGroup, ITString)]:
				createNodeResponse(TILEGROUP);
				
			case [MPIdentifier(_, MPProgrammable, ITString)]:


				final isTileGroup = switch stream {
				   case [MPIdentifier(_, MPTileGroup, ITString)]: true;
				   case _: false;
			   	}
				switch stream {
					case [MPOpen, parsedDefinedParameters = parseDefines()]:
						if (nameString == null) syntaxError('programmable requires #name');

						currentDefinitions = parsedDefinedParameters;

						if (parent != null) syntaxError('programmable nodes must be root node');

						createNodeResponse(PROGRAMMABLE(isTileGroup, currentDefinitions));

					case _: unexpectedError("expected (");
				}
			case [MPIdentifier(_, MPRelativeLayouts, ITString), MPCurlyOpen]:
				
				if (nameString != null) syntaxError('relativeLayouts cannot have #name');

				if (parent != null) syntaxError('relativeLayouts nodes must be root node');
				if (this.nodes.exists(defaultLayoutNodeName)) syntaxError('only single relativeLayouts node is allowed');
				updatableNameType = switch updatableNameType {
					case UNTObject(name): UNTObject(defaultLayoutNodeName);
					case UNTUpdatable(name): UNTUpdatable(defaultLayoutNodeName);
				}
				
				return createNodeResponse(RELATIVE_LAYOUTS(parseLayouts())); // return here skips extended syntax parsing
			case [MPIdentifier(_, MPParticles, ITString), MPCurlyOpen]:
				
				
				if (parent == null) {

					if (nameString == null) syntaxError('particles requires #name');
					final p = parseParticles();
					validateParticles(p, stream.curPos());
					return createNodeResponse(PARTICLES(p)); // return here skips extended syntax parsing
				} 
				final p = parseParticles();
				validateParticles(p, stream.curPos());
				return createNodeResponse(PARTICLES(p)); 
			case [MPIdentifier(_, MPAnimatedPath, ITString), MPCurlyOpen]: // TODO: parse default speed/totalTime
				
				if (nameString == null) syntaxError('animatedPath requires #name');
				if (parent != null) syntaxError('animatedPath nodes must be root node');

				return createNodeResponse(ANIMATED_PATH(parseAnimatedPath())); // return here skips extended syntax parsing
				
				
			case [MPIdentifier(_, MPPaths, ITString), MPCurlyOpen]:
				
				if (this.nodes.exists(defaultPathNodeName)) syntaxError('only single paths node is allowed');
				updatableNameType = switch updatableNameType {
					case UNTObject(name): UNTObject(defaultPathNodeName);
					case UNTUpdatable(name): UNTUpdatable(defaultPathNodeName);
				}
				if (parent != null) syntaxError('paths nodes must be root node');
				
				
				final pathsDef = parsePaths();
				return createNodeResponse(PATHS(pathsDef)); // return here skips extended syntax parsing
			case [MPIdentifier(_, MPPalette, ITString)]:

				if (nameString == null) syntaxError('palette requires #name');
				if (parent != null) syntaxError('palette nodes must be root node');
				

				
				final paletteType = switch stream {
					case [MPOpen]:
						switch stream {
							case [MPIdentifier("2d", _, ITString), MPColon, width = parseInteger(), MPClosed, MPCurlyOpen]:
								PaletteColors2D(parseColorsList(MPCurlyClosed), width);
							case [MPIdentifier("file", _, ITString), MPColon, filename = parseStringOrReference(), MPClosed]:

								return createNodeResponse(PALETTE(PaletteImageFile(filename))); // return here skips extended syntax parsing				
							case _: unexpectedError("expected 2d:<width> or file:<filename>");
						}
					case [MPCurlyOpen]:
						PaletteColors(parseColorsList(MPCurlyClosed));
				}
				
				return createNodeResponse(PALETTE(paletteType)); // return here skips extended syntax parsing
			case [MPIdentifier(_, MPLayers, ITString)]:
				switch stream {
					case [MPOpen, MPClosed]: true;
					case _:
				}
				createNodeResponse(LAYERS);

			case [MPIdentifier(_, MPSettings, ITString), MPOpen]:
				if (parent == null) syntaxError('settings must have a parent');
				if (parent.settings == null) parent.settings = [];
				
				while (true) {
					switch stream {
						case [MPIdentifier(key, _, _), MPArrow ]: 
							final value = parseStringOrReference();
							if (parent.settings.exists(key)) syntaxError('setting ${key} already defined');
							parent.settings[key] = value;
						case _: unexpectedError("Expected name->value");
					}
					switch stream {
						case [MPComma]:
						case [MPClosed]: break;
						case _: unexpectedError("Expected , or )");
					}
				}
				return null;
				
			case [MPIdentifier(_, MPPixels, ITString), MPOpen, pixelShapes = parseShapes()]:
				createNodeResponse(PIXELS(pixelShapes));
			
			case [MPIdentifier(_, MPReference, ITString), MPOpen]:
				 var externalReference = null;
				 var importedBuilder = null;
				 switch stream {
					case  [MPIdentifier(_, MPExternal , ITString), MPOpen, MPIdentifier(er, _ , ITString | ITQuotedString), MPClosed, MPComma]: 
						importedBuilder = imports.get(er);
						if (importedBuilder == null) syntaxError('external reference "$er" could not be found. It has to be imported BEFORE referencing it.');
						externalReference = er;
					case _: 
				}

				var programmableReference = switch stream {
					case  [MPIdentifier(p, _ , ITReference)]: p;
					case _: unexpectedError("expected programmable reference");
				}

				final programmable = if (importedBuilder != null) importedBuilder.multiParserResult?.nodes?.get(programmableReference);
				else nodes.get(programmableReference);

				if (programmable == null) syntaxError('programmable "$programmableReference" could not be found in ${externalReference}. It has to be defined BEFORE referencing it.');
					switch programmable.type {
						case PROGRAMMABLE(isTileGroup, parameters):
							final params:Map<String, ReferencableValue> = switch stream {
								case [MPComma]:
									parseReferenceParameters(parameters);
								case [MPClosed]: [];
							}
							createNodeResponse(REFERENCE(externalReference, programmableReference, params));
						default: 
							createNodeResponse(REFERENCE(externalReference, programmableReference, []));
					}
			
			case [MPIdentifier(_, MPPlaceholder, ITString), MPOpen]:
				final type = switch stream {
					case[MPIdentifier(_, MPError, ITString |ITQuotedString)]: PHError;						
					case[MPIdentifier(_, MPNothing, ITString |ITQuotedString)]:	PHNothing;
					case _:  PHTileSource(parseTileSource());
				}
				switch stream {
					case [MPComma]:
				}
				var source:Null<PlaceholderReplacementSource> = null;
				switch stream {
					case [MPIdentifier(_, MPCallback, ITString), MPOpen, name = parseStringOrReference()]:
						switch stream {
							case [MPComma, index = parseIntegerOrReference(), MPClosed]:
								source = PRSCallbackWithIndex(name, index);
							case [MPClosed]: 
								source = PRSCallback(name);
							case _: unexpectedError("expected color or )");
						}
					case [MPIdentifier(_, MPBuilderParameter, ITString), MPOpen, name = parseStringOrReference(), MPClosed]:
						source = PRSBuilderParameterSource(name);
					case _: unexpectedError("expected placeholder replacement source: callback(name), callback(name, index) or builderParameters(name)");
				}
				switch stream {
					case [MPClosed]:
				}
				createNodeResponse(PLACEHOLDER(type, source));
			
			case [MPIdentifier(_, MPInteractive, ITString), MPOpen, width = parseIntegerOrReference(), MPComma, height = parseIntegerOrReference(), MPComma, id = parseStringOrReference()]:
				final debug = switch stream {
					case [MPClosed]: false;
					case [MPComma, MPIdentifier(_, MPDebug, ITString), MPClosed]: true;
					case [MPIdentifier(_, MPDebug, ITString), MPClosed]: true;
					case _: unexpectedError('expected ) or  "debug"');
				}
				createNodeResponse(INTERACTIVE(width, height, id, debug));
				

			case [MPIdentifier(_, MPRepeatable, ITString), MPOpen,  MPIdentifier(varName, _, ITReference | ITString), MPComma]:
				
				if (currentDefinitions.exists(nameString)) syntaxError('repeatable name "${varName}" is already a parameter.');
				var response = switch stream {
					case [MPIdentifier(_, MPGrid, ITString), MPOpen, repeatCount = parseIntegerOrReference(), MPComma ]:
						var once = createOnceParser();
						var dx:Null<ReferencableValue> = null;
						var dy:Null<ReferencableValue> = null;

						var results = parseOptionalParams([
							ParseIntegerOrReference(MacroUtils.identToString(dx)), 
							ParseIntegerOrReference(MacroUtils.identToString(dy))
						], once);
						switch stream {
						   case [MPClosed]:
						   case _: syntaxError("expected )");
						}
						MacroUtils.optionsSetIfNotNull(dx, results);
						MacroUtils.optionsSetIfNotNull(dy, results);
						if (dx == null && dy == null) syntaxError('grid repeatable needs at least dx or dy or both');
						createNodeResponse(REPEAT(varName, GridIterator(dx, dy, repeatCount)));
					case [MPIdentifier(_, MPLayout, ITString), MPOpen, MPIdentifier(layout, _, ITQuotedString|ITString), MPComma, MPIdentifier(layoutName, _, ITQuotedString|ITString), MPClosed]:
						postParsedActions.push(PPAVerifyRelativeLayout(layoutName, stream.curPos()));
						createNodeResponse(REPEAT(varName, LayoutIterator(layoutName)));
					case [MPIdentifier(_, MPArray, ITString), MPOpen, MPIdentifier(valueVariableName, _, ITString | ITReference), MPComma,  MPIdentifier(arrayName, _, ITReference | ITString), MPClosed]:
						if (currentDefinitions.exists(valueVariableName)) syntaxError('repeatable array iterator value variable name "${valueVariableName}" is already a parameter.');
						createNodeResponse(REPEAT(varName, ArrayIterator( valueVariableName, arrayName)));
					case _: syntaxError("unknown repeatable iterator, expected grid(dx, dy, repeatCount) | layout(layoutName, layout)| array(arrayName)");
				}
				switch stream {
					case [MPClosed]:
					case _: syntaxError("expected )");
				}

				
				response;

			case _: unexpectedError("expected valid node type");
		}
		 
		switch stream {
			case [MPColon, p = parseXY()]:
				eatSemicolon();
				var isFlow = parent != null && switch parent.type {
					case FLOW(_,_,_,_,_,_,_,_,_,_,_,_): true;
					default: false;
				}

				if (isFlow) {
					switch p {
						case ZERO:
						default: syntaxError('xy not allowed to be set for direct descendants of the flow: was ${p} required ";"');
					}
					
				}

				node.pos = p;

			case [MPSemiColon]: node.pos = ZERO;
			case [MPCurlyOpen]:
				parseNodes(node,  currentDefinitions, onceInline, uniqueId + 77, allowChildren);
			case [MPEof]: syntaxError('unexpected end of file');
			case _: unexpectedError("Expected : or { or EOF");
		}

		return node;
	}

	function addNode(name:String, node:Node) {
		if (name == null) {
			syntaxError('root node needs a name');
		}
		if (nodes.exists(name)) syntaxError('duplicate node #${name}');
		nodes.set(name, node);
	}

	function eatSemicolon() {
		switch stream {
			case [MPSemiColon]:
			case _:
		}
	}	
	function eatComma() {
		switch stream {
			case [MPComma]:
			case _:
		}
	}

	
	function createOnceParser() {
		return new OncePropertyParser(name-> syntaxError('$name already defined'));
	}

	public static function getGridCoordinateSystem(node:Node):Null<GridCoordinateSystem> {
		while (node != null) {
			if (node.gridCoordinateSystem != null) return node.gridCoordinateSystem;
			node = node.parent;
		}
		return null;
	}

	public static function getHexCoordinateSystem(node:Node):Null<HexCoordinateSystem> {
		while (node != null) {
			if (node.hexCoordinateSystem != null) return node.hexCoordinateSystem;
			node = node.parent;
		}
		return null;
	}
	
	function parseGridCoordianteSystem() {
		var size = parseSize();
		eatSemicolon();
		return {
			spacingX: size.width,
			spacingY: size.height
		}
	}

	function parseHexCoordianteSystem() {
		return switch stream {
			case [orientation = parseOrientation(), MPOpen, width = parseFloat(), MPComma, height = parseFloat(), MPClosed]:
				final hexLayout = new HexLayout(orientation, new h2d.col.Point(width, height), new h2d.col.Point());
				eatSemicolon();
				{hexLayout:hexLayout}
			
			case _:  unexpectedError("expected grid coordinate system");
		}
	}

	function parseLayoutContent():Null<LayoutContent>{
		switch stream {
			case [MPIdentifier(_, MPPoint, ITString), MPColon, xy = parseXY()]: 
				return LayoutPoint(xy);
			case _: return null;

		}
	}

	function parseFilter():FilterType {
		return switch stream {
			case [MPIdentifier("none", _ , ITString)]: FilterNone;
			case [MPIdentifier("group", _ , ITString), MPOpen]: 

				var filters = [];
				while (true) {
					switch stream {
						case [MPClosed]: break;
						case _: filters.push(parseFilter());
					}
					eatComma();
				}
				FilterGroup(filters);
			case [MPIdentifier("outline", _ , ITString), MPOpen, size = parseFloat(), MPComma, color = parseColor(), MPClosed]: 
				FilterOutline(size, color);
			case [MPIdentifier("saturate", _ , ITString), MPOpen, value = parseFloat(), MPClosed]: 
				FilterSaturate(value);
			case [MPIdentifier("replacePalette", _ , ITString), MPOpen, MPIdentifier(paletteName, _ , ITString|ITQuotedString),  MPComma, sourceRow = parseIntegerOrReference(), MPComma, replacementRow = parseIntegerOrReference(), MPClosed]: 
				FilterPaletteReplace(paletteName, sourceRow, replacementRow);
			case [MPIdentifier("replaceColor", _ , ITString), MPOpen, MPBracketOpen]: 
				var sources = parseColorsList(MPBracketClosed);
				eatComma();
				switch stream {
					case [MPBracketOpen, replacements = parseColorsList(MPBracketClosed), MPClosed]: 
						FilterColorListReplace(sources, replacements);
					case _: unexpectedError("expected [color1, color2, ...], [replacement1, replacement2, ...])");
				}
			case [MPIdentifier("brightness", _ , ITString), MPOpen, value = parseFloat(), MPClosed]: 
				FilterBrightness(value);
			case [MPIdentifier("blur", _ , ITString), MPOpen, radius = parseFloat(), MPComma, gain = parseFloat(), MPClosed]: 
				var quality = 1.;
				var linear = 0.0;
				FilterBlur(radius, gain, quality, linear);
			case [MPIdentifier("pixelOutline", _ , ITString), MPOpen]: 
				var mode = switch stream {
					case [MPIdentifier("knockout", _ , ITString|ITQuotedString), MPComma, color = parseColor(), MPComma, knockout=parseFloat()]: 
						Knockout(color, knockout);
					case [MPIdentifier("inlineColor", _ , ITString|ITQuotedString), MPComma, color = parseColor(), MPComma, inlineColor = parseColor()]: 
						InlineColor(color, inlineColor);
				}
				final smoothColor = switch stream {
					case [MPIdentifier("smoothColor", _, ITString)]: true;
					case [MPClosed]: false;
					case _: unexpectedError("expected smoothColor or )");

				}
				FilterPixelOutline(mode, smoothColor );
			case [MPIdentifier("glow", _ , ITString), MPOpen]: 
				var once = createOnceParser();
				
				var radius:Null<Float> = null;
				var gain:Null<Float> = null;
				var quality:Null<Float> = null;
				var smoothColor:Null<Bool> = null;
				var knockout:Null<Bool> = null;
				var color:Null<Int> = null;
				var alpha:Null<Float> = null;

				var results = parseOptionalParams([
					ParseFloat(MacroUtils.identToString(alpha)), 
					ParseFloat(MacroUtils.identToString(radius)), 
					ParseFloat(MacroUtils.identToString(gain)),
					ParseFloat(MacroUtils.identToString(quality)),

					ParseBool(MacroUtils.identToString(smoothColor)),
					ParseBool(MacroUtils.identToString(knockout)),
					ParseColor(MacroUtils.identToString(color)),
					
					], once);

					switch stream {
						case [MPClosed]:
						case _: unexpectedError("glow expected )");
					}
				return FilterGlow(
					MacroUtils.optionsGetPresentOrDefault(color, results, 0xFFFFFFFF), 
					MacroUtils.optionsGetPresentOrDefault(alpha, results, 1.),
					MacroUtils.optionsGetPresentOrDefault(radius, results, 1.),
					MacroUtils.optionsGetPresentOrDefault(gain, results, 1.),
					MacroUtils.optionsGetPresentOrDefault(quality, results, 1.),
					MacroUtils.optionsGetPresentOrDefault(smoothColor, results, false),
					MacroUtils.optionsGetPresentOrDefault(knockout, results, false)
					);
				
				
			case [MPIdentifier("dropShadow", _ , ITString), MPOpen]: 
				var once = createOnceParser();
				var distance:Null<Float> = null;
				var angle:Null<Float> = null;
				var alpha:Null<Float> = null;
				var radius:Null<Float> = null;
				var quality:Null<Float> = null;
				var color:Null<Int> = null;
				var gain:Null<Float> = null;
				var smoothColor:Null<Bool> = null;
			

				var results = parseOptionalParams([ParseFloat(MacroUtils.identToString(distance)), 
												ParseFloat(MacroUtils.identToString(angle)),
												ParseFloat(MacroUtils.identToString(alpha)), 
												ParseFloat(MacroUtils.identToString(radius)),
												ParseColor(MacroUtils.identToString(color)),
												ParseFloat(MacroUtils.identToString(gain)),
												ParseFloat(MacroUtils.identToString(quality)),
												ParseBool(MacroUtils.identToString(smoothColor)),
												
												], once);
			

				switch stream {
					case [MPClosed]:
					case _: unexpectedError("dropShadow expected )");
				}
				
				return FilterDropShadow(
					MacroUtils.optionsGetPresentOrDefault(distance, results, 4.0), 
					hxd.Math.degToRad(MacroUtils.optionsGetPresentOrDefault(angle, results, 90.0)),
					MacroUtils.optionsGetPresentOrDefault(color, results, 0), 
					MacroUtils.optionsGetPresentOrDefault(alpha, results, 1.),
					MacroUtils.optionsGetPresentOrDefault(radius, results, 1.), 
					MacroUtils.optionsGetPresentOrDefault(gain, results, 1.), 
					MacroUtils.optionsGetPresentOrDefault(quality, results, 1.), 
					MacroUtils.optionsGetPresentOrDefault(smoothColor, results, false));
				
		}
	}


	function parsePaths():PathsDef {

		var paths:PathsDef = [];
		while(true) {
			var name = null;
			switch stream {
				case [MPIdentifier(n, _, ITName)]: 
					if (paths.exists(n)) syntaxError("duplicate path name $n");
					switch stream {
						case [MPIdentifier(_, MPPath, ITString), MPCurlyOpen]:
						case _: syntaxError("expected path {");
					}
					name = n;

				case [MPCurlyClosed]: return paths;
				case _: syntaxError("expected name");
			}

			var pathsArr:Array<ParsedPaths> = [];
			while (true) {
				switch stream {
					case [MPIdentifier(_, MPForward, ITString), MPOpen, distance = parseIntegerOrReference(), MPClosed]:
						pathsArr.push(Forward(distance));
					case [MPIdentifier(_, MPTurn, ITString), MPOpen, angle = parseIntegerOrReference(), MPClosed]:
						pathsArr.push(TurnDegrees(angle));

					case [MPIdentifier(_, MPLine, ITString), MPOpen, end = parseXY(), MPClosed]:
						pathsArr.push(LineTo(end));
					case [MPIdentifier(_, MPCheckpoint, ITString), MPOpen, MPIdentifier(name, _, ITString|ITQuotedString) , MPClosed]:
						pathsArr.push(Checkpoint(name));
						
					case [MPIdentifier(_, MPBezier, ITString), MPOpen, end = parseXY(), MPComma, control1 = parseXY()]:
						switch stream {
							case [MPComma, control2 = parseXY(), MPClosed]:
								pathsArr.push(Bezier3To(end, control1, control2));
							case [MPClosed]:
								pathsArr.push(Bezier2To(end, control1));
							case _: syntaxError("expected XY or )");
						}
					case [MPCurlyClosed]: break;
					case _: syntaxError("expected line or bezier or }");
				}
			}
			paths.set(name, pathsArr);
			
		}
	}

	function parseAnimatedPathAction() {
		return switch stream {
			case [MPIdentifier("changeSpeed", _, ITString),  speed = parseFloatOrReference()]:
				 ChangeSpeed(speed);
			case [MPIdentifier("event", _,  ITString), MPOpen, MPIdentifier(eventName, _, ITString|ITQuotedString), MPClosed]:
				 Event(eventName);
			case [MPIdentifier("attachParticles", _,  ITString), MPOpen, MPIdentifier(particlesName, _, ITString|ITQuotedString)]:
				final particlesTemplate = switch stream {
					case [MPComma,MPIdentifier(particlesTemplate, _, ITString|ITQuotedString), MPClosed]: particlesTemplate;
					case [MPClosed]: null;
					case _: syntaxError("expected <particles template name> or )");
				}
				switch stream {
					case [MPCurlyOpen, particlesDef = parseParticles()]:
						
						if (particlesTemplate == null) validateParticles(particlesDef, stream.curPos());
						else postParsedActions.push(PPAUpdateAndVerifyParticlesTemplate(particlesTemplate, particlesDef, stream.curPos()));
						AttachParticles(particlesName, particlesTemplate, particlesDef);
					case _: syntaxError("expected {");
				}
				 
			case [MPIdentifier("removeParticles", _, ITString), MPOpen, MPIdentifier(particlesName, _, ITString|ITQuotedString), MPClosed]:
				 RemoveParticles(particlesName);
			case [MPIdentifier("changeAnimState", _, ITString), MPOpen, MPIdentifier(state, _, ITString|ITQuotedString), MPClosed]:
				 ChangeAnimSMState(state);

			case _: syntaxError("expected changeSpeed or event or attachParticles or removeParticles or changeAnimState");
		}
	}

	function parseAnimatedPath() {
		var retVal:AnimatedPathDef = [];
		while (true) {
			switch stream {
				case [MPCurlyClosed]: 
					return retVal;
				case [MPIdentifier(checkPointName, _, ITString|ITQuotedString), MPColon, action = parseAnimatedPathAction()]:
					retVal.push({at:Checkpoint(checkPointName), action:action});
				case [rate = parseFloatOrReference(), MPColon, action = parseAnimatedPathAction()]:
					switch rate {
						case RVInteger(i): if (i < 0 || i > 1) syntaxError("at rate must be between 0.0 and 1.0");
						case RVFloat(f): if (f < 0. || f > 1.) syntaxError("at rate must be between 0.0 and 1.0");
						default:
					}
					retVal.push({at:Rate(rate), action:action});
				case _: syntaxError("<at>: <command> or }");
			}
		}
	}

	function parseParticlesEmitMode():ParticlesEmitMode {
		return switch stream {
			case [MPIdentifier("point", _, ITString), MPOpen, emitDistance = parseFloatOrReference(), MPComma, emitDistanceRandom = parseFloatOrReference(), MPClosed]:
				Point(emitDistance, emitDistanceRandom);
			case [MPIdentifier("cone", _, ITString), MPOpen, emitDistance = parseFloatOrReference(), MPComma, emitDistanceRandom = parseFloatOrReference(), MPComma, emitConeAngle = parseFloatOrReference(), MPComma, emitConeAngleRandom = parseFloatOrReference(), MPClosed]:
				Cone(emitDistance, emitDistanceRandom, emitConeAngle, emitConeAngleRandom);
			case [MPIdentifier("box", _, ITString), MPOpen, width = parseFloatOrReference(), MPComma, height = parseFloatOrReference(),MPComma, emitConeAngle = parseFloatOrReference(), MPComma, emitConeAngleRandom = parseFloatOrReference(), MPClosed]:
				 Box(width, height, emitConeAngle, emitConeAngleRandom);
			case _: syntaxError("expected point, cone or box");
		}
	}

	function validateParticles(particlesDefs:ParticlesDef, pos) {
		if (particlesDefs.emit == null) syntaxError('emit is required', pos);
		if (particlesDefs.tiles == null) syntaxError('tiles is required', pos);
	}

	function createEmptyParticlesDef() {
		return {
			count:null,
			emitDelay:null,
			emitSync:null,
			maxLife:null,
			lifeRandom:null,
			size:null,
			sizeRandom:null,
			speed:null,
			speedRandom:null,
			speedIncrease:null,
			loop:null,
			relative:null,
			tiles:null,
			gravity:null,
			gravityAngle:null,
			fadeIn:null,
			fadeOut:null,
			fadePower:null,
			blendMode:null,
			emit:null,
			rotationInitial:null,
			rotationSpeed:null,
			rotationSpeedRandom:null,
			rotateAuto:null,
		};
	}

	function updateParticlesFromTemplate(template:ParticlesDef, particlesDef:ParticlesDef):Void {
		
		particlesDef.count =  particlesDef.count ?? template.count;
		particlesDef.emitDelay =  particlesDef.emitDelay ?? template.emitDelay;
		particlesDef.emitSync =  particlesDef.emitSync ?? template.emitSync;
		particlesDef.maxLife =  particlesDef.maxLife ?? template.maxLife;
		particlesDef.lifeRandom =  particlesDef.lifeRandom ?? template.lifeRandom;
		particlesDef.size =  particlesDef.size ?? template.size;
		particlesDef.sizeRandom =  particlesDef.sizeRandom ?? template.sizeRandom;
		particlesDef.speed =  particlesDef.speed ?? template.speed;
		particlesDef.speedRandom =  particlesDef.speedRandom ?? template.speedRandom;
		particlesDef.speedIncrease =  particlesDef.speedIncrease ?? template.speedIncrease;
		particlesDef.loop =  particlesDef.loop ?? template.loop;
		particlesDef.relative =  particlesDef.relative ?? template.relative;
		particlesDef.tiles =  particlesDef.tiles ?? template.tiles;
		particlesDef.gravity =  particlesDef.gravity ?? template.gravity;
		particlesDef.gravityAngle =  particlesDef.gravityAngle ?? template.gravityAngle;
		particlesDef.fadeIn =  particlesDef.fadeIn ?? template.fadeIn;
		particlesDef.fadeOut =  particlesDef.fadeOut ?? template.fadeOut;
		particlesDef.fadePower =  particlesDef.fadePower ?? template.fadePower;
		particlesDef.blendMode =  particlesDef.blendMode ?? template.blendMode;
		particlesDef.emit =  particlesDef.emit ?? template.emit;
		particlesDef.rotationInitial =  particlesDef.rotationInitial ?? template.rotationInitial;
		particlesDef.rotationSpeed =  particlesDef.rotationSpeed ?? template.rotationSpeed;
		particlesDef.rotationSpeedRandom =  particlesDef.rotationSpeedRandom ?? template.rotationSpeedRandom;
		particlesDef.rotateAuto =  particlesDef.rotateAuto ?? template.rotateAuto;
	
	}
 	
	function parseParticles():ParticlesDef {

		var retVal = createEmptyParticlesDef();
		final once = createOnceParser();
		var results = parseOptionalParams([ParseIntegerOrReference(MacroUtils.identToString(count)), 
											ParseFloatOrReference(MacroUtils.identToString(emitDelay)), 
											ParseFloatOrReference(MacroUtils.identToString(emitSync)), 
											ParseFloatOrReference(MacroUtils.identToString(maxLife)), 
											ParseFloatOrReference(MacroUtils.identToString(lifeRandom)), 
											ParseFloatOrReference(MacroUtils.identToString(size)), 
											ParseFloatOrReference(MacroUtils.identToString(sizeRandom)), 
											ParseFloatOrReference(MacroUtils.identToString(speed)), 
											ParseFloatOrReference(MacroUtils.identToString(speedRandom)), 
											ParseFloatOrReference(MacroUtils.identToString(speedIncrease)), 
											ParseFloatOrReference(MacroUtils.identToString(gravity)), 
											ParseFloatOrReference(MacroUtils.identToString(gravityAngle)), 
											ParseFloatOrReference(MacroUtils.identToString(fadeIn)), 
											ParseFloatOrReference(MacroUtils.identToString(fadeOut)), 
											
											ParseFloatOrReference(MacroUtils.identToString(rotationSpeed)), 
											ParseFloatOrReference(MacroUtils.identToString(rotationSpeedRandom)), 
											ParseFloatOrReference(MacroUtils.identToString(rotationInitial)), 
											ParseBool(MacroUtils.identToString(rotateAuto)), 
											
											ParseBool(MacroUtils.identToString(loop)), 
											ParseBool(MacroUtils.identToString(relative)), 
											ParseCustom(MacroUtils.identToString(tiles), parseTileSources),
											ParseCustom(MacroUtils.identToString(blendMode), tryParseBlendMode),
											ParseCustom(MacroUtils.identToString(emit), parseParticlesEmitMode)
										], once);

		switch stream {
			case [MPCurlyClosed]:
			case _: syntaxError("} expected");
		}

		MacroUtils.optionsSetIfNotNull(retVal.emit, results);
		MacroUtils.optionsSetIfNotNull(retVal.tiles, results);
		MacroUtils.optionsSetIfNotNull(retVal.count, results);
		MacroUtils.optionsSetIfNotNull(retVal.emitDelay, results);
		MacroUtils.optionsSetIfNotNull(retVal.emitSync, results);
		MacroUtils.optionsSetIfNotNull(retVal.maxLife, results);
		MacroUtils.optionsSetIfNotNull(retVal.lifeRandom, results);
		MacroUtils.optionsSetIfNotNull(retVal.size, results);
		MacroUtils.optionsSetIfNotNull(retVal.sizeRandom, results);
		MacroUtils.optionsSetIfNotNull(retVal.speed, results);
		MacroUtils.optionsSetIfNotNull(retVal.speedRandom, results);
		MacroUtils.optionsSetIfNotNull(retVal.speedIncrease, results);
		MacroUtils.optionsSetIfNotNull(retVal.gravity, results);
		MacroUtils.optionsSetIfNotNull(retVal.gravityAngle, results);
		MacroUtils.optionsSetIfNotNull(retVal.fadeIn, results);
		MacroUtils.optionsSetIfNotNull(retVal.fadeOut, results);
		MacroUtils.optionsSetIfNotNull(retVal.fadePower, results);
		MacroUtils.optionsSetIfNotNull(retVal.rotationInitial, results);
		MacroUtils.optionsSetIfNotNull(retVal.rotationSpeed, results);
		MacroUtils.optionsSetIfNotNull(retVal.rotationSpeedRandom, results);
		MacroUtils.optionsSetIfNotNull(retVal.rotateAuto, results);
		MacroUtils.optionsSetIfNotNull(retVal.loop, results);
		MacroUtils.optionsSetIfNotNull(retVal.relative, results);
		MacroUtils.optionsSetIfNotNull(retVal.blendMode, results);
				
		return retVal;
		
	}

	function parseLayouts():LayoutsDef {

		var layouts:LayoutsDef = [];
		

		
		var grids:Array<GridCoordinateSystem> = [];
		var hexes:Array<HexCoordinateSystem> = [];
		var offsets = [new Point(0,0)];
		var parsingStates:Array<LayoutsParsingState> = [LPSEnd];
		
		while (true) {
			var name = null;

			function addLayout(layoutType:LayoutsType) {
				if (layoutType == null) throw 'missing layout content in layout $name';
				final layout:Layout = {
					name: name,
					type: layoutType,
					grid: grids.length == 0 ? null : grids[grids.length - 1],
					hex: hexes.length == 0 ? null : hexes[hexes.length - 1],
					offset: Lambda.fold(offsets, (a,b)-> new Point(a.x + b.x, a.y + b.y), new Point(0,0))
				}
	
				if (layouts.exists(name)) throw 'layout $name already defined';
				layouts.set(name, layout);
			}

			switch stream {
				case [MPIdentifier(n, _, ITName)]: name = n;
					final content = parseLayoutContent();	// Single mode
					if (content != null) {
						addLayout(Single(content));
						continue;
					} 
					switch stream {
						case [MPIdentifier(_, MPSequence, ITString), MPOpen, MPIdentifier(varName, _, ITReference), MPColon, from = parseInteger(), MPDoubleDot, to = parseInteger(), MPClosed]:
							final lc = parseLayoutContent();
							if (lc == null) throw 'layout content expected';
							addLayout(Sequence(varName, from, to, lc));
							continue;
							
						case [MPIdentifier(_, MPList, ITString), MPCurlyOpen]:
							var contentList = [];
							while (true) {
								final lc = parseLayoutContent();
								
								if (lc != null) {
									eatSemicolon();
									contentList.push(lc);
								}
								else {
									eatSemicolon();
									addLayout(List(contentList));
									break;
								}
							}
							switch stream {
								case [MPCurlyClosed]: 
								case _: unexpectedError("expected } or more layout content");
							}
					}

				case [MPCurlyClosed]: 
					final state = parsingStates.pop();
					switch (state)
					{
						case LPSEnd: return layouts;
						case LPSGrid: grids.pop(); 
						case LPSHex: hexes.pop(); 
						case LPSOffset: offsets.pop(); 
						case _: syntaxError("Unexpected }");
					}
					
				case [MPNewLine]:
				case [MPIdentifier(propName, MPGrid, ITString), MPColon, system = parseGridCoordianteSystem(), MPCurlyOpen]: 
					parsingStates.push(LPSGrid);
					grids.push(system);
				case [MPIdentifier(propName, MPHexGrid, ITString), MPColon, system = parseHexCoordianteSystem(), MPCurlyOpen]: 
					parsingStates.push(LPSHex);
					hexes.push(system);
				case [MPIdentifier(propName, MPOffset, ITString), MPColon, size = parseSize(), MPCurlyOpen]: 
					parsingStates.push(LPSOffset);
					offsets.push({x:size.width, y:size.height});
				case _: unexpectedError("Unexpected layout property");
			
			}
		}
	}

	function parseNodes(node:Node, definitions:ParametersDefinitions,  once:OncePropertyParser, uniqueId:Int, allowParseChildren:Bool = true) {

		while(true) {
			switch stream {
				case [MPIdentifier(_, MPImport , ITString),  MPIdentifier(file, _, ITString|ITQuotedString),  MPIdentifier("as", _, ITString), MPIdentifier(importName, _, ITString|ITQuotedString)]:
					eatSemicolon();
					final loadedFile = resourceLoader.loadMultiAnim(file); // TODO: check for cycles
					if (loadedFile == null) syntaxError('could not load multiAnim file ${file}');

					imports.set(importName, loadedFile);
				case [MPIdentifier(propName, MPPosition , ITString)|MPIdentifier(propName, MPPos, ITString )]:
					if (node == null) syntaxError('position not supported on root elements');
					once.parsed(propName);
					switch stream {
						case [MPColon, pos = parseXY()]:
							node.pos = pos;

						case _: unexpectedError("expected valid position:x,y, grid, hex, hexEdge, hexCorner");

					}
				case [MPIdentifier(propName, MPGrid , ITString), MPColon]:
						if (node == null) syntaxError('grid coordinate system not supported on root elements');
						once.parsed(propName);
						node.gridCoordinateSystem = parseGridCoordianteSystem();
				case [MPIdentifier(propName, MPHex , ITString), MPColon]:
						if (node == null) syntaxError('hex coordinate system not supported on root elements');
						once.parsed(propName);
						node.hexCoordinateSystem = parseHexCoordianteSystem();
						
		
				case [MPIdentifier(propName, MPScale , ITString), MPColon, f = parseFloatOrReference()]:
					if (node == null) syntaxError('scale not supported on root elements');
					once.parsed(propName);
					node.scale = f;
				case [MPIdentifier(propName, MPFilter , ITString), MPColon, filter = parseFilter()]:
					if (node == null) syntaxError('filter not supported on root elements');
					once.parsed(propName);
					node.filter = filter;
				case [MPIdentifier(propName, MPAlpha , ITString), MPColon, f = parseFloatOrReference()]:
					if (node == null) syntaxError('alpha not supported on root elements');
					once.parsed(propName);
					node.alpha = f;
				case [MPIdentifier(propName, MPLayer , ITString), MPColon, layerIndex = parseInteger()]:
					if (node == null) syntaxError('layer not supported on root elements');
					else {
						switch node.parent.type {
							case PROGRAMMABLE(isTileGroup, parameters):
							case LAYERS:
							default: syntaxError('layer requires parent node to be either programmable or layers but was ${node.type}');
						}
					}
					once.parsed(propName);
					node.layer = layerIndex;
				case [MPIdentifier(propName, MPBlendMode , ITString), MPColon]:
					if (node == null) syntaxError('blendMode not supported on root elements');
					once.parsed(propName);					
					var blendMode = tryParseBlendMode();
					if (blendMode == null) unexpectedError('unsupported blend mode');
					else node.blendMode = blendMode;
					
					
				case [MPIdentifier(name, _, ITName), ]:
					//trace('name ${name}');
					
					if (allowParseChildren == false) syntaxError('children not allowed');
					final updatableName = switch stream {
						case [MPOpen, un = parseUpdatable(name), MPClosed ]:
							un;
						case _:  UNTObject(name);
					}
					final newNode = parseNode(updatableName, node, definitions, uniqueId + 1);
					if (newNode == null) continue;
					if (node == null) addNode(name, newNode);
					else node.children.push(newNode);
				case [MPNewLine]: 
				case [MPSemiColon]: 
				case [MPCurlyClosed]:  {
					return;
				}
				
				case [MPEof]:  
					if (node != null) syntaxError('unexpected end of file');
					else return;
				default: 
					if (allowParseChildren == false) syntaxError('children not allowed');
					var newNode = parseNode(UNTObject(null), node, definitions, uniqueId+1);
					if (newNode == null) continue;

					if (node == null) addNode(newNode?.updatableName?.getNameString(), newNode);
					else node.children.push(newNode);
			}

		}

	}

	function tryParseBlendMode():Null<h2d.BlendMode> {
		return switch stream {
			case [MPIdentifier("none", _ , ITString)]:
				h2d.BlendMode.None;
			case [MPIdentifier("alpha", _ , ITString)]:
				h2d.BlendMode.Alpha;
			case [MPIdentifier("add", _ , ITString)]:
				h2d.BlendMode.Add;
			case [MPIdentifier("alphaAdd", _ , ITString)]:
				h2d.BlendMode.AlphaAdd;
			case [MPIdentifier("softAdd", _ , ITString)]:
				h2d.BlendMode.SoftAdd;
			case [MPIdentifier("multiply", _ , ITString)]:
				h2d.BlendMode.Multiply;
			case [MPIdentifier("alphaMultiply", _ , ITString)]:
				h2d.BlendMode.AlphaMultiply;
			case [MPIdentifier("erase", _ , ITString)]:
				h2d.BlendMode.Erase;
			case [MPIdentifier("screen", _ , ITString)]:
				h2d.BlendMode.Screen;
			case [MPIdentifier("sub", _ , ITString)]:
				h2d.BlendMode.Sub;
			case [MPIdentifier("max", _ , ITString)]:
				h2d.BlendMode.Max;
			case [MPIdentifier("min", _ , ITString)]:
				h2d.BlendMode.Min;
			case _: null;
		}
	}
	

	function parseOptionalParams(parameters:Array<OptionalParametersParsing>, once:OncePropertyParser) {
		
		function getName(parsingParam):String {
			return switch parsingParam {
				case ParseInteger(name): name;
				case ParseIntegerOrReference(name): name;
				case ParseFloat(name): name;
				case ParseFloatOrReference(name): name;
				case ParseCustom(name, _): name;
				case ParseBool(name): name;
				case ParseColor(name): name;
			}
		}
		function findByName(name:String) {
			var res = Lambda.find(parameters, x->name == getName(x));
			if (res == null) syntaxError('optional param $name not declared');
			return res;
		}
		function getValue(parsingMode):Dynamic {
			return switch parsingMode {
				case ParseInteger(_): parseInteger();
				case ParseIntegerOrReference(_): parseIntegerOrReference();
				case ParseFloat(_): parseFloat();
				case ParseFloatOrReference(_): parseFloatOrReference();
				case ParseBool(_): parseBool();
				case ParseCustom(_, parse): parse();
				case ParseColor(_): parseColor();
			}
		}

			var results:Map<String, Dynamic> = [];
			var canBreak = false;
			while(true) {
				switch stream {
					case [MPIdentifier(name, _, ITString), MPColon]:	
						once.parsed(name);
						final param = findByName(name);
						results.set(name, getValue(param));
						canBreak = false;
					case _ :
						if (canBreak) break;
						else  {
							eatComma();
							canBreak = true;
						}
				}

			}
			return results;
	}

	function parse():MultiAnimResult {
		switch stream {
			case [MPIdentifier(_, MPVersion, ITString), MPColon, MPNumber(fileVersion, NTInteger|NTFloat)]:
				if (fileVersion != version) syntaxError('verson ${version} expected, got ${fileVersion}');
			case _: syntaxError('verson expected, got ${peek(0)}');
		}
		
		parseNodes(null, [], createOnceParser(), 654321);
		switch stream {
			case [MPEof]:
			case _: unexpectedError("unexpected content: probably mismatching \", ) or }");
		}

		for (action in postParsedActions) {
			switch action {
				case PPAVerifyRelativeLayout(layoutName, pos):
					var l = nodes.get(defaultLayoutNodeName);
					switch l.type {
						case RELATIVE_LAYOUTS(layoutsDef):
							if (layoutsDef.exists(layoutName) == false) syntaxError('expected relativeLayout to have layout name ${layoutName} but did not', pos);
						default: syntaxError('expected relativeLayout but got ${l.type}', pos);
					}
				case PPAUpdateAndVerifyParticlesTemplate(particleTemplate, particlesDef, pos):
					var particles = nodes.get(particleTemplate);
					if (particles == null) syntaxError('particles ${particleTemplate} does not exist', pos);
					switch particles.type {
						case PARTICLES(templateParticlesDef):
							updateParticlesFromTemplate(templateParticlesDef, particlesDef);
							validateParticles(particlesDef, pos);

						default: syntaxError('expected particles ${particleTemplate} but got ${particles.type}', pos);
					}


			}
		}

		return {
			nodes:nodes,
			imports:imports
		}
	}



}
