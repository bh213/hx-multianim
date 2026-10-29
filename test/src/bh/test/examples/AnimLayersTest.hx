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
