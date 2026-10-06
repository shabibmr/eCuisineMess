# eCuisine Mess Module — Backend API Reference

**Document Version:** 1.4.0  
**Stack:** FastAPI (Python 3.13) + MariaDB (PyMySQL / PooledDB)  
**Interactive Documentation:** Swagger UI: `http://localhost:8000/docs` · ReDoc: `http://localhost:8000/redoc`  
**Master Contract:** [`docs/04-api-contract.md`](../../docs/04-api-contract.md)

This file describes what the code does **today**. Where the code is known to differ from the master contract's target, the gap is called out as **Pending** (backend change) or **Open** (decision not yet made).

---

## 0. Conventions

### 0.1 Base URL & formats
- Every route is under `/api/v1`, except the three legacy aliases (§0.5) and `/static/...` (uploaded member photos).
- JSON in, JSON out. Dates are `YYYY-MM-DD`, times are `HH:MM:SS` (server local clock).
- `meal_type` values: `BREAKFAST`, `LUNCH`, `DINNER`.
- List endpoints return a **plain JSON array** unless the section says otherwise.
- `create` endpoints return `{"id": "<uuid>", "message": "..."}`. `update` endpoints return `{"success": true, "message": "..."}`.

### 0.2 Authentication
- Login (§1.1) returns a session token. Send it as `Authorization: Bearer <token>`.
- Sessions last `MESS_SESSION_DAYS` days (default **7**).
- **Token required today** only on: `GET /auth/me`, `POST /auth/change-password`, `GET /users`, `POST /users`. A missing, malformed or expired token returns **401**.
- **Token optional** (changes behaviour when sent): `POST /counter/issue-token` (supervisor override, §5.2) and `POST /bills/{id}/cancel` (actor and role check, §5.5). An invalid or expired token on these two is silently treated as "no token".
- **All other routes are open.** Pending (contract gap F2): Bearer auth on every route except `/health` and `/auth/login`.
- No route enforces a role today. Role checks happen only inside override and cancel logic.

### 0.3 Error responses
Errors come back in one of three shapes, depending on where they are raised. Pending (contract §1): one envelope, `{success, error_code, message, details}`, for all of them.

| Source | HTTP status | Body |
|---|---|---|
| Business rule (`MessException`) | 400 / 404 / 409 (as listed per endpoint) | `{"success": false, "error_code": "MENU_LOCKED", "message": "...", "details": {...}}` |
| Plain HTTP error (`HTTPException`) | 400 / 401 / 403 / 404 | `{"success": false, "detail": "...", "message": "..."}` — **no `error_code`** |
| Request validation (missing field, wrong type, `min_length`) | 422 | `{"success": false, "error_code": "VALIDATION_ERROR", "message": "Invalid request parameters", "detail": [...pydantic errors]}` — note `detail`, not `details` |
| Unhandled server error | 500 | `{"success": false, "error_code": "INTERNAL_SERVER_ERROR", "detail": "An unexpected server error occurred."}` |

Common `error_code` values: `NOT_FOUND` (404), `FORBIDDEN` (403), `VALIDATION_ERROR` (400/422), and the 409 codes `RFID_IN_USE`, `UNMAP_BLOCKED`, `MEAL_TIME_OVERLAP`, `PAST_DATE_READ_ONLY`, `MENU_LOCKED`, `UNMAPPED_ITEM`, `DUPLICATE_MENU_ITEM`, `ALREADY_SERVED`, `ALREADY_CANCELLED`.

> **Duplicate names** (category, cuisine, username) currently return **400** plain errors, not 409. Pending (contract §1): 409 `DUPLICATE_ENTRY`.

### 0.4 Counter tap is different
`POST /counter/tap` **always returns HTTP 200**. A refusal is reported in the body as `success: false` + `error_code` (§5.1). Clients must check `success`, not the status code.

### 0.5 Legacy aliases (Frappe-style paths)
| Alias | Same handler as | Notes |
|---|---|---|
| `POST /api/method/mess_module.api.tap_rfid` | `POST /api/v1/counter/tap` | Same body |
| `POST /api/method/mess_module.api.issue_token` | `POST /api/v1/counter/issue-token` | Same body |
| `POST /api/method/mess_module.api.cancel_token?bill_id=<uuid>` | `POST /api/v1/bills/{id}/cancel` | `bill_id` goes in the **query string** (the alias has no path parameter) |

### 0.6 Delete behaviour on masters
`DELETE` on a referenced record does not fail. It returns **200** with an `action` field saying what happened:

```json
{"success": true, "action": "deleted | deactivated | suspended", "message": "..."}
```

Unknown id → 404.

---

## 1. Authentication & User Management

### 1.1 `POST /api/v1/auth/login`
- **Auth:** none.
- **Request Body:**
  ```json
  {"username": "admin", "password": "adminpassword"}
  ```
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "token": "4f9d2b1a8c...",
    "user": {
      "id": "uuid",
      "username": "admin",
      "display_name": "System Administrator",
      "role": "admin",
      "is_active": 1
    }
  }
  ```
- **Errors:** 400 username blank after trimming · **401** unknown user, inactive user or wrong password (`"Invalid username or password"`) · 422 field missing or empty.

### 1.2 `POST /api/v1/auth/logout`
- **Headers:** `Authorization: Bearer <token>` (optional — without it the call is a no-op).
- **Response (200 OK):** `{"success": true, "message": "Logged out successfully"}`. Always 200.

### 1.3 `GET /api/v1/auth/me`
- **Auth:** Bearer required.
- **Response (200 OK):** `{"success": true, "user": {id, username, display_name, role, is_active}}`
- **Errors:** 401.

### 1.4 `POST /api/v1/auth/verify-supervisor`
- **Auth:** none.
- **Description:** Check a supervisor PIN, or a username + password, before an override or cancel. If `pin` is non-empty it is checked and the credentials are ignored.
- **Request Body (PIN):** `{"pin": "1234"}`. The PIN is the server setting `MESS_SUPERVISOR_PIN`.
- **Request Body (credentials):** `{"username": "supervisor_user", "password": "password123"}`
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Supervisor credentials verified",
    "supervisor": {
      "id": "uuid",
      "username": "supervisor_user",
      "display_name": "Duty Supervisor",
      "role": "supervisor",
      "is_active": 1
    }
  }
  ```
  - With a PIN, `message` is `"Supervisor PIN verified"`. `supervisor` is the first active user with role `supervisor` (falling back to `admin`).
  - If no such user exists, it is the placeholder `{"id": "supervisor-pin", "username": "supervisor", "display_name": "Supervisor", "role": "supervisor", "is_active": 1}`.
- **Errors:**

  | Status | When |
  |---|---|
  | 403 | Wrong PIN (`"Invalid supervisor PIN"`) |
  | **401** | Unknown user, inactive user or wrong password |
  | 403 | Valid user whose role is not `supervisor` or `admin` |
  | 400 | Neither a PIN nor a username + password supplied |

### 1.5 `POST /api/v1/auth/change-password`
- **Auth:** Bearer required.
- **Request Body:** `{"old_password": "...", "new_password": "..."}` (`new_password` min 4 chars).
- **Response (200 OK):** `{"success": true, "message": "Password changed successfully"}`
- **Errors:** 400 `"Incorrect current password"` · 401 · 422.

### 1.6 `GET /api/v1/users`
- **Auth:** Bearer required (any role).
- **Response (200 OK):** array ordered by `username`:
  ```json
  [{"id": "uuid", "username": "counter1", "display_name": "Counter 1", "role": "counter", "is_active": 1, "created_at": "2026-10-01T09:00:00"}]
  ```

### 1.7 `POST /api/v1/users`
- **Auth:** Bearer required. **Any** logged-in role can create users today. Pending (D3): **admin-only**; other roles will get 403 `FORBIDDEN`.
- **Request Body:**
  ```json
  {
    "username": "counter2",
    "password": "pass1234",
    "display_name": "Counter Two",
    "role": "counter",
    "is_active": 1
  }
  ```
  - `username`: 2–50 chars. `password`: min 4 chars. `display_name`: 2–150 chars.
  - `role` defaults to `counter`. Intended values are `admin`, `supervisor`, `counter`, but the value is not validated.
- **Response (200 OK):** `{"id": "uuid", "message": "User created successfully"}`
- **Errors:** 400 `"Username already exists"` (Pending: 409 `DUPLICATE_ENTRY`) · 401 · 422.

---

## 2. Health & System Clock

### 2.1 `GET /api/v1/health`
- **Auth:** none.
- **Response (200 OK):**
  ```json
  {
    "status": "online",
    "database": "connected",
    "server_time": "2026-10-05 12:30:00",
    "active_meal": "LUNCH"
  }
  ```
  - `status` is `"degraded"` and `database` is `"disconnected"` when the DB ping fails.
  - `active_meal` checks the windows of **all** cuisines and is `null` outside every window.

---

## 3. Masters Management

### 3.1 Unit of Measure (`/api/v1/uoms`)
Seed-only master (Plate, Bowl, Nos, Cup, Glass, Portion, Packet, Bottle, Kg). No write endpoints.

- `GET /api/v1/uoms?include_inactive=0` → array of `{id, uom_name, sort_order, is_active, created_at}`, ordered by `sort_order`, `uom_name`.

### 3.2 Item Categories (`/api/v1/item-categories`)

| Method & path | Request | Response | Errors |
|---|---|---|---|
| `GET /item-categories?include_inactive=0` | — | array of `{id, category_name, sort_order, is_active, created_at, updated_at}` ordered by `sort_order`, `category_name` | — |
| `GET /item-categories/{id}` | — | one category object | 404 |
| `POST /item-categories` | `{"category_name": "Curries", "sort_order": 0, "is_active": 1}` (`category_name` required, 1–100 chars) | `{id, message}` | **400** `"Category name already exists"` · 422 |
| `PUT /item-categories/{id}` | any subset of `{category_name, sort_order, is_active}` | `{success, message}` | 404 · **400** duplicate name |
| `DELETE /item-categories/{id}` | — | `action: "deactivated"` if any item uses it, else `"deleted"` | 404 |

Pending: duplicate name → 409 `DUPLICATE_ENTRY`.

### 3.3 Items (`/api/v1/items`)

**Item object** (list and detail): `{id, item_name, category_id, uom_id, is_active, created_at, updated_at, category, category_name, unit, uom_name}`
- `category` and `category_name` are both the category name.
- `unit` and `uom_name` are both the UOM name.

| Method & path | Request | Response | Errors |
|---|---|---|---|
| `GET /items?cuisine_id=&category_id=&category=&search=&include_inactive=0` | — | array of items ordered by `item_name` | — |
| `GET /items/{id}` | — | item + `mapped_cuisines: [{id, cuisine_name, default_qty, sort_order}]` | 404 |
| `POST /items` | `{"item_name": "Rice", "category_id": "uuid", "uom_id": "uuid", "is_active": 1}` | `{id, message}` | 400 `"Invalid category_id"` / `"Invalid uom_id"` · 422 |
| `PUT /items/{id}` | any subset of `{item_name, category_id, uom_id, is_active}` | `{success, message}` | 404 · 400 invalid category/uom |
| `DELETE /items/{id}` | — | `action: "deactivated"` if used in a cuisine mapping, daily menu or bill, else `"deleted"` | 404 |

List filters:
- `cuisine_id`: only items mapped to that cuisine.
- `category_id` (exact id) takes precedence over `category` (exact name).
- `search`: `item_name LIKE %search%`.

Item names are not checked for duplicates.

### 3.4 Cuisines (`/api/v1/cuisines`)

**Cuisine object:**
```json
{
  "id": "uuid",
  "cuisine_name": "South Indian",
  "description": "...",
  "is_active": 1,
  "created_at": "...",
  "updated_at": "...",
  "mapped_items_count": 12,
  "active_members_count": 40,
  "items": [
    {"id": "uuid", "item_name": "Idli", "unit": "Plate", "default_qty": 2.0, "sort_order": 0,
     "category_id": "uuid", "category": "Breakfast Items", "uom_id": "uuid"}
  ]
}
```
`active_members_count` counts members with stored status `ACTIVE` whose `validity_end` is today or later.

#### `GET /api/v1/cuisines?include_inactive=0`
Array of cuisine objects ordered by name.

#### `GET /api/v1/cuisines/{id}`
One cuisine object. 404 `NOT_FOUND`.

#### `POST /api/v1/cuisines`
- **Request Body:**
  ```json
  {
    "cuisine_name": "South Indian",
    "description": "optional",
    "is_active": 1,
    "items": [{"item_id": "uuid", "default_qty": 1.0, "sort_order": 0}]
  }
  ```
  - `items` takes precedence over the legacy `item_ids: ["uuid", ...]`.
  - With `item_ids`, each mapping gets `default_qty` 1.0 and `sort_order` = its position in the list.
- Creates 3 default meal windows (BR-T5): Breakfast 07:00–10:00, Lunch 12:00–15:00, Dinner 19:00–22:00.
- **Response:** `{id, message}`.
- **Errors:** **400** `"Cuisine name already exists"` (Pending: 409 `DUPLICATE_ENTRY`) · 422.

#### `PUT /api/v1/cuisines/{id}`
- **Request Body:** any subset of `{cuisine_name, description, is_active, items, item_ids}`.
  - Sending `items` or `item_ids` **replaces** the whole mapping.
  - Omitting both leaves the mapping unchanged.
- **Unmap protection (BR-C5):** removing an item that appears in a daily menu dated today or later returns **409 `UNMAP_BLOCKED`**:
  ```json
  {
    "success": false,
    "error_code": "UNMAP_BLOCKED",
    "message": "Cannot unmap items (Idli) actively used in scheduled menus on 2026-10-06.",
    "details": {
      "affected_items": ["Idli"],
      "affected_dates": ["2026-10-06"],
      "scheduled_usage": [{"item_id": "uuid", "item_name": "Idli", "menu_date": "2026-10-06", "meal_type": "BREAKFAST"}]
    }
  }
  ```
  Open (D2): the contract specifies `details.dates[]`; the code returns the keys above, and the Flutter cuisine editor reads `affected_items` / `affected_dates`.
- **Response:** `{success, message}`.
- **Errors:** 404 · **400** duplicate name · 409 `UNMAP_BLOCKED`.

#### `POST /api/v1/cuisines/{id}/copy-mapping`
- Merges the source cuisine's mappings into `{id}`.
  - Items already mapped to the target are skipped.
  - Copied rows keep the source `default_qty` and are appended after the target's highest `sort_order`.
- **Request Body:** `{"source_cuisine_id": "uuid"}`. Pending (D1): renamed to `{"from_cuisine_id": "uuid"}` to match the contract and `copy-meal`. There will be no alias for the old name.
- **Response:** `{"success": true, "copied_count": 5, "message": "..."}`. Source = target → `copied_count: 0`.
- **Errors:** 404 target or source not found.

#### `DELETE /api/v1/cuisines/{id}`
`action: "deactivated"` if any member or bill references it, else `"deleted"`. 404.

### 3.5 Meal Times (`/api/v1/meal-times`)
Windows are per cuisine. Each cuisine has one window per `meal_type`.

**Meal-time object:** `{id, cuisine_id, meal_type, name, start_time, end_time, is_active, created_at}` (times `HH:MM:SS`).

#### `GET /api/v1/meal-times?cuisine_id=`
- Array of meal-time objects + `cuisine_name`, ordered by cuisine name, then `start_time`.
- Without `cuisine_id`, returns every cuisine's windows.

#### `GET /api/v1/meal-times/current?cuisine_id=`
- **Response (200 OK):**
  ```json
  {
    "server_time": "2026-10-05 12:30:00",
    "cuisine_id": "uuid",
    "window": {"id": "uuid", "cuisine_id": "uuid", "meal_type": "LUNCH", "name": "Lunch",
               "start_time": "12:00:00", "end_time": "15:00:00", "is_active": 1, "created_at": "...", "is_current": true},
    "next":   {"...": "same shape", "meal_type": "DINNER", "is_current": false}
  }
  ```
- A window matches when `start_time <= now <= end_time` (both ends inclusive).
- `window` is `null` outside all windows. There is no fallback to Breakfast.
- `next` is the next window to start today, or wraps to the first window of the day. It is `null` only when the cuisine has no active windows.
- Without `cuisine_id`, the windows of all cuisines are considered.

#### `PUT /api/v1/meal-times/{id}`
- **Request Body:** any subset of `{"name": "Lunch", "start_time": "12:00", "end_time": "15:00", "is_active": 1}`. Times accept `HH:MM` or `HH:MM:SS`.
- **Response:** `{success, message}`.
- **Errors:**
  - 404 `NOT_FOUND`
  - 400 `VALIDATION_ERROR` when `start_time >= end_time`
  - 409 `MEAL_TIME_OVERLAP` when the window overlaps another active window of the **same** cuisine. Body: `details: {"conflicts_with": "BREAKFAST"}`. An inactive window is never rejected for overlap.

### 3.6 Members (`/api/v1/members`)

**Member object:**
```
{id, name, rfid_tag, phone, email, cuisine_id, cuisine_name,
 validity_start, validity_end, status, photo_url, days_left,
 created_at, updated_at}
```
- `status` is derived:
  1. `SUSPENDED` if stored as suspended
  2. else `EXPIRED` if `validity_end` < today
  3. else the stored value
- `days_left` = `validity_end − today` (negative when expired).

#### `GET /api/v1/members?search=&status=`
- Array of member objects, newest first (`created_at DESC`).
- `status` filters on the derived status.
- `search` matches name, RFID or phone (`LIKE`).
- No pagination: every matching member is returned.
- Pending (contract): `cuisine_id`, `limit` (default 100, max 500), `offset` and an `X-Total-Count` header. These parameters are **ignored** today.

#### `GET /api/v1/members/{id}`
Member object. 404 `NOT_FOUND`.

#### `GET /api/v1/members/by-rfid/{rfid_tag}`
Member object for the card, used to check for duplicates during enrolment. 404 `NOT_FOUND` when the card is free.

#### `POST /api/v1/members`
- **Request Body:**
  ```json
  {
    "name": "Rahul Sharma",
    "rfid_tag": "0012345678",
    "phone": "optional",
    "email": "optional",
    "cuisine_id": "uuid (optional)",
    "validity_start": "2026-10-01",
    "validity_end": "2026-12-31",
    "status": "ACTIVE",
    "photo_url": null
  }
  ```
- **Response:** `{id, message}`.
- **Errors:**
  - 409 `RFID_IN_USE` (`details: {rfid_tag}`)
  - 400 `validity_start` after `validity_end`
  - 400 `cuisine_id` unknown or inactive
  - 422

#### `PUT /api/v1/members/{id}`
- **Request Body:** any subset of the POST fields.
- **Response:** `{success, message}`.
- **Errors:** 404 · 409 `RFID_IN_USE` · the same 400s as POST.

#### `PATCH /api/v1/members/{id}/status`
- **Request Body:** `{"status": "SUSPENDED"}`. Accepted values today: `ACTIVE`, `SUSPENDED`, `EXPIRED` (case-insensitive). Pending (D6): only `ACTIVE` / `SUSPENDED`. `EXPIRED` is always derived from `validity_end`.
- **Response:** `{"success": true, "message": "Member status updated to SUSPENDED"}`.
- **Errors:** 404 · 400 invalid value.

#### `POST /api/v1/members/{id}/photo`
- Send **either**:
  - `multipart/form-data` with a `file` field. It is saved to `/static/uploads/members/{id}_{timestamp}{ext}`.
  - a JSON body `{"photo_url": "https://..."}`, which is stored as given.
- **Response:** `{"success": true, "photo_url": "/static/uploads/members/...", "message": "..."}`.
- **Errors:** 404 · 400 neither a file nor `photo_url` supplied.

#### `DELETE /api/v1/members/{id}`
`action: "suspended"` if the member has any bill, else `"deleted"`. 404.

---

## 4. Daily Menu Domain Service

**Menu object:**
```
{id, menu_date, cuisine_id, cuisine_name, meal_type, is_locked, notes,
 created_at, updated_at, items[]}
```
- Each entry in `items[]` is `{id, item_name, unit, quantity, notes, category_id, category, uom_id}`; `id` is the item id.
- `is_locked` is `1` if the stored flag is set **or** a non-cancelled bill exists for the slot (BR-D5).

**Write rules (all 409, shared by §4.6–4.9):**

| `error_code` | When | `details` |
|---|---|---|
| `PAST_DATE_READ_ONLY` | target date < today (BR-D4) | `{menu_date, today}` |
| `MENU_LOCKED` | slot has non-cancelled bills, or its `is_locked` flag is set | `{menu_date, cuisine_id, meal_type}` |
| `UNMAPPED_ITEM` | item not mapped to the cuisine (BR-D2) | `{item_id, cuisine_id}` |
| `DUPLICATE_MENU_ITEM` | same item twice in one slot (BR-D3) | `{item_id, cuisine_id}` |

### 4.1 `GET /api/v1/menus/today`
Array of today's menu objects (all cuisines, all meals).

### 4.2 `GET /api/v1/menus?menu_date=&cuisine_id=&meal_type=`
Array of menu objects, ordered by `menu_date DESC`, `meal_type`. All filters are optional.

### 4.3 `GET /api/v1/menus/{menu_id}`
One menu object. 404 `NOT_FOUND`.

### 4.4 `GET /api/v1/menus/history?from_date=&to_date=&cuisine_id=&limit=50&offset=0`
- `from` and `to` are accepted as aliases for `from_date` and `to_date`.
- **Response (200 OK):**
  ```json
  {
    "total": 42,
    "limit": 50,
    "offset": 0,
    "menus": [
      {"...menu object...": "", "items_count": 6, "item_names_summary": "Rice, Dal, Sambar, Rasam (+2 more)"}
    ]
  }
  ```

### 4.5 `GET /api/v1/menus/status?menu_date=`
- Readiness of each active cuisine for the dashboard and the editor sidebar. `menu_date` defaults to today.
- A slot counts as filled when it has at least one item.
  ```json
  {
    "menu_date": "2026-10-05",
    "readiness": [
      {
        "cuisine_id": "uuid",
        "cuisine_name": "South Indian",
        "status": "FULL",
        "filled_count": 3,
        "total_slots": 3,
        "BREAKFAST": true,
        "LUNCH": true,
        "DINNER": true,
        "slots": {"BREAKFAST": true, "LUNCH": true, "DINNER": true}
      }
    ]
  }
  ```
  `status` is `FULL` (3), `PARTIAL` (1–2) or `EMPTY` (0).

### 4.6 `POST /api/v1/menus` (Slot Save)
- Creates or replaces one `(menu_date, cuisine_id, meal_type)` slot. Its item list is replaced in full.
- **Request Body:**
  ```json
  {
    "menu_date": "2026-10-06",
    "cuisine_id": "uuid",
    "meal_type": "LUNCH",
    "items": [{"item_id": "uuid", "quantity": 1.0, "notes": null}],
    "notes": null,
    "is_locked": 0
  }
  ```
  `items` takes precedence over the shorthand `item_ids: ["uuid", ...]` (quantity 1.0).
- **Response:** `{"id": "<menu uuid>", "message": "Daily menu saved successfully"}`.
- **Errors:** 404 cuisine · the 409 write rules above.

### 4.7 `POST /api/v1/menus/save-day` (Whole-Day Atomic Save)
- **Request Body:**
  ```json
  {
    "menu_date": "2026-10-06",
    "menus": [
      {"cuisine_id": "uuid1", "meal_type": "BREAKFAST", "item_ids": ["uuid-item-1", "uuid-item-2"]},
      {"cuisine_id": "uuid1", "meal_type": "LUNCH", "items": [{"item_id": "uuid-item-3", "quantity": 1.0}], "notes": null, "is_locked": 0}
    ]
  }
  ```
- **All-or-nothing (BR-D6):**
  - Every slot is validated against the same rules as §4.6 before anything is written.
  - The first failure (404 cuisine or any 409) aborts the whole request.
  - Slots not listed are left untouched.
- **Response (200 OK):** `{"success": true, "menu_date": "2026-10-06", "saved_slots_count": 2, "message": "..."}`

### 4.8 `POST /api/v1/menus/copy` (Date-to-Date Copy)
- **Request Body:** `{"from_date": "2026-10-05", "to_date": "2026-10-06", "overwrite": false}`
- Copies every slot of `from_date` to `to_date` (BR-D7). A slot is skipped when:
  - the target slot is locked or has bills
  - the target slot already exists and `overwrite` is false
- Items no longer mapped to the cuisine are dropped from the copy.
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "copied": 4,
    "copied_slots_count": 4,
    "skipped": [
      {"cuisine_id": "uuid", "cuisine_name": "North Indian", "meal_type": "LUNCH",
       "item_id": null, "item_name": null, "reason": "Target slot already exists and overwrite is False"},
      {"cuisine_id": "uuid", "cuisine_name": "North Indian", "meal_type": "DINNER",
       "item_id": "uuid", "item_name": "Paneer", "reason": "Item no longer mapped to cuisine"}
    ],
    "message": "..."
  }
  ```
  - A slot-level skip has `item_id` / `item_name` set to `null`.
  - If `from_date` has no menus, the response has `copied: 0` and is not an error.
- **Errors:** 409 `PAST_DATE_READ_ONLY` when `to_date` < today.

### 4.9 `POST /api/v1/menus/copy-meal` (Cross-Cuisine Copy)
- **Request Body:**
  ```json
  {"menu_date": "2026-10-06", "from_cuisine_id": "uuid", "meal_type": "LUNCH", "to_cuisine_ids": ["uuid2", "uuid3"]}
  ```
- Copies one slot to other cuisines on the same date, overwriting existing target slots.
  - Target ids equal to the source or unknown are ignored silently.
  - Locked targets are skipped.
  - Items not mapped to a target cuisine are dropped for that target.
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "copied_cuisines": ["North Indian"],
    "skipped": [
      {"to_cuisine_id": "uuid3", "to_cuisine_name": "Arabic", "reason": "Target slot is locked (bills exist)"},
      {"to_cuisine_id": "uuid2", "to_cuisine_name": "North Indian", "item_id": "uuid", "item_name": "Idli", "reason": "Item not mapped to target cuisine"}
    ],
    "message": "..."
  }
  ```
- **Errors:** 409 `PAST_DATE_READ_ONLY` · 404 `NOT_FOUND` when the source slot does not exist.

---

## 5. Counter & Billing Operations

### 5.1 `POST /api/v1/counter/tap`
- **Alias:** `/api/method/mess_module.api.tap_rfid`.
- **Auth:** none.
- **Request:** `{"rfid_tag": "0012345678"}`
- **Always HTTP 200** (see §0.3). The 8 checks below run in order and the first failure is returned.

| # | `error_code` | Condition | Extra fields in the failure body |
|---|---|---|---|
| 1 | `EMPTY_TAG` | tag empty or whitespace | — |
| 2 | `UNREGISTERED` | card not found | — |
| 3 | `SUSPENDED` | stored status `SUSPENDED` | `member`, `today` |
| 4 | `EXPIRED` | today outside `validity_start`..`validity_end` | `member`, `today` |
| 5 | `NO_CUISINE` | member has no cuisine | `member`, `today` |
| 6 | `NO_MEAL_SERVICE` | no active window for the member's cuisine | `member`, `today`, `next` (meal-time object, §3.5) |
| 7 | `ALREADY_SERVED` | a `SERVED` bill exists today for this meal | `member`, `meal_type`, `meal_window`, `today`, `existing_bill: {id, bill_number, token_number, bill_time}` |
| 8 | `MENU_NOT_SET` | no daily menu, or a menu with no items, for (today, cuisine, meal). Never falls back to the cuisine master. | `member`, `meal_type`, `meal_window`, `today` |

Every failure body also has `success: false`, `error_code` and `message`.

- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "member": {
      "id": "uuid",
      "name": "Rahul Sharma",
      "cuisine_id": "uuid",
      "cuisine_name": "South Indian",
      "phone": "0501234567",
      "validity_end": "2026-12-31",
      "days_left": 87,
      "photo_url": null,
      "status": "ACTIVE"
    },
    "meal_type": "LUNCH",
    "meal_window": {"...meal-time object (§3.5)": "", "start_time": "12:00:00", "end_time": "15:00:00", "is_current": true},
    "items": [
      {"item_id": "uuid", "item_name": "Rice", "quantity": 1.0, "unit": "Plate", "price": 0.0,
       "category_id": "uuid", "category": "Main", "category_name": "Main", "uom_id": "uuid"}
    ],
    "today": {"BREAKFAST": true, "LUNCH": false, "DINNER": false},
    "total_amount": 0.0
  }
  ```
  `today` shows which meals the member has already been served today.

### 5.2 `POST /api/v1/counter/issue-token`
- **Alias:** `/api/method/mess_module.api.issue_token`.
- **Auth:** optional Bearer (used only for override, below).
- **Request:**
  ```json
  {
    "member_id": "uuid",
    "meal_type": "LUNCH",
    "is_override": 0,
    "override_by": null,
    "override_reason": null,
    "override_pin": null
  }
  ```
- **Guarantees:**
  - The whole issue runs in one `SELECT ... FOR UPDATE` transaction.
  - The member's status, validity, cuisine, active window and the duplicate check are all re-verified inside it.
  - Token numbers (`B-0001`, `L-0001`, `D-0001`) are race-safe and reset daily per meal.
  - Bill items are snapshotted from the daily menu at price 0.00.
- **Duplicate override:** when a `SERVED` bill already exists for this meal today, the request must send `is_override: 1` **and** one of:
  - a valid `override_pin`, or
  - a Bearer token for a `supervisor` or `admin` user.

  The recorded `override_by` is that supervisor's display name.
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "bill": {
      "id": "uuid",
      "bill_number": "BILL-20261005-L0001",
      "token_number": "L-0001",
      "date": "2026-10-05",
      "time": "12:35:10",
      "member_name": "Rahul Sharma",
      "cuisine": "South Indian",
      "meal_type": "LUNCH",
      "items": [{"name": "Rice", "quantity": 1.0}],
      "total_amount": 0.0,
      "is_override": 0
    }
  }
  ```
- **Errors:** most of these are plain `HTTPException` errors with no `error_code` (Pending: contract §1).

  | Status | `error_code` | When |
  |---|---|---|
  | 404 | — | Member not found |
  | 400 | — | Member suspended · card expired or not yet valid · no cuisine · no active meal window · requested `meal_type` is not the active window · menu not set / no items |
  | 409 | `ALREADY_SERVED` | Duplicate serve without `is_override`. `details: {existing_bill: {id, bill_number, token_number}}` |
  | 403 | — | `is_override` on a duplicate, but no valid PIN or supervisor/admin token |
  | 422 | `VALIDATION_ERROR` | Missing `member_id` / `meal_type` |

### 5.3 `GET /api/v1/bills`
- **Query Params:**

  | Param | Notes |
  |---|---|
  | `from_date`, `to_date` | inclusive range on `bill_date` |
  | `bill_date` | single day; **ignored** when `from_date` or `to_date` is sent |
  | `meal_type`, `cuisine_id`, `member_id` | exact match |
  | `status` | `SERVED` or `CANCELLED` |
  | `search` | `LIKE` on `bill_number`, `token_number`, member name |
  | `limit` | default **100**, min 1, max **500** (422 outside the range) |
  | `offset` | default 0 |

- **Response (200 OK):**
  - A plain array, newest first (`bill_date DESC, bill_time DESC`).
  - With no date filter, bills from every date are returned (up to `limit`).
  - No total count is returned. Pending: `X-Total-Count` header.
  ```json
  [
    {
      "id": "uuid", "bill_number": "BILL-20261005-L0001", "token_number": "L-0001",
      "bill_date": "2026-10-05", "bill_time": "12:35:10",
      "member_id": "uuid", "member_name": "Rahul Sharma",
      "cuisine_id": "uuid", "cuisine_name": "South Indian",
      "meal_type": "LUNCH", "total_amount": 0.0, "status": "SERVED",
      "is_override": 0, "override_by": null, "override_reason": null,
      "cancelled_by": null, "cancel_reason": null, "cancelled_at": null, "created_at": "...",
      "items": [{"id": "uuid", "bill_id": "uuid", "item_id": "uuid", "item_name": "Rice", "quantity": 1.0, "unit_price": 0.0, "total_price": 0.0}]
    }
  ]
  ```
  Items are batch-loaded in one query, so there is no N+1.

### 5.4 `GET /api/v1/bills/{id}`
- One bill in the same shape as §5.3.
- 404 `"Bill not found"` (plain error).

### 5.5 `POST /api/v1/bills/{id}/cancel`
- **Alias:** `POST /api/method/mess_module.api.cancel_token?bill_id=<uuid>`.
- **Request:** `{"reason": "Guest meal cancelled by supervisor", "cancelled_by": "Supervisor Name"}`. `reason` is required.
- **Who is recorded as the canceller:**

  | Request | Behaviour |
  |---|---|
  | Valid Bearer token, role `supervisor` or `admin` | Actor = that user's display name; `cancelled_by` is ignored |
  | Valid Bearer token, any other role | 403 `FORBIDDEN` |
  | No token, or an invalid one | `cancelled_by` is required and is recorded as given |

  Pending (contract): the actor must always come from the authenticated supervisor.
- Marks the bill `CANCELLED` and records `cancel_reason`, `cancelled_by` and `cancelled_at`. This frees the member's meal slot for the day, so a new token can be issued.
- **Response (200 OK):** `{"success": true, "message": "Bill BILL-20261005-L0001 cancelled successfully"}`
- **Errors:**

  | Status | `error_code` | When |
  |---|---|---|
  | 400 | `VALIDATION_ERROR` | `reason` is whitespace only |
  | 400 | — | No token and no `cancelled_by` |
  | 403 | `FORBIDDEN` | Token user is not supervisor/admin |
  | 404 | — | Bill not found |
  | 409 | `ALREADY_CANCELLED` | `details: {bill_id, bill_number}` |
  | 422 | `VALIDATION_ERROR` | `reason` missing or empty |

---

## 6. Reports & Analytics Engine

- **Auth:** none today (see §0.2).
- **Common filters:** `from_date` and `to_date` default to **today** when omitted. Only `SERVED` bills are counted; cancelled bills are excluded.
- **CSV exports:**
  - Pipe-delimited (`|`), UTF-8 with a BOM, served as `Content-Type: text/csv`.
  - `Content-Disposition: attachment; filename=<report>_<YYYY-MM-DD>.csv`.
  - Each export takes the same filters as its JSON endpoint.

| Report | JSON endpoint | CSV export |
|---|---|---|
| Headcount | `GET /api/v1/reports/headcount` | `GET /api/v1/reports/headcount/export-csv` |
| Headcount drill-down | `GET /api/v1/reports/headcount/tokens` | — |
| Attendance / Absentees | `GET /api/v1/reports/attendance` | `GET /api/v1/reports/attendance/export-csv` |
| Item Movement | `GET /api/v1/reports/item-movement` | `GET /api/v1/reports/item-movement/export-csv` |
| Time Distribution | `GET /api/v1/reports/time-distribution` | `GET /api/v1/reports/time-distribution/export-csv` |
| Members Register | `GET /api/v1/reports/members` | `GET /api/v1/reports/members/export-csv` |

### 6.1 Headcount — `GET /api/v1/reports/headcount`
- **Params:** `from_date`, `to_date`, `cuisine_id`, `meal_type`, `group_by` (`date` adds a per-day breakdown; any other value is ignored).
- **Response:** plain array, ordered by (date,) cuisine name, meal:
  ```json
  [{"bill_date": "2026-10-05", "cuisine_id": "uuid", "cuisine_name": "South Indian", "meal_type": "LUNCH", "headcount": 85}]
  ```
  `bill_date` is present only when `group_by=date`.
- **CSV columns:** `Cuisine|Meal Type|Headcount`, or `Date|Cuisine|Meal Type|Headcount` with `group_by=date`.

### 6.2 Headcount drill-down — `GET /api/v1/reports/headcount/tokens`
- **Params:** `bill_date` (alias `date`, default today), `cuisine_id`, `meal_type`.
- **Response:** plain array of served tokens, ordered by `bill_time`:
  ```json
  [{"id": "uuid", "bill_number": "...", "token_number": "L-0001", "bill_date": "2026-10-05", "bill_time": "12:35:10",
    "member_id": "uuid", "member_name": "Rahul Sharma", "cuisine_id": "uuid", "cuisine_name": "South Indian",
    "meal_type": "LUNCH", "total_amount": 0.0, "is_override": 0, "status": "SERVED"}]
  ```

### 6.3 Attendance — `GET /api/v1/reports/attendance`
- **Params:** `from_date`, `to_date`, `cuisine_id`, `meal_type`, `member_id`, `absentees_only` (`true`/`false`, default `false`).
- **Response (attendance view):**
  ```json
  {
    "view": "attendance",
    "from_date": "2026-10-01",
    "to_date": "2026-10-05",
    "count": 1,
    "records": [{"member_id": "uuid", "name": "Rahul Sharma", "cuisine_name": "South Indian",
                 "bill_date": "2026-10-05", "meal_type": "LUNCH", "token_number": "L-0001", "bill_time": "12:35:10"}]
  }
  ```
  Records are ordered newest first.
- **Response (`absentees_only=true`):**
  - Lists members with stored status `ACTIVE`, valid on or after `from_date`, with **no** served bill in the range.
  - `meal_type` and `member_id` are **ignored** in this view today. Pending (D4): `meal_type` will be applied (members with no served bill **for that meal** in the range); `member_id` stays ignored in this view.
  ```json
  {
    "view": "absentees",
    "from_date": "...",
    "to_date": "...",
    "count": 1,
    "records": [{"member_id": "uuid", "member_name": "Asha Nair", "cuisine_name": "South Indian", "phone": "...", "validity_end": "2026-12-31"}]
  }
  ```
  Note the record key is `member_name` here but `name` in the attendance view.
- **CSV columns:**
  - Attendance view: `Member Id|Member Name|Cuisine|Date|Meal Type|Token Number|Time`. Filename `attendance_<date>.csv`.
  - Absentees view: `Member Id|Member Name|Cuisine|Phone|Validity End`. Filename `absentees_<date>.csv`.

### 6.4 Item Movement — `GET /api/v1/reports/item-movement`
- **Params:** `from_date`, `to_date`, `cuisine_id`, `meal_type`.
- **Response:** plain array, ordered by `total_quantity DESC`:
  ```json
  [{"item_name": "Rice", "unit": "Plate", "cuisine_name": "South Indian", "category": "Main", "total_quantity": 120.0, "served_count": 118}]
  ```
  `served_count` = number of distinct bills containing the item.
- **CSV columns:** `Item Name|Unit|Category|Cuisine|Total Quantity|Tokens Served` (missing unit → `Nos`).

### 6.5 Time Distribution — `GET /api/v1/reports/time-distribution`
- **Params:** `from_date`, `to_date`, `cuisine_id`, `meal_type`, `interval` (`15`, `30` or `60`, default `60`). Any other integer silently becomes **60** today.
  - Pending (D5): any other value is rejected, on both the JSON and CSV endpoints, with:
    ```json
    {"success": false, "error_code": "VALIDATION_ERROR", "message": "interval must be 15, 30 or 60.",
     "details": {"interval": 45, "allowed": [15, 30, 60]}}
    ```
    HTTP **422**.
- **Response:**
  ```json
  {
    "interval_minutes": 30,
    "from_date": "2026-10-05",
    "to_date": "2026-10-05",
    "total_tokens": 205,
    "first_token_time": "07:02:11",
    "last_token_time": "21:48:40",
    "peak_slot": "12:30 - 13:00",
    "peak_count": 40,
    "slots": [{"slot": "12:30 - 13:00", "BREAKFAST": 0, "LUNCH": 40, "DINNER": 0, "total": 40}]
  }
  ```
  - Only slots containing at least one token are listed, in time order.
  - With no tokens: `peak_slot`, `first_token_time` and `last_token_time` are `null`, and `peak_count` is 0.
- **CSV columns:** `Time Slot|Breakfast|Lunch|Dinner|Total Tokens`.

### 6.6 Members Register — `GET /api/v1/reports/members`
- **Params:**
  - `status`: on the derived status.
  - `expiring_in_days`: keeps members with `0 <= days_left <= N`.
  - `registered_from`, `registered_to`: on `created_at` date.
  - `cuisine_id`.

  Dates do **not** default to today here.
- **Response:**
  ```json
  {
    "total_members": 2,
    "summary": {"active": 1, "expired": 1, "suspended": 0, "by_cuisine": {"South Indian": 2}},
    "members": [
      {"id": "uuid", "name": "Rahul Sharma", "rfid_tag": "0012345678", "phone": "...", "email": "...",
       "cuisine_id": "uuid", "cuisine_name": "South Indian", "validity_start": "2026-10-01", "validity_end": "2026-12-31",
       "days_left": 87, "status": "ACTIVE", "created_at": "2026-10-01 09:00:00"}
    ]
  }
  ```
  - `summary` counts only the members that pass the filters.
  - A member with no cuisine is listed and counted under `"Unassigned"`.
- **CSV columns:** `Member ID|Name|RFID Tag|Phone|Email|Cuisine|Validity Start|Validity End|Days Left|Status`.

---

## 7. Home Operational Dashboard

### 7.1 `GET /api/v1/dashboard/summary`
- **Auth:** none today.
- **Response (200 OK):**
  ```json
  {
    "server_time": "2026-10-05 12:45:00",
    "current_meal": "LUNCH",
    "next_meal": "DINNER",
    "current_window": {"...meal-time object (§3.5)": "", "is_current": true},
    "next_window": {"...meal-time object (§3.5)": "", "is_current": false},
    "served_today": {
      "BREAKFAST": 120, "LUNCH": 85, "DINNER": 0,
      "B": 120, "L": 85, "D": 0,
      "total": 205
    },
    "menu_readiness": [
      {
        "cuisine_id": "uuid",
        "cuisine_name": "South Indian",
        "status": "FULL",
        "filled_count": 3,
        "total_slots": 3,
        "BREAKFAST": true,
        "LUNCH": true,
        "DINNER": true,
        "slots": {"BREAKFAST": true, "LUNCH": true, "DINNER": true}
      }
    ],
    "expiring_members_count": 14
  }
  ```
- Field notes:
  - `current_meal` / `current_window` / `next_window` consider the windows of **all** cuisines. They are `null` when nothing is active or configured.
  - `served_today` counts `SERVED` bills only. `B`/`L`/`D` are short aliases of the full keys.
  - `menu_readiness` is the `readiness` array from §4.5 for today.
  - `expiring_members_count` counts members with stored status `ACTIVE` whose `validity_end` falls between today and today + 7 days (inclusive).
