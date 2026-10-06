# ecuisine_mess

Flutter client for the eCuisine Mess Billing & Management module.

Talks to the FastAPI backend (`backend_api/`) or a Frappe site using the same `/api/v1/...` and `/api/method/mess_module.api.*` routes.

## Features

- Login (default `admin` / `admin123`)
- RFID counter kiosk with token slip + supervisor override
- Members, Cuisines, Item Categories, Bill Register, Reports

## Run (Windows)

1. Start MariaDB (XAMPP or service) and the backend:
   ```powershell
   cd backend_api
   pip install -r requirements.txt
   pwsh -File .\run.ps1
   ```
   Or double-click `backend_api/run.bat`.

2. Run the Flutter client:
   ```bash
   cd ecuisine_mess
   flutter pub get
   flutter run -d windows
   ```

Sign in with `admin` / `admin123`.  
API default: `http://127.0.0.1:8000` (gear icon on the login screen to change it).

**Note:** First Windows build can take several minutes (CMake / Visual Studio toolchain). Enable **Developer Mode** in Windows Settings if Flutter asks for symlink support.
