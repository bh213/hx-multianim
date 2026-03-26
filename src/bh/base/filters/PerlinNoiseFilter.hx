package bh.base.filters;

class PerlinNoiseFilter extends h2d.filter.Filter {
	var pass:PerlinNoisePass;

	public var seed(get, set):Float;
	public var scale(get, set):Float;
	public var intensity(get, set):Float;

	public function new(seed:Float = 0.0, scale:Float = 10.0, intensity:Float = 0.5) {
		super();
		pass = new PerlinNoisePass();
		this.seed = seed;
		this.scale = scale;
		this.intensity = intensity;
	}

	inline function get_seed():Float return pass.seed;
	inline function set_seed(v:Float):Float { pass.seed = v; return v; }
	inline function get_scale():Float return pass.noiseScale;
	inline function set_scale(v:Float):Float { pass.noiseScale = v; return v; }
	inline function get_intensity():Float return pass.intensity;
	inline function set_intensity(v:Float):Float { pass.intensity = v; return v; }

	override function draw(ctx:h2d.RenderContext, t:h2d.Tile) {
		var out = ctx.textures.allocTileTarget("perlinNoise", t);
		pass.apply(t.getTexture(), out);
		return h2d.Tile.fromTexture(out);
	}
}

@ignore("shader")
private class PerlinNoisePass extends h3d.pass.ScreenFx<PerlinNoiseShader> {
	public var seed(default, set):Float;
	public var noiseScale(default, set):Float;
	public var intensity(default, set):Float;

	public function new() {
		super(new PerlinNoiseShader());
		seed = 0.0;
		noiseScale = 10.0;
		intensity = 0.5;
	}

	function set_seed(v:Float):Float { seed = v; shader.seed = v; return v; }
	function set_noiseScale(v:Float):Float { noiseScale = v; shader.noiseScale = v; return v; }
	function set_intensity(v:Float):Float { intensity = v; shader.intensity = v; return v; }

	public function apply(src:h3d.mat.Texture, out:h3d.mat.Texture) {
		engine.pushTarget(out);
		shader.texture = src;
		render();
		engine.popTarget();
	}
}

private class PerlinNoiseShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture:Sampler2D;
		@param var seed:Float;
		@param var noiseScale:Float;
		@param var intensity:Float;

		// Simple hash-based noise (deterministic, no texture lookups)
		function hash(p:Vec2):Float {
			var h = dot(p, vec2(127.1, 311.7));
			return fract(sin(h + seed) * 43758.5453123);
		}

		function noise(p:Vec2):Float {
			var i = floor(p);
			var f = fract(p);
			var u = f * f * (3.0 - 2.0 * f); // smoothstep

			var a = hash(i);
			var b = hash(i + vec2(1.0, 0.0));
			var c = hash(i + vec2(0.0, 1.0));
			var d = hash(i + vec2(1.0, 1.0));

			return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
		}

		function fragment() {
			var color:Vec4 = texture.get(input.uv);
			var n = noise(input.uv * noiseScale);
			// Blend noise with original color: shift toward noise gray
			var noiseColor = vec3(n, n, n);
			color.rgb = mix(color.rgb, noiseColor, intensity * color.a);
			output.color = color;
		}
	};
}
