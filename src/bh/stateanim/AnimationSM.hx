package bh.stateanim;

import bh.stateanim.AnimationFrame;
import bh.stateanim.AnimationClip;
import bh.stateanim.AnimParser.AnimationStateSelector;
import h2d.RenderContext;

/**
	Event types that can be triggered during animation playback.
**/
enum AnimationPlaylistEvent {
	Trigger(data:Dynamic);
	PointEvent(name:String, point:h2d.col.IPoint);
	RandomPointEvent(name:String, point:h2d.col.IPoint, randomRadius:Float);
}

/**
	Events emitted by AnimationSM during playback.
**/
enum AnimationEvent {
	Trigger(data:Dynamic);
	PointEvent(name:String, point:h2d.col.IPoint);
}

/**
	Descriptor for a single animation clip with its states and metadata.
**/
@:nullSafety
typedef AnimationDescriptor = {
	final name:String;
	final states:Array<AnimationFrameState>;
	final loopCount:Int; // -1 = forever, 0 = no loop, N = loop N times
	final extraPoints:Map<String, h2d.col.IPoint>;
};

/**
	State machine animation that uses AnimationClip for rendering.
	Plays named animations with events and loop support.
	Game logic drives animation switching via play().
**/
@:nullSafety
class AnimationSM extends h2d.Object {
	public var paused:Bool = false;

	/**
		When true, animation is driven externally via `update()` instead of
		automatically advancing via `sync()`.
	**/
	public var externallyDriven:Bool;

	var speed:Float = 1.0;
	var elapsedTime:Float = 0;

	public var currentStateIndex(default, null):Int = 0;

	/**
		The AnimationClip used for rendering frames.
	**/
	public var clip(default, null):AnimationClip;

	public var playWhenHidden:Bool = false;
	public var animationStates:Map<String, AnimationDescriptor> = new Map();
	public var current(default, null):Null<AnimationDescriptor>;
	public var currentSelector:AnimationStateSelector;

	// Loop tracking
	var loopsRemaining:Int = 0;

	public function new(selector:AnimationStateSelector, ?externallyDriven:Bool = false) {
		super(null);
		currentSelector = selector;
		this.externallyDriven = externallyDriven ?? false;
		this.clip = new AnimationClip([], this);
	}

	function loadState(stateSelector:AnimationStateSelector, parser:AnimParser) {
		this.animationStates.clear();
		parser.load(stateSelector, this);
		clip.setFrames([]);
	}

	public function getExtraPointForAnim(extraPointName:String, animState:String):Null<h2d.col.IPoint> {
		final selectedState = animationStates[animState];
		if (selectedState == null)
			throw 'animState ${animState} not found';
		return selectedState.extraPoints.get(extraPointName);
	}

	public function getExtraPointNames():Array<String> {
		if (current == null)
			return [];
		else
			return [for (s in current.extraPoints.keys()) s];
	}

	public function getExtraPoint(name:String):Null<h2d.col.IPoint> {
		if (current == null)
			return null;
		return current.extraPoints.get(name);
	}

	public function addAnimationState(name:String, states:Array<AnimationFrameState>, loopCount:Int, extraPoints:Map<String, h2d.col.IPoint>) {
		if (animationStates.exists(name))
			throw 'animation state ${name} already exists';

		var animDesc:AnimationDescriptor = {
			name: name,
			states: states,
			loopCount: loopCount,
			extraPoints: extraPoints
		};
		animationStates.set(name, animDesc);
	}

	/**
		Play an animation by name.
	**/
	public function play(name:String):Void {
		var state = animationStates.get(name);
		if (state == null)
			throw 'unknown animation ${name}';

		current = state;
		elapsedTime = 0;
		paused = false;
		currentStateIndex = 0;
		loopsRemaining = state.loopCount;
		clip.setFrames([]);
		handleCurrent(hxd.Math.EPSILON);
	}

	/**
		Returns true if the current animation has finished (not looping or loops exhausted).
	**/
	public function isFinished():Bool {
		if (current == null)
			return true;
		if (current.loopCount == -1)
			return false; // loops forever
		return currentStateIndex >= current.states.length && loopsRemaining <= 0;
	}

	/**
		Returns the current animation name, or null if none.
	**/
	public function getCurrentAnimName():Null<String> {
		return current != null ? current.name : null;
	}

	function isEnd():Bool {
		if (current == null)
			return false;
		return currentStateIndex >= current.states.length;
	}

	/**
		Returns the current frame being displayed, or null if none.
	**/
	public function getCurrentFrame():Null<AnimationFrame> {
		return clip.getCurrentFrame();
	}

	function setCurrentFrame(frame:AnimationFrame):Void {
		clip.setFrames([frame]);
	}

	function handleCurrent(delta:Float):Void {
		if (current == null)
			return;
		if (paused || (!visible && !playWhenHidden))
			return;

		elapsedTime += delta;

		var currentFrame = clip.getCurrentFrame();
		var iterations = 0;
		final maxIterations = 1000;

		while (iterations < maxIterations) {
			iterations++;

			// Check if waiting for frame duration
			if (currentFrame != null && elapsedTime < currentFrame.duration)
				return;

			// Advance state if we have a frame
			if (currentFrame != null && !isEnd())
				currentStateIndex++;

			// Handle end of states
			if (isEnd()) {
				if (current.loopCount == -1 || loopsRemaining > 0) {
					// Loop back to start
					if (loopsRemaining > 0)
						loopsRemaining--;
					currentStateIndex = 0;
				} else {
					// Animation finished
					onFinished();
					return;
				}
			}

			var currentState = current.states[currentStateIndex];

			switch currentState {
				case Frame(frame):
					if (currentFrame != null)
						elapsedTime -= currentFrame.duration;
					currentFrame = frame;
					setCurrentFrame(frame);
					if (elapsedTime < frame.duration)
						return;

				case Event(event):
					switch event {
						case Trigger(name):
							onAnimationEvent(Trigger(name));
						case PointEvent(name, point):
							onAnimationEvent(PointEvent(name, point));
						case RandomPointEvent(name, point, randomRadius):
							final randomAngle = Math.random() * 2 * Math.PI;
							final r = Math.random() * randomRadius;
							var randomPoint = point.clone();
							randomPoint.x += Std.int(r * Math.cos(randomAngle));
							randomPoint.y += Std.int(r * Math.sin(randomAngle));
							onAnimationEvent(PointEvent(name, randomPoint));
					}
			}
		}

		if (iterations >= maxIterations)
			throw 'animation loop detected in ${current.name}';
	}

	override function sync(ctx:RenderContext) {
		if (!externallyDriven) {
			final animDelta = ctx.elapsedTime * speed;
			handleCurrent(animDelta);
		}
		super.sync(ctx);
	}

	/**
		Manually advances the animation by the given delta time.
		Use this when `externallyDriven` is true.
		@param dt Delta time in seconds.
	**/
	public function update(dt:Float):Void {
		handleCurrent(dt * speed);
	}

	/**
		Called when animation finishes (non-looping or loops exhausted).
	**/
	public dynamic function onFinished():Void {}

	/**
		Called when an animation event is triggered.
	**/
	public dynamic function onAnimationEvent(event:AnimationEvent):Void {}
}

/**
	States in an animation - either a frame or an event.
**/
enum AnimationFrameState {
	Frame(frame:AnimationFrame);
	Event(event:AnimationPlaylistEvent);
}

function animationFrameStateToString(frame:AnimationFrameState):String {
	return switch frame {
		case Frame(frame): 'Frame("${frame.tile.getTexture().name}", ${frame.width} x ${frame.height})';
		case Event(event): 'Event(${event})';
	}
}
