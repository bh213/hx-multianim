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
}
