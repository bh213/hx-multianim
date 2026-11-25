package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Batch-update parity between codegen instances and BuilderResult.
 *
 * BuilderResult exposes beginUpdate()/endUpdate()/batchMode (MultiAnimBuilder.hx); generated
 * codegen instances previously exposed none, so every typed setter immediately ran
 * _applyVisibility -> _updateExpressions -> _fireRebuildListeners. A multi-param state change
 * (e.g. status + disabled) fired TWO rebuilds and TWO listener passes where the builder coalesces
 * to one. Codegen instances now generate the same batch API, deferring the rebuild to endUpdate().
 *
 * Companion fixture: test/examples/136-codegenBatchUpdate/batchUpdate.manim
 */
class CodegenBatchUpdateParityTest extends BuilderTestBase {
	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	/** A batched multi-param change fires the rebuild listener exactly once. */
	@Test
	public function testBatch_CoalescesRebuildListenerFires():Void {
		final inst:Dynamic = createMp().batchTwoParams.create();
		var fires = 0;
		inst.addRebuildListener(() -> fires++);
		inst.beginUpdate();
		inst.setParameter("status", "hover");
		inst.setParameter("disabled", true);
		inst.endUpdate();
		Assert.equals(1, fires,
			"a batched multi-param change must fire the rebuild listener exactly once (was once per setter)");
	}

	/** Control: without a batch, each changing setter fires the listener (one per param). */
	@Test
	public function testUnbatched_FiresPerSetter():Void {
		final inst:Dynamic = createMp().batchTwoParams.create();
		var fires = 0;
		inst.addRebuildListener(() -> fires++);
		inst.setParameter("status", "hover");
		inst.setParameter("disabled", true);
		Assert.equals(2, fires,
			"without a batch, each changing setter fires the rebuild listener (non-batched behavior preserved)");
	}

	/** While batched, the backing field updates but visibility is not applied until endUpdate(). */
	@Test
	public function testBatch_DefersVisibilityUntilEndUpdate():Void {
		final inst:Dynamic = createMp().batchTwoParams.create();
		// default: status=normal, disabled=false -> neither conditional visible
		Assert.equals(0, BuilderTestBase.findVisibleBitmapDescendants(cast inst).length,
			"both bitmaps start hidden (status=normal, disabled=false)");
		inst.beginUpdate();
		inst.setParameter("status", "hover");
		inst.setParameter("disabled", true);
		Assert.equals(0, BuilderTestBase.findVisibleBitmapDescendants(cast inst).length,
			"batched setters must defer visibility until endUpdate()");
		inst.endUpdate();
		Assert.equals(2, BuilderTestBase.findVisibleBitmapDescendants(cast inst).length,
			"endUpdate() applies the accumulated visibility changes (both bitmaps now visible)");
	}

	/** An expression that reads two params, both changed in one batch, is evaluated once. */
	static function countingLabel(counter:{n:Int}):bh.multianim.MultiAnimBuilder.CallbackRequest -> bh.multianim.MultiAnimBuilder.CallbackResult {
		return (request) -> switch request {
			case NameWithIndex(name, _) if (name == "label"):
				counter.n++;
				CBRString("lbl");
			default:
				CBRNoResult;
		};
	}

	@Test
	public function testBatch_Builder_ExpressionOfTwoParamsRunsOnce():Void {
		final calls = {n: 0};
		final builder = BuilderTestBase.builderFromFile("test/examples/136-codegenBatchUpdate/batchUpdate.manim");
		final bp:Dynamic = {callback: countingLabel(calls)};
		final result = builder.buildWithParameters("batchCallbackTwoParams", new Map(), bp, null, true);
		calls.n = 0;
		result.beginUpdate();
		result.setParameter("a", 2);
		result.setParameter("b", 3);
		result.endUpdate();
		Assert.equals(1, calls.n, "builder: one batch, the callback asked once");
	}

	@Test
	public function testBatch_Codegen_ExpressionOfTwoParamsRunsOnce():Void {
		final mp = createMp();
		final inst:Dynamic = mp.batchCallbackTwoParams.create();
		final calls = {n: 0};
		final builder:bh.multianim.MultiAnimBuilder = @:privateAccess cast (mp.batchCallbackTwoParams : Dynamic)._builder;
		@:privateAccess builder.builderParams = {callback: countingLabel(calls)};
		inst.beginUpdate();
		inst.setParameter("a", 2);
		inst.setParameter("b", 3);
		inst.endUpdate();
		Assert.equals(1, calls.n, "codegen: one batch, the callback asked once, as in the builder (not once per changed param)");
	}

	/** batchMode reflects the open/closed state of a batch. Uses the statically-typed instance
	 *  (not Dynamic) so the (get, never) property getter is invoked at compile time. */
	@Test
	public function testBatchMode_Flag():Void {
		final inst = createMp().batchTwoParams.create();
		Assert.isFalse(inst.batchMode, "batchMode is false outside a batch");
		inst.beginUpdate();
		Assert.isTrue(inst.batchMode, "batchMode is true between beginUpdate and endUpdate");
		inst.endUpdate();
		Assert.isFalse(inst.batchMode, "batchMode is false after endUpdate");
	}
}
