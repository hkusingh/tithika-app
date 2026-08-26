import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart';

import 'ephemeris_service.dart';

// Ephemeris asset paths declared in pubspec.yaml
const _epheAssets = [
  'assets/ephemeris/semo_18.se1',
  'assets/ephemeris/sepl_18.se1',
];

// Standard atmosphere — used for sunrise/sunset refraction calculation
const _atPress = 1013.25; // mbar
const _atTemp = 15.0; // °C

// Flags for tropical and sidereal planet positions
final _tropicalFlags = SwephFlag.SEFLG_SWIEPH;
final _siderealFlags = SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SIDEREAL;

class SwephEphemerisService implements EphemerisService {
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    final docsDir = await getApplicationDocumentsDirectory();
    final ephePath = '${docsDir.path}/ephe';
    await Sweph.init(
      epheAssets: _epheAssets,
      assetLoader: _FlutterAssetLoader(),
      epheFilesPath: ephePath,
    );
    // Lahiri ayanamsa — required for nakshatra and sun-sign calculations.
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
    _initialized = true;
  }

  @override
  double julianDayFromUtc(DateTime utc) {
    assert(utc.isUtc, 'julianDayFromUtc requires a UTC DateTime');
    return Sweph.swe_julday(
      utc.year,
      utc.month,
      utc.day,
      utc.hour + utc.minute / 60.0 + utc.second / 3600.0,
      CalendarType.SE_GREG_CAL,
    );
  }

  @override
  DateTime utcFromJulianDay(double jd) {
    return Sweph.swe_jdut1_to_utc(jd, CalendarType.SE_GREG_CAL);
  }

  @override
  double sunLongitude(double julianDay) {
    return Sweph.swe_calc_ut(julianDay, HeavenlyBody.SE_SUN, _tropicalFlags).longitude;
  }

  @override
  double moonLongitude(double julianDay) {
    return Sweph.swe_calc_ut(julianDay, HeavenlyBody.SE_MOON, _tropicalFlags).longitude;
  }

  @override
  double siderealSunLongitude(double julianDay) {
    return Sweph.swe_calc_ut(julianDay, HeavenlyBody.SE_SUN, _siderealFlags).longitude;
  }

  @override
  double siderealMoonLongitude(double julianDay) {
    return Sweph.swe_calc_ut(julianDay, HeavenlyBody.SE_MOON, _siderealFlags).longitude;
  }

  @override
  DateTime? sunrise(DateTime utcMidnight, double lat, double lon) {
    assert(utcMidnight.isUtc);
    final jd = julianDayFromUtc(utcMidnight);
    final resultJd = Sweph.swe_rise_trans(
      jd,
      HeavenlyBody.SE_SUN,
      SwephFlag.SEFLG_SWIEPH,
      RiseSetTransitFlag.SE_CALC_RISE,
      GeoPosition(lon, lat), // sweph: longitude first, latitude second
      _atPress,
      _atTemp,
    );
    return resultJd == null ? null : utcFromJulianDay(resultJd);
  }

  @override
  DateTime? sunset(DateTime utcMidnight, double lat, double lon) {
    assert(utcMidnight.isUtc);
    final jd = julianDayFromUtc(utcMidnight);
    final resultJd = Sweph.swe_rise_trans(
      jd,
      HeavenlyBody.SE_SUN,
      SwephFlag.SEFLG_SWIEPH,
      RiseSetTransitFlag.SE_CALC_SET,
      GeoPosition(lon, lat),
      _atPress,
      _atTemp,
    );
    return resultJd == null ? null : utcFromJulianDay(resultJd);
  }

  @override
  DateTime? moonrise(DateTime utcMidnight, double lat, double lon) {
    assert(utcMidnight.isUtc);
    final jd = julianDayFromUtc(utcMidnight);
    final resultJd = Sweph.swe_rise_trans(
      jd,
      HeavenlyBody.SE_MOON,
      SwephFlag.SEFLG_SWIEPH,
      RiseSetTransitFlag.SE_CALC_RISE,
      GeoPosition(lon, lat),
      _atPress,
      _atTemp,
    );
    return resultJd == null ? null : utcFromJulianDay(resultJd);
  }

  @override
  DateTime? moonset(DateTime utcMidnight, double lat, double lon) {
    assert(utcMidnight.isUtc);
    final jd = julianDayFromUtc(utcMidnight);
    final resultJd = Sweph.swe_rise_trans(
      jd,
      HeavenlyBody.SE_MOON,
      SwephFlag.SEFLG_SWIEPH,
      RiseSetTransitFlag.SE_CALC_SET,
      GeoPosition(lon, lat),
      _atPress,
      _atTemp,
    );
    return resultJd == null ? null : utcFromJulianDay(resultJd);
  }

  @override
  RawEclipse? nextSolarEclipse(DateTime afterUtc, double lat, double lon) {
    assert(afterUtc.isUtc);
    final jd = julianDayFromUtc(afterUtc);
    // Global search first — unlike swe_sol_eclipse_when_loc (which silently
    // SKIPS any eclipse not visible from geoPos), swe_sol_eclipse_when_glob
    // finds every solar eclipse worldwide, so a not-visible-here eclipse is
    // still returned (and reported as such) rather than disappearing.
    final glob = Sweph.swe_sol_eclipse_when_glob(
      jd,
      SwephFlag.SEFLG_SWIEPH,
      EclipseFlag(0), // any type
      false,
    );
    final globTimes = glob.times;
    final globType = glob.eclipseType;
    if (globTimes == null || globType == null) return null;
    final maxJd = globTimes[0];

    // swe_sol_eclipse_how reports the LOCAL type flags and (via
    // SE_ECL_VISIBLE) whether this eclipse is visible from geoPos at
    // maximum. Per its own doc comment, the returned flag is 0 — no
    // SE_ECL_TOTAL/ANNULAR/PARTIAL bits set — when nothing is visible here,
    // so its type is only meaningful when [visible] is true.
    final how = Sweph.swe_sol_eclipse_how(
      maxJd,
      SwephFlag.SEFLG_SWIEPH,
      GeoPosition(lon, lat),
    );
    final howType = how.eclipseType;
    if (howType == null) return null;
    final visible = (howType & EclipseFlag.SE_ECL_VISIBLE).value != 0;
    // When not visible here, fall back to the eclipse's true global type
    // (from the worldwide search) rather than the meaningless local flags —
    // otherwise a not-visible eclipse would be mislabeled "Partial" by
    // default even when it's actually total/annular elsewhere on Earth.
    final type = visible ? howType : globType;

    // Only when visible here can swe_sol_eclipse_when_loc give true local
    // contact times — anchored just before the already-known max so it
    // resolves this same event rather than searching for a different one.
    double startJd = globTimes[2];
    double endJd = globTimes[3];
    if (visible) {
      final loc = Sweph.swe_sol_eclipse_when_loc(
        maxJd - 1.0,
        SwephFlag.SEFLG_SWIEPH,
        GeoPosition(lon, lat),
        false,
      );
      final locTimes = loc.times;
      if (locTimes != null) {
        startJd = locTimes[2];
        endJd = locTimes[3];
      }
    }

    return RawEclipse(
      maxUtc: utcFromJulianDay(maxJd),
      startUtc: utcFromJulianDay(startJd),
      endUtc: utcFromJulianDay(endJd),
      isTotal: (type & EclipseFlag.SE_ECL_TOTAL).value != 0,
      isAnnular: (type & EclipseFlag.SE_ECL_ANNULAR).value != 0,
      isPartial: (type & EclipseFlag.SE_ECL_PARTIAL).value != 0,
      isPenumbral: false,
      visibleAtLocation: visible,
    );
  }

  @override
  RawEclipse? nextLunarEclipse(DateTime afterUtc, double lat, double lon) {
    assert(afterUtc.isUtc);
    final jd = julianDayFromUtc(afterUtc);
    final when = Sweph.swe_lun_eclipse_when(
      jd,
      SwephFlag.SEFLG_SWIEPH,
      EclipseFlag.SE_ECL_ALLTYPES_LUNAR,
      false,
    );
    final times = when.times;
    final type = when.eclipseType;
    if (times == null || type == null) return null;
    // Lunar eclipses are visible from an entire hemisphere, not a narrow
    // path — swe_lun_eclipse_when is global. Visibility at [lat]/[lon] is
    // determined separately via swe_lun_eclipse_how's apparent altitude of
    // the Moon at maximum eclipse (attr[6] > 0 means above horizon).
    final how = Sweph.swe_lun_eclipse_how(
      times[0],
      SwephFlag.SEFLG_SWIEPH,
      GeoPosition(lon, lat),
    );
    final apparentAltitude = how.attributes?[6] ?? -1.0;
    return RawEclipse(
      maxUtc: utcFromJulianDay(times[0]),
      startUtc: utcFromJulianDay(times[2]),
      endUtc: utcFromJulianDay(times[3]),
      isTotal: (type & EclipseFlag.SE_ECL_TOTAL).value != 0,
      isAnnular: false,
      isPartial: (type & EclipseFlag.SE_ECL_PARTIAL).value != 0,
      isPenumbral: (type & EclipseFlag.SE_ECL_PENUMBRAL).value != 0,
      visibleAtLocation: apparentAltitude > 0,
    );
  }
}

/// Loads Flutter asset bytes using [rootBundle].
class _FlutterAssetLoader with AssetLoader {
  @override
  Future<Uint8List> load(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }
}
