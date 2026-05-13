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
    final lunarMonth = _lunarMonth(referenceJd, tithi.number);
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

  // ── Lunar month (Purnimanta) ─────────────────────────────────────────────────

  /// Determines the Purnimanta month for the given [sunriseJd].
  ///
  /// In Purnimanta, the month ENDS at Purnima.  The month name comes from the
  /// sidereal sun sign at the Purnima that ends it.  We always search FORWARD
  /// for the next (upcoming) Purnima, which is the one that ends the current
  /// month regardless of whether we are in Shukla or Krishna paksha.
  ///
  /// The binary-search in [_nextBoundaryJd] breaks down when the search
  /// window spans >180° of elongation travel, so instead of a fixed window
  /// we estimate the days remaining to the next Purnima and search within a
  /// tight ±2-day bracket around that estimate.
  LunarMonth _lunarMonth(double sunriseJd, int tithiNum) {
    const purnimaAngle = 180.0;

    final curElong = _elongation(sunriseJd);

    // Degrees left until the next 180° crossing.
    // In Shukla (0–180): travel = 180 - elong.
    // In Krishna (180–360): travel = (360 - elong) + 180 = 540 - elong.
    final degreesLeft = curElong <= purnimaAngle
        ? purnimaAngle - curElong
        : 540.0 - curElong;
    final daysLeft = degreesLeft / _elongationRatePerDay;

    // Search in a ±2-day window around the estimate — well within the 180°
    // threshold that the binary search requires.
    final searchFrom = sunriseJd + daysLeft - 2.0;
    final purnimaJd = _nextBoundaryJd(searchFrom, purnimaAngle, _elongation,
        maxDays: 4.0);

    final sunSignAtPurnima =
        (_ephe.siderealSunLongitude(purnimaJd) / 30.0).floor().clamp(0, 11);
    return LunarMonth.values[sunSignAtPurnima];
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
