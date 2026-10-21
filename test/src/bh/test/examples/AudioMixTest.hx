package bh.test.examples;

import utest.Assert;
import bh.audio.Audio;
import bh.audio.LogBackend;
import bh.base.Clock;
import bh.base.ResourceLoader.CachingResourceLoader;
import bh.multianim.MultiAnimParser;
import bh.test.BuilderTestBase;
import bh.ui.screens.ScreenManager;
import haxe.io.Bytes;

/**
 * The mix: the `#name mix { }` block (buses, VCAs, snapshots), blended into one state per bus
 * on the backend, and the clock putting the `paused` snapshot on and pitching a `pitch clock` bus.
 */
class AudioMixTest extends utest.Test {
	static final MIX = '
		#main mix {
			bus music
			bus sfx { voices: 24 }
			bus ui
			vca Music: music
			vca Effects: sfx, ui
			snapshot paused { sfx: pause, ui: pause, music: -6db lowpass 0.3, fade: 200ms }
			snapshot dialog { music: -6db, fade: 100ms }
			snapshot slow { sfx: pitch clock  music: lowpass 0.5 }
		}
		#fx sounds {
			bus: sfx
			hit { file: "sound/hit.wav" }
			tune { file: "sound/tune.wav", bus: music }
		}
	';

	function mix():MixDef {
		return BuilderTestBase.builderFromSource(MIX).buildMix("main");
	}

	function audio():{audio:Audio, log:LogBackend} {
		final log = new LogBackend();
		final a = new Audio(log);
		a.randomFunc = () -> 0.0;
		final builder = BuilderTestBase.builderFromSource(MIX);
		a.addBanks(builder);
		log.clear();
		return {audio: a, log: log};
	}

	static function last(log:LogBackend, bus:String):Null<bh.audio.LogBackend.AudioLogEntry> {
		final lines = log.busLines(bus);
		return lines.length == 0 ? null : lines[lines.length - 1];
	}

	// ==================== The block ====================

	@Test
	public function testParsesAMixBlock():Void {
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess(MIX));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#m mix { bus sfx }'));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#m mix { bus a; bus b { voices: 4 }; vca All: a, b; snapshot s { a: -3db, b: pause -6db lowpass 0.2 pitch clock } }'));
	}

	@Test
	public function testWhatAMixBlockRefuses():Void {
		function refused(src:String, why:String, ?says:String):Void {
			final error = BuilderTestBase.parseExpectingError(src);
			Assert.notNull(error, why);
			if (error != null && says != null)
				Assert.isTrue(error.indexOf(says) >= 0, '$why: the error says "$says": $error');
		}
		refused('mix { bus a }', "no #name");
		refused('#p programmable() { #m mix { bus a } }', "inside a programmable", "root");
		refused('#m mix { }', "no buses", "bus");
		refused('#m mix { bus a  bus a }', "a bus twice", "twice");
		refused('#m mix { bus a { wobble: 3 } }', "an unknown bus key", "voices");
		refused('#m mix { bus a  vca V: b }', "a vca over a bus the mix has not", "no bus b");
		refused('#m mix { bus a  vca V: a  vca V: a }', "a vca twice", "twice");
		refused('#m mix { bus a  snapshot s { b: -3db } }', "a snapshot on a bus the mix has not", "no bus b");
		refused('#m mix { bus a  snapshot s { a: louder } }', "an unknown change", "pause");
		refused('#m mix { bus a  snapshot s { a: lowpass 3 } }', "a low-pass share over 1", "0 to 1");
		refused('#m mix { bus a  snapshot s { a: pitch up } }', "pitch without clock", "clock");
		refused('#m mix { bus a  snapshot s { fade: 100ms } }', "a snapshot changing no bus", "no bus");
		refused('#m mix { bus a  snapshot s { a: -3db }  snapshot s { a: -3db } }', "a snapshot twice", "twice");
		refused('#m mix { bus a  snapshot s { a: 3ms } }', "a level in ms", "db");
		refused('#m mix { bus a  cymbal x }', "an unknown entry", "bus, vca or snapshot");
	}

	@Test
	public function testBuildMixGivesTheBlockAsWritten():Void {
		final def = mix();
		Assert.same(["music", "sfx", "ui"], [for (b in def.buses) b.name]);
		Assert.equals(24, def.buses[1].voices);
		Assert.equals(0, def.buses[0].voices, "no limit");
		Assert.equals(2, def.vcas.length);
		Assert.equals("Effects", def.vcas[1].name);
		Assert.same(["sfx", "ui"], def.vcas[1].buses);
		Assert.equals(3, def.snapshots.length);
		final paused = def.snapshots[0];
		Assert.equals("paused", paused.name);
		Assert.floatEquals(0.2, paused.fade);
		Assert.equals(3, paused.buses.length);
		Assert.isTrue(paused.buses[0].changes[0].match(ChangePause));
		Assert.equals("music", paused.buses[2].bus);
		Assert.isTrue(paused.buses[2].changes[0].match(ChangeVolume(-6)));
		Assert.isTrue(paused.buses[2].changes[1].match(ChangeLowPass(0.3)));
		Assert.floatEquals(0.1, def.snapshots[1].fade);
		Assert.isTrue(def.snapshots[2].buses[0].changes[0].match(ChangePitchClock));
		Assert.floatEquals(0, def.snapshots[2].fade, "no fade: at once");
		final builder = BuilderTestBase.builderFromSource(MIX);
		Assert.same(["main"], builder.mixBlockNames());
	}

	// ==================== The service ====================

	@Test
	public function testAMixSetsEveryBusOnce():Void {
		final log = new LogBackend();
		final a = new Audio(log);
		a.addMix("main", mix());
		Assert.isTrue(a.hasMix());
		Assert.same(["music", "sfx", "ui"], a.busNames());
		Assert.same(["Music", "Effects"], a.vcaNames());
		Assert.same(["paused", "dialog", "slow"], a.snapshotNames());
		Assert.equals(4, log.busLines().length, "the three buses and the default one");
		final sfx = last(log, "sfx");
		Assert.equals(24, sfx.voices, "the bus's voices reach the backend");
		Assert.floatEquals(1, sfx.volume);
		Assert.isFalse(sfx.paused);
		Assert.isNull(sfx.lowpass);
		Assert.floatEquals(1, sfx.pitch);
		Assert.equals(0, last(log, "").voices);
		Assert.equals(0, a.snapshotsOnNow().length);
	}

	@Test
	public function testASnapshotFadesInAndOut():Void {
		final a = audio();
		a.audio.snapshot("dialog", true);
		Assert.isTrue(a.audio.isSnapshotOn("dialog"));
		var music = last(a.log, "music");
		Assert.floatEquals(Math.pow(10, -6 / 20), music.volume, 0.0001, "-6 dB");
		Assert.floatEquals(0.1, music.fade, "over the snapshot's fade");
		Assert.equals(1, a.log.busLines().length, "only the bus it changes is set");
		a.audio.snapshot("dialog", true);
		Assert.equals(1, a.log.busLines().length, "already on: nothing");
		a.audio.snapshot("dialog", false);
		music = last(a.log, "music");
		Assert.floatEquals(1, music.volume, "back to 1");
		Assert.floatEquals(0.1, music.fade, "over the same fade");
		Assert.isFalse(a.audio.isSnapshotOn("dialog"));
	}

	@Test
	public function testSnapshotsOnAreSummed():Void {
		final a = audio();
		a.audio.snapshot("dialog", true);
		a.audio.snapshot("paused", true);
		final music = last(a.log, "music");
		Assert.floatEquals(Math.pow(10, -12 / 20), music.volume, 0.0001, "-6 and -6 dB");
		Assert.floatEquals(0.3, music.lowpass, "the paused snapshot's low-pass");
		Assert.isFalse(music.paused, "music is not paused by either");
		Assert.isTrue(last(a.log, "sfx").paused);
		Assert.isTrue(last(a.log, "ui").paused);
		Assert.same(["dialog", "paused"], a.audio.snapshotsOnNow());
		a.audio.snapshot("slow", true);
		Assert.floatEquals(0.3, last(a.log, "music").lowpass, "the lowest low-pass wins");
		a.audio.snapshot("paused", false);
		Assert.floatEquals(0.5, last(a.log, "music").lowpass, "slow's remains");
		Assert.isFalse(last(a.log, "sfx").paused);
	}

	@Test
	public function testAVcaMultipliesIntoEveryBusItNames():Void {
		final a = audio();
		Assert.floatEquals(1, a.audio.getVca("Effects"));
		a.audio.setVca("Effects", 0.5);
		Assert.floatEquals(0.5, last(a.log, "sfx").volume);
		Assert.floatEquals(0.5, last(a.log, "ui").volume);
		Assert.isNull(last(a.log, "music"), "not music");
		Assert.floatEquals(0, last(a.log, "sfx").fade, "a slider moves it at once");
		a.audio.snapshot("dialog", true);
		a.audio.setVca("Music", 0.5);
		Assert.floatEquals(0.5 * Math.pow(10, -6 / 20), last(a.log, "music").volume, 0.0001, "the VCA and the snapshot multiply");
		a.audio.setVca("Music", 2);
		Assert.floatEquals(1, a.audio.getVca("Music"), "held to 0..1");
		var said = "";
		try {
			a.audio.setVca("Voice", 1);
		} catch (e:String) {
			said = e;
		}
		Assert.isTrue(said.indexOf("Music, Effects") >= 0, 'a VCA the mix has not: $said');
	}

	@Test
	public function testTheSameMixTakenAgainKeepsItsLevelsAndSnapshots():Void {
		final a = audio();
		a.audio.setVca("Effects", 0.4);
		a.audio.setVca("Music", 0.7);
		a.audio.snapshot("dialog", true);
		a.audio.snapshot("slow", true);
		// the block again, as a reload writes it: Music and slow are gone, Voice and combat are new
		final again = BuilderTestBase.builderFromSource('#main mix { bus music  bus sfx  bus ui  vca Effects: sfx, ui  vca Voice: ui  snapshot dialog { music: -6db, fade: 100ms }  snapshot combat { sfx: -3db } }')
			.buildMix("main");
		a.log.clear();
		a.audio.addMix("main", again);
		Assert.same(["Effects", "Voice"], a.audio.vcaNames());
		Assert.floatEquals(0.4, a.audio.getVca("Effects"), "a VCA it still has keeps its level");
		Assert.floatEquals(1, a.audio.getVca("Voice"), "a new one starts at 1");
		Assert.same(["dialog"], a.audio.snapshotsOnNow(), "a snapshot on that it still has stays on; slow is gone");
		Assert.floatEquals(0.4, last(a.log, "sfx").volume, 0.0001, "the backend hears the kept level");
		Assert.floatEquals(Math.pow(10, -6 / 20), last(a.log, "music").volume, 0.0001, "and the kept snapshot");
		a.audio.addMix("other", again);
		Assert.floatEquals(1, a.audio.getVca("Effects"), "another block starts every VCA at 1");
		Assert.equals(0, a.audio.snapshotsOnNow().length, "with no snapshot on");
	}

	@Test
	public function testAnUnknownSnapshotIsAnError():Void {
		final a = audio();
		var said = "";
		try {
			a.audio.snapshot("combat", true);
		} catch (e:String) {
			said = e;
		}
		Assert.isTrue(said.indexOf("paused, dialog, slow") >= 0, said);
	}

	@Test
	public function testTheClockPutsThePausedSnapshotOnAndOff():Void {
		final a = audio();
		final clock = new Clock();
		a.audio.clock = clock;
		Assert.equals(0, a.log.busLines().length, "a running clock changes nothing");
		clock.paused = true;
		Assert.isTrue(a.audio.isSnapshotOn("paused"));
		Assert.isTrue(last(a.log, "sfx").paused);
		Assert.floatEquals(Math.pow(10, -6 / 20), last(a.log, "music").volume, 0.0001);
		Assert.floatEquals(0.2, last(a.log, "music").fade);
		clock.paused = false;
		Assert.isFalse(a.audio.isSnapshotOn("paused"));
		Assert.isFalse(last(a.log, "sfx").paused);
		Assert.floatEquals(1, last(a.log, "music").volume);
	}

	@Test
	public function testAPausedBusHoldsItsPlaysWhereTheyAre():Void {
		final a = audio();
		final clock = new Clock();
		a.audio.clock = clock;
		final play = a.audio.play("fx.hit");
		a.audio.update(0.5);
		clock.paused = true;
		a.audio.update(2.0);
		Assert.isTrue(play.isAlive(), "frozen half way, two seconds later still there");
		clock.paused = false;
		a.audio.update(0.4);
		Assert.isTrue(play.isAlive(), "0.9 of its second played");
		a.audio.update(0.2);
		Assert.isFalse(play.isAlive(), "over");
	}

	@Test
	public function testWithoutAPausedSnapshotTheClockPausesEveryBus():Void {
		final log = new LogBackend();
		final a = new Audio(log);
		a.addBanks(BuilderTestBase.builderFromSource('
			#m mix { bus sfx  bus music }
			#fx sounds { bus: sfx  hit { file: "sound/hit.wav" } }
		'));
		final clock = new Clock();
		a.clock = clock;
		log.clear();
		clock.paused = true;
		Assert.isTrue(last(log, "sfx").paused);
		Assert.isTrue(last(log, "music").paused);
		Assert.isTrue(last(log, "").paused, "the sounds that name no bus too");
		clock.paused = false;
		Assert.isFalse(last(log, "sfx").paused);
	}

	@Test
	public function testTheClockPausesEvenWithNoMix():Void {
		final log = new LogBackend();
		final a = new Audio(log);
		a.addBank("fx", BuilderTestBase.builderFromSource('#fx sounds { hit { file: "sound/hit.wav" }  tune { file: "sound/tune.wav", bus: music } }').buildSounds("fx"));
		final clock = new Clock();
		a.clock = clock;
		log.clear();
		clock.paused = true;
		Assert.isTrue(last(log, "").paused);
		Assert.isTrue(last(log, "music").paused, "a bus a sound names is known to the backend");
	}

	@Test
	public function testPitchClockFollowsTheClocksScale():Void {
		final a = audio();
		final clock = new Clock();
		a.audio.clock = clock;
		clock.scale = 0.5;
		Assert.isNull(last(a.log, "sfx"), "slow is not on: nothing");
		a.audio.snapshot("slow", true);
		Assert.floatEquals(0.5, last(a.log, "sfx").pitch, "pitched with the clock");
		clock.scale = 2;
		Assert.floatEquals(2, last(a.log, "sfx").pitch);
		clock.scale = 0;
		Assert.floatEquals(Audio.MIN_PITCH, last(a.log, "sfx").pitch, "never 0, which no driver takes");
		a.audio.snapshot("slow", false);
		Assert.floatEquals(1, last(a.log, "sfx").pitch);
		Assert.floatEquals(1, last(a.log, "music").volume, "slow changed only music's low-pass");
		Assert.isNull(last(a.log, "music").lowpass);
	}

	@Test
	public function testAScreenManagersClockReachesItsAudio():Void {
		final sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		final log = new LogBackend();
		sm.audio.backend = log;
		sm.buildFromResourceName("sounds-block.manim", false);
		Assert.isTrue(sm.audio.hasMix(), "the file's mix block");
		Assert.same(["music", "sfx", "ui"], sm.audio.busNames());
		log.clear();
		sm.clock.paused = true;
		Assert.isTrue(sm.audio.isSnapshotOn("paused"));
		Assert.isTrue(last(log, "sfx").paused);
		sm.clock.paused = false;
		Assert.isFalse(sm.audio.isSnapshotOn("paused"));
		sm.audio.setVca("Music", 0.25);
		Assert.floatEquals(0.25, last(log, "music").volume);
		sm.dispose();
	}

	#if hldx
	static function silentWav(seconds:Float):Bytes {
		final rate = 8000;
		final out = new haxe.io.BytesOutput();
		new format.wav.Writer(out).write({
			header: {format: WF_PCM, channels: 1, samplingRate: rate, byteRate: rate * 2, blockAlign: 2, bitsPerSample: 16},
			data: Bytes.alloc(Std.int(rate * seconds) * 2),
			cuePoints: null
		});
		return out.getBytes();
	}

	@Test
	public function testTheHeapsBackendSetsABus():Void {
		// Only where a device may be (the local DirectX build); with no driver Heaps plays virtually.
		final loader = new CachingResourceLoader();
		loader.loadHXDResourceImpl = name -> hxd.res.Any.fromBytes(name, silentWav(0.5));
		final backend = new bh.audio.HeapsBackend(loader);
		try {
			final voice:Dynamic = backend.play({
				sound: "t.beep", layer: "", path: "sound/beep.wav", volume: 1, pitch: 1.1, bus: "sfx", priority: 1, fadeIn: 0, loop: false
			});
			final channel:hxd.snd.Channel = @:privateAccess voice.channel;
			backend.setBus("sfx", {volume: 0.5, fade: 0, paused: true, lowpass: 0.3, pitch: 2, voices: 4});
			Assert.floatEquals(0.5, backend.group("sfx").volume);
			Assert.isTrue(channel.pause, "its plays are frozen");
			Assert.notNull(backend.lowPass("sfx"), "a low-pass on the group");
			Assert.floatEquals(0.3, backend.lowPass("sfx").gainHF);
			Assert.equals(4, backend.soundGroup("sfx").maxAudible);
			final pitch = channel.getEffect(hxd.snd.effect.Pitch);
			Assert.notNull(pitch);
			Assert.floatEquals(2.2, pitch.value, 0.0001, "the bus's pitch multiplies the play's own");
			backend.setBus("sfx", {volume: 1, fade: 0.1, paused: false, lowpass: null, pitch: 1, voices: 0});
			Assert.isFalse(channel.pause);
			Assert.isNull(backend.lowPass("sfx"), "taken off");
			Assert.equals(-1, backend.soundGroup("sfx").maxAudible, "no limit");
			Assert.floatEquals(1.1, pitch.value, 0.0001);
			voice.stop(0);
		} catch (e:Dynamic) {
			Assert.pass('no audio device here: $e');
		}
	}
	#end
}
