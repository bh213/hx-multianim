package bh.test.examples;

import utest.Assert;
import bh.multianim.MultiAnimParser;

/**
 * Non-visual tests that parse invalid .manim files and assert on parser errors.
 * These tests verify that the parser produces clear error messages for invalid syntax.
 */
class ParserErrorTest extends utest.Test {
	/**
	 * Helper: parse a .manim string and expect it to throw.
	 * Returns the error message string, or null if no error was thrown.
	 */
	static function parseExpectingError(manimSource:String):String {
		return doParse(manimSource, true);
	}

	/**
	 * Helper: parse raw .manim string without version header and expect it to throw.
	 */
	static function parseRawExpectingError(manimSource:String):String {
		return doParse(manimSource, false);
	}

	static function doParse(manimSource:String, addVersion:Bool):String {
		try {
			var source = addVersion ? 'version: 0.3\n$manimSource' : manimSource;
			var input = byte.ByteData.ofString(source);
			var loader = new bh.base.ResourceLoader.CachingResourceLoader();
			MultiAnimParser.parseFile(input, "test-input", loader);
			return null; // No error thrown
		} catch (e:InvalidSyntax) {
			return e.toString();
		} catch (e:Dynamic) {
			return Std.string(e);
		}
	}

	/**
	 * Helper: parse a .manim string and expect success (no error).
	 */
	static function parseExpectingSuccess(manimSource:String):Bool {
		try {
			var source = 'version: 0.3\n$manimSource';
			var input = byte.ByteData.ofString(source);
			var loader = new bh.base.ResourceLoader.CachingResourceLoader();
			MultiAnimParser.parseFile(input, "test-input", loader);
			return true;
		} catch (e:Dynamic) {
			trace('Unexpected parse error: $e');
			return false;
		}
	}

	// ===== @else / @default validation tests =====

	@Test
	public function testElseWithoutPrecedingSibling() {
		var error = parseExpectingError('
			#test programmable(mode:[on,off]=on) {
				@else bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.notNull(error, "Should throw error for @else without preceding sibling");
		Assert.isTrue(error.indexOf("@else/@default requires a preceding sibling") >= 0,
			'Error should mention preceding sibling requirement, got: $error');
	}

	@Test
	public function testDefaultWithoutPrecedingSibling() {
		var error = parseExpectingError('
			#test programmable(mode:[on,off]=on) {
				@default bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.notNull(error, "Should throw error for @default without preceding sibling");
		Assert.isTrue(error.indexOf("@else/@default requires a preceding sibling") >= 0,
			'Error should mention preceding sibling requirement, got: $error');
	}

	@Test
	public function testElseAfterUnconditionalSibling() {
		var error = parseExpectingError('
			#test programmable(mode:[on,off]=on) {
				bitmap(generated(color(10, 10, #f00))): 0,0
				@else bitmap(generated(color(10, 10, #f00))): 0,10
			}
		');
		Assert.notNull(error, "Should throw error for @else after unconditional sibling");
		Assert.isTrue(error.indexOf("previous sibling has no conditional") >= 0,
			'Error should mention previous sibling has no conditional, got: $error');
	}

	@Test
	public function testDefaultAfterUnconditionalSibling() {
		var error = parseExpectingError('
			#test programmable(mode:[on,off]=on) {
				bitmap(generated(color(10, 10, #f00))): 0,0
				@default bitmap(generated(color(10, 10, #f00))): 0,10
			}
		');
		Assert.notNull(error, "Should throw error for @default after unconditional sibling");
		Assert.isTrue(error.indexOf("previous sibling has no conditional") >= 0,
			'Error should mention previous sibling has no conditional, got: $error');
	}

	@Test
	public function testElseOnRootElement() {
		var error = parseExpectingError('
			#test programmable(mode:[on,off]=on) {
				@(mode=>on) bitmap(generated(color(10, 10, #f00))): 0,0
			}
			@else #test2 programmable() {
			}
		');
		Assert.notNull(error, "Should throw error for @else on root element");
	}

	@Test
	public function testValidElseAfterConditional() {
		var success = parseExpectingSuccess('
			#test programmable(mode:[on,off]=on) {
				@(mode=>on) bitmap(generated(color(10, 10, #f00))): 0,0
				@else bitmap(generated(color(10, 10, #f00))): 0,10
			}
		');
		Assert.isTrue(success, "Valid @else after conditional should parse successfully");
	}

	@Test
	public function testValidElseIfChain() {
		var success = parseExpectingSuccess('
			#test programmable(level:uint=1) {
				@(level=>0) bitmap(generated(color(10, 10, #f00))): 0,0
				@else(level=>1) bitmap(generated(color(10, 10, #f00))): 0,10
				@else(level=>2) bitmap(generated(color(10, 10, #f00))): 0,20
				@else bitmap(generated(color(10, 10, #f00))): 0,30
			}
		');
		Assert.isTrue(success, "Valid else-if chain should parse successfully");
	}

	@Test
	public function testValidDefaultAfterConditionals() {
		var success = parseExpectingSuccess('
			#test programmable(mode:[idle,hover,pressed,disabled]=idle) {
				@(mode=>idle) bitmap(generated(color(10, 10, #f00))): 0,0
				@(mode=>hover) bitmap(generated(color(10, 10, #f00))): 0,10
				@default bitmap(generated(color(10, 10, #f00))): 0,20
			}
		');
		Assert.isTrue(success, "Valid @default after conditionals should parse successfully");
	}

	// ===== Conditional parameter validation tests =====

	@Test
	public function testConditionalWithUndefinedParameter() {
		var error = parseExpectingError('
			#test programmable(mode:[on,off]=on) {
				@(nonexistent=>on) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.notNull(error, "Should throw error for undefined conditional parameter");
		Assert.isTrue(error.indexOf("does not have definition") >= 0,
			'Error should mention missing parameter definition, got: $error');
	}

	@Test
	public function testConditionalWithDuplicateParameter() {
		var error = parseExpectingError('
			#test programmable(mode:[on,off]=on) {
				@(mode=>on, mode=>off) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.notNull(error, "Should throw error for duplicate conditional parameter");
		Assert.isTrue(error.indexOf("already defined") >= 0,
			'Error should mention parameter already defined, got: $error');
	}

	// ===== General syntax error tests =====

	@Test
	public function testEmptyProgrammable() {
		var success = parseExpectingSuccess('
			#test programmable() {
			}
		');
		Assert.isTrue(success, "Empty programmable should parse successfully");
	}

	@Test
	public function testUnclosedBrace() {
		var error = parseExpectingError('
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): 0,0
		');
		Assert.notNull(error, "Should throw error for unclosed brace");
	}

	@Test
	public function testMissingElementName() {
		var error = parseExpectingError('
			programmable() {
			}
		');
		Assert.notNull(error, "Should throw error for missing # element name");
	}

	@Test
	public function testDuplicateParameterName() {
		var error = parseExpectingError('
			#test programmable(mode:[on,off]=on, mode:[a,b]=a) {
			}
		');
		Assert.notNull(error, "Should throw error for duplicate parameter name");
		Assert.isTrue(error.indexOf("already defined") >= 0,
			'Error should mention parameter already defined, got: $error');
	}

	@Test
	public function testDoubleCommaInEnum() {
		var error = parseExpectingError('
			#test programmable(mode:[on,,off]=on) {
			}
		');
		Assert.notNull(error, "Should throw error for double comma in enum");
		Assert.isTrue(error.indexOf("double comma") >= 0,
			'Error should mention double comma, got: $error');
	}

	@Test
	public function testDuplicateEnumValue() {
		var error = parseExpectingError('
			#test programmable(mode:[on,off,on]=on) {
			}
		');
		Assert.notNull(error, "Should throw error for duplicate enum value");
		Assert.isTrue(error.indexOf("already defined") >= 0,
			'Error should mention value already defined, got: $error');
	}

	// ===== @() inline property tests =====

	@Test
	public function testAtSignWithoutContent() {
		var error = parseExpectingError('
			#test programmable(mode:[on,off]=on) {
				@ bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.notNull(error, "Should throw error for bare @ without conditional or inline property");
	}

	// ===== Nested conditional tests (valid) =====

	@Test
	public function testElseAfterElse() {
		var success = parseExpectingSuccess('
			#test programmable(mode:[a,b,c]=a) {
				@(mode=>a) bitmap(generated(color(10, 10, #f00))): 0,0
				@else(mode=>b) bitmap(generated(color(10, 10, #f00))): 0,10
				@else bitmap(generated(color(10, 10, #f00))): 0,20
			}
		');
		Assert.isTrue(success, "@else after @else should parse successfully");
	}

	@Test
	public function testDefaultAfterElse() {
		var success = parseExpectingSuccess('
			#test programmable(mode:[a,b,c]=a) {
				@(mode=>a) bitmap(generated(color(10, 10, #f00))): 0,0
				@else(mode=>b) bitmap(generated(color(10, 10, #f00))): 0,10
				@default bitmap(generated(color(10, 10, #f00))): 0,20
			}
		');
		Assert.isTrue(success, "@default after @else should parse successfully");
	}

	@Test
	public function testMultipleConditionalGroups() {
		var success = parseExpectingSuccess('
			#test programmable(mode:[on,off]=on, state:[a,b]=a) {
				@(mode=>on) bitmap(generated(color(10, 10, #f00))): 0,0
				@else bitmap(generated(color(10, 10, #f00))): 0,10
				@(state=>a) bitmap(generated(color(10, 10, #f00))): 0,20
				@else bitmap(generated(color(10, 10, #f00))): 0,30
			}
		');
		Assert.isTrue(success, "Multiple conditional groups should parse successfully");
	}

	// ===== Missing version declaration tests =====

	@Test
	public function testMissingVersionDeclaration() {
		var error = parseRawExpectingError('
			#test programmable() {
			}
		');
		Assert.notNull(error, "Should throw error for missing version declaration");
		Assert.isTrue(error.indexOf("Missing version declaration") >= 0,
			'Error should mention missing version declaration, got: $error');
		Assert.isTrue(error.indexOf("version: 0.3") >= 0,
			'Error should mention the required version syntax, got: $error');
	}

	// ===== Block comment tests =====

	@Test
	public function testBlockCommentInProgrammable() {
		var success = parseExpectingSuccess('
			/* This is a block comment */
			#test programmable() {
				/* comment inside programmable */
				bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "Block comments should be allowed in .manim files");
	}

	@Test
	public function testMultiLineBlockComment() {
		var success = parseExpectingSuccess('
			/*
			  Multi-line
			  block comment
			*/
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "Multi-line block comments should parse successfully");
	}

	@Test
	public function testBlockCommentWithStars() {
		var success = parseExpectingSuccess('
			/**
			 * Javadoc-style comment
			 * with stars
			 */
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "Block comments with extra stars should parse successfully");
	}

	// ===== Named filter parameter tests =====

	@Test
	public function testNamedFilterParamsOutline() {
		var success = parseExpectingSuccess('
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))) {
					filter: outline(size: 2, color: #ff0000)
					pos: 0,0
				}
			}
		');
		Assert.isTrue(success, "Named params for outline filter should parse successfully");
	}

	@Test
	public function testNamedFilterParamsBlur() {
		var success = parseExpectingSuccess('
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))) {
					filter: blur(radius: 2, gain: 1.5)
					pos: 0,0
				}
			}
		');
		Assert.isTrue(success, "Named params for blur filter should parse successfully");
	}

	@Test
	public function testNamedFilterParamsBlurWithQuality() {
		var success = parseExpectingSuccess('
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))) {
					filter: blur(radius: 2, gain: 1.5, quality: 2, linear: 1.0)
					pos: 0,0
				}
			}
		');
		Assert.isTrue(success, "Named params for blur filter with quality/linear should parse successfully");
	}

	@Test
	public function testNamedFilterParamsBrightness() {
		var success = parseExpectingSuccess('
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))) {
					filter: brightness(value: 1.5)
					pos: 0,0
				}
			}
		');
		Assert.isTrue(success, "Named params for brightness filter should parse successfully");
	}

	@Test
	public function testNamedFilterParamsSaturate() {
		var success = parseExpectingSuccess('
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))) {
					filter: saturate(value: 0.5)
					pos: 0,0
				}
			}
		');
		Assert.isTrue(success, "Named params for saturate filter should parse successfully");
	}

	@Test
	public function testPositionalFilterParamsStillWork() {
		var success = parseExpectingSuccess('
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))) {
					filter: outline(2, #ff0000)
					pos: 0,0
				}
				bitmap(generated(color(10, 10, #f00))) {
					filter: blur(2, 1.5)
					pos: 0,10
				}
				bitmap(generated(color(10, 10, #f00))) {
					filter: brightness(1.5)
					pos: 0,20
				}
				bitmap(generated(color(10, 10, #f00))) {
					filter: saturate(0.5)
					pos: 0,30
				}
			}
		');
		Assert.isTrue(success, "Positional filter params should still work");
	}

	@Test
	public function testNamedFilterDuplicateParam() {
		var error = parseExpectingError('
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))) {
					filter: blur(radius: 2, radius: 3)
					pos: 0,0
				}
			}
		');
		Assert.notNull(error, "Should throw error for duplicate named filter param");
		Assert.isTrue(error.indexOf("already defined") >= 0,
			'Error should mention param already defined, got: $error');
	}

	// ===== Symbolic conditional operator tests =====

	@Test
	public function testSymbolicGreaterEquals() {
		var success = parseExpectingSuccess('
			#test programmable(val:0..100=50) {
				@(val >= 30) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "@(val >= 30) should parse successfully");
	}

	@Test
	public function testSymbolicLessEquals() {
		var success = parseExpectingSuccess('
			#test programmable(val:0..100=50) {
				@(val <= 30) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "@(val <= 30) should parse successfully");
	}

	@Test
	public function testSymbolicGreaterThan() {
		var success = parseExpectingSuccess('
			#test programmable(val:0..100=50) {
				@(val > 30) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "@(val > 30) should parse successfully");
	}

	@Test
	public function testSymbolicLessThan() {
		var success = parseExpectingSuccess('
			#test programmable(val:0..100=50) {
				@(val < 30) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "@(val < 30) should parse successfully");
	}

	@Test
	public function testSymbolicNotEquals() {
		var success = parseExpectingSuccess('
			#test programmable(mode:[on,off]=on) {
				@(mode != off) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "@(mode != off) should parse successfully");
	}

	@Test
	public function testBareRangeAfterArrow() {
		var success = parseExpectingSuccess('
			#test programmable(val:0..100=50) {
				@(val => 10..30) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "@(val => 10..30) bare range should parse successfully");
	}

	@Test
	public function testNegativeValueSymbolic() {
		var success = parseExpectingSuccess('
			#test programmable(val:-50..150=50) {
				@(val <= -1) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "@(val <= -1) with negative should parse successfully");
	}

	@Test
	public function testNegativeBareRange() {
		var success = parseExpectingSuccess('
			#test programmable(val:-50..150=50) {
				@(val => -10..100) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "@(val => -10..100) negative bare range should parse successfully");
	}

	@Test
	public function testBackwardCompatGreaterThanOrEqual() {
		var success = parseExpectingSuccess('
			#test programmable(val:0..100=50) {
				@(val => greaterThanOrEqual 30) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "Old greaterThanOrEqual syntax should still work");
	}

	@Test
	public function testBackwardCompatLessThanOrEqual() {
		var success = parseExpectingSuccess('
			#test programmable(val:0..100=50) {
				@(val => lessThanOrEqual 30) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "Old lessThanOrEqual syntax should still work");
	}

	@Test
	public function testBackwardCompatBetween() {
		var success = parseExpectingSuccess('
			#test programmable(val:0..100=50) {
				@(val => between 10..30) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "Old between syntax should still work");
	}

	@Test
	public function testBackwardCompatNegateArrow() {
		var success = parseExpectingSuccess('
			#test programmable(mode:[on,off]=on) {
				@(mode => !off) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "Old @(param => !value) negate syntax should still work");
	}

	@Test
	public function testSymbolicWithCombinedConditions() {
		var success = parseExpectingSuccess('
			#test programmable(hp:0..100=50, mode:[attack,defend]=attack) {
				@(hp >= 30, mode => attack) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "Mixed symbolic and arrow conditions should parse successfully");
	}

	@Test
	public function testNotEqualsWithArray() {
		var success = parseExpectingSuccess('
			#test programmable(mode:[a,b,c,d]=a) {
				@(mode != [a, b]) bitmap(generated(color(10, 10, #f00))): 0,0
			}
		');
		Assert.isTrue(success, "@(mode != [a, b]) should parse successfully");
	}

	// ===== Data block validation tests =====

	@Test
	public function testDataRequiresName() {
		var error = parseExpectingError('data { maxLevel: 5 }');
		Assert.notNull(error, "Should throw error for data without #name");
		Assert.isTrue(error.indexOf("data requires a #name") >= 0,
			'Error should mention #name requirement, got: $error');
	}

	@Test
	public function testDataNotNested() {
		var error = parseExpectingError('
			#outer programmable() {
				#inner data { maxLevel: 5 }
			}
		');
		Assert.notNull(error, "Should throw error for nested data");
		Assert.isTrue(error.indexOf("data must be a root node") >= 0,
			'Error should mention root node requirement, got: $error');
	}

	@Test
	public function testDataDuplicateRecord() {
		var error = parseExpectingError('
			#test data {
				#tier record(name: string, cost: int)
				#tier record(name: string, dmg: float)
			}
		');
		Assert.notNull(error, "Should throw error for duplicate record");
		Assert.isTrue(error.indexOf("already defined") >= 0,
			'Error should mention "already defined", got: $error');
	}

	@Test
	public function testDataUnknownRecordType() {
		var error = parseExpectingError('
			#test data {
				#tier record(name: string, cost: int)
				value: unknown { name: "x", cost: 1 }
			}
		');
		Assert.notNull(error, "Should throw error for unknown record type");
		Assert.isTrue(error.indexOf('unknown record type') >= 0,
			'Error should mention "unknown record type", got: $error');
	}

	@Test
	public function testDataMissingRecordField() {
		var error = parseExpectingError('
			#test data {
				#tier record(name: string, cost: int)
				value: tier { name: "x" }
			}
		');
		Assert.notNull(error, "Should throw error for missing required field");
		Assert.isTrue(error.indexOf("missing required field") >= 0,
			'Error should mention "missing required field", got: $error');
	}

	@Test
	public function testDataUnknownFieldInRecord() {
		var error = parseExpectingError('
			#test data {
				#tier record(name: string, cost: int)
				value: tier { name: "x", cost: 5, unknown: 3 }
			}
		');
		Assert.notNull(error, "Should throw error for unknown field in record");
		Assert.isTrue(error.indexOf('unknown field') >= 0,
			'Error should mention "unknown field", got: $error');
	}

	@Test
	public function testDataDuplicateFieldInRecord() {
		var error = parseExpectingError('
			#test data {
				#tier record(name: string, cost: int)
				value: tier { name: "x", cost: 5, name: "y" }
			}
		');
		Assert.notNull(error, "Should throw error for duplicate field in record");
		Assert.isTrue(error.indexOf('duplicate field') >= 0,
			'Error should mention "duplicate field", got: $error');
	}

	@Test
	public function testDataParseSuccess() {
		var success = parseExpectingSuccess('
			#test data {
				maxLevel: 5
				name: "Warrior"
				costs: [10, 20, 40, 80]
			}
		');
		Assert.isTrue(success, "Simple data block should parse successfully");
	}

	@Test
	public function testDataWithRecords() {
		var success = parseExpectingSuccess('
			#upgrades data {
				#tier record(name: string, cost: int, dmg: float)
				maxLevel: 5
				tiers: tier[] [
					{ name: "Bronze", cost: 10, dmg: 1.0 }
					{ name: "Silver", cost: 20, dmg: 1.5 }
				]
				defaultTier: tier { name: "None", cost: 0, dmg: 0.0 }
			}
		');
		Assert.isTrue(success, "Data block with records should parse successfully");
	}

	@Test
	public function testDataBoolAndFloat() {
		var success = parseExpectingSuccess('
			#config data {
				enabled: true
				speed: 3.5
				ratio: -0.5
				count: -10
			}
		');
		Assert.isTrue(success, "Data block with bools and floats should parse successfully");
	}
}
