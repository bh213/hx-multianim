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

	@Test
	public function testMasterAndSingleToSameSingle_RemovesOnlyMaster():Void {
		// Dropping the master while the single screen stays: only the master leaves.
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);

		var master = new ProbeScreen(sm);
		var single = new ProbeScreen(sm);

		sm.updateScreenMode(MasterAndSingle(master, single));

		var error:Null<String> = null;
		try {
			sm.updateScreenMode(Single(single));
		} catch (e:Dynamic) {
			error = Std.string(e);
		}
		Assert.isNull(error, 'MasterAndSingle(m, s) -> Single(s) must not throw, got: $error');
		Assert.isNull(master.getSceneRoot().parent, "the master must be removed from the scene");
		Assert.isFalse(sm.activeScreens.contains(master), "the master must no longer be active");
		Assert.notNull(single.getSceneRoot().parent, "the single screen stays in the scene");
		Assert.isFalse(single.leavingObserved, "the single screen stays, so it must not receive UILeaving");

		master.getSceneRoot().remove();
		single.getSceneRoot().remove();
	}

	// ==================== A dialog's result belongs to one opening ====================

	@Test
	public function testReopenedDialogAfterAnimatedCloseDoesNotReplayItsResult():Void {
		// closeDialogWithTransition read exitResponse without clearing it, and the only reset is in
		// the controller's update(), which a closed dialog no longer gets — so reopening the same
		// dialog instance delivered the old result on the first update() and closed it again.
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var main = new ProbeScreen(sm);
		var d = new ProbeScreen(sm);

		sm.switchTo(main);
		sm.modalDialog(d, main, "d");
		d.setExitCode(true);
		sm.closeDialogWithTransition(Fade(0.2));
		sm.finalizeTransition();
		Assert.equals("d", main.dialogResults.join(","), "precondition: the animated close delivers the result once");

		main.dialogResults = [];
		sm.modalDialog(d, main, "d");
		sm.update(1 / 60);

		Assert.equals(0, main.dialogResults.length,
			'a reopened dialog must not deliver the result of its previous opening; caller received: ${main.dialogResults}');
		Assert.isTrue(sm.isShowing(d), "the reopened dialog must stay open");

		removeRoots([main, d]);
	}

	@Test
	public function testReopenedDialogAfterInstantCloseDoesNotReplayItsResult():Void {
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var main = new ProbeScreen(sm);
		var d = new ProbeScreen(sm);

		sm.switchTo(main);
		sm.modalDialog(d, main, "d");
		d.setExitCode(true);
		sm.closeDialogWithTransition();
		Assert.equals("d", main.dialogResults.join(","), "precondition: the instant close delivers the result once");

		main.dialogResults = [];
		sm.modalDialog(d, main, "d");
		sm.update(1 / 60);

		Assert.equals(0, main.dialogResults.length,
			'a reopened dialog must not deliver the result of its previous opening; caller received: ${main.dialogResults}');
		Assert.isTrue(sm.isShowing(d), "the reopened dialog must stay open");

		removeRoots([main, d]);
	}

	@Test
	public function testReopenedDialogAfterSwitchScreenDoesNotReplayItsResult():Void {
		// A screen switch closes an open dialog — with a transition through closeDialogWithTransition(None),
		// without one straight through updateScreenMode, which delivers nothing and left the value set.
		// Either way the dialog's next opening must start without a result.
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var main = new ProbeScreen(sm);
		var other = new ProbeScreen(sm);
		var d = new ProbeScreen(sm);

		sm.switchTo(main);
		sm.modalDialog(d, main, "d");
		d.setExitCode(true);
		sm.switchScreen(Single(other), Fade(0.2));
		sm.finalizeTransition();

		main.dialogResults = [];
		sm.modalDialog(d, other, "d");
		sm.update(1 / 60);
		Assert.equals(0, other.dialogResults.length + main.dialogResults.length,
			'after an animated switch closed it, a reopened dialog must not deliver its old result; caller received: ${other.dialogResults}');
		Assert.isTrue(sm.isShowing(d), "the dialog reopened after an animated switch must stay open");

		d.setExitCode(true);
		sm.switchTo(main);
		main.dialogResults = [];
		sm.modalDialog(d, main, "d");
		sm.update(1 / 60);
		Assert.equals(0, main.dialogResults.length,
			'after an instant switch closed it, a reopened dialog must not deliver its old result; caller received: ${main.dialogResults}');
		Assert.isTrue(sm.isShowing(d), "the dialog reopened after an instant switch must stay open");

		removeRoots([main, other, d]);
	}

	@Test
	public function testCoveredDialogRevivedAfterTopCloseDoesNotReplayItsResult():Void {
		// Opening d2 over d1 delivers d1's result. Closing d2 brings d1 back; d1 must not then
		// deliver the same result a second time and close itself.
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var main = new ProbeScreen(sm);
		var d1 = new ProbeScreen(sm);
		var d2 = new ProbeScreen(sm);

		sm.switchTo(main);
		sm.modalDialog(d1, main, "d1");
		d1.setExitCode("x");
		sm.modalDialog(d2, main, "d2");
		Assert.equals("d1", main.dialogResults.join(","), "precondition: opening d2 over d1 delivers d1's result");
		sm.closeDialogWithTransition();
		Assert.isTrue(sm.isShowing(d1), "precondition: closing d2 brings d1 back");

		main.dialogResults = [];
		sm.update(1 / 60);

		Assert.equals(0, main.dialogResults.length,
			'the revived dialog must not deliver its already-delivered result again; caller received: ${main.dialogResults}');
		Assert.isTrue(sm.isShowing(d1), "the revived dialog must stay open");

		removeRoots([main, d1, d2]);
	}

	// ==================== Opening the next dialog from OnDialogResult ====================

	@Test
	public function testOpeningNextDialogFromResultShowsItAndDeliversOnce():Void {
		// The result was delivered while mode was still Dialog(A): modalDialog(B) in the handler took
		// the dialog-over-dialog branch (delivering A's result again) and the pending close of A then
		// removed B.
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var main = new ProbeScreen(sm);
		var a = new ProbeScreen(sm);
		var b = new ProbeScreen(sm);

		sm.switchTo(main);
		sm.modalDialog(a, main, "A");
		var opened = 0;
		main.onDialogResult = (name, result) -> {
			// `opened` stops the recursion the unfixed code runs into (A's result arrives again from
			// inside modalDialog(B)).
			if (name == "A" && result != null && opened == 0) {
				opened++;
				sm.modalDialog(b, main, "B");
			}
		};
		a.setExitCode("ok");
		sm.update(1 / 60);

		Assert.equals("A", main.dialogResults.join(","), 'A\'s result must be delivered once; caller received: ${main.dialogResults}');
		Assert.isTrue(sm.isShowing(b), "B, opened from A's result, must be showing");
		Assert.notNull(b.getSceneRoot().parent, "B must be in the scene");
		Assert.isNull(a.getSceneRoot().parent, "A is closed");

		b.setExitCode("ok");
		sm.update(1 / 60);
		Assert.equals("A,B", main.dialogResults.join(","));
		Assert.isFalse(sm.isShowing(a), "closing B returns to the screen under A, not to A");
		Assert.isTrue(sm.isShowing(main));

		removeRoots([main, a, b]);
	}

	@Test
	public function testOpeningNextDialogFromResultOfInstantCloseShowsIt():Void {
		// Same as above through closeDialogWithTransition() — what OkCancelDialog does with closeTransition = None.
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var main = new ProbeScreen(sm);
		var a = new ProbeScreen(sm);
		var b = new ProbeScreen(sm);

		sm.switchTo(main);
		sm.modalDialog(a, main, "A");
		var opened = 0;
		main.onDialogResult = (name, result) -> {
			if (name == "A" && result != null && opened == 0) {
				opened++;
				sm.modalDialog(b, main, "B");
			}
		};
		a.setExitCode("ok");
		sm.closeDialogWithTransition();

		Assert.equals("A", main.dialogResults.join(","), 'A\'s result must be delivered once; caller received: ${main.dialogResults}');
		Assert.isTrue(sm.isShowing(b), "B, opened from A's result, must be showing");
		Assert.notNull(b.getSceneRoot().parent, "B must be in the scene");
		Assert.isNull(a.getSceneRoot().parent, "A is closed");

		removeRoots([main, a, b]);
	}

	// ==================== Closing or switching during a running transition ====================

	@Test
	public function testDialogExitDuringOpenTransitionFinishesTheTransition():Void {
		// The controller-exit close removed the dialog mid-fade: its enter tween was cancelled with the
		// root half transparent, the transition's onComplete never ran, and isTransitioning stayed true.
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var main = new ProbeScreen(sm);
		var d = new ProbeScreen(sm);

		sm.switchTo(main);
		sm.modalDialogWithTransition(d, main, "d", null, Fade(1.0));
		sm.update(0.016); // skipFirstDt
		sm.update(0.1);
		Assert.isTrue(d.getSceneRoot().alpha < 1.0, "precondition: the open fade is running");

		d.setExitCode(true);
		sm.update(0.016);

		Assert.isFalse(sm.isShowing(d), "precondition: the dialog closed");
		Assert.isFalse(sm.isTransitioning, "closing the dialog must finish its open transition");
		sm.modalDialog(d, main, "d");
		Assert.floatEquals(1.0, d.getSceneRoot().alpha, "a dialog reopened without a transition must be fully opaque");

		removeRoots([main, d]);
	}

	@Test
	public function testInstantCloseDuringOpenTransitionFinishesTheTransition():Void {
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var main = new ProbeScreen(sm);
		var d = new ProbeScreen(sm);

		sm.switchTo(main);
		sm.modalDialogWithTransition(d, main, "d", null, SlideUp(1.0));
		sm.update(0.016); // skipFirstDt
		sm.update(0.1);
		Assert.isTrue(d.getSceneRoot().y > 0, "precondition: the open slide is running");

		sm.closeDialogWithTransition();

		Assert.isFalse(sm.isTransitioning, "closing the dialog must finish its open transition");
		sm.modalDialog(d, main, "d");
		Assert.floatEquals(0.0, d.getSceneRoot().y, "a dialog reopened without a transition must be in place");

		removeRoots([main, d]);
	}

	@Test
	public function testInterruptedSwitchDoesNotEndTheNextTransitionEarly():Void {
		// A's fade-in carried the first transition's onComplete; switchTo(B) finalized the first
		// transition but left that tween running, and when it ended it ran the SECOND transition's
		// cleanup — A removed mid-slide and isTransitioning cleared while B still slid in.
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var a = new ProbeScreen(sm);
		var b = new ProbeScreen(sm);

		sm.switchTo(a, null, Fade(0.3));
		sm.update(0.016); // skipFirstDt
		sm.update(0.1);
		sm.switchTo(b, null, SlideLeft(1.0));
		Assert.floatEquals(1.0, a.getSceneRoot().alpha, "finalizing the interrupted fade must jump it to its end");

		sm.update(0.016); // skipFirstDt of the slide
		sm.update(0.3); // A's old fade would have ended here
		Assert.isTrue(sm.isTransitioning, "the slide to B is still running");
		Assert.notNull(a.getSceneRoot().parent, "A leaves the scene only when the slide ends");

		sm.finalizeTransition();
		Assert.isNull(a.getSceneRoot().parent, "A leaves when the slide is finished");

		removeRoots([a, b]);
	}

	@Test
	public function testClosingDialogDuringOpenFadeDeliversResultWhenCloseEnds():Void {
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var main = new ProbeScreen(sm);
		var d = new ProbeScreen(sm);

		sm.switchTo(main);
		sm.modalDialogWithTransition(d, main, "d", null, Fade(0.3));
		sm.update(0.016); // skipFirstDt
		sm.update(0.1);
		sm.closeDialogWithTransition(Fade(1.0));

		sm.update(0.016);
		sm.update(0.3); // the interrupted open fade would have ended here
		Assert.equals(0, main.dialogResults.length,
			'the result must arrive when the close ends, not when the interrupted open fade ends; caller received: ${main.dialogResults}');
		Assert.isTrue(sm.isTransitioning, "the close is still running");

		sm.finalizeTransition();
		Assert.equals("d", main.dialogResults.join(","), "the result arrives once when the close is finished");

		removeRoots([main, d]);
	}

	@Test
	public function testPromotingTheSingleToMasterWithTransitionIsRejectedLikeTheInstantSwitch():Void {
		// Single(A) -> MasterAndSingle(A, B): the instant path throws; the animated path put A in both
		// the add and the remove set and left it detached from the scene but still active.
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var a = new ProbeScreen(sm);
		var b = new ProbeScreen(sm);

		sm.switchTo(a);
		var error:Null<String> = null;
		try {
			sm.switchScreen(MasterAndSingle(a, b), Fade(0.2));
		} catch (e:Dynamic) {
			error = Std.string(e);
		}
		sm.finalizeTransition();

		Assert.notNull(error, "the switch the instant path rejects must be rejected with a transition too");
		Assert.notNull(a.getSceneRoot().parent, "A must stay in the scene");
		Assert.equals(1, sm.activeScreens.filter(s -> s == a).length, "A must be active exactly once");
		Assert.isTrue(sm.isShowing(a));

		removeRoots([a, b]);
	}

	static function removeRoots(screens:Array<UIScreen>):Void {
		for (s in screens)
			s.getSceneRoot().remove();
	}
}

/** Screen that records the scene-root parent observed when UILeaving fires,
 *  plus every OnDialogResult dialog name it receives as a caller. */
private class ProbeScreen extends UIScreenBase {
	public var leavingObserved:Bool = false;
	public var leavingParentAtDispatch:Null<h2d.Object> = null;
	public var dialogResults:Array<String> = [];
	/** Called after an OnDialogResult is recorded — lets a test react to it (open the next dialog). */
	public var onDialogResult:Null<(dialogName:String, result:Null<Dynamic>) -> Void> = null;

	public function new(sm:ScreenManager) {
		super(sm);
	}

	public function load():Void {}

	public function onScreenEvent(event:bh.ui.UIElement.UIScreenEvent, source:Null<bh.ui.UIElement>):Void {
		switch event {
			case UILeaving:
				leavingObserved = true;
				leavingParentAtDispatch = getSceneRoot().parent;
			case UIOnControllerEvent(OnDialogResult(dialogName, result)):
				dialogResults.push(dialogName);
				final hook = onDialogResult;
				if (hook != null)
					hook(dialogName, result);
			default:
		}
	}

	override public function update(dt:Float):Void {}
}
