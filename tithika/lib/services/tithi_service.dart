import '../models/day_data.dart';
import '../models/lunar_month.dart';
import '../models/nakshatra_info.dart';
import '../models/paksha.dart';
import '../models/special_tithi.dart';
import '../models/tithi_info.dart';
import 'ephemeris_service.dart';

// Each tithi spans exactly 12° of Moon–Sun elongation.
const _degPerTithi = 12.0;

// Each nakshatra spans 360/27 degrees of sidereal Moon longitude.
const _degPerNakshatra = 360.0 / 27.0;

// Net rate at which elongation increases (Moon – Sun, degrees per day).
const _elongationRatePerDay = 12.19;

class TithiService {
  final EphemerisService _ephe;

  TithiService(this._ephe);

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Compute all astronomical data for [localDate] at the given location.
  ///
  /// [localDate] should be a date-only value (time component is ignored).
  /// All returned UTC times can be converted to local using [tzOffset].
  DayData calculateForDate({
    required DateTime localDate,
    required double lat,
    required double lon,
    required Duration tzOffset,
  }) {
    // UTC midnight for this local date.
    final utcMidnight = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
    ).subtract(tzOffset);

    final sunriseUtc = _ephe.sunrise(utcMidnight, lat, lon);
    final sunsetUtc = _ephe.sunset(utcMidnight, lat, lon);

    // All calculations use sunrise as the reference time, per the Drik
    // day-boundary rule.  If GPS fails or the sun never rises (polar edge
    // case), fall back to UTC noon.
    final referenceUtc = sunriseUtc ?? utcMidnight.add(const Duration(hours: 6));
    final referenceJd = _ephe.julianDayFromUtc(referenceUtc);

    final tithi = _tithiAt(referenceJd);
    final nakshatra = _nakshatraAt(referenceJd);
    final sunZodiacSign = _sunZodiacSign(referenceJd);
    final (lunarMonth, isAdhika) = _lunarMonthAndAdhika(referenceJd, tithi.number);
    final sunZodiacEntryToday =
        _sunZodiacSign(referenceJd - 1.0) != sunZodiacSign;

    // Check for a secondary (kshaya) tithi: if the sunrise tithi ends before
    // the next sunrise, a second tithi begins within this calendar day.
    final nextDayUtcMidnight = utcMidnight.add(const Duration(days: 1));
    final nextSunriseUtc = _ephe.sunrise(nextDayUtcMidnight, lat, lon)
        ?? nextDayUtcMidnight.add(const Duration(hours: 6));
    TithiInfo? secondaryTithi;
    if (tithi.end.isBefore(nextSunriseUtc)) {
      final secondaryJd = _ephe.julianDayFromUtc(
        tithi.end.add(const Duration(minutes: 1)),
      );
      secondaryTithi = _tithiAt(secondaryJd);
    }

    return DayData(
      localDate: DateTime(localDate.year, localDate.month, localDate.day),
      tithi: tithi,
      nakshatra: nakshatra,
      sunriseUtc: sunriseUtc,
      sunsetUtc: sunsetUtc,
      lunarMonth: lunarMonth,
      sunZodiacSign: sunZodiacSign,
      sunZodiacEntryToday: sunZodiacEntryToday,
      secondaryTithi: secondaryTithi,
      isAdhika: isAdhika,
    );
  }

  /// Tithi active at an arbitrary UTC moment (used by the Day View to show
  /// the currently active tithi, not just the sunrise-prevailing one).
  TithiInfo tithiAt(DateTime utc) {
    return _tithiAt(_ephe.julianDayFromUtc(utc));
  }

  // ── Tithi ───────────────────────────────────────────────────────────────────

  TithiInfo _tithiAt(double jd) {
    final moonLong = _ephe.moonLongitude(jd);
    final sunLong = _ephe.sunLongitude(jd);
    final num = _tithiNumber(moonLong, sunLong);
    final paksha = num <= 15 ? Paksha.shukla : Paksha.krishna;
    final pakshaNum = num <= 15 ? num : num - 15;

    // Boundaries: tithi N spans elongation ((N-1)*12°, N*12°]
    final startAngle = ((num - 1) * _degPerTithi) % 360.0;
    final endAngle = (num * _degPerTithi) % 360.0; // 0.0 for tithi 30

    final startJd = _prevBoundaryJd(jd, startAngle, _elongation);
    final endJd = _nextBoundaryJd(jd, endAngle, _elongation);

    return TithiInfo(
      number: num,
      pakshaNumber: pakshaNum,
      paksha: paksha,
      start: _ephe.utcFromJulianDay(startJd),
      end: _ephe.utcFromJulianDay(endJd),
      special: _specialTithi(num),
    );
  }

  int _tithiNumber(double moonLong, double sunLong) {
    final elong = (moonLong - sunLong + 360.0) % 360.0;
    final raw = (elong / _degPerTithi).ceil();
    // At exactly 0° elongation ceil() returns 0; that boundary belongs to
    // Amavasya (30).
    return raw == 0 ? 30 : raw;
  }

  double _elongation(double jd) {
    final moon = _ephe.moonLongitude(jd);
    final sun = _ephe.sunLongitude(jd);
    return (moon - sun + 360.0) % 360.0;
  }

  SpecialTithi? _specialTithi(int num) {
    return switch (num) {
      11 || 26 => SpecialTithi.ekadashi,
      15 => SpecialTithi.purnima,
      30 => SpecialTithi.amavasya,
      4 => SpecialTithi.vinayakaChaturthi,
      19 => SpecialTithi.sankashtiChaturthi,
      13 || 28 => SpecialTithi.pradosh,
      _ => null,
    };
  }

  // ── Nakshatra ───────────────────────────────────────────────────────────────

  NakshatraInfo _nakshatraAt(double jd) {
    final siderealMoon = _ephe.siderealMoonLongitude(jd);
    final num = (siderealMoon / _degPerNakshatra).floor() + 1; // 1–27
    // End boundary: the nakshatra ends when sidereal Moon reaches num * span
    final endAngle = (num * _degPerNakshatra) % 360.0;
    final endJd = _nextBoundaryJd(jd, endAngle, _siderealMoonLong);
    return NakshatraInfo(
      number: num.clamp(1, 27),
      end: _ephe.utcFromJulianDay(endJd),
    );
  }

  double _siderealMoonLong(double jd) => _ephe.siderealMoonLongitude(jd);

  // ── Sun zodiac sign ─────────────────────────────────────────────────────────

  int _sunZodiacSign(double jd) {
    return (_ephe.siderealSunLongitude(jd) / 30.0).floor().clamp(0, 11);
  }

  // ── Lunar month (Purnimanta + Adhika detection) ──────────────────────────────

  /// Determines the Amanta lunar month for [sunriseJd] and whether it is an
  /// Adhika (intercalary) month.
  ///
  /// Rule (Wikipedia / drikpanchang): a month is Adhika when the sun does NOT
  /// transit into a new sidereal rashi between two consecutive Amavasyas.
  /// Month name = sun sign at the previous Amavasya (Amanta base).
  (LunarMonth, bool) _lunarMonthAndAdhika(double sunriseJd, int tithiNum) {
    final curElong = _elongation(sunriseJd);

    // Find previous Amavasya (elongation = 0°).
    // Estimate puts the search window ~2 days before the true crossing so the
    // window starts with elongation still approaching 0° (d > 180 → not reached).
    final daysSincePrev = curElong / _elongationRatePerDay;
    final prevAmavasyaJd = _nextBoundaryJd(
      sunriseJd - daysSincePrev - 2.0, 0.0, _elongation, maxDays: 5.0);

    // Find next Amavasya similarly.
    final daysToNext = (360.0 - curElong) / _elongationRatePerDay;
    final nextAmavasyaJd = _nextBoundaryJd(
      sunriseJd + daysToNext - 2.0, 0.0, _elongation, maxDays: 5.0);

    final signAtPrev =
        (_ephe.siderealSunLongitude(prevAmavasyaJd) / 30.0).floor().clamp(0, 11);
    final signAtNext =
        (_ephe.siderealSunLongitude(nextAmavasyaJd) / 30.0).floor().clamp(0, 11);

    // Same rashi at both new moons = no Sankranti within = Adhika month.
    final isAdhika = signAtPrev == signAtNext;

    // Month name = prevAmavasya sign (Amanta base).
    // Correct for regular months, Adhika months, and Nija months after Adhika.
    return (LunarMonth.values[signAtPrev], isAdhika);
  }

  // ── Binary search ───────────────────────────────────────────────────────────

  /// Returns the next JD (≥ [fromJd]) when [angleFn] crosses [targetAngle]
  /// in the increasing direction.
  ///
  /// The [maxDays] window must be small enough that the angle travels <180°
  /// within it (otherwise the d>180 heuristic is ambiguous).  Default 1.5 days
  /// is safe for tithis and nakshatras.  Pass 4.0 when searching for Purnima
  /// in a pre-estimated window.
  double _nextBoundaryJd(
    double fromJd,
    double targetAngle,
    double Function(double jd) angleFn, {
    double maxDays = 1.5,
  }) {
    double lo = fromJd;
    double hi = fromJd + maxDays;
    for (var i = 0; i < 52; i++) {
      final mid = (lo + hi) / 2;
      final d = (angleFn(mid) - targetAngle + 360.0) % 360.0;
      if (d > 180.0) {
        lo = mid; // not reached yet
      } else {
        hi = mid; // at or past target
      }
    }
    return (lo + hi) / 2;
  }

  /// Returns the most recent JD (≤ [fromJd]) when [angleFn] last crossed
  /// [targetAngle] in the increasing direction.
  double _prevBoundaryJd(
    double fromJd,
    double targetAngle,
    double Function(double jd) angleFn, {
    double maxDays = 1.5,
  }) {
    double lo = fromJd - maxDays;
    double hi = fromJd;
    for (var i = 0; i < 52; i++) {
      final mid = (lo + hi) / 2;
      final d = (angleFn(mid) - targetAngle + 360.0) % 360.0;
      if (d > 180.0) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2;
  }
}
