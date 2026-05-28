# Tithika — Product Roadmap

**Last updated:** 2026-05-22
**Status:** v0.2 shipped · Phase 3 next

---

## Shipped — v0.1

Core tithi calendar, fully offline.

| Feature | Notes |
|---|---|
| Tithi calculation (Drik) | Swiss Ephemeris, < 1 min accuracy |
| Nakshatra with end time | Sidereal (Lahiri ayanamsa) |
| Sunrise & sunset | `swe_rise_trans`, location-aware |
| Adhika Maas detection | Implicit orbital mechanics, no blocklist needed |
| Purnimanta / Amanta toggle | User-configurable in Settings |
| 36 tithi-based festivals | Full year coverage |
| Solar festivals | Makar Sankranti, Baisakhi via sun sign entry |
| Special tithi indicators | Ekadashi, Purnima, Amavasya, Chaturthi, Pradosh |
| Kshaya tithi detection | Secondary tithi shown on day view |
| Month grid view | Moon-phase icon, paksha color, festival dots |
| 4-day strip navigation | PageView epoch arithmetic, DST-safe |
| Three-language support | English, Hindi (Latin), Hindi (Devanagari) |
| First-launch onboarding | GPS or manual city picker; Ujjain fallback |
| Fully offline | Ephemeris bundled as Flutter assets (~10 MB) |

---

## Shipped — v0.2 (Phase 2)

| Feature | Notes |
|---|---|
| Moon phases in month grid | `MoonPhaseWidget` replaces paksha dot — all 30 phases, no assets |
| Moonrise & Moonset | `swe_rise_trans` on `SE_MOON`; 2×2 grid in `_SunCard` |
| Hora (planetary hours) | `HoraService`, `/hora` screen, `_HoraCard` on day view |
| Tamil & Bengali | Fonts, all string tables, `scriptStyle()` dispatcher, festival translations |
| Push Notifications | `flutter_local_notifications`; daily panchanga + festival + Ekadashi alerts |
| Tithi window rules | Diwali, Chhath Kharna, Sandhya Arghya, Ganesh Chaturthi, Maha Shivaratri use correct sunset/Madhyahna windows |

---

## Phase 2 — Quick Wins ~~(Q3 2026, ~3 months)~~ ✅ Shipped

**Theme:** Deepen daily engagement and widen the addressable user base.
No new architectural dependencies — all features build directly on the existing service layer.

### 2.1 Moonrise & Moonset

**Effort:** Low (1–2 days) · **Impact:** Medium

`swe_rise_trans` with `CALC_RISE` / `CALC_SET` on `HeavenlyBody.SE_MOON` is already available via the `sweph` package. This is a data model + display addition only.

Changes:
- Add `moonriseUtc` and `moonsetUtc` to `DayData`
- Compute alongside sunrise/sunset in `TithiService.calculateForDate()`
- Add a moon-rise/set row to `_SunCard` on the day view (right half panel)

### 2.2 Additional Languages — Tamil & Bengali

**Effort:** Low (content work per language) · **Impact:** High

The `AppStrings` switch pattern and `FestivalNames` map are designed for extension — no architectural changes needed. Each new language is a new `AppLanguage` enum value + switch arm.

Phase 2 scope: Tamil and Bengali only. Marathi and Gujarati deferred to Phase 3.

Changes:
- Add `tamil` and `bengali` values to `AppLanguage` enum
- Extend every `switch (lang)` arm in `AppStrings` with Tamil and Bengali translations
- Add `_ta` and `_bn` maps to `FestivalNames` (38 festival keys each)
- Add `NotoSansTamil.ttf` and `NotoSansBengali.ttf` to `assets/fonts/`
- Extend language picker in Settings screen
- **Content dependency:** tithi/nakshatra/month names require native-speaker review

### 2.3 Push Notifications

**Effort:** Medium (~2 weeks) · **Impact:** Very High (retention driver)

No competitor executes this well. A notification the evening before Ekadashi converts an occasional user into a weekly one.

Trigger events (user-configurable):
- Ekadashi eve & morning
- Purnima eve
- Amavasya eve
- Upcoming festival (D-1 morning)
- Pradosh eve

Architecture:
- `flutter_local_notifications` for scheduling
- `MuhurtaScheduler` service: at app open, compute next 30 days of events via `TithiService`, schedule local notifications (no network needed — fully offline)
- Notification Settings screen section: master toggle + per-event toggles
- Re-schedule on location change or timezone change

### 2.4 Moon Phases in Month Grid

**Effort:** Trivial (< 1 hour) · **Impact:** Medium (visual completeness)

The existing `MoonPhaseWidget` `CustomPainter` already draws all 30 phases correctly via terminator ellipse math. No new assets needed — the painter scales to any size.

Change: replace the 5×5 paksha dot in `_MonthCell` with `MoonPhaseWidget(tithiNumber: data.tithi.number, glowColor: Colors.transparent, size: 14)`. The tithi number label below it retains the paksha colour. One line change in `month_view_screen.dart`.

### 2.5 Hora (Planetary Hours)

**Effort:** Low (~3 days) · **Impact:** Medium-High (daily active use)

24 planetary hours per day: 12 day horas (sunrise → sunset ÷ 12) + 12 night horas (sunset → next sunrise ÷ 12). Ruled by planets in the fixed sequence Sun → Venus → Mercury → Moon → Saturn → Jupiter → Mars, starting from the day's ruling planet at sunrise. Pure arithmetic — no ephemeris calls beyond existing sunrise/sunset.

UX:
- **Day view:** `_HoraCard` row showing current hora planet + glyph + "until HH:MM". Tappable.
- **Hora screen:** Full `/hora` route with date navigation (arrow strip), 12-row day tabla + 12-row night tabla, current hora highlighted. User can browse any date's horas.

New files:
- `lib/services/hora_service.dart` — `HoraService.calculate(sunriseUtc, sunsetUtc, nextSunriseUtc, weekday)` → `List<HoraSlot>`
- `lib/models/hora_data.dart` — `HoraSlot { planet, start, end, isDay }`
- `lib/features/hora/hora_screen.dart` — full hora table screen
- Register `/hora` route in `router.dart`
- Add `_HoraCard` widget in `day_view_screen.dart`

---

## Phase 3 — Growth (Q4 2026–Q1 2027, ~6 months)

**Theme:** Power-user features that drive word-of-mouth and differentiate from ad-laden competitors.

### 3.1 Muhurta & Rahu Kaal

Rahu Kaal, Yamaganda, Gulika, Abhijit Muhurta, Brahma Muhurta, Choghadiya.
Pure arithmetic on existing sunrise/sunset — no new ephemeris calls.

See `MUHURTA_PLAN.md` for full implementation spec (data models, segment tables, UI design).

### 3.2 Home-Screen Widgets

iOS (WidgetKit) and Android (Glance) lock/home screen widgets showing today's tithi, paksha, and next inauspicious period. Highest visible differentiator in app store screenshots.

Requires native Swift/Kotlin extension alongside Flutter (`home_widget` package bridges data). Most engineering-intensive item in Phase 3.

Widget sizes:
- Small (2×2): tithi name + moon phase icon
- Medium (4×2): tithi, nakshatra, sunrise, Rahu Kaal bar

### 3.3 Full Panchanga

Add the remaining Panchanga elements beyond tithi and nakshatra:

| Element | Calculation |
|---|---|
| Yoga | `(sunLong + moonLong) / (360/27)` → 1–27 |
| Karana | Half-tithi; `ceil((elongation / 6))` → 1–60, maps to 11 types |
| Rahu Kaal | See §3.1 |
| Yamaganda | See §3.1 |
| Gulika | See §3.1 |

Display: collapsible "Full Panchanga" section on the day view, below existing cards.

---

## Phase 4 — Expansion (2027+)

**Theme:** Open the South Indian and Bengali-speaking markets.

### 4.1 Regional Calendars

| Calendar | Key difference |
|---|---|
| Tamil Panchangam | Nakshatra-based month system (not tithi-based); Tamil month names |
| Bengali Panjika | Different month names; Shakabda era |
| Onam (Malayalam) | Thiruvonam nakshatra detection — requires sidereal moon position |

Each requires a dedicated calculation path alongside the existing Drik engine. The `EphemerisService` abstraction is already in place.

### 4.2 Regional Festival Variants

Festival dates that differ by region (e.g. Diwali day varies North vs South; Vat Savitri observed on Purnima in Maharashtra vs Amavasya in the North). Requires a `RegionalConvention` enum in `AppSettings` and a parameterised `FestivalDetector`.

---

## Deferred Indefinitely

- Vakya calculation method
- Monetisation (ads, IAP, paid tier)
- Multi-user / family calendar
- Web version

---

## Open Items (carry-forward from v0.1)

- [ ] Color palette refinement — Shukla / Krishna / festival exact values
- [ ] Typography decision for Tamil / Bengali scripts
- [ ] Whether moon image animates between phases or is static (relevant to §2.4)
- [ ] Notification permission UX — when to prompt (onboarding vs first Ekadashi approach)
