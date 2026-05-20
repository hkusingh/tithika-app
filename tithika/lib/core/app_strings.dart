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
        AppLanguage.tamil           => _weekdayFullTamil[weekday - 1],
        AppLanguage.bengali         => _weekdayFullBengali[weekday - 1],
        _ => _weekdayFullEn[weekday - 1],
      };

  static String weekdayShort(int weekday, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _weekdayShortDeva[weekday - 1],
        AppLanguage.tamil           => _weekdayShortTamil[weekday - 1],
        AppLanguage.bengali         => _weekdayShortBengali[weekday - 1],
        _ => _weekdayShortEn[weekday - 1],
      };

  /// Sunday-first index (0=Sun .. 6=Sat) — for calendar grid column headers.
  static String weekdayLetter(int sundayFirst, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _weekdayLetterDeva[sundayFirst],
        AppLanguage.tamil           => _weekdayLetterTamil[sundayFirst],
        AppLanguage.bengali         => _weekdayLetterBengali[sundayFirst],
        _ => _weekdayLetterEn[sundayFirst],
      };

  // ── Gregorian months (1-based) ────────────────────────────────────────

  static String gregMonth(int month, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _gregMonthDeva[month - 1],
        AppLanguage.tamil           => _gregMonthTamil[month - 1],
        AppLanguage.bengali         => _gregMonthBengali[month - 1],
        _ => _gregMonthEn[month - 1],
      };

  static String gregMonthShort(int month, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _gregMonthShortDeva[month - 1],
        AppLanguage.tamil           => _gregMonthShortTamil[month - 1],
        AppLanguage.bengali         => _gregMonthShortBengali[month - 1],
        _ => _gregMonthShortEn[month - 1],
      };

  // ── Paksha ────────────────────────────────────────────────────────────

  /// All-caps form used in the lunar month line (e.g. "SHUKLA PAKSHA").
  static String pakshaUpper(Paksha p, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => p == Paksha.shukla ? 'शुक्ल' : 'कृष्ण',
        AppLanguage.tamil           => p == Paksha.shukla ? 'வளர்பிறை' : 'தேய்பிறை',
        AppLanguage.bengali         => p == Paksha.shukla ? 'শুক্ল' : 'কৃষ্ণ',
        _ => p == Paksha.shukla ? 'SHUKLA' : 'KRISHNA',
      };

  /// Title-case form used in detail rows (e.g. "Shukla 5").
  static String paksha(Paksha p, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => p == Paksha.shukla ? 'शुक्ल' : 'कृष्ण',
        AppLanguage.tamil           => p == Paksha.shukla ? 'வளர்பிறை' : 'தேய்பிறை',
        AppLanguage.bengali         => p == Paksha.shukla ? 'শুক্ল' : 'কৃষ্ণ',
        _ => p == Paksha.shukla ? 'Shukla' : 'Krishna',
      };

  /// The word "Paksha" / "பக்ஷம்" used as a suffix.
  static String pakshaWord(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'पक्ष',
        AppLanguage.tamil           => 'பக்ஷம்',
        AppLanguage.bengali         => 'পক্ষ',
        _ => 'PAKSHA',
      };

  // ── Labels ────────────────────────────────────────────────────────────

  static String adhikaPrefix(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अधिक ',
        AppLanguage.tamil           => 'அதிக ',
        AppLanguage.bengali         => 'অধিক ',
        _ => 'ADHIKA ',
      };

  static String adhikaPrefixShort(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अधिक ',
        AppLanguage.tamil           => 'அதிக. ',
        AppLanguage.bengali         => 'অধিক. ',
        _ => 'ADH. ',
      };

  static String nakshatra(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'नक्षत्र',
        AppLanguage.tamil           => 'நட்சத்திரம்',
        AppLanguage.bengali         => 'নক্ষত্র',
        _ => 'NAKSHATRA',
      };

  static String sunrise(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'सूर्योदय',
        AppLanguage.tamil           => 'சூரிய உதயம்',
        AppLanguage.bengali         => 'সূর্যোদয়',
        _ => 'SUNRISE',
      };

  static String sunset(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'सूर्यास्त',
        AppLanguage.tamil           => 'சூரிய அஸ்தமனம்',
        AppLanguage.bengali         => 'সূর্যাস্ত',
        _ => 'SUNSET',
      };

  static String festivals(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'पर्व',
        AppLanguage.tamil           => 'விழாக்கள்',
        AppLanguage.bengali         => 'উৎসব',
        _ => 'FESTIVALS',
      };

  static String ekadashi(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'एकादशी',
        AppLanguage.tamil           => 'ஏகாதசி',
        AppLanguage.bengali         => 'একাদশী',
        _ => 'Ekadashi',
      };

  static String purnima(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'पूर्णिमा',
        AppLanguage.tamil           => 'பவுர்ணமி',
        AppLanguage.bengali         => 'পূর্ণিমা',
        _ => 'Purnima',
      };

  static String amavasya(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अमावस्या',
        AppLanguage.tamil           => 'அமாவாசை',
        AppLanguage.bengali         => 'অমাবস্যা',
        _ => 'Amavasya',
      };

  static String moonrise(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'चंद्रोदय',
        AppLanguage.tamil           => 'சந்திர உதயம்',
        AppLanguage.bengali         => 'চন্দ্রোদয়',
        _ => 'MOONRISE',
      };

  static String moonset(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'चंद्रास्त',
        AppLanguage.tamil           => 'சந்திர அஸ்தமனம்',
        AppLanguage.bengali         => 'চন্দ্রাস্ত',
        _ => 'MOONSET',
      };

  static String hora(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'होरा',
        AppLanguage.tamil           => 'ஹோரா',
        AppLanguage.bengali         => 'হোরা',
        _ => 'HORA',
      };

  static String horaDay(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'दिन',
        AppLanguage.tamil           => 'பகல்',
        AppLanguage.bengali         => 'দিন',
        _ => 'DAY',
      };

  static String horaNight(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'रात',
        AppLanguage.tamil           => 'இரவு',
        AppLanguage.bengali         => 'রাত',
        _ => 'NIGHT',
      };

  static String dayView(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'दिन',
        AppLanguage.tamil           => 'நாள்',
        AppLanguage.bengali         => 'দিন',
        _ => 'DAY',
      };

  /// e.g. "Hour 3 · Day" or "Hour 3 · Night"
  static String horaSubLabel(int n, bool isDay, AppLanguage lang) {
    final period = isDay ? horaDay(lang) : horaNight(lang);
    return switch (lang) {
      AppLanguage.hindiDevanagari => 'घंटा $n · $period',
      AppLanguage.tamil           => 'ஹோரா $n · $period',
      AppLanguage.bengali         => 'ঘণ্টা $n · $period',
      _ => 'Hour $n · $period',
    };
  }

  /// "NOW" indicator on the active hora row.
  static String horaNow(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अभी',
        AppLanguage.tamil           => 'இப்போது',
        AppLanguage.bengali         => 'এখন',
        _ => 'NOW',
      };

  /// Error shown when horaProvider returns an error state.
  static String horaUnavailable(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'होरा उपलब्ध नहीं।',
        AppLanguage.tamil           => 'ஹோரா கிடைக்கவில்லை.',
        AppLanguage.bengali         => 'হোরা পাওয়া যাচ্ছে না।',
        _ => 'Hora unavailable for this date.',
      };

  /// Error shown when sunrise/sunset data is missing.
  static String horaSunriseMissing(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'सूर्योदय डेटा अनुपलब्ध।',
        AppLanguage.tamil           => 'சூரிய உதயம் தகவல் இல்லை.',
        AppLanguage.bengali         => 'সূর্যোদয়ের তথ্য নেই।',
        _ => 'Hora unavailable — sunrise data missing.',
      };

  // ── Sentence templates ────────────────────────────────────────────────

  static String nakshatraUntil(String time, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'तक $time',
        AppLanguage.tamil           => '$time வரை',
        AppLanguage.bengali         => '$time পর্যন্ত',
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
        AppLanguage.tamil   => '$monthName $weekday, $month $day-ல் $time முதல்',
        AppLanguage.bengali => '$monthName শুরু হয় $weekday, $month $day-এ $time থেকে',
        _ => '$monthName begins $weekday, $month $day at $time',
      };

  static String secondaryTithiBegins(
    String name,
    String time,
    AppLanguage lang,
  ) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => '· $name $time से',
        AppLanguage.tamil           => '· $name $time முதல்',
        AppLanguage.bengali         => '· $name $time থেকে',
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

  // ── Tamil ─────────────────────────────────────────────────────────────────
  static const _weekdayFullTamil = [
    'திங்கள்', 'செவ்வாய்', 'புதன்', 'வியாழன்', 'வெள்ளி', 'சனி', 'ஞாயிறு',
  ];
  static const _weekdayShortTamil = [
    'திங்', 'செவ்', 'புத', 'வியா', 'வெள்', 'சனி', 'ஞாயி',
  ];
  // Sunday-first (0=Sun .. 6=Sat):
  static const _weekdayLetterTamil = ['ஞா', 'தி', 'செ', 'பு', 'வி', 'வெ', 'ச'];
  static const _gregMonthTamil = [
    'ஜனவரி', 'பிப்ரவரி', 'மார்ச்', 'ஏப்ரல்', 'மே', 'ஜூன்',
    'ஜூலை', 'ஆகஸ்ட்', 'செப்டம்பர்', 'அக்டோபர்', 'நவம்பர்', 'டிசம்பர்',
  ];
  static const _gregMonthShortTamil = [
    'ஜன', 'பிப்', 'மார்', 'ஏப்.', 'மே', 'ஜூன்',
    'ஜூலை', 'ஆக.', 'செப்.', 'அக்.', 'நவ.', 'டிச.',
  ];

  // ── Bengali ───────────────────────────────────────────────────────────────
  static const _weekdayFullBengali = [
    'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার',
  ];
  static const _weekdayShortBengali = [
    'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি',
  ];
  // Sunday-first (0=Sun .. 6=Sat):
  static const _weekdayLetterBengali = ['র', 'সো', 'ম', 'বু', 'বৃ', 'শু', 'শ'];
  static const _gregMonthBengali = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
  ];
  static const _gregMonthShortBengali = [
    'জান', 'ফেব', 'মার্চ', 'এপ্র', 'মে', 'জুন',
    'জুলাই', 'আগ', 'সেপ', 'অক্ট', 'নভ', 'ডিস',
  ];
}
