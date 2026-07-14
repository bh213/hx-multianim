package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.base.TweenManager;

/**
 * Batched updates (beginUpdate/endUpdate) must keep declared transitions and
 * per-param @switch gating, matching BuilderResult batch semantics.
 *
 * Bug shape (ProgrammableCodeGen): the generated endUpdate() runs
 * _applyVisibility() with _changedParam = null, which (a) fails the
 * `_changedParam != null` transition gate so declared transitions degrade to
 * instant toggles, and (b) short-circuits every @switch relevance gate to
 * true so all arms are torn down and rebuilt even when their params didn't
 * change. The builder's batch keeps the changed-param set alive
 * (findTransitionSpec consults it; switch rebuilds are gated per ref).
 *
 * Companion fixture: test/examples/140-codegenBatchTransition/batchTransition.manim
 */
class CodegenBatchTransitionParityTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/140-codegenBatchTransition/batchTransition.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function anyDescendantTweened(root:h2d.Object, tm:TweenManager):Bool {
		if (tm.hasTweens(root)) return true;
		for (i in 0...root.numChildren)
			if (anyDescendantTweened(root.getChildAt(i), tm)) return true;
		return false;
	}

	static function findVisibleBitmapByTileWidth(root:h2d.Object, w:Int):Null<h2d.Bitmap> {
		for (b in BuilderTestBase.findVisibleBitmapDescendants(root))
			if (Std.int(b.tile.width) == w) return b;
		return null;
	}

	/** Builder baseline: a batched change of a transition param still animates. */
	@Test
	public function testBatchTransition_Builder_Animates():Void {
		final tm = new TweenManager();
		final result = BuilderTestBase.buildFromFile(FIXTURE, "batchTrans", null, Incremental);
		result.setTweenManager(tm);
		result.beginUpdate();
		result.setParameter("status", "hover");
		result.endUpdate();
		Assert.isTrue(anyDescendantTweened(result.object, tm),
			"builder: batched status change must start the declared crossfade (active tweens right after endUpdate)");
	}

	/** Codegen control: an unbatched change animates (transition wiring works). */
	@Test
	public function testTransitionUnbatched_Codegen_Animates():Void {
		final tm = new TweenManager();
		final inst:Dynamic = createMp().batchTrans.create();
		inst.setTweenManager(tm);
		inst.setParameter("status", "hover");
		Assert.isTrue(anyDescendantTweened(cast inst, tm),
			"codegen: unbatched status change starts the declared crossfade");
	}

	/** Codegen: the same change inside a batch must also animate. */
	@Test
	public function testBatchTransition_Codegen_Animates():Void {
		final tm = new TweenManager();
		final inst:Dynamic = createMp().batchTrans.create();
		inst.setTweenManager(tm);
		inst.beginUpdate();
		inst.setParameter("status", "hover");
		inst.endUpdate();
		Assert.isTrue(anyDescendantTweened(cast inst, tm),
			"codegen: batched status change must start the declared crossfade, not toggle instantly");
	}

	/** Builder baseline: a batched unrelated-param change leaves the active
	 *  @switch arm object untouched. */
	@Test
	public function testBatchSwitchKeep_Builder_PreservesArm():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "batchSwitchKeep", null, Incremental);
		final before = findVisibleBitmapByTileWidth(result.object, 8);
		Assert.notNull(before, "arm a content (8px bitmap) visible initially");
		result.beginUpdate();
		result.setParameter("y", 5);
		result.endUpdate();
		final after = findVisibleBitmapByTileWidth(result.object, 8);
		Assert.isTrue(before == after,
			"builder: a batched y change must not rebuild the mode switch arm (same bitmap instance)");
	}

	/** Codegen: same guarantee — an unrelated batched param change must not
	 *  force-rebuild every @switch arm. */
	@Test
	public function testBatchSwitchKeep_Codegen_PreservesArm():Void {
		final inst:Dynamic = createMp().batchSwitchKeep.create();
		final before = findVisibleBitmapByTileWidth(cast inst, 8);
		Assert.notNull(before, "arm a content (8px bitmap) visible initially");
		inst.beginUpdate();
		inst.setParameter("y", 5);
		inst.endUpdate();
		final after = findVisibleBitmapByTileWidth(cast inst, 8);
		Assert.isTrue(before == after,
			"codegen: a batched y change must not force-rebuild the mode switch arm (same bitmap instance)");
	}
}
