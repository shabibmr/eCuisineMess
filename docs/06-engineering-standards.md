# 06 — Engineering Standards (shared)

Layer-specific rules: [Flutter](../ecuisine_mess/docs/README.md) · [Backend](../backend_api/docs/README.md). This doc holds what both sides must agree on.

## 1. Naming

| Thing | Convention | Example |
|---|---|---|
| DB tables | `mess_` + plural snake | `mess_daily_menu_items` |
| DB columns | snake_case; booleans `is_…`; FKs `<entity>_id` | `is_active`, `cuisine_id` |
| JSON keys | snake_case (identical to DB column names where 1:1) | `validity_end` |
| REST paths | kebab-case, plural nouns | `/item-categories`, `/meal-times` |
| Python | PEP 8, `snake_case`, type hints | |
| Dart files | `snake_case.dart`; suffix by role | `member_bloc.dart`, `member_event.dart`, `member_state.dart`, `member_page.dart` |
| Dart types | `UpperCamelCase`; DTO `…Model`, domain `…` (no suffix) | `MemberModel` ↔ `Member` |
| Constants | Dart `lowerCamelCase`; Python `UPPER_SNAKE` | |
| Enums (wire) | UPPER_SNAKE strings | `BREAKFAST`, `ALREADY_SERVED` |

## 2. Identifiers & codes

- IDs are UUID strings. Generated **only** by the API. Never display them to users; never sort by them.
- **No `*_code`.** Do not reintroduce `member_code`, `item_code`, … in schema, API, models or UI.
- Operational numbers (`bill_number`, `token_number`) are the only human-readable identifiers.

## 3. Dates, times, numbers

| Type | Wire format | Notes |
|---|---|---|
| Date | `YYYY-MM-DD` | No timezone — single site |
| Time | `HH:MM:SS` | |
| Timestamp | ISO-8601 `YYYY-MM-DDTHH:MM:SS` | server local time |
| Quantity / money | JSON number, 2 dp | parse defensively in Dart |
| Booleans | `true/false` for new endpoints; legacy `0/1` accepted | |

UI display format: `dd-MM-yyyy`, 24-hour `HH:mm` (as in spec/mock). Display formatting happens in the UI only (`intl`).

## 4. Errors

- Business outcomes the user must see in a banner → HTTP 200 + `{success:false, error_code, message}` (counter only).
- Everything else → proper HTTP status + `{detail, code?, context?}` ([04 §1](04-api-contract.md)).
- The client maps responses to a sealed `Failure` hierarchy (`NetworkFailure`, `UnauthorizedFailure`, `ConflictFailure(code, context)`, `ValidationFailure`, `ServerFailure`). Messages shown to users are never raw stack traces or SQL.
- Never swallow errors silently; log with context and surface a retryable state.

## 5. Security baseline

- Passwords: bcrypt. Tokens: `secrets.token_urlsafe(32)`, ≥ 7-day expiry configurable.
- Business routes require auth (BR-U4); role checks server-side (BR-U5).
- No hard-coded secrets/PINs in client code. The demo PIN `1234` is dev-only and removed when `verify-supervisor` ships.
- DB credentials via environment (`MESS_DB_*`), never committed. Dedicated DB user in production.
- CORS: `*` is dev-only; restrict origins in production (desktop client doesn't need CORS at all).
- Parameterised SQL **always** (`%s` placeholders); never string-format user input into SQL.
- Do not log RFID tags in full, passwords, or tokens.

## 6. Git workflow

- Branch from `main`: `feature/<area>-<short>`, `fix/<short>`, `docs/<short>`.
- Conventional-style commits: `feat(counter): …`, `fix(api): …`, `docs: …`, `db: …`.
- One concern per PR; schema change ⇒ migration file **and** `schema.sql` **and** `docs/03` updated together; API change ⇒ `docs/04` updated first.
- Don't commit: `build/`, `.dart_tool/`, `__pycache__/`, `mariadb/data/`, `.env`. *(Today `__pycache__/*.pyc` and the MariaDB data folder are present in the working tree — add them to `.gitignore`; see [08](08-gap-analysis-roadmap.md).)*
- `flutter_app/` was removed; `ecuisine_mess/` is the only client.

## 7. Definition of Done

A change is done when:

- [ ] Behaviour matches the relevant `BR-*` rules and the mock-ui.
- [ ] Backend: new/changed endpoint documented in `docs/04`, covered by a test, parameterised SQL, auth + role applied.
- [ ] Flutter: `flutter analyze` clean, `flutter test` green, bloc/event/state in separate files, page vs widgets split, shared components reused (not duplicated).
- [ ] DB: migration + `schema.sql` + seed updated; works on a fresh install **and** an existing DB.
- [ ] Verified manually on Windows against a real MariaDB (not just unit tests).
- [ ] Docs updated.

## 8. Testing pyramid (shared view)

| Level | Backend | Flutter |
|---|---|---|
| Unit | Services / rule functions (meal window, validity, token format) with fake repos | Use cases, repositories (mock datasource), BLoCs (`bloc_test`), DTO parsing |
| Integration | API against a throwaway MariaDB schema (`ecuisine_mess_test`) | Datasource against a mock HTTP adapter |
| Widget/UI | — | Pages with `MockBloc`, golden tests for token slip |
| E2E smoke | `scripts/smoke.ps1`: health → login → tap → issue → cancel | `flutter build windows --debug` + launch check |

Counter flow (`BR-B*`, error-code table in [01 §E](01-business-rules.md)) is the **highest-priority** area for tests.

## 9. Documentation rules

- Docs are Markdown in the repo, reviewed like code.
- Diagrams: Mermaid in-file (renders on GitHub/VS Code).
- Each doc states its source of truth and status legend; mark unverified claims as such.
