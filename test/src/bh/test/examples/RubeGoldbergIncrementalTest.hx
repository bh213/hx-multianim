package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.test.BuilderTestBase.BuildMode;
import bh.test.BuilderTestBase.buildFromFile;
import bh.test.BuilderTestBase.buildFromSource;
import bh.multianim.MultiAnimBuilder;

/**
 * Test 107 companion — exercises the Rube Goldberg programmable's incremental,
 * codegen, slot, dynamic-ref, and strict-D color behavior.
 *
 * Compiles under both standard and `-D MULTIANIM_DEV` test configs. DEV-only
 * phases (hot reload registry) are body-gated, not class-gated.
 */
class RubeGoldbergIncrementalTest extends BuilderTestBase {
	static inline var MANIM_PATH = "test/examples/107-rubeGoldberg/rubeGoldberg.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	// ==================== Phase A — cold build ====================

	@Test
	public function test107_A_coldBuildBuilder():Void {
		final result = buildFromFile(MANIM_PATH, "rubeGoldberg", null, Incremental);
		Assert.notNull(result, "builder result should not be null");
		Assert.notNull(result.object, "builder root object should not be null");
		Assert.isTrue(result.object.numChildren > 0, "root should have children");
		Assert.isTrue(result.isIncremental, "should be in incremental mode");
	}

	@Test
	public function test107_A_coldBuildMacro():Void {
		final mp = createMp();
		final inst:Dynamic = mp.rubeGoldberg.create();
		Assert.notNull(inst, "codegen instance should not be null");
		Assert.isTrue((inst : h2d.Object).numChildren > 0, "codegen root should have children");
	}

	// ==================== Phase B — setParameter round-trip (consolidated) ====================

	// Build once, exercise every parameter type sequentially on the same instance.
	// This mirrors real usage and avoids building the same .manim 10+ times in parallel tests.
	@Test
	public function test107_B_setParameterRoundTrip():Void {
		final result = buildFromFile(MANIM_PATH, "rubeGoldberg", null, Incremental);

		// Enum (string) param
		result.setParameter("mode", "idle");
		result.setParameter("mode", "danger");
		result.setParameter("mode", "hover");
		Assert.isTrue(result.object.numChildren > 0, "after mode cycle");

		// uint param — drives a repeatable's iteration count
		result.setParameter("count", 2);
		result.setParameter("count", 3);
		Assert.isTrue(result.object.numChildren > 0, "after count cycle");

		// int param — referenced by @(temperature >= 30) conditional
		result.setParameter("temperature", 10);
		result.setParameter("temperature", 42);
		Assert.isTrue(result.object.numChildren > 0, "after temperature cycle");

		// float param
		result.setParameter("zoom", 0.5);
		result.setParameter("zoom", 1.0);
		Assert.isTrue(result.object.numChildren > 0, "after zoom cycle");

		// bool param — referenced by @(enabled => true) / @any / @all
		result.setParameter("enabled", false);
		result.setParameter("enabled", true);
		Assert.isTrue(result.object.numChildren > 0, "after enabled cycle");

		// string param
		result.setParameter("label", "NEW");
		result.setParameter("label", "GO");
		Assert.isTrue(result.object.numChildren > 0, "after label cycle");

		// color param — full strict-D value coverage
		result.setParameter("accent", 0xFFFF0000); // opaque red (8-digit AARRGGBB)
		result.setParameter("accent", 0x80FF8800); // semi-transparent
		result.setParameter("accent", 0x00000000); // fully transparent (not clobbered under strict-D)
		result.setParameter("accent", 0xFF0000);    // native short (top byte = 0)
		result.setParameter("accent", 0xFFFF8800); // back to default
		Assert.isTrue(result.object.numChildren > 0, "after accent color cycle");

		// range param — referenced by @(level => 3..7)
		result.setParameter("level", 1);
		result.setParameter("level", 10);
		result.setParameter("level", 5);
		Assert.isTrue(result.object.numChildren > 0, "after level range cycle");

		// flags param — referenced by @(flags => bit[0])
		result.setParameter("flags", 0);
		result.setParameter("flags", 15);
		result.setParameter("flags", 3);
		Assert.isTrue(result.object.numChildren > 0, "after flags cycle");

		// enum param used as dynamicRef template
		result.setParameter("template", "rgCardA");
		result.setParameter("template", "rgCardC");
		result.setParameter("template", "rgCardB");
		Assert.isTrue(result.object.numChildren > 0, "after template cycle");
	}

	// ==================== Phase C — batch updates ====================

	@Test
	public function test107_C_batchUpdateEmitsSingleRebuild():Void {
		final result = buildFromFile(MANIM_PATH, "rubeGoldberg", null, Incremental);

		var rebuilds = 0;
		result.addRebuildListener(() -> rebuilds++);

		result.beginUpdate();
		result.setParameter("mode", "active");
		result.setParameter("count", 4);
		result.setParameter("label", "BATCH");
		result.setParameter("accent", 0xFF00FF00);
		result.endUpdate();

		Assert.equals(1, rebuilds, "batched update should emit exactly one rebuild listener fire");
	}

	// ==================== Phase D — slots ====================

	@Test
	public function test107_D_plainSlotLifecycle():Void {
		final result = buildFromFile(MANIM_PATH, "rubeGoldberg", null, Incremental);

		final slot = result.getSlot("mainSlot");
		Assert.notNull(slot, "mainSlot should be reachable");
		Assert.isTrue(slot.isEmpty(), "mainSlot starts empty");
		Assert.isFalse(slot.isOccupied(), "isOccupied is inverse of isEmpty");

		final payload = new h2d.Object();
		slot.setContent(payload);
		Assert.isTrue(slot.isOccupied(), "after setContent, slot is occupied");
		Assert.equals(payload, slot.getContent(), "getContent returns set content");

		slot.clear();
		Assert.isTrue(slot.isEmpty(), "after clear, slot is empty again");
	}

	@Test
	public function test107_D_indexedSlotsReachable():Void {
		final result = buildFromFile(MANIM_PATH, "rubeGoldberg", null, Incremental);
		for (i in 0...3) {
			final slot = result.getSlot("row", i);
			Assert.notNull(slot, 'row[$i] should be reachable');
			Assert.isTrue(slot.isEmpty(), 'row[$i] starts empty');
		}
	}

	// ==================== Phase E — fresh build reset ====================

	@Test
	public function test107_E_freshBuildInvariants():Void {
		final first = buildFromFile(MANIM_PATH, "rubeGoldberg", null, Incremental);
		final firstChildren = first.object.numChildren;
		final second = buildFromFile(MANIM_PATH, "rubeGoldberg", null, Incremental);
		Assert.equals(firstChildren, second.object.numChildren, "fresh build produces same child count");
		Assert.notNull(second.getSlot("mainSlot"), "fresh build has slots");
		Assert.notNull(second.getSlot("row", 0), "fresh build has indexed slots");
	}

	// ==================== Phase F — codegen API parity ====================

	@Test
	public function test107_F_codegenSettersExist():Void {
		final mp = createMp();
		final inst:Dynamic = mp.rubeGoldberg.create();
		Assert.isTrue(Reflect.isFunction(inst.setMode), "setMode exists");
		Assert.isTrue(Reflect.isFunction(inst.setCount), "setCount exists");
		Assert.isTrue(Reflect.isFunction(inst.setTemperature), "setTemperature exists");
		Assert.isTrue(Reflect.isFunction(inst.setZoom), "setZoom exists");
		Assert.isTrue(Reflect.isFunction(inst.setEnabled), "setEnabled exists");
		Assert.isTrue(Reflect.isFunction(inst.setLabel), "setLabel exists");
		Assert.isTrue(Reflect.isFunction(inst.setAccent), "setAccent exists");
		Assert.isTrue(Reflect.isFunction(inst.setLevel), "setLevel exists");
		Assert.isTrue(Reflect.isFunction(inst.setFlags), "setFlags exists");
		Assert.isTrue(Reflect.isFunction(inst.setTemplate), "setTemplate exists");
	}

	@Test
	public function test107_F_codegenTypedSettersRoundTrip():Void {
		final mp = createMp();
		final inst:Dynamic = mp.rubeGoldberg.create();
		inst.setCount(5);
		inst.setTemperature(10);
		inst.setZoom(0.75);
		inst.setEnabled(false);
		inst.setLabel("NEW");
		inst.setAccent(0xFFFF0000);
		inst.setLevel(7);
		inst.setFlags(7);
		Assert.isTrue((inst : h2d.Object).numChildren > 0, "root survives codegen setter cycle");
	}

	@Test
	public function test107_F_codegenSlotReachable():Void {
		final mp = createMp();
		final inst:Dynamic = mp.rubeGoldberg.create();
		final mainSlot:Null<bh.multianim.MultiAnimBuilder.SlotHandle> = inst.getSlot("mainSlot", null, null);
		Assert.notNull(mainSlot, "mainSlot reachable via codegen getSlot");
		Assert.isTrue(mainSlot.isEmpty(), "codegen slot starts empty");
	}

	@Test
	public function test107_F_codegenIndexedSlotByIndex():Void {
		final mp = createMp();
		final inst:Dynamic = mp.rubeGoldberg.create();
		final row0:Null<bh.multianim.MultiAnimBuilder.SlotHandle> = inst.getSlot("row", 0, null);
		Assert.notNull(row0, "row[0] reachable via codegen getSlot");
	}

	// ==================== Phase G — data block ====================

	@Test
	public function test107_G_dataBlockFields():Void {
		final mp = createMp();
		final info:Dynamic = mp.rgInfo;
		Assert.notNull(info, "rgInfo data block should be accessible");
		Assert.equals(100, info.hp, "hp field matches");
		Assert.equals(1.5, info.speed, "speed field matches");
		Assert.equals("GO", info.title, "title field matches");
	}

	// ==================== Phase H — import resolution ====================

	@Test
	public function test107_H_importedProgrammableBuilds():Void {
		final result = buildFromFile("test/examples/107-rubeGoldberg/imported.manim", "extWidget", null, Builder);
		Assert.notNull(result, "imported programmable builds directly");
		Assert.isTrue(result.object.numChildren > 0, "imported programmable has content");
	}

	// ==================== Phase I — curves registered ====================

	@Test
	public function test107_I_curvesRegistered():Void {
		final builder = bh.test.BuilderTestBase.builderFromFile(MANIM_PATH);
		Assert.notNull(builder.getCurve("easeRising"), "easeRising curve");
		Assert.notNull(builder.getCurve("threePoint"), "threePoint curve");
		Assert.notNull(builder.getCurve("piecewise"), "piecewise curve");
		Assert.notNull(builder.getCurve("multiplied"), "multiplied curve");
		Assert.notNull(builder.getCurve("applied"), "applied curve");
		Assert.notNull(builder.getCurve("inverted"), "inverted curve");
		Assert.notNull(builder.getCurve("scaled"), "scaled curve");
	}

	// ==================== Phase J — @final constants persist across rebuilds ====================

	// Regression guard for MultiAnimBuilder fix: @final constants at programmable-body scope
	// must survive incremental rebuilds. Previously, the IncrementalUpdateContext deep-copied
	// indexedParams at construction (before build processed @final nodes), so setParameter
	// threw "reference RGB3 does not exist" on rebuild. Fix: syncFinalsFromBuilder() copies
	// surviving @final entries into the context after initial build.
	@Test
	public function test107_J_finalConstantsSurviveRebuild():Void {
		final result = buildFromFile(MANIM_PATH, "rubeGoldberg", null, Incremental);
		// Changing any param triggers re-evaluation of elements referencing @final constants.
		// If the fix regresses, this throws "reference RGB3 does not exist" (or similar).
		result.setParameter("mode", "idle");
		result.setParameter("mode", "hover");
		Assert.isTrue(result.object.numChildren > 0, "@final refs resolved after rebuild");
	}

	// ==================== Phase K-pre — multi-@switch regression ====================

	// Regression guard: a second @switch on a different param (or even the same param)
	// in the same programmable body must build without an Access Violation.

	@Test
	public function test107_K_twoSwitchesWithBlockArmBug():Void {
		// Focused repro of the rubeGoldberg crash: first @switch has a BLOCK arm
		// (multi-element), second @switch on a DIFFERENT enum param crashes the builder.
		// Before the fix this threw "Access violation" during build.
		final result = buildFromSource("
			#blockArmBug programmable(mode:[idle,hover,danger]=hover, tmpl:[a,b,c]=b) {
				@switch(mode) {
					idle: bitmap(generated(color(60, 20, #666666))): 0, 0;
					hover: bitmap(generated(color(60, 20, #ff8800))): 0, 0;
					danger {
						bitmap(generated(color(60, 20, #ff0000))): 0, 0
						text(f3x5, \"!!\", #ffffff): 25, 7
					}
					default: bitmap(generated(color(60, 20, #444444))): 0, 0;
				}
				@switch(tmpl) {
					a: text(f3x5, \"A\", #88ffff): 0, 30;
					b: text(f3x5, \"B\", #ffffff): 0, 30;
					c: text(f3x5, \"C\", #ff88ff): 0, 30;
				}
			}
		", "blockArmBug");
		Assert.notNull(result, "block-arm switch + second switch on different param must build");
		Assert.isTrue(result.object.numChildren > 0, "result has children");
	}

	@Test
	public function test107_K_twoSwitchesOnDifferentParams():Void {
		final result = buildFromSource("
			#twoSw programmable(a:[x,y]=x, b:[p,q]=p) {
				@switch(a) {
					x: text(f3x5, \"X\", #ffffff): 0, 0;
					y: text(f3x5, \"Y\", #ffffff): 0, 0;
				}
				@switch(b) {
					p: text(f3x5, \"P\", #ffffff): 0, 20;
					q: text(f3x5, \"Q\", #ffffff): 0, 20;
				}
			}
		", "twoSw");
		Assert.notNull(result, "two @switch blocks on different params must build");
		Assert.isTrue(result.object.numChildren > 0, "result has children");
	}

	@Test
	public function test107_K_switchOnIntWithRangeAfterFirstSwitch():Void {
		// Originally reported: a second @switch on an int param with range/comparison
		// arms, following a first @switch on an enum param, crashed with Access Violation.
		final result = buildFromSource("
			#intRangeSw programmable(mode:[idle,active]=idle, temp:int=20) {
				@switch(mode) {
					idle: text(f3x5, \"I\", #ffffff): 0, 0;
					active: text(f3x5, \"A\", #ffffff): 0, 0;
				}
				@switch(temp) {
					<= 0:     text(f3x5, \"cold\", #4488ff): 0, 20;
					1..50:    text(f3x5, \"mid\",  #44ff88): 0, 20;
					default:  text(f3x5, \"hot\",  #ff4444): 0, 20;
				}
			}
		", "intRangeSw");
		Assert.notNull(result, "enum @switch then int-range @switch must build");
		Assert.isTrue(result.object.numChildren > 0, "result has children");
	}

	@Test
	public function test107_K_switchOnDynamicRefTemplateParam():Void {
		// The 'template' enum param is also the target of dynamicRef — using it inside
		// @switch in the same programmable may expose a conflict in how the param is tracked.
		final result = buildFromSource("
			#cardA programmable(tint:color=#ffffff) { bitmap(generated(color(10, 10, $tint))): 0, 0 }
			#cardB programmable(tint:color=#ffffff) { bitmap(generated(color(20, 20, $tint))): 0, 0 }
			#templateSw programmable(template:[cardA,cardB]=cardA, accent:color=#ff8800) {
				dynamicRef($template, tint => $accent): 0, 0
				@switch(template) {
					cardA: text(f3x5, \"A\", #ffffff): 0, 30;
					cardB: text(f3x5, \"B\", #ffffff): 0, 30;
				}
			}
		", "templateSw");
		Assert.notNull(result, "dynamicRef + @switch on same enum param must build");
		Assert.isTrue(result.object.numChildren > 0, "result has children");
	}

	@Test
	public function test107_K_twoSwitchesSameParam():Void {
		// Matches the documented pattern in test 100-switchDemo — two @switch on same
		// enum param producing two layered elements.
		final result = buildFromSource("
			#twoSwSame programmable(state:[idle,active]=idle) {
				@switch(state) {
					idle: text(f3x5, \"I1\", #ffffff): 0, 0;
					active: text(f3x5, \"A1\", #ffffff): 0, 0;
				}
				@switch(state) {
					idle: text(f3x5, \"I2\", #ffffff): 0, 20;
					active: text(f3x5, \"A2\", #ffffff): 0, 20;
				}
			}
		", "twoSwSame");
		Assert.notNull(result, "two @switch on same param must build");
		Assert.isTrue(result.object.numChildren > 0, "result has children");
	}

	// ==================== Phase L — hot reload (DEV only) ====================

	#if MULTIANIM_DEV
	@Test
	public function test107_K_devReloadableRegistry():Void {
		final result = buildFromFile(MANIM_PATH, "rubeGoldberg", null, Incremental);
		final registry = new bh.multianim.dev.HotReload.ReloadableRegistry();
		final handle = registry.register(MANIM_PATH, result, "rubeGoldberg");
		Assert.notNull(handle, "registry returns a handle");
		Assert.isTrue(registry.hasAnyFor(MANIM_PATH), "registry tracks path after register");
		Assert.equals(1, registry.getHandles(MANIM_PATH).length, "one handle tracked");
		registry.unregister(handle);
		Assert.isFalse(registry.hasAnyFor(MANIM_PATH), "registry clears after unregister");
	}
	#end
}
