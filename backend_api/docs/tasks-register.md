# Mess Module – Backend Python Completion Tasks Register

| | |
|---|---|
| **Implementation Plan** | [implementation-plan.md](implementation-plan.md) |
| **Specifications** | [01 Business Rules](../../docs/01-business-rules.md) · [04 API Contract](../../docs/04-api-contract.md) · [08 Gap Analysis](../../docs/08-gap-analysis-roadmap.md) |
| **Backend Architecture** | [architecture.md](architecture.md) · [business-logic.md](business-logic.md) · [database-access.md](database-access.md) |
| **CSV Register** | [tasks-register.csv](tasks-register.csv) (delimited with `\|`) |
| **Status** | Complete (100%) |

**Status legend:** `To do` · `Doing` · `Review` · `Done` · `Blocked`  
**Ref column:** `BE` = Backend Python Implementation.

---

## Progress Summary

| Milestone | Tasks | Est (h) | Done | Status |
|---|---|---|---|---|
| M1 Core Infrastructure & Security | T-601 – T-606 | 3.5 | 6 / 6 | Done |
| M2 Counter & Billing Rule Correctness | T-607 – T-612 | 4.5 | 6 / 6 | Done |
| M3 Masters & Integrity Rules | T-613 – T-618 | 4.0 | 6 / 6 | Done |
| M4 Daily Menu Service | T-619 – T-624 | 4.5 | 6 / 6 | Done |
| M5 Reports & Dashboard | T-625 – T-630 | 4.0 | 6 / 6 | Done |
| M6 Automated Verification & Tests | T-631 – T-636 | 3.5 | 6 / 6 | Done |
| **Total** | **36** | **24.0** | **36 / 36 (100%)** | **Complete** |

---

## M1 – Core Infrastructure, Error Envelope & Security

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-601 | Add `core/clock.py` system clock abstraction for testable time calculations | BE Core | – | 0.5 | Done | `get_now()` and `get_today()` provide mockable clock |
| T-602 | Update `core/config.py` with dotenv loading and dynamic `CORS_ORIGINS` | BE Core | – | 0.5 | Done | CORS origins and env settings loaded dynamically |
| T-603 | Extend `core/errors.py` with standard conflict codes and DB error handler | BE Core | – | 0.75 | Done | 409 conflict exception hierarchy and 1062 mapping ready |
| T-604 | Upgrade `main.py` with FastAPI `lifespan` and unified error handlers | BE Core | T-603 | 0.5 | Done | Lifespan active, deprecated startup event removed |
| T-605 | Implement RBAC roles (`admin`, `supervisor`, `counter`) in `core/security.py` | BE Sec | – | 0.75 | Done | `require_role()` dependency gates routes |
| T-606 | Implement supervisor credential verification in `routers/auth.py` | BE Sec | T-605 | 0.5 | Done | `POST /auth/verify-supervisor` checks credentials/PIN |

---

## M2 – Counter & Billing Rule Correctness (P1)

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-607 | Update `counter_service.get_active_meal_window` with cuisine filter and no fallback | BE Counter | T-601 | 0.75 | Done | Window query per cuisine; returns None + next when closed |
| T-608 | Implement strict sequential tap checks and `NO_MEAL_SERVICE` in `counter_service.py` | BE Counter | T-607 | 1.0 | Done | Returns 200 `NO_MEAL_SERVICE` with next window |
| T-609 | Enforce `MENU_NOT_SET` on tap when daily menu missing (no fallback to cuisine items) | BE Counter | T-608 | 0.5 | Done | Tap rejects with `MENU_NOT_SET` (Decision Q1) |
| T-610 | Sanitize tap responses with reduced member shape and add `today` strip | BE Counter | T-608 | 0.5 | Done | Tap returns safe member shape + today meal strip |
| T-611 | Refactor `billing_service.issue_token` into atomic lock with race-safe sequence | BE Billing | T-608, T-609 | 1.0 | Done | Token seq allocated inside FOR UPDATE transaction |
| T-612 | Enforce supervisor auth on overrides and cancellations in `billing_service.py` | BE Billing | T-606, T-611 | 0.75 | Done | Override requires supervisor; cancel audits real actor |

---

## M3 – Masters & Integrity Rules (P2)

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-613 | Implement `services/cuisine_service.py` with auto-creation of default meal windows | BE Master | T-604 | 0.75 | Done | `POST /cuisines` generates 3 default meal windows |
| T-614 | Implement unmap protection (BR-C5) in cuisine service and router | BE Master | T-613 | 0.75 | Done | Unmapping item used in today/future menu raises 409 |
| T-615 | Add `POST /cuisines/{id}/copy-mapping` and count fields in `routers/cuisines.py` | BE Master | T-613 | 0.5 | Done | Copy mapping merges without duplicates; counts in list |
| T-616 | Add cuisine filter and same-cuisine overlap validation (BR-T2) in `meal_times.py` | BE Master | – | 0.75 | Done | Overlapping windows within a cuisine rejected with 409 |
| T-617 | Implement derived member status, validity checks, and RFID-lookup in `members.py` | BE Master | T-601 | 0.75 | Done | Expired status derived; `GET /members/by-rfid` active |
| T-618 | Add cuisine filter in `items.py` and optimize N+1 queries in `bills.py` | BE Master | – | 0.5 | Done | `GET /items?cuisine_id=` ready; batch items on bills |

---

## M4 – Daily Menu Domain Service (P3)

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-619 | Create `services/menu_service.py` with mapped item (BR-D2) & duplicate (BR-D3) checks | BE Menu | T-603 | 0.75 | Done | Unmapped and duplicate items rejected on menu save |
| T-620 | Enforce past-date read-only (BR-D4) and auto-lock on bill existence (BR-D5) | BE Menu | T-619 | 0.75 | Done | Modifying past or billed menu raises 409 |
| T-621 | Implement `POST /api/v1/menus/save-day` for whole-day atomic saving (BR-D6) | BE Menu | T-619 | 1.0 | Done | Multi-slot day save executes within single transaction |
| T-622 | Implement `POST /api/v1/menus/copy` date-to-date copy with skipped unmapped items | BE Menu | T-619 | 0.75 | Done | Copies date menu, skips unmapped items and reports |
| T-623 | Implement `POST /api/v1/menus/copy-meal` for meal copying across cuisines | BE Menu | T-619 | 0.5 | Done | Meal slot copied across selected cuisines |
| T-624 | Implement `GET /menus/history` and `GET /menus/status` in `routers/menus.py` | BE Menu | T-619 | 0.75 | Done | Menu history and readiness status endpoints active |

---

## M5 – Reporting Engine & Dashboard (P4)

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-625 | Implement 5th domain report: Members Register (`/reports/members` & CSV) | BE Report | T-604 | 1.0 | Done | Members report with status filters & totals active |
| T-626 | Add filter parameters (`cuisine_id`, `meal_type`, date groups) to existing reports | BE Report | – | 0.75 | Done | Headcount, attendance, item movement filters work |
| T-627 | Add Headcount Drill-Down endpoint: `GET /reports/headcount/tokens` | BE Report | T-626 | 0.5 | Done | Returns token vouchers list for slot drill-down |
| T-628 | Implement multi-interval (15/30/60m) and peak detection in Time Distribution | BE Report | T-626 | 0.75 | Done | Time distribution supports configurable intervals |
| T-629 | Enforce pipe-delimited (`\|`) CSV format with UTF-8 BOM across all report exports | BE Report | T-625 | 0.5 | Done | All CSV exports use `\|` separator and Excel BOM |
| T-630 | Create `routers/dashboard.py` with `GET /api/v1/dashboard/summary` | BE Dash | T-607, T-624 | 0.5 | Done | Home summary with readiness & counts active |

---

## M6 – Automated Verification & Concurrency Verification

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-631 | Add `tests/conftest.py` with test database fixtures and authenticated client | BE Test | M1 | 0.5 | Done | Clean test DB isolation configured |
| T-632 | Create `tests/test_counter_rules.py` testing tap states & sequential codes | BE Test | M2 | 0.75 | Done | NO_MEAL_SERVICE, MENU_NOT_SET, duplicate serve pass |
| T-633 | Create `tests/test_billing_concurrency.py` for multithreaded token sequencing | BE Test | M2 | 0.75 | Done | 10 concurrent threads get unique sequential tokens |
| T-634 | Create `tests/test_menu_rules.py` testing locks, past dates, save-day & copy | BE Test | M4 | 0.5 | Done | Menu auto-lock and day save validated |
| T-635 | Create `tests/test_masters_and_reports.py` testing unmap-block & 5 reports | BE Test | M3, M5 | 0.5 | Done | Unmap block, overlap check, 5 reports verified |
| T-636 | Create test runner script and execute complete test suite | BE Test | T-631–T-635 | 0.5 | Done | 100% tests pass and code verified |
