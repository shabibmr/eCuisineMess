@echo off
setlocal enabledelayedexpansion

set "BASE_DIR=%~dp0mariadb-11.4.5-winx64"
set "BIN_DIR=%BASE_DIR%\bin"
set "DATA_DIR=%~dp0data"

:: Allow custom port as 1st argument, otherwise default to 3306
set "DB_PORT=%~1"
if "%DB_PORT%"=="" set "DB_PORT=3306"

echo ========================================================
echo  Starting eCuisine MariaDB Server (Port: %DB_PORT%)
echo ========================================================

:: Check if data folder exists
if not exist "%DATA_DIR%\mysql" (
    echo [ERROR] Data directory does not exist yet!
    echo Please run init_db.bat first to initialize the database.
    echo.
    pause
    exit /b 1
)

:: Check if already running
"%BIN_DIR%\mariadb-admin.exe" -u root -P %DB_PORT% ping >nul 2>&1
if !errorlevel! EQU 0 (
    echo [INFO] MariaDB is ALREADY running on port %DB_PORT%.
    pause
    exit /b 0
)

echo Starting MariaDB on port %DB_PORT%...
echo Press Ctrl+C or run stop_db.bat to stop the server.
echo.

"%BIN_DIR%\mariadbd.exe" --datadir="%DATA_DIR%" --basedir="%BASE_DIR%" --port=%DB_PORT% --console
