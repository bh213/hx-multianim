package bh.base;

import bh.multianim.MultiAnimParser.CustomFilterArg;
import bh.multianim.MultiAnimParser.CustomFilterArgType;
import bh.multianim.MultiAnimParser.CustomFilterRef;
import bh.multianim.MultiAnimParser.ReferenceableValue;
import bh.multianim.ShaderCatalog;

/**
	A filter's parameter: its name, its type and its default (none: it must be given), and what a
	tool shows of it, a slider's `min`, `max` and `step`, a `unit`, a `label`, a word's `choices`.
**/
typedef FilterParamDef = ShaderParamInfo;

typedef CustomFilterFactory = (params:Map<String, Dynamic>) -> h2d.filter.Filter;

typedef CustomFilterRegistration = {
	params:Array<FilterParamDef>,
	factory:CustomFilterFactory,
	/** One of the engine's shaders (`ShaderCatalog`), not registered by the game. */
	?builtin:Bool,
};

/**
	An argument of a filter as the build has it: its value resolved, and the name it was given by, if any.
	`word`: the value as text where that is not `value` (an enum parameter's value by its name, where
	`value` is its index), what a word or a palette parameter takes.
**/
typedef GivenFilterArg = {value:Dynamic, ?type:CustomFilterArgType, ?name:String, ?word:String};

/**
	The filters a `.manim` may name beyond the built-in ones (`outline`, `glow`, …): the engine's
	shaders (`ShaderCatalog`, made by `bh.base.shaders.BuiltinShaders`) and a game's own, registered
	with `registerFilter`. Written `filter: name(args)`, an argument by position or by name
	(`crt(curve: 0.2)`); every parameter left out takes its default.

	A filter that is an `EngineShaderFilter` is set in place when its `$param`s change: its uniforms
	are written, the filter is not made again.
**/
class FilterManager {
	private static var filterRegistry:Map<String, CustomFilterRegistration> = new Map();
	private static var builtinRegistry:Map<String, CustomFilterRegistration> = new Map();

	static final builtinNames:Array<String> = [
		"none", "group", "outline", "saturate", "brightness", "grayscale", "hue",
		"glow", "blur", "dropshadow", "pixeloutline", "replacepalette", "replacecolor"
	];

	public static function registerFilter(name:String, params:Array<FilterParamDef>, factory:CustomFilterFactory) {
		var lowerName = name.toLowerCase();
		for (builtin in builtinNames) {
			if (lowerName == builtin) {
				throw 'Cannot register custom filter "$name" — it conflicts with built-in filter "$builtin".';
			}
		}
		if (ShaderCatalog.isBuiltin(lowerName))
			throw 'Cannot register custom filter "$name" — it is one of the engine\'s shaders (ShaderCatalog).';
		if (filterRegistry.exists(lowerName)) {
			throw 'Filter "$name" is already registered. Use a different name or unregister the existing filter first.';
		}
		filterRegistry.set(lowerName, {params: params, factory: factory});
	}

	public static function unregisterFilter(name:String) {
		filterRegistry.remove(name.toLowerCase());
	}

	public static function hasFilter(name:String):Bool {
		return getFilter(name) != null;
	}

	/** A filter by its name: the game's own, else one of the engine's shaders. **/
	public static function getFilter(name:String):Null<CustomFilterRegistration> {
		final lower = name.toLowerCase();
		final own = filterRegistry.get(lower);
		if (own != null)
			return own;
		return builtinOf(lower);
	}

	static function builtinOf(lower:String):Null<CustomFilterRegistration> {
		final had = builtinRegistry.get(lower);
		if (had != null)
			return had;
		final info = ShaderCatalog.find(lower);
		if (info == null)
			return null;
		final reg:CustomFilterRegistration = {
			params: info.params,
			factory: params -> {
				final made = bh.base.shaders.BuiltinShaders.make(lower, params);
				if (made == null)
					throw 'The engine describes the shader "${info.name}" but has none by that name.';
				made;
			},
			builtin: true,
		};
		builtinRegistry.set(lower, reg);
		return reg;
	}

	/**
		A parameter's default, changed for this game: `paletteLock`'s palette held to the game's own
		palette, say, so a filter written without it uses that. The catalogue keeps its own; null puts the
		catalogue's back (a game's own filter's stays as it was given).
	**/
	public static function setParamDefault(name:String, param:String, value:Null<Dynamic>):Void {
		final reg = getFilter(name);
		if (reg == null)
			throw 'Unknown custom filter "$name".';
		if (!Lambda.exists(reg.params, p -> p.name == param))
			throw 'Custom filter "$name" has no parameter "$param".';
		final info = reg.builtin == true ? ShaderCatalog.find(name) : null;
		reg.params = [
			for (p in reg.params)
				if (p.name != param) p else {
					final copy:FilterParamDef = Reflect.copy(p);
					if (value != null)
						copy.defaultValue = value;
					else if (info != null)
						copy.defaultValue = Lambda.find(info.params, q -> q.name == param)?.defaultValue;
					copy;
				}
		];
	}

	/** The game's own filters, by name: the engine's shaders are `ShaderCatalog.shaders`. **/
	public static function getRegisteredFilterNames():Array<String> {
		final keys = [for (k in filterRegistry.keys()) k];
		keys.sort((a, b) -> a < b ? -1 : 1);
		return keys;
	}

	/**
		Which parameter each argument is given to, by position then by name: `crt(0.2, lineSize: 4)`
		gives the first to `curve` and the second to `lineSize`. Throws on a name the filter has not,
		a parameter given twice, or an argument by position after one by name.
	**/
	public static function argIndexes(name:String, params:Array<FilterParamDef>, names:Array<Null<String>>):Array<Int> {
		final indexes:Array<Int> = [];
		var named = false;
		for (i in 0...names.length) {
			final argName = names[i];
			var index = -1;
			if (argName == null) {
				if (named)
					throw 'Filter "$name": an argument by position cannot follow one by name.';
				index = i;
				if (index >= params.length)
					throw 'Filter "$name" accepts at most ${params.length} argument(s), got ${names.length}.';
			} else {
				named = true;
				final lower = argName.toLowerCase();
				for (j in 0...params.length)
					if (params[j].name.toLowerCase() == lower)
						index = j;
				if (index < 0)
					throw 'Filter "$name" has no parameter "$argName"; it has ${[for (p in params) p.name].join(", ")}.';
			}
			if (indexes.contains(index))
				throw 'Filter "$name": "${params[index].name}" is given twice.';
			indexes.push(index);
		}
		return indexes;
	}

	/** Validate all custom filter references from a parse result against registered filters.
	 * Throws on first error with source position. */
	public static function validateCustomFilters(refs:Array<CustomFilterRef>):Void {
		for (ref in refs) {
			final reg = getFilter(ref.name);
			if (reg == null) {
				throw 'Unknown custom filter "${ref.name}" at ${ref.pos}. Register it via FilterManager.registerFilter().';
			}
			final indexes = try argIndexes(ref.name, reg.params, [for (a in ref.args) a.name]) catch (e:String) throw '$e At ${ref.pos}.';
			// Every parameter with no default is given: by position, as many as those; by name, each
			var requiredCount = 0;
			for (p in reg.params)
				if (p.defaultValue == null) requiredCount++;
			if (ref.args.length < requiredCount && !Lambda.exists(ref.args, a -> a.name != null))
				throw 'Custom filter "${ref.name}" requires at least $requiredCount argument(s), got ${ref.args.length} at ${ref.pos}.';
			for (j in 0...reg.params.length)
				if (reg.params[j].defaultValue == null && !indexes.contains(j))
					throw 'Custom filter "${ref.name}" needs "${reg.params[j].name}" at ${ref.pos}.';
			// Types of what is written as it is ($param references are resolved when built)
			for (i in 0...ref.args.length) {
				final arg = ref.args[i];
				if (isRefArg(arg))
					continue;
				final param = reg.params[indexes[i]];
				if (!fits(arg, param.type))
					throw 'Custom filter "${ref.name}" argument "${param.name}" expects ${param.type}, got ${arg.type} at ${ref.pos}.';
				final choices = param.choices;
				if (choices != null && arg.type == CFWord) {
					final word = switch arg.value {
						case RVString(s): s;
						default: null;
					};
					if (word != null && !choices.contains(word))
						throw 'Custom filter "${ref.name}" argument "${param.name}" is one of ${choices.join(", ")}, not "$word" at ${ref.pos}.';
				}
			}
		}
	}

	/** Whether an argument written as one type may be given to a parameter of another: a word to a colour when it names one (`black`). **/
	static function fits(arg:CustomFilterArg, param:CustomFilterArgType):Bool {
		return switch [arg.type, param] {
			case [CFFloat, CFFloat | CFInt]: true;
			case [CFWord, CFWord | CFPalette]: true;
			case [CFWord, CFColor]:
				switch arg.value {
					case RVString(s): bh.multianim.MacroManimParser.tryStringToColor(s) != null;
					default: false;
				}
			default: arg.type == param;
		};
	}

	/** A colour argument: a number, or a colour's name (`black`, written bare). **/
	static function colorOf(filter:String, param:String, raw:Dynamic):Int {
		if (raw is String) {
			final c = bh.multianim.MacroManimParser.tryStringToColor(raw);
			if (c == null)
				throw 'Custom filter "$filter" argument "$param" expects a colour, not "$raw".';
			return c;
		}
		return dynamicToInt(raw);
	}

	/** Check if a custom filter arg contains a $param reference (type resolved at build time, not parse time). */
	static function isRefArg(arg:CustomFilterArg):Bool {
		return containsReference(arg.value);
	}

	static function containsReference(v:ReferenceableValue):Bool {
		return switch v {
			case RVReference(_), RVPropertyAccess(_, _), RVMethodCall(_, _, _), RVTernary(_, _, _): true;
			case EBinop(_, e1, e2): containsReference(e1) || containsReference(e2);
			case EUnaryOp(_, e) | RVParenthesis(e): containsReference(e);
			default: false;
		};
	}

	/**
		Every parameter's value, as its type: those given, the rest at their defaults. A word is held to
		its `choices`; a palette's name becomes its colours through `palette`.
	**/
	public static function valuesOf(name:String, params:Array<FilterParamDef>, args:Array<GivenFilterArg>,
			?palette:String->Array<Int>):Map<String, Dynamic> {
		final indexes = argIndexes(name, params, [for (a in args) a.name]);
		final values = new Map<String, Dynamic>();
		for (j in 0...params.length) {
			final def = params[j];
			final at = indexes.indexOf(j);
			final given = at >= 0 ? args[at] : null;
			final takesWord = switch def.type {
				case CFWord | CFPalette: true;
				default: false;
			};
			final raw:Dynamic = given == null ? def.defaultValue : takesWord && given.word != null ? given.word : given.value;
			if (raw == null) {
				if (at < 0)
					throw 'Custom filter "$name" missing required argument "${def.name}".';
				continue;
			}
			switch def.type {
				case CFFloat:
					values[def.name] = dynamicToFloat(raw);
				case CFInt:
					values[def.name] = Math.round(dynamicToFloat(raw));
				case CFColor:
					values[def.name] = colorOf(name, def.name, raw);
				case CFBool:
					values[def.name] = raw is Bool ? (raw : Bool) : dynamicToFloat(raw) != 0;
				case CFWord:
					final word = Std.string(raw);
					final choices = def.choices;
					if (choices != null && !choices.contains(word))
						throw 'Custom filter "$name" argument "${def.name}" is one of ${choices.join(", ")}, not "$word".';
					values[def.name] = word;
				case CFPalette:
					if (raw is Array)
						values[def.name] = raw;
					else {
						if (palette == null)
							throw 'Custom filter "$name" argument "${def.name}" names a palette, and none can be read here.';
						values[def.name] = palette(Std.string(raw));
					}
			}
		}
		return values;
	}

	/** Build a custom filter at runtime from resolved args. Called by codegen-generated code. */
	public static function buildCustomFilter(name:String, args:Array<GivenFilterArg>, ?palette:String->Array<Int>):h2d.filter.Filter {
		final reg = getFilter(name);
		if (reg == null)
			throw 'Unknown custom filter "$name". Register it via FilterManager.registerFilter().';
		return reg.factory(valuesOf(name, reg.params, args, palette));
	}

	/**
		The filter for these values where `previous` is: `previous` itself, its values written in place,
		when it is a shader filter of the same name; else one made new. What a `$param`'s change runs.
	**/
	public static function customFilterIn(previous:Null<h2d.filter.Filter>, name:String, args:Array<GivenFilterArg>,
			?palette:String->Array<Int>):h2d.filter.Filter {
		final reg = getFilter(name);
		if (reg == null)
			throw 'Unknown custom filter "$name". Register it via FilterManager.registerFilter().';
		final values = valuesOf(name, reg.params, args, palette);
		final kept = sameShader(previous, name);
		if (kept != null) {
			kept.setParams(values);
			return kept;
		}
		return reg.factory(values);
	}

	/**
		A ground's shader (`generated(shader(name, w, h, args))`), drawn from nothing: `previous` set in
		place when it is one of the same name. Its values say `ground: true`, which a shader drawn
		both over a picture and on its own (`fog`) reads.
	**/
	public static function groundFilterIn(previous:Null<h2d.filter.Filter>, name:String, args:Array<GivenFilterArg>,
			?palette:String->Array<Int>):h2d.filter.Filter {
		final reg = getFilter(name);
		if (reg == null)
			throw 'Unknown shader "$name" for a ground. The engine\'s are ShaderCatalog\'s; register a game\'s own via FilterManager.registerFilter().';
		final values = valuesOf(name, reg.params, args, palette);
		values["ground"] = true;
		final kept = sameShader(previous, name);
		if (kept != null) {
			kept.setParams(values);
			return kept;
		}
		return reg.factory(values);
	}

	/** `filter` when it is a shader filter written by this name, to be set in place. **/
	public static function sameShader(filter:Null<h2d.filter.Filter>, name:String):Null<bh.base.filters.EngineShaderFilter> {
		if (filter == null || !(filter is bh.base.filters.EngineShaderFilter))
			return null;
		final shader:bh.base.filters.EngineShaderFilter = cast filter;
		return shader.shaderName == name.toLowerCase() ? shader : null;
	}

	// HL Dynamic→Float/Int can lose type info through Map<String,Dynamic> round-trips.
	// These helpers force correct conversion.
	static function dynamicToFloat(v:Dynamic):Float {
		if (v is Int) return (v : Int) * 1.0;
		if (v is Bool) return (v : Bool) ? 1.0 : 0.0;
		return (v : Float);
	}

	static function dynamicToInt(v:Dynamic):Int {
		if (v is Float) return Std.int((v : Float));
		return (v : Int);
	}

	/** Clear all registered filters (useful for testing). */
	public static function clearAll():Void {
		filterRegistry.clear();
	}
}
