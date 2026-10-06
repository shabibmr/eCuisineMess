# 04 — API Contract

Single source of truth between Flutter and FastAPI. Backend implements it; Flutter datasources consume it. Change it here **first**.

- Base URL: `http://<host>:8000` · Prefix: **`/api/v1`**
- Content type: `application/json` (CSV endpoints: `text/csv`)
- Auth: `Authorization: Bearer <token>` on everything except `health` and `auth/login` *(target — today business routes are open, BR-U4/F2)*
- Implementation inventory (what the code serves right now): [`backend_api/docs/api-reference.md`](../backend_api/docs/api-reference.md). **This contract is the target; the status column shows the gap.** Where code and contract differ on purpose, §14 lists the decision.
- IDs: UUID strings · Dates `YYYY-MM-DD` · Times `HH:MM:SS` · Booleans on the wire are `0/1` integers today (`is_active`); new endpoints should accept/return `true/false` — see [06](06-engineering-standards.md)
- Interactive reference: `http://127.0.0.1:8000/docs`

Status legend: ✅ implemented · ⚠ implemented, needs change · ⬜ planned (needed by a mock-ui screen).

## 1. Conventions

### 1.1 Business outcomes vs. errors

Two kinds of failure — keep them distinct:

| Kind | Used for | Shape |
|---|---|---|
| **Business outcome** (HTTP 200) | Counter tap/issue results the UI must *render* (red banner, override prompt) | `{"success": false, "error_code": "…", "message": "…", …context}` |
| **HTTP error** | Malformed input, not found, conflict, auth | Today three envelopes (see [backend error-handling](../backend_api/docs/error-handling.md)): `{success:false, error_code, message, details}` (`MessException`), `{success:false, detail, message}` (`HTTPException`), 422 `{success:false, error_code:"VALIDATION_ERROR", detail:[…]}`. **Clients read `message`, else `detail`, and use `error_code` when present.** Target: one envelope `{success:false, error_code, message, details}` |

### 1.2 Error codes

| HTTP | Meaning | Body notes |
|---|---|---|
| 400 | Validation / bad input | `detail` string or FastAPI 422 array |
| 401 | Missing/expired/invalid token | Client clears session locally |
| 403 | Authenticated but role lacks permission | ⬜ |
| 404 | Unknown id | |
| 409 | Conflict with a rule (unmap blocked, locked menu, duplicate RFID/name, overlap). **Today duplicates and rule violations return 400** | target `{success:false, error_code:"RFID_IN_USE", message, details:{…}}` ⬜ |
| 422 | Pydantic validation (FastAPI default) | |
| 500 | Unexpected | |

Business `error_code` values (counter): `UNREGISTERED`, `SUSPENDED`, `EXPIRED`, `NO_MEAL_SERVICE` ⬜, `MENU_NOT_SET` ⬜, `ALREADY_SERVED`.
Conflict `error_code` values ⬜: `RFID_IN_USE`, `DUPLICATE_ENTRY`, `UNMAP_BLOCKED`, `MENU_LOCKED`, `MEAL_TIME_OVERLAP`, `PAST_DATE_READ_ONLY`.

**Deleting a referenced master is not an error.** `DELETE` on item / cuisine / item-category / member returns **200** `{success:true, action:"deleted"|"deactivated"|"suspended", message}`; the server deactivates instead of failing. The UI confirms before deleting and shows the returned `message` (this replaces the earlier `*_IN_USE` 409 idea).

### 1.3 Lists

Simple filter params, no envelope for now (plain JSON array). Reports return arrays/objects as specified. When a list can grow large (bills, members) add `limit` (default 100, max 500) and `offset`; return the array and an `X-Total-Count` header ⬜.

### 1.4 Frappe aliases

`/api/method/mess_module.api.{tap_rfid,issue_token,cancel_token}` mirror three counter endpoints for ERPNext parity. **Flutter must not use them.**

---

## 2. System & auth

| Status | Method | Path | Request | Response |
|---|---|---|---|---|
| ✅ | GET | `/health` | — | `{status:"online"\|"degraded", database, server_time, active_meal}` |
| ✅ | POST | `/auth/login` | `{username, password}` | `{success, token, user:{id,username,display_name,is_active}}` · 401 bad creds |
| ✅ | GET | `/auth/me` 🔒 | — | `{success, user}` |
| ✅ | POST | `/auth/logout` | — | `{success:true}` |
| ✅ | POST | `/auth/change-password` 🔒 | `{old_password, new_password}` | `{success}` |
| ✅ | GET | `/users` 🔒 | — | `[{id,username,display_name,is_active,created_at}]` |
| ✅ | POST | `/users` 🔒 | `{username, password, display_name, is_active}` | `{id, message}` |
| ⬜ | PUT | `/users/{id}` · `POST /users/{id}/reset-password` | | Admin only |
| ⚠ | POST | `/auth/verify-supervisor` | **today** `{pin}` → `{success}` / 403. **Target** `{username, password}` → `{success, supervisor:{id, display_name}}` | Replaces demo PIN `1234` |

*(`user` objects gain `role` when roles land — ⬜.)* 🔒 = already requires Bearer in code; **all other business routes are still open** (F2).

## 3. Meal times & UOMs

**Meal windows are per cuisine** (migration 005): every cuisine has its own Breakfast / Lunch / Dinner row (defaults 07:00–10:00, 12:00–15:00, 19:00–22:00). ✅ DB, seed and API are per cuisine; ⚠/⬜ rows are what is still open.

| Status | Method | Path | Notes |
|---|---|---|---|
| ⚠ | GET | `/meal-times/current?cuisine_id=` | ✅ `{server_time, cuisine_id, window}` for that cuisine (no `cuisine_id` → all windows, used by `/health`). **Target** `window:{…}\|null` + `next:{meal_type,start_time}\|null`; today outside service hours it still falls back to that cuisine's first slot (F1) |
| ✅ | GET | `/meal-times?cuisine_id=` | windows incl. `cuisine_id` and `cuisine_name` (`id, cuisine_id, cuisine_name, meal_type, name, start_time, end_time, is_active`), ordered by cuisine then start. Without `cuisine_id` returns every cuisine's windows |
| ✅ | PUT | `/meal-times/{id}` | `{name?, start_time?, end_time?, is_active?}` per row (`cuisine_id`/`meal_type` immutable). `start>=end` → 400 `VALIDATION_ERROR`; overlap with an **active window of the same cuisine** → 409 `MEAL_TIME_OVERLAP` + `details.conflicts_with`. **Per-row PUT** (no bulk endpoint) |
| ⬜ | POST | `/meal-times/apply-to-all` | `{from_cuisine_id, meal_types?[]}` copies one cuisine's windows to every other cuisine (editor convenience). Optional |
| ✅ | POST | `/cuisines` | also creates the cuisine's 3 default windows in the same transaction (BR-T5) |
| ✅ | GET | `/uoms?include_inactive=0` | `[{id, uom_name, sort_order, is_active}]`. Seed-only master, **no writes** |

## 4. Item categories

| Status | Method | Path | Request / Response |
|---|---|---|---|
| ✅ | GET | `/item-categories?include_inactive=0` | `[{id, category_name, sort_order, is_active}]` |
| ✅ | GET | `/item-categories/{id}` | |
| ✅ | POST | `/item-categories` | `{category_name, sort_order, is_active}` → `{id, message}`; duplicate name → 400 (target 409) |
| ✅ | PUT | `/item-categories/{id}` | partial |
| ✅ | DELETE | `/item-categories/{id}` | `{success, action:"deleted"\|"deactivated", message}` |

## 5. Items

Item JSON: `{id, item_name, category_id, category, category_name, uom_id, unit, uom_name, is_active, created_at, updated_at}` — `unit` and `uom_name` are the same UOM label (kept for display compatibility). **There is no writable `unit`; writes use `uom_id`.**

| Status | Method | Path | Request / Response |
|---|---|---|---|
| ✅ | GET | `/items?category_id=&category=&search=&include_inactive=0` | array (active only by default) |
| ✅ | GET | `/items/{id}` | item + `mapped_cuisines:[{id,cuisine_name,default_qty,sort_order}]` |
| ✅ | POST | `/items` | `{item_name, category_id, uom_id, is_active}` — **`category_id` and `uom_id` are required** (spec said category optional; code wins until decided) → `{id, message}` |
| ✅ | PUT | `/items/{id}` | partial `{item_name?, category_id?, uom_id?, is_active?}` |
| ✅ | DELETE | `/items/{id}` | in a cuisine / daily menu / bill → deactivated, else deleted (`action`) |
| ⬜ | GET | `/items?cuisine_id=` | items mapped to a cuisine (Item Search widget in the Daily Menu editor) |

## 6. Cuisines

Cuisine JSON: `{id, cuisine_name, description, is_active, items:[{id, item_name, unit, uom_id, default_qty, sort_order, category_id, category}]}`.

| Status | Method | Path | Request / Response |
|---|---|---|---|
| ✅ | GET | `/cuisines?include_inactive=0` | array, each with `items[]` (mapping). ⬜ add `mapped_items_count`, `active_members_count` for the list screen |
| ✅ | GET | `/cuisines/{id}` | |
| ✅ | POST | `/cuisines` | `{cuisine_name, description, is_active, items:[{item_id,default_qty,sort_order}] \| item_ids:[…]}`; duplicate name → 400 |
| ✅ | PUT | `/cuisines/{id}` | header fields; if `items`/`item_ids` is present the mapping is **replaced atomically** |
| ⚠ | PUT | `/cuisines/{id}` (rule) | must 409 `UNMAP_BLOCKED` with `details.dates[]` when removing an item used in today/future menus (BR-C5) — **not enforced** |
| ✅ | DELETE | `/cuisines/{id}` | has members/bills → deactivated (`action`) |
| ⬜ | POST | `/cuisines/{id}/copy-mapping` | `{from_cuisine_id}` → merged mapping (no duplicates) |

## 7. Members

Member JSON: `{id, name, rfid_tag, phone, email, cuisine_id, cuisine_name, validity_start, validity_end, status, photo_url, days_left, created_at, updated_at}`.

| Status | Method | Path | Request / Response |
|---|---|---|---|
| ✅ | GET | `/members?search=&status=` | `search` over name / RFID / phone; newest first. ⬜ `cuisine_id`, `limit/offset`; ⚠ `status` should be derived (BR-M5) |
| ✅ | GET | `/members/{id}` | |
| ✅ | POST | `/members` | `{name, rfid_tag, phone?, email?, cuisine_id?, validity_start, validity_end, status, photo_url?}` → `{id, message}`; duplicate RFID → 400 `RFID tag '…' is already registered…` (target 409 `RFID_IN_USE`). ⚠ `cuisine_id` should be required (BR-M3) |
| ✅ | PUT | `/members/{id}` | partial; RFID uniqueness re-checked |
| ✅ | PATCH | `/members/{id}/status` | `{status: ACTIVE\|SUSPENDED\|EXPIRED}` |
| ✅ | DELETE | `/members/{id}` | has bills → `SUSPENDED` (`action:"suspended"`), else deleted |
| ⬜ | GET | `/members/by-rfid/{rfid_tag}` | RFID-capture duplicate check: `{exists, member_name?}` |
| ⬜ | POST | `/members/{id}/photo` | multipart; stores file, sets `photo_url` |

## 8. Daily menus

Menu JSON: `{id, menu_date, cuisine_id, cuisine_name, meal_type, is_locked, notes, items:[{id,item_name,unit,uom_id,quantity,notes,category_id,category}]}`.

| Status | Method | Path | Request / Response |
|---|---|---|---|
| ✅ | GET | `/menus/today` | all cuisines × meals for today |
| ✅ | GET | `/menus?menu_date=&cuisine_id=&meal_type=` | filtered list |
| ✅ | POST | `/menus` | **upsert one slot** `(menu_date, cuisine_id, meal_type)`: `{menu_date, cuisine_id, meal_type, items:[{item_id,quantity,notes}] \| item_ids:[…], notes?, is_locked?}` → `{id, message}`; locked slot → 400 |
| ⚠ | POST | `/menus` (rules) | must also enforce: item mapped to cuisine (BR-D2), no duplicate item (BR-D3), past date read-only (BR-D4), **auto-lock when a bill exists** (BR-D5; today `is_locked` is client-supplied) |
| ⬜ | POST | `/menus/save-day` | whole-date save in one transaction: `{menu_date, menus:[{cuisine_id, meal_type, notes?, items:[…]}]}` (BR-D6) — the editor's single **Save** |
| ⬜ | POST | `/menus/copy` | `{from_date, to_date, overwrite}` → `{copied, skipped:[{cuisine, meal, item}]}` |
| ⬜ | POST | `/menus/copy-meal` | `{menu_date, from_cuisine_id, meal_type, to_cuisine_ids[]}` → `{copied, skipped:[…]}` |
| ⬜ | GET | `/menus/history?from=&to=&cuisine_id=` | rows for the history list (`menu_date DESC`) with saved-at; read-only |
| ⬜ | GET | `/menus/status?menu_date=` | per-cuisine fill status (full / partial) for the editor sidebar and the dashboard readiness grid |

> `PUT /menus/{date}` from the first draft of this contract is **replaced** by `POST /menus` (slot) + `POST /menus/save-day` (whole day).

## 9. Counter (billing)

### 9.1 `POST /counter/tap` ✅ ⚠

Request `{ "rfid_tag": "0012345678" }`

Success:
```json
{
  "success": true,
  "member": {"id":"…","name":"Rahul K","cuisine_id":"…","cuisine_name":"South Indian",
             "phone":"…","validity_end":"2026-12-31","days_left":87,"photo_url":null},
  "meal_type": "LUNCH",
  "meal_window": {"start_time":"12:00:00","end_time":"15:00:00"},
  "items": [{"item_id":"…","item_name":"Rice","quantity":1,"unit":"Plate","price":0.0,
             "category_id":"…","category_name":"Main"}],
  "today": {"BREAKFAST": true, "LUNCH": false, "DINNER": false},
  "total_amount": 0.0
}
```
`meal_window` and `today` are ⬜ additions (the counter header and "Today: B✔ L— D—" strip need them).

Failure (HTTP 200):
```json
{"success": false, "error_code": "ALREADY_SERVED", "message": "Already served LUNCH at 13:05:12 (Token: L-0151).",
 "member": {…}, "meal_type": "LUNCH", "existing_bill": {"id","bill_number","token_number","bill_time"}}
```
`error_code` ∈ `EMPTY_TAG` (✅, returned as 200) `| UNREGISTERED | SUSPENDED | EXPIRED | ALREADY_SERVED` (✅) `| NO_MEAL_SERVICE | MENU_NOT_SET | NO_CUISINE` (⬜).
Today the rejection payload includes the **whole member DB row**; target is the same reduced member shape as on success (F21). `items[].unit` is the UOM name.
`NO_MEAL_SERVICE` carries `next: {meal_type, start_time}` ⬜.

### 9.2 `POST /counter/issue-token` ✅ ⚠

Request:
```json
{"member_id":"…","meal_type":"LUNCH","is_override":0,"override_by":null,"override_reason":null,"override_pin":null}
```
Response:
```json
{"success": true, "bill": {"id":"…","bill_number":"…","token_number":"L-0187","date":"2026-10-05","time":"14:23:05",
  "member_name":"Rahul K","cuisine":"South Indian","meal_type":"LUNCH",
  "items":[{"name":"Rice","quantity":1.0}],"total_amount":0.0,"is_override":0}}
```
Today: override is verified only when `override_pin` is sent (`403` if wrong; no PIN ⇒ accepted — F3). Target changes ⬜: re-run the tap validations server-side (don't trust the client), return `409`-style business failure if the member was served between tap and issue (unless valid override), take `override` as `{supervisor_user_id}` after `verify-supervisor`, allocate token race-safely, add `counter_id` / `issued_by` when those columns exist.

### 9.3 `POST /bills/{bill_id}/cancel` ✅ ⚠
Request `{reason, cancelled_by}` → `{success, message}`. Target: `cancelled_by` taken from the authenticated supervisor, not the body; role `bill.cancel` required.

## 10. Bills

| Status | Method | Path | Notes |
|---|---|---|---|
| ⚠ | GET | `/bills?bill_date=&meal_type=&search=&limit=100&offset=0` | newest first (`bill_date DESC, bill_time DESC`); `limit` 1–500; each bill has `items[]` (N+1). ⬜ add `from_date`, `to_date`, `cuisine_id`, `member_id`, `status`, `X-Total-Count` |
| ✅ | GET | `/bills/{id}` | bill + items (voucher view / reprint; reprint is client-rendered with `DUPLICATE` watermark) |

Bill JSON: `id, bill_number, token_number, bill_date, bill_time, member_id, member_name, cuisine_id, cuisine_name, meal_type, total_amount, status, is_override, override_by, override_reason, cancelled_by, cancel_reason, cancelled_at, items:[{id,bill_id,item_id,item_name,quantity,unit_price,total_price}]`.

## 11. Reports

All accept `from_date`, `to_date` (default **today**); ⬜ `cuisine_id?`, `meal_type?`. **Cancelled bills excluded.** Each has `…/export-csv` returning pipe-delimited CSV (`text/csv`, `Content-Disposition: attachment`). **Path names follow the code**:

| Status | Report | Path | Response today → target |
|---|---|---|---|
| ⬜ | Members register | `GET /reports/members?status=&expiring_in_days=&registered_from=&registered_to=` | not implemented; rows = member + `days_left`, `status`; totals by status & cuisine |
| ⚠ | Headcount (cuisine × meal) | `GET /reports/headcount` | `[{cuisine_name, meal_type, headcount}]` → add `cuisine_id`, `group_by=date` (+`date`), filters |
| ⬜ | Headcount drill-down | `GET /reports/headcount/tokens?date=&cuisine_id=&meal_type=` | token list → then `GET /bills/{id}` |
| ⚠ | Item movement | `GET /reports/item-movement` | item × meal quantities → add `item_id`, `group_by=cuisine\|date`, date breakdown for the chart |
| ⚠ | Attendance | `GET /reports/attendance` | served rows (`member_id, name, cuisine_name, bill_date, meal_type, token_number, bill_time`) → add `member_id`, `absentees_only`, `view=summary\|detail` (days in period / absent / calendar grid) |
| ⚠ | Time-based | `GET /reports/time-distribution` | hourly counts → add `interval=15\|30\|60`, `view=slots\|hourly`, per-meal windows, peak slot, first/last token, average |

CSV rule: delimiter **`|`**, header row, `Content-Disposition: attachment; filename=…`; ⬜ UTF-8 BOM (Excel + Arabic).

## 12. Dashboard (Home)

| Status | Method | Path | Response |
|---|---|---|---|
| ⬜ | GET | `/dashboard/summary` | `{server_time, current_meal, next_meal, served_today:{B,L,D,total}, menu_readiness:[{cuisine_id,cuisine_name,BREAKFAST,LUNCH,DINNER}], expiring_members_count}` |

---

## 13. Dart ↔ JSON mapping notes

- JSON keys are `snake_case`; Dart fields `camelCase` via DTO `fromJson`/`toJson`.
- `quantity`, `default_qty`, money → `double` (MariaDB DECIMAL arrives as number or string — parse defensively with `num.parse(v.toString())`).
- `is_active` `0/1` → `bool`.
- `meal_type` → Dart `enum MealType { breakfast, lunch, dinner }` with `fromApi`/`toApi` ("BREAKFAST"…).
- Unknown `error_code` → `CounterFailure.unknown(message)` (never crash).

## 14. Decisions where code and the first-draft contract differ

| Topic | Decision (this doc) | Reason |
|---|---|---|
| Delete of referenced master | **200 + `action`** (`deleted`/`deactivated`/`suspended`) | Implemented; simpler UX than 409 → dialog → second call |
| Report paths | `/reports/item-movement`, `/reports/time-distribution` | Implemented names |
| Meal-time write | per-row `PUT /meal-times/{id}` | Implemented; **three rows per cuisine** (migration 005) |
| Menu write | slot upsert `POST /menus` + `POST /menus/save-day` | Implemented slot endpoint; day-save added for the editor's single Save |
| Item unit | `uom_id` (write) / `unit` + `uom_name` (read); UOMs read-only | Schema migration 004 |
| Item category | required on create | Implemented; revisit if the spec's "optional" is wanted |
| Duplicate / rule conflicts | **409 + `error_code`** (target); 400 tolerated by clients meanwhile | Consistency |
