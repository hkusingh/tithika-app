import '../models/day_data.dart';
import '../models/lunar_month.dart';

abstract final class FestivalDetector {
  /// Returns the English festival name(s) for [day], or an empty list if it
  /// is an ordinary day. Each entry is an independent, individually
  /// localizable/linkable canonical festival name — when more than one is
  /// returned, they are unrelated festivals whose rules both matched the
  /// same calendar day (e.g. a sunrise-rule festival and a special-window
  /// festival), NOT a single combined festival, so callers must render and
  /// link them as separate items rather than joining the strings.
  ///
  /// Tithi numbers use the continuous 1–30 scale: Shukla 1–15 = 1–15,
  /// Krishna 1–14 = 16–29, Amavasya = 30.
  ///
  /// Each returned string is always English and serves as the canonical key.
  /// Use FestivalNames.localize() in the display layer to get a localized name.
  ///
  /// When a kshaya (skipped) tithi falls entirely between two sunrises it
  /// becomes [DayData.secondaryTithi].  This method checks both tithis so
  /// the festival is never silently dropped for western time-zones.
  ///
  /// [tomorrow] is tomorrow's [DayData] at the same location, used to resolve
  /// vruddhi (expanded) tithis — see the comment below.  Pass null only when
  /// tomorrow's data is genuinely unavailable; the vruddhi check is then
  /// skipped and the festival may be reported a day early.
  static List<String> detectAll(DayData day, [DayData? tomorrow]) {
    // ── Solar festivals ──────────────────────────────────────────────────────
    if (day.sunZodiacEntryToday) {
      final solar = switch (day.sunZodiacSign) {
        0 => 'Baisakhi / Vishu',           // Sun enters Mesha
        9 => 'Makar Sankranti / Pongal',   // Sun enters Makara
        _ => null,
      };
      if (solar != null) return [solar];
      // Other sign crossings have no named festival — fall through to tithi check.
    }

    // ── Tithi-based festivals ────────────────────────────────────────────────
    // No tithi-based festivals in Adhika (intercalary) months.
    if (day.isAdhika) return const [];

    // Special-window festivals are computed alongside the sunrise rule (not as
    // an early return) so a special-window festival and a sunrise-rule
    // festival landing on the same calendar day are both reported — this
    // previously caused Ganesh Chaturthi (Madhyahna rule) to silently shadow
    // Hartalika Teej (sunrise rule) whenever both tithis fell on one day.
    final special = _specialWindowFestival(day);

    final m = day.lunarMonth;
    final primary   = _byTithi(m, day.tithi.number);

    // Vruddhi (expanded) tithi: when secondaryTithi is null, TODAY's tithi
    // continues past the next sunrise, meaning it will also rule tomorrow.
    // Drik panchang observes the festival on the LAST such day, so suppress
    // primary here — but only when a sunrise-rule festival actually matched
    // today's tithi; an unrelated vruddhi tithi elsewhere in the day must not
    // blank out the whole day (this previously caused sunrise-rule festivals
    // like Hartalika Teej to disappear whenever the sunrise tithi happened to
    // be vruddhi, even though the festival's own tithi was unaffected).
    var effectivePrimary = primary;
    if (primary != null && day.secondaryTithi == null) {
      final tomorrowStillSame = tomorrow?.tithi.number == day.tithi.number;
      if (tomorrowStillSame) effectivePrimary = null;
    }

    // Purnima (tithi 15) is an exception to the last-day rule above: it
    // follows the Purvahna/Madhyahna Vyapini convention instead — observed on
    // whichever day Purnima prevails at Madhyahna (sunrise-to-sunset
    // midpoint), preferring the FIRST qualifying day if both do (Purva
    // Vyapini tie-break — astronomically rare but possible, since tithi 15
    // can last up to ~26.3h against a ~24h sunrise-to-sunrise gap). This
    // overrides the vruddhi suppression in both directions: it can
    // un-suppress day 1 (when Purnima doesn't survive to day 2's Madhyahna,
    // as in Guru Purnima 2026 for Fremont: Purnima rules both Jul 28 and
    // Jul 29 sunrise but ends at 07:35 on the 29th, before that day's
    // Madhyahna) or suppress day 2 (when day 1 already qualified).
    if (primary != null && day.tithi.number == 15) {
      final sunrise = day.sunriseUtc;
      final sunset = day.sunsetUtc;
      // Today is genuinely day 2 of a tithi-15 vruddhi span only if tithi 15
      // was already ruling at YESTERDAY's sunrise too (approximated as
      // today's sunrise minus 1 day — accurate to within the day-to-day
      // drift of sunrise times, at most a couple of minutes). Only then does
      // checking yesterday's Madhyahna for the tie-break make sense; e.g. if
      // tithi 15 only began mid-day yesterday (ordinary non-vruddhi case),
      // yesterday was never a tithi-15 day and must not be treated as an
      // already-qualified day 1.
      final isDayTwoOfVruddhi = sunrise != null &&
          day.tithi.start.isBefore(sunrise.subtract(const Duration(days: 1)));
      final yesterdayAlreadyQualified = isDayTwoOfVruddhi &&
          sunset != null &&
          _tithiActiveAt(day, 15, sunrise.subtract(sunset.difference(sunrise) ~/ 2));
      effectivePrimary = (!yesterdayAlreadyQualified && _tithiActiveAtMadhyahna(day, 15))
          ? primary
          : null;
    }

    // Only check secondary for festivals when it is a true kshaya tithi —
    // i.e. it never becomes the primary on any calendar day.
    final secondary = (day.secondaryTithi != null && day.secondaryIsKshaya)
        ? _byTithi(m, day.secondaryTithi!.number)
        : null;

    return [special, effectivePrimary, secondary].whereType<String>().toSet().toList();
  }

  /// Convenience wrapper for callers that only need a single name (e.g. to
  /// test "is this day a festival day at all"). Returns the first name from
  /// [detectAll], or null. Prefer [detectAll] wherever the UI renders or
  /// links festival names, so multiple same-day festivals are never merged
  /// into one unlinkable string.
  static String? detect(DayData day, [DayData? tomorrow]) {
    final all = detectAll(day, tomorrow);
    return all.isEmpty ? null : all.first;
  }

  // ── Special-window festivals ───────────────────────────────────────────────
  //
  // These festivals are prescribed for a specific moment other than sunrise:
  //
  //   Sunset window
  //     • Diwali             — Amavasya    (tithi 30) active at sunset
  //     • Maha Shivaratri    — Chaturdashi (tithi 29) active at sunset
  //
  //   Madhyahna window  (midpoint of the sunrise–sunset arc)
  //     • Ganesh Chaturthi   — Chaturthi   (tithi  4) active at Madhyahna
  //
  // Polar-region fallback: if sunriseUtc or sunsetUtc is null (sun does not
  // rise or set), skip special-window detection entirely and fall back to the
  // sunrise rule via _byTithi.
  static String? _specialWindowFestival(DayData day) {
    final sunrise = day.sunriseUtc;
    final sunset  = day.sunsetUtc;
    if (sunrise == null || sunset == null) return null;

    final madhyahna = sunrise.add(sunset.difference(sunrise) ~/ 2);
    final m = day.lunarMonth;

    // Kartika sunset-window festivals.
    if (m == LunarMonth.kartika) {
      if (_tithiActiveAt(day, 30, sunset)) return 'Diwali';                   // Amavasya
    }

    // Ganesh Chaturthi — Madhyahna rule (Bhadrapada Shukla 4).
    if (m == LunarMonth.bhadrapada && _tithiActiveAt(day, 4, madhyahna)) {
      return 'Ganesh Chaturthi';
    }

    // Maha Shivaratri — sunset / night rule (Phalguna Krishna 14 = tithi 29).
    if (m == LunarMonth.phalguna && _tithiActiveAt(day, 29, sunset)) {
      return 'Maha Shivaratri';
    }

    return null;
  }

  /// Returns true if [tithiNumber] is active at [day]'s Madhyahna (the
  /// sunrise-to-sunset midpoint). Used for the Purnima Purvahna/Madhyahna
  /// Vyapini rule. Falls back to true (defer to the sunrise rule) when
  /// sunrise/sunset are unavailable (polar edge case).
  static bool _tithiActiveAtMadhyahna(DayData day, int tithiNumber) {
    final sunrise = day.sunriseUtc;
    final sunset = day.sunsetUtc;
    if (sunrise == null || sunset == null) return true;
    final madhyahna = sunrise.add(sunset.difference(sunrise) ~/ 2);
    return _tithiActiveAt(day, tithiNumber, madhyahna);
  }

  /// Returns true if [tithiNumber] is astronomically active at [moment].
  ///
  /// Checks both the primary tithi (active from its own start through its end)
  /// and the secondary intra-day tithi (began after sunrise) so window checks
  /// are never missed when the relevant tithi starts after sunrise.
  static bool _tithiActiveAt(DayData day, int tithiNumber, DateTime moment) {
    // Primary tithi: defined from its astronomical start to its end.
    if (day.tithi.number == tithiNumber &&
        !moment.isBefore(day.tithi.start) &&
        moment.isBefore(day.tithi.end)) {
      return true;
    }
    // Secondary tithi: started after sunrise; honour its own [start, end) window.
    final sec = day.secondaryTithi;
    if (sec != null &&
        sec.number == tithiNumber &&
        !moment.isBefore(sec.start) &&
        moment.isBefore(sec.end)) {
      return true;
    }
    return false;
  }

  // ── Sunrise-rule festivals ─────────────────────────────────────────────────
  //
  // Month follows Purnimanta convention: month ends at Purnima.
  // Krishna paksha days belong to the month whose Purnima comes next.
  // e.g. Dhanteras (Kartika Krishna 13) → lunarMonth = kartika.
  //
  // Festivals intentionally absent (handled by _specialWindowFestival):
  //   Diwali                 (Kartika 30  — Amavasya at sunset)
  //   Ganesh Chaturthi       (Bhadrapada 4 — Chaturthi at Madhyahna)
  //   Maha Shivaratri        (Phalguna 29 — Chaturdashi at sunset)
  static String? _byTithi(LunarMonth m, int t) {
    return switch ((m, t)) {
      // Chaitra
      (LunarMonth.chaitra, 1)  => 'Gudi Padwa / Ugadi / Chaitra Navratri',
      (LunarMonth.chaitra, 8)  => 'Maha Ashtami',
      (LunarMonth.chaitra, 9)  => 'Ram Navami',           // Shukla 9
      (LunarMonth.chaitra, 15) => 'Hanuman Jayanti',      // Purnima
      (LunarMonth.chaitra, 16) => 'Holi',                 // Krishna 1 = Rangwali Holi

      // Vaishakha
      (LunarMonth.vaishakha, 3)  => 'Akshaya Tritiya',   // Shukla 3
      (LunarMonth.vaishakha, 15) => 'Buddha Purnima',

      // Jyeshtha
      (LunarMonth.jyeshtha, 10) => 'Ganga Dussehra',     // Shukla 10
      (LunarMonth.jyeshtha, 11) => 'Nirjala Ekadashi',   // Shukla 11
      (LunarMonth.jyeshtha, 30) => 'Vat Savitri',        // Amavasya

      // Ashadha
      (LunarMonth.ashadha, 2)  => 'Rath Yatra',          // Shukla 2
      (LunarMonth.ashadha, 11) => 'Devshayani Ekadashi', // Shukla 11
      (LunarMonth.ashadha, 15) => 'Guru Purnima',

      // Shravana
      (LunarMonth.shravana, 3)  => 'Hariyali Teej',      // Shukla 3
      (LunarMonth.shravana, 5)  => 'Nag Panchami',       // Shukla 5
      (LunarMonth.shravana, 15) => 'Raksha Bandhan',

      // Bhadrapada — Krishna 8 (tithi 23) falls here because in Purnimanta
      // the days after Shravana Purnima belong to Bhadrapada month.
      (LunarMonth.bhadrapada, 3)  => 'Hartalika Teej',      // Shukla 3
      (LunarMonth.bhadrapada, 23) => 'Krishna Janmashtami', // Krishna 8
      // Ganesh Chaturthi (Bhadrapada 4) → _specialWindowFestival
      (LunarMonth.bhadrapada, 14) => 'Anant Chaturdashi',   // Shukla 14

      // Ashwina
      (LunarMonth.ashwina, 1)  => 'Sharad Navratri',
      (LunarMonth.ashwina, 23) => 'Jivitputrika Vrat (Jitiya)', // Krishna 8
      (LunarMonth.ashwina, 30) => 'Mahalaya Amavasya',
      (LunarMonth.ashwina, 8)  => 'Maha Ashtami',
      (LunarMonth.ashwina, 9)  => 'Maha Navami',
      (LunarMonth.ashwina, 10) => 'Vijayadashami',
      (LunarMonth.ashwina, 15) => 'Sharad Purnima',

      // Kartika — Krishna paksha (tithi 16–30) and Shukla (1–15) all in same month.
      (LunarMonth.kartika, 19) => 'Karva Chauth',            // Krishna 4
      (LunarMonth.kartika, 23) => 'Ahoi Ashtami',            // Krishna 8
      (LunarMonth.kartika, 28) => 'Dhanteras',               // Krishna 13
      (LunarMonth.kartika, 29) => 'Naraka Chaturdashi',      // Krishna 14
      // Diwali (Kartika 30) → _specialWindowFestival
      (LunarMonth.kartika, 1)  => 'Govardhan Puja',          // Shukla 1
      (LunarMonth.kartika, 2)  => 'Bhai Dooj',               // Shukla 2
      (LunarMonth.kartika, 4)  => 'Chhath — Nahay Khay',     // Shukla 4
      (LunarMonth.kartika, 5)  => 'Chhath — Kharna',         // Shukla 5
      (LunarMonth.kartika, 6)  => 'Chhath — Sandhya Arghya', // Shukla 6
      (LunarMonth.kartika, 7)  => 'Chhath — Usha Arghya',    // Shukla 7
      (LunarMonth.kartika, 11) => 'Devutthana Ekadashi',     // Shukla 11
      (LunarMonth.kartika, 12) => 'Tulsi Vivah',             // Shukla 12
      (LunarMonth.kartika, 15) => 'Kartik Purnima',

      // Margashirsha
      (LunarMonth.margashirsha, 11) => 'Gita Jayanti',      // Shukla 11

      // Magha
      (LunarMonth.magha, 5) => 'Vasant Panchami',           // Shukla 5

      // Phalguna
      // Maha Shivaratri (Phalguna 29) → _specialWindowFestival
      (LunarMonth.phalguna, 15) => 'Holika Dahan',

      _ => null,
    };
  }
}
