# Regional Festival Variant System — Design Spec

**Status:** Draft · Phase 3 candidate  
**Scope:** `FestivalRegion` enum, `AppSettings` extension, `FestivalDetector` refactor, `FestivalNames` additions, Settings UI

---

## 1. Why Regions Matter

Most Hindu festival **dates** are universal — the same tithi is calculated from the same astronomical positions everywhere. What differs by region is:

| Kind of difference | Example |
|---|---|
| **Name only** | Chaitra Pratipada → "Chaitra Navratri" (North) vs "Ugadi" (South) vs "Gudi Padwa" (Maharashtra) |
| **Which day is "the main day"** | South India's Deepavali = Naraka Chaturdashi (tithi 29); North India's Diwali = Amavasya (tithi 30) |
| **Festival present vs absent** | Chhath Puja is not observed in South India; Skanda Sashti is Tamil-only |
| **Genuinely different tithi** | Hanuman Jayanti: North = Chaitra Purnima; South (Karnataka/Andhra) = Margashirsha Shukla 10 |
| **Rule variant** | Vat Savitri: North = Jyeshtha Amavasya; Maharashtra = Jyeshtha Purnima |

The architecture must handle all four without special-casing individual festivals in display code.

---

## 2. The `FestivalRegion` Enum

```dart
/// Determines which regional festival set the user follows.
///
/// This is deliberately separate from [AppLanguage] — a Tamil speaker
/// living in Delhi still follows the North Indian panchang.
enum FestivalRegion {
  northIndia,   // Default. UP, Bihar, Delhi, MP, Rajasthan, Punjab, Haryana
  southIndia,   // Karnataka, Andhra Pradesh, Telangana — Ugadi but North-style Diwali
  tamilNadu,    // Tamil Nadu — Deepavali = Naraka Chaturdashi; Skanda Sashti; Karthigai Deepam
  maharashtra,  // Gudi Padwa; Vat Savitri on Jyeshtha Purnima (not Amavasya)
  westBengal,   // Durga Puja emphasis; different Holika Dahan customs
}
```

**Design principles:**

- 5 values covers ~95% of the Indian diaspora. Do not over-enumerate (no separate Kerala until Onam's nakshatra calculation is supported).
- `FestivalRegion` is not a geography lookup. The user picks it manually; the app suggests a default based on `AppLanguage`.
- The canonical English festival key returned by `FestivalDetector` changes per region. `FestivalNames.localize()` then translates that key into the display language.

---

## 3. Changes to `AppSettings`

```dart
class AppSettings {
  final AppLocation? location;
  final AppLanguage language;
  final MonthSystem monthSystem;
  final FestivalRegion festivalRegion;  // ← NEW
  final NotificationSettings notificationSettings;
  final AppTheme theme;

  const AppSettings({
    this.location,
    this.language = AppLanguage.english,
    this.monthSystem = MonthSystem.purnimanta,
    this.festivalRegion = FestivalRegion.northIndia,  // ← default
    this.notificationSettings = const NotificationSettings(),
    this.theme = AppTheme.system,
  });
  ...
}
```

**Suggested default** (set during onboarding or first language change):

```dart
FestivalRegion _defaultRegionForLanguage(AppLanguage lang) => switch (lang) {
  AppLanguage.tamil           => FestivalRegion.tamilNadu,
  AppLanguage.bengali         => FestivalRegion.westBengal,
  AppLanguage.hindiDevanagari ||
  AppLanguage.hindiLatin      ||
  AppLanguage.english         => FestivalRegion.northIndia,
};
```

This is a suggestion only — the user can override. Language and region are always independently configurable.

---

## 4. `FestivalDetector` Refactor

### 4a. Signature change

```dart
static String? detect(DayData day, FestivalRegion region) { ... }
```

Every call site (providers, notification service) passes `region` from `AppSettings.festivalRegion`.

### 4b. `_specialWindowFestival` stays region-agnostic for now

Diwali's sunset-window check on tithi 30 (Amavasya) is correct for all regions except Tamil Nadu where the "main" day is tithi 29. The resolution is **not** to remove the Amavasya check — instead, Tamil Nadu gets a different canonical key for tithi 29 (see §4c) and the Amavasya day returns a lower-priority or suppressed result:

```dart
if (m == LunarMonth.kartika) {
  if (_tithiActiveAt(day, 30, sunset)) {
    // Tamil Nadu celebrates Deepavali on Naraka Chaturdashi (tithi 29, previous day).
    // On the Amavasya day itself, show 'Diwali — Lakshmi Puja' rather than 'Diwali'
    // so it is a subordinate label, not the main Deepavali heading.
    return region == FestivalRegion.tamilNadu
        ? 'Diwali — Lakshmi Puja'
        : 'Diwali';
  }
}
```

### 4c. `_byTithi` becomes region-aware

Below is the **full rewrite** with regional branching annotated:

```dart
static String? _byTithi(LunarMonth m, int t, FestivalRegion region) {
  final isSouth = region == FestivalRegion.southIndia ||
                  region == FestivalRegion.tamilNadu;
  final isChhathRegion = region == FestivalRegion.northIndia ||
                         region == FestivalRegion.westBengal;

  return switch ((m, t)) {

    // ── Chaitra ─────────────────────────────────────────────────────────────
    // Chaitra Pratipada: same tithi, three different names.
    (LunarMonth.chaitra, 1) => switch (region) {
      FestivalRegion.maharashtra => 'Gudi Padwa',
      FestivalRegion.southIndia  => 'Ugadi',
      FestivalRegion.tamilNadu   => 'Ugadi',        // Tamil: Puthandu is solar
      _                          => 'Chaitra Navratri',
    },
    (LunarMonth.chaitra, 8)  => 'Maha Ashtami',
    (LunarMonth.chaitra, 9)  => 'Ram Navami',
    // Hanuman Jayanti: genuinely different tithi by region.
    (LunarMonth.chaitra, 15) when !isSouth => 'Hanuman Jayanti',
    (LunarMonth.chaitra, 15) when isSouth  => 'Chaitra Purnima', // not their Hanuman J.
    (LunarMonth.chaitra, 16) when !isSouth => 'Holi',            // not widely observed south

    // ── Vaishakha ───────────────────────────────────────────────────────────
    (LunarMonth.vaishakha, 3)  => 'Akshaya Tritiya',
    (LunarMonth.vaishakha, 15) => 'Buddha Purnima',

    // ── Jyeshtha ────────────────────────────────────────────────────────────
    (LunarMonth.jyeshtha, 11) => 'Nirjala Ekadashi',
    // Vat Savitri: Amavasya (North/Bengal) vs Purnima (Maharashtra)
    (LunarMonth.jyeshtha, 30) when region != FestivalRegion.maharashtra => 'Vat Savitri',
    (LunarMonth.jyeshtha, 15) when region == FestivalRegion.maharashtra => 'Vat Savitri',

    // ── Ashadha ─────────────────────────────────────────────────────────────
    (LunarMonth.ashadha, 2)  => 'Rath Yatra',
    (LunarMonth.ashadha, 11) => 'Devshayani Ekadashi',
    (LunarMonth.ashadha, 15) => 'Guru Purnima',

    // ── Shravana ────────────────────────────────────────────────────────────
    (LunarMonth.shravana, 5)  => 'Nag Panchami',
    (LunarMonth.shravana, 15) when !isSouth => 'Raksha Bandhan',

    // ── Bhadrapada ──────────────────────────────────────────────────────────
    (LunarMonth.bhadrapada, 23) => 'Krishna Janmashtami',   // see §5 for Rohini variant
    (LunarMonth.bhadrapada, 14) => 'Anant Chaturdashi',
    // Ganesh Chaturthi → _specialWindowFestival (madhyahna rule, region-agnostic)

    // ── Ashwina ─────────────────────────────────────────────────────────────
    (LunarMonth.ashwina, 1) => switch (region) {
      FestivalRegion.westBengal => 'Durga Puja',             // Bengal name for Navratri
      _                         => 'Sharad Navratri',
    },
    (LunarMonth.ashwina, 8) => switch (region) {
      FestivalRegion.westBengal => 'Durga Ashtami',
      _                         => 'Maha Ashtami',
    },
    (LunarMonth.ashwina, 9)  => 'Maha Navami',
    (LunarMonth.ashwina, 10) => 'Vijayadashami',
    (LunarMonth.ashwina, 15) => 'Sharad Purnima',

    // ── Kartika ─────────────────────────────────────────────────────────────
    (LunarMonth.kartika, 28) => 'Dhanteras',
    // Naraka Chaturdashi: North = subordinate pre-Diwali day; Tamil = main Deepavali.
    (LunarMonth.kartika, 29) => region == FestivalRegion.tamilNadu
        ? 'Deepavali'
        : 'Naraka Chaturdashi',
    // Diwali (Amavasya) → _specialWindowFestival handles this;
    // Tamil Nadu gets 'Diwali — Lakshmi Puja' there.
    (LunarMonth.kartika, 1)  => 'Govardhan Puja',
    (LunarMonth.kartika, 2)  => 'Bhai Dooj',

    // Chhath Puja — only North India + West Bengal diaspora.
    (LunarMonth.kartika, 4) when isChhathRegion => 'Chhath — Nahay Khay',
    (LunarMonth.kartika, 5) when isChhathRegion => 'Chhath — Kharna',
    (LunarMonth.kartika, 6) when isChhathRegion => 'Chhath — Sandhya Arghya',
    // Skanda Sashti — Tamil Nadu only (same Kartika Shukla 6 tithi as Sandhya Arghya).
    (LunarMonth.kartika, 6) when region == FestivalRegion.tamilNadu => 'Skanda Sashti',
    (LunarMonth.kartika, 7) when isChhathRegion => 'Chhath — Usha Arghya',

    (LunarMonth.kartika, 11) => 'Devutthana Ekadashi',
    // Kartik Purnima: Tamil Nadu calls it Karthigai Deepam (major lamp festival).
    (LunarMonth.kartika, 15) => region == FestivalRegion.tamilNadu
        ? 'Karthigai Deepam'
        : 'Kartik Purnima',

    // ── Margashirsha ────────────────────────────────────────────────────────
    (LunarMonth.margashirsha, 10) when isSouth => 'Hanuman Jayanti', // South date
    (LunarMonth.margashirsha, 11) => 'Gita Jayanti',

    // ── Magha ───────────────────────────────────────────────────────────────
    (LunarMonth.magha, 5) => 'Vasant Panchami',

    // ── Phalguna ────────────────────────────────────────────────────────────
    // Maha Shivaratri → _specialWindowFestival (sunset rule, region-agnostic)
    (LunarMonth.phalguna, 15) when !isSouth => 'Holika Dahan',
    (LunarMonth.phalguna, 16) when !isSouth => 'Holi',

    _ => null,
  };
}
```

---

## 5. New Canonical Festival Keys

The following keys are added by this feature. Each must be added to `FestivalNames` localization maps:

| Canonical key | Added for |
|---|---|
| `'Ugadi'` | `southIndia`, `tamilNadu` on Chaitra 1 |
| `'Gudi Padwa'` | `maharashtra` on Chaitra 1 |
| `'Chaitra Purnima'` | `southIndia`/`tamilNadu` when Hanuman Jayanti is suppressed |
| `'Durga Puja'` | `westBengal` — Navratri Pratipada |
| `'Durga Ashtami'` | `westBengal` — Ashwina 8 |
| `'Deepavali'` | `tamilNadu` — Naraka Chaturdashi day |
| `'Diwali — Lakshmi Puja'` | `tamilNadu` — Amavasya (subordinate) |
| `'Skanda Sashti'` | `tamilNadu` — Kartika Shukla 6 |
| `'Karthigai Deepam'` | `tamilNadu` — Kartika Purnima |

---

## 6. Future: Janmashtami Rohini Variant (deferred)

The one remaining date difference that needs `DayData` extension is:

- **South India / ISKCON**: Janmashtami is observed when **both** Ashtami (tithi 23) and Rohini nakshatra are active at midnight. If they don't coincide, some follow the Ashtami day, others the Rohini day.

Currently `DayData` doesn't carry nakshatra info (Phase 3 scope for Tamil Panchangam). Once `DayData.nakshatra` is available, add:

```dart
// Bhadrapada Krishna 8 — Rohini variant for South/ISKCON
(LunarMonth.bhadrapada, 23) when isSouth && day.nakshatraAtMidnight != Nakshatra.rohini
    => 'Janmashtami (Ashtami)',    // flag that Rohini is next day
(LunarMonth.bhadrapada, 24) when isSouth && day.nakshatraAtMidnight == Nakshatra.rohini
    => 'Krishna Janmashtami',
```

---

## 7. Settings UI

### New tile in Settings screen

Under the existing **Calendar** section (which has Month System / Language):

```
Festival Calendar
────────────────
◉  North India          UP, Bihar, Rajasthan, Delhi, Punjab
○  South India          Karnataka, Andhra Pradesh, Telangana  
○  Tamil Nadu           Tamil Nadu — Deepavali, Skanda Sashti, Karthigai Deepam
○  Maharashtra          Gudi Padwa, Vat Savitri on Purnima
○  West Bengal          Durga Puja tradition
```

- Radio button list, not a dropdown — there are only 5 choices and the subtitles are explanatory.
- Auto-suggest: when the user changes language, show a banner: **"Based on Tamil language, suggest switching to Tamil Nadu festival calendar? [Yes / Keep North India]"**
- Store in `SharedPreferences` alongside other `AppSettings` fields.

### Settings UX decision: explicit vs inferred

Do not silently infer region from language — a Tamil speaker in Lucknow still follows the North Indian calendar. Always ask or suggest, never assume.

---

## 8. Migration / Backwards Compatibility

- Default is `FestivalRegion.northIndia`. All existing users who upgrade see no change.
- `SettingsRepository.load()` adds `festivalRegion` to the JSON deserialization with `fromJson` fallback to `northIndia`.
- `FestivalDetector.detect()` signature change is breaking — update all 3 call sites: `FestivalsScreen`, `DayViewScreen`, `NotificationService`.

---

## 9. Files Changed

| File | Change |
|---|---|
| `models/app_settings.dart` | Add `FestivalRegion` enum + field |
| `services/festival_detector.dart` | `detect()` + `_byTithi()` take `FestivalRegion` |
| `core/festival_names.dart` | Add 9 new canonical keys to all three language maps |
| `services/settings_repository.dart` | Serialize/deserialize `festivalRegion` |
| `features/settings/settings_screen.dart` | New Festival Calendar tile |
| `features/onboarding/onboarding_screen.dart` | Optional: add region picker step |
| `state/providers.dart` | Pass `region` from settings when calling `detect()` |

---

## 10. Key Conflicts & Resolutions

### Kartika Shukla 6: Chhath Sandhya Arghya vs Skanda Sashti

These two festivals fall on the exact same tithi. The `when` guard on the switch case cleanly separates them by region — no ambiguity at runtime.

### Chaitra Pratipada: Navratri vs Ugadi vs Gudi Padwa

All three are Chaitra 1. The name changes but the **detection logic is identical** — no separate rule needed.

### Diwali "main day" for Tamil Nadu

Tamil Nadu's Deepavali is Naraka Chaturdashi (tithi 29, already computed via sunrise rule). The Amavasya day (tithi 30, sunset rule) becomes a secondary label. This is handled without touching `_specialWindowFestival`'s window logic — only the returned string differs by region.

### Hanuman Jayanti date split

This is the only case where the **tithi** changes (Chaitra 15 vs Margashirsha 10). Handled by two separate match arms guarded by `isSouth`. No special cases in the caller.
