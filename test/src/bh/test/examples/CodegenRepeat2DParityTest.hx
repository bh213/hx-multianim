package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * REPEAT2D codegen parity gaps (the 1D fixes were never ported to the 2D
 * path):
 *
 * - layout (and array) axes: the builder supports them; the codegen routes
 *   them to the "empty container" fallback and silently renders NOTHING.
 * - param-dependent step offsets: the 2D runtime rebuild bakes the macro-time
 *   fallback 0 (the 1D path resolves _rt_dx/_rt_dy at runtime).
 * - param-dependent range loop values: the 2D inner body iterates raw
 *   0..count and never maps start + i (the 1D path emits _rt_val).
 *
 * Companion fixture: test/examples/146-codegenRepeat2dParity/repeat2dParity.manim
 */
class CodegenRepeat2DParityTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/146-codegenRepeat2dParity/repeat2dParity.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function xToRoot(obj:h2d.Object, root:h2d.Object):Float {
		var x = 0.0;
		var o:h2d.Object = obj;
		while (o != null && o != root) {
			x += o.x;
			o = o.parent;
		}
		return x;
	}

	static function bitmapXs(root:h2d.Object):Array<Float> {
		final xs = [for (b in BuilderTestBase.findVisibleBitmapDescendants(root)) xToRoot(b, root)];
		xs.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
		return xs;
	}

	static function assertXs(expected:Array<Float>, actual:Array<Float>, msg:String):Void {
		Assert.equals(expected.length, actual.length,
			'$msg — expected ${expected.length} bitmaps, got ${actual.length} at $actual');
		if (expected.length == actual.length)
			for (i in 0...expected.length)
				Assert.floatEquals(expected[i], actual[i],
					'$msg — position $i: expected ${expected[i]}, got ${actual[i]} (all: $actual)');
	}

	// ==================== layout axis ====================

	/** Builder baseline: 2-point layout axis x 2-step axis renders 2x2. */
	@Test
	public function testR2dLayoutAxis_Builder_Renders():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "r2dLayoutAxis", null);
		assertXs([0, 0, 40, 40], bitmapXs(result.object), "builder: layout axis x step axis");
	}

	/** Codegen: the same 2D repeat must render, not silently produce nothing. */
	@Test
	public function testR2dLayoutAxis_Codegen_Renders():Void {
		final inst:Dynamic = createMp().r2dLayoutAxis.create();
		assertXs([0, 0, 40, 40], bitmapXs(cast inst),
			"codegen: a layout axis on repeatable2d must render like the builder, not silently render nothing");
	}

	// ==================== param-dependent step offsets ====================

	/** Builder baseline: param dx spreads columns at 0 and 20. */
	@Test
	public function testR2dParamOffsets_Builder_SpreadsColumns():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "r2dParamOffsets", null);
		assertXs([0, 0, 20, 20], bitmapXs(result.object), "builder: step($n, dx: $dx) x step(2, dy: 30)");
	}

	/** Codegen: offsets must apply per iteration and re-apply on change. */
	@Test
	public function testR2dParamOffsets_Codegen_SpreadsColumns():Void {
		final inst:Dynamic = createMp().r2dParamOffsets.create();
		assertXs([0, 0, 20, 20], bitmapXs(cast inst),
			"codegen: 2D step($n, dx: $dx) must spread columns, not stack them at x=0");
		inst.setParameter("dx", 40);
		assertXs([0, 0, 40, 40], bitmapXs(cast inst),
			"codegen: setParameter(dx, 40) must re-apply the 2D iteration offsets");
	}

	// ==================== param-dependent range loop values ====================

	/** Builder baseline: range($start, 8) with start=5 exposes values 5..7. */
	@Test
	public function testR2dRangeValues_Builder_LoopValues():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "r2dRangeValues", null);
		assertXs([5, 5, 6, 6, 7, 7], bitmapXs(result.object), "builder: range($start, 8) x range(0, 2)");
	}

	/** Codegen: loop values must be start + i, and a start change re-derives them. */
	@Test
	public function testR2dRangeValues_Codegen_LoopValues():Void {
		final inst:Dynamic = createMp().r2dRangeValues.create();
		assertXs([5, 5, 6, 6, 7, 7], bitmapXs(cast inst),
			"codegen: 2D range($start, 8) loop values must start at 5, not 0");
		inst.setParameter("start", 6);
		assertXs([6, 6, 7, 7], bitmapXs(cast inst),
			"codegen: setParameter(start, 6) must re-derive the 2D loop values");
	}
}
