package manim.lsp.test;

import manim.lsp.ContextAnalyzer;

class ContextAnalyzerTest {
	public static function run():Void {
		LspTestRunner.suite("ContextAnalyzer");

		testTopLevel();
		testProgrammableBody();
		testParticlesBody();
		testAfterDollar();
		testAfterAt();
		testParamsWithDocCommentsAndEnums();
		testParamsOfAnEarlierProgrammableAreOutOfScope();
		testASlotBodySeesOnlyItsOwnParams();
		testKeywordsMatchInAnyCase();
	}

	static function analyzeAtEnd(text:String):CursorContextResult {
		final lines = text.split("\n");
		return ContextAnalyzer.analyze(text, lines.length - 1, lines[lines.length - 1].length);
	}

	static function testParamsOfAnEarlierProgrammableAreOutOfScope():Void {
		final ctx = analyzeAtEnd("version: 1.0\n#a programmable(first:int=0) {\n}\n#b programmable(second:int=0) {\n\tbitmap(generated(color($");
		LspTestRunner.assertEqual(ctx.paramNames.join(","), "second", "Only the enclosing programmable's params are in scope");
		LspTestRunner.assertEqual(ctx.paramTypes.get("first"), null, "An earlier programmable's param has no type here");
	}

	static function testASlotBodySeesOnlyItsOwnParams():Void {
		final inSlot = analyzeAtEnd("version: 1.0\n#a programmable(outer:int=0) {\n\t#s slot(inner:int=0) {\n\t\tbitmap(generated(color($");
		LspTestRunner.assertEqual(inSlot.paramNames.join(","), "inner", "A slot body sees its own params, not the programmable's");
		final afterSlot = analyzeAtEnd("version: 1.0\n#a programmable(outer:int=0) {\n\t#s slot(inner:int=0) {\n\t}\n\tbitmap(generated(color($");
		LspTestRunner.assertEqual(afterSlot.paramNames.join(","), "outer", "After the slot closes the programmable's params are back");
	}

	static function testKeywordsMatchInAnyCase():Void {
		final ctx = analyzeAtEnd("version: 1.0\n#a Programmable(p:int=0) {\n\t");
		LspTestRunner.assertEqual(ctx.paramNames.join(","), "p", "Programmable( declares params, as the parser reads it");
		LspTestRunner.assertEqual(ctx.context, ProgrammableBody, "Inside a Programmable( body");
		final path = analyzeAtEnd("version: 1.0\n#ap animatedpath {\n\t");
		LspTestRunner.assertEqual(path.context, AnimatedPathBody, "Inside an animatedpath body");
	}

	static function testParamsWithDocCommentsAndEnums():Void {
		// `///` docs (with commas) and an enum's choices are no parameters of their own
		final text = "version: 1.0\n#k export programmable(\n\t/// what it does, idle or walking\n\tstate:[idle, /// stands, still\n\t\twalk] = idle, /// trails, with commas\n\tlabel:string = \"a, b\",\n\thp:int = 0\n) {\n\tbitmap(generated(color($";
		final lines = text.split("\n");
		final ctx = ContextAnalyzer.analyze(text, lines.length - 1, lines[lines.length - 1].length);
		LspTestRunner.assertEqual(ctx.paramNames.join(","), "state,label,hp", "Params of an exported programmable with doc comments, an enum and a string with commas");
		LspTestRunner.assertEqual(ctx.paramTypes.get("state"), "[idle, \n\t\twalk]", "The enum's whole type, its doc comment left out");
	}

	static function testTopLevel():Void {
		final text = "version: 1.0\n";
		final ctx = ContextAnalyzer.analyze(text, 1, 0);
		LspTestRunner.assertEqual(ctx.context, TopLevel, "Empty line after version is TopLevel");
	}

	static function testProgrammableBody():Void {
		final text = "version: 1.0\n#test programmable() {\n\t\n}";
		final ctx = ContextAnalyzer.analyze(text, 2, 1);
		LspTestRunner.assertEqual(ctx.context, ProgrammableBody, "Inside programmable body");
	}

	static function testParticlesBody():Void {
		final text = "version: 1.0\n#test programmable() {\n\t#fx particles {\n\t\t\n\t}\n}";
		final ctx = ContextAnalyzer.analyze(text, 3, 2);
		LspTestRunner.assertEqual(ctx.context, ParticlesBody, "Inside particles body");
	}

	static function testAfterDollar():Void {
		final text = "version: 1.0\n#test programmable(myParam:int=0) {\n\tbitmap(generated(color($";
		final ctx = ContextAnalyzer.analyze(text, 2, 31);
		final isAfterDollar = switch (ctx.context) {
			case AfterDollar(_): true;
			default: false;
		};
		LspTestRunner.assert(isAfterDollar, "After $ is AfterDollar context");
	}

	static function testAfterAt():Void {
		final text = "version: 1.0\n#test programmable(myParam:int=0) {\n\t@";
		final ctx = ContextAnalyzer.analyze(text, 2, 2);
		LspTestRunner.assertEqual(ctx.context, AfterAt, "After @ is AfterAt context");
	}
}
