import 'package:flutter/material.dart';

import '../models/muhurta_data.dart';

// Choghadiya type cycle (7 types, repeating).
const _choghadiyaOrder = [
  ChoghadiyaType.udveg,
  ChoghadiyaType.char,
  ChoghadiyaType.labh,
  ChoghadiyaType.amrit,
  ChoghadiyaType.kaal,
  ChoghadiyaType.shubh,
  ChoghadiyaType.rog,
];

// Day Choghadiya start index into _choghadiyaOrder, keyed by Sun-first weekday
// (0=Sun, 1=Mon … 6=Sat, from DateTime.weekday % 7).
// Sun→Udveg(0), Mon→Amrit(3), Tue→Rog(6), Wed→Labh(2),
// Thu→Shubh(5), Fri→Char(1), Sat→Kaal(4).
const _dayStartIndex   = [0, 3, 6, 2, 5, 1, 4];

// Night Choghadiya start index.
// Sun→Shubh(5), Mon→Char(1), Tue→Kaal(4), Wed→Udveg(0),
// Thu→Amrit(3), Fri→Rog(6), Sat→Labh(2).
const _nightStartIndex = [5, 1, 4, 0, 3, 6, 2];

// Rahu Kaal, Yamaganda, Gulika: 1-based day segment slot, keyed by Sun-first weekday.
// Mnemonic for Rahu: "Mother Saw Father Wearing The Turban Suddenly"
//   → Mon=2, Sat=3, Fri=4, Wed=5, Thu=6, Tue=7, Sun=8
const _rahuSlot      = [8, 2, 7, 5, 6, 4, 3];
const _yamagandaSlot = [5, 4, 3, 2, 1, 7, 6];
const _gulikaSlot    = [7, 6, 5, 4, 3, 2, 1];

class MuhurtaService {
  const MuhurtaService._();

  /// Computes all Muhurta windows for a single calendar day.
  ///
  /// [weekday] is [DateTime.weekday] (Mon=1 … Sun=7).
  /// [nextSunriseUtc] bounds the night Choghadiya and is the anchor for
  /// tomorrow's Brahma Muhurta — pass [horaSlots.last.end] from the
  /// existing hora provider.
  static MuhurtaData calculate({
    required DateTime sunriseUtc,
    required DateTime sunsetUtc,
    required DateTime nextSunriseUtc,
    required int weekday,
  }) {
    final sundayFirst = weekday % 7; // Mon=1→1 … Sun=7→0

    final dayDuration   = sunsetUtc.difference(sunriseUtc);
    final nightDuration = nextSunriseUtc.difference(sunsetUtc);
    final daySegment    = dayDuration  ~/ 8;
    final nightSegment  = nightDuration ~/ 8;

    // ── Rahu Kaal, Yamaganda, Gulika ─────────────────────────────────────
    final rahuKaal  = _daySlot(sunriseUtc, daySegment, _rahuSlot[sundayFirst]);
    final yamaganda = _daySlot(sunriseUtc, daySegment, _yamagandaSlot[sundayFirst]);
    final gulika    = _daySlot(sunriseUtc, daySegment, _gulikaSlot[sundayFirst]);

    // ── Abhijit ──────────────────────────────────────────────────────────
    // Not observed on Wednesday (DateTime.wednesday == 3).
    DateTimeRange? abhijit;
    if (weekday != DateTime.wednesday) {
      final solarNoon = sunriseUtc.add(dayDuration ~/ 2);
      abhijit = DateTimeRange(
        start: solarNoon.subtract(const Duration(minutes: 24)),
        end:   solarNoon.add(const Duration(minutes: 24)),
      );
    }

    // ── Brahma Muhurta ───────────────────────────────────────────────────
    // 14th muhurta of the night before this day: sunrise − 96 min → sunrise − 48 min.
    final brahma = DateTimeRange(
      start: sunriseUtc.subtract(const Duration(minutes: 96)),
      end:   sunriseUtc.subtract(const Duration(minutes: 48)),
    );

    // ── Day Choghadiya (8 slots: sunrise → sunset) ───────────────────────
    final dayIdx = _dayStartIndex[sundayFirst];
    final daySlots = List.generate(8, (i) {
      final type  = _choghadiyaOrder[(dayIdx + i) % 7];
      final start = sunriseUtc.add(daySegment * i);
      final end   = i < 7 ? sunriseUtc.add(daySegment * (i + 1)) : sunsetUtc;
      return ChoghadiyaSlot(type: type, start: start, end: end);
    });

    // ── Night Choghadiya (8 slots: sunset → next sunrise) ────────────────
    final nightIdx = _nightStartIndex[sundayFirst];
    final nightSlots = List.generate(8, (i) {
      final type  = _choghadiyaOrder[(nightIdx + i) % 7];
      final start = sunsetUtc.add(nightSegment * i);
      final end   = i < 7 ? sunsetUtc.add(nightSegment * (i + 1)) : nextSunriseUtc;
      return ChoghadiyaSlot(type: type, start: start, end: end);
    });

    return MuhurtaData(
      rahuKaal:        rahuKaal,
      yamaganda:       yamaganda,
      gulika:          gulika,
      abhijit:         abhijit,
      brahma:          brahma,
      dayChoghadiya:   daySlots,
      nightChoghadiya: nightSlots,
    );
  }

  // Converts a 1-based slot number into a DateTimeRange.
  static DateTimeRange _daySlot(DateTime sunrise, Duration segDur, int slot) =>
      DateTimeRange(
        start: sunrise.add(segDur * (slot - 1)),
        end:   sunrise.add(segDur * slot),
      );
}
