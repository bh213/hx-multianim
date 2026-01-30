package bh.stateanim;

/**
	Represents a single frame of animation with its tile, duration, and trimming offsets.
**/
@:nullSafety
class AnimationFrame {
	public final tile:h2d.Tile;
	// Offset for trimmed tiles
	public final offsetx:Int;
	public final offsety:Int;

	// width & height for trimmed tiles
	public final width:Int;
	public final height:Int;

	/**
		Frame display duration in seconds.
	**/
	public final duration:Float;

	public function new(tile:h2d.Tile, duration:Float, offsetx:Int, offsety:Int, width:Int, height:Int) {
		this.tile = tile;
		this.duration = duration;
		this.offsetx = offsetx;
		this.offsety = offsety;
		this.width = width;
		this.height = height;
	}

	public function cloneWithDuration(newDuration:Float):AnimationFrame {
		return new AnimationFrame(tile, newDuration, offsetx, offsety, width, height);
	}

	public function cloneWithNewTile(newTile:h2d.Tile):AnimationFrame {
		return new AnimationFrame(newTile, duration, offsetx, offsety, width, height);
	}
}
