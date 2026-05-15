package bh.test.examples;

import utest.Assert;
import bh.ui.screens.UIScreen;
import bh.ui.screens.ScreenManager;
import bh.ui.UIElement;
import bh.ui.UIScrollHelper.ScrollConfig;
import bh.test.VisualTestBase;

/**
 * Concrete subclass of UIScrollableScreen for testing.
 */
private class TestScrollableScreen extends bh.ui.screens.UIScrollableScreen {
	public function new(sm:ScreenManager, ?config:ScrollConfig) {
		super(sm, config);
	}

	public function load():Void {}

	public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {}

	public function getScrollContent():h2d.Layers {
		return scrollContent;
	}

	public function getScrollY():Float {
		return scrollY;
	}

	public function getTargetScrollY():Float {
		return targetScrollY;
	}

	public function getScrollContentHeight():Float {
		return scrollContentHeight;
	}

	public function isAutoMeasure():Bool {
		return scrollAutoMeasure;
	}

	public function getScrollSpeed():Float {
		return scrollSpeed;
	}

	public function getScrollSmoothing():Float {
		return scrollSmoothing;
	}

	public function getRoot():h2d.Layers {
		return root;
	}
}

/**
 * Unit tests for UIScrollableScreen.
 * Tests construction, scroll behavior, content routing, cleanup chain, and edge cases.
 */
class UIScrollableScreenTest extends utest.Test {
	var sm:ScreenManager;

	function setup():Void {
		sm = new ScreenManager(VisualTestBase.appInstance);
	}

	function createScreen(?config:ScrollConfig):TestScrollableScreen {
		return new TestScrollableScreen(sm, config);
	}

	// ==================== Construction ====================

	@Test
	public function testDefaultConfig():Void {
		var screen = createScreen();
		Assert.floatEquals(30.0, screen.getScrollSpeed());
		Assert.floatEquals(12.0, screen.getScrollSmoothing());
	}

	@Test
	public function testCustomConfig():Void {
		var screen = createScreen({scrollSpeed: 50, smoothing: 8});
		Assert.floatEquals(50.0, screen.getScrollSpeed());
		Assert.floatEquals(8.0, screen.getScrollSmoothing());
	}

	@Test
	public function testPartialConfig():Void {
		var screen = createScreen({scrollSpeed: 25});
		Assert.floatEquals(25.0, screen.getScrollSpeed());
		Assert.floatEquals(12.0, screen.getScrollSmoothing());
	}

	@Test
	public function testScrollContentIsChildOfRoot():Void {
		var screen = createScreen();
		var root:h2d.Object = screen.getRoot();
		Assert.isTrue(screen.getScrollContent().parent == root);
	}

	// ==================== Content Routing ====================

	@Test
	public function testAddObjectGoesToScrollContent():Void {
		var screen = createScreen();
		var obj = new h2d.Object();
		screen.addObjectToLayer(obj);
		Assert.isTrue(obj.parent == screen.getScrollContent());
	}

	@Test
	public function testAddObjectNotDirectChildOfRoot():Void {
		var screen = createScreen();
		var obj = new h2d.Object();
		screen.addObjectToLayer(obj);
		var root = screen.getRoot();
		var isDirectChild = false;
		for (i in 0...root.numChildren) {
			if (root.getChildAt(i) == obj) {
				isDirectChild = true;
				break;
			}
		}
		Assert.isFalse(isDirectChild);
	}

	@Test
	public function testMultipleObjectsAddedToScrollContent():Void {
		var screen = createScreen();
		var obj1 = new h2d.Object();
		var obj2 = new h2d.Object();
		screen.addObjectToLayer(obj1);
		screen.addObjectToLayer(obj2);
		Assert.isTrue(obj1.parent == screen.getScrollContent());
		Assert.isTrue(obj2.parent == screen.getScrollContent());
	}

	// ==================== Mouse Wheel Scrolling ====================

	@Test
	public function testMouseWheelScrollsWhenContentTallerThanView():Void {
		var screen = createScreen({smoothing: 0});
		screen.setContentHeight(sm.sceneHeight * 2);
		screen.onMouseWheel(new h2d.col.Point(0, 0), 5);
		Assert.isTrue(screen.getScrollY() > 0);
	}

	@Test
	public function testMouseWheelNoScrollWhenContentFitsView():Void {
		var screen = createScreen({smoothing: 0});
		screen.setContentHeight(sm.sceneHeight * 0.5);
		screen.onMouseWheel(new h2d.col.Point(0, 0), 5);
		Assert.floatEquals(0.0, screen.getScrollY());
	}

	@Test
	public function testMouseWheelReturnsTrueWhenContentFits():Void {
		var screen = createScreen({smoothing: 0});
		screen.setContentHeight(sm.sceneHeight * 0.5);
		var result = screen.onMouseWheel(new h2d.col.Point(0, 0), 5);
		Assert.isTrue(result);
	}

	@Test
	public function testMouseWheelReturnsFalseWhenScrolling():Void {
		var screen = createScreen({smoothing: 0});
		screen.setContentHeight(sm.sceneHeight * 2);
		var result = screen.onMouseWheel(new h2d.col.Point(0, 0), 5);
		Assert.isFalse(result);
	}

	@Test
	public function testMouseWheelClampsToMax():Void {
		var screen = createScreen({smoothing: 0});
		var contentH = sm.sceneHeight * 2;
		screen.setContentHeight(contentH);
		screen.onMouseWheel(new h2d.col.Point(0, 0), 10000);
		Assert.floatEquals(contentH - sm.sceneHeight, screen.getScrollY());
	}

	@Test
	public function testMouseWheelClampsToMin():Void {
		var screen = createScreen({smoothing: 0});
		screen.setContentHeight(sm.sceneHeight * 2);
		screen.onMouseWheel(new h2d.col.Point(0, 0), -100);
		Assert.floatEquals(0.0, screen.getScrollY());
	}

	@Test
	public function testMouseWheelInstantModeUpdatesScrollContentY():Void {
		var screen = createScreen({smoothing: 0});
		screen.setContentHeight(sm.sceneHeight * 2);
		screen.onMouseWheel(new h2d.col.Point(0, 0), 5);
		Assert.floatEquals(-screen.getScrollY(), screen.getScrollContent().y);
	}

	@Test
	public function testMouseWheelScrollAmountUsesSpeed():Void {
		var screen = createScreen({scrollSpeed: 10, smoothing: 0});
		screen.setContentHeight(sm.sceneHeight * 10);
		screen.onMouseWheel(new h2d.col.Point(0, 0), 3); // delta * speed = 3 * 10 = 30
		Assert.floatEquals(30.0, screen.getScrollY());
	}

	// ==================== Smooth Scrolling ====================

	@Test
	public function testSmoothScrollSetsTargetNotImmediate():Void {
		var screen = createScreen({smoothing: 12});
		screen.setContentHeight(sm.sceneHeight * 2);
		screen.onMouseWheel(new h2d.col.Point(0, 0), 5);
		Assert.isTrue(screen.getTargetScrollY() > 0);
		Assert.floatEquals(0.0, screen.getScrollY());
	}

	@Test
	public function testSmoothScrollConvergesOnUpdate():Void {
		var screen = createScreen({smoothing: 12});
		screen.setContentHeight(sm.sceneHeight * 2);
		screen.onMouseWheel(new h2d.col.Point(0, 0), 5);
		var target = screen.getTargetScrollY();

		for (_ in 0...100) {
			screen.update(0.016);
		}
		Assert.floatEquals(target, screen.getScrollY());
	}

	@Test
	public function testSmoothScrollUpdatesScrollContentY():Void {
		var screen = createScreen({smoothing: 12});
		screen.setContentHeight(sm.sceneHeight * 2);
		screen.onMouseWheel(new h2d.col.Point(0, 0), 5);
		screen.update(0.016);
		Assert.floatEquals(-screen.getScrollY(), screen.getScrollContent().y);
	}

	// ==================== setContentHeight ====================

	@Test
	public function testSetContentHeightDisablesAutoMeasure():Void {
		var screen = createScreen();
		Assert.isTrue(screen.isAutoMeasure());
		screen.setContentHeight(1000);
		Assert.isFalse(screen.isAutoMeasure());
	}

	@Test
	public function testSetContentHeightUpdatesHeight():Void {
		var screen = createScreen();
		screen.setContentHeight(1000);
		Assert.floatEquals(1000.0, screen.getScrollContentHeight());
	}

	@Test
	public function testSetContentHeightClampsCurrentScroll():Void {
		var screen = createScreen({smoothing: 0});
		var viewH = sm.sceneHeight;
		screen.setContentHeight(viewH * 2);
		screen.onMouseWheel(new h2d.col.Point(0, 0), 10000); // scroll to max
		Assert.floatEquals(viewH, screen.getScrollY()); // max = 2*viewH - viewH = viewH

		// Reduce content height
		screen.setContentHeight(viewH * 1.5); // max = 0.5*viewH
		Assert.floatEquals(viewH * 0.5, screen.getScrollY());
	}

	@Test
	public function testSetContentHeightShorterThanViewClampsToZero():Void {
		var screen = createScreen({smoothing: 0});
		screen.setContentHeight(sm.sceneHeight * 2);
		screen.onMouseWheel(new h2d.col.Point(0, 0), 10);
		Assert.isTrue(screen.getScrollY() > 0);

		screen.setContentHeight(sm.sceneHeight * 0.5);
		Assert.floatEquals(0.0, screen.getScrollY());
		Assert.floatEquals(0.0, screen.getTargetScrollY());
	}

	// ==================== onClear / Cleanup ====================

	@Test
	public function testClearResetsScrollState():Void {
		var screen = createScreen({smoothing: 0});
		screen.setContentHeight(sm.sceneHeight * 2);
		screen.onMouseWheel(new h2d.col.Point(0, 0), 10);
		Assert.isTrue(screen.getScrollY() > 0);

		screen.clear();

		Assert.floatEquals(0.0, screen.getScrollY());
		Assert.floatEquals(0.0, screen.getTargetScrollY());
		Assert.floatEquals(0.0, screen.getScrollContentHeight());
		Assert.isTrue(screen.isAutoMeasure());
	}

	@Test
	public function testClearReattachesScrollContentToRoot():Void {
		var screen = createScreen();
		screen.clear();

		var root:h2d.Object = screen.getRoot();
		Assert.isTrue(screen.getScrollContent().parent == root);
	}

	@Test
	public function testClearRemovesScrollContentChildren():Void {
		var screen = createScreen();

		screen.addObjectToLayer(new h2d.Object());
		screen.addObjectToLayer(new h2d.Object());
		Assert.isTrue(screen.getScrollContent().numChildren > 0);

		screen.clear();

		Assert.equals(0, screen.getScrollContent().numChildren);
	}

	@Test
	public function testClearThenReAddWorks():Void {
		var screen = createScreen();

		screen.addObjectToLayer(new h2d.Object());
		screen.clear();

		var obj = new h2d.Object();
		screen.addObjectToLayer(obj);
		Assert.isTrue(obj.parent == screen.getScrollContent());
	}

	@Test
	public function testMultipleClearCycles():Void {
		var screen = createScreen({smoothing: 0});

		for (_ in 0...3) {
			screen.setContentHeight(sm.sceneHeight * 2);
			screen.onMouseWheel(new h2d.col.Point(0, 0), 10);
			screen.addObjectToLayer(new h2d.Object());
			screen.clear();

			Assert.floatEquals(0.0, screen.getScrollY());
			Assert.isTrue(screen.getScrollContent().parent == screen.getRoot());
			Assert.equals(0, screen.getScrollContent().numChildren);
		}
	}

	@Test
	public function testClearResetsScrollContentY():Void {
		var screen = createScreen({smoothing: 0});
		screen.setContentHeight(sm.sceneHeight * 2);
		screen.onMouseWheel(new h2d.col.Point(0, 0), 10);
		Assert.isTrue(screen.getScrollContent().y < 0);

		screen.clear();

		Assert.floatEquals(0.0, screen.getScrollContent().y);
	}

	// ==================== Edge Cases ====================

	@Test
	public function testZeroSmoothingIsInstant():Void {
		var screen = createScreen({smoothing: 0});
		screen.setContentHeight(sm.sceneHeight * 2);
		screen.onMouseWheel(new h2d.col.Point(0, 0), 5);
		Assert.floatEquals(screen.getTargetScrollY(), screen.getScrollY());
	}

	@Test
	public function testScrollWithExactViewHeight():Void {
		var screen = createScreen({smoothing: 0});
		screen.setContentHeight(sm.sceneHeight); // exactly viewport height
		screen.onMouseWheel(new h2d.col.Point(0, 0), 5);
		Assert.floatEquals(0.0, screen.getScrollY());
	}

	@Test
	public function testScrollUpAndDown():Void {
		var screen = createScreen({scrollSpeed: 10, smoothing: 0});
		screen.setContentHeight(sm.sceneHeight * 10);

		screen.onMouseWheel(new h2d.col.Point(0, 0), 10); // 100px down
		Assert.floatEquals(100.0, screen.getScrollY());

		screen.onMouseWheel(new h2d.col.Point(0, 0), -5); // 50px up
		Assert.floatEquals(50.0, screen.getScrollY());
	}

	@Test
	public function testSmoothScrollSnapsWhenClose():Void {
		var screen = createScreen({smoothing: 100});
		screen.setContentHeight(sm.sceneHeight * 2);
		screen.onMouseWheel(new h2d.col.Point(0, 0), 1);
		var target = screen.getTargetScrollY();

		for (_ in 0...500) {
			screen.update(0.016);
		}

		Assert.floatEquals(target, screen.getScrollY());
	}

	@Test
	public function testUpdateWithNoScrollDoesNothing():Void {
		var screen = createScreen({smoothing: 0});
		screen.setContentHeight(sm.sceneHeight * 0.5);
		var y = screen.getScrollContent().y;
		screen.update(0.016);
		Assert.floatEquals(y, screen.getScrollContent().y);
	}
}
