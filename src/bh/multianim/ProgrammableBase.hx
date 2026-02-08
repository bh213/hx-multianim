package bh.multianim;

import h2d.Object;
import h2d.Layers;
import h2d.ScaleGrid;
import bh.base.ResourceLoader;
import bh.base.ResolvedGeneratedTileType;
import bh.base.PixelLine;

/**
 * Base class for macro-generated programmable UI elements.
 *
 * Usage:
 *   @:build(ProgrammableMacro.build("assets/healthBar.manim", "healthBar"))
 *   class HealthBar extends ProgrammableBase {}
 *
 * The macro generates typed parameter fields, create(), per-parameter
 * setters, and a full refresh() — all as compiled Haxe code with zero
 * interpretation overhead at runtime.
 */
@:nullSafety
class ProgrammableBase {
	var _root:Null<Layers> = null;
	var _resourceLoader:Null<ResourceLoader> = null;

	public function getObject():Null<Object> {
		return _root;
	}

	public function remove() {
		if (_root != null) {
			_root.remove();
		}
	}

	// -- Helpers used by macro-generated code --

	function _load9Patch(sheet:String, tilename:String):ScaleGrid {
		final sheetData = _resourceLoader.loadSheet2(sheet);
		if (sheetData == null)
			throw 'sheet ${sheet} could not be loaded';
		final ninePatch = sheetData.getNinePatch(tilename);
		if (ninePatch == null)
			throw 'tile ${tilename} in sheet ${sheet} could not be loaded';
		return ninePatch;
	}

	function _loadTile(filename:String):h2d.Tile {
		return _resourceLoader.loadTile(filename);
	}

	function _loadSheetTile(sheet:String, name:String, ?index:Int):h2d.Tile {
		final sheetData = _resourceLoader.loadSheet2(sheet);
		if (sheetData == null)
			throw 'sheet ${sheet} could not be loaded';
		if (index != null) {
			final arr = sheetData.getAnim(name);
			if (arr == null)
				throw 'tile ${name}, index ${index} in sheet could not be loaded';
			if (index < 0 || index >= arr.length)
				throw 'tile ${name} does not have index ${index}';
			return arr[index].tile;
		} else {
			final t = sheetData.get(name);
			if (t == null)
				throw 'tile ${name} in sheet could not be loaded';
			return t.tile;
		}
	}

	function _loadFont(fontName:String):h2d.Font {
		return _resourceLoader.loadFont(fontName);
	}

	function _generatePlaceholderTile(type:ResolvedGeneratedTileType):h2d.Tile {
		return _resourceLoader.getOrCreatePlaceholder(type, function(resolvedType) {
			return switch resolvedType {
				case Cross(w, h, color):
					final pl = new PixelLines(w, h);
					pl.rect(0, 0, w - 1, h - 1, color);
					pl.line(0, 0, w - 1, h - 1, color);
					pl.line(0, h - 1, w - 1, 0, color);
					pl.updateBitmap();
					pl.tile;
				case SolidColor(w, h, color):
					h2d.Tile.fromColor(color, w, h);
			};
		});
	}
}
