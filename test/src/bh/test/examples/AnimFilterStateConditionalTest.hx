package bh.test.examples;

import utest.Assert;
import bh.stateanim.AnimParser;
import bh.stateanim.AnimParser.AnimFilterType;
import bh.stateanim.AnimParser.AnimFilterEntry;
import bh.stateanim.AnimParser.AnimConditionalSelector;
import bh.stateanim.AnimParser.AnimConditionalValue;
import bh.stateanim.AnimParser.AnimCompareOp;
import bh.stateanim.AnimParser.AnimationStateSelector;
import bh.stateanim.AnimationSM;
import bh.stateanim.AnimationSM.AnimationFrameState;
import bh.stateanim.AnimationFrame;

/**
 * Integration tests for .anim typed filter state-conditional resolution.
 *
 * Tests countStateMatch (state selector matching), buildAnimFilter (filter creation),
 * resolveAnimFilters (combined matching + filter building), and AnimationSM filter
 * application when animations have state-dependent filters and tint colors.
 */
@:access(bh.stateanim.AnimParser)
class AnimFilterStateConditionalTest extends utest.Test {
	// ==================== Helpers ====================

	static function createFrame(duration:Float):AnimationFrame {
		var tile = h2d.Tile.fromColor(0xFF0000, 16, 16);
		return new AnimationFrame(tile, duration, 0, 0, 16, 16);
	}

	static function createSM(?selector:AnimationStateSelector):AnimationSM {
		if (selector == null) selector = new Map();
		return new AnimationSM(selector, true);
	}

	static function makeSelector(entries:Array<{key:String, value:String}>):AnimConditionalSelector {
		var map:AnimConditionalSelector = new Map();
		for (e in entries)
			map.set(e.key, ACVSingle(e.value));
		return map;
	}

	static function makeStateSelector(entries:Array<{key:String, value:String}>):AnimationStateSelector {
		var map:AnimationStateSelector = new Map();
		for (e in entries)
			map.set(e.key, e.value);
		return map;
	}

	// ==================== countStateMatch: Basic ====================

	@Test
	public function testCountStateMatchExactMatch():Void {
		final cond = makeSelector([{key: "status", value: "hit"}]);
		final runtime = makeStateSelector([{key: "status", value: "hit"}]);
		final score = AnimParser.countStateMatch(cond, runtime);
		Assert.isTrue(score > 0, 'Exact match should have positive score, got $score');
	}

	@Test
	public function testCountStateMatchNoMatch():Void {
		final cond = makeSelector([{key: "status", value: "hit"}]);
		final runtime = makeStateSelector([{key: "status", value: "idle"}]);
		final score = AnimParser.countStateMatch(cond, runtime);
		Assert.isTrue(score < 0, 'Non-matching should have negative score, got $score');
	}

	@Test
	public function testCountStateMatchEmptyCondition():Void {
		final cond:AnimConditionalSelector = new Map();
		final runtime = makeStateSelector([{key: "status", value: "hit"}]);
		final score = AnimParser.countStateMatch(cond, runtime);
		// Empty condition matches anything (score 0 = neutral)
		Assert.isTrue(score >= 0, 'Empty condition should match (score >= 0), got $score');
	}

	@Test
	public function testCountStateMatchMultipleKeys():Void {
		final cond = makeSelector([{key: "status", value: "hit"}, {key: "team", value: "red"}]);
		final runtime = makeStateSelector([{key: "status", value: "hit"}, {key: "team", value: "red"}]);
		final score = AnimParser.countStateMatch(cond, runtime);
		Assert.isTrue(score >= 2, 'Two matching keys should score >= 2, got $score');
	}

	@Test
	public function testCountStateMatchPartialKeyMismatch():Void {
		final cond = makeSelector([{key: "status", value: "hit"}, {key: "team", value: "red"}]);
		final runtime = makeStateSelector([{key: "status", value: "hit"}, {key: "team", value: "blue"}]);
		final score = AnimParser.countStateMatch(cond, runtime);
		// One match, one miss → score should be negative (penalty -10000)
		Assert.isTrue(score < 0, 'Partial mismatch should have negative score, got $score');
	}

	// ==================== countStateMatch: Multi-Value ====================

	@Test
	public function testCountStateMatchMultiValue():Void {
		var cond:AnimConditionalSelector = new Map();
		cond.set("status", ACVMulti(["hit", "stunned"]));
		final runtime = makeStateSelector([{key: "status", value: "hit"}]);
		final score = AnimParser.countStateMatch(cond, runtime);
		Assert.isTrue(score > 0, 'Multi-value match should be positive');
	}

	@Test
	public function testCountStateMatchMultiValueNoMatch():Void {
		var cond:AnimConditionalSelector = new Map();
		cond.set("status", ACVMulti(["hit", "stunned"]));
		final runtime = makeStateSelector([{key: "status", value: "idle"}]);
		final score = AnimParser.countStateMatch(cond, runtime);
		Assert.isTrue(score < 0, 'Multi-value non-match should be negative');
	}

	// ==================== countStateMatch: Negation ====================

	@Test
	public function testCountStateMatchNegation():Void {
		var cond:AnimConditionalSelector = new Map();
		cond.set("status", ACVNot(ACVSingle("idle")));
		final runtime = makeStateSelector([{key: "status", value: "hit"}]);
		final score = AnimParser.countStateMatch(cond, runtime);
		Assert.isTrue(score > 0, 'Negation should match non-matching value');
	}

	@Test
	public function testCountStateMatchNegationFails():Void {
		var cond:AnimConditionalSelector = new Map();
		cond.set("status", ACVNot(ACVSingle("idle")));
		final runtime = makeStateSelector([{key: "status", value: "idle"}]);
		final score = AnimParser.countStateMatch(cond, runtime);
		Assert.isTrue(score < 0, 'Negation should fail for matching value');
	}

	// ==================== countStateMatch: Comparison ====================

	@Test
	public function testCountStateMatchGreaterEqual():Void {
		var cond:AnimConditionalSelector = new Map();
		cond.set("level", ACVCompare(ACmpGte, "3"));
		final runtime = makeStateSelector([{key: "level", value: "5"}]);
		final score = AnimParser.countStateMatch(cond, runtime);
		Assert.isTrue(score > 0, 'level=5 >= 3 should match');
	}

	@Test
	public function testCountStateMatchGreaterEqualFails():Void {
		var cond:AnimConditionalSelector = new Map();
		cond.set("level", ACVCompare(ACmpGte, "3"));
		final runtime = makeStateSelector([{key: "level", value: "2"}]);
		final score = AnimParser.countStateMatch(cond, runtime);
		Assert.isTrue(score < 0, 'level=2 >= 3 should not match');
	}

	@Test
	public function testCountStateMatchLessThan():Void {
		var cond:AnimConditionalSelector = new Map();
		cond.set("health", ACVCompare(ACmpLt, "30"));
		final runtime = makeStateSelector([{key: "health", value: "10"}]);
		final score = AnimParser.countStateMatch(cond, runtime);
		Assert.isTrue(score > 0, 'health=10 < 30 should match');
	}

	// ==================== countStateMatch: Range ====================

	@Test
	public function testCountStateMatchRange():Void {
		var cond:AnimConditionalSelector = new Map();
		cond.set("level", ACVRange("1", "5"));
		final runtime = makeStateSelector([{key: "level", value: "3"}]);
		final score = AnimParser.countStateMatch(cond, runtime);
		Assert.isTrue(score > 0, 'level=3 in range 1..5 should match');
	}

	@Test
	public function testCountStateMatchRangeOutOfBounds():Void {
		var cond:AnimConditionalSelector = new Map();
		cond.set("level", ACVRange("1", "5"));
		final runtime = makeStateSelector([{key: "level", value: "7"}]);
		final score = AnimParser.countStateMatch(cond, runtime);
		Assert.isTrue(score < 0, 'level=7 outside range 1..5 should not match');
	}

	// ==================== buildAnimFilter ====================

	@Test
	public function testBuildAnimFilterTint():Void {
		// Tint returns null filter (handled separately via tintColor)
		final filter = AnimParser.buildAnimFilter(AFTint(0xFF0000));
		Assert.isNull(filter, "Tint should return null filter (tint is separate)");
	}

	@Test
	public function testBuildAnimFilterBrightness():Void {
		final filter = AnimParser.buildAnimFilter(AFBrightness(0.5));
		Assert.notNull(filter, "Brightness should produce a filter");
		Assert.isTrue(Std.isOfType(filter, h2d.filter.ColorMatrix));
	}

	@Test
	public function testBuildAnimFilterOutline():Void {
		final filter = AnimParser.buildAnimFilter(AFOutline(2.0, 0x00FF00));
		Assert.notNull(filter, "Outline should produce a filter");
		Assert.isTrue(Std.isOfType(filter, h2d.filter.Outline));
	}

	@Test
	public function testBuildAnimFilterNone():Void {
		final filter = AnimParser.buildAnimFilter(AFNone);
		Assert.isNull(filter, "None should return null filter");
	}

	// ==================== resolveAnimFilters ====================

	@Test
	public function testResolveAnimFiltersMatchingEntry():Void {
		final entries:Array<AnimFilterEntry> = [
			{states: makeSelector([{key: "status", value: "hit"}]), filter: AFBrightness(0.5)},
			{states: makeSelector([{key: "status", value: "idle"}]), filter: AFBrightness(1.0)}
		];
		final runtime = makeStateSelector([{key: "status", value: "hit"}]);
		final result = AnimParser.resolveAnimFilters(entries, runtime);
		Assert.notNull(result.filter, "Should resolve a filter for matching state");
	}

	@Test
	public function testResolveAnimFiltersTintExtracted():Void {
		final entries:Array<AnimFilterEntry> = [
			{states: makeSelector([{key: "team", value: "red"}]), filter: AFTint(0xFF0000)},
			{states: makeSelector([{key: "team", value: "blue"}]), filter: AFTint(0x0000FF)}
		];
		final runtime = makeStateSelector([{key: "team", value: "red"}]);
		final result = AnimParser.resolveAnimFilters(entries, runtime);
		Assert.isNull(result.filter, "Tint should not produce a h2d filter");
		Assert.equals(0xFF0000, result.tintColor);
	}

	@Test
	public function testResolveAnimFiltersTintDifferentState():Void {
		final entries:Array<AnimFilterEntry> = [
			{states: makeSelector([{key: "team", value: "red"}]), filter: AFTint(0xFF0000)},
			{states: makeSelector([{key: "team", value: "blue"}]), filter: AFTint(0x0000FF)}
		];
		final runtime = makeStateSelector([{key: "team", value: "blue"}]);
		final result = AnimParser.resolveAnimFilters(entries, runtime);
		Assert.equals(0x0000FF, result.tintColor);
	}

	@Test
	public function testResolveAnimFiltersNoMatch():Void {
		final entries:Array<AnimFilterEntry> = [
			{states: makeSelector([{key: "status", value: "hit"}]), filter: AFBrightness(0.5)}
		];
		final runtime = makeStateSelector([{key: "status", value: "idle"}]);
		final result = AnimParser.resolveAnimFilters(entries, runtime);
		Assert.isNull(result.filter, "Non-matching state should produce null filter");
		Assert.isNull(result.tintColor, "Non-matching state should produce null tint");
	}

	@Test
	public function testResolveAnimFiltersEmptyConditionMatchesAll():Void {
		// Empty condition = @default / unconditional
		var defaultCond:AnimConditionalSelector = new Map();
		final entries:Array<AnimFilterEntry> = [
			{states: defaultCond, filter: AFBrightness(0.8)}
		];
		final runtime = makeStateSelector([{key: "status", value: "anything"}]);
		final result = AnimParser.resolveAnimFilters(entries, runtime);
		Assert.notNull(result.filter, "Empty condition (default) should always match");
	}

	@Test
	public function testResolveAnimFiltersNullEntries():Void {
		final result = AnimParser.resolveAnimFilters(null, new Map());
		Assert.isNull(result.filter);
		Assert.isNull(result.tintColor);
	}

	@Test
	public function testResolveAnimFiltersEmptyEntries():Void {
		final result = AnimParser.resolveAnimFilters([], new Map());
		Assert.isNull(result.filter);
		Assert.isNull(result.tintColor);
	}

	// ==================== AnimationSM: State-Conditional Filter Application ====================

	@Test
	public function testAnimSMWithFilterAppliedOnPlay():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		var filter = new h2d.filter.Outline(2.0, 0xFF0000);
		sm.addAnimationState("idle", [Frame(frame)], -1, new Map(), filter, null);
		sm.play("idle");
		Assert.notNull(sm.clip.filter, "Filter should be applied on play");
	}

	@Test
	public function testAnimSMWithTintAppliedOnPlay():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		sm.addAnimationState("idle", [Frame(frame)], -1, new Map(), null, 0xFF0000);
		sm.play("idle");
		@:privateAccess {
			Assert.isTrue(sm.clip.color.r > 0.9, "Red channel should be high for red tint");
			Assert.isTrue(sm.clip.color.g < 0.1, "Green channel should be low for red tint");
		}
	}

	@Test
	public function testAnimSMSwitchAnimChangesFilter():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		var filter1 = new h2d.filter.Outline(2.0, 0xFF0000);
		var filter2 = new h2d.filter.Outline(4.0, 0x00FF00);
		sm.addAnimationState("idle", [Frame(frame)], -1, new Map(), filter1, null);
		sm.addAnimationState("hit", [Frame(frame)], -1, new Map(), filter2, null);

		sm.play("idle");
		var firstFilter = sm.clip.filter;
		Assert.notNull(firstFilter);

		sm.play("hit");
		var secondFilter = sm.clip.filter;
		Assert.notNull(secondFilter);
		// Filters should be different objects
		Assert.isFalse(firstFilter == secondFilter, "Switching anims should change filter");
	}

	@Test
	public function testAnimSMSwitchAnimChangesToNullFilter():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		var filter = new h2d.filter.Outline(2.0, 0xFF0000);
		sm.addAnimationState("filtered", [Frame(frame)], -1, new Map(), filter, null);
		sm.addAnimationState("plain", [Frame(frame)], -1, new Map(), null, null);

		sm.play("filtered");
		Assert.notNull(sm.clip.filter);

		sm.play("plain");
		Assert.isNull(sm.clip.filter, "Switching to anim without filter should clear filter");
	}

	@Test
	public function testAnimSMSwitchAnimChangesToNullTint():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		sm.addAnimationState("tinted", [Frame(frame)], -1, new Map(), null, 0xFF0000);
		sm.addAnimationState("plain", [Frame(frame)], -1, new Map(), null, null);

		sm.play("tinted");
		@:privateAccess {
			Assert.isTrue(sm.clip.color.r > 0.9, "Red should be high for tinted");
		}

		sm.play("plain");
		@:privateAccess {
			// Null tint → white (1.0, 1.0, 1.0)
			Assert.isTrue(sm.clip.color.r > 0.9, "Red should be high for white");
			Assert.isTrue(sm.clip.color.g > 0.9, "Green should be high for white");
			Assert.isTrue(sm.clip.color.b > 0.9, "Blue should be high for white");
		}
	}

	@Test
	public function testAnimSMSetFilterPerFrameOverridesAnimFilter():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		var animFilter = new h2d.filter.Outline(2.0, 0xFF0000);
		var frameFilter = new h2d.filter.Outline(4.0, 0x00FF00);
		var states:Array<AnimationFrameState> = [SetFilter(frameFilter, null), Frame(frame)];
		sm.addAnimationState("test", states, 0, new Map(), animFilter, null);
		sm.play("test");
		// Frame-level SetFilter should override animation-level filter
		Assert.isTrue(sm.clip.filter == frameFilter, "Frame filter should override anim filter");
	}

	@Test
	public function testAnimSMSetFilterNullFallsBackToAnimFilter():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		var animFilter = new h2d.filter.Outline(2.0, 0xFF0000);
		var states:Array<AnimationFrameState> = [SetFilter(null, null), Frame(frame)];
		sm.addAnimationState("test", states, 0, new Map(), animFilter, null);
		sm.play("test");
		// SetFilter(null) falls back to animation-level filter
		Assert.isTrue(sm.clip.filter == animFilter, "Null frame filter should fall back to anim filter");
	}

	@Test
	public function testAnimSMSetFilterTintOverridesAnimTint():Void {
		var sm = createSM();
		var frame = createFrame(0.1);
		var states:Array<AnimationFrameState> = [SetFilter(null, 0x00FF00), Frame(frame)];
		sm.addAnimationState("test", states, 0, new Map(), null, 0xFF0000);
		sm.play("test");
		@:privateAccess {
			// Frame-level green tint overrides animation-level red tint
			Assert.isTrue(sm.clip.color.g > 0.9, "Frame tint green should override anim tint");
		}
	}
}
