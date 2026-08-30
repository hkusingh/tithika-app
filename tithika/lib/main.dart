import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:tithika/core/router.dart' show buildRouter;
import 'package:tithika/core/theme.dart';
import 'package:tithika/services/notification_service.dart';
import 'package:tithika/services/providers.dart';
import 'package:tithika/services/update_service.dart';
import 'package:tithika/services/widget_data_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tithika/state/providers.dart'
    show appSettingsProvider, dayDataProvider, effectiveLocationProvider, muhurtaProvider, selectedDateProvider, yearFestivalsProvider;

Future<void> _refreshWidget(ProviderContainer container) async {
  try {
    final dayData = await container.read(dayDataProvider.future);
    if (dayData == null) return;
    final muhurta = await container.read(muhurtaProvider.future);
    final settings = container.read(appSettingsProvider);
    final location = container.read(effectiveLocationProvider);
    final date = container.read(selectedDateProvider);
    await WidgetDataService.update(
      dayData: dayData,
      muhurta: muhurta,
      settings: settings,
      tzOffset: location.tzOffsetAt(date),
    );
  } catch (_) {}
}

Future<void> _precacheMoonImage() async {
  final completer = Completer<void>();
  final stream = const AssetImage('assets/moon_circle.png')
      .resolve(ImageConfiguration.empty);
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (_, __) { stream.removeListener(listener); completer.complete(); },
    onError: (_, __) { stream.removeListener(listener); completer.complete(); },
  );
  stream.addListener(listener);
  return completer.future;
}

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  tz.initializeTimeZones();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await NotificationService.initialize();

  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  // Pre-warm ephemeris, city database, and moon image in parallel.
  // Timeout guards against a silent hang in Sweph.init() on some simulators.
  await Future.wait([
    container.read(ephemerisServiceProvider.future),
    container.read(citySearchServiceProvider.future),
    _precacheMoonImage(),
  ]).timeout(const Duration(seconds: 15), onTimeout: () => []);

  // Pre-warm festival list for the current year (and next year in December)
  // so the festivals screen loads instantly on first visit.
  unawaited(() async {
    try {
      final now = DateTime.now();
      await container.read(yearFestivalsProvider(now.year).future);
      if (now.month == 12) {
        await container.read(yearFestivalsProvider(now.year + 1).future);
      }
    } catch (_) {}
  }());

  // Check if the weekly notification window has expired; reschedule if so.
  // Re-arms the in-memory timer if the process was restarted mid-week.
  unawaited(() async {
    try {
      final settings = container.read(appSettingsProvider);
      if (settings.notificationSettings.enabled) {
        final tithiSvc =
            await container.read(tithiServiceProvider.future);
        await NotificationService.checkAndRescheduleIfDue(
          settings: settings.notificationSettings,
          appSettings: settings,
          tithiService: tithiSvc,
          prefs: prefs,
        );
      }
    } catch (e, st) {
      // Never swallow this silently: a throw here means no notifications get
      // scheduled at all, and an empty `catch` hid exactly that failure mode
      // through several rounds of debugging.
      debugPrint('checkAndRescheduleIfDue failed: $e\n$st');
    }
  }());

  // Refresh Android home-screen widget data after providers resolve.
  unawaited(_refreshWidget(container));
  await Future.delayed(const Duration(seconds: 1));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TithikaApp(),
    ),
  );
}

class TithikaApp extends ConsumerStatefulWidget {
  const TithikaApp({super.key});

  @override
  ConsumerState<TithikaApp> createState() => _TithikaAppState();
}

class _TithikaAppState extends ConsumerState<TithikaApp>
    with WidgetsBindingObserver {
  GoRouter? _router;
  bool _checkedForUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Asks the store whether a newer build exists, once per launch, after the
  /// first frame so it never delays startup.
  ///
  /// On Android this is a no-op from the app's perspective: Play runs its own
  /// background-download flow, including the defer affordance. On iOS there is
  /// no such API, so a version is returned and the app shows its own dialog
  /// offering "Later" or a link to the App Store.
  Future<void> _maybePromptForUpdate() async {
    final update = await UpdateService.checkForUpdate();
    if (update == null || !mounted) return;
    UpdateService.markPrompted();

    final colors = TithikaColors.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.panel,
        title: const Text('Update available'),
        content: Text(
          'Version ${update.version} is available on the App Store.',
          style: TextStyle(color: colors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          if (update.storeUrl != null)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                unawaited(launchUrl(
                  Uri.parse(update.storeUrl!),
                  mode: LaunchMode.externalApplication,
                ));
              },
              child: Text('Update', style: TextStyle(color: colors.shukla)),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final container = ProviderScope.containerOf(context, listen: false);
      unawaited(_refreshWidget(container));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dismiss the native splash after the first Flutter frame is painted,
    // so there is no blank-screen gap between splash and app content.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      // Once per launch, after the first frame — never delays startup.
      if (!_checkedForUpdate) {
        _checkedForUpdate = true;
        unawaited(_maybePromptForUpdate());
      }
    });
    // Router is created once on first build (ref.listen is only valid in build).
    // Subsequent rebuilds reuse the cached instance, preventing nav reset.
    _router ??= buildRouter(ref);
    final themeMode = ref.watch(appSettingsProvider).theme.themeMode;
    return MaterialApp.router(
      title: 'Tithika',
      debugShowCheckedModeBanner: false,
      theme:      buildTithikaTheme(Brightness.light),
      darkTheme:  buildTithikaTheme(Brightness.dark),
      themeMode:  themeMode,
      routerConfig: _router!,
    );
  }
}
