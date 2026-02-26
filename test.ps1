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

function Write-Line($msg) {
    [Console]::WriteLine($msg)
}

function Format-TestResults($content, $Label) {
    # Parse key fields
    $status = if ($content -match 'status:\s*(\S+)') { $Matches[1] } else { "UNKNOWN" }
    $vTotal = if ($content -match 'visual_total:\s*(\d+)') { [int]$Matches[1] } else { 0 }
    $vPassed = if ($content -match 'visual_passed:\s*(\d+)') { [int]$Matches[1] } else { 0 }
    $vFailed = if ($content -match 'visual_failed:\s*(\d+)') { [int]$Matches[1] } else { 0 }
    $uAssert = if ($content -match 'unit_assertions:\s*(\d+)') { [int]$Matches[1] } else { 0 }
    $uFail = if ($content -match 'unit_failures:\s*(\d+)') { [int]$Matches[1] } else { 0 }
    $uErr = if ($content -match 'unit_errors:\s*(\d+)') { [int]$Matches[1] } else { 0 }
    $macroMM = if ($content -match 'macro_mismatches:\s*(\d+)') { [int]$Matches[1] } else { 0 }
    $elapsed = if ($content -match 'elapsed_seconds:\s*(\d+)') { $Matches[1] + "s" } else { "?" }

    # Status line
    if ($status -eq "OK") {
        Write-Host "PASS$Label`: " -ForegroundColor Green -NoNewline
    } else {
        Write-Host "FAIL$Label`: " -ForegroundColor Red -NoNewline
    }

    # Summary parts
    $parts = @()
    if ($vTotal -gt 0) {
        $vColor = if ($vFailed -eq 0) { "Green" } else { "Red" }
        $parts += @{ text = "$vPassed/$vTotal visual"; color = $vColor }
    }
    if ($uAssert -gt 0) {
        $uColor = if ($uFail -eq 0 -and $uErr -eq 0) { "Green" } else { "Red" }
        $uText = "$uAssert unit assertions"
        if ($uFail -gt 0 -or $uErr -gt 0) { $uText += " ($uFail failures, $uErr errors)" }
        $parts += @{ text = $uText; color = $uColor }
    }
    if ($macroMM -gt 0) {
        $parts += @{ text = "$macroMM macro mismatches"; color = "Yellow" }
    }

    for ($i = 0; $i -lt $parts.Count; $i++) {
        Write-Host $parts[$i].text -ForegroundColor $parts[$i].color -NoNewline
        if ($i -lt $parts.Count - 1) { Write-Host ", " -NoNewline }
    }
    Write-Host " ($elapsed)"

    # Detail lines for failures
    $hasDetails = $false

    # Visual failure details
    $visualDetails = [regex]::Matches($content, '^\s+visual_detail:\s*(.+)$', 'Multiline')
    foreach ($m in $visualDetails) {
        if (-not $hasDetails) { $hasDetails = $true }
        $detail = $m.Groups[1].Value.Trim()
        $parts = $detail -split '\s*\|\s*', 2
        $testName = $parts[0]
        $reason = if ($parts.Count -gt 1) { $parts[1] } else { "failed" }
        # Color-code the reason
        $reasonColor = "Red"
        if ($reason -eq "no_reference") { $reasonColor = "Yellow"; $reason = "no reference image" }
        elseif ($reason -match '^low_similarity') { $reason = $reason -replace '^low_similarity ', 'similarity ' }
        elseif ($reason -match '^error:') { $reasonColor = "Red" }
        Write-Host "  VISUAL " -ForegroundColor DarkGray -NoNewline
        Write-Host "$testName" -ForegroundColor White -NoNewline
        Write-Host " - $reason" -ForegroundColor $reasonColor
    }

    # Macro mismatch details
    $macroDetails = [regex]::Matches($content, '^\s+macro_detail:\s*(.+)$', 'Multiline')
    foreach ($m in $macroDetails) {
        if (-not $hasDetails) { $hasDetails = $true }
        $detail = $m.Groups[1].Value.Trim()
        $parts = $detail -split '\s*\|\s*', 2
        $testName = $parts[0]
        $info = if ($parts.Count -gt 1) { $parts[1] } else { "mismatch" }
        Write-Host "  MACRO  " -ForegroundColor DarkGray -NoNewline
        Write-Host "$testName" -ForegroundColor White -NoNewline
        Write-Host " - $info" -ForegroundColor Yellow
    }

    # Unit test failure details
    $unitDetails = [regex]::Matches($content, '^\s+unit_detail:\s*(.+)$', 'Multiline')
    foreach ($m in $unitDetails) {
        if (-not $hasDetails) { $hasDetails = $true }
        $detail = $m.Groups[1].Value.Trim()
        Write-Host "  UNIT   " -ForegroundColor DarkGray -NoNewline
        Write-Host "$detail" -ForegroundColor Red
    }
}

function Invoke-TestRun {
    if ($TestNum -and -not $AIOutput) { Write-Host "Running test #$TestNum only" -ForegroundColor Cyan }

    Push-Location $Root
    try {
        # Run standard tests
        $result = Do-Run "test-hx-multianim.hxml" "build/hl-test.hl" "build/test_result.txt" ""
        if ($result -ne 0) { return $result }

        # Run dev-mode tests (hot-reload)
        $result = Do-Run "test-hx-multianim-dev.hxml" "build/hl-test-dev.hl" "build/test_result.txt" " [DEV]"
        return $result
    } finally {
        Pop-Location
    }
}

function Do-Run($BaseHxml, $HlBinary, $ResultFileName, $Label) {
    # Select hxml config
    $hxml = $BaseHxml
    if ($VerboseOutput -and $Label -eq "") { $hxml = "test-hx-multianim-verbose.hxml" }

    # Prepare result file
    $resultFile = Join-Path $Root $ResultFileName
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

    # Log file for trace output (always captured, shown only with -v)
    $logFile = Join-Path $Root "build/test_output$($Label.Replace(' ', '_')).log"
    if (Test-Path $logFile) { Remove-Item $logFile }

    # --- PHASE 1: Compilation ---
    if (-not $AIOutput) { Write-Host "Compiling$Label..." -ForegroundColor Cyan }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    # Use cmd.exe /c to support haxe installed as .cmd/.ps1 wrapper (e.g. lix/npm shims)
    $psi.FileName = "cmd.exe"
    $psi.Arguments = "/c haxe $hxml"
    $psi.UseShellExecute = $false
    $psi.WorkingDirectory = $Root
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $compileProc = [System.Diagnostics.Process]::Start($psi)
    $compileStdout = $compileProc.StandardOutput.ReadToEnd()
    $compileStderr = $compileProc.StandardError.ReadToEnd()
    $compileProc.WaitForExit()

    # Save compile output to log
    if ($compileStdout -or $compileStderr) {
        $logContent = "=== COMPILE$Label ===`n"
        if ($compileStdout) { $logContent += $compileStdout }
        if ($compileStderr) { $logContent += $compileStderr }
        [System.IO.File]::AppendAllText($logFile, $logContent)
    }

    if ($compileProc.ExitCode -ne 0) {
        if ($tmpHxml -and (Test-Path $tmpHxml)) { Remove-Item $tmpHxml }
        if ($AIOutput) {
            Write-Line "--- TEST RESULT$Label ---"
            Write-Line "status: COMPILE_ERROR"
            Write-Line "haxe_exit_code: $($compileProc.ExitCode)"
            if ($compileStderr) {
                Write-Line "error_output: $($compileStderr.TrimEnd())"
            }
            Write-Line "--- END TEST RESULT ---"
        } else {
            Write-Host "ERROR:$Label Compilation failed (exit code $($compileProc.ExitCode))" -ForegroundColor Red
            if ($compileStderr) { Write-Host $compileStderr.TrimEnd() -ForegroundColor Red }
        }
        return $compileProc.ExitCode
    }

    # --- PHASE 2: Execution with timeout ---
    if (-not $AIOutput) { Write-Host "Running tests$Label..." -ForegroundColor Cyan }
    $psi2 = New-Object System.Diagnostics.ProcessStartInfo
    $psi2.FileName = "hl"
    $psi2.Arguments = $HlBinary
    $psi2.UseShellExecute = $false
    $psi2.WorkingDirectory = $Root
    $psi2.RedirectStandardOutput = $true
    $psi2.RedirectStandardError = $true
    $hlProc = [System.Diagnostics.Process]::Start($psi2)
    $hlStdoutTask = $hlProc.StandardOutput.ReadToEndAsync()
    $hlStderrTask = $hlProc.StandardError.ReadToEndAsync()
    $exited = $hlProc.WaitForExit($HlTimeout * 1000)

    # Save HL output to log
    if ($exited) {
        $hlStdout = $hlStdoutTask.Result
        $hlStderr = $hlStderrTask.Result
    } else {
        $hlProc.Kill()
        $hlStdout = $hlStdoutTask.Result
        $hlStderr = $hlStderrTask.Result
    }
    if ($hlStdout -or $hlStderr) {
        $logContent = "=== HL RUN$Label ===`n"
        if ($hlStdout) { $logContent += $hlStdout }
        if ($hlStderr) { $logContent += $hlStderr }
        [System.IO.File]::AppendAllText($logFile, $logContent)
    }
    if ($VerboseOutput -and -not $AIOutput) {
        if ($hlStdout) { Write-Host $hlStdout.TrimEnd() }
        if ($hlStderr) { Write-Host $hlStderr.TrimEnd() -ForegroundColor Yellow }
    }

    if (-not $exited) {
        if ($tmpHxml -and (Test-Path $tmpHxml)) { Remove-Item $tmpHxml }
        if ($AIOutput) {
            Write-Line "--- TEST RESULT$Label ---"
            Write-Line "status: TIMEOUT"
            Write-Line "elapsed_seconds: $HlTimeout"
            Write-Line "--- END TEST RESULT ---"
        } else {
            Write-Host "ERROR:$Label hl process did not exit within $HlTimeout seconds" -ForegroundColor Red
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
            Format-TestResults $content $Label
        }
    } else {
        if ($AIOutput) {
            Write-Line "--- TEST RESULT$Label ---"
            Write-Line "status: FAILED"
            Write-Line "error: test did not produce results ($ResultFileName missing)"
            Write-Line "--- END TEST RESULT ---"
        } else {
            Write-Host "ERROR:$Label test did not produce results ($ResultFileName missing)" -ForegroundColor Red
        }
        return 1
    }

    # --- PHASE 3 complete ---
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
