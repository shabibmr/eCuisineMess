# Mess Module – Live Stack Tasks Register (Users + Item Category)

| | |
|---|---|
| Plan | [implementation_plan.md](implementation_plan.md) |
| Overview | [SYSTEM_OVERVIEW.md](SYSTEM_OVERVIEW.md) |
| Created | 05-10-2026 |
| Scope | MariaDB + FastAPI + Flutter only (no mock-ui, no Frappe) |
| Order | Phase 1 Users (login) → Phase 2 Item Category |

**Status legend:** `To do` · `Doing` · `Review` · `Done` · `Blocked`  
**Ref column:** `P1` / `P2` = plan phase; sub-bullets match plan sections.  
**Estimates** are focused hours for one developer.

---

## Progress summary

| Milestone | Tasks | Est (h) | Done | Status |
|---|---|---|---|---|
| M1 Users — Database | T-101 – T-104 | 3.0 | 4 / 4 | Done |
| M2 Users — Backend API | T-105 – T-109 | 5.5 | 5 / 5 | Done |
| M3 Users — Flutter login | T-110 – T-116 | 7.0 | 7 / 7 | Done |
| M4 Users — Verify & docs | T-117 – T-119 | 2.0 | 3 / 3 | Done |
| M5 Item Category — Database | T-201 – T-204 | 3.5 | 4 / 4 | Done |
| M6 Item Category — Backend API | T-205 – T-208 | 4.0 | 4 / 4 | Done |
| M7 Item Category — Flutter | T-209 – T-214 | 5.5 | 6 / 6 | Done |
| M8 Item Category — Verify & docs | T-215 – T-217 | 2.0 | 3 / 3 | Done |
| **Total** | **36** | **32.5** | **36 / 36** | Done |

**Critical path:** T-101 → T-105 → T-107 → T-110 → T-113 → T-117 → T-201 → T-205 → T-209 → T-212 → T-215  

**Parallel after DB ready:** M2 backend can finish while Flutter models start (T-110–T-111); M6 API while Flutter models for categories (T-209–T-210).

---

## M1 – Users — Database

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-101 | Add `mess_users` and `mess_user_sessions` to `database/schema.sql` | P1 Data | – | 0.75 | Done | Tables, FKs, indexes match plan |
| T-102 | Create `database/migrations/001_mess_users.sql` for existing DBs | P1 Files | T-101 | 0.5 | Done | Script runs clean on DB that already has other mess_* tables |
| T-103 | Seed admin user in `database/seed.sql` (`admin` / `admin123`, bcrypt hash) | P1 Data | T-101 | 1.0 | Done | Hash verifies with passlib; login will accept credentials |
| T-104 | Document migrate vs full re-import steps in a short comment at top of migration | P1 | T-102 | 0.25 | Done | Operator can apply without guessing |

---

## M2 – Users — Backend API

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-105 | Add `passlib[bcrypt]` and `bcrypt` to `backend_api/requirements.txt`; pip install | P1 Files | – | 0.25 | Done | Import passlib succeeds in venv |
| T-106 | Implement password hash/verify helpers and session token create/delete | P1 API | T-105, T-101 | 1.5 | Done | Unit-style manual call hashes and round-trips |
| T-107 | `POST /api/v1/auth/login` → user + token; 401 on bad creds / inactive | P1 API | T-106, T-103 | 1.5 | Done | Swagger or curl: good login 200, bad 401 |
| T-108 | `POST /api/v1/auth/logout` and `GET /api/v1/auth/me` with Bearer token | P1 API | T-107 | 1.0 | Done | me returns user; logout then me → 401 |
| T-109 | `POST /api/v1/users` (create) requiring auth; seed remains first user | P1 API | T-108 | 1.25 | Done | Authenticated create works; duplicate username rejected |

---

## M3 – Users — Flutter login

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-110 | Add `shared_preferences` to `pubspec.yaml`; `flutter pub get` | P1 Files | – | 0.25 | Done | Package resolves |
| T-111 | Add `ecuisine_mess/lib/models/user.dart` | P1 Files | – | 0.5 | Done | fromJson covers id, username, display_name |
| T-112 | Extend `ApiService` with `login`, `logout`, `me` (+ optional auth header helper) | P1 Flutter | T-111 | 1.25 | Done | Calls match API paths and parse responses |
| T-113 | Add `AuthProvider` (login/logout/restore from prefs, validate via `/me`) | P1 Flutter | T-112, T-108 | 1.5 | Done | Token persisted; cold start restores or clears |
| T-114 | Add `LoginScreen` (username, password, error, submit) | P1 Flutter | T-113 | 1.5 | Done | UI submits and surfaces API errors |
| T-115 | Gate `main.dart`: LoginScreen vs MainLayout via AuthProvider | P1 Flutter | T-114 | 1.0 | Done | Unauthenticated never sees MainLayout |
| T-116 | MainLayout: show display name + Logout action | P1 Flutter | T-115 | 1.0 | Done | Logout returns to LoginScreen |

---

## M4 – Users — Verify & docs

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-117 | End-to-end verify: login, bad password, session restore, logout | P1 Verify | T-116 | 1.0 | Done | All four cases pass against local API + Flutter |
| T-118 | Run `flutter analyze` on changed Dart; fix introduced issues | P1 Verify | T-116 | 0.5 | Done | No new errors in touched files |
| T-119 | Update `README.md` with default credentials and auth endpoints | P1 Files | T-117 | 0.5 | Done | README documents admin/admin123 and /auth/* |

---

## M5 – Item Category — Database

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-201 | Add `mess_item_categories`; change `mess_items` to `category_id` FK in `schema.sql` | P2 Data | T-119 | 1.0 | Done | Fresh schema has no VARCHAR category on items |
| T-202 | Create `database/migrations/002_mess_item_categories.sql` (create, backfill from distinct strings, drop column) | P2 Files | T-201 | 1.5 | Done | Existing DB migrates without orphan items |
| T-203 | Rewrite `seed.sql`: categories first (5 rows), items use `category_id` | P2 Data | T-201 | 0.75 | Done | Seed imports clean; all items linked |
| T-204 | Confirm seed codes: CAT-MAIN, CAT-SIDE, CAT-BREAD, CAT-BEV, CAT-DESSERT | P2 Data | T-203 | 0.25 | Done | Codes and sort_order match plan table |

---

## M6 – Item Category — Backend API

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-205 | Pydantic models + `GET/POST /api/v1/item-categories` | P2 API | T-201 | 1.25 | Done | List and create work in Swagger |
| T-206 | `PUT /api/v1/item-categories/{id}` | P2 API | T-205 | 0.75 | Done | Update name/code/active/sort |
| T-207 | Update `GET/POST /api/v1/items` to join category and use `category_id` / filter | P2 API | T-205, T-203 | 1.5 | Done | Response has category_id + category_name; filter works |
| T-208 | Remove/stop accepting free-text `category` on item create | P2 API | T-207 | 0.5 | Done | Create requires category_id; old field ignored or rejected |

---

## M7 – Item Category — Flutter

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-209 | Add `item_category.dart` model | P2 Files | – | 0.5 | Done | fromJson for id, code, name, sort, active |
| T-210 | Update `item.dart`: `categoryId`, `categoryName` (compat for display) | P2 Files | T-209 | 0.5 | Done | Parses new API JSON |
| T-211 | ApiService: fetch/create/update categories; items filter by `category_id` | P2 Files | T-210, T-207 | 1.25 | Done | Methods match endpoints |
| T-212 | Add `item_categories_screen.dart` (list + add) | P2 Flutter | T-211 | 2.0 | Done | List loads; add persists and refreshes |
| T-213 | Wire nav entry in `main_layout.dart` (after Cuisines) | P2 Flutter | T-212 | 0.5 | Done | Screen reachable from shell |
| T-214 | Counter kiosk shows `categoryName` from join | P2 Flutter | T-210 | 0.75 | Done | Subtitle/label still readable after API change |

---

## M8 – Item Category — Verify & docs

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-215 | Verify migration + seed + API + Flutter category screen + counter label | P2 Verify | T-213, T-214 | 1.0 | Done | Fresh and migrated paths both OK |
| T-216 | `flutter analyze` on Phase 2 Dart changes | P2 Verify | T-214 | 0.5 | Done | No new errors in touched files |
| T-217 | Update `SYSTEM_OVERVIEW.md` entity list; mark this register Done counts | P2 Docs | T-215 | 0.5 | Done | Overview lists Item Category + User; summary table accurate |

---

## Out of scope (do not schedule here)

- Role / permission matrix  
- Locking counter APIs behind Bearer token  
- mock-ui and Frappe Item Category DocType  
- Password reset / change-password UI  
- Full Flutter Items master CRUD editor  

---

## Export

| Format | Path |
|---|---|
| Markdown (source of truth) | `Mess_LiveStack_Tasks_Register.md` |
| Plan | `implementation_plan.md` |
