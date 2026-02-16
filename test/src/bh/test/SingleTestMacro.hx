package bh.test;

class SingleTestMacro {
	public static macro function getDefineValue():haxe.macro.Expr {
		var value = haxe.macro.Context.definedValue("SINGLE_TEST");
		if (value == null) {
			return macro null;
		}
		return macro $v{value};
	}
}
