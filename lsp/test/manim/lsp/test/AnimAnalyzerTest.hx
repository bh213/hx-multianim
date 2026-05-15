package manim.lsp.test;

import manim.lsp.AnimAnalyzer;
import manim.lsp.LspTypes;

class AnimAnalyzerTest {
	public static function run():Void {
		LspTestRunner.suite("AnimAnalyzer");

		testValidFileNoDiagnostics();
		testMissingBraceDiagnostic();
		testMissingAnimNameDiagnostic();
		testSymbols();
		testCompletions();
		testHover();
	}

	static function testValidFileNoDiagnostics():Void {
		final text = "sheet: hero\nstates: facing(left, right)\nanimation idle {\n\tfps: 10\n\tloop: yes\n\tplaylist {\n\t\tsheet: \"hero_idle\"\n\t}\n}";
		final diags = AnimAnalyzer.getDiagnostics(text, "test.anim");
		LspTestRunner.assertEqual(diags.length, 0, "Valid .anim produces no diagnostics");
	}

	static function testMissingBraceDiagnostic():Void {
		// Missing opening brace — parser expects { after animation name
		final text = "animation idle\n\tplaylist\n";
		final diags = AnimAnalyzer.getDiagnostics(text, "test.anim");
		LspTestRunner.assertGreater(diags.length, 0, "Missing brace produces diagnostic");
	}

	static function testMissingAnimNameDiagnostic():Void {
		final text = "animation {\n}\n";
		final diags = AnimAnalyzer.getDiagnostics(text, "test.anim");
		LspTestRunner.assertGreater(diags.length, 0, "Missing animation name produces diagnostic");
	}

	static function testSymbols():Void {
		final text = "sheet: hero\nstates: facing(left, right)\n@final OFFSET_X = 5\nanimation idle {\n\tfps: 10\n}\nanim walk(fps:20): \"hero_walk\"\nmetadata {\n\thealth: 100\n}";
		final syms = AnimAnalyzer.getSymbols(text, "test.anim");

		var foundIdle = false;
		var foundWalk = false;
		var foundMeta = false;
		var foundStates = false;
		var foundFinal = false;
		for (s in syms) {
			if (s.name == "idle" && s.kind == SymbolKind.Function) foundIdle = true;
			if (s.name == "walk" && s.kind == SymbolKind.Function) foundWalk = true;
			if (s.name == "metadata" && s.kind == SymbolKind.Struct) foundMeta = true;
			if (s.name == "facing" && s.kind == SymbolKind.Variable) foundStates = true;
			if (s.name == "OFFSET_X" && s.kind == SymbolKind.Constant) foundFinal = true;
		}
		LspTestRunner.assert(foundIdle, "Symbol: animation 'idle' found");
		LspTestRunner.assert(foundWalk, "Symbol: anim 'walk' found");
		LspTestRunner.assert(foundMeta, "Symbol: metadata block found");
		LspTestRunner.assert(foundStates, "Symbol: states declaration 'facing' found");
		LspTestRunner.assert(foundFinal, "Symbol: @final 'OFFSET_X' found");
	}

	static function testCompletions():Void {
		final text = "";
		final items = AnimAnalyzer.getCompletions(text, 0, 0);
		LspTestRunner.assertGreater(items.length, 0, "Top-level .anim completions returned");

		var hasAnimation = false;
		var hasSheet = false;
		for (item in items) {
			if (item.label == "animation") hasAnimation = true;
			if (item.label == "sheet") hasSheet = true;
		}
		LspTestRunner.assert(hasAnimation, "Top-level completions include 'animation'");
		LspTestRunner.assert(hasSheet, "Top-level completions include 'sheet'");
	}

	static function testHover():Void {
		final text = "animation idle {\n}";
		final hover = AnimAnalyzer.getHover(text, "test.anim", 0, 3);
		LspTestRunner.assert(hover != null, "Hover returned for 'animation' keyword");
	}
}
