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

		// Portable hash — arithmetic only, no sin() (deterministic across GPUs)
		function hash(p:Vec2):Float {
			var ax = fract(p.x * 0.1031 + seed * 0.1);
			var ay = fract(p.y * 0.1030 + seed * 0.2);
			var az = fract(p.x * 0.0973 + seed * 0.3);
			var d = ax * (ay + 33.33) + ay * (az + 33.33) + az * (ax + 33.33);
			return fract((ax + d + ay + d) * (az + d));
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
			var p0 = input.uv * noiseScale;

			// fBM — 4 octaves for smooth, detailed noise
			var n = 0.5 * noise(p0);
			var p1 = p0 * 2.0 + vec2(1.7, 9.2);
			n = n + 0.25 * noise(p1);
			var p2 = p1 * 2.0 + vec2(1.7, 9.2);
			n = n + 0.125 * noise(p2);
			var p3 = p2 * 2.0 + vec2(1.7, 9.2);
			n = n + 0.0625 * noise(p3);

			var noiseColor = vec3(n, n, n);
			color.rgb = mix(color.rgb, noiseColor, intensity * color.a);
			output.color = color;
		}
	};
}
