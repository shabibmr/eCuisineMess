# Full Mess PC bundle

One Inno Setup installer for a mess counter PC:

1. Flutter `ecuisine_mess.exe` under Program Files.
2. Frozen API as Windows service `EcuisineMessApi` (WinSW, auto-start, restart on failure).
3. Bundled MariaDB as Windows service `EcuisineMessDb` (starts first; the API depends on it).

Writable state stays in `%ProgramData%\eCuisine Mess` (`config.env`, `mariadb-data`, member photos, logs). Upgrades replace program files and keep that folder. Uninstall asks before deleting it. The default answer is No.

NSSM remains the manual fallback in `backend_api/docs/deployment-windows.md`. This bundle is the path that ships to the client.

## Build

From `packaging` on a developer PC:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-bundle.ps1
```

That:
1. Downloads MariaDB 11.4.5 portable, WinSW 2.12.0, and VC++ redistributable if missing.
2. Builds the Flutter Windows release (`ecuisine_mess.exe`).
3. Freezes `serve.py` with PyInstaller (onedir into `packaging\dist\mess-api`).
4. Digitally signs all executables using Authenticode & SHA256 timestamp (`packaging\tools\sign-binaries.ps1`).
5. Compiles and signs `packaging\dist\ecuisine_mess_full_1.0.0.exe` using Inno Setup 6 (`ISCC.exe`).

Parameters:
- `-SkipFlutter`: Skip rebuilding Flutter if already up-to-date.
- `-SkipApi`: Skip rebuilding PyInstaller freeze.
- `-SkipMariaDb`: Skip MariaDB zip check.

## Database & Services Configuration

- **Database**: MariaDB runs on the standard port **`3306`** (the installer aborts if another MySQL/MariaDB/XAMPP already listens on it).
- **Credentials**: User `user2grey` / password `user2grey`.
- **First Install**: Automatically creates `ecuisine_mess` and imports `database\schema.sql` and `database\seed.sql`.
- **Upgrades / Updates**: If `%ProgramData%\eCuisine Mess\mariadb-data\mysql` already exists, database initialization and seed import are skipped, preserving all existing user data, members, and transactions.
- **Go-Live**: Update `MESS_SUPERVISOR_PIN` and passwords in `%ProgramData%\eCuisine Mess\config.env`.
