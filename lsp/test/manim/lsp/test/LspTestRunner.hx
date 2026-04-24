package manim.lsp.test;

/**
 * LSP unit test runner. Runs all test suites and reports results.
 * Compiles to JS and runs via Node.js.
 */
class LspTestRunner {
	static var passed = 0;
	static var failed = 0;
	static var currentSuite = "";

	public static function main():Void {
		trace("=== LSP Unit Tests ===\n");

		ManimAnalyzerTest.run();
		ContextAnalyzerTest.run();
		AnimAnalyzerTest.run();

		trace('\n=== Results: $passed passed, $failed failed ===');
		if (failed > 0) {
			js.Syntax.code("process.exit(1)");
		}
	}

	public static function suite(name:String):Void {
		currentSuite = name;
		trace('--- $name ---');
	}

	public static function assert(condition:Bool, message:String):Void {
		if (condition) {
			passed++;
		} else {
			failed++;
			trace('  FAIL: [$currentSuite] $message');
		}
	}

	public static function assertEqual<T>(actual:T, expected:T, message:String):Void {
		if (actual == expected) {
			passed++;
		} else {
			failed++;
			trace('  FAIL: [$currentSuite] $message — expected "$expected", got "$actual"');
		}
	}

	public static function assertGreater(actual:Int, min:Int, message:String):Void {
		if (actual > min) {
			passed++;
		} else {
			failed++;
			trace('  FAIL: [$currentSuite] $message — expected > $min, got $actual');
		}
	}
}
