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
	TriggerData(name:String, meta:Map<String, String>); // (#9) typed event metadata
	PointEvent(name:String, point:h2d.col.IPoint);
	RandomPointEvent(name:String, point:h2d.col.IPoint, randomRadius:Float);
}

/**
	Events emitted by AnimationSM during playback.
**/
enum AnimationEvent {
	Trigger(data:Dynamic);
	TriggerData(name:String, meta:Map<String, String>); // (#9) typed event metadata
	PointEvent(name:String, point:h2d.col.IPoint);
}

/**
	The other layers of a layered animation (`layers:` in the .anim), for one combination of states.
**/
@:nullSafety
typedef AnimationLayerFrames = {
	/** Per layer of the file, bottom first: one frame per frame of the timeline, or null where the layer draws nothing and for the timeline's own layer. **/
	final frames:Array<Null<Array<AnimationFrame>>>;
	/** Per layer: its `blend:`, or null for the usual alpha blending. **/
	final blends:Array<Null<h2d.BlendMode>>;
	/** The index of the timeline's layer: its frames are the descriptor's own `states`. **/
	final timeline:Int;
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
	final ?filter:Null<h2d.filter.Filter>; // (#12) animation-level filter
	final ?tintColor:Null<Int>; // (#12) animation-level tint color
	final ?layers:Null<AnimationLayerFrames>; // a layered file's other layers
	final ?frameOrdinals:Null<Array<Int>>; // per state: which frame of the timeline it is, or -1
};

/**
	State machine animation that uses AnimationClip for rendering.
	Plays named animations with events and loop support.
	Game logic drives animation switching via play().

	A file with `layers:` draws one clip per layer, bottom first, every one on the same frame of
	the animation's timeline: there is one clock, so they cannot drift apart. `clip` is then the
	timeline's clip of the animation playing; `layer(name)` gives any of them.
**/
@:nullSafety
class AnimationSM extends h2d.Object {
	public var paused:Bool = false;

	/**
		When true, animation is driven externally via `update()` instead of
		automatically advancing via `sync()`.
	**/
	public var externallyDriven:Bool;

	/**
		Replaceable random function for deterministic testing.
		Used by RandomPointEvent. Default: Math.random.
	**/
	public var randomFunc:() -> Float = Math.random;

	var speed:Float = 1.0;
	var elapsedTime:Float = 0;

	public var currentStateIndex(default, null):Int = 0;

	/**
		The AnimationClip used for rendering frames. In a layered file, the clip of the playing
		animation's timeline.
	**/
	public var clip(default, null):AnimationClip;

	public var playWhenHidden:Bool = false;
	public var animationStates:Map<String, AnimationDescriptor> = new Map();
	public var current(default, null):Null<AnimationDescriptor>;
	public var currentSelector:AnimationStateSelector;

	/** A layered file's `layers:`, bottom first; empty for a file without layers. **/
	public var layerNames(default, null):Array<String> = [];

	var layerClips:Array<AnimationClip> = [];
	var layersRoot:Null<h2d.Object> = null;
	// Per layer: the object a detached layer is drawn in instead, or null
	var detachedTo:Array<Null<h2d.Object>> = [];
	// Per layer: whether this machine hid the detached clip (the machine or one above it hidden), to
	// show it again itself; a clip the game hid is left alone
	var hiddenByMachine:Array<Bool> = [];
	// The animation's filter now: on the layers' root, and on each detached layer, which is not under it
	var lookFilter:Null<h2d.filter.Filter> = null;

	/** The parse result this machine was made from, which `setState` reloads the animations from. **/
	@:allow(bh.stateanim.AnimParser) var source:Null<AnimParser> = null;

	// Loop tracking
	var loopsRemaining:Int = 0;

	// Latch so onFinished fires once per completed playback, not every update.
	var finishedFired:Bool = false;

	// Bumped by play(), so handleCurrent can tell an event handler started a playback.
	var playCount:Int = 0;

	// One shared point for placeDetached: it is written and read within that call alone, on the
	// single-threaded Heaps sync, and nothing it calls (localToGlobal/globalToLocal) re-enters it.
	static final scratchPoint = new h2d.col.Point();

	public function new(selector:AnimationStateSelector, ?externallyDriven:Bool = false) {
		super(null);
		currentSelector = selector;
		this.externallyDriven = externallyDriven ?? false;
		this.clip = new AnimationClip([], this);
	}

	/** One clip per layer, in their own object, bottom first; the file's single clip is set aside. **/
	@:allow(bh.stateanim.AnimParser)
	function setupLayers(names:Array<String>):Void {
		layerNames = names.copy();
		clip.remove();
		final root = new h2d.Object(this);
		layersRoot = root;
		layerClips = [for (_ in names) new AnimationClip([], root)];
		detachedTo = [for (_ in names) null];
		hiddenByMachine = [for (_ in names) false];
		clip = layerClips[0];
	}

	inline function isLayered():Bool {
		return layerClips.length > 0;
	}

	function loadState(stateSelector:AnimationStateSelector, parser:AnimParser) {
		this.animationStates.clear();
		parser.load(stateSelector, this);
		clearDisplay();
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

	public function addAnimationState(name:String, states:Array<AnimationFrameState>, loopCount:Int, extraPoints:Map<String, h2d.col.IPoint>,
			?filter:Null<h2d.filter.Filter>, ?tintColor:Null<Int>, ?layers:Null<AnimationLayerFrames>) {
		if (animationStates.exists(name))
			throw 'animation state ${name} already exists';

		var ordinals:Null<Array<Int>> = null;
		if (layers != null) {
			final o:Array<Int> = [];
			var k = 0;
			for (s in states)
				switch s {
					case Frame(_): o.push(k++);
					default: o.push(-1);
				}
			ordinals = o;
		}
		var animDesc:AnimationDescriptor = {
			name: name,
			states: states,
			loopCount: loopCount,
			extraPoints: extraPoints,
			filter: filter,
			tintColor: tintColor,
			layers: layers,
			frameOrdinals: ordinals,
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
		playCount++;
		elapsedTime = 0;
		paused = false;
		finishedFired = false;
		currentStateIndex = 0;
		loopsRemaining = state.loopCount;
		clearDisplay();
		// (#12) Apply animation-level filters
		applyAnimationLook(state);
		handleCurrent(hxd.Math.EPSILON);
	}

	/**
		Changes one state while playing: `setState("hat", "wizard")`. The animations are reloaded
		for the new states; if the one playing has as many frames and events as before, it goes on
		from the same frame and time (a new hat mid-walk), otherwise it starts again.
	**/
	public function setState(name:String, value:String):Void {
		setStates([name => value]);
	}

	/** Changes several states at once, as `setState` changes one. **/
	public function setStates(values:Map<String, String>):Void {
		final parser = source;
		if (parser == null)
			throw 'setState needs a state machine made by createAnimSM';
		final next:AnimationStateSelector = currentSelector.copy();
		var changed = false;
		for (key => value in values) {
			final allowed = parser.definedStates.get(key);
			if (allowed == null)
				throw 'setState: no state "$key" (states: ${[for (k in parser.definedStates.keys()) k].join(", ")})';
			if (!allowed.contains(value))
				throw 'setState: "$value" is not a value of state "$key" (${allowed.join(", ")})';
			if (next.get(key) != value) changed = true;
			next.set(key, value);
		}
		if (!changed)
			return;

		final playing = current;
		final index = currentStateIndex;
		final time = elapsedTime;
		final loops = loopsRemaining;
		final wasPaused = paused;
		final fired = finishedFired;

		// Loaded into a table of its own: a load that fails (frames the sheet has not for these
		// states, found only now) leaves the machine as it was, playing what it played
		final previousStates = animationStates;
		final previousSelector = currentSelector;
		animationStates = new Map();
		currentSelector = next;
		try {
			parser.load(next, this);
		} catch (e:Dynamic) {
			animationStates = previousStates;
			currentSelector = previousSelector;
			throw e;
		}
		if (playing == null) {
			current = null;
			clearDisplay();
			return;
		}
		final desc = animationStates.get(playing.name);
		if (desc == null) {
			current = null;
			clearDisplay();
			return;
		}
		if (desc.states.length != playing.states.length) {
			play(playing.name);
			paused = wasPaused;
			return;
		}
		current = desc;
		currentStateIndex = index;
		elapsedTime = time;
		loopsRemaining = loops;
		paused = wasPaused;
		finishedFired = fired;
		redisplay(desc);
	}

	/**
		Shows the playing animation at one of its states and stays there, paused: scrubbing. The
		frame at or before `stateIndex` shows on every layer, with the per-frame filters up to it;
		no event fires. `play` or `paused = false` goes on from there.
	**/
	public function seek(stateIndex:Int):Void {
		final playing = current;
		if (playing == null || playing.states.length == 0)
			return;
		currentStateIndex = stateIndex < 0 ? 0 : stateIndex >= playing.states.length ? playing.states.length - 1 : stateIndex;
		elapsedTime = 0;
		paused = true;
		redisplay(playing);
	}

	/** After a reload: the look of the animation and of the per-frame filters so far, and the frame showing. **/
	function redisplay(desc:AnimationDescriptor):Void {
		clearDisplay();
		applyAnimationLook(desc);
		if (desc.states.length == 0)
			return;
		final shown = currentStateIndex >= desc.states.length ? desc.states.length - 1 : currentStateIndex;
		for (i in 0...shown + 1)
			switch desc.states[i] {
				case SetFilter(filter, tintColor): applyFrameFilter(filter, tintColor);
				default:
			}
		var i = shown;
		while (i >= 0) {
			switch desc.states[i] {
				case Frame(frame):
					showFrame(frame, i);
					return;
				default:
			}
			i--;
		}
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

	// ===================== Layers =====================

	/** The clip of a layer of a layered file, to hide or tint it or to read its frame; null for a name the file has not. **/
	public function layer(name:String):Null<AnimationClip> {
		final i = layerNames.indexOf(name);
		return i < 0 ? null : layerClips[i];
	}

	/**
		Draws a layer inside another object, a map's shadow layer for instance, so every character's
		shadow is under every character. It goes on advancing with the rest, and is placed where it
		would have been drawn (position and scale, not rotation) on every sync of this machine. The
		animation's filter goes with it, on the layer alone.
	**/
	public function detachLayer(name:String, parent:h2d.Object):Void {
		final i = layerIndex(name);
		detachedTo[i] = parent;
		parent.addChild(layerClips[i]);
		filterOf(layerClips[i], lookFilter);
		placeDetached();
	}

	/** Puts a detached layer back in its place among the others. **/
	public function attachLayer(name:String):Void {
		final i = layerIndex(name);
		final root = layersRoot;
		if (detachedTo[i] == null || root == null)
			return;
		detachedTo[i] = null;
		final c = layerClips[i];
		filterOf(c, null); // the layers' root has it
		c.x = 0;
		c.y = 0;
		c.scaleX = 1;
		c.scaleY = 1;
		// among the layers again, the machine's own visibility hides it; what the game hid stays hidden
		if (hiddenByMachine[i]) {
			hiddenByMachine[i] = false;
			c.visible = true;
		}
		var at = 0;
		for (j in 0...i)
			if (detachedTo[j] == null) at++;
		root.addChildAt(c, at);
	}

	function layerIndex(name:String):Int {
		final i = layerNames.indexOf(name);
		if (i < 0)
			throw 'no layer "$name" (layers: ${layerNames.join(", ")})';
		return i;
	}

	/** Whether this machine is drawn: it and everything above it visible. Heaps syncs the children of a hidden object too. **/
	function shownInScene():Bool {
		var o:Null<h2d.Object> = this;
		while (o != null) {
			if (!o.visible)
				return false;
			o = o.parent;
		}
		return true;
	}

	function placeDetached():Void {
		final shown = shownInScene();
		for (i in 0...detachedTo.length) {
			final parent = detachedTo[i];
			if (parent == null)
				continue;
			final c = layerClips[i];
			// Drawn elsewhere, the clip is not hidden with the machine by Heaps: the machine hides it,
			// and shows again only what it hid, so `layer(name).visible = false` from the game holds
			if (!shown) {
				if (c.visible) {
					c.visible = false;
					hiddenByMachine[i] = true;
				}
			} else if (hiddenByMachine[i]) {
				hiddenByMachine[i] = false;
				c.visible = true;
			}
			final p = scratchPoint;
			p.set(0, 0);
			parent.globalToLocal(localToGlobal(p));
			final ox = p.x;
			final oy = p.y;
			p.set(1, 1);
			parent.globalToLocal(localToGlobal(p));
			c.x = ox;
			c.y = oy;
			c.scaleX = p.x - ox;
			c.scaleY = p.y - oy;
		}
	}

	override function onAdd() {
		super.onAdd();
		for (i in 0...detachedTo.length) {
			final parent = detachedTo[i];
			if (parent != null && layerClips[i].parent != parent)
				parent.addChild(layerClips[i]);
		}
	}

	override function onRemove() {
		for (i in 0...detachedTo.length)
			if (detachedTo[i] != null) layerClips[i].remove();
		super.onRemove();
	}

	// ===================== Drawing =====================

	function clearDisplay():Void {
		if (isLayered())
			for (c in layerClips)
				c.clearFrames();
		else
			clip.clearFrames();
	}

	/** An animation's own filter and tint and, in a layered file, its timeline's clip and each layer's blend. **/
	function applyAnimationLook(state:AnimationDescriptor):Void {
		final layers = state.layers;
		if (isLayered() && layers != null) {
			clip = layerClips[layers.timeline];
			for (i in 0...layerClips.length) {
				final blend = layers.blends[i];
				layerClips[i].blendMode = blend != null ? blend : Alpha;
			}
		}
		setLookFilter(state.filter);
		setLookTint(state.tintColor);
	}

	/** A per-frame filter from the playlist; null falls back to the animation's own. **/
	function applyFrameFilter(filter:Null<h2d.filter.Filter>, tintColor:Null<Int>):Void {
		final _current = current;
		setLookFilter(filter != null ? filter : (_current != null ? _current.filter : null));
		setLookTint(tintColor != null ? tintColor : (_current != null ? _current.tintColor : null));
	}

	/** On the layers together (their root), and on a detached layer by itself, which is drawn elsewhere. **/
	function setLookFilter(filter:Null<h2d.filter.Filter>):Void {
		lookFilter = filter;
		final root = layersRoot;
		if (!isLayered() || root == null) {
			filterOf(clip, filter);
			return;
		}
		filterOf(root, filter);
		for (i in 0...layerClips.length)
			if (detachedTo[i] != null)
				filterOf(layerClips[i], filter);
	}

	/** Heaps types `filter` as never null, and null is how a filter is taken off. **/
	@:nullSafety(Off)
	static function filterOf(o:h2d.Object, filter:Null<h2d.filter.Filter>):Void {
		o.filter = filter;
	}

	function setLookTint(tc:Null<Int>):Void {
		final argb = tc != null ? tc | (tc >>> 24 == 0 ? 0xFF000000 : 0) : 0xFFFFFFFF;
		if (isLayered())
			for (c in layerClips)
				c.color.setColor(argb);
		else
			clip.color.setColor(argb);
	}

	/** Shows the frame of state `stateIndex`, and in a layered file every layer's frame of the same ordinal. **/
	function showFrame(frame:AnimationFrame, stateIndex:Int):Void {
		final _current = current;
		final layers = _current != null ? _current.layers : null;
		final ordinals = _current != null ? _current.frameOrdinals : null;
		if (!isLayered() || layers == null || ordinals == null) {
			clip.setSingleFrame(frame);
			return;
		}
		final k = ordinals[stateIndex];
		for (i in 0...layerClips.length) {
			if (i == layers.timeline) {
				layerClips[i].setSingleFrame(frame);
				continue;
			}
			final frames = layers.frames[i];
			if (frames == null || k < 0)
				layerClips[i].clearFrames();
			else
				layerClips[i].setSingleFrame(frames[k]);
		}
	}

	function handleCurrent(delta:Float):Void {
		if (current == null)
			return;
		if (paused || (!visible && !playWhenHidden))
			return;

		elapsedTime += delta;

		var currentFrame = clip.getCurrentFrame();
		// An event handler may call play(): that starts the new playback itself, and this
		// loop's locals (currentFrame, the index it advances) belong to the old one
		final playback = playCount;
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
					// Animation finished — fire once per playback, not once per
					// subsequent update (handlers commonly spawn/free objects).
					if (!finishedFired) {
						finishedFired = true;
						onFinished();
					}
					return;
				}
			}

			var currentState = current.states[currentStateIndex];

			switch currentState {
				case Frame(frame):
					if (currentFrame != null)
						elapsedTime -= currentFrame.duration;
					currentFrame = frame;
					showFrame(frame, currentStateIndex);
					if (elapsedTime < frame.duration)
						return;

				case Event(event):
					switch event {
						case Trigger(name):
							onAnimationEvent(Trigger(name));
						case TriggerData(name, meta): // (#9)
							onAnimationEvent(TriggerData(name, meta));
						case PointEvent(name, point):
							onAnimationEvent(PointEvent(name, point));
						case RandomPointEvent(name, point, randomRadius):
							final randomAngle = randomFunc() * 2 * Math.PI;
							final r = randomFunc() * randomRadius;
							var randomPoint = point.clone();
							randomPoint.x += Std.int(r * Math.cos(randomAngle));
							randomPoint.y += Std.int(r * Math.sin(randomAngle));
							onAnimationEvent(PointEvent(name, randomPoint));
					}
					if (playCount != playback)
						return;
					// Advance past an event when no frame is showing yet (an event that opens the
					// playlist): the top of the loop only advances from a frame, so it would be
					// read again until the loop guard threw
					if (currentFrame == null)
						currentStateIndex++;

				case SetFilter(filter, tintColor): // (#12) per-frame filter change
					applyFrameFilter(filter, tintColor);
					// Advance past SetFilter when no previous frame triggers the top-of-loop advance
					if (currentFrame == null)
						currentStateIndex++;
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
		if (isLayered())
			placeDetached();
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
	SetFilter(filter:Null<h2d.filter.Filter>, tintColor:Null<Int>); // (#12) per-frame filter change
}

function animationFrameStateToString(frame:AnimationFrameState):String {
	return switch frame {
		case Frame(frame): 'Frame("${frame.tile.getTexture().name}", ${frame.width} x ${frame.height})';
		case Event(event): 'Event(${event})';
		case SetFilter(filter, tintColor): 'SetFilter(filter=${filter != null}, tint=${tintColor})';
	}
}
