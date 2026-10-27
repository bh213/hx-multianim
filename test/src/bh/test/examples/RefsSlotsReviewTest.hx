package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness.UITestScreen;
import bh.multianim.MultiAnimBuilder.BuilderResult;
import bh.multianim.MultiAnimBuilder.PlaceholderValues;
import bh.ui.UIElement;
import bh.ui.UIRichInteractiveHelper;

/**
 * Refs (staticRef / dynamicRef) and slots in incremental builds and codegen instances:
 * - one `#name` in mutually exclusive arms: the arm that is shown answers `getDynamicRef` /
 *   `getSlot`; two sites shown at once still collide;
 * - a constant-count repeatable is not turned into a wholesale rebuild by what its body holds
 *   (a parameterized slot's own params, an inner repeatable's loop variable); one whose body is
 *   gated by a param rebuilds on every param the body uses;
 * - interactives inside a dynamicRef or a parameterized slot reach the screen when they appear,
 *   through a staticRef target too, and an autoStatus/bind interactive placed by a dynamicRef
 *   drives the dynamicRef's own result;
 * - codegen passes its placeholder objects into ref targets and rejects a self-recursive
 *   staticRef like the builder.
 *
 * Companion fixture: test/examples/163-refsSlotsReview/refsSlotsReview.manim
 */
class RefsSlotsReviewTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/163-refsSlotsReview/refsSlotsReview.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	// ==================== helpers ====================

	static function errorOf(fn:() -> Void):Null<String> {
		try {
			fn();
			return null;
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	/** The BuilderError code `fn` throws, a description when it throws something else, null when
	 *  it does not throw. */
	static function errorCodeOf(fn:() -> Void):Null<String> {
		try {
			fn();
			return null;
		} catch (e:bh.multianim.BuilderError) {
			return e.code != null ? e.code : "(no code) " + e.message;
		} catch (e:Dynamic) {
			return "(not a BuilderError) " + Std.string(e);
		}
	}

	/** True when `obj` is `root` or under it, every object on the way visible. */
	static function drawnUnder(obj:Null<h2d.Object>, root:h2d.Object):Bool {
		var cur = obj;
		while (cur != null) {
			if (!cur.visible)
				return false;
			if (cur == root)
				return true;
			cur = cur.parent;
		}
		return false;
	}

	/** True when `obj`'s parent chain reaches `root`. */
	static function isUnder(obj:h2d.Object, root:h2d.Object):Bool {
		var cur = obj;
		while (cur != null) {
			if (cur == root)
				return true;
			cur = cur.parent;
		}
		return false;
	}

	static function xUnder(obj:h2d.Object, root:h2d.Object):Float {
		var x = 0.0;
		var cur = obj;
		while (cur != null && cur != root) {
			x += cur.x;
			cur = cur.parent;
		}
		return x;
	}

	static function yUnder(obj:h2d.Object, root:h2d.Object):Float {
		var y = 0.0;
		var cur = obj;
		while (cur != null && cur != root) {
			y += cur.y;
			cur = cur.parent;
		}
		return y;
	}

	/** Tile widths of the visible bitmaps under `root`, sorted, comma-joined. */
	static function widthsOf(root:h2d.Object):String {
		final ws = [for (b in BuilderTestBase.findVisibleBitmapDescendants(root)) Std.int(b.tile.width)];
		ws.sort((a, b) -> a - b);
		return ws.join(",");
	}

	/** X positions (relative to `root`) of the visible bitmaps `w` wide, sorted, comma-joined. */
	static function xsOfWidth(root:h2d.Object, w:Int):String {
		final xs = [
			for (b in BuilderTestBase.findVisibleBitmapDescendants(root))
				if (Std.int(b.tile.width) == w) Std.int(xUnder(b, root))
		];
		xs.sort((a, b) -> a - b);
		return xs.join(",");
	}

	static function textsOf(root:h2d.Object):String {
		return [for (t in BuilderTestBase.findAllTextDescendants(root)) t.text].join(",");
	}

	static function interactiveIds(objs:Array<bh.base.MAObject>):Array<String> {
		final ids:Array<String> = [];
		for (o in objs)
			switch o.multiAnimType {
				case MAInteractive(_, _, id, _): ids.push(id);
				default:
			}
		return ids;
	}

	// ==================== one #name in mutually exclusive arms ====================

	static final EXCLUSIVE_DYNREF = "
		#panelA programmable() {
			bitmap(generated(color(10, 4, #f00))): 0, 0
		}
		#panelB programmable() {
			bitmap(generated(color(20, 4, #0f0))): 0, 0
		}
		#exclusiveRef programmable(mode:[a,b]=a) {
			@(mode=>a) #panel dynamicRef(panelA): 0, 0
			@else #panel dynamicRef(panelB): 0, 0
		}
	";

	@Test
	public function testSameDynamicRefNameInExclusiveArmsAnswersWithTheShownArm():Void {
		final result = BuilderTestBase.buildFromSource(EXCLUSIVE_DYNREF, "exclusiveRef", null, Incremental);
		Assert.equals("10", widthsOf(result.getDynamicRef("panel").object), "precondition: arm a's panel answers at build");

		final err = errorOf(() -> result.setParameter("mode", "b"));
		Assert.isNull(err, 'showing the @else arm must not reject its #panel as a duplicate of the hidden arm\'s: $err');
		if (err != null)
			return;
		final shown = result.getDynamicRef("panel");
		Assert.isTrue(drawnUnder(shown.object, result.object), "getDynamicRef(\"panel\") answers with the arm that is shown");
		Assert.equals("20", widthsOf(shown.object), "the shown arm's panel is panelB");

		final errBack = errorOf(() -> result.setParameter("mode", "a"));
		Assert.isNull(errBack, 'showing arm a again must not throw: $errBack');
		if (errBack != null)
			return;
		final back = result.getDynamicRef("panel");
		Assert.isTrue(drawnUnder(back.object, result.object), "after flipping back, arm a's panel answers again");
		Assert.equals("10", widthsOf(back.object));
	}

	@Test
	public function testSameDynamicRefNameInExclusiveArmsWorksWhenTheFirstArmIsShownLater():Void {
		final params:Map<String, Dynamic> = ["mode" => "b"];
		final result = BuilderTestBase.buildFromSource(EXCLUSIVE_DYNREF, "exclusiveRef", params, Incremental);
		Assert.equals("20", widthsOf(result.getDynamicRef("panel").object), "precondition: the @else arm's panel answers at build");

		final err = errorOf(() -> result.setParameter("mode", "a"));
		Assert.isNull(err, 'showing arm a (built for the first time) must not reject its #panel: $err');
		if (err != null)
			return;
		final shown = result.getDynamicRef("panel");
		Assert.isTrue(drawnUnder(shown.object, result.object), "getDynamicRef(\"panel\") answers with the arm that is shown");
		Assert.equals("10", widthsOf(shown.object));
	}

	static final EXCLUSIVE_TEMPLATE = "
		#panelA programmable() {
			bitmap(generated(color(10, 4, #f00))): 0, 0
		}
		#panelB programmable() {
			bitmap(generated(color(20, 4, #0f0))): 0, 0
		}
		#panelC programmable() {
			bitmap(generated(color(30, 4, #00f))): 0, 0
		}
		#exclusiveTemplate programmable(mode:[a,b]=a, tmpl:[panelA,panelB,panelC]=panelA) {
			@(mode=>a) #panel dynamicRef($tmpl): 0, 0
			@else #panel dynamicRef($tmpl): 0, 10
		}
	";

	/** A template swap keeps the site's place among the exclusive arms: the other arm, built after
	 *  it, still shares the #name. */
	@Test
	public function testTemplateSwapKeepsAnExclusiveDynamicRefNameShareable():Void {
		final result = BuilderTestBase.buildFromSource(EXCLUSIVE_TEMPLATE, "exclusiveTemplate", null, Incremental);
		result.setParameter("tmpl", "panelB");
		Assert.equals("20", widthsOf(result.getDynamicRef("panel").object), "precondition: arm a shows the swapped template");

		final err = errorOf(() -> result.setParameter("mode", "b"));
		Assert.isNull(err, 'showing the @else arm after a template swap must not reject its #panel as a duplicate: $err');
		if (err != null)
			return;
		final shown = result.getDynamicRef("panel");
		Assert.isTrue(drawnUnder(shown.object, result.object), "getDynamicRef(\"panel\") answers with the arm that is shown");
		Assert.equals(10.0, yUnder(shown.object, result.object), "the @else arm's panel");
		Assert.equals("20", widthsOf(shown.object), "built with the current template");
	}

	/** Both arms built, then the template swapped: one of the two sites is still the shown one. */
	@Test
	public function testTemplateSwapWithBothExclusiveArmsBuiltAnswersWithTheShownArm():Void {
		final result = BuilderTestBase.buildFromSource(EXCLUSIVE_TEMPLATE, "exclusiveTemplate", null, Incremental);
		result.setParameter("mode", "b");
		result.setParameter("mode", "a");

		final err = errorOf(() -> result.setParameter("tmpl", "panelC"));
		Assert.isNull(err, 'the template swap must not throw: $err');
		if (err != null)
			return;
		final errGet = errorOf(() -> result.getDynamicRef("panel"));
		Assert.isNull(errGet, 'getDynamicRef("panel") after the swap must not report a collision: $errGet');
		if (errGet != null)
			return;
		final shown = result.getDynamicRef("panel");
		Assert.isTrue(drawnUnder(shown.object, result.object), "getDynamicRef(\"panel\") answers with the arm that is shown");
		Assert.equals(0.0, yUnder(shown.object, result.object), "arm a's panel");
		Assert.equals("30", widthsOf(shown.object));

		result.setParameter("mode", "b");
		final other = result.getDynamicRef("panel");
		Assert.isTrue(drawnUnder(other.object, result.object), "after the flip, the @else arm's panel answers");
		Assert.equals(10.0, yUnder(other.object, result.object));
		Assert.equals("30", widthsOf(other.object));
	}

	static final EXCLUSIVE_SLOT = "
		#exclusiveSlot programmable(mode:[a,b]=a) {
			@(mode=>a) #content slot: 0, 0
			@else #content slot: 0, 20
		}
	";

	@Test
	public function testSameSlotNameInExclusiveArmsAnswersWithTheShownArm():Void {
		final result = BuilderTestBase.buildFromSource(EXCLUSIVE_SLOT, "exclusiveSlot", null, Incremental);

		final err = errorOf(() -> result.setParameter("mode", "b"));
		Assert.isNull(err, 'showing the @else arm must not throw: $err');
		if (err != null)
			return;
		final slot = result.getSlot("content");
		Assert.isTrue(drawnUnder(slot.container, result.object), "getSlot(\"content\") answers with the slot of the shown arm");
		Assert.equals(20.0, yUnder(slot.container, result.object), "the shown arm's slot sits at y=20");
		final marker = new h2d.Object();
		slot.setContent(marker);
		Assert.isTrue(drawnUnder(marker, result.object), "content set into it is drawn");

		result.setParameter("mode", "a");
		final back = result.getSlot("content");
		Assert.isTrue(drawnUnder(back.container, result.object), "after flipping back, arm a's slot answers");
		Assert.equals(0.0, yUnder(back.container, result.object));
	}

	static final EXCLUSIVE_INDEXED_SLOT = "
		#exclusiveIndexed programmable(mode:[a,b]=a) {
			@(mode=>a) repeatable($i, step(2, dx: 10)) {
				#c[$i] slot: 0, 0
			}
			@else repeatable($i, step(2, dx: 10)) {
				#c[$i] slot: 0, 30
			}
		}
	";

	@Test
	public function testSameIndexedSlotNameInExclusiveArmsAnswersWithTheShownArm():Void {
		final result = BuilderTestBase.buildFromSource(EXCLUSIVE_INDEXED_SLOT, "exclusiveIndexed", null, Incremental);

		final err = errorOf(() -> result.setParameter("mode", "b"));
		Assert.isNull(err, 'the @else arm\'s #c[$$i] slots must not collide with the hidden arm\'s: $err');
		if (err != null)
			return;
		final first = result.getSlot("c", 0);
		final second = result.getSlot("c", 1);
		Assert.isTrue(drawnUnder(first.container, result.object), "getSlot(\"c\", 0) answers with the shown arm's slot");
		Assert.equals(30.0, yUnder(first.container, result.object));
		Assert.isTrue(drawnUnder(second.container, result.object), "getSlot(\"c\", 1) answers with the shown arm's slot");
		Assert.equals(10.0, xUnder(second.container, result.object));

		final errBack = errorOf(() -> result.setParameter("mode", "a"));
		Assert.isNull(errBack, 'showing arm a again must not throw: $errBack');
		if (errBack != null)
			return;
		final back = result.getSlot("c", 0);
		Assert.isTrue(drawnUnder(back.container, result.object), "after flipping back, arm a's slot answers");
		Assert.equals(0.0, yUnder(back.container, result.object));
	}

	static final TWO_NAMED_LEAF = "
		#leaf programmable() {
			bitmap(generated(color(4, 4, #f00))): 0, 0
		}
	";

	/** Existing contract: two sites with one explicit name that are both shown collide. */
	@Test
	public function testTwoShownDynamicRefsWithTheSameNameStillThrow():Void {
		final unconditional = TWO_NAMED_LEAF + "
			#twoNamed programmable() {
				#x dynamicRef(leaf): 0, 0
				#x dynamicRef(leaf): 0, 10
			}
		";
		Assert.notNull(errorOf(() -> BuilderTestBase.buildFromSource(unconditional, "twoNamed")),
			"two unconditional #x dynamicRef sites are rejected");
		Assert.notNull(errorOf(() -> BuilderTestBase.buildFromSource(unconditional, "twoNamed", null, Incremental)),
			"two unconditional #x dynamicRef sites are rejected in an incremental build too");

		final overlapping = TWO_NAMED_LEAF + "
			#bothShown programmable(a:bool=true, b:bool=false) {
				@(a=>true) #x dynamicRef(leaf): 0, 0
				@(b=>true) #x dynamicRef(leaf): 0, 10
			}
		";
		final bothParams:Map<String, Dynamic> = ["b" => true];
		Assert.notNull(errorOf(() -> BuilderTestBase.buildFromSource(overlapping, "bothShown", bothParams, Incremental)),
			"two conditional #x sites shown at build are rejected");
		final result = BuilderTestBase.buildFromSource(overlapping, "bothShown", null, Incremental);
		Assert.notNull(errorOf(() -> result.setParameter("b", true)),
			"showing a second #x site while the first is shown is rejected");
	}

	/** Existing contract: one indexed slot key built twice by two shown repeatables collides. */
	@Test
	public function testTwoShownIndexedSlotsWithTheSameKeyStillThrow():Void {
		final src = "
			#twoIndexed programmable() {
				repeatable($i, step(2, dx: 10)) {
					#c[$i] slot: 0, 0
				}
				repeatable($i, step(2, dx: 10)) {
					#c[$i] slot: 0, 20
				}
			}
		";
		// The indexed name registry (#c[$i] is a name too) is checked first: either collision code
		final codes = ["indexed_slot_collision", "indexed_name_collision"];
		final full = errorCodeOf(() -> BuilderTestBase.buildFromSource(src, "twoIndexed"));
		final incremental = errorCodeOf(() -> BuilderTestBase.buildFromSource(src, "twoIndexed", null, Incremental));
		Assert.isTrue(codes.contains(full), 'a full build rejects the second #c[0]; got $full');
		Assert.isTrue(codes.contains(incremental), 'an incremental build rejects the second #c[0]; got $incremental');
	}

	// ==================== what a constant-count repeatable's body holds ====================

	static final SLOT_PARAMS_IN_REPEAT = "
		#row programmable(v:uint=1) {
			bitmap(generated(color($v, 5, #0f0))): 0, 0
		}
		#slotRows programmable(hp:uint=1) {
			repeatable($i, step(2, dx: 20)) {
				#c[$i] slot(sel:bool=false) {
					@(sel=>true) bitmap(generated(color(4, 4, #f00))): 0, 0
				}
				#r[$i] dynamicRef(row, v=>$hp): 0, 10
			}
		}
	";

	@Test
	public function testParameterizedSlotParamsDoNotMakeTheEnclosingRepeatRebuildWholesale():Void {
		final result = BuilderTestBase.buildFromSource(SLOT_PARAMS_IN_REPEAT, "slotRows", null, Incremental);

		final err = errorOf(() -> result.setParameter("hp", 7));
		Assert.isNull(err, 'a slot\'s own param (sel) must not make the repeat a param-dependent rebuild that rejects hp: $err');
		if (err != null)
			return;
		Assert.equals("7", widthsOf(result.getDynamicRef("r 0").object), "row 0 follows hp");
		Assert.equals("7", widthsOf(result.getDynamicRef("r 1").object), "row 1 follows hp");
	}

	@Test
	public function testSlotContentInConstantRepeatSurvivesAForwardedParamChange():Void {
		final result = BuilderTestBase.buildFromSource(SLOT_PARAMS_IN_REPEAT, "slotRows", null, Incremental);
		final marker = new h2d.Object();
		result.getSlot("c", 0).setContent(marker);

		final err = errorOf(() -> result.setParameter("hp", 7));
		Assert.isNull(err, 'setParameter("hp") must apply: $err');
		if (err != null)
			return;
		Assert.equals(marker, result.getSlot("c", 0).getContent(), "the slot keeps its content: the repeat was not rebuilt");
		Assert.isTrue(drawnUnder(marker, result.object), "and the content is still drawn");
	}

	/** Guard: a parameterized slot inside a repeatable keeps driving its own conditionals — its
	 *  body is the slot's, whatever the repeat does with the conditionals of its own body. */
	@Test
	public function testSlotParamInsideRepeatStillDrivesItsOwnConditional():Void {
		final result = BuilderTestBase.buildFromSource(SLOT_PARAMS_IN_REPEAT, "slotRows", null, Incremental);
		final slot = result.getSlot("c", 0);
		Assert.equals("", widthsOf(slot.container), "precondition: sel=false draws nothing in the slot");

		slot.setParameter("sel", true);
		Assert.equals("4", widthsOf(slot.container), "sel=true draws the slot's 4px bitmap");
		slot.setParameter("sel", false);
		Assert.equals("", widthsOf(slot.container), "sel=false hides it again");
	}

	static final NESTED_LOOP_VAR = "
		#nestedLoops programmable(ox:int=0) {
			repeatable($i, step(2, dx: 30)) {
				repeatable($j, step(2, dy: 10)) {
					@($j => 0) bitmap(generated(color(4, 4, #f00))): 0, 0
				}
				bitmap(generated(color(6, 6, #0f0))): $ox, 20
			}
		}
	";

	@Test
	public function testInnerLoopVariableDoesNotMakeTheOuterRepeatUntracked():Void {
		final result = BuilderTestBase.buildFromSource(NESTED_LOOP_VAR, "nestedLoops", null, Incremental);
		Assert.equals("0,30", xsOfWidth(result.object, 6), "precondition: one 6px bitmap per outer iteration");

		final err = errorOf(() -> result.setParameter("ox", 5));
		Assert.isNull(err, 'the inner loop variable $$j is not a param: ox must stay settable: $err');
		if (err != null)
			return;
		Assert.equals("5,35", xsOfWidth(result.object, 6), "the bitmaps move by ox and keep the 30px step");
		Assert.equals("0,30", xsOfWidth(result.object, 4), "the inner repeat's bitmaps stay where they were");
	}

	@Test
	public function testGatedConstantRepeatFollowsAPositionParam():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "rsGatedRow", null, Incremental);
		Assert.equals("0,12", xsOfWidth(result.object, 4), "precondition: level=2 shows two bitmaps");

		final err = errorOf(() -> result.setParameter("ox", 5));
		Assert.isNull(err, 'every param the gated body uses rebuilds it, ox too: $err');
		if (err != null)
			return;
		Assert.equals("5,17", xsOfWidth(result.object, 4), "the bitmaps sit at ox + 12 * i");
	}

	@Test
	public function testGatedConstantRepeatFollowsATextParam():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "rsGatedRow", null, Incremental);
		Assert.equals("a,a,a,a", textsOf(result.object), "precondition: four texts of the default label");

		final err = errorOf(() -> result.setParameter("label", "x"));
		Assert.isNull(err, 'setParameter("label") must apply: $err');
		Assert.equals("x,x,x,x", textsOf(result.object), "every iteration's text follows label");
	}

	@Test
	public function testGatedConstantRepeatKeepsThePositionParamWhenTheGateChanges():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "rsGatedRow", null, Incremental);

		result.setParameter("level", 3);
		Assert.equals("0,12,24", xsOfWidth(result.object, 4), "level=3 shows three bitmaps");

		final err = errorOf(() -> result.setParameter("ox", 5));
		Assert.isNull(err, 'setParameter("ox") must apply: $err');
		if (err != null)
			return;
		Assert.equals("5,17,29", xsOfWidth(result.object, 4), "all three move by ox");
		result.setParameter("level", 1);
		Assert.equals("5", xsOfWidth(result.object, 4), "a rebuild by the gate keeps the current ox");
	}

	/** Parity guard: codegen unrolls the same repeat and already follows every param. */
	@Test
	public function testCodegenGatedConstantRepeatFollowsEveryParam():Void {
		final inst:Dynamic = createMp().rsGatedRow.create();
		final root:h2d.Object = cast inst;
		Assert.equals("0,12", xsOfWidth(root, 4), "precondition: level=2 shows two bitmaps");

		inst.setParameter("ox", 5);
		Assert.equals("5,17", xsOfWidth(root, 4), "the bitmaps sit at ox + 12 * i");
		inst.setParameter("label", "x");
		Assert.equals("x,x,x,x", textsOf(root), "every iteration's text follows label");
		inst.setParameter("level", 3);
		Assert.equals("5,17,29", xsOfWidth(root, 4), "level=3 shows three bitmaps at the current ox");
	}

	/** Existing contract: a repeatable whose count is a param rebuilds on its count and gates only;
	 *  a param used only in a body interactive id is rejected rather than left stale. */
	@Test
	public function testParamCountRepeatStillRejectsAParamUsedOnlyInABodyInteractiveId():Void {
		final result = BuilderTestBase.buildFromSource("
			#countedIds programmable(n:uint=1, tag:string=\"a\") {
				repeatable($i, step($n, dx: 10)) {
					interactive(5, 5, $tag): 0, 0
				}
			}
		", "countedIds", null, Incremental);
		Assert.equals("untracked_param", errorCodeOf(() -> result.setParameter("tag", "b")));
	}

	// ==================== interactives that appear inside a dynamicRef or a slot ====================

	@Test
	public function testInteractiveShownInsideADynamicRefIsRegisteredOnTheScreen():Void {
		final screen = new UITestScreen();
		final result = BuilderTestBase.buildFromFile(FIXTURE, "rsMenuHost", null, Incremental);
		screen.addInteractives(result, "p");
		Assert.isNull(screen.getInteractive("p.item"), "precondition: hidden at registration");

		result.getDynamicRef("m").setParameter("open", true);

		final w = screen.getInteractive("p.item");
		Assert.notNull(w, "an interactive shown by the dynamicRef's own setParameter is wrapped by the screen");
		if (w != null)
			Assert.isTrue(result.getInteractives().indexOf(w.interactive) >= 0, "and the wrapper holds the live object");

		result.getDynamicRef("m").setParameter("open", false);
		Assert.isNull(screen.getInteractive("p.item"), "hidden again: its wrapper is dropped");
	}

	@Test
	public function testInteractiveShownInsideAParameterizedSlotIsRegisteredOnTheScreen():Void {
		final screen = new UITestScreen();
		final result = BuilderTestBase.buildFromSource("
			#slotMenu programmable() {
				#s slot(open:bool=false) {
					@(open=>true) interactive(40, 40, \"item\"): 0, 0
				}
			}
		", "slotMenu", null, Incremental);
		screen.addInteractives(result, "p");
		Assert.isNull(screen.getInteractive("p.item"), "precondition: hidden at registration");

		result.getSlot("s").setParameter("open", true);

		Assert.notNull(screen.getInteractive("p.item"), "an interactive shown by the slot's setParameter is wrapped by the screen");
	}

	@Test
	public function testCodegenInteractiveShownInsideADynamicRefIsRegisteredOnTheScreen():Void {
		final screen = new UITestScreen();
		final inst = createMp().rsMenuHost.create();
		screen.addInteractives(inst, "p");
		Assert.isNull(screen.getInteractive("p.item"), "precondition: hidden at registration");

		final dyn:Dynamic = inst;
		final menu:BuilderResult = dyn.getDynamicRef("m");
		menu.setParameter("open", true);

		Assert.notNull(screen.getInteractive("p.item"),
			"codegen: an interactive shown by the dynamicRef's own setParameter is wrapped by the screen");
	}

	static final DYNREF_IN_STATICREF_TARGET = "
		#key programmable() {
			interactive(20, 20, \"k\"): 0, 0
		}
		#mid programmable() {
			dynamicRef(key): 0, 0
		}
		#top programmable() {
			staticRef(mid): 0, 0
		}
	";

	@Test
	public function testInteractivesReachADynamicRefInsideAStaticRefTarget():Void {
		final result = BuilderTestBase.buildFromSource(DYNREF_IN_STATICREF_TARGET, "top");
		Assert.isTrue(interactiveIds(result.getInteractives()).indexOf("k") >= 0,
			"getInteractives() lists the interactive of a dynamicRef placed by the staticRef target");

		final incremental = BuilderTestBase.buildFromSource(DYNREF_IN_STATICREF_TARGET, "top", null, Incremental);
		Assert.isTrue(interactiveIds(incremental.getInteractives()).indexOf("k") >= 0, "in an incremental build too");

		final screen = new UITestScreen();
		screen.addInteractives(incremental);
		Assert.notNull(screen.getInteractive("k"), "so the screen registers it");

		final twin = BuilderTestBase.buildFromFile(FIXTURE, "rsTop");
		Assert.isTrue(interactiveIds(twin.getInteractives()).indexOf("k") >= 0, "the fixture's rsTop lists it, as its codegen instance does");
	}

	/** Parity guard: a codegen instance lists its interactives from its scene graph. */
	@Test
	public function testCodegenInteractivesReachADynamicRefInsideAStaticRefTarget():Void {
		final inst = createMp().rsTop.create();
		Assert.isTrue(interactiveIds(inst.getInteractives()).indexOf("k") >= 0,
			"codegen: getInteractives() lists the interactive two refs down");
	}

	// ==================== autoStatus / bind interactives placed by a dynamicRef ====================

	@Test
	public function testAutoStatusInteractivePlacedByDynamicRefDrivesThatDynamicRef():Void {
		final screen = new UITestScreen();
		final result = BuilderTestBase.buildFromSource("
			#btn programmable(status:[normal,hover,pressed]=normal) {
				interactive(40, 20, \"b\", autoStatus => \"status\"): 0, 0
			}
			#btnHost programmable() {
				#b dynamicRef(btn): 0, 0
			}
		", "btnHost", null, Incremental);
		screen.addInteractives(result);
		Assert.notNull(screen.getInteractive("b"), "precondition: the dynamicRef's interactive is registered");

		final err = errorOf(() -> screen.dispatchScreenEvent(UIInteractiveEvent(UIEntering(), "b", null), null));
		Assert.isNull(err, 'hover must set status on the programmable that declares it, not on the host: $err');
		if (err != null)
			return;
		Assert.equals("hover", result.getDynamicRef("b").getParameterValues().get("status"), "the dynamicRef's status follows the hover");
	}

	@Test
	public function testBindInteractivePlacedByDynamicRefDrivesThatDynamicRef():Void {
		final screen = new UITestScreen();
		final result = BuilderTestBase.buildFromSource("
			#bindBtn programmable(status:[normal,hover,pressed]=normal) {
				interactive(40, 20, \"bb\", bind => \"status\"): 0, 0
			}
			#bindHost programmable() {
				#bb dynamicRef(bindBtn): 0, 0
			}
		", "bindHost", null, Incremental);
		final helper = new UIRichInteractiveHelper(screen);
		helper.register(result);
		Assert.isTrue(helper.hasBinding("bb"), "precondition: the dynamicRef's interactive is bound");

		final err = errorOf(() -> helper.handleEvent(UIInteractiveEvent(UIEntering(), "bb", null)));
		Assert.isNull(err, 'hover must set status on the programmable that declares it, not on the host: $err');
		if (err != null)
			return;
		Assert.equals("hover", result.getDynamicRef("bb").getParameterValues().get("status"), "the dynamicRef's status follows the hover");
	}

	@Test
	public function testResyncAfterATemplateSwapDrivesTheNewDynamicRef():Void {
		// Both templates have an interactive "sb": after the swap the id is the same, the result
		// that owns it is the new child
		final screen = new UITestScreen();
		final result = BuilderTestBase.buildFromSource("
			#swapBtnA programmable(status:[normal,hover,pressed]=normal) {
				interactive(40, 20, \"sb\", bind => \"status\"): 0, 0
			}
			#swapBtnB programmable(status:[normal,hover,pressed]=normal) {
				interactive(60, 20, \"sb\", bind => \"status\"): 0, 0
			}
			#swapHost programmable(tmpl:[swapBtnA, swapBtnB]=swapBtnA) {
				#sb dynamicRef($tmpl): 0, 0
			}
		", "swapHost", null, Incremental);
		final helper = new UIRichInteractiveHelper(screen);
		helper.register(result);
		final before = result.getDynamicRef("sb");
		Assert.equals((before : bh.ui.UIInteractiveSource), helper.getSource("sb"), "precondition: bound to the first template's child");

		result.setParameter("tmpl", "swapBtnB");
		final after = result.getDynamicRef("sb");
		Assert.isTrue(after != before, "precondition: the swap made a new child");
		helper.resync(result);

		Assert.equals((after : bh.ui.UIInteractiveSource), helper.getSource("sb"), "resync binds the id to the child that holds it now");
		helper.handleEvent(UIInteractiveEvent(UIEntering(), "sb", null));
		Assert.equals("hover", after.getParameterValues().get("status"), "a hover drives the child that is shown");
	}

	@Test
	public function testResyncAfterATemplateSwapGivesTheNewDynamicRefTheBindingsState():Void {
		final screen = new UITestScreen();
		final result = BuilderTestBase.buildFromSource("
			#keepBtnA programmable(status:[normal,hover,pressed,disabled]=normal) {
				interactive(40, 20, \"kb\", bind => \"status\"): 0, 0
			}
			#keepBtnB programmable(status:[normal,hover,pressed,disabled]=normal) {
				interactive(60, 20, \"kb\", bind => \"status\"): 0, 0
			}
			#keepHost programmable(tmpl:[keepBtnA, keepBtnB]=keepBtnA) {
				#kb dynamicRef($tmpl): 0, 0
			}
		", "keepHost", null, Incremental);
		final helper = new UIRichInteractiveHelper(screen);
		helper.register(result);
		helper.setDisabled("kb", true);
		Assert.equals("disabled", result.getDynamicRef("kb").getParameterValues().get("status"), "precondition: drawn disabled");

		result.setParameter("tmpl", "keepBtnB");
		helper.resync(result);
		Assert.equals("disabled", result.getDynamicRef("kb").getParameterValues().get("status"),
			"the new template is drawn as the helper holds the binding: disabled");
	}

	// ==================== placeholder objects reach ref targets ====================

	/** Builder guard: the builder passes its BuilderParameters into the ref build. */
	@Test
	public function testBuilderPassesPlaceholderObjectsIntoRefTargets():Void {
		final builder = BuilderTestBase.builderFromFile(FIXTURE);
		final staticPortrait = new h2d.Object();
		final staticResult = builder.buildWithParameters("rsHolder", new Map(), {placeholderObjects: ["portrait" => PVObject(staticPortrait)]});
		Assert.isTrue(isUnder(staticPortrait, staticResult.object), "staticRef: the portrait object is placed in the target");

		final dynamicPortrait = new h2d.Object();
		final dynamicResult = builder.buildWithParameters("rsDynHolder", new Map(), {placeholderObjects: ["portrait" => PVObject(dynamicPortrait)]});
		Assert.isTrue(isUnder(dynamicPortrait, dynamicResult.object), "dynamicRef: the portrait object is placed in the target");
	}

	@Test
	public function testCodegenPassesPlaceholderObjectsIntoStaticRefTargets():Void {
		final top = new h2d.Object();
		final portrait = new h2d.Object();
		final inst = createMp().rsHolder.create(["top" => PVObject(top), "portrait" => PVObject(portrait)]);
		Assert.isTrue(isUnder(top, inst), "precondition: the instance's own placeholder takes its object");
		Assert.isTrue(isUnder(portrait, inst), "codegen: the portrait object is placed in the staticRef target, as by the builder");
	}

	@Test
	public function testCodegenPassesPlaceholderObjectsIntoDynamicRefTargets():Void {
		final top = new h2d.Object();
		final portrait = new h2d.Object();
		final inst = createMp().rsDynHolder.create(["top" => PVObject(top), "portrait" => PVObject(portrait)]);
		Assert.isTrue(isUnder(top, inst), "precondition: the instance's own placeholder takes its object");
		Assert.isTrue(isUnder(portrait, inst), "codegen: the portrait object is placed in the dynamicRef target, as by the builder");
	}

	// ==================== a staticRef to its own programmable ====================

	/** Builder guard: the programmable is already being built when its staticRef asks for it. */
	@Test
	public function testBuilderRejectsASelfRecursiveStaticRef():Void {
		Assert.equals("circular_reference", errorCodeOf(() -> BuilderTestBase.buildFromFile(FIXTURE, "rsTree")));
	}

	@Test
	public function testCodegenRejectsASelfRecursiveStaticRef():Void {
		final err = errorOf(() -> createMp().rsTree.create());
		Assert.notNull(err, "codegen: a staticRef to the programmable being created is a circular reference, as in the builder");
		if (err != null)
			Assert.isTrue(err.toLowerCase().indexOf("circular") >= 0, 'the error says so: $err');
	}

	// ==================== codegen: one #name in mutually exclusive arms ====================

	@Test
	public function testCodegenSameDynamicRefNameInExclusiveArmsAnswersWithTheShownArm():Void {
		final inst:Dynamic = createMp().rsExclRef.create();
		final root:h2d.Object = cast inst;
		final first:BuilderResult = inst.getDynamicRef("panel");
		Assert.equals("10", widthsOf(first.object), "precondition: arm a's panel answers at create");
		inst.setParameter("mode", "b");
		final shown:BuilderResult = inst.getDynamicRef("panel");
		Assert.isTrue(drawnUnder(shown.object, root), "getDynamicRef(\"panel\") answers with the arm that is shown");
		Assert.equals("20", widthsOf(shown.object));
		inst.setParameter("mode", "a");
		final back:BuilderResult = inst.getDynamicRef("panel");
		Assert.isTrue(drawnUnder(back.object, root));
		Assert.equals("10", widthsOf(back.object));
	}

	/** A dynamic-name ref (`dynamicRef($tmpl)`) may share its #name across exclusive arms in codegen,
	 *  as in the builder; the shown arm answers, after a template swap too. */
	@Test
	public function testCodegenSameDynamicNameRefNameInExclusiveArmsAnswersWithTheShownArm():Void {
		final inst:Dynamic = createMp().rsExclTemplate.create();
		final root:h2d.Object = cast inst;
		inst.setParameter("tmpl", "rsPanelB");
		final first:BuilderResult = inst.getDynamicRef("panel");
		Assert.isTrue(drawnUnder(first.object, root), "precondition: arm a's panel answers");
		Assert.equals("20", widthsOf(first.object));
		inst.setParameter("mode", "b");
		final shown:BuilderResult = inst.getDynamicRef("panel");
		Assert.isTrue(drawnUnder(shown.object, root), "getDynamicRef(\"panel\") answers with the arm that is shown");
		Assert.equals(10.0, yUnder(shown.object, root), "the @else arm's panel");
		Assert.equals("20", widthsOf(shown.object));
	}

	@Test
	public function testCodegenSameSlotNameInExclusiveArmsAnswersWithTheShownArm():Void {
		final inst:Dynamic = createMp().rsExclSlot.create();
		final root:h2d.Object = cast inst;
		inst.setParameter("mode", "b");
		final slot:bh.multianim.MultiAnimBuilder.SlotHandle = inst.getSlot("content", null, null);
		Assert.isTrue(drawnUnder(slot.container, root), "getSlot(\"content\") answers with the shown arm's slot");
		Assert.equals(20.0, yUnder(slot.container, root));
		final marker = new h2d.Object();
		slot.setContent(marker);
		Assert.isTrue(drawnUnder(marker, root));
		inst.setParameter("mode", "a");
		final back:bh.multianim.MultiAnimBuilder.SlotHandle = inst.getSlot("content", null, null);
		Assert.isTrue(drawnUnder(back.container, root));
		Assert.equals(0.0, yUnder(back.container, root));
	}

	@Test
	public function testCodegenSameIndexedSlotNameInExclusiveArmsAnswersWithTheShownArm():Void {
		final inst:Dynamic = createMp().rsExclIndexedSlot.create();
		final root:h2d.Object = cast inst;
		inst.setParameter("mode", "b");
		final first:bh.multianim.MultiAnimBuilder.SlotHandle = inst.getSlot("c", 0, null);
		final second:bh.multianim.MultiAnimBuilder.SlotHandle = inst.getSlot("c", 1, null);
		Assert.isTrue(drawnUnder(first.container, root));
		Assert.equals(30.0, yUnder(first.container, root));
		Assert.isTrue(drawnUnder(second.container, root));
		Assert.equals(10.0, xUnder(second.container, root));
		inst.setParameter("mode", "a");
		final back:bh.multianim.MultiAnimBuilder.SlotHandle = inst.getSlot("c", 0, null);
		Assert.isTrue(drawnUnder(back.container, root));
		Assert.equals(0.0, yUnder(back.container, root));
	}
}
