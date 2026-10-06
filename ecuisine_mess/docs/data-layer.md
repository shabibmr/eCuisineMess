# Data Layer

Each feature's `data/` converts between the **API contract** ([04](../../docs/04-api-contract.md)) and **domain entities**. Presentation never sees JSON or DTOs.

## 1. Network core (`core/network/`)

```dart
class ApiClient {
  ApiClient(this._config, this._session) {
    _dio = Dio(BaseOptions(
      baseUrl: '${_config.baseUrl}/api/v1',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ))..interceptors.addAll([AuthInterceptor(_session), ErrorInterceptor(), if (kDebugMode) LogInterceptor(...)]);
  }
  Dio get dio => _dio;
  void updateBaseUrl(String root) => _dio.options.baseUrl = '$root/api/v1';   // after Server Settings save
}
```

| Interceptor | Behaviour |
|---|---|
| `AuthInterceptor` | Adds `Authorization: Bearer <token>` when a session exists |
| `ErrorInterceptor` | Maps `DioException` → typed exceptions: timeout/socket → `NetworkException`; 401 → `UnauthorizedException` **and** notifies `AuthBloc.SessionExpired` (local clear, no logout call); 404 → `NotFoundException`; 409 → `ConflictException(code, context)`; 400/422 → `ValidationException(fieldErrors)`; ≥500 → `ServerException` |
| Message extraction | The backend has three error envelopes today (`{success:false,error_code,message,details}`, `{success:false,detail,message}`, 422 `{error_code:"VALIDATION_ERROR",detail:[{loc,msg}]}`). `ErrorInterceptor` reads **`message`**, else string **`detail`**, else joins `detail[].msg`, and keeps `error_code` when present. **HTTP 400 is mapped to `ValidationFailure(message)`** (the backend returns 400 for duplicate RFID/name/username today); 409 → `ConflictFailure(code, context)` once the backend moves duplicates to 409 ([04 §1.2](../../docs/04-api-contract.md)) |
| Logging | Debug only; **redacts** `Authorization`, `password`, and full RFID values |

`ApiEndpoints` holds every path as a constant/function (`ApiEndpoints.member(id)`), so paths exist once.

## 2. Datasource

Thin: one method per endpoint, returns **DTOs** or raw parsed JSON, throws exceptions from §1.

```dart
abstract interface class MemberRemoteDataSource {
  Future<List<MemberModel>> getMembers(MembersQuery q);
  Future<MemberModel> getMember(String id);
  Future<MemberModel> createMember(MemberModel m);
  Future<MemberModel> updateMember(String id, MemberModel m);
  Future<void> deleteMember(String id);
}

class MemberRemoteDataSourceImpl implements MemberRemoteDataSource {
  MemberRemoteDataSourceImpl(this._api); final ApiClient _api;
  @override
  Future<List<MemberModel>> getMembers(MembersQuery q) async {
    final res = await _api.dio.get<List<dynamic>>(ApiEndpoints.members, queryParameters: q.toQuery());
    return res.data!.map((e) => MemberModel.fromJson(e as Map<String, dynamic>)).toList();
  }
  // …
}
```

## 3. DTO (`…Model`)

- `fromJson` tolerant: nullable-safe, `snake_case` keys, numeric strings (`DECIMAL`), `0/1` booleans.
- `toJson` only includes **writable** fields; **never sends `id` on create**.
- `toEntity()` / `fromEntity()` mapping methods. No Flutter imports.

Helpers in `core/utils/json.dart`: `asBool`, `asDouble`, `asDate`, `asTime`, `asString`.

```dart
bool asBool(Object? v) => v == true || v == 1 || v == '1';
double asDouble(Object? v) => v is num ? v.toDouble() : double.parse('$v');
```

## 4. Repository implementation

- Calls datasource, maps DTO → entity.
- **Catches exceptions → throws `Failure`** (one mapper function `mapException(Object e)` in `core/error/`).
- Contains **no caching by default**. Opt-in short-TTL cache only for reference lists that many screens need (cuisines, categories, meal times) — implemented inside the repo as an in-memory field with explicit `invalidate()` on every write.

```dart
class MemberRepositoryImpl implements MemberRepository {
  MemberRepositoryImpl(this._remote); final MemberRemoteDataSource _remote;
  @override
  Future<List<Member>> getMembers(MembersQuery q) async {
    try { return (await _remote.getMembers(q)).map((m) => m.toEntity()).toList(); }
    on Object catch (e) { throw mapException(e); }
  }
}
```

## 5. Counter special case

`TapRfid` returns `TapResult` (sealed). The datasource parses `success` and `error_code`; unknown `error_code` → `TapRejected(code: TapRejectCode.unknown, message: serverMessage)`. HTTP/network problems are **failures**, business rejections are **results**.

## 6. Session storage

`SessionLocalDataSource` (shared_preferences): `mess_session_token`, `mess_session_user` (json), `mess_session_expires`. On start, `RestoreSession` loads token → `GET /auth/me`; 401 → clear. (Windows: for production consider `flutter_secure_storage`; prefs are plain text.)

## 7. Config storage

`AppConfig` keeps `mess_api_base_url` (default `http://127.0.0.1:8000`, trimmed of trailing `/`), validated as `http(s)://host[:port]`. `SaveServerSettings` pings `GET /health` (3 s) before persisting.

## 8. Paging, search, concurrency

- Lists: pass `limit`/`offset` when contract supports; otherwise client-side paging in the bloc.
- Search-as-you-type is debounced in the **bloc transformer**, not in the datasource.
- Cancel in-flight requests with `CancelToken` when a `restartable()` event supersedes (the datasource accepts an optional `CancelToken`).

## 9. Files / CSV

Report export: `dio.get<List<int>>(..., options: Options(responseType: ResponseType.bytes))` → bytes saved verbatim (pipe delimiter and BOM are preserved).

## 10. Mapping table — key DTOs

| Entity | Wire fields |
|---|---|
| `Member` | `id, name, rfid_tag, phone, email, cuisine_id, cuisine_name, validity_start, validity_end, status, days_left, photo_url` |
| `Item` | read: `id, item_name, category_id, category_name, uom_id, unit` (= `uom_name`), `is_active`, `mapped_cuisines[]` (detail only) · write: `item_name, category_id, uom_id, is_active` (**no writable `unit`**) |
| `Uom` | `id, uom_name, sort_order, is_active` (read-only lookup, `GET /uoms`) |
| `Cuisine` | `id, cuisine_name, description, is_active, mapped_items_count, active_members_count` |
| `MealTime` | `id, cuisine_id, cuisine_name, meal_type, name, start_time, end_time, is_active` (per cuisine; `GET /meal-times?cuisine_id=`) |
| `Bill` | `id, bill_number, token_number, bill_date, bill_time, member_*, cuisine_*, meal_type, total_amount, status, is_override, override_by, override_reason, cancelled_*, items[]` |

No `*_code` fields exist in any DTO.


## 11. Delete results (`action`)

`DELETE` on item / cuisine / item-category / member returns **200** with `{success, action: 'deleted' | 'deactivated' | 'suspended', message}` — it is **not** an error. Repositories return a `DeleteResult` entity (`enum DeleteAction`, `message`); the BLoC shows `message` and refreshes the list (a deactivated row disappears from active-only lists or shows greyed with *Show inactive*). The UI asks for confirmation *before* calling delete (wording: "Delete X? If it is in use it will be marked inactive instead").
