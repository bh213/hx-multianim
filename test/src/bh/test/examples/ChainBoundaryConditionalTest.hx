package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Regression — codegen `negatePriorSiblings` must respect chain boundaries.
 *
 * A fresh chain after a terminal (bare) `@else` is legal — a `@()` arm is not
 * an `@else`/`@default` continuation, so the parser permits it. Builder tracks
 * chain state via `prevSiblingMatched`/`anyConditionalSiblingMatched` inside
 * `resolveVisibilityForChildren` and naturally restarts per chain.
 *
 * Codegen's `negatePriorSiblings` walks ALL prior siblings of the parent node
 * and AND-negates every `Conditional`, without stopping at chain boundaries
 * and without reacting to `ConditionalElse(null)` / `ConditionalDefault`.
 * That over-constrains the condition for `@else`/`@default` in a later chain.
 *
 * Fixture: test/examples/112-chainBoundary/chainBoundary.manim defines two
 * chains with a 4-bitmap programmable. Default params (x=other, y=other)
 * yield exactly ONE visible bitmap under correct semantics (the bare `@else`
 * of chain 1). A buggy codegen additionally shows `@default` of chain 2.
 */
class ChainBoundaryConditionalTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/112-chainBoundary/chainBoundary.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	/** Count h2d.Bitmap descendants whose ancestry up to `root` is fully visible. */
	static function countVisibleBitmapsToRoot(root:h2d.Object):Int {
		var n = 0;
		function walk(o:h2d.Object, parentVisible:Bool):Void {
			final v = parentVisible && o.visible;
			if (v && Std.isOfType(o, h2d.Bitmap)) n++;
			for (i in 0...o.numChildren)
				walk(o.getChildAt(i), v);
		}
		walk(root, true);
		return n;
	}

	@Test
	public function testBuilder_DefaultParams_OnlyBareElseVisible():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "chainBoundary", null, Incremental);
		Assert.equals(1, countVisibleBitmapsToRoot(result.object),
			"Builder with defaults (x=other, y=other): exactly 1 bitmap visible (chain-1 bare @else). @default of chain 2 must be hidden.");
	}

	@Test
	public function testCodegen_DefaultParams_OnlyBareElseVisible():Void {
		final mp = createMp();
		final inst:Dynamic = mp.chainBoundary.create();
		final obj:h2d.Object = cast inst;
		Assert.equals(1, countVisibleBitmapsToRoot(obj),
			"Codegen must match builder — exactly 1 bitmap visible. Bug: @default of chain 2 also visible because negatePriorSiblings over-negates across chain boundary.");
	}

	/** Sanity: when chain 1 matches on `@(x=>xa)`, chain 2 still has no match.
	 *  Correct: e1 visible, nothing else. This scenario does NOT expose the bug
	 *  (under the bug, @default is still hidden because the chain-1 negation already
	 *  yields false). Included to guard against over-correcting in the fix. */
	@Test
	public function testBuilder_ChainOneMatches_OnlyE1Visible():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "chainBoundary", ["x" => "xa"], Incremental);
		Assert.equals(1, countVisibleBitmapsToRoot(result.object),
			"Builder with x=xa: e1 visible, e2 hidden (prev matched), e3 hidden, e4 hidden (any=true).");
	}

	@Test
	public function testCodegen_ChainOneMatches_OnlyE1Visible():Void {
		final mp = createMp();
		final inst:Dynamic = mp.chainBoundary.create();
		inst.setX(bh.test.MultiProgrammable_ChainBoundary.Xa);
		final obj:h2d.Object = cast inst;
		Assert.equals(1, countVisibleBitmapsToRoot(obj),
			"Codegen with x=xa: exactly 1 bitmap visible.");
	}
}
