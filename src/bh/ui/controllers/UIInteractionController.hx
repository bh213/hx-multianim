package bh.ui.controllers;

import bh.ui.UIElement;
import bh.ui.UIElement.UIScreenEvent;
import bh.ui.controllers.UIController;
import h2d.col.Point;

/**
 * Base class for modal interaction controllers (card selection, target picking, etc.).
 *
 * Extends UIDefaultController to preserve all default behavior (hover, cursor,
 * outside-click, element updates). Adds:
 * - Deferred completion via `complete()`/`cancel()` (fires in `update()`, safe outside event processing)
 * - `onActivate()`/`onDeactivate()` hooks for setup/teardown
 * - Escape and right-click cancellation built-in
 * - Callback-based result delivery
 *
 * Usage: push via `UIScreenBase.pushController()`, or use convenience methods
 * (`selectFromHand()`, `pickTarget()`) which handle push/pop automatically.
 */
@:nullSafety
class UIInteractionController extends UIDefaultController {
	var pendingResult:Null<Dynamic> = null;
	var pendingCancel:Bool = false;
	var resultCallback:Null<(result:Null<Dynamic>) -> Void>;

	public function new(integration:UIControllerScreenIntegration, resultCallback:(result:Null<Dynamic>) -> Void) {
		super(integration);
		this.resultCallback = resultCallback;
	}

	/** Mark this interaction as completed with a result. Delivery deferred to next update(). */
	public function complete(result:Dynamic):Void {
		if (pendingCancel)
			return; // cancel takes priority if already pending
		pendingResult = result;
	}

	/** Cancel this interaction. Delivery deferred to next update(). Result will be null. */
	public function cancel():Void {
		pendingCancel = true;
		pendingResult = null;
	}

	/** Called when this controller becomes the active (top-of-stack) controller.
	 *  Override to set up visual states, disable drag, highlight targets, etc. */
	public function onActivate():Void {}

	/** Called when this controller is about to be removed from the stack.
	 *  Override to restore visual states, re-enable drag, clear highlights. */
	public function onDeactivate():Void {}

	override public function lifecycleEvent(event:UIControllerLifecycleEvent):Void {
		switch event {
			case LifecycleControllerStarted:
				onActivate();
			case LifecycleControllerFinished:
				onDeactivate();
		}
	}

	override public function update(dt:Float):UIControllerResult {
		// Deliver pending result/cancellation
		if (pendingCancel || pendingResult != null) {
			final wasCancelled = pendingCancel;
			final result = pendingResult;
			pendingCancel = false;
			pendingResult = null;
			final cb = resultCallback;
			resultCallback = null; // prevent double-fire
			if (cb != null)
				cb(wasCancelled ? null : result);
			return UIControllerRunning;
		}

		return super.update(dt);
	}

	/** Escape cancels the interaction. */
	override public function handleKey(keyCode:Int, release:Bool, mousePoint:Point, eventWrapper:EventWrapper):Void {
		if (!release && keyCode == hxd.Key.ESCAPE) {
			cancel();
			return;
		}
		super.handleKey(keyCode, release, mousePoint, eventWrapper);
	}

	/** Right-click cancels the interaction. */
	override public function handleClick(mousePoint:Point, button:Int, release:Bool, eventWrapper:EventWrapper):Void {
		if (release && button == 1) {
			cancel();
			return;
		}
		super.handleClick(mousePoint, button, release, eventWrapper);
	}

	override public function getDebugName():String {
		return "interaction controller";
	}
}
