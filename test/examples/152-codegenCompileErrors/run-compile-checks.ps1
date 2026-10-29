# Isolated codegen compile checks.
#
# Each host class in hosts/ registers one .manim fixture from this directory
# via @:manim. These fixtures used to break compilation OF THE GENERATED CLASS
# (rvToExprInt / callback-default / hex-layout lowering bugs), so while red they
# cannot live in test/src/bh/test/MultiProgrammable.hx — one bad fixture there
# takes down the whole test binary. This harness compiles each host in
# isolation instead.
#
# GREEN condition: every host compiles (exit 0). CgControlHost holds
# static/int-safe shapes of the same elements and must always compile — if it
# fails, the harness (not the codegen) is broken.
#
# CI: the same check runs in .github/workflows/tests.yml ("Codegen compile
# checks" step in the compile job) — it globs hosts/*.hx exactly like this
# script, so adding a new host file wires it into both automatically.
#
# To pin a NEW compile-error-class codegen bug: add a fixture .manim here and a
# matching host class in hosts/ (class name = file name). The script goes red
# until the fix lands.
#
# Run from anywhere: powershell -ExecutionPolicy Bypass -File test/examples/152-codegenCompileErrors/run-compile-checks.ps1

$Root = Resolve-Path "$PSScriptRoot\..\..\.."
Set-Location $Root

$hostFiles = Get-ChildItem -Path "test\examples\152-codegenCompileErrors\hosts" -Filter "*.hx" | Sort-Object Name
$failed = @()
foreach ($hf in $hostFiles) {
    $name = $hf.BaseName
    $log = Join-Path $env:TEMP "cgcheck-$name.log"
    cmd /c "haxe -lib heaps -cp src -cp test\examples\152-codegenCompileErrors\hosts -D resourcesPath=test/res --macro ""bh.base.AtlasMacroInit.init()"" --no-output $name > ""$log"" 2>&1"
    if ($LASTEXITCODE -ne 0) {
        $failed += $name
        Write-Host "FAIL $name" -ForegroundColor Red
        Get-Content $log | Where-Object { $_ -notmatch "Warning" } | Select-Object -First 3 | ForEach-Object { Write-Host "     $_" -ForegroundColor DarkRed }
    } else {
        Write-Host "PASS $name" -ForegroundColor Green
    }
}

Write-Host ""
if ($failed.Count -eq 0) {
    Write-Host "compile_checks: OK ($($hostFiles.Count) hosts compile)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "compile_checks: FAILED ($($failed.Count)/$($hostFiles.Count) hosts do not compile: $($failed -join ', '))" -ForegroundColor Red
    exit 1
}
