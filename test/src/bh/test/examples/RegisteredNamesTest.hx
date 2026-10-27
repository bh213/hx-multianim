package bh.test.examples;

import utest.Assert;
import bh.audio.Audio;
import bh.audio.LogBackend;
import bh.base.CursorManager;
import bh.base.FontManager;
import bh.multianim.BuilderError;
import bh.multianim.MultiAnimBuilder;

/**
 * Names registered for the whole game (cursors, fonts, sound banks, music blocks) follow one rule:
 * a file that registers a name again replaces what it registered (a reload); code, or another
 * file, registering a name already taken is an error naming both. A built-in cursor may be
 * replaced; a font can be unregistered.
 */
class RegisteredNamesTest extends utest.Test {
	/** A builder of `source` read from the file `path`. */
	static function fileBuilder(path:String, source:String):MultiAnimBuilder {
		return MultiAnimBuilder.load(byte.ByteData.ofString('version: 1.0\n$source'), TestResourceLoader.createLoader(false), path);
	}

	static function errorOf(fn:() -> Void):Null<String> {
		try {
			fn();
		} catch (e:BuilderError) {
			return e.message;
		} catch (e:Dynamic) {
			return Std.string(e);
		}
		return null;
	}

	static final CURSORS = '#c cursor { regTmp: generated(color(4, 4, #FF0000)), hot: 1, 1 }';

	function teardownCursors():Void {
		for (name in ["regTmp", "regCode"])
			CursorManager.unregisterCursor(name);
	}

	// ==================== Cursors ====================

	@Test
	public function testAFileRegisteringItsCursorAgainReplacesIt():Void {
		try {
			final a = fileBuilder("a.manim", CURSORS);
			a.registerCursors();
			final first = CursorManager.getCursor("regTmp");
			Assert.isNull(errorOf(() -> a.registerCursors()), "the same file again is a reload");
			Assert.isNull(errorOf(() -> fileBuilder("a.manim", CURSORS).registerCursors()), "a new builder of the same file too");
			Assert.notEquals(first, CursorManager.getCursor("regTmp"), "the cursor is the one registered last");
		} catch (e:Dynamic) {
			teardownCursors();
			throw e;
		}
		teardownCursors();
	}

	@Test
	public function testAnotherFileRegisteringATakenCursorNameIsAnError():Void {
		try {
			fileBuilder("a.manim", CURSORS).registerCursors();
			final kept = CursorManager.getCursor("regTmp");
			final error = errorOf(() -> fileBuilder("b.manim", CURSORS).registerCursors());
			Assert.notNull(error, "two files' cursors of one name");
			if (error != null) {
				Assert.stringContains("regTmp", error);
				Assert.stringContains("a.manim", error);
				Assert.stringContains("b.manim", error);
			}
			Assert.equals(kept, CursorManager.getCursor("regTmp"), "the first file's cursor stays");
			Assert.notNull(errorOf(() -> CursorManager.registerCursor("regTmp", hxd.Cursor.Move)), "code over a file's cursor");
		} catch (e:Dynamic) {
			teardownCursors();
			throw e;
		}
		teardownCursors();
	}

	@Test
	public function testCodeRegisteringATakenCursorNameIsAnError():Void {
		try {
			CursorManager.registerCursor("regCode", hxd.Cursor.Move);
			final error = errorOf(() -> CursorManager.registerCursor("regCode", hxd.Cursor.Button));
			Assert.notNull(error, "code registering a name code has registered");
			Assert.stringContains("regCode", error ?? "");
			Assert.isTrue(Type.enumEq(hxd.Cursor.Move, CursorManager.getCursor("regCode")), "the first stays");
			CursorManager.unregisterCursor("regCode");
			Assert.isNull(errorOf(() -> CursorManager.registerCursor("regCode", hxd.Cursor.Button)), "free again once unregistered");
		} catch (e:Dynamic) {
			teardownCursors();
			throw e;
		}
		teardownCursors();
	}

	@Test
	public function testABuiltInCursorMayBeReplaced():Void {
		final builtIn = CursorManager.getCursor("move");
		try {
			Assert.isNull(errorOf(() -> fileBuilder("a.manim", '#c cursor { move: generated(color(4, 4, #FF0000)) }').registerCursors()),
				"a file's cursor named like an OS one replaces it");
			Assert.notNull(CursorManager.getTileCursor("move"));
			Assert.notNull(errorOf(() -> fileBuilder("b.manim", '#c cursor { move: generated(color(4, 4, #00FF00)) }').registerCursors()),
				"once replaced it is the file's");
		} catch (e:Dynamic) {
			restoreBuiltIn("move", builtIn);
			throw e;
		}
		restoreBuiltIn("move", builtIn);
	}

	static function restoreBuiltIn(name:String, cursor:hxd.Cursor):Void {
		CursorManager.unregisterCursor(name);
		@:privateAccess CursorManager.cursorRegistry.set(name, cursor);
	}

	// ==================== Fonts ====================

	@Test
	public function testAFontCanBeUnregisteredAndRegisteredAgain():Void {
		final font = hxd.res.DefaultFont.get();
		FontManager.registerFont("regFont", font);
		try {
			Assert.notNull(errorOf(() -> FontManager.registerFont("REGFONT", font)), "a taken name, in any case");
			Assert.isTrue(FontManager.unregisterFont("regFont"));
			Assert.isFalse(FontManager.unregisterFont("regFont"), "gone already");
			Assert.notNull(errorOf(() -> FontManager.getFontByName("regFont")));
			Assert.isNull(errorOf(() -> FontManager.registerFont("regFont", font)), "free again");
		} catch (e:Dynamic) {
			FontManager.unregisterFont("regFont");
			throw e;
		}
		FontManager.unregisterFont("regFont");
	}

	// ==================== Sound banks and music blocks ====================

	static final SOUNDS_A = '#ui sounds { click { file: "sound/a_click.wav" } }';
	static final SOUNDS_B = '#ui sounds { click { file: "sound/b_click.wav" } }';

	@Test
	public function testAFileTakingItsBlocksAgainReplacesThem():Void {
		final log = new LogBackend();
		final audio = new Audio(log);
		audio.addBanks(fileBuilder("a.manim", SOUNDS_A + '\n#music music { track title { file: "music/a.ogg" }\ntrack end { file: "music/end.ogg" } }'));
		Assert.isNull(errorOf(() -> audio.addBanks(fileBuilder("a.manim", SOUNDS_B + '\n#music music { track title { file: "music/b.ogg" } }'))),
			"the same file again is a reload");
		audio.play("ui.click");
		Assert.equals("sound/b_click.wav", log.plays()[0].path);
		Assert.same(["music.title"], audio.trackNames(), "the block's tracks are the ones it has now");
	}

	@Test
	public function testAnotherFileTakingATakenBlockNameIsAnError():Void {
		final log = new LogBackend();
		final audio = new Audio(log);
		audio.addBanks(fileBuilder("a.manim", SOUNDS_A));
		final error = errorOf(() -> audio.addBanks(fileBuilder("b.manim", SOUNDS_B)));
		Assert.notNull(error, "two files' sounds blocks of one name");
		if (error != null) {
			Assert.stringContains("ui", error);
			Assert.stringContains("a.manim", error);
			Assert.stringContains("b.manim", error);
		}
		audio.play("ui.click");
		Assert.equals("sound/a_click.wav", log.plays()[0].path, "the first file's bank stays");
		Assert.notNull(errorOf(() -> audio.addBank("ui", fileBuilder("c.manim", SOUNDS_B).buildSounds("ui"))), "code over a file's bank");

		audio.addBanks(fileBuilder("a.manim", '#music music { track title { file: "music/a.ogg" } }'));
		Assert.notNull(errorOf(() -> audio.addBanks(fileBuilder("b.manim", '#music music { track title { file: "music/b.ogg" } }'))),
			"two files' music blocks of one name");
	}

	@Test
	public function testCodeTakingATakenBankNameIsAnError():Void {
		final audio = new Audio(new LogBackend());
		final def = fileBuilder("a.manim", SOUNDS_A).buildSounds("ui");
		audio.addBank("ui", def);
		Assert.notNull(errorOf(() -> audio.addBank("ui", def)), "code registering a name code has registered");
		Assert.isTrue(audio.removeBank("ui"));
		Assert.isNull(errorOf(() -> audio.addBank("ui", def)), "free again once removed");
	}
}
