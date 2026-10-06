# Front-end Architecture

Clean-architecture, **feature-first**, BLoC for state, GoRouter for navigation.

## 1. Layers inside a feature

```
presentation  ──depends on──▶  domain  ◀──implemented by──  data
 (UI, BLoC)                (entities, contracts,         (DTOs, datasources,
                            use cases)                    repository impls)
```

| Layer | Contains | May import | Must NOT import |
|---|---|---|---|
| **domain** | `entities/`, `repositories/` (abstract), `usecases/` | `dart:core`, `equatable`, `core/error`, `core/usecase` | `flutter/*`, `dio`, `data/`, `presentation/` |
| **data** | `models/` (DTOs), `datasources/`, `repositories/` (impl) | `domain`, `core/network`, `dio` | `presentation/`, `flutter/widgets` |
| **presentation** | `bloc/`, `pages/`, `widgets/` | `domain`, `core`, `shared`, `flutter` | `data/` (never reference DTOs or datasources) |

> The BLoC calls **use cases** (or the repository contract for trivial reads). It never touches Dio, DTOs or JSON.

### Cross-feature rules

- A feature **never imports another feature's `data/` or `presentation/`**. If feature B needs data owned by A, it imports A's **domain** entity/use case (`features/a/domain/…`) or — better — both depend on a type in `core/`/`shared/`.
- Example: `daily_menu` needs the list of items → depends on `items/domain/usecases/get_items.dart`. Pickers that many features use live in `shared/` and take plain callbacks/entities, not another feature's bloc.
- `core/` and `shared/` never import from `features/`.

## 2. Anatomy of a feature (example: `members`)

```
features/members/
├── data/
│   ├── models/member_model.dart              # DTO: fromJson/toJson, toEntity()
│   ├── datasources/member_remote_datasource.dart
│   └── repositories/member_repository_impl.dart
├── domain/
│   ├── entities/member.dart                  # immutable, Equatable
│   ├── repositories/member_repository.dart   # abstract contract
│   └── usecases/
│       ├── get_members.dart
│       ├── get_member.dart
│       ├── save_member.dart
│       └── delete_member.dart
└── presentation/
    ├── bloc/
    │   ├── member_list/
    │   │   ├── member_list_bloc.dart
    │   │   ├── member_list_event.dart
    │   │   └── member_list_state.dart
    │   └── member_editor/
    │       ├── member_editor_bloc.dart
    │       ├── member_editor_event.dart
    │       └── member_editor_state.dart
    ├── pages/
    │   ├── member_list_page.dart
    │   └── member_editor_page.dart
    └── widgets/
        ├── member_table.dart
        ├── member_filter_bar.dart
        ├── member_form.dart
        └── rfid_capture_field.dart
```

Full tree: [folder-structure.md](folder-structure.md). Per-feature specs: [feature-catalog.md](feature-catalog.md).

## 3. Core module (`lib/core/`)

| Folder | Purpose |
|---|---|
| `config/` | `AppConfig` (API URL load/save via prefs), constants |
| `di/` | `injection.dart` — `get_it` registrations, one `registerXFeature()` per feature |
| `error/` | `Failure` (sealed), `AppException`s thrown by datasources |
| `network/` | `ApiClient` (Dio), interceptors (auth, logging, error mapping), `ApiEndpoints` |
| `usecase/` | `UseCase<T, P>` base + `NoParams` |
| `router/` | `app_router.dart`, `routes.dart` (names/paths), guards, `RouterRefreshStream` |
| `theme/` | `app_theme.dart`, `app_colors.dart`, `app_spacing.dart`, `AppTokens` ThemeExtension |
| `shortcuts/` | Global keyboard intents/actions |
| `utils/` | `date_format.dart`, `debouncer.dart`, `meal_type.dart`, `result extensions` |
| `l10n/` | (later) localisation |

## 4. Shared module (`lib/shared/`)

Reusable **UI** (no business logic, no BLoC from features): buttons, inputs, tables, dialogs, banners, pickers, layouts, status chips, meal badges, report frame, token slip. Catalogue: [shared-ui-components.md](shared-ui-components.md).

Shared **domain-neutral models** used by several features live in `shared/models/` (e.g. `MealType`, `DateRange`, `Paged<T>`).

## 5. Error handling

```
Datasource  ──throws──▶ ServerException / NetworkException / UnauthorizedException / ConflictException
Repository  ──catches──▶ rethrows as Failure (sealed)             (or returns Either — see below)
UseCase     ──returns──▶ Future<T>  (throws Failure)
BLoC        ──catches Failure──▶ emits state with failure message
Page        ──BlocListener──▶ SnackBar / banner / dialog
```

Chosen convention: **repositories throw `Failure`**, use cases pass it through, **BLoCs catch** it. (No `Either` dependency; keeps use cases trivial.)

```dart
sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;
}
final class NetworkFailure extends Failure { const NetworkFailure([super.message = 'Server unreachable']); }
final class UnauthorizedFailure extends Failure { const UnauthorizedFailure([super.message = 'Session expired']); }
final class ValidationFailure extends Failure { const ValidationFailure(super.message, {this.fieldErrors = const {}}); final Map<String,String> fieldErrors; }
final class ConflictFailure extends Failure { const ConflictFailure(super.message, {required this.code, this.context = const {}}); final String code; final Map<String,dynamic> context; }
final class NotFoundFailure extends Failure { const NotFoundFailure([super.message = 'Not found']); }
final class ServerFailure extends Failure { const ServerFailure([super.message = 'Server error']); }
```

Deleting a referenced master is **not** a failure either: the API returns 200 with `action` (`deleted`/`deactivated`/`suspended`) — model it as a `DeleteResult`. Counter business outcomes (`success:false`, `error_code`) are **not** failures: they are modelled as a **domain result** (`TapResult` sealed: `TapOk` / `TapRejected(code, message, …)`) so the UI can render banners.

## 6. Dependency injection

`get_it` service locator, initialised in `main()` before `runApp`:

- **Singletons:** `SharedPreferences`, `AppConfig`, `ApiClient`, `SessionStorage`, `AuthBloc`, `AppRouter`.
- **Lazy singletons:** datasources, repositories, use cases.
- **Factories:** feature BLoCs (new instance per page) — provided with `BlocProvider(create: (_) => sl<MemberListBloc>()..add(...))`.
- App-wide BLoC (`AuthBloc`) is provided once at the top via `BlocProvider.value`.

```dart
// core/di/injection.dart
final sl = GetIt.instance;
Future<void> configureDependencies() async {
  await registerCore();        // prefs, config, dio, session
  registerAuth();
  registerCounter();
  registerMembers();
  // … one per feature
}
```

## 7. App bootstrap

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();                  // incl. AppConfig.load()
  await configureWindow();                        // window_manager (size, min size, title)
  runApp(const EcuisineMessApp());
}

class EcuisineMessApp extends StatelessWidget {
  const EcuisineMessApp({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: sl<AuthBloc>()..add(const AuthStarted()),
    child: MaterialApp.router(
      title: 'eCuisine Mess',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light, darkTheme: AppTheme.dark,
      routerConfig: sl<AppRouter>().config,
    ),
  );
}
```

## 8. State ownership

| State | Owner | Scope |
|---|---|---|
| Session / current user / role | `AuthBloc` | App |
| API base URL | `AppConfig` (+ `ServerSettingsCubit` for the dialog) | App |
| Theme mode | `ThemeCubit` (persisted) | App |
| Server clock offset / current meal | `MealClockCubit` (polls `/meal-times/current`; meal windows are **per cuisine**, so it takes an optional `cuisineId` — the tapped member's cuisine on the counter, a selected/default cuisine elsewhere) | App (used by counter header + dashboard) |
| Page data (lists, editors, reports) | Feature BLoC | Page (disposed with route) |
| Ephemeral widget state (hover, text controllers, tab index) | `StatefulWidget` / hooks | Widget |

Rule: **don't put server data in a global BLoC unless several unrelated screens need it live.** Fetch per page; invalidate by re-dispatching `Load`.

## 9. Async, lifecycle and cancellation

- BLoCs use `emit.forEach`/`restartable()` (from `bloc_concurrency`) for search-as-you-type; counter tap uses `droppable()` to ignore taps while one is in flight.
- Close subscriptions/timers in `close()`.
- Do not use `BuildContext` across `await` without `mounted` checks; navigation/side-effects are triggered from `BlocListener`, not from BLoCs.

## 10. Quality gates

`flutter analyze` (with `flutter_lints` + project rules in `analysis_options.yaml`) · `flutter test` · import-boundary check (a small script/`import_lint` rule enforcing §1 table) · no `print` (use a logger).
