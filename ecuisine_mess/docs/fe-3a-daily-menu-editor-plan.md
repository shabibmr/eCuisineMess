# FE-3a — Daily Menu Editor

**Status:** **Complete** (FE-3 full milestone T-656–T-665 Done).  
**Approved:** Editor-first slice (user 2026-10-06).  
**Scope:** Flutter `ecuisine_mess/` only. Backend menus APIs already live.  
**Out of scope this slice:** Menu History (T-663+), reports, dashboard, roles.

Register: **T-656 – T-662**. History remainder **T-663 – T-665** later.

Root [`implementation_plan.md`](../../implementation_plan.md) stays the master index.

## Mirror

`features/cuisines/**`, `features/meal_times/**`, `features/bills/**`.  
Domain = pure Dart. Dio + get_it + GoRouter.  
Mapped items for picker / Add all: reuse `GetCuisine` / cuisine `items[]` (BR-D8).

## Files

| Action | Path |
|---|---|
| [MODIFY] | `lib/core/network/api_endpoints.dart` — menus paths |
| [NEW] | `lib/features/daily_menu/**` — domain/data/presentation |
| [MODIFY] | `injection.dart`, `app_routes.dart`, `app_router.dart`, `nav_destinations.dart` |
| [MODIFY] | `Mess_Flutter_Tasks_Register.md` / `.csv` |
| [KEEP] | No legacy menu screen to delete |

## API

| Method | Path | Use |
|---|---|---|
| GET | `/menus?menu_date=` | Load day slots + items |
| GET | `/menus/status?menu_date=` | Cuisine sidebar readiness |
| POST | `/menus/save-day` | Atomic whole-day save |
| POST | `/menus/copy` | Copy from date |
| POST | `/menus/copy-meal` | Cross-cuisine meal copy |
| GET | `/menus/history?…` | Deferred (History slice) |
| GET | `/cuisines/{id}` | Mapped items for picker / Add all |

`409`: `PAST_DATE_READ_ONLY`, `MENU_LOCKED`, `UNMAPPED_ITEM`, `DUPLICATE_MENU_ITEM`.

## UX

Date bar (Prev/picker/Next/Today); Copy From Date; History stub; Reset; Save Menu.  
Past read-only banner. Cuisine sidebar status ✓/◐/○. Meal tabs B/L/D + locked banner.  
Item grid (mapped-only, qty, remove, duplicate guard). Add all mapped. Copy to other cuisines. Unsaved guard.

## Tasks

| ID | Task | Status |
|---|---|---|
| T-656 | ApiEndpoints + FE-3 register rows | Done |
| T-657 | daily_menu domain + usecases | Done |
| T-658 | data layer | Done |
| T-659 | DailyMenuEditorBloc | Done |
| T-660 | DailyMenuEditorPage + widgets | Done |
| T-661 | DI + `/menu` route + nav | Done |
| T-662 | analyze/test; FE-3a Done; proceed to History | Done |

## FE-3b — History (T-663–T-665)

| ID | Task | Status |
|---|---|---|
| T-663 | MenuHistoryBloc + MenuHistoryPage (`/menu/history`) | Done |
| T-664 | History read-only view + Copy to date into editor | Done |
| T-665 | Docs/register: FE-3 full milestone Done | Done |

## Verify (end of FE-3)

`cd ecuisine_mess`; `flutter analyze` clean; `flutter test` green (44 tests pass); `/menu` editor and `/menu/history` work. Milestone FE-3 complete.
