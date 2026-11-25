package bh.audio;

/**
	A sound from a point on: what a music track with `loopFrom:` repeats once its first play, the
	whole file with its intro, has ended. `HeapsBackend` queues it on the play's channel, which Heaps
	joins to the first play with no gap and then loops by itself. It decodes the sound's own data from
	that sample, so an MP3 played gapless (`GaplessMp3Data`) is still played so, and the decoder's
	frame before a jump is decoded first as it is for any loop.
**/
class LoopFromData extends hxd.snd.Data {
	/** The whole sound's data. **/
	public final inner:hxd.snd.Data;

	/** Where every repeat starts, in seconds into the sound. **/
	public final seconds:Float;

	/** That point in the sound's own samples: this data's first sample is the sound's `from`th. **/
	public var from(default, null):Int = 0;

	public function new(inner:hxd.snd.Data, seconds:Float) {
		this.inner = inner;
		this.seconds = seconds;
		refresh();
	}

	/** The sound's format and length as its data says them now (in the browser, once it is decoded). **/
	function refresh():Void {
		samplingRate = inner.samplingRate;
		sampleFormat = inner.sampleFormat;
		channels = inner.channels;
		var at = Math.round(seconds * inner.samplingRate);
		// a point at or past the end repeats the last sample's frame rather than nothing
		if (at >= inner.samples)
			at = inner.samples - 1;
		if (at < 0)
			at = 0;
		from = at;
		samples = inner.samples - from;
	}

	override public function isLoading():Bool {
		final loading = inner.isLoading();
		if (!loading)
			refresh();
		return loading;
	}

	override public function load(onEnd:Void->Void):Void {
		inner.load(() -> {
			refresh();
			onEnd();
		});
	}

	override function decodeBuffer(out:haxe.io.Bytes, outPos:Int, sampleStart:Int, sampleCount:Int):Void {
		@:privateAccess inner.decodeBuffer(out, outPos, from + sampleStart, sampleCount);
	}
}
