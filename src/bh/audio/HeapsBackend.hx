package bh.audio;

import bh.audio.AudioBackend;
import bh.base.ResourceLoader;

private class HeapsVoice implements AudioVoice {
	public final channel:hxd.snd.Channel;
	public final bus:String;
	/** The rate and volume the play was rolled to; the bus's pitch and what the service sets multiply them. */
	final basePitch:Float;
	final baseVolume:Float;
	var busPitch:Float = 1;
	var ownPitch:Float = 1;
	var pitchEffect:Null<hxd.snd.effect.Pitch> = null;

	public function new(channel:hxd.snd.Channel, bus:String, basePitch:Float, baseVolume:Float) {
		this.channel = channel;
		this.bus = bus;
		this.basePitch = basePitch;
		this.baseVolume = baseVolume;
	}

	public function setBusPitch(rate:Float):Void {
		busPitch = rate;
		applyPitch();
	}

	public function setPitch(rate:Float):Void {
		ownPitch = rate;
		applyPitch();
	}

	function applyPitch():Void {
		final value = basePitch * busPitch * ownPitch;
		if (pitchEffect == null) {
			if (value == 1)
				return;
			pitchEffect = channel.addEffect(new hxd.snd.effect.Pitch(value));
		} else {
			pitchEffect.value = value;
		}
	}

	public function setGain(gain:Float, fade:Float):Void {
		if (channel.isReleased())
			return;
		final value = baseVolume * gain;
		if (fade > 0)
			channel.fadeTo(value, fade);
		else
			channel.volume = value;
	}

	public function isPlaying():Bool {
		return !channel.isReleased();
	}

	public function getVolume():Float {
		return channel.volume;
	}

	public function stop(fadeOut:Float):Void {
		if (channel.isReleased())
			return;
		if (fadeOut > 0)
			channel.fadeTo(0, fadeOut, () -> channel.stop());
		else
			channel.stop();
	}
}

/**
	Plays through Heaps' `hxd.snd`: a file is an `hxd.res.Sound` from the loader (`loadSound`, cached),
	a play is a channel of it, a bus is a `ChannelGroup` (its volume and fades, its low-pass) and a
	`SoundGroup` (how many of its plays are heard) made on first use. A bus's pause freezes each of
	its channels (`Channel.pause`, never `Manager.suspended`, which lets time run on), its pitch
	multiplies into each channel's own. The sound manager starts itself on the first play (and runs
	on from `haxe.MainLoop`), so a game that never plays never opens a device.
**/
class HeapsBackend implements AudioBackend {
	/** The name the sounds that name no bus play on. */
	public static inline final DEFAULT_BUS = "default";

	final loader:ResourceLoader;
	final groups:Map<String, hxd.snd.ChannelGroup> = [];
	final soundGroups:Map<String, hxd.snd.SoundGroup> = [];
	final lowPasses:Map<String, hxd.snd.effect.LowPass> = [];
	final states:Map<String, BusState> = [];
	var voices:Array<HeapsVoice> = [];
	/** A looping play's repeat from past its intro, by file and point (`loopBody`). */
	final loopBodies:Map<String, hxd.res.Sound> = [];

	public function new(loader:ResourceLoader) {
		this.loader = loader;
	}

	public function prepare(path:String):Void {
		gapless(loader.loadSound(path));
	}

	/**
		On HashLink, an MP3 that says its gap (an Info frame with LAME's tag) played from its first
		sample to its last (`GaplessMp3Data`), so a loop joins with no pause at its seam: Heaps' own
		decodes from the file's first sample. Done once a sound, and again after a hot reload reads it
		anew. Elsewhere, and for any other sound, nothing.
	**/
	public static function gapless(sound:hxd.res.Sound):Void {
		#if hl
		final data = @:privateAccess sound.data;
		if (Std.isOfType(data, GaplessMp3Data) || (data != null && !Std.isOfType(data, hxd.snd.Mp3Data)))
			return;
		final bytes = sound.entry.getBytes();
		if (bytes.length == 0 || (bytes.get(0) != 0xFF && bytes.get(0) != "I".code))
			return;
		final made = GaplessMp3Data.ofBytes(bytes);
		if (made != null)
			@:privateAccess sound.data = made;
		#end
	}

	static inline function busName(bus:Null<String>):String {
		return bus ?? DEFAULT_BUS;
	}

	/** The channel group a bus plays through, made on first use. */
	public function group(bus:Null<String>):hxd.snd.ChannelGroup {
		final name = busName(bus);
		var g = groups.get(name);
		if (g == null) {
			g = new hxd.snd.ChannelGroup(name);
			groups.set(name, g);
		}
		return g;
	}

	/** The sound group of a bus (its `voices`), made on first use. */
	public function soundGroup(bus:Null<String>):hxd.snd.SoundGroup {
		final name = busName(bus);
		var g = soundGroups.get(name);
		if (g == null) {
			g = new hxd.snd.SoundGroup(name);
			soundGroups.set(name, g);
		}
		return g;
	}

	/** The low-pass on a bus, or null. */
	public function lowPass(bus:Null<String>):Null<hxd.snd.effect.LowPass> {
		return lowPasses.get(busName(bus));
	}

	/**
		What a looping play with `loopFrom` repeats: the sound from that point on (`LoopFromData`), one
		a file and point, made again when the file's data was (a hot reload).
	**/
	public function loopBody(path:String, sound:hxd.res.Sound, seconds:Float):hxd.res.Sound {
		final key = '$path@$seconds';
		final data = sound.getData();
		var body = loopBodies.get(key);
		final had:Null<LoopFromData> = body == null ? null : Std.downcast(@:privateAccess body.data, LoopFromData);
		if (body == null || had == null || had.inner != data) {
			// an entry of its own: Heaps keeps a short sound's decoded buffer by its entry's path, and
			// this one's samples are not the file's (its data is set, so the entry is never read)
			body = new hxd.res.Sound(new hxd.fs.BytesFileSystem.BytesFileEntry(key, haxe.io.Bytes.alloc(0)));
			@:privateAccess body.data = new LoopFromData(data, seconds);
			loopBodies.set(key, body);
		}
		return body;
	}

	public function play(start:VoiceStart):AudioVoice {
		final sound = loader.loadSound(start.path);
		gapless(sound);
		final name = busName(start.bus);
		final channel = sound.play(start.loop, start.fadeIn > 0 ? 0 : start.volume, group(start.bus), soundGroup(start.bus));
		// A repeat from past the intro: the first play is the whole file, then the channel goes on, with
		// no gap, to the sound from that point, which it loops (Heaps plays a queued sound next and
		// loops the last it played)
		final loopFrom = start.loopFrom;
		if (start.loop && loopFrom != null && loopFrom > 0)
			channel.queueSound(loopBody(start.path, sound, loopFrom));
		channel.priority = start.priority;
		if (start.fadeIn > 0)
			channel.fadeTo(start.volume, start.fadeIn);
		final voice = new HeapsVoice(channel, name, start.pitch, start.volume);
		final state = states.get(name);
		voice.setBusPitch(state != null ? state.pitch : 1);
		if (state != null && state.paused)
			channel.pause = true;
		voices.push(voice);
		return voice;
	}

	public function setBus(bus:Null<String>, state:BusState):Void {
		final name = busName(bus);
		final was = states.get(name);
		states.set(name, state);
		final g = group(bus);
		if (was == null || was.volume != state.volume) {
			if (state.fade > 0)
				g.fadeTo(state.volume, state.fade);
			else
				g.volume = state.volume;
		}
		soundGroup(bus).maxAudible = state.voices > 0 ? state.voices : -1;
		if (state.lowpass != null) {
			var lp = lowPasses.get(name);
			if (lp == null) {
				lp = g.addEffect(new hxd.snd.effect.LowPass());
				lowPasses.set(name, lp);
			}
			lp.gainHF = state.lowpass;
		} else {
			final lp = lowPasses.get(name);
			if (lp != null) {
				g.removeEffect(lp);
				lowPasses.remove(name);
			}
		}
		for (v in voices)
			if (v.bus == name) {
				if (was == null || was.paused != state.paused)
					v.channel.pause = state.paused;
				if (was == null || was.pitch != state.pitch)
					v.setBusPitch(state.pitch);
			}
	}

	public function update(dt:Float):Void {
		// hxd.snd.Manager updates itself from haxe.MainLoop; only the list of plays is kept short,
		// in place (a splice makes an array of what it removes)
		var kept = 0;
		for (v in voices)
			if (v.isPlaying())
				voices[kept++] = v;
		voices.resize(kept);
	}
}
