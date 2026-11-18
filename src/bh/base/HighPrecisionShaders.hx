package bh.base;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/**
	Fragment shaders at high precision where the GPU has it. Heaps' `hxsl.GlslOut` writes
	`precision mediump float;` for every fragment shader, and on many phones and some laptops
	mediump is a 16-bit float: a hash of numbers in the thousands comes out about 0 everywhere, and
	a shader's `time` has no fraction left after 1024 seconds. This build macro, put on `GlslOut` by
	`AtlasMacroInit.init()`, writes in its place highp when `GL_FRAGMENT_PRECISION_HIGH` is defined,
	mediump otherwise (desktop GL ignores both). Compile with `-D multianim_mediump` to keep Heaps' line.
**/
class HighPrecisionShaders {
	static final MEDIUMP = "precision mediump float;";

	/** Starts with a comment, not `#`: `GlslOut.decl` moves a line that starts with `#` to the top, above `#extension`. **/
	static final HIGHP_WHERE_HELD = "// fragment precision: highp where the GPU has it (hx-multianim)\n#ifdef GL_FRAGMENT_PRECISION_HIGH\nprecision highp float;\n#else\nprecision mediump float;\n#endif";

	public static function init():Void {
		if (Context.defined("multianim_mediump")) return;
		haxe.macro.Compiler.addMetadata("@:build(bh.base.HighPrecisionShaders.build())", "hxsl.GlslOut");
	}

	public static function build():Array<Field> {
		final fields = Context.getBuildFields();
		var replaced = 0;
		function walk(e:Expr):Expr {
			return switch e.expr {
				case EConst(CString(s, _)) if (s == MEDIUMP):
					replaced++;
					{expr: EConst(CString(HIGHP_WHERE_HELD)), pos: e.pos};
				default:
					haxe.macro.ExprTools.map(e, walk);
			};
		}
		for (field in fields)
			switch field.kind {
				case FFun(fn) if (fn.expr != null):
					fn.expr = walk(fn.expr);
				default:
			}
		if (replaced == 0)
			Context.warning('hx-multianim: hxsl.GlslOut no longer writes "$MEDIUMP"; fragment shaders keep the precision Heaps gives them', Context.currentPos());
		return fields;
	}
}
#end
