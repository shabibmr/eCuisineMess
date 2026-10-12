# Digital signing helper for eCuisine Mess executables and installer
param(
    [string[]]$Files,
    [string]$PfxPath = "$PSScriptRoot\..\certs\ecuisine_dev.pfx",
    [string]$Password = "eCuisineDev2026!",
    [string]$TimestampUrl = "http://timestamp.digicert.com"
)

$ErrorActionPreference = "Stop"

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

    throw "signtool.exe was not found. Please install Windows SDK or Visual Studio."
}

$signtool = Find-SignTool
Write-Host "Using SignTool: $signtool" -ForegroundColor Cyan

if (-not (Test-Path $PfxPath)) {
    throw "Certificate file not found at: $PfxPath"
}

# If no files specified, sign default bundle files that exist
if (-not $Files -or $Files.Count -eq 0) {
    $Root = Split-Path -Parent $PSScriptRoot
    $Files = @(
        (Join-Path $Root "dist\mess-api\mess-api.exe"),
        (Join-Path $Root "dist\mess-api\mess-api-service.exe"),
        (Join-Path $Root "third_party\WinSW-x64.exe"),
        (Join-Path (Split-Path -Parent $Root) "ecuisine_mess\build\windows\x64\runner\Release\ecuisine_mess.exe"),
        (Join-Path $Root "dist\eCuisineMess_full_installer.exe")
    )
}

foreach ($target in $Files) {
    if (Test-Path $target) {
        Write-Host "Signing: $target" -ForegroundColor Yellow
        & $signtool sign /f "$PfxPath" /p "$Password" /fd SHA256 /tr "$TimestampUrl" /td SHA256 "$target"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Successfully signed." -ForegroundColor Green
        } else {
            Write-Warning "  Failed to sign $target (Exit code: $LASTEXITCODE)"
        }
    } else {
        Write-Host "Skipping (not found): $target" -ForegroundColor Gray
    }
}
