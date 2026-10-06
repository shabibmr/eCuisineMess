# Mess Module – Flutter Front-end Tasks Register

| | |
|---|---|
| Plan | [ecuisine_mess/docs/implementation-plan.md](ecuisine_mess/docs/implementation-plan.md) |
| Master | [implementation_plan.md](implementation_plan.md) |
| Approved | 2026-10-05 |
| Scope | Flutter `ecuisine_mess/` only. Backend listed as dependency. No mock-ui. No Frappe. |
| IDs | T-601+ (T-5xx = Items Done) |

**Status legend:** `To do` · `Doing` · `Review` · `Done` · `Blocked`

---

## Progress summary

| Milestone | Tasks | Status |
|---|---|---|
| FE-0 Foundations | T-601 – T-620 | **Done** |
| FE-1 Counter + Bills | T-621 – T-635 | **Done** |
| FE-2a Items + Members | T-636 – T-645 | **Done** |
| FE-2 Masters (remainder) | T-646 – T-655 | To do (Cuisines / Meal Times) |
| FE-3 Daily menu | T-656 – T-665 | To do |
| FE-4 Reports + Dashboard | T-666 – T-680 | To do |
| FE-5 Roles + Users | T-681 – T-690 | To do |
| FE-6 Polish | T-691 – T-700 | To do |

**Critical path:** T-601 → T-610 → T-615 → T-618 → T-620 → T-627 → T-631 → T-633 → T-635 → **T-645** → T-655

---

## FE-2a – Items + Members (partial FE-2)

| ID | Task | Depends | Est | Status | Done when |
|---|---|---|---|---|---|
| T-636 | ApiEndpoints: items, item(id), uoms, members, member(id), membersByRfid, cuisines | T-635 | 0.25 | Done | Endpoints compile |
| T-637 | `features/items` domain: Item/Uom entities, repo, GetItems/GetUoms/SaveItem/DeleteItem | T-636 | 0.75 | Done | UseCases compile |
| T-638 | Items data: models, Dio remote DS, repo impl (delete→deactivated parse) | T-637 | 0.75 | Done | List/create/update/delete via ApiClient |
| T-639 | ItemListBloc + ItemListPage (Active chip, category+UOM dialogs, Nos default) | T-638 | 1.0 | Done | UX parity with legacy ItemsScreen |
| T-640 | `features/members` domain: Member, CuisineOption, RFID check, usecases | T-636 | 0.75 | Done | UseCases compile |
| T-641 | Members data: models, remote DS (+ GET /cuisines lookup), repo impl | T-640 | 0.75 | Done | CRUD + by-rfid + cuisine list |
| T-642 | MemberListBloc + MemberListPage (search, add/edit, RFID Check, dates) | T-641 | 1.25 | Done | RFID conflict blocks save; expired highlight |
| T-643 | DI `_registerItems`/`_registerMembers`; routes; delete legacy screens | T-639,T-642 | 0.5 | Done | `/items` + `/members` feature pages |
| T-644 | `flutter analyze` + `flutter test` green | T-643 | 0.5 | Done | 0 issues; tests pass |
| T-645 | Docs/register: FE-2a Done; halt before Cuisines/Meal Times (T-646+) | T-644 | 0.25 | Done | Gate signed; FE-2 remainder To do |

**Paused:** T-646–T-655 Cuisines dual-pane mapping + Meal Times — do not start until asked.

---

## FE-1 – Counter + Bills (money path)

| ID | Task | Depends | Est | Status | Done when |
|---|---|---|---|---|---|
| T-621 | Add counter/bills/meal-window paths to `ApiEndpoints` | T-620 | 0.25 | Done | Endpoints compile |
| T-622 | Move token slip, supervisor dialog, RFID simulator under `shared/widgets` | T-620 | 0.5 | Done | Shared widgets used by features |
| T-623 | `core/shortcuts` — F10 save/print, F8 override, Esc clear, Ctrl+Shift+L exit | T-622 | 0.5 | Done | Shortcuts fire on CounterPage |
| T-624 | `features/counter` domain: TapResult/MealWindow entities, repo, usecases (tap, issue, meal window) | T-621 | 1.0 | Done | UseCases compile |
| T-625 | Counter data: remote DS via Dio, models, repo impl | T-624 | 1.0 | Done | Tap/issue/window via ApiClient |
| T-626 | CounterBloc + MealClockCubit (cosmetic clock; server owns meal) | T-625 | 1.0 | Done | States cover idle/loading/reject/ready/issued |
| T-627 | CounterPage: meal banner, RFID focus, error banners, today strip, member+invoice, action bar | T-626,T-623 | 1.5 | Done | UX matches docs/05 §3 |
| T-628 | `features/bills` domain: Bill entity, repo, list/get/cancel usecases | T-621 | 0.75 | Done | UseCases compile |
| T-629 | Bills data layer (list filters, get by id, cancel) | T-628 | 0.75 | Done | Dio list/get/cancel work |
| T-630 | BillListBloc with search/date/meal/status filters | T-629 | 0.75 | Done | Filter+refresh states |
| T-631 | Bill list page: filters, reprint slip, cancel + supervisor fields | T-630,T-622 | 1.0 | Done | List UX parity + filters |
| T-632 | Bill detail (drawer or `/bills/:id`) voucher view | T-629 | 0.5 | Done | Detail shows lines |
| T-633 | DI + routes; delete `CounterProvider`, legacy counter/bill screens; drop Provider from `app.dart` | T-627,T-631 | 0.5 | Done | App boots without CounterProvider |
| T-634 | Widget/unit tests + `flutter analyze` clean | T-633 | 0.75 | Done | analyze 0 issues; tests green |
| T-635 | FE-1 exit: docs/registers Done; plan status FE-1 Done | T-634 | 0.25 | Done | Gate signed in task.md |

---

## FE-0 – Foundations (BLoC + GoRouter + Auth + Settings + Categories)

| ID | Task | Depends | Est | Status | Done when |
|---|---|---|---|---|---|
| T-601 | Add target deps (`flutter_bloc`, `go_router`, `get_it`, `dio`, …); update `analysis_options.yaml` | – | 0.5 | Done | `flutter pub get` OK |
| T-602 | `core/config`, `core/error`, `core/usecase` | T-601 | 0.5 | Done | Failures + UseCase compile |
| T-603 | `core/network` Dio `ApiClient` + interceptors + endpoints | T-602 | 1.0 | Done | Login request works via Dio |
| T-604 | `core/di` get_it registrations | T-603 | 0.5 | Done | `configureDependencies()` runs |
| T-605 | `core/theme` (light Flat from existing) | T-601 | 0.25 | Done | Theme applied |
| T-606 | `core/router` routes + GoRouter + refresh stream + auth guard | T-604 | 1.0 | Done | `/login` ↔ shell redirect |
| T-607 | Shared layout: `AppShell`, `MasterPage`, `FormDialog`, banners | T-605 | 1.0 | Done | Shell shows nav |
| T-608 | `auth` feature: entities, datasource, repo, usecases, AuthBloc | T-603 | 1.0 | Done | Login/restore/logout/401 |
| T-609 | `auth` LoginPage + form | T-608 | 0.5 | Done | UI matches prior login |
| T-610 | Wire `main.dart` / `app.dart` to BLoC + router; bridge `ApiService.authToken` | T-606,T-608 | 0.5 | Done | App boots; old screens still auth'd |
| T-611 | `settings` ServerSettingsCubit + dialog (ping health) | T-603 | 0.5 | Done | URL save updates Dio + prefs |
| T-612 | `item_categories` data/domain/presentation (template slice) | T-603,T-607 | 1.5 | Done | List + add/edit via BLoC |
| T-613 | Route `/item-categories` → new page; legacy screens as shell children | T-610,T-612 | 0.5 | Done | Nav opens new categories |
| T-614 | Port `api_config_test` + auth widget test to new stack | T-610 | 0.5 | Done | `flutter test` green |
| T-615 | `flutter analyze` clean for new + bridged code | T-613 | 0.5 | Done | No errors |
| T-616 | Docs: mark FE plan Approved; link register | T-601 | 0.25 | Done | Links correct |
| T-617 | Keep CounterProvider bridge for legacy counter | T-610 | 0.25 | Done | Counter still opens |
| T-618 | Manual/automated smoke: login → categories CRUD → logout | T-615 | 0.5 | Done | analyze + 5 tests; API :8000 was down |
| T-619 | Update `docs/05` live-stack notes for categories (BLoC) | T-618 | 0.25 | Done | Status note |
| T-620 | FE-0 exit: gate checklist signed in task.md | T-618 | 0.25 | Done | FE-0 Done — stop |

CSV: [Mess_Flutter_Tasks_Register.csv](Mess_Flutter_Tasks_Register.csv)
