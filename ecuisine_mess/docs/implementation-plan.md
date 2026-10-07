# Flutter Front-end Implementation Plan — `ecuisine_mess`

**Status:** **Approved** 2026-10-05 — **FE-0 Done**; **FE-1 Done**; **FE-2 Done** (FE-2a + FE-2b); **FE-3a In Progress** (T-656–T-657 Done)  
**Tasks:** [Mess_Flutter_Tasks_Register.md](../../Mess_Flutter_Tasks_Register.md) (T-601–T-657 Done)  
**Scope:** Flutter Windows client only (`ecuisine_mess/`). Backend/DB work is listed as **dependencies**, not executed in this plan.  
**Skip:** `mock-ui/` (reference only), `frappe_app/` (parked).  
**Authoritative refs:**
- [`docs/05-screens-ux-spec.md`](../../docs/05-screens-ux-spec.md)
- [`docs/08-gap-analysis-roadmap.md`](../../docs/08-gap-analysis-roadmap.md)
- [`docs/04-api-contract.md`](../../docs/04-api-contract.md)
- [`architecture.md`](architecture.md) · [`folder-structure.md`](folder-structure.md) · [`feature-catalog.md`](feature-catalog.md)
- [`migration-plan.md`](migration-plan.md) · [`routing-go-router.md`](routing-go-router.md) · [`shared-ui-components.md`](shared-ui-components.md)
- Backend companion: [`backend_api/docs/implementation-plan.md`](../../backend_api/docs/implementation-plan.md)

**Tasks register (to create after approval):** `Mess_Flutter_Tasks_Register.md` / `.csv` (T-601+)

---

## 1. Goal

Replace the current Provider + layer-first app with the mandated architecture:

1. `flutter_bloc` + `go_router` + **feature-first** (`data/` · `domain/` · `presentation/`)
2. Separate files for bloc / events / states and for pages / widgets
3. Shared UI library under `lib/shared/`
4. Full screen set from the mock-ui / UX spec (≈18 routes), Flat light+dark, Windows kiosk-ready counter

**Exit (whole plan):** every screen in [05](../../docs/05-screens-ux-spec.md) works against FastAPI on Windows; `flutter analyze` / `flutter test` / `flutter build windows` green; counter role cannot open masters (when P5 roles land).

---

## 2. What is already done (do not re-build)

### Live-stack history (root plan Phases 1–5)

| Phase | Deliverable | Register | FE outcome still in the tree |
|---|---|---|---|
| 1 | Users / login | LiveStack | `LoginScreen`, `AuthProvider`, Bearer + prefs |
| 2 | Item categories | LiveStack | `ItemCategoriesScreen`, CRUD API wired |
| 3 | App shell | AppShell T-301–319 | `ApiService._send`, `ApiConfig`, `MasterPage`, `showAppFormDialog`, `app_destinations`, 401→login, server settings |
| 4 | Backend foundation | BackendFoundation | APIs Flutter already calls (members, cuisines, items, meal-times, menus, counter, bills, reports, uoms) |
| 5 | Items + seed-only UOM | Items T-501–516 | `ItemsScreen`, UOM dropdowns, `GET /uoms` |

### Current Flutter snapshot (`lib/` today)

```
config/          api_config, app_theme
models/          bill, cuisine, item, item_category, member, rfid_tap_result, user (+ uom via items)
navigation/      app_destinations
providers/       auth_provider, counter_provider
screens/         login, main_layout, counter_kiosk, bill_register, members, cuisines,
                 items, item_categories, reports
services/        api_service (http)
widgets/         master_page, app_form_dialog, server_settings, supervisor_override,
                 token_slip, rfid_tap_simulator
```

**Stack today:** `provider` + `http` + `MaterialApp(home:)` — **not** the target.

### Screen readiness vs target

| Screen | Today | Target feature | Phase |
|---|---|---|---|
| Login | ✅ Provider | `auth` | FE-0 |
| Server settings | ✅ dialog | `settings` | FE-0 |
| Item Categories | ✅ list+edit | `item_categories` | FE-0 template → FE-2 polish |
| Items | ✅ BLoC list+add/edit (FE-2a) | `items` | Done (search/export later) |
| Counter | ✅ FE-1 | `counter` | Done |
| Bills | ✅ FE-1 filters/detail/cancel | `bills` | Done |
| Members | ✅ BLoC list+editor+RFID (FE-2a) | `members` | Done |
| Cuisines | ✅ BLoC list + dual-pane editor (FE-2b) | `cuisines` | Done |
| Reports | ⚠ 2 basic | `reports` ×5 | FE-4 |
| Meal Times | ✅ BLoC settings (FE-2b) | `meal_times` | Done |
| Daily Menu / History | ⬜ | `daily_menu` | FE-3 |
| Dashboard | ✅ BLoC + Home `/` (FE-4a) | `dashboard` | Done |
| Users admin | ⬜ | `users` | FE-5 |
| Dark mode / print / kiosk | ⬜ | polish | FE-6 |

### mock-ui

Reference prototype complete for demos (M0–M5 Done; M6/M7 register may be stale). **Out of scope** for this plan — behaviour source only.

---

## 3. Decisions locked for this plan

From [08 §5](../../docs/08-gap-analysis-roadmap.md) defaults (change only if you reject them at approval):

| ID | Decision |
|---|---|
| Q1 | Tap fails with `MENU_NOT_SET` when no daily menu (needs backend) |
| Q2 | Frappe parked |
| Q3 | Roles: `admin` / `supervisor` / `counter` on `mess_users.role` |
| Q4 | Flat skin only; **light + dark** |
| Q5 | Thermal printing deferred to FE-6 |
| Q6 | `counter_id` on bills deferred until backend P1; settings field stubbed in FE-0 |
| Q8 | Item has no `default_qty`; qty lives on cuisine mapping |
| Q9 | HTTP client = **`dio`** |
| Q10 | Single site / timezone |

---

## 4. Architecture mandates (non-negotiable)

See [architecture.md](architecture.md). Summary:

- Feature folders: `data/` · `domain/` · `presentation/`
- Presentation never imports `data/`; features never import another feature’s `data/` or `presentation/`
- BLoC calls use cases; Dio only in datasources
- Routes only via `AppRoutes` + GoRouter guards
- Shared widgets: no business logic ([shared-ui-components.md](shared-ui-components.md))
- Strangler migration: app runnable after every PR ([migration-plan.md](migration-plan.md))

### Target deps (`pubspec.yaml`)

```yaml
dependencies:
  flutter_bloc, bloc_concurrency, equatable, go_router, get_it, dio,
  shared_preferences, intl, window_manager, audioplayers, file_selector,
  fl_chart, logger, data_table_2, cupertino_icons
dev_dependencies:
  flutter_lints, bloc_test, mocktail
```

Remove `provider` and `http` only after the last feature migrates (FE-0 cleanup / FE-2 end).

---

## 5. Phase plan (Flutter)

Aligned with roadmap **P0–P6** as **FE-0 … FE-6**. Backend blockers noted per phase.

### FE-0 — Foundations (migrate shell + auth + settings)

**Goal:** App boots on BLoC + GoRouter; login/session/401 work; shared chrome exists; `item_categories` is the first vertical-slice template.

**Backend dependency:** none (existing auth APIs).

| Action | Path |
|---|---|
| [MODIFY] | `pubspec.yaml` — add target deps; keep `provider`/`http` until cleanup |
| [MODIFY] | `analysis_options.yaml` — package imports, const, unawaited_futures |
| [NEW] | `lib/core/**` — config, di, error, network (Dio), usecase, router, theme, shortcuts, utils |
| [NEW] | `lib/shared/models/**`, `lib/shared/widgets/**` — shell, MasterPage, FormDialog, ErrorBanner, … |
| [NEW] | `lib/features/auth/**` — AuthBloc, LoginPage, session restore |
| [NEW] | `lib/features/settings/**` — ServerSettingsCubit, ThemeCubit, dialog |
| [NEW] | `lib/features/item_categories/**` — full data/domain/presentation slice |
| [NEW] | `lib/app.dart` — `MaterialApp.router` |
| [MODIFY] | `lib/main.dart` — DI + `runApp` |
| [MODIFY] | Old screens keep working via temporary bridges until each feature moves |
| [DELETE] | (end of FE-0 for auth only) old `auth_provider`, `login_screen`, `ApiConfig` usages once bridged |

**Verify:** login / logout / restore / 401→login; categories list+edit; `flutter analyze`; widget tests for Auth + ApiConfig.

**Est:** ~3–4 days (migration Steps 0–4).

---

### FE-1 — Counter + Bills (money path) — **Done** (T-621–T-635)

**Goal:** Counter matches [05 §3](../../docs/05-screens-ux-spec.md): banners, focus, F10/F8/Esc, today strip, slip; Bills: filters, voucher, reprint, cancel + supervisor dialog.

**Backend dependency (hard):** F1–F5, F7 from [08](../../docs/08-gap-analysis-roadmap.md) — `NO_MEAL_SERVICE`, `MENU_NOT_SET`, auth on routes, real supervisor verify, race-safe token, re-validate on issue. Track in backend plan; FE can stub rejection codes against contract.

| Action | Path |
|---|---|
| [NEW] | `lib/features/counter/**` — CounterBloc, MealClockCubit, CounterPage + widgets |
| [NEW] | `lib/features/bills/**` — BillListBloc, BillDetailBloc, pages/widgets |
| [MODIFY] | `lib/shared/widgets/print/token_slip*.dart` |
| [MODIFY] | `lib/core/shortcuts/**` — F10 / F8 / Esc / Ctrl+Shift+L |
| [DELETE] | `providers/counter_provider.dart`, `screens/counter_kiosk_screen.dart`, `screens/bill_register_screen.dart` when ported |

**Verify:** simulator + live RFID; reject banners; issue+slip; cancel with supervisor; analyze/tests.

**Est:** ~2–3 days FE (+ backend P1).

---

### FE-2 — Masters

**Goal:** Port and complete `items`, `members`, `cuisines` (dual-pane mapping), `item_categories` polish, new `meal_times` settings (per cuisine, 3 rows).

**Backend dependency:** cuisine copy-mapping / unmap-block; member RFID-check; meal-time overlap 409 (largely done); delete→deactivate responses.

#### FE-2a — Items + Members (**Done** — T-636–T-645)

| Action | Path | Status |
|---|---|---|
| [NEW] | `lib/features/items/**` — list + add/edit; category + UOM; delete→deactivate parse | Done |
| [NEW] | `lib/features/members/**` — list + search/status; add/edit; RFID Check; cuisine/dates | Done |
| [MODIFY] | `ApiEndpoints`, DI, GoRouter `/items` `/members` | Done |
| [DELETE] | `screens/items_screen.dart`, `screens/members_screen.dart` | Done |

**Verify (FE-2a):** `flutter analyze` clean; `flutter test` green; routes use feature pages.

#### FE-2b — Cuisines + Meal Times (**Done** — T-646–T-655)

| Action | Path | Status |
|---|---|---|
| [NEW] | `lib/features/cuisines/**` — list + dual-pane `DualPaneList` mapper | Done |
| [NEW] | `lib/features/meal_times/**` — MealTimeSettingsPage | Done |
| [NEW] | `lib/shared/widgets/dual_pane_list.dart` | Done |
| [MODIFY] | DI, GoRouter `/cuisines` `/meal-times`, nav | Done |
| [DELETE] | `screens/cuisines_screen.dart` | Done |

**Verify (full FE-2):** analyze clean; 27 tests green; `/cuisines` + `/meal-times` wired. **FE-2 complete.**

---

### FE-3 — Daily menu

**Goal:** Menu editor + history per BR-D1…D8 (date, cuisine sidebar, meal tabs, qty, copy, lock/read-only past).

**Backend dependency:** date upsert, copy, lock-when-billed, history, mapping validation ([backend plan](../../backend_api/docs/implementation-plan.md) menu_service).

| Action | Path |
|---|---|
| [NEW] | `lib/features/daily_menu/**` — DailyMenuEditorBloc, MenuHistoryBloc, pages/widgets |

**Verify:** save day; past read-only; locked banner; copy flows; unsaved guard.

**Est:** ~2–3 days (after API ready).

---

### FE-4 — Reports + Dashboard

**Goal:** `ReportFrame` ×5 reports + CSV save dialog; Home dashboard (timeline, readiness, KPIs).

**Backend dependency:** members register report; dashboard `/dashboard/summary`; richer filters/drill-downs.

| Action | Path |
|---|---|
| [NEW] | `lib/features/reports/**` — five report blocs/pages |
| [NEW] | `lib/features/dashboard/**` |
| [NEW] | `lib/shared/widgets/reports/**` |
| [MODIFY] | `lib/shared/services/file_export_service.dart` |
| [DELETE] | `screens/reports_screen.dart` |

**Verify:** each report generate + pipe CSV; cancelled excluded; dashboard refresh.

**Est:** ~2–3 days.

---

### FE-5 — Roles & user admin

**Goal:** Role-aware nav + route guards; Users screen; counter kiosk (rail hidden, land on `/counter`).

**Backend dependency:** `mess_users.role`, permission deps on all routes, verify-supervisor, user admin APIs.

| Action | Path |
|---|---|
| [NEW] | `lib/features/users/**` |
| [MODIFY] | `lib/core/router/route_guards.dart`, `nav_destinations.dart` |
| [MODIFY] | `AuthBloc` / `AppUser` — include `role` |

**Verify:** counter user cannot open masters/reports (UI + API 403).

**Est:** ~1–2 days.

---

### FE-6 — Polish & pilot

**Goal:** Dark mode tokens, sounds, window/kiosk (`window_manager`), thermal/print adapter, Windows installer smoke, widget gallery.

| Action | Path |
|---|---|
| [MODIFY] | `lib/core/theme/**` — dark Flat |
| [NEW] | `lib/core/audio/sound_player.dart`, `assets/sounds/` |
| [MODIFY] | `lib/shared/services/printer_service.dart` |
| [NEW] | `lib/features/.../dev gallery` (debug) |
| [MODIFY] | packaging / `windows/` runner as needed |

**Verify:** light/dark; kiosk exit shortcut; print path decided (Q5); `flutter build windows --release`.

**Est:** ~2 days.

---

## 6. Suggested build order (critical path)

```
FE-0 core+auth+settings+item_categories
  → FE-1 counter+bills          (parallel: backend P1 correctness)
  → FE-2 masters+meal_times
  → FE-3 daily_menu             (after menu API rules)
  → FE-4 reports+dashboard
  → FE-5 roles+users
  → FE-6 polish
  → delete leftover provider/http/old folders
```

One feature per PR. Every PR leaves `flutter run -d windows` working.

---

## 7. File inventory (high level)

| Area | Action |
|---|---|
| `lib/core/**` | [NEW] entire tree |
| `lib/shared/**` | [NEW] widgets + models + services |
| `lib/features/{auth,settings,dashboard,counter,bills,members,cuisines,items,item_categories,meal_times,daily_menu,reports,users}/**` | [NEW] |
| `lib/app.dart` | [NEW] |
| `lib/main.dart` | [MODIFY] |
| `pubspec.yaml`, `analysis_options.yaml` | [MODIFY] |
| `test/**` | [NEW]/[MODIFY] mirror features |
| `lib/{config,models,navigation,providers,screens,services,widgets}/**` | [DELETE] after migration |
| Root docs (`README`, `SYSTEM_OVERVIEW`, `docs/05` status column) | [MODIFY] when screens land |

---

## 8. Testing & verify gates

Per [testing.md](testing.md) and [06](../../docs/06-engineering-standards.md):

| Gate | Command / check |
|---|---|
| Static | `flutter analyze` |
| Unit/widget | `flutter test` (bloc_test + MasterPage/Auth/Counter) |
| Windows | `flutter run -d windows` — login → counter → one master → one report |
| Build | `flutter build windows --debug` (release at FE-6) |

Do not mark a phase Done without the gate for that phase.

---

## 9. Out of scope

- mock-ui code changes / Clay·Glass skins
- Frappe parity
- Backend rule fixes (owned by `backend_api/docs/implementation-plan.md`) — FE consumes the contract
- Password-reset email flows
- Multi-site / multi-timezone

---

## 10. Approval checklist

Before coding FE-0, confirm:

- [ ] This plan approved (phases FE-0…FE-6)
- [ ] Locked decisions Q1–Q10 accepted (or list overrides)
- [ ] Backend P1 (counter F1–F5) scheduled so FE-1 is not blocked forever
- [ ] Create `Mess_Flutter_Tasks_Register.md` / `.csv` (T-601+) from this plan after approval

**Approved — execute FE-0 via `task.md` / T-601–T-620.**
