@echo off
REM Test utility script for hx-multianim
REM Usage: test.bat [run|gen-refs|report|rr] [-v|-verbose]

setlocal enabledelayedexpansion
set "ROOT=%~dp0"
set "VERBOSE=0"

REM Check for verbose flag in any position
for %%a in (%*) do (
    if /i "%%a"=="-v" set "VERBOSE=1"
    if /i "%%a"=="-verbose" set "VERBOSE=1"
)

REM Get command (first non-flag argument)
set "CMD="
for %%a in (%*) do (
    if not "%%a"=="-v" if not "%%a"=="-verbose" (
        if not defined CMD set "CMD=%%a"
    )
)

if "%CMD%"=="" goto run
if /i "%CMD%"=="run" goto run
if /i "%CMD%"=="gen-refs" goto gen_refs
if /i "%CMD%"=="report" goto report
if /i "%CMD%"=="rr" goto rr

echo Unknown command: %CMD%
echo Usage: test.bat [run^|gen-refs^|report^|rr] [-v^|-verbose]
goto :eof

:run
echo [96m--- TEST BEGIN ---[0m
pushd "%ROOT%" >nul
if "%VERBOSE%"=="1" (
    haxe test-hx-multianim-verbose.hxml
) else (
    for /f "tokens=*" %%i in ('haxe test-hx-multianim.hxml 2^>^&1 ^| findstr /i "Error FAILURE failures: results: warnings:"') do @echo %%i
)
popd >nul
echo [96m--- TEST END ---[0m
goto :eof

:gen_refs
echo Generating reference images...
if not exist "%ROOT%test\screenshots\" (
    echo Error: test\screenshots\ directory not found
    echo Please run 'test.bat run' first to generate screenshots
    goto :eof
)
echo.
echo Copying screenshots to reference locations...

REM Auto-discover test directories: iterate test\examples\N-testName folders
REM For each, check if test\screenshots\testName_actual.png exists and copy it
for /d %%D in ("%ROOT%test\examples\*") do (
    call :process_test_dir "%%~nxD"
)

echo.
echo Reference images updated. Re-run 'test.bat run' to verify tests pass.
goto :eof

:process_test_dir
REM %~1 = directory name like "1-hexGridPixels" or "38-codegenButton"
set "DIRN=%~1"
REM Extract the number (before first dash) and test name (after first dash)
for /f "tokens=1,* delims=-" %%A in ("!DIRN!") do (
    set "NUM=%%A"
    set "TNAME=%%B"
)
if exist "%ROOT%test\screenshots\!TNAME!_actual.png" (
    copy /Y "%ROOT%test\screenshots\!TNAME!_actual.png" "%ROOT%test\examples\!DIRN!\reference.png" >nul
    echo   !NUM! - !TNAME!
)
goto :eof

:report
set "REPORT=%ROOT%test\screenshots\index.html"
if not exist "%REPORT%" (
    echo Report not found: %REPORT%
    echo Run 'test.bat' first to generate it.
    goto :eof
)
echo Opening report: %REPORT%
start "" "%REPORT%"
goto :eof

:rr
set "REPORT=%ROOT%test\screenshots\index.html"
if exist "%REPORT%" (
    del "%REPORT%"
    if "%VERBOSE%"=="1" echo Deleted old report.
)
echo [96m--- TEST BEGIN ---[0m
pushd "%ROOT%" >nul
if "%VERBOSE%"=="1" (
    cmd /c haxe test-hx-multianim-verbose.hxml
) else (
    for /f "tokens=*" %%i in ('cmd /c haxe test-hx-multianim.hxml 2^>^&1 ^| findstr /i "Error FAILURE failures: results: warnings:"') do @echo %%i
)
popd >nul
echo [96m--- TEST END ---[0m
echo.
if not exist "%REPORT%" (
    echo Report not found: %REPORT%
    goto :eof
)
if "%VERBOSE%"=="1" echo Opening report: %REPORT%
start "" "%REPORT%"
goto :eof
