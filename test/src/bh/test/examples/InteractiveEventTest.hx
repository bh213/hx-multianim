package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.base.CursorManager;
import bh.ui.UIInteractiveWrapper;
import bh.ui.UIRichInteractiveHelper;

/**
 * Unit tests for interactive event filtering, metadata, and cursor support.
 * Tests event flag parsing, UIInteractiveWrapper construction, event filtering logic.
 */
class InteractiveEventTest extends BuilderTestBase {
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
		// Without cursor.hover metadata, hovered state falls back to base cursor.
		// Use cursor => "move" so base cursor is Move (not default Button),
		// proving that hover actually returns the base cursor, not a hardcoded default.
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1", cursor => "move"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		// Before hover: base cursor is Move
		Assert.equals(hxd.Cursor.Move, wrapper.getCursor());
		// Simulate hover via Dynamic cast (hovered is (default, null) property)
		var dyn:Dynamic = wrapper;
		dyn.hovered = true;
		// Hovered cursor should fall back to base cursor (Move), not default interactive cursor (Button)
		Assert.equals(hxd.Cursor.Move, wrapper.getCursor());
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

	// ==================== Cursor State Metadata ====================

	@Test
	public function testCursorExplicitHoverState():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1", cursor.hover => "move"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		// Non-hovered: default interactive cursor (Button)
		Assert.equals(hxd.Cursor.Button, wrapper.getCursor());
		// Simulate hover via Dynamic cast (hovered is (default, null) property)
		var dyn:Dynamic = wrapper;
		dyn.hovered = true;
		// Hovered: explicit cursor.hover => "move" overrides base cursor
		Assert.equals(hxd.Cursor.Move, wrapper.getCursor());
	}

	@Test
	public function testCursorExplicitDisabledState():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1", cursor.disabled => "text"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		// Non-disabled: default interactive cursor (Button)
		Assert.equals(hxd.Cursor.Button, wrapper.getCursor());
		// Set disabled
		wrapper.disabled = true;
		// Disabled: explicit cursor.disabled => "text" overrides default disabled cursor
		Assert.equals(hxd.Cursor.TextInput, wrapper.getCursor());
	}

	@Test
	public function testCursorHoverAndDisabledCombined():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1", cursor.hover => "move", cursor.disabled => "text"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		// Base state: default interactive cursor (Button)
		Assert.equals(hxd.Cursor.Button, wrapper.getCursor());
		// Hovered: cursor.hover => "move"
		var dyn:Dynamic = wrapper;
		dyn.hovered = true;
		Assert.equals(hxd.Cursor.Move, wrapper.getCursor());
		// Clear hover, set disabled
		dyn.hovered = false;
		wrapper.disabled = true;
		Assert.equals(hxd.Cursor.TextInput, wrapper.getCursor());
		// Both hovered AND disabled: disabled takes priority
		dyn.hovered = true;
		Assert.equals(hxd.Cursor.TextInput, wrapper.getCursor());
	}

	@Test
	public function testCursorInvalidSuffixThrows():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1", cursor.foobar => "pointer"): 0, 0
			}
		', "test");
		try {
			var wrapper = new UIInteractiveWrapper(result.interactives[0], null);
			Assert.fail("Should throw for invalid cursor suffix");
		} catch (e:Dynamic) {
			Assert.isTrue(Std.string(e).indexOf("foobar") >= 0);
		}
	}
}
