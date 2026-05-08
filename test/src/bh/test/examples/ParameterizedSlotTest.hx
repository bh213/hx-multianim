package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.BuildMode;
import bh.test.BuilderTestBase.buildFromSource;

/**
 * Unit tests for parameterized slots:
 * slot construction, setParameter, setContent, clear, isEmpty, isOccupied, data,
 * indexed slots, conditional rendering inside slot body.
 */
class ParameterizedSlotTest extends BuilderTestBase {
	// ==================== Basic Slot ====================

	@Test
	public function testBasicSlotBuilds():Void {
		final result = buildFromSource("
			#test programmable() {
				#mySlot slot {
					bitmap(generated(color(10, 10, #555555))): 0, 0
				}
			}
		", "test");
		Assert.notNull(result);
		var slot = result.getSlot("mySlot");
		Assert.notNull(slot);
	}

	@Test
	public function testSlotIsEmptyInitially():Void {
		final result = buildFromSource("
			#test programmable() {
				#mySlot slot {
					bitmap(generated(color(10, 10, #555555))): 0, 0
				}
			}
		", "test");
		var slot = result.getSlot("mySlot");
		Assert.isTrue(slot.isEmpty());
		Assert.isFalse(slot.isOccupied());
	}

	@Test
	public function testSlotSetContent():Void {
		final result = buildFromSource("
			#test programmable() {
				#mySlot slot {
					bitmap(generated(color(10, 10, #555555))): 0, 0
				}
			}
		", "test");
		var slot = result.getSlot("mySlot");
		var obj = new h2d.Object();
		slot.setContent(obj);
		Assert.isTrue(slot.isOccupied());
		Assert.isFalse(slot.isEmpty());
		Assert.equals(obj, slot.getContent());
	}

	@Test
	public function testSlotClear():Void {
		final result = buildFromSource("
			#test programmable() {
				#mySlot slot {
					bitmap(generated(color(10, 10, #555555))): 0, 0
				}
			}
		", "test");
		var slot = result.getSlot("mySlot");
		slot.setContent(new h2d.Object());
		Assert.isTrue(slot.isOccupied());
		slot.clear();
		Assert.isTrue(slot.isEmpty());
		Assert.isNull(slot.getContent());
	}

	@Test
	public function testSlotData():Void {
		final result = buildFromSource("
			#test programmable() {
				#mySlot slot {
					bitmap(generated(color(10, 10, #555555))): 0, 0
				}
			}
		", "test");
		var slot = result.getSlot("mySlot");
		Assert.isNull(slot.data);
		slot.data = "myPayload";
		Assert.equals("myPayload", slot.data);
	}

	// ==================== Parameterized Slot ====================

	@Test
	public function testParameterizedSlotBuilds():Void {
		final result = buildFromSource("
			#test programmable() {
				#mySlot slot(color:[red,green]=green) {
					@(color => green) bitmap(generated(color(20, 20, #00ff00))): 0, 0
					@(color => red) bitmap(generated(color(20, 20, #ff0000))): 0, 0
				}
			}
		", "test");
		Assert.notNull(result);
		var slot = result.getSlot("mySlot");
		Assert.notNull(slot);
	}

	@Test
	public function testParameterizedSlotSetParameter():Void {
		final result = buildFromSource("
			#test programmable() {
				#mySlot slot(color:[red,green]=green) {
					@(color => green) bitmap(generated(color(20, 20, #00ff00))): 0, 0
					@(color => red) bitmap(generated(color(20, 20, #ff0000))): 0, 0
				}
			}
		", "test", null, Incremental);
		var slot = result.getSlot("mySlot");
		Assert.notNull(slot);
		if (slot == null) return;
		// Slot should still be empty (no content set), but decoration should be visible
		Assert.isTrue(slot.isEmpty());
		// Change parameter from green to red
		slot.setParameter("color", "red");
		// Slot should still be structurally intact after parameter change
		Assert.isTrue(slot.isEmpty());
		Assert.notNull(slot);
	}

	@Test
	public function testParameterizedSlotWithBoolParam():Void {
		final result = buildFromSource("
			#test programmable() {
				#mySlot slot(active:bool=false) {
					@(active => true) bitmap(generated(color(20, 20, #00ff00))): 0, 0
					@(active => false) bitmap(generated(color(20, 20, #ff0000))): 0, 0
				}
			}
		", "test", null, Incremental);
		var slot = result.getSlot("mySlot");
		Assert.notNull(slot);
		if (slot == null) return;
		// Verify slot is intact before parameter change
		Assert.isTrue(slot.isEmpty());
		// Toggle active from false to true
		slot.setParameter("active", true);
		// Slot should remain structurally valid after boolean parameter change
		Assert.isTrue(slot.isEmpty());
		Assert.notNull(result.getSlot("mySlot"));
	}

	@Test
	public function testParameterizedSlotSetContent():Void {
		final result = buildFromSource("
			#test programmable() {
				#mySlot slot(status:[normal,hover]=normal) {
					@(status => normal) bitmap(generated(color(20, 20, #888888))): 0, 0
					@(status => hover) bitmap(generated(color(20, 20, #ffff00))): 0, 0
				}
			}
		", "test", null, Incremental);
		var slot = result.getSlot("mySlot");
		// Content goes into a separate contentRoot
		var content = new h2d.Object();
		slot.setContent(content);
		Assert.isTrue(slot.isOccupied());
		Assert.equals(content, slot.getContent());
	}

	// ==================== Indexed Slot ====================

	@Test
	public function testIndexedSlotBuilds():Void {
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, step(3, dx: 20)) {
					#item[$i] slot {
						bitmap(generated(color(10, 10, #555555))): 0, 0
					}
				}
			}
		", "test");
		Assert.notNull(result);
		var slot0 = result.getSlot("item", 0);
		Assert.notNull(slot0);
		var slot1 = result.getSlot("item", 1);
		Assert.notNull(slot1);
		var slot2 = result.getSlot("item", 2);
		Assert.notNull(slot2);
	}

	@Test
	public function testIndexedSlotIndependence():Void {
		final result = buildFromSource("
			#test programmable() {
				repeatable($i, step(3, dx: 20)) {
					#item[$i] slot {
						bitmap(generated(color(10, 10, #555555))): 0, 0
					}
				}
			}
		", "test");
		var slot0 = result.getSlot("item", 0);
		var slot1 = result.getSlot("item", 1);
		slot0.setContent(new h2d.Object());
		Assert.isTrue(slot0.isOccupied());
		Assert.isTrue(slot1.isEmpty());
	}

	// ==================== Slot Mismatch Errors ====================

	@Test
	public function testSlotNonexistentThrows():Void {
		final result = buildFromSource("
			#test programmable() {
				#mySlot slot {
					bitmap(generated(color(10, 10, #555555))): 0, 0
				}
			}
		", "test");
		var err:String = null;
		try {
			result.getSlot("nonexistent");
		} catch (e:Dynamic) {
			err = Std.string(e);
		}
		Assert.notNull(err);
	}

	@Test
	public function testNonIndexedSlotAccessedWithIndexThrows():Void {
		final result = buildFromSource("
			#test programmable() {
				#mySlot slot {
					bitmap(generated(color(10, 10, #555555))): 0, 0
				}
			}
		", "test");
		var err:String = null;
		try {
			result.getSlot("mySlot", 0);
		} catch (e:Dynamic) {
			err = Std.string(e);
		}
		Assert.notNull(err);
	}

	@Test
	public function testNonParameterizedSlotSetParameterThrows():Void {
		final result = buildFromSource("
			#test programmable() {
				#mySlot slot {
					bitmap(generated(color(10, 10, #555555))): 0, 0
				}
			}
		", "test");
		var slot = result.getSlot("mySlot");
		var err:String = null;
		var builderErr:Null<bh.multianim.BuilderError> = null;
		try {
			slot.setParameter("anything", "value");
		} catch (e:Dynamic) {
			err = Std.string(e);
			if (Std.isOfType(e, bh.multianim.BuilderError)) builderErr = cast e;
		}
		Assert.notNull(err);
		Assert.notNull(builderErr, "throw must be a BuilderError");
		if (builderErr != null)
			Assert.equals("slot_no_parameters", builderErr.code, "BuilderError.code for non-parameterized slot");
	}

	// Retained SlotHandle whose enclosing subtree was torn down (SWITCH arm swap,
	// repeatable shrinkage, ...) must reject setParameter instead of silently
	// mutating orphaned h2d.Objects. The entry is evicted from ir.slots by
	// removeRegistrationsUnder, but the external handle's incrementalContext is
	// still live — without a disposed flag, the call cascades into stale
	// conditionalEntries / trackedExpressions pointing at detached objects.
	@Test
	public function testParameterizedSlotSetParameterThrowsAfterArmSwap():Void {
		final result = buildFromSource("
			#test programmable(mode:[active, dormant]=active) {
				@switch(mode) {
					active {
						#panel slot(color:[red, green]=green) {
							@(color => green) bitmap(generated(color(20, 20, #00ff00))): 0, 0
							@(color => red)   bitmap(generated(color(20, 20, #ff0000))): 0, 0
						}
					}
					dormant {
						bitmap(generated(color(20, 20, #222222))): 0, 0
					}
				}
			}
		", "test", null, Incremental);
		final slot = result.getSlot("panel");
		Assert.notNull(slot);
		if (slot == null) return;

		// Sanity: slot is live before the arm swap.
		slot.setParameter("color", "red");

		// Swap SWITCH arm — active arm (which owns the slot subtree) is torn down.
		// cleanupDestroyedSubtree -> removeRegistrationsUnder evicts the slot
		// from ir.slots. The retained `slot` reference above is now stale.
		result.setParameter("mode", "dormant");

		var err:String = null;
		var builderErr:Null<bh.multianim.BuilderError> = null;
		try {
			slot.setParameter("color", "green");
		} catch (e:Dynamic) {
			err = Std.string(e);
			if (Std.isOfType(e, bh.multianim.BuilderError)) builderErr = cast e;
		}
		Assert.notNull(err, "setParameter on disposed SlotHandle should throw");
		if (err != null)
			Assert.isTrue(err.indexOf("disposed") >= 0,
				'error message should mention "disposed", got: $err');
		Assert.notNull(builderErr, "throw must be a BuilderError");
		if (builderErr != null)
			Assert.equals("slot_disposed", builderErr.code, "BuilderError.code for disposed slot");
	}

	// Same disposal contract for setContent / clear / getContent / isEmpty / isOccupied.
	// Without the guard, setContent(obj) on a disposed handle silently attaches obj to
	// an orphaned container (no scene parent) — the node never renders, no error fires.
	// The read methods would return stale state from the torn-down subtree, hiding the
	// fact that the caller's handle is no longer authoritative.
	@Test
	public function testSlotMethodsThrowAfterArmSwap():Void {
		final result = buildFromSource("
			#test programmable(mode:[active, dormant]=active) {
				@switch(mode) {
					active {
						#panel slot {
							bitmap(generated(color(20, 20, #00ff00))): 0, 0
						}
					}
					dormant {
						bitmap(generated(color(20, 20, #222222))): 0, 0
					}
				}
			}
		", "test", null, Incremental);
		final slot = result.getSlot("panel");
		Assert.notNull(slot);
		if (slot == null) return;

		// Sanity: slot is live before the arm swap.
		slot.setContent(new h2d.Object());
		slot.clear();

		// Tear down the active arm — slot is now disposed.
		result.setParameter("mode", "dormant");

		function expectDisposed(label:String, action:Void -> Void):Void {
			var err:String = null;
			var builderErr:Null<bh.multianim.BuilderError> = null;
			try {
				action();
			} catch (e:Dynamic) {
				err = Std.string(e);
				if (Std.isOfType(e, bh.multianim.BuilderError)) builderErr = cast e;
			}
			Assert.notNull(err, '$label on disposed SlotHandle should throw');
			Assert.notNull(builderErr, '$label throw must be a BuilderError');
			if (builderErr != null)
				Assert.equals("slot_disposed", builderErr.code, '$label BuilderError.code');
		}

		expectDisposed("setContent", () -> slot.setContent(new h2d.Object()));
		expectDisposed("clear", () -> slot.clear());
		expectDisposed("getContent", () -> slot.getContent());
		expectDisposed("isEmpty", () -> slot.isEmpty());
		expectDisposed("isOccupied", () -> slot.isOccupied());
	}

	// Hygiene test: when the host MultiAnimBuilder has a TweenManager wired,
	// the parameterized slot's IncrementalUpdateContext must inherit it,
	// matching the buildWithParameters injection pattern. Without this,
	// future parser support for `transition {}` inside SLOT bodies — or any
	// other future use of slot.incrementalContext.tweenManager — silently
	// no-ops. The non-slot path (buildWithParameters) already injects.
	@Test
	public function testParameterizedSlotInheritsTweenManagerFromBuilder():Void {
		final builder = bh.test.BuilderTestBase.builderFromSource("
			#test programmable() {
				#mySlot slot(color:[red,green]=green) {
					@(color => green) bitmap(generated(color(20, 20, #00ff00))): 0, 0
					@(color => red)   bitmap(generated(color(20, 20, #ff0000))): 0, 0
				}
			}
		");
		final tm = new bh.base.TweenManager();
		builder.tweenManager = tm;
		final result = builder.buildWithParameters("test", new Map(), null, null, true);
		final slot = result.getSlot("mySlot");
		Assert.notNull(slot);
		if (slot == null) return;
		Assert.notNull(slot.incrementalContext,
			"parameterized slot must have an IncrementalUpdateContext");
		if (slot.incrementalContext == null) return;
		Assert.equals(tm, slot.incrementalContext.tweenManager,
			"slot context should inherit builder.tweenManager (mirrors buildWithParameters)");
	}

	// Same hygiene contract for the codegen path: `buildSlotContent` constructs
	// its own IncrementalUpdateContext for parameterized slots and must inject
	// the builder's TweenManager. Currently does not — same divergence.
	@Test
	public function testCodegenBuildSlotContentInheritsTweenManagerFromBuilder():Void {
		final builder = bh.test.BuilderTestBase.builderFromSource("
			#test programmable() {
				#mySlot slot(color:[red,green]=green) {
					@(color => green) bitmap(generated(color(20, 20, #00ff00))): 0, 0
					@(color => red)   bitmap(generated(color(20, 20, #ff0000))): 0, 0
				}
			}
		");
		final tm = new bh.base.TweenManager();
		builder.tweenManager = tm;
		final container = new h2d.Object();
		final slot = builder.buildSlotContent("test", "mySlot", new Map(), container);
		Assert.notNull(slot);
		Assert.notNull(slot.incrementalContext, "buildSlotContent should produce an incremental context");
		if (slot.incrementalContext == null) return;
		Assert.equals(tm, slot.incrementalContext.tweenManager,
			"buildSlotContent should inject builder.tweenManager");
	}

	// Decoration of a parameterized slot may declare interactives, named elements,
	// sub-slots, and dynamicRefs. `buildSlotContent` builds these into the slot's
	// container but discarded the per-build InternalBuilderResults — the SlotHandle
	// returned to the caller carried no reference to them, so codegen-side lookup
	// dispatchers and screen wiring/teardown could not reach them by API. Mirrors
	// the SwitchArmResults sink that already solves the same problem for @switch arms.
	@Test
	public function testSlotHandleExposesDecorationInteractives():Void {
		final builder = bh.test.BuilderTestBase.builderFromSource("
			#test programmable() {
				#mySlot slot(highlighted:bool=false) {
					interactive(80, 80, \"card_drop\", role => \"drop\"): 0, 0
					@(highlighted => true) interactive(80, 80, \"card_glow\"): 0, 0
				}
			}
		");
		final container = new h2d.Object();
		final slot = builder.buildSlotContent("test", "mySlot", new Map(), container);

		final initial = slot.getInteractives();
		Assert.equals(1, initial.length,
			'expected 1 interactive (card_drop) initially with highlighted=false, got ${initial.length}');

		slot.setParameter("highlighted", true);
		final afterFlip = slot.getInteractives();
		Assert.equals(2, afterFlip.length,
			'expected 2 interactives after highlighted=true (card_drop + card_glow), got ${afterFlip.length}');
	}

	@Test
	public function testSlotHandleExposesDecorationNamedElement():Void {
		final builder = bh.test.BuilderTestBase.builderFromSource("
			#test programmable() {
				#mySlot slot(highlighted:bool=false) {
					#frame bitmap(generated(color(20, 20, #555555))): 0, 0
				}
			}
		");
		final container = new h2d.Object();
		final slot = builder.buildSlotContent("test", "mySlot", new Map(), container);

		final frame = slot.getUpdatable("frame");
		Assert.notNull(frame, "expected #frame named element from slot decoration to be reachable via SlotHandle");
	}
}
