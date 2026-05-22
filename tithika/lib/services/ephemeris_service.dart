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
}
