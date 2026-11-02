package bh.test.examples;

import utest.Assert;

/**
	An MP3 played on HashLink from its first sample to its last (hx-multianim request 22):
	`test/res/sound/tone441.mp3` is 11000 samples of a 441 Hz tone at 44.1 kHz (110 whole periods, so
	it loops with no seam), encoded by FFmpeg's LAME with an Info frame saying its delay (576) and
	padding. Heaps' `Mp3Data` decodes it from the file's first sample: a silent frame, the delay and
	the decoder's own first.
**/
class GaplessMp3Test extends utest.Test {
	static inline final LENGTH = 11000;

	static function toneBytes():haxe.io.Bytes {
		return hxd.Res.load("sound/tone441.mp3").entry.getBytes();
	}

	/** The tone as it was encoded, at sample `i` (any `i`: it repeats every 100). **/
	static function ideal(i:Int):Float {
		return 0.5 * Math.sin(2 * Math.PI * 441 * i / 44100);
	}

	static function decoded(data:hxd.snd.Data, start:Int, count:Int):haxe.io.Bytes {
		final out = haxe.io.Bytes.alloc(count * 4 * data.channels);
		data.decode(out, 0, start, count);
		return out;
	}

	public function testTheGapIsReadFromTheInfoFrame() {
		final gap = bh.audio.GaplessMp3Data.Mp3Gaps.of(toneBytes());
		Assert.notNull(gap);
		if (gap != null) {
			Assert.equals(576, gap.delay, "LAME's delay");
			Assert.isTrue(gap.padding > 0);
		}
		Assert.isNull(bh.audio.GaplessMp3Data.Mp3Gaps.of(haxe.io.Bytes.ofString("RIFF....WAVE")), "no MP3");
	}

	#if hl
	public function testTheSoundIsPlayedFromItsFirstSampleToItsLast() {
		final data = bh.audio.GaplessMp3Data.GaplessMp3Data.ofBytes(toneBytes());
		Assert.notNull(data);
		if (data == null)
			return;
		Assert.equals(LENGTH, data.samples, "the sound's own length");
		Assert.equals(1152 + 576 + 529, data.skip, "the Info frame, the encoder's delay and the decoder's");
		final out = decoded(data, 0, LENGTH);
		// every sample where it was encoded, the first ones too (MP3 keeps it within a few hundredths)
		var worst = 0.0;
		var at = 0;
		for (i in 0...LENGTH) {
			final error = Math.abs(out.getFloat(i * 4) - ideal(i));
			if (error > worst) {
				worst = error;
				at = i;
			}
		}
		Assert.isTrue(worst < 0.05, 'every sample as encoded (the worst ${Math.round(worst * 1000) / 1000} at $at)');
		// the seam of a loop: the last samples and then the first, as the sound manager asks for them
		final end = decoded(data, LENGTH - 200, 200);
		final start = decoded(data, 0, 200);
		var seam = 0.0;
		for (i in 0...200) {
			seam = Math.max(seam, Math.abs(end.getFloat(i * 4) - ideal(LENGTH - 200 + i)));
			seam = Math.max(seam, Math.abs(start.getFloat(i * 4) - ideal(LENGTH + i)));
		}
		Assert.isTrue(seam < 0.05, 'the loop joins with no gap (the worst ${Math.round(seam * 1000) / 1000})');
		// past its end: silence, never a frame the file has not
		final past = decoded(data, LENGTH - 10, 2000);
		Assert.floatEquals(0, past.getFloat(1500 * 4), "silence after the end");

		// Heaps' own: a frame and more of silence first
		final heaps = new hxd.snd.Mp3Data(toneBytes());
		final first = decoded(heaps, 0, 1500);
		var loudest = 0.0;
		for (i in 0...1500)
			loudest = Math.max(loudest, Math.abs(first.getFloat(i * 4)));
		Assert.isTrue(loudest < 0.01, "Heaps' Mp3Data begins with silence where the tone is");
	}

	public function testTheHeapsBackendPutsTheGaplessDataInPlace() {
		final sound = hxd.Res.load("sound/tone441.mp3").toSound();
		bh.audio.HeapsBackend.gapless(sound);
		Assert.isTrue(Std.isOfType(sound.getData(), bh.audio.GaplessMp3Data.GaplessMp3Data));
		Assert.equals(LENGTH, sound.getData().samples);
		final again = sound.getData();
		bh.audio.HeapsBackend.gapless(sound);
		Assert.equals(again, sound.getData(), "once a sound");
	}
	#end
}
