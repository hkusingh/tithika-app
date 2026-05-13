import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_location.dart';
import '../models/app_settings.dart';
import '../models/day_data.dart';
import '../services/festival_detector.dart';
import '../services/providers.dart' as svc;
import 'app_settings_notifier.dart';

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

  final raw = tithiSvc.calculateForDate(
    localDate: date,
    lat: location.lat,
    lon: location.lon,
    tzOffset: location.tzOffsetAt(date),
  );

  final festivalName = FestivalDetector.detect(raw);
  return raw.copyWith(festivalName: festivalName);
});

// ── Day strip (4 days: selected−1, selected, selected+1, selected+2) ──────────

final stripDaysProvider = FutureProvider<List<DayData>>((ref) async {
  final tithiSvc = await ref.watch(svc.tithiServiceProvider.future);
  final selected = ref.watch(selectedDateProvider);
  final location = ref.watch(effectiveLocationProvider);
  return List.generate(4, (i) {
    final date = DateTime(selected.year, selected.month, selected.day)
        .add(Duration(days: i - 1));
    final raw = tithiSvc.calculateForDate(
      localDate: date,
      lat: location.lat,
      lon: location.lon,
      tzOffset: location.tzOffsetAt(date),
    );
    return raw.copyWith(festivalName: FestivalDetector.detect(raw));
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
        return raw.copyWith(festivalName: FestivalDetector.detect(raw));
      }(),
  };
});
