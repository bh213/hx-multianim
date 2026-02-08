package bh.multianim;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

/**
 * Compile-time macro for generating fast programmable UI element code.
 *
 * Usage:
 *   @:build(bh.multianim.ProgrammableMacro.build("path/to/file.manim", "programmableName"))
 *   class MyElement extends ProgrammableBase {}
 *
 * Generates:
 *   - Typed parameter fields with setters (e.g. public var hp(default, set):Int)
 *   - Static enum constants (e.g. STATUS_NORMAL, STATUS_POISONED)
 *   - create(resourceLoader) — builds h2d object tree directly (Phase 2)
 *   - refresh() — re-applies all expressions + conditionals (Phase 2)
 *   - _applyConditionals() — toggles element visibility (Phase 2)
 *   - Per-parameter setters that trigger targeted updates
 */
private typedef ParamDef = {
	name:String,
	type:ParamType,
	defaultValue:Null<String>,
}

private enum ParamType {
	PTInt;
	PTUInt;
	PTFloat;
	PTBool;
	PTString;
	PTColor;
	PTEnum(values:Array<String>);
	PTRange(from:Int, to:Int);
	PTFlags;
}

class ProgrammableMacro {
	public static function build(manimFile:String, programmableName:String):Array<Field> {
		var fields = Context.getBuildFields();
		var pos = Context.currentPos();

		// 1. Read .manim file
		var filePath:Null<String> = null;
		try {
			filePath = Context.resolvePath(manimFile);
		} catch (e:Dynamic) {}

		if (filePath == null) {
			if (sys.FileSystem.exists(manimFile))
				filePath = manimFile;
			else {
				Context.fatalError('Could not find .manim file: $manimFile', pos);
				return fields;
			}
		}

		var content = sys.io.File.getContent(filePath);

		// 2. Register dependency — recompile when .manim changes
		Context.registerModuleDependency(Context.getLocalModule(), filePath);

		// 3. Extract parameter definitions from the programmable header
		var paramDefs = extractProgrammableParams(content, programmableName);
		if (paramDefs == null) {
			Context.fatalError('Could not find programmable "#$programmableName" in $manimFile', pos);
			return fields;
		}

		// 4. Generate fields

		// 4a. Enum constants + property + setter for each parameter
		for (param in paramDefs) {
			switch (param.type) {
				case PTEnum(values):
					for (i in 0...values.length) {
						fields.push(makeEnumConstant(param.name, values[i], i, pos));
					}
				default:
			}

			fields.push(makeParamProperty(param, pos));
			fields.push(makeParamSetter(param, pos));
		}

		// 4b. create(resourceLoader)
		fields.push(makeCreateMethod(pos));

		// 4c. refresh()
		fields.push(makeRefreshMethod(pos));

		// 4d. _applyConditionals()
		fields.push(makeApplyConditionalsMethod(pos));

		return fields;
	}

	// ----------------------------------------------------------------
	// Field generators
	// ----------------------------------------------------------------

	static function makeEnumConstant(paramName:String, valueName:String, index:Int, pos:Position):Field {
		var constName = paramName.toUpperCase() + "_" + valueName.toUpperCase();
		return {
			name: constName,
			doc: null,
			access: [APublic, AStatic, AInline],
			kind: FVar(macro:Int, macro $v{index}),
			pos: pos,
			meta: [],
		};
	}

	static function makeParamProperty(param:ParamDef, pos:Position):Field {
		var ct = paramTypeToComplexType(param.type);
		var defaultExpr = paramDefaultExpr(param);

		return {
			name: param.name,
			doc: null,
			access: [APublic],
			kind: FProp("default", "set", ct, defaultExpr),
			pos: pos,
			meta: [],
		};
	}

	static function makeParamSetter(param:ParamDef, pos:Position):Field {
		var ct = paramTypeToComplexType(param.type);
		var fieldIdent = param.name;

		// Generated setter body:
		//   this.<field> = v;
		//   if (_root != null) refresh();
		//   return v;
		var body = macro {
			$i{fieldIdent} = v;
			if (_root != null)
				refresh();
			return v;
		};

		return {
			name: 'set_${param.name}',
			doc: null,
			access: [],
			kind: FFun({
				args: [{name: "v", type: ct, opt: false, meta: [], value: null}],
				ret: ct,
				expr: body,
				params: [],
			}),
			pos: pos,
			meta: [],
		};
	}

	static function makeCreateMethod(pos:Position):Field {
		return {
			name: "create",
			doc: null,
			access: [APublic],
			kind: FFun({
				args: [
					{
						name: "resourceLoader",
						type: TPath({pack: ["bh", "base"], name: "ResourceLoader", params: []}),
						opt: false,
						meta: [],
						value: null
					}
				],
				ret: TPath({pack: ["h2d"], name: "Object", params: []}),
				expr: macro {
					_resourceLoader = resourceLoader;
					final root = new h2d.Layers();
					_root = root;
					// Phase 2: macro-generated element construction goes here
					_applyConditionals();
					return root;
				},
				params: [],
			}),
			pos: pos,
			meta: [],
		};
	}

	static function makeRefreshMethod(pos:Position):Field {
		return {
			name: "refresh",
			doc: null,
			access: [APublic],
			kind: FFun({
				args: [],
				ret: macro:Void,
				expr: macro {
					if (_root == null)
						return;
					// Phase 2: macro-generated expression re-evaluation goes here
					_applyConditionals();
				},
				params: [],
			}),
			pos: pos,
			meta: [],
		};
	}

	static function makeApplyConditionalsMethod(pos:Position):Field {
		return {
			name: "_applyConditionals",
			doc: null,
			access: [],
			kind: FFun({
				args: [],
				ret: macro:Void,
				expr: macro {
					// Phase 2: macro-generated conditional visibility toggles go here
				},
				params: [],
			}),
			pos: pos,
			meta: [],
		};
	}

	// ----------------------------------------------------------------
	// Type mapping
	// ----------------------------------------------------------------

	static function paramTypeToComplexType(type:ParamType):ComplexType {
		return switch (type) {
			case PTInt, PTUInt, PTColor, PTFlags, PTRange(_, _), PTEnum(_): macro:Int;
			case PTFloat: macro:Float;
			case PTBool: macro:Bool;
			case PTString: macro:String;
		};
	}

	static function paramDefaultExpr(param:ParamDef):Null<Expr> {
		if (param.defaultValue == null) {
			return switch (param.type) {
				case PTInt, PTUInt, PTColor, PTFlags, PTRange(_, _), PTEnum(_): macro 0;
				case PTFloat: macro 0.0;
				case PTBool: macro false;
				case PTString: macro "";
			};
		}

		var dv = param.defaultValue;
		return switch (param.type) {
			case PTEnum(values):
				var idx = values.indexOf(dv);
				if (idx < 0) idx = 0;
				macro $v{idx};
			case PTBool:
				var bval = dv == "true" || dv == "1";
				macro $v{bval};
			case PTFloat:
				var fval = Std.parseFloat(dv);
				macro $v{fval};
			case PTInt, PTUInt, PTRange(_, _), PTFlags:
				var ival = Std.parseInt(dv);
				if (ival == null) ival = 0;
				macro $v{ival};
			case PTColor:
				var ival = parseColorValue(dv);
				macro $v{ival};
			case PTString:
				macro $v{dv};
		};
	}

	static function parseColorValue(s:String):Int {
		if (s.startsWith("0x") || s.startsWith("0X"))
			return Std.parseInt(s);
		if (s.startsWith("#"))
			return Std.parseInt("0x" + s.substr(1));
		var i = Std.parseInt(s);
		return i != null ? i : 0;
	}

	// ----------------------------------------------------------------
	// .manim text extraction
	// ----------------------------------------------------------------

	static function extractProgrammableParams(content:String, name:String):Null<Array<ParamDef>> {
		var searchStr = '#$name';
		var idx = 0;

		while (idx < content.length) {
			var found = content.indexOf(searchStr, idx);
			if (found < 0)
				return null;

			var cursor = found + searchStr.length;

			// Ensure full word match (next char must be whitespace or ()
			if (cursor < content.length) {
				var nextCh = content.charCodeAt(cursor);
				var isWordChar = (nextCh >= 'a'.code && nextCh <= 'z'.code) || (nextCh >= 'A'.code && nextCh <= 'Z'.code)
					|| (nextCh >= '0'.code && nextCh <= '9'.code) || nextCh == '_'.code;
				if (isWordChar) {
					idx = cursor;
					continue;
				}
			}

			cursor = skipWs(content, cursor);

			// Expect "programmable"
			if (!content.substr(cursor, 12).startsWith("programmable")) {
				idx = cursor;
				continue;
			}
			cursor += 12;
			cursor = skipWs(content, cursor);

			// Expect "("
			if (cursor >= content.length || content.charCodeAt(cursor) != '('.code) {
				idx = cursor;
				continue;
			}
			cursor++;

			// Find matching ), tracking [] nesting
			var start = cursor;
			var bracketDepth = 0;
			while (cursor < content.length) {
				var ch = content.charCodeAt(cursor);
				if (ch == '['.code)
					bracketDepth++;
				else if (ch == ']'.code)
					bracketDepth--;
				else if (ch == ')'.code && bracketDepth == 0)
					break;
				cursor++;
			}

			if (cursor >= content.length)
				return null;

			var paramsStr = content.substring(start, cursor).trim();
			if (paramsStr.length == 0)
				return [];

			return parseParamDefs(paramsStr);
		}

		return null;
	}

	static function skipWs(s:String, idx:Int):Int {
		while (idx < s.length) {
			var ch = s.charCodeAt(idx);
			if (ch != ' '.code && ch != '\t'.code && ch != '\n'.code && ch != '\r'.code)
				break;
			idx++;
		}
		return idx;
	}

	static function parseParamDefs(paramsStr:String):Array<ParamDef> {
		// Split by comma, respecting [] nesting
		var parts:Array<String> = [];
		var depth = 0;
		var start = 0;

		for (i in 0...paramsStr.length) {
			var ch = paramsStr.charCodeAt(i);
			if (ch == '['.code)
				depth++;
			else if (ch == ']'.code)
				depth--;
			else if (ch == ','.code && depth == 0) {
				parts.push(paramsStr.substring(start, i).trim());
				start = i + 1;
			}
		}
		parts.push(paramsStr.substring(start).trim());

		var result:Array<ParamDef> = [];
		for (p in parts) {
			if (p.length == 0)
				continue;
			var def = parseSingleParam(p);
			if (def != null)
				result.push(def);
		}
		return result;
	}

	static function parseSingleParam(p:String):Null<ParamDef> {
		// Formats:
		//   name:type           →  e.g. hp:uint
		//   name:type=default   →  e.g. hp:uint=100
		//   name:[v1,v2,v3]     →  enum type
		//   name=[v1,v2,v3]     →  enum type with = instead of :
		//   name="text"         →  string with default
		//   name:N..M           →  range type
		//   name:N..M=default   →  range with default

		// Find = outside of [], for splitting default value
		var eqIdx = -1;
		var depth = 0;
		for (i in 0...p.length) {
			var ch = p.charCodeAt(i);
			if (ch == '['.code)
				depth++;
			else if (ch == ']'.code)
				depth--;
			else if (ch == '='.code && depth == 0) {
				eqIdx = i;
				break;
			}
		}

		var defaultValue:Null<String> = null;
		var typeAndName = p;
		if (eqIdx >= 0) {
			defaultValue = p.substring(eqIdx + 1).trim();
			typeAndName = p.substring(0, eqIdx).trim();
			// Strip surrounding quotes from string defaults
			if (defaultValue.length >= 2 && defaultValue.charAt(0) == '"' && defaultValue.charAt(defaultValue.length - 1) == '"')
				defaultValue = defaultValue.substring(1, defaultValue.length - 1);
		}

		// Check for enum type: name:[v1,v2] or name[v1,v2]
		var colonIdx = typeAndName.indexOf(":");
		var bracketIdx = typeAndName.indexOf("[");

		if (bracketIdx >= 0 && (colonIdx < 0 || bracketIdx < colonIdx)) {
			// Enum type
			var name:String;
			if (colonIdx >= 0 && colonIdx < bracketIdx)
				name = typeAndName.substring(0, colonIdx).trim();
			else
				name = typeAndName.substring(0, bracketIdx).trim();

			var closeIdx = typeAndName.lastIndexOf("]");
			if (closeIdx < 0)
				return null;

			var valuesStr = typeAndName.substring(bracketIdx + 1, closeIdx).trim();
			var values = [for (s in valuesStr.split(",")) s.trim()];

			return {name: name, type: PTEnum(values), defaultValue: defaultValue};
		}

		if (colonIdx < 0) {
			// No type → string with optional default
			return {name: typeAndName.trim(), type: PTString, defaultValue: defaultValue};
		}

		var name = typeAndName.substring(0, colonIdx).trim();
		var typeStr = typeAndName.substring(colonIdx + 1).trim();

		// Check range: N..M
		var rangeIdx = typeStr.indexOf("..");
		if (rangeIdx >= 0) {
			var from = Std.parseInt(typeStr.substring(0, rangeIdx));
			var to = Std.parseInt(typeStr.substring(rangeIdx + 2));
			return {
				name: name,
				type: PTRange(from != null ? from : 0, to != null ? to : 0),
				defaultValue: defaultValue
			};
		}

		var paramType = switch (typeStr.toLowerCase()) {
			case "uint": PTUInt;
			case "int": PTInt;
			case "float": PTFloat;
			case "bool": PTBool;
			case "string": PTString;
			case "color": PTColor;
			case "flags": PTFlags;
			default:
				Context.warning('Unknown parameter type "$typeStr" for param "$name", defaulting to string', Context.currentPos());
				PTString;
		};

		return {name: name, type: paramType, defaultValue: defaultValue};
	}
}
#end
