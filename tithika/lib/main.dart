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
import 'package:tithika/state/providers.dart' show appSettingsProvider;

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

  // Reschedule notifications after ephemeris is warmed up.
  unawaited(() async {
    try {
      final settings = container.read(appSettingsProvider);
      if (settings.notificationSettings.enabled) {
        final tithiSvc =
            await container.read(tithiServiceProvider.future);
        await NotificationService.scheduleAll(
          settings: settings.notificationSettings,
          appSettings: settings,
          tithiService: tithiSvc,
        );
      }
    } catch (_) {}
  }());
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

class _TithikaAppState extends ConsumerState<TithikaApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Router created once — prevents navigation reset when theme changes.
    _router = buildRouter(ref);
  }

  @override
  Widget build(BuildContext context) {
    // Dismiss the native splash after the first Flutter frame is painted,
    // so there is no blank-screen gap between splash and app content.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    final themeMode = ref.watch(appSettingsProvider).theme.themeMode;
    return MaterialApp.router(
      title: 'Tithika',
      debugShowCheckedModeBanner: false,
      theme:      buildTithikaTheme(Brightness.light),
      darkTheme:  buildTithikaTheme(Brightness.dark),
      themeMode:  themeMode,
      routerConfig: _router,
    );
  }
}
