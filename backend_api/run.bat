@echo off
echo ========================================================
echo Starting eCuisine Mess Module Backend API on port 8000...
echo ========================================================
python -m uvicorn main:app --app-dir backend_api --host 0.0.0.0 --port 8000 --reload
pause
