package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Regression for H6: when a repeat's iteration count is param-dependent, codegen
 * takes the runtime-rebuild branch (ProgrammableCodeGen.rebuildRepeatChildren)
 * and emits each child via generateRuntimeChildExprs. That function only handles
 * BITMAP, POINT, TEXT, RICHTEXT, NINEPATCH, GRAPHICS, PIXELS, MASK, LAYERS, FLOW
 * explicitly — everything else falls through the `default:` arm at
 * ProgrammableCodeGen.hx:2961-2968, which forwards to
 * ProgrammableBuilder.buildNodeByUniqueName(...).
 *
 * The fallback path:
 *   1. Does not call recordUntrackedParams on the subtree — so params referenced
 *      only inside an INTERACTIVE id / metadata / stateanim selector never end
 *      up in untrackedParamRefs. setParameter succeeds at the dispatcher level,
 *      updates the internal _field, but produces no visual change and no throw.
 *   2. Does not register expressionUpdates — _updateExpressions() has no hook
 *      for the subtree.
 *   3. Calls buildSingleNode with the current builderParams, so a count-param
 *      change rebuilds and reads fresh values, but non-count param changes
 *      never trigger a rebuild.
 *
 * Static-count repeats exercise processChildren instead of generateRuntimeChildExprs
 * and correctly flag the same params as untracked (see
 * CodegenIncrementalInteractiveStateanimTest.testUntrackedId_*). This test pins
 * the param-dep-count variant to the same policy: setParameter on a param that
 * flows into an INTERACTIVE id inside a param-dep repeat must throw
 * "untracked_param" in both the builder and the codegen path.
 *
 * Currently fails: codegen setter on the fallback-built subtree silently no-ops.
 *
 * Companion fixture:
 * test/examples/114-codegenRepeatFallbackUntracked/codegenRepeatFallbackUntracked.manim
 */
class CodegenRepeatFallbackUntrackedTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/114-codegenRepeatFallbackUntracked/codegenRepeatFallbackUntracked.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function runAndCatch(fn:() -> Void):Null<String> {
		try { fn(); return null; }
		catch (e:Dynamic) return Std.string(e);
	}

	static function assertUntrackedReject(msg:Null<String>, paramName:String, reasonFragment:String, label:String):Void {
		Assert.notNull(msg, '$label: expected throw, none raised — param is silently frozen (H6).');
		if (msg == null) return;
		Assert.isTrue(msg.indexOf('setParameter("' + paramName + '", ...) rejected') >= 0,
			'$label: message must name rejected param — got: $msg');
		Assert.isTrue(msg.indexOf(reasonFragment) >= 0,
			'$label: message must mention reason "' + reasonFragment + '" — got: $msg');
	}

	/** Builder sanity check: the runtime builder already walks the repeat body
	 *  via MultiAnimBuilder.build and calls markParamUntracked on INTERACTIVE
	 *  id refs. If this test fails it's a separate regression in the builder
	 *  path, not H6. */
	@Test
	public function testParamDepRepeat_InteractiveId_Builder_Throws():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "paramDepRepeatUntrackedId", null, Incremental);
		assertUntrackedReject(runAndCatch(() -> result.setParameter("myId", "other")),
			"myId", "interactive id", "builder");
	}

	/** The H6 test: codegen typed setter on a param referenced only inside an
	 *  INTERACTIVE id within a param-dependent repeat count must throw the same
	 *  "untracked_param" rejection as the static-count baseline
	 *  (testUntrackedId_Codegen_Throws in CodegenIncrementalInteractiveStateanimTest).
	 *
	 *  Currently silent — recordUntrackedParams is never called for the fallback
	 *  subtree, so untrackedParamRefs has no entry for "myId", so the generated
	 *  setter falls through the rejection guard at ProgrammableCodeGen.hx:807-811
	 *  and runs _applyVisibility + _updateExpressions, neither of which touches
	 *  the fallback-built interactive. */
	@Test
	public function testParamDepRepeat_InteractiveId_Codegen_Throws():Void {
		final mp = createMp();
		final inst:Dynamic = mp.paramDepRepeatUntrackedId.create();
		assertUntrackedReject(runAndCatch(() -> inst.setMyId("other")),
			"myId", "interactive id", "codegen typed setter");
		assertUntrackedReject(runAndCatch(() -> inst.setParameter("myId", "another")),
			"myId", "interactive id", "codegen setParameter dispatcher");
	}
}
