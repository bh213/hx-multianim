@echo off
setlocal

REM Save original directory and switch to script directory
set "ORIG_DIR=%CD%"
cd /d "%~dp0"

if not exist build\autotile-mapper.hl (
    echo Building autotile-mapper...
    haxe autotile-mapper.hxml
    if errorlevel 1 exit /b 1
)

if "%~1"=="" (
    echo Usage: autotilemapper.bat ^<file.manim^> [#autotileName]
    echo.
    echo Keys: [A]utodetect [E]xport [C]lear [R]eload [Q]uit
    echo Mouse: Click region tile, then blob47 tile to map. Right-click to unmap.
    exit /b 0
)

REM Convert relative path to absolute if needed
set "MANIM_FILE=%~1"
if not exist "%MANIM_FILE%" (
    set "MANIM_FILE=%ORIG_DIR%\%~1"
)
if not exist "%MANIM_FILE%" (
    set "MANIM_FILE=%~dp0%~1"
)

hl build\autotile-mapper.hl "%MANIM_FILE%" %2 %3 %4
