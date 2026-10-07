# FE-4a — POS Dashboard ("Today") Screen

**Status:** Implemented (manual GUI run pending)
**Tasks:** T-666+ in `Mess_Flutter_Tasks_Register.md` (rows to be added)
**Mirror:** `features/meal_times/` (layers, bloc shape), `features/counter` (`MealClockCubit`, meal strip)
**Mock reference:** `mock-ui/js/screens/home.js`, `mock-ui/js/components/meal-timeline.js`

## 1. Scope
Home screen at route `/` showing today's operations:
- Header: "Today's Operations", date, current service (meal **name**), quick actions (Open Counter → `/counter`, Daily Menu Editor → `/menu`).
- Meal timeline 06:00–22:30: window segments, now-marker, status (Active until HH:mm / Next in Xh Ym / Service Closed). Ticks and ranges come from meal-time data, not hardcoded.
- KPI tiles: Total, Breakfast, Lunch, Dinner (meal-colour accent).
- Menu readiness grid: active cuisines × B/L/D, state Full / Partial / Empty; tap opens menu editor at date + cuisine + meal.
- Served Today table: cuisine × B/L/D/Total, "Report ↗" → `/reports`.

## 2. Out of scope
Shortcut tiles, "members expiring" tile, charts, stock/sales figures (no backend data), role-specific content.

## 3. Decisions
- Backend `/dashboard/summary` is extended with `served_by_cuisine`.
- Dashboard is route `/` with a first Home nav item; **`/counter` remains the post-login default** (`AppRoute.defaultAuthenticated`).
- State: flutter_bloc; 60 s auto-refresh; reuse `MealClockCubit` for the now-marker (no second ticker).
- Do not copy mock defects: hardcoded times/ticks, raw `B/L/D` in header, undefined success/danger badge styles, dead bill-register link, mono font for numbers (use tabular figures).
- Colour: meal colours + danger only; light and dark.

## 4. Files
| Action | Path |
|---|---|
| MODIFY | `backend_api/routers/dashboard.py` — add `served_by_cuisine: [{cuisine_id, cuisine_name, BREAKFAST, LUNCH, DINNER, total}]` (SERVED bills today, active cuisines incl. zero rows) |
| MODIFY | `backend_api/tests/test_reports.py` — extend `test_dashboard_summary` |
| MODIFY | `backend_api/docs/api-reference.md` §7, `docs/04-api-contract.md` §12 (add `current_window`, `next_window`, `status`, `filled_count`, `served_by_cuisine`; mark ✅) |
| MODIFY | `lib/core/network/api_endpoints.dart` — `dashboardSummary` |
| MODIFY | `lib/core/di/injection.dart` — `_registerDashboard()` |
| MODIFY | `lib/core/router/{app_routes,app_router,nav_destinations}.dart` — `/` branch first; keep index order aligned; check `core/shortcuts` indices |
| NEW | `lib/features/dashboard/domain/entities/dashboard_summary.dart` (+ `ReadinessStatus`, `ServedToday`, `ServedByCuisine`) |
| NEW | `.../domain/repositories/dashboard_repository.dart`, `.../domain/usecases/get_dashboard_summary.dart` |
| NEW | `.../data/models/dashboard_summary_model.dart`, `.../data/datasources/dashboard_remote_datasource.dart`, `.../data/repositories/dashboard_repository_impl.dart` |
| NEW | `.../presentation/bloc/dashboard_{bloc,event,state}.dart` |
| NEW | `.../presentation/pages/dashboard_page.dart` |
| NEW | `.../presentation/widgets/{dashboard_header,meal_timeline,served_kpi_row,menu_readiness_grid,served_by_cuisine_table}.dart` |
| NEW | `test/features/dashboard/{dashboard_summary_model_test,dashboard_bloc_test}.dart` + widget tests |

If the counter's `TodayMealStrip`/timeline widgets are reused, move them to `lib/shared/` — no cross-feature presentation/data imports.

## 5. API
`GET /api/v1/dashboard/summary` → `server_time`, `current_meal`, `next_meal`, `current_window`, `next_window`, `served_today`, `menu_readiness[]`, `expiring_members_count` (unused here), `served_by_cuisine[]` (new). Parse defensively (nullable windows/meals, DECIMAL/num-as-string).

## 6. UX
- `MasterPage` shell with loading, error + retry, manual refresh. On refresh failure keep last data and show a banner.
- Layout: KPI row of 4; readiness (flex 2) + served (flex 1) side by side, stacking below ~900 px.
- Empty states: no active cuisines, no active meal ("Service Closed").
- Readiness cell tap → `/menu?date=&cuisine=&meal=`. **Verify the menu editor route accepts these params**; if not, add support in `features/daily_menu` as a sub-task.

## 7. Verify
1. `python backend_api/run_tests.py` green.
2. `flutter analyze` clean, `flutter test` green.
3. `flutter run -d windows`: login lands on `/counter`; Home nav shows `/` with correct data; issue a token, counts update within 60 s or on refresh; readiness tap opens the editor on the right slot.
4. Check light/dark, narrow width, API-down retry, Service Closed state.
