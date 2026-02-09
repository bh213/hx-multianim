package bh.multianim;

import h2d.ScaleGrid;
import h2d.Tile;
import h2d.Font;
import bh.base.ResourceLoader;
import bh.base.Atlas2.IAtlas2;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.multianim.MultiAnimParser.TileSource;

/**
 * Runtime access layer for generated programmable classes.
 * Wraps MultiAnimBuilder's resource loading to provide a clean API
 * that generated code can call without @:privateAccess.
 */
@:allow(bh.multianim.ProgrammableCodeGen)
class ProgrammableBuilderAccess {
	public final builder:MultiAnimBuilder;
	final resourceLoader:ResourceLoader;

	public function new(builder:MultiAnimBuilder) {
		this.builder = builder;
		this.resourceLoader = @:privateAccess builder.resourceLoader;
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

	/** Get a sprite sheet (atlas) by name */
	function getSheet(sheetName:String):IAtlas2 {
		return @:privateAccess builder.getOrLoadSheet(sheetName);
	}

	/** Build a sub-programmable via the builder (for REFERENCE nodes) */
	public function buildReference(name:String, parameters:Map<String, Dynamic>):BuilderResult {
		return builder.buildWithParameters(name, parameters);
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
			for (tileName in sheet.getContents().keys()) {
				final frame = sheet.get(tileName);
				if (frame != null)
					result.push(frame.tile);
			}
		}
		return result;
	}

	/** Get tiles for all frames of a state animation.
	 *  Used by generated code for StateAnimIterator. */
	public function getStateAnimTiles(animFilename:String, animationName:String, selector:Map<String, String>):Array<Tile> {
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
