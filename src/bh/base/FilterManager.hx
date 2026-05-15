package bh.base;

import bh.multianim.MultiAnimParser.CustomFilterArg;
import bh.multianim.MultiAnimParser.CustomFilterArgType;
import bh.multianim.MultiAnimParser.CustomFilterRef;
import bh.multianim.MultiAnimParser.ReferenceableValue;

typedef FilterParamDef = {
	name:String,
	type:CustomFilterArgType,
	?defaultValue:Dynamic,
};

typedef CustomFilterFactory = (params:Map<String, Dynamic>) -> h2d.filter.Filter;

typedef CustomFilterRegistration = {
	params:Array<FilterParamDef>,
	factory:CustomFilterFactory,
};

class FilterManager {
	private static var filterRegistry:Map<String, CustomFilterRegistration> = new Map();

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
		if (filterRegistry.exists(lowerName)) {
			throw 'Filter "$name" is already registered. Use a different name or unregister the existing filter first.';
		}
		filterRegistry.set(lowerName, {params: params, factory: factory});
	}

	public static function unregisterFilter(name:String) {
		filterRegistry.remove(name.toLowerCase());
	}

	public static function hasFilter(name:String):Bool {
		return filterRegistry.exists(name.toLowerCase());
	}

	public static function getFilter(name:String):Null<CustomFilterRegistration> {
		return filterRegistry.get(name.toLowerCase());
	}

	public static function getRegisteredFilterNames():Array<String> {
		final keys = [for (k in filterRegistry.keys()) k];
		keys.sort((a, b) -> a < b ? -1 : 1);
		return keys;
	}

	/** Validate all custom filter references from a parse result against registered filters.
	 * Throws on first error with source position. */
	public static function validateCustomFilters(refs:Array<CustomFilterRef>):Void {
		for (ref in refs) {
			final reg = filterRegistry.get(ref.name);
			if (reg == null) {
				throw 'Unknown custom filter "${ref.name}" at ${ref.pos}. Register it via FilterManager.registerFilter().';
			}
			// Count required params (those without defaults)
			var requiredCount = 0;
			for (p in reg.params) {
				if (p.defaultValue == null) requiredCount++;
			}
			if (ref.argCount < requiredCount) {
				throw 'Custom filter "${ref.name}" requires at least $requiredCount argument(s), got ${ref.argCount} at ${ref.pos}.';
			}
			if (ref.argCount > reg.params.length) {
				throw 'Custom filter "${ref.name}" accepts at most ${reg.params.length} argument(s), got ${ref.argCount} at ${ref.pos}.';
			}
			// Validate types for provided args (skip $param references — type resolved at build time)
			for (i in 0...ref.argCount) {
				if (i < ref.argTypes.length && i < reg.params.length) {
					if (!isRefArg(ref.args[i]) && ref.argTypes[i] != reg.params[i].type) {
						throw 'Custom filter "${ref.name}" argument "${reg.params[i].name}" expects ${reg.params[i].type}, got ${ref.argTypes[i]} at ${ref.pos}.';
					}
				}
			}
		}
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

	/** Build a custom filter at runtime from resolved args. Called by codegen-generated code. */
	public static function buildCustomFilter(name:String, args:Array<{value:Dynamic, type:CustomFilterArgType}>):h2d.filter.Filter {
		final reg = filterRegistry.get(name);
		if (reg == null)
			throw 'Unknown custom filter "$name". Register it via FilterManager.registerFilter().';
		final resolved = new Map<String, Dynamic>();
		for (i in 0...reg.params.length) {
			final paramDef = reg.params[i];
			if (i < args.length) {
				final raw:Dynamic = args[i].value;
				switch paramDef.type {
					case CFFloat: resolved[paramDef.name] = dynamicToFloat(raw);
					case CFColor: resolved[paramDef.name] = dynamicToInt(raw);
					case CFBool: resolved[paramDef.name] = dynamicToFloat(raw) != 0;
				}
			} else if (paramDef.defaultValue != null) {
				resolved[paramDef.name] = paramDef.defaultValue;
			} else {
				throw 'Custom filter "$name" missing required argument "${paramDef.name}".';
			}
		}
		return reg.factory(resolved);
	}

	// HL Dynamic→Float/Int can lose type info through Map<String,Dynamic> round-trips.
	// These helpers force correct conversion.
	static function dynamicToFloat(v:Dynamic):Float {
		if (v is Int) return (v : Int) * 1.0;
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
