# Testing, Debugging & Pitfalls

## Adding a New Test

Visual tests live in [`test/src/bh/test/examples/ProgrammableCodeGenTest.hx`](../../test/src/bh/test/examples/ProgrammableCodeGenTest.hx) and produce 3-image comparisons (reference + builder + macro) via `simpleMacroTest()`. There is no `AllExamplesTest.hx` — `ProgrammableCodeGenTest` is the visual runner. Other files in `test/src/bh/test/examples/` (e.g. `UIMultiAnimGridTest`, `ScreenTransitionTest`) are subsystem-specific and follow the same pattern when they need visual comparison.

To add a new visual test:

1. **Create test directory**: `test/examples/<N>-<testName>/` (N = next number)

2. **Create `.manim` file**: `test/examples/<N>-<testName>/<testName>.manim` with a programmable named after the test feature.

3. **Register the programmable** in [`test/src/bh/test/MultiProgrammable.hx`](../../test/src/bh/test/MultiProgrammable.hx). The `@:build(ProgrammableCodeGen.buildAll())` macro generates a typed factory (`mp.<field>.create()`) from this declaration:
   ```haxe
   @:manim("test/examples/<N>-<testName>/<testName>.manim", "<programmableName>")
   public var <fieldName>;
   ```

4. **Add test method** in `ProgrammableCodeGenTest.hx`:
   ```haxe
   @Test
   public function test<N>_<TestName>(async:utest.Async):Void {
       simpleMacroTest(<N>, "<testName>", () -> createMp().<fieldName>.create(), async);
   }
   ```
   Optional trailing args on `simpleMacroTest`: `placeholderValues`, `extraSetup`, `scale`, `similarityThreshold`. For `.manim` files designed at native resolution, pass `4.0` scale (most existing tests) or `1.0` for screen-sized layouts. For tests that need custom builder vs macro phases (e.g. animation freezing, see `test101_AnimFlip`), don't use `simpleMacroTest` — call `buildRenderScreenshotAndCompare` / `clearScene` / `captureScreenshotRaw` directly and remember to call `addTitleOverlay()` after adding the macro root.

5. **Generate reference image** (test.bat gen-refs uses a dynamic loop — no manual entries needed):
   - Run `test.bat run` to generate screenshot
   - Run `test.bat gen-refs` to copy as reference
   - Verify with `test.bat run` again (should pass)

## Testing Pitfalls

- **utest 2.0-alpha**: Test methods MUST start with `test` prefix to be discovered by the runner. `@Test` metadata alone is NOT sufficient.
- **manim version header**: Parser tests need `version: 1.0` header — prepend to test strings or they'll fail with "version expected".
- **Bitmap syntax for tests**: Use `bitmap(generated(color(w, h, #color)))` for tests without real assets. `bitmap("name")` is NOT valid syntax.
- **Never blindly gen-refs on failures**: When tests fail, ALWAYS investigate each failure first — open the `.manim` file, trace the color/value through the code, and confirm the new visual is correct before regenerating references. A visual change could be a bug, not just an expected consequence.
- **utest warnings = FAIL**: Tests with 0 assertions are utest "warnings" which make `stats.isOk` false → status FAILED. Always add at least one `Assert.*` call per test method.
- **Visual test titles**: Titles come from test CODE (`testTitle` property set in each test method), NOT from `.manim` files. Do NOT add title elements to `.manim` test files.
- **Visual test scale**: Default scale is 4.0x. Pass explicit `1.0` for `.manim` files designed at native resolution (e.g., 1280x720).
- **Custom test macro phase**: When using custom `waitForUpdate` logic instead of `builderAndMacroScreenshotAndCompare`, must call `addTitleOverlay()` after `clearScene()` + adding macro root to scene. Otherwise macro screenshot lacks the title.
- **Macro mismatch vs visual pass**: test output reports `macro_mismatches` for tests where builder OR macro similarity != 1.0 exactly. Both can individually "pass" their threshold but still be flagged as a mismatch.
- **TestApp frame count**: Currently set to 50 frames. Increase if adding many more visual tests.
- **Pre-existing**: test32_Blob47Fallback has a reference image mismatch (not a regression).

## Debug Tracing

Debug traces are included with `-D MULTIANIM_DEV` (same flag that enables hot reload and DevBridge).

## Strict Mode

Fail-fast on `.manim`/`.anim` errors — prints structured error to stderr and `Sys.exit(1)`. For CI/AI workflows:
```hxml
-D MULTIANIM_STRICT
```

## Haxe Language Pitfalls

- **`@:access` does NOT bypass `(default, null)` property setters.** It only bypasses visibility (private/public), not property access restrictions. To write `(default, null)` properties from outside the class, cast to `Dynamic`: `var dg:Dynamic = group; dg.speed = value;`
- **No named argument syntax.** Haxe does NOT support `fn(name: value)`. Must pass positional args: `fn(arg1, null, null, true)` to reach later optional params.
- **String interpolation uses SINGLE quotes, not double.** `'hello $name'` interpolates; `"hello $name"` is literal. In test code, use `"..."` (double quotes) for manim source strings to avoid Haxe interpolation of `$`.
- **Map has no `.count()` method.** Use a separate counter variable to track size.

## Environment Notes

- **NEVER create a `nul` file** in the project. On Windows, redirecting output to `nul` via Bash tool can create a literal file named "nul" instead of discarding output.
- **Lix library cache**: `C:\Users\goraz\AppData\Roaming\haxe\haxe_libraries\`. `HAXE_LIBCACHE` env var in `.hxml` files resolves here.
- **Playwright MCP files**: Store all Playwright screenshots/artifacts in `.playwright-mcp/` (gitignored). Clean up after done with browser testing. Always inject a red "CONTROLLED BY PLAYWRIGHT" banner at the top of browser pages.

## Parser Notes

- `MultiAnimParser.parseFile` is the main entry point. Throws `InvalidSyntax` (extends `ParserError`) for semantic errors, `MultiAnimUnexpected` for syntax errors.
- `syntaxError()` traces before throwing — traces appear in test output when parser error tests run.
- `invalidType` as parameter type causes uncatchable HashLink crash — avoid testing this.
