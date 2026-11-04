package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.multianim.LiveProgrammable;

/**
 * `#name[...]` with an index worked out from loop variables, numbers and @finals
 * (`#card[$row * 3 + $c]`): nested or sibling repeatables number one list, read back by index
 * in the builder and codegen alike — dynamicRefs (`getDynamicRefByIndex`), names, slots, a 2-D
 * index, a @final used as the index; a param-dependent inner count built again at a new count.
 * The parser refuses an unknown variable, a parameter (directly or through a @final) and anything
 * but whole-number arithmetic; two elements given one index are a build error, except in
 * mutually exclusive arms.
 *
 * Companion fixture: test/examples/173-indexExpression/indexExpression.manim
 * The .manim sources use double quotes so Haxe does not interpolate $row / $c.
 */
class IndexExpressionTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/173-indexExpression/indexExpression.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	function builderResult(name:String):bh.multianim.MultiAnimBuilder.BuilderResult {
		return TestResourceLoader.createLoader(false).loadMultiAnim(FIXTURE).buildWithParameters(name, new Map(), null, null, true);
	}

	static function errorOf(fn:Void -> Void):Null<String> {
		try {
			fn();
			return null;
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	static function offsetToRoot(obj:h2d.Object, root:h2d.Object):String {
		var x = 0.0;
		var y = 0.0;
		var o:Null<h2d.Object> = obj;
		while (o != null && o != root) {
			x += o.x;
			y += o.y;
			o = o.parent;
		}
		return Std.int(x) + "," + Std.int(y);
	}

	static function sorted(a:Array<String>):Array<String> {
		final c = a.copy();
		c.sort(Reflect.compare);
		return c;
	}

	/** Each card of the grid read back by index: card k is column k % 3 of row k div 3. */
	static function assertGrid(label:String, live:Dynamic, root:h2d.Object, count:Int):Void {
		for (k in 0...count) {
			final ref:bh.multianim.MultiAnimBuilder.BuilderResult = live.getDynamicRefByIndex("card", k);
			Assert.notNull(ref, '$label: card $k is there');
			if (ref != null)
				Assert.equals(((k % 3) * 20) + "," + (Std.int(k / 3) * 14), offsetToRoot(ref.object, root),
					'$label: card $k is column ${k % 3} of row ${Std.int(k / 3)}');
		}
		Assert.isFalse(live.hasDynamicRef("card " + count), '$label: no card $count');
	}

	// ==================== Two nested repeatables, 3 per row, one list ====================

	@Test
	public function testNestedRepeatablesNumberOneList_Builder():Void {
		final result = builderResult("ixGrid");
		assertGrid("builder", result, result.object, 12);
	}

	@Test
	public function testNestedRepeatablesNumberOneList_Codegen():Void {
		final inst:Dynamic = createMp().ixGrid.create();
		assertGrid("codegen", inst, cast inst, 12);
	}

	@Test
	public function testNestedRepeatablesNumberOneList_SameKeys():Void {
		final inst:LiveProgrammable = createMp().ixGrid.create();
		final res:LiveProgrammable = builderResult("ixGrid");
		final expected = sorted([for (k in 0...12) "card " + k]);
		Assert.same(expected, sorted(res.getDynamicRefKeys()), "builder: card 0 to card 11");
		Assert.same(expected, sorted(inst.getDynamicRefKeys()), "codegen: card 0 to card 11");
	}

	// ==================== Names, slots, 2-D, @finals, sibling repeatables ====================

	/** `slot`: the result's or instance's getSlot (typed: a dynamic call to it misses its optional indexY on HashLink). */
	function assertNames(label:String, live:LiveProgrammable, slot:(String, Int) -> Null<bh.multianim.MultiAnimBuilder.SlotHandle>):Void {
		final root = live.getRoot();
		final dyn:Dynamic = live;
		final slotKeys = [for (e in live.getSlotEntries()) Std.string(e.key)];
		for (row in 0...2)
			for (c in 0...3) {
				final k = row * 3 + c;
				final tile = live.getNamedDrawn("tile", k);
				Assert.notNull(tile, '$label: tile $k ($$row * $$perRow + $$c)');
				if (tile != null)
					Assert.equals((c * 10) + "," + (row * 10), offsetToRoot(tile, root), '$label: tile $k at its column and row');
				final cell = (k * 2) + 1;
				Assert.isTrue(slotKeys.indexOf('Indexed(cell,$cell)') >= 0, '$label: slot cell $cell (($$row * 3 + $$c) * 2 + 1), got $slotKeys');
				final handle = slot("cell", cell);
				Assert.notNull(handle, '$label: getSlot("cell", $cell)');
				final pip = live.getNamedDrawn("pip", c + 1, row * 2);
				Assert.notNull(pip, '$label: pip [${c + 1}, ${row * 2}]');
				if (pip != null)
					Assert.equals((c * 10) + "," + (row * 10 + 80), offsetToRoot(pip, root), '$label: pip [${c + 1}, ${row * 2}] at its column and row');
				Assert.isTrue(dyn.hasDynamicRef('ref2 $c ${row + 1}'), '$label: dynamicRef "ref2 $c ${row + 1}"');
				final mark = live.getNamedDrawn("mark", k);
				Assert.notNull(mark, '$label: mark $k (a @final k = $$row * 3 + $$c as the index)');
				if (mark != null)
					Assert.equals((c * 10) + "," + (row * 10 + 160), offsetToRoot(mark, root), '$label: mark $k at its column and row');
			}
		Assert.isTrue(slotKeys.indexOf("Indexed(cell,0)") < 0, '$label: no slot cell 0 (the cells are odd)');
		for (i in 0...5) {
			final item = live.getNamedDrawn("item", i);
			Assert.notNull(item, '$label: item $i, from the first repeatable (0, 1) or the second ($$j + 2)');
			if (item != null)
				Assert.equals(i < 2 ? (i * 10) + ",200" : ((i - 2) * 10) + ",210", offsetToRoot(item, root), '$label: item $i where its repeatable put it');
		}
		Assert.isNull(live.getNamedDrawn("item", 5), '$label: no item 5');
	}

	@Test
	public function testIndexExpressions_Builder():Void {
		final result = builderResult("ixNames");
		assertNames("builder", result, (n, i) -> result.getSlot(n, i));
	}

	@Test
	public function testIndexExpressions_Codegen():Void {
		final inst = createMp().ixNames.create();
		assertNames("codegen", inst, (n, i) -> inst.getSlot(n, i));
	}

	@Test
	public function testIndexExpressions_SameKeys():Void {
		final inst:LiveProgrammable = createMp().ixNames.create();
		final res:LiveProgrammable = builderResult("ixNames");
		Assert.same(sorted(res.getNamedKeys()), sorted(inst.getNamedKeys()), "named keys");
		Assert.same(sorted([for (e in res.getSlotEntries()) Std.string(e.key)]), sorted([for (e in inst.getSlotEntries()) Std.string(e.key)]), "slot keys");
		Assert.same(sorted(res.getDynamicRefKeys()), sorted(inst.getDynamicRefKeys()), "dynamicRef keys");
		Assert.isTrue(res.getNamedKeys().indexOf("tile 5") >= 0, "builder: tile 5");
		Assert.isTrue(res.getNamedKeys().indexOf("pip 3 2") >= 0, "builder: pip 3 2");
	}

	// ==================== A param-dependent inner count ====================

	function assertParamGrid(label:String, live:Dynamic, present:Array<Int>, absent:Array<Int>):Void {
		final root:h2d.Object = (live : LiveProgrammable).getRoot();
		for (k in present) {
			Assert.isTrue(live.hasDynamicRef("card " + k), '$label: card $k is there');
			if (live.hasDynamicRef("card " + k)) {
				final ref:bh.multianim.MultiAnimBuilder.BuilderResult = live.getDynamicRefByIndex("card", k);
				Assert.equals(((k % 3) * 20) + "," + (Std.int(k / 3) * 14), offsetToRoot(ref.object, root), '$label: card $k at its column and row');
			}
		}
		for (k in absent)
			Assert.isFalse(live.hasDynamicRef("card " + k), '$label: no card $k');
	}

	@Test
	public function testParamDependentInnerCount_Builder():Void {
		final result = builderResult("ixParamGrid");
		assertParamGrid("builder n=3", result, [0, 1, 2, 3, 4, 5], [6]);
		result.setParameter("n", 2);
		assertParamGrid("builder n=2", result, [0, 1, 3, 4], [2, 5]);
		result.setParameter("n", 3);
		assertParamGrid("builder n=3 again", result, [0, 1, 2, 3, 4, 5], [6]);
	}

	@Test
	public function testParamDependentInnerCount_Codegen():Void {
		final inst:Dynamic = createMp().ixParamGrid.create();
		assertParamGrid("codegen n=3", inst, [0, 1, 2, 3, 4, 5], [6]);
		inst.setParameter("n", 2);
		assertParamGrid("codegen n=2", inst, [0, 1, 3, 4], [2, 5]);
		inst.setParameter("n", 3);
		assertParamGrid("codegen n=3 again", inst, [0, 1, 2, 3, 4, 5], [6]);
	}

	@Test
	public function testParamDependentInnerCount_TooManyPerRowCollides():Void {
		final result = builderResult("ixParamGrid");
		final err = errorOf(() -> result.setParameter("n", 4));
		Assert.notNull(err, "4 per row with $row * 3 + $c: card 3 twice");
	}

	// ==================== The parser ====================

	@Test
	public function testUnknownVariableInIndexIsAParseError():Void {
		final err = BuilderTestBase.parseExpectingError("
			#leaf programmable() {
				bitmap(generated(color(4, 4, #ff0000))): 0, 0
			}
			#x programmable() {
				repeatable($row, range(0, 2)) {
					repeatable($c, range(0, 3)) {
						#card[$row * 3 + $col] dynamicRef(leaf): 0, 0
					}
				}
			}
		");
		Assert.notNull(err, "an index naming no loop variable or @final");
		if (err != null) {
			Assert.isTrue(err.indexOf("#card[$row * 3 + $col]") >= 0, 'names the index as written, got: $err');
			Assert.isTrue(err.indexOf("$col is not a known loop variable") >= 0, 'names the unknown variable, got: $err');
			// line 1 is the version header the helper puts in front, line 2 the source's first newline
			Assert.isTrue(err.indexOf("test-input:9:") >= 0, 'names the line, got: $err');
		}
	}

	@Test
	public function testNameWithoutIndexInNestedRepeatablesOffersOneList():Void {
		final err = BuilderTestBase.parseExpectingError("
			#x programmable() {
				repeatable($row, range(0, 2)) {
					repeatable($c, range(0, 3)) {
						#tile bitmap(generated(color(4, 4, #ff0000))): 0, 0
					}
				}
			}
		");
		Assert.notNull(err, "#tile with no index inside repeatables");
		if (err != null) {
			Assert.isTrue(err.indexOf("requires indexed form #tile[$c]") >= 0, 'got: $err');
			Assert.isTrue(err.indexOf("#tile[$row * N + $c]") >= 0, 'offers the one-list form, got: $err');
		}
	}

	@Test
	public function testPlainUnknownIndexVariableIsAParseError():Void {
		final err = BuilderTestBase.parseExpectingError("
			#x programmable() {
				repeatable($i, range(0, 2)) {
					#tile[$j] bitmap(generated(color(4, 4, #ff0000))): 0, 0
				}
			}
		");
		Assert.notNull(err, "a plain $j that is no loop variable");
		if (err != null)
			Assert.isTrue(err.indexOf("index variable $j is not a known loop variable") >= 0, 'got: $err');
	}

	@Test
	public function testParameterInIndexIsAParseError():Void {
		final err = BuilderTestBase.parseExpectingError("
			#x programmable(cols:uint=3) {
				repeatable($row, range(0, 2)) {
					repeatable($c, range(0, $cols)) {
						#tile[$row * $cols + $c] bitmap(generated(color(4, 4, #ff0000))): 0, 0
					}
				}
			}
		");
		Assert.notNull(err, "a parameter in an index");
		if (err != null) {
			Assert.isTrue(err.indexOf("$cols is a parameter") >= 0, 'says it is a parameter, got: $err');
			Assert.isTrue(err.indexOf("@final cols = 3") >= 0, 'says what to write instead, got: $err');
		}
	}

	@Test
	public function testParameterThroughFinalInIndexIsAParseError():Void {
		final err = BuilderTestBase.parseExpectingError("
			#x programmable(cols:uint=3) {
				@final perRow = $cols
				repeatable($row, range(0, 2)) {
					repeatable($c, range(0, 3)) {
						#tile[$row * $perRow + $c] bitmap(generated(color(4, 4, #ff0000))): 0, 0
					}
				}
			}
		");
		Assert.notNull(err, "a @final that uses a parameter, in an index");
		if (err != null)
			Assert.isTrue(err.indexOf("@final $perRow uses the parameter $cols") >= 0, 'got: $err');
	}

	@Test
	public function testComparisonInIndexIsAParseError():Void {
		final err = BuilderTestBase.parseExpectingError("
			#x programmable() {
				repeatable($i, range(0, 2)) {
					#tile[$i == 1] bitmap(generated(color(4, 4, #ff0000))): 0, 0
				}
			}
		");
		Assert.notNull(err, "a comparison is no index");
		if (err != null)
			Assert.isTrue(err.indexOf("cannot be an index") >= 0, 'got: $err');
	}

	@Test
	public function testConstantFinalInIndexParses():Void {
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess("
			#x programmable() {
				@final cols = 3
				@final rowWidth = $cols * 2
				repeatable($row, range(0, 2)) {
					repeatable($c, range(0, 3)) {
						#tile[$row * $rowWidth div 2 + $c, -$row] bitmap(generated(color(4, 4, #ff0000))): 0, 0
					}
				}
			}
		"), "loop variables, numbers and @finals of those, with div, unary minus and a 2-D index");
	}

	// ==================== Two elements given one index ====================

	@Test
	public function testCollidingIndexExpression_Names_Throws():Void {
		final err = errorOf(() -> BuilderTestBase.buildFromSource("#x programmable() {
			repeatable($row, range(0, 2)) {
				repeatable($c, range(0, 3)) {
					#tile[$row * 2 + $c] bitmap(generated(color(4, 4, #ff0000))): 0, 0
				}
			}
		}", "x", null));
		Assert.notNull(err, "row 0 gives 0..2, row 1 gives 2..4: tile 2 twice");
		if (err != null) {
			Assert.isTrue(err.indexOf("indexed name \"tile[2]\"") >= 0, 'names the key, got: $err');
			Assert.isTrue(err.indexOf("#tile[$row * 2 + $c]") >= 0, 'names the index as written, got: $err');
		}
	}

	@Test
	public function testCollidingIndexExpression_DynamicRef_Throws():Void {
		final err = errorOf(() -> BuilderTestBase.buildFromSource("#leaf programmable() {
			bitmap(generated(color(4, 4, #ff0000))): 0, 0
		}
		#x programmable() {
			repeatable($row, range(0, 2)) {
				repeatable($c, range(0, 3)) {
					#card[$row * 2 + $c] dynamicRef(leaf): 0, 0
				}
			}
		}", "x", null));
		Assert.notNull(err, "card 2 twice");
		if (err != null)
			Assert.isTrue(err.indexOf("card 2") >= 0, 'names the key, got: $err');
	}

	@Test
	public function testCollidingIndexExpression_Slot_Throws():Void {
		final err = errorOf(() -> BuilderTestBase.buildFromSource("#x programmable() {
			repeatable($i, range(0, 2)) {
				#slotA[$i div 2] slot: 0, 0
			}
		}", "x", null));
		Assert.notNull(err, "$i div 2 is 0 for $i = 0 and 1");
		// the slot's name is registered before its handle: the names' check answers first
		if (err != null)
			Assert.isTrue(err.indexOf("slotA[0]\" is built more than once") >= 0 && err.indexOf("#slotA[$i div 2]") >= 0, 'got: $err');
	}

	/** The drawn tile k is the shown arm's: 4 wide for mode a, 6 for b. */
	function assertArms(label:String, live:LiveProgrammable, width:Int):Void {
		for (k in 0...6) {
			final tile:Null<h2d.Object> = live.getNamedDrawn("tile", k);
			Assert.notNull(tile, '$label: tile $k drawn');
			final bitmap = tile == null ? null : Std.downcast(tile, h2d.Bitmap);
			if (bitmap != null)
				Assert.equals(width, Std.int(bitmap.tile.width), '$label: tile $k is the shown arm\'s');
		}
	}

	@Test
	public function testIndexExpressionInExclusiveArmsIsNoCollision_Builder():Void {
		var result:Null<bh.multianim.MultiAnimBuilder.BuilderResult> = null;
		final err = errorOf(() -> result = builderResult("ixArms"));
		Assert.isNull(err, 'one index in mutually exclusive arms is no collision, got: $err');
		if (result != null) {
			assertArms("builder mode a", result, 4);
			result.setParameter("mode", "b");
			assertArms("builder mode b", result, 6);
		}
	}

	@Test
	public function testIndexExpressionInExclusiveArmsIsNoCollision_Codegen():Void {
		// generated at all: codegen accepted the one index in both arms
		final inst = createMp().ixArms.create();
		assertArms("codegen mode a", inst, 4);
		inst.setParameter("mode", "b");
		assertArms("codegen mode b", inst, 6);
	}
}
