package bh.base.filters;

/**
	What every shader a filter draws with has: the picture under it (`texture`), that picture's size
	in pixels (`size`) and the game's clock (`time`, from `bh.base.ShaderClock`). A shader of the
	engine's, or of a game's own, extends it and writes `pixelColor` from `calculatedUV`:

	```haxe
	class Sepia extends bh.base.filters.EngineScreenShader {
		static var SRC = {
			@param var amount:Float;
			function fragment() {
				var c:Vec4 = texture.get(calculatedUV);
				var grey = dot(c.rgb, vec3(0.299, 0.587, 0.114));
				pixelColor = vec4(mix(c.rgb, vec3(grey * 1.1, grey, grey * 0.8), amount), c.a);
			}
		};
	}
	```

	The picture is premultiplied, as Heaps draws into a filter: colour times alpha. A shader that
	works on the colour itself divides by alpha first and multiplies again after (see `grade`).
**/
class EngineScreenShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture:Sampler2D;
		@param var size:Vec2;
		@param var time:Float;
	};
}
