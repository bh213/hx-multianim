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
		// Should not throw when setting parameter
		slot.setParameter("color", "red");
		Assert.isTrue(true); // If we got here, it worked
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
		slot.setParameter("active", true);
		Assert.isTrue(true);
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
		try {
			slot.setParameter("anything", "value");
		} catch (e:Dynamic) {
			err = Std.string(e);
		}
		Assert.notNull(err);
	}
}
