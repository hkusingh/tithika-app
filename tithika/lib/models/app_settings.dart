import 'app_location.dart';

enum AppLanguage { english, hindiLatin, hindiDevanagari }

enum MonthSystem { purnimanta, amanta }

class AppSettings {
  final AppLocation? location;
  final AppLanguage language;
  final MonthSystem monthSystem;

  const AppSettings({
    this.location,
    this.language = AppLanguage.english,
    this.monthSystem = MonthSystem.purnimanta,
  });

  bool get hasLocation => location != null;

  AppSettings copyWith({
    AppLocation? location,
    bool clearLocation = false,
    AppLanguage? language,
    MonthSystem? monthSystem,
  }) {
    return AppSettings(
      location: clearLocation ? null : (location ?? this.location),
      language: language ?? this.language,
      monthSystem: monthSystem ?? this.monthSystem,
    );
  }
}
