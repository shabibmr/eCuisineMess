# Front-end Testing

Commands: `flutter analyze` · `flutter test` · `flutter test --coverage`. Test tree mirrors `lib/`.

```
test/
├── core/            network (interceptors), error mapper, router guards, json helpers
├── shared/widgets/  widget + golden tests
├── helpers/         pump_app.dart, fakes, fixtures (json), mock classes
└── features/<feature>/
    ├── data/        model parsing, datasource (mock Dio adapter), repository mapping
    ├── domain/      use cases
    └── presentation/ bloc tests, page widget tests
```

## 1. What to test, by layer

| Layer | Tool | Cases |
|---|---|---|
| DTO | plain `test` | Parses fixture JSON incl. DECIMAL-as-string, `0/1` bools, null optionals; `toJson` omits `id`; **no `code` keys** |
| Datasource | `dio_adapter`/`http_mock_adapter` | Path, query, body shape; error mapping 401/409/422/5xx/timeouts |
| Repository | `mocktail` datasource | DTO→entity mapping; exception→`Failure` mapping |
| Use case | `mocktail` repository | Pass-through & any orchestration |
| **BLoC** | `bloc_test` | initial → loading → success; failure; concurrency (`restartable`/`droppable`); validation; each conflict code |
| Page | `testWidgets` + `MockBloc` | Renders each state; callbacks dispatch events; BlocListener side-effects |
| Shared widget | widget + golden | States, keyboard behaviour, a11y labels |
| Router | `testWidgets` | Redirect matrix: unauth → login; role-based forbidden; deep link with params |

## 2. Priority: Counter

Must-have tests (they encode the money path):

1. `RfidSubmitted` valid → `[Tapping, Ready]` with lines from the response.
2. Each `error_code` (`UNREGISTERED`, `SUSPENDED`, `EXPIRED`, `NO_MEAL_SERVICE`, `MENU_NOT_SET`, `ALREADY_SERVED`, unknown) → `Rejected` with the right banner text; invoice empty.
3. `RfidSubmitted` twice quickly → second is dropped (`droppable`).
4. New tap while `Ready` → invoice replaced (BR-B3).
5. `SaveRequested` twice → exactly one `issueToken` call (BR-B4 client side).
6. `ALREADY_SERVED` → override path → `IssueToken(override)` called with supervisor id/reason.
7. Network failure while `Ready` keeps the invoice and offers retry.
8. After `SlipClosed` → `Idle(lastToken)` and focus request emitted.
9. `ApiClient` 401 → `AuthBloc` receives `SessionExpired`.

Widget: `CounterPage` with `MockCounterBloc` shows the red `RejectionBanner` and **no** invoice rows for rejected states; F10 triggers `SaveRequested` only in `Ready`.

## 3. Fixtures

`test/helpers/fixtures/*.json` copied from real API responses (sanitised). One fixture per DTO + one per counter outcome. Keep in sync with [04](../../docs/04-api-contract.md); a contract change updates the fixture first.

## 4. Pump helper

```dart
Future<void> pumpApp(WidgetTester t, Widget child, {AuthBloc? auth, GoRouter? router}) async {
  await t.pumpWidget(MultiBlocProvider(
    providers: [BlocProvider<AuthBloc>.value(value: auth ?? FakeAuthBloc())],
    child: MaterialApp(theme: AppTheme.light, home: child),
  ));
}
```

## 5. Integration (manual + scripted)

Against a real API + test DB (`ecuisine_mess_test`):
- `integration_test/` driver on Windows: login → counter → tap seeded valid card → F10 → slip → bill appears in register → cancel.
- Smoke script (`scripts/smoke.ps1`): `flutter analyze; flutter test; flutter build windows --debug` then launch the exe for 5 s and check the process stays alive (existing approach from App Shell phase).

## 6. CI gates (when CI exists)

`flutter pub get` → `flutter analyze --fatal-infos` → `flutter test --coverage` (target ≥ 70 % for `domain`+`presentation/bloc`, ≥ 90 % for `counter`) → import-boundary lint → `flutter build windows --release`.

## 7. Conventions

- Test names: `'<unit> when <situation> emits/returns <outcome>'`.
- No real network or `SharedPreferences` — use `SharedPreferences.setMockInitialValues`.
- Prefer fakes for stateful collaborators, mocks for verification.
- Goldens only for `TokenSlip` and a few dense components; generate on Windows at 100 % scale and commit.
