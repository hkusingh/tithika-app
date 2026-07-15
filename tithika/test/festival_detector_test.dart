import 'package:flutter_test/flutter_test.dart';
import 'package:tithika/models/day_data.dart';
import 'package:tithika/models/lunar_month.dart';
import 'package:tithika/models/nakshatra_info.dart';
import 'package:tithika/models/paksha.dart';
import 'package:tithika/models/tithi_info.dart';
import 'package:tithika/services/festival_detector.dart';

TithiInfo _tithi(int number, DateTime start, DateTime end) {
  return TithiInfo(
    number: number,
    pakshaNumber: number <= 15 ? number : number - 15,
    paksha: number <= 15 ? Paksha.shukla : Paksha.krishna,
    start: start,
    end: end,
  );
}

DayData _day({
  required LunarMonth lunarMonth,
  required TithiInfo tithi,
  TithiInfo? secondaryTithi,
  bool secondaryIsKshaya = false,
  DateTime? sunriseUtc,
  DateTime? sunsetUtc,
}) {
  return DayData(
    localDate: DateTime(2026, 9, 1),
    tithi: tithi,
    nakshatra: NakshatraInfo(number: 1, end: DateTime.utc(2026, 9, 2)),
    lunarMonth: lunarMonth,
    sunZodiacSign: 4,
    secondaryTithi: secondaryTithi,
    secondaryIsKshaya: secondaryIsKshaya,
    sunriseUtc: sunriseUtc,
    sunsetUtc: sunsetUtc,
  );
}

void main() {
  group('FestivalDetector.detect — vridhi handling', () {
    test(
      'Hartalika Teej (Bhadrapada Shukla Tritiya) is reported when Tritiya is '
      'vridhi (secondaryTithi null) but tomorrow is a DIFFERENT tithi '
      '(Bangalore-style case: this is not actually a two-day vridhi span for '
      'Tritiya itself, so the festival must not be suppressed)',
      () {
        final today = _day(
          lunarMonth: LunarMonth.bhadrapada,
          tithi: _tithi(3, DateTime.utc(2026, 8, 31, 20), DateTime.utc(2026, 9, 2, 3)),
          secondaryTithi: null,
        );
        final tomorrow = _day(
          lunarMonth: LunarMonth.bhadrapada,
          tithi: _tithi(4, DateTime.utc(2026, 9, 2, 3), DateTime.utc(2026, 9, 3, 6)),
          secondaryTithi: null,
        );

        expect(FestivalDetector.detect(today, tomorrow), 'Hartalika Teej');
      },
    );

    test(
      'Hartalika Teej is suppressed on day 1 of a genuine two-day Tritiya '
      'vridhi span (tomorrow is still Tritiya) and appears on day 2 instead',
      () {
        final day1 = _day(
          lunarMonth: LunarMonth.bhadrapada,
          tithi: _tithi(3, DateTime.utc(2026, 8, 31, 20), DateTime.utc(2026, 9, 2, 3)),
          secondaryTithi: null,
        );
        final day2 = _day(
          lunarMonth: LunarMonth.bhadrapada,
          tithi: _tithi(3, DateTime.utc(2026, 8, 31, 20), DateTime.utc(2026, 9, 2, 3)),
          secondaryTithi: _tithi(4, DateTime.utc(2026, 9, 2, 3), DateTime.utc(2026, 9, 3, 6)),
        );

        expect(FestivalDetector.detect(day1, day2), isNull);
        expect(FestivalDetector.detect(day2, null), 'Hartalika Teej');
      },
    );

    test(
      'when tomorrow is unavailable, the festival is reported rather than '
      'silently dropped — callers that care about vridhi correctness should '
      'pass tomorrow explicitly',
      () {
        final today = _day(
          lunarMonth: LunarMonth.bhadrapada,
          tithi: _tithi(3, DateTime.utc(2026, 8, 31, 20), DateTime.utc(2026, 9, 2, 3)),
          secondaryTithi: null,
        );

        expect(FestivalDetector.detect(today), 'Hartalika Teej');
      },
    );

    test('ordinary kshaya secondary tithi festival still detected', () {
      final today = _day(
        lunarMonth: LunarMonth.bhadrapada,
        tithi: _tithi(2, DateTime.utc(2026, 9, 1, 2), DateTime.utc(2026, 9, 1, 20)),
        secondaryTithi: _tithi(3, DateTime.utc(2026, 9, 1, 20), DateTime.utc(2026, 9, 2, 10)),
        secondaryIsKshaya: true,
      );

      expect(FestivalDetector.detect(today), 'Hartalika Teej');
    });
  });

  group('FestivalDetector.detectAll — special-window / sunrise-rule collision', () {
    test(
      'Hartalika Teej (sunrise-rule, primary=Tritiya) and Ganesh Chaturthi '
      '(special-window, Chaturthi active at Madhyahna as secondaryTithi) are '
      'both returned as SEPARATE list entries when they land on the same '
      'calendar day — this is the real Bangalore 2026 case: Tritiya only '
      'ever rules at sunrise on the SAME day Chaturthi spans Madhyahna, so '
      'they must not be merged into a single joined string (that breaks the '
      'per-festival description/detail link)',
      () {
        final sunrise = DateTime.utc(2026, 9, 14, 0, 38);
        final sunset = DateTime.utc(2026, 9, 14, 18, 30);
        final today = _day(
          lunarMonth: LunarMonth.bhadrapada,
          tithi: _tithi(3, DateTime.utc(2026, 9, 12, 20), DateTime.utc(2026, 9, 14, 1, 37)),
          secondaryTithi: _tithi(4, DateTime.utc(2026, 9, 14, 1, 37), DateTime.utc(2026, 9, 15, 2, 14)),
          secondaryIsKshaya: false,
          sunriseUtc: sunrise,
          sunsetUtc: sunset,
        );

        final result = FestivalDetector.detectAll(today);
        expect(result, containsAll(['Hartalika Teej', 'Ganesh Chaturthi']));
        expect(result.length, 2);
        expect(result, isNot(contains('Ganesh Chaturthi / Hartalika Teej')));
      },
    );
  });

  group('DayData.festivalNames / festivalName', () {
    test('copyWith(festivalName:) sets a single-element festivalNames list', () {
      final day = _day(
        lunarMonth: LunarMonth.bhadrapada,
        tithi: _tithi(3, DateTime.utc(2026, 9, 1), DateTime.utc(2026, 9, 2)),
      );
      final withFestival = day.copyWith(festivalName: 'Hartalika Teej');

      expect(withFestival.festivalNames, ['Hartalika Teej']);
      expect(withFestival.festivalName, 'Hartalika Teej');
    });

    test('copyWith(festivalNames:) supports multiple independent names', () {
      final day = _day(
        lunarMonth: LunarMonth.bhadrapada,
        tithi: _tithi(3, DateTime.utc(2026, 9, 1), DateTime.utc(2026, 9, 2)),
      );
      final withFestivals = day.copyWith(
        festivalNames: ['Ganesh Chaturthi', 'Hartalika Teej'],
      );

      expect(withFestivals.festivalNames, ['Ganesh Chaturthi', 'Hartalika Teej']);
      expect(withFestivals.festivalName, 'Ganesh Chaturthi');
    });
  });
}
