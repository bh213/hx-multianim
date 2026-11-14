package bh.multianim.data;

/**
	A seeded random: Mulberry32, the same numbers on every target for the same seed. What a pick
	draws with when it is given a seed (`data_pick`, a test). It gives the numbers the usual JavaScript
	`mulberry32` gives, so a tool written in JavaScript draws the same rows from the same seed.
**/
class DataRandom {
	var state:Int;

	public function new(seed:Int) {
		state = seed;
	}

	/** Between 0 (included) and 1 (excluded). **/
	public function float():Float {
		// `| 0` wraps to 32 bits on JS, where an Int sum is a double that keeps growing.
		state = (state + 0x6D2B79F5) | 0;
		var t = state;
		t = imul(t ^ (t >>> 15), t | 1);
		t ^= t + imul(t ^ (t >>> 7), t | 61);
		// The 32 bits as an unsigned number: Haxe's Int is signed.
		final u = t ^ (t >>> 14);
		return (u < 0 ? u + 4294967296.0 : u * 1.0) / 4294967296.0;
	}

	static inline function imul(a:Int, b:Int):Int {
		return (((a & 0xffff) * b) + ((((a >>> 16) * b) & 0xffff) << 16)) | 0;
	}
}
