package wt.multianim;

import h2d.HtmlText;
import wt.paths.AnimatedPath;
import wt.paths.AnimatedPath.AnimatePathCommands;
import hxd.res.Atlas;
import wt.paths.MultiAnimPaths.Path;
import wt.stateanim.AnimationSM;
import wt.base.FPoint;
import wt.base.Point;
import wt.ui.UIElement;
import h2d.TileGroup;
import wt.base.filters.ReplacePaletteShader;
import hxd.fs.LoadedBitmap;
import hxd.res.Image;
import wt.base.Palette;
import wt.base.filters.PixelOutline;
import h3d.pass.Blur;
import h2d.Layers;
import wt.multianim.layouts.MultiAnimLayouts;
import wt.base.MAObject;
import wt.multianim.CoordinateSystems;
import wt.base.PixelLine;
import h2d.Object;
import wt.multianim.MultiAnimParser;
import wt.base.ResourceLoader;
using wt.base.MapTools;
using StringTools;
using wt.base.ColorUtils;

@:nullSafety
@:allow(wt.multianim.BuilderResult) 
class Updatable {
	final updatables:Array<NamedBuildResult>;
	var lastObject:Null<h2d.Object> = null;
	function new(updatables) {
		if (updatables == null || updatables.length == 0) throw 'empty updatable';
		this.updatables = updatables;
	}

	public function setVisibility(visible:Bool) {
		for (type in updatables) {
			type.getBuiltHeapsObject().toh2dObject().visible = visible;
		}
	}

	public function updateText(newText, throwIfAnyFails = true) {
		for (v in updatables) {
			
			switch v.object {
				case HeapsText(t):
						t.text = newText;
				default: if (throwIfAnyFails) throw 'invalid updateText ${v.object}';
			}
		}
	}	
	
	public function updateTile(newTile:h2d.Tile, throwIfAnyFails = true) {
		for (v in updatables) {
			switch v.object {
				case HeapsBitmap(b): b.tile = newTile;
				default: if (throwIfAnyFails) throw 'invalid updateTile ${v.object}';
			}
			
		}
	}
	
	public function setObject(newObject:h2d.Object, throwIfFails = true) {
		if (updatables.length != 1) throw 'setObject needs exactly one updatable';
		if (lastObject == newObject) return; // nothing to do
		for (v in updatables) {
			
			if (lastObject != null) lastObject.remove();

			final parent = v.object.toh2dObject();
			parent.addChild(newObject);
		}
	}

	public function addObject(newObject:h2d.Object, throwIfFails = true) {
		if (updatables.length != 1) throw 'addObject needs exactly one updatable';
		
		for (v in updatables) {
			final parent = v.object.toh2dObject();
			parent.addChild(newObject);
		}
	}

	public function clearObjects() {
		for (v in updatables) {
			v.object.toh2dObject().removeChildren();
		}
	}

}


class BuilderResolvedSettings {
	var settings:ResolvedSettings;
	public function new(settings) {
		this.settings = settings;
	}
	public function getOrDefault(settingName:String, defaultString:String):String{
		if (settings == null) return defaultString;
		final r = settings[settingName];
		if (r == null) throw 'expected string setting ${settingName} to present was not';
		return r;
	}
	
	public function getStringOrException(settingName:String):String{
		if (settings == null) throw 'settings not found, was looking for $settingName';
		final r = settings[settingName];
		if (r == null) throw 'expected string setting ${settingName} to present but was not';
		return r;
		
	}

	
	public function getFloatOrException(settingName:String):Float {
		if (settings == null) throw 'settings not found, was looking for $settingName';
		var r = settings[settingName];
		if (r == null) throw 'expected float setting ${settingName} to present but was not';
		var f = Std.parseFloat(r);
	 	if (f != Math.NaN) return f;
		throw 'expected float setting ${settingName} to valid float number but was $r';
	}

	public function getFloatOrDefault(settingName:String, defaultValue:Float):Float {
		if (settings == null) throw 'settings not found, was looking for $settingName';
		var r = settings[settingName];
		if (r == null) return defaultValue;
		var f = Std.parseFloat(r);
	 	if (f != Math.NaN) return f;
		 throw 'expected float setting ${settingName} to valid float number but was $r';
	}
}


@:nullSafety
@:structInit
class BuilderResult {
	public var object:Object;
	public var name:String;
	public var names:Map<String, Array<NamedBuildResult>>;
	public var interactives:Array<MAObject>;
	public var layouts:Map<String, MultiAnimLayouts>;
	public var palettes:Map<String, Palette>;
	public var rootSettings:BuilderResolvedSettings;
	public var offset:wt.base.FPoint;
	public var gridCoordinateSystem:Null<GridCoordinateSystem>;
	public var hexCoordinateSystem:Null<HexCoordinateSystem>;

	public function getNodeSettings(elementName:String):ResolvedSettings {
		final results = names[name];
		if (results == null || results.length != 1) throw 'Could not get single node for name $name';
		final settings = results[0].settings;
		if (settings == null) throw 'no settings specified for $name';
		return settings;
	}

	public function getSingleItemByName(name:String):NamedBuildResult {
		var items = this.names[name];
		if (items == null) throw 'builder result name ${name} not found';
		if (items.length != 1) throw 'builder result name ${name} expected single item but got ${items.length}';
		return items[0];
	}

	public function getUpdatable(name) {
		final namesArray = names[name];
		if (namesArray == null) throw 'Name ${name} not found in BuilderResult';
		return new Updatable(namesArray);
		
	}
	
}
@:nullSafety
enum CallbackRequest {
	Name(name:String);	// called when used in expression
	NameWithIndex(name:String, index:Int); // called when used in expression
	Placeholder(name:String);		// called when used in placeholder
	PlaceholderWithIndex(name:String, index:Int); // when used in placeholder
}

enum CallbackResult {
	CBRInteger(val:Int);
	CBRFloat(val:Float);
	CBRString(val:String);
	CBRObject(val:h2d.Object);
	CBRNoResult; // for default behaviour, e.g. for example of PLACEHOLDER
}



 enum PlaceholderValues {
 	PVObject(obj:h2d.Object);
 	PVFactory(factoryMethod:ResolvedSettings->h2d.Object);
 }
@:nullSafety
typedef BuilderParameters = {
	var ?callback:BuilderCallbackFunction;
	var ?placeholderObjects:Map<String, PlaceholderValues>;
}

@:nullSafety
private enum InternalBuildMode {
	RootMode;
	ObjectMode(current:h2d.Object);
	LayersMode(current:h2d.Layers);
	TileGroupMode(tg:h2d.TileGroup);
}

@:nullSafety
typedef BuilderCallbackFunction = CallbackRequest->CallbackResult;

@:nullSafety
private typedef InternalBuilderResults = {
	names:Map<String, Array<NamedBuildResult>>,
	interactives:Array<MAObject>
}

@:nullSafety
private typedef StoredBuilderState = {
	indexedParams: Map<String, ResolvedIndexParameters>,
	builderParams:BuilderParameters,
	currentNode:Null<Node>
}


// @:nullSafety
@:allow(wt.multianim.layouts.MultiAnimLayouts)
@:allow(wt.paths.MultiAnimPaths)
@:allow(wt.paths.AnimatedPath)
@:allow(wt.multianim.MultiAnimParser)
class MultiAnimBuilder {
	
	final resourceLoader:wt.base.ResourceLoader;
	var multiParserResult:MultiAnimResult;
	
	var indexedParams: Map<String, ResolvedIndexParameters> = [];
	var builderParams:BuilderParameters = {};
	var currentNode:Null<Node> = null;
	var stateStack:Array<StoredBuilderState> = [];

	private function new(data, resourceLoader) {
		this.multiParserResult = data;
		this.resourceLoader = resourceLoader;
		
	}

	function popBuilderState() {
		
		final state = stateStack.pop();
		if (state == null) throw 'builder state stack is empty';

		this.indexedParams = state.indexedParams;
		this.builderParams = state.builderParams;
		this.currentNode = state.currentNode;
	}

	function pushBuilderState() {
		stateStack.push({
			indexedParams: this.indexedParams,
			builderParams: this.builderParams,
			currentNode: this.currentNode,

		});
		this.indexedParams = [];
		this.builderParams = {};
		this.currentNode = null;
	}

	public static function load(byteData, resourceLoader, sourceName) {
		
		var parsed = MultiAnimParser.parseFile(byteData, sourceName, resourceLoader);
		return new MultiAnimBuilder(parsed, resourceLoader);
	}

	function resolveAsArrayElement(v:ReferencableValue):Dynamic {
		switch v {
			case RVElementOfArray(arrayRef, indexRef):
				final arrayVal = indexedParams.get(arrayRef);
			
				switch arrayVal {
					case ArrayString(arrayVal): 
						var index = resolveAsInteger(indexRef);
						if (index < 0 || index >= arrayVal.length) throw 'index out of bounds ${index} for array ${arrayVal.toString()}';
						return arrayVal[index];
					case null: throw throw 'array reference ${arrayRef}[$indexRef] does not exist';
					default: throw 'element of array reference ${arrayRef}[$indexRef] is not an array but ${arrayRef}';
				}
			default: throw 'expected array element but got ${v}';
		}
	}
	function resolveAsArray(v:ReferencableValue):Dynamic {
		switch v {
			case RVArray(array):
				return [for(v in array) resolveAsString(v)];
			case RVArrayReference(refArr):
				final arrayVal = indexedParams.get(refArr);
				trace(indexedParams);
				switch arrayVal {
					case ArrayString(strArray): return strArray;
					default: throw 'array reference ${refArr} is not an array but ${arrayVal}';
				}
			default: throw 'expected array but got ${v}';
		}
	}

	


	function resolveAsColorInteger(v:ReferencableValue):Int {

		function getBuilderWithExternal(externalReference:String) {
			if (externalReference == null) return this;
			var builder = multiParserResult?.imports?.get(externalReference);
			if (builder == null) throw 'could not find builder for external reference ${externalReference}';
			return builder;
		}

		return switch v {
			case RVInteger(i): i;
			case RVColorXY(externalReference, name, x, y): 
				var builder = getBuilderWithExternal(externalReference);
				var palette = builder.getPalette(name);
				palette.getColor2D(resolveAsInteger(x), resolveAsInteger(y));
			case RVColor(externalReference, name, index):
				var builder = getBuilderWithExternal(externalReference);
				var palette = builder.getPalette(name);
				palette.getColorByIndex(resolveAsInteger(index));
			case RVReference(_): resolveAsInteger(v);

			default: throw 'expected color to resolve, got $v';
	
		}
	}

	function resolveRVFunction(functionType:ReferencableValueFunction):Int {
		final gridCoordinateSystem = MultiAnimParser.getGridCoordinateSystem(this.currentNode);
		if (gridCoordinateSystem == null) throw 'cannot resolve $functionType as there is no grid defined';
		
		return switch functionType {
			case RVFGridWidth: gridCoordinateSystem.spacingX;
			case RVFGridHeight:gridCoordinateSystem.spacingY;
		}
	}

	function resolveAsInteger(v:ReferencableValue) {
		function handleCallback(result, input:CallbackRequest, defaultValue) {
			return switch result {
				case CBRInteger(val): val;
				case CBRNoResult: 
					if (defaultValue != null) resolveAsInteger(defaultValue);
					else throw 'no default value for $input';
								
				case _: throw 'callback should return int but was ${result} for $input';

			}
		}

		return switch v {
			case RVElementOfArray(array, index): resolveAsArrayElement(v);
			case RVArray(refArray): throw 'RVArray not supported';
			case RVArrayReference(refArray): throw 'RVArrayReference not supported';
			case RVInteger(i): return i;
			case RVFloat(_)|RVString(_): throw 'should be an integer';
			case RVColorXY(_, _, _)|RVColor(_, _): resolveAsColorInteger(v);
			case RVReference(ref): 
				if (!indexedParams.exists(ref)) {
					throw 'reference ${ref} does not exist';
				}

				final val = indexedParams.get(ref);
				switch val {
					case Value(val): return val;
					case StringValue(s): stringToInt(s);
					case null: throw 'reference ${ref} is null';
					default: throw 'reference ${ref} is not a value but ${val}';
				}
			case RVParenthesis(e):	resolveAsInteger(e);
			case RVFunction(functionType): resolveRVFunction(functionType);
				

			case RVCallbacks(name, defaultValue):	
				final input = Name(resolveAsString(name));
				final result = builderParams.callback(input);
				return handleCallback(result, input, defaultValue);

			case RVCallbacksWithIndex(name, idx, defaultValue):
				final input = NameWithIndex(resolveAsString(name), resolveAsInteger(idx));
				final result = builderParams.callback(input);
				return handleCallback(result, input, defaultValue);				

			case EBinop(op, e1, e2):
						switch op {
							case OpAdd: resolveAsInteger(e1) + resolveAsInteger(e2);
							case OpMul: resolveAsInteger(e1) * resolveAsInteger(e2);
							case OpSub: resolveAsInteger(e1) - resolveAsInteger(e2);
							case OpDiv: Std.int(resolveAsInteger(e1) / resolveAsInteger(e2));
							case OpMod: Std.int(resolveAsInteger(e1) % resolveAsInteger(e2));
							case OpIntegerDiv: Std.int(resolveAsInteger(e1) / resolveAsInteger(e2));
						}
		}

	}

	function resolveAsNumber(v:ReferencableValue):Float {
		return switch v {
			case RVElementOfArray(array, index): resolveAsArrayElement(v);
			case RVArray(refArray): throw 'RVArray not supported';
			case RVArrayReference(refArray): throw 'RVArrayReference not supported';
			case RVInteger(i): i;
			case RVFloat(f): f;
			case RVString(_): throw 'should be an integer or float';
			case RVColorXY(_, _, _)|RVColor(_,_): throw 'reference is a color but needs to be float';
			case RVReference(ref): 
				if (!indexedParams.exists(ref)) throw 'reference ${ref} does not exist';

				final val = indexedParams.get(ref);
				switch val {
					case Value(val): return val;
					case ValueF(val): return val;
					case null: throw 'reference ${ref} is null';
					default: throw 'reference ${ref} is not a value but ${val}';
				}
			case RVParenthesis(e):	resolveAsNumber(e);
			case RVFunction(functionType): resolveRVFunction(functionType);
			case RVCallbacks(name, defaultValue):	
				final input = Name(resolveAsString(name));
				final result = builderParams.callback(input);

				switch result {
					case CBRInteger(val): cast(val, Float);
					case CBRString(val): throw 'callback should return number but was ${val}';
					case CBRFloat(val): val;
					case CBRObject(_): throw 'callback should return number but was CBRObject for $input';
					case CBRNoResult: resolveAsNumber(defaultValue);
					case null: throw 'callback should return number but was null for $input';
				}
			case RVCallbacksWithIndex(name, idx, defaultValue):
				final input = NameWithIndex(resolveAsString(name), resolveAsInteger(idx));
				final result = builderParams.callback(input);
				switch result {
					case CBRInteger(val): cast(val, Float);
					case CBRString(val): throw 'callback should return number but was ${result} for $input';
					case CBRFloat(val): val;
					case CBRNoResult: resolveAsNumber(defaultValue);
					case CBRObject(_): throw 'callback should return number but was CBRObject $result for $input';
					case null: throw 'callback should return number but was null';
	
				}


			case EBinop(op, e1, e2):
					switch op {
						case OpAdd: resolveAsNumber(e1) + resolveAsNumber(e2);
						case OpMul: resolveAsNumber(e1) * resolveAsNumber(e2);
						case OpSub: resolveAsNumber(e1) - resolveAsNumber(e2);
						case OpDiv: resolveAsNumber(e1) / resolveAsNumber(e2);
						case OpMod: resolveAsNumber(e1) % resolveAsNumber(e2);
						case OpIntegerDiv: Std.int(resolveAsInteger(e1) / resolveAsInteger(e2));
					}

		}
	}

	function resolveAsString(v:ReferencableValue):String {
		function handleCallback(result, input:CallbackRequest, defaultValue) {
			return switch result {
				case CBRInteger(val): '${val}';
				case CBRFloat(val): '${val}';
				case CBRString(val): val;
				case CBRObject(_): throw 'callback should return string but was CBRObject for $input';
				case CBRNoResult: 
					if (defaultValue != null) resolveAsString(defaultValue);
					else throw 'no default value for $input';
				case null: throw 'callback should return string but was null for $input';
			}
		}

		return switch v {
			case RVElementOfArray(array, index):
				resolveAsArrayElement(v);
			case RVArray(refArray): throw 'RVArray not supported';
			case RVArrayReference(refArray): throw 'RVArrayReference not supported';
			case RVInteger(i): return '${i}';
			case RVFloat(f): return '${f}';
			case RVString(s): return s;
			case RVColorXY(_, _, _)|RVColor(_, _):   
				var color = resolveAsColorInteger(v);
				'$color';

			case RVReference(ref): 
				if (!indexedParams.exists(ref)) throw 'reference ${ref} does not exist';

				final val:ResolvedIndexParameters = indexedParams.get(ref);
				switch val {
					case Value(val): return '${val}';
					case StringValue(s): return s;
					case Index(_, value): return value;
					default: throw 'invalid reference value ${ref}, expected string got ${val}';
				}
			case RVParenthesis(e): throw 'not supported ${v}';
			case RVFunction(functionType): '${resolveAsInteger(v)}';
			case RVCallbacks(name, defaultValue):	
				final input = Name(resolveAsString(name));
				final result = builderParams.callback(input);
				return handleCallback(result, input, defaultValue);
			case RVCallbacksWithIndex(name, idx, defaultValue):
				final input = NameWithIndex(resolveAsString(name), resolveAsInteger(idx));
				final result = builderParams.callback(input);

				return handleCallback(result, input, defaultValue);
			case EBinop(op, e1, e2): switch op {
				case OpAdd:
					return resolveAsString(e1) + resolveAsString(e2);
				default: throw 'op ${op} not supported on strings';
			}
		}
	}

	function generatePlaceholderBitmap(type:ResolvedGeneratedTileType) {
		
		return switch type {
			case Cross(w, h, color):
				var pl = new PixelLines(w, h);
		
				pl.filledRect(0, 0, w-1, h-1, 0xFF808080);
				pl.rect(0, 0, w-1, h-1, color);
				pl.line(0,0, w-1, h-1, color);
				pl.line(0,h-1, w, 0-1, color);
				pl.updateBitmap();
				pl.tile;
		
			case SolidColor(w, h, color):

				h2d.Tile.fromColor(color.addAlphaIfNotPresent(), w, h);
		}
	}

	function loadTileSource(tileSource):h2d.Tile {
		
		final tile = switch tileSource {
			case TSFile(filename): resourceLoader.loadTile(resolveAsString(filename));
			case TSSheet(sheet, name): loadTileImpl(sheet, resolveAsString(name)).tile;
			case TSSheetWithIndex(sheet, name, index): loadTileImpl(sheet, resolveAsString(name), resolveAsInteger(index)).tile;
			case TSGenerated(type):
				var  resolvedType:ResolvedGeneratedTileType = switch type {
					case Cross(width, height, color): Cross(resolveAsInteger(width), resolveAsInteger(height), resolveAsColorInteger(color));
					case SolidColor(width, height, color): SolidColor(resolveAsInteger(width), resolveAsInteger(height), resolveAsColorInteger(color));
				}
				
				resourceLoader.getOrCreatePlaceholder(resolvedType, (resolvedType)->generatePlaceholderBitmap(resolvedType));
				
				
		}
		
		if (tile == null) throw 'could not load tile $tileSource';
		return tile;
	}

	function createHtmlText(font) {
		final t =  new HtmlText(font);
		t.loadFont = (name) -> resourceLoader.loadFont(name);
		return t;

	}

	function isMatch(node:Node, indexedParams: Map<String, ResolvedIndexParameters>) {

		function match(condValue, currentValue) {
			switch condValue {
				case CoNot(condValue):
					return !match(condValue, currentValue);
				case CoEnums(a):
					switch currentValue {
						case Index(idx, v):
							if (!a.contains(v)) return false;
						case Value(val):
							if (!a.contains(Std.string(val))) return false;
						case StringValue(s):
							if (!a.contains(s)) return false;
						default: throw 'invalid param types ${currentValue}, ${condValue}';
					}
				case CoRange(fromInclusive, toInclusive):
					switch currentValue {
						
						case Value(val):
							if ((fromInclusive != null && val < fromInclusive) || (toInclusive != null && val > toInclusive)) return false;
						case ValueF(val):
							if ((fromInclusive != null && val < fromInclusive) || (toInclusive != null && val > toInclusive)) return false;
						default: throw 'invalid param types ${currentValue}, ${condValue}';									
					}

				case CoIndex(idx, value):
					switch currentValue {
						case Index(i, value): if (idx  != i) return false;
						case StringValue(s): if (s != value) return false;
						default: throw 'invalid param types ${currentValue}, ${condValue}';									

					}
				case CoValue(val):
					switch currentValue {

						case Value(iVal): if (val != iVal) return false;
						default: throw 'invalid param types ${currentValue}, ${condValue}';									

					}
				case CoFlag(f):
					switch currentValue {
						case Flag(i): if (f & i != f) return false;
						default: throw 'invalid param types ${currentValue}, ${condValue}';
						
					}
				case CoAny:
				case CoStringValue(s):
					switch currentValue {
						case Index(idx, value): if (value != s	) return false;
						case StringValue(sv): if (s != sv) return false;
						default: throw 'invalid param types ${currentValue}, ${condValue}';
					}
			}
			return true;
		}
		
		return switch node.conditionals {
			case Conditional(conditions, strict):
				for (key => value in conditions) {
					if (indexedParams[key] == null) return false;	// If there is no provided param for conditional, defaults are included in indexedParams
				}
				for (currentName => currentValue in indexedParams) {
					final condValue = conditions[currentName];
					if (condValue == null) if (strict) return false else continue;	// if there is no conditional matching the params, reject in strict mode
					if (!match(condValue, currentValue)) return false;
				}
				return true;
			case NoConditional: return true;
		}
	}
	function addPosition(obj:h2d.Object, x, y) {
		obj.x += x;
		obj.y += y;
	}
	function calculatePosition(position, gridCoordinateSystem:Null<GridCoordinateSystem>, hexCoordinateSystem:Null<HexCoordinateSystem>):FPoint {
		inline function returnPosition(x:Float, y:Float): FPoint {
			return new FPoint(x, y);
		}
		
		if (builderParams == null) builderParams = {callback:defaultCallback};
		else if (builderParams.callback == null) builderParams.callback = defaultCallback;
		var pos:FPoint = switch position {
			case ZERO:
				returnPosition(0,0);
			case OFFSET(x, y):
				returnPosition(resolveAsNumber(x), resolveAsNumber(y));
			case SELECTED_GRID_POSITION(gridX, gridY):
				if (gridCoordinateSystem == null) throw 'gridCoordinateSystem is null';
				gridCoordinateSystem.resolveAsGrid(resolveAsInteger(gridX), resolveAsInteger(gridY));
			case SELECTED_HEX_EDGE(direction, factor):
				if (hexCoordinateSystem == null) throw 'hexCoordinateSystem is null';
				hexCoordinateSystem.resolveAsHexEdge(resolveAsInteger(direction), resolveAsNumber(factor));
			case SELECTED_HEX_POSITION(hex):
				if (hexCoordinateSystem == null) throw 'hexCoordinateSystem is null';
				hexCoordinateSystem.resolveAsHexPosition(hex);
			case SELECTED_HEX_CORNER(count, factor):
				if (hexCoordinateSystem == null) throw 'hexCoordinateSystem is null';
				hexCoordinateSystem.resolveAsHexCorner(resolveAsInteger(count), resolveAsNumber(factor));
			case LAYOUT(layoutName, index):
				var idx = 0;
				if (index != null) idx = resolveAsInteger(index);
				var pt = getLayouts(builderParams).getPoint(layoutName, idx);
				returnPosition(pt.x, pt.y);
		}
		return pos;
	}


	function drawPixles(shapes:Array<PixelShapes>, gridCoordinateSystem, hexCoordinateSystem) {
		final bounds = new h2d.col.Bounds();
		for (s in shapes) {
			switch s {
				case LINE(line):
					final startPos = calculatePosition(line.start, gridCoordinateSystem, hexCoordinateSystem);
					bounds.addPos(startPos.x, startPos.y);
					final endPos = calculatePosition(line.end, gridCoordinateSystem, hexCoordinateSystem);
					bounds.addPos(endPos.x, endPos.y);
				case RECT(rect)|FILLED_RECT(rect):
					final startPos = calculatePosition(rect.start, gridCoordinateSystem, hexCoordinateSystem);
					bounds.addPos(startPos.x, startPos.y);
					bounds.addPos(startPos.x + resolveAsInteger(rect.width), startPos.y + resolveAsInteger(rect.height));


			}

		}
		var pl = new PixelLines(Std.int(Math.max(Math.ceil(bounds.width), 1))+1, Std.int(Math.max(Math.ceil(bounds.height), 1)+1));				
		final minX = Std.int(bounds.xMin);
		final minY = Std.int(bounds.yMin);

		for (s in shapes) {
			switch s {
				case LINE(line):
					final startPos = calculatePosition(line.start, gridCoordinateSystem, hexCoordinateSystem);
					final endPos = calculatePosition(line.end, gridCoordinateSystem, hexCoordinateSystem);
					pl.line(Std.int(startPos.x - minX), Std.int( startPos.y - minY), Std.int(endPos.x - minX), Std.int(endPos.y - minY), resolveAsColorInteger(line.color).addAlphaIfNotPresent());
				case RECT(rect):
					final start = calculatePosition(rect.start, gridCoordinateSystem, hexCoordinateSystem);

					pl.rect(Std.int(start.x - minX), Std.int(start.y - minY), resolveAsInteger(rect.width), resolveAsInteger(rect.height), resolveAsColorInteger(rect.color).addAlphaIfNotPresent());
				case FILLED_RECT(rect):
					final start = calculatePosition(rect.start, gridCoordinateSystem, hexCoordinateSystem);
					pl.filledRect(Std.int(start.x - minX), Std.int(start.y - minY), resolveAsInteger(rect.width), resolveAsInteger(rect.height), resolveAsColorInteger(rect.color).addAlphaIfNotPresent());
			}
		}
		pl.updateBitmap();
		return {pixelLines:pl, minX:minX, minY:minY};
	}

	function buildTileGroup(node:Node, tileGroup:h2d.TileGroup, currentPos:Point, gridCoordinateSystem:GridCoordinateSystem, hexCoordinateSystem:HexCoordinateSystem, builderParams:BuilderParameters):Void {

		if (isMatch(node, indexedParams) == false) return;
		this.currentNode = node;

		 var pos = calculatePosition(node.pos, gridCoordinateSystem, hexCoordinateSystem).toPoint();
		 currentPos.add(pos.x, pos.y);
		var skipChildren = false;
		var tileGroupTile = switch node.type {

			// case NINEPATCH(sheet, tilename, width, height):
			// 	var sg = load9Pathch(sheet, tilename);
				
			// 	sg.width = resolveAsNumber(width);
			// 	sg.height = resolveAsNumber(height);
			// 	sg.tileCenter = true;
			// 	sg.tileBorders = true;
			// 	sg.ignoreScale = false;
			// 	NinePatch(sg);
			case BITMAP(tileSource, hAlign, vAligh):
				var tile = loadTileSource(tileSource);
				var height = tile.height;
				var width = tile.width;
				var dh = switch vAligh {
					case Top: 0.;
					case Center: -(height * .5);
					case Bottom: -height;
				}
				var wh = switch hAlign {
					case Left: 0.;
					case Right: -width;
					case Center: -(width * .5);
				}

				tile = tile.sub(0, 0, width, height, wh, dh);
				tile;
			case POINT: 
				null;
			case REPEAT(varName, repeatType):
				// trace('repeat $varName $repeatType ${node.pos}');
				var dx = 0;
				var dy = 0;
				var repeatCount = 0;
				var iterator = null;
				var arrayIterator:Array<String> = [];
				
				switch repeatType {
					case GridIterator(dirX, dirY, repeats):
						repeatCount = resolveAsInteger(repeats);
						dx = dirX == null ? 0 : resolveAsInteger(dirX);
						dy = dirY == null ? 0 : resolveAsInteger(dirY);					
					case LayoutIterator(layoutName):
						 final l = getLayouts();
						 repeatCount = l.getLayoutSequenceLengthByLayoutName(layoutName);
						 iterator = l.getIterator(layoutName);
					case ArrayIterator(variableName, arrayName):
						arrayIterator = resolveAsArray(RVArrayReference(arrayName));
						repeatCount = arrayIterator.length;
				}

				if (indexedParams.exists(node.updatableName.getNameString())) throw 'cannot use repeatable index param "$varName" as it is already defined';
				for (count in 0...repeatCount) {
						final gridCoordinateSystem = MultiAnimParser.getGridCoordinateSystem(node);
						final hexCoordinateSystem = MultiAnimParser.getHexCoordinateSystem(node);
						for (childNode in node.children) {
				
							indexedParams.set(varName, Value(count));
							//var repeaterPos = calculatePosition(node.pos, gridCoordinateSystem, hexCoordinateSystem).toPoint();
							
							var iterPos = currentPos.clone();
							switch repeatType {
								case GridIterator(_, _, _):
									iterPos.add(dx * count, dy * count);
								case LayoutIterator(_):
									var pt = iterator.next();
									iterPos.add(cast pt.x, cast pt.y);
								case ArrayIterator(valueVariableName, array):	
									indexedParams.set(valueVariableName, StringValue(arrayIterator[count]));
									trace('$count = arrayIterator[count] ${arrayIterator[count]}');
							}
							buildTileGroup(childNode, tileGroup, iterPos, gridCoordinateSystem, hexCoordinateSystem, builderParams);
						}
				}
				indexedParams.remove(varName);
				skipChildren = true;
				null;
			case PIXELS(shapes):
				final pixelsResult = drawPixles(shapes, gridCoordinateSystem, hexCoordinateSystem);
				currentPos.add(pixelsResult.minX, pixelsResult.minY);
				pixelsResult.pixelLines.tile;
			default: throw 'unsupported node ${node.uniqueNodeName} ${node.type} in tileGroup mode';
		}
		
		addToTileGroup(node,currentPos, tileGroupTile, tileGroup);


		if (!skipChildren) { // for repeatable, as children were already processed
		
			for (childNode in node.children) {
				buildTileGroup(childNode, tileGroup, currentPos.clone(), MultiAnimParser.getGridCoordinateSystem(childNode), MultiAnimParser.getHexCoordinateSystem(childNode), builderParams);
			}
		}
	}

	function addToTileGroup(node:Node, currentPos:Point, tileGroupTile:h2d.Tile, tileGroup:h2d.TileGroup) {


		if (tileGroupTile != null) {
			final scale = node.scale == null ? 1.0 : resolveAsNumber(node.scale);
			tileGroup.setDefaultColor(0xFFFFFF,  node.alpha != null ? resolveAsNumber(node.alpha): 1.0);
			if (node.filter != null && node.filter != FilterNone) throw 'groupTile does not support filters for ${node.type}';
			if (node.blendMode != null && node.blendMode != Alpha) throw 'groupTile does not support blendMode other than Alpha for ${node.type}';
			tileGroup.addTransform(currentPos.x, currentPos.y,  scale, scale, 0, tileGroupTile);
			
		}

	}


	function build(node:Node, buildMode:InternalBuildMode, gridCoordinateSystem:GridCoordinateSystem, hexCoordinateSystem:HexCoordinateSystem, internalResults:InternalBuilderResults, builderParams:BuilderParameters):h2d.Object {

		if (isMatch(node, indexedParams) == false) return null;
		this.currentNode = node;
		var skipChildren = false;
		var layersParent:Null<h2d.Layers> = null;
		

		var selectedBuildMode:Null<InternalBuildMode> = null;
		var current = switch buildMode {
			case RootMode: null;
			case ObjectMode(current): 
				current;
			case LayersMode(current): current;
				layersParent = current;
				current;
			case TileGroupMode(tg): 
				buildTileGroup(node, tg, new Point(0,0), gridCoordinateSystem, hexCoordinateSystem, builderParams);
				return null;
		}
		
		function addChild(toAdd:h2d.Object) {
			
			// TODO: handle UIElementCustomAddToLayer
			if ( node.layer != -1) {
				if (layersParent != null) layersParent.add(toAdd, node.layer);
				else throw 'No layers parent for ${node.uniqueNodeName}-${node.type}';
			}
			else if (current != null) current.addChild(toAdd);
			// else do not add as this is root node
		}
		
		final builtObject:BuiltHeapsComponent = switch node.type {
			case FLOW(maxWidth, maxHeight, minWidth, minHeight, lineHeight, colWidth, layout, paddingTop, paddingBottom, paddingLeft, paddingRight, horizontalSpacing, verticalSpacing, debug):
				var f = new h2d.Flow();
				
				if (maxWidth != null) f.maxWidth = resolveAsInteger(maxWidth);
				if (maxHeight != null) f.maxHeight = resolveAsInteger(maxHeight);
				if (minWidth != null) f.minWidth = resolveAsInteger(minWidth);
				if (minHeight != null) f.minHeight = resolveAsInteger(minHeight);

				if (lineHeight != null) f.lineHeight = resolveAsInteger(lineHeight);
				if (colWidth != null) f.colWidth = resolveAsInteger(colWidth);
				if (layout != null) f.layout = layout;
				
				if (paddingTop != null) f.paddingTop = resolveAsInteger(paddingTop);
				if (paddingBottom != null) f.paddingBottom = resolveAsInteger(paddingBottom);
				if (paddingLeft != null) f.paddingLeft = resolveAsInteger(paddingLeft);
				if (paddingRight != null) f.paddingRight = resolveAsInteger(paddingRight);
				
				if (horizontalSpacing != null) f.horizontalSpacing = resolveAsInteger(horizontalSpacing);
				if (verticalSpacing != null) f.verticalSpacing = resolveAsInteger(verticalSpacing);
				
				f.debug = debug;
				f.overflow = Limit;
				
				HeapsFlow(f);
			case LAYERS:

				final l = new Layers(current);
				selectedBuildMode = LayersMode(l);
				HeapsLayers(l);
			case NINEPATCH(sheet, tilename, width, height):
				var sg = load9Pathch(sheet, tilename);
				
				sg.width = resolveAsNumber(width);
				sg.height = resolveAsNumber(height);
				sg.tileCenter = true;
				sg.tileBorders = true;
				sg.ignoreScale = false;
				NinePatch(sg);
			case BITMAP(tileSource, hAlign, vAligh):
				var tile = loadTileSource(tileSource);


				var height = tile.height;
				var width = tile.width;
				var dh = switch vAligh {
					case Top: 0.;
					case Center: -(height * .5);
					case Bottom: -height;
				}
				var wh = switch hAlign {
					case Left: 0.;
					case Right: -width;
					case Center: -(width * .5);
				}

				tile = tile.sub(0, 0, width, height, wh, dh);
				var b = new h2d.Bitmap(tile);
				HeapsBitmap(b);
			case TEXT(textDef):

				
				final font = resourceLoader.loadFont(resolveAsString(textDef.fontName));
				var t = if (textDef.isHtml) {
					createHtmlText(font);
				} else {
					new h2d.Text(font);
				}
				
				t.textAlign = switch textDef.halign {
					case null: Left;
					case Left: Left;
					case Right: Right;
					case Center: Center;
				}
				if (textDef.textAlignWidth != null) {
					t.maxWidth = textDef.textAlignWidth;
				} else {
					if (gridCoordinateSystem != null) t.maxWidth = gridCoordinateSystem.spacingX;
				}
				
				t.letterSpacing = textDef.letterSpacing;
				t.lineSpacing = textDef.lineSpacing;
				t.lineBreak = textDef.lineBreak;
				if (textDef.dropShadowXY != null) {
					t.dropShadow = {
						dx: textDef.dropShadowXY.x,
						dy: textDef.dropShadowXY.y,
						color: textDef.dropShadowColor,
						alpha: textDef.dropShadowAlpha,
					};
				}
				
				t.textColor = resolveAsColorInteger(textDef.color);
				t.text = resolveAsString(textDef.text);
				
				
				
				HeapsText(t);
			// case HTMLTEXT(fontname, textRef, color, align, textAlignWidth):
			// 	final font = resourceLoader.loadFont(resolveAsString(fontname));
			// 	var t = new h2d.HtmlText(font);
			// 	t.loadFont = x->resourceLoader.loadFont(x);
			// 	t.loadImage = x->resourceLoader.loadTile(x);
				
			// 	t.text = resolveAsString(textRef);
			// 	t.textColor = resolveAsColorInteger(color);
				
			// 	t.textAlign = switch align {
			// 		case null: Left;
			// 		case Left: Left;
			// 		case Right: Right;
			// 		case Center: Center;
			// 	}
			// 	if (textAlignWidth != null) t.maxWidth = textAlignWidth;
			// 	HeapsText(t);

			case RELATIVE_LAYOUTS(_): throw 'layouts not allowed as non-root node';
			case ANIMATED_PATH(_): throw 'animatedPath not allowed as non-root node';
			case PATHS(_): throw 'paths not allowed as non-root node';
			case PARTICLES(particlesDef): 
				Particles(createParticleImpl(particlesDef, node.uniqueNodeName));
			case PALETTE(_): throw 'palette not allowed as non-root node';

			case PLACEHOLDER(type, source):

				var settings = resolveSettings(node);

				function getH2dObj(result:CallbackResult):Null<h2d.Object> {
					return switch result {
						case CBRObject(val): val;
						case CBRNoResult: null;
						default: throw 'expected h2d.object but got $result';
						case null: null;
					}
				}
				var callbackResultH2dObject:Null<h2d.Object> = switch source {
					case PRSCallback(callbackName): 
						getH2dObj(builderParams.callback(Placeholder(resolveAsString(callbackName))));
					case PRSCallbackWithIndex(callbackName, index):
						getH2dObj(builderParams.callback(PlaceholderWithIndex(resolveAsString(callbackName), resolveAsInteger(index))));
					case PRSBuilderParameterSource(callbackName):
						if (builderParams.placeholderObjects == null) null;
						else {
							var param = builderParams.placeholderObjects.get(resolveAsString(callbackName));
							switch param {
								case null: null;
								case PVObject(obj): obj;
								case PVFactory(factoryMethod): 
									var res = factoryMethod(settings);
									// trace('FACTORY', settings, res, type, source);
									res;
							}
						}
				}
				if (callbackResultH2dObject == null) {
					switch type {
						case PHTileSource(source):
							final tile = loadTileSource(source);
							HeapsBitmap(new h2d.Bitmap(tile));
						case PHNothing: HeapsObject(new h2d.Object());
						case PHError: throw 'placeholder ${node.updatableName}, type ${node.type} configured in error mode, no input from $source';
					}
					
					
				} else {
					HeapsObject(callbackResultH2dObject);
				}
				
		
				
			case REFERENCE(externalReference, reference, parameters):
				
				var builder = if (externalReference != null) {
					var builder = multiParserResult?.imports?.get(externalReference);
					if (builder == null) throw 'could not find builder for external reference ${externalReference}';
					builder;
				} else this;
				
				trace('build reference ${reference} with parameters ${parameters} and builderParams ${builderParams} and indexedParams ${indexedParams}');

				var result = builder.buildWithParameters(reference, parameters, builderParams, indexedParams);
				var object = result?.object;
				if (object == null) throw 'could not build placeholder reference ${reference}';
				object.setPosition(result.offset.x, result.offset.y);
				HeapsObject(object);
			
			case POINT:
				HeapsObject(new h2d.Object());
			case STATEANIM(filename, initialState, selectorReferences):
				var selector = [for (k=>v in selectorReferences) k => resolveAsString(v)];
				var animSM = resourceLoader.createAnimSM(filename, selector);
				animSM.addCommand(SwitchState(resolveAsString(initialState)), ExecuteNow);

				StateAnim(animSM);
			case STATEANIM_CONSTRUCT(initialState, construct):
				var animSM = new AnimationSM([]);
				for (key => value in construct) {
					switch value {
						case IndexedSheet(sheet, animName, fps, loop, center):
							final loadedSheet = resourceLoader.loadSheet2(sheet);
							final anim = loadedSheet.getAnim(resolveAsString(animName));
							if (center) {
							for (i in 0...anim.length) {
									anim[i] = anim[i].cloneWithNewTile(anim[i].tile.center());
								}
							}
							
							
							var astates = [for (a in anim) AF_FRAME(a.cloneWithDuration(1.0/resolveAsNumber(fps)))];
							if (loop) astates.push(AF_LOOP(0, FOREVER));

							animSM.addAnimationState(key, astates, []);
					}
				
				}
				final initialStateResolved = resolveAsString(initialState);
				if (animSM.animationStates.exists(initialStateResolved) == false) throw 'initialState ${initialStateResolved} does not exist in constructed stateanim';

				animSM.addCommand(SwitchState(initialStateResolved), ExecuteNow);

				StateAnim(animSM);
			case REPEAT(varName, repeatType):
				
				var object = new h2d.Object();
				var dx = 0;
				var dy = 0;
				var repeatCount = 0;
				var iterator = null;
				var arrayIterator:Array<String> = [];

				switch repeatType {
					case GridIterator(dirX, dirY, repeats):
						repeatCount = resolveAsInteger(repeats);
						dx = dirX == null ? 0 : resolveAsInteger(dirX);
						dy = dirY == null ? 0 : resolveAsInteger(dirY);
					case LayoutIterator(layoutName):
						 final l = getLayouts();
						 repeatCount = l.getLayoutSequenceLengthByLayoutName(layoutName);
						 iterator = l.getIterator(layoutName);
					case ArrayIterator(variableName, arrayName):
						arrayIterator = resolveAsArray(RVArrayReference(arrayName));
						repeatCount = arrayIterator.length;
				}

				if (indexedParams.exists(node.updatableName.getNameString())) throw 'cannot use repeatable index param "$varName" as it is already defined';
				for (count in 0...repeatCount) {
						final gridCoordinateSystem = MultiAnimParser.getGridCoordinateSystem(node);
						final hexCoordinateSystem = MultiAnimParser.getHexCoordinateSystem(node);
						for (childNode in node.children) {
				
							indexedParams.set(varName, Value(count));
							switch repeatType {
								case ArrayIterator(valueVariableName, arrayName):
									indexedParams.set(valueVariableName, StringValue(arrayIterator[count]));
								default:
							}

							var obj = build(childNode, ObjectMode(object), gridCoordinateSystem, hexCoordinateSystem, internalResults, builderParams);
							if (obj == null) continue;
							switch repeatType {
								case GridIterator(_, _, _):
									addPosition(obj, dx * count, dy * count);
								case LayoutIterator(_):
									var pt = iterator.next();
									addPosition(obj, pt.x, pt.y);
								case ArrayIterator(valueVariableName, array):	
									
									
							}
							
						}
						
				}
				
				indexedParams.remove(varName);
				skipChildren = true;
				HeapsObject(object);
		

				
				
			case APPLY: 
				if (current == null) throw 'apply not allowed as root node';
				var pos = calculatePosition(node.pos, MultiAnimParser.getGridCoordinateSystem(node), MultiAnimParser.getHexCoordinateSystem(node));
				addPosition(current, pos.x, pos.y);
				applyExtendedFormProperties(current, node);
				return null;

			case PROGRAMMABLE(_, _):
				throw 'invalid state, programmable should not be build';

			case PIXELS(shapes):

				final pixelsResult = drawPixles(shapes, gridCoordinateSystem, hexCoordinateSystem);
				pixelsResult.pixelLines.setPosition(pixelsResult.minX, pixelsResult.minY);
				Pixels(pixelsResult.pixelLines);
			case INTERACTIVE(width, height, id, debug):

				var obj = new MAObject(MAInteractive(resolveAsInteger(width), resolveAsInteger(height), resolveAsString(id)), debug);
				internalResults.interactives.push(obj);
				HeapsObject(obj);
				
			case TILEGROUP:
				final tg = new TileGroup();
				selectedBuildMode = TileGroupMode(tg);
				HeapsObject(tg);
		}
		final updatableName = node.updatableName;
		
		final object = builtObject.toh2dObject();
		addChild(object);
		object.name = node.uniqueNodeName;
//		trace(object.name);

		
		final n = updatableName.getNameString();
		if (n != null) {
			
			final names = internalResults.names;
			if (names.exists(n)) names[n].push(toNamedResult(updatableName, builtObject, node));
			else names[n] = [toNamedResult(updatableName, builtObject, node)];
		}

		// addPosition is used instead of setPosition as to not overwrite existing offsets (e.g. pixellines)
		

		var pos = calculatePosition(node.pos, MultiAnimParser.getGridCoordinateSystem(node), MultiAnimParser.getHexCoordinateSystem(node));
		addPosition(object, pos.x, pos.y);
		applyExtendedFormProperties(object, node);
		
		if (selectedBuildMode == null) selectedBuildMode = ObjectMode(object);

		if (!skipChildren) { // for repeatable, as children were already processed
			for (childNode in node.children) {
				build(childNode, selectedBuildMode, MultiAnimParser.getGridCoordinateSystem(childNode), MultiAnimParser.getHexCoordinateSystem(childNode), internalResults, builderParams);
			}
		}
		return object;
	}

	function resolveSettings(node:Node):ResolvedSettings {
		var currentSettings:Null<Map<String, ReferencableValue>> = null;
		var current = node;
		while(current != null) {
			if (current.settings != null) {
				if (currentSettings == null) currentSettings = current.settings;
				else {
					for (key => value in current.settings) {
						if (!currentSettings.exists(key)) currentSettings[key] = value;
					}
				}
				
			}
			current = current.parent;
		}
		
		
		if (currentSettings != null) {
			final retSettings:ResolvedSettings = [];
			for (key => value in currentSettings) {
				retSettings[key] = resolveAsString(value);
			}
			return retSettings;
	
		} else return null;

	}

	function toNamedResult(updatableNameType:UpdatableNameType, obj:BuiltHeapsComponent, node:Node):NamedBuildResult {
	
		
		return {
			type: updatableNameType,
			object: obj,
			settings: resolveSettings(node),
			hexCoordinateSystem: MultiAnimParser.getHexCoordinateSystem(node),
			gridCoordinateSystem: MultiAnimParser.getGridCoordinateSystem(node)
		}
	}

	function applyExtendedFormProperties(object:h2d.Object, node:Node) {
		if (node.scale != null) object.setScale(resolveAsNumber(node.scale));
		if (node.alpha != null) object.alpha = resolveAsNumber(node.alpha);
		if (node.blendMode != null) object.blendMode = node.blendMode;
		if (node.filter != null) object.filter = buildFilter(node.filter);
		
	}

	function resolveColorList(colors:Array<ReferencableValue>) {
		return [for (value in colors) resolveAsColorInteger(value)];
	}

	function buildFilter(type:FilterType):h2d.filter.Filter {
		return switch type {
			case FilterNone: null;
			case FilterGroup(filters):
				var ret = new h2d.filter.Group();
				for (f in filters) ret.add(buildFilter(f));
				ret;
			case FilterOutline(size, color): new h2d.filter.Outline(size, color);
			case FilterPaletteReplace(paletteName, sourceRow, replacementRow):
				var palette = getPalette(paletteName);
				var srcRow = resolveAsInteger(sourceRow);
				var dstRow = resolveAsInteger(replacementRow);
				ReplacePaletteShader.createAsPaletteFilter(palette, srcRow, dstRow);
				
			case FilterColorListReplace(sourceColors, replacementColors): 
				
				ReplacePaletteShader.createAsColorsFilter(resolveColorList(sourceColors), resolveColorList(replacementColors));
			case FilterSaturate(v):
				var m = new h3d.Matrix();
				m.identity();
				m.colorSaturate(v);
				new h2d.filter.ColorMatrix(m);
			case FilterBrightness(v):
				var m = new h3d.Matrix();
				m.identity();
				m.colorLightness(v);

				new h2d.filter.ColorMatrix(m);
			case FilterGlow(color, alpha, radius, gain, quality, smoothColor, knockout):
				final f = new h2d.filter.Glow(color, alpha, radius, gain, quality, smoothColor);
				f.knockout = knockout;
				f;
			case FilterBlur(radius, gain, quality, linear):
				new h2d.filter.Blur(radius, gain, quality, linear);
			case FilterDropShadow(distance, angle, color, alpha, radius, gain, quality, smoothColor):
				new h2d.filter.DropShadow(distance, angle, color, alpha, radius, gain, quality, smoothColor);
			case FilterPixelOutline(mode, smoothColor):
				new PixelOutline(mode, smoothColor);
		}
	}


	
	function stringToInt(n) {
		var i = Std.parseInt(n);
		if (i != null) return i;
		return throw 'expected integer, got ${n}';
}


	public function hasMultiAnimWithName(name) {
		return multiParserResult.nodes.exists(name);
	}

	public dynamic function defaultCallback(input:CallbackRequest):CallbackResult {
		return CBRNoResult;
	}

	function getProgrammableParameterDefinitions(node:Node, throwIfNotProgrammable = false):ParametersDefinitions {
		
		 switch node.type {
			case PROGRAMMABLE(_, d): return d;
			default: 
				if (throwIfNotProgrammable) throw 'buildWithParameters require programmable node, was ${node.type}';
				else return [];
		}
		return [];
	}


	function startBuild(name:String, rootNode:Node, gridCoordinateSystem:GridCoordinateSystem, hexCoordinateSystem:HexCoordinateSystem, builderParams:BuilderParameters):BuilderResult {

		var isProgrammable = false;
		var isTileGroup = false;
		switch rootNode.type {
			case PROGRAMMABLE(isTG, _):
				isProgrammable = true;
				isTileGroup = isTG;
			default: false;
		};
	
		var retRoot:h2d.Object;
		final internalResults:InternalBuilderResults = {
			names:[],
			interactives: [],
		}

		if (isTileGroup) {
			var root = new TileGroup();
			retRoot = root;
			this.currentNode = rootNode;
			
			root.setPosition(0,0);
			applyExtendedFormProperties(root, rootNode);
			
			final pos = calculatePosition(rootNode.pos, gridCoordinateSystem, hexCoordinateSystem);
			addPosition(root, pos.x, pos.y);
	
			for (child in rootNode.children) {
				buildTileGroup(child, root, new Point(0,0), gridCoordinateSystem, hexCoordinateSystem, builderParams);
				
			}

		}
		else if (isProgrammable) {
			final root = new h2d.Layers();
			retRoot = root;
			this.currentNode = rootNode;
			root.setPosition(0,0);
			applyExtendedFormProperties(root, rootNode);
			
			final pos = calculatePosition(rootNode.pos, gridCoordinateSystem, hexCoordinateSystem);
			addPosition(root, pos.x, pos.y);

			for (child in rootNode.children) {
				build(child, LayersMode(root),  gridCoordinateSystem, hexCoordinateSystem, internalResults, builderParams);
			}
		} else {	// non-programmable
			final root = build(rootNode, RootMode,  gridCoordinateSystem, hexCoordinateSystem, internalResults, builderParams);
			retRoot = root;
			this.currentNode = rootNode;
			root.setPosition(0,0);
			applyExtendedFormProperties(root, rootNode);
			
			final pos = calculatePosition(rootNode.pos, gridCoordinateSystem, hexCoordinateSystem);
			addPosition(root, pos.x, pos.y);

			for (child in rootNode.children) {
				build(child, ObjectMode(root),  gridCoordinateSystem, hexCoordinateSystem, internalResults, builderParams);
			}

		}
		
		return {
			object: retRoot,
			names: internalResults.names,
			name: name,
			interactives: internalResults.interactives,
			layouts: [],
			palettes: [],
			rootSettings: new BuilderResolvedSettings(resolveSettings(rootNode)),
			offset: new wt.base.FPoint(retRoot.x, retRoot.y),
			hexCoordinateSystem: hexCoordinateSystem,
			gridCoordinateSystem: gridCoordinateSystem
		};
	}

	function getPalette(name:String) {
		return buildPalettes(name);
	}

	function buildPalettes(name:String):Palette {
		var node = multiParserResult?.nodes.get(name);
		if (node == null) throw 'could not get palette node #${name}';
		return switch node.type {
			case PALETTE(paletteType):
				return switch paletteType {
					case PaletteColors(colors): new Palette(resolveColorList(colors));
					case PaletteColors2D(colors, width): new Palette(resolveColorList(colors));
					case PaletteImageFile(filename):
						var filenameResolved = resolveAsString(filename);
						var res = resourceLoader.loadHXDResource(filenameResolved);
						if (res == null) throw 'could not load palette image $filename';
						var pixels = res.toImage().getPixels();
						var pixelArray = pixels.toVector().toArray();
						new Palette(pixelArray, pixels.width);
					}
			default: throw '$name has to be palette';
		}
	}

	function createParticleImpl(particlesDef, name) {
		var particles = new wt.base.Particles();
		final tiles = Lambda.map(particlesDef.tiles, x->loadTileSource(x));
		var group = new wt.base.Particles.ParticleGroup(name, particles, tiles);

		if (particlesDef.count != null) group.nparts = resolveAsInteger(particlesDef.count);
		if (particlesDef.emitDelay != null) group.emitDelay = resolveAsNumber(particlesDef.emitDelay);
		if (particlesDef.emitSync != null) group.emitSync = resolveAsNumber(particlesDef.emitSync);
		if (particlesDef.maxLife != null) group.life = resolveAsNumber(particlesDef.maxLife);
		if (particlesDef.lifeRandom != null) group.lifeRand = resolveAsNumber(particlesDef.lifeRandom);
		if (particlesDef.size != null) group.size = resolveAsNumber(particlesDef.size);
		if (particlesDef.sizeRandom != null) group.sizeRand = resolveAsNumber(particlesDef.sizeRandom);
		if (particlesDef.speed != null) group.speed = resolveAsNumber(particlesDef.speed);
		if (particlesDef.speedRandom != null) group.speedRand = resolveAsNumber(particlesDef.speedRandom);
		if (particlesDef.speedIncrease != null) group.speedIncr = resolveAsNumber(particlesDef.speedIncrease);
		if (particlesDef.gravity != null) group.gravity = resolveAsNumber(particlesDef.gravity);
		if (particlesDef.gravityAngle != null) group.gravityAngle = hxd.Math.degToRad(resolveAsNumber(particlesDef.gravityAngle));

		if (particlesDef.fadeIn != null) {
			final f = resolveAsNumber(particlesDef.fadeIn);
			if (f < 0 || f > 1.0) throw 'fadeIn must be between 0 and 1';
			group.fadeIn = f;
		}
		if (particlesDef.fadeOut != null) {
			final f = resolveAsNumber(particlesDef.fadeOut);
			if (f < 0 || f > 1.0) throw 'fadeOut must be between 0 and 1';
			group.fadeOut = resolveAsNumber(particlesDef.fadeOut);
		}
		if (particlesDef.fadePower != null) group.fadePower = resolveAsNumber(particlesDef.fadePower);
		if (particlesDef.blendMode != null) group.blendMode = particlesDef.blendMode;
		if (particlesDef.loop != null) group.emitLoop = particlesDef.loop; 
		if (particlesDef.relative != null) group.isRelative = particlesDef.relative; 

		if (particlesDef.rotationInitial != null) group.rotInit = hxd.Math.degToRad(resolveAsNumber(particlesDef.rotationInitial));
		if (particlesDef.rotationSpeed != null) group.rotSpeed = hxd.Math.degToRad(resolveAsNumber(particlesDef.rotationSpeed));
		if (particlesDef.rotationSpeedRandom != null) group.rotSpeedRand = hxd.Math.degToRad(resolveAsNumber(particlesDef.rotationSpeedRandom));
		if (particlesDef.rotateAuto != null) group.rotAuto = particlesDef.rotateAuto;

		 
		switch particlesDef.emit {
			case Point(emitDistance,  emitDistanceRandom):
				group.emitMode = Point(resolveAsNumber(emitDistance), resolveAsNumber(emitDistanceRandom));
			case Cone(emitDistance, emitDistanceRandom, emitConeAngle, emitConeAngleRandom):
				group.emitMode = Cone(resolveAsNumber(emitDistance), resolveAsNumber(emitDistanceRandom), hxd.Math.degToRad(resolveAsNumber(emitConeAngle)), hxd.Math.degToRad(resolveAsNumber(emitConeAngleRandom)));
			case Box(width, height, emitConeAngle, emitConeAngleRandom):
				group.emitMode = Box(resolveAsNumber(width), resolveAsNumber(height), hxd.Math.degToRad(resolveAsNumber(emitConeAngle)), hxd.Math.degToRad(resolveAsNumber(emitConeAngleRandom)));
		}


		
		particles.addGroup(group);
		return particles;
	}

	public function createParticles(name:String,  ?builderParams:BuilderParameters):wt.base.Particles {
		var node = multiParserResult?.nodes.get(name);
		if (node == null) throw 'could not get particles node #${name}';
		switch node.type {
			case PARTICLES(particlesDef):
				return createParticleImpl(particlesDef, node.uniqueNodeName);

			default: throw '$name has to be particles';
		}
	}

	public function createAnimatedPath(name:String, path:Path, initialSpeed:Float, positionMode:AnimatedPathPositionMode, object:BuiltHeapsComponent) {
		var node = multiParserResult?.nodes.get(name);
		if (node == null) throw 'could not get animatedPath node #${name}';
		switch node.type {
			case ANIMATED_PATH(pathDef):
				var retVal = new wt.paths.AnimatedPath(path, initialSpeed, object, positionMode, this); 
				for (action in pathDef) {
					var atRate = switch action.at {
						case Rate(r): resolveAsNumber(r);
						case Checkpoint(name):
							path.getCheckpoint(name);
					}
					var resolvedAction:AnimatePathCommands = switch action.action {
						case ChangeSpeed(speed): ChangeSpeed(resolveAsNumber(speed));
						case Event(eventName): Event(Event(eventName));
						case AttachParticles(particlesName, particlesTemplate, particlesDef):
							AttachParticles(particlesName, particlesDef);
						case RemoveParticles(particlesName): RemoveParticles(particlesName);
						case ChangeAnimSMState(state): ChangeAnimSMState(state);
					}
					retVal.addAction({atRateTime: atRate, action: resolvedAction});
					
				}
				return retVal;
				

			default: throw '$name has to be animatedPath';
		}
	}

	public function getLayouts(?builderParams:BuilderParameters):MultiAnimLayouts {
		var node = multiParserResult?.nodes.get(MultiAnimParser.defaultLayoutNodeName);
		if (node == null) throw 'relativeLayouts does not exist';
		switch node.type {
			case RELATIVE_LAYOUTS(layoutsDef):
				return new MultiAnimLayouts(layoutsDef, this);
			default: throw 'relativeLayouts is of unexpected type ${node.type}';
		}
	}

	public function getPaths(?builderParams:BuilderParameters):wt.paths.MultiAnimPaths {
		var node = multiParserResult?.nodes.get(MultiAnimParser.defaultPathNodeName);
		if (node == null) throw 'paths does not exist';
		switch node.type {
			 case PATHS(pathsDef):
			 	return new wt.paths.MultiAnimPaths(pathsDef, this);
			default: throw 'paths is of unexpected type ${node.type}';
		}
	}
	function updateIndexedParamsFromDynamicMap(input:Map<String, Dynamic>, definitions:ParametersDefinitions, ?extraInput:Map<String, ResolvedIndexParameters>):Void {
		
		inline function getDefsType(key:String, value:Dynamic) {
			final type = definitions.get(key)?.type;
			if (type == null) throw '$key=>$value does not have matching ParametersDefinitions ${definitions.toString()} (or type is null)';
			return type;
		}

		function resolveReferencableValue(ref:ReferencableValue, type):Dynamic {
			return switch type {
				case null: throw 'type is null';
				case PPTHexDirecton: resolveAsInteger(ref);
				case PPTGridDirection: resolveAsInteger(ref);
				case PPTFlags(_): resolveAsInteger(ref);
				case PPTEnum(_): resolveAsString(ref);
				case PPTRange(_, _): resolveAsInteger(ref);
				case PPTInt: resolveAsInteger(ref);
				case PPTFloat: resolveAsNumber(ref);
				case PPTBool: resolveAsInteger(ref);
				case PPTUnsignedInt: resolveAsInteger(ref);
				case PPTString: resolveAsString(ref);
				case PPTColor: resolveAsColorInteger(ref);
				case PPTArray: resolveAsArray(ref);
			}

		}
	

		final retVal:Map<String, ResolvedIndexParameters> = [];
		if (input == null && extraInput == null) {
			this.indexedParams = retVal;
		}

		if (extraInput != null) {
			for (k=>v in extraInput) {
				if (!indexedParams.exists(k)) indexedParams.set(k, v);
			}
		}
		if (input != null) for (key => value in input) {
			if (Std.isOfType(value, ResolvedIndexParameters)) {
				retVal.set(key, value);	
			}
			else if (Std.isOfType(value, ReferencableValue)) {
				final ref:ReferencableValue = value;
				final type = getDefsType(key, value);
				final resolved = resolveReferencableValue(ref, type);
				retVal.set(key, MultiAnimParser.dynamicValueToIndex(key, type, resolved, s->throw s));
			}
			else {
				final type = getDefsType(key, value);
				retVal.set(key, MultiAnimParser.dynamicValueToIndex(key, type, value, s->throw s));
			}
		}
		if (extraInput != null) {
			for (key => value in extraInput) {
				if (retVal.exists(key)) throw 'extra input "$key=>$value" already exists in input';
				if (Std.isOfType(value, ResolvedIndexParameters)) {
					retVal.set(key, value);	
				}
				else if (Std.isOfType(value, ReferencableValue)) {
					final ref:ReferencableValue =  cast value;
					final type = getDefsType(key, value);
					final resolved = resolveReferencableValue(ref, type);
					retVal.set(key, MultiAnimParser.dynamicValueToIndex(key, type, resolved, s->throw s));
				}				
				else {
					final type =  getDefsType(key, value);
					
					retVal.set(key, MultiAnimParser.dynamicValueToIndex(key, type, value, s->throw s));
				}
			}
		}

		for (key => value in definitions) {
			if (!retVal.exists(key) && value.defaultValue != null) retVal[key] = value.defaultValue;
		}

		this.indexedParams =  retVal;
		
	}


	public function buildWithParameters(name:String, inputParameters:Map<String, Dynamic>, ?builderParams:BuilderParameters, ?inheritedParameters:Map<String, ResolvedIndexParameters>):BuilderResult {

		pushBuilderState();
		if (builderParams == null) builderParams = {callback:defaultCallback};
		else if (builderParams.callback == null) builderParams.callback = defaultCallback;
		var node = multiParserResult?.nodes.get(name);
		if (node == null) {
			final error = 'buildWithParameters ${inputParameters}: could find element "$name" to build';
			trace(error);
			popBuilderState();
			throw error;

		}
		
		final hasParams = inputParameters != null && inputParameters.count() > 0;
		var definitions:ParametersDefinitions = getProgrammableParameterDefinitions(node, hasParams);
		
		updateIndexedParamsFromDynamicMap(inputParameters, definitions, inheritedParameters);
		this.builderParams = builderParams;

		var retVal = startBuild(name, node, MultiAnimParser.getGridCoordinateSystem(node), MultiAnimParser.getHexCoordinateSystem(node), builderParams);
		// root.ysort(0);
		popBuilderState();
		return retVal;
		
	}

	public function buildWithComboParameters(name:String, inputParameters:Map<String, Dynamic>, allCombos:Array<String>, ?builderParams:BuilderParameters) {
		pushBuilderState();
		try {
			if (builderParams == null)
				builderParams = {callback: defaultCallback};
			else if (builderParams.callback == null)
				builderParams.callback = defaultCallback;

			final node = multiParserResult?.nodes?.get(name);
			if (node == null) {
				throw 'buildWithComboParameters ${allCombos}: could not build ${name}';
			}
			if (inputParameters.count() + allCombos.length == 0) {
				throw 'parameters are required';
			}

			final definitions = getProgrammableParameterDefinitions(node, true);

			var allOptions:Map<String, Array<String>> = [];
			var totalStates = 1;

			var comboCounts = [];
			var comboNames = [];

			for (prop in allCombos) {
				if (!definitions.exists(prop))
					throw 'definition for "${prop}" does not exist';
				if (inputParameters.exists(prop))
					throw 'Prop "${prop}" set both as parameter and combo';
				if (allOptions.exists(prop))
					throw 'Duplicate combo "${prop}"';
				var def = definitions[prop];
				var allValues = switch def.type {
					case PPTHexDirecton: [for (i in 0...6) '$i}'];
					case PPTGridDirection: [for (i in 0...8) '$i}'];
					case PPTFlags(bits): [for (i in 0...bits) '$i}'];
					case PPTEnum(values): values;
					case PPTBool: ["0", "1"];
					case PPTRange(from, to): [for (i in from...to) '$i}'];
					case PPTInt: throw 'Prop "${prop}" is int and cannot be used as combo';
					case PPTUnsignedInt: throw 'Prop "${prop}" is uint and cannot be used as combo';
					case PPTString: throw 'Prop "${prop}" is string and cannot be used as combo';
					case PPTColor: throw 'Prop "${prop}" is color and cannot be used as combo';
					case PPTFloat: throw 'Prop "${prop}" is float and cannot be used as combo';
					case PPTArray: throw 'Prop "${prop}" is array and cannot be used as combo';
				}
				allOptions.set(prop, allValues);
				totalStates *= allValues.length;
				comboNames.push(prop);
				comboCounts.push(allValues.length);

				if (totalStates > 32)
					trace('more than 100 combination for build all');
				else if (totalStates > 1000)
					throw 'more than 1000 combinations for buildAll';
			}
			final gridCoordinateSystem = MultiAnimParser.getGridCoordinateSystem(node);
			final hexCoordinateSystem = MultiAnimParser.getHexCoordinateSystem(node);

			var result = new MultiAnimMultiResult(allCombos);
			for (i in 0...totalStates) {
				final comboParams:Map<String, ResolvedIndexParameters> = [];
				var ci = i;
				for (ki in 0...comboNames.length) {
					final vi = ci % comboCounts[ki];
					ci = Std.int(ci / comboCounts[ki]);
					var key = comboNames[ki];
					comboParams.set(key, StringValue(allOptions[key][vi]));
				}
				
				updateIndexedParamsFromDynamicMap(inputParameters, definitions, comboParams);
				this.builderParams = builderParams;
				var c = startBuild(name, node, gridCoordinateSystem, hexCoordinateSystem,  builderParams);
				result.addResult(c, [for (combo in allCombos) {
					switch comboParams[combo] {
						case StringValue(s): s;
						default: throw 'comboParams [${combo}] is not string';
					}
				}]);
			}
			popBuilderState();
			return result;
		} catch (e) {
			popBuilderState();
			throw e;
		}
	}

	function loadTileImpl(sheet, tilename, ?index:Int) {
		final sheet = resourceLoader.loadSheet2(sheet);
		if (sheet == null) throw 'sheet ${sheet} could not be loaded';

		final tile = if (index != null) {
			final arr = sheet.getAnim(tilename);
			if (arr == null) throw 'tile ${tilename}, index $index sheet ${sheet} could not be loaded';
			if (index < 0 || index >= arr.length) throw 'tile $tilename from sheet $sheet does not have tile index $index, should be [0, ${arr.length-1}]';
			arr[index];
		} else {
			final t = sheet.get(tilename);
			if (t == null) throw 'tile ${tilename} in sheet ${sheet} could not be loaded';
			t;
		}
		
		
		return tile;

	}
	function load9Pathch(sheet, tilename) {
		final sheet = resourceLoader.loadSheet2(sheet);
		if (sheet == null) throw 'sheet ${sheet} could not be loaded';

		final ninePatch = sheet.getNinePatch(tilename);
		if (ninePatch == null) throw 'tile ${tilename} in sheet ${sheet} could not be loaded';
		return ninePatch;

	}

	

}