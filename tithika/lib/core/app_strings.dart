import '../models/app_settings.dart';
import '../models/paksha.dart';

/// Central string localisation hub.
///
/// Every UI label that varies by language lives here.
/// Adding a new language = one new case per switch + one new data list.
/// No other files need to change.
abstract final class AppStrings {
  // ── Weekdays (DateTime.weekday: 1=Mon .. 7=Sun) ───────────────────────

  static String weekdayFull(int weekday, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _weekdayFullDeva[weekday - 1],
        _ => _weekdayFullEn[weekday - 1],
      };

  static String weekdayShort(int weekday, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _weekdayShortDeva[weekday - 1],
        _ => _weekdayShortEn[weekday - 1],
      };

  /// Sunday-first index (0=Sun .. 6=Sat) — for calendar grid column headers.
  static String weekdayLetter(int sundayFirst, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _weekdayLetterDeva[sundayFirst],
        _ => _weekdayLetterEn[sundayFirst],
      };

  // ── Gregorian months (1-based) ────────────────────────────────────────

  static String gregMonth(int month, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _gregMonthDeva[month - 1],
        _ => _gregMonthEn[month - 1],
      };

  static String gregMonthShort(int month, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _gregMonthShortDeva[month - 1],
        _ => _gregMonthShortEn[month - 1],
      };

  // ── Paksha ────────────────────────────────────────────────────────────

  /// All-caps form used in the lunar month line (e.g. "SHUKLA PAKSHA").
  static String pakshaUpper(Paksha p, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => p == Paksha.shukla ? 'शुक्ल' : 'कृष्ण',
        _ => p == Paksha.shukla ? 'SHUKLA' : 'KRISHNA',
      };

  /// Title-case form used in detail rows (e.g. "Shukla 5").
  static String paksha(Paksha p, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => p == Paksha.shukla ? 'शुक्ल' : 'कृष्ण',
        _ => p == Paksha.shukla ? 'Shukla' : 'Krishna',
      };

  /// The word "Paksha" / "पक्ष" used as a suffix.
  static String pakshaWord(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'पक्ष',
        _ => 'PAKSHA',
      };

  // ── Labels ────────────────────────────────────────────────────────────

  static String adhikaPrefix(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अधिक ',
        _ => 'ADHIKA ',
      };

  static String adhikaPrefixShort(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अधिक ',
        _ => 'ADH. ',
      };

  static String nakshatra(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'नक्षत्र',
        _ => 'NAKSHATRA',
      };

  static String sunrise(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'सूर्योदय',
        _ => 'SUNRISE',
      };

  static String sunset(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'सूर्यास्त',
        _ => 'SUNSET',
      };

  static String festivals(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'पर्व',
        _ => 'FESTIVALS',
      };

  static String ekadashi(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'एकादशी',
        _ => 'Ekadashi',
      };

  static String purnima(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'पूर्णिमा',
        _ => 'Purnima',
      };

  static String amavasya(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अमावस्या',
        _ => 'Amavasya',
      };

  // ── Sentence templates ────────────────────────────────────────────────

  static String nakshatraUntil(String time, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'तक $time',
        _ => 'until $time',
      };

  static String hinduMonthBegins(
    String monthName,
    String weekday,
    String month,
    int day,
    String time,
    AppLanguage lang,
  ) =>
      switch (lang) {
        AppLanguage.hindiDevanagari =>
          '$monthName $weekday, $month $day को $time से',
        _ => '$monthName begins $weekday, $month $day at $time',
      };

  static String secondaryTithiBegins(
    String name,
    String time,
    AppLanguage lang,
  ) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => '· $name $time से',
        _ => '· $name begins $time',
      };

  // ── Data ──────────────────────────────────────────────────────────────

  static const _weekdayFullEn = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY',
  ];
  static const _weekdayFullDeva = [
    'सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार',
  ];
  static const _weekdayShortEn   = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _weekdayShortDeva = ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'];
  // Sunday-first (0=Sun .. 6=Sat):
  static const _weekdayLetterEn   = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _weekdayLetterDeva = ['र', 'सो', 'मं', 'बु', 'गु', 'शु', 'श'];

  static const _gregMonthEn = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
  ];
  static const _gregMonthDeva = [
    'जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
    'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर',
  ];
  static const _gregMonthShortEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _gregMonthShortDeva = [
    'जन', 'फर', 'मार्च', 'अप्र', 'मई', 'जून',
    'जुल', 'अग', 'सित', 'अक्त', 'नव', 'दिस',
  ];
}
