package bh.base.shaders;

import bh.base.filters.EngineScreenShader;
import bh.base.filters.EngineShaderFilter;

/**
	The engine's shaders, each a filter (`filter: crt(curve: 0.15)`, on a screen with
	`ScreenManager.setStageShader`, or as a ground with `generated(shader(…))`). What each is and its
	parameters are `bh.multianim.ShaderCatalog`'s; `FilterManager` fills in every value a `.manim`
	leaves out from there before `make` is called, so `make` is always given them all.

	Every shader reads a premultiplied picture (Heaps' filters draw colour times alpha) and writes one.
	Their noise is a hash of arithmetic, never `sin` of a large number, so it draws alike on every GPU.
**/
class BuiltinShaders {
	/** A built-in shader's filter with its first values, or null when the name is none of them. **/
	public static function make(name:String, params:Map<String, Dynamic>):Null<EngineShaderFilter> {
		return switch name.toLowerCase() {
			case "crt": EngineShaderFilter.of("crt", new CrtShader(), (s, p) -> {
					s.curve = num(p["curve"]);
					s.scanlines = num(p["scanlines"]);
					s.lineSize = Math.max(1, num(p["lineSize"]));
					s.vignette = num(p["vignette"]);
					s.shift = num(p["shift"]);
					s.flicker = num(p["flicker"]);
				}, params);
			case "scanlines": EngineShaderFilter.of("scanlines", new ScanlinesShader(), (s, p) -> {
					s.strength = num(p["strength"]);
					s.spacing = Math.max(2, num(p["spacing"]));
				}, params);
			case "vignette": EngineShaderFilter.of("vignette", new VignetteShader(), (s, p) -> {
					s.strength = num(p["strength"]);
					s.radius = num(p["radius"]);
					s.softness = Math.max(0.0001, num(p["softness"]));
					EngineShaderFilter.rgb(s.color, int(p["color"]));
				}, params);
			case "grade": EngineShaderFilter.of("grade", new GradeShader(), (s, p) -> {
					s.brightness = num(p["brightness"]);
					s.contrast = num(p["contrast"]);
					s.saturation = num(p["saturation"]);
					EngineShaderFilter.rgb(s.tint, int(p["tint"]));
					s.tintAmount = num(p["tintAmount"]);
				}, params);
			case "palettelock": EngineShaderFilter.of("paletteLock", new PaletteLockShader(), (s, p) -> {
					final given:Dynamic = p["palette"];
					final colors:Array<Int> = given != null ? cast given : [0x000000, 0xFFFFFF];
					s.palette = paletteTexture(colors);
					s.count = Math.min(colors.length, PaletteLockShader.MOST);
					s.dither = num(p["dither"]);
				}, params);
			case "pixelate": EngineShaderFilter.of("pixelate", new PixelateShader(), (s, p) -> {
					s.block = Math.max(1, num(p["size"]));
				}, params);
			case "dither": EngineShaderFilter.of("dither", new DitherShader(), (s, p) -> {
					s.levels = Math.max(2, num(p["levels"]));
					s.cell = Math.max(1, num(p["size"]));
				}, params);
			case "aberration": EngineShaderFilter.of("aberration", new AberrationShader(), (s, p) -> {
					final angle = hxd.Math.degToRad(num(p["angle"]));
					final amount = num(p["amount"]);
					s.offset.set(Math.cos(angle) * amount, Math.sin(angle) * amount);
				}, params, p -> num(p["amount"]));
			case "wave": EngineShaderFilter.of("wave", new WaveShader(), (s, p) -> {
					s.amplitude = num(p["amplitude"]);
					s.frequency = num(p["frequency"]);
					s.speed = num(p["speed"]);
				}, params, p -> Math.ceil(num(p["amplitude"])));
			case "shockwave": EngineShaderFilter.of("shockwave", new ShockwaveShader(), (s, p) -> {
					s.centre.set(num(p["x"]), num(p["y"]));
					s.radius = num(p["radius"]);
					s.thickness = Math.max(0.0001, num(p["thickness"]));
					s.strength = num(p["strength"]);
				}, params);
			case "fog": EngineShaderFilter.of("fog", new FogShader(), (s, p) -> {
					EngineShaderFilter.rgb(s.color, int(p["color"]));
					s.amount = num(p["amount"]);
					s.scale = Math.max(0.5, num(p["scale"]));
					s.speed = num(p["speed"]);
					s.ground = p["ground"] == true ? 1 : 0;
				}, params);
			case "flash": EngineShaderFilter.of("flash", new FlashShader(), (s, p) -> {
					EngineShaderFilter.rgb(s.color, int(p["color"]));
					s.amount = num(p["amount"]);
				}, params);
			case "dissolve": EngineShaderFilter.of("dissolve", new DissolveShader(), (s, p) -> {
					s.amount = num(p["amount"]);
					s.edge = num(p["edge"]);
					EngineShaderFilter.rgb(s.edgeColor, int(p["edgeColor"]));
					s.grain = Math.max(1, num(p["grain"]));
					s.seed = num(p["seed"]);
				}, params);
			case "shimmer": EngineShaderFilter.of("shimmer", new ShimmerShader(), (s, p) -> {
					EngineShaderFilter.rgb(s.color, int(p["color"]));
					s.strength = num(p["strength"]);
					s.width = Math.max(0.001, num(p["width"]));
					s.every = Math.max(0.05, num(p["every"]));
				}, params);
			case "pulse": EngineShaderFilter.of("pulse", new PulseShader(), (s, p) -> {
					EngineShaderFilter.rgb(s.color, int(p["color"]));
					s.amount = num(p["amount"]);
					s.speed = num(p["speed"]);
				}, params);
			case "silhouette": EngineShaderFilter.of("silhouette", new SilhouetteShader(), (s, p) -> {
					EngineShaderFilter.rgb(s.color, int(p["color"]));
					s.amount = num(p["amount"]);
				}, params);
			case "water": EngineShaderFilter.of("water", new WaterShader(), (s, p) -> {
					EngineShaderFilter.rgb(s.deep, int(p["deep"]));
					EngineShaderFilter.rgb(s.shallow, int(p["shallow"]));
					s.scale = Math.max(1, num(p["scale"]));
					s.speed = num(p["speed"]);
				}, params);
			case "sky": EngineShaderFilter.of("sky", new SkyShader(), (s, p) -> {
					EngineShaderFilter.rgb(s.top, int(p["top"]));
					EngineShaderFilter.rgb(s.bottom, int(p["bottom"]));
					s.clouds = num(p["clouds"]);
					s.scale = Math.max(1, num(p["scale"]));
					s.speed = num(p["speed"]);
				}, params);
			case "stars": EngineShaderFilter.of("stars", new StarsShader(), (s, p) -> {
					s.density = num(p["density"]);
					s.twinkle = num(p["twinkle"]);
					s.speed = num(p["speed"]);
					EngineShaderFilter.rgb(s.color, int(p["color"]));
				}, params);
			default: null;
		};
	}

	// HL's Dynamic loses Int/Float through a Map<String, Dynamic>: read each as the type it is meant to be.
	static function num(v:Dynamic):Float {
		if (v == null) return 0;
		if (v is Int) return (v : Int) * 1.0;
		if (v is Bool) return (v : Bool) ? 1 : 0;
		return (v : Float);
	}

	static function int(v:Dynamic):Int {
		if (v == null) return 0;
		if (v is Float) return Std.int((v : Float));
		return (v : Int);
	}

	/** A palette as a row of pixels, one a colour, made once for each set of colours. **/
	static final palettes:Map<String, h3d.mat.Texture> = [];

	static function paletteTexture(colors:Array<Int>):h3d.mat.Texture {
		final key = colors.join(",");
		final had = palettes.get(key);
		if (had != null && !had.isDisposed())
			return had;
		final n = Std.int(Math.max(1, Math.min(colors.length, PaletteLockShader.MOST)));
		final pixels = hxd.Pixels.alloc(n, 1, hxd.PixelFormat.RGBA);
		for (i in 0...n)
			pixels.setPixel(i, 0, 0xFF000000 | (colors[i] & 0xFFFFFF));
		final texture = h3d.mat.Texture.fromPixels(pixels);
		texture.filter = Nearest;
		palettes.set(key, texture);
		return texture;
	}
}

// ---- over a screen

private class CrtShader extends EngineScreenShader {
	static var SRC = {
		@param var curve:Float;
		@param var scanlines:Float;
		@param var lineSize:Float;
		@param var vignette:Float;
		@param var shift:Float;
		@param var flicker:Float;

		function fragment() {
			// The picture bent outwards from the middle, as a tube's glass is
			var c = calculatedUV * 2.0 - 1.0;
			c = c * (1.0 + curve * dot(c, c));
			var uv = c * 0.5 + 0.5;
			var inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
			var dx = vec2(shift / size.x, 0.0);
			var g:Vec4 = texture.get(uv);
			var r:Vec4 = texture.get(uv + dx);
			var b:Vec4 = texture.get(uv - dx);
			var rgb = vec3(r.r, g.g, b.b);
			var a = max(g.a, max(r.a, b.a));
			// The lines by the picture's own rows; darkest midway between two
			var row = fract(uv.y * size.y / lineSize);
			var line = 1.0 - scanlines * (1.0 - abs(row * 2.0 - 1.0));
			var dark = 1.0 - vignette * smoothstep(0.5, 1.5, length(c));
			// A flicker of the whole picture, a new level 24 times a second
			var f = 1.0 - flicker * fract(floor(time * 24.0) * 0.6180339);
			// Outside the tube's glass, black: a screen's edge, never what is behind the stage
			pixelColor = vec4(rgb * line * dark * f * inside, mix(1.0, a, inside));
		}
	};
}

private class ScanlinesShader extends EngineScreenShader {
	static var SRC = {
		@param var strength:Float;
		@param var spacing:Float;

		function fragment() {
			var c:Vec4 = texture.get(calculatedUV);
			var row = fract(calculatedUV.y * size.y / spacing);
			var dark = step(1.0 - 1.0 / spacing, row);
			pixelColor = vec4(c.rgb * (1.0 - strength * dark), c.a);
		}
	};
}

private class VignetteShader extends EngineScreenShader {
	static var SRC = {
		@param var strength:Float;
		@param var radius:Float;
		@param var softness:Float;
		@param var color:Vec3;

		function fragment() {
			var c:Vec4 = texture.get(calculatedUV);
			// 0 in the middle, 1 in a corner
			var d = length(calculatedUV - 0.5) * 1.4142136;
			var k = clamp((d - (radius - softness)) / softness, 0.0, 1.0);
			k = k * k * (3.0 - 2.0 * k);
			pixelColor = vec4(mix(c.rgb, color * c.a, strength * k), c.a);
		}
	};
}

private class GradeShader extends EngineScreenShader {
	static var SRC = {
		@param var brightness:Float;
		@param var contrast:Float;
		@param var saturation:Float;
		@param var tint:Vec3;
		@param var tintAmount:Float;

		function fragment() {
			var c:Vec4 = texture.get(calculatedUV);
			var rgb = c.rgb / max(c.a, 0.0001);
			rgb = rgb * brightness;
			rgb = (rgb - 0.5) * contrast + 0.5;
			var luma = dot(rgb, vec3(0.299, 0.587, 0.114));
			rgb = mix(vec3(luma, luma, luma), rgb, saturation);
			rgb = mix(rgb, rgb * tint, tintAmount);
			pixelColor = vec4(clamp(rgb, 0.0, 1.0) * c.a, c.a);
		}
	};
}

private class PaletteLockShader extends EngineScreenShader {
	/** The most colours a palette may have here: the shader looks at each. **/
	public static inline var MOST = 64;

	static var SRC = {
		@param var palette:Sampler2D;
		@param var count:Float;
		@param var dither:Float;

		// An ordered dither's threshold, 0 to 1, from the pixel: Bayer 4x4 in arithmetic
		function bayer2(p:Vec2):Float {
			var q = floor(p);
			return fract(q.x * 0.5 + q.y * q.y * 0.75);
		}

		function fragment() {
			var c:Vec4 = texture.get(calculatedUV);
			var rgb = c.rgb / max(c.a, 0.0001);
			var pixel = calculatedUV * size;
			var b = bayer2(pixel * 0.5) * 0.25 + bayer2(pixel);
			rgb = rgb + (b - 0.5) * dither * 0.25;
			var best = vec3(0.0, 0.0, 0.0);
			var bestD = 1000.0;
			var fi = 0.0;
			for (i in 0...64) {
				var col:Vec3 = palette.get(vec2((fi + 0.5) / count, 0.5)).rgb;
				var e = rgb - col;
				var d = dot(e, e) + step(count - 0.5, fi) * 1000.0;
				var nearer = step(d, bestD);
				best = mix(best, col, nearer);
				bestD = min(d, bestD);
				fi = fi + 1.0;
			}
			pixelColor = vec4(best * c.a, c.a);
		}
	};
}

private class PixelateShader extends EngineScreenShader {
	static var SRC = {
		@param var block:Float;

		function fragment() {
			var cell = (floor(calculatedUV * size / block) + 0.5) * block / size;
			pixelColor = texture.get(cell);
		}
	};
}

private class DitherShader extends EngineScreenShader {
	static var SRC = {
		@param var levels:Float;
		@param var cell:Float;

		function bayer2(p:Vec2):Float {
			var q = floor(p);
			return fract(q.x * 0.5 + q.y * q.y * 0.75);
		}

		function fragment() {
			var c:Vec4 = texture.get(calculatedUV);
			var rgb = c.rgb / max(c.a, 0.0001);
			var p = floor(calculatedUV * size / cell);
			var b = bayer2(p * 0.5) * 0.25 + bayer2(p);
			var steps = levels - 1.0;
			rgb = floor(rgb * steps + b) / steps;
			pixelColor = vec4(clamp(rgb, 0.0, 1.0) * c.a, c.a);
		}
	};
}

private class AberrationShader extends EngineScreenShader {
	static var SRC = {
		@param var offset:Vec2;

		function fragment() {
			// Apart by nothing in the middle and by the whole amount at the edges
			var far = length(calculatedUV - 0.5) * 2.0;
			var d = offset / size * far;
			var r:Vec4 = texture.get(calculatedUV + d);
			var g:Vec4 = texture.get(calculatedUV);
			var b:Vec4 = texture.get(calculatedUV - d);
			pixelColor = vec4(r.r, g.g, b.b, max(g.a, max(r.a, b.a)));
		}
	};
}

private class WaveShader extends EngineScreenShader {
	static var SRC = {
		@param var amplitude:Float;
		@param var frequency:Float;
		@param var speed:Float;

		function fragment() {
			var phase = fract(calculatedUV.y * frequency + time * speed) * 6.2831853;
			var dx = amplitude / size.x * sin(phase);
			pixelColor = texture.get(calculatedUV + vec2(dx, 0.0));
		}
	};
}

private class ShockwaveShader extends EngineScreenShader {
	static var SRC = {
		@param var centre:Vec2;
		@param var radius:Float;
		@param var thickness:Float;
		@param var strength:Float;

		function fragment() {
			var aspect = size.x / size.y;
			var p = (calculatedUV - centre) * vec2(aspect, 1.0);
			var d = length(p);
			var ring = 1.0 - smoothstep(0.0, thickness, abs(d - radius));
			var dir = p / max(d, 0.0001);
			var push = dir * strength * ring / vec2(aspect, 1.0);
			pixelColor = texture.get(calculatedUV - push);
		}
	};
}

private class FogShader extends EngineScreenShader {
	static var SRC = {
		@param var color:Vec3;
		@param var amount:Float;
		@param var scale:Float;
		@param var speed:Float;
		/** 1 when drawn as a ground, from nothing; 0 over a picture. **/
		@param var ground:Float;

		function hash(p:Vec2):Float {
			var p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
			p3 = p3 + dot(p3, vec3(p3.y, p3.z, p3.x) + 33.33);
			return fract((p3.x + p3.y) * p3.z);
		}

		function noise(p:Vec2):Float {
			var i = floor(p);
			var f = fract(p);
			var u = f * f * (3.0 - 2.0 * f);
			return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
		}

		function fragment() {
			var c:Vec4 = texture.get(calculatedUV);
			var p = calculatedUV * size / (scale * 8.0) + vec2(time * speed, time * speed * 0.3);
			var n = noise(p) * 0.5 + noise(p * 2.03 + vec2(1.7, 9.2)) * 0.3 + noise(p * 4.01 + vec2(8.3, 2.8)) * 0.2;
			var k = clamp(n * amount * 1.6 - (1.0 - amount) * 0.2, 0.0, 1.0);
			var over = vec4(mix(c.rgb, color * c.a, k), c.a);
			var drawn = vec4(color * k, k);
			pixelColor = mix(over, drawn, ground);
		}
	};
}

// ---- on a thing

private class FlashShader extends EngineScreenShader {
	static var SRC = {
		@param var color:Vec3;
		@param var amount:Float;

		function fragment() {
			var c:Vec4 = texture.get(calculatedUV);
			pixelColor = vec4(mix(c.rgb, color * c.a, amount), c.a);
		}
	};
}

private class DissolveShader extends EngineScreenShader {
	static var SRC = {
		@param var amount:Float;
		@param var edge:Float;
		@param var edgeColor:Vec3;
		@param var grain:Float;
		@param var seed:Float;

		function hash(p:Vec2):Float {
			var p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
			p3 = p3 + dot(p3, vec3(p3.y, p3.z, p3.x) + 33.33);
			return fract((p3.x + p3.y) * p3.z);
		}

		function fragment() {
			var c:Vec4 = texture.get(calculatedUV);
			var n = hash(floor(calculatedUV * size / grain) + vec2(seed * 7.13, seed * 3.71));
			var kept = step(amount, n) * step(0.0001, 1.0 - amount);
			// The burning edge only once it has begun
			var e = edge * step(0.0001, amount);
			var burning = kept * (1.0 - step(amount + e, n));
			var rgb = mix(c.rgb, edgeColor * c.a, burning);
			pixelColor = vec4(rgb, c.a) * kept;
		}
	};
}

private class ShimmerShader extends EngineScreenShader {
	static var SRC = {
		@param var color:Vec3;
		@param var strength:Float;
		@param var width:Float;
		@param var every:Float;

		function fragment() {
			var c:Vec4 = texture.get(calculatedUV);
			// A sweep of 0.6 s (or the whole wait, if shorter), then nothing until the next
			var sweep = min(0.6, every);
			var t = clamp(fract(time / every) * every / sweep, 0.0, 1.0);
			var centre = t * (1.0 + 2.0 * width) - width;
			var d = abs((calculatedUV.x + calculatedUV.y) * 0.5 - centre);
			var k = (1.0 - smoothstep(0.0, width, d)) * strength;
			pixelColor = vec4(mix(c.rgb, color * c.a, k), c.a);
		}
	};
}

private class PulseShader extends EngineScreenShader {
	static var SRC = {
		@param var color:Vec3;
		@param var amount:Float;
		@param var speed:Float;

		function fragment() {
			var c:Vec4 = texture.get(calculatedUV);
			var k = amount * (0.5 - 0.5 * cos(fract(time * speed) * 6.2831853));
			pixelColor = vec4(mix(c.rgb, color * c.a, k), c.a);
		}
	};
}

private class SilhouetteShader extends EngineScreenShader {
	static var SRC = {
		@param var color:Vec3;
		@param var amount:Float;

		function fragment() {
			var c:Vec4 = texture.get(calculatedUV);
			pixelColor = vec4(mix(c.rgb, color * c.a, amount), c.a);
		}
	};
}

// ---- a ground, drawn from nothing: the picture under it is not read

private class WaterShader extends EngineScreenShader {
	static var SRC = {
		@param var deep:Vec3;
		@param var shallow:Vec3;
		@param var scale:Float;
		@param var speed:Float;

		function hash(p:Vec2):Float {
			var p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
			p3 = p3 + dot(p3, vec3(p3.y, p3.z, p3.x) + 33.33);
			return fract((p3.x + p3.y) * p3.z);
		}

		function noise(p:Vec2):Float {
			var i = floor(p);
			var f = fract(p);
			var u = f * f * (3.0 - 2.0 * f);
			return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
		}

		function fragment() {
			var p = calculatedUV * size / scale;
			var t = time * speed;
			var n = noise(p + vec2(t * 0.3, t * 0.2)) * 0.6 + noise(p * 2.1 + vec2(-t * 0.2, t * 0.35)) * 0.4;
			var crest = smoothstep(0.62, 0.78, n);
			var rgb = mix(deep, shallow, n) + vec3(crest, crest, crest) * 0.18;
			pixelColor = vec4(clamp(rgb, 0.0, 1.0), 1.0);
		}
	};
}

private class SkyShader extends EngineScreenShader {
	static var SRC = {
		@param var top:Vec3;
		@param var bottom:Vec3;
		@param var clouds:Float;
		@param var scale:Float;
		@param var speed:Float;

		function hash(p:Vec2):Float {
			var p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
			p3 = p3 + dot(p3, vec3(p3.y, p3.z, p3.x) + 33.33);
			return fract((p3.x + p3.y) * p3.z);
		}

		function noise(p:Vec2):Float {
			var i = floor(p);
			var f = fract(p);
			var u = f * f * (3.0 - 2.0 * f);
			return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
		}

		function fragment() {
			var rgb = mix(top, bottom, calculatedUV.y);
			var p = calculatedUV * size / scale * vec2(1.0, 2.0) + vec2(time * speed, 0.0);
			var n = noise(p) * 0.55 + noise(p * 2.03 + vec2(1.7, 9.2)) * 0.3 + noise(p * 4.07 + vec2(5.2, 1.3)) * 0.15;
			var cover = smoothstep(1.0 - clouds, 1.0 - clouds + 0.25, n);
			rgb = mix(rgb, vec3(1.0, 1.0, 1.0), cover * 0.9);
			pixelColor = vec4(rgb, 1.0);
		}
	};
}

private class StarsShader extends EngineScreenShader {
	static var SRC = {
		@param var density:Float;
		@param var twinkle:Float;
		@param var speed:Float;
		@param var color:Vec3;

		function hash(p:Vec2):Float {
			var p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
			p3 = p3 + dot(p3, vec3(p3.y, p3.z, p3.x) + 33.33);
			return fract((p3.x + p3.y) * p3.z);
		}

		function fragment() {
			// The sky drifts by fractions of a pixel: a star's place is never rounded, and the pixels it
			// lies between share its light, so it glides rather than steps
			var p = calculatedUV * size + vec2(time * speed * 12.0, 0.0);
			var cell = floor(p / 8.0);
			var h = hash(cell);
			// Somewhere in its cell of 8 pixels, kept off the edges so its light stays in the cell
			var at = cell * 8.0 + 1.5 + vec2(hash(cell + vec2(1.7, 0.0)), hash(cell + vec2(0.0, 3.1))) * 5.0;
			var isStar = step(1.0 - density * 0.3, h);
			var light = 1.0 - smoothstep(0.25, 1.0, length(p - at));
			var glow = 1.0 - twinkle * (0.5 + 0.5 * sin(fract(time * 0.7 + h * 13.0) * 6.2831853));
			var bright = isStar * light * glow * (0.55 + 0.45 * hash(cell + vec2(5.3, 7.7)));
			pixelColor = vec4(mix(color, vec3(1.0, 1.0, 1.0), bright), 1.0);
		}
	};
}
