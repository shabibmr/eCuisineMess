@echo off
setlocal enabledelayedexpansion

set "BASE_DIR=%~dp0mariadb-11.4.5-winx64"
set "BIN_DIR=%BASE_DIR%\bin"
set "DATA_DIR=%~dp0data"

:: Allow custom port as 1st argument, otherwise default to 3306
set "DB_PORT=%~1"
if "%DB_PORT%"=="" set "DB_PORT=3306"

echo ========================================================
echo  Initializing Portable MariaDB (Port: %DB_PORT%)
echo ========================================================

:: 1. Initialize data directory if not already created
if not exist "%DATA_DIR%\mysql" (
    echo [1/4] Creating database data directory...
    "%BIN_DIR%\mariadb-install-db.exe" --datadir="%DATA_DIR%" --silent
    if errorlevel 1 (
        echo [ERROR] Failed to initialize database directory.
        pause
        exit /b 1
    )
    echo [OK] Data directory created.
) else (
    echo [1/4] Data directory already exists. Skipping init.
)

:: 2. Start MariaDB server temporarily in the background
echo [2/4] Starting temporary MariaDB instance on port %DB_PORT%...
start "" /b "%BIN_DIR%\mariadbd.exe" --datadir="%DATA_DIR%" --basedir="%BASE_DIR%" --port=%DB_PORT%

:: Wait up to 10 seconds for server to start
set "SERVER_UP=0"
for /L %%i in (1,1,10) do (
    "%BIN_DIR%\mariadb-admin.exe" -u root -P %DB_PORT% ping >nul 2>&1
    if !errorlevel! EQU 0 (
        set "SERVER_UP=1"
        goto :server_ready
    )
    timeout /t 1 /nobreak >nul
)

:server_ready
if "%SERVER_UP%"=="0" (
    echo [ERROR] Could not start MariaDB on port %DB_PORT%.
    echo Is port %DB_PORT% already in use? You can pass another port: init_db.bat 3307
    pause
    exit /b 1
)

echo [OK] MariaDB is running.

:: 3. Create database and import schema + seed
echo [3/4] Creating database 'ecuisine_mess' and importing schema...
"%BIN_DIR%\mariadb.exe" -u root -P %DB_PORT% -e "CREATE DATABASE IF NOT EXISTS ecuisine_mess CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

set "SCHEMA_FILE=%~dp0..\database\schema.sql"
set "SEED_FILE=%~dp0..\database\seed.sql"

if exist "%SCHEMA_FILE%" (
    echo Importing schema from %SCHEMA_FILE%...
    "%BIN_DIR%\mariadb.exe" -u root -P %DB_PORT% ecuisine_mess < "%SCHEMA_FILE%"
    echo [OK] Schema imported.
) else (
    echo [WARN] schema.sql not found at %SCHEMA_FILE%
)

if exist "%SEED_FILE%" (
    echo Importing seed data from %SEED_FILE%...
    "%BIN_DIR%\mariadb.exe" -u root -P %DB_PORT% ecuisine_mess < "%SEED_FILE%"
    echo [OK] Seed data imported.
) else (
    echo [WARN] seed.sql not found at %SEED_FILE%
)

:: 4. Stop temporary server
echo [4/4] Stopping temporary server...
"%BIN_DIR%\mariadb-admin.exe" -u root -P %DB_PORT% shutdown >nul 2>&1

echo ========================================================
echo  MariaDB Initialized and Seeded Successfully!
echo  You can now start it anytime using start_db.bat
echo ========================================================
pause
