# 08 — Gap Analysis, Roadmap & Open Questions

Snapshot date: 2026-10-05. Method: read of `database/schema.sql`, `backend_api/main.py`, `ecuisine_mess/lib/**`, `mock-ui/**`, and the spec.

## 1. Where the stack stands

| Layer | Today | Target |
|---|---|---|
| DB | 13 tables (adds `mess_uoms`; items use `uom_id`), UUID, no codes ✔ | + 3–4 indexes; token sequence strategy |
| Backend | **Modularised v1.1.0** (`core/ routers/ schemas/ services/`), pooled DB + `transaction()`, CRUD for items/categories/cuisines/members/meal-times/menus, read-only `GET /uoms` (UOM CRUD out of scope for now), 4 reports, 8 tests | Rule correctness (counter), auth on all routes + roles, menu rules, members report, repositories only if needed |
| Flutter | Provider + `MaterialApp(home:)`, `screens/ models/ services/ providers/ widgets/`; 7 screens | **flutter_bloc + go_router + feature-first**; ~18 screens |
| Mock-ui | 20 screens, complete reference | unchanged |

## 2. Screen gap matrix (mock-ui → Flutter)

| Screen | API ready? | Flutter today | Work |
|---|---|---|---|
| Login | ✅ | ✅ | Port to BLoC/GoRouter |
| Counter | ⚠ (NO_MEAL_SERVICE, MENU_NOT_SET, today-strip, real supervisor auth) | ✅ basic | Port; add banners, F10/F8/Esc, focus mgmt |
| Bill Register | ⚠ | ⚠ list | Filters, view/reprint/cancel, supervisor auth |
| Members | ✅ CRUD + status (derive `status`, RFID-check endpoint missing) | ⚠ list+create | Editor (RFID capture), edit/delete, filters |
| Cuisines | ✅ CRUD + mapping replace (unmap-block, copy-mapping missing) | ⚠ | Dual-pane mapping editor, copy mapping |
| Items | ✅ CRUD + UOM + mapped cuisines | ⬜ | List + editor (UOM + category dropdowns) + search picker |
| Item Categories | ✅ | ✅ | Port |
| Meal Times | ✅ per-cuisine DB + API (filter, overlap 409, defaults on cuisine create); outside-hours fallback still F1 | ⬜ | Settings screen: cuisine selector, 3 rows, overlap validation |
| Daily Menu Editor | ⚠ per-slot upsert; no mapping/past-date/lock/copy rules | ⬜ | Biggest new feature |
| Menu History | ⬜ | ⬜ | Read-only list/view |
| Dashboard | ⬜ | ⬜ | Timeline, readiness grid, KPIs |
| Reports ×5 | ⚠ 4 basic (headcount, attendance, item-movement, time-distribution) + CSV; members register missing; filters/drill-down thin | ⚠ (2 basic) | Report frame + 5 reports + CSV |
| Roles / permissions | ⬜ | ⬜ | Role in session, nav + route guards |
| Themes / skins | — | light only | Dark mode; skins optional |
| Printing | — | preview only | Thermal printing |

## 3. Defects & risks found in the current code

Status column: **Open** · **Fixed** (already resolved by the v1.1.0 backend refactor) · **Partial**.

| # | Finding | Where | Severity | Status | Fix |
|---|---|---|---|---|---|
| F1 | Outside every meal window, `get_active_meal_window()` falls back to the **first** window and tap proceeds with that meal — a card can be served outside meal hours | `services/counter_service.py` | **High** (violates spec §13) | Open | Return `NO_MEAL_SERVICE` + next meal |
| F2 | Business endpoints unauthenticated (members, items, cuisines, menus, meal-times, tap, issue, bills, cancel, reports). `get_current_user` is applied only to `/auth/me`, `/auth/change-password`, `/users` | `routers/*` | **High** | Open | Router-level `Depends(get_current_user)`; roles (P5) |
| F3 | Override/cancel: demo PIN `1234` (`MESS_SUPERVISOR_PIN`) checked **only if a PIN is sent** — an override with no PIN is accepted; cancel has no auth; `override_by` / `cancelled_by` are client strings | `billing_service.py`, `routers/auth.py` | **High** | Open | Real supervisor verification; derive actor from session |
| F4 | Token number via `COUNT(*)+1` outside any lock — two counters can mint the same token; counts cancelled bills; no `UNIQUE` on token/bill number | `billing_service.issue_token` | **High** | Open | Sequence allocated inside the transaction (`mess_counters … FOR UPDATE`) + `UNIQUE (bill_date, token_number)` |
| F5 | `issue-token` does not re-validate duplicate-serve / validity / suspended / meal window / menu; it trusts the client's `meal_type` | `billing_service.issue_token` | **High** | Open | Re-run tap validations inside the issue transaction ([business-logic §3](../backend_api/docs/business-logic.md)) |
| F6 | `list_bills` ordered by UUID id | `routers/bills.py` | Medium | **Fixed** (now `bill_date DESC, bill_time DESC`) | — |
| F7 | `list_bills` / `list_cuisines` / `list_menus` are N+1 for child rows | routers | Medium | **Partial** (paging `limit/offset` added to bills; N+1 remains; no date-range filter) | One grouped `IN (…)` query; `from_date/to_date` |
| F8 | New DB connection per query, no transactions | `db.py` | High | **Fixed** (`core/database.py`: `PooledDB`, `transaction()`) — but `issue_token` still does its *reads* outside the transaction | Move validations/reads inside `transaction()` (F4/F5) |
| F9 | Everything in one `main.py` | backend | Medium | **Fixed** structurally (`core/ routers/ schemas/ services/`). Simple masters still keep SQL inline in routers; `MessException` hierarchy barely used | Move rules into services as they appear ([architecture §8](../backend_api/docs/architecture.md)) |
| F10 | Tap and issue fall back to **cuisine-mapped items** when there is no daily menu; spec says "Menu not set" error | `counter_service`, `billing_service` | Decision | Open | See Q1 |
| F11 | `__pycache__/*.pyc` tracked; `mariadb/data/**` noisy; `.gitignore` lacks Python/Flutter/DB-data/`.venv`/`.env`/`.claude/scratch` entries | repo | Medium | Open | Update `.gitignore`; `git rm --cached` |
| F12 | Flutter uses `Provider`, `MaterialApp(home:)`, layer-first `screens/` layout; one big `ApiService` | `ecuisine_mess/lib` | By-design to change | Open | [Migration plan](../ecuisine_mess/docs/migration-plan.md) |
| F13 | Root `README.md` tree/Provider description stale | root | Low | Open | Update after migration |
| F14 | CORS `allow_origins=["*"]` + `allow_credentials=True`; not env-driven | `core/config.py` | Low (desktop client) | Open | Config-driven origins |
| F15 | Frappe app lacks Daily Menu DocTypes, has string `category`/codes, no `uom` → drifted from schema | `frappe_app/` | Low (parked) | Open | Decide Q2 |
| F16 | Mock-ui tasks register shows M6/M7 "To do" though report screens exist | registers | Low | Open | Reconcile |
| F17 | Backend: 8 happy-path tests, **run against the dev DB**, no `pytest` in requirements, none for the counter rules/concurrency. Flutter: 2 tests | `tests/` | Medium | Partial | [backend testing](../backend_api/docs/testing.md), [06 §8](06-engineering-standards.md) |
| F18 | Member `status` stored, not derived from `validity_end`; `cuisine_id` nullable (spec: required); `status` not validated on create/update | members | Medium | Open | Derive on read; validate |
| F19 | Master/menu rules missing: meal-time overlap (BR-T2), menu item must be mapped / no duplicates / past-date read-only / auto-lock when billed (BR-D2–D5), unmap-block (BR-C5); `POST /menus` accepts client-set `is_locked` | `routers/menus.py`, `meal_times.py`, `cuisines.py` | Medium | Open | `services/menu_service.py`, validators |
| F20 | Three error envelopes (`MessException`, `HTTPException`, 422) and duplicates return **400** instead of 409 | `main.py`, routers | Medium | Open | Standardise ([error-handling](../backend_api/docs/error-handling.md)) |
| F21 | Tap rejection returns the **full member DB row** (incl. RFID, photo path) | `process_rfid_tap` | Low | Open | Return the reduced member shape |
| F22 | `meal_type` / `member.status` / quantities not validated as enums/ranges; unknown meal prefix becomes `T` | schemas | Low | Open | `Literal`/`Enum` in schemas |
| F23 | Concurrent work: another change set (UOM migration `004`) was landing while these docs were written — docs/schema/API may lag; re-verify | repo | Info | — | Re-run the doc audit after each backend phase |
| F24 | **Meal windows are per cuisine** (migration 005). Backend now follows: `get_active_meal_window(cuisine_id)`, tap passes the member's cuisine, `GET /meal-times[?cuisine_id]`, `/meal-times/current?cuisine_id`, same-cuisine overlap + `start<end` on PUT, defaults created with `POST /cuisines`. Still open: outside-hours fallback (F1), optional `apply-to-all`, `/health` has no cuisine so it reports across all windows | `services/counter_service.py`, `services/meal_time_service.py`, `routers/meal_times.py`, `routers/cuisines.py` | Medium | **Fixed** (tests: `test_meal_times`) | — |

## 4. Roadmap

Ordering principle: **fix the money-path correctness first** (counter), then migrate the client architecture, then add screens by business value.

| Phase | Theme | Backend | Flutter | DB | Exit criteria |
|---|---|---|---|---|---|
| **P0** | Foundations | ✅ Layered refactor + DB pool + `transaction()` **done**; remaining: `.gitignore`, isolated test DB + `pytest` setup | New skeleton: `core/`, DI, theme, router shell, shared widgets, `auth` + `settings` features on BLoC; delete Provider | — | App logs in via BLoC + GoRouter; `flutter analyze`/tests green |
| **P1** | Counter correctness | F1, F2, F3, F4, F5, F7; `NO_MEAL_SERVICE`, `MENU_NOT_SET` (per Q1); `today` strip; verify-supervisor; auth on all routes | `counter` feature complete (banners, focus, F-keys, slip); `bills` feature (filters, view, reprint, cancel) | indexes | Two-counter concurrency test passes; duplicate serve impossible |
| **P2** | Masters | Items CRUD, cuisine mapping + copy, member CRUD/RFID check, meal-times, delete-protection | `items`, `cuisines` (dual-pane), `members`, `item_categories`, `meal_times` | unique (menu_id,item_id) | Each master matches mock behaviour incl. Mark-inactive flow |
| **P3** | Daily menu | `/menus` date API, transactional save, copy, lock, history | `daily_menu` editor + history | — | BR-D1…D8 pass |
| **P4** | Reports + dashboard | 5 reports + CSV + dashboard summary | `reports` feature (report frame ×5), `dashboard` | report indexes | Pipe-CSV verified; cancelled excluded |
| **P5** | Roles & hardening | role column, permission deps, user admin, password change; restrict CORS; DB user | role-aware nav/guards, user admin screen | `mess_users.role` | Counter role cannot reach masters/reports (API **and** UI) |
| **P6** | Polish | — | Dark mode, skins (optional), thermal printing, installer, kiosk mode | — | Pilot at a real counter |

## 5. Open questions (need a decision)

| # | Question | Default assumed in these docs |
|---|---|---|
| **Q1** | When no daily menu exists for cuisine + meal, should tap **fail** with `MENU_NOT_SET` (spec & mock) or **fall back to the cuisine's mapped items** (current backend)? | **Fail with `MENU_NOT_SET`** (spec/mock) |
| **Q2** | Keep maintaining `frappe_app/`? | **Parked** — no new work until the live stack is complete |
| **Q3** | Roles: separate `role` column on `mess_users` (admin/supervisor/counter) acceptable? | Yes |
| **Q4** | Ship Clay/Glass skins or Flat only? | **Flat light+dark** |
| **Q5** | Thermal printer model / connection (USB ESC/POS, Windows spooler, network)? | Windows print spooler via PDF/ESC-POS adapter, decided at P6 |
| **Q6** | Multiple counters: need `counter_id` on bills ("Counter: C1" appears on the slip)? | Add `counter_id` to bills at P1; configured per client install |
| **Q7** | Is the member photo required? (spec: optional, shown at counter) | Optional; file stored on API server |
| **Q8** | Is an item-level `default_qty` on `mess_items` needed (spec §2) or only on cuisine mapping (schema)? | **Schema wins**: `default_qty` lives on `mess_cuisine_items` only |
| **Q9** | Flutter HTTP client: `dio` vs `http`? | `dio` |
| **Q10** | Single site / single timezone assumption OK? | Yes |
