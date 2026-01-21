package bh.stateanim;

import bh.stateanim.AnimationFrame;
import bh.stateanim.BasicAnim;
import bh.stateanim.AnimParser.AnimationStateSelector;
import h2d.RenderContext;

enum AnimationCommandEvent {
	Trigger(data:Dynamic);
}

enum AnimationPlaylistEvent {
	Trigger(data:Dynamic);
	PointEvent(name:String, point:h2d.col.IPoint);
	RandomPointEvent(name:String, point:h2d.col.IPoint, randomRadius:Float);
}

enum CommandTrigger {
	Queued;
	ExecuteNow;
	ExecuteNowAndSkipEvents;
}

enum AnimationEvent {
	Trigger(data:Dynamic);
	PointEvent(name:String, point:h2d.col.IPoint);
}

@:nullSafety
enum AnimationCommand {
	Delay(time:Float);
	SwitchState(name:String);
	CommandEvent(event:AnimationCommandEvent);
	Callback(callback:() -> Void);
	Visible(value:Bool);
}

@:nullSafety
typedef AnimationDescriptor = {
	final name:String;
	final states:Array<AnimationFrameState>;
	final statesCounters:Array<Int>;
	final extraPoints:Map<String, h2d.col.IPoint>;
};

/**
	State machine animation that uses BasicAnim for rendering.
	Handles complex animation states including loops, events, state changes, and exit points.
	The state machine controls which frame is displayed, BasicAnim handles the actual drawing.
**/
@:nullSafety
class AnimationSM extends h2d.Object {
	static inline final STATE_WARNING_THRESHOLD = 50;
	static inline final STATE_ERROR_THRESHOLD = 1000;

	public var paused:Bool = false;

	/**
		When true, animation is driven externally via `updateExternally()` instead of
		automatically advancing via `sync()`. In this mode, call `updateExternally(dt)` manually.
	**/
	public var externallyDriven:Bool;

	var speed = 1.0;
	var elapsedTime:Float;
	var wait:Float;

	public var currentStateIndex(default, null):Int;

	/**
		The BasicAnim used for rendering frames.
	**/
	public var anim(default, null):BasicAnim;

	public var playWhenHidden:Bool = false;
	public var animationStates:Map<String, AnimationDescriptor> = new Map();
	public var commands(default, null):List<AnimationCommand> = new List();
	public var current(default, null):Null<AnimationDescriptor>;
	public var currentSelector:AnimationStateSelector;

	public function new(selector:AnimationStateSelector, ?externallyDriven:Bool = false) {
		super(null);
		this.elapsedTime = 0;
		this.wait = 0;
		this.currentStateIndex = 0;
		currentSelector = selector;
		this.externallyDriven = externallyDriven ?? false;
		// Create BasicAnim as child for rendering
		this.anim = new BasicAnim([], this);
	}

	function loadState(stateSelector:AnimationStateSelector, parser:AnimParser) {
		this.animationStates.clear();
		parser.load(stateSelector, this);
		anim.setFrames([]);
		var oldWait = wait;
		wait = 0;
		handleCurrent(hxd.Math.EPSILON);
		wait = oldWait;
	}

	/**
		Checks if a non-delay command is available for execution.
		Note: This method has side effects - it consumes any pending Delay commands
		and updates the wait timer. Use when you need to check command availability
		as part of animation state processing.
	**/
	public function consumeDelaysAndCheckCommand():Bool {
		if (wait <= 0) {
			var cmd = commands.first();
			return switch cmd {
				case null: false;
				case Delay(time):
					wait += time;
					commands.pop();
					false;
				default: true;
			}
		} else {
			return false;
		}
	}

	/**
		Clears command buffer, optionally executes callbacks & events of deleted commands

		If `executeCommands` is 'true' callbacks & events are immediately executed
	**/
	function clearCommands(executeEvents = true):Void {
		if (executeEvents) {
			for (command in commands) {
				switch command {
					case Delay(time):
					case SwitchState(name):
					case CommandEvent(event):
						onCommandEvent(event);
					case Callback(callback):
						callback();
					case Visible(value):
				}
			}
		}
		commands.clear();
		wait = 0;
		elapsedTime = 0;
	}

	public function addCommand(command:AnimationCommand, trigger:CommandTrigger):Void {
		switch trigger {
			case Queued:
				commands.add(command);
			case ExecuteNow:
				clearCommands(true);
				commands.add(command);
			case ExecuteNowAndSkipEvents:
				clearCommands(false);
				commands.add(command);
		}
	}

	function executeCommand(cmd:AnimationCommand):Bool {
		switch cmd {
			case Delay(time):
				if (wait <= 0)
					wait = time;
				else
					wait += time;
				return time <= 0;
			case SwitchState(name):
				playAnim(name);
				return false;
			case CommandEvent(event):
				onCommandEvent(event);
				return true;
			case Callback(callback):
				callback();
				return true;
			case Visible(value):
				this.visible = value;
				return true;
		}
	}

	public function getExtraPointForAnim(extraPointName:String, animState:String):Null<h2d.col.IPoint> {
		final selectedState = animationStates[animState];
		if (selectedState == null)
			throw 'animState ${animState} not found';
		#if MULTIANIM_TRACE
		trace(selectedState.extraPoints);
		#end
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

	public function addAnimationState(name:String, states, extraPoints) {
		if (animationStates.exists(name))
			throw 'animation state ${name} already exists';

		var animDesc:AnimationDescriptor = {
			name: name,
			states: states,
			statesCounters: [for (i in 0...states.length) -1],
			extraPoints: extraPoints
		};
		animationStates.set(name, animDesc);
	}

	function playAnim(name:String, ?atFrame:Int):Void {
		var state = animationStates.get(name);
		if (state != null) {
			current = state;
			if (wait < 0)
				wait = 0;
			elapsedTime = 0;
			paused = false;
			currentStateIndex = 0;
			anim.setFrames([]); // Clear frames, will be set by state machine
			handleCurrent(hxd.Math.EPSILON);
		} else
			throw 'unknown animation ${name}';
	}

	function isEnd() {
		if (this.current == null)
			return false;
		return this.currentStateIndex == this.current.states.length;
	}

	/**
		Returns the current frame being displayed, or null if none.
	**/
	public function getCurrentFrame():Null<AnimationFrame> {
		return anim.getCurrentFrame();
	}

	function setCurrentFrame(frame:AnimationFrame):Void {
		// Set the frame in BasicAnim by replacing its frames array with single frame
		anim.setFrames([frame]);
	}

	function handleCurrent(delta:Float) {
		if (current == null)
			performNextCommand();
		if (current == null)
			return;
		if (paused || (!visible && !playWhenHidden))
			return;

		elapsedTime += delta;
		wait -= delta < 0 ? 0 : delta;

		var statesCount = 0;
		var currentFrame = anim.getCurrentFrame();
		while (true) {
			if (isEnd()) {
				if (consumeDelaysAndCheckCommand())
					performNextCommand();
			}

			if (currentFrame != null && elapsedTime < currentFrame.duration)
				return; // waiting for next frame
			if (currentFrame != null && !isEnd())
				currentStateIndex++;

			if (isEnd()) {
				if (consumeDelaysAndCheckCommand())
					performNextCommand();
				return;
			}

			var currentState = current.states[currentStateIndex];
			statesCount++;
			if (statesCount > STATE_WARNING_THRESHOLD)
				if (statesCount > STATE_ERROR_THRESHOLD)
					throw 'more than ${STATE_ERROR_THRESHOLD} states, something is wrong.';
				else {
					trace('more than ${STATE_WARNING_THRESHOLD} state changes: ${statesCount}');
				}

			switch currentState {
				case Frame(frame):
					if (currentFrame != null)
						elapsedTime -= frame.duration;
					currentFrame = frame;
					setCurrentFrame(frame);
					if (elapsedTime < frame.duration)
						return;

				case Loop(destIndex, condition):
					switch condition {
						case Forever: currentStateIndex = destIndex - 1;
						case UntilCommand:
							if (!consumeDelaysAndCheckCommand()) {
								currentStateIndex = destIndex - 1;
							}
						case Count(repeatCount):
							var value = current.statesCounters[currentStateIndex];
							if (value == -1)
								value = repeatCount;
							if (value > 0) {
								current.statesCounters[currentStateIndex] = value - 1;
								currentStateIndex = destIndex - 1;
							} else {
								current.statesCounters[currentStateIndex] = repeatCount;
							}
					}

				case Event(event):
					switch event {
						case Trigger(name): onAnimationEvent(Trigger(name));
						case PointEvent(name, point): onAnimationEvent(PointEvent(name, point));
						case RandomPointEvent(name, point, randomRadius):
							final randomAngle = Math.random() * 2 * Math.PI;
							final r = Math.random() * randomRadius;
							var randomPoint = point.clone();
							randomPoint.x += Std.int(r * Math.cos(randomAngle));
							randomPoint.y += Std.int(r * Math.sin(randomAngle));

							onAnimationEvent(PointEvent(name, randomPoint));
					}

				case ChangeState(state):
					playAnim(state, 0);
					return;
				case ExitPoint:
					if (consumeDelaysAndCheckCommand()) {
						performNextCommand();
						return;
					}
			}
		}
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
	public function updateExternally(dt:Float):Void {
		handleCurrent(dt * speed);
	}

	function performNextCommand():Void {
		var readNext:Bool;
		do {
			var cmd = commands.pop();
			readNext = cmd != null && executeCommand(cmd);
		} while (readNext);
	}

	public dynamic function onCommandEvent(event:AnimationCommandEvent) {}

	public dynamic function onAnimationEvent(event:AnimationEvent) {}
}

enum AnimationFrameState {
	Frame(frame:AnimationFrame);
	Loop(destIndex:Int, condition:AnimationFrameCondition);
	Event(event:AnimationPlaylistEvent);
	ChangeState(state:String);
	ExitPoint; // exit animation if there is command waiting
}

enum AnimationFrameCondition {
	Forever;
	Count(repeatCount:Int);
	UntilCommand;
}

function animationFrameStateToString(frame:AnimationFrameState):String {
	return switch frame {
		case Frame(frame): 'Frame("${frame.tile.getTexture().name}", ${frame.width} x ${frame.height})';
		case Loop(destIndex, condition): 'Loop(${destIndex}, ${condition})';
		case Event(event): 'Event(${event})';
		case ChangeState(state): 'ChangeState(${state})';
		case ExitPoint: 'ExitPoint';
	}
}
