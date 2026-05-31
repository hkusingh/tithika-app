import '../models/day_data.dart';
import '../models/lunar_month.dart';

abstract final class FestivalDetector {
  /// Returns the English festival name for [day], or null if it is an ordinary day.
  ///
  /// Detection priority:
  ///   1. Solar festivals (Sankranti) — sun crosses a sign boundary today.
  ///   2. Special-window festivals — prescribed for a moment other than sunrise
  ///      (sunset or Madhyahna).  See [_specialWindowFestival].
  ///   3. Sunrise-rule festivals — tithi active at local sunrise.
  ///
  /// Tithi numbers use the continuous 1–30 scale: Shukla 1–15 = 1–15,
  /// Krishna 1–14 = 16–29, Amavasya = 30.
  ///
  /// The returned string is always English and serves as the canonical key.
  /// Use FestivalNames.localize() in the display layer to get a localized name.
  ///
  /// When a kshaya (skipped) tithi falls entirely between two sunrises it
  /// becomes [DayData.secondaryTithi].  This method checks both tithis so
  /// the festival is never silently dropped for western time-zones.
  static String? detect(DayData day) {
    // ── Solar festivals ──────────────────────────────────────────────────────
    if (day.sunZodiacEntryToday) {
      final solar = switch (day.sunZodiacSign) {
        0 => 'Baisakhi / Vishu',           // Sun enters Mesha
        9 => 'Makar Sankranti / Pongal',   // Sun enters Makara
        _ => null,
      };
      if (solar != null) return solar;
      // Other sign crossings have no named festival — fall through to tithi check.
    }

    // ── Tithi-based festivals ────────────────────────────────────────────────
    // No tithi-based festivals in Adhika (intercalary) months.
    if (day.isAdhika) return null;

    // Special-window festivals are checked first; they take priority over the
    // sunrise rule so the correct calendar day is always chosen.
    final special = _specialWindowFestival(day);
    if (special != null) return special;

    // Vruddhi (expanded) tithi: when secondaryTithi is null the primary tithi
    // continues past the next sunrise, meaning today is the FIRST of two
    // consecutive days with this tithi as primary.  Drik panchang observes the
    // festival on the LAST such day, so suppress here and it will appear
    // naturally tomorrow when the tithi ends before the next sunrise.
    if (day.secondaryTithi == null) return null;

    final m = day.lunarMonth;
    final primary   = _byTithi(m, day.tithi.number);
    // Only check secondary for festivals when it is a true kshaya tithi —
    // i.e. it never becomes the primary on any calendar day.
    final secondary = (day.secondaryTithi != null && day.secondaryIsKshaya)
        ? _byTithi(m, day.secondaryTithi!.number)
        : null;

    if (primary != null && secondary != null) return '$primary / $secondary';
    return primary ?? secondary;
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

  /// Returns true if [tithiNumber] is astronomically active at [moment].
  ///
  /// Checks both the primary tithi (active from its own start through its end)
  /// and the secondary intra-day tithi (began after sunrise) so window checks
  /// are never missed when the relevant tithi starts after sunrise.
  static bool _tithiActiveAt(DayData day, int tithiNumber, DateTime moment) {
    // Primary tithi: defined from its astronomical start to its end.
    if (day.tithi.number == tithiNumber && moment.isBefore(day.tithi.end)) {
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
