# Mess Module – Items + UOM Tasks Register (Live Stack)

| | |
|---|---|
| Plan | [implementation_plan.md](implementation_plan.md) Phase 5 |
| Prior | [Mess_AppShell_Tasks_Register.md](Mess_AppShell_Tasks_Register.md) (Done) |
| Created | 05-10-2026 |
| Scope | MariaDB + FastAPI + Flutter `ecuisine_mess/`. No mock-ui. No Frappe. No UOM CRUD. |
| Order | DB → API → Flutter → verify |

**Status legend:** `To do` · `Doing` · `Review` · `Done` · `Blocked`  
**Ref:** `P5` = Phase 5 Items + seed-only UOM.  
**IDs:** T-501+ (T-4xx reserved for Backend Foundation).

UOM seeds: Piece, Nos, Grams, Litres, MilliLitres, Plate, Bowl, Cup, Glass.

---

## Progress summary

| Milestone | Tasks | Est (h) | Done | Status |
|---|---|---|---|---|
| M1 Database | T-501 – T-503 | 2.0 | 3 / 3 | Done |
| M2 API | T-504 – T-507 | 2.5 | 4 / 4 | Done |
| M3 Flutter | T-508 – T-512 | 3.5 | 5 / 5 | Done |
| M4 Docs + verify | T-513 – T-516 | 1.5 | 4 / 4 | Done |
| **Total** | **16** | **9.5** | **16 / 16** | Done |

**Critical path:** T-501 → T-503 → T-505 → T-510 → T-515 → T-516

---

## M1 – Database

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-501 | Add `mess_uoms` to `schema.sql`; change `mess_items.unit` → `uom_id` FK RESTRICT | P5 DB | – | 0.75 | Done | Fresh schema creates UOM + items with `uom_id` |
| T-502 | Seed 9 UOMs (fixed `a8000001-…` UUIDs); remap item rows to `uom_id` in `seed.sql` | P5 DB | T-501 | 0.5 | Done | Seed loads without free-text `unit` |
| T-503 | Migration `004_mess_uoms.sql`: create+seed UOMs, backfill, FK, drop `unit` | P5 DB | T-501 | 0.75 | Done | Existing UUID DB migrates; items keep display names via join |

---

## M2 – API

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-504 | `GET /api/v1/uoms` (read-only; `include_inactive`) | P5 API | T-503 | 0.5 | Done | Returns 9 seeded rows ordered by `sort_order` |
| T-505 | Items list/get/create/update use `uom_id`; join `uom_name AS unit`; validate FK | P5 API | T-503 | 1.0 | Done | POST/PUT reject bad `uom_id`; list has `unit` + `uom_id` |
| T-506 | Update `ItemCreate`/`ItemUpdate` schemas: `uom_id` replaces write `unit` | P5 API | T-505 | 0.25 | Done | OpenAPI shows `uom_id` |
| T-507 | Fix joins in counter_service, cuisines, menus, report_service (`i.unit` → UOM join) | P5 API | T-505 | 0.75 | Done | Counter tap / cuisine items / reports still return a `unit` string |

---

## M3 – Flutter

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-508 | Add `lib/models/uom.dart` | P5 UI | – | 0.25 | Done | Parses API UOM rows |
| T-509 | `MessItem` adds `uomId`; `unit` stays display name from `unit`/`uom_name` | P5 UI | – | 0.25 | Done | fromJson reads both |
| T-510 | ApiService: `fetchUoms`, `createItem`, `updateItem`; `fetchItems(includeInactive)` | P5 UI | T-505 | 0.75 | Done | Calls match API |
| T-511 | `ItemsScreen`: MasterPage list; add + double-click edit; Category + UOM dropdowns; active | P5 UI | T-510 | 2.0 | Done | CRUD works against live API |
| T-512 | Register Items in `app_destinations` immediately before Item Categories | P5 UI | T-511 | 0.25 | Done | Rail shows Items |

---

## M4 – Docs + verify

| ID | Task | Ref | Depends | Est | Status | Done when |
|---|---|---|---|---|---|---|
| T-513 | Phase 5 section in `implementation_plan.md`; link this register + CSV | P5 Docs | – | 0.25 | Done | Plan points here |
| T-514 | `SYSTEM_OVERVIEW.md`: `mess_uoms`; items `uom_id` | P5 Docs | T-501 | 0.25 | Done | Overview matches schema |
| T-515 | Apply migration; API smoke (uoms, items CRUD, invalid uom 400) | P5 Verify | T-507 | 0.5 | Done | Smoke passes (`SMOKE_OK uoms=9`) |
| T-516 | `flutter analyze` + `flutter test`; Windows build smoke | P5 Verify | T-512 | 0.5 | Done | Analyze clean; 5 tests pass (interactive Windows UI optional spot-check) |

---

## Export

CSV: [Mess_Items_Tasks_Register.csv](Mess_Items_Tasks_Register.csv)
