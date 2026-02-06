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
	MPQuestion;
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
	MPLessThan;
	MPGreaterThan;
	MPLessEquals;
	MPGreaterEquals;
	MPNotEquals;
	MPDoubleEquals;
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
	MPRepeatable2D;
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
	MPArc;
	MPBezier;
	MPCheckpoint;
	MPList;
	MPSequence;
	MPRect;
	MPFilledRect;
	MPPixel;
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
	MPPolygon;
	MPGraphics;
	MPCircle;
	MPEllipse;
	MPRoundRect;
	MPInt;
	MPFloat;
	MPString;
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
	MPRange;
	MPSmoothing;
	MPTiles;
	// Autotile keywords
	MPAutotile;
	MPFormat;
	MPPrefix;
	MPRegion;
	MPDepth;
	MPMapping;
	MPCross;
	MPBlob47;
	MPDemo;
	// Conditional keywords
	MPElse;
	MPDefault;
}

enum PlaceholderTypes {
	PHTileSource(source:TileSource);
	PHError;
	PHNothing;
}

enum PlaceholderReplacementSource {
	PRSCallback(name:ReferenceableValue);
	PRSCallbackWithIndex(name:ReferenceableValue, index:ReferenceableValue);
	PRSBuilderParameterSource(name:ReferenceableValue);
}

@:using(bh.multianim.MultiAnimParser)
enum UpdatableNameType {
	UNTObject(name:String);
	UNTUpdatable(name:String);
}

enum SettingValueType {
	SVTString;
	SVTInt;
	SVTFloat;
}

typedef ParsedSettingValue = {
	var type:SettingValueType;
	var value:ReferenceableValue;
}

enum SettingValue {
	RSVString(s:String);
	RSVInt(i:Int);
	RSVFloat(f:Float);
}

typedef ResolvedSettings = Null<Map<String, SettingValue>>;

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
		"\\?" => MPQuestion,
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
		"!=" => MPNotEquals,
		"==" => MPDoubleEquals,
		"=" => MPEquals,
		"<=" => MPLessEquals,
		">=" => MPGreaterEquals,
		"<" => MPLessThan,
		">" => MPGreaterThan,
		";" => MPSemiColon,
		"[\n\r]" => lexer.token(tok),
		"//[^\n\r]*" => lexer.token(tok),
		"/\\*" => {
			lexer.token(blockComment);
			lexer.token(tok);
		},
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

	public static var blockComment = @:rule [
		"\\*/" => lexer.curPos().pmin,
		"[^\\*]+" => lexer.token(blockComment),
		"\\*" => lexer.token(blockComment),
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
	PIXEL(pixel:PixelPixel);
}

enum GraphicsStyle {
	GSFilled;
	GSLineWidth(width:ReferenceableValue);
}

enum GraphicsElement {
	GERect(color:ReferenceableValue, style:GraphicsStyle, width:ReferenceableValue, height:ReferenceableValue);
	GEPolygon(color:ReferenceableValue, style:GraphicsStyle, points:Array<Coordinates>);
	GECircle(color:ReferenceableValue, style:GraphicsStyle, radius:ReferenceableValue);
	GEEllipse(color:ReferenceableValue, style:GraphicsStyle, width:ReferenceableValue, height:ReferenceableValue);
	GEArc(color:ReferenceableValue, style:GraphicsStyle, radius:ReferenceableValue, startAngle:ReferenceableValue, arcAngle:ReferenceableValue);
	GERoundRect(color:ReferenceableValue, style:GraphicsStyle, width:ReferenceableValue, height:ReferenceableValue, radius:ReferenceableValue);
	GELine(color:ReferenceableValue, lineWidth:ReferenceableValue, start:Coordinates, end:Coordinates);
}

typedef PositionedGraphicsElement = {
	var element:GraphicsElement;
	var pos:Coordinates;
}

@:NotNull
typedef PixelLine = {
	start:Coordinates,
	end:Coordinates,
	color:ReferenceableValue
}

@:NotNull
typedef PixelRect = {
	start:Coordinates,
	width:ReferenceableValue,
	height:ReferenceableValue,
	color:ReferenceableValue

}

@:NotNull
typedef PixelPixel = {
	pos:Coordinates,
	color:ReferenceableValue
}

enum DefinitionType {
	PPTHexDirection;
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

enum RvUnaryOp {
	OpNeg;
}

enum RvOp {
	OpAdd;
	OpMul;
	OpSub;
	OpDiv;
	OpIntegerDiv;
	OpMod;
	OpEq;
	OpNotEq;
	OpLess;
	OpGreater;
	OpLessEq;
	OpGreaterEq;
}


enum ResolvedIndexParameters {
	Index(idx:Int, value:String);
	Value(val:Int);
	ValueF(val:Float);
	Flag(f:Int);
	StringValue(s:String);
	ArrayString(strArray:Array<String>);
	TileSourceValue(tileSource:TileSource);
}


enum ConditionalValues {
	CoEnums(a:Array<String>);
	CoRange(from:Null<Float>, to:Null<Float>, fromExclusive:Bool, toExclusive:Bool);
	CoIndex(idx:Int, value:String);
	CoValue(val:Int);
	CoFlag(f:Int);
	CoAny;
	CoStringValue(s:String);
	CoNot(value:ConditionalValues);

}

enum ReferenceableValueFunction {
	RVFGridWidth;
	RVFGridHeight;
}

enum ReferenceableValue {
	RVElementOfArray(arrayRef:String, index:ReferenceableValue);
	RVString(s:String);
	RVInteger(i:Int);
	RVArray(refArr:Array<ReferenceableValue>);
	RVArrayReference(refArr:String);
	RVFloat(f:Float);
	RVReference(ref:String);
	RVFunction(functionType:ReferenceableValueFunction);
	RVParenthesis(e:ReferenceableValue);
	RVCallbacksWithIndex(name:ReferenceableValue, index:ReferenceableValue, defaultValue:ReferenceableValue);
	RVCallbacks(name:ReferenceableValue, defaultValue:ReferenceableValue);
	RVColorXY(externalReference:Null<String>, palette:String, x:ReferenceableValue, y:ReferenceableValue);
	RVColor(externalReference:Null<String>, palette:String, index:ReferenceableValue);
	RVTernary(condition:ReferenceableValue, ifTrue:ReferenceableValue, ifFalse:ReferenceableValue);
	EBinop(op:RvOp, e1:ReferenceableValue, e2:ReferenceableValue);
	EUnaryOp(op:RvUnaryOp, e:ReferenceableValue);
}

enum TextAlignWidth {
	TAWAuto;
	TAWValue(value:Int);
	TAWGrid;
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
	Rate(float:ReferenceableValue);
	Checkpoint(checkpointName:String);
}

@:structInit
class AnimatedPathTimedAction {
    public var at:AnimatedPathTime;
    public var action:AnimatedPathsAction;
}

@:nullSafety
enum AnimatedPathsAction {
	ChangeSpeed(speed:ReferenceableValue);
    Accelerate(acceleration:ReferenceableValue, duration:ReferenceableValue);
    Event(eventName:String);
    AttachParticles(particlesName:String, particlesTemplate:String, particlesDef:ParticlesDef);
    RemoveParticles(particlesName:String);
    ChangeAnimSMState(state:String);
}


@:nullSafety
typedef AnimatedPathDef = Array<AnimatedPathTimedAction>;

@:nullSafety
enum PathCoordinateMode {
	PCMAbsolute;
	PCMRelative;
}

@:nullSafety
enum SmoothingType {
	STNone;
	STAuto;
	STDistance(value:ReferenceableValue);
}

enum ParsedPaths {
	LineTo(end:Coordinates, mode:Null<PathCoordinateMode>);
	Forward(distance:ReferenceableValue);
	TurnDegrees(angleDelta:ReferenceableValue);
	Checkpoint(checkpointName:String);
	Bezier2To(end:Coordinates, control:Coordinates, mode:Null<PathCoordinateMode>, smoothing:Null<SmoothingType>);
	Bezier3To(end:Coordinates, control1:Coordinates, control2:Coordinates, mode:Null<PathCoordinateMode>, smoothing:Null<SmoothingType>);
	Arc(radius:ReferenceableValue, angleDelta:ReferenceableValue);
}

@:nullSafety
typedef PathsDef = Map<String, Array<ParsedPaths>>;


enum ParticlesEmitMode {
	Point(emitDistance:ReferenceableValue, emitDistanceRandom:ReferenceableValue);
	Cone(emitDistance:ReferenceableValue, emitDistanceRandom:ReferenceableValue, emitConeAngle:ReferenceableValue, emitConeAngleRandom:ReferenceableValue);
	Box(width:ReferenceableValue, height:ReferenceableValue, emitConeAngle:ReferenceableValue, emitConeAngleRandom:ReferenceableValue);
	Path(points:Array<{x:ReferenceableValue, y:ReferenceableValue}>, emitConeAngle:ReferenceableValue, emitConeAngleRandom:ReferenceableValue);
	Circle(radius:ReferenceableValue, radiusRandom:ReferenceableValue, emitConeAngle:ReferenceableValue, emitConeAngleRandom:ReferenceableValue);
}

// Force field types for particles
enum ParticleForceFieldDef {
	FFAttractor(x:ReferenceableValue, y:ReferenceableValue, strength:ReferenceableValue, radius:ReferenceableValue);
	FFRepulsor(x:ReferenceableValue, y:ReferenceableValue, strength:ReferenceableValue, radius:ReferenceableValue);
	FFVortex(x:ReferenceableValue, y:ReferenceableValue, strength:ReferenceableValue, radius:ReferenceableValue);
	FFWind(vx:ReferenceableValue, vy:ReferenceableValue);
	FFTurbulence(strength:ReferenceableValue, scale:ReferenceableValue, speed:ReferenceableValue);
}

// Curve point for velocity/size over lifetime
typedef ParticleCurvePoint = {
	var time:ReferenceableValue;
	var value:ReferenceableValue;
}

// Bounds mode for particle collision
enum ParticleBoundsModeDef {
	BMNone;
	BMKill;
	BMBounce(damping:ReferenceableValue);
	BMWrap;
}

// Sub-emitter trigger types
enum ParticleSubEmitTriggerDef {
	SETOnBirth;
	SETOnDeath;
	SETOnCollision;
	SETOnInterval(interval:ReferenceableValue);
}

// Sub-emitter configuration
typedef ParticleSubEmitterDef = {
	var groupId:String;
	var trigger:ParticleSubEmitTriggerDef;
	var probability:ReferenceableValue;
	var inheritVelocity:Null<ReferenceableValue>;
	var offsetX:Null<ReferenceableValue>;
	var offsetY:Null<ReferenceableValue>;
}

@:nullSafety
typedef ParticlesDef = {
	var count:Null<ReferenceableValue>;
	var loop:Null<Bool>;
	var relative:Null<Bool>;
	var emitDelay:Null<ReferenceableValue>;
	var emitSync:Null<ReferenceableValue>;
	var maxLife:Null<ReferenceableValue>;
	var lifeRandom:Null<ReferenceableValue>;
	var size:Null<ReferenceableValue>;
	var sizeRandom:Null<ReferenceableValue>;
	var blendMode:Null<h2d.BlendMode>;
	var speed:Null<ReferenceableValue>;
	var speedRandom:Null<ReferenceableValue>;
	var speedIncrease:Null<ReferenceableValue>;
	var gravity:Null<ReferenceableValue>;
	var gravityAngle:Null<ReferenceableValue>;
	var fadeIn:Null<ReferenceableValue>;
	var fadeOut:Null<ReferenceableValue>;
	var fadePower:Null<ReferenceableValue>;
	var tiles:Array<TileSource>;
	var emit:ParticlesEmitMode;
	var rotationInitial:Null<ReferenceableValue>;
	var rotationSpeed:Null<ReferenceableValue>;
	var rotationSpeedRandom:Null<ReferenceableValue>;
	var rotateAuto:Null<Bool>;
	// Color interpolation
	var colorStart:Null<ReferenceableValue>;
	var colorEnd:Null<ReferenceableValue>;
	var colorMid:Null<ReferenceableValue>;
	var colorMidPos:Null<ReferenceableValue>;
	// Force fields
	var forceFields:Null<Array<ParticleForceFieldDef>>;
	// Curves
	var velocityCurve:Null<Array<ParticleCurvePoint>>;
	var sizeCurve:Null<Array<ParticleCurvePoint>>;
	// Trails
	var trailEnabled:Null<Bool>;
	var trailLength:Null<ReferenceableValue>;
	var trailFadeOut:Null<Bool>;
	// Bounds/collision
	var boundsMode:Null<ParticleBoundsModeDef>;
	var boundsMinX:Null<ReferenceableValue>;
	var boundsMaxX:Null<ReferenceableValue>;
	var boundsMinY:Null<ReferenceableValue>;
	var boundsMaxY:Null<ReferenceableValue>;
	// Sub-emitters
	var subEmitters:Null<Array<ParticleSubEmitterDef>>;
	// Animation
	var animationRepeat:Null<ReferenceableValue>;
}

enum RepeatType {
	GridIterator(dx:ReferenceableValue, dy:ReferenceableValue, repeatCount:ReferenceableValue);
	LayoutIterator(layoutName:String);
	ArrayIterator(valueVariableName:String, arrayName:String);
	RangeIterator(start:ReferenceableValue, end:ReferenceableValue, step:ReferenceableValue);
	StateAnimIterator(bitmapVarName:String, animFilename:String, animationName:ReferenceableValue, selector:Map<String, ReferenceableValue>);
	// tiles($bitmap, "sheetname") - exposes $bitmap, $tilename, $index
	// tiles($bitmap, "sheetname", "tileprefix") - exposes $bitmap, $index (filters to tiles matching prefix)
	TilesIterator(bitmapVarName:String, tilenameVarName:Null<String>, sheetName:String, tileFilter:Null<String>);
}

// Selector for which tile to get from an autotile
enum AutotileTileSelector {
	ByIndex(index:ReferenceableValue);     // Select by tile index (0-46 for blob47)
	ByEdges(edges:Int);                    // Select by edge bitmask (N|E|S|W|NE|SE|SW|NW)
}

enum GeneratedTileType {
	Cross(width:ReferenceableValue, height:ReferenceableValue, color:ReferenceableValue);
	SolidColor(width:ReferenceableValue, height:ReferenceableValue, color:ReferenceableValue);
	SolidColorWithText(width:ReferenceableValue, height:ReferenceableValue, color:ReferenceableValue, text:ReferenceableValue, textColor:ReferenceableValue, font:ReferenceableValue);
	AutotileRef(autotileName:ReferenceableValue, selector:AutotileTileSelector);
	AutotileRegionSheet(autotileName:ReferenceableValue, scale:ReferenceableValue, font:ReferenceableValue, fontColor:ReferenceableValue);  // Shows entire region with numbered grid overlay
}

enum TileSource {
	TSFile(filename:ReferenceableValue);
	TSSheet(sheet:ReferenceableValue, name:ReferenceableValue);
	TSSheetWithIndex(sheet:ReferenceableValue, name:ReferenceableValue, index:ReferenceableValue);
	TSGenerated(type:GeneratedTileType);
	TSTile(tile:h2d.Tile); // Used for iterator-provided tiles (e.g., from stateanim iterator)
	TSReference(varName:String); // Reference to a TileSource variable (e.g., $bitmap from stateanim iterator)
}

enum PaletteType {
	PaletteColors(colors:Array<ReferenceableValue>);
	PaletteColors2D(colors:Array<ReferenceableValue>, width:Int);
	PaletteImageFile(filename:ReferenceableValue);
}

// Autotile formats for terrain generation
enum AutotileFormat {
	Cross;      // Cross layout + corners for elevation (with depth)
	Blob47;     // Full 47-tile autotile with all edge/corner combinations
}

enum AutotileSource {
	ATSAtlas(sheet:ReferenceableValue, prefix:ReferenceableValue);
	ATSAtlasRegion(sheet:ReferenceableValue, region:Array<ReferenceableValue>);
	ATSFile(filename:ReferenceableValue);
	ATSTiles(tiles:Array<TileSource>);  // explicit tile list for full control
	ATSDemo(edgeColor:ReferenceableValue, fillColor:ReferenceableValue);  // auto-generated demo tiles
}

@:nullSafety
typedef AutotileDef = {
	var format:AutotileFormat;
	var source:AutotileSource;
	var tileSize:ReferenceableValue;
	var ?depth:Null<ReferenceableValue>;  // for isometric elevation
	var ?mapping:Null<Map<Int, Int>>;     // custom index mapping: blob47Index -> tilesetIndex
	var ?region:Null<Array<ReferenceableValue>>;  // optional region [x, y, w, h] for file source
	var ?allowPartialMapping:Bool;        // blob47 only: if true, missing tiles use fallback instead of error
}

enum StateAnimConstruct {
	IndexedSheet(sheet:String, name:ReferenceableValue, fps:ReferenceableValue, loop: Bool, center:Bool);
}

@:nullSafety
typedef TextDef = {
	var fontName:ReferenceableValue;
	var text:ReferenceableValue;
	var color:ReferenceableValue;
	var halign:Null<HorizontalAlign>;
	var textAlignWidth: TextAlignWidth;
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
	FLOW(maxWidth:Null<ReferenceableValue>, maxHeight:Null<ReferenceableValue>, minWidth:Null<ReferenceableValue>, minHeight:Null<ReferenceableValue>,
		lineHeight:Null<ReferenceableValue>, colWidth:Null<ReferenceableValue>, layout:Null<h2d.Flow.FlowLayout>,
		paddingTop:Null<ReferenceableValue>,paddingBottom:Null<ReferenceableValue>, paddingLeft:Null<ReferenceableValue>, paddingRight:Null<ReferenceableValue>,
		horizontalSpacing:Null<ReferenceableValue>, verticalSpacing:Null<ReferenceableValue>, debug:Bool, multiline:Bool
		);
	BITMAP(tileSource:TileSource, hAlign:HorizontalAlign, vAlign:VerticalAlign);
	POINT;
	STATEANIM(filename:String, initialState:ReferenceableValue, selector:Map<String, ReferenceableValue>);
	STATEANIM_CONSTRUCT(initialState:ReferenceableValue, construct:Map<String, StateAnimConstruct>);
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
	REPEAT2D(varNameX:String, varNameY:String, repeatTypeX:RepeatType, repeatTypeY:RepeatType);
	REFERENCE(externalReference:Null<String>, programmableReference:String, parameters:Map<String, ReferenceableValue>);
	PLACEHOLDER(type:PlaceholderTypes, replacementSource:PlaceholderReplacementSource);
	NINEPATCH(sheet:String, tilename:String, width:ReferenceableValue, height:ReferenceableValue);
	INTERACTIVE(width:ReferenceableValue, height:ReferenceableValue, id:ReferenceableValue, debug:Bool);
	PALETTE(paletteType:PaletteType);
	GRAPHICS(elements:Array<PositionedGraphicsElement>);
	AUTOTILE(autotileDef:AutotileDef);

}

enum NodeConditionalValues {
	Conditional(values:Map<String, ConditionalValues>, strict:Bool);
	ConditionalElse(values:Null<Map<String, ConditionalValues>>);
	ConditionalDefault;
	NoConditional;
}

enum FilterType {
	FilterNone;
	FilterGroup(filters:Array<FilterType>);
	FilterOutline(s:ReferenceableValue, color:ReferenceableValue);
	FilterSaturate(v:ReferenceableValue);
	FilterBrightness(v:ReferenceableValue);
	FilterGlow(color:ReferenceableValue, alpha:ReferenceableValue, radius:ReferenceableValue, gain:ReferenceableValue, quality:ReferenceableValue, smoothColor:Bool, knockout:Bool);
	FilterBlur(radius:ReferenceableValue, gain:ReferenceableValue, quality:ReferenceableValue, linear:ReferenceableValue);
	FilterDropShadow(distance:ReferenceableValue, angle:ReferenceableValue, color:ReferenceableValue, alpha:ReferenceableValue, radius:ReferenceableValue, gain:ReferenceableValue, quality:ReferenceableValue, smoothColor:Bool);
	FilterPixelOutline(mode:PixelOutlineModeDef, smoothColor:Bool);
	FilterPaletteReplace(paletteName:String, sourceRow:ReferenceableValue, replacementRow:ReferenceableValue);
	FilterColorListReplace(sourceColors:Array<ReferenceableValue>, replacementColors:Array<ReferenceableValue>);

}

// Used to keep pixelOutline parameters referenceable until build time
enum PixelOutlineModeDef {
	POKnockout(color:ReferenceableValue, knockout:ReferenceableValue);
	POInlineColor(color:ReferenceableValue, inlineColor:ReferenceableValue);
}

@:nullSafety
typedef Node = {
	parent:Null<Node>,
	pos:Coordinates,
	gridCoordinateSystem:Null<GridCoordinateSystem>,
	hexCoordinateSystem:Null<HexCoordinateSystem>,
	scale: Null<ReferenceableValue>,
	alpha: Null<ReferenceableValue>,
	layer:Null<Int>,
	filter: Null<FilterType>,
	blendMode: Null<h2d.BlendMode>,
	updatableName:UpdatableNameType,
	type:NodeType,
	children:Array<Node>,
	conditionals: NodeConditionalValues,
	uniqueNodeName:String,
	settings:Null<Map<String, ParsedSettingValue>>,
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
	final version = "0.3";
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
			#if MULTIANIM_TRACE
			trace(e);
			#end
			throw e;
		}
		
	}

	function unexpectedError(?message:String):Dynamic {
		//throw '${peek(0)}, ${peek(1)}, ${peek(2)}';

		final error = new MultiAnimUnexpected(peek(0), stream.curPos(), message, input);
		#if MULTIANIM_TRACE
		trace(error);
		#end
		throw error;
		
	}

	function syntaxError(error, ?pos):Dynamic {
		final error = new InvalidSyntax(error, pos == null ? stream.curPos(): pos, input);
		#if MULTIANIM_TRACE
		trace(error);
		#end
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


	function tryParseIntegerOrStringForComparison():ReferenceableValue {
		// For comparisons, allow string literals even in integer context
		return switch peek(0) {
			case MPIdentifier(_, _, ITQuotedString): parseStringOrReference();
			case _: parseIntegerOrReference();
		}
	}

	function tryParseFloatOrStringForComparison():ReferenceableValue {
		// For comparisons, allow string literals even in float context
		return switch peek(0) {
			case MPIdentifier(_, _, ITQuotedString): parseStringOrReference();
			case _: parseFloatOrReference();
		}
	}

	function parseNextIntExpression(e1:ReferenceableValue):ReferenceableValue {
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
			case [MPDoubleEquals]:
				binop(e1, OpEq, tryParseIntegerOrStringForComparison());
			case [MPNotEquals]:
				binop(e1, OpNotEq, tryParseIntegerOrStringForComparison());
			case [MPLessThan]:
				binop(e1, OpLess, tryParseIntegerOrStringForComparison());
			case [MPGreaterThan]:
				binop(e1, OpGreater, tryParseIntegerOrStringForComparison());
			case [MPLessEquals]:
				binop(e1, OpLessEq, tryParseIntegerOrStringForComparison());
			case [MPGreaterEquals]:
				binop(e1, OpGreaterEq, tryParseIntegerOrStringForComparison());
			case _:
				e1;
		}
	}

	function parseNextFloatExpression(e1:ReferenceableValue):ReferenceableValue {
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
			case [MPDoubleEquals]:
				binop(e1, OpEq, tryParseFloatOrStringForComparison());
			case [MPNotEquals]:
				binop(e1, OpNotEq, tryParseFloatOrStringForComparison());
			case [MPLessThan]:
				binop(e1, OpLess, tryParseFloatOrStringForComparison());
			case [MPGreaterThan]:
				binop(e1, OpGreater, tryParseFloatOrStringForComparison());
			case [MPLessEquals]:
				binop(e1, OpLessEq, tryParseFloatOrStringForComparison());
			case [MPGreaterEquals]:
				binop(e1, OpGreaterEq, tryParseFloatOrStringForComparison());
			case _:
				e1;
		}
	}

	function parseNextStringExpression(e1:ReferenceableValue):ReferenceableValue {
		return switch stream {
			case [MPPlus, e2 = parseStringOrReference()]:
				binop(e1, OpAdd, e2);
			case [MPDoubleEquals, e2 = parseStringOrReference()]:
				binop(e1, OpEq, e2);
			case [MPNotEquals, e2 = parseStringOrReference()]:
				binop(e1, OpNotEq, e2);
			case [MPLessThan, e2 = parseStringOrReference()]:
				binop(e1, OpLess, e2);
			case [MPGreaterThan, e2 = parseStringOrReference()]:
				binop(e1, OpGreater, e2);
			case [MPLessEquals, e2 = parseStringOrReference()]:
				binop(e1, OpLessEq, e2);
			case [MPGreaterEquals, e2 = parseStringOrReference()]:
				binop(e1, OpGreaterEq, e2);
			case _:
				e1;
		}
	}


	function parseStringInterpolated():ReferenceableValue {
		
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

	function binop(e1:ReferenceableValue, op:RvOp, e2:ReferenceableValue) {
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
	
	function parseArrayOrReference():Array<ReferenceableValue> {
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
			case [MPQuestion, MPOpen, condition = parseAnything(), MPClosed, ifTrue = parseColorOrReference(), MPColon, ifFalse = parseColorOrReference()]:
				RVTernary(condition, ifTrue, ifFalse);
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
		var colors:Array<ReferenceableValue> = [];
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

	/**
	 * Parse autotile tile selector: either an index (number) or edge flags (N+E+S+W+NE+SE+SW+NW)
	 * Edge flags use + to combine (e.g., N+E+S for a tile with north, east, south neighbors).
	 */
	function parseAutotileTileSelector():AutotileTileSelector {
		// Try to parse as edge flags first (identifiers like N, E, S, W, etc.)
		return switch peek(0) {
			case MPIdentifier(id, _, ITString) if (isEdgeFlag(id)):
				// Parse edge flags combined with +
				var edges = 0;
				while (true) {
					switch stream {
						case [MPIdentifier(flagId, _, ITString)]:
							final flag = parseEdgeFlag(flagId);
							if (flag == null) unexpectedError('unknown edge flag: $flagId');
							edges |= flag;
						case _: unexpectedError('expected edge flag (N, E, S, W, NE, SE, SW, NW)');
					}
					// Check for + (combine flags)
					switch peek(0) {
						case MPPlus: junk(); // consume +
						case _: break;
					}
				}
				ByEdges(edges);
			case _:
				// Parse as index
				ByIndex(parseIntegerOrReference());
		};
	}

	function isEdgeFlag(id:String):Bool {
		return switch id.toUpperCase() {
			case "N" | "NE" | "E" | "SE" | "S" | "SW" | "W" | "NW": true;
			case _: false;
		};
	}

	function parseEdgeFlag(id:String):Null<Int> {
		// Using same bit values as bh.base.Autotile
		return switch id.toUpperCase() {
			case "N": 1;
			case "NE": 2;
			case "E": 4;
			case "SE": 8;
			case "S": 16;
			case "SW": 32;
			case "W": 64;
			case "NW": 128;
			case _: null;
		};
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
		} else {
			// parse as integer
			return Std.parseInt(s);
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

	function parseFunction():ReferenceableValueFunction {
		return switch stream {
			case [MPIdentifier("gridWidth", _, ITString), MPClosed]: RVFGridWidth;
			case [MPIdentifier("gridHeight", _, ITString), MPClosed]:RVFGridHeight;
			case _: syntaxError("unknown function");
		}
	}

	function parseNextAnythingExpression(e1:ReferenceableValue):ReferenceableValue {
		// Handle all binary operators - works with any types
		return switch stream {
			case [MPPlus, e2 = parseAnything()]:
				binop(e1, OpAdd, e2);
			case [MPMinus, e2 = parseAnything()]:
				binop(e1, OpSub, e2);
			case [MPStar, e2 = parseAnything()]:
				binop(e1, OpMul, e2);
			case [MPSlash, e2 = parseAnything()]:
				binop(e1, OpDiv, e2);
			case [MPPercent, e2 = parseAnything()]:
				binop(e1, OpMod, e2);
			case [MPIdentifier(_, MPDiv, ITString), e2 = parseAnything()]:
				binop(e1, OpIntegerDiv, e2);
			case [MPDoubleEquals]:
				binop(e1, OpEq, tryParseIntegerOrStringForComparison());
			case [MPNotEquals]:
				binop(e1, OpNotEq, tryParseIntegerOrStringForComparison());
			case [MPLessThan]:
				binop(e1, OpLess, tryParseIntegerOrStringForComparison());
			case [MPGreaterThan]:
				binop(e1, OpGreater, tryParseIntegerOrStringForComparison());
			case [MPLessEquals]:
				binop(e1, OpLessEq, tryParseIntegerOrStringForComparison());
			case [MPGreaterEquals]:
				binop(e1, OpGreaterEq, tryParseIntegerOrStringForComparison());
			case _:
				e1;
		}
	}

	function parseAnything():ReferenceableValue {
		// Parse any type of value - tries int/float first, then falls back to string
		// This is useful for conditions where we want maximum flexibility
		return switch stream {
			case [MPIdentifier(_, MPCallback, ITString)]: 
				parseCallback(VTString); // Callbacks can return any type
			case [MPIdentifier(_, MPFunction, ITString), MPOpen]: 
				RVFunction(parseFunction());
			case [MPMinus]:
				switch stream {
					case [MPNumber(n, NTInteger|NTHexInteger)]:
						parseNextAnythingExpression(RVInteger(-stringToInt(n)));
					case [MPNumber(n, NTFloat)]:
						parseNextAnythingExpression(RVFloat(-stringToFloat(n)));
					case [MPIdentifier(s, _ , ITReference)]:
						switch stream {
							case [MPBracketOpen, index = parseAnything(), MPBracketClosed]:
								parseNextAnythingExpression(EUnaryOp(OpNeg, RVElementOfArray(s, index)));
							case _:
								parseNextAnythingExpression(EUnaryOp(OpNeg, RVReference(s)));
						}
					case [MPOpen, e = parseAnything(), MPClosed]:
						parseNextAnythingExpression(EUnaryOp(OpNeg, RVParenthesis(e)));
					case _: syntaxError('expected value after unary minus');
				}
			case [MPNumber(n, NTInteger|NTHexInteger)]:
				parseNextAnythingExpression(RVInteger(stringToInt(n)));
			case [MPNumber(n, NTFloat)]:
				parseNextAnythingExpression(RVFloat(stringToFloat(n)));
			case [MPIdentifier(s, _ , ITReference)]:
				switch stream {
					case [MPBracketOpen, index = parseAnything(), MPBracketClosed]:
						parseNextAnythingExpression(RVElementOfArray(s, index));
					case _:
						parseNextAnythingExpression(RVReference(s));
				}
			case [MPIdentifier(s, _, ITQuotedString|ITString|ITName)]:
				parseNextAnythingExpression(RVString(s));
			case [MPOpen, e = parseAnything(), MPClosed]:
				parseNextAnythingExpression(RVParenthesis(e));
			case _: syntaxError('expected value or expression, got ${peek(0)}');
		}
	}

	function parseIntegerOrReference() {
		
		return switch stream {
			case [MPQuestion, MPOpen, condition = parseAnything(), MPClosed, ifTrue = parseIntegerOrReference(), MPColon, ifFalse = parseIntegerOrReference()]:
				parseNextIntExpression(RVTernary(condition, ifTrue, ifFalse));

			case [MPIdentifier(_, MPCallback, ITString)]: parseCallback(VTInt);
			case [MPIdentifier(_, MPFunction, ITString), MPOpen]: RVFunction(parseFunction());
			case [MPMinus]:
				switch stream {
					case [MPNumber(n, NTInteger|NTHexInteger)]:
						parseNextIntExpression(RVInteger(-stringToInt(n)));
					case [MPIdentifier(s, _ , ITReference)]:
						switch stream {
							case [MPBracketOpen, index = parseIntegerOrReference(), MPBracketClosed]:
								parseNextIntExpression(EUnaryOp(OpNeg, RVElementOfArray(s, index)));
							case _:
								parseNextIntExpression(EUnaryOp(OpNeg, RVReference(s)));
						}
					case [MPOpen, e = parseIntegerOrReference(), MPClosed]:
						parseNextIntExpression(EUnaryOp(OpNeg, RVParenthesis(e)));
					case _: syntaxError('expected value after unary minus');
				}
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

case [MPQuestion, MPOpen, condition = parseAnything(), MPClosed, ifTrue = parseFloatOrReference(), MPColon, ifFalse = parseFloatOrReference()]:
				parseNextFloatExpression(RVTernary(condition, ifTrue, ifFalse));

			case [MPIdentifier(_, MPCallback, ITString)]: parseCallback(VTFloat);
			case [MPIdentifier(_, MPFunction, ITString), MPOpen]: RVFunction(parseFunction());
			case [MPMinus]:
				switch stream {
					case [MPNumber(n, NTInteger|NTFloat)]:
						parseNextFloatExpression(RVFloat(-stringToFloat(n)));
					case [MPIdentifier(s, _ , ITReference)]:
						switch stream {
							case [MPBracketOpen, index = parseFloatOrReference(), MPBracketClosed]:
								parseNextFloatExpression(EUnaryOp(OpNeg, RVElementOfArray(s, index)));
							case _:
								parseNextFloatExpression(EUnaryOp(OpNeg, RVReference(s)));
						}
					case [MPOpen, e = parseFloatOrReference(), MPClosed]:
						parseNextFloatExpression(EUnaryOp(OpNeg, RVParenthesis(e)));
					case _: syntaxError('expected value after unary minus');
				}
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
			case [MPQuestion, MPOpen, condition = parseAnything(), MPClosed, ifTrue = parseStringOrReference(), MPColon, ifFalse = parseStringOrReference()]:
				parseNextStringExpression(RVTernary(condition, ifTrue, ifFalse));
			case [MPIdentifier(_, MPCallback, ITString)]: parseCallback(VTString);
			case [MPMinus, MPNumber(s, _)]:
				parseNextStringExpression(RVString('-' + s));
			case [MPNumber(s, _)]:
				// Check if followed by identifier for fontnames like "3x5"
				switch stream {
					case [MPIdentifier(s2, _, ITString)]:
						parseNextStringExpression(RVString(s + s2));
					case _:
						parseNextStringExpression(RVString(s));
				}
			case [MPIdentifier(s, _, ITQuotedString|ITString)]:
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

	// Parse stateanim selector: key=>value pairs until )
	// Returns the selector map
	function parseStateAnimSelector():Map<String, ReferenceableValue> {
		var selector:Map<String, ReferenceableValue> = [];
		while (true) {
			switch stream {
				case [MPClosed]: break;
				case [MPComma, MPIdentifier(key, _, ITString|ITQuotedString) | MPNumber(key, _), MPArrow, value = parseStringOrReference()]:
					if (selector.exists(key)) syntaxError('${key} already set');
					selector.set(key, value);
			}
		}
		return selector;
	}

	// Parse tiles iterator variants after "tiles($bitmap, "
	// Returns TilesIterator with appropriate parameters
	function parseTilesIteratorArgs(bitmapVarName:String, currentDefinitions:ParametersDefinitions):RepeatType {
		switch stream {
			// tiles($bitmap, $tilename, "sheetname") - tilename var is ITString or ITReference
			case [MPIdentifier(tilenameVarName, _, ITString | ITReference), MPComma, MPIdentifier(sheetName, _, ITQuotedString), MPClosed]:
				if (currentDefinitions.exists(tilenameVarName)) syntaxError('tiles iterator tilename variable name "${tilenameVarName}" is already a parameter.');
				return TilesIterator(bitmapVarName, tilenameVarName, sheetName, null);
			// tiles($bitmap, "sheetname"...) - sheetname is ITQuotedString, need nested switch for , vs )
			case [MPIdentifier(sheetName, _, ITQuotedString)]:
				switch stream {
					case [MPComma, MPIdentifier(tileFilter, _, ITQuotedString), MPClosed]:
						return TilesIterator(bitmapVarName, null, sheetName, tileFilter);
					case [MPClosed]:
						return TilesIterator(bitmapVarName, null, sheetName, null);
					case _: syntaxError("expected tiles($bitmap, \"sheetname\", \"tilename\") or tiles($bitmap, \"sheetname\")");
				}
			case _: syntaxError("expected tiles($bitmap, $tilename, \"sheetname\") or tiles($bitmap, \"sheetname\", \"tilename\") or tiles($bitmap, \"sheetname\")");
		}
		return null; // unreachable
	}

	function parseXY():Coordinates {
		try {
			switch stream {
				case [MPIdentifier(_, MPGrid, ITString), MPOpen, x = parseIntegerOrReference(), MPComma, y = parseIntegerOrReference()]:
					switch stream {
						case [MPComma, offsetX = parseIntegerOrReference(), MPComma, offsetY = parseIntegerOrReference(), MPClosed]:
							return SELECTED_GRID_POSITION_WITH_OFFSET(x,y, offsetX, offsetY);
						case [MPClosed]:
							return SELECTED_GRID_POSITION(x,y);
						case _: throw unexpectedError("Expected , offsetX, offsetY or )");
					}
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
			case _: syntaxError("pointy or flat expected");
		}
		return null;

	}

	public static function tryStringToBool(val:String) {
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

	public static function dynamicToInt(dynValue:Dynamic, err:String->Dynamic):Int {


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
			case PPTHexDirection:
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
			case PPTHexDirection:
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

						if (i > 0) return Value(1);
						else if (i == 0) return Value(0);
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
							case [MPIdentifier(str, _, _)]: str;
							case [MPNumber(str, NTHexInteger)]: '0x' + str;
							case [MPNumber(str, _)]: str;
							case [MPMinus, MPNumber(str, numType)]: 
								switch (numType) {
									case NTInteger|NTFloat: '-' + str;
									case NTHexInteger: '-0x' + str;
								}
						}
						param.defaultValue = dynamicValueToIndex(param.name, param.type, s, s->syntaxError(s));

				}
			case _:
		}

	}
	function parseDefine() {


		var parameter:Definition = {
			name: null,
			type: PPTHexDirection,
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
						parameter.type = PPTHexDirection;
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
				parameter.type = PPTHexDirection;
			case [MPNumber(from, NTInteger), MPDoubleDot]:
				// Range starting with positive number
				switch stream {
					case [MPNumber(to, NTInteger)]:
						parameter.type = PPTRange(stringToInt(from), stringToInt(to));
					case [MPMinus, MPNumber(to, NTInteger)]:
						// positive..negative range (e.g., 50..-10)
						parameter.type = PPTRange(stringToInt(from), -stringToInt(to));
				}
			case [MPMinus, MPNumber(from, NTInteger), MPDoubleDot]:
				// Range starting with negative number (e.g., -50..150)
				switch stream {
					case [MPNumber(to, NTInteger)]:
						parameter.type = PPTRange(-stringToInt(from), stringToInt(to));
					case [MPMinus, MPNumber(to, NTInteger)]:
						// negative..negative range (e.g., -50..-10)
						parameter.type = PPTRange(-stringToInt(from), -stringToInt(to));
				}
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
			case [MPIdentifier(_, MPString, ITString)]: 
						parameter.type = PPTString;
						parameter.defaultValue = StringValue("");

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

	function parseReferenceParameters(defined:ParametersDefinitions):Map<String, ReferenceableValue> {

		function error(s:String):Dynamic {
			return syntaxError(s);
		}
		final parameterValues:Map<String, ReferenceableValue> = [];
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
								case PPTHexDirection:  parseIntegerOrReference();
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
				case PPTHexDirection:
					var i = dynamicToInt(value, s->syntaxError(s));
					if (i < 0 || i > 5) syntaxError('conditional $name: hexdirection must be 0...5, was $value');
				case PPTGridDirection:
						var i = dynamicToInt(value, s->syntaxError(s));
						if (i < 0 ||  i > 7) syntaxError('conditional $name: gridDirection must be 0...7, was $value');
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

		function parseConditionalSingleValue(name:String, type:DefinitionType, negate:Bool):ConditionalValues {
			// backward compat: @(param => !value)
			if (!negate) {
				negate = switch stream {
					case [MPExclamation]: true;
					case _: false;
				}
			}

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
				case [MPIdentifier("greaterThanOrEqual", _, ITString), val = parseInteger()]:
					validateIntTypes(name, type, val);
					CoRange(val, null, false, false);
				case [MPIdentifier("lessThanOrEqual", _, ITString), val = parseInteger()]:
					validateIntTypes(name, type, val);
					CoRange(null, val, false, false);
				case [MPIdentifier("between", _, ITString), val1 = parseInteger(), MPDoubleDot, val2 = parseInteger()]:
					validateIntTypes(name, type, val1);
					validateIntTypes(name, type, val2);
					CoRange(val1, val2, false, false);
				case [MPIdentifier(value, _, ITString|ITQuotedString)]:
					dynamicToConditionalParam(value, type);
				case [MPIdentifier(value, _, ITName)]:
					dynamicToConditionalParam("#"+value, type);
				case [MPNumber(value, NTInteger|NTFloat)]:
					// check for bare range: N1..N2
					var rangeResult = switch stream {
						case [MPDoubleDot]:
							var val2 = parseInteger();
							var val1:Dynamic = value;
							validateIntTypes(name, type, val1);
							validateIntTypes(name, type, val2);
							CoRange(stringToInt(value), val2, false, false);
						case _: null;
					}
					if (rangeResult != null) rangeResult; else dynamicToConditionalParam(value, type);
				case [MPNumber(value, NTHexInteger)]:
					dynamicToConditionalParam("0x"+value, type);
				case [MPMinus, MPNumber(value, _)]:
					// check for bare negative range: -N1..N2
					var rangeResult = switch stream {
						case [MPDoubleDot]:
							var val2 = parseInteger();
							var val1:Dynamic = '-'+value;
							validateIntTypes(name, type, val1);
							validateIntTypes(name, type, val2);
							CoRange(-stringToInt(value), val2, false, false);
						case _: null;
					}
					if (rangeResult != null) rangeResult; else dynamicToConditionalParam('-'+value, type);
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
			return value;
		}

		while (true) {

			switch stream {
				case [MPIdentifier(name, _, ITString|ITQuotedString)]:

					final paramDefinitions = defined.get(name);
					if (paramDefinitions == null) syntaxError('conditional parameter $name does not have definition in $defined');
					if (parameterValues.exists(name)) syntaxError('conditional parameter ${name} already defined');

					final type = paramDefinitions.type;

					var value = switch stream {
						case [MPGreaterEquals]:
							var val = parseInteger();
							validateIntTypes(name, type, val);
							CoRange(val, null, false, false);
						case [MPLessEquals]:
							var val = parseInteger();
							validateIntTypes(name, type, val);
							CoRange(null, val, false, false);
						case [MPGreaterThan]:
							var val = parseInteger();
							validateIntTypes(name, type, val);
							CoRange(val, null, true, false);
						case [MPLessThan]:
							var val = parseInteger();
							validateIntTypes(name, type, val);
							CoRange(null, val, false, true);
						case [MPNotEquals]:
							parseConditionalSingleValue(name, type, true);
						case [MPArrow]:
							parseConditionalSingleValue(name, type, false);
					}
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
				case [MPIdentifier(_, MPPixel, ITString), pos = parseXY(), MPComma, color = parseColorOrReference()]:
					shapes.push(PIXEL({ pos: pos, color: color }));
			}
		}
	}

	function parseGraphicsStyleRequired():GraphicsStyle {
		return switch stream {
			case [MPIdentifier("filled", _, ITString|ITQuotedString), MPComma]:
				GSFilled;
			case [lw = parseFloatOrReference(), MPComma]:
				GSLineWidth(lw);
			case _: unexpectedError("expected filled or line width");
		}
	}

	function parseGraphicsElements() {
		var elements:Array<PositionedGraphicsElement> = [];
		while (true) {
			var element = switch stream {
				case [MPIdentifier(_, MPRect, ITString)]:
					parseGraphicsRectElement();
				case [MPIdentifier(_, MPPolygon, ITString)]:
					parseGraphicsPolygonElement();
				case [MPIdentifier(_, MPCircle, ITString)]:
					parseGraphicsCircleElement();
				case [MPIdentifier(_, MPEllipse, ITString)]:
					parseGraphicsEllipseElement();
				case [MPIdentifier(_, MPArc, ITString)]:
					parseGraphicsArcElement();
				case [MPIdentifier(_, MPRoundRect, ITString)]:
					parseGraphicsRoundRectElement();
				case [MPIdentifier(_, MPLine, ITString)]:
					parseGraphicsLineElement();
				case [MPClosed]:
					return elements;
				case [MPComma]:
					continue;
				case _: unexpectedError("expected graphics element or )");
			}

			var pos = switch stream {
				case [MPSemiColon]:
					ZERO;
				case [MPColon, p = parseXY()]:
					p;
				case _: unexpectedError("expected ; or :xy after graphics element");
			}

			elements.push({element: element, pos: pos});
		}
	}

	function parseGraphicsRectElement():GraphicsElement {
		return switch stream {
			case [MPOpen, color = parseColorOrReference(), MPComma]:
				final style = parseGraphicsStyleRequired();


				var width = parseIntegerOrReference();
				switch stream {
					case [MPComma]:
					case _: unexpectedError("expected , after width");
				}

				var height = parseIntegerOrReference();

				switch stream {
					case [MPClosed]:
					case _: unexpectedError("expected ) after rect");
				}

				GERect(color, style, width, height);
			case _: unexpectedError("expected rect(color, filled|lineWidth, width, height)");
		}
	}

	function parseGraphicsPolygonElement():GraphicsElement {
		return switch stream {
			case [MPOpen, color = parseColorOrReference(), MPComma]:
				var style = parseGraphicsStyleRequired();
				var points:Array<Coordinates> = [];

				while (true) {
					switch stream {
						case [MPClosed]:
							break;
						case _:
							points.push(parseXY());
							switch stream {
								case [MPComma]:
									continue;
								case [MPClosed]:
									break;
								case _: unexpectedError("expected , or ) after polygon point");
							}
					}
					break;
				}

				if (points.length < 3) syntaxError("polygon requires at least 3 points");

				GEPolygon(color, style, points);
			case _: unexpectedError("expected polygon(color, lineWidth|filled, points...)");
		}
	}

	function parseGraphicsCircleElement():GraphicsElement {
		return switch stream {
			case [MPOpen, color = parseColorOrReference(), MPComma]:
				final style = parseGraphicsStyleRequired();
				eatComma();
				var radius = parseFloatOrReference();

				switch stream {
					case [MPClosed]:
					case _: unexpectedError("expected ) after circle");
				}
				GECircle(color, style, radius);
			case _: unexpectedError("expected circle(color[, filled|lineWidth], radius)");
		}
	}

	function parseGraphicsEllipseElement():GraphicsElement {
		return switch stream {
			case [MPOpen, color = parseColorOrReference(), MPComma]:
				final style = parseGraphicsStyleRequired();
				var width:ReferenceableValue = null;
				var height:ReferenceableValue = null;

				switch stream {
					case [w = parseFloatOrReference(), MPComma, h = parseFloatOrReference()]:
						width = w;
						height = h;
					case _: unexpectedError("expected width and height after style");
				}
			
				switch stream {
					case [MPClosed]:
					case _: unexpectedError("expected ) after ellipse");
				}

				GEEllipse(color, style, width, height);
			case _: unexpectedError("expected ellipse(color[, filled|lineWidth], width, height)");
		}
	}

	function parseGraphicsArcElement():GraphicsElement {
		return switch stream {
			case [MPOpen, color = parseColorOrReference(), MPComma]:
				final style = parseGraphicsStyleRequired();
				
				var radius:ReferenceableValue = null;
				var startAngle:ReferenceableValue = null;
				var arcAngle:ReferenceableValue = null;

								
				switch stream {
					case [r = parseFloatOrReference(), MPComma, sa = parseFloatOrReference(), MPComma, aa = parseFloatOrReference(), MPClosed]:
						radius = r;
						startAngle = sa;
						arcAngle = aa;
					case _: unexpectedError("expected radius, startAngle, arcAngle after style");
				}

				
				GEArc(color, style, radius, startAngle, arcAngle);
			case _: unexpectedError("expected arc(color, style, radius, startAngle, arcAngle)");
		}
	}

	

	function parseGraphicsRoundRectElement():GraphicsElement {
		return switch stream {
			case [MPOpen, color = parseColorOrReference(), MPComma]:
				final style = parseGraphicsStyleRequired();
				var width:ReferenceableValue = null;
				var height:ReferenceableValue = null;
				var radius:ReferenceableValue = null;

				switch stream {
					case [w = parseFloatOrReference(), MPComma, h = parseFloatOrReference(), MPComma, r = parseFloatOrReference()]:
						width = w;
						height = h;
						radius = r;
					case _: unexpectedError("line width, or width after color");
				}

				switch stream {
					case [MPClosed]:
					case _: unexpectedError("expected ) after roundrect");
				}


				GERoundRect(color, style, width, height, radius);
			case _: unexpectedError("expected roundrect(color[, filled|lineWidth], width, height, radius)");
		}
	}

	function parseGraphicsLineElement():GraphicsElement {
		return switch stream {
			case [MPOpen, color = parseColorOrReference(), MPComma, lineWidth = parseFloatOrReference(), MPComma,
				  start = parseXY(), MPComma, end = parseXY(), MPClosed]:
				GELine(color, lineWidth, start, end);
			case _: unexpectedError("expected line(color, lineWidth, x1, y1, x2, y2)");
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
					// colorWithText(width, height, bgColor, "text", textColor, font) - solid color with centered text
					case [MPIdentifier("colorWithText", _ , ITString), MPOpen, width = parseIntegerOrReference(), MPComma, height = parseIntegerOrReference(), MPComma, color = parseColorOrReference(), MPComma, text = parseStringOrReference(), MPComma, textColor = parseColorOrReference(), MPComma, font = parseStringOrReference(), MPClosed, MPClosed]:
						TSGenerated(SolidColorWithText(width, height, color, text, textColor, font));
					// autotile("autotileName", index) OR autotile("autotileName", N|E|S|W) - reference autotile definition
					case [MPIdentifier("autotile", _ , ITString), MPOpen, autotileName = parseStringOrReference(), MPComma]:
						final selector = parseAutotileTileSelector();
						switch stream {
							case [MPClosed, MPClosed]:
							case _: unexpectedError('expected ) after autotile selector');
						}
						TSGenerated(AutotileRef(autotileName, selector));
					// autotileRegionSheet("autotileName", scale, "font", fontColor) - shows entire region with numbered grid overlay
					case [MPIdentifier("autotileRegionSheet", _ , ITString), MPOpen, autotileName = parseStringOrReference(), MPComma, scale = parseIntegerOrReference(), MPComma, font = parseStringOrReference(), MPComma, fontColor = parseColorOrReference(), MPClosed, MPClosed]:
						TSGenerated(AutotileRegionSheet(autotileName, scale, font, fontColor));
					case _: unexpectedError('expected cross(...), color(...), colorWithText(...), autotile(name, index|edges), or autotileRegionSheet(name, scale, font, fontColor)');
				}

			// Reference to a TileSource variable (e.g., $bitmap from stateanim/tiles iterator)
			case [MPIdentifier(varName, _, ITReference)]:
				TSReference(varName);

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
		var alpha:Null<ReferenceableValue> = null;
		var scale:Null<ReferenceableValue> = null;
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
						case [MPIdentifier(_, MPElse, ITString)]:
							onceInline.parsed("conditional");
							switch stream {
								case [MPOpen]:
									conditional = ConditionalElse(parseConditionalParameters(currentDefinitions, false));
								case _:
									conditional = ConditionalElse(null);
							}
						case [MPIdentifier(_, MPDefault, ITString)]:
							onceInline.parsed("conditional");
							conditional = ConditionalDefault;
						case _: break;
					}
					atLestOneInline++;


				}
				if (atLestOneInline == 0) syntaxError('at least one conditional or inline property is required when using @');
			case _:
		}

		// Validate @else/@default placement: must have a preceding sibling with a conditional
		switch conditional {
			case ConditionalElse(_) | ConditionalDefault:
				if (parent == null) syntaxError('@else/@default cannot be used on root elements');
				if (parent.children.length == 0) syntaxError('@else/@default requires a preceding sibling with a @() conditional');
				var prevSibling = parent.children[parent.children.length - 1];
				switch prevSibling.conditionals {
					case NoConditional:
						syntaxError('@else/@default requires a preceding sibling with a @() conditional, but the previous sibling has no conditional');
					case _: // OK - preceding sibling has Conditional, ConditionalElse, or ConditionalDefault
				}
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
						var selector:Map<String, ReferenceableValue> = [];
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

				

				var maxWidth:Null<ReferenceableValue> = null;
				var maxHeight:Null<ReferenceableValue> = null;
				var minWidth:Null<ReferenceableValue> = null;
				var minHeight:Null<ReferenceableValue> = null;
				
				var lineHeight:Null<ReferenceableValue> = null;
				var colWidth:Null<ReferenceableValue> = null;
				var layout:Null<h2d.Flow.FlowLayout> = null;
				
				var paddingLeft:Null<ReferenceableValue> = null;
				var paddingRight:Null<ReferenceableValue> = null;
				var paddingTop:Null<ReferenceableValue> = null;
				var paddingBottom:Null<ReferenceableValue> = null;
				var horizontalSpacing:Null<ReferenceableValue> = null;
				var verticalSpacing:Null<ReferenceableValue> = null;
				var debug:Bool = false;
				var multiline:Bool = false;


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
												   ParseCustom(MacroUtils.identToString(multiline), parseBool),
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
				MacroUtils.optionsSetIfNotNull(multiline, results);

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
				

				createNodeResponse(FLOW(maxWidth, maxHeight, minWidth, minHeight, lineHeight, colWidth, layout, paddingTop, paddingBottom, paddingLeft, paddingRight, horizontalSpacing, verticalSpacing, debug, multiline));
				
			case [MPIdentifier(_, MPPoint, ITString)]:
				switch stream {
					case [MPOpen, MPClosed]:
					case _:
				}	
				createNodeResponse(POINT);
			
			case [MPIdentifier(_, MPText, ITString), MPOpen, fontname = parseStringOrReference(), MPComma, text = parseStringOrReference(), MPComma, color = parseColorOrReference()]:

				
				var textAlignWidth:TextAlignWidth = TAWAuto;
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
									switch stream {
										case [MPIdentifier(_, MPGrid, ITString)]:
											textAlignWidth = TAWGrid;
										case _: 
											final maxWidth = tryParseInteger();
											if (maxWidth == null) hasComma = true;
											else textAlignWidth = TAWValue(maxWidth);
									}
								
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
					 textAlignWidth: textAlignWidth,
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
			case [MPIdentifier(_, MPAutotile, ITString), MPCurlyOpen]:
				if (nameString == null) syntaxError('autotile requires #name');
				if (parent != null) syntaxError('autotile nodes must be root node');

				final autotileDef = parseAutotile();
				return createNodeResponse(AUTOTILE(autotileDef)); // return here skips extended syntax parsing
			case [MPIdentifier(_, MPLayers, ITString)]:
				switch stream {
					case [MPOpen, MPClosed]: true;
					case _:
				}
				createNodeResponse(LAYERS);

		case [MPIdentifier(_, MPSettings, ITString), MPCurlyOpen]:
			if (parent == null) syntaxError('settings must have a parent');
			if (parent.settings == null) parent.settings = [];
			
			while (true) {
				switch stream {
					case [MPIdentifier(key, _, _)]:
						// Now check if it's typed (key:type=>value) or untyped (key=>value)
						switch stream {
							case [MPColon]:
								// Match the type keyword and arrow together
								switch stream {
									case [MPIdentifier(_, MPInt, ITString), MPArrow]:
										final value = parseIntegerOrReference();
										if (parent.settings.exists(key)) syntaxError('setting ${key} already defined');
										parent.settings[key] = {type: SVTInt, value: value};
									case [MPIdentifier(_, MPFloat, ITString), MPArrow]:
										final value = parseFloatOrReference();
										if (parent.settings.exists(key)) syntaxError('setting ${key} already defined');
										parent.settings[key] = {type: SVTFloat, value: value};
									case [MPIdentifier(_, MPString, ITString), MPArrow]:
										final value = parseStringOrReference();
										if (parent.settings.exists(key)) syntaxError('setting ${key} already defined');
										parent.settings[key] = {type: SVTString, value: value};
									case _: unexpectedError("Expected int=>value, float=>value, or string=>value after :");
								}
							case [MPArrow]:
								// Untyped setting: key => value (defaults to string)
								final value = parseStringOrReference();
								if (parent.settings.exists(key)) syntaxError('setting ${key} already defined');
								parent.settings[key] = {type: SVTString, value: value};
							case _: unexpectedError("Expected :type=> or => after setting key");
						}
					case _: unexpectedError("Expected setting key identifier");
				}
				switch stream {
					case [MPComma]:
					case [MPCurlyClosed]: break;
					case _: unexpectedError("Expected , or }");
				}
			}
				return null;
			
		
	case [MPIdentifier(_, MPPixels, ITString), MPOpen, pixelShapes = parseShapes()]:
		createNodeResponse(PIXELS(pixelShapes));

	case [MPIdentifier(_, MPRect, ITString)]:
		createNodeResponse(GRAPHICS([{element: parseGraphicsRectElement(), pos: ZERO}]));

	case [MPIdentifier(_, MPLine, ITString)]:
		createNodeResponse(GRAPHICS([{element: parseGraphicsLineElement(), pos: ZERO}]));

	case [MPIdentifier(_, MPPolygon, ITString)]:
		createNodeResponse(GRAPHICS([{element: parseGraphicsPolygonElement(), pos: ZERO}]));

	case [MPIdentifier(_, MPCircle, ITString)]:
		createNodeResponse(GRAPHICS([{element: parseGraphicsCircleElement(), pos: ZERO}]));

	case [MPIdentifier(_, MPEllipse, ITString)]:
		createNodeResponse(GRAPHICS([{element: parseGraphicsEllipseElement(), pos: ZERO}]));

	case [MPIdentifier(_, MPArc, ITString)]:
		createNodeResponse(GRAPHICS([{element: parseGraphicsArcElement(), pos: ZERO}]));

	case [MPIdentifier(_, MPRoundRect, ITString)]:
		createNodeResponse(GRAPHICS([{element: parseGraphicsRoundRectElement(), pos: ZERO}]));

	case [MPIdentifier(_, MPGraphics, ITString), MPOpen, elements = parseGraphicsElements()]:
		createNodeResponse(GRAPHICS(elements));
		
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
							final params:Map<String, ReferenceableValue> = switch stream {
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
				

			case [MPIdentifier(_, MPRepeatable2D, ITString), MPOpen,  MPIdentifier(varNameX, _, ITReference | ITString), MPComma, MPIdentifier(varNameY, _, ITReference | ITString), MPComma]:
				
				if (currentDefinitions.exists(varNameX)) syntaxError('repeatable2d name "${varNameX}" is already a parameter.');
				if (currentDefinitions.exists(varNameY)) syntaxError('repeatable2d name "${varNameY}" is already a parameter.');
				var repeatTypeX = switch stream {
					case [MPIdentifier(_, MPGrid, ITString), MPOpen, repeatCount = parseIntegerOrReference(), MPComma ]:
						var once = createOnceParser();
						var dx:Null<ReferenceableValue> = null;
						var dy:Null<ReferenceableValue> = null;

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
						GridIterator(dx, dy, repeatCount);
					case [MPIdentifier(_, MPLayout, ITString), MPOpen, MPIdentifier(layout, _, ITQuotedString|ITString), MPComma, MPIdentifier(layoutName, _, ITQuotedString|ITString), MPClosed]:
						postParsedActions.push(PPAVerifyRelativeLayout(layoutName, stream.curPos()));
						LayoutIterator(layoutName);
					case [MPIdentifier(_, MPArray, ITString), MPOpen, MPIdentifier(valueVariableName, _, ITString | ITReference), MPComma,  MPIdentifier(arrayName, _, ITReference | ITString), MPClosed]:
						if (currentDefinitions.exists(valueVariableName)) syntaxError('repeatable2d array iterator value variable name "${valueVariableName}" is already a parameter.');
						ArrayIterator(valueVariableName, arrayName);
					case [MPIdentifier(_, MPRange, ITString), MPOpen, start = parseIntegerOrReference(), MPComma, end = parseIntegerOrReference() ]:
						switch stream {
							case [MPClosed]:
								RangeIterator(start, end, RVInteger(1));
							case [MPComma, step = parseIntegerOrReference(), MPClosed]:
								RangeIterator(start, end, step);
							case _: syntaxError("expected )");
						}
					case [MPIdentifier(_, MPStateanim, ITString), MPOpen, MPIdentifier(bitmapVarName, _, ITString | ITReference), MPComma, MPIdentifier(animFilename, _, ITQuotedString), MPComma, animationName = parseStringOrReference()]:
						if (currentDefinitions.exists(bitmapVarName)) syntaxError('repeatable2d stateanim iterator bitmap variable name "${bitmapVarName}" is already a parameter.');
						StateAnimIterator(bitmapVarName, animFilename, animationName, parseStateAnimSelector());
					case [MPIdentifier(_, MPTiles, ITString), MPOpen, MPIdentifier(bitmapVarName, _, ITString | ITReference), MPComma]:
						if (currentDefinitions.exists(bitmapVarName)) syntaxError('repeatable2d tiles iterator bitmap variable name "${bitmapVarName}" is already a parameter.');
						parseTilesIteratorArgs(bitmapVarName, currentDefinitions);

					case _: syntaxError("unknown repeatable iterator, expected grid(...) | layout(...) | array(...) | range(...) | stateanim(...) | tiles(...)");
				}
				switch stream {
					case [MPComma]:
					case _: syntaxError("expected ,");
				}
				var repeatTypeY = switch stream {
					case [MPIdentifier(_, MPGrid, ITString), MPOpen, repeatCount = parseIntegerOrReference(), MPComma ]:
						var once = createOnceParser();
						var dx:Null<ReferenceableValue> = null;
						var dy:Null<ReferenceableValue> = null;

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
						GridIterator(dx, dy, repeatCount);
					case [MPIdentifier(_, MPLayout, ITString), MPOpen, MPIdentifier(layout, _, ITQuotedString|ITString), MPComma, MPIdentifier(layoutName, _, ITQuotedString|ITString), MPClosed]:
						postParsedActions.push(PPAVerifyRelativeLayout(layoutName, stream.curPos()));
						LayoutIterator(layoutName);
					case [MPIdentifier(_, MPArray, ITString), MPOpen, MPIdentifier(valueVariableName, _, ITString | ITReference), MPComma,  MPIdentifier(arrayName, _, ITReference | ITString), MPClosed]:
						if (currentDefinitions.exists(valueVariableName)) syntaxError('repeatable2d array iterator value variable name "${valueVariableName}" is already a parameter.');
						ArrayIterator(valueVariableName, arrayName);
					case [MPIdentifier(_, MPRange, ITString), MPOpen, start = parseIntegerOrReference(), MPComma, end = parseIntegerOrReference() ]:
						switch stream {
							case [MPClosed]:
								RangeIterator(start, end, RVInteger(1));
							case [MPComma, step = parseIntegerOrReference(), MPClosed]:
								RangeIterator(start, end, step);
							case _: syntaxError("expected )");
						}
					case [MPIdentifier(_, MPStateanim, ITString), MPOpen, MPIdentifier(bitmapVarName, _, ITString | ITReference), MPComma, MPIdentifier(animFilename, _, ITQuotedString), MPComma, animationName = parseStringOrReference()]:
						if (currentDefinitions.exists(bitmapVarName)) syntaxError('repeatable2d stateanim iterator bitmap variable name "${bitmapVarName}" is already a parameter.');
						StateAnimIterator(bitmapVarName, animFilename, animationName, parseStateAnimSelector());
					case [MPIdentifier(_, MPTiles, ITString), MPOpen, MPIdentifier(bitmapVarName, _, ITString | ITReference), MPComma]:
						if (currentDefinitions.exists(bitmapVarName)) syntaxError('repeatable2d tiles iterator bitmap variable name "${bitmapVarName}" is already a parameter.');
						parseTilesIteratorArgs(bitmapVarName, currentDefinitions);

					case _: syntaxError("unknown repeatable iterator, expected grid(...) | layout(...) | array(...) | range(...) | stateanim(...) | tiles(...)");
				}
				switch stream {
					case [MPClosed]:
					case _: syntaxError("expected )");
				}

				createNodeResponse(REPEAT2D(varNameX, varNameY, repeatTypeX, repeatTypeY));

			case [MPIdentifier(_, MPRepeatable, ITString), MPOpen,  MPIdentifier(varName, _, ITReference | ITString), MPComma]:
				
				if (currentDefinitions.exists(nameString)) syntaxError('repeatable name "${varName}" is already a parameter.');
				var response = switch stream {
					case [MPIdentifier(_, MPGrid, ITString), MPOpen, repeatCount = parseIntegerOrReference(), MPComma ]:
						var once = createOnceParser();
						var dx:Null<ReferenceableValue> = null;
						var dy:Null<ReferenceableValue> = null;

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
					case [MPIdentifier(_, MPRange, ITString), MPOpen, start = parseIntegerOrReference(), MPComma, end = parseIntegerOrReference() ]:
						switch stream {
							case [MPClosed]:
								createNodeResponse(REPEAT(varName, RangeIterator(start, end, RVInteger(1))));
							case [MPComma, step = parseIntegerOrReference(), MPClosed]:
								createNodeResponse(REPEAT(varName, RangeIterator(start, end, step)));
							case _: syntaxError("expected )");
						}
					case [MPIdentifier(_, MPStateanim, ITString), MPOpen, MPIdentifier(bitmapVarName, _, ITString | ITReference), MPComma, MPIdentifier(animFilename, _, ITQuotedString), MPComma, animationName = parseStringOrReference()]:
						if (currentDefinitions.exists(bitmapVarName)) syntaxError('repeatable stateanim iterator bitmap variable name "${bitmapVarName}" is already a parameter.');
						createNodeResponse(REPEAT(varName, StateAnimIterator(bitmapVarName, animFilename, animationName, parseStateAnimSelector())));
					case [MPIdentifier(_, MPTiles, ITString), MPOpen, MPIdentifier(bitmapVarName, _, ITString | ITReference), MPComma]:
						if (currentDefinitions.exists(bitmapVarName)) syntaxError('repeatable tiles iterator bitmap variable name "${bitmapVarName}" is already a parameter.');
						createNodeResponse(REPEAT(varName, parseTilesIteratorArgs(bitmapVarName, currentDefinitions)));

					case _: syntaxError("unknown repeatable iterator, expected grid(...) | layout(...) | array(...) | range(...) | stateanim(...) | tiles(...)");
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
					case FLOW(_,_,_,_,_,_,_,_,_,_,_,_,_): true;
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

	/** Returns true if the next tokens look like a named parameter (identifier followed by colon). */
	function isNamedParamNext():Bool {
		return switch peek(0) {
			case MPIdentifier(_, _, ITString):
				switch peek(1) {
					case MPColon: true;
					case _: false;
				}
			case _: false;
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
	
	function parseGridCoordinateSystem() {
		var size = parseSize();
		eatSemicolon();
		return {
			spacingX: size.width,
			spacingY: size.height
		}
	}

	function parseHexCoordinateSystem() {
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
			case [MPIdentifier("outline", _ , ITString), MPOpen]:
				if (isNamedParamNext()) {
					var once = createOnceParser();
					var size:Null<ReferenceableValue> = null;
					var color:Null<ReferenceableValue> = null;
					var results = parseOptionalParams([
						ParseFloatOrReference(MacroUtils.identToString(size)),
						ParseCustom(MacroUtils.identToString(color), parseColorOrReference),
					], once);
					switch stream {
						case [MPClosed]:
						case _: unexpectedError("outline expected )");
					}
					FilterOutline(
						MacroUtils.optionsGetPresentOrDefault(size, results, RVFloat(1.)),
						MacroUtils.optionsGetPresentOrDefault(color, results, RVInteger(0xFF000000))
					);
				} else {
					var size = parseFloatOrReference();
					switch stream { case [MPComma]: }
					var color = parseColorOrReference();
					switch stream { case [MPClosed]: }
					FilterOutline(size, color);
				}
			case [MPIdentifier("saturate", _ , ITString), MPOpen]:
				if (isNamedParamNext()) {
					var once = createOnceParser();
					var value:Null<ReferenceableValue> = null;
					var results = parseOptionalParams([
						ParseFloatOrReference(MacroUtils.identToString(value)),
					], once);
					switch stream {
						case [MPClosed]:
						case _: unexpectedError("saturate expected )");
					}
					FilterSaturate(MacroUtils.optionsGetPresentOrDefault(value, results, RVFloat(1.)));
				} else {
					var value = parseFloatOrReference();
					switch stream { case [MPClosed]: }
					FilterSaturate(value);
				}
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
			case [MPIdentifier("brightness", _ , ITString), MPOpen]:
				if (isNamedParamNext()) {
					var once = createOnceParser();
					var value:Null<ReferenceableValue> = null;
					var results = parseOptionalParams([
						ParseFloatOrReference(MacroUtils.identToString(value)),
					], once);
					switch stream {
						case [MPClosed]:
						case _: unexpectedError("brightness expected )");
					}
					FilterBrightness(MacroUtils.optionsGetPresentOrDefault(value, results, RVFloat(1.)));
				} else {
					var value = parseFloatOrReference();
					switch stream { case [MPClosed]: }
					FilterBrightness(value);
				}
			case [MPIdentifier("blur", _ , ITString), MPOpen]:
				if (isNamedParamNext()) {
					var once = createOnceParser();
					var radius:Null<ReferenceableValue> = null;
					var gain:Null<ReferenceableValue> = null;
					var quality:Null<ReferenceableValue> = null;
					var linear:Null<ReferenceableValue> = null;
					var results = parseOptionalParams([
						ParseFloatOrReference(MacroUtils.identToString(radius)),
						ParseFloatOrReference(MacroUtils.identToString(gain)),
						ParseFloatOrReference(MacroUtils.identToString(quality)),
						ParseFloatOrReference(MacroUtils.identToString(linear)),
					], once);
					switch stream {
						case [MPClosed]:
						case _: unexpectedError("blur expected )");
					}
					FilterBlur(
						MacroUtils.optionsGetPresentOrDefault(radius, results, RVFloat(1.)),
						MacroUtils.optionsGetPresentOrDefault(gain, results, RVFloat(1.)),
						MacroUtils.optionsGetPresentOrDefault(quality, results, RVFloat(1.)),
						MacroUtils.optionsGetPresentOrDefault(linear, results, RVFloat(0.0))
					);
				} else {
					var radius = parseFloatOrReference();
					switch stream { case [MPComma]: }
					var gain = parseFloatOrReference();
					switch stream { case [MPClosed]: }
					FilterBlur(radius, gain, RVFloat(1.), RVFloat(0.0));
				}
			case [MPIdentifier("pixelOutline", _ , ITString), MPOpen]: 
				var mode = switch stream {
					case [MPIdentifier("knockout", _ , ITString|ITQuotedString), MPComma, color = parseColorOrReference(), MPComma, knockout = parseFloatOrReference()]: 
						POKnockout(color, knockout);
					case [MPIdentifier("inlineColor", _ , ITString|ITQuotedString), MPComma, color = parseColorOrReference(), MPComma, inlineColor = parseColorOrReference()]: 
						POInlineColor(color, inlineColor);
				}
				final smoothColor = switch stream {
					case [MPComma]:
						switch stream {
							case [MPIdentifier("smoothColor", _, ITString), MPClosed]: true;
							case _: unexpectedError("expected smoothColor)");
						}
					case [MPClosed]: false;
					case _: unexpectedError("expected , smoothColor or )");

				}
				FilterPixelOutline(mode, smoothColor);
			case [MPIdentifier("glow", _ , ITString), MPOpen]: 
				var once = createOnceParser();
			
				var radius:Null<ReferenceableValue> = null;
				var gain:Null<ReferenceableValue> = null;
				var quality:Null<ReferenceableValue> = null;
				var smoothColor:Null<Bool> = null;
				var knockout:Null<Bool> = null;
				var color:Null<ReferenceableValue> = null;
				var alpha:Null<ReferenceableValue> = null;

				var results = parseOptionalParams([
					ParseFloatOrReference(MacroUtils.identToString(alpha)), 
					ParseFloatOrReference(MacroUtils.identToString(radius)), 
					ParseFloatOrReference(MacroUtils.identToString(gain)),
					ParseFloatOrReference(MacroUtils.identToString(quality)),

					ParseBool(MacroUtils.identToString(smoothColor)),
					ParseBool(MacroUtils.identToString(knockout)),
					ParseCustom(MacroUtils.identToString(color), parseColorOrReference),
				
					], once);

					switch stream {
						case [MPClosed]:
						case _: unexpectedError("glow expected )");
					}
				return FilterGlow(
					MacroUtils.optionsGetPresentOrDefault(color, results, RVInteger(0xFFFFFFFF)), 
					MacroUtils.optionsGetPresentOrDefault(alpha, results, RVFloat(1.)),
					MacroUtils.optionsGetPresentOrDefault(radius, results, RVFloat(1.)),
					MacroUtils.optionsGetPresentOrDefault(gain, results, RVFloat(1.)),
					MacroUtils.optionsGetPresentOrDefault(quality, results, RVFloat(1.)),
					MacroUtils.optionsGetPresentOrDefault(smoothColor, results, false),
					MacroUtils.optionsGetPresentOrDefault(knockout, results, false)
					);
				
				
			case [MPIdentifier("dropShadow", _ , ITString), MPOpen]: 
				var once = createOnceParser();
				var distance:Null<ReferenceableValue> = null;
				var angle:Null<ReferenceableValue> = null;
				var alpha:Null<ReferenceableValue> = null;
				var radius:Null<ReferenceableValue> = null;
				var quality:Null<ReferenceableValue> = null;
				var color:Null<ReferenceableValue> = null;
				var gain:Null<ReferenceableValue> = null;
				var smoothColor:Null<Bool> = null;
			

			var results = parseOptionalParams([ParseFloatOrReference(MacroUtils.identToString(distance)), 
											ParseFloatOrReference(MacroUtils.identToString(angle)),
											ParseFloatOrReference(MacroUtils.identToString(alpha)), 
											ParseFloatOrReference(MacroUtils.identToString(radius)),
											ParseCustom(MacroUtils.identToString(color), parseColorOrReference),
											ParseFloatOrReference(MacroUtils.identToString(gain)),
											ParseFloatOrReference(MacroUtils.identToString(quality)),
											ParseBool(MacroUtils.identToString(smoothColor)),
											
											], once);
			

			switch stream {
				case [MPClosed]:
				case _: unexpectedError("dropShadow expected )");
			}
			
			return FilterDropShadow(
				MacroUtils.optionsGetPresentOrDefault(distance, results, RVFloat(4.0)), 
				MacroUtils.optionsGetPresentOrDefault(angle, results, RVFloat(90.0)),
				MacroUtils.optionsGetPresentOrDefault(color, results, RVInteger(0)), 
				MacroUtils.optionsGetPresentOrDefault(alpha, results, RVFloat(1.)),
				MacroUtils.optionsGetPresentOrDefault(radius, results, RVFloat(1.)), 
				MacroUtils.optionsGetPresentOrDefault(gain, results, RVFloat(1.)), 
				MacroUtils.optionsGetPresentOrDefault(quality, results, RVFloat(1.)),
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

					case [MPIdentifier(_, MPArc, ITString), MPOpen, radius = parseIntegerOrReference(), MPComma, angleDelta = parseIntegerOrReference(), MPClosed]:
						pathsArr.push(Arc(radius, angleDelta));

					case [MPIdentifier(_, MPLine, ITString), MPOpen]:
						final coordinateMode = parseCoordinateMode();
						switch stream {
							case [end = parseXY(), MPClosed]:
								pathsArr.push(LineTo(end, coordinateMode));
							case _: syntaxError("expected absolute/relative, or coordinates");
						} 
						
					case [MPIdentifier(_, MPCheckpoint, ITString), MPOpen, MPIdentifier(name, _, ITString|ITQuotedString) , MPClosed]:
						pathsArr.push(Checkpoint(name));
						
					case [MPIdentifier(_, MPBezier, ITString), MPOpen, ]:
						final coordinateMode = parseCoordinateMode();
						
						
						switch stream {
							case [end = parseXY(), MPComma, control1 = parseXY()]:
								switch stream {
									case [MPClosed]:
										pathsArr.push(Bezier2To(end, control1, coordinateMode, null));
									case [MPComma]:
										final smoothing = parseSmoothing();
										if (smoothing != null) {
											switch stream {
												case [MPClosed]:
													pathsArr.push(Bezier2To(end, control1, coordinateMode, smoothing));
												case _: syntaxError("expected )");
											}
										} else {
											final control2 = parseXY();
											switch stream {
												case [MPClosed]:
													pathsArr.push(Bezier3To(end, control1, control2, coordinateMode, null));
												case [MPComma, smoothing2 = parseSmoothing(), MPClosed]:
															pathsArr.push(Bezier3To(end, control1, control2, coordinateMode, smoothing2));
												
												case _: syntaxError("expected ) or smoothing");
											}
										}
										
								
								}
							case _: syntaxError("expected absolute/relative, or coordinates");
						}
						// Check for optional smoothing parameter
		
					case [MPCurlyClosed]: break;
					case _: syntaxError("expected line, arc, bezier, or }");
				}
			}
			paths.set(name, pathsArr);
			
		}
	}

	function parseAnimatedPathAction() {
		return switch stream {
			case [MPIdentifier("changeSpeed", _, ITString),  speed = parseFloatOrReference()]:
				 ChangeSpeed(speed);
			case [MPIdentifier("accelerate", _, ITString), MPOpen, acceleration = parseFloatOrReference(), MPComma, duration = parseFloatOrReference(), MPClosed]:
				 Accelerate(acceleration, duration);
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

			case _: syntaxError("expected changeSpeed or event or attachParticles or removeParticles or changeAnimState or accelerate");
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

	function parseCoordinateMode():Null<PathCoordinateMode> {
		return switch stream {
			case [MPIdentifier("absolute", _, ITString), MPComma]:
				PCMAbsolute;
			case [MPIdentifier("relative", _, ITString), MPComma]:
				PCMRelative;
			case _: null;
		}
	}

	function parseSmoothing():Null<SmoothingType> {
		return switch stream {
			case [MPIdentifier("smoothing", _, ITString), MPColon]:
				switch stream {
					case [MPIdentifier("auto", _, ITString)]:
						 STAuto;
					case [MPIdentifier("none", _, ITString)]:
						 STNone;
					default:
						final value = parseFloatOrReference();
						STDistance(value);

					}
			case _: null;
		}
	}

	function parseParticlesEmitMode():ParticlesEmitMode {
		return switch stream {
			case [MPIdentifier("point", _, ITString), MPOpen, emitDistance = parseFloatOrReference(), MPComma, emitDistanceRandom = parseFloatOrReference(), MPClosed]:
				Point(emitDistance, emitDistanceRandom);
			case [MPIdentifier("cone", _, ITString), MPOpen, emitDistance = parseFloatOrReference(), MPComma, emitDistanceRandom = parseFloatOrReference(), MPComma, emitConeAngle = parseFloatOrReference(), MPComma, emitConeAngleRandom = parseFloatOrReference(), MPClosed]:
				Cone(emitDistance, emitDistanceRandom, emitConeAngle, emitConeAngleRandom);
			case [MPIdentifier("box", _, ITString), MPOpen, width = parseFloatOrReference(), MPComma, height = parseFloatOrReference(), MPComma, emitConeAngle = parseFloatOrReference(), MPComma, emitConeAngleRandom = parseFloatOrReference(), MPClosed]:
				Box(width, height, emitConeAngle, emitConeAngleRandom);
			case [MPIdentifier("circle", _, ITString), MPOpen, radius = parseFloatOrReference(), MPComma, radiusRandom = parseFloatOrReference(), MPComma, emitConeAngle = parseFloatOrReference(), MPComma, emitConeAngleRandom = parseFloatOrReference(), MPClosed]:
				Circle(radius, radiusRandom, emitConeAngle, emitConeAngleRandom);
			case [MPIdentifier("path", _, ITString), MPOpen]:
				var points:Array<{x:ReferenceableValue, y:ReferenceableValue}> = [];
				// Parse path points: path([(x1,y1), (x2,y2), ...], angle, angleRandom)
				switch stream {
					case [MPBracketOpen]:
						while (true) {
							switch stream {
								case [MPOpen, px = parseFloatOrReference(), MPComma, py = parseFloatOrReference(), MPClosed]:
									points.push({x: px, y: py});
									switch stream {
										case [MPComma]: continue;
										case [MPBracketClosed]: break;
										case _: syntaxError("expected , or ]");
									}
								case [MPBracketClosed]: break;
								case _: syntaxError("expected (x, y) or ]");
							}
						}
					case _: syntaxError("expected [");
				}
				switch stream {
					case [MPComma, emitConeAngle = parseFloatOrReference(), MPComma, emitConeAngleRandom = parseFloatOrReference(), MPClosed]:
						Path(points, emitConeAngle, emitConeAngleRandom);
					case _: syntaxError("expected , angle, angleRandom)");
				}
			case _: syntaxError("expected point, cone, box, circle or path");
		}
	}

	function parseForceFields():Array<ParticleForceFieldDef> {
		var fields:Array<ParticleForceFieldDef> = [];
		switch stream {
			case [MPBracketOpen]:
				while (true) {
					var field = parseForceField();
					if (field != null) {
						fields.push(field);
						switch stream {
							case [MPComma]: continue;
							case [MPBracketClosed]: break;
							case _: syntaxError("expected , or ]");
						}
					} else {
						switch stream {
							case [MPBracketClosed]: break;
							case _: syntaxError("expected force field or ]");
						}
					}
				}
			case _: syntaxError("expected [");
		}
		return fields;
	}

	function parseForceField():ParticleForceFieldDef {
		return switch stream {
			case [MPIdentifier("attractor", _, ITString), MPOpen, x = parseFloatOrReference(), MPComma, y = parseFloatOrReference(), MPComma, strength = parseFloatOrReference(), MPComma, radius = parseFloatOrReference(), MPClosed]:
				FFAttractor(x, y, strength, radius);
			case [MPIdentifier("repulsor", _, ITString), MPOpen, x = parseFloatOrReference(), MPComma, y = parseFloatOrReference(), MPComma, strength = parseFloatOrReference(), MPComma, radius = parseFloatOrReference(), MPClosed]:
				FFRepulsor(x, y, strength, radius);
			case [MPIdentifier("vortex", _, ITString), MPOpen, x = parseFloatOrReference(), MPComma, y = parseFloatOrReference(), MPComma, strength = parseFloatOrReference(), MPComma, radius = parseFloatOrReference(), MPClosed]:
				FFVortex(x, y, strength, radius);
			case [MPIdentifier("wind", _, ITString), MPOpen, vx = parseFloatOrReference(), MPComma, vy = parseFloatOrReference(), MPClosed]:
				FFWind(vx, vy);
			case [MPIdentifier("turbulence", _, ITString), MPOpen, strength = parseFloatOrReference(), MPComma, scale = parseFloatOrReference(), MPComma, speed = parseFloatOrReference(), MPClosed]:
				FFTurbulence(strength, scale, speed);
			case _: null;
		};
	}

	function parseCurvePoints():Array<ParticleCurvePoint> {
		var points:Array<ParticleCurvePoint> = [];
		switch stream {
			case [MPBracketOpen]:
				while (true) {
					switch stream {
						case [MPOpen, time = parseFloatOrReference(), MPComma, value = parseFloatOrReference(), MPClosed]:
							points.push({time: time, value: value});
							switch stream {
								case [MPComma]: continue;
								case [MPBracketClosed]: break;
								case _: syntaxError("expected , or ]");
							}
						case [MPBracketClosed]: break;
						case _: syntaxError("expected (time, value) or ]");
					}
				}
			case _: syntaxError("expected [");
		}
		return points;
	}

	function parseBoundsMode():ParticleBoundsModeDef {
		return switch stream {
			case [MPIdentifier("none", _, ITString)]: BMNone;
			case [MPIdentifier("kill", _, ITString)]: BMKill;
			case [MPIdentifier("bounce", _, ITString), MPOpen, damping = parseFloatOrReference(), MPClosed]: BMBounce(damping);
			case [MPIdentifier("wrap", _, ITString)]: BMWrap;
			case _: syntaxError("expected none, kill, bounce(damping) or wrap");
		};
	}

	function parseSubEmitters():Array<ParticleSubEmitterDef> {
		var emitters:Array<ParticleSubEmitterDef> = [];
		switch stream {
			case [MPBracketOpen]:
				while (true) {
					var emitter = parseSubEmitter();
					if (emitter != null) {
						emitters.push(emitter);
						switch stream {
							case [MPComma]: continue;
							case [MPBracketClosed]: break;
							case _: syntaxError("expected , or ]");
						}
					} else {
						switch stream {
							case [MPBracketClosed]: break;
							case _: syntaxError("expected sub-emitter or ]");
						}
					}
				}
			case _: syntaxError("expected [");
		}
		return emitters;
	}

	function parseSubEmitter():ParticleSubEmitterDef {
		return switch stream {
			case [MPCurlyOpen]:
				var groupId:String = null;
				var trigger:ParticleSubEmitTriggerDef = null;
				var probability:ReferenceableValue = RVFloat(1.0);
				var inheritVelocity:Null<ReferenceableValue> = null;
				var offsetX:Null<ReferenceableValue> = null;
				var offsetY:Null<ReferenceableValue> = null;

				while (true) {
					switch stream {
						case [MPIdentifier("group", _, ITString), MPColon, MPIdentifier(gid, _, ITString | ITQuotedString)]:
							groupId = gid;
						case [MPIdentifier("trigger", _, ITString), MPColon]:
							trigger = switch stream {
								case [MPIdentifier("onBirth", _, ITString)]: SETOnBirth;
								case [MPIdentifier("onDeath", _, ITString)]: SETOnDeath;
								case [MPIdentifier("onCollision", _, ITString)]: SETOnCollision;
								case [MPIdentifier("onInterval", _, ITString), MPOpen, interval = parseFloatOrReference(), MPClosed]: SETOnInterval(interval);
								case _: syntaxError("expected onBirth, onDeath, onCollision or onInterval(interval)");
							};
						case [MPIdentifier("probability", _, ITString), MPColon, p = parseFloatOrReference()]:
							probability = p;
						case [MPIdentifier("inheritVelocity", _, ITString), MPColon, iv = parseFloatOrReference()]:
							inheritVelocity = iv;
						case [MPIdentifier("offsetX", _, ITString), MPColon, ox = parseFloatOrReference()]:
							offsetX = ox;
						case [MPIdentifier("offsetY", _, ITString), MPColon, oy = parseFloatOrReference()]:
							offsetY = oy;
						case [MPCurlyClosed]:
							break;
						case _: syntaxError("expected group, trigger, probability, inheritVelocity, offsetX, offsetY or }");
					}
				}

				if (groupId == null) syntaxError("sub-emitter requires group");
				if (trigger == null) syntaxError("sub-emitter requires trigger");

				{groupId: groupId, trigger: trigger, probability: probability, inheritVelocity: inheritVelocity, offsetX: offsetX, offsetY: offsetY};
			case _: null;
		};
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
			// Color interpolation
			colorStart:null,
			colorEnd:null,
			colorMid:null,
			colorMidPos:null,
			// Force fields
			forceFields:null,
			// Curves
			velocityCurve:null,
			sizeCurve:null,
			// Trails
			trailEnabled:null,
			trailLength:null,
			trailFadeOut:null,
			// Bounds
			boundsMode:null,
			boundsMinX:null,
			boundsMaxX:null,
			boundsMinY:null,
			boundsMaxY:null,
			// Sub-emitters
			subEmitters:null,
			// Animation
			animationRepeat:null,
		};
	}

	function updateParticlesFromTemplate(template:ParticlesDef, particlesDef:ParticlesDef):Void {
		particlesDef.count = particlesDef.count ?? template.count;
		particlesDef.emitDelay = particlesDef.emitDelay ?? template.emitDelay;
		particlesDef.emitSync = particlesDef.emitSync ?? template.emitSync;
		particlesDef.maxLife = particlesDef.maxLife ?? template.maxLife;
		particlesDef.lifeRandom = particlesDef.lifeRandom ?? template.lifeRandom;
		particlesDef.size = particlesDef.size ?? template.size;
		particlesDef.sizeRandom = particlesDef.sizeRandom ?? template.sizeRandom;
		particlesDef.speed = particlesDef.speed ?? template.speed;
		particlesDef.speedRandom = particlesDef.speedRandom ?? template.speedRandom;
		particlesDef.speedIncrease = particlesDef.speedIncrease ?? template.speedIncrease;
		particlesDef.loop = particlesDef.loop ?? template.loop;
		particlesDef.relative = particlesDef.relative ?? template.relative;
		particlesDef.tiles = particlesDef.tiles ?? template.tiles;
		particlesDef.gravity = particlesDef.gravity ?? template.gravity;
		particlesDef.gravityAngle = particlesDef.gravityAngle ?? template.gravityAngle;
		particlesDef.fadeIn = particlesDef.fadeIn ?? template.fadeIn;
		particlesDef.fadeOut = particlesDef.fadeOut ?? template.fadeOut;
		particlesDef.fadePower = particlesDef.fadePower ?? template.fadePower;
		particlesDef.blendMode = particlesDef.blendMode ?? template.blendMode;
		particlesDef.emit = particlesDef.emit ?? template.emit;
		particlesDef.rotationInitial = particlesDef.rotationInitial ?? template.rotationInitial;
		particlesDef.rotationSpeed = particlesDef.rotationSpeed ?? template.rotationSpeed;
		particlesDef.rotationSpeedRandom = particlesDef.rotationSpeedRandom ?? template.rotationSpeedRandom;
		particlesDef.rotateAuto = particlesDef.rotateAuto ?? template.rotateAuto;
		// Color interpolation
		particlesDef.colorStart = particlesDef.colorStart ?? template.colorStart;
		particlesDef.colorEnd = particlesDef.colorEnd ?? template.colorEnd;
		particlesDef.colorMid = particlesDef.colorMid ?? template.colorMid;
		particlesDef.colorMidPos = particlesDef.colorMidPos ?? template.colorMidPos;
		// Force fields
		particlesDef.forceFields = particlesDef.forceFields ?? template.forceFields;
		// Curves
		particlesDef.velocityCurve = particlesDef.velocityCurve ?? template.velocityCurve;
		particlesDef.sizeCurve = particlesDef.sizeCurve ?? template.sizeCurve;
		// Trails
		particlesDef.trailEnabled = particlesDef.trailEnabled ?? template.trailEnabled;
		particlesDef.trailLength = particlesDef.trailLength ?? template.trailLength;
		particlesDef.trailFadeOut = particlesDef.trailFadeOut ?? template.trailFadeOut;
		// Bounds
		particlesDef.boundsMode = particlesDef.boundsMode ?? template.boundsMode;
		particlesDef.boundsMinX = particlesDef.boundsMinX ?? template.boundsMinX;
		particlesDef.boundsMaxX = particlesDef.boundsMaxX ?? template.boundsMaxX;
		particlesDef.boundsMinY = particlesDef.boundsMinY ?? template.boundsMinY;
		particlesDef.boundsMaxY = particlesDef.boundsMaxY ?? template.boundsMaxY;
		// Sub-emitters
		particlesDef.subEmitters = particlesDef.subEmitters ?? template.subEmitters;
		// Animation
		particlesDef.animationRepeat = particlesDef.animationRepeat ?? template.animationRepeat;
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
											ParseFloatOrReference(MacroUtils.identToString(fadePower)),

											ParseFloatOrReference(MacroUtils.identToString(rotationSpeed)),
											ParseFloatOrReference(MacroUtils.identToString(rotationSpeedRandom)),
											ParseFloatOrReference(MacroUtils.identToString(rotationInitial)),
											ParseBool(MacroUtils.identToString(rotateAuto)),

											ParseBool(MacroUtils.identToString(loop)),
											ParseBool(MacroUtils.identToString(relative)),
											ParseCustom(MacroUtils.identToString(tiles), parseTileSources),
											ParseCustom(MacroUtils.identToString(blendMode), tryParseBlendMode),
											ParseCustom(MacroUtils.identToString(emit), parseParticlesEmitMode),

											// Color interpolation
											ParseColor(MacroUtils.identToString(colorStart)),
											ParseColor(MacroUtils.identToString(colorEnd)),
											ParseColor(MacroUtils.identToString(colorMid)),
											ParseFloatOrReference(MacroUtils.identToString(colorMidPos)),

											// Force fields
											ParseCustom(MacroUtils.identToString(forceFields), parseForceFields),

											// Curves
											ParseCustom(MacroUtils.identToString(velocityCurve), parseCurvePoints),
											ParseCustom(MacroUtils.identToString(sizeCurve), parseCurvePoints),

											// Trails
											ParseBool(MacroUtils.identToString(trailEnabled)),
											ParseIntegerOrReference(MacroUtils.identToString(trailLength)),
											ParseBool(MacroUtils.identToString(trailFadeOut)),

											// Bounds/collision
											ParseCustom(MacroUtils.identToString(boundsMode), parseBoundsMode),
											ParseFloatOrReference(MacroUtils.identToString(boundsMinX)),
											ParseFloatOrReference(MacroUtils.identToString(boundsMaxX)),
											ParseFloatOrReference(MacroUtils.identToString(boundsMinY)),
											ParseFloatOrReference(MacroUtils.identToString(boundsMaxY)),

											// Sub-emitters
											ParseCustom(MacroUtils.identToString(subEmitters), parseSubEmitters),

											// Animation
											ParseFloatOrReference(MacroUtils.identToString(animationRepeat))
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
		// Color interpolation
		MacroUtils.optionsSetIfNotNull(retVal.colorStart, results);
		MacroUtils.optionsSetIfNotNull(retVal.colorEnd, results);
		MacroUtils.optionsSetIfNotNull(retVal.colorMid, results);
		MacroUtils.optionsSetIfNotNull(retVal.colorMidPos, results);
		// Force fields
		MacroUtils.optionsSetIfNotNull(retVal.forceFields, results);
		// Curves
		MacroUtils.optionsSetIfNotNull(retVal.velocityCurve, results);
		MacroUtils.optionsSetIfNotNull(retVal.sizeCurve, results);
		// Trails
		MacroUtils.optionsSetIfNotNull(retVal.trailEnabled, results);
		MacroUtils.optionsSetIfNotNull(retVal.trailLength, results);
		MacroUtils.optionsSetIfNotNull(retVal.trailFadeOut, results);
		// Bounds
		MacroUtils.optionsSetIfNotNull(retVal.boundsMode, results);
		MacroUtils.optionsSetIfNotNull(retVal.boundsMinX, results);
		MacroUtils.optionsSetIfNotNull(retVal.boundsMaxX, results);
		MacroUtils.optionsSetIfNotNull(retVal.boundsMinY, results);
		MacroUtils.optionsSetIfNotNull(retVal.boundsMaxY, results);
		// Sub-emitters
		MacroUtils.optionsSetIfNotNull(retVal.subEmitters, results);
		// Animation
		MacroUtils.optionsSetIfNotNull(retVal.animationRepeat, results);

		return retVal;
	}

	function parseAutotile():AutotileDef {
		var format:Null<AutotileFormat> = null;
		var source:Null<AutotileSource> = null;
		var tileSize:Null<ReferenceableValue> = null;
		var depth:Null<ReferenceableValue> = null;
		var mapping:Null<Map<Int, Int>> = null;
		var region:Null<Array<ReferenceableValue>> = null;
		var allowPartialMapping:Bool = false;

		final once = createOnceParser();

		while (true) {
			switch stream {
				// format: cross | blob47
				case [MPIdentifier(_, MPFormat, ITString), MPColon]:
					once.parsed("format");
					switch stream {
						case [MPIdentifier(_, MPCross, ITString)]:
							format = Cross;
						case [MPIdentifier(_, MPBlob47, ITString)]:
							format = Blob47;
						case _: unexpectedError("expected cross or blob47");
					}

				// sheet: "name", prefix: "tile_"  OR  sheet: "name", region: [x, y, w, h]
				// Note: hxparse only matches first token, so we need nested switch
				case [MPIdentifier(_, MPSheet, ITString), MPColon, sheet = parseStringOrReference(), MPComma]:
					once.parsed("source");
					switch stream {
						case [MPIdentifier(_, MPPrefix, ITString), MPColon, prefix = parseStringOrReference()]:
							source = ATSAtlas(sheet, prefix);
						case [MPIdentifier(_, MPRegion, ITString), MPColon, MPBracketOpen]:
							final region:Array<ReferenceableValue> = [];
							while (true) {
								switch stream {
									case [val = parseIntegerOrReference()]:
										region.push(val);
										switch stream {
											case [MPComma]: continue;
											case [MPBracketClosed]: break;
										}
									case [MPBracketClosed]: break;
									case _: unexpectedError("expected integer or ]");
								}
							}
							if (region.length != 4) syntaxError('region must have exactly 4 values [x, y, w, h]');
							source = ATSAtlasRegion(sheet, region);
						case _: unexpectedError("expected prefix: or region: after sheet:");
					}

				// file: "filename.png"
				case [MPIdentifier(_, MPFile, ITString), MPColon, filename = parseStringOrReference()]:
					once.parsed("source");
					source = ATSFile(filename);

				// tiles: sheet("a","b") sheet("a","c") generated(color(16,16,red)) ...
				case [MPIdentifier(_, MPTiles, ITString), MPColon]:
					once.parsed("source");
					source = ATSTiles(parseTileSources());

				// demo: edgeColor, fillColor (auto-generated demo tiles)
				case [MPIdentifier(_, MPDemo, ITString), MPColon, edgeColor = parseColorOrReference(), MPComma, fillColor = parseColorOrReference()]:
					once.parsed("source");
					source = ATSDemo(edgeColor, fillColor);

				// tileSize: 16
				case [MPIdentifier("tileSize", _, ITString), MPColon, size = parseIntegerOrReference()]:
					once.parsed("tileSize");
					tileSize = size;

				// depth: 16 (for isometric elevation)
				case [MPIdentifier(_, MPDepth, ITString), MPColon, d = parseIntegerOrReference()]:
					once.parsed("depth");
					depth = d;

				// mapping: [1, 2, 3, 7:12] - sequential values or explicit source:target pairs
				// Plain number N at position i means: blob47 tile i -> tileset tile N
				// Explicit N:M means: blob47 tile N -> tileset tile M
				case [MPIdentifier(_, MPMapping, ITString), MPColon, MPBracketOpen]:
					once.parsed("mapping");
					mapping = new Map<Int, Int>();
					var sequentialIndex = 0;
					while (true) {
						switch stream {
							case [sourceIdx = parseInteger()]:
								// Check if this is source:target format
								switch stream {
									case [MPColon, targetIdx = parseInteger()]:
										// Explicit mapping: sourceIdx -> targetIdx
										trace('  PARSER mapping explicit: $sourceIdx:$targetIdx');
										if (mapping.exists(sourceIdx))
											syntaxError('duplicate mapping for tile $sourceIdx');
										mapping.set(sourceIdx, targetIdx);
									case _:
										// Sequential: position -> value
										trace('  PARSER mapping sequential: [$sequentialIndex] = $sourceIdx');
										if (mapping.exists(sequentialIndex))
											syntaxError('duplicate mapping for tile $sequentialIndex');
										mapping.set(sequentialIndex, sourceIdx);
										sequentialIndex++;
								}
								switch stream {
									case [MPComma]: continue;
									case [MPBracketClosed]: break;
									case _: unexpectedError("expected , or ]");
								}
							case [MPBracketClosed]: break;
							case _: unexpectedError("expected integer or ]");
						}
					}

				// allowPartialMapping: true - for blob47, missing tiles use fallback
				case [MPIdentifier("allowPartialMapping", _, ITString), MPColon]:
					once.parsed("allowPartialMapping");
					allowPartialMapping = parseBool();

				// region: [x, y, w, h] - optional region for file source (tile indices relative to this region)
				case [MPIdentifier(_, MPRegion, ITString), MPColon, MPBracketOpen]:
					once.parsed("region");
					region = [];
					while (true) {
						switch stream {
							case [val = parseIntegerOrReference()]:
								region.push(val);
								switch stream {
									case [MPComma]: continue;
									case [MPBracketClosed]: break;
								}
							case [MPBracketClosed]: break;
							case _: unexpectedError("expected integer or ]");
						}
					}
					if (region.length != 4) syntaxError('region must have exactly 4 values [x, y, w, h]');

				case [MPCurlyClosed]: break;
				case _: unexpectedError("expected format:, sheet:, file:, tiles:, demo:, tileSize:, depth:, mapping:, region:, allowPartialMapping:, or }");
			}
		}

		if (format == null) syntaxError('autotile requires format: (cross or blob47)');
		if (source == null) syntaxError('autotile requires source (sheet:, file:, tiles:, or demo:)');
		if (tileSize == null) syntaxError('autotile requires tileSize:');

		// allowPartialMapping only valid for blob47
		if (allowPartialMapping && format != Blob47)
			syntaxError('allowPartialMapping is only valid for blob47 format');

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
				case [MPIdentifier(propName, MPGrid, ITString), MPColon, system = parseGridCoordinateSystem(), MPCurlyOpen]: 
					parsingStates.push(LPSGrid);
					grids.push(system);
				case [MPIdentifier(propName, MPHexGrid, ITString), MPColon, system = parseHexCoordinateSystem(), MPCurlyOpen]: 
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
						node.gridCoordinateSystem = parseGridCoordinateSystem();
				case [MPIdentifier(propName, MPHex , ITString), MPColon]:
						if (node == null) syntaxError('hex coordinate system not supported on root elements');
						once.parsed(propName);
						node.hexCoordinateSystem = parseHexCoordinateSystem();
						
		
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
				case ParseColor(_): parseColorOrReference();
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
				if (fileVersion != version) syntaxError('version ${version} expected, got ${fileVersion}');
			case _: syntaxError('Missing version declaration. Files must start with \'version: ${version}\'');
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
