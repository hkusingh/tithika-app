import '../models/pancha_data.dart';

// Yoga: sum of sidereal sun + moon longitudes, divided into 27 equal parts.
const _yogaDeg    = 360.0 / 27.0;   // ≈ 13.333° per yoga
const _yogaRate   = 0.9856 + 13.176; // °/day: sidereal sun + sidereal moon

// Karana: each karana spans 6° of tropical Moon–Sun elongation.
// Rate matches tithi elongation rate.
const _karanaDeg  = 6.0;
const _karanaRate = 12.19; // °/day (tropical elongation rate)

class PanchaService {
  /// Compute Yoga and Karana for the selected day.
  ///
  /// [sunriseUtc]     — sunrise of the selected date
  /// [nextSunriseUtc] — sunrise of the following date (bounds the karana list)
  /// [sidSunLonDeg]   — sidereal sun longitude at sunrise (for yoga)
  /// [sidMoonLonDeg]  — sidereal moon longitude at sunrise (for yoga)
  /// [tropElongDeg]   — tropical Moon–Sun elongation at sunrise (for karana)
  static PanchaData calculate({
    required DateTime sunriseUtc,
    required DateTime nextSunriseUtc,
    required double sidSunLonDeg,
    required double sidMoonLonDeg,
    required double tropElongDeg,
  }) {
    return PanchaData(
      currentYoga: _currentYoga(sunriseUtc, sidSunLonDeg, sidMoonLonDeg),
      nextYoga:    _nextYoga(sunriseUtc, sidSunLonDeg, sidMoonLonDeg),
      karanas:     _dayKaranas(sunriseUtc, nextSunriseUtc, tropElongDeg),
    );
  }

  // ── Yoga ───────────────────────────────────────────────────────────────────

  static YogaInfo _currentYoga(
      DateTime sunriseUtc, double sidSun, double sidMoon) {
    final sum   = (sidSun + sidMoon) % 360.0;
    final idx   = (sum / _yogaDeg).floor() % 27; // 0-based
    final into  = sum % _yogaDeg;
    final start = sunriseUtc.add(_durationDays(-into / _yogaRate));
    final end   = sunriseUtc.add(_durationDays((_yogaDeg - into) / _yogaRate));
    return YogaInfo(number: idx + 1, start: start, end: end);
  }

  static YogaInfo _nextYoga(
      DateTime sunriseUtc, double sidSun, double sidMoon) {
    final current = _currentYoga(sunriseUtc, sidSun, sidMoon);
    final nextIdx = current.number % 27; // (1..27) → next index 0-based = current.number % 27
    final nextEnd = current.end.add(_durationDays(_yogaDeg / _yogaRate));
    return YogaInfo(number: nextIdx + 1, start: current.end, end: nextEnd);
  }

  // ── Karana ──────────────────────────────────────────────────────────────────

  static List<KaranaInfo> _dayKaranas(
      DateTime sunriseUtc, DateTime nextSunriseUtc, double tropElong) {
    // Current karana seq (0-59) and how far into it we are at sunrise.
    final seq   = (tropElong / _karanaDeg).floor() % 60;
    final into  = tropElong % _karanaDeg;

    // Start of the current karana (may be before sunrise).
    final currentStart = sunriseUtc.add(_durationDays(-into / _karanaRate));

    final result  = <KaranaInfo>[];
    var slotStart = currentStart;
    var slotSeq   = seq;

    // Emit one karana before the current one so the list has visible past context.
    final prevStart = currentStart.add(_durationDays(-_karanaDeg / _karanaRate));
    final prevSeq   = (seq - 1 + 60) % 60;
    result.add(KaranaInfo(
      type:  _karanaType(prevSeq),
      start: prevStart,
      end:   currentStart,
    ));

    // Emit current + upcoming karanas until we've covered next sunrise + buffer.
    final limit = nextSunriseUtc.add(const Duration(hours: 14));
    while (slotStart.isBefore(limit) && result.length < 7) {
      final slotEnd = slotStart.add(_durationDays(_karanaDeg / _karanaRate));
      result.add(KaranaInfo(
        type:  _karanaType(slotSeq),
        start: slotStart,
        end:   slotEnd,
      ));
      slotStart = slotEnd;
      slotSeq   = (slotSeq + 1) % 60;
    }

    return result;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Maps a 0-based karana sequence number (0–59) to its [KaranaType].
  static KaranaType _karanaType(int seq) {
    if (seq == 0) return KaranaType.kimstughna;
    if (seq == 57) return KaranaType.shakuni;
    if (seq == 58) return KaranaType.chatushpada;
    if (seq == 59) return KaranaType.naga;
    // seq 1–56: 7 moveable types cycling
    const moveable = [
      KaranaType.bava,
      KaranaType.balava,
      KaranaType.kaulava,
      KaranaType.taitila,
      KaranaType.gara,
      KaranaType.vanija,
      KaranaType.vishti,
    ];
    return moveable[(seq - 1) % 7];
  }

  static Duration _durationDays(double days) =>
      Duration(microseconds: (days * 86400 * 1000000).round());
}
