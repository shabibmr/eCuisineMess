# eCuisine Mess Module — Backend API Reference

**Document Version:** 1.3.0  
**Stack:** FastAPI (Python 3.13) + MariaDB (PyMySQL / PooledDB)  
**Interactive Documentation:** Swagger UI: `http://localhost:8000/docs` · ReDoc: `http://localhost:8000/redoc`  
**Master Contract:** [`docs/04-api-contract.md`](../../docs/04-api-contract.md)  
**Standard Error Envelope:** HTTP 409 Conflict with `{ "success": false, "error_code": "...", "message": "...", "details": {...} }`

---

## 1. Authentication & User Management

### 1.1 `POST /api/v1/auth/login`
- **Description:** Authenticates user credentials and returns a 30-day session token.
- **Request Body:**
  ```json
  {
    "username": "admin",
    "password": "adminpassword"
  }
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

### 1.2 `POST /api/v1/auth/logout`
- **Description:** Invalidate and delete the active session token from `mess_user_sessions`.
- **Headers:** `Authorization: Bearer <token>`
- **Response (200 OK):** `{"success": true, "message": "Logged out successfully"}`

### 1.3 `GET /api/v1/auth/me`
- **Description:** Returns profile and RBAC role of current authenticated session.
- **Headers:** `Authorization: Bearer <token>`
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "user": {
      "id": "uuid",
      "username": "admin",
      "display_name": "System Administrator",
      "role": "admin",
      "is_active": 1
    }
  }
  ```

### 1.4 `POST /api/v1/auth/verify-supervisor`
- **Description:** Verify supervisor PIN or username + password for high-privilege operations (override, bill cancel).
- **Request Body (via PIN):**
  ```json
  {
    "pin": "1234"
  }
  ```
- **Request Body (via Credentials):**
  ```json
  {
    "username": "supervisor_user",
    "password": "password123"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Supervisor credentials verified",
    "supervisor": {
      "id": "uuid",
      "username": "supervisor_user",
      "display_name": "Duty Supervisor",
      "role": "supervisor"
    }
  }
  ```
- **Error (403 Forbidden):** Invalid PIN or user lacks `supervisor`/`admin` role.

### 1.5 `POST /api/v1/auth/change-password`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:** `{"old_password": "...", "new_password": "..."}`
- **Response (200 OK):** `{"success": true, "message": "Password changed successfully"}`

### 1.6 `GET /api/v1/users` & `POST /api/v1/users`
- **Description:** User administration for creating staff accounts with assigned roles (`admin`, `supervisor`, `counter`).

---

## 2. Health & System Clock

### 2.1 `GET /api/v1/health`
- **Description:** System health check reporting MariaDB connection status and active meal window.
- **Response (200 OK):**
  ```json
  {
    "status": "online",
    "database": "connected",
    "server_time": "2026-10-05 12:30:00",
    "active_meal": "LUNCH"
  }
  ```

---

## 3. Masters Management

### 3.1 Unit of Measure (`/api/v1/uoms`)
- `GET /api/v1/uoms`: Seed master listing units (Plate, Bowl, Nos, Cup, Glass, Portion, Packet, Bottle, Kg).

### 3.2 Item Categories (`/api/v1/item-categories`)
- `GET /api/v1/item-categories?include_inactive=0`: List categories.
- `POST /api/v1/item-categories`: Create category (`category_name` unique, 409 conflict).
- `PUT /api/v1/item-categories/{id}`: Partial update.
- `DELETE /api/v1/item-categories/{id}`: Deactivates if referenced by items, else deletes.

### 3.3 Items (`/api/v1/items`)
- `GET /api/v1/items?cuisine_id=&category_id=&category=&search=&include_inactive=0`: List items with category, UOM, and optional cuisine mapping filter.
- `GET /api/v1/items/{id}`: Fetch item with `mapped_cuisines` list.
- `POST /api/v1/items`: Create item (requires `item_name`, `category_id`, `uom_id`).
- `PUT /api/v1/items/{id}`: Update item properties.
- `DELETE /api/v1/items/{id}`: Deactivates if referenced in cuisine mappings, daily menus, or bills.

### 3.4 Cuisines (`/api/v1/cuisines`)
- `GET /api/v1/cuisines?include_inactive=0`: Returns cuisines with `mapped_items_count`, `active_members_count`, and `items[]`.
- `GET /api/v1/cuisines/{id}`: Single cuisine details.
- `POST /api/v1/cuisines`: Create cuisine with item mappings and auto-generates 3 default meal windows (Breakfast 07:00–10:00, Lunch 12:00–15:00, Dinner 19:00–22:00) per BR-T5.
- `PUT /api/v1/cuisines/{id}`: Update metadata and replace mappings. Enforces unmap protection (BR-C5): raises `409 UNMAP_BLOCKED` if an unmapped item is scheduled in today's or future daily menus.
- `POST /api/v1/cuisines/{id}/copy-mapping`: Merge item mappings from a source cuisine without duplicates.
- `DELETE /api/v1/cuisines/{id}`: Deactivates if members or bills exist.

### 3.5 Meal Times (`/api/v1/meal-times`)
- `GET /api/v1/meal-times?cuisine_id=`: List meal windows for a specific cuisine.
- `GET /api/v1/meal-times/current?cuisine_id=`: Returns active window and `next` upcoming window without fallback to Breakfast.
- `PUT /api/v1/meal-times/{id}`: Update window timing. Validates `start_time < end_time` and enforces non-overlapping windows within the same cuisine (`409 MEAL_TIME_OVERLAP`).

### 3.6 Members (`/api/v1/members`)
- `GET /api/v1/members?search=&status=&cuisine_id=&limit=&offset=`: List members with dynamically derived status (`ACTIVE`, `EXPIRED`, `SUSPENDED`) and `days_left`.
- `GET /api/v1/members/{id}`: Single member record.
- `GET /api/v1/members/by-rfid/{rfid_tag}`: Check card duplicate during enrollment.
- `POST /api/v1/members`: Enroll member. Enforces unique RFID (`409 RFID_IN_USE`).
- `PUT /api/v1/members/{id}`: Update member profile.
- `PATCH /api/v1/members/{id}/status`: Manual status toggle (`ACTIVE`, `SUSPENDED`, `EXPIRED`).
- `POST /api/v1/members/{id}/photo`: Upload member photo or save photo URL.
- `DELETE /api/v1/members/{id}`: Sets `SUSPENDED` if bills exist, else deletes.

---

## 4. Daily Menu Domain Service

### 4.1 `GET /api/v1/menus/today`
- Returns all daily menus across all cuisines and meal types for today with items and derived `is_locked`.

### 4.2 `GET /api/v1/menus?menu_date=&cuisine_id=&meal_type=`
- Filtered daily menus query.

### 4.3 `GET /api/v1/menus/{menu_id}`
- Single daily menu with items and lock status.

### 4.4 `GET /api/v1/menus/history?from_date=&to_date=&cuisine_id=&limit=&offset=`
- Paginated historical menus list with item count summaries and saved timestamps.

### 4.5 `GET /api/v1/menus/status?menu_date=`
- Daily menu fill readiness for dashboard and editor sidebar:
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
        "DINNER": true
      }
    ]
  }
  ```

### 4.6 `POST /api/v1/menus` (Slot Save)
- **Rules Enforced:**
  - `409 PAST_DATE_READ_ONLY` if `menu_date < CURDATE()`.
  - `409 MENU_LOCKED` if non-cancelled bills exist for (date, cuisine, meal).
  - `409 UNMAPPED_ITEM` if item is not mapped to the cuisine (BR-D2).
  - `409 DUPLICATE_MENU_ITEM` if item is repeated in the meal slot (BR-D3).

### 4.7 `POST /api/v1/menus/save-day` (Whole-Day Atomic Save)
- **Request Body:**
  ```json
  {
    "menu_date": "2026-10-06",
    "menus": [
      {
        "cuisine_id": "uuid1",
        "meal_type": "BREAKFAST",
        "item_ids": ["uuid-item-1", "uuid-item-2"]
      },
      {
        "cuisine_id": "uuid1",
        "meal_type": "LUNCH",
        "items": [{"item_id": "uuid-item-3", "quantity": 1.0}]
      }
    ]
  }
  ```
- **Response (200 OK):** `{"success": true, "menu_date": "2026-10-06", "saved_slots_count": 2, "message": "..."}`

### 4.8 `POST /api/v1/menus/copy` (Date-to-Date Copy)
- Copies all menu slots from `from_date` to `to_date`.
- Automatically skips items no longer mapped to the cuisine and returns a detailed `skipped` report.

### 4.9 `POST /api/v1/menus/copy-meal` (Cross-Cuisine Copy)
- Copies a meal slot from one cuisine to a list of target cuisines, verifying mapped items for each target cuisine.

---

## 5. Counter & Billing Operations

### 5.1 `POST /api/v1/counter/tap`
- **Request:** `{"rfid_tag": "0012345678"}`
- **Sequential Checks (Checks 1–8):**
  1. `EMPTY_TAG`: RFID tag empty or whitespace.
  2. `UNREGISTERED`: Card not found in `mess_members`.
  3. `SUSPENDED`: Member status is `SUSPENDED`.
  4. `EXPIRED`: Current date outside `validity_start` and `validity_end`.
  5. `NO_CUISINE`: Member has no assigned cuisine.
  6. `NO_MEAL_SERVICE`: Server time outside meal window for member's cuisine (returns `next` upcoming window).
  7. `ALREADY_SERVED`: Non-cancelled bill already issued today for this meal.
  8. `MENU_NOT_SET`: No daily menu set for (today, cuisine, meal). Never falls back to cuisine master.
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "member": {
      "id": "uuid",
      "name": "Rahul Sharma",
      "cuisine_id": "uuid",
      "cuisine_name": "South Indian",
      "validity_end": "2026-12-31",
      "days_left": 87,
      "photo_url": null
    },
    "meal_type": "LUNCH",
    "meal_window": {"start_time": "12:00:00", "end_time": "15:00:00"},
    "items": [
      {"item_id": "uuid", "item_name": "Rice", "quantity": 1.0, "unit": "Plate", "price": 0.0}
    ],
    "today": {"BREAKFAST": true, "LUNCH": false, "DINNER": false},
    "total_amount": 0.0
  }
  ```

### 5.2 `POST /api/v1/counter/issue-token`
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
  - Entire issuance runs within an atomic `SELECT ... FOR UPDATE` transaction.
  - Generates race-safe, collision-free token numbers (`B-0001`, `L-0001`, `D-0001`) reset daily.
  - Re-verifies duplicate serve check inside the transaction. If duplicate exists, requires verified supervisor credentials.
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

### 5.3 `GET /api/v1/bills`
- **Query Params:** `from_date`, `to_date`, `bill_date`, `meal_type`, `cuisine_id`, `member_id`, `status`, `search`, `limit`, `offset`.
- Batch queries items to eliminate N+1 latency.

### 5.4 `POST /api/v1/bills/{id}/cancel`
- **Request:** `{"reason": "Guest meal cancelled by supervisor", "cancelled_by": "Supervisor Name"}`
- Marks bill as `CANCELLED`, records reason and timestamp, and releases the member's meal slot for the day. Re-cancelling a cancelled bill is blocked.

---

## 6. Reports & Analytics Engine

All report exports strictly adhere to **pipe-delimited (`|`) format** with **UTF-8 BOM (`\ufeff`)** for Microsoft Excel and Arabic text support.

| Report | JSON Endpoint | CSV Export Endpoint | Key Filters / Capabilities |
|---|---|---|---|
| **Headcount** | `GET /reports/headcount` | `GET /reports/headcount/export-csv` | `from_date`, `to_date`, `cuisine_id`, `meal_type`, `group_by=date` |
| **Headcount Drill-Down** | `GET /reports/headcount/tokens` | – | `bill_date`, `cuisine_id`, `meal_type` (returns individual token slips) |
| **Attendance** | `GET /reports/attendance` | `GET /reports/attendance/export-csv` | `from_date`, `to_date`, `cuisine_id`, `meal_type`, `member_id`, `absentees_only=true` |
| **Item Movement** | `GET /reports/item-movement` | `GET /reports/item-movement/export-csv` | `from_date`, `to_date`, `cuisine_id`, `meal_type` (includes category & UOM) |
| **Time Distribution** | `GET /reports/time-distribution` | `GET /reports/time-distribution/export-csv` | `interval=15\|30\|60`, peak slot detection, first/last token time |
| **Members Register** | `GET /reports/members` | `GET /reports/members/export-csv` | `status`, `expiring_in_days`, `registered_from`, `registered_to`, `cuisine_id`, summary totals |

---

## 7. Home Operational Dashboard

### 7.1 `GET /api/v1/dashboard/summary`
- **Response (200 OK):**
  ```json
  {
    "server_time": "2026-10-05 12:45:00",
    "current_meal": "LUNCH",
    "next_meal": "DINNER",
    "served_today": {
      "BREAKFAST": 120,
      "LUNCH": 85,
      "DINNER": 0,
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
        "DINNER": true
      }
    ],
    "expiring_members_count": 14
  }
  ```
