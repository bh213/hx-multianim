package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Codegen/builder parity for param-dependent repeat iterators and flow embedding.
 *
 * Bug shapes (ProgrammableCodeGen.resolveRepeatInfo and friends):
 * - step(dx: $dx) offsets that are not statically resolvable silently fall back to
 *   0, in both the static-unroll path (offset literals baked as 0) and the runtime
 *   rebuild path (setPosition skipped entirely because the baked dx is 0). The
 *   builder resolves the offsets at build time and re-resolves them on rebuild.
 * - range($start, end, $step) with param-dependent start/step: the runtime count is
 *   computed correctly, but the loop value bakes the static fallbacks
 *   (_rt_val = Std.int(0 + _rt_i * 1)), so loop values start at 0 with step 1.
 * - repeatable with zero offsets inside a flow: the builder adds iteration children
 *   directly to the flow (needsWrapper logic); codegen always creates one wrapper
 *   container, so the flow sees a single child and iterations overlap.
 *
 * Companion fixture:
 * test/examples/137-codegenRepeatParamParity/repeatParamParity.manim
 */
class CodegenRepeatParamParityTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/137-codegenRepeatParamParity/repeatParamParity.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	/** Sum of x offsets from `obj` up to (excluding) `root` — robust against
	 *  wrapper objects differing between the builder and codegen scene graphs. */
	static function xToRoot(obj:h2d.Object, root:h2d.Object):Float {
		var x = 0.0;
		var o:h2d.Object = obj;
		while (o != null && o != root) {
			x += o.x;
			o = o.parent;
		}
		return x;
	}

	/** Sorted x positions (relative to root) of all visible bitmap descendants. */
	static function bitmapXs(root:h2d.Object):Array<Float> {
		final xs = [for (b in BuilderTestBase.findVisibleBitmapDescendants(root)) xToRoot(b, root)];
		xs.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
		return xs;
	}

	static function assertXs(expected:Array<Float>, actual:Array<Float>, msg:String):Void {
		Assert.equals(expected.length, actual.length, '$msg — expected ${expected.length} bitmaps, got ${actual.length} at $actual');
		if (expected.length == actual.length)
			for (i in 0...expected.length)
				Assert.floatEquals(expected[i], actual[i], '$msg — position $i: expected ${expected[i]}, got ${actual[i]} (all: $actual)');
	}

	/** First h2d.Flow descendant. */
	static function findFlow(obj:h2d.Object):Null<h2d.Flow> {
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, h2d.Flow))
				return cast child;
			final sub = findFlow(child);
			if (sub != null)
				return sub;
		}
		return null;
	}

	// ==================== step() param-dependent offsets, static count ====================

	/** Builder baseline: dx=$dx (default 20) spreads 3 iterations at 0, 20, 40. */
	@Test
	public function testStepParamOffsets_Builder_SpreadsIterations():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "stepParamOffsets", null);
		assertXs([0, 20, 40], bitmapXs(result.object), "builder: step(3, dx: $dx) with dx=20");
	}

	/** Codegen: the same offsets must apply. Currently the static resolve falls back
	 *  to dx=0 and all iterations stack at the origin. */
	@Test
	public function testStepParamOffsets_Codegen_SpreadsIterations():Void {
		final inst:Dynamic = createMp().stepParamOffsets.create();
		assertXs([0, 20, 40], bitmapXs(cast inst), "codegen: step(3, dx: $dx) with dx=20 must spread iterations, not stack at 0");
	}

	// ==================== step() param-dependent offsets AND count ====================

	/** Builder baseline: param count and param dx both resolve at build time. */
	@Test
	public function testStepParamOffsetsRuntime_Builder_SpreadsIterations():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "stepParamOffsetsRt", null);
		assertXs([0, 20, 40], bitmapXs(result.object), "builder: step($n, dx: $dx) with n=3, dx=20");
	}

	/** Codegen runtime-rebuild path: offsets must be applied per iteration, and a dx
	 *  change must reposition. Currently the baked dx is 0 so setPosition is never
	 *  emitted at all. */
	@Test
	public function testStepParamOffsetsRuntime_Codegen_SpreadsIterations():Void {
		final inst:Dynamic = createMp().stepParamOffsetsRt.create();
		assertXs([0, 20, 40], bitmapXs(cast inst), "codegen: step($n, dx: $dx) with n=3, dx=20 must spread iterations");

		inst.setParameter("dx", 40);
		assertXs([0, 40, 80], bitmapXs(cast inst), "codegen: setParameter(dx, 40) must re-apply iteration offsets");
	}

	// ==================== range() param-dependent start/step ====================

	/** Builder baseline: range($start, 11, $stepv) with start=5, stepv=2 yields loop
	 *  values 5, 7, 9 (bitmap x mirrors the loop value). */
	@Test
	public function testRangeParamBounds_Builder_LoopValues():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "rangeParamBounds", null);
		assertXs([5, 7, 9], bitmapXs(result.object), "builder: range($start, 11, $stepv) with start=5, stepv=2");
	}

	/** Codegen: loop values must be start + i*step. Currently the count is right but
	 *  the values bake start=0, step=1 (0, 1, 2). A start change must also re-derive
	 *  the values. */
	@Test
	public function testRangeParamBounds_Codegen_LoopValues():Void {
		final inst:Dynamic = createMp().rangeParamBounds.create();
		assertXs([5, 7, 9], bitmapXs(cast inst), "codegen: range($start, 11, $stepv) with start=5, stepv=2 must yield loop values 5, 7, 9");

		inst.setParameter("start", 7);
		assertXs([7, 9], bitmapXs(cast inst), "codegen: setParameter(start, 7) must yield loop values 7, 9");
	}

	// ==================== repeatable inside flow ====================

	/** Builder baseline: a zero-offset repeatable adds its iteration children
	 *  directly to the enclosing flow. */
	@Test
	public function testFlowRepeat_Builder_FlowSeesEachIteration():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "flowRepeat", null);
		final flow = findFlow(result.object);
		Assert.notNull(flow, "builder: expected an h2d.Flow in the tree");
		Assert.equals(3, flow.numChildren, "builder: flow must see 3 iteration children");
	}

	/** Codegen: the flow must see each iteration child so it can lay them out.
	 *  Currently all iterations live inside one wrapper container. */
	@Test
	public function testFlowRepeat_Codegen_FlowSeesEachIteration():Void {
		final inst:Dynamic = createMp().flowRepeat.create();
		final flow = findFlow(cast inst);
		Assert.notNull(flow, "codegen: expected an h2d.Flow in the tree");
		Assert.equals(3, flow.numChildren, "codegen: flow must see 3 iteration children, not 1 wrapper container");
	}
}
