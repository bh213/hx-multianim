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
			var source = addVersion ? 'version: 0.5\n$manimSource' : manimSource;
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
			var source = 'version: 0.5\n$manimSource';
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
		Assert.isTrue(error.indexOf("version: 0.5") >= 0,
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

	@Test
	public function testDataOptionalField() {
		var success = parseExpectingSuccess('
			#test data {
				#tier record(name: string, cost: int, ?dmg: float)
				value: tier { name: "x", cost: 5 }
			}
		');
		Assert.isTrue(success, "Data block with optional field omitted should parse successfully");
	}

	@Test
	public function testDataOptionalFieldProvided() {
		var success = parseExpectingSuccess('
			#test data {
				#tier record(name: string, ?cost: int, ?dmg: float)
				value: tier { name: "x", cost: 5, dmg: 1.0 }
			}
		');
		Assert.isTrue(success, "Data block with optional fields provided should parse successfully");
	}

	@Test
	public function testDataRequiredFieldStillRequired() {
		var error = parseExpectingError('
			#test data {
				#tier record(name: string, cost: int, ?dmg: float)
				value: tier { cost: 5 }
			}
		');
		Assert.notNull(error, "Should throw error for missing required field");
		Assert.isTrue(error.indexOf("missing required field") >= 0,
			'Error should mention "missing required field", got: $error');
	}

	// ===== @final tests =====

	@Test
	public function testFinalBasicInteger() {
		var success = parseExpectingSuccess('
			#test programmable(x:uint=10) {
				@final doubled = $$x * 2
				bitmap(generated(color($$doubled, $$doubled, #f00))): 0, 0
			}
		');
		Assert.isTrue(success, "@final with integer expression should parse");
	}

	@Test
	public function testFinalChaining() {
		var success = parseExpectingSuccess('
			#test programmable(x:uint=10, y:uint=20) {
				@final cx = $$x + 5
				@final cy = $$y + 5
				@final offset = $$cx + $$cy
				bitmap(generated(color($$offset, $$offset, #f00))): 0, 0
			}
		');
		Assert.isTrue(success, "@final chaining (referencing other finals) should parse");
	}

	@Test
	public function testFinalWithString() {
		var success = parseExpectingSuccess('
			#test programmable(name:string="test") {
				@final label = "hello"
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		');
		Assert.isTrue(success, "@final with string value should parse");
	}

	@Test
	public function testFinalWithColor() {
		var success = parseExpectingSuccess('
			#test programmable() {
				@final bg = #FF0000
				bitmap(generated(color(10, 10, $$bg))): 0, 0
			}
		');
		Assert.isTrue(success, "@final with color value should parse");
	}

	@Test
	public function testFinalWithArray() {
		var success = parseExpectingSuccess('
			#test programmable(x:uint=5, y:uint=10) {
				@final coords = [$$x, $$y, 15]
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		');
		Assert.isTrue(success, "@final with array expression should parse");
	}

	@Test
	public function testFinalWithTernary() {
		var success = parseExpectingSuccess('
			#test programmable(big:bool=true) {
				@final size = ?($$big) 100 : 50
				bitmap(generated(color($$size, $$size, #f00))): 0, 0
			}
		');
		Assert.isTrue(success, "@final with ternary expression should parse");
	}

	@Test
	public function testFinalInsideFlow() {
		var success = parseExpectingSuccess('
			#test programmable(x:uint=5) {
				@final outer = $$x * 2
				flow() {
					@final inner = $$outer + 1
					bitmap(generated(color($$inner, $$inner, #f00))): 0, 0
				}
				bitmap(generated(color($$outer, $$outer, #00f))): 10, 10
			}
		');
		Assert.isTrue(success, "@final with nested scoping should parse");
	}

	@Test
	public function testFinalInsideRepeatable() {
		var success = parseExpectingSuccess('
			#test programmable() {
				repeatable($$i, step(3, dx: 20)) {
					@final pos = $$i * 30 + 5
					bitmap(generated(color(10, 10, #f00))): $$pos, 0
				}
			}
		');
		Assert.isTrue(success, "@final inside repeatable should parse");
	}

	// ===== String interpolation tests =====

	@Test
	public function testInterpolationSimpleRef() {
		// Note: double-quoted Haxe strings to avoid Haxe interpolating $name
		var success = parseExpectingSuccess("
			#test programmable(name:string=\"hi\") {
				text(dd, '${$name}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Simple string interpolation '${" + "$" + "param}' should parse");
	}

	@Test
	public function testInterpolationWithPrefix() {
		var success = parseExpectingSuccess("
			#test programmable(name:string=\"hi\") {
				text(dd, 'hello ${$name}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Interpolation with prefix text should parse");
	}

	@Test
	public function testInterpolationWithSuffix() {
		var success = parseExpectingSuccess("
			#test programmable(name:string=\"hi\") {
				text(dd, '${$name} world', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Interpolation with suffix text should parse");
	}

	@Test
	public function testInterpolationWithPrefixAndSuffix() {
		var success = parseExpectingSuccess("
			#test programmable(name:string=\"hi\") {
				text(dd, 'hello ${$name} world', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Interpolation with surrounding text should parse");
	}

	@Test
	public function testInterpolationMultiple() {
		var success = parseExpectingSuccess("
			#test programmable(a:uint=1, b:uint=2) {
				text(dd, '${$a} and ${$b}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Multiple interpolations in one string should parse");
	}

	@Test
	public function testInterpolationWithExpression() {
		var success = parseExpectingSuccess("
			#test programmable(x:uint=5) {
				text(dd, 'val=${$x * 2}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Interpolation with arithmetic expression should parse");
	}

	@Test
	public function testInterpolationAdjacentToText() {
		var success = parseExpectingSuccess("
			#test programmable(x:uint=5) {
				text(dd, 'count:${$x}items', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Interpolation directly adjacent to text should parse");
	}

	@Test
	public function testInterpolationConsecutive() {
		var success = parseExpectingSuccess("
			#test programmable(a:uint=1, b:uint=2) {
				text(dd, '${$a}${$b}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Consecutive interpolations with no separator should parse");
	}

	@Test
	public function testSingleQuoteNoInterpolation() {
		var success = parseExpectingSuccess("
			#test programmable() {
				text(dd, 'plain text', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Single-quoted string without interpolation should still work");
	}

	@Test
	public function testSingleQuoteDollarWithoutBrace() {
		var success = parseExpectingSuccess("
			#test programmable() {
				text(dd, '$5 price', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Dollar sign not followed by { should be treated as literal text");
	}

	@Test
	public function testInterpolationInRepeatable() {
		var success = parseExpectingSuccess("
			#test programmable(count:uint=3) {
				repeatable($i, step($count, dx: 20)) {
					text(dd, 'item ${$i}', #ffffffff): 0, 0
				}
			}
		");
		Assert.isTrue(success, "Interpolation with loop variable in repeatable should parse");
	}

	@Test
	public function testInterpolationInRepeatable2d() {
		var success = parseExpectingSuccess("
			#test programmable(cols:uint=3, rows:uint=2) {
				repeatable2d($cx, $cy, step($cols, dx: 30), step($rows, dy: 20)) {
					text(dd, '${$cx}/${$cy}', #ffffffff): 0, 0
				}
			}
		");
		Assert.isTrue(success, "Interpolation in repeatable2d with loop variables should parse");
	}

	@Test
	public function testInterpolationMixedWithConcat() {
		var success = parseExpectingSuccess("
			#test programmable(name:string=\"hi\") {
				text(dd, \"prefix:\" + '${$name}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Interpolated string used with + concatenation should parse");
	}

	// ===== String interpolation error tests =====

	@Test
	public function testInterpolationUnclosedBrace() {
		var error = parseExpectingError("
			#test programmable(x:uint=5) {
				text(dd, 'hello ${$x', #ffffffff): 0, 0
			}
		");
		Assert.notNull(error, "Should throw error for unclosed interpolation");
		Assert.isTrue(error.indexOf("Unclosed string interpolation") >= 0,
			'Error should mention unclosed interpolation, got: $error');
	}

	@Test
	public function testInterpolationEmpty() {
		var error = parseExpectingError("
			#test programmable() {
				text(dd, 'hello ${}', #ffffffff): 0, 0
			}
		");
		Assert.notNull(error, "Should throw error for empty interpolation");
		Assert.isTrue(error.indexOf("Empty expression") >= 0,
			'Error should mention empty expression, got: $error');
	}

	@Test
	public function testInterpolationEmptyWhitespace() {
		var error = parseExpectingError("
			#test programmable() {
				text(dd, 'hello ${  }', #ffffffff): 0, 0
			}
		");
		Assert.notNull(error, "Should throw error for whitespace-only interpolation");
		Assert.isTrue(error.indexOf("Empty expression") >= 0,
			'Error should mention empty expression, got: $error');
	}

	@Test
	public function testInterpolationUnclosedString() {
		var error = parseExpectingError("
			#test programmable(x:uint=5) {
				text(dd, 'hello ${$x}
			}
		");
		Assert.notNull(error, "Should throw error for unterminated interpolated string");
		Assert.isTrue(error.indexOf("Unterminated string") >= 0,
			'Error should mention unterminated string, got: $error');
	}

	@Test
	public function testInterpolationUnclosedBraceMessage() {
		var error = parseExpectingError("
			#test programmable(x:uint=5) {
				text(dd, 'value: ${$x + 1', #ffffffff): 0, 0
			}
		");
		Assert.notNull(error, "Should throw error for unclosed interpolation with expression");
		Assert.isTrue(error.indexOf("expected }") >= 0,
			'Error should tell user to close with }, got: $error');
	}

	@Test
	public function testInterpolationNestedUnclosed() {
		// ${  with { inside but no matching }
		var error = parseExpectingError("
			#test programmable(x:uint=5) {
				text(dd, 'test ${$x + {1', #ffffffff): 0, 0
			}
		");
		Assert.notNull(error, "Should throw error for unclosed nested braces in interpolation");
		Assert.isTrue(error.indexOf("Unclosed string interpolation") >= 0,
			'Error should mention unclosed interpolation, got: $error');
	}

	// ===== Undefined variable reference tests =====

	@Test
	public function testUndefinedVarInText() {
		var error = parseExpectingError("
			#test programmable(x:uint=5) {
				text(dd, $nonexistent, #ffffffff): 0, 0
			}
		");
		Assert.notNull(error, "Should throw error for undefined variable in text");
		Assert.isTrue(error.indexOf("unknown variable") >= 0,
			'Error should mention unknown variable, got: $error');
		Assert.isTrue(error.indexOf("nonexistent") >= 0,
			'Error should name the bad variable, got: $error');
	}

	@Test
	public function testUndefinedVarShowsAvailable() {
		var error = parseExpectingError("
			#test programmable(hp:uint=100, mode:[a,b]=a) {
				text(dd, $typo, #ffffffff): 0, 0
			}
		");
		Assert.notNull(error, "Should throw error for undefined variable");
		Assert.isTrue(error.indexOf("hp") >= 0,
			'Error should list available variables including hp, got: $error');
		Assert.isTrue(error.indexOf("mode") >= 0,
			'Error should list available variables including mode, got: $error');
	}

	@Test
	public function testUndefinedVarInInterpolation() {
		var error = parseExpectingError("
			#test programmable(x:uint=5) {
				text(dd, 'value: ${$oops}', #ffffffff): 0, 0
			}
		");
		Assert.notNull(error, "Should throw error for undefined variable in interpolated string");
		Assert.isTrue(error.indexOf("unknown variable") >= 0,
			'Error should mention unknown variable, got: $error');
		Assert.isTrue(error.indexOf("oops") >= 0,
			'Error should name the bad variable, got: $error');
	}

	@Test
	public function testUndefinedVarInPosition() {
		var error = parseExpectingError("
			#test programmable(x:uint=5) {
				bitmap(generated(color(10, 10, #f00))): $missing, 0
			}
		");
		Assert.notNull(error, "Should throw error for undefined variable in position");
		Assert.isTrue(error.indexOf("unknown variable") >= 0,
			'Error should mention unknown variable, got: $error');
	}

	@Test
	public function testUndefinedVarInAlpha() {
		var error = parseExpectingError("
			#test programmable(x:uint=5) {
				@alpha($nope) bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		Assert.notNull(error, "Should throw error for undefined variable in alpha");
		Assert.isTrue(error.indexOf("unknown variable") >= 0,
			'Error should mention unknown variable, got: $error');
	}

	@Test
	public function testDefinedParamIsValid() {
		var success = parseExpectingSuccess("
			#test programmable(x:uint=5, label:string=\"hi\") {
				text(dd, $label, #ffffffff): $x, 0
			}
		");
		Assert.isTrue(success, "Defined parameters should be valid references");
	}

	@Test
	public function testLoopVarIsValid() {
		var success = parseExpectingSuccess("
			#test programmable(count:uint=3) {
				repeatable($i, step($count, dx: 20)) {
					text(dd, $i, #ffffffff): 0, 0
				}
			}
		");
		Assert.isTrue(success, "Loop variable should be valid inside repeatable body");
	}

	@Test
	public function testLoopVarNotValidOutsideScope() {
		var error = parseExpectingError("
			#test programmable(count:uint=3) {
				repeatable($i, step($count, dx: 20)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
				text(dd, $i, #ffffffff): 0, 50
			}
		");
		Assert.notNull(error, "Loop variable should not be valid outside repeatable body");
		Assert.isTrue(error.indexOf("unknown variable") >= 0,
			'Error should mention unknown variable, got: $error');
	}

	@Test
	public function testIteratorOutputVarIsValid() {
		var success = parseExpectingSuccess("
			#test programmable() {
				repeatable($index, tiles($bmp, \"crew2\", \"Arrow_dir0\")) {
					bitmap($bmp): $index * 40, 0;
				}
			}
		");
		Assert.isTrue(success, "Iterator output variable $bmp should be valid inside repeatable body");
	}

	@Test
	public function testFinalVarIsValid() {
		var success = parseExpectingSuccess('
			#test programmable(x:uint=10) {
				@final doubled = $$x * 2
				bitmap(generated(color($$doubled, $$doubled, #f00))): 0, 0
			}
		');
		Assert.isTrue(success, "@final variable should be valid as reference");
	}

	@Test
	public function testFinalVarNotValidBeforeDeclaration() {
		var error = parseExpectingError('
			#test programmable(x:uint=10) {
				bitmap(generated(color($$later, $$later, #f00))): 0, 0
				@final later = $$x * 2
			}
		');
		Assert.notNull(error, "@final variable should not be valid before its declaration");
		Assert.isTrue(error.indexOf("unknown variable") >= 0,
			'Error should mention unknown variable, got: $error');
	}

	@Test
	public function testRepeatable2dVarsValid() {
		var success = parseExpectingSuccess("
			#test programmable(cols:uint=3, rows:uint=2) {
				repeatable2d($cx, $cy, step($cols, dx: 30), step($rows, dy: 20)) {
					text(dd, '${$cx}/${$cy}', #ffffffff): 0, 0
				}
			}
		");
		Assert.isTrue(success, "Both 2d loop variables should be valid inside body");
	}

	@Test
	public function testNestedRepeatableScope() {
		var success = parseExpectingSuccess("
			#test programmable(n:uint=3) {
				repeatable($i, step($n, dx: 40)) {
					repeatable($j, step($n, dy: 20)) {
						text(dd, $i, #ffffffff): 0, 0
						text(dd, $j, #ffffffff): 10, 0
					}
				}
			}
		");
		Assert.isTrue(success, "Outer loop variable should be accessible in inner repeatable");
	}

	@Test
	public function testNonProgrammableNoValidation() {
		// Data blocks and other non-programmable types should not trigger validation
		var success = parseExpectingSuccess('
			#test data {
				maxLevel: 5
			}
		');
		Assert.isTrue(success, "Non-programmable blocks should parse without variable validation");
	}

	@Test
	public function testNameWithoutIndexInsideRepeatable() {
		var error = parseExpectingError("
			#test programmable(n:uint=3) {
				repeatable($i, step($n, dx: 40)) {
					#label text(f3x5, $i, #ffffffff): 0, 0
				}
			}
		");
		Assert.notNull(error, "Should throw error for #name without [$i] inside repeatable");
		Assert.isTrue(error.indexOf("requires indexed form") >= 0,
			'Error should mention indexed form, got: $error');
	}

	@Test
	public function testNameWithoutIndexInsideNestedRepeatable() {
		var error = parseExpectingError("
			#test programmable(n:uint=3) {
				repeatable($i, step($n, dx: 40)) {
					repeatable($j, step($n, dy: 20)) {
						#icon bitmap(generated(color(10, 10, #ff0000))): 0, 0
					}
				}
			}
		");
		Assert.notNull(error, "Should throw error for #name without index in nested repeatable");
		Assert.isTrue(error.indexOf("requires indexed form") >= 0,
			'Error should mention indexed form, got: $error');
	}

	@Test
	public function testIndexedNameInsideRepeatableIsValid() {
		var success = parseExpectingSuccess("
			#test programmable(n:uint=3) {
				repeatable($i, step($n, dx: 40)) {
					#label[$i] text(f3x5, $i, #ffffffff): 0, 0
				}
			}
		");
		Assert.isTrue(success, "#name[$i] inside repeatable should be valid");
	}

	@Test
	public function testNameOutsideRepeatableIsValid() {
		var success = parseExpectingSuccess("
			#test programmable() {
				#header text(f3x5, \"hello\", #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "#name outside repeatable should be valid");
	}

	// ===== Text maxWidth reference tests =====

	@Test
	public function testTextMaxWidthLiteral() {
		var success = parseExpectingSuccess('
			#test programmable() {
				text(dd, "hello", #ffffff, center, 100): 0, 0
			}
		');
		Assert.isTrue(success, "Text with literal maxWidth should parse successfully");
	}

	@Test
	public function testTextMaxWidthReference() {
		var success = parseExpectingSuccess("
			#test programmable(w:uint=40) {
				text(dd, \"hello\", #ffffff, center, $w): 0, 0
			}
		");
		Assert.isTrue(success, "Text with reference maxWidth should parse successfully");
	}

	@Test
	public function testTextMaxWidthExpression() {
		var success = parseExpectingSuccess("
			#test programmable(w:uint=40) {
				text(dd, \"hello\", #ffffff, center, $w * 2): 0, 0
			}
		");
		Assert.isTrue(success, "Text with expression maxWidth should parse successfully");
	}

	@Test
	public function testTextMaxWidthUndefinedRef() {
		var error = parseExpectingError("
			#test programmable(w:uint=40) {
				text(dd, \"hello\", #ffffff, center, $undefined): 0, 0
			}
		");
		Assert.notNull(error, "Should throw error for undefined reference in text maxWidth");
		Assert.isTrue(error.indexOf("unknown variable") >= 0,
			'Error should mention unknown variable, got: $error');
	}

	@Test
	public function testTextMaxWidthWithInterpolatedText() {
		var success = parseExpectingSuccess("
			#test programmable(w:uint=40) {
				text(dd, '${$w}', #ffffff, center, $w): 0, 0
			}
		");
		Assert.isTrue(success, "Text with interpolated text value and reference maxWidth should parse successfully");
	}

	@Test
	public function testTextMaxWidthGrid() {
		var success = parseExpectingSuccess('
			#test programmable() {
				text(dd, "hello", #ffffff, center, grid): 0, 0
			}
		');
		Assert.isTrue(success, "Text with grid maxWidth should still parse successfully");
	}
}
