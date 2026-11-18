package bh.audio;

/** What an MP3's Info (or Xing) frame says of its first and last samples, from LAME's tag. **/
typedef Mp3Gap = {
	/** Samples the encoder put before the sound's first (LAME's 576). **/
	final delay:Int;

	/** Samples of silence it put after the sound's last. **/
	final padding:Int;
}

/**
	Where an MP3's samples begin and end, as its first frame says: an Info (or Xing) frame with LAME's
	tag, which LAME, FFmpeg and the studio's encoder write. Read without decoding, on every target.
**/
class Mp3Gaps {
	/**
		The encoder's delay and padding an MP3 says in its LAME tag (an encoder named `LAME…` or
		FFmpeg's `Lav…`), or null when its first frame is no Info or Xing frame with one.
	**/
	public static function of(bytes:haxe.io.Bytes):Null<Mp3Gap> {
		var p = 0;
		final n = bytes.length;
		// an ID3v2 tag first: its size is four 7-bit bytes after the 6-byte header
		if (n > 10 && bytes.get(0) == "I".code && bytes.get(1) == "D".code && bytes.get(2) == "3".code)
			p = 10 + (((bytes.get(6) & 0x7F) << 21) | ((bytes.get(7) & 0x7F) << 14) | ((bytes.get(8) & 0x7F) << 7) | (bytes.get(9) & 0x7F));
		if (p + 4 > n || bytes.get(p) != 0xFF || (bytes.get(p + 1) & 0xE0) != 0xE0)
			return null;
		final mpeg1 = ((bytes.get(p + 1) >> 3) & 3) == 3;
		final crc = (bytes.get(p + 1) & 1) == 0;
		final mono = ((bytes.get(p + 3) >> 6) & 3) == 3;
		// the Xing header follows the side information
		final xing = p + 4 + (crc ? 2 : 0) + (mpeg1 ? (mono ? 17 : 32) : (mono ? 9 : 17));
		if (xing + 8 > n)
			return null;
		final word = bytes.getString(xing, 4);
		if (word != "Info" && word != "Xing")
			return null;
		final flags = bytes.get(xing + 7);
		var lame = xing + 8;
		if ((flags & 1) != 0) lame += 4; // frames
		if ((flags & 2) != 0) lame += 4; // bytes
		if ((flags & 4) != 0) lame += 100; // table of contents
		if ((flags & 8) != 0) lame += 4; // quality
		if (lame + 24 > n)
			return null;
		final encoder = bytes.getString(lame, 4);
		if (encoder != "LAME" && !StringTools.startsWith(encoder, "Lav"))
			return null;
		final d0 = bytes.get(lame + 21);
		final d1 = bytes.get(lame + 22);
		final d2 = bytes.get(lame + 23);
		return {delay: (d0 << 4) | (d1 >> 4), padding: ((d1 & 0x0F) << 8) | d2};
	}
}

#if hl
/**
	An MP3 played on HashLink from its first sample to its last, as its LAME tag says. Heaps'
	`Mp3Data` counts the samples so but decodes from the file's first: the Info frame's silent frame,
	the encoder's delay and the decoder's own were played first and as many of the sound's last were
	cut, some 50 ms of silence at a loop's seam. This one starts at the sound's first sample
	(`skip`: the Info frame, the encoder's delay and `DECODER_DELAY`), says the sound's own length, and
	fills with silence past the file's last frame. In the browser the decoder does it itself.
	`HeapsBackend` puts one in place of Heaps' as it plays a sound (`gapless`).
**/
class GaplessMp3Data extends hxd.snd.Mp3Data {
	/** The decoder's own delay, in samples: an MP3 decoder's output lags its input by 528 and one. **/
	public static inline final DECODER_DELAY = 529;

	/** Decoded samples before the sound's first. **/
	public var skip(default, null):Int;

	/** The gapless data of an MP3, or null when it says nothing of its gap (`Mp3Gaps.of`). **/
	public static function ofBytes(bytes:haxe.io.Bytes):Null<GaplessMp3Data> {
		final gap = Mp3Gaps.of(bytes);
		return gap == null ? null : new GaplessMp3Data(bytes, gap);
	}

	function new(bytes:haxe.io.Bytes, gap:Mp3Gap) {
		super(bytes);
		skip = samplesPerFrame + gap.delay + DECODER_DELAY;
		final own = frameOffsets.length * samplesPerFrame - samplesPerFrame - gap.delay - gap.padding;
		samples = own > 0 ? own : 0;
	}

	override function decodeBuffer(out:haxe.io.Bytes, outPos:Int, sampleStart:Int, sampleCount:Int) {
		final size = 4 * channels;
		var at = sampleStart + skip;
		while (sampleCount > 0) {
			final f = Std.int(at / samplesPerFrame);
			if (f >= frameOffsets.length) {
				out.fill(outPos, sampleCount * size, 0);
				break;
			}
			if (f != currentFrame) {
				// the decoder keeps what it needs of the frame before (its overlap, its reservoir):
				// a jump (a loop back to the start) decodes that frame first
				if (f != currentFrame + 1 && f > 0)
					seekFrame(f - 1);
				seekFrame(f);
			}
			final inFrame = at - f * samplesPerFrame;
			var count = samplesPerFrame - inFrame;
			if (count > sampleCount)
				count = sampleCount;
			out.blit(outPos, frame, inFrame * size, count * size);
			outPos += count * size;
			at += count;
			sampleCount -= count;
		}
		currentSample = at;
	}
}
#end
