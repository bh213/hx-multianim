package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * A 1-D indexed name/slot `#name[$j]` whose index variable recurs across nested
 * loops produces an ambiguous, colliding key. With
 *
 *     repeatable($i, step(2)) { repeatable($j, step(2)) { #tile[$j] ... } }
 *
 * the inner index $j takes values 0,1 once per outer iteration, so `tile 0` and
 * `tile 1` are each registered twice.
 *
 * The two backends diverge:
 *  - Builder keys named elements / slots in arrays under "name idx" and silently
 *    keeps the first iteration (named) / coexists (slot).
 *  - Codegen emits one switch case per entry (named) or one private handle field
 *    per entry (slot), so the recurring index becomes duplicate switch cases /
 *    a "Duplicate class field declaration" compile error.
 *
 * Contract: reject the collision loudly on both backends. This test covers the
 * runtime builder reject; the codegen reject is a macro-time Context.error
 * (cannot be exercised as a normal test without breaking compilation).
 *
 * The .manim sources use double quotes so Haxe does not interpolate $i / $j.
 */
class NestedIndexedCollisionTest extends BuilderTestBase {
	@Test
	public function testBuilder_NestedRecurringNamedIndex_Throws():Void {
		final src = "#x programmable() {
			repeatable($i, step(2, dy: 20)) {
				repeatable($j, step(2, dx: 10)) {
					#tile[$j] bitmap(generated(color(4, 4, #ff0000))): 0, 0
				}
			}
		}";
		var thrown:Null<String> = null;
		try {
			BuilderTestBase.buildFromSource(src, "x", null);
		} catch (e:Dynamic) {
			thrown = Std.string(e);
		}
		Assert.notNull(thrown,
			"nested loops producing a recurring indexed name (#tile[$j]) must be rejected at build time, not silently collapsed to the first iteration");
	}

	@Test
	public function testBuilder_NestedRecurringSlotIndex_Throws():Void {
		final src = "#x programmable() {
			repeatable($i, step(2, dy: 20)) {
				repeatable($j, step(2, dx: 10)) {
					#cell[$j] slot: 0, 0
				}
			}
		}";
		var thrown:Null<String> = null;
		try {
			BuilderTestBase.buildFromSource(src, "x", null);
		} catch (e:Dynamic) {
			thrown = Std.string(e);
		}
		Assert.notNull(thrown,
			"nested loops producing a recurring indexed slot (#cell[$j]) must be rejected at build time, not silently coexist");
	}

	// Control: a unique single-loop indexed name must still build cleanly (no over-rejection).
	@Test
	public function testBuilder_SingleLoopUniqueIndex_BuildsCleanly():Void {
		final src = "#x programmable() {
			repeatable($i, step(3, dx: 10)) {
				#tile[$i] bitmap(generated(color(4, 4, #00ff00))): 0, 0
			}
		}";
		var thrown:Null<String> = null;
		var result = null;
		try {
			result = BuilderTestBase.buildFromSource(src, "x", null);
		} catch (e:Dynamic) {
			thrown = Std.string(e);
		}
		Assert.isNull(thrown, 'unique indexed names (#tile[$$i] in a single loop) must build without error; threw: $thrown');
		if (result != null) {
			Assert.equals(3, BuilderTestBase.findVisibleBitmapDescendants(result.object).length,
				"single-loop #tile[$i] over step(3) yields 3 elements");
		}
	}
}
