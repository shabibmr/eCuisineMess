# Database Access

Module: `core/database.py` (re-exported by `db.py`). Schema: [03](../../docs/03-database-design.md).

## 1. Pool

`DBUtils.PooledDB` over PyMySQL, created lazily by `get_pool()` and eagerly on app startup.

| Setting | Default | Notes |
|---|---|---|
| `mincached` | 2 | idle connections kept ready |
| `maxcached` | 10 | |
| `maxconnections` | 20 | blocks when exhausted (`blocking=True`) |
| `autocommit` | **False** | every helper commits/rolls back explicitly |
| cursor | `DictCursor` | rows are dicts |
| charset | `utf8mb4` | Arabic safe |

Size the pool against uvicorn's threadpool (default 40 workers): with `maxconnections=20`, up to 20 requests run DB work concurrently; the rest wait. That is fine for a mess counter; raise if you see waits in logs.

## 2. Helpers

| Helper | Use | Commits? |
|---|---|---|
| `query(sql, params)` | SELECT many → `list[dict]` | no (read) |
| `query_one(sql, params)` | SELECT one → `dict \| None` | no |
| `execute(sql, params)` | single INSERT/UPDATE/DELETE | **yes**, rolls back on error; returns `lastrowid` (meaningless for UUID PKs — ignore it) |
| `execute_many(sql, rows)` | batch of one statement | yes |
| `with transaction() as cursor:` | **multi-statement atomic unit** | commit on exit, rollback on exception |
| `ping_database()` | health | — |

### Rule of thumb

- **One statement → `execute`.**
- **Two or more writes that must succeed together → `transaction()`** (issue token = bill + lines; cuisine header + mapping; menu header + items; cancel).
- **Read-then-write where the read decides the write → do the read *inside* the transaction** (with `SELECT … FOR UPDATE` when it guards a uniqueness rule). Today `issue_token` reads (`query_one`) outside the transaction — see §4.

```python
with transaction() as cur:
    cur.execute("SELECT … FROM mess_bills WHERE … FOR UPDATE", (…))
    row = cur.fetchone()
    cur.execute("INSERT INTO mess_bills …", (…))
    cur.execute("INSERT INTO mess_bill_items …", (…))
```

> Reads via `query*` use a different pooled connection than the `cursor` inside `transaction()`; they do **not** see uncommitted rows nor take its locks. Inside a transaction use `cursor.execute(...)` for everything.

## 3. SQL conventions

1. Parameterised only — `%s` placeholders, tuple params. Never f-string user input into SQL (the `LIKE` pattern `f"%{search}%"` is passed *as a parameter*, which is correct).
2. Dynamic filters: start `WHERE 1=1`, append fixed fragments, collect a `params` list (see `routers/items.py`).
3. Never `ORDER BY id` (UUID). Use `created_at`, or `bill_date DESC, bill_time DESC`, or a natural column.
4. Explicit column lists on INSERT; `SELECT *` is tolerated for masters but avoid for joins (column collisions).
5. Always join `mess_uoms` when you need a unit label (`u.uom_name AS unit`); items no longer have a `unit` column.
6. Money/quantity columns are `DECIMAL(10,2)` → returned as `Decimal`; convert with `float()` before JSON (FastAPI's encoder handles `Decimal`, but be explicit in hand-built dicts).
7. `TIME` columns come back as `datetime.timedelta`; `str()` yields `H:MM:SS` (e.g. `6:30:00`, no leading zero) — normalise to `HH:MM:SS` before comparing or returning.
8. Avoid N+1: `list_bills`, `list_cuisines`, `list_menus` fetch child rows per parent. Replace with one `WHERE parent_id IN (…)` query and group in Python once lists grow.

## 4. Concurrency & integrity — the counter

Two counters can tap/issue simultaneously. These are the places the DB must protect correctness:

| Concern | Current | Required |
|---|---|---|
| **No double serve** (BR-B4) | Checked in `process_rfid_tap` only; `issue_token` does **not** re-check | In `issue_token`, inside a transaction: lock and re-check `(member, date, meal, status='SERVED')`; optionally add a DB guard (e.g. generated column `served_key` = `IF(status='SERVED', CONCAT(member_id,bill_date,meal_type), NULL)` with a UNIQUE index) so a race becomes an integrity error → `ALREADY_SERVED` |
| **Token sequence** (BR-B5) | `SELECT count(*)` then insert (race; counts cancelled; two counters can mint the same `L-0042`) | Allocate inside the transaction: `SELECT COALESCE(MAX(seq),0)+1 … FOR UPDATE` on a `mess_counters(date, meal_type, last_seq)` row (preferred), or `MAX(CAST(SUBSTRING(token_number,3) AS UNSIGNED))` with a lock. Add `UNIQUE (bill_date, token_number)` |
| **bill_number uniqueness** | Derived from the same count → same race | Derive from the allocated seq |
| **Menu snapshot** | Items re-queried at issue time (may differ from what the counter previewed if the menu changed in between) | Acceptable; the bill stores the issued snapshot (`mess_bill_items.item_name`) |
| **Cuisine/menu replace** | `DELETE` + re-`INSERT` inside `transaction()` ✔ | keep |

## 5. Migrations & schema ownership

- `database/schema.sql` = fresh install; `database/migrations/NNN_*.sql` = upgrades; `seed.sql` = demo data (users, UOMs, categories, items, cuisines, mapping, members, menus).
- `mess_uoms` is a **seed-only** master: no write API. To add a unit, add a row in `seed.sql` + a migration.
- The API never alters schema at runtime.

## 6. Backup/restore & test DB

See [03 §8](../../docs/03-database-design.md) and [testing.md](testing.md).
