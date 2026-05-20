import '../models/hora_data.dart';

// Chaldean planetary sequence (fixed, cyclic).
const _sequence = HoraPlanet.values; // [sun, venus, mercury, moon, saturn, jupiter, mars]

// Index into _sequence for the first day-hora, keyed by Sunday-first weekday
// (0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat).
// Sunday → Sun, Monday → Moon, Tuesday → Mars, Wednesday → Mercury,
// Thursday → Jupiter, Friday → Venus, Saturday → Saturn.
const _weekdayStart = [0, 3, 6, 2, 5, 1, 4];

class HoraService {
  const HoraService._();

  /// Computes 24 [HoraSlot]s for a given day.
  ///
  /// [weekday] is [DateTime.weekday] (1=Mon…7=Sun).
  static List<HoraSlot> calculate({
    required DateTime sunriseUtc,
    required DateTime sunsetUtc,
    required DateTime nextSunriseUtc,
    required int weekday,
  }) {
    final sundayFirst = weekday % 7; // Mon=1→1 … Sun=7→0
    final startIdx = _weekdayStart[sundayFirst];

    final dayDuration = sunsetUtc.difference(sunriseUtc);
    final dayHora = dayDuration ~/ 12;

    final nightDuration = nextSunriseUtc.difference(sunsetUtc);
    final nightHora = nightDuration ~/ 12;

    final slots = <HoraSlot>[];

    for (var i = 0; i < 12; i++) {
      final planet = _sequence[(startIdx + i) % 7];
      final start = sunriseUtc.add(dayHora * i);
      final end = i < 11 ? sunriseUtc.add(dayHora * (i + 1)) : sunsetUtc;
      slots.add(HoraSlot(planet: planet, start: start, end: end, isDay: true));
    }

    for (var i = 0; i < 12; i++) {
      final planet = _sequence[(startIdx + 12 + i) % 7];
      final start = sunsetUtc.add(nightHora * i);
      final end = i < 11 ? sunsetUtc.add(nightHora * (i + 1)) : nextSunriseUtc;
      slots.add(HoraSlot(planet: planet, start: start, end: end, isDay: false));
    }

    return slots;
  }
}
