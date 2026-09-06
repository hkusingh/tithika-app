import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tithika/core/theme.dart';
import 'package:tithika/features/festivals/festival_bell.dart';
import 'package:tithika/models/app_settings.dart';
import 'package:tithika/services/providers.dart';
import 'package:tithika/state/providers.dart';

/// Pumps a bell inside a tappable ancestor, mirroring how a festival row
/// wraps it, so the gesture-arena behaviour is exercised too.
Future<int> _pumpBell(
  WidgetTester tester, {
  required Map<String, Object> prefs,
  required VoidCallback onRowTap,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  var rowTaps = 0;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
      child: MaterialApp(
        theme: buildTithikaTheme(Brightness.dark),
        home: Scaffold(
          body: GestureDetector(
            onTap: () {
              rowTaps++;
              onRowTap();
            },
            child: const Center(
              child: FestivalBell(canonicalKey: 'Holi'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return rowTaps;
}

void main() {
  // Notifications on, master "all festivals" off — the mode in which bells
  // are the mechanism.
  const individualMode = <String, Object>{
    'notif_enabled': true,
    'notif_festival': false,
  };

  testWidgets('renders an unlit bell when the festival is not selected',
      (tester) async {
    await _pumpBell(tester, prefs: individualMode, onRowTap: () {});

    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active_rounded), findsNothing);
  });

  testWidgets('renders a lit bell when the festival is selected',
      (tester) async {
    await _pumpBell(
      tester,
      prefs: {...individualMode, 'notif_selected_festivals': ['Holi']},
      onRowTap: () {},
    );

    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
  });

  testWidgets('renders lit while the master switch covers all festivals',
      (tester) async {
    await _pumpBell(
      tester,
      prefs: {'notif_enabled': true, 'notif_festival': true},
      onRowTap: () {},
    );

    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
  });

  testWidgets('tapping selects the festival and confirms with a snackbar',
      (tester) async {
    await _pumpBell(tester, prefs: individualMode, onRowTap: () {});

    await tester.tap(find.byType(FestivalBell));
    await tester.pump();

    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
    expect(find.textContaining("You'll be reminded"), findsOneWidget);
  });

  testWidgets('tapping again deselects it', (tester) async {
    await _pumpBell(
      tester,
      prefs: {...individualMode, 'notif_selected_festivals': ['Holi']},
      onRowTap: () {},
    );

    await tester.tap(find.byType(FestivalBell));
    await tester.pump();

    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.textContaining('Reminder off'), findsOneWidget);
  });

  testWidgets('the tap does not reach the surrounding row', (tester) async {
    var rowTapped = false;
    await _pumpBell(
      tester,
      prefs: individualMode,
      onRowTap: () => rowTapped = true,
    );

    await tester.tap(find.byType(FestivalBell));
    await tester.pump();

    // The bell's own detector wins the arena, so a row wrapping it would not
    // also open the festival detail page.
    expect(rowTapped, isFalse);
  });

  testWidgets('explains rather than toggling while the master switch is on',
      (tester) async {
    await _pumpBell(
      tester,
      prefs: {'notif_enabled': true, 'notif_festival': true},
      onRowTap: () {},
    );

    await tester.tap(find.byType(FestivalBell));
    await tester.pumpAndSettle();

    expect(find.text('All festivals are on'), findsOneWidget);
  });

  testWidgets('points at Settings when notifications are switched off',
      (tester) async {
    await _pumpBell(
      tester,
      prefs: {'notif_enabled': false, 'notif_festival': false},
      onRowTap: () {},
    );

    await tester.tap(find.byType(FestivalBell));
    await tester.pump();

    expect(find.textContaining('Turn on notifications'), findsOneWidget);
    // Nothing was written — the bell is still unlit.
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });

  testWidgets(
      'toggling a bell does not invalidate providers that only need '
      'monthSystem or language', (tester) async {
    // Regression: yearFestivalsProvider watched the whole AppSettings object,
    // so a bell tap re-ran its 365-day ephemeris loop and the festivals list
    // blanked out mid-scroll before repopulating.
    SharedPreferences.setMockInitialValues(individualMode);
    final sp = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
    );
    addTearDown(container.dispose);

    var monthSystemRebuilds = 0;
    final probe = Provider<MonthSystem>((ref) {
      monthSystemRebuilds++;
      return ref.watch(appSettingsProvider.select((s) => s.monthSystem));
    });

    container.read(probe);
    expect(monthSystemRebuilds, 1);

    // Write notification settings the way a bell tap does.
    final notif = container.read(appSettingsProvider).notificationSettings;
    container.read(appSettingsProvider.notifier).state = container
        .read(appSettingsProvider)
        .copyWith(
            notificationSettings:
                notif.copyWith(selectedFestivals: const {'Holi'}));

    container.read(probe);
    expect(monthSystemRebuilds, 1,
        reason: 'monthSystem is unchanged, so dependents must not recompute');
  });
}
