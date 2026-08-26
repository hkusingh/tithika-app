/// Abstract interface for the astronomical calculation engine.
/// Backed by SwephEphemerisService (Swiss Ephemeris via sweph package).
/// Swapped out in tests with a deterministic stub.
abstract class EphemerisService {
  /// Must be called once before any calculation method.
  Future<void> initialize();

  /// Julian Day (UT) for a UTC [DateTime].
  double julianDayFromUtc(DateTime utc);

  /// UTC [DateTime] from a Julian Day (UT).
  DateTime utcFromJulianDay(double jd);

  /// Tropical ecliptic longitude of the Sun (0–360°) at [julianDay] (UT).
  double sunLongitude(double julianDay);

  /// Tropical ecliptic longitude of the Moon (0–360°) at [julianDay] (UT).
  double moonLongitude(double julianDay);

  /// Sidereal (Lahiri) ecliptic longitude of the Sun (0–360°).
  double siderealSunLongitude(double julianDay);

  /// Sidereal (Lahiri) ecliptic longitude of the Moon (0–360°).
  double siderealMoonLongitude(double julianDay);

  /// UTC time of sunrise for the calendar date containing [utcMidnight],
  /// at [lat]/[lon] (degrees). Returns null if sun never rises (polar).
  DateTime? sunrise(DateTime utcMidnight, double lat, double lon);

  /// UTC time of sunset for the same date/location. Returns null if sun
  /// never sets.
  DateTime? sunset(DateTime utcMidnight, double lat, double lon);

  /// UTC time of moonrise for the calendar date containing [utcMidnight],
  /// at [lat]/[lon]. Returns null if the moon never rises (polar edge case).
  DateTime? moonrise(DateTime utcMidnight, double lat, double lon);

  /// UTC time of moonset for the same date/location. Returns null if the
  /// moon never sets.
  DateTime? moonset(DateTime utcMidnight, double lat, double lon);

  /// Finds the next solar eclipse (globally, of any type) after [afterUtc].
  /// Returns raw contact/visibility data evaluated for [lat]/[lon]; null if
  /// none is found (should not happen within any realistic search window).
  RawEclipse? nextSolarEclipse(DateTime afterUtc, double lat, double lon);

  /// Finds the next lunar eclipse (globally, of any type) after [afterUtc].
  /// Returns raw contact/visibility data evaluated for [lat]/[lon]; null if
  /// none is found (should not happen within any realistic search window).
  RawEclipse? nextLunarEclipse(DateTime afterUtc, double lat, double lon);
}

/// Raw eclipse contact times and type flags for a single eclipse event,
/// as reported by the ephemeris engine — not yet interpreted into app-level
/// [EclipseSubtype]/visibility semantics (that's [EclipseService]'s job).
class RawEclipse {
  final DateTime maxUtc;
  final DateTime startUtc;
  final DateTime endUtc;
  final bool isTotal;
  final bool isAnnular;
  final bool isPartial;
  final bool isPenumbral;

  /// True if the eclipse is visible (body above horizon) from the location
  /// passed to the search call, at maximum eclipse.
  final bool visibleAtLocation;

  const RawEclipse({
    required this.maxUtc,
    required this.startUtc,
    required this.endUtc,
    required this.isTotal,
    required this.isAnnular,
    required this.isPartial,
    required this.isPenumbral,
    required this.visibleAtLocation,
  });
}
