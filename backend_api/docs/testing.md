# Back-end Testing

## 1. Current state

`tests/test_backend_foundation.py` (298 lines, Starlette `TestClient(main.app)`) has 8 end-to-end tests: `test_health`, `test_auth_flow`, `test_members_crud`, `test_item_categories_crud`, `test_items_and_cuisines`, `test_meal_times`, `test_reports_and_csv_pipe_delimiter`, `test_counter_flow_and_billing`.

Caveats:
- They run against **whatever `MESS_DB_*` points to — by default the dev database `ecuisine_mess`** and create/modify rows there. Run them against a throwaway DB.
- `pytest` is not in `requirements.txt` (add a `requirements-dev.txt`: `pytest`, `httpx`, `freezegun`).
- They exercise the happy paths; the **rules** that matter most (below) are not covered yet.

## 2. Test database

```powershell
$MYSQL = "D:\xampp\mysql\bin\mysql.exe"
& $MYSQL -u root -e "DROP DATABASE IF EXISTS ecuisine_mess_test; CREATE DATABASE ecuisine_mess_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
# schema.sql has `CREATE DATABASE … USE ecuisine_mess` — load with the db name substituted:
(Get-Content ..\database\schema.sql -Raw) -replace 'ecuisine_mess','ecuisine_mess_test' | & $MYSQL -u root
(Get-Content ..\database\seed.sql   -Raw) -replace 'ecuisine_mess','ecuisine_mess_test' | & $MYSQL -u root
$env:MESS_DB_NAME = "ecuisine_mess_test"
python -m pytest tests -q
```
`tests/conftest.py` should refuse to run unless `MESS_DB_NAME` ends with `_test` (safety).

Put this in `scripts/test.ps1` (per repo convention: scripts in files, not long inline commands).

## 3. Layout & fixtures (target)

```
tests/
├── conftest.py                # guard on DB name; `client`, `auth_headers` (login admin), `clean_slate` (truncate txn tables)
├── factories.py               # make_member(), make_cuisine_with_items(), make_menu(), make_bill()
├── unit/                      # pure functions: token format, meal window selection (with frozen time), validators
├── api/                       # one file per router
└── integration/test_counter_concurrency.py
```
Freeze time with `freezegun` (or inject a clock) to test meal windows and validity boundaries deterministically.

## 4. Priority test list (counter first)

| # | Test | Rule |
|---|---|---|
| 1 | Tap valid member inside window with a menu → `success`, items from menu, `price 0` | BR-B1/B2 |
| 2 | Tap unknown tag → `UNREGISTERED`; suspended → `SUSPENDED`; before start / after end → `EXPIRED` | BR-M5 |
| 3 | Tap **outside any window** → `NO_MEAL_SERVICE` (currently fails: falls back) | BR-T4 |
| 4 | Tap with no menu → `MENU_NOT_SET` (decision Q1) | §E |
| 5 | Issue → bill + lines persisted, total 0.00, token `L-0001` | BR-B1/B5 |
| 6 | Second issue same member/meal → `ALREADY_SERVED` at **issue** (not just tap) | BR-B4 |
| 7 | Override without verified supervisor → 403; with → second SERVED bill with `is_override=1` | BR-O* |
| 8 | Cancel with reason → `CANCELLED`; excluded from headcount/attendance; frees the slot for re-issue | BR-X* |
| 9 | **Concurrency:** 10 threads issue for 10 different members same meal → 10 unique tokens `L-0001…L-0010`; 2 threads same member → exactly one SERVED | BR-B4/B5 |
| 10 | Tap does not write (row counts unchanged) | |
| 11 | Delete item/cuisine/member/category when referenced → `action: deactivated/suspended`, row remains | BR-I3/C2/M7 |
| 12 | Duplicate RFID create/update → rejected (400 today / 409 target) | BR-M2 |
| 13 | Meal-time update with overlap → rejected | BR-T2 |
| 14 | Menu save: unmapped item rejected, duplicate item rejected, past date rejected, locked menu rejected | BR-D2–D5 |
| 15 | Unauthenticated call to every business route → 401 (after P1) | BR-U4 |
| 16 | Each report: cancelled excluded; CSV delimiter is `\|`; filters respected | BR-R* |
| 17 | `bills` ordering newest first; `limit/offset` | F6/F7 |
| 18 | UUID format of all returned ids; no `*_code` keys anywhere in responses | AD-1/AD-2 |

Tests 3, 4, 6, 7, 9, 13, 14, 15 are **expected to fail** against today's code; write them first (red), then fix (green) — they pin the P1 work.

## 5. Concurrency test sketch

```python
from concurrent.futures import ThreadPoolExecutor
def issue(member_id): return client.post("/api/v1/counter/issue-token",
                       json={"member_id": member_id, "meal_type": "LUNCH"}, headers=auth).json()
with ThreadPoolExecutor(10) as ex:
    results = list(ex.map(issue, member_ids))
tokens = [r["bill"]["token_number"] for r in results if r.get("success")]
assert len(tokens) == len(set(tokens)) == 10
```
Use a real MariaDB (not SQLite) — locking semantics are the point. `TestClient` shares one process; threads still exercise the pool and row locks.

## 6. Smoke script (`scripts/smoke.ps1`)

health → login → list members → tap seeded card → issue → get bill → cancel → headcount. Exit non-zero on first failure. Used by the Flutter smoke too ([front-end testing §5](../../ecuisine_mess/docs/testing.md)).

## 7. CI gates (when available)

`pytest -q` against a service-container MariaDB 10.11 · `ruff`/`flake8` · `mypy` on `core/` and `services/` (optional) · schema drift check (apply `schema.sql` on empty DB == apply migrations on prior DB; compare `INFORMATION_SCHEMA`).
