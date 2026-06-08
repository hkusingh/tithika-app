import 'package:flutter/material.dart';

import 'app_location.dart';
import 'notification_settings.dart';

export 'notification_settings.dart';

enum AppLanguage { english, hindiLatin, hindiDevanagari, tamil, bengali, odia, telugu, malayalam, kannada }

enum MonthSystem { purnimanta, amanta }

/// User-selected appearance preference.
/// [system] follows the device setting; [light] and [dark] are explicit.
enum AppTheme {
  system,
  light,
  dark;

  ThemeMode get themeMode => switch (this) {
    AppTheme.system => ThemeMode.system,
    AppTheme.light  => ThemeMode.light,
    AppTheme.dark   => ThemeMode.dark,
  };
}

class AppSettings {
  final AppLocation? location;
  final AppLanguage language;
  final MonthSystem monthSystem;
  final NotificationSettings notificationSettings;
  final AppTheme theme;

  const AppSettings({
    this.location,
    this.language = AppLanguage.english,
    this.monthSystem = MonthSystem.purnimanta,
    this.notificationSettings = const NotificationSettings(),
    this.theme = AppTheme.system,
  });

  bool get hasLocation => location != null;

  AppSettings copyWith({
    AppLocation? location,
    bool clearLocation = false,
    AppLanguage? language,
    MonthSystem? monthSystem,
    NotificationSettings? notificationSettings,
    AppTheme? theme,
  }) {
    return AppSettings(
      location: clearLocation ? null : (location ?? this.location),
      language: language ?? this.language,
      monthSystem: monthSystem ?? this.monthSystem,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      theme: theme ?? this.theme,
    );
  }
}
