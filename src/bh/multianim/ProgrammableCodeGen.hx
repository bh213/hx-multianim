package bh.multianim;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import bh.multianim.MultiAnimParser;
import bh.multianim.CoordinateSystems;
import bh.multianim.MacroCompatTypes.MacroFlowLayout;

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

		// Parse .manim file via subprocess (classes with @:autoBuild can't work in macro context)
		final nodes = parseViaSubprocess(manimPath);
		if (nodes == null)
			return null;

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

		final cwd = Sys.getCwd();
		final tmpFile = cwd + "build/.manim_ast_cache.bin";

		// Ensure build dir exists
		if (!sys.FileSystem.exists(cwd + "build"))
			sys.FileSystem.createDirectory(cwd + "build");

		// Compile to HL, then run (eval target is incompatible with heaps)
		final hlBinary = cwd + "build/.manim_serializer.hl";

		// Only recompile serializer if it doesn't exist yet
		if (!sys.FileSystem.exists(hlBinary)) {
			final args:Array<String> = [];
			final libDir = cwd + "haxe_libraries/";
			final excludeLibs = ["utest.hxml"];
			if (sys.FileSystem.exists(libDir)) {
				for (file in sys.FileSystem.readDirectory(libDir)) {
					if (StringTools.endsWith(file, ".hxml") && !excludeLibs.contains(file)) {
						args.push(libDir + file);
					}
				}
			} else {
				args.push("-lib");
				args.push("hxparse");
				args.push("-lib");
				args.push("heaps");
			}
			args.push("-cp");
			args.push(cwd + "src");
			args.push("-D");
			args.push("resourcesPath=" + cwd + "test/res");
			args.push("-main");
			args.push("bh.multianim.ProgrammableASTSerializer");
			args.push("-hl");
			args.push(hlBinary);

			final compileExit = Sys.command("haxe", args);
			if (compileExit != 0) {
				Context.fatalError('ProgrammableCodeGen: failed to compile serializer (exit code $compileExit)', Context.currentPos());
				return null;
			}
		}

		// Run the HL binary to parse the .manim file
		final runExit = Sys.command("hl", [hlBinary, manimPath, tmpFile]);
		if (runExit != 0) {
			Context.fatalError('ProgrammableCodeGen: serializer failed for "$manimPath" (exit code $runExit)', Context.currentPos());
			return null;
		}

		// Read and deserialize
		final serialized = try sys.io.File.getContent(tmpFile) catch (e:Dynamic) {
			Context.fatalError('ProgrammableCodeGen: could not read serialized AST from "$tmpFile": $e', Context.currentPos());
			return null;
		};

		final nodes:Map<String, Node> = try {
			final u = new haxe.Unserializer(serialized);
			u.unserialize();
		} catch (e:Dynamic) {
			Context.fatalError('ProgrammableCodeGen: could not deserialize AST: $e', Context.currentPos());
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

			case REPEAT(_, _) | REPEAT2D(_, _, _, _): {
					fieldType: macro :h2d.Object,
					createExprs: [macro $p{["this", fieldName]} = new h2d.Object()],
					isContainer: true,
					exprUpdates: [],
				};

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
				macro $p{["this", "_" + ref]};
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
				if (paramDefs.exists(ref) && !refs.contains(ref))
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
