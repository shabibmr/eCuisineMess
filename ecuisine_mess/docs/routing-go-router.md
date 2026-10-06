# Routing — go_router

Declarative, URL-style routes; auth/role **redirect guards**; a **shell** for the navigation rail. Route constants live in `core/router/app_routes.dart` — **never hard-code path strings in widgets**.

## 1. Route table

| Name | Path | Page | Feature | Role | Notes |
|---|---|---|---|---|---|
| `login` | `/login` | `LoginPage` | auth | public | Outside the shell |
| `dashboard` | `/` | `DashboardPage` | dashboard | any | Shell root |
| `counter` | `/counter` | `CounterPage` | counter | any (`counter.use`) | Kiosk: nav rail hidden for role `counter` |
| `bills` | `/bills` | `BillListPage` | bills | any | query: `date`, `meal`, `cuisineId`, `memberId` |
| `billDetail` | `/bills/:billId` | `BillDetailPage` | bills | any | Voucher, reprint, cancel |
| `members` | `/members` | `MemberListPage` | members | supervisor+ view | query: `q`, `cuisineId`, `status` |
| `memberNew` | `/members/new` | `MemberEditorPage` | members | admin | |
| `memberEdit` | `/members/:memberId` | `MemberEditorPage` | members | admin | |
| `cuisines` | `/cuisines` | `CuisineListPage` | cuisines | admin | |
| `cuisineNew` / `cuisineEdit` | `/cuisines/new` · `/cuisines/:cuisineId` | `CuisineEditorPage` | cuisines | admin | Dual-pane mapping |
| `items` | `/items` | `ItemListPage` | items | admin | |
| `itemNew` / `itemEdit` | `/items/new` · `/items/:itemId` | `ItemEditorPage` | items | admin | |
| `itemCategories` | `/item-categories` | `ItemCategoryListPage` | item_categories | admin | list + dialog editor |
| `mealTimes` | `/settings/meal-times` | `MealTimeSettingsPage` | meal_times | admin | |
| `menu` | `/menu` | `DailyMenuEditorPage` | daily_menu | any view / admin edit | query: `date` (default today) |
| `menuHistory` | `/menu/history` | `MenuHistoryPage` | daily_menu | any | query: `from`,`to`,`cuisineId` |
| `reportMembers` | `/reports/members` | `MembersReportPage` | reports | supervisor+ | |
| `reportHeadcount` | `/reports/headcount` | `HeadcountReportPage` | reports | supervisor+ | |
| `reportItems` | `/reports/items` | `ItemMovementReportPage` | reports | supervisor+ | |
| `reportAttendance` | `/reports/attendance` | `AttendanceReportPage` | reports | supervisor+ | |
| `reportTime` | `/reports/time-based` | `TimeBasedReportPage` | reports | supervisor+ | |
| `users` | `/settings/users` | `UserListPage` | users | admin | P5 |
| `gallery` | `/dev/gallery` | `WidgetGalleryPage` | shared | debug only | `kDebugMode` |

Server settings is a **dialog** (`showServerSettingsDialog`), not a route, so it is reachable from the login page.

## 2. Router construction

```dart
// core/router/app_router.dart
class AppRouter {
  AppRouter(this._auth);
  final AuthBloc _auth;

  late final GoRouter config = GoRouter(
    initialLocation: AppRoutes.dashboard.path,
    refreshListenable: GoRouterRefreshStream(_auth.stream),
    redirect: _guard,
    errorBuilder: (_, s) => NotFoundPage(location: s.uri.toString()),
    routes: [
      GoRoute(name: AppRoutes.login.name, path: AppRoutes.login.path, builder: (_, __) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(navigationShell: shell),   // nav rail + content
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, __) => const DashboardPage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/counter', builder: (_, __) => const CounterPage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/bills', builder: …, routes: [GoRoute(path: ':billId', builder: …)])]),
          // members, cuisines, items, item-categories, menu, settings, reports …
        ],
      ),
    ],
  );

  String? _guard(BuildContext context, GoRouterState state) {
    final auth = _auth.state;
    final loggingIn = state.matchedLocation == AppRoutes.login.path;
    if (auth is AuthUnknown) return null;                               // splash
    if (auth is Unauthenticated) return loggingIn ? null : AppRoutes.login.path;
    if (auth is Authenticated) {
      if (loggingIn) return AppRoutes.defaultFor(auth.user.role);       // counter → /counter
      if (!AppPermissions.canOpen(auth.user.role, state.matchedLocation)) return AppRoutes.forbidden.path;
    }
    return null;
  }
}
```

- **Session expiry:** `ApiClient`'s 401 interceptor calls `AuthBloc.add(SessionExpired())` → `Unauthenticated` → guard redirects to `/login`. No logout request is sent.
- **Permissions:** `AppPermissions.canOpen(role, location)` is the single mapping from route prefix → required permission ([matrix](../../docs/00-product-overview.md)). The nav rail uses the same function to hide entries.
- **Default landing:** `admin`/`supervisor` → `/`; `counter` → `/counter`.

## 3. Shell & navigation rail

`AppShell` (shared/layout) renders `NavRail` (destinations from a registry `core/router/nav_destinations.dart`, filtered by role) + `navigationShell`. `StatefulShellRoute.indexedStack` keeps each branch's state (e.g. a half-filled editor survives a tab switch). The **Counter** branch disables state keeping on leave (`navigatorContainerBuilder` / `restorationScopeId: null`) so the invoice never lingers.

Reports are one rail destination expanding to the five report routes (`ExpansionTile`/flyout).

## 4. Parameters

- **Path params** for identity: `/members/:memberId` → `state.pathParameters['memberId']`.
- **Query params** for view state that should survive refresh/deep-link: `date`, filters. Pages parse them into the initial BLoC event; changing a filter calls `context.goNamed(..., queryParameters: …)` **and** the bloc responds to the new event (single source: URL → page → event).
- **`extra`** only for transient, non-restorable objects (e.g. `Bill` to show instantly in a dialog) — pages must still work from the URL alone.
- UUIDs only in URLs; never RFID numbers or PII.

## 5. Navigating

```dart
context.goNamed(AppRoutes.memberEdit.name, pathParameters: {'memberId': m.id});
context.pushNamed(AppRoutes.billDetail.name, pathParameters: {'billId': id});  // push for drill-downs
context.pop();                                                                  // after save/cancel
```
- `go` between top-level destinations; `push` for editors/drill-downs so Back returns to the list.
- Unsaved-changes guard in editors: `PopScope(canPop: !state.isDirty, onPopInvokedWithResult: …)` → Save / Discard / Cancel dialog.
- After successful create/update the editor pops and the list page refreshes (the list BLoC re-fetches on `RouteAware`/result: `final changed = await context.pushNamed<bool>(…); if (changed == true) bloc.add(Refreshed())`).

## 6. Keyboard-driven navigation

`Alt+1…9`, `Ctrl+K` palette, etc. are `Shortcuts`/`Actions` wrapped around `AppShell`; actions call `GoRouter.of(context).goNamed(...)` using the same registry ([windows-desktop.md](windows-desktop.md)).

## 7. Testing routes

Pump `MaterialApp.router` with a test `GoRouter` and a fake `AuthBloc`; assert redirects for each of: unauthenticated → `/login`; `counter` role → `/members` → forbidden; admin → `/`. See [testing.md](testing.md).
