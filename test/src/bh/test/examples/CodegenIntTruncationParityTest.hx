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

	// ==================== `div` integerizes operands (float operands) ====================

	/** Builder baseline: `div` integerizes its operands before dividing, in an offset
	 *  (float) context. $a div $b * 10 with a=9.0,b=2.5 -> Std.int(9/2)*10 = 40. */
	@Test
	public function testDivOperandIntegerization_Builder_Offset():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "divOffsetFloat", null);
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.floatEquals(40.0, xToRoot(bitmaps[0], result.object),
			"builder: $a div $b * 10 (a=9.0,b=2.5) -> Std.int(9/2)*10 = 40");
	}

	/** Codegen must integerize div operands like the builder. Currently keeps the float
	 *  quotient: Std.int(9.0/2.5)*10 = 30. */
	@Test
	public function testDivOperandIntegerization_Codegen_Offset():Void {
		final inst:Dynamic = createMp().divOffsetFloat.create();
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(cast inst);
		Assert.equals(1, bitmaps.length);
		Assert.floatEquals(40.0, xToRoot(bitmaps[0], cast inst),
			"codegen: $a div $b * 10 (a=9.0,b=2.5) must integerize operands -> Std.int(9/2)*10 = 40, not Std.int(9.0/2.5)*10 = 30");
	}

	/** Builder baseline: `div` with float params in a grid coordinate -> cell 4 (x=40). */
	@Test
	public function testDivOperandIntegerization_Builder_Grid():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "divGridFloat", null);
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.floatEquals(40.0, xToRoot(bitmaps[0], result.object),
			"builder: $grid.pos($a div $b, 0) (a=9.0,b=2.5) -> Std.int(9/2) = cell 4 -> x=40");
	}

	/** Codegen: grid `div` with float params must land on cell 4, not cell 3. */
	@Test
	public function testDivOperandIntegerization_Codegen_Grid():Void {
		final inst:Dynamic = createMp().divGridFloat.create();
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(cast inst);
		Assert.equals(1, bitmaps.length);
		Assert.floatEquals(40.0, xToRoot(bitmaps[0], cast inst),
			"codegen: $grid.pos($a div $b, 0) (a=9.0,b=2.5) must land on cell 4 (x=40), not cell 3 (x=30)");
	}

	// ==================== Per-node truncation in integer coordinate context ====================

	/** Builder baseline: a compound grid coordinate truncates at every node.
	 *  $grid.pos(7/2*2, 0) -> Std.int(7/2)*2 = 3*2 = cell 6 -> x=60. */
	@Test
	public function testCompoundExpr_Builder_TruncatesPerNode():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "compoundTrunc", null);
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.floatEquals(60.0, xToRoot(bitmaps[0], result.object),
			"builder: $grid.pos(7/2*2, 0) -> Std.int(7/2)*2 = cell 6 -> x=60");
	}

	/** Codegen: a compound grid coordinate must truncate per node like the builder.
	 *  Currently truncates once at the site: Std.int((7/2)*2) = 7 -> cell 7 (x=70). */
	@Test
	public function testCompoundExpr_Codegen_TruncatesPerNode():Void {
		final inst:Dynamic = createMp().compoundTrunc.create();
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(cast inst);
		Assert.equals(1, bitmaps.length);
		Assert.floatEquals(60.0, xToRoot(bitmaps[0], cast inst),
			"codegen: $grid.pos(7/2*2, 0) must land on cell 6 (x=60), not cell 7 (x=70)");
	}

	// ==================== `%` integerizes in integer coordinate context ====================

	/** Builder baseline: `%` with float params in a grid coordinate uses integer mod.
	 *  $grid.pos($a % $b, 0) with a=7.0,b=2.5 -> Std.int(7 % 2) = cell 1 -> x=10. */
	@Test
	public function testModIntegerization_Builder_Grid():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "modGridFloat", null);
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(result.object);
		Assert.equals(1, bitmaps.length);
		Assert.floatEquals(10.0, xToRoot(bitmaps[0], result.object),
			"builder: $grid.pos($a % $b, 0) (a=7.0,b=2.5) -> Std.int(7 % 2) = cell 1 -> x=10");
	}

	/** Codegen: grid `%` with float params must use integer mod (cell 1), not float mod (cell 2). */
	@Test
	public function testModIntegerization_Codegen_Grid():Void {
		final inst:Dynamic = createMp().modGridFloat.create();
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(cast inst);
		Assert.equals(1, bitmaps.length);
		Assert.floatEquals(10.0, xToRoot(bitmaps[0], cast inst),
			"codegen: $grid.pos($a % $b, 0) (a=7.0,b=2.5) must land on cell 1 (x=10) via integer mod, not cell 2 (x=20) via float mod");
	}

	// ==================== Param-dependent repeat count per-node truncation ====================

	/** Builder baseline: a param-dependent compound repeat count truncates at every node.
	 *  step($n / 2 * 2) with n=7 -> resolveAsInteger = Std.int(7/2)*2 = 6 iterations. */
	@Test
	public function testRepeatCountParam_Builder_TruncatesPerNode():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "repeatCountParamTrunc", null);
		Assert.equals(6, BuilderTestBase.findVisibleBitmapDescendants(result.object).length,
			"builder: repeatable($i, step($n / 2 * 2)) with n=7 -> Std.int(7/2)*2 = 6 iterations");
	}

	/** Codegen: a param-dependent compound repeat count must truncate per node like the builder.
	 *  Currently the rebuild path evaluates the count as float and truncates once:
	 *  Std.int((7.0/2.0)*2.0) = Std.int(7.0) = 7 iterations. */
	@Test
	public function testRepeatCountParam_Codegen_TruncatesPerNode():Void {
		final inst:Dynamic = createMp().repeatCountParamTrunc.create();
		Assert.equals(6, BuilderTestBase.findVisibleBitmapDescendants(cast inst).length,
			"codegen: repeatable($i, step($n / 2 * 2)) with n=7 must run 6 iterations like the builder (Std.int(7/2)*2 = 6), not 7 from a single final truncation of float math");
	}
}
