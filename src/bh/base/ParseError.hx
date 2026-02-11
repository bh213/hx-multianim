package bh.base;

/**
	Base class for parser errors.
	Standalone replacement for hxparse.ParserError.
**/
class ParseError {
	public var pos(default, null):ParsePosition;

	public function new(pos:ParsePosition) {
		this.pos = pos;
	}

	public function toString() {
		return "Parser error";
	}
}

/**
	Unexpected token error.
	Standalone replacement for hxparse.Unexpected.
**/
class ParseUnexpected<Token> extends ParseError {
	public var token:Token;

	public function new(token:Token, pos:ParsePosition) {
		super(pos);
		this.token = token;
	}

	override public function toString() {
		return 'Unexpected $token';
	}
}
