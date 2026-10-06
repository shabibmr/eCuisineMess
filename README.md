# eCuisine Mess Billing & Management Module

A complete full-stack Mess Billing and Canteen Entitlement Management solution featuring an interactive **Flutter Frontend**, **MariaDB Database**, a standalone **Python (FastAPI) Backend**, and a ready-to-deploy **Frappe / ERPNext Custom App**.

## 📚 Documentation

| Scope | Start here |
|---|---|
| **Common** (rules, DB, API contract, UX, standards, Windows setup, roadmap) | [`docs/README.md`](docs/README.md) |
| **Front-end** (Flutter · flutter_bloc + go_router + feature-first) | [`ecuisine_mess/docs/README.md`](ecuisine_mess/docs/README.md) |
| **Back-end** (FastAPI + MariaDB) | [`backend_api/docs/README.md`](backend_api/docs/README.md) |

---

## 🏗️ Architecture & Component Overview

```
Mess_Module/
├── database/                            # MariaDB Database Schema & Seed Data
│   ├── schema.sql                       # Complete DDL relational schema for ecuisine_mess
│   └── seed.sql                         # Initial seed dataset (members, cuisines, items, meal times)
│
├── backend_api/                         # Python FastAPI Standalone Server (Direct MariaDB)
│   ├── main.py                          # REST API & Frappe RPC endpoints
│   ├── db.py                            # MariaDB connection pool & queries
│   ├── requirements.txt                 # Dependencies (fastapi, uvicorn, pymysql)
│   └── run.bat                          # One-click start on port 8000
│
├── frappe_app/mess_module/              # Frappe / ERPNext Custom App
│   ├── pyproject.toml / hooks.py        # Frappe app metadata & hooks
│   ├── mess_module/api.py               # Whitelisted Frappe RPC methods (@frappe.whitelist)
│   └── mess_module/doctype/             # DocTypes (Mess Member, Mess Item, Mess Cuisine, Mess Bill, etc.)
│
├── ecuisine_mess/                       # Production Flutter client (replaces flutter_app)
│   ├── lib/
│   │   ├── config/                      # Theme and API configuration
│   │   ├── models/                      # Member, Cuisine, Item, Category, User, Bill, RFID
│   │   ├── services/                    # ApiService (REST / Frappe RPC client)
│   │   ├── providers/                   # AuthProvider, CounterProvider
│   │   ├── screens/                     # Login, Counter, Members, Cuisines, Categories, Bills, Reports
│   │   └── widgets/                     # RFID Tap Simulator, Thermal Token Slip, Supervisor Override
│   └── pubspec.yaml                     # Dependencies (http, provider, intl, shared_preferences)
│
└── mock-ui/                             # Interactive HTML5/CSS3/Alpine.js Mock Prototype
```

---

## ⚡ Quick Start

### 1. Database Setup (MariaDB)
Ensure MariaDB is running on port `3306`, then import the schema and seeds:
```bash
mysql -u root < database/schema.sql
mysql -u root < database/seed.sql
```

**Existing database** — UUID cutover is breaking. Rebuild:
```powershell
& "D:\xampp\mysql\bin\mysql.exe" -u root -e "DROP DATABASE IF EXISTS ecuisine_mess;"
& "D:\xampp\mysql\bin\mysql.exe" -u root -e "SOURCE D:/QtWorkspace/DIT/DITUAE/counter/Mess_Module/database/schema.sql"
& "D:\xampp\mysql\bin\mysql.exe" -u root -e "SOURCE D:/QtWorkspace/DIT/DITUAE/counter/Mess_Module/database/seed.sql"
```
Or run `database/migrations/003_uuid_ids_drop_codes.sql` (drops and reloads).

### 2. Start the Python Backend API
```powershell
cd backend_api
pip install -r requirements.txt
pwsh -File .\run.ps1
# Or double-click run.bat
```
- API Base URL: `http://localhost:8000`
- Interactive Swagger Docs: `http://localhost:8000/docs`
- Auth: `POST /api/v1/auth/login`, `GET /api/v1/auth/me`, `POST /api/v1/auth/logout`
- Default login: **admin** / **admin123**

### 3. Run the Flutter Frontend on Windows (`ecuisine_mess`)
```bash
cd ecuisine_mess
flutter pub get
flutter run -d windows
```
Sign in with `admin` / `admin123` before using the app shell.  
API default: `http://127.0.0.1:8000` (change via the gear icon on the login screen if needed).

### 4. Optional: Install into Frappe / ERPNext Bench
```bash
# In your Frappe bench directory:
bench get-app mess_module /path/to/frappe_app/mess_module
bench --site <your-site> install-app mess_module
bench --site <your-site> migrate
```

---

## 🏷️ Key Features

- **RFID Tap-to-Bill Kiosk**: Sub-second meal entitlement billing at `0.00` price, duplicate-serve prevention, and supervisor PIN override (`1234`).
- **Interactive Thermal Token Slip**: Formatted thermal slip receipt with print cue and duplicate reprint watermark.
- **RFID Demo Tap Simulator**: Built-in widget for one-click testing of valid members, already-served scenarios, expired cards, and unregistered tags.
- **Analytical Reports & Delimited CSV Export**: Headcount matrix and customer attendance records with strict pipe (`|`) delimiter compliance.
