package bh.test.examples;

import utest.Assert;
import bh.stateanim.AnimParser;

/**
 * Tests for .anim parser conditional features: negation (!=) and multi-value ([v1,v2]).
 * Also tests countStateMatch logic with AnimConditionalValue types.
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

	// ===== .anim parse integration tests =====

	static function parseAnimExpectingSuccess(animSource:String):Bool {
		try {
			var input = byte.ByteData.ofString(animSource);
			var loader = new bh.base.ResourceLoader.CachingResourceLoader();
			AnimParser.parseFile(input, "test-input", loader);
			return true;
		} catch (e:Dynamic) {
			trace('Unexpected parse error: $e');
			return false;
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
		var success = parseAnimExpectingSuccess('
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
		Assert.isTrue(success, "Basic @(state=>value) conditional should parse");
	}

	@Test
	public function testParseNotEqualsConditional() {
		// @(direction != l) matches direction=r
		var success = parseAnimExpectingSuccess('
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
		Assert.isTrue(success, "@(state != value) negation should parse");
	}

	@Test
	public function testParseMultiValueConditional() {
		var success = parseAnimExpectingSuccess('
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
		Assert.isTrue(success, "@(state=>[v1,v2]) multi-value should parse");
	}

	@Test
	public function testParseNotEqualsMultiValueConditional() {
		var success = parseAnimExpectingSuccess('
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
		Assert.isTrue(success, "@(state != [v1,v2]) negated multi-value should parse");
	}

	@Test
	public function testParseNotEqualsInMetadata() {
		var success = parseAnimExpectingSuccess('
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
		Assert.isTrue(success, "@(state != value) should work in metadata");
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
	}
}
