package bh.stateanim;

import bh.stateanim.AnimParser.AnimationStateSelector;
import h2d.Drawable;
import h2d.RenderContext;

enum AnimationCommandEvent {
	TRIGGER(data:Dynamic);
}

enum AnimationPlaylistEvent {
	TRIGGER(data:Dynamic);
	POINT_EVENT(name:String, point:h2d.col.IPoint);
	RANDOM_POINT_EVENT(name:String, point:h2d.col.IPoint, randomRadius:Float);
}

enum CommandTrigger {
	Queued;
	ExecuteNow;
	ExecuteNowAndSkipEvents;
}


enum AnimationEvent {
	TRIGGER(data:Dynamic);
	POINT_EVENT(name:String, point:h2d.col.IPoint);
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

class AnimationFrame {
	public final tile:h2d.Tile;
	// Offset for trimmed tiles
	public final offsetx : Int;
	public final offsety : Int;

	// width & height for trimmed tiles
	public final width : Int;
	public final height : Int;
	/**
		Frame display duration in seconds.
	**/
	public final duration:Float;

	public function new(tile:h2d.Tile, duration:Float, offsetx, offsety, width, height) {
		this.tile = tile;
		this.duration = duration;
		this.offsetx = offsetx;
		this.offsety = offsety;
		this.width = width;
		this.height = height;
	}

	public function cloneWithDuration(newDuration:Float) {
		return new AnimationFrame(tile, newDuration, offsetx, offsety, width, height);
	}
	public function cloneWithNewTile(newTile:h2d.Tile) {
		return new AnimationFrame(newTile, duration, offsetx, offsety, width, height);
	}
}

@:nullSafety
class AnimationSM extends Drawable {
	public var paused:Bool = false;

	var speed = 1.0;
	var elapsedTime:Float;
	var wait:Float;
	public var currentStateIndex(default, null):Int;
	var currentFrame:Null<AnimationFrame>;

	public var playWhenHidden:Bool = false;
	public var animationStates:Map<String, AnimationDescriptor> = new Map();
	public var commands(default, null):List<AnimationCommand> = new List();
	public var current(default, null):Null<AnimationDescriptor>;
	public var currentSelector:AnimationStateSelector;

	public function new(selector:AnimationStateSelector, ?parent:h2d.Object) {
		super(parent);
		this.elapsedTime = 0;
		this.wait = 0;
		this.currentStateIndex = 0;
		currentSelector = selector;
	}

	public function clone(newStateSelector:AnimationStateSelector, parser:AnimParser, cloneCommands = false, cloneState = false, cloneStatIndex = false) {
		var cloned = new AnimationSM(newStateSelector, null);
		cloned.animationStates = this.animationStates.copy();
		cloned.speed = this.speed;
		if (cloneCommands) {
			cloned.wait = this.wait;
			cloned.commands = Lambda.list(this.commands);
		}
		if (cloneState) {
			cloned.currentFrame = this.currentFrame;
			cloned.current = this.current;
		}
		if (cloneStatIndex) {
			cloned.currentStateIndex = this.currentStateIndex;
		}
		parser.load(newStateSelector, cloned);
	}

	function loadState(stateSelector:AnimationStateSelector, parser:AnimParser) {
		this.animationStates.clear();
		parser.load(stateSelector, this);
		this.currentFrame = null;
		var oldwait = wait;
		wait = 0; 
		handleCurrent(hxd.Math.EPSILON);
		wait = oldwait;
	}

	override function getBoundsRec(relativeTo:h2d.Object, out:h2d.col.Bounds, forSize:Bool) {

		super.getBoundsRec(relativeTo, out, forSize);
		if( currentFrame != null ) {
				var y = -(currentFrame.height-currentFrame.tile.height) + currentFrame.offsety + currentFrame.tile.dy;
				addBounds(relativeTo, out, currentFrame.tile.dx - currentFrame.offsetx, y, currentFrame.width, currentFrame.height);
		}
	}

	public function hasCommand():Bool {
				if(wait <= 0) {
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
		//current = null;
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
				if (wait <= 0) wait = time;
				else wait += time;
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

	public function getExtraPointForAnim(extraPointName:String, animState:String) {
		final selectedState = animationStates[animState];
		if (selectedState == null)
			throw 'animState ${animState} not found';
		#if MULTIANIM_TRACE
		trace(selectedState.extraPoints);
		#end
		return selectedState.extraPoints.get(extraPointName);
	}

	public function getExtraPointNames() {
		if (current == null) return[];
		else return [for (s in current.extraPoints.keys()) s];
	}

	public function getExtraPoint(name:String) {
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
			if (wait < 0) wait = 0;
			elapsedTime = 0;
			paused = false;
			currentStateIndex = 0;
			currentFrame = null;	// Mark that we want to get first frame
			handleCurrent(hxd.Math.EPSILON);
		} else
			throw 'unknown animation ${name}';
	}

	function isEnd() {
		if (this.current == null) return false;
		return this.currentStateIndex == this.current.states.length;
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
		
		// if (hasCommand()) {
		// 	performNextCommand();
		// }

		var statesCount = 0;
		while (true) {

			if (isEnd()) {
				if (hasCommand()) performNextCommand();
			}
			
			if (currentFrame != null && elapsedTime < currentFrame.duration) return; // waiting for next frame
			if (currentFrame != null && !isEnd()) currentStateIndex++;
			
			if (isEnd()) {
				if (hasCommand()) performNextCommand();
				return;
			}

			var currentState = current.states[currentStateIndex];	
			statesCount++;
			if (statesCount > 50)
				if (statesCount > 1000) throw 'more than 1000 states, something is wrong.';
				else {
					trace('more than 50 state changes: ${statesCount}');
				}
				
			switch currentState {
				case AF_FRAME(frame):
					if (currentFrame != null) elapsedTime -= frame.duration; 
					currentFrame = frame;
					if (elapsedTime < frame.duration) return;

				case AF_LOOP(destIndex, condition):
					switch condition {
						case FOREVER: currentStateIndex = destIndex - 1;
						case AFC_UNTIL_COMMAND:
							if (!hasCommand()) {
								currentStateIndex = destIndex - 1; 
							}
						case AFC_COUNT(repeatCount):
							var value = current.statesCounters[currentStateIndex];
							if (value == -1) value = repeatCount;
							if (value > 0) {
								current.statesCounters[currentStateIndex] = value - 1;
								currentStateIndex = destIndex - 1; 
							}  else {
								current.statesCounters[currentStateIndex] = repeatCount;
							}
					}

				case AF_EVENT(event):
					switch event {
						case TRIGGER(name): onAnimationEvent(TRIGGER(name));
						case POINT_EVENT(name, point): onAnimationEvent(POINT_EVENT(name, point));
						case RANDOM_POINT_EVENT(name, point, randomRadius):
							final randomAngle = Math.random() * 2*Math.PI;
							final r = Math.random() * randomRadius;
							var randomPoint = point.clone();
							randomPoint.x += Std.int(r * Math.cos(randomAngle));
							randomPoint.y += Std.int(r * Math.sin(randomAngle));
							 
							onAnimationEvent(POINT_EVENT(name, randomPoint));
					}
					
				case AF_CHAGE_STATE(state):
					playAnim(state, 0);
					return;
				case AF_EXITPOINT:
					if (hasCommand()) {
						performNextCommand();
						return;
					}
					
			}
		}
	}

	override function sync(ctx:RenderContext) {
		final animDelta = ctx.elapsedTime * speed;
		handleCurrent(animDelta);
		super.sync(ctx);
	}

	override function draw(ctx:RenderContext) {
		if (currentFrame != null && currentFrame.tile != null) {
			emitTile(ctx, currentFrame.tile);
		}
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
	AF_FRAME(frame:AnimationFrame);
	AF_LOOP(destIndex:Int, condition:AnimationFrameCondition);
	AF_EVENT(event:AnimationPlaylistEvent);
	AF_CHAGE_STATE(state:String);
	AF_EXITPOINT; // exit animation if there is command waiting
}

enum AnimationFrameCondition {
	FOREVER;
	AFC_COUNT(repeatCount:Int);
	AFC_UNTIL_COMMAND;
}
