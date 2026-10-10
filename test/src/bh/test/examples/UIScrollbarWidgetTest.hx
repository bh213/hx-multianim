package bh.test.examples;

import utest.Assert;
import bh.multianim.MultiAnimParser.SettingValue;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness;
import bh.test.UITestHarness.MockControllable;
import bh.ui.UIElement;
import bh.ui.UIElement.UIElementListItem;
import bh.ui.UIMultiAnimScrollbar;
import bh.ui.UIMultiAnimScrollableList;
import bh.ui.UIMultiAnimSlider.UIStandardMultiAnimSlider;
import bh.ui.UIMultiAnimProgressBar;
import h2d.col.Point;

/**
 * The widgets for UI art adopted from a pack: a scrollbar that is dragged
 * (`UIMultiAnimScrollbar`, on its own and inside a list), a vertical slider, and a progress bar
 * that changes its value in place.
 */
class UIScrollbarWidgetTest extends BuilderTestBase {
	// A vertical bar: track 10x100 at 0,0; thumb 10 x (panel^2 / scrollable) at y = pos * panel / scrollable;
	// arrows above and below the track. panel 100, scrollable 200: thumb 50 tall, travel 50, positions 0..100.
	static final DRAGBAR_MANIM = "
		#scrollbar programmable(status:[normal,hover,pressed]=normal, disabled:bool=false, panelHeight:uint=100, scrollableHeight:uint=200, scrollPosition:uint=0) {
			#track bitmap(generated(color(10, $panelHeight, #222222))): 0, 0
			#up bitmap(generated(color(10, 10, #444444))): 0, -10
			#down bitmap(generated(color(10, 10, #444444))): 0, $panelHeight
			#thumb bitmap(generated(color(10, $panelHeight * $panelHeight / $scrollableHeight, #888888))): 0, $scrollPosition * $panelHeight / $scrollableHeight
			settings { arrowStep:int => 15 }
		}

		#hbar programmable(status:[normal,hover,pressed]=normal, panelHeight:uint=100, scrollableHeight:uint=200, scrollPosition:uint=0, direction:[vertical,horizontal]=vertical) {
			#track bitmap(generated(color($panelHeight, 10, #222222))): 0, 0
			#thumb bitmap(generated(color($panelHeight * $panelHeight / $scrollableHeight, 10, #888888))): $scrollPosition * $panelHeight / $scrollableHeight, 0
		}

		#oldbar programmable(panelHeight:uint=100, scrollableHeight:uint=200, scrollPosition:uint=0) {
			bitmap(generated(color(4, $panelHeight * $panelHeight / $scrollableHeight, #888888))): 0, $scrollPosition * $panelHeight / $scrollableHeight
		}
	";

	// A list whose scrollbar is dragged: 20 items of 20px in a 200px panel, the bar at x = 110.
	static final DRAG_LIST_MANIM = "
		#list-panel programmable(width:uint=120, height:uint=200, topClearance:uint=0) {
			bitmap(generated(color($width, $height, #333333))): 0, 0
			placeholder(generated(color($width, $height, #000000)), builderParameter(\"mask\")): 0, 0
			#scrollbar point: $width - 10, 0
		}

		#list-item programmable(images:[none,tile]=none, status:[hover,pressed,normal]=normal, selected:[true,false]=false, disabled:[true,false]=false, tile:tile, itemWidth:uint=120, index:uint=0, title:string=title, font:string=testfont, fontColor:int=0xFFFFFFFF) {
			bitmap(generated(color($itemWidth, 20, #555555))): 0, 0
			text($font, $title, $fontColor): 4, 2
			interactive($itemWidth, 20, $index);
			settings{height:float=>20}
		}

		#scrollbar programmable(status:[normal,hover,pressed]=normal, disabled:bool=false, panelHeight:uint=100, scrollableHeight:uint=200, scrollPosition:uint=0) {
			#track bitmap(generated(color(10, $panelHeight, #222222))): 0, 0
			#thumb bitmap(generated(color(10, $panelHeight * $panelHeight / $scrollableHeight, #888888))): 0, $scrollPosition * $panelHeight / $scrollableHeight
		}
	";

	static final VSLIDER_MANIM = "
		#vslider programmable(status:[hover, pressed, normal]=normal, value:0..100=0, size:int=100, disabled:[true, false]=false) {
			bitmap(generated(color(10, 100, #333333))): 0, 0
			#start point: 5, 0
			#end point: 5, 100
		}
		#hslider programmable(status:[hover, pressed, normal]=normal, value:0..100=0, size:int=100, disabled:[true, false]=false) {
			bitmap(generated(color(100, 10, #333333))): 0, 0
			#start point: 0, 5
			#end point: 100, 5
		}
	";

	static final PROGRESS_MANIM = "
		#progressBar programmable(value:0..100=0) {
			bitmap(generated(color(102, 12, #333333))): 0, 0
			@(value => 0..50) bitmap(generated(color($value, 10, #ff4444))): 1, 1
			@(value => 51..100) bitmap(generated(color($value, 10, #44cc44))): 1, 1
		}
	";

	// The position-only scrollbar of older files (UIComponentTest's fixture).
	static final OLD_LIST_MANIM = "
		#list-panel programmable(width:uint=120, height:uint=200, topClearance:uint=0) {
			bitmap(generated(color($width, $height, #333333))): 0, 0
			placeholder(generated(color($width, $height, #000000)), builderParameter(\"mask\")): 0, 0
			#scrollbar point: $width - 10, 0
		}

		#list-item programmable(images:[none,tile]=none, status:[hover,pressed,normal]=normal, selected:[true,false]=false, disabled:[true,false]=false, tile:tile, itemWidth:uint=120, index:uint=0, title:string=title, font:string=testfont, fontColor:int=0xFFFFFFFF) {
			bitmap(generated(color($itemWidth, 20, #555555))): 0, 0
			text($font, $title, $fontColor): 4, 2
			interactive($itemWidth, 20, $index);
			settings{height:float=>20}
		}

		#scrollbar programmable(panelHeight:uint=100, scrollableHeight:uint=200, scrollPosition:uint=0) {
			bitmap(generated(color(4, $panelHeight * $panelHeight / $scrollableHeight, #888888))): 0, $scrollPosition * $panelHeight / $scrollableHeight
		}
	";

	static function ensureTestFont():Void {
		try {
			bh.base.FontManager.getFontByName("testfont");
		} catch (e:Dynamic) {
			bh.base.FontManager.registerFont("testfont", hxd.res.DefaultFont.get());
		}
	}

	static function thumbOf(bar:UIMultiAnimScrollbar):h2d.Object {
		return bar.result.names.get("thumb")[0].getBuiltHeapsObject().toh2dObject();
	}

	static function statusOf(bar:UIMultiAnimScrollbar):String {
		@:privateAccess var params = bar.result.incrementalContext.indexedParams;
		return switch params.get("status") {
			case StringValue(s): s;
			case Index(_, v): v;
			case _: null;
		};
	}

	static function move(element:StandardUIElementEvents, mock:MockControllable, x:Float, y:Float):Void {
		element.onEvent(UITestHarness.createEventWrapper(OnMouseMove, mock, new Point(x, y)));
	}

	static function release(element:StandardUIElementEvents, mock:MockControllable, x:Float, y:Float):Void {
		element.onEvent(UITestHarness.createEventWrapper(OnRelease(0), mock, new Point(x, y)));
	}

	// ==================== UIMultiAnimScrollbar ====================

	@Test
	public function testFitsTellsTheTwoContractsApart():Void {
		final builder = BuilderTestBase.builderFromSource(DRAGBAR_MANIM);
		Assert.isTrue(UIMultiAnimScrollbar.fits(builder, "scrollbar"), "status and #thumb: a dragged scrollbar");
		Assert.isTrue(UIMultiAnimScrollbar.fits(builder, "hbar"));
		Assert.isFalse(UIMultiAnimScrollbar.fits(builder, "oldbar"), "the position-only contract");
		Assert.isFalse(UIMultiAnimScrollbar.fits(builder, "nothing"));
	}

	@Test
	public function testCreateDrawsTheThumbWhereTheArtPutsIt():Void {
		final builder = BuilderTestBase.builderFromSource(DRAGBAR_MANIM);
		final bar = UIMultiAnimScrollbar.create(builder, "scrollbar", 100, 200, 0);
		Assert.equals(0, bar.position);
		Assert.equals(100, bar.maxPosition());
		Assert.equals(15, bar.arrowStep, "settings { arrowStep } is read");
		Assert.equals("normal", statusOf(bar));
		final thumb = thumbOf(bar);
		Assert.equals(0., thumb.y);
		bar.position = 40;
		Assert.equals(20., thumb.y, "position = moves the thumb through the art's own formula");
		var told = -1;
		bar.onChange = p -> told = p;
		bar.position = 60;
		Assert.equals(-1, told, "setting the position tells nobody");
		bar.position = 500;
		Assert.equals(100, bar.position, "clamped to the range");
		bar.position = -5;
		Assert.equals(0, bar.position);
	}

	@Test
	public function testDraggingTheThumbScrolls():Void {
		final builder = BuilderTestBase.builderFromSource(DRAGBAR_MANIM);
		final bar = UIMultiAnimScrollbar.create(builder, "scrollbar", 100, 200, 0);
		final mock = new MockControllable();
		final changes:Array<Int> = [];
		bar.onChange = p -> changes.push(p);

		UITestHarness.simulatePush(bar, mock, new Point(5, 10));
		Assert.isTrue(bar.isDragging, "a push on the thumb starts a drag");
		Assert.equals("pressed", statusOf(bar));
		Assert.isTrue(mock.captureEvents.isCapturing(), "the drag captures the mouse");

		move(bar, mock, 5, 30);
		// The thumb's top went from 0 to 20 of a 50px travel: 40% of 100.
		Assert.equals(40, bar.position);
		Assert.equals([40].toString(), changes.toString(), "onChange with the new position");
		Assert.isTrue(mock.hasEvent(UIChangeValue(40)), "and UIChangeValue to the control");
		Assert.equals(20., thumbOf(bar).y, "the thumb follows");

		move(bar, mock, 5, 500);
		Assert.equals(100, bar.position, "dragged past the end: the end");
		move(bar, mock, 5, -500);
		Assert.equals(0, bar.position);

		release(bar, mock, 5, 10);
		Assert.isFalse(bar.isDragging);
		Assert.isFalse(mock.captureEvents.isCapturing());
		Assert.equals("hover", statusOf(bar), "released over the thumb: hover");
		UITestHarness.simulateLeave(bar, mock, new Point(50, 50));
		Assert.equals("normal", statusOf(bar));
	}

	@Test
	public function testAClickOnTheTrackPagesAndTheArrowsStep():Void {
		final builder = BuilderTestBase.builderFromSource(DRAGBAR_MANIM);
		final bar = UIMultiAnimScrollbar.create(builder, "scrollbar", 100, 200, 0);
		final mock = new MockControllable();
		final changes:Array<Int> = [];
		bar.onChange = p -> changes.push(p);

		UITestHarness.simulateClick(bar, mock, new Point(5, 90));
		Assert.equals(100, bar.position, "below the thumb: a page down (clamped)");
		Assert.isFalse(bar.isDragging, "a page is no drag");
		UITestHarness.simulateClick(bar, mock, new Point(5, 5));
		Assert.equals(0, bar.position, "above the thumb: a page up");

		UITestHarness.simulateClick(bar, mock, new Point(5, 105));
		Assert.equals(15, bar.position, "the down arrow steps by arrowStep");
		UITestHarness.simulateClick(bar, mock, new Point(5, 105));
		Assert.equals(30, bar.position);
		UITestHarness.simulateClick(bar, mock, new Point(5, -5));
		Assert.equals(15, bar.position, "the up arrow steps back");
		Assert.equals([100, 0, 15, 30, 15].toString(), changes.toString());

		bar.onEvent(UITestHarness.createEventWrapper(OnWheel(1), mock, new Point(5, 50)));
		Assert.equals(30, bar.position, "a wheel notch is an arrow step");
		bar.scrollBy(-100);
		Assert.equals(0, bar.position, "scrollBy from code calls onChange too");
		Assert.equals(0, changes[changes.length - 1]);
	}

	@Test
	public function testHoverFollowsTheThumb():Void {
		final builder = BuilderTestBase.builderFromSource(DRAGBAR_MANIM);
		final bar = UIMultiAnimScrollbar.create(builder, "scrollbar", 100, 200, 0);
		final mock = new MockControllable();
		UITestHarness.simulateEnter(bar, mock, new Point(5, 80));
		Assert.equals("normal", statusOf(bar), "entering the track below the thumb is not hover");
		move(bar, mock, 5, 20);
		Assert.equals("hover", statusOf(bar), "over the thumb: hover");
		move(bar, mock, 5, 80);
		Assert.equals("normal", statusOf(bar), "off it again");
	}

	@Test
	public function testDisabledIgnoresTheMouse():Void {
		final builder = BuilderTestBase.builderFromSource(DRAGBAR_MANIM);
		final bar = UIMultiAnimScrollbar.create(builder, "scrollbar", 100, 200, 0);
		final mock = new MockControllable();
		bar.disabled = true;
		@:privateAccess var params = bar.result.incrementalContext.indexedParams;
		Assert.notNull(params.get("disabled"), "disabled is passed when the design declares it");
		UITestHarness.simulatePush(bar, mock, new Point(5, 10));
		move(bar, mock, 5, 50);
		Assert.isFalse(bar.isDragging);
		Assert.equals(0, bar.position);
		Assert.equals(0, mock.eventCount());
		Assert.isTrue(Type.enumEq(bh.base.CursorManager.getDefaultCursor(), bar.getCursor()));
		bar.disabled = false;
		Assert.isTrue(Type.enumEq(bh.base.CursorManager.getDefaultInteractiveCursor(), bar.getCursor()));
	}

	@Test
	public function testAHorizontalBarReadsX():Void {
		final builder = BuilderTestBase.builderFromSource(DRAGBAR_MANIM);
		final bar = UIMultiAnimScrollbar.create(builder, "hbar", 100, 200, 0, Horizontal);
		@:privateAccess var params = bar.result.incrementalContext.indexedParams;
		final dir = switch params.get("direction") {
			case StringValue(s): s;
			case Index(_, v): v;
			case _: null;
		};
		Assert.equals("horizontal", dir, "direction is passed when the design declares it");
		final mock = new MockControllable();
		UITestHarness.simulatePush(bar, mock, new Point(10, 5));
		Assert.isTrue(bar.isDragging);
		move(bar, mock, 35, 5);
		Assert.equals(50, bar.position, "25px of a 50px travel: half way");
		Assert.equals(25., thumbOf(bar).x);
		release(bar, mock, 35, 5);
		UITestHarness.simulateClick(bar, mock, new Point(95, 5));
		Assert.equals(100, bar.position, "a click past the thumb pages along x");
	}

	@Test
	public function testSetRangeKeepsThePositionWhereItFits():Void {
		final builder = BuilderTestBase.builderFromSource(DRAGBAR_MANIM);
		final bar = UIMultiAnimScrollbar.create(builder, "scrollbar", 100, 200, 80);
		Assert.equals(80, bar.position);
		bar.setRange(100, 150);
		Assert.equals(150, bar.scrollableLength);
		Assert.equals(50, bar.position, "clamped to the new range");
		Assert.equals(Math.round(50 * 100 / 150), Math.round(thumbOf(bar).y), "the thumb is where the new formula puts it");
		bar.setRange(100, 100);
		Assert.equals(0, bar.position, "nothing to scroll");
		Assert.equals(0, bar.maxPosition());
	}

	@Test
	public function testTheOldContractIsRefused():Void {
		final builder = BuilderTestBase.builderFromSource(DRAGBAR_MANIM);
		var threw = false;
		try {
			UIMultiAnimScrollbar.create(builder, "oldbar", 100, 200, 0);
		} catch (e:Dynamic) {
			threw = true;
			Assert.isTrue(Std.string(e).indexOf("thumb") >= 0, 'the error says what the design lacks: $e');
		}
		Assert.isTrue(threw, "a position-only design cannot be dragged");
	}

	// ==================== Inside a list ====================

	function createDragList():UIMultiAnimScrollableList {
		ensureTestFont();
		final items:Array<UIElementListItem> = [for (i in 0...20) {name: 'Item ${i + 1}'}];
		final builder = BuilderTestBase.builderFromSource(DRAG_LIST_MANIM);
		return UIMultiAnimScrollableList.createWithSingleBuilder(builder, "list-panel", "list-item", "scrollbar", "scrollbar", 120, 200, items, 0, 0);
	}

	@Test
	public function testAListUsesTheDraggedScrollbarWhenItsDesignFits():Void {
		final list = createDragList();
		Assert.notNull(list.scrollbarWidget, "a status parameter and a #thumb: the list makes a UIMultiAnimScrollbar");
		Assert.equals(200, list.scrollbarWidget.panelLength);
		Assert.equals(400, list.scrollbarWidget.scrollableLength);
		Assert.isFalse(list.isScrollbarDragging());
		@:privateAccess Assert.equals(0., list.mask.scrollY);
	}

	@Test
	public function testDraggingTheListsThumbScrollsTheList():Void {
		final list = createDragList();
		final mock = new MockControllable();
		// The bar sits at x = 110; its thumb is 100 tall (200^2 / 400) with a 100px travel over 200 positions.
		UITestHarness.simulatePush(list, mock, new Point(115, 10));
		Assert.isTrue(list.isScrollbarDragging(), "a push on the thumb starts a drag through the list");
		Assert.equals(-1, list.currentPressedIndex, "no item was pressed");
		move(list, mock, 115, 60);
		@:privateAccess Assert.equals(100., list.mask.scrollY, "50px of drag is 100 of 200 positions");
		Assert.equals(100, list.scrollbarWidget.position);
		move(list, mock, 50, 60);
		@:privateAccess Assert.equals(100., list.mask.scrollY, "moving over the items while dragging keeps dragging");
		Assert.equals(-1, list.currentHoverIndex, "and hovers no item");
		release(list, mock, 50, 60);
		Assert.isFalse(list.isScrollbarDragging());
		Assert.equals(0, list.currentItemIndex, "the release that ended the drag selected nothing");

		// The list's own scrolling moves the thumb.
		list.onEvent(UITestHarness.createEventWrapper(OnWheel(1), mock, new Point(50, 50)));
		@:privateAccess Assert.equals(110., list.mask.scrollY);
		Assert.equals(110, list.scrollbarWidget.position, "a wheel over the items keeps the thumb in step");
		list.scrollToIndex(19);
		Assert.equals(200, list.scrollbarWidget.position);
	}

	@Test
	public function testAClickOnTheListsTrackPagesWithoutSelecting():Void {
		final list = createDragList();
		final mock = new MockControllable();
		UITestHarness.simulateClick(list, mock, new Point(115, 190));
		@:privateAccess Assert.equals(200., list.mask.scrollY, "a page down");
		Assert.equals(0, list.currentItemIndex, "the click selected no item");
		Assert.isFalse(mock.hasEvent(UIChangeItem(0, list.items)));
	}

	@Test
	public function testSetItemsRebuildsTheDraggedScrollbar():Void {
		final list = createDragList();
		list.setItems([for (i in 0...30) {name: 'Item ${i + 1}'}], 0);
		Assert.notNull(list.scrollbarWidget);
		Assert.equals(600, list.scrollbarWidget.scrollableLength);
		list.setItems([{name: "one"}, {name: "two"}], 0);
		Assert.isNull(list.scrollbarWidget, "two items need no scrollbar");
	}

	@Test
	public function testAListsFontSettingIsNotTheScrollbars():Void {
		// `font`/`fontColor` go to every sub-builder of a list; the scrollbar draws no text and
		// declares neither, which must not be a build error. `scrollbar.font` written out is.
		ensureTestFont();
		final items:Array<UIElementListItem> = [for (i in 0...20) {name: 'Item ${i + 1}'}];
		final builder = BuilderTestBase.builderFromSource(DRAG_LIST_MANIM);
		final screen = new bh.test.UITestHarness.UITestScreen();
		final settings:bh.multianim.MultiAnimParser.ResolvedSettings = ["font" => RSVString("testfont"), "fontColor" => RSVInt(0xFFFFFFFF)];
		final list = screen.testAddScrollableList(builder, "list-panel", "list-item", "scrollbar", items, settings, 120, 200);
		Assert.notNull(list.scrollbarWidget, "the list with a font setting builds its dragged scrollbar");

		final explicit:bh.multianim.MultiAnimParser.ResolvedSettings = ["scrollbar.font" => RSVString("testfont")];
		var threw = false;
		try {
			screen.testAddScrollableList(builder, "list-panel", "list-item", "scrollbar", items, explicit, 120, 200);
		} catch (e:Dynamic) {
			threw = true;
			Assert.isTrue(Std.string(e).indexOf("font") >= 0, 'a scrollbar.font the design does not declare is the usual mismatch error: $e');
		}
		Assert.isTrue(threw);
	}

	@Test
	public function testTheOldListContractStillWorks():Void {
		ensureTestFont();
		final items:Array<UIElementListItem> = [for (i in 0...20) {name: 'Item ${i + 1}'}];
		final builder = BuilderTestBase.builderFromSource(OLD_LIST_MANIM);
		final list = UIMultiAnimScrollableList.createWithSingleBuilder(builder, "list-panel", "list-item", "scrollbar", "scrollbar", 120, 200, items, 0, 0);
		Assert.isNull(list.scrollbarWidget, "a position-only #scrollbar is not dragged");
		final mock = new MockControllable();
		list.onEvent(UITestHarness.createEventWrapper(OnWheel(1), mock, new Point(50, 50)));
		@:privateAccess Assert.equals(10., list.mask.scrollY, "it still shows where the list is");
	}

	// ==================== A vertical slider ====================

	@Test
	public function testASliderReadsItsDirectionFromThePoints():Void {
		final builder = BuilderTestBase.builderFromSource(VSLIDER_MANIM);
		final v = UIStandardMultiAnimSlider.create(builder, "vslider", 100, 0.0);
		v.doRedraw();
		Assert.isTrue(v.isVertical(), "#start and #end differ in y and not in x: vertical");
		final h = UIStandardMultiAnimSlider.create(builder, "hslider", 100, 0.0);
		h.doRedraw();
		Assert.isFalse(h.isVertical());

		final mock = new MockControllable();
		UITestHarness.simulatePush(v, mock, new Point(5, 25));
		Assert.equals(25, v.getIntValue(), "a vertical slider reads y");
		Assert.isTrue(mock.hasEvent(UIChangeValue(25)));
		move(v, mock, 5, 75);
		Assert.equals(75, v.getIntValue());
		release(v, mock, 5, 75);

		UITestHarness.simulatePush(h, mock, new Point(40, 5));
		Assert.equals(40, h.getIntValue(), "a horizontal one reads x");
	}

	@Test
	public function testASlidersDirectionCanBeSaid():Void {
		final builder = BuilderTestBase.builderFromSource(VSLIDER_MANIM);
		final s = UIStandardMultiAnimSlider.create(builder, "vslider", 100, 0.0);
		s.direction = Vertical;
		Assert.isTrue(s.isVertical(), "said before the first draw");
		s.doRedraw();
		final mock = new MockControllable();
		UITestHarness.simulatePush(s, mock, new Point(5, 60));
		Assert.equals(60, s.getIntValue());
	}

	// ==================== A progress bar that changes in place ====================

	@Test
	public function testAProgressBarKeepsItsResultAcrossAHundredValues():Void {
		final builder = BuilderTestBase.builderFromSource(PROGRESS_MANIM);
		final bar = UIMultiAnimProgressBar.create(builder, "progressBar", 0);
		bar.doRedraw();
		final first = bar.getResult();
		Assert.notNull(first);
		Assert.isTrue(bar.incremental);
		for (i in 1...101) {
			bar.setIntValue(i);
			Assert.isTrue(bar.requestRedraw);
			bar.doRedraw();
			Assert.equals(first, bar.getResult(), 'value $i changed in place');
		}
		Assert.equals(100, bar.getIntValue());
		Assert.equals(1, bar.getObject().numChildren, "one built object, never a second");
		final fills = BuilderTestBase.findVisibleBitmapDescendants(bar.getObject());
		var fill:Null<h2d.Bitmap> = null;
		for (b in fills)
			if (Std.int(b.tile.width) == 100)
				fill = b;
		Assert.notNull(fill, "the fill is 100 wide at 100");
	}

	@Test
	public function testAProgressBarWhoseValueCannotBeFollowedIsRebuilt():Void {
		// A staticRef with children of its own is not rebuilt when its arguments change
		// (`untracked_param`): the bar falls back to a rebuild on the first change and stays there.
		final builder = BuilderTestBase.builderFromSource("
			#fill programmable(w:uint=10) {
				bitmap(generated(color($w, 10, #ff4444))): 0, 0
			}
			#progressBar programmable(value:0..100=0) {
				bitmap(generated(color(102, 12, #333333))): 0, 0
				staticRef($fill, w => $value) {
					pos: 1, 1
					bitmap(generated(color(2, 2, white))): 0, 0
				}
			}
		");
		function fillWidth(bar:UIMultiAnimProgressBar):Int {
			for (b in BuilderTestBase.findVisibleBitmapDescendants(bar.getObject()))
				if (Std.int(b.tile.height) == 10)
					return Std.int(b.tile.width);
			return -1;
		}
		final bar = UIMultiAnimProgressBar.create(builder, "progressBar", 3);
		bar.doRedraw();
		final first = bar.getResult();
		Assert.equals(3, fillWidth(bar));
		bar.setIntValue(5);
		bar.doRedraw();
		Assert.isFalse(bar.incremental, "the design proved it cannot follow value in place");
		Assert.notEquals(first, bar.getResult(), "rebuilt whole");
		Assert.equals(1, bar.getObject().numChildren);
		Assert.equals(5, fillWidth(bar));
		bar.setIntValue(2);
		bar.doRedraw();
		Assert.equals(2, fillWidth(bar), "and from then on");
	}
}
