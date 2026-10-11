@echo off
setlocal
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0build_exe.ps1"
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Build failed with exit code %errorlevel%.
    pause
    exit /b %errorlevel%
)
pause
