@echo off
REM Autotile Mapper Utility
REM Usage: run-autotile-mapper.bat <file.manim> [#autotileName]
REM
REM Example:
REM   run-autotile-mapper.bat ..\test\examples\32-blob47Fallback\blob47Fallback.manim #blob47Grass

cd /d "%~dp0"

if not exist build\autotile-mapper.hl (
    echo Building autotile-mapper...
    haxe autotile-mapper.hxml
    if errorlevel 1 (
        echo Build failed!
        pause
        exit /b 1
    )
)

if "%~1"=="" (
    echo.
    echo Autotile Mapper - Interactive tool for mapping blob47 autotiles
    echo.
    echo Usage: run-autotile-mapper.bat ^<file.manim^> [#autotileName]
    echo.
    echo Example:
    echo   run-autotile-mapper.bat ..\test\examples\32-blob47Fallback\blob47Fallback.manim #blob47Grass
    echo.
    echo Controls:
    echo   [A] Autodetect - Analyze tiles and guess mappings
    echo   [E] Export     - Print mapping to console
    echo   [C] Clear      - Clear all mappings
    echo   [R] Reload     - Reload the .manim file
    echo   [Q] Quit
    echo.
    echo Mouse:
    echo   Click region tile, then click blob47 tile to create mapping
    echo   Right-click blob47 tile to remove mapping
    echo.
    pause
    exit /b 0
)

hl build\autotile-mapper.hl %*
