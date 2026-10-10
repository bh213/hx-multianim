package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Two repeat-body divergences between codegen and builder:
 *
 * 1. Conditional gates inside a param-dependent repeat: the builder collects
 *    body conditional refs into the repeat's rebuild triggers, so
 *    setParameter("on", ...) rebuilds the repeat. The codegen marks those
 *    params untracked and the generated setter throws instead.
 *
 * 2. dynamicRef($loopVar) inside a statically-unrolled repeat: STATIC_REF
 *    substitutes the loop var, but the DYNAMIC_REF arm treats it as a literal
 *    programmable name ("i"). Both backends throw here (no programmable named
 *    0/1 exists) — the contract pinned is that the missing-target name is the
 *    RESOLVED iteration value, not the loop variable.
 *
 * Companion fixture: test/examples/141-codegenRepeatGate/repeatGate.manim
 */
class CodegenRepeatGateTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/141-codegenRepeatGate/repeatGate.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function visibleWidths(root:h2d.Object):Array<Int> {
		final ws = [for (b in BuilderTestBase.findVisibleBitmapDescendants(root)) Std.int(b.tile.width)];
		ws.sort((a, b) -> a - b);
		return ws;
	}

	static function messageOf(fn:() -> Void):Null<String> {
		try {
			fn();
		} catch (e:Dynamic) {
			return Std.string(e);
		}
		return null;
	}

	// ==================== conditional gate in a param-dependent repeat ====================

	/** Builder baseline: flipping the gate param rebuilds the repeat body. */
	@Test
	public function testCondGate_Builder_GateFlipRerenders():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "condGate", null, Incremental);
		Assert.same([4, 4, 4], visibleWidths(result.object), "builder: gate off shows the 4px else-branch x3");
		result.setParameter("on", true);
		Assert.same([6, 6, 6], visibleWidths(result.object),
			"builder: setParameter(on, true) rebuilds the repeat and shows the 6px branch x3");
	}

	/** Codegen: the same gate flip must apply, not be rejected as untracked. */
	@Test
	public function testCondGate_Codegen_GateFlipRerenders():Void {
		final inst:Dynamic = createMp().condGate.create();
		Assert.same([4, 4, 4], visibleWidths(cast inst), "codegen: gate off shows the 4px else-branch x3");
		try {
			inst.setParameter("on", true);
		} catch (e:Dynamic) {
			Assert.fail('codegen: setParameter("on", true) must rebuild the repeat like the builder, but threw: '
				+ Std.string(e));
			return;
		}
		Assert.same([6, 6, 6], visibleWidths(cast inst),
			"codegen: setParameter(on, true) must re-render the gated branch (6px x3)");
	}

	// ==================== dynamicRef($loopVar) in a static unroll ====================

	/** Builder: the loop var resolves per iteration, so the missing-target
	 *  error names the iteration value "0" (and never the loop var "i"). */
	@Test
	public function testDynRefLoopVar_Builder_ResolvesPerIteration():Void {
		final msg = messageOf(() -> BuilderTestBase.buildFromFile(FIXTURE, "dynRefLoopHost", null));
		Assert.notNull(msg, "builder: dynamicRef($i) with no matching programmable throws");
		if (msg == null) return;
		Assert.isTrue(new EReg("\\b0\\b", "").match(msg),
			'builder: missing-target message names the resolved iteration value "0" — got: $msg');
		Assert.isFalse(new EReg("\\bi\\b", "").match(msg),
			'builder: missing-target message must not name the loop variable "i" — got: $msg');
	}

	/** Codegen: same contract — the loop var must be substituted before the
	 *  dynamicRef target lookup. */
	@Test
	public function testDynRefLoopVar_Codegen_ResolvesPerIteration():Void {
		final msg = messageOf(() -> createMp().dynRefLoopHost.create());
		Assert.notNull(msg, "codegen: dynamicRef($i) with no matching programmable throws");
		if (msg == null) return;
		Assert.isTrue(new EReg("\\b0\\b", "").match(msg),
			'codegen: missing-target message must name the resolved iteration value "0" — got: $msg');
		Assert.isFalse(new EReg("\\bi\\b", "").match(msg),
			'codegen: missing-target message must not name the loop variable "i" — got: $msg');
	}
}
