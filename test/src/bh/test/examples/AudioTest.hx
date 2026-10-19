package bh.test.examples;

import utest.Assert;
import bh.audio.Audio;
import bh.audio.LogBackend;
import bh.base.ResourceLoader.CachingResourceLoader;
import bh.multianim.MultiAnimParser;
import bh.test.BuilderTestBase;
import bh.ui.screens.ScreenManager;
import haxe.io.Bytes;

/**
 * Sounds played by name: the `#name sounds { }` block (parsed, built), and the `Audio` service
 * on the log backend: picks, rolls, voices and stealing, cooldowns, layers with delay and chance,
 * variants by a parameter, banks taken as a file loads.
 */
class AudioTest extends utest.Test {
	static final BANK = '
		#fx sounds {
			bus: sfx
			param surface: [stone, grass]

			coin { file: "sound/coin.wav", bus: ui }
			hit { files: ["sound/hit_1.wav", "sound/hit_2.wav", "sound/hit_3.wav"], pick: shuffle,
				volume: -5db..-1db, pitch: -5%..5%, voices: 3, steal: none, cooldown: 30ms, priority: high }
			tick { file: "sound/tick.wav", cooldown: 30ms }
			step @(surface => stone) { files: ["sound/step_stone_1.wav", "sound/step_stone_2.wav"], pick: turn }
			step @(surface => grass) { file: "sound/step_grass.wav" }
			step { file: "sound/step_any.wav" }
			explosion {
				voices: 2, steal: oldest, fade: out 300ms
				layer boom { files: ["sound/boom_1.wav", "sound/boom_2.wav"], pick: random }
				layer debris { file: "sound/debris.wav", delay: 40..120ms, chance: 70% }
				layer never { file: "sound/never.wav", chance: 0% }
			}
			swell { file: "sound/swell.wav", fade: in 20ms out 1s, voices: 1, steal: quietest }
			quiet { file: "sound/quiet.wav", volume: -20db, voices: 2, steal: quietest }
		}
	';

	function bank():SoundsDef {
		return BuilderTestBase.builderFromSource(BANK).buildSounds("fx");
	}

	function audio(?log:LogBackend):{audio:Audio, log:LogBackend} {
		final l = log ?? new LogBackend();
		final a = new Audio(l);
		a.randomFunc = () -> 0.0;
		a.addBank("fx", bank());
		return {audio: a, log: l};
	}

	/** Rolls given in turn, round and round. */
	static function rolls(values:Array<Float>):() -> Float {
		var i = 0;
		return () -> values[(i++) % values.length];
	}

	// ==================== The block ====================

	@Test
	public function testParsesASoundsBlock():Void {
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess(BANK));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#ui sounds { click { file: "a.wav" } }'));
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess('#ui sounds { click { file: "a.wav" }; hover { file: "b.wav", volume: -6db, pitch: 1.1 } }'));
	}

	@Test
	public function testWhatASoundsBlockRefuses():Void {
		function refused(src:String, why:String, ?says:String):Void {
			final error = BuilderTestBase.parseExpectingError(src);
			Assert.notNull(error, why);
			if (error != null && says != null)
				Assert.isTrue(error.indexOf(says) >= 0, '$why: the error says "$says": $error');
		}
		refused('sounds { a { file: "a.wav" } }', "no #name");
		refused('#p programmable() { #s sounds { a { file: "a.wav" } } }', "inside a programmable", "root");
		refused('#s sounds { }', "empty");
		refused('#s sounds { a { } }', "a sound with no file", "no file");
		refused('#s sounds { a { file: "a.wav", wobble: 3 } }', "an unknown key", "wobble");
		refused('#s sounds { a { file: "a.wav"  layer b { file: "b.wav" } } }', "own files and layers", "not both");
		refused('#s sounds { a { file: "a.wav" }  a { file: "b.wav" } }', "a sound twice", "twice");
		refused('#s sounds { a @(surface => stone) { file: "a.wav" } }', "a variant on a param the block has not", "param");
		refused('#s sounds { param surface: [stone]  a @(surface => mud) { file: "a.wav" } }', "a label the param has not");
		refused('#s sounds { a { file: "a.wav", volume: 3ms } }', "a volume in ms", "db");
		refused('#s sounds { a { file: "a.wav", volume: -1db..-5db } }', "a range high to low", "low to high");
		refused('#s sounds { a { file: "a.wav", delay: 10ms } }', "a delay on a sound's own files", "layer");
		refused('#s sounds { a { file: "a.wav", chance: 150% } }', "odds over 100%");
		refused('#s sounds { a { file: "a.wav", steal: newest } }', "an unknown steal", "oldest");
		refused('#s sounds { a { file: "a.wav", fade: 20ms } }', "a fade without in or out", "in");
		refused('#s sounds { a { layer b { file: "b.wav" } volume: -3db } }', "volume beside layers", "layers");
	}

	@Test
	public function testBuildSoundsGivesTheBlockAsWritten():Void {
		final def = bank();
		Assert.equals("sfx", def.bus);
		Assert.equals(1, def.params.length);
		Assert.equals("surface", def.params[0].name);
		Assert.same(["stone", "grass"], def.params[0].values);
		Assert.equals(9, def.sounds.length);

		final coin = def.sounds[0];
		Assert.equals("coin", coin.name);
		Assert.equals("ui", coin.bus, "its own bus");
		Assert.equals(1, coin.layers.length);
		Assert.equals("", coin.layers[0].name, "its own files are one unnamed layer");
		Assert.same(["sound/coin.wav"], coin.layers[0].files);
		Assert.equals(0, coin.voices, "no limit");
		Assert.isTrue(coin.conditional.match(NoConditional));

		final hit = def.sounds[1];
		Assert.isNull(hit.bus, "the block's bus");
		Assert.equals(3, hit.layers[0].files.length);
		Assert.isTrue(hit.layers[0].pick.match(PickShuffle));
		Assert.floatEquals(-5, hit.layers[0].volumeMinDb);
		Assert.floatEquals(-1, hit.layers[0].volumeMaxDb);
		Assert.floatEquals(0.95, hit.layers[0].pitchMin);
		Assert.floatEquals(1.05, hit.layers[0].pitchMax);
		Assert.equals(3, hit.voices);
		Assert.isTrue(hit.steal.match(StealNone));
		Assert.floatEquals(0.03, hit.cooldown, "30ms in seconds");
		Assert.floatEquals(2, hit.priority, "high");

		final stone = def.sounds[3];
		Assert.equals("step", stone.name);
		Assert.isTrue(stone.conditional.match(Conditional(_, false)), "a variant");
		Assert.isTrue(stone.layers[0].pick.match(PickTurn));
		Assert.isTrue(def.sounds[5].conditional.match(NoConditional), "the default step");

		final explosion = def.sounds[6];
		Assert.equals(3, explosion.layers.length);
		Assert.equals("boom", explosion.layers[0].name);
		Assert.floatEquals(0.04, explosion.layers[1].delayMin);
		Assert.floatEquals(0.12, explosion.layers[1].delayMax);
		Assert.floatEquals(0.7, explosion.layers[1].chance);
		Assert.floatEquals(0, explosion.layers[2].chance);
		Assert.isTrue(explosion.steal.match(StealOldest));
		Assert.floatEquals(0.3, explosion.fadeOut);
		Assert.floatEquals(0, explosion.fadeIn);

		final swell = def.sounds[7];
		Assert.floatEquals(0.02, swell.fadeIn);
		Assert.floatEquals(1, swell.fadeOut, "1s");
		Assert.isTrue(swell.steal.match(StealQuietest));

		final builder = BuilderTestBase.builderFromSource(BANK);
		Assert.same(["fx"], builder.soundBlockNames());
	}

	// ==================== The service ====================

	@Test
	public function testABankPreparesEveryFileAndNamesItsSounds():Void {
		final a = audio();
		Assert.isTrue(a.log.prepared.contains("sound/coin.wav"));
		Assert.isTrue(a.log.prepared.contains("sound/hit_3.wav"));
		Assert.isTrue(a.log.prepared.contains("sound/step_grass.wav"));
		Assert.equals(a.log.prepared.length, Lambda.count(a.log.prepared), "once each");
		Assert.same(["fx"], a.audio.bankNames());
		Assert.same(["fx.coin", "fx.explosion", "fx.hit", "fx.quiet", "fx.step", "fx.swell", "fx.tick"], a.audio.soundNames());
		Assert.isTrue(a.audio.has("fx.step"));
		Assert.isFalse(a.audio.has("fx.nope"));
	}

	@Test
	public function testASoundPlaysOnItsBusAtItsVolume():Void {
		final a = audio();
		final play = a.audio.play("fx.coin");
		Assert.notNull(play);
		Assert.equals(1, a.log.plays().length);
		final e = a.log.plays()[0];
		Assert.equals("fx.coin", e.sound);
		Assert.equals("sound/coin.wav", e.path);
		Assert.equals("ui", e.bus, "the sound's own bus");
		Assert.floatEquals(1, e.volume, "0 dB");
		Assert.floatEquals(1, e.pitch);
		a.audio.play("fx.tick");
		Assert.equals("sfx", a.log.plays("fx.tick")[0].bus, "the block's bus");
	}

	@Test
	public function testAnUnknownSoundIsAnError():Void {
		final a = audio();
		var said = "";
		try {
			a.audio.play("fx.nope");
		} catch (e:String) {
			said = e;
		}
		Assert.isTrue(said.indexOf("fx.nope") >= 0, said);
		Assert.isTrue(said.indexOf("fx.coin") >= 0, "and lists what there is");
	}

	@Test
	public function testVolumeAndPitchAreRolledBetweenTheirEnds():Void {
		final a = audio();
		a.audio.randomFunc = rolls([0.0, 1.0]);
		// hit: shuffle pick (one roll), volume roll, pitch roll
		a.audio.play("fx.hit");
		a.audio.update(0.1);
		a.audio.play("fx.hit");
		final plays = a.log.plays("fx.hit");
		Assert.equals(2, plays.length);
		// first play: pick 0.0, volume 1.0 (-1 dB), pitch 0.0 (0.95); second: pick 1.0, volume 0.0 (-5 dB), pitch 1.0 (1.05)
		Assert.floatEquals(Math.pow(10, -1 / 20), plays[0].volume, 0.0001, "-1 dB");
		Assert.floatEquals(0.95, plays[0].pitch, 0.0001);
		Assert.floatEquals(Math.pow(10, -5 / 20), plays[1].volume, 0.0001, "-5 dB");
		Assert.floatEquals(1.05, plays[1].pitch, 0.0001);
	}

	@Test
	public function testThirtyHitsInAFrameAreThreeSounds():Void {
		// voices: 3, steal: none, cooldown: 30ms, so one hit a frame at most and never more than three alive
		final a = audio();
		var played = 0;
		for (_ in 0...30)
			if (a.audio.play("fx.hit") != null)
				played++;
		Assert.equals(1, played, "the cooldown holds the frame to one");
		Assert.equals(1, a.log.plays("fx.hit").length);
		// across frames, every 40 ms, the voices limit holds at three alive (a file plays a second)
		for (_ in 0...10) {
			a.audio.update(0.04);
			a.audio.play("fx.hit");
		}
		Assert.equals(3, a.log.plays("fx.hit").length, "three voices, the rest dropped");
		Assert.equals(0, a.log.stops().length, "steal: none stops nothing");
		a.audio.update(1.0);
		Assert.notNull(a.audio.play("fx.hit"), "a voice freed, it plays again");
	}

	@Test
	public function testStealOldestStopsTheOldestWithItsFade():Void {
		final a = audio();
		final first = a.audio.play("fx.explosion");
		a.audio.update(0.01);
		final second = a.audio.play("fx.explosion");
		a.audio.update(0.01);
		Assert.equals(2, a.audio.instances.length);
		final third = a.audio.play("fx.explosion");
		Assert.equals(3, a.log.plays("fx.explosion").length);
		final stops = a.log.stops("fx.explosion");
		Assert.equals(1, stops.length, "the oldest stopped");
		Assert.floatEquals(0.3, stops[0].fade, "over the sound's fade out");
		Assert.floatEquals(0.02, stops[0].time, "stopped now");
		Assert.isTrue(first.stopped, "the oldest is the first played");
		Assert.isFalse(second.stopped);
		Assert.isFalse(third.stopped);
		a.audio.update(0.01);
		Assert.equals(2, a.audio.instances.length);
	}

	@Test
	public function testStealQuietestStopsTheQuietest():Void {
		final a = audio();
		a.audio.randomFunc = rolls([0.0]);
		final first = a.audio.play("fx.quiet");
		a.audio.update(0.01);
		final second = a.audio.play("fx.quiet");
		a.audio.update(0.01);
		a.audio.play("fx.quiet");
		// all at -20 dB: the quietest is the first found, the oldest
		Assert.equals(1, a.log.stops("fx.quiet").length);
		Assert.isTrue(first.stopped);
		Assert.isFalse(second.stopped);
	}

	@Test
	public function testShufflePlaysEveryFileBeforeAnyAgain():Void {
		final a = audio();
		a.log.defaultDuration = 0.01; // a hit is over before the next, so its three voices never fill
		a.audio.randomFunc = rolls([0.5, 0.0, 0.9]);
		final seen:Array<String> = [];
		for (_ in 0...6) {
			a.audio.update(0.05);
			a.audio.play("fx.hit");
		}
		for (e in a.log.plays("fx.hit"))
			seen.push(e.path);
		Assert.equals(6, seen.length);
		final first = seen.slice(0, 3);
		final second = seen.slice(3, 6);
		first.sort(Reflect.compare);
		second.sort(Reflect.compare);
		Assert.same(["sound/hit_1.wav", "sound/hit_2.wav", "sound/hit_3.wav"], first, "the first round is every file once");
		Assert.same(["sound/hit_1.wav", "sound/hit_2.wav", "sound/hit_3.wav"], second, "and so is the second");
	}

	@Test
	public function testTurnPlaysTheFilesInOrder():Void {
		final a = audio();
		a.audio.set("surface", "stone");
		for (_ in 0...3)
			a.audio.play("fx.step");
		final paths = [for (e in a.log.plays("fx.step")) e.path];
		Assert.same(["sound/step_stone_1.wav", "sound/step_stone_2.wav", "sound/step_stone_1.wav"], paths);
	}

	@Test
	public function testAVariantIsChosenByTheParameter():Void {
		final a = audio();
		Assert.equals("stone", a.audio.get("surface"), "the first label to begin with");
		a.audio.play("fx.step");
		a.audio.set("surface", "grass");
		a.audio.play("fx.step");
		final paths = [for (e in a.log.plays("fx.step")) e.path];
		Assert.same(["sound/step_stone_1.wav", "sound/step_grass.wav"], paths);

		var said = "";
		try {
			a.audio.set("surface", "mud");
		} catch (e:String) {
			said = e;
		}
		Assert.isTrue(said.indexOf("stone, grass") >= 0, 'a label the param has not: $said');
		said = "";
		try {
			a.audio.set("weather", "rain");
		} catch (e:String) {
			said = e;
		}
		Assert.isTrue(said.indexOf("weather") >= 0, 'a param no block declares: $said');
	}

	@Test
	public function testTheDefaultVariantPlaysWhenNoneMatches():Void {
		final a = new Audio(new LogBackend());
		a.randomFunc = () -> 0.0;
		a.addBank("v", BuilderTestBase.builderFromSource('
			#v sounds {
				param mood: [calm, angry, sad]
				bark @(mood => angry) { file: "sound/bark_angry.wav" }
				bark { file: "sound/bark.wav" }
				growl @(mood => angry) { file: "sound/growl.wav" }
			}
		').buildSounds("v"));
		final log:LogBackend = cast a.backend;
		a.play("v.bark");
		a.set("mood", "angry");
		a.play("v.bark");
		Assert.same(["sound/bark.wav", "sound/bark_angry.wav"], [for (e in log.plays("v.bark")) e.path]);
		Assert.notNull(a.play("v.growl"));
		a.set("mood", "sad");
		Assert.isNull(a.play("v.growl"), "no variant matches and there is no default: nothing plays");
		Assert.equals(1, log.plays("v.growl").length);
	}

	@Test
	public function testLayersStartTogetherAfterTheirDelaysByTheirOdds():Void {
		final a = audio();
		// rolls, only where there is a range or a choice: boom's pick, debris' chance, debris' delay, never's chance
		a.audio.randomFunc = rolls([0.0, 0.5, 0.5, 0.0]);
		final play = a.audio.play("fx.explosion");
		Assert.notNull(play);
		Assert.equals(1, a.log.plays("fx.explosion").length, "the boom at once");
		Assert.equals("boom", a.log.plays("fx.explosion")[0].layer);
		Assert.equals(1, play.pending, "the debris waits for its delay");
		Assert.isTrue(play.isAlive());
		a.audio.update(0.05);
		Assert.equals(1, a.log.plays("fx.explosion").length, "not yet: the delay rolled 80 ms");
		a.audio.update(0.05);
		Assert.equals(2, a.log.plays("fx.explosion").length, "the debris after its delay");
		Assert.equals("debris", a.log.plays("fx.explosion")[1].layer);
		Assert.floatEquals(0.1, a.log.plays("fx.explosion")[1].time, 0.0001);
		Assert.equals(0, play.pending);
		a.audio.update(2.0);
		Assert.equals(2, a.log.plays("fx.explosion").length, "chance: 0% never plays");
		Assert.isFalse(play.isAlive(), "over once every file has played out");
		Assert.equals(0, a.audio.instances.length);
	}

	@Test
	public function testAChanceOfSeventyPercentIsMissedByARollAbove():Void {
		final a = audio();
		a.audio.randomFunc = rolls([0.0, 0.8, 0.0]); // boom's pick, debris' chance, never's chance
		a.audio.play("fx.explosion");
		a.audio.update(1.0);
		Assert.equals(1, a.log.plays("fx.explosion").length, "the debris rolled 0.8 against 70%");
	}

	// ==================== A held sound ====================

	static final HELD = '
		#eng sounds {
			bus: sfx
			hum { file: "sound/hum.wav", loop: yes, voices: 1, steal: none }
			engine {
				voices: 2, fade: out 200ms
				layer start { file: "sound/engine_start.wav" }
				layer hum   { file: "sound/engine_hum.wav", loop: yes, delay: 300ms }
				layer stop  { file: "sound/engine_off.wav", on: stop }
			}
		}
	';

	function held():{audio:Audio, log:LogBackend} {
		final l = new LogBackend();
		final a = new Audio(l);
		a.randomFunc = () -> 0.0;
		a.addBank("eng", BuilderTestBase.builderFromSource(HELD).buildSounds("eng"));
		return {audio: a, log: l};
	}

	static function stopLayerPlays(log:LogBackend):Array<bh.audio.LogBackend.AudioLogEntry> {
		return log.plays("eng.engine").filter(p -> p.layer == "stop");
	}

	@Test
	public function testParsesAHeldSound():Void {
		Assert.isTrue(BuilderTestBase.parseExpectingSuccess(HELD));
		final def = BuilderTestBase.builderFromSource(HELD).buildSounds("eng");
		Assert.isTrue(def.sounds[0].layers[0].loop, "loop: yes on a sound's own files");
		Assert.isFalse(def.sounds[0].layers[0].onStop);
		final engine = def.sounds[1];
		Assert.isFalse(engine.layers[0].loop);
		Assert.isTrue(engine.layers[1].loop, "the hum loops");
		Assert.isFalse(engine.layers[1].onStop);
		Assert.isTrue(engine.layers[2].onStop, "the stop layer plays as the sound stops");
		Assert.isFalse(engine.layers[2].loop);

		function refused(src:String, why:String, ?says:String):Void {
			final error = BuilderTestBase.parseExpectingError(src);
			Assert.notNull(error, why);
			if (error != null && says != null)
				Assert.isTrue(error.indexOf(says) >= 0, '$why: the error says "$says": $error');
		}
		refused('#s sounds { a { file: "a.wav", on: stop } }', "on: stop on a sound's own files", "layer");
		refused('#s sounds { a { layer b { file: "b.wav", loop: yes, on: stop } } }', "a stop layer that loops", "loop");
		refused('#s sounds { a { layer b { file: "b.wav", on: stop } } }', "nothing but stop layers", "start");
		refused('#s sounds { a { layer b { file: "b.wav", on: later } } }', "an unknown on:", "stop");
		refused('#s sounds { a { file: "a.wav", loop: maybe } }', "a loop that is neither yes nor no");
	}

	@Test
	public function testALoopingSoundPlaysUntilStopped():Void {
		final a = held();
		final hum = a.audio.play("eng.hum");
		Assert.notNull(hum);
		Assert.isTrue(a.log.plays("eng.hum")[0].loop, "the backend is told to loop");
		for (_ in 0...50)
			a.audio.update(0.1);
		Assert.isTrue(hum.isAlive(), "five seconds on, well past the file's second");
		Assert.equals(1, a.audio.instances.length);
		Assert.equals(0, a.log.stops().length);
		Assert.isNull(a.audio.play("eng.hum"), "at its one voice");

		Assert.equals(1, a.audio.stop("eng.hum", 0.5));
		Assert.floatEquals(0.5, a.log.stops("eng.hum")[0].fade);
		Assert.isFalse(hum.isAlive());
		Assert.isFalse(hum.isReleasing(), "no stop layer");
		a.audio.update(0.01);
		Assert.equals(0, a.audio.instances.length, "done at once");
		Assert.notNull(a.audio.play("eng.hum"), "and its voice is free");
	}

	@Test
	public function testAStoppedSoundPlaysItsStopLayer():Void {
		final a = held();
		final engine = a.audio.play("eng.engine");
		Assert.equals(1, a.log.plays("eng.engine").length, "the start layer; the hum waits for its delay");
		a.audio.update(0.4);
		final plays = a.log.plays("eng.engine");
		Assert.equals(2, plays.length);
		Assert.equals("hum", plays[1].layer);
		Assert.isTrue(plays[1].loop);
		Assert.isFalse(plays[0].loop);
		Assert.equals(0, stopLayerPlays(a.log).length, "the stop layer is not played at the start");

		engine.stop();
		Assert.equals(2, a.log.stops("eng.engine").length, "the start and the hum, over the sound's fade out");
		Assert.floatEquals(0.2, a.log.stops("eng.engine")[1].fade);
		final off = stopLayerPlays(a.log);
		Assert.equals(1, off.length, "the stop layer plays as the sound stops");
		Assert.equals("sound/engine_off.wav", off[0].path);
		Assert.isFalse(off[0].loop);
		Assert.isFalse(engine.isAlive());
		Assert.isTrue(engine.isReleasing());
		Assert.equals(1, a.audio.instances.length, "listed while its stop layer plays");
		a.audio.update(0.5);
		Assert.isTrue(engine.isReleasing());
		a.audio.update(0.6);
		Assert.isFalse(engine.isReleasing(), "the stop layer's second is over");
		Assert.equals(0, a.audio.instances.length);
		engine.stop();
		Assert.equals(1, stopLayerPlays(a.log).length, "stopped twice plays the stop layer once");
	}

	@Test
	public function testAStoppingSoundFreesItsVoice():Void {
		final a = held();
		final first = a.audio.play("eng.engine");
		a.audio.update(0.01);
		final second = a.audio.play("eng.engine");
		a.audio.update(0.01);
		first.stop();
		final third = a.audio.play("eng.engine");
		Assert.notNull(third, "two voices: one stopping, one playing, room for one more");
		Assert.isFalse(second.stopped, "nothing stolen");
		Assert.equals(2, a.audio.stop("eng.engine"), "the two alive; the one stopping is not stopped again");
		Assert.equals(0, a.audio.stopAll(), "a stop layer plays on through stopAll: it is the sound's ending");
		Assert.equals(3, stopLayerPlays(a.log).length);
	}

	@Test
	public function testAStolenSoundEndsWithItsStopLayer():Void {
		final a = held();
		a.audio.play("eng.engine");
		a.audio.update(0.01);
		a.audio.play("eng.engine");
		a.audio.update(0.01);
		a.audio.play("eng.engine");
		Assert.equals(1, stopLayerPlays(a.log).length, "the oldest, stolen, ends as a stopped one does");
	}

	@Test
	public function testTheSustainIsDrivenWhileItPlays():Void {
		final a = held();
		final hum = a.audio.play("eng.hum");
		hum.setPitch(1.5);
		hum.setVolume(0.5, 0.1);
		final pitched = a.log.entries.filter(e -> e.kind == "pitch");
		Assert.equals(1, pitched.length);
		Assert.floatEquals(1.5, pitched[0].pitch, "the rolled rate (1) times the one set");
		final volumes = a.log.entries.filter(e -> e.kind == "volume");
		Assert.equals(1, volumes.length);
		Assert.floatEquals(0.5, volumes[0].volume, "the rolled volume (0 dB) times the gain");
		Assert.floatEquals(0.1, volumes[0].fade);
		Assert.floatEquals(0.5, hum.volume, "what steal: quietest compares");
		Assert.floatEquals(1.5, hum.rate);
		Assert.floatEquals(0.5, hum.gain);

		final engine = a.audio.play("eng.engine");
		engine.setPitch(2.0);
		a.audio.update(0.4);
		final late = a.log.entries.filter(e -> e.kind == "pitch" && e.layer == "hum");
		Assert.equals(1, late.length, "the hum, started after its delay, is pitched as it starts");
		Assert.floatEquals(2.0, late[0].pitch);
	}

	@Test
	public function testABankLoadedAgainStopsItsHeldSounds():Void {
		final a = held();
		a.audio.play("eng.hum");
		final engine = a.audio.play("eng.engine");
		a.audio.update(0.4);
		a.audio.addBank("eng", BuilderTestBase.builderFromSource(HELD).buildSounds("eng"));
		Assert.equals(1, a.log.stops("eng.hum").length, "the bank's plays stop as it is taken again");
		Assert.equals(2, a.log.stops("eng.engine").length);
		Assert.equals(0, stopLayerPlays(a.log).length, "cut, not stopped: no stop layer");
		Assert.isFalse(engine.isReleasing());
		a.audio.update(0.01);
		Assert.equals(0, a.audio.instances.length);
		Assert.notNull(a.audio.play("eng.hum"), "the new bank plays");
	}

	@Test
	public function testAnAmbienceIsOneHeldSoundAtATime():Void {
		final a = held();
		Assert.isNull(a.audio.ambiencePlaying);
		a.audio.playAmbience("eng.hum");
		Assert.equals("eng.hum", a.audio.ambiencePlaying);
		Assert.equals(1, a.log.plays("eng.hum").length);
		a.audio.playAmbience("eng.hum");
		Assert.equals(1, a.log.plays("eng.hum").length, "the same one plays on");
		a.audio.playAmbience("eng.engine");
		Assert.equals(1, a.log.stops("eng.hum").length, "another: the hum stops");
		Assert.equals("eng.engine", a.audio.ambiencePlaying);
		a.audio.update(0.4);
		a.audio.stopAmbience();
		Assert.isNull(a.audio.ambiencePlaying);
		Assert.equals(1, stopLayerPlays(a.log).length, "stopped as a sound is, with its stop layer");
		a.audio.stopAmbience();
		Assert.equals(2, a.log.stops("eng.engine").length, "nothing more to stop");
	}

	@Test
	public function testStopFadesEveryPlayOfASoundOut():Void {
		final a = audio();
		a.audio.play("fx.swell");
		Assert.floatEquals(0.02, a.log.plays("fx.swell")[0].fade, "fade: in on the play");
		a.audio.play("fx.coin");
		Assert.equals(1, a.audio.stop("fx.swell"));
		Assert.equals(1, a.log.stops().length);
		Assert.floatEquals(1, a.log.stops()[0].fade, "fade: out 1s");
		Assert.equals(1, a.audio.stop("fx.coin", 0.5), "a fade given wins");
		Assert.floatEquals(0.5, a.log.stops()[1].fade);
		Assert.equals(0, a.audio.stop("fx.coin"), "nothing left to stop");
		a.audio.play("fx.coin");
		a.audio.play("fx.tick");
		Assert.equals(2, a.audio.stopAll(0));
	}

	@Test
	public function testABankLoadedAgainReplacesTheOld():Void {
		final a = audio();
		a.audio.addBank("fx", BuilderTestBase.builderFromSource('#fx sounds { coin { file: "sound/coin2.wav" } }').buildSounds("fx"));
		Assert.same(["fx.coin"], a.audio.soundNames(), "the old sounds are gone");
		a.audio.play("fx.coin");
		Assert.equals("sound/coin2.wav", a.log.plays()[0].path);
		Assert.isTrue(a.audio.removeBank("fx"));
		Assert.isFalse(a.audio.removeBank("fx"));
		Assert.equals(0, a.audio.soundNames().length);
	}

	@Test
	public function testAScreenManagerTakesAFilesBanksAsItLoads():Void {
		final sm = new ScreenManager(bh.test.VisualTestBase.appInstance);
		final log = new LogBackend();
		sm.audio.backend = log;
		sm.audio.randomFunc = () -> 0.0;
		Assert.equals(0, sm.audio.bankNames().length);
		sm.buildFromResourceName("sounds-block.manim", false);
		final banks = sm.audio.bankNames();
		banks.sort(Reflect.compare);
		Assert.same(["amb", "fx", "ui"], banks);
		Assert.isTrue(log.prepared.contains("sound/hover.wav"), "the files were prepared as the file loaded");
		sm.audio.play("ui.hover");
		Assert.floatEquals(Math.pow(10, -6 / 20), log.plays()[0].volume, 0.0001);
		Assert.equals("ui", log.plays()[0].bus);
		sm.audio.play("fx.explosion");
		Assert.equals(1, log.plays("fx.explosion").length, "the debris waits 50 ms");
		sm.update(0.06);
		Assert.equals(2, log.plays("fx.explosion").length, "the screen manager's update steps the audio");
	}

	#if hldx
	/** A 16-bit mono WAV of silence, as an asset pipeline writes one. */
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
	public function testTheHeapsBackendPlaysAChannelOfTheLoadedSound():Void {
		// Only where a device may be (the local DirectX build); CI's build has none. With no driver
		// Heaps plays virtually, which this tolerates: the channel exists either way.
		final loader = new CachingResourceLoader();
		loader.loadHXDResourceImpl = name -> hxd.res.Any.fromBytes(name, silentWav(0.5));
		final backend = new bh.audio.HeapsBackend(loader);
		try {
			backend.prepare("sound/beep.wav");
			final voice = backend.play({
				sound: "t.beep", layer: "", path: "sound/beep.wav", volume: 0.5, pitch: 1.1, bus: "sfx", priority: 1, fadeIn: 0,
				loop: false
			});
			Assert.isTrue(voice.isPlaying(), "a channel, released when the half second is over");
			Assert.floatEquals(0.5, voice.getVolume());
			Assert.notNull(backend.group("sfx"), "a bus is a channel group");
			Assert.equals(backend.group("sfx"), backend.group("sfx"), "made once");
			Assert.equals(bh.audio.HeapsBackend.DEFAULT_BUS, backend.group(null).name, "no bus is the default group");
			voice.stop(0);
			Assert.isFalse(voice.isPlaying());
		} catch (e:Dynamic) {
			Assert.pass('no audio device here: $e');
		}
	}
	#end
}
