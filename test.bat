@echo off
REM Test utility script for hx-multianim
REM Usage: test.bat [run|gen-refs]

setlocal
set "ROOT=%~dp0"

if "%1"=="" goto run
if /i "%1"=="run" goto run
if /i "%1"=="gen-refs" goto gen_refs
if /i "%1"=="report" goto report

echo Unknown command: %1
echo Usage: test.bat [run^|gen-refs^|report]
goto :eof

:run
echo Running tests...
pushd "%ROOT%" >nul
haxe test-hx-multianim.hxml
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
