package bh.test.examples;

import utest.Assert;
import bh.stateanim.AnimParser;
import bh.stateanim.AnimationSM;
import bh.stateanim.AnimationFrame;
import bh.test.BuilderTestBase;

/**
 * Layers in .anim (`layers:`, `layer` blocks): parsing and its errors, one clock for every layer,
 * a state changed while playing, a layer drawn elsewhere, and stateanim selectors in manim that
 * change a state in place. Frames are the marine's from crew2: idle and shooting have 4 frames,
 * hit has 5.
 */
class AnimLayersTest extends utest.Test {
	static inline var FIXTURE = "test/examples/154-animLayers/animLayers.manim";

	static final LAYERED = '
sheet: crew2
states: direction(l, r), hat(none, cap)
layers: shadow, body, hat, glow
center: 32, 48
fps: 4

animation walk {
    loop: yes
    layer body { sheet: "marine_$${direction}_idle" }
    layer hat @(hat != none) { sheet: "marine_$${direction}_shooting" }
    layer glow { sheet: "marine_$${direction}_idle" blend: add }
}
';

	static function parse(source:String, withSpans = false):AnimParserResult {
		final loader:bh.base.ResourceLoader = bh.test.TestResourceLoader.createLoader(false);
		return AnimParser.parseFile(byte.ByteData.ofString(source), "test-input", loader, withSpans);
	}

	static function errorOf(source:String):Null<String> {
		try {
			parse(source);
			return null;
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	static function smOf(source:String, selector:AnimationStateSelector):AnimationSM {
		final sm = parse(source).createAnimSM(selector);
		sm.play("walk");
		return sm;
	}

	/** The frame the timeline shows now, and the ordinal of it among the timeline's frames. **/
	static function ordinal(sm:AnimationSM):Int {
		return sm.current.frameOrdinals[sm.currentStateIndex];
	}

	// ===== Parsing =====

	@Test
	public function testLayersParseAndTheTimelineIsTheFirstLayerWithABlock() {
		final loaded = parse(LAYERED).loaded();
		Assert.same(["shadow", "body", "hat", "glow"], loaded.layers);
		final walk = loaded.animations[0];
		Assert.equals("body", walk.timeline, "shadow has no block, so body is the first layer that has one");
		Assert.equals(3, walk.layers.length);
		Assert.equals(1, walk.playlist.length, "the timeline's block is the playlist");
		Assert.equals("add", walk.layers[2].blend);
	}

	@Test
	public function testTimelineNamedOutright() {
		final loaded = parse('
sheet: crew2
states: direction(l, r)
layers: body, hat
fps: 4
animation walk {
    timeline: hat
    layer body { sheet: "marine_$${direction}_idle" }
    layer hat { sheet: "marine_$${direction}_shooting" event step }
}
').loaded();
		Assert.equals("hat", loaded.animations[0].timeline);
	}

	@Test
	public function testLayerErrors() {
		function expect(fragment:String, source:String, ?pos:haxe.PosInfos) {
			final error = errorOf(source);
			Assert.notNull(error, 'expected an error with "$fragment"', pos);
			if (error != null) Assert.stringContains(fragment, error, pos);
		}
		final head = 'sheet: crew2\nstates: direction(l, r)\nlayers: body, hat\nfps: 4\n';
		expect("not one of the layers", head + 'animation walk { layer cape { sheet: "marine_$${direction}_idle" } }');
		expect("declares no layers", 'sheet: crew2\nfps: 4\nanimation walk { layer body { sheet: "a" } }');
		expect("only the timeline (body) sets durations",
			head + 'animation walk { layer body { sheet: "marine_$${direction}_idle" } layer hat { sheet: "marine_$${direction}_idle" duration: 50ms } }');
		expect("only the timeline (body) has events",
			head + 'animation walk { layer body { sheet: "marine_$${direction}_idle" } layer hat { sheet: "marine_$${direction}_idle" event step } }');
		expect("not both",
			head + 'animation walk { playlist { sheet: "marine_$${direction}_idle" } layer body { sheet: "marine_$${direction}_idle" } }');
		expect("written in layer blocks", head + 'animation walk { playlist { sheet: "marine_$${direction}_idle" } }');
		expect("written with layer blocks", head + 'anim walk: "marine_$${direction}_idle"');
		expect("has no layer block", head + 'animation walk { timeline: hat layer body { sheet: "marine_$${direction}_idle" } }');
		expect("blend: expected one of", head + 'animation walk { layer body { sheet: "marine_$${direction}_idle" blend: glowy } }');
		expect("layers must be declared before animations",
			'sheet: crew2\nfps: 4\nanimation walk { playlist { sheet: "a" } }\nlayers: body\n');
		expect("not reachable",
			head + 'animation walk { layer body { sheet: "marine_$${direction}_idle" } layer hat @(direction => [l, r]) { sheet: "marine_$${direction}_idle" } layer hat { sheet: "marine_$${direction}_idle" } }');
		expect("has no block for",
			head + 'animation walk { layer body @(direction => l) { sheet: "marine_l_idle" } }');
	}

	@Test
	public function testALayerWithAnotherFrameCountIsAnError() {
		final parsed = parse('
sheet: crew2
states: direction(l, r)
layers: body, hat
fps: 4
animation walk {
    layer body { sheet: "marine_$${direction}_idle" }
    layer hat { sheet: "marine_$${direction}_hit" }
}
');
		var error:Null<String> = null;
		try
			parsed.createAnimSM(["direction" => "l"])
		catch (e:Dynamic)
			error = Std.string(e);
		Assert.notNull(error);
		Assert.stringContains("layer hat has 5 frames and the timeline, body, has 4", error);
	}

	// ===== One clock =====

	@Test
	public function testEveryLayerShowsTheSameFrameOfItsRun() {
		final sm = smOf(LAYERED, ["direction" => "l", "hat" => "cap"]);
		final body = sm.layer("body");
		final hat = sm.layer("hat");
		final glow = sm.layer("glow");
		Assert.isTrue(sm.clip == body, "clip is the timeline's clip");
		final hatFrames = sm.current.layers.frames[2];
		final glowFrames = sm.current.layers.frames[3];
		for (step in 0...10) {
			final k = ordinal(sm);
			Assert.isTrue(hat.getCurrentFrame() == hatFrames[k], 'step $step: the hat shows frame $k');
			Assert.isTrue(glow.getCurrentFrame() == glowFrames[k], 'step $step: the glow shows frame $k');
			sm.update(0.25);
		}
		Assert.isNull(sm.layer("shadow").getCurrentFrame(), "a layer with no block draws nothing");
		Assert.equals(h2d.BlendMode.Add, glow.blendMode);
		Assert.equals(h2d.BlendMode.Alpha, hat.blendMode);
	}

	@Test
	public function testBlendNamesAreTheManimOnesWithoutRegardToCase() {
		final sm = smOf(StringTools.replace(LAYERED, "blend: add", "blend: AlphaAdd"), ["direction" => "l", "hat" => "cap"]);
		Assert.equals(h2d.BlendMode.AlphaAdd, sm.layer("glow").blendMode);
	}

	@Test
	public function testAConditionalLayerThatDoesNotMatchDrawsNothing() {
		final sm = smOf(LAYERED, ["direction" => "l", "hat" => "none"]);
		sm.update(0.25);
		Assert.isNull(sm.layer("hat").getCurrentFrame());
		Assert.notNull(sm.layer("body").getCurrentFrame());
		Assert.isNull(sm.layer("cape"), "a name the file has not");
	}

	// ===== A state changed while playing =====

	@Test
	public function testSetStateKeepsTheFrameAndTheTime() {
		final sm = smOf(LAYERED, ["direction" => "l", "hat" => "none"]);
		sm.update(0.5);
		sm.update(0.1);
		final index = sm.currentStateIndex;
		Assert.isNull(sm.layer("hat").getCurrentFrame());

		sm.setState("hat", "cap");
		Assert.equals(index, sm.currentStateIndex, "the walk goes on from the same frame");
		Assert.equals("cap", sm.currentSelector.get("hat"));
		Assert.isTrue(sm.layer("hat").getCurrentFrame() == sm.current.layers.frames[2][ordinal(sm)], "the new hat on the same frame");

		sm.setState("direction", "r");
		Assert.equals(index, sm.currentStateIndex, "a direction with as many frames keeps the frame too");
		sm.update(0.15);
		Assert.equals(index + 1, sm.currentStateIndex, "and the time: 0.1 + 0.15 s is past the frame's 0.25 s");
	}

	@Test
	public function testSetStateRestartsWhenTheLengthChanges() {
		final sm = smOf('
sheet: crew2
states: direction(l, r)
layers: body
fps: 4
animation walk {
    loop: yes
    layer body @(direction => l) { sheet: "marine_l_idle" }
    layer body @(direction => r) { sheet: "marine_r_hit" }
}
', ["direction" => "l"]);
		sm.update(0.5);
		Assert.isTrue(sm.currentStateIndex > 0);
		sm.setState("direction", "r");
		Assert.equals(0, sm.currentStateIndex, "5 frames where there were 4: it starts again");
		Assert.equals("walk", sm.getCurrentAnimName());
	}

	@Test
	public function testSetStateOnAFileWithoutLayers() {
		final sm = parse('
sheet: crew2
states: direction(l, r)
fps: 4
animation idle { loop: yes playlist { sheet: "marine_$${direction}_idle" } }
').createAnimSM(["direction" => "l"]);
		sm.play("idle");
		sm.update(0.5);
		final index = sm.currentStateIndex;
		final before = sm.getCurrentFrame();
		sm.setState("direction", "r");
		Assert.equals(index, sm.currentStateIndex);
		Assert.isFalse(sm.getCurrentFrame() == before, "the frame of the other direction");
	}

	@Test
	public function testSetStateRejectsWhatTheFileHasNot() {
		final sm = smOf(LAYERED, ["direction" => "l", "hat" => "none"]);
		Assert.raises(() -> sm.setState("cape", "red"));
		Assert.raises(() -> sm.setState("hat", "crown"));
		final plain = new AnimationSM(["direction" => "l"]);
		Assert.raises(() -> plain.setState("direction", "r")); // not made by createAnimSM
	}

	@Test
	public function testSeekShowsAStateOnEveryLayerAndStays() {
		final sm = smOf(LAYERED, ["direction" => "l", "hat" => "cap"]);
		sm.seek(2);
		Assert.isTrue(sm.paused, "scrubbing pauses");
		Assert.equals(2, sm.currentStateIndex);
		Assert.isTrue(sm.layer("hat").getCurrentFrame() == sm.current.layers.frames[2][ordinal(sm)], "every layer on the frame sought");
		sm.update(1.0);
		Assert.equals(2, sm.currentStateIndex, "and stays there");
		sm.seek(99);
		Assert.equals(sm.current.states.length - 1, sm.currentStateIndex, "past the end: the last state");
	}

	// ===== A layer drawn elsewhere =====

	@Test
	public function testDetachedLayerIsDrawnElsewhereAndKeepsPace() {
		final root = new h2d.Object();
		final shadows = new h2d.Object(root);
		final holder = new h2d.Object(root);
		holder.x = 100;
		holder.y = 50;
		final sm = smOf(LAYERED, ["direction" => "l", "hat" => "cap"]);
		holder.addChild(sm);
		sm.x = 10;
		sm.y = 20;
		sm.setScale(2);

		final glow = sm.layer("glow");
		sm.detachLayer("glow", shadows);
		Assert.isTrue(glow.parent == shadows, "drawn in the other object");
		Assert.floatEquals(110, glow.x);
		Assert.floatEquals(70, glow.y);
		Assert.floatEquals(2, glow.scaleX, "at the state machine's scale");

		sm.update(0.25);
		Assert.isTrue(glow.getCurrentFrame() == sm.current.layers.frames[3][ordinal(sm)], "still on the same frame as the rest");

		// Taken out of the scene and put back (no scene here, so the calls Heaps makes are made by hand)
		@:privateAccess sm.onRemove();
		Assert.isNull(glow.parent, "removed with the state machine");
		@:privateAccess sm.onAdd();
		Assert.isTrue(glow.parent == shadows, "and back with it");

		sm.attachLayer("glow");
		Assert.isTrue(glow.parent != shadows, "back among the layers");
		Assert.equals(3, glow.parent.getChildIndex(glow), "in its place, above body and hat");
	}

	@Test
	public function testDetachedLayerKeepsTheAnimationsFilter() {
		final filtered = StringTools.replace(LAYERED, "animation walk {", "animation walk {
    filters { outline: 1.0, #FF0000 }");
		final sm = smOf(filtered, ["direction" => "l", "hat" => "cap"]);
		final glow = sm.layer("glow");
		final together = glow.parent.filter;
		Assert.notNull(together, "the layers are filtered together");
		Assert.isNull(glow.filter, "not each on its own");

		sm.detachLayer("glow", new h2d.Object());
		Assert.isTrue(glow.filter == together, "a detached layer takes the filter with it");
		sm.play("walk");
		Assert.notNull(glow.filter, "and gets it again when the animation plays again");

		sm.attachLayer("glow");
		Assert.isNull(glow.filter, "back among the layers, their root filters it");
		Assert.notNull(glow.parent.filter);
	}

	@Test
	public function testADetachedLayerCanBeHiddenAndHidesWithTheMachine() {
		final root = new h2d.Object();
		final shadows = new h2d.Object(root);
		final holder = new h2d.Object(root);
		final sm = smOf(LAYERED, ["direction" => "l", "hat" => "cap"]);
		holder.addChild(sm);
		final glow = sm.layer("glow");
		sm.detachLayer("glow", shadows);
		Assert.isTrue(glow.visible);

		// Heaps syncs the children of a hidden object too, so the machine places its layer with the parent hidden
		holder.visible = false;
		@:privateAccess sm.placeDetached();
		Assert.isFalse(glow.visible, "hidden with the machine's parent");
		holder.visible = true;
		@:privateAccess sm.placeDetached();
		Assert.isTrue(glow.visible, "shown again with it");

		glow.visible = false;
		@:privateAccess sm.placeDetached();
		Assert.isFalse(glow.visible, "hidden by the game, it stays hidden");
		sm.visible = false;
		@:privateAccess sm.placeDetached();
		sm.visible = true;
		@:privateAccess sm.placeDetached();
		Assert.isFalse(glow.visible, "through the machine hiding and showing");
		sm.attachLayer("glow");
		Assert.isFalse(glow.visible, "and when put back among the layers");

		glow.visible = true;
		sm.detachLayer("glow", shadows);
		sm.visible = false;
		@:privateAccess sm.placeDetached();
		Assert.isFalse(glow.visible);
		sm.attachLayer("glow");
		Assert.isTrue(glow.visible, "put back, what the machine hid is shown: the machine's own flag hides it there");
	}

	@Test
	public function testASetStateThatCannotLoadLeavesTheMachineAsItWas() {
		// a third direction the sheet has no frames for: loading it fails, after the parse
		final sm = smOf(StringTools.replace(LAYERED, "direction(l, r)", "direction(l, r, up)"), ["direction" => "l", "hat" => "cap"]);
		sm.update(0.25);
		final playing = sm.current;
		final index = sm.currentStateIndex;
		var failed = false;
		try {
			sm.setState("direction", "up");
		} catch (e:Dynamic) {
			failed = true;
		}
		Assert.isTrue(failed, "no marine_up_idle in the sheet");
		Assert.equals("l", sm.currentSelector.get("direction"), "the states are as they were");
		Assert.isTrue(sm.animationStates.get("walk") == playing, "and so are the animations");
		Assert.isTrue(sm.current == playing);
		Assert.equals(index, sm.currentStateIndex, "on the same frame");
		sm.setState("direction", "r");
		Assert.equals("r", sm.currentSelector.get("direction"), "and the next change works");
		Assert.notNull(sm.current);
	}

	// ===== In manim: a selector that names a parameter =====

	@Test
	public function testSelectorParameterChangesTheLayer_Builder() {
		final result = BuilderTestBase.buildFromFile(FIXTURE, "animLayersParams", null, Incremental);
		final sm = findSM(result.object);
		Assert.notNull(sm);
		Assert.isNull(sm.layer("hat").getCurrentFrame());
		result.setParameter("hat", "cap");
		Assert.isTrue(findSM(result.object) == sm, "the same state machine");
		Assert.notNull(sm.layer("hat").getCurrentFrame(), "now with its hat");
		result.setParameter("dir", "r");
		Assert.equals("r", sm.currentSelector.get("direction"));
	}

	@Test
	public function testSelectorParameterChangesTheLayer_Codegen() {
		final mp = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false));
		final inst:Dynamic = mp.animLayersParams.create();
		final sm = findSM(cast inst);
		Assert.notNull(sm);
		Assert.isNull(sm.layer("hat").getCurrentFrame());
		inst.setHat("cap");
		Assert.isTrue(findSM(cast inst) == sm, "the same state machine");
		Assert.notNull(sm.layer("hat").getCurrentFrame(), "now with its hat");
	}

	// ===== For tools =====

	@Test
	public function testLoadedGivesTheLayersAndTheirSpans() {
		final source = LAYERED;
		final loaded = parse(source, true).loaded();
		function text(path:String):Null<String> {
			for (s in loaded.spans)
				if (s.path == path) return source.substring(s.start, s.end);
			return null;
		}
		Assert.equals("shadow, body, hat, glow", text("layers"));
		Assert.equals('layer hat @(hat != none) { sheet: "marine_$${direction}_shooting" }', text("animations.0.layer.hat#0"));
		Assert.equals('"marine_$${direction}_shooting"', text("animations.0.layer.hat#0.0.sheet"));
		Assert.equals("add", text("animations.0.layer.glow#0.blend"));
	}

	// ===== Held at a frame: seekFrame, seekProgress, and frame: / progress: in manim =====

	static inline var FRAME_FIXTURE = "test/examples/174-stateAnimFrame/stateAnimFrame.manim";
	static inline var HIDE_FIXTURE = "test/examples/175-stateAnimHide/stateAnimHide.manim";

	/** Events and filter lines between the frames: 2 idle frames, then 3 of hit, the last 3 tinted. **/
	static final INTERLEAVED = "
sheet: crew2
states: direction(l, r)
center: 32, 48
fps: 4
animation run {
    loop: yes
    playlist {
        event start
        sheet: \"marine_${direction}_idle\" frames: 0..1
        filter tint: #FF0000
        event mid
        sheet: \"marine_${direction}_hit\" frames: 0..2
    }
}
";

	/** The frames of the animation playing, in order. **/
	static function framesOf(sm:AnimationSM):Array<AnimationFrame> {
		final frames:Array<AnimationFrame> = [];
		for (s in sm.current.states)
			switch s {
				case Frame(f): frames.push(f);
				default:
			}
		return frames;
	}

	static function smPlaying(source:String, anim:String, selector:AnimationStateSelector):AnimationSM {
		final sm = parse(source).createAnimSM(selector);
		sm.play(anim);
		return sm;
	}

	@Test
	public function testSeekFrameCountsFramesOnly() {
		final sm = smPlaying(INTERLEAVED, "run", ["direction" => "l"]);
		var events = 0;
		sm.onAnimationEvent = _ -> events++;
		final frames = framesOf(sm);
		Assert.equals(5, sm.frameCount(), "2 + 3 frames; the events and the filter line are not frames");
		Assert.equals(5, frames.length);
		sm.seekFrame(1);
		Assert.isTrue(sm.getCurrentFrame() == frames[1], "frame 1: the second idle frame");
		Assert.isTrue(sm.paused, "held");
		Assert.equals(1.0, sm.clip.color.g, "before the filter line: not tinted");
		sm.seekFrame(2);
		Assert.isTrue(sm.getCurrentFrame() == frames[2], "frame 2: the first of hit, past an event and a filter line");
		Assert.equals(0.0, sm.clip.color.g, "the filter line before it applies (tint #FF0000)");
		sm.update(1.0);
		Assert.isTrue(sm.getCurrentFrame() == frames[2], "and stays there");
		sm.seekFrame(99);
		Assert.isTrue(sm.getCurrentFrame() == frames[4], "past the last: the last");
		sm.seekFrame(-3);
		Assert.isTrue(sm.getCurrentFrame() == frames[0], "before the first: the first");
		Assert.equals(0, events, "seeking fires no event");
	}

	@Test
	public function testSeekProgressWeighsFramesByTheirDurations() {
		// 100 ms, 300 ms, 50 ms, 50 ms: 500 ms in all (the fps is for frames with no duration of their own: none here)
		final sm = smPlaying("
sheet: crew2
states: direction(l, r)
center: 32, 48
fps: 4
animation run {
    playlist {
        sheet: \"marine_${direction}_idle\" frames: 0..0 duration: 100ms
        sheet: \"marine_${direction}_idle\" frames: 1..1 duration: 300ms
        sheet: \"marine_${direction}_hit\" frames: 0..1 duration: 50ms
    }
}
", "run", ["direction" => "l"]);
		final frames = framesOf(sm);
		Assert.equals(4, frames.length);
		function shownAt(t:Float):Int {
			sm.seekProgress(t);
			return frames.indexOf(sm.getCurrentFrame());
		}
		Assert.equals(0, shownAt(0));
		Assert.equals(0, shownAt(0.1), "50 ms in: the first frame (0 to 100 ms)");
		Assert.equals(1, shownAt(0.25), "125 ms: the second (100 to 400 ms)");
		Assert.equals(1, shownAt(0.79), "395 ms: still the second");
		Assert.equals(2, shownAt(0.85), "425 ms: the third");
		Assert.equals(3, shownAt(0.95), "475 ms: the last");
		Assert.equals(3, shownAt(1), "the end: the last frame");
		Assert.equals(3, shownAt(2.5), "past the end: the last frame");
		Assert.equals(0, shownAt(-1), "before the start: the first");
		Assert.equals(0, shownAt(Math.NaN), "not a number: the first");
		Assert.isTrue(sm.paused, "held");
	}

	@Test
	public function testSeekFrameShowsEveryLayerOnTheFrame() {
		final sm = smOf(LAYERED, ["direction" => "l", "hat" => "cap"]);
		Assert.equals(4, sm.frameCount(), "the timeline's frames");
		sm.seekFrame(3);
		Assert.equals(3, ordinal(sm));
		Assert.isTrue(sm.layer("hat").getCurrentFrame() == sm.current.layers.frames[2][3], "the hat on frame 3");
		Assert.isTrue(sm.layer("glow").getCurrentFrame() == sm.current.layers.frames[3][3], "the glow on frame 3");
		sm.seekProgress(0.3);
		Assert.equals(1, ordinal(sm), "0.3 of 4 equal frames: frame 1");
		Assert.isTrue(sm.layer("hat").getCurrentFrame() == sm.current.layers.frames[2][1]);
	}

	@Test
	public function testFrameParameterHoldsAndMoves_Builder() {
		final result = BuilderTestBase.buildFromFile(FRAME_FIXTURE, "stateAnimFrameParams", null, Incremental);
		final sm = findSM(result.object);
		Assert.isTrue(sm.externallyDriven, "frame: takes it off its own clock");
		Assert.isTrue(sm.paused);
		Assert.isTrue(sm.getCurrentFrame() == framesOf(sm)[1], "k = 1");
		sm.update(1.0);
		Assert.isTrue(sm.getCurrentFrame() == framesOf(sm)[1], "held");
		result.setParameter("k", 4);
		Assert.isTrue(sm.getCurrentFrame() == framesOf(sm)[4], "setParameter moves it");
		result.setParameter("anim", "hit");
		Assert.equals("hit", sm.getCurrentAnimName());
		Assert.isTrue(sm.paused, "another animation is held too");
		Assert.isTrue(sm.getCurrentFrame() == framesOf(sm)[4], "at the frame k says");
		result.setParameter("k", 9);
		Assert.isTrue(sm.getCurrentFrame() == framesOf(sm)[4], "past hit's 5 frames: its last");
		result.setParameter("dir", "r");
		Assert.equals("r", sm.currentSelector.get("direction"));
		Assert.isTrue(sm.getCurrentFrame() == framesOf(sm)[4], "another state, held at the frame k says");
		result.beginUpdate();
		result.setParameter("k", 2);
		result.setParameter("anim", "killed");
		result.endUpdate();
		Assert.equals("killed", sm.getCurrentAnimName());
		Assert.isTrue(sm.getCurrentFrame() == framesOf(sm)[2], "the animation and the frame changed together: the frame holds");
	}

	@Test
	public function testFrameParameterHoldsAndMoves_Codegen() {
		final mp = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false));
		final inst:Dynamic = mp.stateAnimFrameParams.create();
		final sm = findSM(cast inst);
		Assert.isTrue(sm.externallyDriven, "frame: takes it off its own clock");
		Assert.isTrue(sm.paused);
		Assert.isTrue(sm.getCurrentFrame() == framesOf(sm)[1], "k = 1");
		inst.setParameter("k", 4);
		Assert.isTrue(sm.getCurrentFrame() == framesOf(sm)[4], "setParameter moves it");
		inst.setParameter("anim", "hit");
		Assert.equals("hit", sm.getCurrentAnimName(), "an enum parameter by its value's name");
		Assert.isTrue(sm.paused, "another animation is held too");
		Assert.isTrue(sm.getCurrentFrame() == framesOf(sm)[4], "at the frame k says");
		inst.setParameter("k", 9);
		Assert.isTrue(sm.getCurrentFrame() == framesOf(sm)[4], "past hit's 5 frames: its last");
		inst.setParameter("dir", "r");
		Assert.equals("r", sm.currentSelector.get("direction"));
		Assert.isTrue(sm.getCurrentFrame() == framesOf(sm)[4], "another state, held at the frame k says");
	}

	@Test
	public function testProgressParameterHoldsAndMoves() {
		final result = BuilderTestBase.buildFromFile(FRAME_FIXTURE, "stateAnimProgressParams", null, Incremental);
		final mp = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false));
		final inst:Dynamic = mp.stateAnimProgressParams.create();
		for (backend in 0...2) {
			final sm = findSM(backend == 0 ? result.object : cast inst);
			final set = (t:Float) -> backend == 0 ? result.setParameter("t", t) : inst.setParameter("t", t);
			final which = backend == 0 ? "builder" : "codegen";
			Assert.isTrue(sm.externallyDriven && sm.paused, '$which: held');
			Assert.isTrue(sm.getCurrentFrame() == framesOf(sm)[0], '$which: t = 0, the first frame');
			set(0.75);
			Assert.isTrue(sm.getCurrentFrame() == framesOf(sm)[4], '$which: 0.75 of 6 frames: frame 4');
			set(1.0);
			Assert.isTrue(sm.getCurrentFrame() == framesOf(sm)[5], '$which: 1, the last');
		}
	}

	@Test
	public function testFrameAndProgressParseErrors() {
		final twice = BuilderTestBase.parseExpectingError("#p programmable() {\n\tstateanim(\"marine.anim\", \"killed\", frame: 1, progress: 0.5): 0, 0\n}");
		Assert.notNull(twice);
		Assert.stringContains("give one of them, once", twice);
		final unknown = BuilderTestBase.parseExpectingError("#p programmable() {\n\tstateanim(\"marine.anim\", \"killed\", speed: 2): 0, 0\n}");
		Assert.notNull(unknown);
		Assert.stringContains("unknown argument \"speed:\"", unknown);
		Assert.stringContains("speed => value", unknown);
	}

	// ===== Layers left out: hide => [...] =====

	static function findAllSM(obj:h2d.Object, ?into:Array<AnimationSM>):Array<AnimationSM> {
		final all = into != null ? into : [];
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, AnimationSM))
				all.push(cast child);
			findAllSM(child, all);
		}
		return all;
	}

	/** Which of body, hat, glow the machine draws: "bhg", "b-g", … **/
	static function shownLayers(sm:AnimationSM):String {
		return [for (n in ["body", "hat", "glow"]) sm.layer(n).visible ? n.charAt(0) : "-"].join("");
	}

	@Test
	public function testHideLayerInAndLayerNamesIn() {
		final root = new h2d.Object();
		final sm = smOf(LAYERED, ["direction" => "l", "hat" => "cap"]);
		root.addChild(sm);
		Assert.isTrue(AnimationSM.hideLayerIn(root, "hat"), "found under the root");
		Assert.isFalse(sm.layer("hat").visible);
		Assert.isTrue(sm.layer("glow").visible);
		Assert.isFalse(AnimationSM.hideLayerIn(root, "cape"), "a layer no machine has");
		Assert.same(["shadow", "body", "hat", "glow"], AnimationSM.layerNamesIn(root));
		Assert.same([], AnimationSM.layerNamesIn(new h2d.Object()));
	}

	@Test
	public function testHideLeavesLayersOut() {
		final result = BuilderTestBase.buildFromFile(HIDE_FIXTURE, "stateAnimHide", null, Incremental);
		final mp = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false));
		final roots:Array<h2d.Object> = [result.object, mp.stateAnimHide.create()];
		for (backend in 0...2) {
			final which = backend == 0 ? "builder" : "codegen";
			final sms = findAllSM(roots[backend]);
			Assert.equals(6, sms.length, '$which: three stateanims and three figures');
			Assert.same(["bhg", "b-g", "b--", "bhg", "bh-", "b-g"], [for (sm in sms) shownLayers(sm)],
				'$which: stateanim, hide => [hat], hide => [hat, glow]; staticRef, staticRef hide => [glow], dynamicRef hide => [hat]');
		}
	}

	@Test
	public function testHiddenLayersStayHiddenAsParametersChange() {
		final result = BuilderTestBase.buildFromFile(HIDE_FIXTURE, "stateAnimHideRefs", null, Incremental);
		final mp = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false));
		final inst:Dynamic = mp.stateAnimHideRefs.create();
		for (backend in 0...2) {
			final which = backend == 0 ? "builder" : "codegen";
			final root:h2d.Object = backend == 0 ? result.object : cast inst;
			Assert.same(["b-g", "bh-"], [for (sm in findAllSM(root)) shownLayers(sm)], '$which: as built');
			if (backend == 0) result.setParameter("dir", "r") else inst.setParameter("dir", "r");
			final sms = findAllSM(root);
			Assert.equals("r", sms[0].currentSelector.get("direction"), '$which: the dynamicRef followed');
			Assert.equals("r", sms[1].currentSelector.get("direction"), '$which: the staticRef was built again');
			Assert.same(["b-g", "bh-"], [for (sm in sms) shownLayers(sm)], '$which: the same layers left out');
		}
	}

	@Test
	public function testHiddenLayersOnAStateanimTheRefDrawsLater() {
		final result = BuilderTestBase.buildFromFile(HIDE_FIXTURE, "stateAnimHideArms", null, Incremental);
		final mp = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false));
		final inst:Dynamic = mp.stateAnimHideArms.create();
		for (backend in 0...2) {
			final which = backend == 0 ? "builder" : "codegen";
			final root:h2d.Object = backend == 0 ? result.object : cast inst;
			Assert.same(["b-g"], [for (sm in findAllSM(root)) shownLayers(sm)], '$which: the pose without its hat');
			if (backend == 0) result.setParameter("kind", "walk") else inst.setParameter("kind", "walk");
			final shown = [for (sm in findAllSM(root)) if (sm.getCurrentAnimName() == "walk") sm];
			Assert.equals(1, shown.length, '$which: the walk drawn');
			Assert.isFalse(shown[0].layer("hat").visible, '$which: an arm built on its first show leaves the hat out too');
		}
	}

	static function buildError(source:String, name:String):Null<String> {
		try {
			BuilderTestBase.buildFromSource(source, name);
			return null;
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	@Test
	public function testHideNamingALayerTheAnimHasNotIsAnError() {
		final onStateanim = buildError("#p programmable() {\n\tstateanim(\"marineLayers.anim\", \"pose\", direction=>l, hat=>cap, glow=>on, hide => [hat, cape]): 0, 0\n}", "p");
		Assert.notNull(onStateanim);
		Assert.stringContains("stateanim(\"marineLayers.anim\") on line 3: hide => [hat, cape]: the .anim has no layer \"cape\" (its layers: body, hat, glow)", onStateanim);

		final noLayers = buildError("#p programmable() {\n\tstateanim(\"marine.anim\", \"idle\", direction=>l, hide => [weapon]): 0, 0\n}", "p");
		Assert.notNull(noLayers);
		Assert.stringContains("the .anim has no layers (no layers: line), so there is no layer \"weapon\" to hide", noLayers);

		final onRef = buildError("#fig programmable() {\n\tstateanim(\"marineLayers.anim\", \"pose\", direction=>l, hat=>cap, glow=>on): 0, 0\n}\n"
			+ "#p programmable() {\n\tstaticRef(fig, hide => [cape]): 0, 0\n}", "p");
		Assert.notNull(onRef);
		Assert.stringContains("staticRef(fig) on line 6: hide => [cape]: no stateanim it draws has a layer \"cape\" (their layers: body, hat, glow)", onRef);

		final onDynamicRef = buildError("#fig programmable() {\n\tbitmap(generated(color(4, 4, #FF0000))): 0, 0\n}\n"
			+ "#p programmable() {\n\tdynamicRef(fig, hide => [hat]): 0, 0\n}", "p");
		Assert.notNull(onDynamicRef);
		Assert.stringContains("dynamicRef(fig) on line 6: hide => [hat]: it draws no stateanim with layers", onDynamicRef);

		final mp = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false));
		var codegen:Null<String> = null;
		try
			mp.stateAnimHideBad.create()
		catch (e:Dynamic)
			codegen = Std.string(e);
		Assert.notNull(codegen);
		Assert.stringContains("stateanim(\"marineLayers.anim\") on line 41 of test/examples/175-stateAnimHide/stateAnimHide.manim: hide => [hat, cape]: the .anim has no layer \"cape\" (its layers: body, hat, glow)", codegen);
	}

	@Test
	public function testHideParsing() {
		Assert.stringContains("hides nothing", BuilderTestBase.parseExpectingError("#p programmable() {\n\tstateanim(\"a.anim\", \"s\", hide => []): 0, 0\n}"));
		Assert.stringContains("not $x", BuilderTestBase.parseExpectingError("#p programmable(x:string=\"a\") {\n\tstateanim(\"a.anim\", \"s\", hide => [$x]): 0, 0\n}"));
		Assert.stringContains("names layer \"hat\" twice", BuilderTestBase.parseExpectingError("#p programmable() {\n\tstateanim(\"a.anim\", \"s\", hide => [hat, glow, hat]): 0, 0\n}"));
		Assert.stringContains("given twice", BuilderTestBase.parseExpectingError("#f programmable() {\n\tpoint: 0, 0\n}\n#p programmable() {\n\tstaticRef(f, hide => [hat], hide => [glow]): 0, 0\n}"));

		// A list is the layers left out; any other value is what it was: a state, or a ref's argument
		final parsed = bh.multianim.MultiAnimParser.parseFileNoImports(byte.ByteData.ofString("version: 1.0\n"
			+ "#f programmable(hide:string=\"\") { point: 0, 0 }\n"
			+ "#p programmable(list:string=\"x\") {\n"
			+ "\tstateanim(\"a.anim\", \"s\", hide => yes, hide => [hat, \"glow\",]): 0, 0\n"
			+ "\tstaticRef(f, hide => $list): 0, 0\n"
			+ "\tdynamicRef(f, hide => \"x\"): 0, 0\n"
			+ "}"), "test-input");
		final children = parsed.nodes.get("p").children;
		switch children[0].type {
			case STATEANIM(_, _, selector, seek):
				Assert.isTrue(selector.exists("hide"), "hide => yes selects the state hide");
				Assert.isNull(seek);
			default:
				Assert.fail("expected a stateanim");
		}
		Assert.same(["hat", "glow"], children[0].hiddenLayers.names, "a trailing comma is fine; a quoted name too");
		Assert.equals(4, children[0].hiddenLayers.line);
		for (i in 1...3) {
			switch children[i].type {
				case STATIC_REF(_, _, params) | DYNAMIC_REF(_, _, params):
					Assert.isTrue(params.exists("hide"), "hide => a value that is not a list is the target's argument");
				default:
					Assert.fail("expected a ref");
			}
			Assert.isNull(children[i].hiddenLayers);
		}
	}

	// ===== stateanim construct: a tile name built from parameters =====

	@Test
	public function testConstructTileNameFromParameters() {
		final bare = BuilderTestBase.parseExpectingError("#p programmable(dir:[l, r]=l) {\n\tstateanim construct(\"a\", \"a\" => sheet \"crew2\", marine_${dir}_idle, 4): 0, 0\n}");
		Assert.notNull(bare);
		Assert.stringContains("a tile name built from parameters is a single-quoted string, 'body_${dir}_human'", bare);

		final fixture = "test/examples/176-stateAnimConstructName/stateAnimConstructName.manim";
		final result = BuilderTestBase.buildFromFile(fixture, "stateAnimConstructName", null, Incremental);
		final mp = new bh.test.MultiProgrammable(bh.test.TestResourceLoader.createLoader(false));
		final roots:Array<h2d.Object> = [result.object, mp.stateAnimConstructName.create()];
		for (backend in 0...2) {
			final which = backend == 0 ? "builder" : "codegen";
			final sms = findAllSM(roots[backend]);
			Assert.equals(3, sms.length, which);
			// marine_r_idle has 4 frames, marine_l_hit 5, marine_r_killed 6: each name worked out by the values' names
			Assert.same([4, 5, 6], [for (sm in sms) sm.frameCount()], '$which: the frames the names built from dir and pose name');
			Assert.equals("hit", sms[2].getCurrentAnimName(), '$which: the initial state an enum parameter names, by its value\'s name');
		}
	}

	static function findSM(obj:h2d.Object):Null<AnimationSM> {
		for (i in 0...obj.numChildren) {
			final child = obj.getChildAt(i);
			if (Std.isOfType(child, AnimationSM))
				return cast child;
			final found = findSM(child);
			if (found != null)
				return found;
		}
		return null;
	}
}
