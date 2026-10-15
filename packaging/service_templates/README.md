# eCuisine Mess API Service

This distribution contains the standalone compiled executable (`mess-api.exe`) and the Windows Service wrapper (`mess-api-service.exe`).

## Directory Structure

- `mess-api.exe` — The frozen FastAPI / Uvicorn backend API server.
- `_internal/` — Bundled Python runtime, DLLs, and dependencies.
- `mess-api-service.exe` — Windows Service wrapper (WinSW).
- `mess-api-service.xml` — Service configuration (auto-start, restart-on-failure, logging).
- `install_service.bat` — Installs and starts the service (Run as Administrator).
- `uninstall_service.bat` — Stops and removes the service (Run as Administrator).
- `config.env.sample` — Configuration template (Database credentials, ports, etc.).
- `logs/` — Auto-rotated service and API output logs.

---

## 1. Running as a Windows Service (Recommended for Production)

### Option A: Using the Batch Scripts
1. Right-click `install_service.bat` and select **Run as administrator**.
2. To uninstall, right-click `uninstall_service.bat` and select **Run as administrator**.

### Option B: Using Command Line / PowerShell (Administrator)
```powershell
# Install the service
.\mess-api-service.exe install

# Start the service
.\mess-api-service.exe start

# Check status
.\mess-api-service.exe status

# Stop the service
.\mess-api-service.exe stop

# Uninstall the service
.\mess-api-service.exe uninstall
```

### Option C: Using Windows Service Control (`sc.exe` / `net`)
Once installed via WinSW, the service is a native Windows Service named `EcuisineMessApi`:
```cmd
net start EcuisineMessApi
net stop EcuisineMessApi
sc query EcuisineMessApi
```

---

## 2. Running Standalone (Console / Debug Mode)

If you just want to run the server in a console window for testing without installing a service:

```cmd
mess-api.exe
```

The API will listen by default on `http://0.0.0.0:8000`.

---

## 3. Configuration

Edit `config.env` in this directory:

```ini
MESS_API_PORT=8000
MESS_DB_HOST=127.0.0.1
MESS_DB_PORT=3306
MESS_DB_USER=user2grey
MESS_DB_PASSWORD=user2grey
MESS_DB_NAME=ecuisine_mess
MESS_SUPERVISOR_PIN=1234
```

---

## 4. Verification

- API Health Endpoint: `http://localhost:8000/api/v1/health`
- Swagger Documentation: `http://localhost:8000/docs`
- Service Logs: `logs/mess-api-service.log` and `logs/mess-api-service.out.log`
