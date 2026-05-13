import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_location.dart';
import '../models/app_settings.dart';
import '../services/providers.dart';
import 'providers.dart';

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsRepositoryProvider).load();

  Future<void> setLocation(AppLocation? location) async {
    await ref.read(settingsRepositoryProvider).saveLocation(location);
    state = state.copyWith(location: location, clearLocation: location == null);

    // Reset the selected date to today at the new location's UTC offset so the
    // day view immediately shows the correct local date for that timezone.
    if (location != null) {
      final localNow = DateTime.now().toUtc().add(location.tzOffset);
      ref.read(selectedDateProvider.notifier).state =
          DateTime(localNow.year, localNow.month, localNow.day);
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    await ref.read(settingsRepositoryProvider).saveLanguage(language);
    state = state.copyWith(language: language);
  }

  Future<void> setMonthSystem(MonthSystem monthSystem) async {
    await ref.read(settingsRepositoryProvider).saveMonthSystem(monthSystem);
    state = state.copyWith(monthSystem: monthSystem);
  }
}
