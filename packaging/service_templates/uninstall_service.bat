@echo off
setlocal
cd /d "%~dp0"

echo ========================================================
echo  Uninstalling eCuisine Mess API Windows Service
echo ========================================================
echo.

:: Check for Administrator permissions
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires Administrator privileges.
    echo Please right-click this script and select 'Run as administrator'.
    echo.
    pause
    exit /b 1
)

echo [INFO] Stopping Windows Service 'EcuisineMessApi'...
"%~dp0mess-api-service.exe" stop >nul 2>&1

echo [INFO] Uninstalling Windows Service 'EcuisineMessApi'...
"%~dp0mess-api-service.exe" uninstall
if %errorlevel% neq 0 (
    echo [ERROR] Failed to uninstall service.
    pause
    exit /b %errorlevel%
)

echo.
echo ========================================================
echo  Service successfully uninstalled.
echo ========================================================
echo.
pause
