import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:tithika/models/app_settings.dart';
import 'package:tithika/models/day_data.dart';
import 'package:tithika/models/lunar_month.dart';
import 'package:tithika/models/nakshatra_info.dart';
import 'package:tithika/models/paksha.dart';
import 'package:tithika/models/special_tithi.dart';
import 'package:tithika/models/tithi_info.dart';
import 'package:tithika/services/notification_service.dart';

/// Mirrors TithiService._specialTithi — [TithiInfo.special] is assigned by
/// the service rather than derived on the model, so fixtures must set it.
SpecialTithi? _specialFor(int number) => switch (number) {
      11 || 26 => SpecialTithi.ekadashi,
      15 => SpecialTithi.purnima,
      30 => SpecialTithi.amavasya,
      4 => SpecialTithi.vinayakaChaturthi,
      19 => SpecialTithi.sankashtiChaturthi,
      13 || 28 => SpecialTithi.pradosh,
      _ => null,
    };

TithiInfo _tithi(int number, DateTime start, DateTime end) {
  return TithiInfo(
    number: number,
    pakshaNumber: number <= 15 ? number : number - 15,
    paksha: number <= 15 ? Paksha.shukla : Paksha.krishna,
    start: start,
    end: end,
    special: _specialFor(number),
  );
}

/// An ordinary day carrying [tithiNumber], with sunrise/sunset set so the
/// Madhyahna checks in FestivalDetector have something to work with.
DayData _day(
  DateTime date, {
  required int tithiNumber,
  required LunarMonth lunarMonth,
  TithiInfo? secondaryTithi,
  bool secondaryIsKshaya = false,
}) {
  final sunrise = DateTime.utc(date.year, date.month, date.day, 1, 0);
  final sunset = DateTime.utc(date.year, date.month, date.day, 13, 0);
  return DayData(
    localDate: date,
    // Starts before sunrise and ends after sunset: rules the whole day, so
    // it is neither vruddhi (secondaryTithi below decides that) nor kshaya.
    tithi: _tithi(
      tithiNumber,
      sunrise.subtract(const Duration(hours: 3)),
      sunset.add(const Duration(hours: 3)),
    ),
    nakshatra: NakshatraInfo(number: 1, end: date.add(const Duration(days: 1))),
    lunarMonth: lunarMonth,
    sunZodiacSign: 4,
    secondaryTithi: secondaryTithi ??
        _tithi(
          tithiNumber + 1,
          sunset.add(const Duration(hours: 3)),
          sunset.add(const Duration(hours: 9)),
        ),
    secondaryIsKshaya: secondaryIsKshaya,
    sunriseUtc: sunrise,
    sunsetUtc: sunset,
  );
}

void main() {
  tzdata.initializeTimeZones();
  final kolkata = tz.getLocation('Asia/Kolkata');
  final newYork = tz.getLocation('America/New_York');

  // A fixed "now" well before any scheduled alert, so nothing is skipped for
  // being in the past.
  final today = DateTime(2026, 3, 1);
  final now = tz.TZDateTime(kolkata, 2026, 3, 1, 0, 1);

  /// Every day is an ordinary Chaitra day with no festival, unless overridden.
  DayDataLookup plainDays({Map<int, DayData> overrides = const {}}) {
    return (date) {
      final offset = date.difference(today).inDays;
      return overrides[offset] ??
          _day(date, tithiNumber: 7, lunarMonth: LunarMonth.chaitra);
    };
  }

  group('notifiesFor / noFestivalAlerts', () {
    test('master on notifies for any festival, selected or not', () {
      const s = NotificationSettings(
        enabled: true,
        festivalAlertsEnabled: true,
        selectedFestivals: {'Holi'},
      );
      expect(s.notifiesFor('Holi'), isTrue);
      expect(s.notifiesFor('Diwali'), isTrue);
      expect(s.noFestivalAlerts, isFalse);
    });

    test('master off notifies only for selected festivals', () {
      const s = NotificationSettings(
        enabled: true,
        festivalAlertsEnabled: false,
        selectedFestivals: {'Holi'},
      );
      expect(s.notifiesFor('Holi'), isTrue);
      expect(s.notifiesFor('Diwali'), isFalse);
      expect(s.noFestivalAlerts, isFalse);
    });

    test('noFestivalAlerts only when master off AND nothing selected', () {
      const off = NotificationSettings(
          enabled: true, festivalAlertsEnabled: false);
      expect(off.noFestivalAlerts, isTrue);
      expect(off.notifiesFor('Holi'), isFalse);
    });

    test('master on/off round trip preserves the selection', () {
      const start = NotificationSettings(
        enabled: true,
        festivalAlertsEnabled: false,
        selectedFestivals: {'Holi', 'Diwali'},
      );
      final on = start.copyWith(festivalAlertsEnabled: true);
      final backOff = on.copyWith(festivalAlertsEnabled: false);
      expect(backOff.selectedFestivals, {'Holi', 'Diwali'});
      expect(backOff.notifiesFor('Holi'), isTrue);
    });
  });

  group('alert fire time', () {
    // Ram Navami 2026 — Chaitra Shukla Navami (tithi 9).
    DayDataLookup withFestivalOnDay(int offset) => plainDays(overrides: {
          offset: _day(today.add(Duration(days: offset)),
              tithiNumber: 9, lunarMonth: LunarMonth.chaitra),
        });

    test('fires at the configured time, the configured number of days before',
        () {
      for (final daysBefore in [0, 1, 2, 3]) {
        final plan = planObservanceAlerts(
          settings: NotificationSettings(
            enabled: true,
            alertDaysBefore: daysBefore,
            alertHour: 6,
            alertMinute: 30,
            ekadashiAlertsEnabled: false,
            purnimaAlertsEnabled: false,
            amavasyaAlertsEnabled: false,
          ),
          dayData: withFestivalOnDay(5),
          tzLocation: kolkata,
          now: now,
          today: today,
        );

        expect(plan, hasLength(1), reason: 'daysBefore=$daysBefore');
        final fire = plan.single.fireTime;
        // Event is on day +5; the alert fires daysBefore earlier at 6:30.
        expect(fire.year, 2026);
        expect(fire.month, 3);
        expect(fire.day, 6 - daysBefore);
        expect(fire.hour, 6);
        expect(fire.minute, 30);
      }
    });

    test('title reflects the offset', () {
      String titleFor(int daysBefore) => planObservanceAlerts(
            settings: NotificationSettings(
              enabled: true,
              alertDaysBefore: daysBefore,
              ekadashiAlertsEnabled: false,
              purnimaAlertsEnabled: false,
              amavasyaAlertsEnabled: false,
            ),
            dayData: withFestivalOnDay(5),
            tzLocation: kolkata,
            now: now,
            today: today,
          ).single.title;

      expect(titleFor(0), 'Ram Navami today');
      expect(titleFor(1), 'Ram Navami tomorrow');
      expect(titleFor(2), 'Ram Navami in 2 days');
      expect(titleFor(3), 'Ram Navami in 3 days');
    });

    test('holds the wall-clock time across a US DST transition', () {
      // US DST began 2026-03-08. An event on Mar 9 alerting 1 day before
      // lands on Mar 8 — the day the clocks jump forward.
      final marchToday = DateTime(2026, 3, 5);
      final plan = planObservanceAlerts(
        settings: const NotificationSettings(
          enabled: true,
          alertDaysBefore: 1,
          alertHour: 6,
          alertMinute: 0,
          ekadashiAlertsEnabled: false,
          purnimaAlertsEnabled: false,
          amavasyaAlertsEnabled: false,
        ),
        dayData: (date) => date.day == 9
            ? _day(date, tithiNumber: 9, lunarMonth: LunarMonth.chaitra)
            : _day(date, tithiNumber: 7, lunarMonth: LunarMonth.chaitra),
        tzLocation: newYork,
        now: tz.TZDateTime(newYork, 2026, 3, 5),
        today: marchToday,
      );

      expect(plan, hasLength(1));
      // Still 6 AM local on Mar 8, not 5 or 7 — the offset is applied to the
      // event day's midnight rather than to an absolute instant.
      expect(plan.single.fireTime.day, 8);
      expect(plan.single.fireTime.hour, 6);
    });
  });

  group('festival filtering', () {
    // Two festivals in the window: Ram Navami (+2) and Hanuman Jayanti (+4).
    DayDataLookup twoFestivals() => plainDays(overrides: {
          2: _day(today.add(const Duration(days: 2)),
              tithiNumber: 9, lunarMonth: LunarMonth.chaitra),
          4: _day(today.add(const Duration(days: 4)),
              tithiNumber: 15, lunarMonth: LunarMonth.chaitra),
        });

    List<String> titlesFor(NotificationSettings s) => planObservanceAlerts(
          settings: s,
          dayData: twoFestivals(),
          tzLocation: kolkata,
          now: now,
          today: today,
        ).map((a) => a.title).toList();

    test('master on schedules every festival', () {
      final titles = titlesFor(const NotificationSettings(
        enabled: true,
        festivalAlertsEnabled: true,
        ekadashiAlertsEnabled: false,
        purnimaAlertsEnabled: false,
        amavasyaAlertsEnabled: false,
      ));
      expect(titles, containsAll(['Ram Navami tomorrow', 'Hanuman Jayanti tomorrow']));
    });

    test('master off schedules only the selected festival', () {
      final titles = titlesFor(const NotificationSettings(
        enabled: true,
        festivalAlertsEnabled: false,
        selectedFestivals: {'Ram Navami'},
        ekadashiAlertsEnabled: false,
        purnimaAlertsEnabled: false,
        amavasyaAlertsEnabled: false,
      ));
      expect(titles, ['Ram Navami tomorrow']);
    });

    test('master off with nothing selected schedules no festivals', () {
      final titles = titlesFor(const NotificationSettings(
        enabled: true,
        festivalAlertsEnabled: false,
        ekadashiAlertsEnabled: false,
        purnimaAlertsEnabled: false,
        amavasyaAlertsEnabled: false,
      ));
      expect(titles, isEmpty);
    });
  });

  group('category independence', () {
    test('festival selection does not affect Ekadashi alerts', () {
      // Ekadashi (tithi 11) on day +3, with no named festival.
      final plan = planObservanceAlerts(
        settings: const NotificationSettings(
          enabled: true,
          festivalAlertsEnabled: false, // master off, nothing selected
          ekadashiAlertsEnabled: true,
          purnimaAlertsEnabled: false,
          amavasyaAlertsEnabled: false,
        ),
        dayData: plainDays(overrides: {
          3: _day(today.add(const Duration(days: 3)),
              tithiNumber: 11, lunarMonth: LunarMonth.chaitra),
        }),
        tzLocation: kolkata,
        now: now,
        today: today,
      );

      expect(plan.map((a) => a.title), ['Ekadashi tomorrow']);
    });

    test('Purnima and Amavasya fire independently of the master switch', () {
      final plan = planObservanceAlerts(
        settings: const NotificationSettings(
          enabled: true,
          festivalAlertsEnabled: false,
          ekadashiAlertsEnabled: false,
          purnimaAlertsEnabled: true,
          amavasyaAlertsEnabled: true,
        ),
        dayData: plainDays(overrides: {
          // Vaishakha Purnima is Buddha Purnima, a named festival; use
          // Jyeshtha so the day carries no festival name of its own.
          2: _day(today.add(const Duration(days: 2)),
              tithiNumber: 15, lunarMonth: LunarMonth.jyeshtha),
          5: _day(today.add(const Duration(days: 5)),
              tithiNumber: 30, lunarMonth: LunarMonth.jyeshtha),
        }),
        tzLocation: kolkata,
        now: now,
        today: today,
      );

      expect(plan.map((a) => a.title),
          containsAll(['Purnima tomorrow', 'Amavasya tomorrow']));
    });
  });

  group('overlap suppression', () {
    test('a subscribed named festival suppresses the generic Purnima alert',
        () {
      // Kartika Purnima (tithi 15) — a named festival AND a Purnima.
      final plan = planObservanceAlerts(
        settings: const NotificationSettings(
          enabled: true,
          festivalAlertsEnabled: true,
          ekadashiAlertsEnabled: false,
          purnimaAlertsEnabled: true,
          amavasyaAlertsEnabled: false,
        ),
        dayData: plainDays(overrides: {
          3: _day(today.add(const Duration(days: 3)),
              tithiNumber: 15, lunarMonth: LunarMonth.kartika),
        }),
        tzLocation: kolkata,
        now: now,
        today: today,
      );

      final titles = plan.map((a) => a.title).toList();
      expect(titles, ['Kartik Purnima tomorrow']);
      expect(titles, isNot(contains('Purnima tomorrow')));
    });

    test('an unsubscribed festival still lets the Purnima alert through', () {
      // Same day, but the user did not bell Kartik Purnima. They asked for
      // Purnima reminders, so the generic alert is still correct.
      final plan = planObservanceAlerts(
        settings: const NotificationSettings(
          enabled: true,
          festivalAlertsEnabled: false,
          selectedFestivals: {'Holi'},
          ekadashiAlertsEnabled: false,
          purnimaAlertsEnabled: true,
          amavasyaAlertsEnabled: false,
        ),
        dayData: plainDays(overrides: {
          3: _day(today.add(const Duration(days: 3)),
              tithiNumber: 15, lunarMonth: LunarMonth.kartika),
        }),
        tzLocation: kolkata,
        now: now,
        today: today,
      );

      expect(plan.map((a) => a.title), ['Purnima tomorrow']);
    });
  });

  group('scheduling window', () {
    test('extends the lookahead so a day +7 event still alerts at offset 3',
        () {
      final plan = planObservanceAlerts(
        settings: const NotificationSettings(
          enabled: true,
          alertDaysBefore: 3,
          festivalAlertsEnabled: true,
          ekadashiAlertsEnabled: false,
          purnimaAlertsEnabled: false,
          amavasyaAlertsEnabled: false,
        ),
        dayData: plainDays(overrides: {
          7: _day(today.add(const Duration(days: 7)),
              tithiNumber: 9, lunarMonth: LunarMonth.chaitra),
        }),
        tzLocation: kolkata,
        now: now,
        today: today,
      );

      expect(plan, hasLength(1));
      expect(plan.single.fireTime.day, 5); // Mar 8 event − 3 days
    });

    test('skips alerts whose fire time has already passed', () {
      // Event tomorrow, alerting 1 day before at 06:00 — i.e. today at 06:00,
      // which is already behind a "now" of 08:00.
      final plan = planObservanceAlerts(
        settings: const NotificationSettings(
          enabled: true,
          alertDaysBefore: 1,
          alertHour: 6,
          festivalAlertsEnabled: true,
          ekadashiAlertsEnabled: false,
          purnimaAlertsEnabled: false,
          amavasyaAlertsEnabled: false,
        ),
        dayData: plainDays(overrides: {
          1: _day(today.add(const Duration(days: 1)),
              tithiNumber: 9, lunarMonth: LunarMonth.chaitra),
        }),
        tzLocation: kolkata,
        now: tz.TZDateTime(kolkata, 2026, 3, 1, 8, 0),
        today: today,
      );

      expect(plan, isEmpty);
    });

    test('allocates ids from the documented per-category ranges', () {
      final plan = planObservanceAlerts(
        settings: const NotificationSettings(
          enabled: true,
          festivalAlertsEnabled: true,
          ekadashiAlertsEnabled: true,
          purnimaAlertsEnabled: true,
          amavasyaAlertsEnabled: true,
        ),
        dayData: plainDays(overrides: {
          1: _day(today.add(const Duration(days: 1)),
              tithiNumber: 9, lunarMonth: LunarMonth.chaitra),
          2: _day(today.add(const Duration(days: 2)),
              tithiNumber: 11, lunarMonth: LunarMonth.chaitra),
          3: _day(today.add(const Duration(days: 3)),
              tithiNumber: 15, lunarMonth: LunarMonth.jyeshtha),
          4: _day(today.add(const Duration(days: 4)),
              tithiNumber: 30, lunarMonth: LunarMonth.jyeshtha),
        }),
        tzLocation: kolkata,
        now: now,
        today: today,
      );

      int idOf(String title) =>
          plan.firstWhere((a) => a.title == title).id;

      expect(idOf('Ram Navami tomorrow'), inInclusiveRange(100, 139));
      expect(idOf('Ekadashi tomorrow'), inInclusiveRange(200, 209));
      expect(idOf('Purnima tomorrow'), inInclusiveRange(300, 309));
      expect(idOf('Amavasya tomorrow'), inInclusiveRange(310, 319));

      // Every id distinct — a collision would silently overwrite an alert.
      final ids = plan.map((a) => a.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });
  });
}
