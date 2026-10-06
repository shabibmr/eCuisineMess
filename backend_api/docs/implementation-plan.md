# Backend Python Implementation Plan — eCuisine Mess Module

**Document Version:** 1.2.0  
**Target Stack:** FastAPI (Python 3.13) + MariaDB (PyMySQL / PooledDB) + Windows 10/11  
**Authoritative References:**  
- [`docs/00-product-overview.md`](../../docs/00-product-overview.md)  
- [`docs/01-business-rules.md`](../../docs/01-business-rules.md)  
- [`docs/02-system-architecture.md`](../../docs/02-system-architecture.md)  
- [`docs/03-database-design.md`](../../docs/03-database-design.md)  
- [`docs/04-api-contract.md`](../../docs/04-api-contract.md)  
- [`docs/08-gap-analysis-roadmap.md`](../../docs/08-gap-analysis-roadmap.md)  
- [`backend_api/docs/architecture.md`](architecture.md)  
- [`backend_api/docs/business-logic.md`](business-logic.md)  
- [`backend_api/docs/database-access.md`](database-access.md)  
- [`backend_api/docs/auth-and-security.md`](auth-and-security.md)  
- [`backend_api/docs/error-handling.md`](error-handling.md)  
- [`backend_api/docs/testing.md`](testing.md)  

---

## 1. Executive Summary & Goals

The backend Python service (`backend_api`) provides the business logic, transaction boundaries, and REST API contract for the eCuisine Mess Module. While modularized into `core/`, `routers/`, `schemas/`, and `services/`, several critical business rules, security gates, and data integrity guarantees identified in `docs/08-gap-analysis-roadmap.md` remain open.

This implementation plan completes the backend Python codebase to reach 100% compliance with the system specifications, ensuring:
1. **Financial & Operational Correctness:** Thread-safe, race-free counter token sequencing, strict prevention of duplicate meal serving, server-side meal window resolution per cuisine without fallback, and "Menu Not Set" business enforcement.
2. **Supervisor Authority & Auditing:** Real supervisor verification for overrides and cancellations, recording authenticated actor names rather than unverified client strings.
3. **Master & Menu Rule Integrity:** Auto-locking menus when bills exist, blocking past-date menu tampering, enforcing cuisine-item mapping on daily menus, blocking unmapping of active menu items, and preventing overlapping meal time windows within a cuisine.
4. **Complete Reporting & Analytics:** Implementation of the 5th report (Members Register), full filter support across all reports, drill-down endpoints, and guaranteed pipe-delimited (`|`) CSV exports with UTF-8 BOM for Excel compatibility.
5. **Security & Role-Based Access Control:** Securing all business routes behind session tokens, implementing `admin`, `supervisor`, and `counter` role permissions, and establishing structured error responses with standard 409 conflict codes.

---

## 2. Architecture & File Matrix

```
backend_api/
├── main.py                     # [MODIFY] Lifespan management, global error handlers, route dependencies
├── requirements.txt            # [MODIFY] Ensure test & dev dependencies (pytest, httpx, python-dotenv)
├── core/
│   ├── clock.py                # [NEW] Server clock abstraction for deterministic testability
│   ├── config.py               # [MODIFY] Dynamic CORS origins, dotenv loading, roles configuration
│   ├── database.py             # [MODIFY] Helpers for row locking and batch operations
│   ├── errors.py               # [MODIFY] Standardized exception hierarchy and error codes
│   └── security.py             # [MODIFY] RBAC dependencies, supervisor verification, session helpers
├── schemas/
│   ├── auth.py                 # [MODIFY] Supervisor verify with username/password or PIN, role fields
│   ├── common.py               # [MODIFY] ActionResponse, StandardErrorResponse
│   ├── counter.py              # [MODIFY] TapResponse, IssueTokenRequest, CancelBillRequest
│   ├── cuisines.py             # [MODIFY] CopyMappingRequest
│   ├── items.py                # [MODIFY] Cuisine query filter
│   ├── meal_times.py           # [MODIFY] Cuisine meal time update & validation
│   ├── members.py              # [MODIFY] Member response with derived status, RFID capture response
│   ├── menus.py                # [MODIFY] SaveDayMenusRequest, CopyMenuRequest, CopyMealRequest
│   └── reports.py              # [MODIFY] Comprehensive report filter schemas and Members report schemas
├── services/
│   ├── counter_service.py      # [MODIFY] Per-cuisine meal window, NO_MEAL_SERVICE, MENU_NOT_SET, reduced member shape
│   ├── billing_service.py      # [MODIFY] Race-safe token seq, atomic issue with FOR UPDATE, supervisor verification
│   ├── cuisine_service.py      # [NEW] Default meal window generation, unmap block validation, copy mapping
│   ├── menu_service.py         # [NEW] Menu auto-lock, past-date protection, mapping validation, save-day, copy
│   └── report_service.py       # [MODIFY] 5 reports, drill-down queries, pipe-delimited CSV with UTF-8 BOM
├── routers/
│   ├── auth.py                 # [MODIFY] Role support, supervisor verification, user management
│   ├── bills.py                # [MODIFY] Multi-filter query, batch item fetching, cancellation auth
│   ├── counter.py              # [MODIFY] Authenticated counter operations
│   ├── cuisines.py             # [MODIFY] Delegated to cuisine_service, copy-mapping endpoint
│   ├── dashboard.py            # [NEW] GET /api/v1/dashboard/summary for home screen & readiness
│   ├── health.py               # [MODIFY] Health check with DB status and active meal window
│   ├── item_categories.py      # [MODIFY] Auth dependency, unique validation
│   ├── items.py                # [MODIFY] Cuisine filter, active status checks
│   ├── meal_times.py           # [MODIFY] Cuisine-filtered windows, same-cuisine overlap validation
│   ├── members.py              # [MODIFY] Derived status, RFID check endpoint, photo upload
│   ├── menus.py                # [MODIFY] Delegated to menu_service, save-day, copy, history, status
│   ├── reports.py              # [MODIFY] 5 reports, drill-down, CSV exports
│   └── uoms.py                 # [MODIFY] Auth dependency
└── tests/
    ├── conftest.py             # [NEW] Test database fixtures, auth client, factory utilities
    ├── test_backend_foundation.py # [MODIFY] Maintain compatibility with initial 8 tests
    ├── test_counter_rules.py   # [NEW] RFID tap, meal windows, duplicate serve, menu not set
    ├── test_billing_concurrency.py # [NEW] Multithreaded token sequencing & double-serve prevention
    ├── test_menu_rules.py      # [NEW] Menu locks, past date validation, save-day, copy
    ├── test_masters_rules.py   # [NEW] Meal time overlap, unmap block, member status derivation
    └── test_reports.py         # [NEW] 5 reports, pipe delimiter '|', drill-down tokens
```

---

## 3. Detailed Implementation Phases

### Phase 1: Core Engine, Security, and Error Infrastructure
- **Clock Abstraction (`core/clock.py`):**
  - Implement `get_now()`, `get_today()`, `get_current_time_str()`, with test overrides (`set_fixed_now()`, `reset_clock()`).
- **Configuration & Environment (`core/config.py`):**
  - Integrate `python-dotenv` to load `.env` on startup.
  - Make `CORS_ORIGINS` configurable via environment variable `MESS_CORS_ORIGINS`.
- **Standardized Error Handling (`core/errors.py` & `main.py`):**
  - Standardize conflict errors on HTTP 409: `RFID_IN_USE`, `DUPLICATE_ENTRY`, `UNMAP_BLOCKED`, `MENU_LOCKED`, `MEAL_TIME_OVERLAP`, `PAST_DATE_READ_ONLY`, `ALREADY_SERVED`.
  - Add DB exception wrapper translating MariaDB error 1062 to 409 conflict.
  - Implement FastAPI `lifespan` handler replacing deprecated `@app.on_event("startup")`.
- **Authentication & RBAC (`core/security.py` & `routers/auth.py`):**
  - Add role attribute to user payload (`admin`, `supervisor`, `counter`).
  - Create permission dependencies: `require_role(*roles)`.
  - Secure all business routers with `Depends(get_current_user)`.
  - Implement real supervisor verification `verify_supervisor_credentials` validating credentials of supervisor/admin users.

### Phase 2: Counter & Billing Engine Rule Correctness (P1)
- **Meal Window Resolution (`services/counter_service.py`):**
  - Update `get_active_meal_window(cuisine_id: Optional[str])`:
    - Filter windows by `cuisine_id` (migration 005 alignment).
    - If current time is outside windows: return `window: None`, calculate next upcoming window. Never fall back to Breakfast.
- **RFID Tap Entitlement (`services/counter_service.py`):**
  - Implement strict sequential evaluation (Checks 1–7):
    1. Empty tag → 200 `EMPTY_TAG`.
    2. Unregistered → 200 `UNREGISTERED`.
    3. Suspended → 200 `SUSPENDED`.
    4. Validity date range → 200 `EXPIRED`.
    5. Missing cuisine → 200 `NO_CUISINE`.
    6. Active meal window for cuisine → 200 `NO_MEAL_SERVICE` with `next` window.
    7. Existing SERVED bill today → 200 `ALREADY_SERVED` with `existing_bill` context.
    8. Daily menu check for (today, cuisine, meal) → 200 `MENU_NOT_SET` (Decision Q1: NO fallback to cuisine items).
  - Sanitized reduced member shape returned for both success and rejection payloads (protecting PII).
  - Include `meal_window` and `today` `{BREAKFAST: bool, LUNCH: bool, DINNER: bool}` meal strip in success response.
- **Atomic Token Issuance & Sequence Allocation (`services/billing_service.py`):**
  - Enclose entire workflow within single `with transaction() as cursor:`.
  - Lock member row with `SELECT ... FOR UPDATE` to serialize concurrent requests.
  - Re-verify validity, meal window, and duplicate serve inside transaction.
  - If duplicate exists: require valid supervisor authorization. Reject otherwise.
  - Race-safe token sequence allocation:
    `SELECT COALESCE(MAX(CAST(SUBSTRING(token_number, 3) AS UNSIGNED)), 0) + 1 FROM mess_bills WHERE bill_date = %s AND meal_type = %s FOR UPDATE`.
  - Snapshot item names and quantities at 0.00 prices.
- **Bill Cancellation (`services/billing_service.py`):**
  - Require supervisor permission. Derive `cancelled_by` from authenticated supervisor.
  - Enforce non-empty `cancel_reason`.
  - Prevent re-cancellation of already cancelled bills.

### Phase 3: Masters & Domain Services (P2)
- **Cuisine Management & Unmap Protection (`services/cuisine_service.py` & `routers/cuisines.py`):**
  - Auto-generate the 3 default meal windows on `POST /cuisines` (Breakfast 07:00–10:00, Lunch 12:00–15:00, Dinner 19:00–22:00).
  - On `PUT /cuisines/{id}`: if unmapping items, query `mess_daily_menus` for `menu_date >= CURDATE()`. If unmapped item exists in active/future menus, raise 409 `UNMAP_BLOCKED` with affected dates.
  - Implement `POST /api/v1/cuisines/{id}/copy-mapping`.
  - In `GET /cuisines`: include `mapped_items_count` and `active_members_count`.
- **Meal Time Windows (`routers/meal_times.py`):**
  - Support `cuisine_id` filtering on `GET /meal-times`.
  - On `PUT /meal-times/{id}`: validate `start_time < end_time` and enforce non-overlapping windows within the same cuisine (BR-T2) raising 409 `MEAL_TIME_OVERLAP`.
- **Members Master (`routers/members.py`):**
  - Dynamically derive `status = 'EXPIRED'` on read if `validity_end < CURDATE()` and status is not `SUSPENDED`.
  - Enforce `validity_start <= validity_end` and require active `cuisine_id`.
  - Implement `GET /api/v1/members/by-rfid/{rfid_tag}` for card enrollment duplicate check.
  - Implement photo upload handler `POST /api/v1/members/{id}/photo`.
- **Items & Bills (`routers/items.py` & `routers/bills.py`):**
  - Support `GET /api/v1/items?cuisine_id=` query filter.
  - Expand `GET /api/v1/bills` with filters: `from_date`, `to_date`, `cuisine_id`, `member_id`, `status`.
  - Eliminate N+1 item query on bill list by batch querying `mess_bill_items WHERE bill_id IN (...)`.

### Phase 4: Daily Menu Domain Service (P3)
- **Menu Business Logic (`services/menu_service.py` & `routers/menus.py`):**
  - On `POST /menus`:
    - Enforce read-only past dates: reject edits if `menu_date < CURDATE()` with 409 `PAST_DATE_READ_ONLY`.
    - Auto-lock enforcement: query non-cancelled bills for (menu_date, cuisine_id, meal_type). If bill exists, lock menu and reject modifications with 409 `MENU_LOCKED`.
    - Verify all items are mapped to the cuisine (BR-D2).
    - Enforce no duplicate items within the meal slot (BR-D3).
  - Implement `POST /api/v1/menus/save-day`: Atomic whole-day save for all cuisines and meal slots (BR-D6).
  - Implement `POST /api/v1/menus/copy`: Copy menus between dates, skipping unmapped items and returning skipped report (BR-D7).
  - Implement `POST /api/v1/menus/copy-meal`: Copy meal slot across cuisines.
  - Implement `GET /api/v1/menus/history`: Historical menus view.
  - Implement `GET /api/v1/menus/status`: Menu fill status (Full / Partial / Empty) for dashboard and sidebar.

### Phase 5: Reporting Engine & Dashboard (P4)
- **Reporting Services (`services/report_service.py` & `routers/reports.py`):**
  - Implement missing 5th report: `GET /api/v1/reports/members` and `.../export-csv` (filtered by status, expiring_in_days, cuisine, with totals).
  - Enhance Headcount Report with `cuisine_id`, `meal_type`, and `group_by=date`.
  - Add Headcount Drill-Down: `GET /api/v1/reports/headcount/tokens`.
  - Enhance Item Movement Report with category and UOM details.
  - Enhance Time Distribution Report with 15/30/60 min intervals, peak slot detection, and first/last token times.
  - Enhance Attendance Report with absent day calculations and filters.
  - Enforce strictly pipe-delimited (`|`) CSV formatting with UTF-8 BOM (`\ufeff`) across all CSV export endpoints.
- **Dashboard Service (`routers/dashboard.py`):**
  - Implement `GET /api/v1/dashboard/summary` returning:
    - `server_time`, `current_meal`, `next_meal`
    - `served_today: {BREAKFAST, LUNCH, DINNER, total}`
    - `menu_readiness: [{cuisine_id, cuisine_name, BREAKFAST, LUNCH, DINNER}]`
    - `expiring_members_count` (validity ending within 7 days).

### Phase 6: Automated Verification & Testing
- Construct comprehensive automated test suites covering:
  1. Counter rules & sequential failure codes (empty, unregistered, suspended, expired, no cuisine, no meal service, menu not set, already served).
  2. Multithreaded concurrent token issuing (no duplicate token numbers, strict single serve per member).
  3. Supervisor override authorization and bill cancellation.
  4. Menu auto-lock and past-date protection.
  5. Master integrity (cuisine unmap blocking, meal time overlap rejection).
  6. All 5 domain reports and pipe-delimited CSV structure verification.
  7. Route-level authentication and role gating.

---

## 4. Verification & Acceptance Criteria
- All business endpoints require authentication (`401 Unauthorized` without token).
- Counter tap rejects with `NO_MEAL_SERVICE` when outside meal window; never defaults to Breakfast.
- Counter tap rejects with `MENU_NOT_SET` when daily menu is missing; never falls back to cuisine items.
- Multithreaded concurrency test with 10 simultaneous requests yields 10 consecutive, unique token numbers (`L-0001` to `L-0010`) without collisions or gaps.
- Attempting to issue two tokens for the same member concurrently succeeds for exactly one request and rejects the second with `ALREADY_SERVED`.
- Daily menu cannot be saved on past dates (`409 PAST_DATE_READ_ONLY`) or when bills exist (`409 MENU_LOCKED`).
- Removing an item from cuisine mapping that is scheduled in today's/future menu is blocked with `409 UNMAP_BLOCKED`.
- All 5 CSV exports strictly use pipe delimiter `|` and start with UTF-8 BOM.
- Full test suite passes completely.
