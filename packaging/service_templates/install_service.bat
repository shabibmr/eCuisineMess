@echo off
setlocal
cd /d "%~dp0"

echo ========================================================
echo  Installing eCuisine Mess API Windows Service
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

:: Copy default config if none exists
if not exist "config.env" (
    if exist "config.env.sample" (
        copy /y "config.env.sample" "config.env" >nul
        echo [INFO] Created default config.env from sample.
    )
)

:: Create logs directory
if not exist "logs" mkdir "logs"

:: Install and start service via WinSW
echo [INFO] Installing Windows Service 'EcuisineMessApi'...
"%~dp0mess-api-service.exe" install
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install service.
    pause
    exit /b %errorlevel%
)

echo [INFO] Starting Windows Service 'EcuisineMessApi'...
"%~dp0mess-api-service.exe" start
if %errorlevel% neq 0 (
    echo [WARN] Service installed, but failed to start immediately.
    echo Check logs in '%~dp0logs' for details.
) else (
    echo.
    echo ========================================================
    echo  Service successfully installed and started!
    echo  API Docs: http://localhost:8000/docs
    echo  Health:   http://localhost:8000/api/v1/health
    echo ========================================================
)

echo.
pause
