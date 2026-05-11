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

	// ==================== Param-dep repeat body: kinds beyond INTERACTIVE/STATEANIM ====================
	//
	// `recordUntrackedParamsInSubtree` (codegen) and `markUntrackedParamsInSubtree`
	// (runtime) currently switch on only three node kinds: INTERACTIVE, STATEANIM,
	// STATEANIM_CONSTRUCT. But the param-dep repeat fallback forwards every other
	// kind (DYNAMIC_REF, STATIC_REF, SWITCH, PARTICLES, PLACEHOLDER, SLOT, ...) via
	// buildNodeByUniqueNameWithParams, which sets incrementalMode=false — so neither
	// the helper marks the refs untracked nor does the build register tracking.
	// Body-only setParameter then silently no-ops, because the repeat body is only
	// rebuilt when the count itself changes (_rebuildRepeat_X early-returns when
	// _rt_count is unchanged).
	//
	// Each test below pins one of those silent-stale combinations. The
	// builder/codegen pair must throw "untracked_param" with the same shape as the
	// existing INTERACTIVE id tests.

	/** dynamicRef target — `$template` names the referenced programmable. Outside
	 *  a repeat this would set up `trackDynamicName`; inside the fallback path it
	 *  doesn't. setParameter on `template` must reject. */
	@Test
	public function testParamDepRepeat_DynRefTarget_Builder_Throws():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "paramDepRepeatUntrackedDynRefTarget", null, Incremental);
		assertUntrackedReject(runAndCatch(() -> result.setParameter("template", "leafB")),
			"template", "param-dep repeat", "builder dynRef target");
	}

	@Test
	public function testParamDepRepeat_DynRefTarget_Codegen_Throws():Void {
		final mp = createMp();
		final inst:Dynamic = mp.paramDepRepeatUntrackedDynRefTarget.create();
		assertUntrackedReject(runAndCatch(() -> inst.setTemplate("leafB")),
			"template", "param-dep repeat", "codegen dynRef target setter");
		assertUntrackedReject(runAndCatch(() -> inst.setParameter("template", "leafA")),
			"template", "param-dep repeat", "codegen dynRef target setParameter");
	}

	/** Conditional visibility — `$mode` gates @() / @else on children inside the
	 *  body. On the runtime side, `collectChildConditionalParamRefs` folds `mode`
	 *  into `repeatParamRefs` so a setParameter triggers a full body rebuild —
	 *  must NOT throw and must NOT be marked untracked. (Codegen has no equivalent
	 *  conditional-rebuild wiring, so the codegen test below pins the throw.) */
	@Test
	public function testParamDepRepeat_ConditionalRef_Builder_TriggersRebuild():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "paramDepRepeatUntrackedCondition", null, Incremental);
		// No throw: setParameter must succeed because conditional refs ARE wired.
		final msg = runAndCatch(() -> result.setParameter("mode", "b"));
		Assert.isNull(msg, 'builder conditional rebuild: setParameter("mode", "b") must not throw (conditional refs are wired into repeatParamRefs) — got: $msg');
	}

	/** Codegen side: `_rebuildRepeat_X` only fires when the count value changes, so
	 *  a body-only conditional flip is silently dropped — must throw untracked_param. */
	@Test
	public function testParamDepRepeat_ConditionalRef_Codegen_Throws():Void {
		final mp = createMp();
		final inst:Dynamic = mp.paramDepRepeatUntrackedCondition.create();
		// `mode` is an enum [a,b] — codegen typed setter expects the int index.
		assertUntrackedReject(runAndCatch(() -> inst.setMode(1)),
			"mode", "param-dep repeat", "codegen conditional setter");
		assertUntrackedReject(runAndCatch(() -> inst.setParameter("mode", "a")),
			"mode", "param-dep repeat", "codegen conditional setParameter");
	}

	/** Child position — `$offX` is used as a body-child x coordinate. Outside the
	 *  fallback path the position would be re-tracked via trackExpression. Inside
	 *  the fallback no tracking exists. */
	@Test
	public function testParamDepRepeat_ChildPos_Builder_Throws():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "paramDepRepeatUntrackedChildPos", null, Incremental);
		assertUntrackedReject(runAndCatch(() -> result.setParameter("offX", 25)),
			"offX", "param-dep repeat", "builder child position");
	}

	@Test
	public function testParamDepRepeat_ChildPos_Codegen_Throws():Void {
		final mp = createMp();
		final inst:Dynamic = mp.paramDepRepeatUntrackedChildPos.create();
		assertUntrackedReject(runAndCatch(() -> inst.setOffX(25)),
			"offX", "param-dep repeat", "codegen child position setter");
		assertUntrackedReject(runAndCatch(() -> inst.setParameter("offX", 30)),
			"offX", "param-dep repeat", "codegen child position setParameter");
	}
}
