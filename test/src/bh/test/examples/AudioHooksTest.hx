package bh.test.examples;

import utest.Assert;
import bh.base.Clock;
import bh.base.ResourceLoader.CachingResourceLoader;
import bh.stateanim.AnimationSM;
import bh.stateanim.AnimationFrame;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness;
import bh.test.UITestHarness.MockControllable;
import bh.ui.UIElement;
import bh.ui.UIElement.UIElementListItem;
import bh.ui.UIMultiAnimButton.UIStandardMultiAnimButton;
import bh.ui.UIMultiAnimDropdown.UIStandardMultiAnimDropdown;
import bh.ui.UIMultiAnimSlider.UIStandardMultiAnimSlider;
import bh.ui.screens.ScreenManager;
import h2d.col.Point;
import haxe.io.Bytes;

/**
 * The hooks a sound layer hangs on: a sound loaded like a sheet, a button's hover and a
 * dropdown's open and close said as events, a slider's change said only when its value changes,
 * more than one listener for an `.anim`'s events, and the clock the DevBridge's pause sets.
 */
@:access(bh.multianim.dev.DevBridge)
class AudioHooksTest extends utest.Test {
	static final BUTTON_MANIM = "
		#button programmable(buttonText:string=Click, status:[normal,hover,pressed]=normal, disabled:bool=false) {
			bitmap(generated(color(100, 30, #444444))): 0, 0
		}
	";

	static final SLIDER_MANIM = "
		#slider programmable(status:[hover, pressed, normal]=normal, value:0..100=0, size:int=100, disabled:[true, false]=false) {
			bitmap(generated(color(100, 10, #333333))): 0, 0
			#start point: 0, 5
			#end point: 100, 5
		}
	";

	static final DROPDOWN_MANIM = "
		#dropdown programmable(status:[normal,hover,pressed,disabled]=normal, panel:[open,closed]=closed, font:string=testfont, fontColor:int=0xFFFFFFFF) {
			bitmap(generated(color(120, 30, #444444))): 0, 0
			#panelPoint (updatable) point: 0, 30
			#selectedName(updatable) text($font, callback(\"selectedName\"), $fontColor): 2, 4
			settings{transitionTimer:float=>0.2}
		}

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

	// ==================== A sound loaded like a sheet ====================

	/** A 16-bit mono WAV of `seconds` of silence at 8 kHz, the way an asset pipeline would write one. */
	static function silentWav(seconds:Float):Bytes {
		final rate = 8000;
		final samples = Std.int(rate * seconds);
		final out = new haxe.io.BytesOutput();
		new format.wav.Writer(out).write({
			header: {
				format: WF_PCM,
				channels: 1,
				samplingRate: rate,
				byteRate: rate * 2,
				blockAlign: 2,
				bitsPerSample: 16
			},
			data: Bytes.alloc(samples * 2),
			cuePoints: null
		});
		return out.getBytes();
	}

	@Test
	public function testASoundIsReadThroughTheResourceLoaderAndKept():Void {
		final loader = new CachingResourceLoader();
		var reads = 0;
		loader.loadHXDResourceImpl = name -> {
			reads++;
			return hxd.res.Any.fromBytes(name, silentWav(0.25));
		};
		final first = loader.loadSound("sound/beep.wav");
		final again = loader.loadSound("sound/beep.wav");
		Assert.equals(first, again, "the same sound both times");
		Assert.equals(1, reads, "read once");
		Assert.floatEquals(0.25, first.getData().duration, 0.001, "a quarter second of 8 kHz samples");

		loader.clearCache();
		final fresh = loader.loadSound("sound/beep.wav");
		Assert.notEquals(first, fresh, "cleared with the other caches");
		Assert.equals(2, reads);
	}

	@Test
	public function testASoundNobodyCanLoadSaysItsName():Void {
		final loader = new CachingResourceLoader();
		loader.loadHXDResourceImpl = name -> null;
		var said = "";
		try {
			loader.loadSound("sound/missing.wav");
		} catch (e:Dynamic) {
			said = Std.string(e);
		}
		Assert.stringContains("sound/missing.wav", said);
	}

	// ==================== The events sound needs ====================

	@Test
	public function testAButtonSaysWhenThePointerComesAndGoes():Void {
		final builder = BuilderTestBase.builderFromSource(BUTTON_MANIM);
		final button = UIStandardMultiAnimButton.create(builder, "button", "Buy");
		final mock = new MockControllable();

		UITestHarness.simulateEnter(button, mock);
		Assert.isTrue(mock.hasEvent(UIHover(true)), "over");
		Assert.equals(1, mock.eventCount());
		UITestHarness.simulateLeave(button, mock);
		Assert.isTrue(mock.hasEvent(UIHover(false)), "left");
		Assert.equals(2, mock.eventCount());

		mock.clearEvents();
		button.disabled = true;
		UITestHarness.simulateEnter(button, mock);
		Assert.equals(0, mock.eventCount(), "a disabled button says nothing");
	}

	function ensureTestFont() {
		try {
			bh.base.FontManager.getFontByName("testfont");
		} catch (e:Dynamic) {
			bh.base.FontManager.registerFont("testfont", hxd.res.DefaultFont.get());
		}
	}

	@Test
	public function testADropdownSaysWhenItOpensAndCloses():Void {
		ensureTestFont();
		final items:Array<UIElementListItem> = [{name: "One"}, {name: "Two"}, {name: "Three"}];
		final builder = BuilderTestBase.builderFromSource(DROPDOWN_MANIM);
		final dropdown = UIStandardMultiAnimDropdown.createWithSingleBuilder(builder, items, 0, "dropdown", "list-panel", "list-item", "scrollbar",
			"scrollbar", 120, 200);
		dropdown.autoOpen = false;
		dropdown.autoCloseOnLeave = false;
		final mock = new MockControllable();
		// above the panel's bounds: while the panel is open, an event inside them goes to the panel
		final onButton = new Point(60, -100);

		UITestHarness.simulateClick(dropdown, mock, onButton);
		Assert.isTrue(mock.hasEvent(UIOpen), "opened by a click");
		Assert.isFalse(mock.hasEvent(UIClose));
		mock.clearEvents();

		UITestHarness.simulateClick(dropdown, mock, onButton);
		Assert.isTrue(mock.hasEvent(UIClose), "closed by the next click");
		Assert.isFalse(mock.hasEvent(UIOpen));
		mock.clearEvents();

		dropdown.autoOpen = true;
		dropdown.autoCloseOnLeave = true;
		UITestHarness.simulateEnter(dropdown, mock, onButton);
		Assert.isTrue(mock.hasEvent(UIOpen), "opened as the pointer comes");
		UITestHarness.simulateLeave(dropdown, mock, onButton);
		Assert.isTrue(mock.hasEvent(UIClose), "closed as it leaves");
	}

	@Test
	public function testASliderSaysAChangeOnlyWhenItsValueChanges():Void {
		final builder = BuilderTestBase.builderFromSource(SLIDER_MANIM);
		final slider = UIStandardMultiAnimSlider.create(builder, "slider", 100, 0.0);
		slider.doRedraw();
		final mock = new MockControllable();

		UITestHarness.simulatePush(slider, mock, new Point(40, 5));
		Assert.isTrue(mock.hasEvent(UIChangeValue(40)));
		Assert.equals(2, mock.eventCount(), "the int and the float, once");

		slider.onEvent(UITestHarness.createEventWrapper(OnMouseMove, mock, new Point(40, 5)));
		slider.onEvent(UITestHarness.createEventWrapper(OnMouseMove, mock, new Point(40, 7)));
		Assert.equals(2, mock.eventCount(), "dragged without moving the value: nothing said");

		slider.onEvent(UITestHarness.createEventWrapper(OnMouseMove, mock, new Point(41, 5)));
		Assert.equals(4, mock.eventCount(), "one pixel over: said");
		Assert.isTrue(mock.hasEvent(UIChangeValue(41)));
		slider.onEvent(UITestHarness.createEventWrapper(OnRelease(0), mock, new Point(41, 5)));

		mock.clearEvents();
		UITestHarness.simulatePush(slider, mock, new Point(41, 5));
		Assert.equals(0, mock.eventCount(), "pushed where it already stands: nothing said");
		slider.onEvent(UITestHarness.createEventWrapper(OnRelease(0), mock, new Point(41, 5)));

		slider.setIntValue(70);
		UITestHarness.simulatePush(slider, mock, new Point(70, 5));
		Assert.equals(0, mock.eventCount(), "a value set from code is where it stands");
		slider.onEvent(UITestHarness.createEventWrapper(OnRelease(0), mock, new Point(70, 5)));
		UITestHarness.simulatePush(slider, mock, new Point(20, 5));
		Assert.isTrue(mock.hasEvent(UIChangeValue(20)), "and a push elsewhere is a change");
	}

	// ==================== More than one listener for an .anim's events ====================

	static function createFrame(duration:Float):AnimationFrame {
		final tile = h2d.Tile.fromColor(0xFF0000, 16, 16);
		return new AnimationFrame(tile, duration, 0, 0, 16, 16);
	}

	@Test
	public function testTwoListenersHearOneTriggerBesideTheHandler():Void {
		final sm = new AnimationSM(new Map(), true);
		sm.addAnimationState("fire", [Frame(createFrame(0.001)), Event(Trigger("shot")), Frame(createFrame(0.1))], 0, new Map());

		final heard:Array<String> = [];
		sm.onAnimationEvent = e -> switch e {
			case Trigger(name): heard.push('handler:$name');
			default:
		};
		final sound = (e:bh.stateanim.AnimationSM.AnimationEvent) -> switch e {
			case Trigger(name): heard.push('sound:$name');
			default:
		};
		final tool = (e:bh.stateanim.AnimationSM.AnimationEvent) -> switch e {
			case Trigger(name): heard.push('tool:$name');
			default:
		};
		sm.addEventListener(sound);
		sm.addEventListener(tool);

		sm.play("fire");
		sm.update(0.01);
		Assert.same(["handler:shot", "sound:shot", "tool:shot"], heard, "the handler first, then the listeners in order");

		Assert.isTrue(sm.removeEventListener(sound));
		Assert.isFalse(sm.removeEventListener(sound), "gone already");
		heard.resize(0);
		sm.play("fire");
		sm.update(0.01);
		Assert.same(["handler:shot", "tool:shot"], heard);
	}

	@Test
	public function testAListenerThatRemovesItselfDoesNotSkipTheNext():Void {
		final sm = new AnimationSM(new Map(), true);
		sm.addAnimationState("fire", [Frame(createFrame(0.001)), Event(Trigger("shot")), Frame(createFrame(0.1))], 0, new Map());

		final heard:Array<String> = [];
		var once:Null<bh.stateanim.AnimationSM.AnimationEvent->Void> = null;
		once = e -> {
			heard.push("once");
			sm.removeEventListener(once);
		};
		final after = (e:bh.stateanim.AnimationSM.AnimationEvent) -> {
			heard.push("after");
		};
		sm.addEventListener(once);
		sm.addEventListener(after);

		sm.play("fire");
		sm.update(0.01);
		Assert.same(["once", "after"], heard, "the listener after one that removed itself still hears the event");
	}

	// ==================== Pause told ====================

	@Test
	public function testTheClockTellsItsListenersOfAChange():Void {
		final clock = new Clock();
		var told = 0;
		var seen:Null<Clock> = null;
		final listener = (c:Clock) -> {
			told++;
			seen = c;
		};
		clock.addListener(listener);
		clock.paused = true;
		Assert.equals(1, told);
		Assert.equals(clock, seen);
		clock.paused = true;
		Assert.equals(1, told, "no change, nothing told");
		clock.scale = 0.5;
		Assert.equals(2, told);
		clock.scale = -1;
		Assert.equals(0.0, clock.scale, "never below zero");
		Assert.equals(3, told, "held at zero, still a change from a half");
		Assert.isTrue(clock.removeListener(listener));
		clock.paused = false;
		Assert.equals(3, told, "told nobody after the listener went");
	}

	#if MULTIANIM_DEV
	@Test
	public function testTheDevBridgePauseSetsTheScreenManagersClock():Void {
		final sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		final bridge = new bh.multianim.dev.DevBridge(sm, 0);
		var heard:Array<Bool> = [];
		sm.clock.addListener(c -> heard.push(c.paused));
		Assert.isFalse(sm.clock.paused);
		// paused and resumed within the one test, so the test app's own loop goes on
		bridge.dispatch("pause", {paused: true});
		Assert.isTrue(sm.clock.paused, "the pause RPC pauses the clock");
		bridge.dispatch("pause", {paused: false});
		Assert.isFalse(sm.clock.paused, "and the resume resumes it");
		Assert.same([true, false], heard);
		sm.dispose();
	}
	#end
}
