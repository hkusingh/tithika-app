import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_location.dart';
import '../models/app_settings.dart';
import '../models/day_data.dart';
import '../models/hora_data.dart';
import '../models/lunar_month.dart';
import '../models/paksha.dart';
import '../services/festival_detector.dart';
import '../services/hora_service.dart';
import '../services/providers.dart' as svc;
import 'app_settings_notifier.dart';

// ── Month system adjustment ───────────────────────────────────────────────────

/// Base month naming from [_lunarMonthAndAdhika] is Amanta (prevAmavasya sign).
/// For Purnimanta display, non-Adhika Krishna paksha belongs to the NEXT month.
DayData _applyMonthSystem(DayData raw, MonthSystem system) {
  if (system == MonthSystem.amanta) return raw;
  if (!raw.isAdhika && raw.tithi.paksha == Paksha.krishna) {
    final next = LunarMonth.values[(raw.lunarMonth.index + 1) % 12];
    return raw.copyWith(lunarMonth: next);
  }
  return raw;
}

// ── Settings ─────────────────────────────────────────────────────────────────

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

// ── Selected date ─────────────────────────────────────────────────────────────

final selectedDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

// ── Location helpers ──────────────────────────────────────────────────────────

/// The effective location: user's saved location, or Ujjain as fallback.
final effectiveLocationProvider = Provider<AppLocation>((ref) {
  return ref.watch(appSettingsProvider).location ?? AppLocation.ujjain;
});

/// True once the user has explicitly set a location (not using Ujjain fallback).
final locationIsSetProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).hasLocation;
});

// ── Day data ──────────────────────────────────────────────────────────────────

/// Computes full [DayData] for the selected date at the effective location,
/// including festival detection. Returns null while the ephemeris is loading.
final dayDataProvider = FutureProvider<DayData?>((ref) async {
  final tithiSvc = await ref.watch(svc.tithiServiceProvider.future);
  final date = ref.watch(selectedDateProvider);
  final location = ref.watch(effectiveLocationProvider);
  final monthSystem = ref.watch(appSettingsProvider).monthSystem;

  final raw = tithiSvc.calculateForDate(
    localDate: date,
    lat: location.lat,
    lon: location.lon,
    tzOffset: location.tzOffsetAt(date),
  );

  final adjusted = _applyMonthSystem(raw, monthSystem);
  final purnimanta = _applyMonthSystem(raw, MonthSystem.purnimanta);
  final festivalName = FestivalDetector.detect(purnimanta);
  return adjusted.copyWith(festivalName: festivalName);
});

// ── Day strip (4 days: selected−1, selected, selected+1, selected+2) ──────────

final stripDaysProvider = FutureProvider<List<DayData>>((ref) async {
  final tithiSvc = await ref.watch(svc.tithiServiceProvider.future);
  final selected = ref.watch(selectedDateProvider);
  final location = ref.watch(effectiveLocationProvider);
  final monthSystem = ref.watch(appSettingsProvider).monthSystem;
  return List.generate(4, (i) {
    final date = DateTime(selected.year, selected.month, selected.day)
        .add(Duration(days: i - 1));
    final raw = tithiSvc.calculateForDate(
      localDate: date,
      lat: location.lat,
      lon: location.lon,
      tzOffset: location.tzOffsetAt(date),
    );
    final adjusted = _applyMonthSystem(raw, monthSystem);
    final purnimanta = _applyMonthSystem(raw, MonthSystem.purnimanta);
    return adjusted.copyWith(festivalName: FestivalDetector.detect(purnimanta));
  });
});

// ── Month navigation ──────────────────────────────────────────────────────────

/// The month currently shown in MonthViewScreen. Initialised from selectedDate.
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final d = ref.read(selectedDateProvider);
  return DateTime(d.year, d.month);
});

// ── Month grid data ───────────────────────────────────────────────────────────

/// Full [DayData] for every day in (year, month), keyed by day-of-month.
/// Festival names are included via [FestivalDetector].
/// Each day uses its own DST-adjusted tzOffset so month boundaries across
/// DST transitions are computed correctly.
final monthDataProvider =
    FutureProvider.family<Map<int, DayData>, (int, int)>((ref, args) async {
  final tithiSvc = await ref.watch(svc.tithiServiceProvider.future);
  final location = ref.watch(effectiveLocationProvider);
  final monthSystem = ref.watch(appSettingsProvider).monthSystem;
  final (year, month) = args;
  final daysInMonth = DateTime(year, month + 1, 0).day;
  return {
    for (var d = 1; d <= daysInMonth; d++)
      d: () {
        final date = DateTime(year, month, d);
        final raw = tithiSvc.calculateForDate(
          localDate: date,
          lat: location.lat,
          lon: location.lon,
          tzOffset: location.tzOffsetAt(date),
        );
        final adjusted = _applyMonthSystem(raw, monthSystem);
        final purnimanta = _applyMonthSystem(raw, MonthSystem.purnimanta);
        return adjusted.copyWith(festivalName: FestivalDetector.detect(purnimanta));
      }(),
  };
});

// ── Hindu month transitions ───────────────────────────────────────────────────

class NextHinduMonthInfo {
  final LunarMonth month;
  final DateTime date;
  final DateTime startUtc;
  final Duration tzOffset;

  const NextHinduMonthInfo({
    required this.month,
    required this.date,
    required this.startUtc,
    required this.tzOffset,
  });
}

/// Returns all Hindu (Purnimanta) month transitions that START within the
/// given Gregorian (year, month). Derives from already-cached monthDataProvider
/// so no extra ephemeris calls are made.
final hinduMonthTransitionsProvider =
    FutureProvider.family<List<NextHinduMonthInfo>, (int, int)>((ref, args) async {
  final (year, month) = args;
  final monthData = await ref.watch(monthDataProvider(args).future);
  final location = ref.watch(effectiveLocationProvider);

  final transitions = <NextHinduMonthInfo>[];
  LunarMonth? prev;
  final days = monthData.keys.toList()..sort();
  for (final d in days) {
    final data = monthData[d]!;
    if (prev != null && data.lunarMonth != prev) {
      final date = DateTime(year, month, d);
      transitions.add(NextHinduMonthInfo(
        month: data.lunarMonth,
        date: date,
        startUtc: data.tithi.start,
        tzOffset: location.tzOffsetAt(date),
      ));
    }
    prev = data.lunarMonth;
  }
  return transitions;
});

// ── Hora ──────────────────────────────────────────────────────────────────────

/// 24 unequal planetary hours for the selected date at the effective location.
/// Returns null while the ephemeris is loading or sunrise/sunset is unavailable.
final horaProvider = FutureProvider<List<HoraSlot>?>((ref) async {
  final dayData = await ref.watch(dayDataProvider.future);
  if (dayData == null) return null;
  if (dayData.sunriseUtc == null || dayData.sunsetUtc == null) return null;

  final tithiSvc = await ref.watch(svc.tithiServiceProvider.future);
  final location = ref.watch(effectiveLocationProvider);
  final date = ref.watch(selectedDateProvider);

  final tomorrow = DateTime(date.year, date.month, date.day + 1);
  final nextDayRaw = tithiSvc.calculateForDate(
    localDate: tomorrow,
    lat: location.lat,
    lon: location.lon,
    tzOffset: location.tzOffsetAt(tomorrow),
  );
  final nextSunrise = nextDayRaw.sunriseUtc;
  if (nextSunrise == null) return null;

  return HoraService.calculate(
    sunriseUtc: dayData.sunriseUtc!,
    sunsetUtc: dayData.sunsetUtc!,
    nextSunriseUtc: nextSunrise,
    weekday: date.weekday,
  );
});

// ── Year festival list ────────────────────────────────────────────────────────

class FestivalEntry {
  final DateTime date;
  final DayData data;

  const FestivalEntry({required this.date, required this.data});
}

/// All festival days for [year] at the effective location.
/// Iterates all 365/366 days — pure arithmetic, no I/O, completes in < 1s.
final yearFestivalsProvider =
    FutureProvider.family<List<FestivalEntry>, int>((ref, year) async {
  final tithiSvc = await ref.watch(svc.tithiServiceProvider.future);
  final location = ref.watch(effectiveLocationProvider);
  final monthSystem = ref.watch(appSettingsProvider).monthSystem;

  final entries = <FestivalEntry>[];
  for (var month = 1; month <= 12; month++) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final raw = tithiSvc.calculateForDate(
        localDate: date,
        lat: location.lat,
        lon: location.lon,
        tzOffset: location.tzOffsetAt(date),
      );
      final adjusted = _applyMonthSystem(raw, monthSystem);
      final purnimanta = _applyMonthSystem(raw, MonthSystem.purnimanta);
      final enriched = adjusted.copyWith(festivalName: FestivalDetector.detect(purnimanta));
      if (enriched.festivalName != null) {
        entries.add(FestivalEntry(date: date, data: enriched));
      }
    }
  }
  return entries;
});
