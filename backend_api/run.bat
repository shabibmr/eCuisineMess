@echo off
cd /d "%~dp0"
echo ========================================================
echo Starting eCuisine Mess Module Backend API on port 8000...
echo ========================================================
echo Working dir: %CD%
echo Docs:        http://127.0.0.1:8000/docs
echo.
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
pause
