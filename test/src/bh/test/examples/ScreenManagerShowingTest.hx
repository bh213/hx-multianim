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
	final managers:Array<ScreenManager> = [];

	/** A screen manager disposed after the test, so it stops hearing the window's input. */
	function newManager(?loader:bh.base.ResourceLoader.CachingResourceLoader):ScreenManager {
		final sm = new ScreenManager(bh.test.VisualTestBase.appInstance, loader);
		managers.push(sm);
		return sm;
	}

	function teardown():Void {
		for (sm in managers)
			sm.dispose();
		managers.resize(0);
	}

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
		var sm = newManager();
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
		var sm = newManager();
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
		var sm = newManager();
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
		var sm = newManager();
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
		var sm = newManager();
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
		var sm = newManager();
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
		var sm = newManager();
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
		var sm = newManager();
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
		var sm = newManager();
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
		var sm = newManager();
		var a = new ProbeScreen(sm);
		var b = new ProbeScreen(sm);

		sm.switchTo(a);
		sm.switchScreen(Single(b), Fade(0.2));
		sm.reenter(b);

		Assert.isFalse(sm.isTransitioning, "reenter finishes the running transition first");
		Assert.isNull(a.getSceneRoot().parent, "the screen switched away from has left the scene");

		removeRoots([a, b]);
	}

	// ==================== loader ====================

	// A game's code plays a character's `.anim` through the screen manager's loader, the
	// one the manager builds every `.manim` with — no `@:privateAccess`. The probe is a
	// plain class outside the test class's `@:access`, like an actor a game's screen makes
	// (a screen itself is let in by `@:allow(bh.ui.screens.UIScreen)`, a subclass too).
	@Test
	public function testAGamesCodeMakesAnAnimsStateMachineThroughTheManagersLoader():Void {
		final loader = bh.test.TestResourceLoader.createLoader(false);
		var sm = newManager(loader);
		var a = new LoaderProbe(sm);

		Assert.equals(loader, a.managersLoader(), "the loader the manager was given");
		final animSM = a.makeAnimSM("marine.anim", "l");
		animSM.play("idle");
		Assert.equals("idle", animSM.current.name);
		animSM.remove();
	}

	// ==================== reload() ====================

	static final ITEM_NARROW = "version: 1.0\n#item programmable() {\n\tbitmap(generated(color(10, 10, #ff0000))): 0, 0\n}\n";
	static final ITEM_WIDE = "version: 1.0\n#item programmable() {\n\tbitmap(generated(color(99, 10, #ff0000))): 0, 0\n}\n";
	// The block is never closed
	static final ITEM_BROKEN = "version: 1.0\n#item programmable() {\n\tbitmap(generated(color(10, 10, #ff0000))): 0, 0\n";

	/** Runs `body` with `test/res/<fileName>` holding `content`; the file is deleted afterwards. */
	static function withTempManim(fileName:String, content:String, body:String -> Void):Void {
		final filePath = "test/res/" + fileName;
		sys.io.File.saveContent(filePath, content);
		var caught:Null<Dynamic> = null;
		try {
			body(filePath);
		} catch (e:Dynamic) {
			caught = e;
		}
		if (sys.FileSystem.exists(filePath))
			sys.FileSystem.deleteFile(filePath);
		if (caught != null)
			throw caught;
	}

	/** The width of the one bitmap `screen` shows, or -1 when it shows none or several. */
	static function shownItemWidth(screen:UIScreen):Int {
		final bitmaps = bh.test.BuilderTestBase.findVisibleBitmapDescendants(screen.getSceneRoot());
		return bitmaps.length == 1 ? Std.int(bitmaps[0].tile.width) : -1;
	}

	@Test
	public function testReloadBuildsTheScreensFromTheFilesNewText():Void {
		// reload() asked the loader for each file before clearing the loader's cache, got the old
		// parse back and kept it: the screens were loaded again, from the text of before.
		withTempManim("screen-reload-tmp.manim", ITEM_NARROW, filePath -> {
			var sm = newManager();
			var screen = new FileScreen(sm, "screen-reload-tmp.manim");
			sm.addScreen("file", screen);
			sm.switchTo(screen);
			Assert.equals(10, shownItemWidth(screen), "precondition: the screen shows the file as first written");

			sys.io.File.saveContent(filePath, ITEM_WIDE);
			final result = sm.reload();

			Assert.isTrue(result.success, "the reload: " + result.error);
			Assert.equals(2, screen.loads, "precondition: the reload loads the screen again");
			Assert.equals(99, shownItemWidth(screen), "a reloaded screen must be built from the file's new text");

			removeRoots([screen]);
		});
	}

	@Test
	public function testReloadReportsAnErrorInTheFilesNewTextAndKeepsTheScreens():Void {
		withTempManim("screen-reload-broken-tmp.manim", ITEM_NARROW, filePath -> {
			var sm = newManager();
			var screen = new FileScreen(sm, "screen-reload-broken-tmp.manim");
			sm.addScreen("file", screen);
			sm.switchTo(screen);

			sys.io.File.saveContent(filePath, ITEM_BROKEN);
			final failed = sm.reload(null, false);

			Assert.isFalse(failed.success, "a file that no longer parses must fail the reload");
			Assert.notNull(failed.error, "with the error");
			Assert.equals(1, screen.loads, "the screens are left as they were");
			Assert.equals(10, shownItemWidth(screen), "showing what they showed");

			sys.io.File.saveContent(filePath, ITEM_WIDE);
			final result = sm.reload(null, false);
			Assert.isTrue(result.success, "the reload of the mended file: " + result.error);
			Assert.equals(99, shownItemWidth(screen), "the mended file is read");

			removeRoots([screen]);
		});
	}

	static final ITEM_ONE_CURSOR = "version: 1.0\n#c cursor { reloadTmpOld: generated(color(4, 4, #FF0000)), hot: 1, 1 }\n"
		+ "#item programmable() {\n\tbitmap(generated(color(10, 10, #ff0000))): 0, 0\n}\n";
	// The second cursor's name is one code has registered: taking the file's cursors fails after the first
	static final ITEM_CURSOR_CLASH = "version: 1.0\n#c cursor {\n\treloadTmpNew: generated(color(4, 4, #FF0000)), hot: 1, 1\n"
		+ "\treloadTmpCode: generated(color(4, 4, #FF0000)), hot: 1, 1\n}\n"
		+ "#item programmable() {\n\tbitmap(generated(color(10, 10, #ff0000))): 0, 0\n}\n";

	@Test
	public function testFailedReloadLeavesTheCursorsOfTheTextBefore():Void {
		// A file that failed while its blocks were taken had taken some of them: the screens went
		// back to the builders of before, the registered names stayed those of the text that failed.
		final names = ["reloadTmpOld", "reloadTmpNew", "reloadTmpCode"];
		var caught:Null<Dynamic> = null;
		try {
			withTempManim("screen-reload-cursor-tmp.manim", ITEM_ONE_CURSOR, filePath -> {
				var sm = newManager();
				var screen = new FileScreen(sm, "screen-reload-cursor-tmp.manim");
				sm.addScreen("file", screen);
				sm.switchTo(screen);
				Assert.notNull(bh.base.CursorManager.getCursor("reloadTmpOld"), "precondition: the file's cursor is registered as it loads");

				bh.base.CursorManager.registerCursor("reloadTmpCode", hxd.Cursor.Move);
				sys.io.File.saveContent(filePath, ITEM_CURSOR_CLASH);
				final failed = sm.reload(null, false);

				Assert.isFalse(failed.success, "precondition: a cursor named like one code registered fails the reload");
				Assert.equals(1, screen.loads, "precondition: the screens are left as they were");
				Assert.isNull(bh.base.CursorManager.getCursor("reloadTmpNew"), "a failed reload must leave no cursor of the text that failed");
				Assert.notNull(bh.base.CursorManager.getCursor("reloadTmpOld"), "and keep those of the text before");

				removeRoots([screen]);
			});
		} catch (e:Dynamic) {
			caught = e;
		}
		for (name in names)
			bh.base.CursorManager.unregisterCursor(name);
		if (caught != null)
			throw caught;
	}

	// ==================== dispose() ====================

	@Test
	public function testDisposeDetachesTheManagerFromTheWindowsEvents():Void {
		final window = hxd.Window.getInstance();
		final before = @:privateAccess window.eventTargets.length;
		var sm = newManager();
		Assert.equals(before + 1, @:privateAccess window.eventTargets.length, "precondition: a new manager listens to the window");

		sm.dispose();
		Assert.equals(before, @:privateAccess window.eventTargets.length, "a disposed manager no longer hears the window's input");
	}
}

/** Not a screen: an actor factory a game hands its screen manager, reaching the loader. */
private class LoaderProbe {
	final screenManager:ScreenManager;

	public function new(sm:ScreenManager) {
		screenManager = sm;
	}

	public function managersLoader():bh.base.ResourceLoader.CachingResourceLoader {
		return screenManager.loader;
	}

	public function makeAnimSM(file:String, facing:String):bh.stateanim.AnimationSM {
		return screenManager.loader.createAnimSM(file, ["direction" => facing]);
	}
}

/** Builds `item` from a file on every load, counting loads. */
private class FileScreen extends UIScreenBase {
	final fileName:String;

	public var loads:Int = 0;

	public function new(sm:ScreenManager, fileName:String) {
		super(sm);
		this.fileName = fileName;
	}

	public function load():Void {
		loads++;
		final builder = screenManager.buildFromResourceName(fileName, false);
		addObjectToLayer(builder.buildWithParameters("item", new Map(), null, null, true).object);
	}

	public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {}
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
