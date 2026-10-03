# Mess Module – Mock UI Implementation Plan

| | |
|---|---|
| Version | 1.0 (02-10-2026) |
| Source specs | [Mess_Modules.md](Mess_Modules.md), [Mess_Screens_Specification.md](Mess_Screens_Specification.md) |
| Task register | [Mess_MockUI_Tasks_Register.md](Mess_MockUI_Tasks_Register.md) |
| Output folder | `Mess_Module/mock-ui/` |
| Stack | Static HTML + CSS + JS, no build step, all libraries vendored locally |

---

## 1. Goal and scope

Build a clickable, production-quality **replica of every Mess Module screen** with hardcoded sample data. It is used to:

1. Sign off layouts and flows with the client before the Qt build starts.
2. Give the Qt developers a pixel-and-behaviour reference for each screen.
3. Demo the RFID billing flow end to end without hardware.

**In scope**
- All 20 screens and widgets in the spec, plus an app shell, a "Today" home, a widget gallery (the three search widgets) and a demo panel.
- Three skins: **Clay**, **Glass** and **Flat** (modern Apple-like). Each has a **light** and **dark** mode, plus **Auto**, which follows the OS.
- Realistic sample data: items, cuisines, mappings, members, meal times, 34 days of menus and about 4,500 generated bills, so the reports have real numbers.
- Working client-side logic: CRUD, validation, referential delete blocking, the billing validations, token numbering, the menu-lock rules, report aggregation, CSV/XLSX/PDF export and token printing.
- Changes persist in `localStorage`, and a **Reset sample data** command restores the seed.

**Out of scope**
- A backend, real authentication, real RFID or printer drivers. The reader is simulated as a keyboard wedge, and printing uses the browser's print path.
- Arabic (RTL) layout. The fonts include Arabic glyphs so Arabic names render, but mirroring is a later phase.

---

## 2. Assumptions to confirm with the client

| # | Assumption | If wrong |
|---|-----------|----------|
| A1 | Users are staff or labour-camp mess operators in the UAE. Members are mostly South Asian, Filipino and Arab workers. | Change the sample names and cuisines only. |
| A2 | The counter PC is 1366×768 or 1920×1080. Supervisors may use a tablet (≥1024 px). | Billing layout breakpoints. |
| A3 | Dates are `dd-mm-yyyy` with a 24-hour clock, as in the spec. | `format.js` only. |
| A4 | The mock should open from a double-click on `index.html` (`file://`) in Chrome/Edge. | Could switch to ES modules plus a dev server. |
| A5 | The company name on the token is a placeholder: "Sample Camp Mess, Jebel Ali". | Change one config value. |
| A6 | Roles: **Admin** (everything), **Supervisor** (override and cancel bills), **Counter staff** (counter and Bill Register view). | Role matrix in `store.js`. |

---

## 3. Design direction

### 3.1 Subject, audience, job

- **Subject:** a staff mess where hundreds of members tap a card three times a day and receive a food token.
- **Audience:**
  - counter staff working fast in a noisy hall, at arm's length from the screen;
  - a mess admin who plans menus a few days ahead;
  - a manager who reads headcounts to order food.
- **Primary job:** answer "who is this, what do they get, and is it allowed?" in under a second, then reset for the next person.

### 3.2 The core idea: the meal is the colour

The day has three meals, and every important number in this module is cut by meal (token prefix B/L/D, menu tabs, headcount columns, attendance markers). The mock therefore uses one chromatic code across all skins:

| Token | Meal | Light | Dark | Icon (Lucide) |
|-------|------|-------|------|---------------|
| `--meal-b` | Breakfast, "Saffron" | `#E08A1E` | `#F2AE55` | `sunrise` |
| `--meal-l` | Lunch, "Curry leaf" | `#1F9D6B` | `#45C893` | `sun` |
| `--meal-d` | Dinner, "Night violet" | `#6A4BD1` | `#A48BFF` | `moon-star` |
| `--danger` | Stop / error | `#D7263D` | `#FF5A6E` | `octagon-alert` |

Rule: **colour means meal; red means stop; everything else is ink.**
- No decorative accent hues and no gradient washes.
- Status badges (Active, Expiring, Inactive) use ink, icons and outline weight, never extra colours.
- Meal colour always comes with its icon or letter, so it never depends on colour vision alone.
- Each meal colour has a `-soft` variant (12–18 % alpha) for tab underlays and heat-map cells.

### 3.3 Skin palettes

Each skin is a recipe for **surfaces**, built on the shared meal code. The primary button never uses a meal colour.

**Flat (Apple-like)**: hairline separators, grouped inset lists, no shadows except on popovers.

| Role | Light | Dark |
|------|-------|------|
| Canvas | `#F5F5F7` | `#000000` |
| Surface | `#FFFFFF` | `#1C1C1E` |
| Raised | `#FFFFFF` | `#2C2C2E` |
| Ink / Ink-2 | `#1D1D1F` / `#6E6E73` | `#F5F5F7` / `#98989D` |
| Separator | `#D2D2D7` | `#38383A` |
| Primary | `#0071E3` | `#0A84FF` |

**Clay**: soft extruded surfaces with an inner highlight and shade, and pressable controls that sink when pressed. The primary button is an ink-coloured clay pill.

| Role | Light | Dark |
|------|-------|------|
| Canvas | `#DCE3EE` | `#1F2433` |
| Surface | `#E8EDF5` | `#272D3F` |
| Highlight (inset) | `#FFFFFF` | `#353C52` |
| Shade (inset/drop) | `#B4BFD3` | `#141826` |
| Ink / Ink-2 | `#26304A` / `#5D6782` | `#E6E9F2` / `#9AA3BA` |
| Primary | `#26304A` (pill), text `#F3F5FA` | `#E6E9F2` (pill), text `#1F2433` |

**Glass**: frosted panels over a **meal-aware backdrop**. Three blurred light pools in saffron, leaf and violet sit behind the app, and the pool for the *current meal* grows and brightens: warm in the morning, violet at night. The backdrop is the only ambient decoration in the product, and it carries information.

| Role | Light | Dark |
|------|-------|------|
| Backdrop base | `#E7EDF3` | `#070B16` |
| Glass | `rgba(255,255,255,.58)` | `rgba(22,30,52,.55)` |
| Glass strong (tables, forms) | `rgba(255,255,255,.80)` | `rgba(22,30,52,.82)` |
| Stroke | `rgba(255,255,255,.65)` | `rgba(255,255,255,.12)` |
| Ink / Ink-2 | `#12213A` / `#4A5873` | `#EEF2FA` / `#9AA6BF` |
| Primary | ink pill (`#12213A` / `#EEF2FA`) | same, inverted |

Glass rules:
- Dense content (grids, forms, the invoice) always sits on **glass strong**, keeping text contrast at 4.5:1 or better.
- With `prefers-reduced-transparency`, or when `backdrop-filter` is unsupported, glass becomes opaque surface colours.

### 3.4 Typography

One family per skin, chosen for what the surface recipe needs.

| Skin | Family | Why |
|------|--------|-----|
| Flat | `-apple-system, "SF Pro Text", "Segoe UI Variable Text", "Inter", system-ui` | Apple-like means the OS's own face. On the Windows counter PC this resolves to Segoe UI Variable. |
| Clay | **Nunito** (variable, 400–800) | Rounded terminals echo the soft extruded shapes, and it stays legible at heavy weights on pillowy buttons. |
| Glass | **Sora** (variable, 300–700) | Geometric with open apertures, so it holds up at light weights over blurred backgrounds. |
| All | **IBM Plex Sans Arabic** as a fallback | Renders Arabic member names. |

- **Numerals:** `font-variant-numeric: tabular-nums` on every qty, time, token and count column. There is no monospace in the UI. The only monospace is the **thermal token slip**, because that is what the printer itself produces.
- **Scale** (base 15 px, ratio ≈ 1.2): 12 · 13 · **15** · 18 · 22 · 27 · 32.
  - Line height: 1.45 for body text, 1.15 for headings.
  - Weights: 400 (text), 600 (labels, emphasis), 750 (headings).
- **Counter scale** (`.counter` root, base 20 px):
  - member name 32/600;
  - token number **96/750** in the meal colour;
  - clock 40 tabular;
  - error banner 36/700.
- **Copy rules:**
  - Sentence case everywhere, with no all-caps labels. The spec's "MESS COUNTER" becomes "Mess counter".
  - Buttons say exactly what happens ("Save & print token"), and the matching toast repeats the verb ("Token L-0188 printed").
  - No `→` glyphs on buttons and no dot-joined meta strings.

### 3.5 Layout concept

The app is left-aligned throughout. Numbers are right-aligned in grids, and forms use top-aligned labels in a single 560 px column, or two columns at ≥1280 px.

**App shell**: sidebar groups (Masters, Operations, Reports) with no numbering, because they are not a sequence.
```
┌────────────┬──────────────────────────────────────────────────────────┐
│ Mess       │ ⌕ Search screens, members, items…   [Clay|Glass|Flat] ◐ │
│            ├──────────────────────────────────────────────────────────┤
│ Today      │                                                          │
│ Counter ●L │   <screen outlet>                                        │
│            │                                                          │
│ Masters    │                                                          │
│  Items     │                                                          │
│  Cuisines  │                                                          │
│  Members   │                                                          │
│ Operations │                                                          │
│  Daily menu│                                                          │
│  Menu hist.│                                                          │
│  Bills     │                                                          │
│  Meal times│                                                          │
│ Reports    │                                                          │
│  …5        │                                                          │
│ ─────────  │                                                          │
│ admin ▾    │                                                          │
└────────────┴──────────────────────────────────────────────────────────┘
```
- Width: 248 px, collapsing to a 72 px icon rail below 1280 px and to a drawer below 768 px.
- The Counter nav entry shows a live dot in the current meal's colour.

**List screen** (Items / Cuisines / Members)
```
 Items                                               [ + New item ]
 [⌕ Search code or name     ]  [ ] Show inactive   Category ▾   ⤓ Export
 ┌──────────────────────────────────────────────────────────────────┐
 │ Code   Item name            Category        Unit    Active        │
 │ I001   Idli                 Breakfast       Nos     ✓             │
 │ …  (Tabulator, virtual rows, sticky header)                      │
 └──────────────────────────────────────────────────────────────────┘
 48 items · 3 inactive
```

**Counter (kiosk route, no sidebar)**: the one place where the design gets loud.
```
┌──────────────────────────────────────────────────────────────────────┐
│ ‹ Leave   Mess counter      ☀ Lunch 12:00–15:00 ▓▓▓▓▓░░░   14:23:05 │
├──────────────────────────────────────────────────────────────────────┤
│                     ((  Tap card  ))     ••••••2398                  │
├──────────────────────────┬───────────────────────────────────────────┤
│  ┌────┐ Rahul K          │  #  Item           Qty   Rate   Amount    │
│  │ RK │ M-0042           │  1  Rice            1    0.00    0.00     │
│  └────┘ South Indian     │  2  Sambar          1    0.00    0.00     │
│  Valid to 31-12-2026 ✓   │  3  Rasam           1    0.00    0.00     │
│  Today  B✓  L·  D·       │                      Total       0.00     │
├──────────────────────────┴───────────────────────────────────────────┤
│ [ Save & print token  F10 ]   [ Clear  Esc ]       Last token L-0187 │
└──────────────────────────────────────────────────────────────────────┘
```

### 3.6 Principles

1. **One loud moment: the token.** On Save, a token slip slides out of a slot at the top of the invoice panel, showing the token number at 96 px in the meal colour. It holds for 1.2 s, then the screen resets. This is the only orchestrated, non-requested animation in the product.
2. **Readable at arm's length.** The counter uses its own type scale. Each state (waiting, loaded, error, printed) changes the whole screen, not a small label.
3. **Three skins, one DOM.** Skins only swap tokens and surface recipes; markup and behaviour are identical, so the comparison is fair.
4. **Keyboard first.** Every screen works without a mouse: F2, F10, Esc, Enter and arrows, as in the spec.
5. **Quiet everywhere else.** Masters and reports are calm, dense and aligned. There are no hover lifts and no entrance animations on sections.

### 3.7 Review against the brief (revisions made)

| Default the first draft drifted toward | Why it was generic | Revision |
|---|---|---|
| Glass skin over a purple-blue gradient blob background | That is the stock "glassmorphism" look and says nothing about a mess. | The pools of light are the **meal colours**, and the current meal's pool dominates. The backdrop now tells the time of day. |
| Clay skin with every block a rounded card with the same shadow | The SaaS card kit. Clay amplifies it. | Radius follows hierarchy: shell 28, panels 20, controls 12, chips full. Grid rows are not individual clay blobs; a whole table sits in one inset "well". |
| A "Today" home with four big-number KPI cards and gradient accents | The default dashboard opening. | Home is a **meal timeline** (06:00–22:30 with the three windows and a now-marker) plus a **menu readiness grid** (cuisine × B/L/D, each cell linking into the Daily Menu Editor). It shows what to do next, not vanity numbers. |
| A brand accent colour plus meal colours | Two competing colour systems. | The primary button is ink (clay, glass) or system blue (flat only). Colour is reserved for meals and danger. |
| Monospace for codes and RFID | A generated-UI tell. | Tabular numerals in the skin face. Monospace appears only on the thermal slip. |
| Uppercase section eyebrows ("MASTERS") | Template chrome. | Sentence-case group labels in Ink-2 at 13/600. |

---

## 4. Theme system

### 4.1 Mechanics
```html
<html data-skin="glass" data-mode="dark" data-meal="L">
```
- **`data-skin`**: `clay | glass | flat`, default `flat`.
- **`data-mode`**: `light | dark`. "Auto" is stored as `auto` and resolved with `matchMedia('(prefers-color-scheme: dark)')`, with a live listener.
- **`data-meal`**: `B | L | D | none`, set by the clock service. It drives the glass backdrop and the Counter nav dot.
- **Persistence:** stored in `localStorage` under `mess-mock:theme`. An inline script in `<head>` applies it before first paint, so there is no flash.
- **Switching:**
  - The topbar has a 3-way segmented control (skin) and a sun/moon button (mode). A long-press or right-click on the mode button offers Auto.
  - The change runs inside `document.startViewTransition()` as a circular reveal from the button that was clicked. It falls back to an instant swap, and is instant under reduced motion.
- **Event:** `window.dispatchEvent(new CustomEvent('themechange'))`. ApexCharts, Tabulator and Flatpickr adapters listen for it and re-read the CSS variables.

### 4.2 CSS layering
```
css/base/tokens.css        spacing (4px grid), type scale, radii hierarchy, z-index, motion, meal + danger colours
css/skins/flat.css         [data-skin=flat]  + [data-skin=flat][data-mode=dark]
css/skins/clay.css         [data-skin=clay]  …
css/skins/glass.css        [data-skin=glass] … + backdrop + fallbacks
css/components/*.css       consume only semantic tokens (--surface, --ink, --elev-1, --radius-panel …)
css/vendor-theme/*.css     Tabulator / Flatpickr / Notyf / ApexCharts overrides, token-driven
```
Component CSS never names a skin. Skins only set semantic tokens, plus the few recipe hooks below:

| Semantic token | Flat | Clay | Glass |
|---|---|---|---|
| `--elev-panel` | `none` + 1px separator | dual inset highlight/shade + soft drop | `backdrop-filter: blur(24px) saturate(160%)` + stroke |
| `--elev-pop` | `0 8px 30px rgba(0,0,0,.12)` | stronger drop | blur 32 + stroke + soft drop |
| `--press` | opacity .7 | inset shadow swap (pressed-in) | glass brightens 6 % |
| `--radius-shell / panel / control / chip` | 14 / 12 / 8 / 999 | 28 / 20 / 12 / 999 | 24 / 18 / 12 / 999 |
| `--focus-ring` | 3px primary @ 40 % | 3px ink @ 35 % + offset 2 | 2px white + 4px ink @ 30 % |

Specificity rule: one class per component (`.btn`, `.btn--primary`). Skins only override custom properties, never component selectors. No section-level margins; vertical rhythm comes from `gap` on layout containers, which avoids padding and margin conflicts.

---

## 5. Technology stack

No build step and no framework compile. Every library is downloaded once into `mock-ui/vendor/` by `tools/vendor.ps1`, so the mock works offline on a counter PC. Exact versions are written to `vendor/VERSIONS.md` at download time.

| Need | Library (pin major) | Why this one |
|------|---------------------|--------------|
| Reactivity / templating | **Alpine.js 3.x** | Declarative, no build, works from `file://`. Its stores suit the mock data. |
| Data grids (lists, register, reports) | **Tabulator 6.x** | Virtual DOM (4.5k bills is fine), grouping, totals row (`bottomCalc`), keyboard nav, CSV/XLSX/PDF download, fully CSS-themable. |
| Excel export | **SheetJS (xlsx) 0.20.x** from `cdn.sheetjs.com` | Used by Tabulator's `download('xlsx')`. |
| PDF export | **jsPDF 2.x + jspdf-autotable 3.x** | Tabulator's PDF download path. |
| Charts | **ApexCharts 4.x** | Heat maps (hourly-by-date), stacked columns (time slots), clean SVG. Themed from CSS variables. |
| Fuzzy search in widgets | **Fuse.js 7.x** | Contains-match with ranking across code, name, phone and RFID. |
| Date picking | **flatpickr 4.6.x** | Small, keyboard-friendly, `d-m-Y` format, range mode for reports. |
| Drag between mapping panes | **SortableJS 1.15.x** | Multi-drag between Available and Mapped (on top of the ▶ ◀ buttons). |
| List add/remove motion | **AutoAnimate 0.8.x** | Animates only rows the user adds or removes (menu grid, mapping). |
| Toasts | **Notyf 3.x** | Minimal and themable. |
| Hotkeys | **hotkeys-js 3.x** | Scoped shortcuts (per screen) and F-keys. |
| Dates | **Day.js 1.11.x** (+ customParseFormat, isBetween, isoWeek) | Formatting and arithmetic. |
| Icons | **Lucide** (UMD) | A consistent 1.5px stroke set with meal icons (sunrise, sun, moon-star). |
| Fonts | Nunito, Sora, IBM Plex Sans Arabic (woff2, subset Latin + Arabic) | Self-hosted in `assets/fonts/`. |

Native platform features used:
- `<dialog>` for modals and sheets.
- View Transitions API for screen and theme changes.
- Web Audio for the beeps (no audio files).
- `@page` print CSS for the token slip.
- `structuredClone` for snapshots used by dirty checks.

**Not used, and why:**
- **Tailwind:** three skins would need three variant systems. Semantic CSS variables are simpler.
- **React/Vue:** they need a build step, which breaks the `file://` requirement (A4).
- **Bootstrap:** its visual defaults fight all three skins.

---

## 6. Project structure

```
mock-ui/
├─ index.html                 shell markup, script/style load order, no-flash theme script
├─ README.md                  how to open, demo script, keyboard map
├─ tools/
│  └─ vendor.ps1              downloads pinned libs + fonts → vendor/, writes VERSIONS.md
├─ vendor/                    (generated) alpine, tabulator, apexcharts, fuse, flatpickr, sortable,
│                             auto-animate, notyf, hotkeys, dayjs, lucide, xlsx, jspdf(+autotable)
├─ assets/
│  ├─ fonts/                  nunito.woff2, sora.woff2, plex-arabic.woff2
│  └─ img/                    logo.svg, card-reader.svg, empty-*.svg (single-colour line art)
├─ css/
│  ├─ base/                   reset.css, tokens.css, typography.css, layout.css, a11y.css
│  ├─ skins/                  flat.css, clay.css, glass.css
│  ├─ components/             button, field, check-switch, segmented, tabs, badge, avatar, dialog,
│  │                          sheet, toast, tooltip, context-menu, picker, banner, empty, toolbar,
│  │                          dual-pane, timeline, token-slip
│  ├─ vendor-theme/           tabulator.css, flatpickr.css, notyf.css, apex.css
│  ├─ screens/                home, counter, menu-editor, cuisine-editor, customer-editor, reports
│  └─ print/                  token.css (58/80mm), report.css (A4 landscape)
└─ js/
   ├─ core/                   prng.js, format.js, clock.js, store.js, persist.js, router.js,
   │                          theme.js, hotkeys.js, audio.js, rfid.js, print.js, roles.js, screens.js
   ├─ data/                   seed-items.js, seed-cuisines.js, seed-mapping.js, seed-customers.js,
   │                          seed-meal-times.js, gen-menus.js, gen-bills.js, integrity.js
   ├─ components/             search-picker.js, pickers.js, data-grid.js, list-frame.js,
   │                          editor-frame.js, report-frame.js, dialog.js, dual-pane.js,
   │                          rfid-capture.js, meal-timeline.js, token-slip.js, demo-panel.js,
   │                          command-palette.js
   ├─ screens/                one file per screen (see §10)
   └─ app.js                  boot: theme → data → stores → shell → router.start()
```

All scripts are **classic scripts** loaded in order, each attaching to `window.Mess`. This keeps `file://` working: ES modules and `fetch()` of local partials are blocked by Chrome over `file://`.

---

## 7. Architecture

### 7.1 Boot sequence
1. The inline `<head>` script applies the theme attributes.
2. Vendor scripts load (`defer`), then `core/*`, `data/*`, `components/*`, `screens/*` and `app.js`.
3. `app.js`:
   1. `Mess.data.build(seed, today)` generates menus and bills deterministically (seeded PRNG, `mulberry32(20261002)`).
   2. It applies the persisted user changes from `localStorage`.
   3. It registers the Alpine stores, then starts Alpine and the router.

### 7.2 Stores (`Alpine.store`)
| Store | Holds | Key methods |
|---|---|---|
| `data` | items, cuisines, cuisineItems, customers, mealTimes, menus, bills | `list(kind, filter)`, `get`, `save`, `remove` (with `refsOf` check), `markInactive`, `reset()` |
| `ui` | skin, mode, sidebar state, open dialogs, toasts | `setSkin`, `setMode`, `toast(kind, text)` |
| `session` | user, role, counter id (`C1`), clock override | `can(action)`, `now()` |
| `counter` | billing state machine (§10.13) | `tap(rfid)`, `save()`, `clear()`, `override()` |

### 7.3 Persistence
- Generated data (menus and bills) is **not** stored. It is rebuilt at boot from the seed, so the dates always stay relative to *today*.
- User changes are stored as a compact **change log** per collection (`upserts`, `deletes`) in `localStorage['mess-mock:v1']`. This stays small even after a long demo.
- `Reset sample data` (demo panel, and the command palette) clears the key and reloads.

### 7.4 Router
- Hash routes with params, e.g. `#/items/I012`, `#/menu/2026-10-05`, `#/reports/headcount?from=…`.
- **Guards:**
  - `role` (redirects to Today with a toast "You don't have access to Bills");
  - `canLeave()` (the dirty-editor `Save / Discard / Cancel` dialog from the spec).
- Screen swaps use a View Transition (a 160 ms cross-fade), or instant under reduced motion.
- The document title updates with each screen, as `Items – Mess`.

### 7.5 Screen module contract
```js
Mess.screens.register({
  id: 'item-list',
  route: '/items',
  title: 'Items',
  nav: { group: 'Masters', icon: 'utensils', order: 10 },
  roles: ['admin'],
  template: () => /* html */ `…Alpine markup…`,
  component: () => ({ init() {}, destroy() {} }),
  hotkeys: { 'n': 'create', '/': 'focusSearch', 'enter': 'openSelected', 'delete': 'remove' },
  canLeave() { return true; },
});
```
The router mounts the `template()` HTML into `#outlet`, calls `Alpine.initTree`, binds the hotkey scope and calls `destroy()` on leave (this destroys the Tabulator and Apex instances).

### 7.6 Services
| Service | Behaviour |
|---|---|
| `clock.js` | `now()` returns the real time or the demo override. It emits `tick` every second and `mealchange` when the window changes. `currentMeal()` and `nextMeal()` read the Meal Time Settings. |
| `rfid.js` | Keyboard-wedge detection: printable keys arriving < 35 ms apart and ending in Enter are a card read (≥ 8 chars). It emits `rfid:read`. The demo panel "types" a card the same way, so the real path is exercised. |
| `audio.js` | Web Audio beeps: `ok` (880 Hz, 80 ms) and `error` (220 Hz, 2 × 160 ms). Mute toggle in the topbar menu. |
| `print.js` | Renders the token HTML into a hidden iframe with `print/token.css` and calls `print()`. "Print to device" is **off** by default in the mock, so the demo isn't interrupted by the browser dialog. When off, it shows the slip preview instead. |
| `roles.js` | Permission matrix: `bill.cancel`, `bill.override`, `masters.edit`, `menu.edit`, `reports.view`, `counter.use`. |

---

## 8. Sample data

All data is deterministic. Dates are relative to the real today (shown here as 02-10-2026).

### 8.1 Items (48): `I001`–`I048`
| Category | Items (unit) |
|---|---|
| Breakfast | Idli (Nos), Plain dosa (Nos), Masala dosa (Nos), Ven pongal (Plate), Rava upma (Plate), Medu vada (Nos), Poha (Plate), Aloo paratha (Nos), Appam (Nos), Puttu (Plate), Halwa puri (Plate), Foul medames (Bowl), Longganisa (Plate), Fried egg (Nos) |
| Breads | Chapati (Nos), Tandoori naan (Nos), Khubz (Nos), Kerala porotta (Nos) |
| Rice | Steamed rice (Plate), Kerala matta rice (Plate), Jeera rice (Plate), Chicken biryani (Plate), Chicken machboos (Plate), Garlic rice (Plate) |
| Curries | Sambar (Bowl), Rasam (Bowl), Dal tadka (Bowl), Rajma (Bowl), Paneer butter masala (Bowl), Kadala curry (Bowl), Kerala fish curry (Bowl), Mutton karahi (Bowl), Chicken handi (Bowl), Chicken adobo (Bowl), Sinigang (Bowl) |
| Sides | Coconut chutney (Cup), Cabbage poriyal (Cup), Avial (Cup), Hummus (Cup), Falafel (Nos), Fattoush (Bowl), Pancit (Plate), Raita (Cup) |
| Beverages | Karak tea (Cup), Filter coffee (Cup), Laban (Glass) |
| Desserts | Gulab jamun (Nos), Fresh fruit (Piece) |

Two items are **inactive** (Halwa puri, Longganisa) to demo greyed-out mapped items.

### 8.2 Cuisines (7)
| Code | Name | Mapped items | Notes |
|---|---|---|---|
| SI | South Indian | 14 | Largest group |
| NI | North Indian | 12 | |
| KR | Kerala | 12 | Today's **Dinner menu is deliberately not set**, to demo "Menu not set" |
| PK | Pakistani | 10 | |
| FL | Filipino | 9 | |
| AR | Arabic | 10 | |
| CT | Continental | 0 | **Inactive, no mapping**: demos the "No items mapped" state and inactive filtering |

### 8.3 Members (64): `M-0001`–`M-0064`
- Diverse names (Indian, Pakistani, Filipino, Nepali, Bangladeshi, Egyptian, plus a few in Arabic script) and `+971 5x xxx xxxx` phones.
- Ten-digit RFID numbers, displayed masked as `••••••2398`.
- Photos are generated **initials avatars** (SVG, hue derived from the member code). Six members have uploaded-style illustrated photos stored in `assets/img/`.
- Split across cuisines roughly in proportion: SI 16, NI 12, KR 10, PK 9, FL 9, AR 8.
- **Scenario members** (also listed in the demo panel):

| Member | Scenario |
|---|---|
| M-0042 Rahul K (SI) | Happy path. The spec's own example. |
| M-0007 Maria Santos (FL) | Already served the current meal today (has a token) |
| M-0013 Imran Qureshi (PK) | **Expired** 3 days ago |
| M-0021 Sunil Thapa (NI) | **Expiring** in 4 days (warning highlight in lists) |
| M-0030 Ahmed Fathy (AR) | **Inactive** |
| M-0055 Arjun Nair (KR) | Kerala, so "Menu not set" at dinner |
| Card `0009 999 999` | **Not registered** |
| Card `0004 777 001` | Unassigned card for the RFID-capture demo in Customer Editor |

### 8.4 Meal times
As in the spec: Breakfast 06:00–10:00, Lunch 12:00–15:00, Dinner 19:00–22:30, all active.

### 8.5 Menus (generated)
- From **today −30 to today +3**, for every active cuisine and every meal. Items are chosen by rotation from the cuisine's mapping, with 3–6 items per meal and qty from Default Qty.
- `saved_by` alternates between `admin` and `chef.ravi`, with `saved_at` the previous evening.
- Intentional gaps:
  - Kerala dinner today (empty);
  - today+3 has only Breakfast (partial, so the left pane shows a dot);
  - today+2 has Filipino empty.

### 8.6 Bills (generated, about 4,500)
- For each member, day and meal from today −30 to *now*, a bill is created with probability B 0.70, L 0.85, D 0.75. The probability drops to 0 outside the member's validity or while they are inactive.
- **Times** follow a skewed distribution inside the window, with a peak 30–60 min after opening, so the Time-based report shows a real peak.
- **Token numbers** are `B-0001…`, restarting per day per meal, in time order.
- 1 % are **cancelled** (reason text and supervisor recorded) and 0.5 % carry an **override** flag.
- **Lines are not stored.** They are derived from the menu of that date, cuisine and meal (which is exactly what the business rule says). This keeps memory and storage small.
- `integrity.js` asserts the following at boot and logs a table to the console:
  - unique tokens per day and meal;
  - no bill outside validity;
  - no bill for a meal without a menu;
  - all mapping references are valid.

---

## 9. Shared components

| Component | Spec ref | Behaviour |
|---|---|---|
| **Search picker** (`search-picker.js`) | Common pattern, §3, §6, §9 | Input with a popover list (max 8 rows). Fuse.js contains-match on configured keys; active records only by default. ↑/↓, Enter, Esc. **F2** opens the full List screen in a `<dialog>` in **pick mode** (Tabulator, Enter or double-click picks). The optional `+ New` row opens the Editor in a sheet and selects the new record on save. API: `selected` event (`detail.id`), `currentId()`, `setCurrentId(id)`, `clear()`, `setCuisine(id)` (item picker). Matched text is highlighted (weight, not colour). |
| Pickers preset (`pickers.js`) | §3, §6, §9 | **Item:** `Code – Name (Unit)`, cuisine filter. **Cuisine:** `Code – Name`. **Customer:** `Code – Name – Cuisine – Valid to` with an avatar; listens to `rfid:read` while focused, so a tap selects directly. |
| Data grid (`data-grid.js`) | Lists, register, reports | Tabulator wrapper. Skin theme, virtual rows, sticky header, keyboard row focus, Enter/double-click → open, `bottomCalc` totals, group-by, download (CSV, XLSX, PDF), print. Rebuilds on `themechange`. |
| List frame | Common list pattern | Title, primary `New`, toolbar (`Edit`, `Delete`, `Refresh`, `Export`), search (filters as you type, debounced 120 ms), `Show inactive`, extra filters slot, footer count. Delete when referenced opens a dialog: "Idli is used in 3 cuisines and 214 bills. It can't be deleted. Mark inactive instead?" `[Mark inactive] [Cancel]`. |
| Editor frame | Common editor pattern | Title `New item` / `Edit item – Idli`. Inline validation under each field, shown on blur and on Save attempt. `Save` disabled until required fields are valid. `Save`, `Save & new`, `Cancel`; Ctrl+S saves. Dirty tracking via snapshot compare. Leave guard. |
| Report frame | §16–20 common frame | Filter bar (date range defaulting to today, Cuisine picker, Meal segmented `All/B/L/D`, extra filters slot), `Generate` (results don't auto-run, matching the spec), `Print`, `Export ▾ (Excel / PDF / CSV)`. Result area with view switcher where a report has two views. **Drill-down drawer** from the right, stackable two levels with a breadcrumb. Cancelled bills are always excluded. |
| Dialog / sheet / confirm / prompt | — | `<dialog>`-based, focus trap, Esc closes. Supervisor prompt (password `1234` in the mock), reason prompt. |
| Dual pane (`dual-pane.js`) | §5 mapping | Two lists with search and checkboxes, ▶ ▶▶ ◀ ◀◀, double-click to move, SortableJS drag, AutoAnimate. Counts in the headers. |
| RFID capture | §8 | `Capture` → listening state ("Tap card now…", 15 s timeout ring) → fills the field. A duplicate shows "Card linked to Arjun Nair (M-0055)" and blocks save. `Clear RFID` button. |
| Meal timeline | Home, Counter | A 06:00–22:30 track with three meal-coloured windows, a now-marker and a "next meal" label. |
| Token slip | §14 | One renderer used by the counter animation, the preview dialog and print. 58/80 mm widths, `DUPLICATE` watermark line on reprints. |
| Banner | Counter errors, read-only states | Full-width; danger (counter) or neutral-info (history read-only, locked meal). |
| Empty states | Everywhere | Line-art illustration plus one sentence and one action. Examples: "No items mapped to Continental yet. Open the cuisine to map items." `[Open Continental]`. "No bills match these filters. Widen the date range." |
| Command palette | Extra | Ctrl+K: jump to any screen, member, item or cuisine, and run commands (switch skin, toggle dark, reset data). |
| Demo panel | Mock only | Ctrl+Shift+D, docked bottom-right and visibly separate (dashed outline, labelled "Demo controls"). Tap scenario cards, override the clock (slider plus "Breakfast / Lunch / Dinner / Closed" quick buttons), switch role, toggle print to device, reset data. |

---

## 10. Screen-by-screen plan

Every screen must render correctly in all six skin × mode combinations and pass the keyboard walkthrough in §11.

### Home: Today (`#/`), an addition
- **Meal timeline** at the top.
- **Menu readiness grid:** active cuisines × B/L/D. Each cell shows its item count and state (complete ✓, empty ○ in Ink-2, locked 🔒). A click opens the Daily Menu Editor at that date, cuisine and meal.
- **Served so far today:** a small cuisine × meal count table (links to the Headcount report).
- **Shortcut tiles:**
  - "Open counter";
  - "Set tomorrow's menu";
  - "Members expiring in 7 days (n)".

### 1. Item List (`#/items`)
- Columns per spec (Code, Item name, Category, Unit, Active), plus a Category filter.
- Inactive rows are shown in Ink-2 with an "Inactive" outline badge.
- Delete is blocked for referenced items, and the dialog offers Mark inactive.

### 2. Item Editor (`#/items/new`, `#/items/:id`)
- Fields per spec:
  - Code: auto-suggested as the next `I0xx`, must be unique.
  - Name.
  - Category: select with "+ Add category" inline.
  - Unit: segmented chips Nos / Plate / Bowl / Cup / Glass / Piece.
  - Default Qty: stepper, decimal 0.5 steps.
  - Active switch.
- **Mapped cuisines** (read-only) as chips at the bottom, each linking to its cuisine.
- Validation messages:
  - "Item code I012 is already used by Idli."
  - "Enter an item name."

### 3. Item Search Widget (gallery `#/widgets#item`, live in §11 and §18)
- The gallery shows three instances: no filter, `setCuisine('SI')`, and one with `+ New`.
- A live **event log** under each instance shows `selected(I012)` and the API buttons (`setCurrentId`, `clear`).

### 4. Cuisine List (`#/cuisines`)
- Columns per spec, including **Mapped items** and **Active members** counts.
- Continental shows 0 / 0 and Inactive.

### 5. Cuisine Editor (`#/cuisines/new`, `#/cuisines/:id`)
- The header fields sit in one row.
- **Item mapping** uses the dual pane, with the Category filter on the left and a search on each side.
- `Copy mapping from cuisine…` opens a dialog with the Cuisine picker, then a summary toast: "Added 7 items from North Indian. 3 were already mapped."
- **Unmap block:** moving Sambar out while it's on today's or a future menu snaps it back. The dialog lists the dates ("Sambar is on the menu for 02-10-2026 Lunch, 03-10-2026 Breakfast…") and offers `Open Daily menu`.
- Inactive mapped items are greyed with a tooltip.
- Saving with no mapped items shows the warning dialog from the spec, with options "Save anyway" and "Map items".
- The `Save` / `Save & new` / `Cancel` bar is sticky at the bottom.

### 6. Cuisine Search Widget (gallery `#/widgets#cuisine`, live in §8 and reports)
- Shows active cuisines only. The gallery includes a "Show inactive" variant for comparison.

### 7. Customer List (`#/customers`), labelled "Members" in the UI
- Columns per spec. RFID is masked.
- **Valid to** is highlighted:
  - expired: danger text plus an icon;
  - within 7 days: outline badge "4 days left" with a clock icon.
- Extra filters: Cuisine picker and Status segmented (All / Active / Expiring / Expired / Inactive).
- The avatar thumbnail sits in the Name cell.

### 8. Customer Editor (`#/customers/new`, `#/customers/:id`)
- A two-column form: the photo card on the left (drop zone, file input → dataURL, "Remove photo") and the fields on the right.
- **RFID field:**
  - `Capture` enters listening mode; a demo-panel tap or a real wedge fills the field;
  - a duplicate blocks with the linked member's name;
  - `Clear RFID`.
- **Cuisine:** Cuisine picker (active only).
- **Validity:** Flatpickr range, defaulting from today to today +1 year, with quick chips "+1 month / +3 months / +1 year". Valid To must be on or after Valid From.
- Member Code is auto-generated `M-00nn` and editable.
- An **"Attendance this month"** mini-strip (read-only B/L/D pips) for existing members. It links to report 19 with the member preset.

### 9. Customer Search Widget (gallery `#/widgets#customer`, live in §15 and §19)
- Rows show the avatar, `M-0042 – Rahul K – South Indian – 31-12-2026`.
- With focus in the widget, a demo-panel tap selects the matching member directly.

### 10. Meal Time Settings (`#/settings/meal-times`)
- Three rows (meal icon, name, From/To time inputs, Active switch).
- A live preview on the **meal timeline** updates as you type.
- **Overlap validation** highlights both conflicting rows: "Lunch starts before Breakfast ends (09:30 < 10:00)."
- Save/Cancel; saving updates the clock service immediately, which affects the counter and the glass backdrop.

### 11. Daily Menu Editor (`#/menu/:date?`)
- Layout per spec.
- **Top bar:**
  - date (Flatpickr) with Prev/Next (Alt+←/→);
  - `Copy from date…`;
  - `History`.
- **Left pane:** active cuisines with a status glyph (✓ all three meals, ◐ some, ○ none) and an item count.
- **Meal tabs:** a meal-coloured underline, icon and count badge. A lock icon appears when bills exist ("Locked – 142 tokens printed for Lunch").
- **Item grid:**
  - rows with an inline Item picker (filtered to the cuisine's mapping), qty stepper, unit and remove;
  - `+ add item…` as the last row;
  - `Add all mapped` button above the grid;
  - adding a duplicate shakes and focuses the existing row with the message "Idli is already in Lunch".
- **Right-click on a tab** → "Copy Lunch to other cuisines…" dialog with checkboxes, then a skip summary ("Skipped for Arabic: Sambar, Rasam – not mapped").
- **Copy from date…** → date picker, then an overwrite confirmation, then the skip summary.
- **Empty mapping** (Continental, if activated in the demo): the empty state with a link to the Cuisine Editor.
- **Past date:** the whole screen is disabled, with the read-only banner "History – read only" and only Print, `Copy to date…` and Close available.
- **Footer:** per-cuisine status `B ✓ L ✓ D ✗`, plus `Save` (one transaction, toast "Menu for 05-10-2026 saved – 6 cuisines, 18 meals"), `Reset` and `Close`. Dirty guard.

### 12. Daily Menu History (`#/menu-history`, view `#/menu-history/:date`)
- A list with a date range defaulting to the last 30 days and a Cuisine filter.
- Columns per spec. The B/L/D item counts show as meal-tinted numbers, and an empty meal shows as `–`.
- **View** reuses the Daily Menu Editor component with `readOnly: true`.

### 13. Mess Billing – Counter (`#/counter`, kiosk layout)
State machine in `Alpine.store('counter')`:
```
idle ──tap──▶ resolving ──ok──▶ loaded ──F10──▶ saving ──▶ printed (1.2s) ──▶ idle
                 │                  │ tap (other card) → resolving (replaces invoice)
                 └──fail──▶ error (banner + beep; auto-clears on next tap or Esc)
```
- **Idle:**
  - a large "Tap card" target with the reader illustration;
  - the masked last-read field;
  - the meal timeline in the header;
  - focus is pinned to the hidden RFID input, re-focused on any blur unless a dialog is open.
- **Resolving:** the validation order follows the spec table. Each failure produces its exact message:
  - "Card not registered"
  - "Membership inactive"
  - "Membership expired on 29-09-2026"
  - "No meal service now. Next: Dinner 19:00"
  - "Menu not set for Kerala – Dinner"
  - "Already served Lunch at 13:05 (L-0151)"
- **Loaded:**
  - Member card: photo or avatar, name, code, cuisine, Valid To with ✓, and today's B/L/D pips.
  - Invoice grid: #, Item, Qty, Rate 0.00, Amount 0.00, Total 0.00. Lines are read-only.
- **Error:**
  - full-width danger banner at 36 px with the icon and the error beep;
  - the invoice stays empty;
  - for "Already served", a `Supervisor override` button opens the password prompt and reason, then loads the invoice with an "Override" badge.
- **Supervisor override** also allows removing a line, via a row action that appears only after authentication. The override is recorded on the bill.
- **Save (F10):**
  1. Create the bill and assign the next token for the day and meal.
  2. Play the token slip animation, showing the number at 96 px in the meal colour.
  3. Show the toast "Token L-0188 printed".
  4. Print if "Print to device" is on.
  5. Reset to idle and update "Last token".
- **Esc** clears. A **header session counter** shows "Served this meal: 142".
- **Leaving** the counter requires the `‹ Leave` button or Ctrl+Shift+L, which prevents accidental exits.

### 14. Mess Token (KOT) Print Layout (preview `#/bills/:voucher/token`)
- The slip follows the spec layout exactly, in monospace, with 58 mm and 80 mm toggles and a `DUPLICATE` line on reprints.
- The company name comes from config.
- `@page { size: 80mm auto; margin: 0 }` (or 58mm), black on white in every skin.

### 15. Mess Bill Register (`#/bills`)
- **Filters:** date range, Meal, Cuisine picker, Customer picker.
- **Columns** per spec:
  - Override shows as an icon with a tooltip naming the supervisor;
  - cancelled rows are shown struck through in Ink-2 with a "Cancelled" badge, and are included here but never in reports.
- **Row actions:**
  - `View` opens a read-only sheet with the lines;
  - `Reprint token` marks the slip DUPLICATE;
  - `Cancel bill` is supervisor only, requires a reason, and greys out with a tooltip for other roles.

### 16. Members Register Report (`#/reports/members`)
- **Extra filters:** Status (Active / Expired / Expiring in N days with an N input / Inactive), Registered between.
- **Columns** per spec, with Days Left right-aligned (negative numbers in danger).
- **Totals panel:** count by status and by cuisine, as two compact tables (no pie charts).

### 17. Cuisine × Meal Headcount (`#/reports/headcount`)
- **Matrix:** cuisine rows × Breakfast / Lunch / Dinner / Total, with grand totals.
- Each cell is **tinted with the meal's soft colour**, scaled by value (a heat map within each column), and its number is always printed.
- The `Group by date` option adds date as the outer row group (Tabulator groups, with group totals).
- **Drill-down:** clicking a cell opens the drawer with that cell's token list.

### 18. Item-wise Movement (`#/reports/items`)
- **Extra filter:** Item picker (no cuisine filter).
- Columns per spec, with the B/L/D qty column headers meal-tinted.
- Options `Group by cuisine` / `Group by date`.
- **Drill-down:** an item opens date-wise quantities as a small ApexCharts stacked column chart (B/L/D) above the table.

### 19. Customer-wise Attendance (`#/reports/attendance`)
- **Extra filters:** Customer picker and `Show only absentees`.
- **Summary view:** columns per spec.
- **Detail view:** a calendar grid (custom CSS grid, sticky first column and header).
  - Each cell holds three tiny pips in B/L/D order, filled with the meal colour when taken and hollow when not.
  - Each pip carries its letter for screen readers, and in a tooltip ("Lunch 13:05, L-0151").
  - Weekends are lightly shaded.
- **Drill-down:** a customer opens their token list with times.

### 20. Time-based Report (`#/reports/time`)
- **Extra filter:** Interval segmented 15 / 30 / 60 min.
- **Time-slot view:**
  - ApexCharts columns for each meal window, in the meal colour;
  - the **peak slot** is marked with an annotation and a bold table row;
  - the table below gives Slot, Tokens and % of meal.
- **Hourly by date view:** an ApexCharts heat map (dates × hours) on a single-hue ink scale, with meal windows drawn as background bands.
- **Summary strip:** first token, last token, peak slot and average per slot for each meal. These are plain table rows, not KPI cards.

### Extras
- `#/widgets`: the widget gallery for screens 3, 6 and 9.
- `#/styleguide`: every component in the current skin and mode, used for QA screenshots.

---

## 11. Keyboard map

| Scope | Keys |
|---|---|
| Global | Ctrl+K command palette · Ctrl+Shift+D demo panel · Alt+1…9 jump to nav items · Ctrl+Shift+T cycle skin · Ctrl+Shift+M toggle dark |
| Lists | `/` focus search · ↑/↓ rows · Enter open · N new · Delete delete · Ctrl+E export |
| Editors | Ctrl+S save · Ctrl+Shift+S save & new · Esc cancel (with guard) |
| Search widget | ↑/↓ · Enter select · Esc close · F2 full list in pick mode |
| Daily menu | Alt+←/→ previous/next date · Ctrl+1/2/3 meal tab · Ctrl+↑/↓ previous/next cuisine · Ctrl+Enter add all mapped |
| Counter | F10 save & print · Esc clear · F8 supervisor override · Ctrl+Shift+L leave |
| Reports | Ctrl+Enter generate · Ctrl+P print |

A `?` key on any screen opens a sheet listing that screen's shortcuts.

---

## 12. Motion plan

| Moment | Trigger | Treatment | Reduced motion |
|---|---|---|---|
| **Token slip** (the signature moment) | Save at counter | Slip slides 0→100 % out of the slot (260 ms, ease-out), the number scales 0.96→1, holds 1.2 s, then fades out | Instant show, 1.2 s hold, instant hide |
| Error banner | Failed tap | 120 ms drop-in plus a single 6 px shake | No shake, instant |
| Theme switch | Click | Circular View Transition reveal from the control (400 ms) | Instant |
| Screen change | Route | 160 ms cross-fade | Instant |
| Row add/remove | User action | AutoAnimate (180 ms) | Disabled |
| RFID listening | Capture click | Slow ring pulse while listening | Static ring + text |
| Pressed controls | Pointer down | Skin `--press` (clay sinks, glass brightens, flat dims) | Same (not motion) |

Nothing animates on load except the token slip; there are no entrance animations on sections and no hover lifts.

---

## 13. Responsive and accessibility

- **Breakpoints:**
  - ≥1440 wide;
  - 1280 standard (counter PC);
  - 1024 tablet (rail sidebar; billing stacks the member card above the invoice);
  - 768 (drawer nav; grids switch to stacked cards for lists only);
  - 390 phone (lists, editors and reports usable; the counter shows "Use a screen at least 1024 px wide").
- **Contrast:**
  - text 4.5:1 and UI components 3:1, checked for all six skin × mode combinations (§14);
  - glass dense content sits on glass strong.
- **Focus and semantics:**
  - a visible focus ring per skin (`--focus-ring`), never removed;
  - landmarks (`nav`, `main`, `header`), `aria-live="assertive"` for counter banners, `aria-live="polite"` for toasts;
  - grids keep Tabulator's keyboard navigation, and custom grids (attendance) use `role="grid"` with roving tabindex.
- **Preferences:** `prefers-reduced-motion`, `prefers-reduced-transparency` and `prefers-contrast: more` (thicker strokes, opaque glass) are all honoured.
- **Colour:** never the only signal. Meals always carry an icon or letter, and errors carry an icon and text.

---

## 14. QA and acceptance

**Definition of done (per screen)**
1. Matches the spec section fields, columns, buttons, rules and messages, using the exact message text from the spec.
2. Works with keyboard only.
3. Renders in all 6 skin × mode combinations; screenshots captured into `mock-ui/qa/<screen>/<skin>-<mode>.png`.
4. Has empty, error and read-only states where applicable.
5. Throws no console errors and leaves no failing `integrity.js` checks.
6. Is responsive at 1366, 1024 and 390 widths.

**Cross-browser:** Chrome and Edge (primary), Firefox, Safari. The Qt team may later embed the mock in QtWebEngine (Chromium), so Chrome is the reference.

**Performance:**
- first paint < 1 s from `file://`;
- data generation < 300 ms;
- Bill Register with all ~4.5k rows filters in < 100 ms;
- skin switch < 100 ms.

**Demo script** (README, about 10 minutes):
1. Today screen.
2. Open the Counter at Lunch, tap Rahul, then F10 to see the token.
3. Tap Maria to get "Already served", then a supervisor override.
4. Tap Imran to get "Expired".
5. Move the clock to Dinner and tap Arjun to get "Menu not set".
6. Open the Daily Menu Editor and add Kerala dinner with `Add all mapped`, then Save.
7. Return to the Counter and tap Arjun again, which now succeeds.
8. Open the Cuisine Editor and try to unmap Sambar, which is blocked.
9. Run the reports: Headcount, then drill into a cell; then Attendance in calendar view.
10. Switch through all three skins in light and dark.

---

## 15. Risks and mitigations

| Risk | Mitigation |
|---|---|
| `backdrop-filter` is slow on low-end counter PCs | The glass skin reduces blur to 12 px when `navigator.hardwareConcurrency ≤ 4`. Opaque fallback toggle in the demo panel. |
| Tabulator theming fights three skins | Override only through custom properties in one `vendor-theme/tabulator.css`, and verify on the styleguide page first (task T-016). |
| `file://` restrictions (fonts, downloads) | Classic scripts only. Fonts load from relative URLs, which Chrome/Edge allow. The README also documents `python -m http.server` as a fallback. |
| Generated data feels random | Seeded PRNG, realistic per-meal probabilities, a peak-shaped time distribution and fixed scenario members. |
| Clay turns into a "card soup" | Radius hierarchy, one inset well per table, and a review of every screen in the clay skin before sign-off (task T-093). |
| Scope creep from extras (palette, home) | They are marked "Extra" in the register and come after all 20 spec screens are done. |

---

## 16. Milestones

| Milestone | Contents | Tasks |
|---|---|---|
| M0 Foundation | Folder, vendoring, fonts, tokens, three skins, theme switcher, styleguide | T-001 – T-019 |
| M1 Core and data | Stores, router, services, shell, demo panel, sample data and generators | T-020 – T-039 |
| M2 Shared components | Pickers, grid, list, editor and report frames, dialogs, dual pane | T-040 – T-049 |
| M3 Masters | Screens 1–9 plus the widget gallery | T-050 – T-059 |
| M4 Operations | Today, Meal times, Daily menu, History | T-060 – T-069 |
| M5 Billing | Counter, token, Bill Register | T-070 – T-079 |
| M6 Reports | Screens 16–20 | T-080 – T-089 |
| M7 QA and polish | Responsive, a11y, cross-browser, screenshots, performance, README, demo | T-090 – T-099 |

The detailed tasks, dependencies, estimates and acceptance checks are in [Mess_MockUI_Tasks_Register.md](Mess_MockUI_Tasks_Register.md).
