package bh.base;

import bh.base.Atlas2.IAtlas2;
import h2d.ScaleGrid;

/**
	A nine-patch drawn from the frames of an indexed atlas name (`Button_Warning_3x3_idle` with
	`index: 0..3`), played in a loop at `fps` from `sync`, like an animated terrain: nothing to call
	from the game loop. `fps` 0 holds `frameIndex`; `frames` has one tile for every frame, all with
	the borders of the first.

	`ninepatch("ui", "button", w, h, fps: 8)` builds one; `ninepatch(…, index: 3)` is a plain
	`h2d.ScaleGrid` of that frame.
**/
class AnimatedScaleGrid extends ScaleGrid {
	public final frames:Array<h2d.Tile>;
	public var fps:Float;
	public var frameIndex(default, null):Int = 0;
	var time:Float = 0;

	public function new(frames:Array<h2d.Tile>, borderL:Int, borderT:Int, borderR:Int, borderB:Int, fps:Float, ?parent:h2d.Object) {
		if (frames.length == 0)
			throw "AnimatedScaleGrid needs at least one frame";
		super(frames[0], borderL, borderT, borderR, borderB, parent);
		this.frames = frames;
		this.fps = fps;
	}

	/** Shows frame `index` (wrapped) now and restarts the clock from it. */
	public function seek(index:Int):Void {
		final n = frames.length;
		frameIndex = ((index % n) + n) % n;
		time = frameIndex / (fps > 0 ? fps : 1);
		tile = frames[frameIndex];
	}

	/** Advances the animation by `dt` seconds, as `sync` does every frame. */
	public function advance(dt:Float):Void {
		if (fps <= 0 || frames.length < 2)
			return;
		time += dt;
		final idx = Std.int(time * fps) % frames.length;
		if (idx != frameIndex) {
			frameIndex = idx;
			tile = frames[idx]; // ScaleGrid.checkUpdate redraws when the tile changed
		}
	}

	override function sync(ctx:h2d.RenderContext) {
		advance(ctx.elapsedTime);
		super.sync(ctx);
	}

	/** Every frame of the nine-patch `name` in `atlas`, as one animated grid. Throws when the name
	 *  is not a nine-patch or its frames are not split alike. */
	public static function fromAtlas(atlas:IAtlas2, sheetName:String, name:String, fps:Float):AnimatedScaleGrid {
		final count = atlas.ninePatchFrameCount(name);
		if (count <= 0)
			throw 'tile $name in sheet $sheetName could not be loaded';
		final first = atlas.getNinePatch(name, 0);
		if (first == null)
			throw 'tile $name in sheet $sheetName could not be loaded';
		final tiles = [first.tile];
		for (i in 1...count) {
			final sg = atlas.getNinePatch(name, i);
			if (sg == null)
				throw 'tile $name in sheet $sheetName has no frame $i';
			if (sg.borderLeft != first.borderLeft || sg.borderRight != first.borderRight || sg.borderTop != first.borderTop
				|| sg.borderBottom != first.borderBottom)
				throw 'tile $name in sheet $sheetName: frame $i is split differently from frame 0';
			tiles.push(sg.tile);
		}
		return new AnimatedScaleGrid(tiles, first.borderLeft, first.borderTop, first.borderRight, first.borderBottom, fps);
	}
}
