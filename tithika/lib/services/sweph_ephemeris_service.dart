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
}

/// Loads Flutter asset bytes using [rootBundle].
class _FlutterAssetLoader with AssetLoader {
  @override
  Future<Uint8List> load(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }
}
