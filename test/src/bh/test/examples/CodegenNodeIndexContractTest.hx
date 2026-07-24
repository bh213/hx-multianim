package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Positional index contracts between macro-generated fields and the
 * ProgrammableBuilder runtime lookups.
 *
 * - particles in a statically-unrolled repeatable: the macro emits one
 *   buildParticles(index) per unrolled iteration, but buildParticles counts
 *   PARTICLES parse nodes (one) — the second iteration's index is out of
 *   range and create() throws.
 * - conditional sibling tilegroups: the macro bakes a document-order ordinal
 *   over ALL tilegroup nodes while buildTileGroupFromProgrammable collects
 *   TileGroups from the conditional-filtered built tree — non-matching
 *   siblings shift the index space and create() throws (or picks wrong
 *   content when the counts happen to line up).
 *
 * Companion fixture: test/examples/142-codegenNodeIndex/nodeIndex.manim
 */
class CodegenNodeIndexContractTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/142-codegenNodeIndex/nodeIndex.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	/** Count instances in the VISIBLE subtree matching a predicate. */
	static function countVisible(obj:h2d.Object, pred:h2d.Object -> Bool):Int {
		var n = pred(obj) ? 1 : 0;
		for (i in 0...obj.numChildren) {
			final c = obj.getChildAt(i);
			if (c.visible)
				n += countVisible(c, pred);
		}
		return n;
	}

	static function isParticles(o:h2d.Object):Bool {
		// Exact class match — a substring test also caught the generated instance
		// class itself (…_ParticlesRepeatInstance).
		return Type.getClassName(Type.getClass(o)) == "bh.base.Particles";
	}

	/** Diagnostic: class names of all visible matches. */
	static function listVisible(obj:h2d.Object, pred:h2d.Object -> Bool, acc:Array<String>):Void {
		if (pred(obj))
			acc.push(Type.getClassName(Type.getClass(obj)));
		for (i in 0...obj.numChildren) {
			final c = obj.getChildAt(i);
			if (c.visible)
				listVisible(c, pred, acc);
		}
	}

	static function isTileGroup(o:h2d.Object):Bool {
		return Std.isOfType(o, h2d.TileGroup);
	}

	// ==================== particles in a static unroll ====================

	/** Builder baseline: two iterations build two particle systems. */
	@Test
	public function testParticlesRepeat_Builder_BuildsPerIteration():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "particlesRepeat", null);
		final n = countVisible(result.object, isParticles);
		Assert.equals(2, n,
			'builder: repeatable x2 with a particles body builds two particle systems — got $n');
	}

	/** Codegen: create() must not throw and must yield both systems. */
	@Test
	public function testParticlesRepeat_Codegen_BuildsPerIteration():Void {
		var inst:Dynamic = null;
		try {
			inst = createMp().particlesRepeat.create();
		} catch (e:Dynamic) {
			Assert.fail('codegen: particlesRepeat.create() must not throw (particles index space must match the runtime lookup) — threw: '
				+ Std.string(e));
			return;
		}
		final matches:Array<String> = [];
		listVisible(cast inst, isParticles, matches);
		Assert.equals(2, matches.length,
			'codegen: repeatable x2 with a particles body must yield two particle systems — got $matches');
	}

	// ==================== conditional sibling tilegroups ====================

	/** Builder baseline: with m=a only the a-arm tilegroup is built. */
	@Test
	public function testTgCond_Builder_OneVisibleTileGroup():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "tgCond", null);
		Assert.equals(1, countVisible(result.object, isTileGroup),
			"builder: m=a builds exactly the matching conditional tilegroup");
	}

	/** Codegen: create() must not throw and exactly one tilegroup is visible. */
	@Test
	public function testTgCond_Codegen_CreateSucceeds():Void {
		var inst:Dynamic = null;
		try {
			inst = createMp().tgCond.create();
		} catch (e:Dynamic) {
			Assert.fail('codegen: tgCond.create() must not throw (tilegroup index space must match the conditional-filtered built tree) — threw: '
				+ Std.string(e));
			return;
		}
		Assert.equals(1, countVisible(cast inst, isTileGroup),
			"codegen: m=a must show exactly one tilegroup (the a-arm)");
	}
}
