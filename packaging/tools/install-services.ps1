# Register MariaDB and the frozen API as auto-start Windows services.
# Called by the Inno Setup installer after files are copied.
param(
    [Parameter(Mandatory = $true)][string]$AppDir,
    [Parameter(Mandatory = $true)][string]$DataDir
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    $logDir = Join-Path $DataDir "logs"
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    Add-Content -Path (Join-Path $logDir "install.log") -Value $line -Encoding utf8
    Write-Host $line
}

function Escape-XmlText {
    param([string]$Value)
    return [System.Security.SecurityElement]::Escape($Value)
}

function Test-PortFree {
    param([int]$Port)
    $busy = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($busy) {
        $pids = ($busy | Select-Object -ExpandProperty OwningProcess -Unique) -join ", "
        throw "Port $Port is already in use (PID $pids). Stop XAMPP or the other MariaDB, then run setup again."
    }
}

function Grant-ServiceStart {
    param([string]$Name)
    $raw = & sc.exe sdshow $Name
    if ($LASTEXITCODE -ne 0) {
        Write-Log "WARN sdshow $Name failed"
        return
    }
    $sddl = (($raw | ForEach-Object { "$_".Trim() }) -join "") -replace "\s", ""
    if (-not $sddl.StartsWith("D:")) {
        Write-Log "WARN unexpected SDDL for $Name"
        return
    }
    if ($sddl -match "\(A;;[^)]*RP[^)]*;;;AU\)") {
        return
    }
    $updated = $sddl -replace "^D:", "D:(A;;RPLC;;;AU)"
    & sc.exe sdset $Name $updated | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Log "WARN could not grant start rights on $Name"
    }
}

function Set-RestartOnFailure {
    param([string]$Name)
    & sc.exe failure $Name reset= 86400 actions= restart/10000/restart/10000/restart/10000 | Out-Null
    & sc.exe failureflag $Name 1 | Out-Null
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
}

function Install-WinSw {
    param([string]$WrapperExe)
    if (-not (Test-Path $WrapperExe)) {
        throw "Missing service wrapper: $WrapperExe"
    }
    & $WrapperExe stop 2>$null | Out-Null
    & $WrapperExe uninstall 2>$null | Out-Null
    & $WrapperExe install
    if ($LASTEXITCODE -ne 0) {
        throw "WinSW install failed for $WrapperExe (exit $LASTEXITCODE)"
    }
}

function Wait-DbPing {
    param(
        [string]$AdminExe,
        [int]$Port = 8233,
        [string]$User = "root",
        [string]$Password = "",
        [int]$Seconds = 30
    )
    $authArgs = @("-u", $User, "-P", "$Port")
    if ($Password) { $authArgs += "-p$Password" }
    for ($i = 0; $i -lt $Seconds; $i++) {
        & $AdminExe --protocol=tcp @authArgs ping 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { return }
        Start-Sleep -Seconds 1
    }
    throw "MariaDB did not answer on port $Port."
}

function Initialize-Database {
    param(
        [string]$BinDir,
        [string]$BaseDir,
        [string]$DataPath,
        [int]$Port = 8233,
        [string]$DbUser = "ecuisine_user",
        [string]$DbPass = "MessDbPass8233!",
        [string]$DbName = "ecuisine_mess"
    )
    $marker = Join-Path $DataPath "mysql"
    if (Test-Path $marker) {
        Write-Log "Database data directory already exists. Skipping schema import."
        return
    }

    Test-PortFree -Port $Port
    $installDb = Join-Path $BinDir "mariadb-install-db.exe"
    $server = Join-Path $BinDir "mariadbd.exe"
    $client = Join-Path $BinDir "mariadb.exe"
    $admin = Join-Path $BinDir "mariadb-admin.exe"
    $schema = Join-Path $DataDir "sql\schema.sql"
    $seed = Join-Path $DataDir "sql\seed.sql"
    if (-not (Test-Path $schema)) { throw "Missing $schema" }
    if (-not (Test-Path $seed)) { throw "Missing $seed" }

    Write-Log "Initializing MariaDB data directory"
    New-Item -ItemType Directory -Force -Path $DataPath | Out-Null
    & $installDb --datadir="$DataPath" --silent
    if ($LASTEXITCODE -ne 0) { throw "mariadb-install-db failed (exit $LASTEXITCODE)" }

    $proc = Start-Process -FilePath $server -ArgumentList @(
        "--datadir=$DataPath",
        "--basedir=$BaseDir",
        "--port=$Port",
        "--bind-address=127.0.0.1",
        "--console"
    ) -PassThru -WindowStyle Hidden
    try {
        Wait-DbPing -AdminExe $admin -Port $Port -User "root"
        Write-Log "Creating database $DbName and user $DbUser on port $Port"
        $sqlInit = @"
CREATE DATABASE IF NOT EXISTS $DbName CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DbUser'@'127.0.0.1' IDENTIFIED BY '$DbPass';
GRANT ALL PRIVILEGES ON $DbName.* TO '$DbUser'@'127.0.0.1';
FLUSH PRIVILEGES;
"@
        & $client --protocol=tcp -u root -P $Port -e "$sqlInit"
        if ($LASTEXITCODE -ne 0) { throw "Database and user creation failed" }

        Write-Log "Importing schema into $DbName"
        cmd /c "`"$client`" --protocol=tcp -u $DbUser -p$DbPass -P $Port $DbName < `"$schema`""
        if ($LASTEXITCODE -ne 0) { throw "schema import failed" }

        Write-Log "Importing seed data into $DbName"
        cmd /c "`"$client`" --protocol=tcp -u $DbUser -p$DbPass -P $Port $DbName < `"$seed`""
        if ($LASTEXITCODE -ne 0) { throw "seed import failed" }
    }
    finally {
        & $admin --protocol=tcp -u root -P $Port shutdown 2>$null | Out-Null
        if (-not $proc.HasExited) {
            Wait-Process -Id $proc.Id -Timeout 20 -ErrorAction SilentlyContinue
        }
        if (-not $proc.HasExited) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
    }
}

try {
    Write-Log "Install services started. AppDir=$AppDir"
    foreach ($name in @("logs", "backups", "sql", "static\uploads\members")) {
        New-Item -ItemType Directory -Force -Path (Join-Path $DataDir $name) | Out-Null
    }

    $dbPort = 8233
    $dbUser = "ecuisine_user"
    $dbPass = "MessDbPass8233!"
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

    $mariaBin = Join-Path $AppDir "mariadb\bin"
    $mariaBase = Join-Path $AppDir "mariadb"
    $dataPath = Join-Path $DataDir "mariadb-data"
    $apiExe = Join-Path $AppDir "server\mess-api.exe"
    if (-not (Test-Path $apiExe)) { throw "Missing $apiExe. Build the frozen API first." }
    if (-not (Test-Path (Join-Path $mariaBin "mariadbd.exe"))) { throw "Missing MariaDB binaries." }

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
    Install-WinSw -WrapperExe (Join-Path $mariaBase "EcuisineMessDb.exe")
    Install-WinSw -WrapperExe (Join-Path $AppDir "server\EcuisineMessApi.exe")
    Set-RestartOnFailure -Name "EcuisineMessDb"
    Set-RestartOnFailure -Name "EcuisineMessApi"
    Grant-ServiceStart -Name "EcuisineMessDb"
    Grant-ServiceStart -Name "EcuisineMessApi"

    $rule = "eCuisine Mess API 8000"
    $existing = Get-NetFirewallRule -DisplayName $rule -ErrorAction SilentlyContinue
    if (-not $existing) {
        New-NetFirewallRule -DisplayName $rule -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow -Profile Private,Domain | Out-Null
        Write-Log "Firewall rule added for TCP 8000"
    }

    Write-Log "Starting services"
    & (Join-Path $mariaBase "EcuisineMessDb.exe") start
    Wait-DbPing -AdminExe (Join-Path $mariaBin "mariadb-admin.exe") -Port $dbPort -User $dbUser -Password $dbPass
    & (Join-Path $AppDir "server\EcuisineMessApi.exe") start

    $healthy = $false
    for ($i = 0; $i -lt 40; $i++) {
        try {
            $res = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/health" -TimeoutSec 2
            if ($res.database -eq "connected") {
                $healthy = $true
                break
            }
        }
        catch { }
        Start-Sleep -Seconds 1
    }
    if (-not $healthy) {
        throw "API health check did not report database=connected. See logs under $DataDir\logs"
    }
    Write-Log "Install services finished. Health check passed."
    exit 0
}
catch {
    Write-Log "ERROR $($_.Exception.Message)"
    exit 1
}
