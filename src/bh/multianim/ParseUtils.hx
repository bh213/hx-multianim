package bh.multianim;

@:nullSafety
class ParseUtils {
	/** Parses string to Int, throws if not a valid integer. Use when the lexer/parser guarantees the token is numeric. */
	public static inline function toInt(s:String):Int {
		return Std.parseInt(s) ?? throw 'expected integer, got "$s"';
	}
}
