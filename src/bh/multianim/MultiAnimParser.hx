package bh.multianim;

import bh.multianim.MacroCompatTypes;
import bh.base.Hex;
import bh.base.Hex.HexLayout;
import bh.base.ParseError;
import bh.base.ParseError.ParseUnexpected;
import bh.base.ParsePosition;
import bh.multianim.CoordinateSystems;
import bh.multianim.layouts.LayoutTypes;
using StringTools;
using bh.base.ColorUtils;
#if !macro
import bh.base.Particles;
import bh.base.PixelLine;
import bh.stateanim.AnimationSM;
import h2d.ScaleGrid;
#end

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
	MPMask;
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
	// Atlas2 inline
	MPAtlas2;
	// Conditional keywords
	MPElse;
	MPDefault;
	MPTint;
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

function getNameString(updatableNameType:UpdatableNameType) {
	return switch updatableNameType {
		case UNTObject(name): name;
		case UNTUpdatable(name): name;
	}
}

#if !macro
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
		case HeapsMask(m): m;
		case Particles(p): p;
	}
}
#end

#if !macro
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
	HeapsMask(m:h2d.Mask);
	Particles(p:bh.base.Particles);
}
#end


class MultiAnimUnexpected<Token> extends ParseUnexpected<Token> {

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

// MultiAnimLexer removed — parsing is now handled by MacroManimParser

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
	ExpressionAlias(expr:ReferenceableValue);
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

@:nullSafety
enum AnimatedPathModeType {
	APDistance;
	APTime;
}

@:nullSafety
enum AnimatedPathCurveSlotType {
	APSpeed;
	APScale;
	APAlpha;
	APRotation;
	APProgress;
	APCustom(name:String);
}

@:structInit
class AnimatedPathCurveAssignment {
	public var at:AnimatedPathTime;
	public var slot:AnimatedPathCurveSlotType;
	public var curveName:String;
}

@:structInit
class AnimatedPathTimedEvent {
	public var at:AnimatedPathTime;
	public var eventName:String;
}

@:nullSafety
typedef AnimatedPathDef = {
	var mode:Null<AnimatedPathModeType>;
	var speed:Null<ReferenceableValue>;
	var duration:Null<ReferenceableValue>;
	var pathName:String;
	var curveAssignments:Array<AnimatedPathCurveAssignment>;
	var events:Array<AnimatedPathTimedEvent>;
};

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

@:nullSafety
enum EasingType {
	Linear;
	EaseInQuad;
	EaseOutQuad;
	EaseInOutQuad;
	EaseInCubic;
	EaseOutCubic;
	EaseInOutCubic;
	EaseInBack;
	EaseOutBack;
	EaseInOutBack;
	EaseOutBounce;
	EaseOutElastic;
	CubicBezier(x1:Float, y1:Float, x2:Float, y2:Float);
}

enum ParsedPaths {
	LineTo(end:Coordinates, mode:Null<PathCoordinateMode>);
	Forward(distance:ReferenceableValue);
	TurnDegrees(angleDelta:ReferenceableValue);
	Checkpoint(checkpointName:String);
	Bezier2To(end:Coordinates, control:Coordinates, mode:Null<PathCoordinateMode>, smoothing:Null<SmoothingType>);
	Bezier3To(end:Coordinates, control1:Coordinates, control2:Coordinates, mode:Null<PathCoordinateMode>, smoothing:Null<SmoothingType>);
	Arc(radius:ReferenceableValue, angleDelta:ReferenceableValue);
	Close;
	MoveTo(target:Coordinates, mode:Null<PathCoordinateMode>);
	Spiral(radiusStart:ReferenceableValue, radiusEnd:ReferenceableValue, angleDelta:ReferenceableValue);
	Wave(amplitude:ReferenceableValue, wavelength:ReferenceableValue, count:ReferenceableValue);
}

@:nullSafety
typedef PathsDef = Map<String, Array<ParsedPaths>>;

typedef CurveSegmentDef = {
	var timeStart:ReferenceableValue;
	var timeEnd:ReferenceableValue;
	var easing:EasingType;
	var valueStart:ReferenceableValue;
	var valueEnd:ReferenceableValue;
};

typedef CurveDef = {
	var easing:Null<EasingType>;
	var points:Null<Array<ParticleCurvePoint>>;
	var segments:Null<Array<CurveSegmentDef>>;
};

@:nullSafety
typedef CurvesDef = Map<String, CurveDef>;

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
	var blendMode:Null<MacroBlendMode>;
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
	StepIterator(dx:ReferenceableValue, dy:ReferenceableValue, repeatCount:ReferenceableValue);
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
	#if !macro
	TSTile(tile:h2d.Tile); // Used for iterator-provided tiles (e.g., from stateanim iterator)
	#end
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

enum Atlas2Source {
	A2SFile(filename:ReferenceableValue);
	A2SSheet(sheetName:ReferenceableValue);
}

@:nullSafety
typedef Atlas2EntryDef = {
	var name:String;
	var x:Int;
	var y:Int;
	var w:Int;
	var h:Int;
	var ?offsetX:Null<Int>;
	var ?offsetY:Null<Int>;
	var ?origW:Null<Int>;
	var ?origH:Null<Int>;
	var ?split:Null<Array<Int>>;
	var ?index:Null<Int>;
}

@:nullSafety
typedef Atlas2Def = {
	var source:Atlas2Source;
	var entries:Array<Atlas2EntryDef>;
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

// ========== Data block types ==========

enum DataValueType {
	DVTInt;
	DVTFloat;
	DVTString;
	DVTBool;
	DVTRecord(recordName:String);
	DVTArray(elementType:DataValueType);
}

enum DataValue {
	DVInt(v:Int);
	DVFloat(v:Float);
	DVString(v:String);
	DVBool(v:Bool);
	DVArray(elements:Array<DataValue>);
	DVRecord(recordName:String, fields:Map<String, DataValue>);
}

typedef DataRecordDef = {
	var name:String;
	var fields:Array<{name:String, type:DataValueType, optional:Bool}>;
}

typedef DataFieldDef = {
	var name:String;
	var type:DataValueType;
	var value:DataValue;
}

typedef DataDef = {
	var records:Map<String, DataRecordDef>;
	var fields:Array<DataFieldDef>;
}

@:nullSafety
enum NodeType {
	FLOW(maxWidth:Null<ReferenceableValue>, maxHeight:Null<ReferenceableValue>, minWidth:Null<ReferenceableValue>, minHeight:Null<ReferenceableValue>,
		lineHeight:Null<ReferenceableValue>, colWidth:Null<ReferenceableValue>, layout:Null<MacroFlowLayout>,
		paddingTop:Null<ReferenceableValue>,paddingBottom:Null<ReferenceableValue>, paddingLeft:Null<ReferenceableValue>, paddingRight:Null<ReferenceableValue>,
		horizontalSpacing:Null<ReferenceableValue>, verticalSpacing:Null<ReferenceableValue>, debug:Bool, multiline:Bool,
		bgSheet:Null<ReferenceableValue>, bgTile:Null<ReferenceableValue>
		);
	BITMAP(tileSource:TileSource, hAlign:HorizontalAlign, vAlign:VerticalAlign);
	POINT;
	STATEANIM(filename:String, initialState:ReferenceableValue, selector:Map<String, ReferenceableValue>);
	STATEANIM_CONSTRUCT(initialState:ReferenceableValue, construct:Map<String, StateAnimConstruct>);
	PIXELS(shapes:Array<PixelShapes>);
	TEXT(textDef:TextDef);
	PROGRAMMABLE(isTileGroup:Bool, parameters:ParametersDefinitions, paramOrder:Array<String>);
	TILEGROUP;
	RELATIVE_LAYOUTS(layoutsDef:LayoutsDef);
	PATHS(paths:PathsDef);
	ANIMATED_PATH(animatedPathDef:AnimatedPathDef);
	CURVES(curves:CurvesDef);
	PARTICLES(particles:ParticlesDef);
	APPLY;
	LAYERS;
	MASK(width:ReferenceableValue, height:ReferenceableValue);
	REPEAT(varName:String, repeatType:RepeatType);
	REPEAT2D(varNameX:String, varNameY:String, repeatTypeX:RepeatType, repeatTypeY:RepeatType);
	REFERENCE(externalReference:Null<String>, programmableReference:String, parameters:Map<String, ReferenceableValue>);
	PLACEHOLDER(type:PlaceholderTypes, replacementSource:PlaceholderReplacementSource);
	NINEPATCH(sheet:String, tilename:String, width:ReferenceableValue, height:ReferenceableValue);
	INTERACTIVE(width:ReferenceableValue, height:ReferenceableValue, id:ReferenceableValue, debug:Bool,
		metadata:Null<Array<{key:ReferenceableValue, type:SettingValueType, value:ReferenceableValue}>>);
	PALETTE(paletteType:PaletteType);
	GRAPHICS(elements:Array<PositionedGraphicsElement>);
	AUTOTILE(autotileDef:AutotileDef);
	ATLAS2(atlas2Def:Atlas2Def);
	DATA(dataDef:DataDef);
	FINAL_VAR(name:String, value:ReferenceableValue);
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
	tint: Null<ReferenceableValue>,
	layer:Null<Int>,
	filter: Null<FilterType>,
	blendMode: Null<MacroBlendMode>,
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
	var imports:Map<String, Dynamic>;
}

#if !macro
class MultiAnimParser {
	public static final defaultLayoutNodeName = "#defaultLayout";
	public static final defaultPathNodeName = "#defaultPaths";
	public static final defaultCurveNodeName = "#defaultCurves";

	public static function parseFile(input:byte.ByteData, sourceName:String, resourceLoader:bh.base.ResourceLoader):MultiAnimResult {
		final content = input.readString(0, input.length);
		return MacroManimParser.parseFile(content, sourceName, resourceLoader);
	}

	public static function parseFileNoImports(input:byte.ByteData, sourceName:String):MultiAnimResult {
		final content = input.readString(0, input.length);
		return MacroManimParser.parseFile(content, sourceName, null);
	}

	// Static utility methods used by MultiAnimBuilder
	public static function tryStringToBool(val:String) {
		if (val == null) return null;
		return switch val.toLowerCase() {
			case "true"|"yes"|"1": true;
			case "false"|"no"|"0": false;
			default: null;
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
			final v:ResolvedIndexParameters = cast dynValue;
			return switch v {
				case Value(i): i;
				default: err('expected integer-ish in dynamicToInt as ParameterValue, got ${dynValue}');
			}
		}

		return err('expected integer-ish in dynamicToInt, got ${dynValue}');
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

	public static function dynamicValueToIndex(name:String, type:DefinitionType, value:Dynamic, err:String->Dynamic):ResolvedIndexParameters {
		final s:String = Std.isOfType(value, String) ? cast value : Std.string(value);
		return switch (type) {
			case PPTEnum(values):
				if (!values.contains(s)) err('enum "$name" does not contain value "$s"');
				Index(values.indexOf(s), s);
			case PPTRange(from, to):
				final n = Std.parseInt(s);
				if (n == null) err('expected integer for range default');
				Value(n);
			case PPTInt | PPTUnsignedInt:
				final n = Std.parseInt(s);
				if (n == null) err('expected integer for default');
				Value(n);
			case PPTFloat:
				final f = Std.parseFloat(s);
				if (Math.isNaN(f)) err('expected float for default');
				ValueF(f);
			case PPTBool:
				switch (s.toLowerCase()) {
					case "true" | "yes" | "1": Value(1);
					case "false" | "no" | "0": Value(0);
					default: err('invalid bool default: $s');
				}
			case PPTString: StringValue(s);
			case PPTColor:
				final c = tryStringToColor(s);
				if (c != null) Value(c) else Value(Std.parseInt(s));
			case PPTHexDirection | PPTGridDirection:
				final n = Std.parseInt(s);
				if (n == null) err('expected integer for default');
				Value(n);
			case PPTFlags(bits):
				final n = Std.parseInt(s);
				if (n == null) err('expected integer for default');
				Flag(n);
			case PPTArray:
				if (Std.isOfType(value, Array))
					ArrayString(cast value)
				else
					err('array default not supported in this context');
		}
	}

	public static function tryStringToColor(s:String):Null<Int> {
		return MacroManimParser.tryStringToColor(s);
	}
}
#end

// Dead code below removed — parsing is now handled by MacroManimParser
