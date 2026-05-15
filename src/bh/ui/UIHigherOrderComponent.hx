package bh.ui;

import bh.ui.UIElement.UIScreenEvent;

/**
 * Interface for higher-order UI components (Grid, CardHand) that need
 * lifecycle auto-wiring from UIScreenBase: update, mouse routing, event
 * dispatch, and disposal.
 *
 * Unlike UIElement (simple controls like buttons/sliders), higher-order
 * components manage their own scene graph and may span multiple layers.
 * Scene graph attachment remains manual — the screen calls addObjectToLayer()
 * as needed for each component's specific layering requirements.
 */
interface UIHigherOrderComponent {
	/** Advance animations. Called automatically by UIScreenBase.update(dt). */
	function update(dt:Float):Void;

	/** Route mouse move. Returns true if consumed (blocks further processing). */
	function onMouseMove(sceneX:Float, sceneY:Float):Bool;

	/** Route mouse click. Returns true if consumed. */
	function onMouseClick(sceneX:Float, sceneY:Float, button:Int):Bool;

	/** Route mouse release. Returns true if consumed. */
	function onMouseRelease(sceneX:Float, sceneY:Float):Bool;

	/** Route screen events (UIInteractiveEvent, etc). Returns true if consumed. */
	function handleScreenEvent(event:UIScreenEvent):Bool;

	/** Get the primary scene graph object. Used by macroBuildWithParameters for placeholder placement.
	 *  Components that manage multiple containers (e.g. CardHand) may not support macro placement. */
	function getObject():h2d.Object;

	/** Clean up all resources. Called automatically by UIScreenBase.clear(). */
	function dispose():Void;
}
