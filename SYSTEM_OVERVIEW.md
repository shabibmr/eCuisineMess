# eCuisine Mess Module — System Overview

**Generated:** 2026-10-05  
**Scope:** Full-stack architecture of `Mess_Module`

---

## 1. What it is

RFID tap-to-bill mess / canteen entitlement system for DIT UAE (eCuisine):

1. Register members with RFID + cuisine + validity  
2. Maintain items, cuisines, and cuisine→item mapping  
3. Plan daily menus per cuisine × meal (Breakfast / Lunch / Dinner)  
4. At the counter: tap RFID → validate → issue token at **0.00** price → print slip  
5. Block duplicate serves; allow supervisor override (PIN `1234`)  
6. Report headcount, attendance, item movement, time-based usage  

Domain rules live in `Mess_Modules.md` and `Mess_Screens_Specification.md`.

---

## 2. Four deliverables (same domain, different roles)

| Layer | Path | Role | Runtime |
|---|---|---|---|
| **Spec / UX prototype** | `mock-ui/` | Client demo, full screen set, design system | Static HTML + Alpine.js (`file://` or any static server) |
| **Production UI** | `ecuisine_mess/` | Kiosk + ops app talking to API | Flutter (web / Windows / mobile) |
| **Standalone API** | `backend_api/` | MariaDB-backed REST + Frappe-compatible RPC paths | FastAPI on `:8000` |
| **ERP path** | `frappe_app/mess_module/` | Same domain as Frappe/ERPNext DocTypes + whitelisted methods | Frappe bench |

Shared persistence model for the API path: MariaDB schema in `database/schema.sql` + `seed.sql` (`ecuisine_mess`).

```
┌─────────────────┐     ┌──────────────────┐
│  mock-ui        │     │  ecuisine_mess   │
│  (local store)  │     │  ApiService      │
└────────┬────────┘     └────────┬─────────┘
         │ offline demo          │ HTTP
         ▼                       ▼
   browser seed/store    ┌───────────────────┐
                         │ backend_api       │──► MariaDB ecuisine_mess
                         │ OR Frappe site    │──► Frappe DocTypes
                         └───────────────────┘
```

**Important:** `mock-ui` does **not** call the Python API. It is a self-contained prototype with seeded in-browser data. `ecuisine_mess` + FastAPI/Frappe are the live stack. The old `flutter_app/` folder was removed after its code was moved into `ecuisine_mess/`.

---

## 3. Domain model (MariaDB)

Core tables in `database/schema.sql`:

All primary keys and foreign keys are **UUID** (`CHAR(36)`). There are **no** `*_code` columns (`item_code`, `member_code`, `cuisine_code`, `category_code` removed). Operational slip fields `bill_number` / `token_number` remain on bills.

| Table | Purpose |
|---|---|
| `mess_meal_times` | B/L/D windows |
| `mess_item_categories` | Item category master (name + sort) |
| `mess_uoms` | Unit of measure master (seed-only; no app CRUD) |
| `mess_items` | Item master (`category_id`, `uom_id` UUID FKs) |
| `mess_cuisines` | Cuisine master (unique name) |
| `mess_cuisine_items` | Default entitlement mapping |
| `mess_members` | Member + unique `rfid_tag` + validity + status |
| `mess_daily_menus` / `mess_daily_menu_items` | Day × cuisine × meal menu |
| `mess_bills` / `mess_bill_items` | Issued tokens (amount default 0.00) |
| `mess_users` / `mess_user_sessions` | App login users and opaque session tokens |

Billing uniqueness is enforced in application logic (member + date + meal), supported by index `idx_member_date_meal`.

---

## 4. Counter flow (canonical business path)

1. Detect active meal window from `mess_meal_times` vs server clock  
2. `POST /api/v1/counter/tap` (also aliased as `/api/method/mess_module.api.tap_rfid`)  
3. Resolve RFID → member; reject `UNREGISTERED` / `SUSPENDED` / expired / outside meal window / already served  
4. Load today’s menu for member’s cuisine + meal; fall back to cuisine mapping if needed  
5. `POST …/issue-token` → create bill + line items + token number (`B-####` / `L-####` / `D-####`)  
6. Optional supervisor override stamps `is_override`, `override_by`, `override_reason`  
7. Cancel via cancel endpoint with reason + actor  

Same logic is mirrored in `frappe_app/.../api.py` for ERP installs.

---

## 5. Component maturity

### mock-ui (richest UX)

- Design system: Flat / Clay / Glass × light/dark, Arabic-capable fonts, skins, hotkeys, demo panel  
- Screens present under `mock-ui/js/screens/`: home, items, cuisines, customers, meal times, menu editor, counter, bills, five report screens, styleguide, token preview, widget gallery  
- Data: in-memory store + local persistence + generators (`js/data/`)  
- Tasks register (`Mess_MockUI_Tasks_Register.md`) marks M0–M5 **Done** (79/99); M6 Reports and M7 QA listed **To do**, but report screen JS files already exist — treat the register as partly stale pending a status reconcile  

### ecuisine_mess (live Flutter client)

Nav from `navigation/app_destinations.dart` (rail in `MainLayout`): Counter | Members | Cuisines | Item Categories | Bills | Reports  

Present: login + session restore, RFID simulator, token slip dialog, supervisor override, Provider-based counter/auth state. App shell: shared `ApiService._send` + `ApiException`, Bearer token, 401 → clear local session (no logout POST), persisted `mess_api_base_url` (default `http://127.0.0.1:8000`), shared server-settings dialog, `MasterPage` + `showAppFormDialog` on Items / Categories / Members / Cuisines. Items use `uom_id` with seed UOMs from `GET /api/v1/uoms` (no UOM CRUD). Business FastAPI routes remain open.

Gaps vs mock-ui / spec: no dedicated Items list, Daily Menu editor, Meal Time settings, Home/dashboard, skins/themes, role matrix, or full report drill-downs as in the HTML prototype.

### backend_api (operational)

Endpoints include health, current meal window, tap, issue-token, cancel bill, members CRUD-ish, cuisines, items, bills list, today’s menus, headcount + attendance reports with pipe-delimited CSV export. Dual routes (`/api/v1/...` and `/api/method/mess_module.api.*`) keep Flutter workable against FastAPI or Frappe.

### frappe_app (partial ERP mirror)

DocTypes: Mess Member, Item, Cuisine, Cuisine Item, Meal Time, Bill, Bill Item.  

**Missing vs SQL schema:** Daily Menu / Daily Menu Item DocTypes are not in `doctype/`. Menu planning on Frappe is incomplete relative to MariaDB and the mock-ui Menu Editor.

---

## 6. How the pieces fit in practice

| Goal | Use |
|---|---|
| Stakeholder demo / UX sign-off | Open `mock-ui/index.html` |
| Dev / kiosk with real DB | Start MariaDB → `backend_api` → `cd ecuisine_mess && flutter run` |
| ERPNext deployment | Install `frappe_app/mess_module`, point `ecuisine_mess` `ApiConfig` at the site |
| Spec / backlog | `Mess_Screens_Specification.md`, `Mess_MockUI_Implementation_Plan.md`, tasks register |

---

## 7. Risks and gaps (overview level)

1. **Two backends, one UI contract** — FastAPI and Frappe must stay behaviour-aligned on tap / issue / cancel error codes.  
2. **Frappe schema lag** — no Daily Menu DocTypes; menu APIs may diverge from MariaDB.  
3. **Flutter feature lag** — `ecuisine_mess` covers a thinner set than the mock’s ~20 screens.  
4. **mock-ui vs live data** — prototype never exercises MariaDB integrity or concurrency.  
5. **Supervisor PIN** — documented hardcoded `1234` in demos; production needs proper auth.  
6. **Tasks register drift** — M6/M7 status may not match files already under `mock-ui/js/screens/`.  

---

## 8. Recommended next analyses

- Mock UI ↔ Flutter gap matrix (screen-by-screen)  
- Spec compliance pass against `Mess_Screens_Specification.md`  
- FastAPI ↔ Frappe API parity check  
- Formal Balram/Sherlock audit on Counter + Billing rules  
