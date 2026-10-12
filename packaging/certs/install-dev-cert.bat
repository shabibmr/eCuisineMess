@echo off
:: Installs the self-signed eCuisine development certificate on this PC
:: Right-click and "Run as administrator"
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Administrator privileges required. Right-click and select "Run as administrator".
    pause
    exit /b 1
)

echo Trusting eCuisine Development Certificate...
certutil -addstore -f "Root" "%~dp0ecuisine_dev.cer"
certutil -addstore -f "TrustedPublisher" "%~dp0ecuisine_dev.cer"

echo.
echo [OK] Certificate installed. Windows will now trust eCuisine signed binaries without SmartScreen warnings.
pause
