import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_location.dart';
import '../models/app_settings.dart';
import '../services/notification_service.dart';
import '../services/providers.dart';
import 'providers.dart';

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsRepositoryProvider).load();

  Future<void> setLocation(AppLocation? location) async {
    await ref.read(settingsRepositoryProvider).saveLocation(location);
    state = state.copyWith(location: location, clearLocation: location == null);

    if (location != null) {
      final localNow = DateTime.now().toUtc().add(location.tzOffset);
      ref.read(selectedDateProvider.notifier).state =
          DateTime(localNow.year, localNow.month, localNow.day);
    }
    await _rescheduleNotifications();
  }

  Future<void> setLanguage(AppLanguage language) async {
    await ref.read(settingsRepositoryProvider).saveLanguage(language);
    state = state.copyWith(language: language);
  }

  Future<void> setMonthSystem(MonthSystem monthSystem) async {
    await ref.read(settingsRepositoryProvider).saveMonthSystem(monthSystem);
    state = state.copyWith(monthSystem: monthSystem);
  }

  Future<void> setTheme(AppTheme theme) async {
    await ref.read(settingsRepositoryProvider).saveTheme(theme);
    state = state.copyWith(theme: theme);
  }

  Future<void> setNotificationSettings(NotificationSettings settings) async {
    await ref
        .read(settingsRepositoryProvider)
        .saveNotificationSettings(settings);
    state = state.copyWith(notificationSettings: settings);
    await _rescheduleNotifications();
  }

  Future<void> _rescheduleNotifications() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final tithiSvc = await ref.read(tithiServiceProvider.future);
      await NotificationService.scheduleAll(
        settings: state.notificationSettings,
        appSettings: state,
        tithiService: tithiSvc,
        prefs: prefs,
      );
    } catch (_) {}
  }
}
