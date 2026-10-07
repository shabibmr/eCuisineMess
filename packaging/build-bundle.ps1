# Build the Full Mess PC inputs: Flutter Release, frozen API, WinSW, VC++ redist.
# Does not install services and does not run the installer (this PC may already use port 3306).
param(
    [switch]$SkipFlutter
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Packaging = $PSScriptRoot
$FlutterDir = Join-Path $Root "ecuisine_mess"
$ApiDir = Join-Path $Root "backend_api"
$ThirdParty = Join-Path $Packaging "third_party"
$Redist = Join-Path $Packaging "redist"
$Venv = Join-Path $Packaging ".venv"
$WinSwUrl = "https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW-x64.exe"
$VcUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"

function Get-Python {
    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($py) { return @("py", "-3.13") }
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) { return @($python.Source) }
    throw "Python 3.13 was not found. Install it, then run this script again."
}

function Save-IfMissing {
    param([string]$Url, [string]$Dest)
    if (Test-Path $Dest) {
        Write-Host "Already present: $Dest"
        return
    }
    $dir = Split-Path -Parent $Dest
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Write-Host "Downloading $Url"
    Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing
}

if (-not $SkipFlutter) {
    Write-Host "Building Flutter Windows release"
    Push-Location $FlutterDir
    try {
        & flutter build windows --release
        if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed (exit $LASTEXITCODE)" }
    }
    finally {
        Pop-Location
    }
}

$pyArgs = Get-Python
$pyExe = $pyArgs[0]
$pyRest = @()
if ($pyArgs.Length -gt 1) { $pyRest = $pyArgs[1..($pyArgs.Length - 1)] }

if (-not (Test-Path (Join-Path $Venv "Scripts\python.exe"))) {
    Write-Host "Creating packaging venv"
    & $pyExe @pyRest -m venv $Venv
    if ($LASTEXITCODE -ne 0) { throw "venv creation failed" }
}

$venvPy = Join-Path $Venv "Scripts\python.exe"
& $venvPy -m pip install -U pip
if ($LASTEXITCODE -ne 0) { throw "pip upgrade failed" }
& $venvPy -m pip install -r (Join-Path $ApiDir "requirements.txt") pyinstaller
if ($LASTEXITCODE -ne 0) { throw "pip install failed" }

Write-Host "Freezing mess-api (onedir)"
Push-Location $Packaging
try {
    & $venvPy -m PyInstaller .\mess-api.spec --distpath .\dist --workpath .\build --noconfirm --clean
    if ($LASTEXITCODE -ne 0) { throw "PyInstaller failed (exit $LASTEXITCODE)" }
}
finally {
    Pop-Location
}

Save-IfMissing -Url $WinSwUrl -Dest (Join-Path $ThirdParty "WinSW-x64.exe")
Save-IfMissing -Url $VcUrl -Dest (Join-Path $Redist "vc_redist.x64.exe")

$iss = Join-Path $Packaging "ecuisine_mess_full.iss"
$iscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
Write-Host ""
Write-Host "Bundle inputs are ready. Compile the installer on a machine that will not be the acceptance test:"
if (Test-Path $iscc) {
    Write-Host "  & `"$iscc`" `"$iss`""
}
else {
    Write-Host "  ISCC.exe `"$iss`""
    Write-Host "Install Inno Setup 6 if ISCC.exe is not on this PC."
}
Write-Host "Do not run the setup on a PC where XAMPP or another server already listens on port 3306."
Write-Host "Installer output: packaging\dist\ecuisine_mess_full_1.0.0.exe"
