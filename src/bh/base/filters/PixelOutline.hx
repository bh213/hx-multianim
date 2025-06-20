package bh.base.filters;

enum PixelOutlineFilterMode {
	Knockout(color:Int, knockout:Float);
	InlineColor(color:Int, inlineColor:Int);
}

// --- Filter -------------------------------------------------------------------------------
class PixelOutline extends h2d.filter.Filter {
	@:isVar public var mode(default, set):PixelOutlineFilterMode;

	var pass:PixelOutlinePass;

	public function new(mode, smooth) {
		super();
		pass = new PixelOutlinePass();
		this.smooth = smooth;
		this.mode = mode;
	}

	inline function set_mode(m:PixelOutlineFilterMode) {
		this.mode = m;
		switch mode {
			case Knockout(color, knockout):
				pass.color = color;
				pass.inlineColor = 0;
				pass.knockOut = knockout;

			case InlineColor(color, inlineColor):
				pass.color = color;
				pass.inlineColor = inlineColor;
				pass.knockOut = 0.;
		}
		return mode;
	}

	override function sync(ctx:h2d.RenderContext, s:h2d.Object) {
		boundsExtend = 1;
	}

	override function draw(ctx:h2d.RenderContext, t:h2d.Tile) {
		var out = ctx.textures.allocTileTarget("pixelOutline", t);
		pass.apply(t.getTexture(), out);
		return h2d.Tile.fromTexture(out);
	}
}

// --- H3D pass -------------------------------------------------------------------------------

@ignore("shader")
private class PixelOutlinePass extends h3d.pass.ScreenFx<PixelOutlineShader> {
	public var color(default, set):Int;
	public var knockOut(default, set):Float;
	public var inlineColor(default, set):Int;

	public function new() {
		super(new PixelOutlineShader());
	}

	function set_color(c) {
		if (color == c)
			return c;
		return color = c;
	}

	function set_inlineColor(c) {
		if (inlineColor == c)
			return c;
		return inlineColor = c;
	}

	function set_knockOut(v) {
		if (knockOut == v)
			return v;
		return knockOut = v;
	}

	public function apply(src:h3d.mat.Texture, out:h3d.mat.Texture) {
		engine.pushTarget(out);

		shader.texture = src;
		shader.outlineColor.setColor(color);
		shader.inlineColor.setColor(inlineColor);
		shader.pixelSize.set(1 / src.width, 1 / src.height);
		shader.knockOutMul = knockOut;
		render();

		engine.popTarget();
	}
}

// --- Shader -------------------------------------------------------------------------------
private class PixelOutlineShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture:Sampler2D;
		@param var pixelSize:Vec2;
		@param var outlineColor:Vec3;
		@param var inlineColor:Vec4;
		@param var knockOutMul:Float;
		function fragment() {
			var curColor:Vec4 = texture.get(input.uv);
			if (curColor.a == 0) {
				if (texture.get(vec2(input.uv.x + pixelSize.x, input.uv.y)).a != 0
					|| texture.get(vec2(input.uv.x - pixelSize.x, input.uv.y)).a != 0
					|| texture.get(vec2(input.uv.x, input.uv.y + pixelSize.y)).a != 0
					|| texture.get(vec2(input.uv.x, input.uv.y - pixelSize.y)).a != 0)
					output.color = vec4(outlineColor, 1);
			} else if (length(inlineColor) != 0) {
				output.color = inlineColor;
			} else
				output.color = curColor * knockOutMul;
		}
	};
}
