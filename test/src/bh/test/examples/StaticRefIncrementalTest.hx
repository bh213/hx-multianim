package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.BuildMode;

/**
 * Regression — a staticRef inside a programmable built incrementally (and in a codegen instance),
 * with setParameter on the enclosing programmable.
 *
 * Bug shape: buildWithParameters(incremental=false) for the staticRef kept the enclosing build's
 * incrementalMode/incrementalContext (pushBuilderState saves them but does not reset them), so the
 * staticRef's expressions were tracked on the OUTER context and re-resolved against the outer params
 * by name: `staticRef($sail, dir=>e)` inside a programmable with its own `dir` redrew the sail with
 * the outer value, while its conditionals (the hull) and renamed arguments (`w=>$size`) never
 * followed. Codegen never updated a staticRef at all. Now the nested build is isolated and a
 * staticRef whose target or arguments use the enclosing params is built again when one changes.
 *
 * Companion fixture: test/examples/156-staticRefIncremental/staticRefIncremental.manim
 */
class StaticRefIncrementalTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/156-staticRefIncremental/staticRefIncremental.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	/** The visible bitmaps, in tree order, as "WxH". */
	static function sizes(obj:h2d.Object):String {
		return [for (b in BuilderTestBase.findVisibleBitmapDescendants(obj)) Std.int(b.tile.width) + "x" + Std.int(b.tile.height)].join(",");
	}

	static function build(name:String) {
		return BuilderTestBase.buildFromFile(FIXTURE, name, null, Incremental);
	}

	static function bitmaps(obj:h2d.Object):Array<h2d.Bitmap> {
		return BuilderTestBase.findVisibleBitmapDescendants(obj);
	}

	/** The visible bitmaps, in tree order, as "WxH@x,y" relative to `root`. */
	static function placed(root:h2d.Object):String {
		return [
			for (b in bitmaps(root)) {
				var x = 0.0, y = 0.0;
				var o:h2d.Object = b;
				while (o != null && o != root) {
					x += o.x;
					y += o.y;
					o = o.parent;
				}
				'${Std.int(b.tile.width)}x${Std.int(b.tile.height)}@${Std.int(x)},${Std.int(y)}';
			}
		].join(" ");
	}

	static function runAndCatch(fn:() -> Void):Null<String> {
		try {
			fn();
			return null;
		} catch (e:Dynamic)
			return Std.string(e);
	}

	static function assertRefusedForChildren(msg:Null<String>, paramName:String, label:String):Void {
		Assert.notNull(msg, '$label: expected throw, none raised');
		if (msg == null)
			return;
		Assert.isTrue(msg.indexOf('setParameter("' + paramName + '", ...) rejected') >= 0, '$label: message must name the param — got: $msg');
		Assert.isTrue(msg.indexOf("staticRef with children") >= 0, '$label: message must give the reason — got: $msg');
	}

	// ==================== Builder ====================

	@Test
	public function testBuilder_LiteralArgumentKeepsItsValue():Void {
		final r = build("sriLiteral");
		Assert.equals("11x2,5x4", sizes(r.object));
		r.setParameter("w", 22);
		Assert.equals("22x2,5x4", sizes(r.object), "the outer w changes the outer's bitmap only; staticRef(w=>5) stays 5");
	}

	@Test
	public function testBuilder_RenamedArgumentFollows():Void {
		final r = build("sriRenamed");
		Assert.equals("11x4", sizes(r.object));
		r.setParameter("size", 22);
		Assert.equals("22x4", sizes(r.object), "staticRef(w=>$size) follows size");
	}

	@Test
	public function testBuilder_ConditionalsInsideFollow():Void {
		final r = build("sriNested");
		Assert.equals("11x4", sizes(r.object));
		r.setParameter("dir", "n");
		Assert.equals("22x4", sizes(r.object), "the referenced programmable's own @(dir=>…) arms follow dir");
		r.setParameter("dir", "e");
		Assert.equals("11x4", sizes(r.object));
	}

	@Test
	public function testBuilder_DeferredArmFollowsAfterShown():Void {
		final r = build("sriDefer");
		Assert.equals("5x4", sizes(r.object));
		r.setParameter("dir", "w");
		Assert.equals("6x4", sizes(r.object), "the deferred arm is built with the current c");
		r.setParameter("c", 9);
		Assert.equals("10x4", sizes(r.object), "the materialized arm's staticRef follows c afterwards");
		r.setParameter("dir", "e");
		Assert.equals("9x4", sizes(r.object));
	}

	@Test
	public function testBuilder_LoopVariableKeptForRebuild():Void {
		final r = build("sriRepeat");
		Assert.equals("5x4,6x4", sizes(r.object));
		r.setParameter("c", 9);
		Assert.equals("9x4,10x4", sizes(r.object), "each copy is rebuilt with its own $i");
	}

	@Test
	public function testBuilder_TargetChosenByParam():Void {
		final r = build("sriByName");
		Assert.equals("7x4", sizes(r.object));
		r.setParameter("which", "sriLeafTall");
		Assert.equals("7x7", sizes(r.object));
	}

	@Test
	public function testBuilder_ShipTurnsAndRecolours():Void {
		final r = build("sriDemo");
		Assert.equals("99x99,40x1,3x4", sizes(r.object));
		r.setParameter("dir", "n");
		Assert.equals("99x99,1x40,3x7", sizes(r.object), "the ship's hull and its sail both turn");
		r.setParameter("colour", 8);
		Assert.equals("99x99,1x40,8x7", sizes(r.object));
	}

	@Test
	public function testBuilder_BatchedChangesRebuildOnce():Void {
		final r = build("sriDemo");
		r.beginUpdate();
		r.setParameter("dir", "n");
		r.setParameter("colour", 8);
		r.endUpdate();
		Assert.equals("99x99,1x40,8x7", sizes(r.object));
	}

	@Test
	public function testBuilder_StaticRefWithoutParamsIsNeverRebuilt():Void {
		final r = build("sriLiteral");
		final leaf = bitmaps(r.object)[1];
		r.setParameter("w", 22);
		Assert.isTrue(leaf == bitmaps(r.object)[1], "staticRef(w=>5) uses no param: the same build stays");
	}

	@Test
	public function testBuilder_StaticRefWithChildrenRefusesItsParams():Void {
		final r = build("sriWithKids");
		Assert.equals("2x1,5x4,2x2", sizes(r.object));
		r.setParameter("bar", 3);
		Assert.equals("3x1,5x4,2x2", sizes(r.object), "a param the staticRef does not use still follows");

		var err:Null<bh.multianim.BuilderError> = null;
		var msg:Null<String> = null;
		try {
			r.setParameter("c", 9);
		} catch (e:Dynamic) {
			msg = Std.string(e);
			if (Std.isOfType(e, bh.multianim.BuilderError))
				err = cast e;
		}
		assertRefusedForChildren(msg, "c", "builder");
		Assert.notNull(err, "builder throw must be a BuilderError");
		if (err != null)
			Assert.equals("untracked_param", err.code, "BuilderError.code");
		Assert.equals("3x1,5x4,2x2", sizes(r.object), "the refused change leaves the staticRef and its children as built");
	}

	@Test
	public function testBuilder_StaticRefChildrenMoveWithTargetPos():Void {
		final r = build("sriKidsAt");
		Assert.equals("4x4@3,2 2x2@4,3", placed(r.object), "the children go into the target's root, at its pos");
	}

	@Test
	public function testBuilder_LoopVariablesAndFinalsAreNotTracked():Void {
		final r = build("sriFixedOnly");
		Assert.equals("5x1,3x4,4x4", sizes(r.object));
		final ctx = r.incrementalContext;
		Assert.notNull(ctx);
		if (ctx != null) {
			final tracked = @:privateAccess ctx.trackedByParam;
			Assert.isFalse(tracked.exists("i"), "a loop variable never changes: nothing tracked for it");
			Assert.isFalse(tracked.exists("W"), "a @final never changes: nothing tracked for it");
		}
		final leaf = bitmaps(r.object)[1];
		r.setParameter("c", 9);
		Assert.equals("9x1,3x4,4x4", sizes(r.object));
		Assert.isTrue(leaf == bitmaps(r.object)[1], "the staticRef is left as built");
	}

	@Test
	public function testBuilder_ExternalStaticRefFollows():Void {
		final r = build("sriExternal");
		Assert.equals("5x3", sizes(r.object));
		r.setParameter("c", 9);
		Assert.equals("9x3", sizes(r.object), "staticRef(external(ext), …, w=>$c) is built again by the imported builder");
	}

	@Test
	public function testBuilder_NonIncrementalBuildUnchanged():Void {
		final r = BuilderTestBase.buildFromFile(FIXTURE, "sriLiteral", ["w" => 22]);
		Assert.equals("22x2,5x4", sizes(r.object));
		final d = BuilderTestBase.buildFromFile(FIXTURE, "sriDemo", ["dir" => "n", "colour" => 8]);
		Assert.equals("99x99,1x40,8x7", sizes(d.object));
	}

	// ==================== Codegen ====================

	@Test
	public function testCodegen_LiteralArgumentKeepsItsValue():Void {
		final inst:Dynamic = createMp().sriLiteral.create();
		Assert.equals("11x2,5x4", sizes(inst));
		inst.setParameter("w", 22);
		Assert.equals("22x2,5x4", sizes(inst));
	}

	@Test
	public function testCodegen_RenamedArgumentFollows():Void {
		final inst:Dynamic = createMp().sriRenamed.create();
		Assert.equals("11x4", sizes(inst));
		inst.setParameter("size", 22);
		Assert.equals("22x4", sizes(inst), "codegen: staticRef(w=>$size) follows size");
	}

	@Test
	public function testCodegen_ConditionalsInsideFollow():Void {
		final inst:Dynamic = createMp().sriNested.create();
		Assert.equals("11x4", sizes(inst));
		inst.setParameter("dir", "n");
		Assert.equals("22x4", sizes(inst));
		inst.setParameter("dir", "e");
		Assert.equals("11x4", sizes(inst));
	}

	@Test
	public function testCodegen_ConditionalArmsFollow():Void {
		final inst:Dynamic = createMp().sriDefer.create();
		Assert.equals("5x4", sizes(inst));
		inst.setParameter("dir", "w");
		Assert.equals("6x4", sizes(inst));
		inst.setParameter("c", 9);
		Assert.equals("10x4", sizes(inst));
		inst.setParameter("dir", "e");
		Assert.equals("9x4", sizes(inst));
	}

	@Test
	public function testCodegen_LoopVariableKeptForRebuild():Void {
		final inst:Dynamic = createMp().sriRepeat.create();
		Assert.equals("5x4,6x4", sizes(inst));
		inst.setParameter("c", 9);
		Assert.equals("9x4,10x4", sizes(inst));
	}

	@Test
	public function testCodegen_TargetChosenByParam():Void {
		final inst:Dynamic = createMp().sriByName.create();
		Assert.equals("7x4", sizes(inst));
		inst.setParameter("which", "sriLeafTall");
		Assert.equals("7x7", sizes(inst));
	}

	@Test
	public function testCodegen_ShipTurnsAndRecolours():Void {
		final inst:Dynamic = createMp().sriDemo.create();
		Assert.equals("99x99,40x1,3x4", sizes(inst));
		inst.setParameter("dir", "n");
		Assert.equals("99x99,1x40,3x7", sizes(inst));
		inst.setParameter("colour", 8);
		Assert.equals("99x99,1x40,8x7", sizes(inst));
		inst.beginUpdate();
		inst.setParameter("dir", "e");
		inst.setParameter("colour", 4);
		inst.endUpdate();
		Assert.equals("99x99,40x1,4x4", sizes(inst));
	}

	@Test
	public function testCodegen_UnchangedValuesBuildNothing():Void {
		final inst:Dynamic = createMp().sriDemo.create();
		final before = bitmaps(inst);
		inst.beginUpdate();
		inst.setParameter("dir", "n");
		inst.setParameter("dir", "e");
		inst.endUpdate();
		final after = bitmaps(inst);
		Assert.equals("99x99,40x1,3x4", sizes(inst));
		Assert.isTrue(before[1] == after[1] && before[2] == after[2], "a batch that ends on the values built with builds nothing");

		inst.setParameter("dir", "n");
		Assert.isFalse(before[2] == bitmaps(inst)[2], "a changed argument builds again");
	}

	@Test
	public function testCodegen_StaticRefWithoutParamsIsNeverRebuilt():Void {
		final inst:Dynamic = createMp().sriLiteral.create();
		final leaf = bitmaps(inst)[1];
		inst.setParameter("w", 22);
		Assert.isTrue(leaf == bitmaps(inst)[1], "codegen: staticRef(w=>5) uses no param: the same build stays");
	}

	@Test
	public function testCodegen_StaticRefWithChildrenRefusesItsParams():Void {
		final inst:Dynamic = createMp().sriWithKids.create();
		final leaf = bitmaps(inst)[1];
		inst.setParameter("bar", 3);
		Assert.equals(3, Std.int(bitmaps(inst)[0].tile.width), "codegen: a param the staticRef does not use still follows");
		assertRefusedForChildren(runAndCatch(() -> inst.setC(9)), "c", "codegen typed setter");
		assertRefusedForChildren(runAndCatch(() -> inst.setParameter("c", 9)), "c", "codegen setParameter dispatcher");
		Assert.isTrue(leaf == bitmaps(inst)[1], "codegen: the refused change leaves the staticRef as built");
	}

	/** Codegen parity: the builder draws a staticRef's own children inside it; codegen dropped them
	 *  (generateStaticRefCreate returned isContainer: false, so processChildren never ran for them). */
	@Test
	public function testCodegen_StaticRefChildrenAreDrawn():Void {
		final inst:Dynamic = createMp().sriWithKids.create();
		Assert.equals(sizes(build("sriWithKids").object), sizes(inst), "codegen draws the staticRef's children like the builder");
	}

	@Test
	public function testCodegen_StaticRefChildrenMoveWithTargetPos():Void {
		final inst:Dynamic = createMp().sriKidsAt.create();
		Assert.equals("4x4@3,2 2x2@4,3", placed(inst), "codegen: the children go into the target's root, at its pos");
	}

	@Test
	public function testCodegen_LoopVariablesAndFinalsAreNotTracked():Void {
		final inst:Dynamic = createMp().sriFixedOnly.create();
		Assert.equals("5x1,3x4,4x4", sizes(inst));
		final leaf = bitmaps(inst)[1];
		inst.setParameter("c", 9);
		Assert.equals("9x1,3x4,4x4", sizes(inst));
		Assert.isTrue(leaf == bitmaps(inst)[1], "codegen: the staticRef is left as built");
	}

	@Test
	public function testCodegen_ExternalStaticRefFollows():Void {
		final inst:Dynamic = createMp().sriExternal.create();
		Assert.equals("5x3", sizes(inst));
		inst.setParameter("c", 9);
		Assert.equals("9x3", sizes(inst), "codegen: the external staticRef is built again");
	}
}
