package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.buildFromSource;
import bh.test.BuilderTestBase.parseExpectingError;

/**
 * Unit tests for flow element properties:
 * overflow modes, fillWidth, fillHeight, reverse, alignment, spacer, @flow.* per-child properties.
 */
class FlowOverflowTest extends BuilderTestBase {
	// ==================== Helpers ====================

	/** Find the first h2d.Flow descendant in the object tree. */
	static function findFlow(obj:h2d.Object):Null<h2d.Flow> {
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, h2d.Flow))
				return cast child;
			var sub = findFlow(child);
			if (sub != null)
				return sub;
		}
		return null;
	}

	/** Find all h2d.Flow descendants in the object tree. */
	static function findAllFlows(obj:h2d.Object):Array<h2d.Flow> {
		var result:Array<h2d.Flow> = [];
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, h2d.Flow))
				result.push(cast child);
			for (f in findAllFlows(child))
				result.push(f);
		}
		return result;
	}

	// ==================== Overflow Modes ====================

	@Test
	public function testOverflowExpand():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: horizontal, overflow: expand) {
					bitmap(generated(color(30, 15, #ff0000))): 0, 0
				}
			}
		", "test");
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		Assert.equals(h2d.Flow.FlowOverflow.Expand, flow.overflow);
	}

	@Test
	public function testOverflowLimit():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: horizontal, overflow: limit) {
					bitmap(generated(color(30, 15, #ff0000))): 0, 0
				}
			}
		", "test");
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		Assert.equals(h2d.Flow.FlowOverflow.Limit, flow.overflow);
	}

	@Test
	public function testOverflowHidden():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(maxWidth: 50, layout: horizontal, overflow: hidden) {
					bitmap(generated(color(30, 15, #ff0000))): 0, 0
				}
			}
		", "test");
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		Assert.equals(h2d.Flow.FlowOverflow.Hidden, flow.overflow);
	}

	@Test
	public function testOverflowScroll():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: horizontal, overflow: scroll) {
					bitmap(generated(color(30, 15, #ff0000))): 0, 0
				}
			}
		", "test");
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		Assert.equals(h2d.Flow.FlowOverflow.Scroll, flow.overflow);
	}

	@Test
	public function testDefaultOverflowIsLimit():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: horizontal) {
					bitmap(generated(color(30, 15, #ff0000))): 0, 0
				}
			}
		", "test");
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		Assert.equals(h2d.Flow.FlowOverflow.Limit, flow.overflow);
	}

	// ==================== Fill Properties ====================

	@Test
	public function testFillWidthTrue():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: horizontal, fillWidth: true) {
					bitmap(generated(color(30, 15, #ff0000))): 0, 0
				}
			}
		", "test");
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		Assert.isTrue(flow.fillWidth);
	}

	@Test
	public function testFillWidthDefault():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: horizontal) {
					bitmap(generated(color(30, 15, #ff0000))): 0, 0
				}
			}
		", "test");
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		Assert.isFalse(flow.fillWidth);
	}

	@Test
	public function testFillHeightTrue():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: horizontal, fillHeight: true) {
					bitmap(generated(color(30, 15, #ff0000))): 0, 0
				}
			}
		", "test");
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		Assert.isTrue(flow.fillHeight);
	}

	// ==================== Reverse ====================

	@Test
	public function testReverseTrue():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: horizontal, reverse: true) {
					bitmap(generated(color(30, 15, #ff0000))): 0, 0
					bitmap(generated(color(30, 15, #00ff00))): 0, 0
				}
			}
		", "test");
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		Assert.isTrue(flow.reverse);
	}

	@Test
	public function testReverseDefault():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: horizontal) {
					bitmap(generated(color(30, 15, #ff0000))): 0, 0
				}
			}
		", "test");
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		Assert.isFalse(flow.reverse);
	}

	// ==================== Alignment ====================

	@Test
	public function testHorizontalAlignRight():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(minWidth: 100, layout: vertical, horizontalAlign: right) {
					bitmap(generated(color(30, 15, #ff0000))): 0, 0
				}
			}
		", "test");
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		Assert.equals(h2d.Flow.FlowAlign.Right, flow.horizontalAlign);
	}

	@Test
	public function testVerticalAlignBottom():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(minHeight: 100, layout: horizontal, verticalAlign: bottom) {
					bitmap(generated(color(30, 15, #ff0000))): 0, 0
				}
			}
		", "test");
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		Assert.equals(h2d.Flow.FlowAlign.Bottom, flow.verticalAlign);
	}

	// ==================== Spacer ====================

	@Test
	public function testSpacerInFlow():Void {
		// Spacer creates spacing inside a flow. Test that it builds successfully.
		final result = buildFromSource("
			#test programmable() {
				flow(layout: vertical, verticalSpacing: 1) {
					bitmap(generated(color(40, 10, #ff0000))): 0, 0
					spacer(0, 8): 0, 0
					bitmap(generated(color(40, 10, #00ff00))): 0, 0
				}
			}
		", "test");
		Assert.notNull(result);
		// Flow should contain children
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		Assert.isTrue(flow.numChildren >= 2);
	}

	// ==================== @flow.halign per-child ====================

	@Test
	public function testFlowHalignPerChild():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(minWidth: 60, layout: vertical, verticalSpacing: 1) {
					bitmap(generated(color(40, 10, #ff0000))): 0, 0
					@flow.halign(right) bitmap(generated(color(25, 10, #00ff00))): 0, 0
					@flow.halign(middle) bitmap(generated(color(30, 10, #0000ff))): 0, 0
				}
			}
		", "test");
		Assert.notNull(result);
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		// Verify the flow built with children
		Assert.isTrue(flow.numChildren >= 3);
	}

	// ==================== @flow.absolute ====================

	@Test
	public function testFlowAbsoluteChild():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: vertical, verticalSpacing: 1) {
					bitmap(generated(color(40, 10, #ff0000))): 0, 0
					bitmap(generated(color(40, 10, #00ff00))): 0, 0
					@flow.absolute bitmap(generated(color(15, 15, #0000ff))): 30, 2
				}
			}
		", "test");
		Assert.notNull(result);
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		Assert.isTrue(flow.numChildren >= 3);
	}

	// ==================== @flow.offset per-child ====================

	@Test
	public function testFlowOffsetPerChild():Void {
		final result = buildFromSource("
			#test programmable() {
				flow(layout: vertical, verticalSpacing: 1) {
					bitmap(generated(color(40, 10, #ff0000))): 0, 0
					@flow.offset(10, 0) bitmap(generated(color(40, 10, #00ff00))): 0, 0
					bitmap(generated(color(40, 10, #0000ff))): 0, 0
				}
			}
		", "test");
		Assert.notNull(result);
		var flow = findFlow(result.object);
		Assert.notNull(flow);
		Assert.isTrue(flow.numChildren >= 3);
	}

	// ==================== Parse Errors ====================

	@Test
	public function testFlowPropertiesOutsideFlowErrors():Void {
		// @flow.* outside a flow ancestor should cause a parse error
		var err = parseExpectingError("
			#test programmable() {
				@flow.halign(right) bitmap(generated(color(40, 10, #ff0000))): 0, 0
			}
		");
		Assert.notNull(err);
	}
}
