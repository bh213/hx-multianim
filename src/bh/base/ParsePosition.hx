package bh.base;

/**
	Position information for parser errors.
	Stores source file name, line number, and column number.
**/
class ParsePosition {
	public var psource:String;
	public var line:Int;
	public var col:Int;

	public function new(source:String, line:Int, col:Int) {
		psource = source;
		this.line = line;
		this.col = col;
	}

	public function toString() {
		return '$psource:$line:$col';
	}

	public function format(?input:Dynamic) {
		return '$psource:$line: character $col';
	}
}
