package bh.ui;

import bh.ui.screens.UIScreen.LayersEnum;
import bh.ui.UIElement.UIScreenEvent;
import bh.ui.UIInteractiveSource;

/**
 * Interface for services that higher-order components (CardHand, etc.) need from their host.
 * Decouples components from the concrete UIScreenBase — enables testing and standalone usage.
 *
 * UIScreenBase implements this interface.
 */
interface UIComponentHost {
	/** Add an h2d.Object to a named scene layer. */
	function addObjectToLayer(object:h2d.Object, ?layer:LayersEnum):h2d.Object;

	/** Register all interactives from a source for event dispatch. Accepts either a
	 *  `BuilderResult` (runtime path) or a codegen instance — both implement `UIInteractiveSource`. */
	function addInteractives(source:UIInteractiveSource, ?prefix:String):Array<UIInteractiveWrapper>;

	/** Unregister interactives by prefix. */
	function removeInteractives(?prefix:String):Void;

	/** Look up a registered interactive by ID (O(1)). */
	function getInteractive(id:String):Null<UIInteractiveWrapper>;

	/** Get the screen's auto-wiring helper for `autoStatus` interactives, or null. */
	function getAutoInteractiveHelper():Null<UIRichInteractiveHelper>;

	/** Push an event into the host (e.g. panel close notifications). */
	function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void;
}
