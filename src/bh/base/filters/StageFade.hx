package bh.base.filters;

/**
	One whole-stage shader giving way to another: both drawn from the same picture, mixed by `t`
	(0 the one going, 1 the one coming). `ScreenManager.setStageShader` puts it on the scene for the
	length of the fade and takes it off after. Either side may be none: the picture as it is.
**/
class StageFade extends h2d.filter.Filter {
	public var from:Null<h2d.filter.Filter>;
	public var to:Null<h2d.filter.Filter>;

	/** How far the fade has come, 0 to 1. **/
	public var t:Float = 0;

	final pass:h3d.pass.ScreenFx<StageFadeShader>;

	public function new(from:Null<h2d.filter.Filter>, to:Null<h2d.filter.Filter>) {
		super();
		this.from = from;
		this.to = to;
		this.pass = new h3d.pass.ScreenFx(new StageFadeShader());
	}

	override function bind(s:h2d.Object) {
		final a = from, b = to;
		if (a != null) a.bind(s);
		if (b != null) b.bind(s);
	}

	override function unbind(s:h2d.Object) {
		final a = from, b = to;
		if (a != null) a.unbind(s);
		if (b != null) b.unbind(s);
	}

	override function sync(ctx:h2d.RenderContext, s:h2d.Object) {
		boundsExtend = 0;
		for (f in [from, to])
			if (f != null && f.enable) {
				f.sync(ctx, s);
				boundsExtend = Math.max(boundsExtend, f.boundsExtend);
			}
	}

	override function draw(ctx:h2d.RenderContext, input:h2d.Tile):h2d.Tile {
		final a = drawSide(from, ctx, input);
		final b = drawSide(to, ctx, input);
		final out = ctx.textures.allocTileTarget("stageFade", input);
		ctx.engine.pushTarget(out);
		pass.shader.from = a.getTexture();
		pass.shader.to = b.getTexture();
		pass.shader.t = hxd.Math.clamp(t, 0, 1);
		pass.render();
		ctx.engine.popTarget();
		// dx/dy stay 0: Object.drawFilters adds the target's own offset to a tile a filter returns
		return h2d.Tile.fromTexture(out);
	}

	static function drawSide(f:Null<h2d.filter.Filter>, ctx:h2d.RenderContext, input:h2d.Tile):h2d.Tile {
		if (f == null || !f.enable)
			return input;
		final drawn = f.draw(ctx, input);
		return drawn != null ? drawn : input;
	}
}

private class StageFadeShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var from:Sampler2D;
		@param var to:Sampler2D;
		@param var t:Float;

		function fragment() {
			pixelColor = mix(from.get(calculatedUV), to.get(calculatedUV), t);
		}
	};
}
