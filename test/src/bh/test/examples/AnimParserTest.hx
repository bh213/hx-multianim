package bh.test.examples;

import utest.Assert;
import bh.stateanim.AnimParser;
import bh.stateanim.AnimParser.AnimMetadata;
import bh.stateanim.AnimParser.AnimParserResult;
import bh.stateanim.AnimationSM.AnimationFrameState;
import bh.stateanim.AnimationSM.AnimationPlaylistEvent;

/**
 * Tests for .anim parser: conditionals, metadata API, and AnimationSM state machine.
 */
class AnimParserTest extends utest.Test {
	// ===== countStateMatch unit tests =====

	@Test
	public function testMatchSingleValue() {
		var condSelector:AnimConditionalSelector = ["direction" => ACVSingle("l")];
		var runtimeState:AnimationStateSelector = ["direction" => "l"];
		Assert.equals(1, AnimParser.countStateMatch(condSelector, runtimeState));
	}

	@Test
	public function testMatchSingleValueMismatch() {
		var condSelector:AnimConditionalSelector = ["direction" => ACVSingle("l")];
		var runtimeState:AnimationStateSelector = ["direction" => "r"];
		Assert.isTrue(AnimParser.countStateMatch(condSelector, runtimeState) < 0);
	}

	@Test
	public function testMatchNegation() {
		var condSelector:AnimConditionalSelector = ["direction" => ACVNot(ACVSingle("l"))];
		var runtimeState:AnimationStateSelector = ["direction" => "r"];
		Assert.equals(1, AnimParser.countStateMatch(condSelector, runtimeState));
	}

	@Test
	public function testMatchNegationFails() {
		var condSelector:AnimConditionalSelector = ["direction" => ACVNot(ACVSingle("l"))];
		var runtimeState:AnimationStateSelector = ["direction" => "l"];
		Assert.isTrue(AnimParser.countStateMatch(condSelector, runtimeState) < 0);
	}

	@Test
	public function testMatchMultiValue() {
		var condSelector:AnimConditionalSelector = ["direction" => ACVMulti(["l", "r"])];
		var runtimeState:AnimationStateSelector = ["direction" => "l"];
		Assert.equals(1, AnimParser.countStateMatch(condSelector, runtimeState));

		runtimeState = ["direction" => "r"];
		Assert.equals(1, AnimParser.countStateMatch(condSelector, runtimeState));
	}

	@Test
	public function testMatchMultiValueMismatch() {
		var condSelector:AnimConditionalSelector = ["direction" => ACVMulti(["l", "r"])];
		var runtimeState:AnimationStateSelector = ["direction" => "u"];
		Assert.isTrue(AnimParser.countStateMatch(condSelector, runtimeState) < 0);
	}

	@Test
	public function testMatchNegatedMultiValue() {
		var condSelector:AnimConditionalSelector = ["direction" => ACVNot(ACVMulti(["l", "r"]))];
		var runtimeState:AnimationStateSelector = ["direction" => "u"];
		Assert.equals(1, AnimParser.countStateMatch(condSelector, runtimeState));

		runtimeState = ["direction" => "l"];
		Assert.isTrue(AnimParser.countStateMatch(condSelector, runtimeState) < 0);
	}

	@Test
	public function testMatchEmptyCondSelector() {
		var condSelector:AnimConditionalSelector = [];
		var runtimeState:AnimationStateSelector = ["direction" => "l"];
		Assert.equals(0, AnimParser.countStateMatch(condSelector, runtimeState));
	}

	@Test
	public function testMatchMultipleConditions() {
		var condSelector:AnimConditionalSelector = [
			"direction" => ACVSingle("l"),
			"color" => ACVSingle("red")
		];
		var runtimeState:AnimationStateSelector = ["direction" => "l", "color" => "red"];
		Assert.equals(2, AnimParser.countStateMatch(condSelector, runtimeState));
	}

	// ===== matchConditionalValue unit tests =====

	@Test
	public function testMatchConditionalValueSingle() {
		Assert.isTrue(AnimParser.matchConditionalValue(ACVSingle("l"), "l"));
		Assert.isFalse(AnimParser.matchConditionalValue(ACVSingle("l"), "r"));
	}

	@Test
	public function testMatchConditionalValueMulti() {
		Assert.isTrue(AnimParser.matchConditionalValue(ACVMulti(["l", "r"]), "l"));
		Assert.isTrue(AnimParser.matchConditionalValue(ACVMulti(["l", "r"]), "r"));
		Assert.isFalse(AnimParser.matchConditionalValue(ACVMulti(["l", "r"]), "u"));
	}

	@Test
	public function testMatchConditionalValueNot() {
		Assert.isTrue(AnimParser.matchConditionalValue(ACVNot(ACVSingle("l")), "r"));
		Assert.isFalse(AnimParser.matchConditionalValue(ACVNot(ACVSingle("l")), "l"));
	}

	@Test
	public function testMatchConditionalValueCompareGte() {
		Assert.isTrue(AnimParser.matchConditionalValue(ACVCompare(ACmpGte, "3"), "3"));
		Assert.isTrue(AnimParser.matchConditionalValue(ACVCompare(ACmpGte, "3"), "5"));
		Assert.isFalse(AnimParser.matchConditionalValue(ACVCompare(ACmpGte, "3"), "2"));
	}

	@Test
	public function testMatchConditionalValueCompareLte() {
		Assert.isTrue(AnimParser.matchConditionalValue(ACVCompare(ACmpLte, "3"), "3"));
		Assert.isTrue(AnimParser.matchConditionalValue(ACVCompare(ACmpLte, "3"), "1"));
		Assert.isFalse(AnimParser.matchConditionalValue(ACVCompare(ACmpLte, "3"), "5"));
	}

	@Test
	public function testMatchConditionalValueCompareGt() {
		Assert.isTrue(AnimParser.matchConditionalValue(ACVCompare(ACmpGt, "3"), "4"));
		Assert.isFalse(AnimParser.matchConditionalValue(ACVCompare(ACmpGt, "3"), "3"));
		Assert.isFalse(AnimParser.matchConditionalValue(ACVCompare(ACmpGt, "3"), "2"));
	}

	@Test
	public function testMatchConditionalValueCompareLt() {
		Assert.isTrue(AnimParser.matchConditionalValue(ACVCompare(ACmpLt, "3"), "2"));
		Assert.isFalse(AnimParser.matchConditionalValue(ACVCompare(ACmpLt, "3"), "3"));
		Assert.isFalse(AnimParser.matchConditionalValue(ACVCompare(ACmpLt, "3"), "4"));
	}

	@Test
	public function testMatchConditionalValueCompareNonNumeric() {
		// Non-numeric values should return false for comparisons
		Assert.isFalse(AnimParser.matchConditionalValue(ACVCompare(ACmpGte, "3"), "abc"));
		Assert.isFalse(AnimParser.matchConditionalValue(ACVCompare(ACmpGte, "abc"), "3"));
	}

	@Test
	public function testMatchConditionalValueRange() {
		Assert.isTrue(AnimParser.matchConditionalValue(ACVRange("1", "5"), "1"));
		Assert.isTrue(AnimParser.matchConditionalValue(ACVRange("1", "5"), "3"));
		Assert.isTrue(AnimParser.matchConditionalValue(ACVRange("1", "5"), "5"));
		Assert.isFalse(AnimParser.matchConditionalValue(ACVRange("1", "5"), "0"));
		Assert.isFalse(AnimParser.matchConditionalValue(ACVRange("1", "5"), "6"));
	}

	@Test
	public function testMatchConditionalValueRangeNonNumeric() {
		Assert.isFalse(AnimParser.matchConditionalValue(ACVRange("1", "5"), "abc"));
	}

	// ===== countStateMatch with Compare/Range =====

	@Test
	public function testMatchCompareInStateSelector() {
		var condSelector:AnimConditionalSelector = ["level" => ACVCompare(ACmpGte, "3")];
		var runtimeState:AnimationStateSelector = ["level" => "5"];
		Assert.equals(1, AnimParser.countStateMatch(condSelector, runtimeState));

		runtimeState = ["level" => "1"];
		Assert.isTrue(AnimParser.countStateMatch(condSelector, runtimeState) < 0);
	}

	@Test
	public function testMatchRangeInStateSelector() {
		var condSelector:AnimConditionalSelector = ["level" => ACVRange("2", "8")];
		var runtimeState:AnimationStateSelector = ["level" => "5"];
		Assert.equals(1, AnimParser.countStateMatch(condSelector, runtimeState));

		runtimeState = ["level" => "10"];
		Assert.isTrue(AnimParser.countStateMatch(condSelector, runtimeState) < 0);
	}

	// ===== .anim parse integration tests =====

	static function parseAnimExpectingSuccess(animSource:String):AnimParserResult {
		try {
			var input = byte.ByteData.ofString(animSource);
			var loader = new bh.base.ResourceLoader.CachingResourceLoader();
			return AnimParser.parseFile(input, "test-input", loader);
		} catch (e:Dynamic) {
			Assert.fail('Unexpected parse error: $e');
			return null;
		}
	}

	static function parseAnimExpectingError(animSource:String):String {
		try {
			var input = byte.ByteData.ofString(animSource);
			var loader = new bh.base.ResourceLoader.CachingResourceLoader();
			AnimParser.parseFile(input, "test-input", loader);
			return null;
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	@Test
	public function testParseBasicConditional() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
states: direction(l, r)
animation @(direction=>l) {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
animation @(direction=>r) {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(result, "Basic @(state=>value) conditional should parse");
		Assert.notNull(result.definedStates);
		Assert.notNull(result.definedStates["direction"]);
		Assert.equals(2, result.definedStates["direction"].length);
	}

	@Test
	public function testParseNotEqualsConditional() {
		// @(direction != l) matches direction=r
		var result = parseAnimExpectingSuccess('
sheet: testSheet
states: direction(l, r)
allowedExtraPoints: [fire]
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
    extrapoints {
        @(direction=>l) fire: -5, -19
        @(direction != l) fire: 5, -19
    }
}
');
		Assert.notNull(result, "@(state != value) negation should parse");
		Assert.notNull(result.definedStates);
		Assert.notNull(result.definedStates["direction"]);
	}

	@Test
	public function testParseMultiValueConditional() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
states: direction(l, r, u, d)
animation @(direction=>[l,r]) {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle_lr"
    }
}
animation @(direction=>[u,d]) {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle_ud"
    }
}
');
		Assert.notNull(result, "@(state=>[v1,v2]) multi-value should parse");
		Assert.notNull(result.definedStates["direction"]);
		Assert.equals(4, result.definedStates["direction"].length);
	}

	@Test
	public function testParseNotEqualsMultiValueConditional() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
states: direction(l, r, u, d)
animation @(direction != [u,d]) {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle_lr"
    }
}
animation @(direction=>[u,d]) {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle_ud"
    }
}
');
		Assert.notNull(result, "@(state != [v1,v2]) negated multi-value should parse");
		Assert.notNull(result.definedStates["direction"]);
	}

	@Test
	public function testParseNotEqualsInMetadata() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
states: direction(l, r)
metadata {
    @(direction=>l) offsetX: -5
    @(direction != l) offsetX: 5
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(result, "@(state != value) should work in metadata");
		Assert.notNull(result.metadata);
		Assert.equals(-5, result.metadata.getIntOrDefault("offsetX", 0, ["direction" => "l"]));
		Assert.equals(5, result.metadata.getIntOrDefault("offsetX", 0, ["direction" => "r"]));
	}

	@Test
	public function testParseInvalidStateInConditional() {
		var error = parseAnimExpectingError('
sheet: testSheet
states: direction(l, r)
animation @(direction=>x) {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(error, "Should throw error for undefined state value 'x'");
		Assert.stringContains("x", error);
	}

	@Test
	public function testParseInvalidStateInMultiValue() {
		var error = parseAnimExpectingError('
sheet: testSheet
states: direction(l, r)
animation @(direction=>[l,x]) {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(error, "Should throw error for undefined state value 'x' in multi-value");
		Assert.stringContains("x", error);
	}

	// ===== Additional .anim parse positive tests =====

	@Test
	public function testParseComparisonConditional() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
states: level(1, 2, 3, 4, 5)
animation @(level >= 3) {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_high"
    }
}
animation @(level < 3) {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_low"
    }
}
');
		Assert.notNull(result, "@(state >= N) comparison should parse");
		Assert.notNull(result.definedStates["level"]);
		Assert.equals(5, result.definedStates["level"].length);
	}

	@Test
	public function testParseRangeConditional() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
states: level(1, 2, 3, 4, 5)
animation @(level => 1..2) {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_low"
    }
}
animation @(level => 3..5) {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_high"
    }
}
');
		Assert.notNull(result, "@(state => 1..5) range should parse");
		Assert.notNull(result.definedStates["level"]);
	}

	@Test
	public function testParseMetadataWithTypes() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
metadata {
    offsetX: 10
    speed: 1.5
    label: "hello"
    tint: #FF0000
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(result, "Metadata with int, float, string, color should parse");
		Assert.notNull(result.metadata);
		Assert.equals(10, result.metadata.getIntOrDefault("offsetX", 0));
		Assert.floatEquals(1.5, result.metadata.getFloatOrDefault("speed", 0.0));
		Assert.equals("hello", result.metadata.getStringOrDefault("label", ""));
	}

	@Test
	public function testParseMetadataWithConditionals() {
		// Parse and verify metadata values are accessible
		var input = byte.ByteData.ofString('
sheet: testSheet
states: direction(l, r)
metadata {
    @(direction=>l) offsetX: -5
    @(direction=>r) offsetX: 5
    speed: 10
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		var loader = new bh.base.ResourceLoader.CachingResourceLoader();
		var result = AnimParser.parseFile(input, "test-input", loader);
		Assert.notNull(result.metadata, "Should have metadata");
		Assert.equals(-5, result.metadata.getIntOrDefault("offsetX", 0, ["direction" => "l"]));
		Assert.equals(5, result.metadata.getIntOrDefault("offsetX", 0, ["direction" => "r"]));
		Assert.equals(10, result.metadata.getIntOrDefault("speed", 0));
	}

	@Test
	public function testParseHeaderName() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation idle {
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(result, "Animation with header name should parse");
		var d:Dynamic = result;
		Assert.equals(1, d.animations.length);
		Assert.equals("idle", d.animations[0].name);
	}

	@Test
	public function testParseCenter() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
center: 32, 48
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(result, "center: x,y should parse");
		var d:Dynamic = result;
		Assert.notNull(d.center);
		Assert.equals(32, d.center.x);
		Assert.equals(48, d.center.y);
	}

	@Test
	public function testParseFileLevelDefaults() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
fps: 10
loop: yes
animation {
    name: idle
    playlist {
        sheet: "test_idle"
    }
}
animation {
    name: walk
    playlist {
        sheet: "test_walk"
    }
}
');
		Assert.notNull(result, "File-level fps/loop defaults should parse");
		var d:Dynamic = result;
		Assert.equals(10, d.defaultFps);
		Assert.equals(-1, d.defaultLoop);
		Assert.equals(2, d.animations.length);
	}

	@Test
	public function testParseLoopCount() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: 3
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(result, "loop: N should parse");
		var d:Dynamic = result;
		Assert.equals(3, d.animations[0].loop);
	}

	@Test
	public function testParsePlaylistFrameRange() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: dodge
    fps: 4
    playlist {
        sheet: "test_dodge" frames: 0..3
    }
}
');
		Assert.notNull(result, "playlist with frames: range should parse");
		var d:Dynamic = result;
		Assert.equals(1, d.animations.length);
		Assert.equals("dodge", d.animations[0].name);
	}

	@Test
	public function testParseEventBare() {
		// Bare event: just "event <name>" (no keyword after name)
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: hit
    fps: 10
    loop: yes
    playlist {
        sheet: "test_hit"
        event hit
    }
}
');
		Assert.notNull(result, "bare event should parse");
		var d:Dynamic = result;
		Assert.equals("hit", d.animations[0].name);
	}

	@Test
	public function testParseEventRandomPoint() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: hit
    fps: 10
    loop: yes
    playlist {
        sheet: "test_hit"
        event hit random 0,-10, 10
    }
}
');
		Assert.notNull(result, "event random with point and radius should parse");
		var d:Dynamic = result;
		Assert.equals("hit", d.animations[0].name);
	}

	@Test
	public function testParseEventPoint() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: fire
    fps: 10
    playlist {
        sheet: "test_fire"
        event fire 5, -10
    }
}
');
		Assert.notNull(result, "event with point should parse");
		var d:Dynamic = result;
		Assert.equals("fire", d.animations[0].name);
	}

	@Test
	public function testParseElseConditionalInExtrapoints() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
states: direction(l, r)
allowedExtraPoints: [fire]
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
    extrapoints {
        @(direction=>l) fire: -5, -19
        @else fire: 5, -19
    }
}
');
		Assert.notNull(result, "@else in extrapoints should parse");
		Assert.notNull(result.definedStates["direction"]);
	}

	@Test
	public function testParseAnimShorthand() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
fps: 10
anim idle(loop: yes): "test_idle"
anim walk: "test_walk"
anim hit(fps: 20, loop: 2): "test_hit"
');
		Assert.notNull(result, "anim shorthand should parse");
		var d:Dynamic = result;
		Assert.equals(3, d.animations.length);
		Assert.equals("idle", d.animations[0].name);
		Assert.equals("walk", d.animations[1].name);
		Assert.equals("hit", d.animations[2].name);
	}

	@Test
	public function testParseFinalConstants() {
		var result = parseAnimExpectingSuccess("
sheet: testSheet
@final OFFSET_X = 5
@final OFFSET_Y = -10
allowedExtraPoints: [fire]
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: \"test_idle\"
    }
    extrapoints {
        fire: $OFFSET_X, $OFFSET_Y
    }
}
");
		Assert.notNull(result, "@final constants should parse");
		var d:Dynamic = result;
		Assert.floatEquals(5.0, d.constants.get("OFFSET_X"));
		Assert.floatEquals(-10.0, d.constants.get("OFFSET_Y"));
	}

	@Test
	public function testParseStateInterpolation() {
		var result = parseAnimExpectingSuccess("
sheet: testSheet
states: direction(l, r)
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: \"test_${direction}_idle\"
    }
}
");
		Assert.notNull(result, "state interpolation in sheet names should parse");
		Assert.notNull(result.definedStates["direction"]);
		var d:Dynamic = result;
		Assert.equals(1, d.animations.length);
		Assert.equals("idle", d.animations[0].name);
	}

	// ===== Additional .anim parse negative tests =====

	@Test
	public function testParseEmptyAnimation() {
		var error = parseAnimExpectingError('
sheet: testSheet
animation {
}
');
		Assert.notNull(error, "Should error when animation body has no name/playlist");
		Assert.stringContains("name", error);
	}

	@Test
	public function testParseMissingFps() {
		var error = parseAnimExpectingError('
sheet: testSheet
animation {
    name: idle
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(error, "Should error when fps is not set anywhere");
		Assert.stringContains("fps", error);
	}

	@Test
	public function testParseMissingPlaylist() {
		var error = parseAnimExpectingError('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: yes
}
');
		Assert.notNull(error, "Should error when playlist is missing");
		Assert.stringContains("playlist", error);
	}

	@Test
	public function testParseMissingAnimName() {
		var error = parseAnimExpectingError('
sheet: testSheet
animation {
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(error, "Should error when animation name is missing");
		Assert.stringContains("name", error);
	}

	@Test
	public function testParseDuplicateSheet() {
		var error = parseAnimExpectingError('
sheet: testSheet
sheet: testSheet2
animation {
    name: idle
    fps: 4
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(error, "Should error on duplicate sheet declaration");
		Assert.stringContains("sheet", error);
	}

	@Test
	public function testParseDuplicateStates() {
		var error = parseAnimExpectingError('
sheet: testSheet
states: direction(l, r)
states: color(red, blue)
animation {
    name: idle
    fps: 4
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(error, "Should error on duplicate states declaration");
		Assert.stringContains("states", error);
	}

	@Test
	public function testParseExtraPointNotDeclared() {
		var error = parseAnimExpectingError('
sheet: testSheet
allowedExtraPoints: [fire]
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
    extrapoints {
        missile: 5, -10
    }
}
');
		Assert.notNull(error, "Should error when extra point is not in allowedExtraPoints");
		Assert.stringContains("missile", error);
	}

	@Test
	public function testParseInvalidFps() {
		var error = parseAnimExpectingError('
sheet: testSheet
animation {
    name: idle
    fps: 0
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(error, "Should error when fps is 0");
		Assert.stringContains("fps", error);
	}

	@Test
	public function testParseInvalidLoopCount() {
		var error = parseAnimExpectingError('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: 0
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(error, "Should error when loop count is 0");
		Assert.stringContains("loop", error);
	}

	@Test
	public function testParseUndeclaredState() {
		var error = parseAnimExpectingError('
sheet: testSheet
states: direction(l, r)
animation @(color=>red) {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(error, "Should error on undeclared state name");
		Assert.stringContains("color", error);
	}

	@Test
	public function testParseDuplicateFinalConstant() {
		var error = parseAnimExpectingError('
sheet: testSheet
@final X = 5
@final X = 10
animation {
    name: idle
    fps: 4
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.notNull(error, "Should error on duplicate @final constant");
		Assert.stringContains("X", error);
	}

	@Test
	public function testParseUndefinedConstantRef() {
		var error = parseAnimExpectingError("
sheet: testSheet
allowedExtraPoints: [fire]
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: \"test_idle\"
    }
    extrapoints {
        fire: $UNDEFINED, 0
    }
}
");
		Assert.notNull(error, "Should error on undefined $constant reference");
		Assert.stringContains("UNDEFINED", error);
	}

	@Test
	public function testParseSheetAfterAnimation() {
		var error = parseAnimExpectingError('
sheet: testSheet
animation {
    name: idle
    fps: 4
    playlist {
        sheet: "test_idle"
    }
}
sheet: anotherSheet
');
		Assert.notNull(error, "Should error when sheet: appears after animation");
		Assert.stringContains("sheet", error);
	}

	// ===== AnimMetadata API tests =====

	static function parseAnimWithMetadata(animSource:String):AnimMetadata {
		var input = byte.ByteData.ofString(animSource);
		var loader = new bh.base.ResourceLoader.CachingResourceLoader();
		var result = AnimParser.parseFile(input, "test-input", loader);
		Assert.notNull(result.metadata, "Should have metadata");
		return result.metadata;
	}

	@Test
	public function testMetadataGetIntOrDefault() {
		var meta = parseAnimWithMetadata('
sheet: testSheet
metadata {
    health: 100
    speed: 5
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.equals(100, meta.getIntOrDefault("health", 0));
		Assert.equals(5, meta.getIntOrDefault("speed", 0));
		Assert.equals(42, meta.getIntOrDefault("missing", 42));
	}

	@Test
	public function testMetadataGetIntOrException() {
		var meta = parseAnimWithMetadata('
sheet: testSheet
metadata {
    health: 100
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.equals(100, meta.getIntOrException("health"));
		var threw = false;
		try {
			meta.getIntOrException("missing");
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "getIntOrException should throw for missing key");
	}

	@Test
	public function testMetadataGetIntWithStateSelector() {
		var meta = parseAnimWithMetadata('
sheet: testSheet
states: direction(l, r)
metadata {
    @(direction=>l) offsetX: -5
    @(direction=>r) offsetX: 5
    health: 100
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.equals(-5, meta.getIntOrDefault("offsetX", 0, ["direction" => "l"]));
		Assert.equals(5, meta.getIntOrDefault("offsetX", 0, ["direction" => "r"]));
		// Without selector, should still find unconditional entry
		Assert.equals(100, meta.getIntOrDefault("health", 0));
		Assert.equals(100, meta.getIntOrDefault("health", 0, ["direction" => "l"]));
	}

	@Test
	public function testMetadataGetFloatOrDefault() {
		var meta = parseAnimWithMetadata('
sheet: testSheet
metadata {
    speed: 1.5
    intVal: 10
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.floatEquals(1.5, meta.getFloatOrDefault("speed", 0.0));
		// Int should be returned as float
		Assert.floatEquals(10.0, meta.getFloatOrDefault("intVal", 0.0));
		Assert.floatEquals(3.14, meta.getFloatOrDefault("missing", 3.14));
	}

	@Test
	public function testMetadataGetFloatOrException() {
		var meta = parseAnimWithMetadata('
sheet: testSheet
metadata {
    speed: 2.5
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.floatEquals(2.5, meta.getFloatOrException("speed"));
		var threw = false;
		try {
			meta.getFloatOrException("missing");
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "getFloatOrException should throw for missing key");
	}

	@Test
	public function testMetadataGetStringOrDefault() {
		var meta = parseAnimWithMetadata('
sheet: testSheet
metadata {
    label: "hello"
    count: 42
    rate: 1.5
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.equals("hello", meta.getStringOrDefault("label", ""));
		// Int/Float should be convertible to string
		Assert.equals("42", meta.getStringOrDefault("count", ""));
		Assert.equals("1.5", meta.getStringOrDefault("rate", ""));
		Assert.equals("default", meta.getStringOrDefault("missing", "default"));
	}

	@Test
	public function testMetadataGetStringOrException() {
		var meta = parseAnimWithMetadata('
sheet: testSheet
metadata {
    label: "world"
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.equals("world", meta.getStringOrException("label"));
		var threw = false;
		try {
			meta.getStringOrException("missing");
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "getStringOrException should throw for missing key");
	}

	@Test
	public function testMetadataGetStringWithStateSelector() {
		var meta = parseAnimWithMetadata('
sheet: testSheet
states: direction(l, r)
metadata {
    @(direction=>l) facing: "left"
    @(direction=>r) facing: "right"
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.equals("left", meta.getStringOrDefault("facing", "", ["direction" => "l"]));
		Assert.equals("right", meta.getStringOrDefault("facing", "", ["direction" => "r"]));
	}

	@Test
	public function testMetadataGetColorOrDefault() {
		var meta = parseAnimWithMetadata('
sheet: testSheet
metadata {
    tint: #FF0000
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.equals(0xFF0000, meta.getColorOrDefault("tint", 0));
		Assert.equals(0xFFFFFF, meta.getColorOrDefault("missing", 0xFFFFFF));
	}

	@Test
	public function testMetadataGetColorOrException() {
		var meta = parseAnimWithMetadata('
sheet: testSheet
metadata {
    tint: #00FF00
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		Assert.equals(0x00FF00, meta.getColorOrException("tint"));
		var threw = false;
		try {
			meta.getColorOrException("missing");
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "getColorOrException should throw for missing key");
	}

	@Test
	public function testMetadataTypeMismatchIntFromString() {
		var meta = parseAnimWithMetadata('
sheet: testSheet
metadata {
    label: "hello"
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		var threw = false;
		try {
			meta.getIntOrDefault("label", 0);
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "getIntOrDefault should throw for string value");
	}

	@Test
	public function testMetadataTypeMismatchColorFromString() {
		var meta = parseAnimWithMetadata('
sheet: testSheet
metadata {
    label: "hello"
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		var threw = false;
		try {
			meta.getColorOrDefault("label", 0);
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "getColorOrDefault should throw for string value");
	}

	@Test
	public function testMetadataBestMatchPriority() {
		// More specific state match should win over less specific
		var meta = parseAnimWithMetadata('
sheet: testSheet
states: direction(l, r), color(red, blue)
metadata {
    score: 1
    @(direction=>l) score: 10
    @(direction=>l) @(color=>red) score: 100
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		// Two-state match should win over single-state match
		Assert.equals(100, meta.getIntOrDefault("score", 0, ["direction" => "l", "color" => "red"]));
		// Single-state match should win over unconditional
		Assert.equals(10, meta.getIntOrDefault("score", 0, ["direction" => "l", "color" => "blue"]));
	}

	@Test
	public function testMetadataNullSelector() {
		var meta = parseAnimWithMetadata('
sheet: testSheet
metadata {
    health: 100
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		// Null state selector should match unconditional entries
		Assert.equals(100, meta.getIntOrDefault("health", 0, null));
	}

	// ===== AnimationSM unit tests =====

	@Test
	public function testAnimSMAddAndPlay() {
		var sm = new bh.stateanim.AnimationSM([]);
		var dummyTile = h2d.Tile.fromColor(0xFF0000, 8, 8);
		var frame = new bh.stateanim.AnimationFrame(dummyTile, 0.1, 0, 0, 8, 8);
		sm.addAnimationState("idle", [Frame(frame)], -1, []);
		sm.play("idle");
		Assert.equals("idle", sm.getCurrentAnimName());
	}

	@Test
	public function testAnimSMPlayUnknownThrows() {
		var sm = new bh.stateanim.AnimationSM([]);
		var threw = false;
		try {
			sm.play("nonexistent");
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "play() should throw for unknown animation");
	}

	@Test
	public function testAnimSMDuplicateStateThrows() {
		var sm = new bh.stateanim.AnimationSM([]);
		var dummyTile = h2d.Tile.fromColor(0xFF0000, 8, 8);
		var frame = new bh.stateanim.AnimationFrame(dummyTile, 0.1, 0, 0, 8, 8);
		sm.addAnimationState("idle", [Frame(frame)], -1, []);
		var threw = false;
		try {
			sm.addAnimationState("idle", [Frame(frame)], -1, []);
		} catch (e:Dynamic) {
			threw = true;
		}
		Assert.isTrue(threw, "addAnimationState should throw on duplicate name");
	}

	@Test
	public function testAnimSMIsFinishedNoLoop() {
		var sm = new bh.stateanim.AnimationSM([], true);
		var dummyTile = h2d.Tile.fromColor(0xFF0000, 8, 8);
		var frame = new bh.stateanim.AnimationFrame(dummyTile, 0.1, 0, 0, 8, 8);
		sm.addAnimationState("once", [Frame(frame)], 0, []);
		sm.play("once");
		Assert.isFalse(sm.isFinished());
		sm.update(0.2); // advance past frame duration
		Assert.isTrue(sm.isFinished());
	}

	@Test
	public function testAnimSMIsFinishedInfiniteLoop() {
		var sm = new bh.stateanim.AnimationSM([], true);
		var dummyTile = h2d.Tile.fromColor(0xFF0000, 8, 8);
		var frame = new bh.stateanim.AnimationFrame(dummyTile, 0.1, 0, 0, 8, 8);
		sm.addAnimationState("loop", [Frame(frame)], -1, []);
		sm.play("loop");
		sm.update(1.0);
		Assert.isFalse(sm.isFinished());
	}

	@Test
	public function testAnimSMFinishedCallback() {
		var sm = new bh.stateanim.AnimationSM([], true);
		var dummyTile = h2d.Tile.fromColor(0xFF0000, 8, 8);
		var frame = new bh.stateanim.AnimationFrame(dummyTile, 0.1, 0, 0, 8, 8);
		sm.addAnimationState("once", [Frame(frame)], 0, []);
		var finished = false;
		sm.onFinished = function() { finished = true; };
		sm.play("once");
		sm.update(0.2);
		Assert.isTrue(finished, "onFinished should fire when animation ends");
	}

	@Test
	public function testAnimSMEventCallback() {
		var sm = new bh.stateanim.AnimationSM([], true);
		var dummyTile = h2d.Tile.fromColor(0xFF0000, 8, 8);
		var frame = new bh.stateanim.AnimationFrame(dummyTile, 0.1, 0, 0, 8, 8);
		var events:Array<bh.stateanim.AnimationSM.AnimationEvent> = [];
		sm.onAnimationEvent = function(e) { events.push(e); };
		sm.addAnimationState("fire", [
			Frame(frame),
			Event(Trigger("hit")),
			Frame(frame)
		], 0, []);
		sm.play("fire");
		sm.update(0.15); // past first frame, trigger event
		Assert.equals(1, events.length);
		switch events[0] {
			case Trigger(data): Assert.equals("hit", data);
			default: Assert.fail("Expected Trigger event");
		}
	}

	@Test
	public function testAnimSMPaused() {
		var sm = new bh.stateanim.AnimationSM([], true);
		var dummyTile = h2d.Tile.fromColor(0xFF0000, 8, 8);
		var frame = new bh.stateanim.AnimationFrame(dummyTile, 0.5, 0, 0, 8, 8);
		sm.addAnimationState("idle", [Frame(frame)], 0, []);
		sm.play("idle");
		sm.paused = true;
		sm.update(1.0);
		Assert.isFalse(sm.isFinished(), "Paused animation should not advance");
	}

	@Test
	public function testAnimSMGetExtraPoint() {
		var sm = new bh.stateanim.AnimationSM([], true);
		var dummyTile = h2d.Tile.fromColor(0xFF0000, 8, 8);
		var frame = new bh.stateanim.AnimationFrame(dummyTile, 0.1, 0, 0, 8, 8);
		var extraPts:Map<String, h2d.col.IPoint> = ["fire" => new h2d.col.IPoint(5, -10)];
		sm.addAnimationState("idle", [Frame(frame)], -1, extraPts);
		sm.play("idle");
		var pt = sm.getExtraPoint("fire");
		Assert.notNull(pt);
		Assert.equals(5, pt.x);
		Assert.equals(-10, pt.y);
		Assert.isNull(sm.getExtraPoint("nonexistent"));
	}

	@Test
	public function testAnimSMLoopCount() {
		var sm = new bh.stateanim.AnimationSM([], true);
		var dummyTile = h2d.Tile.fromColor(0xFF0000, 8, 8);
		var frame = new bh.stateanim.AnimationFrame(dummyTile, 0.1, 0, 0, 8, 8);
		sm.addAnimationState("blink", [Frame(frame)], 2, []);
		sm.play("blink");
		Assert.isFalse(sm.isFinished());
		sm.update(0.15); // loop 1
		Assert.isFalse(sm.isFinished());
		sm.update(0.1); // loop 2
		Assert.isFalse(sm.isFinished());
		sm.update(0.1); // done
		Assert.isTrue(sm.isFinished());
	}

	@Test
	public function testAnimSMNoCurrentAnim() {
		var sm = new bh.stateanim.AnimationSM([]);
		Assert.isNull(sm.getCurrentAnimName());
		Assert.isTrue(sm.isFinished());
	}

	@Test
	public function testAnimSMGetExtraPointNames() {
		var sm = new bh.stateanim.AnimationSM([], true);
		var dummyTile = h2d.Tile.fromColor(0xFF0000, 8, 8);
		var frame = new bh.stateanim.AnimationFrame(dummyTile, 0.1, 0, 0, 8, 8);
		var extraPts:Map<String, h2d.col.IPoint> = [
			"fire" => new h2d.col.IPoint(5, -10),
			"targeting" => new h2d.col.IPoint(0, -12)
		];
		sm.addAnimationState("idle", [Frame(frame)], -1, extraPts);
		sm.play("idle");
		var names = sm.getExtraPointNames();
		Assert.equals(2, names.length);
		Assert.isTrue(names.contains("fire"));
		Assert.isTrue(names.contains("targeting"));
	}

	@Test
	public function testAnimSMPointEvent() {
		var sm = new bh.stateanim.AnimationSM([], true);
		var dummyTile = h2d.Tile.fromColor(0xFF0000, 8, 8);
		var frame = new bh.stateanim.AnimationFrame(dummyTile, 0.1, 0, 0, 8, 8);
		var events:Array<bh.stateanim.AnimationSM.AnimationEvent> = [];
		sm.onAnimationEvent = function(e) { events.push(e); };
		sm.addAnimationState("fire", [
			Frame(frame),
			Event(PointEvent("muzzle", new h2d.col.IPoint(10, -5)))
		], 0, []);
		sm.play("fire");
		sm.update(0.15);
		Assert.equals(1, events.length);
		switch events[0] {
			case PointEvent(name, pt):
				Assert.equals("muzzle", name);
				Assert.equals(10, pt.x);
				Assert.equals(-5, pt.y);
			default: Assert.fail("Expected PointEvent");
		}
	}

	@Test
	public function testAnimSMRandomPointEvent() {
		var sm = new bh.stateanim.AnimationSM([], true);
		sm.randomFunc = function() { return 0.5; }; // deterministic
		var dummyTile = h2d.Tile.fromColor(0xFF0000, 8, 8);
		var frame = new bh.stateanim.AnimationFrame(dummyTile, 0.1, 0, 0, 8, 8);
		var events:Array<bh.stateanim.AnimationSM.AnimationEvent> = [];
		sm.onAnimationEvent = function(e) { events.push(e); };
		sm.addAnimationState("hit", [
			Frame(frame),
			Event(RandomPointEvent("spark", new h2d.col.IPoint(0, 0), 10.0))
		], 0, []);
		sm.play("hit");
		sm.update(0.15);
		Assert.equals(1, events.length);
		switch events[0] {
			case PointEvent(name, pt):
				Assert.equals("spark", name);
				// With random=0.5: angle=PI, radius=5 => x=~-5, y=~0
				Assert.isTrue(pt != null);
			default: Assert.fail("Expected PointEvent from random");
		}
	}

	// ===== Full integration: parse .anim and create AnimSM =====

	@Test
	public function testParseMetadataConditionalFullExample() {
		var input = byte.ByteData.ofString('
sheet: testSheet
states: direction(l, r)
metadata {
    @(direction=>l) offsetX: -5
    @(direction=>r) offsetX: 5
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		var loader = new bh.base.ResourceLoader.CachingResourceLoader();
		var result = AnimParser.parseFile(input, "test-input", loader);
		Assert.notNull(result.definedStates);
		Assert.notNull(result.definedStates["direction"]);
		Assert.equals(2, result.definedStates["direction"].length);
		Assert.notNull(result.metadata);
		Assert.equals(-5, result.metadata.getIntOrDefault("offsetX", 0, ["direction" => "l"]));
		Assert.equals(5, result.metadata.getIntOrDefault("offsetX", 0, ["direction" => "r"]));
	}

	// ===== AnimMetadata state-selector API (additional coverage) =====

	@Test
	public function testMetadataGetFloatWithStateSelector() {
		// Existing tests cover float without state selector; this tests float WITH state
		var input = byte.ByteData.ofString('
sheet: testSheet
states: size(small, large)
metadata {
    @(size=>small) scale: 0.5
    @(size=>large) scale: 2.0
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		var loader = new bh.base.ResourceLoader.CachingResourceLoader();
		var result = AnimParser.parseFile(input, "test-input", loader);
		var meta = result.metadata;
		Assert.notNull(meta);
		Assert.floatEquals(0.5, meta.getFloatOrDefault("scale", 1.0, ["size" => "small"]));
		Assert.floatEquals(2.0, meta.getFloatOrDefault("scale", 1.0, ["size" => "large"]));
		Assert.floatEquals(1.0, meta.getFloatOrDefault("missing", 1.0));
	}

	@Test
	public function testMetadataGetColorWithStateSelector() {
		// Existing testMetadataGetColorOrDefault tests color without state; this tests WITH state
		var input = byte.ByteData.ofString('
sheet: testSheet
states: type(fire, ice)
metadata {
    @(type=>fire) tint: #FF0000
    @(type=>ice) tint: #0000FF
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		var loader = new bh.base.ResourceLoader.CachingResourceLoader();
		var result = AnimParser.parseFile(input, "test-input", loader);
		var meta = result.metadata;
		Assert.notNull(meta);
		Assert.equals(0xFF0000, meta.getColorOrDefault("tint", 0, ["type" => "fire"]));
		Assert.equals(0x0000FF, meta.getColorOrDefault("tint", 0, ["type" => "ice"]));
		Assert.equals(0xFFFFFF, meta.getColorOrDefault("missing", 0xFFFFFF));
	}

	@Test
	public function testMetadataExceptionMessageContent() {
		// Existing testMetadataGetIntOrException checks throws but not message content
		var input = byte.ByteData.ofString('
sheet: testSheet
metadata {
    damage: 50
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		var loader = new bh.base.ResourceLoader.CachingResourceLoader();
		var result = AnimParser.parseFile(input, "test-input", loader);
		var meta = result.metadata;
		Assert.notNull(meta);
		Assert.equals(50, meta.getIntOrException("damage"));
		var threw = false;
		try {
			meta.getIntOrException("missing");
		} catch (e:Dynamic) {
			threw = true;
			Assert.stringContains("missing", Std.string(e));
		}
		Assert.isTrue(threw, "getIntOrException should throw for missing key");
	}

	// ===== .anim filter parsing tests (#12) =====

	@Test
	public function testFilterTint() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        tint: #FF0000
    }
}
');
		Assert.notNull(result, "tint filter should parse");
		var d:Dynamic = result;
		Assert.notNull(d.animations[0].filters);
		Assert.equals(1, d.animations[0].filters.length);
	}

	@Test
	public function testFilterBrightness() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        brightness: 0.8
    }
}
');
		Assert.notNull(result, "brightness filter should parse");
		var d:Dynamic = result;
		Assert.notNull(d.animations[0].filters);
		Assert.equals(1, d.animations[0].filters.length);
	}

	@Test
	public function testFilterSaturate() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        saturate: 0.5
    }
}
');
		Assert.notNull(result, "saturate filter should parse");
		var d:Dynamic = result;
		Assert.notNull(d.animations[0].filters);
		Assert.equals(1, d.animations[0].filters.length);
	}

	@Test
	public function testFilterGrayscale() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        grayscale: 1.0
    }
}
');
		Assert.notNull(result, "grayscale filter should parse");
		var d:Dynamic = result;
		Assert.notNull(d.animations[0].filters);
		Assert.equals(1, d.animations[0].filters.length);
	}

	@Test
	public function testFilterHue() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        hue: 90.0
    }
}
');
		Assert.notNull(result, "hue filter should parse");
		var d:Dynamic = result;
		Assert.notNull(d.animations[0].filters);
		Assert.equals(1, d.animations[0].filters.length);
	}

	@Test
	public function testFilterOutline() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        outline: 2.0, #FFFF00
    }
}
');
		Assert.notNull(result, "outline filter should parse");
		var d:Dynamic = result;
		Assert.notNull(d.animations[0].filters);
		Assert.equals(1, d.animations[0].filters.length);
	}

	@Test
	public function testFilterPixelOutline() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        pixelOutline: #00FF00
    }
}
');
		Assert.notNull(result, "pixelOutline filter should parse");
		var d:Dynamic = result;
		Assert.notNull(d.animations[0].filters);
		Assert.equals(1, d.animations[0].filters.length);
	}

	@Test
	public function testFilterReplaceColor() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        replaceColor: [#FF0000, #00FF00] => [#0000FF, #FFFF00]
    }
}
');
		Assert.notNull(result, "replaceColor filter should parse");
		var d:Dynamic = result;
		Assert.notNull(d.animations[0].filters);
		Assert.equals(1, d.animations[0].filters.length);
	}

	@Test
	public function testFilterMultiple() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        tint: #FF4444
        brightness: 0.8
        outline: 1.0, #FFFFFF
    }
}
');
		Assert.notNull(result, "multiple filters should parse");
		var d:Dynamic = result;
		Assert.notNull(d.animations[0].filters);
		Assert.equals(3, d.animations[0].filters.length);
	}

	@Test
	public function testFilterWithConditionals() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
states: level(1, 2, 3, 4, 5)
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        @(level >= 3) outline: 2.0, #FFFF00
        @else pixelOutline: #00FF00
        tint: #FF0000
    }
}
');
		Assert.notNull(result, "filters with state conditionals should parse");
		var d:Dynamic = result;
		Assert.notNull(d.animations[0].filters);
		Assert.equals(3, d.animations[0].filters.length);
	}

	@Test
	public function testFilterWithDefault() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
states: team(red, blue)
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        @(team=>red) tint: #FF0000
        @(team=>blue) tint: #0000FF
        @default tint: #FFFFFF
    }
}
');
		Assert.notNull(result, "filters with @default should parse");
		var d:Dynamic = result;
		Assert.notNull(d.animations[0].filters);
		Assert.equals(3, d.animations[0].filters.length);
	}

	@Test
	public function testFilterNone() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        none
    }
}
');
		Assert.notNull(result, "filter none should parse");
		var d:Dynamic = result;
		Assert.notNull(d.animations[0].filters);
		Assert.equals(1, d.animations[0].filters.length);
	}

	@Test
	public function testPlaylistFilter() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: hit
    fps: 10
    playlist {
        sheet: "test_hit_01"
        filter tint: #FF0000
        sheet: "test_hit_02"
        filter none
        sheet: "test_hit_03"
    }
}
');
		Assert.notNull(result, "playlist filter entries should parse");
		var d:Dynamic = result;
		Assert.equals("hit", d.animations[0].name);
	}

	@Test
	public function testPlaylistFilterMultiple() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: hit
    fps: 10
    playlist {
        filter tint: #FF0000
        filter outline: 1.0, #FFFFFF
        sheet: "test_hit_01"
        filter none
        sheet: "test_hit_02"
    }
}
');
		Assert.notNull(result, "multiple playlist filter entries should parse");
		var d:Dynamic = result;
		Assert.equals("hit", d.animations[0].name);
	}

	@Test
	public function testFilterUnknownType() {
		var error = parseAnimExpectingError('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        blur: 5.0
    }
}
');
		Assert.notNull(error, "unknown filter type should fail");
		Assert.stringContains("blur", error);
	}

	@Test
	public function testFilterOutlineMissingColor() {
		var error = parseAnimExpectingError('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        outline: 1.0
    }
}
');
		Assert.notNull(error, "outline missing color should fail");
		Assert.stringContains("expected", error);
	}

	@Test
	public function testFilterReplaceColorMismatchLength() {
		var error = parseAnimExpectingError('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        replaceColor: [#FF0000, #00FF00] => [#0000FF]
    }
}
');
		Assert.notNull(error, "replaceColor length mismatch should fail");
		Assert.stringContains("replaceColor", error);
	}

	@Test
	public function testFilterNegativeFloat() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: idle
    fps: 4
    loop: yes
    playlist { sheet: "test_idle" }
    filters {
        brightness: -0.5
    }
}
');
		Assert.notNull(result, "negative float in filter should parse");
		var d:Dynamic = result;
		Assert.notNull(d.animations[0].filters);
		Assert.equals(1, d.animations[0].filters.length);
	}

	// ===== @default conditional tests =====

	@Test
	public function testDefaultConditionalInExtrapoints() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
states: direction(l, r, u, d)
allowedExtraPoints: [fire]
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
    extrapoints {
        @(direction=>l) fire: -5, -19
        @(direction=>r) fire: 5, -19
        @default fire: 0, -19
    }
}
');
		Assert.notNull(result, "@default in extrapoints should parse");
		Assert.notNull(result.definedStates["direction"]);
		Assert.equals(4, result.definedStates["direction"].length);
	}

	@Test
	public function testDefaultConditionalInMetadata() {
		var input = byte.ByteData.ofString('
sheet: testSheet
states: team(red, blue, green)
metadata {
    @(team=>red) tint: #FF0000
    @(team=>blue) tint: #0000FF
    @default tint: #FFFFFF
    speed: 10
}
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
}
');
		var loader = new bh.base.ResourceLoader.CachingResourceLoader();
		var result = AnimParser.parseFile(input, "test-input", loader);
		Assert.notNull(result.metadata, "Should have metadata");
		Assert.equals(0xFF0000, result.metadata.getColorOrDefault("tint", 0, ["team" => "red"]));
		Assert.equals(0x0000FF, result.metadata.getColorOrDefault("tint", 0, ["team" => "blue"]));
		Assert.equals(0xFFFFFF, result.metadata.getColorOrDefault("tint", 0, ["team" => "green"]));
		Assert.equals(10, result.metadata.getIntOrDefault("speed", 0));
	}

	@Test
	public function testDefaultConditionalInPlaylist() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
states: team(red, blue, green)
animation {
    name: idle
    fps: 4
    loop: yes
    playlist @(team=>red) {
        sheet: "test_idle_red"
    }
    playlist @default {
        sheet: "test_idle_default"
    }
}
');
		Assert.notNull(result, "@default in playlist should parse");
		var d:Dynamic = result;
		Assert.equals(1, d.animations.length);
	}

	@Test
	public function testElseAndDefaultCombined() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
states: level(1, 2, 3, 4, 5)
allowedExtraPoints: [fire]
animation {
    name: idle
    fps: 4
    loop: yes
    playlist {
        sheet: "test_idle"
    }
    extrapoints {
        @(level=>1) fire: -5, -19
        @else(level=>2) fire: 5, -19
        @default fire: 0, -10
    }
}
');
		Assert.notNull(result, "@else and @default combined in extrapoints should parse");
		Assert.equals(5, result.definedStates["level"].length);
	}

	// ===== Typed event metadata tests =====

	@Test
	public function testEventMetadataTrigger() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: hit
    fps: 10
    playlist {
        sheet: "test_hit"
        event impact { damage:int => 5, element => "fire" }
    }
}
');
		Assert.notNull(result, "trigger event with typed metadata should parse");
		var d:Dynamic = result;
		Assert.equals("hit", d.animations[0].name);
	}

	@Test
	public function testEventMetadataPoint() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: hit
    fps: 10
    playlist {
        sheet: "test_hit"
        event spark 10, -5 { intensity:float => 0.8, color => "red" }
    }
}
');
		Assert.notNull(result, "point event with typed metadata should parse");
		var d:Dynamic = result;
		Assert.equals("hit", d.animations[0].name);
	}

	@Test
	public function testEventMetadataAllTypes() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: hit
    fps: 10
    playlist {
        sheet: "test_hit"
        event hit { damage:int => 42, speed:float => 1.5, label => "crit", tint => #FF0000, active => true }
    }
}
');
		Assert.notNull(result, "event metadata with int, float, string, color, bool types should parse");
		var d:Dynamic = result;
		Assert.equals("hit", d.animations[0].name);
	}

	@Test
	public function testEventMetadataRandomPoint() {
		var result = parseAnimExpectingSuccess('
sheet: testSheet
animation {
    name: explode
    fps: 10
    playlist {
        sheet: "test_explode"
        event debris random 0, 0, 50 { count:int => 3, size:float => 0.5 }
    }
}
');
		Assert.notNull(result, "random point event with metadata should parse");
		var d:Dynamic = result;
		Assert.equals("explode", d.animations[0].name);
	}

	// ===== Playlist reachability validation (bug 1.1) =====

	@Test
	public function testUnreachablePlaylistWithNoExtraPointsDetected() {
		// Bug: playlist validation is nested inside the extraPoint loop.
		// When an animation has 0 extra points, the playlist validation is
		// skipped entirely. This test has an unreachable playlist @(direction=>up)
		// but no extra points — should still be caught.
		var error = parseAnimExpectingError('
sheet: testSheet
states: direction(l, r)
animation {
    name: idle
    fps: 4
    loop: yes
    playlist @(direction=>l) {
        sheet: "test_idle_l"
    }
    playlist @(direction=>r) {
        sheet: "test_idle_r"
    }
    playlist @(direction=>up) {
        sheet: "test_idle_up"
    }
}
');
		Assert.notNull(error, "Unreachable playlist with no extra points should be detected");
	}

	@Test
	public function testReachablePlaylistWithNoExtraPointsStillPasses() {
		// Verify that the fix doesn't break valid animations with no extra points.
		var result = parseAnimExpectingSuccess('
sheet: testSheet
states: direction(l, r)
animation {
    name: idle
    fps: 4
    loop: yes
    playlist @(direction=>l) {
        sheet: "test_idle_l"
    }
    playlist @(direction=>r) {
        sheet: "test_idle_r"
    }
}
');
		Assert.notNull(result, "Valid animation with no extra points should parse");
	}
}
