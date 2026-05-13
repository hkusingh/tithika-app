import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_location.dart';
import '../models/app_settings.dart';

const _keyLocation = 'location';
const _keyLanguage = 'language';
const _keyMonthSystem = 'monthSystem';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  AppSettings load() {
    return AppSettings(
      location: AppLocation.tryDecode(_prefs.getString(_keyLocation)),
      language: AppLanguage.values[_prefs.getInt(_keyLanguage) ?? 0],
      monthSystem: MonthSystem.values[_prefs.getInt(_keyMonthSystem) ?? 0],
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
}
