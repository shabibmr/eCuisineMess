# 05 — Screens & UX Spec

Behavioural detail for each screen lives in `Mess_Screens_Specification.md` and in the working mock (`mock-ui/js/screens/*.js`). This doc is the **index and mapping**: spec screen → mock-ui route → Flutter feature/route → API → status. Apply the two overrides: **no codes, UUID ids**.

## 1. Screen map

Flutter route names are final (GoRouter, see [front-end routing](../ecuisine_mess/docs/routing-go-router.md)). `Feature` = folder under `ecuisine_mess/lib/features/`.

| # | Screen (spec) | mock-ui route / file | Flutter route | Feature | Min. role | Live stack today |
|---|---|---|---|---|---|---|
| — | Login | — | `/login` | `auth` | public | ✅ (Provider) |
| — | Home / Dashboard | `#/` `home.js` | `/` | `dashboard` | counter | ⬜ |
| 1–3 | Item List / Editor / Search | `#/items` `item-list.js`, `item-editor.js` | `/items`, `/items/new`, `/items/:id` | `items` | supervisor (view) / admin (edit) | ⬜ (items read-only via API) |
| — | Item Categories (live-stack addition) | — | `/item-categories` | `item_categories` | admin | ✅ (FE-0 BLoC + GoRouter) |
| 4–6 | Cuisine List / Editor (dual-pane mapping) / Search | `#/cuisines` `cuisine-list.js`, `cuisine-editor.js` | `/cuisines`, `/cuisines/new`, `/cuisines/:id` | `cuisines` | admin | ⚠ list+create only, no mapping UI |
| 7–9 | Customer (Member) List / Editor / Search | `#/customers` `customer-list.js`, `customer-editor.js` | `/members`, `/members/new`, `/members/:id` | `members` | admin | ⚠ list+create |
| 10 | Meal Time Settings (**per cuisine**: cuisine selector → 3 rows B/L/D; optional "Apply to all cuisines") | `#/settings/meal-times` | `/settings/meal-times` | `meal_times` | admin | ⬜ |
| 11 | Daily Menu Editor | `#/menu` `menu-editor.js` | `/menu` (`?date=`) | `daily_menu` | admin (edit) / all (view) | ⬜ |
| 12 | Daily Menu History | `menu-history.js` | `/menu/history` | `daily_menu` | all | ⬜ |
| 13 | **Mess Billing (RFID Counter)** | `#/counter` `counter.js` | `/counter` | `counter` | counter | ✅ core flow |
| 14 | Token (KOT) print layout | `token-preview.js` | dialog (`TokenSlip`) | `counter` + shared | — | ✅ preview |
| 15 | Bill Register | `#/bills` `bill-register.js` | `/bills`, `/bills/:id` | `bills` | counter (view) / supervisor (cancel) | ⚠ list |
| 16 | Members Register report | `#/reports/members` | `/reports/members` | `reports` | supervisor | ⬜ |
| 17 | Cuisine × Meal Headcount | `#/reports/headcount` | `/reports/headcount` | `reports` | supervisor | ⚠ basic |
| 18 | Item-wise Movement | `#/reports/items` | `/reports/items` | `reports` | supervisor | ⬜ |
| 19 | Customer-wise Attendance | `#/reports/attendance` | `/reports/attendance` | `reports` | supervisor | ⚠ basic |
| 20 | Time-based Report | `#/reports/time-based` | `/reports/time-based` | `reports` | supervisor | ⬜ |
| — | Server settings (API URL) | — | dialog | `settings` | public | ✅ |
| — | Styleguide / Widget gallery | `styleguide.js`, `widget-gallery.js` | `/dev/gallery` (debug builds only) | `shared` | dev | ⬜ |

Navigation rail (order): Home · Counter · Bills · Members · Cuisines · Items · Item Categories · Menu · Meal Times · Reports ▸ (5) · Settings. Items the current role cannot access are hidden, and route guards redirect on direct URL.

## 2. Shared UX patterns (from the spec)

### List screens (Items, Cuisines, Members, Item Categories)
- Toolbar: **New · Edit · Delete · Refresh · Export**. Search-as-you-type + **Show inactive** checkbox. Sortable table. Double-click / Enter → editor.
- Delete blocked when referenced → dialog offering **Mark inactive**.

### Editor screens
- Same page for create/edit (title `New …` / `Edit …`). **Save · Save & New · Cancel**. Inline validation; Save disabled until required fields valid. Unsaved-changes guard: Save / Discard / Cancel.

### Search pickers (Item, Cuisine, Member)
- Type-ahead, contains-match, case-insensitive, active only by default. ↑/↓/Enter/Esc. **F2** opens the full list in pick mode. Optional **+ New** row.
- Match fields (no codes): Item → name; Cuisine → name; Member → name, **RFID**, phone. A card tapped while a Member picker is focused selects that member.
- **Item editor:** Category and **UOM** are drop-downs fed by `GET /item-categories` and `GET /uoms` (UOMs are a seed-only master — no UOM editor screen). Both are required by the API. The spec's "Default Qty" lives on the cuisine mapping, not on the item.
- Row text: `Name (Unit)`, `Name`, `Name – Cuisine – Valid To`.

### Report frame
- Filter bar (From/To, Cuisine, Meal, + report-specific) → **Generate · Print · Export (CSV)**. Sortable grid with totals. Cancelled bills excluded. Drill-down drawers (token list → voucher).

## 3. Counter screen — the critical screen

Layout (kiosk, landscape): **header** (title · current meal + window · live clock; once a member is tapped the window shown is **that member's cuisine's** window) → **RFID input** (always focused) → **member card** | **invoice grid** → **action bar** (Save & Print F10 · Clear Esc · Supervisor F8 · Last token).

Behaviour that must hold:

1. RFID field **auto-regains focus** after every action, dialog close and route return; hardware reader types digits then `Enter`.
2. Tap → `POST /counter/tap` → render result. **Errors are large full-width banners with an error beep; invoice stays empty.**
3. New tap before Save **replaces** the current invoice.
4. Lines are read-only. Supervisor Override (F8) can authorise `ALREADY_SERVED`.
5. F10 → issue token → slide-out slip preview → print → clear → focus RFID. Last token shown.
6. Today strip: `B ✔ L — D —` for the tapped member.
7. No client-side clock authority: header clock is cosmetic; the server decides the meal.
8. Leaving the counter is `Ctrl+Shift+L` (kiosk-safe exit).

Slip (58/80 mm): company, "MESS TOKEN", token + meal, date/time, name, cuisine, items × qty, counter + user. **DUPLICATE** watermark on reprint. (No member code line.)

## 4. Keyboard map

| Key | Scope | Action |
|---|---|---|
| `Ctrl+K` | Global | Command palette (screens, records, actions) |
| `Alt+1…9` | Global | Jump to nav item |
| `/` | Lists | Focus search |
| `F2` | Pickers | Open full list in pick mode |
| `F10` | Counter | Save & print token |
| `Esc` | Counter/global | Clear invoice / close dialog |
| `F8` | Counter | Supervisor override |
| `Ctrl+Shift+L` | Counter | Exit counter |
| `Ctrl+Enter` | Reports / Menu | Generate / Add all mapped |
| `Ctrl+P` | Global | Print current view |
| `Ctrl+Shift+M` | Global | Light/Dark |
| `Ctrl+Shift+T` | Global | Cycle skin *(optional — see below)* |
| `Ctrl+Shift+D` | Global | Demo panel *(debug builds only)* |

Implemented in Flutter with `Shortcuts` + `Actions` + `CallbackShortcuts`, declared centrally in `core/shortcuts/`.

## 5. Visual design

The mock offers three skins (Flat default, Clay, Glass) × light/dark. **Production target: Flat, light + dark.** Clay/Glass are optional (see [08](08-gap-analysis-roadmap.md) Q4). Design tokens (colours, meal colours, spacing, radius, type scale) come from `mock-ui/css/base` and are re-expressed as a `ThemeExtension` in the Flutter app ([theming](../ecuisine_mess/docs/theming-and-design-tokens.md)).

Meal colour semantics (mock): Breakfast = sunrise/amber, Lunch = sun/blue-green, Dinner = moon/indigo. Icons: Lucide in the mock → Material Symbols equivalents in Flutter (`sunrise→wb_twilight`, `sun→light_mode`, `moon-star→nights_stay`).

Arabic-capable font stack required (cuisine names/items may be Arabic); the app must support RTL text inside LTR layout.

## 6. Accessibility & kiosk

- Min touch target 44 px; focus rings visible; every icon-only button has a tooltip/semantics label.
- Errors never colour-only (icon + text); beeps are optional/mutable.
- Kiosk: no accidental navigation away from `/counter` for role `counter` (nav rail hidden, exit via shortcut).
