package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * dynamicRef lookup-key contract parity between builder and codegen.
 *
 * 1) Unnamed sibling dynamicRef sites referring to the same programmable collide
 *    on the map key. The builder stores per-writer arrays and getDynamicRef
 *    throws on arr.length > 1 to force #name disambiguation
 *    (BuilderResult.getDynamicRef, MultiAnimBuilder.hx). Codegen's
 *    dynamicRefFields is a plain Map keyed by the target programmable name, so
 *    the second site silently overwrites the first — getDynamicRef returns the
 *    last-built result with no signal that another site was shadowed.
 *
 * 2) #name dynamicRef($param) — the explicit #name must be the stable lookup key
 *    across template swaps (builder resolveDynamicRefKey: explicit name wins;
 *    binding.stableKey is only renamed for unnamed sites). Codegen's dynamic-name
 *    branch drops the explicit name and the generated dispatcher compares against
 *    the live template name (_dynref_name_X), so getDynamicRef("name") returns
 *    null and the working key changes whenever the template param changes. The
 *    literal-target variant (#name dynamicRef($literalProg)) was already aligned;
 *    this pins the param-driven variant.
 *
 * Companion fixture:
 * test/examples/133-codegenDynRefKeyContract/dynRefKeyContract.manim
 */
class CodegenDynRefKeyContractTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/133-codegenDynRefKeyContract/dynRefKeyContract.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function runAndCatch(fn:() -> Void):Null<String> {
		try { fn(); return null; }
		catch (e:Dynamic) return Std.string(e);
	}

	/** Asserts the single visible bitmap under `obj` has the given tile width —
	 *  identifies which leaf programmable a dynamicRef result built (A=11, B=22). */
	static function assertLeafWidth(obj:h2d.Object, width:Int, label:String):Void {
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(obj);
		Assert.equals(1, bitmaps.length, label + ": expected exactly one leaf bitmap");
		if (bitmaps.length == 1)
			Assert.equals(width, Std.int(bitmaps[0].tile.width), label);
	}

	/** Builder baseline: two unnamed sibling sites on the same programmable
	 *  collide — getDynamicRef must throw to force #name disambiguation. */
	@Test
	public function testUnnamedCollision_Builder_ThrowsOnLookup():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "dynRefUnnamedCollision", null);
		final msg = runAndCatch(() -> result.getDynamicRef("dynKeyLeafA"));
		Assert.notNull(msg, "builder: getDynamicRef on a collided unnamed key must throw");
		if (msg != null)
			Assert.isTrue(msg.indexOf("collide") >= 0,
				"builder: collision message must point at #name disambiguation — got: " + msg);
	}

	/** Codegen: the same lookup must throw instead of silently returning the
	 *  last-built site. */
	@Test
	public function testUnnamedCollision_Codegen_ThrowsOnLookup():Void {
		final inst:Dynamic = createMp().dynRefUnnamedCollision.create();
		final msg = runAndCatch(() -> {
			final r:Dynamic = inst.getDynamicRef("dynKeyLeafA");
			if (r == null) throw "returned null instead of throwing";
		});
		Assert.notNull(msg,
			"codegen: getDynamicRef on a collided unnamed key must throw like the builder (currently last-writer-wins, returns one site silently)");
		if (msg != null)
			Assert.isTrue(msg != "returned null instead of throwing" && msg.indexOf("collide") >= 0,
				"codegen: collision must surface as a thrown disambiguation error — got: " + msg);
	}

	/** Builder baseline: #panel dynamicRef($tpl) stays addressable as "panel"
	 *  before and after the template param swaps. */
	@Test
	public function testNamedDynamicTarget_Builder_KeyStableAcrossSwap():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "dynRefNamedDynamicTarget", null, Incremental);
		final before = result.getDynamicRef("panel");
		Assert.notNull(before, "builder: getDynamicRef(\"panel\") must resolve the explicit #name");
		assertLeafWidth(before.object, 11, "builder before swap: default tpl=dynKeyLeafA");

		result.setParameter("tpl", "dynKeyLeafB");
		final after = result.getDynamicRef("panel");
		Assert.notNull(after, "builder: \"panel\" must remain the key after the template swap");
		assertLeafWidth(after.object, 22, "builder after swap: tpl=dynKeyLeafB");
	}

	/** Codegen: the explicit #name must be the lookup key for the param-driven
	 *  template variant too — before and after the swap. Currently keyed by the
	 *  live template name, so "panel" resolves to null. */
	@Test
	public function testNamedDynamicTarget_Codegen_KeyStableAcrossSwap():Void {
		final inst:Dynamic = createMp().dynRefNamedDynamicTarget.create();
		Assert.isTrue(inst.hasDynamicRef("panel"),
			"codegen: hasDynamicRef(\"panel\") must report the explicit #name (currently keyed by template name)");
		final before:Dynamic = inst.getDynamicRef("panel");
		Assert.notNull(before,
			"codegen: getDynamicRef(\"panel\") must resolve the explicit #name (currently keyed by template name)");
		if (before != null)
			assertLeafWidth(before.object, 11, "codegen before swap: default tpl=dynKeyLeafA");

		inst.setParameter("tpl", "dynKeyLeafB");
		final after:Dynamic = inst.getDynamicRef("panel");
		Assert.notNull(after, "codegen: \"panel\" must remain the key after the template swap");
		if (after != null)
			assertLeafWidth(after.object, 22, "codegen after swap: tpl=dynKeyLeafB");
	}
}
