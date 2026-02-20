# test.ps1 - Test utility script for hx-multianim
# Usage: .\test.ps1 [run|gen-refs|report|rr] [testNum] [-v] [-aioutput]
#
# Examples:
#   .\test.ps1 run              Run all tests
#   .\test.ps1 run 7            Run only test #7
#   .\test.ps1 rr 7             Run test #7 and open report
#   .\test.ps1 run -v           Run all tests with verbose output
#   .\test.ps1 rr 7 -v          Run test #7 verbose and open report
#   .\test.ps1 run -aioutput    Run tests with structured machine-readable output
#   .\test.ps1 gen-refs         Generate reference images from latest screenshots

param(
    [Parameter(Position = 0)]
    [string]$Command = "run",

    [Parameter(Position = 1)]
    [string]$TestNum,

    [Alias("v")]
    [switch]$VerboseOutput,

    [switch]$AIOutput
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$HlTimeout = 90

# Handle: test.ps1 7 (number as first arg = run that test)
if ($Command -match '^\d+$') {
    $TestNum = $Command
    $Command = "run"
}

function Write-Status($msg) {
    if (-not $AIOutput) {
        Write-Host $msg -ForegroundColor Cyan
    }
}

function Write-Line($msg) {
    [Console]::WriteLine($msg)
}

function Invoke-TestRun {
    Write-Status "--- TEST BEGIN ---"
    if ($TestNum) { Write-Status "Running test #$TestNum only" }

    Push-Location $Root
    try {
        $result = Do-Run
        return $result
    } finally {
        Pop-Location
    }
}

function Do-Run {
    # Select hxml config
    $hxml = "test-hx-multianim.hxml"
    if ($VerboseOutput) { $hxml = "test-hx-multianim-verbose.hxml" }

    # Prepare result file
    $resultFile = Join-Path $Root "build\test_result.txt"
    if (Test-Path $resultFile) { Remove-Item $resultFile }
    $buildDir = Join-Path $Root "build"
    if (-not (Test-Path $buildDir)) {
        New-Item -ItemType Directory -Path $buildDir | Out-Null
    }

    # Single-test override via temp hxml
    $tmpHxml = $null
    if ($TestNum) {
        $tmpHxml = Join-Path $Root "build\_test_single.hxml"
        Set-Content $tmpHxml "$hxml`n-D SINGLE_TEST=$TestNum"
        $hxml = $tmpHxml
    }

    # --- PHASE 1: Compilation ---
    Write-Status "Compiling..."
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "haxe"
    $psi.Arguments = $hxml
    $psi.UseShellExecute = $false
    $psi.WorkingDirectory = $Root
    if ($AIOutput) {
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
    }
    $compileProc = [System.Diagnostics.Process]::Start($psi)
    if ($AIOutput) {
        $compileStdout = $compileProc.StandardOutput.ReadToEnd()
        $compileStderr = $compileProc.StandardError.ReadToEnd()
    }
    $compileProc.WaitForExit()

    if ($compileProc.ExitCode -ne 0) {
        if ($tmpHxml -and (Test-Path $tmpHxml)) { Remove-Item $tmpHxml }
        if ($AIOutput) {
            Write-Line "--- TEST RESULT ---"
            Write-Line "status: COMPILE_ERROR"
            Write-Line "haxe_exit_code: $($compileProc.ExitCode)"
            if ($compileStderr) {
                Write-Line "error_output: $($compileStderr.TrimEnd())"
            }
            Write-Line "--- END TEST RESULT ---"
        } else {
            Write-Host "ERROR: Compilation failed (exit code $($compileProc.ExitCode))" -ForegroundColor Red
        }
        return $compileProc.ExitCode
    }

    # --- PHASE 2: Execution with timeout ---
    Write-Status "Running tests..."
    $psi2 = New-Object System.Diagnostics.ProcessStartInfo
    $psi2.FileName = "hl"
    $psi2.Arguments = "build/hl-test.hl"
    $psi2.UseShellExecute = $false
    $psi2.WorkingDirectory = $Root
    if ($AIOutput) {
        $psi2.RedirectStandardOutput = $true
        $psi2.RedirectStandardError = $true
    }
    $hlProc = [System.Diagnostics.Process]::Start($psi2)
    if ($AIOutput) {
        $hlStdoutTask = $hlProc.StandardOutput.ReadToEndAsync()
        $hlStderrTask = $hlProc.StandardError.ReadToEndAsync()
    }
    $exited = $hlProc.WaitForExit($HlTimeout * 1000)

    if (-not $exited) {
        $hlProc.Kill()
        if ($tmpHxml -and (Test-Path $tmpHxml)) { Remove-Item $tmpHxml }
        if ($AIOutput) {
            Write-Line "--- TEST RESULT ---"
            Write-Line "status: TIMEOUT"
            Write-Line "elapsed_seconds: $HlTimeout"
            Write-Line "--- END TEST RESULT ---"
        } else {
            Write-Host "ERROR: hl process did not exit within $HlTimeout seconds" -ForegroundColor Red
        }
        return 124
    }

    if ($tmpHxml -and (Test-Path $tmpHxml)) { Remove-Item $tmpHxml }

    # --- PHASE 3: Read results ---
    if (Test-Path $resultFile) {
        $content = Get-Content $resultFile -Raw
        if ($AIOutput) {
            Write-Line ($content.TrimEnd())
        } else {
            if ($content -match 'status:\s*(\S+)') {
                $status = $Matches[1]
                if ($status -eq "OK") {
                    $vTotal = if ($content -match 'visual_total:\s*(\d+)') { $Matches[1] } else { "?" }
                    $vPassed = if ($content -match 'visual_passed:\s*(\d+)') { $Matches[1] } else { "?" }
                    $uAssert = if ($content -match 'unit_assertions:\s*(\d+)') { $Matches[1] } else { "0" }
                    Write-Host "OK: $vPassed/$vTotal visual tests passed, $uAssert unit assertions passed" -ForegroundColor Green
                } else {
                    Write-Host $content -ForegroundColor Red
                }
            } else {
                Write-Line ($content)
            }
        }
    } else {
        if ($AIOutput) {
            Write-Line "--- TEST RESULT ---"
            Write-Line "status: FAILED"
            Write-Line "error: test did not produce results (build/test_result.txt missing)"
            Write-Line "--- END TEST RESULT ---"
        } else {
            Write-Host "Error: test did not produce results (build/test_result.txt missing)" -ForegroundColor Red
        }
        return 1
    }

    Write-Status "--- TEST END ---"
    return $hlProc.ExitCode
}

function Invoke-GenRefs {
    Write-Host "Generating reference images..."
    $screenshotsDir = Join-Path $Root "test\screenshots"
    if (-not (Test-Path $screenshotsDir)) {
        Write-Host "Error: test\screenshots\ directory not found"
        Write-Host "Please run '.\test.ps1 run' first to generate screenshots"
        return
    }

    Write-Host ""
    Write-Host "Copying screenshots to reference locations..."

    Get-ChildItem (Join-Path $Root "test\examples") -Directory | ForEach-Object {
        $dirName = $_.Name
        if ($dirName -match '^(\d+)-(.+)$') {
            $num = $Matches[1]
            $tname = $Matches[2]
            $actualPath = Join-Path $screenshotsDir "${tname}_actual.png"
            if (Test-Path $actualPath) {
                $refPath = Join-Path $_.FullName "reference.png"
                Copy-Item $actualPath $refPath -Force
                Write-Host "  $num - $tname"
            }
        }
    }

    Write-Host ""
    Write-Host "Reference images updated. Re-run '.\test.ps1 run' to verify tests pass."
}

function Invoke-Report {
    $reportPath = Join-Path $Root "test\screenshots\index.html"
    if (-not (Test-Path $reportPath)) {
        Write-Host "Report not found: $reportPath"
        Write-Host "Run '.\test.ps1 run' first to generate it."
        return
    }
    Write-Host "Opening report: $reportPath"
    Start-Process $reportPath
}

# --- Main dispatch ---
$exitCode = 0

switch ($Command.ToLower()) {
    "run" {
        $exitCode = Invoke-TestRun
    }
    "gen-refs" {
        Invoke-GenRefs
    }
    "report" {
        Invoke-Report
    }
    "rr" {
        $reportPath = Join-Path $Root "test\screenshots\index.html"
        if (Test-Path $reportPath) {
            Remove-Item $reportPath
            if ($VerboseOutput) { Write-Host "Deleted old report." }
        }
        $exitCode = Invoke-TestRun
        if (Test-Path $reportPath) {
            if ($VerboseOutput) { Write-Host "Opening report: $reportPath" }
            Start-Process $reportPath
        } else {
            Write-Host "Report not found: $reportPath"
        }
    }
    default {
        Write-Host "Unknown command: $Command"
        Write-Host "Usage: .\test.ps1 [run|gen-refs|report|rr] [testNum] [-v] [-aioutput]"
        $exitCode = 1
    }
}

exit $exitCode
