package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Integer-resolution parity between builder and codegen.
 *
 * The runtime builder truncates: resolveAsInteger handles OpDiv with
 * Std.int(a / b) and RVFloat with Std.int(f) (MultiAnimBuilder.hx), and grid
 * coordinates pass through resolveAsInteger before resolveAsGrid. Codegen
 * diverges in two places:
 *
 * - tryResolveStaticInt (ProgrammableCodeGen.hx) uses Math.round for RVFloat and
 *   OpDiv, so a statically resolvable repeat count like step(7/2) unrolls 4
 *   iterations where the builder runs 3. (The param-dependent count path already
 *   wraps Std.int(...) and agrees with the builder.)
 * - grid position codegen emits raw float math ($gx * spacing) without integer
 *   truncation of the cell coordinate, so $grid.pos($col/2, 0) with col=3 lands
 *   at 1.5 * spacing instead of the builder's Std.int(1.5) * spacing.
 *
 * Companion fixture:
 * test/examples/132-codegenIntTruncation/intTruncation.manim
 */
class CodegenIntTruncationParityTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/132-codegenIntTruncation/intTruncation.manim";

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

	/** Builder baseline: step(7/2) truncates to 3 iterations. */
	@Test
	public function testStepCount_Builder_TruncatesDivision():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "stepCountTrunc", null);
		Assert.equals(3, BuilderTestBase.findVisibleBitmapDescendants(result.object).length,
			"builder: step(7/2) = Std.int(3.5) = 3 iterations");
	}

	/** Codegen: the statically resolved count must truncate like the builder.
	 *  Currently Math.round(3.5) unrolls 4 iterations. */
	@Test
	public function testStepCount_Codegen_TruncatesDivision():Void {
		final inst:Dynamic = createMp().stepCountTrunc.create();
		Assert.equals(3, BuilderTestBase.findVisibleBitmapDescendants(cast inst).length,
			"codegen: step(7/2) must run 3 iterations like the builder (static resolve currently rounds to 4)");
	}

	/** Builder baseline: grid cell coordinates truncate before spacing multiply,
	 *  for both a param-driven and a literal coordinate expression. */
	@Test
	public function testGridCoord_Builder_TruncatesCell():Void {
		final paramResult = BuilderTestBase.buildFromFile(FIXTURE, "gridCoordParam", null);
		var bitmaps = BuilderTestBase.findVisibleBitmapDescendants(paramResult.object);
		Assert.equals(1, bitmaps.length);
		Assert.floatEquals(10.0, xToRoot(bitmaps[0], paramResult.object),
			"builder: $grid.pos($col/2, 0) with col=3 -> cell 1 -> x=10");

		final staticResult = BuilderTestBase.buildFromFile(FIXTURE, "gridCoordStatic", null);
		bitmaps = BuilderTestBase.findVisibleBitmapDescendants(staticResult.object);
		Assert.equals(1, bitmaps.length);
		Assert.floatEquals(10.0, xToRoot(bitmaps[0], staticResult.object),
			"builder: $grid.pos(3/2, 0) -> cell 1 -> x=10");
	}

	/** Codegen: a param-driven grid coordinate must truncate to the cell index.
	 *  Currently the emitted expression keeps the float quotient (x=15). */
	@Test
	public function testGridCoord_Codegen_TruncatesCell_ParamExpr():Void {
		final inst:Dynamic = createMp().gridCoordParam.create();
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(cast inst);
		Assert.equals(1, bitmaps.length);
		Assert.floatEquals(10.0, xToRoot(bitmaps[0], cast inst),
			"codegen: $grid.pos($col/2, 0) with col=3 must land on cell 1 (x=10), not 1.5 cells (x=15)");
	}

	/** Codegen: a literal grid coordinate expression must truncate the same way. */
	@Test
	public function testGridCoord_Codegen_TruncatesCell_StaticExpr():Void {
		final inst:Dynamic = createMp().gridCoordStatic.create();
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(cast inst);
		Assert.equals(1, bitmaps.length);
		Assert.floatEquals(10.0, xToRoot(bitmaps[0], cast inst),
			"codegen: $grid.pos(3/2, 0) must land on cell 1 (x=10), not 1.5 cells (x=15)");
	}
}
