import 'app_settings.dart';

/// The 12 Purnimanta lunar months, keyed by the sidereal sun sign at Purnima.
///
/// The moon is in the nakshatra that names the month at each Full Moon; the sun
/// is therefore ~180° away, i.e. one sign "behind":
///   Mesha sun → moon in Krittika/Rohini area → Vaishakha
///   Vrishabha sun → Jyeshtha … and so on.
///
/// Index = sidereal sun sign (0 = Mesha … 11 = Meena) at the Purnima that
/// ENDS the current Purnimanta month.
enum LunarMonth {
  vaishakha,    // Sun in Mesha  (sign 0) at Purnima
  jyeshtha,     // Sun in Vrishabha (1)
  ashadha,      // Sun in Mithuna  (2)
  shravana,     // Sun in Karka    (3)
  bhadrapada,   // Sun in Simha    (4)
  ashwina,      // Sun in Kanya    (5)
  kartika,      // Sun in Tula     (6)
  margashirsha, // Sun in Vrishchika (7)
  pausha,       // Sun in Dhanu    (8)
  magha,        // Sun in Makara   (9)
  phalguna,     // Sun in Kumbha   (10)
  chaitra,      // Sun in Meena    (11)
}

extension LunarMonthName on LunarMonth {
  // Array order matches enum declaration (vaishakha=0 … chaitra=11)
  String get nameEn => const [
        'Vaishakha', 'Jyeshtha', 'Ashadha', 'Shravana',
        'Bhadrapada', 'Ashwina', 'Kartika', 'Margashirsha',
        'Pausha', 'Magha', 'Phalguna', 'Chaitra',
      ][index];

  String get nameDeva => const [
        'वैशाख', 'ज्येष्ठ', 'आषाढ़', 'श्रावण',
        'भाद्रपद', 'आश्विन', 'कार्तिक', 'मार्गशीर्ष',
        'पौष', 'माघ', 'फाल्गुन', 'चैत्र',
      ][index];

  String get nameTamil => const [
        'வைகாசி', 'ஆனி', 'ஆடி', 'ஆவணி',
        'புரட்டாசி', 'ஐப்பசி', 'கார்த்திகை', 'மார்கழி',
        'தை', 'மாசி', 'பங்குனி', 'சித்திரை',
      ][index];

  String get nameBengali => const [
        'বৈশাখ', 'জ্যৈষ্ঠ', 'আষাঢ়', 'শ্রাবণ',
        'ভাদ্র', 'আশ্বিন', 'কার্তিক', 'অগ্রহায়ণ',
        'পৌষ', 'মাঘ', 'ফাল্গুন', 'চৈত্র',
      ][index];

  String get nameOdia => const [
        'ବୈଶାଖ', 'ଜ୍ୟେଷ୍ଠ', 'ଆଷାଢ଼', 'ଶ୍ରାବଣ',
        'ଭାଦ୍ରବ', 'ଆଶ୍ୱିନ', 'କାର୍ତ୍ତିକ', 'ମାର୍ଗଶୀର',
        'ପୌଷ', 'ମାଘ', 'ଫାଲ୍ଗୁନ', 'ଚୈତ୍ର',
      ][index];

  String get nameTelugu => const [
        'వైశాఖ', 'జ్యేష్ఠ', 'ఆషాఢ', 'శ్రావణ',
        'భాద్రపద', 'ఆశ్వయుజ', 'కార్తీక', 'మార్గశిర',
        'పుష్య', 'మాఘ', 'ఫాల్గుణ', 'చైత్ర',
      ][index];

  String get nameMalayalam => const [
        'വൈശാഖം', 'ജ്യേഷ്ഠം', 'ആഷാഢം', 'ശ്രാവണം',
        'ഭാദ്രം', 'ആശ്വിനം', 'കാർത്തിക', 'മാർഗ്ഗശീർഷം',
        'പൗഷം', 'മാഘം', 'ഫാൽഗുനം', 'ചൈത്രം',
      ][index];

  String get nameKannada => const [
        'ವೈಶಾಖ', 'ಜ್ಯೇಷ್ಠ', 'ಆಷಾಢ', 'ಶ್ರಾವಣ',
        'ಭಾದ್ರಪದ', 'ಆಶ್ವಿನ', 'ಕಾರ್ತೀಕ', 'ಮಾರ್ಗಶಿರ',
        'ಪುಷ್ಯ', 'ಮಾಘ', 'ಫಾಲ್ಗುಣ', 'ಚೈತ್ರ',
      ][index];

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

  // 4-char abbreviation for the month-grid cell label.
  // ASHA=Ashadha, ASHW=Ashwina (unique pair).
  String get abbr4 => const [
        'VAIS', 'JYES', 'ASHA', 'SHRA', 'BHAD', 'ASHW',
        'KART', 'MARG', 'PAUS', 'MAGH', 'PHAL', 'CHAI',
      ][index];
}
