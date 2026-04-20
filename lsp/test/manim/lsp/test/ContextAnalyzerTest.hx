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
