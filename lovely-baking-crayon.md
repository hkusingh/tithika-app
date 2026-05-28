# Plan: Light Mode Support — Design Mockups

## Screen Designs (Warm Parchment)

### Day View

```
╔══════════════════════════════════════════╗  bg: #F5F0E8
║  🏠   TITHIKA          📅  🗓  ☆  ⚙  ║  nav: #EDE8D8 border
╠══════════════════════════════════════════╣  divider: dark @8%
║                                          ║
║  ◀  Thu, May 21  ·  Vaishakha          ▶ ║  ink: #1A1F3C
║                                          ║
║ ┌──────────────────────────────────────┐ ║
║ │  SHUKLA TRAYODASHI          ◐        │ ║  card bg: #EDE8D8
║ │  ━━━━━━━━━━━━━━━━━━━━━━━              │ ║  gold bar: #C8922A
║ │  Shukla · Vaishakha 13               │ ║  text: #1A1F3C
║ │  until 8:42 PM                       │ ║  muted: #8890A8
║ └──────────────────────────────────────┘ ║
║                                          ║
║ ┌──────────────────────────────────────┐ ║
║ │  Nakshatra: Uttara Phalguni          │ ║  border: dark @8%
║ │  until 6:15 AM                       │ ║
║ └──────────────────────────────────────┘ ║
║                                          ║
║ ┌─────────────┬────────────────────────┐ ║
║ │ ☀ Sunrise   │          Sunset ☀     │ ║
║ │  6:02 AM    │           7:48 PM      │ ║
║ ├─────────────┼────────────────────────┤ ║  2×2 grid
║ │ ☽ Moonrise  │         Moonset ☽     │ ║
║ │ 10:24 PM    │           9:58 AM      │ ║
║ └─────────────┴────────────────────────┘ ║
║                                          ║
║ ┌──────────────────────────────────────┐ ║
║ │  ☉  Sun Hora  · Hour 3 · Day        │ ║  accent: #C8922A
║ │     until 8:44 AM                   │ ║
║ └──────────────────────────────────────┘ ║
╚══════════════════════════════════════════╝
```

---

### Month View

```
╔══════════════════════════════════════════╗  bg: #F5F0E8
║  🏠   TITHIKA          📅  🗓  ☆  ⚙  ║
╠══════════════════════════════════════════╣
║            May 2026                      ║  ink: #1A1F3C
╠════╦════╦════╦════╦════╦════╦════╦════╣
║    ║ Su ║ Mo ║ Tu ║ We ║ Th ║ Fr ║ Sa ║  header: #4A5070
╠════╬════╬════╬════╬════╬════╬════╬════╣  grid: dark @8%
║    ║    ║    ║    ║    ║    ║  1 ║  2 ║
║    ║    ║    ║    ║    ║    ║  🌑 ║  🌒 ║
║    ║    ║    ║    ║    ║    ║ 30 ║  1 ║
╠════╬════╬════╬════╬════╬════╬════╬════╣
║  3 ║  4 ║  5 ║  6 ║  7 ║  8 ║  9 ║ 10 ║
║  🌒 ║ 🌓  ║ 🌔  ║ 🌔  ║ 🌕  ║ 🌖  ║ 🌗  ║  🌕 full = Purnima
║  2 ║  3 ║  4 ║  5 ║  6 ║  7 ║  8 ║  9 ║  gold text: #C8922A
╠════╬════╬════╬════╬════╬╔══╗╬════╬════╣        selected: amber border
║ 19 ║ 20 ║ 21 ║ 22 ║ 23 ║║24║║ 25 ║ 26 ║
║ 🌒  ║ 🌑  ║ 🌑  ║ 🌒  ║ 🌒  ║║🌒  ║║ 🌓  ║  selected cell:
║ 17 ║ 18 ║ 19 ║ 20 ║ 21 ║║22║║ 23 ║ 24 ║  #C8922A border
╠════╬════╬════╬════╬════╬╚══╝╬════╬════╣
║    ║    ║ ●  ║    ║    ║    ║    ║    ║  ● = festival dot #D46A1E
╚════╩════╩════╩════╩════╩════╩════╩════╝
```

---

### Festivals Screen

```
╔══════════════════════════════════════════╗  bg: #F5F0E8
║  🏠   TITHIKA          📅  🗓  ☆  ⚙  ║
╠══════════════════════════════════════════╣
║  Festivals 2026                          ║
╠══════════════════════════════════════════╣
║                                          ║
║  MAY                                     ║  section label: #C8922A bold
║  ┌──────────────────────────────────┐    ║
║  │▌  Akshaya Tritiya               │    ║  card bg: #EDE8D8
║  │   Vaishakha · Shukla 3  Mon May 4│    ║  accent strip: #D46A1E @20%
║  └──────────────────────────────────┘    ║
║  ┌──────────────────────────────────┐    ║
║  │▌  Buddha Purnima                │    ║
║  │   Vaishakha · Shukla 15  Thu May 12│  ║
║  └──────────────────────────────────┘    ║
║                                          ║
║  JUNE                                    ║
║  ┌──────────────────────────────────┐    ║
║  │▌  Nirjala Ekadashi              │    ║
║  │   Jyeshtha · Shukla 11  Wed Jun 3│    ║
║  └──────────────────────────────────┘    ║
╚══════════════════════════════════════════╝
```

---

### Settings — New APPEARANCE Section

```
╔══════════════════════════════════════════╗  bg: #F5F0E8
║  🏠   TITHIKA          📅  🗓  ☆  ⚙  ║
╠══════════════════════════════════════════╣
║  Settings                                ║
╠══════════════════════════════════════════╣
║                                          ║
║  APPEARANCE                              ║  section label: #8890A8
║  ┌──────────────────────────────────┐    ║
║  │  ┌─────────┬────────┬────────┐  │    ║  segmented control
║  │  │  System │ ●Light │  Dark  │  │    ║  selected: amber bg
║  │  └─────────┴────────┴────────┘  │    ║
║  └──────────────────────────────────┘    ║
║                                          ║
║  LANGUAGE                                ║
║  ┌──────────────────────────────────┐    ║
║  │  English                    ✓   │    ║
║  │  Hindi (Latin)                  │    ║
║  │  हिन्दी                           │    ║
║  │  தமிழ்                            │    ║
║  │  বাংলা                            │    ║
║  └──────────────────────────────────┘    ║
╚══════════════════════════════════════════╝
```

---

### Hora Screen

```
╔══════════════════════════════════════════╗  bg: #F5F0E8
║  🏠            HORA                      ║
╠══════════════════════════════════════════╣
║  ‹        Thursday, May 21         ›     ║
╠══════════════════════════════════════════╣
║  DAY                                     ║  section label: #8890A8
║  ┌──────────────────────────────────┐    ║
║  │ ☉  Sun         Hour 1 · Day     │    ║  accent: #FFB347 (unchanged)
║  │                  6:02 – 7:10 AM  │    ║
║  └──────────────────────────────────┘    ║
║  ┌──────────────────────────────────┐    ║
║  │ ♀  Venus        Hour 2 · Day    │    ║
║  │                  7:10 – 8:19 AM  │    ║  past: 38% opacity
║  └──────────────────────────────────┘    ║
║  ┌──────────────────────────────────┐    ║  active: amber border
║  │ ☿  Mercury ┌NOW┐  Hour 3 · Day  │    ║  + 8% amber bg tint
║  │             └───┘ 8:19 – 9:27AM  │    ║
║  └──────────────────────────────────┘    ║
╚══════════════════════════════════════════╝
```

---

### Starfield → Dawn Sky (light mode)

```
Dark mode:                Light mode:
                          
  ·  ·    ·    ·          ░░░░░░░░░░░░░░░░
·    ·  ·    ·   ·        ░░░░░░░░░░░░░░░░  warm amber (#F5E6C8)
  ·    ·   ·   ·          ░░░░░░░░░░░░░░░░  fades to
·  ·    ·    ·  ·         ░░░░░░░░░░░░░░░░  soft cream (#F5F0E8)
                          
Navy/black background     Gradient: sunrise amber top
White star dots           → parchment bottom
                          Tiny dark speckles (3–5% opacity)
                          as subtle texture
```

---



## Context

The app is currently hardcoded dark-only. All 15 color constants live in `TithikaColors` as `static const` fields and are referenced ~178 times across 11 widget files. There is no ThemeMode, no darkTheme, no appearance setting in AppSettings, and no toggle in the settings UI.

Adding light mode requires: a new color palette, a mechanism to switch palettes at runtime, mechanical updates to every color reference, and fixing a handful of hardcoded colors that bypass `TithikaColors`.

---

## Recommended Approach: ThemeExtension + `of(context)` shorthand

Convert `TithikaColors` from static constants into a Flutter `ThemeExtension<TithikaColors>`. Add a `static TithikaColors of(BuildContext context)` helper so call sites change from `TithikaColors.foo` → `TithikaColors.of(context).foo` — a purely mechanical, low-risk find-and-replace across 11 files.

This is the Flutter-idiomatic pattern and keeps all color logic in one place.

---

## Scope & Effort

| Task | Effort |
|---|---|
| Design light color palette | ½ day |
| Convert TithikaColors to ThemeExtension + dark/light instances | ½ day |
| Add AppTheme (light/dark/system) to AppSettings + provider + persist | ½ day |
| Update MaterialApp to use theme/darkTheme/themeMode | 1 hr |
| Mechanical refactor: 178 refs across 11 files (`TithikaColors.x` → `TithikaColors.of(context).x`) | 1 day |
| Fix hardcoded colors (starfield, grid lines, switch colors) | ½ day |
| Settings UI: APPEARANCE section with Light / Dark / System toggle | ½ day |
| Test across all screens in both modes | ½ day |
| **Total** | **~4 days** |

---

## Color Palette

### Dark (current)
| Token | Hex | Role |
|---|---|---|
| background | `#0B0F1E` | Screen background |
| panel | `#11132A` | Cards, sheets |
| card | `#0AFFFFFF` | Subtle card tint |
| ink | `#F3EEDF` | Primary text |
| inkSoft | `#AAB0C5` | Secondary text |
| inkMuted | `#6C7290` | Tertiary text |
| line | `#14FFFFFF` | Borders |
| lineStrong | `#26FFFFFF` | Strong borders |
| shukla | `#E6B85C` | Waxing gold |
| krishna | `#7D8DF0` | Waning indigo |
| festival | `#FF8C42` | Festival saffron |
| moonLight | `#F7F2DC` | Moon lit face |
| moonDark | `#1C2147` | Moon shadow |

### Light (proposed — warm parchment aesthetic)
| Token | Hex | Role |
|---|---|---|
| background | `#F5F0E8` | Warm parchment |
| panel | `#EDE8D8` | Slightly darker cream |
| card | `#0A000000` | Subtle dark tint |
| ink | `#1A1F3C` | Dark navy text |
| inkSoft | `#4A5070` | Medium gray text |
| inkMuted | `#8890A8` | Light gray text |
| line | `#14000000` | Borders (dark @ 8%) |
| lineStrong | `#26000000` | Strong borders (dark @ 15%) |
| shukla | `#C8922A` | Deeper amber (readable on light) |
| krishna | `#5A6BD8` | Deeper indigo |
| festival | `#D46A1E` | Darker saffron |
| moonLight | `#F7F2DC` | Moon lit face (unchanged) |
| moonDark | `#1C2147` | Moon shadow (unchanged) |

---

## Files to Change

### Core infrastructure
| File | Change |
|---|---|
| `lib/core/theme.dart` | Convert TithikaColors to ThemeExtension; add dark/light instances; update buildTithikaTheme(Brightness) |
| `lib/models/app_settings.dart` | Add `AppTheme` enum (system/light/dark); add `theme` field |
| `lib/state/app_settings_notifier.dart` | Persist/load `theme` field via SharedPreferences |
| `lib/main.dart` | Pass `theme:`, `darkTheme:`, `themeMode:` to MaterialApp.router |

### Mechanical color refactor (11 files)
All ~178 usages of `TithikaColors.foo` → `TithikaColors.of(context).foo`.  
Note: any widget currently using `const` constructor will lose `const` if it references a theme color — acceptable trade-off.

- `lib/features/day_view/day_view_screen.dart` (48 refs)
- `lib/features/settings/settings_screen.dart` (33 refs)
- `lib/features/month_view/month_view_screen.dart` (26 refs)
- `lib/features/festivals/festivals_screen.dart` (15 refs)
- `lib/core/theme.dart` (14 refs — internal, already in scope)
- `lib/features/hora/hora_screen.dart` (12 refs)
- `lib/features/shared/city_picker_sheet.dart` (11 refs)
- `lib/features/onboarding/onboarding_screen.dart` (7 refs)
- `lib/features/shared/tithika_nav_bar.dart` (6 refs)
- `lib/features/day_view/location_banner.dart` (4 refs)
- `lib/features/day_view/moon_phase_widget.dart` (2 refs)

### Hardcoded color fixes
| File | Fix |
|---|---|
| `lib/features/shared/starfield_background.dart` | In light mode: replace dark navy gradient with a light dawn/morning sky gradient (warm cream → soft blue); keep stars but render as dark speckles. Pass `Brightness` via constructor or read from Theme. |
| `lib/features/month_view/month_view_screen.dart` | Replace `Color(0x0AFFFFFF)` grid lines with `TithikaColors.of(context).line` |
| `lib/features/day_view/day_view_screen.dart` | Replace `Color(0x07FFFFFF)` strip overlay with `TithikaColors.of(context).card` |
| `lib/features/settings/settings_screen.dart` | Replace `Colors.white`/`Colors.black` Switch thumb/track colors with theme-aware values |
| `lib/features/onboarding/onboarding_screen.dart` | Replace hardcoded glow `Color(0x60E6B85C)` with `TithikaColors.of(context).shuklaGlow` |

### New UI
| File | Change |
|---|---|
| `lib/features/settings/settings_screen.dart` | Add APPEARANCE section above LANGUAGE with a 3-way segmented control: System / Light / Dark |

---

## Key Implementation Detail: ThemeExtension pattern

```dart
// theme.dart
class TithikaColors extends ThemeExtension<TithikaColors> {
  final Color background;
  final Color ink;
  // ... all 15 tokens as final fields

  const TithikaColors._({required this.background, required this.ink, ...});

  // Factory instances
  static const dark  = TithikaColors._(background: Color(0xFF0B0F1E), ...);
  static const light = TithikaColors._(background: Color(0xFFF5F0E8), ...);

  // Context shorthand — replaces TithikaColors.foo at call sites
  static TithikaColors of(BuildContext context) =>
      Theme.of(context).extension<TithikaColors>()!;

  @override
  TithikaColors copyWith({Color? background, ...}) => ...;
  @override
  TithikaColors lerp(TithikaColors other, double t) => ...;
}

ThemeData buildTithikaTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark
      ? TithikaColors.dark
      : TithikaColors.light;
  return ThemeData(
    brightness: brightness,
    extensions: [colors],
    scaffoldBackgroundColor: colors.background,
    // ...
  );
}
```

```dart
// main.dart
MaterialApp.router(
  theme:     buildTithikaTheme(Brightness.light),
  darkTheme: buildTithikaTheme(Brightness.dark),
  themeMode: _appThemeToMaterialThemeMode(settings.theme),
  ...
)
```

---

## Risks & Notes

- **`const` widget loss**: Widgets using `TithikaColors.of(context)` can no longer be `const`. Given the app is heavily stateful (Riverpod), this has negligible performance impact.
- **Starfield**: Requires visual design judgment — a morning-sky gradient for light mode (warm sunrise amber → pale blue) maintains the astronomical character.
- **Hora planet accent colors** in `hora_data.dart` (`Color(0xFFFFB347)` etc.) are independent accent colors, not surface/text colors — they work on both light and dark backgrounds and need no change.
- **`shuklaGlow`/`krishnaGlow`**: Add these as tokens to the ThemeExtension (they are currently only in TithikaColors as static consts).
- **Native speaker review**: Unrelated to light mode — carry-forward open item from Phase 2.

---

## Verification

1. Toggle Light in Settings → all screens render with parchment background, dark navy text, visible borders
2. Toggle Dark → original dark navy aesthetic unchanged
3. Toggle System → follows device dark/light setting
4. Starfield: dark mode = star field; light mode = dawn gradient with subtle speckles
5. Moon phase widget: lit face and shadow face legible on both backgrounds
6. Hora accent colors (planet glyphs) readable on both backgrounds
7. Festival dots and tithi numbers retain correct paksha color on both backgrounds
