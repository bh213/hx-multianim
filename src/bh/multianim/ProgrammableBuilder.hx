package bh.multianim;

import h2d.ScaleGrid;
import h2d.Tile;
import h2d.Font;
import bh.base.ResourceLoader;
import bh.base.Atlas2.IAtlas2;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.multianim.MultiAnimBuilder.CallbackRequest;
import bh.multianim.MultiAnimBuilder.CallbackResult;
import bh.multianim.MultiAnimBuilder.PlaceholderValues;
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

	/** Load a tile from a sprite sheet by name */
	public function loadTile(sheet:String, name:String):Tile {
		final atlas = getSheet(sheet);
		final frame = atlas.get(name);
		if (frame == null)
			throw 'tile "$name" not found in sheet "$sheet"';
		return frame.tile;
	}

	/** Load a tile from a sprite sheet by name and index */
	public function loadTileWithIndex(sheet:String, name:String, index:Int):Tile {
		final atlas = getSheet(sheet);
		final anim = atlas.getAnim(name);
		if (anim == null)
			throw 'tile "$name" not found in sheet "$sheet"';
		if (index < 0 || index >= anim.length)
			throw 'tile "$name" in sheet "$sheet" does not have index $index';
		return anim[index].tile;
	}

	/** Load a tile from a file path */
	public function loadTileFile(filename:String):Tile {
		return resourceLoader.loadTile(filename);
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

	/** Build a sub-programmable via the builder (for REFERENCE nodes) */
	public function buildReference(name:String, parameters:Map<String, Dynamic>):BuilderResult {
		return (_builder : MultiAnimBuilder).buildWithParameters(name, parameters);
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

	/** Build a TileGroup by finding it in the programmable's node tree.
	 *  Used by generated code for TILEGROUP nodes.
	 *  Delegates to the builder which handles TileGroup's special child-add mechanism. */
	public function buildTileGroupFromProgrammable(programmableName:String):h2d.Object {
		final builder:MultiAnimBuilder = cast _builder;
		final progNode = builder.multiParserResult.nodes.get(programmableName);
		if (progNode == null)
			throw 'could not find programmable node: $programmableName';
		final tgNode = findFirstTileGroupChild(progNode);
		if (tgNode == null)
			throw 'no tileGroup found in programmable: $programmableName';
		// Build the tilegroup via the builder — it handles TileGroupMode for children
		final result = builder.buildWithParameters(programmableName, new Map());
		// Find the TileGroup in the result's object tree
		return findTileGroupInTree(result.object);
	}

	private static function findFirstTileGroupChild(node:MultiAnimParser.Node):Null<MultiAnimParser.Node> {
		for (child in node.children) {
			switch child.type {
				case TILEGROUP: return child;
				default:
					var found = findFirstTileGroupChild(child);
					if (found != null) return found;
			}
		}
		return null;
	}

	private static function findTileGroupInTree(obj:h2d.Object):h2d.Object {
		if (Std.isOfType(obj, h2d.TileGroup)) return obj;
		final it = @:privateAccess obj.children.iterator();
		while (it.hasNext()) {
			var child = it.next();
			var found = findTileGroupInTree(child);
			if (found != null) return found;
		}
		return obj; // fallback
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
	public function buildPlaceholderViaSource(name:String):Null<h2d.Object> {
		final builder:MultiAnimBuilder = _builder;
		final phObjects = @:privateAccess builder.builderParams.placeholderObjects;
		if (phObjects == null) return null;
		final param = phObjects.get(name);
		return switch param {
			case null: null;
			case PVObject(obj): obj;
			case PVFactory(factoryMethod): factoryMethod(null);
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

	static function extractObject(result:CallbackResult):Null<h2d.Object> {
		return switch result {
			case CBRObject(val): val;
			case CBRNoResult: null;
			case null: null;
			default: null;
		};
	}
}
