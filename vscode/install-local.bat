@echo off
REM Install vs-multianim extension locally to VS Code
setlocal

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM Build TypeScript and .vsix package
echo Compiling TypeScript...
cd /d "%SCRIPT_DIR%"
call npm run compile
if errorlevel 1 (
    echo ERROR: Failed to compile TypeScript
    exit /b 1
)

echo Building .vsix package...
call npx @vscode/vsce package --allow-missing-repository
if errorlevel 1 (
    echo ERROR: Failed to build .vsix package
    exit /b 1
)

REM Find the .vsix file (version-independent)
for %%f in (multianim-*.vsix) do set "VSIX_FILE=%%f"

REM Install using code CLI
echo Installing extension...
code --install-extension "%SCRIPT_DIR%\%VSIX_FILE%" --force
if errorlevel 1 (
    echo ERROR: Failed to install extension. Make sure 'code' is in your PATH.
    exit /b 1
)

echo.
echo Extension installed successfully.
echo Please reload VS Code (Ctrl+Shift+P ^> "Developer: Reload Window").
echo.

endlocal
