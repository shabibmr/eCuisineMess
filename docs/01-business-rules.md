# 01 — Business Rules

Rule IDs (`BR-…`) are stable so tests, tickets and code comments can reference them. **Enforcement** says where the rule *must* hold; the backend is always authoritative, the client only mirrors for UX.

Legend — status: ✅ implemented · ⚠ partial / differs · ⬜ not yet.

## A. Members

| ID | Rule | Enforcement | Status |
|---|---|---|---|
| BR-M1 | `name` required | API + client | ✅ |
| BR-M2 | `rfid_tag` required and **unique** across all members | DB unique key + API (create **and** update re-check; today 400 with message, target 409 `RFID_IN_USE`) | ✅ |
| BR-M3 | `cuisine_id` required and must reference an **active** cuisine | API + client | ⚠ (DB allows NULL) |
| BR-M4 | `validity_start` ≤ `validity_end`; both required; start defaults to today | API + client | ⚠ |
| BR-M5 | Status ∈ `ACTIVE`, `EXPIRED`, `SUSPENDED`. `EXPIRED` is **derived** from `validity_end < today`; do not rely on the stored value alone | API (compute on read) | ⚠ |
| BR-M6 | RFID is shown masked except last 4 characters in lists/reports | Client | ⬜ |
| BR-M7 | A member with bills cannot be deleted — API sets `SUSPENDED` instead and returns `action:"suspended"` | API | ✅ |
| BR-M8 | "Clear RFID" unlinks a lost card (requires re-capture before the member can be served) | API | ⬜ |

## B. Items, categories, cuisines

| ID | Rule | Enforcement | Status |
|---|---|---|---|
| BR-I1 | `item_name` required; **`uom_id` required** (FK to `mess_uoms`: Nos, Plate, Bowl, Cup…; seed-only master); `category_id` required by the API on create | API + client | ✅ |
| BR-I2 | `category_id` optional; category names unique | DB unique + API | ✅ |
| BR-I3 | Item referenced by any cuisine mapping, daily menu or bill **cannot be deleted** — the API deactivates it and returns `action:"deactivated"` (client confirms before delete and shows the message) | API | ✅ |
| BR-I4 | Inactive item stays in mappings (greyed) but is not offered in the Daily Menu editor | Client + API | ⬜ |
| BR-C1 | `cuisine_name` required, unique | DB unique + API | ✅ |
| BR-C2 | Cuisine assigned to any member or billed cannot be deleted — API deactivates (`action:"deactivated"`). (Menu usage is not checked today) | API | ⚠ |
| BR-C3 | Inactive cuisine cannot be picked for new members and is hidden from the Daily Menu editor | API + client | ⬜ |
| BR-C4 | A cuisine with no mapped items may be saved but shows "No items mapped – menu cannot be set for this cuisine" | Client | ⬜ |
| BR-C5 | **Unmapping** an item that appears in **today's or a future** daily menu of that cuisine is **blocked**; error lists the affected dates. Past menus/bills unaffected | API (409 + dates) | ⬜ |
| BR-C6 | `mess_cuisine_items` unique on (`cuisine_id`, `item_id`); "Copy mapping from cuisine" must not duplicate | DB + API | ✅ DB |

## C. Meal times

| ID | Rule | Enforcement | Status |
|---|---|---|---|
| BR-T1 | **Each cuisine has its own** meal windows: exactly three meal types per cuisine — BREAKFAST, LUNCH, DINNER (`UNIQUE(cuisine_id, meal_type)`) | DB | ✅ (migration 005) |
| BR-T2 | Within **one cuisine** the windows must **not overlap**; `start_time < end_time`. Different cuisines may overlap freely | API + client (inline highlight on conflicting rows) | ✅ API (409 `MEAL_TIME_OVERLAP`, 400 on start≥end) · ⬜ client |
| BR-T3 | Defaults for every cuisine: **Breakfast 07:00–10:00, Lunch 12:00–15:00, Dinner 19:00–22:00** | Seed + API (BR-T5) | ✅ seed |
| BR-T4 | Current meal = the **active** window **of the member's cuisine** containing the **server** clock. Client clock is never used for validation | API | ✅ tap resolves the window from the member's cuisine (outside-hours fallback still F1) |
| BR-T5 | Creating a cuisine also creates its three default windows (BR-T3); deleting a cuisine removes them (FK cascade). A cuisine without windows cannot serve any meal | API | ✅ |

## D. Daily menus

| ID | Rule | Enforcement | Status |
|---|---|---|---|
| BR-D1 | One menu per (`menu_date`, `cuisine_id`, `meal_type`) — `POST /menus` upserts the slot | DB unique + API | ✅ |
| BR-D2 | Only items **mapped** to the cuisine may be added | API | ⬜ |
| BR-D3 | The same item cannot appear twice in one meal | API + client | ⬜ |
| BR-D4 | **Today and future** dates editable; **past dates are read-only** (= History) | API + client | ⬜ |
| BR-D5 | Once a non-cancelled bill exists for (date, cuisine, meal), that menu is **locked** (`is_locked = 1`); tokens already printed must stay consistent. Today a locked slot rejects edits, but `is_locked` is **client-set**, not derived from bills | API | ⚠ |
| BR-D6 | One **Save** writes the whole date (all cuisines × meals) in a single transaction (slot upsert is transactional today; day-level `save-day` ⬜) | API | ⚠ |
| BR-D7 | "Copy from date" asks before overwriting; items no longer mapped are skipped and listed | API (returns skipped list) + client | ⬜ |
| BR-D8 | "Add all mapped" fills a meal tab with the cuisine mapping at `default_qty` | Client | ⬜ |

## E. Billing (counter)

Canonical order of checks on **tap** (first failure wins; nothing is added to the invoice):

| # | Check | `error_code` | Message (target) | Status |
|---|---|---|---|---|
| 1 | RFID empty | `EMPTY_TAG` (200) | "RFID tag cannot be empty." | ✅ |
| 2 | Card not registered | `UNREGISTERED` | "Card not registered" | ✅ |
| 3 | Member suspended/inactive | `SUSPENDED` | "Membership inactive" | ✅ |
| 4 | Today outside validity | `EXPIRED` | "Membership expired on dd-mm-yyyy" | ✅ |
| 5 | Server time outside **the member's cuisine's** meal windows | `NO_MEAL_SERVICE` | "No meal service now. Next: Dinner 19:00" | ⚠ backend currently **falls back to the first window (Breakfast)** — must change |
| 6 | Already billed for this meal today (non-cancelled) | `ALREADY_SERVED` | "Already served Lunch at 13:05 (L-0151)" | ✅ |
| 7 | No menu saved for cuisine + meal today | `MENU_NOT_SET` | "Menu not set for South Indian – Lunch" | ⚠ backend currently falls back to cuisine mapping (see Open Question Q1 in [08](08-gap-analysis-roadmap.md)) |

| ID | Rule | Enforcement | Status |
|---|---|---|---|
| BR-B1 | Bill total is always `0.00`; each line `unit_price = 0.00`, `total_price = 0.00` | API | ✅ |
| BR-B2 | Invoice lines come from today's menu (cuisine + meal); qty from menu; counter staff **cannot edit lines** | API + client | ✅ |
| BR-B3 | Tapping a new card before Save **replaces** the current invoice | Client | ✅ |
| BR-B4 | **One non-cancelled bill per (member, date, meal)**. Enforced in application logic inside the issue transaction (index `idx_member_date_meal` supports it). A cancelled bill frees the slot | API | ✅ |
| BR-B5 | `token_number` = meal prefix (`B`/`L`/`D`) + zero-padded running number that **resets each day** per meal. Must be race-safe (two counters) | API | ⚠ `COUNT(*)+1` — **not** race-safe, counts cancelled bills (F4) |
| BR-B6 | `bill_number` unique, never reused | DB unique | ✅ |
| BR-B7 | Bill header stores `bill_date`, `bill_time` from the **server** | API | ✅ |
| BR-B8 | Bill items snapshot `item_name` (history survives item rename) | API | ✅ |
| BR-B9 | Reprint shows a **DUPLICATE** watermark | Client | ✅ |

### Supervisor override

| ID | Rule | Status |
|---|---|---|
| BR-O1 | Override allows (a) issuing despite `ALREADY_SERVED`, (b) removing a line (optional) | ⚠ (a) only |
| BR-O2 | Requires a supervisor credential. **Current**: demo PIN `1234` (`MESS_SUPERVISOR_PIN`), verified by `/auth/verify-supervisor` and by `issue-token` **only when a PIN is sent**. **Target**: authenticate a real user with `bill.override`; no PIN ⇒ reject | ⚠ |
| BR-O3 | Bill records `is_override = 1`, `override_by`, `override_reason` | ✅ |
| BR-O4 | Bill Register shows an override flag | ⚠ |

### Cancel

| ID | Rule | Status |
|---|---|---|
| BR-X1 | Cancel needs supervisor authorisation **and** a reason | ⚠ (PIN) |
| BR-X2 | Sets `status = CANCELLED`, `cancelled_by`, `cancel_reason`, `cancelled_at` — **never deletes** | ✅ |
| BR-X3 | Cancelled bills are struck through in the register and **excluded from every report** and from the duplicate-serve check | ✅ |
| BR-X4 | A cancelled bill cannot be un-cancelled | ⬜ |

## F. Reports

| ID | Rule |
|---|---|
| BR-R1 | Common filters: From/To date (default today), Cuisine, Meal type (All/B/L/D) |
| BR-R2 | Cancelled bills always excluded |
| BR-R3 | Exports are CSV with the **pipe `|` delimiter** (client requirement). Excel/PDF are optional later |
| BR-R4 | Headcount cell = count of tokens; drill-down cell → token list → voucher (reprint) |
| BR-R5 | Attendance "days absent" = days in period with no non-cancelled bill for the member within validity |
| BR-R6 | Time-based report intervals: 15 / 30 / 60 min; highlights the peak slot |

## G. Users and sessions

| ID | Rule | Status |
|---|---|---|
| BR-U1 | Login by `username` + password; passwords bcrypt-hashed, never returned (`change-password` exists) | ✅ |
| BR-U2 | Session = opaque bearer token with `expires_at`; `401` clears the client session locally | ✅ |
| BR-U3 | Seed user `admin / admin123` — **must be changed outside dev** | ✅ |
| BR-U4 | Every business endpoint requires a valid bearer token | ⬜ (currently open) |
| BR-U5 | Roles `admin` / `supervisor` / `counter` gate endpoints and nav items | ⬜ |

## H. Cross-cutting

| ID | Rule |
|---|---|
| BR-X-1 | All identifiers are UUIDs generated server-side (`uuid4`). Clients never invent IDs |
| BR-X-2 | All date/time decisions use the **server** clock and server timezone (single mess site) |
| BR-X-3 | Deletes of referenced masters are blocked → offer *Mark inactive* |
| BR-X-4 | Money columns exist but are always `0.00`; do not compute totals on the client |
