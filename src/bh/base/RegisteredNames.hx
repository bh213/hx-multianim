package bh.base;

/**
	The rule every registry of names for the whole game keeps (`CursorManager`, the sound banks and
	music blocks of `bh.audio.Audio`): a file that registers a name again replaces what it
	registered, as a reload does, and the names it has no more are dropped; code (no file), or
	another file, registering a name already taken is an error that names both. Fonts and custom
	filters come from code only, so a taken name is an error there too, until it is unregistered.
**/
class RegisteredNames {
	/** The error for `source` registering a `kind` called `name` that `owner` holds, or null when
	 *  `source` may replace it (the same file). A null `owner` or `source` is code. */
	public static function clash(kind:String, name:String, owner:Null<String>, source:Null<String>):Null<String> {
		if (source != null && owner == source)
			return null;
		return '$kind "$name" is registered by ${by(owner)}, and ${by(source)} registers it too: a name is one $kind for the whole game. Rename one, or remove the first';
	}

	static function by(source:Null<String>):String {
		return source == null ? "code" : '"$source"';
	}
}
