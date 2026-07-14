package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * @switch mixed-arm chains with a non-last `default:` arm.
 *
 * Bug shape (ProgrammableCodeGen.processSwitch, mixed-arm path): the if-chain
 * is folded in reverse and a `default:` arm REPLACES the accumulated chain,
 * so arms that appear after the default in document order are discarded. The
 * builder (resolveMatchedSwitchArm) treats default position-independently:
 * first matching non-default arm wins, default is only the fallback.
 *
 * Companion fixture: test/examples/139-codegenSwitchDefaultOrder/switchDefaultOrder.manim
 * Arms are distinguished by tile width: <=2 -> 10px, default -> 12px, >=8 -> 14px.
 */
class CodegenSwitchDefaultOrderTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/139-codegenSwitchDefaultOrder/switchDefaultOrder.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function visibleTileWidth(root:h2d.Object):Int {
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(root);
		Assert.equals(1, bitmaps.length, "expected exactly one visible arm bitmap");
		return bitmaps.length == 1 ? Std.int(bitmaps[0].tile.width) : -1;
	}

	/** Builder baseline: an arm after a non-last default still matches. */
	@Test
	public function testSwitchDefaultOrder_Builder_ArmAfterDefaultMatches():Void {
		final params = new Map<String, Dynamic>();
		params.set("n", 9);
		final result = BuilderTestBase.buildFromFile(FIXTURE, "switchDefaultOrder", params);
		Assert.equals(14, visibleTileWidth(result.object),
			"builder: n=9 must match the >=8 arm (14px) even though default precedes it");
	}

	/** Codegen: the same chain must not swallow arms after the default. */
	@Test
	public function testSwitchDefaultOrder_Codegen_ArmAfterDefaultMatches():Void {
		final inst:Dynamic = createMp().switchDefaultOrder.create();
		Assert.equals(12, visibleTileWidth(cast inst),
			"codegen: n=5 (no arm matches) falls back to the default arm (12px)");
		inst.setParameter("n", 9);
		Assert.equals(14, visibleTileWidth(cast inst),
			"codegen: n=9 must match the >=8 arm (14px) — a non-last default must not swallow later arms");
		inst.setParameter("n", 1);
		Assert.equals(10, visibleTileWidth(cast inst),
			"codegen: n=1 matches the <=2 arm (10px)");
	}
}
