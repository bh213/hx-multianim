package bh.base;

class CursorManager {
	private static var cursorRegistry:Map<String, hxd.Cursor> = new Map();
	private static var defaultCursor:hxd.Cursor = Default;
	private static var defaultInteractiveCursor:hxd.Cursor = Button;
	private static var initialized = false;

	static function ensureInit() {
		if (initialized)
			return;
		initialized = true;
		for (name in BUILT_IN_NAMES)
			cursorRegistry.set(name, builtIn(name));
	}

	static final BUILT_IN_NAMES = [
		"default", "pointer", "button", "move", "text", "hide", "none", "resize-ns", "resize-we", "resize-nwse", "resize-nesw"
	];

	/** The OS cursor a name stands for before anything is registered under it, or null. */
	static function builtIn(key:String):Null<hxd.Cursor> {
		return switch key {
			case "default": hxd.Cursor.Default;
			case "pointer" | "button": hxd.Cursor.Button;
			case "move": hxd.Cursor.Move;
			case "text": hxd.Cursor.TextInput;
			case "hide" | "none": hxd.Cursor.Hide;
			case "resize-ns": hxd.Cursor.ResizeNS;
			case "resize-we": hxd.Cursor.ResizeWE;
			case "resize-nwse": hxd.Cursor.ResizeNWSE;
			case "resize-nesw": hxd.Cursor.ResizeNESW;
			default: null;
		}
	}

	/**
		Registers `cursor` under `name` (any case). `source` is the file registering it, null for code:
		the same file registering a name again replaces its cursor (a reload); code, or another file,
		registering a name already taken is an error naming both (`RegisteredNames`), until it is
		unregistered. An OS cursor's name (`pointer`, `move`, …) may be taken once.
	**/
	public static function registerCursor(name:String, cursor:hxd.Cursor, ?source:String):Void {
		ensureInit();
		final clash = clashOf(name, source);
		if (clash != null)
			throw clash;
		final key = name.toLowerCase();
		cursorRegistry.set(key, cursor);
		owners.set(key, source);
		tileCursors.remove(key);
	}

	/** The error registering `name` from `source` (null: code) would be, or null when it may: the
	 *  name is free, an OS cursor's, or `source`'s own. */
	public static function clashOf(name:String, ?source:String):Null<String> {
		final key = name.toLowerCase();
		return owners.exists(key) ? RegisteredNames.clash("cursor", name, owners.get(key), source) : null;
	}

	/** Who registered each name that is not an OS cursor's: a file's path, or null for code. */
	private static var owners:Map<String, Null<String>> = new Map();

	/**
		A bitmap cursor from a tile (an atlas cell), registered under `name` like the OS cursors,
		so `cursor => "name"` on an interactive, `cursor.hover`, and `getCursor(name)` find it.
		`hotX`, `hotY` is the pixel of the tile that clicks (inside the tile). The tile's pixels are
		read once, from its texture; on HashLink the cursor is an SDL/DirectX one, in the browser a
		CSS `url(data:…)` cursor made from the same pixels. A `.manim` file's `#name cursor { }`
		block registers its cursors this way when the file loads, `source` its path (see
		`registerCursor`).
	**/
	public static function registerTileCursor(name:String, tile:h2d.Tile, hotX:Int = 0, hotY:Int = 0, ?source:String):hxd.Cursor {
		final clash = clashOf(name, source);
		if (clash != null)
			throw clash;
		final cursor = cursorFromTile(tile, hotX, hotY);
		registerCursor(name, cursor, source);
		tileCursors.set(name.toLowerCase(), {tile: tile, hotX: hotX, hotY: hotY});
		return cursor;
	}

	/** An `hxd.Cursor.Custom` from the tile's pixels; nothing registered. Throws (a String) for an
	 *  empty tile or a hot point outside it, which SDL does not allow. */
	public static function cursorFromTile(tile:h2d.Tile, hotX:Int = 0, hotY:Int = 0):hxd.Cursor {
		final w = tile.iwidth;
		final h = tile.iheight;
		if (w <= 0 || h <= 0)
			throw 'a cursor needs a tile with pixels, got ${w}x${h}';
		if (hotX < 0 || hotY < 0 || hotX >= w || hotY >= h)
			throw 'cursor hot point $hotX, $hotY is outside its ${w}x${h} tile';
		if (tile.getTexture() == null)
			throw 'a cursor needs a tile with a texture';
		// Drawn to a texture of the tile's size and read back: works for a cell of an atlas and
		// for a generated tile (a 1x1 texture stretched to its size) alike.
		final target = new h3d.mat.Texture(w, h, [Target]);
		target.clear(0, 0.0);
		final scene = new h2d.Scene();
		final bitmap = new h2d.Bitmap(tile.sub(0, 0, w, h), scene);
		bitmap.drawTo(target);
		final pixels = target.capturePixels();
		scene.dispose();
		target.dispose();
		final frame = new hxd.BitmapData(w, h);
		frame.setPixels(pixels);
		pixels.dispose();
		return Custom(new hxd.Cursor.CustomCursor([frame], 1, hotX, hotY));
	}

	/** Removes the cursor registered under `name` (any case), so the name may be registered again;
	 *  an OS cursor's name (`move`, `pointer`, …) is the OS cursor again, never removed. Returns
	 *  whether a cursor was removed: false for a name nothing is registered under, an OS cursor's
	 *  that nothing replaced included. */
	public static function unregisterCursor(name:String):Bool {
		ensureInit();
		final key = name.toLowerCase();
		tileCursors.remove(key);
		final os = builtIn(key);
		if (os == null) {
			owners.remove(key);
			return cursorRegistry.remove(key);
		}
		cursorRegistry.set(key, os);
		return owners.remove(key);
	}

	/** Drops the cursors the file `source` registered that `keep` does not name (any case): what a
	 *  reload of a file that has them no more leaves free for another file (`unregisterCursor`, so
	 *  an OS cursor's name is the OS cursor again). Returns how many. */
	public static function unregisterDroppedBy(source:String, keep:Array<String>):Int {
		ensureInit();
		final kept = [for (name in keep) name.toLowerCase()];
		final dropped = [for (key => owner in owners) if (owner == source && !kept.contains(key)) key];
		for (key in dropped)
			unregisterCursor(key);
		return dropped.length;
	}

	/** Every registered cursor name (the OS ones and the registered ones), sorted. */
	public static function getRegisteredCursorNames():Array<String> {
		ensureInit();
		final names = [for (name in cursorRegistry.keys()) name];
		names.sort((a, b) -> a < b ? -1 : a > b ? 1 : 0);
		return names;
	}

	/** The tile a cursor was registered from with `registerTileCursor`, or null for any other. */
	public static function getTileCursor(name:String):Null<{tile:h2d.Tile, hotX:Int, hotY:Int}> {
		return tileCursors.get(name.toLowerCase());
	}

	private static var tileCursors:Map<String, {tile:h2d.Tile, hotX:Int, hotY:Int}> = new Map();

	public static function getCursor(name:String):Null<hxd.Cursor> {
		ensureInit();
		return cursorRegistry.get(name.toLowerCase());
	}

	public static function setDefaultInteractiveCursor(cursor:hxd.Cursor):Void {
		defaultInteractiveCursor = cursor;
	}

	public static function getDefaultInteractiveCursor():hxd.Cursor {
		return defaultInteractiveCursor;
	}

	public static function setDefaultCursor(cursor:hxd.Cursor):Void {
		defaultCursor = cursor;
	}

	public static function getDefaultCursor():hxd.Cursor {
		return defaultCursor;
	}

	/**
		A cursor shown whatever the UI under the mouse would show (the card hand hides the cursor
		this way while its arrow targets): set now, and the one controllers set while it lasts.
		`null` clears it, setting nothing itself: a controller sets the hovered element's cursor
		again on its next move or frame.
	**/
	public static function setOverrideCursor(cursor:Null<hxd.Cursor>):Void {
		overrideCursor = cursor;
		overrideVersion++;
		if (cursor != null)
			hxd.System.setCursor(cursor);
	}

	public static function getOverrideCursor():Null<hxd.Cursor> {
		return overrideCursor;
	}

	/** Changes every time the override is set or cleared, so a controller knows to set its cursor again. **/
	public static function getOverrideVersion():Int {
		return overrideVersion;
	}

	private static var overrideCursor:Null<hxd.Cursor> = null;
	private static var overrideVersion:Int = 0;
}
