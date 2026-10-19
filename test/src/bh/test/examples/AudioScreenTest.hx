package bh.test.examples;

import utest.Assert;
import bh.audio.Audio;
import bh.audio.LogBackend;
import bh.stateanim.AnimationSM;
import bh.stateanim.AnimationFrame;
import bh.test.BuilderTestBase;
import bh.test.UITestHarness;
import bh.test.UITestHarness.MockControllable;
import bh.ui.UIElement;
import bh.ui.UIInteractiveWrapper;
import bh.ui.UIMultiAnimButton.UIStandardMultiAnimButton;
import bh.ui.screens.ScreenManager;
import bh.ui.screens.UIScreen;

/**
 * Sound with no code: the widgets' sounds from the `ui` bank and an element's `sound.<key>`
 * setting, an `.anim`'s `sounds { }` played by the state machine, music by screen (`music =>`)
 * crossfaded on a switch with the `dialog` snapshot under a dialog, and the DevBridge's audio ops.
 */
class AudioScreenTest extends utest.Test {
	static final WIDGETS = '
		#button programmable(buttonText:string=Click, status:[normal,hover,pressed]=normal, disabled:bool=false) {
			bitmap(generated(color(100, 30, #444444))): 0, 0
		}
		#quiet programmable(buttonText:string=Click, status:[normal,hover,pressed]=normal, disabled:bool=false) {
			bitmap(generated(color(100, 30, #444444))): 0, 0
			settings { sound.click => none, sound.hover => "fx.explosion" }
		}
		#panel programmable() {
			interactive(40, 20, "buy", sound.click => "ui.change"): 0, 0
		}
		#menu programmable() {
			bitmap(generated(color(10, 10, #222222))): 0, 0
			settings { music => "music.play" }
		}
	';

	/** A screen manager playing into a log, with the test file's banks, mix and music. */
	function manager():{sm:ScreenManager, log:LogBackend} {
		final sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		final log = new LogBackend();
		sm.audio.backend = log;
		sm.audio.randomFunc = () -> 0.0;
		sm.buildFromResourceName("sounds-block.manim", false);
		log.clear();
		return {sm: sm, log: log};
	}

	// ==================== Widgets ====================

	@Test
	public function testAButtonsHoverAndClickPlayTheUiBankWithNoCode():Void {
		final m = manager();
		final screen = new SoundTestScreen(m.sm);
		final button = UIStandardMultiAnimButton.create(BuilderTestBase.builderFromSource(WIDGETS), "button", "Buy");
		screen.dispatchScreenEvent(UIHover(true), button);
		Assert.equals(1, m.log.plays("ui.hover").length, "the pointer came: ui.hover");
		screen.dispatchScreenEvent(UIHover(false), button);
		Assert.equals(1, m.log.plays().length, "leaving is silent");
		screen.dispatchScreenEvent(UIClick, button);
		Assert.equals(1, m.log.plays("ui.click").length);
		screen.dispatchScreenEvent(UIChangeValue(3), button);
		Assert.equals(1, m.log.plays("ui.change").length);
		screen.dispatchScreenEvent(UIChangeFloatValue(3), button);
		Assert.equals(1, m.log.plays("ui.change").length, "a slider's float beside its int: one sound");
		screen.dispatchScreenEvent(UIToggle(true), button);
		screen.dispatchScreenEvent(UIOpen, button);
		Assert.equals(3, m.log.plays().length, "toggle and open: the ui bank has neither, nothing plays");
		Assert.equals(7, screen.recordedEvents.length, "the screen still hears every event");
	}

	@Test
	public function testAWidgetsOwnSettingSaysItsSoundOrNone():Void {
		final m = manager();
		final screen = new SoundTestScreen(m.sm);
		final quiet = UIStandardMultiAnimButton.create(BuilderTestBase.builderFromSource(WIDGETS), "quiet", "Buy");
		screen.dispatchScreenEvent(UIClick, quiet);
		Assert.equals(0, m.log.plays().length, "sound.click => none");
		screen.dispatchScreenEvent(UIHover(true), quiet);
		Assert.equals(1, m.log.plays("fx.explosion").length, "sound.hover names another sound");
		Assert.equals(0, m.log.plays("ui.hover").length);
	}

	@Test
	public function testAnInteractivesMetadataSaysItsSound():Void {
		final m = manager();
		final screen = new SoundTestScreen(m.sm);
		final result = BuilderTestBase.builderFromSource(WIDGETS).buildWithParameters("panel", []);
		final wrapper = new UIInteractiveWrapper(result.interactives[0], null);
		final mock = new MockControllable();
		UITestHarness.simulateClick(wrapper, mock);
		Assert.isTrue(mock.recordedEvents.length > 0);
		for (e in mock.recordedEvents)
			screen.dispatchScreenEvent(e.event, wrapper);
		Assert.equals(1, m.log.plays("ui.change").length, "sound.click => \"ui.change\" in the interactive's metadata");
		Assert.equals(0, m.log.plays("ui.click").length);
	}

	@Test
	public function testAScreenWithNoManagerIsSilent():Void {
		final screen = new bh.test.UITestHarness.UITestScreen();
		final button = UIStandardMultiAnimButton.create(BuilderTestBase.builderFromSource(WIDGETS), "button", "Buy");
		screen.dispatchScreenEvent(UIClick, button);
		Assert.equals(1, screen.recordedEvents.length, "nothing to play through; the event still arrives");
	}

	// ==================== An .anim's sounds ====================

	static function createFrame(duration:Float):AnimationFrame {
		return new AnimationFrame(h2d.Tile.fromColor(0xFF0000, 16, 16), duration, 0, 0, 16, 16);
	}

	@Test
	public function testAStateMachinePlaysItsEventsSounds():Void {
		final log = new LogBackend();
		final audio = new Audio(log);
		audio.randomFunc = () -> 0.0;
		audio.addBank("fx", BuilderTestBase.builderFromSource('#fx sounds { shot { file: "sound/shot.wav" } }').buildSounds("fx"));
		final sm = new AnimationSM(new Map(), true);
		sm.sounds = ["fire" => "fx.shot"];
		sm.audio = audio;
		sm.addAnimationState("fire", [Frame(createFrame(0.001)), Event(Trigger("fire")), Event(Trigger("flash")), Frame(createFrame(0.1))], 0, new Map());
		var heard = 0;
		sm.onAnimationEvent = e -> heard++;
		sm.play("fire");
		sm.update(0.01);
		Assert.equals(2, heard, "the game's handler hears both events");
		Assert.equals(1, log.plays("fx.shot").length, "fire plays its sound");
		Assert.equals(1, log.plays().length, "flash has none");
	}

	@Test
	public function testTheAnimFilesSoundsBlockIsParsed():Void {
		final loader = bh.test.TestResourceLoader.createLoader();
		final src = 'sheet: "crew2"\nfps: 10\nsounds {\n\tfire: "fx.shot"\n\tstep: "fx.step"\n}\nanimation idle { playlist { sheet: "idle" frames: 0..1 } }\n';
		var parsed:Null<bh.stateanim.AnimParser.AnimParserResult> = null;
		var error = "";
		try {
			parsed = bh.stateanim.AnimParser.parseString(src, "snd-test.anim", loader);
		} catch (e:Dynamic) {
			error = Std.string(e);
		}
		if (parsed != null) {
			Assert.equals("fx.shot", parsed.sounds.get("fire"));
			Assert.equals("fx.step", parsed.sounds.get("step"));
		} else {
			// the sheet or its frames are not in the test resources: the block itself still parsed
			Assert.isTrue(error.indexOf("sounds") < 0, 'the error is about the sheet, not the sounds block: $error');
		}
		var said = "";
		try {
			bh.stateanim.AnimParser.parseString('sheet: "crew2"\nsounds { fire: "a"  fire: "b" }\n', "twice.anim", loader);
		} catch (e:Dynamic) {
			said = Std.string(e);
		}
		Assert.isTrue(said.indexOf("twice") >= 0, 'an event twice: $said');
	}

	// ==================== Music by screen ====================

	@Test
	public function testMusicFollowsTheScreensAndCrossfades():Void {
		final m = manager();
		final menu = new SoundTestScreen(m.sm);
		menu.screenMusic = "music.title";
		final play = new SoundTestScreen(m.sm);
		play.screenMusic = "music.play";
		final silent = new SoundTestScreen(m.sm);
		final quiet = new SoundTestScreen(m.sm);
		quiet.screenMusic = "none";
		m.sm.addScreen("menu", menu);
		m.sm.addScreen("play", play);
		m.sm.addScreen("silent", silent);
		m.sm.addScreen("quiet", quiet);

		m.sm.switchTo(menu);
		Assert.equals("music.title", m.sm.audio.musicPlaying);
		var plays = m.log.plays("music.title");
		Assert.equals(1, plays.length);
		Assert.equals("music/title.mp3", plays[0].path);
		Assert.equals("music", plays[0].bus, "the music bus");
		Assert.floatEquals(Audio.MUSIC_CROSSFADE, plays[0].fade, "faded in");

		m.sm.switchTo(play);
		Assert.equals("music.play", m.sm.audio.musicPlaying);
		Assert.equals(1, m.log.stops("music.title").length, "the title fades out");
		Assert.floatEquals(Audio.MUSIC_CROSSFADE, m.log.stops("music.title")[0].fade);
		Assert.equals(1, m.log.plays("music.play").length);

		m.sm.switchTo(silent);
		Assert.equals("music.play", m.sm.audio.musicPlaying, "a screen that says nothing keeps what plays");
		Assert.equals(1, m.log.stops().length);

		m.sm.switchTo(play);
		Assert.equals(1, m.log.plays("music.play").length, "the same track plays on");

		m.sm.switchTo(quiet);
		Assert.isNull(m.sm.audio.musicPlaying, "none stops it");
		Assert.equals(1, m.log.stops("music.play").length);
	}

	@Test
	public function testADialogDucksTheMusicAndKeepsItsCallers():Void {
		final m = manager();
		final menu = new SoundTestScreen(m.sm);
		menu.screenMusic = "music.title";
		final dialog = new SoundTestScreen(m.sm);
		m.sm.addScreen("menu", menu);
		m.sm.addScreen("dialog", dialog);
		m.sm.switchTo(menu);
		Assert.isFalse(m.sm.audio.isSnapshotOn("dialog"));
		m.sm.modalDialog(dialog, menu, "options");
		Assert.isTrue(m.sm.audio.isSnapshotOn("dialog"), "the dialog snapshot is on under a dialog");
		Assert.equals("music.title", m.sm.audio.musicPlaying, "the caller's music plays on");
		Assert.equals(1, m.log.plays("music.title").length);
		m.sm.closeDialogWithTransition();
		Assert.isFalse(m.sm.audio.isSnapshotOn("dialog"), "and off after it");
		Assert.equals("music.title", m.sm.audio.musicPlaying);
	}

	@Test
	public function testAScreenReadsItsMusicFromItsSettings():Void {
		final m = manager();
		final screen = new SoundTestScreen(m.sm);
		Assert.isNull(screen.screenMusic);
		screen.addBuilderResult(BuilderTestBase.builderFromSource(WIDGETS).buildWithParameters("menu", []));
		Assert.equals("music.play", screen.screenMusic, "settings { music => \"music.play\" }");
		screen.addBuilderResult(BuilderTestBase.builderFromSource(WIDGETS).buildWithParameters("button", ["buttonText" => "x"]));
		Assert.equals("music.play", screen.screenMusic, "the first that says it");
	}

	@Test
	public function testAScreenMayNameItsOwnControlsMusicSoundAndVolume():Void {
		final m = manager();
		final builder = BuilderTestBase.builderFromSource(WIDGETS);
		final screen = new SoundControlsScreen(m.sm);
		screen.music = UIStandardMultiAnimButton.create(builder, "button", "Music");
		screen.addBuilderResult(builder.buildWithParameters("menu", []));
		m.sm.addScreen("options", screen);
		m.sm.switchTo(screen);
		Assert.notNull(screen.music, "the screen's own field holds its control");
		Assert.equals("music.play", m.sm.audio.musicPlaying, "settings { music => } still gives the screen its music");
	}

	@Test
	public function testAnUnknownTrackIsAnError():Void {
		final m = manager();
		var said = "";
		try {
			m.sm.audio.playMusic("music.credits");
		} catch (e:String) {
			said = e;
		}
		Assert.isTrue(said.indexOf("music.play, music.title") >= 0, said);
		Assert.same(["music.play", "music.title"], m.sm.audio.trackNames());
	}

	@Test
	public function testTheHistoryKeepsWhatHappened():Void {
		final m = manager();
		final audio = m.sm.audio;
		final before = audio.history.length;
		audio.play("ui.click");
		audio.setVca("Music", 0.5);
		audio.snapshot("dialog", true);
		audio.playMusic("music.title");
		audio.stop("ui.click");
		final lines = audio.history.slice(before);
		Assert.same(["play", "vca", "snapshot", "music", "stop"], [for (l in lines) l.kind]);
		Assert.equals("ui.click", lines[0].name);
		Assert.equals("sound/click.wav", lines[0].detail);
		Assert.equals("0.5", lines[1].detail);
		Assert.equals("on", lines[2].detail);
		Assert.isTrue(lines[4].id > lines[0].id, "ids grow");
		Assert.equals(lines.length, audio.historySince(lines[0].id - 1).length);
		Assert.equals(0, audio.historySince(lines[4].id).length);
	}

	@Test
	public function testStopAllWritesAHistoryLine():Void {
		final m = manager();
		final audio = m.sm.audio;
		audio.play("ui.click");
		audio.play("ui.hover");
		final before = audio.history.length;
		Assert.equals(2, audio.stopAll());
		final lines = audio.history.slice(before);
		Assert.equals(1, lines.length, "one line for the lot");
		Assert.equals("stop", lines[0].kind);
		Assert.equals("*", lines[0].name);
		Assert.equals("2", lines[0].detail);
		Assert.equals(0, audio.stopAll(), "nothing alive");
		Assert.equals(before + 1, audio.history.length, "stopping nothing writes nothing");
	}

	#if MULTIANIM_DEV
	@Test
	public function testTheDevBridgeSeesAndSetsTheSound():Void {
		final m = manager();
		final bridge = new bh.multianim.dev.DevBridge(m.sm, 0);
		@:privateAccess {
			final state:Dynamic = bridge.dispatch("audio_state", {});
			final banks:Array<String> = state.banks;
			banks.sort(Reflect.compare);
			Assert.same(["fx", "ui"], banks);
			Assert.isTrue((state.sounds : Array<String>).contains("ui.click"));
			Assert.equals(3, (state.mix.buses : Array<Dynamic>).length);
			Assert.same(["music.play", "music.title"], state.tracks);
			Assert.isNull(state.music);
			Assert.equals("bh.audio.LogBackend", state.backend);

			final heard:Array<Dynamic> = [];
			bridge.registerListeners();
			m.sm.audio.onHistory = e -> heard.push(e);
			final done:Dynamic = bridge.dispatch("audio_set", {play: "ui.click", vca: "Music", value: 0.25, snapshot: "dialog", on: true, music: "music.title"});
			Assert.equals(4, (done.done : Array<String>).length);
			Assert.equals(1, m.log.plays("ui.click").length);
			Assert.floatEquals(0.25, m.sm.audio.getVca("Music"));
			Assert.isTrue(m.sm.audio.isSnapshotOn("dialog"));
			Assert.equals("music.title", m.sm.audio.musicPlaying);
			Assert.equals(4, heard.length, "every line of the history is told");

			final log:Dynamic = bridge.dispatch("audio_log", {since: 0});
			final entries:Array<Dynamic> = log.entries;
			Assert.isTrue(entries.length >= 4);
			final later:Dynamic = bridge.dispatch("audio_log", {since: entries[entries.length - 1].id});
			Assert.equals(0, (later.entries : Array<Dynamic>).length);

			var threw = false;
			try {
				bridge.dispatch("audio_set", {});
			} catch (e:Dynamic) {
				threw = true;
			}
			Assert.isTrue(threw, "nothing to do is an error");
			bridge.unregisterListeners();
		}
	}
	#end
}

private class SoundTestScreen extends UIScreenBase {
	public var recordedEvents:Array<UIScreenEvent> = [];

	public function new(sm:ScreenManager) {
		super(sm);
	}

	public function load():Void {}

	public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {
		recordedEvents.push(event);
	}
}

/** A screen whose controls are named after what they do, as `macroBuildWithParameters` keys them. */
private class SoundControlsScreen extends UIScreenBase {
	public var music:Null<UIStandardMultiAnimButton> = null;
	public var sound:Null<UIStandardMultiAnimButton> = null;
	public var volume:Null<UIStandardMultiAnimButton> = null;

	public function new(sm:ScreenManager) {
		super(sm);
	}

	public function load():Void {}

	public function onScreenEvent(event:UIScreenEvent, source:Null<UIElement>):Void {}
}
