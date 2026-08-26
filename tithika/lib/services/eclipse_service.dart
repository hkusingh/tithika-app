import '../models/app_location.dart';
import '../models/eclipse_info.dart';
import 'ephemeris_service.dart';

const _sutakBeforeSolar = Duration(hours: 12);
const _sutakBeforeLunar = Duration(hours: 9);

// Safety cap so a search bug (e.g. an ephemeris gap) can't spin forever.
const _maxEclipsesPerYear = 8;

class EclipseService {
  final EphemerisService _ephe;

  EclipseService(this._ephe);

  /// All solar and lunar eclipses with maximum eclipse falling within
  /// [year] (Jan 1 00:00 UTC – Dec 31 23:59:59 UTC), evaluated for
  /// visibility/contact-times at [location]. Chronologically sorted.
  List<EclipseInfo> eclipsesForYear(int year, AppLocation location) {
    final result = <EclipseInfo>[];
    result.addAll(_walk(
      year: year,
      location: location,
      search: _ephe.nextSolarEclipse,
      kind: EclipseKind.solar,
    ));
    result.addAll(_walk(
      year: year,
      location: location,
      search: _ephe.nextLunarEclipse,
      kind: EclipseKind.lunar,
    ));
    result.sort((a, b) => a.maxUtc.compareTo(b.maxUtc));
    return result;
  }

  List<EclipseInfo> _walk({
    required int year,
    required AppLocation location,
    required RawEclipse? Function(DateTime afterUtc, double lat, double lon) search,
    required EclipseKind kind,
  }) {
    final yearStart = DateTime.utc(year);
    final yearEnd = DateTime.utc(year + 1);
    final found = <EclipseInfo>[];

    // Start the search a bit before the year boundary so an eclipse whose
    // max eclipse is very early on Jan 1 (search returns "next after")
    // isn't missed by starting exactly at yearStart.
    var cursor = yearStart.subtract(const Duration(days: 40));
    for (var i = 0; i < _maxEclipsesPerYear; i++) {
      final raw = search(cursor, location.lat, location.lon);
      if (raw == null) break;
      if (!raw.maxUtc.isBefore(yearEnd)) break;
      if (!raw.maxUtc.isBefore(yearStart)) {
        found.add(_toEclipseInfo(raw, kind, location));
      }
      // Advance past this eclipse's end so the next search call finds a
      // genuinely different event.
      cursor = raw.endUtc.add(const Duration(days: 1));
    }
    return found;
  }

  EclipseInfo _toEclipseInfo(RawEclipse raw, EclipseKind kind, AppLocation location) {
    final subtype = switch (kind) {
      EclipseKind.solar => raw.isTotal
          ? EclipseSubtype.total
          : raw.isAnnular
              ? EclipseSubtype.annular
              : EclipseSubtype.partial,
      EclipseKind.lunar => raw.isTotal
          ? EclipseSubtype.total
          : raw.isPartial
              ? EclipseSubtype.partial
              : EclipseSubtype.penumbral,
    };
    final sutakBefore = kind == EclipseKind.solar ? _sutakBeforeSolar : _sutakBeforeLunar;
    // tzOffsetAt expects a local calendar date, not a UTC instant. Resolve it
    // in two passes: an approximate offset (from the fixed fallback, always
    // within a day of correct) locates the right calendar date, which is
    // then used to re-query the precise DST-aware offset for that date.
    final approxLocal = raw.maxUtc.add(Duration(minutes: location.tzOffsetMinutes));
    final approxLocalDate = DateTime(approxLocal.year, approxLocal.month, approxLocal.day);
    final tzOffset = location.tzOffsetAt(approxLocalDate);
    final localMax = raw.maxUtc.add(tzOffset);
    return EclipseInfo(
      kind: kind,
      subtype: subtype,
      maxUtc: raw.maxUtc,
      startUtc: raw.startUtc,
      endUtc: raw.endUtc,
      visible: raw.visibleAtLocation,
      sutakStartUtc: raw.visibleAtLocation ? raw.startUtc.subtract(sutakBefore) : null,
      localDate: DateTime(localMax.year, localMax.month, localMax.day),
    );
  }
}
