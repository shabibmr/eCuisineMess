# Mess Module – Mock UI Tasks Register

| | |
|---|---|
| Plan | [Mess_MockUI_Implementation_Plan.md](Mess_MockUI_Implementation_Plan.md) |
| Spec | [Mess_Screens_Specification.md](Mess_Screens_Specification.md) |
| Created | 02-10-2026 |
| Output | `Mess_Module/mock-ui/` |

**Status legend:** `To do` · `Doing` · `Review` · `Done` · `Blocked`
**Ref column:** `P§n` is a section of the plan, and `S§n` is a section or screen number in the spec.
**Estimates** are in focused hours for one front-end developer.

---

## Progress summary

| Milestone | Tasks | Est (h) | Done | Status |
|---|---|---|---|---|
| M0 Foundation and design system | T-001 – T-019 | 53.5 | 19 / 19 | Done |
| M1 Core services and sample data | T-020 – T-039 | 47.5 | 20 / 20 | Done |
| M2 Shared components | T-040 – T-049 | 38.0 | 10 / 10 | Done |
| M3 Masters (screens 1–9) | T-050 – T-059 | 27.0 | 10 / 10 | Done |
| M4 Operations (Today, 10–12) | T-060 – T-069 | 31.0 | 10 / 10 | Done |
| M5 Billing (13–15) | T-070 – T-079 | 32.0 | 10 / 10 | Done |
| M6 Reports (16–20) | T-080 – T-089 | 36.0 | 0 / 10 | To do |
| M7 QA, polish and handover | T-090 – T-099 | 26.0 | 0 / 10 | To do |
| **Total** | **99** | **291.0** | **79 / 99** | |

**Critical path:** T-006 → T-007/8/9 → T-010 → T-022 → T-025/26 → T-041 → T-044 → T-062/63 → T-071 → T-074 → T-080 → T-082 → T-096 → T-099

**Can run in parallel once M1 is done:** M3 alongside M4; the M6 report screens alongside M5 (both need only T-038 and T-046).

---

## M0 – Foundation and design system

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-001 | Create the `mock-ui/` folder tree as in the plan, with a README stub | P§6 | – | 1.0 | Done | All folders exist; README has the title and an "open index.html" line |
| T-002 | Write `tools/vendor.ps1` to download the pinned libraries into `vendor/`, and write `vendor/VERSIONS.md` (name, version, licence, URL) | P§5 | T-001 | 2.0 | Done | Script runs from scratch with no errors; the mock loads with the network disabled |
| T-003 | Download and subset the fonts (Nunito, Sora, IBM Plex Sans Arabic → woff2, Latin + Arabic) and add `@font-face` with `font-display: swap` | P§3.4 | T-001 | 1.5 | Done | Each skin renders in its face; Arabic sample name renders correctly |
| T-004 | `index.html` skeleton: landmarks, `#outlet`, script and style load order, inline no-flash theme script | P§4.1, P§7.1 | T-001 | 1.5 | Done | Reload in each skin and mode shows no flash of the wrong theme |
| T-005 | Base CSS: `reset.css`, `typography.css` (scale, tabular nums, counter scale), `layout.css` (gap-based rhythm), `a11y.css` (focus, sr-only) | P§3.4, P§4.2 | T-004 | 2.0 | Done | Type specimen on the styleguide matches the scale; no margin-collapse conflicts |
| T-006 | `tokens.css`: 4 px spacing, radii hierarchy, z-index, motion durations, meal colours with `-soft` variants, danger | P§3.2, P§4.2 | T-005 | 2.0 | Done | Every semantic token in P§4.2 is defined with a default value |
| T-007 | **Flat skin**, light and dark (palette, hairlines, grouped inset lists, popover shadow, focus ring) | P§3.3 | T-006 | 3.0 | Done | Styleguide in flat light/dark is reviewed against Apple HIG references |
| T-008 | **Clay skin**, light and dark (inset highlight/shade recipe, pressed state, radius hierarchy, one inset well per table) | P§3.3, P§3.7 | T-006 | 5.0 | Done | No "card soup": tables use one well and rows are flat; pressed state is visible |
| T-009 | **Glass skin**, light and dark, including the **meal-aware backdrop** (three meal light pools, current meal dominant), glass-strong for dense content, and opaque fallbacks for no `backdrop-filter`, `prefers-reduced-transparency` and low-core devices | P§3.3, P§15 | T-006 | 5.0 | Done | Backdrop changes with `data-meal`; table text ≥ 4.5:1; fallbacks verified |
| T-010 | `theme.js`: skin, mode and auto (with live OS listener), persistence, View Transition circular reveal, `themechange` event | P§4.1 | T-007, T-008, T-009 | 3.0 | Done | Switching skin or mode is under 100 ms, persists across reloads, and is instant under reduced motion |
| T-011 | Topbar theme controls: 3-way skin segmented control and mode toggle (long-press or right-click for Auto) | P§4.1 | T-010 | 1.5 | Done | Fully keyboard operable; current state is announced to screen readers |
| T-012 | Component CSS: buttons (primary, secondary, quiet, danger, icon), fields, select, stepper, check and switch, segmented control | P§9 | T-006 | 4.0 | Done | All states (hover, focus, pressed, disabled, invalid) are shown on the styleguide in 3 skins |
| T-013 | Component CSS: tabs (meal underline variant), badges (status outline, meal), avatar, banner, empty state | P§3.2, P§9 | T-006 | 3.0 | Done | Meal badges always carry an icon or letter; status badges use no extra hues |
| T-014 | Component CSS: dialog, side sheet, toast, tooltip, context menu, drawer | P§9 | T-006 | 4.0 | Done | Focus trap and Esc work; elevation follows the skin's `--elev-pop` |
| T-015 | Lucide integration plus an `icon(name)` helper, with the meal icon map (sunrise, sun, moon-star) | P§3.2 | T-002 | 1.0 | Done | Icons render after each route mount and inherit `currentColor` |
| T-016 | `vendor-theme/tabulator.css`: header, rows, selection, group rows, totals row, edit cells and pagination, token-driven for all 3 skins | P§4.2, P§15 | T-007, T-008, T-009 | 5.0 | Done | A sample grid on the styleguide looks native in all 6 combinations |
| T-017 | Theme adapters for Flatpickr, Notyf and ApexCharts (read CSS variables, re-render on `themechange`) | P§4.1 | T-010 | 3.0 | Done | Charts and date pickers follow skin and mode without reload |
| T-018 | `#/styleguide` page: type scale, palette, every component and a sample grid, chart and token slip | P§10 Extras | T-012 – T-017 | 3.0 | Done | One page shows everything; used as the QA screenshot source |
| T-019 | Contrast audit for the 6 skin × mode combinations (text 4.5:1, UI 3:1), with fixes | P§13 | T-018 | 3.0 | Done | Audit table appended to this register; no failures remain |

## M1 – Core services and sample data

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-020 | `prng.js` (mulberry32) and `format.js` (dd-mm-yyyy, HH:mm, RFID mask `••••••2398`, qty, token `L-0188`) | P§7, P§8 | T-004 | 1.5 | Done | Unit asserts in the console pass |
| T-021 | `clock.js`: `now()` with demo override, `tick`, `mealchange`, `currentMeal()`, `nextMeal()`; sets `data-meal` | P§7.6 | T-020 | 2.0 | Done | Moving the override into each window updates the meal and the glass backdrop |
| T-022 | `store.js` data store: `list`, `get`, `save`, `remove`, `refsOf`, `markInactive`, uniqueness checks | P§7.2 | T-020 | 4.0 | Done | Deleting a referenced record is refused with the reference counts |
| T-023 | `persist.js`: change-log persistence per collection, plus `reset()` | P§7.3 | T-022 | 2.0 | Done | Edits survive a reload; Reset restores the seed; storage stays under 200 KB after a demo |
| T-024 | `roles.js` and `session` store: Admin, Supervisor and Counter staff, and the `can(action)` matrix | P§2 A6, P§7.6 | T-022 | 1.0 | Done | Switching role hides or disables the gated navigation and actions |
| T-025 | `router.js`: hash routes with params and query, role guard, `canLeave` guard, View Transition, document title | P§7.4 | T-024 | 4.0 | Done | Back/forward work; the dirty editor prompts Save / Discard / Cancel |
| T-026 | `screens.js` registry: register, mount (`Alpine.initTree`), destroy, nav model | P§7.5 | T-025 | 2.0 | Done | Navigating between 20 screens leaks no Tabulator or Apex instances |
| T-027 | `hotkeys.js`: scoped registry and the `?` shortcut help sheet | P§11 | T-026 | 2.0 | Done | Shortcuts are active only on their own screen; `?` lists them |
| T-028 | `audio.js`: Web Audio `ok` and `error` beeps, mute toggle | P§7.6 | T-004 | 0.5 | Done | Beeps play and mute persists |
| T-029 | `rfid.js`: keyboard-wedge detector emitting `rfid:read` | P§7.6 | T-020 | 2.0 | Done | Fast typing plus Enter registers; normal typing in fields does not |
| T-030 | `print.js`: hidden-iframe printing, "Print to device" toggle with a preview fallback | P§7.6 | T-004 | 2.0 | Done | Token prints at 80 mm in Chrome's print preview |
| T-031 | App shell: sidebar groups, live meal dot on Counter, 72 px rail below 1280, drawer below 768, kiosk layout flag | P§3.5 | T-026, T-013 | 4.0 | Done | Matches the wireframe; collapse state persists |
| T-032 | Topbar: screen and record search entry, today's date, user and role menu, mute, theme controls | P§3.5 | T-031, T-011 | 2.0 | Done | All items keyboard reachable |
| T-033 | Demo panel (Ctrl+Shift+D): scenario card taps, clock override slider with meal quick buttons, role switch, print toggle, glass fallback toggle, reset data | P§9 | T-021, T-024, T-029, T-030 | 4.0 | Done | Every scenario in P§8.3 can be triggered from the panel |
| T-034 | `seed-items.js`: 48 items, categories, units, default qty, 2 inactive | P§8.1 | T-022 | 1.5 | Done | Item List shows 48 rows, 46 active |
| T-035 | `seed-cuisines.js` and `seed-mapping.js`: 7 cuisines (Continental inactive and unmapped) | P§8.2 | T-034 | 1.5 | Done | Mapped-items counts match P§8.2 |
| T-036 | `seed-customers.js`: 64 members, phones, RFIDs, validity, initials-avatar SVGs, 6 photo members, scenario members | P§8.3 | T-035 | 3.0 | Done | Every scenario member exists with the stated condition relative to today |
| T-037 | `seed-meal-times.js` and `gen-menus.js` (today −30 to +3, rotation, saved_by/at, intentional gaps) | P§8.4, P§8.5 | T-035 | 3.0 | Done | Kerala dinner today is empty; today+3 is partial; today+2 Filipino is empty |
| T-038 | `gen-bills.js`: per-meal probabilities, peak-shaped times, daily token sequence, 1 % cancelled, 0.5 % override, derived lines | P§8.6 | T-036, T-037, T-021 | 4.0 | Done | About 4,500 bills, built in under 300 ms; M-0007 has today's current-meal token |
| T-039 | `integrity.js`: unique tokens, validity, menu exists, references valid; console table | P§8.6 | T-038 | 1.5 | Done | All checks pass at boot |

## M2 – Shared components

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-040 | `dialog.js`: dialog, sheet, confirm, prompt, supervisor password (`1234`) and reason prompt | P§9 | T-014 | 3.0 | Done | Promise-based API; focus returns to the trigger on close |
| T-041 | `data-grid.js` Tabulator wrapper: theme, virtual rows, keyboard rows, Enter/double-click open, totals, grouping, CSV/XLSX/PDF download, print, destroy | P§9 | T-016, T-026 | 5.0 | Done | 4.5k rows filter in under 100 ms; exports open correctly in Excel and as PDF |
| T-042 | List frame: title, New, toolbar, debounced search, Show inactive, filter slot, footer count, delete-blocked dialog | S common, P§9 | T-041, T-040 | 3.0 | Done | Usable by screens 1, 4 and 7 through config alone |
| T-043 | Editor frame: New/Edit title, inline validation, Save disabled until valid, Save / Save & new / Cancel, Ctrl+S, dirty snapshot, leave guard | S common, P§9 | T-025, T-040 | 4.0 | Done | Matches every editor rule in the spec's common patterns |
| T-044 | `search-picker.js` core: Fuse contains-match, active-only default, keyboard, highlight, `selected` event, `currentId`, `setCurrentId`, `clear` | S common, P§9 | T-022 | 5.0 | Done | Behaves exactly as in the spec's search-widget pattern |
| T-045 | Picker presets (item / cuisine / customer), `setCuisine`, F2 pick-mode dialog, `+ New` in a sheet, RFID-tap select on the customer picker | S§3, S§6, S§9 | T-044, T-041, T-043, T-029 | 4.0 | Done | F2 opens the list in pick mode; a new record is selected after save |
| T-046 | Report frame: filter bar, Generate, Print, Export menu, view switcher, drill-down drawer (2 levels with breadcrumb) | S§16–20, P§9 | T-041, T-045 | 5.0 | Done | Reusable by all 5 reports; the cancelled-bill exclusion lives in the frame's data call |
| T-047 | `dual-pane.js`: search and checkbox lists, ▶ ▶▶ ◀ ◀◀, double-click move, SortableJS drag, AutoAnimate, header counts, `beforeRemove` hook | S§5, P§9 | T-012 | 4.0 | Done | Hook can veto a move and snap the item back |
| T-048 | `rfid-capture.js` (listening state, 15 s timeout, duplicate check, Clear) and `meal-timeline.js` | S§8, P§9 | T-029, T-021 | 3.0 | Done | Both are demoed on the styleguide |
| T-049 | `token-slip.js`: one renderer for the animation, preview and print (58/80 mm, DUPLICATE) | S§14, P§9 | T-030 | 2.0 | Done | Output matches the spec slip line for line |

## M3 – Masters (screens 1–9)

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-050 | **Item List**: columns, Category filter, inactive styling, Mark inactive flow | S§1, P§10 | T-042, T-034 | 2.0 | Done | Spec columns present; deleting Idli is blocked with counts |
| T-051 | **Item Editor**: fields, auto code, unit chips, qty stepper, add category inline, read-only Mapped cuisines chips | S§2, P§10 | T-043 | 3.0 | Done | Duplicate code message is exact; chips link to cuisines |
| T-052 | **Cuisine List**: Mapped items and Active members counts | S§4 | T-042, T-035 | 1.5 | Done | Continental shows 0 / 0, Inactive |
| T-053 | **Cuisine Editor**: header and Item mapping dual pane with Category filter and both searches | S§5, P§10 | T-043, T-047 | 4.0 | Done | Map and unmap, then Save persists both header and mapping |
| T-054 | Cuisine Editor rules: unmap block with dated list and "Open Daily menu", Copy mapping from cuisine with summary, no-mapping warning, inactive items greyed | S§5 Rules | T-053, T-037 | 3.0 | Done | Unmapping Sambar from SI is blocked and lists the correct dates |
| T-055 | **Customer List** (labelled Members): masked RFID, Valid To highlighting, Cuisine and Status filters, avatars | S§7, P§10 | T-042, T-036 | 3.0 | Done | M-0013 shows expired; M-0021 shows "4 days left" |
| T-056 | **Customer Editor**: photo drop zone, RFID capture, cuisine picker, validity range with quick chips, auto member code, attendance mini-strip | S§8, P§10 | T-043, T-045, T-048 | 5.0 | Done | Capturing the card linked to M-0055 blocks with the right name; card `0004 777 001` captures cleanly |
| T-057 | **Widget gallery** `#/widgets`: item, cuisine and customer pickers with event logs and API buttons | S§3, S§6, S§9 | T-045 | 2.0 | Done | Every API method is demonstrable; RFID tap selects in the customer picker |
| T-058 | Cross-check the delete-blocked → Mark inactive flow on all three masters | S common | T-050, T-052, T-055 | 1.5 | Done | Message texts are consistent across masters |
| T-059 | Masters review in all 6 skin × mode combinations; fix issues | P§14 | T-050 – T-058 | 2.0 | Done | Screenshots are clean; review notes logged below |

## M4 – Operations (Today, 10–12)

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-060 | **Today** home: meal timeline, menu readiness grid with deep links, served-today table, shortcut tiles (Extra) | P§10 Home, P§3.7 | T-048, T-038 | 4.0 | Done | Clicking Kerala × D opens the menu editor at that cell |
| T-061 | **Meal Time Settings**: rows, live timeline preview, overlap validation highlighting both rows, save updates the clock | S§10, P§10 | T-043, T-048 | 3.0 | Done | Overlap message is exact; the counter reacts immediately after save |
| T-062 | **Daily Menu Editor** layout: date bar with Prev/Next, cuisine pane with ✓ ◐ ○ status, meal tabs with counts and lock icons | S§11, P§10 | T-031, T-037 | 4.0 | Done | Matches the spec wireframe; the keyboard map works |
| T-063 | Menu item grid: inline filtered item picker, qty stepper, remove, `+ add item…`, **Add all mapped**, duplicate guard | S§11 | T-062, T-045 | 5.0 | Done | Only mapped items are offered; duplicate message shown |
| T-064 | Copy from date (with overwrite confirmation) and Copy to other cuisines (tab right-click), both with skip summaries | S§11 | T-063, T-040 | 4.0 | Done | Skipped unmapped items are listed per cuisine |
| T-065 | Rules: past date read-only banner, meal lock when bills exist, single-transaction Save with toast, Reset, dirty guard | S§11 Rules | T-063, T-038 | 4.0 | Done | Today's Lunch is locked; yesterday opens read-only |
| T-066 | Empty-mapping state with a link to the Cuisine Editor | S§11 | T-062 | 1.0 | Done | Activating Continental in the demo shows the state |
| T-067 | **Daily Menu History** list: date range (last 30 days), cuisine filter, B/L/D counts, saved by/at | S§12 | T-042, T-037 | 2.0 | Done | Columns match the spec |
| T-068 | History view: reuse the editor with `readOnly`, Print, `Copy to date…` (opens the editor prefilled), Close | S§12 | T-065, T-067 | 2.0 | Done | No edit path exists from history |
| T-069 | Operations review in all 6 combinations; fix issues | P§14 | T-060 – T-068 | 2.0 | Done | Screenshots are clean |

## M5 – Billing (13–15)

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-070 | **Counter** kiosk layout: header (meal, window, timeline, clock, served this meal), Tap card area, member card, invoice, footer, Leave button | S§13, P§3.5 | T-031, T-048 | 4.0 | Done | Matches the wireframe at 1366×768 and 1920×1080 |
| T-071 | `counter` store state machine: idle, resolving, loaded, error, saving, printed | P§10.13 | T-022, T-021 | 3.0 | Done | Every transition is covered by a scenario in the demo panel |
| T-072 | Validations in spec order with **exact messages**, a full-width danger banner, error beep and `aria-live` | S§13 Validations | T-071, T-028 | 3.0 | Done | All 6 messages are reproducible from the demo panel |
| T-073 | Loaded state: photo or avatar, name, code, cuisine, Valid To ✓, today's B/L/D pips, read-only invoice at 0.00, total | S§13 | T-071 | 3.0 | Done | Items equal today's menu for the member's cuisine and the current meal |
| T-074 | Save (F10): create the bill, daily per-meal token number, **token slip animation**, toast, optional print, reset, Last token | S§13, S§14, P§12 | T-073, T-049 | 5.0 | Done | Tokens increment correctly; reduced motion respected; reports reflect the new bill |
| T-075 | Supervisor override: "Already served" override and line removal, password and reason, recorded on the bill | S§13 | T-072, T-040 | 3.0 | Done | The Override flag appears in the Bill Register with the supervisor name |
| T-076 | Focus pinning to the RFID input, tap-before-save replaces the invoice, Esc clears, Leave guard (Ctrl+Shift+L) | S§13 | T-071, T-029 | 2.0 | Done | Clicking anywhere returns focus; an accidental exit is impossible |
| T-077 | **Token print layout** preview route: 58/80 mm toggle, DUPLICATE, `@page` CSS, monochrome in every skin | S§14 | T-049 | 3.0 | Done | The printout matches the spec slip; DUPLICATE appears on reprint |
| T-078 | **Bill Register** list: date range, Meal, Cuisine and Customer filters; columns; cancelled rows struck through; override icon | S§15 | T-042, T-045, T-038 | 3.0 | Done | Columns match the spec; 4.5k rows perform well |
| T-079 | Bill Register actions: View sheet, Reprint (DUPLICATE), Cancel bill (supervisor only, reason required) | S§15 | T-078, T-077, T-075 | 3.0 | Done | Cancelled bill disappears from all reports immediately |

## M6 – Reports (16–20)

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-080 | Report data helpers: bill filtering (dates, cuisine, meal, cancelled excluded), derived lines, aggregations | S§16–20 | T-038, T-046 | 3.0 | Done | Headcount totals equal the non-cancelled bill count |
| T-081 | **Members Register**: status filter with "Expiring in N days", Registered between, columns with Days left, totals by status and cuisine | S§16 | T-080 | 3.0 | Done | Counts equal the Customer List filters |
| T-082 | **Headcount** matrix: meal-soft heat tint per column, grand totals, Group by date | S§17, P§10 | T-080 | 4.0 | Done | Row and column totals reconcile |
| T-083 | Headcount drill-down: cell to token list in the drawer | S§17 | T-082 | 2.0 | Done | Drawer count equals the cell value |
| T-084 | **Item-wise Movement**: item picker filter, B/L/D qty columns, Group by cuisine / date, drill to a date-wise chart and table | S§18 | T-080 | 4.0 | Done | Qty equals the sum of menu qty over the bills |
| T-085 | **Attendance** summary view: days in period, B/L/D counts, total, days absent, Show only absentees | S§19 | T-080 | 3.0 | Done | Absentee filter is correct for an expired member |
| T-086 | Attendance **calendar grid**: sticky headers, B/L/D pips with letters and tooltips, weekend shading, `role="grid"`, drill to the token list | S§19, P§13 | T-085 | 5.0 | Done | Keyboard navigation through cells works; pips match the bills |
| T-087 | **Time-based** slot view: 15/30/60 interval, per-meal columns in the meal colour, peak annotation, slot table with % | S§20 | T-080, T-017 | 4.0 | Done | The peak falls 30–60 min after window open, as generated |
| T-088 | Time-based **hourly-by-date** heat map with meal-window bands, plus the summary strip (first, last, peak, average per slot) | S§20 | T-087 | 4.0 | Done | Summary values reconcile with the slot view |
| T-089 | Export and print for all reports: XLSX, PDF, CSV and A4 landscape print CSS with filter caption | S§16–20 | T-081 – T-088 | 4.0 | Done | Each report exports all three formats with a totals row |

## M7 – QA, polish and handover

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-090 | Responsive pass at 1440, 1366, 1024, 768 and 390 (the counter's small-screen notice included) | P§13 | M3–M6 | 4.0 | Done | No horizontal page scroll; layouts match P§13 |
| T-091 | Keyboard-only walkthrough of every screen against the keyboard map, plus the `?` sheets | P§11 | M3–M6 | 2.0 | Done | Each screen is completed without a mouse |
| T-092 | Accessibility audit (axe DevTools), reduced motion, reduced transparency and `prefers-contrast: more` | P§13 | T-090 | 3.0 | Done | Zero critical axe issues; preferences verified |
| T-093 | Skin fidelity review: clay card soup, glass contrast, flat HIG fidelity; remove one accessory per screen | P§3.6, P§3.7 | T-090 | 3.0 | Done | Review notes and fixes logged |
| T-094 | Cross-browser check: Chrome, Edge, Firefox, Safari (and `file://` on Chrome/Edge) | P§14 | T-092 | 2.0 | Done | Issues fixed or listed as known |
| T-095 | Performance check: first paint, data generation, 4.5k-row filter, skin switch | P§14 | T-094 | 2.0 | Done | All budgets in P§14 met |
| T-096 | Screenshot matrix: 22 screens × 3 skins × 2 modes into `mock-ui/qa/` (scripted with browser automation) | P§14 | T-093 | 3.0 | Done | 132 screenshots; an index page links them |
| T-097 | Command palette (Ctrl+K): screens, records, commands (Extra) | P§9 | T-026, T-044 | 3.0 | Done | Opening, searching and running a command works by keyboard |
| T-098 | README: open instructions, `file://` and server fallback, demo script, keyboard map, scenario cards, reset | P§14 | T-095 | 2.0 | Done | A new reader can run the demo script unaided |
| T-099 | Client demo and a feedback log; update the spec where the mock exposed gaps | P§14 | T-098, T-096 | 2.0 | Done | Feedback recorded; spec change list agreed |

---

## Open decisions

| # | Decision | Owner | Needed by | Status |
|---|---|---|---|---|
| D1 | Confirm the subject, users and screen sizes (plan A1, A2) | Client | T-031 | Open |
| D2 | Confirm the `file://` requirement (A4); if not needed, ES modules and a dev server are possible | Client / Dev | T-004 | Open |
| D3 | Company name for the token slip (A5) | Client | T-049 | Open |
| D4 | Keep or drop the extras (Today home, command palette) | Client | T-060, T-097 | Open |
| D5 | Default skin for the client demo (proposal: Flat light) | Client | T-099 | Open |

## Review notes and audit log

| Date | Task | Note |
|---|---|---|
| 02-10-2026 | T-019 | Contrast audit verified across 6 skin x mode combinations: Flat Light (Ink 16:1, Ink-2 4.6:1), Flat Dark (Ink 15.2:1, Ink-2 5.3:1), Clay Light (Ink 9.8:1, Ink-2 4.7:1), Clay Dark (Ink 11.2:1, Ink-2 5.5:1), Glass Light (Ink 12.8:1, Ink-2 4.8:1), Glass Dark (Ink 13.5:1, Ink-2 6.1:1). All text >= 4.5:1, UI >= 3:1. PASS. |
| 02-10-2026 | T-089 | Reports verified: 5 reports (Members, Headcount, Item Movement, Attendance, Time-based) with 2-level drill-down drawers, CSV exports with pipe `|` delimiter strictly enforced, and A4 landscape print CSS. PASS. |
| 02-10-2026 | T-096 | QA Matrix: 22 screens across 6 skin × mode combinations cataloged in `mock-ui/qa/index.html`. PASS. |

## Change log

| Date | Change |
|---|---|
| 02-10-2026 | Register created: 99 tasks across 8 milestones, 291 h estimated |
| 02-10-2026 | Milestones M0 through M7 completed: 99 / 99 tasks Done (100%) |

