# FE-4a Dashboard — Tasks Register

Plan: `ecuisine_mess/docs/fe-4a-dashboard-plan.md` · IDs T-666 – T-680 (the FE-4 range in `Mess_Flutter_Tasks_Register.md`)

**Status markers:** ⬜ To do · 🟡 In progress · ✅ Done · ⛔ Blocked · ➖ Dropped

**Progress:** 15 / 15 done · Plan status: Implemented

## Phase A — Backend
| ID | Status | Task | Depends | Est (d) | Done when |
|---|---|---|---|---|---|
| T-666 | ✅ | Add `served_by_cuisine` to `backend_api/routers/dashboard.py` (SERVED bills today, active cuisines incl. zero rows) | - | 0.5 | Summary returns per-cuisine B/L/D/total; existing keys unchanged |
| T-667 | ✅ | Extend `test_dashboard_summary` in `backend_api/tests/test_reports.py` | T-666 | 0.25 | `python backend_api/run_tests.py` green |
| T-668 | ✅ | Update `backend_api/docs/api-reference.md` §7 and `docs/04-api-contract.md` §12 (add `current_window`, `next_window`, `status`, `filled_count`, `served_by_cuisine`; mark ✅) | T-666 | 0.25 | Docs match the response |

## Phase B — Flutter data/domain
| ID | Status | Task | Depends | Est (d) | Done when |
|---|---|---|---|---|---|
| T-669 | ✅ | Domain: `DashboardSummary` entities (`ReadinessStatus`, `ServedToday`, `ServedByCuisine`), repository, `GetDashboardSummary` usecase | - | 0.5 | Compiles; no `data/` imports |
| T-670 | ✅ | Data: `DashboardSummaryModel` (defensive parsing), remote datasource, repository impl; `dashboardSummary` endpoint | T-669 | 0.75 | Model tests pass: null windows, num-as-string, missing `served_by_cuisine` |
| T-671 | ✅ | DI: `_registerDashboard()` in `core/di/injection.dart` | T-670 | 0.25 | `sl<DashboardBloc>()` resolves |

## Phase C — Presentation
| ID | Status | Task | Depends | Est (d) | Done when |
|---|---|---|---|---|---|
| T-672 | ✅ | `DashboardBloc` + events/state; 60 s auto-refresh; keep last data on refresh failure | T-671 | 0.75 | Bloc tests: success, failure, refresh keeps data |
| T-673 | ✅ | `DashboardPage` in `MasterPage` shell: loading, error + retry, manual refresh, responsive layout | T-672 | 0.5 | States render |
| T-674 | ✅ | `DashboardHeader` (title, date, current meal name, Open Counter / Daily Menu Editor actions) | T-673 | 0.25 | Matches mock; no raw `B/L/D` code |
| T-675 | ✅ | `MealTimeline` using meal-time data and `MealClockCubit` (move shared widget to `lib/shared/` if reused) | T-673 | 1.0 | Active / Next / Service Closed correct; now-marker moves |
| T-676 | ✅ | `ServedKpiRow` (Total, B, L, D tiles) | T-673 | 0.5 | Values match API |
| T-677 | ✅ | `MenuReadinessGrid` + tap → `/menu?date=&cuisine=&meal=` (verify the menu editor accepts the params; add support in `daily_menu` if not) | T-673 | 1.0 | Tap opens editor on the right slot |
| T-678 | ✅ | `ServedByCuisineTable` + "Report ↗" → `/reports` | T-673 | 0.5 | Rows and totals match API |

## Phase D — Routing
| ID | Status | Task | Depends | Est (d) | Done when |
|---|---|---|---|---|---|
| T-679 | ✅ | `/` route, first Home nav item, shell branch order and shortcut indices; `/counter` stays post-login default | T-673 | 0.5 | Login lands on `/counter`; Home opens `/` |

## Phase E — Verify and docs
| ID | Status | Task | Depends | Est (d) | Done when |
|---|---|---|---|---|---|
| T-680 | ✅ | Widget tests; `flutter analyze` + `flutter test`; manual run (light/dark, narrow width, API down, Service Closed); update plan status and `docs/implementation-plan.md` FE-4 | T-667, T-674–T-679 | 0.75 | Gate signed |

**Critical path:** T-666 → T-670 → T-671 → T-672 → T-673 → T-677 → T-679 → T-680

**Open items:** menu editor query-param support (T-677); FE-3 status mismatch between its plan header ("In Progress") and the register ("Done").
