package bh.base;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/**
	A mask (`h2d.Mask`, a list's clip) inside a filtered object clips where it is drawn. Heaps'
	`h2d.RenderContext.setRZ` maps the zone into the filter's texture and then through the screen's
	viewport as well (`scene.viewportA * engine.width / 2`, `viewportX`), as if it were drawing to the
	screen, and never takes away where the filter's texture starts: a mask under a filter clips off to
	the side by the content left of it, and at a page zoom that is not whole by the zoom again. This
	build macro, put on `RenderContext` by `AtlasMacroInit.init()`, maps the zone through the target
	the filter draws into (its own view, `pushTarget`'s) instead. Drawing to the screen is as Heaps has
	it. Compile with `-D multianim_heaps_render_zone` to keep Heaps' `setRZ` whole.
**/
class FilterRenderZone {
	public static function init():Void {
		if (Context.defined("multianim_heaps_render_zone")) return;
		haxe.macro.Compiler.addMetadata("@:build(bh.base.FilterRenderZone.build())", "h2d.RenderContext");
	}

	public static function build():Array<Field> {
		final fields = Context.getBuildFields();
		for (field in fields) {
			if (field.name != "setRZ")
				continue;
			switch field.kind {
				case FFun(fn) if (fn.expr != null && fn.args.length == 4 && haxe.macro.ExprTools.toString(fn.expr).indexOf("filterMatrixA") >= 0):
					final heaps = fn.expr;
					fn.expr = macro {
						if (inFilter != null && curTarget != null) {
							hasRenderZone = true;
							renderX = x;
							renderY = y;
							renderW = w;
							renderH = h;
							// the zone in the filtered object's frame (the filter matrix), then in the
							// pixels of the texture the filter draws into, through that target's view
							final fa = baseShader.filterMatrixA;
							final fb = baseShader.filterMatrixB;
							final x2 = x + w;
							final y2 = y + h;
							final rx1 = x * fa.x + y * fa.y + fa.z;
							final ry1 = x * fb.x + y * fb.y + fb.z;
							final rx2 = x2 * fa.x + y2 * fa.y + fa.z;
							final ry2 = x2 * fb.x + y2 * fb.y + fb.z;
							final halfW = curTarget.width / 2;
							final halfH = curTarget.height / 2;
							final px1 = (rx1 * viewA + viewX + 1) * halfW;
							final py1 = (ry1 * viewD + viewY + 1) * halfH;
							final px2 = (rx2 * viewA + viewX + 1) * halfW;
							final py2 = (ry2 * viewD + viewY + 1) * halfH;
							engine.setRenderZone(Std.int(px1 + 1e-10), Std.int(py1 + 1e-10), Std.int(px2 - px1 + 1e-10), Std.int(py2 - py1 + 1e-10));
							return;
						}
						$heaps;
					};
					return fields;
				default:
			}
		}
		Context.warning("hx-multianim: h2d.RenderContext.setRZ is no longer as it was; a mask inside a filter clips where Heaps puts it", Context.currentPos());
		return fields;
	}
}
#end
