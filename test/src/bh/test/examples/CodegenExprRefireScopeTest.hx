package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;
import bh.multianim.MultiAnimBuilder.CallbackRequest;
import bh.multianim.MultiAnimBuilder.CallbackResult;

/**
 * Expression-update scoping and numeric callback contracts.
 *
 * - The generated _updateExpressions() is one monolithic method: any
 *   setParameter whose param is referenced by SOME expression re-runs ALL
 *   expression updates — re-invoking game callbacks (and restarting
 *   stateanims, re-allocating filters) that don't reference the changed
 *   param. The builder gates tracked expressions per changed-param set.
 *
 * - A callback returning CBRFloat in a position coordinate: positions are a
 *   FLOAT context in the builder (resolveAsNumber), which accepts CBRFloat
 *   and uses the value (x = 12.5). The ProgrammableBuilder has no float
 *   resolver at all — every numeric callback routes through
 *   resolveCallbackWithIndexInt, whose `default:` arm silently discards
 *   CBRFloat and substitutes the declared default (x = 5). The same shim also
 *   breaks true int contexts (builder throws there; PB silently defaults).
 *
 * Companion fixture: test/examples/144-codegenExprRefire/exprRefire.manim
 */
class CodegenExprRefireScopeTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/144-codegenExprRefire/exprRefire.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	/** Install a callback on the factory's underlying MultiAnimBuilder (the
	 *  generated instance resolves callbacks through it via _pb). */
	static function installCallback(factory:Dynamic, cb:CallbackRequest -> CallbackResult):Void {
		final builder:bh.multianim.MultiAnimBuilder = @:privateAccess cast factory._builder;
		Assert.notNull(builder, "factory should have a builder after create()");
		@:privateAccess {
			builder.builderParams = {callback: cb};
		}
	}

	// ==================== unrelated setParameter must not re-invoke callbacks ====================

	/** Builder baseline: only expressions referencing the changed param re-fire. */
	@Test
	public function testExprRefire_Builder_UnrelatedParamDoesNotReinvoke():Void {
		var invocations = 0;
		final builder = BuilderTestBase.builderFromFile(FIXTURE);
		final bp:Dynamic = {
			callback: (request:CallbackRequest) -> {
				return switch request {
					case NameWithIndex(name, _) if (name == "label"):
						invocations++;
						CBRString("lbl");
					default:
						CBRNoResult;
				};
			},
		};
		final result = builder.buildWithParameters("exprRefire", new Map(), bp, null, true);
		final base = invocations;
		Assert.isTrue(base >= 1, "builder: the callback resolves at least once during the initial build");
		result.setParameter("y", 5);
		Assert.equals(base, invocations,
			"builder: changing y (referenced only by the other bitmap) must not re-invoke the label callback");
		result.setParameter("idx", 1);
		Assert.equals(base + 1, invocations,
			"builder control: changing idx re-resolves the callback-driven text once");
	}

	/** Codegen: same scoping — an unrelated param change must not re-invoke. */
	@Test
	public function testExprRefire_Codegen_UnrelatedParamDoesNotReinvoke():Void {
		final mp = createMp();
		final inst:Dynamic = mp.exprRefire.create();
		var invocations = 0;
		installCallback(mp.exprRefire, (request:CallbackRequest) -> {
			return switch request {
				case NameWithIndex(name, _) if (name == "label"):
					invocations++;
					CBRString("lbl");
				default:
					CBRNoResult;
			};
		});
		inst.setParameter("idx", 1);
		Assert.equals(1, invocations,
			"codegen control: changing idx re-resolves the callback-driven text once");
		inst.setParameter("y", 5);
		Assert.equals(1, invocations,
			"codegen: changing y (referenced only by the other bitmap's position) must not re-invoke the label callback");
	}

	// ==================== CBRFloat in a numeric context ====================

	static function singleBitmapX(root:h2d.Object):Float {
		final bitmaps = BuilderTestBase.findVisibleBitmapDescendants(root);
		Assert.equals(1, bitmaps.length, "expected exactly one callback-positioned bitmap");
		if (bitmaps.length != 1)
			return Math.NaN;
		var x = 0.0;
		var o:h2d.Object = bitmaps[0];
		while (o != null && o != root) {
			x += o.x;
			o = o.parent;
		}
		return x;
	}

	/** Builder baseline: CBRFloat in a float position context is USED (x=12.5). */
	@Test
	public function testCbFloat_Builder_UsesFloatResult():Void {
		final builder = BuilderTestBase.builderFromFile(FIXTURE);
		final bp:Dynamic = {
			callback: (request:CallbackRequest) -> CBRFloat(12.5),
		};
		final result = builder.buildWithParameters("cbFloat", new Map(), bp, null, false);
		Assert.floatEquals(12.5, singleBitmapX(result.object),
			"builder: a CBRFloat callback result positions the bitmap at 12.5");
	}

	/** Codegen: the same CBRFloat result must be used, not silently discarded
	 *  in favor of the declared default. */
	@Test
	public function testCbFloat_Codegen_UsesFloatResult():Void {
		final mp = createMp();
		final inst:Dynamic = mp.cbFloat.create();
		installCallback(mp.cbFloat, (request:CallbackRequest) -> CBRFloat(12.5));
		inst.setParameter("k", 1); // re-resolve the callback with the installed handler
		Assert.floatEquals(12.5, singleBitmapX(cast inst),
			"codegen: a CBRFloat callback result must position the bitmap at 12.5 (builder parity) — "
			+ "resolveCallbackWithIndexInt currently discards it and substitutes the default (5)");
	}
}
