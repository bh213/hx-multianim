package bh.test.examples;

import utest.Assert;
import bh.test.UITestHarness.UITestScreen;
import bh.ui.UIElement;
import bh.ui.UIElement.UIElementCustomAddToLayer;
import bh.ui.UIElement.UIElementCustomAddToLayerResult;
import bh.ui.screens.UIScreen.LayersEnum;
import bh.ui.screens.UIScreen.UIScreenBase;
import h2d.col.Point;

/**
 * Element that defers its scene-graph placement so the screen queues it in
 * postCustomAddToLayer and drains it on the next update().
 */
private class PostponedElement implements UIElement implements UIElementCustomAddToLayer {
	var obj:h2d.Object;
	public var drainCalls:Int = 0;

	public function new() {
		obj = new h2d.Object();
	}

	public function getObject():h2d.Object return obj;
	public function containsPoint(pos:Point):Bool return false;
	public function clear():Void {}

	public function customAddToLayer(requestedLayer:Null<LayersEnum>, screen:bh.ui.screens.UIScreen, updateMode:Bool):UIElementCustomAddToLayerResult {
		if (updateMode) {
			drainCalls++;
			return Added;
		}
		return Postponed;
	}
}

/**
 * Watchdog for UIScreenBase.update(): the postponed customAddToLayer queue must
 * not be iterated (which allocates a key-value iterator) when nothing is queued.
 */
class UIScreenUpdateAllocationTest extends utest.Test {
	public function new() {
		super();
	}

	@Test
	public function testUpdateSkipsPostponedDrainWhenQueueEmpty():Void {
		var screen = new UITestScreen();

		// Warm-up tick — settle any first-time work.
		screen.update(0.016);

		// Empty steady state: no postponed elements queued. The drain loop must
		// not run (no key-value iterator allocated) on any of these frames.
		final baseline = UIScreenBase.postponedDrainCount;
		for (i in 0...30)
			screen.update(0.016);
		Assert.equals(0, UIScreenBase.postponedDrainCount - baseline,
			"update() must not iterate the postponed queue when empty. Got "
			+ (UIScreenBase.postponedDrainCount - baseline) + " drains across 30 frames.");

		// Queue one postponed element — the next update() must drain exactly once.
		var element = new PostponedElement();
		screen.testAddElement(element, DefaultLayer);
		final beforeDrain = UIScreenBase.postponedDrainCount;
		screen.update(0.016);
		Assert.equals(1, UIScreenBase.postponedDrainCount - beforeDrain,
			"update() must drain exactly once when an element is queued.");
		Assert.equals(1, element.drainCalls, "the postponed element must be drained.");

		// Queue is empty again: no further drains.
		final afterDrain = UIScreenBase.postponedDrainCount;
		for (i in 0...30)
			screen.update(0.016);
		Assert.equals(0, UIScreenBase.postponedDrainCount - afterDrain,
			"update() must not iterate the postponed queue after it has been drained. Got "
			+ (UIScreenBase.postponedDrainCount - afterDrain) + " drains across 30 frames.");
	}
}
