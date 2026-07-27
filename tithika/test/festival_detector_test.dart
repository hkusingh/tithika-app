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

  group('FestivalDetector.detect — Purnima Purvahna/Madhyahna exception', () {
    // Real Fremont, CA data for Guru Purnima 2026 (all times PDT, UTC-7):
    //   Jul 28 sunrise 06:08:55, Purnima active 05:49:28 (Jul 28) – 07:35:43 (Jul 29)
    //   Jul 29 sunrise 06:09:44, Purnima still ruling at sunrise but ends before Madhyahna
    // Generic vruddhi-last-day logic would (incorrectly) suppress Jul 28 and
    // report Jul 29 instead. Purnima must follow the Madhyahna-prevails rule:
    // observed on Jul 28, since Purnima has already ended by Jul 29's Madhyahna.
    test(
      'Guru Purnima is reported on the FIRST day of a two-day Purnima span '
      'when Purnima does not survive to the second day\'s Madhyahna',
      () {
        final jul28 = _day(
          lunarMonth: LunarMonth.ashadha,
          tithi: _tithi(15, DateTime.utc(2026, 7, 28, 12, 49, 28),
              DateTime.utc(2026, 7, 29, 14, 35, 43)),
          secondaryTithi: null,
          sunriseUtc: DateTime.utc(2026, 7, 28, 13, 8, 55),
          sunsetUtc: DateTime.utc(2026, 7, 29, 3, 30),
        );
        final jul29 = _day(
          lunarMonth: LunarMonth.ashadha,
          tithi: _tithi(15, DateTime.utc(2026, 7, 28, 12, 49, 28),
              DateTime.utc(2026, 7, 29, 14, 35, 43)),
          secondaryTithi: _tithi(16, DateTime.utc(2026, 7, 29, 14, 35, 43),
              DateTime.utc(2026, 7, 30, 16, 0, 48)),
          sunriseUtc: DateTime.utc(2026, 7, 29, 13, 9, 44),
          sunsetUtc: DateTime.utc(2026, 7, 30, 3, 31),
        );

        expect(FestivalDetector.detect(jul28, jul29), 'Guru Purnima');
        expect(FestivalDetector.detect(jul29, null), isNull);
      },
    );

    test(
      'Purnima with no vruddhi (starts after day 1 sunrise, so day 1 is '
      "still tithi 14) is reported on day 2, when it becomes day 2's sunrise "
      'tithi and survives to Madhyahna',
      () {
        final day1 = _day(
          lunarMonth: LunarMonth.ashadha,
          tithi: _tithi(14, DateTime.utc(2026, 7, 27, 14), DateTime.utc(2026, 7, 28, 16)),
          secondaryTithi: _tithi(15, DateTime.utc(2026, 7, 28, 16), DateTime.utc(2026, 7, 29, 22)),
          secondaryIsKshaya: false,
          sunriseUtc: DateTime.utc(2026, 7, 28, 13),
          sunsetUtc: DateTime.utc(2026, 7, 29, 3),
        );
        final day2 = _day(
          lunarMonth: LunarMonth.ashadha,
          tithi: _tithi(15, DateTime.utc(2026, 7, 28, 16), DateTime.utc(2026, 7, 29, 22)),
          secondaryTithi: null,
          sunriseUtc: DateTime.utc(2026, 7, 29, 13),
          sunsetUtc: DateTime.utc(2026, 7, 30, 3),
        );

        expect(FestivalDetector.detect(day1, day2), isNull);
        expect(FestivalDetector.detect(day2, null), 'Guru Purnima');
      },
    );
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
