/// A nakshatra instance — which nakshatra and when it ends.
class NakshatraInfo {
  /// 1–27 (Ashwini = 1, Revati = 27).
  final int number;

  /// UTC time this nakshatra ends.
  final DateTime end;

  const NakshatraInfo({required this.number, required this.end});

  String get nameEn => _namesEn[number - 1];
  String get nameDeva => _namesDeva[number - 1];
  String get nameTamil => _namesTamil[number - 1];
  String get nameBengali => _namesBengali[number - 1];
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
