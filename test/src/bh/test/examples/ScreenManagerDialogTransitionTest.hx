package bh.test.examples;

import utest.Assert;
import bh.ui.screens.ScreenManager;
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

/** Screen that records the scene-root parent observed when UILeaving fires. */
private class ProbeScreen extends UIScreenBase {
	public var leavingObserved:Bool = false;
	public var leavingParentAtDispatch:Null<h2d.Object> = null;

	public function new(sm:ScreenManager) {
		super(sm);
	}

	public function load():Void {}

	public function onScreenEvent(event:bh.ui.UIElement.UIScreenEvent, source:Null<bh.ui.UIElement>):Void {
		switch event {
			case UILeaving:
				leavingObserved = true;
				leavingParentAtDispatch = getSceneRoot().parent;
			default:
		}
	}

	override public function update(dt:Float):Void {}
}
