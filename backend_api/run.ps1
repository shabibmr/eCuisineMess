# Start eCuisine Mess Module Backend API on port 8000
# Usage:  pwsh -File .\run.ps1
# Or:     right-click → Run with PowerShell

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

Write-Host '========================================================' -ForegroundColor Cyan
Write-Host ' Starting eCuisine Mess Module Backend API on port 8000' -ForegroundColor Cyan
Write-Host '========================================================' -ForegroundColor Cyan
Write-Host " Working dir: $PWD"
Write-Host ' Docs:        http://127.0.0.1:8000/docs'
Write-Host ''

python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload

Write-Host ''
Write-Host 'Server stopped.' -ForegroundColor Yellow
Read-Host 'Press Enter to close'
