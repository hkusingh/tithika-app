# Tithika — Requirements Document

**App name:** Tithika (तिथिका) — diminutive of *tithi*; signals tithi-focused scope.
**Version:** 0.1 (Initial Requirements)
**Date:** 2026-05-11
**Status:** Approved scope — ready to begin design

---

## 1. Overview

A mobile app for iOS and Android that calculates and displays **tithis** (lunar phases per the Hindu calendar) with astronomical accuracy. The app focuses on the tithi (and tithi-derived festivals/observances) rather than the full Panchanga.

**Audience:** General users — devout users (who need accuracy for fasts and observances) and curious users alike. The app must be approachable but the underlying math must be correct.

**License:** Open source.

---

## 2. Platforms & Tech Stack

| Item | Choice |
|------|--------|
| Target platforms | iOS and Android |
| Framework | **Flutter** (single codebase) |
| Language | Dart |
| Astronomical engine | **Swiss Ephemeris** (Astrodienst `libswe`) |
| Native integration | **Dart FFI** (`dart:ffi`) — evaluate the [`sweph`](https://pub.dev/packages/sweph) package first; fall back to custom FFI bindings if needed |
| Ephemeris data | Bundled as Flutter assets (~10 MB, Sun + Moon files) |
| Operation mode | **Fully offline** (no backend required) |
| Swiss Ephemeris license | **AGPL** (open-source app, no commercial license needed) |

---

## 3. Calendar System

| Item | Default | Configurable? |
|------|---------|---------------|
| Calculation method | **Drik** (true astronomical positions) | Future versions: add Vakya |
| Month system | **Purnimanta** (month ends on Purnima — North Indian convention) | Yes — Amanta toggle in Settings |
| Day-boundary rule (calendar grid) | **Sunrise-prevailing tithi** — whichever tithi is active at local sunrise is "that day's" tithi | Not user-configurable (standard practice) |
| Day-boundary rule (main view) | **Currently-active tithi**, with "transitions to X at HH:MM" line | Not user-configurable |

---

## 4. Core Calculations

Per location and date, the app computes:

- **Sun longitude** and **Moon longitude** (from Swiss Ephemeris)
- **Tithi** = `((moonLong − sunLong) mod 360) / 12°` → value 1–30
  - 1–15 = **Shukla Paksha** (waxing)
  - 16–30 = **Krishna Paksha** (waning); displayed as Krishna 1–14 + Amavasya
- **Tithi start time** and **end time** (when longitude difference crosses 12° boundaries)
- **Nakshatra** = `moonLong / (360/27)` → one of 27 nakshatras, with end time
- **Sunrise & sunset** (Swiss Ephemeris `swe_rise_trans`) — sunrise also used for day-boundary rule
- **Lunar month** (Chaitra, Vaishakha … Phalguna) — Purnimanta convention
- **Sun's zodiacal sign** (Makara, Mesha, etc.) — needed for solar festivals

Location-dependent — all calculations use user's lat/lon and timezone.

---

## 5. UI / Screen Structure

### 5.1 Main screen (default view)

**Top 75% — Today / selected date:**
- **Prominent Gregorian date** (large, hero element)
- Hindu month + paksha line (e.g., *Vaishakha · Shukla Paksha*)
- **Moon image** — rendered programmatically based on current illumination percentage (illumination derived from tithi)
- Tithi name (e.g., *Shukla Pratipada*) + tithi number
- Current tithi start time and end time (e.g., "6:42 AM – 8:17 PM")
- **Nakshatra** + end time
- **Sunrise & sunset** times
- Festival name if applicable (see §7)
- Special-day indicator if applicable (see §6)

**Bottom 25% — 4-day strip:**
- Previous day | **Current day (highlighted)** | Next day | Day after
- Each cell shows: date, tithi number, paksha color
- Tapping a cell makes it the selected date (top 75% updates)

### 5.2 Month view (toggleable from main screen)

- Standard month grid (7 columns)
- Each cell displays:
  - Gregorian date
  - Tithi number (sunrise-prevailing)
  - **Small moon-phase icon** — programmatic, accurate per tithi
  - Paksha color (Shukla = light/gold, Krishna = dark/blue) — exact palette TBD in design
  - Indicator dot for special tithi / festival days
- Tapping a day returns to main screen with that date selected

### 5.3 First-launch onboarding

On first app open, before reaching the main screen, the user is asked to set their location. This becomes their saved default; they can change it later in Settings.

Two ways to provide it:
- **Use my current location** — triggers OS GPS permission prompt; on grant, captures lat/lon and resolves to nearest city name
- **Enter manually** — searchable city picker

The user is strongly prompted to complete this step before entering the app. If GPS permission is denied, manual entry remains available.

**Fallback:** If the user dismisses the onboarding prompt without providing a location, the app uses **Ujjain** (75.78°E, 23.18°N — classical Hindu calendrical reference meridian) as a temporary location. A persistent banner on the main screen reads "Tap to set your location" until the user provides one.

### 5.4 Settings screen

| Setting | Options | Default |
|---------|---------|---------|
| Location | GPS (refresh from current) / Manual city picker | The location set during onboarding |
| Language | English / Hindi (Latin script) / Hindi (Devanagari script) | English |
| Month system | Purnimanta / Amanta | Purnimanta |

---

## 6. Special Tithi Indicators

Subtle visual indicators (dot/icon) on the calendar grid and a callout on the main view for:

| Tithi | Significance |
|-------|--------------|
| **Ekadashi** (11th, both pakshas) | Fasting day |
| **Purnima** (full moon) | Full moon observance |
| **Amavasya** (new moon) | New moon observance |
| **Chaturthi** (Krishna 4th) | Sankashti Chaturthi (Ganesh) |
| **Chaturthi** (Shukla 4th) | Vinayaka Chaturthi |
| **Trayodashi** (13th, both pakshas) | Pradosh |

---

## 7. Festivals (v1 scope)

Festival names overlaid on the relevant date.

**Tithi-based festivals** (derived from tithi + lunar month):

| Festival | Month | Tithi |
|---|---|---|
| Chaitra Navratri (Day 1) | Chaitra | Shukla 1 |
| Chaitra Navratri (Days 2–8) | Chaitra | Shukla 2–8 |
| Ram Navami | Chaitra | Shukla 9 |
| Hanuman Jayanti | Chaitra | Purnima (15) |
| Holi / Rangwali Holi | Chaitra | Krishna 1 (tithi 16) |
| Akshaya Tritiya | Vaishakha | Shukla 3 |
| Buddha Purnima | Vaishakha | Purnima (15) |
| Nirjala Ekadashi | Jyeshtha | Shukla 11 |
| Vat Savitri | Jyeshtha | Amavasya (30) |
| Rath Yatra | Ashadha | Shukla 2 |
| Devshayani Ekadashi | Ashadha | Shukla 11 |
| Guru Purnima | Ashadha | Purnima (15) |
| Nag Panchami | Shravana | Shukla 5 |
| Raksha Bandhan | Shravana | Purnima (15) |
| Krishna Janmashtami | Bhadrapada | Krishna 8 (tithi 23) |
| Ganesh Chaturthi | Bhadrapada | Shukla 4 |
| Anant Chaturdashi | Bhadrapada | Shukla 14 |
| Sharad Navratri (Day 1) | Ashwina | Shukla 1 |
| Sharad Navratri (Days 2–8) | Ashwina | Shukla 2–8 |
| Vijayadashami / Dussehra | Ashwina | Shukla 10 |
| Sharad Purnima | Ashwina | Purnima (15) |
| Dhanteras | Kartika | Krishna 13 (tithi 28) |
| Naraka Chaturdashi | Kartika | Krishna 14 (tithi 29) |
| Diwali | Kartika | Amavasya (30) |
| Govardhan Puja | Kartika | Shukla 1 (tithi 16) |
| Bhai Dooj | Kartika | Shukla 2 (tithi 17) |
| Chhath — Nahay Khay | Kartika | Shukla 4 |
| Chhath — Kharna | Kartika | Shukla 5 |
| Chhath — Sandhya Arghya | Kartika | Shukla 6 |
| Chhath — Usha Arghya | Kartika | Shukla 7 |
| Devutthana Ekadashi | Kartika | Shukla 11 |
| Kartik Purnima | Kartika | Purnima (15) |
| Gita Jayanti | Margashirsha | Shukla 11 |
| Vasant Panchami | Magha | Shukla 5 |
| Maha Shivaratri | Phalguna | Krishna 14 (tithi 29) |
| Holika Dahan | Phalguna | Purnima (15) |

**Solar festivals** (derived from Sun's sidereal zodiac sign transition):

| Festival | Condition |
|---|---|
| Makar Sankranti / Pongal | Sun enters Makara (sign 9) |
| Baisakhi / Vishu | Sun enters Mesha (sign 0) |

Regional date variations — out of scope for v1, default to North Indian Purnimanta-based dates.
Vat Savitri: observed on Jyeshtha Amavasya (North Indian convention).
Onam: requires nakshatra-based detection — deferred.

---

## 8. Localization

Three display modes (user-selectable):

| Mode | Example |
|------|---------|
| English | "Shukla Pratipada" |
| Hindi (Latin script) | "Shukla Pratipada" — currently same as English; may differ for festival names ("Deepavali" vs "Diwali") |
| Hindi (Devanagari script) | "शुक्ल प्रतिपदा" |

All tithi names, paksha names, month names, and festival names must be available in all three modes.

---

## 9. Non-functional Requirements

- **Offline-first** — no network required for any core function. Ephemeris files bundled.
- **Accuracy** — tithi transitions must match published Drik Panchang sources to within 1 minute.
- **Performance** — main screen renders in under 200ms on mid-range Android devices.
- **App size** — target under 30 MB installed (driven mostly by ephemeris data).
- **Privacy** — if GPS is used, location stays on-device. No analytics in v1.

---

## 10. Out of Scope (v1)

Explicitly deferred to later versions:
- Yoga, Karana (remaining elements of full Panchanga — Nakshatra is now included in v1)
- Rahu Kaal, Yamaganda, Gulika, Abhijit muhurta
- Moonrise/moonset display (sunrise/sunset now shown; moonrise/moonset deferred)
- Notifications / reminders for festivals or Ekadashi
- Home-screen widgets
- Vakya calculation method
- Tamil / Bengali / Malayalam / Marathi / Gujarati regional calendars
- Multi-region festival date variations (e.g., regional Diwali differences)
- Photo-realistic moon imagery (stylized programmatic render for v1)
- Monetization (ads, in-app purchases, paid tier)

---

## 11. Future Versions (noted, not committed)

- Pre-rendered moon images (replace programmatic render)
- Notifications (Ekadashi, Purnima, Amavasya, festivals)
- Full Panchanga
- Additional regional calendars
- Muhurta / auspicious time calculations
- Home-screen widgets (iOS and Android)
- More languages (Tamil, Bengali, Malayalam, Marathi, Gujarati, etc.)

---

## 12. Open Items (to resolve before/during design phase)

- [x] App name — **Tithika**
- [x] Visual theme — **dark / night-sky background** across all screens
- [ ] Color palette refinement (Shukla / Krishna / festival exact values — current draft: warm gold #d9a441, cool indigo #4a5fc1, saffron #c8421d)
- [ ] Typography (especially for Devanagari script support)
- [ ] Exact festival list beyond the confirmed five
- [x] Default location — **set by user during first-launch onboarding** (GPS or manual entry); no preset fallback
- [x] Behavior if user dismisses onboarding location prompt — **Ujjain fallback with persistent "Tap to set your location" banner**
- [ ] Whether the moon image animates between phases or is static
