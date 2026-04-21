package bh.test.examples;

import utest.Assert;
import bh.test.BuilderTestBase;

/**
 * Regression — INTERACTIVE(w, h, ...) size and STATEANIM(filename, initialState, ...)
 * initialState must re-apply when a referenced $param changes.
 *
 * Scope:
 *   - INTERACTIVE: width + height only. id/metadata remain frozen at construction.
 *   - STATEANIM:   initialState only (drives AnimationSM.play). Selectors remain frozen.
 *
 * Companion fixture: test/examples/111-codegenIncrementalInteractiveStateanim/codegenIncrementalInteractiveStateanim.manim
 */
class CodegenIncrementalInteractiveStateanimTest extends BuilderTestBase {
	static inline var FIXTURE = "test/examples/111-codegenIncrementalInteractiveStateanim/codegenIncrementalInteractiveStateanim.manim";

	function createMp():bh.test.MultiProgrammable {
		return new bh.test.MultiProgrammable(TestResourceLoader.createLoader(false));
	}

	static function findMAObject(obj:h2d.Object):Null<bh.base.MAObject> {
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, bh.base.MAObject))
				return cast child;
			final found = findMAObject(child);
			if (found != null)
				return found;
		}
		return null;
	}

	static function findAnimationSM(obj:h2d.Object):Null<bh.stateanim.AnimationSM> {
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, bh.stateanim.AnimationSM))
				return cast child;
			final found = findAnimationSM(child);
			if (found != null)
				return found;
		}
		return null;
	}

	static function extractInteractiveSize(o:bh.base.MAObject):{w:Int, h:Int} {
		switch o.multiAnimType {
			case MAInteractive(w, h, _, _): return {w: w, h: h};
			default: throw "expected MAInteractive";
		}
	}

	// ==================== INTERACTIVE ====================

	@Test
	public function testInteractive_Builder_SizeUpdate():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "codegenIncInteractive", null, Incremental);
		final o = findMAObject(result.object);
		Assert.notNull(o, "Should find MAObject");
		var size = extractInteractiveSize(o);
		Assert.equals(100, size.w, "Initial w=100");
		Assert.equals(50, size.h, "Initial h=50");

		result.setParameter("w", 250);
		size = extractInteractiveSize(o);
		Assert.equals(250, size.w, "w after setParameter(w, 250)");
		Assert.equals(50, size.h, "h unchanged");

		result.setParameter("h", 80);
		size = extractInteractiveSize(o);
		Assert.equals(250, size.w, "w still 250");
		Assert.equals(80, size.h, "h after setParameter(h, 80)");
	}

	@Test
	public function testInteractive_Codegen_SizeUpdate():Void {
		final mp = createMp();
		final inst:Dynamic = mp.codegenIncInteractive.create();
		final obj:h2d.Object = cast inst;

		final o = findMAObject(obj);
		Assert.notNull(o, "Should find MAObject");
		var size = extractInteractiveSize(o);
		Assert.equals(100, size.w, "Initial w=100");
		Assert.equals(50, size.h, "Initial h=50");

		inst.setW(250);
		size = extractInteractiveSize(o);
		Assert.equals(250, size.w, "w after setW(250)");
		Assert.equals(50, size.h, "h unchanged");

		inst.setH(80);
		size = extractInteractiveSize(o);
		Assert.equals(250, size.w, "w still 250");
		Assert.equals(80, size.h, "h after setH(80)");
	}

	// ==================== STATEANIM ====================

	@Test
	public function testStateanim_Builder_InitialStateUpdate():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "codegenIncStateanim", null, Incremental);
		final sm = findAnimationSM(result.object);
		Assert.notNull(sm, "Should find AnimationSM child");
		Assert.equals("idle", sm.getCurrentAnimName(), "Initial animation = idle");

		result.setParameter("initial", "fire-up");
		Assert.equals("fire-up", sm.getCurrentAnimName(), "After setParameter(initial, fire-up)");

		result.setParameter("initial", "idle");
		Assert.equals("idle", sm.getCurrentAnimName(), "Back to idle");
	}

	@Test
	public function testStateanim_Codegen_InitialStateUpdate():Void {
		final mp = createMp();
		final inst:Dynamic = mp.codegenIncStateanim.create();
		final obj:h2d.Object = cast inst;

		final sm = findAnimationSM(obj);
		Assert.notNull(sm, "Should find AnimationSM child");
		Assert.equals("idle", sm.getCurrentAnimName(), "Initial animation = idle");

		inst.setInitial("fire-up");
		Assert.equals("fire-up", sm.getCurrentAnimName(), "After setInitial(fire-up)");

		inst.setInitial("idle");
		Assert.equals("idle", sm.getCurrentAnimName(), "Back to idle");
	}

	// ==================== Untracked-ref rejection ====================
	// Params referenced only in untracked slots (interactive id/metadata, stateanim selectors)
	// are silently frozen at construction. To prevent footgun where setParameter succeeds in
	// updating the field but has no visual effect, both setter and setParameter must throw.
	//
	// Assert exact shape of the error so regressions (e.g. generic "unknown parameter" throws
	// from a miswired check) don't masquerade as pass.

	/** Captures the caught value as a String for substring asserts. BuilderError toString()
	 *  returns its message; codegen throws a raw String literal — both work with Std.string(). */
	static function runAndCatch(fn:() -> Void):Null<String> {
		try { fn(); return null; }
		catch (e:Dynamic) return Std.string(e);
	}

	static function assertUntrackedReject(msg:Null<String>, paramName:String, reasonFragment:String, label:String):Void {
		Assert.notNull(msg, '$label: expected throw, none raised');
		if (msg == null) return;
		Assert.isTrue(msg.indexOf('setParameter("' + paramName + '", ...) rejected') >= 0,
			'$label: message must name rejected param — got: $msg');
		Assert.isTrue(msg.indexOf(reasonFragment) >= 0,
			'$label: message must mention slot reason "' + reasonFragment + '" — got: $msg');
	}

	@Test
	public function testUntrackedId_Builder_Throws():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "codegenIncUntrackedId", null, Incremental);
		final msg = runAndCatch(() -> result.setParameter("myId", "other"));
		assertUntrackedReject(msg, "myId", "interactive id", "builder id");

		// Builder additionally surfaces a structured BuilderError with code="untracked_param".
		var err:Null<bh.multianim.BuilderError> = null;
		try { result.setParameter("myId", "another"); }
		catch (e:Dynamic) {
			if (Std.isOfType(e, bh.multianim.BuilderError)) err = cast e;
		}
		Assert.notNull(err, "builder throw must be a BuilderError");
		if (err != null) Assert.equals("untracked_param", err.code, "BuilderError.code");
	}

	@Test
	public function testUntrackedId_Codegen_Throws():Void {
		final mp = createMp();
		final inst:Dynamic = mp.codegenIncUntrackedId.create();
		assertUntrackedReject(runAndCatch(() -> inst.setMyId("other")),
			"myId", "interactive id", "codegen typed setter");
		assertUntrackedReject(runAndCatch(() -> inst.setParameter("myId", "another")),
			"myId", "interactive id", "codegen setParameter dispatcher");
	}

	@Test
	public function testUntrackedMetadata_Builder_Throws():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "codegenIncUntrackedMeta", null, Incremental);
		assertUntrackedReject(runAndCatch(() -> result.setParameter("price", 250)),
			"price", "interactive metadata value", "builder metadata");
	}

	@Test
	public function testUntrackedMetadata_Codegen_Throws():Void {
		final mp = createMp();
		final inst:Dynamic = mp.codegenIncUntrackedMeta.create();
		assertUntrackedReject(runAndCatch(() -> inst.setPrice(250)),
			"price", "interactive metadata value", "codegen metadata");
	}

	@Test
	public function testUntrackedSelector_Builder_Throws():Void {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "codegenIncUntrackedSelector", null, Incremental);
		assertUntrackedReject(runAndCatch(() -> result.setParameter("dir", "r")),
			"dir", "stateanim selector \"direction\"", "builder selector");
	}

	@Test
	public function testUntrackedSelector_Codegen_Throws():Void {
		final mp = createMp();
		final inst:Dynamic = mp.codegenIncUntrackedSelector.create();
		assertUntrackedReject(runAndCatch(() -> inst.setDir("r")),
			"dir", "stateanim selector \"direction\"", "codegen selector");
	}

	// ==================== Metadata type compat (parse-time validation) ====================
	// Typed :int / :float / :color / :bool / :string metadata on an interactive(...) element
	// must reject param refs whose declared param type would cause runtime vs codegen to
	// diverge. The existing behavior was: runtime resolveAs*() leniently coerces across
	// Value/ValueF/StringValue/Index/Flag; codegen emits raw `RSV<Type>(this._p)` based on
	// the metadata's declared type, which either (a) compile-errors on non-int params used
	// in :int meta, or (b) silently returns the enum index / flag bits while runtime throws.
	// Parser now rejects mismatches so both paths fail at parse time with the same error.
	//
	// Compatibility policy (implemented in MacroManimParser.validateMetadataTypeCompat):
	//   :int / :color → param must be int-backed (int, uint, range, color, bool, hex/grid dir)
	//   :float        → param must be numeric (float, int, uint, range, color, bool, dir)
	//   :bool         → param must be bool, int, uint, range, or direction
	//   :string       → param must stringify without runtime default-throw (rejects flags, array, tile)

	@Test
	public function testInteractiveMetadata_TypedIntFromEnum_RejectedAtParseTime():Void {
		final err = BuilderTestBase.parseExpectingError(
			"#p programmable(status:[a,b,c]=b) {
			  interactive(100, 50, \"btn\", statusIdx:int => $status): 0, 0
			}"
		);
		Assert.notNull(err, "expected parse error for enum → :int metadata");
		if (err != null) {
			Assert.isTrue(err.indexOf("statusIdx") >= 0 || err.indexOf("status") >= 0,
				'error should name the key or param — got: $err');
			Assert.isTrue(err.indexOf("enum") >= 0 || err.indexOf(":int") >= 0,
				'error should mention the incompatible types — got: $err');
		}
	}

	@Test
	public function testInteractiveMetadata_TypedIntFromInt_StillParses():Void {
		// Regression guard: int → :int is the matching case and must continue to parse.
		final ok = BuilderTestBase.parseExpectingSuccess(
			"#p programmable(price:int=10) {
			  interactive(100, 50, \"btn\", price:int => $price): 0, 0
			}"
		);
		Assert.isTrue(ok, "int param with :int typed metadata must still parse");
	}
}
