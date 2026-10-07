# Screen Coverage & Gap Review — 2026-10-07

Scope: `ecuisine_mess` Flutter client vs `docs/05-screens-ux-spec.md`, `docs/08-gap-analysis-roadmap.md` and `docs/implementation-plan.md`.
Verification: `flutter analyze` — no issues; `flutter test` — 89 tests passed.

## Verdict

All 20 spec screens are implemented. Remaining gaps are role enforcement, supervisor verification, legacy-code cleanup, polish and stale docs.

## Screen coverage (spec → Flutter)

| Screen | Status |
|---|---|
| Login, server settings | ✅ Done |
| Dashboard (`/`) | ✅ Done |
| Counter, token slip, bill register (filters, detail, cancel) | ✅ Done |
| Items, Item Categories, Members (editor + RFID check), Cuisines (dual-pane), Meal Times | ✅ Done |
| Daily Menu editor, Menu History | ✅ Done (plan doc still lists them as ⬜ / in progress) |
| Reports: Headcount, Attendance, Item Movement, Time Distribution, Members Register | ✅ Done, in one tabbed page |
| Styleguide / widget gallery (`/dev/gallery`) | ⬜ Missing (dev-only) |
| Users admin | ⬜ Missing (planned FE-5) |

## Gaps

1. **No role handling in the app (FE-5).** `AppUser` has no `role` field; there are no route guards or role-based nav hiding. A counter operator can open Members, Cuisines and Reports. The backend already has `require_role` and a `role` column, so only the client is missing.
2. **Supervisor override uses a hardcoded demo PIN.** `supervisor_override_dialog.dart` checks `1234` locally and shows the PIN on screen. It should call the backend verify-supervisor endpoint.
3. **Route differences from the spec.**
   - Spec routes `/members/new`, `/members/:id`, `/items/new`, `/items/:id`, `/bills/:id`, `/settings/meal-times`, `/reports/<name>`: only cuisines follow this pattern; members, items and bills use dialogs or sheets.
   - Reports are tabs on one `/reports` page, and meal times live at `/meal-times`.
   - Individual reports have no deep link, so per-report role guards are not possible.
4. **Dead legacy code in `lib/`.**
   - `lib/screens/`, `providers/`, `models/`, `widgets/`, `navigation/app_destinations.dart` and `config/` are leftovers from the old Provider layout.
   - `services/api_service.dart` is still used by `injection.dart`, `auth_bloc.dart` and one test, so `AuthBloc` is not fully on the new data layer.
   - `main_layout.dart` and `item_categories_screen.dart` are unused; `lib/screens/reports_screen.dart` is staged for deletion.
5. **Polish not done (FE-6).** No dark theme (`darkTheme` / `themeMode` absent) and no kiosk or fullscreen mode. Thermal printing files exist (`escpos_slip_builder`, `windows_raw_printer`) but were not verified on hardware.
6. **Docs are stale.** `implementation-plan.md` (Daily Menu and Reports rows), `docs/05` and `docs/08` (screen matrix) still show finished screens as missing or basic.
7. **Backend risks from `docs/08` (not re-verified in code).**
   - Business routes may still be unauthenticated.
   - Token numbering may still use `COUNT(*)+1`.
   - The outside-meal-hours fallback (F1) may still be open.
   - Issue-token may not re-validate.
8. **Working-tree hygiene.**
   - Three uploaded `.gif` files under `backend_api/static/uploads/members/` are untracked and should probably be gitignored.
   - A large batch of work is uncommitted.
   - `flutter test` printed a layout/overflow warning (a `Column` debug dump) although the suite passed. The widget causing it is not yet identified.

## Suggested order

1. Role model + route guards + nav hiding (gap 1).
2. Real supervisor verification (gap 2).
3. Remove legacy code and finish the `AuthBloc` migration (gap 4).
4. Update the stale docs (gap 6).
5. Dark mode and kiosk polish (gap 5).
