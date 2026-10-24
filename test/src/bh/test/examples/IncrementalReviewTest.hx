package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.base.TweenManager;
import bh.multianim.MultiAnimBuilder.CallbackRequest;
import bh.multianim.MultiAnimBuilder.CallbackResult;

/**
 * Incremental updates (setParameter, batches, hide and show) against the result a fresh build
 * with the same parameters would give, builder and codegen:
 * - a show transition starts from the element's current param-driven position and alpha;
 * - an element fading out does not evaluate its param expressions any more;
 * - `apply {}` composes over the parent's current param-driven value, in either order;
 * - `BuilderResult.setTweenManager` reaches the contexts of dynamicRef children, a template a
 *   swap builds later, and dynamicRefs inside parameterized slots;
 * - a programmable's root `pos:` follows its param;
 * - a transition on a param used as a condition's value animates;
 * - showing a conditional again does not restart a param-driven stateanim;
 * - a batch that shows an arm and changes a param-dependent repeat inside it builds the repeat once;
 * - `@else` inside a `@switch` arm follows its chain;
 * - a conditional repeatable with `@flow.*` properties in a flow hides and shows.
 *
 * Companion fixture: test/examples/162-incrementalReview/incrementalReview.manim
 */
class IncrementalReviewTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/162-incrementalReview/incrementalReview.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	// ==================== Helpers ====================

	static function anyDescendantTweened(root:h2d.Object, tm:TweenManager):Bool {
		if (tm.hasTweens(root)) return true;
		for (i in 0...root.numChildren)
			if (anyDescendantTweened(root.getChildAt(i), tm)) return true;
		return false;
	}

	static function allBitmaps(root:h2d.Object):Array<h2d.Bitmap> {
		final out:Array<h2d.Bitmap> = [];
		if (Std.isOfType(root, h2d.Bitmap)) out.push(cast root);
		for (i in 0...root.numChildren)
			for (b in allBitmaps(root.getChildAt(i)))
				out.push(b);
		return out;
	}

	static function findBitmapByWidth(root:h2d.Object, w:Int):Null<h2d.Bitmap> {
		for (b in allBitmaps(root))
			if (Std.int(b.tile.width) == w) return b;
		return null;
	}

	/** Widths of the visible bitmaps under `root`, sorted, comma-separated. */
	static function widths(root:h2d.Object):String {
		final ws = [for (b in BuilderTestBase.findVisibleBitmapDescendants(root)) Std.int(b.tile.width)];
		ws.sort((a, b) -> a - b);
		return ws.join(",");
	}

	/** x of `obj` in `ancestor`'s space (no scale or rotation on the way). */
	static function offsetX(obj:h2d.Object, ancestor:h2d.Object):Float {
		var x = 0.0;
		var o = obj;
		while (o != null && o != ancestor) {
			x += o.x;
			o = o.parent;
		}
		return x;
	}

	static function errorOf(fn:Void -> Void):Null<String> {
		try {
			fn();
			return null;
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	static function findGraphics(obj:h2d.Object):Null<h2d.Graphics> {
		if (Std.isOfType(obj, h2d.Graphics)) return cast obj;
		for (i in 0...obj.numChildren) {
			final found = findGraphics(obj.getChildAt(i));
			if (found != null) return found;
		}
		return null;
	}

	static function findAnimationSM(obj:h2d.Object):Null<bh.stateanim.AnimationSM> {
		if (Std.isOfType(obj, bh.stateanim.AnimationSM)) return cast obj;
		for (i in 0...obj.numChildren) {
			final found = findAnimationSM(obj.getChildAt(i));
			if (found != null) return found;
		}
		return null;
	}

	// ==================== A show transition starts from the current values ====================

	@Test
	public function testShowSlide_Builder_EndsAtThePositionSetWhileHidden():Void {
		final tm = new TweenManager();
		final result = BuilderTestBase.buildFromSource("
			#p programmable(open:bool=true, px:int=0) {
				transition { open: slide(left, 0.3) }
				@(open=>true) bitmap(generated(color(10, 10, #f00))): $px, 0
			}
		", "p", null, Incremental);
		final bmp = findBitmapByWidth(result.object, 10);
		Assert.notNull(bmp, "the bitmap is built while open");
		if (bmp == null) return;

		result.setParameter("open", false); // no tween manager yet: hidden at once
		Assert.isNull(bmp.parent, "precondition: hidden");
		result.setParameter("px", 100);
		result.setTweenManager(tm);
		result.setParameter("open", true);
		Assert.isTrue(tm.hasTweens(bmp), "precondition: the show slides in");

		tm.update(0.0);
		tm.update(0.5);
		Assert.floatEquals(100.0, bmp.x, 0.001,
			"the slide ends at $px = 100, set while hidden, not at the position it had when it was hidden");
	}

	@Test
	public function testShowFade_Builder_EndsAtTheAlphaSetWhileHidden():Void {
		final tm = new TweenManager();
		final result = BuilderTestBase.buildFromSource("
			#p programmable(open:bool=true, a:float=1.0) {
				transition { open: fade(0.3) }
				@(open=>true) @alpha($a) bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		", "p", null, Incremental);
		final bmp = findBitmapByWidth(result.object, 10);
		Assert.notNull(bmp, "the bitmap is built while open");
		if (bmp == null) return;

		result.setParameter("open", false);
		result.setParameter("a", 0.5);
		result.setTweenManager(tm);
		result.setParameter("open", true);
		Assert.isTrue(tm.hasTweens(bmp), "precondition: the show fades in");

		tm.update(0.0);
		tm.update(0.5);
		Assert.floatEquals(0.5, bmp.alpha, 0.001,
			"the fade ends at $a = 0.5, set while hidden, not at the alpha it had when it was hidden");
	}

	@Test
	public function testShowSlide_Codegen_EndsAtThePositionSetInTheSameBatch():Void {
		final tm = new TweenManager();
		final inst:Dynamic = createMp().irShowSlide.create();
		inst.setTweenManager(tm);
		inst.beginUpdate();
		inst.setParameter("px", 100);
		inst.setParameter("open", true);
		inst.endUpdate();
		final bmp = findBitmapByWidth(cast inst, 10);
		Assert.notNull(bmp, "shown by the batch");
		if (bmp == null) return;
		Assert.isTrue(tm.hasTweens(bmp), "precondition: the show slides in");

		tm.update(0.0);
		tm.update(0.5);
		Assert.floatEquals(100.0, bmp.x, 0.001,
			"codegen: the slide ends at $px = 100 set in the same batch, not at the position before the batch");
	}

	// ==================== An element fading out ====================

	@Test
	public function testFadingOutElement_Builder_DoesNotEvaluateItsExpressions():Void {
		final tm = new TweenManager();
		final result = BuilderTestBase.buildFromSource("
			#p programmable(max:int=50) {
				transition { max: fade(0.3) }
				@(max=>1..99) graphics(rect(#fff, filled, 100 / $max, 4): 0, 0): 0, 0
			}
		", "p", null, Incremental);
		result.setTweenManager(tm);
		final g = findGraphics(result.object);
		Assert.notNull(g, "the bar is drawn while max is in 1..99");

		final err = errorOf(() -> result.setParameter("max", 0));
		Assert.isNull(err, 'the bar fades out because max left 1..99; its width (100 / $$max) must not be evaluated for max = 0 meanwhile; got $err');

		tm.update(0.0);
		tm.update(0.5);
		if (g != null)
			Assert.isNull(g.parent, "the fade-out ends with the bar gone");
	}

	/** Guard: an element under a hidden conditional does not evaluate its expressions. */
	@Test
	public function testElementUnderHiddenConditional_Builder_DoesNotEvaluateItsExpressions():Void {
		final result = BuilderTestBase.buildFromSource("
			#p programmable(max:int=50) {
				@(max=>1..99) layers() {
					graphics(rect(#fff, filled, 100 / $max, 4): 0, 0): 0, 0
				}
			}
		", "p", null, Incremental);
		final err = errorOf(() -> result.setParameter("max", 0));
		Assert.isNull(err, 'the bar is hidden with its layers; its width must not be evaluated for max = 0; got $err');
	}

	// ==================== apply {} over a param-driven value ====================

	@Test
	public function testApplyOff_Builder_RestoresTheParamDrivenAlpha():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "irApplyAlpha", null, Incremental);
		final bmp = findBitmapByWidth(result.object, 10);
		Assert.notNull(bmp);
		if (bmp == null) return;
		final point = bmp.parent;

		result.setParameter("a", 0.5);
		Assert.floatEquals(0.5, point.alpha, 0.001, "precondition: alpha follows $a");
		result.setParameter("dim", true);
		Assert.floatEquals(0.4, point.alpha, 0.001, "dim: the apply's alpha");
		result.setParameter("dim", false);
		Assert.floatEquals(0.5, point.alpha, 0.001, "dim off: back to $a = 0.5, not the alpha the point had at build time");
	}

	@Test
	public function testApplyOn_Builder_StaysOnTopOfAParamChange():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "irApplyAlpha", null, Incremental);
		final bmp = findBitmapByWidth(result.object, 10);
		Assert.notNull(bmp);
		if (bmp == null) return;
		final point = bmp.parent;

		result.setParameter("dim", true);
		Assert.floatEquals(0.4, point.alpha, 0.001, "dim: the apply's alpha");
		result.setParameter("a", 0.7);
		Assert.floatEquals(0.4, point.alpha, 0.001, "a change of $a while the apply matches leaves the apply's 0.4 on top");
		result.setParameter("dim", false);
		Assert.floatEquals(0.7, point.alpha, 0.001, "dim off: the $a set meanwhile");
	}

	@Test
	public function testUnconditionalApplyPos_Builder_AddsToTheParamDrivenPosition():Void {
		final result = BuilderTestBase.buildFromSource("
			#p programmable(x:int=0, dy:int=5) {
				point {
					pos: $x, 0
					apply { pos: 0, $dy }
					bitmap(generated(color(4, 4, #f00))): 0, 0
				}
			}
		", "p", null, Incremental);
		final bmp = findBitmapByWidth(result.object, 4);
		Assert.notNull(bmp);
		if (bmp == null) return;
		final point = bmp.parent;
		Assert.floatEquals(0.0, point.x, 0.001, "built: x = $x");
		Assert.floatEquals(5.0, point.y, 0.001, "built: the apply adds $dy");

		result.setParameter("x", 10);
		Assert.floatEquals(10.0, point.x, 0.001, "x follows $x");
		Assert.floatEquals(5.0, point.y, 0.001, "and the apply's offset stays on top");

		result.setParameter("dy", 7);
		Assert.floatEquals(10.0, point.x, 0.001, "a change of the apply's own param keeps x = $x");
		Assert.floatEquals(7.0, point.y, 0.001, "and adds the new $dy");

		result.setParameter("x", 20);
		Assert.floatEquals(20.0, point.x, 0.001, "x follows $x again");
		Assert.floatEquals(7.0, point.y, 0.001, "with the apply on top");
	}

	@Test
	public function testApplyOff_Codegen_RestoresTheParamDrivenAlpha():Void {
		final inst:Dynamic = createMp().irApplyAlpha.create();
		final bmp = findBitmapByWidth(cast inst, 10);
		Assert.notNull(bmp);
		if (bmp == null) return;
		final point = bmp.parent;

		inst.setParameter("a", 0.5);
		Assert.floatEquals(0.5, point.alpha, 0.001, "precondition: alpha follows $a");
		inst.setParameter("dim", true);
		Assert.floatEquals(0.4, point.alpha, 0.001, "dim: the apply's alpha");
		inst.setParameter("dim", false);
		Assert.floatEquals(0.5, point.alpha, 0.001, "codegen: dim off goes back to $a = 0.5, not the alpha at construction");
	}

	@Test
	public function testApplyOn_Codegen_StaysOnTopOfAParamChange():Void {
		final inst:Dynamic = createMp().irApplyAlpha.create();
		final bmp = findBitmapByWidth(cast inst, 10);
		Assert.notNull(bmp);
		if (bmp == null) return;
		final point = bmp.parent;

		inst.setParameter("dim", true);
		Assert.floatEquals(0.4, point.alpha, 0.001, "dim: the apply's alpha");
		inst.setParameter("a", 0.7);
		Assert.floatEquals(0.4, point.alpha, 0.001, "codegen: a change of $a while the apply matches leaves the apply's 0.4 on top");
		inst.setParameter("dim", false);
		Assert.floatEquals(0.7, point.alpha, 0.001, "codegen: dim off shows the $a set meanwhile");
	}

	@Test
	public function testUnrelatedSetter_Codegen_KeepsTheParamDrivenAlpha():Void {
		final inst:Dynamic = createMp().irApplyAlpha.create();
		final bmp = findBitmapByWidth(cast inst, 10);
		Assert.notNull(bmp);
		if (bmp == null) return;
		final point = bmp.parent;

		inst.setParameter("a", 0.5);
		Assert.floatEquals(0.5, point.alpha, 0.001, "precondition: alpha follows $a");
		inst.setParameter("w", 20);
		Assert.equals(20, Std.int(bmp.tile.width), "precondition: the bitmap follows $w");
		Assert.floatEquals(0.5, point.alpha, 0.001,
			"codegen: a setter for a param the alpha does not use must not reset it to the alpha at construction");
	}

	// ==================== setTweenManager reaches nested contexts ====================

	@Test
	public function testSetTweenManager_Builder_ReachesDynamicRefChildren():Void {
		final tm = new TweenManager();
		final result = BuilderTestBase.buildFromSource("
			#fadeChild programmable(open:bool=false) {
				transition { open: fade(0.5) }
				@(open=>true) bitmap(generated(color(10, 10, #f00))): 0, 0
			}
			#host programmable(open:bool=false) {
				#c dynamicRef($fadeChild, open=>$open): 0, 0
			}
		", "host", null, Incremental);
		result.setTweenManager(tm);
		result.setParameter("open", true);
		Assert.notNull(findBitmapByWidth(result.object, 10), "precondition: the child shows its bitmap");
		Assert.isTrue(anyDescendantTweened(result.object, tm),
			"the child's open has a fade: the tween manager set on the result must reach the dynamicRef's context");
	}

	@Test
	public function testSetTweenManager_Builder_ReachesTheTemplateASwapBuilds():Void {
		final tm = new TweenManager();
		final result = BuilderTestBase.buildFromSource("
			#fadeA programmable(open:bool=false) {
				transition { open: fade(0.5) }
				@(open=>true) bitmap(generated(color(10, 10, #f00))): 0, 0
			}
			#fadeB programmable(open:bool=false) {
				transition { open: fade(0.5) }
				@(open=>true) bitmap(generated(color(12, 12, #00f))): 0, 0
			}
			#host programmable(tmpl:[fadeA, fadeB]=fadeA, open:bool=false) {
				#c dynamicRef($tmpl, open=>$open): 0, 0
			}
		", "host", null, Incremental);
		result.setTweenManager(tm);
		result.setParameter("tmpl", "fadeB");
		result.setParameter("open", true);
		Assert.notNull(findBitmapByWidth(result.object, 12), "precondition: fadeB is placed and shows its bitmap");
		Assert.isTrue(anyDescendantTweened(result.object, tm),
			"fadeB's open has a fade: the template a swap builds after setTweenManager must get the tween manager too");
	}

	@Test
	public function testSetTweenManager_Builder_ReachesDynamicRefsInSlots():Void {
		final tm = new TweenManager();
		final result = BuilderTestBase.buildFromSource("
			#fadeChild programmable(open:bool=false) {
				transition { open: fade(0.5) }
				@(open=>true) bitmap(generated(color(10, 10, #f00))): 0, 0
			}
			#host programmable() {
				#s slot(open:bool=false) {
					dynamicRef($fadeChild, open=>$open): 0, 0
				}
			}
		", "host", null, Incremental);
		result.setTweenManager(tm);
		result.getSlot("s").setParameter("open", true);
		Assert.notNull(findBitmapByWidth(result.object, 10), "precondition: the slot's dynamicRef shows its bitmap");
		Assert.isTrue(anyDescendantTweened(result.object, tm),
			"the child's open has a fade: the tween manager set on the result must reach a dynamicRef inside its slot");
	}

	// ==================== Root pos follows its param ====================

	@Test
	public function testRootPos_Builder_FollowsItsParam():Void {
		final result = BuilderTestBase.buildFromSource("
			#p programmable(px:int=10) {
				pos: $px, 0
				bitmap(generated(color(4, 4, #f00))): 0, 0
			}
		", "p", null, Incremental);
		final host = new h2d.Object();
		host.addChild(result.object);
		final bmp = findBitmapByWidth(result.object, 4);
		Assert.notNull(bmp);
		if (bmp == null) return;
		Assert.floatEquals(10.0, offsetX(bmp, host), 0.001, "built at $px = 10");

		result.setParameter("px", 30);
		Assert.floatEquals(30.0, offsetX(bmp, host), 0.001, "the programmable moves to $px = 30");
	}

	@Test
	public function testRootPosBuiltAtZero_Builder_FollowsItsParam():Void {
		final result = BuilderTestBase.buildFromSource("
			#p programmable(px:int=0) {
				pos: $px, 0
				bitmap(generated(color(4, 4, #f00))): 0, 0
			}
		", "p", null, Incremental);
		final host = new h2d.Object();
		host.addChild(result.object);
		final bmp = findBitmapByWidth(result.object, 4);
		Assert.notNull(bmp);
		if (bmp == null) return;
		Assert.floatEquals(0.0, offsetX(bmp, host), 0.001, "built at $px = 0");

		result.setParameter("px", 30);
		Assert.floatEquals(30.0, offsetX(bmp, host), 0.001, "built at 0, the programmable still moves to $px = 30");
	}

	/** The root pos composes with the caller's placement of the result's object, as documented
	 *  for the static case: the param moves the programmable from where the caller put it. */
	@Test
	public function testRootPosBuiltAtZero_Builder_ComposesWithTheCallersPlacement():Void {
		final result = BuilderTestBase.buildFromSource("
			#p programmable(px:int=0) {
				pos: $px, 0
				bitmap(generated(color(4, 4, #f00))): 0, 0
			}
		", "p", null, Incremental);
		final host = new h2d.Object();
		host.addChild(result.object);
		result.object.x = 7; // the caller places the result
		final bmp = findBitmapByWidth(result.object, 4);
		Assert.notNull(bmp);
		if (bmp == null) return;

		result.setParameter("px", 30);
		Assert.floatEquals(37.0, offsetX(bmp, host), 0.001, "the caller's 7 plus $px = 30");
	}

	@Test
	public function testRootPos_Codegen_FollowsItsParam():Void {
		final inst:Dynamic = createMp().irRootPos.create();
		final host = new h2d.Object();
		host.addChild(cast inst);
		final bmp = findBitmapByWidth(cast inst, 4);
		Assert.notNull(bmp);
		if (bmp == null) return;
		Assert.floatEquals(0.0, offsetX(bmp, host), 0.001, "built at $px = 0");

		inst.setParameter("px", 30);
		Assert.floatEquals(30.0, offsetX(bmp, host), 0.001, "codegen: the programmable moves to $px = 30");
	}

	// ==================== A transition on a param used as a condition's value ====================

	@Test
	public function testTransitionOnConditionValueParam_Builder_Animates():Void {
		final tm = new TweenManager();
		final result = BuilderTestBase.buildFromFile(FIXTURE, "irCondValueTrans", null, Incremental);
		result.setTweenManager(tm);
		Assert.isNull(findBitmapByWidth(result.object, 10), "precondition: hidden while hp < max");

		result.setParameter("max", 3);
		Assert.notNull(findBitmapByWidth(result.object, 10), "shown once hp >= max");
		Assert.isTrue(anyDescendantTweened(result.object, tm),
			"max has a fade and decides the condition (hp >= $max): the show must fade in, not toggle at once");
	}

	@Test
	public function testTransitionOnConditionValueParam_Codegen_Animates():Void {
		final tm = new TweenManager();
		final inst:Dynamic = createMp().irCondValueTrans.create();
		inst.setTweenManager(tm);
		Assert.isNull(findBitmapByWidth(cast inst, 10), "precondition: hidden while hp < max");

		inst.setParameter("max", 3);
		Assert.notNull(findBitmapByWidth(cast inst, 10), "shown once hp >= max");
		Assert.isTrue(anyDescendantTweened(cast inst, tm),
			"codegen: max has a fade and decides the condition (hp >= $max): the show must fade in, not toggle at once");
	}

	// ==================== Showing a conditional again keeps a stateanim's playhead ====================

	@Test
	public function testShowAgain_Builder_DoesNotRestartAParamDrivenStateanim():Void {
		final result = BuilderTestBase.buildFromSource("
			#p programmable(open:bool=true, initial:string=\"idle\") {
				@(open=>true) stateanim(\"marine.anim\", $initial, \"direction\"=>\"l\"): 0, 0
			}
		", "p", null, Incremental);
		final sm = findAnimationSM(result.object);
		Assert.notNull(sm, "the state machine is built while open");
		if (sm == null) return;
		sm.seek(2); // the game stops idle on its third frame
		Assert.equals(2, sm.currentStateIndex, "precondition: on the third frame");

		result.setParameter("open", false);
		result.setParameter("open", true);
		Assert.equals("idle", sm.getCurrentAnimName(), "still idle");
		Assert.equals(2, sm.currentStateIndex,
			"$initial did not change while hidden: showing it again must not play idle again from the start");
		Assert.isTrue(sm.paused, "nor undo the pause the game put it in");
	}

	// ==================== One batch: show an arm and change its repeat ====================

	@Test
	public function testBatchShowingAnArmAndChangingItsRepeat_Builder_BuildsTheRepeatOnce():Void {
		var calls = 0;
		final builder = BuilderTestBase.builderFromSource("
			#p programmable(open:bool=false, n:uint=2) {
				@(open=>true) layers() {
					repeatable($i, step($n, dx: 10)) {
						text(dd, callback(\"cell\", $i), #fff): 0, 0
					}
				}
			}
		");
		final bp:Dynamic = {
			callback: (request:CallbackRequest) -> {
				return switch request {
					case NameWithIndex(name, _) if (name == "cell"):
						calls++;
						CBRString("c");
					default:
						CBRNoResult;
				};
			},
		};
		final result = builder.buildWithParameters("p", new Map(), bp, null, true);
		Assert.equals(0, calls, "precondition: nothing is built while closed");

		result.beginUpdate();
		result.setParameter("open", true);
		result.setParameter("n", 3);
		result.endUpdate();
		Assert.equals(3, BuilderTestBase.findAllTextDescendants(result.object).length, "three cells shown");
		Assert.equals(3, calls,
			"the arm is built with n = 3 when the batch shows it; the repeat inside must not be built a second time for the same batch");
	}

	// ==================== @else inside a @switch arm ====================

	@Test
	public function testElseInSwitchArm_Builder_FollowsItsChain():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "irSwitchElse", null, Incremental);
		Assert.equals("8", widths(result.object), "flag on: only the @() element of arm a, not its @else");
		result.setParameter("flag", false);
		Assert.equals("12", widths(result.object), "flag off: only the @else element");
		result.setParameter("mode", "b");
		Assert.equals("4", widths(result.object), "mode b: the default arm");
	}

	@Test
	public function testElseInSwitchArm_BuilderNonIncremental_FollowsItsChain():Void {
		final on = BuilderTestBase.buildFromFile(FIXTURE, "irSwitchElse");
		Assert.equals("8", widths(on.object), "flag on: only the @() element of arm a, not its @else");
		final off = BuilderTestBase.buildFromFile(FIXTURE, "irSwitchElse", ["flag" => false]);
		Assert.equals("12", widths(off.object), "flag off: only the @else element");
	}

	@Test
	public function testElseInSwitchArm_Codegen_FollowsItsChain():Void {
		final inst:Dynamic = createMp().irSwitchElse.create();
		Assert.equals("8", widths(cast inst), "codegen: flag on: only the @() element of arm a, not its @else");
		inst.setParameter("flag", false);
		Assert.equals("12", widths(cast inst), "codegen: flag off: only the @else element");
		inst.setParameter("mode", "b");
		Assert.equals("4", widths(cast inst), "codegen: mode b: the default arm");
	}

	// ==================== A conditional repeatable with @flow.* in a flow ====================

	/** Guard: hidden at build, shown and hidden again on its condition, its flow properties kept. */
	@Test
	public function testConditionalRepeatWithFlowProps_Builder_HidesAndShows():Void {
		final result = BuilderTestBase.buildFromSource("
			#p programmable(show:bool=false) {
				flow(layout: vertical, minWidth: 40) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
					@(show=>true) @flow.halign(right) repeatable($i, range(0, 2)) {
						bitmap(generated(color(4, 4, #0f0))): $i * 6, 0
					}
				}
			}
		", "p", null, Incremental);
		Assert.equals("10", widths(result.object), "hidden at build: only the unconditional bitmap");

		result.setParameter("show", true);
		Assert.equals("4,4,10", widths(result.object), "shown: both iterations");
		final cell = findBitmapByWidth(result.object, 4);
		Assert.notNull(cell);
		if (cell != null) {
			final flow = Std.downcast(result.object.getChildAt(0), h2d.Flow);
			Assert.notNull(flow, "the root's first child is the flow");
			// The flow lays out each item (no wrapper): each takes the repeat's @flow.*
			if (flow != null) {
				Assert.isTrue(cell.parent == flow, "the item is the flow's own child");
				Assert.equals(h2d.Flow.FlowAlign.Right, flow.getProperties(cell).horizontalAlign,
					"the repeat's @flow.halign is the item's once shown");
			}
		}

		result.setParameter("show", false);
		Assert.equals("10", widths(result.object), "hidden again");
	}
}
