# Build eCuisine Mess Backend API into an Executable and Windows Service Package
# Usage: pwsh -File .\build_exe.ps1

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$RootDir = Split-Path -Parent $ScriptDir
$PackagingDir = Join-Path $RootDir "packaging"
$SpecFile = Join-Path $PackagingDir "mess-api.spec"
$DistDir = Join-Path $PackagingDir "dist\mess-api"
$ThirdPartyDir = Join-Path $PackagingDir "third_party"
$WinSwExe = Join-Path $ThirdPartyDir "WinSW-x64.exe"
$WinSwUrl = "https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW-x64.exe"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Building Backend API Executable & Windows Service Package  " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Resolve Python executable
function Get-PythonCmd {
    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($py) { return @("py", "-3.13") }
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) { return @($python.Source) }
    throw "Python was not found in PATH."
}

$pyCmd = Get-PythonCmd
$pyExe = $pyCmd[0]
$pyArgs = @()
if ($pyCmd.Length -gt 1) { $pyArgs = $pyCmd[1..($pyCmd.Length - 1)] }

# 2. Ensure PyInstaller is installed
Write-Host "[1/4] Checking PyInstaller..." -ForegroundColor Yellow
& $pyExe @pyArgs -m pip show pyinstaller 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing PyInstaller..." -ForegroundColor Yellow
    & $pyExe @pyArgs -m pip install pyinstaller
}

# 3. Ensure WinSW is downloaded
Write-Host "[2/4] Checking Windows Service Wrapper (WinSW)..." -ForegroundColor Yellow
if (-not (Test-Path $WinSwExe)) {
    New-Item -ItemType Directory -Force -Path $ThirdPartyDir | Out-Null
    Write-Host "Downloading WinSW from $WinSwUrl..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $WinSwUrl -OutFile $WinSwExe -UseBasicParsing
}

# 4. Run PyInstaller
Write-Host "[3/4] Compiling Backend API to EXE with PyInstaller..." -ForegroundColor Yellow
Push-Location $PackagingDir
try {
    & $pyExe @pyArgs -m PyInstaller $SpecFile --distpath dist --workpath build --noconfirm
    if ($LASTEXITCODE -ne 0) { throw "PyInstaller failed with code $LASTEXITCODE" }
}
finally {
    Pop-Location
}

# 5. Assemble Service Artifacts
Write-Host "[4/4] Setting up Windows Service wrapper files..." -ForegroundColor Yellow
$TemplatesDir = Join-Path $PackagingDir "service_templates"
if (Test-Path $TemplatesDir) {
    Copy-Item -Path (Join-Path $TemplatesDir "*") -Destination $DistDir -Force
}
Copy-Item -Path $WinSwExe -Destination (Join-Path $DistDir "mess-api-service.exe") -Force

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " BUILD COMPLETED SUCCESSFULLY!                              " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host " Output Directory: $DistDir"
Write-Host " - Backend EXE:     $(Join-Path $DistDir 'mess-api.exe')"
Write-Host " - Service Wrapper: $(Join-Path $DistDir 'mess-api-service.exe')"
Write-Host " - Service XML:     $(Join-Path $DistDir 'mess-api-service.xml')"
Write-Host " - Install Script:  $(Join-Path $DistDir 'install_service.bat')"
Write-Host ""
Write-Host " To install and run as a Windows Service:"
Write-Host "   1. Navigate to: $DistDir"
Write-Host "   2. Right-click 'install_service.bat' -> 'Run as administrator'"
Write-Host "============================================================" -ForegroundColor Green
