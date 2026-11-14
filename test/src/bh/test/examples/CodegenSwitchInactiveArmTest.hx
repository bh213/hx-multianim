package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Regression — codegen @switch arm rebuild must be gated on the CURRENTLY-active arm,
 * not the union of all arms' param refs. Changing a param referenced only in an inactive
 * sibling arm must not tear down + rebuild the active arm (which would restart its
 * stateanim playheads / re-seed particles). Probe via object identity.
 *
 * Companion fixture:
 * test/examples/130-switchInactiveArmRebuild/switchInactiveArmRebuild.manim
 */
class CodegenSwitchInactiveArmTest extends BuilderTestBase {
	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	@Test
	public function testCodegenSwitchActiveArmSurvivesInactiveArmParamChange():Void {
		final mp = createMp();
		final inst:Dynamic = mp.switchInactiveArmRebuild.create();
		final obj:h2d.Object = cast inst;

		var bitmaps = BuilderTestBase.findVisibleBitmapDescendants(obj);
		Assert.equals(1, bitmaps.length);
		Assert.equals(10, Std.int(bitmaps[0].tile.width));
		final before = bitmaps[0];

		// bx is referenced ONLY in the inactive arm b. Changing it must not rebuild arm a.
		inst.setParameter("bx", 99);
		bitmaps = BuilderTestBase.findVisibleBitmapDescendants(obj);
		Assert.equals(1, bitmaps.length);
		Assert.isTrue(before == bitmaps[0],
			"codegen: active arm must not be rebuilt when a param used only in an inactive arm changes");

		// Sanity: a param used by the active arm still triggers its rebuild + update.
		inst.setParameter("ax", 50);
		bitmaps = BuilderTestBase.findVisibleBitmapDescendants(obj);
		Assert.equals(1, bitmaps.length);
		Assert.equals(50, Std.int(bitmaps[0].tile.width));
	}
}
