@echo off
REM Test utility script for hx-multianim
REM Usage: test.bat [run|gen-refs|report|rr] [-v|-verbose]

setlocal
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
pushd "%ROOT%" >nul
if "%VERBOSE%"=="1" (
    haxe test-hx-multianim-verbose.hxml
) else (
    for /f "tokens=*" %%i in ('haxe test-hx-multianim.hxml 2^>^&1 ^| findstr /i "Error FAILURE failures: results: warnings:"') do @echo %%i
)
popd >nul
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

REM Example 1: hex grid + pixels
if exist "%ROOT%test\screenshots\hexGridPixels_actual.png" (
    copy /Y "%ROOT%test\screenshots\hexGridPixels_actual.png" "%ROOT%test\examples\1-hexGridPixels\reference.png" >nul
    echo   01 - hexGridPixels
)

REM Example 2: text
if exist "%ROOT%test\screenshots\textDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\textDemo_actual.png" "%ROOT%test\examples\2-textDemo\reference.png" >nul
    echo   02 - textDemo
)

REM Example 3: bitmap
if exist "%ROOT%test\screenshots\bitmapDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\bitmapDemo_actual.png" "%ROOT%test\examples\3-bitmapDemo\reference.png" >nul
    echo   03 - bitmapDemo
)

REM Example 4: repeatable
if exist "%ROOT%test\screenshots\repeatableDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\repeatableDemo_actual.png" "%ROOT%test\examples\4-repeatableDemo\reference.png" >nul
    echo   04 - repeatableDemo
)

REM Example 5: stateanim
if exist "%ROOT%test\screenshots\stateAnimDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\stateAnimDemo_actual.png" "%ROOT%test\examples\5-stateAnimDemo\reference.png" >nul
    echo   05 - stateAnimDemo
)

REM Example 6: flow
if exist "%ROOT%test\screenshots\flowDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\flowDemo_actual.png" "%ROOT%test\examples\6-flowDemo\reference.png" >nul
    echo   06 - flowDemo
)

REM Example 7: palette
if exist "%ROOT%test\screenshots\paletteDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\paletteDemo_actual.png" "%ROOT%test\examples\7-paletteDemo\reference.png" >nul
    echo   07 - paletteDemo
)

REM Example 8: layers
if exist "%ROOT%test\screenshots\layersDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\layersDemo_actual.png" "%ROOT%test\examples\8-layersDemo\reference.png" >nul
    echo   08 - layersDemo
)

REM Example 9: 9-patch
if exist "%ROOT%test\screenshots\ninePatchDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\ninePatchDemo_actual.png" "%ROOT%test\examples\9-ninePatchDemo\reference.png" >nul
    echo   09 - ninePatchDemo
)

REM Example 10: reference
if exist "%ROOT%test\screenshots\referenceDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\referenceDemo_actual.png" "%ROOT%test\examples\10-referenceDemo\reference.png" >nul
    echo   10 - referenceDemo
)

REM Example 11: bitmap align
if exist "%ROOT%test\screenshots\bitmapAlignDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\bitmapAlignDemo_actual.png" "%ROOT%test\examples\11-bitmapAlignDemo\reference.png" >nul
    echo   11 - bitmapAlignDemo
)

REM Example 12: updatable from code
if exist "%ROOT%test\screenshots\updatableDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\updatableDemo_actual.png" "%ROOT%test\examples\12-updatableDemo\reference.png" >nul
    echo   12 - updatableDemo
)

REM Example 13: layout repeatable
if exist "%ROOT%test\screenshots\layoutRepeatableDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\layoutRepeatableDemo_actual.png" "%ROOT%test\examples\13-layoutRepeatableDemo\reference.png" >nul
    echo   13 - layoutRepeatableDemo
)

REM Example 14: tileGroup
if exist "%ROOT%test\screenshots\tileGroupDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\tileGroupDemo_actual.png" "%ROOT%test\examples\14-tileGroupDemo\reference.png" >nul
    echo   14 - tileGroupDemo
)

REM Example 15: stateAnim construct
if exist "%ROOT%test\screenshots\stateAnimConstructDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\stateAnimConstructDemo_actual.png" "%ROOT%test\examples\15-stateAnimConstructDemo\reference.png" >nul
    echo   15 - stateAnimConstructDemo
)

REM Example 16: div/mod
if exist "%ROOT%test\screenshots\divModDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\divModDemo_actual.png" "%ROOT%test\examples\16-divModDemo\reference.png" >nul
    echo   16 - divModDemo
)

REM Example 17: apply
if exist "%ROOT%test\screenshots\applyDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\applyDemo_actual.png" "%ROOT%test\examples\17-applyDemo\reference.png" >nul
    echo   17 - applyDemo
)

REM Example 18: conditionals (consolidated)
if exist "%ROOT%test\screenshots\conditionalsDemo_actual.png" (
    if not exist "%ROOT%test\examples\18-conditionalsDemo\" (
        mkdir "%ROOT%test\examples\18-conditionalsDemo\"
    )
    copy /Y "%ROOT%test\screenshots\conditionalsDemo_actual.png" "%ROOT%test\examples\18-conditionalsDemo\reference.png" >nul
    echo   18 - conditionalsDemo
)

REM Example 19: tertiary op
if exist "%ROOT%test\screenshots\tertiaryOpDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\tertiaryOpDemo_actual.png" "%ROOT%test\examples\19-tertiaryOpDemo\reference.png" >nul
    echo   19 - tertiaryOpDemo
)

REM Example 20: graphics
if exist "%ROOT%test\screenshots\graphicsDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\graphicsDemo_actual.png" "%ROOT%test\examples\20-graphicsDemo\reference.png" >nul
    echo   20 - graphicsDemo
)

REM Example 21: repeatable2d
if exist "%ROOT%test\screenshots\repeatable2dDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\repeatable2dDemo_actual.png" "%ROOT%test\examples\21-repeatable2dDemo\reference.png" >nul
    echo   21 - repeatable2dDemo
)

REM Example 23: tiles/stateanim iteration
if exist "%ROOT%test\screenshots\tilesIteration_actual.png" (
    copy /Y "%ROOT%test\screenshots\tilesIteration_actual.png" "%ROOT%test\examples\23-tilesIteration\reference.png" >nul
    echo   23 - tilesIteration
)

REM Example 24: atlas demo
if exist "%ROOT%test\screenshots\atlasDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\atlasDemo_actual.png" "%ROOT%test\examples\24-atlasDemo\reference.png" >nul
    echo   24 - atlasDemo
)

REM Example 25: autotile demo
if exist "%ROOT%test\screenshots\autotileDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\autotileDemo_actual.png" "%ROOT%test\examples\25-autotileDemo\reference.png" >nul
    echo   25 - autotileDemo
)

REM Example 26: autotile cross
if exist "%ROOT%test\screenshots\autotileCross_actual.png" (
    copy /Y "%ROOT%test\screenshots\autotileCross_actual.png" "%ROOT%test\examples\26-autotileCross\reference.png" >nul
    echo   26 - autotileCross
)

REM Example 27: autotile blob47
if exist "%ROOT%test\screenshots\autotileBlob47_actual.png" (
    copy /Y "%ROOT%test\screenshots\autotileBlob47_actual.png" "%ROOT%test\examples\27-autotileBlob47\reference.png" >nul
    echo   27 - autotileBlob47
)

REM Example 28: font showcase
if exist "%ROOT%test\screenshots\fontShowcase_actual.png" (
    copy /Y "%ROOT%test\screenshots\fontShowcase_actual.png" "%ROOT%test\examples\28-fontShowcase\reference.png" >nul
    echo   28 - fontShowcase
)

REM Example 29: scale position demo
if exist "%ROOT%test\screenshots\scalePositionDemo_actual.png" (
    copy /Y "%ROOT%test\screenshots\scalePositionDemo_actual.png" "%ROOT%test\examples\29-scalePositionDemo\reference.png" >nul
    echo   29 - scalePositionDemo
)

echo.
echo Reference images updated. Re-run 'test.bat run' to verify tests pass.
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
pushd "%ROOT%" >nul
if "%VERBOSE%"=="1" (
    cmd /c haxe test-hx-multianim-verbose.hxml
) else (
    for /f "tokens=*" %%i in ('cmd /c haxe test-hx-multianim.hxml 2^>^&1 ^| findstr /i "Error FAILURE failures: results: warnings:"') do @echo %%i
)
popd >nul
echo.
if not exist "%REPORT%" (
    echo Report not found: %REPORT%
    goto :eof
)
if "%VERBOSE%"=="1" echo Opening report: %REPORT%
start "" "%REPORT%"
goto :eof
