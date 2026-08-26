import 'package:flutter_test/flutter_test.dart';
import 'package:tithika/models/app_location.dart';
import 'package:tithika/models/eclipse_info.dart';
import 'package:tithika/services/eclipse_service.dart';
import 'package:tithika/services/ephemeris_service.dart';

const _ujjain = AppLocation(
  lat: 23.18,
  lon: 75.78,
  cityName: 'Ujjain',
  country: 'IN',
  tzOffsetMinutes: 330,
  tzId: 'Asia/Kolkata',
);

/// A fixed, chronologically-ordered list of real-world eclipse events for a
/// single kind (solar or lunar). [search] returns the first entry whose
/// [RawEclipse.maxUtc] is after [afterUtc], mimicking Swiss Ephemeris's
/// "find next event" semantics.
class _FixedEclipseSearch {
  final List<RawEclipse> events;
  _FixedEclipseSearch(this.events);

  RawEclipse? call(DateTime afterUtc, double lat, double lon) {
    for (final e in events) {
      if (e.maxUtc.isAfter(afterUtc)) return e;
    }
    return null;
  }
}

class _StubEphemeris implements EphemerisService {
  final _FixedEclipseSearch solar;
  final _FixedEclipseSearch lunar;

  _StubEphemeris({required this.solar, required this.lunar});

  @override
  Future<void> initialize() async {}
  @override
  double julianDayFromUtc(DateTime utc) => 0;
  @override
  DateTime utcFromJulianDay(double jd) => DateTime.utc(2026);
  @override
  double sunLongitude(double julianDay) => 0;
  @override
  double moonLongitude(double julianDay) => 0;
  @override
  double siderealSunLongitude(double julianDay) => 0;
  @override
  double siderealMoonLongitude(double julianDay) => 0;
  @override
  DateTime? sunrise(DateTime utcMidnight, double lat, double lon) => null;
  @override
  DateTime? sunset(DateTime utcMidnight, double lat, double lon) => null;
  @override
  DateTime? moonrise(DateTime utcMidnight, double lat, double lon) => null;
  @override
  DateTime? moonset(DateTime utcMidnight, double lat, double lon) => null;

  @override
  RawEclipse? nextSolarEclipse(DateTime afterUtc, double lat, double lon) =>
      solar(afterUtc, lat, lon);

  @override
  RawEclipse? nextLunarEclipse(DateTime afterUtc, double lat, double lon) =>
      lunar(afterUtc, lat, lon);
}

void main() {
  group('EclipseService.eclipsesForYear', () {
    // Real-world 2026 eclipses:
    //   Feb 17, 2026 — annular solar eclipse (path over Antarctica/S. Atlantic;
    //     not visible from Ujjain, India).
    //   Mar 3, 2026 — total lunar eclipse (visible across Asia, including India).
    //   Aug 12, 2026 — total solar eclipse (path over Greenland/Iceland/Spain;
    //     not visible from Ujjain).
    //   Aug 28, 2026 — partial lunar eclipse (visible from the Americas/Pacific;
    //     not visible from Ujjain, which is on the other side of the globe at
    //     that hour).
    final febSolar = RawEclipse(
      maxUtc: DateTime.utc(2026, 2, 17, 12, 13),
      startUtc: DateTime.utc(2026, 2, 17, 10, 59),
      endUtc: DateTime.utc(2026, 2, 17, 13, 27),
      isTotal: false,
      isAnnular: true,
      isPartial: false,
      isPenumbral: false,
      visibleAtLocation: false,
    );
    final augSolar = RawEclipse(
      maxUtc: DateTime.utc(2026, 8, 12, 17, 46),
      startUtc: DateTime.utc(2026, 8, 12, 15, 5),
      endUtc: DateTime.utc(2026, 8, 12, 20, 27),
      isTotal: true,
      isAnnular: false,
      isPartial: false,
      isPenumbral: false,
      visibleAtLocation: false,
    );
    final marLunar = RawEclipse(
      maxUtc: DateTime.utc(2026, 3, 3, 11, 33),
      startUtc: DateTime.utc(2026, 3, 3, 9, 49),
      endUtc: DateTime.utc(2026, 3, 3, 13, 17),
      isTotal: true,
      isAnnular: false,
      isPartial: false,
      isPenumbral: false,
      visibleAtLocation: true,
    );
    final augLunar = RawEclipse(
      maxUtc: DateTime.utc(2026, 8, 28, 4, 13),
      startUtc: DateTime.utc(2026, 8, 28, 2, 47),
      endUtc: DateTime.utc(2026, 8, 28, 5, 39),
      isTotal: false,
      isAnnular: false,
      isPartial: true,
      isPenumbral: true,
      visibleAtLocation: false,
    );

    EclipseService buildService() => EclipseService(_StubEphemeris(
          solar: _FixedEclipseSearch([febSolar, augSolar]),
          lunar: _FixedEclipseSearch([marLunar, augLunar]),
        ));

    test('returns all four 2026 eclipses, chronologically sorted', () {
      final result = buildService().eclipsesForYear(2026, _ujjain);
      expect(result.length, 4);
      expect(result[0].maxUtc, febSolar.maxUtc);
      expect(result[1].maxUtc, marLunar.maxUtc);
      expect(result[2].maxUtc, augSolar.maxUtc);
      expect(result[3].maxUtc, augLunar.maxUtc);
    });

    test('classifies solar subtypes correctly (annular / total)', () {
      final result = buildService().eclipsesForYear(2026, _ujjain);
      final feb = result.firstWhere((e) => e.maxUtc == febSolar.maxUtc);
      final aug = result.firstWhere((e) => e.maxUtc == augSolar.maxUtc);
      expect(feb.kind, EclipseKind.solar);
      expect(feb.subtype, EclipseSubtype.annular);
      expect(aug.kind, EclipseKind.solar);
      expect(aug.subtype, EclipseSubtype.total);
    });

    test('classifies lunar subtypes correctly (total / partial)', () {
      final result = buildService().eclipsesForYear(2026, _ujjain);
      final mar = result.firstWhere((e) => e.maxUtc == marLunar.maxUtc);
      final aug = result.firstWhere((e) => e.maxUtc == augLunar.maxUtc);
      expect(mar.kind, EclipseKind.lunar);
      expect(mar.subtype, EclipseSubtype.total);
      expect(aug.kind, EclipseKind.lunar);
      expect(aug.subtype, EclipseSubtype.partial);
    });

    test('visibility flag is passed through from the ephemeris layer', () {
      final result = buildService().eclipsesForYear(2026, _ujjain);
      final feb = result.firstWhere((e) => e.maxUtc == febSolar.maxUtc);
      final mar = result.firstWhere((e) => e.maxUtc == marLunar.maxUtc);
      expect(feb.visible, isFalse);
      expect(mar.visible, isTrue);
    });

    test(
      'Sutak start is 12h before solar eclipse start, only when visible',
      () {
        final result = buildService().eclipsesForYear(2026, _ujjain);
        final feb = result.firstWhere((e) => e.maxUtc == febSolar.maxUtc);
        // Not visible from Ujjain — no Sutak.
        expect(feb.sutakStartUtc, isNull);
      },
    );

    test(
      'Sutak start is 9h before lunar eclipse start, only when visible',
      () {
        final result = buildService().eclipsesForYear(2026, _ujjain);
        final mar = result.firstWhere((e) => e.maxUtc == marLunar.maxUtc);
        expect(mar.sutakStartUtc, marLunar.startUtc.subtract(const Duration(hours: 9)));

        final aug = result.firstWhere((e) => e.maxUtc == augLunar.maxUtc);
        // Not visible from Ujjain — no Sutak.
        expect(aug.sutakStartUtc, isNull);
      },
    );

    test('localDate reflects the location timezone, not raw UTC date', () {
      final result = buildService().eclipsesForYear(2026, _ujjain);
      final mar = result.firstWhere((e) => e.maxUtc == marLunar.maxUtc);
      // maxUtc 11:33 UTC + 5:30 IST = 17:03 IST, same calendar day.
      expect(mar.localDate, DateTime(2026, 3, 3));
    });

    test('eclipses outside the requested year are excluded', () {
      final result = buildService().eclipsesForYear(2025, _ujjain);
      expect(result, isEmpty);
    });
  });
}
