package bh.test.examples;

import utest.Assert;
import bh.base.CursorManager;
import bh.base.MAObject;
import bh.multianim.BuilderError;
import bh.multianim.MultiAnimParser.SettingValue;
import bh.test.BuilderTestBase;
import bh.ui.UIInteractiveWrapper;
import bh.ui.screens.ScreenManager;

/**
 * Bitmap cursors from atlas cells (UI art adopted from a pack):
 * `CursorManager.registerTileCursor(name, tile, hotX, hotY)` and the `#name cursor { }` block a
 * file's load registers, so a registered name works wherever an OS cursor name does.
 */
class CursorTest extends BuilderTestBase {
	static final CURSOR_MANIM = '
		#cursors cursor {
			hand: sheet("ui", "icon_drop"), hot: 2, 3
			sword: sheet("ui", "icon_forward_idle")
			solid: generated(color(8, 8, #FF0000)), hot: 7, 7
		}
		#user programmable() {
			interactive(40, 20, "grab", cursor => "hand", cursor.hover => "sword"): 0, 0
		}
	';

	static function customOf(cursor:Null<hxd.Cursor>):Null<hxd.Cursor.CustomCursor> {
		return switch cursor {
			case Custom(c): c;
			default: null;
		};
	}

	function teardownCursors():Void {
		for (name in ["sword", "hand", "solid", "tmp", "resHand", "resArrow"])
			CursorManager.unregisterCursor(name);
	}

	// ==================== CursorManager ====================

	@Test
	public function testRegisterTileCursorIsFoundByName():Void {
		final tile = h2d.Tile.fromColor(0xFF00FF00, 12, 9);
		final cursor = CursorManager.registerTileCursor("tmp", tile, 3, 4);
		final custom = customOf(cursor);
		Assert.notNull(custom, "a tile cursor is an hxd.Cursor.Custom");
		Assert.equals(custom, customOf(CursorManager.getCursor("tmp")), "registered under its name");
		Assert.equals(custom, customOf(CursorManager.getCursor("TMP")), "names are matched without regard to case");
		@:privateAccess {
			Assert.equals(3, custom.offsetX, "the hot point is the cursor's offset");
			Assert.equals(4, custom.offsetY);
			Assert.equals(1, custom.frames.length, "one frame, the tile's pixels");
			Assert.equals(12, custom.frames[0].width);
			Assert.equals(9, custom.frames[0].height);
		}
		final tc = CursorManager.getTileCursor("tmp");
		Assert.notNull(tc);
		Assert.equals(tile, tc.tile);
		Assert.isTrue(CursorManager.getRegisteredCursorNames().contains("tmp"));
		Assert.isTrue(CursorManager.getRegisteredCursorNames().contains("pointer"), "the OS cursors are listed too");
		CursorManager.unregisterCursor("tmp");
		Assert.isNull(CursorManager.getCursor("tmp"));
		Assert.isNull(CursorManager.getTileCursor("tmp"));
	}

	@Test
	public function testTheCursorHasTheTilesPixels():Void {
		final tile = h2d.Tile.fromColor(0x2040C0, 4, 4);
		final custom = customOf(CursorManager.registerTileCursor("tmp", tile, 0, 0));
		final pixels = @:privateAccess custom.frames[0].getPixels();
		pixels.convert(ARGB);
		Assert.equals(0x2040C0, pixels.getPixel(1, 1) & 0xFFFFFF, "the frame is the tile, pixel for pixel");
		Assert.equals(0xFF, pixels.getPixel(1, 1) >>> 24, "opaque where the tile is");
		pixels.dispose();
		CursorManager.unregisterCursor("tmp");
	}

	@Test
	public function testAHotPointOutsideTheTileIsAnError():Void {
		final tile = h2d.Tile.fromColor(0xFFFFFFFF, 6, 6);
		var threw = false;
		try {
			CursorManager.registerTileCursor("tmp", tile, 6, 0);
		} catch (e:String) {
			threw = true;
			Assert.isTrue(e.indexOf("hot") >= 0, 'the error says what is wrong: $e');
		}
		Assert.isTrue(threw, "SDL cannot make a cursor whose hot point is outside it");
		Assert.isNull(CursorManager.getCursor("tmp"), "nothing registered");
		threw = false;
		try {
			CursorManager.registerTileCursor("tmp", tile, 0, -1);
		} catch (e:String) {
			threw = true;
		}
		Assert.isTrue(threw);
	}

	@Test
	public function testRegisterCursorReplacesATileCursor():Void {
		CursorManager.registerTileCursor("tmp", h2d.Tile.fromColor(0xFFFFFFFF, 2, 2));
		CursorManager.registerCursor("tmp", hxd.Cursor.Move);
		Assert.isNull(CursorManager.getTileCursor("tmp"), "no longer a tile cursor");
		Assert.isTrue(Type.enumEq(hxd.Cursor.Move, CursorManager.getCursor("tmp")));
		CursorManager.unregisterCursor("tmp");
	}

	// ==================== The cursor block ====================

	@Test
	public function testParsesACursorBlock():Void {
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#c cursor { pointer: sheet("ui", "hand"), hot: 3, 1 }'));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#c cursor { pointer: sheet("ui", "hand")  sword: file("sword.png"), hot: 0, 0 }'));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#c cursor { pointer: sheet("ui", "hand"); sword: center(sheet("ui", "sword")) }'));
	}

	@Test
	public function testACursorBlockNeedsANameAndTheRoot():Void {
		var error = BuilderTestBase.parseExpectingError('cursor { pointer: sheet("ui", "hand") }');
		Assert.notNull(error, "a cursor block without a #name is an error");
		error = BuilderTestBase.parseExpectingError('#p programmable() { #c cursor { pointer: sheet("ui", "hand") } }');
		Assert.notNull(error, "a cursor block inside a programmable is an error");
		Assert.isTrue(error.indexOf("root") >= 0, 'the error says root: $error');
		error = BuilderTestBase.parseExpectingError('#c cursor { }');
		Assert.notNull(error, "an empty block is an error");
		error = BuilderTestBase.parseExpectingError('#c cursor { a: sheet("ui", "x")  A: sheet("ui", "y") }');
		Assert.notNull(error, "a name given twice (in any case) is an error");
		Assert.isTrue(error.indexOf("twice") >= 0, '$error');
		error = BuilderTestBase.parseExpectingError('#c cursor { a: sheet("ui", "x"), hot: -1, 0 }');
		Assert.notNull(error, "a negative hot point is an error");
		error = BuilderTestBase.parseExpectingError('#c cursor { a: sheet("ui", "x"), 3, 1 }');
		Assert.notNull(error, "the hot point is written hot: x, y");
	}

	@Test
	public function testBuildCursorsMakesOneCursorPerEntry():Void {
		final builder = BuilderTestBase.builderFromSource(CURSOR_MANIM);
		final cursors = builder.buildCursors("cursors");
		final hand = customOf(cursors.get("hand"));
		final sword = customOf(cursors.get("sword"));
		final solid = customOf(cursors.get("solid"));
		Assert.notNull(hand);
		Assert.notNull(sword);
		Assert.notNull(solid, "a generated tile (a stretched 1x1 texture) is drawn to pixels too");
		@:privateAccess {
			Assert.equals(2, hand.offsetX);
			Assert.equals(3, hand.offsetY);
			Assert.equals(0, sword.offsetX, "hot: defaults to 0, 0");
			Assert.equals(10, hand.frames[0].width, "icon_drop is 10x10");
			Assert.equals(8, solid.frames[0].width);
			final pixels = solid.frames[0].getPixels();
			pixels.convert(ARGB);
			Assert.equals(0xFF0000, pixels.getPixel(3, 3) & 0xFFFFFF, "the generated colour");
			pixels.dispose();
		}
		Assert.isNull(CursorManager.getCursor("hand"), "buildCursors registers nothing");
		Assert.equals(["cursors"].toString(), builder.cursorBlockNames().toString());
	}

	@Test
	public function testRegisterCursorsThenAnInteractiveFindsThemByName():Void {
		final builder = BuilderTestBase.builderFromSource(CURSOR_MANIM);
		try {
			Assert.equals(3, builder.registerCursors(), "every entry of every block");
			Assert.notNull(customOf(CursorManager.getCursor("hand")));
			Assert.notNull(customOf(CursorManager.getCursor("sword")));
			final tc = CursorManager.getTileCursor("hand");
			Assert.equals(2, tc.hotX);

			// cursor => "hand" on an interactive resolves through CursorManager.
			final result = builder.buildWithParameters("user", []);
			Assert.equals(1, result.interactives.length);
			final wrapper = new UIInteractiveWrapper(result.interactives[0], null);
			Assert.equals(customOf(CursorManager.getCursor("hand")), customOf(wrapper.getCursor()), "the interactive's cursor is the hand");
			wrapper.onEvent(bh.test.UITestHarness.createEventWrapper(OnEnter, new bh.test.UITestHarness.MockControllable()));
			Assert.equals(customOf(CursorManager.getCursor("sword")), customOf(wrapper.getCursor()), "cursor.hover is the sword");
		} catch (e:Dynamic) {
			teardownCursors();
			throw e;
		}
		teardownCursors();
	}

	@Test
	public function testACellTheSheetHasNotIsABuildErrorAtTheBlock():Void {
		final builder = BuilderTestBase.builderFromSource('#c cursor { bad: sheet("ui", "no_such_cell") }');
		var threw:Null<BuilderError> = null;
		try {
			builder.registerCursors();
		} catch (e:BuilderError) {
			threw = e;
		}
		Assert.notNull(threw);
		if (threw != null)
			Assert.isTrue(threw.message.indexOf("no_such_cell") >= 0, 'the error names the cell: ${threw.message}');
		Assert.isNull(CursorManager.getCursor("bad"));
	}

	@Test
	public function testScreenManagerRegistersAFilesCursorsWhenItLoads():Void {
		final sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		try {
			Assert.isNull(CursorManager.getCursor("resHand"), "not registered before the file loads");
			final builder = sm.buildFromResourceName("cursor-block.manim", false);
			Assert.notNull(customOf(CursorManager.getCursor("resHand")), "buildFromResource registers the file's cursor block");
			Assert.notNull(customOf(CursorManager.getCursor("resArrow")));
			final tc = CursorManager.getTileCursor("resHand");
			Assert.equals(2, tc.hotX);
			Assert.equals(3, tc.hotY);
			// The file's own interactive uses it, as an OS cursor name.
			final result = builder.buildWithParameters("cursorUser", []);
			final wrapper = new UIInteractiveWrapper(result.interactives[0], null);
			Assert.equals(customOf(CursorManager.getCursor("resHand")), customOf(wrapper.getCursor()));
		} catch (e:Dynamic) {
			teardownCursors();
			throw e;
		}
		teardownCursors();
	}

	@Test
	public function testTheSystemCursorIsSetFromTheRegisteredOne():Void {
		// What a controller does with it: hxd.System.setCursor gets the Custom cursor.
		final cursor = CursorManager.registerTileCursor("tmp", h2d.Tile.fromColor(0xFFFFFFFF, 3, 3), 1, 1);
		final applied:Array<hxd.Cursor> = [];
		final was = hxd.System.setCursor;
		hxd.System.setCursor = c -> applied.push(c);
		try {
			CursorManager.setOverrideCursor(CursorManager.getCursor("tmp"));
			Assert.equals(1, applied.length);
			Assert.equals(customOf(cursor), customOf(applied[0]));
			CursorManager.setOverrideCursor(null);
		} catch (e:Dynamic) {
			hxd.System.setCursor = was;
			CursorManager.unregisterCursor("tmp");
			throw e;
		}
		hxd.System.setCursor = was;
		CursorManager.unregisterCursor("tmp");
	}
}
