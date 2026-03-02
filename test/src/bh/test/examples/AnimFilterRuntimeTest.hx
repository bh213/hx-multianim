package bh.test.examples;

import utest.Assert;
import bh.stateanim.AnimationSM;
import bh.stateanim.AnimationFrame;

/**
 * Unit tests for AnimationSM:
 * animation state registration, playback, filters, tint colors, loop counts, events.
 */
class AnimFilterRuntimeTest extends utest.Test {
	// ==================== Helpers ====================

	/** Create a simple AnimationFrame with a colored tile. */
	static function createFrame(duration:Float):AnimationFrame {
		var tile = h2d.Tile.fromColor(0xFF0000, 16, 16);
		return new AnimationFrame(tile, duration, 0, 0, 16, 16);
	}

	/** Create an AnimationSM in externally-driven mode (no sync). */
	static function createSM():AnimationSM {
		return new AnimationSM(new Map(), true);
	}

	// ==================== Basic Registration & Play ====================

	@Test
	public function testAddAnimationState():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		sm.addAnimationState("idle", [Frame(frame)], -1, new Map());
		Assert.isTrue(sm.animationStates.exists("idle"));
	}

	@Test
	public function testPlaySetsCurrentName():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		sm.addAnimationState("idle", [Frame(frame)], -1, new Map());
		sm.play("idle");
		Assert.equals("idle", sm.getCurrentAnimName());
	}

	@Test
	public function testPlayUnknownThrows():Void {
		var sm = createSM();
		try {
			sm.play("nonexistent");
			Assert.fail("Should throw for unknown animation");
		} catch (e:Dynamic) {
			Assert.isTrue(true);
		}
	}

	@Test
	public function testDuplicateAnimNameThrows():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		sm.addAnimationState("idle", [Frame(frame)], -1, new Map());
		try {
			sm.addAnimationState("idle", [Frame(frame)], -1, new Map());
			Assert.fail("Should throw for duplicate name");
		} catch (e:Dynamic) {
			Assert.isTrue(true);
		}
	}

	@Test
	public function testGetCurrentAnimNameBeforePlay():Void {
		var sm = createSM();
		Assert.isNull(sm.getCurrentAnimName());
	}

	// ==================== Loop Count ====================

	@Test
	public function testInfiniteLoopNeverFinishes():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		sm.addAnimationState("idle", [Frame(frame)], -1, new Map());
		sm.play("idle");

		// Advance many times
		for (_ in 0...100) {
			sm.update(0.1);
		}
		Assert.isFalse(sm.isFinished());
	}

	@Test
	public function testNoLoopFinishes():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		sm.addAnimationState("once", [Frame(frame)], 0, new Map());
		sm.play("once");

		sm.update(0.2); // past the single frame
		Assert.isTrue(sm.isFinished());
	}

	@Test
	public function testCountedLoopFinishes():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		sm.addAnimationState("loop3", [Frame(frame)], 3, new Map());
		sm.play("loop3");

		// Need to advance through initial play + 3 loops = 4 total passes
		for (_ in 0...50) {
			sm.update(0.1);
		}
		Assert.isTrue(sm.isFinished());
	}

	@Test
	public function testOnFinishedCallback():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		sm.addAnimationState("once", [Frame(frame)], 0, new Map());

		var finished = false;
		sm.onFinished = function() {
			finished = true;
		};
		sm.play("once");
		sm.update(0.2);
		Assert.isTrue(finished);
	}

	// ==================== Filter & Tint ====================

	@Test
	public function testPlayAppliesNullFilter():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		sm.addAnimationState("idle", [Frame(frame)], -1, new Map(), null, null);
		sm.play("idle");
		// No filter set
		Assert.isNull(sm.clip.filter);
	}

	@Test
	public function testPlayWithNullTintSetsWhite():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		sm.addAnimationState("idle", [Frame(frame)], -1, new Map(), null, null);
		sm.play("idle");
		// Null tint → 0xFFFFFFFF (white)
		@:privateAccess {
			var colorVal = sm.clip.color.r;
			// r should be ~1.0 for white
			Assert.isTrue(colorVal > 0.9);
		}
	}

	@Test
	public function testPlayWithTintColor():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		// tintColor 0xFF0000 (red, no alpha byte)
		sm.addAnimationState("idle", [Frame(frame)], -1, new Map(), null, 0xFF0000);
		sm.play("idle");
		// When alpha byte is 0, 0xFF000000 is prepended
		@:privateAccess {
			// Red channel should be high
			var r = sm.clip.color.r;
			Assert.isTrue(r > 0.9);
		}
	}

	// ==================== SetFilter Frame State ====================

	@Test
	public function testSetFilterNullFallsBackToAnimFilter():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		// Animation with no filter
		var states:Array<AnimationFrameState> = [SetFilter(null, null), Frame(frame)];
		sm.addAnimationState("test", states, 0, new Map(), null, null);
		sm.play("test");
		// SetFilter with null filter and null tint → should use animation-level (also null)
		Assert.isNull(sm.clip.filter);
	}

	@Test
	public function testSetFilterNullTintFallsBackToAnimTint():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		// Animation with tint 0x00FF00
		var states:Array<AnimationFrameState> = [SetFilter(null, null), Frame(frame)];
		sm.addAnimationState("test", states, 0, new Map(), null, 0x00FF00);
		sm.play("test");
		// SetFilter with null tint → should use animation-level tint
		@:privateAccess {
			// Green channel should be high
			var g = sm.clip.color.g;
			Assert.isTrue(g > 0.9);
		}
	}

	// ==================== Events ====================

	@Test
	public function testTriggerEvent():Void {
		var sm = createSM();
		var shortFrame = createFrame(0.001);
		var frame = createFrame(0.1);
		var states:Array<AnimationFrameState> = [Frame(shortFrame), Event(Trigger("fire")), Frame(frame)];
		sm.addAnimationState("test", states, 0, new Map());

		var eventFired = false;
		sm.onAnimationEvent = function(event) {
			switch (event) {
				case Trigger(data):
					eventFired = true;
				default:
			}
		};
		sm.play("test");
		sm.update(0.01); // past shortFrame duration, triggers Event
		Assert.isTrue(eventFired);
	}

	@Test
	public function testTriggerDataEvent():Void {
		var sm = createSM();
		var shortFrame = createFrame(0.001);
		var frame = createFrame(0.1);
		var meta = new Map<String, String>();
		meta.set("damage", "50");
		var states:Array<AnimationFrameState> = [Frame(shortFrame), Event(TriggerData("hit", meta)), Frame(frame)];
		sm.addAnimationState("test", states, 0, new Map());

		var eventName:String = null;
		sm.onAnimationEvent = function(event) {
			switch (event) {
				case TriggerData(name, _):
					eventName = name;
				default:
			}
		};
		sm.play("test");
		sm.update(0.01); // past shortFrame, triggers TriggerData event
		Assert.equals("hit", eventName);
	}

	@Test
	public function testPointEvent():Void {
		var sm = createSM();
		var shortFrame = createFrame(0.001);
		var frame = createFrame(0.1);
		var pt = new h2d.col.IPoint(10, 20);
		var states:Array<AnimationFrameState> = [Frame(shortFrame), Event(PointEvent("spawn", pt)), Frame(frame)];
		sm.addAnimationState("test", states, 0, new Map());

		var eventPoint:h2d.col.IPoint = null;
		sm.onAnimationEvent = function(event) {
			switch (event) {
				case PointEvent(name, point):
					eventPoint = point;
				default:
			}
		};
		sm.play("test");
		sm.update(0.01); // past shortFrame, triggers PointEvent
		Assert.notNull(eventPoint);
		if (eventPoint == null) return;
		Assert.equals(10, eventPoint.x);
		Assert.equals(20, eventPoint.y);
	}

	// ==================== Extra Points ====================

	@Test
	public function testExtraPointRetrieval():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		var extraPoints = new Map<String, h2d.col.IPoint>();
		extraPoints.set("bullet", new h2d.col.IPoint(5, 10));
		sm.addAnimationState("idle", [Frame(frame)], -1, extraPoints);
		sm.play("idle");

		var pt = sm.getExtraPoint("bullet");
		Assert.notNull(pt);
		Assert.equals(5, pt.x);
		Assert.equals(10, pt.y);
	}

	@Test
	public function testExtraPointMissing():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		sm.addAnimationState("idle", [Frame(frame)], -1, new Map());
		sm.play("idle");

		var pt = sm.getExtraPoint("nonexistent");
		Assert.isNull(pt);
	}

	@Test
	public function testGetExtraPointNames():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		var extraPoints = new Map<String, h2d.col.IPoint>();
		extraPoints.set("bullet", new h2d.col.IPoint(5, 10));
		extraPoints.set("shield", new h2d.col.IPoint(15, 20));
		sm.addAnimationState("idle", [Frame(frame)], -1, extraPoints);
		sm.play("idle");

		var names = sm.getExtraPointNames();
		Assert.equals(2, names.length);
		Assert.isTrue(names.indexOf("bullet") >= 0);
		Assert.isTrue(names.indexOf("shield") >= 0);
	}

	@Test
	public function testGetExtraPointNamesBeforePlay():Void {
		var sm = createSM();
		var names = sm.getExtraPointNames();
		Assert.equals(0, names.length);
	}

	// ==================== Pause ====================

	@Test
	public function testPausedDoesNotAdvance():Void {
		var sm = createSM();
		var frame1 = createFrame(0.1);
		var frame2 = createFrame(0.1);
		sm.addAnimationState("test", [Frame(frame1), Frame(frame2)], 0, new Map());
		sm.play("test");

		sm.paused = true;
		sm.update(0.5);
		// Should not advance past first frame
		Assert.equals(0, sm.currentStateIndex);
	}

	// ==================== ExternallyDriven ====================

	@Test
	public function testExternallyDrivenFlag():Void {
		var sm = new AnimationSM(new Map(), true);
		Assert.isTrue(sm.externallyDriven);

		var sm2 = new AnimationSM(new Map(), false);
		Assert.isFalse(sm2.externallyDriven);
	}

	// ==================== RandomPointEvent with deterministic random ====================

	@Test
	public function testRandomPointEventDeterministic():Void {
		var sm = createSM();
		var shortFrame = createFrame(0.001);
		var frame = createFrame(0.1);
		var pt = new h2d.col.IPoint(50, 50);
		var states:Array<AnimationFrameState> = [Frame(shortFrame), Event(RandomPointEvent("spark", pt, 10.0)), Frame(frame)];
		sm.addAnimationState("test", states, 0, new Map());

		// Set deterministic random: always returns 0.5
		sm.randomFunc = function():Float { return 0.5; };

		var eventPoint:h2d.col.IPoint = null;
		sm.onAnimationEvent = function(event) {
			switch (event) {
				case PointEvent(name, point):
					eventPoint = point;
				default:
			}
		};
		sm.play("test");
		sm.update(0.01); // past shortFrame, triggers RandomPointEvent

		Assert.notNull(eventPoint);
		if (eventPoint == null) return;
		// With random=0.5: angle=0.5*2*PI=PI, r=0.5*10=5
		// offset: (5*cos(PI), 5*sin(PI)) = (-5, ~0)
		Assert.isTrue(eventPoint.x >= 40 && eventPoint.x <= 60);
		Assert.isTrue(eventPoint.y >= 40 && eventPoint.y <= 60);
	}

	// ==================== getExtraPointForAnim ====================

	@Test
	public function testGetExtraPointForAnim():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		var ep1 = new Map<String, h2d.col.IPoint>();
		ep1.set("pt", new h2d.col.IPoint(1, 2));
		var ep2 = new Map<String, h2d.col.IPoint>();
		ep2.set("pt", new h2d.col.IPoint(10, 20));
		sm.addAnimationState("anim1", [Frame(frame)], -1, ep1);
		sm.addAnimationState("anim2", [Frame(frame)], -1, ep2);
		sm.play("anim1");

		// Should get point from anim2, not current
		var pt = sm.getExtraPointForAnim("pt", "anim2");
		Assert.notNull(pt);
		Assert.equals(10, pt.x);
		Assert.equals(20, pt.y);
	}

	@Test
	public function testGetExtraPointForAnimUnknownThrows():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		sm.addAnimationState("idle", [Frame(frame)], -1, new Map());
		sm.play("idle");

		try {
			sm.getExtraPointForAnim("pt", "nonexistent");
			Assert.fail("Should throw for unknown anim state");
		} catch (e:Dynamic) {
			Assert.isTrue(true);
		}
	}
}
