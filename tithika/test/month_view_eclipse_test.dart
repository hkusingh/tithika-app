import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tithika/core/theme.dart';
import 'package:tithika/features/month_view/month_view_screen.dart';
import 'package:tithika/models/day_data.dart';
import 'package:tithika/models/eclipse_info.dart';
import 'package:tithika/models/lunar_month.dart';
import 'package:tithika/models/nakshatra_info.dart';
import 'package:tithika/models/paksha.dart';
import 'package:tithika/models/tithi_info.dart';
import 'package:tithika/services/providers.dart';
import 'package:tithika/state/providers.dart';

TithiInfo _tithi() {
  return TithiInfo(
    number: 1,
    pakshaNumber: 1,
    paksha: Paksha.shukla,
    start: DateTime.utc(2026, 3, 1),
    end: DateTime.utc(2026, 3, 2),
  );
}

Map<int, DayData> _fakeMarch2026() {
  final data = <int, DayData>{};
  for (var d = 1; d <= 31; d++) {
    data[d] = DayData(
      localDate: DateTime(2026, 3, d),
      tithi: _tithi(),
      nakshatra: NakshatraInfo(number: 1, end: DateTime.utc(2026, 3, d + 1)),
      lunarMonth: LunarMonth.phalguna,
      sunZodiacSign: 10,
    );
  }
  return data;
}

// Real total lunar eclipse, March 3, 2026 (max ~11:33 UTC — visible from
// Ujjain at ~17:03 IST).
final _marchLunarEclipse = EclipseInfo(
  kind: EclipseKind.lunar,
  subtype: EclipseSubtype.total,
  maxUtc: DateTime.utc(2026, 3, 3, 11, 33),
  startUtc: DateTime.utc(2026, 3, 3, 9, 49),
  endUtc: DateTime.utc(2026, 3, 3, 13, 17),
  visible: true,
  sutakStartUtc: DateTime.utc(2026, 3, 3, 0, 49),
  localDate: DateTime(2026, 3, 3),
);

void main() {
  testWidgets('Month view — eclipse section, dot marker, and detail sheet render',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final marchData = _fakeMarch2026();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 3, 15)),
          selectedMonthProvider.overrideWith((ref) => DateTime(2026, 3)),
          monthDataProvider.overrideWith((ref, args) async => marchData),
          monthEclipsesProvider
              .overrideWith((ref, args) async => [_marchLunarEclipse]),
          yearEclipsesProvider
              .overrideWith((ref, year) async => [_marchLunarEclipse]),
        ],
        child: MaterialApp(
          theme: buildTithikaTheme(Brightness.dark),
          home: const MonthViewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Eclipse section header and row content are present.
    expect(find.text('ECLIPSES'), findsOneWidget);
    expect(find.text('Total Lunar Eclipse'), findsOneWidget);

    // Tapping the row opens the eclipse detail sheet.
    await tester.tap(find.text('Total Lunar Eclipse'));
    await tester.pumpAndSettle();
    expect(find.text('Sutak begins'), findsOneWidget);
    expect(find.text('Visible here'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Month view — not-visible eclipse is listed with a "not visible" tag',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final marchData = _fakeMarch2026();

    final notVisible = EclipseInfo(
      kind: EclipseKind.solar,
      subtype: EclipseSubtype.annular,
      maxUtc: DateTime.utc(2026, 3, 17, 6, 0),
      startUtc: DateTime.utc(2026, 3, 17, 5, 0),
      endUtc: DateTime.utc(2026, 3, 17, 7, 0),
      visible: false,
      sutakStartUtc: null,
      localDate: DateTime(2026, 3, 17),
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 3, 15)),
          selectedMonthProvider.overrideWith((ref) => DateTime(2026, 3)),
          monthDataProvider.overrideWith((ref, args) async => marchData),
          monthEclipsesProvider.overrideWith((ref, args) async => [notVisible]),
          yearEclipsesProvider.overrideWith((ref, year) async => [notVisible]),
        ],
        child: MaterialApp(
          theme: buildTithikaTheme(Brightness.dark),
          home: const MonthViewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not visible here'), findsOneWidget);

    // Opening the detail sheet for a not-visible eclipse must show times in
    // UTC (labelled as such), never silently reinterpreted through the
    // viewer's local timezone as if they were real local observation times.
    await tester.tap(find.text('Annular Solar Eclipse'));
    await tester.pumpAndSettle();
    expect(find.text('Times shown in UTC (not visible here)'), findsOneWidget);
    expect(find.textContaining('UTC'), findsWidgets);
    // sutakStartUtc is null for not-visible eclipses, so no Sutak row.
    expect(find.text('Sutak begins'), findsNothing);

    expect(tester.takeException(), isNull);
  });
}
