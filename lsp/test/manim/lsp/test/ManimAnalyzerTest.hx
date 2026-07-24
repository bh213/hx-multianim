package manim.lsp.test;

import manim.lsp.ManimAnalyzer;
import manim.lsp.LspTypes;

class ManimAnalyzerTest {
	public static function run():Void {
		LspTestRunner.suite("ManimAnalyzer");

		testValidFileNoDiagnostics();
		testInvalidFileDiagnostics();
		testSymbols();
		testCompletions();
		testReferenceCompletionLabels();
		testPathCompletionsSuggestOnlyParserKeywords();
		testHover();
		testDefinition();
		testDataEnumSymbols();
	}

	static function testValidFileNoDiagnostics():Void {
		final text = "version: 1.0\n#test programmable(status:[normal,hover]=normal) {\n\tbitmap(generated(color(10, 10, #FF0000))): 0, 0\n}";
		final diags = ManimAnalyzer.getDiagnostics(text, "test.manim");
		LspTestRunner.assertEqual(diags.length, 0, "Valid .manim produces no diagnostics");
	}

	static function testInvalidFileDiagnostics():Void {
		final text = "version: 1.0\n#test programmable() {\n\tunknownElement(\n}";
		final diags = ManimAnalyzer.getDiagnostics(text, "test.manim");
		LspTestRunner.assertGreater(diags.length, 0, "Invalid .manim produces diagnostics");
		LspTestRunner.assertEqual(diags[0].severity, DiagnosticSeverity.Error, "Diagnostic is error severity");
	}

	static function testSymbols():Void {
		final text = "version: 1.0\n#myWidget programmable(count:int=0) {\n\tbitmap(generated(color(10, 10, #FF0000))): 0, 0\n}\n#myData data {\n\tkey: 42\n}\n@final MAX_SIZE = 100";
		final syms = ManimAnalyzer.getSymbols(text, "test.manim");
		LspTestRunner.assertGreater(syms.length, 0, "Symbols extracted from valid .manim");

		var foundProg = false;
		var foundData = false;
		var foundFinal = false;
		for (s in syms) {
			if (s.name == "myWidget" && s.kind == SymbolKind.Class) foundProg = true;
			if (s.name == "myData" && s.kind == SymbolKind.Struct) foundData = true;
			if (s.name == "MAX_SIZE" && s.kind == SymbolKind.Constant) foundFinal = true;
		}
		LspTestRunner.assert(foundProg, "Symbol: programmable 'myWidget' found as Class");
		LspTestRunner.assert(foundData, "Symbol: data 'myData' found as Struct");
		LspTestRunner.assert(foundFinal, "Symbol: @final 'MAX_SIZE' found as Constant");
	}

	static function testCompletions():Void {
		final text = "version: 1.0\n";
		final items = ManimAnalyzer.getCompletions(text, 1, 0);
		LspTestRunner.assertGreater(items.length, 0, "Top-level completions returned");

		var hasProgrammable = false;
		for (item in items) {
			if (item.label == "programmable") hasProgrammable = true;
		}
		LspTestRunner.assert(hasProgrammable, "Top-level completions include 'programmable'");
	}

	static function testReferenceCompletionLabels():Void {
		// Each declared parameter must complete as "$<paramName>". A string-
		// interpolation escape bug ('$$name' == literal "$name") once labeled
		// every parameter completion with the same literal string.
		final text = "version: 1.0\n#w programmable(hp:int=0, mode:[a,b]=a) {\n\tbitmap(generated(color($";
		final lines = text.split("\n");
		final items = ManimAnalyzer.getCompletions(text, 2, lines[2].length);
		LspTestRunner.assertGreater(items.length, 0, "Reference completions returned after '$'");

		var hasHp = false;
		var hasMode = false;
		var hasLiteralName = false;
		for (item in items) {
			if (item.label == "$hp") hasHp = true;
			if (item.label == "$mode") hasMode = true;
			if (item.label == "$name") hasLiteralName = true;
		}
		LspTestRunner.assert(hasHp, "Reference completions include '$hp' for param hp");
		LspTestRunner.assert(hasMode, "Reference completions include '$mode' for param mode");
		LspTestRunner.assert(!hasLiteralName, "No completion may carry the literal label '$name'");
	}

	static function testPathCompletionsSuggestOnlyParserKeywords():Void {
		// Every suggested path command must be accepted by the parser.
		// "quadratic" is not a parser keyword — quadratic curves are the
		// 2-point form of bezier(...).
		final text = "version: 1.0\npaths {\n\t\n}";
		final items = ManimAnalyzer.getCompletions(text, 2, 1);
		LspTestRunner.assertGreater(items.length, 0, "Path completions returned inside paths block");

		var hasQuadratic = false;
		var hasBezier = false;
		for (item in items) {
			if (item.label == "quadratic") hasQuadratic = true;
			if (item.label == "bezier") hasBezier = true;
		}
		LspTestRunner.assert(hasBezier, "Path completions include 'bezier'");
		LspTestRunner.assert(!hasQuadratic, "'quadratic' is not parseable and must not be suggested");
	}

	static function testHover():Void {
		final text = "version: 1.0\nprogrammable";
		final hover = ManimAnalyzer.getHover(text, "test.manim", 1, 5);
		LspTestRunner.assert(hover != null, "Hover returned for 'programmable' keyword");
	}

	static function testDataEnumSymbols():Void {
		final text = 'version: 1.0\n#items data {\n\t#rarity enum(common, rare, legendary)\n\t#stats record(hp:int, atk:int)\n\tname: "sword"\n\tgrade: rarity common\n}';
		final diags = ManimAnalyzer.getDiagnostics(text, "test.manim");
		LspTestRunner.assertEqual(diags.length, 0, "Data block with enum produces no diagnostics");

		final syms = ManimAnalyzer.getSymbols(text, "test.manim");
		var foundData = false;
		var foundEnum = false;
		var foundRecord = false;
		var foundField = false;
		for (s in syms) {
			if (s.name == "items" && s.kind == SymbolKind.Struct) {
				foundData = true;
				if (s.children != null) {
					for (c in s.children) {
						if (c.name == "#rarity" && c.kind == SymbolKind.Enum) foundEnum = true;
						if (c.name == "#stats" && c.kind == SymbolKind.Struct) foundRecord = true;
						if (c.name == "name" && c.kind == SymbolKind.Field) foundField = true;
					}
				}
			}
		}
		LspTestRunner.assert(foundData, "Symbol: data 'items' found");
		LspTestRunner.assert(foundEnum, "Symbol: enum '#rarity' found as child of data");
		LspTestRunner.assert(foundRecord, "Symbol: record '#stats' found as child of data");
		LspTestRunner.assert(foundField, "Symbol: field 'name' found as child of data");
	}

	static function testDefinition():Void {
		final text = "version: 1.0\n#test programmable(myParam:int=0) {\n\tbitmap(generated(color(10, 10, #FF0000))): 0, 0\n}";
		// Try go-to-definition — should not crash
		final loc = ManimAnalyzer.getDefinition(text, "test.manim", 2, 29);
		LspTestRunner.assert(true, "Definition lookup does not crash");
	}
}
