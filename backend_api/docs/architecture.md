# Back-end Architecture

> **Snapshot:** reflects the code as of 2026-10-05 (API version `1.1.0`). The backend is under active change — when this doc and the code disagree, the code wins; fix the doc.

## 1. Current layout (actual)

```
backend_api/
├── main.py                 # FastAPI app: CORS, exception handlers, startup (pool), include_router × 12
├── db.py                   # backward-compat proxy → core.database (keep until imports migrated)
├── requirements.txt        # fastapi, uvicorn, pymysql, cryptography, pydantic, bcrypt, DBUtils, python-dotenv
├── run.ps1 · run.bat
├── core/
│   ├── config.py           # Settings (env): DB_*, pool sizes, SESSION_DAYS, SUPERVISOR_PIN_DEFAULT, CORS_ORIGINS
│   ├── database.py         # PooledDB pool; query / query_one / execute / execute_many / transaction() / ping_database
│   ├── security.py         # new_id, bcrypt hash/verify, create/delete_session, get_current_user, get_optional_user, verify_supervisor_pin
│   └── errors.py           # MessException(code,message,status,details) + NotFound/Duplicate/Unauthenticated/Forbidden
├── routers/                # one file per resource; paths hard-coded as /api/v1/...
│   health · auth(+users) · members · item_categories · uoms · items · cuisines
│   meal_times · menus · counter · bills · reports
├── schemas/                # Pydantic request models (+ a few response models)
│   auth · common · counter · cuisines · items · meal_times · members · menus · reports
├── services/               # counter_service (tap, meal window) · meal_time_service (default windows, time normalising) · billing_service (issue/cancel) · report_service (queries + CSV)
└── tests/test_backend_foundation.py   # TestClient tests against the real DB
```

Roughly: **routers** (HTTP + a lot of inline SQL for the simple masters) → **services** (counter, billing, reports) → **core.database**.

## 2. Layer rules (to follow going forward)

| Layer | Does | Must not |
|---|---|---|
| `routers/` | Declare route, auth `Depends`, call a service, shape response | Contain multi-step rules or multi-statement writes |
| `schemas/` | Pydantic request/response contracts — keep identical to [04](../../docs/04-api-contract.md) | Logic |
| `services/` | Business rules (`BR-*`), orchestration, transactions, raise `MessException` | Import FastAPI request objects |
| `core/` | Infra: config, pool, security, errors | Business rules |

Today the simple masters (items, categories, cuisines, members, meal times, menus) keep their SQL **inside the router functions**. That is acceptable for pure CRUD, but **anything with a rule** (menu save, cuisine mapping changes, delete protection, token issuing, overrides) belongs in `services/`. Move a master into `services/<name>_service.py` the first time it needs a second rule. A separate `repositories/` layer is **not required** at this size; add it only if SQL is duplicated across services.

## 3. Request lifecycle

```
HTTP → CORS → router function
     → Depends(get_current_user)        [401]  ← currently applied only to /auth/me, /auth/change-password, /users*
     → Pydantic validation              [422 → {success:false, error_code:"VALIDATION_ERROR", detail:[…]}]
     → service / inline SQL via core.database
     → return dict (FastAPI JSON-encodes; Decimal/date/time converted ad hoc with str()/float())
     ← MessException  → {success:false, error_code, message, details}
     ← HTTPException  → {success:false, detail, message}
     ← anything else  → 500 {success:false, error_code:"INTERNAL_SERVER_ERROR"}
```

## 4. Database access (summary — details in [database-access.md](database-access.md))

- `core.database.get_pool()` → `DBUtils.PooledDB` (min 2 cached / max 10 cached / max 20 connections, blocking), `autocommit=False`, `DictCursor`, utf8mb4. Initialised on startup.
- Helpers `query`, `query_one` (read), `execute`, `execute_many` (single statement + commit), and `with transaction() as cursor:` for multi-statement atomic work.
- `db.py` re-exports these for legacy imports.

## 5. Conventions

- **Sync `def` handlers** (PyMySQL is blocking; FastAPI runs them in a threadpool). Don't introduce `async def` handlers that call the DB.
- **IDs:** `core.security.new_id()` (`uuid4`). Never accept client-supplied IDs on create.
- **Parameterised SQL only** (`%s`). Dynamic `WHERE` is built from fixed fragments + params list (see `list_items`).
- **Soft-delete semantics:** `DELETE` on a referenced master returns **200** `{success:true, action:"deactivated"|"suspended"|"deleted", message}` instead of failing (items, cuisines, item-categories, members). The client must read `action`.
- **Dates/times:** MariaDB `TIME` arrives as `timedelta`/`time`; convert with `str()` before returning (done ad hoc). Prefer one serializer helper.
- **Clock:** `datetime.now()` / `date.today()` are called directly in services; a single `core/clock.py` would make time-dependent rules testable (recommended).
- **Naming:** routers `list_*`, `get_*`, `create_*`, `update_*`, `delete_*`; services use intent names (`process_rfid_tap`, `issue_token`, `cancel_bill`).

## 6. Config (`core/config.py`)

| Env var | Default | Purpose |
|---|---|---|
| `MESS_DB_HOST` / `PORT` / `USER` / `PASSWORD` / `NAME` | `localhost` / `3306` / `root` / *(empty)* / `ecuisine_mess` | DB |
| `MESS_DB_MIN_CACHED` / `MAX_CACHED` / `MAX_CONNECTIONS` | `2` / `10` / `20` | Pool |
| `MESS_SESSION_DAYS` | `7` | Session TTL |
| `MESS_SUPERVISOR_PIN` | `1234` | Demo supervisor PIN (**to be replaced**, see [auth-and-security](auth-and-security.md)) |
| `CORS_ORIGINS` | `["*"]` (hard-coded, **not** env-driven yet) | Restrict in prod |

`python-dotenv` is a dependency but `.env` is not yet loaded — `Settings` reads `os.getenv` directly. Either call `load_dotenv()` at import or drop the dependency. Do not commit `.env`.

## 7. Frappe aliases

Three counter routes are double-decorated: `/api/method/mess_module.api.tap_rfid | issue_token | cancel_token` → the same handlers as `/api/v1/counter/tap | issue-token | bills/{id}/cancel`. Flutter uses **`/api/v1` only**. The Frappe app is parked ([08 Q2](../../docs/08-gap-analysis-roadmap.md)).

## 8. Known structural debt

| # | Item | Fix |
|---|---|---|
| S1 | Rules and SQL inline in routers (menus, cuisines, items, members) | Move to services when rules are added |
| S2 | Three different error shapes (`MessException` envelope, `HTTPException` envelope, 422 envelope) and routers mostly raise `HTTPException`, so `MessException` subclasses are barely used | Standardise on `MessException` (see [error-handling](error-handling.md)) |
| S3 | `schemas/` has response models that routers don't use (`response_model` absent) → OpenAPI shows no response schemas | Add `response_model` as endpoints stabilise |
| S4 | `CORS_ORIGINS`, `.env` not wired to env | `core/config.py` |
| S5 | `datetime.now()` scattered | `core/clock.py` |
| S6 | Tests hit the **dev database** | Separate `MESS_DB_NAME=ecuisine_mess_test` ([testing](testing.md)) |
| S7 | `main.py` uses `@app.on_event("startup")` (deprecated in current FastAPI) | `lifespan` context manager |

## 9. Observability

- Logging via stdlib `logging` (`backend_api.*` loggers); unhandled exceptions are logged with stack trace and returned as a generic 500.
- `GET /api/v1/health` → `{status: online|degraded, database, server_time, active_meal}` (also used by the client's "test connection").
- Recommended additions: request-id + access log line (method, path, status, ms, user id), slow-query warning > 300 ms, RFID redaction (last 4) in logs.
