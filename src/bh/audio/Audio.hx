package bh.audio;

import bh.audio.AudioBackend;
import bh.base.Clock;
import bh.base.RegisteredNames;
import bh.multianim.MultiAnimBuilder;
import bh.multianim.MultiAnimParser;

/** One parameter of one bank: its labels, in the order written, and the value now. */
private typedef BankParam = {
	final values:Array<String>;
	var value:String;
}

/** One sound of one bank, with what is kept between its plays: the cooldown, the shuffle bags, the turns. */
private class SoundEntry {
	public final block:String;
	public final def:SoundDef;
	public var lastPlay:Null<Float> = null;
	/** Per layer, the files of the shuffle round not yet played. */
	public final bags:Array<Array<String>>;
	/** Per layer, the next file of a `pick: turn`. */
	public final turns:Array<Int>;

	public function new(block:String, def:SoundDef) {
		this.block = block;
		this.def = def;
		bags = [for (_ in def.layers) []];
		turns = [for (_ in def.layers) 0];
	}
}

/** One play of a sound: its voices, started or still to start after a layer's delay, and after
 *  `stop()` its `on: stop` layers' voices (`release`) until they end. A looping sound plays until
 *  stopped; `setPitch` and `setVolume` drive it meanwhile (an engine by its revs and throttle). */
class SoundInstance {
	public final name:String;
	/** The bank it is of: the part of `name` before the dot. */
	public final bank:String;
	public final startedAt:Float;
	/** The loudest layer's volume, linear, times the `gain` set: what `steal: quietest` compares. */
	public var volume(default, null):Float;
	public final fadeOut:Float;
	public var voices(default, null):Array<AudioVoice> = [];
	/** Layers waiting for their delay. */
	public var pending(default, null):Int = 0;
	public var stopped(default, null):Bool = false;
	/** The `on: stop` layers' voices, playing after `stop()`. */
	public var release(default, null):Array<AudioVoice> = [];
	/** Stop layers waiting for their delay. */
	public var releasePending(default, null):Int = 0;
	/** The gain set with `setVolume`, over the rolled volumes; 1 as played. */
	public var gain(default, null):Float = 1;
	/** The rate set with `setPitch`, over the rolled pitches; 1 as played. */
	public var rate(default, null):Float = 1;
	final loudest:Float;
	/** Starts the stop layers; the service sets it when the sound has any. */
	@:allow(bh.audio.Audio) var onStop:Null<SoundInstance->Void> = null;

	public function new(name:String, startedAt:Float, volume:Float, fadeOut:Float) {
		this.name = name;
		final dot = name.indexOf(".");
		this.bank = dot < 0 ? name : name.substr(0, dot);
		this.startedAt = startedAt;
		this.loudest = volume;
		this.volume = volume;
		this.fadeOut = fadeOut;
	}

	/** Playing, or about to: not stopped, with a voice playing or a layer still to start. */
	public function isAlive():Bool {
		if (stopped)
			return false;
		if (pending > 0)
			return true;
		for (v in voices)
			if (v.isPlaying())
				return true;
		return false;
	}

	/** Stopped, with a stop layer still playing or to start. Not alive: its voice is free. */
	public function isReleasing():Bool {
		if (!stopped)
			return false;
		if (releasePending > 0)
			return true;
		for (v in release)
			if (v.isPlaying())
				return true;
		return false;
	}

	/** Neither alive nor releasing: the service forgets it. */
	public function isDone():Bool {
		return !isAlive() && !isReleasing();
	}

	/** Stops every voice, over the sound's `fade: out` unless `fadeOut` says otherwise, and starts
	 *  the `on: stop` layers. Stopped again, it does nothing. */
	public function stop(?fadeOut:Float):Void {
		if (stopped)
			return;
		stopped = true;
		pending = 0;
		for (v in voices)
			v.stop(fadeOut ?? this.fadeOut);
		if (onStop != null)
			onStop(this);
	}

	/** Stops everything, the stop layers too, and starts none: what a bank taken again does to its plays. */
	public function cut(?fadeOut:Float):Void {
		final fade = fadeOut ?? this.fadeOut;
		if (!stopped) {
			stopped = true;
			pending = 0;
			for (v in voices)
				v.stop(fade);
		}
		releasePending = 0;
		for (v in release)
			v.stop(fade);
	}

	/** Pitches every voice, those still to start too, by `rate` over its rolled pitch (1 as played). */
	public function setPitch(rate:Float):Void {
		this.rate = rate;
		for (v in voices)
			v.setPitch(rate);
		for (v in release)
			v.setPitch(rate);
	}

	/** Sets every voice, those still to start too, to `gain` times its rolled volume (1 as played),
	 *  over `fade` seconds when more than 0. */
	public function setVolume(gain:Float, fade:Float = 0):Void {
		this.gain = gain;
		volume = loudest * gain;
		for (v in voices)
			v.setGain(gain, fade);
		for (v in release)
			v.setGain(gain, fade);
	}

	/** A voice the service started, given the rate and gain set so far. */
	@:allow(bh.audio.Audio) function addVoice(voice:AudioVoice, isRelease:Bool):Void {
		if (rate != 1)
			voice.setPitch(rate);
		if (gain != 1)
			voice.setGain(gain, 0);
		(isRelease ? release : voices).push(voice);
	}
}

/** A layer's voice waiting for its delay; a `release` one is an `on: stop` layer's, started after the sound stopped. */
private typedef Pending = {instance:SoundInstance, at:Float, start:VoiceStart, release:Bool};

/** A layer rolled for one start, and the delay before it. */
private typedef RolledStart = {start:VoiceStart, delay:Float};

/** One line of `Audio.history`. */
typedef AudioHistoryEntry = {
	var id:Int;
	/** The service's time. */
	var time:Float;
	/** "play", "drop" (a play that did not happen), "stop", "snapshot", "vca", "param", "music", "ambience". */
	var kind:String;
	/** The sound, snapshot, VCA, parameter or track. */
	var name:String;
	/** What of it: a drop's reason, a snapshot's on/off, a VCA's or parameter's value, a track's crossfade,
	 *  a play's file or layers (`on stop` for the stop layers as a sound stops). */
	var detail:String;
}

/**
	The sounds of the game, played by name: `audio.play("ui.click")`. What a sound is comes from the
	`#name sounds { }` blocks of the files the screen manager loads (`addBank`, done as a file loads),
	never from code: its files and how one is picked, its volume and pitch rolled per play, how many
	may play at once and what gives way, its cooldown, its layers with their delays and odds, its
	variants by the block's parameters (`set("surface", "grass")`). The `#name mix { }` block gives
	the buses, the VCAs a settings screen moves (`setVca("Music", 0.6)`) and the snapshots
	(`snapshot("dialog", true)`), blended into one state per bus; the clock (`clock`) puts the
	`paused` snapshot on and pitches a `pitch clock` bus by its scale. A backend plays the files:
	`HeapsBackend` through `hxd.snd`, `LogBackend` into a log for tests and headless runs.
	`ScreenManager.audio` is the one the game uses, stepped from its update.
**/
class Audio {
	/** The lowest a `pitch clock` bus is pitched to: a rate of 0 is no sound and no driver takes it. */
	public static inline final MIN_PITCH = 0.05;
	/** The snapshot the clock's pause puts on, when the mix has one; without it, every bus pauses. */
	public static inline final PAUSED_SNAPSHOT = "paused";
	/** The snapshot the screen manager puts on under a dialog, when the mix has one. */
	public static inline final DIALOG_SNAPSHOT = "dialog";
	/** The bank the widgets' sounds come from: `ui.hover`, `ui.click`, `ui.toggle`, `ui.change`, `ui.open`, `ui.close`. */
	public static inline final UI_BANK = "ui";
	/** Seconds one track fades into the next unless `playMusic` says otherwise. */
	public static inline final MUSIC_CROSSFADE = 0.5;
	/** The bus music plays on unless its block names one. */
	public static inline final MUSIC_BUS = "music";
	/** How many lines `history` keeps. */
	public static inline final HISTORY_SIZE = 200;

	public var backend:AudioBackend;
	/** 0 to 1, for every roll: replace it for a test that wants the same picks every time. */
	public var randomFunc:() -> Float = () -> hxd.Math.random();
	/** Seconds since the service was made, by the steps it was given. */
	public var time(default, null):Float = 0;
	/** The plays alive now. */
	public var instances(default, null):Array<SoundInstance> = [];
	/** The game's clock: its pause puts the `paused` snapshot on (or pauses every bus when the mix
	 *  has none) and its scale pitches the buses a snapshot on says `pitch clock` for. */
	public var clock(default, set):Null<Clock> = null;

	final banks:Map<String, SoundsDef> = [];
	/** The file each bank and each music block is from, null for code (`RegisteredNames`). */
	final bankOwners:Map<String, Null<String>> = [];
	final musicOwners:Map<String, Null<String>> = [];
	/** A sound's full name to its variants, in file order. */
	final entries:Map<String, Array<SoundEntry>> = [];
	/** Each bank's own parameters by name: their labels and the value now. */
	final bankParams:Map<String, Map<String, BankParam>> = [];
	final pending:Array<Pending> = [];

	var mix:Null<MixDef> = null;
	var mixName:Null<String> = null;
	final vcaValues:Map<String, Float> = [];
	/** The snapshots on, in the order they went on. */
	final snapshotsOn:Array<String> = [];
	/** Every bus the backend was told of: the mix's, the banks', and "" for the sounds that name none. */
	final knownBuses:Array<String> = [];

	/** A track's full name to it and its block's bus. */
	final tracks:Map<String, {def:MusicTrackDef, bus:Null<String>}> = [];
	/** The track playing, its full name, or null. */
	public var musicPlaying(default, null):Null<String> = null;
	var musicVoice:Null<AudioVoice> = null;

	/** What happened, the last `HISTORY_SIZE` lines: plays and drops, stops, snapshots, VCAs,
	 *  parameters, music. For tools (the DevBridge's `audio_log`); the log backend is the full record. */
	public var history(default, null):Array<AudioHistoryEntry> = [];
	var nextHistoryId:Int = 1;
	/** Told of every history line as it is written (the DevBridge's `audio` event). */
	public var onHistory:Null<AudioHistoryEntry->Void> = null;

	public function new(backend:AudioBackend) {
		this.backend = backend;
	}

	// ---- Banks ----

	/** Takes a `sounds` block under its name, so its sounds are `name.sound` and its parameters
	 *  (`param surface: [stone, grass]`) its own, each at its first label. `source` is the file the
	 *  block is from, null for code: the same file taking it again replaces it (a reload, which keeps
	 *  the values the game set where the block still has them); code, or another file, taking a name
	 *  already here is an error naming both (`RegisteredNames`). Every file is given to the backend
	 *  to prepare. */
	public function addBank(name:String, def:SoundsDef, ?source:String):Void {
		var kept:Null<Map<String, BankParam>> = null;
		if (banks.exists(name)) {
			final clash = RegisteredNames.clash("sounds block", name, bankOwners.get(name), source);
			if (clash != null)
				throw 'audio: $clash';
			kept = bankParams.get(name);
			removeBank(name);
		}
		banks.set(name, def);
		bankOwners.set(name, source);
		final own = new Map<String, BankParam>();
		for (p in def.params) {
			final was = kept != null && kept.exists(p.name) ? kept.get(p.name).value : null;
			own.set(p.name, {values: p.values, value: was != null && p.values.contains(was) ? was : p.values[0]});
		}
		bankParams.set(name, own);
		ensureBus(def.bus);
		for (s in def.sounds) {
			final full = '$name.${s.name}';
			var list = entries.get(full);
			if (list == null) {
				list = [];
				entries.set(full, list);
			}
			list.push(new SoundEntry(name, s));
			ensureBus(s.bus);
			for (l in s.layers)
				for (f in l.files)
					backend.prepare(f);
		}
	}

	/** Every `sounds`, `mix` and `music` block of a file; returns how many. */
	public function addBanks(builder:MultiAnimBuilder):Int {
		var n = 0;
		for (block in builder.mixBlockNames()) {
			addMix(block, builder.buildMix(block));
			n++;
		}
		for (block in builder.musicBlockNames()) {
			addMusic(block, builder.buildMusic(block), builder.sourceName);
			n++;
		}
		for (block in builder.soundBlockNames()) {
			addBank(block, builder.buildSounds(block), builder.sourceName);
			n++;
		}
		return n;
	}

	/** Drops a bank and cuts its plays, the stop layers too (a bank taken again is a reload: what
	 *  plays is not what the block says now, and a looping sound would play on for good); returns
	 *  whether the bank was here. */
	public function removeBank(name:String):Bool {
		if (!banks.remove(name))
			return false;
		bankOwners.remove(name);
		bankParams.remove(name);
		var cut = 0;
		for (i in instances)
			if (i.bank == name && !i.isDone()) {
				i.cut();
				cut++;
			}
		if (cut > 0)
			note("stop", '${name}.*', '$cut');
		for (full in [for (k in entries.keys()) k]) {
			final kept = entries.get(full).filter(e -> e.block != name);
			if (kept.length == 0)
				entries.remove(full);
			else
				entries.set(full, kept);
		}
		return true;
	}

	public function bankNames():Array<String> {
		return [for (k in banks.keys()) k];
	}

	/** Every sound's full name, `block.sound`, sorted. */
	public function soundNames():Array<String> {
		final names = [for (k in entries.keys()) k];
		names.sort(Reflect.compare);
		return names;
	}

	public function has(name:String):Bool {
		return entries.exists(name);
	}

	// ---- The mix ----

	/** Takes a `mix` block as the mix: its buses set, every VCA at 1, no snapshot on. The same block
	 *  taken again (a reload) keeps what the game set: the levels of the VCAs it still has and the
	 *  snapshots on that it still has; another block replaces the mix whole. */
	public function addMix(name:String, def:MixDef):Void {
		final again = mixName == name;
		final oldVcas = vcaValues.copy();
		final oldOn = snapshotsOn.copy();
		mix = def;
		mixName = name;
		vcaValues.clear();
		snapshotsOn.resize(0);
		for (v in def.vcas)
			vcaValues.set(v.name, again && oldVcas.exists(v.name) ? oldVcas.get(v.name) : 1);
		if (again)
			for (sn in oldOn)
				if (snapshotDef(sn) != null)
					snapshotsOn.push(sn);
		for (b in def.buses)
			if (!knownBuses.contains(b.name))
				knownBuses.push(b.name);
		if (!knownBuses.contains(""))
			knownBuses.push("");
		refreshAll(0);
		applyClock();
	}

	public function hasMix():Bool {
		return mix != null;
	}

	/** The mix's buses, in file order. */
	public function busNames():Array<String> {
		return mix == null ? [] : [for (b in mix.buses) b.name];
	}

	public function vcaNames():Array<String> {
		return mix == null ? [] : [for (v in mix.vcas) v.name];
	}

	public function snapshotNames():Array<String> {
		return mix == null ? [] : [for (s in mix.snapshots) s.name];
	}

	/** Sets a VCA, 0 to 1 (what a settings slider gives), over every bus it names. */
	public function setVca(name:String, value:Float):Void {
		if (!vcaValues.exists(name))
			throw 'audio: no vca "$name" (${vcaNames().join(", ")})';
		value = hxd.Math.clamp(value, 0, 1);
		if (vcaValues.get(name) == value)
			return;
		vcaValues.set(name, value);
		note("vca", name, '$value');
		for (v in mix.vcas)
			if (v.name == name)
				for (bus in v.buses)
					refreshBus(bus, 0);
	}

	public function getVca(name:String):Float {
		final v = vcaValues.get(name);
		if (v == null)
			throw 'audio: no vca "$name" (${vcaNames().join(", ")})';
		return v;
	}

	/** Puts a snapshot on or takes it off: every bus it changes is set again, its volume over the
	 *  snapshot's `fade`. The snapshots on are summed (dB added, the lowest low-pass, paused if any
	 *  says so). Nothing happens when it already is as asked. */
	public function snapshot(name:String, on:Bool):Void {
		final def = snapshotDef(name);
		if (def == null)
			throw 'audio: no snapshot "$name" (${snapshotNames().join(", ")})';
		if (snapshotsOn.contains(name) == on)
			return;
		if (on)
			snapshotsOn.push(name);
		else
			snapshotsOn.remove(name);
		note("snapshot", name, on ? "on" : "off");
		for (b in def.buses)
			refreshBus(b.bus, def.fade);
	}

	public function isSnapshotOn(name:String):Bool {
		return snapshotsOn.contains(name);
	}

	public function hasSnapshot(name:String):Bool {
		return snapshotDef(name) != null;
	}

	/** The snapshots on, in the order they went on. */
	public function snapshotsOnNow():Array<String> {
		return snapshotsOn.copy();
	}

	function snapshotDef(name:String):Null<MixSnapshotDef> {
		if (mix == null)
			return null;
		for (s in mix.snapshots)
			if (s.name == name)
				return s;
		return null;
	}

	/** A bus as the mix, the snapshots on and the clock make it now. */
	public function busState(bus:Null<String>):BusState {
		var volume = 1.0;
		var db = 0.0;
		var paused = false;
		var lowpass:Null<Float> = null;
		var pitchClock = false;
		var voices = 0;
		if (mix != null && bus != null) {
			for (b in mix.buses)
				if (b.name == bus)
					voices = b.voices;
			for (v in mix.vcas)
				if (v.buses.contains(bus))
					volume *= vcaValues.get(v.name);
			for (sn in snapshotsOn) {
				final def = snapshotDef(sn);
				if (def == null)
					continue;
				for (sb in def.buses)
					if (sb.bus == bus)
						for (c in sb.changes)
							switch c {
								case ChangePause: paused = true;
								case ChangeVolume(d): db += d;
								case ChangeLowPass(g): lowpass = lowpass == null ? g : Math.min(lowpass, g);
								case ChangePitchClock: pitchClock = true;
							}
			}
		}
		volume *= Math.pow(10, db / 20);
		if (clock != null && clock.paused && !hasSnapshot(PAUSED_SNAPSHOT))
			paused = true;
		final pitch = pitchClock && clock != null ? Math.max(clock.scale, MIN_PITCH) : 1.0;
		return {volume: volume, fade: 0, paused: paused, lowpass: lowpass, pitch: pitch, voices: voices};
	}

	function refreshBus(bus:Null<String>, fade:Float):Void {
		final state = busState(bus);
		state.fade = fade;
		backend.setBus(bus, state);
	}

	function refreshAll(fade:Float):Void {
		for (b in knownBuses)
			refreshBus(b == "" ? null : b, fade);
	}

	/** A bus a bank names that the backend has not heard of yet is set once, so it has its state. */
	function ensureBus(bus:Null<String>):Void {
		final key = bus ?? "";
		if (knownBuses.contains(key))
			return;
		knownBuses.push(key);
		refreshBus(bus, 0);
	}

	// ---- The clock ----

	function set_clock(c:Null<Clock>):Null<Clock> {
		if (clock != null)
			clock.removeListener(onClock);
		clock = c;
		if (c != null)
			c.addListener(onClock);
		applyClock();
		return c;
	}

	function onClock(c:Clock):Void {
		applyClock();
	}

	/** The clock's pause as the `paused` snapshot (or every bus paused), its scale on the `pitch clock` buses. */
	function applyClock():Void {
		if (clock == null)
			return;
		if (hasSnapshot(PAUSED_SNAPSHOT)) {
			snapshot(PAUSED_SNAPSHOT, clock.paused);
		} else {
			refreshAll(0);
		}
		if (mix != null)
			for (sn in snapshotsOn) {
				final def = snapshotDef(sn);
				if (def == null)
					continue;
				for (sb in def.buses)
					if (Lambda.exists(sb.changes, c -> c.match(ChangePitchClock)))
						refreshBus(sb.bus, 0);
			}
	}

	// ---- Music ----

	/** Takes a `music` block: its tracks are `name.track`. `source` as for `addBank`: the same file
	 *  taking it again replaces the block's tracks (the one playing plays on), code or another file
	 *  taking a name already here is an error. */
	public function addMusic(name:String, def:MusicDef, ?source:String):Void {
		if (musicOwners.exists(name)) {
			final clash = RegisteredNames.clash("music block", name, musicOwners.get(name), source);
			if (clash != null)
				throw 'audio: $clash';
			for (full in [for (k in tracks.keys()) k])
				if (StringTools.startsWith(full, '$name.'))
					tracks.remove(full);
		}
		musicOwners.set(name, source);
		ensureBus(def.bus ?? MUSIC_BUS);
		for (t in def.tracks) {
			tracks.set('$name.${t.name}', {def: t, bus: def.bus ?? MUSIC_BUS});
			backend.prepare(t.file);
		}
	}

	/** Every track's full name, sorted. */
	public function trackNames():Array<String> {
		final names = [for (k in tracks.keys()) k];
		names.sort(Reflect.compare);
		return names;
	}

	public function hasTrack(name:String):Bool {
		return tracks.exists(name);
	}

	/** Plays a track by its full name, the one playing fading out as it fades in over `crossfade`
	 *  seconds (`MUSIC_CROSSFADE` unless given). The track already playing plays on. A name no block
	 *  has is an error. */
	public function playMusic(name:String, ?crossfade:Float):Void {
		final track = tracks.get(name);
		if (track == null)
			throw 'audio: no track "$name" (the tracks are: ${trackNames().join(", ")})';
		if (musicPlaying == name && musicVoice != null && musicVoice.isPlaying())
			return;
		final fade = crossfade ?? MUSIC_CROSSFADE;
		if (musicVoice != null)
			musicVoice.stop(fade);
		musicPlaying = name;
		musicVoice = backend.play({
			sound: name, layer: "", path: track.def.file, volume: 1, pitch: 1, bus: track.bus, priority: 2, fadeIn: fade,
			loop: track.def.loop
		});
		note("music", name, 'crossfade $fade');
	}

	/** Stops the music over `fade` seconds (`MUSIC_CROSSFADE` unless given); nothing when none plays. */
	public function stopMusic(?fade:Float):Void {
		if (musicVoice == null)
			return;
		musicVoice.stop(fade ?? MUSIC_CROSSFADE);
		note("music", musicPlaying ?? "", "stopped");
		musicVoice = null;
		musicPlaying = null;
	}

	// ---- Ambience ----

	/** The ambience, a sound's full name, or null: one held sound at a time beside the music, what a
	 *  screen's `settings { ambience => "amb.hum" }` names (a looping sound of a `sounds` block). */
	public var ambiencePlaying(default, null):Null<String> = null;
	var ambienceVoice:Null<SoundInstance> = null;

	/** Plays a sound as the ambience: the one playing stops (over its `fade: out`, or `fade`, its stop
	 *  layers playing) and this one starts, as `play` starts it; the same one plays on. A name no bank
	 *  has is an error. */
	public function playAmbience(name:String, ?fade:Float):Void {
		if (ambiencePlaying == name && ambienceVoice != null && ambienceVoice.isAlive())
			return;
		if (!has(name))
			throw 'audio: no sound "$name" (the sounds are: ${soundNames().join(", ")})';
		if (ambienceVoice != null)
			ambienceVoice.stop(fade);
		ambiencePlaying = name;
		ambienceVoice = play(name);
		note("ambience", name, ambienceVoice != null ? "" : "dropped");
	}

	/** Stops the ambience (over its `fade: out`, or `fade`, its stop layers playing); nothing when none. */
	public function stopAmbience(?fade:Float):Void {
		final name = ambiencePlaying;
		if (name == null)
			return;
		if (ambienceVoice != null)
			ambienceVoice.stop(fade);
		note("ambience", name, "stopped");
		ambienceVoice = null;
		ambiencePlaying = null;
	}

	// ---- The widgets' sounds ----

	/** A widget's event by its key (`hover`, `click`, `toggle`, `change`, `open`, `close`): plays what
	 *  the widget's own `sound.<key>` setting names (`own`; "none" is silence), else `ui.<key>` when
	 *  the bank `ui` has it, else nothing. The screen calls it for every widget event. */
	public function playUi(key:String, ?own:String):Null<SoundInstance> {
		if (own != null) {
			if (own == "none" || own == "")
				return null;
			return play(own);
		}
		final name = '$UI_BANK.$key';
		return has(name) ? play(name) : null;
	}

	// ---- History ----

	function note(kind:String, name:String, detail:String):Void {
		final entry:AudioHistoryEntry = {id: nextHistoryId++, time: time, kind: kind, name: name, detail: detail};
		history.push(entry);
		if (history.length > HISTORY_SIZE)
			history.shift();
		if (onHistory != null)
			onHistory(entry);
	}

	/** The history lines after `sinceId` (0 for all kept). */
	public function historySince(sinceId:Int):Array<AudioHistoryEntry> {
		return [for (e in history) if (e.id > sinceId) e];
	}

	// ---- Parameters ----

	/** Sets a parameter a `sounds` block declares (`param surface: [stone, grass]`) to one of its
	 *  labels. Each bank has its own: by its full name (`fx.surface`) one bank's is set, by the bare
	 *  name every bank's that has the label (the others keep theirs). A label no bank has is an
	 *  error. */
	public function set(param:String, value:String):Void {
		final dot = param.indexOf(".");
		if (dot >= 0) {
			final bank = param.substr(0, dot);
			final own = bankParams.get(bank);
			if (own == null)
				throw 'audio: no sounds block "$bank" (param "$param")';
			final p = own.get(param.substr(dot + 1));
			if (p == null)
				throw 'audio: sounds block "$bank" declares no param "${param.substr(dot + 1)}"';
			if (!p.values.contains(value))
				throw 'audio: param "$param" takes ${p.values.join(", ")}, not "$value"';
			p.value = value;
			note("param", param, value);
			return;
		}
		final takes:Array<String> = [];
		var changed = 0;
		for (bank in sortedBanks()) {
			final p = bankParams.get(bank).get(param);
			if (p == null)
				continue;
			if (p.values.contains(value)) {
				p.value = value;
				changed++;
			} else
				takes.push('${p.values.join(", ")} ($bank)');
		}
		if (changed == 0)
			throw takes.length == 0 ? 'audio: no sounds block declares param "$param"' : 'audio: param "$param" takes ${takes.join("; ")}, not "$value"';
		note("param", param, value);
	}

	/** A parameter's value now: one bank's by its full name (`fx.surface`); by the bare name the
	 *  value every bank that has it holds, null when they differ. */
	public function get(param:String):Null<String> {
		final dot = param.indexOf(".");
		if (dot >= 0) {
			final own = bankParams.get(param.substr(0, dot));
			final p = own != null ? own.get(param.substr(dot + 1)) : null;
			return p != null ? p.value : null;
		}
		var value:Null<String> = null;
		for (own in bankParams) {
			final p = own.get(param);
			if (p == null)
				continue;
			if (value != null && p.value != value)
				return null;
			value = p.value;
		}
		return value;
	}

	/** Every bank's parameters by full name (`fx.surface`) and their values now, a copy. */
	public function parameters():Map<String, String> {
		final out = new Map<String, String>();
		for (bank => own in bankParams)
			for (name => p in own)
				out.set('$bank.$name', p.value);
		return out;
	}

	function sortedBanks():Array<String> {
		final names = [for (k in bankParams.keys()) k];
		names.sort(Reflect.compare);
		return names;
	}

	// ---- Playing ----

	/** Plays a sound by its full name. Returns the play, or null when nothing played: the sound's
	 *  cooldown has not passed, it is at its `voices` with `steal: none`, or no variant matches and
	 *  it has no default. A name no bank has is an error. */
	public function play(name:String):Null<SoundInstance> {
		final list = entries.get(name);
		if (list == null)
			throw 'audio: no sound "$name" (the sounds are: ${soundNames().join(", ")})';
		final entry = pickVariant(list);
		if (entry == null) {
			note("drop", name, "no variant matches and no default");
			return null;
		}
		final def = entry.def;
		if (def.cooldown > 0 && entry.lastPlay != null && time - entry.lastPlay < def.cooldown) {
			note("drop", name, "cooldown");
			return null;
		}
		if (def.voices > 0) {
			final live = [for (i in instances) if (i.name == name && i.isAlive()) i];
			while (live.length >= def.voices) {
				switch def.steal {
					case StealNone:
						note("drop", name, 'at ${def.voices} voices');
						return null;
					case StealOldest:
						var oldest = live[0];
						for (i in live)
							if (i.startedAt < oldest.startedAt)
								oldest = i;
						oldest.stop();
						live.remove(oldest);
					case StealQuietest:
						var quietest = live[0];
						for (i in live)
							if (i.volume < quietest.volume)
								quietest = i;
						quietest.stop();
						live.remove(quietest);
				}
			}
		}
		entry.lastPlay = time;
		final bank = banks.get(entry.block);
		final bus = def.bus ?? (bank != null ? bank.bus : null);
		var loudest = 0.0;
		final starts:Array<RolledStart> = [];
		var stopLayers = false;
		for (li in 0...def.layers.length) {
			if (def.layers[li].onStop) {
				stopLayers = true;
				continue;
			}
			final s = rollLayer(name, entry, li, bus);
			if (s == null)
				continue;
			if (s.start.volume > loudest)
				loudest = s.start.volume;
			starts.push(s);
		}
		final instance = new SoundInstance(name, time, loudest, def.fadeOut);
		if (stopLayers)
			instance.onStop = i -> startStopLayers(i, entry, bus);
		instances.push(instance);
		note("play", name, starts.length == 1 ? starts[0].start.path : '${starts.length} layers');
		for (s in starts)
			startVoice(instance, s, false);
		return instance;
	}

	/** A layer rolled for one start: its file picked, its volume, pitch and delay rolled, in that
	 *  order; null when its chance misses. */
	function rollLayer(name:String, entry:SoundEntry, li:Int, bus:Null<String>):Null<RolledStart> {
		final def = entry.def;
		final layer = def.layers[li];
		if (layer.chance < 1 && randomFunc() >= layer.chance)
			return null;
		final path = pickFile(entry, li);
		final volume = Math.pow(10, roll(layer.volumeMinDb, layer.volumeMaxDb) / 20);
		final pitch = roll(layer.pitchMin, layer.pitchMax);
		final delay = roll(layer.delayMin, layer.delayMax);
		return {
			start: {
				sound: name, layer: layer.name, path: path, volume: volume, pitch: pitch, bus: bus, priority: def.priority,
				fadeIn: layer.onStop ? 0 : def.fadeIn, loop: layer.loop
			},
			delay: delay
		};
	}

	/** Starts a rolled layer now, or keeps it in `pending` for its delay. */
	function startVoice(instance:SoundInstance, s:RolledStart, isRelease:Bool):Void {
		if (s.delay <= 0) {
			instance.addVoice(backend.play(s.start), isRelease);
			return;
		}
		@:privateAccess if (isRelease)
			instance.releasePending++;
		else
			instance.pending++;
		pending.push({instance: instance, at: time + s.delay, start: s.start, release: isRelease});
	}

	/** As a sound with `on: stop` layers is stopped: they start, rolled as the others were. */
	function startStopLayers(instance:SoundInstance, entry:SoundEntry, bus:Null<String>):Void {
		final def = entry.def;
		var n = 0;
		for (li in 0...def.layers.length) {
			if (!def.layers[li].onStop)
				continue;
			final s = rollLayer(instance.name, entry, li, bus);
			if (s == null)
				continue;
			startVoice(instance, s, true);
			n++;
		}
		if (n > 0)
			note("play", instance.name, n == 1 ? "on stop" : '$n layers on stop');
	}

	/** Stops every play of a sound, over its `fade: out` unless `fadeOut` is given; returns how many. */
	public function stop(name:String, ?fadeOut:Float):Int {
		var n = 0;
		for (i in instances)
			if (i.name == name && i.isAlive()) {
				i.stop(fadeOut);
				n++;
			}
		if (n > 0)
			note("stop", name, '$n');
		return n;
	}

	/** Stops every play, over each one's `fade: out` unless `fadeOut` is given; returns how many. */
	public function stopAll(?fadeOut:Float):Int {
		var n = 0;
		for (i in instances)
			if (i.isAlive()) {
				i.stop(fadeOut);
				n++;
			}
		if (n > 0)
			note("stop", "*", '$n');
		return n;
	}

	/** Once a frame: starts the layers whose delay has passed, forgets the plays that ended (their
	 *  stop layers too). */
	public function update(dt:Float):Void {
		time += dt;
		backend.update(dt);
		var i = 0;
		while (i < pending.length) {
			final p = pending[i];
			if (p.at <= time) {
				pending.splice(i, 1);
				if (p.release) {
					// a cut sound (its bank taken again) has forgotten its stop layers
					if (p.instance.releasePending > 0) {
						@:privateAccess p.instance.releasePending--;
						p.instance.addVoice(backend.play(p.start), true);
					}
				} else if (!p.instance.stopped) {
					@:privateAccess p.instance.pending--;
					p.instance.addVoice(backend.play(p.start), false);
				}
			} else {
				i++;
			}
		}
		var j = 0;
		while (j < instances.length) {
			if (instances[j].isDone())
				instances.splice(j, 1);
			else
				j++;
		}
	}

	// ---- Picking and rolling ----

	function roll(min:Float, max:Float):Float {
		return min == max ? min : min + randomFunc() * (max - min);
	}

	function pickFile(entry:SoundEntry, li:Int):String {
		final layer = entry.def.layers[li];
		final files = layer.files;
		if (files.length == 1)
			return files[0];
		return switch layer.pick {
			case PickRandom:
				files[Std.int(randomFunc() * files.length) % files.length];
			case PickTurn:
				final i = entry.turns[li];
				entry.turns[li] = (i + 1) % files.length;
				files[i];
			case PickShuffle:
				var bag = entry.bags[li];
				if (bag.length == 0) {
					bag = files.copy();
					entry.bags[li] = bag;
				}
				bag.splice(Std.int(randomFunc() * bag.length) % bag.length, 1)[0];
		}
	}

	/** The first variant whose `@(…)` matches its bank's parameters, else the one without; null when neither. */
	function pickVariant(list:Array<SoundEntry>):Null<SoundEntry> {
		var fallback:Null<SoundEntry> = null;
		for (e in list)
			switch e.def.conditional {
				case NoConditional:
					if (fallback == null)
						fallback = e;
				case Conditional(conditions, anyMode):
					if (matches(conditions, anyMode, bankParams.get(e.block)))
						return e;
				default:
			}
		return fallback;
	}

	function matches(conditions:Map<String, ConditionalValues>, anyMode:Bool, own:Null<Map<String, BankParam>>):Bool {
		for (param => cv in conditions) {
			final p = own != null ? own.get(param) : null;
			final value = p != null ? p.value : null;
			final ok = value != null && matchOne(cv, value);
			if (anyMode && ok)
				return true;
			if (!anyMode && !ok)
				return false;
		}
		return !anyMode;
	}

	function matchOne(cv:ConditionalValues, value:String):Bool {
		return switch cv {
			case CoEnums(a): a.contains(value);
			case CoIndex(_, v): v == value;
			case CoStringValue(s): s == value;
			case CoAny: true;
			case CoNot(inner): !matchOne(inner, value);
			case CoAnyOf(values): Lambda.exists(values, v -> matchOne(v, value));
			default: false;
		}
	}
}
