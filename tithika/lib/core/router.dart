import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tithika/features/day_view/day_view_screen.dart';
import 'package:tithika/features/festivals/festivals_screen.dart';
import 'package:tithika/features/hora/hora_screen.dart';
import 'package:tithika/features/month_view/month_view_screen.dart';
import 'package:tithika/features/muhurta/muhurta_screen.dart';
import 'package:tithika/features/onboarding/onboarding_screen.dart';
import 'package:tithika/features/panchanga/panchanga_screen.dart';
import 'package:tithika/features/settings/settings_screen.dart';
import 'package:tithika/state/providers.dart';

class Routes {
  Routes._();
  static const onboarding = '/onboarding';
  static const dayView = '/';
  static const monthView = '/month';
  static const settings = '/settings';
  static const festivals = '/festivals';
  static const hora = '/hora';
  static const muhurta = '/muhurta';
  static const panchanga = '/panchanga';
}

/// Builds the router with access to Riverpod so the redirect can read
/// [locationIsSetProvider] to decide whether onboarding is needed.
GoRouter buildRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: Routes.dayView,
    redirect: (context, state) {
      final locationSet = ref.read(locationIsSetProvider);
      final goingToOnboarding = state.matchedLocation == Routes.onboarding;
      if (!locationSet && !goingToOnboarding) return Routes.onboarding;
      if (locationSet && goingToOnboarding) return Routes.dayView;
      return null;
    },
    refreshListenable: _ProviderListenable(ref, locationIsSetProvider),
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.dayView,
        builder: (context, state) => const DayViewScreen(),
        routes: [
          GoRoute(
            path: 'month',
            builder: (context, state) => const MonthViewScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'festivals',
            builder: (context, state) => const FestivalsScreen(),
          ),
          GoRoute(
            path: 'hora',
            builder: (context, state) => const HoraScreen(),
          ),
          GoRoute(
            path: 'muhurta',
            builder: (context, state) => const MuhurtaScreen(),
          ),
          GoRoute(
            path: 'panchanga',
            builder: (context, state) => const PanchaScreen(),
          ),
        ],
      ),
    ],
    // Glance widget taps arrive as glance-action:/CALLBACK?... deep links.
    // Any unrecognised URI falls back to day view rather than crashing.
    errorBuilder: (_, __) => const DayViewScreen(),
  );
}

/// Bridges a Riverpod [Provider] to [Listenable] so GoRouter re-evaluates
/// its redirect whenever [locationIsSetProvider] changes.
class _ProviderListenable<T> extends ChangeNotifier {
  _ProviderListenable(WidgetRef ref, ProviderListenable<T> provider) {
    ref.listen(provider, (prev, next) => notifyListeners());
  }
}
