package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.base.CursorManager;
import bh.ui.UIInteractiveWrapper;
import bh.ui.UIRichInteractiveHelper;
import bh.base.MAObject.MultiAnimObjectData;
import bh.multianim.MultiAnimBuilder.BuilderResult;

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

	// ==================== containsPoint allocation hygiene ====================
	// containsPoint runs every mouse-move per registered interactive — card hand
	// targeting iterates every drop target on every drag tick. The defensive
	// copy that protects the caller's Point from globalToLocal's in-place mutation
	// must be cached, not allocated per call.

	@Test
	public function testContainsPointReusesStaticScratchAcrossCalls():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1"): 0, 0
			}
		', "test");
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);

		// Prime the static scratch.
		var probe = new h2d.col.Point(10, 10);
		wrapper.containsPoint(probe);
		var cached:Dynamic = Reflect.field(UIInteractiveWrapper, "_scratchPt");
		Assert.notNull(cached,
			"UIInteractiveWrapper should expose a cached static _scratchPt h2d.col.Point after containsPoint — got null");

		// Subsequent calls (with different point instances) must reuse the same Point.
		wrapper.containsPoint(new h2d.col.Point(20, 20));
		Assert.equals(cached, Reflect.field(UIInteractiveWrapper, "_scratchPt"),
			"containsPoint must reuse the cached static _scratchPt (no per-call allocation)");

		wrapper.containsPoint(new h2d.col.Point(50, 50));
		Assert.equals(cached, Reflect.field(UIInteractiveWrapper, "_scratchPt"),
			"containsPoint must reuse the cached static _scratchPt across calls");
	}

	// ==================== Hidden conditional-arm interactive is not exposed as a click target ====
	// An interactive eagerly built in the true arm of a runtime-builder conditional must stop being
	// exposed via getInteractives() once the condition flips false. The flip detaches the object from
	// the scene graph (removeChild) but leaves its registration in the static interactives list at
	// stale coords; getInteractives() must reflect the live graph (as codegen does), so the screen's
	// syncInteractivesFrom diff drops the stale wrapper instead of leaving a ghost click target.

	static function getInteractiveIds(result:BuilderResult):Array<String> {
		return [
			for (o in result.getInteractives())
				switch o.multiAnimType { case MAInteractive(_, _, id, _): id; default: null; }
		];
	}

	@Test
	public function testHiddenConditionalInteractiveIsNotExposed():Void {
		var result = BuilderTestBase.buildFromSource('
			#test programmable(open:bool=true) {
				@(open=>true) interactive(100, 30, "btn1"): 0, 0
			}
		', "test", Incremental);

		// Visible arm: interactive is exposed.
		Assert.isTrue(getInteractiveIds(result).indexOf("btn1") >= 0,
			"interactive should be exposed by getInteractives() while the conditional arm is shown");

		// Flip the condition false — the interactive is removed from the scene graph.
		result.setParameter("open", false);
		Assert.equals(-1, getInteractiveIds(result).indexOf("btn1"),
			"interactive must NOT be exposed by getInteractives() after its arm is hidden (ghost click target)");

		// Flip back true — it is exposed again.
		result.setParameter("open", true);
		Assert.isTrue(getInteractiveIds(result).indexOf("btn1") >= 0,
			"interactive should be exposed by getInteractives() again after its arm is shown");
	}

	@Test
	public function testHiddenConditionalNestedInteractiveIsNotExposed():Void {
		// The interactive sits below an extra container inside the hidden arm, so its immediate parent
		// stays non-null when the arm is detached — only an ancestor goes null. getInteractives() must
		// still drop it (reachability walk, not just immediate-parent check).
		var result = BuilderTestBase.buildFromSource('
			#test programmable(open:bool=true) {
				@(open=>true) layers() {
					interactive(100, 30, "nested"): 0, 0
				}
			}
		', "test", Incremental);

		Assert.isTrue(getInteractiveIds(result).indexOf("nested") >= 0,
			"nested interactive should be exposed while its conditional arm is shown");

		result.setParameter("open", false);
		Assert.equals(-1, getInteractiveIds(result).indexOf("nested"),
			"nested interactive must NOT be exposed after its arm is hidden (ancestor detached, immediate parent still set)");

		result.setParameter("open", true);
		Assert.isTrue(getInteractiveIds(result).indexOf("nested") >= 0,
			"nested interactive should be exposed again after its arm is shown");
	}

	@Test
	public function testContainsPointDoesNotMutateCallerPoint():Void {
		// Regression guard: a tempting "fix" is to pass `pos` straight into globalToLocal
		// to avoid the allocation. But globalToLocal mutates in place, and callers
		// (UICardHandTargeting, UIDefaultController.getEventElements) pass the SAME
		// scratch Point across an iteration over multiple interactives. Mutating it
		// would corrupt iteration N+1's input. containsPoint must leave pos untouched.
		var result = BuilderTestBase.buildFromSource('
			#test programmable() {
				bitmap(generated(color(100, 30, #666666))): 0, 0
				interactive(100, 30, "btn1"): 0, 0
			}
		', "test");
		// Position the interactive so globalToLocal is NOT identity — only then can
		// mutation of pos be observed (identity transform would leave pos unchanged
		// even with the wrong fix).
		result.interactives[0].setPosition(40, 25);
		var wrapper = new UIInteractiveWrapper(result.interactives[0], null);

		var pos = new h2d.col.Point(123.0, 77.0);
		wrapper.containsPoint(pos);
		Assert.floatEquals(123.0, pos.x, 0.001,
			"containsPoint must not mutate caller's pos.x (would corrupt iteration over multiple interactives)");
		Assert.floatEquals(77.0, pos.y, 0.001,
			"containsPoint must not mutate caller's pos.y");
	}
}
