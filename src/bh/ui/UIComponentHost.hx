package bh.ui;

import bh.ui.screens.UIScreen.LayersEnum;
import bh.multianim.MultiAnimBuilder.BuilderResult;

/**
 * Interface for services that higher-order components (CardHand, etc.) need from their host.
 * Decouples components from the concrete UIScreenBase — enables testing and standalone usage.
 *
 * UIScreenBase implements this interface.
 */
interface UIComponentHost {
	/** Add an h2d.Object to a named scene layer. */
	function addObjectToLayer(object:h2d.Object, ?layer:LayersEnum):h2d.Object;

	/** Register all interactives from a BuilderResult for event dispatch. */
	function addInteractives(r:BuilderResult, ?prefix:String):Array<UIInteractiveWrapper>;

	/** Unregister interactives by prefix. */
	function removeInteractives(?prefix:String):Void;

	/** Look up a registered interactive by ID (O(1)). */
	function getInteractive(id:String):Null<UIInteractiveWrapper>;

	/** Get the screen's auto-wiring helper for `autoStatus` interactives, or null. */
	function getAutoInteractiveHelper():Null<UIRichInteractiveHelper>;
}
