# Start, stop, or query the eCuisine Mess Windows services.
# Used by the Flutter app. Standard users can start the services after install.
# Every run is logged to <ProgramData>\eCuisine Mess\logs\service-control.log
# (falls back to %TEMP% when that folder is not writable for the current user).
param(
    [Parameter(Position = 0)]
    [ValidateSet("status", "start", "stop")]
    [string]$Action = "status"
)

$ErrorActionPreference = "Stop"

$DbService = "EcuisineMessDb"
$ApiService = "EcuisineMessApi"

$script:LogFile = $null

function Initialize-LogFile {
    $candidates = @(
        (Join-Path $env:ProgramData "eCuisine Mess\logs"),
        $env:TEMP
    )
    foreach ($dir in $candidates) {
        try {
            if (-not $dir) { continue }
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
            $path = Join-Path $dir "service-control.log"
            Add-Content -Path $path -Value "" -Encoding utf8
            $script:LogFile = $path
            return
        }
        catch { }
    }
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")][string]$Level = "INFO"
    )
    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    if ($script:LogFile) {
        try { Add-Content -Path $script:LogFile -Value $line -Encoding utf8 } catch { }
    }
    # stdout for the calling app; stderr for problems. Write-Host keeps this out of function return values.
    if ($Level -eq "INFO") { Write-Host $line } else { [Console]::Error.WriteLine($line) }
}

function Get-ScMessage {
    param([int]$Code)
    switch ($Code) {
        0 { "success" }
        5 { "access denied (the service permissions were not granted, or the installer did not finish)" }
        1053 { "service did not respond to the start request in time" }
        1056 { "service already running" }
        1060 { "service is not installed (setup did not complete)" }
        1062 { "service already stopped" }
        1058 { "service is disabled" }
        1068 { "a dependency service failed to start" }
        1069 { "service logon failed" }
        1722 { "RPC server unavailable" }
        default { "see 'net helpmsg $Code'" }
    }
}

function Test-ScOk {
    param([int]$Code)
    # 0 success, 1056 already running, 1062 already stopped
    return ($Code -eq 0 -or $Code -eq 1056 -or $Code -eq 1062)
}

# Returns the SCM state name (RUNNING, STOPPED, ...) or $null when the service is not installed.
function Get-ServiceState {
    param([string]$Name)
    $raw = & sc.exe query $Name 2>&1
    if ($LASTEXITCODE -ne 0) { return $null }
    foreach ($line in $raw) {
        if ("$line" -match "STATE\s*:\s*\d+\s+(\w+)") { return $Matches[1] }
    }
    return "UNKNOWN"
}

function Wait-ServiceState {
    param([string]$Name, [string]$Wanted, [int]$Seconds)
    $state = $null
    for ($i = 0; $i -lt $Seconds; $i++) {
        $state = Get-ServiceState -Name $Name
        if ($state -eq $Wanted) { return $true }
        if ($Wanted -eq "RUNNING" -and $state -eq "STOPPED" -and $i -ge 3) { break }
        Start-Sleep -Seconds 1
    }
    Write-Log "$Name did not reach $Wanted (last state: $state)" -Level ERROR
    return $false
}

# Run `sc.exe <verb> <name>`, log the outcome and return the exit code.
function Invoke-Sc {
    param([string]$Verb, [string]$Name)
    Write-Log "sc.exe $Verb $Name"
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $out = & sc.exe $Verb $Name 2>&1
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $prev
    }
    $detail = Get-ScMessage -Code $code
    if (Test-ScOk $code) {
        Write-Log "sc.exe $Verb $Name -> exit $code ($detail)"
    }
    else {
        Write-Log "sc.exe $Verb $Name -> exit $code ($detail)" -Level ERROR
        foreach ($line in $out) {
            $text = "$line".Trim()
            if ($text) { Write-Log "  $text" -Level ERROR }
        }
    }
    return $code
}

# After a failed start, point at the service logs that explain why.
function Write-StartFailureHints {
    param([string]$Name)
    $logDir = Join-Path $env:ProgramData "eCuisine Mess\logs"
    Write-Log "Check $logDir\$Name.err.log, $Name.out.log and $Name.wrapper.log for the cause" -Level ERROR
    foreach ($suffix in @("err", "wrapper")) {
        $file = Join-Path $logDir "$Name.$suffix.log"
        if (-not (Test-Path $file)) { continue }
        try {
            Write-Log "Last lines of ${file}:" -Level ERROR
            foreach ($line in (Get-Content -Path $file -Tail 15 -ErrorAction Stop)) {
                $text = "$line".TrimEnd()
                if ($text) { Write-Log "  | $text" -Level ERROR }
            }
        }
        catch {
            Write-Log "  could not read ${file}: $($_.Exception.Message)" -Level WARN
        }
    }
}

Initialize-LogFile

try {
    Write-Log "mess-service '$Action' as $([Environment]::UserDomainName)\$([Environment]::UserName) (log: $script:LogFile)"

    switch ($Action) {
        "status" {
            foreach ($name in @($DbService, $ApiService)) {
                $state = Get-ServiceState -Name $name
                if ($null -eq $state) {
                    Write-Log "$name : NOT INSTALLED" -Level WARN
                }
                else {
                    Write-Log "$name : $state"
                }
                & sc.exe query $name
            }
            exit 0
        }
        "start" {
            $code = Invoke-Sc -Verb "start" -Name $DbService
            if (-not (Test-ScOk $code)) {
                Write-StartFailureHints -Name $DbService
                exit $code
            }
            if (-not (Wait-ServiceState -Name $DbService -Wanted "RUNNING" -Seconds 30)) {
                Write-StartFailureHints -Name $DbService
                exit 1
            }

            $admin = Join-Path $PSScriptRoot "..\mariadb\bin\mariadb-admin.exe"
            if (Test-Path $admin) {
                $pinged = $false
                for ($i = 0; $i -lt 20; $i++) {
                    & $admin --protocol=tcp -u root -P 3306 ping 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0) { $pinged = $true; break }
                    Start-Sleep -Seconds 1
                }
                if ($pinged) {
                    Write-Log "MariaDB answered on port 3306"
                }
                else {
                    Write-Log "MariaDB did not answer on port 3306 after 20s; starting the API anyway" -Level WARN
                }
            }
            else {
                Write-Log "mariadb-admin.exe not found at $admin; skipping the database ping" -Level WARN
            }

            $code = Invoke-Sc -Verb "start" -Name $ApiService
            if (-not (Test-ScOk $code)) {
                Write-StartFailureHints -Name $ApiService
                exit $code
            }
            if (-not (Wait-ServiceState -Name $ApiService -Wanted "RUNNING" -Seconds 30)) {
                Write-StartFailureHints -Name $ApiService
                exit 1
            }
            Write-Log "Both services are running"
            exit 0
        }
        "stop" {
            $code = Invoke-Sc -Verb "stop" -Name $ApiService
            if (-not (Test-ScOk $code)) { exit $code }
            $code = Invoke-Sc -Verb "stop" -Name $DbService
            if (-not (Test-ScOk $code)) { exit $code }
            Write-Log "Both services are stopped"
            exit 0
        }
    }
}
catch {
    Write-Log "Unhandled error in '$Action': $($_.Exception.GetType().FullName): $($_.Exception.Message)" -Level ERROR
    if ($_.ScriptStackTrace) {
        foreach ($frame in ($_.ScriptStackTrace -split "`r?`n")) {
            Write-Log "  at $frame" -Level ERROR
        }
    }
    exit 1
}
