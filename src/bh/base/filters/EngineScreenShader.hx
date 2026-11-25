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

	A shader that moves for long should move by `loopTime` (seconds into a loop of `LOOP` seconds)
	and `loops` (the loops gone, counted up to 1024 and round again), not by `time`: a GPU may run a
	page's shaders at 16-bit precision, where `time` has no fraction left after 1024 seconds and is
	too coarse for motion long before. Beat a whole number of times a loop and the loop has no seam.
**/
class EngineScreenShader extends h3d.shader.ScreenShader {
	/** The length of a loop of `loopTime`, in seconds. **/
	public static inline final LOOP:Float = 32;

	/** `loops` goes round after this many: a whole number a 16-bit float holds exactly. **/
	public static inline final LOOPS:Float = 1024;

	static var SRC = {
		@param var texture:Sampler2D;
		@param var size:Vec2;
		@param var time:Float;
		@param var loopTime:Float;
		@param var loops:Float;
	};

	/** The clock given to a shader: `time`, and `loopTime` and `loops` worked out at full precision on the CPU. **/
	public function setClock(now:Float):Void {
		time = now;
		final loop = Math.floor(now / LOOP);
		loopTime = now - loop * LOOP;
		loops = loop - Math.floor(loop / LOOPS) * LOOPS;
	}
}
