package bh.multianim;

/** `h2d.Graphics` that keeps its vertex content when detached from the scene.

	Vanilla `h2d.Graphics.onRemove` calls `clear()`, wiping all draw commands.
	For long-lived objects that get detached and re-attached (e.g. screens
	swapping in/out of `ScreenManager`), the manim redraw path only re-fires
	for conditional re-insertion — it does not re-fire when the whole screen
	root is detached and later re-added. The content vanishes.

	KeepGraphics suppresses the onRemove-triggered `clear()` while still
	running the rest of `onRemove` (filter unbind, child recursion). Any
	explicit `clear()` call (param-driven redraw via `trackExpression`, etc.)
	still works normally. */
class KeepGraphics extends h2d.Graphics {
	var suppressClear:Bool = false;

	override function onRemove() {
		suppressClear = true;
		super.onRemove();
		suppressClear = false;
	}

	override function clear():Void {
		if (suppressClear) return;
		super.clear();
	}
}
