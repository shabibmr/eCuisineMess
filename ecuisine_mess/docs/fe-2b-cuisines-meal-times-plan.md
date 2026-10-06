# FE-2b — Cuisines + Meal Times (FE-2 remainder)

**Approved:** user chose **Full remainder now** (2026-10-06).  
**Scope:** Flutter `ecuisine_mess/` only. Completes FE-2 after FE-2a.  
**Out of scope:** Daily menu (FE-3), reports, roles, item_categories polish, photo.

Register: **T-646 – T-655**.

## Mirror

`features/items/**`, `features/members/**`, `item_categories/**`. Domain = pure Dart. Dio + get_it + GoRouter.

## Files

| Action | Path |
|---|---|
| [MODIFY] | `api_endpoints.dart` — cuisine(id), cuisineCopyMapping(id), mealTimes, mealTime(id) (`cuisines` already present) |
| [NEW] | `lib/shared/widgets/dual_pane_list.dart` — generic DualPaneList\<T\> (available / mapped, search, add/remove selected, optional qty on mapped) |
| [NEW] | `lib/features/cuisines/**` — list + editor (header + dual-pane mapping + copy-mapping) |
| [NEW] | `lib/features/meal_times/**` — MealTimeSettingsPage (cuisine selector + 3 rows) |
| [MODIFY] | `injection.dart`, `app_router.dart`, `app_routes.dart`, `nav_destinations.dart`, `app_destinations.dart` if still used |
| [DELETE] | `lib/screens/cuisines_screen.dart` |

## API

**Cuisines**
- `GET /cuisines?include_inactive=1` — list with `items[]`, `mapped_items_count`, `active_members_count`
- `GET /cuisines/{id}` — detail + items
- `POST /cuisines` `{cuisine_name, description?, is_active, items?:[{item_id,default_qty,sort_order}]}`
- `PUT /cuisines/{id}` same partial; replacing `items` may 409 `UNMAP_BLOCKED` with dates
- `POST /cuisines/{id}/copy-mapping` `{source_cuisine_id}`
- `DELETE /cuisines/{id}` → delete or deactivate
- Available items for mapper: reuse `GetItems` from items feature (`includeInactive: false`)

**Meal times**
- `GET /meal-times?cuisine_id=` — rows with `meal_type`, `name`, `start_time`, `end_time`, `is_active`
- `PUT /meal-times/{id}` `{name?, start_time?, end_time?, is_active?}` — 400 start≥end; 409 overlap same cuisine
- Creating cuisine auto-seeds 3 windows — no POST meal-times needed

## UX

**Cuisines**
- List page: name, mapped count, members count, Active chip; Add; open editor (tap / Edit)
- Editor: name, description, active; DualPane available↔mapped; qty edit on mapped; Save; Copy mapping from another cuisine; empty mapping warning; show UNMAP_BLOCKED details in dialog
- Route: `/cuisines` list; `/cuisines/:id` editor (and `/cuisines/new` for create) OR single page with list→push editor via GoRouter

**Meal Times**
- New nav: **Meal Times** → `/meal-times`
- Cuisine dropdown; show 3 rows (Breakfast/Lunch/Dinner); time pickers + active; Save per row or Save all dirty; client-side overlap flag; surface API overlap message
- Unsaved switch cuisine → Save/Discard dialog

## Verify

`flutter analyze` clean; `flutter test` green; delete legacy cuisines screen; mark FE-2 Done in registers.
