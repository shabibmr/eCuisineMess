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
pwsh -File .\build-bundle.ps1
```

That builds the Flutter Windows release, freezes `serve.py` with PyInstaller (onedir), and downloads WinSW 2.12.0 and the VC++ 2015–2022 x64 redist if they are missing. Binaries are not committed.

Then compile `ecuisine_mess_full.iss` with Inno Setup 6 (`ISCC.exe`). The setup file is `packaging\dist\ecuisine_mess_full_1.0.0.exe`.

`-SkipFlutter` skips the Flutter build when `ecuisine_mess\build\windows\x64\runner\Release` is already current.

## Do not install on the XAMPP dev PC

The installer stops if TCP 3306 is already taken, and the first install imports `database\schema.sql` and `database\seed.sql` only when `%ProgramData%\eCuisine Mess\mariadb-data\mysql` is missing. Verify on a clean Windows user or VM:

- After install and after reboot, both services are Running and Automatic.
- Killing `mess-api.exe` comes back (service recovery).
- With the API stopped, the Flutter app asks "Mess server is not running. Start it?" and a standard user can start it.
- Login works. A member photo saved under ProgramData is served at `/static/...`.
- An upgrade keeps bills and members. Uninstall with the default (keep data), then reinstall, does not wipe them.

Schema changes stay a manual release-note step. The installer does not run `database\migrations`.

Go-live must change `MESS_SUPERVISOR_PIN` in `config.env` (the default is `1234`) and the seed admin password.
