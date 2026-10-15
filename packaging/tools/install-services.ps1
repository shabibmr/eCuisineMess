# Register MariaDB and the frozen API as auto-start Windows services.
# Called by the Inno Setup installer after files are copied.
# Everything is logged to <DataDir>\logs\install.log. On failure a diagnostics dump
# (service state, port owners, service/MariaDB logs, SCM events) is appended there.
param(
    [Parameter(Mandatory = $true)][string]$AppDir,
    [Parameter(Mandatory = $true)][string]$DataDir
)

$ErrorActionPreference = "Stop"

$script:DbServiceName = "EcuisineMessDb"
$script:ApiServiceName = "EcuisineMessApi"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")][string]$Level = "INFO"
    )
    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    try {
        $logDir = Join-Path $DataDir "logs"
        New-Item -ItemType Directory -Force -Path $logDir | Out-Null
        Add-Content -Path (Join-Path $logDir "install.log") -Value $line -Encoding utf8
    }
    catch {
        # Never let a logging problem hide the real failure.
        Write-Host "(could not write install.log: $($_.Exception.Message))"
    }
    Write-Host $line
}

function Escape-XmlText {
    param([string]$Value)
    return [System.Security.SecurityElement]::Escape($Value)
}

# Run a native command without letting stderr output (e.g. MariaDB warnings) trip
# $ErrorActionPreference = "Stop". Output goes to the install log; returns the exit code.
# -Label names the step so the exit code is always logged.
function Invoke-Native {
    param(
        [scriptblock]$Command,
        [string]$Label = ""
    )
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $out = & $Command 2>&1
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $prev
    }
    foreach ($line in $out) {
        $text = "$line".Trim()
        if ($text) { Write-Log "  $text" }
    }
    if ($Label) {
        $level = if ($code -eq 0) { "INFO" } else { "ERROR" }
        Write-Log "$Label exit code $code" -Level $level
    }
    return $code
}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-FileInfo {
    param([string]$Label, [string]$Path)
    if (Test-Path $Path) {
        $size = (Get-Item $Path).Length
        Write-Log "  ok      $Label : $Path ($size bytes)"
    }
    else {
        Write-Log "  MISSING $Label : $Path" -Level ERROR
    }
}

function Write-Environment {
    Write-Log "---- Environment ----"
    Write-Log "OS: $([Environment]::OSVersion.VersionString) (64-bit OS: $([Environment]::Is64BitOperatingSystem))"
    Write-Log "PowerShell: $($PSVersionTable.PSVersion) (64-bit process: $([Environment]::Is64BitProcess))"
    Write-Log "User: $([Environment]::UserDomainName)\$([Environment]::UserName), elevated: $(Test-IsAdmin)"
    Write-Log "AppDir=$AppDir"
    Write-Log "DataDir=$DataDir"
    if (-not (Test-IsAdmin)) {
        Write-Log "Script is not running elevated; service registration will most likely fail." -Level WARN
    }
    try {
        $drive = (Get-Item $DataDir).PSDrive
        if ($drive -and $null -ne $drive.Free) {
            Write-Log ("Free space on {0}: {1:N0} MB" -f $drive.Name, ($drive.Free / 1MB))
        }
    }
    catch {
        Write-Log "Could not read free disk space: $($_.Exception.Message)" -Level WARN
    }
}

function Write-PortOwners {
    param([int[]]$Ports)
    foreach ($port in $Ports) {
        try {
            $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction Stop
            foreach ($c in $conns) {
                $procName = (Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue).ProcessName
                Write-Log "  port $port listening on $($c.LocalAddress) by PID $($c.OwningProcess) ($procName)"
            }
        }
        catch {
            Write-Log "  port $port : nothing listening"
        }
    }
}

function Test-PortFree {
    param([int]$Port)
    $busy = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($busy) {
        $pids = ($busy | Select-Object -ExpandProperty OwningProcess -Unique) -join ", "
        $names = ($busy | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object {
                (Get-Process -Id $_ -ErrorAction SilentlyContinue).ProcessName
            }) -join ", "
        throw "Port $Port is already in use (PID $pids, process $names). Stop XAMPP or the other MariaDB, then run setup again."
    }
    Write-Log "Port $Port is free"
}

# Returns the SCM state name (RUNNING, STOPPED, START_PENDING, ...) or $null if not installed.
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
    param(
        [string]$Name,
        [string]$Wanted = "RUNNING",
        [int]$Seconds = 30
    )
    $last = ""
    for ($i = 0; $i -lt $Seconds; $i++) {
        $state = Get-ServiceState -Name $Name
        if ($state -ne $last) {
            Write-Log "Service $Name state: $state (after ${i}s)"
            $last = $state
        }
        if ($state -eq $Wanted) { return $true }
        # A service that fell back to STOPPED while we wait for RUNNING has crashed; no point waiting.
        if ($Wanted -eq "RUNNING" -and $state -eq "STOPPED" -and $i -ge 3) { return $false }
        Start-Sleep -Seconds 1
    }
    Write-Log "Service $Name did not reach $Wanted within ${Seconds}s (last state: $last)" -Level ERROR
    return $false
}

function Write-ServiceDiagnostics {
    param([string]$Name)
    Write-Log "---- Service $Name ----"
    $state = Get-ServiceState -Name $Name
    if ($null -eq $state) {
        Write-Log "Service $Name is not registered with the Service Control Manager" -Level ERROR
        return
    }
    Invoke-Native { & sc.exe queryex $Name } | Out-Null
    Invoke-Native { & sc.exe qc $Name } | Out-Null
    try {
        $svc = Get-CimInstance Win32_Service -Filter "Name='$Name'" -ErrorAction Stop
        if ($svc) {
            Write-Log "  StartName=$($svc.StartName) StartMode=$($svc.StartMode) State=$($svc.State) ExitCode=$($svc.ExitCode) ServiceSpecificExitCode=$($svc.ServiceSpecificExitCode)"
        }
    }
    catch {
        Write-Log "  Could not query Win32_Service: $($_.Exception.Message)" -Level WARN
    }
}

function Write-LogTail {
    param([string]$Path, [int]$Lines = 40)
    if (-not (Test-Path $Path)) { return }
    Write-Log "---- Last $Lines lines of $Path ----"
    try {
        foreach ($line in (Get-Content -Path $Path -Tail $Lines -ErrorAction Stop)) {
            $text = "$line".TrimEnd()
            if ($text) { Write-Log "  | $text" }
        }
    }
    catch {
        Write-Log "  Could not read ${Path}: $($_.Exception.Message)" -Level WARN
    }
}

function Write-ServiceEvents {
    Write-Log "---- Recent Service Control Manager events ----"
    try {
        $events = Get-WinEvent -FilterHashtable @{
            LogName      = "System"
            ProviderName = "Service Control Manager"
            StartTime    = (Get-Date).AddMinutes(-15)
        } -MaxEvents 60 -ErrorAction Stop |
            Where-Object { $_.Message -match "eCuisine|Ecuisine" } |
            Select-Object -First 12
        if (-not $events) {
            Write-Log "  (no matching events)"
            return
        }
        foreach ($e in $events) {
            $msg = ($e.Message -replace "\s+", " ").Trim()
            Write-Log ("  {0} id={1} {2}" -f $e.TimeCreated.ToString("HH:mm:ss"), $e.Id, $msg)
        }
    }
    catch {
        Write-Log "  (no events or could not read: $($_.Exception.Message))"
    }
}

# Everything useful to diagnose a failed install or start, in one place.
function Write-FailureDiagnostics {
    Write-Log "======== Failure diagnostics ========" -Level ERROR
    try {
        Write-ServiceDiagnostics -Name $script:DbServiceName
        Write-ServiceDiagnostics -Name $script:ApiServiceName
        Write-Log "---- Port listeners ----"
        Write-PortOwners -Ports @(3306, 8000)

        $logDir = Join-Path $DataDir "logs"
        if (Test-Path $logDir) {
            Write-Log "---- Files in $logDir ----"
            Get-ChildItem -Path $logDir -File -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Log ("  {0}  {1,10:N0} bytes  {2}" -f $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"), $_.Length, $_.Name)
            }
            # WinSW writes <id>.out.log, <id>.err.log and <id>.wrapper.log here.
            foreach ($name in @($script:DbServiceName, $script:ApiServiceName)) {
                foreach ($suffix in @("wrapper", "err", "out")) {
                    Write-LogTail -Path (Join-Path $logDir "$name.$suffix.log") -Lines 40
                }
            }
        }

        $dataPath = Join-Path $DataDir "mariadb-data"
        if (Test-Path $dataPath) {
            Get-ChildItem -Path $dataPath -Filter "*.err" -File -ErrorAction SilentlyContinue |
                ForEach-Object { Write-LogTail -Path $_.FullName -Lines 60 }
        }

        Write-ServiceEvents
    }
    catch {
        Write-Log "Diagnostics itself failed: $($_.Exception.Message)" -Level WARN
    }
    Write-Log "======== End diagnostics ========" -Level ERROR
}

function Grant-ServiceStart {
    param([string]$Name)
    $raw = & sc.exe sdshow $Name
    if ($LASTEXITCODE -ne 0) {
        Write-Log "sdshow $Name failed (exit $LASTEXITCODE): $raw" -Level WARN
        return
    }
    $sddl = (($raw | ForEach-Object { "$_".Trim() }) -join "") -replace "\s", ""
    if (-not $sddl.StartsWith("D:")) {
        Write-Log "Unexpected SDDL for ${Name}: $sddl" -Level WARN
        return
    }
    if ($sddl -match "\(A;;[^)]*RP[^)]*;;;AU\)") {
        Write-Log "Authenticated users can already start $Name"
        return
    }
    $updated = $sddl -replace "^D:", "D:(A;;RPLC;;;AU)"
    $out = & sc.exe sdset $Name $updated
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Could not grant start rights on $Name (exit $LASTEXITCODE): $out" -Level WARN
    }
    else {
        Write-Log "Granted start rights on $Name to authenticated users"
    }
}

function Set-RestartOnFailure {
    param([string]$Name)
    $out = & sc.exe failure $Name reset= 86400 actions= restart/10000/restart/10000/restart/10000
    if ($LASTEXITCODE -ne 0) {
        Write-Log "sc failure $Name returned $LASTEXITCODE : $out" -Level WARN
    }
    $out = & sc.exe failureflag $Name 1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "sc failureflag $Name returned $LASTEXITCODE : $out" -Level WARN
    }
    else {
        Write-Log "Restart-on-failure configured for $Name"
    }
}

function Write-ServiceXml {
    param(
        [string]$Path,
        [string]$Id,
        [string]$DisplayName,
        [string]$Description,
        [string]$Executable,
        [string]$Arguments,
        [string]$WorkDir,
        [string]$Depend
    )
    $logPath = Escape-XmlText (Join-Path $DataDir "logs")
    $exe = Escape-XmlText $Executable
    $args = Escape-XmlText $Arguments
    $work = ""
    if ($WorkDir) {
        $work = "  <workingdirectory>$(Escape-XmlText $WorkDir)</workingdirectory>`r`n"
    }
    $dependXml = ""
    if ($Depend) {
        $dependXml = "  <depend>$Depend</depend>`r`n"
    }
    $envXml = ""
    if ($Id -eq "EcuisineMessApi") {
        $envXml = @"
  <env name="MESS_DATA_DIR" value="$(Escape-XmlText $DataDir)"/>
  <env name="MESS_CONFIG_FILE" value="$(Escape-XmlText (Join-Path $DataDir 'config.env'))"/>

"@
    }
    $xml = @"
<service>
  <id>$Id</id>
  <name>$DisplayName</name>
  <description>$Description</description>
  <executable>$exe</executable>
  <arguments>$args</arguments>
$work$dependXml$envXml  <logpath>$logPath</logpath>
  <log mode="roll-by-size">
    <sizeThreshold>10240</sizeThreshold>
    <keepFiles>8</keepFiles>
  </log>
  <onfailure action="restart" delay="10 sec"/>
  <onfailure action="restart" delay="10 sec"/>
  <onfailure action="restart" delay="10 sec"/>
  <resetfailure>1 day</resetfailure>
  <startmode>Automatic</startmode>
  <waithint>30 sec</waithint>
  <stoptimeout>20 sec</stoptimeout>
</service>
"@
    Set-Content -Path $Path -Value $xml -Encoding UTF8
    Write-Log "Wrote service definition $Path (executable: $Executable)"
}

function Install-WinSw {
    param([string]$WrapperExe, [string]$Id)
    if (-not (Test-Path $WrapperExe)) {
        throw "Missing service wrapper: $WrapperExe"
    }
    $xmlPath = [System.IO.Path]::ChangeExtension($WrapperExe, ".xml")
    if (-not (Test-Path $xmlPath)) {
        throw "Missing service definition next to the wrapper: $xmlPath"
    }
    Write-Log "Registering $Id with $WrapperExe"
    # Clean up any previous registration. Failures here are expected on a first install.
    Invoke-Native { & $WrapperExe stop } -Label "winsw stop $Id (pre-clean, failure is normal on first install)" | Out-Null
    Invoke-Native { & $WrapperExe uninstall } -Label "winsw uninstall $Id (pre-clean, failure is normal on first install)" | Out-Null
    $code = Invoke-Native { & $WrapperExe install } -Label "winsw install $Id"
    if ($code -ne 0) {
        throw "WinSW install failed for $WrapperExe (exit $code). Check the output above and $xmlPath"
    }
    $state = Get-ServiceState -Name $Id
    if ($null -eq $state) {
        throw "WinSW reported success but service $Id is not registered with the Service Control Manager"
    }
    Write-Log "Service $Id registered (state: $state)"
}

function Start-WinSwService {
    param([string]$WrapperExe, [string]$Id, [int]$Seconds = 30)
    Write-Log "Starting service $Id"
    $code = Invoke-Native { & $WrapperExe start } -Label "winsw start $Id"
    if ($code -ne 0) {
        throw "Could not start $Id (exit $code)"
    }
    if (-not (Wait-ServiceState -Name $Id -Wanted "RUNNING" -Seconds $Seconds)) {
        throw "$Id was started but is not running (state: $(Get-ServiceState -Name $Id))"
    }
    Write-Log "Service $Id is running"
}

function Wait-DbPing {
    param(
        [string]$AdminExe,
        [int]$Port = 3306,
        [string]$User = "root",
        [string]$Password = "",
        [int]$Seconds = 30,
        $Process = $null
    )
    $authArgs = @("-u", $User, "-P", "$Port")
    if ($Password) { $authArgs += "-p$Password" }
    Write-Log "Waiting up to ${Seconds}s for MariaDB to answer on port $Port as $User"
    $lastOut = ""
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        for ($i = 0; $i -lt $Seconds; $i++) {
            if ($Process -and $Process.HasExited) {
                throw "MariaDB process exited with code $($Process.ExitCode) before answering on port $Port. See the *.err file in $DataDir\mariadb-data"
            }
            $lastOut = (& $AdminExe --protocol=tcp @authArgs ping 2>&1 | ForEach-Object { "$_".Trim() }) -join " "
            if ($LASTEXITCODE -eq 0) {
                Write-Log "MariaDB answered on port $Port after ${i}s"
                return
            }
            if ($i -gt 0 -and ($i % 5) -eq 0) {
                Write-Log "  still waiting (${i}s): $lastOut" -Level WARN
            }
            Start-Sleep -Seconds 1
        }
    }
    finally {
        $ErrorActionPreference = $prev
    }
    throw "MariaDB did not answer on port $Port within ${Seconds}s. Last response: $lastOut"
}

function Initialize-Database {
    param(
        [string]$BinDir,
        [string]$BaseDir,
        [string]$DataPath,
        [int]$Port = 3306,
        [string]$DbUser = "user2grey",
        [string]$DbPass = "user2grey",
        [string]$DbName = "ecuisine_mess"
    )
    $marker = Join-Path $DataPath "mysql"
    if (Test-Path (Join-Path $DataPath $DbName)) {
        Write-Log "Database data directory already exists ($DataPath). Skipping schema import."
        return
    }
    if (Test-Path $marker) {
        # Left behind by an interrupted install: system tables but our database was never created.
        Write-Log "Removing incomplete MariaDB data directory from a previous failed install: $DataPath" -Level WARN
        Remove-Item -Recurse -Force -Path $DataPath
    }

    Test-PortFree -Port $Port
    $installDb = Join-Path $BinDir "mariadb-install-db.exe"
    $server = Join-Path $BinDir "mariadbd.exe"
    $client = Join-Path $BinDir "mariadb.exe"
    $admin = Join-Path $BinDir "mariadb-admin.exe"
    $schema = Join-Path $DataDir "sql\schema.sql"
    $seed = Join-Path $DataDir "sql\seed.sql"
    foreach ($f in @($installDb, $server, $client, $admin)) {
        if (-not (Test-Path $f)) { throw "Missing MariaDB tool: $f" }
    }
    if (-not (Test-Path $schema)) { throw "Missing $schema" }
    if (-not (Test-Path $seed)) { throw "Missing $seed" }
    Write-Log "Schema: $schema ($((Get-Item $schema).Length) bytes), seed: $seed ($((Get-Item $seed).Length) bytes)"

    Write-Log "Initializing MariaDB data directory at $DataPath"
    New-Item -ItemType Directory -Force -Path $DataPath | Out-Null
    $code = Invoke-Native { & $installDb --datadir="$DataPath" --silent } -Label "mariadb-install-db"
    if ($code -ne 0) { throw "mariadb-install-db failed (exit $code)" }

    Write-Log "Starting temporary MariaDB on port $Port for first-time setup"
    $proc = Start-Process -FilePath $server -ArgumentList @(
        "--datadir=$DataPath",
        "--basedir=$BaseDir",
        "--port=$Port",
        "--bind-address=127.0.0.1",
        "--console"
    ) -PassThru -WindowStyle Hidden
    Write-Log "Temporary MariaDB started as PID $($proc.Id)"
    try {
        Wait-DbPing -AdminExe $admin -Port $Port -User "root" -Process $proc
        Write-Log "Creating database $DbName and user $DbUser on port $Port"
        $sqlInit = @"
CREATE DATABASE IF NOT EXISTS $DbName CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DbUser'@'127.0.0.1' IDENTIFIED BY '$DbPass';
GRANT ALL PRIVILEGES ON $DbName.* TO '$DbUser'@'127.0.0.1';
FLUSH PRIVILEGES;
"@
        $code = Invoke-Native { & $client --protocol=tcp -u root -P $Port -e "$sqlInit" } -Label "create database and user"
        if ($code -ne 0) { throw "Database and user creation failed (exit $code)" }

        Write-Log "Importing schema into $DbName"
        $code = Invoke-Native { cmd /c "`"$client`" --protocol=tcp -u $DbUser -p$DbPass -P $Port $DbName < `"$schema`"" } -Label "schema import"
        if ($code -ne 0) { throw "schema import failed (exit $code)" }

        Write-Log "Importing seed data into $DbName"
        $code = Invoke-Native { cmd /c "`"$client`" --protocol=tcp -u $DbUser -p$DbPass -P $Port $DbName < `"$seed`"" } -Label "seed import"
        if ($code -ne 0) { throw "seed import failed (exit $code)" }
        Write-Log "Database initialized"
    }
    catch {
        Write-Log "Database setup failed: $($_.Exception.Message)" -Level ERROR
        if ($proc.HasExited) {
            Write-Log "Temporary MariaDB exited early with code $($proc.ExitCode)" -Level ERROR
        }
        Get-ChildItem -Path $DataPath -Filter "*.err" -File -ErrorAction SilentlyContinue |
            ForEach-Object { Write-LogTail -Path $_.FullName -Lines 60 }
        throw
    }
    finally {
        Write-Log "Shutting down temporary MariaDB"
        Invoke-Native { & $admin --protocol=tcp -u root -P $Port shutdown } -Label "mariadb-admin shutdown" | Out-Null
        if (-not $proc.HasExited) {
            Wait-Process -Id $proc.Id -Timeout 20 -ErrorAction SilentlyContinue
        }
        if (-not $proc.HasExited) {
            Write-Log "Temporary MariaDB did not stop in 20s; killing PID $($proc.Id)" -Level WARN
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
        else {
            Write-Log "Temporary MariaDB stopped (exit code $($proc.ExitCode))"
        }
    }
}

try {
    Write-Log "=== Install services started ==="
    Write-Environment
    foreach ($name in @("logs", "backups", "sql", "static\uploads\members")) {
        New-Item -ItemType Directory -Force -Path (Join-Path $DataDir $name) | Out-Null
    }

    $dbPort = 3306
    $dbUser = "user2grey"
    $dbPass = "user2grey"
    $dbName = "ecuisine_mess"

    $configPath = Join-Path $DataDir "config.env"
    if (-not (Test-Path $configPath)) {
        @"
MESS_DB_HOST=127.0.0.1
MESS_DB_PORT=$dbPort
MESS_DB_USER=$dbUser
MESS_DB_PASSWORD=$dbPass
MESS_DB_NAME=$dbName
MESS_SUPERVISOR_PIN=1234
"@ | Set-Content -Path $configPath -Encoding ascii
        Write-Log "Wrote default config.env configured for port $dbPort"
    }
    else {
        Write-Log "Keeping existing config.env at $configPath"
    }

    $mariaBin = Join-Path $AppDir "mariadb\bin"
    $mariaBase = Join-Path $AppDir "mariadb"
    $dataPath = Join-Path $DataDir "mariadb-data"
    $apiExe = Join-Path $AppDir "server\mess-api.exe"
    $dbWrapper = Join-Path $mariaBase "EcuisineMessDb.exe"
    $apiWrapper = Join-Path $AppDir "server\EcuisineMessApi.exe"

    Write-Log "---- Required files ----"
    Write-FileInfo "API executable" $apiExe
    Write-FileInfo "MariaDB server" (Join-Path $mariaBin "mariadbd.exe")
    Write-FileInfo "DB service wrapper" $dbWrapper
    Write-FileInfo "API service wrapper" $apiWrapper
    if (-not (Test-Path $apiExe)) { throw "Missing $apiExe. Build the frozen API first." }
    if (-not (Test-Path (Join-Path $mariaBin "mariadbd.exe"))) { throw "Missing MariaDB binaries in $mariaBin." }

    foreach ($svcName in @($script:DbServiceName, $script:ApiServiceName)) {
        $existingState = Get-ServiceState -Name $svcName
        if ($existingState) {
            Write-Log "Service $svcName already registered (state: $existingState); it will be re-registered"
        }
    }

    Initialize-Database -BinDir $mariaBin -BaseDir $mariaBase -DataPath $dataPath -Port $dbPort -DbUser $dbUser -DbPass $dbPass -DbName $dbName
    Test-PortFree -Port $dbPort

    $dbXml = Join-Path $mariaBase "EcuisineMessDb.xml"
    $apiXml = Join-Path $AppDir "server\EcuisineMessApi.xml"
    Write-ServiceXml -Path $dbXml -Id "EcuisineMessDb" -DisplayName "eCuisine Mess Database" `
        -Description "MariaDB for eCuisine Mess on port $dbPort. Starts at boot and restarts on failure." `
        -Executable (Join-Path $mariaBin "mariadbd.exe") `
        -Arguments "--datadir=`"$dataPath`" --basedir=`"$mariaBase`" --port=$dbPort --bind-address=127.0.0.1 --console" `
        -WorkDir "" -Depend ""
    Write-ServiceXml -Path $apiXml -Id "EcuisineMessApi" -DisplayName "eCuisine Mess API" `
        -Description "FastAPI backend for eCuisine Mess. Starts after MariaDB and restarts on failure." `
        -Executable $apiExe `
        -Arguments "" `
        -WorkDir (Join-Path $AppDir "server") `
        -Depend "EcuisineMessDb"

    Write-Log "Registering services"
    Install-WinSw -WrapperExe $dbWrapper -Id $script:DbServiceName
    Install-WinSw -WrapperExe $apiWrapper -Id $script:ApiServiceName
    Set-RestartOnFailure -Name $script:DbServiceName
    Set-RestartOnFailure -Name $script:ApiServiceName
    Grant-ServiceStart -Name $script:DbServiceName
    Grant-ServiceStart -Name $script:ApiServiceName

    $rule = "eCuisine Mess API 8000"
    $existing = Get-NetFirewallRule -DisplayName $rule -ErrorAction SilentlyContinue
    if (-not $existing) {
        New-NetFirewallRule -DisplayName $rule -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow -Profile Private,Domain | Out-Null
        Write-Log "Firewall rule added for TCP 8000"
    }
    else {
        Write-Log "Firewall rule '$rule' already exists"
    }

    Write-Log "Starting services"
    Start-WinSwService -WrapperExe $dbWrapper -Id $script:DbServiceName
    Wait-DbPing -AdminExe (Join-Path $mariaBin "mariadb-admin.exe") -Port $dbPort -User $dbUser -Password $dbPass
    Start-WinSwService -WrapperExe $apiWrapper -Id $script:ApiServiceName

    $healthUrl = "http://127.0.0.1:8000/api/v1/health"
    Write-Log "Waiting up to 40s for $healthUrl to report database=connected"
    $healthy = $false
    $lastHealth = ""
    for ($i = 0; $i -lt 40; $i++) {
        try {
            $res = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 2
            $lastHealth = "HTTP ok, body: $($res | ConvertTo-Json -Compress -Depth 3)"
            if ($res.database -eq "connected") {
                $healthy = $true
                Write-Log "Health check passed after ${i}s: $lastHealth"
                break
            }
        }
        catch {
            $lastHealth = $_.Exception.Message
        }
        if ($i -gt 0 -and ($i % 5) -eq 0) {
            Write-Log "  health check still failing (${i}s): $lastHealth  [API service: $(Get-ServiceState -Name $script:ApiServiceName)]" -Level WARN
        }
        if ((Get-ServiceState -Name $script:ApiServiceName) -eq "STOPPED") {
            throw "API service stopped while waiting for the health check. Last health result: $lastHealth"
        }
        Start-Sleep -Seconds 1
    }
    if (-not $healthy) {
        throw "API health check did not report database=connected. Last result: $lastHealth. See logs under $DataDir\logs"
    }
    Write-Log "=== Install services finished. Health check passed. ==="
    exit 0
}
catch {
    $err = $_
    Write-Log "$($err.Exception.GetType().FullName): $($err.Exception.Message)" -Level ERROR
    if ($err.InvocationInfo -and $err.InvocationInfo.PositionMessage) {
        Write-Log ("Location: " + ($err.InvocationInfo.PositionMessage -replace "\s+", " ")) -Level ERROR
    }
    if ($err.ScriptStackTrace) {
        foreach ($frame in ($err.ScriptStackTrace -split "`r?`n")) {
            Write-Log "  at $frame" -Level ERROR
        }
    }
    Write-FailureDiagnostics
    Write-Log "=== Install services FAILED. Full details above; share this file when reporting the problem: $(Join-Path $DataDir 'logs\install.log') ===" -Level ERROR
    exit 1
}
