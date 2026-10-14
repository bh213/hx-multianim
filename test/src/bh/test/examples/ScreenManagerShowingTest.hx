package bh.test.examples;

import utest.Assert;
import bh.base.TweenManager.Tween;
import bh.base.TweenManager.TweenProperty;
import bh.ui.screens.ScreenManager;
import bh.ui.screens.ScreenTransition;
import bh.ui.screens.UIScreen;
import bh.ui.UIElement;

/**
 * ScreenManager's public view of what is showing (`showing()`, `isShowing()`) and
 * `reenter()`, which sends a showing screen UILeaving then UIEntering without
 * taking it out of the scene.
 */
@:access(bh.ui.screens.ScreenManager)
class ScreenManagerShowingTest extends utest.Test {
	static function assertScreen(expected:UIScreen, actual:Null<UIScreen>, ?msg:String, ?pos:haxe.PosInfos):Void {
		Assert.equals(expected, actual, msg, pos);
	}

	static function removeRoots(screens:Array<UIScreen>):Void {
		for (s in screens)
			s.getSceneRoot().remove();
	}

	// ==================== showing() / isShowing() ====================

	@Test
	public function testShowingNothing():Void {
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var a = new ProbeScreen(sm);

		final s = sm.showing();
		Assert.isNull(s.base);
		Assert.isNull(s.master);
		Assert.isNull(s.dialog);
		Assert.isNull(s.dialogName);
		Assert.isFalse(sm.isShowing(a));
	}

	@Test
	public function testShowingSingle():Void {
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var a = new ProbeScreen(sm);
		var b = new ProbeScreen(sm);

		sm.switchTo(a);

		final s = sm.showing();
		assertScreen(a, s.base);
		Assert.isNull(s.master);
		Assert.isNull(s.dialog);
		Assert.isNull(s.dialogName);
		Assert.isTrue(sm.isShowing(a));
		Assert.isFalse(sm.isShowing(b));

		removeRoots([a, b]);
	}

	@Test
	public function testShowingMasterAndSingleUnderDialog():Void {
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var master = new ProbeScreen(sm);
		var base = new ProbeScreen(sm);
		var dialog = new ProbeScreen(sm);

		sm.updateScreenMode(MasterAndSingle(master, base));
		var s = sm.showing();
		assertScreen(base, s.base, "MasterAndSingle: base is the single screen");
		assertScreen(master, s.master);
		Assert.isNull(s.dialog);

		sm.modalDialog(dialog, base, "confirm");
		s = sm.showing();
		assertScreen(base, s.base, "under a dialog, base is still the screen below it");
		assertScreen(master, s.master, "under a dialog, master is still the master below it");
		assertScreen(dialog, s.dialog);
		Assert.equals("confirm", s.dialogName);
		Assert.isTrue(sm.isShowing(dialog));
		Assert.isTrue(sm.isShowing(base));
		Assert.isTrue(sm.isShowing(master));

		removeRoots([master, base, dialog]);
	}

	@Test
	public function testShowingDialogOverDialog():Void {
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var main = new ProbeScreen(sm);
		var d1 = new ProbeScreen(sm);
		var d2 = new ProbeScreen(sm);

		sm.switchTo(main);
		sm.modalDialog(d1, main, "d1");
		sm.modalDialog(d2, main, "d2");

		final s = sm.showing();
		assertScreen(main, s.base, "base is found through every dialog in the stack");
		assertScreen(d2, s.dialog, "dialog is the top dialog");
		Assert.equals("d2", s.dialogName);
		Assert.isFalse(sm.isShowing(d1), "a covered dialog is taken out of the scene, so it is not showing");

		removeRoots([main, d1, d2]);
	}

	@Test
	public function testShowingDuringTransitionIsTheNewMode():Void {
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var a = new ProbeScreen(sm);
		var b = new ProbeScreen(sm);

		sm.switchTo(a);
		sm.switchScreen(Single(b), Fade(0.2));
		Assert.isTrue(sm.isTransitioning, "precondition: the switch animates");

		assertScreen(b, sm.showing().base, "during a transition, showing() reports the screen being switched to");
		Assert.isTrue(sm.isShowing(b));
		Assert.isFalse(sm.isShowing(a), "the leaving screen is still drawn but no longer showing");

		sm.finalizeTransition();
		removeRoots([a, b]);
	}

	// ==================== reenter() ====================

	@Test
	public function testReenterSendsLeavingThenEnteringInPlace():Void {
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var a = new ProbeScreen(sm);

		sm.switchTo(a, "first");
		a.events = [];
		sm.reenter(a, "again");

		Assert.equals("UILeaving,Leaving,UIEntering:again,Entering", a.events.join(","),
			"reenter sends the leave events, then the enter events with the new data");
		Assert.isTrue(a.alwaysAttached, "the screen stays in the scene throughout");
		Assert.isTrue(sm.isShowing(a));
		assertScreen(a, sm.showing().base);

		removeRoots([a]);
	}

	@Test
	public function testReenterScreenUnderDialog():Void {
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var a = new ProbeScreen(sm);
		var dialog = new ProbeScreen(sm);

		sm.switchTo(a);
		sm.modalDialog(dialog, a, "confirm");
		a.events = [];
		dialog.events = [];

		sm.reenter(a, 7);

		Assert.equals("UILeaving,Leaving,UIEntering:7,Entering", a.events.join(","));
		Assert.equals(0, dialog.events.length, "the dialog on top is left alone");
		assertScreen(dialog, sm.showing().dialog, "the dialog stays open");
		Assert.isTrue(sm.isShowing(a));

		removeRoots([a, dialog]);
	}

	@Test
	public function testReenterScreenThatIsNotShowingThrows():Void {
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var a = new ProbeScreen(sm);
		var b = new ProbeScreen(sm);

		sm.switchTo(a);
		var error:Null<String> = null;
		try {
			sm.reenter(b);
		} catch (e:Dynamic) {
			error = Std.string(e);
		}
		Assert.notNull(error, "reenter of a screen that is not showing must throw");
		Assert.equals(0, b.events.length, "a screen that is not showing gets no events");

		removeRoots([a, b]);
	}

	@Test
	public function testReenterCancelsTheScreensTweensBeforeEntering():Void {
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var a = new ProbeScreen(sm);
		final child = new h2d.Object(a.getSceneRoot());

		sm.switchTo(a);
		final before = sm.tweens.tween(child, 1.0, [Alpha(0.0)]);
		var during:Null<Tween> = null;
		a.onEnteringTween = () -> {
			during = sm.tweens.tween(child, 1.0, [X(10.0)]);
		};

		sm.reenter(a);

		Assert.isTrue(before.cancelled, "the tween from before reenter is cancelled, as when the screen leaves");
		Assert.notNull(during, "precondition: UIEntering started a tween");
		if (during != null)
			Assert.isFalse(during.cancelled, "a tween started by UIEntering survives");

		removeRoots([a]);
	}

	@Test
	public function testReenterFinishesARunningTransition():Void {
		var sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		var a = new ProbeScreen(sm);
		var b = new ProbeScreen(sm);

		sm.switchTo(a);
		sm.switchScreen(Single(b), Fade(0.2));
		sm.reenter(b);

		Assert.isFalse(sm.isTransitioning, "reenter finishes the running transition first");
		Assert.isNull(a.getSceneRoot().parent, "the screen switched away from has left the scene");

		removeRoots([a, b]);
	}
}

/** Records the lifecycle events it receives and whether its root was attached at each. */
private class ProbeScreen extends UIScreenBase {
	public var events:Array<String> = [];
	public var alwaysAttached:Bool = true;
	public var onEnteringTween:Null<Void -> Void> = null;

	public function new(sm:ScreenManager) {
		super(sm);
	}

	public function load():Void {}

	public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {
		final label = switch event {
			case UILeaving: "UILeaving";
			case UIEntering(data):
				if (onEnteringTween != null)
					onEnteringTween();
				'UIEntering:$data';
			case UIOnControllerEvent(Leaving): "Leaving";
			case UIOnControllerEvent(Entering): "Entering";
			default: null;
		};
		if (label == null)
			return;
		events.push(label);
		if (getSceneRoot().parent == null)
			alwaysAttached = false;
	}

	override public function update(dt:Float):Void {}
}
