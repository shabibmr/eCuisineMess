# 07 — Windows Setup & Run

Everything runs on **Windows 10/11**. Commands are PowerShell unless noted. Repo root: `D:\QtWorkspace\DIT\DITUAE\counter\Mess_Module` (called `$ROOT`).

## 1. Prerequisites

| Tool | Version | Check |
|---|---|---|
| MariaDB (XAMPP `D:\xampp\mysql` **or** bundled `$ROOT\mariadb`) | 10.6+ | `mysql --version` |
| Python | 3.13 (3.11+ OK) | `python --version` |
| Flutter SDK | 3.44.x stable (Dart ≥ 3.12) | `flutter --version` |
| Visual Studio 2022 | "Desktop development with C++" workload | `flutter doctor` |
| Windows desktop support | enabled | `flutter config --enable-windows-desktop` |
| Git | any | |

`flutter doctor -v` must show ✔ for **Windows Version** and **Visual Studio**.

## 2. Database

```powershell
$MYSQL = "D:\xampp\mysql\bin\mysql.exe"       # adjust
# Fresh install
& $MYSQL -u root -e "SOURCE $ROOT/database/schema.sql"
& $MYSQL -u root -e "SOURCE $ROOT/database/seed.sql"

# Reset everything (destructive – dev only)
& $MYSQL -u root -e "DROP DATABASE IF EXISTS ecuisine_mess;"
```
(Use forward slashes inside `SOURCE`.) The bundled instance can be started with `mariadb\connect_db.bat`.

Verify:
```powershell
& $MYSQL -u root ecuisine_mess -e "SHOW TABLES; SELECT username FROM mess_users;"
```
Expect 13 tables (incl. `mess_uoms`) and user `admin`.

## 3. Backend

```powershell
cd $ROOT\backend_api
python -m venv .venv                 # recommended
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
pwsh -File .\run.ps1                 # or double-click run.bat
```
- API: <http://127.0.0.1:8000> · Swagger: <http://127.0.0.1:8000/docs> · Health: `/api/v1/health`
- Login: `admin` / `admin123`

Environment overrides (defaults in parentheses):

| Variable | Meaning |
|---|---|
| `MESS_DB_HOST` (`localhost`) | DB host |
| `MESS_DB_PORT` (`3306`) | DB port |
| `MESS_DB_USER` (`root`) | DB user |
| `MESS_DB_PASSWORD` (empty) | DB password |
| `MESS_DB_NAME` (`ecuisine_mess`) | Database |
| `MESS_DB_MIN_CACHED` / `MESS_DB_MAX_CACHED` / `MESS_DB_MAX_CONNECTIONS` (`2` / `10` / `20`) | Connection pool |
| `MESS_SESSION_DAYS` (`7`) | Session lifetime |
| `MESS_SUPERVISOR_PIN` (`1234`) | Demo supervisor PIN — change it |

```powershell
$env:MESS_DB_USER = "mess_api"; $env:MESS_DB_PASSWORD = "…"; pwsh -File .\run.ps1
```

Smoke test:
```powershell
Invoke-RestMethod http://127.0.0.1:8000/api/v1/health
$r = Invoke-RestMethod -Method Post http://127.0.0.1:8000/api/v1/auth/login -ContentType application/json `
     -Body (@{username="admin";password="admin123"} | ConvertTo-Json)
$r.token
```

## 4. Flutter client

```powershell
cd $ROOT\ecuisine_mess
flutter pub get
flutter run -d windows
```
- First screen is **Login**. Gear icon → **Server Settings** to change the API URL (default `http://127.0.0.1:8000`).
- Release build: `flutter build windows --release` → `build\windows\x64\runner\Release\ecuisine_mess.exe` (ship the whole `Release` folder).
- Quality gates: `flutter analyze` · `flutter test`.

## 5. Running the mock UI (reference)

Open `mock-ui\index.html` in Chrome/Edge, or `cd mock-ui; python -m http.server 8080`. Press `Ctrl+Shift+D` for the demo panel.

## 6. RFID reader

Use a USB reader in **keyboard-wedge** mode (types the card number then `Enter`). No driver code is needed: the counter page keeps a focused `TextField` and submits on Enter. Configure the reader to **append Enter** and to output the same number format used when registering members. For testing without hardware use the in-app **RFID Tap Simulator** (debug builds).

## 7. Production-ish layout (server + counters)

1. **Server PC**: install MariaDB (service), create DB user, import schema/seed, install Python + deps, run the API as a Windows service (NSSM):
   ```powershell
   nssm install EcuisineMessApi "C:\mess\backend_api\.venv\Scripts\python.exe" "-m uvicorn main:app --host 0.0.0.0 --port 8000"
   nssm set EcuisineMessApi AppDirectory C:\mess\backend_api
   nssm start EcuisineMessApi
   ```
2. Firewall: `New-NetFirewallRule -DisplayName "Mess API" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow`
3. **Counter PCs**: copy the Flutter `Release` folder; set Server Settings to `http://<server-ip>:8000`.
4. Backups: see [03 §8](03-database-design.md).
5. Change the `admin` password and remove the demo PIN before go-live.

## 8. Troubleshooting

| Symptom | Fix |
|---|---|
| `Can't connect to MySQL server` | Start MariaDB; check port/`MESS_DB_*` |
| `Unknown database 'ecuisine_mess'` | Import `schema.sql` |
| Flutter shows "Server unreachable" | API not running / wrong URL in Server Settings / firewall |
| Login always 401 | Re-seed `mess_users`; check bcrypt installed |
| `flutter run -d windows` → no device | `flutter config --enable-windows-desktop`; install VS C++ workload |
| Long-path / build errors | Enable Windows long paths; keep repo path short |
| `command line is too long` in scripts | Put commands in a `.ps1` file instead of inline `-Command` |
| Garbled Arabic text | Ensure DB/connection `utf8mb4` and the Arabic-capable font in the theme |
