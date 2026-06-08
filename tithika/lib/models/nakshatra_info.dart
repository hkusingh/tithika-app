import 'app_settings.dart';

/// A nakshatra instance — which nakshatra and when it ends.
class NakshatraInfo {
  /// 1–27 (Ashwini = 1, Revati = 27).
  final int number;

  /// UTC time this nakshatra ends.
  final DateTime end;

  const NakshatraInfo({required this.number, required this.end});

  String get nameEn       => _namesEn[number - 1];
  String get nameDeva     => _namesDeva[number - 1];
  String get nameTamil    => _namesTamil[number - 1];
  String get nameBengali  => _namesBengali[number - 1];
  String get nameOdia     => _namesOdia[number - 1];
  String get nameTelugu   => _namesTelugu[number - 1];
  String get nameMalayalam => _namesMalayalam[number - 1];
  String get nameKannada  => _namesKannada[number - 1];

  String nameFor(AppLanguage lang) => switch (lang) {
    AppLanguage.hindiDevanagari => nameDeva,
    AppLanguage.tamil           => nameTamil,
    AppLanguage.bengali         => nameBengali,
    AppLanguage.odia            => nameOdia,
    AppLanguage.telugu          => nameTelugu,
    AppLanguage.malayalam       => nameMalayalam,
    AppLanguage.kannada         => nameKannada,
    _                           => nameEn,
  };
}

const _namesEn = [
  'Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira',
  'Ardra', 'Punarvasu', 'Pushya', 'Ashlesha', 'Magha',
  'Purva Phalguni', 'Uttara Phalguni', 'Hasta', 'Chitra', 'Swati',
  'Vishakha', 'Anuradha', 'Jyeshtha', 'Mula', 'Purva Ashadha',
  'Uttara Ashadha', 'Shravana', 'Dhanishtha', 'Shatabhisha',
  'Purva Bhadrapada', 'Uttara Bhadrapada', 'Revati',
];

const _namesDeva = [
  'अश्विनी', 'भरणी', 'कृत्तिका', 'रोहिणी', 'मृगशिरा',
  'आर्द्रा', 'पुनर्वसु', 'पुष्य', 'आश्लेषा', 'मघा',
  'पूर्व फाल्गुनी', 'उत्तर फाल्गुनी', 'हस्त', 'चित्रा', 'स्वाति',
  'विशाखा', 'अनुराधा', 'ज्येष्ठा', 'मूल', 'पूर्वाषाढ़ा',
  'उत्तराषाढ़ा', 'श्रवण', 'धनिष्ठा', 'शतभिषा',
  'पूर्व भाद्रपद', 'उत्तर भाद्रपद', 'रेवती',
];

const _namesTamil = [
  'அஸ்வினி', 'பரணி', 'கார்த்திகை', 'ரோகிணி', 'மிருகசீரிஷம்',
  'திருவாதிரை', 'புனர்பூசம்', 'பூசம்', 'ஆயில்யம்', 'மகம்',
  'பூரம்', 'உத்திரம்', 'அஸ்தம்', 'சித்திரை', 'சுவாதி',
  'விசாகம்', 'அனுஷம்', 'கேட்டை', 'மூலம்', 'பூராடம்',
  'உத்திராடம்', 'திருவோணம்', 'அவிட்டம்', 'சதயம்',
  'பூரட்டாதி', 'உத்திரட்டாதி', 'ரேவதி',
];

const _namesBengali = [
  'অশ্বিনী', 'ভরণী', 'কৃত্তিকা', 'রোহিণী', 'মৃগশিরা',
  'আর্দ্রা', 'পুনর্বসু', 'পুষ্যা', 'আশ্লেষা', 'মঘা',
  'পূর্ব ফাল্গুনী', 'উত্তর ফাল্গুনী', 'হস্তা', 'চিত্রা', 'স্বাতী',
  'বিশাখা', 'অনুরাধা', 'জ্যেষ্ঠা', 'মূলা', 'পূর্বাষাঢ়া',
  'উত্তরাষাঢ়া', 'শ্রবণা', 'ধনিষ্ঠা', 'শতভিষা',
  'পূর্বভাদ্রপদা', 'উত্তরভাদ্রপদা', 'রেবতী',
];

const _namesOdia = [
  'ଅଶ୍ୱିନୀ', 'ଭରଣୀ', 'କୃତ୍ତିକା', 'ରୋହିଣୀ', 'ମୃଗଶିରା',
  'ଆର୍ଦ୍ରା', 'ପୁନର୍ବସୁ', 'ପୁଷ୍ୟ', 'ଆଶ୍ଲେଷା', 'ମଘା',
  'ପୂର୍ବ ଫାଲ୍ଗୁନୀ', 'ଉତ୍ତର ଫାଲ୍ଗୁନୀ', 'ହସ୍ତ', 'ଚିତ୍ରା', 'ସ୍ୱାତୀ',
  'ବିଶାଖା', 'ଅନୁରାଧା', 'ଜ୍ୟେଷ୍ଠା', 'ମୂଳ', 'ପୂର୍ବାଷାଢ଼',
  'ଉତ୍ତରାଷାଢ଼', 'ଶ୍ରବଣ', 'ଧନିଷ୍ଠା', 'ଶତଭିଷା',
  'ପୂର୍ବ ଭାଦ୍ରପଦ', 'ଉତ୍ତର ଭାଦ୍ରପଦ', 'ରେବତୀ',
];

const _namesTelugu = [
  'అశ్విని', 'భరణి', 'కృత్తిక', 'రోహిణి', 'మృగశిర',
  'ఆర్ద్ర', 'పునర్వసు', 'పుష్యమి', 'ఆశ్లేష', 'మఘ',
  'పూర్వ ఫల్గుణి', 'ఉత్తర ఫల్గుణి', 'హస్త', 'చిత్ర', 'స్వాతి',
  'విశాఖ', 'అనూరాధ', 'జ్యేష్ఠ', 'మూల', 'పూర్వాషాఢ',
  'ఉత్తరాషాఢ', 'శ్రవణం', 'ధనిష్ఠ', 'శతభిష',
  'పూర్వాభాద్ర', 'ఉత్తరాభాద్ర', 'రేవతి',
];

const _namesMalayalam = [
  'അശ്വതി', 'ഭരണി', 'കാർത്തിക', 'രോഹിണി', 'മകയിരം',
  'തിരുവാതിര', 'പുനർതം', 'പൂയം', 'ആയില്യം', 'മകം',
  'പൂരം', 'ഉത്രം', 'അത്തം', 'ചിത്തിര', 'ചോതി',
  'വിശാഖം', 'അനിഴം', 'തൃക്കേട്ട', 'മൂലം', 'പൂരാടം',
  'ഉത്രാടം', 'തിരുവോണം', 'അവിട്ടം', 'ചതയം',
  'പൂരുരുട്ടാതി', 'ഉത്രട്ടാതി', 'രേവതി',
];

const _namesKannada = [
  'ಅಶ್ವಿನಿ', 'ಭರಣಿ', 'ಕೃತ್ತಿಕ', 'ರೋಹಿಣಿ', 'ಮೃಗಶಿರ',
  'ಆರ್ದ್ರ', 'ಪುನರ್ವಸು', 'ಪುಷ್ಯ', 'ಆಶ್ಲೇಷ', 'ಮಘ',
  'ಪೂರ್ವ ಫಲ್ಗುಣಿ', 'ಉತ್ತರ ಫಲ್ಗುಣಿ', 'ಹಸ್ತ', 'ಚಿತ್ರ', 'ಸ್ವಾತಿ',
  'ವಿಶಾಖ', 'ಅನುರಾಧ', 'ಜ್ಯೇಷ್ಠ', 'ಮೂಲ', 'ಪೂರ್ವಾಷಾಢ',
  'ಉತ್ತರಾಷಾಢ', 'ಶ್ರವಣ', 'ಧನಿಷ್ಠ', 'ಶತಭಿಷ',
  'ಪೂರ್ವಭಾದ್ರಪದ', 'ಉತ್ತರಭಾದ್ರಪದ', 'ರೇವತಿ',
];
