# Mess Module – Screens Specification

Source requirements: [Mess_Modules.md](Mess_Modules.md)

---

## 0. Screen Index

| #  | Screen / Widget                    | Type               | Module |
|----|------------------------------------|--------------------|--------|
| 1  | Item List                          | List               | B      |
| 2  | Item Editor                        | Create / Edit      | B      |
| 3  | Item Search Widget                 | Reusable widget    | B      |
| 4  | Cuisine List                       | List               | B      |
| 5  | Cuisine Editor                     | Create / Edit      | B      |
| 6  | Cuisine Search Widget              | Reusable widget    | B      |
| 7  | Customer List                      | List               | A      |
| 8  | Customer Editor (Registration)     | Create / Edit      | A      |
| 9  | Customer Search Widget             | Reusable widget    | A      |
| 10 | Meal Time Settings                 | Settings           | D      |
| 11 | Daily Menu Editor                  | Create / Edit      | C      |
| 12 | Daily Menu History                 | List + Read-only   | C      |
| 13 | Mess Billing (RFID Counter)        | Transaction        | D      |
| 14 | Mess Token (KOT) Print Layout      | Print format       | D      |
| 15 | Mess Bill Register                 | List + Reprint     | D      |
| 16 | Members Register Report            | Report             | E      |
| 17 | Cuisine × Meal Headcount Report    | Report             | E      |
| 18 | Item-wise Movement Report          | Report             | E      |
| 19 | Customer-wise Attendance Report    | Report             | E      |
| 20 | Time-based Report                  | Report             | E      |

### Common patterns

**List screens** (Item, Cuisine, Customer)
- Toolbar: `New`, `Edit`, `Delete`, `Refresh`, `Export`.
- Search box (filters as you type) + `Show Inactive` checkbox.
- Sortable table. Double-click / Enter on a row opens the Editor.
- Delete is blocked when the record is referenced; the user is offered `Mark Inactive` instead.

**Editor screens**
- Same screen for Create and Edit (title shows `New …` / `Edit …`).
- Buttons: `Save`, `Save & New`, `Cancel`.
- Validation errors are shown inline next to the field; `Save` stays disabled until required fields are filled.

**Search widgets** (Item, Cuisine, Customer)
- Line edit with a drop-down completer, usable anywhere a record must be picked.
- Matches on code and name (Customer also on RFID and phone), case-insensitive, contains-match.
- Shows only active records by default.
- Keyboard: ↑/↓ to move, Enter to select, Esc to close. `F2` opens the full List screen in pick mode.
- Emits `selected(id)`; exposes `currentId()`, `setCurrentId(id)`, `clear()`.
- Optional `+ New` entry at the bottom opens the Editor and selects the new record on save.

---

## 1. Item List

Lists all mess food items.

| Column    | Notes                     |
|-----------|---------------------------|
| Code      |                           |
| Item Name |                           |
| Category  |                           |
| Unit      | Plate, Nos, Bowl, Cup, …  |
| Active    | Yes / No                  |

## 2. Item Editor

| Field       | Type          | Rules                     |
|-------------|---------------|---------------------------|
| Item Code   | Text          | Required, unique          |
| Item Name   | Text          | Required                  |
| Category    | Drop-down     | Optional                  |
| Unit        | Drop-down     | Required (default `Nos`)  |
| Default Qty | Decimal       | Default `1`. Pre-filled when the item is added to a menu |
| Active      | Checkbox      | Default on                |

- Data: `inventoryItemDataModel`, with a flag `is_mess_item = 1` (or a dedicated `mess_items` table).
- An item that is mapped to any cuisine, or used in any daily menu or bill, cannot be deleted, only made inactive.
- A read-only **Mapped Cuisines** list at the bottom of the editor shows which cuisines use this item.

## 3. Item Search Widget

- Follows the common search-widget pattern above.
- Result row shows: `Code – Name (Unit)`.
- Optional filter: `setCuisine(id)` limits results to items mapped to that cuisine.
- Used by: Daily Menu Editor (with the cuisine filter) and the Item-wise Movement report filter (no filter).

---

## 4. Cuisine List

| Column         | Notes                               |
|----------------|-------------------------------------|
| Code           |                                     |
| Cuisine Name   | e.g. North Indian, South Indian, Arabic |
| Mapped Items   | Count of items mapped to this cuisine |
| Active Members | Count of customers on this cuisine  |
| Active         | Yes / No                            |

## 5. Cuisine Editor

### Header

| Field        | Type      | Rules            |
|--------------|-----------|------------------|
| Cuisine Code | Text      | Required, unique |
| Cuisine Name | Text      | Required, unique |
| Description  | Text      | Optional         |
| Active       | Checkbox  | Default on       |

### Item Mapping

Lists the items that may be served under this cuisine. Only these items can be added to this cuisine's daily menu.

```
┌──────────────────────────────────────────────────────────────────────┐
│ Code: [SI ]  Name: [South Indian        ]  [✔] Active                 │
├────────────────────────────┬───┬─────────────────────────────────────┤
│ AVAILABLE ITEMS            │   │ MAPPED ITEMS (12)                   │
│ Search: [ dos__        ]   │   │ Search: [               ]           │
│ ☐ Masala Dosa   (Nos)      │ ▶ │ Code  Item               Unit       │
│ ☐ Plain Dosa    (Nos)      │ ▶▶│ I012  Idli               Nos        │
│ ☐ Rava Dosa     (Nos)      │ ◀ │ I020  Sambar             Bowl       │
│                            │ ◀◀│ I031  Rice               Plate      │
│ Category: [All ▼]          │   │ …                                   │
├────────────────────────────┴───┴─────────────────────────────────────┤
│ [Copy Mapping From Cuisine…]               [Save] [Save & New] [Cancel]│
└──────────────────────────────────────────────────────────────────────┘
```

- **Left pane:** active items not yet mapped. Filter by search text and Category; multi-select with checkboxes.
- **Buttons:** `▶` adds the selected items, `▶▶` adds every item in the filtered list, `◀` removes the selected items, `◀◀` removes all. Double-clicking a row moves it to the other pane.
- **Right pane:** the items mapped to this cuisine, with search. A mapped item can be put on the menu for any meal.
- **Copy Mapping From Cuisine…:** adds the mapping of another cuisine (picked with the Cuisine Search Widget) to this one. Items already mapped are not duplicated.
- Mapping changes are saved together with the header by the one `Save` button.

### Rules
- A cuisine with no mapped items can be saved, but shows the warning "No items mapped – menu cannot be set for this cuisine".
- **Unmapping an item that is in today's or a future daily menu** for this cuisine is blocked. The message lists the affected dates; the user must remove the item from those menus first. Past menus and bills are not affected.
- An inactive item stays in the mapping (shown greyed out) but is not offered in the Daily Menu Editor.

- Data: `mess_cuisines` (header), `mess_cuisine_items` (mapping).
- A cuisine assigned to any customer or used in any menu cannot be deleted, only made inactive.
- An inactive cuisine cannot be picked for new customers and does not appear in the Daily Menu Editor.

## 6. Cuisine Search Widget

- Follows the common search-widget pattern above.
- Result row shows: `Code – Name`.
- Used by: Customer Editor and the report filters.

---

## 7. Customer List

| Column        | Notes                                    |
|---------------|------------------------------------------|
| Member Code   |                                          |
| Name          |                                          |
| Phone         |                                          |
| RFID          | Masked except last 4 digits              |
| Cuisine       |                                          |
| Valid From    |                                          |
| Valid To      | Highlighted when expired or expiring within 7 days |
| Status        | Active / Expired / Inactive              |

Extra filters: Cuisine (Cuisine Search Widget) and Status.

## 8. Customer Editor (Member Registration)

| Field        | Type                  | Rules                                         |
|--------------|-----------------------|-----------------------------------------------|
| Member Code  | Text                  | Auto-generated, editable, unique              |
| Name         | Text                  | Required                                      |
| Phone        | Text                  | Optional                                      |
| RFID Card No | Text + `Capture` button | Required, unique among all customers        |
| Cuisine      | Cuisine Search Widget | Required, active cuisine only                 |
| Valid From   | Date                  | Required, default today                       |
| Valid To     | Date                  | Required, must be ≥ Valid From                |
| Photo        | Image                 | Optional, shown on the billing screen         |
| Active       | Checkbox              | Default on                                    |

**RFID capture**
- `Capture` puts the field into listening mode ("Tap card now…"). The next reader input fills the field.
- If the card is already linked to another customer, show that customer's name and block saving.
- `Clear RFID` unlinks the card (for lost or replaced cards).

- Data: `mess_customers` (optionally linked to `AddressBook/Contacts` via `contact_id`).

## 9. Customer Search Widget

- Follows the common search-widget pattern above.
- Matches on Member Code, Name, Phone, or RFID. A card tapped while the widget has focus selects that customer directly.
- Result row shows: `Code – Name – Cuisine – Valid To`.
- Used by: the Customer-wise Attendance report filter and the Mess Bill Register filter.

---

## 10. Meal Time Settings

Sets the time windows used to work out the current meal in billing.

| Meal      | From  | To    | Active |
|-----------|-------|-------|--------|
| Breakfast | 06:00 | 10:00 | ✔      |
| Lunch     | 12:00 | 15:00 | ✔      |
| Dinner    | 19:00 | 22:30 | ✔      |

- Windows cannot overlap.
- Data: `mess_meal_times`.

---

## 11. Daily Menu Editor

Enter the items for **Breakfast, Lunch and Dinner** for **all cuisines** for one date, on one screen.

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│ Date: [02-10-2026 ▼]   [◀ Prev] [Next ▶]   [Copy From Date…] [History]│
├───────────────┬──────────────────────────────────────────────────────┤
│ CUISINES      │  [ Breakfast ] [ Lunch ] [ Dinner ]   ← meal tabs     │
│ ▸ North Indian│ ┌──────────────────────────────────────────────────┐ │
│ ✔ South Indian│ │ Item (Item Search Widget)     │ Qty │ Unit │  ✕  │ │
│   Arabic      │ │ Idli                          │  3  │ Nos  │  ✕  │ │
│   Continental │ │ Sambar                        │  1  │ Bowl │  ✕  │ │
│               │ │ + add item…                   │     │      │     │ │
│               │ └──────────────────────────────────────────────────┘ │
├───────────────┴──────────────────────────────────────────────────────┤
│ Status: B ✔  L ✔  D ✖ (South Indian)          [Save] [Reset] [Close] │
└──────────────────────────────────────────────────────────────────────┘
```

- **Left pane:** all active cuisines. A tick means all three meals have items for that cuisine. A dot means some are filled.
- **Meal tabs:** Breakfast / Lunch / Dinner for the selected cuisine. Each tab shows its item count.
- **Item grid:** add rows with the Item Search Widget, filtered to the **items mapped to the selected cuisine**. Qty is pre-filled from the item's Default Qty and can be changed. The same item cannot appear twice in one meal.
- **Add All Mapped** (button above the grid): adds every item mapped to this cuisine to the current meal tab in one step. Qty can then be changed, and unwanted rows removed.
- **Copy From Date…:** copies the whole menu (all cuisines, all meals) from another date. It asks before overwriting entries already made. Items no longer mapped to their cuisine are skipped and listed in a summary.
- **Copy to other cuisines** (right-click on a meal tab): copies this meal's items to the selected cuisines. Items not mapped to a target cuisine are skipped and listed in a summary.
- A cuisine with no mapped items shows "No items mapped – open Cuisine Editor" in place of the grid, with a link that opens the editor.
- A single `Save` writes the whole date (all cuisines × all meals) in one transaction.

### Rules
- **Date:** today and future dates are editable. **Past dates open read-only** (same as History).
- Once a bill exists for a date + cuisine + meal, that meal is locked for that cuisine, so tokens already printed stay consistent with the menu.
- Leaving with unsaved changes asks `Save / Discard / Cancel`.

### Data
- `mess_daily_menu` (date, cuisine_id, meal_type) → `mess_daily_menu_items` (item_id, qty).

## 12. Daily Menu History (read-only)

- **List:** Date range filter (default: last 30 days) and Cuisine filter.
  Columns: Date, Cuisine, Breakfast items, Lunch items, Dinner items, Last saved by, Saved at.
- **View:** opens the Daily Menu Editor layout for the selected date with every field **disabled** and a "History – Read Only" banner. Only `Print`, `Copy to Date…` (opens the editor on a new date, filled with these items) and `Close` are available.
- No edit or delete from history.

---

## 13. Mess Billing (RFID Counter)

A screen for counter staff. The cursor always returns to the RFID input.

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│ MESS COUNTER        Current Meal: LUNCH (12:00–15:00)     14:23:05    │
├──────────────────────────────────────────────────────────────────────┤
│ RFID: [ ●●●●●●●●  ]   ← auto-focus; tap card                          │
├───────────────────────────┬──────────────────────────────────────────┤
│ [Photo]  Name: Rahul K     │  #  Item              Qty  Rate  Amount  │
│ Code: M-0042               │  1  Rice               1   0.00   0.00   │
│ Cuisine: South Indian      │  2  Sambar             1   0.00   0.00   │
│ Valid To: 31-12-2026  ✔    │  3  Rasam              1   0.00   0.00   │
│ Today: B ✔  L —  D —       │  4  Poriyal            1   0.00   0.00   │
│                            │                       Total:      0.00   │
├───────────────────────────┴──────────────────────────────────────────┤
│ [Save & Print Token (F10)]   [Clear (Esc)]        Last Token: L-0187  │
└──────────────────────────────────────────────────────────────────────┘
```

### Flow
1. **Tap RFID card.** The reader input lands in the RFID field.
2. **Identify the customer** from `mess_customers.rfid`.
3. **Use the customer's registered cuisine.**
4. **Work out the current meal** from the system time and the Meal Time Settings.
5. **Load the invoice items:** all items from **today's menu** for *that cuisine + current meal* are added to the invoice item list (Qty from the menu, Rate = 0.00).
6. **Save** (button or F10):
   - saves the bill at **0.00** (`salesvoucher`, with mess fields: customer_id, cuisine_id, meal_type, token_no),
   - **prints the token (KOT)**,
   - clears the screen and returns the cursor to RFID for the next customer.

### Validations (shown as a large red banner with a beep; nothing is added to the invoice)

| Condition                                  | Message                                  |
|--------------------------------------------|------------------------------------------|
| Card not registered                        | "Card not registered"                    |
| Customer inactive                          | "Membership inactive"                    |
| Today outside Valid From – Valid To        | "Membership expired on dd-mm-yyyy"       |
| Current time outside every meal window     | "No meal service now. Next: Dinner 19:00"|
| No menu saved for cuisine + meal today     | "Menu not set for South Indian – Lunch"  |
| Customer already billed for this meal today| "Already served Lunch at 13:05 (L-0151)" |

- If a new card is tapped before Save, the current invoice is replaced by the new customer.
- Item lines cannot be edited by counter staff. An optional **Supervisor Override** (password) allows removing a line or overriding the "already served" check; the override is recorded on the bill.

## 14. Mess Token (KOT) Print Layout

For a thermal printer (58 / 80 mm):

```
        <COMPANY NAME>
          MESS TOKEN
--------------------------------
Token : L-0187       LUNCH
Date  : 02-10-2026   14:23
Name  : Rahul K (M-0042)
Cuisine: South Indian
--------------------------------
Item                       Qty
Rice                         1
Sambar                       1
Rasam                        1
Poriyal                      1
--------------------------------
Counter: C1     User: admin
```

- Token number: meal prefix (B/L/D) + running number that **resets daily**.
- Reprints are marked "DUPLICATE".

## 15. Mess Bill Register

- Filters: Date range, Meal, Cuisine, Customer (Customer Search Widget).
- Columns: Token No, Date, Time, Customer, Cuisine, Meal, Items count, User, Override flag.
- Actions: `View` (read-only), `Reprint Token`, `Cancel Bill` (supervisor only, reason required; cancelled bills are left out of all reports).

---

## 16–20. Reports

**Common report frame**
- Filter bar: From/To Date (default: today), Cuisine (Cuisine Search Widget), Meal Type (All/B/L/D), plus the filters specific to each report.
- `Generate`, `Print`, `Export (Excel / PDF / CSV)`.
- Sortable grid with a totals row. Double-click drills down where noted.
- Cancelled bills are always excluded.

### 16. Members Register Report
- Extra filters: Status (Active / Expired / Expiring in N days / Inactive), Registered between.
- Columns: Member Code, Name, Phone, RFID (masked), Cuisine, Valid From, Valid To, Days Left, Status.
- Totals: member count by status and by cuisine.

### 17. Cuisine-wise × Meal-Type-wise Headcount Report
- Matrix: rows = Cuisine, columns = Breakfast | Lunch | Dinner | Total. Cell = number of tokens.
- Grand totals by row and column.
- Option `Group by Date` adds Date as the outer row group (day-by-day headcount).
- Drill-down: cell → list of tokens.

### 18. Item-wise Movement Report
- Extra filter: Item (Item Search Widget).
- Columns: Item Code, Item Name, Unit, Breakfast Qty, Lunch Qty, Dinner Qty, Total Qty.
- Option `Group by Cuisine` / `Group by Date`.
- Drill-down: item → date-wise quantities.

### 19. Customer-wise Attendance Report
- Extra filter: Customer (Customer Search Widget), `Show only absentees`.
- **Summary view:** Member, Cuisine, Days in period, Breakfast count, Lunch count, Dinner count, Total meals, Days absent.
- **Detail view (calendar grid):** rows = customers, columns = dates, cell = `B L D` markers for meals taken.
- Drill-down: customer → list of tokens with times.

### 20. Time-based Report
- Extra filters: Interval (15 / 30 / 60 min).
- **Time-slot view:** rows = time slots within each meal window, columns = token count, % of meal total. Highlights the peak slot.
- **Hourly by Date view:** rows = dates, columns = hours, cell = token count.
- Summary: first token, last token, peak slot, and average tokens per slot for each meal.

---

## Data Model Summary

| Table                     | Key Fields                                                            |
|---------------------------|-----------------------------------------------------------------------|
| `mess_items` / `inventoryItemDataModel` | id, code, name, category, unit, default_qty, active     |
| `mess_cuisines`           | id, code, name, description, active                                   |
| `mess_cuisine_items`      | cuisine_id, item_id — unique (cuisine_id, item_id)                    |
| `mess_customers`          | id, member_code, name, phone, rfid (unique), cuisine_id, valid_from, valid_to, photo, active, contact_id |
| `mess_meal_times`         | meal_type (B/L/D), time_from, time_to, active                         |
| `mess_daily_menu`         | id, menu_date, cuisine_id, meal_type, saved_by, saved_at — unique (menu_date, cuisine_id, meal_type) |
| `mess_daily_menu_items`   | menu_id, item_id, qty, sort_order                                     |
| `salesvoucher` (+ mess fields) | voucher_no, date, time, customer_id, cuisine_id, meal_type, token_no, total = 0.00, override_by, cancelled |
| `salesvoucher` details    | item_id, qty, rate = 0.00                                             |
