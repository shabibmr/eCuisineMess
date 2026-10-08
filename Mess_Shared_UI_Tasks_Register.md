# Mess Module – Shared UI Components & Material 3 Refactoring Plan

| | |
|---|---|
| Master Plan | [implementation_plan.md](implementation_plan.md) |
| Target Branch | `ui/redesign-material3` |
| Scope | Flutter `ecuisine_mess/lib/shared/widgets/` & feature presentation refactoring |
| Task IDs | UI-101 – UI-125 |

**Status legend:** `To do` · `Doing` · `Review` · `Done` · `Blocked`

---

## 1. Architectural Strategy & Objectives

1. **DRY & Unified UX**: Eliminate duplicate UI implementations across all feature pages (search inputs, date/time pickers, modal forms, status badges, action buttons, KPI cards, and separated list cards).
2. **Material 3 Alignment**: Adhere strictly to Material 3 design tokens, typography, surfaces, and interactive states.
3. **Pure Presentational Components**: Extracted shared widgets are purely presentational and interact via standard Flutter callbacks (`onChanged`, `onSubmitted`, `onPressed`) and value notifiers, maintaining loose coupling.
4. **Zero Regressions**: Business logic (BLoCs, Cubits, UseCases, Services) is untouched; refactoring is strictly confined to presentation layers.

---

## 2. Target Directory Structure

```
ecuisine_mess/lib/shared/widgets/
├── badges/
│   └── app_status_badge.dart            # Active, Inactive, Expired, Suspended, Served, Cancelled, Locked, Unsaved
├── buttons/
│   ├── app_save_button.dart             # Submit button with built-in loading spinner
│   ├── app_create_button.dart           # Standard '+' icon action button
│   ├── app_refresh_button.dart          # Standard tooltip refresh button
│   └── app_danger_button.dart           # Destructive/red confirm button
├── dialogs/
│   ├── app_confirm_dialog.dart          # Warning/delete confirmation modal
│   └── app_form_dialog.dart             # Responsive form modal container with validation
├── feedback/
│   ├── app_alert_banner.dart            # In-page error, warning, info, success banners
│   └── app_empty_state.dart             # Centered empty/inbox view with action CTA
├── inputs/
│   ├── app_search_field.dart            # Search field with search icon & clear button
│   ├── app_date_picker_field.dart       # Read-only clickable field launching datepicker
│   ├── app_time_picker_field.dart       # HH:mm field launching timepicker
│   ├── app_dropdown.dart                # Generic DropdownButtonFormField<T> wrapper
│   ├── app_password_field.dart          # Obscure toggle textfield with eye icon
│   └── app_switch_tile.dart             # Zero-padding active/inactive switch list tile
├── tables/
│   ├── app_data_table.dart              # Generic desktop-optimized DataTable with scrollbars
│   ├── app_separated_list_card.dart     # Card + ListView.separated wrapper
│   └── app_kpi_card.dart                # Metric stat card with colored accent bar
├── layout/
│   ├── app_shell.dart                   # (Existing) App shell & navigation
│   └── master_page.dart                 # (Consolidated) Page scaffolding
└── dual_pane_list.dart                  # (Existing) Dual-pane available/mapped transfer list
```

---

## 3. Tasks Register

| ID | Task | Depends | Scope | Est (h) | Status | Done When |
|---|---|---|---|---|---|---|
| **UI-101** | Create `AppStatusBadge` | None | `lib/shared/widgets/badges/app_status_badge.dart` | 1.0 | To do | Supports Active, Inactive, Expired, Suspended, Served, Cancelled, Locked, Unsaved with consistent colors & borders |
| **UI-102** | Create `AppSaveButton` & `AppDangerButton` | None | `lib/shared/widgets/buttons/` | 1.0 | To do | Button supports `isLoading` (spinner), icon, label, and destructive red styling |
| **UI-103** | Create `AppCreateButton` & `AppRefreshButton` | None | `lib/shared/widgets/buttons/` | 0.5 | To do | Standardized `FilledButton.icon` with '+' and `IconButton` with refresh tooltip |
| **UI-104** | Create `AppSearchField` | None | `lib/shared/widgets/inputs/app_search_field.dart` | 1.0 | To do | Prefix search icon, clear button suffix on input, debounce / callbacks |
| **UI-105** | Create `AppDatePickerField` & `AppTimePickerField` | None | `lib/shared/widgets/inputs/` | 1.5 | To do | Formats `yyyy-MM-dd` and `HH:mm`, launches pickers, optional clear button |
| **UI-106** | Create `AppDropdown<T>` & `AppSwitchTile` | None | `lib/shared/widgets/inputs/` | 1.0 | To do | Replaces ad-hoc `DropdownButtonFormField` with optional placeholder & zero-pad switches |
| **UI-107** | Create `AppPasswordField` | None | `lib/shared/widgets/inputs/app_password_field.dart` | 0.5 | To do | Includes built-in password visibility toggle icon |
| **UI-108** | Create `AppAlertBanner` & `AppEmptyState` | None | `lib/shared/widgets/feedback/` | 1.0 | To do | Unifies `ErrorBanner`, `RejectBanner`, `MenuStatusBanners`, and inbox empty views |
| **UI-109** | Create `AppConfirmDialog` | UI-102 | `lib/shared/widgets/dialogs/app_confirm_dialog.dart` | 1.0 | To do | Returns `Future<bool>`, replaces `_confirmDelete` in cuisines & organizations |
| **UI-110** | Consolidate & Enhance `AppFormDialog` | None | `lib/shared/widgets/dialogs/app_form_dialog.dart` | 1.0 | To do | Responsive width (420-560px), scrollable body, single source of truth |
| **UI-111** | Create `AppSeparatedListCard` & `AppKpiCard` | None | `lib/shared/widgets/tables/` | 1.5 | To do | Standard Card + ListView.separated + Divider; Stat card with accent border & tabular figures |
| **UI-112** | Refactor `ItemCategoryListPage` | UI-101, UI-103, UI-106, UI-110, UI-111 | `features/item_categories/` | 1.0 | To do | Uses shared list card, form dialog, status badge, and buttons |
| **UI-113** | Refactor `ItemListPage` | UI-101, UI-103, UI-106, UI-110, UI-111 | `features/items/` | 1.0 | To do | Uses shared list card, dropdowns, form dialog, status badges |
| **UI-114** | Refactor `OrganizationListPage` | UI-101, UI-103, UI-104, UI-109, UI-110 | `features/organizations/` | 1.5 | To do | Uses `AppSearchField`, `AppConfirmDialog`, `AppFormDialog`, and `AppStatusBadge` |
| **UI-115** | Refactor `MemberListPage` | UI-101, UI-103, UI-104, UI-105, UI-106, UI-111 | `features/members/` | 1.5 | To do | Uses `AppSearchField`, `AppDatePickerField`, `AppDropdown`, and `AppSeparatedListCard` |
| **UI-116** | Refactor `CuisineListPage` & `CuisineEditorPage` | UI-101, UI-102, UI-104, UI-106, UI-108, UI-109 | `features/cuisines/` | 2.0 | To do | Uses `AppSearchField`, `AppStatusBadge`, `AppSaveButton`, `AppConfirmDialog`, `AppAlertBanner` |
| **UI-117** | Refactor `MealTimeSettingsPage` & `MealTimeRow` | UI-101, UI-102, UI-105, UI-106, UI-109 | `features/meal_times/` | 1.5 | To do | Uses `AppTimePickerField`, `AppSwitchTile`, `AppDropdown`, `AppSaveButton`, `AppConfirmDialog` |
| **UI-118** | Refactor `BillListPage` & `BillFiltersBar` | UI-101, UI-104, UI-105, UI-106, UI-109, UI-111 | `features/bills/` | 1.5 | To do | Uses `AppSearchField`, `AppDropdown`, `AppDatePickerField`, `AppSeparatedListCard`, `AppConfirmDialog` |
| **UI-119** | Refactor `CounterPage` widgets | UI-102, UI-104, UI-108 | `features/counter/` | 1.0 | To do | Uses `AppAlertBanner` for reject banner and `AppSaveButton` in action bar |
| **UI-120** | Refactor `DailyMenuEditorPage` widgets | UI-101, UI-102, UI-105, UI-108 | `features/daily_menu/` | 1.5 | To do | Uses `AppDatePickerField`, `AppSaveButton`, and `AppAlertBanner` |
| **UI-121** | Refactor `DashboardPage` widgets | UI-111 | `features/dashboard/` | 1.0 | To do | Replaces `_KpiTile` with `AppKpiCard` |
| **UI-122** | Refactor `ReportsPage` & `PeriodFilters` | UI-105, UI-106, UI-108, UI-111 | `features/reports/`, `shared/widgets/reports/` | 1.5 | To do | Refactors `ReportDateField` and `ReportDropdown` to use root shared widgets |
| **UI-123** | Refactor `LoginForm` & Settings Dialogs | UI-102, UI-107 | `features/auth/`, `features/settings/`, `features/email/` | 1.0 | To do | Uses `AppPasswordField` and `AppSaveButton` across login & settings dialogs |
| **UI-124** | Clean up duplicate legacy files | UI-110, UI-112–UI-123 | `lib/widgets/` | 0.5 | To do | Remove redundant `lib/widgets/app_form_dialog.dart` and `lib/widgets/master_page.dart` |
| **UI-125** | Run analysis & regression tests | UI-112–UI-124 | Entire project | 1.0 | To do | `flutter analyze` passes with 0 issues; `flutter test` passes 100% |
