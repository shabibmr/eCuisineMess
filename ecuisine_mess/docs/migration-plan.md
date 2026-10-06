# Migration Plan — Provider/layer-first → BLoC/GoRouter/feature-first

Current `lib/` (layer-first, `provider`, `MaterialApp(home:)`):

```
config/{api_config,app_theme}.dart
models/{bill,cuisine,item,item_category,member,rfid_tap_result,user}.dart
navigation/app_destinations.dart
providers/{auth_provider,counter_provider}.dart
screens/{bill_register,counter_kiosk,cuisines,items,item_categories,login,main_layout,members,reports}_screen.dart
services/api_service.dart
widgets/{app_form_dialog,master_page,rfid_tap_simulator,server_settings_dialog,supervisor_override_dialog,token_slip_dialog}.dart
main.dart
```

Strategy: **strangler migration**, feature by feature, app stays runnable at every step. Old and new code coexist until the last feature moves; then the old folders are deleted.

## Step 0 — Prep (½ day)
- [ ] Branch `feature/flutter-bloc-migration`.
- [ ] Add deps ([README](README.md)): `flutter_bloc, equatable, go_router, get_it, dio, bloc_concurrency, window_manager`, dev: `bloc_test, mocktail`. Remove `provider`/`http` **only at the end**.
- [ ] `analysis_options.yaml`: enable `always_use_package_imports`, `prefer_const_constructors`, `avoid_print`, `unawaited_futures`.
- [ ] Create skeleton dirs per [folder-structure](folder-structure.md).
- [ ] Remove the unsupported platform folders if desired (`android ios web linux macos`).

## Step 1 — Core (1 day) → P0
Move/rewrite:

| Old | New |
|---|---|
| `config/api_config.dart` | `core/config/app_config.dart` |
| `config/app_theme.dart` | `core/theme/*` (+ tokens, dark) |
| `services/api_service.dart` (`_send`, `ApiException`, Bearer, 401) | `core/network/api_client.dart` + interceptors + `core/error/*` |
| `navigation/app_destinations.dart` | `core/router/nav_destinations.dart` |
| — | `core/di/injection.dart`, `core/router/app_router.dart`, `core/usecase/usecase.dart`, `shared/models/meal_type.dart` |

Gate: app boots to a placeholder `MaterialApp.router`; `flutter analyze` clean.

## Step 2 — Shared widgets (1–2 days)
| Old | New |
|---|---|
| `widgets/master_page.dart` | `shared/widgets/layout/master_page.dart` |
| `widgets/app_form_dialog.dart` | `shared/widgets/layout/form_dialog.dart` |
| `widgets/token_slip_dialog.dart` | `shared/widgets/print/token_slip.dart` + `token_slip_dialog.dart` (split slip from dialog) |
| `widgets/server_settings_dialog.dart` | `features/settings/presentation/widgets/server_settings_dialog.dart` |
| `widgets/supervisor_override_dialog.dart` | `features/counter/presentation/widgets/supervisor_override_dialog.dart` |
| `widgets/rfid_tap_simulator.dart` | `features/counter/presentation/widgets/rfid_tap_simulator.dart` (debug-only) |
| `screens/main_layout.dart` | `shared/widgets/layout/app_shell.dart` + `nav_rail.dart` |

New: `ErrorBanner`, `ConfirmDialog`, `StatusChip`, `MealBadge`, `AppDataTable`, `EntitySearchPicker`, `EmptyState`.

## Step 3 — `auth` + `settings` (1 day)
- `models/user.dart` → `auth/domain/entities/app_user.dart` + `auth/data/models/user_model.dart`.
- `providers/auth_provider.dart` → `AuthBloc` (+ events/states files) + `RestoreSession/Login/Logout` use cases.
- `screens/login_screen.dart` → `LoginPage` + `LoginForm`.
- Wire GoRouter guard + `GoRouterRefreshStream`.
- **Delete** `providers/auth_provider.dart`, `screens/login_screen.dart`, `ApiConfig` usages.
- Gate: login/logout/session-restore/401 redirect work (port the existing widget test).

## Step 4 — `item_categories` (½ day) — smallest vertical slice, use as the template
`models/item_category.dart` + the category calls in `api_service.dart` + `screens/item_categories_screen.dart` → full `data/domain/presentation` with `ItemCategoryListBloc`. Validate the pattern with the team before continuing.

## Step 5 — `counter` (2 days) → with P1 backend fixes
- `models/rfid_tap_result.dart`, `models/bill.dart` → `counter/domain/entities` (`TapResult` sealed, `IssuedBill`) + `data/models`.
- `providers/counter_provider.dart` → `CounterBloc` (+ `MealClockCubit`).
- `screens/counter_kiosk_screen.dart` → `CounterPage` + `CounterHeader`, `RfidInputField`, `MemberCard`, `TodayMealStrip`, `InvoiceGrid`, `RejectionBanner`, `CounterActionBar`.
- Add shortcuts (F10/Esc/F8/Ctrl+Shift+L), focus manager, sounds.
- Gate: counter test list in [testing §2](testing.md) passes; manual run with simulator + real MariaDB.

## Step 6 — `bills`, `members`, `cuisines` (2–3 days)
Port list screens first (parity), then add editors/filters per [feature-catalog](feature-catalog.md). Replace `screens/bill_register_screen.dart`, `members_screen.dart`, `cuisines_screen.dart`, models `member.dart`, `cuisine.dart`, `bill.dart`.

## Step 7 — `reports` (parity) (1 day)
Port the two existing basic reports into `reports/` with `ReportFrame`; the other three come in P4.

## Step 8 — Cleanup (½ day)
- [ ] Delete `models/ providers/ screens/ services/ widgets/ navigation/ config/` (old).
- [ ] Remove `provider` and `http` from `pubspec.yaml`.
- [ ] Update root `README.md` architecture tree and `SYSTEM_OVERVIEW.md` "Flutter" section.
- [ ] `flutter analyze`, `flutter test`, `flutter build windows --release`, manual smoke on Windows.

## Mapping checklist (old → new)

| Old file | New home | Done |
|---|---|---|
| `models/user.dart` | `features/auth/{domain/entities,data/models}` | ☐ |
| `models/item_category.dart` | `features/item_categories/…` | ☐ |
| `models/item.dart` | `features/items/…` | ☐ |
| `models/cuisine.dart` | `features/cuisines/…` | ☐ |
| `models/member.dart` | `features/members/…` | ☐ |
| `models/bill.dart` | `features/bills/…` (+ counter `IssuedBill`) | ☐ |
| `models/rfid_tap_result.dart` | `features/counter/…` | ☐ |
| `providers/auth_provider.dart` | `features/auth/presentation/bloc/auth_bloc.dart` | ☐ |
| `providers/counter_provider.dart` | `features/counter/presentation/bloc/counter_bloc.dart` | ☐ |
| `services/api_service.dart` | split into each feature's datasource + `core/network` | ☐ |
| `config/api_config.dart` | `core/config/app_config.dart` | ☐ |
| `navigation/app_destinations.dart` | `core/router/nav_destinations.dart` | ☐ |
| `screens/*` | `features/*/presentation/pages` (+ `widgets`) | ☐ |
| `widgets/*` | `shared/widgets/*` or feature widgets (see Step 2) | ☐ |

## Rules during migration

- Every PR leaves `flutter run -d windows` working.
- No new code in the old folders. Bug fixes in old code are allowed only if the feature isn't migrated yet.
- Contract-first: if the backend lacks an endpoint a feature needs, build the datasource against [04](../../docs/04-api-contract.md) and stub with a fake datasource behind `get_it` until the API lands.
- Migrate **tests with the code** (the two existing tests move to `test/core/…` and `test/features/auth/…`).
- One feature per PR; reviewer checks the [anti-patterns](state-management-bloc.md#8-anti-patterns-reject-in-review) and the layer import rules.
