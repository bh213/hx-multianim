package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.buildFromSource;

/**
 * Incremental-mode parity for repeatable2d.
 *
 * Bug shape: the REPEAT case in MultiAnimBuilder collects repeatParamRefs, marks
 * untracked params, suppresses conditional tracking for the body, and registers a
 * structural rebuild expression so param-dependent counts re-run on setParameter.
 * The REPEAT2D case does none of that: param-dependent iterator counts silently
 * freeze after setParameter, and conditionals inside the body register per-iteration
 * tracking entries that collapse onto the shared node key, so the incremental build
 * renders a different set of children than the full build.
 */
class Repeat2DIncrementalTest extends BuilderTestBase {
	static inline var COUNT_SOURCE = "
		#rep2dCount programmable(nx:int=2) {
			repeatable2d($x, $y, step($nx, dx: 10), step(2, dy: 10)) {
				bitmap(generated(color(4, 4, #FF0000))): 0, 0
			}
		}
	";

	static inline var COND_SOURCE = "
		#rep2dCond programmable() {
			repeatable2d($x, $y, step(3, dx: 10), step(2, dy: 10)) {
				@($x => 0) bitmap(generated(color(4, 4, #00FF00))): 0, 0
			}
		}
	";

	static inline var PARAM_COND_SOURCE = "
		#rep2dParamCond programmable(on:bool=false) {
			repeatable2d($x, $y, step(3, dx: 10), step(2, dy: 10)) {
				@(on => true) bitmap(generated(color(4, 4, #00FF00))): 0, 0
				@else bitmap(generated(color(4, 4, #FF0000))): 0, 0
			}
		}
	";

	/** Full-build baseline: the param-dependent X count resolves at build time. */
	@Test
	public function testParamDependentCount_FullBuild_ResolvesCount():Void {
		final defResult = buildFromSource(COUNT_SOURCE, "rep2dCount");
		Assert.equals(4, BuilderTestBase.findVisibleBitmapDescendants(defResult.object).length,
			"full build: nx=2 (default) x 2 rows must render 4 bitmaps");

		final params = new Map<String, Dynamic>();
		params.set("nx", 3);
		final result = buildFromSource(COUNT_SOURCE, "rep2dCount", params);
		Assert.equals(6, BuilderTestBase.findVisibleBitmapDescendants(result.object).length,
			"full build: nx=3 x 2 rows must render 6 bitmaps");
	}

	/** Incremental build: setParameter on the count param must rebuild the iterations,
	 *  like the 1D repeatable does. Currently repeatable2d registers no rebuild
	 *  trigger, so the count silently freezes at its build-time value. */
	@Test
	public function testParamDependentCount_Incremental_RebuildsOnSetParameter():Void {
		final result = buildFromSource(COUNT_SOURCE, "rep2dCount", null, Incremental);
		Assert.equals(4, BuilderTestBase.findVisibleBitmapDescendants(result.object).length,
			"incremental build: nx=2 (default) x 2 rows must render 4 bitmaps");

		result.setParameter("nx", 3);
		Assert.equals(6, BuilderTestBase.findVisibleBitmapDescendants(result.object).length,
			"incremental: setParameter(nx, 3) must rebuild to 6 bitmaps — repeatable2d currently freezes the count");
	}

	/** Full-build baseline: a loop-var conditional selects one column of the 3x2 grid. */
	@Test
	public function testLoopVarConditional_FullBuild_SelectsColumn():Void {
		final result = buildFromSource(COND_SOURCE, "rep2dCond");
		Assert.equals(2, BuilderTestBase.findVisibleBitmapDescendants(result.object).length,
			"full build: @($x => 0) in a 3x2 repeatable2d must render 2 bitmaps (x=0, both rows)");
	}

	/** Incremental build must render the same visible set as the full build. */
	@Test
	public function testLoopVarConditional_Incremental_MatchesFullBuild():Void {
		final result = buildFromSource(COND_SOURCE, "rep2dCond", null, Incremental);
		Assert.equals(2, BuilderTestBase.findVisibleBitmapDescendants(result.object).length,
			"incremental build: @($x => 0) in a 3x2 repeatable2d must render 2 bitmaps, same as the full build");
	}

	/** Full-build baseline: a param conditional with @else renders exactly one arm
	 *  per iteration. */
	@Test
	public function testParamElseConditional_FullBuild_OneArmPerIteration():Void {
		final result = buildFromSource(PARAM_COND_SOURCE, "rep2dParamCond");
		Assert.equals(6, BuilderTestBase.findVisibleBitmapDescendants(result.object).length,
			"full build: @(on => true)/@else in a 3x2 repeatable2d must render one arm per iteration (6 bitmaps)");
	}

	/** Incremental build: one arm per iteration, both at build time and after a
	 *  param flip. Currently resolveConditionalChildren returns ALL arms in
	 *  incremental mode and repeatable2d does not suppress conditional tracking
	 *  like REPEAT does, so the per-iteration entries collapse onto the shared
	 *  node key and both arms can render simultaneously. */
	@Test
	public function testParamElseConditional_Incremental_OneArmPerIteration():Void {
		final result = buildFromSource(PARAM_COND_SOURCE, "rep2dParamCond", null, Incremental);
		Assert.equals(6, BuilderTestBase.findVisibleBitmapDescendants(result.object).length,
			"incremental build: @(on => true)/@else in a 3x2 repeatable2d must render one arm per iteration (6 bitmaps)");

		result.setParameter("on", true);
		Assert.equals(6, BuilderTestBase.findVisibleBitmapDescendants(result.object).length,
			"incremental: after setParameter(on, true) still exactly one arm per iteration (6 bitmaps)");
	}
}
