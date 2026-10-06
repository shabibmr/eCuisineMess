# ecuisine_mess — Front-end Docs (Flutter, Windows)

Flutter **Windows desktop** client for the eCuisine Mess Module. Talks to the FastAPI backend ([contract](../../docs/04-api-contract.md)).

**Mandated architecture**

1. `flutter_bloc` for state + `go_router` for navigation + **feature-first** structure
2. Every feature has `data/`, `domain/`, `presentation/`
3. **Separate files** for bloc, events, states
4. **Separate files** for pages and widgets
5. **Shared UI components** library

Shared/common docs (business rules, DB, API, UX) are in [`../../docs/`](../../docs/README.md). Read [00](../../docs/00-product-overview.md), [01](../../docs/01-business-rules.md), [04](../../docs/04-api-contract.md) and [05](../../docs/05-screens-ux-spec.md) first.

| Doc | Contents |
|---|---|
| [implementation-plan.md](implementation-plan.md) | **FE-0…FE-6 execution plan** (awaiting approval) — what to build, order, gates |
| [architecture.md](architecture.md) | Layers, dependency rule, feature anatomy, error handling, DI |
| [folder-structure.md](folder-structure.md) | Full target tree, naming, file templates |
| [state-management-bloc.md](state-management-bloc.md) | BLoC conventions, event/state patterns, templates, anti-patterns |
| [routing-go-router.md](routing-go-router.md) | Route table, shell, guards, params, redirects |
| [feature-catalog.md](feature-catalog.md) | Per-feature spec: entities, use cases, events/states, pages, widgets, endpoints |
| [shared-ui-components.md](shared-ui-components.md) | Reusable widget library catalogue + rules |
| [data-layer.md](data-layer.md) | Dio client, datasources, DTOs, repositories, mapping, caching |
| [theming-and-design-tokens.md](theming-and-design-tokens.md) | Theme, tokens, dark mode, typography, Arabic |
| [windows-desktop.md](windows-desktop.md) | RFID wedge, focus, shortcuts, printing, window/kiosk, packaging |
| [testing.md](testing.md) | Test strategy + examples |
| [migration-plan.md](migration-plan.md) | Step-by-step move from the current Provider app |

## Quick facts

| | |
|---|---|
| Package name | `ecuisine_mess` |
| SDK | Flutter 3.44.x, Dart ^3.12 |
| Target | Windows only (`flutter run -d windows`) |
| Default API | `http://127.0.0.1:8000` (user-changeable, persisted) |
| Dev login | `admin` / `admin123` |
| IDs | UUID **strings**; no `code` fields |

## Current state vs. target

The app today uses `provider`, `MaterialApp(home:)` and a layer-first layout (`screens/ models/ services/ providers/ widgets/`). It is being **replaced** by the architecture in these docs; see [migration-plan.md](migration-plan.md). New code must follow the docs; do not extend the old layout.

## Dependencies (target `pubspec.yaml`)

```yaml
dependencies:
  flutter: {sdk: flutter}
  flutter_bloc: ^9.0.0
  bloc_concurrency: ^0.3.0
  equatable: ^2.0.7
  go_router: ^16.0.0
  get_it: ^8.0.0
  dio: ^5.8.0
  shared_preferences: ^2.5.3
  intl: ^0.20.3
  window_manager: ^0.5.0        # Windows window/kiosk control
  audioplayers: ^6.0.0          # counter beeps
  file_selector: ^1.0.3         # CSV save / photo open dialogs (Windows)
  fl_chart: ^1.0.0              # item-movement stacked bar chart
  logger: ^2.5.0
  data_table_2: ^2.6.0          # desktop data grids (optional)
  cupertino_icons: ^1.0.8
dev_dependencies:
  flutter_test: {sdk: flutter}
  flutter_lints: ^6.0.0
  bloc_test: ^10.0.0
  mocktail: ^1.0.4
```
> Versions are minimums at time of writing; run `flutter pub add <pkg>` to resolve the latest compatible, then commit `pubspec.lock`.
