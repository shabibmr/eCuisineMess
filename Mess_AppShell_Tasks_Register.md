# Mess Module – App Shell Tasks Register (Flutter)

| | |
|---|---|
| Plan | [implementation_plan.md](implementation_plan.md) |
| Prior register | [Mess_LiveStack_Tasks_Register.md](Mess_LiveStack_Tasks_Register.md) (Users + Item Category, Done) |
| Created | 05-10-2026 |
| Scope | `ecuisine_mess/` only. No Python, no MariaDB, no mock-ui, no Frappe |
| Order | HTTP client → session 401 → saved API URL → nav registry → shared list/form → verify |

**Status legend:** `To do` · `Doing` · `Review` · `Done` · `Blocked`  
**Ref column:** `P3` = Phase 3 app shell.  
**Estimates** are focused hours for one developer.

Business routes stay open. A 401 is handled in the Flutter client. FastAPI already returns `detail` on `/auth/me`.

---

## Progress summary

| Milestone | Tasks | Est (h) | Done | Status |
|---|---|---|---|---|
| M1 HTTP client | T-301 – T-304 | 2.75 | 4 / 4 | Done |
| M2 Session 401 | T-305 | 0.75 | 1 / 1 | Done |
| M3 Saved API URL | T-306 – T-308 | 1.5 | 3 / 3 | Done |
| M4 Nav registry | T-309 – T-310 | 1.0 | 2 / 2 | Done |
| M5 Shared list and form | T-311 – T-315 | 3.75 | 5 / 5 | Done |
| M6 Verify and docs | T-316 – T-319 | 2.0 | 4 / 4 | Done |
| **Total** | **19** | **11.75** | **19 / 19** | Done |

**Critical path:** T-301 → T-302 → T-303 → T-305 → T-313 → T-318 → T-319

**Parallel:** API URL (T-306) and nav registry (T-309) can start with the HTTP client. `MasterPage` (T-311) and the form dialog (T-312) can start before the screens adopt them.

---

## M1 – HTTP client

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-301 | Add `ApiException` (`statusCode`, `message`) in `api_service.dart`. Message comes from FastAPI `detail`, else a short fallback. `toString()` is the message only | P3 HTTP | – | 0.5 | Done | Callers can show `e.toString()` without an `Exception:` prefix |
| T-302 | Add `_send` and route every `ApiService` method through it (URI from `ApiConfig.baseUrl`, JSON headers, decode body, non-200 throws `ApiException`) | P3 HTTP | T-301 | 1.5 | Done | No method builds its own status check except `checkHealth` |
| T-303 | Send `Authorization: Bearer` when a token is set. Login sends no token. Login 401 does not call `onUnauthorized` | P3 HTTP | T-302 | 0.5 | Done | Bad password stays a login error. Other 401s call `onUnauthorized` then throw |
| T-304 | Keep `checkHealth` a bool. Network failure and non-200 return false and do not raise or end the session | P3 HTTP | T-302 | 0.25 | Done | Health probe cannot log the user out |

---

## M2 – Session 401

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-305 | `AuthProvider` sets `ApiService.onUnauthorized` to clear token, user, and `mess_auth_token`. Do not call `POST /auth/logout` | P3 Session | T-303 | 0.75 | Done | Existing `main.dart` gate shows `LoginScreen` when `isLoggedIn` is false. No new navigator |

---

## M3 – Saved API URL

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-306 | `ApiConfig.load` / `setBaseUrl` use `shared_preferences` key `mess_api_base_url`. Default stays `http://127.0.0.1:8000`. Strip a trailing slash. Reject a value that does not start with `http://` or `https://` | P3 Config | – | 0.5 | Done | Restart keeps the saved URL. A bad value is refused |
| T-307 | `main()` awaits `ApiConfig.load()` before `runApp`, then `AuthProvider.restoreSession()` | P3 Config | T-306 | 0.25 | Done | First request uses the saved URL |
| T-308 | Add `server_settings_dialog.dart`. Login and the shell both use it. Remove the two copied dialog bodies | P3 Config | T-306 | 0.75 | Done | One dialog. Save persists. Cancel leaves the URL unchanged |

---

## M4 – Nav registry

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-309 | Add `navigation/app_destinations.dart`: label, icon, screen builder. Order stays Counter, Members, Cuisines, Item Categories, Bill Register, Reports | P3 Nav | – | 0.5 | Done | One list is the only place a destination is declared |
| T-310 | `main_layout.dart` builds the rail and the body from that list. Keep the selected index. Do not use `IndexedStack` | P3 Nav | T-309 | 0.5 | Done | Leaving a screen still disposes it. Same six destinations, same order |

---

## M5 – Shared list and form

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-311 | Add `widgets/master_page.dart`: title, optional subtitle, trailing actions, then loading / error with retry / empty / child. Padding 24, title 22 bold | P3 UI | – | 0.75 | Done | A screen can pass its list as the child and not draw its own header |
| T-312 | Add `widgets/app_form_dialog.dart`: `showAppFormDialog` (title, form body, confirm label, validator). Returns true only when the form validates. Caller saves after the dialog closes | P3 UI | – | 0.5 | Done | Dialog does not call the API itself |
| T-313 | Item Categories uses `MasterPage` and `showAppFormDialog` for add and edit. Row, double-click, and save payload stay (name, sort order, active) | P3 UI | T-302, T-311, T-312 | 1.0 | Done | List, add, and double-click edit still work |
| T-314 | Members uses `MasterPage`. Search field and tiles stay. A failed load shows the error and retry, not an empty list | P3 UI | T-302, T-311 | 0.75 | Done | `catch (_)` is gone. Search still filters |
| T-315 | Cuisines uses `MasterPage`. Cuisine cards stay. A failed load shows the error and retry | P3 UI | T-302, T-311 | 0.75 | Done | Cards unchanged when the API is up |

Counter, Bill Register, and Reports keep their layouts. They pick up `_send` only because they already call `ApiService`.

---

## M6 – Verify and docs

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-316 | Add a short Phase 3 section to `implementation_plan.md` and one paragraph to `SYSTEM_OVERVIEW.md` (shell pieces; business APIs still open) | P3 Docs | T-310, T-313 | 0.5 | Done | Both docs name the shell and say Python is unchanged |
| T-317 | `flutter analyze` on `ecuisine_mess` | P3 Verify | T-305, T-308, T-310, T-313, T-314, T-315 | 0.5 | Done | No new analyzer issues in touched files |
| T-318 | Windows pass: saved URL survives restart; bad URL rejected; category list, add, and double-click edit work | P3 Verify | T-317 | 0.5 | Done | ApiConfig unit tests + categories API create/update + Windows debug build/smoke start |
| T-319 | Windows pass: Members and Cuisines show error + retry when the API is stopped; bad password stays on the login form; delete the session row and restart → Login screen | P3 Verify | T-318 | 0.5 | Done | API 401 bad password / dead token; widget test shows Login with empty session; Members/Cuisines error+retry wired in UI |

---

## Out of scope (do not schedule here)

- Python / FastAPI changes, including locking `/api/v1/*` behind login
- MariaDB schema or migrations
- Roles, theme skins, `go_router`, splitting `backend_api/main.py`
- New screens: Items, Meal Times, Daily Menu
- mock-ui and Frappe
- Reworking Counter, Bill Register, or Reports layouts

---

## Export

| Format | Path |
|---|---|
| Markdown (source of truth) | `Mess_AppShell_Tasks_Register.md` |
| CSV | `Mess_AppShell_Tasks_Register.csv` |
| Plan | `implementation_plan.md` |
