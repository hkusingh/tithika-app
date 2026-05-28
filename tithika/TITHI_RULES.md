# Tithi Rules — Festival Date Determination

**Last updated:** 2026-05-22

---

## What is a Tithi?

A *tithi* is a lunar day — the time it takes for the Moon to move exactly 12° relative to the Sun. Because the Moon's speed varies, a tithi can last anywhere from 20 to 27 hours. This means a tithi frequently overlaps two consecutive sunrises, or in rare cases passes entirely between two sunrises without touching either (a *Kshaya* tithi).

A solar calendar day runs from one sunrise to the next. A tithi and a solar day are almost never perfectly aligned, which is why Hindu festival dates shift year to year relative to the Gregorian calendar.

---

## The Three Rules

### 1. Sunrise Rule (Standard)

A festival is observed on the solar day when the required tithi is active at local sunrise.

This is the default rule and covers the majority of festivals. If Ekadashi (tithi 11) is active at today's sunrise, today is the Ekadashi observance day — regardless of when that tithi began or ends.

**Applied to:** Ram Navami, Hanuman Jayanti, Raksha Bandhan, Vijayadashami, Dhanteras, Chhath Nahay Khay, Chhath Usha Arghya, and most other tithi-based festivals.

**Edge case — Kshaya tithi:** When a tithi is so short that it fits entirely between two consecutive sunrises (never the active tithi at any sunrise), it becomes a secondary tithi on the day it falls within. Tithika checks both the primary and secondary tithi so a kshaya festival is never silently dropped.

---

### 2. Vyapini (Duration) Rule

For certain festivals, sunrise alone is not sufficient. The tithi must be active at a specific window of the day — typically midday (*Madhyahna*) or sunset.

**Day 1 vs. Day 2:** If the required tithi touches sunrise briefly on Day 1 but fully covers the prescribed window on Day 2, the festival is observed on Day 2. Conversely, if the tithi begins after sunrise but reaches the prescribed window before the next sunrise, the festival belongs to Day 1.

**Ekadashi previous-day rule:** Ekadashi fasts require the tithi to be active at dawn *and* must avoid the tithi bleeding into the following day. When this conflict arises, observance shifts to the earlier day.

---

### 3. Moon Phase / Specific Time Rule

Certain festivals are intrinsically tied to a particular time of day or night because of their ritual character. The required tithi must prevail at that specific moment.

- **Diwali** — Amavasya (New Moon, tithi 30) must be active at sunset and into the evening to allow lamp-lighting.
- **Ganesh Chaturthi** — Chaturthi (tithi 4) must be active at Madhyahna (midday), the auspicious afternoon period. If Chaturthi starts after sunrise but is present at midday, the festival is that day.
- **Maha Shivaratri** — Chaturdashi (tithi 29) must prevail during the night, even if it does not align with the morning sunrise.
- **Chhath Kharna** — Panchami (tithi 5) must be active at sunset; devotees break their fast after moonrise.
- **Chhath Sandhya Arghya** — Shasthi (tithi 6) must be active at sunset for the evening water offering.

---

## Regional and Global Variance

Tithis are calculated from precise astronomical moments in universal time. The same tithi therefore occurs at different local times around the world. A tithi that spans sunset in India may have already ended — or not yet begun — at the equivalent moment in California.

Tithika computes all tithi boundaries using the Swiss Ephemeris and the user's local coordinates, so every festival date reflects the astronomically correct local observance rather than India Standard Time.

---

## Chhath Puja — Example (Bay Area, CA, 2026)

Chhath is dedicated to Surya (the Sun God), so every ritual window is anchored to local sunrise and sunset. The Bay Area 2026 schedule illustrates all three rules in sequence:

| Day | Ritual | Date | Rule Applied | Tithi Required |
|---|---|---|---|---|
| 1 | Nahay Khay | Fri, Nov 13 | Sunrise Rule | Chaturthi (4) at sunrise |
| 2 | Kharna | Sat, Nov 14 | Moon Phase / Sunset Window | Panchami (5) at sunset |
| 3 | Sandhya Arghya | Sun, Nov 15 | Vyapini Rule at Sunset | Shasthi (6) at sunset |
| 4 | Usha Arghya | Mon, Nov 16 | Sunrise Rule | Saptami (7) at sunrise |

**Why Kharna can never collide with Nahay Khay:** Chaturthi must span a full sunrise to claim Day 1 (Nahay Khay). If Chaturthi spans Day 1's sunrise, it almost certainly spanned Day 0's sunrise as well — meaning Nahay Khay was already assigned to Day 0. By the time Panchami is active at Day 1's sunset, Nahay Khay is already settled on a prior day.

---

## Implementation in Tithika

`lib/services/festival_detector.dart` enforces these rules with three detection layers, applied in priority order:

### Priority 1 — Solar festivals
Sun crosses a 30° zodiac boundary today (Sankranti). Overrides all tithi rules.
Examples: Makar Sankranti, Baisakhi / Vishu.

### Priority 2 — Special-window festivals (`_specialWindowFestival`)
Tithi must be active at a specific moment. Tithika computes:

- **Madhyahna** = `sunrise + (sunset − sunrise) / 2`
- **Sunset window** = `sunsetUtc`

Both the primary tithi (active at sunrise) and the secondary intra-day tithi (begins after sunrise) are checked via `_tithiActiveAt()`.

| Festival | Month | Tithi | Window |
|---|---|---|---|
| Chhath — Kharna | Kartika | Panchami (5) | Sunset |
| Chhath — Sandhya Arghya | Kartika | Shasthi (6) | Sunset |
| Diwali | Kartika | Amavasya (30) | Sunset |
| Ganesh Chaturthi | Bhadrapada | Chaturthi (4) | Madhyahna |
| Maha Shivaratri | Phalguna | Chaturdashi (29) | Sunset |

**Polar fallback:** If `sunriseUtc` or `sunsetUtc` is null (sun does not rise or set), special-window detection is skipped and the sunrise rule applies.

### Priority 3 — Sunrise-rule festivals (`_byTithi`)
Tithi active at local sunrise determines the festival. Covers all remaining tithi-based festivals. Also checks the secondary (kshaya) tithi when `secondaryIsKshaya` is true.

---

## Tithi Number Reference

| Range | Paksha | Tithis |
|---|---|---|
| 1 – 15 | Shukla (waxing) | Pratipada through Purnima |
| 16 – 29 | Krishna (waning) | Pratipada through Chaturdashi |
| 30 | — | Amavasya (New Moon) |
