# Deployment on Windows

The shipped client installer is the Full Mess PC bundle in [packaging/README.md](../../packaging/README.md): Flutter exe, frozen API (WinSW service `EcuisineMessApi`), and bundled MariaDB (WinSW service `EcuisineMessDb`). Both services start at boot and restart on failure. The NSSM steps below are the manual fallback when you run the API from a Python venv.

Companion to [common Windows setup](../../docs/07-windows-setup.md). This covers running the API reliably on a server PC.

## 1. Layout on the server

```
C:\mess\
├── backend_api\          (copy of repo folder; .venv inside)
├── database\             (schema, seed, migrations)
├── logs\                 (api.out.log, api.err.log)
└── backups\
```

## 2. Install

```powershell
cd C:\mess\backend_api
py -3.13 -m venv .venv
.\.venv\Scripts\python -m pip install -U pip
.\.venv\Scripts\pip install -r requirements.txt
```
Set machine-level environment variables (System Properties → Environment Variables, or):
```powershell
[Environment]::SetEnvironmentVariable("MESS_DB_HOST","127.0.0.1","Machine")
[Environment]::SetEnvironmentVariable("MESS_DB_USER","mess_api","Machine")
[Environment]::SetEnvironmentVariable("MESS_DB_PASSWORD","<secret>","Machine")
[Environment]::SetEnvironmentVariable("MESS_DB_NAME","ecuisine_mess","Machine")
[Environment]::SetEnvironmentVariable("MESS_SUPERVISOR_PIN","<new-pin>","Machine")   # until real supervisor auth ships
```
Create the DB user:
```sql
CREATE USER 'mess_api'@'127.0.0.1' IDENTIFIED BY '<secret>';
GRANT SELECT, INSERT, UPDATE, DELETE ON ecuisine_mess.* TO 'mess_api'@'127.0.0.1';
```

## 3. Run

| Mode | Command | Use |
|---|---|---|
| Dev | `pwsh -File run.ps1` / `run.bat` | `--reload`, console, `0.0.0.0:8000` |
| Prod | `.\.venv\Scripts\python -m uvicorn main:app --host 0.0.0.0 --port 8000 --workers 1` | no `--reload` |

**Workers:** use **1 worker** initially (a pooled sync app on one process comfortably serves a mess). If you scale to several workers, the DB-side token/duplicate guards ([database-access §4](database-access.md)) are mandatory, and pool sizes are per process (`workers × maxconnections` ≤ MariaDB `max_connections`).

## 4. Windows service (NSSM)

```powershell
nssm install EcuisineMessApi "C:\mess\backend_api\.venv\Scripts\python.exe" "-m uvicorn main:app --host 0.0.0.0 --port 8000"
nssm set EcuisineMessApi AppDirectory C:\mess\backend_api
nssm set EcuisineMessApi AppStdout C:\mess\logs\api.out.log
nssm set EcuisineMessApi AppStderr C:\mess\logs\api.err.log
nssm set EcuisineMessApi AppRotateFiles 1
nssm set EcuisineMessApi AppRotateBytes 10485760
nssm set EcuisineMessApi Start SERVICE_AUTO_START
nssm set EcuisineMessApi DependOnService MariaDB     # adjust to the actual service name
nssm start EcuisineMessApi
```
(Alternative: Task Scheduler "At startup", run as SYSTEM, `Restart on failure`.)

Firewall:
```powershell
New-NetFirewallRule -DisplayName "Mess API 8000" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow -Profile Private,Domain
```

## 5. Verify

```powershell
Invoke-RestMethod http://localhost:8000/api/v1/health          # status online, database connected
Invoke-RestMethod http://<server-ip>:8000/api/v1/health        # from a counter PC
```

## 6. Upgrade procedure

1. Announce a short window; stop the service: `nssm stop EcuisineMessApi`.
2. **Back up the DB** (`mysqldump --single-transaction`).
3. Copy new `backend_api`; `pip install -r requirements.txt`.
4. Apply new `database/migrations/NNN_*.sql` in order (never re-run applied ones).
5. `nssm start EcuisineMessApi`; hit `/health`; run `scripts/smoke.ps1`.
6. Roll back = stop, restore previous folder + DB dump, start.

Keep API and client versions compatible: the API only adds fields within `/api/v1`; breaking changes need a new prefix or a coordinated client release.

## 7. Backups & retention

Nightly `mysqldump` via Task Scheduler (script in [03 §8](../../docs/03-database-design.md)); keep 14 daily + 12 monthly; test a restore quarterly. Weekly session purge. Bills are the audit trail — never purge them.

## 8. Monitoring

- Health: `GET /api/v1/health` every minute from a scheduled task; alert on non-`online`.
- Logs: rotate NSSM logs; watch for `Transaction rolled back` and `Unhandled exception`.
- MariaDB: `SHOW PROCESSLIST` for stuck locks during token issue; slow-query log on at 0.5 s.
- Clock: server on NTP — meal windows depend on it.

## 9. Troubleshooting

| Symptom | Check |
|---|---|
| `database: disconnected` in health | MariaDB service running? `MESS_DB_*` correct? user grants? |
| 500 on every call | `logs\api.err.log`; DB schema out of date (missing `mess_uoms` → apply migration) |
| Counters can't connect | Firewall rule, server IP, client Server Settings URL, API bound to `0.0.0.0` |
| Pool wait / slow | raise `MESS_DB_MAX_CONNECTIONS`; check slow queries; N+1 list endpoints |
| Wrong meal detected | server clock/timezone; `mess_meal_times` windows |
| Arabic shows `????` | DB/table charset not utf8mb4 |
