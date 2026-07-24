package bh.test.examples;

import utest.Assert;
import bh.ui.screens.ScreenManager;
import bh.ui.screens.ScreenTransition;
import bh.ui.screens.UIScreen;
import bh.ui.UIElement;

/**
 * Regression tests for ScreenManager dialog transition lifecycle.
 *
 * In every non-dialog transition, an outgoing UIScreen receives UILeaving
 * while its scene root is still attached — the shared post-switch loop
 * fires the lifecycle events first and only then calls removeScreen().
 *
 * The Dialog -> Dialog branch historically had an extra explicit
 * removeScreen(oldDialog) call that detached the scene root BEFORE the
 * lifecycle loop fired UILeaving, breaking that invariant only for this
 * one transition.
 */
@:access(bh.ui.screens.ScreenManager)
class ScreenManagerDialogTransitionTest extends utest.Test {
	@Test
	public function testDialogToDialog_UILeavingFiresWhileAttached():Void {
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);

		var main = new ProbeScreen(sm);
		var d1 = new ProbeScreen(sm);
		var d2 = new ProbeScreen(sm);

		sm.switchTo(main);
		sm.modalDialog(d1, main, "d1");
		sm.modalDialog(d2, main, "d2");

		Assert.isTrue(d1.leavingObserved, "d1 must receive UILeaving during Dialog->Dialog transition");
		Assert.isTrue(d1.leavingParentAtDispatch != null,
			"d1.sceneRoot.parent must still be attached when UILeaving fires — "
			+ "this matches every non-dialog transition and preserves invariant for event listeners");

		main.getSceneRoot().remove();
		d1.getSceneRoot().remove();
		d2.getSceneRoot().remove();
	}

	@Test
	public function testAnimatedDialogClose_RestoresUnderlyingDialog():Void {
		// A dialog opened over another dialog captures the inner dialog as its
		// previousMode, but the inner dialog is removed from the scene when the
		// outer one opens. Closing the outer dialog with a transition must
		// re-attach the inner dialog and restore its input — matching the
		// instant (no-transition) close path, which routes through
		// updateScreenMode's Dialog -> Dialog branch.
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);

		var main = new ProbeScreen(sm);
		var d1 = new ProbeScreen(sm);
		var d2 = new ProbeScreen(sm);

		sm.switchTo(main);
		sm.modalDialog(d1, main, "d1");
		sm.modalDialog(d2, main, "d2"); // d2.previousMode == Dialog(d1, ...)

		// Animated close of the outer dialog, driven to completion.
		sm.closeDialogWithTransition(Fade(0.2));
		sm.finalizeTransition();

		Assert.notNull(d1.getSceneRoot().parent,
			"underlying dialog d1 must be re-attached to the scene after animated close of d2");
		Assert.isTrue(sm.activeScreenControllers.contains(d1),
			"underlying dialog d1 must receive input after animated close of d2");

		main.getSceneRoot().remove();
		d1.getSceneRoot().remove();
		d2.getSceneRoot().remove();
	}

	@Test
	public function testDialogOverDialogCloseDeliversDialogResultOnce():Void {
		// Closing the top dialog of a dialog-over-dialog stack must deliver
		// OnDialogResult for the closing dialog exactly once. The instant close
		// path fires it in closeDialogWithTransition, and updateScreenMode's
		// Dialog -> Dialog branch must not fire it a second time when returning
		// to the underlying dialog.
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);

		var main = new ProbeScreen(sm);
		var d1 = new ProbeScreen(sm);
		var d2 = new ProbeScreen(sm);

		sm.switchTo(main);
		sm.modalDialog(d1, main, "d1");
		sm.modalDialog(d2, main, "d2");

		// Ignore the open-over notification for d1 — only observe the close of d2.
		main.dialogResults = [];
		sm.closeDialogWithTransition();

		final d2Results = main.dialogResults.filter(n -> n == "d2");
		Assert.equals(1, d2Results.length,
			'closing the top dialog must deliver exactly one OnDialogResult("d2"); caller received: ${main.dialogResults}');

		main.getSceneRoot().remove();
		d1.getSceneRoot().remove();
		d2.getSceneRoot().remove();
	}

	@Test
	public function testSameDialogModeRefreshKeepsOverlayAndFiresNoPhantomResult():Void {
		// ScreenManager.reload() ends with updateScreenMode(this.mode). With a
		// dialog open this is a Dialog -> Dialog transition where old and new
		// dialog are the SAME screen. That refresh must be a no-op for the
		// dialog lifecycle: the modal overlay must survive, the caller must not
		// receive a phantom OnDialogResult, and the dialog must not observe a
		// spurious UILeaving/UIEntering round trip.
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);

		var main = new ProbeScreen(sm);
		var d1 = new ProbeScreen(sm);

		sm.switchTo(main);
		d1.modalOverlayConfig = {color: 0x000000, alpha: 0.5};
		sm.modalDialog(d1, main, "confirm");
		Assert.notNull(sm.modalOverlay, "sanity: modal overlay exists after opening the dialog");

		main.dialogResults = [];
		d1.leavingObserved = false;

		// What reload() does after rebuilding screens.
		sm.updateScreenMode(sm.mode);

		Assert.equals(0, main.dialogResults.length,
			'refreshing the current mode must not deliver a phantom OnDialogResult; caller received: ${main.dialogResults}');
		Assert.notNull(sm.modalOverlay, "modal overlay must survive a same-dialog mode refresh (reload with dialog open)");
		Assert.isFalse(d1.leavingObserved, "open dialog must not receive spurious UILeaving on a same-dialog mode refresh");

		main.getSceneRoot().remove();
		d1.getSceneRoot().remove();
	}

	@Test
	public function testSingleToSingle_UILeavingFiresWhileAttached():Void {
		// Control case: Single -> Single transition fires UILeaving while attached.
		// Dialog -> Dialog should match this ordering.
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);

		var a = new ProbeScreen(sm);
		var b = new ProbeScreen(sm);

		sm.switchTo(a);
		sm.switchTo(b);

		Assert.isTrue(a.leavingObserved, "a must receive UILeaving during Single->Single transition");
		Assert.isTrue(a.leavingParentAtDispatch != null,
			"Control: Single->Single fires UILeaving while scene root is still attached");

		a.getSceneRoot().remove();
		b.getSceneRoot().remove();
	}
}

/** Screen that records the scene-root parent observed when UILeaving fires,
 *  plus every OnDialogResult dialog name it receives as a caller. */
private class ProbeScreen extends UIScreenBase {
	public var leavingObserved:Bool = false;
	public var leavingParentAtDispatch:Null<h2d.Object> = null;
	public var dialogResults:Array<String> = [];

	public function new(sm:ScreenManager) {
		super(sm);
	}

	public function load():Void {}

	public function onScreenEvent(event:bh.ui.UIElement.UIScreenEvent, source:Null<bh.ui.UIElement>):Void {
		switch event {
			case UILeaving:
				leavingObserved = true;
				leavingParentAtDispatch = getSceneRoot().parent;
			case UIOnControllerEvent(OnDialogResult(dialogName, _)):
				dialogResults.push(dialogName);
			default:
		}
	}

	override public function update(dt:Float):Void {}
}
