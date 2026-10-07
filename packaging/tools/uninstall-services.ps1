# Stop and remove the eCuisine Mess services. Database files stay unless -RemoveData.
param(
    [Parameter(Mandatory = $true)][string]$AppDir,
    [Parameter(Mandatory = $true)][string]$DataDir,
    [switch]$RemoveData
)

$ErrorActionPreference = "Continue"

function Remove-OneService {
    param([string]$Wrapper)
    if (Test-Path $Wrapper) {
        & $Wrapper stop 2>$null | Out-Null
        & $Wrapper uninstall 2>$null | Out-Null
    }
}

Remove-OneService (Join-Path $AppDir "server\EcuisineMessApi.exe")
Remove-OneService (Join-Path $AppDir "mariadb\EcuisineMessDb.exe")
& sc.exe stop EcuisineMessApi 2>$null | Out-Null
& sc.exe stop EcuisineMessDb 2>$null | Out-Null
& sc.exe delete EcuisineMessApi 2>$null | Out-Null
& sc.exe delete EcuisineMessDb 2>$null | Out-Null

Get-NetFirewallRule -DisplayName "eCuisine Mess API 8000" -ErrorAction SilentlyContinue |
    Remove-NetFirewallRule -ErrorAction SilentlyContinue

if ($RemoveData -and (Test-Path $DataDir)) {
    Remove-Item -LiteralPath $DataDir -Recurse -Force -ErrorAction SilentlyContinue
}

exit 0
