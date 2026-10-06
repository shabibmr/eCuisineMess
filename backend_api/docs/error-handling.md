# Error Handling

Code: `core/errors.py`, exception handlers in `main.py`. Client mapping: [front-end data layer](../../ecuisine_mess/docs/data-layer.md).

## 1. Two kinds of failure

| Kind | Used for | HTTP |
|---|---|---|
| **Business outcome** | Counter tap results the UI renders as a banner | **200** `{success:false, error_code, message, …}` — returned (not raised) by `process_rfid_tap` |
| **Error** | Bad input, not found, auth, conflict, unexpected | 4xx/5xx, shapes below |

## 2. Response shapes produced today

| Source | Status | Body |
|---|---|---|
| `MessException` (and subclasses) | `exc.status_code` | `{"success":false,"error_code":"NOT_FOUND\|DUPLICATE_ENTRY\|UNAUTHORIZED\|FORBIDDEN…","message":"…","details":{}}` |
| `HTTPException` (**what routers raise almost everywhere**) | as raised | `{"success":false,"detail":"…","message":"…"}` |
| Request validation | 422 | `{"success":false,"error_code":"VALIDATION_ERROR","message":"Invalid request parameters","detail":[{loc,msg,type},…]}` |
| Unhandled `Exception` | 500 | `{"success":false,"error_code":"INTERNAL_SERVER_ERROR","detail":"An unexpected server error occurred."}` (stack logged) |

**Client must read:** `message` first, else `detail` (string), else join `detail[].msg` for 422; use `error_code` when present.

## 3. Status-code policy (target)

| Situation | Status | `error_code` |
|---|---|---|
| Malformed / failed validation | 422 (Pydantic) or 400 (service rule) | `VALIDATION_ERROR` / specific |
| No/expired token | 401 | `UNAUTHORIZED` |
| Role lacks permission | 403 | `FORBIDDEN` |
| Unknown id | 404 | `NOT_FOUND` |
| Uniqueness / rule conflict (duplicate RFID, name, overlapping meal windows, locked menu, unmap blocked) | **409** | `RFID_IN_USE`, `DUPLICATE_ENTRY`, `MEAL_TIME_OVERLAP`, `MENU_LOCKED`, `UNMAP_BLOCKED`, … + `details` |
| Unexpected | 500 | `INTERNAL_SERVER_ERROR` |

**Today** duplicates return **400** and rule violations return 400 with a plain `detail`. Migrate to 409 + codes behind the contract change in [04 §1.2](../../docs/04-api-contract.md); the Flutter `ErrorInterceptor` already maps 409 → `ConflictFailure(code, context)`, and during the transition maps 400 → `ValidationFailure(message)`.

## 4. How to raise errors (convention)

```python
from core.errors import NotFoundException, DuplicateException, MessException

raise NotFoundException("Member", member_id)                           # 404 NOT_FOUND
raise DuplicateException("RFID tag already registered")                # 400 today → 409 target
raise MessException("MENU_LOCKED", "Menu is locked", 409, {"menu_id": mid})
```
- Prefer `MessException` in **services** and new routers; keep `HTTPException` only for trivial cases. This yields one envelope with `error_code`.
- Never return `str(exc)` of DB errors to clients. Map `pymysql.err.IntegrityError` (1062 duplicate, 1451/1452 FK) in one place (a `handle_db_error` helper) → `DUPLICATE_ENTRY` / `IN_USE`.
- Messages are human-readable English, safe to show in the UI; machine logic uses `error_code`.

## 5. Counter business error codes

`UNREGISTERED`, `SUSPENDED`, `EXPIRED`, `ALREADY_SERVED` (implemented) · `EMPTY_TAG` (implemented, returned as 200) · `NO_MEAL_SERVICE`, `MENU_NOT_SET`, `NO_CUISINE` (target). Unknown codes must be tolerated by clients.

## 6. Logging

- Unhandled errors: `logger.exception(...)` with method + path.
- Transaction rollbacks: `logger.error("Transaction rolled back…")` in `core.database.transaction()`.
- Don't log request bodies (passwords, RFID). Add a request-id and access log line (see [architecture §9](architecture.md)).
