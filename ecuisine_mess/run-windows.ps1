#Requires -Version 7.0
<#
.SYNOPSIS
  Run the eCuisine Mess Flutter app on Windows and write the session log here.

.DESCRIPTION
  Starts `flutter run -d windows` from this script's directory.
  Console output is mirrored to flutter-windows.log in the same folder.
  Extra arguments are forwarded, for example:
    pwsh -File .\run-windows.ps1 --dart-define=FOO=bar

.EXAMPLE
  pwsh -File .\run-windows.ps1
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$projectRoot = $PSScriptRoot
$logFile = Join-Path $projectRoot 'flutter-windows.log'

Set-Location -LiteralPath $projectRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error 'flutter was not found on PATH.'
    exit 1
}

$writer = [System.IO.StreamWriter]::new(
    $logFile,
    $false,
    [System.Text.UTF8Encoding]::new($false))
$writer.AutoFlush = $true

function Write-LogLine {
    param([string] $Line)
    $writer.WriteLine($Line)
    Write-Host $Line
}

try {
    Write-LogLine "===== flutter run -d windows ====="
    Write-LogLine "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-LogLine "Directory: $projectRoot"
    if ($args.Count -gt 0) {
        Write-LogLine "Extra args: $($args -join ' ')"
    }
    Write-LogLine "Log file: $logFile"
    Write-LogLine ''

    & flutter run -d windows @args 2>&1 | ForEach-Object {
        Write-LogLine "$_"
    }

    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) {
        $exitCode = 0
    }

    Write-LogLine ''
    Write-LogLine "===== exited $exitCode at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ====="
    exit $exitCode
}
finally {
    $writer.Dispose()
}
