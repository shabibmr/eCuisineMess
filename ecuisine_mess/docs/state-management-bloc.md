# State Management — flutter_bloc

**Rule:** one BLoC (or Cubit) per screen concern; **separate files** for bloc, events, states (linked with `part`/`part of`, see [folder-structure §2](folder-structure.md)).

## 1. BLoC vs Cubit

| Use | When |
|---|---|
| **Bloc** (events) | Anything with user-driven transitions, concurrency rules, or that is traced/tested by event: lists with search/filter/paging, editors, **counter**, auth, reports |
| **Cubit** | Tiny, linear state with no event semantics: theme mode, server-settings dialog, meal clock |

Even Cubits live in `…_cubit.dart` + `…_state.dart` (two files).

## 2. Conventions

1. **Events** — `sealed class XEvent extends Equatable`; past-tense-ish or imperative names describing *intent*: `MemberListStarted`, `MemberListSearchChanged(query)`, `MemberListRefreshed`, `MemberDeleteRequested(id)`.
2. **States** — one immutable class with a **status enum** + data (`copyWith`) for list/editor screens; a **sealed hierarchy** when states are mutually exclusive and carry different data (auth, counter).
3. **Status enum** — `enum Status { initial, loading, success, failure }` (shared in `core/utils/status.dart`) for page data; add `submitting` for editors.
4. **One-shot effects** (snackbar, navigate, open dialog) are **not** states that stay forever. Use either:
   - a nullable `effect`/`message` field that the page consumes via `BlocListener` and then the bloc clears (`MessageConsumed` event), or
   - `listenWhen` on a status transition (`submitting → success`).
5. **No `BuildContext`, no widgets, no navigation** inside a BLoC.
6. **Dependencies** are use cases (constructor-injected). No `get_it` calls inside blocs.
7. **Handlers** are small private methods `_onX(event, emit)`; register in constructor with `on<X>(_onX, transformer: …)`.
8. **Concurrency** (`bloc_concurrency`): `restartable()` for search/type-ahead, `droppable()` for submit/tap, `sequential()` default, `concurrent()` rarely.
9. **Error → state:** catch `Failure`, emit `status: failure, error: failure.message`. Never emit raw exceptions.
10. **Equatable everywhere** so states dedupe; lists in props are fine (use immutable lists).
11. Page owns creation: `BlocProvider(create: (_) => sl<MemberListBloc>()..add(const MemberListStarted()), child: …)`.
12. Widgets read with `context.select`/`BlocSelector` to limit rebuilds; use `BlocBuilder` + `buildWhen` for big trees.

## 3. Template — list screen

```dart
// member_list_event.dart
part of 'member_list_bloc.dart';

sealed class MemberListEvent extends Equatable {
  const MemberListEvent();
  @override List<Object?> get props => [];
}
final class MemberListStarted extends MemberListEvent { const MemberListStarted(); }
final class MemberListRefreshed extends MemberListEvent { const MemberListRefreshed(); }
final class MemberListSearchChanged extends MemberListEvent {
  const MemberListSearchChanged(this.query); final String query;
  @override List<Object?> get props => [query];
}
final class MemberListFilterChanged extends MemberListEvent {
  const MemberListFilterChanged({this.cuisineId, this.status, this.includeInactive});
  final String? cuisineId; final MemberStatus? status; final bool? includeInactive;
  @override List<Object?> get props => [cuisineId, status, includeInactive];
}
final class MemberDeleteRequested extends MemberListEvent {
  const MemberDeleteRequested(this.id); final String id;
  @override List<Object?> get props => [id];
}
```

```dart
// member_list_state.dart
part of 'member_list_bloc.dart';

final class MemberListState extends Equatable {
  const MemberListState({
    this.status = Status.initial, this.members = const [], this.query = '',
    this.cuisineId, this.memberStatus, this.includeInactive = false,
    this.error, this.notice,
  });
  final Status status; final List<Member> members; final String query;
  final String? cuisineId; final MemberStatus? memberStatus; final bool includeInactive;
  final String? error;   // failure message for banner
  final String? notice;  // one-shot snackbar text; page clears via MemberListNoticeConsumed

  MemberListState copyWith({Status? status, List<Member>? members, String? query,
      Object? cuisineId = _keep, Object? memberStatus = _keep, bool? includeInactive,
      String? error, String? notice, bool clearNotice = false}) => /* … */;

  @override List<Object?> get props => [status, members, query, cuisineId, memberStatus, includeInactive, error, notice];
}
```

```dart
// member_list_bloc.dart
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'member_list_event.dart';
part 'member_list_state.dart';

class MemberListBloc extends Bloc<MemberListEvent, MemberListState> {
  MemberListBloc({required GetMembers getMembers, required DeleteMember deleteMember})
      : _getMembers = getMembers, _deleteMember = deleteMember, super(const MemberListState()) {
    on<MemberListStarted>(_load);
    on<MemberListRefreshed>(_load);
    on<MemberListSearchChanged>(_onSearch, transformer: restartable());   // + debounce in transformer
    on<MemberListFilterChanged>(_onFilter);
    on<MemberDeleteRequested>(_onDelete, transformer: droppable());
  }
  final GetMembers _getMembers; final DeleteMember _deleteMember;

  Future<void> _load(MemberListEvent _, Emitter<MemberListState> emit) async {
    emit(state.copyWith(status: Status.loading, error: null));
    try {
      final list = await _getMembers(MembersQuery(search: state.query, cuisineId: state.cuisineId,
          status: state.memberStatus, includeInactive: state.includeInactive));
      emit(state.copyWith(status: Status.success, members: list));
    } on Failure catch (f) {
      emit(state.copyWith(status: Status.failure, error: f.message));
    }
  }
  // _onSearch: emit(state.copyWith(query: e.query)); await _load(e, emit);
  // _onDelete: result = await _deleteMember(id); notice = result.message  (action 'suspended' when the member has bills)
}
```

## 4. Template — editor screen

State has `status` (`initial/loading/ready/submitting/success/failure`), the `draft` form values, `fieldErrors` (`Map<String,String>`), and `isDirty`.
Events: `EditorStarted(id?)`, `FieldChanged(name, value)`, `SaveSubmitted({bool andNew})`, `Discarded`, `DeleteRequested`.
Validation: pure functions in `domain/validators/` run in the BLoC on every change → `fieldErrors`; **Save is enabled only when `fieldErrors.isEmpty && isDirty`**. Server `ValidationFailure.fieldErrors`/`ConflictFailure` are merged into `fieldErrors` (e.g. `RFID_IN_USE` → `rfidTag: 'Already linked to <name>'`). Leaving with `isDirty` → page shows the Save/Discard/Cancel dialog (`PopScope`).

## 5. Template — sealed states (auth)

```dart
sealed class AuthState extends Equatable { const AuthState(); @override List<Object?> get props => []; }
final class AuthUnknown extends AuthState { const AuthUnknown(); }            // restoring session
final class Authenticated extends AuthState { const Authenticated(this.user); final AppUser user; @override List<Object?> get props => [user]; }
final class Unauthenticated extends AuthState { const Unauthenticated({this.message}); final String? message; @override List<Object?> get props => [message]; }
```
GoRouter listens to `AuthBloc.stream` via `GoRouterRefreshStream` and redirects ([routing](routing-go-router.md)).

## 6. The Counter BLoC (reference implementation)

The only screen with a real state machine. States (sealed):

| State | Meaning | UI |
|---|---|---|
| `CounterIdle` | Waiting for tap; carries `lastToken?`, `server meal` | RFID field focused, empty invoice |
| `CounterTapping` | Request in flight | spinner on RFID field; further taps dropped |
| `CounterReady(member, mealType, items, today, existingBill?)` | Valid entitlement loaded | Member card + invoice; F10 enabled |
| `CounterRejected(code, message, member?, existingBill?)` | Business rejection | Full-width red banner + beep; `ALREADY_SERVED` offers **Supervisor Override** (F8) |
| `CounterIssuing` | Issue request in flight | Save disabled |
| `CounterIssued(bill)` | Token created | Slip dialog → on close, back to `CounterIdle(lastToken)` |
| `CounterFailure(failure)` | Network/server error | Retry banner; invoice preserved if `Ready` |

Events: `RfidSubmitted(tag)`, `SaveRequested`, `ClearRequested`, `OverrideRequested(supervisorId, reason)`, `SlipClosed`, `BannerDismissed`.
Transformers: `RfidSubmitted` → `droppable()`; `SaveRequested` → `droppable()` (prevents double token on double-press).
New `RfidSubmitted` while `CounterReady` **replaces** the invoice (BR-B3).
Side-effects (beep, focus, slip dialog) in `BlocListener`s on the page, never in the bloc.

## 7. Testing blocs

`bloc_test` + `mocktail`: arrange mock use cases → `act: bloc.add(...)` → `expect: [states]`. Every bloc has tests for: initial load, failure path, concurrency rule (where used), and each rule-related branch (e.g. conflict codes). See [testing.md](testing.md).

## 8. Anti-patterns (reject in review)

- Business logic or `Dio` in a widget/page.
- BLoC referencing `BuildContext`, `Navigator`, `ScaffoldMessenger`.
- Feature A's bloc reading Feature B's bloc (`context.read<B>()` inside A). Share via a use case/domain stream.
- Giant state with 20 nullable fields — split into sealed states or sub-blocs.
- Emitting after `close()` / not guarding async gaps; forgetting `restartable()` on search.
- Mutable collections in state; `props` missing a field.
- Putting events/states in the same file as unrelated widgets; multiple blocs per file.
