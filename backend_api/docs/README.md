# backend_api — Back-end Docs (FastAPI + MariaDB, Windows)

Python/FastAPI service that owns **all business rules** and is the only component that talks to MariaDB. The Flutter client consumes it through [`/api/v1`](../../docs/04-api-contract.md).

Common docs (rules, DB, API contract, standards, Windows setup): [`../../docs/`](../../docs/README.md). Read [01 Business Rules](../../docs/01-business-rules.md), [03 Database](../../docs/03-database-design.md) and [04 API Contract](../../docs/04-api-contract.md) first.

| Doc | Contents |
|---|---|
| [architecture.md](architecture.md) | Actual layout (`core/ routers/ schemas/ services/`), layer rules, request lifecycle, config, structural debt |
| [implementation-plan.md](implementation-plan.md) | Detailed plan to complete the backend Python implementation |
| [tasks-register.md](tasks-register.md) | Task tracking register with status, dependencies, and estimates |
| [database-access.md](database-access.md) | Pool, `transaction()`, SQL conventions, counter concurrency (token sequence, double-serve) |
| [business-logic.md](business-logic.md) | Tap / issue / override / cancel algorithms: code today vs target; master delete rules; menus; reports |
| [auth-and-security.md](auth-and-security.md) | Sessions, what is/isn't enforced, roles, supervisor verification, hardening checklist |
| [api-reference.md](api-reference.md) | Inventory of endpoints the code serves today + diff vs the contract |
| [error-handling.md](error-handling.md) | Exception hierarchy, response shapes, logging |
| [testing.md](testing.md) | Test DB, fixtures, unit + integration + concurrency tests |
| [deployment-windows.md](deployment-windows.md) | Running as a service, config, logs, backup, upgrade |

## Quick facts

| | |
|---|---|
| Framework | FastAPI ≥ 0.110, Pydantic v2, uvicorn |
| DB | MariaDB via PyMySQL (`DictCursor`), **no ORM** |
| Python | 3.13 (3.11+) |
| Port | `8000` (`0.0.0.0`) |
| Docs UI | `/docs` (Swagger) · `/redoc` |
| Run | `pwsh -File backend_api\run.ps1` or `run.bat` |
| Config | env vars `MESS_DB_HOST/PORT/USER/PASSWORD/NAME` (+ new `MESS_*` below) |
| IDs | UUID `CHAR(36)` generated here (`uuid.uuid4()`), no `*_code` columns |
| Default login | `admin` / `admin123` |

## Current state vs. target

The backend has been **modularised** (v1.1.0): `core/` (config, pooled DB, security, errors), `routers/` (12 resources), `schemas/`, `services/` (counter, billing, reports), plus tests. CRUD for items, categories, cuisines, members, meal times, menus and 4 reports exists; UOMs are a read-only lookup (`GET /uoms`, no CRUD for now). What remains is **rule correctness and security**, not structure: business routes are still unauthenticated, the counter falls back instead of rejecting (no-meal-window / no-menu), token numbering and double-serve are race-prone, override/cancel trust the client, and several spec rules (menu mapping/lock/past-date, meal-time overlap, unmap-block) are not enforced. See findings in [08](../../docs/08-gap-analysis-roadmap.md) and the per-area detail in [business-logic.md](business-logic.md).

> The backend is changing quickly. These docs describe the code as of **2026-10-05 (v1.1.0)**; re-verify against the code before relying on a detail.

## Compatibility rules

- Keep `/api/v1/*` stable; additive changes only without a contract update.
- The three `/api/method/mess_module.api.*` aliases stay until the Frappe app is formally retired ([08 Q2](../../docs/08-gap-analysis-roadmap.md)). They must point at the **same** handler functions.
- Pipe-delimited CSV behaviour is a client requirement — do not change.
