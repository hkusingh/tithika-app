import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_location.dart';
import '../models/app_settings.dart';

const _keyLocation = 'location';
const _keyLanguage = 'language';
const _keyMonthSystem = 'monthSystem';
const _keyTheme = 'theme';
const _keyNotifEnabled = 'notif_enabled';
const _keyNotifDailyEnabled = 'notif_daily_enabled';
const _keyNotifDailyHour = 'notif_daily_hour';
const _keyNotifDailyMinute = 'notif_daily_minute';
const _keyNotifFestival = 'notif_festival';
const _keyNotifEkadashi = 'notif_ekadashi';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  AppSettings load() {
    return AppSettings(
      location: AppLocation.tryDecode(_prefs.getString(_keyLocation)),
      language: AppLanguage.values[_prefs.getInt(_keyLanguage) ?? 0],
      monthSystem: MonthSystem.values[_prefs.getInt(_keyMonthSystem) ?? 0],
      theme: AppTheme.values[_prefs.getInt(_keyTheme) ?? 0],
      notificationSettings: NotificationSettings(
        enabled: _prefs.getBool(_keyNotifEnabled) ?? false,
        dailyReminderEnabled:
            _prefs.getBool(_keyNotifDailyEnabled) ?? true,
        dailyReminderHour: _prefs.getInt(_keyNotifDailyHour) ?? 7,
        dailyReminderMinute: _prefs.getInt(_keyNotifDailyMinute) ?? 0,
        festivalAlertsEnabled: _prefs.getBool(_keyNotifFestival) ?? true,
        ekadashiAlertsEnabled: _prefs.getBool(_keyNotifEkadashi) ?? true,
      ),
    );
  }

  Future<void> saveLocation(AppLocation? location) async {
    if (location == null) {
      await _prefs.remove(_keyLocation);
    } else {
      await _prefs.setString(_keyLocation, location.encode());
    }
  }

  Future<void> saveLanguage(AppLanguage language) async {
    await _prefs.setInt(_keyLanguage, language.index);
  }

  Future<void> saveMonthSystem(MonthSystem monthSystem) async {
    await _prefs.setInt(_keyMonthSystem, monthSystem.index);
  }

  Future<void> saveTheme(AppTheme theme) async {
    await _prefs.setInt(_keyTheme, theme.index);
  }

  Future<void> saveNotificationSettings(NotificationSettings s) async {
    await _prefs.setBool(_keyNotifEnabled, s.enabled);
    await _prefs.setBool(_keyNotifDailyEnabled, s.dailyReminderEnabled);
    await _prefs.setInt(_keyNotifDailyHour, s.dailyReminderHour);
    await _prefs.setInt(_keyNotifDailyMinute, s.dailyReminderMinute);
    await _prefs.setBool(_keyNotifFestival, s.festivalAlertsEnabled);
    await _prefs.setBool(_keyNotifEkadashi, s.ekadashiAlertsEnabled);
  }
}
