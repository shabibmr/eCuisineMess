# Mess Module – Client Handover Package & Technical Specification Guide

| Metadata | Details |
|---|---|
| **Product** | Mess Module (Staff Canteen & Catering Management Suite) |
| **Artifact** | Client Walkthrough Package, Spec Synchronization & Handover Guide |
| **Mock UI Location** | `D:\QtWorkspace\DIT\DITUAE\counter\Mess_Module\mock-ui\` |
| **Specifications Referenced** | `Mess_Modules.md`, `Mess_Screens_Specification.md`, `Mess_MockUI_Implementation_Plan.md` |
| **Task Register Status** | 99 / 99 Tasks Completed (100% — Milestones M0 through M7) |
| **Target Runtime** | Zero-compilation static app; offline `file://` protocol or static HTTP server |
| **Target Implementation** | Qt 6 / C++ Desktop Suite or Web/Cloud Microservices Architecture |
| **Release Date** | October 2026 |

---

## 1. Executive Summary

The **Mess Module Mock UI** is a production-grade, interactive, full-fidelity prototype developed to validate all visual layouts, operator ergonomics, fast-paced counter workflows, and business intelligence reporting with stakeholders and clients before core backend and Qt/C++ desktop development commences.

### Key Milestones Delivered
1. **100% Specification Parity**: All 20 functional screens and reusable widgets defined in `Mess_Screens_Specification.md` (derived from `Mess_Modules.md` sections A through E) have been fully engineered, styled, and validated.
2. **Zero-Dependency Offline Architecture**: The application runs directly off local disk via double-clicking `index.html` (`file://` protocol) in modern browsers (Chrome, Edge, Firefox, Safari) with zero npm build steps, zero external CDN calls, and all vendor dependencies locally pinned and archived in `vendor/`.
3. **Multi-Skin Design System**: Three distinct visual paradigms (**Flat Apple HIG**, **Clay 3D Neumorphic**, and **Glass Frosted Luminance**) available across both Light and Dark modes (plus OS Auto sync), with WCAG 2.1 AA compliant contrast ratios across all 132 UI variants.
4. **Deterministic Simulation Seed**: Mulberry32 PRNG seed generates ~4,500 historical bills across 34 days, 64 members, 7 cuisines, 48 food items, and complete meal schedules. This allows clients and testers to immediately experience realistic aggregations, rush-hour peak distributions, and attendance matrices without manual data entry.
5. **Interactive Edge-Case Simulator**: A docked Demo Panel (<kbd>Ctrl+Shift+D</kbd>) enables instant simulation of RFID taps (valid, duplicate, expired, inactive, already served, unmapped), time-travel clock manipulation across meal windows, and role privilege switching.

---

## 2. Feature Matrix Mapped to Specifications

This matrix validates parity between the high-level business requirements (`Mess_Modules.md`), the screen-level technical requirements (`Mess_Screens_Specification.md`), the implementation plan (`Mess_MockUI_Implementation_Plan.md`), and the delivered codebase in `mock-ui/`.

| Screen / Component | Spec Ref | Plan Ref | Mock UI Route / Component | Implementation Status | Enhancements Introduced |
|---|---|---|---|---|---|
| **Executive Dashboard** | Extra | P§10 Home | `#/` (`js/screens/home.js`) | **Complete (100%)** | Added live 24h meal timeline, real-time meal readiness grid with direct deep links, served-today KPI counters, and quick navigation shortcut cards. |
| **Item List** | S§1, Mod B.1 | P§10.1 | `#/items` (`js/screens/item-list.js`) | **Complete (100%)** | Category filtering, unit badges, active/inactive toggles, referential delete blocking modal with reference counts (`refsOf`). |
| **Item Editor** | S§2, Mod B.1 | P§10.2 | `#/items/new`, `#/items/:id` (`js/screens/item-editor.js`) | **Complete (100%)** | Auto-code generation (`I-00XX`), unit chips, default quantity stepper, read-only mapped cuisines chip deck linking to cuisines. |
| **Item Search Widget** | S§3, Common | P§9 | `SearchPicker.createItemPicker` (`js/components/search-picker.js`) | **Complete (100%)** | Fuse.js fuzzy contains-match, keyboard navigation (↑/↓/Enter/Esc), F2 picker modal dialog, and optional cuisine-scoped filtering (`setCuisine(id)`). |
| **Cuisine List** | S§4, Mod B.2 | P§10.4 | `#/cuisines` (`js/screens/cuisine-list.js`) | **Complete (100%)** | Dynamic count aggregation of mapped items and active registered diners, status chips, delete blocking on referenced cuisines. |
| **Cuisine Editor & Mapping** | S§5, Mod B.2 | P§10.5 | `#/cuisines/new`, `#/cuisines/:id` (`js/screens/cuisine-editor.js`) | **Complete (100%)** | Interactive dual-pane selector (`dual-pane.js`) with drag & drop handles, SortableJS, AutoAnimate transitions, unmap protection veto hook for items scheduled on future menus, and "Copy mapping from cuisine". |
| **Cuisine Search Widget** | S§6, Common | P§9 | `SearchPicker.createCuisinePicker` (`js/components/search-picker.js`) | **Complete (100%)** | Instant cuisine lookup by code or title with active-only enforcement and F2 grid picker dialog. |
| **Member List** | S§7, Mod A | P§10.7 | `#/customers` (`js/screens/customer-list.js`) | **Complete (100%)** | Masked RFID numbers (`••••••2398`), Valid To expiry warning chips (red for expired, amber for ≤7 days), cuisine badge filters, member photo/initials avatars. |
| **Member Registration Editor** | S§8, Mod A | P§10.8 | `#/customers/new`, `#/customers/:id` (`js/screens/customer-editor.js`) | **Complete (100%)** | Live RFID capture widget with 15s listening ring, duplicate RFID detection displaying conflicting member names, auto-member code generation (`M-00XX`), attendance history mini-strip. |
| **Member Search Widget** | S§9, Common | P§9 | `SearchPicker.createCustomerPicker` (`js/components/search-picker.js`) | **Complete (100%)** | Multi-attribute match (Code, Name, Phone, RFID), direct card tap listener, status chips, and F2 modal view. |
| **Meal Time Settings** | S§10, Mod D.1 | P§10.10 | `#/settings/meal-times` (`js/screens/meal-time-settings.js`) | **Complete (100%)** | Meal window definitions (Breakfast, Lunch, Dinner), instant time overlap validator highlighting conflicting rows, live visual preview bar, immediate clock sync. |
| **Daily Menu Editor** | S§11, Mod C | P§10.11 | `#/menu` (`js/screens/menu-editor.js`) | **Complete (100%)** | Date navigator with date picker, cuisine status tree (✓ Complete, ◐ Partial, ○ Empty), meal tabs with counts, inline item picker filtered to cuisine-mapped items, "Add All Mapped", copy from date, copy meal to other cuisines, bill-lock protection (`🔒 Locked`) for meals with issued tokens. |
| **Daily Menu History** | S§12, Mod C | P§10.12 | `#/menu-history` (`js/screens/menu-history.js`) | **Complete (100%)** | 30-day historical log, read-only layout view with watermark banner, copy historical menu to future date, thermal print layout. |
| **Mess Counter Kiosk** | S§13, Mod D | P§10.13 | `#/counter` (`js/screens/counter.js`) | **Complete (100%)** | High-contrast full-screen kiosk layout, persistent RFID input focus, automatic diner resolution, entitlement invoice populated at 0.00, 6 exact validation rules with audio error cues, supervisor override modal (password `1234`), F10 save & print, animated token feed. |
| **Token Slip Print Layout** | S§14, Mod D.6 | P§10.14 | `#/token-preview`, `js/components/token-slip.js` | **Complete (100%)** | Strict 58mm and 80mm thermal receipt formats, monochrome high-contrast print stylesheet (`@page`), sequential daily token numbers (`B-0001`, `L-0001`), duplicate watermark banner for reprints. |
| **Mess Bill Register** | S§15, Mod D.7 | P§10.15 | `#/bills` (`js/screens/bill-register.js`) | **Complete (100%)** | Date range, meal, cuisine, and customer filters; Tabulator virtualized table; voucher detail modal sheet; instant thermal reprint; supervisor bill cancellation with mandatory reason. |
| **Members Register Report** | S§16, Mod E.1 | P§10.16 | `#/reports/members` (`js/screens/report-members.js`) | **Complete (100%)** | Expiry status filter (Expiring in 7/15/30 days, Expired, Active), days remaining calculation, cuisine breakdown KPIs, pipe-delimited CSV, XLSX, and PDF exports. |
| **Cuisine × Meal Headcount** | S§17, Mod E.2 | P§10.17 | `#/reports/headcount` (`js/screens/report-headcount.js`) | **Complete (100%)** | Matrix grid with meal-soft chromatic heat tints, row and column totals, optional "Group by Date" view, 2-level drill-down drawer opening token roster and voucher slip. |
| **Item-wise Movement Report** | S§18, Mod E.3 | P§10.18 | `#/reports/items` (`js/screens/report-items.js`) | **Complete (100%)** | Aggregates item consumption across B, L, D; grouping by cuisine and date; dynamic menu line derivation; interactive ApexCharts stacked bar breakdown in drill-down drawer. |
| **Customer Attendance Report** | S§19, Mod E.4 | P§10.19 | `#/reports/attendance` (`js/screens/report-attendance.js`) | **Complete (100%)** | **Summary View** (days present, absent, total meals, absentee filter) and **Calendar Grid View** (dates as columns, circular B/L/D meal pips, keyboard arrow cell traversal, drill-down to member tokens). |
| **Time-based Rush Report** | S§20, Mod E.5 | P§10.20 | `#/reports/time-based` (`js/screens/report-time-based.js`) | **Complete (100%)** | 15/30/60 minute intervals, automatic peak rush hour identification, hourly-by-date heatmap with shaded meal window bands, summary KPI strip (first/last token, peak slot, average). |
| **Global Command Palette** | Extra | P§9 | `Ctrl+K` (`js/components/command-palette.js`) | **Complete (100%)** | Quick navigation to any screen, lookup of items/members/cuisines, instant skin switching, theme mode toggling, audio mute toggle, data reset. |
| **Demo Scenario Panel** | Extra | P§9 | `Ctrl+Shift+D` (`js/components/demo-panel.js`) | **Complete (100%)** | 8 deterministic scenario cards, virtual clock override across meal windows, on-the-fly role switching, seed data reset button. |
| **Widget Gallery** | Extra | P§10 Extras | `#/widgets` (`js/screens/widget-gallery.js`) | **Complete (100%)** | Live interactive sandbox demonstrating all picker variants, programmatic API triggers, and real-time event logging. |
| **Design Styleguide** | Extra | P§10 Extras | `#/styleguide` (`js/screens/styleguide.js`) | **Complete (100%)** | Comprehensive visual catalog of typography scale, semantic tokens, buttons, form controls, badges, dialogs, charts, and sample grids. |

---

## 3. Architectural Decisions & High-Impact Enhancements

During the design and implementation of the Mock UI, several architectural enhancements were introduced to elevate user experience, ensure rock-solid simulation fidelity, and optimize memory performance. Backend and Qt engineers should review these decisions:

### 3.1 Dynamic Menu Line Derivation for Bills
- **The Problem**: In a staff mess operation serving 4,500+ meals monthly, storing full line-item details for every 0.00 bill in client-side storage would rapidly exhaust browser `localStorage` (over 20,000 array objects) and degrade report computation speed.
- **The Solution**: The mock implements a dual-mode storage pattern (`Mess.reportHelpers.getDerivedItemLines` in `js/components/report-frame.js`):
  1. If a bill was issued via standard entitlement (no lines modified), its line items are dynamically reconstructed on the fly by joining `(bill.date, bill.cuisineId, bill.meal)` against `mess_daily_menu_items` and `mess_items`.
  2. If an item line was manually removed or adjusted via **Supervisor Override**, the customized array is serialized directly onto `bill.items`.
- **Backend Architecture Note**: In the relational database, `salesvoucher_details` lines should be automatically populated via a single database transaction or trigger at the moment of bill generation, copying records from `mess_daily_menu_items`. This preserves immutable historical snapshots even if menu masters are modified retrospectively.

### 3.2 AutoAnimate UMD Integration in Dual-Pane Mapping
- **The Innovation**: In `mock-ui/js/components/dual-pane.js`, the dual-pane item mapping component integrates `@formkit/auto-animate` via UMD alongside `SortableJS`.
- **User Impact**: When operators transfer items between "Available Items" and "Mapped Items" (via double-click or arrow controls) or when items snap back due to unmapping validation vetoes, the DOM elements smoothly transition with spring physics. This provides a tactile native-app feel without introducing heavy JavaScript frameworks.
- **Unmap Veto Hook (`beforeRemove`)**: If an operator attempts to remove an item that is currently scheduled on today's or future daily menus, the hook intercepts the move, performs an asynchronous validation against upcoming menus, displays a warning dialog detailing the conflicting dates, and snaps the item back to the mapped pane.

### 3.3 Demo Panel Scenario Injector (`Ctrl+Shift+D`)
- **The Innovation**: Built directly into the shell (`js/components/demo-panel.js`) to provide zero-hardware client demonstrations.
- **Features**:
  - **8 One-Click Scenario Cards**:
    1. *Rahul K (M-0042)*: Happy path valid South Indian member.
    2. *Maria (M-0007)*: Triggers the `"Already served Lunch at 13:05 (L-0151)"` validation.
    3. *Imran (M-0013)*: Triggers `"Membership expired on 25-09-2026"`.
    4. *Sunil (M-0021)*: Valid member expiring in 4 days (amber warning).
    5. *Ahmed (M-0030)*: Triggers `"Membership inactive"`.
    6. *Arjun (M-0055)*: Triggers `"Menu not set for North Indian – Lunch"`.
    7. *Unregistered Card (`0009999999`)*: Triggers `"Card not registered"`.
    8. *Unassigned Capture Card (`0004777001`)*: Used during Member Registration to capture a clean card.
  - **Virtual Time-Travel Clock**: Overrides the internal system clock to Breakfast (`08:00`), Lunch (`13:00`), Dinner (`20:00`), or Closed (`16:00`), instantly re-evaluating meal windows and updating the UI.
  - **Instant Role Switcher**: Switches between Admin, Supervisor, and Counter Staff permissions.

### 3.4 Global Command Palette (`Ctrl+K`)
- **The Innovation**: An accessible, keyboard-first modal overlay (`js/components/command-palette.js`) powered by Fuse.js.
- **Capabilities**:
  - Direct fuzzy search across all 20+ routes and views.
  - Live query across masters: typing a customer name, RFID digits, or food item instantly displays the record and opens its editor upon pressing <kbd>Enter</kbd>.
  - Quick action commands: change skin (Flat, Clay, Glass), toggle theme mode, mute audio, or reset data.

### 3.5 Multi-Skin Engine & Meal-Aware Ambient Glass Pools
- **Semantic Token System**: Built upon pure CSS Custom Properties (`tokens.css`), establishing strict separation between chromatic meal colors and surface materials.
  - **Breakfast**: Saffron (`--meal-b: #E08A1E`, Dark: `#F2AE55`, Icon: `sunrise`)
  - **Lunch**: Curry Leaf (`--meal-l: #1F9D6B`, Dark: `#45C893`, Icon: `sun`)
  - **Dinner**: Night Violet (`--meal-d: #6A4BD1`, Dark: `#A48BFF`, Icon: `moon-star`)
  - **Stop/Danger**: Red (`--danger: #D7263D`, Dark: `#FF5A6E`, Icon: `octagon-alert`)
- **Ambient Glass Glow Pools**: In the **Glass** skin, three blurred chromatic light pools sit fixed in the background (`.glass-pool--b`, `.glass-pool--l`, `.glass-pool--d`). As the system shifts between Breakfast, Lunch, and Dinner, the active meal pool dynamically scales up (125%) and brightens (70% opacity) based on the root attribute `data-meal="B|L|D"`.
- **Dense Content Readability**: High-density elements (Tabulator grids, customer invoices, forms) automatically adopt `--surface-strong` (82–85% opacity with 32px backdrop blur), guaranteeing WCAG text contrast ratios ≥ 4.5:1.

### 3.6 2-Level Drill-Down Drawer Architecture
- **The Problem**: In analytical reporting (Headcount, Attendance, Item Movement), operators need to inspect underlying transaction records without losing their filter context or page position.
- **The Solution**: A unified side-sheet drawer stack (`report-frame.js`):
  - **Level 1**: Clicking any aggregate cell (e.g., Headcount matrix cell for South Indian Lunch = 48 tokens) slides in a Tabulator sub-grid of the 48 individual tokens with timestamps and member names.
  - **Level 2**: Clicking any token row in Level 1 slides in the complete thermal voucher slip representation with a live "Reprint Token" action.
  - **Breadcrumb Navigation**: Displays `Report / South Indian – Lunch / Token L-0042`, allowing single-click back navigation or <kbd>Esc</kbd> dismissal.

### 3.7 Strict Pipe Delimiter (`|`) for CSV Exports
- **Memory Rule Compliance**: In strict compliance with enterprise integration guidelines, all data grid and report CSV exports in the application (`data-grid.js`, `report-frame.js`, and individual report modules) enforce the pipe delimiter `'|'` rather than comma or semicolon. This prevents truncation or misalignment when item descriptions or member names contain commas.

---

## 4. Live Client Walkthrough & Demo Script

Follow this step-by-step presentation script to conduct a smooth, impressive client demonstration.

### Preparation
1. Open Google Chrome or Microsoft Edge.
2. Launch `mock-ui/index.html` (via `file://` or local server).
3. Maximize the browser window (<kbd>F11</kbd> optional for kiosk mode).
4. Verify audio is unmuted (topbar volume icon shows sound waves).
5. Open the Demo Panel by pressing <kbd>Ctrl+Shift+D</kbd> and dock it on the right side of the screen.

---

### Phase 1: Brand Experience & Visual Skins (2 Minutes)
1. **Explain the Philosophy**:
   > *"Notice how the interface immediately conveys time and context. The day's meal is encoded by color: Saffron for Breakfast, Leaf Green for Lunch, and Violet for Dinner. Ink colors handle all standard text, and red is reserved exclusively for errors."*
2. **Cycle Skins**:
   - In the topbar, click through the skin switcher: **Flat** → **Clay** → **Glass** (or press <kbd>Ctrl+Shift+T</kbd>).
   - Point out how **Clay** provides tactile neumorphic inset wells and pill buttons.
   - Point out how **Glass** illuminates the ambient meal light pools in the background.
3. **Toggle Dark Mode**:
   - Click the Moon icon in the topbar (or press <kbd>Ctrl+Shift+M</kbd>).
   - Note that all text contrast remains crisp and exceeds WCAG AA standards.
   - Set the skin back to **Flat Light** for the remainder of the functional demo.

---

### Phase 2: Shift Readiness & Operations Planning (3 Minutes)
1. **Executive Dashboard (`#/`)**:
   - Point to the **Meal Timeline** at the top showing the 24-hour visual distribution of Breakfast (06:00–10:00), Lunch (12:00–15:00), and Dinner (19:00–22:30).
   - Review the **Menu Readiness Grid**: show how operators can spot at a glance which cuisines have complete menus configured for each meal.
2. **Daily Menu Editor (`#/menu`)**:
   - Select date **Today**.
   - Select **South Indian** on the left pane.
   - Click the **Lunch** tab: show the `🔒 Locked` badge.
   - Explain: *"Because tokens have already been issued to workers for Lunch today, the menu is locked to prevent retrospective tampering."*
   - Click the **Dinner** tab: show how items can be added using the inline Item Search Picker.
   - Click **"Add All Mapped"**: demonstrate how all 12 items mapped to South Indian are added in one click with pre-filled default quantities.
3. **Menu History (`#/menu-history`)**:
   - Show the 30-day historical archive.
   - Click **View** on yesterday's menu: demonstrate that historical menus open in a protected read-only view with a watermark banner.

---

### Phase 3: Masters & Dual-Pane Drag Mapping (3 Minutes)
1. **Cuisines & Dual-Pane Item Mapping (`#/cuisines`)**:
   - Open **South Indian** cuisine.
   - Point to the two-pane transfer layout. Search `dosa` in Available Items.
   - Double-click `Masala Dosa`: watch it animate smoothly into Mapped Items via AutoAnimate.
   - Drag an item using its grip handle to reorder the priority.
   - **Show Unmap Protection**: Attempt to remove `Sambar` (which is scheduled on today's lunch).
   - An alert dialog immediately appears: *"Cannot unmap Sambar — it is scheduled on Daily Menus for [Today]. Remove from menu first."* Sambar snaps back safely.
2. **Member Registration & RFID Capture (`#/customers`)**:
   - Click **New Member**.
   - Enter Name: `Farhan Akhtar`. Select Cuisine: `North Indian`.
   - Click the **Capture RFID** button:
     - The listening ring animates with a 15-second countdown.
   - In the Demo Panel (<kbd>Ctrl+Shift+D</kbd>), click **Unassigned Capture Card (`0004777001`)**.
   - The card number captures instantly with an audio confirmation chime.
   - Click **Cancel** to return to the list.

---

### Phase 4: High-Velocity Counter Billing Kiosk (4 Minutes)
*This is the core operational feature of the canteen suite.*

1. **Enter Counter Mode (`#/counter`)**:
   - Point out the kiosk layout: the cursor is automatically trapped in the RFID input.
   - The top banner shows current meal **LUNCH (12:00–15:00)** with real-time served count.
2. **Scenario 1: Happy Path Diner (Rahul K)**:
   - In Demo Panel, click **"M-0042 Rahul K (Happy)"**.
   - **UI Behavior**: Audio chime sounds. Rahul's photo, Member Code (`M-0042`), South Indian cuisine badge, and validity date appear on the left. The invoice on the right populates with today's South Indian lunch menu items at `0.00`.
   - Press <kbd>F10</kbd> (or click **Save & Print Token**).
   - **UI Behavior**: An 80mm thermal token slip (`L-0042`) slides out from the virtual printer slot with an authentic paper-feed animation. A success toast appears, the served counter increments, and the screen resets in under 500ms ready for the next worker.
3. **Scenario 2: Fraud / Double Tap Prevention (Already Served)**:
   - In Demo Panel, click **"M-0007 Maria (Already served)"**.
   - **UI Behavior**: A loud warning beep sounds. A full-width red danger banner flashes:
     > `"Already served Lunch at 13:05 (L-0151)"`
   - No invoice items are loaded.
4. **Scenario 3: Supervisor Override**:
   - With Maria's error on screen, press <kbd>F8</kbd> (or click **Supervisor Override**).
   - Enter password `1234` and reason: `Fingerprint verified, authorized by Camp Manager`.
   - Click **Authorize Override**.
   - **UI Behavior**: The invoice unlocks, allowing issuance. Press <kbd>F10</kbd> to issue the override token.
5. **Scenario 4: Expired Membership**:
   - In Demo Panel, click **"M-0013 Imran (Expired)"**.
   - **UI Behavior**: Danger banner: `"Membership expired on 25-09-2026"`. Issuance is strictly blocked.
6. **Scenario 5: Outside Service Hours**:
   - In Demo Panel under Clock Override, click **Closed (16:00)**.
   - In Demo Panel, click Rahul K.
   - **UI Behavior**: Danger banner: `"No meal service now. Next: Dinner 19:00"`.
   - Click **Reset Clock** in Demo Panel to return to live time.

---

### Phase 5: Bill Register & Audit Controls (2 Minutes)
1. **Navigate to Bills (`#/bills`)**:
   - Filter by meal: **Lunch**.
   - Point out the newly issued tokens at the top of the table.
   - Point out the **Override badge** on Maria's bill, showing supervisor authorization.
2. **Reprint Token**:
   - Click the **Printer icon** on any row.
   - The thermal slip preview opens with a bold **`DUPLICATE`** banner across the header.
3. **Cancel Voucher**:
   - Click the **Ban/Cancel icon** on a bill.
   - Enter supervisor password `1234` and cancellation reason: `Worker reported sick to clinic`.
   - The bill row is immediately struck through. Explain that cancelled vouchers are permanently excised from all analytical reports.

---

### Phase 6: Analytical Intelligence & Drill-Down (4 Minutes)
1. **Cuisine × Meal Headcount Matrix (`#/reports/headcount`)**:
   - Click **Generate**.
   - Point out the cross-tab matrix: Rows = Cuisines, Columns = Breakfast, Lunch, Dinner, and Total.
   - Cells display chromatic heat tints indicating volume.
   - **Demonstrate 2-Level Drill-Down**:
     - Click the **South Indian Lunch** cell.
     - **Level 1 Drawer** slides in from the right showing all individual tokens issued for that cell.
     - Click any token in the drawer:
     - **Level 2 Drawer** slides in showing the exact thermal receipt breakdown and meal items.
     - Click **Close** or press <kbd>Esc</kbd>.
2. **Item-wise Movement Report (`#/reports/items`)**:
   - Filter by Item: `Biryani Rice` or leave as All Items.
   - Click **Generate**.
   - Show total consumed portions across B, L, D.
   - Double-click `Idli`: the drill-down drawer displays an **ApexCharts stacked bar chart** revealing daily consumption trends across the selected date range.
3. **Customer Attendance Calendar Grid (`#/reports/attendance`)**:
   - Switch View from **Summary** to **Calendar Grid**.
   - Point out the sticky header row with dates and sticky left column with member names.
   - Cells display colored circular badges: Saffron **B**, Green **L**, Violet **D**.
   - Use keyboard arrow keys to navigate across the calendar matrix.
4. **Time-Based Peak Rush Analysis (`#/reports/time-based`)**:
   - Set Interval to **15 Minutes**. Click **Generate**.
   - Show the summary cards: **Peak Rush Slot: 12:45–13:00 (142 tokens)**.
   - Point out the hourly-by-date heatmap revealing kitchen bottleneck windows.
5. **CSV Export Verification**:
   - Click **Export** → **Export as CSV**.
   - Open the downloaded CSV file in Notepad: verify that columns are strictly separated by pipe characters (`|`).

---

## 5. Architecture & Extensibility Guide for Backend Developers

This section provides the technical blueprint for the engineering team responsible for building the production Qt 6 / C++ desktop application or Web microservices backend.

### 5.1 Relational Database Schema Blueprint (DDL)

The schema is normalized, enforces referential integrity with foreign key constraints, and incorporates audit logging.

```sql
-- 1. Mess Food Items Master
CREATE TABLE mess_items (
    id VARCHAR(36) PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    unit VARCHAR(20) NOT NULL DEFAULT 'Nos',
    default_qty DECIMAL(8, 2) NOT NULL DEFAULT 1.00,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_mess_items_code ON mess_items(code);
CREATE INDEX idx_mess_items_active ON mess_items(active);

-- 2. Cuisines Master
CREATE TABLE mess_cuisines (
    id VARCHAR(36) PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Cuisine-to-Item Mapping (Many-to-Many)
CREATE TABLE mess_cuisine_items (
    cuisine_id VARCHAR(36) NOT NULL REFERENCES mess_cuisines(id) ON DELETE RESTRICT,
    item_id VARCHAR(36) NOT NULL REFERENCES mess_items(id) ON DELETE RESTRICT,
    sort_order INT DEFAULT 0,
    PRIMARY KEY (cuisine_id, item_id)
);
CREATE INDEX idx_mci_cuisine ON mess_cuisine_items(cuisine_id);
CREATE INDEX idx_mci_item ON mess_cuisine_items(item_id);

-- 4. Members / Diners Master
CREATE TABLE mess_customers (
    id VARCHAR(36) PRIMARY KEY,
    member_code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(30),
    rfid_card_no VARCHAR(50) NOT NULL UNIQUE,
    cuisine_id VARCHAR(36) NOT NULL REFERENCES mess_cuisines(id) ON DELETE RESTRICT,
    valid_from DATE NOT NULL,
    valid_to DATE NOT NULL,
    photo_path VARCHAR(255),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_valid_dates CHECK (valid_to >= valid_from)
);
CREATE INDEX idx_mc_rfid ON mess_customers(rfid_card_no);
CREATE INDEX idx_mc_validity ON mess_customers(valid_from, valid_to);
CREATE INDEX idx_mc_active ON mess_customers(active);

-- 5. Meal Time Operating Windows
CREATE TABLE mess_meal_times (
    meal_type CHAR(1) PRIMARY KEY, -- 'B', 'L', 'D'
    name VARCHAR(30) NOT NULL,
    time_from TIME NOT NULL,
    time_to TIME NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_meal_window CHECK (time_to > time_from)
);

-- 6. Daily Menus Header
CREATE TABLE mess_daily_menu (
    id VARCHAR(36) PRIMARY KEY,
    menu_date DATE NOT NULL,
    cuisine_id VARCHAR(36) NOT NULL REFERENCES mess_cuisines(id) ON DELETE RESTRICT,
    meal_type CHAR(1) NOT NULL REFERENCES mess_meal_times(meal_type),
    saved_by VARCHAR(50) NOT NULL,
    saved_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_daily_menu UNIQUE (menu_date, cuisine_id, meal_type)
);
CREATE INDEX idx_mdm_lookup ON mess_daily_menu(menu_date, cuisine_id, meal_type);

-- 7. Daily Menu Line Items
CREATE TABLE mess_daily_menu_items (
    id VARCHAR(36) PRIMARY KEY,
    menu_id VARCHAR(36) NOT NULL REFERENCES mess_daily_menu(id) ON DELETE CASCADE,
    item_id VARCHAR(36) NOT NULL REFERENCES mess_items(id) ON DELETE RESTRICT,
    qty DECIMAL(8, 2) NOT NULL DEFAULT 1.00,
    sort_order INT DEFAULT 0,
    CONSTRAINT uq_menu_item UNIQUE (menu_id, item_id)
);
CREATE INDEX idx_mdmi_menu ON mess_daily_menu_items(menu_id);

-- 8. Sales Vouchers / Mess Token Header
CREATE TABLE salesvoucher (
    id VARCHAR(36) PRIMARY KEY,
    voucher_no VARCHAR(30) NOT NULL UNIQUE,
    bill_date DATE NOT NULL,
    bill_time TIME NOT NULL,
    customer_id VARCHAR(36) NOT NULL REFERENCES mess_customers(id) ON DELETE RESTRICT,
    cuisine_id VARCHAR(36) NOT NULL REFERENCES mess_cuisines(id) ON DELETE RESTRICT,
    meal_type CHAR(1) NOT NULL REFERENCES mess_meal_times(meal_type),
    token_prefix CHAR(1) NOT NULL,
    token_seq INT NOT NULL,
    token_no VARCHAR(20) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    counter_id VARCHAR(20) DEFAULT 'C1',
    user_id VARCHAR(50) NOT NULL,
    cancelled BOOLEAN NOT NULL DEFAULT FALSE,
    cancel_reason TEXT,
    cancelled_by VARCHAR(50),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    override BOOLEAN NOT NULL DEFAULT FALSE,
    override_reason TEXT,
    override_by VARCHAR(50),
    override_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_token_daily UNIQUE (bill_date, meal_type, token_seq)
);
CREATE INDEX idx_sv_lookup ON salesvoucher(bill_date, meal_type, customer_id);
CREATE INDEX idx_sv_reports ON salesvoucher(bill_date, cuisine_id, meal_type, cancelled);

-- 9. Sales Voucher Line Items (Details)
CREATE TABLE salesvoucher_details (
    id VARCHAR(36) PRIMARY KEY,
    voucher_id VARCHAR(36) NOT NULL REFERENCES salesvoucher(id) ON DELETE CASCADE,
    item_id VARCHAR(36) NOT NULL REFERENCES mess_items(id) ON DELETE RESTRICT,
    qty DECIMAL(8, 2) NOT NULL,
    rate DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    sort_order INT DEFAULT 0
);
CREATE INDEX idx_svd_voucher ON salesvoucher_details(voucher_id);
CREATE INDEX idx_svd_item ON salesvoucher_details(item_id);
```

---

### 5.2 Core Business Logic & State Machines

#### A. Counter Kiosk State Machine (`Qt / C++ QStateMachine` or Event Loop)
```
[ IDLE ] ──────── RFID Scan (Enter) ────────► [ RESOLVING ]
   ▲                                                 │
   │                                                 ▼
[ RESET ] ◄──── Save & Print (F10) ──── [ LOADED / INVOICE ] ── Supervisor Override ──► [ OVERRIDE_AUTH ]
   ▲                                                 │                                          │
   │                                                 ▼                                          │
   └────────── Clear / Timeout (Esc) ◄───────── [ ERROR ] ◄─────────────────────────────────────┘
```

1. **Idle State**: Focus locked to RFID buffer. Keystroke scanner reads string terminated by `CR`/`LF`.
2. **Resolving State**:
   - Query `mess_customers WHERE rfid_card_no = :rfid`.
   - **Validation 1**: If record not found → Error: `"Card not registered"`.
   - **Validation 2**: If `customer.active = FALSE` → Error: `"Membership inactive"`.
   - **Validation 3**: If `current_date NOT BETWEEN valid_from AND valid_to` → Error: `"Membership expired on DD-MM-YYYY"`.
   - **Validation 4**: Check current time against `mess_meal_times`. If outside all windows → Error: `"No meal service now. Next: [NextMeal] [NextTime]"`.
   - **Validation 5**: Query `mess_daily_menu WHERE menu_date = current_date AND cuisine_id = customer.cuisine_id AND meal_type = current_meal`. If not found → Error: `"Menu not set for [CuisineName] – [MealName]"`.
   - **Validation 6**: Query `salesvoucher WHERE bill_date = current_date AND meal_type = current_meal AND customer_id = customer.id AND cancelled = FALSE`. If found → Error: `"Already served [MealName] at HH:MM (Token [TokenNo])"`.
3. **Loaded State**:
   - Display member card, photo, and entitlement invoice.
   - Fetch items from `mess_daily_menu_items` for the identified menu.
   - Populate invoice rows at `rate = 0.00`, `amount = 0.00`.
4. **Saving State**:
   - Execute in an atomic database transaction:
     ```sql
     BEGIN TRANSACTION;
     -- Compute next sequential token for this meal today
     SELECT COALESCE(MAX(token_seq), 0) + 1 INTO :next_seq 
     FROM salesvoucher 
     WHERE bill_date = CURRENT_DATE AND meal_type = :current_meal;

     INSERT INTO salesvoucher (...) VALUES (...);
     INSERT INTO salesvoucher_details (...) SELECT ... FROM mess_daily_menu_items ...;
     COMMIT;
     ```
   - Dispatch thermal print payload to printer queue.
   - Reset UI state to Idle within 300ms.

#### B. Daily Menu Locking Rule
- Daily menus cannot be edited if tokens have already been issued for that date, cuisine, and meal.
- **SQL Guard Check**:
  ```sql
  SELECT COUNT(*) FROM salesvoucher 
  WHERE bill_date = :menu_date AND cuisine_id = :cuisine_id AND meal_type = :meal_type AND cancelled = FALSE;
  ```
  If count > 0, set editor view to `readOnly = TRUE` and display `"Locked – Tokens already issued"`.

---

### 5.3 Hardware Integration Specifications

#### 1. RFID Card Readers (125 kHz EM-Marine / 13.56 MHz Mifare)
- **Interface**: USB HID Keyboard Wedge (Default) or USB Virtual COM (CDC-ACM).
- **Keyboard Wedge Handling**:
  - RFID readers emit digits rapidly (typically <15ms between characters) followed by an `Enter` keystroke.
  - Implement an inter-character timing filter: normal human typing generates 80–250ms intervals; reader bursts occur in <30ms intervals.
  - Automatically redirect burst streams to the RFID resolution handler even if operator focus was inadvertently placed on another widget.

#### 2. Thermal Receipt Printers (58mm / 80mm ESC/POS)
- **Interface**: USB Direct, Network TCP/IP (Port 9100), or Serial RS-232.
- **ESC/POS Command Structure**:
  ```
  [ESC @]                Initialize printer
  [ESC a 1]              Align center
  [ESC ! 0x08]           Bold text
  <COMPANY NAME> \n
  MESS TOKEN \n
  [ESC ! 0x00]           Normal text
  --------------------------------\n
  [ESC a 0]              Align left
  [GS ! 0x11]            Double width & height
  Token : L-0042        LUNCH\n
  [GS ! 0x00]            Normal text
  Date  : 02-10-2026   13:05\n
  Name  : Rahul K (M-0042)\n
  Cuisine: South Indian\n
  --------------------------------\n
  Item                       Qty\n
  --------------------------------\n
  Rice                         1\n
  Sambar                       1\n
  Rasam                        1\n
  Poriyal                      1\n
  --------------------------------\n
  Counter: C1     User: admin\n
  \n\n\n\n
  [GS V 0x41 0x03]       Partial cut
  ```

---

### 5.4 Role-Based Access Control (RBAC) Matrix

| Feature / Action | Counter Staff | Supervisor | Administrator |
|---|:---:|:---:|:---:|
| View Counter Kiosk & Issue Tokens | ✓ | ✓ | ✓ |
| View Bill Register | ✓ (Today only) | ✓ (All dates) | ✓ (All dates) |
| Reprint Token Slip | ✓ (DUPLICATE) | ✓ (DUPLICATE) | ✓ (DUPLICATE) |
| Authorize "Already Served" Override | ✗ | ✓ (Password req.) | ✓ |
| Authorize Line Removal on Invoice | ✗ | ✓ (Password req.) | ✓ |
| Cancel Issued Bill Voucher | ✗ | ✓ (Reason req.) | ✓ (Reason req.) |
| Create / Edit Daily Menus | ✗ | ✓ | ✓ |
| Create / Edit Masters (Items, Cuisines, Members) | ✗ | ✗ | ✓ |
| Modify Meal Time Settings | ✗ | ✗ | ✓ |
| View & Export Analytical Reports | ✗ | ✓ | ✓ |

---

### 5.5 SQL Reporting Query Optimization Recipes

#### Report 1: Cuisine × Meal Headcount Matrix (Pivot)
```sql
SELECT 
    c.id AS cuisine_id,
    c.name AS cuisine_name,
    COUNT(CASE WHEN sv.meal_type = 'B' THEN 1 END) AS breakfast_count,
    COUNT(CASE WHEN sv.meal_type = 'L' THEN 1 END) AS lunch_count,
    COUNT(CASE WHEN sv.meal_type = 'D' THEN 1 END) AS dinner_count,
    COUNT(sv.id) AS total_headcount
FROM mess_cuisines c
LEFT JOIN salesvoucher sv ON c.id = sv.cuisine_id 
    AND sv.bill_date BETWEEN :from_date AND :to_date
    AND sv.cancelled = FALSE
WHERE c.active = TRUE
GROUP BY c.id, c.name
ORDER BY total_headcount DESC;
```

#### Report 2: Item-wise Movement & Consumption
```sql
SELECT 
    i.code AS item_code,
    i.name AS item_name,
    i.unit,
    SUM(CASE WHEN sv.meal_type = 'B' THEN svd.qty ELSE 0 END) AS breakfast_qty,
    SUM(CASE WHEN sv.meal_type = 'L' THEN svd.qty ELSE 0 END) AS lunch_qty,
    SUM(CASE WHEN sv.meal_type = 'D' THEN svd.qty ELSE 0 END) AS dinner_qty,
    SUM(svd.qty) AS total_consumed_qty
FROM mess_items i
JOIN salesvoucher_details svd ON i.id = svd.item_id
JOIN salesvoucher sv ON svd.voucher_id = sv.id
WHERE sv.bill_date BETWEEN :from_date AND :to_date
  AND sv.cancelled = FALSE
GROUP BY i.id, i.code, i.name, i.unit
ORDER BY total_consumed_qty DESC;
```

#### Report 3: 15-Minute Rush-Hour Interval Distribution
```sql
SELECT 
    sv.meal_type,
    TO_CHAR(
        DATE_TRUNC('hour', sv.bill_time) + 
        INTERVAL '15 min' * FLOOR(EXTRACT(MINUTE FROM sv.bill_time) / 15),
        'HH24:MI'
    ) AS time_slot,
    COUNT(sv.id) AS token_count,
    ROUND(COUNT(sv.id) * 100.0 / SUM(COUNT(sv.id)) OVER (PARTITION BY sv.meal_type), 2) AS pct_of_meal
FROM salesvoucher sv
WHERE sv.bill_date BETWEEN :from_date AND :to_date
  AND sv.cancelled = FALSE
GROUP BY sv.meal_type, time_slot
ORDER BY sv.meal_type, time_slot ASC;
```

---

## 6. Verification & Handover Sign-Off

| Verification Item | Specification Standard | Mock UI Validation Result |
|---|---|:---:|
| **Screen Coverage** | 20 Screens & Widgets (`Mess_Screens_Specification.md`) | **100% Verified (20/20 + 4 Extras)** |
| **Milestone Tasks** | 99 Planned Tasks (`Mess_MockUI_Tasks_Register.md`) | **100% Completed (99/99)** |
| **Design Variants** | 22 Views × 3 Skins × 2 Modes = 132 Configurations | **100% Verified in `qa/index.html`** |
| **Accessibility & Contrast** | WCAG 2.1 AA (Text ≥ 4.5:1, UI Elements ≥ 3.0:1) | **PASS (Audited across all 6 themes)** |
| **Data Integrity** | Unique RFID, non-overlapping meal times, menu-bill sync | **PASS (`Mess.integrity.run()`)** |
| **CSV Export Format** | Strict Pipe (`|`) Delimiter compliance | **PASS (All grids & reports verified)** |
| **Offline Operation** | Launch via `file://` protocol with zero network calls | **PASS (All vendor scripts & fonts local)** |

---
*Document prepared and synchronized by the Documentation & Spec Synchronization Specialist.*  
*Ready for immediate client presentation, user sign-off, and engineering handover.*
