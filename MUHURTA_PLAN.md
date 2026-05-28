# Phase 3 — Muhurta & Full Panchanga: Spec

**Status:** UX approved · Ready for implementation  
**Scope:** §3.1 Muhurta & Rahu Kaal + §3.3 Full Panchanga  
**Target:** v1.5.0  
**Wireframe:** `wireframes/wireframes-v4-muhurta.html`

---

## Implementation Phases

Work is split into three independently shippable phases. The VS Code Claude plugin should implement them in order.

| Phase | Scope | Effort | Dependency |
|---|---|---|---|
| **3a** | Rahu Kaal · Yamaganda · Gulika · Abhijit · Brahma Muhurta · Day/Night Choghadiya · MuhurtaScreen · Day View card | ~3 days | None — pure arithmetic on existing sunrise/sunset |
| **3b** | Night Choghadiya expand interaction · extend HoraData with nextSunriseUtc · Choghadiya in summary card | ~2.5 days | Phase 3a |
| **3c** | Yoga · Karana · Vara · Full Panchanga collapsible card on Day View | ~3 days | sunLongitude/moonLongitude plumbing into DayData |

**Recommended task order within Phase 3a:**
1. `MuhurtaData` model + `MuhurtaService` (pure logic, no UI)
2. `muhurtaProvider` — wire into state, reuse HoraData sunrise/sunset
3. `_MuhurtaCard` on Day View
4. `MuhurtaScreen` + `/muhurta` route
5. Localization strings (English + Hindi first)
6. Fix Festivals screen nav consistency
7. Verify output against Drik Panchang (≥3 dates, including a Wednesday)

---

## UX Decisions (approved 2026-05-25)

### Navigation & screen structure

- **Top nav bar is identical on every screen.** The `AppHeader` widget (TITHIKA logo + icon row) does not change between Day View, Month View, Festivals, Hora, Muhurta, or Settings. No screen-specific nav bar.
- **Page titles live in a sub-header below the nav.** Each secondary screen has a `PageTitleBar` widget directly under `AppHeader`:
  ```
  ┌─────────────────────────────────┐  AppHeader (shared)
  │  🏠  TITHIKA   📅 🗓 ☆ ⚙      │
  ├─────────────────────────────────┤  PageTitleBar (per screen)
  │  Muhurta              New York  │
  ├─────────────────────────────────┤  DateNavStrip (where applicable)
  │  ‹  Thursday, 21 May  ›        │
  └─────────────────────────────────┘
  ```
- **Festivals screen** gets the same fix: "Festivals" moves from the nav area into a `PageTitleBar`. Year shown right-aligned. No date strip on Festivals.
- **Hora screen** should be audited for the same pattern if it has a standalone header.

### Muhurta card on Day View (Option C — ambient indicator)

- **Always two rows.** Card height never collapses to one row mid-scroll.
- **Row 1** = current Choghadiya (name, quality sub-label, time remaining).
- **Row 2 logic:**
  - Normal: next upcoming inauspicious period (time shown as clock time, e.g. "1:30 PM").
  - Within 30 min of Rahu/Yamaganda/Gulika: urgency format "in 18 min".
  - When Rahu is **active**: row 1 becomes the Rahu warning (with NOW pill); row 2 flips to **next auspicious Choghadiya** — gives the user an "escape route."
- **Left border colour:** amber (`#C8922A`) when current Choghadiya is auspicious; red (`#B84040`) when inauspicious or Rahu active. Card background tints red (6% opacity) when Rahu active.
- **3 px vertical bar** inside each row encodes auspiciousness at a glance (gold / red / muted).
- Card is fully tappable → navigates to `/muhurta`.

### Muhurta screen

- **Auspicious section:** Brahma Muhurta + Abhijit Muhurta rows. Past rows at 38% opacity.
- **Abhijit on Wednesday:** Row stays in the list but dimmed (45% opacity). Sub-label reads "not observed on Wednesday" (italics). Time cell shows "—". Teaches the rule rather than silently omitting it.
- **Inauspicious section:** Rahu Kaal · Yamaganda · Gulika as a single grouped card. Active row gets red tint + NOW pill. Past rows at 38% opacity.
- **Day Choghadiya:** 8 rows. Active slot: amber highlight (or red if inauspicious type). Past slots: 38% opacity. Screen auto-scrolls to active slot on open (same as Hora screen).
- **Night Choghadiya:** Collapsed by default. Single tappable row showing "▸ expand" + slot count + time range. Expands inline — no new screen or modal. Collapse/expand state is not persisted across sessions.
- **Active slot colour:** amber (`lm-shukla`) for auspicious types (Amrit/Shubh/Labh/Char); red (`mu-warn`) for inauspicious types (Udveg/Kaal/Rog). One consistent active-state pattern, colour-coded by quality.

### Open questions resolved

| Question | Decision |
|---|---|
| Nav icon for Muhurta? | No bottom nav item. Access only via Day View card tap. Nav bar already at capacity. |
| Brahma Muhurta: today vs tomorrow? | Always show tomorrow's value after it passes. User at 8 PM wants tomorrow's window. |
| Vishti/Bhadra alias? | Show "Vishti" in list only. Add "(Bhadra)" as a parenthetical in AppStrings comment. |
| Yoga end time in v1.5? | Name only — no "until HH:MM." Iterative ephemeris query deferred to later phase. |
| Choghadiya auto-scroll? | Yes — auto-scroll to active slot on screen open, matching Hora screen. |

---

## Localization Requirements

All strings must be added to `AppStrings` before Phase 3a ships. English + Hindi Devanagari are blocking; Tamil + Bengali may ship as v1.5.1 patch.

| Key | English | Hindi | Tamil | Bengali |
|---|---|---|---|---|
| `pageTitle.muhurta` | Muhurta | मुहूर्त | முகூர்த்தம் | মুহূর্ত |
| `pageTitle.festivals` | Festivals | त्योहार | விழாக்கள் | উৎসব |
| `section.auspicious` | Auspicious | शुभ | சுபம் | শুভ |
| `section.inauspicious` | Inauspicious | अशुभ | அசுபம் | অশুভ |
| `muhurta.brahma` | Brahma Muhurta | ब्रह्म मुहूर्त | பிரம்ம முகூர்த்தம் | ব্রহ্ম মুহূর্ত |
| `muhurta.brahma.sub` | meditation & prayer | ध्यान और पूजा | தியானம் மற்றும் வழிபாடு | ধ্যান ও পূজা |
| `muhurta.abhijit` | Abhijit Muhurta | अभिजित् मुहूर्त | அபிஜித் முகூர்த்தம் | অভিজিৎ মুহূর্ত |
| `muhurta.abhijit.sub` | most auspicious window | सर्वाधिक शुभ समय | மிகவும் சுபகரமான நேரம் | সবচেয়ে শুভ সময় |
| `muhurta.abhijit.notObserved` | not observed on Wednesday | बुधवार को नहीं होता | புதன்கிழமை கொண்டாடப்படுவதில்லை | বুধবারে পালিত হয় না |
| `muhurta.rahuKaal` | Rahu Kaal | राहु काल | ராகு காலம் | রাহু কাল |
| `muhurta.yamaganda` | Yamaganda | यमगण्ड | யமகண்டம் | যমগণ্ড |
| `muhurta.gulika` | Gulika | गुलिक | குலிகன் | গুলিক |
| `muhurta.avoidNewStarts` | avoid new starts | नए काम न करें | புதிய தொடக்கங்களை தவிர்க்கவும் | নতুন কাজ এড়িয়ে চলুন |
| `choghadiya.day` | Day Choghadiya | दिन का चौघड़िया | பகல் சோகடியா | দিনের চৌঘড়িয়া |
| `choghadiya.night` | Night Choghadiya | रात का चौघड़िया | இரவு சோகடியா | রাতের চৌঘড়িয়া |
| `choghadiya.night.expand` | ▸ expand | ▸ विस्तार करें | ▸ விரிவாக்கு | ▸ বিস্তার করুন |
| `choghadiya.amrit` | Amrit | अमृत | அமிர்தம் | অমৃত |
| `choghadiya.shubh` | Shubh | शुभ | சுபம் | শুভ |
| `choghadiya.labh` | Labh | लाभ | லாபம் | লাভ |
| `choghadiya.char` | Char | चर | சரம் | চর |
| `choghadiya.udveg` | Udveg | उद्वेग | உத்வேகம் | উদ্বেগ |
| `choghadiya.kaal` | Kaal | काल | காலம் | কাল |
| `choghadiya.rog` | Rog | रोग | ரோகம் | রোগ |
| `quality.excellent` | excellent | सर्वश्रेष्ठ | சிறந்தது | চমৎকার |
| `quality.auspicious` | auspicious | शुभ | சுபகரமான | শুভ |
| `quality.profitable` | profitable | लाभदायक | இலாபகரமான | লাভজনক |
| `quality.neutral` | neutral | सामान्य | நடுநிலை | নিরপেক্ষ |
| `quality.inauspicious` | inauspicious | अशुभ | அசுபகரமான | অশুভ |
| `label.now` | NOW | अभी | இப்போது | এখন |

---

## What We're Adding

| Feature | User Value |
|---|---|
| Rahu Kaal | Most-searched feature in this category — "avoid starting anything now" |
| Yamaganda & Gulika | Completes the inauspicious period set |
| Abhijit Muhurta | Best auspicious window of the day |
| Brahma Muhurta | Morning meditation/prayer window |
| Choghadiya | 96-minute planetary windows — travel, business, weddings |
| Yoga | 27th element of panchanga; "the quality of the day" |
| Karana | Half-tithi; appears on every printed panchanga |

All calculations are pure arithmetic on existing sunrise/sunset data.  
**No new ephemeris calls required** except for Yoga (needs sun + moon longitude).

---

## Calculations

### Shared: Day Segment Arithmetic

The day (sunrise → sunset) is divided into 8 equal segments.  
The night (sunset → next sunrise) is also divided into 8 equal segments.

```
daySegment   = (sunset - sunrise) / 8
nightSegment = (nextSunrise - sunset) / 8

startOf(n, sunrise, segDur) = sunrise + (n − 1) × segDur   [n = 1..8]
endOf(n, sunrise, segDur)   = sunrise + n × segDur
```

---

### Rahu Kaal

Inauspicious 1/8 of the day. The slot index by weekday (1-based, where 1 = Sunday):

| Day | Slot |
|---|---|
| Sunday | 8 |
| Monday | 2 |
| Tuesday | 7 |
| Wednesday | 5 |
| Thursday | 6 |
| Friday | 4 |
| Saturday | 3 |

Mnemonic: **"Mother Saw Father Wearing The Turban Suddenly"** → Mon·2, Sat·3, Fri·4, Wed·5, Thu·6, Tue·7, Sun·8

```dart
const _rahuSlot = [8, 2, 7, 5, 6, 4, 3]; // index by (weekday % 7), Sun=0
```

---

### Yamaganda

Inauspicious 1/8 of the day.

| Day | Slot |
|---|---|
| Sunday | 5 |
| Monday | 4 |
| Tuesday | 3 |
| Wednesday | 2 |
| Thursday | 1 |
| Friday | 7 |
| Saturday | 6 |

```dart
const _yamagandaSlot = [5, 4, 3, 2, 1, 7, 6]; // index by (weekday % 7)
```

---

### Gulika (Mandi)

Inauspicious 1/8 of the day.

| Day | Slot |
|---|---|
| Sunday | 7 |
| Monday | 6 |
| Tuesday | 5 |
| Wednesday | 4 |
| Thursday | 3 |
| Friday | 2 |
| Saturday | 1 |

```dart
const _gulikaSlot = [7, 6, 5, 4, 3, 2, 1]; // index by (weekday % 7)
```

---

### Abhijit Muhurta

The most auspicious window of the day, centred on solar noon.

```
solarNoon     = sunrise + (sunset − sunrise) / 2
abhijitStart  = solarNoon − 24 minutes
abhijitEnd    = solarNoon + 24 minutes
```

**Exception:** Wednesday — Abhijit is considered inauspicious and is omitted.

---

### Brahma Muhurta

The pre-dawn auspicious window for meditation and prayer.

```
brahmaStart = sunrise − 96 minutes
brahmaEnd   = sunrise − 48 minutes
```

This is the 14th muhurta of the night (a muhurta = 48 minutes).  
Computed from tomorrow's sunrise on the previous night.

---

### Choghadiya

16 periods per day (8 day + 8 night), each a 1/8 slice of the day or night duration.

**7 types, cycling in order:**

| Type | Quality | Ruling Planet |
|---|---|---|
| Amrit | Excellent | Moon |
| Shubh | Auspicious | Jupiter |
| Labh | Profitable | Mercury |
| Char | Neutral (good for travel) | Venus |
| Udveg | Inauspicious | Sun |
| Kaal | Inauspicious | Saturn |
| Rog | Inauspicious | Mars |

The cycle repeats after 7, so slot 8 = same type as slot 1.

**Day Choghadiya starting type (sunrise → sunset):**

| Day | Start Type |
|---|---|
| Sunday | Udveg |
| Monday | Amrit |
| Tuesday | Rog |
| Wednesday | Labh |
| Thursday | Shubh |
| Friday | Char |
| Saturday | Kaal |

**Night Choghadiya starting type (sunset → next sunrise):**

| Day | Start Type |
|---|---|
| Sunday | Shubh |
| Monday | Char |
| Tuesday | Kaal |
| Wednesday | Udveg |
| Thursday | Amrit |
| Friday | Rog |
| Saturday | Labh |

```dart
const _choghadiyaOrder = [
  ChoghadiyaType.udveg, ChoghadiyaType.char, ChoghadiyaType.labh,
  ChoghadiyaType.amrit, ChoghadiyaType.kaal, ChoghadiyaType.shubh,
  ChoghadiyaType.rog,
]; // 7-element cycle

const _dayStart  = [0, 1, 6, 2, 3, 4, 5]; // Sun=0 → Udveg=0, Mon=1 → Amrit=1, ...
const _nightStart = [3, 4, 5, 0, 1, 6, 2]; // index into _choghadiyaOrder
```

For each slot `i` (0-based), type = `_choghadiyaOrder[(startIndex + i) % 7]`.

---

### Yoga (Full Panchanga §3.3)

27 yogas, cycling through the sum of solar + lunar longitude.

```
yoga = floor((sunLongitude + moonLongitude) / (360/27)) + 1   [1–27]
```

| # | Name | # | Name | # | Name |
|---|---|---|---|---|---|
| 1 | Vishkambha | 10 | Ganda | 19 | Parigha |
| 2 | Priti | 11 | Vriddhi | 20 | Shiva |
| 3 | Ayushman | 12 | Dhruva | 21 | Siddha |
| 4 | Saubhagya | 13 | Vyaghata | 22 | Sadhya |
| 5 | Shobhana | 14 | Harshana | 23 | Shubha |
| 6 | Atiganda | 15 | Vajra | 24 | Shukla |
| 7 | Sukarman | 16 | Siddhi | 25 | Brahma |
| 8 | Dhriti | 17 | Vyatipata | 26 | Indra |
| 9 | Shula | 18 | Variyan | 27 | Vaidhriti |

**Yogas 6 (Atiganda), 9 (Shula), 10 (Ganda), 17 (Vyatipata), 27 (Vaidhriti)** are considered inauspicious.

**Implementation note:** We currently compute `elongation = moonLong − sunLong` for tithi.  
Yoga requires both `sunLong` and `moonLong` individually. We add both to `DayData`; the existing ephemeris call already has them — it is a data plumbing addition only, no new calculations.

---

### Karana (Full Panchanga §3.3)

A karana is half a tithi (6° of elongation).

```
elongation = moonLong − sunLong (mod 360)
karanaIndex = floor(elongation / 6)   [0–59]
```

60 karanas per lunar month. 4 are fixed, 7 are moveable (repeating).

| Karana Index | Name | Type |
|---|---|---|
| 0 | Kimstughna | Fixed |
| 1–56 | Bava → Balava → Kaulava → Taitila → Garaja → Vanija → Vishti (×8) | Moveable |
| 57 | Shakuni | Fixed |
| 58 | Chatushpada | Fixed |
| 59 | Naga | Fixed |

For moveable karanas: `name = _moveableKaranas[(karanaIndex − 1) % 7]`

The 7 moveable karanas:

| Index % 7 | Name | Note |
|---|---|---|
| 0 | Bava | Auspicious |
| 1 | Balava | Auspicious |
| 2 | Kaulava | Auspicious |
| 3 | Taitila | Auspicious |
| 4 | Garaja | Neutral |
| 5 | Vanija | Neutral |
| 6 | Vishti (Bhadra) | Inauspicious — avoided for major events |

---

## Data Models

### New: `MuhurtaData`

```dart
// lib/models/muhurta_data.dart

class MuhurtaData {
  final DateTimeRange rahuKaal;
  final DateTimeRange yamaganda;
  final DateTimeRange gulika;
  final DateTimeRange? abhijit;       // null on Wednesdays
  final DateTimeRange brahma;         // pre-dawn, anchored to next sunrise
  final List<ChoghadiyaSlot> dayChoghadiya;    // 8 slots
  final List<ChoghadiyaSlot> nightChoghadiya;  // 8 slots
}

class ChoghadiyaSlot {
  final ChoghadiyaType type;
  final DateTime start;
  final DateTime end;
}

enum ChoghadiyaType { amrit, shubh, labh, char, udveg, kaal, rog }

extension ChoghadiyaTypeX on ChoghadiyaType {
  bool get isAuspicious =>
      this == ChoghadiyaType.amrit ||
      this == ChoghadiyaType.shubh ||
      this == ChoghadiyaType.labh;
  String get displayName => /* localisable */ ...;
  Color get color => /* amrit/shubh/labh = gold, char = neutral, udveg/kaal/rog = muted-red */ ...;
}
```

### Additions to `DayData`

```dart
// lib/models/day_data.dart — add to existing model
final double? sunLongitude;   // ecliptic longitude in degrees (for Yoga)
final double? moonLongitude;  // ecliptic longitude in degrees (for Yoga + Karana)

// Derived:
int? get yoga    => sunLongitude != null && moonLongitude != null
    ? ((sunLongitude! + moonLongitude!) % 360 ~/ (360 / 27)) + 1
    : null;
int? get karana  => moonLongitude != null && sunLongitude != null
    ? (((moonLongitude! - sunLongitude!) % 360) ~/ 6).toInt()
    : null;
```

---

## New Service

```dart
// lib/services/muhurta_service.dart

class MuhurtaService {
  static MuhurtaData calculate({
    required DateTime sunriseUtc,
    required DateTime sunsetUtc,
    required DateTime nextSunriseUtc,
    required int weekday,   // DateTime.weekday: Mon=1, Sun=7
  });
}
```

Pure arithmetic — no async, no ephemeris. Instantaneous.

---

## UI

### Day View — Muhurta Card

Inserted **below** the Hora card. Two rows:

```
┌─────────────────────────────────────────────┐
│  MUHURTA                                    │
│                                             │
│  ☽  Amrit         Hora 3 · until 9:27 AM   │
│  ⚠  Rahu Kaal     4:30 – 6:00 PM      ›    │
└─────────────────────────────────────────────┘
```

- First row: current Choghadiya type + name + end time
- Second row: Rahu Kaal window (amber ⚠ icon if currently active)
- Whole card tappable → `/muhurta`

---

### Muhurta Screen (`/muhurta`)

Same shell as the Hora screen (shared nav bar + date strip).

```
╔═══════════════════════════════════════════╗
║  🏠  TITHIKA                 📅 🗓 ☆ ⚙  ║
╠═══════════════════════════════════════════╣
║          ‹  Thursday, May 21  ›           ║
╠═══════════════════════════════════════════╣
║                                           ║
║  AUSPICIOUS                               ║
║  ┌───────────────────────────────────┐    ║
║  │  ☀  Brahma Muhurta  4:26 – 5:14 AM│   ║
║  └───────────────────────────────────┘    ║
║  ┌───────────────────────────────────┐    ║
║  │  ✦  Abhijit Muhurta 12:08 – 12:56PM   ║
║  └───────────────────────────────────┘    ║
║                                           ║
║  INAUSPICIOUS                             ║
║  ┌───────────────────────────────────┐    ║
║  │  ⚠  Rahu Kaal     1:30 – 3:00 PM │    ║
║  │  ⚠  Yamaganda    12:00 – 1:30 PM │    ║
║  │  ⚠  Gulika        3:00 – 4:30 PM │    ║
║  └───────────────────────────────────┘    ║
║                                           ║
║  DAY CHOGHADIYA                           ║
║  ┌─────────────────────────────────────┐  ║
║  │ ✦ Amrit  · Day 1   6:02 – 7:54 AM  │  ║  ← gold border (auspicious)
║  │   Kaal   · Day 2   7:54 – 9:46 AM  │  ║  ← muted (past + inauspicious)
║  │ ✦ Shubh  · Day 3   9:46 – 11:38 AM │  ║  ← gold, past, dimmed
║  │ ✦ Labh ┌NOW┐ Day 4 11:38 – 1:30 PM │  ║  ← amber border, active
║  │   Udveg  · Day 5   1:30 – 3:22 PM  │  ║  ← upcoming
║  │ ✦ Amrit  · Day 6   3:22 – 5:14 PM  │  ║
║  │   Rog    · Day 7   5:14 – 7:06 PM  │  ║
║  │   Kaal   · Day 8   7:06 – 7:48 PM  │  ║
║  └─────────────────────────────────────┘  ║
║                                           ║
║  NIGHT CHOGHADIYA                         ║
║  ┌─────────────────────────────────────┐  ║
║  │ ...8 night slots...                 │  ║
║  └─────────────────────────────────────┘  ║
╚═══════════════════════════════════════════╝
```

Visual conventions (consistent with Hora screen):
- **Active slot**: amber border, 8% amber background tint, NOW badge
- **Past slot**: 38% opacity
- **Auspicious** (Amrit/Shubh/Labh): gold ✦ prefix, amber text for name
- **Inauspicious** (Udveg/Kaal/Rog): no prefix, muted text

---

### Day View — Full Panchanga Section (§3.3)

Collapsible card below Muhurta card. Collapsed by default; expands on tap.

```
┌──────────────────────────────────────────────┐
│  FULL PANCHANGA                         ˅    │
├──────────────────────────────────────────────┤  (expanded)
│  Yoga      Siddha            until 2:18 PM   │
│  Karana    Balava            (current half)  │
│  Vara      Thursday · Jupiter               │
└──────────────────────────────────────────────┘
```

- **Yoga**: name + end time (when the sun+moon sum crosses the next 13°20' boundary)
- **Karana**: name of the current half-tithi (changes mid-day)
- **Vara**: day-of-week + its ruling planet (pure lookup, no calculation)

---

## Provider

```dart
// lib/state/providers.dart — add alongside horaProvider

@riverpod
MuhurtaData? muhurta(MuhurtaRef ref) {
  final horaAsync = ref.watch(horaProvider);   // reuse — hora already has sunrise/sunset
  final date = ref.watch(selectedDateProvider);

  return horaAsync.valueOrNull.let((slots) {
    if (slots == null || slots.length < 24) return null;
    final sunriseUtc    = slots[0].start;
    final sunsetUtc     = slots[12].start;
    final nextSunriseUtc = slots[12].end + const Duration(hours: 1);
    // ^ approximate; better: store nextSunrise separately in HoraData
    return MuhurtaService.calculate(
      sunriseUtc:     sunriseUtc,
      sunsetUtc:      sunsetUtc,
      nextSunriseUtc: nextSunriseUtc,
      weekday:        date.weekday,
    );
  });
}
```

**Better:** extend `HoraData` to include `nextSunriseUtc` so the provider has it directly without estimation.

---

## Files to Create / Modify

| File | Change |
|---|---|
| `lib/models/muhurta_data.dart` | **New** — `MuhurtaData`, `ChoghadiyaSlot`, `ChoghadiyaType` |
| `lib/services/muhurta_service.dart` | **New** — pure arithmetic calculator |
| `lib/models/day_data.dart` | Add `sunLongitude`, `moonLongitude` fields |
| `lib/models/hora_data.dart` | Add `nextSunriseUtc` to `HoraData` or `HoraResult` |
| `lib/services/tithi_service.dart` | Pass `sunLongitude` + `moonLongitude` into `DayData` |
| `lib/services/hora_service.dart` | Expose `nextSunriseUtc` in return value |
| `lib/state/providers.dart` | Add `muhurtaProvider` |
| `lib/core/app_strings.dart` | Add strings for yoga names, karana names, choghadiya types, Rahu Kaal etc. (all 5 languages) |
| `lib/core/router.dart` | Add `/muhurta` route |
| `lib/features/muhurta/muhurta_screen.dart` | **New** — full Muhurta screen |
| `lib/features/day_view/day_view_screen.dart` | Add `_MuhurtaCard` + `_FullPanchangaSection` |
| `lib/features/shared/tithika_nav_bar.dart` | Add Muhurta icon to right icon row (or reuse existing) |

---

## Localisation

New strings needed in `AppStrings` (English shown; all 5 languages required):

- 27 Yoga names
- 11 Karana names
- 7 Choghadiya type names + quality labels ("Excellent", "Auspicious", "Profitable", "Neutral", "Inauspicious")
- "Rahu Kaal", "Yamaganda", "Gulika", "Abhijit Muhurta", "Brahma Muhurta"
- "Day Choghadiya", "Night Choghadiya"
- 7 Vara (weekday) ruling planets

This is the most time-consuming part — content work for Tamil and Bengali in particular.

---

## Effort Estimate

| Task | Effort |
|---|---|
| `MuhurtaService` + data models | 1 day |
| Add `sunLongitude`/`moonLongitude` to `DayData` via `TithiService` | ½ day |
| Extend `HoraData` with `nextSunriseUtc` | ½ day |
| `muhurtaProvider` + wire into existing providers | ½ day |
| `_MuhurtaCard` on day view | ½ day |
| Full `MuhurtaScreen` | 1.5 days |
| `_FullPanchangaSection` (Yoga, Karana, Vara) on day view | ½ day |
| Nav icon for Muhurta screen | ½ day |
| Localisation strings (English + Hindi) | 1 day |
| Tamil + Bengali strings | 1 day (content dependency) |
| Testing + verification against Drik Panchang | 1 day |
| **Total** | **~8.5 days** |

---

## Open Questions

All resolved — see UX Decisions section above.

| # | Question | Resolution |
|---|---|---|
| 1 | Nav icon for Muhurta? | No nav icon. Access via Day View card tap only. |
| 2 | Brahma Muhurta: today vs tomorrow? | Show tomorrow's after it passes. |
| 3 | Choghadiya auto-scroll? | Yes — auto-scroll to active slot on open. |
| 4 | "Bhadra" alias for Vishti? | Show "Vishti" only; note alias in AppStrings comment. |
| 5 | Yoga end time in v1.5? | Name only — no "until HH:MM." Deferred. |
| 6 | Localisation phasing? | English + Hindi blocking; Tamil + Bengali as v1.5.1 patch. |
