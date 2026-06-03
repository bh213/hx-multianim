package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Codegen instances must expose hasSlot / hasDynamicRef as the existence companions to
 * the generated getSlot / getDynamicRef, matching BuilderResult (MultiAnimBuilder.hx).
 *
 * The documented "guard before access" pattern (hasSlot before getSlot for indexed slots
 * whose iteration count can shrink) only holds if both methods exist on the builder AND
 * the codegen path. ProgrammableCodeGen generates getSlot/getDynamicRef but neither
 * existence check, so typed user code calling instance.hasSlot(...) fails to compile; via
 * a Dynamic instance the same gap surfaces as a missing-field runtime failure. Both stem
 * from the methods never being generated.
 *
 * Fixture: test/examples/127-codegenHasSlotDynRef/codegenHasSlotDynRef.manim
 */
class CodegenHasSlotDynRefTest extends BuilderTestBase {
	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	/** hasSlot on a codegen instance: present named/indexed slots report true; kind and
	 *  index mismatches return false instead of throwing — exactly like BuilderResult.hasSlot. */
	@Test
	public function testCodegenHasSlotReportsPresentAndAbsentSlots():Void {
		final inst:Dynamic = createMp().codegenHasSlotDynRef.create();
		// Always pass all three args so the Dynamic call matches the generated arity.
		function has(name:String, ?index:Null<Int>, ?indexY:Null<Int>):Bool
			return inst.hasSlot(name, index, indexY);

		// Named slots present.
		Assert.isTrue(has("footer"), "hasSlot('footer') must be true on a codegen instance");
		Assert.isTrue(has("extra"), "hasSlot('extra') must be true on a codegen instance");

		// Indexed slot entries present / absent by index — never throws.
		Assert.isTrue(has("item", 0), "hasSlot('item', 0) must be true");
		Assert.isTrue(has("item", 2), "hasSlot('item', 2) must be true");
		Assert.isFalse(has("item", 99), "hasSlot('item', 99) must be false (not throw) — index out of range");

		// Kind mismatches return false, never throw.
		Assert.isFalse(has("item"), "hasSlot('item') without index must be false for an indexed slot");
		Assert.isFalse(has("footer", 0), "hasSlot('footer', 0) must be false — 'footer' is not indexed");
		Assert.isFalse(has("missing"), "hasSlot('missing') must be false (not throw) for an unknown name");
	}

	/** hasDynamicRef on a codegen instance must agree with getDynamicRef for the same key:
	 *  true exactly where getDynamicRef resolves, false (never throwing) where it returns null.
	 *  Keyed by the unnamed dynamicRef's target programmable name ("leaf"), matching the
	 *  codegen dispatcher. Mirrors BuilderResult.hasDynamicRef. */
	@Test
	public function testCodegenHasDynamicRefReportsPresentAndAbsentRefs():Void {
		final inst:Dynamic = createMp().codegenHasSlotDynRef.create();
		function hasRef(name:String):Bool return inst.hasDynamicRef(name);
		function getRef(name:String):Dynamic return inst.getDynamicRef(name);

		Assert.notNull(getRef("leaf"), "precondition: getDynamicRef('leaf') resolves on a codegen instance");
		Assert.isTrue(hasRef("leaf"), "hasDynamicRef('leaf') must be true where getDynamicRef resolves it");

		Assert.isNull(getRef("missing"), "precondition: getDynamicRef('missing') is null on a codegen instance");
		Assert.isFalse(hasRef("missing"), "hasDynamicRef('missing') must be false (not throw) for an unknown name");
	}
}
