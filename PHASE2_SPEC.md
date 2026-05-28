# Tithika Phase 2 — Spec & Implementation Plan

**Features:** Moon phases · Moonrise & Moonset · Hora · Tamil & Bengali · Push Notifications
**Status:** ✅ All complete
**Last updated:** 2026-05-22

---

## 1. Moon Phases in Month Grid

### 1.1 Overview

The month grid currently shows a 5×5 px paksha dot (gold for Shukla, indigo for Krishna) below each date number. This encodes *which* paksha but not *which phase*. Replacing it with a small `MoonPhaseWidget` gives both — the shape of the terminator communicates the phase, and the existing paksha color on the tithi number below it retains the waxing/waning distinction.

The `MoonPhaseWidget` `CustomPainter` already renders all 30 phases correctly via terminator ellipse math. No new assets, no new dependencies.

### 1.2 UX Spec

**Month grid cell — before:**
```
[ Hindu month label or 4px spacer ]
[ Date number in 20×20 circle     ]
[ 5×5 px paksha dot               ]  ← remove
[ Tithi number (paksha-colored)   ]
[ 4×4 px festival dot if any      ]
```

**Month grid cell — after:**
```
[ Hindu month label or 4px spacer ]
[ Date number in 20×20 circle     ]
[ 14px moon phase icon            ]  ← replace dot
[ Tithi number (paksha-colored)   ]
[ 4×4 px festival dot if any      ]
```

- Icon size: **14 px diameter**
- No glow shadow on grid icons (`glowColor: Colors.transparent`)
- Special cases visible at a glance: Purnima (tithi 15) = full white disc; Amavasya (tithi 30) = near-black disc with faint ring
- `childAspectRatio` unchanged — 14 px icon replaces 5 px dot, net +9 px height is well within the ~75 px cell on a 390 px phone

### 1.3 Files Changed

| File | Change |
|---|---|
| `lib/features/month_view/month_view_screen.dart` | In `_MonthCell.build()`: replace `Container(width:5, height:5, ...)` paksha dot with `MoonPhaseWidget(tithiNumber: data!.tithi.number, glowColor: Colors.transparent, size: 14)` inside `Padding(vertical: 1)`. Keep null guard — cells with no data render a `SizedBox`. |

No other files require changes.

### 1.4 Acceptance Criteria

- [x] Each day cell shows a moon phase icon sized 14 px
- [x] Phase shape is geometrically correct at every tithi (1–30)
- [x] Purnima (15) renders as a full white disc; Amavasya (30) as a near-black disc
- [x] Waxing moons (1–15) lit on the right; waning (16–30) lit on the left
- [x] No glow artifact around icons in the grid
- [x] Festival dot, tithi number, and date number are unaffected
- [x] Month view scrolls and swipes without jank

---

## 2. Moonrise & Moonset

### 2.1 Overview

`swe_rise_trans` — the Swiss Ephemeris function already used for sunrise and sunset — supports the Moon as the target body via `HeavenlyBody.SE_MOON`. Adding moonrise and moonset is a straight extension of the existing pattern across four layers: `EphemerisService` interface, `SwephEphemerisService` implementation, `DayData` model, and `_SunCard` widget.

### 2.2 UX Spec

The existing `_SunCard` is a 2-column horizontal card (sunrise left, sunset right). It expands to a **2×2 grid**:

```
┌──────────────┬──────────────┐
│ ☀ Sunrise    │    Sunset ●  │
│ 6:12 AM      │    7:41 PM   │
├──────────────┼──────────────┤
│ ● Moonrise   │   Moonset ●  │  ← new row
│ 9:44 PM      │   10:58 AM   │
└──────────────┴──────────────┘
```

- Horizontal divider between the two rows; vertical divider between columns (both `TithikaColors.line`)
- Moon icon color: `TithikaColors.moonLight` (`#F7F2DC`) for rise, slightly dimmed for set
- If moonrise or moonset is null (polar edge case): display `—`
- Card internal padding and corner radius unchanged

**Localization:** `AppStrings.moonrise(language)` and `moonset(language)` covering all supported languages.

### 2.3 Files Changed

| File | Change |
|---|---|
| `lib/services/ephemeris_service.dart` | Add `moonrise()` and `moonset()` to abstract class |
| `lib/services/sweph_ephemeris_service.dart` | Implement with `HeavenlyBody.SE_MOON` + `SE_CALC_RISE` / `SE_CALC_SET` |
| `lib/models/day_data.dart` | Add `moonriseUtc`, `moonsetUtc` nullable fields |
| `lib/services/tithi_service.dart` | Compute moonrise/moonset in `calculateForDate()` |
| `lib/core/app_strings.dart` | Add `moonrise(lang)` and `moonset(lang)` |
| `lib/features/day_view/day_view_screen.dart` | Rewrite `_SunCard` to 2×2 grid |

### 2.4 Acceptance Criteria

- [x] `DayData.moonriseUtc` and `moonsetUtc` populated for all normal latitudes
- [x] Times display in user's local timezone
- [x] Null values display `—` without crashing
- [x] `_SunCard` renders as 2×2 grid with correct dividers
- [x] Labels localize correctly in all languages
- [x] `DayData.copyWith()` propagates new fields correctly

---

## 3. Hora (Planetary Hours)

### 3.1 Overview

Hora divides each day into 24 unequal planetary hours: 12 day horas (sunrise to sunset) and 12 night horas (sunset to next sunrise). Each hora is ruled by one of seven classical planets in the fixed sequence Sun → Venus → Mercury → Moon → Saturn → Jupiter → Mars (cycling). The first hora of each day begins at sunrise and is ruled by the planet of the weekday.

**Start planet by weekday:**

| Weekday | Planet | Sequence index |
|---|---|---|
| Sunday | Sun | 0 |
| Monday | Moon | 3 |
| Tuesday | Mars | 6 |
| Wednesday | Mercury | 2 |
| Thursday | Jupiter | 5 |
| Friday | Venus | 1 |
| Saturday | Saturn | 4 |

### 3.2 Data Models

**`lib/models/hora_data.dart`** — `HoraPlanet` enum with extension providing `name(AppLanguage)`, `glyph`, `accentColor`. `HoraSlot` with `planet`, `start`, `end`, `isDay`.

**Planet accent colors:**

| Planet | Glyph | Accent |
|---|---|---|
| Sun | ☉ | `#FFB347` |
| Venus | ♀ | `#E6B85C` |
| Mercury | ☿ | `#7D8DF0` |
| Moon | ☽ | `#F7F2DC` |
| Saturn | ♄ | `#AAB0C5` |
| Jupiter | ♃ | `#E6B85C` |
| Mars | ♂ | `#FF7070` |

### 3.3 Service

**`lib/services/hora_service.dart`** — pure static function `HoraService.calculate({sunriseUtc, sunsetUtc, nextSunriseUtc, weekday})` returning exactly 24 `HoraSlot`s. No I/O. Fully unit-tested in `test/hora_service_test.dart` (11 tests).

### 3.4 UX Spec — Day View Card (`_HoraCard`)

Sits between `_SunCard` and the location row in `_DayContent`. Shows current hora planet, glyph, sublabel ("Hour N · Day/Night"), and end time. Taps to `/hora`.

### 3.5 UX Spec — Hora Screen

**Route:** `/hora`

**Header:**
```
[ 🏠 ]          HORA          [    ]
```
- Left: `IconButton(Icons.home_rounded)` → `context.go('/')`
- Center: "HORA" title
- Right: 48 px spacer (balance)

**Date navigation strip:**
```
[ ‹ ]      WEDNESDAY, MAY 20      [ › ]
```
- Gregorian date only (weekday + month + day)
- Arrows increment/decrement `selectedDateProvider`

**Hora table:** Scrollable `ListView`, DAY header + 12 day rows + NIGHT header + 12 night rows.

Row states:
- **Current hora:** accent-colored border + 8% tint background + "NOW" pill badge
- **Past hora:** opacity 0.38
- **Future hora:** full opacity, no tint

On screen open: `Scrollable.ensureVisible()` via `GlobalKey` scrolls active hora to ~40% from top.

### 3.6 Files Changed

| File | Change | New? |
|---|---|---|
| `lib/models/hora_data.dart` | `HoraPlanet` enum + extension, `HoraSlot` | ✅ New |
| `lib/services/hora_service.dart` | `HoraService.calculate()` | ✅ New |
| `lib/features/hora/hora_screen.dart` | Full screen with date nav + table | ✅ New |
| `test/hora_service_test.dart` | 11 unit tests | ✅ New |
| `lib/state/providers.dart` | Add `horaProvider` | Modify |
| `lib/core/router.dart` | Register `/hora` GoRoute | Modify |
| `lib/features/day_view/day_view_screen.dart` | Add `_HoraCard` | Modify |
| `lib/core/app_strings.dart` | hora labels | Modify |

### 3.7 Acceptance Criteria

- [x] `HoraService.calculate()` returns exactly 24 slots for any valid input
- [x] Day horas span sunrise → sunset; night horas span sunset → next sunrise, no gaps
- [x] First hora planet matches the weekday correctly (all 7 weekdays tested)
- [x] `_HoraCard` shows correct current hora; tapping navigates to `/hora`
- [x] Hora screen header: home icon left (`Icons.home_rounded` → `context.go('/')`), "HORA" centered
- [x] Date nav strip shows Gregorian date; arrows update `selectedDateProvider`
- [x] Current hora highlighted with accent color + NOW badge; scrolled to ~40% on open
- [x] Past horas dimmed (0.38); browsing non-today = no highlighting
- [x] Night hora end time shows "+1" suffix when crossing midnight
- [x] Null sunrise/sunset: `_HoraCard` hidden; `/hora` shows graceful empty state

---

## 4. Tamil & Bengali Language Support

### 4.1 Overview

English, Hindi Latin, and Hindi Devanagari are already supported via `AppStrings` and `devanagariStyle()`. This batch adds Tamil and Bengali end-to-end: new enum values, font helpers, all string tables, all model name arrays (tithi, nakshatra, lunar month, hora planets), festival translations, and UI font wiring.

### 4.2 Architecture — `scriptStyle()` unified helper

**Problem:** Six widget files have `isDeva ? devanagariStyle(…) : base?.copyWith(…)` ternaries. Adding Tamil and Bengali booleans makes this unreadable.

**Solution:** Add `scriptStyle(AppLanguage, TextStyle?, {color, fontSize, fontWeight})` to `lib/core/theme.dart`:

```dart
TextStyle scriptStyle(AppLanguage lang, TextStyle? base,
    {Color? color, double? fontSize, FontWeight? fontWeight}) =>
    switch (lang) {
      AppLanguage.hindiDevanagari => devanagariStyle(base, ...),
      AppLanguage.tamil           => tamilStyle(base, ...),
      AppLanguage.bengali         => bengaliStyle(base, ...),
      _  => (base ?? const TextStyle()).copyWith(...),
    };
```

All `isDeva ? devanagariStyle() : copyWith()` calls across 6 widget files collapse to `scriptStyle(language, base, ...)`.

### 4.3 Fonts

Bundle `NotoSansTamil[wdth,wght].ttf` and `NotoSansBengali[wdth,wght].ttf` in `assets/fonts/`. Declare in `pubspec.yaml`. System fallbacks (`Tamil MN`, `Bangla MN`) ensure rendering even before fonts load.

### 4.4 String Values

**Tamil:**

| Key | Value |
|---|---|
| weekdayFull (Mon→Sun) | திங்கள், செவ்வாய், புதன், வியாழன், வெள்ளி, சனி, ஞாயிறு |
| weekdayShort | திங், செவ், புத, வியா, வெள், சனி, ஞாயி |
| weekdayLetter (Sun→Sat) | ஞா, தி, செ, பு, வி, வெ, ச |
| gregMonth | ஜனவரி, பிப்ரவரி, மார்ச், ஏப்ரல், மே, ஜூன், ஜூலை, ஆகஸ்ட், செப்டம்பர், அக்டோபர், நவம்பர், டிசம்பர் |
| gregMonthShort | ஜன, பிப், மார், ஏப்., மே, ஜூன், ஜூலை, ஆக., செப்., அக்., நவ., டிச. |
| pakshaUpper Shukla/Krishna | வளர்பிறை / தேய்பிறை |
| pakshaWord | பக்ஷம் |
| nakshatra | நட்சத்திரம் |
| sunrise / sunset | சூரிய உதயம் / சூரிய அஸ்தமனம் |
| moonrise / moonset | சந்திர உதயம் / சந்திர அஸ்தமனம் |
| festivals | விழாக்கள் |
| ekadashi / purnima / amavasya | ஏகாதசி / பவுர்ணமி / அமாவாசை |
| hora / horaDay / horaNight | ஹோரா / பகல் / இரவு |
| horaNow | இப்போது |
| horaSubLabel | ஹோரா $n · $period |
| horaUnavailable | ஹோரா கிடைக்கவில்லை. |
| horaSunriseMissing | சூரிய உதயம் தகவல் இல்லை. |
| nakshatraUntil | $time வரை |
| hinduMonthBegins | $monthName $weekday, $month $day-ல் $time முதல் |
| secondaryTithiBegins | · $name $time முதல் |

**Hora planets (Tamil):** சூரியன், சுக்கிரன், புதன், சந்திரன், சனி, குரு, செவ்வாய்

**Lunar months (Tamil, Amanta order):**
வைகாசி, ஆனி, ஆடி, ஆவணி, புரட்டாசி, ஐப்பசி, கார்த்திகை, மார்கழி, தை, மாசி, பங்குனி, சித்திரை

**Tithis (Tamil, 30 values):**
பிரதமை, துவிதியை, திரிதியை, சதுர்த்தி, பஞ்சமி, ஷஷ்டி, சப்தமி, அஷ்டமி, நவமி, தசமி, ஏகாதசி, துவாதசி, திரயோதசி, சதுர்தசி, பவுர்ணமி, பிரதமை, துவிதியை, திரிதியை, சதுர்த்தி, பஞ்சமி, ஷஷ்டி, சப்தமி, அஷ்டமி, நவமி, தசமி, ஏகாதசி, துவாதசி, திரயோதசி, சதுர்தசி, அமாவாசை

**Nakshatras (Tamil, 27 values):**
அஸ்வினி, பரணி, கார்த்திகை, ரோகிணி, மிருகசீரிஷம், திருவாதிரை, புனர்பூசம், பூசம், ஆயில்யம், மகம், பூரம், உத்திரம், அஸ்தம், சித்திரை, சுவாதி, விசாகம், அனுஷம், கேட்டை, மூலம், பூராடம், உத்திராடம், திருவோணம், அவிட்டம், சதயம், பூரட்டாதி, உத்திரட்டாதி, ரேவதி

---

**Bengali:**

| Key | Value |
|---|---|
| weekdayFull (Mon→Sun) | সোমবার, মঙ্গলবার, বুধবার, বৃহস্পতিবার, শুক্রবার, শনিবার, রবিবার |
| weekdayShort | সোম, মঙ্গল, বুধ, বৃহঃ, শুক্র, শনি, রবি |
| weekdayLetter (Sun→Sat) | র, সো, ম, বু, বৃ, শু, শ |
| gregMonth | জানুয়ারি, ফেব্রুয়ারি, মার্চ, এপ্রিল, মে, জুন, জুলাই, আগস্ট, সেপ্টেম্বর, অক্টোবর, নভেম্বর, ডিসেম্বর |
| gregMonthShort | জান, ফেব, মার্চ, এপ্র, মে, জুন, জুলাই, আগ, সেপ, অক্ট, নভ, ডিস |
| pakshaUpper Shukla/Krishna | শুক্ল / কৃষ্ণ |
| pakshaWord | পক্ষ |
| nakshatra | নক্ষত্র |
| sunrise / sunset | সূর্যোদয় / সূর্যাস্ত |
| moonrise / moonset | চন্দ্রোদয় / চন্দ্রাস্ত |
| festivals | উৎসব |
| ekadashi / purnima / amavasya | একাদশী / পূর্ণিমা / অমাবস্যা |
| hora / horaDay / horaNight | হোরা / দিন / রাত |
| horaNow | এখন |
| horaSubLabel | ঘণ্টা $n · $period |
| horaUnavailable | হোরা পাওয়া যাচ্ছে না। |
| horaSunriseMissing | সূর্যোদয়ের তথ্য নেই। |
| nakshatraUntil | $time পর্যন্ত |
| hinduMonthBegins | $monthName শুরু হয় $weekday, $month $day-এ $time থেকে |
| secondaryTithiBegins | · $name $time থেকে |

**Hora planets (Bengali):** সূর্য, শুক্র, বুধ, চন্দ্র, শনি, বৃহস্পতি, মঙ্গল

**Lunar months (Bengali, Amanta order):**
বৈশাখ, জ্যৈষ্ঠ, আষাঢ়, শ্রাবণ, ভাদ্র, আশ্বিন, কার্তিক, অগ্রহায়ণ, পৌষ, মাঘ, ফাল্গুন, চৈত্র

**Tithis (Bengali, 30 values):**
প্রতিপদ, দ্বিতীয়া, তৃতীয়া, চতুর্থী, পঞ্চমী, ষষ্ঠী, সপ্তমী, অষ্টমী, নবমী, দশমী, একাদশী, দ্বাদশী, ত্রয়োদশী, চতুর্দশী, পূর্ণিমা, প্রতিপদ, দ্বিতীয়া, তৃতীয়া, চতুর্থী, পঞ্চমী, ষষ্ঠী, সপ্তমী, অষ্টমী, নবমী, দশমী, একাদশী, দ্বাদশী, ত্রয়োদশী, চতুর্দশী, অমাবস্যা

**Nakshatras (Bengali, 27 values):**
অশ্বিনী, ভরণী, কৃত্তিকা, রোহিণী, মৃগশিরা, আর্দ্রা, পুনর্বসু, পুষ্যা, আশ্লেষা, মঘা, পূর্ব ফাল্গুনী, উত্তর ফাল্গুনী, হস্তা, চিত্রা, স্বাতী, বিশাখা, অনুরাধা, জ্যেষ্ঠা, মূলা, পূর্বাষাঢ়া, উত্তরাষাঢ়া, শ্রবণা, ধনিষ্ঠা, শতভিষা, পূর্বভাদ্রপদা, উত্তরভাদ্রপদা, রেবতী

### 4.5 Files Changed

| File | Change |
|---|---|
| `lib/models/app_settings.dart` | Add `tamil`, `bengali` to `AppLanguage` enum |
| `lib/core/theme.dart` | Add `tamilStyle()`, `bengaliStyle()`, `scriptStyle()` dispatcher |
| `lib/core/app_strings.dart` | Tamil + Bengali cases in all 30 switch methods + 10 new data arrays |
| `lib/models/lunar_month.dart` | Add `nameTamil`, `nameBengali` getters |
| `lib/models/tithi_info.dart` | Add Tamil/Bengali name arrays (30 each) + `fullName` getters |
| `lib/models/nakshatra_info.dart` | Add Tamil/Bengali name arrays (27 each) + getters |
| `lib/models/hora_data.dart` | Add Tamil/Bengali cases to `HoraPlanetExt.name()` |
| `lib/core/festival_names.dart` | Add `_ta` and `_bn` maps (38 keys each) + switch arms |
| `lib/features/settings/settings_screen.dart` | Add `தமிழ்` and `বাংলা` options with correct script fonts |
| `lib/features/day_view/day_view_screen.dart` | Replace `isDeva` ternaries with `scriptStyle()`; switch tithi/nakshatra/month names |
| `lib/features/month_view/month_view_screen.dart` | Replace `isDeva` ternaries with `scriptStyle()` |
| `lib/features/festivals/festivals_screen.dart` | Replace `isDeva` ternaries with `scriptStyle()` |
| `lib/features/hora/hora_screen.dart` | Replace `isDeva` ternaries with `scriptStyle()` |
| `lib/features/onboarding/onboarding_screen.dart` | Replace `isDeva` ternary with `scriptStyle()` |
| `pubspec.yaml` | Declare `NotoSansTamil` and `NotoSansBengali` font families |

> ⚠️ Native speaker review recommended for festival names before release. `?? key` fallback means untranslated keys degrade to English rather than crash.

### 4.6 Acceptance Criteria

- [ ] Settings picker shows `தமிழ்` and `বাংলা` with correct script fonts
- [ ] Day view shows Tamil/Bengali tithi, nakshatra, month name in correct script
- [ ] Hora screen shows Tamil/Bengali planet names + sublabels
- [ ] Month view calendar headers show Tamil/Bengali weekday letters
- [ ] Festivals screen shows Tamil/Bengali festival names
- [ ] Switch back to English — no regressions in any other language

---

## 5. Push Notifications

### 5.1 Overview

All notifications are **locally scheduled** — no server required. The `timezone` package is already in `pubspec.yaml`. Adds `flutter_local_notifications` and a `NotificationService` that pre-schedules alerts using the existing ephemeris engine.

### 5.2 Notification Types

| Type | Content | Default |
|---|---|---|
| Daily panchanga | Title: tithi + nakshatra. Body: sunrise + any festival | ON, 7:00 AM |
| Festival alerts | "Diwali today" on each festival date at 8:00 AM | ON |
| Ekadashi alerts | "Ekadashi today — fast day" at 6:00 AM on Ekadashi dates | ON |

Hora-change notifications intentionally excluded (too frequent).

### 5.3 Architecture

**New package:** `flutter_local_notifications: ^18.0.0`

**Notification IDs:**
- `0` — daily panchanga
- `1–200` — festival notifications (one per festival × year)
- `201–260` — Ekadashi notifications (next 30 occurrences)

### 5.4 `NotificationSettings` model

```dart
// lib/models/notification_settings.dart
class NotificationSettings {
  final bool enabled;               // master toggle (default: false)
  final bool dailyReminderEnabled;  // default: true
  final int  dailyReminderHour;     // 0–23, default: 7
  final int  dailyReminderMinute;   // 0–59, default: 0
  final bool festivalAlertsEnabled; // default: true
  final bool ekadashiAlertsEnabled; // default: true
}
```

SharedPreferences keys (prefix `notif_`): `notif_enabled`, `notif_daily_enabled`, `notif_daily_hour`, `notif_daily_minute`, `notif_festival`, `notif_ekadashi`.

### 5.5 `NotificationService`

```dart
// lib/services/notification_service.dart
class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();  // Android 13+ POST_NOTIFICATIONS
  Future<void> scheduleAll(NotificationSettings settings, AppSettings app);
  Future<void> cancelAll();
}
```

`scheduleAll()` logic:
1. Cancel all existing notifications
2. Return early if `settings.enabled == false`
3. **Daily:** `zonedSchedule` repeating at `(hour, minute)` local time via `DateTimeComponents.time`
4. **Festival:** iterate `FestivalService` dates for current year + next year → one notification at 8:00 AM per date
5. **Ekadashi:** scan next 60 days for `tithi.number == 11` → schedule at 6:00 AM

**Re-schedule triggers:** Call `scheduleAll()` on app startup, location change, and notification settings change.

### 5.6 Settings UI (NOTIFICATIONS section)

Added after MONTH SYSTEM, before CREDITS:

```
NOTIFICATIONS
  Enable notifications        [Switch]
  ─ (visible only when enabled)
  Daily panchanga reminder    [Switch]
    Time  [07:00 AM]          [tap to pick time]
  Festival alerts             [Switch]
  Ekadashi alerts             [Switch]
```

Time picker: `showTimePicker()` Flutter built-in.

### 5.7 Platform Changes

**`android/app/src/main/AndroidManifest.xml`:**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

**iOS:** `flutter_local_notifications` handles `UNUserNotificationCenter` permission at runtime — no `Info.plist` key needed beyond what the package provides.

### 5.8 Files Changed

| File | Change | New? |
|---|---|---|
| `lib/models/notification_settings.dart` | Value class with 6 fields | ✅ New |
| `lib/services/notification_service.dart` | initialize, requestPermission, scheduleAll, cancelAll | ✅ New |
| `lib/models/app_settings.dart` | Add `notificationSettings` field + `copyWith` | |
| `lib/state/app_settings_notifier.dart` | Persist + load new keys; call scheduleAll on settings change | |
| `lib/main.dart` | Initialize NotificationService; call `scheduleAll()` on startup | |
| `lib/features/settings/settings_screen.dart` | NOTIFICATIONS section (master toggle + 4 sub-options) | |
| `android/app/src/main/AndroidManifest.xml` | Add POST_NOTIFICATIONS + SCHEDULE_EXACT_ALARM | |
| `pubspec.yaml` | Add `flutter_local_notifications: ^18.0.0` | |

### 5.9 Acceptance Criteria

- [ ] `flutter pub get` resolves without conflicts
- [ ] iOS: toggle ON → system permission dialog appears
- [ ] Android 13+: POST_NOTIFICATIONS prompt shown on first enable
- [ ] Daily notification fires at configured time with correct tithi + nakshatra content
- [ ] Festival notification fires at 8:00 AM on festival dates
- [ ] Ekadashi notification fires at 6:00 AM on Ekadashi dates
- [ ] Toggle OFF → all notifications cancelled
- [ ] Location change → notifications rescheduled with new sunrise time
- [ ] Changing reminder time → reschedules immediately

---

## 6. Implementation Plan

### Sequence

| Batch | Feature | Estimate | Status |
|---|---|---|---|
| 1A | Moon phases in month grid | ½ day | ✅ Done |
| 1B | Moonrise & Moonset | 1–2 days | ✅ Done |
| 1C | Hora | 3 days | ✅ Done |
| 2.1 | Hora header fix (HOME icon) | 15 min | ✅ Done |
| 2.2 | Tamil & Bengali | 3–4 days | ✅ Done |
| 2.3 | Push Notifications | 2–3 days | ✅ Done |

### Batch 2.2 — Tamil & Bengali

| # | Task | File |
|---|---|---|
| 1 | Download NotoSansTamil.ttf + NotoSansBengali.ttf to `assets/fonts/` | — |
| 2 | `pubspec.yaml` — font declarations | `pubspec.yaml` |
| 3 | Add `tamil`, `bengali` to `AppLanguage` | `app_settings.dart` |
| 4 | Add `tamilStyle`, `bengaliStyle`, `scriptStyle` | `theme.dart` |
| 5 | Add Tamil + Bengali cases to all 30 string methods | `app_strings.dart` |
| 6 | Add `nameTamil`, `nameBengali` getters | `lunar_month.dart`, `tithi_info.dart`, `nakshatra_info.dart` |
| 7 | Add Tamil/Bengali planet names | `hora_data.dart` |
| 8 | Add `_ta`, `_bn` festival maps | `festival_names.dart` |
| 9 | Add language picker options | `settings_screen.dart` |
| 10 | Replace `isDeva` → `scriptStyle()` across 6 widget files | day_view, month_view, festivals, hora, onboarding, settings |

### Batch 2.3 — Push Notifications

| # | Task | File |
|---|---|---|
| 1 | `pubspec.yaml` — add `flutter_local_notifications` | `pubspec.yaml` |
| 2 | `NotificationSettings` model | `notification_settings.dart` |
| 3 | `AppSettings` + notifier — add fields + persist | `app_settings.dart`, `app_settings_notifier.dart` |
| 4 | `NotificationService` — initialize, schedule, cancel | `notification_service.dart` |
| 5 | `main.dart` — init + startup schedule | `main.dart` |
| 6 | Platform permissions | `AndroidManifest.xml` |
| 7 | Settings UI — NOTIFICATIONS section | `settings_screen.dart` |

---

## 7. Open Items

- [x] Moonrise/moonset null on `_HoraCard`: hide entirely if `sunriseUtc` null
- [x] Hora time display: 12h format via `formatLocalTime()`
- [x] Hora midnight crossing: "+1" suffix on night hora 12 end time
- [x] Hora header: `Icons.home_rounded` → `context.go('/')` *(updated from original back-arrow spec)*
- [x] Hora date nav: Gregorian only — no Hindu date
- [ ] Festival translations (Tamil/Bengali): native speaker review before release; `?? key` fallback to English in interim
