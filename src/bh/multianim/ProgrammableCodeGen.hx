package bh.multianim;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import bh.multianim.MultiAnimParser;
import bh.multianim.CoordinateSystems;
import bh.multianim.MacroCompatTypes.MacroFlowLayout;
import bh.multianim.layouts.LayoutTypes.LayoutContent;
import bh.multianim.layouts.LayoutTypes.Layout;

using StringTools;

/**
 * Compile-time macro that generates typed fields for programmable classes from .manim definitions.
 *
 * Usage:
 *   @:build(bh.multianim.ProgrammableCodeGen.build("test/res/std.manim", "button"))
 *   class ButtonProgrammable {}
 *
 * The macro fills the class with:
 *   - `root: h2d.Object` — the root of the built h2d tree
 *   - `static create(access, typedParams...)` — factory with typed enum/bool params
 *   - `setXxx(v)` — typed setter per parameter (updates visibility + expressions)
 *   - `get_xxx()` — accessors for named elements
 */
class ProgrammableCodeGen {
	static var elementCounter:Int = 0;
	static var expressionUpdates:Array<{fieldName:String, updateExpr:Expr, paramRefs:Array<String>}> = [];
	static var visibilityEntries:Array<{fieldName:String, condition:Expr}> = [];
	static var namedElements:Map<String, Array<String>> = [];

	static var paramDefs:ParametersDefinitions;
	static var paramNames:Array<String> = [];

	// Maps param name -> generated enum abstract type path (for enum/bool params)
	static var paramEnumTypes:Map<String, {typePath:String, typeName:String}> = new Map();

	// Loop variable substitutions: during repeat unrolling, maps loop var name -> current iteration value
	static var loopVarSubstitutions:Map<String, Int> = new Map();

	// Runtime loop variable mappings: maps manim var name -> runtime Haxe identifier name (for runtime iterators)
	static var runtimeLoopVars:Map<String, String> = new Map();

	// Repeat pool entries: for param-dependent repeats, tracks which pool containers to show/hide
	static var repeatPoolEntries:Array<{containerField:String, iterIndex:Int, countParamRefs:Array<String>, countExpr:Expr}> = [];

	// All parsed nodes from the .manim file (for looking up layouts etc.)
	static var allParsedNodes:Map<String, Node> = new Map();

	// The local class info for generating return types
	static var localClassPack:Array<String> = [];
	static var localClassName:String = "";

	// Cache parsed results to avoid re-running subprocess for same file
	static var parsedCache:Map<String, Map<String, Node>> = new Map();

	public static function build(manimPath:String, programmableName:String):Array<Field> {
		// Reset state
		elementCounter = 0;
		expressionUpdates = [];
		visibilityEntries = [];
		namedElements = [];
		paramDefs = new Map();
		paramNames = [];
		paramEnumTypes = new Map();
		loopVarSubstitutions = new Map();
		runtimeLoopVars = new Map();
		repeatPoolEntries = [];
		allParsedNodes = new Map();

		// Parse .manim file via subprocess (classes with @:autoBuild can't work in macro context)
		final nodes = parseViaSubprocess(manimPath);
		if (nodes == null)
			return null;
		allParsedNodes = nodes;

		// Find the programmable node
		final node = nodes.get(programmableName);
		if (node == null) {
			Context.fatalError('ProgrammableCodeGen: programmable "$programmableName" not found in "$manimPath"', Context.currentPos());
			return null;
		}

		switch (node.type) {
			case PROGRAMMABLE(isTileGroup, parameters):
				paramDefs = parameters;
				for (kv in parameters.keyValueIterator()) {
					paramNames.push(kv.key);
				}
			default:
				Context.fatalError('ProgrammableCodeGen: "$programmableName" is not a programmable', Context.currentPos());
				return null;
		}

		// Get the local class info for defining companion types and return types
		final localClass = Context.getLocalClass();
		localClassPack = if (localClass != null) localClass.get().pack else [];
		localClassName = if (localClass != null) localClass.get().name else "";
		final classModule = if (localClass != null) localClass.get().module else "";

		// Classify params for typed API generation
		classifyParamTypes();

		return generateFields(node);
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

		final nodes:Map<String, Node> = try {
			MacroManimParser.parseFile(content, manimPath);
		} catch (e:Dynamic) {
			Context.fatalError('ProgrammableCodeGen: parse error in "$manimPath": $e', Context.currentPos());
			return null;
		};

		// Cache for reuse
		parsedCache.set(manimPath, nodes);
		return nodes;
	}

	// ==================== Field Generation ====================

	static function generateFields(rootNode:Node):Array<Field> {
		final fields:Array<Field> = [];
		final pos = Context.currentPos();

		// 1. Root field
		fields.push(makeField("root", FVar(macro :h2d.Object, null), [APublic], pos));

		// 1b. Static inline enum constants (e.g. Hover = 0, Pressed = 1, Normal = 2)
		generateEnumConstants(fields, pos);

		// 2. Parameter fields
		for (name in paramNames) {
			final def = paramDefs.get(name);
			final fieldType = paramFieldType(def.type);
			fields.push(makeField("_" + name, FVar(fieldType, null), [APrivate], pos));
		}

		// 3. Element fields + constructor body
		final constructorExprs:Array<Expr> = [];
		constructorExprs.push(macro this.root = new h2d.Object());

		for (name in paramNames) {
			final paramField = "_" + name;
			constructorExprs.push(macro $p{["this", paramField]} = $i{paramField});
		}

		// Process children
		if (rootNode.children != null)
			processChildren(rootNode.children, "root", fields, constructorExprs, null, pos);

		// 4. _applyVisibility()
		final visExprs:Array<Expr> = [];
		for (entry in visibilityEntries) {
			final fieldRef = macro $p{["this", entry.fieldName]};
			visExprs.push(macro $fieldRef.visible = ${entry.condition});
		}
		// Pool-based repeat visibility: show/hide based on count param
		for (entry in repeatPoolEntries) {
			final fieldRef = macro $p{["this", entry.containerField]};
			if (entry.iterIndex == -1) {
				// 2D pool: countExpr is already a boolean (ix < countX && iy < countY)
				visExprs.push(macro $fieldRef.visible = ${entry.countExpr});
			} else {
				// 1D pool: show if iterIndex < count
				final idx = entry.iterIndex;
				final countE = entry.countExpr;
				visExprs.push(macro $fieldRef.visible = ($v{idx} < $countE));
			}
		}
		if (visExprs.length == 0)
			visExprs.push(macro {});
		fields.push(makeMethod("_applyVisibility", visExprs, [], macro :Void, [APrivate], pos));

		// 5. _updateExpressions()
		final exprUpdateExprs:Array<Expr> = [];
		for (update in expressionUpdates) {
			exprUpdateExprs.push(update.updateExpr);
		}
		if (exprUpdateExprs.length == 0)
			exprUpdateExprs.push(macro {});
		fields.push(makeMethod("_updateExpressions", exprUpdateExprs, [], macro :Void, [APrivate], pos));

		// 6. Private constructor (raw Int params, used internally by create())
		final ctorArgs:Array<FunctionArg> = [];
		ctorArgs.push({name: "access", type: macro :bh.multianim.ProgrammableBuilderAccess});
		for (name in paramNames) {
			final def = paramDefs.get(name);
			ctorArgs.push({
				name: "_" + name,
				type: paramFieldType(def.type),
				opt: def.defaultValue != null,
				value: def.defaultValue != null ? resolvedParamToExpr(def.defaultValue, def.type) : null,
			});
		}

		final ctorBody = constructorExprs.copy();
		ctorBody.push(macro this._applyVisibility());
		ctorBody.push(macro this._updateExpressions());
		fields.push(makeMethod("new", ctorBody, ctorArgs, null, [APrivate], pos));

		// 7. Static create() factory with typed params, reordered (required first, optional last)
		fields.push(generateCreateFactory(pos));

		// 8. Typed setters
		for (name in paramNames) {
			final def = paramDefs.get(name);
			final paramField = "_" + name;
			final setterExprs:Array<Expr> = [];

			// For bool params, convert Bool -> Int (true=0, false=1 matching enum index convention)
			if (paramEnumTypes.exists(name) && paramEnumTypes.get(name).typePath == "Bool") {
				setterExprs.push(macro $p{["this", paramField]} = ($i{"v"} ? 0 : 1));
			} else {
				setterExprs.push(macro $p{["this", paramField]} = $i{"v"});
			}
			setterExprs.push(macro this._applyVisibility());

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
			fields.push(makeMethod("set" + toPascalCase(name), setterExprs, [{name: "v", type: setterParamType}], macro :Void, [APublic], pos));
		}

		// 9. getRoot()
		fields.push(makeMethod("getRoot", [macro return this.root], [], macro :h2d.Object, [APublic], pos));

		// 10. Named element accessors
		for (name => elementFields in namedElements) {
			if (elementFields.length == 1) {
				final ef = elementFields[0];
				fields.push(makeMethod("get_" + name, [macro return $p{["this", ef]}], [], macro :h2d.Object, [APublic], pos));
			}
		}

		return fields;
	}

	// ==================== Node Processing ====================

	static function processChildren(children:Array<Node>, parentField:String, fields:Array<Field>, ctorExprs:Array<Expr>, siblingConditions:Array<{node:Node, fieldName:String}>, pos:Position):Void {
		var siblings:Array<{node:Node, fieldName:String}> = if (siblingConditions != null) siblingConditions else [];
		for (child in children) {
			processNode(child, parentField, fields, ctorExprs, siblings, pos);
		}
	}

	static function processNode(node:Node, parentField:String, fields:Array<Field>, ctorExprs:Array<Expr>, siblings:Array<{node:Node, fieldName:String}>, pos:Position):Void {
		// Handle REPEAT/REPEAT2D specially — they unroll or pool children
		switch (node.type) {
			case REPEAT(varName, repeatType):
				processRepeat(node, varName, repeatType, parentField, fields, ctorExprs, siblings, pos);
				return;
			case REPEAT2D(varNameX, varNameY, repeatTypeX, repeatTypeY):
				processRepeat2D(node, varNameX, varNameY, repeatTypeX, repeatTypeY, parentField, fields, ctorExprs, siblings, pos);
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

		// Position
		final posExpr = generatePositionExpr(node.pos, fieldName, pos);
		if (posExpr != null)
			ctorExprs.push(posExpr);

		// Scale
		if (node.scale != null) {
			final scaleExpr = rvToExpr(node.scale);
			final fieldRef = macro $p{["this", fieldName]};
			ctorExprs.push(macro {
				final s = $scaleExpr;
				$fieldRef.scaleX = s;
				$fieldRef.scaleY = s;
			});
		}

		// Alpha
		if (node.alpha != null) {
			final alphaExpr = rvToExpr(node.alpha);
			final fieldRef = macro $p{["this", fieldName]};
			ctorExprs.push(macro $fieldRef.alpha = $alphaExpr);
		}

		// Add to parent
		final parentRef = macro $p{["this", parentField]};
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
			default:
		}

		// Visibility
		final visCond = generateVisibilityCondition(node, siblings, fieldName, pos);
		if (visCond != null) {
			visibilityEntries.push({fieldName: fieldName, condition: visCond});
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
			default: null;
		};
	}

	/** Resolve repeat iterator info: returns {count, dx, dy, rangeStart, rangeStep} or null if param-dependent */
	static function resolveRepeatInfo(repeatType:RepeatType):{staticCount:Null<Int>, dx:Int, dy:Int, rangeStart:Int, rangeStep:Int, countRV:Null<ReferenceableValue>} {
		return switch (repeatType) {
			case GridIterator(dirX, dirY, repeats):
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
		final posExpr = generatePositionExpr(node.pos, containerName, pos);
		if (posExpr != null)
			ctorExprs.push(posExpr);

		// Add to parent
		final parentRef = macro $p{["this", parentField]};
		ctorExprs.push(macro $parentRef.addChild($p{["this", containerName]}));

		// Visibility for the container itself
		final visCond = generateVisibilityCondition(node, siblings, containerName, pos);
		if (visCond != null)
			visibilityEntries.push({fieldName: containerName, condition: visCond});
		siblings.push({node: node, fieldName: containerName});

		if (info.staticCount != null) {
			// Static unroll: generate children N times with loop var substituted
			unrollRepeatChildren(node, varName, info.staticCount, info.dx, info.dy, info.rangeStart, info.rangeStep, containerName, fields, ctorExprs, pos);
		} else {
			// Param-dependent: determine max from param default, pre-allocate pool
			final countParamRefs = collectParamRefs(info.countRV);
			final maxCount = resolveMaxCount(info.countRV);
			poolRepeatChildren(node, varName, maxCount, info.dx, info.dy, info.rangeStart, info.rangeStep, containerName, fields, ctorExprs, countParamRefs, info.countRV, repeatType, pos);
		}
	}

	/** Resolve max pool size from a param-dependent count expression */
	static function resolveMaxCount(countRV:ReferenceableValue):Int {
		if (countRV == null) return 10;
		switch (countRV) {
			case RVReference(ref):
				// Use the param's default value as the max
				final def = paramDefs.get(ref);
				if (def != null && def.defaultValue != null) {
					return switch (def.defaultValue) {
						case Value(v): v;
						case Index(idx, _): idx;
						default: 10;
					};
				}
			default:
		}
		return 10;
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

	/** Pool-based repeat: pre-allocate maxCount iteration containers, show/hide based on count param */
	static function poolRepeatChildren(node:Node, varName:String, maxCount:Int, dx:Int, dy:Int, rangeStart:Int, rangeStep:Int, containerField:String, fields:Array<Field>, ctorExprs:Array<Expr>, countParamRefs:Array<String>, countRV:ReferenceableValue, repeatType:RepeatType, pos:Position):Void {
		if (node.children == null) return;

		// Generate the count expression: for GridIterator it's the count directly, for RangeIterator it needs calculation
		final countExpr:Expr = switch (repeatType) {
			case RangeIterator(start, end, step):
				final endExpr = rvToExpr(end);
				final startExpr = rvToExpr(start);
				final stepExpr = rvToExpr(step);
				macro Math.ceil(($endExpr - $startExpr) / $stepExpr);
			case GridIterator(_, _, repeats):
				rvToExpr(repeats);
			default:
				rvToExpr(countRV);
		};

		for (i in 0...maxCount) {
			final resolvedIndex = rangeStart + i * rangeStep;
			loopVarSubstitutions.set(varName, resolvedIndex);

			// Create an iteration container
			final iterContainerName = "_e" + (elementCounter++);
			fields.push(makeField(iterContainerName, FVar(macro :h2d.Object, null), [APrivate], pos));
			ctorExprs.push(macro $p{["this", iterContainerName]} = new h2d.Object());

			// Grid offset
			if (dx != 0 || dy != 0) {
				final offsetX:Float = dx * i;
				final offsetY:Float = dy * i;
				ctorExprs.push(macro $p{["this", iterContainerName]}.setPosition($v{offsetX}, $v{offsetY}));
			}

			ctorExprs.push(macro $p{["this", containerField]}.addChild($p{["this", iterContainerName]}));

			// Add visibility entry: show only if i < count
			final iterIdx = i;
			repeatPoolEntries.push({
				containerField: iterContainerName,
				iterIndex: iterIdx,
				countParamRefs: countParamRefs,
				countExpr: countExpr,
			});

			// Process children into the iteration container
			processChildren(node.children, iterContainerName, fields, ctorExprs, [], pos);

			loopVarSubstitutions.remove(varName);
		}
	}

	/** Process LayoutIterator: resolve layout points at compile time from parsed AST */
	static function processLayoutRepeat(node:Node, varName:String, layoutName:String, parentField:String, fields:Array<Field>, ctorExprs:Array<Expr>,
			siblings:Array<{node:Node, fieldName:String}>, pos:Position):Void {
		// Look up the #defaultLayout node from allParsedNodes
		final layoutNode = allParsedNodes.get("#defaultLayout");
		if (layoutNode == null) {
			Context.warning('ProgrammableCodeGen: no relativeLayouts found for layout "$layoutName", using fallback', Context.currentPos());
			processRepeatFallback(node, parentField, fields, ctorExprs, siblings, pos);
			return;
		}

		// Extract layouts definition
		final layoutsDef = switch (layoutNode.type) {
			case RELATIVE_LAYOUTS(ld): ld;
			default:
				Context.warning('ProgrammableCodeGen: unexpected layout node type', Context.currentPos());
				processRepeatFallback(node, parentField, fields, ctorExprs, siblings, pos);
				return;
		};

		final layout = layoutsDef.get(layoutName);
		if (layout == null) {
			Context.warning('ProgrammableCodeGen: layout "$layoutName" not found', Context.currentPos());
			processRepeatFallback(node, parentField, fields, ctorExprs, siblings, pos);
			return;
		}

		// Create the repeat container
		final containerName = "_e" + (elementCounter++);
		fields.push(makeField(containerName, FVar(macro :h2d.Object, null), [APrivate], pos));
		ctorExprs.push(macro $p{["this", containerName]} = new h2d.Object());

		final posExpr = generatePositionExpr(node.pos, containerName, pos);
		if (posExpr != null)
			ctorExprs.push(posExpr);

		final parentRef = macro $p{["this", parentField]};
		ctorExprs.push(macro $parentRef.addChild($p{["this", containerName]}));

		final visCond = generateVisibilityCondition(node, siblings, containerName, pos);
		if (visCond != null)
			visibilityEntries.push({fieldName: containerName, condition: visCond});
		siblings.push({node: node, fieldName: containerName});

		// Resolve layout points and unroll
		switch (layout.type) {
			case List(list):
				final offsetX:Float = layout.offset != null ? layout.offset.x : 0;
				final offsetY:Float = layout.offset != null ? layout.offset.y : 0;
				for (i in 0...list.length) {
					loopVarSubstitutions.set(varName, i);
					final pt = resolveLayoutPoint(list[i], layout, i);
					if (pt != null) {
						final px:Float = pt.x + offsetX;
						final py:Float = pt.y + offsetY;
						if (px != 0 || py != 0) {
							final iterContainerName = "_e" + (elementCounter++);
							fields.push(makeField(iterContainerName, FVar(macro :h2d.Object, null), [APrivate], pos));
							ctorExprs.push(macro $p{["this", iterContainerName]} = new h2d.Object());
							ctorExprs.push(macro $p{["this", iterContainerName]}.setPosition($v{px}, $v{py}));
							ctorExprs.push(macro $p{["this", containerName]}.addChild($p{["this", iterContainerName]}));
							processChildren(node.children, iterContainerName, fields, ctorExprs, [], pos);
						} else {
							processChildren(node.children, containerName, fields, ctorExprs, [], pos);
						}
					} else {
						processChildren(node.children, containerName, fields, ctorExprs, [], pos);
					}
					loopVarSubstitutions.remove(varName);
				}

			case Single(content):
				loopVarSubstitutions.set(varName, 0);
				final offsetX:Float = layout.offset != null ? layout.offset.x : 0;
				final offsetY:Float = layout.offset != null ? layout.offset.y : 0;
				final pt = resolveLayoutPoint(content, layout, 0);
				if (pt != null) {
					final px:Float = pt.x + offsetX;
					final py:Float = pt.y + offsetY;
					if (px != 0 || py != 0) {
						final iterContainerName = "_e" + (elementCounter++);
						fields.push(makeField(iterContainerName, FVar(macro :h2d.Object, null), [APrivate], pos));
						ctorExprs.push(macro $p{["this", iterContainerName]} = new h2d.Object());
						ctorExprs.push(macro $p{["this", iterContainerName]}.setPosition($v{px}, $v{py}));
						ctorExprs.push(macro $p{["this", containerName]}.addChild($p{["this", iterContainerName]}));
						processChildren(node.children, iterContainerName, fields, ctorExprs, [], pos);
					} else {
						processChildren(node.children, containerName, fields, ctorExprs, [], pos);
					}
				} else {
					processChildren(node.children, containerName, fields, ctorExprs, [], pos);
				}
				loopVarSubstitutions.remove(varName);

			case Sequence(seqVarName, from, to, content):
				final offsetX:Float = layout.offset != null ? layout.offset.x : 0;
				final offsetY:Float = layout.offset != null ? layout.offset.y : 0;
				for (i in from...(to + 1)) {
					loopVarSubstitutions.set(varName, i - from);
					loopVarSubstitutions.set(seqVarName, i);
					final pt = resolveLayoutPointSequence(content, layout, seqVarName, i);
					if (pt != null) {
						final px:Float = pt.x + offsetX;
						final py:Float = pt.y + offsetY;
						if (px != 0 || py != 0) {
							final iterContainerName = "_e" + (elementCounter++);
							fields.push(makeField(iterContainerName, FVar(macro :h2d.Object, null), [APrivate], pos));
							ctorExprs.push(macro $p{["this", iterContainerName]} = new h2d.Object());
							ctorExprs.push(macro $p{["this", iterContainerName]}.setPosition($v{px}, $v{py}));
							ctorExprs.push(macro $p{["this", containerName]}.addChild($p{["this", iterContainerName]}));
							processChildren(node.children, iterContainerName, fields, ctorExprs, [], pos);
						} else {
							processChildren(node.children, containerName, fields, ctorExprs, [], pos);
						}
					} else {
						processChildren(node.children, containerName, fields, ctorExprs, [], pos);
					}
					loopVarSubstitutions.remove(varName);
					loopVarSubstitutions.remove(seqVarName);
				}
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
			case SELECTED_GRID_POSITION_WITH_OFFSET(gridX, gridY, offsetX, offsetY):
				final gx = resolveRVStatic(gridX);
				final gy = resolveRVStatic(gridY);
				final ox = resolveRVStatic(offsetX);
				final oy = resolveRVStatic(offsetY);
				if (gx != null && gy != null && ox != null && oy != null && layout.grid != null) {
					{x: layout.grid.spacingX * gx + ox, y: layout.grid.spacingY * gy + oy};
				} else {
					null;
				}
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

		final posExpr = generatePositionExpr(node.pos, containerName, pos);
		if (posExpr != null)
			ctorExprs.push(posExpr);

		final parentRef = macro $p{["this", parentField]};
		ctorExprs.push(macro $parentRef.addChild($p{["this", containerName]}));

		final visCond = generateVisibilityCondition(node, siblings, containerName, pos);
		if (visCond != null)
			visibilityEntries.push({fieldName: containerName, condition: visCond});
		siblings.push({node: node, fieldName: containerName});

		final containerRef = macro $p{["this", containerName]};

		// Set up runtime loop var mapping so rvToExpr generates runtime references
		runtimeLoopVars.set(varName, "_rt_i");

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
					final _rt_tiles = access.getSheetTiles($v{sheetStr}, $filterExpr);
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
					final _rt_tiles = access.getStateAnimTiles($v{fileStr}, Std.string($animNameExpr), $selectorMapExpr);
					for (_rt_i in 0..._rt_tiles.length) {
						$loopBody;
					}
				});

			case ArrayIterator(valueVariableName, arrayName):
				final arrayField = "_" + arrayName;
				final arrayRef = macro $p{["this", arrayField]};
				ctorExprs.push(macro {
					final arr:Array<Dynamic> = $arrayRef;
					if (arr != null) {
						for (_rt_i in 0...arr.length) {
							$loopBody;
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
				// Reset tile dx/dy to match builder's TileGroup behavior
				stmts.push(macro final _rt_tile = $bitmapExpr);
				stmts.push(macro _rt_tile.dx = 0);
				stmts.push(macro _rt_tile.dy = 0);
				stmts.push(macro final _rt_bmp = new h2d.Bitmap(_rt_tile));
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

			default:
				bodyExprs.push(macro {
					final _rt_obj = new h2d.Object();
					$containerRef.addChild(_rt_obj);
				});
		}
	}

	/** Fallback for unsupported repeat iterator types — empty container */
	static function processRepeatFallback(node:Node, parentField:String, fields:Array<Field>, ctorExprs:Array<Expr>, siblings:Array<{node:Node, fieldName:String}>, pos:Position):Void {
		final fieldName = "_e" + (elementCounter++);
		fields.push(makeField(fieldName, FVar(macro :h2d.Object, null), [APrivate], pos));
		ctorExprs.push(macro $p{["this", fieldName]} = new h2d.Object());
		final parentRef = macro $p{["this", parentField]};
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

		final posExpr = generatePositionExpr(node.pos, containerName, pos);
		if (posExpr != null)
			ctorExprs.push(posExpr);

		final parentRef = macro $p{["this", parentField]};
		ctorExprs.push(macro $parentRef.addChild($p{["this", containerName]}));

		final visCond = generateVisibilityCondition(node, siblings, containerName, pos);
		if (visCond != null)
			visibilityEntries.push({fieldName: containerName, condition: visCond});
		siblings.push({node: node, fieldName: containerName});

		if (infoX.staticCount != null && infoY.staticCount != null) {
			// Both axes static: fully unroll
			unrollRepeat2DChildren(node, varNameX, varNameY, infoX, infoY, containerName, fields, ctorExprs, pos);
		} else {
			// At least one axis is param-dependent: pool
			poolRepeat2DChildren(node, varNameX, varNameY, infoX, infoY, repeatTypeX, repeatTypeY, containerName, fields, ctorExprs, pos);
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

	/** Pool-based 2D repeat: pre-allocate maxX * maxY iteration containers */
	static function poolRepeat2DChildren(node:Node, varNameX:String, varNameY:String, infoX:{staticCount:Null<Int>, dx:Int, dy:Int, rangeStart:Int, rangeStep:Int, countRV:Null<ReferenceableValue>}, infoY:{staticCount:Null<Int>, dx:Int, dy:Int, rangeStart:Int, rangeStep:Int, countRV:Null<ReferenceableValue>}, repeatTypeX:RepeatType, repeatTypeY:RepeatType, containerField:String, fields:Array<Field>, ctorExprs:Array<Expr>, pos:Position):Void {
		if (node.children == null) return;

		final maxX = infoX.staticCount != null ? infoX.staticCount : resolveMaxCount(infoX.countRV);
		final maxY = infoY.staticCount != null ? infoY.staticCount : resolveMaxCount(infoY.countRV);

		final countXExpr:Expr = if (infoX.staticCount != null) macro $v{infoX.staticCount} else switch (repeatTypeX) {
			case RangeIterator(start, end, step):
				final endExpr = rvToExpr(end);
				final startExpr = rvToExpr(start);
				final stepExpr = rvToExpr(step);
				macro Math.ceil(($endExpr - $startExpr) / $stepExpr);
			case GridIterator(_, _, repeats): rvToExpr(repeats);
			default: macro $v{maxX};
		};

		final countYExpr:Expr = if (infoY.staticCount != null) macro $v{infoY.staticCount} else switch (repeatTypeY) {
			case RangeIterator(start, end, step):
				final endExpr = rvToExpr(end);
				final startExpr = rvToExpr(start);
				final stepExpr = rvToExpr(step);
				macro Math.ceil(($endExpr - $startExpr) / $stepExpr);
			case GridIterator(_, _, repeats): rvToExpr(repeats);
			default: macro $v{maxY};
		};

		// Collect param refs for both axes
		var allCountParamRefs:Array<String> = [];
		if (infoX.countRV != null)
			for (r in collectParamRefs(infoX.countRV))
				if (!allCountParamRefs.contains(r))
					allCountParamRefs.push(r);
		if (infoY.countRV != null)
			for (r in collectParamRefs(infoY.countRV))
				if (!allCountParamRefs.contains(r))
					allCountParamRefs.push(r);

		for (iy in 0...maxY) {
			final resolvedY = infoY.rangeStart + iy * infoY.rangeStep;
			loopVarSubstitutions.set(varNameY, resolvedY);

			for (ix in 0...maxX) {
				final resolvedX = infoX.rangeStart + ix * infoX.rangeStep;
				loopVarSubstitutions.set(varNameX, resolvedX);

				final iterContainerName = "_e" + (elementCounter++);
				fields.push(makeField(iterContainerName, FVar(macro :h2d.Object, null), [APrivate], pos));
				ctorExprs.push(macro $p{["this", iterContainerName]} = new h2d.Object());

				final totalDx:Float = infoX.dx * ix + infoY.dx * iy;
				final totalDy:Float = infoX.dy * ix + infoY.dy * iy;
				if (totalDx != 0 || totalDy != 0) {
					ctorExprs.push(macro $p{["this", iterContainerName]}.setPosition($v{totalDx}, $v{totalDy}));
				}

				ctorExprs.push(macro $p{["this", containerField]}.addChild($p{["this", iterContainerName]}));

				// Visibility: show if ix < countX && iy < countY
				final ixVal = ix;
				final iyVal = iy;
				repeatPoolEntries.push({
					containerField: iterContainerName,
					iterIndex: -1, // special: use 2D check
					countParamRefs: allCountParamRefs,
					countExpr: macro($v{ixVal} < $countXExpr && $v{iyVal} < $countYExpr),
				});

				processChildren(node.children, iterContainerName, fields, ctorExprs, [], pos);

				loopVarSubstitutions.remove(varNameX);
			}
			loopVarSubstitutions.remove(varNameY);
		}
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
				generateTextCreate(node, fieldName, textDef, pos);

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

			case FLOW(maxWidth, maxHeight, minWidth, minHeight, lineHeight, colWidth, layout, paddingTop, paddingBottom, paddingLeft, paddingRight, horizontalSpacing, verticalSpacing, debug, multiline):
				generateFlowCreate(node, fieldName, maxWidth, maxHeight, minWidth, minHeight, lineHeight, colWidth, layout, paddingTop, paddingBottom, paddingLeft, paddingRight, horizontalSpacing, verticalSpacing, debug, multiline, pos);

			case INTERACTIVE(w, h, id, _debug):
				final wExpr = rvToExpr(w);
				final hExpr = rvToExpr(h);
				final idExpr = rvToExpr(id);
				{
					fieldType: macro :h2d.Object,
					createExprs: [macro $p{["this", fieldName]} = new bh.base.MAObject($wExpr, $hExpr, $idExpr)],
					isContainer: false,
					exprUpdates: [],
				};

			case PLACEHOLDER(_, _): {
					fieldType: macro :h2d.Object,
					createExprs: [macro $p{["this", fieldName]} = new h2d.Object()],
					isContainer: true,
					exprUpdates: [],
				};

			case REFERENCE(_, _, _): {
					fieldType: macro :h2d.Object,
					createExprs: [macro $p{["this", fieldName]} = new h2d.Object()],
					isContainer: false,
					exprUpdates: [],
				};

			case REPEAT(_, _) | REPEAT2D(_, _, _, _):
				// Should not be reached — processNode handles REPEAT/REPEAT2D directly
				null;

			case GRAPHICS(_) | PIXELS(_) | PARTICLES(_): {
					fieldType: macro :h2d.Object,
					createExprs: [macro $p{["this", fieldName]} = new h2d.Object()],
					isContainer: false,
					exprUpdates: [],
				};

			default: null;
		};
	}

	static function generateBitmapCreate(node:Node, fieldName:String, tileSource:TileSource, hAlign:HorizontalAlign, vAlign:VerticalAlign, pos:Position):CreateResult {
		final tileExpr = tileSourceToExpr(tileSource);
		final fieldRef = macro $p{["this", fieldName]};
		final createExprs:Array<Expr> = [];
		final alignExprs:Array<Expr> = [];

		switch (vAlign) {
			case Center: alignExprs.push(macro tile.dy = -(tile.height * 0.5));
			case Bottom: alignExprs.push(macro tile.dy = -tile.height);
			default:
		}

		switch (hAlign) {
			case Center: alignExprs.push(macro tile.dx = -(tile.width * 0.5));
			case Right: alignExprs.push(macro tile.dx = -tile.width);
			default:
		}

		if (alignExprs.length > 0) {
			final block:Array<Expr> = [macro var tile = $tileExpr];
			for (e in alignExprs)
				block.push(e);
			block.push(macro tile = tile.sub(0, 0, tile.width, tile.height, tile.dx, tile.dy));
			block.push(macro $fieldRef = new h2d.Bitmap(tile));
			createExprs.push(macro $b{block});
		} else {
			createExprs.push(macro $fieldRef = new h2d.Bitmap($tileExpr));
		}

		return {
			fieldType: macro :h2d.Bitmap,
			createExprs: createExprs,
			isContainer: false,
			exprUpdates: [],
		};
	}

	static function generateTextCreate(node:Node, fieldName:String, textDef:TextDef, pos:Position):CreateResult {
		final fieldRef = macro $p{["this", fieldName]};
		final createExprs:Array<Expr> = [];
		final exprUpdates:Array<{fieldName:String, updateExpr:Expr, paramRefs:Array<String>}> = [];

		final fontExpr = rvToExpr(textDef.fontName);
		if (textDef.isHtml) {
			createExprs.push(macro {
				final font = access.loadFont($fontExpr);
				final t = new h2d.HtmlText(font);
				t.loadFont = (name) -> access.loadFont(name);
				$fieldRef = t;
			});
		} else {
			createExprs.push(macro $fieldRef = new h2d.Text(access.loadFont($fontExpr)));
		}

		// Alignment
		switch (textDef.halign) {
			case null: createExprs.push(macro $fieldRef.textAlign = Left);
			case Right: createExprs.push(macro $fieldRef.textAlign = Right);
			case Center: createExprs.push(macro $fieldRef.textAlign = Center);
			case Left: createExprs.push(macro $fieldRef.textAlign = Left);
		}

		// maxWidth
		switch (textDef.textAlignWidth) {
			case TAWValue(value):
				createExprs.push(macro $fieldRef.maxWidth = $v{value});
			default:
		}

		// Properties
		if (textDef.letterSpacing != 0)
			createExprs.push(macro $fieldRef.letterSpacing = $v{textDef.letterSpacing});
		if (textDef.lineSpacing != 0)
			createExprs.push(macro $fieldRef.lineSpacing = $v{textDef.lineSpacing});
		if (textDef.lineBreak)
			createExprs.push(macro $fieldRef.lineBreak = true);

		if (textDef.dropShadowXY != null) {
			final dx:Float = textDef.dropShadowXY.x;
			final dy:Float = textDef.dropShadowXY.y;
			final color:Int = textDef.dropShadowColor;
			final alpha:Float = textDef.dropShadowAlpha;
			createExprs.push(macro $fieldRef.dropShadow = {dx: $v{dx}, dy: $v{dy}, color: $v{color}, alpha: $v{alpha}});
		}

		final colorExpr = rvToExpr(textDef.color);
		createExprs.push(macro $fieldRef.textColor = $colorExpr);

		final textExpr = rvToExpr(textDef.text);
		// Wrap with Std.string() to handle non-string params (e.g. uint used as text)
		final textAssign = isStringRV(textDef.text) ? macro $fieldRef.text = $textExpr : macro $fieldRef.text = Std.string($textExpr);
		createExprs.push(textAssign);

		final textParamRefs = collectParamRefs(textDef.text);
		if (textParamRefs.length > 0) {
			exprUpdates.push({
				fieldName: fieldName,
				updateExpr: textAssign,
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

		return {
			fieldType: macro :h2d.Text,
			createExprs: createExprs,
			isContainer: false,
			exprUpdates: exprUpdates,
		};
	}

	static function generateNinepatchCreate(node:Node, fieldName:String, sheet:String, tilename:String, width:ReferenceableValue, height:ReferenceableValue, pos:Position):CreateResult {
		final fieldRef = macro $p{["this", fieldName]};
		final wExpr = rvToExpr(width);
		final hExpr = rvToExpr(height);
		final exprUpdates:Array<{fieldName:String, updateExpr:Expr, paramRefs:Array<String>}> = [];

		final createExprs:Array<Expr> = [
			macro {
				final sg = access.load9Patch($v{sheet}, $v{tilename});
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

	static function generateFlowCreate(node:Node, fieldName:String, maxWidth:Null<ReferenceableValue>, maxHeight:Null<ReferenceableValue>, minWidth:Null<ReferenceableValue>, minHeight:Null<ReferenceableValue>, lineHeight:Null<ReferenceableValue>, colWidth:Null<ReferenceableValue>, layout:Null<MacroFlowLayout>, paddingTop:Null<ReferenceableValue>, paddingBottom:Null<ReferenceableValue>, paddingLeft:Null<ReferenceableValue>, paddingRight:Null<ReferenceableValue>, horizontalSpacing:Null<ReferenceableValue>, verticalSpacing:Null<ReferenceableValue>, debug:Bool, multiline:Bool, pos:Position):CreateResult {
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
		createExprs.push(macro $fieldRef.overflow = h2d.Flow.FlowOverflow.Limit);

		return {
			fieldType: macro :h2d.Flow,
			createExprs: createExprs,
			isContainer: true,
			exprUpdates: [],
		};
	}

	// ==================== Condition/Visibility ====================

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
			final paramExpr = macro $p{["this", "_" + paramName]};
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
					final fromVal:Float = from;
					result = if (fromExclusive) macro($paramExpr > $v{fromVal}) else macro($paramExpr >= $v{fromVal});
				}
				if (to != null) {
					final toVal:Float = to;
					final toCond = if (toExclusive) macro($paramExpr < $v{toVal}) else macro($paramExpr <= $v{toVal});
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
				return value == "true" ? 0 : 1;
			default:
		}
		return 0;
	}

	// ==================== Expression Translation ====================

	static function rvToExpr(rv:ReferenceableValue):Expr {
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
				} else {
					macro $p{["this", "_" + ref]};
				}
			case EBinop(op, e1, e2):
				final left = rvToExpr(e1);
				final right = rvToExpr(e2);
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
				final innerExpr = rvToExpr(inner);
				macro -($innerExpr);
			case RVParenthesis(e):
				final inner = rvToExpr(e);
				macro($inner);
			case RVTernary(condition, ifTrue, ifFalse):
				final condE = rvToExpr(condition);
				final trueE = rvToExpr(ifTrue);
				final falseE = rvToExpr(ifFalse);
				macro($condE != 0 ? $trueE : $falseE);
			case RVCallbacks(_name, defaultValue):
				rvToExpr(defaultValue);
			case RVCallbacksWithIndex(_name, _index, defaultValue):
				rvToExpr(defaultValue);
			default:
				macro 0;
		};
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
				if (paramDefs.exists(ref) && !loopVarSubstitutions.exists(ref) && !refs.contains(ref))
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
			default:
		}
	}

	// ==================== Tile Source ====================

	static function tileSourceToExpr(ts:TileSource):Expr {
		return switch (ts) {
			case TSFile(filename):
				final fnExpr = rvToExpr(filename);
				macro access.loadTileFile($fnExpr);
			case TSSheet(sheet, name):
				final sheetExpr = rvToExpr(sheet);
				final nameExpr = rvToExpr(name);
				macro access.loadTile($sheetExpr, $nameExpr);
			case TSSheetWithIndex(sheet, name, index):
				final sheetExpr = rvToExpr(sheet);
				final nameExpr = rvToExpr(name);
				final indexExpr = rvToExpr(index);
				macro access.loadTileWithIndex($sheetExpr, $nameExpr, $indexExpr);
			default:
				macro access.loadTileFile("placeholder.png");
		};
	}

	// ==================== Position ====================

	static function generatePositionExpr(coords:Coordinates, fieldName:String, pos:Position):Null<Expr> {
		if (coords == null)
			return null;
		final fieldRef = macro $p{["this", fieldName]};

		return switch (coords) {
			case ZERO: null;
			case OFFSET(x, y):
				final xExpr = rvToExpr(x);
				final yExpr = rvToExpr(y);
				macro $fieldRef.setPosition($xExpr, $yExpr);
			default: null;
		};
	}

	// ==================== Factory / Public API ====================

	/** Generate the static create() factory method with typed params, reordered so required params come first */
	static function generateCreateFactory(pos:Position):Field {
		// Partition params: required (no default) first, optional (has default) last
		final requiredParams:Array<String> = [];
		final optionalParams:Array<String> = [];
		for (name in paramNames) {
			final def = paramDefs.get(name);
			if (def.defaultValue != null)
				optionalParams.push(name);
			else
				requiredParams.push(name);
		}
		final orderedParams = requiredParams.concat(optionalParams);

		// Build factory args
		final factoryArgs:Array<FunctionArg> = [];
		factoryArgs.push({name: "access", type: macro :bh.multianim.ProgrammableBuilderAccess});

		for (name in orderedParams) {
			final def = paramDefs.get(name);
			final pubType = publicParamType(name, def.type);
			final hasDefault = def.defaultValue != null;

			factoryArgs.push({
				name: name,
				type: pubType,
				opt: hasDefault,
				value: hasDefault ? publicDefaultValue(name, def) : null,
			});
		}

		// Build the constructor call args: convert Bool params to Int, pass others directly
		final ctorCallArgs:Array<Expr> = [macro access];
		for (pName in paramNames) {
			final enumInfo = paramEnumTypes.get(pName);
			if (enumInfo != null && enumInfo.typePath == "Bool") {
				// Bool -> Int: true=0 (first index), false=1 (second index)
				ctorCallArgs.push(macro($i{pName} ? 0 : 1));
			} else {
				ctorCallArgs.push(macro $i{pName});
			}
		}

		final classType:ComplexType = TPath({pack: localClassPack, name: localClassName});
		// Build: return @:privateAccess new pkg.ClassName(args...)
		final newExpr:Expr = {
			expr: ENew({pack: localClassPack, name: localClassName}, ctorCallArgs),
			pos: pos,
		};
		final factoryBody:Array<Expr> = [macro return @:privateAccess $newExpr];

		return {
			name: "create",
			kind: FFun({
				args: factoryArgs,
				ret: classType,
				expr: macro $b{factoryBody},
			}),
			access: [APublic, AStatic],
			pos: pos,
		};
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
			// Bool param: Index(0, "true") -> true, Index(1, "false") -> false
			return switch (def.defaultValue) {
				case Index(idx, _): macro $v{idx == 0};
				case Value(val): macro $v{val == 0};
				default: macro false;
			};
		} else if (enumInfo != null) {
			// Enum param: just use the Int index directly
			return resolvedParamToExpr(def.defaultValue, def.type);
		}
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
			case PPTArray: macro :Dynamic;
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
			default:
				macro null;
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
};
#end
