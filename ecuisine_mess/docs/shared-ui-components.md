# Shared UI Components

Location: `lib/shared/widgets/`. These are **presentation-only**, stateless where possible, theme-driven (no hard-coded colours), and know nothing about BLoCs, repositories or Dio. Features compose them; they never fork them.

## 1. Rules

1. **No business logic** and **no feature imports.** Inputs are plain values + callbacks (`onChanged`, `onSearch`, `onSelected`).
2. Style only via `Theme.of(context)` + `AppTokens` ([theming](theming-and-design-tokens.md)).
3. Every component: keyboard accessible, visible focus, `Semantics`/tooltip for icon-only controls, 44 px min target.
4. Each has a **golden or widget test** and an entry in the **Widget Gallery** page (`/dev/gallery`, debug only) — mirrors mock-ui `widget-gallery.js`/`styleguide.js`.
5. Before writing a new widget in a feature, search here; promote after the **second** use.
6. API surface small and consistent: `required` data first, then callbacks, then optional style flags.

## 2. Catalogue

### Layout
| Component | Purpose | Key props |
|---|---|---|
| `AppShell` | Nav rail + content + top bar (user, theme, logout) | `navigationShell`, `destinations` |
| `NavRail` | Role-filtered destination rail with keyboard `Alt+n` | `destinations`, `selected`, `onSelect` |
| `PageScaffold` | Title, breadcrumb, actions, body; handles loading/error/empty slots | `title`, `actions`, `status`, `child` |
| `MasterPage` | List-screen chrome: toolbar (**New·Edit·Delete·Refresh·Export**), search box, *Show inactive*, table slot | `title`, `onNew`, `onRefresh`, `onSearch`, `onToggleInactive`, `table` |
| `FormDialog` / `showAppFormDialog` | Modal editor with Save / Save & New / Cancel, inline errors, dirty guard | `title`, `form`, `onSave`, `onSaveAndNew` |
| `SplitPane` | Resizable master/detail | `left`, `right`, `ratio` |

### Inputs
| Component | Notes |
|---|---|
| `AppTextField` | label, hint, `errorText`, `prefix/suffix`, mask option |
| `AppDropdown<T>` | Typed items, search for > 8 entries |
| `DateField` / `DateRangeField` | `dd-MM-yyyy` display, picker, min/max |
| `TimeField` | 24-h `HH:mm` |
| `QtyField` | Decimal ≥ 0, step buttons |
| `SearchField` | Debounced (300 ms), `/` focus shortcut, clear button |
| `ToggleField` | Active / switch with label |
| `RfidInputField` | Always-focused, hides text (`●●●●`), submits on Enter, auto-refocus |

### Pickers (search-as-you-type)
`EntitySearchPicker<T>` is the **generic** base: `searchFn(String) → Future<List<T>>`, `labelOf(T)`, `onSelected(T?)`, `initial`, `showNewEntry`, `onNew`, `pickModeRoute` (F2). Keyboard ↑/↓/Enter/Esc. Active-only by default. Thin wrappers:

| Wrapper | Row text | Matches |
|---|---|---|
| `ItemPicker` | `Name (Unit)` | name; optional `cuisineId` filter |
| `CuisinePicker` | `Name` | name |
| `MemberPicker` | `Name – Cuisine – Valid To` | name, RFID, phone; tap-card selects |

> Wrappers receive their `searchFn` from the **calling page** (which gets it from its own feature's use case) — this keeps `shared/` free of feature imports.

### Data display
| Component | Notes |
|---|---|
| `AppDataTable<T>` | Sortable columns, sticky header, row double-click/Enter → `onOpen`, selection, totals row, empty/loading/error states, striped/dense, column `cellBuilder`. Backed by `data_table_2` |
| `StatusChip` | `ACTIVE/EXPIRED/SUSPENDED/SERVED/CANCELLED` colour + icon |
| `MealBadge` | B / L / D with meal colour + icon (`wb_twilight`, `light_mode`, `nights_stay`) |
| `ActiveBadge` | Yes/No |
| `KpiTile` | Number + label + delta |
| `MaskedText` | `••••1234` helper |
| `EmptyState` | Icon + message + CTA |
| `MealTimeline` | 06:00–23:00 bar with one cuisine's windows (defaults 07–10, 12–15, 19–22) + live marker (dashboard, counter header) |

### Feedback
| Component | Notes |
|---|---|
| `ErrorBanner` | Full-width, danger colour, icon + text, optional action; used for counter rejections (`autoDismiss: false`) |
| `AppSnackbar.success/error/info` | Wraps `ScaffoldMessenger` |
| `ConfirmDialog` | `title, message, confirmLabel, destructive` → `Future<bool>` |
| `DeleteResultNotice` | Snackbar/dialog text from the server's `action`/`message` after a delete ("Item is in use — marked inactive") (BR-I3/C2/M7). Pre-delete confirmation uses `ConfirmDialog` |
| `LoadingOverlay` / `AppProgress` | |
| `UnsavedChangesDialog` | Save / Discard / Cancel |

### Reports
| Component | Notes |
|---|---|
| `ReportFrame` | `FilterBar` + Generate/Print/Export + grid slot + totals + drawer host |
| `FilterBar` | From/To, `CuisinePicker`, meal segmented control (All/B/L/D), extra slot |
| `TotalsRow` | |
| `DrillDownDrawer` | Right-side 2-level drawer (token list → voucher) |
| `HeatCell` | Meal-tinted count cell |

### Print / slip
| Component | Notes |
|---|---|
| `TokenSlip` | 58/80 mm monospace layout; props: company, token, meal, date/time, member name, cuisine, lines, counter, user, `duplicate` watermark |
| `TokenSlipDialog` | Slide-out preview, print button, auto-close, plays print cue |
| `PrinterService` (interface) | `printSlip(SlipData)`; implementations: `PreviewPrinter` (default), `EscPosPrinter`/`SpoolerPrinter` (P6) |

### Utilities (non-visual, `core/` or `shared/services/`)
`SoundPlayer` (success/error/print beeps; mutable), `FileExportService` (save CSV), `AppShortcuts` (intents), `Debouncer`.

## 3. Naming & API example

```dart
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone, this.icon});
  final String label; final StatusTone tone; final IconData? icon;   // StatusTone {success, warning, danger, neutral, info}
  // feature code maps domain status → tone:  StatusChip(label: m.status.label, tone: m.status.tone)
}
```
Domain → UI mapping extensions (`MemberStatus.tone`) live in the **feature's presentation layer**, not in `shared/`.

## 4. Mock-ui → Flutter component map

| mock-ui (`js/components`) | Flutter |
|---|---|
| `list-frame.js` | `MasterPage` |
| `editor-frame.js` | `FormDialog` / editor `PageScaffold` |
| `data-grid.js` | `AppDataTable` |
| `search-picker.js`, `pickers.js` | `EntitySearchPicker` + wrappers |
| `dual-pane.js` | `DualPaneList<T>` |
| `report-frame.js` | `ReportFrame` |
| `rfid-capture.js` | `RfidCaptureField` (members feature, built on `RfidInputField`) |
| `token-slip.js` | `TokenSlip` / `TokenSlipDialog` |
| `meal-timeline.js` | `MealTimeline` |
| `dialog.js` | `ConfirmDialog`, `InUseDialog`, `UnsavedChangesDialog` |
| `command-palette.js` | `CommandPalette` (global, `Ctrl+K`) |
| `demo-panel.js` | `DebugPanel` (debug builds only) |
