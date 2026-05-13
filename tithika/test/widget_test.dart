import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tithika/core/theme.dart';
import 'package:tithika/features/onboarding/onboarding_screen.dart';
import 'package:tithika/services/providers.dart';

void main() {
  testWidgets('app launches and shows onboarding when no location is set',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: buildTithikaTheme(),
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
