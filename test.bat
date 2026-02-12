@echo off
REM Test utility script for hx-multianim
REM Usage: test.bat [run|gen-refs|report|rr] [testNum] [-v|-verbose]
REM
REM Examples:
REM   test.bat run           Run all tests
REM   test.bat run 7         Run only test #7
REM   test.bat rr 7          Run test #7 and open report
REM   test.bat run -v        Run all tests with verbose output
REM   test.bat rr 7 -v       Run test #7 verbose and open report
REM   test.bat gen-refs      Generate reference images from latest screenshots

setlocal enabledelayedexpansion
set "ROOT=%~dp0"
set "VERBOSE=0"
set "TESTNUM="

REM Parse arguments: flags, command, and optional test number
for %%a in (%*) do (
    if /i "%%a"=="-v" (
        set "VERBOSE=1"
    ) else if /i "%%a"=="-verbose" (
        set "VERBOSE=1"
    ) else if not defined CMD (
        set "CMD=%%a"
    ) else if not defined TESTNUM (
        set "TESTNUM=%%a"
    )
)

if "%CMD%"=="" goto run
if /i "%CMD%"=="run" goto run
if /i "%CMD%"=="gen-refs" goto gen_refs
if /i "%CMD%"=="report" goto report
if /i "%CMD%"=="rr" goto rr

REM Check if CMD is a number (user typed "test.bat 7" meaning "test.bat run 7")
set "IS_NUM=1"
for /f "delims=0123456789" %%i in ("%CMD%") do set "IS_NUM=0"
if "%IS_NUM%"=="1" (
    set "TESTNUM=%CMD%"
    goto run
)

echo Unknown command: %CMD%
echo Usage: test.bat [run^|gen-refs^|report^|rr] [testNum] [-v^|-verbose]
goto :eof

:run
echo [96m--- TEST BEGIN ---[0m
if defined TESTNUM echo Running test #%TESTNUM% only
pushd "%ROOT%" >nul
call :do_run
popd >nul
echo [96m--- TEST END ---[0m
goto :eof

:rr
set "REPORT=%ROOT%test\screenshots\index.html"
if exist "%REPORT%" (
    del "%REPORT%"
    if "%VERBOSE%"=="1" echo Deleted old report.
)
echo [96m--- TEST BEGIN ---[0m
if defined TESTNUM echo Running test #%TESTNUM% only
pushd "%ROOT%" >nul
call :do_run
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

:do_run
set "HXML=test-hx-multianim.hxml"
if "%VERBOSE%"=="1" set "HXML=test-hx-multianim-verbose.hxml"
set "RESULT_FILE=%ROOT%build\test_result.txt"
if exist "!RESULT_FILE!" del "!RESULT_FILE!"

if not exist "%ROOT%build\" mkdir "%ROOT%build"

if defined TESTNUM (
    set "TMPHXML=%ROOT%build\_test_single.hxml"
    echo !HXML!> "!TMPHXML!"
    echo -D SINGLE_TEST=!TESTNUM!>> "!TMPHXML!"
    set "HXML=!TMPHXML!"
)

call haxe "!HXML!"

if defined TESTNUM (
    if exist "!TMPHXML!" del "!TMPHXML!"
)

REM Show test result summary from result file
if exist "!RESULT_FILE!" (
    type "!RESULT_FILE!"
) else (
    echo Error: test did not produce results (build/test_result.txt missing^)
)
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

for /d %%D in ("%ROOT%test\examples\*") do (
    call :process_test_dir "%%~nxD"
)

echo.
echo Reference images updated. Re-run 'test.bat run' to verify tests pass.
goto :eof

:process_test_dir
set "DIRN=%~1"
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
