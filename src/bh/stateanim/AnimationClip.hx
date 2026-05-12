package bh.stateanim;

import bh.stateanim.AnimationFrame;
import h2d.Drawable;
import h2d.RenderContext;

/**
	An animation clip - a sequence of frames with durations and events.
	Completely externally driven via the `update(dt)` method.
**/
@:nullSafety
class AnimationClip extends Drawable {
	var elapsedTime:Float = 0;
	var frames:Array<AnimationFrame>;
	var currentFrameIndex:Int = 0;

	// Reused for setSingleFrame to keep the steady-state frame-swap path
	// allocation-free. Constructed once per clip; slot is always overwritten
	// before being assigned to `frames`.
	@:nullSafety(Off) final _singleFrameBuf:Array<AnimationFrame> = [null];

	// Allocation watchdog for tests. Gated behind MULTIANIM_ALLOC_TRACK so the
	// per-call increment vanishes from production builds; setFrames is the
	// array-accepting entry point and any caller invoking it on a per-frame
	// hot path (e.g. AnimationSM state advance) is paying for an Array alloc.
	#if MULTIANIM_ALLOC_TRACK
	public static var setFramesCallCount:Int = 0;
	#end

	/**
		Creates a new AnimationClip with the given frames.
		@param frames Array of AnimationFrame objects to play.
	**/
	public function new(frames:Array<AnimationFrame>, ?parent:h2d.Object) {
		super(parent);
		this.frames = frames;
	}

	/**
		Sets new frames for the animation, resetting playback to the beginning.
	**/
	public function setFrames(frames:Array<AnimationFrame>):Void {
		#if MULTIANIM_ALLOC_TRACK
		setFramesCallCount++;
		#end
		this.frames = frames;
		reset();
	}

	/**
		Replaces the playlist with a single frame without allocating a wrapper array.
		Use this on hot paths (e.g. AnimationSM frame advance) that previously called
		`setFrames([frame])` once per state change.
	**/
	public function setSingleFrame(frame:AnimationFrame):Void {
		_singleFrameBuf[0] = frame;
		this.frames = _singleFrameBuf;
		reset();
	}

	/**
		Returns the current frames array.
	**/
	public function getFrames():Array<AnimationFrame> {
		return frames;
	}

	/**
		Resets the animation to the beginning.
	**/
	public function reset():Void {
		currentFrameIndex = 0;
		elapsedTime = 0;
	}

	/**
		Returns the current frame, or null if no frames exist.
	**/
	public function getCurrentFrame():Null<AnimationFrame> {
		if (frames.length == 0)
			return null;
		return frames[currentFrameIndex];
	}

	/**
		Returns the current frame index.
	**/
	public function getCurrentFrameIndex():Int {
		return currentFrameIndex;
	}

	/**
		Sets the current frame by index.
	**/
	public function setCurrentFrameIndex(index:Int):Void {
		if (index >= 0 && index < frames.length) {
			currentFrameIndex = index;
			elapsedTime = 0;
		}
	}

	/**
		Returns true if the animation is at the last frame and elapsed time exceeds its duration.
	**/
	public function isAtEnd():Bool {
		return currentFrameIndex >= frames.length - 1 && elapsedTime >= getCurrentFrameDuration();
	}

	/**
		Returns the total number of frames.
	**/
	public function getFrameCount():Int {
		return frames.length;
	}

	/**
		Returns the current frame's duration.
	**/
	public inline function getCurrentFrameDuration():Float {
		if (frames.length == 0)
			return 0;
		return frames[currentFrameIndex].duration;
	}

	/**
		Returns the elapsed time within the current frame.
	**/
	public function getElapsedTime():Float {
		return elapsedTime;
	}

	/**
		Sets the elapsed time within the current frame.
	**/
	public function setElapsedTime(time:Float):Void {
		elapsedTime = time;
	}

	/**
		Advances the animation by the given delta time.
		Returns true if the frame changed, false otherwise.
		Does not loop - caller must handle end-of-animation.
		@param dt Delta time in seconds.
		@return True if the frame index changed.
	**/
	public function update(dt:Float):Bool {
		if (frames.length == 0)
			return false;

		elapsedTime += dt;
		var frameChanged = false;

		while (elapsedTime >= getCurrentFrameDuration() && currentFrameIndex < frames.length - 1) {
			elapsedTime -= getCurrentFrameDuration();
			currentFrameIndex++;
			frameChanged = true;
		}

		return frameChanged;
	}

	override function draw(ctx:RenderContext) {
		var frame = getCurrentFrame();
		if (frame != null) {
			emitTile(ctx, frame.tile);
		}
	}

	override function getBoundsRec(relativeTo:h2d.Object, out:h2d.col.Bounds, forSize:Bool) {
		super.getBoundsRec(relativeTo, out, forSize);
		var frame = getCurrentFrame();
		if (frame != null) {
			var y = -(frame.height - frame.tile.height) + frame.offsety + frame.tile.dy;
			addBounds(relativeTo, out, frame.tile.dx - frame.offsetx, y, frame.width, frame.height);
		}
	}
}
