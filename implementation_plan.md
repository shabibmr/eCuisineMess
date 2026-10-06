# Implementation Plan — eCuisine Mess Module (Master)

**Last rewritten:** 2026-10-05  
**Live-stack scope:** MariaDB + FastAPI + Flutter (`ecuisine_mess/`). Skip `mock-ui/` edits and `frappe_app/` (parked).  
**IDs:** UUID (`CHAR(36)`); no master `*_code` columns.

---

## Layer plans (source of truth going forward)

| Layer | Plan | Status |
|---|---|---|
| **History (Phases 1–5)** | This file §Completed | **Done** |
| **Flutter front-end (next)** | [`ecuisine_mess/docs/implementation-plan.md`](ecuisine_mess/docs/implementation-plan.md) · [Mess_Flutter_Tasks_Register.md](Mess_Flutter_Tasks_Register.md) | **FE-0 + FE-1 + FE-2 + FE-3 Done** |
| **Backend remaining** | [`backend_api/docs/implementation-plan.md`](backend_api/docs/implementation-plan.md) | Planned (correctness, roles, menus, reports) |
| **Roadmap / gaps** | [`docs/08-gap-analysis-roadmap.md`](docs/08-gap-analysis-roadmap.md) | P0–P6 |
| **Common specs** | [`docs/`](docs/README.md) | Authoritative for product/API/UX |
| **Flutter architecture** | [`ecuisine_mess/docs/`](ecuisine_mess/docs/README.md) | BLoC + GoRouter + feature-first |

---

## Completed work (do not re-open)

| Phase | Theme | Register | Outcome |
|---|---|---|---|
| **1** | Users / login | [Mess_LiveStack_Tasks_Register](Mess_LiveStack_Tasks_Register.md) | `mess_users` + sessions; `POST /auth/login`; Flutter login; seed `admin`/`admin123` |
| **2** | Item Category | LiveStack | `mess_item_categories`; Flutter categories screen; items FK |
| **3** | App shell (Flutter) | [Mess_AppShell_Tasks_Register](Mess_AppShell_Tasks_Register.md) T-301–319 | Shared HTTP client, 401→login, persisted API URL, nav registry, `MasterPage` / form dialog |
| **4** | Backend foundation | [Mess_BackendFoundation_Tasks_Register](Mess_BackendFoundation_Tasks_Register.md) T-401–426 | `core/` · `routers/` · `schemas/` · `services/`; pool + `transaction()`; CRUD + counter + 4 reports |
| **5** | Items + seed-only UOM | [Mess_Items_Tasks_Register](Mess_Items_Tasks_Register.md) T-501–516 | `mess_uoms`; `GET /uoms`; Flutter Items with Category + UOM |

**Also done (related):** UUID cutover (`003`); per-cuisine meal times DB/API (`005`); mock-ui M0–M5 for demos (reference only).

### Flutter today (strangler progress)

`flutter_bloc` + `go_router` + `get_it` + `dio` for **auth, settings, item_categories, items, members, counter, bills, cuisines, meal_times**. Legacy Provider/`http` remains for Reports until FE-4. **Missing vs spec:** Dashboard, Daily Menu, full Reports, roles, dark mode.

---

## Next: Flutter front-end rebuild (FE-0 … FE-6)

Full detail, files, gates, and open-question locks:  
→ **[`ecuisine_mess/docs/implementation-plan.md`](ecuisine_mess/docs/implementation-plan.md)**

| FE phase | Theme | Depends on backend | Exit |
|---|---|---|---|
| **FE-0** ✅ | Core + Dio + GoRouter + Auth/Settings + Item Categories template | — | Login on BLoC/GoRouter; analyze green |
| **FE-1** ✅ | Counter + Bills (full UX) | Counter F1–F5 / supervisor / token race | Spec counter + cancel/reprint |
| **FE-2** ✅ | Items+Members+Cuisines+Meal Times (FE-2a/2b) | Mapping/RFID/meal rules | Masters match mock |
| **FE-3** ✅ | Daily menu + history | Menu save/copy/lock/history APIs | BR-D1…D8 |
| **FE-4** | Reports ×5 + Dashboard | Members report + `/dashboard/summary` | CSV + home KPIs |
| **FE-5** | Roles + Users admin | `mess_users.role` + route auth | Counter cannot open masters |
| **FE-6** | Dark mode, print, kiosk, packaging | — | Pilot-ready Windows build |

**Task IDs:** [Mess_Flutter_Tasks_Register.md](Mess_Flutter_Tasks_Register.md) / `.csv` (**T-601+**).

**Migration strategy:** strangler — see [`ecuisine_mess/docs/migration-plan.md`](ecuisine_mess/docs/migration-plan.md). One feature per PR; `flutter run -d windows` always works.

**Current slice:** FE-3 complete (T-656–T-665 Done). Next: FE-4 Reports + Dashboard.

---

## Parallel: Backend remaining (not FE scope)

Tracked in [`backend_api/docs/implementation-plan.md`](backend_api/docs/implementation-plan.md). FE-1+ need especially: `NO_MEAL_SERVICE` / `MENU_NOT_SET`, auth on business routes, supervisor verify, race-safe tokens, menu rules, dashboard + 5th report, roles.

---

## Out of scope (unchanged)

- Editing `mock-ui/` as product delivery  
- Frappe DocType parity until live stack complete  
- Clay/Glass skins (Flat light+dark only)  
- Multi-site / multi-timezone  

---

## Approval

- [x] Master index accepted  
- [x] Flutter plan approved (2026-10-05)  
- [x] Decisions Q1–Q10 defaults accepted  
- [x] Flutter tasks register T-601+ created  
- [x] FE-0 complete (see `task.md`)  
- [x] FE-1 complete (Counter + Bills; T-621–T-635)  
- [x] FE-2a Items + Members (T-636–T-645)  
- [x] FE-2b Cuisines + Meal Times (T-646–T-655) — FE-2 complete  
- [x] FE-3 Daily Menu + History (T-656–T-665) — FE-3 complete  

**Next:** FE-4 Reports + Dashboard (T-666+).
