package bh.base;

/**
	The game's clock as the engine's services see it: paused or not, and how fast it runs.

	`ScreenManager.clock` is the one the game and its tools set: the DevBridge's `pause` sets
	`paused`, a game's own pause menu or slow motion sets `paused` and `scale` itself. Nothing in the
	engine stops because of it: it is a signal, for a sound to pause with the game, a pitch to follow
	slow motion, a tool to show the state. Listeners hear every change, with the clock.
**/
class Clock {
	/** True while the game stands still. */
	public var paused(default, set):Bool = false;

	/** 1 at full speed, 0.5 at half, 2 at double; never below 0. */
	public var scale(default, set):Float = 1.0;

	var listeners:Array<Clock->Void> = [];

	public function new() {}

	function set_paused(v:Bool):Bool {
		if (paused == v)
			return v;
		paused = v;
		tell();
		return v;
	}

	function set_scale(v:Float):Float {
		if (v < 0)
			v = 0;
		if (scale == v)
			return v;
		scale = v;
		tell();
		return v;
	}

	/** Hears every change of `paused` or `scale`. */
	public function addListener(listener:Clock->Void):Void {
		listeners.push(listener);
	}

	public function removeListener(listener:Clock->Void):Bool {
		for (i in 0...listeners.length)
			if (Reflect.compareMethods(listeners[i], listener)) {
				listeners.splice(i, 1);
				return true;
			}
		return false;
	}

	function tell():Void {
		for (listener in listeners)
			listener(this);
	}
}
