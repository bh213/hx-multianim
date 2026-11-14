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

	/**
		This frame drawn with (`cx`, `cy`) of its untrimmed frame at the origin: a trimmed tile keeps
		its place in the untrimmed frame. This frame itself when its tile is placed so already; a
		clone of the tile otherwise (a sheet's tiles are shared).
	**/
	public function placedAbout(cx:Float, cy:Float):AnimationFrame {
		final dx = offsetx - cx;
		final dy = (height - tile.height) - offsety - cy;
		if (tile.dx == dx && tile.dy == dy)
			return this;
		final placed = tile.clone();
		placed.dx = dx;
		placed.dy = dy;
		return cloneWithNewTile(placed);
	}
}
