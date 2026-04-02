package bh.multianim;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import bh.multianim.MultiAnimParser;
import bh.multianim.MultiAnimParser.MultiAnimResult;
import bh.multianim.MultiAnimParser.StateAnimConstruct;
import bh.multianim.MultiAnimParser.AnimatedPathDef;
import bh.multianim.MultiAnimParser.AnimatedPathModeType;
import bh.multianim.MultiAnimParser.ParsedPaths;
import bh.multianim.MultiAnimParser.PathCoordinateMode;
import bh.multianim.MultiAnimParser.SmoothingType;
import bh.multianim.MultiAnimParser.EasingType;
import bh.multianim.MultiAnimParser.TransitionType;
import bh.multianim.MultiAnimParser.TransitionDirection;
import bh.multianim.MultiAnimParser.ReferenceableValue;
import bh.multianim.MultiAnimParser.SettingValueType;
import bh.multianim.MultiAnimParser.CurveDef;
import bh.multianim.MultiAnimParser.CurveOperation;
import bh.multianim.MultiAnimParser.CurveSegmentDef;
import bh.multianim.MultiAnimParser.CurvesDef;
import bh.multianim.MultiAnimParser.PathsDef;
import bh.multianim.MultiAnimParser.DataDef;
import bh.multianim.MultiAnimParser.DataEnumDef;
import bh.multianim.MultiAnimParser.DataValue;
import bh.multianim.MultiAnimParser.DataValueType;
import bh.multianim.MultiAnimParser.DataRecordDef;
import bh.multianim.MultiAnimParser.DataFieldDef;
import bh.multianim.CoordinateSystems;
import bh.multianim.MacroCompatTypes.MacroFlowLayout;
import bh.multianim.MacroCompatTypes.MacroFlowOverflow;
import bh.multianim.MacroCompatTypes.MacroFlowAlign;
import bh.multianim.MacroCompatTypes.MacroBlendMode;
import bh.multianim.layouts.LayoutTypes.LayoutContent;
import bh.multianim.layouts.LayoutTypes.Layout;

using StringTools;

private enum MacroSlotKey {
	Named(name:String);
	Indexed(name:String, index:Int);
	Indexed2D(name:String, indexX:Int, indexY:Int);
}

/**
 * Compile-time macro that generates typed factory + instance classes for programmable UI components from .manim definitions.
 *
 * Usage:
 *   @:build(bh.multianim.ProgrammableCodeGen.buildAll())
 *   class MyScreen extends ProgrammableBuilder {
 *       @:manim("path/to/file.manim", "buttonName") public var button;
 *   }
 *
 *   var screen = new MyScreen(resourceLoader);
 *   var btn = screen.button.create(status, text);  // returns new instance (h2d.Object)
 *   scene.addChild(btn);                           // instance IS the h2d.Object
 *   btn.setStatus(MyScreen_Button.Hover);
 *
 * For each @:manim field, two classes are generated:
 *   - Factory (e.g. MyScreen_Button) extends ProgrammableBuilder:
 *     - `create(typedParams...)` — creates a new instance with the given params
 *     - Static enum constants (e.g. Hover = 0, Pressed = 1)
 *   - Instance (e.g. MyScreen_ButtonInstance) extends h2d.Object:
 *     - `setXxx(v)` — typed setter per parameter (updates visibility + expressions)
 *     - `get_xxx()` — accessors for named elements
 * The parent class gets a constructor that initializes all factory fields.
 */
class ProgrammableCodeGen {
	static var elementCounter:Int = 0;
	static var expressionUpdates:Array<{fieldName:String, updateExpr:Expr, paramRefs:Array<String>}> = [];
	static var visibilityEntries:Array<{fieldName:String, condition:Expr, paramRefs:Array<String>, sentinelField:String, parentField:String, layer:Int, restoreFlowPropsExpr:Null<Expr>}> = [];
	static var namedElements:Map<String, Array<String>> = [];
	static var indexedNamedElements:Map<String, Array<{index:Int, fieldName:String}>> = new Map();
	static var indexed2DNamedElements:Map<String, Array<{indexX:Int, indexY:Int, fieldName:String}>> = new Map();
	static var slotEntries:Array<{key:MacroSlotKey, fieldName:String, hasParams:Bool, loopVars:Map<String, Int>}> = [];
	static var dynamicRefFields:Map<String, String> = new Map(); // component name -> BuilderResult field name
	static var hexLayoutFieldMap:Map<String, String> = new Map(); // layout key → field name
	static var hexLayoutFieldCount:Int = 0;
	static var needsLayoutAlign:Bool = false;

	static var hasBuilderParameterPlaceholders:Bool = false;

	static var paramDefs:ParametersDefinitions;
	static var paramNames:Array<String> = [];

	// Maps param name -> generated enum abstract type path (for enum/bool params)
	static var paramEnumTypes:Map<String, {typePath:String, typeName:String}> = new Map();

	// Loop variable substitutions: during repeat unrolling, maps loop var name -> current iteration value
	static var loopVarSubstitutions:Map<String, Int> = new Map();

	// Runtime loop variable mappings: maps manim var name -> runtime Haxe identifier name (for runtime iterators)
	static var runtimeLoopVars:Map<String, String> = new Map();

	// @final variable expressions: maps name -> expression for inline expansion in rvToExpr
	static var finalVarExprs:Map<String, ReferenceableValue> = new Map();

	// Repeat rebuild entries: for param-dependent repeats that need runtime rebuild when count changes
	static var repeatRebuildEntries:Array<{callExpr:Expr}> = [];

	// Conditional APPLY entries: tracks condition + apply/revert expressions for _applyVisibility()
	static var applyEntries:Array<{condition:Expr, applyExprs:Array<Expr>, revertExprs:Array<Expr>}> = [];

	// All parsed nodes from the .manim file (for looking up layouts etc.)
	static var allParsedNodes:Map<String, Node> = new Map();

	// The local class info for generating return types
	static var localClassPack:Array<String> = [];
	static var localClassName:String = ""; // factory class name
	static var instanceClassName:String = ""; // instance class name (returned by create())

	// Current manim path being processed (set per-field in buildAll, used by generateFields)
	static var currentManimPath:String = "";

	// Current programmable name being processed (set per-field in buildAll)
	static var currentProgrammableName:String = "";

	// Current node being processed (for resolving grid coordinate system in rvToExpr)
	static var currentProcessingNode:Node = null;

	// Counter for tileGroup elements within a programmable (for multi-tilegroup support)
	static var tileGroupCounter:Int = 0;

	// Counter for particles elements within a programmable (for multi-particles support)
	static var particlesCounter:Int = 0;

	// Counter for sentinel objects (position anchors for conditional elements)
	static var sentinelCounter:Int = 0;

	// Cache parsed results to avoid re-running subprocess for same file
	static var parsedCache:Map<String, Map<String, Node>> = new Map();

	// Type deduplication cache: signature → fully qualified type name (for mergeTypes)
	static var mergedTypeCache:Map<String, {pack:Array<String>, name:String}> = new Map();

	// Track generated style/image setters to avoid duplicates across text elements
	static var generatedStyleSetters:Map<String, Bool> = new Map();
	static var generatedImageSetters:Map<String, Bool> = new Map();

	// Transition declarations from the current programmable's transition{} block
	static var currentTransitions:Null<Map<String, TransitionType>> = null;

	static function resetState():Void {
		elementCounter = 0;
		expressionUpdates = [];
		visibilityEntries = [];
		namedElements = [];
		indexedNamedElements = new Map();
		indexed2DNamedElements = new Map();
		slotEntries = [];
		dynamicRefFields = new Map();
		hasBuilderParameterPlaceholders = false;
		paramDefs = new Map();
		paramNames = [];
		paramEnumTypes = new Map();
		loopVarSubstitutions = new Map();
		runtimeLoopVars = new Map();
		finalVarExprs = new Map();
		repeatRebuildEntries = [];
		applyEntries = [];
		allParsedNodes = new Map();
		currentProcessingNode = null;
		currentManimPath = "";
		currentProgrammableName = "";
		hexLayoutFieldMap = new Map();
		hexLayoutFieldCount = 0;
		needsLayoutAlign = false;
		tileGroupCounter = 0;
		particlesCounter = 0;
		sentinelCounter = 0;
		instanceClassName = "";
		generatedStyleSetters = new Map();
		generatedImageSetters = new Map();
		currentTransitions = null;
	}

	/**
	 * Multi-programmable macro: scans user-declared fields for @:manim metadata,
	 * generates a companion class per field via Context.defineType(), and adds
	 * a constructor to the parent class that initializes all fields.
	 */
	public static function buildAll():Array<Field> {
		final pos = Context.currentPos();
		final localClass = Context.getLocalClass();
		if (localClass == null) {
			Context.fatalError('ProgrammableCodeGen.buildAll(): cannot get local class', pos);
			return null;
		}

		final parentPack = localClass.get().pack;
		final parentName = localClass.get().name;
		final parentModule = localClass.get().module;

		final fields = Context.getBuildFields();
		final newFields:Array<Field> = [];
		final ctorInitExprs:Array<Expr> = [];

		for (field in fields) {
			if (field.meta == null) continue;
			for (meta in field.meta) {
				if (meta.name == ":manim" || meta.name == "manim") {
					if (meta.params == null || meta.params.length < 2) {
						Context.fatalError('ProgrammableCodeGen.buildAll(): @:manim requires (manimPath, programmableName)', field.pos);
						continue;
					}

					// Extract string arguments from metadata
					final manimPath = extractMetaString(meta.params[0]);
					final programmableName = extractMetaString(meta.params[1]);
					if (manimPath == null || programmableName == null) {
						Context.fatalError('ProgrammableCodeGen.buildAll(): @:manim arguments must be string literals', field.pos);
						continue;
					}

					// Reset codegen state for each programmable
					resetState();
					currentManimPath = manimPath;
					currentProgrammableName = programmableName;

					// Parse the .manim file
					final nodes = parseViaSubprocess(manimPath);
					if (nodes == null) continue;
					allParsedNodes = nodes;

					final node = nodes.get(programmableName);
					if (node == null) {
						Context.fatalError('ProgrammableCodeGen.buildAll(): programmable "$programmableName" not found in "$manimPath"', field.pos);
						continue;
					}

					switch (node.type) {
						case PROGRAMMABLE(isTileGroup, parameters, paramOrder):
							paramDefs = parameters;
							for (name in paramOrder)
								paramNames.push(name);
						default:
							Context.fatalError('ProgrammableCodeGen.buildAll(): "$programmableName" is not a programmable', field.pos);
							continue;
					}

					// Factory class name: ParentName_FieldName
					final factoryName = parentName + "_" + toPascalCase(field.name);
					final instName = factoryName + "Instance";

					// Set class info for generateFields to use
					localClassPack = parentPack;
					localClassName = factoryName;
					instanceClassName = instName;

					classifyParamTypes();

					// Store transition declarations for codegen
					currentTransitions = node.transitions;

					// Generate fields for both factory and instance classes
					final result = generateFields(node);

					// Define the instance type (extends h2d.Object — IS the root)
					final instTd:TypeDefinition = {
						pack: parentPack,
						name: instName,
						pos: pos,
						kind: TDClass(
							needsLayoutAlign
								? {pack: ["bh", "multianim"], name: "LayoutAlignRoot"}
								: {pack: ["h2d"], name: "Object"},
							null, false, false, false
						),
						fields: result.instanceFields,
						meta: [{name: ":allow", params: [macro bh.multianim.ProgrammableCodeGen], pos: pos}, {name: ":keep", params: null, pos: pos}],
					};
					Context.defineType(instTd);

					// Define the factory type (extends ProgrammableBuilder — has resource loading helpers)
					final factoryTd:TypeDefinition = {
						pack: parentPack,
						name: factoryName,
						pos: pos,
						kind: TDClass({pack: ["bh", "multianim"], name: "ProgrammableBuilder"}, null, false, false, false),
						fields: result.factoryFields,
						meta: [{name: ":allow", params: [macro bh.multianim.ProgrammableCodeGen], pos: pos}],
					};
					Context.defineType(factoryTd);

					// Update the field's type to the factory class
					final factoryTypePath = {pack: parentPack, name: factoryName};
					field.kind = FVar(TPath(factoryTypePath), null);

					// Track factory info for parent constructor generation
					final factoryNewExpr:Expr = {
						expr: ENew({pack: parentPack, name: factoryName}, [macro this.resourceLoader]),
						pos: pos,
					};
					final fieldRef = macro $p{["this", field.name]};
					ctorInitExprs.push(macro $fieldRef = $factoryNewExpr);

				} else if (meta.name == ":data" || meta.name == "data") {
					if (meta.params == null || meta.params.length < 2) {
						Context.fatalError('ProgrammableCodeGen.buildAll(): @:data requires (manimPath, dataName)', field.pos);
						continue;
					}

					final manimPath = extractMetaString(meta.params[0]);
					final dataName = extractMetaString(meta.params[1]);
					if (manimPath == null || dataName == null) {
						Context.fatalError('ProgrammableCodeGen.buildAll(): @:data arguments must be string literals', field.pos);
						continue;
					}

					// Optional 3rd param: typepackage (string)
					var typePack = parentPack;
					if (meta.params.length >= 3) {
						final tp = extractMetaString(meta.params[2]);
						if (tp != null) typePack = tp.length > 0 ? tp.split(".") : [];
					}

					// Optional: mergeTypes flag (identifier)
					var mergeTypes = false;
					for (i in 2...meta.params.length) {
						switch (meta.params[i].expr) {
							case EConst(CIdent("mergeTypes")):
								mergeTypes = true;
							default:
						}
					}

					// Parse the .manim file (reuses same cache as @:manim)
					final nodes = parseViaSubprocess(manimPath);
					if (nodes == null) continue;

					final node = nodes.get(dataName);
					if (node == null) {
						Context.fatalError('ProgrammableCodeGen.buildAll(): data "$dataName" not found in "$manimPath"', field.pos);
						continue;
					}

					switch (node.type) {
						case DATA(dataDef):
							final dataClassName = parentName + "_" + toPascalCase(field.name);
							final dataFields = generateDataClass(dataDef, dataName, dataClassName, typePack, mergeTypes, pos);

							// Define the data class
							final dataTd:TypeDefinition = {
								pack: parentPack,
								name: dataClassName,
								pos: pos,
								kind: TDClass(null, null, false, false, false),
								fields: dataFields,
							};
							Context.defineType(dataTd);

							// Update the field type to the data class
							field.kind = FVar(TPath({pack: parentPack, name: dataClassName}), null);

							// Add initialization to constructor
							final dataNewExpr:Expr = {
								expr: ENew({pack: parentPack, name: dataClassName}, []),
								pos: pos,
							};
							final fieldRef = macro $p{["this", field.name]};
							ctorInitExprs.push(macro $fieldRef = $dataNewExpr);

						default:
							Context.fatalError('ProgrammableCodeGen.buildAll(): "$dataName" is not a data block', field.pos);
							continue;
					}
				}
			}
		}

		// Generate parent constructor that initializes all @:manim fields
		newFields.push({
			name: "new",
			kind: FFun({
				args: [{name: "resourceLoader", type: macro :bh.base.ResourceLoader}],
				ret: null,
				expr: macro {
					super(resourceLoader);
					$b{ctorInitExprs};
				},
			}),
			access: [APublic],
			pos: pos,
		});

		return fields.concat(newFields);
	}

	/** Extract a string literal from a macro expression */
	static function extractMetaString(e:Expr):Null<String> {
		return switch (e.expr) {
			case EConst(CString(s, _)): s;
			default: null;
		};
	}

	/** Classify params and record which ones need enum constants or Bool conversion */
	static function classifyParamTypes():Void {
		for (name in paramNames) {
			final def = paramDefs.get(name);
			switch (def.type) {
				case PPTEnum(_):
					paramEnumTypes.set(name, {typePath: "enum", typeName: toPascalCase(name)});
				case PPTBool:
					paramEnumTypes.set(name, {typePath: "Bool", typeName: "Bool"});
				default:
			}
		}
	}

	/** Generate static inline constants for enum params directly on the class.
	 *  e.g. status:[hover, pressed, normal] → static inline var Hover = 0; etc. */
	static function generateEnumConstants(fields:Array<Field>, pos:Position):Void {
		for (name in paramNames) {
			final def = paramDefs.get(name);
			switch (def.type) {
				case PPTEnum(values):
					for (i in 0...values.length) {
						fields.push({
							pos: pos,
							name: toPascalCase(values[i]),
							access: [APublic, AStatic, AInline],
							kind: FVar(macro :Int, macro $v{i}),
						});
					}
				default:
			}
		}
	}

	static function parseViaSubprocess(manimPath:String):Map<String, Node> {
		// Check cache first
		if (parsedCache.exists(manimPath))
			return parsedCache.get(manimPath);

		// Read .manim file content and parse inline (no subprocess needed)
		final content = try sys.io.File.getContent(manimPath) catch (e:Dynamic) {
			Context.fatalError('ProgrammableCodeGen: could not read "$manimPath": $e', Context.currentPos());
			return null;
		};

		final result:MultiAnimResult = try {
			MacroManimParser.parseFile(content, manimPath);
		} catch (e:Dynamic) {
			Context.fatalError('ProgrammableCodeGen: parse error in "$manimPath": $e', Context.currentPos());
			return null;
		};

		// Cache for reuse
		parsedCache.set(manimPath, result.nodes);
		return result.nodes;
	}

	// ==================== Field Generation ====================

	static function generateFields(rootNode:Node):{instanceFields:Array<Field>, factoryFields:Array<Field>} {
		final instanceFields:Array<Field> = [];
		final factoryFields:Array<Field> = [];
		final pos = Context.currentPos();

		// ============ Instance class fields (extends h2d.Object) ============

		// 1. _pb reference to ProgrammableBuilder (for runtime builder calls)
		instanceFields.push(makeField("_pb", FVar(macro :bh.multianim.ProgrammableBuilder, null), [APrivate], pos));

		// 1b. _transHelper field when transitions exist
		final hasTransitions = currentTransitions != null && currentTransitions.iterator().hasNext();
		if (hasTransitions)
			instanceFields.push(makeField("_transHelper", FVar(macro :Null<bh.multianim.CodegenTransitionHelper>, null), [APrivate], pos));

		// 2. Parameter fields
		for (name in paramNames) {
			final def = paramDefs.get(name);
			final fieldType = paramFieldType(def.type);
			instanceFields.push(makeField("_" + name, FVar(fieldType, null), [APrivate], pos));
		}

		// 3. Element fields + constructor body
		// Note: processChildren adds element fields to instanceFields,
		// and tree-building exprs use _pb for ProgrammableBuilder methods
		final constructorExprs:Array<Expr> = [];

		for (name in paramNames) {
			final paramField = "_" + name;
			constructorExprs.push(macro $p{["this", paramField]} = $i{paramField});
		}

		// Process children — parentField=null means add directly to this (the h2d.Object root)
		if (rootNode.children != null)
			processChildren(rootNode.children, null, instanceFields, constructorExprs, null, pos);

		// 3b. Multi-element named: create ProgrammableUpdatable fields + init
		for (name => elementFieldsList in namedElements) {
			if (elementFieldsList.length > 1) {
				final namedField = "_named_" + name;
				instanceFields.push(makeField(namedField, FVar(macro :bh.multianim.ProgrammableUpdatable, null), [APrivate], pos));
				var arrayExprs = elementFieldsList.map(ef -> macro $p{["this", ef]});
				final arrayLiteral:Expr = {expr: EArrayDecl(arrayExprs), pos: pos};
				constructorExprs.push(macro $p{["this", namedField]} = new bh.multianim.ProgrammableUpdatable($arrayLiteral));
			}
		}

		// 4. _applyVisibility(?_changedParam)
		// Collect the set of param names that have transitions
		final transParamNames:Map<String, Bool> = new Map();
		if (hasTransitions) {
			for (pName in currentTransitions.keys())
				transParamNames.set(pName, true);
		}

		final visExprs:Array<Expr> = [];
		for (entry in visibilityEntries) {
			final fieldRef = macro $p{["this", entry.fieldName]};
			final sentinelRef = entry.sentinelField != null ? macro $p{["this", entry.sentinelField]} : null;
			final parentRef = entry.parentField != null ? macro $p{["this", entry.parentField]} : macro this;
			// Check if this entry's paramRefs intersect with transition-declared params
			var usesTransition = false;
			if (hasTransitions) {
				for (ref in entry.paramRefs) {
					if (transParamNames.exists(ref)) { usesTransition = true; break; }
				}
			}
			if (sentinelRef != null) {
				// Scene graph add/remove via sentinel
				var addExpr = if (entry.layer != -1) {
					final layerVal = entry.layer;
					macro {
						final _lp = cast($parentRef, h2d.Layers);
						final _si = _lp.getChildIndexInLayer($sentinelRef);
						_lp.add($fieldRef, $v{layerVal}, _si + 1);
					};
				} else {
					macro $parentRef.addChildAt($fieldRef, $parentRef.getChildIndex($sentinelRef) + 1);
				};
				// Append flow property restore after re-add (Flow.removeChild discards FlowProperties)
				if (entry.restoreFlowPropsExpr != null) {
					final restoreExpr = entry.restoreFlowPropsExpr;
					addExpr = macro { $addExpr; $restoreExpr; };
				}
				if (usesTransition) {
					final transRestoreExpr = entry.restoreFlowPropsExpr;
					visExprs.push(macro {
						final _newVis = ${entry.condition};
						if (this._transHelper != null && _changedParam != null && this._transHelper.tweenManager != null) {
							this._transHelper.setPresenceWithTransition($fieldRef, _newVis, _changedParam, $parentRef, $sentinelRef);
							${if (transRestoreExpr != null) macro { if ($fieldRef.parent != null) $transRestoreExpr; } else macro {}}
						} else {
							final _inGraph = $fieldRef.parent != null;
							if (_newVis && !_inGraph)
								$addExpr
							else if (!_newVis && _inGraph)
								$parentRef.removeChild($fieldRef);
						}
					});
				} else {
					visExprs.push(macro {
						final _newVis = ${entry.condition};
						final _inGraph = $fieldRef.parent != null;
						if (_newVis && !_inGraph)
							$addExpr
						else if (!_newVis && _inGraph)
							$parentRef.removeChild($fieldRef);
					});
				}
			} else {
				// Fallback: visibility toggle (no sentinel — shouldn't happen in practice)
				if (usesTransition) {
					visExprs.push(macro {
						final _newVis = ${entry.condition};
						if (this._transHelper != null && _changedParam != null && this._transHelper.tweenManager != null)
							this._transHelper.setVisibilityWithTransition($fieldRef, _newVis, _changedParam)
						else
							$fieldRef.visible = _newVis;
					});
				} else {
					visExprs.push(macro $fieldRef.visible = ${entry.condition});
				}
			}
		}
		// Repeat rebuild: call rebuild method when count param changes
		for (entry in repeatRebuildEntries) {
			visExprs.push(entry.callExpr);
		}
		// Conditional APPLY: apply or revert parent properties based on condition
		for (entry in applyEntries) {
			final cond = entry.condition;
			final applyBlock = macro $b{entry.applyExprs};
			final revertBlock = macro $b{entry.revertExprs};
			visExprs.push(macro if ($cond) $applyBlock else $revertBlock);
		}
		if (visExprs.length == 0)
			visExprs.push(macro {});
		// When transitions exist, _applyVisibility takes optional param name
		final visArgs:Array<FunctionArg> = [];
		if (hasTransitions)
			visArgs.push({name: "_changedParam", type: macro :String, opt: true, value: null});
		instanceFields.push(makeMethod("_applyVisibility", visExprs, visArgs, macro :Void, [APrivate], pos));

		// 5. _updateExpressions()
		final exprUpdateExprs:Array<Expr> = [];
		for (update in expressionUpdates) {
			exprUpdateExprs.push(update.updateExpr);
		}
		if (exprUpdateExprs.length == 0)
			exprUpdateExprs.push(macro {});
		instanceFields.push(makeMethod("_updateExpressions", exprUpdateExprs, [], macro :Void, [APrivate], pos));

		// 6. Pre-constructor: push slot/dynamicRef init expressions to constructorExprs
		// (slotEntries and dynamicRefFields are already populated from processChildren)
		for (entry in slotEntries) {
			final handleField = slotHandleFieldName(entry.key);
			if (entry.hasParams) {
				// Parameterized slot: delegate building to runtime builder via ProgrammableBuilder
				final slotName:String = switch entry.key {
					case Named(name): name;
					case Indexed(baseName, _): baseName;
					case Indexed2D(baseName, _, _): baseName;
				};
				final progNameExpr:Expr = macro $v{currentProgrammableName};
				final slotNameExpr:Expr = macro $v{slotName};
				final containerExpr:Expr = macro $p{["this", entry.fieldName]};

				// Build parent params map with all programmable parameters + loop variables
				final mapExprs:Array<Expr> = [macro final _slotPP = new Map<String, Dynamic>()];
				for (pn in paramNames) {
					final keyExpr:Expr = macro $v{pn};
					mapExprs.push(macro _slotPP.set($keyExpr, $p{["this", "_" + pn]}));
				}
				for (loopVar => loopVal in entry.loopVars) {
					final keyExpr:Expr = macro $v{loopVar};
					final valExpr:Expr = macro $v{loopVal};
					mapExprs.push(macro _slotPP.set($keyExpr, $valExpr));
				}
				mapExprs.push(macro $p{["this", handleField]} = this._pb.buildParameterizedSlot($progNameExpr, $slotNameExpr, _slotPP, $containerExpr));
				constructorExprs.push(macro $b{mapExprs});
			} else {
				constructorExprs.push(macro {
					var _ct:Null<h2d.Object> = null;
					final _sc = $p{["this", entry.fieldName]};
					for (_ci in 0..._sc.numChildren) {
						if (Std.downcast(_sc.getChildAt(_ci), bh.multianim.MultiAnimBuilder.SlotContentRoot) != null) {
							_ct = _sc.getChildAt(_ci);
							break;
						}
					}
					$p{["this", handleField]} = new bh.multianim.MultiAnimBuilder.SlotHandle(_sc, null, _ct);
				});
			}
		}

		// 6b. Transition helper initialization
		if (hasTransitions) {
			constructorExprs.push(generateTransitionHelperInit(pos));
		}

		// 7. Instance constructor: (pb, params...) -> builds tree
		instanceFields.push(generateInstanceConstructor(constructorExprs, pos));

		// 8. Typed setters (on instance)
		for (name in paramNames) {
			final def = paramDefs.get(name);
			final paramField = "_" + name;
			final setterExprs:Array<Expr> = [];

			// For bool params, convert Bool -> Int (true=1, false=0 matching parser convention)
			if (paramEnumTypes.exists(name) && paramEnumTypes.get(name).typePath == "Bool") {
				setterExprs.push(macro $p{["this", paramField]} = ($i{"v"} ? 1 : 0));
			} else {
				setterExprs.push(macro $p{["this", paramField]} = $i{"v"});
			}
			// Pass param name to _applyVisibility when transitions exist for this param
			if (hasTransitions && transParamNames.exists(name)) {
				final nameStr = name;
				setterExprs.push(macro this._applyVisibility($v{nameStr}));
			} else {
				setterExprs.push(macro this._applyVisibility());
			}

			var refsParam = false;
			for (update in expressionUpdates) {
				if (update.paramRefs.contains(name)) {
					refsParam = true;
					break;
				}
			}
			if (refsParam)
				setterExprs.push(macro this._updateExpressions());

			final setterParamType = publicParamType(name, def.type);
			instanceFields.push(makeMethod("set" + toPascalCase(name), setterExprs, [{name: "v", type: setterParamType}], macro :Void, [APublic], pos));
		}

		// 8b. Transition control methods (on instance)
		if (hasTransitions) {
			instanceFields.push(makeMethod("setTweenManager", [
				macro { if (this._transHelper != null) this._transHelper.tweenManager = tm; }
			], [{name: "tm", type: macro :Null<bh.base.TweenManager>}], macro :Void, [APublic], pos));
			instanceFields.push(makeMethod("cancelAllTransitions", [
				macro { if (this._transHelper != null) this._transHelper.cancelAllTransitions(); }
			], [], macro :Void, [APublic], pos));
		}

		// 8c. Named element accessors (on instance)
		for (name => elementFieldsList in namedElements) {
			// Skip names that have indexed accessors — they get the indexed get_name(index/x,y) method instead
			if (indexedNamedElements.exists(name) || indexed2DNamedElements.exists(name))
				continue;
			if (elementFieldsList.length == 1) {
				final ef = elementFieldsList[0];
				instanceFields.push(makeMethod("get_" + name, [macro return $p{["this", ef]}], [], macro :h2d.Object, [APublic], pos));
			} else if (elementFieldsList.length > 1) {
				final namedField = "_named_" + name;
				instanceFields.push(makeMethod("get_" + name, [macro return $p{["this", namedField]}], [],
					macro :bh.multianim.IUpdatable, [APublic], pos));
			}
		}

		// 8b. Indexed named element accessors: get_name(index:Int):h2d.Object
		for (name => indexedList in indexedNamedElements) {
			// Build switch cases: case 0: return this._e5; case 1: return this._e8; ...
			final switchCases:Array<Case> = [];
			for (entry in indexedList) {
				switchCases.push({
					values: [macro $v{entry.index}],
					expr: macro return $p{["this", entry.fieldName]},
				});
			}
			final switchExpr:Expr = {
				expr: ESwitch(macro index, switchCases, macro return null),
				pos: pos,
			};
			instanceFields.push(makeMethod("get_" + name, [switchExpr], [{name: "index", type: macro :Int}], macro :h2d.Object, [APublic], pos));
		}

		// 8b2. 2D Indexed named element accessors: get_name(x:Int, y:Int):h2d.Object
		for (name => indexedList in indexed2DNamedElements) {
			final ifExprs:Array<Expr> = [];
			for (entry in indexedList) {
				ifExprs.push(macro if (x == $v{entry.indexX} && y == $v{entry.indexY}) return $p{["this", entry.fieldName]});
			}
			ifExprs.push(macro return null);
			instanceFields.push(makeMethod("get_" + name, ifExprs, [
				{name: "x", type: macro :Int},
				{name: "y", type: macro :Int},
			], macro :h2d.Object, [APublic], pos));
		}

		// 8c. Slot accessors (on instance) — init expressions already pushed to constructorExprs in step 6
		// Collect indexed slot base names and their entries
		final indexedSlotGroups:Map<String, Array<{index:Int, fieldName:String}>> = new Map();
		final indexed2DSlotGroups:Map<String, Array<{indexX:Int, indexY:Int, fieldName:String}>> = new Map();
		final namedSlots:Array<{name:String, fieldName:String}> = [];
		for (entry in slotEntries) {
			switch entry.key {
				case Indexed(baseName, index):
					var list = indexedSlotGroups.get(baseName);
					if (list == null) {
						list = [];
						indexedSlotGroups.set(baseName, list);
					}
					list.push({index: index, fieldName: entry.fieldName});
				case Indexed2D(baseName, indexX, indexY):
					var list = indexed2DSlotGroups.get(baseName);
					if (list == null) {
						list = [];
						indexed2DSlotGroups.set(baseName, list);
					}
					list.push({indexX: indexX, indexY: indexY, fieldName: entry.fieldName});
				case Named(name):
					namedSlots.push({name: name, fieldName: entry.fieldName});
			}
		}
		// All slot entries get private handle fields
		for (entry in slotEntries) {
			final handleField = slotHandleFieldName(entry.key);
			instanceFields.push(makeField(handleField, FVar(macro :bh.multianim.MultiAnimBuilder.SlotHandle, null), [APrivate], pos));
		}
		// Non-indexed: typed getSlot_name() accessor
		for (ns in namedSlots) {
			final handleField = "_slotHandle_" + ns.name;
			instanceFields.push(makeMethod("getSlot_" + ns.name, [macro return $p{["this", handleField]}], [],
				macro :bh.multianim.MultiAnimBuilder.SlotHandle, [APublic], pos));
		}
		// 1D Indexed: typed getSlot_name(index:Int) accessor with switch
		for (baseName => indexedList in indexedSlotGroups) {
			final switchCases:Array<Case> = [];
			for (entry in indexedList) {
				final handleField = "_slotHandle_" + baseName + "_" + entry.index;
				switchCases.push({
					values: [macro $v{entry.index}],
					expr: macro return $p{["this", handleField]},
				});
			}
			final switchExpr:Expr = {
				expr: ESwitch(macro index, switchCases, macro return null),
				pos: pos,
			};
			instanceFields.push(makeMethod("getSlot_" + baseName, [switchExpr], [{name: "index", type: macro :Int}],
				macro :bh.multianim.MultiAnimBuilder.SlotHandle, [APublic], pos));
		}
		// 2D Indexed: typed getSlot_name(x:Int, y:Int) accessor with if-chain
		for (baseName => indexedList in indexed2DSlotGroups) {
			final ifExprs:Array<Expr> = [];
			for (entry in indexedList) {
				final handleField = slotHandleFieldName(Indexed2D(baseName, entry.indexX, entry.indexY));
				ifExprs.push(macro if (x == $v{entry.indexX} && y == $v{entry.indexY}) return $p{["this", handleField]});
			}
			ifExprs.push(macro return null);
			instanceFields.push(makeMethod("getSlot_" + baseName, ifExprs, [
				{name: "x", type: macro :Int},
				{name: "y", type: macro :Int},
			], macro :bh.multianim.MultiAnimBuilder.SlotHandle, [APublic], pos));
		}
		// Generic getSlot(name:String, ?index:Null<Int>, ?indexY:Null<Int>) dispatcher
		if (slotEntries.length > 0) {
			final bodyExprs:Array<Expr> = [];

			// Handle 2D indexed slots: require both index and indexY
			for (baseName => indexedList in indexed2DSlotGroups) {
				final ifCases:Array<Expr> = [];
				for (entry in indexedList) {
					final handleField = slotHandleFieldName(Indexed2D(baseName, entry.indexX, entry.indexY));
					ifCases.push(macro if (index == $v{entry.indexX} && indexY == $v{entry.indexY}) return $p{["this", handleField]});
				}
				final notFoundMsg = 'Slot "' + baseName + '" index (';
				ifCases.push(macro throw $v{notFoundMsg} + index + ', ' + indexY + ') not found');
				bodyExprs.push(macro if (name == $v{baseName}) {
					if (index == null || indexY == null)
						throw 'Slot "' + $v{baseName} + '" is 2D-indexed — use getSlot("' + $v{baseName} + '", x, y)';
					$b{ifCases};
				});
			}

			// Handle 1D indexed slots: require index parameter
			for (baseName => indexedList in indexedSlotGroups) {
				final indexCases:Array<Case> = [];
				for (entry in indexedList) {
					final handleField = "_slotHandle_" + baseName + "_" + entry.index;
					indexCases.push({
						values: [macro $v{entry.index}],
						expr: macro return $p{["this", handleField]},
					});
				}
				final notFoundMsg = 'Slot "$baseName" index ';
				final indexSwitch:Expr = {
					expr: ESwitch(macro index, indexCases, macro throw $v{notFoundMsg} + index + ' not found'),
					pos: pos,
				};
				bodyExprs.push(macro if (name == $v{baseName}) {
					if (index == null)
						throw 'Slot "' + $v{baseName} + '" is indexed — use getSlot("' + $v{baseName} + '", index)';
					$indexSwitch;
				});
			}

			// Handle non-indexed slots: reject index parameter
			for (ns in namedSlots) {
				final handleField = "_slotHandle_" + ns.name;
				bodyExprs.push(macro if (name == $v{ns.name}) {
					if (index != null)
						throw 'Slot "' + $v{ns.name} + '" is not indexed — use getSlot("' + $v{ns.name} + '") without index';
					return $p{["this", handleField]};
				});
			}

			bodyExprs.push(macro throw 'Slot "' + name + '" not found');
			instanceFields.push(makeMethod("getSlot", bodyExprs, [
				{name: "name", type: macro :String},
				{name: "index", opt: true, type: macro :Null<Int>},
				{name: "indexY", opt: true, type: macro :Null<Int>},
			], macro :bh.multianim.MultiAnimBuilder.SlotHandle, [APublic], pos));
		}

		// 8d. DynamicRef accessors (on instance)
		for (refName => resultField in dynamicRefFields) {
			instanceFields.push(makeField(resultField, FVar(macro :bh.multianim.MultiAnimBuilder.BuilderResult, null), [APrivate], pos));
		}
		if (Lambda.count(dynamicRefFields) > 0) {
			final refCases:Array<Case> = [];
			for (refName => resultField in dynamicRefFields) {
				refCases.push({
					values: [macro $v{refName}],
					expr: macro return $p{["this", resultField]},
				});
			}
			final refSwitch:Expr = {
				expr: ESwitch(macro name, refCases, macro return null),
				pos: pos,
			};
			instanceFields.push(makeMethod("getDynamicRef", [refSwitch], [{name: "name", type: macro :String}],
				macro :bh.multianim.MultiAnimBuilder.BuilderResult, [APublic], pos));
		}

		// ============ Factory class fields (extends ProgrammableBuilder) ============

		// Static inline enum constants (e.g. Hover = 0, Pressed = 1, Normal = 2)
		generateEnumConstants(factoryFields, pos);

		// Factory constructor (just resourceLoader)
		final factoryCtor:Array<Expr> = [macro super(resourceLoader)];
		factoryFields.push(makeMethod("new", factoryCtor, [{name: "resourceLoader", type: macro :bh.base.ResourceLoader}], null, [APublic], pos));

		// Factory create() — loads builder, creates new instance, returns it
		factoryFields.push(generateFactoryCreate(pos));

		// Factory createFrom() — struct-based named parameters alternative
		factoryFields.push(generateFactoryCreateFrom(pos));

		// Generate path/curve/animatedPath factory methods from sibling root nodes
		if (allParsedNodes != null) {
			for (nodeName => node in allParsedNodes) {
				switch (node.type) {
					case PATHS(pathsDef):
						generatePathsFactoryMethods(pathsDef, factoryFields, pos);
					case ANIMATED_PATH(apDef):
						generateAnimatedPathFactoryMethod(nodeName, apDef, factoryFields, pos);
					case CURVES(curvesDef):
						generateCurvesFactoryMethods(curvesDef, factoryFields, pos);
					default:
				}
			}
		}

		return {instanceFields: instanceFields, factoryFields: factoryFields};
	}

	// ==================== Node Processing ====================

	static function processChildren(children:Array<Node>, parentField:String, fields:Array<Field>, ctorExprs:Array<Expr>, siblingConditions:Array<{node:Node, fieldName:String}>, pos:Position):Void {
		var siblings:Array<{node:Node, fieldName:String}> = if (siblingConditions != null) siblingConditions else [];
		for (child in children) {
			processNode(child, parentField, fields, ctorExprs, siblings, pos);
		}
	}

	static function processNode(node:Node, parentField:String, fields:Array<Field>, ctorExprs:Array<Expr>, siblings:Array<{node:Node, fieldName:String}>, pos:Position):Void {
		currentProcessingNode = node;
		// Handle REPEAT/REPEAT2D specially — they unroll or pool children
		switch (node.type) {
			case REPEAT(varName, repeatType):
				processRepeat(node, varName, repeatType, parentField, fields, ctorExprs, siblings, pos);
				return;
			case REPEAT2D(varNameX, varNameY, repeatTypeX, repeatTypeY):
				processRepeat2D(node, varNameX, varNameY, repeatTypeX, repeatTypeY, parentField, fields, ctorExprs, siblings, pos);
				return;
			case APPLY:
				switch (node.conditionals) {
					case NoConditional:
						processApply(node, parentField, fields, ctorExprs, pos);
						return;
					default:
						processConditionalApply(node, parentField, fields, ctorExprs, siblings, pos);
						return;
				}
			case FINAL_VAR(name, expr):
				finalVarExprs.set(name, expr);
				return;
			default:
		}

		final fieldName = "_e" + (elementCounter++);
		final createResult = generateCreateExpr(node, fieldName, pos);
		if (createResult == null)
			return;

		fields.push(makeField(fieldName, FVar(createResult.fieldType, null), [APrivate], pos));
		for (expr in createResult.createExprs)
			ctorExprs.push(expr);
		if (createResult.extraFields != null) {
			for (ef in createResult.extraFields)
				fields.push(ef);
		}

		// Position
		ensureHexLayoutIfNeeded(node.pos, node, fields, ctorExprs, pos);
		final posExpr = generatePositionExpr(node.pos, fieldName, pos, node);
		if (posExpr != null)
			ctorExprs.push(posExpr);

		// Scale
		if (node.scale != null) {
			final scaleExpr = rvToExpr(node.scale);
			final fieldRef = macro $p{["this", fieldName]};
			final scaleUpdateExpr = macro {
				final s = $scaleExpr;
				$fieldRef.scaleX = s;
				$fieldRef.scaleY = s;
			};
			ctorExprs.push(scaleUpdateExpr);

			final scaleRefs = collectParamRefs(node.scale);
			if (scaleRefs.length > 0) {
				expressionUpdates.push({
					fieldName: fieldName,
					updateExpr: scaleUpdateExpr,
					paramRefs: scaleRefs,
				});
			}
		}

		// Rotation
		if (node.rotation != null) {
			final rotExpr = rvToExpr(node.rotation);
			final fieldRef = macro $p{["this", fieldName]};
			final rotUpdateExpr = macro $fieldRef.rotation = hxd.Math.degToRad($rotExpr);
			ctorExprs.push(rotUpdateExpr);

			final rotRefs = collectParamRefs(node.rotation);
			if (rotRefs.length > 0) {
				expressionUpdates.push({
					fieldName: fieldName,
					updateExpr: rotUpdateExpr,
					paramRefs: rotRefs,
				});
			}
		}

		// Alpha
		if (node.alpha != null) {
			final alphaExpr = rvToExpr(node.alpha);
			final fieldRef = macro $p{["this", fieldName]};
			final alphaUpdateExpr = macro $fieldRef.alpha = $alphaExpr;
			ctorExprs.push(alphaUpdateExpr);

			final alphaRefs = collectParamRefs(node.alpha);
			if (alphaRefs.length > 0) {
				expressionUpdates.push({
					fieldName: fieldName,
					updateExpr: alphaUpdateExpr,
					paramRefs: alphaRefs,
				});
			}
		}

		// BlendMode
		if (node.blendMode != null) {
			final fieldRef = macro $p{["this", fieldName]};
			final bmExpr:Expr = switch (node.blendMode) {
				case MBNone: macro h2d.BlendMode.None;
				case MBAlpha: macro h2d.BlendMode.Alpha;
				case MBAdd: macro h2d.BlendMode.Add;
				case MBAlphaAdd: macro h2d.BlendMode.AlphaAdd;
				case MBSoftAdd: macro h2d.BlendMode.SoftAdd;
				case MBMultiply: macro h2d.BlendMode.Multiply;
				case MBAlphaMultiply: macro h2d.BlendMode.AlphaMultiply;
				case MBErase: macro h2d.BlendMode.Erase;
				case MBScreen: macro h2d.BlendMode.Screen;
				case MBSub: macro h2d.BlendMode.Sub;
				case MBMax: macro h2d.BlendMode.Max;
				case MBMin: macro h2d.BlendMode.Min;
			};
			ctorExprs.push(macro $fieldRef.blendMode = $bmExpr);
		}

		// Tint
		if (node.tint != null) {
			final tintExpr = rvToExpr(node.tint);
			final fieldRef = macro $p{["this", fieldName]};
			final tintUpdateExpr = macro {
				final _obj = $fieldRef;
				if (Std.isOfType(_obj, h2d.Drawable)) {
					final d:h2d.Drawable = cast _obj;
					var c:Int = $tintExpr;
					if (c >>> 24 == 0) c |= 0xFF000000;
					d.color.setColor(c);
				}
			};
			ctorExprs.push(tintUpdateExpr);

			// Tint expression updates: if tint has $param references, update on setter calls
			final tintRefs = collectParamRefs(node.tint);
			if (tintRefs.length > 0) {
				expressionUpdates.push({
					fieldName: fieldName,
					updateExpr: tintUpdateExpr,
					paramRefs: tintRefs,
				});
			}
		}

		// Filters
		if (node.filter != null) {
			final filterExpr = generateFilterExpr(node.filter, pos);
			if (filterExpr != null) {
				final fieldRef = macro $p{["this", fieldName]};
				ctorExprs.push(macro $fieldRef.filter = $filterExpr);

				// Filter expression updates: if filter has $param references, update on setter calls
				final filterRefs = collectFilterParamRefs(node.filter);
				if (filterRefs.length > 0) {
					expressionUpdates.push({
						fieldName: fieldName,
						updateExpr: macro $fieldRef.filter = $filterExpr,
						paramRefs: filterRefs,
					});
				}
			}
		}

		// Position expression updates: if position has $param references, add to expressionUpdates
		if (node.pos != null) {
			final posParamRefs = collectPositionParamRefs(node.pos);
			if (posParamRefs.length > 0) {
				final posUpdate = generatePositionExpr(node.pos, fieldName, pos, node);
				if (posUpdate != null) {
					expressionUpdates.push({
						fieldName: fieldName,
						updateExpr: posUpdate,
						paramRefs: posParamRefs,
					});
				}
			}
		}

		// Create sentinel before adding conditional element to parent
		final sentinelName = createSentinelIfConditional(node, parentField, fields, ctorExprs, pos);

		// Add to parent (parentField == null means add to this directly)
		final parentRef = parentField != null ? (macro $p{["this", parentField]}) : (macro this);
		final fieldRef = macro $p{["this", fieldName]};
		if (node.layer != null && node.layer != -1) {
			final layerVal:Int = node.layer;
			ctorExprs.push(macro {
				final layersParent = cast($parentRef, h2d.Layers);
				layersParent.add($fieldRef, $v{layerVal});
			});
		} else {
			ctorExprs.push(macro $parentRef.addChild($fieldRef));
		}

		// Set flow properties for spacer and per-element flow annotations after addChild
		var flowRestoreExpr:Null<Expr> = null;
		{
			final fp = node.flowProperties;
			final isSpacer = node.type.match(SPACER(_, _));

			if (isSpacer || fp != null) {
				if (parentField == null) {
					Context.error(isSpacer ? 'spacer used outside of flow' : 'per-element flow properties used outside of flow', pos);
				}
				final propStmts:Array<Expr> = [];
				propStmts.push(macro final _fp = Std.downcast($parentRef, h2d.Flow));
				propStmts.push(macro if (_fp == null) throw $v{isSpacer ? 'spacer used outside of flow' : 'per-element flow properties used outside of flow'});
				propStmts.push(macro final _props = _fp.getProperties($fieldRef));
				switch (node.type) {
					case SPACER(width, height):
						final wExpr = width != null ? rvToExpr(width) : macro 0;
						final hExpr = height != null ? rvToExpr(height) : macro 0;
						propStmts.push(macro _props.minWidth = $wExpr);
						propStmts.push(macro _props.minHeight = $hExpr);
					default:
				}
				if (fp != null) {
					if (fp.hAlign != null) propStmts.push(macro _props.horizontalAlign = ${flowAlignToExpr(fp.hAlign)});
					if (fp.vAlign != null) propStmts.push(macro _props.verticalAlign = ${flowAlignToExpr(fp.vAlign)});
					if (fp.offsetX != null) propStmts.push(macro _props.offsetX = ${rvToExpr(fp.offsetX)});
					if (fp.offsetY != null) propStmts.push(macro _props.offsetY = ${rvToExpr(fp.offsetY)});
					if (fp.isAbsolute) propStmts.push(macro _props.isAbsolute = true);
				}
				ctorExprs.push({expr: EBlock(propStmts), pos: pos});
				// Build restore expression for _applyVisibility (re-apply after addChildAt)
				if (!isSpacer && fp != null && sentinelName != null) {
					final restoreStmts:Array<Expr> = [];
					restoreStmts.push(macro final _fp = Std.downcast($parentRef, h2d.Flow));
					restoreStmts.push(macro if (_fp != null) {
						final _props = _fp.getProperties($fieldRef);
						${if (fp.hAlign != null) macro _props.horizontalAlign = ${flowAlignToExpr(fp.hAlign)} else macro {}}
						${if (fp.vAlign != null) macro _props.verticalAlign = ${flowAlignToExpr(fp.vAlign)} else macro {}}
						${if (fp.offsetX != null) macro _props.offsetX = ${rvToExpr(fp.offsetX)} else macro {}}
						${if (fp.offsetY != null) macro _props.offsetY = ${rvToExpr(fp.offsetY)} else macro {}}
						${if (fp.isAbsolute) macro _props.isAbsolute = true else macro {}}
					});
					flowRestoreExpr = {expr: EBlock(restoreStmts), pos: pos};
				}
			}
		}

		// Named element
		switch (node.updatableName) {
			case UNTObject(name) | UNTUpdatable(name):
				if (name != null && name != "") {
					var list = namedElements.get(name);
					if (list == null) {
						list = [];
						namedElements.set(name, list);
					}
					list.push(fieldName);
				}
			case UNTIndexed(name, indexVar):
				if (name != null && name != "") {
					// Also store in regular namedElements for backward compat (get_name returns all)
					var list = namedElements.get(name);
					if (list == null) {
						list = [];
						namedElements.set(name, list);
					}
					list.push(fieldName);
					// Store indexed mapping for get_name(index) accessor
					final currentIndex = loopVarSubstitutions.exists(indexVar) ? loopVarSubstitutions.get(indexVar) : 0;
					var indexedList = indexedNamedElements.get(name);
					if (indexedList == null) {
						indexedList = [];
						indexedNamedElements.set(name, indexedList);
					}
					indexedList.push({index: currentIndex, fieldName: fieldName});
				}
			case UNTIndexed2D(name, indexVarX, indexVarY):
				if (name != null && name != "") {
					var list = namedElements.get(name);
					if (list == null) {
						list = [];
						namedElements.set(name, list);
					}
					list.push(fieldName);
					final currentX = loopVarSubstitutions.exists(indexVarX) ? loopVarSubstitutions.get(indexVarX) : 0;
					final currentY = loopVarSubstitutions.exists(indexVarY) ? loopVarSubstitutions.get(indexVarY) : 0;
					var indexedList = indexed2DNamedElements.get(name);
					if (indexedList == null) {
						indexedList = [];
						indexed2DNamedElements.set(name, indexedList);
					}
					indexedList.push({indexX: currentX, indexY: currentY, fieldName: fieldName});
				}
		}

		// Track slot containers — name comes from #name / #name[$i] prefix
		switch (node.type) {
			case SLOT(parameters, _):
				final hp = parameters != null;
				// Capture current loop variable values for parameterized slots
				final capturedLoopVars:Map<String, Int> = hp ? [for (k => v in loopVarSubstitutions) k => v] : new Map();
				switch (node.updatableName) {
					case UNTIndexed(baseName, ref) if (loopVarSubstitutions.exists(ref)):
						final currentIndex = loopVarSubstitutions.get(ref);
						slotEntries.push({key: Indexed(baseName, currentIndex), fieldName: fieldName, hasParams: hp, loopVars: capturedLoopVars});
					case UNTIndexed2D(baseName, refX, refY) if (loopVarSubstitutions.exists(refX) && loopVarSubstitutions.exists(refY)):
						final currentX = loopVarSubstitutions.get(refX);
						final currentY = loopVarSubstitutions.get(refY);
						slotEntries.push({key: Indexed2D(baseName, currentX, currentY), fieldName: fieldName, hasParams: hp, loopVars: capturedLoopVars});
					case UNTObject(name) | UNTUpdatable(name):
						slotEntries.push({key: Named(name), fieldName: fieldName, hasParams: hp, loopVars: capturedLoopVars});
					default:
						Context.warning("Slot requires a #name prefix for codegen", pos);
				}
			default:
		}

		// Track dynamicRef BuilderResult fields
		switch (node.type) {
			case DYNAMIC_REF(_, programmableRef, _):
				final compName = programmableRef;
				if (compName != null) {
					final resultField = "_comp_" + compName;
					dynamicRefFields.set(compName, resultField);
				}
			default:
		}

		// Visibility
		final visCond = generateVisibilityCondition(node, siblings, fieldName, pos);
		if (visCond != null) {
			visibilityEntries.push({fieldName: fieldName, condition: visCond, paramRefs: extractConditionalParamRefs(node, siblings),
				sentinelField: sentinelName, parentField: parentField, layer: node.layer, restoreFlowPropsExpr: flowRestoreExpr});
		}

		siblings.push({node: node, fieldName: fieldName});

		for (update in createResult.exprUpdates)
			expressionUpdates.push(update);

		// Children
		if (createResult.isContainer) {
			if (node.children != null && node.children.length > 0)
				processChildren(node.children, fieldName, fields, ctorExprs, [], pos);
		}
	}

	// ==================== Repeat Processing ====================

	/** Try to resolve a ReferenceableValue as a compile-time integer constant */
	static function tryResolveStaticInt(rv:ReferenceableValue):Null<Int> {
		if (rv == null) return null;
		return switch (rv) {
			case RVInteger(i): i;
			case RVFloat(f): Math.round(f);
			case EBinop(op, e1, e2):
				final left = tryResolveStaticInt(e1);
				final right = tryResolveStaticInt(e2);
				if (left != null && right != null) {
					switch (op) {
						case OpAdd: left + right;
						case OpSub: left - right;
						case OpMul: left * right;
						case OpDiv: right != 0 ? Math.round(left / right) : null;
						case OpMod: right != 0 ? left % right : null;
						default: null;
					};
				} else null;
			case RVParenthesis(e): tryResolveStaticInt(e);
			case EUnaryOp(_, e):
				final inner = tryResolveStaticInt(e);
				if (inner != null) -inner else null;
			default: null;
		};
	}

	/** Resolve repeat iterator info: returns {count, dx, dy, rangeStart, rangeStep} or null if param-dependent */
	static function resolveRepeatInfo(repeatType:RepeatType):{staticCount:Null<Int>, dx:Int, dy:Int, rangeStart:Int, rangeStep:Int, countRV:Null<ReferenceableValue>} {
		return switch (repeatType) {
			case StepIterator(dirX, dirY, repeats):
				final count = tryResolveStaticInt(repeats);
				final dxVal = dirX != null ? tryResolveStaticInt(dirX) : 0;
				final dyVal = dirY != null ? tryResolveStaticInt(dirY) : 0;
				{staticCount: count, dx: dxVal != null ? dxVal : 0, dy: dyVal != null ? dyVal : 0, rangeStart: 0, rangeStep: 1, countRV: count == null ? repeats : null};
			case RangeIterator(start, end, step):
				final s = tryResolveStaticInt(start);
				final e = tryResolveStaticInt(end);
				final st = tryResolveStaticInt(step);
				if (s != null && e != null && st != null) {
					{staticCount: Math.ceil((e - s) / st), dx: 0, dy: 0, rangeStart: s, rangeStep: st, countRV: null};
				} else {
					{staticCount: null, dx: 0, dy: 0, rangeStart: s != null ? s : 0, rangeStep: st != null ? st : 1, countRV: end};
				}
			default:
				// LayoutIterator, ArrayIterator, etc. — not supported yet in codegen
				null;
		};
	}

	/** Process a REPEAT node: unroll for static count, or pool for param-dependent count */
	static function processRepeat(node:Node, varName:String, repeatType:RepeatType, parentField:String, fields:Array<Field>, ctorExprs:Array<Expr>, siblings:Array<{node:Node, fieldName:String}>, pos:Position):Void {
		// Handle LayoutIterator and runtime iterators (TilesIterator, StateAnimIterator, ArrayIterator) specially
		switch (repeatType) {
			case LayoutIterator(layoutName):
				processLayoutRepeat(node, varName, layoutName, parentField, fields, ctorExprs, siblings, pos);
				return;
			case TilesIterator(bitmapVarName, tilenameVarName, sheetName, tileFilter):
				processRuntimeRepeat(node, varName, repeatType, parentField, fields, ctorExprs, siblings, pos);
				return;
			case StateAnimIterator(bitmapVarName, animFilename, animationName, selector):
				processRuntimeRepeat(node, varName, repeatType, parentField, fields, ctorExprs, siblings, pos);
				return;
			case ArrayIterator(valueVariableName, arrayName):
				processRuntimeRepeat(node, varName, repeatType, parentField, fields, ctorExprs, siblings, pos);
				return;
			default:
		}

		final info = resolveRepeatInfo(repeatType);
		if (info == null) {
			processRepeatFallback(node, parentField, fields, ctorExprs, siblings, pos);
			return;
		}

		// Create the repeat container
		final containerName = "_e" + (elementCounter++);
		fields.push(makeField(containerName, FVar(macro :h2d.Object, null), [APrivate], pos));
		ctorExprs.push(macro $p{["this", containerName]} = new h2d.Object());

		// Position the container
		ensureHexLayoutIfNeeded(node.pos, node, fields, ctorExprs, pos);
		final posExpr = generatePositionExpr(node.pos, containerName, pos, node);
		if (posExpr != null)
			ctorExprs.push(posExpr);

		// Create sentinel before adding conditional container
		final repeatSentinelName = createSentinelIfConditional(node, parentField, fields, ctorExprs, pos);

		// Add to parent (parentField == null means add to this directly)
		final parentRef = parentField != null ? (macro $p{["this", parentField]}) : (macro this);
		ctorExprs.push(macro $parentRef.addChild($p{["this", containerName]}));

		// Visibility for the container itself
		final visCond = generateVisibilityCondition(node, siblings, containerName, pos);
		if (visCond != null)
			visibilityEntries.push({fieldName: containerName, condition: visCond, paramRefs: extractConditionalParamRefs(node, siblings),
				sentinelField: repeatSentinelName, parentField: parentField, layer: node.layer, restoreFlowPropsExpr: null});
		siblings.push({node: node, fieldName: containerName});

		if (info.staticCount != null) {
			// Static unroll: generate children N times with loop var substituted
			unrollRepeatChildren(node, varName, info.staticCount, info.dx, info.dy, info.rangeStart, info.rangeStep, containerName, fields, ctorExprs, pos);
		} else {
			// Param-dependent: generate runtime rebuild method
			final countParamRefs = collectParamRefs(info.countRV);
			rebuildRepeatChildren(node, varName, info.dx, info.dy, info.rangeStart, info.rangeStep, containerName, fields, ctorExprs, countParamRefs, info.countRV, repeatType, pos);
		}
	}

	/** Unroll repeat children: generate N copies with loop var substituted to literal values */
	static function unrollRepeatChildren(node:Node, varName:String, count:Int, dx:Int, dy:Int, rangeStart:Int, rangeStep:Int, containerField:String, fields:Array<Field>, ctorExprs:Array<Expr>, pos:Position):Void {
		if (node.children == null) return;

		for (i in 0...count) {
			final resolvedIndex = rangeStart + i * rangeStep;
			// Set loop var substitution
			loopVarSubstitutions.set(varName, resolvedIndex);

			// Create an iteration container for grid offset
			if (dx != 0 || dy != 0) {
				final iterContainerName = "_e" + (elementCounter++);
				fields.push(makeField(iterContainerName, FVar(macro :h2d.Object, null), [APrivate], pos));
				ctorExprs.push(macro $p{["this", iterContainerName]} = new h2d.Object());
				final offsetX:Float = dx * i;
				final offsetY:Float = dy * i;
				ctorExprs.push(macro $p{["this", iterContainerName]}.setPosition($v{offsetX}, $v{offsetY}));
				ctorExprs.push(macro $p{["this", containerField]}.addChild($p{["this", iterContainerName]}));

				// Process children into the iteration container
				processChildren(node.children, iterContainerName, fields, ctorExprs, [], pos);
			} else {
				// No grid offset — process children directly into the main container
				processChildren(node.children, containerField, fields, ctorExprs, [], pos);
			}

			loopVarSubstitutions.remove(varName);
		}
	}

	/** Runtime rebuild repeat: generates a method that creates/recreates children based on count param */
	static function rebuildRepeatChildren(node:Node, varName:String, dx:Int, dy:Int, rangeStart:Int, rangeStep:Int, containerField:String, fields:Array<Field>, ctorExprs:Array<Expr>, countParamRefs:Array<String>, countRV:ReferenceableValue, repeatType:RepeatType, pos:Position):Void {
		if (node.children == null) return;

		// Generate the count expression: for StepIterator it's the count directly, for RangeIterator it needs calculation
		final countExpr:Expr = switch (repeatType) {
			case RangeIterator(start, end, step):
				final endExpr = rvToExpr(end);
				final startExpr = rvToExpr(start);
				final stepExpr = rvToExpr(step);
				macro Math.ceil(($endExpr - $startExpr) / $stepExpr);
			case StepIterator(_, _, repeats):
				rvToExpr(repeats);
			default:
				rvToExpr(countRV);
		};

		// For RangeIterator, the loop variable should be rangeStart + _rt_i * rangeStep, not just _rt_i
		final isRange = switch (repeatType) { case RangeIterator(_, _, _): true; default: false; };
		final loopVarIdent = isRange ? "_rt_val" : "_rt_i";

		// Use runtimeLoopVars so rvToExpr generates runtime references for the loop variable
		runtimeLoopVars.set(varName, loopVarIdent);

		// Build loop body expressions from child nodes
		final containerRef = macro _rt_cont;
		final loopBodyExprs:Array<Expr> = [];
		if (node.children != null) {
			for (child in node.children) {
				generateRuntimeChildExprs(child, repeatType, containerRef, loopBodyExprs, pos);
			}
		}

		runtimeLoopVars.remove(varName);

		// Build the for-loop body: create container, position, add children
		final forBodyExprs:Array<Expr> = [];
		if (isRange) {
			final rangeStartFloat:Float = rangeStart;
			final rangeStepFloat:Float = rangeStep;
			forBodyExprs.push(macro final _rt_val = Std.int($v{rangeStartFloat} + _rt_i * $v{rangeStepFloat}));
		}
		forBodyExprs.push(macro final _rt_cont = new h2d.Object());
		final dxFloat:Float = dx;
		final dyFloat:Float = dy;
		if (dx != 0 || dy != 0) {
			forBodyExprs.push(macro _rt_cont.setPosition($v{dxFloat} * _rt_i, $v{dyFloat} * _rt_i));
		}
		final containerFieldRef = macro $p{["this", containerField]};
		forBodyExprs.push(macro $containerFieldRef.addChild(_rt_cont));
		for (e in loopBodyExprs) forBodyExprs.push(e);

		final forBody:Expr = {expr: EBlock(forBodyExprs), pos: pos};

		// Generate rebuild method
		final rebuildMethodName = "_rebuildRepeat_" + containerField;
		final countTrackingField = rebuildMethodName + "_n";

		// Tracking field for current count (to avoid unnecessary rebuilds)
		fields.push(makeField(countTrackingField, FVar(macro :Int, macro -1), [APrivate], pos));

		// Rebuild method: clears container and recreates children for the new count
		final rebuildBody:Array<Expr> = [];
		rebuildBody.push(macro if (_rt_count == $p{["this", countTrackingField]}) return);
		rebuildBody.push(macro $p{["this", countTrackingField]} = _rt_count);
		rebuildBody.push(macro $containerFieldRef.removeChildren());
		rebuildBody.push(macro for (_rt_i in 0..._rt_count) $forBody);

		fields.push(makeMethod(rebuildMethodName, rebuildBody, [{name: "_rt_count", type: macro :Int}], macro :Void, [APrivate], pos));

		// Call rebuild in constructor with default count
		ctorExprs.push(macro $i{rebuildMethodName}(Std.int(${countExpr})));

		// Register for rebuild on param change
		repeatRebuildEntries.push({
			callExpr: macro $i{rebuildMethodName}(Std.int(${countExpr})),
		});
	}

	/** Process LayoutIterator: resolve layout points at compile time from parsed AST */
	static function processLayoutRepeat(node:Node, varName:String, layoutName:String, parentField:String, fields:Array<Field>, ctorExprs:Array<Expr>,
			siblings:Array<{node:Node, fieldName:String}>, pos:Position):Void {
		final layout = getLayoutDef(layoutName);
		if (layout == null) {
			Context.error('ProgrammableCodeGen: layout "$layoutName" not found in layouts block', Context.currentPos());
			return;
		}

		// Create the repeat container
		final containerName = "_e" + (elementCounter++);
		fields.push(makeField(containerName, FVar(macro :h2d.Object, null), [APrivate], pos));
		ctorExprs.push(macro $p{["this", containerName]} = new h2d.Object());

		ensureHexLayoutIfNeeded(node.pos, node, fields, ctorExprs, pos);
		final posExpr = generatePositionExpr(node.pos, containerName, pos, node);
		if (posExpr != null)
			ctorExprs.push(posExpr);

		final layoutRepeatSentinel = createSentinelIfConditional(node, parentField, fields, ctorExprs, pos);
		final parentRef = parentField != null ? (macro $p{["this", parentField]}) : (macro this);
		ctorExprs.push(macro $parentRef.addChild($p{["this", containerName]}));

		final visCond = generateVisibilityCondition(node, siblings, containerName, pos);
		if (visCond != null)
			visibilityEntries.push({fieldName: containerName, condition: visCond, paramRefs: extractConditionalParamRefs(node, siblings),
				sentinelField: layoutRepeatSentinel, parentField: parentField, layer: node.layer, restoreFlowPropsExpr: null});
		siblings.push({node: node, fieldName: containerName});

		// Resolve layout points and unroll
		final isAligned = layoutHasAlign(layout);
		if (isAligned) needsLayoutAlign = true;
		final alignXInt = isAligned ? alignXToInt(layout.alignX) : 0;
		final alignYInt = isAligned ? alignYToInt(layout.alignY) : 0;
		final offsetX:Float = layout.offset != null ? layout.offset.x : 0;
		final offsetY:Float = layout.offset != null ? layout.offset.y : 0;

		switch (layout.type) {
			case List(list):
				for (i in 0...list.length) {
					loopVarSubstitutions.set(varName, i);
					final pt = resolveLayoutPoint(list[i], layout, i);
					if (pt != null)
						emitLayoutIterationContainer(node, containerName, pt.x + offsetX, pt.y + offsetY, isAligned, alignXInt, alignYInt, fields, ctorExprs, pos);
					else
						processChildren(node.children, containerName, fields, ctorExprs, [], pos);
					loopVarSubstitutions.remove(varName);
				}

			case Single(content):
				loopVarSubstitutions.set(varName, 0);
				final pt = resolveLayoutPoint(content, layout, 0);
				if (pt != null)
					emitLayoutIterationContainer(node, containerName, pt.x + offsetX, pt.y + offsetY, isAligned, alignXInt, alignYInt, fields, ctorExprs, pos);
				else
					processChildren(node.children, containerName, fields, ctorExprs, [], pos);
				loopVarSubstitutions.remove(varName);

			case Sequence(seqVarName, from, to, content):
				for (i in from...(to + 1)) {
					loopVarSubstitutions.set(varName, i - from);
					loopVarSubstitutions.set(seqVarName, i);
					final pt = resolveLayoutPointSequence(content, layout, seqVarName, i);
					if (pt != null)
						emitLayoutIterationContainer(node, containerName, pt.x + offsetX, pt.y + offsetY, isAligned, alignXInt, alignYInt, fields, ctorExprs, pos);
					else
						processChildren(node.children, containerName, fields, ctorExprs, [], pos);
					loopVarSubstitutions.remove(varName);
					loopVarSubstitutions.remove(seqVarName);
				}

			case Grid(cols, rows, cellW, cellH):
				final total = cols * rows;
				for (i in 0...total) {
					loopVarSubstitutions.set(varName, i);
					final col = i % cols;
					final row = Std.int(i / cols);
					emitLayoutIterationContainer(node, containerName, col * cellW + offsetX, row * cellH + offsetY, isAligned, alignXInt, alignYInt, fields, ctorExprs, pos);
					loopVarSubstitutions.remove(varName);
				}
		}
	}

	/** Emit a positioned container for one layout iteration, or add children directly if at origin */
	static function emitLayoutIterationContainer(node:Node, containerName:String, px:Float, py:Float, isAligned:Bool, alignXInt:Int, alignYInt:Int,
			fields:Array<Field>, ctorExprs:Array<Expr>, pos:Position):Void {
		if (px != 0 || py != 0 || isAligned) {
			final iterContainerName = "_e" + (elementCounter++);
			fields.push(makeField(iterContainerName, FVar(macro :h2d.Object, null), [APrivate], pos));
			ctorExprs.push(macro $p{["this", iterContainerName]} = new h2d.Object());
			if (isAligned)
				ctorExprs.push(macro this.addAlignEntry($p{["this", iterContainerName]}, $v{px}, $v{py}, $v{alignXInt}, $v{alignYInt}, 0.0, 0.0))
			else
				ctorExprs.push(macro $p{["this", iterContainerName]}.setPosition($v{px}, $v{py}));
			ctorExprs.push(macro $p{["this", containerName]}.addChild($p{["this", iterContainerName]}));
			processChildren(node.children, iterContainerName, fields, ctorExprs, [], pos);
		} else {
			processChildren(node.children, containerName, fields, ctorExprs, [], pos);
		}
	}

	/** Resolve a LayoutPoint coordinate to an {x, y} at macro time */
	static function resolveLayoutPoint(content:LayoutContent, layout:Layout, index:Int):Null<{x:Float, y:Float}> {
		return switch (content) {
			case LayoutPoint(coords):
				resolveCoordinatesStatic(coords, layout, index);
		};
	}

	/** Resolve a LayoutPoint coordinate for Sequence layouts */
	static function resolveLayoutPointSequence(content:LayoutContent, layout:Layout, seqVarName:String, seqIndex:Int):Null<{x:Float, y:Float}> {
		return switch (content) {
			case LayoutPoint(coords):
				resolveCoordinatesStatic(coords, layout, seqIndex);
		};
	}

	/** Statically resolve a Coordinates value at macro time */
	static function resolveCoordinatesStatic(coords:Coordinates, layout:Layout, index:Int):Null<{x:Float, y:Float}> {
		return switch (coords) {
			case ZERO: {x: 0.0, y: 0.0};
			case OFFSET(x, y):
				final xVal = resolveRVStatic(x);
				final yVal = resolveRVStatic(y);
				if (xVal != null && yVal != null) {
					{x: xVal, y: yVal};
				} else {
					null;
				}
			case SELECTED_GRID_POSITION(gridX, gridY):
				final gx = resolveRVStatic(gridX);
				final gy = resolveRVStatic(gridY);
				if (gx != null && gy != null && layout.grid != null) {
					{x: layout.grid.spacingX * gx, y: layout.grid.spacingY * gy};
				} else {
					null;
				}
			case SELECTED_HEX_CUBE(q, r, s):
				if (layout.hex != null) {
					final qv = resolveRVStatic(q);
					final rv2 = resolveRVStatic(r);
					final sv = resolveRVStatic(s);
					if (qv != null && rv2 != null && sv != null) {
						final hex = new bh.base.Hex.FractionalHex(qv, rv2, sv).round();
						final pt = layout.hex.hexLayout.hexToPixel(hex);
						{x: pt.x, y: pt.y};
					} else null;
				} else null;
			case SELECTED_HEX_CORNER(count, factor):
				if (layout.hex != null) {
					final c = resolveRVStatic(count);
					final f = resolveRVStatic(factor);
					if (c != null && f != null) {
						final pt = layout.hex.hexLayout.polygonCorner(bh.base.Hex.zero(), Std.int(c), f);
						{x: pt.x, y: pt.y};
					} else null;
				} else null;
			case SELECTED_HEX_EDGE(direction, factor):
				if (layout.hex != null) {
					final d = resolveRVStatic(direction);
					final f = resolveRVStatic(factor);
					if (d != null && f != null) {
						final pt = layout.hex.hexLayout.polygonEdge(bh.base.Hex.zero(), Std.int(d), f);
						{x: pt.x, y: pt.y};
					} else null;
				} else null;
			case SELECTED_HEX_OFFSET(col, row, parity):
				if (layout.hex != null) {
					final c = resolveRVStatic(col);
					final r2 = resolveRVStatic(row);
					if (c != null && r2 != null) {
						final parityVal = switch (parity) {
							case EVEN: bh.base.Hex.OffsetCoord.EVEN;
							case ODD: bh.base.Hex.OffsetCoord.ODD;
						};
						final hex = switch (layout.hex.hexLayout.orientation) {
							case POINTY: bh.base.Hex.OffsetCoord.qoffsetToCube(parityVal, new bh.base.Hex.OffsetCoord(Std.int(c), Std.int(r2)));
							case FLAT: bh.base.Hex.OffsetCoord.roffsetToCube(parityVal, new bh.base.Hex.OffsetCoord(Std.int(c), Std.int(r2)));
						};
						final pt = layout.hex.hexLayout.hexToPixel(hex);
						{x: pt.x, y: pt.y};
					} else null;
				} else null;
			case SELECTED_HEX_DOUBLED(col2, row2):
				if (layout.hex != null) {
					final c = resolveRVStatic(col2);
					final r2 = resolveRVStatic(row2);
					if (c != null && r2 != null) {
						final hex = switch (layout.hex.hexLayout.orientation) {
							case POINTY: bh.base.Hex.DoubledCoord.qdoubledToCube(new bh.base.Hex.DoubledCoord(Std.int(c), Std.int(r2)));
							case FLAT: bh.base.Hex.DoubledCoord.rdoubledToCube(new bh.base.Hex.DoubledCoord(Std.int(c), Std.int(r2)));
						};
						final pt = layout.hex.hexLayout.hexToPixel(hex);
						{x: pt.x, y: pt.y};
					} else null;
				} else null;
			case SELECTED_HEX_CELL_CORNER(cell, cornerIndex, factor):
				if (layout.hex != null) {
					final ci = resolveRVStatic(cornerIndex);
					final f = resolveRVStatic(factor);
					final cellHex = resolveCoordToStaticHex(cell, layout.hex.hexLayout);
					if (ci != null && f != null && cellHex != null) {
						final pt = layout.hex.hexLayout.polygonCorner(cellHex, Std.int(ci), f);
						{x: pt.x, y: pt.y};
					} else null;
				} else null;
			case SELECTED_HEX_CELL_EDGE(cell, direction, factor):
				if (layout.hex != null) {
					final d = resolveRVStatic(direction);
					final f = resolveRVStatic(factor);
					final cellHex = resolveCoordToStaticHex(cell, layout.hex.hexLayout);
					if (d != null && f != null && cellHex != null) {
						final pt = layout.hex.hexLayout.polygonEdge(cellHex, Std.int(d), f);
						{x: pt.x, y: pt.y};
					} else null;
				} else null;
			default: null;
		};
	}

	/** Try to resolve a ReferenceableValue as a static Float (resolving loop var substitutions) */
	static function resolveRVStatic(rv:ReferenceableValue):Null<Float> {
		if (rv == null) return null;
		return switch (rv) {
			case RVInteger(i): cast(i, Float);
			case RVFloat(f): f;
			case RVReference(ref):
				if (loopVarSubstitutions.exists(ref))
					cast(loopVarSubstitutions.get(ref), Float)
				else if (finalVarExprs.exists(ref))
					resolveRVStatic(finalVarExprs.get(ref))
				else
					null;
			case EBinop(op, e1, e2):
				final left = resolveRVStatic(e1);
				final right = resolveRVStatic(e2);
				if (left != null && right != null) {
					switch (op) {
						case OpAdd: left + right;
						case OpSub: left - right;
						case OpMul: left * right;
						case OpDiv: left / right;
						case OpMod: left % right;
						default: null;
					};
				} else {
					null;
				}
			case RVParenthesis(e): resolveRVStatic(e);
			case EUnaryOp(_, e):
				final inner = resolveRVStatic(e);
				if (inner != null) -inner else null;
			case RVPropertyAccess(ref, property):
				switch (ref) {
					case "grid" | "ctx.grid":
						final grid = getGridFromCurrentNode();
						if (grid != null) {
							switch (property) {
								case "width": cast(grid.spacingX, Float);
								case "height": cast(grid.spacingY, Float);
								default: null;
							}
						} else null;
					case "hex" | "ctx.hex":
						final hexLayout = getHexLayoutForNode(currentProcessingNode);
						if (hexLayout != null) {
							switch (property) {
								case "width": hexLayout.size.x;
								case "height": hexLayout.size.y;
								default: null;
							}
						} else null;
					default:
						// Named coordinate systems
						if (currentProcessingNode != null) {
							final namedCS = getNamedCoordSystem(ref, currentProcessingNode);
							if (namedCS != null) {
								switch (namedCS) {
									case NamedGrid(system):
										switch (property) {
											case "width": cast(system.spacingX, Float);
											case "height": cast(system.spacingY, Float);
											default: null;
										}
									case NamedHex(system):
										switch (property) {
											case "width": system.hexLayout.size.x;
											case "height": system.hexLayout.size.y;
											default: null;
										}
								}
							} else null;
						} else null;
				}
			case RVMethodCall(ref, method, args):
				// $ctx.random() cannot be resolved statically
				null;
			case RVChainedMethodCall(base, property, _):
				if (property != "x" && property != "y") null;
				else switch (base) {
					case RVMethodCall(ref, method, args):
						final pt = resolveMethodCallToStaticPoint(ref, method, args);
						if (pt != null) (property == "x" ? pt.x : pt.y) else null;
					default: null;
				}
			default: null;
		};
	}

	/** Process runtime iterators (TilesIterator, StateAnimIterator, ArrayIterator) via builder delegation.
	 *  These iterators need runtime data (sheet contents, .anim files, array values),
	 *  so we generate a runtime loop in the constructor. */
	static function processRuntimeRepeat(node:Node, varName:String, repeatType:RepeatType, parentField:String, fields:Array<Field>, ctorExprs:Array<Expr>,
			siblings:Array<{node:Node, fieldName:String}>, pos:Position):Void {
		// Create a container for the repeat
		final containerName = "_e" + (elementCounter++);
		fields.push(makeField(containerName, FVar(macro :h2d.Object, null), [APrivate], pos));
		ctorExprs.push(macro $p{["this", containerName]} = new h2d.Object());

		ensureHexLayoutIfNeeded(node.pos, node, fields, ctorExprs, pos);
		final posExpr = generatePositionExpr(node.pos, containerName, pos, node);
		if (posExpr != null)
			ctorExprs.push(posExpr);

		final runtimeRepeatSentinel = createSentinelIfConditional(node, parentField, fields, ctorExprs, pos);
		final parentRef = parentField != null ? (macro $p{["this", parentField]}) : (macro this);
		ctorExprs.push(macro $parentRef.addChild($p{["this", containerName]}));

		final visCond = generateVisibilityCondition(node, siblings, containerName, pos);
		if (visCond != null)
			visibilityEntries.push({fieldName: containerName, condition: visCond, paramRefs: extractConditionalParamRefs(node, siblings),
				sentinelField: runtimeRepeatSentinel, parentField: parentField, layer: node.layer, restoreFlowPropsExpr: null});
		siblings.push({node: node, fieldName: containerName});

		final containerRef = macro $p{["this", containerName]};

		// Set up runtime loop var mapping so rvToExpr generates runtime references
		runtimeLoopVars.set(varName, "_rt_i");

		// For array iterators, map the value variable to a runtime var
		switch (repeatType) {
			case ArrayIterator(valueVariableName, _):
				runtimeLoopVars.set(valueVariableName, "_rt_val");
			default:
		}

		// Build loop body expressions from child nodes
		final loopBodyExprs:Array<Expr> = [];
		if (node.children != null) {
			for (child in node.children) {
				generateRuntimeChildExprs(child, repeatType, containerRef, loopBodyExprs, pos);
			}
		}

		runtimeLoopVars.remove(varName);

		// Remove bitmap var from runtimeLoopVars (was set by generateRuntimeChildExprs indirectly — clean up)
		switch (repeatType) {
			case TilesIterator(bitmapVarName, tilenameVarName, _, _):
				runtimeLoopVars.remove(bitmapVarName);
				if (tilenameVarName != null) runtimeLoopVars.remove(tilenameVarName);
			case StateAnimIterator(bitmapVarName, _, _, _):
				runtimeLoopVars.remove(bitmapVarName);
			case ArrayIterator(valueVariableName, _):
				runtimeLoopVars.remove(valueVariableName);
			default:
		}

		// Build the loop body block
		final loopBody:Expr = if (loopBodyExprs.length == 1)
			loopBodyExprs[0]
		else
			{expr: EBlock(loopBodyExprs), pos: pos};

		// Generate the tile-fetching code + loop
		switch (repeatType) {
			case TilesIterator(bitmapVarName, tilenameVarName, sheetName, tileFilter):
				final sheetStr = sheetName;
				final filterExpr:Expr = tileFilter != null ? macro $v{tileFilter} : macro null;
				ctorExprs.push(macro {
					final _rt_tiles = this._pb.getSheetTiles($v{sheetStr}, $filterExpr);
					for (_rt_i in 0..._rt_tiles.length) {
						$loopBody;
					}
				});

			case StateAnimIterator(bitmapVarName, animFilename, animationName, selectorRefs):
				final fileStr = animFilename;
				final selectorPairs:Array<Expr> = [];
				for (k => v in selectorRefs) {
					final keyStr = k;
					final valExpr = rvToExpr(v);
					selectorPairs.push(macro $v{keyStr} => Std.string($valExpr));
				}
				final selectorMapExpr:Expr = if (selectorPairs.length == 0) macro new Map() else {
					expr: EArrayDecl(selectorPairs),
					pos: pos,
				};
				final animNameExpr = rvToExpr(animationName);
				ctorExprs.push(macro {
					final _rt_tiles = this._pb.getStateAnimTiles($v{fileStr}, Std.string($animNameExpr), $selectorMapExpr);
					for (_rt_i in 0..._rt_tiles.length) {
						$loopBody;
					}
				});

			case ArrayIterator(valueVariableName, arrayName):
				final arrayField = "_" + arrayName;
				final arrayRef = macro $p{["this", arrayField]};
				final valAssign:Expr = macro final _rt_val = arr[_rt_i];
				final arrayLoopBody:Expr = {expr: EBlock([valAssign, loopBody]), pos: pos};
				ctorExprs.push(macro {
					final arr:Array<String> = $arrayRef;
					if (arr != null) {
						for (_rt_i in 0...arr.length) {
							$arrayLoopBody;
						}
					}
				});

			default:
		}
	}

	/** Generate runtime loop body expressions for a single child node of a runtime iterator.
	 *  For bitmap children, creates a bitmap from the tile array and positions it. */
	static function generateRuntimeChildExprs(child:Node, repeatType:RepeatType, containerRef:Expr, bodyExprs:Array<Expr>, pos:Position):Void {
		switch (child.type) {
			case BITMAP(tileSource, hAlign, vAlign):
				final bitmapExpr:Expr = switch (tileSource) {
					case TSReference(_):
						macro _rt_tiles[_rt_i];
					default:
						tileSourceToExpr(tileSource);
				};
				// Collect all statements into a single block so _rt_bmp is in scope
				final stmts:Array<Expr> = [];
				// Apply hAlign/vAlign via tile.sub() dx/dy, matching generateBitmapCreate
				var dxExpr:Expr = switch (hAlign) {
					case Center: macro -(_rt_tile.width * 0.5);
					case Right: macro -_rt_tile.width;
					default: macro 0.0;
				};
				var dyExpr:Expr = switch (vAlign) {
					case Center: macro -(_rt_tile.height * 0.5);
					case Bottom: macro -_rt_tile.height;
					default: macro 0.0;
				};
				stmts.push(macro final _rt_tile = $bitmapExpr);
				stmts.push(macro final _rt_bmp = new h2d.Bitmap(_rt_tile.sub(0, 0, _rt_tile.width, _rt_tile.height, $dxExpr, $dyExpr)));
				stmts.push(macro $containerRef.addChild(_rt_bmp));
				if (child.pos != null) {
					switch (child.pos) {
						case OFFSET(x, y):
							final xExpr = rvToExpr(x);
							final yExpr = rvToExpr(y);
							stmts.push(macro _rt_bmp.setPosition($xExpr, $yExpr));
						default:
					}
				}
				if (child.scale != null) {
					final scaleExpr = rvToExpr(child.scale);
					stmts.push(macro _rt_bmp.scaleX = $scaleExpr);
					stmts.push(macro _rt_bmp.scaleY = $scaleExpr);
				}
				if (child.rotation != null) {
					final rotExpr = rvToExpr(child.rotation);
					stmts.push(macro _rt_bmp.rotation = hxd.Math.degToRad($rotExpr));
				}
				if (child.alpha != null) {
					final alphaExpr = rvToExpr(child.alpha);
					stmts.push(macro _rt_bmp.alpha = $alphaExpr);
				}
				bodyExprs.push({expr: EBlock(stmts), pos: pos});

			case POINT:
				final ptStmts:Array<Expr> = [];
				ptStmts.push(macro final _rt_obj = new h2d.Object());
				ptStmts.push(macro $containerRef.addChild(_rt_obj));
				if (child.pos != null) {
					switch (child.pos) {
						case OFFSET(x, y):
							final xExpr = rvToExpr(x);
							final yExpr = rvToExpr(y);
							ptStmts.push(macro _rt_obj.setPosition($xExpr, $yExpr));
						default:
					}
				}
				if (child.scale != null) {
					final scaleExpr = rvToExpr(child.scale);
					ptStmts.push(macro _rt_obj.scaleX = $scaleExpr);
					ptStmts.push(macro _rt_obj.scaleY = $scaleExpr);
				}
				if (child.rotation != null) {
					final rotExpr = rvToExpr(child.rotation);
					ptStmts.push(macro _rt_obj.rotation = hxd.Math.degToRad($rotExpr));
				}
				if (child.alpha != null) {
					final alphaExpr = rvToExpr(child.alpha);
					ptStmts.push(macro _rt_obj.alpha = $alphaExpr);
				}
				// Recurse into point's children with _rt_obj as parent
				if (child.children != null) {
					for (grandchild in child.children) {
						final innerStmts:Array<Expr> = [];
						generateRuntimeChildExprs(grandchild, repeatType, macro _rt_obj, innerStmts, pos);
						for (s in innerStmts)
							ptStmts.push(s);
					}
				}
				bodyExprs.push({expr: EBlock(ptStmts), pos: pos});

			case TEXT(textDef) | RICHTEXT(textDef):
				final isRichText = child.type.match(RICHTEXT(_));
				final stmts:Array<Expr> = [];
				final fontExpr = rvToExpr(textDef.fontName);
				if (isRichText) {
					stmts.push(macro final _rt_txt = new h2d.HtmlText(this._pb.loadFont($fontExpr)));
					stmts.push(macro {
						final ht:h2d.HtmlText = cast _rt_txt;
						ht.loadFont = (name) -> this._pb.loadFont(name);
					});
				} else {
					stmts.push(macro final _rt_txt = new h2d.Text(this._pb.loadFont($fontExpr)));
				}
				stmts.push(macro $containerRef.addChild(_rt_txt));

				final colorExpr = rvToExpr(textDef.color);
				stmts.push(macro _rt_txt.textColor = $colorExpr);

				final textExpr = rvToExpr(textDef.text, true);
				if (isRichText) {
					stmts.push(macro _rt_txt.text = bh.multianim.TextMarkupConverter.convert(Std.string($textExpr)));
				} else {
					stmts.push(macro _rt_txt.text = Std.string($textExpr));
				}

				switch (textDef.halign) {
					case Right: stmts.push(macro _rt_txt.textAlign = Right);
					case Center: stmts.push(macro _rt_txt.textAlign = Center);
					default: stmts.push(macro _rt_txt.textAlign = Left);
				}

				switch (textDef.textAlignWidth) {
					case TAWValue(value):
						final scaleAdjust:Float = if (child.scale != null) {
							final s = resolveRVStatic(child.scale);
							if (s != null) s else 1.0;
						} else 1.0;
						final staticVal = resolveRVStatic(value);
						if (staticVal != null) {
							final adjustedWidth:Float = staticVal / scaleAdjust;
							stmts.push(macro _rt_txt.maxWidth = $v{adjustedWidth});
						} else {
							final valExpr = rvToExpr(value);
							final scaleExpr = macro $v{scaleAdjust};
							stmts.push(macro _rt_txt.maxWidth = $valExpr / $scaleExpr);
						}
					default:
				}

				if (textDef.letterSpacing != 0)
					stmts.push(macro _rt_txt.letterSpacing = $v{textDef.letterSpacing});
				if (textDef.lineSpacing != 0)
					stmts.push(macro _rt_txt.lineSpacing = $v{textDef.lineSpacing});
				stmts.push(macro _rt_txt.lineBreak = $v{textDef.lineBreak});

				if (textDef.dropShadowXY != null) {
					final dx:Float = textDef.dropShadowXY.x;
					final dy:Float = textDef.dropShadowXY.y;
					final color:Int = textDef.dropShadowColor;
					final alpha:Float = textDef.dropShadowAlpha;
					stmts.push(macro _rt_txt.dropShadow = {dx: $v{dx}, dy: $v{dy}, color: $v{color}, alpha: $v{alpha}});
				}

				if (child.pos != null) {
					switch (child.pos) {
						case OFFSET(x, y):
							final xExpr = rvToExpr(x);
							final yExpr = rvToExpr(y);
							stmts.push(macro _rt_txt.setPosition($xExpr, $yExpr));
						default:
					}
				}
				if (child.scale != null) {
					final scaleExpr = rvToExpr(child.scale);
					stmts.push(macro _rt_txt.scaleX = $scaleExpr);
					stmts.push(macro _rt_txt.scaleY = $scaleExpr);
				}
				if (child.rotation != null) {
					final rotExpr = rvToExpr(child.rotation);
					stmts.push(macro _rt_txt.rotation = hxd.Math.degToRad($rotExpr));
				}
				if (child.alpha != null) {
					final alphaExpr = rvToExpr(child.alpha);
					stmts.push(macro _rt_txt.alpha = $alphaExpr);
				}
				bodyExprs.push({expr: EBlock(stmts), pos: pos});

			case NINEPATCH(sheet, tilename, width, height):
				final stmts:Array<Expr> = [];
				final sheetStr = sheet;
				final tileStr = tilename;
				final wExpr = rvToExpr(width);
				final hExpr = rvToExpr(height);
				stmts.push(macro final _rt_sg = this._pb.load9Patch($v{sheetStr}, $v{tileStr}));
				stmts.push(macro _rt_sg.width = $wExpr);
				stmts.push(macro _rt_sg.height = $hExpr);
				stmts.push(macro _rt_sg.tileCenter = true);
				stmts.push(macro _rt_sg.tileBorders = true);
				stmts.push(macro _rt_sg.ignoreScale = false);
				stmts.push(macro $containerRef.addChild(_rt_sg));
				if (child.pos != null) {
					switch (child.pos) {
						case OFFSET(x, y):
							final xExpr = rvToExpr(x);
							final yExpr = rvToExpr(y);
							stmts.push(macro _rt_sg.setPosition($xExpr, $yExpr));
						default:
					}
				}
				if (child.scale != null) {
					final scaleExpr = rvToExpr(child.scale);
					stmts.push(macro _rt_sg.scaleX = $scaleExpr);
					stmts.push(macro _rt_sg.scaleY = $scaleExpr);
				}
				if (child.rotation != null) {
					final rotExpr = rvToExpr(child.rotation);
					stmts.push(macro _rt_sg.rotation = hxd.Math.degToRad($rotExpr));
				}
				if (child.alpha != null) {
					final alphaExpr = rvToExpr(child.alpha);
					stmts.push(macro _rt_sg.alpha = $alphaExpr);
				}
				bodyExprs.push({expr: EBlock(stmts), pos: pos});

			case GRAPHICS(elements):
				final stmts:Array<Expr> = [];
				stmts.push(macro final _rt_g = new h2d.Graphics());
				stmts.push(macro $containerRef.addChild(_rt_g));
				for (item in elements) {
					final drawExprs = generateGraphicsElementExprs(macro _rt_g, item.element, item.pos, child, pos);
					for (de in drawExprs)
						stmts.push(de);
				}
				if (child.pos != null) {
					switch (child.pos) {
						case OFFSET(x, y):
							final xExpr = rvToExpr(x);
							final yExpr = rvToExpr(y);
							stmts.push(macro _rt_g.setPosition($xExpr, $yExpr));
						default:
					}
				}
				if (child.scale != null) {
					final scaleExpr = rvToExpr(child.scale);
					stmts.push(macro _rt_g.scaleX = $scaleExpr);
					stmts.push(macro _rt_g.scaleY = $scaleExpr);
				}
				if (child.rotation != null) {
					final rotExpr = rvToExpr(child.rotation);
					stmts.push(macro _rt_g.rotation = hxd.Math.degToRad($rotExpr));
				}
				if (child.alpha != null) {
					final alphaExpr = rvToExpr(child.alpha);
					stmts.push(macro _rt_g.alpha = $alphaExpr);
				}
				bodyExprs.push({expr: EBlock(stmts), pos: pos});

			case PIXELS(shapes):
				final stmts:Array<Expr> = [];
				// Resolve all shapes at compile time for bounds calculation
				var allStatic = true;
				var staticShapes:Array<{type:String, x1:Float, y1:Float, x2:Float, y2:Float, w:Float, h:Float, color:Null<Int>, filled:Bool}> = [];
				for (s in shapes) {
					switch (s) {
						case LINE(line):
							final startXY = coordsToStaticXY(line.start, pos, child);
							final endXY = coordsToStaticXY(line.end, pos, child);
							final c = resolveRVStatic(line.color);
							if (startXY != null && endXY != null && c != null)
								staticShapes.push({type: "line", x1: startXY.x, y1: startXY.y, x2: endXY.x, y2: endXY.y, w: 0, h: 0, color: Std.int(c), filled: false});
							else allStatic = false;
						case RECT(rect) | FILLED_RECT(rect):
							final startXY = coordsToStaticXY(rect.start, pos, child);
							final w = resolveRVStatic(rect.width);
							final h = resolveRVStatic(rect.height);
							final c = resolveRVStatic(rect.color);
							final filled = switch (s) { case FILLED_RECT(_): true; default: false; };
							if (startXY != null && w != null && h != null && c != null)
								staticShapes.push({type: "rect", x1: startXY.x, y1: startXY.y, x2: 0, y2: 0, w: w, h: h, color: Std.int(c), filled: filled});
							else allStatic = false;
						case PIXEL(pixel):
							final xy = coordsToStaticXY(pixel.pos, pos, child);
							final c = resolveRVStatic(pixel.color);
							if (xy != null && c != null)
								staticShapes.push({type: "pixel", x1: xy.x, y1: xy.y, x2: 0, y2: 0, w: 0, h: 0, color: Std.int(c), filled: false});
							else allStatic = false;
					}
				}
				if (allStatic && staticShapes.length > 0) {
					var minX:Int = 0x7FFFFFFF; var minY:Int = 0x7FFFFFFF;
					var maxX:Int = -0x80000000; var maxY:Int = -0x80000000;
					for (s in staticShapes) {
						switch (s.type) {
							case "line":
								final ix1 = Math.round(s.x1); final iy1 = Math.round(s.y1);
								final ix2 = Math.round(s.x2); final iy2 = Math.round(s.y2);
								if (ix1 < minX) minX = ix1; if (iy1 < minY) minY = iy1;
								if (ix2 < minX) minX = ix2; if (iy2 < minY) minY = iy2;
								if (ix1 > maxX) maxX = ix1; if (iy1 > maxY) maxY = iy1;
								if (ix2 > maxX) maxX = ix2; if (iy2 > maxY) maxY = iy2;
							case "rect":
								final ix = Math.round(s.x1); final iy = Math.round(s.y1);
								final iw = Math.round(s.w); final ih = Math.round(s.h);
								if (ix < minX) minX = ix; if (iy < minY) minY = iy;
								if (ix + iw + 1 > maxX) maxX = ix + iw + 1;
								if (iy + ih + 1 > maxY) maxY = iy + ih + 1;
							case "pixel":
								final ix = Math.round(s.x1); final iy = Math.round(s.y1);
								if (ix < minX) minX = ix; if (iy < minY) minY = iy;
								if (ix > maxX) maxX = ix; if (iy > maxY) maxY = iy;
							default:
						}
					}
					final width:Int = maxX - minX + 1;
					final height:Int = maxY - minY + 1;
					stmts.push(macro final _rt_pl = new bh.base.PixelLine.PixelLines($v{width}, $v{height}));
					stmts.push(macro $containerRef.addChild(_rt_pl));
					stmts.push(macro _rt_pl.setPosition($v{minX}, $v{minY}));
					for (s in staticShapes) {
						switch (s.type) {
							case "line":
								final ix1:Int = Math.round(s.x1) - minX; final iy1:Int = Math.round(s.y1) - minY;
								final ix2:Int = Math.round(s.x2) - minX; final iy2:Int = Math.round(s.y2) - minY;
								var c:Int = s.color; if (c >>> 24 == 0) c |= 0xFF000000;
								stmts.push(macro _rt_pl.line($v{ix1}, $v{iy1}, $v{ix2}, $v{iy2}, $v{c}));
							case "rect":
								final ix:Int = Math.round(s.x1) - minX; final iy:Int = Math.round(s.y1) - minY;
								final iw:Int = Math.round(s.w); final ih:Int = Math.round(s.h);
								var c:Int = s.color; if (c >>> 24 == 0) c |= 0xFF000000;
								if (s.filled)
									stmts.push(macro _rt_pl.filledRect($v{ix}, $v{iy}, $v{iw}, $v{ih}, $v{c}));
								else
									stmts.push(macro _rt_pl.rect($v{ix}, $v{iy}, $v{iw}, $v{ih}, $v{c}));
							case "pixel":
								final ix:Int = Math.round(s.x1) - minX; final iy:Int = Math.round(s.y1) - minY;
								var c:Int = s.color; if (c >>> 24 == 0) c |= 0xFF000000;
								stmts.push(macro _rt_pl.pixel($v{ix}, $v{iy}, $v{c}));
							default:
						}
					}
					stmts.push(macro _rt_pl.updateBitmap());
				}
				bodyExprs.push({expr: EBlock(stmts), pos: pos});

			case MASK(w, h):
				final stmts:Array<Expr> = [];
				final wExpr = rvToExpr(w);
				final hExpr = rvToExpr(h);
				stmts.push(macro final _rt_mask = new h2d.Mask(Math.round($wExpr), Math.round($hExpr)));
				stmts.push(macro $containerRef.addChild(_rt_mask));
				if (child.pos != null) {
					switch (child.pos) {
						case OFFSET(x, y):
							final xExpr = rvToExpr(x);
							final yExpr = rvToExpr(y);
							stmts.push(macro _rt_mask.setPosition($xExpr, $yExpr));
						default:
					}
				}
				if (child.scale != null) {
					final scaleExpr = rvToExpr(child.scale);
					stmts.push(macro _rt_mask.scaleX = $scaleExpr);
					stmts.push(macro _rt_mask.scaleY = $scaleExpr);
				}
				if (child.rotation != null) {
					final rotExpr = rvToExpr(child.rotation);
					stmts.push(macro _rt_mask.rotation = hxd.Math.degToRad($rotExpr));
				}
				if (child.alpha != null) {
					final alphaExpr = rvToExpr(child.alpha);
					stmts.push(macro _rt_mask.alpha = $alphaExpr);
				}
				if (child.children != null) {
					for (grandchild in child.children) {
						final innerStmts:Array<Expr> = [];
						generateRuntimeChildExprs(grandchild, repeatType, macro _rt_mask, innerStmts, pos);
						for (s in innerStmts)
							stmts.push(s);
					}
				}
				bodyExprs.push({expr: EBlock(stmts), pos: pos});

			case LAYERS:
				final stmts:Array<Expr> = [];
				stmts.push(macro final _rt_layers = new h2d.Layers());
				stmts.push(macro $containerRef.addChild(_rt_layers));
				if (child.pos != null) {
					switch (child.pos) {
						case OFFSET(x, y):
							final xExpr = rvToExpr(x);
							final yExpr = rvToExpr(y);
							stmts.push(macro _rt_layers.setPosition($xExpr, $yExpr));
						default:
					}
				}
				if (child.scale != null) {
					final scaleExpr = rvToExpr(child.scale);
					stmts.push(macro _rt_layers.scaleX = $scaleExpr);
					stmts.push(macro _rt_layers.scaleY = $scaleExpr);
				}
				if (child.rotation != null) {
					final rotExpr = rvToExpr(child.rotation);
					stmts.push(macro _rt_layers.rotation = hxd.Math.degToRad($rotExpr));
				}
				if (child.alpha != null) {
					final alphaExpr = rvToExpr(child.alpha);
					stmts.push(macro _rt_layers.alpha = $alphaExpr);
				}
				if (child.children != null) {
					for (grandchild in child.children) {
						final innerStmts:Array<Expr> = [];
						generateRuntimeChildExprs(grandchild, repeatType, macro _rt_layers, innerStmts, pos);
						for (s in innerStmts)
							stmts.push(s);
					}
				}
				bodyExprs.push({expr: EBlock(stmts), pos: pos});

			case FLOW(maxWidth, maxHeight, minWidth, minHeight, lineHeight, colWidth, layout, paddingTop, paddingBottom, paddingLeft, paddingRight, horizontalSpacing, verticalSpacing, debug, multiline, bgSheet, bgTile, overflow, fillWidth, fillHeight, reverse, hAlign, vAlign):
				final stmts:Array<Expr> = [];
				stmts.push(macro final _rt_flow = new h2d.Flow());
				stmts.push(macro $containerRef.addChild(_rt_flow));
				if (maxWidth != null) stmts.push(macro _rt_flow.maxWidth = ${rvToExpr(maxWidth)});
				if (maxHeight != null) stmts.push(macro _rt_flow.maxHeight = ${rvToExpr(maxHeight)});
				if (minWidth != null) stmts.push(macro _rt_flow.minWidth = ${rvToExpr(minWidth)});
				if (minHeight != null) stmts.push(macro _rt_flow.minHeight = ${rvToExpr(minHeight)});
				if (lineHeight != null) stmts.push(macro _rt_flow.lineHeight = ${rvToExpr(lineHeight)});
				if (colWidth != null) stmts.push(macro _rt_flow.colWidth = ${rvToExpr(colWidth)});
				if (layout != null) {
					switch (layout) {
						case MFLHorizontal: stmts.push(macro _rt_flow.layout = h2d.Flow.FlowLayout.Horizontal);
						case MFLVertical: stmts.push(macro _rt_flow.layout = h2d.Flow.FlowLayout.Vertical);
						case MFLStack: stmts.push(macro _rt_flow.layout = h2d.Flow.FlowLayout.Stack);
					}
				}
				if (paddingTop != null) stmts.push(macro _rt_flow.paddingTop = ${rvToExpr(paddingTop)});
				if (paddingBottom != null) stmts.push(macro _rt_flow.paddingBottom = ${rvToExpr(paddingBottom)});
				if (paddingLeft != null) stmts.push(macro _rt_flow.paddingLeft = ${rvToExpr(paddingLeft)});
				if (paddingRight != null) stmts.push(macro _rt_flow.paddingRight = ${rvToExpr(paddingRight)});
				if (horizontalSpacing != null) stmts.push(macro _rt_flow.horizontalSpacing = ${rvToExpr(horizontalSpacing)});
				if (verticalSpacing != null) stmts.push(macro _rt_flow.verticalSpacing = ${rvToExpr(verticalSpacing)});
				if (debug) stmts.push(macro _rt_flow.debug = true);
				if (multiline) stmts.push(macro _rt_flow.multiline = true);
				if (overflow != null) {
					switch (overflow) {
						case MFOExpand: stmts.push(macro _rt_flow.overflow = h2d.Flow.FlowOverflow.Expand);
						case MFOLimit: stmts.push(macro _rt_flow.overflow = h2d.Flow.FlowOverflow.Limit);
						case MFOScroll: stmts.push(macro _rt_flow.overflow = h2d.Flow.FlowOverflow.Scroll);
						case MFOHidden: stmts.push(macro _rt_flow.overflow = h2d.Flow.FlowOverflow.Hidden);
					}
				} else {
					stmts.push(macro _rt_flow.overflow = h2d.Flow.FlowOverflow.Limit);
				}
				if (fillWidth) stmts.push(macro _rt_flow.fillWidth = true);
				if (fillHeight) stmts.push(macro _rt_flow.fillHeight = true);
				if (reverse) stmts.push(macro _rt_flow.reverse = true);
				if (hAlign != null) stmts.push(macro _rt_flow.horizontalAlign = ${flowAlignToExpr(hAlign)});
				if (vAlign != null) stmts.push(macro _rt_flow.verticalAlign = ${flowAlignToExpr(vAlign)});
				if (bgSheet != null && bgTile != null) {
					final sheetExpr = rvToExpr(bgSheet, true);
					final tileExpr = rvToExpr(bgTile, true);
					stmts.push(macro {
						final _rt_bg = this._pb.load9Patch(Std.string($sheetExpr), Std.string($tileExpr));
						_rt_flow.borderLeft = _rt_bg.borderLeft;
						_rt_flow.borderRight = _rt_bg.borderRight;
						_rt_flow.borderTop = _rt_bg.borderTop;
						_rt_flow.borderBottom = _rt_bg.borderBottom;
						_rt_flow.backgroundTile = _rt_bg.tile;
					});
				}
				if (child.pos != null) {
					switch (child.pos) {
						case OFFSET(x, y):
							final xExpr = rvToExpr(x);
							final yExpr = rvToExpr(y);
							stmts.push(macro _rt_flow.setPosition($xExpr, $yExpr));
						default:
					}
				}
				if (child.scale != null) {
					final scaleExpr = rvToExpr(child.scale);
					stmts.push(macro _rt_flow.scaleX = $scaleExpr);
					stmts.push(macro _rt_flow.scaleY = $scaleExpr);
				}
				if (child.rotation != null) {
					final rotExpr = rvToExpr(child.rotation);
					stmts.push(macro _rt_flow.rotation = hxd.Math.degToRad($rotExpr));
				}
				if (child.alpha != null) {
					final alphaExpr = rvToExpr(child.alpha);
					stmts.push(macro _rt_flow.alpha = $alphaExpr);
				}
				if (child.children != null) {
					for (grandchild in child.children) {
						final innerStmts:Array<Expr> = [];
						generateRuntimeChildExprs(grandchild, repeatType, macro _rt_flow, innerStmts, pos);
						for (s in innerStmts)
							stmts.push(s);
					}
				}
				bodyExprs.push({expr: EBlock(stmts), pos: pos});

			default:
				// Forward unsupported node types to the builder at runtime
				final progName = currentProgrammableName;
				final nodeName = child.uniqueNodeName;
				bodyExprs.push(macro {
					final _rt_obj = this._pb.buildNodeByUniqueName($v{progName}, $v{nodeName});
					if (_rt_obj != null) $containerRef.addChild(_rt_obj);
				});
		}
	}

	/** Fallback for unsupported repeat iterator types — empty container */
	static function processRepeatFallback(node:Node, parentField:String, fields:Array<Field>, ctorExprs:Array<Expr>, siblings:Array<{node:Node, fieldName:String}>, pos:Position):Void {
		final fieldName = "_e" + (elementCounter++);
		fields.push(makeField(fieldName, FVar(macro :h2d.Object, null), [APrivate], pos));
		ctorExprs.push(macro $p{["this", fieldName]} = new h2d.Object());
		final parentRef = parentField != null ? (macro $p{["this", parentField]}) : (macro this);
		ctorExprs.push(macro $parentRef.addChild($p{["this", fieldName]}));
		siblings.push({node: node, fieldName: fieldName});
	}

	/** Process a REPEAT2D node */
	static function processRepeat2D(node:Node, varNameX:String, varNameY:String, repeatTypeX:RepeatType, repeatTypeY:RepeatType, parentField:String, fields:Array<Field>, ctorExprs:Array<Expr>, siblings:Array<{node:Node, fieldName:String}>, pos:Position):Void {
		final infoX = resolveRepeatInfo(repeatTypeX);
		final infoY = resolveRepeatInfo(repeatTypeY);
		if (infoX == null || infoY == null) {
			processRepeatFallback(node, parentField, fields, ctorExprs, siblings, pos);
			return;
		}

		// Create the 2D repeat container
		final containerName = "_e" + (elementCounter++);
		fields.push(makeField(containerName, FVar(macro :h2d.Object, null), [APrivate], pos));
		ctorExprs.push(macro $p{["this", containerName]} = new h2d.Object());

		ensureHexLayoutIfNeeded(node.pos, node, fields, ctorExprs, pos);
		final posExpr = generatePositionExpr(node.pos, containerName, pos, node);
		if (posExpr != null)
			ctorExprs.push(posExpr);

		final repeat2dSentinel = createSentinelIfConditional(node, parentField, fields, ctorExprs, pos);
		final parentRef = parentField != null ? (macro $p{["this", parentField]}) : (macro this);
		ctorExprs.push(macro $parentRef.addChild($p{["this", containerName]}));

		final visCond = generateVisibilityCondition(node, siblings, containerName, pos);
		if (visCond != null)
			visibilityEntries.push({fieldName: containerName, condition: visCond, paramRefs: extractConditionalParamRefs(node, siblings),
				sentinelField: repeat2dSentinel, parentField: parentField, layer: node.layer, restoreFlowPropsExpr: null});
		siblings.push({node: node, fieldName: containerName});

		if (infoX.staticCount != null && infoY.staticCount != null) {
			// Both axes static: fully unroll
			unrollRepeat2DChildren(node, varNameX, varNameY, infoX, infoY, containerName, fields, ctorExprs, pos);
		} else {
			// At least one axis is param-dependent: runtime rebuild
			rebuildRepeat2DChildren(node, varNameX, varNameY, infoX, infoY, repeatTypeX, repeatTypeY, containerName, fields, ctorExprs, pos);
		}
	}

	/** Unroll 2D repeat: static countX * countY copies */
	static function unrollRepeat2DChildren(node:Node, varNameX:String, varNameY:String, infoX:{staticCount:Null<Int>, dx:Int, dy:Int, rangeStart:Int, rangeStep:Int, countRV:Null<ReferenceableValue>}, infoY:{staticCount:Null<Int>, dx:Int, dy:Int, rangeStart:Int, rangeStep:Int, countRV:Null<ReferenceableValue>}, containerField:String, fields:Array<Field>, ctorExprs:Array<Expr>, pos:Position):Void {
		if (node.children == null) return;

		for (iy in 0...infoY.staticCount) {
			final resolvedY = infoY.rangeStart + iy * infoY.rangeStep;
			loopVarSubstitutions.set(varNameY, resolvedY);

			for (ix in 0...infoX.staticCount) {
				final resolvedX = infoX.rangeStart + ix * infoX.rangeStep;
				loopVarSubstitutions.set(varNameX, resolvedX);

				final totalDx:Float = infoX.dx * ix + infoY.dx * iy;
				final totalDy:Float = infoX.dy * ix + infoY.dy * iy;

				if (totalDx != 0 || totalDy != 0) {
					final iterContainerName = "_e" + (elementCounter++);
					fields.push(makeField(iterContainerName, FVar(macro :h2d.Object, null), [APrivate], pos));
					ctorExprs.push(macro $p{["this", iterContainerName]} = new h2d.Object());
					ctorExprs.push(macro $p{["this", iterContainerName]}.setPosition($v{totalDx}, $v{totalDy}));
					ctorExprs.push(macro $p{["this", containerField]}.addChild($p{["this", iterContainerName]}));
					processChildren(node.children, iterContainerName, fields, ctorExprs, [], pos);
				} else {
					processChildren(node.children, containerField, fields, ctorExprs, [], pos);
				}

				loopVarSubstitutions.remove(varNameX);
			}
			loopVarSubstitutions.remove(varNameY);
		}
	}

	/** Runtime rebuild 2D repeat: generates a method that creates/recreates children based on count params */
	static function rebuildRepeat2DChildren(node:Node, varNameX:String, varNameY:String, infoX:{staticCount:Null<Int>, dx:Int, dy:Int, rangeStart:Int, rangeStep:Int, countRV:Null<ReferenceableValue>}, infoY:{staticCount:Null<Int>, dx:Int, dy:Int, rangeStart:Int, rangeStep:Int, countRV:Null<ReferenceableValue>}, repeatTypeX:RepeatType, repeatTypeY:RepeatType, containerField:String, fields:Array<Field>, ctorExprs:Array<Expr>, pos:Position):Void {
		if (node.children == null) return;

		final countXExpr:Expr = if (infoX.staticCount != null) macro $v{infoX.staticCount} else switch (repeatTypeX) {
			case RangeIterator(start, end, step):
				final endExpr = rvToExpr(end);
				final startExpr = rvToExpr(start);
				final stepExpr = rvToExpr(step);
				macro Math.ceil(($endExpr - $startExpr) / $stepExpr);
			case StepIterator(_, _, repeats): rvToExpr(repeats);
			default: macro 0;
		};

		final countYExpr:Expr = if (infoY.staticCount != null) macro $v{infoY.staticCount} else switch (repeatTypeY) {
			case RangeIterator(start, end, step):
				final endExpr = rvToExpr(end);
				final startExpr = rvToExpr(start);
				final stepExpr = rvToExpr(step);
				macro Math.ceil(($endExpr - $startExpr) / $stepExpr);
			case StepIterator(_, _, repeats): rvToExpr(repeats);
			default: macro 0;
		};

		// Use runtimeLoopVars so rvToExpr generates runtime references
		runtimeLoopVars.set(varNameX, "_rt_ix");
		runtimeLoopVars.set(varNameY, "_rt_iy");

		// Build loop body expressions from child nodes
		final containerRef = macro _rt_cont;
		final loopBodyExprs:Array<Expr> = [];
		if (node.children != null) {
			for (child in node.children) {
				generateRuntimeChildExprs(child, repeatTypeX, containerRef, loopBodyExprs, pos);
			}
		}

		runtimeLoopVars.remove(varNameX);
		runtimeLoopVars.remove(varNameY);

		// Build inner loop body: create container, position, add children
		final innerBodyExprs:Array<Expr> = [];
		innerBodyExprs.push(macro final _rt_cont = new h2d.Object());
		final dxX:Float = infoX.dx;
		final dyX:Float = infoX.dy;
		final dxY:Float = infoY.dx;
		final dyY:Float = infoY.dy;
		if (dxX != 0 || dyX != 0 || dxY != 0 || dyY != 0) {
			innerBodyExprs.push(macro _rt_cont.setPosition($v{dxX} * _rt_ix + $v{dxY} * _rt_iy, $v{dyX} * _rt_ix + $v{dyY} * _rt_iy));
		}
		final containerFieldRef = macro $p{["this", containerField]};
		innerBodyExprs.push(macro $containerFieldRef.addChild(_rt_cont));
		for (e in loopBodyExprs) innerBodyExprs.push(e);

		final innerBody:Expr = {expr: EBlock(innerBodyExprs), pos: pos};

		// Generate rebuild method
		final rebuildMethodName = "_rebuildRepeat_" + containerField;
		final countTrackingField = rebuildMethodName + "_n";

		// Tracking field: encode both counts as countX * 10000 + countY for change detection
		fields.push(makeField(countTrackingField, FVar(macro :Int, macro -1), [APrivate], pos));

		final rebuildBody:Array<Expr> = [];
		rebuildBody.push(macro {
			final _rt_key = _rt_countX * 10000 + _rt_countY;
			if (_rt_key == $p{["this", countTrackingField]}) return;
			$p{["this", countTrackingField]} = _rt_key;
		});
		rebuildBody.push(macro $containerFieldRef.removeChildren());
		rebuildBody.push(macro for (_rt_iy in 0..._rt_countY) for (_rt_ix in 0..._rt_countX) $innerBody);

		fields.push(makeMethod(rebuildMethodName, rebuildBody, [
			{name: "_rt_countX", type: macro :Int},
			{name: "_rt_countY", type: macro :Int},
		], macro :Void, [APrivate], pos));

		// Call rebuild in constructor
		ctorExprs.push(macro $i{rebuildMethodName}(Std.int($countXExpr), Std.int($countYExpr)));

		// Register for rebuild on param change
		repeatRebuildEntries.push({
			callExpr: macro $i{rebuildMethodName}(Std.int($countXExpr), Std.int($countYExpr)),
		});
	}

	// ==================== Node Creation ====================

	static function generateCreateExpr(node:Node, fieldName:String, pos:Position):Null<CreateResult> {
		return switch (node.type) {
			case POINT: {
					fieldType: macro :h2d.Object,
					createExprs: [macro $p{["this", fieldName]} = new h2d.Object()],
					isContainer: true,
					exprUpdates: [],
				};

			case LAYERS: {
					fieldType: macro :h2d.Layers,
					createExprs: [macro $p{["this", fieldName]} = new h2d.Layers()],
					isContainer: true,
					exprUpdates: [],
				};

			case BITMAP(tileSource, hAlign, vAlign):
				generateBitmapCreate(node, fieldName, tileSource, hAlign, vAlign, pos);

			case TEXT(textDef):
				generateTextCreate(node, fieldName, textDef, false, pos);

			case RICHTEXT(textDef):
				generateTextCreate(node, fieldName, textDef, true, pos);

			case NINEPATCH(sheet, tilename, width, height):
				generateNinepatchCreate(node, fieldName, sheet, tilename, width, height, pos);

			case MASK(w, h):
				final wExpr = rvToExpr(w);
				final hExpr = rvToExpr(h);
				{
					fieldType: macro :h2d.Mask,
					createExprs: [macro $p{["this", fieldName]} = new h2d.Mask(Math.round($wExpr), Math.round($hExpr))],
					isContainer: true,
					exprUpdates: [],
				};

			case FLOW(maxWidth, maxHeight, minWidth, minHeight, lineHeight, colWidth, layout, paddingTop, paddingBottom, paddingLeft, paddingRight, horizontalSpacing, verticalSpacing, debug, multiline, bgSheet, bgTile, overflow, fillWidth, fillHeight, reverse, hAlign, vAlign):
				generateFlowCreate(node, fieldName, maxWidth, maxHeight, minWidth, minHeight, lineHeight, colWidth, layout, paddingTop, paddingBottom, paddingLeft, paddingRight, horizontalSpacing, verticalSpacing, debug, multiline, bgSheet, bgTile, overflow, fillWidth, fillHeight, reverse, hAlign, vAlign, pos);

			case SPACER(width, height):
				generateSpacerCreate(node, fieldName, width, height, pos);

			case SLOT(parameters, _):
				// Plain slots: container with children generated by codegen
				// Parameterized slots: container only (children built at runtime via IncrementalUpdateContext)
				return {
					createExprs: [macro $p{["this", fieldName]} = new h2d.Object()],
					fieldType: macro :h2d.Object,
					isContainer: parameters == null,
					exprUpdates: [],
				};

			case SLOT_CONTENT:
				return {
					createExprs: [
						macro $p{["this", fieldName]} = new bh.multianim.MultiAnimBuilder.SlotContentRoot(),
					],
					fieldType: macro :h2d.Object,
					isContainer: true,
					exprUpdates: [],
				};

			case INTERACTIVE(w, h, id, debug, metadata):
				final wExpr = rvToExpr(w);
				final hExpr = rvToExpr(h);
				final idExpr = rvToExpr(id);
				final debugExpr:Expr = debug ? macro true : macro false;
				final metaExpr:Expr = if (metadata == null) {
					macro null;
				} else {
					final entries:Array<Expr> = [];
					for (entry in metadata) {
						final keyExpr = rvToExpr(entry.key, true);
						final valExpr:Expr = switch entry.type {
							case SVTInt: final v = rvToExpr(entry.value); macro bh.multianim.MultiAnimParser.SettingValue.RSVInt($v);
							case SVTFloat: final v = rvToExpr(entry.value); macro bh.multianim.MultiAnimParser.SettingValue.RSVFloat($v);
							case SVTString: final v = rvToExpr(entry.value, true); macro bh.multianim.MultiAnimParser.SettingValue.RSVString($v);
							case SVTColor: final v = rvToExpr(entry.value); macro bh.multianim.MultiAnimParser.SettingValue.RSVColor($v);
							case SVTBool: final v = rvToExpr(entry.value); macro bh.multianim.MultiAnimParser.SettingValue.RSVBool($v != 0);
						};
						entries.push(macro m.set($keyExpr, $valExpr));
					}
					final setBlock:Expr = {expr: EBlock(entries), pos: Context.currentPos()};
					macro {
						var m = new Map<String, bh.multianim.MultiAnimParser.SettingValue>();
						$setBlock;
						m;
					};
				};
				{
					fieldType: macro :bh.base.MAObject,
					createExprs: [
						macro $p{["this", fieldName]} = new bh.base.MAObject(
							bh.base.MAObject.MultiAnimObjectData.MAInteractive($wExpr, $hExpr, $idExpr, $metaExpr), $debugExpr)
					],
					isContainer: false,
					exprUpdates: [],
				};

			case PLACEHOLDER(type, source):
				generatePlaceholderCreate(node, fieldName, type, source, pos);

			case STATIC_REF(externalReference, programmableRef, parameters):
				generateStaticRefCreate(node, fieldName, externalReference, programmableRef, parameters, pos);

			case DYNAMIC_REF(externalReference, programmableRef, parameters):
				generateDynamicRefCreate(node, fieldName, externalReference, programmableRef, parameters, pos);

			case REPEAT(_, _) | REPEAT2D(_, _, _, _):
				// Should not be reached — processNode handles REPEAT/REPEAT2D directly
				null;

			case GRAPHICS(elements):
				generateGraphicsCreate(node, fieldName, elements, pos);

			case PIXELS(shapes):
				generatePixelsCreate(node, fieldName, shapes, pos);

			case PARTICLES(particlesDef):
				generateParticlesCreate(node, fieldName, particlesDef, pos);

			case STATEANIM(filename, initialState, selectorReferences):
				generateStateAnimCreate(node, fieldName, filename, initialState, selectorReferences, pos);

			case STATEANIM_CONSTRUCT(initialState, construct, externallyDriven):
				generateStateAnimConstructCreate(node, fieldName, initialState, construct, externallyDriven, pos);

			case TILEGROUP:
				generateTileGroupCreate(node, fieldName, pos);

			default: null;
		};
	}

	// ==================== StaticRef ====================

	static function generateStaticRefCreate(node:Node, fieldName:String, externalReference:Null<String>,
			programmableRef:String, parameters:Map<String, ReferenceableValue>, pos:Position):CreateResult {
		final fieldRef = macro $p{["this", fieldName]};
		final createExprs:Array<Expr> = [];
		final refNameExpr:Expr = macro $v{programmableRef};

		// Build parameter map at runtime: new Map<String,Dynamic>()
		final mapBuildExprs:Array<Expr> = [macro final _refParams = new Map<String, Dynamic>()];
		if (parameters != null) {
			for (key => val in parameters) {
				final keyExpr:Expr = macro $v{key};
				final valExpr = rvToExpr(val);
				mapBuildExprs.push(macro _refParams.set($keyExpr, $valExpr));
			}
		}
		final extRefExpr:Expr = externalReference != null ? macro $v{externalReference} : macro null;
		mapBuildExprs.push(macro {
			final _result = this._pb.buildStaticRef($refNameExpr, _refParams, $extRefExpr);
			$fieldRef = _result != null ? _result.object : new h2d.Object();
		});

		createExprs.push(macro $b{mapBuildExprs});

		return {
			fieldType: macro :h2d.Object,
			createExprs: createExprs,
			isContainer: false,
			exprUpdates: [],
		};
	}

	// ==================== DynamicRef ====================

	static function generateDynamicRefCreate(node:Node, fieldName:String, externalReference:Null<String>,
			programmableRef:String, parameters:Map<String, ReferenceableValue>, pos:Position):CreateResult {
		final fieldRef = macro $p{["this", fieldName]};
		final createExprs:Array<Expr> = [];
		final refNameExpr:Expr = macro $v{programmableRef};

		final resultField = "_comp_" + programmableRef;

		// Build parameter map at runtime
		final mapBuildExprs:Array<Expr> = [macro final _refParams = new Map<String, Dynamic>()];
		if (parameters != null) {
			for (key => val in parameters) {
				final keyExpr:Expr = macro $v{key};
				final valExpr = rvToExpr(val);
				mapBuildExprs.push(macro _refParams.set($keyExpr, $valExpr));
			}
		}
		// Build with incremental: true
		final dynExtRefExpr:Expr = externalReference != null ? macro $v{externalReference} : macro null;
		mapBuildExprs.push(macro {
			final _result = this._pb.buildDynamicRef($refNameExpr, _refParams, $dynExtRefExpr);
			$fieldRef = _result != null ? _result.object : new h2d.Object();
			$p{["this", resultField]} = _result;
		});

		createExprs.push(macro $b{mapBuildExprs});

		return {
			fieldType: macro :h2d.Object,
			createExprs: createExprs,
			isContainer: false,
			exprUpdates: [],
		};
	}

	// ==================== Placeholder ====================

	static function generatePlaceholderCreate(node:Node, fieldName:String, type:MultiAnimParser.PlaceholderTypes,
			source:MultiAnimParser.PlaceholderReplacementSource, pos:Position):CreateResult {
		final fieldRef = macro $p{["this", fieldName]};
		final createExprs:Array<Expr> = [];

		// Generate the callback/source resolution call
		final callExpr:Expr = switch (source) {
			case PRSCallback(callbackName):
				final nameExpr = rvToExpr(callbackName);
				macro this._pb.buildPlaceholderViaCallback($nameExpr);
			case PRSCallbackWithIndex(callbackName, index):
				final nameExpr = rvToExpr(callbackName);
				final idxExpr = rvToExpr(index);
				macro this._pb.buildPlaceholderViaCallbackWithIndex($nameExpr, $idxExpr);
			case PRSBuilderParameterSource(callbackName):
				hasBuilderParameterPlaceholders = true;
				final nameExpr = rvToExpr(callbackName);
				final settingsExpr = nodeSettingsToExpr(node);
				macro this._pb.buildPlaceholderViaSource($nameExpr, $settingsExpr);
		};

		// Generate fallback expression based on placeholder type
		final fallbackExpr:Expr = switch (type) {
			case PHTileSource(tileSource):
				final tileExpr = tileSourceToExpr(tileSource);
				macro new h2d.Bitmap($tileExpr);
			case PHNothing:
				macro new h2d.Object();
			case PHError:
				macro new h2d.Object();
		};

		createExprs.push(macro {
			final _phResult = $callExpr;
			$fieldRef = _phResult != null ? _phResult : $fallbackExpr;
		});

		return {
			fieldType: macro :h2d.Object,
			createExprs: createExprs,
			isContainer: true,
			exprUpdates: [],
		};
	}

	// ==================== Graphics ====================

	static function generateGraphicsCreate(node:Node, fieldName:String, elements:Array<PositionedGraphicsElement>, pos:Position):CreateResult {
		final fieldRef = macro $p{["this", fieldName]};
		final createExprs:Array<Expr> = [macro $fieldRef = new h2d.Graphics()];

		// Generate draw calls for each element
		for (item in elements) {
			final drawExprs = generateGraphicsElementExprs(fieldRef, item.element, item.pos, node, pos);
			for (de in drawExprs)
				createExprs.push(de);
		}

		return {
			fieldType: macro :h2d.Graphics,
			createExprs: createExprs,
			isContainer: false,
			exprUpdates: [],
		};
	}

	static function generateGraphicsElementExprs(gRef:Expr, element:GraphicsElement, elementPos:Coordinates, node:Node, pos:Position):Array<Expr> {
		final exprs:Array<Expr> = [];

		// Resolve element position offset
		final elPos = coordsToXYExprs(elementPos, pos, node);
		var posXExpr:Expr = elPos.x;
		var posYExpr:Expr = elPos.y;

		// Reset line style before each element
		exprs.push(macro {
			final _g:h2d.Graphics = cast $gRef;
			_g.lineStyle();
		});

		switch (element) {
			case GERect(color, style, width, height):
				final cExpr = rvToExpr(color);
				final wExpr = rvToExpr(width);
				final hExpr = rvToExpr(height);
				switch (style) {
					case GSFilled:
						exprs.push(macro {
							final _g:h2d.Graphics = cast $gRef;
							var c:Int = $cExpr;
							if (c >>> 24 == 0) c |= 0xFF000000;
							_g.beginFill(c);
							_g.drawRect($posXExpr, $posYExpr, $wExpr, $hExpr);
							_g.endFill();
						});
					case GSLineWidth(lw):
						final lwExpr = rvToExpr(lw);
						exprs.push(macro {
							final _g:h2d.Graphics = cast $gRef;
							var c:Int = $cExpr;
							if (c >>> 24 == 0) c |= 0xFF000000;
							_g.lineStyle($lwExpr, c);
							_g.drawRect($posXExpr, $posYExpr, $wExpr, $hExpr);
							_g.lineStyle();
						});
				}

			case GECircle(color, style, radius):
				final cExpr = rvToExpr(color);
				final rExpr = rvToExpr(radius);
				switch (style) {
					case GSFilled:
						exprs.push(macro {
							final _g:h2d.Graphics = cast $gRef;
							var c:Int = $cExpr;
							if (c >>> 24 == 0) c |= 0xFF000000;
							_g.beginFill(c);
							_g.drawCircle($posXExpr, $posYExpr, $rExpr);
							_g.endFill();
						});
					case GSLineWidth(lw):
						final lwExpr = rvToExpr(lw);
						exprs.push(macro {
							final _g:h2d.Graphics = cast $gRef;
							var c:Int = $cExpr;
							if (c >>> 24 == 0) c |= 0xFF000000;
							_g.lineStyle($lwExpr, c);
							_g.drawCircle($posXExpr, $posYExpr, $rExpr);
							_g.lineStyle();
						});
				}

			case GEEllipse(color, style, width, height):
				final cExpr = rvToExpr(color);
				final wExpr = rvToExpr(width);
				final hExpr = rvToExpr(height);
				switch (style) {
					case GSFilled:
						exprs.push(macro {
							final _g:h2d.Graphics = cast $gRef;
							var c:Int = $cExpr;
							if (c >>> 24 == 0) c |= 0xFF000000;
							_g.beginFill(c);
							_g.drawEllipse($posXExpr, $posYExpr, $wExpr, $hExpr);
							_g.endFill();
						});
					case GSLineWidth(lw):
						final lwExpr = rvToExpr(lw);
						exprs.push(macro {
							final _g:h2d.Graphics = cast $gRef;
							var c:Int = $cExpr;
							if (c >>> 24 == 0) c |= 0xFF000000;
							_g.lineStyle($lwExpr, c);
							_g.drawEllipse($posXExpr, $posYExpr, $wExpr, $hExpr);
							_g.lineStyle();
						});
				}

			case GERoundRect(color, style, width, height, radius):
				final cExpr = rvToExpr(color);
				final wExpr = rvToExpr(width);
				final hExpr = rvToExpr(height);
				final radExpr = rvToExpr(radius);
				switch (style) {
					case GSFilled:
						exprs.push(macro {
							final _g:h2d.Graphics = cast $gRef;
							var c:Int = $cExpr;
							if (c >>> 24 == 0) c |= 0xFF000000;
							_g.beginFill(c);
							_g.drawRoundedRect($posXExpr, $posYExpr, $wExpr, $hExpr, $radExpr);
							_g.endFill();
						});
					case GSLineWidth(lw):
						final lwExpr = rvToExpr(lw);
						exprs.push(macro {
							final _g:h2d.Graphics = cast $gRef;
							var c:Int = $cExpr;
							if (c >>> 24 == 0) c |= 0xFF000000;
							_g.lineStyle($lwExpr, c);
							_g.drawRoundedRect($posXExpr, $posYExpr, $wExpr, $hExpr, $radExpr);
							_g.lineStyle();
						});
				}

			case GEArc(color, style, radius, startAngle, arcAngle):
				final cExpr = rvToExpr(color);
				final rExpr = rvToExpr(radius);
				final saExpr = rvToExpr(startAngle);
				final aaExpr = rvToExpr(arcAngle);
				switch (style) {
					case GSLineWidth(lw):
						final lwExpr = rvToExpr(lw);
						exprs.push(macro {
							final _g:h2d.Graphics = cast $gRef;
							var c:Int = $cExpr;
							if (c >>> 24 == 0) c |= 0xFF000000;
							_g.lineStyle($lwExpr, c);
							_g.drawPie($posXExpr, $posYExpr, $rExpr, hxd.Math.degToRad($saExpr), hxd.Math.degToRad($aaExpr));
							_g.lineStyle();
						});
					case GSFilled:
						exprs.push(macro {
							final _g:h2d.Graphics = cast $gRef;
							var c:Int = $cExpr;
							if (c >>> 24 == 0) c |= 0xFF000000;
							_g.lineStyle(1.0, c);
							_g.drawPie($posXExpr, $posYExpr, $rExpr, hxd.Math.degToRad($saExpr), hxd.Math.degToRad($aaExpr));
							_g.lineStyle();
						});
				}

			case GELine(color, lineWidth, start, end):
				final cExpr = rvToExpr(color);
				final lwExpr = rvToExpr(lineWidth);
				final startXY = coordsToXYExprs(start, pos, node);
				final endXY = coordsToXYExprs(end, pos, node);
				final sxExpr = startXY.x;
				final syExpr = startXY.y;
				final exExpr = endXY.x;
				final eyExpr = endXY.y;
				exprs.push(macro {
					final _g:h2d.Graphics = cast $gRef;
					var c:Int = $cExpr;
					if (c >>> 24 == 0) c |= 0xFF000000;
					_g.lineStyle($lwExpr, c);
					_g.moveTo($posXExpr + $sxExpr, $posYExpr + $syExpr);
					_g.lineTo($posXExpr + $exExpr, $posYExpr + $eyExpr);
					_g.lineStyle();
				});

			case GEPolygon(color, style, points):
				final cExpr = rvToExpr(color);
				// Build polygon point arrays at compile time
				final xExprs:Array<Expr> = [];
				final yExprs:Array<Expr> = [];
				for (p in points) {
					switch (p) {
						case OFFSET(x, y):
							xExprs.push(rvToExpr(x));
							yExprs.push(rvToExpr(y));
						case ZERO | null:
							xExprs.push(macro 0.0);
							yExprs.push(macro 0.0);
						default:
							xExprs.push(macro 0.0);
							yExprs.push(macro 0.0);
					}
				}
				if (xExprs.length > 0) {
					final polyExprs:Array<Expr> = [];

					switch (style) {
						case GSFilled:
							polyExprs.push(macro {
								var c:Int = $cExpr;
								if (c >>> 24 == 0) c |= 0xFF000000;
								final _g:h2d.Graphics = cast $gRef;
								_g.beginFill(c);
							});
						case GSLineWidth(lw):
							final lwExpr = rvToExpr(lw);
							polyExprs.push(macro {
								var c:Int = $cExpr;
								if (c >>> 24 == 0) c |= 0xFF000000;
								final _g:h2d.Graphics = cast $gRef;
								_g.lineStyle($lwExpr, c);
							});
					}

					// moveTo first point
					final fx = xExprs[0];
					final fy = yExprs[0];
					polyExprs.push(macro {
						final _g:h2d.Graphics = cast $gRef;
						_g.moveTo($posXExpr + $fx, $posYExpr + $fy);
					});

					// lineTo remaining points
					for (i in 1...xExprs.length) {
						final px = xExprs[i];
						final py = yExprs[i];
						polyExprs.push(macro {
							final _g:h2d.Graphics = cast $gRef;
							_g.lineTo($posXExpr + $px, $posYExpr + $py);
						});
					}

					// Close polygon
					polyExprs.push(macro {
						final _g:h2d.Graphics = cast $gRef;
						_g.lineTo($posXExpr + $fx, $posYExpr + $fy);
					});

					switch (style) {
						case GSFilled:
							polyExprs.push(macro {
								final _g:h2d.Graphics = cast $gRef;
								_g.endFill();
							});
						case GSLineWidth(_):
							polyExprs.push(macro {
								final _g:h2d.Graphics = cast $gRef;
								_g.lineStyle();
							});
					}

					exprs.push(macro $b{polyExprs});
				}
		}

		return exprs;
	}

	// ==================== Pixels ====================

	/** Resolve a Coordinates value to compile-time {x:Float, y:Float}, supporting all coordinate types */
	static function coordsToStaticXY(coords:Coordinates, pos:Position, ?node:MultiAnimParser.Node):Null<{x:Float, y:Float}> {
		if (coords == null) return {x: 0.0, y: 0.0};
		return switch (coords) {
			case ZERO: {x: 0.0, y: 0.0};
			case OFFSET(xrv, yrv):
				final xVal = resolveRVStatic(xrv);
				final yVal = resolveRVStatic(yrv);
				if (xVal != null && yVal != null) {x: xVal, y: yVal} else null;
			case SELECTED_GRID_POSITION(gridX, gridY):
				final grid = getGridFromNode(node);
				final gx = resolveRVStatic(gridX);
				final gy = resolveRVStatic(gridY);
				if (grid != null && gx != null && gy != null) {x: gx * grid.spacingX, y: gy * grid.spacingY} else null;
			case SELECTED_HEX_CUBE(q, r, s):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final qv = resolveRVStatic(q);
					final rv2 = resolveRVStatic(r);
					final sv = resolveRVStatic(s);
					if (qv != null && rv2 != null && sv != null) {
						final hex = new bh.base.Hex.FractionalHex(qv, rv2, sv).round();
						final pt = hexLayout.hexToPixel(hex);
						{x: pt.x, y: pt.y};
					} else null;
				} else null;
			case SELECTED_HEX_OFFSET(col, row, parity):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final c = resolveRVStatic(col);
					final r2 = resolveRVStatic(row);
					if (c != null && r2 != null) {
						final parityVal = switch (parity) { case EVEN: bh.base.Hex.OffsetCoord.EVEN; case ODD: bh.base.Hex.OffsetCoord.ODD; };
						final hex = switch (hexLayout.orientation) {
							case POINTY: bh.base.Hex.OffsetCoord.qoffsetToCube(parityVal, new bh.base.Hex.OffsetCoord(Std.int(c), Std.int(r2)));
							case FLAT: bh.base.Hex.OffsetCoord.roffsetToCube(parityVal, new bh.base.Hex.OffsetCoord(Std.int(c), Std.int(r2)));
						};
						final pt = hexLayout.hexToPixel(hex);
						{x: pt.x, y: pt.y};
					} else null;
				} else null;
			case SELECTED_HEX_DOUBLED(col2, row2):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final c = resolveRVStatic(col2);
					final r2 = resolveRVStatic(row2);
					if (c != null && r2 != null) {
						final hex = switch (hexLayout.orientation) {
							case POINTY: bh.base.Hex.DoubledCoord.qdoubledToCube(new bh.base.Hex.DoubledCoord(Std.int(c), Std.int(r2)));
							case FLAT: bh.base.Hex.DoubledCoord.rdoubledToCube(new bh.base.Hex.DoubledCoord(Std.int(c), Std.int(r2)));
						};
						final pt = hexLayout.hexToPixel(hex);
						{x: pt.x, y: pt.y};
					} else null;
				} else null;
			case SELECTED_HEX_PIXEL(px, py):
				// pixelToHex can't be statically resolved at macro time
				null;
			case SELECTED_HEX_CELL_CORNER(cell, cornerIndex, factor):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final ci = resolveRVStatic(cornerIndex);
					final f = resolveRVStatic(factor);
					final cellHex = resolveCoordToStaticHex(cell, hexLayout);
					if (ci != null && f != null && cellHex != null) {
						final pt = hexLayout.polygonCorner(cellHex, Std.int(ci), f);
						{x: pt.x, y: pt.y};
					} else null;
				} else null;
			case SELECTED_HEX_CELL_EDGE(cell, direction, factor):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final d = resolveRVStatic(direction);
					final f = resolveRVStatic(factor);
					final cellHex = resolveCoordToStaticHex(cell, hexLayout);
					if (d != null && f != null && cellHex != null) {
						final pt = hexLayout.polygonEdge(cellHex, Std.int(d), f);
						{x: pt.x, y: pt.y};
					} else null;
				} else null;
			case SELECTED_HEX_CORNER(count, factor):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final c = resolveRVStatic(count);
					final f = resolveRVStatic(factor);
					if (c != null && f != null) {
						final pt = hexLayout.polygonCorner(bh.base.Hex.zero(), Std.int(c), f);
						{x: pt.x, y: pt.y};
					} else null;
				} else null;
			case SELECTED_HEX_EDGE(direction, factor):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final d = resolveRVStatic(direction);
					final f = resolveRVStatic(factor);
					if (d != null && f != null) {
						final pt = hexLayout.polygonEdge(bh.base.Hex.zero(), Std.int(d), f);
						{x: pt.x, y: pt.y};
					} else null;
				} else null;
			case LAYOUT(layoutName, index):
				final idx = index != null ? resolveRVStatic(index) : 0.0;
				if (idx != null) resolveLayoutPosition(layoutName, Std.int(idx)) else null;
			case NAMED_COORD(name, coord):
				final namedCS = if (node != null) getNamedCoordSystem(name, node) else null;
				if (namedCS != null) {
					resolveNamedCoordStatic(namedCS, coord, pos, node);
				} else null;
			case WITH_OFFSET(base, offsetX, offsetY):
				final basePt = coordsToStaticXY(base, pos, node);
				final ox = resolveRVStatic(offsetX);
				final oy = resolveRVStatic(offsetY);
				if (basePt != null && ox != null && oy != null) {x: basePt.x + ox, y: basePt.y + oy} else null;
			case EXTRA_POINT_REF(_, _, _) | EXTRA_POINT_ANIM(_, _, _, _, _):
				null; // requires runtime resolution — not available at macro time
		};
	}

	/** Resolve a named coordinate system's inner coordinate statically */
	static function resolveNamedCoordStatic(namedCS:CoordinateSystems.CoordinateSystemDef, coord:Coordinates, pos:Position, node:MultiAnimParser.Node):Null<{x:Float, y:Float}> {
		switch (namedCS) {
			case NamedGrid(system):
				return switch (coord) {
					case SELECTED_GRID_POSITION(gridX, gridY):
						final gx = resolveRVStatic(gridX);
						final gy = resolveRVStatic(gridY);
						if (gx != null && gy != null) {x: system.spacingX * gx, y: system.spacingY * gy} else null;
					default: null;
				};
			case NamedHex(system):
				final hexLayout = system.hexLayout;
				return switch (coord) {
					case SELECTED_HEX_CUBE(q, r, s):
						final qv = resolveRVStatic(q);
						final rv2 = resolveRVStatic(r);
						final sv = resolveRVStatic(s);
						if (qv != null && rv2 != null && sv != null) {
							final hex = new bh.base.Hex.FractionalHex(qv, rv2, sv).round();
							final pt = hexLayout.hexToPixel(hex);
							{x: pt.x, y: pt.y};
						} else null;
					case SELECTED_HEX_CORNER(count, factor):
						final c = resolveRVStatic(count);
						final f = resolveRVStatic(factor);
						if (c != null && f != null) {
							final pt = hexLayout.polygonCorner(bh.base.Hex.zero(), Std.int(c), f);
							{x: pt.x, y: pt.y};
						} else null;
					case SELECTED_HEX_EDGE(direction, factor):
						final d = resolveRVStatic(direction);
						final f = resolveRVStatic(factor);
						if (d != null && f != null) {
							final pt = hexLayout.polygonEdge(bh.base.Hex.zero(), Std.int(d), f);
							{x: pt.x, y: pt.y};
						} else null;
					default: null;
				};
		}
	}

	/** Resolve a cell Coordinates to a static Hex for use in cell-relative operations */
	static function resolveCoordToStaticHex(cell:Coordinates, hexLayout:bh.base.Hex.HexLayout):Null<bh.base.Hex> {
		return switch (cell) {
			case SELECTED_HEX_CUBE(q, r, s):
				final qv = resolveRVStatic(q);
				final rv2 = resolveRVStatic(r);
				final sv = resolveRVStatic(s);
				if (qv != null && rv2 != null && sv != null)
					new bh.base.Hex.FractionalHex(qv, rv2, sv).round()
				else null;
			case SELECTED_HEX_OFFSET(col, row, parity):
				final c = resolveRVStatic(col);
				final r2 = resolveRVStatic(row);
				if (c != null && r2 != null) {
					final parityVal = switch (parity) { case EVEN: bh.base.Hex.OffsetCoord.EVEN; case ODD: bh.base.Hex.OffsetCoord.ODD; };
					switch (hexLayout.orientation) {
						case POINTY: bh.base.Hex.OffsetCoord.qoffsetToCube(parityVal, new bh.base.Hex.OffsetCoord(Std.int(c), Std.int(r2)));
						case FLAT: bh.base.Hex.OffsetCoord.roffsetToCube(parityVal, new bh.base.Hex.OffsetCoord(Std.int(c), Std.int(r2)));
					};
				} else null;
			case SELECTED_HEX_DOUBLED(col2, row2):
				final c = resolveRVStatic(col2);
				final r2 = resolveRVStatic(row2);
				if (c != null && r2 != null) {
					switch (hexLayout.orientation) {
						case POINTY: bh.base.Hex.DoubledCoord.qdoubledToCube(new bh.base.Hex.DoubledCoord(Std.int(c), Std.int(r2)));
						case FLAT: bh.base.Hex.DoubledCoord.rdoubledToCube(new bh.base.Hex.DoubledCoord(Std.int(c), Std.int(r2)));
					};
				} else null;
			case SELECTED_HEX_PIXEL(_, _):
				// pixelToHex can't be statically resolved at macro time
				null;
			default: null;
		};
	}

	/** Generate a runtime macro expression that evaluates to bh.base.Hex at runtime.
	 *  Mirrors resolveCoordToStaticHex() but produces expressions instead of values.
	 *  Parity and orientation are known at macro time and baked into generated code. */
	static function resolveCoordToRuntimeHexExpr(cell:Coordinates, hexLayout:bh.base.Hex.HexLayout):Null<Expr> {
		return switch (cell) {
			case SELECTED_HEX_CUBE(q, r, s):
				final qExpr = rvToExpr(q);
				final rExpr = rvToExpr(r);
				final sExpr = rvToExpr(s);
				macro new bh.base.Hex.FractionalHex($qExpr, $rExpr, $sExpr).round();
			case SELECTED_HEX_OFFSET(col, row, parity):
				final colExpr = rvToExpr(col);
				final rowExpr = rvToExpr(row);
				final parityExpr = switch (parity) {
					case EVEN: macro bh.base.Hex.OffsetCoord.EVEN;
					case ODD: macro bh.base.Hex.OffsetCoord.ODD;
				};
				switch (hexLayout.orientation) {
					case POINTY: macro bh.base.Hex.OffsetCoord.qoffsetToCube($parityExpr, new bh.base.Hex.OffsetCoord($colExpr, $rowExpr));
					case FLAT: macro bh.base.Hex.OffsetCoord.roffsetToCube($parityExpr, new bh.base.Hex.OffsetCoord($colExpr, $rowExpr));
				};
			case SELECTED_HEX_DOUBLED(col2, row2):
				final colExpr = rvToExpr(col2);
				final rowExpr = rvToExpr(row2);
				switch (hexLayout.orientation) {
					case POINTY: macro bh.base.Hex.DoubledCoord.qdoubledToCube(new bh.base.Hex.DoubledCoord($colExpr, $rowExpr));
					case FLAT: macro bh.base.Hex.DoubledCoord.rdoubledToCube(new bh.base.Hex.DoubledCoord($colExpr, $rowExpr));
				};
			case SELECTED_HEX_PIXEL(px, py):
				final xExpr = rvToExpr(px);
				final yExpr = rvToExpr(py);
				final _hlRef = hexFieldRef(null, hexLayout);
				macro $_hlRef.pixelToHex(new bh.base.FPoint($xExpr, $yExpr)).round();
			default: null;
		};
	}

	/** Resolve an RVMethodCall($ref.method(args)) to a static {x, y} point at macro time.
	 *  Returns null if any argument can't be statically resolved. */
	static function resolveMethodCallToStaticPoint(ref:String, method:String, args:Array<ReferenceableValue>):Null<{x:Float, y:Float}> {
		final hexLayout = getHexLayoutForNode(currentProcessingNode);
		final grid = getGridFromCurrentNode();

		// Grid methods
		if (ref == "grid" || ref == "ctx.grid") {
			if (grid == null) return null;
			switch (method) {
				case "pos":
					if (args.length < 2) return null;
					final gx = resolveRVStatic(args[0]);
					final gy = resolveRVStatic(args[1]);
					if (gx == null || gy == null) return null;
					var ox:Float = 0; var oy:Float = 0;
					if (args.length >= 4) {
						final oxv = resolveRVStatic(args[2]);
						final oyv = resolveRVStatic(args[3]);
						if (oxv == null || oyv == null) return null;
						ox = oxv; oy = oyv;
					}
					return {x: gx * grid.spacingX + ox, y: gy * grid.spacingY + oy};
				default: return null;
			}
		}

		// Named grid systems
		if (currentProcessingNode != null) {
			final namedCS = getNamedCoordSystem(ref, currentProcessingNode);
			if (namedCS != null) {
				switch (namedCS) {
					case NamedGrid(system):
						switch (method) {
							case "pos":
								if (args.length < 2) return null;
								final gx = resolveRVStatic(args[0]);
								final gy = resolveRVStatic(args[1]);
								if (gx == null || gy == null) return null;
								var ox:Float = 0; var oy:Float = 0;
								if (args.length >= 4) {
									final oxv = resolveRVStatic(args[2]);
									final oyv = resolveRVStatic(args[3]);
									if (oxv == null || oyv == null) return null;
									ox = oxv; oy = oyv;
								}
								return {x: gx * system.spacingX + ox, y: gy * system.spacingY + oy};
							default: return null;
						}
					case NamedHex(system):
						return resolveHexMethodToStaticPoint(system.hexLayout, method, args);
				}
			}
		}

		// Hex methods
		if (hexLayout == null) return null;
		return resolveHexMethodToStaticPoint(hexLayout, method, args);
	}

	static function resolveHexMethodToStaticPoint(hexLayout:bh.base.Hex.HexLayout, method:String, args:Array<ReferenceableValue>):Null<{x:Float, y:Float}> {
		switch (method) {
			case "corner":
				if (args.length < 1) return null;
				final idx = resolveRVStatic(args[0]);
				final factor = if (args.length >= 2) resolveRVStatic(args[1]) else 1.0;
				if (idx == null || factor == null) return null;
				final pt = hexLayout.polygonCorner(bh.base.Hex.zero(), Std.int(idx), factor);
				return {x: pt.x, y: pt.y};
			case "edge":
				if (args.length < 1) return null;
				final dir = resolveRVStatic(args[0]);
				final factor = if (args.length >= 2) resolveRVStatic(args[1]) else 1.0;
				if (dir == null || factor == null) return null;
				final pt = hexLayout.polygonEdge(bh.base.Hex.zero(), Std.int(dir), factor);
				return {x: pt.x, y: pt.y};
			case "cube":
				if (args.length != 3) return null;
				final qv = resolveRVStatic(args[0]);
				final rv2 = resolveRVStatic(args[1]);
				final sv = resolveRVStatic(args[2]);
				if (qv == null || rv2 == null || sv == null) return null;
				final hex = new bh.base.Hex.FractionalHex(qv, rv2, sv).round();
				final pt = hexLayout.hexToPixel(hex);
				return {x: pt.x, y: pt.y};
			case "offset":
				if (args.length < 2) return null;
				final c = resolveRVStatic(args[0]);
				final r2 = resolveRVStatic(args[1]);
				if (c == null || r2 == null) return null;
				final parityVal = if (args.length >= 3) {
					switch (args[2]) {
						case RVString(s) if (s == "odd"): bh.base.Hex.OffsetCoord.ODD;
						default: bh.base.Hex.OffsetCoord.EVEN;
					};
				} else bh.base.Hex.OffsetCoord.EVEN;
				final hex = switch (hexLayout.orientation) {
					case POINTY: bh.base.Hex.OffsetCoord.qoffsetToCube(parityVal, new bh.base.Hex.OffsetCoord(Std.int(c), Std.int(r2)));
					case FLAT: bh.base.Hex.OffsetCoord.roffsetToCube(parityVal, new bh.base.Hex.OffsetCoord(Std.int(c), Std.int(r2)));
				};
				final pt = hexLayout.hexToPixel(hex);
				return {x: pt.x, y: pt.y};
			case "doubled":
				if (args.length != 2) return null;
				final c = resolveRVStatic(args[0]);
				final r2 = resolveRVStatic(args[1]);
				if (c == null || r2 == null) return null;
				final hex = switch (hexLayout.orientation) {
					case POINTY: bh.base.Hex.DoubledCoord.qdoubledToCube(new bh.base.Hex.DoubledCoord(Std.int(c), Std.int(r2)));
					case FLAT: bh.base.Hex.DoubledCoord.rdoubledToCube(new bh.base.Hex.DoubledCoord(Std.int(c), Std.int(r2)));
				};
				final pt = hexLayout.hexToPixel(hex);
				return {x: pt.x, y: pt.y};
			case "pixel":
				// pixelToHex not available at macro time
				return null;
			default: return null;
		}
	}

	/** Generate a runtime expression for extracting .x or .y from a coordinate method call */
	static function resolveMethodCallToRuntimeComponentExpr(ref:String, method:String, args:Array<ReferenceableValue>, component:String):Expr {
		final argExprs = args.map(a -> rvToExpr(a));

		// Grid methods — check named systems too
		var gridSystem:Null<GridCoordinateSystem> = null;
		if (ref == "grid" || ref == "ctx.grid") {
			gridSystem = getGridFromCurrentNode();
		} else if (currentProcessingNode != null) {
			final namedCS = getNamedCoordSystem(ref, currentProcessingNode);
			if (namedCS != null) {
				switch (namedCS) {
					case NamedGrid(system): gridSystem = system;
					case NamedHex(_): // fall through to hex handling below
				}
			}
		}
		if (gridSystem != null) {
			switch (method) {
				case "pos":
					final sx:Int = gridSystem.spacingX;
					final sy:Int = gridSystem.spacingY;
					final gxExpr = argExprs[0];
					final gyExpr = argExprs[1];
					if (component == "x") {
						if (argExprs.length >= 4) { final oxExpr = argExprs[2]; return macro $gxExpr * $v{sx} + $oxExpr; }
						return macro $gxExpr * $v{sx};
					} else {
						if (argExprs.length >= 4) { final oyExpr = argExprs[3]; return macro $gyExpr * $v{sy} + $oyExpr; }
						return macro $gyExpr * $v{sy};
					}
				default:
					Context.error('Runtime .$component extraction not supported for grid method .$method()', Context.currentPos());
					return macro 0;
			}
		}

		// $ref.extraPoint("name" [, fallbackX, fallbackY]).x / .y — runtime resolution via named element
		if (method == "extraPoint") {
			final elementFields = namedElements.get(ref);
			if (elementFields == null || elementFields.length == 0) {
				Context.error('ProgrammableCodeGen: extraPoint reference: element "$ref" not found in named elements', Context.currentPos());
				return macro 0;
			}
			final elemRef = macro $p{["this", elementFields[0]]};
			final pointNameExpr = argExprs[0];
			final hasFallback = argExprs.length >= 3;
			final fbExpr = if (hasFallback) (component == "x" ? argExprs[1] : argExprs[2]) else null;
			if (hasFallback) {
				if (component == "x")
					return macro { final _ep = (cast $elemRef : bh.stateanim.AnimationSM).getExtraPoint($pointNameExpr); if (_ep != null) (_ep.x : Float) else $fbExpr; };
				else
					return macro { final _ep = (cast $elemRef : bh.stateanim.AnimationSM).getExtraPoint($pointNameExpr); if (_ep != null) (_ep.y : Float) else $fbExpr; };
			} else {
				if (component == "x")
					return macro { final _ep = (cast $elemRef : bh.stateanim.AnimationSM).getExtraPoint($pointNameExpr); if (_ep == null) throw "extraPoint not found"; (_ep.x : Float); };
				else
					return macro { final _ep = (cast $elemRef : bh.stateanim.AnimationSM).getExtraPoint($pointNameExpr); if (_ep == null) throw "extraPoint not found"; (_ep.y : Float); };
			}
		}

		// Hex methods — need _hexLayout field
		if (hexLayoutFieldCount == 0) {
			Context.error('Runtime hex .$component extraction requires hex coordinate system with runtime parameters in scope', Context.currentPos());
			return macro 0;
		}

		final _hlRef = hexFieldRef(currentProcessingNode);
		switch (method) {
			case "corner":
				if (argExprs.length < 1) Context.error('corner() requires at least 1 argument', Context.currentPos());
				final idxExpr = argExprs[0];
				final factorExpr = if (argExprs.length >= 2) argExprs[1] else macro 1.0;
				if (component == "x")
					return macro $_hlRef.polygonCorner(bh.base.Hex.zero(), $idxExpr, $factorExpr).x;
				else
					return macro $_hlRef.polygonCorner(bh.base.Hex.zero(), $idxExpr, $factorExpr).y;
			case "edge":
				if (argExprs.length < 1) Context.error('edge() requires at least 1 argument', Context.currentPos());
				final dirExpr = argExprs[0];
				final factorExpr = if (argExprs.length >= 2) argExprs[1] else macro 1.0;
				if (component == "x")
					return macro $_hlRef.polygonEdge(bh.base.Hex.zero(), $dirExpr, $factorExpr).x;
				else
					return macro $_hlRef.polygonEdge(bh.base.Hex.zero(), $dirExpr, $factorExpr).y;
			case "cube":
				if (argExprs.length != 3) Context.error('cube() requires 3 arguments', Context.currentPos());
				final qExpr = argExprs[0];
				final rExpr = argExprs[1];
				final sExpr = argExprs[2];
				if (component == "x")
					return macro $_hlRef.hexToPixel(new bh.base.Hex.FractionalHex($qExpr, $rExpr, $sExpr).round()).x;
				else
					return macro $_hlRef.hexToPixel(new bh.base.Hex.FractionalHex($qExpr, $rExpr, $sExpr).round()).y;
			case "offset":
				if (argExprs.length < 2) Context.error('offset() requires at least 2 arguments', Context.currentPos());
				final colExpr = argExprs[0];
				final rowExpr = argExprs[1];
				final parityStr = if (args.length >= 3) switch (args[2]) { case RVString(s): s; default: "even"; } else "even";
				final parityExpr = if (parityStr == "odd") macro bh.base.Hex.OffsetCoord.ODD else macro bh.base.Hex.OffsetCoord.EVEN;
				final hexLayout = getHexLayoutForNode(currentProcessingNode);
				if (hexLayout != null) {
					final hexExpr = switch (hexLayout.orientation) {
						case POINTY: macro bh.base.Hex.OffsetCoord.qoffsetToCube($parityExpr, new bh.base.Hex.OffsetCoord($colExpr, $rowExpr));
						case FLAT: macro bh.base.Hex.OffsetCoord.roffsetToCube($parityExpr, new bh.base.Hex.OffsetCoord($colExpr, $rowExpr));
					};
					if (component == "x")
						return macro $_hlRef.hexToPixel($hexExpr).x;
					else
						return macro $_hlRef.hexToPixel($hexExpr).y;
				} else { Context.error('offset() requires hex coordinate system in scope', Context.currentPos()); return macro 0; }
			case "doubled":
				if (argExprs.length != 2) Context.error('doubled() requires 2 arguments', Context.currentPos());
				final colExpr = argExprs[0];
				final rowExpr = argExprs[1];
				final hexLayout = getHexLayoutForNode(currentProcessingNode);
				if (hexLayout != null) {
					final hexExpr = switch (hexLayout.orientation) {
						case POINTY: macro bh.base.Hex.DoubledCoord.qdoubledToCube(new bh.base.Hex.DoubledCoord($colExpr, $rowExpr));
						case FLAT: macro bh.base.Hex.DoubledCoord.rdoubledToCube(new bh.base.Hex.DoubledCoord($colExpr, $rowExpr));
					};
					if (component == "x")
						return macro $_hlRef.hexToPixel($hexExpr).x;
					else
						return macro $_hlRef.hexToPixel($hexExpr).y;
				} else { Context.error('doubled() requires hex coordinate system in scope', Context.currentPos()); return macro 0; }
			case "pixel":
				if (argExprs.length != 2) Context.error('pixel() requires 2 arguments', Context.currentPos());
				final xExpr = argExprs[0];
				final yExpr = argExprs[1];
				final ptExpr = macro $_hlRef.hexToPixel($_hlRef.pixelToHex(new bh.base.FPoint($xExpr, $yExpr)).round());
				if (component == "x")
					return macro $ptExpr.x;
				else
					return macro $ptExpr.y;
			default:
				Context.error('Runtime .${component} extraction not supported for method .$method()', Context.currentPos());
				return macro 0;
		}
	}

	/** Resolve a Coordinates value to expression pair {x:Expr, y:Expr}, supporting all coordinate types.
	 *  Falls back to rvToExpr for OFFSET when static resolution fails (param-dependent). */
	static function coordsToXYExprs(coords:Coordinates, pos:Position, ?node:MultiAnimParser.Node):{x:Expr, y:Expr} {
		if (coords == null) return {x: macro 0.0, y: macro 0.0};

		// First try static resolution (works for all coordinate types)
		final staticXY = coordsToStaticXY(coords, pos, node);
		if (staticXY != null) {
			return {x: macro $v{staticXY.x}, y: macro $v{staticXY.y}};
		}

		// Fall back to expression-based resolution for param-dependent coords
		final _hlRef = hexFieldRef(node != null ? node : currentProcessingNode);
		return switch (coords) {
			case OFFSET(xrv, yrv):
				{x: rvToExpr(xrv), y: rvToExpr(yrv)};
			case SELECTED_HEX_CUBE(q, r, s):
				final qExpr = rvToExpr(q);
				final rExpr = rvToExpr(r);
				final sExpr = rvToExpr(s);
				{
					x: macro $_hlRef.hexToPixel(new bh.base.Hex.FractionalHex($qExpr, $rExpr, $sExpr).round()).x,
					y: macro $_hlRef.hexToPixel(new bh.base.Hex.FractionalHex($qExpr, $rExpr, $sExpr).round()).y
				};
			case SELECTED_HEX_CORNER(count, factor):
				final cExpr = rvToExpr(count);
				final fExpr = rvToExpr(factor);
				{
					x: macro $_hlRef.polygonCorner(bh.base.Hex.zero(), $cExpr, $fExpr).x,
					y: macro $_hlRef.polygonCorner(bh.base.Hex.zero(), $cExpr, $fExpr).y
				};
			case SELECTED_HEX_EDGE(dir, factor):
				final dExpr = rvToExpr(dir);
				final fExpr = rvToExpr(factor);
				{
					x: macro $_hlRef.polygonEdge(bh.base.Hex.zero(), $dExpr, $fExpr).x,
					y: macro $_hlRef.polygonEdge(bh.base.Hex.zero(), $dExpr, $fExpr).y
				};
			case SELECTED_HEX_OFFSET(col, row, parity):
				final colExpr = rvToExpr(col);
				final rowExpr = rvToExpr(row);
				final parityExpr = switch (parity) { case EVEN: macro bh.base.Hex.OffsetCoord.EVEN; case ODD: macro bh.base.Hex.OffsetCoord.ODD; };
				final hexLayout = if (node != null) getHexLayoutForNode(node) else null;
				if (hexLayout != null) {
					final hexExpr = switch (hexLayout.orientation) {
						case POINTY: macro bh.base.Hex.OffsetCoord.qoffsetToCube($parityExpr, new bh.base.Hex.OffsetCoord($colExpr, $rowExpr));
						case FLAT: macro bh.base.Hex.OffsetCoord.roffsetToCube($parityExpr, new bh.base.Hex.OffsetCoord($colExpr, $rowExpr));
					};
					{ x: macro $_hlRef.hexToPixel($hexExpr).x, y: macro $_hlRef.hexToPixel($hexExpr).y };
				} else {
					Context.error('ProgrammableCodeGen: hex offset requires hex coordinate system', pos);
					{x: macro 0.0, y: macro 0.0};
				}
			case SELECTED_HEX_DOUBLED(col, row):
				final colExpr = rvToExpr(col);
				final rowExpr = rvToExpr(row);
				final hexLayout = if (node != null) getHexLayoutForNode(node) else null;
				if (hexLayout != null) {
					final hexExpr = switch (hexLayout.orientation) {
						case POINTY: macro bh.base.Hex.DoubledCoord.qdoubledToCube(new bh.base.Hex.DoubledCoord($colExpr, $rowExpr));
						case FLAT: macro bh.base.Hex.DoubledCoord.rdoubledToCube(new bh.base.Hex.DoubledCoord($colExpr, $rowExpr));
					};
					{ x: macro $_hlRef.hexToPixel($hexExpr).x, y: macro $_hlRef.hexToPixel($hexExpr).y };
				} else {
					Context.error('ProgrammableCodeGen: hex doubled requires hex coordinate system', pos);
					{x: macro 0.0, y: macro 0.0};
				}
			case SELECTED_HEX_PIXEL(px, py):
				final xExpr = rvToExpr(px);
				final yExpr = rvToExpr(py);
				{
					x: macro $_hlRef.hexToPixel($_hlRef.pixelToHex(new bh.base.FPoint($xExpr, $yExpr)).round()).x,
					y: macro $_hlRef.hexToPixel($_hlRef.pixelToHex(new bh.base.FPoint($xExpr, $yExpr)).round()).y
				};
			case ZERO:
				{x: macro 0.0, y: macro 0.0};
			case SELECTED_GRID_POSITION(gridX, gridY):
				final grid = getGridFromNode(node);
				if (grid != null) {
					final gxExpr = rvToExpr(gridX);
					final gyExpr = rvToExpr(gridY);
					final sx:Int = grid.spacingX;
					final sy:Int = grid.spacingY;
					{x: macro $gxExpr * $v{sx}, y: macro $gyExpr * $v{sy}};
				} else {
					Context.error('ProgrammableCodeGen: grid coordinate requires grid coordinate system', pos);
					{x: macro 0.0, y: macro 0.0};
				}
			case LAYOUT(layoutName, index):
				final idx = index != null ? resolveRVStatic(index) : 0.0;
				if (idx != null) {
					final pt = resolveLayoutPosition(layoutName, Std.int(idx));
					if (pt != null) {
						{x: macro $v{pt.x}, y: macro $v{pt.y}};
					} else {
						Context.error('ProgrammableCodeGen: layout "$layoutName" not found or index out of range', pos);
						{x: macro 0.0, y: macro 0.0};
					}
				} else {
					Context.error('ProgrammableCodeGen: param-dependent layout index not supported in pixels', pos);
					{x: macro 0.0, y: macro 0.0};
				}
			case NAMED_COORD(name, coord):
				final namedCS = if (node != null) getNamedCoordSystem(name, node) else null;
				if (namedCS != null) {
					switch (namedCS) {
						case NamedGrid(system):
							switch (coord) {
								case SELECTED_GRID_POSITION(gridX, gridY):
									final gxExpr = rvToExpr(gridX);
									final gyExpr = rvToExpr(gridY);
									final sx:Int = system.spacingX;
									final sy:Int = system.spacingY;
									{x: macro $gxExpr * $v{sx}, y: macro $gyExpr * $v{sy}};
								default:
									Context.error('ProgrammableCodeGen: unsupported coordinate type inside named grid', pos);
									{x: macro 0.0, y: macro 0.0};
							}
						case NamedHex(system):
							// Delegate to the hex handling by recursing with the inner coord
							coordsToXYExprs(coord, pos, node);
					}
				} else {
					Context.error('ProgrammableCodeGen: named coordinate system "$name" not found', pos);
					{x: macro 0.0, y: macro 0.0};
				}
			case WITH_OFFSET(base, offsetX, offsetY):
				final baseXY = coordsToXYExprs(base, pos, node);
				final oxExpr = rvToExpr(offsetX);
				final oyExpr = rvToExpr(offsetY);
				final bx = baseXY.x;
				final by = baseXY.y;
				{x: macro $bx + $oxExpr, y: macro $by + $oyExpr};
			case SELECTED_HEX_CELL_CORNER(cell, cornerIndex, factor):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final ciExpr = rvToExpr(cornerIndex);
					final fExpr = rvToExpr(factor);
					final cellHex = resolveCoordToStaticHex(cell, hexLayout);
					if (cellHex != null) {
						{
							x: macro $_hlRef.polygonCorner(new bh.base.Hex($v{cellHex.q}, $v{cellHex.r}, $v{cellHex.s}), $ciExpr, $fExpr).x,
							y: macro $_hlRef.polygonCorner(new bh.base.Hex($v{cellHex.q}, $v{cellHex.r}, $v{cellHex.s}), $ciExpr, $fExpr).y
						};
					} else {
						final cellExpr = resolveCoordToRuntimeHexExpr(cell, hexLayout);
						if (cellExpr != null) {
							{
								x: macro { final _cellHex = $cellExpr; $_hlRef.polygonCorner(_cellHex, $ciExpr, $fExpr).x; },
								y: macro { final _cellHex = $cellExpr; $_hlRef.polygonCorner(_cellHex, $ciExpr, $fExpr).y; }
							};
						} else {
							Context.error('ProgrammableCodeGen: cannot resolve cell coordinate for hex cell corner', pos);
							{x: macro 0.0, y: macro 0.0};
						}
					}
				} else {
					Context.error('ProgrammableCodeGen: hex cell corner requires hex coordinate system', pos);
					{x: macro 0.0, y: macro 0.0};
				}
			case SELECTED_HEX_CELL_EDGE(cell, direction, factor):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final dExpr = rvToExpr(direction);
					final fExpr = rvToExpr(factor);
					final cellHex = resolveCoordToStaticHex(cell, hexLayout);
					if (cellHex != null) {
						{
							x: macro $_hlRef.polygonEdge(new bh.base.Hex($v{cellHex.q}, $v{cellHex.r}, $v{cellHex.s}), $dExpr, $fExpr).x,
							y: macro $_hlRef.polygonEdge(new bh.base.Hex($v{cellHex.q}, $v{cellHex.r}, $v{cellHex.s}), $dExpr, $fExpr).y
						};
					} else {
						final cellExpr = resolveCoordToRuntimeHexExpr(cell, hexLayout);
						if (cellExpr != null) {
							{
								x: macro { final _cellHex = $cellExpr; $_hlRef.polygonEdge(_cellHex, $dExpr, $fExpr).x; },
								y: macro { final _cellHex = $cellExpr; $_hlRef.polygonEdge(_cellHex, $dExpr, $fExpr).y; }
							};
						} else {
							Context.error('ProgrammableCodeGen: cannot resolve cell coordinate for hex cell edge', pos);
							{x: macro 0.0, y: macro 0.0};
						}
					}
				} else {
					Context.error('ProgrammableCodeGen: hex cell edge requires hex coordinate system', pos);
					{x: macro 0.0, y: macro 0.0};
				}
			case EXTRA_POINT_REF(elementName, pointName, fallback):
				final elementFields = namedElements.get(elementName);
				if (elementFields == null || elementFields.length == 0) {
					Context.error('ProgrammableCodeGen: extraPoint reference: element "$elementName" not found in named elements', pos);
					{x: macro 0.0, y: macro 0.0};
				} else {
					final elemRef = macro $p{["this", elementFields[0]]};
					final fallbackXY = fallback != null ? coordsToXYExprs(fallback, pos, node) : null;
					final fbX = fallbackXY != null ? fallbackXY.x : null;
					final fbY = fallbackXY != null ? fallbackXY.y : null;
					{
						x: if (fbX != null)
							macro { final _ep = (cast $elemRef : bh.stateanim.AnimationSM).getExtraPoint($v{pointName}); if (_ep != null) (_ep.x : Float) else $fbX; }
						else
							macro { final _ep = (cast $elemRef : bh.stateanim.AnimationSM).getExtraPoint($v{pointName}); if (_ep == null) throw $v{'extraPoint: point "$pointName" not found'}; (_ep.x : Float); },
						y: if (fbY != null)
							macro { final _ep = (cast $elemRef : bh.stateanim.AnimationSM).getExtraPoint($v{pointName}); if (_ep != null) (_ep.y : Float) else $fbY; }
						else
							macro { final _ep = (cast $elemRef : bh.stateanim.AnimationSM).getExtraPoint($v{pointName}); if (_ep == null) throw $v{'extraPoint: point "$pointName" not found'}; (_ep.y : Float); }
					};
				}
			case EXTRA_POINT_ANIM(filename, animName, pointName, selectorRefs, fallback):
				final fallbackXY = fallback != null ? coordsToXYExprs(fallback, pos, node) : null;
				final fbX = fallbackXY != null ? fallbackXY.x : null;
				final fbY = fallbackXY != null ? fallbackXY.y : null;
				// Build selector map expressions
				final selExprs:Array<Expr> = [macro final _selMap = new Map<String, String>()];
				for (k => v in selectorRefs) {
					final keyExpr:Expr = macro $v{k};
					final valExpr = rvToExpr(v);
					selExprs.push(macro _selMap.set($keyExpr, Std.string($valExpr)));
				}
				selExprs.push(macro final _animSM = this._pb.resourceLoader.createAnimSM($v{filename}, _selMap));
				selExprs.push(macro _animSM.play($v{animName}));
				{
					x: {
						final block = selExprs.copy();
						if (fbX != null)
							block.push(macro { final _ep = _animSM.getExtraPoint($v{pointName}); if (_ep != null) (_ep.x : Float) else $fbX; })
						else
							block.push(macro { final _ep = _animSM.getExtraPoint($v{pointName}); if (_ep == null) throw $v{'extraPoint: point "$pointName" not found'}; (_ep.x : Float); });
						macro $b{block};
					},
					y: {
						final block = selExprs.copy();
						if (fbY != null)
							block.push(macro { final _ep = _animSM.getExtraPoint($v{pointName}); if (_ep != null) (_ep.y : Float) else $fbY; })
						else
							block.push(macro { final _ep = _animSM.getExtraPoint($v{pointName}); if (_ep == null) throw $v{'extraPoint: point "$pointName" not found'}; (_ep.y : Float); });
						macro $b{block};
					}
				};
		};
	}

	static function generatePixelsCreate(node:Node, fieldName:String, shapes:Array<PixelShapes>, pos:Position):CreateResult {
		final fieldRef = macro $p{["this", fieldName]};
		final createExprs:Array<Expr> = [];

		// Try to resolve all shapes at compile time for bounds calculation
		var allStatic = true;
		var staticShapes:Array<{type:String, x1:Float, y1:Float, x2:Float, y2:Float, w:Float, h:Float, color:Null<Int>, filled:Bool}> = [];

		for (s in shapes) {
			switch (s) {
				case LINE(line):
					final startXY = coordsToStaticXY(line.start, pos, node);
					final endXY = coordsToStaticXY(line.end, pos, node);
					final c = resolveRVStatic(line.color);
					if (startXY != null && endXY != null && c != null) {
						staticShapes.push({type: "line", x1: startXY.x, y1: startXY.y, x2: endXY.x, y2: endXY.y, w: 0, h: 0, color: Std.int(c), filled: false});
					} else allStatic = false;
				case RECT(rect) | FILLED_RECT(rect):
					final startXY = coordsToStaticXY(rect.start, pos, node);
					final w = resolveRVStatic(rect.width);
					final h = resolveRVStatic(rect.height);
					final c = resolveRVStatic(rect.color);
					final filled = switch (s) { case FILLED_RECT(_): true; default: false; };
					if (startXY != null && w != null && h != null && c != null) {
						staticShapes.push({type: "rect", x1: startXY.x, y1: startXY.y, x2: 0, y2: 0, w: w, h: h, color: Std.int(c), filled: filled});
					} else allStatic = false;
				case PIXEL(pixel):
					final xy = coordsToStaticXY(pixel.pos, pos, node);
					final c = resolveRVStatic(pixel.color);
					if (xy != null && c != null) {
						staticShapes.push({type: "pixel", x1: xy.x, y1: xy.y, x2: 0, y2: 0, w: 0, h: 0, color: Std.int(c), filled: false});
					} else allStatic = false;
			}
		}

		if (allStatic && staticShapes.length > 0) {
			// Fully static: compute bounds and generate direct draw calls
			var minX:Int = 0x7FFFFFFF;
			var minY:Int = 0x7FFFFFFF;
			var maxX:Int = -0x80000000;
			var maxY:Int = -0x80000000;
			for (s in staticShapes) {
				switch (s.type) {
					case "line":
						final ix1 = Math.round(s.x1);
						final iy1 = Math.round(s.y1);
						final ix2 = Math.round(s.x2);
						final iy2 = Math.round(s.y2);
						if (ix1 < minX) minX = ix1; if (iy1 < minY) minY = iy1;
						if (ix2 < minX) minX = ix2; if (iy2 < minY) minY = iy2;
						if (ix1 > maxX) maxX = ix1; if (iy1 > maxY) maxY = iy1;
						if (ix2 > maxX) maxX = ix2; if (iy2 > maxY) maxY = iy2;
					case "rect":
						final ix = Math.round(s.x1);
						final iy = Math.round(s.y1);
						final iw = Math.round(s.w);
						final ih = Math.round(s.h);
						if (ix < minX) minX = ix; if (iy < minY) minY = iy;
						if (ix + iw + 1 > maxX) maxX = ix + iw + 1;
						if (iy + ih + 1 > maxY) maxY = iy + ih + 1;
					case "pixel":
						final ix = Math.round(s.x1);
						final iy = Math.round(s.y1);
						if (ix < minX) minX = ix; if (iy < minY) minY = iy;
						if (ix > maxX) maxX = ix; if (iy > maxY) maxY = iy;
					default:
				}
			}
			final width:Int = maxX - minX + 1;
			final height:Int = maxY - minY + 1;

			createExprs.push(macro {
				final _pl = new bh.base.PixelLine.PixelLines($v{width}, $v{height});
				$fieldRef = _pl;
			});

			for (s in staticShapes) {
				switch (s.type) {
					case "line":
						final ix1:Int = Math.round(s.x1) - minX;
						final iy1:Int = Math.round(s.y1) - minY;
						final ix2:Int = Math.round(s.x2) - minX;
						final iy2:Int = Math.round(s.y2) - minY;
						var c:Int = s.color;
						if (c >>> 24 == 0) c |= 0xFF000000;
						createExprs.push(macro {
							final _pl:bh.base.PixelLine.PixelLines = cast $fieldRef;
							_pl.line($v{ix1}, $v{iy1}, $v{ix2}, $v{iy2}, $v{c});
						});
					case "rect":
						final ix:Int = Math.round(s.x1) - minX;
						final iy:Int = Math.round(s.y1) - minY;
						final iw:Int = Math.round(s.w);
						final ih:Int = Math.round(s.h);
						var c:Int = s.color;
						if (c >>> 24 == 0) c |= 0xFF000000;
						if (s.filled) {
							createExprs.push(macro {
								final _pl:bh.base.PixelLine.PixelLines = cast $fieldRef;
								_pl.filledRect($v{ix}, $v{iy}, $v{iw}, $v{ih}, $v{c});
							});
						} else {
							createExprs.push(macro {
								final _pl:bh.base.PixelLine.PixelLines = cast $fieldRef;
								_pl.rect($v{ix}, $v{iy}, $v{iw}, $v{ih}, $v{c});
							});
						}
					case "pixel":
						final ix:Int = Math.round(s.x1) - minX;
						final iy:Int = Math.round(s.y1) - minY;
						var c:Int = s.color;
						if (c >>> 24 == 0) c |= 0xFF000000;
						createExprs.push(macro {
							final _pl:bh.base.PixelLine.PixelLines = cast $fieldRef;
							_pl.pixel($v{ix}, $v{iy}, $v{c});
						});
					default:
				}
			}

			createExprs.push(macro {
				final _pl:bh.base.PixelLine.PixelLines = cast $fieldRef;
				_pl.updateBitmap();
				_pl.setPosition($v{minX}, $v{minY});
			});
		} else {
			// Param-dependent: generate runtime bounds calculation + draw
			final boundsExprs:Array<Expr> = [
				macro var _minX:Int = 0x7FFFFFFF
			];
			boundsExprs.push(macro var _minY:Int = 0x7FFFFFFF);
			boundsExprs.push(macro var _maxX:Int = -0x80000000);
			boundsExprs.push(macro var _maxY:Int = -0x80000000);

			// Track shapes for second pass
			var shapeIdx = 0;
			final shapeVarExprs:Array<Expr> = [];
			for (s in shapes) {
				final idx = shapeIdx++;
				switch (s) {
					case LINE(line):
						final start = coordsToXYExprs(line.start, pos, node);
						final end = coordsToXYExprs(line.end, pos, node);
						final cExpr = rvToExpr(line.color);
						final x1Var = "_sx" + idx;
						final y1Var = "_sy" + idx;
						final x2Var = "_ex" + idx;
						final y2Var = "_ey" + idx;
						final cVar = "_c" + idx;
						boundsExprs.push(macro var $x1Var:Int = Math.round(${start.x}));
						boundsExprs.push(macro var $y1Var:Int = Math.round(${start.y}));
						boundsExprs.push(macro var $x2Var:Int = Math.round(${end.x}));
						boundsExprs.push(macro var $y2Var:Int = Math.round(${end.y}));
						boundsExprs.push(macro var $cVar:Int = { var c:Int = $cExpr; if (c >>> 24 == 0) c |= 0xFF000000; c; });
						boundsExprs.push(macro if ($i{x1Var} < _minX) _minX = $i{x1Var});
						boundsExprs.push(macro if ($i{y1Var} < _minY) _minY = $i{y1Var});
						boundsExprs.push(macro if ($i{x2Var} < _minX) _minX = $i{x2Var});
						boundsExprs.push(macro if ($i{y2Var} < _minY) _minY = $i{y2Var});
						boundsExprs.push(macro if ($i{x1Var} > _maxX) _maxX = $i{x1Var});
						boundsExprs.push(macro if ($i{y1Var} > _maxY) _maxY = $i{y1Var});
						boundsExprs.push(macro if ($i{x2Var} > _maxX) _maxX = $i{x2Var});
						boundsExprs.push(macro if ($i{y2Var} > _maxY) _maxY = $i{y2Var});
						shapeVarExprs.push(macro _pl.line($i{x1Var} - _minX, $i{y1Var} - _minY, $i{x2Var} - _minX, $i{y2Var} - _minY, $i{cVar}));
					case RECT(rect) | FILLED_RECT(rect):
						final start = coordsToXYExprs(rect.start, pos, node);
						final wExpr = rvToExpr(rect.width);
						final hExpr = rvToExpr(rect.height);
						final cExpr = rvToExpr(rect.color);
						final filled = switch (s) { case FILLED_RECT(_): true; default: false; };
						final xVar = "_rx" + idx;
						final yVar = "_ry" + idx;
						final wVar = "_rw" + idx;
						final hVar = "_rh" + idx;
						final cVar = "_c" + idx;
						boundsExprs.push(macro var $xVar:Int = Math.round(${start.x}));
						boundsExprs.push(macro var $yVar:Int = Math.round(${start.y}));
						boundsExprs.push(macro var $wVar:Int = $wExpr);
						boundsExprs.push(macro var $hVar:Int = $hExpr);
						boundsExprs.push(macro var $cVar:Int = { var c:Int = $cExpr; if (c >>> 24 == 0) c |= 0xFF000000; c; });
						boundsExprs.push(macro if ($i{xVar} < _minX) _minX = $i{xVar});
						boundsExprs.push(macro if ($i{yVar} < _minY) _minY = $i{yVar});
						boundsExprs.push(macro if ($i{xVar} + $i{wVar} + 1 > _maxX) _maxX = $i{xVar} + $i{wVar} + 1);
						boundsExprs.push(macro if ($i{yVar} + $i{hVar} + 1 > _maxY) _maxY = $i{yVar} + $i{hVar} + 1);
						if (filled)
							shapeVarExprs.push(macro _pl.filledRect($i{xVar} - _minX, $i{yVar} - _minY, $i{wVar}, $i{hVar}, $i{cVar}));
						else
							shapeVarExprs.push(macro _pl.rect($i{xVar} - _minX, $i{yVar} - _minY, $i{wVar}, $i{hVar}, $i{cVar}));
					case PIXEL(pixel):
						final xy = coordsToXYExprs(pixel.pos, pos, node);
						final cExpr = rvToExpr(pixel.color);
						final xVar = "_px" + idx;
						final yVar = "_py" + idx;
						final cVar = "_c" + idx;
						boundsExprs.push(macro var $xVar:Int = Math.round(${xy.x}));
						boundsExprs.push(macro var $yVar:Int = Math.round(${xy.y}));
						boundsExprs.push(macro var $cVar:Int = { var c:Int = $cExpr; if (c >>> 24 == 0) c |= 0xFF000000; c; });
						boundsExprs.push(macro if ($i{xVar} < _minX) _minX = $i{xVar});
						boundsExprs.push(macro if ($i{yVar} < _minY) _minY = $i{yVar});
						boundsExprs.push(macro if ($i{xVar} > _maxX) _maxX = $i{xVar});
						boundsExprs.push(macro if ($i{yVar} > _maxY) _maxY = $i{yVar});
						shapeVarExprs.push(macro _pl.pixel($i{xVar} - _minX, $i{yVar} - _minY, $i{cVar}));
				}
			}

			// Create PixelLines and draw
			final drawExprs:Array<Expr> = [
				macro var _pl = new bh.base.PixelLine.PixelLines(_maxX - _minX + 1, _maxY - _minY + 1)
			];
			for (e in shapeVarExprs)
				drawExprs.push(e);
			drawExprs.push(macro _pl.updateBitmap());
			drawExprs.push(macro $fieldRef = _pl);
			drawExprs.push(macro _pl.setPosition(_minX, _minY));

			final allExprs = boundsExprs.concat(drawExprs);
			createExprs.push(macro $b{allExprs});
		}

		return {
			fieldType: macro :bh.base.PixelLine.PixelLines,
			createExprs: createExprs,
			isContainer: false,
			exprUpdates: [],
		};
	}

	// ==================== Particles ====================

	static function generateParticlesCreate(node:Node, fieldName:String, particlesDef:ParticlesDef, pos:Position):CreateResult {
		final fieldRef = macro $p{["this", fieldName]};
		final nameExpr:Expr = macro $v{currentProgrammableName};
		final indexExpr:Expr = macro $v{particlesCounter++};
		final createExprs:Array<Expr> = [
			macro $fieldRef = this._pb.buildParticles($nameExpr, $indexExpr),
		];

		return {
			fieldType: macro :bh.base.Particles,
			createExprs: createExprs,
			isContainer: false,
			exprUpdates: [],
		};
	}

	// ==================== State Anim ====================

	static function generateStateAnimCreate(node:Node, fieldName:String, filename:String, initialState:ReferenceableValue,
			selectorReferences:Map<String, ReferenceableValue>, pos:Position):CreateResult {
		final fieldRef = macro $p{["this", fieldName]};
		final filenameExpr:Expr = macro $v{filename};
		final initialStateExpr = rvToExpr(initialState);

		// Build selector map: new Map(), then .set() for each entry
		final mapBuildExprs:Array<Expr> = [macro final _selMap = new Map<String, String>()];
		for (k => v in selectorReferences) {
			final keyExpr:Expr = macro $v{k};
			final valExpr = rvToExpr(v);
			mapBuildExprs.push(macro _selMap.set($keyExpr, Std.string($valExpr)));
		}
		mapBuildExprs.push(macro $fieldRef = this._pb.buildStateAnim($filenameExpr, _selMap, Std.string($initialStateExpr)));

		return {
			fieldType: macro :h2d.Object,
			createExprs: [macro $b{mapBuildExprs}],
			isContainer: false,
			exprUpdates: [],
		};
	}

	// ==================== State Anim Construct ====================

	static function generateStateAnimConstructCreate(node:Node, fieldName:String, initialState:ReferenceableValue,
			construct:Map<String, StateAnimConstruct>, externallyDriven:Bool, pos:Position):CreateResult {
		final fieldRef = macro $p{["this", fieldName]};
		final initialStateExpr = rvToExpr(initialState);

		// Build construct data array expression
		final constructExprs:Array<Expr> = [];
		for (key => value in construct) {
			switch value {
				case IndexedSheet(sheet, animName, fps, loop, center):
					final keyExpr:Expr = macro $v{key};
					final sheetExpr:Expr = macro $v{sheet};
					final animNameExpr = rvToExpr(animName);
					final fpsExpr = rvToExpr(fps);
					final loopExpr:Expr = macro $v{loop};
					final centerExpr:Expr = macro $v{center};
					constructExprs.push(macro {
						key: $keyExpr,
						sheet: $sheetExpr,
						animName: Std.string($animNameExpr),
						fps: $fpsExpr,
						loop: $loopExpr,
						center: $centerExpr,
					});
			}
		}

		final constructArrayExpr:Expr = macro $a{constructExprs};
		final externallyDrivenExpr:Expr = macro $v{externallyDriven};
		final createExprs:Array<Expr> = [
			macro $fieldRef = this._pb.buildStateAnimConstruct(Std.string($initialStateExpr), $constructArrayExpr, $externallyDrivenExpr),
		];

		return {
			fieldType: macro :h2d.Object,
			createExprs: createExprs,
			isContainer: false,
			exprUpdates: [],
		};
	}

	// ==================== TileGroup ====================

	static function generateTileGroupCreate(node:Node, fieldName:String, pos:Position):CreateResult {
		final fieldRef = macro $p{["this", fieldName]};
		final nameExpr:Expr = macro $v{currentProgrammableName};
		final indexExpr:Expr = macro $v{tileGroupCounter++};
		final createExprs:Array<Expr> = [
			macro $fieldRef = this._pb.buildTileGroupFromProgrammable($nameExpr, $indexExpr),
		];

		return {
			fieldType: macro :h2d.Object,
			createExprs: createExprs,
			isContainer: false,
			exprUpdates: [],
		};
	}

	// ==================== Apply ====================

	/** APPLY modifies the parent node's properties (position, scale, alpha, blendMode, tint, filter).
	 *  It doesn't create a new element. */
	static function processApply(node:Node, parentField:String, fields:Array<Field>, ctorExprs:Array<Expr>, pos:Position):Void {
		final parentRef = parentField != null ? (macro $p{["this", parentField]}) : (macro this);

		// Position offset
		ensureHexLayoutIfNeeded(node.pos, node, fields, ctorExprs, pos);
		final posExpr = generatePositionExpr(node.pos, parentField, pos, node);
		if (posExpr != null)
			ctorExprs.push(posExpr);

		// Scale
		if (node.scale != null) {
			final scaleExpr = rvToExpr(node.scale);
			ctorExprs.push(macro {
				final s = $scaleExpr;
				$parentRef.scaleX = s;
				$parentRef.scaleY = s;
			});
		}

		// Rotation
		if (node.rotation != null) {
			final rotExpr = rvToExpr(node.rotation);
			ctorExprs.push(macro $parentRef.rotation = hxd.Math.degToRad($rotExpr));
		}

		// Alpha
		if (node.alpha != null) {
			final alphaExpr = rvToExpr(node.alpha);
			ctorExprs.push(macro $parentRef.alpha = $alphaExpr);
		}

		// BlendMode
		if (node.blendMode != null) {
			final bmExpr:Expr = switch (node.blendMode) {
				case MBNone: macro h2d.BlendMode.None;
				case MBAlpha: macro h2d.BlendMode.Alpha;
				case MBAdd: macro h2d.BlendMode.Add;
				case MBAlphaAdd: macro h2d.BlendMode.AlphaAdd;
				case MBSoftAdd: macro h2d.BlendMode.SoftAdd;
				case MBMultiply: macro h2d.BlendMode.Multiply;
				case MBAlphaMultiply: macro h2d.BlendMode.AlphaMultiply;
				case MBErase: macro h2d.BlendMode.Erase;
				case MBScreen: macro h2d.BlendMode.Screen;
				case MBSub: macro h2d.BlendMode.Sub;
				case MBMax: macro h2d.BlendMode.Max;
				case MBMin: macro h2d.BlendMode.Min;
			};
			ctorExprs.push(macro $parentRef.blendMode = $bmExpr);
		}

		// Tint
		if (node.tint != null) {
			final tintExpr = rvToExpr(node.tint);
			ctorExprs.push(macro {
				final _obj = $parentRef;
				if (Std.isOfType(_obj, h2d.Drawable)) {
					final d:h2d.Drawable = cast _obj;
					var c:Int = $tintExpr;
					if (c >>> 24 == 0) c |= 0xFF000000;
					d.color.setColor(c);
				}
			});
		}

		// Filter
		if (node.filter != null) {
			final filterExpr = generateFilterExpr(node.filter, pos);
			if (filterExpr != null) {
				ctorExprs.push(macro $parentRef.filter = $filterExpr);
			}
		}
	}

	/** Conditional APPLY: saves original property values, then in _applyVisibility() applies or reverts based on condition. */
	static function processConditionalApply(node:Node, parentField:String, fields:Array<Field>, ctorExprs:Array<Expr>,
			siblings:Array<{node:Node, fieldName:String}>, pos:Position):Void {
		final parentRef = parentField != null ? (macro $p{["this", parentField]}) : (macro this);
		final applyExprs:Array<Expr> = [];
		final revertExprs:Array<Expr> = [];
		final applyIdx = applyEntries.length;

		// Position offset — save original x/y, apply offset, revert to saved
		if (node.pos != null) {
			switch (node.pos) {
				case ZERO:
				default:
					final saveFieldX = "_applyOrigX_" + applyIdx;
					final saveFieldY = "_applyOrigY_" + applyIdx;
					fields.push(makeField(saveFieldX, FVar(macro :Float, null), [APrivate], pos));
					fields.push(makeField(saveFieldY, FVar(macro :Float, null), [APrivate], pos));
					ctorExprs.push(macro $p{["this", saveFieldX]} = $parentRef.x);
					ctorExprs.push(macro $p{["this", saveFieldY]} = $parentRef.y);
					ensureHexLayoutIfNeeded(node.pos, node, fields, ctorExprs, pos);
					final posExpr = generatePositionExpr(node.pos, parentField, pos, node);
					if (posExpr != null)
						applyExprs.push(posExpr);
					revertExprs.push(macro {
						$parentRef.x = $p{["this", saveFieldX]};
						$parentRef.y = $p{["this", saveFieldY]};
					});
			}
		}

		// Scale — save original, apply, revert
		if (node.scale != null) {
			final saveField = "_applyOrigScale_" + applyIdx;
			fields.push(makeField(saveField, FVar(macro :Float, null), [APrivate], pos));
			ctorExprs.push(macro $p{["this", saveField]} = $parentRef.scaleX);
			final scaleExpr = rvToExpr(node.scale);
			applyExprs.push(macro {
				final s = $scaleExpr;
				$parentRef.scaleX = s;
				$parentRef.scaleY = s;
			});
			revertExprs.push(macro {
				$parentRef.scaleX = $p{["this", saveField]};
				$parentRef.scaleY = $p{["this", saveField]};
			});
		}

		// Rotation — save original, apply, revert
		if (node.rotation != null) {
			final saveField = "_applyOrigRotation_" + applyIdx;
			fields.push(makeField(saveField, FVar(macro :Float, null), [APrivate], pos));
			ctorExprs.push(macro $p{["this", saveField]} = $parentRef.rotation);
			final rotExpr = rvToExpr(node.rotation);
			applyExprs.push(macro $parentRef.rotation = hxd.Math.degToRad($rotExpr));
			revertExprs.push(macro $parentRef.rotation = $p{["this", saveField]});
		}

		// Alpha — save original, apply, revert
		if (node.alpha != null) {
			final saveField = "_applyOrigAlpha_" + applyIdx;
			fields.push(makeField(saveField, FVar(macro :Float, null), [APrivate], pos));
			ctorExprs.push(macro $p{["this", saveField]} = $parentRef.alpha);
			final alphaExpr = rvToExpr(node.alpha);
			applyExprs.push(macro $parentRef.alpha = $alphaExpr);
			revertExprs.push(macro $parentRef.alpha = $p{["this", saveField]});
		}

		// BlendMode — save original, apply, revert
		if (node.blendMode != null) {
			final saveField = "_applyOrigBM_" + applyIdx;
			fields.push(makeField(saveField, FVar(macro :h2d.BlendMode, null), [APrivate], pos));
			ctorExprs.push(macro $p{["this", saveField]} = $parentRef.blendMode);
			final bmExpr:Expr = switch (node.blendMode) {
				case MBNone: macro h2d.BlendMode.None;
				case MBAlpha: macro h2d.BlendMode.Alpha;
				case MBAdd: macro h2d.BlendMode.Add;
				case MBAlphaAdd: macro h2d.BlendMode.AlphaAdd;
				case MBSoftAdd: macro h2d.BlendMode.SoftAdd;
				case MBMultiply: macro h2d.BlendMode.Multiply;
				case MBAlphaMultiply: macro h2d.BlendMode.AlphaMultiply;
				case MBErase: macro h2d.BlendMode.Erase;
				case MBScreen: macro h2d.BlendMode.Screen;
				case MBSub: macro h2d.BlendMode.Sub;
				case MBMax: macro h2d.BlendMode.Max;
				case MBMin: macro h2d.BlendMode.Min;
			};
			applyExprs.push(macro $parentRef.blendMode = $bmExpr);
			revertExprs.push(macro $parentRef.blendMode = $p{["this", saveField]});
		}

		// Tint — save original color, apply, revert
		if (node.tint != null) {
			final saveField = "_applyOrigTint_" + applyIdx;
			fields.push(makeField(saveField, FVar(macro :Int, null), [APrivate], pos));
			ctorExprs.push(macro {
				final _obj = $parentRef;
				$p{["this", saveField]} = if (Std.isOfType(_obj, h2d.Drawable)) {
					final d:h2d.Drawable = cast _obj;
					d.color.toColor();
				} else 0xFFFFFFFF;
			});
			final tintExpr = rvToExpr(node.tint);
			applyExprs.push(macro {
				final _obj = $parentRef;
				if (Std.isOfType(_obj, h2d.Drawable)) {
					final d:h2d.Drawable = cast _obj;
					var c:Int = $tintExpr;
					if (c >>> 24 == 0) c |= 0xFF000000;
					d.color.setColor(c);
				}
			});
			revertExprs.push(macro {
				final _obj = $parentRef;
				if (Std.isOfType(_obj, h2d.Drawable)) {
					final d:h2d.Drawable = cast _obj;
					d.color.setColor($p{["this", saveField]});
				}
			});
		}

		// Filter — save original, apply, revert
		if (node.filter != null) {
			final saveField = "_applyOrigFilter_" + applyIdx;
			fields.push(makeField(saveField, FVar(macro :h2d.filter.Filter, null), [APrivate], pos));
			ctorExprs.push(macro $p{["this", saveField]} = $parentRef.filter);
			final filterExpr = generateFilterExpr(node.filter, pos);
			if (filterExpr != null) {
				applyExprs.push(macro $parentRef.filter = $filterExpr);
				revertExprs.push(macro $parentRef.filter = $p{["this", saveField]});
			}
		}

		// Generate visibility condition
		final visCond = generateVisibilityCondition(node, siblings, null, pos);
		if (visCond != null) {
			applyEntries.push({condition: visCond, applyExprs: applyExprs, revertExprs: revertExprs});
		}

		if (siblings != null)
			siblings.push({node: node, fieldName: ""});
	}

	static function generateBitmapCreate(node:Node, fieldName:String, tileSource:TileSource, hAlign:HorizontalAlign, vAlign:VerticalAlign, pos:Position):CreateResult {
		final tileExpr = tileSourceToExpr(tileSource);
		final fieldRef = macro $p{["this", fieldName]};
		final createExprs:Array<Expr> = [];
		final exprUpdates:Array<{fieldName:String, updateExpr:Expr, paramRefs:Array<String>}> = [];
		// Always use tile.sub() to get an independent copy with correct dx/dy.
		// Atlas tiles may have dx/dy mutated by AnimParser, so we must reset them.
		// This matches the builder which always calls tile.sub() (MultiAnimBuilder line 1481).
		var dxExpr:Expr = switch (hAlign) {
			case Center: macro -(tile.width * 0.5);
			case Right: macro -tile.width;
			default: macro 0.0;
		};
		var dyExpr:Expr = switch (vAlign) {
			case Center: macro -(tile.height * 0.5);
			case Bottom: macro -tile.height;
			default: macro 0.0;
		};

		{
			final block:Array<Expr> = [macro var tile = $tileExpr];
			block.push(macro $fieldRef = new h2d.Bitmap(tile.sub(0, 0, tile.width, tile.height, $dxExpr, $dyExpr)));
			createExprs.push(macro $b{block});
		}

		final tileRefs = collectTileSourceParamRefs(tileSource);
		if (tileRefs.length > 0) {
			exprUpdates.push({
				fieldName: fieldName,
				updateExpr: macro {
					var tile = $tileExpr;
					$fieldRef.tile = tile.sub(0, 0, tile.width, tile.height, $dxExpr, $dyExpr);
				},
				paramRefs: tileRefs,
			});
		}

		return {
			fieldType: macro :h2d.Bitmap,
			createExprs: createExprs,
			isContainer: false,
			exprUpdates: exprUpdates,
		};
	}

	static function generateTextCreate(node:Node, fieldName:String, textDef:TextDef, isRichText:Bool, pos:Position):CreateResult {
		final fieldRef = macro $p{["this", fieldName]};
		final createExprs:Array<Expr> = [];
		final exprUpdates:Array<{fieldName:String, updateExpr:Expr, paramRefs:Array<String>}> = [];
		final extraFields:Array<Field> = [];

		final fontExpr = rvToExpr(textDef.fontName);

		if (isRichText) {
			createExprs.push(macro {
				final font = this._pb.loadFont($fontExpr);
				final t = new h2d.HtmlText(font);
				t.loadFont = (name) -> this._pb.loadFont(name);
				$fieldRef = t;
			});

			// Layer 1: Named styles — defineHtmlTag for each style + shadow fields + setters
			if (textDef.styles != null) {
				for (style in textDef.styles) {
					final safeName = TextMarkupConverter.escapeStyleName(style.name);
					final nameExpr = macro $v{safeName};
					final colorExpr2:Expr = if (style.color != null) {
						final colorRV = style.color;
						final refs = collectParamRefs(colorRV);
						if (refs.length == 0) {
							// Static — bake value
							final c:Int = Std.int(resolveRVStatic(colorRV)) & 0xFFFFFF;
							macro $v{c};
						} else {
							// Dynamic — generate expression
							final rvExpr = rvToExpr(colorRV);
							macro ($rvExpr & 0xFFFFFF);
						}
					} else macro null;
					final fontExpr2:Expr = if (style.fontName != null) {
						final fontRV = style.fontName;
						final refs = collectParamRefs(fontRV);
						if (refs.length == 0) {
							rvToExpr(fontRV);
						} else {
							rvToExpr(fontRV);
						}
					} else macro null;
					createExprs.push(macro {
						final ht:h2d.HtmlText = cast $fieldRef;
						ht.defineHtmlTag($nameExpr, $colorExpr2, $fontExpr2);
					});

					// Shadow fields + setters for each style (only once per style name)
					if (!generatedStyleSetters.exists(style.name)) {
						generatedStyleSetters.set(style.name, true);
						final colorShadow = "_sc_" + style.name;
						final fontShadow = "_sf_" + style.name;
						extraFields.push(makeField(colorShadow, FVar(macro :Null<Int>, null), [APrivate], pos));
						extraFields.push(makeField(fontShadow, FVar(macro :Null<String>, null), [APrivate], pos));
						// Initialize shadow fields
						createExprs.push(macro $p{["this", colorShadow]} = $colorExpr2);
						createExprs.push(macro $p{["this", fontShadow]} = $fontExpr2);
						// setStyleColor_<name>(color:Null<Int>)
						final colorShadowRef = macro $p{["this", colorShadow]};
						final fontShadowRef = macro $p{["this", fontShadow]};
						extraFields.push(makeMethod("setStyleColor_" + style.name, [
							macro $colorShadowRef = color,
							macro {
								final ht:h2d.HtmlText = cast $fieldRef;
								ht.defineHtmlTag($nameExpr, if (color != null) color & 0xFFFFFF else null, $fontShadowRef);
							},
						], [{name: "color", type: macro :Null<Int>}], macro :Void, [APublic], pos));
						// setStyleFont_<name>(fontName:Null<String>)
						extraFields.push(makeMethod("setStyleFont_" + style.name, [
							macro $fontShadowRef = fontName,
							macro {
								final ht:h2d.HtmlText = cast $fieldRef;
								ht.defineHtmlTag($nameExpr, $colorShadowRef, fontName);
							},
						], [{name: "fontName", type: macro :Null<String>}], macro :Void, [APublic], pos));
					}
				}
			}

			// Layer 2: Inline images — loadImage callback (instance field for setter access)
			if (textDef.images != null) {
				final imgMapField = "_imgMap_" + fieldName;
				extraFields.push(makeField(imgMapField, FVar(macro :haxe.ds.StringMap<h2d.Tile>, null), [APrivate], pos));
				final imgMapRef = macro $p{["this", imgMapField]};
				final mapExprs:Array<Expr> = [macro $imgMapRef = new haxe.ds.StringMap<h2d.Tile>()];
				for (img in textDef.images) {
					final imgNameExpr = macro $v{img.name};
					final tileExpr = tileSourceToExpr(img.tileSource);
					mapExprs.push(macro $imgMapRef.set($imgNameExpr, $tileExpr));
				}
				mapExprs.push(macro {
					final ht:h2d.HtmlText = cast $fieldRef;
					ht.loadImage = (url) -> $imgMapRef.get(url);
				});
				final mapBlock:Expr = {expr: EBlock(mapExprs), pos: pos};
				createExprs.push(mapBlock);

				// Generate setImageTile_<name>(tile:h2d.Tile) for each image
				for (img in textDef.images) {
					if (!generatedImageSetters.exists(img.name)) {
						generatedImageSetters.set(img.name, true);
						final imgNameExpr2 = macro $v{img.name};
						extraFields.push(makeMethod("setImageTile_" + img.name, [
							macro $imgMapRef.set($imgNameExpr2, tile),
							macro {
								final ht:h2d.HtmlText = cast $fieldRef;
								ht.text = ht.text;
						},
					], [{name: "tile", type: macro :h2d.Tile}], macro :Void, [APublic], pos));
					}
				}
			}

			// Layer 3: condenseWhite
			if (textDef.condenseWhite != null) {
				final cwExpr = macro $v{textDef.condenseWhite};
				createExprs.push(macro {
					final ht:h2d.HtmlText = cast $fieldRef;
					ht.condenseWhite = $cwExpr;
				});
			}

			// Layer 4: Hyperlinks — onHyperlink fires builder callback("link:id"), hover sets cursor
			createExprs.push(macro {
				final ht:h2d.HtmlText = cast $fieldRef;
				ht.onHyperlink = (url) -> {
					this._pb.resolveCallback("link:" + url, "");
				};
				ht.onOverHyperlink = (url) -> {
					hxd.System.setCursor(Button);
				};
				ht.onOutHyperlink = (url) -> {
					hxd.System.setCursor(Default);
				};
			});
		} else {
			createExprs.push(macro $fieldRef = new h2d.Text(this._pb.loadFont($fontExpr)));
		}

		// Alignment
		switch (textDef.halign) {
			case null: createExprs.push(macro $fieldRef.textAlign = Left);
			case Right: createExprs.push(macro $fieldRef.textAlign = Right);
			case Center: createExprs.push(macro $fieldRef.textAlign = Center);
			case Left: createExprs.push(macro $fieldRef.textAlign = Left);
		}

		// maxWidth — divide by scale to match builder behavior (alignment is calculated pre-scale)
		switch (textDef.textAlignWidth) {
			case TAWValue(value):
				final scaleAdjust:Float = if (node.scale != null) {
					final s = resolveRVStatic(node.scale);
					if (s != null) s else 1.0;
				} else 1.0;
				final staticVal = resolveRVStatic(value);
				if (staticVal != null) {
					final adjustedWidth:Float = staticVal / scaleAdjust;
					createExprs.push(macro $fieldRef.maxWidth = $v{adjustedWidth});
				} else {
					final valExpr = rvToExpr(value);
					final scaleExpr = macro $v{scaleAdjust};
					createExprs.push(macro $fieldRef.maxWidth = $valExpr / $scaleExpr);
				}
			default:
		}

		// Properties
		if (textDef.letterSpacing != 0)
			createExprs.push(macro $fieldRef.letterSpacing = $v{textDef.letterSpacing});
		if (textDef.lineSpacing != 0)
			createExprs.push(macro $fieldRef.lineSpacing = $v{textDef.lineSpacing});
		createExprs.push(macro $fieldRef.lineBreak = $v{textDef.lineBreak});

		if (textDef.dropShadowXY != null) {
			final dx:Float = textDef.dropShadowXY.x;
			final dy:Float = textDef.dropShadowXY.y;
			final color:Int = textDef.dropShadowColor;
			final alpha:Float = textDef.dropShadowAlpha;
			createExprs.push(macro $fieldRef.dropShadow = {dx: $v{dx}, dy: $v{dy}, color: $v{color}, alpha: $v{alpha}});
		}

		final colorExpr = rvToExpr(textDef.color);
		createExprs.push(macro $fieldRef.textColor = $colorExpr);

		final textExpr = rvToExpr(textDef.text, true);
		final rawTextExpr = isStringRV(textDef.text) ? textExpr : macro Std.string($textExpr);

		// Text assignment — with markup conversion if rich text
		final textAssign = if (isRichText) {
			// For static text, pre-convert at macro time
			switch (textDef.text) {
				case RVString(s):
					final converted = TextMarkupConverter.convert(s);
					macro $fieldRef.text = $v{converted};
				default:
					// Runtime conversion for dynamic text
					macro $fieldRef.text = bh.multianim.TextMarkupConverter.convert($rawTextExpr);
			}
		} else {
			isStringRV(textDef.text) ? macro $fieldRef.text = $textExpr : macro $fieldRef.text = Std.string($textExpr);
		}
		createExprs.push(textAssign);

		// Auto-fit: generate font fallback logic
		if (textDef.autoFitFonts != null && textDef.autoFitMode != null) {
			// Build array of fallback font load expressions
			final fontLoadExprs:Array<Expr> = [];
			for (fontRef in textDef.autoFitFonts) {
				final fontNameExpr = rvToExpr(fontRef);
				fontLoadExprs.push(macro this._pb.loadFont($fontNameExpr));
			}
			final fontsArrayExpr:Expr = {expr: EArrayDecl(fontLoadExprs), pos: pos};

			// Determine fit dimensions
			final scaleAdjust:Float = if (node.scale != null) {
				final s = resolveRVStatic(node.scale);
				if (s != null) s else 1.0;
			} else 1.0;

			var fitWidthExpr:Expr = macro null;
			var fitHeightExpr:Expr = macro null;
			switch (textDef.autoFitMode) {
				case AFWidth | AFFillWidth:
					switch (textDef.textAlignWidth) {
						case TAWValue(value):
							final staticVal = resolveRVStatic(value);
							if (staticVal != null) {
								final adj:Float = staticVal / scaleAdjust;
								fitWidthExpr = macro $v{adj};
							} else {
								final valExpr = rvToExpr(value);
								final scExpr = macro $v{scaleAdjust};
								fitWidthExpr = macro $valExpr / $scExpr;
							}
						default:
					}
				case AFBox(w, h) | AFFillBox(w, h):
					final wStatic = resolveRVStatic(w);
					final hStatic = resolveRVStatic(h);
					if (wStatic != null) {
						final adj:Float = wStatic / scaleAdjust;
						fitWidthExpr = macro $v{adj};
					} else {
						final wExpr2 = rvToExpr(w);
						final scExpr = macro $v{scaleAdjust};
						fitWidthExpr = macro $wExpr2 / $scExpr;
					}
					if (hStatic != null) {
						final adj:Float = hStatic / scaleAdjust;
						fitHeightExpr = macro $v{adj};
					} else {
						final hExpr2 = rvToExpr(h);
						final scExpr = macro $v{scaleAdjust};
						fitHeightExpr = macro $hExpr2 / $scExpr;
					}
			}

			final isFill = switch (textDef.autoFitMode) {
				case AFFillWidth | AFFillBox(_, _): true;
				default: false;
			};

			if (isFill) {
				createExprs.push(macro bh.multianim.ProgrammableBuilder.autoFitFill($fieldRef, $fontsArrayExpr, $fitWidthExpr, $fitHeightExpr));
			} else {
				createExprs.push(macro bh.multianim.ProgrammableBuilder.autoFitFirstFit($fieldRef, $fontsArrayExpr, $fitWidthExpr, $fitHeightExpr));
			}
		}

		final textParamRefs = collectParamRefs(textDef.text);
		if (textParamRefs.length > 0) {
			// For incremental updates, always use runtime conversion for rich text
			final updateExpr = if (isRichText) {
				macro $fieldRef.text = bh.multianim.TextMarkupConverter.convert($rawTextExpr);
			} else {
				textAssign;
			}
			exprUpdates.push({
				fieldName: fieldName,
				updateExpr: updateExpr,
				paramRefs: textParamRefs,
			});
		}
		final colorParamRefs = collectParamRefs(textDef.color);
		if (colorParamRefs.length > 0) {
			exprUpdates.push({
				fieldName: fieldName,
				updateExpr: macro $fieldRef.textColor = $colorExpr,
				paramRefs: colorParamRefs,
			});
		}

		// Track style color and font param refs for incremental updates
		if (textDef.styles != null) {
			for (style in textDef.styles) {
				final sNameExpr = macro $v{style.name};
				final sColorExpr:Expr = if (style.color != null) { final e = rvToExpr(style.color); macro ($e & 0xFFFFFF); } else macro null;
				final sFontExpr:Expr = if (style.fontName != null) rvToExpr(style.fontName) else macro null;
				// Collect all param refs from both color and font
				var styleRefs:Array<String> = [];
				if (style.color != null) styleRefs = styleRefs.concat(collectParamRefs(style.color));
				if (style.fontName != null) styleRefs = styleRefs.concat(collectParamRefs(style.fontName));
				if (styleRefs.length > 0) {
					exprUpdates.push({
						fieldName: fieldName,
						updateExpr: macro {
							final ht:h2d.HtmlText = cast $fieldRef;
							ht.defineHtmlTag($sNameExpr, $sColorExpr, $sFontExpr);
						},
						paramRefs: styleRefs,
					});
				}
			}
		}

		return {
			fieldType: macro :h2d.Text,
			createExprs: createExprs,
			isContainer: false,
			exprUpdates: exprUpdates,
			extraFields: extraFields.length > 0 ? extraFields : null,
		};
	}

	static function generateNinepatchCreate(node:Node, fieldName:String, sheet:String, tilename:String, width:ReferenceableValue, height:ReferenceableValue, pos:Position):CreateResult {
		final fieldRef = macro $p{["this", fieldName]};
		final wExpr = rvToExpr(width);
		final hExpr = rvToExpr(height);
		final exprUpdates:Array<{fieldName:String, updateExpr:Expr, paramRefs:Array<String>}> = [];

		final createExprs:Array<Expr> = [
			macro {
				final sg = this._pb.load9Patch($v{sheet}, $v{tilename});
				sg.width = $wExpr;
				sg.height = $hExpr;
				sg.tileCenter = true;
				sg.tileBorders = true;
				sg.ignoreScale = false;
				$fieldRef = sg;
			}
		];

		final wRefs = collectParamRefs(width);
		if (wRefs.length > 0) {
			exprUpdates.push({
				fieldName: fieldName,
				updateExpr: macro $fieldRef.width = $wExpr,
				paramRefs: wRefs,
			});
		}
		final hRefs = collectParamRefs(height);
		if (hRefs.length > 0) {
			exprUpdates.push({
				fieldName: fieldName,
				updateExpr: macro $fieldRef.height = $hExpr,
				paramRefs: hRefs,
			});
		}

		return {
			fieldType: macro :h2d.ScaleGrid,
			createExprs: createExprs,
			isContainer: true,
			exprUpdates: exprUpdates,
		};
	}

	static function flowAlignToExpr(align:MacroFlowAlign):Expr {
		return switch (align) {
			case MFALeft: macro h2d.Flow.FlowAlign.Left;
			case MFARight: macro h2d.Flow.FlowAlign.Right;
			case MFAMiddle: macro h2d.Flow.FlowAlign.Middle;
			case MFATop: macro h2d.Flow.FlowAlign.Top;
			case MFABottom: macro h2d.Flow.FlowAlign.Bottom;
		};
	}

	static function generateFlowCreate(node:Node, fieldName:String, maxWidth:Null<ReferenceableValue>, maxHeight:Null<ReferenceableValue>, minWidth:Null<ReferenceableValue>, minHeight:Null<ReferenceableValue>, lineHeight:Null<ReferenceableValue>, colWidth:Null<ReferenceableValue>, layout:Null<MacroFlowLayout>, paddingTop:Null<ReferenceableValue>, paddingBottom:Null<ReferenceableValue>, paddingLeft:Null<ReferenceableValue>, paddingRight:Null<ReferenceableValue>, horizontalSpacing:Null<ReferenceableValue>, verticalSpacing:Null<ReferenceableValue>, debug:Bool, multiline:Bool, bgSheet:Null<ReferenceableValue>, bgTile:Null<ReferenceableValue>, overflow:Null<MacroFlowOverflow>, fillWidth:Bool, fillHeight:Bool, reverse:Bool, hAlign:Null<MacroFlowAlign>, vAlign:Null<MacroFlowAlign>, pos:Position):CreateResult {
		final fieldRef = macro $p{["this", fieldName]};
		final createExprs:Array<Expr> = [macro $fieldRef = new h2d.Flow()];

		if (maxWidth != null) createExprs.push(macro $fieldRef.maxWidth = ${rvToExpr(maxWidth)});
		if (maxHeight != null) createExprs.push(macro $fieldRef.maxHeight = ${rvToExpr(maxHeight)});
		if (minWidth != null) createExprs.push(macro $fieldRef.minWidth = ${rvToExpr(minWidth)});
		if (minHeight != null) createExprs.push(macro $fieldRef.minHeight = ${rvToExpr(minHeight)});
		if (lineHeight != null) createExprs.push(macro $fieldRef.lineHeight = ${rvToExpr(lineHeight)});
		if (colWidth != null) createExprs.push(macro $fieldRef.colWidth = ${rvToExpr(colWidth)});
		if (layout != null) {
			switch (layout) {
				case MFLHorizontal: createExprs.push(macro $fieldRef.layout = h2d.Flow.FlowLayout.Horizontal);
				case MFLVertical: createExprs.push(macro $fieldRef.layout = h2d.Flow.FlowLayout.Vertical);
				case MFLStack: createExprs.push(macro $fieldRef.layout = h2d.Flow.FlowLayout.Stack);
			}
		}
		if (paddingTop != null) createExprs.push(macro $fieldRef.paddingTop = ${rvToExpr(paddingTop)});
		if (paddingBottom != null) createExprs.push(macro $fieldRef.paddingBottom = ${rvToExpr(paddingBottom)});
		if (paddingLeft != null) createExprs.push(macro $fieldRef.paddingLeft = ${rvToExpr(paddingLeft)});
		if (paddingRight != null) createExprs.push(macro $fieldRef.paddingRight = ${rvToExpr(paddingRight)});
		if (horizontalSpacing != null) createExprs.push(macro $fieldRef.horizontalSpacing = ${rvToExpr(horizontalSpacing)});
		if (verticalSpacing != null) createExprs.push(macro $fieldRef.verticalSpacing = ${rvToExpr(verticalSpacing)});
		if (debug) createExprs.push(macro $fieldRef.debug = true);
		if (multiline) createExprs.push(macro $fieldRef.multiline = true);
		if (overflow != null) {
			switch (overflow) {
				case MFOExpand: createExprs.push(macro $fieldRef.overflow = h2d.Flow.FlowOverflow.Expand);
				case MFOLimit: createExprs.push(macro $fieldRef.overflow = h2d.Flow.FlowOverflow.Limit);
				case MFOScroll: createExprs.push(macro $fieldRef.overflow = h2d.Flow.FlowOverflow.Scroll);
				case MFOHidden: createExprs.push(macro $fieldRef.overflow = h2d.Flow.FlowOverflow.Hidden);
			}
		} else {
			createExprs.push(macro $fieldRef.overflow = h2d.Flow.FlowOverflow.Limit);
		}
		if (fillWidth) createExprs.push(macro $fieldRef.fillWidth = true);
		if (fillHeight) createExprs.push(macro $fieldRef.fillHeight = true);
		if (reverse) createExprs.push(macro $fieldRef.reverse = true);
		if (hAlign != null) createExprs.push(macro $fieldRef.horizontalAlign = ${flowAlignToExpr(hAlign)});
		if (vAlign != null) createExprs.push(macro $fieldRef.verticalAlign = ${flowAlignToExpr(vAlign)});
		if (bgSheet != null && bgTile != null) {
			final sheetExpr = rvToExpr(bgSheet, true);
			final tileExpr = rvToExpr(bgTile, true);
			createExprs.push(macro {
				final _bg = this._pb.load9Patch(Std.string($sheetExpr), Std.string($tileExpr));
				$fieldRef.borderLeft = _bg.borderLeft;
				$fieldRef.borderRight = _bg.borderRight;
				$fieldRef.borderTop = _bg.borderTop;
				$fieldRef.borderBottom = _bg.borderBottom;
				$fieldRef.backgroundTile = _bg.tile;
			});
		}

		return {
			fieldType: macro :h2d.Flow,
			createExprs: createExprs,
			isContainer: true,
			exprUpdates: [],
		};
	}

	static function generateSpacerCreate(node:Node, fieldName:String, width:Null<ReferenceableValue>, height:Null<ReferenceableValue>, pos:Position):CreateResult {
		final fieldRef = macro $p{["this", fieldName]};
		final createExprs:Array<Expr> = [macro $fieldRef = new h2d.Object()];

		// Flow properties will be set after addChild in processNode via spacerFlowEntries
		return {
			fieldType: macro :h2d.Object,
			createExprs: createExprs,
			isContainer: false,
			exprUpdates: [],
		};
	}

	// ==================== Condition/Visibility ====================

	/** Create a sentinel field and emit constructor code to add it before a conditional element. Returns sentinel field name, or null if not conditional. */
	static function createSentinelIfConditional(node:Node, parentField:String, fields:Array<Field>, ctorExprs:Array<Expr>, pos:Position):Null<String> {
		if (node.conditionals.match(NoConditional)) return null;
		final sentinelName = '_sentinel_${sentinelCounter++}';
		fields.push(makeField(sentinelName, FVar(macro :h2d.Object, null), [APrivate], pos));
		final sentinelRef = macro $p{["this", sentinelName]};
		final parentRef = if (parentField != null) macro $p{["this", parentField]} else macro this;
		ctorExprs.push(macro $sentinelRef = new h2d.Object());
		if (node.layer != -1) {
			final layerVal:Int = node.layer;
			ctorExprs.push(macro cast($parentRef, h2d.Layers).add($sentinelRef, $v{layerVal}));
		} else {
			ctorExprs.push(macro $parentRef.addChild($sentinelRef));
		}
		return sentinelName;
	}

	static function generateVisibilityCondition(node:Node, siblings:Array<{node:Node, fieldName:String}>, fieldName:String, pos:Position):Null<Expr> {
		return switch (node.conditionals) {
			case NoConditional: null;

			case Conditional(values, _strict):
				condMapToExpr(values);

			case ConditionalElse(values):
				final priorNeg = negatePriorSiblings(siblings);
				if (values != null) {
					final ownCond = condMapToExpr(values);
					macro($priorNeg && $ownCond);
				} else {
					priorNeg;
				}

			case ConditionalDefault:
				negatePriorSiblings(siblings);
		};
	}

	/** Extract parameter names referenced by a node's conditionals (and prior siblings for @else/@default). */
	static function extractConditionalParamRefs(node:Node, siblings:Array<{node:Node, fieldName:String}>):Array<String> {
		final refs:Array<String> = [];
		switch (node.conditionals) {
			case NoConditional:
			case Conditional(values, _):
				for (key in values.keys())
					if (!refs.contains(key)) refs.push(key);
			case ConditionalElse(values):
				// Collects from prior siblings too (since @else depends on them)
				for (sib in siblings) {
					switch (sib.node.conditionals) {
						case Conditional(sValues, _):
							for (key in sValues.keys())
								if (!refs.contains(key)) refs.push(key);
						case ConditionalElse(sValues):
							if (sValues != null)
								for (key in sValues.keys())
									if (!refs.contains(key)) refs.push(key);
						default:
					}
				}
				if (values != null)
					for (key in values.keys())
						if (!refs.contains(key)) refs.push(key);
			case ConditionalDefault:
				for (sib in siblings) {
					switch (sib.node.conditionals) {
						case Conditional(sValues, _):
							for (key in sValues.keys())
								if (!refs.contains(key)) refs.push(key);
						case ConditionalElse(sValues):
							if (sValues != null)
								for (key in sValues.keys())
									if (!refs.contains(key)) refs.push(key);
						default:
					}
				}
		}
		return refs;
	}

	static function negatePriorSiblings(siblings:Array<{node:Node, fieldName:String}>):Expr {
		var result:Expr = macro true;
		for (sib in siblings) {
			switch (sib.node.conditionals) {
				case Conditional(values, _):
					final sibCond = condMapToExpr(values);
					result = macro($result && !($sibCond));
				case ConditionalElse(values):
					if (values != null) {
						final sibCond = condMapToExpr(values);
						result = macro($result && !($sibCond));
					}
				default:
			}
		}
		return result;
	}

	static function condMapToExpr(values:Map<String, ConditionalValues>):Expr {
		var result:Expr = macro true;
		for (kv in values.keyValueIterator()) {
			final paramName:String = kv.key;
			final condVal:ConditionalValues = kv.value;
			final paramExpr = if (loopVarSubstitutions.exists(paramName)) {
				final val = loopVarSubstitutions.get(paramName);
				macro $v{val};
			} else if (runtimeLoopVars.exists(paramName)) {
				final rtName = runtimeLoopVars.get(paramName);
				macro $i{rtName};
			} else {
				macro $p{["this", "_" + paramName]};
			};
			final cond = condValueToExpr(condVal, paramExpr, paramName);
			result = macro($result && $cond);
		}
		return result;
	}

	static function condValueToExpr(cv:ConditionalValues, paramExpr:Expr, paramName:String):Expr {
		return switch (cv) {
			case CoAny: macro true;

			case CoIndex(idx, _value):
				macro $paramExpr == $v{idx};

			case CoValue(val):
				macro $paramExpr == $v{val};

			case CoStringValue(s):
				macro $paramExpr == $v{s};

			case CoEnums(a):
				if (a.length == 1) {
					final val = enumValueToIndex(paramName, a[0]);
					macro $paramExpr == $v{val};
				} else {
					var result:Expr = macro false;
					for (enumVal in a) {
						final val = enumValueToIndex(paramName, enumVal);
						result = macro($result || $paramExpr == $v{val});
					}
					result;
				}

			case CoRange(from, to, fromExclusive, toExclusive):
				var result:Expr = macro true;
				if (from != null) {
					final fromExpr = rvToExpr(from);
					result = if (fromExclusive) macro($paramExpr > $fromExpr) else macro($paramExpr >= $fromExpr);
				}
				if (to != null) {
					final toExpr = rvToExpr(to);
					final toCond = if (toExclusive) macro($paramExpr < $toExpr) else macro($paramExpr <= $toExpr);
					result = macro($result && $toCond);
				}
				result;

			case CoFlag(f):
				macro($paramExpr & $v{f} == $v{f});

			case CoNot(inner):
				final innerExpr = condValueToExpr(inner, paramExpr, paramName);
				macro !($innerExpr);
		};
	}

	static function enumValueToIndex(paramName:String, value:String):Int {
		final def = paramDefs.get(paramName);
		if (def == null)
			return 0;
		switch (def.type) {
			case PPTEnum(values):
				for (i in 0...values.length) {
					if (values[i] == value)
						return i;
				}
			case PPTBool:
				return value == "true" ? 1 : 0;
			default:
		}
		return 0;
	}

	// ==================== Expression Translation ====================

	static function rvToExpr(rv:ReferenceableValue, forString:Bool = false):Expr {
		if (rv == null)
			return macro 0;

		return switch (rv) {
			case RVInteger(i):
				macro $v{i};
			case RVFloat(f):
				macro $v{f};
			case RVString(s):
				macro $v{s};
			case RVReference(ref):
				// Check loop variable substitutions first (for repeat unrolling)
				if (loopVarSubstitutions.exists(ref)) {
					final val = loopVarSubstitutions.get(ref);
					macro $v{val};
				} else if (runtimeLoopVars.exists(ref)) {
					final rtName = runtimeLoopVars.get(ref);
					macro $i{rtName};
				} else if (finalVarExprs.exists(ref)) {
					rvToExpr(finalVarExprs.get(ref), forString);
				} else {
					final fieldExpr = macro $p{["this", "_" + ref]};
					if (forString) {
						enumToStringExpr(ref, fieldExpr);
					} else {
						fieldExpr;
					}
				}
			case EBinop(op, e1, e2):
				final left = rvToExpr(e1, forString);
				final right = rvToExpr(e2, forString);
				switch (op) {
					case OpAdd: macro($left + $right);
					case OpSub: macro($left - $right);
					case OpMul: macro($left * $right);
					case OpDiv: macro($left / $right);
					case OpIntegerDiv: macro Std.int($left / $right);
					case OpMod: macro($left % $right);
					case OpEq: macro($left == $right ? 1 : 0);
					case OpNotEq: macro($left != $right ? 1 : 0);
					case OpLess: macro($left < $right ? 1 : 0);
					case OpGreater: macro($left > $right ? 1 : 0);
					case OpLessEq: macro($left <= $right ? 1 : 0);
					case OpGreaterEq: macro($left >= $right ? 1 : 0);
				};
			case EUnaryOp(_op, inner):
				final innerExpr = rvToExpr(inner, forString);
				macro -($innerExpr);
			case RVParenthesis(e):
				final inner = rvToExpr(e, forString);
				macro($inner);
			case RVTernary(condition, ifTrue, ifFalse):
				final condE = rvToExpr(condition);
				final trueE = rvToExpr(ifTrue, forString);
				final falseE = rvToExpr(ifFalse, forString);
				macro($condE != 0 ? $trueE : $falseE);
			case RVCallbacks(name, defaultValue):
				final nameExpr = rvToExpr(name);
				final defExpr = rvToExpr(defaultValue);
				if (isStringRV(defaultValue) || defaultValue == null) {
					final defStr = defaultValue != null ? defExpr : macro "";
					macro this._pb.resolveCallback(Std.string($nameExpr), $defStr);
				} else {
					macro this._pb.resolveCallbackInt(Std.string($nameExpr), $defExpr);
				}
			case RVCallbacksWithIndex(name, index, defaultValue):
				final nameExpr = rvToExpr(name);
				final indexExpr = rvToExpr(index);
				final defExpr = rvToExpr(defaultValue);
				if (isStringRV(defaultValue) || defaultValue == null) {
					final defStr = defaultValue != null ? defExpr : macro "";
					macro this._pb.resolveCallbackWithIndex(Std.string($nameExpr), $indexExpr, $defStr);
				} else {
					macro this._pb.resolveCallbackWithIndexInt(Std.string($nameExpr), $indexExpr, $defExpr);
				}
			case RVColorXY(externalReference, name, x, y):
				final nameExpr = macro $v{name};
				final xExpr = rvToExpr(x);
				final yExpr = rvToExpr(y);
				macro this._pb.getPaletteColor2D($nameExpr, $xExpr, $yExpr);
			case RVColor(externalReference, name, index):
				final nameExpr = macro $v{name};
				final indexExpr = rvToExpr(index);
				macro this._pb.getPaletteColorByIndex($nameExpr, $indexExpr);
			case RVElementOfArray(arrayRef, index):
				final indexExpr = rvToExpr(index);
				if (runtimeLoopVars.exists(arrayRef)) {
					final rtName = runtimeLoopVars.get(arrayRef);
					macro $i{rtName};
				} else {
					final arrayFieldRef = macro $p{["this", "_" + arrayRef]};
					macro $arrayFieldRef[$indexExpr];
				}
			case RVPropertyAccess(ref, property):
				// Try static resolution first
				final staticVal = resolveRVStatic(rv);
				if (staticVal != null) {
					macro $v{staticVal};
				} else {
					// Runtime properties
					switch (ref) {
						case "ctx":
							switch (property) {
								case "width": macro this.getScene().width;
								case "height": macro this.getScene().height;
								default:
									Context.error('Unknown context property: $$ctx.$property', Context.currentPos());
									macro 0;
							}
						default:
							Context.error('Cannot resolve property access $$ref.$property at runtime', Context.currentPos());
							macro 0;
					}
				}
			case RVMethodCall(ref, method, args):
				switch (ref) {
					case "ctx":
						switch (method) {
							case "random":
								if (args.length == 2) {
									final minExpr = rvToExpr(args[0]);
									final maxExpr = rvToExpr(args[1]);
									macro $minExpr + Std.random($maxExpr - $minExpr);
								} else {
									Context.error('$$ctx.random() requires 2 arguments (min, max)', Context.currentPos());
									macro 0;
								}
							case "font":
								Context.error('$$ctx.font() must be followed by .lineHeight or .baseLine', Context.currentPos());
								macro 0;
							default:
								Context.error('Unknown context method: $$ctx.$method()', Context.currentPos());
								macro 0;
						}
					default:
						Context.error('Cannot resolve method call $$ref.$method() in expression context — use .x or .y to extract coordinates', Context.currentPos());
						macro 0;
				}
			case RVChainedMethodCall(base, property, _):
				if (property == "lineHeight" || property == "baseLine") {
					// Font property access: $ctx.font("name").lineHeight / .baseLine
					switch (base) {
						case RVMethodCall(ref, method, args):
							if (ref == "ctx" && method == "font" && args.length == 1) {
								final fontNameExpr = rvToExpr(args[0]);
								if (property == "lineHeight")
									macro this._pb.loadFont($fontNameExpr).lineHeight;
								else
									macro this._pb.loadFont($fontNameExpr).baseLine;
							} else {
								Context.error('$$ctx.font("name") is required for .$property access', Context.currentPos());
								macro 0;
							}
						default:
							Context.error('Unsupported base expression for .$property — use $$ctx.font("name").$property', Context.currentPos());
							macro 0;
					}
				} else if (property != "x" && property != "y") {
					Context.error('Unsupported chained property .$property — only .x, .y, .lineHeight, .baseLine are supported', Context.currentPos());
					macro 0;
				} else {
					// Try static resolution first
					final staticVal = resolveRVStatic(rv);
					if (staticVal != null) {
						macro $v{staticVal};
					} else {
						// Generate runtime expression
						switch (base) {
							case RVMethodCall(ref, method, args):
								resolveMethodCallToRuntimeComponentExpr(ref, method, args, property);
							default:
								Context.error('Unsupported base expression for .$property extraction', Context.currentPos());
								macro 0;
						}
					}
				}
			case RVArray(_), RVArrayReference(_):
				Context.error('Array values are not supported in expression context — use repeatable() with array iterator instead', Context.currentPos());
				macro 0;
		};
	}

	/** For enum params in string context, generate a lookup: ["idle","hover",...][this._status].
	 *  For non-enum params, return the expression unchanged. */
	static function enumToStringExpr(ref:String, fieldExpr:Expr):Expr {
		final def = paramDefs.get(ref);
		if (def != null) {
			switch (def.type) {
				case PPTEnum(values):
					final namesExprs = values.map(v -> macro $v{v});
					final namesArray:Expr = {expr: EArrayDecl(namesExprs), pos: Context.currentPos()};
					return macro $namesArray[$fieldExpr];
				default:
			}
		}
		return fieldExpr;
	}

	static function collectParamRefs(rv:ReferenceableValue):Array<String> {
		final refs:Array<String> = [];
		collectParamRefsImpl(rv, refs);
		return refs;
	}

	static function collectParamRefsImpl(rv:ReferenceableValue, refs:Array<String>):Void {
		if (rv == null)
			return;

		switch (rv) {
			case RVReference(ref):
				if (finalVarExprs.exists(ref))
					collectParamRefsImpl(finalVarExprs.get(ref), refs)
				else if (paramDefs.exists(ref) && !loopVarSubstitutions.exists(ref) && !refs.contains(ref))
					refs.push(ref);
			case EBinop(_op, e1, e2):
				collectParamRefsImpl(e1, refs);
				collectParamRefsImpl(e2, refs);
			case EUnaryOp(_op, e):
				collectParamRefsImpl(e, refs);
			case RVParenthesis(e):
				collectParamRefsImpl(e, refs);
			case RVTernary(cond, ifTrue, ifFalse):
				collectParamRefsImpl(cond, refs);
				collectParamRefsImpl(ifTrue, refs);
				collectParamRefsImpl(ifFalse, refs);
			case RVCallbacks(name, defaultValue):
				collectParamRefsImpl(name, refs);
				collectParamRefsImpl(defaultValue, refs);
			case RVCallbacksWithIndex(name, index, defaultValue):
				collectParamRefsImpl(name, refs);
				collectParamRefsImpl(index, refs);
				collectParamRefsImpl(defaultValue, refs);
			case RVMethodCall(_, _, args):
				for (a in args) collectParamRefsImpl(a, refs);
			case RVChainedMethodCall(base, _, args):
				collectParamRefsImpl(base, refs);
				for (a in args) collectParamRefsImpl(a, refs);
			default:
		}
	}

	static function collectTileSourceParamRefs(ts:TileSource):Array<String> {
		final refs:Array<String> = [];
		switch (ts) {
			case TSFile(filename): collectParamRefsImpl(filename, refs);
			case TSSheet(sheet, name): collectParamRefsImpl(sheet, refs); collectParamRefsImpl(name, refs);
			case TSSheetWithIndex(sheet, name, index): collectParamRefsImpl(sheet, refs); collectParamRefsImpl(name, refs); collectParamRefsImpl(index, refs);
			case TSGenerated(type):
				switch (type) {
					case SolidColor(w, h, color): collectParamRefsImpl(w, refs); collectParamRefsImpl(h, refs); collectParamRefsImpl(color, refs);
					case Cross(w, h, color, thickness):
						collectParamRefsImpl(w, refs); collectParamRefsImpl(h, refs);
						collectParamRefsImpl(color, refs); collectParamRefsImpl(thickness, refs);
					case SolidColorWithText(w, h, color, text, textColor, font):
						collectParamRefsImpl(w, refs); collectParamRefsImpl(h, refs); collectParamRefsImpl(color, refs);
						collectParamRefsImpl(text, refs); collectParamRefsImpl(textColor, refs); collectParamRefsImpl(font, refs);
					default:
				}
			case TSReference(ref):
				if (paramDefs != null && paramDefs.exists(ref) && !loopVarSubstitutions.exists(ref) && !refs.contains(ref))
					refs.push(ref);
			default:
		}
		return refs;
	}

	// ==================== Node Settings ====================

	/** Convert a node's settings (walking parent chain) to a ResolvedSettings expression */
	static function nodeSettingsToExpr(node:Node):Expr {
		// Collect settings walking up the parent chain (same logic as MultiAnimBuilder.resolveSettings)
		var merged:Null<Map<String, MultiAnimParser.ParsedSettingValue>> = null;
		var current = node;
		while (current != null) {
			if (current.settings != null) {
				if (merged == null)
					merged = current.settings.copy();
				else {
					for (key => value in current.settings) {
						if (!merged.exists(key))
							merged[key] = value;
					}
				}
			}
			current = current.parent;
		}
		if (merged == null)
			return macro null;

		final entries:Array<Expr> = [];
		for (key => sv in merged) {
			final keyExpr = macro $v{key};
			final valExpr:Expr = switch sv.type {
				case SVTInt: final v = rvToExpr(sv.value); macro bh.multianim.MultiAnimParser.SettingValue.RSVInt($v);
				case SVTFloat: final v = rvToExpr(sv.value); macro bh.multianim.MultiAnimParser.SettingValue.RSVFloat($v);
				case SVTString: final v = rvToExpr(sv.value, true); macro bh.multianim.MultiAnimParser.SettingValue.RSVString($v);
				case SVTColor: final v = rvToExpr(sv.value); macro bh.multianim.MultiAnimParser.SettingValue.RSVColor($v);
				case SVTBool: final v = rvToExpr(sv.value); macro bh.multianim.MultiAnimParser.SettingValue.RSVBool($v != 0);
			};
			entries.push(macro m.set($keyExpr, $valExpr));
		}
		final setBlock:Expr = {expr: EBlock(entries), pos: Context.currentPos()};
		return macro {
			var m = new Map<String, bh.multianim.MultiAnimParser.SettingValue>();
			$setBlock;
			m;
		};
	}

	// ==================== Tile Source ====================

	static function tileSourceToExpr(ts:TileSource):Expr {
		return switch (ts) {
			case TSFile(filename):
				final fnExpr = rvToExpr(filename);
				macro this._pb.loadTileFile($fnExpr);
			case TSSheet(sheet, name):
				final sheetExpr = rvToExpr(sheet);
				final nameExpr = rvToExpr(name);
				macro this._pb.loadTile($sheetExpr, $nameExpr);
			case TSSheetWithIndex(sheet, name, index):
				final sheetExpr = rvToExpr(sheet);
				final nameExpr = rvToExpr(name);
				final indexExpr = rvToExpr(index);
				macro this._pb.loadTileWithIndex($sheetExpr, $nameExpr, $indexExpr);
			case TSGenerated(genType):
				switch (genType) {
					case SolidColor(w, h, color):
						final wExpr = rvToExpr(w);
						final hExpr = rvToExpr(h);
						final cExpr = rvToExpr(color);
						macro {
							var c:Int = $cExpr;
							if (c >>> 24 == 0) c |= 0xFF000000;
							h2d.Tile.fromColor(c, Std.int($wExpr), Std.int($hExpr));
						};
					case Cross(w, h, color, thickness):
						// Cross: solid color with diagonal lines — approximate as solid color
						final wExpr = rvToExpr(w);
						final hExpr = rvToExpr(h);
						final cExpr = rvToExpr(color);
						macro {
							var c:Int = $cExpr;
							if (c >>> 24 == 0) c |= 0xFF000000;
							h2d.Tile.fromColor(c, Std.int($wExpr), Std.int($hExpr));
						};
					case SolidColorWithText(w, h, color, text, textColor, font):
						final wExpr = rvToExpr(w);
						final hExpr = rvToExpr(h);
						final cExpr = rvToExpr(color);
						final textExpr = rvToExpr(text);
						final tcExpr = rvToExpr(textColor);
						final fontExpr = rvToExpr(font);
						macro {
							var c:Int = $cExpr;
							if (c >>> 24 == 0) c |= 0xFF000000;
							var tc:Int = $tcExpr;
							if (tc >>> 24 == 0) tc |= 0xFF000000;
							this._pb.generateColorWithTextTile($wExpr, $hExpr, c, "" + $textExpr, tc, $fontExpr);
						};
					case AutotileRef(autotileName, selector):
						final nameExpr = rvToExpr(autotileName);
						switch (selector) {
							case ByIndex(index):
								final indexExpr = rvToExpr(index);
								macro this._pb.getAutotileTileByIndex($nameExpr, $indexExpr);
							case ByEdges(edges):
								final edgesExpr:Expr = macro $v{edges};
								macro this._pb.getAutotileTileByIndex($nameExpr, $edgesExpr);
						};
					case AutotileRegionSheet(autotileName, scale, font, fontColor):
						final nameExpr = rvToExpr(autotileName);
						final scaleExpr = rvToExpr(scale);
						final fontExpr = rvToExpr(font);
						final fcExpr = rvToExpr(fontColor);
						macro {
							var fc:Int = $fcExpr;
							if (fc >>> 24 == 0) fc |= 0xFF000000;
							this._pb.getAutotileRegionSheetTile($nameExpr, $scaleExpr, $fontExpr, fc);
						};
					default:
						macro this._pb.loadTileFile("placeholder.png");
				};
			case TSReference(ref):
				// Check if the reference is a tile parameter — use the field directly as h2d.Tile
				final def = paramDefs != null ? paramDefs.get(ref) : null;
				if (def != null && def.type == PPTTile) {
					macro $p{["this", "_" + ref]};
				} else {
					macro this._pb.loadTileFile("placeholder.png");
				};
			default:
				macro this._pb.loadTileFile("placeholder.png");
		};
	}

	// ==================== Position ====================

	static function generatePositionExpr(coords:Coordinates, fieldName:String, pos:Position, ?node:MultiAnimParser.Node):Null<Expr> {
		if (coords == null)
			return null;
		final fieldRef = macro $p{["this", fieldName]};

		return switch (coords) {
			case ZERO: null;
			case OFFSET(x, y):
				final xExpr = rvToExpr(x);
				final yExpr = rvToExpr(y);
				macro $fieldRef.setPosition($xExpr, $yExpr);
			case SELECTED_GRID_POSITION(gridX, gridY):
				final grid = getGridFromNode(node);
				if (grid != null) {
					final gxExpr = rvToExpr(gridX);
					final gyExpr = rvToExpr(gridY);
					final sx:Int = grid.spacingX;
					final sy:Int = grid.spacingY;
					macro $fieldRef.setPosition($gxExpr * $v{sx}, $gyExpr * $v{sy});
				} else null;
			case SELECTED_HEX_CUBE(q, r, s):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final qv = resolveRVStatic(q);
					final rv2 = resolveRVStatic(r);
					final sv = resolveRVStatic(s);
					if (qv != null && rv2 != null && sv != null) {
						final hex = new bh.base.Hex.FractionalHex(qv, rv2, sv).round();
						final pt = hexLayout.hexToPixel(hex);
						macro $fieldRef.setPosition($v{pt.x}, $v{pt.y});
					} else {
						final qExpr = rvToExpr(q);
						final rExpr = rvToExpr(r);
						final sExpr = rvToExpr(s);
						final _hlRef = hexFieldRef(node, pos);
						macro {
							final _hex = new bh.base.Hex.FractionalHex($qExpr, $rExpr, $sExpr).round();
							final _p = $_hlRef.hexToPixel(_hex);
							$fieldRef.setPosition(_p.x, _p.y);
						};
					}
				} else null;
			case SELECTED_HEX_OFFSET(col, row, parity):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final c = resolveRVStatic(col);
					final r2 = resolveRVStatic(row);
					if (c != null && r2 != null) {
						final parityVal = switch (parity) { case EVEN: bh.base.Hex.OffsetCoord.EVEN; case ODD: bh.base.Hex.OffsetCoord.ODD; };
						final hex = switch (hexLayout.orientation) {
							case POINTY: bh.base.Hex.OffsetCoord.qoffsetToCube(parityVal, new bh.base.Hex.OffsetCoord(Std.int(c), Std.int(r2)));
							case FLAT: bh.base.Hex.OffsetCoord.roffsetToCube(parityVal, new bh.base.Hex.OffsetCoord(Std.int(c), Std.int(r2)));
						};
						final pt = hexLayout.hexToPixel(hex);
						macro $fieldRef.setPosition($v{pt.x}, $v{pt.y});
					} else {
						final colExpr = rvToExpr(col);
						final rowExpr = rvToExpr(row);
						final parityExpr = switch (parity) {
							case EVEN: macro bh.base.Hex.OffsetCoord.EVEN;
							case ODD: macro bh.base.Hex.OffsetCoord.ODD;
						};
						final _hlRef = hexFieldRef(node, pos);
						switch (hexLayout.orientation) {
							case POINTY: macro {
								final _hex = bh.base.Hex.OffsetCoord.qoffsetToCube($parityExpr, new bh.base.Hex.OffsetCoord($colExpr, $rowExpr));
								final _p = $_hlRef.hexToPixel(_hex);
								$fieldRef.setPosition(_p.x, _p.y);
							};
							case FLAT: macro {
								final _hex = bh.base.Hex.OffsetCoord.roffsetToCube($parityExpr, new bh.base.Hex.OffsetCoord($colExpr, $rowExpr));
								final _p = $_hlRef.hexToPixel(_hex);
								$fieldRef.setPosition(_p.x, _p.y);
							};
						};
					}
				} else null;
			case SELECTED_HEX_DOUBLED(col2, row2):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final c = resolveRVStatic(col2);
					final r2 = resolveRVStatic(row2);
					if (c != null && r2 != null) {
						final hex = switch (hexLayout.orientation) {
							case POINTY: bh.base.Hex.DoubledCoord.qdoubledToCube(new bh.base.Hex.DoubledCoord(Std.int(c), Std.int(r2)));
							case FLAT: bh.base.Hex.DoubledCoord.rdoubledToCube(new bh.base.Hex.DoubledCoord(Std.int(c), Std.int(r2)));
						};
						final pt = hexLayout.hexToPixel(hex);
						macro $fieldRef.setPosition($v{pt.x}, $v{pt.y});
					} else {
						final colExpr = rvToExpr(col2);
						final rowExpr = rvToExpr(row2);
						final _hlRef = hexFieldRef(node, pos);
						switch (hexLayout.orientation) {
							case POINTY: macro {
								final _hex = bh.base.Hex.DoubledCoord.qdoubledToCube(new bh.base.Hex.DoubledCoord($colExpr, $rowExpr));
								final _p = $_hlRef.hexToPixel(_hex);
								$fieldRef.setPosition(_p.x, _p.y);
							};
							case FLAT: macro {
								final _hex = bh.base.Hex.DoubledCoord.rdoubledToCube(new bh.base.Hex.DoubledCoord($colExpr, $rowExpr));
								final _p = $_hlRef.hexToPixel(_hex);
								$fieldRef.setPosition(_p.x, _p.y);
							};
						};
					}
				} else null;
			case SELECTED_HEX_PIXEL(px, py):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final xExpr = rvToExpr(px);
					final yExpr = rvToExpr(py);
					final _hlRef = hexFieldRef(node, pos);
					macro {
						final _hex = $_hlRef.pixelToHex(new bh.base.FPoint($xExpr, $yExpr)).round();
						final _p = $_hlRef.hexToPixel(_hex);
						$fieldRef.setPosition(_p.x, _p.y);
					};
				} else null;
			case SELECTED_HEX_CELL_CORNER(cell, cornerIndex, factor):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final ci = resolveRVStatic(cornerIndex);
					final f = resolveRVStatic(factor);
					final cellHex = resolveCoordToStaticHex(cell, hexLayout);
					if (ci != null && f != null && cellHex != null) {
						final pt = hexLayout.polygonCorner(cellHex, Std.int(ci), f);
						macro $fieldRef.setPosition($v{pt.x}, $v{pt.y});
					} else {
						final ciExpr = rvToExpr(cornerIndex);
						final fExpr = rvToExpr(factor);
						final _hlRef = hexFieldRef(node, pos);
						if (cellHex != null) {
							// Cell is static, only corner params are dynamic
							macro {
								final _p = $_hlRef.polygonCorner(new bh.base.Hex($v{cellHex.q}, $v{cellHex.r}, $v{cellHex.s}), $ciExpr, $fExpr);
								$fieldRef.setPosition(_p.x, _p.y);
							};
						} else {
							final cellExpr = resolveCoordToRuntimeHexExpr(cell, hexLayout);
							if (cellExpr != null)
								macro {
									final _cellHex = $cellExpr;
									final _p = $_hlRef.polygonCorner(_cellHex, $ciExpr, $fExpr);
									$fieldRef.setPosition(_p.x, _p.y);
								}
							else null;
						}
					}
				} else null;
			case SELECTED_HEX_CELL_EDGE(cell, direction, factor):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final d = resolveRVStatic(direction);
					final f = resolveRVStatic(factor);
					final cellHex = resolveCoordToStaticHex(cell, hexLayout);
					if (d != null && f != null && cellHex != null) {
						final pt = hexLayout.polygonEdge(cellHex, Std.int(d), f);
						macro $fieldRef.setPosition($v{pt.x}, $v{pt.y});
					} else {
						final dExpr = rvToExpr(direction);
						final fExpr = rvToExpr(factor);
						final _hlRef = hexFieldRef(node, pos);
						if (cellHex != null) {
							macro {
								final _p = $_hlRef.polygonEdge(new bh.base.Hex($v{cellHex.q}, $v{cellHex.r}, $v{cellHex.s}), $dExpr, $fExpr);
								$fieldRef.setPosition(_p.x, _p.y);
							};
						} else {
							final cellExpr = resolveCoordToRuntimeHexExpr(cell, hexLayout);
							if (cellExpr != null)
								macro {
									final _cellHex = $cellExpr;
									final _p = $_hlRef.polygonEdge(_cellHex, $dExpr, $fExpr);
									$fieldRef.setPosition(_p.x, _p.y);
								}
							else null;
						}
					}
				} else null;
			case SELECTED_HEX_CORNER(count, factor):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final c = resolveRVStatic(count);
					final f = resolveRVStatic(factor);
					if (c != null && f != null) {
						final pt = hexLayout.polygonCorner(bh.base.Hex.zero(), Std.int(c), f);
						macro $fieldRef.setPosition($v{pt.x}, $v{pt.y});
					} else {
						final cExpr = rvToExpr(count);
						final fExpr = rvToExpr(factor);
						final _hlRef = hexFieldRef(node, pos);
						macro {
							final _p = $_hlRef.polygonCorner(bh.base.Hex.zero(), $cExpr, $fExpr);
							$fieldRef.setPosition(_p.x, _p.y);
						};
					}
				} else null;
			case SELECTED_HEX_EDGE(direction, factor):
				final hexLayout = getHexLayoutForNode(node);
				if (hexLayout != null) {
					final d = resolveRVStatic(direction);
					final f = resolveRVStatic(factor);
					if (d != null && f != null) {
						final pt = hexLayout.polygonEdge(bh.base.Hex.zero(), Std.int(d), f);
						macro $fieldRef.setPosition($v{pt.x}, $v{pt.y});
					} else {
						final dExpr = rvToExpr(direction);
						final fExpr = rvToExpr(factor);
						final _hlRef = hexFieldRef(node, pos);
						macro {
							final _p = $_hlRef.polygonEdge(bh.base.Hex.zero(), $dExpr, $fExpr);
							$fieldRef.setPosition(_p.x, _p.y);
						};
					}
				} else null;
			case LAYOUT(layoutName, index):
				final idx = index != null ? resolveRVStatic(index) : 0.0;
				if (idx != null) {
					final layout = getLayoutDef(layoutName);
					final pt = resolveLayoutPosition(layoutName, Std.int(idx));
					if (pt != null) {
						if (layout != null && layoutHasAlign(layout)) {
							needsLayoutAlign = true;
							final ax = alignXToInt(layout.alignX);
							final ay = alignYToInt(layout.alignY);
							macro this.addAlignEntry($fieldRef, $v{pt.x}, $v{pt.y}, $v{ax}, $v{ay}, 0.0, 0.0);
						} else {
							macro $fieldRef.setPosition($v{pt.x}, $v{pt.y});
						}
					} else null;
				} else null;
			case NAMED_COORD(name, coord):
				final namedCS = if (node != null) getNamedCoordSystem(name, node) else null;
				if (namedCS != null) {
					final pt = resolveNamedCoordStatic(namedCS, coord, pos, node);
					if (pt != null)
						macro $fieldRef.setPosition($v{pt.x}, $v{pt.y})
					else
						null;
				} else null;
			case WITH_OFFSET(base, offsetX, offsetY):
				final ox = resolveRVStatic(offsetX);
				final oy = resolveRVStatic(offsetY);
				if (ox != null && oy != null) {
					// Check if base is an aligned LAYOUT
					switch (base) {
						case LAYOUT(layoutName, index):
							final idx = index != null ? resolveRVStatic(index) : 0.0;
							if (idx != null) {
								final layout = getLayoutDef(layoutName);
								final pt = resolveLayoutPosition(layoutName, Std.int(idx));
								if (pt != null && layout != null && layoutHasAlign(layout)) {
									needsLayoutAlign = true;
									final ax = alignXToInt(layout.alignX);
									final ay = alignYToInt(layout.alignY);
									macro this.addAlignEntry($fieldRef, $v{pt.x}, $v{pt.y}, $v{ax}, $v{ay}, $v{ox}, $v{oy});
								} else if (pt != null) {
									macro $fieldRef.setPosition($v{pt.x + ox}, $v{pt.y + oy});
								} else null;
							} else null;
						default:
							final basePt = coordsToStaticXY(base, pos, node);
							if (basePt != null)
								macro $fieldRef.setPosition($v{basePt.x + ox}, $v{basePt.y + oy})
							else {
								// Base is non-static (e.g. EXTRA_POINT_REF) — resolve at runtime with static offset
								final baseXY = coordsToXYExprs(base, pos, node);
								final oxV = ox;
								final oyV = oy;
								macro $fieldRef.setPosition(${baseXY.x} + $v{oxV}, ${baseXY.y} + $v{oyV});
							}
					}
				} else {
					// Non-static offsets — resolve everything at runtime
					final baseXY = coordsToXYExprs(base, pos, node);
					final oxExpr = rvToExpr(offsetX);
					final oyExpr = rvToExpr(offsetY);
					macro $fieldRef.setPosition(${baseXY.x} + $oxExpr, ${baseXY.y} + $oyExpr);
				};
			case EXTRA_POINT_REF(elementName, pointName, fallback):
				final elementFields = namedElements.get(elementName);
				if (elementFields == null || elementFields.length == 0) {
					Context.error('ProgrammableCodeGen: extraPoint reference: element "$elementName" not found in named elements', pos);
					null;
				} else {
					final elemRef = macro $p{["this", elementFields[0]]};
					final fallbackExpr = fallback != null ? generatePositionExpr(fallback, fieldName, pos, node) : null;
					if (fallbackExpr != null)
						macro {
							final _ep = (cast $elemRef : bh.stateanim.AnimationSM).getExtraPoint($v{pointName});
							if (_ep != null) $fieldRef.setPosition(_ep.x, _ep.y) else $fallbackExpr;
						}
					else
						macro {
							final _ep = (cast $elemRef : bh.stateanim.AnimationSM).getExtraPoint($v{pointName});
							if (_ep == null) throw $v{'extraPoint: point "$pointName" not found'};
							$fieldRef.setPosition(_ep.x, _ep.y);
						};
				}
			case EXTRA_POINT_ANIM(filename, animName, pointName, selectorRefs, fallback):
				final fallbackExpr = fallback != null ? generatePositionExpr(fallback, fieldName, pos, node) : null;
				final selExprs:Array<Expr> = [macro final _selMap = new Map<String, String>()];
				for (k => v in selectorRefs) {
					final keyExpr:Expr = macro $v{k};
					final valExpr = rvToExpr(v);
					selExprs.push(macro _selMap.set($keyExpr, Std.string($valExpr)));
				}
				selExprs.push(macro final _animSM = this._pb.resourceLoader.createAnimSM($v{filename}, _selMap));
				selExprs.push(macro _animSM.play($v{animName}));
				if (fallbackExpr != null)
					selExprs.push(macro {
						final _ep = _animSM.getExtraPoint($v{pointName});
						if (_ep != null) $fieldRef.setPosition(_ep.x, _ep.y) else $fallbackExpr;
					})
				else
					selExprs.push(macro {
						final _ep = _animSM.getExtraPoint($v{pointName});
						if (_ep == null) throw $v{'extraPoint: point "$pointName" not found'};
						$fieldRef.setPosition(_ep.x, _ep.y);
					});
				macro $b{selExprs};
		};
	}

	static function collectCoordParamRefs(coord:Coordinates, refs:Array<String>):Void {
		if (coord == null) return;
		switch (coord) {
			case OFFSET(x, y): collectParamRefsImpl(x, refs); collectParamRefsImpl(y, refs);
			case SELECTED_GRID_POSITION(x, y): collectParamRefsImpl(x, refs); collectParamRefsImpl(y, refs);
			case SELECTED_HEX_CUBE(q, r, s): collectParamRefsImpl(q, refs); collectParamRefsImpl(r, refs); collectParamRefsImpl(s, refs);
			case SELECTED_HEX_OFFSET(col, row, _): collectParamRefsImpl(col, refs); collectParamRefsImpl(row, refs);
			case SELECTED_HEX_DOUBLED(col, row): collectParamRefsImpl(col, refs); collectParamRefsImpl(row, refs);
			case SELECTED_HEX_PIXEL(x, y): collectParamRefsImpl(x, refs); collectParamRefsImpl(y, refs);
			case SELECTED_HEX_CORNER(count, factor): collectParamRefsImpl(count, refs); collectParamRefsImpl(factor, refs);
			case SELECTED_HEX_EDGE(dir, factor): collectParamRefsImpl(dir, refs); collectParamRefsImpl(factor, refs);
			case SELECTED_HEX_CELL_CORNER(cell, cornerIndex, factor): collectCoordParamRefs(cell, refs); collectParamRefsImpl(cornerIndex, refs); collectParamRefsImpl(factor, refs);
			case SELECTED_HEX_CELL_EDGE(cell, direction, factor): collectCoordParamRefs(cell, refs); collectParamRefsImpl(direction, refs); collectParamRefsImpl(factor, refs);
			case NAMED_COORD(_, coord): collectCoordParamRefs(coord, refs);
			case WITH_OFFSET(base, offsetX, offsetY): collectCoordParamRefs(base, refs); collectParamRefsImpl(offsetX, refs); collectParamRefsImpl(offsetY, refs);
			default:
		}
	}

	/** Collect param refs from a Coordinates value */
	static function collectPositionParamRefs(coords:Coordinates):Array<String> {
		if (coords == null) return [];
		return switch (coords) {
			case OFFSET(x, y):
				final refs:Array<String> = [];
				collectParamRefsImpl(x, refs);
				collectParamRefsImpl(y, refs);
				refs;
			case SELECTED_GRID_POSITION(gridX, gridY):
				final refs:Array<String> = [];
				collectParamRefsImpl(gridX, refs);
				collectParamRefsImpl(gridY, refs);
				refs;
			case SELECTED_HEX_CORNER(count, factor):
				final refs:Array<String> = [];
				collectParamRefsImpl(count, refs);
				collectParamRefsImpl(factor, refs);
				refs;
			case SELECTED_HEX_EDGE(direction, factor):
				final refs:Array<String> = [];
				collectParamRefsImpl(direction, refs);
				collectParamRefsImpl(factor, refs);
				refs;
			case SELECTED_HEX_CUBE(q, r, s):
				final refs:Array<String> = [];
				collectParamRefsImpl(q, refs);
				collectParamRefsImpl(r, refs);
				collectParamRefsImpl(s, refs);
				refs;
			case SELECTED_HEX_OFFSET(col, row, _):
				final refs:Array<String> = [];
				collectParamRefsImpl(col, refs);
				collectParamRefsImpl(row, refs);
				refs;
			case SELECTED_HEX_DOUBLED(col, row):
				final refs:Array<String> = [];
				collectParamRefsImpl(col, refs);
				collectParamRefsImpl(row, refs);
				refs;
			case SELECTED_HEX_PIXEL(x, y):
				final refs:Array<String> = [];
				collectParamRefsImpl(x, refs);
				collectParamRefsImpl(y, refs);
				refs;
			case SELECTED_HEX_CELL_CORNER(cell, cornerIndex, factor):
				final refs:Array<String> = [];
				collectCoordParamRefs(cell, refs);
				collectParamRefsImpl(cornerIndex, refs);
				collectParamRefsImpl(factor, refs);
				refs;
			case SELECTED_HEX_CELL_EDGE(cell, direction, factor):
				final refs:Array<String> = [];
				collectCoordParamRefs(cell, refs);
				collectParamRefsImpl(direction, refs);
				collectParamRefsImpl(factor, refs);
				refs;
			case LAYOUT(_, index):
				final refs:Array<String> = [];
				collectParamRefsImpl(index, refs);
				refs;
			case NAMED_COORD(_, coord):
				collectPositionParamRefs(coord);
			case WITH_OFFSET(base, offsetX, offsetY):
				final refs:Array<String> = collectPositionParamRefs(base);
				collectParamRefsImpl(offsetX, refs);
				collectParamRefsImpl(offsetY, refs);
				refs;
			default: [];
		};
	}

	/** Get named coordinate system by walking parent chain (macro-safe version) */
	static function getNamedCoordSystem(name:String, node:MultiAnimParser.Node):Null<CoordinateSystems.CoordinateSystemDef> {
		while (node != null) {
			if (node.namedCoordinateSystems != null) {
				final cs = node.namedCoordinateSystems.get(name);
				if (cs != null) return cs;
			}
			node = node.parent;
		}
		return null;
	}

	/** Get grid coordinate system from current node's parent chain */
	static function getGridFromCurrentNode():Null<CoordinateSystems.GridCoordinateSystem> {
		var node = currentProcessingNode;
		while (node != null) {
			if (node.gridCoordinateSystem != null) return node.gridCoordinateSystem;
			node = node.parent;
		}
		return null;
	}

	/** Get grid coordinate system from #defaultLayout */
	static function getGridFromLayout():Null<CoordinateSystems.GridCoordinateSystem> {
		final layoutNode = allParsedNodes.get("#defaultLayout");
		if (layoutNode == null) return null;
		return switch (layoutNode.type) {
			case RELATIVE_LAYOUTS(ld):
				var result:Null<CoordinateSystems.GridCoordinateSystem> = null;
				for (_ => layout in ld) {
					if (layout.grid != null) {
						result = layout.grid;
						break;
					}
				}
				result;
			default: null;
		};
	}

	/** Get grid layout for a node — first traverses parent chain, then falls back to #defaultLayout */
	static function getGridFromNode(?node:MultiAnimParser.Node):Null<CoordinateSystems.GridCoordinateSystem> {
		var n = node;
		while (n != null) {
			if (n.gridCoordinateSystem != null)
				return n.gridCoordinateSystem;
			n = n.parent;
		}
		return getGridFromLayout();
	}

	/** Get hex layout for a node — first traverses parent chain, then falls back to #defaultLayout */
	static function getHexLayoutForNode(?node:MultiAnimParser.Node):Null<bh.base.Hex.HexLayout> {
		// First try the node's parent chain (handles inline hex: pointy/flat on parent elements)
		// Inlined from MultiAnimParser.getHexCoordinateSystem — can't call runtime functions from macro
		var n = node;
		while (n != null) {
			if (n.hexCoordinateSystem != null)
				return n.hexCoordinateSystem.hexLayout;
			n = n.parent;
		}
		// Fall back to #defaultLayout
		final layoutNode = allParsedNodes.get("#defaultLayout");
		if (layoutNode == null) return null;
		return switch (layoutNode.type) {
			case RELATIVE_LAYOUTS(ld):
				var result:Null<bh.base.Hex.HexLayout> = null;
				for (_ => layout in ld) {
					if (layout.hex != null) {
						result = layout.hex.hexLayout;
						break;
					}
				}
				result;
			default: null;
		};
	}

	/** Create a unique key for a hex layout based on orientation + size */
	static function hexLayoutKey(hl:bh.base.Hex.HexLayout):String {
		final o = switch (hl.orientation) { case POINTY: "P"; case FLAT: "F"; };
		return '${o}_${hl.size.x}_${hl.size.y}';
	}

	/** Get or create a hex layout field, returns the field name */
	static function getOrCreateHexField(hexLayout:bh.base.Hex.HexLayout, fields:Array<Field>, ctorExprs:Array<Expr>,
			pos:Position):String {
		final key = hexLayoutKey(hexLayout);
		if (hexLayoutFieldMap.exists(key))
			return hexLayoutFieldMap.get(key);
		final fieldName = hexLayoutFieldCount == 0 ? "_hexLayout" : '_hexLayout${hexLayoutFieldCount}';
		hexLayoutFieldCount++;
		hexLayoutFieldMap.set(key, fieldName);
		fields.push(makeField(fieldName, FVar(macro :bh.base.Hex.HexLayout, null), [APrivate], pos));
		final orientExpr = switch (hexLayout.orientation) {
			case POINTY: macro bh.base.Hex.HexOrientation.POINTY;
			case FLAT: macro bh.base.Hex.HexOrientation.FLAT;
		};
		final initExpr = macro bh.base.Hex.HexLayout.createFromFloats($orientExpr, $v{hexLayout.size.x}, $v{hexLayout.size.y},
			$v{hexLayout.origin.x}, $v{hexLayout.origin.y});
		ctorExprs.push({
			expr: EBinop(OpAssign, {expr: EField({expr: EConst(CIdent("this")), pos: pos}, fieldName), pos: pos}, initExpr),
			pos: pos
		});
		return fieldName;
	}

	/** Build a `this.fieldName` expression for the hex layout of the given node */
	static function hexFieldRef(?node:MultiAnimParser.Node, ?hexLayout:bh.base.Hex.HexLayout, ?pos:Position):Expr {
		if (pos == null) pos = Context.currentPos();
		final hl = hexLayout != null ? hexLayout : (node != null ? getHexLayoutForNode(node) : null);
		if (hl == null) return {expr: EField({expr: EConst(CIdent("this")), pos: pos}, "_hexLayout"), pos: pos};
		final key = hexLayoutKey(hl);
		final fieldName = hexLayoutFieldMap.exists(key) ? hexLayoutFieldMap.get(key) : "_hexLayout";
		return {expr: EField({expr: EConst(CIdent("this")), pos: pos}, fieldName), pos: pos};
	}

	/** Ensure _hexLayout field exists on instance class if coords need runtime hex calculation */
	static function ensureHexLayoutIfNeeded(coords:Coordinates, node:MultiAnimParser.Node, fields:Array<Field>, ctorExprs:Array<Expr>,
			pos:Position):Void {
		if (coords == null)
			return;
		final needsRuntime = switch (coords) {
			case SELECTED_HEX_CORNER(count, factor) | SELECTED_HEX_EDGE(count, factor):
				resolveRVStatic(count) == null || resolveRVStatic(factor) == null;
			case SELECTED_HEX_CUBE(q, r, s):
				resolveRVStatic(q) == null || resolveRVStatic(r) == null || resolveRVStatic(s) == null;
			case SELECTED_HEX_OFFSET(col, row, _):
				resolveRVStatic(col) == null || resolveRVStatic(row) == null;
			case SELECTED_HEX_DOUBLED(col, row):
				resolveRVStatic(col) == null || resolveRVStatic(row) == null;
			case SELECTED_HEX_PIXEL(_, _):
				true; // pixelToHex always requires runtime
			case SELECTED_HEX_CELL_CORNER(cell, cornerIndex, factor):
				resolveRVStatic(cornerIndex) == null || resolveRVStatic(factor) == null || resolveCoordToStaticHex(cell, getHexLayoutForNode(node)) == null;
			case SELECTED_HEX_CELL_EDGE(cell, direction, factor):
				resolveRVStatic(direction) == null || resolveRVStatic(factor) == null || resolveCoordToStaticHex(cell, getHexLayoutForNode(node)) == null;
			default: false;
		};
		if (needsRuntime) {
			final hexLayout = getHexLayoutForNode(node);
			if (hexLayout != null) {
				getOrCreateHexField(hexLayout, fields, ctorExprs, pos);
			}
		}
	}

	/** Ensure _hexLayout field is created for runtime hex method calls in expression context (.x/.y). */
	static function ensureHexLayoutForExprRV(rv:ReferenceableValue, node:MultiAnimParser.Node, fields:Array<Field>, ctorExprs:Array<Expr>,
			pos:Position):Void {
		switch (rv) {
			case RVChainedMethodCall(RVMethodCall(ref, method, _), property, _) if (property == "x" || property == "y"):
				if (ref == "hex" || ref == "ctx.hex" || (currentProcessingNode != null && getNamedCoordSystem(ref, currentProcessingNode) != null)) {
					// Check if static resolution fails (needs runtime)
					if (resolveRVStatic(rv) == null) {
						final hexLayout = getHexLayoutForNode(node);
						if (hexLayout != null) {
							getOrCreateHexField(hexLayout, fields, ctorExprs, pos);
						}
					}
				}
			default:
		}
	}

	/** Get a Layout definition by name from #defaultLayout */
	static function getLayoutDef(name:String):Null<bh.multianim.layouts.LayoutTypes.Layout> {
		final layoutNode = allParsedNodes.get("#defaultLayout");
		if (layoutNode == null) return null;
		final layoutsDef = switch (layoutNode.type) {
			case RELATIVE_LAYOUTS(ld): ld;
			default: return null;
		};
		return layoutsDef.get(name);
	}

	/** Check if a layout uses non-default alignment */
	static function layoutHasAlign(layout:bh.multianim.layouts.LayoutTypes.Layout):Bool {
		return layout.alignX != bh.multianim.layouts.LayoutTypes.LayoutAlignX.Left
			|| layout.alignY != bh.multianim.layouts.LayoutTypes.LayoutAlignY.Top;
	}

	/** Convert LayoutAlignX to integer code for LayoutAlignRoot */
	static function alignXToInt(ax:bh.multianim.layouts.LayoutTypes.LayoutAlignX):Int {
		return switch (ax) { case Left: 0; case Center: 1; case Right: 2; };
	}

	/** Convert LayoutAlignY to integer code for LayoutAlignRoot */
	static function alignYToInt(ay:bh.multianim.layouts.LayoutTypes.LayoutAlignY):Int {
		return switch (ay) { case Top: 0; case Center: 1; case Bottom: 2; };
	}

	/** Resolve a layout position by name and index at macro time */
	static function resolveLayoutPosition(layoutName:String, index:Int):Null<{x:Float, y:Float}> {
		final layoutNode = allParsedNodes.get("#defaultLayout");
		if (layoutNode == null) return null;
		final layoutsDef = switch (layoutNode.type) {
			case RELATIVE_LAYOUTS(ld): ld;
			default: return null;
		};
		final layout = layoutsDef.get(layoutName);
		if (layout == null) return null;

		final offsetX:Float = layout.offset != null ? layout.offset.x : 0;
		final offsetY:Float = layout.offset != null ? layout.offset.y : 0;

		final pt:Null<{x:Float, y:Float}> = switch (layout.type) {
			case Single(content):
				resolveLayoutPoint(content, layout, 0);
			case List(list):
				if (index >= 0 && index < list.length)
					resolveLayoutPoint(list[index], layout, index)
				else
					null;
			case Sequence(_, from, to, content):
				if (index >= from && index <= to)
					resolveLayoutPoint(content, layout, index)
				else
					null;
			case Grid(cols, rows, cellW, cellH):
				if (index >= 0 && index < cols * rows)
					{x: (index % cols) * cellW + 0.0, y: Std.int(index / cols) * cellH + 0.0}
				else
					null;
		};

		if (pt != null) {
			return {x: pt.x + offsetX, y: pt.y + offsetY};
		}
		return null;
	}

	// ==================== Filters ====================

	/** Collect param refs from a FilterType value */
	static function collectFilterParamRefs(filter:FilterType):Array<String> {
		final refs:Array<String> = [];
		collectFilterParamRefsImpl(filter, refs);
		return refs;
	}

	static function collectFilterParamRefsImpl(filter:FilterType, refs:Array<String>):Void {
		switch (filter) {
			case FilterNone:
			case FilterGroup(filters):
				for (f in filters) collectFilterParamRefsImpl(f, refs);
			case FilterOutline(size, color):
				collectParamRefsImpl(size, refs);
				collectParamRefsImpl(color, refs);
			case FilterSaturate(v):
				collectParamRefsImpl(v, refs);
			case FilterBrightness(v):
				collectParamRefsImpl(v, refs);
			case FilterGrayscale(v):
				collectParamRefsImpl(v, refs);
			case FilterHue(v):
				collectParamRefsImpl(v, refs);
			case FilterGlow(color, alpha, radius, gain, quality, _, _):
				collectParamRefsImpl(color, refs);
				collectParamRefsImpl(alpha, refs);
				collectParamRefsImpl(radius, refs);
				collectParamRefsImpl(gain, refs);
				collectParamRefsImpl(quality, refs);
			case FilterBlur(radius, gain, quality, linear):
				collectParamRefsImpl(radius, refs);
				collectParamRefsImpl(gain, refs);
				collectParamRefsImpl(quality, refs);
				collectParamRefsImpl(linear, refs);
			case FilterDropShadow(distance, angle, color, alpha, radius, gain, quality, _):
				collectParamRefsImpl(distance, refs);
				collectParamRefsImpl(angle, refs);
				collectParamRefsImpl(color, refs);
				collectParamRefsImpl(alpha, refs);
				collectParamRefsImpl(radius, refs);
				collectParamRefsImpl(gain, refs);
				collectParamRefsImpl(quality, refs);
			case FilterPixelOutline(mode, _):
				switch (mode) {
					case POKnockout(color, knockout):
						collectParamRefsImpl(color, refs);
						collectParamRefsImpl(knockout, refs);
					case POInlineColor(color, inlineColor):
						collectParamRefsImpl(color, refs);
						collectParamRefsImpl(inlineColor, refs);
				}
			case FilterPaletteReplace(_, sourceRow, replacementRow):
				collectParamRefsImpl(sourceRow, refs);
				collectParamRefsImpl(replacementRow, refs);
			case FilterColorListReplace(sourceColors, replacementColors):
				for (c in sourceColors) collectParamRefsImpl(c, refs);
				for (c in replacementColors) collectParamRefsImpl(c, refs);
			case FilterCustom(_, args):
				for (a in args) collectParamRefsImpl(a.value, refs);
		}
	}

	static function generateFilterExpr(filter:FilterType, pos:Position):Null<Expr> {
		return switch (filter) {
			case FilterNone: null;
			case FilterGroup(filters):
				final addExprs:Array<Expr> = [macro final _fg = new h2d.filter.Group()];
				for (f in filters) {
					final fe = generateFilterExpr(f, pos);
					if (fe != null)
						addExprs.push(macro _fg.add($fe));
				}
				addExprs.push(macro _fg);
				macro $b{addExprs};
			case FilterOutline(size, color):
				final sExpr = rvToExpr(size);
				final cExpr = rvToExpr(color);
				macro new h2d.filter.Outline($sExpr, $cExpr);
			case FilterSaturate(v):
				final vExpr = rvToExpr(v);
				macro {
					final m = new h3d.Matrix();
					m.identity();
					m.colorSaturate($vExpr);
					new h2d.filter.ColorMatrix(m);
				};
			case FilterBrightness(v):
				final vExpr = rvToExpr(v);
				macro {
					final m = new h3d.Matrix();
					m.identity();
					m.colorLightness($vExpr);
					new h2d.filter.ColorMatrix(m);
				};
			case FilterGrayscale(v):
				final vExpr = rvToExpr(v);
				macro {
					final m = new h3d.Matrix();
					m.identity();
					m.colorSaturate(-$vExpr);
					new h2d.filter.ColorMatrix(m);
				};
			case FilterHue(v):
				final vExpr = rvToExpr(v);
				macro {
					final m = new h3d.Matrix();
					m.identity();
					m.colorHue($vExpr);
					new h2d.filter.ColorMatrix(m);
				};
			case FilterGlow(color, alpha, radius, gain, quality, smoothColor, knockout):
				final cExpr = rvToExpr(color);
				final aExpr = rvToExpr(alpha);
				final rExpr = rvToExpr(radius);
				final gExpr = rvToExpr(gain);
				final qExpr = rvToExpr(quality);
				if (knockout) {
					macro {
						final f = new h2d.filter.Glow($cExpr, $aExpr, $rExpr, $gExpr, $qExpr, $v{smoothColor});
						f.knockout = true;
						f;
					};
				} else {
					macro new h2d.filter.Glow($cExpr, $aExpr, $rExpr, $gExpr, $qExpr, $v{smoothColor});
				}
			case FilterBlur(radius, gain, quality, linear):
				final rExpr = rvToExpr(radius);
				final gExpr = rvToExpr(gain);
				final qExpr = rvToExpr(quality);
				final lExpr = rvToExpr(linear);
				macro new h2d.filter.Blur($rExpr, $gExpr, $qExpr, $lExpr);
			case FilterDropShadow(distance, angle, color, alpha, radius, gain, quality, smoothColor):
				final dExpr = rvToExpr(distance);
				final aExpr = rvToExpr(angle);
				final cExpr = rvToExpr(color);
				final alExpr = rvToExpr(alpha);
				final rExpr = rvToExpr(radius);
				final gExpr = rvToExpr(gain);
				final qExpr = rvToExpr(quality);
				macro new h2d.filter.DropShadow($dExpr, hxd.Math.degToRad($aExpr), $cExpr, $alExpr, $rExpr, $gExpr, $qExpr, $v{smoothColor});
			case FilterPixelOutline(mode, smoothColor):
				switch (mode) {
					case POKnockout(color, knockout):
						final cExpr = rvToExpr(color);
						final kExpr = rvToExpr(knockout);
						macro new bh.base.filters.PixelOutline(bh.base.filters.PixelOutlineFilterMode.Knockout($cExpr, $kExpr), $v{smoothColor});
					case POInlineColor(color, inlineColor):
						final cExpr = rvToExpr(color);
						final icExpr = rvToExpr(inlineColor);
						macro new bh.base.filters.PixelOutline(bh.base.filters.PixelOutlineFilterMode.InlineColor($cExpr, $icExpr), $v{smoothColor});
				}
			case FilterPaletteReplace(paletteName, sourceRow, replacementRow):
				final srcExpr = rvToExpr(sourceRow);
				final dstExpr = rvToExpr(replacementRow);
				macro this._pb.buildPaletteReplaceFilter($v{paletteName}, $srcExpr, $dstExpr);
			case FilterColorListReplace(sourceColors, replacementColors):
				// Color list replace — generate arrays of resolved colors
				final srcExprs:Array<Expr> = [];
				for (c in sourceColors) srcExprs.push(rvToExpr(c));
				final dstExprs:Array<Expr> = [];
				for (c in replacementColors) dstExprs.push(rvToExpr(c));
				final srcArr:Expr = {expr: EArrayDecl(srcExprs), pos: pos};
				final dstArr:Expr = {expr: EArrayDecl(dstExprs), pos: pos};
				macro bh.base.filters.ReplacePaletteShader.createAsColorsFilter($srcArr, $dstArr);
			case FilterCustom(name, args):
				// Generate runtime call to FilterManager — custom filters are resolved at runtime only
				final argExprs:Array<Expr> = [];
				for (a in args) {
					final valExpr = rvToExpr(a.value);
					final typeExpr = switch a.type {
						case CFFloat: macro bh.multianim.MultiAnimParser.CustomFilterArgType.CFFloat;
						case CFColor: macro bh.multianim.MultiAnimParser.CustomFilterArgType.CFColor;
						case CFBool: macro bh.multianim.MultiAnimParser.CustomFilterArgType.CFBool;
					};
					argExprs.push(macro {value: $valExpr, type: $typeExpr});
				}
				final argsArr:Expr = {expr: EArrayDecl(argExprs), pos: pos};
				macro bh.base.FilterManager.buildCustomFilter($v{name}, $argsArr);
		};
	}

	// ==================== Factory / Public API ====================

	/** Generate instance class constructor: (pb:ProgrammableBuilder, params...) -> builds tree.
	 *  The instance extends h2d.Object, so super() is h2d.Object(). */
	static function generateInstanceConstructor(constructorExprs:Array<Expr>, pos:Position):Field {
		// Build constructor args: first is _pb, then typed params
		final ctorArgs:Array<FunctionArg> = [];
		ctorArgs.push({name: "_pb", type: macro :bh.multianim.ProgrammableBuilder});

		// Partition params: required first, optional last
		final orderedParams = getOrderedParams();
		for (name in orderedParams) {
			final def = paramDefs.get(name);
			final pubType = publicParamType(name, def.type);
			final hasDefault = def.defaultValue != null;
			ctorArgs.push({
				name: name,
				type: pubType,
				opt: hasDefault,
				value: hasDefault ? publicDefaultValue(name, def) : null,
			});
		}

		// Build constructor body
		final ctorBody:Array<Expr> = [];
		ctorBody.push(macro super());
		ctorBody.push(macro this._pb = _pb);

		// Create local vars for params with proper conversion (Bool -> Int, etc.)
		// These locals are named _paramName to match what constructorExprs references
		for (pName in paramNames) {
			final privateName = "_" + pName;
			final def = paramDefs.get(pName);
			final enumInfo = paramEnumTypes.get(pName);
			final convExpr:Expr = if (enumInfo != null && enumInfo.typePath == "Bool") {
				macro($i{pName} ? 1 : 0);
			} else if (def.type == PPTArray && def.defaultValue != null) {
				// Array params default to null in signature; apply parsed default here
				final defaultArr = resolvedParamToExpr(def.defaultValue, def.type);
				macro($i{pName} != null ? $i{pName} : $defaultArr);
			} else {
				macro $i{pName};
			};
			ctorBody.push({
				expr: EVars([{name: privateName, type: null, expr: convExpr, isFinal: false}]),
				pos: pos,
			});
		}

		// Tree building (param assignments, child elements)
		for (e in constructorExprs)
			ctorBody.push(e);

		ctorBody.push(macro this._applyVisibility());
		ctorBody.push(macro this._updateExpressions());

		return {
			name: "new",
			kind: FFun({
				args: ctorArgs,
				ret: null,
				expr: macro $b{ctorBody},
			}),
			access: [APublic],
			pos: pos,
		};
	}

	/** Generate factory create() method: loads builder, creates new instance, returns it. */
	static function generateFactoryCreate(pos:Position):Field {
		final hasTransitions = currentTransitions != null && currentTransitions.iterator().hasNext();
		// Build create() args (same typed params as instance constructor, minus _pb)
		final createArgs:Array<FunctionArg> = [];
		final orderedParams = getOrderedParams();
		for (name in orderedParams) {
			final def = paramDefs.get(name);
			final pubType = publicParamType(name, def.type);
			final hasDefault = def.defaultValue != null;
			createArgs.push({
				name: name,
				type: pubType,
				opt: hasDefault,
				value: hasDefault ? publicDefaultValue(name, def) : null,
			});
		}

		// Add optional placeholders parameter when programmable uses builderParameter placeholders
		if (hasBuilderParameterPlaceholders) {
			createArgs.push({
				name: "placeholders",
				type: macro :Null<Map<String, bh.multianim.MultiAnimBuilder.PlaceholderValues>>,
				opt: true,
				value: null,
			});
		}

		// Build create() body: load builder, create instance, return it
		final manimPathLit = macro $v{currentManimPath};

		// Build the new InstanceClass(this, param1, param2, ...) expression
		final newArgs:Array<Expr> = [macro this];
		for (name in orderedParams)
			newArgs.push(macro $i{name});

		final instTypePath = {pack: localClassPack, name: instanceClassName};
		final newExpr:Expr = {expr: ENew(instTypePath, newArgs), pos: pos};

		final createBody:Array<Expr> = [
			macro this._builder = this.resourceLoader.loadMultiAnim($manimPathLit),
		];
		if (hasBuilderParameterPlaceholders)
			createBody.push(macro this.setPlaceholderObjects(placeholders));
		if (hasTransitions) {
			createBody.push(macro final _inst = $newExpr);
			createBody.push(macro if (this.tweenManager != null) _inst.setTweenManager(this.tweenManager));
			createBody.push(macro return _inst);
		} else {
			createBody.push(macro return $newExpr);
		}

		final instType:ComplexType = TPath(instTypePath);
		return {
			name: "create",
			kind: FFun({
				args: createArgs,
				ret: instType,
				expr: macro $b{createBody},
			}),
			access: [APublic],
			pos: pos,
		};
	}

	/** Generate factory createFrom() method: takes anonymous struct with named params, creates new instance. */
	static function generateFactoryCreateFrom(pos:Position):Field {
		// 1. Build anonymous struct type: one field per param, optional fields use Null<T>
		final anonFields:Array<Field> = [];
		for (name in paramNames) {
			final def = paramDefs.get(name);
			final hasDefault = def.defaultValue != null;
			final baseType = publicParamType(name, def.type);
			final fieldType = if (hasDefault) nullableType(baseType, def.type) else baseType;

			anonFields.push({
				name: name,
				kind: FVar(fieldType, null),
				pos: pos,
				access: [],
				meta: hasDefault ? [{name: ":optional", params: [], pos: pos}] : [],
			});
		}
		final paramStructType:ComplexType = TAnonymous(anonFields);

		// 2. Build method body: extract values from struct with null-coalescing, then new Instance(this, ...)
		final manimPathLit = macro $v{currentManimPath};
		final bodyExprs:Array<Expr> = [
			macro this._builder = this.resourceLoader.loadMultiAnim($manimPathLit),
		];
		if (hasBuilderParameterPlaceholders)
			bodyExprs.push(macro this.setPlaceholderObjects(placeholders));

		final orderedParams = getOrderedParams();
		final newArgs:Array<Expr> = [macro this];

		for (name in orderedParams) {
			final def = paramDefs.get(name);
			final hasDefault = def.defaultValue != null;
			final fieldAccess:Expr = {expr: EField(macro params, name), pos: pos};

			if (hasDefault) {
				final defaultExpr = publicDefaultValue(name, def);
				final ternaryExpr:Expr = {
					expr: ETernary(
						{expr: EBinop(OpNotEq, fieldAccess, macro null), pos: pos},
						fieldAccess,
						defaultExpr
					),
					pos: pos,
				};
				final localName = "_arg_" + name;
				bodyExprs.push({
					expr: EVars([{name: localName, type: null, expr: ternaryExpr, isFinal: true}]),
					pos: pos,
				});
				newArgs.push(macro $i{localName});
			} else {
				newArgs.push(fieldAccess);
			}
		}

		final instTypePath = {pack: localClassPack, name: instanceClassName};
		final newExpr:Expr = {expr: ENew(instTypePath, newArgs), pos: pos};
		final hasTransitions = currentTransitions != null && currentTransitions.iterator().hasNext();
		if (hasTransitions) {
			bodyExprs.push(macro final _inst = $newExpr);
			bodyExprs.push(macro if (this.tweenManager != null) _inst.setTweenManager(this.tweenManager));
			bodyExprs.push(macro return _inst);
		} else {
			bodyExprs.push(macro return $newExpr);
		}

		final instType:ComplexType = TPath(instTypePath);
		final createFromArgs:Array<FunctionArg> = [{name: "params", type: paramStructType}];
		if (hasBuilderParameterPlaceholders) {
			createFromArgs.push({
				name: "placeholders",
				type: macro :Null<Map<String, bh.multianim.MultiAnimBuilder.PlaceholderValues>>,
				opt: true,
			});
		}
		return {
			name: "createFrom",
			kind: FFun({
				args: createFromArgs,
				ret: instType,
				expr: macro $b{bodyExprs},
			}),
			access: [APublic],
			pos: pos,
		};
	}

	/** Wrap a type in Null<T> for value types (Int, Float, Bool) to make them nullable in anonymous structs.
	 *  String is already nullable and doesn't need wrapping. */
	static function nullableType(baseType:ComplexType, defType:DefinitionType):ComplexType {
		return switch (defType) {
			case PPTString:
				baseType; // String is already nullable
			default:
				TPath({pack: [], name: "Null", params: [TPType(baseType)]});
		};
	}

	/** Get ordered params: required first, optional last */
	static function getOrderedParams():Array<String> {
		final requiredParams:Array<String> = [];
		final optionalParams:Array<String> = [];
		for (name in paramNames) {
			final def = paramDefs.get(name);
			if (def.defaultValue != null)
				optionalParams.push(name);
			else
				requiredParams.push(name);
		}
		return requiredParams.concat(optionalParams);
	}

	/** Get the public-facing type for a parameter (Bool for bool params, Int for enums, raw type otherwise) */
	static function publicParamType(name:String, type:DefinitionType):ComplexType {
		final enumInfo = paramEnumTypes.get(name);
		if (enumInfo != null) {
			if (enumInfo.typePath == "Bool")
				return macro :Bool;
			// Enum params use Int with static inline constants on the class
			return macro :Int;
		}
		return paramFieldType(type);
	}

	/** Generate the default value expression for a parameter in the public API */
	static function publicDefaultValue(name:String, def:{defaultValue:ResolvedIndexParameters, type:DefinitionType}):Expr {
		final enumInfo = paramEnumTypes.get(name);
		if (enumInfo != null && enumInfo.typePath == "Bool") {
			// Bool param: Value(1) -> true, Value(0) -> false (matching parser convention)
			return switch (def.defaultValue) {
				case Index(idx, _): macro $v{idx != 0};
				case Value(val): macro $v{val != 0};
				default: macro false;
			};
		} else if (enumInfo != null) {
			// Enum param: just use the Int index directly
			return resolvedParamToExpr(def.defaultValue, def.type);
		}
		// Array params: Haxe doesn't allow non-constant default values, use null
		if (def.type == PPTArray)
			return macro null;
		return resolvedParamToExpr(def.defaultValue, def.type);
	}

	// ==================== Helpers ====================

	/** Check if a ReferenceableValue will produce a String expression */
	static function isStringRV(rv:ReferenceableValue):Bool {
		if (rv == null) return false;
		return switch (rv) {
			case RVString(_): true;
			case RVReference(ref):
				final def = paramDefs.get(ref);
				def != null && def.type == PPTString;
			case RVCallbacks(_, defaultValue): defaultValue == null || isStringRV(defaultValue);
			case RVCallbacksWithIndex(_, _, defaultValue): defaultValue == null || isStringRV(defaultValue);
			default: false;
		};
	}

	static function paramFieldType(type:DefinitionType):ComplexType {
		return switch (type) {
			case PPTEnum(_): macro :Int;
			case PPTBool: macro :Int;
			case PPTInt | PPTUnsignedInt | PPTColor: macro :Int;
			case PPTFloat: macro :Float;
			case PPTString: macro :String;
			case PPTRange(_, _): macro :Int;
			case PPTFlags(_): macro :Int;
			case PPTArray: macro :Array<String>;
			case PPTTile: macro :Dynamic;
			default: macro :Int;
		};
	}

	static function resolvedParamToExpr(rip:ResolvedIndexParameters, type:DefinitionType):Expr {
		if (rip == null)
			return macro 0;

		return switch (rip) {
			case Index(idx, _value):
				macro $v{idx};
			case Value(val):
				macro $v{val};
			case ValueF(val):
				macro $v{val};
			case Flag(f):
				macro $v{f};
			case StringValue(s):
				macro $v{s};
			case ArrayString(arr):
				final elements:Array<Expr> = [for (s in arr) macro $v{s}];
				{expr: EArrayDecl(elements), pos: (macro null).pos};
			default:
				macro null;
		};
	}

	// ==================== Data Block Codegen ====================

	/** Generate fields for a data class from a DataDef.
	 *  Enum types become enum abstracts over Int, record types become exposed classes,
	 *  scalar/array fields become public final fields.
	 *  @param dataName The #name from the manim file (e.g., "gameData") — used for exposed type naming
	 *  @param className The internal data class name (e.g., "MultiProgrammable_GameData")
	 *  @param typePack Package for exposed record/enum types
	 *  @param mergeTypes Whether to deduplicate identical record/enum types
	 */
	static function generateDataClass(dataDef:DataDef, dataName:String, className:String, typePack:Array<String>,
			mergeTypes:Bool, pos:Position):Array<Field> {
		var dataFields:Array<Field> = [];

		// Map from enum name → exposed type {pack, name}
		var enumTypeMap:Map<String, {pack:Array<String>, name:String}> = new Map();

		// Generate enum abstract types (before records, since records may reference enums)
		for (enumName => enumDef in dataDef.enums) {
			final exposedName = toPascalCase(dataName) + toPascalCase(enumName);

			// Check for mergeTypes dedup
			if (mergeTypes) {
				final sig = enumSignature(enumDef);
				final existing = mergedTypeCache.get(sig);
				if (existing != null) {
					enumTypeMap.set(enumName, existing);
					continue;
				}
			}

			// Check for type collision
			try {
				Context.getType(typePack.join(".") + (typePack.length > 0 ? "." : "") + exposedName);
				Context.fatalError('Type "$exposedName" already exists (collision with data enum "$enumName")', pos);
			} catch (_:Dynamic) {
				// Expected — type doesn't exist yet
			}

			final enumFields:Array<Field> = [];
			for (i in 0...enumDef.values.length) {
				enumFields.push({
					name: toPascalCase(enumDef.values[i]),
					kind: FVar(null),
					pos: pos,
				});
			}

			final typeInfo = {pack: typePack, name: exposedName};
			enumTypeMap.set(enumName, typeInfo);

			final enumTd:TypeDefinition = {
				pack: typePack,
				name: exposedName,
				pos: pos,
				kind: TDEnum,
				fields: enumFields,
			};
			Context.defineType(enumTd);

			if (mergeTypes) {
				mergedTypeCache.set(enumSignature(enumDef), typeInfo);
			}
		}

		// Map from record name → exposed type {pack, name}
		var recordTypeMap:Map<String, {pack:Array<String>, name:String}> = new Map();

		// Generate exposed record types
		for (recordName => recordDef in dataDef.records) {
			final exposedName = toPascalCase(dataName) + toPascalCase(recordName);

			// Check for mergeTypes dedup
			if (mergeTypes) {
				final sig = recordSignature(recordDef);
				final existing = mergedTypeCache.get(sig);
				if (existing != null) {
					recordTypeMap.set(recordName, existing);
					continue;
				}
			}

			// Check for type collision
			try {
				Context.getType(typePack.join(".") + (typePack.length > 0 ? "." : "") + exposedName);
				Context.fatalError('Type "$exposedName" already exists (collision with data record "$recordName")', pos);
			} catch (_:Dynamic) {
				// Expected — type doesn't exist yet
			}

			final recordFields:Array<Field> = [];

			// Public final fields for each record field
			for (rf in recordDef.fields) {
				var ct = dataTypeToComplexType(rf.type, enumTypeMap, recordTypeMap);
				if (rf.optional) ct = TPath({pack: [], name: "Null", params: [TPType(ct)]});
				recordFields.push({
					name: rf.name,
					kind: FVar(ct, null),
					access: [APublic],
					pos: pos,
				});
			}

			// Constructor: new(field1, field2, ...) — optional fields have opt:true
			final ctorArgs:Array<FunctionArg> = [];
			final ctorAssigns:Array<Expr> = [];
			for (rf in recordDef.fields) {
				var ct = dataTypeToComplexType(rf.type, enumTypeMap, recordTypeMap);
				if (rf.optional) ct = TPath({pack: [], name: "Null", params: [TPType(ct)]});
				ctorArgs.push({name: rf.name, type: ct, opt: rf.optional});
				ctorAssigns.push(macro $p{["this", rf.name]} = $i{rf.name});
			}
			recordFields.push({
				name: "new",
				kind: FFun({args: ctorArgs, ret: null, expr: macro $b{ctorAssigns}}),
				access: [APublic],
				pos: pos,
			});

			final typeInfo = {pack: typePack, name: exposedName};
			recordTypeMap.set(recordName, typeInfo);

			final recordTd:TypeDefinition = {
				pack: typePack,
				name: exposedName,
				pos: pos,
				kind: TDClass(null, null, false, false, false),
				fields: recordFields,
			};
			Context.defineType(recordTd);

			if (mergeTypes) {
				mergedTypeCache.set(recordSignature(recordDef), typeInfo);
			}
		}

		// Generate public final fields for each data entry
		for (field in dataDef.fields) {
			final initExpr = dataValueToExpr(field.value, enumTypeMap, recordTypeMap, dataDef.enums, dataDef.records, pos);
			dataFields.push({
				name: field.name,
				kind: FVar(dataTypeToComplexType(field.type, enumTypeMap, recordTypeMap), initExpr),
				access: [APublic, AFinal],
				pos: pos,
			});
		}

		// Empty constructor (fields initialized inline)
		dataFields.push({
			name: "new",
			kind: FFun({args: [], ret: null, expr: macro {}}),
			access: [APublic],
			pos: pos,
		});

		return dataFields;
	}

	/** Build a signature string for a record definition (for mergeTypes dedup) */
	static function recordSignature(recordDef:DataRecordDef):String {
		var parts:Array<String> = [];
		for (rf in recordDef.fields) {
			final opt = rf.optional ? "?" : "";
			parts.push('$opt${rf.name}:${dataValueTypeSignature(rf.type)}');
		}
		return parts.join(",");
	}

	/** Build a signature string for an enum definition (for mergeTypes dedup) */
	static function enumSignature(enumDef:DataEnumDef):String {
		return 'Enum(${enumDef.values.join(",")})';
	}

	static function dataValueTypeSignature(type:DataValueType):String {
		return switch (type) {
			case DVTInt: "Int";
			case DVTFloat: "Float";
			case DVTString: "String";
			case DVTBool: "Bool";
			case DVTEnum(enumName): 'Enum($enumName)';
			case DVTRecord(recordName): 'Record($recordName)';
			case DVTArray(elemType): 'Array<${dataValueTypeSignature(elemType)}>';
		};
	}

	/** Convert a DataValueType to a Haxe ComplexType */
	static function dataTypeToComplexType(type:DataValueType, enumTypeMap:Map<String, {pack:Array<String>, name:String}>,
			recordTypeMap:Map<String, {pack:Array<String>, name:String}>):ComplexType {
		return switch (type) {
			case DVTInt: macro :Int;
			case DVTFloat: macro :Float;
			case DVTString: macro :String;
			case DVTBool: macro :Bool;
			case DVTEnum(enumName):
				final info = enumTypeMap.get(enumName);
				if (info == null) macro :Int;
				else TPath({pack: info.pack, name: info.name});
			case DVTRecord(recordName):
				final info = recordTypeMap.get(recordName);
				if (info == null) macro :Dynamic;
				else TPath({pack: info.pack, name: info.name});
			case DVTArray(elemType):
				final elemCT = dataTypeToComplexType(elemType, enumTypeMap, recordTypeMap);
				TPath({pack: [], name: "Array", params: [TPType(elemCT)]});
		};
	}

	/** Convert a DataValue to a Haxe expression for field initialization */
	static function dataValueToExpr(value:DataValue, enumTypeMap:Map<String, {pack:Array<String>, name:String}>,
			recordTypeMap:Map<String, {pack:Array<String>, name:String}>,
			enums:Map<String, DataEnumDef>, records:Map<String, DataRecordDef>, pos:Position):Expr {
		return switch (value) {
			case DVInt(v): {expr: EConst(CInt('$v')), pos: pos};
			case DVFloat(v): {expr: EConst(CFloat('$v')), pos: pos};
			case DVString(v): {expr: EConst(CString(v)), pos: pos};
			case DVBool(v): {expr: EConst(CIdent(v ? "true" : "false")), pos: pos};
			case DVEnumValue(enumName, value):
				final info = enumTypeMap.get(enumName);
				if (info != null) {
					// Build fully-qualified enum constructor: pack.EnumType.Constructor
					var typeExpr:Expr = {expr: EConst(CIdent(info.pack.length > 0 ? info.pack[0] : info.name)), pos: pos};
					if (info.pack.length > 0) {
						for (i in 1...info.pack.length)
							typeExpr = {expr: EField(typeExpr, info.pack[i]), pos: pos};
						typeExpr = {expr: EField(typeExpr, info.name), pos: pos};
					}
					{expr: EField(typeExpr, toPascalCase(value)), pos: pos};
				} else {
					// Fallback: use string value
					{expr: EConst(CString(value)), pos: pos};
				}
			case DVArray(elements):
				final elemExprs = [for (e in elements) dataValueToExpr(e, enumTypeMap, recordTypeMap, enums, records, pos)];
				{expr: EArrayDecl(elemExprs), pos: pos};
			case DVRecord(recordName, fields):
				final info = recordTypeMap.get(recordName);
				final recordDef = records.get(recordName);
				final ctorArgs:Array<Expr> = [];
				if (recordDef != null) {
					for (rf in recordDef.fields) {
						final val = fields.get(rf.name);
						if (val != null)
							ctorArgs.push(dataValueToExpr(val, enumTypeMap, recordTypeMap, enums, records, pos));
						else if (rf.optional)
							ctorArgs.push(macro null);
					}
				}
				if (info != null)
					{expr: ENew({pack: info.pack, name: info.name}, ctorArgs), pos: pos}
				else
					macro null;
		};
	}

	static function slotHandleFieldName(key:MacroSlotKey):String {
		return switch key {
			case Named(name): "_slotHandle_" + name;
			case Indexed(name, index): "_slotHandle_" + name + "_" + index;
			case Indexed2D(name, indexX, indexY): "_slotHandle_" + name + "_" + indexX + "_" + indexY;
		};
	}

	static function toPascalCase(s:String):String {
		final parts = s.split("-").join("_").split("_");
		var result = "";
		for (part in parts) {
			if (part.length > 0)
				result += part.charAt(0).toUpperCase() + part.substr(1);
		}
		return result;
	}

	// ==================== Paths/Curves/AnimatedPath Factory Methods ====================

	static function generatePathsFactoryMethods(pathsDef:PathsDef, factoryFields:Array<Field>, pos:Position):Void {
		// Generic getPath(name, ?normalization) method - still uses builder for dynamic name
		factoryFields.push(makeMethod("getPath", [
			macro return this.buildPath(name, normalization)
		], [
			{name: "name", type: macro :String},
			{name: "normalization", type: macro :Null<bh.paths.MultiAnimPaths.PathNormalization>, opt: true},
		], macro :bh.paths.MultiAnimPaths.Path, [APublic], pos));

		// Per-path typed methods: getPath_<name>(?startPoint, ?endPoint) with inline construction
		for (pathName => pathDef in pathsDef) {
			var resolved = resolvePathToExprs(pathDef);
			if (resolved != null) {
				// Pre-compute normalized ranges at compile time
				var totalLength = 0.0;
				for (l in resolved.lengths) totalLength += l;

				if (totalLength > 0) {
					// Compute normalized startRange/endRange for each segment
					var startRanges:Array<Float> = [];
					var endRanges:Array<Float> = [];
					var cumulative = 0.0;
					for (l in resolved.lengths) {
						startRanges.push(cumulative / totalLength);
						cumulative += l;
						endRanges.push(cumulative / totalLength);
					}

					// Rewrite exprs to use SinglePath.withRange() with pre-normalized ranges
					var rangedExprs:Array<Expr> = [];
					for (i in 0...resolved.exprs.length) {
						var origExpr = resolved.exprs[i];
						var sr = startRanges[i];
						var er = endRanges[i];
						switch origExpr.expr {
							case ENew(_, args) if (args.length == 3):
								rangedExprs.push(macro bh.paths.MultiAnimPaths.SinglePath.withRange(
									${args[0]}, ${args[1]}, ${args[2]}, $v{sr}, $v{er}
								));
							default:
								rangedExprs.push(origExpr);
						}
					}

					// Normalize checkpoint rates
					var cpNames:Array<Expr> = [for (n in resolved.checkpointNames) macro $v{n}];
					var cpRates:Array<Expr> = [for (l in resolved.checkpointLengths) macro $v{l / totalLength}];
					var cpNamesExpr:Expr = {expr: EArrayDecl(cpNames), pos: pos};
					var cpRatesExpr:Expr = {expr: EArrayDecl(cpRates), pos: pos};

					// Compute endpoint from last segment's end point
					var lastExpr = resolved.exprs[resolved.exprs.length - 1];
					var endpointExpr:Expr = switch lastExpr.expr {
						case ENew(_, args) if (args.length >= 2): args[1];
						default: macro new bh.base.FPoint(0, 0);
					};

					// Generate cached path field for lazy initialization
					var cacheFieldName = "_cachedPath_" + pathName;
					factoryFields.push(makeField(cacheFieldName,
						FVar(macro :bh.paths.MultiAnimPaths.Path, macro null),
						[], pos));

					var arrExpr:Expr = {expr: EArrayDecl(rangedExprs), pos: pos};
					var cacheIdent = cacheFieldName;
					factoryFields.push(makeMethod("getPath_" + pathName, [
						macro {
							if (normalization != null) {
								// Dynamic transform requested — build fresh path and apply transform
								var basePath = bh.paths.MultiAnimPaths.Path.fromPrecomputed(
									$arrExpr, $v{totalLength}, $cpNamesExpr, $cpRatesExpr, $endpointExpr
								);
								return basePath.applyTransform(normalization);
							}
							// Return cached base path
							if ($i{cacheIdent} == null) {
								$i{cacheIdent} = bh.paths.MultiAnimPaths.Path.fromPrecomputed(
									$arrExpr, $v{totalLength}, $cpNamesExpr, $cpRatesExpr, $endpointExpr
								);
							}
							return $i{cacheIdent};
						}
					], [
						{name: "normalization", type: macro :Null<bh.paths.MultiAnimPaths.PathNormalization>, opt: true},
					], macro :bh.paths.MultiAnimPaths.Path, [APublic], pos));
				} else {
					// Zero-length path — use regular constructor
					var arrExpr:Expr = {expr: EArrayDecl(resolved.exprs), pos: pos};
					factoryFields.push(makeMethod("getPath_" + pathName, [
						macro {
							var basePath = new bh.paths.MultiAnimPaths.Path($arrExpr);
							if (normalization != null)
								return basePath.applyTransform(normalization);
							return basePath;
						}
					], [
						{name: "normalization", type: macro :Null<bh.paths.MultiAnimPaths.PathNormalization>, opt: true},
					], macro :bh.paths.MultiAnimPaths.Path, [APublic], pos));
				}
			} else {
				// Fallback to builder for paths with parameter references
				final nameExpr:Expr = macro $v{pathName};
				factoryFields.push(makeMethod("getPath_" + pathName, [
					macro return this.buildPath($nameExpr, normalization)
				], [
					{name: "normalization", type: macro :Null<bh.paths.MultiAnimPaths.PathNormalization>, opt: true},
				], macro :bh.paths.MultiAnimPaths.Path, [APublic], pos));
			}
		}
	}

	/** Try to resolve a ReferenceableValue to a Float at compile time. Returns null if it contains references. */
	static function tryResolveFloat(rv:ReferenceableValue):Null<Float> {
		if (rv == null) return null;
		return switch (rv) {
			case RVFloat(f): f;
			case RVInteger(i): cast(i, Float);
			case EBinop(op, e1, e2):
				var l = tryResolveFloat(e1);
				var r = tryResolveFloat(e2);
				if (l == null || r == null) null;
				else
					switch (op) {
						case OpAdd: l + r;
						case OpSub: l - r;
						case OpMul: l * r;
						case OpDiv: l / r;
						case OpMod: l % r;
						case OpIntegerDiv: Math.floor(l / r);
						default: null;
					};
			case EUnaryOp(_, e):
				var v = tryResolveFloat(e);
				if (v != null) -v else null;
			case RVParenthesis(e): tryResolveFloat(e);
			default: null;
		};
	}

	/** Try to resolve a Coordinates to (x, y) at compile time. Returns null if it contains references. */
	static function tryResolveCoordinate(coord:bh.multianim.CoordinateSystems.Coordinates):{x:Float, y:Float} {
		return switch coord {
			case ZERO: {x: 0.0, y: 0.0};
			case OFFSET(xr, yr):
				var x = tryResolveFloat(xr);
				var y = tryResolveFloat(yr);
				if (x != null && y != null) {x: x, y: y} else null;
			default: null;
		};
	}

	/** Resolve an entire path definition to pre-computed path data at compile time.
	 *  Returns null if any value cannot be resolved (contains parameter references).
	 *  Returns exprs with SinglePath.withRange() calls (pre-normalized), plus totalLength, checkpoints, and endpoint. */
	static function resolvePathToExprs(pathDef:Array<ParsedPaths>):Null<{
		exprs:Array<Expr>,
		lengths:Array<Float>,
		checkpointNames:Array<String>,
		checkpointLengths:Array<Float>
	}> {
		var exprs:Array<Expr> = [];
		var lengths:Array<Float> = [];
		var checkpointNames:Array<String> = [];
		var checkpointLengths:Array<Float> = []; // cumulative length at each checkpoint
		var px:Float = 0.0, py:Float = 0.0;
		var angle:Float = 0.0;

		for (cmd in pathDef) {
			switch cmd {
				case LineTo(endCoord, mode):
					var end = tryResolveCoordinate(endCoord);
					if (end == null) return null;
					var ex:Float, ey:Float;
					switch mode {
						case PCMAbsolute:
							ex = end.x;
							ey = end.y;
						case PCMRelative | null:
							ex = px + end.x;
							ey = py + end.y;
					}
					exprs.push(macro new bh.paths.MultiAnimPaths.SinglePath(
						new bh.base.FPoint($v{px}, $v{py}),
						new bh.base.FPoint($v{ex}, $v{ey}),
						bh.paths.MultiAnimPaths.PathType.Line
					));
					lengths.push(lineLength(px, py, ex, ey));
					angle = Math.atan2(ey - py, ex - px);
					px = ex;
					py = ey;

				case Forward(distance):
					var d = tryResolveFloat(distance);
					if (d == null) return null;
					var ex = px + d * Math.cos(angle);
					var ey = py + d * Math.sin(angle);
					exprs.push(macro new bh.paths.MultiAnimPaths.SinglePath(
						new bh.base.FPoint($v{px}, $v{py}),
						new bh.base.FPoint($v{ex}, $v{ey}),
						bh.paths.MultiAnimPaths.PathType.Line
					));
					lengths.push(lineLength(px, py, ex, ey));
					px = ex;
					py = ey;

				case TurnDegrees(angleDelta):
					var ad = tryResolveFloat(angleDelta);
					if (ad == null) return null;
					angle += ad * Math.PI / 180.0;
					// Normalize angle to [-PI, PI]
					while (angle > Math.PI) angle -= 2 * Math.PI;
					while (angle < -Math.PI) angle += 2 * Math.PI;

				case Arc(radius, angleDelta):
					var r = tryResolveFloat(radius);
					var ad = tryResolveFloat(angleDelta);
					if (r == null || ad == null) return null;
					var angleDeltaRad = ad * Math.PI / 180.0;
					var perpAngle = angle + (ad > 0 ? Math.PI / 2 : -Math.PI / 2);
					var cx = px + r * Math.cos(perpAngle);
					var cy = py + r * Math.sin(perpAngle);
					var startAngle = Math.atan2(py - cy, px - cx);
					var endAngle = startAngle + angleDeltaRad;
					var ex = cx + r * Math.cos(endAngle);
					var ey = cy + r * Math.sin(endAngle);
					exprs.push(macro new bh.paths.MultiAnimPaths.SinglePath(
						new bh.base.FPoint($v{px}, $v{py}),
						new bh.base.FPoint($v{ex}, $v{ey}),
						bh.paths.MultiAnimPaths.PathType.Arc(new bh.base.FPoint($v{cx}, $v{cy}), $v{startAngle}, $v{r}, $v{ad})
					));
					lengths.push(arcLength(r, ad));
					angle += angleDeltaRad;
					px = ex;
					py = ey;

				case Checkpoint(name):
					// Record checkpoint - don't add to exprs/lengths (will be filtered out)
					var cumulativeLength = 0.0;
					for (l in lengths) cumulativeLength += l;
					checkpointNames.push(name);
					checkpointLengths.push(cumulativeLength);

				case Bezier2To(endCoord, controlCoord, mode, smoothing):
					var end = tryResolveCoordinate(endCoord);
					var control = tryResolveCoordinate(controlCoord);
					if (end == null || control == null) return null;
					var ex:Float, ey:Float, ctrlX:Float, ctrlY:Float;
					switch mode {
						case PCMAbsolute:
							ex = end.x;
							ey = end.y;
							ctrlX = control.x;
							ctrlY = control.y;
						case PCMRelative | null:
							ex = px + end.x;
							ey = py + end.y;
							ctrlX = px + control.x;
							ctrlY = py + control.y;
					}
					var pxDist = getSmoothingDistanceCompileTime(smoothing, px, py, ctrlX, ctrlY);
					if (pxDist == null) return null;
					if (pxDist > 0) {
						var smoothX = px + pxDist * Math.cos(angle);
						var smoothY = py + pxDist * Math.sin(angle);
						exprs.push(macro new bh.paths.MultiAnimPaths.SinglePath(
							new bh.base.FPoint($v{px}, $v{py}),
							new bh.base.FPoint($v{ex}, $v{ey}),
							bh.paths.MultiAnimPaths.PathType.Bezier3(
								new bh.base.FPoint($v{smoothX}, $v{smoothY}),
								new bh.base.FPoint($v{ctrlX}, $v{ctrlY}),
								new bh.base.FPoint($v{ex}, $v{ey})
							)
						));
						lengths.push(bezier3Length(px, py, smoothX, smoothY, ctrlX, ctrlY, ex, ey));
					} else {
						exprs.push(macro new bh.paths.MultiAnimPaths.SinglePath(
							new bh.base.FPoint($v{px}, $v{py}),
							new bh.base.FPoint($v{ex}, $v{ey}),
							bh.paths.MultiAnimPaths.PathType.Bezier3(
								new bh.base.FPoint($v{px}, $v{py}),
								new bh.base.FPoint($v{ctrlX}, $v{ctrlY}),
								new bh.base.FPoint($v{ex}, $v{ey})
							)
						));
						lengths.push(bezier3Length(px, py, px, py, ctrlX, ctrlY, ex, ey));
					}
					angle = Math.atan2(ey - ctrlY, ex - ctrlX);
					px = ex;
					py = ey;

				case Bezier3To(endCoord, control1Coord, control2Coord, mode, smoothing):
					var end = tryResolveCoordinate(endCoord);
					var c1 = tryResolveCoordinate(control1Coord);
					var c2 = tryResolveCoordinate(control2Coord);
					if (end == null || c1 == null || c2 == null) return null;
					var ex:Float, ey:Float, c1x:Float, c1y:Float, c2x:Float, c2y:Float;
					switch mode {
						case PCMAbsolute:
							ex = end.x;
							ey = end.y;
							c1x = c1.x;
							c1y = c1.y;
							c2x = c2.x;
							c2y = c2.y;
						case PCMRelative | null:
							ex = px + end.x;
							ey = py + end.y;
							c1x = px + c1.x;
							c1y = py + c1.y;
							c2x = px + c2.x;
							c2y = py + c2.y;
					}
					var pxDist = getSmoothingDistanceCompileTime(smoothing, px, py, c1x, c1y);
					if (pxDist == null) return null;
					if (pxDist > 0) {
						var smoothX = px + pxDist * Math.cos(angle);
						var smoothY = py + pxDist * Math.sin(angle);
						exprs.push(macro new bh.paths.MultiAnimPaths.SinglePath(
							new bh.base.FPoint($v{px}, $v{py}),
							new bh.base.FPoint($v{ex}, $v{ey}),
							bh.paths.MultiAnimPaths.PathType.Bezier4(
								new bh.base.FPoint($v{smoothX}, $v{smoothY}),
								new bh.base.FPoint($v{c1x}, $v{c1y}),
								new bh.base.FPoint($v{c2x}, $v{c2y}),
								new bh.base.FPoint($v{ex}, $v{ey})
							)
						));
						lengths.push(bezier4Length(px, py, smoothX, smoothY, c1x, c1y, c2x, c2y, ex, ey));
					} else {
						exprs.push(macro new bh.paths.MultiAnimPaths.SinglePath(
							new bh.base.FPoint($v{px}, $v{py}),
							new bh.base.FPoint($v{ex}, $v{ey}),
							bh.paths.MultiAnimPaths.PathType.Bezier4(
								new bh.base.FPoint($v{px}, $v{py}),
								new bh.base.FPoint($v{c1x}, $v{c1y}),
								new bh.base.FPoint($v{c2x}, $v{c2y}),
								new bh.base.FPoint($v{ex}, $v{ey})
							)
						));
						lengths.push(bezier4Length(px, py, px, py, c1x, c1y, c2x, c2y, ex, ey));
					}
					angle = Math.atan2(ey - c2y, ex - c2x);
					px = ex;
					py = ey;

				case Close:
					// Close back to start of first segment
					var closeX:Float = 0.0;
					var closeY:Float = 0.0;
					// We can't easily get the start of first segment from exprs at compile time;
					// fall back to builder
					return null;

				case MoveTo(target, mode):
					var t = tryResolveCoordinate(target);
					if (t == null) return null;
					switch mode {
						case PCMAbsolute:
							angle = Math.atan2(t.y - py, t.x - px);
							px = t.x;
							py = t.y;
						case PCMRelative | null:
							var nx = px + t.x;
							var ny = py + t.y;
							angle = Math.atan2(ny - py, nx - px);
							px = nx;
							py = ny;
					}

				case Spiral(radiusStart, radiusEnd, angleDelta):
					var rStart = tryResolveFloat(radiusStart);
					var rEnd = tryResolveFloat(radiusEnd);
					var ad = tryResolveFloat(angleDelta);
					if (rStart == null || rEnd == null || ad == null) return null;
					var angleDeltaRad = ad * Math.PI / 180.0;
					var perpAngle = angle + (ad > 0 ? Math.PI / 2 : -Math.PI / 2);
					var cx = px + rStart * Math.cos(perpAngle);
					var cy = py + rStart * Math.sin(perpAngle);
					var sa = Math.atan2(py - cy, px - cx);
					var ea = sa + angleDeltaRad;
					var ex = cx + rEnd * Math.cos(ea);
					var ey = cy + rEnd * Math.sin(ea);
					exprs.push(macro new bh.paths.MultiAnimPaths.SinglePath(
						new bh.base.FPoint($v{px}, $v{py}),
						new bh.base.FPoint($v{ex}, $v{ey}),
						bh.paths.MultiAnimPaths.PathType.Spiral(
							new bh.base.FPoint($v{cx}, $v{cy}), $v{sa}, $v{rStart}, $v{rEnd}, $v{ad}
						)
					));
					lengths.push(spiralLength(cx, cy, sa, rStart, rEnd, ad));
					angle += angleDeltaRad;
					px = ex;
					py = ey;

				case Wave(amplitude, wavelength, count):
					var amp = tryResolveFloat(amplitude);
					var wl = tryResolveFloat(wavelength);
					var cnt = tryResolveFloat(count);
					if (amp == null || wl == null || cnt == null) return null;
					var totalLength = wl * cnt;
					var ex = px + totalLength * Math.cos(angle);
					var ey = py + totalLength * Math.sin(angle);
					final a = angle; // capture for macro
					exprs.push(macro new bh.paths.MultiAnimPaths.SinglePath(
						new bh.base.FPoint($v{px}, $v{py}),
						new bh.base.FPoint($v{ex}, $v{ey}),
						bh.paths.MultiAnimPaths.PathType.Wave($v{amp}, $v{wl}, $v{cnt}, $v{a})
					));
					lengths.push(waveLength(px, py, amp, wl, cnt, a));
					px = ex;
					py = ey;
			}
		}
		return if (exprs.length > 0) {exprs: exprs, lengths: lengths, checkpointNames: checkpointNames, checkpointLengths: checkpointLengths} else null;
	}

	/** Compute smoothing distance at compile time. Returns null if the smoothing value contains references. */
	static function getSmoothingDistanceCompileTime(smoothing:Null<SmoothingType>, sx:Float, sy:Float, cx:Float, cy:Float):Null<Float> {
		if (smoothing == null) {
			// Auto smoothing - 50% of distance to control point
			return Math.sqrt((sx - cx) * (sx - cx) + (sy - cy) * (sy - cy)) * 0.5;
		}
		return switch smoothing {
			case STNone: 0.0;
			case STAuto: Math.sqrt((sx - cx) * (sx - cx) + (sy - cy) * (sy - cy)) * 0.5;
			case STDistance(value): tryResolveFloat(value);
		};
	}

	/** Compute line length at compile time. */
	static inline function lineLength(sx:Float, sy:Float, ex:Float, ey:Float):Float {
		return Math.sqrt((ex - sx) * (ex - sx) + (ey - sy) * (ey - sy));
	}

	/** Compute arc length at compile time. */
	static inline function arcLength(radius:Float, angleDeltaDeg:Float):Float {
		return radius * Math.abs(angleDeltaDeg * Math.PI / 180.0);
	}

	/** Estimate bezier3 (cubic) length at compile time via sampling. */
	static function bezier3Length(sx:Float, sy:Float, c1x:Float, c1y:Float, c2x:Float, c2y:Float, ex:Float, ey:Float):Float {
		// Points: P0=start, P1=c1, P2=c2, P3=end — cubic bezier with 8 sample steps
		var length = 0.0;
		var lastX = sx, lastY = sy;
		for (i in 1...9) {
			var t = i / 8.0;
			var mt = 1.0 - t;
			var mt2 = mt * mt;
			var t2 = t * t;
			var px = mt2 * mt * sx + 3 * mt2 * t * c1x + 3 * mt * t2 * c2x + t2 * t * ex;
			var py = mt2 * mt * sy + 3 * mt2 * t * c1y + 3 * mt * t2 * c2y + t2 * t * ey;
			length += Math.sqrt((px - lastX) * (px - lastX) + (py - lastY) * (py - lastY));
			lastX = px;
			lastY = py;
		}
		return length;
	}

	/** Estimate bezier4 (quartic) length at compile time via sampling. */
	static function bezier4Length(sx:Float, sy:Float, c1x:Float, c1y:Float, c2x:Float, c2y:Float, c3x:Float, c3y:Float, ex:Float, ey:Float):Float {
		var length = 0.0;
		var lastX = sx, lastY = sy;
		for (i in 1...13) {
			var t = i / 12.0;
			var mt = 1.0 - t;
			var mt2 = mt * mt;
			var mt3 = mt2 * mt;
			var mt4 = mt3 * mt;
			var t2 = t * t;
			var t3 = t2 * t;
			var t4 = t3 * t;
			var px = mt4 * sx + 4 * mt3 * t * c1x + 6 * mt2 * t2 * c2x + 4 * mt * t3 * c3x + t4 * ex;
			var py = mt4 * sy + 4 * mt3 * t * c1y + 6 * mt2 * t2 * c2y + 4 * mt * t3 * c3y + t4 * ey;
			length += Math.sqrt((px - lastX) * (px - lastX) + (py - lastY) * (py - lastY));
			lastX = px;
			lastY = py;
		}
		return length;
	}

	/** Estimate spiral length at compile time via sampling. */
	static function spiralLength(cx:Float, cy:Float, startAngle:Float, rStart:Float, rEnd:Float, angleDeltaDeg:Float):Float {
		var angleDeltaRad = angleDeltaDeg * Math.PI / 180.0;
		var sx = cx + rStart * Math.cos(startAngle);
		var sy = cy + rStart * Math.sin(startAngle);
		var length = 0.0;
		var lastX = sx, lastY = sy;
		for (i in 1...17) {
			var rate = i / 16.0;
			var currentAngle = startAngle + angleDeltaRad * rate;
			var r = rStart + (rEnd - rStart) * rate;
			var px = cx + r * Math.cos(currentAngle);
			var py = cy + r * Math.sin(currentAngle);
			length += Math.sqrt((px - lastX) * (px - lastX) + (py - lastY) * (py - lastY));
			lastX = px;
			lastY = py;
		}
		return length;
	}

	/** Estimate wave length at compile time via sampling. */
	static function waveLength(sx:Float, sy:Float, amp:Float, wl:Float, cnt:Float, dirAngle:Float):Float {
		var totalLen = wl * cnt;
		var steps = Std.int(Math.max(16, Math.ceil(cnt * 8)));
		var cosD = Math.cos(dirAngle);
		var sinD = Math.sin(dirAngle);
		var length = 0.0;
		var lastX = sx, lastY = sy;
		for (i in 1...steps + 1) {
			var rate = i / steps;
			var forward = rate * totalLen;
			var phase = rate * cnt * 2 * Math.PI;
			var lateral = amp * Math.sin(phase);
			var px = sx + forward * cosD - lateral * sinD;
			var py = sy + forward * sinD + lateral * cosD;
			length += Math.sqrt((px - lastX) * (px - lastX) + (py - lastY) * (py - lastY));
			lastX = px;
			lastY = py;
		}
		return length;
	}

	static function generateAnimatedPathFactoryMethod(name:String, apDef:AnimatedPathDef, factoryFields:Array<Field>, pos:Position):Void {
		final methodName = "createAnimatedPath_" + sanitizeIdentifier(name);

		// Try to generate inline code
		var bodyExprs:Array<Expr> = [];

		// 1. Get path - call our own getPath_<name>() inline method
		final pathMethodName = "getPath_" + sanitizeIdentifier(apDef.pathName);
		bodyExprs.push(macro var path = $i{pathMethodName}(normalization));

		// 2. Determine mode
		var modeExpr:Expr = null;
		switch (apDef.mode) {
			case APTime | null if (apDef.duration != null):
				var durFloat = tryResolveFloat(apDef.duration);
				if (durFloat != null) {
					modeExpr = macro bh.paths.AnimatedPath.AnimatedPathMode.Time($v{durFloat});
				} else {
					var durExpr = rvToExpr(apDef.duration);
					modeExpr = macro bh.paths.AnimatedPath.AnimatedPathMode.Time($durExpr);
				}
			case APDistance | null if (apDef.speed != null):
				var spdFloat = tryResolveFloat(apDef.speed);
				if (spdFloat != null) {
					modeExpr = macro bh.paths.AnimatedPath.AnimatedPathMode.Distance($v{spdFloat});
				} else {
					var spdExpr = rvToExpr(apDef.speed);
					modeExpr = macro bh.paths.AnimatedPath.AnimatedPathMode.Distance($spdExpr);
				}
			default:
				// Fall back to builder
				final nameExpr:Expr = macro $v{name};
				factoryFields.push(makeMethod(methodName, [
					macro return this.buildAnimatedPath($nameExpr, normalization)
				], [
					{name: "normalization", opt: true, type: macro :Null<bh.paths.MultiAnimPaths.PathNormalization>},
				], macro :bh.paths.AnimatedPath, [APublic], pos));
				return;
		}

		bodyExprs.push(macro var ap = new bh.paths.AnimatedPath(path, $modeExpr));
		if (apDef.loop) bodyExprs.push(macro ap.loop = true);
		if (apDef.pingPong) bodyExprs.push(macro ap.pingPong = true);

		// 3. Add curve segments
		for (ca in apDef.curveAssignments) {
			// Resolve rate
			var rateExpr:Expr;
			switch ca.at {
				case Rate(r):
					rateExpr = rvToExpr(r);
				case Checkpoint(cpName):
					final cpNameStr:String = cpName;
					rateExpr = macro path.getCheckpoint($v{cpNameStr});
			}

			// Get curve: inline easing or named curve reference
			var curveExpr:Expr;
			if (ca.inlineEasing != null) {
				// Create a Curve from inline easing type
				var easingExpr = easingTypeToExpr(ca.inlineEasing);
				curveExpr = macro new bh.paths.Curve(null, $easingExpr, null);
			} else if (ca.curveName != null) {
				var easing = MacroManimParser.tryMatchEasingName(ca.curveName);
				if (easing != null) {
					var easingExpr = easingTypeToExpr(easing);
					curveExpr = macro new bh.paths.Curve(null, $easingExpr, null);
				} else {
					final curveMethodName = "getCurve_" + sanitizeIdentifier(ca.curveName);
					curveExpr = macro $i{curveMethodName}();
				}
			} else {
				continue;
			}

			// Determine slot
			var slotExpr:Expr = switch ca.slot {
				case APSpeed: macro bh.paths.AnimatedPath.CurveSlot.Speed;
				case APScale: macro bh.paths.AnimatedPath.CurveSlot.Scale;
				case APAlpha: macro bh.paths.AnimatedPath.CurveSlot.Alpha;
				case APRotation: macro bh.paths.AnimatedPath.CurveSlot.Rotation;
				case APProgress: macro bh.paths.AnimatedPath.CurveSlot.Progress;
				case APColor(_, _): null;
				case APCustom(customName):
					null; // handled below
			};

			switch ca.slot {
				case APCustom(customName):
					final cn:String = customName;
					bodyExprs.push(macro ap.addCustomCurveSegment($v{cn}, $rateExpr, $curveExpr));
				case APColor(startColor, endColor):
					var scExpr = rvToExpr(startColor);
					var ecExpr = rvToExpr(endColor);
					bodyExprs.push(macro ap.addColorCurveSegment($rateExpr, $curveExpr, Std.int($scExpr), Std.int($ecExpr)));
				default:
					bodyExprs.push(macro ap.addCurveSegment($slotExpr, $rateExpr, $curveExpr));
			}
		}

		// 4. Add events
		for (ev in apDef.events) {
			var rateExpr:Expr;
			switch ev.at {
				case Rate(r):
					rateExpr = rvToExpr(r);
				case Checkpoint(cpName):
					final cpNameStr:String = cpName;
					rateExpr = macro path.getCheckpoint($v{cpNameStr});
			}
			final evNameStr:String = ev.eventName;
			bodyExprs.push(macro ap.addEvent($rateExpr, $v{evNameStr}));
		}

		bodyExprs.push(macro return ap);

		factoryFields.push(makeMethod(methodName, bodyExprs, [
			{name: "normalization", opt: true, type: macro :Null<bh.paths.MultiAnimPaths.PathNormalization>},
		], macro :bh.paths.AnimatedPath, [APublic], pos));
	}

	static function generateCurvesFactoryMethods(curvesDef:CurvesDef, factoryFields:Array<Field>, pos:Position):Void {
		for (curveName => curveDef in curvesDef) {
			final methodName = "getCurve_" + sanitizeIdentifier(curveName);

			// Generate an inline ICurve implementation with all math baked in (no state, no allocations)
			var getValueBody = generateInlineCurveBody(curveDef, pos);

			// Cached curve field for lazy initialization
			var cacheFieldName = "_cachedCurve_" + sanitizeIdentifier(curveName);
			factoryFields.push(makeField(cacheFieldName,
				FVar(macro :bh.paths.Curve.ICurve, macro null),
				[], pos));

			var cacheIdent = cacheFieldName;
			factoryFields.push(makeMethod(methodName, [
				macro {
					if ($i{cacheIdent} == null)
						$i{cacheIdent} = new bh.paths.InlineCurve(function(t:Float):Float { $getValueBody; });
					return $i{cacheIdent};
				}
			], [], macro :bh.paths.Curve.ICurve, [APublic], pos));
		}
	}

	/** Generate the body of an inline getValue function with all curve math baked in. */
	static function generateInlineCurveBody(curveDef:CurveDef, pos:Position):Expr {
		if (curveDef.operation != null) {
			return generateOperationCurveBody(curveDef.operation, pos);
		}

		// Clamp t to [0, 1]
		var bodyExprs:Array<Expr> = [
			macro t = bh.base.TweenUtils.FloatTools.clamp(t, 0.0, 1.0)
		];

		if (curveDef.easing != null) {
			// Pure easing function — single call
			var easingExpr = easingTypeToExpr(curveDef.easing);
			bodyExprs.push(macro return bh.base.TweenUtils.FloatTools.applyEasing($easingExpr, t));
		} else if (curveDef.points != null && curveDef.points.length > 0) {
			var pts = curveDef.points;

			if (pts.length == 1) {
				// Single point — constant value
				var v = tryResolveFloat(pts[0].value);
				bodyExprs.push(macro return $v{v});
			} else {
				// Multiple points — generate if/else chain for each segment
				var firstTime = tryResolveFloat(pts[0].time);
				var firstValue = tryResolveFloat(pts[0].value);
				var lastTime = tryResolveFloat(pts[pts.length - 1].time);
				var lastValue = tryResolveFloat(pts[pts.length - 1].value);

				// Clamp to first point
				bodyExprs.push(macro if (t <= $v{firstTime}) return $v{firstValue});

				// Generate each segment as an if block
				for (i in 0...pts.length - 1) {
					var t0 = tryResolveFloat(pts[i].time);
					var v0 = tryResolveFloat(pts[i].value);
					var t1 = tryResolveFloat(pts[i + 1].time);
					var v1 = tryResolveFloat(pts[i + 1].value);
					var dt = t1 - t0;

					if (dt <= 0) {
						// Degenerate segment — skip
						continue;
					}

					bodyExprs.push(macro if (t <= $v{t1}) {
						var segT = (t - $v{t0}) / $v{dt};
						return bh.base.TweenUtils.FloatTools.lerp(segT, $v{v0}, $v{v1});
					});
				}

				// Final fallback (shouldn't normally reach due to clamping)
				bodyExprs.push(macro return $v{lastValue});
			}
		} else if (curveDef.segments != null && curveDef.segments.length > 0) {
			// Easing segments — generate inline evaluation
			bodyExprs.push(generateInlineSegmentsBody(curveDef.segments, pos));
		} else {
			// Identity curve
			bodyExprs.push(macro return t);
		}

		return macro $b{bodyExprs};
	}

	/** Generate an expression that evaluates a named curve at `t`. Falls back to inline easing if name matches a built-in easing. */
	static function curveGetValueExpr(name:String):Expr {
		var easing = MacroManimParser.tryMatchEasingName(name);
		if (easing != null) {
			var easingExpr = easingTypeToExpr(easing);
			return macro bh.base.TweenUtils.FloatTools.applyEasing($easingExpr, bh.base.TweenUtils.FloatTools.clamp(t, 0.0, 1.0));
		}
		var methodName = "getCurve_" + sanitizeIdentifier(name);
		return macro $i{methodName}().getValue(t);
	}

	/** Generate inline code for curve operations (multiply, compose, invert, scale). */
	static function generateOperationCurveBody(op:CurveOperation, pos:Position):Expr {
		switch (op) {
			case Multiply(names):
				var expr:Expr = null;
				for (name in names) {
					var call = curveGetValueExpr(name);
					expr = if (expr == null) call else macro $expr * $call;
				}
				return macro return $expr;
			case Compose(outerName, innerName):
				// outer(inner(t)) — inner evaluates at t, outer evaluates at inner's result
				var innerExpr = curveGetValueExpr(innerName);
				var outerEasing = MacroManimParser.tryMatchEasingName(outerName);
				if (outerEasing != null) {
					var easingExpr = easingTypeToExpr(outerEasing);
					return macro return bh.base.TweenUtils.FloatTools.applyEasing($easingExpr, bh.base.TweenUtils.FloatTools.clamp($innerExpr, 0.0, 1.0));
				}
				var outerMethod = "getCurve_" + sanitizeIdentifier(outerName);
				return macro return $i{outerMethod}().getValue($innerExpr);
			case Invert(curveName):
				var call = curveGetValueExpr(curveName);
				return macro return 1.0 - $call;
			case Scale(curveName, factor):
				var call = curveGetValueExpr(curveName);
				var factorVal = tryResolveFloat(factor);
				return macro return $call * $v{factorVal};
		}
	}

	/** Generate inline code for evaluating easing segments (weighted blend with gap interpolation). */
	static function generateInlineSegmentsBody(segments:Array<CurveSegmentDef>, pos:Position):Expr {
		var exprs:Array<Expr> = [];

		exprs.push(macro var totalWeight:Float = 0.0);
		exprs.push(macro var weightedSum:Float = 0.0);
		exprs.push(macro var leftEnd:Float = -1e30);
		exprs.push(macro var leftValue:Float = 0.0);
		exprs.push(macro var rightStart:Float = 1e30);
		exprs.push(macro var rightValue:Float = 0.0);

		// Unroll each segment as an if block
		for (s in segments) {
			var ts = tryResolveFloat(s.timeStart);
			var te = tryResolveFloat(s.timeEnd);
			var vs = tryResolveFloat(s.valueStart);
			var ve = tryResolveFloat(s.valueEnd);
			var easExpr = easingTypeToExpr(s.easing);

			exprs.push(macro {
				if (t >= $v{ts} && t < $v{te}) {
					var segDuration = $v{te} - $v{ts};
					var localT = if (segDuration <= 0.0) 0.0 else (t - $v{ts}) / segDuration;
					var easedT = bh.base.TweenUtils.FloatTools.applyEasing($easExpr, localT);
					var value = bh.base.TweenUtils.FloatTools.lerp(easedT, $v{vs}, $v{ve});
					var halfDur = segDuration * 0.5;
					var weight = if (halfDur <= 0.0) 1.0 else Math.max(Math.min((t - $v{ts}) / halfDur, ($v{te} - t) / halfDur), 1e-6);
					totalWeight += weight;
					weightedSum += weight * value;
				} else if ($v{te} <= t && $v{te} > leftEnd) {
					leftEnd = $v{te};
					leftValue = $v{ve};
				} else if ($v{ts} > t && $v{ts} < rightStart) {
					rightStart = $v{ts};
					rightValue = $v{vs};
				}
			});
		}

		exprs.push(macro if (totalWeight > 0.0) return weightedSum / totalWeight);
		exprs.push(macro if (leftEnd == t) return leftValue);
		exprs.push(macro {
			var hasLeft = leftEnd != -1e30;
			var hasRight = rightStart != 1e30;
			if (hasLeft && hasRight) {
				var gapT = (t - leftEnd) / (rightStart - leftEnd);
				return bh.base.TweenUtils.FloatTools.lerp(gapT, leftValue, rightValue);
			}
		});
		exprs.push(macro if (leftEnd != -1e30) return leftValue);
		exprs.push(macro if (rightStart != 1e30) return rightValue);
		exprs.push(macro return t);

		return macro $b{exprs};
	}

	static function easingTypeToExpr(easing:EasingType):Expr {
		return switch easing {
			case Linear: macro bh.multianim.MultiAnimParser.EasingType.Linear;
			case EaseInQuad: macro bh.multianim.MultiAnimParser.EasingType.EaseInQuad;
			case EaseOutQuad: macro bh.multianim.MultiAnimParser.EasingType.EaseOutQuad;
			case EaseInOutQuad: macro bh.multianim.MultiAnimParser.EasingType.EaseInOutQuad;
			case EaseInCubic: macro bh.multianim.MultiAnimParser.EasingType.EaseInCubic;
			case EaseOutCubic: macro bh.multianim.MultiAnimParser.EasingType.EaseOutCubic;
			case EaseInOutCubic: macro bh.multianim.MultiAnimParser.EasingType.EaseInOutCubic;
			case EaseInBack: macro bh.multianim.MultiAnimParser.EasingType.EaseInBack;
			case EaseOutBack: macro bh.multianim.MultiAnimParser.EasingType.EaseOutBack;
			case EaseInOutBack: macro bh.multianim.MultiAnimParser.EasingType.EaseInOutBack;
			case EaseOutBounce: macro bh.multianim.MultiAnimParser.EasingType.EaseOutBounce;
			case EaseOutElastic: macro bh.multianim.MultiAnimParser.EasingType.EaseOutElastic;
			case CubicBezier(x1, y1, x2, y2):
				macro bh.multianim.MultiAnimParser.EasingType.CubicBezier($v{x1}, $v{y1}, $v{x2}, $v{y2});
		};
	}

	static function transitionDirToExpr(dir:TransitionDirection):Expr {
		return switch dir {
			case TDLeft: macro bh.multianim.MultiAnimParser.TransitionDirection.TDLeft;
			case TDRight: macro bh.multianim.MultiAnimParser.TransitionDirection.TDRight;
			case TDUp: macro bh.multianim.MultiAnimParser.TransitionDirection.TDUp;
			case TDDown: macro bh.multianim.MultiAnimParser.TransitionDirection.TDDown;
		};
	}

	static function transitionTypeToExpr(tt:TransitionType):Expr {
		return switch tt {
			case TransNone:
				macro bh.multianim.MultiAnimParser.TransitionType.TransNone;
			case TransFade(duration, easing):
				final easingExpr = easing != null ? easingTypeToExpr(easing) : macro null;
				macro bh.multianim.MultiAnimParser.TransitionType.TransFade($v{duration}, $easingExpr);
			case TransCrossfade(duration, easing):
				final easingExpr = easing != null ? easingTypeToExpr(easing) : macro null;
				macro bh.multianim.MultiAnimParser.TransitionType.TransCrossfade($v{duration}, $easingExpr);
			case TransFlipX(duration, easing):
				final easingExpr = easing != null ? easingTypeToExpr(easing) : macro null;
				macro bh.multianim.MultiAnimParser.TransitionType.TransFlipX($v{duration}, $easingExpr);
			case TransFlipY(duration, easing):
				final easingExpr = easing != null ? easingTypeToExpr(easing) : macro null;
				macro bh.multianim.MultiAnimParser.TransitionType.TransFlipY($v{duration}, $easingExpr);
			case TransSlide(dir, duration, distance, easing):
				final dirExpr = transitionDirToExpr(dir);
				final distExpr:Expr = if (distance != null) { final d:Float = distance; macro $v{d}; } else macro null;
				final easingExpr = easing != null ? easingTypeToExpr(easing) : macro null;
				macro bh.multianim.MultiAnimParser.TransitionType.TransSlide($dirExpr, $v{duration}, $distExpr, $easingExpr);
		};
	}

	/** Generate constructor expression that initializes _transHelper with the transition map. */
	static function generateTransitionHelperInit(pos:Position):Expr {
		final mapExprs:Array<Expr> = [macro final _tm = new Map<String, bh.multianim.MultiAnimParser.TransitionType>()];
		for (paramName => transType in currentTransitions) {
			final keyExpr:Expr = macro $v{paramName};
			final valExpr = transitionTypeToExpr(transType);
			mapExprs.push(macro _tm.set($keyExpr, $valExpr));
		}
		mapExprs.push(macro this._transHelper = new bh.multianim.CodegenTransitionHelper(_tm));
		return macro $b{mapExprs};
	}

	/** Sanitize a name for use as a Haxe identifier (strip leading #, replace non-alphanumeric) */
	static function sanitizeIdentifier(name:String):String {
		if (name.charAt(0) == "#") name = name.substr(1);
		var result = new StringBuf();
		for (i in 0...name.length) {
			final c = name.charCodeAt(i);
			if ((c >= 65 && c <= 90) || (c >= 97 && c <= 122) || (c >= 48 && c <= 57) || c == 95)
				result.addChar(c);
			else
				result.addChar(95); // underscore
		}
		return result.toString();
	}

	static function makeField(name:String, kind:FieldType, access:Array<Access>, pos:Position):Field {
		return {
			name: name,
			kind: kind,
			access: access,
			pos: pos,
		};
	}

	static function makeMethod(name:String, body:Array<Expr>, args:Array<FunctionArg>, ret:Null<ComplexType>, access:Array<Access>, pos:Position):Field {
		return {
			name: name,
			kind: FFun({
				args: args,
				ret: ret,
				expr: macro $b{body},
			}),
			access: access,
			pos: pos,
		};
	}
}

private typedef CreateResult = {
	fieldType:ComplexType,
	createExprs:Array<Expr>,
	isContainer:Bool,
	exprUpdates:Array<{fieldName:String, updateExpr:Expr, paramRefs:Array<String>}>,
	?extraFields:Array<Field>,
};
#end
