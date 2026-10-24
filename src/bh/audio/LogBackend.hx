package bh.audio;

import bh.audio.AudioBackend;

/** One line of the log: a file started, stopped, re-pitched or re-leveled, or a bus set. */
typedef AudioLogEntry = {
	/** The backend's time, seconds since it was made. */
	var time:Float;
	/** "play", "stop", "pitch", "volume" or "bus". */
	var kind:String;
	/** The sound's full name; "" on a bus line. */
	var sound:String;
	var layer:String;
	var path:String;
	var bus:Null<String>;
	/** A play's volume as started; a volume line's new one. */
	var volume:Float;
	/** A play's rate as started; a pitch line's new one. */
	var pitch:Float;
	/** The fade asked for: in on a play, out on a stop, a volume line's, the bus's on a bus line. */
	var fade:Float;
	/** A play line: round and round until stopped. */
	var loop:Bool;
	/** A bus line: frozen or not. */
	var paused:Bool;
	/** A bus line: the low-pass share of highs kept, or null. */
	var lowpass:Null<Float>;
	/** A bus line: how many of its plays are heard at once, 0 for no limit. */
	var voices:Int;
}

private class LogVoice implements AudioVoice {
	final log:LogBackend;
	public final start:VoiceStart;
	final duration:Float;
	/** Seconds played, counted while its bus is not paused. */
	public var elapsed:Float = 0;
	/** Its rate and volume now, as started times what was set on it. */
	public var pitch:Float;
	public var volume:Float;
	var stopped = false;

	public function new(log:LogBackend, start:VoiceStart, duration:Float) {
		this.log = log;
		this.start = start;
		this.duration = duration;
		pitch = start.pitch;
		volume = start.volume;
	}

	public function isPlaying():Bool {
		return !stopped && (start.loop || elapsed < duration);
	}

	public function getVolume():Float {
		return volume;
	}

	public function stop(fadeOut:Float):Void {
		if (stopped)
			return;
		stopped = true;
		log.entries.push(entry("stop", fadeOut));
	}

	public function setPitch(rate:Float):Void {
		pitch = start.pitch * rate;
		log.entries.push(entry("pitch", 0));
	}

	public function setGain(gain:Float, fade:Float):Void {
		volume = start.volume * gain;
		log.entries.push(entry("volume", fade));
	}

	/** A line of this voice as it is now: `kind` with the fade asked for. */
	public function entry(kind:String, fade:Float):AudioLogEntry {
		return {
			time: log.time, kind: kind, sound: start.sound, layer: start.layer, path: start.path, bus: start.bus, volume: volume, pitch: pitch,
			fade: fade, loop: start.loop, paused: false, lowpass: null, voices: 0
		};
	}
}

/**
	A backend that plays nothing and writes down what would have played: what tests read, and what
	a game runs with where nothing should be heard (a headless test, a replay). A file plays for
	`durations[path]` seconds, or `defaultDuration`, and a looping one until stopped; a paused bus
	holds its files where they are.
**/
class LogBackend implements AudioBackend {
	public var entries:Array<AudioLogEntry> = [];
	/** Every path `prepare` was given, once each. */
	public var prepared:Array<String> = [];
	public var durations:Map<String, Float> = [];
	public var defaultDuration:Float = 1.0;
	public var time(default, null):Float = 0.0;
	/** Every bus as it was last set, by name ("" for the sounds that name none). */
	public var buses:Map<String, BusState> = [];

	var voices:Array<LogVoice> = [];

	public function new() {}

	public function prepare(path:String):Void {
		if (!prepared.contains(path))
			prepared.push(path);
	}

	public function play(start:VoiceStart):AudioVoice {
		final duration = durations.exists(start.path) ? durations.get(start.path) : defaultDuration;
		final voice = new LogVoice(this, start, duration);
		entries.push(voice.entry("play", start.fadeIn));
		voices.push(voice);
		return voice;
	}

	public function setBus(bus:Null<String>, state:BusState):Void {
		buses.set(bus ?? "", state);
		entries.push({
			time: time, kind: "bus", sound: "", layer: "", path: "", bus: bus, volume: state.volume, pitch: state.pitch,
			fade: state.fade, loop: false, paused: state.paused, lowpass: state.lowpass, voices: state.voices
		});
	}

	/** Whether a bus is paused as last set. */
	public function isBusPaused(bus:Null<String>):Bool {
		final state = buses.get(bus ?? "");
		return state != null && state.paused;
	}

	public function update(dt:Float):Void {
		time += dt;
		var i = 0;
		while (i < voices.length) {
			final v = voices[i];
			if (!isBusPaused(v.start.bus))
				v.elapsed += dt;
			if (v.isPlaying())
				i++;
			else
				voices.splice(i, 1);
		}
	}

	/** The plays, of one sound when `sound` is given. */
	public function plays(?sound:String):Array<AudioLogEntry> {
		return [for (e in entries) if (e.kind == "play" && (sound == null || e.sound == sound)) e];
	}

	public function stops(?sound:String):Array<AudioLogEntry> {
		return [for (e in entries) if (e.kind == "stop" && (sound == null || e.sound == sound)) e];
	}

	/** The bus lines, of one bus when `bus` is given ("" for the sounds that name none). */
	public function busLines(?bus:String):Array<AudioLogEntry> {
		return [for (e in entries) if (e.kind == "bus" && (bus == null || (e.bus ?? "") == bus)) e];
	}

	public function clear():Void {
		entries = [];
	}
}
