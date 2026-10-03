# eCuisine Mess Billing & Management Module

A complete full-stack Mess Billing and Canteen Entitlement Management solution featuring an interactive **Flutter Frontend**, **MariaDB Database**, a standalone **Python (FastAPI) Backend**, and a ready-to-deploy **Frappe / ERPNext Custom App**.

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
├── flutter_app/                         # Production-Ready Flutter Application
│   ├── lib/
│   │   ├── config/                      # Theme and API configuration
│   │   ├── models/                      # Member, Cuisine, Item, Bill, RFID models
│   │   ├── services/                    # ApiService (REST / Frappe RPC client)
│   │   ├── providers/                   # State management (CounterProvider)
│   │   ├── screens/                     # Kiosk Counter, Members, Cuisines, Bills, Reports
│   │   └── widgets/                     # RFID Tap Simulator, Thermal Token Slip, Supervisor Override
│   └── pubspec.yaml                     # Dependencies (http, provider, intl)
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

### 2. Start the Python Backend API
```bash
# In backend_api/
pip install -r requirements.txt
python -m uvicorn main:app --app-dir backend_api --host 0.0.0.0 --port 8000 --reload
# Or simply double-click backend_api/run.bat
```
- API Base URL: `http://localhost:8000`
- Interactive Swagger Docs: `http://localhost:8000/docs`

### 3. Run the Flutter Frontend
```bash
cd flutter_app
flutter pub get
flutter run -d chrome    # Or flutter run -d windows
```

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
