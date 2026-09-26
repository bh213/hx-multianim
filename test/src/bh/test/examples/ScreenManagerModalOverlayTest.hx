package bh.test.examples;

import utest.Assert;
import bh.ui.UIElement;
import bh.ui.screens.ScreenManager;
import bh.ui.screens.UIScreen;
import bh.ui.screens.UIScreen.ModalOverlayConfig;
import bh.test.VisualTestBase;

/** Minimal caller screen — no content. */
private class BgScreen extends bh.ui.screens.UIScreenBase {
	public function new(sm:ScreenManager) {
		super(sm);
	}

	public function load():Void {}

	public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {}
}

/** Dialog screen that declares its ModalOverlayConfig during load(). */
private class DialogWithOverlay extends bh.ui.screens.UIScreenBase {
	final overlayCfg:ModalOverlayConfig;

	public function new(sm:ScreenManager, cfg:ModalOverlayConfig) {
		super(sm);
		this.overlayCfg = cfg;
	}

	public function load():Void {
		this.modalOverlayConfig = this.overlayCfg;
	}

	public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {}
}

/**
 * Regression tests for ScreenManager modal overlay lifecycle across
 * Dialog → Dialog transitions.
 *
 * Bug: `modalDialog(d2, ...)` while a dialog is already open would overwrite
 * `modalOverlay` with a fresh bitmap and then have `updateScreenMode`'s
 * top-of-Dialog-case `removeModalOverlay()` immediately destroy it — leaving
 * the first dialog's overlay orphaned in the scene and the new dialog with
 * no overlay at all.
 */
@:access(bh.ui.screens.ScreenManager)
class ScreenManagerModalOverlayTest extends utest.Test {
	var sm:ScreenManager;
	var caller:BgScreen;
	var savedScaleMode:h2d.Scene.ScaleMode;

	function setup():Void {
		sm = new ScreenManager(VisualTestBase.appInstance);
		caller = new BgScreen(sm);
		sm.switchTo(caller);
		savedScaleMode = VisualTestBase.appInstance.s2d.scaleMode;
	}

	function teardown():Void {
		// The scene is shared with the visual tests: put its size back and drop the overlay.
		VisualTestBase.appInstance.s2d.scaleMode = savedScaleMode;
		sm.removeModalOverlay();
	}

	/**
	 * The overlay used to be a fixed 4096×4096 bitmap, which stops short of the
	 * edge on a 5K canvas or an AutoZoom-scaled scene. It must be sized to the scene.
	 */
	@Test
	public function testOverlayIsSizedToScene():Void {
		final s2d = VisualTestBase.appInstance.s2d;
		var d = new DialogWithOverlay(sm, {color: 0x000000, alpha: 0.5});
		sm.modalDialog(d, caller, "d");

		var overlay = sm.modalOverlay;
		Assert.notNull(overlay);
		if (overlay == null) return;
		Assert.floatEquals(s2d.width, overlay.tile.width, "overlay width must match the scene width");
		Assert.floatEquals(s2d.height, overlay.tile.height, "overlay height must match the scene height");
	}

	/**
	 * A scene resize while the dialog is open (window resize, scaleMode change)
	 * must refit the overlay on the next update() — in both directions.
	 */
	@Test
	public function testOverlayRefitsWhenSceneResizes():Void {
		final s2d = VisualTestBase.appInstance.s2d;
		var d = new DialogWithOverlay(sm, {color: 0x000000, alpha: 0.5});
		sm.modalDialog(d, caller, "d");

		var overlay = sm.modalOverlay;
		Assert.notNull(overlay);
		if (overlay == null) return;

		// Larger than the old fixed bitmap in both dimensions.
		s2d.scaleMode = Stretch(5120, 4320);
		Assert.equals(5120, s2d.width, "precondition: the scaleMode change resized the scene");
		sm.update(1 / 60);
		Assert.floatEquals(5120, overlay.tile.width, "overlay must grow to the new scene width");
		Assert.floatEquals(4320, overlay.tile.height, "overlay must grow to the new scene height");

		s2d.scaleMode = Stretch(640, 360);
		sm.update(1 / 60);
		Assert.floatEquals(640, overlay.tile.width, "overlay must shrink to the new scene width");
		Assert.floatEquals(360, overlay.tile.height, "overlay must shrink to the new scene height");
	}

	@Test
	public function testDialogOverDialogKeepsNewOverlay():Void {
		var d1 = new DialogWithOverlay(sm, {color: 0xFF0000, alpha: 0.5});
		sm.modalDialog(d1, caller, "d1");

		var overlay1 = sm.modalOverlay;
		Assert.notNull(overlay1);

		var d2 = new DialogWithOverlay(sm, {color: 0x00FF00, alpha: 0.7});
		sm.modalDialog(d2, caller, "d2");

		// The new dialog must end up with a live overlay.
		var overlay2 = sm.modalOverlay;
		Assert.notNull(overlay2, "modalDialog over an existing dialog must produce an overlay");
		if (overlay2 != null)
			Assert.notNull(overlay2.parent, "new overlay must be attached to the scene graph");

		// The previous overlay must not linger in the scene (leak check).
		if (overlay1 != null)
			Assert.isNull(overlay1.parent, "previous overlay must be removed from the scene graph");
	}

	/**
	 * The `exclude` parameter of `applyBlurToUnderlyingScreens` silently degrades to
	 * a no-op if the excluded screen isn't in `activeScreens` at call time. That
	 * makes the contract between `modalDialog` (which flips the ordering so the
	 * new dialog is in `activeScreens` before blur applies) and this helper
	 * fragile — a future refactor could restore the natural "prepare overlay
	 * before mode switch" ordering and silently blur the new dialog.
	 *
	 * The helper must reject an `exclude` that is not currently active.
	 */
	@Test
	public function testApplyBlurExcludeMustBeInActiveScreens():Void {
		var stranger = new BgScreen(sm);
		// `stranger` was never activated via switchTo/modalDialog, so it is not in activeScreens.
		Assert.isFalse(sm.activeScreens.contains(stranger),
			"precondition: stranger must not be in activeScreens");

		var threw = false;
		try {
			sm.applyBlurToUnderlyingScreens(4.0, stranger);
		} catch (_:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw,
			"applyBlurToUnderlyingScreens must throw when `exclude` is not in activeScreens — "
			+ "otherwise the exclude silently becomes a no-op and a future caller re-ordering "
			+ "would apply blur to the wrong screens");
	}
}
