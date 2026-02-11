package bh.multianim;

import h2d.ScaleGrid;
import h2d.Tile;
import h2d.Font;
import bh.base.ResourceLoader;
import bh.base.Atlas2.IAtlas2;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.multianim.MultiAnimParser.TileSource;

/**
 * Base class for generated programmable classes.
 * The parent factory class is constructed with a ResourceLoader.
 * Companion classes receive a MultiAnimBuilder at creation time
 * (stored in _builder) for full resource resolution.
 *
 * Usage:
 *   @:build(bh.multianim.ProgrammableCodeGen.buildAll())
 *   class MyScreen extends ProgrammableBuilder {
 *       @:manim("path.manim", "button") public var button;
 *   }
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
}
