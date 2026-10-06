# Feature Catalog

For each feature: **purpose · entities · use cases · BLoCs (events → states) · pages · widgets · endpoints · rules**. Every feature follows `data/ domain/ presentation/`; bloc/event/state are separate files; pages and widgets are separate files ([folder-structure](folder-structure.md)). Behaviour detail: [business rules](../../docs/01-business-rules.md), [screens](../../docs/05-screens-ux-spec.md), endpoints: [API contract](../../docs/04-api-contract.md).

Build order follows the roadmap phases P0–P5 ([08](../../docs/08-gap-analysis-roadmap.md)).

Shared pieces referenced below are in [shared-ui-components.md](shared-ui-components.md).

---

## 1. `auth` (P0)

| | |
|---|---|
| Purpose | Login, session restore, logout, current user/role, supervisor verification |
| Entities | `AppUser {id, username, displayName, role}`, `Session {token, expiresAt}` |
| Use cases | `Login`, `RestoreSession`, `Logout`, `GetCurrentUser`, `VerifySupervisor` (P1) |
| Data | `AuthRemoteDataSource`, `SessionLocalDataSource` (shared_preferences key `mess_session`), `AuthRepositoryImpl` |
| BLoC | **`AuthBloc`** (app-wide) — events `AuthStarted`, `LoginSubmitted(username,password)`, `LogoutRequested`, `SessionExpired`; states sealed `AuthUnknown / Authenticated(user) / Unauthenticated(message?)` |
| BLoC | **`LoginFormBloc`/Cubit** — fields, `submitting`, error text |
| Pages | `LoginPage` |
| Widgets | `LoginForm`, `ServerSettingsButton` (opens settings dialog) |
| Endpoints | `POST /auth/login`, `GET /auth/me`, `POST /auth/logout`, `POST /auth/verify-supervisor` |
| Rules | BR-U1…U5. 401 anywhere → `SessionExpired` (local clear only) |

## 2. `settings` (P0)

| | |
|---|---|
| Purpose | API base URL, theme mode, (later) counter id, printer |
| Entities | `ServerSettings {baseUrl}`, `ThemeSetting` |
| Use cases | `GetServerSettings`, `SaveServerSettings` (validates URL, pings `/health`), `GetThemeMode`, `SetThemeMode` |
| BLoC | `ServerSettingsCubit` (`initial/testing/ok/error`), `ThemeCubit` |
| Pages/widgets | `ServerSettingsDialog` (shown from login + shell), `ThemeToggleButton` |
| Notes | Replaces `server_settings_dialog.dart` + `ApiConfig`. Saving rebuilds `ApiClient.baseUrl` |

## 3. `dashboard` (P4)

| | |
|---|---|
| Purpose | Overview: meal timeline, menu readiness, served-today KPIs, shortcuts |
| Entities | `DashboardSummary {serverTime, currentMeal, nextMeal, served{B,L,D,total}, readiness[], expiringMembers}` |
| Use cases | `GetDashboardSummary` |
| BLoC | `DashboardBloc` — `DashboardStarted`, `DashboardRefreshed` (auto every 60 s); states `loading/success/failure` |
| Pages | `DashboardPage` |
| Widgets | `MealTimeline`, `MenuReadinessGrid`, `ServedTodayKpis`, `QuickActionTiles` |
| Endpoints | `GET /dashboard/summary` |

## 4. `counter` (P1) — the critical feature

| | |
|---|---|
| Purpose | RFID tap → validate → invoice preview → issue token → slip |
| Entities | `CounterMember {id,name,cuisineId,cuisineName,phone,validityEnd,daysLeft,photoUrl}`, `InvoiceLine {itemId,itemName,quantity,unit,categoryName}`, `TapResult` (sealed `TapOk{member, mealType, window, lines, today}` / `TapRejected{code, message, member?, existingBill?, next?}`), `IssuedBill {id, billNumber, tokenNumber, date, time, memberName, cuisine, mealType, lines, isOverride}` |
| Use cases | `TapRfid`, `IssueToken` (with optional `OverrideAuth`), `GetCurrentMeal` |
| BLoC | **`CounterBloc`** — see [state machine](state-management-bloc.md#6-the-counter-bloc-reference-implementation) |
| BLoC | `MealClockCubit` (app/shell scope): polls `/meal-times/current` every 30 s, ticks the clock per second locally |
| Pages | `CounterPage` |
| Widgets | `CounterHeader` (meal + window + clock), `RfidInputField` (always-focused), `MemberCard`, `TodayMealStrip` (B✔ L— D—), `InvoiceGrid`, `RejectionBanner`, `CounterActionBar` (Save F10 · Clear Esc · Supervisor F8 · Last token), `SupervisorOverrideDialog`, `RfidTapSimulator` (debug only) |
| Shared used | `TokenSlipDialog`, `ErrorBanner`, `MealBadge`, `SoundPlayer`, `ConfirmDialog` |
| Endpoints | `POST /counter/tap`, `POST /counter/issue-token`, `POST /auth/verify-supervisor`, `GET /meal-times/current` |
| Rules | BR-B1…B9, BR-O*, tap validation order in [01 §E](../../docs/01-business-rules.md). Focus returns to RFID after any action. Lines read-only. No member code shown |
| Kiosk | Role `counter` lands here; nav rail hidden; exit `Ctrl+Shift+L` |

## 5. `bills` (P1)

| | |
|---|---|
| Purpose | Bill Register: filter, view voucher, reprint (DUPLICATE), cancel |
| Entities | `Bill`, `BillLine`, `BillStatus {served, cancelled}`, `BillFilter {from,to,mealType,cuisineId,memberId,search,status}` |
| Use cases | `GetBills`, `GetBill`, `CancelBill(billId, reason, supervisorAuth)` |
| BLoC | `BillListBloc` (`Started`, `FilterChanged`, `Refreshed`, `PageRequested`); `BillDetailBloc` (`Started(id)`, `CancelRequested(reason)`, `ReprintRequested`) |
| Pages | `BillListPage`, `BillDetailPage` (or side drawer) |
| Widgets | `BillFilterBar` (uses `MemberPicker`, `CuisinePicker`), `BillTable` (cancelled rows struck-through, override badge), `BillVoucherView`, `CancelBillDialog` |
| Shared used | `AppDataTable`, `TokenSlipDialog(duplicate: true)`, `FilterBar` |
| Endpoints | `GET /bills`, `GET /bills/{id}`, `POST /bills/{id}/cancel` |
| Rules | BR-X1…X4. Cancel needs `bill.cancel` + reason + supervisor auth |

## 6. `members` (P2)

| | |
|---|---|
| Entities | `Member {id,name,rfidTag,phone,email,cuisineId,cuisineName,validityStart,validityEnd,status,daysLeft,photoUrl}`, `MemberStatus {active, expired, suspended}`, `MembersQuery` |
| Use cases | `GetMembers`, `GetMember`, `SaveMember` (create/update), `DeleteMember`, `CheckRfidAvailable` |
| BLoC | `MemberListBloc`; `MemberEditorBloc` (form + validation + RFID capture state) |
| Pages | `MemberListPage`, `MemberEditorPage` |
| Widgets | `MemberTable` (masked RFID `••••1234`, Valid To highlighted when expired / ≤ 7 days, status chip), `MemberFilterBar`, `MemberForm`, `RfidCaptureField` (Capture → "Tap card now…", 15 s timeout ring, duplicate check, Clear RFID), `PhotoPicker` |
| Shared used | `MasterPage`, `CuisinePicker`, `DateField`, `StatusChip`, `FormDialog`/`PageScaffold` |
| Endpoints | `GET/POST /members`, `GET/PUT/DELETE /members/{id}`, `GET /members/by-rfid/{tag}` |
| Rules | BR-M1…M8 |

## 7. `cuisines` (P2)

| | |
|---|---|
| Entities | `Cuisine {id,name,description,isActive,mappedItemsCount,activeMembersCount}`, `CuisineItemMapping {itemId,itemName,uomName,defaultQty,sortOrder,isActive}` |
| Use cases | `GetCuisines`, `GetCuisine`, `SaveCuisine` (header + mapping), `DeleteCuisine`, `CopyMapping` |
| BLoC | `CuisineListBloc`; **`CuisineEditorBloc`** (header draft; `available`/`mapped` lists; events `ItemsAdded(ids)`, `ItemsRemoved(ids)`, `AllAdded`, `AllRemoved`, `QtyChanged`, `CopyMappingRequested(fromId)`, `SaveSubmitted`) |
| Pages | `CuisineListPage`, `CuisineEditorPage` |
| Widgets | `CuisineTable`, `CuisineHeaderForm`, **`DualPaneMapper`** (available ◀▶ mapped; search; category filter; checkboxes; double-click move; drag handles) — generic, lives in `shared/widgets/` as `DualPaneList<T>` |
| Rules | BR-C1…C6; shows warning when mapping empty; `UNMAP_BLOCKED` conflict lists dates in a dialog |

## 8. `items` (P2)

| | |
|---|---|
| Entities | `Item {id,name,categoryId,categoryName,uomId,uomName,isActive,mappedCuisines[]}`, `Uom {id,name}` (lookup; seed-only, **no UOM screen**) |
| Use cases | `GetItems(query)`, `GetItem`, `SaveItem`, `DeleteItem` (returns `DeleteResult` — deleted/deactivated), `GetUoms` |
| BLoC | `ItemListBloc` (search, category filter, show inactive); `ItemEditorBloc` |
| Pages/widgets | `ItemListPage`, `ItemEditorPage`; `ItemTable`, `ItemForm`, `MappedCuisinesList` (read-only), `UomDropdown` (from `GET /uoms`), `CategoryDropdown` (both required by the API) |
| Shared | `ItemPicker` (supports `cuisineId` filter) is built on `EntitySearchPicker<Item>` and **exposed from `items/domain` via a shared widget that takes a `search` callback** to respect the boundary rule |
| Rules | BR-I1…I4. Delete of a referenced item returns `action:'deactivated'` → show the message (no separate "Mark inactive" call). Default qty is **not** on the item (schema: cuisine mapping) |

## 9. `item_categories` (P0/P2 — exists today)

| | |
|---|---|
| Entities | `ItemCategory {id,name,sortOrder,isActive}` |
| Use cases | `GetItemCategories`, `SaveItemCategory` (create/update) |
| BLoC | `ItemCategoryListBloc` (+ inline dialog form state) |
| Pages/widgets | `ItemCategoryListPage` (uses `MasterPage` + `FormDialog`), `ItemCategoryForm` |
| Rules | BR-I2 (unique name) |

## 10. `meal_times` (P2)

| | |
|---|---|
| Entities | `MealTime {id,cuisineId,cuisineName,mealType,name,start,end,isActive}` — **3 rows per cuisine** (windows are per cuisine) |
| Use cases | `GetMealTimes(cuisineId?)`, `SaveMealTime` (per-row PUT), `ApplyMealTimesToAll(fromCuisineId)` (optional), `GetCurrentMeal(cuisineId)` (shared with counter via `shared/models`) |
| BLoC | `MealTimeSettingsBloc` — state holds the selected cuisine + its 3 rows; validates `start<end` and **same-cuisine** overlap live, conflicting rows flagged; switching cuisine with unsaved edits prompts Save/Discard |
| Pages/widgets | `MealTimeSettingsPage`; `CuisineSelector` (shared picker), `MealTimeRow` (time fields + active toggle) |
| Rules | BR-T1…T5. Defaults: Breakfast 07:00–10:00, Lunch 12:00–15:00, Dinner 19:00–22:00 |

## 11. `daily_menu` (P3) — editor + history

| | |
|---|---|
| Entities | `DayMenu {date, cuisines: [CuisineMenu]}`, `CuisineMenu {cuisineId, name, meals: {MealType → MealMenu}}`, `MealMenu {menuId?, isLocked, lines:[MenuLine{itemId,itemName,unit,quantity}], notes}`, `FillStatus {empty, partial, full}` |
| Use cases | `GetDayMenu(date)`, `SaveDayMenu`, `CopyFromDate`, `CopyMealToCuisines`, `GetMenuHistory` |
| BLoC | **`DailyMenuEditorBloc`** — events `Started(date)`, `DateChanged`, `CuisineSelected`, `MealTabSelected`, `ItemAdded`, `ItemRemoved`, `QtyChanged`, `AddAllMappedPressed`, `CopyFromDateRequested`, `CopyMealToCuisinesRequested`, `ResetPressed`, `SavePressed`; state holds `original` + `draft` DayMenu → `isDirty`, `readOnly` (past date), per-meal lock |
| BLoC | `MenuHistoryBloc` |
| Pages | `DailyMenuEditorPage`, `MenuHistoryPage` (+ read-only variant of editor) |
| Widgets | `MenuDateBar` (prev/next/copy/history), `CuisineSidebar` (✔ / dot status), `MealTabs` (with counts), `MenuItemGrid`, `AddItemRow` (ItemPicker filtered by cuisine), `LockedBanner`, `ReadOnlyBanner`, `CopySummaryDialog` |
| Endpoints | `GET /menus?date=`, `PUT /menus/{date}`, `POST /menus/copy`, `POST /menus/copy-meal`, `GET /menus/history` |
| Rules | BR-D1…D8; unsaved-changes guard; item must be mapped to cuisine |

## 12. `reports` (P4)

Common: `ReportFrame` (filter bar → Generate / Print / Export CSV → grid with totals → drill-down drawer). Each report = own bloc + page + widgets under `presentation/`. All share `ReportFilter {from,to,cuisineId,mealType}`; cancelled excluded server-side.

| Report | Entities | BLoC events | Widgets |
|---|---|---|---|
| **Members register** | `MemberRegisterRow`, totals | `Generated(filter, status, expiringInDays)`, `Exported` | `MembersRegisterTable`, `StatusFilter` |
| **Headcount** | `HeadcountCell {cuisine, meal, count}`, `HeadcountMatrix` | `Generated`, `GroupByDateToggled`, `CellTapped(cuisine, meal, date?)` | `HeadcountMatrix` (meal-tinted heat cells), `TokenListDrawer` → `BillVoucherView` |
| **Item movement** | `ItemMovementRow {item, b, l, d, total}` | `Generated`, `GroupByChanged`, `ItemSelected` | `ItemMovementTable`, `ItemDateBreakdownDrawer` (stacked bar chart — `fl_chart`) |
| **Attendance** | `AttendanceSummaryRow`, `AttendanceDetailGrid` | `Generated`, `ViewChanged(summary/detail)`, `AbsenteesOnlyToggled`, `MemberSelected` | `AttendanceSummaryTable`, `AttendanceCalendarGrid` (B L D markers) |
| **Time-based** | `TimeSlot {from,to,count,pct}`, `HourlyRow` | `Generated`, `IntervalChanged(15/30/60)`, `ViewChanged` | `TimeSlotTable` (peak highlighted), `HourlyHeatGrid`, `MealSummaryCards` |

Export: `GET …/export-csv` bytes → `FileExportService.saveWithDialog('headcount_2026-10-05.csv')` (Windows save dialog via `file_selector`). Pipe-delimited (BR-R3) — client saves bytes untouched.

## 13. `users` (P5)

`User {id, username, displayName, role, isActive}`; `UserListBloc`, `UserEditorBloc` (create, reset password, activate/deactivate); pages `UserListPage`, `UserEditorDialog`. Admin only.

---

## 14. Feature dependency map

```
auth ─┬─ (guards) everything
settings ─ auth (login page button)
counter ──▶ meal_times(domain: current meal), bills(domain: Bill for slip), shared/TokenSlip
bills ────▶ members(domain: MemberPicker via shared), cuisines(domain)
daily_menu ▶ cuisines(domain), items(domain), meal_times(domain)
reports ──▶ bills(domain Bill for drill-down), members/cuisines/items(domain pickers)
```
Cross-feature references are **domain-only** (entities/use cases) or go through `shared/` pickers that take callbacks.
