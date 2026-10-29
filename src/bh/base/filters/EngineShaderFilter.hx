package bh.base.filters;

/**
	A shader as a filter, set in place: `setParams` writes its uniforms, so a value changed sixty times
	a second (a slider, a `$param` the game moves) never makes the filter again. Each draws into a
	target of its own, so two of them can be drawn in one frame (a crossfade between two screens'
	shaders). Built by `FilterManager` for `filter: name(args)`; a game's own shader is made the same
	way with `EngineShaderFilter.of`, given to `FilterManager.registerFilter`:

	```haxe
	FilterManager.registerFilter("sepia", [{name: "amount", type: CFFloat, defaultValue: 0.8, min: 0, max: 1, label: "Amount"}],
		params -> EngineShaderFilter.of("sepia", new Sepia(), (s, p) -> s.amount = p["amount"], params));
	```
**/
class EngineShaderFilter extends h2d.filter.Filter {
	static var made = 0;

	/** Every shader filter off at once, drawn as if it were not there: a game seen without its shaders. **/
	public static var off:Bool = false;

	/** The name it is written by, in lower case: a filter of the same name is set in place, not made again. **/
	public final shaderName:String;

	public final shader:EngineScreenShader;

	/** The values it was last given, by parameter name: what a tool reads back. **/
	public final values:Map<String, Dynamic> = [];

	final pass:h3d.pass.ScreenFx<EngineScreenShader>;
	final apply:Map<String, Dynamic>->Void;
	final boundsOf:Null<Map<String, Dynamic>->Float>;
	final target:String;

	/**
		@param apply writes the values given into the shader's uniforms
		@param boundsOf how far it draws past the thing it is on, from its values (a wave's amplitude)
	**/
	public function new(name:String, shader:EngineScreenShader, apply:Map<String, Dynamic>->Void,
			?boundsOf:Map<String, Dynamic>->Float) {
		super();
		this.shaderName = name.toLowerCase();
		this.shader = shader;
		this.apply = apply;
		this.boundsOf = boundsOf;
		this.pass = new h3d.pass.ScreenFx(shader);
		this.target = 'engineShader${made++}';
	}

	/** A shader made into a filter with its first values: what a registered filter's factory returns. **/
	public static function of<T:EngineScreenShader>(name:String, shader:T, apply:(T, Map<String, Dynamic>) -> Void,
			params:Map<String, Dynamic>, ?boundsOf:Map<String, Dynamic>->Float):EngineShaderFilter {
		final filter = new EngineShaderFilter(name, shader, p -> apply(shader, p), boundsOf);
		filter.setParams(params);
		return filter;
	}

	/** New values, written into the shader at once: those not given keep what they were. **/
	public function setParams(params:Map<String, Dynamic>):Void {
		for (name => value in params)
			values[name] = value;
		apply(values);
		final bounds = boundsOf;
		if (bounds != null)
			boundsExtend = Math.max(0, bounds(values));
	}

	override function get_enable():Bool {
		return enable && !off;
	}

	override function draw(ctx:h2d.RenderContext, t:h2d.Tile):h2d.Tile {
		final texture = t.getTexture();
		final out = ctx.textures.allocTileTarget(target, t);
		ctx.engine.pushTarget(out);
		shader.texture = texture;
		shader.size.set(texture.width, texture.height);
		shader.time = bh.base.ShaderClock.now();
		pass.render();
		ctx.engine.popTarget();
		return h2d.Tile.fromTexture(out);
	}

	/** A colour of a `.manim` (`0xRRGGBB`) into a shader's `Vec3`. **/
	public static inline function rgb(into:h3d.Vector, color:Int):Void {
		into.set(((color >> 16) & 0xFF) / 255, ((color >> 8) & 0xFF) / 255, (color & 0xFF) / 255);
	}
}
