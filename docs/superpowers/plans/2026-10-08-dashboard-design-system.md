# eCuisineMess Design System & Dashboard Pilot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the generic blue Material 3 theme with a distinctive, meal-aware design token system covering the whole app, and pilot it end-to-end on the Dashboard page.

**Architecture:** Introduce a small token layer (`lib/core/theme/`) — spacing/radii constants, a typography builder, and a `MealColors` `ThemeExtension` carrying Breakfast/Lunch/Dinner/Danger colors for light and dark — then wire it into the existing `AppTheme.lightTheme`/`darkTheme`. Feature widgets keep reading colors only from `Theme.of(context)` (existing project rule, see `app_theme.dart` doc comment); no raw `Color` literals in feature code. The Dashboard feature (`lib/features/dashboard/`) is rewired first as the pilot; every other screen is listed as a follow-up backlog, not touched in this plan.

**Tech Stack:** Flutter 3 / Material 3 (`useMaterial3: true`), `flutter_bloc`, existing `ThemeExtension` mechanism (no new packages).

**Spec:** No separate spec document exists. This plan's own "Design Tokens" section below is the spec, derived from reviewing `mock-ui/css/base/tokens.css` (the sibling HTML mock's design language: 4px spacing grid, meal-chromatic coding, WCAG AA targets) and the current `ecuisine_mess/lib/core/theme/app_theme.dart`.

## Design Tokens (Spec)

**Spacing** (`lib/core/theme/app_spacing.dart`), mapped 1:1 from `mock-ui/css/base/tokens.css` `--space-*`:
`space1=4, space2=8, space3=12, space4=16, space5=20, space6=24, space8=32, space10=40, space12=48, space16=64` (all `double`).

**Radii** (`lib/core/theme/app_radii.dart`), mapped from `mock-ui` `--radius-*`:
`shell=14.0, panel=12.0, control=8.0, chip=999.0` (pill).

**Meal colors**, adapted from `mock-ui` `--meal-*` tokens, each with a "soft" 12%-alpha container variant for chips/backgrounds:
- Light: breakfast `#C9790A` / soft `#C9790A` @12%, lunch `#16815A` / soft @12%, dinner `#5A3FC0` / soft @12%, danger `#C62840` / soft @12%.
- Dark: breakfast `#F2AE55`, lunch `#45C893`, dinner `#A48BFF`, danger `#FF5A6E` (soft variants @18% alpha, matching `mock-ui`'s dark-mode bump).
- These are darkened slightly from `mock-ui`'s raw light-mode hexes (`#E08A1E`, `#1F9D6B`, `#6A4BD1`, `#D7263D`) to clear 4.5:1 text contrast on white per the Review Focus item below — `mock-ui` only guarantees this via its own surface treatment, not ours.

**Typography:** No new font asset is introduced in this pass (see Review Focus #5 — bundling a licensed display font is a separate, explicit decision). Keep `fontFamily: 'Segoe UI'` for all UI text; add a `tabularNumberStyle` built on the platform `monospace` fallback family for KPI counts, meal-timeline clock labels, and token numbers, so columns of digits align. Hierarchy comes from weight/letter-spacing/size via a `TextTheme` builder, not a second brand font.

**Status colors** (menu readiness: full/partial/empty) stay semantically distinct from meal colors — reuse `ColorScheme.tertiary`/`secondary`/`outline` family, never breakfast/lunch/dinner hues, so "which meal" and "is it ready" never visually collide (Review Focus #4).

## Global Constraints

- `useMaterial3: true` must remain set on both themes.
- No raw `Color(0x...)` literals in `lib/features/**` — all colors come from `Theme.of(context).colorScheme` or `Theme.of(context).extension<MealColors>()`.
- WCAG 2.1 AA: body text ≥ 4.5:1 contrast against its background, non-text UI (icons, borders, chip fills) ≥ 3.0:1.
- 4px spacing grid — any new `EdgeInsets`/`SizedBox` value in touched files must come from `AppSpacing`.
- `darkTheme` must reach the same component-theme coverage as `lightTheme` (button/input/nav/tooltip/snackbar/card) — currently it does not.
- No new third-party font or network-fetched asset in this pass (desktop app, offline-first, matches `mock-ui`'s "zero external CDN calls" principle).

## Review Focus

1. **Dark-mode parity gap** — `AppTheme.darkTheme` currently only sets `colorScheme`, `cardTheme`, and background; it's missing `filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`, `iconButtonTheme`, `inputDecorationTheme`, `navigationRailTheme`, `tooltipTheme`, `snackBarTheme`. A user who switches to dark mode today gets default Material fallbacks mixed with the light theme's bespoke look — jarring. Task 4 must give dark theme the same component set as light.
2. **Static `AppTheme.*` const removal** — `AppTheme.primary`, `.ink`, `.surface`, `.surfaceContainer`, `.border` are read directly by `lib/app.dart` (confirmed via `grep -rl "AppTheme\." lib`, only `app.dart` and `app_theme.dart` itself match). Any rename/removal of these consts while introducing tokens must update `app.dart` too, or keep the consts as thin aliases over the new token files.
3. **Meal-color contrast on white** — raw `mock-ui` hexes (`#E08A1E` saffron, `#1F9D6B` green) are design tokens for a differently-styled surface and are not guaranteed ≥4.5:1 against pure white text backgrounds used by this app's chips. Task 2's unit test must assert contrast ratios, not just copy the hex values.
4. **Meal color vs. readiness-status color collision** — `menu_readiness_grid.dart`'s full/partial/empty indicators must not reuse breakfast/lunch/dinner hues (a green "Lunch" chip next to a green "menu complete" dot reads as one signal). Task 8's test asserts the two palettes are disjoint.
5. **`DashboardHeader` currently keys off free-text `currentMealName`** (`summary.currentWindow?.name`), a display string with no fixed vocabulary. `MealWindow` also carries `mealType` (`'B'|'L'|'D'`, the backend-stable code used by `salesvoucher.meal_type` per the mock's schema). Task 6 must switch `DashboardHeader` to accept the `MealWindow?` and key color off `mealType`, not fuzzy-match `name`, and must handle `mealType` values outside `{B,L,D}` (and null) with the existing neutral "Service closed" style rather than throwing.

---

## File Structure

- Create `lib/core/theme/app_spacing.dart` — spacing constants.
- Create `lib/core/theme/app_radii.dart` — radius constants.
- Create `lib/core/theme/meal_colors.dart` — `MealColors extends ThemeExtension<MealColors>`, light/dark factories, `forMealType(String?)` lookup, `BuildContext` extension getter.
- Create `lib/core/theme/app_typography.dart` — `TextTheme` builder + `tabularNumberStyle`.
- Modify `lib/core/theme/app_theme.dart` — consume the three new files above; fill dark-theme component-theme gap; register `MealColors` extension on both themes; keep existing `AppTheme.primary` etc. consts as aliases so `app.dart` keeps compiling.
- Modify `lib/features/dashboard/presentation/widgets/dashboard_header.dart` — accept `MealWindow? currentWindow` instead of `String? currentMealName`; use `context.mealColors.forMealType(...)`.
- Modify `lib/features/dashboard/presentation/pages/dashboard_page.dart` — update the one call site passing `currentMealName:` to pass `currentWindow:` instead.
- Modify `lib/features/dashboard/presentation/widgets/meal_timeline.dart` — use `MealColors` for the B/L/D bands and current-time marker instead of its current ad hoc colors.
- Modify `lib/features/dashboard/presentation/widgets/served_kpi_row.dart` — apply `AppSpacing`/`tabularNumberStyle`.
- Modify `lib/features/dashboard/presentation/widgets/menu_readiness_grid.dart` — apply `AppSpacing`/`AppRadii`; confirm readiness-status colors are disjoint from `MealColors`.
- Modify `lib/features/dashboard/presentation/widgets/served_by_cuisine_table.dart` — apply `AppSpacing`/`tabularNumberStyle`.
- Create `docs/design-system.md` — human-readable token reference + the follow-up screen backlog (Task 9 writes this; it is documentation, not code).

---

### Task 1: Spacing & Radii Tokens

**Files:**
- Create: `ecuisine_mess/lib/core/theme/app_spacing.dart`
- Create: `ecuisine_mess/lib/core/theme/app_radii.dart`
- Test: `ecuisine_mess/test/core/theme/app_spacing_test.dart`

**Interfaces:**
- Produces: `AppSpacing` with static `const double` fields `space1, space2, space3, space4, space5, space6, space8, space10, space12, space16` (values per Design Tokens section above). `AppRadii` with static `const double shell, panel, control, chip`.

- [ ] **Step 1: Write the failing test** asserting `AppSpacing.space4 == 16.0`, `AppSpacing.space1 == 4.0`, and `AppRadii.panel == 12.0`, `AppRadii.chip == 999.0`.
- [ ] **Step 2: Run test to verify it fails** — `flutter test test/core/theme/app_spacing_test.dart` — Expected: FAIL, `AppSpacing` undefined.
- [ ] **Step 3: Implement `AppSpacing` and `AppRadii`** in their files per the exact values in the Design Tokens section.
- [ ] **Step 4: Run test to verify it passes** — Expected: PASS.
- [ ] **Step 5: Commit** — `git add ecuisine_mess/lib/core/theme/app_spacing.dart ecuisine_mess/lib/core/theme/app_radii.dart ecuisine_mess/test/core/theme/app_spacing_test.dart && git commit -m "feat: add spacing and radii design tokens"`.

---

### Task 2: `MealColors` Theme Extension

**Files:**
- Create: `ecuisine_mess/lib/core/theme/meal_colors.dart`
- Test: `ecuisine_mess/test/core/theme/meal_colors_test.dart`

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: `class MealColors extends ThemeExtension<MealColors>` with fields `breakfast, breakfastSoft, lunch, lunchSoft, dinner, dinnerSoft, danger, dangerSoft` (all `Color`); static `const MealColors.light()` and `const MealColors.dark()` factories with the exact hexes from the Design Tokens section; `Color? forMealType(String? mealType)` returning `breakfast`/`lunch`/`dinner` for `'B'`/`'L'`/`'D'` (case-sensitive, matching the backend code) and `null` for anything else including `null`; `copyWith(...)` and `lerp(ThemeExtension<MealColors>? other, double t)` overrides. Also produces `extension MealColorsContext on BuildContext { MealColors get mealColors => Theme.of(this).extension<MealColors>()!; }` in the same file.

- [ ] **Step 1: Write the failing tests**:
```dart
test('light breakfast meets 4.5:1 contrast against white', () {
  expect(contrastRatio(MealColors.light().breakfast, Colors.white), greaterThanOrEqualTo(4.5));
});
test('forMealType maps B/L/D and falls back to null', () {
  final c = MealColors.light();
  expect(c.forMealType('B'), c.breakfast);
  expect(c.forMealType('L'), c.lunch);
  expect(c.forMealType('D'), c.dinner);
  expect(c.forMealType('X'), isNull);
  expect(c.forMealType(null), isNull);
});
```
  (Write a small local `double contrastRatio(Color a, Color b)` test helper using the standard WCAG relative-luminance formula — this is test-only code, not shipped.)
- [ ] **Step 2: Run test to verify it fails** — `flutter test test/core/theme/meal_colors_test.dart` — Expected: FAIL, `MealColors` undefined.
- [ ] **Step 3: Implement `MealColors`** per the Interfaces block. If the Design Tokens hexes fail the contrast test, darken them further (keep hue, reduce lightness) until they pass — document the final hexes back into this plan's Design Tokens section via a follow-up note, do not silently diverge.
- [ ] **Step 4: Run test to verify it passes** — Expected: PASS.
- [ ] **Step 5: Commit** — `git add ecuisine_mess/lib/core/theme/meal_colors.dart ecuisine_mess/test/core/theme/meal_colors_test.dart && git commit -m "feat: add MealColors theme extension"`.

---

### Task 3: Typography Scale

**Files:**
- Create: `ecuisine_mess/lib/core/theme/app_typography.dart`
- Test: `ecuisine_mess/test/core/theme/app_typography_test.dart`

**Interfaces:**
- Produces: `TextTheme buildTextTheme({required Color ink, required Color inkMuted})` returning a full `TextTheme` (display/headline/title/body/label, each weight-differentiated, `fontFamily: 'Segoe UI'`) and `TextStyle tabularNumberStyle({required Color color, double fontSize = 14, FontWeight weight = FontWeight.w600})` returning a style with `fontFamilyFallback: ['monospace']` and `fontFeatures: [FontFeature.tabularFigures()]`.

- [ ] **Step 1: Write the failing test** asserting `buildTextTheme(...).headlineSmall!.fontWeight == FontWeight.w700` (or the chosen weight) and `tabularNumberStyle(color: Colors.black).fontFeatures!.contains(const FontFeature.tabularFigures())`.
- [ ] **Step 2: Run test to verify it fails** — Expected: FAIL, functions undefined.
- [ ] **Step 3: Implement both functions** per the Interfaces block; pick concrete sizes/weights for each `TextTheme` slot (implementer's choice, no spec value pins these beyond "weight-differentiated").
- [ ] **Step 4: Run test to verify it passes** — Expected: PASS.
- [ ] **Step 5: Commit** — `git add ecuisine_mess/lib/core/theme/app_typography.dart ecuisine_mess/test/core/theme/app_typography_test.dart && git commit -m "feat: add app typography scale"`.

---

### Task 4: Wire Tokens into `AppTheme`, Close Dark-Mode Gap

**Files:**
- Modify: `ecuisine_mess/lib/core/theme/app_theme.dart`
- Modify: `ecuisine_mess/lib/app.dart` (only if a static const this task removes is referenced — check with `grep -n "AppTheme\." ecuisine_mess/lib/app.dart` first; if it only reads `AppTheme.lightTheme`/`darkTheme`, no change needed there)
- Test: `ecuisine_mess/test/core/theme/app_theme_test.dart`

**Interfaces:**
- Consumes: `AppSpacing`, `AppRadii` (Task 1), `MealColors.light()`/`.dark()` (Task 2), `buildTextTheme`/`tabularNumberStyle` (Task 3).
- Produces: `AppTheme.lightTheme` and `AppTheme.darkTheme` each with `.extensions` containing a `MealColors` instance, `textTheme` set from `buildTextTheme`, and matching component-theme coverage (`filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`, `iconButtonTheme`, `inputDecorationTheme`, `navigationRailTheme`, `tooltipTheme`, `snackBarTheme`, `cardTheme`, `dividerTheme`) on **both** themes. Existing `AppTheme.primary/primaryDark/ink/surface/surfaceContainer/border` static consts are kept (as the light-mode source values) so `app.dart` keeps compiling unchanged.

- [ ] **Step 1: Write the failing test**:
```dart
test('both themes expose MealColors and matching component theme coverage', () {
  for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    expect(theme.extension<MealColors>(), isNotNull);
    expect(theme.filledButtonTheme.style, isNotNull);
    expect(theme.navigationRailTheme.indicatorColor, isNotNull);
    expect(theme.inputDecorationTheme.filled, isTrue);
  }
});
```
- [ ] **Step 2: Run test to verify it fails** — Expected: FAIL (dark theme missing these).
- [ ] **Step 3: Implement** — add `extensions: [MealColors.light()]` / `[MealColors.dark()]`, set `textTheme: buildTextTheme(...)`, and port the light theme's button/input/nav/tooltip/snackbar theming to dark theme using dark-appropriate colors from `scheme`/`surface`.
- [ ] **Step 4: Run test to verify it passes** — Expected: PASS. Also run `flutter analyze` — Expected: no new warnings.
- [ ] **Step 5: Commit** — `git add ecuisine_mess/lib/core/theme/app_theme.dart ecuisine_mess/test/core/theme/app_theme_test.dart && git commit -m "feat: register MealColors and typography, close dark theme gap"`.

---

### Task 5: Dashboard Pilot — Meal-Aware Header

**Files:**
- Modify: `ecuisine_mess/lib/features/dashboard/presentation/widgets/dashboard_header.dart`
- Modify: `ecuisine_mess/lib/features/dashboard/presentation/pages/dashboard_page.dart:73` (change `DashboardHeader(currentMealName: summary.currentWindow?.name)` to `DashboardHeader(currentWindow: summary.currentWindow)`)
- Test: `ecuisine_mess/test/features/dashboard/dashboard_header_test.dart` (new)

**Interfaces:**
- Consumes: `MealColors.forMealType` and `context.mealColors` (Task 2), `MealWindow` (existing, `lib/features/counter/domain/entities/meal_window.dart`).
- Produces: `DashboardHeader({super.key, this.currentWindow})` where `currentWindow` is `MealWindow?`, replacing the old `currentMealName` parameter.

- [ ] **Step 1: Write the failing tests** — pump `DashboardHeader` inside a themed `MaterialApp` for each of: `currentWindow: MealWindow(name: 'Lunch', mealType: 'L', ...)` → chip background equals `context.mealColors.lunchSoft` and text equals the active style; `currentWindow: null` → chip shows "Service closed" in the existing neutral style; `currentWindow` with `mealType: 'X'` (unexpected code) → also falls back to "Service closed" neutral style rather than throwing.
- [ ] **Step 2: Run test to verify it fails** — Expected: FAIL, old API / missing color mapping.
- [ ] **Step 3: Implement** — change the constructor parameter, compute `final mealColor = context.mealColors.forMealType(currentWindow?.mealType);`, use `mealColor` (and its `*Soft` pair) when non-null, otherwise keep today's `scheme.surfaceContainerHighest`/"Service closed" path. Display text still reads `currentWindow!.name` when active.
- [ ] **Step 4: Run test to verify it passes** — Expected: PASS. Also run `flutter test test/features/dashboard/dashboard_page_test.dart` — Expected: still PASS (confirms the page-level call-site update didn't break the existing test).
- [ ] **Step 5: Commit** — `git add ecuisine_mess/lib/features/dashboard/presentation/widgets/dashboard_header.dart ecuisine_mess/lib/features/dashboard/presentation/pages/dashboard_page.dart ecuisine_mess/test/features/dashboard/dashboard_header_test.dart && git commit -m "feat: key dashboard header color off meal type, not free text"`.

---

### Task 6: Dashboard Pilot — Meal Timeline Colors

**Files:**
- Modify: `ecuisine_mess/lib/features/dashboard/presentation/widgets/meal_timeline.dart`
- Test: `ecuisine_mess/test/features/dashboard/meal_timeline_test.dart` (new, or extend if one exists — check `test/features/dashboard/` first)

**Interfaces:**
- Consumes: `context.mealColors`, `MealColors.forMealType` (Task 2). `meal_timeline.dart` already receives `List<MealWindow> windows` (each with `mealType`) per `dashboard_page.dart:100` — read the existing widget to confirm the current per-window color source before replacing it.

- [ ] **Step 1: Write the failing test** — pump `MealTimeline` with windows of `mealType` `'B'`, `'L'`, `'D'` and assert each band's `Container`/`CustomPaint` color (whichever the current implementation uses — inspect the file first) equals `context.mealColors.forMealType('B'/'L'/'D')`.
- [ ] **Step 2: Run test to verify it fails** — Expected: FAIL (current ad hoc colors don't match).
- [ ] **Step 3: Implement** — replace the widget's current per-meal color source with `context.mealColors.forMealType(window.mealType)`, falling back to `scheme.outlineVariant` for an unrecognized `mealType`.
- [ ] **Step 4: Run test to verify it passes** — Expected: PASS.
- [ ] **Step 5: Commit** — `git add ecuisine_mess/lib/features/dashboard/presentation/widgets/meal_timeline.dart ecuisine_mess/test/features/dashboard/meal_timeline_test.dart && git commit -m "feat: drive meal timeline bands from MealColors"`.

---

### Task 7: Dashboard Pilot — Spacing/Typography Pass on KPI Row, Readiness Grid, Served Table

**Files:**
- Modify: `ecuisine_mess/lib/features/dashboard/presentation/widgets/served_kpi_row.dart`
- Modify: `ecuisine_mess/lib/features/dashboard/presentation/widgets/menu_readiness_grid.dart`
- Modify: `ecuisine_mess/lib/features/dashboard/presentation/widgets/served_by_cuisine_table.dart`
- Test: `ecuisine_mess/test/features/dashboard/menu_readiness_grid_test.dart` (new — the one test in this task that pins a Review Focus item; the other two files get a manual spacing/token pass without a new pinning test since no spec value beyond "use the tokens" governs them)

**Interfaces:**
- Consumes: `AppSpacing`, `AppRadii` (Task 1), `context.mealColors` (Task 2), `tabularNumberStyle` (Task 3).

- [ ] **Step 1: Write the failing test** for `menu_readiness_grid.dart` asserting its full/partial/empty status colors are none of `{context.mealColors.breakfast, .lunch, .dinner}` (Review Focus #4) — pump the widget with one row of each status and inspect the rendered indicator colors.
- [ ] **Step 2: Run test to verify it fails or passes** — if the current status colors already happen to avoid meal hues, this step may already PASS; either way confirm by running `flutter test test/features/dashboard/menu_readiness_grid_test.dart` before touching the file.
- [ ] **Step 3: Implement** — in all three files, replace literal `EdgeInsets`/`SizedBox`/radius values with `AppSpacing`/`AppRadii` constants, and route KPI counts / table numeric cells through `tabularNumberStyle`. In `menu_readiness_grid.dart`, if Step 2 failed, move the status colors onto `scheme.tertiary`/`scheme.secondary`/`scheme.outline` so they stay disjoint from `MealColors`.
- [ ] **Step 4: Run test to verify it passes** — Expected: PASS. Also run `flutter test test/features/dashboard/` (whole directory) — Expected: all PASS.
- [ ] **Step 5: Commit** — `git add ecuisine_mess/lib/features/dashboard/presentation/widgets/served_kpi_row.dart ecuisine_mess/lib/features/dashboard/presentation/widgets/menu_readiness_grid.dart ecuisine_mess/lib/features/dashboard/presentation/widgets/served_by_cuisine_table.dart ecuisine_mess/test/features/dashboard/menu_readiness_grid_test.dart && git commit -m "feat: apply design tokens to dashboard KPI, readiness, and served widgets"`.

---

### Task 8: Full-Suite Verification

**Files:** none created/modified.

- [ ] **Step 1: Run `flutter analyze`** from `ecuisine_mess/` — Expected: no new issues versus the pre-plan baseline.
- [ ] **Step 2: Run `flutter test`** from `ecuisine_mess/` — Expected: all tests PASS, including the untouched `dashboard_bloc_test.dart` and `dashboard_summary_model_test.dart`.
- [ ] **Step 3: Commit** only if either command required a fix: `git add -A && git commit -m "fix: resolve analyzer/test issues from design system pilot"`. If nothing needed fixing, skip this step — there is nothing to commit.

---

### Task 9: Design System Doc & Follow-Up Backlog

**Files:**
- Create: `docs/design-system.md`

**Interfaces:** none (documentation only).

- [ ] **Step 1: Write `docs/design-system.md`** summarizing the Design Tokens section of this plan (spacing/radii/meal-colors/typography, with the final contrast-corrected hexes from Task 2 if they changed) as the canonical reference, and listing the **not-yet-touched** screens as a backlog, one line each with its current file path, e.g.: Items list/editor (`lib/features/items/`), Cuisines list/editor (`lib/features/cuisines/`), Members list/editor (`lib/features/customers/`), Meal Time Settings, Daily Menu Editor, Counter Kiosk (`meal_banner.dart` already partly redesigned per git history — note it should be re-checked against `MealColors` once this plan lands), Bill Register, and the five analytical report screens.
- [ ] **Step 2: Commit** — `git add docs/design-system.md && git commit -m "docs: record design system tokens and redesign backlog"`.

---

## Self-Review

**Spec coverage:** Spacing/Radii → Task 1. Meal colors (+ contrast) → Task 2. Typography → Task 3. Theme wiring + dark-mode parity → Task 4. Dashboard header/timeline/KPI/readiness/table → Tasks 5–7. Verification → Task 8. Backlog documentation → Task 9. No Design Tokens item is unassigned.

**Review Focus coverage:** #1 (dark parity) → Task 4 Step 1 test. #2 (static const removal) → Task 4's Interfaces note + File Structure note to keep aliases. #3 (meal-color contrast) → Task 2 Step 1 test. #4 (status/meal color collision) → Task 7 Step 1 test. #5 (`mealType` vs free-text `name`) → Task 5's Interfaces and Step 3.

**Proportion check:** nine tasks for a token layer plus one pilot feature is proportionate to the scope (nine files created/modified, no large generated-code tasks); code blocks above are limited to test bodies and signatures, no step transcribes a full widget implementation.

---

Plan complete and saved to `docs/superpowers/plans/2026-10-08-dashboard-design-system.md`. Please review the plan. Which execution approach would you prefer?

- **Subagent-driven** — a fresh subagent implements each task and a fresh reviewer checks it before the next starts, then a whole-branch review at the end. Most thorough; costs a fresh context per task and per review.
- **Native** — I implement every task myself in this session, then one fresh reviewer checks the whole branch at the end. Cheapest and fastest; no independent review until the end.

For this plan I recommend **Native**, because the nine tasks are mostly linear (tokens → theme wiring → pilot widgets) with narrow, well-typed interfaces between them, there's no fan-out of independent subsystems, and a shipped mistake here is a visual regression on one page, not a cross-cutting break — cheap to catch with one end-of-branch review rather than nine isolated ones.

Does the plan capture what you want, and which approach should we use?
