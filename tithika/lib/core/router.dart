import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tithika/features/day_view/day_view_screen.dart';
import 'package:tithika/features/month_view/month_view_screen.dart';
import 'package:tithika/features/onboarding/onboarding_screen.dart';
import 'package:tithika/features/settings/settings_screen.dart';
import 'package:tithika/state/providers.dart';

class Routes {
  Routes._();
  static const onboarding = '/onboarding';
  static const dayView = '/';
  static const monthView = '/month';
  static const settings = '/settings';
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
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}

/// Bridges a Riverpod [Provider] to [Listenable] so GoRouter re-evaluates
/// its redirect whenever [locationIsSetProvider] changes.
class _ProviderListenable<T> extends ChangeNotifier {
  _ProviderListenable(WidgetRef ref, ProviderListenable<T> provider) {
    ref.listen(provider, (prev, next) => notifyListeners());
  }
}
