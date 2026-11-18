package bh.ui;

/** A host that holds some interactives pressed whatever the pointer does: a jukebox's key while its
 *  track plays (`UIScreenBase`). Every `UIRichInteractiveHelper` on such a host shows a held key
 *  `pressed` where it would show `normal`, `hover` or `pressed`, so the pointer leaving it, or the
 *  click that started its track, leaves it pressed. */
interface UIHeldKeys {
	/** Whether the interactive of this id is held pressed now. */
	function isKeyHeld(interactiveId:String):Bool;
}
