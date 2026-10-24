package bh.base;

/**
	The time shaders move by: seconds of the game's own clock. `ScreenManager.update(dt)` advances it
	by the `dt` it is given, so a game that slows or stops its `dt` slows or stops its shaders, and the
	DevBridge's pause (which stops the update) stops them too. Every shader that moves reads `now()`
	as it draws; nothing sets a shader's time by hand.

	A picture taken to be compared (the studio's captures) sets `fixed`, so a moving shader draws the
	same each time: `ShaderClock.fixed = 1.5;` … `ShaderClock.fixed = null;`.
**/
class ShaderClock {
	/** Seconds of game time since the first update. */
	public static var seconds(default, null):Float = 0;

	/** When set, the time every shader draws at, whatever `seconds` is. */
	public static var fixed:Null<Float> = null;

	/** The time a shader draws at now. */
	public static inline function now():Float {
		final at = fixed;
		return at != null ? at : seconds;
	}

	/** On by `dt` seconds; nothing for a `dt` of 0 or less. */
	public static function advance(dt:Float):Void {
		if (dt > 0)
			seconds += dt;
	}

	/** Back to 0: what a test or a fresh game starts from. */
	public static function reset():Void {
		seconds = 0;
		fixed = null;
	}
}
