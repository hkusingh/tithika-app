import '../models/app_settings.dart';
import '../models/muhurta_data.dart';
import '../models/paksha.dart';
import '../models/pancha_data.dart';

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

  static String ekadashiIntro(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari =>
          'एकादशी प्रत्येक पक्ष के ग्यारहवें दिन पड़ती है — अर्थात महीने में दो बार। यह उपवास, प्रार्थना और भगवान विष्णु की भक्ति के लिए सबसे पवित्र दिनों में से एक है। एकादशी का व्रत मन को शुद्ध करता है और आध्यात्मिक पुण्य अर्जित करता है।',
        AppLanguage.tamil =>
          'ஏகாதசி ஒவ்வொரு சந்திர பக்கத்தின் பதினோராம் நாளில் வருகிறது — மாதத்தில் இருமுறை. இது உபவாசம், வழிபாடு மற்றும் திருமால் பக்திக்கான மிகவும் புனிதமான நாட்களில் ஒன்றாகும். ஏகாதசி விரதம் மனதை தூய்மைப்படுத்தி ஆன்மீக புண்ணியம் சேர்க்கும்.',
        AppLanguage.bengali =>
          'একাদশী প্রতিটি চন্দ্র পক্ষের একাদশ দিনে পড়ে — মাসে দুইবার। এটি উপবাস, প্রার্থনা এবং ভগবান বিষ্ণুর ভক্তির জন্য সবচেয়ে পবিত্র দিনগুলির মধ্যে একটি। একাদশী পালন মনকে শুদ্ধ করে এবং আধ্যাত্মিক পুণ্য অর্জন করে।',
        _ =>
          'Ekadashi falls on the 11th day of each lunar fortnight — twice a month. It is one of the most auspicious days for fasting, prayer, and devotion to Lord Vishnu. Observing Ekadashi is believed to purify the mind and accumulate spiritual merit.',
      };

  static String about(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'विवरण',
        AppLanguage.tamil           => 'விவரம்',
        AppLanguage.bengali         => 'বিবরণ',
        _                           => 'ABOUT',
      };

  static String howToObserve(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'कैसे मनाएँ',
        AppLanguage.tamil           => 'எப்படி கொண்டாடுவது',
        AppLanguage.bengali         => 'কীভাবে পালন করবেন',
        _                           => 'HOW TO OBSERVE',
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

  /// Title-case "Hora" for PageTitleBar (distinct from all-caps HORA label).
  static String horaPageTitle(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'होरा',
        AppLanguage.tamil           => 'ஹோரா',
        AppLanguage.bengali         => 'হোরা',
        _ => 'Hora',
      };

  /// Title-case "Festivals" for PageTitleBar.
  static String festivalsPageTitle(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'त्योहार',
        AppLanguage.tamil           => 'விழாக்கள்',
        AppLanguage.bengali         => 'উৎসব',
        _ => 'Festivals',
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

  // ── Muhurta ───────────────────────────────────────────────────────────────

  static String muhurta(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'मुहूर्त',
        AppLanguage.tamil           => 'முகூர்த்தம்',
        AppLanguage.bengali         => 'মুহূর্ত',
        _ => 'Muhurta',
      };

  static String sectionAuspicious(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'शुभ',
        AppLanguage.tamil           => 'சுபம்',
        AppLanguage.bengali         => 'শুভ',
        _ => 'Auspicious',
      };

  static String sectionInauspicious(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अशुभ',
        AppLanguage.tamil           => 'அசுபம்',
        AppLanguage.bengali         => 'অশুভ',
        _ => 'Inauspicious',
      };

  static String brahmaMuhurta(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'ब्रह्म मुहूर्त',
        AppLanguage.tamil           => 'பிரம்ம முகூர்த்தம்',
        AppLanguage.bengali         => 'ব্রহ্ম মুহূর্ত',
        _ => 'Brahma Muhurta',
      };

  static String brahmaMuhurtaSub(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'ध्यान और पूजा',
        AppLanguage.tamil           => 'தியானம் மற்றும் வழிபாடு',
        AppLanguage.bengali         => 'ধ্যান ও পূজা',
        _ => 'meditation & prayer',
      };

  static String abhijitMuhurta(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अभिजित् मुहूर्त',
        AppLanguage.tamil           => 'அபிஜித் முகூர்த்தம்',
        AppLanguage.bengali         => 'অভিজিৎ মুহূর্ত',
        _ => 'Abhijit Muhurta',
      };

  static String abhijitMuhurtaSub(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'सर्वाधिक शुभ समय',
        AppLanguage.tamil           => 'மிகவும் சுபகரமான நேரம்',
        AppLanguage.bengali         => 'সবচেয়ে শুভ সময়',
        _ => 'most auspicious window',
      };

  static String abhijitNotObserved(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'बुधवार को नहीं होता',
        AppLanguage.tamil           => 'புதன்கிழமை கொண்டாடப்படுவதில்லை',
        AppLanguage.bengali         => 'বুধবারে পালিত হয় না',
        _ => 'not observed on Wednesday',
      };

  static String rahuKaal(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'राहु काल',
        AppLanguage.tamil           => 'ராகு காலம்',
        AppLanguage.bengali         => 'রাহু কাল',
        _ => 'Rahu Kaal',
      };

  static String yamaganda(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'यमगण्ड',
        AppLanguage.tamil           => 'யமகண்டம்',
        AppLanguage.bengali         => 'যমগণ্ড',
        _ => 'Yamaganda',
      };

  static String gulika(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'गुलिक',
        AppLanguage.tamil           => 'குலிகன்',
        AppLanguage.bengali         => 'গুলিক',
        _ => 'Gulika',
      };

  static String avoidNewStarts(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'नए काम न करें',
        AppLanguage.tamil           => 'புதிய தொடக்கங்களை தவிர்க்கவும்',
        AppLanguage.bengali         => 'নতুন কাজ এড়িয়ে চলুন',
        _ => 'avoid new starts',
      };

  static String dayChoghadiya(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'दिन का चौघड़िया',
        AppLanguage.tamil           => 'பகல் சோகடியா',
        AppLanguage.bengali         => 'দিনের চৌঘড়িয়া',
        _ => 'Day Choghadiya',
      };

  static String nightChoghadiya(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'रात का चौघड़िया',
        AppLanguage.tamil           => 'இரவு சோகடியா',
        AppLanguage.bengali         => 'রাতের চৌঘড়িয়া',
        _ => 'Night Choghadiya',
      };

  static String nightChoghadiyaExpand(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => '▸ विस्तार करें',
        AppLanguage.tamil           => '▸ விரிவாக்கு',
        AppLanguage.bengali         => '▸ বিস্তার করুন',
        _ => '▸ expand',
      };

  static String nightChoghadiyaCollapse(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => '▾ छुपाएं',
        AppLanguage.tamil           => '▾ மறை',
        AppLanguage.bengali         => '▾ লুকান',
        _ => '▾ collapse',
      };

  static String muhurtaCardTitle(AppLanguage lang) => muhurta(lang);

  static String labelNow(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अभी',
        AppLanguage.tamil           => 'இப்போது',
        AppLanguage.bengali         => 'এখন',
        _ => 'NOW',
      };

  // ── Choghadiya type names ─────────────────────────────────────────────────

  static String choghadiyaName(ChoghadiyaType type, AppLanguage lang) =>
      switch (type) {
        ChoghadiyaType.amrit => _chogNameAmrit(lang),
        ChoghadiyaType.shubh => _chogNameShubh(lang),
        ChoghadiyaType.labh  => _chogNameLabh(lang),
        ChoghadiyaType.char  => _chogNameChar(lang),
        ChoghadiyaType.udveg => _chogNameUdveg(lang),
        ChoghadiyaType.kaal  => _chogNameKaal(lang),
        ChoghadiyaType.rog   => _chogNameRog(lang),
      };

  static String _chogNameAmrit(AppLanguage lang) => switch (lang) {
    AppLanguage.hindiDevanagari => 'अमृत',
    AppLanguage.tamil           => 'அமிர்தம்',
    AppLanguage.bengali         => 'অমৃত',
    _ => 'Amrit',
  };
  static String _chogNameShubh(AppLanguage lang) => switch (lang) {
    AppLanguage.hindiDevanagari => 'शुभ',
    AppLanguage.tamil           => 'சுபம்',
    AppLanguage.bengali         => 'শুভ',
    _ => 'Shubh',
  };
  static String _chogNameLabh(AppLanguage lang) => switch (lang) {
    AppLanguage.hindiDevanagari => 'लाभ',
    AppLanguage.tamil           => 'லாபம்',
    AppLanguage.bengali         => 'লাভ',
    _ => 'Labh',
  };
  static String _chogNameChar(AppLanguage lang) => switch (lang) {
    AppLanguage.hindiDevanagari => 'चर',
    AppLanguage.tamil           => 'சரம்',
    AppLanguage.bengali         => 'চর',
    _ => 'Char',
  };
  static String _chogNameUdveg(AppLanguage lang) => switch (lang) {
    AppLanguage.hindiDevanagari => 'उद्वेग',
    AppLanguage.tamil           => 'உத்வேகம்',
    AppLanguage.bengali         => 'উদ্বেগ',
    _ => 'Udveg',
  };
  static String _chogNameKaal(AppLanguage lang) => switch (lang) {
    AppLanguage.hindiDevanagari => 'काल',
    AppLanguage.tamil           => 'காலம்',
    AppLanguage.bengali         => 'কাল',
    _ => 'Kaal',
  };
  static String _chogNameRog(AppLanguage lang) => switch (lang) {
    AppLanguage.hindiDevanagari => 'रोग',
    AppLanguage.tamil           => 'ரோகம்',
    AppLanguage.bengali         => 'রোগ',
    _ => 'Rog',
  };

  // ── Choghadiya quality labels ─────────────────────────────────────────────

  static String choghadiyaQuality(ChoghadiyaType type, AppLanguage lang) =>
      switch (type) {
        ChoghadiyaType.amrit => qualityExcellent(lang),
        ChoghadiyaType.shubh => qualityAuspicious(lang),
        ChoghadiyaType.labh  => qualityProfitable(lang),
        ChoghadiyaType.char  => qualityNeutral(lang),
        ChoghadiyaType.udveg => qualityInauspicious(lang),
        ChoghadiyaType.kaal  => qualityInauspicious(lang),
        ChoghadiyaType.rog   => qualityInauspicious(lang),
      };

  static String qualityExcellent(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'सर्वश्रेष्ठ',
        AppLanguage.tamil           => 'சிறந்தது',
        AppLanguage.bengali         => 'চমৎকার',
        _ => 'excellent',
      };

  static String qualityAuspicious(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'शुभ',
        AppLanguage.tamil           => 'சுபகரமான',
        AppLanguage.bengali         => 'শুভ',
        _ => 'auspicious',
      };

  static String qualityProfitable(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'लाभदायक',
        AppLanguage.tamil           => 'இலாபகரமான',
        AppLanguage.bengali         => 'লাভজনক',
        _ => 'profitable',
      };

  static String qualityNeutral(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'सामान्य',
        AppLanguage.tamil           => 'நடுநிலை',
        AppLanguage.bengali         => 'নিরপেক্ষ',
        _ => 'neutral',
      };

  static String qualityInauspicious(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अशुभ',
        AppLanguage.tamil           => 'அசுபகரமான',
        AppLanguage.bengali         => 'অশুভ',
        _ => 'inauspicious',
      };

  // ── Panchanga ─────────────────────────────────────────────────────────────

  static String panchaTitle(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'पंचांग',
        AppLanguage.tamil           => 'பஞ்சாங்கம்',
        AppLanguage.bengali         => 'পঞ্চাঙ্গ',
        _ => 'Panchanga',
      };

  static String fiveElementsLabel(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'पंच तत्त्व',
        AppLanguage.tamil           => 'ஐந்து அங்கங்கள்',
        AppLanguage.bengali         => 'পঞ্চতত্ত্ব',
        _ => 'Five Elements',
      };

  static String varaLabel(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'वार',
        AppLanguage.tamil           => 'வாரம்',
        AppLanguage.bengali         => 'বার',
        _ => 'Vara',
      };

  static String tithiLabel(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'तिथि',
        AppLanguage.tamil           => 'திதி',
        AppLanguage.bengali         => 'তিথি',
        _ => 'Tithi',
      };

  static String nakshatraLabel(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'नक्षत्र',
        AppLanguage.tamil           => 'நட்சத்திரம்',
        AppLanguage.bengali         => 'নক্ষত্র',
        _ => 'Nakshatra',
      };

  /// Title-case weekday name for display in the Five Elements card.
  static String weekdayTitle(int weekday, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _weekdayFullDeva[weekday - 1],
        AppLanguage.tamil           => _weekdayFullTamil[weekday - 1],
        AppLanguage.bengali         => _weekdayFullBengali[weekday - 1],
        _ => _weekdayTitleEn[weekday - 1],
      };

  /// Sanskrit vara name · ruling planet sub-line for the Five Elements card.
  static String varaRulerSub(int weekday, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _varaRulerSubDeva[weekday - 1],
        AppLanguage.tamil           => _varaRulerSubTamil[weekday - 1],
        AppLanguage.bengali         => _varaRulerSubBengali[weekday - 1],
        _ => _varaRulerSubEn[weekday - 1],
      };

  static String avoidNewBeginnings(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'नई शुरुआत न करें',
        AppLanguage.tamil           => 'புதிய தொடக்கங்களை தவிர்க்கவும்',
        AppLanguage.bengali         => 'নতুন সূচনা এড়িয়ে চলুন',
        _ => 'avoid new beginnings',
      };

  // ── Yoga ─────────────────────────────────────────────────────────────────

  static String yogaName(int number, AppLanguage lang) {
    assert(number >= 1 && number <= 27);
    return switch (lang) {
      AppLanguage.hindiDevanagari => _yogaNamesDeva[number - 1],
      AppLanguage.tamil           => _yogaNamesTamil[number - 1],
      AppLanguage.bengali         => _yogaNamesBengali[number - 1],
      _ => _yogaNamesEn[number - 1],
    };
  }

  static String yogaQualityLabel(YogaQuality q, AppLanguage lang) =>
      switch (q) {
        YogaQuality.excellent    => qualityExcellent(lang),
        YogaQuality.auspicious   => qualityAuspicious(lang),
        YogaQuality.neutral      => qualityNeutral(lang),
        YogaQuality.inauspicious => qualityInauspicious(lang),
      };

  static String yogaLabel(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'योग',
        AppLanguage.tamil           => 'யோகம்',
        AppLanguage.bengali         => 'যোগ',
        _ => 'Yoga',
      };

  static String nextYogaLabel(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अगला',
        AppLanguage.tamil           => 'அடுத்து',
        AppLanguage.bengali         => 'পরবর্তী',
        _ => 'Next',
      };

  static const _yogaNamesEn = [
    'Vishkambha', 'Priti',    'Ayushman', 'Saubhagya', 'Shobhana',
    'Atiganda',   'Sukarma',  'Dhriti',   'Shula',     'Ganda',
    'Vriddhi',    'Dhruva',   'Vyaghata', 'Harshana',  'Vajra',
    'Siddhi',     'Vyatipata','Variyan',  'Parigha',   'Shiva',
    'Siddha',     'Sadhya',   'Shubha',   'Shukla',    'Brahma',
    'Indra',      'Vaidhriti',
  ];

  static const _yogaNamesDeva = [
    'विष्कम्भ', 'प्रीति',   'आयुष्मान', 'सौभाग्य', 'शोभन',
    'अतिगण्ड',  'सुकर्मा', 'धृति',     'शूल',     'गण्ड',
    'वृद्धि',   'ध्रुव',   'व्याघात',  'हर्षण',   'वज्र',
    'सिद्धि',   'व्यतीपात','वरीयान्',  'परिघ',    'शिव',
    'सिद्ध',    'साध्य',   'शुभ',      'शुक्ल',   'ब्रह्म',
    'इन्द्र',   'वैधृति',
  ];

  static const _yogaNamesTamil = [
    'விஷ்கம்பம்', 'பிரீதி',     'ஆயுஷ்மான்', 'சௌபாக்கியம்', 'சோபனம்',
    'அதிகண்டம்',  'சுகர்மம்',  'திருதி',    'சூலம்',       'கண்டம்',
    'விருத்தி',   'த்ருவம்',   'வியாகாதம்', 'ஹர்ஷணம்',    'வஜ்ரம்',
    'சித்தி',     'வியதீபாதம்','வரீயான்',   'பரிகம்',      'சிவம்',
    'சித்தம்',    'சாத்தியம்', 'சுபம்',     'சுக்லம்',     'பிரம்மம்',
    'இந்திரம்',   'வைத்ருதி',
  ];

  static const _yogaNamesBengali = [
    'বিষ্কম্ভ', 'প্রীতি',   'আয়ুষ্মান', 'সৌভাগ্য', 'শোভন',
    'অতিগণ্ড',  'সুকর্মা', 'ধৃতি',     'শূল',     'গণ্ড',
    'বৃদ্ধি',   'ধ্রুব',   'ব্যাঘাত',  'হর্ষণ',   'বজ্র',
    'সিদ্ধি',   'ব্যতীপাত','বরীয়ান্',  'পরিঘ',    'শিব',
    'সিদ্ধ',    'সাধ্য',   'শুভ',      'শুক্ল',   'ব্রহ্ম',
    'ইন্দ্র',   'বৈধৃতি',
  ];

  // ── Karana ────────────────────────────────────────────────────────────────

  static String karanaName(KaranaType type, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _karanaNameDeva(type),
        AppLanguage.tamil           => _karanaNameTamil(type),
        AppLanguage.bengali         => _karanaNameBengali(type),
        _ => _karanaNameEn(type),
      };

  static String karanaQuality(KaranaType type, AppLanguage lang) =>
      type.isInauspicious
          ? qualityInauspicious(lang)
          : type.isFixed
              ? qualityNeutral(lang)
              : qualityAuspicious(lang);

  static String karanaLabel(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'करण',
        AppLanguage.tamil           => 'கரணம்',
        AppLanguage.bengali         => 'করণ',
        _ => 'Karana',
      };

  static String _karanaNameEn(KaranaType t) => switch (t) {
    KaranaType.bava         => 'Bava',
    KaranaType.balava       => 'Balava',
    KaranaType.kaulava      => 'Kaulava',
    KaranaType.taitila      => 'Taitila',
    KaranaType.gara         => 'Gara',
    KaranaType.vanija       => 'Vanija',
    KaranaType.vishti       => 'Vishti',
    KaranaType.shakuni      => 'Shakuni',
    KaranaType.chatushpada  => 'Chatushpada',
    KaranaType.naga         => 'Naga',
    KaranaType.kimstughna   => 'Kimstughna',
  };

  static String _karanaNameDeva(KaranaType t) => switch (t) {
    KaranaType.bava         => 'बव',
    KaranaType.balava       => 'बालव',
    KaranaType.kaulava      => 'कौलव',
    KaranaType.taitila      => 'तैतिल',
    KaranaType.gara         => 'गर',
    KaranaType.vanija       => 'वणिज',
    KaranaType.vishti       => 'विष्टि',
    KaranaType.shakuni      => 'शकुनि',
    KaranaType.chatushpada  => 'चतुष्पाद',
    KaranaType.naga         => 'नाग',
    KaranaType.kimstughna   => 'किंस्तुघ्न',
  };

  static String _karanaNameTamil(KaranaType t) => switch (t) {
    KaranaType.bava         => 'பவம்',
    KaranaType.balava       => 'பாலவம்',
    KaranaType.kaulava      => 'கௌலவம்',
    KaranaType.taitila      => 'தைதிலம்',
    KaranaType.gara         => 'கரஜம்',
    KaranaType.vanija       => 'வணிஜம்',
    KaranaType.vishti       => 'விஷ்டி',
    KaranaType.shakuni      => 'சகுனி',
    KaranaType.chatushpada  => 'சதுஷ்பாதம்',
    KaranaType.naga         => 'நாகம்',
    KaranaType.kimstughna   => 'கிம்ஸ்துக்னம்',
  };

  static String _karanaNameBengali(KaranaType t) => switch (t) {
    KaranaType.bava         => 'বব',
    KaranaType.balava       => 'বালব',
    KaranaType.kaulava      => 'কৌলব',
    KaranaType.taitila      => 'তৈতিল',
    KaranaType.gara         => 'গর',
    KaranaType.vanija       => 'বণিজ',
    KaranaType.vishti       => 'বিষ্টি',
    KaranaType.shakuni      => 'শকুনি',
    KaranaType.chatushpada  => 'চতুষ্পাদ',
    KaranaType.naga         => 'নাগ',
    KaranaType.kimstughna   => 'কিংস্তুঘ্ন',
  };

  // ── Five Elements data ────────────────────────────────────────────────────

  static const _weekdayTitleEn = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static const _varaRulerSubEn = [
    'Somavara · Moon',
    'Mangalavara · Mars',
    'Budhavara · Mercury',
    'Guruvara · Jupiter',
    'Shukravara · Venus',
    'Shanivara · Saturn',
    'Ravivara · Sun',
  ];

  static const _varaRulerSubDeva = [
    'सोमवार · चंद्र',
    'मंगलवार · मंगल',
    'बुधवार · बुध',
    'गुरुवार · गुरु',
    'शुक्रवार · शुक्र',
    'शनिवार · शनि',
    'रविवार · रवि',
  ];

  static const _varaRulerSubTamil = [
    'சோமவாரம் · சந்திரன்',
    'மங்கலவாரம் · செவ்வாய்',
    'புதன்வாரம் · புதன்',
    'குருவாரம் · வியாழன்',
    'சுக்கிரவாரம் · வெள்ளி',
    'சனிவாரம் · சனி',
    'ஞாயிற்றுக்கிழமை · சூரியன்',
  ];

  static const _varaRulerSubBengali = [
    'সোমবার · চন্দ্র',
    'মঙ্গলবার · মঙ্গল',
    'বুধবার · বুধ',
    'বৃহস্পতিবার · বৃহস্পতি',
    'শুক্রবার · শুক্র',
    'শনিবার · শনি',
    'রবিবার · রবি',
  ];
}
