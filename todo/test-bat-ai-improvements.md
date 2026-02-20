# test.bat Improvements for AI Parseability & Hang Detection

## Problem

When an AI runs `test.bat run`, it gets back unstructured output that's hard to parse programmatically:
- Success/failure requires string matching on "OK:" vs "FAILED:"
- No structured failure details (which tests, why)
- No hang detection — if `hl` hangs, the batch script blocks forever
- Compilation errors from `haxe` aren't distinguished from test failures
- No timing information to judge if something is abnormally slow

## Proposed Changes

### 1. Add a timeout wrapper around `hl` execution

**Problem:** The `hl` process can hang (GPU driver issue, infinite loop, etc.), blocking the AI indefinitely. The internal 60s wall-clock timeout in TestApp.hx only works if the app loop is running — a hang during init or rendering will never trigger it.

**Solution:** Use `timeout` or `start /wait` with a kill mechanism in the batch file.

```batch
:do_run
set "HXML=test-hx-multianim.hxml"
...
call haxe "!HXML!"
if errorlevel 1 (
    echo ##[error] Compilation failed with exit code %errorlevel%
    echo --- RESULT: COMPILE_ERROR ---
    goto :eof
)

REM Run HL with a timeout (90 seconds, allowing for 60s internal timeout + overhead)
set "HL_TIMEOUT=90"
start "" /B /WAIT cmd /c "hl build/hl-test.hl"
REM (see option B below for actual timeout implementation)
```

**Recommended approach — PowerShell wrapper** (most reliable on Windows):

```batch
powershell -NoProfile -Command "$p = Start-Process -FilePath 'hl' -ArgumentList 'build/hl-test.hl' -PassThru -NoNewWindow; if (-not $p.WaitForExit(90000)) { $p.Kill(); exit 124 } else { exit $p.ExitCode }"
set "HL_EXIT=%errorlevel%"
if "%HL_EXIT%"=="124" (
    echo --- RESULT: HUNG ---
    echo Error: hl process did not exit within 90 seconds
    goto :eof
)
```

### 2. Output a machine-readable result block

**Problem:** Current output is a single human-readable line. An AI must regex-match it.

**Solution:** Write a structured summary to `build/test_result.txt` AND echo a standardized block.

Change `getSummary()` in `HtmlReportGenerator.hx` to output a structured format:

```
--- TEST RESULT ---
status: OK | FAILED | TIMEOUT
visual_total: 47
visual_passed: 46
visual_failed: 1
visual_failures: [#32: Blob47Fallback]
unit_assertions: 983
unit_failures: 0
unit_errors: 3
unit_error_details: [BuilderUnitTest.testFoo: NullPointerException at line 123, ...]
elapsed_seconds: 8
--- END TEST RESULT ---
```

This is trivially parseable: look for `status:` line, or parse any specific field.

### 3. Separate compilation from execution in test.bat output

**Problem:** If `haxe` fails, the batch falls through and reports "test did not produce results" — indistinguishable from a hang.

**Solution:**

```batch
call haxe "!HXML!"
if errorlevel 1 (
    echo --- TEST RESULT ---
    echo status: COMPILE_ERROR
    echo haxe_exit_code: %errorlevel%
    echo --- END TEST RESULT ---
    goto :eof
)
```

### 4. Include unit test error details in test_result.txt

**Problem:** Current `FAILED: unit tests: 0 failures, 3 errors out of 983 assertions` says tests failed but not WHICH ones or WHY. The AI must open the HTML report to investigate.

**Solution:** Extend `getSummary()` to include per-failure details:

```haxe
public static function getSummary():String {
    var buf = new StringBuf();
    buf.add("--- TEST RESULT ---\n");

    var visualPassed = results.filter(r -> r.passed).length;
    var visualFailed = results.length - visualPassed;
    var hasFailures = visualFailed > 0;

    // Unit test stats
    var unitFail = 0; var unitErr = 0; var unitAssert = 0;
    if (includeUnitTests && unitAggregator != null && unitAggregator.root != null) {
        var us = unitAggregator.root.stats;
        unitFail = us.failures; unitErr = us.errors; unitAssert = us.assertations;
        if (!us.isOk) hasFailures = true;
    }

    buf.add('status: ${hasFailures ? "FAILED" : "OK"}\n');
    buf.add('visual_total: ${results.length}\n');
    buf.add('visual_passed: ${visualPassed}\n');
    buf.add('visual_failed: ${visualFailed}\n');
    if (visualFailed > 0) {
        var failedNames = results.filter(r -> !r.passed).map(r -> r.testName);
        buf.add('visual_failures: [${failedNames.join(", ")}]\n');
    }
    buf.add('unit_assertions: ${unitAssert}\n');
    buf.add('unit_failures: ${unitFail}\n');
    buf.add('unit_errors: ${unitErr}\n');
    // Per-failure details
    if (unitFail > 0 || unitErr > 0) {
        buf.add("unit_error_details:\n");
        // iterate fixtures, output each failing method + message
    }
    buf.add("--- END TEST RESULT ---\n");
    return buf.toString();
}
```

### 5. Add elapsed time to result file

**Problem:** No way to know if a test run was abnormally slow.

**Solution:** TestApp already tracks `startTime`. Pass elapsed to `getSummary()`:

```haxe
var elapsed = Sys.time() - startTime;
buf.add('elapsed_seconds: ${Math.round(elapsed)}\n');
```

### 6. Exit code propagation

**Problem:** `test.bat` doesn't check or propagate the exit code from `hl`. The `errorlevel` after `call haxe` is checked implicitly by the `--cmd` mechanism, but it's not explicit.

**Solution:** Make the batch file capture and return the exit code:

```batch
REM After hl execution:
if errorlevel 1 (
    echo Tests failed (exit code %errorlevel%)
)
exit /b %errorlevel%
```

And at the end of the `:run` label, use `exit /b` to propagate.

## Implementation Priority

| # | Change | Effort | Impact |
|---|--------|--------|--------|
| 1 | Structured result block in `getSummary()` | Medium | High — biggest win for AI parsing |
| 2 | Separate compile vs test failure in test.bat | Low | High — eliminates ambiguity |
| 3 | Hang detection timeout wrapper | Low | High — prevents infinite blocking |
| 4 | Unit test error details in result file | Medium | Medium — saves a round-trip to HTML |
| 5 | Elapsed time | Trivial | Low — nice to have |
| 6 | Exit code propagation | Trivial | Low — already partially works |

## Files to Modify

- `test.bat` — timeout wrapper, compile error detection, exit codes
- `test/src/bh/test/HtmlReportGenerator.hx` — `getSummary()` structured output
- `test/src/bh/test/TestApp.hx` — pass elapsed time to summary

## Backwards Compatibility

The structured format can be designed to still contain the old `OK:` / `FAILED:` prefix in the `status:` line, so any existing CI scripts that grep for those strings continue to work. The `--- TEST RESULT ---` / `--- END TEST RESULT ---` delimiters make it easy to extract just the machine-readable block.
