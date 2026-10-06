# FE-2b — Cuisines + Meal Times

Register: `Mess_Flutter_Tasks_Register.md` (T-646–T-655)  
Plan: `ecuisine_mess/docs/fe-2b-cuisines-meal-times-plan.md`  
Approved: Full remainder now (user 2026-10-06)

## Checklist

- [ ] T-646 ApiEndpoints: cuisine(id), cuisineCopyMapping(id), mealTimes, mealTime(id)
- [ ] T-647 Shared `DualPaneList<T>` widget
- [ ] T-648 `features/cuisines` domain (Cuisine, CuisineItemMapping, DeleteResult; usecases incl. CopyMapping)
- [ ] T-649 Cuisines data layer (Dio models/repo)
- [ ] T-650 CuisineListBloc + CuisineEditorBloc + pages (list + dual-pane editor)
- [ ] T-651 `features/meal_times` domain + data (MealTime entity; GetMealTimes; SaveMealTime)
- [ ] T-652 MealTimeSettingsBloc + MealTimeSettingsPage
- [ ] T-653 DI + routes + nav (Meal Times); delete `screens/cuisines_screen.dart`
- [ ] T-654 `flutter analyze` + `flutter test`
- [ ] T-655 Docs/register: FE-2 complete Done

## Exit gate

- [ ] analyze clean; tests green
- [ ] `/cuisines` feature pages; `/meal-times` in nav
- [ ] Full FE-2 marked Done; next FE-3 only when asked
