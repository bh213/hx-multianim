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
		this.target = 'engineShader' + (made++);
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

	override function sync(ctx:h2d.RenderContext, s:h2d.Object):Void {
		super.sync(ctx, s);
		owner = s;
	}

	override function draw(ctx:h2d.RenderContext, t:h2d.Tile):h2d.Tile {
		final whole = findWhole(ctx, t);
		final texture = whole ? placedInWhole(ctx, t) : t.getTexture();
		final out = whole ? ctx.textures.allocTarget(target, wholeW, wholeH, false) : ctx.textures.allocTileTarget(target, t);
		ctx.engine.pushTarget(out);
		shader.texture = texture;
		shader.size.set(texture.width, texture.height);
		shader.setClock(bh.base.ShaderClock.now());
		pass.render();
		ctx.engine.popTarget();
		final drawn = h2d.Tile.fromTexture(out);
		if (whole) {
			// where the whole tile starts, from where the part Heaps drew starts (drawFilters adds that back)
			drawn.dx = wholeDx;
			drawn.dy = wholeDy;
		}
		return drawn;
	}

	/** The thing the filter is on, kept at `sync`: what its whole tile is measured by. **/
	var owner:Null<h2d.Object>;

	/** The widest or tallest whole tile drawn whole: past it a filter shades only the part on the stage. **/
	public static var wholeLimit = 4096;

	/** The owner's bounds, measured into this every draw: one per filter, and `draw` runs no game code
		between writing it and reading it, so nothing else reaches it meanwhile. **/
	final wholeBounds = new h2d.col.Bounds();

	/** The whole tile `findWhole` found: its size in the filter's pixels and where it starts from the part drawn. **/
	var wholeW = 0;
	var wholeH = 0;
	var wholeDx = 0;
	var wholeDy = 0;

	/**
		Whether Heaps cut the filter's picture down to the part on the stage (`Object.clipBounds`) and the whole
		tile is to be drawn: `wholeW`, `wholeH`, `wholeDx`, `wholeDy` then say where it is. False when the part is
		the whole, or the whole is past `wholeLimit`. A shader's `calculatedUV` and `size` then mean the whole tile,
		as they do on the stage: a disc half off the edge is drawn as half a disc, not as a smaller one in the half
		shown. Allocates nothing.
	**/
	function findWhole(ctx:h2d.RenderContext, t:h2d.Tile):Bool {
		final s = owner;
		if (s == null || !autoBounds || boundsExtend < 0) return false;
		final stack = @:privateAccess ctx.inFilter;
		if (stack == null || stack.spr != s) return false;
		final sx = stack.scaleX, sy = stack.scaleY;
		final b = s.getBounds(s, wholeBounds); // getBounds empties it first
		if (b.isEmpty()) return false;
		final xMin = Math.floor(b.xMin * sx - boundsExtend + 1e-10);
		final yMin = Math.floor(b.yMin * sy - boundsExtend + 1e-10);
		final w = Math.ceil(b.xMax * sx + boundsExtend - xMin - 1e-10);
		final h = Math.ceil(b.yMax * sy + boundsExtend - yMin - 1e-10);
		// the part drawn: where it starts, in the filter's pixels, and its size
		final cx = Math.round(t.dx * sx), cy = Math.round(t.dy * sy);
		final cw = t.getTexture().width, ch = t.getTexture().height;
		if (cx <= xMin && cy <= yMin && cx + cw >= xMin + w && cy + ch >= yMin + h) return false;
		if (w <= 0 || h <= 0 || w > wholeLimit || h > wholeLimit) return false;
		wholeW = w;
		wholeH = h;
		wholeDx = xMin - cx;
		wholeDy = yMin - cy;
		return true;
	}

	/** Lays the part into the whole: made the first time a filter is drawn off the stage, null until then. **/
	var place:Null<h3d.pass.ScreenFx<PlaceShader>>;

	/** The part Heaps drew laid into a clear picture of the whole tile (`findWhole`'s), where it sits in it. **/
	function placedInWhole(ctx:h2d.RenderContext, t:h2d.Tile):h3d.mat.Texture {
		var place = this.place;
		if (place == null)
			this.place = place = new h3d.pass.ScreenFx(new PlaceShader());
		final part = t.getTexture();
		final full = ctx.textures.allocTarget(target + "Whole", wholeW, wholeH, false);
		ctx.engine.pushTarget(full);
		ctx.engine.clear(0);
		place.shader.texture = part;
		// a pixel of the whole at uv is the part's at (uv * whole - offset) / part
		place.shader.scale.set(wholeW / part.width, wholeH / part.height);
		place.shader.offset.set(-wholeDx / part.width, -wholeDy / part.height);
		place.render();
		ctx.engine.popTarget();
		return full;
	}

	/** A colour of a `.manim` (`0xRRGGBB`) into a shader's `Vec3`. **/
	public static inline function rgb(into:h3d.Vector, color:Int):Void {
		into.set(((color >> 16) & 0xFF) / 255, ((color >> 8) & 0xFF) / 255, (color & 0xFF) / 255);
	}
}

/** Lays a picture into a bigger one: `scale` and `offset` take the bigger one's uv to the picture's; outside it, clear. **/
private class PlaceShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture:Sampler2D;
		@param var scale:Vec2;
		@param var offset:Vec2;
		function fragment() {
			var uv = calculatedUV * scale - offset;
			var inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
			pixelColor = texture.get(uv) * inside;
		}
	};
}
