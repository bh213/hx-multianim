package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.multianim.BuilderError;
import bh.multianim.MultiAnimBuilder.BuilderResult;

/**
 * The builder (incremental) against codegen (@:manim) on the same programmables:
 * - a layout point picked by a param (`layout(name, $idx)`, with and without `.offset()`)
 *   follows the param in codegen as in the builder;
 * - a @final computed from a param follows the param in both backends: in a bitmap, in a
 *   dynamicRef forward, and as an interactive id (whose param then cannot be set); a repeat
 *   count from a constant @final keeps the body's own params tracked;
 * - a @final, a @switch or an unconditional apply between conditionals starts a fresh chain
 *   for a later @default, in codegen as in the builder;
 * - `bit[N]` tests int params and loop variables, and comparisons test a flags param's value,
 *   in the builder as in codegen;
 * - a @switch arm whose pattern uses a param re-selects when that param changes;
 * - a value whose apply threw is applied again when it is set again;
 * - loop variables reach a tileGroup and particles inside a statically unrolled repeat;
 * - a @final inside a param-dependent repeat body takes each iteration's loop variable.
 *
 * Companion fixture: test/examples/164-codegenParityReview/codegenParityReview.manim
 */
class CodegenParityReviewTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/164-codegenParityReview/codegenParityReview.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function errorOf(fn:Void -> Void):Null<String> {
		try {
			fn();
			return null;
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	static function offsetToRoot(obj:h2d.Object, root:h2d.Object):{x:Float, y:Float} {
		var x = 0.0;
		var y = 0.0;
		var o:Null<h2d.Object> = obj;
		while (o != null && o != root) {
			x += o.x;
			y += o.y;
			o = o.parent;
		}
		return {x: x, y: y};
	}

	/** "x,y" of each visible bitmap, relative to the root, in scene-graph order. */
	static function bitmapPositions(root:h2d.Object):String {
		return [
			for (b in BuilderTestBase.findVisibleBitmapDescendants(root)) {
				final p = offsetToRoot(b, root);
				Std.int(p.x) + "," + Std.int(p.y);
			}
		].join(";");
	}

	/** x of each visible bitmap relative to the root, sorted. */
	static function bitmapXs(root:h2d.Object):String {
		final xs = [for (b in BuilderTestBase.findVisibleBitmapDescendants(root)) Std.int(offsetToRoot(b, root).x)];
		xs.sort((a, b) -> a - b);
		return xs.join(",");
	}

	static function widths(root:h2d.Object):String {
		final ws = [for (b in BuilderTestBase.findVisibleBitmapDescendants(root)) Std.int(b.tile.width)];
		ws.sort((a, b) -> a - b);
		return ws.join(",");
	}

	static function sizes(root:h2d.Object):String {
		return [for (b in BuilderTestBase.findVisibleBitmapDescendants(root)) Std.int(b.tile.width) + "x" + Std.int(b.tile.height)].join(";");
	}

	/** xMin of each tileGroup's baked content in its own space, sorted. */
	static function tileGroupXMins(root:h2d.Object):String {
		final out:Array<Int> = [];
		collectTileGroupXMins(root, out);
		out.sort((a, b) -> a - b);
		return out.join(",");
	}

	static function collectTileGroupXMins(obj:h2d.Object, out:Array<Int>):Void {
		if (Std.isOfType(obj, h2d.TileGroup)) {
			final tg:h2d.TileGroup = cast obj;
			out.push(Std.int(tg.getBounds(tg).xMin));
		}
		for (i in 0...obj.numChildren)
			collectTileGroupXMins(obj.getChildAt(i), out);
	}

	/** Particle count of every group of every particle system, sorted. */
	static function particleCounts(root:h2d.Object):String {
		final out:Array<Int> = [];
		collectParticleCounts(root, out);
		out.sort((a, b) -> a - b);
		return out.join(",");
	}

	static function collectParticleCounts(obj:h2d.Object, out:Array<Int>):Void {
		if (Std.isOfType(obj, bh.base.Particles)) {
			final particles:bh.base.Particles = cast obj;
			for (group in particles.getGroups())
				out.push(group.nparts);
		}
		for (i in 0...obj.numChildren)
			collectParticleCounts(obj.getChildAt(i), out);
	}

	/** errorOf's text of an untracked_param rejection (BuilderError's message names the slots). */
	static function isUntrackedParamError(err:Null<String>):Bool {
		return err != null && err.indexOf("incremental-unsupported") >= 0;
	}

	// ==================== A layout point picked by a param ====================

	@Test
	public function testLayoutPointByParam_Builder_FollowsTheParam():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpLayoutIdx", null, Incremental);
		Assert.equals("300,200", bitmapPositions(result.object), "builder: on point 1 of cpRow");
		result.setParameter("idx", 2);
		Assert.equals("500,200", bitmapPositions(result.object), "builder: on point 2 once idx is 2");
	}

	@Test
	public function testLayoutPointByParam_Codegen_FollowsTheParam():Void {
		final inst:Dynamic = createMp().cpLayoutIdx.create();
		Assert.equals("300,200", bitmapPositions(cast inst), "codegen: on point 1 of cpRow, not left at 0,0");
		inst.setParameter("idx", 2);
		Assert.equals("500,200", bitmapPositions(cast inst), "codegen: on point 2 once idx is 2");
	}

	@Test
	public function testLayoutPointByParamWithOffset_Builder_FollowsTheParam():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpLayoutIdxOffset", null, Incremental);
		Assert.equals("305,200", bitmapPositions(result.object), "builder: point 1 of cpRow plus 5");
		result.setParameter("idx", 2);
		Assert.equals("505,200", bitmapPositions(result.object), "builder: point 2 plus 5 once idx is 2");
	}

	@Test
	public function testLayoutPointByParamWithOffset_Codegen_FollowsTheParam():Void {
		final inst:Dynamic = createMp().cpLayoutIdxOffset.create();
		Assert.equals("305,200", bitmapPositions(cast inst), "codegen: point 1 of cpRow plus 5, not left at 0,0");
		inst.setParameter("idx", 2);
		Assert.equals("505,200", bitmapPositions(cast inst), "codegen: point 2 plus 5 once idx is 2");
	}

	// ==================== A @final computed from a param ====================

	@Test
	public function testParamDependentFinal_Builder_FollowsItsParam():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpFinalLive", null, Incremental);
		Assert.equals("10x10", sizes(result.object), "builder: dbl = x * 2 = 10 wide, y = 10 high");
		result.setParameter("x", 10);
		Assert.equals("20x10", sizes(result.object), "builder: setting x makes the @final 20 at once, not on the next unrelated change");
		result.setParameter("y", 12);
		Assert.equals("20x12", sizes(result.object), "builder: an unrelated param leaves the @final as it is");
	}

	@Test
	public function testParamDependentFinal_Codegen_FollowsItsParam():Void {
		final inst:Dynamic = createMp().cpFinalLive.create();
		Assert.equals("10x10", sizes(cast inst), "codegen: dbl = x * 2 = 10 wide, y = 10 high");
		inst.setParameter("x", 10);
		Assert.equals("20x10", sizes(cast inst), "codegen: setting x makes the @final 20 at once");
		inst.setParameter("y", 12);
		Assert.equals("20x12", sizes(cast inst), "codegen: an unrelated param leaves the @final as it is");
	}

	@Test
	public function testDynamicRefForwardThroughFinal_Builder_UpdatesTheChild():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpFinalFwd", null, Incremental);
		Assert.equals("10", widths(result.object), "builder: the child gets v = fw = 10");
		result.setParameter("x", 10);
		Assert.equals("20", widths(result.object), "builder: setting x forwards v = fw = 20 to the child");
	}

	@Test
	public function testDynamicRefForwardThroughFinal_Codegen_UpdatesTheChild():Void {
		final inst:Dynamic = createMp().cpFinalFwd.create();
		Assert.equals("10", widths(cast inst), "codegen: the child gets v = fw = 10");
		inst.setParameter("x", 10);
		Assert.equals("20", widths(cast inst), "codegen: setting x forwards v = fw = 20 to the child");
	}

	@Test
	public function testRepeatCountFromConstantFinal_Builder_KeepsBodyParamsTracked():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpFinalCount", null, Incremental);
		Assert.equals("0,10,20", bitmapXs(result.object), "builder: N = 3 iterations, 10 apart");
		final err = errorOf(() -> result.setParameter("ox", 5));
		Assert.isNull(err, 'builder: a constant @final count is no param, so the body stays incremental and ox can be set; got $err');
		Assert.equals("5,15,25", bitmapXs(result.object), "builder: every iteration moves by ox and keeps its step");
	}

	@Test
	public function testRepeatCountFromConstantFinal_Codegen_KeepsBodyParamsTracked():Void {
		final inst:Dynamic = createMp().cpFinalCount.create();
		Assert.equals("0,10,20", bitmapXs(cast inst), "codegen: N = 3 iterations, 10 apart");
		final err = errorOf(() -> inst.setParameter("ox", 5));
		Assert.isNull(err, 'codegen: a constant @final count unrolls like a literal one, so ox can be set; got $err');
		Assert.equals("5,15,25", bitmapXs(cast inst), "codegen: every iteration moves by ox and keeps its step");
	}

	@Test
	public function testInteractiveIdFromParamFinal_Builder_RejectsSettingTheParam():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpFinalId", null, Incremental);
		final err = errorOf(() -> result.setParameter("x", 6));
		Assert.isTrue(isUntrackedParamError(err),
			'builder: x reaches the frozen interactive id through a @final, so setting it throws untracked_param as it does for an id that names x; got $err');
	}

	@Test
	public function testInteractiveIdFromParamFinal_Codegen_RejectsSettingTheParam():Void {
		final inst:Dynamic = createMp().cpFinalId.create();
		final err = errorOf(() -> inst.setParameter("x", 6));
		Assert.notNull(err, "codegen: x reaches the frozen interactive id through a @final, so setting it throws");
		Assert.stringContains("interactive id", Std.string(err), "codegen: the rejection names the interactive id");
	}

	// ==================== A chain broken by a @final, a @switch or an apply ====================

	@Test
	public function testDefaultAfterChainBrokenByFinal_Builder_StartsAFreshChain():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpChainFinal", null, Incremental);
		Assert.equals("4,8", widths(result.object), "builder: a true, and the @default of the chain after the @final shows with b false");
		result.setParameter("b", true);
		Assert.equals("4,6", widths(result.object), "builder: b true hides the @default");
		result.setParameter("b", false);
		Assert.equals("4,8", widths(result.object), "builder: b false shows it again");
	}

	@Test
	public function testDefaultAfterChainBrokenByFinal_Codegen_StartsAFreshChain():Void {
		final inst:Dynamic = createMp().cpChainFinal.create();
		Assert.equals("4,8", widths(cast inst), "codegen: the @final starts a fresh chain, so the @default shows with b false although a is true");
		inst.setParameter("b", true);
		Assert.equals("4,6", widths(cast inst), "codegen: b true hides the @default");
		inst.setParameter("b", false);
		Assert.equals("4,8", widths(cast inst), "codegen: b false shows it again");
	}

	@Test
	public function testDefaultAfterChainBrokenBySwitch_Builder_StartsAFreshChain():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpChainSwitch", null, Incremental);
		Assert.equals("4,8,10", widths(result.object), "builder: a true, arm p, and the @default of the chain after the @switch");
		result.setParameter("m", "q");
		Assert.equals("4,8,12", widths(result.object), "builder: arm q, the @default still shown");
	}

	@Test
	public function testDefaultAfterChainBrokenBySwitch_Codegen_StartsAFreshChain():Void {
		final inst:Dynamic = createMp().cpChainSwitch.create();
		Assert.equals("4,8,10", widths(cast inst), "codegen: the @switch starts a fresh chain, so the @default shows with b false although a is true");
		inst.setParameter("m", "q");
		Assert.equals("4,8,12", widths(cast inst), "codegen: arm q, the @default still shown");
	}

	@Test
	public function testDefaultAfterChainBrokenByApply_Builder_StartsAFreshChain():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpChainApply", null, Incremental);
		Assert.equals("4,8", widths(result.object), "builder: a true, and the @default of the chain after the apply shows with b false");
	}

	@Test
	public function testDefaultAfterChainBrokenByApply_Codegen_StartsAFreshChain():Void {
		final inst:Dynamic = createMp().cpChainApply.create();
		Assert.equals("4,8", widths(cast inst), "codegen: the unconditional apply starts a fresh chain, so the @default shows with b false although a is true");
	}

	// ==================== bit[N] and comparisons beyond their usual param types ====================

	@Test
	public function testBitTestOnIntParam_Builder_TestsTheBit():Void {
		var result:Null<BuilderResult> = null;
		final err = errorOf(() -> result = BuilderTestBase.buildFromFile(FIXTURE, "cpBitInt", null, Incremental));
		Assert.isNull(err, 'builder: bit[N] on an int param tests that bit of its value, as codegen does; got $err');
		if (result == null) return;
		Assert.equals("6", widths(result.object), "builder: bits = 4 has bit 2, not bit 0");
		result.setParameter("bits", 1);
		Assert.equals("8", widths(result.object), "builder: bits = 1 has bit 0, not bit 2");
	}

	@Test
	public function testBitTestOnIntParam_Codegen_TestsTheBit():Void {
		final inst:Dynamic = createMp().cpBitInt.create();
		Assert.equals("6", widths(cast inst), "codegen: bits = 4 has bit 2, not bit 0");
		inst.setParameter("bits", 1);
		Assert.equals("8", widths(cast inst), "codegen: bits = 1 has bit 0, not bit 2");
	}

	@Test
	public function testBitTestOnLoopVariable_Builder_TestsTheBit():Void {
		var result:Null<BuilderResult> = null;
		final err = errorOf(() -> result = BuilderTestBase.buildFromFile(FIXTURE, "cpBitLoop", null, Incremental));
		Assert.isNull(err, 'builder: bit[N] on a loop variable tests that bit of the iteration, as codegen does; got $err');
		if (result == null) return;
		Assert.equals("10,30", bitmapXs(result.object), "builder: only the odd iterations draw");
	}

	@Test
	public function testBitTestOnLoopVariable_Codegen_TestsTheBit():Void {
		final inst:Dynamic = createMp().cpBitLoop.create();
		Assert.equals("10,30", bitmapXs(cast inst), "codegen: only the odd iterations draw");
	}

	@Test
	public function testComparisonOnFlagsParam_Builder_ComparesItsValue():Void {
		var result:Null<BuilderResult> = null;
		final err = errorOf(() -> result = BuilderTestBase.buildFromFile(FIXTURE, "cpFlagsCmp", null, Incremental));
		Assert.isNull(err, 'builder: a comparison on a flags param compares its value, as codegen does; got $err');
		if (result == null) return;
		Assert.equals("6", widths(result.object), "builder: f = 3 is >= 2");
		result.setParameter("f", 1);
		Assert.equals("8", widths(result.object), "builder: f = 1 is < 2");
	}

	@Test
	public function testComparisonOnFlagsParam_Codegen_ComparesItsValue():Void {
		final inst:Dynamic = createMp().cpFlagsCmp.create();
		Assert.equals("6", widths(cast inst), "codegen: f = 3 is >= 2");
		inst.setParameter("f", 1);
		Assert.equals("8", widths(cast inst), "codegen: f = 1 is < 2");
	}

	// ==================== A @switch arm whose pattern uses a param ====================

	@Test
	public function testSwitchArmPatternParam_Builder_ReselectsWhenItChanges():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpSwitchRef", null, Incremental);
		Assert.equals("8", widths(result.object), "builder: hp 5 <= max 10");
		result.setParameter("max", 3);
		Assert.equals("12", widths(result.object), "builder: hp 5 is no longer <= max 3, so the default arm shows");
		result.setParameter("max", 10);
		Assert.equals("8", widths(result.object), "builder: and back once max is 10 again");
	}

	@Test
	public function testSwitchArmPatternParam_Codegen_ReselectsWhenItChanges():Void {
		final inst:Dynamic = createMp().cpSwitchRef.create();
		Assert.equals("8", widths(cast inst), "codegen: hp 5 <= max 10");
		inst.setParameter("max", 3);
		Assert.equals("12", widths(cast inst), "codegen: hp 5 is no longer <= max 3, so the default arm shows");
		inst.setParameter("max", 10);
		Assert.equals("8", widths(cast inst), "codegen: and back once max is 10 again");
	}

	// ==================== A value whose apply threw, set again ====================

	@Test
	public function testFailedTemplateSwapSetAgain_Builder_IsAppliedAgain():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpSwapRetry", null, Incremental);
		Assert.equals("10", widths(result.object), "builder: cpSwapA is placed");
		Assert.notNull(errorOf(() -> result.setParameter("tmpl", "cpSwapB")), "builder: cpSwapB has no `p`, so the swap throws");
		Assert.notNull(errorOf(() -> result.setParameter("tmpl", "cpSwapB")),
			"builder: the same value set again is applied again, and throws again while the cause stands");
		Assert.equals("10", widths(result.object), "builder: cpSwapA stays in place");
	}

	@Test
	public function testFailedTemplateSwapSetAgain_Codegen_IsAppliedAgain():Void {
		final inst:Dynamic = createMp().cpSwapRetry.create();
		Assert.equals("10", widths(cast inst), "codegen: cpSwapA is placed");
		Assert.notNull(errorOf(() -> inst.setParameter("tmpl", "cpSwapB")), "codegen: cpSwapB has no `p`, so the swap throws");
		Assert.notNull(errorOf(() -> inst.setParameter("tmpl", "cpSwapB")),
			"codegen: the same value set again is applied again, and throws again while the cause stands, not skipped as unchanged");
		Assert.equals("10", widths(cast inst), "codegen: cpSwapA stays in place");
	}

	// ==================== A repeat in a flow ====================

	static function reflowAll(o:h2d.Object):Void {
		final f = Std.downcast(o, h2d.Flow);
		if (f != null) f.reflow();
		for (i in 0...o.numChildren)
			reflowAll(o.getChildAt(i));
	}

	/** x (relative to the root) of each drawn bitmap `w` wide, the flows laid out first. */
	static function xsOfWidth(root:h2d.Object, w:Int):String {
		reflowAll(root);
		return [
			for (b in BuilderTestBase.findVisibleBitmapDescendants(root))
				if (Std.int(b.tile.width) == w) Std.int(offsetToRoot(b, root).x)
		].join(",");
	}

	/** The flow lays out each item of the repeat (10 wide) between the 5-wide and 7-wide bitmaps. */
	static function checkFlowItems(root:h2d.Object, items:String, last:String, label:String):Void {
		Assert.equals(items, xsOfWidth(root, 10), '$label: the items, laid out by the flow');
		Assert.equals(last, xsOfWidth(root, 7), '$label: the element after them');
	}

	@Test
	public function testConditionalRepeatInFlow_Builder_LaysOutEachItem():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpFlowRepeatConst", null, Incremental);
		checkFlowItems(result.object, "7,19,31", "43", "builder");
		result.setParameter("open", false);
		checkFlowItems(result.object, "", "7", "builder, hidden");
		result.setParameter("open", true);
		checkFlowItems(result.object, "7,19,31", "43", "builder, shown again");
	}

	@Test
	public function testConditionalRepeatInFlow_Codegen_LaysOutEachItem():Void {
		final inst:Dynamic = createMp().cpFlowRepeatConst.create();
		checkFlowItems(cast inst, "7,19,31", "43", "codegen");
		inst.setParameter("open", false);
		checkFlowItems(cast inst, "", "7", "codegen, hidden");
		inst.setParameter("open", true);
		checkFlowItems(cast inst, "7,19,31", "43", "codegen, shown again");
	}

	@Test
	public function testConditionalRepeatInFlowShownLater_Builder_LaysOutEachItem():Void {
		final params:Map<String, Dynamic> = ["open" => false];
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpFlowRepeatConst", params, Incremental);
		checkFlowItems(result.object, "", "7", "builder, hidden at build");
		result.setParameter("open", true);
		checkFlowItems(result.object, "7,19,31", "43", "builder, first shown");
		result.setParameter("open", false);
		checkFlowItems(result.object, "", "7", "builder, hidden again");
	}

	@Test
	public function testParamCountRepeatInFlow_Builder_LaysOutEachItem():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpFlowRepeatCount", null, Incremental);
		checkFlowItems(result.object, "7,19,31", "43", "builder");
		result.setParameter("n", 2);
		checkFlowItems(result.object, "7,19", "31", "builder, n 2");
		result.setParameter("n", 4);
		checkFlowItems(result.object, "7,19,31,43", "55", "builder, n 4");
	}

	@Test
	public function testParamCountRepeatInFlow_Codegen_LaysOutEachItem():Void {
		final inst:Dynamic = createMp().cpFlowRepeatCount.create();
		checkFlowItems(cast inst, "7,19,31", "43", "codegen");
		inst.setParameter("n", 2);
		checkFlowItems(cast inst, "7,19", "31", "codegen, n 2");
		inst.setParameter("n", 4);
		checkFlowItems(cast inst, "7,19,31,43", "55", "codegen, n 4");
	}

	@Test
	public function testConditionalParamCountRepeatInFlow_Builder_RebuildsWhileHidden():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpFlowRepeatBoth", null, Incremental);
		checkFlowItems(result.object, "7,19,31", "43", "builder");
		result.setParameter("open", false);
		result.setParameter("n", 2);
		checkFlowItems(result.object, "", "7", "builder, hidden, n set");
		result.setParameter("open", true);
		checkFlowItems(result.object, "7,19", "31", "builder, shown with n 2");
		result.setParameter("n", 4);
		checkFlowItems(result.object, "7,19,31,43", "55", "builder, n 4 while shown");
	}

	@Test
	public function testConditionalParamCountRepeatInFlow_Codegen_RebuildsWhileHidden():Void {
		final inst:Dynamic = createMp().cpFlowRepeatBoth.create();
		checkFlowItems(cast inst, "7,19,31", "43", "codegen");
		inst.setParameter("open", false);
		inst.setParameter("n", 2);
		checkFlowItems(cast inst, "", "7", "codegen, hidden, n set");
		inst.setParameter("open", true);
		checkFlowItems(cast inst, "7,19", "31", "codegen, shown with n 2");
		inst.setParameter("n", 4);
		checkFlowItems(cast inst, "7,19,31,43", "55", "codegen, n 4 while shown");
	}

	@Test
	public function testRepeatFlowPropsInFlow_Builder_GoToEachItem():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpFlowRepeatProps", null, Incremental);
		Assert.equals("", xsOfWidth(result.object, 4), "builder: hidden at build");
		result.setParameter("show", true);
		Assert.equals("36,36", xsOfWidth(result.object, 4), "builder: each item right-aligned by the repeat's @flow.halign");
		Assert.equals("0", xsOfWidth(result.object, 10), "builder: the other element keeps its place");
		result.setParameter("show", false);
		result.setParameter("show", true);
		Assert.equals("36,36", xsOfWidth(result.object, 4), "builder: and again after a hide");
		final full = BuilderTestBase.buildFromFile(FIXTURE, "cpFlowRepeatProps", ["show" => true]);
		Assert.equals("36,36", xsOfWidth(full.object, 4), "full build: the same");
	}

	@Test
	public function testRepeatFlowPropsInFlow_Codegen_GoToEachItem():Void {
		final inst:Dynamic = createMp().cpFlowRepeatProps.create();
		Assert.equals("", xsOfWidth(cast inst, 4), "codegen: hidden at create");
		inst.setParameter("show", true);
		Assert.equals("36,36", xsOfWidth(cast inst, 4), "codegen: each item right-aligned by the repeat's @flow.halign");
		Assert.equals("0", xsOfWidth(cast inst, 10), "codegen: the other element keeps its place");
		inst.setParameter("show", false);
		inst.setParameter("show", true);
		Assert.equals("36,36", xsOfWidth(cast inst, 4), "codegen: and again after a hide");
	}

	@Test
	public function testRepeatInFlow_FullBuild_IsTheReference():Void {
		// A non-incremental build places the items in the flow (no tracking): what the others match
		checkFlowItems(BuilderTestBase.buildFromFile(FIXTURE, "cpFlowRepeatConst", null).object, "7,19,31", "43", "full build");
		checkFlowItems(BuilderTestBase.buildFromFile(FIXTURE, "cpFlowRepeatCount", null).object, "7,19,31", "43", "full build, count");
	}

	// ==================== A hidden element's expressions ====================

	/** Hidden, an element on `layout(cpRow, $idx)` is not placed: $idx past the layout's end throws
	 *  nothing, and shown it sits on the point $idx names then (500, 200 for 2). */
	function checkHiddenLayout(setParameter:(String, Dynamic) -> Void, root:h2d.Object, label:String):Void {
		Assert.equals("300,200", bitmapPositions(root), '$label: on point 1');
		setParameter("on", false);
		Assert.isNull(errorOf(() -> setParameter("idx", 5)), '$label: hidden, a point past the end is not looked up');
		setParameter("idx", 2);
		Assert.equals("", bitmapPositions(root), '$label: still hidden');
		Assert.isNull(errorOf(() -> setParameter("on", true)), '$label: shown on a point that exists');
		Assert.equals("500,200", bitmapPositions(root), '$label: shown, on the point set while hidden');
		setParameter("idx", 0);
		Assert.equals("100,200", bitmapPositions(root), '$label: and it follows the param again');
	}

	@Test
	public function testHiddenElementExpressions_Builder_AreNotEvaluated():Void {
		for (name in ["cpLayoutHidden", "cpLayoutHiddenNested"]) {
			final result = BuilderTestBase.buildFromFile(FIXTURE, name, null, Incremental);
			checkHiddenLayout((k, v) -> result.setParameter(k, v), result.object, 'builder $name');
		}
	}

	@Test
	public function testHiddenElementExpressions_Codegen_AreNotEvaluated():Void {
		final mp = createMp();
		final insts:Array<Dynamic> = [mp.cpLayoutHidden.create(), mp.cpLayoutHiddenNested.create()];
		for (inst in insts)
			checkHiddenLayout((k, v) -> inst.setParameter(k, v), cast inst, 'codegen ${Type.getClassName(Type.getClass(inst))}');
	}

	// ==================== A @final in a @switch arm not shown at build ====================

	@Test
	public function testFinalInSwitchArmShownLater_Builder_FollowsItsParam():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpSwitchArmFinal", null, Incremental);
		result.setParameter("mode", "b");
		Assert.equals("10", widths(result.object), "builder: arm b draws $W = 2 * 5");
		result.setParameter("x", 7);
		Assert.equals("14", widths(result.object), "builder: arm b follows $x through its @final");
	}

	@Test
	public function testFinalInSwitchArmShownLater_Codegen_FollowsItsParam():Void {
		final inst:Dynamic = createMp().cpSwitchArmFinal.create();
		inst.setParameter("mode", "b");
		Assert.equals("10", widths(cast inst), "codegen: arm b draws $W = 2 * 5");
		inst.setParameter("x", 7);
		Assert.equals("14", widths(cast inst), "codegen: arm b follows $x through its @final");
	}

	@Test
	public function testFailedTemplateSwapInABatchSetAgain_Builder_IsAppliedAgain():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpSwapRetry", null, Incremental);
		result.beginUpdate();
		result.setParameter("tmpl", "cpSwapB");
		Assert.notNull(errorOf(() -> result.endUpdate()), "builder: the batch's swap throws");
		Assert.notNull(errorOf(() -> result.setParameter("tmpl", "cpSwapB")),
			"builder: the same value set again after the batch is applied again");
		Assert.equals("10", widths(result.object), "builder: cpSwapA stays in place");
	}

	@Test
	public function testFailedTemplateSwapInABatchSetAgain_Codegen_IsAppliedAgain():Void {
		final inst:Dynamic = createMp().cpSwapRetry.create();
		inst.beginUpdate();
		inst.setParameter("tmpl", "cpSwapB");
		Assert.notNull(errorOf(() -> inst.endUpdate()), "codegen: the batch's swap throws");
		Assert.notNull(errorOf(() -> inst.setParameter("tmpl", "cpSwapB")),
			"codegen: the same value set again after the batch is applied again, not skipped as unchanged");
		Assert.equals("10", widths(cast inst), "codegen: cpSwapA stays in place");
	}

	// ==================== Loop variables in subtrees codegen hands to the builder ====================

	@Test
	public function testTileGroupInStaticRepeat_Builder_SeesTheLoopVariable():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpTgRepeat", null);
		Assert.equals("0,3", tileGroupXMins(result.object), "builder: copy i bakes its bitmap at i * 3");
	}

	@Test
	public function testTileGroupInStaticRepeat_Codegen_SeesTheLoopVariable():Void {
		var inst:Dynamic = null;
		final err = errorOf(() -> inst = createMp().cpTgRepeat.create());
		Assert.isNull(err, 'codegen: a tileGroup in an unrolled repeat must see the loop variable; got $err');
		if (inst == null) return;
		Assert.equals("0,3", tileGroupXMins(cast inst), "codegen: copy i bakes its bitmap at i * 3");
	}

	@Test
	public function testParticlesInStaticRepeat_Builder_SeeTheLoopVariable():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpParticlesRepeat", null);
		Assert.equals("3,4", particleCounts(result.object), "builder: copy i has i + 3 particles");
	}

	@Test
	public function testParticlesInStaticRepeat_Codegen_SeeTheLoopVariable():Void {
		var inst:Dynamic = null;
		final err = errorOf(() -> inst = createMp().cpParticlesRepeat.create());
		Assert.isNull(err, 'codegen: particles in an unrolled repeat must see the loop variable; got $err');
		if (inst == null) return;
		Assert.equals("3,4", particleCounts(cast inst), "codegen: copy i has i + 3 particles");
	}

	// ==================== A @final inside a param-dependent repeat body ====================

	@Test
	public function testFinalInParamRepeatBody_Builder_TakesEachIterationsLoopVariable():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpFinalInParamRepeat", null, Incremental);
		Assert.equals("4,5", widths(result.object), "builder: W = 4 + i for each of the n = 2 iterations");
		result.setParameter("n", 3);
		Assert.equals("4,5,6", widths(result.object), "builder: a third iteration with W = 6");
	}

	@Test
	public function testFinalInParamRepeatBody_Codegen_TakesEachIterationsLoopVariable():Void {
		var inst:Dynamic = null;
		final err = errorOf(() -> inst = createMp().cpFinalInParamRepeat.create());
		Assert.isNull(err, 'codegen: a @final in a param-dependent repeat body must build; got $err');
		if (inst == null) return;
		Assert.equals("4,5", widths(cast inst), "codegen: W = 4 + i for each of the n = 2 iterations");
		inst.setParameter("n", 3);
		Assert.equals("4,5,6", widths(cast inst), "codegen: a third iteration with W = 6");
	}

	// ==================== A param forwarded into several dynamicRefs ====================

	@Test
	public function testParamForwardedIntoTwoDynamicRefs_Builder_FiresTheRebuildListenersOnce():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpFwdTwice", null, Incremental);
		var fired = 0;
		result.addRebuildListener(() -> fired++);
		result.setParameter("v", 6);
		Assert.equals("6,6", widths(result.object), "precondition: both children follow $v");
		Assert.equals(1, fired, "builder: one setParameter, one rebuild of the host");
	}

	@Test
	public function testParamForwardedIntoTwoDynamicRefs_Codegen_FiresTheRebuildListenersOnce():Void {
		final inst:Dynamic = createMp().cpFwdTwice.create();
		var fired = 0;
		inst.addRebuildListener(() -> fired++);
		inst.setParameter("v", 6);
		Assert.equals("6,6", widths(cast inst), "precondition: both children follow $v");
		Assert.equals(1, fired, "codegen: one setParameter, one rebuild of the instance, as in the builder; not once more per child it forwards into");
		fired = 0;
		inst.beginUpdate();
		inst.setParameter("v", 8);
		inst.endUpdate();
		Assert.equals(1, fired, "codegen: one batch, one rebuild of the instance");
		fired = 0;
		(inst.getDynamicRef("c1") : BuilderResult).setParameter("v", 9);
		Assert.equals(1, fired, "codegen: a child's own setParameter still reaches the instance's listeners");
	}

	// ==================== An apply whose value uses a param ====================

	/** The parent of the bitmap `width` wide under `root`. */
	static function parentOfWidth(root:h2d.Object, width:Int):Null<h2d.Object> {
		for (b in BuilderTestBase.findVisibleBitmapDescendants(root))
			if (Std.int(b.tile.width) == width)
				return b.parent;
		return null;
	}

	@Test
	public function testValueDependentApply_Builder_UnrelatedParamLeavesTheParent():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpApplyValueGate", null, Incremental);
		final point = parentOfWidth(result.object, 10);
		Assert.notNull(point);
		if (point == null) return;
		Assert.floatEquals(0.5, point.alpha, 0.001, "precondition: the apply's alpha $a");
		point.alpha = 0.3;
		result.setParameter("other", 6);
		Assert.floatEquals(0.3, point.alpha, 0.001, "builder: a param the apply does not use leaves the alpha the game set");
		result.setParameter("a", 0.8);
		Assert.floatEquals(0.8, point.alpha, 0.001, "builder: a change of $a applies it");
	}

	@Test
	public function testValueDependentApply_Codegen_UnrelatedParamLeavesTheParent():Void {
		final inst:Dynamic = createMp().cpApplyValueGate.create();
		final point = parentOfWidth(cast inst, 10);
		Assert.notNull(point);
		if (point == null) return;
		Assert.floatEquals(0.5, point.alpha, 0.001, "precondition: the apply's alpha $a");
		point.alpha = 0.3;
		inst.setParameter("other", 6);
		Assert.floatEquals(0.3, point.alpha, 0.001, "codegen: a param the apply does not use leaves the alpha the game set, as in the builder");
		inst.setParameter("a", 0.8);
		Assert.floatEquals(0.8, point.alpha, 0.001, "codegen: a change of $a applies it");
		point.alpha = 0.3;
		inst.beginUpdate();
		inst.setParameter("other", 8);
		inst.endUpdate();
		Assert.floatEquals(0.3, point.alpha, 0.001, "codegen: nor does a batch of it");
	}

	@Test
	public function testValueDependentUnconditionalApply_Builder_UnrelatedParamLeavesTheParent():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "cpApplyValueUncond", null, Incremental);
		final point = parentOfWidth(result.object, 10);
		Assert.notNull(point);
		if (point == null) return;
		Assert.floatEquals(0.5, point.alpha, 0.001, "precondition: the apply's alpha $a");
		point.alpha = 0.3;
		result.setParameter("other", 6);
		Assert.floatEquals(0.3, point.alpha, 0.001, "builder: a param the apply does not use leaves the alpha the game set");
		result.setParameter("a", 0.8);
		Assert.floatEquals(0.8, point.alpha, 0.001, "builder: a change of $a applies it");
	}

	@Test
	public function testValueDependentUnconditionalApply_Codegen_UnrelatedParamLeavesTheParent():Void {
		final inst:Dynamic = createMp().cpApplyValueUncond.create();
		final point = parentOfWidth(cast inst, 10);
		Assert.notNull(point);
		if (point == null) return;
		Assert.floatEquals(0.5, point.alpha, 0.001, "precondition: the apply's alpha $a");
		point.alpha = 0.3;
		inst.setParameter("other", 6);
		Assert.floatEquals(0.3, point.alpha, 0.001, "codegen: a param the apply does not use leaves the alpha the game set");
		inst.setParameter("a", 0.8);
		Assert.floatEquals(0.8, point.alpha, 0.001, "codegen: a change of $a applies it");
	}
}
