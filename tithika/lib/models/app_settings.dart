import 'app_location.dart';
import 'notification_settings.dart';

export 'notification_settings.dart';

enum AppLanguage { english, hindiLatin, hindiDevanagari, tamil, bengali }

enum MonthSystem { purnimanta, amanta }

class AppSettings {
  final AppLocation? location;
  final AppLanguage language;
  final MonthSystem monthSystem;
  final NotificationSettings notificationSettings;

  const AppSettings({
    this.location,
    this.language = AppLanguage.english,
    this.monthSystem = MonthSystem.purnimanta,
    this.notificationSettings = const NotificationSettings(),
  });

  bool get hasLocation => location != null;

  AppSettings copyWith({
    AppLocation? location,
    bool clearLocation = false,
    AppLanguage? language,
    MonthSystem? monthSystem,
    NotificationSettings? notificationSettings,
  }) {
    return AppSettings(
      location: clearLocation ? null : (location ?? this.location),
      language: language ?? this.language,
      monthSystem: monthSystem ?? this.monthSystem,
      notificationSettings:
          notificationSettings ?? this.notificationSettings,
    );
  }
}
