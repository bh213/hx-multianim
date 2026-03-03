package bh.test.examples;

import utest.Assert;
import bh.multianim.MultiAnimParser;
import bh.multianim.MultiAnimParser.MultiAnimResult;
import bh.multianim.MultiAnimParser.NodeType;
import bh.multianim.MultiAnimParser.NodeConditionalValues;

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

	/**
	 * Helper: parse a .manim string and return the parsed result for AST inspection.
	 */
	static function parseExpectingResult(manimSource:String):MultiAnimResult {
		try {
			var source = 'version: 0.5\n$manimSource';
			var input = byte.ByteData.ofString(source);
			var loader = new bh.base.ResourceLoader.CachingResourceLoader();
			return MultiAnimParser.parseFile(input, "test-input", loader);
		} catch (e:Dynamic) {
			trace('Unexpected parse error: $e');
			return null;
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
		Assert.stringContains("root", error);
	}

	@Test
	public function testValidElseAfterConditional() {
		var result = parseExpectingResult('
			#test programmable(mode:[on,off]=on) {
				@(mode=>on) bitmap(generated(color(10, 10, #f00))): 0,0
				@else bitmap(generated(color(10, 10, #f00))): 0,10
			}
		');
		Assert.notNull(result, "Valid @else after conditional should parse successfully");
		var node = result.nodes.get("test");
		Assert.notNull(node);
		Assert.equals(2, node.children.length);
		Assert.isTrue(node.children[0].conditionals.match(Conditional(_, _)), "first child should have @() conditional");
		Assert.isTrue(node.children[1].conditionals.match(ConditionalElse(_)), "second child should have @else conditional");
	}

	@Test
	public function testValidElseIfChain() {
		var result = parseExpectingResult('
			#test programmable(level:uint=1) {
				@(level=>0) bitmap(generated(color(10, 10, #f00))): 0,0
				@else(level=>1) bitmap(generated(color(10, 10, #f00))): 0,10
				@else(level=>2) bitmap(generated(color(10, 10, #f00))): 0,20
				@else bitmap(generated(color(10, 10, #f00))): 0,30
			}
		');
		Assert.notNull(result, "Valid else-if chain should parse successfully");
		var node = result.nodes.get("test");
		Assert.notNull(node);
		Assert.equals(4, node.children.length);
		Assert.isTrue(node.children[0].conditionals.match(Conditional(_, _)), "first should be @()");
		Assert.isTrue(node.children[1].conditionals.match(ConditionalElse(_)), "second should be @else()");
		Assert.isTrue(node.children[2].conditionals.match(ConditionalElse(_)), "third should be @else()");
		Assert.isTrue(node.children[3].conditionals.match(ConditionalElse(_)), "fourth should be @else");
	}

	@Test
	public function testValidDefaultAfterConditionals() {
		var result = parseExpectingResult('
			#test programmable(mode:[idle,hover,pressed,disabled]=idle) {
				@(mode=>idle) bitmap(generated(color(10, 10, #f00))): 0,0
				@(mode=>hover) bitmap(generated(color(10, 10, #f00))): 0,10
				@default bitmap(generated(color(10, 10, #f00))): 0,20
			}
		');
		Assert.notNull(result, "Valid @default after conditionals should parse successfully");
		var node = result.nodes.get("test");
		Assert.notNull(node);
		Assert.equals(3, node.children.length);
		Assert.isTrue(node.children[2].conditionals.match(ConditionalDefault), "third child should be @default");
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
		Assert.stringContains("end of file", error);
	}

	@Test
	public function testMissingElementName() {
		var error = parseExpectingError('
			programmable() {
			}
		');
		Assert.notNull(error, "Should throw error for missing # element name");
		Assert.isTrue(error.indexOf("programmable requires a #name prefix") >= 0,
			'Error should mention missing #name prefix, got: $error');
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
		Assert.stringContains("after @", error);
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
		var result = parseExpectingResult('
			#test data {
				maxLevel: 5
				name: "Warrior"
				costs: [10, 20, 40, 80]
			}
		');
		Assert.notNull(result, "Simple data block should parse successfully");
		var node = result.nodes.get("test");
		Assert.notNull(node);
		Assert.isTrue(node.type.match(DATA(_)), "should be DATA node");
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

	// ===== Bare identifier interpolation (${name} shorthand for ${$name}) =====
	// Note: Haxe double-quoted strings "" have NO interpolation, single-quoted '' do

	@Test
	public function testInterpolationBareIdentifier() {
		var success = parseExpectingSuccess("
			#test programmable(name:string=\"hi\") {
				text(dd, '${name}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Bare identifier in interpolation should be treated as reference");
	}

	@Test
	public function testInterpolationBareIdentifierWithPrefix() {
		var success = parseExpectingSuccess("
			#test programmable(name:string=\"hi\") {
				text(dd, 'hello ${name}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Bare identifier with prefix text should parse");
	}

	@Test
	public function testInterpolationBareArithmetic() {
		var success = parseExpectingSuccess("
			#test programmable(x:uint=5) {
				text(dd, 'val=${x * 2}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Bare identifier with arithmetic should parse");
	}

	@Test
	public function testInterpolationBareMultipleVars() {
		var success = parseExpectingSuccess("
			#test programmable(a:uint=1, b:uint=2) {
				text(dd, '${a} and ${b}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Multiple bare identifiers in interpolation should parse");
	}

	@Test
	public function testInterpolationBareExpression() {
		var success = parseExpectingSuccess("
			#test programmable(a:uint=1, b:uint=2) {
				text(dd, '${a + b}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Bare identifier expression in interpolation should parse");
	}

	@Test
	public function testInterpolationDivOperator() {
		var success = parseExpectingSuccess("
			#test programmable(value:uint=100) {
				text(dd, '${value div 10}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "div operator inside string interpolation should parse");
	}

	@Test
	public function testInterpolationArithmeticAdd() {
		var success = parseExpectingSuccess("
			#test programmable(value:uint=77) {
				text(dd, '${value + 10}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Addition inside string interpolation should parse");
	}

	@Test
	public function testInterpolationWithSuffixText() {
		var success = parseExpectingSuccess("
			#test programmable(x:uint=5) {
				text(dd, 'prefix ${x + 1} suffix', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Multi-token interpolation with prefix and suffix text should parse");
	}

	@Test
	public function testInterpolationErrorPositionNotLine1() {
		// Error inside interpolation should report the actual line, not line 1
		var error = parseExpectingError("
			#test programmable(x:uint=5) {
				bitmap(generated(color(10, 10, #ff0000))): 0, 0
				bitmap(generated(color(10, 10, #00ff00))): 0, 20
				text(dd, 'value: ${$oops}', #ffffffff): 0, 40
			}
		");
		Assert.notNull(error, "Should throw error for undefined variable in interpolation");
		// The error should NOT report line 1 (sub-lexer default) — it should report the actual line
		Assert.isFalse(error.indexOf("test-input:1:") >= 0,
			'Error position should not be line 1 (sub-lexer default), got: $error');
		Assert.isTrue(error.indexOf("test-input:") >= 0,
			'Error should contain a file:line reference, got: $error');
	}

	@Test
	public function testInterpolationBareMixedWithDollar() {
		var success = parseExpectingSuccess("
			#test programmable(a:uint=1, b:uint=2) {
				text(dd, '${a} and ${$b}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Mixing bare and dollar-prefixed refs should parse");
	}

	@Test
	public function testInterpolationBareWithDoubleQuotedString() {
		var success = parseExpectingSuccess("
			#test programmable(x:uint=5) {
				text(dd, 'prefix ${x + \"items\"}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "Bare identifier with double-quoted string concat should parse");
	}

	@Test
	public function testInterpolationBareInRepeatable() {
		var success = parseExpectingSuccess("
			#test programmable(count:uint=3) {
				repeatable($i, step($count, dx: 20)) {
					text(dd, 'item ${i}', #ffffffff): 0, 0
				}
			}
		");
		Assert.isTrue(success, "Bare loop variable in interpolation should parse");
	}

	@Test
	public function testInterpolationBareInRepeatable2d() {
		var success = parseExpectingSuccess("
			#test programmable(cols:uint=3, rows:uint=2) {
				repeatable2d($cx, $cy, step($cols, dx: 30), step($rows, dy: 20)) {
					text(dd, '${cx}x${cy}', #ffffffff): 0, 0
				}
			}
		");
		Assert.isTrue(success, "Bare loop variables in repeatable2d interpolation should parse");
	}

	@Test
	public function testInterpolationBareUndefinedVar() {
		var error = parseExpectingError("
			#test programmable(x:uint=5) {
				text(dd, '${oops}', #ffffffff): 0, 0
			}
		");
		Assert.notNull(error, "Bare undefined variable in interpolation should throw error");
		Assert.isTrue(error.indexOf("unknown variable") >= 0,
			'Error should mention unknown variable, got: $error');
		Assert.isTrue(error.indexOf("oops") >= 0,
			'Error should name the bad variable, got: $error');
	}

	@Test
	public function testInterpolationBareCallbackPreserved() {
		var success = parseExpectingSuccess("
			#test programmable(x:uint=5) {
				text(dd, '${callback(\"test\")}', #ffffffff): 0, 0
			}
		");
		Assert.isTrue(success, "callback keyword inside interpolation should be preserved");
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

	// ===== Tile parameter type tests =====

	@Test
	public function testTileParameterTypeParsesSuccessfully() {
		var success = parseExpectingSuccess('
			#test programmable(icon:tile) {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		');
		Assert.isTrue(success, "tile parameter type should parse successfully");
	}

	@Test
	public function testTileParameterCannotHaveDefault() {
		var error = parseExpectingError('
			#test programmable(icon:tile="something") {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for tile parameter with default value");
		Assert.isTrue(error.indexOf("cannot have a default") >= 0,
			'Error should mention tile cannot have default, got: $error');
	}

	@Test
	public function testTileParameterWithBitmapRef() {
		var success = parseExpectingSuccess('
			#test programmable(icon:tile) {
				bitmap($$icon): 0, 0
			}
		');
		Assert.isTrue(success, "tile parameter used as bitmap source via $$ref should parse");
	}

	@Test
	public function testMultipleTileParameters() {
		var success = parseExpectingSuccess('
			#test programmable(icon:tile, bg:tile, mode:[a,b]=a) {
				bitmap($$icon): 0, 0
				bitmap($$bg): 30, 0
			}
		');
		Assert.isTrue(success, "Multiple tile parameters should parse successfully");
	}

	// ===== Coordinate system & property access syntax tests =====

	@Test
	public function testCtxReservedAsParameterName() {
		var error = parseExpectingError('
			#test programmable(ctx:uint=0) {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for ctx as parameter name");
		Assert.stringContains("reserved", error);
	}

	@Test
	public function testGridPosParseSuccess() {
		var result = parseExpectingResult('
			#test programmable(n:uint=0) {
				grid: 20, 20
				bitmap(generated(color(10, 10, #f00))): $$grid.pos($$n, 0)
			}
		');
		Assert.notNull(result, "grid.pos() coordinate should parse");
		var node = result.nodes.get("test");
		Assert.notNull(node);
		Assert.isTrue(node.type.match(PROGRAMMABLE(_, _, _)), "should be PROGRAMMABLE");
		Assert.equals(1, node.children.length);
		Assert.isTrue(node.children[0].type.match(BITMAP(_, _, _)), "child should be BITMAP");
	}

	@Test
	public function testGridPosWithOffsetParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable(n:uint=0) {
				grid: 20, 20
				bitmap(generated(color(10, 10, #f00))): $$grid.pos($$n, 0, 5, 3)
			}
		');
		Assert.isTrue(success, "grid.pos() with offset should parse");
	}

	@Test
	public function testGridPropertyWidthParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable(n:uint=0) {
				grid: 20, 15
				bitmap(generated(color($$grid.width, $$grid.height, #f00))): 0, 0
			}
		');
		Assert.isTrue(success, "grid.width/height properties should parse");
	}

	@Test
	public function testHexCubeParseSuccess() {
		var result = parseExpectingResult('
			#test programmable(n:uint=0) {
				hex: pointy(16, 16)
				bitmap(generated(color(10, 10, #f00))): $$hex.cube(0, 0, 0)
			}
		');
		Assert.notNull(result, "hex.cube() coordinate should parse");
		var node = result.nodes.get("test");
		Assert.notNull(node);
		Assert.isTrue(node.type.match(PROGRAMMABLE(_, _, _)), "should be PROGRAMMABLE");
		Assert.equals(1, node.children.length);
		Assert.isTrue(node.children[0].type.match(BITMAP(_, _, _)), "child should be BITMAP");
	}

	@Test
	public function testHexCornerParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable(n:uint=0) {
				hex: pointy(16, 16)
				bitmap(generated(color(10, 10, #f00))): $$hex.corner($$n, 1.0)
			}
		');
		Assert.isTrue(success, "hex.corner() coordinate should parse");
	}

	@Test
	public function testHexEdgeParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable(n:uint=0) {
				hex: pointy(16, 16)
				bitmap(generated(color(10, 10, #f00))): $$hex.edge($$n, 0.5)
			}
		');
		Assert.isTrue(success, "hex.edge() coordinate should parse");
	}

	@Test
	public function testHexOffsetParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable(n:uint=0) {
				hex: pointy(16, 16)
				bitmap(generated(color(10, 10, #f00))): $$hex.offset($$n, 0, even)
			}
		');
		Assert.isTrue(success, "hex.offset() coordinate should parse");
	}

	@Test
	public function testHexDoubledParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable(n:uint=0) {
				hex: pointy(16, 16)
				bitmap(generated(color(10, 10, #f00))): $$hex.doubled($$n, 0)
			}
		');
		Assert.isTrue(success, "hex.doubled() coordinate should parse");
	}

	@Test
	public function testHexPixelParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable(n:uint=0) {
				hex: pointy(16, 16)
				bitmap(generated(color(10, 10, #f00))): $$hex.pixel(100, 200)
			}
		');
		Assert.isTrue(success, "hex.pixel() coordinate should parse");
	}

	@Test
	public function testHexWidthHeightParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color($$hex.width, $$hex.height, #f00))): 0, 0
			}
		');
		Assert.isTrue(success, "hex.width/height properties should parse");
	}

	@Test
	public function testNamedGridSystemParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable(n:uint=0) {
				grid: #small 10, 10
				grid: #big 40, 40
				bitmap(generated(color(10, 10, #f00))): $$small.pos($$n, 0)
				bitmap(generated(color(10, 10, #00f))): $$big.pos($$n, 0)
			}
		');
		Assert.isTrue(success, "Named grid coordinate systems should parse");
	}

	@Test
	public function testNamedHexSystemParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable(n:uint=0) {
				hex: #myHex pointy(16, 16)
				bitmap(generated(color(10, 10, #f00))): $$myHex.cube(0, 0, 0)
			}
		');
		Assert.isTrue(success, "Named hex coordinate system should parse");
	}

	@Test
	public function testMixedNamedSystemsParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable(n:uint=0) {
				grid: #g 20, 20
				hex: #h flat(12, 12)
				bitmap(generated(color(10, 10, #f00))): $$g.pos($$n, 0)
				bitmap(generated(color(10, 10, #00f))): $$h.cube(0, 0, 0)
			}
		');
		Assert.isTrue(success, "Mixed named grid+hex systems should parse");
	}

	@Test
	public function testCoordinateXYExtractionParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable(n:uint=0) {
				grid: 20, 15
				bitmap(generated(color($$grid.pos($$n, 0).x, $$grid.pos($$n, 0).y, #f00))): 0, 0
			}
		');
		Assert.isTrue(success, "Coordinate .x/.y extraction should parse");
	}

	@Test
	public function testHexCornerXYExtractionParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable(n:uint=0) {
				hex: pointy(16, 16)
				bitmap(generated(color($$hex.corner($$n, 1.0).x, $$hex.corner($$n, 1.0).y, #f00))): 0, 0
			}
		');
		Assert.isTrue(success, "Hex corner .x/.y extraction should parse");
	}

	@Test
	public function testCtxWidthHeightParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable() {
				bitmap(generated(color($$ctx.width, $$ctx.height, #f00))): 0, 0
			}
		');
		Assert.isTrue(success, "ctx.width/height properties should parse");
	}

	@Test
	public function testCtxRandomParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable() {
				bitmap(generated(color($$ctx.random(5, 20), 10, #f00))): 0, 0
			}
		');
		Assert.isTrue(success, "ctx.random() method should parse");
	}

	@Test
	public function testHexOffsetOddParseSuccess() {
		var success = parseExpectingSuccess('
			#test programmable(n:uint=0) {
				hex: flat(16, 16)
				bitmap(generated(color(10, 10, #f00))): $$hex.offset($$n, 0, odd)
			}
		');
		Assert.isTrue(success, "hex.offset() with odd parity should parse");
	}

	@Test
	public function testGridPosXYInExpressionValue() {
		// .x/.y extraction used in expression context (bitmap dimensions), not as position
		var success = parseExpectingSuccess('
			#test programmable(n:uint=0) {
				grid: 20, 15
				bitmap(generated(color($$grid.pos($$n, 0).x + 5, $$grid.pos($$n, 0).y + 3, #f00))): 0, 0
			}
		');
		Assert.isTrue(success, "grid.pos().x/y as expression values should parse");
	}

	// ===== Settings: dotted key parsing =====

	@Test
	public function testSettingsDottedKeyParses() {
		var success = parseExpectingSuccess('
			#test programmable() {
				placeholder(generated(cross(10, 10, white)), builderParameter("x")) {
					settings {
						item.fontColor: int => 0xff0000,
						scrollbar.thickness: int => 6
					}
				}
			}
		');
		Assert.isTrue(success, "Dotted setting keys should parse successfully");
	}

	@Test
	public function testSettingsDottedKeyWithStringType() {
		var success = parseExpectingSuccess('
			#test programmable() {
				placeholder(generated(cross(10, 10, white)), builderParameter("x")) {
					settings {
						item.font: string => "dd",
						panel.mode => "custom"
					}
				}
			}
		');
		Assert.isTrue(success, "Dotted setting keys with string type should parse");
	}

	@Test
	public function testSettingsMixedDottedAndPlain() {
		var success = parseExpectingSuccess('
			#test programmable() {
				placeholder(generated(cross(10, 10, white)), builderParameter("x")) {
					settings {
						buildName => "myBtn",
						width: int => 300,
						item.fontColor: int => 0xff0000
					}
				}
			}
		');
		Assert.isTrue(success, "Mixed dotted and plain setting keys should parse");
	}

	// ===== Layout align tests =====

	@Test
	public function testLayoutAlignCenterX() {
		var success = parseExpectingSuccess("
			layouts {
				#pos point: 100, 50 align: centerX
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): layout(pos)
			}
		");
		Assert.isTrue(success, "Layout align: centerX should parse");
	}

	@Test
	public function testLayoutAlignRightBottom() {
		var success = parseExpectingSuccess("
			layouts {
				#pos point: 10, 10 align: right, bottom
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): layout(pos)
			}
		");
		Assert.isTrue(success, "Layout align: right, bottom should parse");
	}

	@Test
	public function testLayoutAlignCenter() {
		var success = parseExpectingSuccess("
			layouts {
				#pos point: 0, 0 align: center
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): layout(pos)
			}
		");
		Assert.isTrue(success, "Layout align: center should parse");
	}

	@Test
	public function testLayoutAlignCenterY() {
		var success = parseExpectingSuccess("
			layouts {
				#pos point: 50, 0 align: centerY
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): layout(pos)
			}
		");
		Assert.isTrue(success, "Layout align: centerY should parse");
	}

	@Test
	public function testLayoutAlignOnCells() {
		var success = parseExpectingSuccess("
			layouts {
				#grid cells(cols: 3, rows: 2, cellWidth: 50, cellHeight: 50) align: right, bottom
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): layout(grid, 0)
			}
		");
		Assert.isTrue(success, "Layout align on cells should parse");
	}

	@Test
	public function testLayoutAlignOnSequence() {
		var success = parseExpectingSuccess("
			layouts {
				grid: 32, 32 {
					#slots sequence($i: 0..5) point: $i * 32, 0 align: centerX
				}
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): layout(slots, 0)
			}
		");
		Assert.isTrue(success, "Layout align on sequence should parse");
	}

	@Test
	public function testLayoutAlignOnList() {
		var success = parseExpectingSuccess("
			layouts {
				#pts list {
					point: 10, 10
					point: 20, 20
				} align: bottom
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): layout(pts, 0)
			}
		");
		Assert.isTrue(success, "Layout align on list should parse");
	}

	@Test
	public function testLayoutAlignNoAlign() {
		var success = parseExpectingSuccess("
			layouts {
				#pos point: 100, 50
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): layout(pos)
			}
		");
		Assert.isTrue(success, "Layout without align should parse");
	}

	@Test
	public function testLayoutAlignDuplicateX() {
		var error = parseExpectingError("
			layouts {
				#pos point: 10, 10 align: right, centerX
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): layout(pos)
			}
		");
		Assert.notNull(error, "Should throw error for duplicate X alignment");
		Assert.isTrue(error.indexOf("duplicate X alignment") >= 0,
			'Error should mention duplicate X alignment, got: $error');
	}

	@Test
	public function testLayoutAlignDuplicateY() {
		var error = parseExpectingError("
			layouts {
				#pos point: 10, 10 align: bottom, centerY
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): layout(pos)
			}
		");
		Assert.notNull(error, "Should throw error for duplicate Y alignment");
		Assert.isTrue(error.indexOf("duplicate Y alignment") >= 0,
			'Error should mention duplicate Y alignment, got: $error');
	}

	@Test
	public function testLayoutAlignCenterCombined() {
		var error = parseExpectingError("
			layouts {
				#pos point: 10, 10 align: center, right
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): layout(pos)
			}
		");
		Assert.notNull(error, "Should throw error for center combined with other values");
		Assert.isTrue(error.indexOf("center cannot be combined") >= 0,
			'Error should mention center cannot be combined, got: $error');
	}

	@Test
	public function testLayoutAlignCenterAfterOther() {
		var error = parseExpectingError("
			layouts {
				#pos point: 10, 10 align: right, center
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): layout(pos)
			}
		");
		Assert.notNull(error, "Should throw error for center after other align value");
		Assert.isTrue(error.indexOf("center cannot be combined") >= 0,
			'Error should mention center cannot be combined, got: $error');
	}

	// ===== .offset(x, y) suffix tests =====

	@Test
	public function testOffsetOnLayout() {
		var success = parseExpectingSuccess("
			layouts {
				#pos point: 10, 10
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): layout(pos).offset(5, 10)
			}
		");
		Assert.isTrue(success, "layout().offset() should parse successfully");
	}

	@Test
	public function testOffsetOnGridPos() {
		var success = parseExpectingSuccess("
			#test programmable() {
				grid: 32, 32
				bitmap(generated(color(10, 10, #f00))): " + "$" + "grid.pos(1, 2).offset(3, 4)
			}
		");
		Assert.isTrue(success, "grid.pos().offset() should parse successfully");
	}

	@Test
	public function testOffsetInvalidSuffix() {
		var error = parseExpectingError("
			layouts {
				#pos point: 10, 10
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): layout(pos).foo(1, 2)
			}
		");
		Assert.notNull(error, "Should throw error for unknown coordinate suffix");
		Assert.isTrue(error.indexOf("Unknown coordinate suffix") >= 0,
			'Error should mention unknown coordinate suffix, got: $error');
	}

	// ===== @(condition) #name — name after conditional =====

	@Test
	public function testConditionalBeforeNameParseSuccess() {
		var success = parseExpectingSuccess("
			#test programmable(mode:[on,off]=on) {
				@(mode=>on) #myElement bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		Assert.isTrue(success, "@(condition) #name element should parse");
	}

	@Test
	public function testConditionalBeforeNameWithUpdatable() {
		var success = parseExpectingSuccess("
			#test programmable(mode:[on,off]=on) {
				@(mode=>on) #myElement(updatable) bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		Assert.isTrue(success, "@(condition) #name(updatable) element should parse");
	}

	@Test
	public function testConditionalBeforeNameWithIndex() {
		var success = parseExpectingSuccess("
			#test programmable(mode:[on,off]=on, count:uint=3) {
				repeatable($i, step($count, dx: 20)) {
					@(mode=>on) #myElement[$i] bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		");
		Assert.isTrue(success, "@(condition) #name[$i] element should parse");
	}

	@Test
	public function testElseBeforeNameParseSuccess() {
		var success = parseExpectingSuccess("
			#test programmable(mode:[on,off]=on) {
				@(mode=>on) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else #fallback bitmap(generated(color(10, 10, #00f))): 0, 0
			}
		");
		Assert.isTrue(success, "@else #name element should parse");
	}

	@Test
	public function testDefaultBeforeNameParseSuccess() {
		var success = parseExpectingSuccess("
			#test programmable(mode:[on,off,other]=on) {
				@(mode=>on) bitmap(generated(color(10, 10, #f00))): 0, 0
				@default #fallback bitmap(generated(color(10, 10, #00f))): 0, 0
			}
		");
		Assert.isTrue(success, "@default #name element should parse");
	}

	@Test
	public function testConditionalBeforeNameWithAlphaScale() {
		var success = parseExpectingSuccess("
			#test programmable(mode:[on,off]=on) {
				@(mode=>on) @alpha(0.5) @scale(2) #myElement bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		Assert.isTrue(success, "@(condition) @alpha @scale #name element should parse");
	}

	// ===== @rotate parsing tests =====

	@Test
	public function testRotateInlinePrefix() {
		var success = parseExpectingSuccess("
			#test programmable() {
				@rotate(45) bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		Assert.isTrue(success, "@rotate(45) should parse");
	}

	@Test
	public function testRotateWithDegSuffix() {
		var success = parseExpectingSuccess("
			#test programmable() {
				@rotate(90deg) bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		Assert.isTrue(success, "@rotate(90deg) should parse");
	}

	@Test
	public function testRotatePropertySyntax() {
		var success = parseExpectingSuccess("
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))) {
					rotate: 45deg
					pos: 0, 0
				}
			}
		");
		Assert.isTrue(success, "rotate: 45deg property syntax should parse");
	}

	@Test
	public function testRotateCombinedWithAlphaScale() {
		var success = parseExpectingSuccess("
			#test programmable(mode:[on,off]=on) {
				@(mode=>on) @alpha(0.5) @scale(2) @rotate(90deg) #myElement bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		Assert.isTrue(success, "@(condition) @alpha @scale @rotate #name element should parse");
	}

	@Test
	public function testRotateWithDirectionConstant() {
		var success = parseExpectingSuccess("
			#test programmable() {
				@rotate(down) bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		Assert.isTrue(success, "@rotate(down) should parse");
	}

	// ===== Particles block error recovery tests =====

	@Test
	public function testParticlesUnexpectedTokenError() {
		var error = parseExpectingError('
			#test programmable() {
				#fx particles {
					count: 10
					[invalid]
				}
			}
		');
		Assert.notNull(error, "Should throw error for unexpected token in particles block");
		Assert.isTrue(error.indexOf("unexpected token") >= 0,
			'Error should mention unexpected token, got: $error');
	}

	@Test
	public function testParticlesValidBasicBlock() {
		var success = parseExpectingSuccess('
			#test programmable() {
				#fx particles {
					count: 50
					maxLife: 2.0
					speed: 100
					emit: point(dist: 0, distRand: 0)
					tiles: generated(color(4, 4, #ff0000))
				}
			}
		');
		Assert.isTrue(success, "Basic particles block should parse successfully");
	}

	// ===== Flow unexpected token error test =====

	@Test
	public function testFlowUnexpectedTokenError() {
		var error = parseExpectingError('
			#test programmable() {
				flow([invalid]) {
				}
			}
		');
		Assert.notNull(error, "Should throw error for unexpected token in flow parameters");
		Assert.stringContains("unexpected token", error);
	}

	@Test
	public function testConditionalBeforeNameDuplicateNameError() {
		var error = parseExpectingError("
			#test programmable(mode:[on,off]=on) {
				#outer @(mode=>on) #inner bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		Assert.notNull(error, "Should throw error when both #outer and #inner names provided");
		Assert.isTrue(error.indexOf("already has a name") >= 0,
			'Error should mention duplicate name, got: $error');
	}

	// ===== Particles renames: angle units =====

	@Test
	public function testParticlesAngleUnitDeg() {
		Assert.isTrue(parseExpectingSuccess("
			#test programmable() {
				point {
					pos: 0, 0
					particles {
						count: 10
						tiles: file(\"test.png\")
						gravityAngle: 90deg
						rotationSpeed: 45deg
						forwardAngle: 270deg
					}
				}
			}
		"), "Angle deg suffix should parse");
	}

	@Test
	public function testParticlesAngleUnitRad() {
		Assert.isTrue(parseExpectingSuccess("
			#test programmable() {
				point {
					pos: 0, 0
					particles {
						count: 10
						tiles: file(\"test.png\")
						gravityAngle: 1.57rad
					}
				}
			}
		"), "Angle rad suffix should parse");
	}

	@Test
	public function testParticlesAngleUnitTurn() {
		Assert.isTrue(parseExpectingSuccess("
			#test programmable() {
				point {
					pos: 0, 0
					particles {
						count: 10
						tiles: file(\"test.png\")
						gravityAngle: 0.25turn
					}
				}
			}
		"), "Angle turn suffix should parse");
	}

	@Test
	public function testParticlesDirectionConstants() {
		Assert.isTrue(parseExpectingSuccess("
			#test programmable() {
				point {
					pos: 0, 0
					particles {
						count: 10
						tiles: file(\"test.png\")
						gravityAngle: down
						forwardAngle: up
					}
				}
			}
		"), "Direction constants should parse");
	}

	@Test
	public function testParticlesDirectionWithOffset() {
		Assert.isTrue(parseExpectingSuccess("
			#test programmable() {
				point {
					pos: 0, 0
					particles {
						count: 10
						tiles: file(\"test.png\")
						gravityAngle: down + 10deg
					}
				}
			}
		"), "Direction with offset should parse");
	}

	// ===== Particles renames: property aliases =====

	@Test
	public function testParticlesAliases() {
		Assert.isTrue(parseExpectingSuccess("
			#test programmable() {
				point {
					pos: 0, 0
					particles {
						count: 10
						tiles: file(\"test.png\")
						lifeRand: 0.5
						sizeRand: 0.3
						speedRand: 0.2
						speedIncr: 5
						rotSpeed: 90
						rotSpeedRand: 10
						rotInitial: 45
						autoRotate: true
						delay: 0.1
						animRepeat: 2
					}
				}
			}
		"), "Property aliases should parse");
	}

	// ===== Particles renames: named emit parameters =====

	@Test
	public function testEmitNamedParams() {
		Assert.isTrue(parseExpectingSuccess("
			#test programmable() {
				point {
					pos: 0, 0
					particles {
						count: 10
						tiles: file(\"test.png\")
						emit: cone(dist: 50, distRand: 10, angle: right, angleSpread: 90deg)
					}
				}
			}
		"), "Named emit params should parse");
	}

	@Test
	public function testEmitBoxCenter() {
		Assert.isTrue(parseExpectingSuccess("
			#test programmable() {
				point {
					pos: 0, 0
					particles {
						count: 10
						tiles: file(\"test.png\")
						emit: box(w: 100, h: 100, center: true, angle: down, angleSpread: 45deg)
					}
				}
			}
		"), "Named emit box with center should parse");
	}

	// ===== Particles renames: bounds combined syntax =====

	@Test
	public function testBoundsCombined() {
		Assert.isTrue(parseExpectingSuccess("
			#test programmable() {
				point {
					pos: 0, 0
					particles {
						count: 10
						tiles: file(\"test.png\")
						bounds: kill, box(0, 0, 800, 600)
					}
				}
			}
		"), "Combined bounds syntax should parse");
	}

	@Test
	public function testBoundsCombinedNamed() {
		Assert.isTrue(parseExpectingSuccess("
			#test programmable() {
				point {
					pos: 0, 0
					particles {
						count: 10
						tiles: file(\"test.png\")
						bounds: bounce(0.6), box(x: -50, y: -50, w: 250, h: 250), line(0, 0, 100, 0)
					}
				}
			}
		"), "Combined bounds with named box and line should parse");
	}

	// ===== Particles renames: colorStops =====

	@Test
	public function testColorStops() {
		Assert.isTrue(parseExpectingSuccess("
			#test programmable() {
				point {
					pos: 0, 0
					particles {
						count: 10
						tiles: file(\"test.png\")
						colorStops: 0.0 #FF0000, 1.0 #0000FF
					}
				}
			}
		"), "Simple colorStops should parse");
	}

	@Test
	public function testColorStopsWithEasing() {
		Assert.isTrue(parseExpectingSuccess("
			#test programmable() {
				point {
					pos: 0, 0
					particles {
						count: 10
						tiles: file(\"test.png\")
						colorStops: 0.0 #FF4400, 0.5 #FFAA00 easeInQuad, 1.0 #FFFF88
					}
				}
			}
		"), "ColorStops with easing should parse");
	}

	// ===== Angle units in other contexts =====

	@Test
	public function testGraphicsArcAngleUnits() {
		Assert.isTrue(parseExpectingSuccess("
			#test programmable() {
				graphics(
					arc(#ff0000, filled, 50, 0deg, 90deg): 100, 100;
				): 0, 0
			}
		"), "Graphics arc with angle units should parse");
	}

	@Test
	public function testDropShadowAngleUnit() {
		Assert.isTrue(parseExpectingSuccess("
			#test programmable() {
				bitmap(generated(color(50, 50, #ff0000))): 0, 0
				filter: dropShadow(distance: 5, angle: 45deg, color: #000000, alpha: 0.5)
			}
		"), "DropShadow with angle unit should parse");
	}

	// ==================== Named range syntax ====================

	@Test
	public function testNamedRangeInclusiveParsesOk() {
		Assert.isTrue(parseExpectingSuccess('
			#test programmable() {
				repeatable($$i, range(from: 0, to: 5)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		'), "Named range with from/to should parse");
	}

	@Test
	public function testNamedRangeExclusiveParsesOk() {
		Assert.isTrue(parseExpectingSuccess('
			#test programmable() {
				repeatable($$i, range(from: 0, until: 5)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		'), "Named range with from/until should parse");
	}

	@Test
	public function testNamedRangeWithStepParsesOk() {
		Assert.isTrue(parseExpectingSuccess('
			#test programmable() {
				repeatable($$i, range(from: 0, to: 10, step: 2)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		'), "Named range with from/to/step should parse");
	}

	@Test
	public function testNamedRangeWithParamRefParsesOk() {
		Assert.isTrue(parseExpectingSuccess('
			#test programmable(n:uint=5) {
				repeatable($$i, range(from: 0, to: $$n)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		'), "Named range with param reference should parse");
	}

	@Test
	public function testNamedRangeInvalidEndKeyword() {
		final err = parseExpectingError('
			#test programmable() {
				repeatable($$i, range(from: 0, end: 5)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		');
		Assert.notNull(err, "Named range with invalid keyword 'end' should fail");
		Assert.isTrue(err.indexOf("to") >= 0 || err.indexOf("until") >= 0, 'Error should mention "to" or "until": $err');
	}

	@Test
	public function testNamedRangeInvalidStepKeyword() {
		final err = parseExpectingError('
			#test programmable() {
				repeatable($$i, range(from: 0, to: 10, stride: 2)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		');
		Assert.notNull(err, "Named range with invalid keyword 'stride' should fail");
		Assert.isTrue(err.indexOf("step") >= 0, 'Error should mention "step": $err');
	}

	@Test
	public function testNamedRangeNegativeStartParsesOk() {
		Assert.isTrue(parseExpectingSuccess('
			#test programmable() {
				repeatable($$i, range(from: -3, to: 3)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		'), "Named range with negative start should parse");
	}

	@Test
	public function testPositionalRangeWithStepParsesOk() {
		Assert.isTrue(parseExpectingSuccess('
			#test programmable() {
				repeatable($$i, range(0, 10, 3)) {
					bitmap(generated(color(10, 10, #f00))): 0, 0
				}
			}
		'), "Positional range with step should parse");
	}

	// ==================== Malformed expression tests ====================

	@Test
	public function testUnaryMinusWithoutValue() {
		var error = parseExpectingError('
			#test programmable(x:uint=10) {
				@final v = -
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for unary minus without value");
		Assert.isTrue(error.indexOf("expected value after unary minus") >= 0,
			'Error should mention unary minus, got: $error');
	}

	@Test
	public function testGarbageInNumericPosition() {
		var error = parseExpectingError('
			#test programmable() {
				bitmap(generated(color(abc, 10, #f00))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for non-numeric in numeric position");
		Assert.stringContains("expected integer", error);
	}

	@Test
	public function testMalformedTernaryMissingColon() {
		var error = parseExpectingError('
			#test programmable(big:bool=true) {
				@final size = ?($$big) 100
				bitmap(generated(color($$size, $$size, #f00))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for ternary missing colon/false branch");
		Assert.stringContains("Colon", error);
	}

	@Test
	public function testIncompleteArithmeticExpression() {
		var error = parseExpectingError('
			#test programmable(x:uint=10) {
				bitmap(generated(color($$x + , 10, #f00))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for incomplete arithmetic (trailing +)");
		Assert.stringContains("expected", error);
	}

	@Test
	public function testUnaryMinusWithoutValueInFloat() {
		var error = parseExpectingError('
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))) {
					pos: 0, 0
					alpha: -
				}
			}
		');
		Assert.notNull(error, "Should throw error for unary minus without value in float context");
		Assert.stringContains("unary minus", error);
	}

	// ==================== Invalid type tests ====================

	@Test
	public function testInvalidColorFormat() {
		var error = parseExpectingError('
			#test programmable() {
				bitmap(generated(color(10, 10, #GGGG))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for invalid color format");
		Assert.stringContains("Invalid color", error);
	}

	@Test
	public function testInvalidColorDigitCount() {
		var error = parseExpectingError('
			#test programmable() {
				bitmap(generated(color(10, 10, #FF00))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for color with wrong digit count");
		Assert.isTrue(error.indexOf("Invalid color") >= 0,
			'Error should mention invalid color, got: $error');
	}

	@Test
	public function testUnknownParameterType() {
		var error = parseExpectingError('
			#test programmable(x:foobar=1) {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for unknown parameter type");
		Assert.isTrue(error.indexOf("unknown parameter type") >= 0,
			'Error should mention unknown parameter type, got: $error');
	}

	@Test
	public function testInvalidBoolDefault() {
		var error = parseExpectingError('
			#test programmable(flag:bool=maybe) {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for invalid bool default");
		Assert.isTrue(error.indexOf("invalid bool default") >= 0,
			'Error should mention invalid bool default, got: $error');
	}

	@Test
	public function testInvalidFloatDefault() {
		var error = parseExpectingError('
			#test programmable(speed:float=abc) {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for invalid float default");
		Assert.isTrue(error.indexOf("expected float for default") >= 0,
			'Error should mention expected float, got: $error');
	}

	@Test
	public function testEnumDefaultNotInValues() {
		var error = parseExpectingError('
			#test programmable(mode:[a,b]=c) {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for enum default not in values");
		Assert.isTrue(error.indexOf("does not contain value") >= 0,
			'Error should mention value not in enum, got: $error');
	}

	@Test
	public function testUnknownFilterType() {
		var error = parseExpectingError('
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))) {
					filter: notAFilter(1)
					pos: 0, 0
				}
			}
		');
		Assert.notNull(error, "Should throw error for unknown filter type");
		Assert.isTrue(error.indexOf("unknown filter type") >= 0,
			'Error should mention unknown filter type, got: $error');
	}

	@Test
	public function testUnknownGeneratedTileType() {
		var error = parseExpectingError('
			#test programmable() {
				bitmap(generated(hexagon(10, 10, #f00))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for unknown generated tile type");
		Assert.isTrue(error.indexOf("unknown generated tile type") >= 0,
			'Error should mention unknown generated tile type, got: $error');
	}

	// ==================== Duplicate tests (additional) ====================

	@Test
	public function testDuplicateRootNodeName() {
		var error = parseExpectingError('
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): 0, 0
			}
			#test programmable() {
				bitmap(generated(color(10, 10, #00f))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for duplicate root node #name");
		Assert.isTrue(error.indexOf("duplicate node") >= 0,
			'Error should mention duplicate node, got: $error');
	}

	@Test
	public function testDuplicateSettingKey() {
		var error = parseExpectingError('
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): 0, 0
				settings {
					buildName => "test"
					buildName => "test2"
				}
			}
		');
		Assert.notNull(error, "Should throw error for duplicate setting key");
		Assert.isTrue(error.indexOf("already defined") >= 0,
			'Error should mention already defined, got: $error');
	}

	// ==================== Circular / self-reference tests ====================

	@Test
	public function testFinalSelfReference() {
		// @final referencing itself — should fail at parse or build time
		var error = parseExpectingError('
			#test programmable() {
				@final x = $$x + 1
				bitmap(generated(color($$x, $$x, #f00))): 0, 0
			}
		');
		// The parser's variable validation should catch $$x as undefined at this point
		Assert.notNull(error, "Should throw error for @final self-reference");
		Assert.isTrue(error.indexOf("unknown variable") >= 0,
			'Error should mention unknown variable, got: $error');
	}

	@Test
	public function testFinalForwardReference() {
		// @final referencing a later @final — $$y is not yet defined when $$x is parsed
		var error = parseExpectingError('
			#test programmable() {
				@final x = $$y + 1
				@final y = 10
				bitmap(generated(color($$x, $$x, #f00))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for @final forward reference");
		Assert.isTrue(error.indexOf("unknown variable") >= 0,
			'Error should mention unknown variable, got: $error');
	}

	@Test
	public function testUndefinedRefInExpression() {
		var error = parseExpectingError('
			#test programmable(x:uint=10) {
				bitmap(generated(color($$y, 10, #f00))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for undefined $$y reference");
		Assert.isTrue(error.indexOf("unknown variable") >= 0,
			'Error should mention unknown variable, got: $error');
	}

	@Test
	public function testUndefinedRefInFinalExpression() {
		var error = parseExpectingError('
			#test programmable(x:uint=10) {
				@final v = $$x + $$z
				bitmap(generated(color($$v, 10, #f00))): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for undefined $$z in @final");
		Assert.isTrue(error.indexOf("unknown variable") >= 0,
			'Error should mention unknown variable, got: $error');
	}

	// ===== Rich text markup tests =====

	@Test
	public function testRichTextStylesColorOnly() {
		var success = parseExpectingSuccess('
			#test programmable() {
				richText(dd, "hello [damage]world[/]", white, left, 200,
					styles: {damage: color(#FF0000)}): 0, 0
			}
		');
		Assert.isTrue(success, "styles with color() should parse");
	}

	@Test
	public function testRichTextStylesFontOnly() {
		var success = parseExpectingSuccess('
			#test programmable() {
				richText(dd, "hello [em]world[/]", white, left, 200,
					styles: {em: font("dd")}): 0, 0
			}
		');
		Assert.isTrue(success, "styles with font() only should parse");
	}

	@Test
	public function testRichTextStylesColorAndFont() {
		var success = parseExpectingSuccess('
			#test programmable() {
				richText(dd, "hello [gold]100g[/]", white, left, 200,
					styles: {gold: color(#FFD700) font("dd")}): 0, 0
			}
		');
		Assert.isTrue(success, "styles with color() and font() should parse");
	}

	@Test
	public function testRichTextStylesMultiple() {
		var success = parseExpectingSuccess('
			#test programmable() {
				richText(dd, "[a]x[/] [b]y[/] [c]z[/]", white, left, 200,
					styles: {a: color(#FF0000), b: color(#00FF00) font("dd"), c: font("dd")}): 0, 0
			}
		');
		Assert.isTrue(success, "multiple styles should parse");
	}

	@Test
	public function testRichTextStylesNamedColor() {
		var success = parseExpectingSuccess('
			#test programmable() {
				richText(dd, "[fire]flames[/]", white, left, 200,
					styles: {fire: color(red)}): 0, 0
			}
		');
		Assert.isTrue(success, "styles with named color should parse");
	}

	@Test
	public function testRichTextStyleNoColorNoFont() {
		var error = parseExpectingError('
			#test programmable() {
				richText(dd, "hello", white, left, 200,
					styles: {bad: }): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for style with no color() or font()");
		Assert.stringContains("color()", error);
	}

	@Test
	public function testRichTextUnknownStyleRef() {
		var error = parseExpectingError('
			#test programmable() {
				richText(dd, "hello [unknown]world[/]", white, left, 200,
					styles: {damage: color(#FF0000)}): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for unknown style reference");
		Assert.isTrue(error.indexOf("unknown style") >= 0,
			'Error should mention unknown style, got: $error');
	}


	@Test
	public function testRichTextImageParses() {
		var success = parseExpectingSuccess('
			#test programmable() {
				richText(dd, "Cost [img:coin] 100", white, left, 200,
					images: {coin: generated(color(14, 14, #FFD700))}): 0, 0
			}
		');
		Assert.isTrue(success, "image markup should parse");
	}

	@Test
	public function testRichTextAlignParses() {
		var success = parseExpectingSuccess('
			#test programmable() {
				richText(dd, "left\n[align:center]center[/]", white, left, 200): 0, 0
			}
		');
		Assert.isTrue(success, "align markup should parse");
	}

	@Test
	public function testRichTextLinkParses() {
		var success = parseExpectingSuccess('
			#test programmable() {
				richText(dd, "[link:shop]click[/]", white, left, 200): 0, 0
			}
		');
		Assert.isTrue(success, "link markup should parse");
	}

	@Test
	public function testRichTextCondenseWhiteParses() {
		var success = parseExpectingSuccess('
			#test programmable() {
				richText(dd, "spaces   here", white, left, 200, condenseWhite: true): 0, 0
			}
		');
		Assert.isTrue(success, "condenseWhite should parse");
	}

	@Test
	public function testRichTextNestingParses() {
		var success = parseExpectingSuccess('
			#test programmable() {
				richText(dd, "[damage]crit [highlight]50[/] dmg[/]", white, left, 200,
					styles: {damage: color(#FF0000), highlight: color(yellow)}): 0, 0
			}
		');
		Assert.isTrue(success, "nested markup should parse");
	}

	@Test
	public function testPlainTextParses() {
		var success = parseExpectingSuccess('
			#test programmable() {
				text(dd, "plain text no markup", white, left, 200): 0, 0
			}
		');
		Assert.isTrue(success, "plain text should parse");
	}

	@Test
	public function testTextRejectsStyles() {
		var error = parseExpectingError('
			#test programmable() {
				text(dd, "hello", white, left, 200,
					styles: {warn: color(#FF0000)}): 0, 0
			}
		');
		Assert.notNull(error, "text() should reject styles");
		Assert.isTrue(error.indexOf("richText") >= 0,
			'Error should mention richText(), got: $error');
	}

	@Test
	public function testTextRejectsImages() {
		var error = parseExpectingError('
			#test programmable() {
				text(dd, "hello", white, left, 200,
					images: {coin: generated(color(14, 14, #FFD700))}): 0, 0
			}
		');
		Assert.notNull(error, "text() should reject images");
		Assert.isTrue(error.indexOf("richText") >= 0,
			'Error should mention richText(), got: $error');
	}

	@Test
	public function testTextRejectsCondenseWhite() {
		var error = parseExpectingError('
			#test programmable() {
				text(dd, "hello", white, left, 200, condenseWhite: true): 0, 0
			}
		');
		Assert.notNull(error, "text() should reject condenseWhite");
		Assert.isTrue(error.indexOf("richText") >= 0,
			'Error should mention richText(), got: $error');
	}

	@Test
	public function testRichTextStylesBracketSyntaxFails() {
		var error = parseExpectingError('
			#test programmable() {
				richText(dd, "hello", white, left, 200,
					styles: [damage #FF0000]): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for bracket syntax on styles");
		Assert.stringContains("expected", error);
	}

	@Test
	public function testRichTextOldStyleSyntaxFails() {
		var error = parseExpectingError('
			#test programmable() {
				richText(dd, "[warn]Warning[/]", white, left, 200,
					styles: {warn: #FF4444}): 0, 0
			}
		');
		Assert.notNull(error, "Should throw error for old style syntax (bare color without color())");
		Assert.stringContains("color()", error);
	}

	@Test
	public function testRichTextStylesMultipleColors() {
		var success = parseExpectingSuccess('
			#test programmable() {
				richText(dd, "[warn]Warning:[/] costs [price]100g[/]", white, left, 200,
					styles: {warn: color(#FF4444), price: color(gold)}): 0, 0
			}
		');
		Assert.isTrue(success, "styles with color() function should parse");
	}

	// ===== Coordinate system negative tests =====

	@Test
	public function testGridUnknownMethod() {
		var error = parseExpectingError('
			#test programmable() {
				grid: 20, 20
				bitmap(generated(color(10, 10, #f00))): $$grid.invalid(0, 0)
			}
		');
		Assert.notNull(error, "Should throw error for unknown grid method");
		Assert.stringContains("Unknown grid method", error);
	}

	@Test
	public function testHexUnknownMethod() {
		var error = parseExpectingError('
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color(10, 10, #f00))): $$hex.invalid(0, 0)
			}
		');
		Assert.notNull(error, "Should throw error for unknown hex method");
		Assert.stringContains("Unknown hex method", error);
	}

	@Test
	public function testUnknownCoordinateSystem() {
		var error = parseExpectingError('
			#test programmable() {
				bitmap(generated(color(10, 10, #f00))): $$unknown.pos(0, 0)
			}
		');
		Assert.notNull(error, "Should throw error for unknown coordinate system");
		Assert.isTrue(error.indexOf("unknown") >= 0,
			'Error should mention the unknown coordinate system, got: $$error');
	}

	@Test
	public function testGridNotOnRoot() {
		var error = parseExpectingError('
			grid: 20, 20
		');
		Assert.notNull(error, "Should throw error for grid on root level");
		Assert.stringContains("grid not supported on root", error);
	}

	@Test
	public function testHexNotOnRoot() {
		var error = parseExpectingError('
			hex: pointy(16, 16)
		');
		Assert.notNull(error, "Should throw error for hex on root level");
		Assert.stringContains("hex not supported on root", error);
	}

	@Test
	public function testUnknownHexChainMethod() {
		var error = parseExpectingError('
			#test programmable() {
				hex: pointy(16, 16)
				bitmap(generated(color(10, 10, #f00))): $$hex.cube(1, 0, -1).invalid(0, 1)
			}
		');
		Assert.notNull(error, "Should throw error for unknown hex chain method");
		Assert.isTrue(error.indexOf("invalid") >= 0 || error.indexOf("unknown") >= 0 || error.indexOf("Unknown") >= 0,
			'Error should mention the unknown method, got: $$error');
	}

	// ===== @ifstrict error cases =====

	@Test
	public function testIfstrictParseSuccess() {
		var success = parseExpectingSuccess("
			#test programmable(status:[idle,hover]=idle) {
				@ifstrict(status=>hover) bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		Assert.isTrue(success, "@ifstrict should parse successfully");
	}

	@Test
	public function testIfstrictWithElse() {
		var success = parseExpectingSuccess("
			#test programmable(status:[idle,hover]=idle) {
				@ifstrict(status=>hover) bitmap(generated(color(10, 10, #f00))): 0, 0
				@else bitmap(generated(color(20, 20, #00f))): 0, 0
			}
		");
		Assert.isTrue(success, "@ifstrict with @else should parse successfully");
	}

	@Test
	public function testIfstrictMissingParen() {
		var error = parseExpectingError("
			#test programmable(status:[idle,hover]=idle) {
				@ifstrict bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		Assert.notNull(error, "Should throw error for @ifstrict without parens");
		Assert.isTrue(error.indexOf("(") >= 0 || error.indexOf("expected") >= 0 || error.indexOf("paren") >= 0,
			'Error should mention expected parenthesis, got: $$error');
	}

	@Test
	public function testIfstrictUnknownParam() {
		var error = parseExpectingError("
			#test programmable(status:[idle,hover]=idle) {
				@ifstrict(unknown=>value) bitmap(generated(color(10, 10, #f00))): 0, 0
			}
		");
		Assert.notNull(error, "Should throw error for @ifstrict with undefined parameter");
		Assert.isTrue(error.indexOf("unknown") >= 0 || error.indexOf("Unknown") >= 0 || error.indexOf("param") >= 0,
			'Error should mention the unknown parameter, got: $$error');
	}

	// ===== import statement error cases =====

	@Test
	public function testImportMissingAs() {
		var error = parseExpectingError('
			import "file.manim"
		');
		Assert.notNull(error, "Should throw error for import without as");
		Assert.isTrue(error.indexOf("as") >= 0 || error.indexOf("expected") >= 0 || error.indexOf("import") >= 0,
			'Error should mention expected "as" keyword, got: $$error');
	}

	@Test
	public function testImportMissingFilename() {
		var error = parseExpectingError('
			import as "name"
		');
		Assert.notNull(error, "Should throw error for import without filename");
		Assert.isTrue(error.indexOf("expected") >= 0 || error.indexOf("filename") >= 0 || error.indexOf("import") >= 0 || error.indexOf("string") >= 0,
			'Error should mention expected filename, got: $$error');
	}

	@Test
	public function testImportFileNotFound() {
		var error = parseExpectingError('
			import "nonexistent-file.manim" as "ext"
		');
		Assert.notNull(error, "Should throw error for import with missing file");
		Assert.isTrue(error.indexOf("nonexistent") >= 0 || error.indexOf("import") >= 0 || error.indexOf("load") >= 0 || error.indexOf("not found") >= 0 || error.indexOf("file") >= 0,
			'Error should mention the file not found, got: $error');
	}
}
