@echo off
set "BIN_DIR=%~dp0mariadb-11.4.5-winx64\bin"

:: Allow custom port as 1st argument, otherwise default to 3306
set "DB_PORT=%~1"
if "%DB_PORT%"=="" set "DB_PORT=3306"

echo Connecting to MariaDB ecuisine_mess on port %DB_PORT%...
"%BIN_DIR%\mariadb.exe" -u root -P %DB_PORT% ecuisine_mess
