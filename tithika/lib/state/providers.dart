import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_location.dart';
import '../models/app_settings.dart';
import '../models/day_data.dart';
import '../models/eclipse_info.dart';
import '../models/hora_data.dart';
import '../models/lunar_month.dart';
import '../models/muhurta_data.dart';
import '../models/paksha.dart';
import '../models/pancha_data.dart';
import '../models/special_tithi.dart';
import '../services/festival_detector.dart';
import '../services/hora_service.dart';
import '../services/muhurta_service.dart';
import '../services/pancha_service.dart';
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
  final tomorrow = date.add(const Duration(days: 1));
  final rawTomorrow = tithiSvc.calculateForDate(
    localDate: tomorrow,
    lat: location.lat,
    lon: location.lon,
    tzOffset: location.tzOffsetAt(tomorrow),
  );

  final adjusted = _applyMonthSystem(raw, monthSystem);
  final purnimanta = _applyMonthSystem(raw, MonthSystem.purnimanta);
  final purnimantaTomorrow = _applyMonthSystem(rawTomorrow, MonthSystem.purnimanta);
  final festivalNames = FestivalDetector.detectAll(purnimanta, purnimantaTomorrow);
  return adjusted.copyWith(festivalNames: festivalNames);
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
    final tomorrow = date.add(const Duration(days: 1));
    final rawTomorrow = tithiSvc.calculateForDate(
      localDate: tomorrow,
      lat: location.lat,
      lon: location.lon,
      tzOffset: location.tzOffsetAt(tomorrow),
    );
    final adjusted = _applyMonthSystem(raw, monthSystem);
    final purnimanta = _applyMonthSystem(raw, MonthSystem.purnimanta);
    final purnimantaTomorrow = _applyMonthSystem(rawTomorrow, MonthSystem.purnimanta);
    return adjusted.copyWith(
      festivalNames: FestivalDetector.detectAll(purnimanta, purnimantaTomorrow),
    );
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
        final tomorrow = date.add(const Duration(days: 1));
        final rawTomorrow = tithiSvc.calculateForDate(
          localDate: tomorrow,
          lat: location.lat,
          lon: location.lon,
          tzOffset: location.tzOffsetAt(tomorrow),
        );
        final adjusted = _applyMonthSystem(raw, monthSystem);
        final purnimanta = _applyMonthSystem(raw, MonthSystem.purnimanta);
        final purnimantaTomorrow = _applyMonthSystem(rawTomorrow, MonthSystem.purnimanta);
        return adjusted.copyWith(
          festivalNames: FestivalDetector.detectAll(purnimanta, purnimantaTomorrow),
        );
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

// ── Muhurta ───────────────────────────────────────────────────────────────────

/// Rahu Kaal, Yamaganda, Gulika, Abhijit, Brahma Muhurta, and Choghadiya
/// for the selected date. Returns null while hora data is loading.
final muhurtaProvider = FutureProvider<MuhurtaData?>((ref) async {
  final dayData   = await ref.watch(dayDataProvider.future);
  final horaSlots = await ref.watch(horaProvider.future);
  final date      = ref.watch(selectedDateProvider);

  if (dayData == null) return null;
  if (dayData.sunriseUtc == null || dayData.sunsetUtc == null) return null;
  if (horaSlots == null || horaSlots.isEmpty) return null;

  return MuhurtaService.calculate(
    sunriseUtc:     dayData.sunriseUtc!,
    sunsetUtc:      dayData.sunsetUtc!,
    nextSunriseUtc: horaSlots.last.end, // last night slot ends at next sunrise
    weekday:        date.weekday,
  );
});

// ── Panchanga (Yoga + Karana) ─────────────────────────────────────────────────

/// Yoga and Karana data for the selected date.
/// Returns null while hora data is loading or sunrise/sunset is unavailable.
final panchaProvider = FutureProvider<PanchaData?>((ref) async {
  final dayData   = await ref.watch(dayDataProvider.future);
  final horaSlots = await ref.watch(horaProvider.future);

  if (dayData == null) return null;
  if (dayData.sunriseUtc == null) return null;
  if (dayData.sidSunLonDeg == null || dayData.sidMoonLonDeg == null) return null;
  if (dayData.tropElongDeg == null) return null;
  if (horaSlots == null || horaSlots.isEmpty) return null;

  return PanchaService.calculate(
    sunriseUtc:     dayData.sunriseUtc!,
    nextSunriseUtc: horaSlots.last.end,
    sidSunLonDeg:   dayData.sidSunLonDeg!,
    sidMoonLonDeg:  dayData.sidMoonLonDeg!,
    tropElongDeg:   dayData.tropElongDeg!,
  );
});

// ── Year festival list ────────────────────────────────────────────────────────

class FestivalEntry {
  final DateTime date;
  final DayData data;

  /// True for any Ekadashi day (named or generic) — controls the Ekadasi tab.
  final bool isEkadashi;

  /// True when the day carries a proper festival name (including named
  /// Ekadashis like Nirjala) — controls the Festivals tab.
  final bool inFestivals;

  const FestivalEntry({
    required this.date,
    required this.data,
    this.isEkadashi = false,
    this.inFestivals = false,
  });
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
      final tomorrow = date.add(const Duration(days: 1));
      final rawTomorrow = tithiSvc.calculateForDate(
        localDate: tomorrow,
        lat: location.lat,
        lon: location.lon,
        tzOffset: location.tzOffsetAt(tomorrow),
      );
      final purnimantaTomorrow = _applyMonthSystem(rawTomorrow, MonthSystem.purnimanta);
      final primaryIsEkadashi = raw.tithi.special == SpecialTithi.ekadashi;
      final kshayaIsEkadashi = raw.secondaryIsKshaya &&
          raw.secondaryTithi?.special == SpecialTithi.ekadashi;
      final isEkadashiDay = primaryIsEkadashi || kshayaIsEkadashi;
      // Vruddhi: look ahead — if tomorrow also has Ekadashi as primary, today
      // is Day 1 and should be suppressed (observe on Day 2).  Lookahead is
      // more robust than secondaryTithi == null alone, which can miss the case
      // where Ekadashi ends minutes before the next sunrise.
      final isVruddhiFirstDay =
          primaryIsEkadashi && rawTomorrow.tithi.special == SpecialTithi.ekadashi;
      final detectedNames = FestivalDetector.detectAll(purnimanta, purnimantaTomorrow);
      final isObservedEkadashi = isEkadashiDay && !isVruddhiFirstDay;

      // One FestivalEntry per detected name — each links to its own
      // description, so unrelated same-day festivals must never be merged.
      for (final name in detectedNames) {
        entries.add(FestivalEntry(
          date: date,
          data: adjusted.copyWith(festivalName: name),
          isEkadashi: isObservedEkadashi,
          inFestivals: true,
        ));
        // Golu (Bommai Kolu) — Tamil Nadu tradition during Sharad Navratri,
        // same start date, shown as a separate festival entry.
        if (name == 'Sharad Navratri') {
          entries.add(FestivalEntry(
            date: date,
            data: adjusted.copyWith(festivalName: 'Golu'),
            inFestivals: true,
          ));
        }
      }
      if (detectedNames.isEmpty && isObservedEkadashi) {
        entries.add(FestivalEntry(
          date: date,
          data: adjusted.copyWith(festivalName: 'Ekadashi'),
          isEkadashi: true,
          inFestivals: false,
        ));
      }
    }
  }
  return entries;
});

// ── Eclipses ─────────────────────────────────────────────────────────────────

/// All solar and lunar eclipses with maximum eclipse in [year], evaluated
/// for visibility/contact-times at the effective location. Cheap — only a
/// handful of forward ephemeris searches per year, no per-day loop.
final yearEclipsesProvider =
    FutureProvider.family<List<EclipseInfo>, int>((ref, year) async {
  final eclipseSvc = await ref.watch(svc.eclipseServiceProvider.future);
  final location = ref.watch(effectiveLocationProvider);
  return eclipseSvc.eclipsesForYear(year, location);
});

/// Eclipses whose [EclipseInfo.localDate] falls within the given Gregorian
/// (year, month). Derives from [yearEclipsesProvider] so no extra ephemeris
/// calls are made; handles eclipses near a year boundary since either
/// adjacent year's list is consulted as needed.
final monthEclipsesProvider =
    FutureProvider.family<List<EclipseInfo>, (int, int)>((ref, args) async {
  final (year, month) = args;
  final yearList = await ref.watch(yearEclipsesProvider(year).future);
  var candidates = yearList;
  if (month == 1) {
    final prevYearList = await ref.watch(yearEclipsesProvider(year - 1).future);
    candidates = [...prevYearList, ...yearList];
  } else if (month == 12) {
    final nextYearList = await ref.watch(yearEclipsesProvider(year + 1).future);
    candidates = [...yearList, ...nextYearList];
  }
  return candidates
      .where((e) => e.localDate.year == year && e.localDate.month == month)
      .toList();
});
