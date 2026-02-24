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
		cursorRegistry.set("default", hxd.Cursor.Default);
		cursorRegistry.set("pointer", hxd.Cursor.Button);
		cursorRegistry.set("button", hxd.Cursor.Button);
		cursorRegistry.set("move", hxd.Cursor.Move);
		cursorRegistry.set("text", hxd.Cursor.TextInput);
		cursorRegistry.set("hide", hxd.Cursor.Hide);
		cursorRegistry.set("none", hxd.Cursor.Hide);
		cursorRegistry.set("resize-ns", hxd.Cursor.ResizeNS);
		cursorRegistry.set("resize-we", hxd.Cursor.ResizeWE);
		cursorRegistry.set("resize-nwse", hxd.Cursor.ResizeNWSE);
		cursorRegistry.set("resize-nesw", hxd.Cursor.ResizeNESW);


	}

	public static function registerCursor(name:String, cursor:hxd.Cursor):Void {
		ensureInit();
		cursorRegistry.set(name.toLowerCase(), cursor);
	}

	public static function unregisterCursor(name:String):Bool {
		ensureInit();
		return cursorRegistry.remove(name.toLowerCase());
	}

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
}
