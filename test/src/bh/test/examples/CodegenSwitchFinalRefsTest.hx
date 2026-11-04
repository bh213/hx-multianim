package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.base.TweenManager;

/**
 * Codegen (@:manim) instances against the builder on the same programmables:
 * - a @switch inside a constant-count repeatable: every unrolled copy is the same parse
 *   node, so every copy must ask the builder for the same switch, with its loop variable;
 * - @final constants in the subtrees codegen hands to the builder (switch arms, particles,
 *   tileGroup) are in scope there as they are in the builder's own build;
 * - a template swap whose build throws leaves the old template in place;
 * - a fade-out runs on when an unrelated param changes meanwhile, and a batch that sets a
 *   param without a transition first still fades.
 *
 * Companion fixture: test/examples/161-codegenSwitchFinalRefs/switchFinalRefs.manim
 */
class CodegenSwitchFinalRefsTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/161-codegenSwitchFinalRefs/switchFinalRefs.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function widths(root:h2d.Object):String {
		final ws = [for (b in BuilderTestBase.findVisibleBitmapDescendants(root)) Std.int(b.tile.width)];
		ws.sort((a, b) -> a - b);
		return ws.join(",");
	}

	static function errorOf(fn:Void -> Void):Null<String> {
		try {
			fn();
			return null;
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	static function anyDescendantTweened(root:h2d.Object, tm:TweenManager):Bool {
		if (tm.hasTweens(root)) return true;
		for (i in 0...root.numChildren)
			if (anyDescendantTweened(root.getChildAt(i), tm)) return true;
		return false;
	}

	static function findBitmapByWidth(root:h2d.Object, w:Int):Null<h2d.Bitmap> {
		for (b in allBitmaps(root))
			if (Std.int(b.tile.width) == w) return b;
		return null;
	}

	static function allBitmaps(root:h2d.Object):Array<h2d.Bitmap> {
		final out:Array<h2d.Bitmap> = [];
		if (Std.isOfType(root, h2d.Bitmap)) out.push(cast root);
		for (i in 0...root.numChildren)
			for (b in allBitmaps(root.getChildAt(i)))
				out.push(b);
		return out;
	}

	static function findParticles(obj:h2d.Object):Null<bh.base.Particles> {
		if (Std.isOfType(obj, bh.base.Particles)) return cast obj;
		for (i in 0...obj.numChildren) {
			final found = findParticles(obj.getChildAt(i));
			if (found != null) return found;
		}
		return null;
	}

	static function findTileGroup(obj:h2d.Object):Null<h2d.TileGroup> {
		if (Std.isOfType(obj, h2d.TileGroup)) return cast obj;
		for (i in 0...obj.numChildren) {
			final found = findTileGroup(obj.getChildAt(i));
			if (found != null) return found;
		}
		return null;
	}

	// ==================== @switch inside a constant-count repeatable ====================

	@Test
	public function testSwitchInRepeat_Builder_BuildsEveryCopyAndTheNextSwitch():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "swInRepeat", null, Incremental);
		Assert.equals("8,8,16", widths(result.object), "builder: two copies of arm a, then side l");
		result.setParameter("mode", "b");
		Assert.equals("12,12,16", widths(result.object), "builder: both copies flip to arm b");
	}

	@Test
	public function testSwitchInRepeat_Codegen_BuildsEveryCopyAndTheNextSwitch():Void {
		var inst:Dynamic = null;
		final err = errorOf(() -> inst = createMp().swInRepeat.create());
		Assert.isNull(err, 'codegen: create() must build every unrolled copy of the switch; got $err');
		if (inst == null) return;
		Assert.equals("8,8,16", widths(cast inst), "codegen: two copies of arm a, then side l (the switch after the repeat)");
		inst.setParameter("mode", "b");
		Assert.equals("12,12,16", widths(cast inst), "codegen: both copies flip to arm b");
		inst.setParameter("side", "r");
		Assert.equals("12,12,20", widths(cast inst), "codegen: the switch after the repeat flips to side r");
	}

	@Test
	public function testSwitchInRepeat_Codegen_ArmSeesTheLoopVariable():Void {
		var inst:Dynamic = null;
		final err = errorOf(() -> inst = createMp().swInRepeatLoopVar.create());
		Assert.isNull(err, 'codegen: an arm using $$i must build; got $err');
		if (inst == null) return;
		final ys = [for (b in BuilderTestBase.findVisibleBitmapDescendants(cast inst)) Std.int(b.y)];
		ys.sort((a, b) -> a - b);
		Assert.equals("0,5", ys.join(","), "codegen: copy $i sits at y = $i * 5");
	}

	// ==================== @final in subtrees codegen hands to the builder ====================

	@Test
	public function testFinalInSwitchArm_Codegen_IsInScope():Void {
		final builderResult = BuilderTestBase.buildFromFile(FIXTURE, "swFinal", null, Incremental);
		Assert.equals("20", widths(builderResult.object), "builder: arm a draws $W = 20 wide");

		var inst:Dynamic = null;
		final err = errorOf(() -> inst = createMp().swFinal.create());
		Assert.isNull(err, 'codegen: an arm using a @final must build; got $err');
		if (inst == null) return;
		Assert.equals("20", widths(cast inst), "codegen: arm a draws $W = 20 wide");
	}

	@Test
	public function testFinalInParticles_Codegen_IsInScope():Void {
		var inst:Dynamic = null;
		final err = errorOf(() -> inst = createMp().particlesFinal.create());
		Assert.isNull(err, 'codegen: particles using a @final must build; got $err');
		if (inst == null) return;
		final particles = findParticles(cast inst);
		Assert.notNull(particles, "codegen: the particles are there");
		if (particles == null) return;
		for (group in particles.getGroups())
			Assert.equals(13, group.nparts, "codegen: count is $N = 13");
	}

	@Test
	public function testFinalInTileGroup_Codegen_IsInScope():Void {
		var inst:Dynamic = null;
		final err = errorOf(() -> inst = createMp().tileGroupFinal.create());
		Assert.isNull(err, 'codegen: a tileGroup using a @final must build; got $err');
		if (inst == null) return;
		final tg = findTileGroup(cast inst);
		Assert.notNull(tg, "codegen: the tileGroup is there");
		if (tg == null) return;
		Assert.equals(30.0, tg.getBounds(tg).xMin, "codegen: the baked bitmap sits at $X = 30");
	}

	// ==================== A template swap that throws ====================

	@Test
	public function testFailedTemplateSwap_Codegen_KeepsTheOldTemplate():Void {
		final inst:Dynamic = createMp().swapFail.create();
		Assert.equals("10", widths(cast inst), "swapA is placed");

		final err = errorOf(() -> inst.setParameter("tmpl", "swapB"));
		Assert.notNull(err, "swapB has no `p`, so the swap throws");
		Assert.equals("10", widths(cast inst), "the failed swap leaves swapA in place, not an empty site");

		inst.setParameter("tmpl", "swapA");
		Assert.equals("10", widths(cast inst), "going back to swapA shows swapA");
	}

	// ==================== Transitions: unrelated params and batches ====================

	@Test
	public function testFadeOut_Codegen_RunsOnAcrossAnUnrelatedParam():Void {
		final tm = new TweenManager();
		final inst:Dynamic = createMp().fadeOutUnrelated.create();
		inst.setTweenManager(tm);
		final bmp = findBitmapByWidth(cast inst, 10);
		Assert.notNull(bmp);
		if (bmp == null) return;

		inst.setParameter("open", false);
		tm.update(0.0);
		tm.update(0.1);
		Assert.notNull(bmp.parent, "fading out: still drawn 0.1 s into a 0.5 s fade");

		inst.setParameter("hover", true);
		Assert.notNull(bmp.parent, "an unrelated param must not cut the fade-out short");
		Assert.isTrue(tm.hasTweens(bmp), "the fade-out tween is still running");

		tm.update(0.6);
		Assert.isNull(bmp.parent, "the fade-out ends with the bitmap gone");
		Assert.floatEquals(1.0, bmp.alpha, 0.001, "and its alpha restored for the next show");

		inst.setParameter("open", true);
		tm.update(0.0);
		tm.update(0.6);
		Assert.notNull(bmp.parent, "shown again");
		Assert.floatEquals(1.0, bmp.alpha, 0.001, "and fully visible once the fade-in ends");
	}

	@Test
	public function testBatchSettingAParamWithoutTransitionFirst_Builder_StillFades():Void {
		final tm = new TweenManager();
		final result = BuilderTestBase.buildFromFile(FIXTURE, "batchCheckedAfterStatus", null, Incremental);
		result.setTweenManager(tm);
		result.beginUpdate();
		result.setParameter("status", "pressed");
		result.setParameter("checked", true);
		result.endUpdate();
		Assert.isTrue(anyDescendantTweened(result.object, tm), "builder: the checked bitmap fades in");
	}

	@Test
	public function testBatchSettingAParamWithoutTransitionFirst_Codegen_StillFades():Void {
		final tm = new TweenManager();
		final inst:Dynamic = createMp().batchCheckedAfterStatus.create();
		inst.setTweenManager(tm);
		inst.beginUpdate();
		inst.setParameter("status", "pressed");
		inst.setParameter("checked", true);
		inst.endUpdate();
		Assert.isTrue(anyDescendantTweened(cast inst, tm),
			"codegen: `checked` has a fade; setting `status` first in the batch must not show the bitmap at once");
	}
}
