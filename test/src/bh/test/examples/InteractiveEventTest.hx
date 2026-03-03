package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness.UITestScreen;
import bh.base.CursorManager;
import bh.ui.UIInteractiveWrapper;
import bh.ui.UIRichInteractiveHelper;
import bh.ui.UIElement.UIScreenEvent;

/**
 * Unit tests for interactive event filtering, metadata, and cursor support.
 * Tests event flag parsing, UIInteractiveWrapper construction, event filtering logic.
 */
class InteractiveEventTest extends BuilderTestBase {
	// ==================== Helpers ====================

	/** Build and return screen + wrappers for the given manim. */
	static function buildWithScreen(manim:String, name:String):{screen:UITestScreen, wrappers:Array<UIInteractiveWrapper>} {
		var screen = new UITestScreen();
		var result = BuilderTestBase.buildFromSource(manim, name, null, Incremental);
		screen.addInteractives(result, null);
		// Collect wrappers from screen
		var wrappers:Array<UIInteractiveWrapper> = [];
		for (interactive in result.interactives) {
			var wrapper = new UIInteractiveWrapper(interactive, null);
			wrappers.push(wrapper);
		}
		return {screen: screen, wrappers: wrappers};
	}

	// ==================== Event Flag Parsing ====================

	@Test
	public function testDefaultEventFlags():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1"): 0, 0
			}
		', "test");
		Assert.notNull(result);
		Assert.isTrue(result.interactives.length > 0);
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		// Default: EVENT_ALL = 7
		Assert.equals(UIInteractiveWrapper.EVENT_ALL, wrapper.eventFlags);
	}

	@Test
	public function testHoverOnlyEventFlags():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1", events: [hover]): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		Assert.equals(UIInteractiveWrapper.EVENT_HOVER, wrapper.eventFlags);
	}

	@Test
	public function testClickOnlyEventFlags():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1", events: [click]): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		Assert.equals(UIInteractiveWrapper.EVENT_CLICK, wrapper.eventFlags);
	}

	@Test
	public function testPushOnlyEventFlags():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1", events: [push]): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		Assert.equals(UIInteractiveWrapper.EVENT_PUSH, wrapper.eventFlags);
	}

	@Test
	public function testHoverAndClickEventFlags():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1", events: [hover, click]): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		var expected = UIInteractiveWrapper.EVENT_HOVER | UIInteractiveWrapper.EVENT_CLICK;
		Assert.equals(expected, wrapper.eventFlags);
	}

	@Test
	public function testAllEventsExplicit():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1", events: [hover, click, push]): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		Assert.equals(UIInteractiveWrapper.EVENT_ALL, wrapper.eventFlags);
	}

	// ==================== Interactive ID ====================

	@Test
	public function testInteractiveId():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "myButton"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		Assert.equals("myButton", wrapper.id);
	}

	@Test
	public function testInteractiveIdWithPrefix():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "myButton"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], "panel");
		Assert.equals("panel.myButton", wrapper.id);
	}

	// ==================== Interactive Metadata ====================

	@Test
	public function testInteractiveMetadataString():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1", action => "buy"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		Assert.notNull(wrapper.metadata);
		Assert.isTrue(wrapper.metadata.has("action"));
	}

	@Test
	public function testInteractiveBindMetadata():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable(status:[normal,hover]=normal) {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1", bind => "status"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		Assert.isTrue(wrapper.metadata.has("bind"));
	}

	// ==================== Disabled State ====================

	@Test
	public function testDisabledInitiallyFalse():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		Assert.isFalse(wrapper.disabled);
	}

	@Test
	public function testDisabledCanBeSet():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		wrapper.disabled = true;
		Assert.isTrue(wrapper.disabled);
	}

	// ==================== Event Constants ====================

	@Test
	public function testEventConstants():Void {
		Assert.equals(1, UIInteractiveWrapper.EVENT_HOVER);
		Assert.equals(2, UIInteractiveWrapper.EVENT_CLICK);
		Assert.equals(4, UIInteractiveWrapper.EVENT_PUSH);
		Assert.equals(7, UIInteractiveWrapper.EVENT_ALL);
	}

	// ==================== Hovered State ====================

	@Test
	public function testHoveredInitiallyFalse():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		Assert.isFalse(wrapper.hovered);
	}

	// ==================== Cursor Support ====================

	@Test
	public function testCursorDefaultPointer():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		// Default interactive cursor is Button (pointer)
		Assert.equals(hxd.Cursor.Button, wrapper.getCursor());
	}

	@Test
	public function testCursorExplicitPointer():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1", cursor => "pointer"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		Assert.equals(hxd.Cursor.Button, wrapper.getCursor());
	}

	@Test
	public function testCursorDisabledFallback():Void {
		// Without cursor.disabled metadata, disabled state falls back to getDefaultCursor (= Default)
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		wrapper.disabled = true;
		Assert.equals(hxd.Cursor.Default, wrapper.getCursor());
	}

	@Test
	public function testCursorHoveredFallback():Void {
		// Without cursor.hover metadata, hovered state falls back to base cursor (= Button)
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		// Simulate hover via Dynamic cast
		var dyn:Dynamic = wrapper;
		dyn.hovered = true;
		// Hovered cursor defaults to base cursor (Button) when no cursor.hover metadata
		Assert.equals(hxd.Cursor.Button, wrapper.getCursor());
	}

	@Test
	public function testCursorExplicitMove():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1", cursor => "move"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		Assert.equals(hxd.Cursor.Move, wrapper.getCursor());
	}

	@Test
	public function testCursorManagerGetRegistered():Void {
		var cursor = CursorManager.getCursor("pointer");
		Assert.equals(hxd.Cursor.Button, cursor);
	}

	@Test
	public function testCursorManagerGetUnregistered():Void {
		var cursor = CursorManager.getCursor("nonexistent");
		Assert.isNull(cursor);
	}

	@Test
	public function testCursorUnknownNameThrows():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1", cursor => "xyzzy"): 0, 0
			}
		', "test");
		try {
			var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
			Assert.fail("Should throw for unregistered cursor name");
		} catch (e:Dynamic) {
			Assert.isTrue(Std.string(e).indexOf("xyzzy") >= 0);
		}
	}
}
