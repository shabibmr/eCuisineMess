# End-to-end build script for eCuisine Mess full installer:
# 1. Downloads WinSW, VC++ Redist, and MariaDB 11.4.5 portable (if missing)
# 2. Builds Flutter Windows release
# 3. Freezes FastAPI backend with PyInstaller
# 4. Digitally signs all binaries using Authenticode & RFC 3161 timestamp
# 5. Compiles and signs the Inno Setup single installer (ecuisine_mess_full_1.0.0.exe)

param(
    [switch]$SkipFlutter,
    [switch]$SkipApi,
    [switch]$SkipMariaDb,
    [string]$PfxPath = "$PSScriptRoot\certs\ecuisine_dev.pfx",
    [string]$PfxPassword = "eCuisineDev2026!"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Packaging = $PSScriptRoot
$FlutterDir = Join-Path $Root "ecuisine_mess"
$ApiDir = Join-Path $Root "backend_api"
$ThirdParty = Join-Path $Packaging "third_party"
$Redist = Join-Path $Packaging "redist"
$Venv = Join-Path $Packaging ".venv"
$MariaDir = Join-Path $Root "mariadb"
$MariaTarget = Join-Path $MariaDir "mariadb-11.4.5-winx64"

$WinSwUrl = "https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW-x64.exe"
$VcUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
$MariaDbUrl = "https://archive.mariadb.org/mariadb-11.4.5/winx64-packages/mariadb-11.4.5-winx64.zip"

function Get-Python {
    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($py) { return @("py", "-3.13") }
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) { return @($python.Source) }
    throw "Python was not found. Install Python 3.11+, then run this script again."
}

function Save-IfMissing {
    param([string]$Url, [string]$Dest)
    if (Test-Path $Dest) {
        Write-Host "Already present: $Dest" -ForegroundColor Gray
        return
    }
    $dir = Split-Path -Parent $Dest
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Write-Host "Downloading $Url..." -ForegroundColor Cyan
    curl.exe -L --progress-bar -o "$Dest" "$Url"
    if ($LASTEXITCODE -ne 0) {
        throw "Download failed for $Url"
    }
}

# -------------------------------------------------------------
# 1. Download Dependencies (WinSW, VC++ Redist, MariaDB Portable)
# -------------------------------------------------------------
Write-Host "=== [1/5] Checking Dependencies ===" -ForegroundColor Green
Save-IfMissing -Url $WinSwUrl -Dest (Join-Path $ThirdParty "WinSW-x64.exe")
Save-IfMissing -Url $VcUrl -Dest (Join-Path $Redist "vc_redist.x64.exe")

if (-not $SkipMariaDb) {
    if (-not (Test-Path (Join-Path $MariaTarget "bin\mariadbd.exe"))) {
        $zipDest = Join-Path $MariaDir "mariadb-11.4.5-winx64.zip"
        Save-IfMissing -Url $MariaDbUrl -Dest $zipDest
        Write-Host "Extracting MariaDB portable..." -ForegroundColor Cyan
        Expand-Archive -Path $zipDest -DestinationPath $MariaDir -Force
        if (Test-Path $zipDest) { Remove-Item $zipDest -Force }
        Write-Host "MariaDB portable extracted to $MariaTarget" -ForegroundColor Green
    } else {
        Write-Host "Already present: $MariaTarget" -ForegroundColor Gray
    }
}

# -------------------------------------------------------------
# 2. Build Flutter Windows Release
# -------------------------------------------------------------
if (-not $SkipFlutter) {
    Write-Host "`n=== [2/5] Building Flutter Windows Release ===" -ForegroundColor Green
    Push-Location $FlutterDir
    try {
        & flutter build windows --release
        if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed (exit $LASTEXITCODE)" }
    }
    finally {
        Pop-Location
    }
} else {
    Write-Host "`n=== [2/5] Skipping Flutter build ===" -ForegroundColor Gray
}

# -------------------------------------------------------------
# 3. Freeze FastAPI Backend (PyInstaller)
# -------------------------------------------------------------
if (-not $SkipApi) {
    Write-Host "`n=== [3/5] Freezing mess-api ===" -ForegroundColor Green
    $pyArgs = Get-Python
    $pyExe = $pyArgs[0]
    $pyRest = @()
    if ($pyArgs.Length -gt 1) { $pyRest = $pyArgs[1..($pyArgs.Length - 1)] }

    if (-not (Test-Path (Join-Path $Venv "Scripts\python.exe"))) {
        Write-Host "Creating packaging venv..."
        & $pyExe @pyRest -m venv $Venv
        if ($LASTEXITCODE -ne 0) { throw "venv creation failed" }
    }

    $venvPy = Join-Path $Venv "Scripts\python.exe"
    & $venvPy -m pip install -U pip --quiet
    & $venvPy -m pip install -r (Join-Path $ApiDir "requirements.txt") pyinstaller --quiet
    if ($LASTEXITCODE -ne 0) { throw "pip install failed" }

    Push-Location $Packaging
    try {
        & $venvPy -m PyInstaller .\mess-api.spec --distpath .\dist --workpath .\build --noconfirm --clean
        if ($LASTEXITCODE -ne 0) { throw "PyInstaller failed (exit $LASTEXITCODE)" }
    }
    finally {
        Pop-Location
    }
} else {
    Write-Host "`n=== [3/5] Skipping backend freeze ===" -ForegroundColor Gray
}

# -------------------------------------------------------------
# 4. Digitally Sign Binaries
# -------------------------------------------------------------
Write-Host "`n=== [4/5] Digitally Signing Component Binaries ===" -ForegroundColor Green
$signScript = Join-Path $Packaging "tools\sign-binaries.ps1"
if (Test-Path $signScript) {
    & powershell.exe -ExecutionPolicy Bypass -File "$signScript" -PfxPath "$PfxPath" -Password "$PfxPassword"
} else {
    Write-Warning "Signing script not found at $signScript"
}

# -------------------------------------------------------------
# 5. Compile with Inno Setup (Single Installer)
# -------------------------------------------------------------
Write-Host "`n=== [5/5] Compiling Single Inno Setup Installer ===" -ForegroundColor Green
$iss = Join-Path $Packaging "ecuisine_mess_full.iss"

function Find-Iscc {
    $cmd = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
        "${env:LOCALAPPDATA}\Programs\Inno Setup 6\ISCC.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

function Find-SignTool {
    $cmd = Get-Command signtool.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $searchPaths = @(
        "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe",
        "C:\Program Files\Windows Kits\10\bin\*\x64\signtool.exe",
        "C:\Program Files (x86)\Windows Kits\10\App Certification Kit\signtool.exe"
    )
    foreach ($pattern in $searchPaths) {
        $found = Get-Item $pattern -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
        if ($found) { return $found.FullName }
    }
    return $null
}

$iscc = Find-Iscc
$signtool = Find-SignTool

if ($iscc) {
    Write-Host "Compiling installer using: $iscc" -ForegroundColor Cyan
    # Inno Setup's $q token = literal quote, which avoids nested-quote mangling when passing /S to ISCC.
    $signCmd = '$q' + $signtool + '$q sign /f $q' + $PfxPath + '$q /p $q' + $PfxPassword + '$q /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $f'
    & "$iscc" "/Ssigntool=$signCmd" "$iss"
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup compilation failed (exit $LASTEXITCODE)" }
    
    $outExe = Join-Path $Packaging "dist\ecuisine_mess_full_1.0.0.exe"
    if (Test-Path $outExe) {
        Write-Host "`nSUCCESS! Single installer created and signed:" -ForegroundColor Green
        Write-Host "  Path: $outExe" -ForegroundColor Cyan
        $sizeMb = [math]::Round(((Get-Item $outExe).Length / 1MB), 2)
        Write-Host "  Size: $sizeMb MB" -ForegroundColor Cyan
    }
} else {
    Write-Warning "Inno Setup 6 (ISCC.exe) was not found on this machine."
    Write-Host "Install Inno Setup 6 by running:" -ForegroundColor Yellow
    Write-Host "  winget install --id JRSoftware.InnoSetup -e" -ForegroundColor White
    Write-Host "Then run this script again or execute:" -ForegroundColor Yellow
    Write-Host "  ISCC.exe /S`"signtool=`\`"$signtool`\`" sign /f `\`"$PfxPath`\`" /p `\`"$PfxPassword`\`" /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 `$f`" `"$iss`"" -ForegroundColor White
}
