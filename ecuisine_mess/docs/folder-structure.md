# Folder Structure

## 1. Target tree

```
ecuisine_mess/
├── pubspec.yaml · analysis_options.yaml
├── docs/                                  ← this folder
├── assets/
│   ├── fonts/                             (Inter/Noto Sans + Noto Naskh Arabic)
│   ├── images/
│   └── sounds/                            (success.wav, error.wav, print.wav)
├── test/                                  mirrors lib/ (see testing.md)
├── windows/                               Flutter runner (generated)
└── lib/
    ├── main.dart                          bootstrap only
    ├── app.dart                           EcuisineMessApp (MaterialApp.router)
    │
    ├── core/
    │   ├── config/        app_config.dart · constants.dart
    │   ├── di/            injection.dart · (register_*.dart per feature optional)
    │   ├── error/         failures.dart · exceptions.dart
    │   ├── network/       api_client.dart · api_endpoints.dart · interceptors/
    │   │                  (auth_interceptor.dart · error_interceptor.dart)
    │   ├── usecase/       usecase.dart
    │   ├── router/        app_router.dart · app_routes.dart · route_guards.dart
    │   ├── theme/         app_theme.dart · app_colors.dart · app_spacing.dart · app_tokens.dart
    │   ├── shortcuts/     app_intents.dart · app_shortcuts.dart
    │   ├── audio/         sound_player.dart
    │   └── utils/         date_format.dart · debouncer.dart · masking.dart · csv_saver.dart
    │
    ├── shared/
    │   ├── models/        meal_type.dart · date_range.dart · paged.dart
    │   ├── widgets/       (see shared-ui-components.md)
    │   │   ├── buttons/   app_button.dart · icon_action_button.dart
    │   │   ├── inputs/    app_text_field.dart · app_dropdown.dart · date_field.dart · time_field.dart · search_field.dart
    │   │   ├── pickers/   entity_search_picker.dart (generic) · item_picker.dart · cuisine_picker.dart · member_picker.dart
    │   │   ├── tables/    app_data_table.dart · table_toolbar.dart · empty_state.dart
    │   │   ├── feedback/  error_banner.dart · app_snackbar.dart · loading_overlay.dart · confirm_dialog.dart
    │   │   ├── layout/    app_shell.dart · nav_rail.dart · page_scaffold.dart · master_page.dart · form_dialog.dart
    │   │   ├── status/    status_chip.dart · meal_badge.dart · active_badge.dart
    │   │   ├── reports/   report_frame.dart · filter_bar.dart · totals_row.dart · drill_down_drawer.dart
    │   │   └── print/     token_slip.dart · token_slip_dialog.dart
    │   └── services/      printer_service.dart (interface) · file_export_service.dart
    │
    └── features/
        ├── auth/
        ├── settings/              server settings (API URL), theme
        ├── dashboard/
        ├── counter/
        ├── bills/
        ├── members/
        ├── cuisines/
        ├── items/
        ├── item_categories/
        ├── meal_times/
        ├── daily_menu/            editor + history
        ├── reports/               members · headcount · items · attendance · time_based
        └── users/                 (P5) user admin
```

Each feature repeats:

```
<feature>/
├── data/{models,datasources,repositories}/
├── domain/{entities,repositories,usecases}/
└── presentation/{bloc,pages,widgets}/
```

`reports/` is one feature with a sub-feature per report to keep each report's bloc/page small:

```
reports/
├── data/…
├── domain/…
└── presentation/
    ├── bloc/{members_report,headcount_report,item_movement_report,attendance_report,time_based_report}/
    ├── pages/…
    └── widgets/…
```

## 2. File naming & suffixes

| Role | File | Class |
|---|---|---|
| Entity | `member.dart` | `Member` |
| DTO | `member_model.dart` | `MemberModel` |
| Repository contract | `member_repository.dart` | `abstract interface class MemberRepository` |
| Repository impl | `member_repository_impl.dart` | `MemberRepositoryImpl` |
| Datasource | `member_remote_datasource.dart` | `MemberRemoteDataSource` (+ `…Impl`) |
| Use case | `get_members.dart` | `GetMembers` |
| BLoC | `member_list_bloc.dart` | `MemberListBloc` |
| Events | `member_list_event.dart` | `sealed class MemberListEvent` |
| States | `member_list_state.dart` | `MemberListState` |
| Page | `member_list_page.dart` | `MemberListPage` (route target, owns `BlocProvider`) |
| Widget | `member_table.dart` | `MemberTable` |

**Rules**

- **One public class per file** (except sealed event/state hierarchies, which share one file each, and their subclasses).
- bloc/event/state use `part`/`part of` **or** plain imports — project standard: **`part` files** so event/state can access the bloc's private types and generated code stays tidy:

```dart
// member_list_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
part 'member_list_event.dart';
part 'member_list_state.dart';

// member_list_event.dart
part of 'member_list_bloc.dart';
```
- **Pages vs widgets:** a `*_page.dart` only does: create/provide the BLoC, wire `BlocListener`s (snackbars/navigation), and compose widgets in a `PageScaffold`. All layout chunks of more than ~30 lines go into `presentation/widgets/`. Pages contain no business logic and no `Dio`.
- Feature-local widgets stay in the feature. The moment a second feature needs one, **promote it to `shared/widgets/`** (don't copy-paste, don't cross-import).
- Barrel files (`index.dart`) are **not** used — explicit imports keep boundaries visible.
- Imports: always `package:ecuisine_mess/...` (no relative `../../` across layers).

## 3. Template: a minimal feature (copy me)

```dart
// domain/entities/item_category.dart
class ItemCategory extends Equatable {
  const ItemCategory({required this.id, required this.name, required this.sortOrder, required this.isActive});
  final String id; final String name; final int sortOrder; final bool isActive;
  @override List<Object?> get props => [id, name, sortOrder, isActive];
}

// domain/repositories/item_category_repository.dart
abstract interface class ItemCategoryRepository {
  Future<List<ItemCategory>> getAll({bool includeInactive = false});
  Future<ItemCategory> create(ItemCategory c);
  Future<ItemCategory> update(ItemCategory c);
}

// domain/usecases/get_item_categories.dart
class GetItemCategories implements UseCase<List<ItemCategory>, GetItemCategoriesParams> {
  GetItemCategories(this._repo); final ItemCategoryRepository _repo;
  @override Future<List<ItemCategory>> call(GetItemCategoriesParams p) => _repo.getAll(includeInactive: p.includeInactive);
}

// data/models/item_category_model.dart
class ItemCategoryModel {
  const ItemCategoryModel({required this.id, required this.categoryName, required this.sortOrder, required this.isActive});
  final String id; final String categoryName; final int sortOrder; final bool isActive;
  factory ItemCategoryModel.fromJson(Map<String, dynamic> j) => ItemCategoryModel(
      id: j['id'] as String, categoryName: j['category_name'] as String,
      sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0, isActive: (j['is_active'] ?? 1) == 1 || j['is_active'] == true);
  Map<String, dynamic> toJson() => {'category_name': categoryName, 'sort_order': sortOrder, 'is_active': isActive ? 1 : 0};
  ItemCategory toEntity() => ItemCategory(id: id, name: categoryName, sortOrder: sortOrder, isActive: isActive);
}
```

See [state-management-bloc.md](state-management-bloc.md) for the BLoC/event/state templates and [routing-go-router.md](routing-go-router.md) for wiring the page.
