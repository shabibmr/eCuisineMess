# Mess Module – Mock UI Reference & Demo Guide

A fully interactive, high-fidelity static HTML5/CSS3/JavaScript mock application replicating the complete Mess Billing & Canteen Management suite. Designed for zero-compilation offline operation (`file://` protocol compatible) or any static web server.

---

## 1. Quick Start

### Option A: Direct Browser File Launch (Zero Install)
Double click `mock-ui/index.html` or open it directly in Google Chrome, Microsoft Edge, Mozilla Firefox, or Apple Safari:
```
file:///D:/QtWorkspace/DIT/DITUAE/counter/Mess_Module/mock-ui/index.html
```

### Option B: Local Static Server (Optional)
If you prefer running via HTTP:
```bash
# Using Python 3:
cd mock-ui
python -m http.server 8080

# Or using Node.js:
npx serve mock-ui
```
Then navigate to `http://localhost:8080`.

---

## 2. Design System & Theme Switcher

The application features three distinct visual skins across both light and dark modes:

1. **Flat (Default)**: Modern, crisp Apple Human Interface Guidelines aesthetic with clean borders and subtle neutral fills.
2. **Clay**: Soft, tactile neumorphic 3D surfaces with physical depth and convex pill buttons.
3. **Glass**: Luminous glassmorphic interface with vibrant translucent backdrops and vivid meal-colored ambient glow pools.

### Theme Controls:
- **Skin Switcher**: Toggle Flat / Clay / Glass directly from the topbar segmented control, or press <kbd>Ctrl+Shift+T</kbd> to cycle skins.
- **Dark/Light Mode**: Click the sun/moon icon in the topbar or press <kbd>Ctrl+Shift+M</kbd>. Long-press the icon or right-click to restore system automatic mode.
- **Audio Cues**: Click the volume icon in the topbar to mute/unmute audio beeps (counter tap success chime, error warning beep, and print cue).

---

## 3. Keyboard Map

| Key Combo | Scope | Action |
|---|---|---|
| <kbd>Ctrl+K</kbd> | Global | Open Global Command Palette (search screens, records, actions) |
| <kbd>Ctrl+Shift+D</kbd> | Global | Open / Close Demo Panel (Scenario taps, clock override, role switcher) |
| <kbd>Ctrl+Shift+T</kbd> | Global | Cycle Skin (Flat → Clay → Glass) |
| <kbd>Ctrl+Shift+M</kbd> | Global | Toggle Dark / Light mode |
| <kbd>?</kbd> | Global | Open Keyboard Shortcuts Help Dialog |
| <kbd>F10</kbd> | Counter | Save Bill & Print Token Slip (with feed animation) |
| <kbd>Esc</kbd> | Counter / Global | Clear Counter invoice / Close open modals & drawers |
| <kbd>F8</kbd> | Counter | Request Supervisor Override |
| <kbd>Ctrl+Shift+L</kbd> | Counter | Safely Exit / Leave Counter Kiosk |
| <kbd>Alt+1 … 9</kbd> | Global | Jump to navigation item by index |
| <kbd>/</kbd> | Lists & Grids | Focus search input field |
| <kbd>Ctrl+Enter</kbd> | Reports / Menu | Generate Report / Add all mapped items |
| <kbd>Ctrl+P</kbd> | Global | Print current view / report in A4 landscape format |

---

## 4. Guided Client Demo Script

### Step 1: Dashboard Overview (`#/`)
1. Observe the **Meal Timeline** at the top displaying 06:00–22:30 meal windows with the live time marker.
2. Review the **Menu Readiness Grid**: notice active cuisines and their Breakfast, Lunch, and Dinner readiness status.
3. Review **Served Today** KPIs and quick shortcut tiles.

### Step 2: Masters Management
1. Navigate to **Items** (`#/items`):
   - Search for `Idli` or `Biryani`. Notice the Category filter and Unit badges.
   - Click `New Item` or double-click a row to open the editor.
   - Notice referential delete protection: attempting to delete an item used in active bills shows the "Mark Inactive instead" protection dialog.
2. Navigate to **Cuisines** (`#/cuisines`):
   - Open `South Indian` or `Arabic`.
   - Experience the **Dual-Pane Item Mapping**: search items, drag & drop handles, and double-click to move items between Available and Mapped lists.
   - Notice unmap protection: removing an item currently scheduled on upcoming daily menus triggers an alert preventing accidental unmapping.
3. Navigate to **Members** (`#/customers`):
   - Notice masked RFID numbers, status badges, and Days Left counters (with danger highlight for expired cards).
   - Edit a member to test the **RFID Capture Widget** (15s timeout ring and duplicate RFID validation).

### Step 3: Operations & Daily Menus
1. Navigate to **Meal Time Settings** (`#/settings/meal-times`):
   - Edit From/To times. Notice instant overlap validation highlighting conflicting rows.
2. Navigate to **Daily Menu Editor** (`#/menu`):
   - Switch between cuisines on the left and meal tabs (Breakfast / Lunch / Dinner).
   - Notice bill lock: meals with issued tokens display `🔒 Locked` to prevent menu tampering.
   - Test "Copy Lunch to other cuisines…" and "Add All Mapped".

### Step 4: Mess Billing Counter (`#/counter`)
1. Press <kbd>Ctrl+Shift+D</kbd> to ensure the **Demo Panel** is visible.
2. Under "Tap Scenario Cards", click **"Valid Member (Rahul K)"**:
   - The reader chimes, resolves the member, loads the member photo/avatar, and generates the entitlement invoice at `0.00`.
3. Press <kbd>F10</kbd> (or click **Save & Print Token**):
   - Observe the thermal token slip slide out from the printer slot.
   - The token sequence increments (e.g., `L-0042`), counter stat increments, and screen smoothly resets for the next diner.
4. Test Validations:
   - Click **"Already Served"**: produces a full-width danger banner and audio error beep stating `"Already served Lunch at 13:05 (L-0151)"`.
   - Click **Supervisor Override** (password `1234`): authorizes issuing the token and records the supervisor on the bill.
   - Test **"Expired Card"**, **"Inactive Card"**, and **"Unregistered RFID"** scenario cards.

### Step 5: Bill Register & Cancellations (`#/bills`)
1. View issued tokens in the Tabulator grid.
2. Click **View (Eye icon)** to inspect the bill voucher sheet.
3. Click **Reprint (Printer icon)**: opens thermal preview with `DUPLICATE` watermark.
4. Click **Cancel Bill (Ban icon)**: requires supervisor password `1234` and cancellation reason. Cancelled bills are struck through in ink-2 and immediately excluded from all reports.

### Step 6: Analytical Reports
1. **Members Register** (`#/reports/members`): filter by expiring in N days, view days left, and export.
2. **Cuisine × Meal Headcount** (`#/reports/headcount`):
   - Matrix breakdown with meal-soft heat tints.
   - Toggle **Group by Date** for day-by-day breakdowns.
   - Click any cell to open the **2-level drill-down drawer** (Level 1: Token list, Level 2: Voucher slip with reprint).
3. **Item-wise Movement** (`#/reports/items`):
   - Aggregate consumed quantities across B, L, D.
   - Click an item to view the date-wise breakdown and **ApexCharts stacked bar chart**.
4. **Customer-wise Attendance** (`#/reports/attendance`):
   - **Summary View**: meal counts, days in period, days absent, and absentee filter.
   - **Calendar Grid Detail View**: sticky column grid with B, L, D circular colored pips and keyboard arrow navigation.
5. **Time-based Report** (`#/reports/time`):
   - 15/30/60 minute intervals.
   - Automatic identification and annotation of **Peak Rush Hours**.
   - Hourly-by-Date heat map with shaded meal window bands.

---

## 5. CSV Export Compliance

As required by corporate integration standards, all CSV exports (Bill Register, Members, Headcount, Item Movement, Attendance, and Time-based reports) strictly use `'|'` (pipe) as the delimiter.

---

## 6. Data Reset & Integrity

- **Deterministic Seed**: Generates ~4,500 bills, 25 members, 6 cuisines, and 34 daily menus upon first launch.
- **Resetting Mock Data**: Open the Demo Panel (<kbd>Ctrl+Shift+D</kbd>) and click **"Reset Seed Data"**, or run in the browser console:
  ```js
  Mess.persist.reset();
  ```
