import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tithika/core/theme.dart';
import 'package:tithika/features/month_view/month_view_screen.dart';
import 'package:tithika/models/day_data.dart';
import 'package:tithika/models/lunar_month.dart';
import 'package:tithika/models/nakshatra_info.dart';
import 'package:tithika/models/paksha.dart';
import 'package:tithika/models/tithi_info.dart';
import 'package:tithika/services/providers.dart';
import 'package:tithika/state/providers.dart';

// Fixed tithi number (1 = Pratipada) for every day, so the small tithi-number
// label inside each cell never collides with the day-of-month text we assert
// on below (the two are rendered as separate Text widgets with the same
// string when they happen to coincide, e.g. day 10 + tithi 10).
TithiInfo _tithi() {
  return TithiInfo(
    number: 1,
    pakshaNumber: 1,
    paksha: Paksha.shukla,
    start: DateTime.utc(2026, 10, 1),
    end: DateTime.utc(2026, 10, 2),
  );
}

Map<int, DayData> _fakeOctober2026() {
  final data = <int, DayData>{};
  for (var d = 1; d <= 31; d++) {
    // Simulate a Hindu-month transition on day 21 (matches user's report).
    final month = d < 21 ? LunarMonth.ashwina : LunarMonth.kartika;
    data[d] = DayData(
      localDate: DateTime(2026, 10, d),
      tithi: _tithi(),
      nakshatra: NakshatraInfo(number: 1, end: DateTime.utc(2026, 10, d + 1)),
      lunarMonth: month,
      sunZodiacSign: 5,
    );
  }
  return data;
}

void main() {
  testWidgets('Month view — October 2026 day cells render fully, label at bottom',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final octData = _fakeOctober2026();

    // Narrow width to stress the same pixel budget reported on the user's phone.
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 15)),
          selectedMonthProvider.overrideWith((ref) => DateTime(2026, 10)),
          monthDataProvider.overrideWith((ref, args) async => octData),
        ],
        child: MaterialApp(
          theme: buildTithikaTheme(Brightness.dark),
          home: const MonthViewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Every two-digit day must render its FULL string (not truncated, e.g.
    // "21" clipped down to "2") and must not report a text overflow.
    for (final day in [10, 15, 20, 21, 22, 28, 31]) {
      final finder = find.text('$day');
      expect(finder, findsOneWidget,
          reason: 'Day $day should render as "$day", not be clipped');
      final renderText = tester.renderObject<RenderParagraph>(finder);
      expect(renderText.text.toPlainText(), '$day');
      expect(renderText.didExceedMaxLines, isFalse,
          reason: 'Day $day text should not overflow its box');
    }

    // No RenderFlex/text overflow anywhere in the tree (the classic silent
    // clip inside _MonthCell's ClipRect that motivated this test). Checked
    // immediately, before GoogleFonts' unawaited network font-fetch (which
    // always fails in this offline test sandbox) can surface as a stray
    // async exception unrelated to layout correctness.
    expect(tester.takeException(), isNull);
  });
}
