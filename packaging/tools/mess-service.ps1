# Start, stop, or query the eCuisine Mess Windows services.
# Used by the Flutter app. Standard users can start the services after install.
param(
    [Parameter(Position = 0)]
    [ValidateSet("status", "start", "stop")]
    [string]$Action = "status"
)

$ErrorActionPreference = "Stop"

function Test-ScOk {
    param([int]$Code)
    # 0 success, 1056 already running, 1062 already stopped
    return ($Code -eq 0 -or $Code -eq 1056 -or $Code -eq 1062)
}

switch ($Action) {
    "status" {
        & sc.exe query EcuisineMessDb
        & sc.exe query EcuisineMessApi
        exit 0
    }
    "start" {
        & sc.exe start EcuisineMessDb | Out-Null
        if (-not (Test-ScOk $LASTEXITCODE)) { exit $LASTEXITCODE }
        $admin = Join-Path $PSScriptRoot "..\mariadb\bin\mariadb-admin.exe"
        if (Test-Path $admin) {
            for ($i = 0; $i -lt 20; $i++) {
                & $admin --protocol=tcp -u root -P 3306 ping 2>$null | Out-Null
                if ($LASTEXITCODE -eq 0) { break }
                Start-Sleep -Seconds 1
            }
        }
        & sc.exe start EcuisineMessApi | Out-Null
        if (-not (Test-ScOk $LASTEXITCODE)) { exit $LASTEXITCODE }
        exit 0
    }
    "stop" {
        & sc.exe stop EcuisineMessApi | Out-Null
        if (-not (Test-ScOk $LASTEXITCODE)) { exit $LASTEXITCODE }
        & sc.exe stop EcuisineMessDb | Out-Null
        if (-not (Test-ScOk $LASTEXITCODE)) { exit $LASTEXITCODE }
        exit 0
    }
}
