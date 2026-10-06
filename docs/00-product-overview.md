# 00 — Product Overview

## 1. Purpose

A mess (canteen) at DIT UAE feeds registered members on a prepaid / entitlement basis. Nobody pays at the counter; the system must:

- know **who** is entitled (member + cuisine + validity),
- know **what** they get (the day's menu for their cuisine and meal),
- **prevent double-serving** in the same meal,
- **print a token** the kitchen hands over food against,
- give management **headcount, attendance and item-movement reports**.

## 2. Users and roles

| Role | Who | Can do |
|---|---|---|
| **Counter** | Counter staff | Use the billing counter; view menus and bills |
| **Supervisor** | Floor supervisor | Counter + override "already served" / remove line + cancel bill + reports |
| **Admin** | Mess manager | Everything incl. masters (items, cuisines, members), menus, meal times, users |

Permission matrix (from `mock-ui/js/core/roles.js`):

| Permission | admin | supervisor | counter |
|---|:-:|:-:|:-:|
| masters.view / masters.edit | ✔ / ✔ | ✔ / ✘ | ✘ / ✘ |
| menu.view / menu.edit | ✔ / ✔ | ✔ / ✘ | ✔ / ✘ |
| counter.use | ✔ | ✔ | ✔ |
| bill.view | ✔ | ✔ | ✔ |
| bill.cancel / bill.override | ✔ / ✔ | ✔ / ✔ | ✘ / ✘ |
| reports.view | ✔ | ✔ | ✘ |

> **Status:** the live stack currently has login only — **no roles** (see [08](08-gap-analysis-roadmap.md)). The matrix above is the target.

## 3. Functional modules

Taken from `Mess_Modules.md`:

| Module | Capability |
|---|---|
| **A. Member Registration** | Name, RFID capture, cuisine, validity period |
| **B. Cuisine** | Create items; create cuisines; map items to cuisines |
| **C. Daily Menu** | Per date × cuisine × meal (B/L/D): choose items + qty |
| **D. Billing** | Meal-time validation → capture RFID → fetch member → fetch cuisine → load menu items → print token → save bill @ 0.00 |
| **E. Reports** | Members register; cuisine × meal headcount; item-wise movement; customer-wise attendance; time-based |

Added in the live stack: **Users/Login**, **Item Categories** (master entity), **Server settings** (API URL on the client).

## 4. Scope

**In scope**

- Windows desktop Flutter client (kiosk + back-office).
- FastAPI backend, MariaDB database.
- Thermal-slip rendering (on-screen preview now; physical printer integration is a later task).

**Out of scope (for now)**

- Payments / non-zero pricing (schema carries `unit_price` / `total_price` columns for future use; value is always `0.00`).
- Mobile/web targets (Flutter project has the platform folders but Windows is the only supported target).
- Frappe/ERPNext app (`frappe_app/`) — kept in repo, **not** maintained in lock-step; see [08](08-gap-analysis-roadmap.md).
- `mock-ui/` is a reference prototype only; it never talks to the API.

## 5. Platform constraints

| Layer | Runs on |
|---|---|
| Flutter client | **Windows 10/11 desktop** (`flutter run -d windows`) |
| Backend API | **Windows** (Python 3.13 + uvicorn, `run.ps1` / `run.bat`) |
| Database | **MariaDB** (local XAMPP / bundled `mariadb/` folder, port 3306) |

## 6. Glossary

| Term | Meaning |
|---|---|
| **Member / Customer** | A registered diner. DB table `mess_members`; UI label "Members" (mock-ui route calls it `customers`) |
| **Cuisine** | A diet group (South Indian, Arabic…). A member belongs to exactly one cuisine |
| **Cuisine mapping** | The set of items a cuisine is *allowed* to serve (`mess_cuisine_items`), each with `default_qty` |
| **Daily menu** | Items actually served on a date for a cuisine + meal (`mess_daily_menus` + `…_items`) |
| **Meal type** | `BREAKFAST` \| `LUNCH` \| `DINNER` (DB). UI/mock shorthand: `B` / `L` / `D` |
| **Meal window** | Start/end time of a meal **for one cuisine** (`mess_meal_times`, unique per cuisine × meal type); a cuisine's windows must not overlap. Defaults: Breakfast 07:00–10:00, Lunch 12:00–15:00, Dinner 19:00–22:00 |
| **Token / KOT** | Printed slip handed to the kitchen. `token_number` = `B-0012`, `L-0042`, `D-0015`; resets daily |
| **Bill** | The record of one served token (`mess_bills`), always 0.00 |
| **Tap** | Presenting the RFID card; backend validates and returns the entitlement preview |
| **Issue token** | Commit step that creates the bill + items and returns the token number |
| **Override** | Supervisor-authorised bypass of "already served"; recorded on the bill |
| **Cancel** | Supervisor voids a bill with reason; cancelled bills are excluded from all reports |
| **Rail** | The Flutter left navigation (`NavigationRail`) |
