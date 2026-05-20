import 'package:flutter_test/flutter_test.dart';
import 'package:tithika/models/hora_data.dart';
import 'package:tithika/services/hora_service.dart';

void main() {
  // Reference day: Wednesday 2025-03-12, Mumbai-ish sunrise/sunset times (UTC).
  // First day hora on Wednesday must be Mercury (index 2 in sequence).
  final sunrise = DateTime.utc(2025, 3, 12, 1, 5); // 06:35 IST
  final sunset  = DateTime.utc(2025, 3, 12, 13, 5); // 18:35 IST
  final nextSunrise = DateTime.utc(2025, 3, 13, 1, 4);

  group('HoraService.calculate', () {
    test('returns exactly 24 slots', () {
      final slots = HoraService.calculate(
        sunriseUtc: sunrise,
        sunsetUtc: sunset,
        nextSunriseUtc: nextSunrise,
        weekday: DateTime(2025, 3, 12).weekday, // Wednesday = 3
      );
      expect(slots.length, 24);
    });

    test('first 12 slots are isDay=true, last 12 are isDay=false', () {
      final slots = HoraService.calculate(
        sunriseUtc: sunrise,
        sunsetUtc: sunset,
        nextSunriseUtc: nextSunrise,
        weekday: 3,
      );
      expect(slots.take(12).every((s) => s.isDay), isTrue);
      expect(slots.skip(12).every((s) => !s.isDay), isTrue);
    });

    test('Wednesday first hora is Mercury', () {
      final slots = HoraService.calculate(
        sunriseUtc: sunrise,
        sunsetUtc: sunset,
        nextSunriseUtc: nextSunrise,
        weekday: 3, // Wednesday
      );
      expect(slots.first.planet, HoraPlanet.mercury);
    });

    test('Sunday first hora is Sun', () {
      final slots = HoraService.calculate(
        sunriseUtc: sunrise,
        sunsetUtc: sunset,
        nextSunriseUtc: nextSunrise,
        weekday: 7, // DateTime.weekday Sunday = 7
      );
      expect(slots.first.planet, HoraPlanet.sun);
    });

    test('Monday first hora is Moon', () {
      final slots = HoraService.calculate(
        sunriseUtc: sunrise,
        sunsetUtc: sunset,
        nextSunriseUtc: nextSunrise,
        weekday: 1, // Monday
      );
      expect(slots.first.planet, HoraPlanet.moon);
    });

    test('Saturday first hora is Saturn', () {
      final slots = HoraService.calculate(
        sunriseUtc: sunrise,
        sunsetUtc: sunset,
        nextSunriseUtc: nextSunrise,
        weekday: 6, // Saturday
      );
      expect(slots.first.planet, HoraPlanet.saturn);
    });

    test('slots cover full day — first.start == sunrise', () {
      final slots = HoraService.calculate(
        sunriseUtc: sunrise,
        sunsetUtc: sunset,
        nextSunriseUtc: nextSunrise,
        weekday: 3,
      );
      expect(slots.first.start, sunrise);
    });

    test('slots cover full day — last.end == nextSunrise', () {
      final slots = HoraService.calculate(
        sunriseUtc: sunrise,
        sunsetUtc: sunset,
        nextSunriseUtc: nextSunrise,
        weekday: 3,
      );
      expect(slots.last.end, nextSunrise);
    });

    test('day/night boundary: slot 11 ends at sunset, slot 12 starts at sunset', () {
      final slots = HoraService.calculate(
        sunriseUtc: sunrise,
        sunsetUtc: sunset,
        nextSunriseUtc: nextSunrise,
        weekday: 3,
      );
      expect(slots[11].end, sunset);
      expect(slots[12].start, sunset);
    });

    test('consecutive slots are contiguous', () {
      final slots = HoraService.calculate(
        sunriseUtc: sunrise,
        sunsetUtc: sunset,
        nextSunriseUtc: nextSunrise,
        weekday: 3,
      );
      for (var i = 0; i < slots.length - 1; i++) {
        expect(
          slots[i].end,
          slots[i + 1].start,
          reason: 'slot $i end must equal slot ${i + 1} start',
        );
      }
    });

    test('each slot start is before end', () {
      final slots = HoraService.calculate(
        sunriseUtc: sunrise,
        sunsetUtc: sunset,
        nextSunriseUtc: nextSunrise,
        weekday: 3,
      );
      for (final s in slots) {
        expect(s.start.isBefore(s.end), isTrue,
            reason: 'slot ${s.planet} start must be before end');
      }
    });
  });
}
