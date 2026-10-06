# Theming & Design Tokens

Source: `mock-ui/css/base` (tokens), `mock-ui/css/skins`. Production target: **Flat skin, light + dark** (see [08 Q4](../../docs/08-gap-analysis-roadmap.md)). Clay/Glass are optional and would be additional `ThemeExtension` values, not forks.

## 1. Structure

```
core/theme/
├── app_colors.dart     # raw palette (light + dark)
├── app_spacing.dart    # 4-pt scale, radii, elevations, durations
├── app_typography.dart # TextTheme
├── app_tokens.dart     # ThemeExtension<AppTokens>: semantic + meal colours
└── app_theme.dart      # AppTheme.light / AppTheme.dark → ThemeData (Material 3)
```

- Material 3 (`useMaterial3: true`), `ColorScheme.fromSeed` tuned to the mock's brand colour, then overridden to match tokens.
- Components styled through theme (`FilledButtonTheme`, `InputDecorationTheme`, `DataTableTheme`, `NavigationRailTheme`, `DialogTheme`, `SnackBarTheme`) — widgets use defaults.
- **Never** call `Color(0xFF…)` in feature code. Use `Theme.of(context).colorScheme` or `context.tokens`.

```dart
extension TokensX on BuildContext { AppTokens get tokens => Theme.of(this).extension<AppTokens>()!; }
```

## 2. Semantic tokens (`AppTokens`)

| Token | Use |
|---|---|
| `success / warning / danger / info` (+ `…Container`) | Status chips, banners |
| `surfaceMuted`, `border`, `ink2`, `ink3` | Secondary text/surfaces (mock `ink-2`, cancelled rows) |
| `breakfast`, `lunch`, `dinner` (+ soft tints) | Meal badges, heat cells, timeline, tabs |
| `focusRing` | Visible keyboard focus |
| `watermark` | DUPLICATE slip overlay |

Meal colours: Breakfast = sunrise amber, Lunch = sun (teal/blue), Dinner = indigo — take exact hex values from the mock's CSS variables when implementing (`mock-ui/css/base/*.css`).

## 3. Spacing, shape, motion

- 4-pt scale: `xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32`. Page padding 24, table row height 44 (dense 36), min touch 44.
- Radius: `sm 6 · md 10 · lg 16`. Elevation minimal in Flat.
- Motion: 150–250 ms ease-out; slip slide-out 400 ms. Respect "reduce motion".

## 4. Typography

- Latin: **Inter** (bundled). Arabic: **Noto Naskh Arabic** or **Noto Sans Arabic** (bundled; fallback list `fontFamilyFallback`). Add under `flutter: fonts:` in `pubspec.yaml`; do not rely on system fonts on kiosk PCs.
- Scale: display 28 / title 20 / body 14 / label 12; tabular figures for counts and times (`FontFeature.tabularFigures()`).
- Slip uses a monospace (`Cascadia Mono`/`Consolas` bundled fallback) at 12 px to emulate 32-column thermal print.
- Text direction stays LTR for the UI; Arabic strings inside render RTL automatically via the Unicode bidi algorithm. Test with Arabic item/cuisine names.

## 5. Dark mode

- `ThemeCubit` (`system | light | dark`), persisted in prefs `mess_theme_mode`; `Ctrl+Shift+M` toggles; "restore system" via long-press like the mock.
- Dark palette defined once in `AppColors.dark`; `AppTokens.dark`. Contrast ≥ 4.5:1 for text, 3:1 for UI components; verify banners/chips in both modes.

## 6. Icons

Material Symbols (`Icons.*`). Mock's Lucide names map: `sunrise→wb_twilight`, `sun→light_mode`, `moon-star→nights_stay`, `printer→print`, `eye→visibility`, `ban→block`, `clock→schedule`. Keep a single `AppIcons` class so swaps are one-file.

## 7. Windows specifics

- Density: use `VisualDensity.compact` for tables on desktop; keep touch targets ≥ 44 px on the **counter** page (touch kiosks).
- Scrollbars always visible on desktop (`ScrollbarThemeData(thumbVisibility: true)`).
- Respect system DPI scaling; test at 100 %, 125 %, 150 %.
