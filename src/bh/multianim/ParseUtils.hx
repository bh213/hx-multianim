package bh.multianim;

@:nullSafety
class ParseUtils {
	/** Parses string to Int, throws if not a valid integer. Use when the lexer/parser guarantees the token is numeric. */
	public static function toInt(s:String):Int {
		final value = int32OrNull(s);
		if (value != null) return value;
		throw Std.parseInt(s) == null ? 'expected integer, got "$s"' : 'integer $s does not fit in 32 bits';
	}

	/** An integer literal as a 32-bit Int, the same on every target: decimal from -2147483648 to
	 *  2147483647, or `0x` hex of up to 8 digits taken as its bits (`0xFFFF0000` is -65536, as a
	 *  Heaps colour is). `Std.parseInt` alone clamps on HashLink and keeps the whole number on JS.
	 *  Null when `s` is not an integer or does not fit. */
	public static function int32OrNull(s:String):Null<Int> {
		final value = Std.parseInt(s);
		if (value == null) return null;
		final first = s.charAt(0);
		final body = first == "-" || first == "+" ? s.substr(1) : s;
		if (body.length > 1 && body.charAt(0) == "0" && (body.charAt(1) == "x" || body.charAt(1) == "X")) {
			var digits = body.substr(2);
			while (digits.length > 1 && digits.charAt(0) == "0")
				digits = digits.substr(1);
			if (digits.length > 8) return null;
			return value | 0;
		}
		final asFloat = Std.parseFloat(s);
		if (asFloat > 2147483647.0 || asFloat < -2147483648.0) return null;
		return value;
	}
}
