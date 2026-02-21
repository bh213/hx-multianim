package bh.multianim;

import h2d.ScaleGrid;
import h2d.Tile;
import h2d.Font;
import bh.base.ResourceLoader;
import bh.base.Atlas2.IAtlas2;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.multianim.MultiAnimBuilder.SlotHandle;
import bh.multianim.MultiAnimBuilder.CallbackRequest;
import bh.multianim.MultiAnimBuilder.CallbackResult;
import bh.multianim.MultiAnimBuilder.PlaceholderValues;
import bh.multianim.MultiAnimParser.ResolvedSettings;
import bh.multianim.MultiAnimParser.TileSource;
import bh.stateanim.AnimationSM;
import bh.stateanim.AnimationSM.AnimationFrameState;

/**
 * Base class for generated programmable classes.
 * Both the parent class and companion classes are constructed with a ResourceLoader.
 * Companion classes load a MultiAnimBuilder on create() and store it in _builder.
 *
 * Usage:
 *   @:build(bh.multianim.ProgrammableCodeGen.buildAll())
 *   class MyScreen extends ProgrammableBuilder {
 *       @:manim("path.manim", "button") public var button;
 *   }
 *
 *   var screen = new MyScreen(resourceLoader);
 *   var btn = screen.button.create(params...);
 *   btn.root;  // h2d tree
 */
@:allow(bh.multianim.ProgrammableCodeGen)
class ProgrammableBuilder {
	public final resourceLoader:ResourceLoader;
	var _builder:Dynamic = null;

	public function new(resourceLoader:ResourceLoader) {
		this.resourceLoader = resourceLoader;
	}

	/** Load a tile from a sprite sheet by name.
	 *  Returns a copy so callers never mutate the cached atlas tile. */
	public function loadTile(sheet:String, name:String):Tile {
		final atlas = getSheet(sheet);
		final frame = atlas.get(name);
		if (frame == null)
			throw 'tile "$name" not found in sheet "$sheet"';
		return copyTile(frame.tile);
	}

	/** Load a tile from a sprite sheet by name and index.
	 *  Returns a copy so callers never mutate the cached atlas tile. */
	public function loadTileWithIndex(sheet:String, name:String, index:Int):Tile {
		final atlas = getSheet(sheet);
		final anim = atlas.getAnim(name);
		if (anim == null)
			throw 'tile "$name" not found in sheet "$sheet"';
		if (index < 0 || index >= anim.length)
			throw 'tile "$name" in sheet "$sheet" does not have index $index';
		return copyTile(anim[index].tile);
	}

	/** Load a tile from a file path.
	 *  Returns a copy so callers never mutate the cached tile. */
	public function loadTileFile(filename:String):Tile {
		return copyTile(resourceLoader.loadTile(filename));
	}

	/** Create an independent copy of a tile so the cached original is never mutated. */
	static inline function copyTile(t:Tile):Tile {
		return t.sub(0, 0, t.width, t.height, t.dx, t.dy);
	}

	/** Load a 9-patch ScaleGrid from a sprite sheet */
	public function load9Patch(sheet:String, name:String):ScaleGrid {
		final atlas = getSheet(sheet);
		final ninePatch = atlas.getNinePatch(name);
		if (ninePatch == null)
			throw '9-patch "$name" not found in sheet "$sheet"';
		return ninePatch;
	}

	/** Load a font by name */
	public function loadFont(name:String):Font {
		return resourceLoader.loadFont(name);
	}

	/** Get a sprite sheet (atlas) by name.
	 *  Uses builder's getOrLoadSheet when available (handles inline atlases),
	 *  otherwise falls back to resourceLoader.loadSheet2. */
	function getSheet(sheetName:String):IAtlas2 {
		if (_builder != null)
			return @:privateAccess (_builder : MultiAnimBuilder).getOrLoadSheet(sheetName);
		return resourceLoader.loadSheet2(sheetName);
	}

	/** Look up a 2D palette color by name and x,y coordinates */
	public function getPaletteColor2D(paletteName:String, x:Int, y:Int):Int {
		return @:privateAccess (_builder : MultiAnimBuilder).getPalette(paletteName).getColor2D(x, y);
	}

	/** Look up a palette color by name and index */
	public function getPaletteColorByIndex(paletteName:String, index:Int):Int {
		return @:privateAccess (_builder : MultiAnimBuilder).getPalette(paletteName).getColorByIndex(index);
	}

	/** Build a palette replace filter via the builder (for FilterPaletteReplace) */
	public function buildPaletteReplaceFilter(paletteName:String, sourceRow:Int, replacementRow:Int):h2d.filter.Filter {
		var palette = @:privateAccess (_builder : MultiAnimBuilder).getPalette(paletteName);
		return bh.base.filters.ReplacePaletteShader.createAsPaletteFilter(palette, sourceRow, replacementRow);
	}

	/** Build a sub-programmable via the builder (for STATIC_REF nodes) */
	public function buildStaticRef(name:String, parameters:Map<String, Dynamic>):BuilderResult {
		return (_builder : MultiAnimBuilder).buildWithParameters(name, parameters);
	}

	/** Build a dynamic ref via the builder (for DYNAMIC_REF nodes, always incremental) */
	public function buildDynamicRef(name:String, parameters:Map<String, Dynamic>):BuilderResult {
		return (_builder : MultiAnimBuilder).buildWithParameters(name, parameters, null, null, true);
	}

	/** Build a parameterized slot's children via the builder (for SLOT nodes with parameters in codegen).
	 *  Returns a SlotHandle with IncrementalUpdateContext for runtime setParameter() calls. */
	public function buildParameterizedSlot(programmableName:String, slotName:String,
			parentParams:Map<String, Dynamic>, container:h2d.Object):SlotHandle {
		return (_builder : MultiAnimBuilder).buildSlotContent(programmableName, slotName, parentParams, container);
	}

	/** Build a particle system via the builder (for PARTICLES nodes).
	 *  Searches the named programmable's children for a PARTICLES node. */
	public function buildParticles(programmableName:String):bh.base.Particles {
		final builder:MultiAnimBuilder = cast _builder;
		final progNode = builder.multiParserResult.nodes.get(programmableName);
		if (progNode == null)
			throw 'could not find programmable node: $programmableName';
		final particlesNode = findFirstParticlesChild(progNode);
		if (particlesNode == null)
			throw 'no particles found in programmable: $programmableName';
		return switch particlesNode.type {
			case PARTICLES(particlesDef):
				builder.createParticleFromDef(particlesDef, particlesNode.uniqueNodeName);
			default:
				throw 'unexpected node type in $programmableName';
		};
	}

	private static function findFirstParticlesChild(node:MultiAnimParser.Node):Null<MultiAnimParser.Node> {
		for (child in node.children) {
			switch child.type {
				case PARTICLES(_): return child;
				default:
					var found = findFirstParticlesChild(child);
					if (found != null) return found;
			}
		}
		return null;
	}

	/** Build a state animation from a .anim file.
	 *  Used by generated code for STATEANIM nodes. */
	public function buildStateAnim(filename:String, selectorMap:Map<String, String>, initialState:String):AnimationSM {
		final animSM = resourceLoader.createAnimSM(filename, selectorMap);
		animSM.play(initialState);
		return animSM;
	}

	/** Build an inline-constructed state animation.
	 *  Used by generated code for STATEANIM_CONSTRUCT nodes. */
	public function buildStateAnimConstruct(initialState:String, constructData:Array<{key:String, sheet:String, animName:String, fps:Float, loop:Bool, center:Bool}>):AnimationSM {
		final animSM = new AnimationSM([]);
		for (entry in constructData) {
			final loadedSheet = getSheet(entry.sheet);
			final anim = loadedSheet.getAnim(entry.animName);
			if (entry.center) {
				for (i in 0...anim.length) {
					anim[i] = anim[i].cloneWithNewTile(anim[i].tile.center());
				}
			}
			final animStates = [for (a in anim) Frame(a.cloneWithDuration(1.0 / entry.fps))];
			final loopCount = entry.loop ? -1 : 0;
			animSM.addAnimationState(entry.key, animStates, loopCount, new Map());
		}
		animSM.play(initialState);
		return animSM;
	}

	/** Build a TileGroup by finding the Nth one in the programmable's node tree.
	 *  Used by generated code for TILEGROUP nodes.
	 *  Delegates to the builder which handles TileGroup's special child-add mechanism. */
	public function buildTileGroupFromProgrammable(programmableName:String, index:Int = 0):h2d.Object {
		final builder:MultiAnimBuilder = cast _builder;
		final progNode = builder.multiParserResult.nodes.get(programmableName);
		if (progNode == null)
			throw 'could not find programmable node: $programmableName';
		// Build the tilegroup via the builder — it handles TileGroupMode for children
		final result = builder.buildWithParameters(programmableName, new Map());
		// Find all TileGroups in the result's object tree
		final tileGroups:Array<h2d.Object> = [];
		findAllTileGroupsInTree(result.object, tileGroups);
		if (index >= tileGroups.length)
			throw 'tileGroup index $index out of range (found ${tileGroups.length}) in programmable: $programmableName';
		return tileGroups[index];
	}

	private static function findAllTileGroupsInTree(obj:h2d.Object, result:Array<h2d.Object>):Void {
		if (Std.isOfType(obj, h2d.TileGroup)) {
			result.push(obj);
			return;
		}
		final it = @:privateAccess obj.children.iterator();
		while (it.hasNext()) {
			findAllTileGroupsInTree(it.next(), result);
		}
	}

	/** Get all tiles from a sheet, optionally filtered by tile name prefix.
	 *  Used by generated code for TilesIterator. */
	public function getSheetTiles(sheetName:String, tileFilter:Null<String>):Array<Tile> {
		final sheet = getSheet(sheetName);
		final result:Array<Tile> = [];
		if (tileFilter != null) {
			final frames = sheet.getAnim(tileFilter);
			if (frames != null) {
				for (frame in frames) {
					if (frame != null && frame.tile != null)
						result.push(frame.tile);
				}
			}
		} else {
			for (entries in sheet.getContents()) {
				for (entry in entries) {
					if (entry != null)
						result.push(entry.t);
				}
			}
		}
		return result;
	}

	/** Get tiles for all frames of a state animation.
	 *  Used by generated code for StateAnimIterator. */
	public function getStateAnimTiles(animFilename:String, animationName:String, selector:Map<String, String>):Array<Tile> {
		final builder:MultiAnimBuilder = _builder;
		final tiles = @:privateAccess builder.collectStateAnimFrames(animFilename, animationName, selector);
		final result:Array<Tile> = [];
		for (ts in tiles) {
			switch (ts) {
				case TSTile(tile):
					result.push(tile);
				case TSSheet(sheet, name):
					final sheetStr = @:privateAccess builder.resolveAsString(sheet);
					final nameStr = @:privateAccess builder.resolveAsString(name);
					final atlas = getSheet(sheetStr);
					final frame = atlas.get(nameStr);
					if (frame != null)
						result.push(frame.tile);
				default:
			}
		}
		return result;
	}

	/** Build a placeholder via builder callback (for PLACEHOLDER nodes with PRSCallback source) */
	public function buildPlaceholderViaCallback(name:String):Null<h2d.Object> {
		final builder:MultiAnimBuilder = _builder;
		final callback = @:privateAccess builder.builderParams.callback;
		if (callback == null) return null;
		return extractObject(callback(Placeholder(name)));
	}

	/** Build a placeholder via builder callback with index (for PRSCallbackWithIndex source) */
	public function buildPlaceholderViaCallbackWithIndex(name:String, index:Int):Null<h2d.Object> {
		final builder:MultiAnimBuilder = _builder;
		final callback = @:privateAccess builder.builderParams.callback;
		if (callback == null) return null;
		return extractObject(callback(PlaceholderWithIndex(name, index)));
	}

	/** Build a placeholder via builder parameter source (for PRSBuilderParameterSource) */
	public function buildPlaceholderViaSource(name:String, settings:ResolvedSettings = null):Null<h2d.Object> {
		final builder:MultiAnimBuilder = _builder;
		final phObjects = @:privateAccess builder.builderParams.placeholderObjects;
		if (phObjects == null) return null;
		final param = phObjects.get(name);
		return switch param {
			case null: null;
			case PVObject(obj):
				if (settings != null)
					trace('Warning: PVObject placeholder "$name" ignores .manim settings — use PVFactory instead to receive settings');
				obj;
			case PVFactory(factoryMethod): factoryMethod(settings);
		};
	}

	/** Resolve a callback by name, returning a string result.
	 *  Used by generated code for RVCallbacks in text elements. */
	public function resolveCallback(name:String, defaultValue:String):String {
		final builder:MultiAnimBuilder = cast _builder;
		final callback = @:privateAccess builder.builderParams.callback;
		if (callback == null) return defaultValue;
		final result = callback(Name(name));
		return switch result {
			case CBRInteger(val): '$val';
			case CBRFloat(val): '$val';
			case CBRString(val): val;
			case CBRNoResult: defaultValue;
			case null: defaultValue;
			default: defaultValue;
		};
	}

	/** Resolve a callback by name and index, returning a string result.
	 *  Used by generated code for RVCallbacksWithIndex in text elements. */
	public function resolveCallbackWithIndex(name:String, index:Int, defaultValue:String):String {
		final builder:MultiAnimBuilder = cast _builder;
		final callback = @:privateAccess builder.builderParams.callback;
		if (callback == null) return defaultValue;
		final result = callback(NameWithIndex(name, index));
		return switch result {
			case CBRInteger(val): '$val';
			case CBRFloat(val): '$val';
			case CBRString(val): val;
			case CBRNoResult: defaultValue;
			case null: defaultValue;
			default: defaultValue;
		};
	}

	/** Resolve a callback by name, returning an integer result.
	 *  Used by generated code for RVCallbacks in numeric expressions. */
	public function resolveCallbackInt(name:String, defaultValue:Int):Int {
		final builder:MultiAnimBuilder = cast _builder;
		final callback = @:privateAccess builder.builderParams.callback;
		if (callback == null) return defaultValue;
		final result = callback(Name(name));
		return switch result {
			case CBRInteger(val): val;
			case CBRNoResult: defaultValue;
			case null: defaultValue;
			default: defaultValue;
		};
	}

	/** Resolve a callback by name and index, returning an integer result.
	 *  Used by generated code for RVCallbacksWithIndex in numeric expressions. */
	public function resolveCallbackWithIndexInt(name:String, index:Int, defaultValue:Int):Int {
		final builder:MultiAnimBuilder = cast _builder;
		final callback = @:privateAccess builder.builderParams.callback;
		if (callback == null) return defaultValue;
		final result = callback(NameWithIndex(name, index));
		return switch result {
			case CBRInteger(val): val;
			case CBRNoResult: defaultValue;
			case null: defaultValue;
			default: defaultValue;
		};
	}

	/** Generate a tile with centered text on a solid color background.
	 *  Used by generated code for colorWithText() in generated() tiles. */
	public function generateColorWithTextTile(w:Int, h:Int, bgColor:Int, text:String, textColor:Int, fontName:String):Tile {
		return @:privateAccess (_builder : MultiAnimBuilder).generateTileWithText(w, h, bgColor, text, textColor, fontName);
	}

	/** Generate an autotile region sheet tile showing the full region with numbered grid overlay.
	 *  Used by generated code for autotileRegionSheet() in generated() tiles. */
	public function getAutotileRegionSheetTile(autotileName:String, scale:Int, font:String, fontColor:Int):Tile {
		final builder:MultiAnimBuilder = cast _builder;
		final resolved = @:privateAccess builder.resolveAutotileRegionSheet(
			MultiAnimParser.ReferenceableValue.RVString(autotileName),
			MultiAnimParser.ReferenceableValue.RVInteger(scale),
			MultiAnimParser.ReferenceableValue.RVString(font),
			MultiAnimParser.ReferenceableValue.RVInteger(fontColor)
		);
		return @:privateAccess builder.generatePlaceholderBitmap(resolved);
	}

	/** Generate an autotile tile by name and index.
	 *  Looks up the autotile definition and resolves the tile from the appropriate source. */
	public function getAutotileTileByIndex(autotileName:String, tileIndex:Int):Tile {
		final builder:MultiAnimBuilder = cast _builder;
		final resolved = @:privateAccess builder.resolveAutotileRef(
			MultiAnimParser.ReferenceableValue.RVString(autotileName),
			MultiAnimParser.AutotileTileSelector.ByIndex(MultiAnimParser.ReferenceableValue.RVInteger(tileIndex))
		);
		return @:privateAccess builder.generatePlaceholderBitmap(resolved);
	}

	/** Build a named path via the builder.
	 *  Used by generated code for PATHS nodes. */
	public function buildPath(name:String, ?normalization:bh.paths.MultiAnimPaths.PathNormalization):bh.paths.MultiAnimPaths.Path {
		return (_builder : MultiAnimBuilder).getPaths().getPath(name, normalization);
	}

	/** Create an animated path via the builder.
	 *  Used by generated code for ANIMATED_PATH nodes. */
	public function buildAnimatedPath(name:String, ?normalization:bh.paths.MultiAnimPaths.PathNormalization):bh.paths.AnimatedPath {
		return (_builder : MultiAnimBuilder).createAnimatedPath(name, normalization);
	}

	/** Build a named curve via the builder.
	 *  Used by generated code for CURVES nodes. */
	public function buildCurve(name:String):bh.paths.Curve.ICurve {
		return (_builder : MultiAnimBuilder).getCurve(name);
	}

	/** Build an arbitrary node by its unique name, forwarding to the builder.
	 *  Used by generated repeatable code for node types not handled inline. */
	public function buildNodeByUniqueName(programmableName:String, uniqueNodeName:String):Null<h2d.Object> {
		final builder:MultiAnimBuilder = cast _builder;
		if (builder == null) return null;
		final progNode = builder.multiParserResult.nodes.get(programmableName);
		if (progNode == null) return null;
		final targetNode = findNodeByUniqueName(progNode, uniqueNodeName);
		if (targetNode == null) return null;
		return @:privateAccess builder.buildSingleNode(targetNode);
	}

	private static function findNodeByUniqueName(node:MultiAnimParser.Node, name:String):Null<MultiAnimParser.Node> {
		if (node.uniqueNodeName == name) return node;
		if (node.children != null) {
			for (child in node.children) {
				final found = findNodeByUniqueName(child, name);
				if (found != null) return found;
			}
		}
		return null;
	}

	static function extractObject(result:CallbackResult):Null<h2d.Object> {
		return switch result {
			case CBRObject(val): val;
			case CBRNoResult: null;
			case null: null;
			default: null;
		};
	}
}
