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
        AppLanguage.odia            => _weekdayFullOdia[weekday - 1],
        AppLanguage.telugu          => _weekdayFullTelugu[weekday - 1],
        AppLanguage.malayalam       => _weekdayFullMalayalam[weekday - 1],
        AppLanguage.kannada         => _weekdayFullKannada[weekday - 1],
        _ => _weekdayFullEn[weekday - 1],
      };

  static String weekdayShort(int weekday, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _weekdayShortDeva[weekday - 1],
        AppLanguage.tamil           => _weekdayShortTamil[weekday - 1],
        AppLanguage.bengali         => _weekdayShortBengali[weekday - 1],
        AppLanguage.odia            => _weekdayShortOdia[weekday - 1],
        AppLanguage.telugu          => _weekdayShortTelugu[weekday - 1],
        AppLanguage.malayalam       => _weekdayShortMalayalam[weekday - 1],
        AppLanguage.kannada         => _weekdayShortKannada[weekday - 1],
        _ => _weekdayShortEn[weekday - 1],
      };

  /// Sunday-first index (0=Sun .. 6=Sat) — for calendar grid column headers.
  static String weekdayLetter(int sundayFirst, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _weekdayLetterDeva[sundayFirst],
        AppLanguage.tamil           => _weekdayLetterTamil[sundayFirst],
        AppLanguage.bengali         => _weekdayLetterBengali[sundayFirst],
        AppLanguage.odia            => _weekdayLetterOdia[sundayFirst],
        AppLanguage.telugu          => _weekdayLetterTelugu[sundayFirst],
        AppLanguage.malayalam       => _weekdayLetterMalayalam[sundayFirst],
        AppLanguage.kannada         => _weekdayLetterKannada[sundayFirst],
        _ => _weekdayLetterEn[sundayFirst],
      };

  // ── Gregorian months (1-based) ────────────────────────────────────────

  static String gregMonth(int month, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _gregMonthDeva[month - 1],
        AppLanguage.tamil           => _gregMonthTamil[month - 1],
        AppLanguage.bengali         => _gregMonthBengali[month - 1],
        AppLanguage.odia            => _gregMonthOdia[month - 1],
        AppLanguage.telugu          => _gregMonthTelugu[month - 1],
        AppLanguage.malayalam       => _gregMonthMalayalam[month - 1],
        AppLanguage.kannada         => _gregMonthKannada[month - 1],
        _ => _gregMonthEn[month - 1],
      };

  static String gregMonthShort(int month, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _gregMonthShortDeva[month - 1],
        AppLanguage.tamil           => _gregMonthShortTamil[month - 1],
        AppLanguage.bengali         => _gregMonthShortBengali[month - 1],
        AppLanguage.odia            => _gregMonthShortOdia[month - 1],
        AppLanguage.telugu          => _gregMonthShortTelugu[month - 1],
        AppLanguage.malayalam       => _gregMonthShortMalayalam[month - 1],
        AppLanguage.kannada         => _gregMonthShortKannada[month - 1],
        _ => _gregMonthShortEn[month - 1],
      };

  // ── Paksha ────────────────────────────────────────────────────────────

  /// All-caps form used in the lunar month line (e.g. "SHUKLA PAKSHA").
  static String pakshaUpper(Paksha p, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => p == Paksha.shukla ? 'शुक्ल' : 'कृष्ण',
        AppLanguage.tamil           => p == Paksha.shukla ? 'வளர்பிறை' : 'தேய்பிறை',
        AppLanguage.bengali         => p == Paksha.shukla ? 'শুক্ল' : 'কৃষ্ণ',
        AppLanguage.odia            => p == Paksha.shukla ? 'ଶୁକ୍ଳ' : 'କୃଷ୍ଣ',
        AppLanguage.telugu          => p == Paksha.shukla ? 'శుక్ల' : 'కృష్ణ',
        AppLanguage.malayalam       => p == Paksha.shukla ? 'ശുക്ല' : 'കൃഷ്ണ',
        AppLanguage.kannada         => p == Paksha.shukla ? 'ಶುಕ್ಲ' : 'ಕೃಷ್ಣ',
        _ => p == Paksha.shukla ? 'SHUKLA' : 'KRISHNA',
      };

  /// Title-case form used in detail rows (e.g. "Shukla 5").
  static String paksha(Paksha p, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => p == Paksha.shukla ? 'शुक्ल' : 'कृष्ण',
        AppLanguage.tamil           => p == Paksha.shukla ? 'வளர்பிறை' : 'தேய்பிறை',
        AppLanguage.bengali         => p == Paksha.shukla ? 'শুক্ল' : 'কৃষ্ণ',
        AppLanguage.odia            => p == Paksha.shukla ? 'ଶୁକ୍ଳ' : 'କୃଷ୍ଣ',
        AppLanguage.telugu          => p == Paksha.shukla ? 'శుక్ల' : 'కృష్ణ',
        AppLanguage.malayalam       => p == Paksha.shukla ? 'ശുക്ല' : 'കൃഷ്ണ',
        AppLanguage.kannada         => p == Paksha.shukla ? 'ಶುಕ್ಲ' : 'ಕೃಷ್ಣ',
        _ => p == Paksha.shukla ? 'Shukla' : 'Krishna',
      };

  /// The word "Paksha" / "பக்ஷம்" used as a suffix.
  static String pakshaWord(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'पक्ष',
        AppLanguage.tamil           => 'பக்ஷம்',
        AppLanguage.bengali         => 'পক্ষ',
        AppLanguage.odia            => 'ପକ୍ଷ',
        AppLanguage.telugu          => 'పక్షం',
        AppLanguage.malayalam       => 'പക്ഷം',
        AppLanguage.kannada         => 'ಪಕ್ಷ',
        _ => 'PAKSHA',
      };

  // ── Labels ────────────────────────────────────────────────────────────

  static String adhikaPrefix(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अधिक ',
        AppLanguage.tamil           => 'அதிக ',
        AppLanguage.bengali         => 'অধিক ',
        AppLanguage.odia            => 'ଅଧିକ ',
        AppLanguage.telugu          => 'అధిక ',
        AppLanguage.malayalam       => 'അധിക ',
        AppLanguage.kannada         => 'ಅಧಿಕ ',
        _ => 'ADHIKA ',
      };

  static String adhikaPrefixShort(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अधिक ',
        AppLanguage.tamil           => 'அதிக. ',
        AppLanguage.bengali         => 'অধিক. ',
        AppLanguage.odia            => 'ଅଧ. ',
        AppLanguage.telugu          => 'అధ. ',
        AppLanguage.malayalam       => 'അധ. ',
        AppLanguage.kannada         => 'ಅಧ. ',
        _ => 'ADH. ',
      };

  static String nakshatra(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'नक्षत्र',
        AppLanguage.tamil           => 'நட்சத்திரம்',
        AppLanguage.bengali         => 'নক্ষত্র',
        AppLanguage.odia            => 'ନକ୍ଷତ୍ର',
        AppLanguage.telugu          => 'నక్షత్రం',
        AppLanguage.malayalam       => 'നക്ഷത്രം',
        AppLanguage.kannada         => 'ನಕ್ಷತ್ರ',
        _ => 'NAKSHATRA',
      };

  static String sunrise(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'सूर्योदय',
        AppLanguage.tamil           => 'சூரிய உதயம்',
        AppLanguage.bengali         => 'সূর্যোদয়',
        AppLanguage.odia            => 'ସୂର୍ଯ୍ୟୋଦୟ',
        AppLanguage.telugu          => 'సూర్యోదయం',
        AppLanguage.malayalam       => 'സൂര്യോദയം',
        AppLanguage.kannada         => 'ಸೂರ್ಯೋದಯ',
        _ => 'SUNRISE',
      };

  static String sunset(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'सूर्यास्त',
        AppLanguage.tamil           => 'சூரிய அஸ்தமனம்',
        AppLanguage.bengali         => 'সূর্যাস্ত',
        AppLanguage.odia            => 'ସୂର୍ଯ୍ୟାସ୍ତ',
        AppLanguage.telugu          => 'సూర్యాస్తమయం',
        AppLanguage.malayalam       => 'സൂര്യാസ്തമനം',
        AppLanguage.kannada         => 'ಸೂರ್ಯಾಸ್ತ',
        _ => 'SUNSET',
      };

  static String festivals(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'पर्व',
        AppLanguage.tamil           => 'விழாக்கள்',
        AppLanguage.bengali         => 'উৎসব',
        AppLanguage.odia            => 'ଉତ୍ସବ',
        AppLanguage.telugu          => 'పండుగలు',
        AppLanguage.malayalam       => 'ഉത്സവങ്ങൾ',
        AppLanguage.kannada         => 'ಹಬ್ಬಗಳು',
        _ => 'FESTIVALS',
      };

  static String ekadashi(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'एकादशी',
        AppLanguage.tamil           => 'ஏகாதசி',
        AppLanguage.bengali         => 'একাদশী',
        AppLanguage.odia            => 'ଏକାଦଶୀ',
        AppLanguage.telugu          => 'ఏకాదశి',
        AppLanguage.malayalam       => 'ഏകാദശി',
        AppLanguage.kannada         => 'ಏಕಾದಶಿ',
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
        AppLanguage.odia =>
          'ଏକାଦଶୀ ପ୍ରତ୍ୟେକ ଚନ୍ଦ୍ର ପକ୍ଷର ଏକାଦଶ ଦିନ ଆସେ — ମାସରେ ଦୁଇ ଥର। ଉପବାସ, ପ୍ରାର୍ଥନା ଏବଂ ଭଗବାନ ବିଷ୍ଣୁଙ୍କ ଭକ୍ତି ପାଇଁ ଏହା ସବୁଠୁ ପବିତ୍ର ଦିନ। ଏକାଦଶୀ ପାଳନ ମନକୁ ଶୁଦ୍ଧ କରେ ଓ ଆଧ୍ୟାତ୍ମିକ ପୁଣ୍ୟ ଅର୍ଜନ ହୁଏ।',
        AppLanguage.telugu =>
          'ఏకాదశి ప్రతి చంద్ర పక్షం యొక్క పదకొండవ రోజున వస్తుంది — నెలలో రెండుసార్లు. ఇది ఉపవాసం, ప్రార్థన మరియు శ్రీమహావిష్ణువు భక్తికి అత్యంత పవిత్రమైన రోజులలో ఒకటి. ఏకాదశి పాటించడం వలన మనసు శుద్ధి అవుతుంది మరియు ఆధ్యాత్మిక పుణ్యం పేరుకుంటుంది.',
        AppLanguage.malayalam =>
          'ഏകാദശി ഓരോ ചന്ദ്ര പക്ഷത്തിലെ പതിനൊന്നാം ദിവസം വരുന്നു — മാസത്തിൽ രണ്ടുതവണ. ഉപവാസം, പ്രാർഥന, ഭഗവാൻ വിഷ്ണുവിന്റെ ഭക്തി എന്നിവയ്ക്ക് ഏറ്റവും ശുഭകരമായ ദിവസങ്ങളിൽ ഒന്നാണ് ഇത്. ഏകാദശി ആചരിക്കുന്നത് മനസ്സിനെ ശുദ്ധിയാക്കുകയും ആത്മീയ പുണ്യം ആർജ്ജിക്കുകയും ചെയ്യുന്നു.',
        AppLanguage.kannada =>
          'ಏಕಾದಶಿ ಪ್ರತಿ ಚಂದ್ರ ಪಕ್ಷದ ಹನ್ನೊಂದನೇ ದಿನ ಬರುತ್ತದೆ — ತಿಂಗಳಿಗೆ ಎರಡು ಬಾರಿ. ಉಪವಾಸ, ಪ್ರಾರ್ಥನೆ ಮತ್ತು ಶ್ರೀ ವಿಷ್ಣುವಿನ ಭಕ್ತಿಗಾಗಿ ಅತ್ಯಂತ ಪವಿತ್ರವಾದ ದಿನಗಳಲ್ಲಿ ಇದು ಒಂದು. ಏಕಾದಶಿ ಆಚರಿಸುವುದರಿಂದ ಮನಸ್ಸು ಶುದ್ಧವಾಗಿ ಆಧ್ಯಾತ್ಮಿಕ ಪುಣ್ಯ ಸಂಗ್ರಹವಾಗುತ್ತದೆ.',
        _ =>
          'Ekadashi falls on the 11th day of each lunar fortnight — twice a month. It is one of the most auspicious days for fasting, prayer, and devotion to Lord Vishnu. Observing Ekadashi is believed to purify the mind and accumulate spiritual merit.',
      };

  static String about(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'विवरण',
        AppLanguage.tamil           => 'விவரம்',
        AppLanguage.bengali         => 'বিবরণ',
        AppLanguage.odia            => 'ବିବରଣ',
        AppLanguage.telugu          => 'వివరణ',
        AppLanguage.malayalam       => 'വിവരണം',
        AppLanguage.kannada         => 'ವಿವರಣ',
        _                           => 'ABOUT',
      };

  static String howToObserve(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'कैसे मनाएँ',
        AppLanguage.tamil           => 'எப்படி கொண்டாடுவது',
        AppLanguage.bengali         => 'কীভাবে পালন করবেন',
        AppLanguage.odia            => 'କିପରି ପାଳନ କରିବେ',
        AppLanguage.telugu          => 'ఎలా ఆచరించాలి',
        AppLanguage.malayalam       => 'എങ്ങനെ ആചരിക്കണം',
        AppLanguage.kannada         => 'ಹೇಗೆ ಆಚರಿಸಬೇಕು',
        _                           => 'HOW TO OBSERVE',
      };

  static String purnima(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'पूर्णिमा',
        AppLanguage.tamil           => 'பவுர்ணமி',
        AppLanguage.bengali         => 'পূর্ণিমা',
        AppLanguage.odia            => 'ପୂର୍ଣ୍ଣିମା',
        AppLanguage.telugu          => 'పూర్ణిమ',
        AppLanguage.malayalam       => 'പൂർണ്ണിമ',
        AppLanguage.kannada         => 'ಪೂರ್ಣಿಮ',
        _ => 'Purnima',
      };

  static String amavasya(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अमावस्या',
        AppLanguage.tamil           => 'அமாவாசை',
        AppLanguage.bengali         => 'অমাবস্যা',
        AppLanguage.odia            => 'ଅମାବାସ୍ୟା',
        AppLanguage.telugu          => 'అమావాస్య',
        AppLanguage.malayalam       => 'അമാവാസ്യ',
        AppLanguage.kannada         => 'ಅಮಾವಾಸ್ಯ',
        _ => 'Amavasya',
      };

  static String moonrise(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'चंद्रोदय',
        AppLanguage.tamil           => 'சந்திர உதயம்',
        AppLanguage.bengali         => 'চন্দ্রোদয়',
        AppLanguage.odia            => 'ଚନ୍ଦ୍ରୋଦୟ',
        AppLanguage.telugu          => 'చంద్రోదయం',
        AppLanguage.malayalam       => 'ചന്ദ്രോദയം',
        AppLanguage.kannada         => 'ಚಂದ್ರೋದಯ',
        _ => 'MOONRISE',
      };

  static String moonset(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'चंद्रास्त',
        AppLanguage.tamil           => 'சந்திர அஸ்தமனம்',
        AppLanguage.bengali         => 'চন্দ্রাস্ত',
        AppLanguage.odia            => 'ଚନ୍ଦ୍ରାସ୍ତ',
        AppLanguage.telugu          => 'చంద్రాస్తమయం',
        AppLanguage.malayalam       => 'ചന്ദ്രാസ്തമനം',
        AppLanguage.kannada         => 'ಚಂದ್ರಾಸ್ತ',
        _ => 'MOONSET',
      };

  static String hora(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'होरा',
        AppLanguage.tamil           => 'ஹோரா',
        AppLanguage.bengali         => 'হোরা',
        AppLanguage.odia            => 'ହୋରା',
        AppLanguage.telugu          => 'హోర',
        AppLanguage.malayalam       => 'ഹോര',
        AppLanguage.kannada         => 'ಹೋರ',
        _ => 'HORA',
      };

  /// Title-case "Hora" for PageTitleBar (distinct from all-caps HORA label).
  static String horaPageTitle(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'होरा',
        AppLanguage.tamil           => 'ஹோரா',
        AppLanguage.bengali         => 'হোরা',
        AppLanguage.odia            => 'ହୋରା',
        AppLanguage.telugu          => 'హోర',
        AppLanguage.malayalam       => 'ഹോര',
        AppLanguage.kannada         => 'ಹೋರ',
        _ => 'Hora',
      };

  /// Title-case "Festivals" for PageTitleBar.
  static String festivalsPageTitle(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'त्योहार',
        AppLanguage.tamil           => 'விழாக்கள்',
        AppLanguage.bengali         => 'উৎসব',
        AppLanguage.odia            => 'ଉତ୍ସବ',
        AppLanguage.telugu          => 'పండుగలు',
        AppLanguage.malayalam       => 'ഉത്സവങ്ങൾ',
        AppLanguage.kannada         => 'ಹಬ್ಬಗಳು',
        _ => 'Festivals',
      };

  static String horaDay(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'दिन',
        AppLanguage.tamil           => 'பகல்',
        AppLanguage.bengali         => 'দিন',
        AppLanguage.odia            => 'ଦିନ',
        AppLanguage.telugu          => 'పగలు',
        AppLanguage.malayalam       => 'പകൽ',
        AppLanguage.kannada         => 'ಹಗಲು',
        _ => 'DAY',
      };

  static String horaNight(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'रात',
        AppLanguage.tamil           => 'இரவு',
        AppLanguage.bengali         => 'রাত',
        AppLanguage.odia            => 'ରାତ',
        AppLanguage.telugu          => 'రాత్రి',
        AppLanguage.malayalam       => 'രാത്രി',
        AppLanguage.kannada         => 'ರಾತ್ರಿ',
        _ => 'NIGHT',
      };

  static String dayView(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'दिन',
        AppLanguage.tamil           => 'நாள்',
        AppLanguage.bengali         => 'দিন',
        AppLanguage.odia            => 'ଦିନ',
        AppLanguage.telugu          => 'రోజు',
        AppLanguage.malayalam       => 'ദിവസം',
        AppLanguage.kannada         => 'ದಿನ',
        _ => 'DAY',
      };

  /// e.g. "Hour 3 · Day" or "Hour 3 · Night"
  static String horaSubLabel(int n, bool isDay, AppLanguage lang) {
    final period = isDay ? horaDay(lang) : horaNight(lang);
    return switch (lang) {
      AppLanguage.hindiDevanagari => 'घंटा $n · $period',
      AppLanguage.tamil           => 'ஹோரா $n · $period',
      AppLanguage.bengali         => 'ঘণ্টা $n · $period',
      AppLanguage.odia            => 'ଘଣ୍ଟା $n · $period',
      AppLanguage.telugu          => 'హోర $n · $period',
      AppLanguage.malayalam       => 'ഹോര $n · $period',
      AppLanguage.kannada         => 'ಹೋರ $n · $period',
      _ => 'Hour $n · $period',
    };
  }

  /// "NOW" indicator on the active hora row.
  static String horaNow(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अभी',
        AppLanguage.tamil           => 'இப்போது',
        AppLanguage.bengali         => 'এখন',
        AppLanguage.odia            => 'ଏବେ',
        AppLanguage.telugu          => 'ఇప్పుడు',
        AppLanguage.malayalam       => 'ഇപ്പോൾ',
        AppLanguage.kannada         => 'ಈಗ',
        _ => 'NOW',
      };

  /// Error shown when horaProvider returns an error state.
  static String horaUnavailable(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'होरा उपलब्ध नहीं।',
        AppLanguage.tamil           => 'ஹோரா கிடைக்கவில்லை.',
        AppLanguage.bengali         => 'হোরা পাওয়া যাচ্ছে না।',
        AppLanguage.odia            => 'ହୋରା ଅନୁପଲବ୍ଧ।',
        AppLanguage.telugu          => 'హోర అందుబాటులో లేదు.',
        AppLanguage.malayalam       => 'ഹോര ലഭ്യമല്ല.',
        AppLanguage.kannada         => 'ಹೋರ ಲಭ್ಯವಿಲ್ಲ.',
        _ => 'Hora unavailable for this date.',
      };

  /// Error shown when sunrise/sunset data is missing.
  static String horaSunriseMissing(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'सूर्योदय डेटा अनुपलब्ध।',
        AppLanguage.tamil           => 'சூரிய உதயம் தகவல் இல்லை.',
        AppLanguage.bengali         => 'সূর্যোদয়ের তথ্য নেই।',
        AppLanguage.odia            => 'ସୂର୍ଯ୍ୟୋଦୟ ତଥ୍ୟ ଅନୁପଲବ୍ଧ।',
        AppLanguage.telugu          => 'సూర్యోదయ సమాచారం లేదు.',
        AppLanguage.malayalam       => 'സൂര്യോദയ വിവരം ലഭ്യമല്ല.',
        AppLanguage.kannada         => 'ಸೂರ್ಯೋದಯ ವಿವರ ಲಭ್ಯವಿಲ್ಲ.',
        _ => 'Hora unavailable — sunrise data missing.',
      };

  // ── Sentence templates ────────────────────────────────────────────────

  static String nakshatraUntil(String time, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'तक $time',
        AppLanguage.tamil           => '$time வரை',
        AppLanguage.bengali         => '$time পর্যন্ত',
        AppLanguage.odia            => '$time ପର୍ଯ୍ୟନ୍ତ',
        AppLanguage.telugu          => '$time వరకు',
        AppLanguage.malayalam       => '$time വരെ',
        AppLanguage.kannada         => '$time ವರೆಗೆ',
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
        AppLanguage.odia    => '$monthName $weekday, $month $day-ରୁ $time',
        AppLanguage.telugu  => '$monthName $weekday, $month $day నుండి $time',
        AppLanguage.malayalam => '$monthName $weekday, $month $day-ൽ $time മുതൽ',
        AppLanguage.kannada => '$monthName $weekday, $month $day-ರಿಂದ $time',
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
        AppLanguage.odia            => '· $name $time ଠାରୁ',
        AppLanguage.telugu          => '· $name $time నుండి',
        AppLanguage.malayalam       => '· $name $time മുതൽ',
        AppLanguage.kannada         => '· $name $time ರಿಂದ',
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
        AppLanguage.odia            => 'ମୁହୂର୍ତ',
        AppLanguage.telugu          => 'ముహూర్తం',
        AppLanguage.malayalam       => 'മുഹൂർത്തം',
        AppLanguage.kannada         => 'ಮುಹೂರ್ತ',
        _ => 'Muhurta',
      };

  static String sectionAuspicious(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'शुभ',
        AppLanguage.tamil           => 'சுபம்',
        AppLanguage.bengali         => 'শুভ',
        AppLanguage.odia            => 'ଶୁଭ',
        AppLanguage.telugu          => 'శుభ',
        AppLanguage.malayalam       => 'ശുഭ',
        AppLanguage.kannada         => 'ಶುಭ',
        _ => 'Auspicious',
      };

  static String sectionInauspicious(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अशुभ',
        AppLanguage.tamil           => 'அசுபம்',
        AppLanguage.bengali         => 'অশুভ',
        AppLanguage.odia            => 'ଅଶୁଭ',
        AppLanguage.telugu          => 'అశుభ',
        AppLanguage.malayalam       => 'അശുഭ',
        AppLanguage.kannada         => 'ಅಶುಭ',
        _ => 'Inauspicious',
      };

  static String brahmaMuhurta(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'ब्रह्म मुहूर्त',
        AppLanguage.tamil           => 'பிரம்ம முகூர்த்தம்',
        AppLanguage.bengali         => 'ব্রহ্ম মুহূর্ত',
        AppLanguage.odia            => 'ବ୍ରହ୍ମ ମୁହୂର୍ତ',
        AppLanguage.telugu          => 'బ్రహ్మ ముహూర్తం',
        AppLanguage.malayalam       => 'ബ്രഹ്മ മുഹൂർത്തം',
        AppLanguage.kannada         => 'ಬ್ರಹ್ಮ ಮುಹೂರ್ತ',
        _ => 'Brahma Muhurta',
      };

  static String brahmaMuhurtaSub(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'ध्यान और पूजा',
        AppLanguage.tamil           => 'தியானம் மற்றும் வழிபாடு',
        AppLanguage.bengali         => 'ধ্যান ও পূজা',
        AppLanguage.odia            => 'ଧ୍ୟାନ ଓ ପୂଜା',
        AppLanguage.telugu          => 'ధ్యానం మరియు ప్రార్థన',
        AppLanguage.malayalam       => 'ധ്യാനവും പ്രാർഥനയും',
        AppLanguage.kannada         => 'ಧ್ಯಾನ ಮತ್ತು ಪ್ರಾರ್ಥನೆ',
        _ => 'meditation & prayer',
      };

  static String abhijitMuhurta(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अभिजित् मुहूर्त',
        AppLanguage.tamil           => 'அபிஜித் முகூர்த்தம்',
        AppLanguage.bengali         => 'অভিজিৎ মুহূর্ত',
        AppLanguage.odia            => 'ଅଭିଜିତ ମୁହୂର୍ତ',
        AppLanguage.telugu          => 'అభిజిత్ ముహూర్తం',
        AppLanguage.malayalam       => 'അഭിജിത് മുഹൂർത്തം',
        AppLanguage.kannada         => 'ಅಭಿಜಿತ್ ಮುಹೂರ್ತ',
        _ => 'Abhijit Muhurta',
      };

  static String abhijitMuhurtaSub(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'सर्वाधिक शुभ समय',
        AppLanguage.tamil           => 'மிகவும் சுபகரமான நேரம்',
        AppLanguage.bengali         => 'সবচেয়ে শুভ সময়',
        AppLanguage.odia            => 'ସର୍ବାଧିକ ଶୁଭ ସମୟ',
        AppLanguage.telugu          => 'అత్యంత శుభ సమయం',
        AppLanguage.malayalam       => 'ഏറ്റവും ശുഭകരമായ സമയം',
        AppLanguage.kannada         => 'ಅತ್ಯಂತ ಶುಭ ಸಮಯ',
        _ => 'most auspicious window',
      };

  static String abhijitNotObserved(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'बुधवार को नहीं होता',
        AppLanguage.tamil           => 'புதன்கிழமை கொண்டாடப்படுவதில்லை',
        AppLanguage.bengali         => 'বুধবারে পালিত হয় না',
        AppLanguage.odia            => 'ବୁଧବାରରେ ଆଚରଣ ହୁଏ ନାହିଁ',
        AppLanguage.telugu          => 'బుధవారం పాటించబడదు',
        AppLanguage.malayalam       => 'ബുധനാഴ്ച ആചരിക്കില്ല',
        AppLanguage.kannada         => 'ಬುಧವಾರ ಆಚರಿಸಲ್ಪಡುವುದಿಲ್ಲ',
        _ => 'not observed on Wednesday',
      };

  static String rahuKaal(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'राहु काल',
        AppLanguage.tamil           => 'ராகு காலம்',
        AppLanguage.bengali         => 'রাহু কাল',
        AppLanguage.odia            => 'ରାହୁ କାଳ',
        AppLanguage.telugu          => 'రాహు కాలం',
        AppLanguage.malayalam       => 'രാഹു കാലം',
        AppLanguage.kannada         => 'ರಾಹು ಕಾಲ',
        _ => 'Rahu Kaal',
      };

  static String yamaganda(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'यमगण्ड',
        AppLanguage.tamil           => 'யமகண்டம்',
        AppLanguage.bengali         => 'যমগণ্ড',
        AppLanguage.odia            => 'ଯମଗଣ୍ଡ',
        AppLanguage.telugu          => 'యమగండం',
        AppLanguage.malayalam       => 'യമഗണ്ഡം',
        AppLanguage.kannada         => 'ಯಮಗಂಡ',
        _ => 'Yamaganda',
      };

  static String gulika(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'गुलिक',
        AppLanguage.tamil           => 'குலிகன்',
        AppLanguage.bengali         => 'গুলিক',
        AppLanguage.odia            => 'ଗୁଳିକ',
        AppLanguage.telugu          => 'గులిక',
        AppLanguage.malayalam       => 'ഗുളിക',
        AppLanguage.kannada         => 'ಗುಳಿಕ',
        _ => 'Gulika',
      };

  static String avoidNewStarts(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'नए काम न करें',
        AppLanguage.tamil           => 'புதிய தொடக்கங்களை தவிர்க்கவும்',
        AppLanguage.bengali         => 'নতুন কাজ এড়িয়ে চলুন',
        AppLanguage.odia            => 'ନୂଆ କାର୍ଯ୍ୟ ଆରମ୍ଭ କରନ୍ତୁ ନାହିଁ',
        AppLanguage.telugu          => 'కొత్త పనులు ప్రారంభించవద్దు',
        AppLanguage.malayalam       => 'പുതിയ ആരംഭങ്ങൾ ഒഴിവാക്കുക',
        AppLanguage.kannada         => 'ಹೊಸ ಕೆಲಸ ಆರಂಭಿಸಬೇಡಿ',
        _ => 'avoid new starts',
      };

  static String dayChoghadiya(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'दिन का चौघड़िया',
        AppLanguage.tamil           => 'பகல் சோகடியா',
        AppLanguage.bengali         => 'দিনের চৌঘড়িয়া',
        AppLanguage.odia            => 'ଦିନ ଚୌଘଡ଼ିଆ',
        AppLanguage.telugu          => 'పగటి చోఘడియా',
        AppLanguage.malayalam       => 'പകൽ ചോഘഡിയ',
        AppLanguage.kannada         => 'ಹಗಲು ಚೌಘಡಿಯ',
        _ => 'Day Choghadiya',
      };

  static String nightChoghadiya(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'रात का चौघड़िया',
        AppLanguage.tamil           => 'இரவு சோகடியா',
        AppLanguage.bengali         => 'রাতের চৌঘড়িয়া',
        AppLanguage.odia            => 'ରାତ ଚୌଘଡ଼ିଆ',
        AppLanguage.telugu          => 'రాత్రి చోఘడియా',
        AppLanguage.malayalam       => 'രാത്രി ചോഘഡിയ',
        AppLanguage.kannada         => 'ರಾತ್ರಿ ಚೌಘಡಿಯ',
        _ => 'Night Choghadiya',
      };

  static String nightChoghadiyaExpand(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => '▸ विस्तार करें',
        AppLanguage.tamil           => '▸ விரிவாக்கு',
        AppLanguage.bengali         => '▸ বিস্তার করুন',
        AppLanguage.odia            => '▸ ବିସ୍ତାର କରନ୍ତୁ',
        AppLanguage.telugu          => '▸ విస్తరించు',
        AppLanguage.malayalam       => '▸ വിപുലീകരിക്കൂ',
        AppLanguage.kannada         => '▸ ವಿಸ್ತರಿಸಿ',
        _ => '▸ expand',
      };

  static String nightChoghadiyaCollapse(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => '▾ छुपाएं',
        AppLanguage.tamil           => '▾ மறை',
        AppLanguage.bengali         => '▾ লুকান',
        AppLanguage.odia            => '▾ ଲୁଚ',
        AppLanguage.telugu          => '▾ మూయు',
        AppLanguage.malayalam       => '▾ ചുരുക്കൂ',
        AppLanguage.kannada         => '▾ ಮುಚ್ಚಿ',
        _ => '▾ collapse',
      };

  static String muhurtaCardTitle(AppLanguage lang) => muhurta(lang);

  static String labelNow(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अभी',
        AppLanguage.tamil           => 'இப்போது',
        AppLanguage.bengali         => 'এখন',
        AppLanguage.odia            => 'ଏବେ',
        AppLanguage.telugu          => 'ఇప్పుడు',
        AppLanguage.malayalam       => 'ഇപ്പോൾ',
        AppLanguage.kannada         => 'ಈಗ',
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
    AppLanguage.odia            => 'ଅମୃତ',
    AppLanguage.telugu          => 'అమృత',
    AppLanguage.malayalam       => 'അമൃത',
    AppLanguage.kannada         => 'ಅಮೃತ',
    _ => 'Amrit',
  };
  static String _chogNameShubh(AppLanguage lang) => switch (lang) {
    AppLanguage.hindiDevanagari => 'शुभ',
    AppLanguage.tamil           => 'சுபம்',
    AppLanguage.bengali         => 'শুভ',
    AppLanguage.odia            => 'ଶୁଭ',
    AppLanguage.telugu          => 'శుభ',
    AppLanguage.malayalam       => 'ശുഭ',
    AppLanguage.kannada         => 'ಶುಭ',
    _ => 'Shubh',
  };
  static String _chogNameLabh(AppLanguage lang) => switch (lang) {
    AppLanguage.hindiDevanagari => 'लाभ',
    AppLanguage.tamil           => 'லாபம்',
    AppLanguage.bengali         => 'লাভ',
    AppLanguage.odia            => 'ଲାଭ',
    AppLanguage.telugu          => 'లాభ',
    AppLanguage.malayalam       => 'ലാഭ',
    AppLanguage.kannada         => 'ಲಾಭ',
    _ => 'Labh',
  };
  static String _chogNameChar(AppLanguage lang) => switch (lang) {
    AppLanguage.hindiDevanagari => 'चर',
    AppLanguage.tamil           => 'சரம்',
    AppLanguage.bengali         => 'চর',
    AppLanguage.odia            => 'ଚର',
    AppLanguage.telugu          => 'చర',
    AppLanguage.malayalam       => 'ചര',
    AppLanguage.kannada         => 'ಚರ',
    _ => 'Char',
  };
  static String _chogNameUdveg(AppLanguage lang) => switch (lang) {
    AppLanguage.hindiDevanagari => 'उद्वेग',
    AppLanguage.tamil           => 'உத்வேகம்',
    AppLanguage.bengali         => 'উদ্বেগ',
    AppLanguage.odia            => 'ଉଦ୍ବେଗ',
    AppLanguage.telugu          => 'ఉద్వేగ',
    AppLanguage.malayalam       => 'ഉദ്വേഗ',
    AppLanguage.kannada         => 'ಉದ್ವೇಗ',
    _ => 'Udveg',
  };
  static String _chogNameKaal(AppLanguage lang) => switch (lang) {
    AppLanguage.hindiDevanagari => 'काल',
    AppLanguage.tamil           => 'காலம்',
    AppLanguage.bengali         => 'কাল',
    AppLanguage.odia            => 'କାଳ',
    AppLanguage.telugu          => 'కాల',
    AppLanguage.malayalam       => 'കാല',
    AppLanguage.kannada         => 'ಕಾಲ',
    _ => 'Kaal',
  };
  static String _chogNameRog(AppLanguage lang) => switch (lang) {
    AppLanguage.hindiDevanagari => 'रोग',
    AppLanguage.tamil           => 'ரோகம்',
    AppLanguage.bengali         => 'রোগ',
    AppLanguage.odia            => 'ରୋଗ',
    AppLanguage.telugu          => 'రోగ',
    AppLanguage.malayalam       => 'രോഗ',
    AppLanguage.kannada         => 'ರೋಗ',
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
        AppLanguage.odia            => 'ଶ୍ରେଷ୍ଠ',
        AppLanguage.telugu          => 'అత్యుత్తమ',
        AppLanguage.malayalam       => 'ഉത്തമം',
        AppLanguage.kannada         => 'ಶ್ರೇಷ್ಠ',
        _ => 'excellent',
      };

  static String qualityAuspicious(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'शुभ',
        AppLanguage.tamil           => 'சுபகரமான',
        AppLanguage.bengali         => 'শুভ',
        AppLanguage.odia            => 'ଶୁଭ',
        AppLanguage.telugu          => 'శుభ',
        AppLanguage.malayalam       => 'ശുഭ',
        AppLanguage.kannada         => 'ಶುಭ',
        _ => 'auspicious',
      };

  static String qualityProfitable(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'लाभदायक',
        AppLanguage.tamil           => 'இலாபகரமான',
        AppLanguage.bengali         => 'লাভজনক',
        AppLanguage.odia            => 'ଲାଭଦାୟକ',
        AppLanguage.telugu          => 'లాభదాయకం',
        AppLanguage.malayalam       => 'ലാഭകരം',
        AppLanguage.kannada         => 'ಲಾಭದಾಯಕ',
        _ => 'profitable',
      };

  static String qualityNeutral(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'सामान्य',
        AppLanguage.tamil           => 'நடுநிலை',
        AppLanguage.bengali         => 'নিরপেক্ষ',
        AppLanguage.odia            => 'ସାଧାରଣ',
        AppLanguage.telugu          => 'తటస్థ',
        AppLanguage.malayalam       => 'നിഷ്പക്ഷ',
        AppLanguage.kannada         => 'ತಟಸ್ಥ',
        _ => 'neutral',
      };

  static String qualityInauspicious(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अशुभ',
        AppLanguage.tamil           => 'அசுபகரமான',
        AppLanguage.bengali         => 'অশুভ',
        AppLanguage.odia            => 'ଅଶୁଭ',
        AppLanguage.telugu          => 'అశుభ',
        AppLanguage.malayalam       => 'അശുഭ',
        AppLanguage.kannada         => 'ಅಶುಭ',
        _ => 'inauspicious',
      };

  // ── Panchanga ─────────────────────────────────────────────────────────────

  static String panchaTitle(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'पंचांग',
        AppLanguage.tamil           => 'பஞ்சாங்கம்',
        AppLanguage.bengali         => 'পঞ্চাঙ্গ',
        AppLanguage.odia            => 'ପଞ୍ଚାଙ୍ଗ',
        AppLanguage.telugu          => 'పంచాంగం',
        AppLanguage.malayalam       => 'പഞ്ചാംഗം',
        AppLanguage.kannada         => 'ಪಂಚಾಂಗ',
        _ => 'Panchanga',
      };

  static String fiveElementsLabel(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'पंच तत्त्व',
        AppLanguage.tamil           => 'ஐந்து அங்கங்கள்',
        AppLanguage.bengali         => 'পঞ্চতত্ত্ব',
        AppLanguage.odia            => 'ପଞ୍ଚ ତତ୍ତ୍ୱ',
        AppLanguage.telugu          => 'ఐదు అంగాలు',
        AppLanguage.malayalam       => 'അഞ്ചു അംഗങ്ങൾ',
        AppLanguage.kannada         => 'ಐದು ಅಂಗಗಳು',
        _ => 'Five Elements',
      };

  static String varaLabel(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'वार',
        AppLanguage.tamil           => 'வாரம்',
        AppLanguage.bengali         => 'বার',
        AppLanguage.odia            => 'ବାର',
        AppLanguage.telugu          => 'వారం',
        AppLanguage.malayalam       => 'ദിവസം',
        AppLanguage.kannada         => 'ವಾರ',
        _ => 'Vara',
      };

  static String tithiLabel(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'तिथि',
        AppLanguage.tamil           => 'திதி',
        AppLanguage.bengali         => 'তিথি',
        AppLanguage.odia            => 'ତିଥି',
        AppLanguage.telugu          => 'తిథి',
        AppLanguage.malayalam       => 'തിഥി',
        AppLanguage.kannada         => 'ತಿಥಿ',
        _ => 'Tithi',
      };

  static String nakshatraLabel(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'नक्षत्र',
        AppLanguage.tamil           => 'நட்சத்திரம்',
        AppLanguage.bengali         => 'নক্ষত্র',
        AppLanguage.odia            => 'ନକ୍ଷତ୍ର',
        AppLanguage.telugu          => 'నక్షత్రం',
        AppLanguage.malayalam       => 'നക്ഷത്രം',
        AppLanguage.kannada         => 'ನಕ್ಷತ್ರ',
        _ => 'Nakshatra',
      };

  /// Title-case weekday name for display in the Five Elements card.
  static String weekdayTitle(int weekday, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _weekdayFullDeva[weekday - 1],
        AppLanguage.tamil           => _weekdayFullTamil[weekday - 1],
        AppLanguage.bengali         => _weekdayFullBengali[weekday - 1],
        AppLanguage.odia            => _weekdayFullOdia[weekday - 1],
        AppLanguage.telugu          => _weekdayFullTelugu[weekday - 1],
        AppLanguage.malayalam       => _weekdayFullMalayalam[weekday - 1],
        AppLanguage.kannada         => _weekdayFullKannada[weekday - 1],
        _ => _weekdayTitleEn[weekday - 1],
      };

  /// Sanskrit vara name · ruling planet sub-line for the Five Elements card.
  static String varaRulerSub(int weekday, AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => _varaRulerSubDeva[weekday - 1],
        AppLanguage.tamil           => _varaRulerSubTamil[weekday - 1],
        AppLanguage.bengali         => _varaRulerSubBengali[weekday - 1],
        AppLanguage.odia            => _varaRulerSubOdia[weekday - 1],
        AppLanguage.telugu          => _varaRulerSubTelugu[weekday - 1],
        AppLanguage.malayalam       => _varaRulerSubMalayalam[weekday - 1],
        AppLanguage.kannada         => _varaRulerSubKannada[weekday - 1],
        _ => _varaRulerSubEn[weekday - 1],
      };

  static String avoidNewBeginnings(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'नई शुरुआत न करें',
        AppLanguage.tamil           => 'புதிய தொடக்கங்களை தவிர்க்கவும்',
        AppLanguage.bengali         => 'নতুন সূচনা এড়িয়ে চলুন',
        AppLanguage.odia            => 'ନୂଆ ଆରମ୍ଭ ଏଡ଼ାନ୍ତୁ',
        AppLanguage.telugu          => 'కొత్త ప్రారంభాలు నివారించండి',
        AppLanguage.malayalam       => 'പുതിയ ആരംഭങ്ങൾ ഒഴിവാക്കുക',
        AppLanguage.kannada         => 'ಹೊಸ ಆರಂಭ ತಪ್ಪಿಸಿ',
        _ => 'avoid new beginnings',
      };

  // ── Yoga ─────────────────────────────────────────────────────────────────

  static String yogaName(int number, AppLanguage lang) {
    assert(number >= 1 && number <= 27);
    return switch (lang) {
      AppLanguage.hindiDevanagari => _yogaNamesDeva[number - 1],
      AppLanguage.tamil           => _yogaNamesTamil[number - 1],
      AppLanguage.bengali         => _yogaNamesBengali[number - 1],
      AppLanguage.odia            => _yogaNamesOdia[number - 1],
      AppLanguage.telugu          => _yogaNamesTelugu[number - 1],
      AppLanguage.malayalam       => _yogaNamesMalayalam[number - 1],
      AppLanguage.kannada         => _yogaNamesKannada[number - 1],
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
        AppLanguage.odia            => 'ଯୋଗ',
        AppLanguage.telugu          => 'యోగ',
        AppLanguage.malayalam       => 'യോഗ',
        AppLanguage.kannada         => 'ಯೋಗ',
        _ => 'Yoga',
      };

  static String nextYogaLabel(AppLanguage lang) =>
      switch (lang) {
        AppLanguage.hindiDevanagari => 'अगला',
        AppLanguage.tamil           => 'அடுத்து',
        AppLanguage.bengali         => 'পরবর্তী',
        AppLanguage.odia            => 'ପରବର୍ତ୍ତୀ',
        AppLanguage.telugu          => 'తదుపరి',
        AppLanguage.malayalam       => 'അടുത്തത്',
        AppLanguage.kannada         => 'ಮುಂದಿನ',
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
        AppLanguage.odia            => _karanaNameOdia(type),
        AppLanguage.telugu          => _karanaNameTelugu(type),
        AppLanguage.malayalam       => _karanaNameMalayalam(type),
        AppLanguage.kannada         => _karanaNameKannada(type),
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
        AppLanguage.odia            => 'କରଣ',
        AppLanguage.telugu          => 'కరణం',
        AppLanguage.malayalam       => 'കരണം',
        AppLanguage.kannada         => 'ಕರಣ',
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

  static String _karanaNameOdia(KaranaType t) => switch (t) {
    KaranaType.bava         => 'ବବ',
    KaranaType.balava       => 'ବାଳବ',
    KaranaType.kaulava      => 'କୌଳବ',
    KaranaType.taitila      => 'ତୈତିଳ',
    KaranaType.gara         => 'ଗର',
    KaranaType.vanija       => 'ବଣିଜ',
    KaranaType.vishti       => 'ବିଷ୍ଟି',
    KaranaType.shakuni      => 'ଶକୁନି',
    KaranaType.chatushpada  => 'ଚତୁଷ୍ପାଦ',
    KaranaType.naga         => 'ନାଗ',
    KaranaType.kimstughna   => 'କିଂସ୍ତୁଘ୍ନ',
  };

  static String _karanaNameTelugu(KaranaType t) => switch (t) {
    KaranaType.bava         => 'బవ',
    KaranaType.balava       => 'బాలవ',
    KaranaType.kaulava      => 'కౌలవ',
    KaranaType.taitila      => 'తైతిల',
    KaranaType.gara         => 'గర',
    KaranaType.vanija       => 'వణిజ',
    KaranaType.vishti       => 'విష్టి',
    KaranaType.shakuni      => 'శకుని',
    KaranaType.chatushpada  => 'చతుష్పాద',
    KaranaType.naga         => 'నాగ',
    KaranaType.kimstughna   => 'కింస్తుఘ్న',
  };

  static String _karanaNameMalayalam(KaranaType t) => switch (t) {
    KaranaType.bava         => 'ബവ',
    KaranaType.balava       => 'ബാലവ',
    KaranaType.kaulava      => 'കൗലവ',
    KaranaType.taitila      => 'തൈതില',
    KaranaType.gara         => 'ഗര',
    KaranaType.vanija       => 'വണിജ',
    KaranaType.vishti       => 'വിഷ്ടി',
    KaranaType.shakuni      => 'ശകുനി',
    KaranaType.chatushpada  => 'ചതുഷ്പാദ',
    KaranaType.naga         => 'നാഗ',
    KaranaType.kimstughna   => 'കിംസ്തുഘ്ന',
  };

  static String _karanaNameKannada(KaranaType t) => switch (t) {
    KaranaType.bava         => 'ಬವ',
    KaranaType.balava       => 'ಬಾಲವ',
    KaranaType.kaulava      => 'ಕೌಲವ',
    KaranaType.taitila      => 'ತೈತಿಲ',
    KaranaType.gara         => 'ಗರ',
    KaranaType.vanija       => 'ವಣಿಜ',
    KaranaType.vishti       => 'ವಿಷ್ಟಿ',
    KaranaType.shakuni      => 'ಶಕುನಿ',
    KaranaType.chatushpada  => 'ಚತುಷ್ಪಾದ',
    KaranaType.naga         => 'ನಾಗ',
    KaranaType.kimstughna   => 'ಕಿಂಸ್ತುಘ್ನ',
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

  // ── Odia ──────────────────────────────────────────────────────────────────
  static const _weekdayFullOdia = [
    'ସୋମବାର', 'ମଙ୍ଗଳବାର', 'ବୁଧବାର', 'ଗୁରୁବାର', 'ଶୁକ୍ରବାର', 'ଶନିବାର', 'ରବିବାର',
  ];
  static const _weekdayShortOdia = [
    'ସୋମ', 'ମଙ୍ଗଳ', 'ବୁଧ', 'ଗୁରୁ', 'ଶୁକ୍ର', 'ଶନି', 'ରବି',
  ];
  // Sunday-first (0=Sun .. 6=Sat):
  static const _weekdayLetterOdia = ['ର', 'ସୋ', 'ମ', 'ବୁ', 'ଗୁ', 'ଶୁ', 'ଶ'];
  static const _gregMonthOdia = [
    'ଜାନୁଆରୀ', 'ଫେବ୍ରୁଆରୀ', 'ମାର୍ଚ୍ଚ', 'ଏପ୍ରିଲ', 'ମଇ', 'ଜୁନ',
    'ଜୁଲାଇ', 'ଅଗଷ୍ଟ', 'ସେପ୍ଟେମ୍ବର', 'ଅକ୍ଟୋବର', 'ନଭେମ୍ବର', 'ଡିସେମ୍ବର',
  ];
  static const _gregMonthShortOdia = [
    'ଜାନ', 'ଫେବ', 'ମାର', 'ଏପ୍ର', 'ମଇ', 'ଜୁନ',
    'ଜୁଲ', 'ଅଗ', 'ସେପ', 'ଅକ୍ଟ', 'ନଭ', 'ଡିସ',
  ];
  static const _varaRulerSubOdia = [
    'ସୋମବାର · ଚନ୍ଦ୍ର',
    'ମଙ୍ଗଳବାର · ମଙ୍ଗଳ',
    'ବୁଧବାର · ବୁଧ',
    'ଗୁରୁବାର · ଗୁରୁ',
    'ଶୁକ୍ରବାର · ଶୁକ୍ର',
    'ଶନିବାର · ଶନି',
    'ରବିବାର · ରବି',
  ];

  // ── Telugu ────────────────────────────────────────────────────────────────
  static const _weekdayFullTelugu = [
    'సోమవారం', 'మంగళవారం', 'బుధవారం', 'గురువారం', 'శుక్రవారం', 'శనివారం', 'ఆదివారం',
  ];
  static const _weekdayShortTelugu = [
    'సోమ', 'మంగళ', 'బుధ', 'గురు', 'శుక్ర', 'శని', 'ఆది',
  ];
  // Sunday-first (0=Sun .. 6=Sat):
  static const _weekdayLetterTelugu = ['ఆ', 'సో', 'మం', 'బు', 'గు', 'శు', 'శ'];
  static const _gregMonthTelugu = [
    'జనవరి', 'ఫిబ్రవరి', 'మార్చి', 'ఏప్రిల్', 'మే', 'జూన్',
    'జులై', 'ఆగస్టు', 'సెప్టెంబర్', 'అక్టోబర్', 'నవంబర్', 'డిసెంబర్',
  ];
  static const _gregMonthShortTelugu = [
    'జన', 'ఫిబ్ర', 'మార్చి', 'ఏప్ర', 'మే', 'జూన్',
    'జులై', 'ఆగ', 'సెప్ట', 'అక్ట', 'నవ', 'డిస',
  ];
  static const _varaRulerSubTelugu = [
    'సోమవారం · చంద్ర',
    'మంగళవారం · మంగళ',
    'బుధవారం · బుధ',
    'గురువారం · గురు',
    'శుక్రవారం · శుక్ర',
    'శనివారం · శని',
    'ఆదివారం · సూర్య',
  ];

  // ── Malayalam ─────────────────────────────────────────────────────────────
  static const _weekdayFullMalayalam = [
    'തിങ്കൾ', 'ചൊവ്വ', 'ബുധൻ', 'വ്യാഴം', 'വെള്ളി', 'ശനി', 'ഞായർ',
  ];
  static const _weekdayShortMalayalam = [
    'തിങ്', 'ചൊവ്വ', 'ബുധ', 'വ്യാഴ', 'വെള്ളി', 'ശനി', 'ഞായ',
  ];
  // Sunday-first (0=Sun .. 6=Sat):
  static const _weekdayLetterMalayalam = ['ഞ', 'തി', 'ചൊ', 'ബു', 'വ്യ', 'വെ', 'ശ'];
  static const _gregMonthMalayalam = [
    'ജനുവരി', 'ഫെബ്രുവരി', 'മാർച്ച്', 'ഏപ്രിൽ', 'മേയ്', 'ജൂൺ',
    'ജൂലൈ', 'ഓഗസ്റ്റ്', 'സെപ്റ്റംബർ', 'ഒക്ടോബർ', 'നവംബർ', 'ഡിസംബർ',
  ];
  static const _gregMonthShortMalayalam = [
    'ജന', 'ഫെബ്', 'മാർ', 'ഏപ്ര', 'മേ', 'ജൂൺ',
    'ജൂലൈ', 'ഓഗ', 'സെപ്', 'ഒക്', 'നവ', 'ഡിസ',
  ];
  static const _varaRulerSubMalayalam = [
    'തിങ്കൾ · ചന്ദ്ര',
    'ചൊവ്വ · ചൊവ്വ',
    'ബുധൻ · ബുധ',
    'വ്യാഴം · ഗുരു',
    'വെള്ളി · ശുക്ര',
    'ശനി · ശനി',
    'ഞായർ · സൂര്യ',
  ];

  // ── Kannada ───────────────────────────────────────────────────────────────
  static const _weekdayFullKannada = [
    'ಸೋಮವಾರ', 'ಮಂಗಳವಾರ', 'ಬುಧವಾರ', 'ಗುರುವಾರ', 'ಶುಕ್ರವಾರ', 'ಶನಿವಾರ', 'ಭಾನುವಾರ',
  ];
  static const _weekdayShortKannada = [
    'ಸೋಮ', 'ಮಂಗಳ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ', 'ಭಾನು',
  ];
  // Sunday-first (0=Sun .. 6=Sat):
  static const _weekdayLetterKannada = ['ಭಾ', 'ಸೋ', 'ಮಂ', 'ಬು', 'ಗು', 'ಶು', 'ಶ'];
  static const _gregMonthKannada = [
    'ಜನವರಿ', 'ಫೆಬ್ರವರಿ', 'ಮಾರ್ಚ್', 'ಏಪ್ರಿಲ್', 'ಮೇ', 'ಜೂನ್',
    'ಜುಲೈ', 'ಆಗಸ್ಟ್', 'ಸೆಪ್ಟೆಂಬರ್', 'ಅಕ್ಟೋಬರ್', 'ನವಂಬರ್', 'ಡಿಸೆಂಬರ್',
  ];
  static const _gregMonthShortKannada = [
    'ಜನ', 'ಫೆಬ್', 'ಮಾರ್ಚ್', 'ಏಪ್ರ', 'ಮೇ', 'ಜೂನ್',
    'ಜುಲೈ', 'ಆಗ', 'ಸೆಪ್ಟ', 'ಅಕ್ಟ', 'ನವ', 'ಡಿಸ',
  ];
  static const _varaRulerSubKannada = [
    'ಸೋಮವಾರ · ಚಂದ್ರ',
    'ಮಂಗಳವಾರ · ಮಂಗಳ',
    'ಬುಧವಾರ · ಬುಧ',
    'ಗುರುವಾರ · ಗುರು',
    'ಶುಕ್ರವಾರ · ಶುಕ್ರ',
    'ಶನಿವಾರ · ಶನಿ',
    'ಭಾನುವಾರ · ಸೂರ್ಯ',
  ];

  // ── Yoga names (new languages) ────────────────────────────────────────────

  static const _yogaNamesOdia = [
    'ବିଷ୍କମ୍ଭ', 'ପ୍ରୀତି',    'ଆୟୁଷ୍ମାନ', 'ସୌଭାଗ୍ୟ', 'ଶୋଭନ',
    'ଅତିଗଣ୍ଡ',  'ସୁକର୍ମ',  'ଧୃତି',     'ଶୂଳ',     'ଗଣ୍ଡ',
    'ବୃଦ୍ଧି',   'ଧ୍ରୁବ',   'ବ୍ୟାଘାତ',  'ହର୍ଷଣ',   'ବଜ୍ର',
    'ସିଦ୍ଧି',   'ବ୍ୟତୀପାତ','ବରୀୟାନ',   'ପରିଘ',    'ଶିବ',
    'ସିଦ୍ଧ',    'ସାଧ୍ୟ',   'ଶୁଭ',      'ଶୁକ୍ଳ',   'ବ୍ରହ୍ମ',
    'ଇନ୍ଦ୍ର',   'ବୈଧୃତି',
  ];

  static const _yogaNamesTelugu = [
    'విష్కంభ', 'ప్రీతి',    'ఆయుష్మాన్', 'సౌభాగ్య', 'శోభన',
    'అతిగండ',  'సుకర్మ',  'ధృతి',      'శూల',     'గండ',
    'వృద్ధి',  'ధ్రువ',   'వ్యాఘాత',   'హర్షణ',   'వజ్ర',
    'సిద్ధి',  'వ్యతీపాత','వరీయాన్',   'పరిఘ',    'శివ',
    'సిద్ధ',   'సాధ్య',   'శుభ',       'శుక్ల',   'బ్రహ్మ',
    'ఇంద్ర',   'వైధృతి',
  ];

  static const _yogaNamesMalayalam = [
    'വിഷ്കംഭ', 'പ്രീതി',    'ആയുഷ്മാൻ', 'സൗഭാഗ്യ', 'ശോഭന',
    'അതിഗണ്ഡ',  'സുകർമ',  'ധൃതി',     'ശൂല',     'ഗണ്ഡ',
    'വൃദ്ധി',   'ധ്രുവ',   'വ്യാഘാത',  'ഹർഷണ',   'വജ്ര',
    'സിദ്ധി',   'വ്യതീപാത','വരീയാൻ',   'പരിഘ',    'ശിവ',
    'സിദ്ധ',    'സാധ്യ',   'ശുഭ',      'ശുക്ല',   'ബ്രഹ്മ',
    'ഇന്ദ്ര',   'വൈധൃതി',
  ];

  static const _yogaNamesKannada = [
    'ವಿಷ್ಕಂಭ', 'ಪ್ರೀತಿ',    'ಆಯುಷ್ಮಾನ್', 'ಸೌಭಾಗ್ಯ', 'ಶೋಭನ',
    'ಅತಿಗಂಡ',  'ಸುಕರ್ಮ',  'ಧೃತಿ',      'ಶೂಲ',     'ಗಂಡ',
    'ವೃದ್ಧಿ',  'ಧ್ರುವ',   'ವ್ಯಾಘಾತ',   'ಹರ್ಷಣ',   'ವಜ್ರ',
    'ಸಿದ್ಧಿ',  'ವ್ಯತೀಪಾತ','ವರೀಯಾನ್',   'ಪರಿಘ',    'ಶಿವ',
    'ಸಿದ್ಧ',   'ಸಾಧ್ಯ',   'ಶುಭ',       'ಶುಕ್ಲ',   'ಬ್ರಹ್ಮ',
    'ಇಂದ್ರ',   'ವೈಧೃತಿ',
  ];
}
