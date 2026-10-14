package bh.audio;

/** What a backend is asked to start: one file of one layer of one sound, rolled and resolved. */
typedef VoiceStart = {
	/** The sound's full name, `ui.click`. */
	var sound:String;
	/** The layer's name, "" for a sound's own files. */
	var layer:String;
	var path:String;
	/** Linear, 1 as written in the file at 0 dB. */
	var volume:Float;
	/** A rate, 1 unchanged. */
	var pitch:Float;
	var bus:Null<String>;
	var priority:Float;
	/** Seconds, 0 for none. */
	var fadeIn:Float;
	var loop:Bool;
}

/** What a bus is set to, whole, every time any of it changes (the service works it out from the
 *  mix's VCAs and the snapshots on, and the clock). */
typedef BusState = {
	/** Linear, 1 as the files are. */
	var volume:Float;
	/** Seconds the volume takes to get there; 0 at once. */
	var fade:Float;
	/** Its plays frozen, and new ones start frozen. */
	var paused:Bool;
	/** The share of highs kept by a low-pass filter, 0..1, or null for no filter. */
	var lowpass:Null<Float>;
	/** A rate every play of the bus is pitched by, 1 unchanged. */
	var pitch:Float;
	/** How many of its plays are heard at once, 0 for no limit. */
	var voices:Int;
}

/** One file playing, as the backend started it. */
interface AudioVoice {
	function isPlaying():Bool;
	/** Its volume now, linear, as the service set it (fades and the bus apart). */
	function getVolume():Float;
	/** Stops it, over `fadeOut` seconds when more than 0. */
	function stop(fadeOut:Float):Void;
}

/**
	Where the sound goes: `HeapsBackend` plays it through `hxd.snd`, `LogBackend` plays nothing and
	writes down what would have played. The `Audio` service does everything above this line
	(picking, rolling, voices, stealing, cooldowns, layers); a backend only starts and stops files.
**/
interface AudioBackend {
	/** The file will be played: load it now, so the first play does not wait. */
	function prepare(path:String):Void;
	function play(start:VoiceStart):AudioVoice;
	/** A bus as it is now, whole; `null` is the bus of the sounds that name none. */
	function setBus(bus:Null<String>, state:BusState):Void;
	/** Once a frame, with the game's step. */
	function update(dt:Float):Void;
}
