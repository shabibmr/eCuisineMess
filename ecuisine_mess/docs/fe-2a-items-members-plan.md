# FE-2a — Items + Members (partial FE-2)

**Scope:** Flutter `ecuisine_mess/` only. Mode C strangler (BLoC + GoRouter + get_it + Dio).  
**User choice:** Items + Members first; **pause** before Cuisines dual-pane mapping and Meal Times.  
**Out of scope this slice:** Cuisines editor/mapping, Meal Times, Item Categories polish, photo upload, CSV export.

Register tasks (this slice): **T-636 – T-645** (Cuisines/Meal Times remain T-646–T-655 To do).

## Mirror patterns

Use `features/item_categories/**` and `features/bills/**` as templates:
- Domain entities pure Dart (no Flutter imports)
- Dio remote DS via `ApiClient` + `ApiEndpoints`
- `Failure` / `Status` / `part` event-state files
- Pages: `BlocProvider` + `sl<>()` factory; shared `MasterPage` / `showAppFormDialog`
- Package imports (`package:ecuisine_mess/...`)

## Files

| Action | Path |
|---|---|
| [MODIFY] | `lib/core/network/api_endpoints.dart` — items, uoms, members, membersByRfid, cuisines (lookup for member form) |
| [NEW] | `lib/features/items/**` — domain/data/presentation (list + add/edit dialog; UOM + category dropdowns; delete→deactivate notice) |
| [NEW] | `lib/features/members/**` — domain/data/presentation (list + filters; add/edit dialog; RFID field + uniqueness via `GET /members/by-rfid/{tag}`; cuisine dropdown from `GET /cuisines`) |
| [MODIFY] | `lib/core/di/injection.dart` — `_registerItems`, `_registerMembers` |
| [MODIFY] | `lib/core/router/app_router.dart` — `/items` → `ItemListPage`, `/members` → `MemberListPage` |
| [DELETE] | `lib/screens/items_screen.dart`, `lib/screens/members_screen.dart` |
| [KEEP] | Legacy `lib/models/{item,member,uom,cuisine}.dart` and `ApiService` item/member methods until nothing else imports them (cuisines/reports may still use models) |

## API contracts (existing backend)

**Items**
- `GET /items?include_inactive=1&category_id=`
- `POST /items` `{item_name, category_id, uom_id, is_active}`
- `PUT /items/{id}` partial
- `DELETE /items/{id}` → may return deactivate when referenced
- `GET /uoms` seed-only lookup
- Categories: reuse `GetItemCategories` from item_categories feature

**Members**
- `GET /members?search=&status=`
- `GET /members/{id}`, `GET /members/by-rfid/{tag}`
- `POST /members` `{name, rfid_tag, phone?, email?, cuisine_id?, validity_start, validity_end, status}`
- `PUT /members/{id}` partial
- `DELETE /members/{id}` (optional in UI; include in repo)
- Cuisine options: `GET /cuisines` (list headers only for dropdown; no mapping editor)

## UX acceptance

**Items**
- List with Active/Inactive chip; double-tap or edit opens dialog
- Add requires name + category + UOM (default UOM prefer `Nos`)
- Edit can toggle Active
- Delete (if exposed) shows snackbar when API returns deactivated
- No `*_code` fields in UI

**Members**
- Search toolbar (name / RFID / phone); optional status filter if cheap
- Add Member + double-tap edit
- Form: name, RFID, phone, email, cuisine, validity start/end, status (ACTIVE/SUSPENDED)
- RFID: on blur or “Check”, call by-rfid; if found and different id → block with message
- Expired / ≤7 days validity highlighted like current list
- No photo picker in this slice

## Verify

1. `flutter analyze` — no issues
2. `flutter test` — all pass
3. Routes `/items` and `/members` open new pages; legacy screens deleted
4. Stop; do **not** start Cuisines/Meal Times until asked

## Est

~1–1.5 days for this slice.
