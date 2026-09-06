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
// Retains its original key: the stored value carries over on upgrade, only
// its meaning widens from "festival alerts on/off" to "all festivals".
const _keyNotifFestival = 'notif_festival';
const _keyNotifEkadashi = 'notif_ekadashi';
const _keyNotifPurnima = 'notif_purnima';
const _keyNotifAmavasya = 'notif_amavasya';
const _keyNotifSelFests = 'notif_selected_festivals';
const _keyNotifAlertDays = 'notif_alert_days';
const _keyNotifAlertHour = 'notif_alert_hour';
const _keyNotifAlertMinute = 'notif_alert_minute';

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
        purnimaAlertsEnabled: _prefs.getBool(_keyNotifPurnima) ?? true,
        amavasyaAlertsEnabled: _prefs.getBool(_keyNotifAmavasya) ?? true,
        selectedFestivals:
            _prefs.getStringList(_keyNotifSelFests)?.toSet() ?? const <String>{},
        // Clamped so a corrupted or future-version pref can't blow out the
        // scheduling lookahead.
        alertDaysBefore: (_prefs.getInt(_keyNotifAlertDays) ?? 1)
            .clamp(0, maxAlertDaysBefore),
        alertHour: (_prefs.getInt(_keyNotifAlertHour) ?? 6).clamp(0, 23),
        alertMinute: (_prefs.getInt(_keyNotifAlertMinute) ?? 0).clamp(0, 59),
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
    await _prefs.setBool(_keyNotifPurnima, s.purnimaAlertsEnabled);
    await _prefs.setBool(_keyNotifAmavasya, s.amavasyaAlertsEnabled);
    // Stored independently of the master switch, so a master on/off round
    // trip restores the user's individual selection rather than losing it.
    await _prefs.setStringList(
        _keyNotifSelFests, s.selectedFestivals.toList());
    await _prefs.setInt(_keyNotifAlertDays, s.alertDaysBefore);
    await _prefs.setInt(_keyNotifAlertHour, s.alertHour);
    await _prefs.setInt(_keyNotifAlertMinute, s.alertMinute);
  }
}
