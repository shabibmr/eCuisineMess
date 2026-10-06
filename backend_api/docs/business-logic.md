# Business Logic

Authoritative rules: [01 Business Rules](../../docs/01-business-rules.md). This doc maps them to code (`services/`) and states the **target** algorithm where current code deviates. ✅ = as coded · ⚠ = deviates (fix tracked in [08](../../docs/08-gap-analysis-roadmap.md)).

## 1. Meal window — `counter_service.get_active_meal_window()`

> **Meal windows are per cuisine** (migration 005, `mess_meal_times.cuisine_id`, `UNIQUE(cuisine_id, meal_type)`). `get_active_meal_window(cuisine_id=None)` filters on the cuisine (the tap passes the member's `cuisine_id`; `/health` passes none and looks across all windows). Time normalisation lives in `services/meal_time_service.normalize_time`.

```
now = server clock
windows = active mess_meal_times WHERE cuisine_id = member.cuisine_id ORDER BY start_time   ✅
current = first window with start <= now <= end                 ✅
if none: window = windows[0] with is_current=false              ⚠ (fallback to Breakfast)
return {server_time, window}
```

**Target:** return `{server_time, window: current|null, next: <next window today or tomorrow's first>}`. Callers (`/meal-times/current`, `/health`, tap) must treat `window == null` as "no service".
Normalise `TIME` values (`timedelta` → `HH:MM:SS`) before comparing; the string comparison in code relies on zero-padded `HH:MM:SS`. Boundary: `start <= now < end` is preferable so back-to-back windows don't double-match (windows can't overlap anyway — BR-T2).

## 2. Tap — `counter_service.process_rfid_tap(rfid_tag)`

Order of checks (matches [01 §E](../../docs/01-business-rules.md)). Returns HTTP 200 with `success:false` on business rejection.

| # | Step | Code today | Target |
|---|---|---|---|
| 0 | Empty tag | `EMPTY_TAG` (200) | keep (contract lists as 400; align client to accept either) |
| 1 | Member by `rfid_tag` | `UNREGISTERED` ✅ | |
| 2 | `status == SUSPENDED` | `SUSPENDED` ✅ | also reject `is_active`-like states if added |
| 3 | `validity_start <= today <= validity_end` | `EXPIRED` ✅ (message for not-yet-started says "expired") | distinguish `NOT_YET_VALID` (optional) |
| 4 | Resolve meal (window of the **member's cuisine**) | ✅ cuisine window; ⚠ falls back to that cuisine's first window when outside hours | **`NO_MEAL_SERVICE`** with `next` |
| 5 | Existing non-cancelled bill for (member, today, meal) | `ALREADY_SERVED` + `existing_bill` ✅ | |
| 6 | Daily menu for (today, cuisine, meal) | ⚠ falls back to `mess_cuisine_items` when no menu | **`MENU_NOT_SET`** (decision Q1) |
| 7 | Build response | member summary + `items[]` (name, qty, `unit` from UOM, `price` 0, category) ✅ | add `meal_window`, `today{B,L,D}` strip, `photo_url` |

Notes:
- Member without `cuisine_id` → currently yields an empty `items` list and `success:true`. Target: `NO_CUISINE` rejection.
- The tap **must not write**. It's a preview; only `issue-token` creates bills.
- Response `member` is a *reduced* object on success but the **full DB row** on rejection (includes `rfid_tag`, `photo_url`…). Reduce to the same safe shape in both.

## 3. Issue token — `billing_service.issue_token(payload)`

Today:
1. Load member (404 if missing).
2. If `is_override` **and** `override_pin` given → verify PIN (403 if wrong). ⚠ An override with **no** PIN is accepted.
3. Token number from `COUNT(*)` of today's bills for that meal (+1) → `L-0042`; `bill_number = BILL-YYYYMMDD-L0042`. ⚠ race, counts cancelled, no `UNIQUE`.
4. Items: today's menu for (cuisine, meal) else cuisine mapping (⚠ same fallback as tap).
5. `transaction()`: INSERT bill (total 0.00, `SERVED`, override fields) + INSERT each line (0.00 prices). ✅ atomic.
6. Return `{success, bill{id, bill_number, token_number, date, time, member_name, cuisine, meal_type, items[{name, quantity}], total_amount, is_override}}`.

**Target algorithm** (single transaction; fixes F4, F5, F3):

```
authorize: caller session valid (Depends) ; if is_override → supervisor identity verified server-side
BEGIN
  member := SELECT … WHERE id=? FOR UPDATE            -- serialises concurrent taps of the same card
  re-run tap validations 2–4 and 6 (validity, suspended, meal window == payload.meal_type, menu)
  if existing SERVED bill for (member,today,meal) and not valid override → ROLLBACK, ALREADY_SERVED
  seq := next token for (today, meal) from mess_counters FOR UPDATE   -- BR-B5
  INSERT bill (id, bill_number, token_number, …, issued_by=session user, counter_id)
  INSERT bill items (snapshot item_name, quantity, 0.00)
COMMIT
```
`meal_type` from the client must equal the server-resolved meal (or be derived server-side and the field dropped). Return the same shape as today so the client keeps working; add `counter_id`, `issued_by`, `company`.

## 4. Override rules (BR-O*)

- Allowed only for `ALREADY_SERVED` (and optionally line removal later). Never for `UNREGISTERED`, `SUSPENDED`, `EXPIRED`, `NO_MEAL_SERVICE`.
- Records `is_override=1`, `override_by` (supervisor display name from the **authenticated** supervisor, not a free-text field), `override_reason`.
- An override creates a **second** SERVED bill for the same (member, date, meal) — so the "one SERVED bill" DB guard (see [database-access §4](database-access.md)) must exempt `is_override=1` rows (include `is_override` in the generated key, or exempt in app logic only).
- Current: PIN `1234` via `MESS_SUPERVISOR_PIN`, checked only when supplied.

## 5. Cancel — `billing_service.cancel_bill(bill_id, reason, cancelled_by)`

✅ 404 if missing; already cancelled → `{success:false, message}`; sets `CANCELLED`, `cancel_reason`, `cancelled_by`, `cancelled_at`; never deletes.
⚠ No authorisation; `cancelled_by` is a client string; `reason` min length 1 only.
**Target:** require supervisor/`bill.cancel`; derive actor from session/verified supervisor; reject empty/whitespace reason; return 409-style for already cancelled.

## 6. Masters — delete protection & uniqueness (implemented in routers)

| Entity | Delete when referenced | Unique checks | Notes |
|---|---|---|---|
| Item | in cuisine mapping / daily menu / bill items → **deactivate** (`action:"deactivated"`) | none on name | create requires `category_id` and `uom_id` (validated) |
| Item category | has items → deactivate | name unique (400) | |
| Cuisine | has members or bills → deactivate | name unique (400) | `items[]` replaces the mapping atomically; legacy `item_ids[]` accepted; **missing**: BR-C5 unmap-block when item is in today/future menus |
| Member | has bills → set `SUSPENDED` | `rfid_tag` unique (400, create & update) | `PATCH /members/{id}/status`; `days_left` via `DATEDIFF`; ⚠ `status` is stored, not derived (BR-M5); `cuisine_id` optional (BR-M3) |
| Meal time (per cuisine) | cuisine delete cascades its windows (FK) | `UNIQUE(cuisine_id, meal_type)` | `PUT /meal-times/{id}` per row; ✅ start<end (400) and same-cuisine overlap (409 `MEAL_TIME_OVERLAP`) (BR-T2); ✅ `POST /cuisines` creates the 3 default windows in its transaction (BR-T5) |
| UOM | read-only (`GET /uoms`), seed-managed | | |

## 6.1 Daily menus (`routers/menus.py`)

`POST /menus` upserts one menu for `(menu_date, cuisine_id, meal_type)`: if it exists and `is_locked` → 400; otherwise update header, **replace** items (delete + insert) in one transaction. Accepts `items[{item_id, quantity, notes}]` or legacy `item_ids[]`.

Missing vs [01 §D](../../docs/01-business-rules.md): BR-D2 (item mapped to cuisine), BR-D3 (no duplicate item in a meal), BR-D4 (past dates read-only), BR-D5 (auto-lock when a bill exists — today `is_locked` is **client-set** via the payload and not derived from bills), BR-D6 (whole-date save), copy-from-date endpoints. Implement in a `services/menu_service.py`.

## 7. Reports — `report_service`

All filter `status = 'SERVED'` (cancelled excluded ✅) and default `from/to` to today. Pipe-delimited CSV via `csv.writer(delimiter='|')` ✅ (add UTF-8 BOM for Excel — contract).

| Endpoint | Query | Gaps vs spec |
|---|---|---|
| `headcount` | `COUNT` by cuisine × meal | no `cuisine_id`/`meal_type` filter, no group-by-date, no drill-down |
| `attendance` | raw served rows (member, date, meal, token, time) | no summary (days absent), no calendar view, no member/absentee filters |
| `item-movement` | by item × meal qty | no group-by cuisine/date; check `unit` join to UOM |
| `time-distribution` | hourly counts | spec wants 15/30/60 min slots, per-meal windows, peak, first/last token |
| members register | **missing** | spec report #16 |

`ReportFilter` schema exists (`from_date,to_date,cuisine_id,meal_type`) but isn't used by the routes yet.

## 8. Token & bill number formats

`token_number = {B|L|D}-{seq:04d}` (resets daily per meal) · `bill_number = BILL-{YYYYMMDD}-{B|L|D}{seq:04d}`. Prefix map `BREAKFAST→B, LUNCH→L, DINNER→D`, unknown → `T` (⚠ should be a validation error: reject any `meal_type` not in the three values).

## 9. Input validation gaps (apply everywhere)

- `meal_type` must be one of `BREAKFAST|LUNCH|DINNER` (use an `Enum`/`Literal` in schemas).
- `member.status` ∈ `ACTIVE|EXPIRED|SUSPENDED` on create/update (only the PATCH validates).
- `validity_start <= validity_end`, valid ISO dates.
- Time strings `HH:MM[:SS]`, `start < end`.
- Quantities > 0.
- `is_active`/`is_override` are `int` 0/1 in schemas today — accept `bool` too in new endpoints.
